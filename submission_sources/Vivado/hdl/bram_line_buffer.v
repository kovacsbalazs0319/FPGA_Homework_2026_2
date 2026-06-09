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
//   Four-stage BRAM line buffer for building the vertical 5-pixel window
//   required by the downstream 5x5 FIR filter.
//
// Dependencies:
//
// Revision:
// Revision 0.02 - Reworked into a pipelined 4-stage line buffer chain
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

/*
 * Single-line storage primitive.
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

/*
 * Initially set BRAMs to 0 for deterministic behaviour
 */
initial begin
    for (init_idx = 0; init_idx < LINE_WIDTH; init_idx = init_idx + 1)
        mem[init_idx] = {DATA_WIDTH{1'b0}};
    dout = {DATA_WIDTH{1'b0}};
end

always @(posedge clk) begin
    if (en) begin
        // Read First mode
        dout      <= mem[addr];
        mem[addr] <= din;
    end
end

endmodule

/*
 * Four cascaded line memories store the previous 4 image rows.
 *
 * The visible outputs are delayed so that current_pixel and the four buffered
 * lines all correspond to the same column when the FIR consumes them.
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

reg  [ADDR_WIDTH-1:0] column_addr;
wire [ADDR_WIDTH-1:0] addr_current;
wire                  write_enable;
wire [DATA_WIDTH-1:0] pixel_or_black;

// The BRAM chain advances every clock; blanked pixels are written as zeros.
assign write_enable = 1'b1;
assign pixel_or_black = pixel_valid ? pixel_in : {DATA_WIDTH{1'b0}};

reg  [ADDR_WIDTH-1:0] addr_delayed1;
reg  [ADDR_WIDTH-1:0] addr_delayed2;
reg  [ADDR_WIDTH-1:0] addr_delayed3;

reg                   write_enable_delayed1;
reg                   write_enable_delayed2;
reg                   write_enable_delayed3;

reg                   pixel_valid_d1;
reg                   pixel_valid_d2;
reg                   pixel_valid_d3;
reg                   pixel_valid_d4;

reg                   h_sync_d1;
reg                   h_sync_d2;
reg                   h_sync_d3;
reg                   h_sync_d4;
reg                   h_sync_prev;

reg                   v_sync_d1;
reg                   v_sync_d2;
reg                   v_sync_d3;
reg                   v_sync_d4;

// Raw outputs of the four BRAM stages before final tap alignment.
wire [DATA_WIDTH-1:0] line_1_bram_pixel;
wire [DATA_WIDTH-1:0] line_2_bram_pixel;
wire [DATA_WIDTH-1:0] line_3_bram_pixel;
wire [DATA_WIDTH-1:0] line_4_bram_pixel;

// Internal delay chain for aligning the current input pixel to the deepest tap.
reg  [DATA_WIDTH-1:0] current_pixel_delayed1;
reg  [DATA_WIDTH-1:0] current_pixel_delayed2;
reg  [DATA_WIDTH-1:0] current_pixel_delayed3;
reg  [DATA_WIDTH-1:0] current_pixel_delayed4;

// Extra alignment registers for the shallower buffered lines.
reg  [DATA_WIDTH-1:0] line_1_pixel_delayed1;
reg  [DATA_WIDTH-1:0] line_1_pixel_delayed2;
reg  [DATA_WIDTH-1:0] line_1_pixel_delayed3;

reg  [DATA_WIDTH-1:0] line_2_pixel_delayed1;
reg  [DATA_WIDTH-1:0] line_2_pixel_delayed2;

reg  [DATA_WIDTH-1:0] line_3_pixel_delayed1;
wire                  start_of_line;

// Restart the circular addressing from column 0 on each new line.
assign start_of_line = h_sync & ~h_sync_prev;
assign addr_current = start_of_line ? {ADDR_WIDTH{1'b0}} : column_addr;

always @(posedge clk) begin
    if (rst) begin
        column_addr     <= {ADDR_WIDTH{1'b0}};

        addr_delayed1   <= {ADDR_WIDTH{1'b0}};
        addr_delayed2   <= {ADDR_WIDTH{1'b0}};
        addr_delayed3   <= {ADDR_WIDTH{1'b0}};

        write_enable_delayed1  <= 1'b0;
        write_enable_delayed2  <= 1'b0;
        write_enable_delayed3  <= 1'b0;

        pixel_valid_d1  <= 1'b0;
        pixel_valid_d2  <= 1'b0;
        pixel_valid_d3  <= 1'b0;
        pixel_valid_d4  <= 1'b0;

        h_sync_d1       <= 1'b0;
        h_sync_d2       <= 1'b0;
        h_sync_d3       <= 1'b0;
        h_sync_d4       <= 1'b0;
        h_sync_prev     <= 1'b0;

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
        h_sync_prev <= h_sync;

        if (start_of_line) begin
            column_addr <= {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
        end else if (write_enable) begin
            if (column_addr == LINE_WIDTH - 1) begin
                column_addr <= {ADDR_WIDTH{1'b0}};
            end else begin
                column_addr <= column_addr + 1'b1;
            end
        end

        // Each later BRAM stage reads the same column one cycle later.
        addr_delayed1  <= addr_current;
        addr_delayed2  <= addr_delayed1;
        addr_delayed3  <= addr_delayed2;

        // The delayed enables keep the BRAM pipeline aligned with read-first latency.
        write_enable_delayed1 <= write_enable;
        write_enable_delayed2 <= write_enable_delayed1;
        write_enable_delayed3 <= write_enable_delayed2;

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

        // Match the current input pixel to the latency of the deepest line output.
        current_pixel_delayed1 <= pixel_or_black;
        current_pixel_delayed2 <= current_pixel_delayed1;
        current_pixel_delayed3 <= current_pixel_delayed2;
        current_pixel_delayed4 <= current_pixel_delayed3;

        // The buffered rows need progressively fewer extra delay stages.
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
    .en(write_enable),
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
    .en(write_enable_delayed1),
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
    .en(write_enable_delayed2),
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
    .en(write_enable_delayed3),
    .addr(addr_delayed3),
    .din(line_3_bram_pixel),
    .dout(line_4_bram_pixel)
);

// Output alignment:
//   current_pixel -> 4 extra cycles
//   line_1_pixel  -> 3 extra cycles
//   line_2_pixel  -> 2 extra cycles
//   line_3_pixel  -> 1 extra cycle
//   line_4_pixel  -> no extra delay
assign current_pixel    = current_pixel_delayed4;
assign line_1_pixel     = line_1_pixel_delayed3;
assign line_2_pixel     = line_2_pixel_delayed2;
assign line_3_pixel     = line_3_pixel_delayed1;
assign line_4_pixel     = line_4_bram_pixel;

// Control signals are delayed by the same 4 cycles as the visible data path.
assign pixel_valid_out  = pixel_valid_d4;
assign h_sync_out       = h_sync_d4;
assign v_sync_out       = v_sync_d4;

endmodule
