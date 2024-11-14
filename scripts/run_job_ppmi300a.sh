#!/bin/bash 

CHOLLA_DIR=$HOME/code/cholla
source $CHOLLA_DIR/builds/setup.pp_mi300a.sh
EXE=$CHOLLA_DIR/bin/cholla.hydro.pp_mi300a

# Collect power profile
echo "Starting power profiler $(date)"
POWER_PROFILER=/home/bvillase/code/power_analysis/power_profiler/power_profiler
taskset -c 1 $POWER_PROFILER power_profile.txt 300 100 &

export HSA_ENABLE_SDMA=0

echo "Starting application $(date)"
export OMP_NUM_THREADS=1
$OMPI_DIR/bin/mpirun -n 4 --mca pml ucx -x UCX_PROTO_ENABLE=n -x UCX_ROCM_COPY_LAT=2e-6 -x UCX_ROCM_IPC_MIN_ZCOPY=4096 \
       $CHOLLA_DIR/scripts/affinity_mi300a.sh $EXE parameter_file.txt > simulation_output.log

echo "Finished application $(date)"

# Stop the power profile banckground processes
echo "Stoping power profiler $(date)"
pkill -f power_profiler