module embaralhador #(
    parameter DATA_WIDTH = 9,
    parameter ADDR_WIDTH = 7
) (
    input  wire clk,
    input  wire rst,
    input  wire start_shuffle,           // Comando da FSM
    output reg  done,                    // Sinal para a FSM
    input  wire [DATA_WIDTH-1:0] memory_in [0:(1<<ADDR_WIDTH)-1],
    output reg  [DATA_WIDTH-1:0] memory_out [0:(1<<ADDR_WIDTH)-1]
);

    integer i;
    localparam NUM_CARTAS = 1 << ADDR_WIDTH;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;
        end else if (start_shuffle) begin
            // Lógica de embaralhamento (Inversão)
            for (i = 0; i < NUM_CARTAS; i = i + 1) begin
                memory_out[i] <= memory_in[NUM_CARTAS - 1 - i];
            end
            done <= 1'b1; // Sinaliza que o processamento terminou
        end else begin
            done <= 1'b0;
        end
    end
endmodule
