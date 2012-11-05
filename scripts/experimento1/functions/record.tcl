proc record { valsnn } {
	global f0 f1 f2 f3
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
	#Taxa de entrega
	for {set i 0} {$i < $valsnn } {incr i} {
		if {[$sink($i) set npkts_] > 0} {
			set taxa($i) [expr ([$sink($i) set npkts_]*100)/([$sink($i) set npkts_]+[$sink($i) set nlost_])]
		} else {
			set taxa($i) 100
		}
	}
	

	#Get the current time
	set now [$ns now]

	#Record informations
	puts $f0 "$now\t$lost(0)"
	puts $f1 "$now\t$byte(0)"
	puts $f2 "$now\t$pkts(0)"
	puts $f3 "$now\t$taxa(0)"

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

