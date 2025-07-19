# Virtual Screening Workflow for ERO1A using POAP

This repository contains a shell script to perform a virtual screening workflow against the protein ERO1A using Autodock4 and POAP multithreaded pipeline. The script prepares the protein and ligand files, and then runs the virtual screening calculations for different ligand sets (Phytochemical compounds from COCONUT database, FAD, and EN460).

## Dependencies

Before running the script, ensure you have the following software installed:

*   **Conda:** To manage the `poap` environment.
*   **MGLTools:** Required for preparing the receptor. Specifically, `python2` and the `prepare_receptor4.py` script are used.
*   **PDB2PQR:** For converting PDB files to PQR format. Can be installed via `pip` or from the [PDB2PQR website](https://www.poissonboltzmann.org/pdb2pqr).
    ```bash
    pip install pdb2pqr
    ```
*   **POAP:** multithreaded pipeline for virtual screening. It is assumed that you have a `poap` conda environment set up, or follow our modified version here [POAP_CMUTEAM](https://github.com/asangphukieo/POAP_CMUTEAM)

## Directory Structure

The script assumes the following directory structure. Please modify the paths in `run_virtual_screening.sh` to match your setup.
/home/cmu03/Downloads/Drug_screening/
├── PREPARED_LIGAND_ALL_COCONUT/
├── PREPARED_PROTEIN_ERO1A/
├── PREPARED_FAD/
├── PREPARED_EN460/
├── WORKING_POAP_ERO1A_COCONUT/
├── WORKING_POAP_ERO1A_FAD/
├── WORKING_POAP_ERO1A_EN460/
├── test/
│ └── protein/
│ ├── 3AHQ_protein.pdb
│ └── 3AHQ.txt
└── POAP_CMUTEAM-main/
└── scripts_v1_1_conda/
└── POAP_vs.bash
