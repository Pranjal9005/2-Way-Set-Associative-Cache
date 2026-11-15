`timescale 1ns/1ps

module cache_array (
    input clk,
    input reset,

    input set_index,
    input way_select,
    input write_en,

    input [2:0] tag_in,
    input [7:0] data_in,

    output [2:0] tag_way0,
    output [2:0] tag_way1,

    output [7:0] data_way0,
    output [7:0] data_way1,

    output valid_way0,
    output valid_way1
);

    // Storage for 2 sets x 2 ways = 4 cache lines
    reg [2:0] tag_mem [0:3];
    reg [7:0] data_mem [0:3];
    reg valid_mem [0:3];

    integer i;

    // Synchronous reset and write operation
    always @(posedge clk) begin

        if (reset) begin
            for (i = 0; i < 4; i = i + 1) begin
                tag_mem[i]   <= 3'b000;
                data_mem[i]  <= 8'b00000000;
                valid_mem[i] <= 1'b0;
            end
        end

        else if (write_en) begin
            tag_mem[{set_index, way_select}]   <= tag_in;
            data_mem[{set_index, way_select}]  <= data_in;
            valid_mem[{set_index, way_select}] <= 1'b1;
        end

    end

    // Read both ways of the selected set
    assign tag_way0 = tag_mem[{set_index, 1'b0}];
    assign tag_way1 = tag_mem[{set_index, 1'b1}];

    assign data_way0 = data_mem[{set_index, 1'b0}];
    assign data_way1 = data_mem[{set_index, 1'b1}];

    assign valid_way0 = valid_mem[{set_index, 1'b0}];
    assign valid_way1 = valid_mem[{set_index, 1'b1}];

endmodule
