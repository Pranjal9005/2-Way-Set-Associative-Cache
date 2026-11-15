`timescale 1ns/1ps

module hit_miss_unit_tb;

    // Inputs
    reg valid_way0;
    reg valid_way1;

    reg tag_match_way0;
    reg tag_match_way1;

    reg lru_bit;

    // Outputs
    wire hit_way0;
    wire hit_way1;

    wire cache_hit;
    wire cache_miss;

    wire selected_way;

    integer pass_count = 0;

    // Instantiate DUT
    hit_miss_unit uut (
        .valid_way0(valid_way0),
        .valid_way1(valid_way1),

        .tag_match_way0(tag_match_way0),
        .tag_match_way1(tag_match_way1),

        .lru_bit(lru_bit),

        .hit_way0(hit_way0),
        .hit_way1(hit_way1),

        .cache_hit(cache_hit),
        .cache_miss(cache_miss),

        .selected_way(selected_way)
    );

    // Task to check outputs
    task check_result;
        input expected_hit;
        input expected_miss;
        input expected_way;
        input expected_hit0;
        input expected_hit1;

        begin
            #10;

            if (
                cache_hit !== expected_hit ||
                cache_miss !== expected_miss ||
                selected_way !== expected_way ||
                hit_way0 !== expected_hit0 ||
                hit_way1 !== expected_hit1
            ) begin
                $display("FAIL: Test failed");
                $display("Expected: hit=%b miss=%b way=%b hit0=%b hit1=%b",
                    expected_hit, expected_miss, expected_way,
                    expected_hit0, expected_hit1);
                $display("Actual:   hit=%b miss=%b way=%b hit0=%b hit1=%b",
                    cache_hit, cache_miss, selected_way,
                    hit_way0, hit_way1);
                $fatal(1);
            end

            else begin
                pass_count = pass_count + 1;
                $display("PASS: Test %0d", pass_count);
            end
        end
    endtask

    initial begin

        $display("================================");
        $display("       HIT/MISS UNIT TEST");
        $display("================================");

        // Test 1: Way 0 hit
        valid_way0 = 1;
        valid_way1 = 1;
        tag_match_way0 = 1;
        tag_match_way1 = 0;
        lru_bit = 1;
        check_result(1, 0, 0, 1, 0);

        // Test 2: Way 1 hit
        valid_way0 = 1;
        valid_way1 = 1;
        tag_match_way0 = 0;
        tag_match_way1 = 1;
        lru_bit = 0;
        check_result(1, 0, 1, 0, 1);

        // Test 3: Both ways invalid
        valid_way0 = 0;
        valid_way1 = 0;
        tag_match_way0 = 0;
        tag_match_way1 = 0;
        lru_bit = 1;
        check_result(0, 1, 0, 0, 0);

        // Test 4: Way 0 invalid, Way 1 valid
        valid_way0 = 0;
        valid_way1 = 1;
        tag_match_way0 = 0;
        tag_match_way1 = 0;
        lru_bit = 0;
        check_result(0, 1, 0, 0, 0);

        // Test 5: Way 1 invalid, Way 0 valid
        valid_way0 = 1;
        valid_way1 = 0;
        tag_match_way0 = 0;
        tag_match_way1 = 0;
        lru_bit = 1;
        check_result(0, 1, 1, 0, 0);

        // Test 6: Both valid, LRU victim is Way 0
        valid_way0 = 1;
        valid_way1 = 1;
        tag_match_way0 = 0;
        tag_match_way1 = 0;
        lru_bit = 0;
        check_result(0, 1, 0, 0, 0);

        // Test 7: Both valid, LRU victim is Way 1
        valid_way0 = 1;
        valid_way1 = 1;
        tag_match_way0 = 0;
        tag_match_way1 = 0;
        lru_bit = 1;
        check_result(0, 1, 1, 0, 0);

        // Test 8: Tag matches but Way 0 is invalid
        valid_way0 = 0;
        valid_way1 = 1;
        tag_match_way0 = 1;
        tag_match_way1 = 0;
        lru_bit = 0;
        check_result(0, 1, 0, 0, 0);

        $display("--------------------------------");
        $display("RESULT: %0d/8 CHECKS PASSED", pass_count);
        $display("HIT/MISS UNIT TEST PASSED");
        $display("--------------------------------");

        $finish;

    end

endmodule
