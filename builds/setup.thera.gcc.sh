#!/bin/bash

#-- This script needs to be source-d in the terminal, e.g.
#   source ./setup.lockhart.cce.sh

module load gcc 
module load rocm/7.2.0


#-- GPU-aware MPI

export MACHINE=thera
export CHOLLA_ENVSET=1
