#!/bin/bash
# __SP_application: run.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_siesta_prepare() {
  local input=""
  input=$(__runinp ${MAININPUT})
  input=${input%%${cntlsuffix}}
  local inpfile=""

  # prepare inputs --------------------------------------------------------------
  inpfile="${INPUTDIR}/${input}${cntlsuffix}"
  if test -f "${inpfile}" ; then
    __cpunzmv "${inpfile}" "${WORKDIR}"
  else
    errmsg "file ${inpfile} not found"
    return 21
  fi


  # prepare libs ----------------------------------------------------------------
  if ! test -d "${LIBDIR}" ; then
    warnmsg "directory ${LIBDIR} doesn't exist"
  fi

  if ! test -z "${LIBS}" ; then
    for lib in ${LIBS}; do
      # build potcar
      local libpath="${LIBDIR}/${lib}"
      if ! test -f "${libpath}" ; then
        errmsg "pseudofile ${libpath} not found"
        return 31
      fi

      local pname=${lib%%.*${pseusuffix##.}*}${pseusuffix}
      __cpunzmv "${libpath}" "${WORKDIR}" "${pname}"
    done
  fi # LIBS

  # prepare others --------------------------------------------------------------
  local oinpath=""
  for oin in ${OTHERINPUTS}; do
    oinpath="${INPUTDIR}/${oin}"
    if ! test -f "${oinpath}" ; then
      errmsg "file ${oinpath} not found"
      return 35
    fi
    __cpunzmv "${oinpath}" "${WORKDIR}"
  done

  return 0
}


function __SP_siesta_finish() {
  return 0
}

function __SP_siesta_collect() {
  __collect false
  return $?
}
