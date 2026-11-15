`timescale 1ns/1ps

module main_memory_tb;

    reg clk;
    reg reset;
    reg read_req;
    reg write_req;
    reg [3:0] address;
    reg [7:0] write_data;

    wire ready;
    wire [7:0] read_data;

    main_memory uut (
        .clk(clk),
        .reset(reset),
        .read_req(read_req),
        .write_req(write_req),
        .address(address),
        .write_data(write_data),
        .ready(ready),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        read_req = 0;
        write_req = 0;
        address = 0;
        write_data = 0;

        // Reset memory
        @(posedge clk);
        #1 reset = 0;

        // Read address 3: expected A3
        @(negedge clk);
        address = 4'b0011;
        read_req = 1;

        @(posedge clk);
        #1;
        if (ready && read_data == 8'hA3)
            $display("PASS: Memory read");
        else
            $fatal(1, "Memory read failed");

        // Write 55 to address 3
        @(negedge clk);
        read_req = 0;
        write_req = 1;
        write_data = 8'h55;

        @(posedge clk);
        #1;
        if (ready)
            $display("PASS: Memory write");
        else
            $fatal(1, "Memory write failed");

        // Read address 3 again: expected 55
        @(negedge clk);
        write_req = 0;
        read_req = 1;

        @(posedge clk);
        #1;
        if (ready && read_data == 8'h55)
            $display("PASS: Read after write");
        else
            $fatal(1, "Read after write failed");

        // Read boundary address 4'hF: expected AF
        @(negedge clk);
        write_req = 0;
        address = 4'hF;
        read_req = 1;

        @(posedge clk);
        #1;
        if (ready && read_data == 8'hAF)
            $display("PASS: Read boundary address 4'hF");
        else
            $fatal(1, "Read boundary address 4'hF failed");

        // Test simultaneous read and write requests (should reject/no-op)
        @(negedge clk);
        address = 4'hF;
        read_req = 1;
        write_req = 1;
        write_data = 8'h99;

        @(posedge clk);
        #1;
        if (!ready)
            $display("PASS: Simultaneous read and write rejected (ready deasserted)");
        else
            $fatal(1, "Simultaneous read and write should not assert ready");

        $finish;
    end

endmodule
