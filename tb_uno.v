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

    // Reduzindo o timer dos LEDs para a simulação rodar muito rápido
    defparam U_UNO.U_AL_PT.CICLOS = 2;
    defparam U_UNO.U_AL_CT.CICLOS = 2;
    defparam U_UNO.U_AL_IM.CICLOS = 2;
    defparam U_UNO.U_AL_DA.CICLOS = 2;
    defparam U_UNO.U_AL_SA.CICLOS = 2;

    // Geração do Clock (50MHz)
    always #10 clk = ~clk;

    // =========================================================================
    // TASKS AUXILIARES
    // =========================================================================

    // Imprime o nome da carta legível direto no log
    task print_card_name;
        input [7:0] c;
        reg [1:0] color;
        reg [3:0] val;
        reg esp;
        begin
            esp = c[6];
            color = c[5:4];
            val = c[3:0];
            if (esp) begin
                if (val == 3) $fwrite(arquivo, "WILD");
                else if (val == 4) $fwrite(arquivo, "WILD_DRAW4");
                else begin
                    if (color==0) $fwrite(arquivo, "VERMELHO_");
                    else if (color==1) $fwrite(arquivo, "AMARELO_");
                    else if (color==2) $fwrite(arquivo, "VERDE_");
                    else if (color==3) $fwrite(arquivo, "AZUL_");
                    
                    if (val == 0) $fwrite(arquivo, "SKIP");
                    else if (val == 1) $fwrite(arquivo, "REVERSE");
                    else if (val == 2) $fwrite(arquivo, "DRAW2");
                end
            end else begin
                if (color==0) $fwrite(arquivo, "VERMELHO_");
                else if (color==1) $fwrite(arquivo, "AMARELO_");
                else if (color==2) $fwrite(arquivo, "VERDE_");
                else if (color==3) $fwrite(arquivo, "AZUL_");
                $fwrite(arquivo, "%0d", val);
            end
        end
    endtask

    // Aguarda pelo turno de alguém (Estados: 7=Player, 16=CPU, 31=Win, 32=Lose)
    task wait_for_turn;
        integer timeout;
        begin
            timeout = 0;
            while (U_UNO.estado != 6'd7 && U_UNO.estado != 6'd16 && U_UNO.estado != 6'd31 && U_UNO.estado != 6'd32) begin
                @(posedge clk);
                timeout = timeout + 1;
                
                if (timeout > 100000) begin
                    $fdisplay(arquivo, "[ERRO FATAL] FSM presa no estado: %0d. Abortando.", U_UNO.estado);
                    $fflush(arquivo);
                    $finish;
                end
            end
        end
    endtask

    // Executa a interação de um jogador real com os botões
    task do_player_turn;
        integer attempts;
        reg move_accepted;
        begin
            $fwrite(arquivo, "[%0t] TURNO DO PLAYER | Mao: %0d cartas | Topo: ", $time, n_player);
            print_card_name(top_card);
            $fdisplay(arquivo, ""); // Quebra linha
            $fflush(arquivo);

            attempts = 0;
            move_accepted = 0;

            while (attempts < n_player && !move_accepted) begin
                // 1. Aperta PLAY na carta atual
                play = 1;
                @(posedge clk); play = 0;
                
                // 2. Aguarda 1 clock para FSM processar o botao e sair do estado 7
                @(posedge clk);

                // 3. Enquanto a FSM estiver validando (8), mostrando erro (13) ou resultado (9), aguarda.
                while (U_UNO.estado == 6'd8 || U_UNO.estado == 6'd9 || U_UNO.estado == 6'd13) begin
                    @(posedge clk);
                end

                // 4. Se a FSM voltar para o estado 7, a jogada foi invalida!
                if (U_UNO.estado == 6'd7) begin
                    // Aperta SELECT para rotacionar a carta da mao
                    select = 1;
                    @(posedge clk); select = 0;
                    @(posedge clk); // 1 clock pro sel_idx atualizar
                    attempts = attempts + 1;
                end else begin
                    // A FSM avancou (estado 10 ou 12), jogada aceita!
                    move_accepted = 1;
                end
            end

            // 5. Se rodou toda a mao e nada foi aceito, aperta DRAW.
            if (!move_accepted) begin
                $fdisplay(arquivo, "      -> Nenhuma carta da mao foi aceita. Comprando (DRAW)...");
                $fflush(arquivo);
                draw = 1; @(posedge clk); draw = 0;
            end else begin
                $fdisplay(arquivo, "      -> Carta da mao (Tentativa %0d) jogada com sucesso!", attempts + 1);
                $fflush(arquivo);
            end
        end
    endtask

    // Observa a jogada da CPU sem interferir
    task log_cpu_turn;
        begin
            $fwrite(arquivo, "[%0t] TURNO DA CPU    | Mao: %0d cartas | Topo: ", $time, n_cpu);
            print_card_name(top_card);
            $fdisplay(arquivo, ""); // Quebra linha
            $fflush(arquivo);

            // A CPU roda sozinha, entao apenas esperamos ela sair do estado 16.
            while (U_UNO.estado == 6'd16) @(posedge clk);
        end
    endtask


    // =========================================================================
    // LÓGICA PRINCIPAL
    // =========================================================================
    integer turn_count;
    
    initial begin
        arquivo = $fopen("log_simulacao_uno.txt", "w");
        $dumpfile("simulacao_uno.vcd");
        $dumpvars(0, tb_uno);
        
        $fdisplay(arquivo, "=== INICIANDO SIMULACAO UNO (FSM Autonoma para CPU) ===");
        $fflush(arquivo);
        
        clk = 0; rst = 1; select = 0; play = 0; draw = 0;
        #100 rst = 0;

        wait_for_turn();

        turn_count = 0;
        // Roda o jogo até que alguem ganhe ou chegue no limite (para não rodar infinito)
        while (!win && !lose && turn_count < 250) begin
            
            if (U_UNO.estado == 6'd7) begin
                do_player_turn();
                wait_for_turn();
                turn_count = turn_count + 1; // Soma o turno apenas se jogou
            end 
            else if (U_UNO.estado == 6'd16) begin
                log_cpu_turn();
                wait_for_turn(); 
                turn_count = turn_count + 1; // Soma o turno apenas se jogou
            end
            else begin
                // ESTADOS DE FIM DE JOGO (31 ou 32)
                // Aguarda o clock bater para que os sinais 'win' e 'lose' 
                // sejam atualizados pela FSM antes de testar o while de novo.
                @(posedge clk);
            end
            
        end

        $fdisplay(arquivo, "=======================================");
        if (win) $fdisplay(arquivo, "=== FIM DE JOGO: O PLAYER VENCEU!!! ===");
        else if (lose) $fdisplay(arquivo, "=== FIM DE JOGO: A CPU VENCEU!!! ===");
        else $fdisplay(arquivo, "=== FIM DE JOGO: EMPATE (LIMITE DE TURNOS ATINGIDO) ===");
        
        $fclose(arquivo);
        $finish; 
    end
endmodule