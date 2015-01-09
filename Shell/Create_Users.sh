#!/bin/bash

######################################################################################################
# Very basic script to create users from text file with username and password
# 
#
# Change Record
# ====================
# v1.0 - 05/12/2012 - Initial Version
#
######################################################################################################

inputFile=$1

while read line
do
	username=`echo $line | cut -d ',' -f1`
	password=`echo $line | cut -d ',' -f2`
	useradd -p $password $username
	echo $password > pass
	cat pass | passwd --stdin $username
done<$inputFile
