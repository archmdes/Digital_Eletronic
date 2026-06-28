module embaralhador #(
    parameter DATA_WIDTH = 7,
    parameter ADDR_WIDTH = 7,
    parameter NUM_CARTAS = 108
) (
    input  wire clk,
    input  wire rst,
    input  wire start,       
    output reg  done,        

    // Interface de Leitura (Para a ROM)
    output reg  [ADDR_WIDTH-1:0] addr_in,
    input  wire [DATA_WIDTH-1:0] data_in,

    // Interface de Escrita (Para a RAM)
    output reg  we_out,
    output reg  [ADDR_WIDTH-1:0] addr_out,
    output reg  [DATA_WIDTH-1:0] data_out
);

    localparam S_IDLE  = 2'd0;
    localparam S_READ  = 2'd1;
    localparam S_WRITE = 2'd2;
    localparam S_DONE  = 2'd3;

    reg [1:0] estado;
    reg [6:0] contador;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            estado   <= S_IDLE;
            contador <= 0;
            done     <= 0;
            we_out   <= 0;
            addr_in  <= 0;
        end else begin
            case (estado)
                
                S_IDLE: begin
                    done     <= 0;
                    we_out   <= 0;
                    contador <= 0;
                    if (start) begin
                        estado  <= S_READ;
                        addr_in <= 0; 
                    end
                end

                S_READ: begin
                    we_out <= 0;
                    estado <= S_WRITE; 
                end

                S_WRITE: begin
                    we_out   <= 1;
                    data_out <= data_in; 
                    
                    addr_out <= (NUM_CARTAS - 1) - contador;

                    if (contador == NUM_CARTAS - 1) begin
                        estado <= S_DONE;
                    end else begin
                        contador <= contador + 1;
                        addr_in  <= contador + 1; 
                        estado   <= S_READ;
                    end
                end

                S_DONE: begin
                    we_out <= 0;
                    done   <= 1;
                    if (!start) begin
                        estado <= S_IDLE; 
                    end
                end
                
                default: estado <= S_IDLE;
            endcase
        end
    end
endmodule
