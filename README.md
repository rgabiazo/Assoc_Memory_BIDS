# BIDS Directory for Analyzing Baseline & Endpoint Data of Associative Memory Task (Face-Place Task)
This repository contains scripts for preprocessing and first-level analysis of a BIDS dataset, including FSL and ICA-AROMA processing steps. The dataset includes three functional runs of an associative memory task (Face-place task).

## Setting Up

 **Update Base Directory in Scripts**: Change the base directory in the `.sh` scripts to match your home base directory.
   
   Example:
   ```sh
   BASE_DIR="/Users/nagamatsulab/Desktop/BIDS" —> BASE_DIR="/Volumes/T7_Shield/BIDS"


 **Ensure subject folders should contain zip DICOM files located in sourcedata/Dicom

   Example: /Volumes/T7_Shield/BIDS/sourcedata/Dicom/sub-01/ses-baseline


 **Navigate to Script Directory to run scripts

Running Scripts
Navigate to Script Directory
Organize BIDS Data
Convert DICOM to NIfTI and transfer to BIDS_dataset per subject and session.

Baseline
chmod +x ses-baseline_organize_dcm_nifti_bids.sh
./ses-baseline_organize_dcm_nifti_bids.sh sub-01

Endpoint
chmod +x ses-endpoint_organize_dcm_nifti_bids.sh
./ses-endpoint_organize_dcm_nifti_bids.sh sub-01

Create .tsv Files with Custom Text Files
Baseline
chmod +x ses-baseline_create_tsv_files.sh
./ses-baseline_create_tsv_files.sh sub-01

Endpoint
chmod +x ses-endpoint_create_tsv_files.sh
./ses-endpoint_create_tsv_files.sh sub-01

Field-Map Correction
Transfer relevant files for field-map correction, extract volumes, merge AP and PA volumes, and create acquisition parameters.
Baseline
chmod +x ses-baseline_setup_topup.sh
./ses-baseline_setup_topup.sh

Endpoint
chmod +x ses-endpoint_setup_topup.sh
./ses-endpoint_setup_topup.sh

Estimate and Correct Field Distortions
Use AP/PA to calculate the field map using FSL topup and correct distortions using FSL applytopup.
Baseline
chmod +x ses-baseline_blipupdown.sh
./ses-baseline_blipupdown.sh sub-01:01,02,03

Endpoint
chmod +x ses-endpoint_blipupdown.sh
./ses-endpoint_blipupdown.sh sub-01:01,02,03

FSL Feat (No Field-Map Correction)
Setup for FSL Feat
Baseline
chmod +x ses-baseline_fsl_feat_setup.sh
./ses-baseline_fsl_feat_setup.sh sub-01

Endpoint
chmod +x ses-endpoint_fsl_feat_setup.sh
./ses-endpoint_fsl_feat_setup.sh sub-01

BET Brain Extraction
Strip skull from the brain, perform bias field and neck cleanup.
Baseline
chmod +x ses-baseline_feat_run_BET.sh
./ses-baseline_feat_run_BET.sh sub-02

Endpoint
chmod +x ses-endpoint_feat_run_BET.sh
./ses-endpoint_feat_run_BET.sh sub-02

Run First-Level Analysis
Run first-level analysis on the specified subjects and runs.
Baseline
chmod +x ses-baseline_feat_1st-Lvl.sh
./ses-baseline_feat_1st-Lvl.sh sub-01:01

Endpoint
chmod +x ses-endpoint_feat_1st-Lvl.sh
./ses-endpoint_feat_1st-Lvl.sh sub-01

FSL Feat (With Field-Map Correction)
10. Setup Field Map Corrected Files
Transfer files from topup_correction and create timing files from BIDS_dataset.
Baseline
chmod +x ses-baseline_feat_fieldmap_setup.sh
./ses-baseline_feat_fieldmap_setup.sh

Endpoint
chmod +x ses-endpoint_feat_fieldmap_setup.sh
./ses-endpoint_feat_fieldmap_setup.sh

Run First-Level Analysis with Fieldmap Corrected Runs
Baseline
chmod +x ses-baseline_feat_fieldmap_first_level.sh
./ses-baseline_feat_fieldmap_first_level.sh sub-01:01,02,03

Endpoint
chmod +x ses-endpoint_feat_fieldmap_first_level.sh
./ses-endpoint_feat_fieldmap_first_level.sh sub-01:01,02,03

ICA-AROMA First-Level Analysis
Setup ICA-AROMA
Transfer files from topup_correction and create timing files from BIDS_dataset.
Baseline
chmod +x ses-baseline_ICA_setup.sh
./ses-baseline_ICA_setup.sh

Endpoint
chmod +x ses-endpoint_ICA_setup.sh
./ses-endpoint_ICA_setup.sh

Preprocessing for ICA-AROMA
Baseline
chmod +x ses-baseline_ICA_Aroma_preproc.sh
./ses-baseline_ICA_Aroma_preproc.sh

Endpoint
chmod +x ses-endpoint_ICA_Aroma_preproc.sh
./ses-endpoint_ICA_Aroma_preproc.sh

Run ICA-AROMA
Run ICA-AROMA on preprocessed fMRI data.
Baseline
chmod +x ses-endpoint_run_ica_aroma.sh
./ses-endpoint_run_ica_aroma.sh sub-01:01,02,03

Endpoint
chmod +x ses-endpoint_run_ica_aroma.sh
./ses-endpoint_run_ica_aroma.sh sub-01:01,02,03


