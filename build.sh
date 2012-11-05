#!/bin/bash

echo -n "DSDV - Executando experimento 1... "
cd DSDV/experimento1
ns experimento1.tcl >/dev/null 2>&1
RETVAL=$?
cd ../../
[ "$RETVAL" = "0" ] && echo "[DONE]" || echo "[FAIL]"

echo -n "AODV - Executando experimento 1... "
cd AODV/experimento1
ns experimento1.tcl >/dev/null 2>&1
RETVAL=$?
cd ../../
[ "$RETVAL" = "0" ] && echo "[DONE]" || echo "[FAIL]"

echo -n "OLSR - Executando experimento 1... "
cd OLSR/experimento1
ns experimento1.tcl >/dev/null 2>&1
RETVAL=$?
cd ../../
[ "$RETVAL" = "0" ] && echo "[DONE]" || echo "[FAIL]"

echo -n "Extraindo média dados do experimento 1... "
cd scripts/extractData
./extractDataExperimento1.sh > ../../doc/experimento1.table
RETVAL=$?
cd ../../
[ "$RETVAL" = "0" ] && echo "[DONE]" || echo "[FAIL]"


#cd DSDV/experimento2
#./build.sh
#cd ../../

#cd AODV/experimento2
#./build.sh
#cd ../../

#cd OLSR/experimento2
#./build.sh
#cd ../../

