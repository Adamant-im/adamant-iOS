#!/bin/bash

# Define the script names
SCRIPTS=("CopyScript.sh" "GenerateAssetsScript.sh" "DeleteTempraryAssets.sh")

# Get the directory where the script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Iterate over each script and execute it
for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="$SCRIPT_DIR/$script"
    
    if [ -f "$SCRIPT_PATH" ]; then
        echo "Executing $script..."
        bash "$SCRIPT_PATH"
        
        # Check if the script exited with an error
        if [ $? -ne 0 ]; then
            echo "Error: $script failed to execute. Stopping execution."
            exit 1
        fi
    else
        echo "Error: $script not found in $SCRIPT_DIR."
        exit 1
    fi
done

echo "All scripts executed successfully."
