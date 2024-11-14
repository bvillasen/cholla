#!/bin/bash

#-- This script needs to be source-d in the terminal, e.g.
#   source ./setup.lockhart.cce.sh

module load cray-python
module load rocm/6.2.1
module load craype-accel-amd-gfx942
module load cray-hdf5 cray-fftw
module load libfabric

#-- GPU-aware MPI
export MPICH_GPU_SUPPORT_ENABLED=1

export MACHINE=lockhart_mi300a
export CHOLLA_ENVSET=1
