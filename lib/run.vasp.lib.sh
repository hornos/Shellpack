#!/bin/bash
# __SP_application: run.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


function __SP_vasp_prepare() {
  input=`__runinp ${MAININPUT}`

  # prepare inputs --------------------------------------------------------------
  inpfile="${INPUTDIR}/${input}${cntlsuffix}"
  if test -f "${inpfile}" ; then
    __cpunzmv "${inpfile}" "${WORKDIR}" INCAR
  else
    errmsg "file ${inpfile} not found"
    return 21
  fi

  inpfile="${INPUTDIR}/${input}${geomsuffix}"
  if test -f "${inpfile}" ; then
    __cpunzmv "${inpfile}" "${WORKDIR}" POSCAR
  else
    errmsg "file ${inpfile} not found"
    return 22
  fi

  inpfile="${INPUTDIR}/${input}${kptssuffix}"
  if test -f "${inpfile}" ; then
    __cpunzmv "${inpfile}" "${WORKDIR}" KPOINTS
  else
    errmsg "file ${inpfile} not found"
    return 23
  fi

  inpfile="${INPUTDIR}/${input}${qptssuffix}"
  if test -f "${inpfile}" ; then
    __cpunzmv "${inpfile}" "${WORKDIR}" QPOINTS
  else
    warnmsg "file ${inpfile} not found"
    # return 24
  fi

  # prepare libs ----------------------------------------------------------------
  if ! test -d "${LIBDIR}" ; then
    warnmsg "directory ${LIBDIR} doesn't exist"
  fi

  if ! test -z "${LIBS}" ; then
    for lib in ${LIBS}; do
      # build potcar
      libpath="${LIBDIR}/${lib}/POTCAR.gz"
      if ! test -f "${libpath}" ; then
        errmsg "projectorfile ${libpath} not found"
        return 31
      fi
      __cpunzmv "${libpath}" "${WORKDIR}"
      tmplibpath="${WORKDIR}/POTCAR"
      if ! test -f "${tmplibpath}" ; then
        errmsg "projectorfile ${tmplibpath} not found"
        return 32
      fi
      cat "${tmplibpath}" >> "${WORKDIR}/tmpPOTCAR"
      rm -f "${tmplibpath}"

      # build potsic for GW calcs
      if test "${GW}" = "on" ; then
        libpath="${LIBDIR}/${lib}/POTSIC.gz"
        if ! test -f "${libpath}" ; then
          errmsg "projectorfile ${libpath} not found"
          return 33
        fi
        __cpunzmv "${libpath}" "${WORKDIR}"
        tmplibpath="${WORKDIR}/POTSIC"
        if ! test -f "${tmplibpath}" ; then
          errmsg "projectorfile ${tmplibpath} not found"
          return 34
        fi
        cat "${tmplibpath}" >> "${WORKDIR}/tmpPOTSIC"
        rm -f "${tmplibpath}"
      fi
    done

    # finalize
    mv -f "${WORKDIR}/tmpPOTCAR" "${WORKDIR}/POTCAR"
    if test "${GW}" = "on" ; then
      mv -f "${WORKDIR}/tmpPOTSIC" "${WORKDIR}/POTSIC"
    fi
  fi # LIBS

  # prepare others --------------------------------------------------------------
  prefix=${MAININPUT}
  for oin in ${OTHERINPUTS}; do
    oinpath="${INPUTDIR}/${oin}"
    if ! test -f "${oinpath}" ; then
      errmsg "projectorfile ${tmplibpath} not found"
      return 35
    fi
    oout=${oin##${prefix}.}
    __cpunzmv "${oinpath}" "${WORKDIR}" "${oout}"
  done

  return 0
}


function __SP_vasp_finish() {
  return 0
}

function __SP_vasp_collect() {
  if test "${NEB}" = "on" ; then
    cd "${WORKDIR}"

    for rs in ${WORKDIR}/[01]*; do
      if test -f "${rs}" ; then
        __save "${rs}" "${input}"
        ret=$?
        if test $ret -gt 0 ; then
          return $ret
        fi
      fi
    done
  fi

  return 0
}
