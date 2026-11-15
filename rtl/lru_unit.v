`timescale 1ns/1ps

module lru_unit (
    input clk,
    input reset,

    input set_index,
    input update_en,
    input access_valid,
    input access_way,

    output lru_bit
);

    // One LRU bit for each set
    reg lru_mem [0:1];

    // Update LRU state
    always @(posedge clk) begin

        if (reset) begin
            lru_mem[0] <= 1'b0;
            lru_mem[1] <= 1'b0;
        end

        else if (update_en && access_valid) begin

            // Access Way 0: Way 1 becomes LRU
            // Access Way 1: Way 0 becomes LRU
            lru_mem[set_index] <= ~access_way;

        end

    end

    // Read LRU bit of selected set
    assign lru_bit = lru_mem[set_index];

endmodule
