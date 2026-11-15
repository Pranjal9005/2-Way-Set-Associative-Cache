`timescale 1ns/1ps

module cache_2way (
    input wire clk,
    input wire reset,

    // CPU interface
    input wire request_valid,
    input wire [3:0] cpu_address,

    output wire request_ready,
    output wire response_valid,
    output wire [7:0] cpu_read_data,
    output wire cache_hit
);

    // --------------------------------
    // Internal signals
    // --------------------------------

    // Controller signals
    wire [3:0] mem_address;
    wire mem_read_req;
    wire mem_ready;
    wire [7:0] mem_read_data;

    wire cache_write_en;
    wire [2:0] cache_write_tag;
    wire [7:0] cache_write_data;
    wire cache_write_way;

    wire lru_update_en;
    wire lru_access_way;

    // Address decoder
    wire [2:0] requested_tag;
    wire set_index;

    // Cache array outputs
    wire [2:0] tag_way0;
    wire [2:0] tag_way1;

    wire [7:0] data_way0;
    wire [7:0] data_way1;

    wire valid_way0;
    wire valid_way1;

    // Tag comparator
    wire tag_match_way0;
    wire tag_match_way1;

    // LRU
    wire lru_bit;

    // Hit/miss unit
    wire selected_way;
    wire hit;

    // Selected cache data
    wire [7:0] hit_data;

    assign cache_hit = hit;

    // --------------------------------
    // 1. Cache Controller
    // --------------------------------

    cache_controller controller (
        .clk(clk),
        .reset(reset),

        .request_valid(request_valid),
        .request_ready(request_ready),
        .address(cpu_address),

        .response_data(cpu_read_data),
        .response_valid(response_valid),

        .cache_hit(hit),
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


    // --------------------------------
    // 2. Address Decoder
    // --------------------------------

    address_decoder decoder (
        .address(mem_address),
        .tag(requested_tag),
        .set_index(set_index)
    );


    // --------------------------------
    // 3. Cache Array
    // --------------------------------

    cache_array cache (
        .clk(clk),
        .reset(reset),

        .set_index(set_index),
        .way_select(cache_write_way),

        .write_en(cache_write_en),
        .tag_in(cache_write_tag),
        .data_in(cache_write_data),

        .tag_way0(tag_way0),
        .tag_way1(tag_way1),

        .data_way0(data_way0),
        .data_way1(data_way1),

        .valid_way0(valid_way0),
        .valid_way1(valid_way1)
    );


    // --------------------------------
    // 4. Tag Comparator
    // --------------------------------

    tag_comparator comparator (
        .requested_tag(requested_tag),

        .tag_way0(tag_way0),
        .tag_way1(tag_way1),

        .tag_match_way0(tag_match_way0),
        .tag_match_way1(tag_match_way1)
    );


    // --------------------------------
    // 5. LRU Unit
    // --------------------------------

    lru_unit lru (
        .clk(clk),
        .reset(reset),

        .set_index(set_index),
        .update_en(lru_update_en),

        .access_valid(1'b1),
        .access_way(lru_access_way),

        .lru_bit(lru_bit)
    );


    // --------------------------------
    // 6. Hit/Miss Unit
    // --------------------------------

    hit_miss_unit hit_miss (
        .valid_way0(valid_way0),
        .valid_way1(valid_way1),

        .tag_match_way0(tag_match_way0),
        .tag_match_way1(tag_match_way1),

        .lru_bit(lru_bit),

        .hit_way0(),
        .hit_way1(),

        .cache_hit(hit),
        .cache_miss(),
        .selected_way(selected_way)
    );


    // --------------------------------
    // 7. Select Hit Data
    // --------------------------------

    assign hit_data = selected_way ? data_way1 : data_way0;


    // --------------------------------
    // 8. Main Memory
    // --------------------------------

    main_memory memory (
        .clk(clk),
        .reset(reset),

        .read_req(mem_read_req),
        .write_req(1'b0),

        .address(mem_address),
        .write_data(8'b0),

        .read_data(mem_read_data),
        .ready(mem_ready)
    );

endmodule
