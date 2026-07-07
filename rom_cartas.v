module rom_cartas #(
    parameter DATA_WIDTH = 7,
    parameter ADDR_WIDTH = 7
) (
    input  wire                  clk,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] rom [0:127];

    initial begin
        $readmemb("uno_deck_rom.txt", rom);

        // -----------------------------------------------------------
        // VERIFICACAO DE SEGURANCA: se o arquivo nao foi encontrado ou
        // nao pode ser lido, rom[0] permanece com bits 'X'. Isso e uma
        // causa MUITO comum de bugs silenciosos (o design "funciona"
        // mas todos os dados sao X). Emitimos um erro alto e explicito
        // em vez de deixar o jogo rodar silenciosamente corrompido.
        // -----------------------------------------------------------
        if (^rom[0] === 1'bx) begin
            $display("################################################################");
            $display("# ERRO FATAL: rom_cartas.v nao conseguiu carregar");
            $display("# 'uno_deck_rom.txt' -- rom[0] esta em estado X.");
            $display("# Verifique se o arquivo uno_deck_rom.txt esta no diretorio");
            $display("# de trabalho a partir de onde a simulacao foi INICIADA");
            $display("# (nao necessariamente o diretorio dos arquivos .v).");
            $display("################################################################");
            $finish;
        end
    end

    // Leitura sincrona
    always @(posedge clk) begin
        data_out <= rom[addr];
    end

endmodule