// =============================================================================
// MODULO: validate_move
// -----------------------------------------------------------------------------
// Maquina de Mealy responsavel por validar se uma jogada (carta escolhida
// pelo PLAYER, ou carta selecionada pela CPU) pode ser colocada sobre a
// carta do topo da pilha de descarte (TOP_CARD).
//
// PADRAO DE CODIFICACAO DA CARTA (8 bits, igual em todo o projeto):
//   bit 7   -> nao usado (0)
//   bit 6   -> ESPECIAL (1=especial, 0=numerica)
//   bits5:4 -> COR  (00=Vermelho, 01=Amarelo, 10=Verde, 11=Azul)
//   bits3:0 -> VALOR (numero 0-9, ou 0=Skip,1=Reverse,2=+2,3=Wild,4=+4)
//
// Regra de compatibilidade (igual a regra real do UNO):
//   - Curinga (Wild ou Wild Draw Four) -> sempre valida, joga em qualquer carta.
//   - mesma COR da carta do topo       -> valida.
//   - mesmo VALOR/numero (cartas numericas) -> valida.
//   - mesmo tipo de carta especial (ex: Skip sobre Skip) -> valida.
//   - qualquer outro caso -> INVALIDA.
// =============================================================================
module validate_move (
    input  wire       clk,
    input  wire       rst,

    input  wire        PLAYER_TURN,
    input  wire        CPU_TURN,
    input  wire [7:0]  PLAYER_CARD,
    input  wire [7:0]  CPU_CARD,
    input  wire [7:0]  TOP_CARD,

    output reg          INVALID_MOVE,
    output reg          SPECIAL_CARD,
    output reg  [7:0]   NEW_TOP_CARD
);

    localparam VAL_WILD  = 4'd3,
               VAL_WILD4 = 4'd4;

    // Carta a ser analisada nesta rodada (do PLAYER ou da CPU)
    wire [7:0] carta_analisada = PLAYER_TURN ? PLAYER_CARD : CPU_CARD;

    wire        c_especial = carta_analisada[6];
    wire [1:0]  c_cor      = carta_analisada[5:4];
    wire [3:0]  c_valor    = carta_analisada[3:0];

    wire        t_especial = TOP_CARD[6];
    wire [1:0]  t_cor      = TOP_CARD[5:4];
    wire [3:0]  t_valor    = TOP_CARD[3:0];

    wire eh_curinga = c_especial && (c_valor == VAL_WILD || c_valor == VAL_WILD4);

    wire jogada_valida =
            eh_curinga ||
            (c_cor == t_cor) ||
            (!c_especial && !t_especial && (c_valor == t_valor)) ||
            ( c_especial &&  t_especial && (c_valor == t_valor) &&
              c_valor != VAL_WILD && c_valor != VAL_WILD4);

    // -------------------------------------------------------------------
    // Estados da maquina de Mealy
    // -------------------------------------------------------------------
    localparam [1:0]
        IDLE           = 2'b00,
        SEGUE_JOGADA   = 2'b01,
        CARTA_ESPECIAL = 2'b10,
        INVALID_STATE  = 2'b11;

    // Maquina de Mealy: as saidas dependem apenas de proximo_estado (calculado
    // combinacionalmente). O registrador de estado atual nao e necessario para
    // as saidas e foi removido para eliminar o warning "assigned but never read".
    reg [1:0] proximo_estado;

    always @(*) begin
        proximo_estado = IDLE;

        if (PLAYER_TURN || CPU_TURN) begin
            if (!jogada_valida)
                proximo_estado = INVALID_STATE;
            else if (c_especial)
                proximo_estado = CARTA_ESPECIAL;
            else
                proximo_estado = SEGUE_JOGADA;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            INVALID_MOVE <= 1'b0;
            SPECIAL_CARD <= 1'b0;
            NEW_TOP_CARD <= 8'd0;
        end
        else begin
            case (proximo_estado)
                SEGUE_JOGADA: begin
                    INVALID_MOVE <= 1'b0;
                    SPECIAL_CARD <= 1'b0;
                    NEW_TOP_CARD <= carta_analisada;
                end
                CARTA_ESPECIAL: begin
                    INVALID_MOVE <= 1'b0;
                    SPECIAL_CARD <= 1'b1;
                    NEW_TOP_CARD <= carta_analisada;
                end
                INVALID_STATE: begin
                    INVALID_MOVE <= 1'b1;
                    SPECIAL_CARD <= 1'b0;
                    NEW_TOP_CARD <= TOP_CARD;
                end
                default: begin // IDLE
                    INVALID_MOVE <= 1'b0;
                    SPECIAL_CARD <= 1'b0;
                    NEW_TOP_CARD <= TOP_CARD;
                end
            endcase
        end
    end

endmodule
