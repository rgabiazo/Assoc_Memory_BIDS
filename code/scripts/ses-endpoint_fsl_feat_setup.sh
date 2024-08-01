#!/bin/bash

# Base directory where BIDS data is located
BASE_DIR="/Volumes/T7_Shield/BIDS"
DATASET_DIR="${BASE_DIR}/BIDS_dataset"
output_dir="${BASE_DIR}/derivatives/feat/fsl_custom_events"
fsl_level_one_dir="${BASE_DIR}/derivatives/feat/Assoc_Memory_1st-Level"
log_dir="${BASE_DIR}/code/logs"
script_dir="${BASE_DIR}/code/scripts"

log_file="${log_dir}/$(basename $0)_$(date +%Y-%m-%d_%H-%M-%S).log"
mkdir -p "$log_dir"

# Start logging
echo "Preparing fsl feat..."

# Loop through each subject folder
for subject in $(ls $DATASET_DIR | grep 'sub-'); do
    echo "Processing $subject..." | tee -a "$log_file"
    # Define paths
    ses_path="$DATASET_DIR/$subject/ses-endpoint/func"
    anat_path="$DATASET_DIR/$subject/ses-endpoint/anat"
    output_sub_dir="$output_dir/$subject/ses-endpoint"
    fsl_anat_dir="$fsl_level_one_dir/$subject/ses-endpoint/anat"
    fsl_func_dir="$fsl_level_one_dir/$subject/ses-endpoint/func"

    # Create output directories if they don't exist
    mkdir -p $output_sub_dir $fsl_anat_dir $fsl_func_dir

    # Process each events file
    for events_file in $(ls $ses_path | grep 'events.tsv'); do
        # Extract run identifier directly from filename
        run_id=$(echo $events_file | grep -o 'run-[0-9]\+')
        echo "Processing $events_file for $run_id..." | tee -a "$log_file"

        # Extract conditions and create txt files
        for trial_type in encoding_pair recog_pair encoding_place recog_place encoding_face recog_face; do
            output_file="${output_sub_dir}/${subject}_ses-endpoint_task-assoc_memory_${trial_type}_${run_id}.txt"
            # Ensure using tab as the field separator for awk and accurately select the columns
            awk -F'\t' -v tt="$trial_type" '$3==tt {print $1, $2, $4}' OFS='\t' "${ses_path}/${events_file}" > "$output_file"
            echo "Created file: $output_file" | tee -a "$log_file"
        done
    done

    # Copy T1 and BOLD files to respective directories in FSL structure
    # Copy T1-weighted file
    t1_file="${subject}_T1w.nii.gz"
    if [ -f "${anat_path}/${t1_file}" ]; then
        cp "${anat_path}/${t1_file}" "${fsl_anat_dir}/"
        echo "T1-weighted file '${t1_file}' copied to ${fsl_anat_dir}" | tee -a "$log_file"
    else
        echo "T1-weighted file not found for $subject." | tee -a "$log_file"
    fi

    # Copy all BOLD files
    for bold_file in $(ls $ses_path | grep 'bold.nii.gz'); do
        cp "${ses_path}/${bold_file}" "${fsl_func_dir}/"
        echo "BOLD file '${bold_file}' copied to ${fsl_func_dir}" | tee -a "$log_file"
    done
done

echo "All processing complete." | tee -a "$log_file"


# Move the script to BASE_DIR/code/scripts after execution
if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $script_dir"
    mv "$0" "$script_dir/"
fi

