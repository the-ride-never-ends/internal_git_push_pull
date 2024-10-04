#!/bin/bash

# Define the source directory
SOURCE_DIR="$HOME/custom_modules"

# Get the directory where the script is running from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' not found!"
    exit 1
fi

# Function to list available folders
list_folders() {
    echo "Available folders in $SOURCE_DIR:"
    ls -d "$SOURCE_DIR"/*/ | xargs -n 1 basename
}

# Ask user for folders to copy
echo "Which folders would you like to copy from $SOURCE_DIR?"
echo "Enter folder names separated by spaces, or 'all' for all folders."
list_folders
read -p "Your choice: " USER_INPUT

# Process user input
if [ "$USER_INPUT" = "all" ]; then
    FOLDERS_TO_COPY=($(ls -d "$SOURCE_DIR"/*/ | xargs -n 1 basename))
else
    IFS=' ' read -ra FOLDERS_TO_COPY <<< "$USER_INPUT"
fi

# Loop through each folder in the list
for folder in "${FOLDERS_TO_COPY[@]}"; do
    SOURCE_FOLDER="$SOURCE_DIR/$folder"
    
    # Check if the source folder exists
    if [ -d "$SOURCE_FOLDER" ]; then
        echo "Copying files from $SOURCE_FOLDER to $SCRIPT_DIR"

        # Check if the destination folder already exists
        if [ -d "$DEST_FOLDER" ]; then
            read -p "Folder $folder already exists in the destination. Overwrite? (y/n): " overwrite
            if [[ $overwrite =~ ^[Yy]$ ]]; then
                rm -rf "$DEST_FOLDER"
            else
                echo "Skipping $folder"
                continue
            fi
        fi
        # Copy the entire folder to the script directory
        cp -R "$SOURCE_FOLDER" "$SCRIPT_DIR"
        
        # Check if the copy operation was successful
        if [ $? -eq 0 ]; then
            echo "Successfully copied folder $folder"
        else
            echo "Error copying folder $folder"
        fi

    else
        echo "Warning: Folder '$folder' not found in $SOURCE_DIR"
    fi
done

echo "Copy operation complete!"