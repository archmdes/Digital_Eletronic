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

    // Saidas
    wire INVALID_MOVE;
    wire SPECIAL_CARD;
    wire [7:0] NEW_TOP_CARD;

    // Instancia o modulo
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

    
    initial clk = 0
    always #5 clk = ~clk;

    // Tarefa auxiliar para exibir resultado
    task show_result;
        input [7:0] card;
        input [7:0] top;
        begin
        @(posedge clk); // ? espera a borda de subida
        #1;             // ? pequeno delay para pegar sa�da estabilizada
        $display("CARD=%b  TOP=%b  | INVALID=%b  SPECIAL=%b  NEW_TOP=%b",
                  card, top, INVALID_MOVE, SPECIAL_CARD, NEW_TOP_CARD);
        end
    endtask
    
    initial begin
        // Inicializa��o
        clk = 0;
        rst = 1;
        PLAYER_TURN = 0;
        CPU_TURN    = 0;
        PLAYER_CARD = 8'b0;
        CPU_CARD    = 8'b0;
        TOP_CARD    = 8'b0;
	
	    @(posedge clk);
        @(posedge clk);
        #10 rst = 0;

        $display("=== Testes do PLAYER ===");

        // -------------------------------------------------
        // Teste 1: mesma cor (azul), carta normal ? V�LIDA
        // TOP:    000 0001 01  (azul, naipe 1, normal)
        // PLAYER: 000 0011 01  (azul, naipe 3, normal)
        // -------------------------------------------------
        PLAYER_TURN = 1;
        TOP_CARD    = 8'b00_0001_01;
        PLAYER_CARD = 8'b00_0011_01;
        show_result(PLAYER_CARD, TOP_CARD);

        // -------------------------------------------------
        // Teste 2: mesmo naipe (3), cor diferente ? V�LIDA
        // TOP:    000 0011 01  (azul, naipe 3)
        // PLAYER: 000 0011 10  (amarelo, naipe 3)
        // -------------------------------------------------
        TOP_CARD    = 8'b00_0011_01;
        PLAYER_CARD = 8'b00_0011_10;
        show_result(PLAYER_CARD, TOP_CARD);

        // -------------------------------------------------
        // Teste 3: cor e naipe diferentes ? INV�LIDA
        // TOP:    000 0001 01  (azul, naipe 1)
        // PLAYER: 000 0111 11  (verde, naipe 7)
        // -------------------------------------------------
        TOP_CARD    = 8'b00_0001_01;
        PLAYER_CARD = 8'b00_0111_11;
	show_result(PLAYER_CARD, TOP_CARD);

        // -------------------------------------------------
        // Teste 4: carta especial +2 ? SPECIAL_CARD
        // PLAYER: 10 0000 01  (azul, +2)
        // -------------------------------------------------
        TOP_CARD    = 8'b00_0001_01;
        PLAYER_CARD = 8'b10_0000_01;
        show_result(PLAYER_CARD, TOP_CARD);

        // -------------------------------------------------
        // Teste 5: carta especial +4 ? SPECIAL_CARD
        // PLAYER: 01 0000 00  (+4, troca cor)
        // -------------------------------------------------
        TOP_CARD    = 8'b00_0001_01;
        PLAYER_CARD = 8'b01_0000_00;
        show_result(PLAYER_CARD, TOP_CARD);

        $display("=== Teste da CPU ===");

        // -------------------------------------------------
        // Teste 6: CPU joga carta normal ? s� atualiza topo
        // -------------------------------------------------
        PLAYER_TURN = 0;
        CPU_TURN    = 1;
        TOP_CARD    = 8'b00_0001_01;
        CPU_CARD    = 8'b00_0101_11;
        show_result(CPU_CARD, TOP_CARD);

        // -------------------------------------------------
        // Teste 7: CPU joga carta especial reverso
        // -------------------------------------------------
        CPU_CARD = 8'b10_0000_10;
        show_result(CPU_CARD, TOP_CARD);

        $display("=== Fim dos testes ===");
        $finish;
    end

endmodule     