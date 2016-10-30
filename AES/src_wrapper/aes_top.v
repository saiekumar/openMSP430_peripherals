// Sai Marri: AES wrapper compatible with the openMSP430 IP

module aes_top
(
	clk, 
    reset_n, 
    per_addr,
    per_en,
    per_wen,
    per_din,
    per_dout,
    int_aes
);

parameter   AES_CTRL    =   8'h00;
parameter   AES_STATUS  =   8'h02;
parameter   AES_KEY     =   8'h04;
parameter   AES_DIN     =   8'h06;
parameter   AES_DOUT    =   8'h08;

//---------------------------------------------------------------------------------------
// module interfaces 
// global signals 
input			clk;
input			reset_n;

input   [13:0]  per_addr;
input           per_en;
input   [1:0]   per_wen;
input   [15:0]  per_din;
output reg  [15:0]  per_dout;
output          int_aes;


//---------------------------------------------------------------------------------------
// registered outputs 

reg [5:0]  aes_ctrl;
//  BIT[0]      :   0 - AES Disable : 1 - AES Enable
//  BIT[1]      :   0 - Encryption : 1 - Decryption
//  BIT[3:2]    :   00 - 128: 01 - 192 : 10 - 256 : 11 - 128
//  BIT[4]      :   1 - Start process
//  BIT[5]      :   enable interrupt
wire [3:0]  aes_status;
// BIT[0]       :   1 - Ready for next data : 0 - Busy
// BIT[1]       :   1 - Key expansion done
// BIT[2]       :   1 - Data available
// BIT[3]       :   1 - interrput set
reg [15:0]  aes_key_reg;
reg [15:0]  aes_din_reg;
reg [15:0]  aes_dout_reg;

reg [255:0] aes_key;
reg [127:0] aes_data_in;
wire [127:0] aes_data_out;

reg [3:0]   key_count;
reg [2:0]   data_count;

reg         int_key_start;
reg         int_data_valid;

wire        o_key_ready;
wire        o_data_valid;
wire        o_ready;

wire [1:0]  i_key_mode;

//---------------------------------------------------------------------------------------
// module implementation 
// internal key and data vectors write process 
always @ (posedge clk or negedge reset_n) 
begin 
	if (!reset_n) 
	begin 
        aes_data_in     <=  128'h0;
        aes_key         <=  256'h0;
        aes_ctrl        <=  6'h0;
        aes_key_reg     <=  16'h0;
        aes_din_reg     <=  16'h0;
        aes_dout_reg    <=  16'h0;
        key_count       <=  4'h0;
        data_count      <=  3'h0;
        int_key_start   <=  1'b0;
        int_data_valid  <=  1'b0;
	end 
	else 
	begin 
        aes_ctrl[4]     <=  1'b0;        
        per_dout        <=  16'h00;
        int_key_start   <=  1'b0;
        if(int_key_start == 1'b1)
            key_count   <=   4'h0;

        if((per_addr[13:8] == 6'h00) && (per_en == 1'b1)) // Modify the address once you have identyfied the address space
        begin
            if(per_addr[8:0] == AES_CTRL)
            begin
                if(per_wen == 2'b11)
                    aes_ctrl    <=  per_din[5:0];
                else
                    per_dout[5:0]    <=  aes_ctrl;
            end
            else if((per_addr[8:0] == AES_STATUS) && (per_wen == 2'b00))
                per_dout    <=  aes_status;
            else if((per_addr[8:0] == AES_KEY) && (per_wen == 2'b11))
            begin
                case (key_count)
                    4'h00:   aes_key[015:000]   <=  per_din;
                    4'h01:   aes_key[031:016]   <=  per_din;
                    4'h02:   aes_key[047:032]   <=  per_din;
                    4'h03:   aes_key[063:048]   <=  per_din;
                    4'h04:   aes_key[079:064]   <=  per_din;
                    4'h05:   aes_key[095:080]   <=  per_din;
                    4'h06:   aes_key[111:096]   <=  per_din;
                    4'h07:
                    begin
                            aes_key[127:112]   <=  per_din;
                            if(i_key_mode == 2'b00)
                                int_key_start <= 1'b1;
                    end
                    4'h08:   aes_key[143:128]   <=  per_din;
                    4'h09:   aes_key[159:144]   <=  per_din;
                    4'h10:   aes_key[175:160]   <=  per_din;
                    4'h11:   
                    begin
                            aes_key[191:176]   <=  per_din;
                            if(i_key_mode == 2'b01)
                                int_key_start <= 1'b1;
                    end
                    4'h12:   aes_key[207:192]   <=  per_din;
                    4'h13:   aes_key[223:208]   <=  per_din;
                    4'h14:   aes_key[239:224]   <=  per_din;
                    4'h15:
                    begin
                            aes_key[255:240]   <=  per_din;
                            if(i_key_mode == 2'b10)
                                int_key_start <= 1'b1;
                    end
                endcase
                key_count   <=  key_count + 1;
            end
            else if((per_addr[8:0] == AES_DIN) && (per_wen == 2'b11))
            begin
                case (data_count)
                    3'h00:   
                    begin
                             aes_data_in[015:000]   <=  per_din;
                             int_data_valid         <=  1'b0;
                    end
                    3'h01:   aes_data_in[031:016]   <=  per_din;
                    3'h02:   aes_data_in[047:032]   <=  per_din;
                    3'h03:   aes_data_in[063:048]   <=  per_din;
                    3'h04:   aes_data_in[079:064]   <=  per_din;
                    3'h05:   aes_data_in[095:080]   <=  per_din;
                    3'h06:   aes_data_in[111:096]   <=  per_din;
                    3'h07:
                    begin
                             aes_data_in[127:112]   <=  per_din;
                             int_data_valid         <=  1'b1;
                    end
                endcase
                data_count   <=  data_count + 1;
            end
            else if((per_addr[8:0] == AES_DOUT) && (per_wen == 2'b00))
            begin
                case (data_count)
                    3'h00:  per_dout    <=  aes_data_out[015:000];
                    3'h01:  per_dout    <=  aes_data_out[031:016];
                    3'h02:  per_dout    <=  aes_data_out[047:032];
                    3'h03:  per_dout    <=  aes_data_out[063:048];
                    3'h04:  per_dout    <=  aes_data_out[079:064];
                    3'h05:  per_dout    <=  aes_data_out[095:080];
                    3'h06:  per_dout    <=  aes_data_out[111:096];
                    3'h07:  per_dout    <=  aes_data_out[127:112];
                endcase
                data_count   <=  data_count + 1;
            end
        end
    end
end 


assign i_key_mode           =   aes_ctrl[3:2];
assign i_enable             =   aes_ctrl[0];
assign i_enc_dec            =   aes_ctrl[1];
assign start_process        =   int_data_valid & aes_ctrl[4];
assign int_enable           =   aes_ctrl[5];

assign aes_status[1]        =   o_key_ready;
assign aes_status[2]        =   o_data_valid;
assign aes_status[0]        =   o_ready;
assign int_aes              =   int_enable && o_data_valid;
assign aes_status[3]        =   int_aes;




// AES core instance 
aes u_aes 
(
   .clk(clk),
   .reset(reset_n),
   .i_start(int_key_start),
   .i_enable(i_enable),
   .i_ende(i_enc_dec),
   .i_key(aes_key),
   .i_key_mode(i_key_mode),
   .i_data(aes_data_in),
   .i_data_valid(start_process),
   .o_ready(o_ready),
   .o_data(aes_data_out),
   .o_data_valid(o_data_valid),
   .o_key_ready(o_key_ready)
);

endmodule
