// Sai Marri :: simple DMA controller to operate with openMSP430.
// DMA TOP module


module dma_top(
        clk,
        reset_n,
        
        per_addr,
        per_en,
        per_wen,
        per_din,
        per_dout,

        dma_addr_p1,
        dma_en_p1,
        dma_wen_p1,
        dma_din_p1,
        dma_ready_p1,
        dma_dout_p1,
        dma_resp_p1,

        dma_addr_p2,
        dma_en_p2,
        dma_wen_p2,
        dma_din_p2,
        dma_ready_p2,
        dma_dout_p2,
        dma_resp_p2,
        
        int_dma);


input                   clk;
input                   reset_n;

input   [13:0]          per_addr;
input                   per_en;
input   [1:0]           per_wen;
input   [15:0]          per_din;
output  [15:0]          per_dout;                

output  [15:0]          dma_addr_p1;
output                  dma_en_p1;
output  [1:0]           dma_wen_p1;
output  [15:0]          dma_din_p1;
input                   dma_ready_p1;
input   [15:0]          dma_dout_p1;
input                   dma_resp_p1;   

output  [15:0]          dma_addr_p2;
output                  dma_en_p2;
output  [1:0]           dma_wen_p2;
output  [15:0]          dma_din_p2;
input                   dma_ready_p2;
input   [15:0]          dma_dout_p2;
input                   dma_resp_p2;   

output                  int_dma;

wire    [15:0]          fifo1_din;
wire                    fifo1_wen;
wire                    fifo1_full;
wire                    fifo1_prog_full;
wire                    fifo1_ren;
wire    [15:0]          fifo1_dout;
wire                    fifo1_empty;
wire    [5:0]           fifo1_data_count;

wire    [15:0]          fifo2_din;
wire                    fifo2_wen;
wire                    fifo2_full;
wire                    fifo2_prog_full;
wire                    fifo2_ren;
wire    [15:0]          fifo2_dout;
wire                    fifo2_empty;
wire    [5:0]           fifo2_data_count;

wire                    int_enabled;
wire                    port_dir;

wire                    int_gen, int_gen_port1, int_gen_port2;
wire                    dma_busy, dma_busy_port1, dma_busy_port2;

wire                    dma_go;
wire  [15:0]            port1_start_addr;
wire  [15:0]            port2_start_addr;
wire  [15:0]            transfer_len;

wire                    clear_int;


dma_port port1(
       .clk(clk),
       .reset_n(reset_n),
       .dma_addr(dma_addr_p1),
       .dma_en(dma_en_p1),
       .dma_wen(dma_wen_p1),
       .dma_din(dma_din_p1),
       .dma_ready(dma_ready_p1),
       .dma_dout(dma_dout_p1),
       .dma_resp(dma_resp_p1),
       .int_enabled(int_enabled),
       .port_dir(port_dir),
       .dma_go(dma_go),
       .int_gen(int_gen_port1),
       .busy(dma_busy_port1),
       .port_start_addr(port1_start_addr),
       .transfer_len(transfer_len),
       .fifo_din(fifo1_din),
       .fifo_wen(fifo1_wen),
       .fifo_full(fifo1_prog_full),
       .fifo_dout(fifo2_dout),
       .fifo_ren(fifo2_ren),
       .fifo_empty(fifo2_empty),
       .error_generated(p1_error_generated),
       .int_clear(clear_int)
    );


dma_port port2(
       .clk(clk),
       .reset_n(reset_n),
       .dma_addr(dma_addr_p2),
       .dma_en(dma_en_p2),
       .dma_wen(dma_wen_p2),
       .dma_din(dma_din_p2),
       .dma_ready(dma_ready_p2),
       .dma_dout(dma_dout_p2),
       .dma_resp(dma_resp_p2),
       .int_enabled(int_enabled),
       .port_dir(~port_dir),
       .dma_go(dma_go),
       .int_gen(int_gen_port2),
       .busy(dma_busy_port2),
       .port_start_addr(port2_start_addr),
       .transfer_len(transfer_len),
       .fifo_din(fifo2_din),
       .fifo_wen(fifo2_wen),
       .fifo_full(fifo2_prog_full),
       .fifo_dout(fifo1_dout),
       .fifo_ren(fifo1_ren),
       .fifo_empty(fifo1_empty),
       .error_generated(p2_error_generated),
       .int_clear(clear_int)
    );


dma_registers registers(
       .clk(clk),
       .reset_n(reset_n),
       .per_addr(per_addr),
       .per_en(per_en),
       .per_wen(per_wen),
       .per_din(per_din),
       .per_dout(per_dout),
       .int_gen(int_gen),
       .dma_busy(dma_busy),
       .int_enabled(int_enabled),
       .direction_bit(port_dir),
       .dma_trans_start(dma_go),
       .dma_p1_start_addr(port1_start_addr),
       .dma_p2_start_addr(port2_start_addr),
       .dma_transfer_len(transfer_len),
       .clear_int(clear_int)
        );
    

assign int_gen  =   int_gen_port1 || int_gen_port2;
assign dma_busy =   dma_busy_port1|| dma_busy_port2;


fifo_dma fifo1(
        .clk(clk),
        .rst(!reset_n),
        .din(fifo1_din),
        .wr_en(fifo1_wen),
        .full(fifo1_full),
        .prog_full(fifo1_prog_full),
        .dout(fifo1_dout),
        .rd_en(fifo1_ren),
        .empty(fifo1_empty),
        .data_count(fifo1_data_count)
        );

fifo_dma fifo2(
        .clk(clk),
        .rst(!reset_n),
        .din(fifo2_din),
        .wr_en(fifo2_wen),
        .full(fifo2_full),
        .prog_full(fifo2_prog_full),
        .dout(fifo2_dout),
        .rd_en(fifo2_ren),
        .empty(fifo2_empty),
        .data_count(fifo2_data_count)
        );

assign int_dma  =   int_gen_port1 || int_gen_port2;

endmodule
