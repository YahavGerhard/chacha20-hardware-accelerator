`timescale 1ns / 1ps

module chacha_core (
    input  wire         clk,
    input  wire         rst_n, 
    input  wire         start,     
    input  wire [255:0] key,     
    input  wire [95:0]  nonce,   
    input  wire [31:0]  counter,
    
    output reg  [511:0] keystream,
    output reg          valid
);

    localparam STATE_IDLE       = 3'd0;
    localparam STATE_INIT       = 3'd1;
    localparam STATE_ROUND_COL  = 3'd2; 
    localparam STATE_ROUND_DIAG = 3'd3;
    localparam STATE_FINALIZE   = 3'd4;
    localparam STATE_DONE       = 3'd5;

    reg [2:0] state;
    reg [4:0] round_count; 

    
    reg [31:0] init_matrix [0:15];
    reg [31:0] work_matrix [0:15];

    localparam CONST0 = 32'h61707865;
    localparam CONST1 = 32'h3320646e;
    localparam CONST2 = 32'h79622d32;
    localparam CONST3 = 32'h6b206574;

    
    wire is_diag = (state == STATE_ROUND_DIAG);

    wire [31:0] qr0_a, qr0_b, qr0_c, qr0_d;
    wire [31:0] qr1_a, qr1_b, qr1_c, qr1_d;
    wire [31:0] qr2_a, qr2_b, qr2_c, qr2_d;
    wire [31:0] qr3_a, qr3_b, qr3_c, qr3_d;

    chacha_qr worker0 (
        .a_in(work_matrix[0]), 
        .b_in(is_diag ? work_matrix[5]  : work_matrix[4]), 
        .c_in(is_diag ? work_matrix[10] : work_matrix[8]), 
        .d_in(is_diag ? work_matrix[15] : work_matrix[12]),
        .a_out(qr0_a), .b_out(qr0_b), .c_out(qr0_c), .d_out(qr0_d)
    );

    chacha_qr worker1 (
        .a_in(work_matrix[1]), 
        .b_in(is_diag ? work_matrix[6]  : work_matrix[5]), 
        .c_in(is_diag ? work_matrix[11] : work_matrix[9]), 
        .d_in(is_diag ? work_matrix[12] : work_matrix[13]),
        .a_out(qr1_a), .b_out(qr1_b), .c_out(qr1_c), .d_out(qr1_d)
    );

    chacha_qr worker2 (
        .a_in(work_matrix[2]), 
        .b_in(is_diag ? work_matrix[7]  : work_matrix[6]), 
        .c_in(is_diag ? work_matrix[8]  : work_matrix[10]), 
        .d_in(is_diag ? work_matrix[13] : work_matrix[14]),
        .a_out(qr2_a), .b_out(qr2_b), .c_out(qr2_c), .d_out(qr2_d)
    );

    chacha_qr worker3 (
        .a_in(work_matrix[3]), 
        .b_in(is_diag ? work_matrix[4]  : work_matrix[7]), 
        .c_in(is_diag ? work_matrix[9]  : work_matrix[11]), 
        .d_in(is_diag ? work_matrix[14] : work_matrix[15]),
        .a_out(qr3_a), .b_out(qr3_b), .c_out(qr3_c), .d_out(qr3_d)
    );

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            valid <= 1'b0;
            round_count <= 5'd0;
        end else begin
            case (state)
                
                STATE_IDLE: begin
                    valid <= 1'b0;
                    if (start) begin
                        state <= STATE_INIT;
                    end
                end

                STATE_INIT: begin
                    work_matrix[0] <= CONST0;  init_matrix[0] <= CONST0;
                    work_matrix[1] <= CONST1;  init_matrix[1] <= CONST1;
                    work_matrix[2] <= CONST2;  init_matrix[2] <= CONST2;
                    work_matrix[3] <= CONST3;  init_matrix[3] <= CONST3;
                    
                    work_matrix[4] <= key[255:224]; init_matrix[4] <= key[255:224];
                    work_matrix[5] <= key[223:192]; init_matrix[5] <= key[223:192];
                    work_matrix[6] <= key[191:160]; init_matrix[6] <= key[191:160];
                    work_matrix[7] <= key[159:128]; init_matrix[7] <= key[159:128];
                    work_matrix[8] <= key[127:96];  init_matrix[8] <= key[127:96];
                    work_matrix[9] <= key[95:64];   init_matrix[9] <= key[95:64];
                    work_matrix[10]<= key[63:32];   init_matrix[10]<= key[63:32];
                    work_matrix[11]<= key[31:0];    init_matrix[11]<= key[31:0];
                    
                    work_matrix[12]<= counter;      init_matrix[12]<= counter;
                    work_matrix[13]<= nonce[95:64]; init_matrix[13]<= nonce[95:64];
                    work_matrix[14]<= nonce[63:32]; init_matrix[14]<= nonce[63:32];
                    work_matrix[15]<= nonce[31:0];  init_matrix[15]<= nonce[31:0];
                    
                    round_count <= 5'd0;
                    state <= STATE_ROUND_COL;
                end

                STATE_ROUND_COL: begin
                    work_matrix[0] <= qr0_a; work_matrix[4] <= qr0_b; work_matrix[8] <= qr0_c; work_matrix[12] <= qr0_d;
                    work_matrix[1] <= qr1_a; work_matrix[5] <= qr1_b; work_matrix[9] <= qr1_c; work_matrix[13] <= qr1_d;
                    work_matrix[2] <= qr2_a; work_matrix[6] <= qr2_b; work_matrix[10]<= qr2_c; work_matrix[14] <= qr2_d;
                    work_matrix[3] <= qr3_a; work_matrix[7] <= qr3_b; work_matrix[11]<= qr3_c; work_matrix[15] <= qr3_d;
                    
                    state <= STATE_ROUND_DIAG;
                end

                STATE_ROUND_DIAG: begin
                    work_matrix[0] <= qr0_a; work_matrix[5] <= qr0_b; work_matrix[10]<= qr0_c; work_matrix[15] <= qr0_d;
                    work_matrix[1] <= qr1_a; work_matrix[6] <= qr1_b; work_matrix[11]<= qr1_c; work_matrix[12] <= qr1_d;
                    work_matrix[2] <= qr2_a; work_matrix[7] <= qr2_b; work_matrix[8] <= qr2_c; work_matrix[13] <= qr2_d;
                    work_matrix[3] <= qr3_a; work_matrix[4] <= qr3_b; work_matrix[9] <= qr3_c; work_matrix[14] <= qr3_d;
                    
                    round_count <= round_count + 5'd2;
                    
                    if (round_count == 5'd18)
                        state <= STATE_FINALIZE;
                    else
                        state <= STATE_ROUND_COL;
                end

                STATE_FINALIZE: begin
                    keystream[31:0]   <= work_matrix[0]  + init_matrix[0];
                    keystream[63:32]  <= work_matrix[1]  + init_matrix[1];
                    keystream[95:64]  <= work_matrix[2]  + init_matrix[2];
                    keystream[127:96] <= work_matrix[3]  + init_matrix[3];
                    keystream[159:128]<= work_matrix[4]  + init_matrix[4];
                    keystream[191:160]<= work_matrix[5]  + init_matrix[5];
                    keystream[223:192]<= work_matrix[6]  + init_matrix[6];
                    keystream[255:224]<= work_matrix[7]  + init_matrix[7];
                    keystream[287:256]<= work_matrix[8]  + init_matrix[8];
                    keystream[319:288]<= work_matrix[9]  + init_matrix[9];
                    keystream[351:320]<= work_matrix[10] + init_matrix[10];
                    keystream[383:352]<= work_matrix[11] + init_matrix[11];
                    keystream[415:384]<= work_matrix[12] + init_matrix[12];
                    keystream[447:416]<= work_matrix[13] + init_matrix[13];
                    keystream[479:448]<= work_matrix[14] + init_matrix[14];
                    keystream[511:480]<= work_matrix[15] + init_matrix[15];
                    
                    valid <= 1'b1;
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    if (!start) begin
                        valid <= 1'b0;
                        state <= STATE_IDLE; 
                    end
                end
                
                default: state <= STATE_IDLE; 
            endcase
        end
    end

endmodule