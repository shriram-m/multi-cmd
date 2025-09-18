#!/bin/bash

# ==============================================================================
# Multi Command Runner (multi_cmd.sh)
# ==============================================================================
# 
# Description: A generic script to execute any command with multiple combinations
#              of variables, with support for logging, pre/post commands, and 
#              output file management.
#
# Author: Shriram M
# Version: 1.0.0
# License: MIT License
# Repository: https://github.com/shriram-m/multi-cmd
#
# Features:
#   - Execute any command with variable combinations
#   - Optional logging of all command outputs
#   - Pre-command and post-command execution
#   - Automatic output file copying and organization
#   - Detailed failure reporting with formatted tables
#   - Configurable output directories
#
# ==============================================================================

# Usage: ./multi_cmd.sh [-c|--command="command"] [-x|--command-suffix="suffix"] [-l|--log] [-p|--pre-command="command"] [-s|--post-command="command"] VAR1=VAL1,VAL2 VAR2=VAL3,VAL4 VAR3=VAL5,...

# Print help menu if no arguments are provided or if -h is used
if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "Description: This script helps to run any command for multiple combinations of variables.\n"
    echo -e "Usage: multi_cmd.sh [-c|--command=\"command\"] [-l|--log] [-p|--prebuild=\"command\"] [-o|--postbuild=\"command\"]  VAR1=VAL1,VAL2  VAR2=VAL3,VAL4  VAR3=VAL5,...\n"
    echo -e "Args:  -c, --command=\"command\": The main command to execute for each combination (required)"
    echo -e "       -x, --command-suffix=\"suffix\": Fixed suffix to append to every command execution (after variable combinations)"
    echo -e "       -l, --log: Enable logging mode - saves command logs for each combination in a separate file in the output directory"
    echo -e "       -p, --pre-command=\"command\": Custom command to run before each main command execution (output logged to command log)"
    echo -e "       -s, --post-command=\"command\": Custom command to run after each successful main command execution (output logged to command log)"
    echo -e "       -f, --output-file=\"path\": Path to output file to copy after successful command execution (relative to current directory)"
    echo -e "       -d, --output-dir=\"path\": Custom output directory for copied files (default: auto-generated based on current directory)"
    echo -e "       Other vars: Specify variables and their possible values (comma-separated) for the command as shown below"
    echo -e "           VAR1=VAL1,VAL2  VAR2=VAL3,VAL4  ...\n"
    echo -e "       Examples: multi_cmd.sh -c \"make build\" -x \"-j\" -l -f \"build/app.hex\" -p \"make clean\" TOOLCHAIN=GCC_ARM,ARM CONFIG=Debug,Release\n"
    echo -e "                 multi_cmd.sh -c \"npm run build\" -l -f \"dist/bundle.js\" --command-suffix=\"--verbose\" --pre-command=\"npm install\" ENV=dev,prod NODE_VERSION=16,18\n"
    echo -e "                 multi_cmd.sh -c \"docker build -t myapp\" --command-suffix=\"--no-cache\" --log --output-file=\"myapp.tar\" --post-command=\"docker save myapp > myapp.tar\" ARCH=amd64,arm64 VERSION=latest,v1.0\n"
    exit 0
fi

MAIN_COMMAND=""
COMMAND_SUFFIX=""
PRE_COMMAND=""
POST_COMMAND=""
OUTPUT_FILE=""
CUSTOM_OUTPUT_DIR=""

# Directory where the command output is generated
OUTPUT_DIR="../$(basename "$(pwd)")_run_$(date +%d-%m-%y_%H-%M-%S)"

# Check if logging mode is enabled
LOGGING=false
ARGS=("$@")
i=0
while [ $i -lt $# ]; do
    case "${ARGS[$i]}" in
        -c|--command=*)
            if [[ "${ARGS[$i]}" =~ ^-c$ ]]; then
                # Handle -c argument (next argument contains the command)
                MAIN_COMMAND="${ARGS[$((i+1))]}"
                unset ARGS[$i]
                unset ARGS[$((i+1))]
                ((i++))
            else
                # Handle --command=command format
                MAIN_COMMAND="${ARGS[$i]#*=}"
                unset ARGS[$i]
            fi
            ;;
        -x|--command-suffix=*)
            if [[ "${ARGS[$i]}" =~ ^-x$ ]]; then
                # Handle -x argument (next argument contains the suffix)
                COMMAND_SUFFIX="${ARGS[$((i+1))]}"
                unset ARGS[$i]
                unset ARGS[$((i+1))]
                ((i++))
            else
                # Handle --command-suffix=suffix format
                COMMAND_SUFFIX="${ARGS[$i]#*=}"
                unset ARGS[$i]
            fi
            ;;
        -l|--log)
            LOGGING=true
            unset ARGS[$i]
            ;;
        -p|--pre-command=*)
            if [[ "${ARGS[$i]}" =~ ^-p$ ]]; then
                # Handle -p argument (next argument contains the command)
                PRE_COMMAND="${ARGS[$((i+1))]}"
                unset ARGS[$i]
                unset ARGS[$((i+1))]
                ((i++))
            else
                # Handle --pre-command=command format
                PRE_COMMAND="${ARGS[$i]#*=}"
                unset ARGS[$i]
            fi
            ;;
        -s|--post-command=*)
            if [[ "${ARGS[$i]}" =~ ^-s$ ]]; then
                # Handle -s argument (next argument contains the command)
                POST_COMMAND="${ARGS[$((i+1))]}"
                unset ARGS[$i]
                unset ARGS[$((i+1))]
                ((i++))
            else
                # Handle --post-command=command format
                POST_COMMAND="${ARGS[$i]#*=}"
                unset ARGS[$i]
            fi
            ;;
        -f|--output-file=*)
            if [[ "${ARGS[$i]}" =~ ^-f$ ]]; then
                # Handle -f argument (next argument contains the file path)
                OUTPUT_FILE="${ARGS[$((i+1))]}"
                unset ARGS[$i]
                unset ARGS[$((i+1))]
                ((i++))
            else
                # Handle --output-file=path format
                OUTPUT_FILE="${ARGS[$i]#*=}"
                unset ARGS[$i]
            fi
            ;;
        -d|--output-dir=*)
            if [[ "${ARGS[$i]}" =~ ^-d$ ]]; then
                # Handle -d argument (next argument contains the directory path)
                CUSTOM_OUTPUT_DIR="${ARGS[$((i+1))]}"
                unset ARGS[$i]
                unset ARGS[$((i+1))]
                ((i++))
            else
                # Handle --output-dir=path format
                CUSTOM_OUTPUT_DIR="${ARGS[$i]#*=}"
                unset ARGS[$i]
            fi
            ;;
    esac
    ((i++))
done

# Check if main command is provided
if [[ -z "$MAIN_COMMAND" ]]; then
    echo "Error: Main command is required. Use -c or --command to specify the command to run."
    echo "Use --help for more information."
    exit 1
fi

# Rebuild args array without the processed options
NEW_ARGS=()
for arg in "${ARGS[@]}"; do
    if [[ -n "$arg" ]]; then
        NEW_ARGS+=("$arg")
    fi
done

# Parse input arguments into an associative array and preserve order
declare -A VARIABLES
declare -a VARIABLE_ORDER  # Array to preserve input order
for ARG in "${NEW_ARGS[@]}"; do
    IFS='=' read -r VAR VALUES <<< "$ARG"
    IFS=',' read -r -a VALUES_ARRAY <<< "$VALUES"
    VARIABLES["$VAR"]="${VALUES_ARRAY[@]}"
    VARIABLE_ORDER+=("$VAR")  # Preserve the input order
done

# Use custom output directory if provided, otherwise use default
if [[ -n "$CUSTOM_OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$CUSTOM_OUTPUT_DIR"
fi

# Display configuration
echo "Command Configuration:"
echo "  Main command: $MAIN_COMMAND"
if [[ -n "$COMMAND_SUFFIX" ]]; then
    echo "  Command suffix: $COMMAND_SUFFIX"
fi
echo "  Logging mode: $LOGGING"
if [[ -n "$PRE_COMMAND" ]]; then
    echo "  Pre-command: $PRE_COMMAND"
fi
if [[ -n "$POST_COMMAND" ]]; then
    echo "  Post-command: $POST_COMMAND"
fi
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "  Output file to copy: $OUTPUT_FILE"
    echo "  Output directory: $OUTPUT_DIR"
fi
echo ""

# Array to store failed combinations
FAILED_COMMANDS=()

# Function to recursively generate combinations of variables
generate_combinations() {
    local CURRENT_INDEX=$1
    local CURRENT_COMBINATION=$2
    local CURRENT_VALUES=$3

    # Use the preserved order from VARIABLE_ORDER array
    local VAR_NAMES=()
    for var in "${VARIABLE_ORDER[@]}"; do
        if [[ -n "${VARIABLES[$var]}" ]]; then
            VAR_NAMES+=("$var")
        fi
    done

    # If we've processed all variables, process the command execution logic
    if [ "$CURRENT_INDEX" -ge "${#VAR_NAMES[@]}" ]; then

        echo -e "\n\n================================== [START] =================================="
        echo "Running with ${CURRENT_COMBINATION// /   }"
        echo -e "=============================================================================\n"

        # Remove leading and trailing underscores from CURRENT_VALUES
        CURRENT_VALUES="${CURRENT_VALUES#_}" # Remove leading underscores
        CURRENT_VALUES="${CURRENT_VALUES%_}" # Remove trailing underscores

        # Prepare log file name if logging mode is enabled
        if $LOGGING; then
            mkdir -p "$OUTPUT_DIR"
            LOG_FILE="${OUTPUT_DIR}/run_${CURRENT_VALUES}.log"
            echo "Saving command log to $LOG_FILE"
        fi

        # Function to execute and log commands
        execute_and_log() {
            local CMD="$1"
            local DESCRIPTION="$2"
            
            if [[ -n "$CMD" ]]; then
                echo "$DESCRIPTION"
                if $LOGGING; then
                    echo -e "\n=== $DESCRIPTION ===" >> "$LOG_FILE"
                    eval "$CMD" 2>&1 | tee -a "$LOG_FILE"
                    local EXIT_CODE=${PIPESTATUS[0]}
                    echo -e "=== End $DESCRIPTION (Exit Code: $EXIT_CODE) ===\n" >> "$LOG_FILE"
                else
                    eval "$CMD"
                    local EXIT_CODE=$?
                fi
                
                if [ $EXIT_CODE -ne 0 ]; then
                    echo "Error: $DESCRIPTION failed with exit code $EXIT_CODE"
                    return $EXIT_CODE
                fi
            fi
            return 0
        }

        # Execute pre-command
        execute_and_log "$PRE_COMMAND" "Running pre-command"
        PRE_EXIT_CODE=$?
        
        if [ $PRE_EXIT_CODE -ne 0 ]; then
            echo "Command aborted due to pre-command failure"
            echo "Command failed for ${CURRENT_COMBINATION// /   } (pre-command failure)"
            FAILED_COMMANDS+=("${CURRENT_COMBINATION// /   } (pre-command failure)")
            echo -e "\n=================================== [END] ===================================\n"
            return
        fi

        # Run the main command with the current combination
        echo "Running main command..."
        FULL_COMMAND="$MAIN_COMMAND $CURRENT_COMBINATION"
        if [[ -n "$COMMAND_SUFFIX" ]]; then
            FULL_COMMAND="$FULL_COMMAND $COMMAND_SUFFIX"
        fi
        
        if $LOGGING; then
            echo -e "\n=== Main Command ===" >> "$LOG_FILE"
            eval $FULL_COMMAND 2>&1 | tee -a "$LOG_FILE"
            MAIN_EXIT_CODE=${PIPESTATUS[0]}
            echo -e "=== End Main Command (Exit Code: $MAIN_EXIT_CODE) ===\n" >> "$LOG_FILE"
        else
            eval $FULL_COMMAND
            MAIN_EXIT_CODE=$?
        fi

        if [ $MAIN_EXIT_CODE -eq 0 ]; then
            # Execute post-command
            execute_and_log "$POST_COMMAND" "Running post-command"
            POST_EXIT_CODE=$?
            
            if [ $POST_EXIT_CODE -ne 0 ]; then
                echo "Warning: Post-command failed, but main command was successful"
            fi
            
            # Copy output file if specified and successful
            if [[ -n "$OUTPUT_FILE" ]]; then
                if [ -f "$OUTPUT_FILE" ]; then
                    mkdir -p "$OUTPUT_DIR"
                    
                    # Get file extension
                    FILE_EXTENSION="${OUTPUT_FILE##*.}"
                    
                    # Create output filename with combination values
                    if [[ -n "$CURRENT_VALUES" ]]; then
                        OUTPUT_FILENAME="output_${CURRENT_VALUES}.${FILE_EXTENSION}"
                    else
                        # Fallback if no variables provided
                        OUTPUT_FILENAME="output_$(date +%H-%M-%S).${FILE_EXTENSION}"
                    fi
                    
                    DEST_FILE="${OUTPUT_DIR}/${OUTPUT_FILENAME}"
                    cp "$OUTPUT_FILE" "$DEST_FILE"
                    echo "Output file copied to: $DEST_FILE"
                else
                    echo "Warning: Output file $OUTPUT_FILE not found after successful command execution"
                fi
            fi
            
            echo "Command execution successful."
        else
            # If the command fails, record the combination
            echo "Command failed for ${CURRENT_COMBINATION// /   }"
            FAILED_COMMANDS+=("${CURRENT_COMBINATION// /   }")
        fi
        echo -e "\n=================================== [END] ===================================\n"
        return
    fi

    # Get the current variable name
    local VAR_NAME="${VAR_NAMES[$CURRENT_INDEX]}"

    # Iterate over all values of the current variable
    IFS=' ' read -r -a VALUES <<< "${VARIABLES[$VAR_NAME]}"
    for VALUE in "${VALUES[@]}"; do
        generate_combinations $((CURRENT_INDEX + 1)) "$CURRENT_COMBINATION $VAR_NAME=$VALUE" "${CURRENT_VALUES}${VALUE}_"
    done
}

# Call generate_combinations() to process all variable combinations
generate_combinations 0 "" ""

# Print all failed combinations
if [ ${#FAILED_COMMANDS[@]} -ne 0 ]; then
    echo -e "\n\n============================= [Failed Configs] ==============================\n"
    echo "  The following command executions failed:"

    # Use the preserved input order for the header
    VAR_NAMES=()
    # Add variables in their input order
    for var in "${VARIABLE_ORDER[@]}"; do
        if [[ -n "${VARIABLES[$var]}" ]]; then
            VAR_NAMES+=("$var")
        fi
    done

    # Calculate the maximum width for each column
    declare -A COLUMN_WIDTHS
    for VAR_NAME in "${VAR_NAMES[@]}"; do
        # Skip empty or invalid variable names
        if [[ -z "$VAR_NAME" ]]; then
            continue
        fi
        COLUMN_WIDTHS["$VAR_NAME"]=${#VAR_NAME}  # Start with the length of the header
    done

    for FAILED in "${FAILED_COMMANDS[@]}"; do
        for VAR_NAME in "${VAR_NAMES[@]}"; do
            # Skip empty or invalid variable names
            if [[ -z "$VAR_NAME" ]]; then
                continue
            fi
            VALUE=$(echo "$FAILED" | grep -oP "(?<=\b${VAR_NAME}=)[^ ]+")
            if [ ${#VALUE} -gt ${COLUMN_WIDTHS["$VAR_NAME"]} ]; then
                COLUMN_WIDTHS["$VAR_NAME"]=${#VALUE}
            fi
        done
    done

    # Build the header row
    HEADER="|"
    for VAR_NAME in "${VAR_NAMES[@]}"; do
        # Skip empty or invalid variable names
        if [[ -z "$VAR_NAME" ]]; then
            continue
        fi
        HEADER+=" $(printf "%-${COLUMN_WIDTHS[$VAR_NAME]}s" "$VAR_NAME") |"
    done

    # Build the dashes row with corners
    DASHES="+"
    for VAR_NAME in "${VAR_NAMES[@]}"; do
        # Skip empty or invalid variable names
        if [[ -z "$VAR_NAME" ]]; then
            continue
        fi
        DASHES+=$(printf "%-$((COLUMN_WIDTHS[$VAR_NAME] + 2))s" "" | tr ' ' '-')+
    done

    # Print the header and dashes
    echo -e "    $DASHES"
    echo -e "    $HEADER"
    echo -e "    $DASHES"

    # Print each failed combination
    for FAILED in "${FAILED_COMMANDS[@]}"; do
        ROW="|"
        for VAR_NAME in "${VAR_NAMES[@]}"; do
            # Skip empty or invalid variable names
            if [[ -z "$VAR_NAME" ]]; then
                continue
            fi
            VALUE=$(echo "$FAILED" | grep -oP "(?<=\b${VAR_NAME}=)[^ ]+")
            ROW+=" $(printf "%-${COLUMN_WIDTHS[$VAR_NAME]}s" "$VALUE") |"
        done
        echo -e "    $ROW"
    done

    # Print the closing dashes
    echo -e "    $DASHES"
    echo -e "\n=============================================================================\n"
else
    echo -e "\n\n=============================================================================\n"
    echo "  All command executions were successful!"
    echo -e "\n=============================================================================\n"
fi
