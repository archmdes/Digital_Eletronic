module embaralhador #(
    parameter DATA_WIDTH = 8,
    parameter NUM_CARTAS = 108  // Definido explicitamente como 108 cartas
) (
    input  wire clk,
    input  wire rst,
    input  wire start_shuffle,
    output reg  done,
    input  wire [DATA_WIDTH-1:0] memory_in  [0:NUM_CARTAS-1], // Índices 0 a 107
    output reg  [DATA_WIDTH-1:0] memory_out [0:NUM_CARTAS-1]
);

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;
        end else if (start_shuffle) begin
            // Inverte exatamente as 108 cartas
            for (i = 0; i < NUM_CARTAS; i = i + 1) begin
                memory_out[i] <= memory_in[NUM_CARTAS - 1 - i];
            end
            done <= 1'b1; 
        end else begin
            done <= 1'b0;
        end
    end
endmodule
