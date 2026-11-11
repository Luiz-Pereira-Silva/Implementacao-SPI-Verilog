module spi_controller #(parameter integer DIV = 10)
							  (input wire        clk, clr_n, parallel_load, start, peripheral_sel, cipo,
							   input wire  [7:0] parallel_in,
								output wire       sclk, copi, busy, done,
								output wire [7:0] parallel_out,
								output wire [1:0] cs_n
								);
	
	reg 		  flag_sclk, last_bit, shift, load, sample, clr_error, peripheral_set;
	reg  [7:0] contador;
	
	wire 		  clr_sipo, cipo_reg;
	
	RegistradorSIPO registrador_sipo(.clk(clk), .clr_n(clr_sipo), .sample(sample), 
												.last_bit(last_bit), .serial_in(pico), 
												.parallel_out(parallel_out), .valid(rx_valid));
												
	RegistradorPISO registrador_piso(.clk(clk), .clr_n(clr_n), .load(load),
												.shift(shift), .parallel_in(parallel_in), 
												.serial_out(cipo_reg));
												
	assign cipo = cs_n ? 1'hz : cipo_reg;
	assign clr_sipo = clr_n || clr_error;
	
	assign cs_n = peripheral_sel;
	
	initial begin
		flag_sclk <= 0;
		contador  <= 0;
		last_bit  <= 0;
		shift     <= 0;
		sample    <= 0;
		clr_error <= 0;
		sclk      <= 0;
	end
	
	always @(posedge clk) begin
		if (contador == (DIV -1)) begin
			contador <= 0;
			sclk <= ~sclk;
		end
		else begin
			contador <= 0;
		end
	end
	
	always @(posedge clk) begin
		
	end
	
endmodule