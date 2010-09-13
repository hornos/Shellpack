#!/bin/bash
# __SP_application: queue.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_jobsub_slurm() {
  local qbatch="${1}"

  echo "#${pfx} --job-name ${NAME}"                  >> "${qbatch}"

  # mail
  if ! test -z "${QUEUE_MAIL}" && test "${QUEUE_MAIL}" != "runprg" ; then
    echo "#${pfx} --mail-type=${QUEUE_MAIL}"         >> "${qbatch}"
    if ! test -z "${QUEUE_MAIL_TO}" ; then
      echo "#${pfx} --mail-user=${QUEUE_MAIL_TO}"      >> "${qbatch}"
    fi
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

  echo "#${pfx} -o ${QUEUE_STDOUT:-StdOut}"   >> "${qbatch}"
  echo "#${pfx} -e ${QUEUE_ERROUT:-ErrOut}"   >> "${qbatch}"

  if ! test -z "${QUEUE_OPTS}" ; then
    echo "#${pfx} ${QUEUE_OPTS}"              >> "${qbatch}"
  fi

}

function __mail_sub() {
  echo "Job ${SLURM_JOB_ID} (${SLURM_JOB_NAME})"
}

function __mail_msg() {
  local msg=""
  msg=$(date)
  if ! test -z "${SLURM_JOB_NUM_NODES}" ; then
    echo "${msg}\nRunning on ${SLURM_JOB_NUM_NODES} nodes"
  else
    echo "${msg}"
  fi
}
