module ComunicacaoSPI (input wire clk, 

							  input wire 		  start, peripheral_sel, clr_controller, 
							  input wire 		  parallel_load_controller,
							  input wire  [7:0] parallel_in_controller, 
							  output wire [7:0] parallel_out_controller, 
							  output wire 		  busy, done,
							  
							  input wire        clr_p0, parallel_load_p0,
							  input wire  [7:0] parallel_in_p0,
							  output wire       rx_valid_p0, 
							  output wire [7:0] parallel_out_p0,
							  
							  input wire        clr_p1, parallel_load_p1,
							  input wire  [7:0] parallel_in_p1,
							  output wire       rx_valid_p1, 
							  output wire [7:0] parallel_out_p1
							  );
	
	wire cipo, cipo_p0, cipo_p1, pico, sclk;
	wire [1:0] cs_n;
	
	assign cipo = cs_n[0] ? (cs_n[1] ? 1'b0 : cipo_p1) : cipo_p0;
	
	Controlador #(.DIV(10)) controlador (.clk(clk), .clr_n(clr_controller), .cipo(cipo),
													 .start(start), .peripheral_sel(peripheral_sel),
													 .parallel_load(parallel_load_controller),
													 .parallel_in(parallel_in_controller),
													 .parallel_out(parallel_out_controller),
													 .pico(pico), .cs_n(cs_n), .busy(busy), 
													 .done(done), .sclk(sclk)
													 );
									  
	Periferico periferico_p0 (.clk(clk), .sclk(sclk), .clr_n(clr_p0), 
									  .cs_n(cs_n[0]), .pico(pico),
									  .parallel_load(parallel_load_p0),
									  .parallel_in(parallel_in_p0),
									  .parallel_out(parallel_out_p0),
									  .rx_valid(rx_valid_p0), .cipo(cipo_p0)
									  );
									 
	Periferico periferico_p1 (.clk(clk), .sclk(sclk), .clr_n(clr_p1), 
									  .cs_n(cs_n[1]), .pico(pico),
									  .parallel_load(parallel_load_p1),
									  .parallel_in(parallel_in_p1),
									  .parallel_out(parallel_out_p1),
									  .rx_valid(rx_valid_p1), .cipo(cipo_p1));
	
endmodule