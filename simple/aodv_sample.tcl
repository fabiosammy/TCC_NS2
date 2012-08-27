#======================================================================
# Simple MANET simulation
#
# Fabio L. Janiszevski - Jul 2012
#
#======================================================================

# Parametros principais
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
set MacTrace	OFF			;#
set Movement	OFF			;#
set val(nn)	3			;#Número de nós
set val(rp)	AODV			;#Protocolo
set val(x)	500			;#Tamanho X
set val(y)	500			;#Tamanho Y

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
#set f1 [open out1.tr w]
#set f2 [open out2.tr w]

# Uso de cores para identificação no NAM
#$ns color 0 Blue
$ns color 1 Green 
$ns color 2 Red
$ns color 3 Orange

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
$node_(0) set X_  10.0
$node_(0) set Y_  50.0
$node_(0) set Z_   0.0
#$ns at 0.1 "$node_(0) setdest 50.0 50.0 0.0"
#$ns color $node_(0) Blue
# NÓ 1
$node_(1) set X_ 125.0
$node_(1) set Y_  70.0
$node_(1) set Z_   0.0
#$ns at 0.1 "$node_(1) setdest 200.0 450.0 0.0"
$node_(1) color Red
# NÓ 2
$node_(2) set X_ 230.0
$node_(2) set Y_  50.0
$node_(2) set Z_   0.0
#$ns at 0.1 "$node_(2) setdest 450.0 100.0 0.0"
#$ns color $node_(2) Green
# NÓ 3
#$node_(3) set X_ 150.0
#$node_(3) set Y_ 100.0
#$node_(3) set Z_   0.0
#$ns at 0.1 "$node_(3) setdest 150.0 100.0 0.0"
#$ns color $node_(3) Green


#Posição inicial dos nós no NAM
#$ns initial_node_pos <node> <size>
# * <size> = Tamanho do nó no NAM
for {set i 0} {$i < $val(nn)} {incr i} {
	$ns initial_node_pos $node_($i) 20
}

# No1 segue em direcao ao no 0. Depois se afasta.
# sintaxe:
# <ns> at <tempo> "<nó> setdest <ponto X> <ponto Y> <Velocidade m/s>
$ns at 0.1 "$node_(0) setdest  10.0  50.0  1.5"
$ns at 0.1 "$node_(1) setdest 200.0 200.0  1.5"
$ns at 0.1 "$node_(2) setdest 450.0 450.0 10.5"
#$ns at 0.1 "$node_(3) setdest 450.0 450.0 1.5"

#======================================================================
# CBR - Escolhido pois é o serviço aplicado para audio/video
#======================================================================
for {set i 0} {$i < $val(nn)} {incr i} {
	#Cria o agente UDP
	set udp_($i) [new Agent/UDP]
		#Anexa uma cor ao agente
		#$udp_($i) set class_ $i
		#$udp_($i) set fid_ $i
	#Cria o agente CBR
	set cbr_($i) [new Application/Traffic/CBR]
		#Tamanho do pacote (em bytes) - DEFAULT: 210
		$cbr_($i) set packetSize_ 500
		#Taxa de envio dos pacotes - DEFAUL: 448kb
		$cbr_($i) set rate_ 2Mb
		#Coloração
		#$cbr_($i) set class_ $i
	#Cria o agente NULL (SINK)
	set null_($i) [new Agent/Null]
		#coloração
		#$null_($i) set class_ $i
}

#Cria uma comunicação com o nó 2 ao nó 0
$ns attach-agent $node_(2) $udp_(0)	;#Anexa o gerador de pacotes
$ns attach-agent $node_(0) $null_(0)	;#Anexa o consumidor de pacotes
$ns connect $udp_(0) $null_(0)		;#Cria o ponto de conexão entre o gerador e o consumidor
$cbr_(0) attach-agent $udp_(0)		;#Anexa uma aplicação ao gerador
$ns at 0.1 "$cbr_(0) start"		;#Inicia a aplicação
$ns at 140.0 "$cbr_(0) stop" 		;#Para a aplicação

#Cria uma comunicação com o nó 0 ao nó 2
$ns attach-agent $node_(0) $udp_(1)	;#Anexa o gerador de pacotes
$ns attach-agent $node_(2) $null_(1)	;#Anexa o consumidor de pacotes
$ns connect $udp_(1) $null_(1)		;#Cria o ponto de conexão entre o gerador e o consumidor
$cbr_(1) attach-agent $udp_(1)		;#Anexa uma aplicação ao gerador
$ns at 0.1 "$cbr_(1) start"		;#Inicia a aplicação
$ns at 140.0 "$cbr_(1) stop" 		;#Para a aplicação
$udp_(1) set class_ 2

#Cria uma comunicação com o nó 1 ao nó 2
$ns attach-agent $node_(1) $udp_(2)	;#Anexa o gerador de pacotes
$ns attach-agent $node_(2) $null_(2)	;#Anexa o consumidor de pacotes
$ns connect $udp_(2) $null_(2)		;#Cria o ponto de conexão entre o gerador e o consumidor
$cbr_(2) attach-agent $udp_(2)		;#Anexa uma aplicação ao gerador
$ns at 0.1 "$cbr_(2) start"		;#Inicia a aplicação
$ns at 140.0 "$cbr_(2) stop" 		;#Para a aplicação

#======================================================================
# Record function 
#======================================================================
proc record {} {
	global f0 ns null_(0)
	# Intervalo da execução
	set time 0.5
	# Calcula o número de bytes recebidos 
	set bw0 [$null_(0) set bytes_]
	# Tempo atual
	set now [$ns now]
	# Calcula a largura da banda
	puts $f0 "$now [expr $bw0/$time*8/1000000]"
	$null_(0) set bytes_ 0
	# Chamada recursiva
	$ns at [expr $now+$time] "record"
}

#======================================================================
# Simulation Control
#======================================================================
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns at 150.0 "$node_($i) reset";
}

#$ns at 0.0 "record"
$ns at 150.0001 "$ns nam-end-wireless 150.0002"
$ns at 150.0002 "stop"
$ns at 150.0003 "puts \"NS EXITING...\" ; $ns halt"
proc stop {} {
	global ns tracefile nf f0
	$ns flush-trace
	close $tracefile
	close $nf
	close $f0
	exit 0
}
puts "Starting Simulation..."
$ns run

