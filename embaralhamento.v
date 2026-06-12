module embaralhador #(
    parameter DATA_WIDTH = 9,  // Tamanho do dado (9 bits por carta)
    parameter ADDR_WIDTH = 7   // Tamanho do endereço (7 fios de endereço)
) (
    input  wire clk,
    input  wire rst,
    // [8:0] (9 bits) nome_da_variavel [0:108]
    input  wire [DATA_WIDTH-1:0] memory_in  [0:(1<<ADDR_WIDTH)-20],
    output reg  [DATA_WIDTH-1:0] memory_out [0:(1<<ADDR_WIDTH)-20]
);

    integer i;

    localparam NUM_CARTAS = 1 << ADDR_WIDTH; 

    always @(posedge clk) begin
        if (rst) begin
            // Lógica de "Embaralhar" (Inverter a ordem)
            for (i = 0; i < NUM_CARTAS; i = i + 1) begin
                memory_out[i] <= memory_in[NUM_CARTAS - 1 - i];
            end
        end else begin
            // Comportamento normal: Apenas copia a memória de forma idêntica
            for (i = 0; i < NUM_CARTAS; i = i + 1) begin
                memory_out[i] <= memory_in[i];
            end
        end
    end
endmodule