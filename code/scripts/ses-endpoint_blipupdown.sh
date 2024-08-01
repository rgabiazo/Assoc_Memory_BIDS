#!/bin/bash

# Base directory for the BIDS formatted data
BASE_DIR="/Volumes/T7_Shield/BIDS"
TOPUP_DIR="${BASE_DIR}/derivatives/topup_correction"
LOG_DIR="${BASE_DIR}/code/logs"
LOG_FILE="${LOG_DIR}/ses-endpoint_blipupdown.sh_$(date '+%Y-%m-%d_%H-%M-%S').log"
SCRIPT_DIR="${BASE_DIR}/code/scripts"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to process each subject and run
process_run() {
    local subject=$1
    local run=$2

    {
        echo "Processing subject $subject, run $run"

        # Directory paths
        RUN_DIR="${TOPUP_DIR}/${subject}/ses-endpoint/run-${run}/func"
        OUTPUT_DIR="${RUN_DIR}/topup_results_run_${run}"
        TOPUP_LOG_FILE="${RUN_DIR}/${subject}_AP_PA_run-${run}.topup_log"

        # Check if topup has already been applied
        if [ -f "$TOPUP_LOG_FILE" ]; then
            echo "Skipping $subject, run-$run as topup has already been applied: $TOPUP_LOG_FILE"
            return # Skip processing this run
        fi

        # Ensure output directory exists
        mkdir -p "$OUTPUT_DIR"
        echo "Output directory created at: $OUTPUT_DIR"

        # File paths
        AP_PA="${RUN_DIR}/${subject}_AP_PA_run-${run}.nii.gz"
        ACQ_PARAMS="${RUN_DIR}/${subject}_acq_param_run-${run}.txt"
        TOPUP_CONFIG="b02b0.cnf"
        TOPUP_OUT="${OUTPUT_DIR}/topup_results"
        CORRECTED_AP_PA="${OUTPUT_DIR}/corrected_AP_PA_run${run}.nii.gz"

        # Echo file paths for topup
        echo "Running topup with:"
        echo "  Input AP/PA file: $AP_PA"
        echo "  Acquisition parameters file: $ACQ_PARAMS"
        echo "  Output Topup file: $TOPUP_OUT"

        # Run topup
        topup --imain="$AP_PA" --datain="$ACQ_PARAMS" --config="$TOPUP_CONFIG" --out="$TOPUP_OUT" --iout="$CORRECTED_AP_PA"
        echo "Topup completed. Corrected output: $CORRECTED_AP_PA"

        # Create topup log file
        touch "$TOPUP_LOG_FILE"

        # File for applytopup
        TASK_FILE="${RUN_DIR}/${subject}_ses-endpoint_acq-AP_run-${run}.nii.gz"
        CORRECTED_TASK_FILE="${OUTPUT_DIR}/${subject}_corrected_task-assoc_memory_run-${run}_bold.nii.gz"

        # Echo file paths for applytopup
        echo "Running applytopup with:"
        echo "  Input functional file: $TASK_FILE"
        echo "  Topup results file: $TOPUP_OUT"
        echo "  Output corrected functional file: $CORRECTED_TASK_FILE"

        # Run applytopup
        applytopup --imain="$TASK_FILE" --inindex=1 --datain="$ACQ_PARAMS" --topup="$TOPUP_OUT" --method=jac --out="$CORRECTED_TASK_FILE"
        echo "Applytopup completed. Corrected file: $CORRECTED_TASK_FILE"
    } | tee -a "$LOG_FILE"  # Append all echoed statements to a log file as well as the terminal
}

# Loop through each argument
for subj_run in "$@"; do
    IFS=':' read -r subject runs <<< "$subj_run"
    for run in ${runs//,/ }; do
        process_run "$subject" "$run"
    done
done

# Move this script to the scripts directory after all runs have been processed
if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $SCRIPT_DIR"
    mv "$0" "$SCRIPT_DIR/"
fi

