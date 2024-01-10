#!/bin/bash

# This builds out a compound object structure suitable for ingest as an oral history for Islandora 1 and Drupal 7.
#
# It's based on the work done for the CLIR grant ingests and expects a particular file structure. It is also
# intended to create a specific file structure, wherein the compound object ingest will grab the OBJ and the MODS,
# but doesn't know what the heck to do with the VTT and doesn't automatically generate the PROXY_MP3 files needed
# for playback of mp3 files through the oral history module. It assumes that the MODS have already been extracted
# into the root directory of the collection to be ingested. It also assumes that the VTTs are somewhat consistently
# named; in this use-case, they have a filename consisting of the PID, followed by some string of text indicating
# the author and that the file has been reviewed and edited, followed by the file extension.
#
# Customization is probably required for other ingests.
#
# ###########
# FUNCTION
# ###########
#
# Given a base directory, MODS files in this base directory, mp3 files, and vtt files, this script creates the
# following directory structure:
# 
# Base: English-Readable Batch Name
#   ├ (directory) compound_objects
#       └ [each individual parent object has a directory; directory name is the PID]
#           ├ MODS.xml
#           └ OBJ.mp3
#   ├ (directory) datastreams
#       ├ (directory) PROXY_MP3
#           └ [Each individual mp3 file, following naming convention pitt_(PID)_PROXY_MP3.mp3]
#       ├ (directory) RELS-EXT (empty)
#       ├ (directory) TN (empty)
#       └ (directory) VTT
#           └ [Each individual VTT file, following naming convention pitt_(PID)_TRANSCRIPT.xml]
#   └ [lists of PIDs as .txt files]
#
#
# ###########
# OPERATION
# ###########
#
# 1. Extract the MODS into the root directory of the collection to be ingested.
# 2. Move the object directories into a compound_objects directory
# 3. From a BASH shell, CD into the root directory of this collection
# 4. Execute this script!
#
# For some source file -> VTT converters, you may need to run a global regular expression replacement to fix a
# timestamp issue.

# Path Settings
path_compound="compound_objects"
path_datastreams="datastreams"
path_proxy_mp3="$path_datastreams/PROXY_MP3"
path_rels_ext="$path_datastreams/RELS-EXT"
path_tn="$path_datastreams/TN"
path_vtt="$path_datastreams/VTT"

# Filename Conventions
prefix="pitt_"
suffix_proxy="_PROXY_MP3"
suffix_mods="_MODS"
suffix_vtt="_TRANSCRIPT"
extension_mods=".xml"
extension_vtt=".vtt"
filename_mp3_obj="OBJ.mp3"
filename_mods="MODS.xml"

# Regular Expression Settings
filename_regex="(.*\/)([^\/]+)(\.[^\.]+)$"
vtt_regex="^([0-9]+-[0-9]{2}).*$"

# PID File Creation Settings
prefix_full="pitt:"
pid_file_parent_name="pids_parent.txt"
pid_file_child_name="pids_child.txt"

# Other Setup
pid=""
ext=""
path=""
newdir=""
filename=""

# Wrapping mkdir in a wrapper to test to see if the directory already exists
create_directory() {
	test -d "$1"
	if [[ $? -eq 1 ]]; then
		mkdir "$1"
	fi
}
print_banner() {
	printf "\n*****************************************************************\n"
	printf "$1\n"
	printf "*****************************************************************\n\n"
}

# make necessary directories, if missing?
create_directory "$path_datastreams"
create_directory "$path_proxy_mp3"
create_directory "$path_rels_ext"
create_directory "$path_tn"
create_directory "$path_vtt"

# Create some empty files
>$pid_file_parent_name
>$pid_file_child_name

# loop through mp3s
print_banner "Processing MP3 Files and Generating Directory Structure"
find . -type f -name "*.mp3"|while read fname; do
	# get ID
	if [[ $fname =~ $filename_regex ]]; then
		path="${BASH_REMATCH[1]}"
		pid="${BASH_REMATCH[2]}"
		ext="${BASH_REMATCH[3]}"
	fi
	printf "Processing file $fname\n"
	# make directory
	printf "    Making directory...\r"
	newdir="$path$pid"
	create_directory "$newdir"
	# copy files into PROXY_MP3 directory
	printf "\033[K    Copying file to PROXY_MP3...\r"
	cp "$fname" "$path_proxy_mp3/$prefix$pid$suffix_proxy$ext"
	# move original files into new child directory
	printf "\033[K    Moving MP3 to proper directory...\r"
	mv "$fname" "$newdir/$filename_mp3_obj"
	# move the mods files into the new child directory, too
	printf "\033[K    Moving MODS to proper directory...\r"
	mv "./$prefix$pid$suffix_mods$extension_mods" "$newdir/$filename_mods"
	# record a child PID
	printf "\033[K    Recording PID...\r"
	printf "$prefix_full$pid\n" >> $pid_file_child_name

	printf "\033[K    Done\n"
done

print_banner "Processing Parent Mods"

# get the remaining MODS at the current depth, and move them into place - these *should* be the MODS for the parent objects
find . -maxdepth 1 -type f -name "*.xml"|while read fname; do
	# get filename (as $pid, for the moment)
	if [[ $fname =~ $filename_regex ]]; then
		path="${BASH_REMATCH[1]}"
		pid="${BASH_REMATCH[2]}"
		ext="${BASH_REMATCH[3]}"
	fi
	printf "Processing file $fname\n"

	# Checking to see if we have the prefix and suffix in the filename, and if so, we remove them.
	printf "    Extracting PID...\r"
	if [[ $pid == *"$suffix_mods"* ]]; then
		pid=${pid//$suffix_mods/}
	fi
	if [[ $pid == *"$prefix"* ]]; then
		pid=${pid//$prefix/}
	fi

	# move file into directory
	printf "\033[K    Moving parent MODS file to proper directory...\r"
	mv "$fname" "$path_compound/$pid/$filename_mods"
	# record a parent PID
	printf "\033[K    Recording PID...\r"
	printf "$prefix_full$pid\n" >> $pid_file_parent_name


	printf "\033[K    Done\n"
done

print_banner "Processing VTT Files"

# move the VTT files into the VTT directory
find . -type f -name "*.vtt"|while read fname; do
	# get filename
	if [[ $fname =~ $filename_regex ]]; then
		path="${BASH_REMATCH[1]}"
		filename="${BASH_REMATCH[2]}"
		ext="${BASH_REMATCH[3]}"
	fi
	printf "Processing file $fname\n"

	# Checking to see if we have the prefix and suffix in the filename, and if so, we remove them.
	printf "\033[K    Extracting PID from filename...\r"
	if [[ $filename =~ $vtt_regex ]]; then
		pid="${BASH_REMATCH[1]}"
	fi

	# move file into directory
	printf "\033[K    Moving VTT file to proper directory...\r"
	mv "$fname" "$path_vtt/$prefix$pid$suffix_vtt$extension_vtt"
	printf "\033[K    Done\n"
done