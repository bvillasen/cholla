#!/bin/bash


if [[ -z "${CHOLLA_ROOT}" ]]; then
  echo -e "The CHOLLA_ROOT environment variable should be set"
  echo "Did you remember to `source scripts/set_env.sh` in the cholla directory ?"
  return
fi


if [[ "${CHOLLA_SYSTEM}" == "lockhart_mi250x" ]]; then
  AFFINITY="--cpu-bind=verbose --cpu-bind=mask_cpu:ff000000000000,ff00000000000000,ff0000,ff000000,ff,ff00,ff00000000,ff0000000000"
  SRUN="srun"
elif [[ "${CHOLLA_SYSTEM}" == "lockhart_mi300a" ]]; then
  AFFINITY=${CHOLLA_ROOT}/scripts/affinity_mi300a.sh
  SRUN="srun"
elif [[ "${CHOLLA_SYSTEM}" == "pp_conductor" ]]; then
  AFFINITY="--mca pml ucx -x UCX_PROTO_ENABLE=n -x UCX_ROCM_COPY_LAT=2e-6 -x UCX_ROCM_IPC_MIN_ZCOPY=4096 ${CHOLLA_ROOT}/scripts/affinity_mi300a.sh"
  SRUN="${OMPI_PATH}/bin/mpirun"
elif [[ "${CHOLLA_SYSTEM}" == "frontier" ]]; then
  AFFINITY="--gpu-bind=closest"
  SRUN="srun"
elif [[ "${CHOLLA_SYSTEM}" == "vultr" ]]; then
  AFFINITY="--mca pml ucx -x UCX_PROTO_ENABLE=n -x UCX_ROCM_COPY_LAT=2e-6 -x UCX_ROCM_IPC_MIN_ZCOPY=4096 "
  SRUN="${CHOLLA_OMPI_ROOT}/bin/mpirun"  
fi  

if [[ "${PROFILER}" == "rocprofv3_stats" ]]; then
  stats_dir=${WORK_DIR}/stats
  mkdir ${stats_dir}
  PROFILER_CMD="$CHOLLA_ROOT/scripts/rocprofv3_mpi_wrapper.sh $stats_dir results --kernel-trace --stats --truncate-kernels --"
else
  PROFILER_CMD=""
fi

export CHOLLA_EXEC=${CHOLLA_ROOT}/bin/cholla.${PROBLEM_TYPE}.${CHOLLA_SYSTEM}
export CHOLLA_PARAMETER_FILE=${PARAMETER_FILE}

module list

echo "Rank: $SLURM_PROCID"
# rocm-smi

echo "CHOLLA_SYSTEM=${CHOLLA_SYSTEM}"
echo "CHOLLA_EXEC=${CHOLLA_EXEC}"
echo "PARAMETER_FILE=${PARAMETER_FILE}"
echo "PROFILER_CMD=${PROFILER_CMD}"


# Use blitz kernels instead of SDMA
export HSA_ENABLE_SDMA=0


# export ROCSTAR_OUTPUT_DIR="${WORK_DIR}/rocSTAR_data"
# export ROCSTAR_DERIVED_POWER=1
# ROCSTAR_CMD="/localhome/bvillase/util/rocSTAR/rocSTAR_launch.sh"
# RUN_CMD="${SRUN} -n ${N_MPI} ${AFFINITY} ${PROFILER_CMD} ${ROCSTAR_CMD} ${CHOLLA_EXEC} ${PARAMETER_FILE} |& tee ${WORK_DIR}/app_output.log"

RUN_CMD="${SRUN} -n ${N_MPI} ${AFFINITY} ${PROFILER_CMD} ${CHOLLA_EXEC} ${PARAMETER_FILE} |& tee ${WORK_DIR}/app_output.log"


echo -e "Run command: ${RUN_CMD}" 

eval ${RUN_CMD}