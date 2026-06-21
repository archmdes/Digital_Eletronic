module top_uno (

    input clk,
    input reset

);

    reg [7:0] played_card;
    reg apply_effect;
    reg current_turn;

    wire next_turn;
    wire skip_next;
    wire SKIP_ACTION;
    wire DRAW_ACTION;
    wire [2:0] draw_count;

    special_cards_control u1 (
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

	endmodule