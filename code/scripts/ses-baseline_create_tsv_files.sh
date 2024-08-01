#!/bin/bash

# Check if subject IDs are provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <subject_id1> [<subject_id2> ...]" | tee -a "$log_file"
    echo "Example: $0 sub-02 sub-03" | tee -a "$log_file"
    exit 1
fi
# Setup directory
BASE_DIR="/Volumes/T7_Shield/BIDS"
# Setup log file
log_dir="${BASE_DIR}/code/logs"
log_file="${log_dir}/$(basename $0)_$(date +%Y-%m-%d_%H-%M-%S).log"
mkdir -p "$log_dir"
echo "Log file created at $log_file" > "$log_file"

# Define the conditions
conditions=("face" "place" "pair")

# Function to process and combine conditions into a single TSV file
process_and_combine_conditions() {
    subject_id=$1
    run_num=$2
    txt_dir="${BASE_DIR}/sourcedata/custom_txt/$subject_id"
    output_dir="${BASE_DIR}/BIDS_dataset/$subject_id/ses-baseline/func"
    
    combined_file=$(mktemp)
    tsv_file="$output_dir/${subject_id}_ses-baseline_task-assoc_memory_run-$(printf "%02d" $run_num)_events.tsv"
    echo -e "onset\tduration\ttrial_type\tweight" > "$tsv_file"

    for condition in "${conditions[@]}"; do
        encoding_file=$(find "$txt_dir" -type f -name "encoding_response_data_${condition}_run${run_num}*.txt")
        recog_file=$(find "$txt_dir" -type f -name "recog_response_data_${condition}_run${run_num}*.txt")

        if [[ -f "$encoding_file" && -f "$recog_file" ]]; then
            echo "Processing $condition for run $run_num of $subject_id..." | tee -a "$log_file"
            echo "Using encoding file: $encoding_file" | tee -a "$log_file"
            echo "Using recognition file: $recog_file" | tee -a "$log_file"
            awk '{print $1 "\t" $2 "\t" "encoding_'$condition'""\t" $3}' "$encoding_file" >> "$combined_file"
            awk '{print $1 "\t" $2 "\t" "recog_'$condition'""\t" $3}' "$recog_file" >> "$combined_file"
        else
            echo "Files for $condition run $run_num not found for $subject_id." | tee -a "$log_file"
        fi
    done

    # Sort by onset time and write to the final TSV file
    sort -k1,1n "$combined_file" >> "$tsv_file"
    rm "$combined_file"
    echo "Created combined TSV for run $run_num of $subject_id: $tsv_file" | tee -a "$log_file"
}

# Loop over each subject ID provided
for subject_id in "$@"; do
    # Define the directories for each subject
    txt_dir="${BASE_DIR}/sourcedata/custom_txt/$subject_id"
    output_dir="${BASE_DIR}/BIDS_dataset/$subject_id/ses-baseline/func"

    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"

    # Detect run numbers by looking at the filenames
    run_nums=$(find "$txt_dir" -type f -name "*_run[0-9]*.txt" | sed -E 's/.*_run([0-9]+).*/\1/' | sort -n | uniq)

    # Process detected runs
    for run_num in $run_nums; do
        process_and_combine_conditions "$subject_id" "$run_num"
    done

    echo "All specified TSV files created and moved to $output_dir for $subject_id" | tee -a "$log_file"
done

# Move the script to BASE_DIR/code/scripts after execution
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)/$(basename "$0")"
DEST_DIR="${BASE_DIR}/code/scripts"
if [ "$(readlink -f "$0")" != "$(readlink -f "$SCRIPT_DIR/$0")" ]; then
    echo "Moving script to $SCRIPT_DIR"
    mv "$0" "$DEST_DIR/"
fi
