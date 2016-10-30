// sample Test program to verify the DMA controller.
// Developed by Sai Marri


module dma_test_program(
                        clk,
                        reset_n,
                        per_addr,
                        per_en,
                        per_wen,
                        per_din,
                        per_dout);


input               clk;
input               reset_n;

output  reg [13:0]      per_addr;
output  reg             per_en;
output  reg [1:0]       per_wen;
output  reg [15:0]      per_din;
input       [15:0]      per_dout;

 
initial   
begin
    per_addr    =   14'h0;
    per_en      =   1'b0;
    per_wen     =   2'b00;
    per_din     =   16'h0;
    wait(reset_n    ==   1'b1);
    #100;
    @(posedge clk);
    per_addr    =   14'h2008;
    per_en      =   1'b1;
    per_wen     =   2'b11;
    per_din     =   16'h020;   

    @(posedge clk);
    per_addr    =   14'h2000;
    per_en      =   1'b1;
    per_wen     =   2'b11;
    per_din     =   16'h4;   

    @(posedge clk);
    per_addr    =   14'h0;
    per_en      =   1'b0;
    per_wen     =   2'b00;
    per_din     =   16'h0;   
   #20000; 
    $finish;
end

endmodule
