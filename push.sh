#!/bin/bash

# Define the destination directory
DEST_DIR="$HOME/staging"
PARENT_DIR=$(dirname "$DEST_DIR")

# Get the directory where the script is running from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define the path to the .internal_gitignore.txt file
IGNORE_FILE="$SCRIPT_DIR/.internal_gitignore.txt"

# Function to parse an internal gitignore file.
# Currently hardcode because the regex is fucked up somewhere.
get_internal_gitignore() {
    echo "Checking for .internal_gitignore.txt"
    # Check if the .internal_gitignore.txt file exists
    if [ ! -f "$IGNORE_FILE" ]; then
        echo "Warning: .internal_gitignore.txt file not found in $SCRIPT_DIR. Defaulting to built-in regex."
        EXCLUDE_PATTERN="^(__pycache__|venv|debug_logs)/"
    else
        # Read the EXCLUDE_PATTERN from the .internal_gitignore.txt file
        # We use grep to remove empty lines and comments, then join the patterns with '|'
        echo "TODO: Unhard code the pattern '^(__pycache__|venv|debug_logs)/'"
        EXCLUDE_PATTERN="^(__pycache__|venv|debug_logs)/"
        # EXCLUDE_PATTERN=$(grep -v '^\s*$\|^\s*#' "$IGNORE_FILE" | sed 's/[]\/$*.^[]/\\&/g' | sed 's/\s/\\ /g' | tr '\n' '|' | sed 's/|$//')
    fi
}

get_internal_gitignore


# Check if the destination directory exists, if not create it
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
    echo "Created staging directory: $DEST_DIR"
fi

# Function to list available folders in the current directory, excluding those matching EXCLUDE_PATTERN
list_folders() {
    echo "Available folders in $SCRIPT_DIR:"
    ls -d */ | grep -vE "$EXCLUDE_PATTERN" | cut -f1 -d'/'
}

# Ask user for folders to push
echo "Which folders would you like to push to $DEST_DIR?"
echo "Enter folder names separated by spaces, or 'all' for all folders."
list_folders
read -p "Your choice: " USER_INPUT

# Process user input
if [ "$USER_INPUT" = "all" ]; then
    FOLDERS_TO_PUSH=($(ls -d */ | grep -vE "$EXCLUDE_PATTERN" | cut -f1 -d'/'))
else
    IFS=' ' read -ra FOLDERS_TO_PUSH <<< "$USER_INPUT"
fi

# Loop through each folder in the list
for folder in "${FOLDERS_TO_PUSH[@]}"; do
    SOURCE_FOLDER="$SCRIPT_DIR/$folder"
    
    # Check if the source folder exists and doesn't match the exclude pattern
    if [ -d "$SOURCE_FOLDER" ] && ! echo "$folder/" | grep -qE "$EXCLUDE_PATTERN"; then
        echo "Pushing files from $SOURCE_FOLDER to $DEST_DIR"
        
        # Copy all files from the source folder to the destination directory, excluding patterns from .internal_gitignore.txt
        rsync -av --exclude-from="$IGNORE_FILE" "$SOURCE_FOLDER" "$DEST_DIR"
        
        # Check if the copy operation was successful
        if [ $? -eq 0 ]; then
            echo "Successfully pushed files from $folder"
        else
            echo "Error pushing files from $folder"
        fi
    elif echo "$folder/" | grep -qE "$EXCLUDE_PATTERN"; then
        echo "Skipping $folder as it's excluded from push"
    else
        echo "Warning: Folder '$folder' not found in $SCRIPT_DIR"
    fi
done

# Function to move files and directories from staging to parent directory
move_to_parent() {
    echo "Moving items from staging to parent directory..."
    for item in "$DEST_DIR"/*; do
        if [ -e "$item" ]; then
            basename=$(basename "$item")
            if [ -e "$PARENT_DIR/$basename" ]; then
                if [ -d "$item" ]; then
                    read -p "Directory $basename already exists in parent directory. Merge contents? (y/n): " merge
                    if [[ $merge =~ ^[Yy]$ ]]; then
                        rsync -av "$item/" "$PARENT_DIR/$basename/"
                        rm -rf "$item"
                        echo "Merged: $basename"
                    else
                        echo "Skipped: $basename"
                    fi
                else
                    read -p "File $basename already exists in parent directory. Overwrite? (y/n): " overwrite
                    if [[ $overwrite =~ ^[Yy]$ ]]; then
                        mv -f "$item" "$PARENT_DIR/"
                        echo "Overwritten: $basename"
                    else
                        echo "Skipped: $basename"
                    fi
                fi
            else
                mv "$item" "$PARENT_DIR/"
                echo "Moved: $basename"
            fi
        fi
    done
    echo "Move operation complete!"
}


# Step 2: Move files from staging to parent directory
read -p "Do you want to move files from staging to the parent directory '$PARENT_DIR'? (y/n): " move_choice
if [[ $move_choice =~ ^[Yy]$ ]]; then
    move_to_parent
else
    echo "Files will remain in the staging directory."
fi