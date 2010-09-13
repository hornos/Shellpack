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
  local queue=${QUEUE_TYPE}
  uselib queue.${queue}

  local qbatch="./submit.${QUEUE_TYPE}.sh"
  local timestamp
  timestamp=$(date)

  echo "#!${shell}"      >  "${qbatch}"
  echo "## ${timestamp}" >> "${qbatch}"

# MPI vars ----------------------------------------------------------------------
  local nodes=${NODES}
  local cores=${CORES}
  local cpus=${CPUS}
  local total_cpus=$((nodes*cpus))
  local tasks=$((cpus*cores))
  local slots=$((nodes*tasks))
  local threads=${cores}

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
    echo "${QUEUE_SETUP}"                     >> "${qbatch}"
  fi

# MPI ---------------------------------------------------------------------------
  if test "${HYBMPI}" = "on" ; then
    echo "export HYBMPI_MPIRUN_OPTS=\"-np ${total_cpus} -npernode ${cpus}\"" >> "${qbatch}"
  else
    threads=1
    echo "export HYBMPI_MPIRUN_OPTS=\"-np ${slots} -npernode ${tasks}\""     >> "${qbatch}"
  fi
  # Intel MKL
  echo "export OMP_NUM_THREADS=${threads}" >> "${qbatch}"
  echo "export MKL_NUM_THREADS=${threads}" >> "${qbatch}"
  echo "export MKL_DYNAMIC=FALSE"          >> "${qbatch}"
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
    COMMAND="${COMMAND} -s ${QUEUE_TYPE}"
  fi
  echo "${COMMAND}"                           >> "${qbatch}"

# submission --------------------------------------------------------------------
  echo
  echo "Shellpack: $QUEUE_TYPE"
  prnsln
  cat "${qbatch}"
  prnsln
  echo

  yesno "Submit job?"
  local ret=$?
  if test $ret -gt 0 ; then
    return $ret
  fi
  ${submit} "${qbatch}"
}
