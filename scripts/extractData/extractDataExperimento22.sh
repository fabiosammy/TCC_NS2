#!/bin/bash

echo "#DSDV - EXPERIMENTO 2"
awk 'BEGIN{send = 0; received = 0;}	
				$1~/s/ && /AGT/  { send ++ }  
				$1~/r/ && /AGT/  { received ++ } 
							END{print "DSDV percent = "((received*100)/send)"%" }'	\
												../../DSDV/experimento2/out_movement1.tcl_.tr
awk 'BEGIN{lost=0; } 		{lost+=$2} 		END{print "DSDV lost = "lost}'		../../DSDV/experimento2/lost.dat
awk 'BEGIN{bytes=0; } 		{bytes+=($2/1024/1024); }
							END{print "DSDV MegaBytes = "bytes}'	../../DSDV/experimento2/byte.dat
awk 'BEGIN{lines=0; delay=0; } 	{lines++; delay+=$2} 	END{print "DSDV delay = " delay/lines}'	../../DSDV/experimento2/delay.dat
awk 'BEGIN{pkts=0} 		{pkts+=$2} 		END{print "DSDV pkts = "pkts}' 		../../DSDV/experimento2/pkts.dat

echo "#AODV - EXPERIMENTO 2"
awk 'BEGIN{send = 0; received = 0;}	
				$1~/s/ && /AGT/  { send ++ }  
				$1~/r/ && /AGT/  { received ++ } 
							END{print "AODV percent = "((received*100)/send)"%" }'	\
												../../AODV/experimento2/out_movement1.tcl_.tr
awk 'BEGIN{lost=0; } 		{lost+=$2} 		END{print "AODV lost = "lost}'		../../AODV/experimento2/lost.dat
awk 'BEGIN{bytes=0; } 		{bytes+=($2/1024/1024); }
							END{print "AODV MegaBytes = "bytes}'	../../AODV/experimento2/byte.dat
awk 'BEGIN{lines=0; delay=0; } 	{lines++; delay+=$2} 	END{print "AODV delay = " delay/lines}'	../../AODV/experimento2/delay.dat
awk 'BEGIN{pkts=0} 		{pkts+=$2} 		END{print "AODV pkts = "pkts}' 		../../AODV/experimento2/pkts.dat

echo "#OLSR - EXPERIMENTO 2"
awk 'BEGIN{send = 0; received = 0;}	
				$1~/s/ && /AGT/  { send ++ }  
				$1~/r/ && /AGT/  { received ++ } 
							END{print "OLSR percent = "((received*100)/send)"%" }'	\
												../../OLSR/experimento2/out_movement1.tcl_.tr
awk 'BEGIN{lost=0; } 		{lost+=$2} 		END{print "OLSR lost = "lost}'		../../OLSR/experimento2/lost.dat
awk 'BEGIN{bytes=0; } 		{bytes+=($2/1024/1024); }
							END{print "OLSR MegaBytes = "bytes}'	../../OLSR/experimento2/byte.dat
awk 'BEGIN{lines=0; delay=0; } 	{lines++; delay+=$2} 	END{print "OLSR delay = " delay/lines}'	../../OLSR/experimento2/delay.dat
awk 'BEGIN{pkts=0} 		{pkts+=$2} 		END{print "OLSR pkts = "pkts}' 		../../OLSR/experimento2/pkts.dat

