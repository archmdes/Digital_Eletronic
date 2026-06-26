module ram_cartas #(
    parameter DATA_WIDTH = 7,
	 parameter ADDR_WIDTH = 7,
    parameter NUM_CARTAS = 108
) (
    input wire clk,
    input wire we, // Write Enable
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Memória RAM
    reg [DATA_WIDTH-1:0] ram [0:NUM_CARTAS-1];

    always @(posedge clk) begin
        if (we) begin
            if(addr < NUM_CARTAS) begin
                ram[addr] <= data_in; // Escrita
                end
        end
        data_out <= ram[addr];    // Leitura
    end

endmodule