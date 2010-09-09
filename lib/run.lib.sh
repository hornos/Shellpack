#!/bin/bash
# __SP_application: run.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __isrdrc() {
  if test "${1:0:1}" = "<" ; then
    return 1
  fi
  return 0
}

function __runinp() {
  __isrdrc ${1}
  if test $? -gt 0 ; then
    echo ${1:1}
  else
    echo ${1}
  fi
}

function __cleanup() {
  cd "${INPUTDIR}"

  delete_directory "${WORKDIR}"

  delete_symlink "${WORKDIRLINK}"

  return 0
}


function __save() {
  rs="${1}"
  input="${2}"
  if ! test -z "${input}" ; then
    input="${input}."
  fi

  dst=${RESULTDIR}/${input}${rs}${csuffix}
  sav=${RESULTDIR}/${input}${rs}.old${csuffix}

  if test -f "${dst}" ; then
    mv -f "${dst}" "${sav}"
    if test $? -gt 0 ; then
      errmsg "file $dst can't be renamed"
      return 20
    fi
  fi

  crs="${rsfile}${csuffix}"
  ${compress} "${rs}"
  cp -f "${crs}" "${dst}"
  if test $? -gt 0 ; then
    errmsg "file $crs can't be copied"
    return 21
  fi
  chmod u-w "${dst}"
  rm -f "${crs}"
  if test $? -gt 0 ; then
    errmsg "file $crs can't be deleted"
    return 22
  fi

  return 0
}


function __collect() {
  input=`__runinp ${MAININPUT}`

  cd "${WORKDIR}"

  for rs in ${RESULTS}; do
    if test -f "${rs}" ; then
      __save "${rs}" "${input}"
      ret=$?
      if test $ret -gt 0 ; then
        return $ret
      fi
    fi
  done

  return 0
}


function __SP_runprg() {
  # options ---------------------------------------------------------------------
  prg=${1:-vasp}
  guide=${2:-vasp.guide}

  # read guide ------------------------------------------------------------------
  if ! test -f "${guide}" ; then
    errmsg "file $guide not found"
    return 10
  fi
  . "${guide}"

  # create directories ----------------------------------------------------------
  if ! test -d "${INPUTDIR}" ; then
    errmsg "directory $INPUTDIR doesn't exist"
    return 11
  fi

  cd "${INPUTDIR}"

  create_directory "${WORKDIR}"
  if test $? -gt 0 ; then
    return 12
  fi

  create_directory "${RESULTDIR}"
  if test $? -gt 0 ; then
    __cleanup
    return 12
  fi

  WORKDIRLINK=${INPUTDIR}/vasp-${USER}-${HOSTNAME}-${$}
  workdir_path=`readlink ${WORKDIR}`
  if test $? -gt 0 ; then
    workdir_path="${WORKDIR}"
  fi

  create_symlink ${workdir_path} ${WORKDIRLINK}

  if test $? -gt 0 ; then
    warnmsg "link $workdir_path can't be created"
  fi

  # load program library --------------------------------------------------------
  uselib run.${prg}

  # preapre ---------------------------------------------------------------------
  __SP_${prg}_prepare

  __cleanup
  exit
  # run program -----------------------------------------------------------------
  cd "${WORKDIR}"

  output=${prg}.output
  program="${PROGRAMBIN}"

  if ! test -z "${PRERUN}" ; then
    program="${PRERUN} ${program}"
  fi

  if ! test -z "${PARAMS}" ; then
    program="${program} ${PARAMS}"
  fi

  __isrdrc ${MAININPUT}
  input=`__runinp ${MAININPUT}`
  if test $? -gt 0 ; then
    ${program} < ${input} >& ${output}
  else
    ${program} >& ${output}
  fi
  ret=$?

  # check exit status -----------------------------------------------------------
  if test $ret -gt 0 ; then
    if test "${ONERROR}" = "clean" ; then
      __cleanup
    else
      errmsg "program ${program} exited with error code $ret"
      return $ret
    fi
  fi

  __SP_${prg}_finish

  # collect ---------------------------------------------------------------------
  __collect
  if test $ret -gt 0 ; then
    if test "${ONERROR}" = "clean" ; then
      __cleanup
    else
      errmsg "collect exited with error code $ret"
      return $ret
    fi
  fi

  __SP_${prg}_collect

  __cleanup
}
