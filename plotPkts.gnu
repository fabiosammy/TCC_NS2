#GNUPlot Script
reset

#EPS File
set terminal postscript eps enhanced color font 'Helvetica,10' 
set output 'doc/TCC/images/pkts.eps'

#Estilo
set style line
set style fill solid

#labels
set title 'Quantidade de pacotes de roteamento'
set xlabel 'Tempo (s)'
set ylabel 'Pacotes'
set grid
set autoscale

AODV = 'AODV/pkts.dat'
DSDV = 'DSDV/pkts.dat'
OLSR = 'OLSR/pkts.dat'

plot AODV using 1:2 title 'AODV' with linespoints, \
	DSDV using 1:2 title 'DSDV' with linespoints, \
	OLSR using 1:2 title 'OLSR' with linespoints 

