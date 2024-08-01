#!/bin/bash

# Deine base directory
BASE_DIR="/Volumes/T7_Shield/BIDS"

# Define script directory
SCRIPT_DIR="${BASE_DIR}/code/scripts"

# Define log directory and log file name
log_dir="${BASE_DIR}/code/logs"
log_file="${log_dir}/ses-baseline_feat_1st-Lvl.sh$(date +%Y-%m-%d-%H-%M-%S).log"

# Ensure log directory exists
mkdir -p "$log_dir"

# Path to the FSF template

template_fsf="${BASE_DIR}/code/design_files/feat/Assoc_Memory/ses-baseline/Assoc_Memory_1st-Level/design.fsf"
# Base directory for data
data_base="${BASE_DIR}/derivatives/feat/Assoc_Memory_1st-Level"


# Base directory for custom EV files
ev_base="${BASE_DIR}/derivatives/feat/fsl_custom_events"


# Start logging
exec > >(tee -a "$log_file") 2>&1

# Iterate over each argument
for arg in "$@"; do
    sub=$(echo $arg | cut -d: -f1)
    runs=$(echo $arg | cut -d: -f2)
    
    # Handle multiple runs per subject
    IFS=',' read -ra RUNS <<< "$runs"
    for run in "${RUNS[@]}"; do
        run_pad=$(printf "%02d" $run)  # Pad the run number
        output_fsf="${data_base}/${sub}/temp/${sub}_run-${run_pad}_feat_1st_level_.fsf"
        
        # Ensure the directory for output_fsf exists
        mkdir -p "$(dirname "$output_fsf")"
        
        cp $template_fsf $output_fsf
        
        # Echo current processing information
        echo "Processing Subject: $sub, Run: $run_pad"
        
        # Replace placeholders in the FSF file
        sed -i '' -e "s|@outputdir@|${data_base}/${sub}/ses-baseline/run-${run_pad}|g" $output_fsf
        sed -i '' -e "s|@func@|${data_base}/${sub}/ses-baseline/func/${sub}_task-assoc_memory_run-${run_pad}_bold|g" $output_fsf
        sed -i '' -e "s|@highresfile@|${data_base}/${sub}/ses-baseline/anat/${sub}_T1w_brain|g" $output_fsf
        
        # Replace custom EV files manually
        sed -i '' -e "s|@custom1@|${ev_base}/${sub}/ses-baseline/${sub}_ses-baseline_task-assoc_memory_encoding_face_run-${run_pad}.txt|g" $output_fsf
        sed -i '' -e "s|@custom2@|${ev_base}/${sub}/ses-baseline/${sub}_ses-baseline_task-assoc_memory_encoding_place_run-${run_pad}.txt|g" $output_fsf
        sed -i '' -e "s|@custom3@|${ev_base}/${sub}/ses-baseline/${sub}_ses-baseline_task-assoc_memory_encoding_pair_run-${run_pad}.txt|g" $output_fsf
        sed -i '' -e "s|@custom4@|${ev_base}/${sub}/ses-baseline/${sub}_ses-baseline_task-assoc_memory_recog_face_run-${run_pad}.txt|g" $output_fsf
        sed -i '' -e "s|@custom5@|${ev_base}/${sub}/ses-baseline/${sub}_ses-baseline_task-assoc_memory_recog_place_run-${run_pad}.txt|g" $output_fsf
        sed -i '' -e "s|@custom6@|${ev_base}/${sub}/ses-baseline/${sub}_ses-baseline_task-assoc_memory_recog_pair_run-${run_pad}.txt|g" $output_fsf
        
        # Echo input and output details
        echo "Input 4D Data: ${data_base}/${sub}/ses-baseline/func/${sub}_corrected_task-assoc_memory_run-${run_pad}_bold"
        echo "High Res File: ${data_base}/${sub}/ses-baseline/anat/${sub}_T1w_brain"
        echo "Output Directory: ${data_base}${sub}/ses-baseline/run-${run_pad}"
        
        # Run feat
        feat $output_fsf
        
        # Remove the FSF file and its parent directory (temporary directory)
        rm $output_fsf
        rmdir "$(dirname "$output_fsf")" 
    done
done

if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    log "Moving script to $SCRIPT_DIR"
    mv "$0" "$SCRIPT_DIR/"
fi
