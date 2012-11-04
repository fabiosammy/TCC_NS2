proc record { valsnn } {
	global f0 f1 f2
	global sink

	#Get an instance of the simulator
	set ns [Simulator instance]

	#Set the time after which the procedure should be called again
	set time 5.0

	#Variables to record
	set Slosts 0
	set Sbytes 0 
	set Spakts 0

	#How many lost packages?
	for {set i 0} {$i < $valsnn } {incr i} {
		set Slosts [expr $Slosts + [$sink($i) set nlost_]]
	}
	#How many bytes have been received by the traffic sinks?
	for {set i 0} {$i < $valsnn } {incr i} {
		set Sbytes [expr $Sbytes + [$sink($i) set bytes_]]
	}
	#How many packages expected?
	for {set i 0} {$i < $valsnn } {incr i} {
		set Spakts [expr $Spakts + [$sink($i) set npkts_]]
	}

	#Get the current time
	set now [$ns now]

	#Record informations
	puts $f0 "$now\t$Slosts"
	puts $f1 "$now\t$Sbytes"
	puts $f2 "$now\t$Spakts"

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

