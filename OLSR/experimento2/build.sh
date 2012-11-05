#!/bin/bash

echo "OLSR - EXPERIMENTO2:"

for MOVE in  $(ls ../../scripts/experimento2/movements/*.tcl) ; do
	MOVE=${MOVE/*\//}
	echo -ne "\tExecutando o movimento $MOVE... \t"
	ns experimento2.tcl $MOVE  >/dev/null 2>&1
	[ "$?" = "0" ] && echo "[DONE]" || echo "[FAIL]"
done

