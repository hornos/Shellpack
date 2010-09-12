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

# MPI ---------------------------------------------------------------------------
  local nodes=${NODES}
  local cores=${CORES}
  local cpus=${CPUS}
  local total_cpus=$((nodes*cpus))
  local tasks=$((cpus*cores))
  local slots=$((nodes*tasks))
  local threads=${cores}

  export SLOTS=${slots}
  export TASKS=${tasks}

  if test "${HYBMPI}" = "on" ; then
    export HYBMPI_MPIRUN_OPTS="-np ${total_cpus} -npernode ${cpus}"
  else
    threads=1
    export HYBMPI_MPIRUN_OPTS="-np ${slots} -npernode ${tasks}"
  fi
  # Intel MKL
  export OMP_NUM_THREADS=${threads}
  export MKL_NUM_THREADS=${threads}
  export MKL_DYNAMIC=FALSE


# submit to queue ---------------------------------------------------------------
  local queue=${QUEUE_TYPE}
  uselib queue.${queue}

  local qbatch="./submit.${QUEUE_TYPE}.sh"
  local timestamp
  timestamp=$(date)

  echo "#!${shell}"      >  "${qbatch}"
  echo "## ${timestamp}" >> "${qbatch}"

  __SP_jobsub_${queue} "${qbatch}"

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
