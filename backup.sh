#!/usr/bin/env bash
# Retzer Oliver, Sahil Singh

# Default Path to backup if nothing provided
DEFAULT_PATH=~/

# Input Path of the backup - which file/directory to backup
INPUT_PATH=

# Where the Output of the Backup should be store - on /tmp
OUTPUT_PATH=/tmp

# Name of the Backup File - will be generated in get_filename()
OUTPUT_NAME="" 

# Check with Backup the count of files and directories
NR_FILES=
NR_DIRECTORIES=
NR_FILES_BACKUP=
NR_DIRECTORIES_BACKUP=

# Sum of Directories and files of all backups
NR_SUM_FINAL=0


# Check if the path to backup is a valid directory - if not, take the DEFAULT_PATH
checkPath() {
  if [ ! -d "$1" ] 
  then
  	# Path not valid - use the default path
	echo "Directory not found, using default directory $DEFAULT_PATH"
	INPUT_PATH=$DEFAULT_PATH
  else
  	# Set the Input Path - used for the next process - Backup and Verification
  	echo "Directory found! Proceeding Backup for $1..."
	INPUT_PATH=$1
  fi
}

# Create the Name for the Backup-File: backup_username_currentTimestamp.tar.gz
get_filename() {
  local DATE=$(date +"%Y-%m-%d_%H%M%S")
  USERNAME=$(stat -c '%U' $1)
  OUTPUT_NAME="backup_${USERNAME}_${DATE}.tar.gz"
}

# Create the Backup of the File
create_backup() {

  # Get the Filename for the Backup File
  get_filename $INPUT_PATH
  
  # Pack the Backup File with tar
  sudo tar -czf $OUTPUT_PATH/$OUTPUT_NAME $INPUT_PATH 2>/dev/null
  
  # Get the Return code from tar - and check if the process was sucessful or not
  return_code=$?
  if [ $return_code -eq 0 ]; then
    echo "Backup completed - can be found at $OUTPUT_PATH/$OUTPUT_NAME"
    return
  fi
  
  # Problem with the Backup!
  echo "Backup had a problem and returned with code $return_code"
}

# Get the Numbers of Files of a directory (recursivly) - Directory to check will be at $1
nrFiles() {
  local DIRPATH=$1
  NR_FILES=$(find $DIRPATH -type f | wc -l)
}

# Get the numbers of Directories in a directory (recursivly) - Directory to check will be at $1
nrDirectories() {
  local DIRPATH=$1
  NR_DIRECTORIES=$(find $DIRPATH -type d | wc -l)
}

# Get the Number of files from the whole Backup
nrFilesBackup() {
 
  # Unpack the Backup and grep the Output: 
  # Get the numbers of "-" as starting tail from the Output
  # which indicates a file
  NR_FILES_BACKUP=$(tar -ztvf $OUTPUT_PATH/$OUTPUT_NAME | grep '^-' | wc -l)
}

# Get the Number of directories from the whole backup
nrDirectoriesBackup() {

  # Unpack the Backup and grep the Output: 
  # Get the numbers of "d" as starting tail from the Output
  # which indicates a directory
  NR_DIRECTORIES_BACKUP=$(tar -ztvf $OUTPUT_PATH/$OUTPUT_NAME | grep '^d' | wc -l)
}

# Check if the Backup has as many files and directories as the directory to back-up
checkBackup() {
  # Get the numbers of files and directory from input path and output it
  echo "----------------------------------------"
  nrFiles $INPUT_PATH
  echo "Number of files in $INPUT_PATH: $NR_FILES"
  
  nrDirectories $INPUT_PATH
  echo "Number of directories in $INPUT_PATH: $NR_DIRECTORIES"
  echo "----------------------------------------"

  # Get the number of files and directories from backup and output it
  nrFilesBackup
  echo "Number of Files actually backed up: $NR_FILES_BACKUP"

  nrDirectoriesBackup
  echo "Number of Directories actually backed up: $NR_DIRECTORIES_BACKUP"
  echo "----------------------------------------"
  
  # Sum up the Files and Directories for final count
  NR_SUM_FINAL=$((${NR_SUM_FINAL} + ${NR_DIRECTORIES} + ${NR_FILES}))
  
  # Compare the numbers and alert if needed
  if [ $NR_FILES -eq $NR_FILES_BACKUP ] && [ $NR_DIRECTORIES -eq $NR_DIRECTORIES_BACKUP ]; then
    echo "Backup has no problems! The numbers of files and directories do match!"
  else
    echo "Problems with Backup! The numbers of files or directories do not match!"
  fi
}

# Encrypt the Backup using symmetric encryption - generate a bin file as the key
encryptBackup() {
  # Get the name for the encryption key which will be needed for the decryption process
  echo "Please enter a name for the encryption key"
  read PUBSSHKEY
  
  # Generate the key for encryption, will be saved at the current directory where the backup has started
  $(openssl rand -base64 32 > ${PUBSSHKEY}.bin)
  echo "Generated ${PUBSSHKEY}.bin - keep it for the decryption!"
  
  # Encrypt the Backup File using aes256 and a file as passphrase
  $(openssl enc -e -aes256 -in ${OUTPUT_PATH}/${OUTPUT_NAME} -out ${OUTPUT_PATH}/secured_${OUTPUT_NAME} -pass file:./${PUBSSHKEY}.bin)
  
  echo "Encrypted the backup! Removing the not encrypted backup.."
  
  # Remove the unencrypted backup file since we created an encrypted backup file
  $(sudo rm ${OUTPUT_PATH}/${OUTPUT_NAME})
}

# Sign the Backup and save the signature - used for verification at the restore process
signBackup() {
  # Get the path to the private key
  echo "Please enter the path to your private key"
  read private_key
  
  # Sign the secured Backup - save the signature at the current directory where the backup has started
  $(openssl dgst -sha1 -sign ${private_key} -out ${OUTPUT_NAME}.sign ${OUTPUT_PATH}/secured_${OUTPUT_NAME})
  echo "Signature created - can be found at ${OUTPUT_NAME}.sign"
}

# ---------------- MAIN ---------------- #

# Loop since it is possible to backup more than one directory
for directory in $*
  do
        echo -e "\n\n\t**** Backup of ${directory} directory ****\n"
        
        # Wait 1 Second so we don't have collision with backup directory 
        # Name if we have the same owner + the same Date
        sleep 1
        
        echo "Checking Path..."
        checkPath $directory
        
        echo "Starting Backup..."
        create_backup
        
        echo "Verifying Backup..."
        checkBackup
        
        echo "Encrypting Backup..."
        encryptBackup
        
        echo "Signing Backup..."
        signBackup
       
done

echo "Total Numbers of Files + Directories backed up: ${NR_SUM_FINAL}"
