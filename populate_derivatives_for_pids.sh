#!/bin/bash

# USAGE
# populate_derivatives_for_pids.sh [PIDs file] [target file to propagate] [optional: prefix] [optional: suffix]

# Get arguments
pids_file=$1
target=$2
prefix=$3
suffix=$4
newfile=""

# Error and argument checking
if [ -z $pids_file ]; then
	printf "Fatal error: no PIDs file\n"
	exit 1
fi
if [ -z $target ]; then
	printf "Fatal error: no target file to copy\n"
	exit 1
fi
if [ -z $prefix ]; then
	prefix="pitt_"
fi
if [ -z $suffix ]; then
	suffix="_TN"
fi

# Get file extension
fileext_regex=".+(\.[^\.]+)$"
if [[ $target =~ $fileext_regex ]]; then
	fileext="${BASH_REMATCH[1]}"
else
	fileext=""
fi

# Loop through PIDs
printf "Copying: $target \n"
while read pid; do
	pid="${pid//pitt:/}"	# remove starting "pitt:"
	pid="${pid//$'\r'/}"	# remove trailing \r, since this is linux and we're probably working with windows text encoding
	newfile=$prefix$pid$suffix$fileext
	printf "    Copying to $newfile\n"
	cp $target $newfile
done < $pids_file
