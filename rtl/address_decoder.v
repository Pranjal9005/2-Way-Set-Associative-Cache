`timescale 1ns/1ps

module address_decoder (
    input  [3:0] address,
    output [2:0] tag,
    output       set_index
);

    assign tag       = address[3:1];
    assign set_index = address[0];

endmodule
