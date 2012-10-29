#!bin/bash

neato -Teps experimento1.dot -o ../images/experimento1.eps
neato -Teps experimento2.dot -o ../images/experimento2.eps
neato -Teps dsdvOperation.dot -o ../images/dsdvOperation.eps
dot -Teps aodvOperation.dot -o ../images/aodvOperation.eps
dot -Teps aodvRREQ.dot -o ../images/aodvRREQ.eps
dot -Teps aodvRREP.dot -o ../images/aodvRREP.eps

