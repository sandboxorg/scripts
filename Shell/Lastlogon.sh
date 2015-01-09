#!/bin/bash
######################################################################################################
# Finds all files within /home/<user>/aircl_in that are greater than 32 days old and deletes
# Finds all files within /home/<user>/aircl_out that are greater than 15 days old and deletes
# 
#
# Change Record
# ====================
# v1.0 - 07/12/2012 - Initial Version
#
######################################################################################################

for dirs in `ls /home`;do
      echo -n "DELETING FILES FROM "$dirs" in Aircelle in Directory"
      find  /home/$dirs\/aircl_in/* -mtime +32 -exec rm -r {} \; > /dev/null 2>&1
      sleep 2
      echo "  ..OK"
      echo -n "DELETING FILES FROM "$dirs" in Aircelle out Directory"
      find  /home/$dirs\/aircl_out/* -mtime +15  -exec rm -r {} \; > /dev/null 2>&1
      sleep 2
      echo "  ..OK"
done
