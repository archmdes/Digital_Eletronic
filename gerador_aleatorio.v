// =============================================================================
// MODULO: gerador_aleatorio
// -----------------------------------------------------------------------------
// Gera uma sequencia pseudoaleatoria de numeros usando um LFSR (Linear
// Feedback Shift Register) de 16 bits, no polinomio x^16+x^14+x^13+x^11+1
// (maximal, periodo 65535).
//
// O registrador "gira" em TODO ciclo de clock, independente do jogo estar
// rodando ou nao. Como o jogador aciona o botao RESET em um instante de tempo
// que nao tem relacao com a fase do LFSR, o valor capturado no momento do
// embaralhamento e, na pratica, imprevisivel/"aleatorio" o suficiente para
// um jogo de cartas - essa e a tecnica classica usada em projetos didaticos
// de FPGA, ja que o dispositivo nao possui fonte de entropia fisica.
//
// Entradas:
//   clk   -> clock do sistema
//   rst   -> reset assincrono (carrega a semente SEED)
//   seed  -> semente inicial (carregada no reset). Nao pode ser zero.
//   avanca-> quando em 1, o LFSR avanca 1 passo por ciclo de clock
//             (deixado sempre em 1 para girar livremente)
//
// Saida:
//   valor -> estado atual do LFSR (16 bits)
// =============================================================================
module gerador_aleatorio #(
    parameter LARGURA = 16
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire [LARGURA-1:0]    seed,
    input  wire                  avanca,
    output reg  [LARGURA-1:0]    valor
);

    wire bit_feedback;

    // Polinomio de realimentacao (taps 16,14,13,11 -> indices 15,13,12,10)
    assign bit_feedback = valor[15] ^ valor[13] ^ valor[12] ^ valor[10];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Semente nunca pode ser todo-zero (estado morto do LFSR)
            valor <= (seed == 0) ? 16'hACE1 : seed;
        end
        else if (avanca) begin
            valor <= {valor[14:0], bit_feedback};
        end
    end

endmodule
