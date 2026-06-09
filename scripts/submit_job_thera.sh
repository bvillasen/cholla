#!/bin/bash


CHOLLA_ROOT=${HOME}/code/cholla
source ${CHOLLA_ROOT}/builds/setup.thera.gcc.sh

#export HSA_ENABLE_SDMA=0

EXEC=${HOME}/code/cholla/bin/cholla.cosmology.thera

export LD_LIBRARY_PATH=${HOME}/util/hdf5/v1.12.2/install/lib:$LD_LIBRARY_PATH

MPI_ROOT=${HOME}/util/openmpi/rocm7.2.0/install/ompi

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

${MPI_ROOT}/bin/mpirun -n 8 \
  -x UCX_TLS=sm,self,rocm \
  --mca pml ucx \
  ${EXEC} parameter_file.txt 
