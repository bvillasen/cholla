#!/bin/bash
# Per-rank CPU + GPU binding wrapper for MI250X nodes (8 GCDs/node).
#
# Reproduces, launcher-agnostically, the affinity that this srun line gives:
#   srun --gpu-bind=closest \
#        --cpu-bind=mask_cpu:ff000000000000,ff00000000000000,ff0000,ff000000,ff,ff00,ff00000000,ff0000000000
#
# Idea: mpirun only places the ranks; this wrapper does the binding based on the
# node-local rank, so the result is identical no matter which mpirun is used.
#
# Usage:
#   mpirun -n 8 ./bind_mi250x.sh ${EXEC} parameter_file.txt

# --- node-local rank, across the common launchers -------------------------
LRANK=${PALS_LOCAL_RANKID:-${MPI_LOCALRANKID:-${OMPI_COMM_WORLD_LOCAL_RANK:-${PMI_LOCAL_RANK:-${SLURM_LOCALID:-0}}}}}

# --- per-rank CPU masks (hex), index = local rank ------------------------
# These are exactly the srun mask_cpu values, in the same rank order, so each
# rank gets the 8 cores that are NUMA-local to its closest GCD.
CPU_MASKS=( ff000000000000 ff00000000000000 ff0000 ff000000 ff ff00 ff00000000 ff0000000000 )

# --- pin this rank to its closest GPU and core set -----------------------
# With the masks above, rank i is NUMA-local to GCD i, matching gpu-bind=closest.
export ROCR_VISIBLE_DEVICES=${LRANK}

MASK=${CPU_MASKS[${LRANK}]}

exec taskset "${MASK}" "$@"
