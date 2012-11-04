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
	$this_traffic set packetSize_ 512
	$this_traffic set interval_ 0.5 
	$this_traffic set random_ 1
#	$this_traffic set maxpkts_ 10000
	$this_traffic set rate 11Mb

	# Attach traffic source to the traffic generator
	$this_traffic attach-agent $this_source
	#Connect the source and the sink
	$ns connect $this_source $this_sink
	puts "Test this nodes: $this_node to $this_sink; UDP=$this_source; CBR=$this_traffic"
	return $this_traffic

}

