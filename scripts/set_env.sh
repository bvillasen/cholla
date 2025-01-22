#!/bin/bash


if [[ -v CHOLLA_ROOT ]]; then
    echo "CHOLLA_ROOT: ${CHOLLA_ROOT}"
else
  CURRENT_DIR=$(pwd)
  if [[ "$CURRENT_DIR" == *"cholla"* ]]; then
    prefix=${CURRENT_DIR%%"cholla"*}
    index=$(( ${#prefix} ))
    export CHOLLA_ROOT="${CURRENT_DIR:0:index}cholla"
    echo -e "CHOLLA_ROOT: ${CHOLLA_ROOT}" 
  else
    echo -e "ERROR: CHOLLA_ROOT directory couldn't be find"
    echo -e "Set the path manually by setting: export CHOLLA_ROOT=<path to Cholla repository"
    return
  fi
fi

echo -e "Setting environment for system: ${SYSTEM}"


if [[ "${SYSTEM}" = "lockhart_mi250x" ]]; then
  module load cray-python
  module load rocm
  module load cray-hdf5 cray-fftw
  module load craype-accel-amd-gfx90a
  export MPICH_GPU_SUPPORT_ENABLED=1
  export MACHINE=lockhart_mi250x
  export CHOLLA_ENVSET=1
  export CHOLLA_GPU_TYPE='mi250x'

elif [[ "${SYSTEM}" = "frontier" ]]; then
  module load cray-python
  module load rocm
  module load cray-hdf5 cray-fftw
  module load craype-accel-amd-gfx90a
  export MPICH_GPU_SUPPORT_ENABLED=1
  export MACHINE=frontier
  export CHOLLA_ENVSET=1
  export CHOLLA_GPU_TYPE='mi250x'


else
  echo -e "System: ${SYSTEM} not in list of known systems. "
  return
fi

export CHOLLA_SYSTEM=${SYSTEM}
