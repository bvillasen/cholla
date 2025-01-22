import os
import sys
import shutil
import time
import argparse
import slurm_templates as slurm_templates   
import cholla_tools as tools

CHOLLA_ROOT = os.getenv('CHOLLA_ROOT', None)
if not CHOLLA_ROOT:
  print("The CHOLLA_ROOT environment variable should be set ")
  print("Did you remember to `source scripts/set_env.sh` in the cholla directory ?")
  sys.exit(1)

CHOLLA_GPU_TYPE = os.getenv('CHOLLA_GPU_TYPE', None)

n_hrs = 1
n_threads_per_core = 1

use_omnistat = False

parser = argparse.ArgumentParser( description="Cholla SLURM script generator.")
parser.add_argument('--system', dest='system', type=str, help='System for the run.', default=None )
parser.add_argument('--type', dest='type', type=str, help='Problem type, for example hydro or particles', default='hydro' )
parser.add_argument('--n_nodes', dest='n_nodes', type=int, help='Number of nodes for the run.', default=1 )
parser.add_argument('--n_mpi', dest='n_mpi', type=int, help='Number of MPI ranks per node for the run.', default=1 )
parser.add_argument('--work_dir', dest='work_dir', type=str, help='Path of the work directory.', default=None )
parser.add_argument('--use_nodes', dest='use_nodes', nargs='+', help='List of nodes to use for the run.', default=None )
parser.add_argument('--exclude_nodes', dest='exclude_nodes', nargs='+', help='List of nodes to exclude for the run.', default=None )
parser.add_argument('--profiler', dest='profiler', type=str, help='Type of profiler to use', default=None )
parser.add_argument('--power_cap', dest='power_cap', type=int, help='Set GPU power cap', default=None )
parser.add_argument('--use_omnistat', dest='use_omnistat', type=bool, help='Use omnistat for the run', default=False )
args = parser.parse_args()

system = args.system
if system is None:
  print( 'ERROR: parameter `--system` has to be specified ')
  exit(1)

p_type = args.type

work_dir = args.work_dir
if work_dir is None:
  print( 'ERROR: parameter `--work_dir` has to be specified ')
  exit(1)
  
profiler = ''
if args.profiler is not None:
  if args.profiler == 'rocprofv3_stats': profiler = args.profiler
  else:
    print( f'ERROR: Invalid profiler: {args.profiler}')
    sys.exit(1)


n_nodes = args.n_nodes
n_mpi_per_node = args.n_mpi
n_mpi_total = n_nodes * n_mpi_per_node
job_name = f'c-{p_type}_N{n_nodes}' 
use_nodes = args.use_nodes
exclude_nodes = args.exclude_nodes
power_cap = args.power_cap
use_omnistat = args.use_omnistat

if not os.path.isdir(work_dir): os.mkdir(work_dir)
run_base_name = 'run'
run_dir = f'{work_dir}/{run_base_name}_nnodes{n_nodes}_nmpi{n_mpi_total}'
if power_cap is not None: run_dir += f'_powercap{power_cap}'
if not os.path.isdir(run_dir): os.mkdir(run_dir)
work_dir = run_dir

use_slurm = True
if system == 'lockhart_mi250x':
  slurm_template = slurm_templates.lockhart
  slurm_partition = ""
  n_gpu_per_node = 8
  slurm_options = ''
elif system == 'frontier':
  slurm_template = slurm_templates.frontier
  slurm_partition = ""
  n_gpu_per_node = 8
  slurm_options = ''
  if power_cap is not None: slurm_options += f'#SBATCH --gpu-power-cap={power_cap}'  
else:
  print(f'ERROR: System {system} is not supported.')
  exit(1)

if use_nodes is not None:
  nodes_list = ''
  for node in use_nodes:
    nodes_list += f'{node},'
  slurm_options += f'#SBATCH -w {nodes_list[:-1]} \n'

if exclude_nodes is not None:
  nodes_list = ''
  for node in exclude_nodes:
    nodes_list += f'{node},'
  slurm_options += f'#SBATCH --exclude {nodes_list[:-1]} \n'

print(f'system: {system}' )
print(f'GPU type: {CHOLLA_GPU_TYPE}' )
print(f'problem type: {p_type}' )
print(f'n_nodes: {n_nodes}' )
print(f'n_mpi_per_node: {n_mpi_per_node}' )
print(f'use_nodes: {use_nodes}' )
print(f'exclude_nodes: {exclude_nodes}' )
if profiler is not None: print(f'profiler: {profiler}' )
if power_cap is not None: print(f'power_cap: {power_cap}' )
print(f'use_omnistat: {use_omnistat}' )

# Generate parameter file
parameter_file_name = 'parameter_file.txt' 
tools.generate_parameter_file( p_type, CHOLLA_GPU_TYPE, n_mpi_total, work_dir, parameter_file_name )


set_env_command = f'''
# Set the Cholla environment
export CHOLLA_ROOT={CHOLLA_ROOT}
SYSTEM={system} source {CHOLLA_ROOT}/scripts/set_env.sh
'''

app_run_cmd = f'''
# Call application run script
echo "Starting app run. $(date)"
PROBLEM_TYPE=P_TYPE N_MPI=NMPI WORK_DIR=WORKDIR PARAMETER_FILE={parameter_file_name} PROFILER={profiler} bash {CHOLLA_ROOT}/scripts/run_app.sh
echo "Finished app run. $(date)"
'''

start_omnistat= '''
export OMNISTAT_VICSERVER_DATADIR=/tmp/omnistat/${SLURM_JOB_ID}
ml use /autofs/nccs-svm1_sw/crusher/amdsw/modules
ml omnistat
omnistat-usermode --start --interval 1
'''

stop_omnistat = '''
omnistat-usermode --stopexporters
omnistat-query --job ${SLURM_JOB_ID} --interval 1 --pdf omnistat.${SLURM_JOB_ID}.pdf
omnistat-usermode --stopserver
mv /tmp/omnistat/${SLURM_JOB_ID} data_omnistat.${SLURM_JOB_ID}
'''

slurm_script_content = set_env_command
if use_omnistat: slurm_script_content += start_omnistat
slurm_script_content += app_run_cmd
if use_omnistat: slurm_script_content += stop_omnistat



slurm_script = slurm_template 
slurm_script = slurm_script.replace( 'SLURM_SCRIPT_CONTENT', slurm_script_content)
slurm_script = slurm_script.replace( 'SBATCH_PARTITION', slurm_partition )
slurm_script = slurm_script.replace( 'JOB_NAME', job_name )
slurm_script = slurm_script.replace( 'P_TYPE', p_type )
slurm_script = slurm_script.replace( 'NMPI', str(n_mpi_total) )
slurm_script = slurm_script.replace( 'N_HRS', str(n_hrs) )
slurm_script = slurm_script.replace( 'N_NODES', str(n_nodes) )
slurm_script = slurm_script.replace( 'N_TASK_PER_NODE', str(n_mpi_per_node) )
slurm_script = slurm_script.replace( 'N_GPU_PER_NODE', str(n_gpu_per_node) )
slurm_script = slurm_script.replace( 'N_THREADS_PER_CORE', str(n_threads_per_core) )
slurm_script = slurm_script.replace( 'SLURM_OPTIONS', slurm_options )
slurm_script = slurm_script.replace( 'WORKDIR', work_dir )

file_name = f'{work_dir}/submit_job.slurm'
file = open( file_name, 'w' )
file.write( slurm_script )
file.close()
time.sleep(0.5)
print(f'Saved file: {file_name}')

if use_slurm: submit_cmnd = f'sbatch {file_name}'
else: submit_cmnd = f'bash {file_name}'
print( f'Submitting job: {file_name}' )
if use_slurm: os.system( submit_cmnd )
