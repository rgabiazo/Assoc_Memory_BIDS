#!/bin/bash

# Base directories
BASE_DIR="/Volumes/T7_Shield/BIDS"
BIDS_DATA_DIR="${BASE_DIR}/BIDS_dataset"
TOPUP_DIR="${BASE_DIR}/derivatives/topup_correction"
DEST_DIR="${BASE_DIR}/derivatives/feat_fieldmap/Assoc_Memory_1st-Level"
LOG_DIR="${BASE_DIR}/code/logs"
SCRIPT_DIR="${BASE_DIR}/code/scripts"

# Log file setup
LOG_FILE="${LOG_DIR}/ses-endpoint_feat_fieldmap_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Process each subject folder in the topup directory for functional data
for sub_dir in ${TOPUP_DIR}/*; do
  # Check if it's a directory
  if [ -d "${sub_dir}" ]; then
    sub=$(basename $sub_dir)
    
    # Handle functional data
    for run in 01 02 03; do  # Adjust the number of runs as needed
      SRC_FUNC="${TOPUP_DIR}/${sub}/ses-endpoint/run-${run}/func/topup_results_run_${run}/${sub}_corrected_task-assoc_memory_run-${run}_bold.nii.gz"
      
      if [ -f "${SRC_FUNC}" ]; then
        DEST_FUNC="${DEST_DIR}/${sub}/ses-endpoint/func"
        mkdir -p "${DEST_FUNC}"
        cp "${SRC_FUNC}" "${DEST_FUNC}"
        echo "Successfully copied functional data from ${SRC_FUNC} to ${DEST_FUNC}" | tee -a "${LOG_FILE}"

        # Create custom events directory if it does not exist
        CUSTOM_EVENTS_DIR="${BASE_DIR}/derivatives/feat_fieldmap/fsl_custom_events"
        mkdir -p "${CUSTOM_EVENTS_DIR}"

        # Process each events file and create txt files
        SES_PATH="${BIDS_DATA_DIR}/${sub}/ses-endpoint/func"  # Adjusted to correct BIDS directory
        OUTPUT_SUB_DIR="${CUSTOM_EVENTS_DIR}/${sub}/ses-endpoint"  # Custom output directory for txt files
        mkdir -p "${OUTPUT_SUB_DIR}"  # Ensure the directory exists

        echo "Looking for event files in $SES_PATH" | tee -a "${LOG_FILE}"
        ls $SES_PATH | grep 'task-assoc_memory.*events.tsv' | tee -a "${LOG_FILE}"  # Updated to match file naming

        for events_file in $(ls $SES_PATH | grep 'task-assoc_memory.*events.tsv'); do
            run_id=$(echo $events_file | grep -o 'run-[0-9]\+')
            echo "Processing $events_file for $run_id..." | tee -a "$LOG_FILE"
            for trial_type in encoding_pair recog_pair encoding_place recog_place encoding_face recog_face; do
                output_file="${OUTPUT_SUB_DIR}/${sub}_ses-endpoint_task-assoc_memory_${trial_type}_${run_id}.txt"
                awk -F'\t' -v tt="$trial_type" '$3==tt {print $1, $2, $4}' OFS='\t' "${SES_PATH}/${events_file}" > "$output_file"
                echo "Created file: $output_file" | tee -a "$LOG_FILE"
            done
        done

      else
        echo "Skipping: Functional file ${SRC_FUNC} not found." | tee -a "${LOG_FILE}"
      fi
    done

    # Handle anatomical data from BIDS dataset
    SRC_ANAT="${BIDS_DATA_DIR}/${sub}/ses-endpoint/anat/${sub}_T1w.nii.gz"
    if [ -f "${SRC_ANAT}" ]; then
      DEST_ANAT="${DEST_DIR}/${sub}/ses-endpoint/anat"
      mkdir -p "${DEST_ANAT}"
      cp "${SRC_ANAT}" "${DEST_ANAT}"
      echo "Successfully copied T1w image from ${SRC_ANAT} to ${DEST_ANAT}" | tee -a "${LOG_FILE}"
      
      # Check if the brain extracted file already exists
      if [ ! -f "${DEST_ANAT}/${sub}_T1w_brain.nii.gz" ]; then
        echo "Running BET brain extraction for ${sub}_T1w.nii.gz" | tee -a "${LOG_FILE}"
        # Run BET with bias field and neck cleanup
        bet "${DEST_ANAT}/${sub}_T1w.nii.gz" "${DEST_ANAT}/${sub}_T1w_brain.nii.gz" -B -f 0.1
        echo "BET brain extraction completed for ${sub}_T1w.nii.gz" | tee -a "${LOG_FILE}"
      else
        echo "BET brain extraction already processed for ${sub}_T1w.nii.gz" | tee -a "${LOG_FILE}"
      fi
    else
      echo "Skipping: T1w anatomical file ${SRC_ANAT} not found." | tee -a "${LOG_FILE}"
    fi
  else
    echo "Skipping non-directory item: ${sub_dir}" | tee -a "${LOG_FILE}"
  fi
done

echo "All applicable files have been processed." | tee -a "${LOG_FILE}"

if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $SCRIPT_DIR"
    mv "$0" "$SCRIPT_DIR/"
fi

