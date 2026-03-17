`timescale 1 ns / 1 ps

module chacha20_axi_v1_0 #
(
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH  = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH  = 6,

    // Parameters of Axi Slave Bus Interface S00_AXIS
    parameter integer C_S00_AXIS_TDATA_WIDTH    = 64,

    // Parameters of Axi Master Bus Interface M00_AXIS
    parameter integer C_M00_AXIS_TDATA_WIDTH    = 64,
    parameter integer C_M00_AXIS_START_COUNT    = 32
)
(
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready,

    // Ports of Axi Slave Bus Interface S00_AXIS
    input wire  s00_axis_aclk,
    input wire  s00_axis_aresetn,
    output wire  s00_axis_tready,
    input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
    input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
    input wire  s00_axis_tlast,
    input wire  s00_axis_tvalid,

    // Ports of Axi Master Bus Interface M00_AXIS
    input wire  m00_axis_aclk,
    input wire  m00_axis_aresetn,
    output wire  m00_axis_tvalid,
    output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
    output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
    output wire  m00_axis_tlast,
    input wire  m00_axis_tready
);

    // ========================================================
    // Internal signals connecting AXI-Lite to the ChaCha20 Core
    // ========================================================
    wire [255:0] sig_key;
    wire [95:0]  sig_nonce;
    wire [31:0]  sig_counter;
    wire         sig_start;
    
    wire [511:0] sig_keystream;
    wire         sig_valid;

    // Instantiation of Axi Bus Interface S00_AXI
    chacha20_axi_v1_0_S00_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) chacha20_axi_v1_0_S00_AXI_inst (
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready),
        // Connect control registers to internal signals
        .key_out(sig_key),
        .nonce_out(sig_nonce),
        .counter_out(sig_counter),
        .start_out(sig_start)
    );

    // Instantiation of Axi Bus Interface S00_AXIS
    chacha20_axi_v1_0_S00_AXIS # ( 
        .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
    ) chacha20_axi_v1_0_S00_AXIS_inst (
        .S_AXIS_ACLK(s00_axis_aclk),
        .S_AXIS_ARESETN(s00_axis_aresetn),
        .S_AXIS_TREADY(s00_axis_tready),
        .S_AXIS_TDATA(s00_axis_tdata),
        .S_AXIS_TSTRB(s00_axis_tstrb),
        .S_AXIS_TLAST(s00_axis_tlast),
        .S_AXIS_TVALID(s00_axis_tvalid)
    );

    // Instantiation of Axi Bus Interface M00_AXIS
    chacha20_axi_v1_0_M00_AXIS # ( 
        .C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
        .C_M_START_COUNT(C_M00_AXIS_START_COUNT)
    ) chacha20_axi_v1_0_M00_AXIS_inst (
        .M_AXIS_ACLK(m00_axis_aclk),
        .M_AXIS_ARESETN(m00_axis_aresetn),
        .M_AXIS_TVALID(m00_axis_tvalid),
        .M_AXIS_TDATA(m00_axis_tdata),
        .M_AXIS_TSTRB(m00_axis_tstrb),
        .M_AXIS_TLAST(m00_axis_tlast),
        .M_AXIS_TREADY(m00_axis_tready)
    );

    // ========================================================
    // Custom ChaCha20 Core Instantiation
    // ========================================================
    chacha_core my_crypto_brain (
        .clk(s00_axi_aclk),
        .rst_n(s00_axi_aresetn),
        .start(sig_start),
        .key(sig_key),
        .nonce(sig_nonce),
        .counter(sig_counter),
        .keystream(sig_keystream),
        .valid(sig_valid)
    );

    // ========================================================
    // AXI-Stream Data Management and XOR Processing
    // ========================================================
    reg [2:0] chunk_counter;
    wire [63:0] current_keystream_chunk;

    // Splitting 512-bit keystream into 8x 64-bit chunks for streaming
    assign current_keystream_chunk =
        (chunk_counter == 3'd0) ? sig_keystream[63:0]   :
        (chunk_counter == 3'd1) ? sig_keystream[127:64]  :
        (chunk_counter == 3'd2) ? sig_keystream[191:128] :
        (chunk_counter == 3'd3) ? sig_keystream[255:192] :
        (chunk_counter == 3'd4) ? sig_keystream[319:256] :
        (chunk_counter == 3'd5) ? sig_keystream[383:320] :
        (chunk_counter == 3'd6) ? sig_keystream[447:384] :
                                  sig_keystream[511:448];

    // Real-time processing: Plaintext XOR Keystream = Ciphertext
    // Signals are routed directly to/from top-level ports for efficiency
    assign m00_axis_tdata  = s00_axis_tdata ^ current_keystream_chunk;
    assign m00_axis_tvalid = s00_axis_tvalid & sig_valid;
    assign s00_axis_tready = m00_axis_tready & sig_valid;
    assign m00_axis_tlast  = s00_axis_tlast;
    assign m00_axis_tstrb  = s00_axis_tstrb;

    // Chunk counter logic to synchronize with AXI-Stream handshakes
    always @(posedge s00_axis_aclk) begin
        if (!s00_axis_aresetn) begin
            chunk_counter <= 3'd0;
        } else if (s00_axis_tvalid && s00_axis_tready && sig_valid) begin
            chunk_counter <= chunk_counter + 3'd1;
        end
    end

endmodule
