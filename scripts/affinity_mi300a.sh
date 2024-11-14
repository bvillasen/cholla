#!/bin/bash

if [[ -n ${OMPI_COMM_WORLD_LOCAL_RANK+z} ]]; then  
    export MPI_RANK=${OMPI_COMM_WORLD_LOCAL_RANK}   
    export MPI_SIZE=${OMPI_COMM_WORLD_LOCAL_SIZE} 
elif [[ -n "${SLURM_LOCALID+z}" ]]; then 
    export MPI_RANK=${SLURM_LOCALID} 
    export MPI_SIZE=${SLURM_NTASKS}
fi 
echo "MPI_RANK: $MPI_RANK  MPI_SIZE: $MPI_SIZE" 


if [ -z "${RANK_STRIDE}" ]; then
    let RANK_STRIDE=96/${MPI_SIZE}
fi

if [ -z "${OMP_STRIDE}" ]; then
    let OMP_STRIDE=1
fi

if [ -z "${NUM_GPUS}" ]; then
    let NUM_GPUS=4
fi

if [ -z "${CPU_SHIFT}" ]; then
    let CPU_SHIFT=0
fi

if [ -z "${GPU_START}" ]; then
    let GPU_START=0
fi

if [ -z "${GPU_STRIDE}" ]; then
    let GPU_STRIDE=1
fi

if [ -z "${EXTRA_CPU}" ]; then
    let EXTRA_CPU=0
fi

if [ -z "${OMP_NUM_THREADS}" ]; then
            export OMP_NUM_THREADS=1
fi


APU_LIST=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23)
NUMA_LIST_SPX=(0 1 2 3)

let num_chiplets=12
let ranks_per_chiplet=$(((${MPI_SIZE}+${num_chiplets}-1)/${num_chiplets}))

let chiplet_ID=$(((${MPI_RANK})/${ranks_per_chiplet}))

let ranks_per_gpu=$(((${MPI_SIZE}+${NUM_GPUS}-1)/${NUM_GPUS}))
# echo $ranks_per_gpu
let my_gpu=$(($MPI_RANK*$GPU_STRIDE/$ranks_per_gpu))+${GPU_START}

let cpu_start=$(($RANK_STRIDE*$MPI_RANK))+${GPU_START}+${CPU_SHIFT}
let cpu_stop=$(($cpu_start+$OMP_NUM_THREADS*$OMP_STRIDE-1))+${EXTRA_CPU}
export GOMP_CPU_AFFINITY=$cpu_start-$cpu_stop:$OMP_STRIDE
#export OMP_PLACES="{$cpu_start:$OMP_NUM_THREADS:$OMP_STRIDE}"

export ROCR_VISIBLE_DEVICES=${APU_LIST[$my_gpu]}
# export HIP_VISIBLE_DEVICES=${APU_LIST[$my_gpu]}


echo "rank_local= " $MPI_RANK "  GOMP_CPU_AFFINITY= " $GOMP_CPU_AFFINITY "  ROCR_VISIBLE_DEVICES= " $ROCR_VISIBLE_DEVICES " chiplet_ID= " $chiplet_ID
#echo "rank_local= " $OMPI_COMM_WORLD_LOCAL_RANK "  OMP_PLACES= " $OMP_PLACES "  ROCR_VISIBLE_DEVICES= " $ROCR_VISIBLE_DEVICES

echo "eval: numactl -C $cpu_start-$cpu_stop  -m ${NUMA_LIST_SPX[$my_gpu]} $*"
eval "numactl -C $cpu_start-$cpu_stop  -m ${NUMA_LIST_SPX[$my_gpu]} $*"

#eval "taskset -c $cpu_start-$cpu_stop $*"

#$@

