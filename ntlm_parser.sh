#!/bin/bash
#author : Venom
#Version : v1_beta
#Date : 02/08/2024
#Git : https://github.com/EUWVeNoM/ntlm_parser

# Function to display help
function display_help {
    echo "___________________________________________________________"
    echo "Usage: $0 ntds_dump hash_cracked [-o output_file]"
    echo
    echo "This script is designed to parse the NTDS database with"
    echo "cracked user passwords."
    echo
    echo "It takes two input files:"
    echo "1. The first file (ntds_dump) should have the format:"
    echo "   User:xxx:xxx:NT_hash:::"
    echo "2. The second file (hash_cracked) should have the format:"
    echo "   NT_hash:Password"
    echo
    echo "For each NT_hash found in both files, the script will display"
    echo "User:Password. If no match is found for an NT_hash, a message"
    echo "will be displayed, though these messages are not saved in the"
    echo "output file if specified."
    echo
    echo "Options:"
    echo "  -o output_file : Specify an output file to save the results."
    echo
    echo "Example:"
    echo "  $0 ntds_dump hash_cracked -o output.txt"
    echo "___________________________________________________________"
    echo
    exit 1
}

# Check if the arguments are provided
if [ $# -lt 2 ]; then
    display_help
fi

# Input files
ntds_dump=$1
hash_cracked=$2
output_file=""

# Parse optional arguments
shift 2
while getopts ":o:" opt; do
    case ${opt} in
        o )
            output_file=$OPTARG
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            display_help
            ;;
        : )
            echo "Option -$OPTARG requires an argument." >&2
            display_help
            ;;
    esac
done

# Check if the files exist
if [ ! -f "$ntds_dump" ] || [ ! -f "$hash_cracked" ]; then
    echo "Error: One of the provided files does not exist."
    exit 1
fi

# Read the values from hash_cracked while preserving the order
declare -A hash
declare -a order

echo "Loading values ..."
echo ""
while IFS=: read -r NT_hash Password; do
    # Remove unnecessary spaces from NT_hash and keep Password intact
    NT_hash=$(echo -n "$NT_hash" | tr -d '[:space:]')
    Password=$(echo -n "$Password" | tr -d '[:space:]')

    if [[ -n "$NT_hash" ]]; then
        hash["$NT_hash"]="$Password"
        order+=("$NT_hash")
    fi
done < "$hash_cracked"

# Read the lines from ntds_dump and store the results
declare -A results

while IFS=: read -r User _ _ NT_hash _ _; do
    # Remove unnecessary spaces from User and NT_hash
    User=$(echo -n "$User" | tr -d '[:space:]')
    NT_hash=$(echo -n "$NT_hash" | tr -d '[:space:]')

    if [[ -n "$NT_hash" && -n "${hash[$NT_hash]}" ]]; then
        results["$NT_hash"]="$User:${hash[$NT_hash]}"
    fi
done < "$ntds_dump"

# Handle output with or without output file
if [[ -n "$output_file" ]]; then
    # Save to output file and display, excluding "No match found" messages from file
    for NT_hash in "${order[@]}"; do
        if [[ -n "${results[$NT_hash]}" ]]; then
            echo "${results[$NT_hash]}" | tee -a "$output_file"
        else
            echo "No match found for '$NT_hash'"
        fi
    done
    echo "Results saved to $output_file"
else
    # Display only
    for NT_hash in "${order[@]}"; do
        if [[ -n "${results[$NT_hash]}" ]]; then
            echo "${results[$NT_hash]}"
        else
            echo "No match found for '$NT_hash'"
        fi
    done
fi

echo ""
echo "Job Well Done. Enjoy !"
echo "https://github.com/EUWVeNoM/ntlm_parser"
