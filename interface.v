module interface (
    input wire CLK,        
    input wire RESET,      
    input wire SELECT,      
    input wire PLAY,       
    input wire DRAW,        

    input wire [3:0] N_PLAYER,     
    input wire [3:0] N_CPU,         
    input wire [7:0] PLAYER_CARD,  
    input wire [7:0] TOP_CARD,      
    
    input wire PLAYER_TURN,       
    input wire CPU_TURN,          
    input wire INVALID_MOVE,       
    input wire DRAW_ACTION,         
    input wire SKIP_ACTION,       
    input wire WIN,                
    input wire LOSE,               

    output wire select_pulse,
    output wire play_pulse,
    output wire draw_pulse,

    output wire [7:0] HEX0, // Display 0 (PLAYER_CARD - Valor)
    output wire [7:0] HEX1, // Display 1 (PLAYER_CARD - Cor)
    output wire [7:0] HEX2, // Display 2 (TOP_CARD - Valor)
    output wire [7:0] HEX3, // Display 3 (TOP_CARD - Cor)
    output wire [7:0] HEX4, // Display 4 (N_PLAYER - Unidade)
	output wire [7:0] HEX5, // Display 5 (N_PLAYER - Dezena)
    output wire [7:0] HEX6, // Display 6 (N_CPU - Unidade)
	output wire [7:0] HEX7, // Display 7 (N_CPU - Dezena)
    
	output wire [8:0] LEDG, // LEDs Verdes (Turnos e Vitória/Ação Válida)
    output wire [17:0] LEDR // LEDs Vermelhos (Erros, Ações Especiais e Derrota)
);
/////
/////////////// INSTANCIANDO O CONDICIONADOR PARA O BOTÃO
	
    button_conditioner btn_select (
        .clk(CLK),
        .btn_in(SELECT),
        .pulse_out(select_pulse)
    );

    button_conditioner btn_play (
        .clk(CLK),
        .btn_in(PLAY),
        .pulse_out(play_pulse)
    );

    button_conditioner btn_draw (
        .clk(CLK),
        .btn_in(DRAW),
        .pulse_out(draw_pulse)
    );
//////
//////////////// DECODIFICACAO DOS DISPLAYS

    card_decoder decoder_player (
        .card_id(PLAYER_CARD),
        .hex_color(HEX1),
        .hex_val(HEX0)
    );

    card_decoder decoder_top (
        .card_id(TOP_CARD),
        .hex_color(HEX3),
        .hex_val(HEX2)
    );

    bcd_to_7seg bcd_player (
        .binary_in(N_PLAYER),
        .hex_tens(HEX5),
        .hex_units(HEX4)
    );

    bcd_to_7seg bcd_cpu (
        .binary_in(N_CPU),
        .hex_tens(HEX7),
        .hex_units(HEX6)
    );
	 
///	 
	 led_controller led_ctrl (
    .clk(CLK), .reset(RESET),
    .PLAYER_TURN(PLAYER_TURN), .CPU_TURN(CPU_TURN),
    .INVALID_MOVE(INVALID_MOVE), .DRAW_ACTION(DRAW_ACTION), .SKIP_ACTION(SKIP_ACTION),
    .WIN(WIN), .LOSE(LOSE),
    .LEDG(LEDG), .LEDR(LEDR)
);

endmodule

///////////FILTRP DO BOTÃO

module button_conditioner (
    input wire clk,
    input wire btn_in,
    output reg pulse_out
);
	
 // O ~btn_in inverte o sinal, fazendo a lógica interna trabalhar com 1 = Pressionado.
    reg sync_0 = 0, sync_1 = 0;
    always @(posedge clk) begin
        sync_0 <= ~btn_in;
        sync_1 <= sync_0;
    end

    parameter DEBOUNCE_LIMIT = 1000000; //para teste voltar para 1000000
    reg [19:0] counter = 0;
    reg stable_state = 0;

    always @(posedge clk) begin
        if (sync_1 != stable_state) begin
            counter <= counter + 1;
            if (counter == DEBOUNCE_LIMIT) begin
                stable_state <= sync_1;
                counter <= 0;
            end
        end else begin
            counter <= 0;
        end
    end

    reg delayed_state = 0;
    always @(posedge clk) begin
        delayed_state <= stable_state;
        pulse_out <= stable_state & ~delayed_state;
    end

endmodule

///////////DECODIFICADOR DE ID DE CARTA PARA 7 SEGS
module card_decoder (
    input wire [7:0] card_id,
    output reg [7:0] hex_color,
    output reg [7:0] hex_val
);

    wire [3:0] color = card_id[7:4];
    wire [3:0] val   = card_id[3:0];

	
    // Mapeamento de Cores (Active Low: 0=ON, 1=OFF)
    // Ordem dos bits: [ DP g f e d c b a ]
    always @(*) begin
        case(color)
            4'd0: hex_color = 8'b1010_1111;  // r (Red)
            4'd1: hex_color = 8'b1100_0010;  // G (Green)
            4'd2: hex_color = 8'b1000_0011;  // b (Blue)
            4'd3: hex_color = 8'b1001_0001;  // Y (Yellow)
            4'd4: hex_color = 8'b1000_0110;  // E (Especial)
            default: hex_color = 8'b1111_1111; 
        endcase
    end

    always @(*) begin
        case(val)
            4'd0:  hex_val = 8'b1100_0000; //'0'
            4'd1:  hex_val = 8'b1111_1001; //'1'
            4'd2:  hex_val = 8'b1010_0100; //'2'
            4'd3:  hex_val = 8'b1011_0000; //'3'
            4'd4:  hex_val = 8'b1001_1001; //'4'
            4'd5:  hex_val = 8'b1001_0010; //'5'
            4'd6:  hex_val = 8'b1000_0010; //'6'
            4'd7:  hex_val = 8'b1111_1000; //'7'
            4'd8:  hex_val = 8'b1000_0000; //'8'
            4'd9:  hex_val = 8'b1001_0000; //'9'
			4'd10: hex_val = 8'b1011_1111; //'-' (Skip)
			4'd11: hex_val = 8'b1110_0011; //'u' (reverse)
			4'd12: hex_val = 8'b0010_0100; //'2. (+2)
			4'd13: hex_val = 8'b1100_0110; //C' (Muda de cor)
			4'd14: hex_val = 8'b0001_1001; //'4.' (+4)
            default: hex_val = 8'b1111_1111;
        endcase
    end
endmodule

///////////CONVERSOR BINÁRIO PARA BCD 7 SEG
module bcd_to_7seg (
	input wire [3:0] binary_in, ///MAX 15 CARTAS
    output reg [7:0] hex_tens,
    output reg [7:0] hex_units
);
    reg [3:0] tens, units;

    always @(*) begin
        if (binary_in > 9) begin
            tens  = 1;
            units = binary_in - 10;
        end else begin
            tens  = 0;
            units = binary_in;
        end
    end

    function [7:0] seg7;
        input [3:0] digit;
        case(digit)
            4'd0: seg7 = 8'b1100_0000;
            4'd1: seg7 = 8'b1111_1001;
            4'd2: seg7 = 8'b1010_0100;
            4'd3: seg7 = 8'b1011_0000;
            4'd4: seg7 = 8'b1001_1001;
            4'd5: seg7 = 8'b1001_0010;
            4'd6: seg7 = 8'b1000_0010;
            4'd7: seg7 = 8'b1111_1000;
            4'd8: seg7 = 8'b1000_0000;
            4'd9: seg7 = 8'b1001_0000;
            default: seg7 = 8'b1111_1111;
        endcase
    endfunction

    always @(*) begin
        if (tens == 0)
            hex_tens = 8'b1111_1111;
        else
            hex_tens = seg7(tens);
            
        hex_units = seg7(units);
    end
endmodule

///////////TEMPORIZACAO DO LED
module led_controller (
    input wire clk,
    input wire reset,
    input wire PLAYER_TURN, CPU_TURN,
    input wire INVALID_MOVE, DRAW_ACTION, SKIP_ACTION,
    input wire WIN, LOSE,
    
    output reg [8:0] LEDG,
    output reg [17:0] LEDR
);
/// CONTADOR DE 2s
    reg [26:0] timer = 0;
    reg active_timer = 0;
   
    reg latch_error = 0;
    reg latch_action = 0;

    reg is_win = 0;
    reg is_lose = 0;

    always @(posedge clk) begin
        if (~reset) begin
            timer <= 0;
            active_timer <= 0;
            latch_error <= 0;
            latch_action <= 0;
            is_win <= 0;
            is_lose <= 0;
        end 
        else begin
            if (WIN) is_win <= 1;
            if (LOSE) is_lose <= 1;

            if (active_timer) begin
                if (timer < 100000000) begin // para teste colocar depois para 100000000
                    timer <= timer + 1;
                end else begin
                    timer <= 0;
                    active_timer <= 0;
                    latch_error <= 0;
                    latch_action <= 0;
                end
            end 
            else if (INVALID_MOVE) begin
                active_timer <= 1;
                latch_error <= 1;
            end 
            else if (DRAW_ACTION || SKIP_ACTION) begin
                active_timer <= 1;
                latch_action <= 1;
            end
        end
    end
/////PRIORIDADE
    always @(*) begin
        LEDG = 9'b0;
        LEDR = 18'b0;
//// WIN OU LOSE
        if (is_win) begin
            LEDG = 9'b111111111; 
        end
        else if (is_lose) begin
            LEDR = 18'b111111111111111111; 
        end
        ////AVISOS
        else if (active_timer) begin
            if (latch_error) LEDR = 18'b111111111111111111; 
            if (latch_action) LEDG = 9'b111111111; 
        end
        /// TURNOS
        else begin
            LEDG[0] = PLAYER_TURN;
            LEDG[1] = CPU_TURN;
        end
    end
endmodule
