module embaralhador_fsm #(
    parameter DATA_WIDTH = 7,
    parameter ADDR_WIDTH = 7,
    parameter NUM_CARTAS = 108
) (
    input  wire clk,
    input  wire rst,
    input  wire start,       // Sinal externo para iniciar a cópia/embaralhamento
    
    // Interface com a ROM (Leitura)
    output reg  [ADDR_WIDTH-1:0] rom_addr,
    input  wire [DATA_WIDTH-1:0] rom_data,
    
    // Interface com a RAM (Escrita)
    output reg  [ADDR_WIDTH-1:0] ram_addr,
    output reg  [DATA_WIDTH-1:0] ram_data,
    output reg  ram_we,
    
    // Status
    output reg  done         // Fica em ALTO (1) quando terminar todas as 108 cartas
);

    // Definição dos Estados da Máquina (FSM)
    localparam IDLE       = 3'b000;
    localparam REQ_ROM    = 3'b001; // Pede o endereço para a ROM
    localparam WAIT_ROM   = 3'b010; // Espera 1 ciclo para a ROM liberar o dado
    localparam WRITE_RAM  = 3'b011; // Grava na RAM
    localparam DONE_STATE = 3'b100; // Finalizado

    reg [2:0] state;
    reg [ADDR_WIDTH-1:0] contador;

    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            contador <= 0;
            rom_addr <= 0;
            ram_addr <= 0;
            ram_data <= 0;
            ram_we   <= 1'b0;
            done     <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    contador <= 0;
                    ram_we <= 1'b0;
                    if (start) begin
                        state <= REQ_ROM;
                    end
                end

                REQ_ROM: begin
                    // Solicita a carta na posição 'contador' da ROM
                    rom_addr <= contador;
                    ram_we   <= 1'b0;
                    state    <= WAIT_ROM;
                end

                WAIT_ROM: begin
                    // A ROM é síncrona, então precisamos esperar 1 ciclo de clock 
                    // para que o dado (rom_data) esteja disponível e estável.
                    state <= WRITE_RAM;
                end

                WRITE_RAM: begin
                    // Pega o dado da ROM e prepara para escrever na RAM.
                    ram_data <= rom_data;
                    
                    // Lógica de "Embaralhar" original (Inverter a ordem): 
                    // A carta 0 vai para a 107, a 1 para a 106, etc.
                    ram_addr <= (NUM_CARTAS - 1) - contador;
                    
                    ram_we   <= 1'b1; // Habilita a escrita na RAM
                    
                    // Verifica se já lemos todas as cartas
                    if (contador == NUM_CARTAS - 1) begin
                        state <= DONE_STATE;
                    end else begin
                        contador <= contador + 1'b1;
                        state    <= REQ_ROM; // Volta para buscar a próxima carta
                    end
                end

                DONE_STATE: begin
                    ram_we <= 1'b0; // Desliga a escrita por segurança
                    done   <= 1'b1; // Avisa o sistema que terminou
                    // Fica aqui até o sistema ser resetado
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule