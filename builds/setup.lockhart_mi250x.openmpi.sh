#!/bin/bash

#-- This script needs to be source-d in the terminal, e.g.
#   source ./setup.lockhart.cce.sh

module purge
# module load PrgEnv-cray
module load PrgEnv-gnu
module load cray-python
module load rocm/7.2.0
module load cray-hdf5 

export OMPI_ROOT=${HOME}/util/openmpi/rocm7.2.0/install/ompi
export MACHINE=lockhart_mi250x_openmpi
export CHOLLA_ENVSET=1
