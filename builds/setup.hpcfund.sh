#!/bin/bash

# module load openmpi4
module load hdf5
module load rocm/7.2.0

export MPI_DIR=/home1/bvillase/util/openmpi/rocm7.2.0/install/ompi
export MACHINE=hpcfund
export CHOLLA_MACHINE=hpcfund
export CHOLLA_ENVSET=1
 
