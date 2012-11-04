#======================================================================
# Simple MANET simulation
#
# Fabio L. Janiszevski - Jul 2012
#
#======================================================================

#======================================================================
# Functions
#======================================================================
source ../../scripts/experimento1/functions/attach_cbr.tcl
source ../../scripts/experimento1/functions/record.tcl

proc stop {} {
	global ns tracefile nf f0 f1 f2 val
	$ns flush-trace
	close $tracefile
	close $nf
	close $f0
	close $f1
	close $f2
	exec cat out.tr | perl ../../scripts/extractData/delay_calc_avg-ng.pl $val(t) 1 
	exit 0
}

#======================================================================
# Parametros principais
#======================================================================
source ../../scripts/experimento1/parameters.tcl

#======================================================================
# Protocolo
#======================================================================
set val(rp)	OLSR			;#Protocolo

#Cria o Escalonador de Eventos
set ns [new Simulator]

#Ativa sistema de trace melhorado
$ns use-newtrace

#Configura os Arquivos de Trace
set tracefile [open out.tr w]
$ns trace-all $tracefile
# Set NAM tracefile
set nf [open out.nam w]
$ns namtrace-all-wireless $nf $val(x) $val(y)	;#Para uma área de 500 por 500 metros

# Arquivos de estatística
set f0 [open lost.dat w]
set f1 [open byte.dat w]
set f2 [open pkts.dat w]

# Cria a topologia
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)		;#Cria o grid de 500x500 metros

# Cria o nosso "Deus" em relação ao número de nós
create-god $val(nn)

# Configure nodes
$ns node-config -adhocRouting $val(rp) \
	-llType $val(ll) \
	-macType $val(mac) \
	-ifqType $val(ifq) \
	-ifqLen $val(ifqlen) \
	-antType $val(ant) \
	-propType $val(prop) \
	-phyType $val(netif) \
	-topoInstance $topo \
	-agentTrace $AgentTrace \
	-routerTrace $RouterTrace \
	-macTrace $MacTrace \
	-movementTrace $Movement \
	-channel [new $val(chan)] 

# Configure nodes
for {set i 0} {$i < $val(nn) } {incr i} {
	set node($i) [$ns node]
	$node($i) random-motion 0	;#Desabilitar movimento randômico dos nós
	$ns initial_node_pos $node($i) 30
}

#Movement
source ../../scripts/experimento1/movement.tcl

#Traffic
source ../../scripts/experimento1/traffic.tcl

#======================================================================
# Simulation Control
#======================================================================
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns at $val(t) "$node($i) reset";
}

#Schedules
$ns at 0.0 "record $valsnn"
puts "In [expr $val(t)-10] we have sttoped the source traffic" 
$ns at $val(t).0001 "$ns nam-end-wireless $val(t).0002"
$ns at $val(t).0002 "stop"
$ns at $val(t).0003 "puts \"NS EXITING...\" ; $ns halt"

puts "Starting Simulation..."
$ns run

