// =============================================================================
// MODULO: special_cards_control
// -----------------------------------------------------------------------------
// Decodifica o efeito de uma carta especial recem-jogada e gera os sinais de
// controle correspondentes para a FSM principal do jogo.
//
// PADRAO DE CODIFICACAO DA CARTA (8 bits, usado em todo o projeto):
//   bit 7   -> nao usado (sempre 0)
//   bit 6   -> ESPECIAL (1 = carta especial, 0 = carta numerica normal)
//   bits5:4 -> COR  (00=Vermelho, 01=Amarelo, 10=Verde, 11=Azul)
//   bits3:0 -> VALOR:
//        ESPECIAL=0 -> numero da carta (0 a 9)
//        ESPECIAL=1 -> 0=Skip, 1=Reverse, 2=Draw Two(+2),
//                       3=Wild, 4=Wild Draw Four(+4)
//
// Regras implementadas (jogo de apenas 2 participantes: PLAYER e CPU):
//   - Skip / Reverse  -> o oponente perde a vez (Reverse com 2 jogadores
//                         equivale a Skip, conforme permitido no enunciado).
//   - Draw Two  (+2)   -> oponente compra 2 cartas E perde a vez.
//   - Draw Four (+4)   -> oponente compra 4 cartas E perde a vez.
//   - Wild             -> nao tem efeito de turno/compra (apenas pode ser
//                         jogada sobre qualquer carta); a cor e mantida
//                         (simplificacao adotada no projeto, ja que o
//                         console nao possui interface para escolha de cor).
// =============================================================================
module special_cards_control (
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] played_card,   // carta que acabou de ser jogada
    input  wire       apply_effect,  // pulso: "aplique o efeito desta carta agora"

    output reg        skip_next,     // pulso: o oponente perde a vez
    output reg        SKIP_ACTION,   // saida de topo (ativa por >=2s, controlada externamente)
    output reg        DRAW_ACTION,   // saida de topo (ativa por >=2s, controlada externamente)
    output reg [2:0]  draw_count     // quantidade de cartas que o oponente deve comprar
);

    // Campos da carta jogada
    wire        especial = played_card[6];
    wire [3:0]  valor    = played_card[3:0];

    localparam VAL_SKIP   = 4'd0,
               VAL_REV    = 4'd1,
               VAL_DRAW2  = 4'd2,
               VAL_WILD   = 4'd3,
               VAL_DRAW4  = 4'd4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            SKIP_ACTION <= 1'b0;
            DRAW_ACTION <= 1'b0;
            draw_count  <= 3'd0;
            skip_next   <= 1'b0;
        end
        else begin
            skip_next <= 1'b0; // pulso de 1 ciclo por padrao

            if (apply_effect) begin
                SKIP_ACTION <= 1'b0;
                DRAW_ACTION <= 1'b0;
                draw_count  <= 3'd0;

                if (especial) begin
                    case (valor)
                        VAL_SKIP, VAL_REV: begin
                            SKIP_ACTION <= 1'b1;
                            skip_next   <= 1'b1;
                        end
                        VAL_DRAW2: begin
                            DRAW_ACTION <= 1'b1;
                            draw_count  <= 3'd2;
                            skip_next   <= 1'b1; // oponente compra e tambem perde a vez
                        end
                        VAL_DRAW4: begin
                            DRAW_ACTION <= 1'b1;
                            draw_count  <= 3'd4;
                            skip_next   <= 1'b1;
                        end
                        VAL_WILD: begin
                            // Sem efeito de turno/compra; apenas "encaixa" em qualquer carta.
                        end
                        default: begin
                            // valor especial desconhecido -> nenhum efeito
                        end
                    endcase
                end
            end
        end
    end

endmodule
