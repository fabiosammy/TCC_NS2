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
set val(t)	300			;#Tempo de duração da simulação (em segundos)
set val(x)	500			;#Tamanho X
set val(y)	500			;#Tamanho Y

