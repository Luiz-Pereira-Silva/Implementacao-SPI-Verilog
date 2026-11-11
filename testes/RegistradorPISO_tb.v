`timescale 1ns/1ps

module RegistradorPISO_tb;

    reg clk;
    reg clr_n;
    reg load;
    reg shift;
    reg serial_in;
    reg [7:0] parallel_in;

    wire serial_out;

    RegistradorPISO uut (
        .clk(clk),
        .clr_n(clr_n),
        .load(load),
        .shift(shift),
        .parallel_in(parallel_in),
        .serial_out(serial_out)
    );

    // Clock com período de 2 ns
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    initial begin

        // Estado inicial
        clr_n = 0;
        load = 0;
        shift = 0;
        parallel_in = 8'h00;

        // Teste de clear assíncrono
        #1;
        clr_n = 1;

        // Carregamento paralelo
        @(negedge clk);
        parallel_in = 8'hA5;
        load = 1;

        @(negedge clk);
        load = 0;

        // Deslocamento serial
        repeat (8) begin
            @(negedge clk);
            shift = 1;
        end

        @(negedge clk);
        shift = 0;

        // Novo carregamento
        parallel_in = 8'b11001010;
        load = 1;

        @(negedge clk);
        load = 0;

        // Teste de prioridade do load sobre shift
        shift = 1;
        parallel_in = 8'b11110000;
        load = 1;

        @(negedge clk);
        load = 0;

        // Teste de clear durante operação
        #0.5;
        clr_n = 0;

        #1;
        clr_n = 1;

        @(negedge clk);
        shift = 0;

        #4;
        $finish;
    end

endmodule
