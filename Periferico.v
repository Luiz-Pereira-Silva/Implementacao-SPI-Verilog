module Periferico(input wire sclk, serial_in, chip_select, output reg serial_out, output reg[7:0] registrador_in, registrador_out);
	RegistradorIN modulo_registrador_in(.clock(sclk), .serial_in(serial_in), .registrador_out(registrador_in));
	RegistradorOUT modulo_registrador_out(.clock(sclk), .serial_out(serial_out), .registrador_out(registrador_out));
endmodule

module RegistradorOUT(input wire clock, output reg serial_out, output reg[7:0] registrador_out);
	reg [7:0] registrador;
	
	always @(posedge clock, negedge clear) begin
		serial_out <= registrador[7];
		registrador <= {registrador[6:0], 1'h0};
		registrador_out <= registrador;
	end
endmodule

module RegistradorIN(input wire clock, serial_in, clear, output reg[7:0] registrador_out);
	reg [7:0] registrador;
	
	always @(posedge clock, negedge clear) begin
		registrador <= {serial_in, registrador[7:1]};
		registrador_out <= registrador;
	end
endmodule