Estudo, simulações e comparações de protocolos de redes ad hoc móveis em cenários militares.
============================================================================================

Acadêmico:
----------
* Fábio Leandro Janiszevski - <fabiosammy at gmail dot com>

Orientadores:
-------------
* Daniel Kikuti   - <e-mail>
* Hermano Pereira - <e-mail>

Estrutura do repositório
========================
* ./docs/*       - documento do TCC (Não disponível)
* ./OSDV/*       - Simulações com o protocolo OSDV
* ./AODV/*       - Simulações com o protocolo AODV
* ./OLSR/*       - Simulações com o protocolo OLSR
* ./simple/*     - Simulações de exemplo
* ./links.txt    - Links de vários materiais 
* ./Variaveis.sh - Script shell que lê os arquivos de log e registra algumas variáveis de análise

Arquivo de logs (<nome>.tr)
======================
* D - DROP (Retirada indevida do pacote da fila de espera)
* s - Operações de envio
* r - Operações de recepção
* f - Reencaminhamento (forward)
* c - Colisão na camada MAC
* M - Posiocionamento do nó
Sintaxe:
--------
* <Tipo> <Tempo> <Nó> <Camada> --- <Identificador> <Pacote> <Tamanho> [<Duração> <Destino> <Origem> <Cabeçalho>] ------- [<Origem> <Destino> <TTL> <HOP>]
* <Tipo>          - Tipo da operação, foram descritas acima.
* <Tempo>         - Tempo em que a operação esta sendo realizada.
* <Nó>            - Nó que efetuou a operação
* <Camada>        - Camada da operação
* ---             - Razão pela qual o trace do pacote foi realizado
* <Identificador> - Identificador do pacote
* <Pacote>        - Tipo do pacote (message, tcp, etc...)
* <Tamanho>       - Tamanho do pacote trafegado
* []              - Cabeçalho MAC
** <Duração>      - Duração do pacote contido no cabeçalho MAC
** <Destino>      - Endereço MAC de destino (ffffffff - endereço de broadcast)
** <Origem>       - Endereço MAC de origem do pacote
** <Cabeçalho>    - Tipo de cabeçalho MAC do pacote (800 - ARP)
* -------         - Estado das 7 flags do pacote
* []              - Cabeçalho IP
** <Origem>       - Endereço IP do nó que originou o pacote seguido da ???? da origem (Separado por ":")
** <Destino>      - Endereço IP do nó de destino para o pacote seguido da ??? de destino (Separado por ":")
** <TTL>          - Representa o TTL (time-to-live)
** <HOP>          - Próximo HOP (0 situação de broadcast)

