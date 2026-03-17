`timescale 1ns / 1ps

module chacha_qr (
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] c_in,
    input  wire [31:0] d_in,
    
    output wire [31:0] a_out,
    output wire [31:0] b_out,
    output wire [31:0] c_out,
    output wire [31:0] d_out
);

    // --- Step 1 ---
    wire [31:0] a1 = a_in + b_in;
    wire [31:0] d_xor1 = d_in ^ a1;
    wire [31:0] d1 = {d_xor1[15:0], d_xor1[31:16]};

    // --- Step 2 ---
    wire [31:0] c1 = c_in + d1;
    wire [31:0] b_xor1 = b_in ^ c1;
    wire [31:0] b1 = {b_xor1[19:0], b_xor1[31:20]};

    // --- Step 3 ---
    wire [31:0] a2 = a1 + b1;
    wire [31:0] d_xor2 = d1 ^ a2;
    wire [31:0] d2 = {d_xor2[23:0], d_xor2[31:24]};

    // --- Step 4 ---
    wire [31:0] c2 = c1 + d2;
    wire [31:0] b_xor2 = b1 ^ c2;
    wire [31:0] b2 = {b_xor2[24:0], b_xor2[31:25]};

    // --- Assign Outputs ---
    assign a_out = a2;
    assign b_out = b2;
    assign c_out = c2;
    assign d_out = d2;

endmodule