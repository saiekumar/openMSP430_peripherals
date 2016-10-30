// Sai Marri :: DMA Registers
// Simple DMA controller for the OpenMSP430 IP core


module dma_registers(
        clk,
        reset_n,
        per_addr,
        per_en,
        per_wen,
        per_din,
        per_dout,
        int_gen,
        dma_busy,
        int_enabled,
        direction_bit,
        dma_trans_start,
        dma_p1_start_addr,
        dma_p2_start_addr,
        dma_transfer_len,
        clear_int);

parameter   DMA_CSR         =   8'h00;
//  BIT[0]      :   0 - INT_DISABLED        : 1 - INT_ENABLED
//  BIT[1]      :   0 - port1 -> port2      : 1 - port2 -> port1
//  BIT[2]      :   1 - DMA Start
parameter   DMA_STATUS      =   8'h02;
//  BIT[0]      :   1 - INT_Generated
//  BIT[1]      :   0 - DMA Idle      : 1 - DMA Busy
parameter   DMA_P1_SADDR    =   8'h04;
parameter   DMA_P2_SADDR    =   8'h06;
parameter   DMA_TRANS_LEN   =   8'h08;

parameter   DMA_BASE_ADDR   =   6'h20;

input               clk;
input               reset_n;
input       [13:0]  per_addr;
input               per_en;
input       [1:0]   per_wen;
input       [15:0]  per_din;
output reg  [15:0]  per_dout;

input               int_gen;
input               dma_busy;

output              int_enabled;
output              direction_bit;
output              dma_trans_start;

output reg  [15:0]  dma_p1_start_addr;
output reg  [15:0]  dma_p2_start_addr;
output reg  [15:0]  dma_transfer_len;
output reg          clear_int;

reg     [2:0]   dma_ctrl;


always @(posedge clk or negedge reset_n)
begin
    if(reset_n == 1'b0)
    begin
        dma_transfer_len    =   16'h00;
        dma_p1_start_addr   =   16'h00;
        dma_p2_start_addr   =   16'h00;
        dma_ctrl            =   3'h0;
        clear_int           =   1'b0;
    end
    else
    begin
        clear_int           =   1'b0;
        dma_ctrl[2]         =   1'b0;
        per_dout            =   16'h0;
        if((per_en == 1'b1) & (per_addr[13:8] == DMA_BASE_ADDR))
        begin
            if(per_wen == 2'b11)
            begin
                if(per_addr[7:0]    ==  DMA_CSR)
                    dma_ctrl    =   per_din[2:0];
                else if(per_addr[7:0]   ==  DMA_STATUS)
                begin
                    if(per_din[0] == 1'b1)
                        clear_int   =   1'b1;
                end
                else if(per_addr[7:0]   ==  DMA_P1_SADDR)
                    dma_p1_start_addr   =   per_din;
                else if(per_addr[7:0]   ==  DMA_P2_SADDR)
                    dma_p2_start_addr   =   per_din;
                else if(per_addr[7:0]   ==  DMA_TRANS_LEN)
                    dma_transfer_len    =   per_din;
            end
            else if(per_wen == 2'b00)
            begin
                if(per_addr[7:0]    ==  DMA_CSR)
                    per_dout[2:0]   =   dma_ctrl;
                else if(per_addr[7:0]   ==  DMA_STATUS)
                    per_dout[1:0]  =   {dma_busy,int_gen};
                else if(per_addr[7:0]   ==  DMA_P1_SADDR)
                    per_dout        =   dma_p1_start_addr;
                else if(per_addr[7:0]   ==  DMA_P2_SADDR)
                    per_dout        =   dma_p2_start_addr;
                else if(per_addr[7:0]   ==  DMA_TRANS_LEN)
                    per_dout        =   dma_transfer_len;
            end
        end
    end
end

assign int_enabled      =  dma_ctrl[0];
assign direction_bit    =  dma_ctrl[1];
assign dma_trans_start  =  dma_ctrl[2];

endmodule
