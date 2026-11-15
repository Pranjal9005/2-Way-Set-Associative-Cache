`timescale 1ns/1ps

module hit_miss_unit (
    input valid_way0,
    input valid_way1,

    input tag_match_way0,
    input tag_match_way1,

    input lru_bit,

    output hit_way0,
    output hit_way1,

    output cache_hit,
    output cache_miss,

    output reg selected_way
);

    // A hit requires both a valid line and matching tag
    assign hit_way0 = valid_way0 && tag_match_way0;
    assign hit_way1 = valid_way1 && tag_match_way1;

    // Overall cache hit/miss detection
    assign cache_hit  = hit_way0 || hit_way1;
    assign cache_miss = !cache_hit;

    // Select the way for reading or filling
    always @(*) begin

        if (hit_way0) begin
            selected_way = 1'b0;
        end

        else if (hit_way1) begin
            selected_way = 1'b1;
        end

        else if (!valid_way0) begin
            selected_way = 1'b0;
        end

        else if (!valid_way1) begin
            selected_way = 1'b1;
        end

        else begin
            selected_way = lru_bit;
        end

    end

endmodule
