#!/bin/bash

#-- This script needs to be source-d in the terminal, e.g.
#   source ./setup.lockhart.cce.sh

module load gcc rocm
module load hdf5-no-fortran

#-- GPU-aware MPI

export MACHINE=thera
export CHOLLA_ENVSET=1
