#!/bin/bash

##SBATCH -J cholla
##SBATCH -o job_output.log
##SBATCH -e job_error.log
##SBATCH -N 1
##SBATCH -n 8
##SBATCH --cpus-per-task=8
##SBATCH --threads-per-core=1
##SBATCH -t 00:10:00
##SBATCH -p mi2508x

#module load openmpi4
# module load hdf5
# module load rocm/7.2.0


#export HSA_ENABLE_SDMA=0

EXEC=${HOME}/code/cholla/bin/cholla.cosmology.conductor_mi355x

export LD_LIBRARY_PATH=${HOME}/util/hdf5/v1.12.2/install/lib:$LD_LIBRARY_PATH

MPI_ROOT=${HOME}/util/openmpi/rocm7.2.3/install/ompi


${MPI_ROOT}/bin/mpirun -n 8 \
  -x UCX_TLS=sm,self,rocm \
  --mca pml ucx \
  ${EXEC} parameter_file.txt > app_output.log 