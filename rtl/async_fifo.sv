module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    // =========================
    // WRITE CLOCK DOMAIN
    // =========================
    input  logic                   wclk,
    input  logic                   wrst_n,
    input  logic                   w_en,
    input  logic [DATA_WIDTH-1:0]  wdata,
    output logic                   wfull,

    // =========================
    // READ CLOCK DOMAIN
    // =========================
    input  logic                   rclk,
    input  logic                   rrst_n,
    input  logic                   r_en,
    output logic [DATA_WIDTH-1:0]  rdata,
    output logic                   rempty
);

    // Pointer width = address width + 1
	
    localparam PTR_WIDTH = ADDR_WIDTH + 1;


    // =========================================================
    // INTERNAL SIGNALS
    // =========================================================

    // Write pointer
    logic [PTR_WIDTH-1:0] wgray;

    // Read pointer
    logic [PTR_WIDTH-1:0] rgray;

    // Read pointer synchronized into WRITE domain
    logic [PTR_WIDTH-1:0] rgray_sync;

    // Write pointer synchronized into READ domain
    logic [PTR_WIDTH-1:0] wgray_sync;

    // Memory addresses
    logic [ADDR_WIDTH-1:0] waddr;
    logic [ADDR_WIDTH-1:0] raddr;


    // =========================================================
    // WRITE ENABLE TO MEMORY
    // =========================================================

    logic mem_w_en;
    logic  mem_r_en;
    assign mem_w_en = w_en && !wfull;
    assign mem_r_en = r_en && !rempty;


    // =========================================================
    // WRITE POINTER CONTROLLER
    // =========================================================

    fifo_write_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH)) 
	write_ctrl (
        .wclk       (wclk),
        .wrst_n     (wrst_n),
        .w_en       (w_en),
        .rgray_sync (rgray_sync),
        .waddr      (waddr),
        .wgray      (wgray),
        .wfull      (wfull)        
		);


    // =========================================================
    // READ POINTER CONTROLLER
    // =========================================================

    fifo_read_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH)) 
	read_ctrl (
        .rclk       (rclk),
        .rrst_n     (rrst_n),
        .r_en       (r_en),
        .wgray_sync (wgray_sync),
        .raddr      (raddr),
        .rgray      (rgray),
        .rempty     (rempty)
    );

    gray_sync #(
        .PTR_WIDTH(PTR_WIDTH)) 
		wptr_sync (
        .dst_clk   (rclk),
        .dst_rst_n (rrst_n),
        .gray_in   (wgray),
        .gray_out  (wgray_sync)
    );

    gray_sync #(
        .PTR_WIDTH(PTR_WIDTH)) 
		rptr_sync (
        .dst_clk   (wclk),
        .dst_rst_n (wrst_n),

        .gray_in   (rgray),
        .gray_out  (rgray_sync)
    );


    // =========================================================
    // DUAL CLOCK FIFO MEMORY
    // =========================================================

    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory (
        // Write side
        .wclk  (wclk),
        .w_en  (mem_w_en),
        .waddr (waddr),
        .wdata (wdata),

        // Read side
        .rclk  (rclk),
        .r_en  (mem_r_en),
        .raddr (raddr),
        .rdata (rdata)
    );

endmodule