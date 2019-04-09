#!/bin/bash

if [ ${#*} != 2 ]
then
	echo "$0 string directory"
	exit 1
fi

pattern=$1
dir_arr=( $2 )
index=0

while [ $index -lt ${#dir_arr[@]} ]
do
	cur_dir=${dir_arr[$index]}
	for name in $(ls $cur_dir)
	do
		path="$cur_dir/$name"
		if [ -d "$path" ]
		then
			dir_arr+=( $path )
		fi

 		if [ -f "$path" ]
		then
			if [[ $0 != *"$name"* ]]
			then
				if grep --quiet $pattern $path
				then
					echo "$path"
					grep $pattern $path
				fi
			fi
		fi
	done	
	index=$(( $index + 1 ))
done

