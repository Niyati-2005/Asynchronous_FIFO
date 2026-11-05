module fifo_read_ctrl #(
    parameter ADDR_WIDTH = 4)
	(
    input  logic                    rclk,
    input  logic                    rrst_n,
    input  logic                    r_en,
    // Write pointer synchronized into read domain
    input  logic [ADDR_WIDTH:0]     wgray_sync,
    output logic [ADDR_WIDTH-1:0]   raddr,
    output logic [ADDR_WIDTH:0]     rgray,
    output logic                    rempty
);
    logic [ADDR_WIDTH:0] rbin;
    logic [ADDR_WIDTH:0] rbin_next;
    logic [ADDR_WIDTH:0] rgray_next;
    logic rinc;
    logic rempty_next;

    // Read operation is allowed only when FIFO is not empty
    assign rinc = r_en && !rempty;
    // Next binary pointer
    assign rbin_next = rbin + rinc;
    // Binary -> Gray
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;
    // Memory address
    assign raddr = rbin[ADDR_WIDTH-1:0];
    // Empty detection
    assign rempty_next = (rgray_next == wgray_sync);

    always_ff @(posedge rclk or negedge rrst_n) 
	begin
        if (!rrst_n) 
		begin
            rbin   <= 1'b0;
            rgray  <= 1'b0;
            rempty <= 1'b1;
        end
        else 
		begin
            rbin   <= rbin_next;
            rgray  <= rgray_next;
            rempty <= rempty_next;
        end
    end

endmodule