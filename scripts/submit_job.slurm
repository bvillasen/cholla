#!/bin/bash

#SBATCH -J cholla
#SBATCH -o job_output.log
#SBATCH -e job_error.log
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --cpus-per-task=8
#SBATCH --threads-per-core=1
#SBATCH -t 00:10:00
#SBATCH -p mi2508x

#module load openmpi4
module load hdf5
module load rocm/7.2.0

#export HSA_ENABLE_SDMA=0

EXEC=${HOME}/code/cholla/bin/cholla.cosmology.hpcfund

MPI_ROOT=/home1/bvillase/util/openmpi/rocm7.2.0/install/ompi
export OMPI_MCA_pml=ucx
export UCX_PROTO_ENABLE=n
export UCX_ROCM_COPY_LAT=2e-6
export UCX_ROCM_IPC_MIN_ZCOPY=4096

# This node allocates CPUs 0-31 and 64-95 (not 32-63 — those are SMT siblings).
# Let SLURM bind each of the 8 tasks to its 8 adjacent allocated cores.
# Expected layout: ranks 0-3 on CPUs 0-31, ranks 4-7 on CPUs 64-95.
#
# If you need explicit masks for this topology, use:
# CPU_MASKS="ff,ff00,ff0000,ff000000,ff0000000000000000,ff000000000000000000,ff00000000000000000000,ff0000000000000000000000"

srun -n 8 --cpus-per-task=8 --threads-per-core=1 \
  --distribution=block:block \
  --cpu-bind=verbose,cores \
  ${EXEC} parameter_file.txt > app_output.log 2>&1
