//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Mon Jun  8 16:22:22 2026
//Host        : DESKTOP-H73H9I1 running 64-bit major release  (build 9200)
//Command     : generate_target cpu_hdmi_system_wrapper.bd
//Design      : cpu_hdmi_system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module cpu_hdmi_system_wrapper
   (clk_in,
    coeff_out_0,
    rstbtn,
    uart_rx,
    uart_tx);
  input clk_in;
  output [399:0]coeff_out_0;
  input rstbtn;
  input uart_rx;
  output uart_tx;

  wire clk_in;
  wire [399:0]coeff_out_0;
  wire rstbtn;
  wire uart_rx;
  wire uart_tx;

  cpu_hdmi_system cpu_hdmi_system_i
       (.clk_in(clk_in),
        .coeff_out_0(coeff_out_0),
        .rstbtn(rstbtn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx));
endmodule
