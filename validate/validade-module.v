module validate_move(
    clk, rst,
    PLAYER_CARD, CPU_CARD, TOP_CARD,
    PLAYER_TURN, CPU_TURN,
    INVALID_MOVE, SPECIAL_CARD,
    NEW_TOP_CARD
);

    // Entradas
    input clk;
    input rst;

    input PLAYER_TURN;
    input CPU_TURN;

    input [8:0] PLAYER_CARD;
    input [8:0] CPU_CARD;
    input [8:0] TOP_CARD;

    // Saídas
    output reg INVALID_MOVE;
    output reg SPECIAL_CARD;
    output reg [8:0] NEW_TOP_CARD; // TOP_CARD não pode ser saída e entrada ao mesmo tempo

    // Mapeamento dos bits:
    // [1:0]  = cor      (00=vermelho, 01=azul, 10=amarelo, 11=verde)
    // [5:2]  = naipe    (0–9)
    // [8:6]  = especial (000=normal, 001=+4, 010=+2, 011=bloqueado, 100=reverso, 101=trocar cor)

    // Fios internos para as cartas jogadas
    wire [1:0] player_color   = PLAYER_CARD[1:0];
    wire [3:0] player_number  = PLAYER_CARD[5:2];
    wire [2:0] player_special = PLAYER_CARD[8:6];

    wire [1:0] top_color      = TOP_CARD[1:0];
    wire [3:0] top_number     = TOP_CARD[5:2];
    wire [2:0] top_special    = TOP_CARD[8:6];

    wire [1:0] cpu_color      = CPU_CARD[1:0];
    wire [3:0] cpu_number     = CPU_CARD[5:2];
    wire [2:0] cpu_special    = CPU_CARD[8:6];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            INVALID_MOVE  <= 1'b0;
            SPECIAL_CARD  <= 1'b0;
            NEW_TOP_CARD  <= TOP_CARD;
        end
        else begin
            // Reset dos sinais a cada ciclo
            INVALID_MOVE <= 1'b0;
            SPECIAL_CARD <= 1'b0;
            NEW_TOP_CARD <= TOP_CARD;

            if (PLAYER_TURN) begin
                // Carta especial
                if (player_special != 3'b000) begin
                    SPECIAL_CARD <= 1'b1;
                    NEW_TOP_CARD <= PLAYER_CARD;
                    // Aqui você pode chamar/sinalizar o módulo de jogadas especiais
                end
                // Carta normal: mesma cor OU mesmo naipe
                else if ((player_color == top_color) || (player_number == top_number)) begin
                    NEW_TOP_CARD <= PLAYER_CARD;
                end
                else begin
                    INVALID_MOVE <= 1'b1;
                    // TOP_CARD permanece a mesma (NEW_TOP_CARD já foi atribuída acima)
                end
            end

            else if (CPU_TURN) begin
                // Carta especial da CPU
                if (cpu_special != 3'b000) begin
                    SPECIAL_CARD <= 1'b1;
                    NEW_TOP_CARD <= CPU_CARD;
                end
                // Carta normal da CPU
                else if ((cpu_color == top_color) || (cpu_number == top_number)) begin
                    NEW_TOP_CARD <= CPU_CARD;
                end
                else begin
                    INVALID_MOVE <= 1'b1;
                end
            end
        end
    end

endmodule

// Exemplo de carta: 010 0010 01
//   cor     = 01  → azul
//   naipe   = 0010 → número 2
//   especial= 010  → +2