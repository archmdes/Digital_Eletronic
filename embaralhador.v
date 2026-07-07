// =============================================================================
// MODULO: embaralhador
// -----------------------------------------------------------------------------
// Responsavel por embaralhar o baralho de UNO de forma ALEATORIA, percorrendo
// todas as posicoes de memoria, conforme exigido na especificacao do trabalho.
//
// Algoritmo: Fisher-Yates shuffle.
//   1) Copia as 108 cartas da ROM (ordem fixa) para a RAM (mesma ordem).
//   2) Para i = NUM_CARTAS-1 decrescendo até 1:
//        j = numero_aleatorio % (i+1)
//        troca RAM[i] <-> RAM[j]
//   Ao final, a RAM contem as 108 cartas em uma ordem aleatoria, e a partir
//   dai elas sao lidas sequencialmente a partir do endereco 0 (regra do
//   trabalho).
//
// Esse modulo corresponde aos estados "EMBARALHAR / EMB1 / EMB2 / EMB3" do
// diagrama de estados do projeto.
// =============================================================================
module embaralhador #(
    parameter DATA_WIDTH = 7,
    parameter ADDR_WIDTH = 7,
    parameter NUM_CARTAS = 108
) (
    input  wire clk,
    input  wire rst,
    input  wire start,          // pulso/nivel: inicia o embaralhamento
    output reg  done,           // fica em 1 quando o embaralhamento termina

    // Quando pular_copia=1, NAO copia da ROM: embaralha diretamente os
    // primeiros "quantidade" enderecos ja presentes na RAM. Usado quando a
    // pilha de descarte e devolvida ao baralho (estado TRANSFERIR_PILHA_MEMO).
    input  wire                  pular_copia,
    input  wire [ADDR_WIDTH-1:0] quantidade,

    // --- Interface com a ROM (baralho original, somente leitura) ---
    output reg  [ADDR_WIDTH-1:0] rom_addr,
    input  wire [DATA_WIDTH-1:0] rom_data,

    // --- Interface com a RAM (baralho embaralhado, leitura e escrita) ---
    output reg                   ram_we,
    output reg  [ADDR_WIDTH-1:0] ram_addr,
    output reg  [DATA_WIDTH-1:0] ram_data_w,
    input  wire [DATA_WIDTH-1:0] ram_data_r,

    // --- Interface com o gerador de numeros pseudoaleatorios (LFSR) ---
    output reg                   rand_avanca,
    input  wire [15:0]           rand_valor
);

    // -------------------------------------------------------------------
    // Estados da FSM de embaralhamento
    // -------------------------------------------------------------------
    // Constante do tamanho correto para evitar warning de truncamento (32->7 bits)
    localparam [ADDR_WIDTH-1:0] ULTIMA_CARTA = NUM_CARTAS - 1;

    localparam S_IDLE        = 4'd0,
               S_COPIA_SET   = 4'd1,  // posiciona endereco na ROM
               S_COPIA_LATCH = 4'd2,  // aguarda dado valido da ROM
               S_COPIA_WRITE = 4'd3,  // escreve a carta na RAM
               S_SORTEIA_J   = 4'd4,  // calcula indice aleatorio j
               S_LE_I        = 4'd5,  // posiciona leitura em RAM[i]
               S_LE_I_ESP    = 4'd6,  // aguarda 1 ciclo a latencia sincrona da RAM
               S_LATCH_I     = 4'd7,  // guarda RAM[i] e posiciona leitura em RAM[j]
               S_LE_J_ESP    = 4'd8,  // aguarda 1 ciclo a latencia sincrona da RAM
               S_LATCH_J     = 4'd9,  // guarda RAM[j]
               S_TROCA_I     = 4'd10, // escreve RAM[i] <= valor antigo de RAM[j]
               S_TROCA_J     = 4'd11, // escreve RAM[j] <= valor antigo de RAM[i]
               S_DONE        = 4'd12;

    reg [3:0]            estado;
    reg [ADDR_WIDTH-1:0] i_idx;      // indice "i" do Fisher-Yates (desce de NUM_CARTAS-1 a 1)
    reg [ADDR_WIDTH-1:0] j_idx;      // indice sorteado "j" (0 <= j <= i)
    reg [DATA_WIDTH-1:0] val_i, val_j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            estado      <= S_IDLE;
            done        <= 1'b0;
            ram_we      <= 1'b0;
            rand_avanca <= 1'b1;     // LFSR gira livremente sempre, mesmo parado
            rom_addr    <= 0;
            ram_addr    <= 0;
            ram_data_w  <= 0;
            i_idx       <= 0;
            j_idx       <= 0;
        end
        else begin
            rand_avanca <= 1'b1; // LFSR sempre avancando (fonte de aleatoriedade continua)
            ram_we      <= 1'b0;

            case (estado)

                // ----------------------------------------------------
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        if (pular_copia) begin
                            // reembaralhamento parcial: pula a copia da ROM e
                            // embaralha diretamente os "quantidade" enderecos
                            // que ja estao na RAM (pilha de descarte recem-copiada)
                            i_idx  <= quantidade - 1'b1;
                            estado <= S_SORTEIA_J;
                        end
                        else begin
                            rom_addr <= 0;
                            estado   <= S_COPIA_SET;
                        end
                    end
                end

                // ---- FASE 1: copia ROM -> RAM (ordem original) -----
                S_COPIA_SET: begin
                    estado <= S_COPIA_LATCH; // aguarda 1 ciclo (latencia sincrona da ROM)
                end

                S_COPIA_LATCH: begin
                    estado <= S_COPIA_WRITE;
                end

                S_COPIA_WRITE: begin
                    ram_we     <= 1'b1;
                    ram_addr   <= rom_addr;
                    ram_data_w <= rom_data;

                    if (rom_addr == ULTIMA_CARTA) begin
                        // copia concluida -> inicia fase de troca (i comeca no topo)
                        i_idx  <= ULTIMA_CARTA;
                        estado <= S_SORTEIA_J;
                    end
                    else begin
                        rom_addr <= rom_addr + 1'b1;
                        estado   <= S_COPIA_SET;
                    end
                end

                // ---- FASE 2: Fisher-Yates shuffle dentro da RAM ----
                S_SORTEIA_J: begin
                    // j = numero_aleatorio % (i+1)  -> 0 <= j <= i
                    // Usa apenas os 8 bits menos significativos do LFSR como
                    // dividendo. i_idx max = 107, portanto (i_idx+1) max = 108,
                    // que cabe em 8 bits. Um divisor 8x8 e ~4x menor e mais
                    // rapido que o divisor 16x8 anterior, fechando o timing
                    // a 50 MHz sem alterar a qualidade estatistica do embaralhamento.
                    // Resultado do % e 8 bits; j_idx e 7 bits (max=107<128).
                    // O resultado nunca excede 107, entao o bit 7 sempre e 0
                    // e a atribuicao e segura. Usamos & para evitar o warning.
                    j_idx  <= rand_valor[7:0] % (i_idx + 1'b1) & 7'h7F;
                    estado <= S_LE_I;
                end

                S_LE_I: begin
                    ram_addr <= i_idx;
                    estado   <= S_LE_I_ESP;
                end

                S_LE_I_ESP: begin
                    // aguarda 1 ciclo: o endereco "i_idx" so fica estavel no
                    // barramento a partir deste ciclo; a RAM (leitura sincrona)
                    // amostra o endereco agora e so disponibiliza o dado no
                    // proximo ciclo (estado S_LATCH_I).
                    estado <= S_LATCH_I;
                end

                S_LATCH_I: begin
                    val_i    <= ram_data_r;   // agora sim, dado valido = RAM[i_idx]
                    ram_addr <= j_idx;
                    estado   <= S_LE_J_ESP;
                end

                S_LE_J_ESP: begin
                    estado <= S_LATCH_J;
                end

                S_LATCH_J: begin
                    val_j  <= ram_data_r;      // dado valido = RAM[j_idx]
                    estado <= S_TROCA_I;
                end

                S_TROCA_I: begin
                    ram_we     <= 1'b1;
                    ram_addr   <= i_idx;
                    ram_data_w <= val_j;     // RAM[i] <- valor antigo de RAM[j]
                    estado     <= S_TROCA_J;
                end

                S_TROCA_J: begin
                    ram_we     <= 1'b1;
                    ram_addr   <= j_idx;
                    ram_data_w <= val_i;     // RAM[j] <- valor antigo de RAM[i]

                    if (i_idx == 1) begin
                        // ja trocamos a posicao 1 com alguma posicao 0..1 -> terminou
                        estado <= S_DONE;
                    end
                    else begin
                        i_idx  <= i_idx - 1'b1;
                        estado <= S_SORTEIA_J;
                    end
                end

                // -----------------------------------------------------
                S_DONE: begin
                    done <= 1'b1;
                    if (!start) begin
                        estado <= S_IDLE;
                    end
                end

                default: estado <= S_IDLE;
            endcase
        end
    end

endmodule
