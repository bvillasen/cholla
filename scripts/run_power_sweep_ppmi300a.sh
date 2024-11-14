#!/bin/bash 

CHOLLA_DIR=$HOME/code/cholla
source $CHOLLA_DIR/builds/setup.pp_mi300a.sh
EXE=$CHOLLA_DIR/bin/cholla.hydro.pp_mi300a

base_dir=$PWD/power_sweep
mkdir -p $base_dir

for pow in 550 500 450 400 350 300 250 200 150
do
  echo
  echo Running with gpu max power : $pow

  run_dir=$base_dir/power_$pow
  mkdir -p $run_dir

  echo "y" | rocm-smi --setpoweroverdrive $pow

  #Show current max power
  rocm-smi --showmaxpower > $run_dir/max_power.txt

  # Collect power profile
  echo "Starting power profiler $(date)"
  POWER_PROFILER=/home/bvillase/code/power_analysis/power_profiler/power_profiler
  taskset -c 1 $POWER_PROFILER $run_dir/power_profile.txt 300 10 &

  export HSA_ENABLE_SDMA=0

  echo "Starting application $(date)"
  export OMP_NUM_THREADS=1
  $OMPI_DIR/bin/mpirun -n 4 --mca pml ucx -x UCX_PROTO_ENABLE=n -x UCX_ROCM_COPY_LAT=2e-6 -x UCX_ROCM_IPC_MIN_ZCOPY=4096 \
        $CHOLLA_DIR/scripts/affinity_mi300a.sh $EXE parameter_file.txt > $run_dir/simulation_output.log

  echo "Finished application $(date)"

  # Stop the power profile banckground processes
  echo "Stoping power profiler $(date)"
  pkill -f power_profiler

done
echo "Resetting power setting"
rocm-smi --resetpoweroverdrive
rocm-smi --showmaxpower