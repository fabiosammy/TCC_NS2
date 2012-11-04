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

