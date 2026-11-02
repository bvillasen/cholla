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

echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
start_time=$(date +%s)
echo "Starting SLURM job. $(date)"

CHOLLA_ROOT=/home1/bvillase/code/cholla_cosmology
# UCX is the OpenMPI 5 transport, so use the OpenMPI environment + binary.
source ${CHOLLA_ROOT}/builds/setup.hpcfund.sh
module list

OMPI_ROOT=/home1/bvillase/util/openmpi/rocm7.2.0/install/ompi


EXEC=${CHOLLA_ROOT}/bin/cholla.cosmology.lockhart_mi250x_openmpi

# GPU-aware MPI over UCX (OpenMPI 5):
#   --mca pml ucx / --mca osc ucx : force the UCX point-to-point + one-sided paths
#   UCX_TLS=self,sm,rocm          : enable ROCm device transports (rocm_copy/rocm_ipc)
#                                   alongside shared-memory + self for intra-node
#   UCX_MEMTYPE_CACHE=n           : avoid stale memtype cache hits with device memory
# These require a UCX that was built with ROCm support.
#
# mpirun only PLACES the 8 ranks (one per GCD); the wrapper does the actual
# CPU + GPU binding per rank so the affinity matches the srun --cpu-bind=mask_cpu
# + --gpu-bind=closest layout exactly.
${OMPI_ROOT}/bin/mpirun -n 8 \
  --mca osc ucx -mca pml ucx -x UCX_TLS=sm,self,rocm_copy,rocm_ipc
  ${EXEC} parameter_file.txt |& tee app_output.log
  # ${CHOLLA_ROOT}/slurm/bind_mi250x.sh \
