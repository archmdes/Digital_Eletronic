module embaralhador_datapath #(
    parameter DATA_WIDTH = 7,  // Ajustado para 7 bits (cartas do UNO)
    parameter ADDR_WIDTH = 7,  // 7 fios de endereço
    parameter NUM_CARTAS = 108 // Limite cravado nas cartas reais
) (
    input  wire clk,
    input  wire rst,

    // ==========================================
    // Sinais de Controle (Recebidos da FSM)
    // ==========================================
    input  wire enable, // FSM diz: "Avance para a próxima carta"
    input  wire clear,  // FSM diz: "Zere a contagem"
    input  wire mode,   // FSM diz: 0 = Copiar normal, 1 = Inverter ordem

    // ==========================================
    // Sinal de Status (Enviado para a FSM)
    // ==========================================
    output wire tc,     // Terminal Count: Avisa a FSM que chegou na carta 107

    // ==========================================
    // Barramentos para as Memórias
    // ==========================================
    input  wire [DATA_WIDTH-1:0] rom_data, // Dado lido da ROM
    output wire [ADDR_WIDTH-1:0] rom_addr, // Endereço solicitado à ROM
    
    output wire [ADDR_WIDTH-1:0] ram_addr, // Endereço onde gravar na RAM
    output wire [DATA_WIDTH-1:0] ram_data  // Dado a ser gravado na RAM
);

    // Registrador interno para contar qual carta estamos manipulando
    reg [ADDR_WIDTH-1:0] contador;

    // ==========================================
    // Bloco Sequencial: O Contador Escravo
    // ==========================================
    always @(posedge clk) begin
        if (rst || clear) begin
            contador <= 0; // O Reset agora apenas limpa o estado
        end else if (enable) begin
            if (contador < NUM_CARTAS - 1) begin
                contador <= contador + 1'b1;
            end
        end
    end

    // Avisa a FSM quando terminar (tc vai para Nível Alto 1)
    assign tc = (contador == NUM_CARTAS - 1);

    // ==========================================
    // Bloco Combinacional: Roteamento
    // ==========================================
    
    // O endereço de leitura da ROM sempre segue o contador normal
    assign rom_addr = contador;
    
    // O dado que entra na RAM é o mesmo que saiu da ROM
    assign ram_data = rom_data;
    
    // O Endereço da RAM muda dependendo da ordem (mode) dada pela FSM:
    // Se mode == 1: Faz a lógica de inversão original
    // Se mode == 0: Faz a cópia idêntica original
    assign ram_addr = (mode) ? ((NUM_CARTAS - 1) - contador) : contador;

endmodule
