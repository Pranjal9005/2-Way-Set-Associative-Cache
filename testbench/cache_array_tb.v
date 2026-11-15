`timescale 1ns/1ps

module cache_array_tb;

    // Inputs
    reg clk;
    reg reset;
    reg set_index;
    reg way_select;
    reg write_en;

    reg [2:0] tag_in;
    reg [7:0] data_in;

    // Outputs
    wire [2:0] tag_way0;
    wire [2:0] tag_way1;

    wire [7:0] data_way0;
    wire [7:0] data_way1;

    wire valid_way0;
    wire valid_way1;

    integer passed;

    // Instantiate Cache Storage Module
    cache_array DUT (
        .clk(clk),
        .reset(reset),

        .set_index(set_index),
        .way_select(way_select),
        .write_en(write_en),

        .tag_in(tag_in),
        .data_in(data_in),

        .tag_way0(tag_way0),
        .tag_way1(tag_way1),

        .data_way0(data_way0),
        .data_way1(data_way1),

        .valid_way0(valid_way0),
        .valid_way1(valid_way1)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;


    // Task to write data into a selected cache line
    task write_line;
        input set_no;
        input way_no;
        input [2:0] tag_value;
        input [7:0] data_value;

        begin
            @(negedge clk);

            set_index = set_no;
            way_select = way_no;
            tag_in = tag_value;
            data_in = data_value;
            write_en = 1'b1;

            @(posedge clk);
            #1;

            write_en = 1'b0;
        end
    endtask


    // Task to verify both ways of a selected set
    task check_line;
        input set_no;

        input [2:0] expected_tag0;
        input [2:0] expected_tag1;

        input [7:0] expected_data0;
        input [7:0] expected_data1;

        input expected_valid0;
        input expected_valid1;

        begin
            @(negedge clk);

            set_index = set_no;
            #1;

            if ((tag_way0 !== expected_tag0) ||
                (tag_way1 !== expected_tag1) ||
                (data_way0 !== expected_data0) ||
                (data_way1 !== expected_data1) ||
                (valid_way0 !== expected_valid0) ||
                (valid_way1 !== expected_valid1)) begin

                $display("FAIL: Set %0d", set_no);

                $display("Way 0: Tag=%b Data=%b Valid=%b",
                         tag_way0, data_way0, valid_way0);

                $display("Way 1: Tag=%b Data=%b Valid=%b",
                         tag_way1, data_way1, valid_way1);

                $fatal(1, "Cache storage mismatch");
            end

            else begin
                $display("PASS: Set %0d", set_no);
                passed = passed + 1;
            end
        end
    endtask


    // Main test procedure
    initial begin

        // Initialize signals
        clk = 0;
        reset = 0;

        set_index = 0;
        way_select = 0;
        write_en = 0;

        tag_in = 0;
        data_in = 0;

        passed = 0;

        $display("================================");
        $display("       CACHE STORAGE TEST");
        $display("================================");


        // TEST 1: Reset all cache lines
        @(negedge clk);
        reset = 1;

        @(posedge clk);
        #1;

        reset = 0;

        check_line(0,
                   3'b000, 3'b000,
                   8'h00, 8'h00,
                   0, 0);

        check_line(1,
                   3'b000, 3'b000,
                   8'h00, 8'h00,
                   0, 0);


        // TEST 2: Write Set 0, Way 0
        $display("\nTEST 2: Write Set 0, Way 0");

        write_line(0, 0, 3'b101, 8'hCA);

        check_line(0,
                   3'b101, 3'b000,
                   8'hCA, 8'h00,
                   1, 0);


        // TEST 3: Write Set 0, Way 1
        $display("\nTEST 3: Write Set 0, Way 1");

        write_line(0, 1, 3'b011, 8'hAA);

        check_line(0,
                   3'b101, 3'b011,
                   8'hCA, 8'hAA,
                   1, 1);


        // TEST 4: Write Set 1, Way 0
        $display("\nTEST 4: Write Set 1, Way 0");

        write_line(1, 0, 3'b110, 8'hF0);

        check_line(1,
                   3'b110, 3'b000,
                   8'hF0, 8'h00,
                   1, 0);


        // TEST 5: Write Set 1, Way 1
        $display("\nTEST 5: Write Set 1, Way 1");

        write_line(1, 1, 3'b001, 8'h55);

        check_line(1,
                   3'b110, 3'b001,
                   8'hF0, 8'h55,
                   1, 1);


        // TEST 6: Verify Set 0 remains unchanged
        $display("\nTEST 6: Verify Set 0 Independence");

        check_line(0,
                   3'b101, 3'b011,
                   8'hCA, 8'hAA,
                   1, 1);


        // TEST 7: Reset all cache lines again
        $display("\nTEST 7: Reset Verification");

        @(negedge clk);
        reset = 1;

        @(posedge clk);
        #1;

        reset = 0;

        check_line(0,
                   3'b000, 3'b000,
                   8'h00, 8'h00,
                   0, 0);

        check_line(1,
                   3'b000, 3'b000,
                   8'h00, 8'h00,
                   0, 0);


        // Final result
        $display("\n================================");
        $display("RESULT: %0d/9 CHECKS PASSED", passed);
        $display("CACHE STORAGE TEST PASSED");
        $display("================================");

        $finish;

    end

endmodule
