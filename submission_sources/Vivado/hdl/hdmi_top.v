`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2019 04:56:58 PM
// Design Name: 
// Module Name: hdmi_top
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


module hdmi_top(
   input  wire       clk100M,
   input  wire       rstbt,
   output wire [7:0] led_r,
   input  wire [7:0] sw,
   inout  wire [3:0] bt,
   input  wire       uart_rxd,
   output wire       uart_txd,
   
   input  wire       hdmi_rx_d0_p,
   input  wire       hdmi_rx_d0_n,
   input  wire       hdmi_rx_d1_p,
   input  wire       hdmi_rx_d1_n,
   input  wire       hdmi_rx_d2_p,
   input  wire       hdmi_rx_d2_n,
   input  wire       hdmi_rx_clk_p,
   input  wire       hdmi_rx_clk_n,
   input  wire       hdmi_rx_cec,
   output wire       hdmi_rx_hpd,
   input  wire       hdmi_rx_scl,
   inout  wire       hdmi_rx_sda,
   
   output wire       hdmi_tx_d0_p,
   output wire       hdmi_tx_d0_n,
   output wire       hdmi_tx_d1_p,
   output wire       hdmi_tx_d1_n,
   output wire       hdmi_tx_d2_p,
   output wire       hdmi_tx_d2_n,
   output wire       hdmi_tx_clk_p,
   output wire       hdmi_tx_clk_n,
   input  wire       hdmi_tx_cec,
   input  wire       hdmi_tx_hpdn,
   input  wire       hdmi_tx_scl,
   input  wire       hdmi_tx_sda
);

//******************************************************************************
//* Generating the 200 MHz reference clock for the IDELAYCTRL.                 *
//******************************************************************************
wire clk200M;
wire pll_clkfb;
wire pll_locked;

PLLE2_BASE #(
   .BANDWIDTH("OPTIMIZED"),         // OPTIMIZED, HIGH, LOW
   .CLKFBOUT_MULT(10),              // Multiply value for all CLKOUT, (2-64)
   .CLKFBOUT_PHASE(0.0),            // Phase offset in degrees of CLKFB, (-360.000-360.000).
   .CLKIN1_PERIOD(1000.0 / 100.0),  // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
   .CLKOUT0_DIVIDE(5),              // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
   .CLKOUT1_DIVIDE(1),
   .CLKOUT2_DIVIDE(1),
   .CLKOUT3_DIVIDE(1),
   .CLKOUT4_DIVIDE(1),
   .CLKOUT5_DIVIDE(1),
   .CLKOUT0_DUTY_CYCLE(0.5),        // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
   .CLKOUT1_DUTY_CYCLE(0.5),
   .CLKOUT2_DUTY_CYCLE(0.5),
   .CLKOUT3_DUTY_CYCLE(0.5),
   .CLKOUT4_DUTY_CYCLE(0.5),
   .CLKOUT5_DUTY_CYCLE(0.5),
   .CLKOUT0_PHASE(0.0),             // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
   .CLKOUT1_PHASE(0.0),
   .CLKOUT2_PHASE(0.0),
   .CLKOUT3_PHASE(0.0),
   .CLKOUT4_PHASE(0.0),
   .CLKOUT5_PHASE(0.0),
   .DIVCLK_DIVIDE(1),               // Master division value, (1-56)
   .REF_JITTER1(0.0),               // Reference input jitter in UI, (0.000-0.999).
   .STARTUP_WAIT("FALSE")           // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
) clk_generator1 (
   .CLKOUT0(clk200M),               // 1-bit output: CLKOUT0
   .CLKOUT1(),                      // 1-bit output: CLKOUT1
   .CLKOUT2(),                      // 1-bit output: CLKOUT2
   .CLKOUT3(),                      // 1-bit output: CLKOUT3
   .CLKOUT4(),                      // 1-bit output: CLKOUT4
   .CLKOUT5(),                      // 1-bit output: CLKOUT5
   .CLKFBOUT(pll_clkfb),            // 1-bit output: Feedback clock
   .LOCKED(pll_locked),             // 1-bit output: LOCK
   .CLKIN1(clk100M),                // 1-bit input: Input clock
   .PWRDWN(1'b0),                   // 1-bit input: Power-down
   .RST(rstbt),                     // 1-bit input: Reset
   .CLKFBIN(pll_clkfb)              // 1-bit input: Feedback clock
);

wire rst;
assign rst = ~pll_locked;

wire clk_200M;
BUFG BUFG_200M (
   .O(clk_200M),
   .I(clk200M)
);



wire rx_clk, rx_clk_5x;
wire [7:0] rx_red, rx_green, rx_blue;
wire rx_dv, rx_hs, rx_vs;
wire [5:0] rx_status;
hdmi_rx hdmi_rx_0(
   .clk_200M(clk_200M),
   .rst(rst),
   .hdmi_rx_cec(hdmi_rx_cec),
   .hdmi_rx_hpd(hdmi_rx_hpd),
   .hdmi_rx_scl(hdmi_rx_scl),
   .hdmi_rx_sda(hdmi_rx_sda),
   .hdmi_rx_clk_p(hdmi_rx_clk_p),
   .hdmi_rx_clk_n(hdmi_rx_clk_n),
   .hdmi_rx_d0_p(hdmi_rx_d0_p),
   .hdmi_rx_d0_n(hdmi_rx_d0_n),
   .hdmi_rx_d1_p(hdmi_rx_d1_p),
   .hdmi_rx_d1_n(hdmi_rx_d1_n),
   .hdmi_rx_d2_p(hdmi_rx_d2_p),
   .hdmi_rx_d2_n(hdmi_rx_d2_n),
   .rx_clk(rx_clk),
   .rx_clk_5x(rx_clk_5x),
   .rx_red(rx_red),
   .rx_green(rx_green),
   .rx_blue(rx_blue),
   .rx_dv(rx_dv),
   .rx_hs(rx_hs),
   .rx_vs(rx_vs),
   .rx_status(rx_status)
);

localparam integer FIR_LINE_WIDTH = 2048;
localparam integer FIR_ADDR_WIDTH = 11;

wire rgb2y_dv;
wire rgb2y_hs;
wire rgb2y_vs;
wire [7:0] rgb2y_y;
wire [399:0] coeff_wire;
wire signed [15:0] fir_coeff_00;
wire signed [15:0] fir_coeff_01;
wire signed [15:0] fir_coeff_02;
wire signed [15:0] fir_coeff_03;
wire signed [15:0] fir_coeff_04;
wire signed [15:0] fir_coeff_10;
wire signed [15:0] fir_coeff_11;
wire signed [15:0] fir_coeff_12;
wire signed [15:0] fir_coeff_13;
wire signed [15:0] fir_coeff_14;
wire signed [15:0] fir_coeff_20;
wire signed [15:0] fir_coeff_21;
wire signed [15:0] fir_coeff_22;
wire signed [15:0] fir_coeff_23;
wire signed [15:0] fir_coeff_24;
wire signed [15:0] fir_coeff_30;
wire signed [15:0] fir_coeff_31;
wire signed [15:0] fir_coeff_32;
wire signed [15:0] fir_coeff_33;
wire signed [15:0] fir_coeff_34;
wire signed [15:0] fir_coeff_40;
wire signed [15:0] fir_coeff_41;
wire signed [15:0] fir_coeff_42;
wire signed [15:0] fir_coeff_43;
wire signed [15:0] fir_coeff_44;

wire [7:0] current_pixel;
wire [7:0] line_1_pixel;
wire [7:0] line_2_pixel;
wire [7:0] line_3_pixel;
wire [7:0] line_4_pixel;
wire linebuf_dv;
wire linebuf_hs;
wire linebuf_vs;

wire signed [24:0] fir_pixel_0;
wire signed [24:0] fir_pixel_1;
wire signed [24:0] fir_pixel_2;
wire signed [24:0] fir_pixel_3;
wire signed [24:0] fir_pixel_4;

wire [7:0] fir_out_sat;
wire fir_dv;
wire fir_hs;
wire fir_vs;

wire [7:0] tx_red;
wire [7:0] tx_green;
wire [7:0] tx_blue;
wire tx_dv;
wire tx_hs;
wire tx_vs;

cpu_hdmi_system_sv processor_inst (
   .rstbtn(rstbt),
   .clk_in(clk100M),
   .uart_rx(uart_rxd),
   .uart_tx(uart_txd),
   .coeff_out_0(coeff_wire)
);

assign fir_coeff_00 = coeff_wire[15:0];
assign fir_coeff_01 = coeff_wire[31:16];
assign fir_coeff_02 = coeff_wire[47:32];
assign fir_coeff_03 = coeff_wire[63:48];
assign fir_coeff_04 = coeff_wire[79:64];
assign fir_coeff_10 = coeff_wire[95:80];
assign fir_coeff_11 = coeff_wire[111:96];
assign fir_coeff_12 = coeff_wire[127:112];
assign fir_coeff_13 = coeff_wire[143:128];
assign fir_coeff_14 = coeff_wire[159:144];
assign fir_coeff_20 = coeff_wire[175:160];
assign fir_coeff_21 = coeff_wire[191:176];
assign fir_coeff_22 = coeff_wire[207:192];
assign fir_coeff_23 = coeff_wire[223:208];
assign fir_coeff_24 = coeff_wire[239:224];
assign fir_coeff_30 = coeff_wire[255:240];
assign fir_coeff_31 = coeff_wire[271:256];
assign fir_coeff_32 = coeff_wire[287:272];
assign fir_coeff_33 = coeff_wire[303:288];
assign fir_coeff_34 = coeff_wire[319:304];
assign fir_coeff_40 = coeff_wire[335:320];
assign fir_coeff_41 = coeff_wire[351:336];
assign fir_coeff_42 = coeff_wire[367:352];
assign fir_coeff_43 = coeff_wire[383:368];
assign fir_coeff_44 = coeff_wire[399:384];

assign fir_pixel_0 = {17'd0, current_pixel};
assign fir_pixel_1 = {17'd0, line_1_pixel};
assign fir_pixel_2 = {17'd0, line_2_pixel};
assign fir_pixel_3 = {17'd0, line_3_pixel};
assign fir_pixel_4 = {17'd0, line_4_pixel};

rgb2y rgb2y_0(
   .clk(rx_clk),
   .kr_i(18'sd27865),
   .kb_i(18'sd9463),
   .dv_i(rx_dv),
   .hs_i(rx_hs),
   .vs_i(rx_vs),
   .r_i(rx_red),
   .g_i(rx_green),
   .b_i(rx_blue),
   .dv_o(rgb2y_dv),
   .hs_o(rgb2y_hs),
   .vs_o(rgb2y_vs),
   .y_o(rgb2y_y)
);

bram_line_buffer #(
   .DATA_WIDTH(8),
   .LINE_WIDTH(FIR_LINE_WIDTH),
   .ADDR_WIDTH(FIR_ADDR_WIDTH)
) line_buffer_0 (
   .clk(rx_clk),
   .rst(rst),
   .pixel_in(rgb2y_y),
   .pixel_valid(rgb2y_dv),
   .h_sync(rgb2y_hs),
   .v_sync(rgb2y_vs),
   .current_pixel(current_pixel),
   .line_1_pixel(line_1_pixel),
   .line_2_pixel(line_2_pixel),
   .line_3_pixel(line_3_pixel),
   .line_4_pixel(line_4_pixel),
   .pixel_valid_out(linebuf_dv),
   .h_sync_out(linebuf_hs),
   .v_sync_out(linebuf_vs)
);

FIR_filter_5x5 #(
   .CTRL_DELAY(8)
) fir_0 (
   .clk(rx_clk),
   .pixel_valid_i(linebuf_dv),
   .h_sync_i(linebuf_hs),
   .v_sync_i(linebuf_vs),
   .pixel_0_i(fir_pixel_0),
   .pixel_1_i(fir_pixel_1),
   .pixel_2_i(fir_pixel_2),
   .pixel_3_i(fir_pixel_3),
   .pixel_4_i(fir_pixel_4),
   .coeff_00_i(fir_coeff_00),
   .coeff_01_i(fir_coeff_01),
   .coeff_02_i(fir_coeff_02),
   .coeff_03_i(fir_coeff_03),
   .coeff_04_i(fir_coeff_04),
   .coeff_10_i(fir_coeff_10),
   .coeff_11_i(fir_coeff_11),
   .coeff_12_i(fir_coeff_12),
   .coeff_13_i(fir_coeff_13),
   .coeff_14_i(fir_coeff_14),
   .coeff_20_i(fir_coeff_20),
   .coeff_21_i(fir_coeff_21),
   .coeff_22_i(fir_coeff_22),
   .coeff_23_i(fir_coeff_23),
   .coeff_24_i(fir_coeff_24),
   .coeff_30_i(fir_coeff_30),
   .coeff_31_i(fir_coeff_31),
   .coeff_32_i(fir_coeff_32),
   .coeff_33_i(fir_coeff_33),
   .coeff_34_i(fir_coeff_34),
   .coeff_40_i(fir_coeff_40),
   .coeff_41_i(fir_coeff_41),
   .coeff_42_i(fir_coeff_42),
   .coeff_43_i(fir_coeff_43),
   .coeff_44_i(fir_coeff_44),
   .fir_out_sat(fir_out_sat),
   .pixel_valid_out(fir_dv),
   .h_sync_out(fir_hs),
   .v_sync_out(fir_vs)
);

assign tx_dv    = fir_dv;
assign tx_hs    = fir_hs;
assign tx_vs    = fir_vs;
assign tx_red   = fir_out_sat;
assign tx_green = fir_out_sat;
assign tx_blue  = fir_out_sat;




hdmi_tx hdmi_tx_0(
   .tx_clk(rx_clk),
   .tx_clk_5x(rx_clk_5x),
   .rst(rst),
   .tx_red(tx_red),
   .tx_green(tx_green),
   .tx_blue(tx_blue),
   .tx_dv(tx_dv),
   .tx_hs(tx_hs),
   .tx_vs(tx_vs),
   .hdmi_tx_clk_p(hdmi_tx_clk_p),
   .hdmi_tx_clk_n(hdmi_tx_clk_n),
   .hdmi_tx_d0_p(hdmi_tx_d0_p),
   .hdmi_tx_d0_n(hdmi_tx_d0_n),
   .hdmi_tx_d1_p(hdmi_tx_d1_p),
   .hdmi_tx_d1_n(hdmi_tx_d1_n),
   .hdmi_tx_d2_p(hdmi_tx_d2_p),
   .hdmi_tx_d2_n(hdmi_tx_d2_n)
);

assign led_r = {pll_locked, 1'b0, rx_status};

endmodule
