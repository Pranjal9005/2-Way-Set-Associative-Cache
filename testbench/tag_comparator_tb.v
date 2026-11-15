`timescale 1ns/1ps

module tag_comparator_tb;

    reg [2:0] requested_tag;
    reg [2:0] tag_way0;
    reg [2:0] tag_way1;

    wire hit_way0;
    wire hit_way1;

    integer passed;

    // Instantiate DUT
    tag_comparator DUT (
        .requested_tag(requested_tag),
        .tag_way0(tag_way0),
        .tag_way1(tag_way1),
        .hit_way0(hit_way0),
        .hit_way1(hit_way1)
    );

    // Task to check comparator outputs
    task check_result;
        input expected_hit0;
        input expected_hit1;

        begin
            #10;

            if ((hit_way0 !== expected_hit0) ||
                (hit_way1 !== expected_hit1)) begin

                $display("FAIL: Requested=%b Way0=%b Way1=%b",
                         requested_tag, tag_way0, tag_way1);

                $display("Expected: Hit0=%b Hit1=%b",
                         expected_hit0, expected_hit1);

                $display("Actual: Hit0=%b Hit1=%b",
                         hit_way0, hit_way1);

                $fatal(1, "Tag comparator mismatch");
            end
            else begin
                $display("PASS: Requested=%b Hit0=%b Hit1=%b",
                         requested_tag, hit_way0, hit_way1);

                passed = passed + 1;
            end
        end
    endtask

    initial begin

        passed = 0;

        $display("================================");
        $display("     TAG COMPARATOR TEST");
        $display("================================");

        // TEST 1: Match Way 0 only
        requested_tag = 3'b101;
        tag_way0 = 3'b101;
        tag_way1 = 3'b011;
        check_result(1'b1, 1'b0);

        // TEST 2: Match Way 1 only
        requested_tag = 3'b110;
        tag_way0 = 3'b001;
        tag_way1 = 3'b110;
        check_result(1'b0, 1'b1);

        // TEST 3: No match
        requested_tag = 3'b100;
        tag_way0 = 3'b001;
        tag_way1 = 3'b010;
        check_result(1'b0, 1'b0);

        // TEST 4: Both tags match
        requested_tag = 3'b111;
        tag_way0 = 3'b111;
        tag_way1 = 3'b111;
        check_result(1'b1, 1'b1);

        // TEST 5: Both tags are zero
        requested_tag = 3'b000;
        tag_way0 = 3'b000;
        tag_way1 = 3'b000;
        check_result(1'b1, 1'b1);

        // TEST 6: Way 0 match, Way 1 mismatch
        requested_tag = 3'b010;
        tag_way0 = 3'b010;
        tag_way1 = 3'b100;
        check_result(1'b1, 1'b0);

        // TEST 7: Way 0 mismatch, Way 1 match
        requested_tag = 3'b011;
        tag_way0 = 3'b110;
        tag_way1 = 3'b011;
        check_result(1'b0, 1'b1);

        // TEST 8: Both ways mismatch
        requested_tag = 3'b001;
        tag_way0 = 3'b010;
        tag_way1 = 3'b100;
        check_result(1'b0, 1'b0);

        $display("================================");
        $display("RESULT: %0d/8 CHECKS PASSED", passed);
        $display("TAG COMPARATOR TEST PASSED");
        $display("================================");

        $finish;
    end

endmodule
