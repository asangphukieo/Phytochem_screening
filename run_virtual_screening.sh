
### Shell Script (`run_screening_workflow.sh`)

This version is a single, continuous script without functions or the re-run logic, as requested.

```bash
#!/bin/bash
set -e -o pipefail

#================================================================================================
# HIGH-THROUGHPUT VIRTUAL SCREENING WORKFLOW (Linear Execution)
#
# This script automates a full virtual screening pipeline in a sequential manner:
# 1. Ligand Preparation: Prepares 3D ligands from a SMILES file using Gypsum-DL.
# 2. Protein Preparation: Prepares a receptor PDB file for docking.
# 3. Virtual Screening: Runs a high-throughput screen using POAP.
#================================================================================================

#------------------------------------------------------------------------------------------------
# SECTION 1: CONFIGURATION
# !! EDIT THESE VARIABLES TO MATCH YOUR SYSTEM AND PROJECT !!
#------------------------------------------------------------------------------------------------

# --- Project and File Paths ---
MAIN_DIR="${HOME}/Downloads/Drug_screening/AUTODOCK"
PROTEIN_PDB="${HOME}/Downloads/SWISS_model/ERO1B_HUMAN.pdb"
MASTER_SMILES_FILE="${HOME}/Downloads/Drug_screening/COCONUT_DB.smi"
POAP_SCRIPT_DIR="${HOME}/Downloads/Drug_screening/POAP_CMUTEAM-main/scripts_v1_1_conda/"
GRID_PARAM_FILE="${HOME}/Downloads/Drug_screening/test/protein/3AHQ.txt"
MGLTOOLS_PREP_PATH="${HOME}/miniconda3/envs/autodock/bin/"

# --- File Naming ---
PROTEIN_NAME="ERO1B"

# --- Parallel Processing Parameters ---
NTASKS=125
LIGANDS_PER_SPLIT=125

# --- Conda Environments ---
CONDA_ENV_GYPSUM="gypsum"
CONDA_ENV_AUTODOCK="autodock"
CONDA_ENV_POAP="poap"

# --- Directory Names (Script will create these inside MAIN_DIR) ---
GYPSUM_OUTPUT_DIR="COCONUT_PDB"
PDBQT_OUTPUT_DIR="COCONUT_PDBQT"
SPLIT_SMI_DIR="SPLIT_INPUT"
PREPARED_PROTEIN_DIR="PREPARED_PROTEIN"
PREPARED_LIGAND_DIR="PREPARED_LIGANDS"
POAP_WORKING_DIR="WORKING_POAP"

#------------------------------------------------------------------------------------------------
# SECTION 2: SCRIPT EXECUTION
# The script will now run from top to bottom.
#------------------------------------------------------------------------------------------------

echo "INFO: Creating main working directory at ${MAIN_DIR}"
mkdir -p "${MAIN_DIR}"
cd "${MAIN_DIR}"

# --- Step 1: Ligand Preparation with Gypsum-DL ---
echo "INFO: Activating conda environment: ${CONDA_ENV_GYPSUM}"
source activate "${CONDA_ENV_GYPSUM}"

echo "INFO: Splitting master SMILES file into chunks of ${LIGANDS_PER_SPLIT}..."
mkdir -p "${SPLIT_SMI_DIR}"
split --additional-suffix=".smi" -l "${LIGANDS_PER_SPLIT}" "${MASTER_SMILES_FILE}" "${SPLIT_SMI_DIR}/CO_"

echo "INFO: Running Gypsum-DL in parallel with ${NTASKS} tasks..."
mkdir -p "${GYPSUM_OUTPUT_DIR}"
for smi in "${SPLIT_SMI_DIR}"/*.smi; do
    echo "INFO: Processing input file >>> $(basename "$smi")"
    mpirun -n "${NTASKS}" python -m mpi4py run_gypsum_dl.py \
        --source "${smi}" \
        --output_folder "../${GYPSUM_OUTPUT_DIR}" \
        --add_pdb_output \
        -m 1 \
        --job_manager mpi \
        --num_processors "${NTASKS}"
done

echo "INFO: Renaming output PDB files for simplicity..."
cd "${GYPSUM_OUTPUT_DIR}"
for f in *_output_1.pdb; do
    mv -- "$f" "${f%_output_1.pdb}.pdb"
done
cd ..

echo "INFO: Deactivating conda environment."
conda deactivate

# --- Step 2: Convert Ligand PDB to PDBQT ---
echo "INFO: Activating conda environment: ${CONDA_ENV_AUTODOCK}"
source activate "${CONDA_ENV_AUTODOCK}"

echo "INFO: Converting ligand PDB files to PDBQT format..."
mkdir -p "${PDBQT_OUTPUT_DIR}"
cd "${GYPSUM_OUTPUT_DIR}"
for fname in *.pdb; do
    python2 "${MGLTOOLS_PREP_PATH}prepare_ligand4.py" -l "${fname}" -v -o "../${PDBQT_OUTPUT_DIR}/${fname%.pdb}.pdbqt"
done
cd ..

echo "INFO: Deactivating conda environment."
conda deactivate

# --- Step 3: Prepare Protein Receptor ---
echo "INFO: Activating conda environment: ${CONDA_ENV_AUTODOCK}"
source activate "${CONDA_ENV_AUTODOCK}"

echo "INFO: Preparing protein receptor ${PROTEIN_NAME}..."
pdb2pqr30 --ff=AMBER --with-ph=7.4 "${PROTEIN_PDB}" "${PROTEIN_NAME}.pqr"
python2 "${MGLTOOLS_PREP_PATH}prepare_receptor4.py" -r "${PROTEIN_NAME}.pqr" -v -o "${PROTEIN_NAME}.pdbqt"

echo "INFO: Deactivating conda environment."
conda deactivate

# --- Step 4: Organize Files for POAP Screening ---
echo "INFO: Organizing final ligand and protein files for POAP..."
mkdir -p "${PREPARED_PROTEIN_DIR}" "${PREPARED_LIGAND_DIR}"
cp "${PDBQT_OUTPUT_DIR}"/*.pdbqt "${PREPARED_LIGAND_DIR}/"
cp "${PROTEIN_NAME}.pdbqt" "${PREPARED_PROTEIN_DIR}/"
cp "${GRID_PARAM_FILE}" "${PREPARED_PROTEIN_DIR}/${PROTEIN_NAME}.txt"

# --- Step 5: Run POAP Virtual Screening ---
echo "INFO: Activating conda environment: ${CONDA_ENV_POAP}"
source activate "${CONDA_ENV_POAP}"

echo "INFO: Starting POAP virtual screening..."
bash "${POAP_SCRIPT_DIR}/POAP_vs.bash" -s <<EOF
1
${MAIN_DIR}/${PREPARED_LIGAND_DIR}
${MAIN_DIR}/${PREPARED_PROTEIN_DIR}
${MAIN_DIR}/${POAP_WORKING_DIR}
8
8
1
2000
EOF

echo "INFO: Deactivating conda environment."
conda deactivate

# --- Workflow Complete ---
echo "------------------------------------------------------"
echo "SCRIPT COMPLETE."
echo "Final results are located in: ${MAIN_DIR}/${POAP_WORKING_DIR}/Results"
echo "------------------------------------------------------"

# --- Optional Commands for Analysis ---
#
# To move completed ligands from an interrupted run (run this manually if needed):
# for i in `cut -f1 WORKING_POAP/Results/output.txt`; do mv PREPARED_LIGANDS/${i}.pdbqt PREPARED_LIGANDS/COMPLETED_RUN/; done
#
# To count total unique compounds from multiple combined runs:
# cat WORKING_POAP_RUN1/Results/output.txt WORKING_POAP_RUN2/Results/sorted.txt | cut -f1 | sort | uniq | wc -l
#
