# Virtual screening workflow of Phytochemical compounds against the protein ERO1A 

This repository contains a shell script for performing a high-throughput virtual screening workflow. The process begins with preparing a large library of ligands from a SMILES file using Gypsum-DL, preparing a protein receptor, and finally, running the virtual screening for different ligand sets (Phytochemical compounds from COCONUT database, FAD, and EN460) using Autodock4 and POAP multithreaded pipeline targetting ERO1A protein. 

## Key Features

*   **Ligand Preparation**: Uses Gypsum-DL to convert a SMILES (`.smi`) file into 3D conformers (`.pdb`).
*   **Parallel Processing**: Splits the input SMILES file and uses MPI to process the chunks in parallel, significantly speeding up ligand preparation.
*   **Receptor Preparation**: Uses PDB2PQR and MGLTools to prepare a protein for docking.
*   **Automated Docking**: Utilizes the POAP script to run the virtual screening with AutoDock Vina.

## Dependencies

Before running the script, ensure you have the following software installed:

*   **Conda:** To manage the `poap` environment.
*   **Gypsum-DL**: For 3D ligand preparation.
*   **MGLTools:** Required for preparing the receptor. Specifically, `python2` and the `prepare_receptor4.py` script are used.
*   **PDB2PQR:** For converting PDB files to PQR format. Can be installed via `pip` or from the [PDB2PQR website](https://www.poissonboltzmann.org/pdb2pqr).
*   **MPI**: An MPI implementation like OpenMPI is required for parallel execution with `mpirun`.
*   **POAP:** multithreaded pipeline for virtual screening. It is assumed that you have a `poap` conda environment set up, or follow our modified version here [POAP_CMUTEAM](https://github.com/asangphukieo/POAP_CMUTEAM)

## How to Run

1.  **Setup**: Clone this repository and ensure your directory structure and input files match the layout described above.
2.  **Configure**: Open `run_screening_workflow.sh` and edit the **CONFIGURATION** section at the top. Set the correct paths, filenames, and parameters like the number of MPI tasks.
3.  **Execute**: Run the script from your main project directory.
    ```bash
    bash run_screening_workflow.sh
    ```

## Docking Grid Parameters for ERO1A binding pocket

The docking search space is limited to ERO1A's binding pocket of FAD, defined by a grid parameter file, which you must provide. The parameters used in this workflow are:

*   **Grid Point Spacing**: 1.000 Å
*   **Grid Dimensions (npts)**: 20 x 22 x 24 points
*   **Grid Center (center)**: 35.546, 36.151, 31.291

Ensure your grid parameter file (`3AHQ.txt` in this example) contains these values in the correct format for POAP.
