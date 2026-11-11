
`timescale 1ns/1ps

module Periferico_tb;

    reg clk;
    reg clr_n;
    reg parallel_load;
    reg [7:0] parallel_in;

    wire [7:0] parallel_out;
    wire rx_valid;

    reg sclk;
    reg cs_n;
    reg copi;
    wire cipo;

    integer rx_valid_count;
    integer i;

    // DUT
    Periferico uut (
        .clk(clk),
        .clr_n(clr_n),
        .parallel_load(parallel_load),
        .parallel_in(parallel_in),
        .parallel_out(parallel_out),
        .rx_valid(rx_valid),
        .sclk(sclk),
        .cs_n(cs_n),
        .pico(copi),
        .cipo(cipo)
    );

    // Clock principal: período de 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Contador de pulsos de recepção concluída
    initial rx_valid_count = 0;

    always @(posedge clk) begin
        if (!clr_n)
            rx_valid_count = 0;
        else if (rx_valid)
            rx_valid_count = rx_valid_count + 1;
    end

    // --------------------------------------------------
    // Carrega uma palavra no PISO enquanto cs_n = 1
    // --------------------------------------------------

    task load_word;
        input [7:0] data;
        begin
            @(negedge clk);
            parallel_in = data;
            parallel_load = 1;

            repeat (4) @(posedge clk);

            @(negedge clk);
            parallel_load = 0;

            repeat (4) @(posedge clk);
        end
    endtask

    // --------------------------------------------------
    // Envia um bit e verifica o bit transmitido
    // Usado nos testes de transferência incompleta
    // --------------------------------------------------

    task send_partial_bit;
        input tx_expected;
        input rx_bit;
        begin
            @(negedge clk);
            copi = rx_bit;

            repeat (6) @(posedge clk);

            if (cipo !== tx_expected) begin
                $display("ERRO: CIPO esperado = %b, recebido = %b",
                         tx_expected, cipo);
                $fatal;
            end

            @(negedge clk);
            sclk = 1;

            repeat (6) @(posedge clk);

            @(negedge clk);
            sclk = 0;

            repeat (6) @(posedge clk);
        end
    endtask

    // --------------------------------------------------
    // Transferência completa de 8 bits
    // Verifica transmissão, recepção e rx_valid
    // --------------------------------------------------

    task full_transfer;
        input [7:0] tx_data;
        input [7:0] rx_data;

        begin
            @(negedge clk);
            cs_n = 0;

            repeat (6) @(posedge clk);

            for (i = 7; i >= 0; i = i - 1) begin

                // Configura o bit a ser recebido
                @(negedge clk);
                copi = rx_data[i];

                repeat (6) @(posedge clk);

                // Verifica o bit transmitido
                if (cipo !== tx_data[i]) begin
                    $display("ERRO na transmissão do bit %0d", i);
                    $display("Esperado: %b | Recebido: %b",
                             tx_data[i], cipo);
                    $fatal;
                end

                // Borda de subida: amostragem do COPI
                @(negedge clk);
                sclk = 1;

                repeat (6) @(posedge clk);

                // Deslocamento na borda de descida,
                // exceto após o oitavo bit
                if (i > 0) begin
                    @(negedge clk);
                    sclk = 0;

                    repeat (6) @(posedge clk);
                end
            end

            // Aguarda a atualização dos sinais de recepção
            repeat (6) @(posedge clk);

            // Verifica a palavra recebida
            if (parallel_out !== rx_data) begin
                $display("ERRO na recepção!");
                $display("Esperado: %h | Recebido: %h",
                         rx_data, parallel_out);
                $fatal;
            end

            // Verifica rx_valid
            if (rx_valid_count != 1) begin
                $display("ERRO: quantidade incorreta de pulsos rx_valid.");
                $display("Esperado: 1 | Recebido: %0d",
                         rx_valid_count);
                $fatal;
            end

            // Finaliza a seleção
            @(negedge clk);
            cs_n = 1;
            sclk = 0;

            repeat (6) @(posedge clk);

            $display("Transferência concluída!");
            $display("TX: %h | RX: %h", tx_data, parallel_out);
        end
    endtask

    // --------------------------------------------------
    // Testbench principal
    // --------------------------------------------------

    initial begin

        // Inicialização
        clk = 0;
        clr_n = 0;
        parallel_load = 0;
        parallel_in = 0;
        sclk = 0;
        cs_n = 1;
        copi = 0;

        repeat (5) @(posedge clk);

        @(negedge clk);
        clr_n = 1;

        repeat (5) @(posedge clk);

        $display("----------------------------------");
        $display(" INICIANDO TESTES DO SPI PERIPHERAL");
        $display("----------------------------------");

        // ==============================================
        // TESTE 1: Carga paralela e transferência completa
        // ==============================================

        $display("\nTESTE 1: Transferência completa");

        load_word(8'hA5);

        full_transfer(
            8'hA5,  // Palavra transmitida
            8'h3C   // Palavra recebida
        );

        // ==============================================
        // TESTE 2: Cancelamento de transferência
        // ==============================================

        $display("\nTESTE 2: Cancelamento de transferência");

        load_word(8'h96);

        @(negedge clk);
        cs_n = 0;

        repeat (6) @(posedge clk);

        // Transmite e recebe apenas 3 bits
        send_partial_bit(1'b1, 1'b1);
        send_partial_bit(1'b0, 1'b0);
        send_partial_bit(1'b0, 1'b1);

        // Interrompe a transferência
        @(negedge clk);
        cs_n = 1;

        repeat (6) @(posedge clk);

        // A palavra anterior deve ser preservada
        if (parallel_out !== 8'h3C) begin
            $display("ERRO: palavra parcial alterou parallel_out!");
            $fatal;
        end

        // Não pode gerar rx_valid
        if (rx_valid_count != 1) begin
            $display("ERRO: rx_valid foi gerado indevidamente!");
            $fatal;
        end

        $display("Transferência parcial descartada corretamente.");

        // ==============================================
        // TESTE 3: SCLK deve ser ignorado com cs_n = 1
        // ==============================================

        $display("\nTESTE 3: Periférico deselecionado");

        repeat (3) begin
            @(negedge clk);
            sclk = 1;
            copi = ~copi;

            repeat (6) @(posedge clk);

            @(negedge clk);
            sclk = 0;

            repeat (6) @(posedge clk);
        end

        if (parallel_out !== 8'h3C) begin
            $display("ERRO: parallel_out foi alterado com cs_n = 1!");
            $fatal;
        end

        if (rx_valid_count != 1) begin
            $display("ERRO: recepção ocorreu com periférico deselecionado!");
            $fatal;
        end

        $display("SCLK ignorado corretamente.");

        // ==============================================
        // TESTE 4: Nova transferência após cancelamento
        // ==============================================

        $display("\nTESTE 4: Reinicialização da contagem de bits");

        load_word(8'h96);

        // A contagem deve reiniciar e permitir 8 novos bits
        rx_valid_count = 0;

        full_transfer(
            8'h96,  // Palavra transmitida
            8'h5A   // Palavra recebida
        );

        // ==============================================
        // RESULTADO FINAL
        // ==============================================

        $display("\n----------------------------------");
        $display(" TODOS OS TESTES FORAM CONCLUIDOS!");
        $display("----------------------------------");

        $finish;
    end

endmodule
