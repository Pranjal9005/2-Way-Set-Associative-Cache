`timescale 1ns/1ps

module main_memory (
    input clk,
    input reset,

    input read_req,
    input write_req,

    input [3:0] address,
    input [7:0] write_data,

    output reg ready,
    output reg [7:0] read_data
);

    // 16 memory locations, each storing 8 bits
    reg [7:0] mem [0:15];

    integer i;

    always @(posedge clk) begin

        if (reset) begin
            ready <= 1'b0;
            read_data <= 8'b0;

            // Initialize memory with recognizable values
            for (i = 0; i < 16; i = i + 1) begin
                mem[i] <= 8'hA0 + i;
            end
        end

        else begin
            // Default: no response
            ready <= 1'b0;

            if (read_req && !write_req) begin
                read_data <= mem[address];
                ready <= 1'b1;
            end

            else if (write_req && !read_req) begin
                mem[address] <= write_data;
                ready <= 1'b1;
            end
        end
    end

endmodule
