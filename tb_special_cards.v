module tb_special_cards;

    // ENTRADAS (simuladas)
    reg clk;
    reg reset;
    reg [7:0] played_card;
    reg apply_effect;
    reg current_turn;

    // SAÍDAS (observadas)
    wire next_turn;
    wire skip_next;
    wire SKIP_ACTION;
    wire DRAW_ACTION;
    wire [2:0] draw_count;


 // INSTÂNCIA DO MÓDULO
    special_cards_control uut (
        .clk(clk),
        .reset(reset),
        .played_card(played_card),
        .apply_effect(apply_effect),
        .current_turn(current_turn),
        .next_turn(next_turn),
        .skip_next(skip_next),
        .SKIP_ACTION(SKIP_ACTION),
        .DRAW_ACTION(DRAW_ACTION),
        .draw_count(draw_count)
    );

    // CLOCK (10ns período)
    always #5 clk = ~clk;
   
	// TESTES
    initial begin

  // Inicialização
        clk = 0;
        reset = 1;
        apply_effect = 0;
        current_turn = 0;

        #10 reset = 0;

   // TESTE 1 — SKIP
  
        played_card = 8'b00101000; // valor = 10
        apply_effect = 1;
        #10 apply_effect = 0;

        #30;
  // TESTE 2 — +2
        played_card = 8'b00110000; // valor = 12
        apply_effect = 1;
        #10 apply_effect = 0;

        #30;
        
 // TESTE 3 — +4
    played_card = 8'b00111000; // valor = 14
    apply_effect = 1;
    #10 apply_effect = 0;
    #50;
        $stop;

    end

endmodule