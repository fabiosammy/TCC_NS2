#!/bin/bash

neato -Teps experimento1.dot -o ../images/experimento1.eps
neato -Teps experimento2.dot -o ../images/experimento2.eps
neato -Teps dsdvOperation.dot -o ../images/dsdvOperation.eps
dot -Teps aodvOperation.dot -o ../images/aodvOperation.eps
dot -Teps aodvRREQ.dot -o ../images/aodvRREQ.eps
dot -Teps aodvRREP.dot -o ../images/aodvRREP.eps


dot -Teps olsrOperationStep1.dot -o ../images/olsrOperationStep1.eps
dot -Teps olsrOperationStep2.dot -o ../images/olsrOperationStep2.eps
dot -Teps olsrOperationStep3.dot -o ../images/olsrOperationStep3.eps
dot -Teps olsrOperationStep4.dot -o ../images/olsrOperationStep4.eps
dot -Teps olsrOperationStep5.dot -o ../images/olsrOperationStep5.eps
dot -Teps olsrOperationStep6.dot -o ../images/olsrOperationStep6.eps
dot -Teps olsrOperationStep7.dot -o ../images/olsrOperationStep7.eps

