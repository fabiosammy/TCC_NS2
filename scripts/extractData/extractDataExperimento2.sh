#!/bin/bash

#Delay
awk '{print $1}' delay_movement1.tcl_.dat > delay_backup.dat
for DELAY in $(ls delay_*_.dat) ; do
	awk '{print $2}' $DELAY > bkp_$DELAY 
done
paste -d '\t' delay_backup.dat $(ls bkp_delay_*_.dat) > bkp_delay__.dat
awk '{print $1" "($2+$3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13+$14+$15+$16)/15}' bkp_delay__.dat > delay.dat

rm delay_backup.dat
rm bkp_delay_*_.dat
#rm delay_*_.dat

#Lost
awk '{print $1}' lost_movement1.tcl_.dat > lost_backup.dat
for LOST in $(ls lost_*_.dat) ; do
	awk '{print $2}' $LOST > bkp_$LOST 
done
paste -d '\t' lost_backup.dat $(ls bkp_lost_*_.dat) > bkp_lost__.dat
awk '{printf ("%d \t %0.f\n", $1, ($2+$3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13+$14+$15+$16)/15)}' bkp_lost__.dat > lost.dat

rm lost_backup.dat
rm bkp_lost_*_.dat
#rm lost_*_.dat

#Byte
awk '{print $1}' byte_movement1.tcl_.dat > byte_backup.dat
for BYTE in $(ls byte_*_.dat) ; do
	awk '{print $2}' $BYTE > bkp_$BYTE
done
paste -d '\t' byte_backup.dat $(ls bkp_byte_*_.dat) > bkp_byte__.dat
awk '{print $1" "($2+$3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13+$14+$15+$16)/15}' bkp_byte__.dat > byte.dat

rm byte_backup.dat
rm bkp_byte_*_.dat
#rm byte_*_.dat

#Pkts
awk '{print $1}' pkts_movement1.tcl_.dat > pkts_backup.dat
for PKTS in $(ls pkts_*_.dat) ; do
	awk '{print $2}' $PKTS > bkp_$PKTS
done
paste -d '\t' pkts_backup.dat $(ls bkp_pkts_*_.dat) > bkp_pkts__.dat
awk '{printf ("%d \t %0.f\n", $1, ($2+$3+$4+$5+$6+$7+$8+$9+$10+$11+$12+$13+$14+$15+$16)/15)}' bkp_pkts__.dat > pkts.dat

rm pkts_backup.dat
rm bkp_pkts_*_.dat
#rm pkts_*_.dat

#Taxa de entrega
awk '{print $1}' pkts.dat > taxa_backup.dat
for TAXA in pkts.dat lost.dat ; do
	awk '{print $2}' $TAXA > bkp_taxa_$TAXA
done
paste -d '\t' taxa_backup.dat bkp_taxa_lost.dat bkp_taxa_pkts.dat > bkp_taxa__.dat
awk '{ 	if ( $3 > 0 ){
		printf ("%d \t %2.f\n", $1, ($3*100/($2+$3)))
	} else
		printf ("%d \t %d\n", $1, 100)
	}' bkp_taxa__.dat > taxa.dat

