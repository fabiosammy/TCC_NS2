#SINK (Consumidores)
#Grupos consumidores
#Grupo1 -> Tanque
set sink(0) [new Agent/LossMonitor]
$ns_ attach-agent $node_(1) $sink(0)
#Grupo2 -> Tanque
set sink(1) [new Agent/LossMonitor]
$ns_ attach-agent $node_(5) $sink(1)
#Grupo3 -> Tanque
set sink(2) [new Agent/LossMonitor]
$ns_ attach-agent $node_(9) $sink(2)
#Grupo4 -> Tanque
set sink(3) [new Agent/LossMonitor]
$ns_ attach-agent $node_(13) $sink(3)

#Comandos
#Grupo 1 -> Comandante do grupo
set sink(4) [new Agent/LossMonitor]
$ns_ attach-agent $node_(2) $sink(4)
$ns_ attach-agent $node_(3) $sink(4)
$ns_ attach-agent $node_(4) $sink(4)
#Grupo 2 -> Comandante do grupo
set sink(5) [new Agent/LossMonitor]
$ns_ attach-agent $node_(6) $sink(5)
$ns_ attach-agent $node_(7) $sink(5)
$ns_ attach-agent $node_(8) $sink(5)
#Grupo 3 -> Comandante do grupo
set sink(6) [new Agent/LossMonitor]
$ns_ attach-agent $node_(10) $sink(6)
$ns_ attach-agent $node_(11) $sink(6)
$ns_ attach-agent $node_(12) $sink(6)
#Grupo 3 -> Comandante do grupo
set sink(7) [new Agent/LossMonitor]
$ns_ attach-agent $node_(14) $sink(7)
$ns_ attach-agent $node_(15) $sink(7)
$ns_ attach-agent $node_(16) $sink(7)

#CBR Sources (Alimentadores)
#Tanque -> Grupo 1
set source(0)  [attach-expoo-cbr $node_(0) $sink(0)]
$ns_ at   0.1 "$source(0) start"
$ns_ at 590.0 "$source(0) stop"

#Tanque -> Grupo 2 
set source(1)  [attach-expoo-cbr $node_(0) $sink(1)]
$ns_ at   0.1 "$source(1) start"
$ns_ at 590.0 "$source(1) stop"

#Tanque -> Grupo 3
set source(2)  [attach-expoo-cbr $node_(0) $sink(2)]
$ns_ at   0.1 "$source(2) start"
$ns_ at 590.0 "$source(2) stop"

#Tanque -> Grupo 4
set source(3)  [attach-expoo-cbr $node_(0) $sink(3)]
$ns_ at   0.1 "$source(3) start"
$ns_ at 590.0 "$source(3) stop"

#Comandante do grupo -> Grupo1
set source(4)  [attach-expoo-cbr $node_(1) $sink(4)]
$ns_ at   0.1 "$source(4) start"
$ns_ at 590.0 "$source(4) stop"

#Comandante do grupo -> Grupo2
set source(5)  [attach-expoo-cbr $node_(5) $sink(5)]
$ns_ at   0.1 "$source(5) start"
$ns_ at 590.0 "$source(5) stop"

#Comandante do grupo -> Grupo3
set source(6)  [attach-expoo-cbr $node_(9) $sink(6)]
$ns_ at   0.1 "$source(6) start"
$ns_ at 590.0 "$source(6) stop"

#Comandante do grupo -> Grupo4
set source(7)  [attach-expoo-cbr $node_(13) $sink(7)]
$ns_ at   0.1 "$source(7) start"
$ns_ at 590.0 "$source(7) stop"

