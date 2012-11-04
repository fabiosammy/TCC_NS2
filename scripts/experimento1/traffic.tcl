#SINK
set sink(0) [new Agent/LossMonitor]
$ns attach-agent $node(0) $sink(0)

#CBR Sources
set source(0)  [attach-expoo-cbr $node(2) $sink(0)]
$ns at   0.1 "$source(0) start"
$ns at 290.0 "$source(0) stop"
