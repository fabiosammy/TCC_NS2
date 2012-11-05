#GNUPlot Script
reset

#EPS File
set terminal postscript eps enhanced color font 'Helvetica,22' 
set output '../../doc/TCC/images/exp1_pkts.eps'

#Estilo
set style line
set style fill solid

#labels
set title 'Número de pacotes de roteamento'
set xlabel 'Tempo de simulacao (s)'
set ylabel 'Pacotes'
set grid
set autoscale

#Gray Scale
set palette gray
unset colorbox

AODV = '../../AODV/experimento1/pkts.dat'
DSDV = '../../DSDV/experimento1/pkts.dat'
OLSR = '../../OLSR/experimento1/pkts.dat'

plot AODV using 1:2 title 'AODV' with linespoints, \
	DSDV using 1:2 title 'DSDV' with linespoints, \
	OLSR using 1:2 title 'OLSR' with linespoints 

set output '../../doc/TCC/images/exp2_pkts.eps'

AODV = '../../AODV/experimento2/pkts.dat'
DSDV = '../../DSDV/experimento2/pkts.dat'
OLSR = '../../OLSR/experimento2/pkts.dat'

plot AODV using 1:2 title 'AODV' with linespoints, \
	DSDV using 1:2 title 'DSDV' with linespoints, \
	OLSR using 1:2 title 'OLSR' with linespoints 

