#!/bin/bash
# __SP_application: queue.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_jobsub() {
# read job info -----------------------------------------------------------------
  local job_info=${1:-start.job}
  if test -f "${job_info}" ; then
    . ${job_info}
  else
    errmsg "job file ${job_info} not found"
    return 1
  fi

# read queue info ---------------------------------------------------------------
  local queue_info="${shellpack_queues}/${QUEUE:-default}"
  if test -r "${queue_info}" ; then
    . ${queue_info}
  else
    errmsg "queue file ${queue_info} not found"
    return 2
  fi

# submit to queue ---------------------------------------------------------------
  local queue=${SCHED}
  uselib queue.${queue}

  local qbatch="./submit.${SCHED}.sh"
  local timestamp
  timestamp=$(date)

  echo "#!${shell}"      >  "${qbatch}"
  echo "## ${timestamp}" >> "${qbatch}"

# MPI vars ----------------------------------------------------------------------
  local nodes=${NODES:-1}
  local cores=${CORES:-4}
  local sckts=${SCKTS:-2}
  local thrds=${THRDS:-1}

  local total_sckts=$((nodes*sckts))
  local tasks=$((sckts*cores))
  local slots=$((nodes*tasks))
  local threads=$((cores*thrds))

  SLOTS=${slots}
  TASKS=${tasks}

# queue specific jobsub ---------------------------------------------------------
  if test -z "${COMMAND}" ; then
    errmsg "no command"
    return 10
  fi

  if test -z "${NAME}" ; then
    errmsg "no job name"
    return 11
  fi

  __SP_jobsub_${queue} "${qbatch}"

# command -----------------------------------------------------------------------
  if ! test -z "${QUEUE_SETUP}" ; then
    echo "${QUEUE_SETUP}"                        >> "${qbatch}"
  fi

# mail --------------------------------------------------------------------------
  if test "${QUEUE_MAIL}" = "runprg" ; then
    echo "export QUEUE_MAIL_TO=${QUEUE_MAIL_TO}" >> "${qbatch}"
  fi

# MPI ---------------------------------------------------------------------------
  if test "${HYBMPI}" = "on" ; then
    echo "export HYBMPI_MPIRUN_OPTS=\"-np ${total_sckts} -npernode ${sckts}\"" >> "${qbatch}"
  else
    threads=${thrds}
    echo "export HYBMPI_MPIRUN_OPTS=\"-np ${slots} -npernode ${tasks}\""     >> "${qbatch}"
  fi
  # Intel MKL
  echo "export OMP_NUM_THREADS=${threads}" >> "${qbatch}"
  echo "export MKL_NUM_THREADS=${threads}" >> "${qbatch}"
  # echo "export MKL_DYNAMIC=FALSE"          >> "${qbatch}"
  echo "export MKL_DYNAMIC=TRUE"           >> "${qbatch}"
  if test ${threads} -gt 1 ; then
    echo "export KMP_LIBRARY=turnaround"   >> "${qbatch}"
    # echo "export KMP_AFFINITY=granularity=core,compact,0,0"   >> "${qbatch}"
    # echo "export KMP_AFFINITY=norespect,granularity=core,none,0,0"   >> "${qbatch}"
    # echo "export KMP_AFFINITY=granularity=thread,compact0,0" >> "${qbatch}"
  else
    echo "export KMP_LIBRARY=serial"       >> "${qbatch}"
  fi

# mail --------------------------------------------------------------------------
  if test "${COMMAND/*runprg*/runprg}" = "runprg" ; then
    COMMAND="${COMMAND} -s ${SCHED}"
  fi
  echo "${COMMAND}"                           >> "${qbatch}"

# submission --------------------------------------------------------------------
  echo
  echo "Shellpack: $SCHED"
  prnsln
  cat "${qbatch}"
  prnsln
  echo

  yesno "Submit job?"
  local ret=$?
  if test $ret -gt 0 ; then
    return $ret
  fi
  echo
  ${submit} "${qbatch}"
}
