#======================================================================
# Simple MANET simulation
#
# Fabio L. Janiszevski - Jul 2012
#
#======================================================================

# Parametros principais
set val(chan)	Channel/WirelessChannel	;# channel type
set val(prop)	Propagation/TwoRayGround
set val(netif)	Phy/WirelessPhy		;# network interface type
set val(mac)	Mac/802_11		;# MAC type
set val(ifq)	Queue/DropTail/PriQueue	;# Interface queue type
set val(ll)	LL			;# Link layer type
set val(ant)	Antenna/OmniAntenna	;# Antenna type
#set val(ifq)	CMUPriQueue 		;# somente para DSR!
set val(ifqlen)	100
set val(nn)	2			;#Número de nós
set val(rp)	AODV			;#Protocolo

#Cria o Escalonador de Eventos
set ns [new Simulator]

#Configura os Arquivos de Trace
set tracefile [open out.tr w]
$ns trace-all $tracefile
set nf [open out.nam w]
$ns namtrace-all-wireless $nf 500 500	;#Para uma área de 500 por 500 metros

# Cria a topologia
set topo [new Topography]
$topo load_flatgrid 500 500		;#Cria o grid de 500x500 metros
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
	-agentTrace ON \
	-routerTrace ON \
	-macTrace ON \
	-movementTrace ON \
	-channel [new $val(chan)] 

# Configure nodes
for {set i 0} {$i < $val(nn) } {incr i} {
	set node_($i) [$ns node ]
	$node_($i) random-motion 0	;#Desabilitar movimento randômico dos nós
}

# Posiciona os nos
$node_(0) set X_ 5.0
$node_(0) set Y_ 2.0
$node_(0) set Z_ 0.0
$node_(1) set X_ 390.0
$node_(1) set Y_ 385.0
$node_(1) set Z_ 0.0

#Posição inicial dos nós no NAM
#for {set i 0} {$i < $val(nn)} {incr i} {
#	$ns initial_node_pos $n($i) 50
#}

# No1 segue em direcao ao no 0. Depois se afasta.
# sintaxe:
# <ns> at <tempo> "<nó> setdest <ponto X> <ponto Y> <Velocidade m/s>
$ns at  10.0 "$node_(0) setdest 40.0 22.1 0.5"
$ns at  30.0 "$node_(1) setdest 21.0  5.4 0.5"
$ns at  50.0 "$node_(1) setdest 20.0  5.4 0.5"
$ns at  80.0 "$node_(1) setdest 20.0  0.5 0.5"
$ns at 130.0 "$node_(1) setdest 20.0 22.1 0.5"

# Cria agentes: transporte e aplicacao
set tcp [new Agent/TCP]
$tcp set class_ 1			;#TCP Tahoe
$ns attach-agent $node_(0) $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $node_(1) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 10.0 "$ftp start"

#======================================================================
# Simulation Control
#======================================================================
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns at 150.0 "$node_($i) reset";
}
$ns at 150.0001 "stop"
$ns at 150.0002 "puts \"NS EXITING...\" ; $ns halt"
proc stop {} {
	global ns tracefile
	global ns nf
	$ns flush-trace
	close $tracefile
	close $nf
	exit 0
}
puts "Starting Simulation..."
$ns run

