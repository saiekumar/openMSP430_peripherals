// Sai Marri :: This module interfaces to the dma channel port and the fifo.
// Simple DMA controller suitable to the openMSP430 module


module dma_port(
        clk,
        reset_n,
        dma_addr,
        dma_en,
        dma_wen,
        dma_din,
        dma_ready,
        dma_dout,
        dma_resp,
        int_enabled,
        port_dir,
        dma_go,
        int_gen,
        busy,
        port_start_addr,
        transfer_len,
        fifo_din,
        fifo_wen,
        fifo_full,
        fifo_dout,
        fifo_ren,
        fifo_empty,
        error_generated,
        int_clear);

parameter   IDLE        =   2'b00;
parameter   DMA_RD      =   2'b01;
parameter   FIFO_RD     =   2'b10;
parameter   DMA_WR      =   2'b11;


input               clk;
input               reset_n;

output reg  [14:0]  dma_addr;
output reg          dma_en;
output reg  [1:0]   dma_wen;
output reg  [15:0]  dma_din;
input               dma_ready;
input       [15:0]  dma_dout;
input               dma_resp;

input               int_enabled;
input               port_dir;
input               dma_go;
output reg          int_gen;
output reg          busy;
input       [15:0]  port_start_addr;
input       [15:0]  transfer_len;

output reg  [15:0]  fifo_din;
output reg          fifo_wen;
input               fifo_full;

input       [15:0]  fifo_dout;
output  reg         fifo_ren;
input               fifo_empty;
output  reg         error_generated;
input               int_clear;

reg                 dma_done;
reg [1:0]           state;
reg                 first_trans;
reg [15:0]          count;
reg                 sample_dout;

reg                 fifo_ren_reg;
reg                 check_ready;


always @(posedge clk or negedge reset_n)
begin
    if(!reset_n)
    begin
        dma_addr        <=  15'h0;
        dma_en          <=  1'b0;
        dma_wen         <=  2'b00;
        dma_din         <=  16'h00;
        fifo_ren        <=  1'b0;
        dma_done        <=  1'b0;
        state           <=  IDLE;
        first_trans     <=  1'b0;
        error_generated <=  1'b0;
        count           <=  16'h0;
        sample_dout     <=  1'b0;
        check_ready     <=  1'b0;
    end
    else
    begin
        dma_done    <=  1'b0;
        sample_dout <=  1'b0;
        fifo_ren    <=  1'b0;
        case (state)
            IDLE:
            begin
                error_generated <= 1'b0;
                if(dma_go == 1'b1) 
                begin
                    if(port_dir ==  1'b0)
                        state   <=   DMA_RD;
                    else
                        state   <=   FIFO_RD;
                end
            end
            DMA_RD:
            begin
                if(first_trans == 1'b0)
                begin
                    first_trans <=   1'b1;
                    dma_addr    <=   port_start_addr[14:0];
                    dma_en      <=   1'b1;
                    count       <=   count + 2;
                end 
                else
                begin
                    if(dma_ready == 1'b1)
                    begin
                        if(dma_resp == 1'b1)
                            error_generated <= 1'b1;
                        if(count == transfer_len)
                        begin
                            dma_addr    <=  16'h00;
                            count       <=  16'h00;
                            sample_dout <=  1'b1;
                            dma_en      <=  1'b0;
                            state       <=  IDLE;
                            dma_done    <=  1'b1;
                        end
                        else if(fifo_full == 1'b1)
                        begin
                            dma_addr    <=  16'h00;
                            sample_dout <=  1'b1;
                            dma_en      <=  1'b0;
                            first_trans <=  1'b0;
                        end 
                        else
                        begin
                            dma_addr    <=   port_start_addr[14:0] + count;
                            count       <=  count + 2;
                            sample_dout <=  1'b1;
                        end
                    end
                end
            end
            FIFO_RD:
            begin
                if(fifo_empty == 1'b0)
                begin
                    fifo_ren    <=  1'b1;
                    state       <=  DMA_WR;
                end
            end
            DMA_WR:
            begin
                if(fifo_ren_reg == 1'b1)
                begin
                    dma_addr    <=  port_start_addr + count;
                    count       <=  count + 2;
                    dma_en      <=  1'b1;
                    dma_wen     <=  2'b11; 
                    dma_din     <=  fifo_dout;
                    check_ready <=  1'b1;
                end
                else if (check_ready == 1'b1)
                begin
                    if(dma_ready == 1'b1)
                    begin
                        check_ready     <=  1'b0;
                        dma_addr        <=  16'h0;
                        dma_en          <=  1'b0;
                        dma_wen         <=  2'b00;
                        if(count == transfer_len)
                        begin
                            dma_done        <= 1'b1;
                            state           <= IDLE;
                        end
                        else
                            fifo_ren        <= 1'b1;
                        if(dma_resp == 1'b1)
                            error_generated <=  1'b1;
                    end
                end
            end
        endcase
    end
end


// Writing to the FiFO
always @(posedge clk or negedge reset_n)
begin
    if(!reset_n)
    begin
        fifo_din    <=  16'h0;
        fifo_wen    <=  1'b0;
        fifo_ren_reg<=  1'b0;
    end
    else
    begin
        fifo_wen    <=  1'b0;
        fifo_ren_reg<=  fifo_ren;
        if(sample_dout == 1'b1)
        begin
            fifo_din    <=  dma_dout;
            fifo_wen    <=  1'b1;
        end
    end
end


// Setting the DMA busy flag
always @(posedge clk or negedge reset_n)
begin
    if(!reset_n)
    begin
        busy    <=   1'b0;
        int_gen <=   1'b0;
    end
    else
    begin
        if(dma_go == 1'b1)
		  begin
            busy    <=   1'b1;
            int_gen <=   1'b0;
		  end
        else if(dma_done == 1'b1)
        begin
            busy    <=   1'b0;
            int_gen <=   1'b1;
        end
        else if(int_clear)
            int_gen <=   1'b0;
    end    
end

endmodule
