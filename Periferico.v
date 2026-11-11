module Periferico(input wire 		   clk, clr_n, sclk, cs_n, pico, parallel_load,
						input wire  [7:0] parallel_in,
						output wire [7:0] parallel_out,
						output wire 		rx_valid, cipo
						);
						
	reg 		  flag_sclk, last_bit, shift, load, sample, clr_error;
	reg  [2:0] contador;
	
	wire 		  clr_sipo, cipo_reg;
	
	RegistradorSIPO registrador_sipo(.clk(clk), .clr_n(clr_sipo), .sample(sample), 
												.last_bit(last_bit), .serial_in(pico), 
												.parallel_out(parallel_out), .valid(rx_valid));
												
	RegistradorPISO registrador_piso(.clk(clk), .clr_n(clr_n), .load(load),
												.shift(shift), .parallel_in(parallel_in), 
												.serial_out(cipo_reg));
												
	assign cipo     = cs_n ? 1'hz : cipo_reg;
	assign clr_sipo = clr_n || clr_error;
	
	initial begin
		flag_sclk <= 0;
		contador  <= 0;
		last_bit  <= 0;
		shift     <= 0;
		sample    <= 0;
		clr_error <= 0;
	end
	
	always @(posedge clk) begin
		if(cs_n == 0) begin
			if (sclk) begin
				if (flag_sclk == 0) begin
					flag_sclk  <= 1;
					contador   <= contador + 1;
					if (contador == 7) begin
						last_bit <= 1'h1;
					end
					else begin
						last_bit <= 1'h0;
					end
					sample <= 1'h1;
				end
				else begin
					sample <= 1'h0;
				end
			end
			else begin
				if (flag_sclk == 1) begin
					flag_sclk <= 0;
					if (contador != 0) begin
						shift <= 1;
					end
				end
				else begin
					shift <= 0;
				end
			end
		end
		else begin
			if (parallel_load) begin
				load <= 1'h1;
			end
			else begin
				load <= 1'h0;
			end
			if (contador != 0) begin
				clr_error <= 1'h1;
				contador <= 3'h0;
			end 
			else begin
				clr_error <= 1'h0;
			end
		end
	end
endmodule