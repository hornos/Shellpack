#!/bin/bash
# __SP_application: queue.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_jobsub_slurm() {
  local timestamp
  local qbatch="${1:-./queue.${QUEUE_TYPE}}"

  timestamp=$(date)

  echo "#!${shell}"      >  "${qbatch}"
  echo "## ${timestamp}" >> "${qbatch}"

  if test -z "${COMMAND}" ; then
    errmsg "no command"
    return 10
  fi

  if test -z "${NAME}" ; then
    errmsg "no job name"
    return 11
  fi
  echo "#${pfx} --job-name ${NAME}"                  >> "${qbatch}"

  # mail
  if ! test -z "${QUEUE_MAIL_TO}" ; then
    echo "#${pfx} --mail-user=${QUEUE_MAIL_TO}"      >> "${qbatch}"
  fi
  if ! test -z "${QUEUE_MAIL}" ; then
    echo "#${pfx} --mail-type=${QUEUE_MAIL}"         >> "${qbatch}"
  fi

  # time
  if ! test -z "${TIME}" ; then
    echo "#${pfx} --time=${TIME}"             >> "${qbatch}"
  fi

  # memory
  if ! test -z "${MEMORY}" ; then
    echo "#${pfx} --mem-per-cpu=${MEMORY}${memsize}" >> "${qbatch}"
  fi

  if ! test -z "${NODES}" ; then
    echo "#${pfx} --nodes=${NODES}"                  >> "${qbatch}"
  fi

  if ! test -z "${TASKS}" ; then
      echo "#${pfx} --ntasks-per-node=${TASKS}"      >> "${qbatch}"  
  else
    if ! test -z "${CORES}" ; then
      echo "#${pfx} --ntasks-per-node=${CORES}"      >> "${qbatch}"
    fi
  fi
  
  # other constraints
  if ! test -z "${QUEUE_CONST}" ; then
    for con in ${QUEUE_CONST} ; do
      echo "#${pfx} --constraint=${con}"      >> "${qbatch}"
    done
  fi

  # project
  if ! test -z "${QUEUE_PROJECT}" ; then
    echo "#${pfx} --account=${QUEUE_PROJECT}" >> "${qbatch}"
  fi

  echo "#${pfx} --output=${QUEUE_ERROUT:-ErrorOut}" >> "${qbatch}"

  if ! test -z "${QUEUE_OPTS}" ; then
    echo "#${pfx} ${QUEUE_OPTS}"              >> "${qbatch}"
  fi

  if ! test -z "${QUEUE_SETUP}" ; then
    echo "${QUEUE_SETUP}"                     >> "${qbatch}"
  fi

  # for mail
  if test "${COMMAND/*runprg*/runprg}" = "runprg" ; then
    COMMAND="${COMMAND} -s ${QUEUE_TYPE}"
  fi
  echo "${COMMAND}"                           >> "${qbatch}"
}

function __mail_sub() {
  echo "Job ${SLURM_JOB_ID} (${SLURM_JOB_NAME})"
}

function __mail_msg() {
  local msg=""
  msg=$(date)
  if ! test -z "${SLURM_JOB_NUM_NODES}" ; then
    echo "${msg}\nRunning on ${SLURM_JOB_NUM_NODES} nodes"
    if ! test -z "${SLURM_NTASKS_PER_NODE}" ; then
      echo "Running on ${SLURM_NTASKS_PER_NODE} cores per node"
    fi 
  else
    echo "${msg}"
  fi
}
