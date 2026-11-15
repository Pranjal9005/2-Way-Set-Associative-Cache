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
    integer accepted_count;
    integer handshake_timeout;
    integer addr;

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

    // Count memory reads and accepted CPU requests
    always @(posedge clk) begin
        if (reset) begin
            memory_read_count = 0;
            accepted_count = 0;
        end
        else begin
            if (dut.mem_read_req)
                memory_read_count = memory_read_count + 1;

            if (request_valid && request_ready)
                accepted_count = accepted_count + 1;
        end
    end

    // CPU read task
    task cpu_read;
        input [3:0] addr;
        input [7:0] expected_data;
        integer timeout;

        begin
            // Wait until controller is ready
            wait(request_ready == 1'b1);

            // Send request
            @(negedge clk);
            address = addr;
            request_valid = 1'b1;

            // Request accepted
            @(posedge clk);
            #1;
            request_valid = 1'b0;

            // Wait for response with timeout
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
    endtask

    initial begin

        // Initialize signals and counters
        reset = 1'b1;
        request_valid = 1'b0;
        address = 4'b0000;

        passed = 0;
        failed = 0;
        memory_read_count = 0;
        accepted_count = 0;

        // Reset
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;


        // TEST 1: Cold miss
        $display("\nTEST 1: Cold miss - address 3");

        cpu_read(4'b0011, 8'hA3);

        if (memory_read_count == 1) begin
            $display("PASS: One memory read occurred");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Unexpected memory read count");
            failed = failed + 1;
        end


        // TEST 2: Cache hit
        $display("\nTEST 2: Cache hit - address 3");

        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);

        if (memory_read_count == reads_before) begin
            $display("PASS: Cache hit did not access memory");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Cache hit accessed memory");
            failed = failed + 1;
        end


        // TEST 3: Fill second way
        $display("\nTEST 3: Fill second way - address 5");

        cpu_read(4'b0101, 8'hA5);


        // TEST 4: Update LRU
        $display("\nTEST 4: Access address 3 to make Way 1 LRU");

        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);

        if (memory_read_count == reads_before) begin
            $display("PASS: Address 3 hit");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Address 3 unexpectedly missed");
            failed = failed + 1;
        end


        // TEST 5: Evict Way 1
        $display("\nTEST 5: Address 7 should evict Way 1");

        reads_before = memory_read_count;
        cpu_read(4'b0111, 8'hA7);

        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Conflict miss caused one refill");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Unexpected refill count");
            failed = failed + 1;
        end


        // TEST 6: Address 3 should remain cached
        $display("\nTEST 6: Verify address 3 remains cached");

        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);

        if (memory_read_count == reads_before) begin
            $display("PASS: Address 3 remained cached");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Address 3 was unexpectedly evicted");
            failed = failed + 1;
        end


        // TEST 7: Address 5 should have been evicted
        $display("\nTEST 7: Verify address 5 was evicted");

        reads_before = memory_read_count;
        cpu_read(4'b0101, 8'hA5);

        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Evicted address caused a memory read");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Expected a memory read");
            failed = failed + 1;
        end


        // TEST 8: Access different set
        $display("\nTEST 8: Cold miss in Set 0 - address 0");

        reads_before = memory_read_count;
        cpu_read(4'b0000, 8'hA0);

        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Set 0 cold miss caused one read");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Unexpected Set 0 read count");
            failed = failed + 1;
        end


        // TEST 9: Verify Set 1 independence
        $display("\nTEST 9: Verify Set 1 independence");

        reads_before = memory_read_count;

        cpu_read(4'b0011, 8'hA3);
        cpu_read(4'b0101, 8'hA5);

        if (memory_read_count == reads_before) begin
            $display("PASS: Set 0 access did not affect Set 1");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Set 1 accessed main memory unexpectedly");
            failed = failed + 1;
        end


        // TEST 10: Update LRU to make Way 0 the victim
        $display("\nTEST 10: Update LRU to make Way 0 the victim");

        reads_before = memory_read_count;
        cpu_read(4'b0101, 8'hA5);

        if (memory_read_count == reads_before) begin
            $display("PASS: Address 5 hit and updated LRU");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Address 5 unexpectedly missed");
            failed = failed + 1;
        end


        // TEST 11: Address 9 should evict address 3
        $display("\nTEST 11: Address 9 should evict Way 0");

        reads_before = memory_read_count;
        cpu_read(4'b1001, 8'hA9);

        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Reverse LRU eviction caused one refill");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Unexpected reverse eviction refill count");
            failed = failed + 1;
        end


        // TEST 12: Address 5 should remain cached
        $display("\nTEST 12: Verify address 5 remains cached");

        reads_before = memory_read_count;
        cpu_read(4'b0101, 8'hA5);

        if (memory_read_count == reads_before) begin
            $display("PASS: Address 5 remained cached");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Address 5 was unexpectedly evicted");
            failed = failed + 1;
        end


        // TEST 13: Address 3 should now miss
        $display("\nTEST 13: Verify address 3 was evicted");

        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);

        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Address 3 caused a miss after eviction");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Address 3 was not evicted as expected");
            failed = failed + 1;
        end


        // TEST 14: Reset after filling the cache
        $display("\nTEST 14: Reset after cache fill");

        @(negedge clk);
        reset = 1'b1;

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        reads_before = memory_read_count;

        $display("Access address 3 after reset");
        cpu_read(4'b0011, 8'hA3);

        if (memory_read_count == reads_before + 1) begin
            $display("PASS: Reset invalidated previous cache entry");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Expected a cold miss after reset");
            failed = failed + 1;
        end


        // TEST 15: Verify all 16 memory addresses
        $display("\nTEST 15: Verify all 16 addresses");

        for (addr = 0; addr < 16; addr = addr + 1) begin
            cpu_read(addr[3:0], 8'hA0 + addr);
        end


        // TEST 16: Request handshake verification
        $display("\nTEST 16: Request handshake verification");

        // Ensure controller is idle
        wait(request_ready == 1'b1);

        reads_before = accepted_count;

        // Send first request: address 2
        @(negedge clk);
        address = 4'b0010;
        request_valid = 1'b1;

        // Wait for request acceptance
        @(posedge clk);
        #1;
        request_valid = 1'b0;

        // Check that cache becomes busy
        if (request_ready == 1'b0) begin
            $display("PASS: Cache became busy after accepting request");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Cache did not enter busy state");
            failed = failed + 1;
        end

        // Present second request while cache is busy
        @(negedge clk);
        address = 4'b0100;
        request_valid = 1'b1;

        // Keep request asserted for two clock edges
        repeat (2) @(posedge clk);

        // Withdraw second request before cache becomes ready
        @(negedge clk);
        request_valid = 1'b0;

        // Wait for first request response
        handshake_timeout = 0;

        while (response_valid !== 1'b1 &&
               handshake_timeout < 20) begin
            @(posedge clk);
            #1;
            handshake_timeout = handshake_timeout + 1;
        end

        if (response_valid === 1'b1) begin
            $display("PASS: First request received a response");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: First request timed out");
            failed = failed + 1;
        end

        // Only first request should have been accepted
        if (accepted_count == reads_before + 1) begin
            $display("PASS: Busy-state request was not accepted");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Unexpected request acceptance count");
            failed = failed + 1;
        end

        // Wait for controller to return to idle
        wait(request_ready == 1'b1);


        // TEST 17: Hold request_valid HIGH while cache is busy
        //          and verify the pending request is accepted later.
        $display("\nTEST 17: Hold request_valid until cache becomes ready");

        // Ensure controller is idle
        wait(request_ready == 1'b1);

        reads_before = accepted_count;

        // ------------------------------------------------
        // FIRST REQUEST: Address 2
        // ------------------------------------------------
        @(negedge clk);
        address       = 4'b0010;
        request_valid = 1'b1;

        // First request handshake
        @(posedge clk);
        #1;

        if (request_ready == 1'b0) begin
            $display("PASS: First request accepted, cache is busy");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Cache did not become busy");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // SECOND REQUEST: Address 4
        // Present it after the first request was accepted.
        // Keep valid HIGH and address stable while busy.
        // ------------------------------------------------
        @(negedge clk);
        address = 4'b0100;

        // Wait for first response while keeping second
        // request pending.
        handshake_timeout = 0;

        while (response_valid !== 1'b1 &&
               handshake_timeout < 20) begin
            @(posedge clk);
            #1;
            handshake_timeout = handshake_timeout + 1;
        end

        if (response_valid === 1'b1 &&
            response_data === 8'hA2) begin
            $display("PASS: First response received correctly (data=A2)");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: First response incorrect or timeout");
            failed = failed + 1;
        end

        // Confirm second request has not yet been accepted
        if (accepted_count == reads_before + 1) begin
            $display("PASS: Second request remains pending while busy");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Unexpected request acceptance while busy");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // WAIT FOR CACHE TO BECOME READY
        // request_valid remains HIGH and address remains 4.
        // ------------------------------------------------
        wait(request_ready == 1'b1);

        // Second request handshake
        @(posedge clk);
        #1;

        if (request_ready == 1'b0) begin
            $display("PASS: Second request accepted when cache became ready");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Second request was not accepted");
            failed = failed + 1;
        end

        // Deassert valid after second request acceptance
        @(negedge clk);
        request_valid = 1'b0;

        // ------------------------------------------------
        // VERIFY SECOND RESPONSE
        // ------------------------------------------------
        handshake_timeout = 0;

        while (response_valid !== 1'b1 &&
               handshake_timeout < 20) begin
            @(posedge clk);
            #1;
            handshake_timeout = handshake_timeout + 1;
        end

        if (response_valid === 1'b1 &&
            response_data === 8'hA4) begin
            $display("PASS: Second response received correctly (data=A4)");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Second response incorrect or timeout");
            failed = failed + 1;
        end

        // Exactly two requests should have been accepted
        if (accepted_count == reads_before + 2) begin
            $display("PASS: Exactly two requests accepted");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Unexpected request acceptance count (%0d)",
                     accepted_count - reads_before);
            failed = failed + 1;
        end

        wait(request_ready == 1'b1);

        // FINAL REPORT
        repeat (2) @(posedge clk);

        $display("\n================================");
        $display("CACHE INTEGRATION TEST COMPLETE");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("================================");

        if (failed == 0)
            $display("ALL INTEGRATION TESTS PASSED");
        else begin
            $display("INTEGRATION TEST FAILED");
            $fatal(1, "Integration tests failed");
        end

        $finish;

    end

endmodule
