`timescale 1ns / 1ps


module dma_tb_top;

	// Inputs
	reg clk;
	reg reset_n;

	wire [13:0] per_addr;
	wire per_en;
	wire [1:0] per_wen;
	wire [15:0] per_din;
	wire dma_ready_p1;
	wire [15:0] dma_dout_p1;
	wire dma_resp_p1;
	wire dma_ready_p2;
	wire [15:0] dma_dout_p2;
	wire dma_resp_p2;

	// Outputs
	wire [15:0] per_dout;
	wire [15:0] dma_addr_p1;
	wire dma_en_p1;
	wire [1:0] dma_wen_p1;
	wire [15:0] dma_din_p1;
	wire [15:0] dma_addr_p2;
	wire dma_en_p2;
	wire [1:0] dma_wen_p2;
	wire [15:0] dma_din_p2;
	wire int_dma;

	// Instantiate the Unit Under Test (UUT)
	dma_top uut (
		.clk(clk), 
		.reset_n(reset_n),
		
		.per_addr(per_addr), 
		.per_en(per_en), 
		.per_wen(per_wen), 
		.per_din(per_din), 
		.per_dout(per_dout), 

		.dma_addr_p1(dma_addr_p1), 
		.dma_en_p1(dma_en_p1), 
		.dma_wen_p1(dma_wen_p1), 
		.dma_din_p1(dma_din_p1), 
		.dma_ready_p1(dma_ready_p1), 
		.dma_dout_p1(dma_dout_p1), 
		.dma_resp_p1(dma_resp_p1), 
		
		.dma_addr_p2(dma_addr_p2), 
		.dma_en_p2(dma_en_p2), 
		.dma_wen_p2(dma_wen_p2), 
		.dma_din_p2(dma_din_p2), 
		.dma_ready_p2(dma_ready_p2), 
		.dma_dout_p2(dma_dout_p2), 
		.dma_resp_p2(dma_resp_p2), 
		.int_dma(int_dma)
	);

    always #25 clk = ~clk;  // 20Mhz clock source

	initial 
    begin
		// Initialize Inputs
		clk             =   1'b0;
		reset_n         =   1'b0;

        // wait for 200ns and Release reset
		#100;
        reset_n         =   1'b1;
	end


    dma_ahb_slave   slave0(
        .clk(clk),
        .reset_n(reset_n),
        .ahb_slave_addr(dma_addr_p1),
        .ahb_slave_en(dma_en_p1),
        .ahb_slave_wen(dma_wen_p1),
        .ahb_slave_din(dma_din_p1),
        .ahb_slave_ready(dma_ready_p1),
        .ahb_slave_dout(dma_dout_p1),
        .ahb_slave_resp(dma_resp_p1));

    dma_ahb_slave   slave1(
        .clk(clk),
        .reset_n(reset_n),
        .ahb_slave_addr(dma_addr_p2),
        .ahb_slave_en(dma_en_p2),
        .ahb_slave_wen(dma_wen_p2),
        .ahb_slave_din(dma_din_p2),
        .ahb_slave_ready(dma_ready_p2),
        .ahb_slave_dout(dma_dout_p2),
        .ahb_slave_resp(dma_resp_p2));

    dma_test_program    test(
        .clk(clk),
        .reset_n(reset_n),
        .per_addr(per_addr),
        .per_en(per_en),
        .per_wen(per_wen),
        .per_din(per_din),
        .per_dout(per_dout));
      
endmodule

