


lockhart='''#!/bin/bash
SBATCH_PARTITION
#SBATCH -J JOB_NAME
#SBATCH --time=N_HRS:00:00
#SBATCH --no-requeue
#SBATCH --nodes=N_NODES
#SBATCH --ntasks-per-node=N_TASK_PER_NODE
#SBATCH --gpus-per-node=N_GPU_PER_NODE
#SBATCH --threads-per-core=N_THREADS_PER_CORE
#SBATCH -D WORKDIR
#SBATCH -e WORKDIR/job_error.log
#SBATCH -o WORKDIR/job_output.log
#SBATCH --exclusive
SLURM_OPTIONS

echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"

SLURM_SCRIPT_CONTENT

echo "Finished SLURM job. $(date)"
'''

conductor='''#!/bin/bash

echo "Starting job. $(date)"

SLURM_SCRIPT_CONTENT

echo "Finished job. $(date)"
'''

frontier='''#!/bin/bash
#SBATCH -A ven114
#SBATCH -J JOB_NAME
#SBATCH --time=N_HRS:00:00
#SBATCH --no-requeue
#SBATCH --nodes=N_NODES
#SBATCH --ntasks-per-node=N_TASK_PER_NODE
#SBATCH --gpus-per-node=N_GPU_PER_NODE
#SBATCH --threads-per-core=N_THREADS_PER_CORE
#SBATCH -D WORKDIR
#SBATCH -e WORKDIR/job_error.log
#SBATCH -o WORKDIR/job_output.log
SLURM_OPTIONS

echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"

SLURM_SCRIPT_CONTENT

rocm-smi

echo "Finished SLURM job. $(date)"
'''

conductor='''#!/bin/bash

echo "Starting job. $(date)"

SLURM_SCRIPT_CONTENT

echo "Finished job. $(date)"
'''
