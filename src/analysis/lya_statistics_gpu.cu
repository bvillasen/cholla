#ifdef ANALYSIS
#ifdef LYA_STATISTICS
#ifdef GPU_LYA_FLUX

#include <stdio.h>
#include "../io/io.h"
#include "../utils/gpu.hpp"
#include "../global/global_cuda.h"
#include "../analysis/analysis.h"

#define TPB_LYA_FLUX 512


void Extend_Periodic_Field( int n_skewers, int field_size, int n_ghost, Real *field, Real *field_extended ){
  
  int n_los_total, n_los_full;
  n_los_total = field_size;
  n_los_full = field_size + 2 * n_ghost;
  
  // Fill the Real cells first
  for (int skewer_id=0; skewer_id<n_skewers; skewer_id++){
    for (int los_id=0; los_id<n_los_total; los_id++ ){
      field_extended[skewer_id*n_los_full + los_id + n_ghost] = field[ skewer_id*n_los_total + los_id ];
    }
  }
  
  // Fill the ghost cells
  for (int skewer_id=0; skewer_id<n_skewers; skewer_id++){
    for ( int los_id=0; los_id<n_ghost; los_id++ ){
      field_extended[skewer_id*n_los_full + los_id] = field[skewer_id*n_los_total + n_los_total - n_ghost + los_id];
      field_extended[skewer_id*n_los_full + n_los_full - n_ghost + los_id] = field[skewer_id*n_los_total + los_id];  
    }
  }
}

// __global__ void Compute_Skewers_Optical_Depth_kernel( int n_skewers, int n_los, int n_ghost, Real dens_factor, Real vel_factor, Real temp_factor, Real dv_Hubble, Real Lya_sigma, 
//                                                   Real *skewers_density, Real *skewers_velocity, Real *skewers_temperature, Real *skewers_optical_depth )
// {                                                    
//   int global_id, los_id, skewer_id, los_id_loop, id_in_block, n_loop, n_in_block;
//   global_id = threadIdx.x + blockIdx.x * blockDim.x;                                                  
//   if ( global_id >= n_skewers * n_los ) return;                                           
//   skewer_id = global_id / n_los;
//   los_id = global_id % n_los;
//   id_in_block = threadIdx.x; 
//   n_in_block = blockDim.x;
//   n_loop = ( n_los - 1 ) / n_in_block + 1;
// 
//   Real density, velocity, doppler_b, tau, vel_Hubble, y_l, y_r;
// 
//   tau = 0;
//   vel_Hubble = ( static_cast<Real>(los_id - n_ghost) + 0.5 ) * dv_Hubble;
// 
//   __shared__ Real sh_density[TPB_LYA_FLUX];
//   __shared__ Real sh_velocity[TPB_LYA_FLUX];
//   __shared__ Real sh_doppler_b[TPB_LYA_FLUX];
//   int counter = 0;  
//   for ( int loop_id=0; loop_id<n_loop; loop_id++ ){
//     los_id_loop = loop_id*n_in_block + id_in_block;
//     if ( los_id_loop >= n_los ) break;    
// 
//     sh_density[id_in_block]   = skewers_density[skewer_id*n_los + los_id_loop] * dens_factor;
//     sh_velocity[id_in_block]  = ( los_id_loop - n_ghost + 0.5 ) * dv_Hubble + skewers_velocity[skewer_id*n_los + los_id_loop] * vel_factor;
//     sh_doppler_b[id_in_block] = sqrt(skewers_temperature[skewer_id*n_los + los_id_loop] * temp_factor);
//     __syncthreads();
// 
//     for (int i=0; i<n_in_block; i++){
//       if ( loop_id*n_in_block + i >= n_los ) break;
//       counter += 1;
//       // if ( skewer_id == 1  ) printf(" tau skewer 1: %e\n", tau );    
//       density   = sh_density[i] ;
//       velocity  = sh_velocity[i] ;
//       doppler_b = sh_doppler_b[i];
//       y_l = ( vel_Hubble - 0.5*dv_Hubble - velocity ) / doppler_b;
//       y_r = ( vel_Hubble + 0.5*dv_Hubble - velocity ) / doppler_b;
//       tau += density * ( erf(y_r) - erf(y_l) ) / 2;    
//     }
//   }
// 
//   skewers_optical_depth[global_id] = tau * Lya_sigma;
//   if (counter != 306)  printf(" skewer_id: %d   los_id: %d  counter %d n_loop: %d \n", skewer_id, los_id, counter, n_loop );
// 
// }

__global__ void Compute_Skewers_Optical_Depth_kernel( int n_skewers, int n_los, int n_ghost, Real dens_factor, Real vel_factor, Real temp_factor, Real dv_Hubble, Real Lya_sigma, 
                                                  Real *skewers_density, Real *skewers_velocity, Real *skewers_temperature, Real *skewers_optical_depth )
{                                                    
  int global_id, los_id, skewer_id, los_id_loop, id_in_block, n_loop, n_in_block;
                                                    
  los_id = threadIdx.x + blockIdx.x * blockDim.x;
  if ( los_id >= n_los ) return;                                           
  skewer_id = threadIdx.y + blockIdx.y * blockDim.y;
  if ( skewer_id >= n_skewers ) return;
  global_id = skewer_id * n_los + los_id;                                           
  id_in_block = threadIdx.x; 
  n_in_block = blockDim.x;
  n_loop = ( n_los - 1 ) / n_in_block + 1;
  
  Real density, velocity, doppler_b, tau, vel_Hubble, y_l, y_r;
  
  tau = 0;
  vel_Hubble = ( static_cast<Real>(los_id - n_ghost) + 0.5 ) * dv_Hubble;
  
  __shared__ Real sh_density[TPB_LYA_FLUX];
  __shared__ Real sh_velocity[TPB_LYA_FLUX];
  __shared__ Real sh_doppler_b[TPB_LYA_FLUX];
  int counter = 0;  
  for ( int loop_id=0; loop_id<n_loop; loop_id++ ){
    los_id_loop = loop_id*n_in_block + id_in_block;
    if ( los_id_loop >= n_los ) break;    
  
    sh_density[id_in_block]   = skewers_density[skewer_id*n_los + los_id_loop] * dens_factor;
    sh_velocity[id_in_block]  = ( los_id_loop - n_ghost + 0.5 ) * dv_Hubble + skewers_velocity[skewer_id*n_los + los_id_loop] * vel_factor;
    sh_doppler_b[id_in_block] = sqrt(skewers_temperature[skewer_id*n_los + los_id_loop] * temp_factor);
    __syncthreads();
  
    for (int i=0; i<n_in_block; i++){
      if ( loop_id*n_in_block + i >= n_los ) break;
      counter += 1;
      // if ( skewer_id == 1  ) printf(" tau skewer 1: %e\n", tau );    
      density   = sh_density[i] ;
      velocity  = sh_velocity[i] ;
      doppler_b = sh_doppler_b[i];
      y_l = ( vel_Hubble - 0.5*dv_Hubble - velocity ) / doppler_b;
      y_r = ( vel_Hubble + 0.5*dv_Hubble - velocity ) / doppler_b;
      tau += density * ( erf(y_r) - erf(y_l) ) / 2;    
    }
  }
  
  skewers_optical_depth[global_id] = tau * Lya_sigma;
  // if (counter != 306)  printf(" skewer_id: %d   los_id: %d  counter %d n_loop: %d \n", skewer_id, los_id, counter, n_loop );
                                                  
}


__global__ void Compute_Skewers_Transmitted_Flux_kernel( int n_skewers, int n_los_real, int n_ghost, Real *skewers_optical_depth, Real *skewers_transmitted_flux ){
  
  int global_id, skewer_id, los_id, n_los_full;
  global_id = threadIdx.x + blockIdx.x * blockDim.x;                                                  
  if ( global_id >= n_skewers * n_los_real ) return;                                           
  skewer_id = global_id / n_los_real;
  los_id = global_id % n_los_real;
  n_los_full = n_los_real + 2 * n_ghost;
  
  skewers_transmitted_flux[global_id] = exp( - skewers_optical_depth[ skewer_id*n_los_full + los_id + n_ghost] );  
}

void Grid3D::Compute_Transmitted_Flux_Skewers_single_chem_GPU( int axis, int chem_type ){
  
  int n_los_full, n_los_real, n_ghost, n_skewers;
  bool am_I_root;
  Real *skewers_density;
  Real *skewers_velocity;
  Real *skewers_temperature;
  Real *host_skewers_density;
  Real *host_skewers_velocity;
  Real *host_skewers_temperature;
  Real *host_skewers_transmitted_flux;
  Real *dev_skewers_density;
  Real *dev_skewers_velocity;
  Real *dev_skewers_temperature;
  Real *dev_skewers_optical_depth;
  Real *dev_skewers_transmitted_flux;
  Real Lbox, delta_x;
  Real *flux_mean_root;
  
  if ( chem_type != 0 && chem_type != 1 ){
    printf( "ERROR: Incorrect chem_type for GPU Lya flux. Values are 0 for HI and 1 for HeII \n");
    exit(-1);
  }
  
  n_ghost = Analysis.n_ghost_skewer;
  
  if ( axis == 0 ){
    Lbox    = Analysis.Lbox_x;
    delta_x = Analysis.dx;
    am_I_root  = Analysis.am_I_root_x;
    n_skewers  = Analysis.n_skewers_local_x; 
    n_los_full = Analysis.n_los_full_x;
    n_los_real = Analysis.nx_total;
    if (chem_type == 0) skewers_density = Analysis.skewers_HI_density_root_x;
    if (chem_type == 1) skewers_density = Analysis.skewers_HeII_density_root_x;
    skewers_velocity = Analysis.skewers_velocity_root_x;
    skewers_temperature = Analysis.skewers_temperature_root_x;  
    host_skewers_density = Analysis.host_skewers_density_x;  
    host_skewers_velocity = Analysis.host_skewers_velocity_x;
    host_skewers_temperature = Analysis.host_skewers_temperature_x;
    // host_skewers_transmitted_flux = Analysis.host_skewers_transmitted_flux_x;
    if ( chem_type == 0 ) host_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HI_x;
    if ( chem_type == 1 ) host_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HeII_x;
    dev_skewers_density = Analysis.dev_skewers_density_x;  
    dev_skewers_velocity = Analysis.dev_skewers_velocity_x;
    dev_skewers_temperature = Analysis.dev_skewers_temperature_x;
    dev_skewers_optical_depth = Analysis.dev_skewers_optical_depth_x;
    dev_skewers_transmitted_flux = Analysis.dev_skewers_transmitted_flux_x;
    if (chem_type == 0) flux_mean_root = &Analysis.Flux_mean_root_HI_x;
    if (chem_type == 1) flux_mean_root = &Analysis.Flux_mean_root_HeII_x;
  }
  
  if ( axis == 1 ){
    Lbox    = Analysis.Lbox_y;
    delta_x = Analysis.dy;
    am_I_root  = Analysis.am_I_root_y;
    n_skewers  = Analysis.n_skewers_local_y; 
    n_los_full = Analysis.n_los_full_y;
    n_los_real = Analysis.ny_total;
    if (chem_type == 0) skewers_density = Analysis.skewers_HI_density_root_y;
    if (chem_type == 1) skewers_density = Analysis.skewers_HeII_density_root_y;
    skewers_velocity = Analysis.skewers_velocity_root_y;
    skewers_temperature = Analysis.skewers_temperature_root_y;  
    host_skewers_density = Analysis.host_skewers_density_y;  
    host_skewers_velocity = Analysis.host_skewers_velocity_y;
    host_skewers_temperature = Analysis.host_skewers_temperature_y;
    // host_skewers_transmitted_flux = Analysis.host_skewers_transmitted_flux_y;
    if ( chem_type == 0 ) host_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HI_y;
    if ( chem_type == 1 ) host_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HeII_y;
    dev_skewers_density = Analysis.dev_skewers_density_y;  
    dev_skewers_velocity = Analysis.dev_skewers_velocity_y;
    dev_skewers_temperature = Analysis.dev_skewers_temperature_y;
    dev_skewers_optical_depth = Analysis.dev_skewers_optical_depth_y;
    dev_skewers_transmitted_flux = Analysis.dev_skewers_transmitted_flux_y;
    if (chem_type == 0) flux_mean_root = &Analysis.Flux_mean_root_HI_y;
    if (chem_type == 1) flux_mean_root = &Analysis.Flux_mean_root_HeII_y;
  }
  
  if ( axis == 2 ){
    Lbox    = Analysis.Lbox_z;
    delta_x = Analysis.dz;
    am_I_root  = Analysis.am_I_root_z;
    n_skewers  = Analysis.n_skewers_local_z; 
    n_los_full = Analysis.n_los_full_z;
    n_los_real = Analysis.nz_total;
    if (chem_type == 0) skewers_density = Analysis.skewers_HI_density_root_z;
    if (chem_type == 1) skewers_density = Analysis.skewers_HeII_density_root_z;
    skewers_velocity = Analysis.skewers_velocity_root_z;
    skewers_temperature = Analysis.skewers_temperature_root_z;  
    host_skewers_density = Analysis.host_skewers_density_z;  
    host_skewers_velocity = Analysis.host_skewers_velocity_z;
    host_skewers_temperature = Analysis.host_skewers_temperature_z;
    // host_skewers_transmitted_flux = Analysis.host_skewers_transmitted_flux_z;
    if ( chem_type == 0 ) host_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HI_z;
    if ( chem_type == 1 ) host_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HeII_z;
    dev_skewers_density = Analysis.dev_skewers_density_z;  
    dev_skewers_velocity = Analysis.dev_skewers_velocity_z;
    dev_skewers_temperature = Analysis.dev_skewers_temperature_z;
    dev_skewers_optical_depth = Analysis.dev_skewers_optical_depth_z;
    dev_skewers_transmitted_flux = Analysis.dev_skewers_transmitted_flux_z;
    if (chem_type == 0) flux_mean_root = &Analysis.Flux_mean_root_HI_z;
    if (chem_type == 1) flux_mean_root = &Analysis.Flux_mean_root_HeII_z;
  }
  
  if ( !am_I_root ) return;
  
  // Constants in CGS
  Real Msun, kpc, Mp, kpc3, Me, e_charge, c, Kb;
  Kb   = 1.38064852e-16; //g (cm/s)^2 K-1
  Msun = 1.98847e33;     //g
  Mp   = 1.6726219e-24;  //g
  Me   = 9.10938356e-28; //g
  c    = 2.99792458e10;    //cm/s
  kpc  = 3.0857e21;        //cm
  kpc3 = kpc * kpc * kpc;
  e_charge =  4.8032e-10;  // cm^3/2 g^1/2 s^-1  

  Extend_Periodic_Field(  n_skewers, n_los_real, n_ghost, skewers_density, host_skewers_density );
  Extend_Periodic_Field(  n_skewers, n_los_real, n_ghost, skewers_velocity, host_skewers_velocity );
  Extend_Periodic_Field(  n_skewers, n_los_real, n_ghost, skewers_temperature, host_skewers_temperature );
  
  int size_skewers_field_full = n_skewers * n_los_full;
  CudaSafeCall( cudaMemcpy(dev_skewers_density,     host_skewers_density,     size_skewers_field_full*sizeof(Real), cudaMemcpyHostToDevice ) ) ;
  CudaSafeCall( cudaMemcpy(dev_skewers_velocity,    host_skewers_velocity,    size_skewers_field_full*sizeof(Real), cudaMemcpyHostToDevice ) );
  CudaSafeCall( cudaMemcpy(dev_skewers_temperature, host_skewers_temperature, size_skewers_field_full*sizeof(Real), cudaMemcpyHostToDevice ) );
  
  Real dens_factor_cosmo, dens_factor_HI, dens_factor_HeII, dens_factor, vel_factor;
  dens_factor_cosmo = 1. / ( Cosmo.current_a * Cosmo.current_a * Cosmo.current_a ) * Cosmo.cosmo_h * Cosmo.cosmo_h; 
  dens_factor_HI   = dens_factor_cosmo * Msun / ( kpc3 ) / Mp;
  dens_factor_HeII = dens_factor_cosmo * Msun / ( kpc3 ) / (4*Mp);
  vel_factor = 1e5; //cm/s
  // Conversion from comoving density to physical number density in units 1/cm^3 
  if ( chem_type == 0) dens_factor = dens_factor_HI;
  if ( chem_type == 1) dens_factor = dens_factor_HeII;
  
  // Get Cosmological variables
  Real H, current_a, L_proper, dx_proper, dv_Hubble; 
  Real H_cgs, Lya_lambda_HI, f_12, Lya_sigma_HI;
  Real Lya_lambda_HeII, Lya_sigma_HeII, Lya_sigma;
  current_a = Cosmo.current_a;
  L_proper = Lbox * current_a / Cosmo.cosmo_h;
  dx_proper = delta_x * current_a / Cosmo.cosmo_h;
  H = Cosmo.Get_Hubble_Parameter( current_a );
  dv_Hubble = H * dx_proper * vel_factor; // cm/s
  
  Lya_lambda_HI   = 1.21567e-5;          // cm  Rest wave length of the Lyman Alpha Transition Hydrogen
  Lya_lambda_HeII = Lya_lambda_HI / 4;   // cm  Rest wave length of the Lyman Alpha Transition Helium II
  f_12 =  0.416;                         // Lya transition Oscillator strength
  H_cgs = H * 1e5 / kpc;
  
  Lya_sigma_HI   = M_PI * e_charge * e_charge / Me / c * Lya_lambda_HI   * f_12 / H_cgs;
  Lya_sigma_HeII = M_PI * e_charge * e_charge / Me / c * Lya_lambda_HeII * f_12 / H_cgs;   
  if ( chem_type == 0 ) Lya_sigma = Lya_sigma_HI;
  if ( chem_type == 1 ) Lya_sigma = Lya_sigma_HeII;
  
  Real temp_factor;
  if ( chem_type == 0 ) temp_factor = 2 * Kb / Mp;
  if ( chem_type == 1 ) temp_factor = 2 * Kb / (4*Mp);
    
  
  // Parameters for kernel launch
  int n_blocks_per_skewers = (n_los_full - 1) / TPB_LYA_FLUX + 1;
  dim3 dim2dGrid(n_blocks_per_skewers, n_skewers, 1);
  dim3 dim2dBlock(TPB_LYA_FLUX, 1, 1);  
  
  hipLaunchKernelGGL(Compute_Skewers_Optical_Depth_kernel, dim2dGrid, dim2dBlock, 0, 0, n_skewers, n_los_full, n_ghost, dens_factor, vel_factor, temp_factor,  
                     dv_Hubble, Lya_sigma, dev_skewers_density, dev_skewers_velocity, dev_skewers_temperature, dev_skewers_optical_depth );

  int ngrid = (n_skewers*n_los_real - 1) / TPB_LYA_FLUX + 1;
  dim3 dim1dGrid(ngrid, 1, 1);
  dim3 dim1dBlock(TPB_LYA_FLUX, 1, 1);  

  hipLaunchKernelGGL(Compute_Skewers_Transmitted_Flux_kernel, dim1dGrid, dim1dBlock, 0, 0, n_skewers, n_los_real, n_ghost, dev_skewers_optical_depth, dev_skewers_transmitted_flux );  
  
  int size_skewers_field_real = n_skewers * n_los_real;
  CudaSafeCall( cudaMemcpy(host_skewers_transmitted_flux, dev_skewers_transmitted_flux, size_skewers_field_real*sizeof(Real), cudaMemcpyDeviceToHost ) ) ;
  
  
  // Compute the mean transmitted flux
  Real  flux_mean = 0;
  for ( int skewer_id=0; skewer_id<n_skewers; skewer_id++ ){
    for ( int los_id=0; los_id<n_los_real; los_id++ ){
      flux_mean += host_skewers_transmitted_flux[skewer_id*n_los_real + los_id];
    }
  }
  flux_mean /= n_los_real;
  *flux_mean_root += flux_mean;
  
  
  // Real *cpu_skewers_transmitted_flux;
  // if ( axis == 0 && chem_type == 0 ) cpu_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HI_x;
  // if ( axis == 1 && chem_type == 0 ) cpu_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HI_y;
  // if ( axis == 2 && chem_type == 0 ) cpu_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HI_z;
  // if ( axis == 0 && chem_type == 1 ) cpu_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HeII_x;
  // if ( axis == 1 && chem_type == 1 ) cpu_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HeII_y;
  // if ( axis == 2 && chem_type == 1 ) cpu_skewers_transmitted_flux = Analysis.skewers_transmitted_flux_HeII_z;
  // 
  // 
  // Real diff;
  // for ( int skewer_id=0; skewer_id<n_skewers; skewer_id++ ){
  //   // if ( skewer_id > 1 ) continue;
  //   for ( int i=0; i< n_los_real; i++ ){
  //     diff =  host_skewers_transmitted_flux[skewer_id*n_los_real+i] / cpu_skewers_transmitted_flux[ skewer_id*n_los_real+i] - 1;
  //     if ( fabs( diff ) > 1e-11 ) printf(" skewer_id: %d  los_id: %d   gpu: %e   cpu: %e  diff: %e \n", skewer_id, i, host_skewers_transmitted_flux[skewer_id*n_los_real+i],  cpu_skewers_transmitted_flux[ skewer_id*n_los_real+i],  diff );
  //   }
  // }
  
  
}

void Grid3D::Compute_Transmitted_Flux_Skewers_GPU( int axis ){
  
  bool am_I_root;
  int n_skewers_local;
  int *n_skewers_processed_root;
  if ( axis == 0 ){
    am_I_root = Analysis.am_I_root_x;
    n_skewers_local = Analysis.n_skewers_local_x;
    n_skewers_processed_root = &Analysis.n_skewers_processed_root_x;
  } 
  if ( axis == 1 ){
    am_I_root = Analysis.am_I_root_y;
    n_skewers_local = Analysis.n_skewers_local_y;
    n_skewers_processed_root = &Analysis.n_skewers_processed_root_y;
  } 
  if ( axis == 2 ){
    am_I_root = Analysis.am_I_root_z;
    n_skewers_local = Analysis.n_skewers_local_z;
    n_skewers_processed_root = &Analysis.n_skewers_processed_root_z;
  } 
  
  if ( !am_I_root ) return;
   
  // Compute HI transmitted_flux
  Compute_Transmitted_Flux_Skewers_single_chem_GPU( axis, 0 );
  
  // Compute HeII transmitted_flux
  Compute_Transmitted_Flux_Skewers_single_chem_GPU( axis, 1 );
  
  *n_skewers_processed_root += n_skewers_local;
    
}

#endif //GPU_LYA_FLUX
#endif //LYA_STATISTICS
#endif //ANALYSIS
