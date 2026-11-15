`timescale 1ns/1ps

module cache_2way_tb;

    reg clk;
    reg reset;
    reg request_valid;
    reg [3:0] address;

    wire request_ready;
    wire [7:0] response_data;
    wire response_valid;
    wire cache_hit;

    integer passed;
    integer failed;
    integer memory_read_count;
    integer reads_before;

    // Instantiate complete cache
    cache_2way dut (
        .clk(clk),
        .reset(reset),
        .request_valid(request_valid),
        .cpu_address(address),
        .request_ready(request_ready),
        .cpu_read_data(response_data),
        .response_valid(response_valid),
        .cache_hit(cache_hit)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Count main-memory read requests
    always @(posedge clk) begin
        if (dut.mem_read_req)
            memory_read_count = memory_read_count + 1;
    end

    // Send one CPU read request and check returned data
    task cpu_read;
        input [3:0] addr;
        input [7:0] expected_data;
        begin

            // Wait until controller returns to IDLE
            wait(request_ready == 1'b1);

            // Send request
            @(negedge clk);
            address = addr;
            request_valid = 1'b1;

            // Request accepted
            @(posedge clk);
            #1;
            request_valid = 1'b0;

            // Wait for response, with timeout
            begin : wait_for_response
                integer timeout;
                timeout = 0;

                while (response_valid !== 1'b1 && timeout < 20) begin
                    @(posedge clk);
                    #1;
                    timeout = timeout + 1;
                end

                if (response_valid !== 1'b1) begin
                    $display("FAIL: Timeout for address %h", addr);
                    failed = failed + 1;
                end
                else if (response_data !== expected_data) begin
                    $display("FAIL: Address %h | Expected %h | Got %h",
                             addr, expected_data, response_data);
                    failed = failed + 1;
                end
                else begin
                    $display("PASS: Address %h | Data %h",
                             addr, response_data);
                    passed = passed + 1;
                end
            end
        end
    endtask


    initial begin
        reset = 1'b1;
        request_valid = 1'b0;
        address = 4'b0000;

        passed = 0;
        failed = 0;
        memory_read_count = 0;

        // Reset
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // TEST 1: Cold miss - address 3, set 1
        $display("\nTEST 1: Cold miss (address 3, set 1)");
        cpu_read(4'b0011, 8'hA3);
        if (memory_read_count == 1) begin
            $display("PASS: First access caused one memory read");
            passed = passed + 1;
        end else begin
            $display("FAIL: Unexpected memory read count");
            failed = failed + 1;
        end

        // TEST 2: Same address - should be a cache hit
        $display("\nTEST 2: Cache hit on address 3");
        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);
        if (memory_read_count == reads_before) begin
            $display("PASS: Cache hit did not access main memory");
            passed = passed + 1;
        end else begin
            $display("FAIL: Cache hit accessed main memory");
            failed = failed + 1;
        end

        // TEST 3: Another tag in the same set - fills Way 1
        $display("\nTEST 3: Fill second way with address 5");
        cpu_read(4'b0101, 8'hA5);

        // TEST 4: Access first address again - makes Way 1 LRU
        $display("\nTEST 4: Access address 3 to make Way 1 LRU");
        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);
        if (memory_read_count == reads_before) begin
            $display("PASS: Address 3 hit in cache");
            passed = passed + 1;
        end else begin
            $display("FAIL: Address 3 missed");
            failed = failed + 1;
        end

        // TEST 5: Third tag in same set - should evict Way 1 (address 5)
        $display("\nTEST 5: Access address 7 (evicts LRU Way 1)");
        reads_before = memory_read_count;
        cpu_read(4'b0111, 8'hA7);
        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Conflict miss caused one memory refill");
            passed = passed + 1;
        end else begin
            $display("FAIL: Memory refill count unexpected");
            failed = failed + 1;
        end

        // TEST 5B: Verify address 3 remained cached after address 7 replaced address 5
        $display("\nTEST 5B: Verify address 3 remained cached");
        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);
        if (memory_read_count == reads_before) begin
            $display("PASS: Address 3 remained cached (Way 0 intact)");
            passed = passed + 1;
        end else begin
            $display("FAIL: Address 3 was unexpectedly evicted");
            failed = failed + 1;
        end

        // TEST 6: Address 5 should now miss because it was evicted
        $display("\nTEST 6: Verify evicted address 5 causes miss");
        reads_before = memory_read_count;
        cpu_read(4'b0101, 8'hA5);
        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Evicted address caused a memory read");
            passed = passed + 1;
        end else begin
            $display("FAIL: Expected a memory read after eviction");
            failed = failed + 1;
        end

        // TEST 7: Different set (Set 0) - cold miss
        $display("\nTEST 7: Access address 0 (Set 0)");
        reads_before = memory_read_count;
        cpu_read(4'b0000, 8'hA0);
        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Set 0 cold miss caused one memory read");
            passed = passed + 1;
        end else begin
            $display("FAIL: Set 0 cold miss did not access memory");
            failed = failed + 1;
        end

        // TEST 8: Verify Set 1 lines remain intact after Set 0 access
        $display("\nTEST 8: Verify Set 1 lines remain intact after Set 0 access");
        reads_before = memory_read_count;
        cpu_read(4'b0101, 8'hA5);
        cpu_read(4'b0111, 8'hA7);
        if (memory_read_count == reads_before) begin
            $display("PASS: Set 1 cache lines remained intact without main memory access");
            passed = passed + 1;
        end else begin
            $display("FAIL: Set 0 operation interfered with Set 1 lines");
            failed = failed + 1;
        end

        // Final report
        repeat (2) @(posedge clk);

        $display("\n--------------------------------");
        $display("CACHE INTEGRATION TEST COMPLETE");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("--------------------------------");

        if (failed == 0)
            $display("ALL INTEGRATION TESTS PASSED");
        else begin
            $display("INTEGRATION TEST FAILED");
            $fatal(1, "Integration tests failed");
        end

        $finish;
    end

endmodule
