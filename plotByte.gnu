#GNUPlot Script
reset

#EPS File
set terminal postscript eps enhanced color font 'Helvetica,10' 
set output 'doc/TCC/images/byte.eps'

#Estilo
set style line
set style fill solid

#labels
set title 'Quantidade de bytes de roteamento'
set xlabel 'Tempo (s)'
set ylabel 'Pacotes'
set grid
set autoscale

AODV = 'AODV/byte.dat'
DSDV = 'DSDV/byte.dat'
OLSR = 'OLSR/byte.dat'

plot AODV using 1:2 title 'AODV' with linespoints, \
	DSDV using 1:2 title 'DSDV' with linespoints, \
	OLSR using 1:2 title 'OLSR' with linespoints 

