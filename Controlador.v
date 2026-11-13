module Controlador #(parameter integer DIV = 10)
						  (input wire 		   clk, clr_n, cipo, parallel_load, 
						   input wire        start, peripheral_sel,
						   input wire  [7:0] parallel_in,
						   output wire [7:0] parallel_out,
							output wire       pico,
							output reg  [1:0] cs_n,
						   output reg  		busy, done, sclk
						   );
							
	localparam [1:0] IDLE 	  = 2'h0;
	localparam [1:0] SETUP 	  = 2'h1;
	localparam [1:0] TRANSFER = 2'h2;
	localparam [1:0] DONE 	  = 2'h3;
						
	reg 		  flag_sclk, flag_sclk_inicio, last_bit, shift, load, sample, clr_error;
	reg        enable_contador;
	reg  [7:0] contador_sclk;
	reg  [2:0] contador;
	reg  [1:0] estado;
	wire 		  clr_sipo;
	
	RegistradorSIPO registrador_sipo(.clk(clk), .clr_n(clr_sipo), .sample(sample), 
												.last_bit(last_bit), .serial_in(cipo), 
												.parallel_out(parallel_out), .valid(rx_valid));
												
	RegistradorPISO registrador_piso(.clk(clk), .clr_n(clr_n), .load(load),
												.shift(shift), .parallel_in(parallel_in), 
												.serial_out(pico));
	
	assign clr_sipo = clr_n || clr_error;
	
	initial begin
		flag_sclk 		 <= 0;
		contador  		 <= 0;
		contador_sclk   <= 0;
		enable_contador <= 0;
		last_bit  		 <= 0;
		shift     		 <= 0;
		sample    		 <= 0;
		clr_error 		 <= 0;
		cs_n            <= 2'b11;
		estado    		 <= IDLE;
	end
	
	//Divisor de SCLK
	
	always @(posedge clk) begin
		if (enable_contador) begin
			if (contador_sclk == (DIV - 1)) begin
				contador_sclk <= 0;
				if (sclk) begin
					sclk <= 0;
				end
				else begin
					sclk <= 1;
				end
			end
			else begin
				contador_sclk <= contador_sclk + 1;
			end
		end
		else begin
			contador_sclk <= 0;
			sclk 		     <= 0;
		end
	end
	
	// Maquina de estados
	
	always @(posedge clk) begin
		if (estado == IDLE) begin
			busy 		 <= 0;
			done		 <= 0;
			if (start) begin
				estado <= SETUP;
				busy <= 1;
			end
		end
		
		if (estado == SETUP) begin
			if (peripheral_sel) begin
				cs_n = 2'b01;
			end
			else begin
				cs_n = 2'b10;
			end
			flag_sclk_inicio <= 1;
			enable_contador <= 1;
			estado <= TRANSFER;
		end
		
		if (estado == TRANSFER) begin
			if (last_bit) begin
				estado <= DONE;
				enable_contador <= 0;
				flag_sclk_inicio <= 0;
			end
		end

		if (estado == DONE) begin
			done 		 <= 1'h1;
			estado 	 <= IDLE;
			cs_n      <= 2'b11;
		end
		
	end
	
	//Logica dos registradores
	
	always @(posedge clk) begin
		if (enable_contador) begin
			if (sclk) begin
				if (flag_sclk == 0) begin
					flag_sclk  <= 1;
					
					sample <= 1'h1;
				end
				else begin
					sample <= 1'h0;
				end
			end
			else begin
				if (flag_sclk == 1) begin
					contador = contador + 1;
					if (contador == 0) begin
						last_bit <= 1'h1;
					end
					else begin
						last_bit <= 1'h0;
					end
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
			
			last_bit <= 0;
		
			if (parallel_load) begin
				load <= 1'h1;
			end
			else begin
				load <= 1'h0;
			end
			if (contador != 0) begin
				clr_error <= 1'h1;
				contador  <= 3'h0;
			end 
			else begin
				clr_error <= 1'h0;
			end
		end
	end
endmodule