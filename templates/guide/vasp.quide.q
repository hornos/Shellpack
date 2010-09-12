# for batch scheduler comment out
TMPDIR=${HOME}/temp

INPUTDIR="${PWD}"
WORKDIR="${TMPDIR}/vasp-${USER}-${HOSTNAME}-$$"
RESULTDIR="${INPUTDIR}"

PRGBIN="vasp"
PARAMS=""
LIBDIR="/projectors/POTCAR_PBE"
LIBS="Si"

MAININPUT="Si"
OTHERINPUTS=""

# for GW comment out
# GW="on"

ONERR="clean"

RESULTS="*"

# MPI
PRERUN="mpirun ${HYBMPI_MPIRUN_OPTS}"

# LD_LIBRARY_PATH
