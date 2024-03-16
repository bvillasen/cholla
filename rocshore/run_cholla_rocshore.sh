#!/bin/bash

rocshore_dir=$(pwd)
cholla_dir="$(dirname "$rocshore_dir")"
echo "Cholla dir: ${cholla_dir}"

echo "Seting MI300A environment"
source ${cholla_dir}/builds/setup.mi300.sh

cholla_exec=$(find . -name 'cholla*')
echo "Cholla executable: ${cholla_exec}"cat s


# run_cmd="mpirun -n 1 ${cholla_exec} parameter_file.txt > simulation_output.log"
run_cmd="$OMPI_DIR/bin/mpirun -n 1 --mca osc ucx --mca pml ucx -x UCX_RNDV_THRESH=2048 ${cholla_exec} parameter_file.txt > simulation_output.log"
echo "Run command: ${run_cmd}"
$run_cmd

# Parse FOM
# average_timestep="$(grep "Time Total" simulation_output.log | tail -1 | awk -F: '{print $2}')"
# n_steps="$(grep "Average Times" simulation_output.log  | awk -F: '{print $2}')"
# echo "n steps: ${n_steps}"
# echo "average timestep: ${average_timestep}"