module gray_sync #(
    parameter PTR_WIDTH = 5
)(
    input  logic                  dst_clk,
    input  logic                  dst_rst_n,

    input  logic [PTR_WIDTH-1:0]  gray_in,
    output logic [PTR_WIDTH-1:0]  gray_out
);

    logic [PTR_WIDTH-1:0] sync_ff1;

    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            sync_ff1 <= '0;
            gray_out <= '0;
        end
        else begin
            sync_ff1 <= gray_in;
            gray_out <= sync_ff1;
        end
    end

endmodule