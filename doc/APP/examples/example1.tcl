#======================================================================
# Simple MANET simulation
#
# Fabio L. Janiszevski - Jul 2012
#
#======================================================================
proc stop {} {
	global ns_ tracefile nf
	$ns_ flush-trace
	close $tracefile
	close $nf
	exit 0
}


#======================================================================
# Parametros principais
#======================================================================
set val(chan)	Channel/WirelessChannel	;# channel type
set val(prop)	Propagation/TwoRayGround;# radio model propagation
set val(netif)	Phy/WirelessPhy		;# network interface type
set val(mac)	Mac/802_11		;# MAC type
set val(ifq)	Queue/DropTail/PriQueue	;# Interface queue type
set val(ll)	LL			;# Link layer type
set val(ant)	Antenna/OmniAntenna	;# Antenna type
set val(ifqlen)	100			;#Max packet in ifq
set AgentTrace	ON			;#
set RouterTrace	ON			;#
set MacTrace	ON			;#
set Movement	ON			;#
set val(nn)	4			;#Número de nós
set valsnn	1			;#Número de sinks
set val(rp)	AODV			;#Protocolo
set val(t)	300			;#Tempo de duração da simulação (em segundos)
set val(x)	1000			;#Tamanho X
set val(y)	1000			;#Tamanho Y

#======================================================================
# Initialize the SharedMedia interface with parameters to make
# it work like the 914MHz Lucent WaveLAN DSSS radio interface
Phy/WirelessPhy set CPThresh_ 10.0
Phy/WirelessPhy set CSThresh_ 1.559e-11
Phy/WirelessPhy set RXThresh_ 3.652e-10
Phy/WirelessPhy set Rb_ 2*1e6
Phy/WirelessPhy set Pt_ 0.2818
Phy/WirelessPhy set freq_ 914e+6 
Phy/WirelessPhy set L_ 1.0

#Cria o Escalonador de Eventos
set ns_ [new Simulator]

#Ativa sistema de trace melhorado
$ns_ use-newtrace

#Configura os Arquivos de Trace
set tracefile [open out.tr w]
$ns_ trace-all $tracefile
# Set NAM tracefile
set nf [open out.nam w]
$ns_ namtrace-all-wireless $nf $val(x) $val(y)	;#Para uma área de 500 por 500 metros

# Cria a topologia
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)		;#Cria o grid de 500x500 metros

# Cria o nosso "Deus" em relação ao número de nós
create-god $val(nn)

# Configure nodes
$ns_ node-config -adhocRouting $val(rp) \
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
	set node_($i) [$ns_ node]
	$node_($i) random-motion 0	;#Desabilitar movimento randômico dos nós
	$ns_ initial_node_pos $node_($i) 30
}

# Posiciona os nos
source movement.tcl

#======================================================================
# Simulation Control
#======================================================================
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns_ at $val(t) "$node_($i) reset";
}

#Schedules
#$ns at 0.0 "record $valsnn"
#puts "In [expr $val(t)-10] we have sttoped the source traffic" 
$ns_ at $val(t).0001 "$ns_ nam-end-wireless $val(t).0002"
$ns_ at $val(t).0002 "stop"
$ns_ at $val(t).0003 "puts \"NS EXITING...\" ; $ns_ halt"

puts "Starting Simulation..."
$ns_ run

