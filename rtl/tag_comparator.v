`timescale 1ns/1ps

module tag_comparator (

    input  [2:0] requested_tag,
    input  [2:0] tag_way0,
    input  [2:0] tag_way1,

    output hit_way0,
    output hit_way1

);

    // Compare requested tag with both cache ways
    assign hit_way0 = (requested_tag == tag_way0);

    assign hit_way1 = (requested_tag == tag_way1);

endmodule
