# Digital_Eletronic

Objetivo Geral:
Criar e implementar um jogo eletrônico de UNO baseado em FPGA.

Descrição:
UNO é um jogo de cartas no qual os jogadores devem descartar cartas compatíveis com a carta presente na
mesa. A compatibilidade pode ocorrer por:

- mesma cor;
- mesmo número;
- mesmo tipo de ação.

O jogo será composto por um jogador humano (denominado PLAYER) e um jogador autônomo (denominado
CPU, controlado pelo FPGA). Inicialmente, cada participante receberá 7 cartas. Uma carta adicional será
colocada sobre a mesa, virada para cima, para iniciar a pilha de descarte.

Durante sua vez, PLAYER deverá:
- jogar uma carta válida, caso a identifique em sua mão; ou
- comprar uma nova carta do baralho, caso não identifique uma carta válida em sua mão – neste caso,
se a carta comprada for válida, o FPGA
- passar a vez.

O jogador CPU executará suas ações de forma autônoma, obedecendo às regras do jogo.
As cartas especiais implementadas deverão incluir:

Especificação:
Sua equipe deverá projetar um jogo eletrônico portátil de UNO e implementá-lo na placa DE2-115.
O console do jogo deverá possuir os seguintes botões:

- PLAY → jogar carta selecionada;
- DRAW → comprar carta;
- NEXT → selecionar próxima carta da mão;
- RESET → reiniciar o jogo.

As cartas serão armazenadas em uma memória embaralhada aleatoriamente após cada RESET.

Após o embaralhamento:
1. cada jogador receberá 7 cartas;
2. uma carta será posicionada na mesa;
3. o jogador PLAYER iniciará a partida.

O FPGA deverá:
- controlar a distribuição das cartas;
- validar jogadas;
- controlar turnos;
- aplicar efeitos das cartas especiais;
- identificar vitória;
- atualizar os displays e LEDs da placa.

Interfaces:
Entradas
- CLK → clock do sistema;
- RESET → reinicialização;
- SELECT → seleciona próxima carta da mão do jogador;
- PLAY → joga carta selecionada;
- DRAW → compra carta.
 
Interfaces de Memória
- CARD_IN;
- CARD_OUT;
- MEM_CTRL.

Saídas
- PLAYER_TURN → indica a vez de jogar do PLAYER – sinal ativo por pelo menos 2 segundos;
- CPU_TURN → indica a vez de jogar da CPU – sinal ativo por pelo menos 2 segundos;
- INVALID_MOVE → indica que PLAYER tentou realizar uma jogada inválida – sinal ativo por pelo
menos 2 segundos;
- DRAW_ACTION → indica que ocorreu uma ação de compra de carta pelo jogador atual, seja de forma
normal (botão DRAW acionado pelo PLAYER ou compra automática pela CPU) ou por ação de cartas
de penalidade (+2 ou +4) – sinal ativo por pelo menos 2 segundos;
- SKIP_ACTION → indica que o adversário perdeu a vez (jogador atual usou uma carta Skip ou Reverse)
– sinal ativo por pelo menos 2 segundos;
- WIN → indica vitória do PLAYER – sinal ativo até a ocorrência de RESET;
- LOSE → indica derrota do PLAYER – sinal ativo até a ocorrência de RESET;
- N_PLAYER → indica o número de cartas na mão do PLAYER;
- N_CPU → indica o número de cartas na mão da CPU;
- PLAYER_CARD → indica a carta atualmente selecionada na mão do PLAYER;
- TOP_CARD → indica a carta no topo da pilha de descarte sobre a mesa.

Exibição
Os displays de 7 segmentos poderão exibir (considerar o uso de sinais de entrada adicionais para seleção):
- quantidade de cartas do jogador (N_PLAYER);
- quantidade de cartas da CPU (N_CPU);
- carta selecionada (PLAYER_CARD);
- carta no topo da pilha de descarte sobre a mesa (TOP_CARD).
LEDs poderão indicar:
- turno atual;
- ações especiais;
- estado de vitória/derrota.

Considerações Importantes:
- Existe apenas um jogador humano (PLAYER) e um jogador autônomo (CPU).
- O baralho completo de UNO deverá estar presente na memória.
- O embaralhamento deverá ocorrer após RESET.
- As cartas deverão ser obtidas sequencialmente após o embaralhamento.
- Caso o jogador não possua cartas válidas, deverá comprar apenas uma carta via botão DRAW (no
caso de PLAYER) ou automaticamente (no caso da CPU). Caso a carta comprada seja válida, ela será
jogada automaticamente sobre a pilha na mesa. Caso contrário, passa-se a vez automaticamente
para o outro jogador
- O jogador CPU deverá jogar a primeira carta válida disponível dentro de sua mão.
- O jogo termina quando um dos participantes ficar sem cartas.
- Cartas especiais devem modificar o fluxo do jogo adequadamente. Como há apenas 2 jogadores,
Reverse poderá ser tratado como Skip.
- Caso o baralho se esgote, as cartas descartadas (exceto a do topo da pilha, a qual deverá permanecer
sobre a mesa) deverão ser reutilizadas após novo embaralhamento.
