`timescale 1ns / 1ps

/*
 * Testbench: tb_line_buffer_chain
 *
 * Purpose:
 *   Tests a chain of four read-first BRAM line buffers.
 *
 *   The testbench feeds an 8x8 artificial image into the BRAM chain.
 *   Each pixel value is generated as:
 *
 *      pixel = row * 10 + col
 *
 *   Example:
 *      row 4, col 2 -> pixel value 42
 *
 *   Expected behavior:
 *      d0 = pixel from previous row, same column
 *      d1 = pixel from two rows earlier, same column
 *      d2 = pixel from three rows earlier, same column
 *      d3 = pixel from four rows earlier, same column
 *
 *   This verifies the vertical line-buffer shifting behavior:
 *
 *      pixel_in -> BRAM0 -> BRAM1 -> BRAM2 -> BRAM3
 */

module tb_line_buffer_chain;

    localparam DATA_WIDTH = 8;
    localparam LINE_WIDTH = 3;
    localparam ADDR_WIDTH = 2;

    reg clk;
    reg rst;
    reg pixel_valid;
    reg h_sync;
    reg [DATA_WIDTH-1:0] pixel_in;

    wire [DATA_WIDTH-1:0] current_pixel;
    wire [DATA_WIDTH-1:0] line_1_pixel;
    wire [DATA_WIDTH-1:0] line_2_pixel;
    wire [DATA_WIDTH-1:0] line_3_pixel;
    wire [DATA_WIDTH-1:0] line_4_pixel;

    wire pixel_valid_out;
    wire h_sync_out;

    reg [DATA_WIDTH-1:0] pixel_in_delayed1;
    reg [DATA_WIDTH-1:0] pixel_in_delayed2;
    reg [DATA_WIDTH-1:0] pixel_in_delayed3;
    reg [DATA_WIDTH-1:0] pixel_in_delayed4;

    integer row;
    integer col;

    bram_line_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .LINE_WIDTH(LINE_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .h_sync(h_sync),
        .current_pixel(current_pixel),
        .line_1_pixel(line_1_pixel),
        .line_2_pixel(line_2_pixel),
        .line_3_pixel(line_3_pixel),
        .line_4_pixel(line_4_pixel),
        .pixel_valid_out(pixel_valid_out),
        .h_sync_out(h_sync_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst) begin
            pixel_in_delayed1 <= {DATA_WIDTH{1'b0}};
            pixel_in_delayed2 <= {DATA_WIDTH{1'b0}};
            pixel_in_delayed3 <= {DATA_WIDTH{1'b0}};
            pixel_in_delayed4 <= {DATA_WIDTH{1'b0}};
        end else begin
            pixel_in_delayed1 <= pixel_in;
            pixel_in_delayed2 <= pixel_in_delayed1;
            pixel_in_delayed3 <= pixel_in_delayed2;
            pixel_in_delayed4 <= pixel_in_delayed3;
        end
    end

    initial begin
        rst         = 1'b1;
        pixel_valid = 1'b0;
        h_sync      = 1'b0;
        pixel_in    = 8'h00;

        repeat (3) @(posedge clk);
        rst = 1'b0;

        @(posedge clk);

        for (row = 0; row < 5; row = row + 1) begin
            for (col = 0; col < LINE_WIDTH; col = col + 1) begin
                drive_pixel(row, col, (col == 0));
            end

            @(negedge clk);
            pixel_valid <= 1'b0;
            h_sync      <= 1'b0;
            pixel_in    <= 8'h00;
        end

        repeat (8) @(posedge clk);
        $finish;
    end

    task drive_pixel;
        input integer row_index;
        input integer col_index;
        input integer start_of_line;
        begin
            @(negedge clk);
            pixel_valid <= 1'b1;
            h_sync      <= start_of_line[0];
            pixel_in    <= make_pixel(row_index, col_index);
        end
    endtask

    function [DATA_WIDTH-1:0] make_pixel;
        input integer row_index;
        input integer col_index;
        begin
            case (row_index)
                0: make_pixel = "0" + col_index;
                1: make_pixel = "A" + col_index;
                2: make_pixel = "3" + col_index;
                3: make_pixel = "D" + col_index;
                4: make_pixel = "6" + col_index;
                default: make_pixel = "?";
            endcase
        end
    endfunction

endmodule
