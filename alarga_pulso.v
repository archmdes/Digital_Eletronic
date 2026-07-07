// =============================================================================
// MODULO: alarga_pulso
// -----------------------------------------------------------------------------
// Modulo generico reutilizavel para "alargar" um pulso de 1 ciclo de clock em
// um nivel alto que dura, no minimo, CICLOS ciclos de clock (2 segundos, a
// 50MHz, com o valor padrao 100_000_000).
//
// Usado para gerar as saidas PLAYER_HIT, DEALER_HIT, PLAYER_TURN, CPU_TURN,
// INVALID_MOVE, DRAW_ACTION, SKIP_ACTION etc, todas exigidas pela
// especificacao como "ativas por pelo menos 2 segundos".
//
// Caso o pulso de entrada ocorra novamente enquanto a saida ainda esta alta,
// o contador e reiniciado (retrigger).
// =============================================================================
module alarga_pulso #(
    parameter CICLOS = 100_000_000   // 2s @ 50MHz
) (
    input  wire clk,
    input  wire rst,
    input  wire pulso_in,
    output reg  saida
);

    reg [26:0] contador;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            saida    <= 1'b0;
            contador <= 0;
        end
        else if (pulso_in) begin
            saida    <= 1'b1;
            contador <= 0;
        end
        else if (saida) begin
            if (contador < CICLOS - 1) begin
                contador <= contador + 1'b1;
            end
            else begin
                saida    <= 1'b0;
                contador <= 0;
            end
        end
    end

endmodule
