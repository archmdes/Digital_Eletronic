// =============================================================================
// MODULO: ram_cartas
// -----------------------------------------------------------------------------
// Memoria RAM que armazena o baralho APOS o embaralhamento. Possui uma unica
// porta de Leitura/Escrita (sincrona), endereco compartilhado entre os dois
// modos atraves do sinal "we" (write enable).
//
// E usada pelo modulo "embaralhador" para gravar as cartas na ordem sorteada
// e, depois, pela FSM principal do jogo para ler as cartas sequencialmente
// (distribuicao inicial e compras/HIT/DRAW), a partir do endereco 0.
// =============================================================================
module ram_cartas #(
    parameter DATA_WIDTH = 7,
    parameter ADDR_WIDTH = 7,
    parameter NUM_CARTAS = 108
) (
    input  wire                       clk,
    input  wire                       we,       // habilita escrita
    input  wire [ADDR_WIDTH-1:0]      addr,
    input  wire [DATA_WIDTH-1:0]      data_in,
    output reg  [DATA_WIDTH-1:0]      data_out
);

    // Memoria RAM (inferida como bloco de memoria pelo Quartus)
    reg [DATA_WIDTH-1:0] ram [0:NUM_CARTAS-1];

    always @(posedge clk) begin
        if (we) begin
            if (addr < NUM_CARTAS) begin
                ram[addr] <= data_in; // Escrita
            end
        end
        data_out <= ram[addr];        // Leitura (sincrona, 1 ciclo de latencia)
    end

endmodule
