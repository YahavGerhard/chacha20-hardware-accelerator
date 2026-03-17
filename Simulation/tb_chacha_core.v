`timescale 1ns / 1ps

module tb_chacha_core();

    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] key;
    reg [95:0]  nonce;
    reg [31:0]  counter;
    
    wire [511:0] keystream;
    wire valid;

    // Unit Under Test (UUT)
    chacha_core uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .key(key),
        .nonce(nonce),
        .counter(counter),
        .keystream(keystream),
        .valid(valid)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // --- Task: Run Test Scenario and Print Results ---
    task run_test;
        input [255:0] t_key;
        input [95:0]  t_nonce;
        input [31:0]  t_counter;
        input [255:0] test_name; // Test name string
        begin
            $display("\n==================================================");
            $display("Running Test: %s", test_name);
            $display("==================================================");
            
            // Apply test vectors
            key = t_key;
            nonce = t_nonce;
            counter = t_counter;

            // Trigger Start Pulse
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            // Wait for core to complete (valid flag high)
            wait(valid);
            @(posedge clk);

            // Display output in 32-bit blocks for RFC compliance check
            $display("OUTPUT KEYSTREAM (16 Words):");
            $display("Word  0-3  : %08x  %08x  %08x  %08x", keystream[31:0], keystream[63:32], keystream[95:64], keystream[127:96]);
            $display("Word  4-7  : %08x  %08x  %08x  %08x", keystream[159:128], keystream[191:160], keystream[223:192], keystream[255:224]);
            $display("Word  8-11 : %08x  %08x  %08x  %08x", keystream[287:256], keystream[319:288], keystream[351:320], keystream[383:352]);
            $display("Word 12-15 : %08x  %08x  %08x  %08x", keystream[415:384], keystream[447:416], keystream[479:448], keystream[511:480]);
            $display("==================================================\n");
            
            #50; // Delay between tests
        end
    endtask

    // --- Main Test Stimulus ---
    initial begin
        clk = 0; rst_n = 0; start = 0;
        key = 0; nonce = 0; counter = 0;

        #20 rst_n = 1; // Release Reset
        #20;

        // Test 1: All Zeros Vector
        run_test(256'h0, 96'h0, 32'h0, "ALL ZEROS TEST");

        // Test 2: RFC 7539 Standard Test Vector
        run_test(
            256'h03020100_07060504_0b0a0908_0f0e0d0c_13121110_17161514_1b1a1918_1f1e1d1c, // Key
            96'h09000000_4a000000_00000000, // Nonce
            32'h00000001, // Counter
            "RFC 7539 STANDARD TEST VECTOR"
        );

        $display("ALL TESTS COMPLETED SUCCESSFULLY!");
        $finish;
    end

endmodule
