#!/bin/bash

echo "#DSDV - EXPERIMENTO 1"
awk 'BEGIN{send = 0; received = 0;}	
				$1~/s/ && /AGT/  { send ++ }  
				$1~/r/ && /AGT/  { received ++ } 
							END{print "DSDV percent = "((received*100)/send)"%" }'	\
												../../DSDV/experimento1/out.tr
awk 'BEGIN{lost=0; } 		{lost+=$2} 		END{print "DSDV lost = "lost}'		../../DSDV/experimento1/lost.dat
awk 'BEGIN{bytes=0; } 		{bytes+=$2; } 		END{print "DSDV bytes = "bytes}'	../../DSDV/experimento1/byte.dat
awk 'BEGIN{lines=0; delay=0; } 	{lines++; delay+=$2} 	END{print "DSDV delay = " delay/lines}'	../../DSDV/experimento1/delay.dat
awk 'BEGIN{pkts=0} 		{pkts+=$2} 		END{print "DSDV pkts = "pkts}' 		../../DSDV/experimento1/pkts.dat

echo "#AODV - EXPERIMENTO 1"
awk 'BEGIN{send = 0; received = 0;}	
				$1~/s/ && /AGT/  { send ++ }  
				$1~/r/ && /AGT/  { received ++ } 
							END{print "AODV percent = "((received*100)/send)"%" }'	\
												../../AODV/experimento1/out.tr
awk 'BEGIN{lost=0; } 		{lost+=$2} 		END{print "AODV lost = "lost}'		../../AODV/experimento1/lost.dat
awk 'BEGIN{bytes=0; } 		{bytes+=$2; } 		END{print "AODV bytes = "bytes}'	../../AODV/experimento1/byte.dat
awk 'BEGIN{lines=0; delay=0; } 	{lines++; delay+=$2} 	END{print "AODV delay = " delay/lines}'	../../AODV/experimento1/delay.dat
awk 'BEGIN{pkts=0} 		{pkts+=$2} 		END{print "AODV pkts = "pkts}' 		../../AODV/experimento1/pkts.dat

echo "#OLSR - EXPERIMENTO 1"
awk 'BEGIN{send = 0; received = 0;}	
				$1~/s/ && /AGT/  { send ++ }  
				$1~/r/ && /AGT/  { received ++ } 
							END{print "OLSR percent = "((received*100)/send)"%" }'	\
												../../OLSR/experimento1/out.tr
awk 'BEGIN{lost=0; } 		{lost+=$2} 		END{print "OLSR lost = "lost}'		../../OLSR/experimento1/lost.dat
awk 'BEGIN{bytes=0; } 		{bytes+=$2; } 		END{print "OLSR bytes = "bytes}'	../../OLSR/experimento1/byte.dat
awk 'BEGIN{lines=0; delay=0; } 	{lines++; delay+=$2} 	END{print "OLSR delay = " delay/lines}'	../../OLSR/experimento1/delay.dat
awk 'BEGIN{pkts=0} 		{pkts+=$2} 		END{print "OLSR pkts = "pkts}' 		../../OLSR/experimento1/pkts.dat

