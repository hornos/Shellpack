#!/bin/bash
# __SP_application: run.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#

function __cpunzmv() {
 local src="${1}"
 local dir="${2}"
 local dst="${3}"
 
 local fname=""
 fname=`basename ${src}`
 local noext=${fname%%${csuffix}}

 cp "${src}" "${dir}"
 if test $? -gt 0 ; then
   errmsg "file $src can't be copied"
   return 50
 fi

 if test "${fname}" != "${noext}" ; then
   ${uncompress} "${dir}/${fname}"
 fi

 if ! test -z "${dst}" ; then
   mv "${dir}/${noext}" "${dir}/${dst}"
   if test $? -gt 0 ; then
     errmsg "file ${dir}/${noext} can't be renamed"
     return 51
   fi
   chmod u+w "${dir}/${dst}"
 else
   chmod u+w "${dir}/${noext}"
 fi

 return 0
}


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
  local rs="${1}"
  local input="${2}"
  if ! test -z "${input}" ; then
    input="${input}."
  fi

  local dst=${RESULTDIR}/${input}${rs}${csuffix}
  local sav=${RESULTDIR}/${input}${rs}.old${csuffix}

  if test -f "${dst}" ; then
    mv -f "${dst}" "${sav}"
    if test $? -gt 0 ; then
      errmsg "file $dst can't be renamed"
      return 20
    fi
  fi

  local crs="${rs}${csuffix}"
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
  local input=""
  input=`__runinp ${MAININPUT}`

  cd "${WORKDIR}"

  local ret
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
  local prg=${1:-vasp}
  local guide=${2:-vasp.guide}

  # read guide ------------------------------------------------------------------
  if ! test -f "${guide}" ; then
    errmsg "file $guide not found"
    return 10
  fi
  . "${guide}"

  # checks ----------------------------------------------------------------------
  if ! test -x "${PRGBIN}" ; then
    errmsg "executable ${PRGBIN} not found"
    return 11
  fi

  # create directories ----------------------------------------------------------
  if ! test -d "${INPUTDIR}" ; then
    errmsg "directory $INPUTDIR doesn't exist"
    return 12
  fi

  cd "${INPUTDIR}"

  create_directory "${WORKDIR}"
  if test $? -gt 0 ; then
    return 13
  fi

  create_directory "${RESULTDIR}"
  if test $? -gt 0 ; then
    __cleanup
    return 14
  fi

  WORKDIRLINK=${INPUTDIR}/vasp-${USER}-${HOSTNAME}-${$}
  local workdir_path=""
  workdir_path=`readlink ${WORKDIR}`
  if test $? -gt 0 ; then
    workdir_path="${WORKDIR}"
  fi

  create_symlink "${workdir_path}" "${WORKDIRLINK}"

  if test $? -gt 0 ; then
    warnmsg "link $workdir_path can't be created"
  fi

  # load program library --------------------------------------------------------
  uselib run.${prg}

  # preapre ---------------------------------------------------------------------
  __SP_${prg}_prepare

  # run program -----------------------------------------------------------------
  cd "${WORKDIR}"

  echo
  echo "Input files in ${WORKDIR}:"
  ls

  local output=${prg}.output
  local program="${PRGBIN}"

  if ! test -z "${PRERUN}" ; then
    program="${PRERUN} ${program}"
  fi

  if ! test -z "${PARAMS}" ; then
    program="${program} ${PARAMS}"
  fi

  echo
  echo "Running ${program}"

  __isrdrc ${MAININPUT}
  local input=""
  input=`__runinp ${MAININPUT}`
  if test $? -gt 0 ; then
    ${program} < ${input} >& ${output}
  else
    ${program} >& ${output}
  fi
  local ret=$?

  echo
  echo "Output files in ${WORKDIR}:"
  ls

  # check exit status -----------------------------------------------------------
  if test $ret -gt 0 ; then
    if test "${ONERR}" = "clean" ; then
      __cleanup
      return $ret
    fi
    errmsg "program ${program} exited with error $ret"
  fi

  __SP_${prg}_finish

  # collect ---------------------------------------------------------------------
  echo
  echo "Saved output files:"
  ls ${RESULTS}

  __collect
  if test $ret -gt 0 ; then
    if test "${ONERR}" = "clean" ; then
      __cleanup
      return $ret
    else
      errmsg "collect exited with error code $ret"
    fi
  fi

  __SP_${prg}_collect

  __cleanup
}
