#!/bin/bash

#SBATCH -J cholla
#SBATCH -o job_output.log
#SBATCH -e job_error.log
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --cpus-per-task=16
#SBATCH --threads-per-core=1
#SBATCH -t 00:10:00
#SBATCH -p MI300x

module load gcc 
module load rocm/7.2.0
module load hdf5-no-fortran


#export HSA_ENABLE_SDMA=0

EXEC=${HOME}/code/cholla/bin/cholla.cosmology.thera

export LD_LIBRARY_PATH=${HOME}/util/hdf5/1.12.2/lib:$LD_LIBRARY_PATH

MPI_ROOT=${HOME}/util/openmpi/rocm7.2.3/install/ompi
export OMPI_MCA_pml=ucx
export UCX_PROTO_ENABLE=n
export UCX_ROCM_COPY_LAT=2e-6
export UCX_ROCM_IPC_MIN_ZCOPY=4096

srun -n 8 --cpus-per-task=16 --threads-per-core=1 \
  ${EXEC} parameter_file.txt > app_output.log 2>&1
