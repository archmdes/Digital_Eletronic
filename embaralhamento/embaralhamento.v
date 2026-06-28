module embaralhador #(
    parameter DATA_WIDTH = 7,
    parameter NUM_CARTAS = 108
) (
    input  wire clk,
    input  wire rst,
    input  wire start_shuffle,
    output reg  done,
    input  wire [DATA_WIDTH-1:0] memory_in  [0:NUM_CARTAS-1],
    output reg  [DATA_WIDTH-1:0] memory_out [0:NUM_CARTAS-1]
);

    // Codificação dos Estados da FSM
    localparam S_IDLE    = 2'b00;
    localparam S_SHUFFLE = 2'b01;
    localparam S_DONE    = 2'b10;

    reg [1:0] estado_atual;
    reg [6:0] contador; // 7 bits cobrem o valor 108 (até 127)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            estado_atual <= S_IDLE;
            contador     <= 0;
            done         <= 1'b0;
        end else begin
            case (estado_atual)
                // ESTADO 1: Aguarda o comando da Super FSM
                S_IDLE: begin
                    done     <= 1'b0;
                    contador <= 0;
                    if (start_shuffle) begin
                        estado_atual <= S_SHUFFLE;
                    end
                end

                // ESTADO 2: Realiza a inversão carta por carta
                S_SHUFFLE: begin
                    memory_out[contador] <= memory_in[NUM_CARTAS - 1 - contador];
                    
                    if (contador == NUM_CARTAS - 1) begin
                        estado_atual <= S_DONE; // Terminou todas as cartas
                    end else begin
                        contador <= contador + 1; // Avança para a próxima carta
                    end
                end

                // ESTADO 3: Sinaliza a conclusão para a FSM
                S_DONE: begin
                    done <= 1'b1;
                    if (!start_shuffle) begin
                        estado_atual <= S_IDLE; // Retorna quando o comando for desligado
                    end
                end

                default: estado_atual <= S_IDLE;
            endcase
        end
    end
endmodule
