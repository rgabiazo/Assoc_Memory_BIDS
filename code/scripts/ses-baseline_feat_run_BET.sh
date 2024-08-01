#!/bin/bash

# Define base directory for operations
BASE_DIR="/Volumes/T7_Shield/BIDS"
FEAT_FIRST_LVL_DIR="${BASE_DIR}/derivatives/feat/Assoc_Memory_1st-Level"

# Log file setup
LOG_DIR="${BASE_DIR}/code/logs"
LOG_FILE="${LOG_DIR}/ses-baseline_run_BET_$(date +'%Y-%m-%d_%H-%M-%S').log"

SCRIPT_DIR="${BASE_DIR}/code/scripts"

# Function to process each subject
process_subject() {
    local sub_dir="$1"
    local subj=$(basename "$sub_dir")
    local anat_dir="${sub_dir}/ses-baseline/anat"
    local input_img="${anat_dir}/${subj}_T1w.nii.gz"
    local output_img="${anat_dir}/${subj}_T1w_brain.nii.gz"

    # Check if output already exists
    if [ -f "$output_img" ]; then
        echo "$subj BET has already been run" | tee -a "$LOG_FILE"
        return
    fi

    # Log the processing of the current subject
    echo "Running BET for $subj" | tee -a "$LOG_FILE"
    echo "Input file: $input_img" | tee -a "$LOG_FILE"
    echo "Output will be saved as: $output_img" | tee -a "$LOG_FILE"

    # Run BET with bias field and neck cleanup
    bet "$input_img" "$output_img" -B -f 0.1
}

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Process each subject directory
for sub_dir in "$FEAT_FIRST_LVL_DIR"/sub-*; do
    if [ -d "$sub_dir" ]; then
        process_subject "$sub_dir"
    fi
done


# Move this script to the scripts directory after all runs have been processed
if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $SCRIPT_DIR"
    mv "$0" "$SCRIPT_DIR/"
fi

