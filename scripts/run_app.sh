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
fi  

if [[ "${PROFILER}" == "rocprofv3_stats" ]]; then
  stats_dir=${WORK_DIR}/stats
  mkdir ${stats_dir}
  PROFILER_CMD="$CHOLLA_ROOT/scripts/rocprofv3_mpi_wrapper.sh $stats_dir results --kernel-trace --stats --truncate-kernels --"
else
  PROFILER_CMD=""
fi

CHOLLA_EXEC=${CHOLLA_ROOT}/bin/cholla.${PROBLEM_TYPE}.${CHOLLA_SYSTEM}

module list
echo "CHOLLA_SYSTEM=${CHOLLA_SYSTEM}"
echo "CHOLLA_EXEC=${CHOLLA_EXEC}"
echo "PARAMETER_FILE=${PARAMETER_FILE}"
echo "PROFILER_CMD=${PROFILER_CMD}"


# Use blitz kernels instead of SDMA
export HSA_ENABLE_SDMA=0

RUN_CMD="${SRUN} -n ${N_MPI} ${AFFINITY} ${PROFILER_CMD} ${CHOLLA_EXEC} ${PARAMETER_FILE} |& tee ${WORK_DIR}/app_output.log" 
echo -e "Run command: ${RUN_CMD}" 

eval ${RUN_CMD}