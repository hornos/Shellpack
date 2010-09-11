#!/bin/bash
# __SP_application: queue.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_jobsub_sge() {
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
  echo "#${pfx} -N ${NAME}"                  >> "${qbatch}"
  echo "#${pfx} -S ${QUEUE_SHELL:-${shell}}" >> "${qbatch}"

  local nodes=${NODES}
  local cores=${CORES}
  local slots=$((nodes*cores))
  # mail
  if ! test -z "${QUEUE_MAIL_TO}" ; then
    echo "#${pfx} -M ${QUEUE_MAIL_TO}"       >> "${qbatch}"
  fi
  if ! test -z "${QUEUE_MAIL}" ; then
    echo "#${pfx} -m ${QUEUE_MAIL}"          >> "${qbatch}"
  fi

  # time
  if ! test -z "${TIME}" ; then
    echo "#${pfx} -l h_cpu=${TIME}"          >> "${qbatch}"
  fi

  # memory
  if ! test -z "${MEMORY}" ; then
    local memory=${MEMORY}
    vmem=$((slots*memory))
    echo "#${pfx} -l h_vmem=${vmem}${memsize}" >> "${qbatch}"
  fi

  # arch
  if ! test -z "${QUEUE_ARCH}" ; then
    echo "#${pfx} -l arch=${QUEUE_ARCH}"      >> "${qbatch}"
  fi

  # other constraints
  if ! test -z "${QUEUE_CONST}" ; then
    echo "#${pfx} -l ${QUEUE_CONST}"          >> "${qbatch}"
  fi

  # pe
  if ! test -z "${QUEUE_PE}" ; then
    echo "#${pfx} -pe ${QUEUE_PE} ${slots}" >> "${qbatch}"
  fi

  # project
  if ! test -z "${QUEUE_PROJECT}" ; then
    echo "#${pfx} -A ${QUEUE_PROJECT}"        >> "${qbatch}"
  fi

  # queue
  if ! test -z "${QUEUE_QUEUE}" ; then
    echo "#${pfx} -q ${QUEUE_QUEUE}"          >> "${qbatch}"
  fi

  echo "#${pfx} -o ${QUEUE_ERROUT:-ErrorOut}" >> "${qbatch}"

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
  echo "Job ${JOB_ID} (${JOB_NAME})"
}

function __mail_msg() {
  local msg=""
  msg=$(date)
  if ! test -z "${NSLOTS}" ; then
    echo "${msg}\nRunning on ${NSLOTS} nodes"
  else
    echo "${msg}"
  fi
}
