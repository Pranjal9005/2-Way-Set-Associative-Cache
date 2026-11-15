`timescale 1ns/1ps

module address_decoder_tb;

    reg  [3:0] address;
    wire [2:0] tag;
    wire       set_index;

    integer i;
    integer passed;

    address_decoder DUT (
        .address(address),
        .tag(tag),
        .set_index(set_index)
    );

    initial begin
        $dumpfile("simulation/waveforms/address_decoder.vcd");
        $dumpvars(0, address_decoder_tb);

        passed = 0;

        $display("==================================");
        $display(" ADDRESS DECODER TEST");
        $display("==================================");
        $display("Address | Expected Tag | Actual Tag | Set");
        $display("----------------------------------");

        // Test all 16 possible 4-bit addresses
        for (i = 0; i < 16; i = i + 1) begin

            address = i;
            #10;

            if ((tag !== (i >> 1)) ||
                (set_index !== (i & 1))) begin

                $display("FAIL: Address=%b Tag=%b Set=%b",
                         address, tag, set_index);

                $fatal(1, "Address decoder mismatch");
            end

            else begin
                $display("PASS: %b       %b           %b        %b",
                         address, (i >> 1), tag, set_index);
                passed = passed + 1;
            end

        end

        $display("----------------------------------");
        $display("RESULT: %0d/16 tests passed", passed);
        $display("ADDRESS DECODER TEST PASSED");

        $finish;
    end

endmodule
