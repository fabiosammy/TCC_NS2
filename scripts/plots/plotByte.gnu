#GNUPlot Script
reset

#EPS File
set terminal postscript eps enhanced color font 'Helvetica,22' 
set output '../../doc/TCC/images/exp1_byte.eps'

#Estilo
set style line
set style fill solid

#labels
set title 'Numero de bytes de roteamento'
set xlabel 'Tempo de simulacao (s)'
set ylabel 'Bytes'
set grid
set autoscale

#Gray Scale
set palette gray
unset colorbox

AODV = '../../AODV/experimento1/byte.dat'
DSDV = '../../DSDV/experimento1/byte.dat'
OLSR = '../../OLSR/experimento1/byte.dat'

plot AODV using 1:2 title 'AODV' with linespoints, \
	DSDV using 1:2 title 'DSDV' with linespoints, \
	OLSR using 1:2 title 'OLSR' with linespoints 

