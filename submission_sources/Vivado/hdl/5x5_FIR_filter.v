`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 19:10:22
// Design Name: 
// Module Name: 5x5_FIR_filter
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

/*
 * DSP with passthrough for systolic mode
 */
module dsp_25x18_passthrough
#(
    parameter integer A_REG = 2,
    parameter integer B_REG = 2
)(
    input  wire                     clk,
    input  wire signed [24:0]       a,
    input  wire signed [17:0]       b,
    input  wire signed [47:0]       pci,
    output wire signed [24:0]       a_passthrough,
    output wire signed [47:0]       p
);

reg signed [24:0] a_reg [0:A_REG-1];
reg signed [17:0] b_reg [0:B_REG-1];
reg signed [42:0] m_reg;
reg signed [47:0] p_reg;
integer i;
integer init_idx;


/*
 * For deterministic behaviour set registers to 0 initially
 */
initial begin
    for (init_idx = 0; init_idx < A_REG; init_idx = init_idx + 1)
        a_reg[init_idx] = 25'sd0;
    for (init_idx = 0; init_idx < B_REG; init_idx = init_idx + 1)
        b_reg[init_idx] = 18'sd0;
    m_reg = 43'sd0;
    p_reg = 48'sd0;
end

/*
 * Parameterized registering, this is for easier object marking
 * for the systolic FIR
 * A is for the data
 * B is for the coeff
 */
always @(posedge clk)
for (i = 0; i < A_REG; i = i + 1)
    a_reg[i] <= (i == 0) ? a : a_reg[i-1];

always @(posedge clk)
for (i = 0; i < B_REG; i = i + 1)
    b_reg[i] <= (i == 0) ? b : b_reg[i-1];

always @(posedge clk) begin
    m_reg <= a_reg[A_REG-1] * b_reg[B_REG-1];
    p_reg <= m_reg + pci;
end

assign a_passthrough = a_reg[A_REG-1];
assign p = p_reg;

endmodule

/*
 * 1 row of systolic Fir filetr, 1D
 */
module fir_row_5_cells
(
    input  wire                     clk,
    input  wire signed [24:0]       pixel_in,
    input  wire signed [17:0]       coeff_0_i,
    input  wire signed [17:0]       coeff_1_i,
    input  wire signed [17:0]       coeff_2_i,
    input  wire signed [17:0]       coeff_3_i,
    input  wire signed [17:0]       coeff_4_i,
    input  wire signed [47:0]       pci_i,
    output wire signed [47:0]       p_o
);

localparam integer COEFF_REG_STAGES = 1;

wire signed [24:0] pixel_0_to_1;
wire signed [24:0] pixel_1_to_2;
wire signed [24:0] pixel_2_to_3;
wire signed [24:0] pixel_3_to_4;
wire signed [24:0] pixel_4_unused;
wire signed [47:0] p_0;
wire signed [47:0] p_1;
wire signed [47:0] p_2;
wire signed [47:0] p_3;
wire signed [47:0] p_4;

dsp_25x18_passthrough #(
    .A_REG(1),
    .B_REG(COEFF_REG_STAGES)
) dsp_cell_0 (
    .clk(clk),
    .a(pixel_in),
    .b(coeff_0_i),
    .pci(pci_i),
    .a_passthrough(pixel_0_to_1),
    .p(p_0)
);

dsp_25x18_passthrough #(
    .A_REG(2),
    .B_REG(COEFF_REG_STAGES)
) dsp_cell_1 (
    .clk(clk),
    .a(pixel_0_to_1),
    .b(coeff_1_i),
    .pci(p_0),
    .a_passthrough(pixel_1_to_2),
    .p(p_1)
);

dsp_25x18_passthrough #(
    .A_REG(2),
    .B_REG(COEFF_REG_STAGES)
) dsp_cell_2 (
    .clk(clk),
    .a(pixel_1_to_2),
    .b(coeff_2_i),
    .pci(p_1),
    .a_passthrough(pixel_2_to_3),
    .p(p_2)
);

dsp_25x18_passthrough #(
    .A_REG(2),
    .B_REG(COEFF_REG_STAGES)
) dsp_cell_3 (
    .clk(clk),
    .a(pixel_2_to_3),
    .b(coeff_3_i),
    .pci(p_2),
    .a_passthrough(pixel_3_to_4),
    .p(p_3)
);

dsp_25x18_passthrough #(
    .A_REG(2),
    .B_REG(COEFF_REG_STAGES)
) dsp_cell_4 (
    .clk(clk),
    .a(pixel_3_to_4),
    .b(coeff_4_i),
    .pci(p_3),
    .a_passthrough(pixel_4_unused),
    .p(p_4)
);

assign p_o = p_4;

endmodule

/*
 * full 5x5 window from the 5 rows
 */
module FIR_filter_5x5 #(
    parameter integer CTRL_DELAY = 12
)(
    input  wire                     clk,
    input  wire                     pixel_valid_i,
    input  wire                     h_sync_i,
    input  wire                     v_sync_i,
    input  wire signed [24:0]       pixel_0_i,
    input  wire signed [24:0]       pixel_1_i,
    input  wire signed [24:0]       pixel_2_i,
    input  wire signed [24:0]       pixel_3_i,
    input  wire signed [24:0]       pixel_4_i,
    input  wire signed [15:0]       coeff_00_i,
    input  wire signed [15:0]       coeff_01_i,
    input  wire signed [15:0]       coeff_02_i,
    input  wire signed [15:0]       coeff_03_i,
    input  wire signed [15:0]       coeff_04_i,
    input  wire signed [15:0]       coeff_10_i,
    input  wire signed [15:0]       coeff_11_i,
    input  wire signed [15:0]       coeff_12_i,
    input  wire signed [15:0]       coeff_13_i,
    input  wire signed [15:0]       coeff_14_i,
    input  wire signed [15:0]       coeff_20_i,
    input  wire signed [15:0]       coeff_21_i,
    input  wire signed [15:0]       coeff_22_i,
    input  wire signed [15:0]       coeff_23_i,
    input  wire signed [15:0]       coeff_24_i,
    input  wire signed [15:0]       coeff_30_i,
    input  wire signed [15:0]       coeff_31_i,
    input  wire signed [15:0]       coeff_32_i,
    input  wire signed [15:0]       coeff_33_i,
    input  wire signed [15:0]       coeff_34_i,
    input  wire signed [15:0]       coeff_40_i,
    input  wire signed [15:0]       coeff_41_i,
    input  wire signed [15:0]       coeff_42_i,
    input  wire signed [15:0]       coeff_43_i,
    input  wire signed [15:0]       coeff_44_i,
    output reg  [7:0]               fir_out_sat,
    output wire                     pixel_valid_out,
    output wire                     h_sync_out,
    output wire                     v_sync_out
);

wire signed [47:0] row0_p;
wire signed [47:0] row1_p;
wire signed [47:0] row2_p;
wire signed [47:0] row3_p;
wire signed [47:0] row4_p;
wire signed [47:0] row_sum_total;
wire signed [17:0] coeff_00_ext;
wire signed [17:0] coeff_01_ext;
wire signed [17:0] coeff_02_ext;
wire signed [17:0] coeff_03_ext;
wire signed [17:0] coeff_04_ext;
wire signed [17:0] coeff_10_ext;
wire signed [17:0] coeff_11_ext;
wire signed [17:0] coeff_12_ext;
wire signed [17:0] coeff_13_ext;
wire signed [17:0] coeff_14_ext;
wire signed [17:0] coeff_20_ext;
wire signed [17:0] coeff_21_ext;
wire signed [17:0] coeff_22_ext;
wire signed [17:0] coeff_23_ext;
wire signed [17:0] coeff_24_ext;
wire signed [17:0] coeff_30_ext;
wire signed [17:0] coeff_31_ext;
wire signed [17:0] coeff_32_ext;
wire signed [17:0] coeff_33_ext;
wire signed [17:0] coeff_34_ext;
wire signed [17:0] coeff_40_ext;
wire signed [17:0] coeff_41_ext;
wire signed [17:0] coeff_42_ext;
wire signed [17:0] coeff_43_ext;
wire signed [17:0] coeff_44_ext;


/*
 * Coeffs are 16 bit bit dsp B reg is 18, extend for deterministic behaviour
 */
assign coeff_00_ext = {{2{coeff_00_i[15]}}, coeff_00_i};
assign coeff_01_ext = {{2{coeff_01_i[15]}}, coeff_01_i};
assign coeff_02_ext = {{2{coeff_02_i[15]}}, coeff_02_i};
assign coeff_03_ext = {{2{coeff_03_i[15]}}, coeff_03_i};
assign coeff_04_ext = {{2{coeff_04_i[15]}}, coeff_04_i};
assign coeff_10_ext = {{2{coeff_10_i[15]}}, coeff_10_i};
assign coeff_11_ext = {{2{coeff_11_i[15]}}, coeff_11_i};
assign coeff_12_ext = {{2{coeff_12_i[15]}}, coeff_12_i};
assign coeff_13_ext = {{2{coeff_13_i[15]}}, coeff_13_i};
assign coeff_14_ext = {{2{coeff_14_i[15]}}, coeff_14_i};
assign coeff_20_ext = {{2{coeff_20_i[15]}}, coeff_20_i};
assign coeff_21_ext = {{2{coeff_21_i[15]}}, coeff_21_i};
assign coeff_22_ext = {{2{coeff_22_i[15]}}, coeff_22_i};
assign coeff_23_ext = {{2{coeff_23_i[15]}}, coeff_23_i};
assign coeff_24_ext = {{2{coeff_24_i[15]}}, coeff_24_i};
assign coeff_30_ext = {{2{coeff_30_i[15]}}, coeff_30_i};
assign coeff_31_ext = {{2{coeff_31_i[15]}}, coeff_31_i};
assign coeff_32_ext = {{2{coeff_32_i[15]}}, coeff_32_i};
assign coeff_33_ext = {{2{coeff_33_i[15]}}, coeff_33_i};
assign coeff_34_ext = {{2{coeff_34_i[15]}}, coeff_34_i};
assign coeff_40_ext = {{2{coeff_40_i[15]}}, coeff_40_i};
assign coeff_41_ext = {{2{coeff_41_i[15]}}, coeff_41_i};
assign coeff_42_ext = {{2{coeff_42_i[15]}}, coeff_42_i};
assign coeff_43_ext = {{2{coeff_43_i[15]}}, coeff_43_i};
assign coeff_44_ext = {{2{coeff_44_i[15]}}, coeff_44_i};


/*
 * Delay line for valid and sync
 */
generate
if (CTRL_DELAY > 0) begin : gen_ctrl_delay
    reg valid_delay [0:CTRL_DELAY-1];
    reg hsync_delay [0:CTRL_DELAY-1];
    reg vsync_delay [0:CTRL_DELAY-1];
    integer ctrl_idx;

    always @(posedge clk) begin
        for (ctrl_idx = 0; ctrl_idx < CTRL_DELAY; ctrl_idx = ctrl_idx + 1) begin
            valid_delay[ctrl_idx] <= (ctrl_idx == 0) ? pixel_valid_i : valid_delay[ctrl_idx-1];
            hsync_delay[ctrl_idx] <= (ctrl_idx == 0) ? h_sync_i      : hsync_delay[ctrl_idx-1];
            vsync_delay[ctrl_idx] <= (ctrl_idx == 0) ? v_sync_i      : vsync_delay[ctrl_idx-1];
        end
    end

    assign pixel_valid_out = valid_delay[CTRL_DELAY-1];
    assign h_sync_out      = hsync_delay[CTRL_DELAY-1];
    assign v_sync_out      = vsync_delay[CTRL_DELAY-1];
end else begin : gen_ctrl_passthrough
    assign pixel_valid_out = pixel_valid_i;
    assign h_sync_out      = h_sync_i;
    assign v_sync_out      = v_sync_i;
end
endgenerate

fir_row_5_cells row_0 (
    .clk(clk),
    .pixel_in(pixel_0_i),
    .coeff_0_i(coeff_00_ext),
    .coeff_1_i(coeff_01_ext),
    .coeff_2_i(coeff_02_ext),
    .coeff_3_i(coeff_03_ext),
    .coeff_4_i(coeff_04_ext),
    .pci_i(48'sd0),
    .p_o(row0_p)
);

fir_row_5_cells row_1 (
    .clk(clk),
    .pixel_in(pixel_1_i),
    .coeff_0_i(coeff_10_ext),
    .coeff_1_i(coeff_11_ext),
    .coeff_2_i(coeff_12_ext),
    .coeff_3_i(coeff_13_ext),
    .coeff_4_i(coeff_14_ext),
    .pci_i(48'sd0),
    .p_o(row1_p)
);

fir_row_5_cells row_2 (
    .clk(clk),
    .pixel_in(pixel_2_i),
    .coeff_0_i(coeff_20_ext),
    .coeff_1_i(coeff_21_ext),
    .coeff_2_i(coeff_22_ext),
    .coeff_3_i(coeff_23_ext),
    .coeff_4_i(coeff_24_ext),
    .pci_i(48'sd0),
    .p_o(row2_p)
);

fir_row_5_cells row_3 (
    .clk(clk),
    .pixel_in(pixel_3_i),
    .coeff_0_i(coeff_30_ext),
    .coeff_1_i(coeff_31_ext),
    .coeff_2_i(coeff_32_ext),
    .coeff_3_i(coeff_33_ext),
    .coeff_4_i(coeff_34_ext),
    .pci_i(48'sd0),
    .p_o(row3_p)
);

fir_row_5_cells row_4 (
    .clk(clk),
    .pixel_in(pixel_4_i),
    .coeff_0_i(coeff_40_ext),
    .coeff_1_i(coeff_41_ext),
    .coeff_2_i(coeff_42_ext),
    .coeff_3_i(coeff_43_ext),
    .coeff_4_i(coeff_44_ext),
    .pci_i(48'sd0),
    .p_o(row4_p)
);

// First the five horizontal FIR rows are evaluated independently,
// then their partial sums are accumulated into the final 5x5 result.
assign row_sum_total = row0_p + row1_p + row2_p + row3_p + row4_p;

// Drop the fractional Q8.8 part before clamping the result to 8-bit range.
always @(posedge clk) begin
    if (row_sum_total[47]) begin
        fir_out_sat <= 8'd0;
    end else if (|row_sum_total[46:16]) begin
        fir_out_sat <= 8'd255;
    end else begin
        fir_out_sat <= row_sum_total[15:8];
    end
end

endmodule
