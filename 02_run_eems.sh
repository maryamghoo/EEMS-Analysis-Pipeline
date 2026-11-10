#!/bin/bash -l
#SBATCH -J eems
#SBATCH -o eems_%j.out
#SBATCH -e eems_%j.err
#SBATCH -p normal
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH -t 5-00:00:00

set -e

PROJECT_DIR="/path/to/eems_project"
EEMS="/path/to/eems/runeems_snps/src/runeems_snps"

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-32}"
cd "$PROJECT_DIR"

# Use a new output directory for each run.
if [ -d output ] && [ "$(ls -A output)" ]; then
  echo "The output directory is not empty. Move it before running again."
  exit 1
fi

"$EEMS" --params "$PROJECT_DIR/params.ini" --seed 123
