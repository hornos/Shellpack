#!/bin/bash
# __SP_application: queue.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_jobsub_sge() {
  local qbatch="${1}"

  echo "#${pfx} -N ${NAME}"                  >> "${qbatch}"
  echo "#${pfx} -S ${QUEUE_SHELL:-${shell}}" >> "${qbatch}"

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
    vmem=$((SLOTS*memory))
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
    echo "#${pfx} -pe ${QUEUE_PE} ${SLOTS}"   >> "${qbatch}"
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
