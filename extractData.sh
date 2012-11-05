#!/bin/bash

echo "Extraindo dados do experimento 2... "

echo -n "DSDV - Extraindo dados... "
cd DSDV/experimento2
../../scripts/extractData/extractDataExperimento2.sh
RETVAL=$?
cd ../../
[ "$RETVAL" = "0" ] && echo "[DONE]" || echo "[FAIL]"

echo -n "AODV - Extraindo dados... "
cd AODV/experimento2
../../scripts/extractData/extractDataExperimento2.sh
RETVAL=$?
RETVAL=$?
cd ../../
[ "$RETVAL" = "0" ] && echo "[DONE]" || echo "[FAIL]"

echo -n "OLSR - Extraindo dados... "
cd OLSR/experimento2
../../scripts/extractData/extractDataExperimento2.sh
RETVAL=$?
RETVAL=$?
cd ../../
[ "$RETVAL" = "0" ] && echo "[DONE]" || echo "[FAIL]"


