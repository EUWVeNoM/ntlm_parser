# NTDS Parser

## Overview

**NTDS Parser** is a script designed to parse the NTDS database and match cracked user passwords. It processes two input files: one containing NTDS user data and another containing cracked NT hashes along with their corresponding passwords. The script outputs the matched user-password pairs and provides an option to save the results to a file.

## Features

- **Input Parsing**: Handles two input files: `ntds_dump` and `hash_cracked`.
- **Matching**: Finds and displays matches between NT hashes in both files, showing the corresponding User:Password pairs.
- **Output Options**: Displays results on the console and optionally saves them to a specified output file.
- **Logging**: Provides feedback on unmatched NT hashes.

## Usage

To run the script, use the following command:

```bash
./ntds_parser.sh ntds_dump hash_cracked [-o output_file]
```

## Parameters

- ntds_dump: The NTDS file containing user data formatted as User:xxx:xxx:NT_hash:::.
- hash_cracked: The file containing cracked NT hashes and passwords formatted as NT_hash:Password.
- -o output_file: (Optional) Specifies the output file to save the matched results. If not provided, results are displayed only on the console.

## Help

To display the help message, simply run the script without any arguments:

```bash
./ntds_parser.sh
```

## Installation

Follow these steps to set up the script:
1. Clone the repository :
```bash
git clone https://github.com/EUWVeNoM/ntlm_parser.git
```
2. Navigate into the directory :
```bash
cd ntlm_parser
```
3. Make the script executable :
```bash
chmod +x ntds_parser.sh
```

## Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue or submit a pull request. Your input helps improve the script.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/EUWVeNoM/ntlm_parser/tree/main?tab=MIT-1-ov-file#readme) file for details.

## Author

GitHub: [EUWVeNoM](https://github.com/EUWVeNoM)
