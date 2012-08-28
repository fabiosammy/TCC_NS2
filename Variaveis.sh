#!/bin/bash

OUT_FILE=$1
[ -z "$OUT_FILE" ] && OUT_FILE="out"

NUM_DROP=$(awk 'BEGIN {num=0} /^d/{num+=1} END {print num}' out.tr)
NUM_SEND=$(awk 'BEGIN {num=0} /^s.* AGT/{num++} END {print num}' out.tr)
NUM_RECEIVE=$(awk 'BEGIN {num=0} /^r.* AGT/{num++} END {print num}' out.tr)
NUM_FORWARD=$(awk 'BEGIN {num=0} /^f.* RTR/{num++} END {print num}' out.tr)
NUM_COLISION=$(awk 'BEGIN {num=0} /^c/{num+=1} END {print num}' out.tr)
NUM_FORWARD_REQUEST=$(grep "^f" out.tr | grep "Pc REQUEST" | awk 'END{print NR}')
NUM_SEND_REQUEST=$(grep "^s" out.tr | grep "Pc REQUEST" | awk 'END{print NR}')
NUM_RECEIVE_REQUEST=$(grep "^r" out.tr | grep "Pc REQUEST" | awk 'END{print NR}')
NUM_FORWARD_REPLY=$(grep "^f" out.tr | grep "Pc REPLY" | awk 'END{print NR}')
NUM_SEND_REPLY=$(grep "^s" out.tr | grep "Pc REPLY" | awk 'END{print NR}')
NUM_RECEIVE_REPLY=$(grep "^r" out.tr | grep "Pc REPLY" | awk 'END{print NR}')
NUM_FORWARD_ERROR=$(grep "^f" out.tr | grep "Pc ERROR" | awk 'END{print NR}')
NUM_SEND_ERROR=$(grep "^s" out.tr | grep "Pc ERROR" | awk 'END{print NR}')
NUM_RECEIVE_ERROR=$(grep "^r" out.tr | grep "Pc ERROR" | awk 'END{print NR}')
NUM_FORWARD_HELLO=$(grep "^f" out.tr | grep "Pc HELLO" | awk 'END{print NR}')
NUM_SEND_HELLO=$(grep "^s" out.tr | grep "Pc HELLO" | awk 'END{print NR}')
NUM_RECEIVE_HELLO=$(grep "^r" out.tr | grep "Pc HELLO" | awk 'END{print NR}')

echo -n "#Estatísticas de dados do tracefile
NUM_COLISION=$NUM_COLISION
NUM_DROP=$NUM_DROP
NUM_SEND=$NUM_SEND
NUM_RECEIVE=$NUM_RECEIVE
NUM_FORWARD=$NUM_FORWARD
#REQUEST
NUM_SEND_REQUEST=$NUM_SEND_REQUEST
NUM_RECEIVE_REQUEST=$NUM_RECEIVE_REQUEST
NUM_FORWARD_REQUEST=$NUM_FORWARD_REQUEST
#REPLY
NUM_SEND_REPLY=$NUM_SEND_REPLY
NUM_RECEIVE_REPLY=$NUM_RECEIVE_REPLY
NUM_FORWARD_REPLY=$NUM_FORWARD_REPLY
#ERROR
NUM_SEND_ERROR=$NUM_SEND_ERROR
NUM_RECEIVE_ERROR=$NUM_RECEIVE_ERROR
NUM_FORWARD_ERROR=$NUM_FORWARD_ERROR
#HELLO
NUM_SEND_HELLO=$NUM_SEND_HELLO
NUM_RECEIVE_HELLO=$NUM_RECEIVE_HELLO
NUM_FORWARD_HELLO=$NUM_FORWARD_HELLO
" > $OUT_FILE.log

cat $OUT_FILE.log

