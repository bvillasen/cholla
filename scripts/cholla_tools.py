

def generate_parameter_file( problem_type, gpu_type, n_mpi, work_dir, file_name, simulation_time=1.0):
  print( "Generating cholla parameter file...")
  print( f"n_mpi: {n_mpi}")
  print( f"work_dir: {work_dir}")
  print( f"file_name: {file_name}")

  if gpu_type == 'mi250x': 
    nx_base = 256
    Lx_base = 1.0
  elif gpu_type == 'mi300a': 
    nx_base = 512
    Lx_base = 2.0
  elif gpu_type == 'mi300x': 
    nx_base = 512
    Lx_base = 2.0  
  else: 
    nx_base = 256
    Lx_base = 1.0

  ny_base = 512
  nz_base = 256 

  Ly_base = 2.0
  Lz_base = 1.0





  nx = n_mpi * nx_base
  ny = ny_base
  nz = nz_base

  Lx = n_mpi * Lx_base
  Ly = Ly_base
  Lz = Lz_base

  run_time = simulation_time

  ics_type = 'Spherical_Overdensity_3D'
  # ics_type = 'Uniform'

  params_hydro=f'''#
# Parameter File for the 3D Hydrodynamics.
#

######################################
# number of grid cells in the x dimension
nx={nx}
# number of grid cells in the y dimension
ny={ny}
# number of grid cells in the z dimension
nz={nz}
# output time
tout={run_time}
# how often to output
outstep=100
# value of gamma
gamma=1.66666667
# name of initial conditions
init={ics_type}
# domain properties
xmin=0.0
ymin=0.0
zmin=0.0
xlen={Lx}
ylen={Ly}
zlen={Lz}
# type of boundary conditions
xl_bcnd=1
xu_bcnd=1
yl_bcnd=1
yu_bcnd=1
zl_bcnd=1
zu_bcnd=1
# density and temperature floors
density_floor=0.00001
temperature_floor=0.1
# path to output directory
outdir={work_dir}/snapshot_files/
'''

  if problem_type == 'hydro':  parameters = params_hydro
  elif problem_type == 'gravity':  parameters = params_hydro
  elif problem_type == 'particles':  parameters = params_hydro
  else: 
    print(f"ERROR: problem type: {problem_type} is not valid")

  file = open( f'{work_dir}/{file_name}', 'w' )
  file.write( parameters )
  file.close()
  print( f"Saved file: {work_dir}/{file_name}")
