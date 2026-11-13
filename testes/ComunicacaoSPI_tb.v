
`timescale 1ns/1ps

module ComunicacaoSPI_tb;

    // =================================================
    // SINAIS DE ENTRADA
    // =================================================

    reg clk;
    reg start, peripheral_sel;

    reg clr_controller, clr_p0, clr_p1;

    reg parallel_load_controller;
    reg parallel_load_p0, parallel_load_p1;

    reg [7:0] parallel_in_controller;
    reg [7:0] parallel_in_p0;
    reg [7:0] parallel_in_p1;

    // =================================================
    // SINAIS DE SAIDA
    // =================================================

    wire [7:0] parallel_out_controller;
    wire [7:0] parallel_out_p0;
    wire [7:0] parallel_out_p1;

    wire busy, done;
    wire rx_valid_p0, rx_valid_p1;

    // =================================================
    // SINAIS INTERNOS PARA WAVEFORM
    // =================================================

    wire sclk;
    wire [1:0] cs_n;
    wire copi, cipo;

    assign sclk = uut.sclk;
    assign cs_n = uut.cs_n;
    assign copi = uut.pico;
    assign cipo = uut.cipo;

    // =================================================
    // INSTANCIA DO SISTEMA
    // =================================================

    ComunicacaoSPI uut (
        .clk(clk),
        .start(start),
        .peripheral_sel(peripheral_sel),
        .clr_controller(clr_controller),

        .parallel_load_controller(parallel_load_controller),
        .parallel_in_controller(parallel_in_controller),
        .parallel_out_controller(parallel_out_controller),

        .busy(busy),
        .done(done),

        .clr_p0(clr_p0),
        .parallel_load_p0(parallel_load_p0),
        .parallel_in_p0(parallel_in_p0),
        .parallel_out_p0(parallel_out_p0),
        .rx_valid_p0(rx_valid_p0),

        .clr_p1(clr_p1),
        .parallel_load_p1(parallel_load_p1),
        .parallel_in_p1(parallel_in_p1),
        .parallel_out_p1(parallel_out_p1),
        .rx_valid_p1(rx_valid_p1)
    );

    // =================================================
    // CLOCK: PERIODO DE 20 ns
    // =================================================

    initial clk = 0;
    always #10 clk = ~clk;

    // =================================================
    // CONTADORES E CAPTURA SERIAL
    // =================================================

    integer sclk_edges;
    integer bit_count;
    integer done_count;

    reg [7:0] copi_capturado;
    reg [7:0] cipo_capturado;

    initial begin
        sclk_edges = 0;
        bit_count = 0;
        done_count = 0;

        copi_capturado = 0;
        cipo_capturado = 0;
    end

    // Captura os dados transmitidos na subida do SCLK

    always @(posedge sclk) begin
        if (busy === 1'b1) begin
            sclk_edges = sclk_edges + 1;
            bit_count = bit_count + 1;

            copi_capturado = {copi_capturado[6:0], copi};
            cipo_capturado = {cipo_capturado[6:0], cipo};
        end
    end

    always @(posedge done)
        done_count = done_count + 1;

    // =================================================
    // TAREFA: LIMPAR CAPTURA
    // =================================================

    task limpar_captura;
        begin
            sclk_edges = 0;
            bit_count = 0;

            copi_capturado = 0;
            cipo_capturado = 0;
        end
    endtask

    // =================================================
    // TAREFA: CARREGAR REGISTRADORES PISO
    // =================================================

    task carregar_palavras;

        input [7:0] controlador;
        input [7:0] periferico0;
        input [7:0] periferico1;

        input carregar_p0;
        input carregar_p1;

        begin
            @(negedge clk);

            parallel_in_controller = controlador;
            parallel_in_p0 = periferico0;
            parallel_in_p1 = periferico1;

            parallel_load_controller = 1;
            parallel_load_p0 = carregar_p0;
            parallel_load_p1 = carregar_p1;

            repeat (2) @(posedge clk);

            @(negedge clk);

            parallel_load_controller = 0;
            parallel_load_p0 = 0;
            parallel_load_p1 = 0;

            repeat (2) @(posedge clk);
        end

    endtask

    // =================================================
    // TAREFA: INICIAR TRANSFERENCIA
    // =================================================

    task iniciar_transferencia;
        begin
            @(negedge clk);
            start = 1;

            @(negedge clk);
            start = 0;
        end
    endtask

    // =================================================
    // TAREFA: AGUARDAR DONE
    // =================================================

    task aguardar_done;

        integer timeout;

        begin
            timeout = 0;

            while ((done !== 1'b1) && (timeout < 5000)) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display("ERRO: Timeout aguardando DONE.");
                $fatal;
            end
        end

    endtask

    // =================================================
    // TAREFA: VERIFICAR DADOS PARALELOS
    // =================================================

    task verificar_dados;

        input [7:0] esperado_controller;
        input [7:0] esperado_p0;
        input [7:0] esperado_p1;

        begin

            if (parallel_out_controller !== esperado_controller) begin
                $display("ERRO CONTROLADOR: Esperado %h | Recebido %h",
                         esperado_controller, parallel_out_controller);
                $fatal;
            end

            if (parallel_out_p0 !== esperado_p0) begin
                $display("ERRO PERIFERICO 0: Esperado %h | Recebido %h",
                         esperado_p0, parallel_out_p0);
                $fatal;
            end

            if (parallel_out_p1 !== esperado_p1) begin
                $display("ERRO PERIFERICO 1: Esperado %h | Recebido %h",
                         esperado_p1, parallel_out_p1);
                $fatal;
            end

            $display("PASSOU: CTRL=%h | P0=%h | P1=%h",
                     parallel_out_controller,
                     parallel_out_p0,
                     parallel_out_p1);

        end

    endtask

    // =================================================
    // TAREFA: VERIFICAR TRANSMISSAO SERIAL
    // =================================================

    task verificar_serial;

        input [7:0] esperado_copi;
        input [7:0] esperado_cipo;

        begin

            if (bit_count != 8) begin
                $display("ERRO: Quantidade incorreta de bits.");
                $display("Esperado: 8 | Recebido: %0d", bit_count);
                $fatal;
            end

            if (copi_capturado !== esperado_copi) begin
                $display("ERRO COPI: Esperado %b | Recebido %b",
                         esperado_copi, copi_capturado);
                $fatal;
            end

            if (cipo_capturado !== esperado_cipo) begin
                $display("ERRO CIPO: Esperado %b | Recebido %b",
                         esperado_cipo, cipo_capturado);
                $fatal;
            end

            $display("PASSOU: COPI=%b | CIPO=%b",
                     copi_capturado, cipo_capturado);

        end

    endtask

    // =================================================
    // TAREFA: VERIFICAR SCLK
    // =================================================

    task verificar_clock;

        begin

            if (sclk_edges != 8) begin
                $display("ERRO: Quantidade incorreta de pulsos SCLK.");
                $display("Esperado: 8 | Recebido: %0d", sclk_edges);
                $fatal;
            end

            if (sclk !== 1'b0) begin
                $display("ERRO: SCLK nao terminou em nivel baixo.");
                $fatal;
            end

            $display("PASSOU: 8 pulsos de SCLK.");

        end

    endtask

    // =================================================
    // VARIAVEIS AUXILIARES
    // =================================================

    reg [7:0] p1_anterior;
    reg [7:0] p0_anterior;

    // =================================================
    // INICIO DOS TESTES
    // =================================================

    initial begin

        // Inicializacao

        start = 0;
        peripheral_sel = 0;

        parallel_load_controller = 0;
        parallel_load_p0 = 0;
        parallel_load_p1 = 0;

        parallel_in_controller = 0;
        parallel_in_p0 = 0;
        parallel_in_p1 = 0;

        clr_controller = 0;
        clr_p0 = 0;
        clr_p1 = 0;

        repeat (5) @(posedge clk);

        @(negedge clk);

        clr_controller = 1;
        clr_p0 = 1;
        clr_p1 = 1;

        repeat (5) @(posedge clk);

        $display("\n======================================");
        $display(" INICIANDO TESTES DA COMUNICACAO SPI");
        $display("======================================");


        // =============================================
        // EXPERIMENTO 1 - COMUNICACAO COM P0
        // =============================================

        $display("\nEXPERIMENTO 1 - COMUNICACAO COM P0");

        carregar_palavras(8'hA5, 8'h3C, 8'hA7, 1, 1);

        p1_anterior = parallel_out_p1;

        peripheral_sel = 0;

        limpar_captura;

        iniciar_transferencia;

        @(posedge sclk);
        #1;

        if (cs_n !== 2'b10) begin
            $display("ERRO: P0 nao foi selecionado corretamente.");
            $fatal;
        end

        aguardar_done;

        verificar_dados(8'h3C, 8'hA5, p1_anterior);
        verificar_serial(8'hA5, 8'h3C);
        verificar_clock;

        if (cs_n !== 2'b11) begin
            $display("ERRO: CS nao foi desativado.");
            $fatal;
        end

        $display("EXPERIMENTO 1 CONCLUIDO.");


        // =============================================
        // EXPERIMENTO 2 - COMUNICACAO COM P1
        // =============================================

        $display("\nEXPERIMENTO 2 - COMUNICACAO COM P1");

        // P1 continua com A7 no seu PISO.
        // Apenas o PISO do controlador recebe 5A.

        carregar_palavras(8'h5A, 8'h00, 8'h00, 0, 0);

        peripheral_sel = 1;

        limpar_captura;

        iniciar_transferencia;

        @(posedge sclk);
        #1;

        if (cs_n !== 2'b01) begin
            $display("ERRO: P1 nao foi selecionado corretamente.");
            $fatal;
        end

        aguardar_done;

        verificar_dados(8'hA7, 8'hA5, 8'h5A);
        verificar_serial(8'h5A, 8'hA7);
        verificar_clock;

        $display("EXPERIMENTO 2 CONCLUIDO.");


        // =============================================
        // EXPERIMENTO 3 - TRANSFERENCIA 3
        // =============================================

        $display("\nEXPERIMENTO 3 - TRANSFERENCIA 3");

        carregar_palavras(8'hF0, 8'h96, 8'h00, 1, 0);

        peripheral_sel = 0;

        limpar_captura;

        iniciar_transferencia;

        aguardar_done;

        verificar_dados(8'h96, 8'hF0, 8'h5A);
        verificar_serial(8'hF0, 8'h96);
        verificar_clock;

        $display("TRANSFERENCIA 3 CONCLUIDA.");


        // =============================================
        // EXPERIMENTO 3 - TRANSFERENCIA 4
        // =============================================

        $display("\nEXPERIMENTO 3 - TRANSFERENCIA 4");

        carregar_palavras(8'h0F, 8'h00, 8'h00, 0, 1);

        peripheral_sel = 1;

        limpar_captura;

        iniciar_transferencia;

        aguardar_done;

        verificar_dados(8'h00, 8'hF0, 8'h0F);
        verificar_serial(8'h0F, 8'h00);
        verificar_clock;

        $display("TRANSFERENCIA 4 CONCLUIDA.");


        // =============================================
        // EXPERIMENTO 4A - SISTEMA OCIOSO
        // =============================================

        $display("\nEXPERIMENTO 4A - SISTEMA OCIOSO");

        repeat (20) @(posedge clk);

        if (sclk !== 1'b0 || cs_n !== 2'b11 || busy !== 1'b0) begin
            $display("ERRO: Sistema nao esta ocioso.");
            $fatal;
        end

        $display("PASSOU: SCLK=0, CS=11 e BUSY=0.");


        // =============================================
        // EXPERIMENTO 4B - START DURANTE BUSY
        // =============================================

        $display("\nEXPERIMENTO 4B - NOVO START DURANTE BUSY");

        carregar_palavras(8'hA5, 8'h3C, 8'h00, 1, 0);

        peripheral_sel = 0;

        limpar_captura;
        done_count = 0;

        iniciar_transferencia;

        if (busy !== 1'b1) begin
            $display("ERRO: BUSY nao foi ativado.");
            $fatal;
        end

        // Aguarda tres bordas de subida do SCLK

        repeat (3) @(posedge sclk);

        // Solicita outra transferencia enquanto BUSY=1

        iniciar_transferencia;

        aguardar_done;

        verificar_dados(8'h3C, 8'hA5, 8'h0F);
        verificar_serial(8'hA5, 8'h3C);
        verificar_clock;

        repeat (30) @(posedge clk);

        if (done_count != 1) begin
            $display("ERRO: Solicitação adicional nao foi ignorada.");
            $display("Quantidade de DONE: %0d", done_count);
            $fatal;
        end

        $display("PASSOU: Nova solicitacao foi ignorada.");


        // =============================================
        // EXPERIMENTO 4C - ALTERACAO DA SELECAO
        // =============================================

        $display("\nEXPERIMENTO 4C - ALTERACAO DE SELECAO");

        carregar_palavras(8'hF0, 8'h96, 8'h00, 1, 1);

        peripheral_sel = 0;

        limpar_captura;

        iniciar_transferencia;

        // Aguarda tres bordas de subida do SCLK

        repeat (3) @(posedge sclk);

        #1;

        // Tenta selecionar P1 durante a transferencia

        peripheral_sel = 1;

        if (cs_n !== 2'b10) begin
            $display("ERRO: CS mudou durante a transferencia.");
            $fatal;
        end

        aguardar_done;

        verificar_dados(8'h96, 8'hF0, 8'h0F);
        verificar_serial(8'hF0, 8'h96);
        verificar_clock;

        $display("PASSOU: P0 permaneceu selecionado.");


        // =============================================
        // EXPERIMENTO 4D - INTEGRIDADE DOS DADOS
        // =============================================

        $display("\nEXPERIMENTO 4D - INTEGRIDADE DOS DADOS");

        carregar_palavras(8'hA5, 8'h3C, 8'h00, 1, 0);

        p0_anterior = parallel_out_p0;

        peripheral_sel = 0;

        limpar_captura;

        iniciar_transferencia;

        // Aguarda o recebimento de sete bits

        repeat (7) @(posedge sclk);

        // Permite que a logica sequencial processe as amostras

        repeat (3) @(posedge clk);
        @(negedge clk);

        if (parallel_out_p0 !== p0_anterior) begin
            $display("ERRO: Saida P0 alterada antes do recebimento completo.");
            $fatal;
        end

        $display("PASSOU: Saida P0 permaneceu inalterada apos 7 bits.");

        aguardar_done;

        verificar_dados(8'h3C, 8'hA5, 8'h0F);
        verificar_serial(8'hA5, 8'h3C);
        verificar_clock;


        // =============================================
        // RESULTADO FINAL
        // =============================================

        $display("\n======================================");
        $display(" TODOS OS TESTES FORAM CONCLUIDOS");
        $display("======================================");

        $finish;

    end

endmodule
