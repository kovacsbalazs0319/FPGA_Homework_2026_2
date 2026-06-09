`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2026 20:13:57
// Design Name: 
// Module Name: tb_bram_filter_jointed
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_bram_filter_jointed(

);

localparam integer DATA_WIDTH   = 8;
localparam integer ACTIVE_COLS  = 8;
localparam integer BLANK_COLS   = 5;
localparam integer LINE_WIDTH   = ACTIVE_COLS + BLANK_COLS;
localparam integer ADDR_WIDTH   = 4;
localparam integer NUM_ROWS     = 7;

reg clk;
reg rst;
reg [DATA_WIDTH-1:0] pixel_in;
reg pixel_valid;
reg h_sync;
reg v_sync;

wire [DATA_WIDTH-1:0] current_pixel;
wire [DATA_WIDTH-1:0] line_1_pixel;
wire [DATA_WIDTH-1:0] line_2_pixel;
wire [DATA_WIDTH-1:0] line_3_pixel;
wire [DATA_WIDTH-1:0] line_4_pixel;
wire pixel_valid_out;
wire h_sync_out;
wire v_sync_out;

wire signed [24:0] pixel_0_fir;
wire signed [24:0] pixel_1_fir;
wire signed [24:0] pixel_2_fir;
wire signed [24:0] pixel_3_fir;
wire signed [24:0] pixel_4_fir;

wire        [7:0]  fir_out_sat;
wire               fir_valid_out;
wire               fir_h_sync_out;
wire               fir_v_sync_out;

assign pixel_0_fir = {17'd0, current_pixel};
assign pixel_1_fir = {17'd0, line_1_pixel};
assign pixel_2_fir = {17'd0, line_2_pixel};
assign pixel_3_fir = {17'd0, line_3_pixel};
assign pixel_4_fir = {17'd0, line_4_pixel};

bram_line_buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dut_line_buffer (
    .clk(clk),
    .rst(rst),
    .pixel_in(pixel_in),
    .pixel_valid(pixel_valid),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .current_pixel(current_pixel),
    .line_1_pixel(line_1_pixel),
    .line_2_pixel(line_2_pixel),
    .line_3_pixel(line_3_pixel),
    .line_4_pixel(line_4_pixel),
    .pixel_valid_out(pixel_valid_out),
    .h_sync_out(h_sync_out),
    .v_sync_out(v_sync_out)
);

FIR_filter_5x5 #(
    .CTRL_DELAY(12)
) dut_fir (
    .clk(clk),
    .pixel_valid_i(pixel_valid_out),
    .h_sync_i(h_sync_out),
    .v_sync_i(v_sync_out),
    .pixel_0_i(pixel_0_fir),
    .pixel_1_i(pixel_1_fir),
    .pixel_2_i(pixel_2_fir),
    .pixel_3_i(pixel_3_fir),
    .pixel_4_i(pixel_4_fir),
    .coeff_00_i(16'sd0),
    .coeff_01_i(16'sd0),
    .coeff_02_i(16'sd0),
    .coeff_03_i(16'sd0),
    .coeff_04_i(16'sd256),
    .coeff_10_i(16'sd0),
    .coeff_11_i(16'sd0),
    .coeff_12_i(16'sd0),
    .coeff_13_i(16'sd0),
    .coeff_14_i(16'sd256),
    .coeff_20_i(16'sd0),
    .coeff_21_i(16'sd0),
    .coeff_22_i(16'sd0),
    .coeff_23_i(16'sd0),
    .coeff_24_i(16'sd256),
    .coeff_30_i(16'sd0),
    .coeff_31_i(16'sd0),
    .coeff_32_i(16'sd0),
    .coeff_33_i(16'sd0),
    .coeff_34_i(16'sd256),
    .coeff_40_i(16'sd0),
    .coeff_41_i(16'sd0),
    .coeff_42_i(16'sd0),
    .coeff_43_i(16'sd0),
    .coeff_44_i(16'sd256),
    .fir_out_sat(fir_out_sat),
    .pixel_valid_out(fir_valid_out),
    .h_sync_out(fir_h_sync_out),
    .v_sync_out(fir_v_sync_out)
);

always #5 clk = ~clk;

initial begin
    clk         = 1'b0;
    rst         = 1'b1;
    pixel_in    = {DATA_WIDTH{1'b0}};
    pixel_valid = 1'b0;
    h_sync      = 1'b0;
    v_sync      = 1'b0;

    repeat (4) @(posedge clk);
    rst = 1'b0;

    drive_frame();

    repeat (40) @(posedge clk);
    $finish;
end

task drive_frame;
    integer row_idx;
begin
    for (row_idx = 0; row_idx < NUM_ROWS; row_idx = row_idx + 1) begin
        drive_row(row_idx);
        drive_blank();
    end
end
endtask

task drive_row;
    input integer row_idx;
    integer col_idx;
begin
    for (col_idx = 0; col_idx < ACTIVE_COLS; col_idx = col_idx + 1) begin
        @(negedge clk);
        pixel_valid <= 1'b1;
        h_sync      <= (col_idx == 0);
        v_sync      <= ((row_idx == 0) && (col_idx == 0));
        pixel_in    <= row_idx * 16 + col_idx + 1;
    end
end
endtask

task drive_blank;
    integer blank_idx;
begin
    for (blank_idx = 0; blank_idx < BLANK_COLS; blank_idx = blank_idx + 1) begin
        @(negedge clk);
        pixel_valid <= 1'b0;
        h_sync      <= 1'b0;
        v_sync      <= 1'b0;
        pixel_in    <= {DATA_WIDTH{1'b0}};
    end
end
endtask

always @(posedge clk) begin
    if (!rst && pixel_valid_out) begin
        $display("[%0t] LB/FIR: lb_valid=%0b fir_valid=%0b hs=%0b hs_fir=%0b pixels={%0d,%0d,%0d,%0d,%0d} sat=%0d",
            $time,
            pixel_valid_out,
            fir_valid_out,
            h_sync_out,
            fir_h_sync_out,
            pixel_4_fir,
            pixel_3_fir,
            pixel_2_fir,
            pixel_1_fir,
            pixel_0_fir,
            fir_out_sat
        );
    end
end

endmodule
