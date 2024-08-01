#!/bin/bash

# Define source and destination directories
BASE_DIR="/Volumes/T7_Shield/BIDS"
source_dir="${BASE_DIR}/BIDS_dataset"
destination_dir="${BASE_DIR}/derivatives/topup_correction"
log_dir="${BASE_DIR}/code/logs"
log_file="${log_dir}/ses-baseline_setup_topup_$(date +'%Y-%m-%d_%H-%M-%S').log"
SCRIPT_DIR="${BASE_DIR}/code/scripts"

# Start logging to both terminal and log file
exec > >(tee "$log_file") 2>&1

# Loop through each subject's directory
for subject_folder in $(ls $source_dir); do
    if [[ $subject_folder == sub-* ]]; then
        echo "Processing $subject_folder"
        func_source="$source_dir/$subject_folder/ses-baseline/func"
        rfMRI_PA_json="$func_source/${subject_folder}_rfMRI_PA.json"
        rfMRI_PA_nii="$func_source/${subject_folder}_rfMRI_PA.nii.gz"
        
        # Process each BOLD and JSON file pair
        for bold_file in $(ls $func_source/*_bold.nii.gz); do
            # Extract run number from the file name
            run_number=$(echo $bold_file | awk -F '_' '{print $(NF-1)}' | sed 's/run-//')
            formatted_run_number=$(printf "run-%02d" $run_number)
            run_func_directory="$destination_dir/$subject_folder/ses-baseline/$formatted_run_number/func"

            # Create the func directory inside run directory if it doesn't exist
            mkdir -p "$run_func_directory"

            # Copy and rename BOLD and corresponding JSON file
            json_file="${bold_file%.nii.gz}.json"
            bold_dest_name="${subject_folder}_ses-baseline_acq-AP_${formatted_run_number}"
            cp "$bold_file" "$run_func_directory/${bold_dest_name}.nii.gz"
            cp "$json_file" "$run_func_directory/${bold_dest_name}.json"
            echo "$(basename $bold_file) has been renamed to ${bold_dest_name}.nii.gz"
            echo "$(basename $json_file) has been renamed to ${bold_dest_name}.json"

             # Extract the first volume using fslroi
            echo "Extracting first volume from ${bold_dest_name}.nii.gz"
            fslroi "$run_func_directory/${bold_dest_name}.nii.gz" "$run_func_directory/${subject_folder}_AP_${formatted_run_number}" 0 1

            # Check AP JSON file for encoding direction and readout time
            phase_dir=$(jq -r '.PhaseEncodingDirection' "$run_func_directory/${bold_dest_name}.json")
            readout_time=$(jq -r '.TotalReadoutTime' "$run_func_directory/${bold_dest_name}.json")
            if [[ "$phase_dir" == "j-" ]]; then
                echo "${bold_dest_name}.json: [0 -1 $readout_time]"
                echo "0 -1 0 $readout_time" > "$run_func_directory/${subject_folder}_acq_param_${formatted_run_number}.txt"
            fi
        done

        # Copy and rename the rfMRI_PA files to each run func directory for the current subject
        for run_dir in $(ls $destination_dir/$subject_folder/ses-baseline); do
            if [[ $run_dir == run-* ]]; then
                run_func_directory="$destination_dir/$subject_folder/ses-baseline/$run_dir/func"
                rfMRI_PA_dest_name="${subject_folder}_ses-baseline_acq-PA_${run_dir}"
                cp "$rfMRI_PA_json" "$run_func_directory/${rfMRI_PA_dest_name}.json"
                cp "$rfMRI_PA_nii" "$run_func_directory/${rfMRI_PA_dest_name}.nii.gz"
                echo "$(basename $rfMRI_PA_json) has been renamed to ${rfMRI_PA_dest_name}.json"
                echo "$(basename $rfMRI_PA_nii) has been renamed to ${rfMRI_PA_dest_name}.nii.gz"

                # Extract the first volume using fslroi
                echo "Extracting first volume from ${rfMRI_PA_dest_name}.nii.gz"
                fslroi "$run_func_directory/${rfMRI_PA_dest_name}.nii.gz" \
                       "$run_func_directory/${subject_folder}_PA_${run_dir}" 0 1

                # Merge the extracted AP and PA volumes using fslmerge
                echo "Merging AP and PA volumes for ${run_dir}: ${subject_folder}_AP_${run_dir}.nii.gz and ${subject_folder}_PA_${run_dir}.nii.gz"
                fslmerge -t "$run_func_directory/${subject_folder}_AP_PA_${run_dir}" \
                         "$run_func_directory/${subject_folder}_AP_${run_dir}.nii.gz" \
                         "$run_func_directory/${subject_folder}_PA_${run_dir}.nii.gz"
                echo "Merged files into ${subject_folder}_AP_PA_${run_dir}.nii.gz"

                # Check PA JSON file for encoding direction and readout time at the end
                phase_dir=$(jq -r '.PhaseEncodingDirection' "$run_func_directory/${rfMRI_PA_dest_name}.json")
                readout_time=$(jq -r '.TotalReadoutTime' "$run_func_directory/${rfMRI_PA_dest_name}.json")
                if [[ "$phase_dir" == "j" ]]; then
                    echo "${rfMRI_PA_dest_name}.json: [0 1 $readout_time]"
                    echo "0 1 0 $readout_time" >> "$run_func_directory/${subject_folder}_acq_param_${run_dir}.txt"
                fi
            fi
        done
    fi
done

echo "Setup for topup completed for all subjects."

# Move this script to the scripts directory after all runs have been processed
if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $SCRIPT_DIR"
    mv "$0" "$SCRIPT_DIR/"
fi


