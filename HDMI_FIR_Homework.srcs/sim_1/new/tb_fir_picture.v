`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 01.06.2026 21:56:17
// Design Name:
// Module Name: tb_fir_picture
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//   Picture-based end-to-end testbench for:
//      RGB888 RAW -> grayscale -> line buffer -> 5x5 FIR -> RAW output
//
//   Input format:
//      512x512 RGB888 raw image (3 bytes per pixel, no header)
//
// Dependencies:
//
// Revision:
// Revision 0.02 - FIR picture testbench added
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module tb_fir_picture();

localparam integer RES        = 512;
localparam integer BLANK_COLS = 51;
localparam integer LINE_WIDTH = RES + BLANK_COLS;
localparam integer ADDR_WIDTH = 10;

reg clk = 1'b0;
reg rst = 1'b1;

wire                dv_i;
wire                hs_i;
wire                vs_i;
wire          [7:0] r_i;
wire          [7:0] g_i;
wire          [7:0] b_i;
wire                dv_y;
wire                hs_y;
wire                vs_y;
wire          [7:0] pixel_y;

wire          [7:0] current_pixel;
wire          [7:0] line_1_pixel;
wire          [7:0] line_2_pixel;
wire          [7:0] line_3_pixel;
wire          [7:0] line_4_pixel;
wire                pixel_valid_lb;
wire                h_sync_lb;
wire                v_sync_lb;

wire signed [24:0] pixel_0_fir;
wire signed [24:0] pixel_1_fir;
wire signed [24:0] pixel_2_fir;
wire signed [24:0] pixel_3_fir;
wire signed [24:0] pixel_4_fir;

wire         [7:0] fir_out_sat;
wire               fir_valid_o;
wire               fir_h_sync_o;
wire               fir_v_sync_o;

integer file_in, file_out;
integer file_status;
integer out_count = 0;
integer valid_count = 0;
integer sample_debug_count = 0;
reg [7:0] mem_in [0:RES*RES*3-1];

reg [15:0] col = 16'hffff;
reg [15:0] row = 16'hffff;

reg signed [17:0] kr_i = 18'sd27865;
reg signed [17:0] kb_i = 18'sd9463;

// Active preset: 5x5 Gaussian-like blur.
// Coefficients are stored as signed s8.8 values in 16 bits.
localparam signed [15:0] K00 = 16'sd1,  K01 = 16'sd4,  K02 = 16'sd6,  K03 = 16'sd4,  K04 = 16'sd1;
localparam signed [15:0] K10 = 16'sd4,  K11 = 16'sd16, K12 = 16'sd24, K13 = 16'sd16, K14 = 16'sd4;
localparam signed [15:0] K20 = 16'sd6,  K21 = 16'sd24, K22 = 16'sd36, K23 = 16'sd24, K24 = 16'sd6;
localparam signed [15:0] K30 = 16'sd4,  K31 = 16'sd16, K32 = 16'sd24, K33 = 16'sd16, K34 = 16'sd4;
localparam signed [15:0] K40 = 16'sd1,  K41 = 16'sd4,  K42 = 16'sd6,  K43 = 16'sd4,  K44 = 16'sd1;

// Quick presets to try later by just editing the constants above:
// 1) 5x5 box blur (very bright unless you scale later):
//    every Kxy = 16'sd1
//
// 2) Simple horizontal edge detector in the causal frame:
//    last row only: {0, 0, 0, -1, 1}
//    all other rows: 0
//
// 3) "Coefficient image" debug from the old test:
//    every row: {0, 0, 0, 0, 1}

assign pixel_0_fir = {17'd0, current_pixel};
assign pixel_1_fir = {17'd0, line_1_pixel};
assign pixel_2_fir = {17'd0, line_2_pixel};
assign pixel_3_fir = {17'd0, line_3_pixel};
assign pixel_4_fir = {17'd0, line_4_pixel};

rgb2y rgb2y_uut (
    .clk(clk),
    .kr_i(kr_i),
    .kb_i(kb_i),
    .dv_i(dv_i),
    .hs_i(hs_i),
    .vs_i(vs_i),
    .r_i(r_i),
    .g_i(g_i),
    .b_i(b_i),
    .dv_o(dv_y),
    .hs_o(hs_y),
    .vs_o(vs_y),
    .y_o(pixel_y)
);

bram_line_buffer #(
    .DATA_WIDTH(8),
    .LINE_WIDTH(LINE_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) line_buffer_uut (
    .clk(clk),
    .rst(rst),
    .pixel_in(pixel_y),
    .pixel_valid(dv_y),
    .h_sync(hs_y),
    .v_sync(vs_y),
    .current_pixel(current_pixel),
    .line_1_pixel(line_1_pixel),
    .line_2_pixel(line_2_pixel),
    .line_3_pixel(line_3_pixel),
    .line_4_pixel(line_4_pixel),
    .pixel_valid_out(pixel_valid_lb),
    .h_sync_out(h_sync_lb),
    .v_sync_out(v_sync_lb)
);

FIR_filter_5x5 #(
    .CTRL_DELAY(8)
) fir_uut (
    .clk(clk),
    .pixel_valid_i(pixel_valid_lb),
    .h_sync_i(h_sync_lb),
    .v_sync_i(v_sync_lb),
    .pixel_0_i(pixel_0_fir),
    .pixel_1_i(pixel_1_fir),
    .pixel_2_i(pixel_2_fir),
    .pixel_3_i(pixel_3_fir),
    .pixel_4_i(pixel_4_fir),

    .coeff_00_i(K00), .coeff_01_i(K01), .coeff_02_i(K02), .coeff_03_i(K03), .coeff_04_i(K04),
    .coeff_10_i(K10), .coeff_11_i(K11), .coeff_12_i(K12), .coeff_13_i(K13), .coeff_14_i(K14),
    .coeff_20_i(K20), .coeff_21_i(K21), .coeff_22_i(K22), .coeff_23_i(K23), .coeff_24_i(K24),
    .coeff_30_i(K30), .coeff_31_i(K31), .coeff_32_i(K32), .coeff_33_i(K33), .coeff_34_i(K34),
    .coeff_40_i(K40), .coeff_41_i(K41), .coeff_42_i(K42), .coeff_43_i(K43), .coeff_44_i(K44),

    .fir_out_sat(fir_out_sat),
    .pixel_valid_o(fir_valid_o),
    .h_sync_o(fir_h_sync_o),
    .v_sync_o(fir_v_sync_o)
);

always #5 clk <= ~clk;

initial begin
    file_in = $fopen("lena.raw", "rb");
    if (file_in == 0) begin
        $display("ERROR: could not open input file lena.raw");
        $stop;
    end

    file_out = $fopen("fir_img_out.raw", "wb");
    if (file_out == 0) begin
        $display("ERROR: could not open output file fir_img_out.raw");
        $stop;
    end

    file_status = $fread(mem_in, file_in);
    $fclose(file_in);

    repeat (4) @(posedge clk);
    rst <= 1'b0;

    wait (out_count == RES*RES);
    $display("DONE: wrote %0d pixels to fir_img_out.raw", out_count);

    $fclose(file_out);
    $stop;
end

initial begin
    #(10_000_000);
    $display("TIMEOUT: out_count=%0d valid_count=%0d row=%0d col=%0d fir_valid_o=%0b", out_count, valid_count, row, col, fir_valid_o);
    $fclose(file_out);
    $stop;
end

always @(negedge clk) begin
    if (col == (LINE_WIDTH-1)) begin
        col <= 16'd0;
    end else begin
        col <= col + 1'b1;
    end

    if (col == (LINE_WIDTH-1)) begin
        if (row == (LINE_WIDTH - 1)) begin
            row <= 16'd0;
        end else begin
            row <= row + 1'b1;
        end
    end
end

assign dv_i = (col < RES) && (row < RES);
assign hs_i = (col == (RES + 10));
assign vs_i = (row == (RES + 10));
assign r_i = dv_i ? mem_in[row*RES*3 + col*3 + 0] : 8'd0;
assign g_i = dv_i ? mem_in[row*RES*3 + col*3 + 1] : 8'd0;
assign b_i = dv_i ? mem_in[row*RES*3 + col*3 + 2] : 8'd0;

always @(negedge clk) begin
    if (fir_valid_o) begin
        $fwrite(file_out, "%c", fir_out_sat);
        out_count = out_count + 1;
        valid_count = valid_count + 1;
        if (sample_debug_count < 32) begin
            $display("PIXDBG: n=%0d row=%0d col=%0d rgb=(%0d,%0d,%0d) y=%0d taps={%0d,%0d,%0d,%0d,%0d} sat=%0d",
                     sample_debug_count, row, col, r_i, g_i, b_i, pixel_y,
                     pixel_4_fir[7:0], pixel_3_fir[7:0], pixel_2_fir[7:0], pixel_1_fir[7:0], pixel_0_fir[7:0],
                     fir_out_sat);
            sample_debug_count = sample_debug_count + 1;
        end
        if ((out_count % 16384) == 0)
            $display("PROGRESS: wrote %0d pixels", out_count);
    end
end

endmodule
