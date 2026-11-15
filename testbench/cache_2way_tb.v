`timescale 1ns/1ps

module cache_2way_tb;

    reg clk;
    reg reset;
    reg request_valid;
    reg [3:0] address;

    wire request_ready;
    wire [7:0] response_data;
    wire response_valid;

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
        .cache_hit()
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
        cpu_read(4'b0011, 8'hA3);
        if (memory_read_count == 1)
            $display("PASS: First access caused one memory read");
        else begin
            $display("FAIL: Unexpected memory read count");
            failed = failed + 1;
        end

        // TEST 2: Same address - should be a cache hit
        reads_before = memory_read_count;
        cpu_read(4'b0011, 8'hA3);
        if (memory_read_count == reads_before)
            $display("PASS: Cache hit did not access main memory");
        else begin
            $display("FAIL: Cache hit accessed main memory");
            failed = failed + 1;
        end

        // TEST 3: Another tag in the same set - fills Way 1
        cpu_read(4'b0101, 8'hA5);

        // TEST 4: Access first address again - makes Way 1 LRU
        cpu_read(4'b0011, 8'hA3);

        // TEST 5: Third tag in same set - should evict Way 1
        cpu_read(4'b0111, 8'hA7);

        // TEST 6: Address 5 should now miss because it was evicted
        reads_before = memory_read_count;
        cpu_read(4'b0101, 8'hA5);
        if (memory_read_count == reads_before + 1)
            $display("PASS: Evicted address caused a memory read");
        else begin
            $display("FAIL: Expected a memory read after eviction");
            failed = failed + 1;
        end

        // TEST 7: Different set - should work independently
        cpu_read(4'b0000, 8'hA0);

        // Final report
        repeat (2) @(posedge clk);

        $display("--------------------------------");
        $display("CACHE INTEGRATION TEST COMPLETE");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("--------------------------------");

        if (failed == 0)
            $display("ALL INTEGRATION TESTS PASSED");
        else
            $display("INTEGRATION TEST FAILED");

        $finish;
    end

endmodule
