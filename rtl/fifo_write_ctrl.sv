module fifo_write_ctrl #(
    parameter ADDR_WIDTH = 4
)(
    input  logic                    wclk,
    input  logic                    wrst_n,
    input  logic                    w_en,
    input  logic [ADDR_WIDTH:0]     rgray_sync,
    output logic [ADDR_WIDTH-1:0]   waddr,
    output logic [ADDR_WIDTH:0]     wgray,
    output logic                    wfull
);

    logic [ADDR_WIDTH:0] wbin;
    logic [ADDR_WIDTH:0] wbin_next;
    logic [ADDR_WIDTH:0] wgray_next;
    logic winc;
    logic wfull_next;
	
    assign winc = w_en && !wfull;
    assign wbin_next = wbin + winc;
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;
    assign waddr = wbin[ADDR_WIDTH-1:0];
    assign wfull_next = (wgray_next == {~rgray_sync[ADDR_WIDTH:ADDR_WIDTH-1],rgray_sync[ADDR_WIDTH-2:0]});

    always_ff @(posedge wclk or negedge wrst_n) 
	begin
        if (!wrst_n)
		begin
            wbin  <= 1'b0;
            wgray <= 1'b0;
            wfull <= 1'b0;
        end
        else 
		begin
            wbin  <= wbin_next;
            wgray <= wgray_next;
            wfull <= wfull_next;
        end
    end

endmodule