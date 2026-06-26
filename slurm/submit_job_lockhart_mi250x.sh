#!/bin/bash

#SBATCH -J dy_pow
#SBATCH -p MI250X_A1_COS_OK
#SBATCH --time=1:00:00
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8
#SBATCH --threads-per-core=1
#SBATCH --cpus-per-task=8
#SBATCH -e job_error.log
#SBATCH -o job_output.log
#SBATCH --exclusive


echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
start_time=$(date +%s)
echo "Starting SLURM job. $(date)"

CHOLLA_ROOT=${HOME}/code/cholla_cosmology
source ${CHOLLA_ROOT}/builds/setup.lockhart_mi250x.cce.sh
# NOTE: Do NOT prepend a different ROCm version here. The binary and the Cray
# MPICH GTL are linked against the rocm/6.4.3 module loaded in the setup script.
# Injecting rocm-7.0.0/lib swaps libhsa-runtime64.so at runtime and makes the
# GPU-to-GPU IPC path (hsa_amd_ipc_memory_attach) fail with
# HSA_STATUS_ERROR_INVALID_ARGUMENT, which crashes GPU-aware MPI exchanges.
# export LD_LIBRARY_PATH=/opt/COE_modules/rocm/rocm-7.0.0/lib:$LD_LIBRARY_PATH
module list

# Use the ROCm libraries from the loaded module. Mixing ROCm versions can
# make hipFFT/rocFFT fail during plan creation.
# export HSA_ENABLE_SDMA=0

EXEC=${CHOLLA_ROOT}/bin/cholla.cosmology.lockhart_mi250x

srun -n 8 --cpus-per-task=8 --threads-per-core=1 --gpus-per-node=8 \
  --gpu-bind=closest \
  --cpu-bind=verbose --cpu-bind=mask_cpu:ff000000000000,ff00000000000000,ff0000,ff000000,ff,ff00,ff00000000,ff0000000000 \
  ${EXEC} parameter_file.txt |& tee app_output.log
