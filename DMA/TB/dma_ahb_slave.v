// DMA AHB slave testbench
// Developed by Sai Marri


module dma_ahb_slave(
                        clk,
                        reset_n,
                        ahb_slave_addr,
                        ahb_slave_en,
                        ahb_slave_wen,
                        ahb_slave_din,
                        ahb_slave_ready,
                        ahb_slave_dout,
                        ahb_slave_resp);



input           clk;
input           reset_n;

input  [15:0]   ahb_slave_addr;
input           ahb_slave_en;
input  [1:0]    ahb_slave_wen;
input  [15:0]   ahb_slave_din;

output          ahb_slave_ready;
output          ahb_slave_resp;
output [15:0]   ahb_slave_dout;


assign      ahb_slave_resp  =   1'b0;
assign      ahb_slave_ready =   1'b1;

                        
ram_8x512   mem_msb (
    .addra        (ahb_slave_addr[8:0]),
    .clka         (clk),
    .dina         (ahb_slave_din[15:8]),
    .douta        (ahb_slave_dout[15:8]),
    .ena          (ahb_slave_en),
    .wea          (ahb_slave_wen[1])
);
ram_8x512  mem_lsb (
    .addra        (ahb_slave_addr[8:0]),
    .clka         (clk),
    .dina         (ahb_slave_din[7:0]),
    .douta        (ahb_slave_dout[7:0]),
    .ena          (ahb_slave_en),
    .wea          (ahb_slave_wen[0])
);

endmodule
