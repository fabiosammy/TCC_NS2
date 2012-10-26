#GNUPlot Script
reset

#PNG File
#set terminal png transparent nocrop enhanced
#set terminal png nocrop enhanced
#set output "lost.png"

#SVG File
#set terminal svg size 800,600 fname 'Verdana, Helvetica, Arial, sans-serif' 
#set output 'lost.svg'

#WTX File
#set terminal wxt enhanced font 'Verdana,9' persist
#set output 'lost.wxt'

set terminal postscript eps enhanced color font 'Helvetica,10' 
set output 'lost.eps'

#Estilo
set style line
#set linestyle 1 linewidth 3
#set style data histogram
#set style histogram cluster gap 5
set style fill solid
#set key right
#set boxwidth 0.4
#set logscale y

#labels
set title 'Pacotes perdidos'
set xlabel 'Tempo (s)'
set ylabel 'Pacotes'
#set xrange [0:]
#set yrange [0:]
#set yzeroaxis
set grid
set autoscale

data = 'lost.dat'

plot data using 1:2 title 'Soldado 0' with linespoints, \
	data using 1:3 title 'Soldado 1' with linespoints, \
	data using 1:4 title 'Soldado 2' with linespoints, \
	data using 1:5 title 'Super Soldado' with linespoints



