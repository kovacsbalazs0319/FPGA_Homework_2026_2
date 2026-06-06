`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2026 18:20:18
// Design Name: 
// Module Name: tb_fir_filter
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


module tb_fir_filter(
);

reg clk;
reg pixel_valid_i;
reg h_sync_i;
reg v_sync_i;

reg signed [24:0] pixel_0_i;
reg signed [24:0] pixel_1_i;
reg signed [24:0] pixel_2_i;
reg signed [24:0] pixel_3_i;
reg signed [24:0] pixel_4_i;

reg signed [15:0] coeff_00_i;
reg signed [15:0] coeff_01_i;
reg signed [15:0] coeff_02_i;
reg signed [15:0] coeff_03_i;
reg signed [15:0] coeff_04_i;
reg signed [15:0] coeff_10_i;
reg signed [15:0] coeff_11_i;
reg signed [15:0] coeff_12_i;
reg signed [15:0] coeff_13_i;
reg signed [15:0] coeff_14_i;
reg signed [15:0] coeff_20_i;
reg signed [15:0] coeff_21_i;
reg signed [15:0] coeff_22_i;
reg signed [15:0] coeff_23_i;
reg signed [15:0] coeff_24_i;
reg signed [15:0] coeff_30_i;
reg signed [15:0] coeff_31_i;
reg signed [15:0] coeff_32_i;
reg signed [15:0] coeff_33_i;
reg signed [15:0] coeff_34_i;
reg signed [15:0] coeff_40_i;
reg signed [15:0] coeff_41_i;
reg signed [15:0] coeff_42_i;
reg signed [15:0] coeff_43_i;
reg signed [15:0] coeff_44_i;

wire [7:0] fir_out_sat;
wire pixel_valid_o;
wire h_sync_o;
wire v_sync_o;

FIR_filter_5x5 dut (
    .clk(clk),
    .pixel_valid_i(pixel_valid_i),
    .h_sync_i(h_sync_i),
    .v_sync_i(v_sync_i),
    .pixel_0_i(pixel_0_i),
    .pixel_1_i(pixel_1_i),
    .pixel_2_i(pixel_2_i),
    .pixel_3_i(pixel_3_i),
    .pixel_4_i(pixel_4_i),
    .coeff_00_i(coeff_00_i),
    .coeff_01_i(coeff_01_i),
    .coeff_02_i(coeff_02_i),
    .coeff_03_i(coeff_03_i),
    .coeff_04_i(coeff_04_i),
    .coeff_10_i(coeff_10_i),
    .coeff_11_i(coeff_11_i),
    .coeff_12_i(coeff_12_i),
    .coeff_13_i(coeff_13_i),
    .coeff_14_i(coeff_14_i),
    .coeff_20_i(coeff_20_i),
    .coeff_21_i(coeff_21_i),
    .coeff_22_i(coeff_22_i),
    .coeff_23_i(coeff_23_i),
    .coeff_24_i(coeff_24_i),
    .coeff_30_i(coeff_30_i),
    .coeff_31_i(coeff_31_i),
    .coeff_32_i(coeff_32_i),
    .coeff_33_i(coeff_33_i),
    .coeff_34_i(coeff_34_i),
    .coeff_40_i(coeff_40_i),
    .coeff_41_i(coeff_41_i),
    .coeff_42_i(coeff_42_i),
    .coeff_43_i(coeff_43_i),
    .coeff_44_i(coeff_44_i),
    .fir_out_sat(fir_out_sat),
    .pixel_valid_o(pixel_valid_o),
    .h_sync_o(h_sync_o),
    .v_sync_o(v_sync_o)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
end

task clear_coeffs;
begin
    coeff_00_i = 16'sd0; coeff_01_i = 16'sd0; coeff_02_i = 16'sd0; coeff_03_i = 16'sd0; coeff_04_i = 16'sd0;
    coeff_10_i = 16'sd0; coeff_11_i = 16'sd0; coeff_12_i = 16'sd0; coeff_13_i = 16'sd0; coeff_14_i = 16'sd0;
    coeff_20_i = 16'sd0; coeff_21_i = 16'sd0; coeff_22_i = 16'sd0; coeff_23_i = 16'sd0; coeff_24_i = 16'sd0;
    coeff_30_i = 16'sd0; coeff_31_i = 16'sd0; coeff_32_i = 16'sd0; coeff_33_i = 16'sd0; coeff_34_i = 16'sd0;
    coeff_40_i = 16'sd0; coeff_41_i = 16'sd0; coeff_42_i = 16'sd0; coeff_43_i = 16'sd0; coeff_44_i = 16'sd0;
end
endtask

task set_pixels;
    input signed [24:0] p0;
    input signed [24:0] p1;
    input signed [24:0] p2;
    input signed [24:0] p3;
    input signed [24:0] p4;
begin
    pixel_0_i = p0;
    pixel_1_i = p1;
    pixel_2_i = p2;
    pixel_3_i = p3;
    pixel_4_i = p4;
end
endtask

task wait_cycles;
    input integer num_cycles;
    integer idx;
begin
    for (idx = 0; idx < num_cycles; idx = idx + 1)
        @(posedge clk);
end
endtask

task check_output;
    input [7:0]         expected;
    input [255:0]       test_name;
begin
    if (fir_out_sat !== expected) begin
        $display("[%0t] FAIL: %0s expected=%0d got=%0d", $time, test_name, expected, fir_out_sat);
        $stop;
    end else begin
        $display("[%0t] PASS: %0s expected=%0d got=%0d", $time, test_name, expected, fir_out_sat);
    end
end
endtask

initial begin
    pixel_valid_i = 1'b1;
    h_sync_i      = 1'b0;
    v_sync_i      = 1'b0;
    set_pixels(25'sd0, 25'sd0, 25'sd0, 25'sd0, 25'sd0);
    clear_coeffs();

    wait_cycles(2);

    // Test 1:
    // Only the last coefficient of each row is 1, so the implemented cascade
    // should produce the sum of the five row inputs at steady state.
    set_pixels(25'sd1, 25'sd2, 25'sd3, 25'sd4, 25'sd5);
    coeff_04_i = 16'sd256;
    coeff_14_i = 16'sd256;
    coeff_24_i = 16'sd256;
    coeff_34_i = 16'sd256;
    coeff_44_i = 16'sd256;

    wait_cycles(40);
    check_output(8'd15, "unit coefficients on last column");

    // Test 2:
    // Mixed signed coefficients to verify add/subtract behavior.
    clear_coeffs();
    set_pixels(25'sd10, 25'sd20, 25'sd30, 25'sd40, 25'sd50);
    coeff_04_i = 16'sd512;
    coeff_14_i = -16'sd256;
    coeff_24_i = 16'sd768;
    coeff_34_i = 16'sd0;
    coeff_44_i = 16'sd1024;

    wait_cycles(40);
    check_output(8'd255, "signed coefficient cascade");

    // Test 3:
    // All coefficients zero, output must decay back to zero after the pipeline clears.
    clear_coeffs();
    set_pixels(25'sd7, 25'sd8, 25'sd9, 25'sd10, 25'sd11);

    wait_cycles(40);
    check_output(8'd0, "all zero coefficients");

    $display("[%0t] All FIR filter tests passed.", $time);
    $finish;
end

endmodule
