#!/usr/bin/env bash


#Path to backup - should be provided as an Arg
INPUT_PATH=$1

# Path of the unpacked Backup - where the Output should be
OUTPUT_PATH=


# Verify the Backup using the signature and the public key
verifyBackup() {

   # Get the Path of the Public KEy
   echo "Please enter the path to your public key"
   read public_key
   
   # Get the Path of the Signature used to sign the backup   
   echo "Please enter the path to your signature for the backup"
   read signature_path
   
   # Verify the Backup and output the result
   verification_status=$(openssl dgst -sha1 -verify ${public_key} -signature ${signature_path} ${INPUT_PATH})
   echo "Verification Status: ${verification_status}"
}

# Decrypt the Backup using the key generated while creating the backup
decryptBackup() {
   # Get the Path of the Files Backup
   echo "Please enter the path to put the files of the backup"
   read output
   
   # Get the Path of the Key which encrypted the Backup
   echo "Please enter the path to the key for the decrypton"
   read key

   # Will be needed outside the method
   OUTPUT_PATH=$output
     
   # Decryption Process
   $(openssl enc -d -aes256 -in ${INPUT_PATH} -pass file:${key} | tar xz -C ${OUTPUT_PATH})
}

echo "Restoring backup at ${INPUT_PATH}"

echo "Verifying Backup..."
verifyBackup

echo "Decryption Backup..."
decryptBackup

echo "Backup restored! It can be found at ${OUTPUT_PATH}"
