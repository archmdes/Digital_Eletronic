module special_cards_control (

    input clk,
    input reset,

    input [7:0] played_card,
    input apply_effect,
    input current_turn,

    output reg next_turn,
    output reg skip_next,
    output reg SKIP_ACTION,
    output reg DRAW_ACTION,
    output reg [2:0] draw_count

);

    parameter SKIP  = 4'd10;
    parameter REV   = 4'd11;
    parameter DRAW2 = 4'd12;
    parameter WILD  = 4'd13;
    parameter DRAW4 = 4'd14;

    wire [3:0] value;
    assign value = played_card[5:2];

    reg [31:0] counter;
    parameter TEMPO_2S = 32'd100000000;

    always @(posedge clk or posedge reset) begin

      if (reset) begin
         SKIP_ACTION <= 0;
         DRAW_ACTION <= 0;
         draw_count  <= 0;
         next_turn   <= 0;
         skip_next   <= 0;
         counter     <= 0;
        end

        else begin
          next_turn <= 0;
          skip_next <= 0;

          if (apply_effect) begin
             SKIP_ACTION <= 0;
             DRAW_ACTION <= 0;
             draw_count  <= 0;

             if (value == SKIP || value == REV) begin
                SKIP_ACTION <= 1;
                skip_next   <= 1;
                end

                else if (value == DRAW2) begin
                    DRAW_ACTION <= 1;
                    draw_count  <= 2;
                end

                else if (value == DRAW4) begin
                    DRAW_ACTION <= 1;
                    draw_count  <= 4;
                end

                next_turn <= 1;
            end

            if (SKIP_ACTION || DRAW_ACTION) begin
                counter <= counter + 1;

                if (counter >= TEMPO_2S) begin
                    SKIP_ACTION <= 0;
                    DRAW_ACTION <= 0;
                    counter <= 0;
                end
            end

        end
    end

endmodule