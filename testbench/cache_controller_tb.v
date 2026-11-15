`timescale 1ns/1ps

module cache_controller_tb;

    reg clk;
    reg reset;

    // CPU interface
    reg request_valid;
    wire request_ready;
    reg [3:0] address;

    wire [7:0] response_data;
    wire response_valid;

    // Cache lookup interface
    reg cache_hit;
    reg selected_way;
    reg [7:0] hit_data;

    // Main memory interface
    wire mem_read_req;
    wire [3:0] mem_address;
    reg mem_ready;
    reg [7:0] mem_read_data;

    // Cache fill interface
    wire cache_write_en;
    wire cache_write_way;
    wire [2:0] cache_write_tag;
    wire [7:0] cache_write_data;

    // LRU interface
    wire lru_update_en;
    wire lru_access_way;

    integer passed;
    integer failed;

    // Device Under Test
    cache_controller dut (
        .clk(clk),
        .reset(reset),

        .request_valid(request_valid),
        .request_ready(request_ready),
        .address(address),

        .response_data(response_data),
        .response_valid(response_valid),

        .cache_hit(cache_hit),
        .selected_way(selected_way),
        .hit_data(hit_data),

        .mem_read_req(mem_read_req),
        .mem_address(mem_address),
        .mem_ready(mem_ready),
        .mem_read_data(mem_read_data),

        .cache_write_en(cache_write_en),
        .cache_write_way(cache_write_way),
        .cache_write_tag(cache_write_tag),
        .cache_write_data(cache_write_data),

        .lru_update_en(lru_update_en),
        .lru_access_way(lru_access_way)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    // Test checking task
    task check;
        input condition;
        input [8*100-1:0] message;
        begin
            if (condition === 1'b1) begin
                $display("PASS: %0s", message);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s", message);
                failed = failed + 1;
            end
        end
    endtask

    // Simulated main memory
    // Responds one clock after receiving request
    always @(posedge clk) begin
        if (reset) begin
            mem_ready <= 1'b0;
            mem_read_data <= 8'b0;
        end
        else begin
            mem_ready <= 1'b0;

            if (mem_read_req) begin
                mem_read_data <= 8'hAB;
                mem_ready <= 1'b1;
            end
        end
    end

    // Global simulation timeout
    initial begin
        #1000;
        $display("ERROR: Simulation timeout!");
        $fatal(1, "Testbench did not complete");
    end

    initial begin

        clk = 0;
        reset = 1;

        request_valid = 0;
        address = 0;

        cache_hit = 0;
        selected_way = 0;
        hit_data = 0;

        mem_ready = 0;
        mem_read_data = 0;

        passed = 0;
        failed = 0;

        $display("");
        $display("==================================");
        $display("       CACHE CONTROLLER TEST");
        $display("==================================");

        // TEST 1: Reset
        repeat(2) @(negedge clk);
        #1;

        check(request_ready == 1,
              "Controller enters IDLE after reset");

        reset = 0;

        // TEST 2: Request acceptance
        @(negedge clk);
        address = 4'b1010;
        request_valid = 1;

        #1;
        check(request_ready == 1,
              "Controller ready before request");

        @(posedge clk);
        #1;

        check(request_ready == 0,
              "Controller accepts CPU request");

        @(negedge clk);
        request_valid = 0;

        // TEST 3: Cache hit
        cache_hit = 1;
        selected_way = 1;
        hit_data = 8'h55;

        // Controller is now in LOOKUP
        #1;

        check(lru_update_en == 1,
              "LRU update enabled on cache hit");

        check(lru_access_way == 1,
              "Correct way selected for LRU update");

        // LOOKUP -> RESPONSE
        @(posedge clk);
        #1;

        check(response_valid == 1,
              "Cache hit produces valid response");

        check(response_data == 8'h55,
              "Cache hit returns correct data");

        // RESPONSE -> IDLE
        @(posedge clk);
        #1;

        check(request_ready == 1,
              "Controller returns to IDLE after hit");

        // TEST 4: Cache miss
        @(negedge clk);

        address = 4'b0110;
        request_valid = 1;
        cache_hit = 0;
        selected_way = 0;

        @(posedge clk);
        #1;

        check(request_ready == 0,
              "Controller accepts second request");

        @(negedge clk);
        request_valid = 0;

        // LOOKUP -> MEM_READ
        @(posedge clk);
        #1;

        check(mem_read_req == 1,
              "Memory read request issued on miss");

        check(mem_address == 4'b0110,
              "Correct memory address generated");

        // MEM_READ -> WAIT_MEM
        @(posedge clk);
        #1;

        check(mem_read_req == 0,
              "Memory request deasserted after one cycle");

        // WAIT_MEM: Wait for memory response
        wait(mem_ready == 1);

        @(posedge clk);
        #1;

        // Controller is now in FILL
        check(cache_write_en == 1,
              "Cache write enabled after memory response");

        check(cache_write_way == 0,
              "Correct cache way selected for refill");

        check(cache_write_tag == 3'b011,
              "Correct tag generated for refill");

        check(cache_write_data == 8'hAB,
              "Correct memory data selected for refill");

        check(lru_update_en == 1,
              "LRU updated after cache refill");

        // FILL -> RESPONSE
        @(posedge clk);
        #1;

        check(response_valid == 1,
              "Cache miss produces valid response");

        check(response_data == 8'hAB,
              "Cache miss returns memory data");

        // RESPONSE -> IDLE
        @(posedge clk);
        #1;

        check(request_ready == 1,
              "Controller returns to IDLE after miss");

        // Final result
        $display("");
        $display("==================================");
        $display("         FINAL RESULTS");
        $display("==================================");

        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0) begin
            $display("CACHE CONTROLLER TEST PASSED");
        end
        else begin
            $display("CACHE CONTROLLER TEST FAILED");
            $fatal(1, "One or more tests failed");
        end

        $display("==================================");

        $finish;

    end

endmodule
