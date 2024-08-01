#!/bin/bash

# Directories - change if different paths
BASE_DIR="/Volumes/T7_Shield/BIDS"
dcm_dir="${BASE_DIR}/sourcedata/Dicom"
nifti_dir="${BASE_DIR}/sourcedata/Nifti"
bids_dir="${BASE_DIR}/BIDS_dataset"
script_dir="${BASE_DIR}/code/scripts"
log_dir="${BASE_DIR}/code/logs"
subjects=("$@")

# Creating a log file in the logs directory with the date and script name
log_file="${log_dir}/$(basename $0)_$(date +%Y-%m-%d_%H-%M-%S).log"
mkdir -p "$log_dir"
echo "Log file created at $log_file" > "$log_file"

for subj in "${subjects[@]}"; do
    bids_subj_dir="${bids_dir}/${subj}/ses-endpoint"
    if [ -d "$bids_subj_dir" ]; then
        echo "$subj DICOM files have already been organized into NIfTI and moved to $bids_subj_dir." >> "$log_file"
        continue
    fi

    subj_folder="$dcm_dir/$subj/ses-endpoint/"
    output_dir="${subj_folder}nifti_output/"
    mkdir -p "$output_dir"
    echo "Processing $subj_folder" >> "$log_file"

    echo "Unzipping files for $subj..." >> "$log_file"
    unzip "$subj_folder/*.zip" -d "$subj_folder" && echo "Finished unzipping for $subj." >> "$log_file"

    if [ -d "${subj_folder}DICOM" ]; then
        dicom_dirs=$(find "${subj_folder}DICOM" -type d)
        for dir in $dicom_dirs; do
            if ls "$dir"/*.dcm 1> /dev/null 2>&1; then
                echo "Converting DICOM to NIfTI for $subj in $dir..." >> "$log_file"
                /Applications/MRIcron.app/Contents/Resources/dcm2niix -f "${subj}_%p_%s" -p y -z y -o "$output_dir" "$dir" && echo "Conversion completed for $dir." >> "$log_file"
            fi
        done

        folders=("AAHScout" "localizer" "rfMRI_PA" "rfMRI_REST_AP" "rfMRI_TASK_AP" "T1w_mprage_800iso_vNav" "T1w_vNav_setter" "T2w_space_800iso_vNav" "T2w_vNav_setter")
        for folder in "${folders[@]}"; do
            mkdir -p "$output_dir/$folder"
        done

        for file in "$output_dir"/*.nii.gz; do
            filename=$(basename "$file")
            for folder in "${folders[@]}"; do
                if [[ "$filename" == *"$folder"* ]]; then
                    mv "$file" "$output_dir/$folder/"
                    json_file="${file%.nii.gz}.json"
                    if [ -f "$json_file" ]; then
                        mv "$json_file" "$output_dir/$folder/"
                        echo "Moved $filename and associated JSON to $output_dir/$folder/" >> "$log_file"
                    fi
                fi
            done
        done

        nifti_subj_dir="${nifti_dir}/${subj}/ses-endpoint"
        mkdir -p "$nifti_subj_dir"
        mv "$output_dir"/* "$nifti_subj_dir/"
        echo "Organized files moved to $nifti_subj_dir" >> "$log_file"

        # Additional steps for renaming and copying functional and anatomical scans
        mkdir -p "$output_dir/func"
        func_files=($(find "$nifti_subj_dir/rfMRI_TASK_AP" -type f -name "*.nii.gz" -size +390M | sort -t_ -k4,4n))
        if [ ${#func_files[@]} -ge 3 ]; then
            for i in {0..2}; do
                run_num=$(printf "%02d" $((i + 1)))
                old_nii_file="${func_files[$i]}"
                new_nii_file="$output_dir/func/${subj}_task-assoc_memory_run-${run_num}_bold.nii.gz"
                cp "$old_nii_file" "$new_nii_file"
                echo "Copied and renamed $old_nii_file to $new_nii_file" >> "$log_file"

                old_json_file="${old_nii_file%.nii.gz}.json"
                new_json_file="${new_nii_file%.nii.gz}.json"
                if [ -f "$old_json_file" ]; then
                    cp "$old_json_file" "$new_json_file"
                    echo "Copied and renamed $old_json_file to $new_json_file" >> "$log_file"
                fi
            done
            echo "Functional runs copied and renamed in $output_dir/func." >> "$log_file"
        else
            echo "Not enough functional runs found for $subj." >> "$log_file"
        fi

        # Handle rfMRI_PA files directly into the func directory
        rfmri_pa_files=($(ls "$nifti_subj_dir/rfMRI_PA"/*.nii.gz | sort -V | tail -1))
        if [ -n "${rfmri_pa_files[0]}" ]; then
            new_rfmri_pa_file="$output_dir/func/${subj}_rfMRI_PA.nii.gz"
            cp "${rfmri_pa_files[0]}" "$new_rfmri_pa_file"
            echo "Copied and renamed ${rfmri_pa_files[0]} to $new_rfmri_pa_file" >> "$log_file"

            old_rfmri_pa_json_file="${rfmri_pa_files[0]%.nii.gz}.json"
            new_rfmri_pa_json_file="${new_rfmri_pa_file%.nii.gz}.json"
            if [ -f "$old_rfmri_pa_json_file" ]; then
                cp "$old_rfmri_pa_json_file" "$new_rfmri_pa_json_file"
                echo "Copied and renamed $old_rfmri_pa_json_file to $new_rfmri_pa_json_file" >> "$log_file"
            fi
        else
            echo "No rfMRI_PA files found for $subj." >> "$log_file"
        fi
        
        mkdir -p "$output_dir/anat"
        # T1w_mprage_800iso_vNav
        t1w_file=$(ls "$nifti_subj_dir/T1w_mprage_800iso_vNav"/*.nii.gz | sort -V | tail -1)
        if [ -n "$t1w_file" ]; then
            new_t1w_file="$output_dir/anat/${subj}_T1w.nii.gz"
            cp "$t1w_file" "$new_t1w_file"
            echo "Copied and renamed $t1w_file to $new_t1w_file" >> "$log_file"
        else
            echo "No T1w_mprage_800iso_vNav file found for $subj." >> "$log_file"
        fi

        # T2w_space_800iso_vNav
        t2w_file=$(ls "$nifti_subj_dir/T2w_space_800iso_vNav"/*.nii.gz | sort -V | tail -1)
        if [ -n "$t2w_file" ]; then
            new_t2w_file="$output_dir/anat/${subj}_T2w.nii.gz"
            cp "$t2w_file" "$new_t2w_file"
            echo "Copied and renamed $t2w_file to $new_t2w_file" >> "$log_file"
        else
            echo "No T2w_space_800iso_vNav file found for $subj." >> "$log_file"
        fi

        # Move 'anat' and 'func' folders to BIDS directory
        mkdir -p "${bids_subj_dir}/anat" "${bids_subj_dir}/func"
        mv "${output_dir}/anat"/* "${bids_subj_dir}/anat/"
        mv "${output_dir}/func"/* "${bids_subj_dir}/func/"
        echo "'anat' and 'func' folders moved to ${bids_subj_dir}" >> "$log_file"

        # Cleanup
        rmdir "$output_dir/anat" "$output_dir/func"
        rmdir "$output_dir"
    else
        echo "No DICOM directory found for $subj." >> "$log_file"
    fi
    echo "Finished processing $subj." >> "$log_file"
done

echo "Script execution completed. Log file is located at $log_file" >> "$log_file"

# Move the script to BASE_DIR/code/scripts after execution
if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $script_dir"
    mv "$0" "$script_dir/"
fi



