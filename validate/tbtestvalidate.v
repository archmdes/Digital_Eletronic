`timescale 1ns/1ps

module validate_move_tb;

    // Entradas
    reg clk;
    reg rst;
    reg PLAYER_TURN;
    reg CPU_TURN;
    reg [7:0] PLAYER_CARD;
    reg [7:0] CPU_CARD;
    reg [7:0] TOP_CARD;

    // Saídas
    wire INVALID_MOVE;
    wire SPECIAL_CARD;
    wire [7:0] NEW_TOP_CARD;

    // Instancia o módulo
    validate_move uut (
        .clk(clk),
        .rst(rst),
        .PLAYER_CARD(PLAYER_CARD),
        .CPU_CARD(CPU_CARD),
        .TOP_CARD(TOP_CARD),
        .PLAYER_TURN(PLAYER_TURN),
        .CPU_TURN(CPU_TURN),
        .INVALID_MOVE(INVALID_MOVE),
        .SPECIAL_CARD(SPECIAL_CARD),
        .NEW_TOP_CARD(NEW_TOP_CARD)
    );

    // Clock: período de 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Tarefa: aplica sinais e exibe resultado após borda
    task aplicar_teste;
        input [63:0] descricao; // apenas para referência no log
        input        p_turn;
        input        c_turn;
        input [7:0]  p_card;
        input [7:0]  c_card;
        input [7:0]  t_card;
        begin
            PLAYER_TURN = p_turn;
            CPU_TURN    = c_turn;
            PLAYER_CARD = p_card;
            CPU_CARD    = c_card;
            TOP_CARD    = t_card;
            @(posedge clk); #1;
            $display("PLAYER_CARD=%b  CPU_CARD=%b  TOP=%b | INVALID=%b  SPECIAL=%b  NEW_TOP=%b  [estado=%b]",
                      PLAYER_CARD, CPU_CARD, TOP_CARD,
                      INVALID_MOVE, SPECIAL_CARD, NEW_TOP_CARD,
                      uut.estado_atual);
        end
    endtask

    // Tarefa: aguarda N ciclos exibindo o estado (para ver INVALID_MOVE durando)
    task aguardar_ciclos;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk); #1;
                $display("  >> ciclo extra | INVALID=%b  SPECIAL=%b  NEW_TOP=%b  [estado=%b]",
                          INVALID_MOVE, SPECIAL_CARD, NEW_TOP_CARD,
                          uut.estado_atual);
            end
        end
    endtask

    initial begin
        // Inicialização
        rst         = 1;
        PLAYER_TURN = 0;
        CPU_TURN    = 0;
        PLAYER_CARD = 8'b0;
        CPU_CARD    = 8'b0;
        TOP_CARD    = 8'b0;

        // Reset por 2 ciclos
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // -------------------------------------------------------
        // BLOCO 1: testes do PLAYER
        // -------------------------------------------------------
        $display("\n=== Testes do PLAYER ===");

        // Teste 1: mesma cor (azul) → segueJogada
        // TOP:    00_0001_01  (azul, naipe 1, normal)
        // PLAYER: 00_0011_01  (azul, naipe 3, normal)
        $display("-- Teste 1: mesma cor (azul) -> segueJogada");
        aplicar_teste("T1", 1, 0, 8'b00_0011_01, 8'b0, 8'b00_0001_01);

        // Volta ao IDLE entre testes
        PLAYER_TURN = 0;
        @(posedge clk); #1;

        // Teste 2: mesmo naipe (3), cor diferente → segueJogada
        // TOP:    00_0011_01  (azul, naipe 3)
        // PLAYER: 00_0011_10  (amarelo, naipe 3)
        $display("-- Teste 2: mesmo naipe, cor diferente -> segueJogada");
        aplicar_teste("T2", 1, 0, 8'b00_0011_10, 8'b0, 8'b00_0011_01);

        PLAYER_TURN = 0;
        @(posedge clk); #1;

        // Teste 3: cor e naipe diferentes → invalidMove (2 ciclos)
        // TOP:    00_0001_01  (azul, naipe 1)
        // PLAYER: 00_0111_11  (verde, naipe 7)
        $display("-- Teste 3: cor e naipe diferentes -> invalidMove (2 ciclos)");
        aplicar_teste("T3", 1, 0, 8'b00_0111_11, 8'b0, 8'b00_0001_01);
        aguardar_ciclos(3); // observa os 2 ciclos de INVALID_MOVE + retorno ao IDLE

        PLAYER_TURN = 0;
        @(posedge clk); #1;

        // Teste 4: carta especial +2 → cartaEspecial
        // PLAYER: 01_0000_01  (azul, especial=01 → +2)
        $display("-- Teste 4: carta especial +2 -> cartaEspecial");
        aplicar_teste("T4", 1, 0, 8'b01_0000_01, 8'b0, 8'b00_0001_01);

        PLAYER_TURN = 0;
        @(posedge clk); #1;

        // Teste 5: carta especial +4 → cartaEspecial
        // PLAYER: 11_0000_00  (especial=11 → +4/trocar cor)
        $display("-- Teste 5: carta especial +4 -> cartaEspecial");
        aplicar_teste("T5", 1, 0, 8'b11_0000_00, 8'b0, 8'b00_0001_01);

        PLAYER_TURN = 0;
        @(posedge clk); #1;

        // -------------------------------------------------------
        // BLOCO 2: testes da CPU
        // -------------------------------------------------------
        $display("\n=== Testes da CPU ===");

        // Teste 6: CPU joga carta normal → segueJogada
        // CPU:    00_0101_11  (verde, naipe 5, normal)
        $display("-- Teste 6: CPU carta normal -> segueJogada");
        aplicar_teste("T6", 0, 1, 8'b0, 8'b00_0101_11, 8'b00_0001_01);

        CPU_TURN = 0;
        @(posedge clk); #1;

        // Teste 7: CPU joga carta especial reverso → cartaEspecial
        // CPU:    10_0000_10  (amarelo, especial=10 → reverso)
        $display("-- Teste 7: CPU carta especial reverso -> cartaEspecial");
        aplicar_teste("T7", 0, 1, 8'b0, 8'b10_0000_10, 8'b00_0001_01);

        CPU_TURN = 0;
        @(posedge clk); #1;

        // -------------------------------------------------------
        // BLOCO 3: caso sem turno ativo → IDLE
        // -------------------------------------------------------
        $display("\n=== Sem turno ativo (IDLE) ===");
        $display("-- Teste 8: nenhum turno -> IDLE, saidas zeradas");
        aplicar_teste("T8", 0, 0, 8'b00_0011_01, 8'b0, 8'b00_0001_01);

        $display("\n=== Fim dos testes ===");
        $finish;
    end

endmodule