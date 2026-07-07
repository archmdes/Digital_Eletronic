// =============================================================================
// MODULO: UNO  (TOPO DO PROJETO - mapeamento para a placa DE2-115)
// -----------------------------------------------------------------------------
// Une o modulo "uno" (FSM principal do jogo) ao modulo "interface" (botoes,
// displays de 7 segmentos e LEDs), e conecta tudo aos pinos fisicos da placa
// Terasic DE2-115 (FPGA Cyclone IV E, EP4CE115F29C7).
//
// Mapeamento de botoes (KEY sao ativos em NIVEL BAIXO na DE2-115):
//   KEY[0] -> RESET  (reinicia o jogo / dispara novo embaralhamento)
//   KEY[1] -> SELECT (seleciona a proxima carta da mao do PLAYER)
//   KEY[2] -> PLAY   (joga a carta selecionada)
//   KEY[3] -> DRAW   (compra uma carta do baralho)
//
// Observacao: o modulo "interface" ja inclui o circuito de debounce
// (button_conditioner), que internamente inverte o nivel do botao
// (1 = pressionado). Por isso os KEY sao conectados diretamente, SEM
// inversao, ao modulo "interface". Apenas o RESET (consumido diretamente
// pela FSM "uno", sem passar pelo debounce) precisa ser invertido aqui,
// pois a FSM espera um reset ativo em NIVEL ALTO.
// =============================================================================
module top_uno (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,

    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX7,

    output wire [8:0]  LEDG,
    output wire [17:0] LEDR
);

    wire clk   = CLOCK_50;
    wire reset = ~KEY[0];   // RESET ativo em nivel ALTO para a FSM "uno"

    // -------------------------------------------------------------------
    // Sinais intermediarios entre "interface" e "uno"
    // -------------------------------------------------------------------
    wire select_pulse, play_pulse, draw_pulse;

    wire player_turn, cpu_turn, invalid_move, draw_action, skip_action, win, lose;
    wire [3:0] n_player, n_cpu;
    wire [7:0] player_card, top_card;

    wire [7:0] hex0_w, hex1_w, hex2_w, hex3_w, hex4_w, hex5_w, hex6_w, hex7_w;

    // -------------------------------------------------------------------
    // FSM principal do jogo
    // -------------------------------------------------------------------
    uno U_UNO (
        .CLK          (clk),
        .RESET        (reset),
        .SELECT       (select_pulse),
        .PLAY         (play_pulse),
        .DRAW         (draw_pulse),
        .PLAYER_TURN  (player_turn),
        .CPU_TURN     (cpu_turn),
        .INVALID_MOVE (invalid_move),
        .DRAW_ACTION  (draw_action),
        .SKIP_ACTION  (skip_action),
        .WIN          (win),
        .LOSE         (lose),
        .N_PLAYER     (n_player),
        .N_CPU        (n_cpu),
        .PLAYER_CARD  (player_card),
        .TOP_CARD     (top_card)
    );

    // -------------------------------------------------------------------
    // Interface de botoes, displays de 7 segmentos e LEDs
    // -------------------------------------------------------------------
    interface U_INTERFACE (
        .CLK          (clk),
        .RESET        (reset),
        .SELECT       (KEY[1]),
        .PLAY         (KEY[2]),
        .DRAW         (KEY[3]),

        .N_PLAYER     (n_player),
        .N_CPU        (n_cpu),
        .PLAYER_CARD  (player_card),
        .TOP_CARD     (top_card),

        .PLAYER_TURN  (player_turn),
        .CPU_TURN     (cpu_turn),
        .INVALID_MOVE (invalid_move),
        .DRAW_ACTION  (draw_action),
        .SKIP_ACTION  (skip_action),
        .WIN          (win),
        .LOSE         (lose),

        .select_pulse (select_pulse),
        .play_pulse   (play_pulse),
        .draw_pulse   (draw_pulse),

        .HEX0 (hex0_w), .HEX1 (hex1_w), .HEX2 (hex2_w), .HEX3 (hex3_w),
        .HEX4 (hex4_w), .HEX5 (hex5_w), .HEX6 (hex6_w), .HEX7 (hex7_w),

        .LEDG (LEDG),
        .LEDR (LEDR)
    );

    // A placa DE2-115 so possui 7 segmentos fisicos por display (sem ponto
    // decimal conectado); o bit 7 gerado pelos decodificadores e descartado.
    assign HEX0 = hex0_w[6:0];
    assign HEX1 = hex1_w[6:0];
    assign HEX2 = hex2_w[6:0];
    assign HEX3 = hex3_w[6:0];
    assign HEX4 = hex4_w[6:0];
    assign HEX5 = hex5_w[6:0];
    assign HEX6 = hex6_w[6:0];
    assign HEX7 = hex7_w[6:0];

endmodule
