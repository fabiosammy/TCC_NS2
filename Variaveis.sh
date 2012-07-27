#!/bin/bash

TRAFEGO=$(awk '/^s/{soma += $8} END {print soma}' out.tr)


echo "
TRAFEGO=$TRAFEGO
" > out.log

