`timescale 1ns/1ps

module cache_controller (
    input clk,
    input reset,

    // CPU interface
    input request_valid,
    output request_ready,
    input [3:0] address,

    output reg [7:0] response_data,
    output reg response_valid,

    // Cache lookup results
    input cache_hit,
    input selected_way,
    input [7:0] hit_data,

    // Main memory interface
    output reg mem_read_req,
    output reg [3:0] mem_address,
    input mem_ready,
    input [7:0] mem_read_data,

    // Cache fill interface
    output reg cache_write_en,
    output reg cache_write_way,
    output reg [2:0] cache_write_tag,
    output reg [7:0] cache_write_data,

    // LRU update interface
    output reg lru_update_en,
    output reg lru_access_way
);

    // FSM states
    localparam IDLE     = 3'b000;
    localparam LOOKUP   = 3'b001;
    localparam MEM_READ = 3'b010;
    localparam WAIT_MEM = 3'b011;
    localparam FILL     = 3'b100;
    localparam RESPONSE = 3'b101;

    reg [2:0] state, next_state;

    // Internal registers
    reg [3:0] address_reg;
    reg [7:0] memory_data_reg;
    reg [7:0] response_data_reg;
    reg selected_way_reg;

    // CPU can submit a request when controller is idle
    assign request_ready = (state == IDLE);

    // Sequential logic
    always @(posedge clk) begin

        if (reset) begin
            state <= IDLE;
            address_reg <= 4'b0;
            memory_data_reg <= 8'b0;
            response_data_reg <= 8'b0;
            selected_way_reg <= 1'b0;
        end

        else begin
            state <= next_state;

            // Accept and store CPU request
            if (state == IDLE && request_valid)
                address_reg <= address;

            // Store selected way during lookup
            if (state == LOOKUP)
                selected_way_reg <= selected_way;

            // Store data on cache hit
            if (state == LOOKUP && cache_hit)
                response_data_reg <= hit_data;

            // Capture main memory response
            if (state == WAIT_MEM && mem_ready)
                memory_data_reg <= mem_read_data;

            // Prepare CPU response after refill
            if (state == FILL)
                response_data_reg <= memory_data_reg;

        end
    end

    // Next-state logic
    always @(*) begin

        next_state = state;

        case (state)

            IDLE: begin
                if (request_valid)
                    next_state = LOOKUP;
            end

            LOOKUP: begin
                if (cache_hit)
                    next_state = RESPONSE;
                else
                    next_state = MEM_READ;
            end

            MEM_READ: begin
                next_state = WAIT_MEM;
            end

            WAIT_MEM: begin
                if (mem_ready)
                    next_state = FILL;
            end

            FILL: begin
                next_state = RESPONSE;
            end

            RESPONSE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // Combinational output logic
    always @(*) begin

        mem_read_req = 1'b0;
        mem_address = address_reg;

        cache_write_en = 1'b0;
        cache_write_way = selected_way_reg;
        cache_write_tag = address_reg[3:1];
        cache_write_data = memory_data_reg;

        lru_update_en = 1'b0;
        lru_access_way = selected_way_reg;

        response_data = response_data_reg;
        response_valid = 1'b0;

        case (state)

            LOOKUP: begin
                if (cache_hit) begin
                    lru_update_en = 1'b1;
                    lru_access_way = selected_way;
                end
            end

            MEM_READ: begin
                mem_read_req = 1'b1;
            end

            FILL: begin
                cache_write_en = 1'b1;
                lru_update_en = 1'b1;
            end

            RESPONSE: begin
                response_valid = 1'b1;
            end

        endcase

    end

endmodule
