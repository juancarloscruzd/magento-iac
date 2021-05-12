#!/bin/bash

AWS_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
EFS_MOUNT_DIR=/var/www/html

# Modify your own EFS endpoint
EFS_HOSTNAME=fs-feae020a.efs.us-east-1.amazonaws.com

# Do not replace this fstab directory
FSTAB_FILE=/etc/fstab

# Command to mount your EFS on fstab
$AWS_AZ.$EFS_HOSTNAME:/ $EFS_MOUNT_DIR nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0 >> $FSTAB_FILE