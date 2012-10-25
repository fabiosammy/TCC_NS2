#GNUPlot Script
reset
#set terminal png transparent nocrop enhanced
set terminal png nocrop enhanced

set output "band.png"

#Estilo
set style line
#set linestyle 1 linewidth 3
#set style data histogram
#set style histogram cluster gap 5
set style fill solid
set key right
set boxwidth 0.4
#set logscale y

#labels
set title 'Trafego de banda'
set xlabel 'Tempo (s)'
set ylabel 'Trafego (Mbit/s)'
#set xrange [0:]
set yrange [0:0.4]
#set yzeroaxis
set grid
#set autoscale

data = 'band.dat'

plot data using 1:2 title 'Soldado 0' with linespoints, \
	data using 1:3 title 'Soldado 1' with linespoints, \
	data using 1:4 title 'Soldado 2' with linespoints, \
	data using 1:5 title 'Super Soldado' with linespoints



