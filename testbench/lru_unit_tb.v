`timescale 1ns/1ps

module lru_unit_tb;

    reg clk;
    reg reset;
    reg set_index;
    reg update_en;
    reg access_valid;
    reg access_way;

    wire lru_bit;

    integer passed;

    // Instantiate LRU module
    lru_unit DUT (
        .clk(clk),
        .reset(reset),
        .set_index(set_index),
        .update_en(update_en),
        .access_valid(access_valid),
        .access_way(access_way),
        .lru_bit(lru_bit)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;


    // Task to perform an access
    task perform_access;
        input set_no;
        input way_no;

        begin
            @(negedge clk);

            set_index = set_no;
            access_way = way_no;
            update_en = 1'b1;
            access_valid = 1'b1;

            @(posedge clk);
            #1;

            update_en = 1'b0;
            access_valid = 1'b0;
        end
    endtask


    // Task to check LRU output
    task check_lru;
        input set_no;
        input expected_lru;

        begin
            @(negedge clk);

            set_index = set_no;
            #1;

            if (lru_bit !== expected_lru) begin

                $display("FAIL: Set=%0d Expected=%b Actual=%b",
                         set_no, expected_lru, lru_bit);

                $fatal(1, "LRU mismatch");

            end

            else begin

                $display("PASS: Set=%0d LRU=%b",
                         set_no, lru_bit);

                passed = passed + 1;

            end
        end
    endtask


    initial begin

        clk = 0;
        reset = 0;

        set_index = 0;
        update_en = 0;
        access_valid = 0;
        access_way = 0;

        passed = 0;

        $display("================================");
        $display("       LRU UNIT TEST");
        $display("================================");


        // TEST 1: Reset both sets
        @(negedge clk);
        reset = 1;

        @(posedge clk);
        #1;

        reset = 0;

        check_lru(0, 1'b0);
        check_lru(1, 1'b0);


        // TEST 2: Access Way 0 in Set 0
        $display("\nTEST 2: Access Way 0 in Set 0");

        perform_access(0, 0);
        check_lru(0, 1'b1);


        // TEST 3: Access Way 1 in Set 0
        $display("\nTEST 3: Access Way 1 in Set 0");

        perform_access(0, 1);
        check_lru(0, 1'b0);


        // TEST 4: Access Way 0 in Set 1
        $display("\nTEST 4: Access Way 0 in Set 1");

        perform_access(1, 0);
        check_lru(1, 1'b1);


        // TEST 5: Verify Set 0 is independent
        $display("\nTEST 5: Check Set 0 Independence");

        check_lru(0, 1'b0);


        // TEST 6: Disable update and verify state
        $display("\nTEST 6: Update Disabled");

        @(negedge clk);

        set_index = 1;
        access_way = 1;
        update_en = 0;
        access_valid = 1;

        @(posedge clk);
        #1;

        access_valid = 0;

        check_lru(1, 1'b1);


        // TEST 7: Invalid access must not update LRU
        $display("\nTEST 7: Invalid Access");

        @(negedge clk);

        set_index = 1;
        access_way = 1;
        update_en = 1;
        access_valid = 0;

        @(posedge clk);
        #1;

        update_en = 0;

        check_lru(1, 1'b1);


        // Final result
        $display("\n================================");
        $display("RESULT: %0d/8 CHECKS PASSED", passed);
        $display("LRU UNIT TEST PASSED");
        $display("================================");

        $finish;

    end

endmodule
