#!/bin/bash

# Need a one-time script to build parent MODS from child MODS.
# The benefit of building from the child MODS is that we can
# grab the titles, which we wouldn't otherwise have if we just
# built MODS from the path.

# Path Settings
path_compound="compound_objects"

# Filename Conventions
suffix_mods="_MODS"
filename_mp3_obj="OBJ.mp3"
filename_mods="MODS.xml"

# Regular Expression Settings
parent_dir_regex="(.*\/)([^\/]+)$"
filename_regex="(.*\/)([^\/]+)(\.[^\.]+)$"
vtt_regex="^([0-9]+-[0-9]{2}).*$"

# PID File Creation Settings
prefix_full="pitt:"
pid_file_parent_name="pids_parent.txt"

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

# Create an empty file
>$pid_file_parent_name

# loop through parent directories
print_banner "Creating Parent MODS"
find compound_objects/ -maxdepth 1 -type d|while read dname; do
	# skip the first directory returned; it's just the compound object directory.
	if [[ $dname == "$path_compound/" ]]; then
		continue
	fi

	# get ID
	if [[ $dname =~ $parent_dir_regex ]]; then
		path="${BASH_REMATCH[1]}"
		pid="${BASH_REMATCH[2]}"
	fi
	printf "Processing item $path\n"

	# for each parent, find one child
	# I'm lazy so instead of mucking around with subshells I'm piping this into a loop and
	# breaking out of the loop after the first pass.
	find $dname -type f -name "$filename_mods"  | head -n 1 | while read fname; do
		# copy MODS file into parent MODS
		printf "\033[K    Creating new MODS...\r"
		cp $fname $dname
		# find/delete "tape # side #"
		printf "\033[K    Updating title...\r"
		sed -i 's/, tape [[:digit:]], side [[:digit:]]//g' $dname/$filename_mods
		# find/delete trailing item number from ID
		printf "\033[K    Updating identifier...\r"
		sed -i -E "s/<mods:identifier type=\"pitt\">[[:digit:]]+-[[:digit:]]+<\/mods:identifier>/<mods:identifier type=\"pitt\">$pid<\/mods:identifier>/g" $dname/$filename_mods
		# find/delete source element
		printf "\033[K    Removing source reference...\r"
		sed -i -E "s/<mods:identifier type=\"source\">[[:digit:]]+<\/mods:identifier>//g" $dname/$filename_mods

		break
	done
	# record a parent PID
	printf "\033[K    Recording PID...\r"
	printf "$prefix_full$pid\n" >> $pid_file_parent_name

	printf "\033[K    Done\n"
done
