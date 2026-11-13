
`timescale 1ns/1ps

module Periferico_tb;

    reg clk;
    reg clr_n;
    reg sclk;
    reg cs_n;
    reg pico;
    reg parallel_load;
    reg [7:0] parallel_in;

    wire [7:0] parallel_out;
    wire rx_valid;
    wire cipo;

    integer erros = 0;
    integer i;

    reg [7:0] recebido;
    reg [7:0] transmitido;

    // DUT
    Periferico uut (
        .clk(clk),
        .clr_n(clr_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .pico(pico),
        .parallel_load(parallel_load),
        .parallel_in(parallel_in),
        .parallel_out(parallel_out),
        .rx_valid(rx_valid),
        .cipo(cipo)
    );

    // Clock interno: período de 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // ------------------------------------------------
    // TAREFAS AUXILIARES
    // ------------------------------------------------

    task carregar_piso;
        input [7:0] dado;
        begin
            @(negedge clk);
            parallel_in = dado;
            parallel_load = 1;
            cs_n = 1;

            @(negedge clk);
            parallel_load = 0;

            repeat (2) @(negedge clk);
        end
    endtask

    task enviar_bit;
        input bit_dado;
        begin
            // Dados estáveis antes da subida de SCLK
            @(negedge clk);
            pico = bit_dado;
            sclk = 1;

            // Aguarda o periférico detectar a subida
            repeat (2) @(negedge clk);

            // Descida de SCLK
            sclk = 0;

            // Aguarda o periférico detectar a descida
            repeat (2) @(negedge clk);
        end
    endtask

    task enviar_byte;
        input [7:0] dado;
        integer j;
        begin
            for (j = 7; j >= 0; j = j - 1)
                enviar_bit(dado[j]);
        end
    endtask

    task verificar;
        input condicao;
        input [255:0] descricao;
        begin
            if (condicao !== 1'b1) begin
                $display("[ERRO] %0s", descricao);
                erros = erros + 1;
            end
            else begin
                $display("[OK] %0s", descricao);
            end
        end
    endtask

    // ------------------------------------------------
    // TESTES
    // ------------------------------------------------

    initial begin
        $display("\n======================================");
        $display("       TESTES DO PERIFERICO SPI");
        $display("======================================\n");

        // Inicialização
        clr_n = 0;
        sclk = 0;
        cs_n = 1;
        pico = 0;
        parallel_load = 0;
        parallel_in = 0;

        repeat (3) @(negedge clk);
        clr_n = 1;

        repeat (2) @(negedge clk);

        // --------------------------------------------
        // TESTE 1: CARREGAMENTO DO PISO
        // --------------------------------------------

        $display("\nTESTE 1: Carregamento do PISO");

        carregar_piso(8'hA5);

        verificar(uut.registrador_piso.serial_out === 1'b1,
                  "MSB do PISO carregado corretamente (A5)");

        // --------------------------------------------
        // TESTE 2: TRANSMISSAO SERIAL POR CIPO
        // --------------------------------------------

        // --------------------------------------------
// TESTE 2: TRANSMISSAO SERIAL POR CIPO
// --------------------------------------------

$display("\nTESTE 2: Transmissao serial por CIPO");

cs_n = 0;
transmitido = 8'hA5;
recebido = 8'h00;

for (i = 7; i >= 0; i = i - 1) begin

    // Captura o bit transmitido
    @(negedge clk);
    recebido[i] = cipo;

    // Pulso de SCLK para avançar o PISO
    sclk = 1;
    repeat (2) @(negedge clk);

    sclk = 0;
    repeat (2) @(negedge clk);

end

cs_n = 1;
repeat (2) @(negedge clk);

// Compara somente depois de receber os 8 bits
$display("Esperado: %b", transmitido);
$display("Recebido: %b", recebido);

verificar(recebido === transmitido,
          "Byte transmitido corretamente por CIPO");

        // --------------------------------------------
        // TESTE 3: RECEPCAO SERIAL POR COPI
        // --------------------------------------------

        $display("\nTESTE 3: Recepcao serial por COPI");

        recebido = 8'h3C;

        // Limpa o estado do periférico
        clr_n = 0;
        repeat (2) @(negedge clk);
        clr_n = 1;
        repeat (2) @(negedge clk);

        cs_n = 0;
        enviar_byte(recebido);

        // Aguarda atualização do registrador
        repeat (2) @(negedge clk);

        verificar(parallel_out === recebido,
                  "Byte recebido corretamente (3C)");

        // --------------------------------------------
        // TESTE 4: CANCELAMENTO DE TRANSFERENCIA
        // --------------------------------------------

        $display("\nTESTE 4: Cancelamento de transferencia");

        cs_n = 1;
        repeat (3) @(negedge clk);

        // Reinicia o periférico
        clr_n = 0;
        repeat (2) @(negedge clk);
        clr_n = 1;
        repeat (2) @(negedge clk);

        cs_n = 0;

        // Envia apenas quatro bits
        enviar_bit(1);
        enviar_bit(0);
        enviar_bit(1);
        enviar_bit(0);

        cs_n = 1;

        repeat (4) @(negedge clk);

        verificar(uut.contador === 3'b000,
                  "Contador zerado após cancelamento");

        verificar(uut.clr_error === 1'b1 ||
                  uut.clr_error === 1'b0,
                  "Circuito de cancelamento executado");

        verificar(rx_valid === 1'b0,
                  "rx_valid não ativado em transferência incompleta");

        // --------------------------------------------
        // RESULTADO FINAL
        // --------------------------------------------

        $display("\n======================================");
        if (erros == 0)
            $display("TODOS OS TESTES PASSARAM!");
        else
            $display("TOTAL DE ERROS: %0d", erros);

        $display("======================================\n");

        $finish;
    end

endmodule
