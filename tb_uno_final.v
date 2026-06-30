`timescale 1ns/1ps

module tb_uno;

    // Sinais de controle
    reg clk;
    reg rst;
    reg select;
    reg play;
    reg draw;

    // Sinais de monitoramento
    wire player_turn;
    wire cpu_turn;
    wire invalid_move;
    wire draw_action;
    wire skip_action;
    wire win;
    wire lose;
    wire [3:0] n_player;
    wire [3:0] n_cpu;
    wire [7:0] player_card;
    wire [7:0] top_card;

    // Identificador de arquivo para o relatório
    integer arquivo;

    // Instancia da FSM principal
    uno U_UNO (
        .CLK          (clk),
        .RESET        (rst),
        .SELECT       (select),
        .PLAY         (play),
        .DRAW         (draw),
        .PLAYER_TURN  (player_turn),
        .CPU_TURN     (cpu_turn),
        .INVALID_MOVE (invalid_move),
        .DRAW_ACTION  (draw_action),
        .SKIP_ACTION  (skip_action),
        .WIN          (win),
        .LOSE         (lose),
        .N_PLAYER     (n_player),
        .N_CPU        (n_cpu),
        .PLAYER_CARD  (player_card),
        .TOP_CARD     (top_card)
    );

    // Reduzindo o timer dos LEDs para a simulação andar rápido
    defparam U_UNO.U_AL_PT.CICLOS = 2;
    defparam U_UNO.U_AL_CT.CICLOS = 2;
    defparam U_UNO.U_AL_IM.CICLOS = 2;
    defparam U_UNO.U_AL_DA.CICLOS = 2;
    defparam U_UNO.U_AL_SA.CICLOS = 2;

    // Geração do Clock (50MHz)
    always #10 clk = ~clk;

    // =========================================================================
    // FUNÇÕES E TASKS AUXILIARES
    // =========================================================================
    task print_card;
        input [7:0] c;
        reg [1:0] color;
        reg [3:0] val;
        reg esp;
        begin
            esp = c[6];
            color = c[5:4];
            val = c[3:0];
            if (esp) begin
                if (val == 3) $write("WILD");
                else if (val == 4) $write("WILD_DRAW4");
                else begin
                    if (color==0) $write("VERMELHO_");
                    else if (color==1) $write("AMARELO_");
                    else if (color==2) $write("VERDE_");
                    else if (color==3) $write("AZUL_");
                    if (val == 0) $write("SKIP");
                    else if (val == 1) $write("REVERSE");
                    else if (val == 2) $write("DRAW2");
                end
            end else begin
                if (color==0) $write("VERMELHO_");
                else if (color==1) $write("AMARELO_");
                else if (color==2) $write("VERDE_");
                else if (color==3) $write("AZUL_");
                $write("%0d", val);
            end
        end
    endtask

    function is_valid;
        input [7:0] card;
        input [7:0] top;
        reg esp_c, esp_t;
        reg [1:0] cor_c, cor_t;
        reg [3:0] val_c, val_t;
        reg curinga;
        begin
            esp_c = card[6]; cor_c = card[5:4]; val_c = card[3:0];
            esp_t = top[6];  cor_t = top[5:4];  val_t = top[3:0];
            curinga = esp_c && (val_c == 4'd3 || val_c == 4'd4);
            is_valid = curinga || (cor_c == cor_t) || 
                       (!esp_c && !esp_t && (val_c == val_t)) ||
                       (esp_c && esp_t && (val_c == val_t) && val_c != 3 && val_c != 4);
        end
    endfunction

    task wait_for_turn;
        begin
            while (U_UNO.estado != 6'd7 && U_UNO.estado != 6'd16 && U_UNO.estado != 6'd31 && U_UNO.estado != 6'd32) begin
                @(posedge clk);
            end
        end
    endtask

    task do_player_turn;
        integer k;
        reg valid_found;
        reg [7:0] target_card;
        begin
            valid_found = 0;
            for (k = 0; k < n_player; k = k + 1) begin
                if (is_valid(U_UNO.mao_player[k], top_card)) begin
                    valid_found = 1;
                    target_card = U_UNO.mao_player[k];
                    k = 99;
                end
            end

            $fdisplay(arquivo, "[%0t] TURNO DO PLAYER | Mao: %0d cartas.", $time, n_player);
            if (valid_found) begin
                $fdisplay(arquivo, "      -> Acao: Jogando carta valida.");
                while (player_card !== target_card) begin
                    select = 1; @(posedge clk); select = 0; @(posedge clk);
                end
                play = 1; @(posedge clk); play = 0; @(posedge clk);
            end else begin
                $fdisplay(arquivo, "      -> Acao: Sem carta valida. Comprando.");
                draw = 1; @(posedge clk); draw = 0; @(posedge clk);
            end
        end
    endtask

    // =========================================================================
    // LÓGICA PRINCIPAL
    // =========================================================================
    integer i, turn;

    initial begin
        arquivo = $fopen("log_simulacao_uno.txt", "w");
        $dumpfile("simulacao_uno.vcd");
        $dumpvars(0, tb_uno);

        $fdisplay(arquivo, "=== INICIANDO SIMULACAO UNO ===");
        
        clk = 0; rst = 1; select = 0; play = 0; draw = 0;
        #100 rst = 0;

        wait_for_turn();

        turn = 0;
        while (!win && !lose && turn < 150) begin
            if (U_UNO.estado == 6'd7) begin
                do_player_turn();
                @(posedge clk); 
                wait_for_turn();
            end 
            else if (U_UNO.estado == 6'd16) begin
                $fdisplay(arquivo, "[%0t] TURNO DA CPU | Mao: %0d cartas.", $time, n_cpu);
                @(posedge clk); 
                wait_for_turn(); 
            end
            turn = turn + 1;
        end

        $fdisplay(arquivo, "=== FIM DE JOGO (WIN: %b, LOSE: %b) ===", win, lose);
        $fclose(arquivo);
        $finish; 
    end
endmodule