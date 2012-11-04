#======================================================================
# Simple MANET simulation
#
# Fabio L. Janiszevski - Jul 2012
#
#======================================================================

if { $argc != 1 } {
	puts "ERROR!! You must be pass a scenario moviment"
	exit 1
}

#======================================================================
# Functions
#======================================================================
source ../../scripts/experimento2/functions/attach_cbr.tcl
source ../../scripts/experimento2/functions/record.tcl

proc stop {} {
	global ns_ tracefile nf f0 f1 f2 val
	$ns_ flush-trace
	close $tracefile
	close $nf
	close $f0
	close $f1
	close $f2
	exec cat out_$val(mm)_.tr | perl ../../scripts/extractData/delay_calc_avg-ng.pl $val(t) 1 delay_$val(mm)_.dat 
	exit 0
}

#======================================================================
# Parametros principais
#======================================================================
source ../../scripts/experimento2/parameters.tcl

#======================================================================
# Protocolo
#======================================================================
set val(rp)	AODV			;#Protocolo
#======================================================================
# Scenarios 
#======================================================================
set val(mm)	[ lindex $argv 0 ]	;#Cenário de movimentos

#Cria o Escalonador de Eventos
set ns_ [new Simulator]

#Ativa sistema de trace melhorado
$ns_ use-newtrace

#Configura os Arquivos de Trace
set tracefile [open out_$val(mm)_.tr w]
$ns_ trace-all $tracefile
# Set NAM tracefile
set nf [open out_$val(mm)_.nam w]
$ns_ namtrace-all-wireless $nf $val(x) $val(y)	;#Para uma área de 500 por 500 metros

# Arquivos de estatística
set f0 [open lost_$val(mm)_.dat w]
set f1 [open byte_$val(mm)_.dat w]
set f2 [open pkts_$val(mm)_.dat w]

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

#Movement
source ../../scripts/experimento2/movements/$val(mm)

#Traffic
source ../../scripts/experimento2/traffic.tcl

#======================================================================
# Simulation Control
#======================================================================
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns_ at $val(t) "$node_($i) reset";
}

#Schedules
$ns_ at 0.0 "record $valsnn"
puts "In [expr $val(t)-10] we have sttoped the source traffic" 
$ns_ at $val(t).0001 "$ns_ nam-end-wireless $val(t).0002"
$ns_ at $val(t).0002 "stop"
$ns_ at $val(t).0003 "puts \"NS EXITING...\" ; $ns_ halt"

puts "Starting Simulation..."
$ns_ run

