module uno_top_level (
    input  wire clk,
    input  wire rst,
    
    // Sinal para dar início ao embaralhamento
    input  wire start_shuffle, 
    
    // Sinal de status informando que o deck está pronto
    output wire shuffle_done,
    
    // Portas para o restante do jogo ler as cartas da RAM (após embaralhar)
    input  wire [6:0] game_ram_addr,
    output wire [6:0] game_ram_data_out
);

    // ==========================================
    // 1. Declaração dos Fios (Wires) Internos
    // ==========================================
    
    // Fios entre Embaralhador e ROM
    wire [6:0] w_rom_addr;
    wire [6:0] w_rom_data;
    
    // Fios entre Embaralhador e RAM
    wire [6:0] w_ram_addr;
    wire [6:0] w_ram_data_in;
    wire       w_ram_we;

    // ==========================================
    // 2. Multiplexador de Acesso à RAM
    // ==========================================
    // Se o embaralhamento terminou, o jogo escolhe qual endereço da RAM ler.
    // Caso contrário, o embaralhador escolhe o endereço para gravar.
    wire [6:0] actual_ram_addr = (shuffle_done) ? game_ram_addr : w_ram_addr;

    // ==========================================
    // 3. Instanciação dos Módulos
    // ==========================================

    // Instância da ROM (que lê o arquivo uno_deck.txt)
    rom_cartas #(
        .DATA_WIDTH(7), // Padronizado para 7 bits[cite: 3]
        .ADDR_WIDTH(7)  // Endereçamento de 7 fios[cite: 3]
    ) u_rom (
        .clk(clk),
        .addr(w_rom_addr),
        .data_out(w_rom_data)
    );

    // Instância da Máquina de Estados do Embaralhador
    embaralhador_fsm #(
        .DATA_WIDTH(7),
        .ADDR_WIDTH(7),
        .NUM_CARTAS(108)
    ) u_embaralhador (
        .clk(clk),
        .rst(rst),
        .start(start_shuffle),
        
        // Conectando os fios da ROM
        .rom_addr(w_rom_addr),
        .rom_data(w_rom_data),
        
        // Conectando os fios da RAM
        .ram_addr(w_ram_addr),
        .ram_data(w_ram_data_in),
        .ram_we(w_ram_we),
        
        // Conectando o sinal de fim para a saída
        .done(shuffle_done)
    );

    // Instância da RAM (onde o baralho ficará guardado para o jogo)
    ram_cartas #(
        .DATA_WIDTH(7),
        .NUM_CARTAS(108)
    ) u_ram (
        .clk(clk),
        .we(w_ram_we),               // Controlado exclusivamente pelo embaralhador
        .addr(actual_ram_addr),      // Endereço multiplexado definido acima
        .data_in(w_ram_data_in),     // Dado vindo do embaralhador
        .data_out(game_ram_data_out) // Saída para o seu jogo ler as cartas
    );

endmodule