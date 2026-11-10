#!/bin/bash
#SBATCH -J eems_prepare
#SBATCH -o prepare_%j.out
#SBATCH -e prepare_%j.err
#SBATCH -p normal
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH -t 1-00:00:00

set -e

PROJECT_DIR="/path/to/eems_project"
VCF="/path/to/filtered_snps.vcf"
KEEP="/path/to/samples.keep"
BED2DIFFS="/path/to/eems/bed2diffs/src/bed2diffs_v2"

mkdir -p "$PROJECT_DIR"
PREFIX="$PROJECT_DIR/eems_data"

# Keep the selected samples in PLINK format.
plink --allow-extra-chr \
  --vcf "$VCF" \
  --keep "$KEEP" \
  --make-bed \
  --out "$PROJECT_DIR/snps"

# Calculate PLINK distances for reference.
plink --allow-extra-chr \
  --bfile "$PROJECT_DIR/snps" \
  --distance square \
  --out "$PREFIX"

# Calculate the dissimilarity matrix used by EEMS.
"$BED2DIFFS" --bfile "$PROJECT_DIR/snps" \
  --nthreads "${SLURM_CPUS_PER_TASK:-8}"
cp "$PROJECT_DIR/snps.diffs" "$PREFIX.diffs"
cp "$PROJECT_DIR/snps.order" "$PREFIX.order"

# Coordinates and the habitat boundary are prepared separately.
for file in "$PREFIX.coord" "$PREFIX.outer"; do
  if [ ! -s "$file" ]; then
    echo "Missing EEMS input: $file"
    exit 1
  fi
done

N_INDIV=$(wc -l < "$PROJECT_DIR/snps.fam")
N_SITES=$(wc -l < "$PROJECT_DIR/snps.bim")
N_COORD=$(wc -l < "$PREFIX.coord")
if [ "$N_COORD" -ne "$N_INDIV" ]; then
  echo "Coordinate count ($N_COORD) does not match sample count ($N_INDIV)."
  exit 1
fi

cat > "$PROJECT_DIR/params.ini" <<EOF_PARAMS
datapath = $PREFIX
mcmcpath = $PROJECT_DIR/output
nDemes = 200
nIndiv = $N_INDIV
nSites = $N_SITES
numMCMCIter = 20000000
numBurnIter = 2000000
numThinIter = 10000
EOF_PARAMS

echo "Prepared $N_INDIV samples and $N_SITES SNPs."
echo "Check that eems_data.coord follows the sample order in eems_data.order."
