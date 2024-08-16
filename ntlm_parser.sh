#!/bin/bash
#Date : 16/08/2024
#Git : https://github.com/EUWVeNoM/ntlm_parser

# Function to display help
function display_help {
    echo "   _  __ ______ __    __  ___     ___    ___    ___    ____  ____  ___  "
    echo "  / |/ //_  __// /   /  |/  /    / _ \  / _ |  / _ \  / __/ / __/ / _ \ "
    echo " /    /  / /  / /__ / /|_/ /    / ___/ / __ | / , _/ _\ \  / _/  / , _/ "
    echo "/_/|_/  /_/  /____//_/  /_/    /_/    /_/ |_|/_/|_| /___/ /___/ /_/|_|  "
    echo "Version : v02 // author : Venom"
    echo ""
    echo "Usage:"
    echo "  $0 crack ntds.dit SYSTEM [-w specify_wordlist] [-r specify_rules] [-o output_file]"
    echo "  $0 coerce ntds_dump hash_cracked [-o output_file]"
    echo ""
    echo "Arguments:"
    echo "  Mode :"
    echo "    crack               Initiates the process to extract and crack NTDS passwords."
    echo "    coerce              Matches previously extracted NTDS dump with cracked hashes."
    echo "  Parameters :"
    echo "    -w specify_wordlist   Specify a custom wordlist for hashcat (crack mode only)."
    echo "    -r specify_rules      Specify custom rules for hashcat (crack mode only)."
    echo "    -o output_file        (Optional) Specify output file to save results."
    exit 1
}

# Check if the minimum number of arguments is provided
if [ $# -lt 1 ]; then
    display_help
fi
echo "   _  __ ______ __    __  ___     ___    ___    ___    ____  ____  ___  "
echo "  / |/ //_  __// /   /  |/  /    / _ \  / _ |  / _ \  / __/ / __/ / _ \ "
echo " /    /  / /  / /__ / /|_/ /    / ___/ / __ | / , _/ _\ \  / _/  / , _/ "
echo "/_/|_/  /_/  /____//_/  /_/    /_/    /_/ |_|/_/|_| /___/ /___/ /_/|_|  "
echo "Version : v02 // author : Venom"
echo ""


# Mode "crack"
if [ "$1" == "crack" ]; then
    # Ensure correct number of arguments for crack mode
    if [ $# -lt 3 ]; then
        display_help
    fi
    
    echo "[+]---- Entering in crack mode ----[+]"
    
    # Inputs for crack mode
    ntds_file=$2
    system_file=$3
    wordlist=""
    rules=""
    output_file=""
    
    # Shift parameters
    shift 3
    
    # Parse optional flags
    while getopts ":w:r:o:" opt; do
        case $opt in
            w) wordlist=$OPTARG ;;
            r) rules=$OPTARG ;;
            o) output_file=$OPTARG ;;
            \?) echo "Invalid option -$OPTARG" >&2; display_help ;;
        esac
    done
    
    # Check if the files exist
    if [ ! -f "$ntds_file" ] || [ ! -f "$system_file" ]; then
        echo "[+]- Error: Files does not exist. -[+]"
        exit 1
    fi
    
    # Execute secretsdump.py to extract NTDS information
    echo "[+]----  Extracting NTDS data  ----[+]"
    secretsdump.py -ntds "$ntds_file" -system "$system_file" LOCAL > ntds_dump_temp
    
    # Check if the extraction was successful
    if [ ! -f "ntds_dump_temp" ]; then
        echo "[+] Error: Failed to extract data. [+]"
        exit 1
    fi
    
    # Filter the relevant lines NTLM
    grep ':::' ntds_dump_temp > ntds_dump
    
    # Run hashcat to crack the NT hashes
    echo "[+]--- Try to crack NT hashes.. ---[+]"

    if [ -n "$wordlist" ] && [ -n "$rules" ]; then
        # Case: wordlist and rules are specified
        hashcat -m 1000 -a 0 ntds_dump "$wordlist" -r "$rules" -o hash_cracked --force --show >/dev/null 2>&1 &
    elif [ -n "$wordlist" ]; then
        # Case: only wordlist is specified, no rules
        hashcat -m 1000 -a 0 ntds_dump "$wordlist" -o hash_cracked --force --show >/dev/null 2>&1 &
    else
        # Case: no wordlist specified, use default rockyou.txt
        hashcat -m 1000 -a 0 ntds_dump /usr/share/wordlists/rockyou.txt -o hash_cracked --force --show >/dev/null 2>&1 &
    fi
    
    sleep 2

    # Check if hashcat succeeded
    if [ ! -f "hash_cracked" ]; then
        echo "[+] Error: Failed to crack hashes. [+]"
        exit 1
    fi
    
    echo "[+]--- Compilation of results.. ---[+]"
    
    # Proceed to matching the results using the same logic as in the coerce mode
    
    # Existing logic for matching ntds_dump and hash_cracked
    declare -A hash
    declare -a order
    
    while IFS=: read -r NT_hash Password; do
        NT_hash=$(echo -n "$NT_hash" | tr -d '[:space:]')
        Password=$(echo -n "$Password" | tr -d '[:space:]')
    
        if [[ -n "$NT_hash" ]]; then
            hash["$NT_hash"]="$Password"
            order+=("$NT_hash")
        fi
    done < hash_cracked
    
    declare -A results
    
    while IFS=: read -r User _ _ NT_hash _ _; do
        User=$(echo -n "$User" | tr -d '[:space:]')
        NT_hash=$(echo -n "$NT_hash" | tr -d '[:space:]')
    
        if [[ -n "$NT_hash" && -n "${hash[$NT_hash]}" ]]; then
            results["$NT_hash"]="$User:${hash[$NT_hash]}"
        fi
    done < ntds_dump
    
    # Display or save the results
    if [ -n "$output_file" ]; then
        echo "File generated by NTLM PARSER v02" >> "$output_file"
        echo "Github : https://github.com/EUWVeNoM/ntlm_parser" >> "$output_file"
        echo $(date) >> "$output_file"
        echo "" >> "$output_file"
        for NT_hash in "${order[@]}"; do
            if [[ -n "${results[$NT_hash]}" ]]; then
                echo "${results[$NT_hash]}" >> "$output_file"
            fi
        done
        echo "[+]- Results saved in $output_file. -[+]"
    else
        for NT_hash in "${order[@]}"; do
            if [[ -n "${results[$NT_hash]}" ]]; then
                echo "${results[$NT_hash]}"
            fi
        done
    fi
    rm -f ntds_dump_temp ntds_dump hash_cracked
    echo "[+]---- Job Well Done. Enjoy ! ----[+]"
    exit 0

# Mode "coerce"
elif [ "$1" == "coerce" ]; then
    # Ensure correct number of arguments for coerce mode
    if [ $# -lt 3 ]; then
        display_help
    fi

    echo "[+]---- Entering in coerce mode ----[+]"

    # Inputs for coerce mode
    ntds_dump=$2
    hash_cracked=$3
    output_file=""
    
    # Check for optional output file
    shift 3
    while getopts ":o:" opt; do
        case $opt in
            o) output_file=$OPTARG ;;
            \?) echo "Invalid option -$OPTARG" >&2; display_help ;;
        esac
    done
    
    # Check if the input files exist
    if [ ! -f "$ntds_dump" ] || [ ! -f "$hash_cracked" ]; then
        echo "[+]- Error: Files does not exist.  -[+]"
        exit 1
    fi
    
    # Coerce logic (same as in crack mode)
    declare -A hash
    declare -a order
    
    while IFS=: read -r NT_hash Password; do
        NT_hash=$(echo -n "$NT_hash" | tr -d '[:space:]')
        Password=$(echo -n "$Password" | tr -d '[:space:]')
    
        if [[ -n "$NT_hash" ]]; then
            hash["$NT_hash"]="$Password"
            order+=("$NT_hash")
        fi
    done < "$hash_cracked"
    
    declare -A results
    
    while IFS=: read -r User _ _ NT_hash _ _; do
        User=$(echo -n "$User" | tr -d '[:space:]')
        NT_hash=$(echo -n "$NT_hash" | tr -d '[:space:]')
    
        if [[ -n "$NT_hash" && -n "${hash[$NT_hash]}" ]]; then
            results["$NT_hash"]="$User:${hash[$NT_hash]}"
        fi
    done < "$ntds_dump"
    
    # Display or save the results
    if [ -n "$output_file" ]; then
        echo "File generated by NTLM PARSER v02" >> "$output_file"
        echo "Github : https://github.com/EUWVeNoM/ntlm_parser" >> "$output_file"
        echo $(date) >> "$output_file"
        echo "" >> "$output_file"
        for NT_hash in "${order[@]}"; do
            if [[ -n "${results[$NT_hash]}" ]]; then
                echo "${results[$NT_hash]}" >> "$output_file"
            fi
        done
        echo "[+]- Results saved in $output_file -[+]"
    else
        for NT_hash in "${order[@]}"; do
            if [[ -n "${results[$NT_hash]}" ]]; then
                echo "${results[$NT_hash]}"
            fi
        done
    fi
    echo "[+]---- Job Well Done. Enjoy !  ----[+]"
    exit 0
else
    display_help
fi
