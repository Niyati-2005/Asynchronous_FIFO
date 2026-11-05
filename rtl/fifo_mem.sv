module fifo_mem #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)
(
    input  logic                    wclk,
    input  logic                    w_en,
    input  logic [ADDR_WIDTH-1:0]   waddr,
    input  logic [DATA_WIDTH-1:0]   wdata,

    input  logic                    rclk,
    input  logic                    r_en,
    input  logic [ADDR_WIDTH-1:0]   raddr,
    output logic [DATA_WIDTH-1:0]   rdata
);

    localparam DEPTH = 1 << ADDR_WIDTH;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write side
    always_ff @(posedge wclk) 
	begin
        if (w_en) 
		begin
            mem[waddr] <= wdata;
        end
    end

    // Read side
    always_ff @(posedge rclk) 
	begin
        if (r_en)
		begin
            rdata <= mem[raddr];
        end
    end

endmodule