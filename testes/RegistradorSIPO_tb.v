
`timescale 1ns/1ps

module RegistradorSIPO_tb;

    reg clk;
    reg clr_n;
    reg sample;
    reg last_bit;
    reg serial_in;

    wire [7:0] parallel_out;
    wire valid;

    RegistradorSIPO uut (
        .clk(clk),
        .clr_n(clr_n),
        .sample(sample),
        .last_bit(last_bit),
        .serial_in(serial_in),
        .parallel_out(parallel_out),
        .valid(valid)
    );

    // Clock com período de 2 ns
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    initial begin

        // Inicialização
        clr_n = 0;
        sample = 0;
        last_bit = 0;
        serial_in = 0;

        // Clear
        #1;
        clr_n = 1;

        // Recepção do byte 10110101
        @(negedge clk);
        sample = 1;

        serial_in = 1;
        @(negedge clk);

        serial_in = 0;
        @(negedge clk);

        serial_in = 1;
        @(negedge clk);

        serial_in = 1;
        @(negedge clk);

        serial_in = 0;
        @(negedge clk);

        serial_in = 1;
        @(negedge clk);

        serial_in = 0;
        @(negedge clk);

        serial_in = 1;
        last_bit = 1;

        @(negedge clk);
        last_bit = 0;
        sample = 0;

        // Período sem amostragem
        repeat (2) @(negedge clk);

        // Recepção do byte 11001010
        sample = 1;

        serial_in = 1;
        @(negedge clk);

        serial_in = 1;
        @(negedge clk);

        serial_in = 0;
        @(negedge clk);

        serial_in = 0;
        @(negedge clk);

        serial_in = 1;
        @(negedge clk);

        serial_in = 0;
        @(negedge clk);

        serial_in = 1;
        @(negedge clk);

        serial_in = 0;
        last_bit = 1;

        @(negedge clk);
        last_bit = 0;
        sample = 0;

        // Teste de clear durante operação
        #0.5;
        clr_n = 0;

        #1;
        clr_n = 1;

        #3;
        $finish;
    end

endmodule
