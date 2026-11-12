`timescale 1ns/1ps

module Controlador_tb;

    // =========================================================
    // Sinais de entrada do controlador
    // =========================================================

    reg clk;
    reg clr_n;
    reg cipo;
    reg parallel_load;

    reg start;
    reg peripheral_sel;

    reg [7:0] parallel_in;


    // =========================================================
    // Sinais de saída do controlador
    // =========================================================

    wire [7:0] parallel_out;
    wire [1:0] cs_n;

    wire pico;
    wire sclk;
    wire busy;
    wire done;


    // =========================================================
    // Instância do controlador
    // DIV pequeno para acelerar a simulação
    // =========================================================

    Controlador #(
        .DIV(2)
    ) uut (

        .clk(clk),
        .clr_n(clr_n),
        .cipo(cipo),
        .parallel_load(parallel_load),

        .start(start),
        .peripheral_sel(peripheral_sel),

        .parallel_in(parallel_in),

        .parallel_out(parallel_out),
        .cs_n(cs_n),

        .pico(pico),
        .sclk(sclk),
        .busy(busy),
        .done(done)
    );


    // =========================================================
    // Clock principal
    // Período = 10 ns
    // =========================================================

    initial begin

        clk = 0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // Simulação do periférico
    //
    // CIPO muda na borda de descida para estar estável
    // antes da próxima borda de subida.
    // =========================================================

    reg [7:0] dados_cipo;
    integer indice_cipo;

    initial begin

        dados_cipo = 8'b1010_1100;
        indice_cipo = 7;

    end


    always @(negedge sclk) begin

        if (busy) begin

            cipo <= dados_cipo[indice_cipo];

            if (indice_cipo > 0)
                indice_cipo <= indice_cipo - 1;

        end

    end


    // =========================================================
    // Contadores para verificar os requisitos
    // =========================================================

    integer subidas_sclk;
    integer descidas_sclk;

    initial begin

        subidas_sclk  = 0;
        descidas_sclk = 0;

    end


    always @(posedge sclk) begin

        if (busy)
            subidas_sclk = subidas_sclk + 1;

    end


    always @(negedge sclk) begin

        if (busy)
            descidas_sclk = descidas_sclk + 1;

    end


    // =========================================================
    // Testes
    // =========================================================

    initial begin

        // Valores iniciais

        clr_n = 0;

        cipo = 0;

        parallel_load = 0;

        start = 0;

        peripheral_sel = 0;

        parallel_in = 8'b1100_1010;


        // =====================================================
        // TESTE 1
        // Reset
        // =====================================================

        #20;

        clr_n = 1;

        #10;

        if (cs_n !== 2'b11)
            $display("ERRO: CS deveria estar desativado no estado IDLE");
        else
            $display("OK: IDLE com ambos os perifericos desativados");


        if (busy !== 0)
            $display("ERRO: busy deveria ser 0 no estado IDLE");
        else
            $display("OK: busy = 0 no estado IDLE");


        if (sclk !== 0)
            $display("ERRO: SCLK deveria iniciar em 0");
        else
            $display("OK: SCLK = 0 no estado IDLE");


        // =====================================================
        // TESTE 2
        // Carregamento dos dados
        // =====================================================

        @(posedge clk);

        parallel_load = 1;

        @(posedge clk);

        parallel_load = 0;


        $display("");
        $display("==========================================");
        $display("INICIANDO TRANSFERENCIA");
        $display("==========================================");


        // =====================================================
        // TESTE 3
        // Selecionar periférico 0
        //
        // peripheral_sel = 0
        // cs_n esperado = 2'b10
        // =====================================================

        peripheral_sel = 0;

        @(posedge clk);

        start = 1;

        @(posedge clk);

        start = 0;


        // Aguarda o controlador sair de IDLE

        wait(busy == 1);

        #1;


        if (cs_n !== 2'b10)
            $display("ERRO: Periferico 0 deveria gerar CS = 10");
        else
            $display("OK: Periferico 0 selecionado corretamente");


        // =====================================================
        // TESTE 4
        // Alterar peripheral_sel durante a transferência
        //
        // O CS NÃO pode mudar
        // =====================================================

        peripheral_sel = 1;

        #20;


        if (cs_n !== 2'b10)
            $display("ERRO: CS mudou durante a transferencia!");
        else
            $display("OK: Periferico permaneceu selecionado");


        // =====================================================
        // TESTE 5
        // Novo start durante transferência
        //
        // Não deve reiniciar/interromper a operação
        // =====================================================

        @(posedge clk);

        start = 1;

        @(posedge clk);

        start = 0;

        $display("OK: Start adicional enviado durante transferencia");


        // =====================================================
        // Aguarda final da transferência
        // =====================================================

        wait(done == 1);

        #1;


        // =====================================================
        // TESTE 6
        // Verificar quantidade de ciclos de SCLK
        // =====================================================

        if (subidas_sclk == 8)
            $display("OK: Foram geradas 8 bordas de subida");
        else
            $display("ERRO: Esperado 8 bordas de subida. Obtido: %0d",
                     subidas_sclk);


        // =====================================================
        // TESTE 7
        // Estado DONE
        // =====================================================

        if (sclk !== 0)
            $display("ERRO: SCLK deveria estar em 0 no final");
        else
            $display("OK: SCLK retornou para 0");


        if (cs_n !== 2'b11)
            $display("ERRO: CS deveria ser desativado no final");
        else
            $display("OK: CS desativado no final");


        // =====================================================
        // Aguarda retorno ao IDLE
        // =====================================================

        @(posedge clk);

        #10;


        if (busy !== 0)
            $display("ERRO: busy deveria retornar para 0");
        else
            $display("OK: busy retornou para 0");


        // =====================================================
        // TESTE 8
        // Verificar dados recebidos
        // =====================================================

        $display("");
        $display("==========================================");
        $display("DADOS RECEBIDOS");
        $display("Esperado: %b", dados_cipo);
        $display("Obtido:   %b", parallel_out);
        $display("==========================================");


        if (parallel_out === dados_cipo)
            $display("OK: Dados recebidos corretamente");
        else
            $display("ERRO: Dados recebidos incorretamente");


        // =====================================================
        // TESTE 9
        // Nova transferência com periférico 1
        // =====================================================

        $display("");
        $display("==========================================");
        $display("TESTANDO PERIFERICO 1");
        $display("==========================================");


        subidas_sclk  = 0;
        descidas_sclk = 0;


        parallel_in = 8'b1111_0000;

        peripheral_sel = 1;

        indice_cipo = 7;


        @(posedge clk);

        parallel_load = 1;

        @(posedge clk);

        parallel_load = 0;


        @(posedge clk);

        start = 1;

        @(posedge clk);

        start = 0;


        wait(busy == 1);

        #1;


        if (cs_n === 2'b01)
            $display("OK: Periferico 1 selecionado corretamente");
        else
            $display("ERRO: Periferico 1 deveria gerar CS = 01");


        wait(done == 1);

        #10;


        if (subidas_sclk == 8)
            $display("OK: Segunda transferencia teve 8 ciclos");
        else
            $display("ERRO: Numero incorreto de ciclos");


        // =====================================================
        // Fim da simulação
        // =====================================================

        $display("");
        $display("==========================================");
        $display("FIM DOS TESTES");
        $display("==========================================");

        $stop;

    end


endmodule