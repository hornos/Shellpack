#!/bin/bash
# __SP_application: queue.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_jobsub_pbs() {
  local qbatch="${1}"

  echo "#${pfx} -N ${NAME}"                 >> "${qbatch}"

  # mail
  if ! test -z "${QUEUE_MAIL}" && test "${QUEUE_MAIL}" != "runprg" ; then
    echo "#${pfx} -m ${QUEUE_MAIL}"         >> "${qbatch}"
    if ! test -z "${QUEUE_MAIL_TO}" ; then
      echo "#${pfx} -M ${QUEUE_MAIL_TO}"      >> "${qbatch}"
    fi
  fi

  # time
  if ! test -z "${TIME}" ; then
    echo "#${pfx} -lwalltime=${TIME}"       >> "${qbatch}"
  fi

  # memory
  if ! test -z "${MEMORY}" ; then
    echo "#${pfx} -lpmem=${MEMORY}${memsize}" >> "${qbatch}"
  fi

  # other constraints
  local const=""
  if ! test -z "${QUEUE_CONST}" ; then
    for con in ${QUEUE_CONST} ; do
      const="${const}:${con}"
    done
  fi

  local tasks=""
  if ! test -z "${TASKS}" ; then
    tasks=":ppn=${TASKS}"
  fi

  if ! test -z "${NODES}" ; then
    echo "#${pfx} -lnodes=${NODES}${tasks}${const}" >> "${qbatch}"
  fi

  # project
  if ! test -z "${QUEUE_PROJECT}" ; then
    echo "#${pfx} -A ${QUEUE_PROJECT}"              >> "${qbatch}"
  fi

  # queue
  if ! test -z "${QUEUE_QUEUE}" ; then
    echo "#${pfx} -q ${QUEUE_QUEUE}"                >> "${qbatch}"
  fi

  echo "#${pfx} -o ${QUEUE_STDOUT:-StdOut}"         >> "${qbatch}"
  echo "#${pfx} -e ${QUEUE_ERROUT:-ErrOut}"         >> "${qbatch}"

  if ! test -z "${QUEUE_OPTS}" ; then
    echo "#${pfx} ${QUEUE_OPTS}"                    >> "${qbatch}"
  fi

  echo 'cd "${PBS_O_WORKDIR}"'                      >> "${qbatch}"
}

function __mail_sub() {
  echo "Job ${PBS_JOB_ID} (${PBS_JOBNAME})"
}

function __mail_msg() {
  local msg=""
  msg=$(date)
  if ! test -z "${PBS_NNODES}" ; then
    echo "${msg}\nRunning on ${PBS_NNODES} nodes"
  else
    echo "${msg}"
  fi
}
