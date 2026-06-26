module rom_cartas #(
    parameter DATA_WIDTH = 6, // Conforme deter
    parameter ADDR_WIDTH = 7  // 128 posições
) (
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Declaração da matriz
    reg [6:0] rom [0:127];

    // INICIALIZAÇÃO DA MEMÓRIA
    // O bloco 'initial' é lido pelo Quartus antes de sintetizar o circuito.
    initial begin
        // Lê os dados de um arquivo de texto e preenche a matriz 'rom'
        // Crie um arquivo "cartas_iniciais.txt" na pasta do seu projeto.
        $readmemb("uno_deck.txt", rom);
    end

    // Leitura Síncrona (Apenas Leitura, não tem 'if(we)')
    always @(posedge clk) begin
        data_out <= rom[addr];
    end

endmodule