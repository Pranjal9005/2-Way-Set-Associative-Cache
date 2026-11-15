`timescale 1ns/1ps

module address_decoder_tb;

    reg  [3:0] address;
    wire [2:0] tag;
    wire       set_index;

    // Instantiate Device Under Test (DUT)
    address_decoder DUT (
        .address(address),
        .tag(tag),
        .set_index(set_index)
    );

    initial begin
        $display("Address | Tag | Set");
        $display("--------------------");

        address = 4'b1010;
        #10;
        $display("  %b  | %b  | %b", address, tag, set_index);

        address = 4'b1011;
        #10;
        $display("  %b  | %b  | %b", address, tag, set_index);

        address = 4'b0110;
        #10;
        $display("  %b  | %b  | %b", address, tag, set_index);

        $finish;
    end

endmodule

