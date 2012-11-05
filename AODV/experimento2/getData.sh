#!/bin/bash


awk '{print $1}' delay_movement1.tcl_.dat > delay_backup.dat
for DELAY in $(ls delay_*_.dat) ; do
	awk '{print $2}' $DELAY | while read DATA ; do
		sed "s/$/$DATA/" delay_backup.dat
	done
done

