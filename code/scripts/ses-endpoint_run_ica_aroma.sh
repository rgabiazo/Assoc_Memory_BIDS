#!/bin/bash

# This script runs ICA-AROMA for specified runs of multiple subjects.

# Usage:
# ./ses-endpoint_run_ica_aroma.sh sub-02:01,02,03 sub-03:01,03

# Set base directories
BASE_DIR="/Volumes/T7_Shield/BIDS"
LOG_DIR="${BASE_DIR}/code/logs"
LOG_FILE="${LOG_DIR}/ses-endpoint_run_ica_aroma_$(date '+%Y-%m-%d_%H-%M-%S').log"
SCRIPT_DIR="${BASE_DIR}/code/scripts"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Redirect echo output to log file and terminal
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

cd ${BASE_DIR}/code/ICA-AROMA-master

source venv/bin/activate

for arg in "$@"; do
    SUBJECT=$(echo $arg | cut -d':' -f1)
    RUNS=$(echo $arg | cut -d':' -f2 | tr ',' ' ')
    
    for RUN in $RUNS; do
        FUNC_DIR="${BASE_DIR}/derivatives/ICA_AROMA/Assoc_Memory_1st-Level/${SUBJECT}/ses-endpoint/feat_preproc/${SUBJECT}_corrected_task-assoc_memory_run-${RUN}_preproc.feat/filtered_func_data.nii.gz"
        MC_DIR="${BASE_DIR}/derivatives/ICA_AROMA/Assoc_Memory_1st-Level/${SUBJECT}/ses-endpoint/feat_preproc/${SUBJECT}_corrected_task-assoc_memory_run-${RUN}_preproc.feat/mc/prefiltered_func_data_mcf.par"
        AFFMAT_DIR="${BASE_DIR}/derivatives/ICA_AROMA/Assoc_Memory_1st-Level/${SUBJECT}/ses-endpoint/feat_preproc/${SUBJECT}_corrected_task-assoc_memory_run-${RUN}_preproc.feat/reg/example_func2standard.mat"
        OUTPUT_DIR="${BASE_DIR}/derivatives/ICA_AROMA/Assoc_Memory_1st-Level/${SUBJECT}/ses-endpoint/aroma/ICA_AROMA_run-${RUN}"
        MASK_FILE="${BASE_DIR}/derivatives/ICA_AROMA/Assoc_Memory_1st-Level//${SUBJECT}/ses-endpoint/func/${SUBJECT}_ICA_Aroma_task-Assoc_memory_run-${RUN}_mask.nii.gz"
        
        
        log "Processing Subject: $SUBJECT, Run: $RUN"
        log "Func directory: $FUNC_DIR"
        log ".par directory: $MC_DIR"
        log "Affmat directory: $AFFMAT_DIR"
        log "Output directory: $OUTPUT_DIR"
        log "Mask file: $MASK_FILE"
        
        # Run ICA-AROMA and only show output in the terminal
        python2.7 ${BASE_DIR}/code/ICA-AROMA-master/ICA_AROMA.py -in ${FUNC_DIR} -out ${OUTPUT_DIR} -mc ${MC_DIR} -affmat ${AFFMAT_DIR} -m ${MASK_FILE}

    done
done

# Deactivate the Python environment
deactivate

if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    log "Moving script to $SCRIPT_DIR"
    mv "$0" "$SCRIPT_DIR/"
fi

