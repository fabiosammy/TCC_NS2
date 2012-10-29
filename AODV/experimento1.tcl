#======================================================================
# Simple MANET simulation
#
# Fabio L. Janiszevski - Jul 2012
#
#======================================================================

#======================================================================
# Functions
#======================================================================
proc attach-expoo-cbr { this_node this_sink } {
	#Get an instance of the simulator
	set ns [Simulator instance]

	#Create a UDP agent and attach it to the node
	set this_source [new Agent/UDP]
	$ns attach-agent $this_node $this_source

	#Create an Expoo traffic agent and set its configuration parameters
	set this_traffic [new Application/Traffic/CBR]
	$this_traffic set packetSize 500
	$this_traffic set rate 11Mb

	# Attach traffic source to the traffic generator
	$this_traffic attach-agent $this_source
	#Connect the source and the sink
	$ns connect $this_source $this_sink
	puts "Test this nodes: $this_node to $this_sink; UDP=$this_source; CBR=$this_traffic"
	return $this_traffic

}

proc record { valsnn } {
	global f0 f1 f2
	global sink

	#Get an instance of the simulator
	set ns [Simulator instance]

	#Set the time after which the procedure should be called again
	set time 5.0

	#How many lost packages?
	for {set i 0} {$i < $valsnn } {incr i} {
		set lost($i) [$sink($i) set nlost_]
	}
	#How many bytes have been received by the traffic sinks?
	for {set i 0} {$i < $valsnn } {incr i} {
		set byte($i) [$sink($i) set bytes_]
	}
	#How many packages expected?
	for {set i 0} {$i < $valsnn } {incr i} {
		set pkts($i) [$sink($i) set npkts_]
	}

	#Get the current time
	set now [$ns now]

	#Record informations
	puts $f0 "$now\t$lost(0)"
	puts $f1 "$now\t$byte(0)"
	puts $f2 "$now\t$pkts(0)"

	#Reset the bytes_ values on the traffic sinks
	for {set i 0} {$i < $valsnn } {incr i} {
		$sink($i) clear
		#Lost packages reset
		$sink($i) set nlost_ 0
		#Received bytes
		$sink($i) set bytes_ 0
		#Received packages
		$sink($i) set npkts_ 0
	}

	#Re-schedule the procedure
	$ns at [expr $now+$time] "record $valsnn"
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
set val(ifqlen)	100			;#Max packet in ifq
set AgentTrace	ON			;#
set RouterTrace	ON			;#
set MacTrace	ON			;#
set Movement	ON			;#
set val(nn)	4			;#Número de nós
set valsnn	1			;#Número de sinks
set val(rp)	AODV			;#Protocolo
set val(t)	300			;#Tempo de duração da simulação (em segundos)
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

# Posiciona os nos
# Soldado 0 
$node(0) set X_  60.0; $node(0) set Y_  10.0; $node(0) set Z_   0.0
$ns at 0.0 "$node(0) label Soldado_0"
# Soldado 1
$node(1) set X_ 200.0; $node(1) set Y_  50.0; $node(1) set Z_   0.0
$ns at 0.0 "$node(1) label Soldado_1"
# Soldado 2
$node(2) set X_ 340.0; $node(2) set Y_  10.0; $node(2) set Z_   0.0
$ns at 0.0 "$node(2) label Soldado_2"
# Super Soldado
$node(3) set X_ 200.0; $node(3) set Y_ 300.0; $node(3) set Z_   0.0
$ns at 0.0 "$node(3) label Soldado_3"

# Comandos de movimento 
# sintaxe:
# <ns> at <tempo> "<nó> setdest <ponto X> <ponto Y> <Velocidade m/s>
$ns at   0.1 "$node(0) setdest  60.0 460.0  1.5"
$ns at   0.1 "$node(1) setdest 200.0 150.0  1.5"
$ns at   0.1 "$node(2) setdest 340.0 460.0  1.5"
$ns at   0.1 "$node(3) setdest 200.0 300.0  1.5"
$ns at 150.0 "$node(3) setdest 200.0 450.0  1.5"

#SINK
set sink(0) [new Agent/LossMonitor]
$ns attach-agent $node(0) $sink(0)

#CBR Sources
set source(0)  [attach-expoo-cbr $node(2) $sink(0)]
$ns at   0.1 "$source(0) start"
$ns at 290.0 "$source(0) stop"

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

