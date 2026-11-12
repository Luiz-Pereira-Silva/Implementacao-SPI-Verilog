module RegistradorSIPO (input wire 		  clk, clr_n, sample, last_bit, serial_in, 
								output reg [7:0] parallel_out, 
								output reg       valid);
	reg [7:0] registrador;
	reg flag_valid;
	
	initial begin
		parallel_out  <= 8'h0;
		flag_valid    <= 1'h0;
		valid         <= 1'h0;
	end
	
	always @(posedge clk or negedge clr_n) begin
		if (clr_n == 0) begin
			registrador <= 8'h0;
		end
		else begin
			if (sample) begin
				registrador = {registrador[6:0], serial_in};
				if (last_bit) begin
					if (flag_valid == 0) begin
						valid      <= 1'h1;
					end
					parallel_out <= registrador;
				end
				else begin
					valid <= 1'h0;
				end
			end
			
			if (valid) begin
				valid <= 0;
			end
		end
	end
endmodule