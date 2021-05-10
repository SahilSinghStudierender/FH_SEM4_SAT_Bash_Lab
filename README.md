# Lab 04 - Bash Scripting

## What is the purpose of the bash script

With the help of the backup.sh and restore_backup.sh it is possible to backup one or more directories and encrypt it with symmetric encryption: AES-256. After the encryption, the backup file will be signed.
On the Restoration part - the backup file will be verified and decrypted - if the user has the key.

## What you need before creating a backup
First, you need a directory to backup. The Backup will be saved at /tmp.
Also, it is necessary to have a public/private key (.pem) - generated with OpenSSL

## How to backup a directory
First, execute the command to start the backup process:

    ./backup /path/to/directory/to/backup /another/path/to/directory/to/backup
Please enter the sudo password if needed.
Now the Backup file will be created and verified by comparing the count of the files and directories of the input path with the count of directories and files in the created backup.
Now enter a name for the encryption key, since the symmetric encryption needs a passphrase. Please keep the key, since it is important for the decryption part. Also, do not enter any file extensions at the end of the keyname.
Example for Encryption Key Name:

    Please enter a name for the encryption key
    key
   Now the key will be used for the encryption and will be saved at the directory where the backup command has been executed.
   After that, you need to provide the path to your private key, since the signature process needs it:
   
    Please enter the path to your private key
    /home/user/.ssh/private_key.pem

The signature will be created and saved at the directory where the backup command has been executed.

## How to restore a backup
For the restoration, you will need the public key associated with the private key which was used for the signature and the key for the decryption.
First, execute the command for restoration:

    ./restore_backup.sh /path/to/backup.tar.gz
Now enter the path to your public key for the verification of the signature

    Please enter the path to your public key
    /home/user/.ssh/public_key.pem
Now enter the path to your signature which was generated by the backup:

    Please enter the path to your signature for the backup:
    /path/to/the/signature.sign
Now you will get an output, if the verification is OK or not.

Now you need to enter the path where the output of the backup should be placed

    Please enter the path to put the files of the backup
    /path/to/output/backup
And now provide the path to your key which was generated with the backup process

    Please enter the path to the key for the decryption
    /path/to/key.bin

Now the Backup is restored at the path given by you.
