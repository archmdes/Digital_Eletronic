`timescale 1ns / 1ps

module tb_uno;

    // ==========================================
    // 1. Sinais de Estímulo (Entradas do Top Level)
    // ==========================================
    reg clk;
    reg rst;
    reg start_shuffle;
    reg [6:0] game_ram_addr;

    // ==========================================
    // 2. Fios de Observação (Saídas do Top Level)
    // ==========================================
    wire shuffle_done;
    wire [6:0] game_ram_data_out;

    // Váriavel para iteração (loop de leitura)
    integer i;

    // ==========================================
    // 3. Instanciação do Device Under Test (DUT)
    // ==========================================
    uno_top_level uut (
        .clk(clk),
        .rst(rst),
        .start_shuffle(start_shuffle),
        .shuffle_done(shuffle_done),
        .game_ram_addr(game_ram_addr),
        .game_ram_data_out(game_ram_data_out)
    );

    // ==========================================
    // 4. Geração do Clock
    // ==========================================
    // Inverte o valor do clock a cada 10 unidades de tempo (Período = 20ns -> 50 MHz)
    always #10 clk = ~clk;

    // ==========================================
    // 5. Rotina de Teste (Estímulos)
    // ==========================================
    initial begin
        // Condições iniciais
        clk = 0;
        rst = 1;
        start_shuffle = 0;
        game_ram_addr = 0;

        // Imprime mensagem inicial no console do ModelSim
        $display("--- Iniciando Simulação do Baralho UNO ---");

        // Aguarda um pouco e desativa o reset
        #50;
        rst = 0;
        #20;

        // Dá o comando (pulso) para a FSM começar a embaralhar
        $display("[%0t] Comando START enviado.", $time);
        start_shuffle = 1;
        #20; // Mantém o sinal em ALTO por 1 ciclo de clock
        start_shuffle = 0;

        // Aguarda a FSM terminar
        // @(posedge shuffle_done) faz a simulação pausar até o sinal ir para 1
        @(posedge shuffle_done);
        $display("[%0t] Embaralhamento concluido (Sinal DONE detectado).", $time);
        
        // Dá um tempinho de segurança
        #40;

        // ==========================================
        // 6. Verificação do Resultado (Leitura da RAM)
        // ==========================================
        $display("\n--- Lendo o Baralho da RAM ---");
        
        for (i = 0; i < 108; i = i + 1) begin
            game_ram_addr = i; // Informa o endereço que queremos ler
            #20;               // Espera 1 ciclo de clock para a RAM responder
            
            // Imprime no console o endereço e o dado lido em binário
            $display("Carta na posicao %0d da RAM: %b", i, game_ram_data_out);
        end

        $display("--- Fim da Simulacao ---");
        
        // Finaliza a simulação no ModelSim
        #50;
        $stop;
    end

endmodule