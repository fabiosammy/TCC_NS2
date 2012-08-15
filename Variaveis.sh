#!/bin/bash

NUM_DROP=$(awk 'BEGIN {num=0} /^D/{num+=1} END {print num}' out.tr)
NUM_SEND=$(awk 'BEGIN {num=0} /^s/{num+=1} END {print num}' out.tr)
NUM_RECEIVE=$(awk 'BEGIN {num=0} /^r/{num+=1} END {print num}' out.tr)
NUM_FORWARD=$(awk 'BEGIN {num=0} /^f/{num+=1} END {print num}' out.tr)
NUM_COLISION=$(awk 'BEGIN {num=0} /^c/{num+=1} END {print num}' out.tr)
TRAFEGO=$(
	awk '
		BEGIN{
			soma=0
			type="bytes"
		}
		/^s/{soma += $8} 
		END {
			if (soma > 1024){
				soma = soma / 1024
				type = "kbytes"
			}
			if (soma > 1024){
				soma = soma / 1024
				type = "mbytes"
			}
			print soma" "type
		}
	' out.tr)


echo -n "
TRAFEGO=$TRAFEGO
NUM_DROP=$NUM_DROP
NUM_RECEIVE=$NUM_RECEIVE
NUM_FORWARD=$NUM_FORWARD
NUM_COLISION=$NUM_COLISION
NUM_SEND=$NUM_SEND
" > out.log

