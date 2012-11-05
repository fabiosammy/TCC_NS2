#GNUPlot Script
reset

#EPS File
set terminal postscript eps enhanced color font 'Helvetica,22' 
set output '../../doc/TCC/images/exp1_delay.eps'

#Estilo
set style line
set style fill solid

#labels
set title 'Atraso medio fim a fim dos pacotes de dados'
set xlabel 'Tempo de simulacao (s)'
set ylabel 'Delay medio (ms)'
set grid
set autoscale

#Gray Scale
set palette gray
unset colorbox

AODV = '../../AODV/experimento1/delay.dat'
DSDV = '../../DSDV/experimento1/delay.dat'
OLSR = '../../OLSR/experimento1/delay.dat'

plot AODV using 1:2 title 'AODV' with linespoints, \
	DSDV using 1:2 title 'DSDV' with linespoints, \
	OLSR using 1:2 title 'OLSR' with linespoints 

set output '../../doc/TCC/images/exp2_delay.eps'

AODV = '../../AODV/experimento2/delay.dat'
DSDV = '../../DSDV/experimento2/delay.dat'
OLSR = '../../OLSR/experimento2/delay.dat'

plot AODV using 1:2 title 'AODV' with linespoints, \
	DSDV using 1:2 title 'DSDV' with linespoints, \
	OLSR using 1:2 title 'OLSR' with linespoints 

