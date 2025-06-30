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

  module load PrgEnv-cray
  module load cce/18.0.0
  module load cray-python
  module load rocm
  module load craype-accel-amd-gfx90a
  module load cray-hdf5 cray-fftw
  module load libfabric
  export MPICH_GPU_SUPPORT_ENABLED=1
  export MACHINE=lockhart_mi250x
  export CHOLLA_ENVSET=1
  export CHOLLA_GPU_TYPE='mi250x'

  # Use blitz kernels instead of SDMA
  export HSA_ENABLE_SDMA=0

  export LD_LIBRARY_PATH=/home/bvillase/util/rocSTAR/build/lib:$LD_LIBRARY_PATH

elif [[ "${SYSTEM}" = "lockhart_mi300a" ]]; then
  # module load cray-python
  # module load rocm
  # module load cray-hdf5 cray-fftw
  # module load craype-accel-amd-gfx942
  export MPICH_GPU_SUPPORT_ENABLED=1
  export MACHINE=lockhart_mi300a
  export CHOLLA_ENVSET=1
  export CHOLLA_GPU_TYPE='mi300a'  

  export LD_LIBRARY_PATH=/home/bvillase/util/rocSTAR/build/lib:$LD_LIBRARY_PATH

elif [[ "${SYSTEM}" = "frontier" ]]; then
  module load cray-python
  module load rocm
  module load cray-hdf5 cray-fftw
  module load craype-accel-amd-gfx90a
  export MPICH_GPU_SUPPORT_ENABLED=1
  export MACHINE=frontier
  export CHOLLA_ENVSET=1
  export CHOLLA_GPU_TYPE='mi250x'

  # Use blitz kernels instead of SDMA
  export HSA_ENABLE_SDMA=0

elif [[ "${SYSTEM}" = "thera_mi250" ]]; then
  module load gcc 
  module load rocm/6.4.0
  module load hdf5-no-fortran
  export MACHINE=thera
  export CHOLLA_OMPI_ROOT="/home/bvillase/util/openmpi/install/ompi"
  export CHOLLA_ENVSET=1
  export CHOLLA_GPU_TYPE='mi250'

  export PATH=${CHOLLA_OMPI_ROOT}/bin:${PATH}

elif [[ "${SYSTEM}" = "vultr" ]]; then
  export ROCM_PATH="/opt/rocm-6.4.0"
  export CHOLLA_OMPI_ROOT="/localhome/bvillase/util/openmpi/install/ompi"
  export HDF5_DIR="/localhome/bvillase/util/hdf5/parallel/install"
  export MPICH_GPU_SUPPORT_ENABLED=1
  export MACHINE=vultr
  export CHOLLA_ENVSET=1
  export CHOLLA_GPU_TYPE='mi300x'  

  export LD_LIBRARY_PATH=${HOME}/util/rocSTAR/build/lib:$LD_LIBRARY_PATH

else
  echo -e "System: ${SYSTEM} not in list of known systems. "
  return
fi

export CHOLLA_SYSTEM=${SYSTEM}
