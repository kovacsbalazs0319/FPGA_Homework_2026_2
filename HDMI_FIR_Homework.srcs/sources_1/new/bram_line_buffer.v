`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12.05.2026 13:11:27
// Design Name:
// Module Name: bram_line_buffer
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//   High-level 4-stage BRAM line buffer chain.
//
//   Each stage uses a read-first line RAM. Because the data read from a BRAM
//   address becomes valid one clock later, the address and valid/control signals
//   are delayed by one extra cycle per stage to keep the column indices aligned.
//
// Dependencies:
//
// Revision:
// Revision 0.02 - Reworked into a pipelined 4-stage line buffer chain
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

/*
 * Internal single-line storage primitive.
 *
 * Memory behavior:
 *   Read-first mode is required:
 *   dout receives the previous content at addr before din overwrites it.
 */
module bram_line_buffer_ram#(

    parameter DATA_WIDTH = 8,
    parameter LINE_WIDTH = 2048,
    parameter ADDR_WIDTH = 11

)(

    input  wire                  clk,
    input  wire                  en,

    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

reg [DATA_WIDTH-1:0] mem [0:LINE_WIDTH-1];
integer init_idx;

initial begin
    for (init_idx = 0; init_idx < LINE_WIDTH; init_idx = init_idx + 1)
        mem[init_idx] = {DATA_WIDTH{1'b0}};
    dout = {DATA_WIDTH{1'b0}};
end

always @(posedge clk) begin
    if (en) begin
        dout      <= mem[addr];
        mem[addr] <= din;
    end
end

endmodule

/*
 * High-level 4-stage BRAM line buffer chain.
 *
 * Inputs:
 *   pixel_in     - incoming pixel stream
 *   pixel_valid  - high when pixel_in is valid and should advance the column
 *   h_sync       - start-of-line marker, resets the column counter to 0
 *
 * The externally visible outputs are aligned to the deepest BRAM stage so the
 * five vertical taps can be consumed together by the downstream FIR logic.
 */
module bram_line_buffer#(

    parameter DATA_WIDTH = 8,
    parameter LINE_WIDTH = 2048,
    parameter ADDR_WIDTH = 11

)(

    input  wire                  clk,
    input  wire                  rst,
    input  wire [DATA_WIDTH-1:0] pixel_in,
    input  wire                  pixel_valid,
    input  wire                  h_sync,
    input  wire                  v_sync,

    output wire [DATA_WIDTH-1:0] current_pixel,
    output wire [DATA_WIDTH-1:0] line_1_pixel,
    output wire [DATA_WIDTH-1:0] line_2_pixel,
    output wire [DATA_WIDTH-1:0] line_3_pixel,
    output wire [DATA_WIDTH-1:0] line_4_pixel,

    output wire                  pixel_valid_out,
    output wire                  h_sync_out,
    output wire                  v_sync_out
);

wire [ADDR_WIDTH-1:0] line_width_minus_one;
assign line_width_minus_one = LINE_WIDTH - 1;

reg  [ADDR_WIDTH-1:0] column_addr;
wire [ADDR_WIDTH-1:0] addr_current;
wire                  stream_advance;
wire [DATA_WIDTH-1:0] pixel_or_black;

assign stream_advance = 1'b1;
assign pixel_or_black = pixel_valid ? pixel_in : {DATA_WIDTH{1'b0}};

reg  [ADDR_WIDTH-1:0] addr_delayed1;
reg  [ADDR_WIDTH-1:0] addr_delayed2;
reg  [ADDR_WIDTH-1:0] addr_delayed3;

reg                   valid_delayed1;
reg                   valid_delayed2;
reg                   valid_delayed3;

reg                   pixel_valid_d1;
reg                   pixel_valid_d2;
reg                   pixel_valid_d3;
reg                   pixel_valid_d4;

reg                   h_sync_d1;
reg                   h_sync_d2;
reg                   h_sync_d3;
reg                   h_sync_d4;

reg                   v_sync_d1;
reg                   v_sync_d2;
reg                   v_sync_d3;
reg                   v_sync_d4;

wire [DATA_WIDTH-1:0] line_1_bram_pixel;
wire [DATA_WIDTH-1:0] line_2_bram_pixel;
wire [DATA_WIDTH-1:0] line_3_bram_pixel;
wire [DATA_WIDTH-1:0] line_4_bram_pixel;

reg  [DATA_WIDTH-1:0] current_pixel_delayed1;
reg  [DATA_WIDTH-1:0] current_pixel_delayed2;
reg  [DATA_WIDTH-1:0] current_pixel_delayed3;
reg  [DATA_WIDTH-1:0] current_pixel_delayed4;

reg  [DATA_WIDTH-1:0] line_1_pixel_delayed1;
reg  [DATA_WIDTH-1:0] line_1_pixel_delayed2;
reg  [DATA_WIDTH-1:0] line_1_pixel_delayed3;

reg  [DATA_WIDTH-1:0] line_2_pixel_delayed1;
reg  [DATA_WIDTH-1:0] line_2_pixel_delayed2;

reg  [DATA_WIDTH-1:0] line_3_pixel_delayed1;

// Force address 0 on the first pixel of a new line so the write/read pair
// starts from column 0 immediately, independent of the previously stored count.
assign addr_current = h_sync ? {ADDR_WIDTH{1'b0}} : column_addr;

always @(posedge clk) begin
    if (rst) begin
        column_addr     <= {ADDR_WIDTH{1'b0}};

        addr_delayed1   <= {ADDR_WIDTH{1'b0}};
        addr_delayed2   <= {ADDR_WIDTH{1'b0}};
        addr_delayed3   <= {ADDR_WIDTH{1'b0}};

        valid_delayed1  <= 1'b0;
        valid_delayed2  <= 1'b0;
        valid_delayed3  <= 1'b0;

        pixel_valid_d1  <= 1'b0;
        pixel_valid_d2  <= 1'b0;
        pixel_valid_d3  <= 1'b0;
        pixel_valid_d4  <= 1'b0;

        h_sync_d1       <= 1'b0;
        h_sync_d2       <= 1'b0;
        h_sync_d3       <= 1'b0;
        h_sync_d4       <= 1'b0;

        v_sync_d1       <= 1'b0;
        v_sync_d2       <= 1'b0;
        v_sync_d3       <= 1'b0;
        v_sync_d4       <= 1'b0;

        current_pixel_delayed1 <= {DATA_WIDTH{1'b0}};
        current_pixel_delayed2 <= {DATA_WIDTH{1'b0}};
        current_pixel_delayed3 <= {DATA_WIDTH{1'b0}};
        current_pixel_delayed4 <= {DATA_WIDTH{1'b0}};

        line_1_pixel_delayed1 <= {DATA_WIDTH{1'b0}};
        line_1_pixel_delayed2 <= {DATA_WIDTH{1'b0}};
        line_1_pixel_delayed3 <= {DATA_WIDTH{1'b0}};

        line_2_pixel_delayed1 <= {DATA_WIDTH{1'b0}};
        line_2_pixel_delayed2 <= {DATA_WIDTH{1'b0}};

        line_3_pixel_delayed1 <= {DATA_WIDTH{1'b0}};

    end else begin
        if (h_sync) begin
            column_addr <= {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
        end else if (stream_advance) begin
            if (column_addr == line_width_minus_one) begin
                column_addr <= {ADDR_WIDTH{1'b0}};
            end else begin
                column_addr <= column_addr + 1'b1;
            end
        end

        addr_delayed1  <= addr_current;
        addr_delayed2  <= addr_delayed1;
        addr_delayed3  <= addr_delayed2;

        valid_delayed1 <= stream_advance;
        valid_delayed2 <= valid_delayed1;
        valid_delayed3 <= valid_delayed2;

        pixel_valid_d1 <= pixel_valid;
        pixel_valid_d2 <= pixel_valid_d1;
        pixel_valid_d3 <= pixel_valid_d2;
        pixel_valid_d4 <= pixel_valid_d3;

        h_sync_d1      <= h_sync;
        h_sync_d2      <= h_sync_d1;
        h_sync_d3      <= h_sync_d2;
        h_sync_d4      <= h_sync_d3;

        v_sync_d1      <= v_sync;
        v_sync_d2      <= v_sync_d1;
        v_sync_d3      <= v_sync_d2;
        v_sync_d4      <= v_sync_d3;

        current_pixel_delayed1 <= pixel_or_black;
        current_pixel_delayed2 <= current_pixel_delayed1;
        current_pixel_delayed3 <= current_pixel_delayed2;
        current_pixel_delayed4 <= current_pixel_delayed3;

        line_1_pixel_delayed1 <= line_1_bram_pixel;
        line_1_pixel_delayed2 <= line_1_pixel_delayed1;
        line_1_pixel_delayed3 <= line_1_pixel_delayed2;

        line_2_pixel_delayed1 <= line_2_bram_pixel;
        line_2_pixel_delayed2 <= line_2_pixel_delayed1;

        line_3_pixel_delayed1 <= line_3_bram_pixel;
    end
end

bram_line_buffer_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) bram_line_0 (
    .clk(clk),
    .en(stream_advance),
    .addr(addr_current),
    .din(pixel_or_black),
    .dout(line_1_bram_pixel)
);

bram_line_buffer_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) bram_line_1 (
    .clk(clk),
    .en(valid_delayed1),
    .addr(addr_delayed1),
    .din(line_1_bram_pixel),
    .dout(line_2_bram_pixel)
);

bram_line_buffer_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) bram_line_2 (
    .clk(clk),
    .en(valid_delayed2),
    .addr(addr_delayed2),
    .din(line_2_bram_pixel),
    .dout(line_3_bram_pixel)
);

bram_line_buffer_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .LINE_WIDTH(LINE_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) bram_line_3 (
    .clk(clk),
    .en(valid_delayed3),
    .addr(addr_delayed3),
    .din(line_3_bram_pixel),
    .dout(line_4_bram_pixel)
);

assign current_pixel    = current_pixel_delayed4;
assign line_1_pixel     = line_1_pixel_delayed3;
assign line_2_pixel     = line_2_pixel_delayed2;
assign line_3_pixel     = line_3_pixel_delayed1;
assign line_4_pixel     = line_4_bram_pixel;

assign pixel_valid_out  = pixel_valid_d4;
assign h_sync_out       = h_sync_d4;
assign v_sync_out       = v_sync_d4;

endmodule
