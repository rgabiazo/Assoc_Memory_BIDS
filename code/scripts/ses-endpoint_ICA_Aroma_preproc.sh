#!/bin/bash

# Base directory for output and input data
BASE_DIR="/Volumes/T7_Shield/BIDS"

AROMA_DIR="${BASE_DIR}/derivatives/ICA_AROMA/Assoc_Memory_1st-Level"

# Script directory to run script from
SCRIPT_DIR="${BASE_DIR}/code/scripts"

# Define the log file with timestamp
LOG_DIR="${BASE_DIR}/code/logs"
LOG_FILE="${LOG_DIR}/ses-endpoint_ICA_Aroma_preproc.sh_$(date +'%Y-%m-%d_%H-%M-%S').log"

# Location of the FSF template
FSF_TEMPLATE="${BASE_DIR}/code/design_files/ICA_design/preprocess_design.fsf"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting preprocessing..."

for arg in "$@"; do
    # Extract subject ID and run numbers from the argument
    SUBJ_ID=$(echo $arg | cut -d ':' -f 1)
    RUNS=$(echo $arg | cut -d ':' -f 2)

    IFS=',' read -r -a RUN_ARRAY <<< "$RUNS"

    for RUN in "${RUN_ARRAY[@]}"; do
        # Define the paths for input and output
        OUTPUT_DIR="${AROMA_DIR}/${SUBJ_ID}/ses-endpoint/feat_preproc/${SUBJ_ID}_corrected_task-assoc_memory_run-${RUN}_preproc"
        BOLD_FILE="${AROMA_DIR}/${SUBJ_ID}/ses-endpoint/func/${SUBJ_ID}_corrected_task-assoc_memory_run-${RUN}_bold.nii.gz"
        HIGHRES_FILE="${AROMA_DIR}/${SUBJ_ID}/ses-endpoint/anat/${SUBJ_ID}_T1w_brain.nii.gz"

        # Print the details of the current processing
        echo "Processing Subject: $SUBJ_ID, Run: $RUN"
        echo "Output Directory: $OUTPUT_DIR"
        echo "Functional File: $BOLD_FILE"
        echo "High-Res File: $HIGHRES_FILE"

        # Check if necessary files exist
        if [ ! -f "$BOLD_FILE" ] || [ ! -f "$HIGHRES_FILE" ]; then
            echo "Missing files for Subject: $SUBJ_ID, Run: $RUN. Skipping..."
            continue
        fi

        # Copy the FSF template and replace placeholders
        TEMP_FSF="/tmp/${SUBJ_ID}_run${RUN}.fsf"
        cp $FSF_TEMPLATE $TEMP_FSF
        sed -i '' "s|@output@|$OUTPUT_DIR|g" $TEMP_FSF
        sed -i '' "s|@bold@|$BOLD_FILE|g" $TEMP_FSF
        sed -i '' "s|@highres@|$HIGHRES_FILE|g" $TEMP_FSF

        # Run feat for preprocessing
        feat $TEMP_FSF

        # Define the path for example_func.nii.gz
        EXAMPLE_FUNC="${OUTPUT_DIR}.feat/example_func.nii.gz"
        BET_OUTPUT="${AROMA_DIR}/${SUBJ_ID}/ses-endpoint/func/${SUBJ_ID}_ICA_Aroma_task-Assoc_memory_run-${RUN}"

        # Check if example_func exists and then apply bet
        if [ -f "$EXAMPLE_FUNC" ]; then
            echo "Applying BET on $EXAMPLE_FUNC"
            bet "$EXAMPLE_FUNC" "$BET_OUTPUT" -f 0.3 -n -m -R
        else
            echo "example_func.nii.gz not found for Subject: $SUBJ_ID, Run: $RUN. Skipping BET..."
        fi
    done
done

echo "Preprocessing complete."

if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $SCRIPT_DIR"
    mv "$0" "$SCRIPT_DIR/"
fi

