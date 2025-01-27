#!/bin/bash

export MPI_RANK=${SLURM_PROCID} 
export MPI_SIZE=${SLURM_NPROCS}
echo "MPI_RANK: $MPI_RANK  MPI_SIZE: $MPI_SIZE"

rocm-smi

# if [ $(( $MPI_RANK % $MPI_SIZE )) -eq 0 ]; then
#     NODE=$(expr $MPI_RANK / $MPI_SIZE)
#     echo "Rank: $MPI_RANK   Node: $NODE Starting power_profiler $(date)"
#     taskset -c 1  $HOME/code/power_analysis/power_profiler/power_profiler --output power_profile_${NODE}.txt --time 6000  --sampling_freq 10 --get_cray_pm &
# fi



$CHOLLA_EXEC $CHOLLA_PARAMETER_FILE



# if [ $(( $MPI_RANK % $MPI_SIZE )) -eq 0 ]; then
#     NODE=$(expr $MPI_RANK / $MPI_SIZE)
#     echo "Rank: $MPI_RANK   Node: $NODE Stopping power_profiler $(date)" 
#     pkill -f power_profiler 
# fi
