#======================================================================
# Simple MANET simulation
#
# Fabio L. Janiszevski - Jul 2012
#
#======================================================================

#======================================================================
# Functions
#======================================================================
proc attach-expoo-cbr { node sink } {
	#Get an instance of the simulator
	set ns [Simulator instance]

	#Create a UDP agent and attach it to the node
	set source [new Agent/UDP]
	$source set class_ 1
	$ns attach-agent $node $source

	#Create an Expoo traffic agent and set its configuration parameters
	set traffic [new Application/Traffic/CBR]
	$traffic set packetSize 500
	$traffic set rate 2Mb

	# Attach traffic source to the traffic generator
	$traffic attach-agent $source
	#Connect the source and the sink
	$ns connect $source $sink
	puts "Test this nodes: $node to $sink; UDP=$source; CBR=$traffic"
	return $traffic
}

proc record {} {
	global sink0 sink1 sink2 f0 f1 f2

	#Get an instance of the simulator
	set ns [Simulator instance]

	#Set the time after which the procedure should be called again
	set time 0.5

	#How many bytes have been received by the traffic sinks?
	set loss0 [$sink0 set nlost_]
	set bw1 [$sink1 set bytes_]

	#Get the current time
	set now [$ns now]

	#Calculate the bandwidth (in MBit/s) and write it to the files
	puts $f0 "$now\t$loss0"
	puts $f1 "$now\t[expr $bw1/$time*8/1000000]"

	#Reset the bytes_ values on the traffic sinks
	$sink0 clear
	$sink1 set bytes_ 0

	#Re-schedule the procedure
	$ns at [expr $now+$time] "record"
}

proc stop {} {
	global ns tracefile nf f0 f1 f2
	$ns flush-trace
	close $tracefile
	close $nf
	close $f0
	close $f1
	close $f2
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
#set val(ifq)	CMUPriQueue 		;# somente para DSR!
set val(ifqlen)	100			;#Max packet in ifq
set AgentTrace	ON			;#
set RouterTrace	ON			;#
set MacTrace	ON			;#
set Movement	ON			;#
set val(nn)	3			;#Número de nós
set val(rp)	AODV			;#Protocolo
set val(t)	150			;#Tempo que finaliza
set val(x)	500			;#Tamanho X
set val(y)	500			;#Tamanho Y

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
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]

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
	set node_($i) [$ns node]
	$node_($i) random-motion 0	;#Desabilitar movimento randômico dos nós
}

# Posiciona os nos
# NÓ 0
$node_(0) set X_  10.0; $node_(0) set Y_  50.0; $node_(0) set Z_   0.0
# NÓ 1
$node_(1) set X_ 125.0; $node_(1) set Y_  70.0; $node_(1) set Z_   0.0
# NÓ 2
$node_(2) set X_ 230.0; $node_(2) set Y_  50.0; $node_(2) set Z_   0.0
# NÓ 3
#$node_(3) set X_ 150.0; #$node_(3) set Y_ 100.0; #$node_(3) set Z_   0.0


#Posição inicial dos nós no NAM
#$ns initial_node_pos <node> <size>
# * <size> = Tamanho do nó no NAM
for {set i 0} {$i < $val(nn)} {incr i} {
	$ns initial_node_pos $node_($i) 30
}

# No1 segue em direcao ao no 0. Depois se afasta.
# sintaxe:
# <ns> at <tempo> "<nó> setdest <ponto X> <ponto Y> <Velocidade m/s>
$ns at 0.1 "$node_(0) setdest  10.0  50.0  1.5"
$ns at 0.1 "$node_(1) setdest 200.0 200.0  1.5"
$ns at 0.1 "$node_(2) setdest 450.0 450.0 10.5"
#$ns at 0.1 "$node_(3) setdest 450.0 450.0 1.5"

#Label define
$ns at 0.0 "$node_(0) label Soldier_1"
$ns at 0.0 "$node_(1) label Soldier_2"
$ns at 0.0 "$node_(2) label Tank"

#Color packages
$node_(2) color green
$ns at 0.0 "$node_(2) color green"

#SINK
#set sink0 [new Agent/LossMonitor]
#set sink1 [new Agent/LossMonitor]
#set sink2 [new Agent/LossMonitor]
set sink0 [new Agent/Null] 
set sink1 [new Agent/Null] 
set sink2 [new Agent/Null] 

$ns attach-agent $node_(0) $sink0
$ns attach-agent $node_(1) $sink1
$ns attach-agent $node_(2) $sink2

set source0 [attach-expoo-cbr $node_(2) $sink0]
set source1 [attach-expoo-cbr $node_(0) $sink2]
set source2 [attach-expoo-cbr $node_(1) $sink2]

# Uso de cores para identificação no NAM
$ns color 1 magenta
$ns color 2 blue
$ns color 3 cyan
$ns color 4 green
$ns color 5 yellow
$ns color 6 black
$ns color 7 magenta
$ns color 8 gold
$ns color 9 red
$ns color 10 cornflowerblue
$ns color 11 deepskyblue
$ns color 12 steelblue
$ns color 13 navy

#======================================================================
# Simulation Control
#======================================================================
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns at $val(t).0 "$node_($i) reset";
}

#Schedules
#$ns at 0.0 "record"
$ns at 0.1 "$source0 start"
$ns at 0.1 "$source1 start"
$ns at 0.1 "$source2 start"
$ns at 140.0 "$source0 stop"
$ns at 140.0 "$source1 stop"
$ns at 140.0 "$source2 stop"
$ns at $val(t).0001 "$ns nam-end-wireless $val(t).0002"
$ns at $val(t).0002 "stop"
$ns at $val(t).0003 "puts \"NS EXITING...\" ; $ns halt"

puts "Starting Simulation..."
$ns run

