module uno (
    input  wire        CLK,
    input  wire        RESET,

    // Pulsos de botao JA CONDICIONADOS (vindos do modulo "interface")
    input  wire        SELECT,   // escolhe a proxima carta da mao do PLAYER
    input  wire        PLAY,     // joga a carta selecionada
    input  wire        DRAW,     // compra uma carta do baralho

    output wire        PLAYER_TURN,
    output wire        CPU_TURN,
    output wire        INVALID_MOVE,
    output wire        DRAW_ACTION,
    output wire        SKIP_ACTION,
    output reg         WIN,
    output reg         LOSE,

    // Saidas de informacao para os displays
    output wire [3:0]  N_PLAYER,
    output wire [3:0]  N_CPU,
    output wire [7:0]  PLAYER_CARD,
    output wire [7:0]  TOP_CARD
);

    // =========================================================================
    // PARAMETROS GERAIS
    // =========================================================================
    localparam NUM_CARTAS  = 108;   // cartas totais do baralho de UNO
    localparam MAX_MAO     = 24;    // profundidade maxima das maos

    // =========================================================================
    // ESTADOS DA FSM PRINCIPAL (Movidos para o topo!)
    // =========================================================================
    localparam
        ST_RESET            = 6'd0,
        ST_EMB_START        = 6'd1,
        ST_EMB_WAIT         = 6'd2,
        ST_DIST_LER         = 6'd3,
        ST_DIST_GRAVA       = 6'd4,
        ST_MESA_LER         = 6'd5,
        ST_MESA_GRAVA       = 6'd6,
        ST_TURNO_PLAYER     = 6'd7,
        ST_PLAYER_VALIDA    = 6'd8,
        ST_PLAYER_RESULTADO = 6'd9,
        ST_PLAYER_EFEITO    = 6'd10,
        ST_PLAYER_EFEITO_LE = 6'd11,
        ST_PLAYER_PASSA     = 6'd12,
        ST_PLAYER_INVALIDA  = 6'd13,
        ST_PLAYER_DRAW_PREP = 6'd14,
        ST_PLAYER_DRAW_CHK  = 6'd15,
        ST_TURNO_CPU        = 6'd16,
        ST_CPU_VALIDA       = 6'd17,
        ST_CPU_RESULTADO    = 6'd18,
        ST_CPU_EFEITO       = 6'd19,
        ST_CPU_EFEITO_LE    = 6'd20,
        ST_CPU_PASSA        = 6'd21,
        ST_CPU_DRAW_PREP    = 6'd22,
        ST_CPU_DRAW_CHK     = 6'd23,
        ST_COMPRA_VERIFICA  = 6'd24,
        ST_COMPRA_TRANSF1   = 6'd25,
        ST_COMPRA_TRANSF2   = 6'd26,
        ST_COMPRA_TRANSF3   = 6'd27,
        ST_COMPRA_LER       = 6'd28,
        ST_COMPRA_GRAVA     = 6'd29,
        ST_COMPRA_RETORNA   = 6'd30,
        ST_WIN              = 6'd31,
        ST_LOSE             = 6'd32,
        // ---------------------------------------------------------------
        // NOVOS ESTADOS DE ESPERA (fix do bug de temporizacao da RAM)
        // -----------------------------------------------------------------
        // A ram_cartas.v e uma RAM sincrona: "data_out <= ram[addr]" so
        // captura o endereco correto se ele estiver ESTAVEL no barramento
        // durante o ciclo INTEIRO anterior ao flanco de leitura. Como
        // "fsm_ram_addr" e atribuido de forma nao-bloqueante no estado LER,
        // o novo endereco só fica visível no barramento a partir do ciclo
        // seguinte. Sem um estado extra de espera, o estado GRAVA acaba
        // lendo o dado referente ao endereco ANTERIOR (defasado em uma
        // posicao), corrompendo a distribuicao de cartas, a carta do topo
        // e as compras. O modulo "embaralhador" ja usa esse padrao de 3
        // estados corretamente (SET/ESPERA/LATCH); replicamos aqui.
        // ---------------------------------------------------------------
        ST_DIST_ESPERA      = 6'd33,
        ST_MESA_ESPERA      = 6'd34,
        ST_COMPRA_ESPERA    = 6'd35;

    reg [5:0] estado;

    // =========================================================================
    // BANCO DE REGISTRADORES DO JOGO
    // =========================================================================
    reg [7:0] mao_player [0:MAX_MAO-1];
    reg [7:0] mao_cpu    [0:MAX_MAO-1];
    reg [4:0] n_player, n_cpu;          // quantidade de cartas em cada mao
    reg [4:0] sel_idx;                  // carta atualmente selecionada (PLAYER)

    reg [7:0] top_card_r;               // carta no topo da pilha de descarte
    reg [7:0] pilha_descarte [0:NUM_CARTAS-1];
    reg [6:0] n_descarte;               // quantidade de cartas na pilha (exceto o topo)

    reg [6:0] deck_ptr;                 // proximo endereco a comprar na RAM
    reg [6:0] baralho_tam;              // tamanho atual do baralho de compra

    // turno: 0 = vez do PLAYER, 1 = vez da CPU
    wire turno = (estado == ST_TURNO_CPU     || estado == ST_CPU_VALIDA   ||
                  estado == ST_CPU_RESULTADO || estado == ST_CPU_EFEITO   ||
                  estado == ST_CPU_EFEITO_LE || estado == ST_CPU_PASSA    ||
                  estado == ST_CPU_DRAW_PREP || estado == ST_CPU_DRAW_CHK);
                  
    reg [4:0] dist_count;               // contador da distribuicao inicial (0..13)

    reg [2:0] compras_restantes;
    reg       quem_compra;              // 0 = PLAYER, 1 = CPU compra
    reg       autoplay_apos_compra;
    reg [5:0] retorno_estado;
    reg [7:0] ultima_compra;
    reg [6:0] j_transf;

    reg [4:0] idx_cpu_valida;           // indice de carta valida encontrada na mao da CPU
    reg [4:0] tmp_idx;                  // variavel auxiliar (combinacional) usada na busca acima

    assign N_PLAYER    = (n_player > 15) ? 4'd15 : n_player[3:0];
    assign N_CPU       = (n_cpu    > 15) ? 4'd15 : n_cpu[3:0];
    assign PLAYER_CARD = (n_player == 0) ? 8'd0 : mao_player[sel_idx];
    assign TOP_CARD    = top_card_r;

    // =========================================================================
    // SUBMODULOS: memoria do baralho + embaralhador + gerador aleatorio
    // =========================================================================
    wire [6:0] rom_addr_w;
    wire [6:0] rom_data_w;

    wire        ram_we_w;
    wire [6:0]  ram_addr_w;
    wire [6:0]  ram_data_w_w;
    wire [6:0]  ram_data_r_w;

    wire [15:0] rand_valor_w;
    wire        rand_avanca_w;

    wire        emb_start_w, emb_done_w, emb_pular_copia_w;
    wire [6:0]  emb_quantidade_w;

    reg         fsm_ram_we;
    reg  [6:0]  fsm_ram_addr;
    reg  [6:0]  fsm_ram_data_w;
    reg         embaralhando; // 1 = barramento da RAM pertence ao embaralhador

    // Fios movidos para antes do assign!
    wire emb_ram_we;
    wire [6:0] emb_ram_addr;
    wire [6:0] emb_ram_data_w;

    assign ram_we_w     = embaralhando ? emb_ram_we      : fsm_ram_we;
    assign ram_addr_w   = embaralhando ? emb_ram_addr    : fsm_ram_addr;
    assign ram_data_w_w = embaralhando ? emb_ram_data_w  : fsm_ram_data_w;

    rom_cartas #(.DATA_WIDTH(7), .ADDR_WIDTH(7)) U_ROM (
        .clk      (CLK),
        .addr     (rom_addr_w),
        .data_out (rom_data_w)
    );

    ram_cartas #(.DATA_WIDTH(7), .ADDR_WIDTH(7), .NUM_CARTAS(NUM_CARTAS)) U_RAM (
        .clk      (CLK),
        .we       (ram_we_w),
        .addr     (ram_addr_w),
        .data_in  (ram_data_w_w),
        .data_out (ram_data_r_w)
    );

    gerador_aleatorio #(.LARGURA(16)) U_LFSR (
        .clk    (CLK),
        .rst    (RESET),
        .seed   (16'hBEEF),
        .avanca (rand_avanca_w),
        .valor  (rand_valor_w)
    );

    embaralhador #(.DATA_WIDTH(7), .ADDR_WIDTH(7), .NUM_CARTAS(NUM_CARTAS)) U_EMB (
        .clk          (CLK),
        .rst          (RESET),
        .start        (emb_start_w),
        .done         (emb_done_w),
        .pular_copia  (emb_pular_copia_w),
        .quantidade   (emb_quantidade_w),
        .rom_addr     (rom_addr_w),
        .rom_data     (rom_data_w),
        .ram_we       (emb_ram_we),
        .ram_addr     (emb_ram_addr),
        .ram_data_w   (emb_ram_data_w),
        .ram_data_r   (ram_data_r_w),
        .rand_avanca  (rand_avanca_w),
        .rand_valor   (rand_valor_w)
    );

    // =========================================================================
    // SUBMODULOS: validacao de jogada e efeitos de cartas especiais
    // =========================================================================
    reg         vm_player_turn, vm_cpu_turn;
    reg  [7:0]  vm_player_card, vm_cpu_card;
    wire        vm_invalid_move, vm_special_card;
    wire [7:0]  vm_new_top_card;

    validate_move U_VALIDA (
        .clk           (CLK),
        .rst           (RESET),
        .PLAYER_TURN   (vm_player_turn),
        .CPU_TURN      (vm_cpu_turn),
        .PLAYER_CARD   (vm_player_card),
        .CPU_CARD      (vm_cpu_card),
        .TOP_CARD      (top_card_r),
        .INVALID_MOVE  (vm_invalid_move),
        .SPECIAL_CARD  (vm_special_card),
        .NEW_TOP_CARD  (vm_new_top_card)
    );

    reg         sc_apply_effect;
    reg [7:0]   sc_played_card;
    wire        sc_skip_next;
    wire        sc_skip_action_w, sc_draw_action_w;
    wire [2:0]  sc_draw_count;

    special_cards_control U_ESPECIAL (
        .clk          (CLK),
        .reset        (RESET),
        .played_card  (sc_played_card),
        .apply_effect (sc_apply_effect),
        .skip_next    (sc_skip_next),
        .SKIP_ACTION  (sc_skip_action_w),
        .DRAW_ACTION  (sc_draw_action_w),
        .draw_count   (sc_draw_count)
    );

    // =========================================================================
    // ALARGADORES DE PULSO
    // =========================================================================
    reg p_player_turn, p_cpu_turn, p_invalid_move, p_draw_action, p_skip_action;
    reg efeito_skip_next;

    alarga_pulso U_AL_PT (.clk(CLK), .rst(RESET), .pulso_in(p_player_turn),  .saida(PLAYER_TURN));
    alarga_pulso U_AL_CT (.clk(CLK), .rst(RESET), .pulso_in(p_cpu_turn),     .saida(CPU_TURN));
    alarga_pulso U_AL_IM (.clk(CLK), .rst(RESET), .pulso_in(p_invalid_move), .saida(INVALID_MOVE));
    alarga_pulso U_AL_DA (.clk(CLK), .rst(RESET), .pulso_in(p_draw_action),  .saida(DRAW_ACTION));
    alarga_pulso U_AL_SA (.clk(CLK), .rst(RESET), .pulso_in(p_skip_action),  .saida(SKIP_ACTION));

    // =========================================================================
    // Funcao combinacional
    // =========================================================================
    function carta_valida;
        input [7:0] carta;
        input [7:0] topo;
        reg         esp_c, esp_t;
        reg  [1:0]  cor_c, cor_t;
        reg  [3:0]  val_c, val_t;
        reg         curinga;
        begin
            esp_c   = carta[6];
            cor_c   = carta[5:4];
            val_c   = carta[3:0];
            esp_t   = topo[6];
            cor_t   = topo[5:4];
            val_t   = topo[3:0];
            curinga = esp_c && (val_c == 4'd3 || val_c == 4'd4);

            carta_valida = curinga
                         || (cor_c == cor_t)
                         || (!esp_c && !esp_t && (val_c == val_t))
                         || ( esp_c &&  esp_t && (val_c == val_t)
                              && val_c != 4'd3 && val_c != 4'd4);
        end
    endfunction

    integer k;

    // Pulsos para o embaralhador
    reg         r_emb_start, r_emb_pular_copia;
    reg [6:0]   r_emb_quantidade;
    assign emb_start_w       = r_emb_start;
    assign emb_pular_copia_w = r_emb_pular_copia;
    assign emb_quantidade_w  = r_emb_quantidade;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            estado            <= ST_RESET;
            embaralhando      <= 1'b0;
            r_emb_start       <= 1'b0;
            r_emb_pular_copia <= 1'b0;
            r_emb_quantidade  <= 7'd0;
            fsm_ram_we        <= 1'b0;
            fsm_ram_addr      <= 7'd0;
            fsm_ram_data_w    <= 7'd0;
            n_player          <= 5'd0;
            n_cpu             <= 5'd0;
            sel_idx           <= 5'd0;
            top_card_r        <= 8'd0;
            n_descarte        <= 7'd0;
            deck_ptr          <= 7'd0;
            baralho_tam       <= NUM_CARTAS;
            dist_count        <= 5'd0;
            compras_restantes <= 3'd0;
            quem_compra       <= 1'b0;
            autoplay_apos_compra <= 1'b0;
            retorno_estado    <= ST_TURNO_PLAYER;
            ultima_compra     <= 8'd0;
            j_transf          <= 7'd0;
            idx_cpu_valida    <= 5'd0;
            WIN               <= 1'b0;
            LOSE              <= 1'b0;
            p_player_turn     <= 1'b0;
            p_cpu_turn        <= 1'b0;
            p_invalid_move    <= 1'b0;
            p_draw_action     <= 1'b0;
            p_skip_action     <= 1'b0;
            efeito_skip_next  <= 1'b0;
            vm_player_turn    <= 1'b0;
            vm_cpu_turn       <= 1'b0;
            vm_player_card    <= 8'd0;
            vm_cpu_card       <= 8'd0;
            sc_apply_effect   <= 1'b0;
            sc_played_card    <= 8'd0;
        end
        else begin
            p_player_turn  <= 1'b0;
            p_cpu_turn     <= 1'b0;
            p_invalid_move <= 1'b0;
            p_draw_action  <= 1'b0;
            p_skip_action  <= 1'b0;
            vm_player_turn <= 1'b0;
            vm_cpu_turn    <= 1'b0;
            sc_apply_effect<= 1'b0;
            fsm_ram_we     <= 1'b0;

            case (estado)

                ST_RESET: begin
                    n_player    <= 5'd0; n_cpu <= 5'd0; sel_idx <= 5'd0;
                    n_descarte  <= 7'd0; deck_ptr <= 7'd0;
                    baralho_tam <= 7'd108; 
                    dist_count  <= 5'd0;
                    WIN <= 1'b0; LOSE <= 1'b0;
                    embaralhando      <= 1'b1;
                    r_emb_pular_copia <= 1'b0;
                    r_emb_quantidade  <= NUM_CARTAS;
                    estado <= ST_EMB_START;
                end

                ST_EMB_START: begin
                    r_emb_start <= 1'b1;
                    estado      <= ST_EMB_WAIT;
                end

                ST_EMB_WAIT: begin
                    if (emb_done_w) begin
                        r_emb_start  <= 1'b0;
                        embaralhando <= 1'b0;
                        deck_ptr     <= 0;
                        dist_count   <= 0;
                        estado       <= ST_DIST_LER;
                    end
                end

                ST_DIST_LER: begin
                    fsm_ram_addr <= deck_ptr;
                    fsm_ram_we   <= 1'b0;
                    estado       <= ST_DIST_ESPERA;
                end

                // NOVO: aguarda 1 ciclo o endereco se estabilizar no
                // barramento antes de confiar no dado lido da RAM.
                ST_DIST_ESPERA: begin
                    estado <= ST_DIST_GRAVA;
                end

                ST_DIST_GRAVA: begin
                    if (dist_count[0] == 1'b0) begin
                        mao_player[n_player] <= {1'b0, ram_data_r_w};
                        n_player <= n_player + 1'b1;
                    end
                    else begin
                        mao_cpu[n_cpu] <= {1'b0, ram_data_r_w};
                        n_cpu <= n_cpu + 1'b1;
                    end
                    deck_ptr <= deck_ptr + 1'b1;

                    if (dist_count == 13) begin
                        estado <= ST_MESA_LER; 
                    end
                    else begin
                        dist_count <= dist_count + 1'b1;
                        estado     <= ST_DIST_LER;
                    end
                end

                ST_MESA_LER: begin
                    fsm_ram_addr <= deck_ptr;
                    fsm_ram_we   <= 1'b0;
                    estado       <= ST_MESA_ESPERA;
                end

                // NOVO: mesmo motivo do ST_DIST_ESPERA acima.
                ST_MESA_ESPERA: begin
                    estado <= ST_MESA_GRAVA;
                end

                ST_MESA_GRAVA: begin
                    top_card_r <= {1'b0, ram_data_r_w};
                    deck_ptr   <= deck_ptr + 1'b1;
                    p_player_turn <= 1'b1;
                    estado     <= ST_TURNO_PLAYER;
                end

                ST_TURNO_PLAYER: begin
                    if (SELECT && n_player > 0) begin
                        sel_idx <= (sel_idx == n_player - 1) ? 5'd0 : (sel_idx + 1'b1);
                    end
                    else if (PLAY && n_player > 0) begin
                        vm_player_turn <= 1'b1;
                        vm_player_card <= mao_player[sel_idx];
                        estado <= ST_PLAYER_VALIDA;
                    end
                    else if (DRAW) begin
                        compras_restantes    <= 3'd1;
                        quem_compra          <= 1'b0; 
                        autoplay_apos_compra <= 1'b1;
                        retorno_estado       <= ST_PLAYER_DRAW_CHK;
                        estado               <= ST_COMPRA_VERIFICA;
                    end
                end

                ST_PLAYER_VALIDA: begin
                    estado <= ST_PLAYER_RESULTADO;
                end

                ST_PLAYER_RESULTADO: begin
                    if (vm_invalid_move) begin
                        estado <= ST_PLAYER_INVALIDA;
                    end
                    else begin
                        pilha_descarte[n_descarte] <= top_card_r;
                        n_descarte <= n_descarte + 1'b1;
                        top_card_r <= vm_new_top_card;

                        for (k = 0; k < MAX_MAO - 1; k = k + 1) begin
                            if (k >= sel_idx && k < n_player - 1)
                                mao_player[k] <= mao_player[k+1];
                        end
                        n_player <= n_player - 1'b1;
                        if (sel_idx > 0) sel_idx <= sel_idx - 1'b1;

                        if (vm_special_card) begin
                            sc_apply_effect <= 1'b1;
                            sc_played_card  <= vm_new_top_card;
                            estado <= ST_PLAYER_EFEITO;
                        end
                        else begin
                            efeito_skip_next <= 1'b0; 
                            estado <= ST_PLAYER_PASSA;
                        end
                    end
                end

                ST_PLAYER_INVALIDA: begin
                    p_invalid_move <= 1'b1;
                    estado <= ST_TURNO_PLAYER;
                end

                ST_PLAYER_EFEITO: begin
                    estado <= ST_PLAYER_EFEITO_LE;
                end

                ST_PLAYER_EFEITO_LE: begin
                    if (sc_skip_action_w) p_skip_action <= 1'b1;
                    if (sc_draw_action_w) p_draw_action <= 1'b1;
                    
                    efeito_skip_next <= sc_skip_next;

                    if (sc_draw_count != 0) begin
                        compras_restantes    <= sc_draw_count;
                        quem_compra          <= 1'b1; 
                        autoplay_apos_compra <= 1'b0; 
                        retorno_estado       <= ST_PLAYER_PASSA;
                        estado               <= ST_COMPRA_VERIFICA;
                    end
                    else begin
                        estado <= ST_PLAYER_PASSA;
                    end
                end

                ST_PLAYER_PASSA: begin
                    if (n_player == 0) begin
                        estado <= ST_WIN;
                    end
                    else if (efeito_skip_next) begin
                        efeito_skip_next <= 1'b0;
                        p_player_turn <= 1'b1;
                        estado <= ST_TURNO_PLAYER;
                    end
                    else begin
                        p_cpu_turn <= 1'b1;
                        estado <= ST_TURNO_CPU;
                    end
                end

                ST_PLAYER_DRAW_CHK: begin
                    if (carta_valida(ultima_compra, top_card_r)) begin
                        pilha_descarte[n_descarte] <= top_card_r;
                        n_descarte <= n_descarte + 1'b1;
                        top_card_r <= ultima_compra;
                        n_player   <= n_player - 1'b1; 

                        if (ultima_compra[6]) begin
                            sc_apply_effect <= 1'b1;
                            sc_played_card  <= ultima_compra;
                            estado <= ST_PLAYER_EFEITO;
                        end
                        else begin
                            efeito_skip_next <= 1'b0;
                            estado <= ST_PLAYER_PASSA;
                        end
                    end
                    else begin
                        efeito_skip_next <= 1'b0;
                        estado <= ST_PLAYER_PASSA;
                    end
                end

                ST_TURNO_CPU: begin
                    tmp_idx = n_cpu[4:0]; 
                    for (k = 0; k < MAX_MAO; k = k + 1) begin
                        if (k < n_cpu && tmp_idx == n_cpu && carta_valida(mao_cpu[k], top_card_r))
                            tmp_idx = k;
                    end
                    idx_cpu_valida <= tmp_idx;
                    estado <= ST_CPU_VALIDA;
                end

                ST_CPU_VALIDA: begin
                    if (idx_cpu_valida == n_cpu) begin
                        compras_restantes    <= 3'd1;
                        quem_compra          <= 1'b1;
                        autoplay_apos_compra <= 1'b1;
                        retorno_estado       <= ST_CPU_DRAW_CHK;
                        estado               <= ST_COMPRA_VERIFICA;
                    end
                    else begin
                        vm_cpu_turn <= 1'b1;
                        vm_cpu_card <= mao_cpu[idx_cpu_valida];
                        estado <= ST_CPU_RESULTADO;
                    end
                end

                ST_CPU_RESULTADO: begin
                    pilha_descarte[n_descarte] <= top_card_r;
                    n_descarte <= n_descarte + 1'b1;
                    top_card_r <= vm_new_top_card;

                    for (k = 0; k < MAX_MAO - 1; k = k + 1) begin
                        if (k >= idx_cpu_valida && k < n_cpu - 1)
                            mao_cpu[k] <= mao_cpu[k+1];
                    end
                    n_cpu <= n_cpu - 1'b1;

                    if (vm_special_card) begin
                        sc_apply_effect <= 1'b1;
                        sc_played_card  <= vm_new_top_card;
                        estado <= ST_CPU_EFEITO;
                    end
                    else begin
                        efeito_skip_next <= 1'b0;
                        estado <= ST_CPU_PASSA;
                    end
                end

                ST_CPU_EFEITO: begin
                    estado <= ST_CPU_EFEITO_LE;
                end

                ST_CPU_EFEITO_LE: begin
                    if (sc_skip_action_w) p_skip_action <= 1'b1;
                    if (sc_draw_action_w) p_draw_action <= 1'b1;
                    efeito_skip_next <= sc_skip_next; 

                    if (sc_draw_count != 0) begin
                        compras_restantes    <= sc_draw_count;
                        quem_compra          <= 1'b0; 
                        autoplay_apos_compra <= 1'b0;
                        retorno_estado       <= ST_CPU_PASSA;
                        estado               <= ST_COMPRA_VERIFICA;
                    end
                    else begin
                        estado <= ST_CPU_PASSA;
                    end
                end

                ST_CPU_PASSA: begin
                    if (n_cpu == 0) begin
                        estado <= ST_LOSE;
                    end
                    else if (efeito_skip_next) begin
                        efeito_skip_next <= 1'b0;
                        p_cpu_turn <= 1'b1;
                        estado <= ST_TURNO_CPU;
                    end
                    else begin
                        p_player_turn <= 1'b1;
                        estado <= ST_TURNO_PLAYER;
                    end
                end

                ST_CPU_DRAW_CHK: begin
                    if (carta_valida(ultima_compra, top_card_r)) begin
                        pilha_descarte[n_descarte] <= top_card_r;
                        n_descarte <= n_descarte + 1'b1;
                        top_card_r <= ultima_compra;
                        n_cpu      <= n_cpu - 1'b1; 

                        if (ultima_compra[6]) begin
                            sc_apply_effect <= 1'b1;
                            sc_played_card  <= ultima_compra;
                            estado <= ST_CPU_EFEITO;
                        end
                        else begin
                            efeito_skip_next <= 1'b0;
                            estado <= ST_CPU_PASSA;
                        end
                    end
                    else begin
                        efeito_skip_next <= 1'b0;
                        estado <= ST_CPU_PASSA;
                    end
                end

                ST_COMPRA_VERIFICA: begin
                    if (deck_ptr >= baralho_tam) begin
                        if (n_descarte > 0) begin
                            j_transf <= 0;
                            estado   <= ST_COMPRA_TRANSF1;
                        end
                        else begin
                            estado <= retorno_estado;
                        end
                    end
                    else begin
                        estado <= ST_COMPRA_LER;
                    end
                end

                ST_COMPRA_TRANSF1: begin
                    fsm_ram_we     <= 1'b1;
                    fsm_ram_addr   <= j_transf;
                    fsm_ram_data_w <= pilha_descarte[j_transf][6:0];

                    if (j_transf == n_descarte - 1) begin
                        baralho_tam <= n_descarte;
                        deck_ptr    <= 0;
                        n_descarte  <= 0;
                        estado      <= ST_COMPRA_TRANSF2;
                    end
                    else begin
                        j_transf <= j_transf + 1'b1;
                    end
                end

                ST_COMPRA_TRANSF2: begin
                    embaralhando      <= 1'b1;
                    r_emb_pular_copia <= 1'b1;
                    r_emb_quantidade  <= baralho_tam;
                    r_emb_start       <= 1'b1;
                    estado            <= ST_COMPRA_TRANSF3;
                end

                ST_COMPRA_TRANSF3: begin
                    if (emb_done_w) begin
                        r_emb_start  <= 1'b0;
                        embaralhando <= 1'b0;
                        estado       <= ST_COMPRA_LER;
                    end
                end

                ST_COMPRA_LER: begin
                    fsm_ram_addr <= deck_ptr;
                    fsm_ram_we   <= 1'b0;
                    estado       <= ST_COMPRA_ESPERA;
                end

                // NOVO: mesmo motivo do ST_DIST_ESPERA acima.
                ST_COMPRA_ESPERA: begin
                    estado <= ST_COMPRA_GRAVA;
                end

                ST_COMPRA_GRAVA: begin
                    ultima_compra <= {1'b0, ram_data_r_w};
                    if (quem_compra == 1'b0) begin
                        mao_player[n_player] <= {1'b0, ram_data_r_w};
                        n_player <= n_player + 1'b1;
                    end
                    else begin
                        mao_cpu[n_cpu] <= {1'b0, ram_data_r_w};
                        n_cpu <= n_cpu + 1'b1;
                    end
                    deck_ptr <= deck_ptr + 1'b1;
                    p_draw_action <= 1'b1;

                    if (compras_restantes == 1) begin
                        estado <= ST_COMPRA_RETORNA;
                    end
                    else begin
                        compras_restantes <= compras_restantes - 1'b1;
                        estado <= ST_COMPRA_VERIFICA;
                    end
                end

                ST_COMPRA_RETORNA: begin
                    if (autoplay_apos_compra)
                        estado <= retorno_estado; 
                    else
                        estado <= retorno_estado; 
                end

                ST_WIN: begin
                    WIN <= 1'b1;
                end

                ST_LOSE: begin
                    LOSE <= 1'b1;
                end

                default: estado <= ST_RESET;
            endcase
        end
    end

endmodule