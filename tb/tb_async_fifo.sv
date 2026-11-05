`timescale 1ns/1ps

module tb_async_fifo;

    // ============================================================
    // PARAMETERS
    // ============================================================

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 4;

    localparam FIFO_DEPTH = (1 << ADDR_WIDTH);
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;


    // ============================================================
    // SIGNALS
    // ============================================================

    logic                   wclk;
    logic                   rclk;

    logic                   wrst_n;
    logic                   rrst_n;

    logic                   w_en;
    logic [DATA_WIDTH-1:0]  wdata;
    logic                   wfull;

    logic                   r_en;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   rempty;


    // ============================================================
    // DUT
    // ============================================================

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .w_en   (w_en),
        .wdata  (wdata),
        .wfull  (wfull),

        .rclk   (rclk),
        .rrst_n (rrst_n),
        .r_en   (r_en),
        .rdata  (rdata),
        .rempty (rempty)
    );


    // ============================================================
    // REFERENCE MODEL
    // ============================================================

    logic [DATA_WIDTH-1:0] expected_fifo[$];

    int total_writes;
    int total_reads;

    int write_errors;
    int read_errors;

    int test_errors;


    // ============================================================
    // CLOCK GENERATION
    // ============================================================

    // Write clock = 10 ns period
    initial begin
        wclk = 1'b0;

        forever #5 wclk = ~wclk;
    end


    // Read clock = 14 ns period
    initial begin
        rclk = 1'b0;

        forever #7 rclk = ~rclk;
    end


    // ============================================================
    // RESET
    // ============================================================

    task automatic reset_fifo();

        begin

            wrst_n = 1'b0;
            rrst_n = 1'b0;

            w_en   = 1'b0;
            r_en   = 1'b0;
            wdata  = 1'b0;

            repeat (4)@(posedge wclk);
            repeat (4)@(posedge rclk);

            wrst_n = 1'b1;
            rrst_n = 1'b1;

            // Allow both domains to settle
            repeat (3)@(posedge wclk);
            repeat (3)@(posedge rclk);

            $display("");
            $display("================================================");
            $display("RESET COMPLETE");
            $display("================================================");

        end

    endtask


    // ============================================================
    // WRITE TASK
    // ============================================================

    task automatic fifo_write(
        input logic [DATA_WIDTH-1:0] data
    );

        begin

            // Wait for a write clock
            @(posedge wclk);

            // Wait until FIFO has space
            while (wfull) begin
                @(posedge wclk);
            end

            // Drive write transaction
            wdata <= data;
            w_en  <= 1'b1;

            // The write is accepted on this clock edge
            @(posedge wclk);

            // Update reference model
            expected_fifo.push_back(data);

            total_writes++;

            $display(
                "[WRITE] time=%0t data=0x%08h expected_depth=%0d",
                $time,
                data,
                expected_fifo.size()
            );

            w_en <= 1'b0;

        end

    endtask


    // ============================================================
    // READ TASK
    // ============================================================

    task automatic fifo_read();

        logic [DATA_WIDTH-1:0] expected_data;

        begin

            @(posedge rclk);

            // Wait until data is available
            while (rempty) begin
                @(posedge rclk);
            end

            // The reference model must contain data
            if (expected_fifo.size() == 0) begin

                $error(
                    "[READ ERROR] DUT indicates non-empty but reference FIFO is empty"
                );

                read_errors++;
                test_errors++;

            end
            else begin

                // Expected FIFO data
                expected_data = expected_fifo.pop_front();

                // Request read
                r_en <= 1'b1;

                // DUT memory is registered, therefore allow
                // the read clock edge to update rdata.
                @(posedge rclk);

                #1;

                r_en <= 1'b0;

                total_reads++;

                if (rdata !== expected_data) begin

                    $error(
                        "[READ FAIL] time=%0t expected=0x%08h actual=0x%08h",
                        $time,
                        expected_data,
                        rdata
                    );

                    read_errors++;
                    test_errors++;

                end
                else begin

                    $display(
                        "[READ PASS] time=%0t expected=0x%08h actual=0x%08h remaining=%0d",
                        $time,
                        expected_data,
                        rdata,
                        expected_fifo.size()
                    );

                end

            end

        end

    endtask


    // ============================================================
    // TEST 1
    // RESET / INITIAL EMPTY
    // ============================================================

    task automatic test_reset();

        begin

            $display("");
            $display("================================================");
            $display("TEST 1 : RESET");
            $display("================================================");

            reset_fifo();

            if (rempty !== 1'b1) begin

                $error(
                    "[FAIL] FIFO should be EMPTY after reset"
                );

                test_errors++;

            end
            else begin

                $display(
                    "[PASS] FIFO is EMPTY after reset"
                );

            end


            if (wfull !== 1'b0) begin

                $error(
                    "[FAIL] FIFO should NOT be FULL after reset"
                );

                test_errors++;

            end
            else begin

                $display(
                    "[PASS] FIFO is NOT FULL after reset"
                );

            end

        end

    endtask


    // ============================================================
    // TEST 2
    // BASIC FIFO OPERATION
    // ============================================================

    task automatic test_basic();

        begin

            $display("");
            $display("================================================");
            $display("TEST 2 : BASIC WRITE / READ");
            $display("================================================");

            fifo_write(32'hAAAA_0001);
            fifo_write(32'hAAAA_0002);
            fifo_write(32'hAAAA_0003);
            fifo_write(32'hAAAA_0004);

            // Allow write pointer synchronization
            repeat (5)
                @(posedge rclk);

            fifo_read();
            fifo_read();
            fifo_read();
            fifo_read();

            repeat (4)
                @(posedge rclk);

            if (rempty !== 1'b1) begin

                $error(
                    "[FAIL] FIFO should be EMPTY after reading all data"
                );

                test_errors++;

            end
            else begin

                $display(
                    "[PASS] FIFO became EMPTY after all reads"
                );

            end

        end

    endtask


    // ============================================================
    // TEST 3
    // FIFO ORDER
    // ============================================================

    task automatic test_order();

        begin

            $display("");
            $display("================================================");
            $display("TEST 3 : FIFO ORDERING");
            $display("================================================");

            fifo_write(32'h1111_1111);
            fifo_write(32'h2222_2222);
            fifo_write(32'h3333_3333);
            fifo_write(32'h4444_4444);
            fifo_write(32'h5555_5555);

            repeat (5)
                @(posedge rclk);

            fifo_read();
            fifo_read();
            fifo_read();
            fifo_read();
            fifo_read();

            $display(
                "[PASS] FIFO ordering verified using reference queue"
            );

        end

    endtask


    // ============================================================
    // TEST 4
    // FILL FIFO TO FULL
    // ============================================================

    task automatic test_full();

        int i;

        begin

            $display("");
            $display("================================================");
            $display("TEST 4 : FULL CONDITION");
            $display("================================================");

            // Fill FIFO completely
            for (i = 0; i < FIFO_DEPTH; i++) begin

                fifo_write(
                    32'hF000_0000 + i
                );

            end

            // Give write-domain logic time to update FULL
            repeat (3)
                @(posedge wclk);

            if (wfull !== 1'b1) begin

                $error(
                    "[FAIL] FIFO should be FULL after %0d writes",
                    FIFO_DEPTH
                );

                test_errors++;

            end
            else begin

                $display(
                    "[PASS] FIFO reached FULL after %0d writes",
                    FIFO_DEPTH
                );

            end

        end

    endtask


    // ============================================================
    // TEST 5
    // EMPTY CONDITION
    // ============================================================

    task automatic test_empty();

        int i;

        begin

            $display("");
            $display("================================================");
            $display("TEST 5 : EMPTY CONDITION");
            $display("================================================");

            // Read everything remaining
            while (expected_fifo.size() != 0) begin

                fifo_read();

            end

            repeat (5)
                @(posedge rclk);

            if (rempty !== 1'b1) begin

                $error(
                    "[FAIL] FIFO should be EMPTY"
                );

                test_errors++;

            end
            else begin

                $display(
                    "[PASS] FIFO reached EMPTY"
                );

            end

        end

    endtask


    // ============================================================
    // TEST 6
    // RANDOM TRAFFIC
    // ============================================================

    task automatic test_random();

        int i;
        int operation;
        logic [DATA_WIDTH-1:0] random_data;

        begin

            $display("");
            $display("================================================");
            $display("TEST 6 : RANDOM TRAFFIC");
            $display("================================================");

            // Start from a clean FIFO
            reset_fifo();

            // Make sure reference model is empty
            expected_fifo.delete();

            for (i = 0; i < 100; i++) begin

                operation = $urandom_range(0, 1);

                if (operation == 0) begin

                    // WRITE
                    random_data = $urandom();

                    fifo_write(random_data);

                end
                else begin

                    // READ only if reference model contains data
                    if (expected_fifo.size() != 0) begin

                        fifo_read();

                    end
                    else begin

                        // If empty, perform a write instead
                        random_data = $urandom();

                        fifo_write(random_data);

                    end

                end

            end

            // Drain remaining data
            while (expected_fifo.size() != 0) begin

                fifo_read();

            end

            repeat (5)
                @(posedge rclk);

            if (test_errors == 0) begin

                $display(
                    "[PASS] Random traffic completed successfully"
                );

            end

        end

    endtask


    // ============================================================
    // ASSERTIONS
    // ============================================================

    // ------------------------------------------------------------
    // When FIFO is full, the write pointer must not advance.
    // ------------------------------------------------------------

    property full_holds_write_pointer;

        @(posedge wclk)
        wfull |=> $stable(dut.write_ctrl.wgray);

    endproperty

    assert property (full_holds_write_pointer)
        else $error(
            "[ASSERTION FAIL] Write pointer changed while FIFO was FULL"
        );


    // ------------------------------------------------------------
    // When FIFO is empty, the read pointer must not advance.
    // ------------------------------------------------------------

    property empty_holds_read_pointer;

        @(posedge rclk)
        rempty |=> $stable(dut.read_ctrl.rgray);

    endproperty

    assert property (empty_holds_read_pointer)
        else $error(
            "[ASSERTION FAIL] Read pointer changed while FIFO was EMPTY"
        );


    // ------------------------------------------------------------
    // Gray pointer must change by at most one bit.
    // ------------------------------------------------------------

    property write_gray_one_bit_change;

        @(posedge wclk)
        $countones(
            dut.write_ctrl.wgray ^
            $past(dut.write_ctrl.wgray)
        ) <= 1;

    endproperty

    assert property (write_gray_one_bit_change)
        else $error(
            "[ASSERTION FAIL] Write Gray pointer changed by more than one bit"
        );


    property read_gray_one_bit_change;

        @(posedge rclk)
        $countones(
            dut.read_ctrl.rgray ^
            $past(dut.read_ctrl.rgray)
        ) <= 1;

    endproperty

    assert property (read_gray_one_bit_change)
        else $error(
            "[ASSERTION FAIL] Read Gray pointer changed by more than one bit"
        );


    // ============================================================
    // FUNCTIONAL COVERAGE
    // ============================================================

    covergroup write_cg @(posedge wclk);

        coverpoint w_en {

            bins no_write = {0};
            bins write    = {1};

        }

        coverpoint wfull {

            bins not_full = {0};
            bins full     = {1};

        }

        cross w_en, wfull;

    endgroup


    covergroup read_cg @(posedge rclk);

        coverpoint r_en {

            bins no_read = {0};
            bins read    = {1};

        }

        coverpoint rempty {

            bins not_empty = {0};
            bins empty     = {1};

        }

        cross r_en, rempty;

    endgroup


    write_cg write_coverage = new();
    read_cg  read_coverage  = new();


    // ============================================================
    // FINAL REPORT
    // ============================================================

    task automatic print_report();

        begin

            $display("");
            $display("");
            $display("================================================");
            $display("          ASYNCHRONOUS FIFO REPORT");
            $display("================================================");

            $display(
                "FIFO DEPTH       : %0d",
                FIFO_DEPTH
            );

            $display(
                "DATA WIDTH       : %0d bits",
                DATA_WIDTH
            );

            $display(
                "TOTAL WRITES     : %0d",
                total_writes
            );

            $display(
                "TOTAL READS      : %0d",
                total_reads
            );

            $display(
                "WRITE ERRORS     : %0d",
                write_errors
            );

            $display(
                "READ ERRORS      : %0d",
                read_errors
            );

            $display(
                "REFERENCE QUEUE  : %0d entries",
                expected_fifo.size()
            );

            $display(
                "TEST ERRORS      : %0d",
                test_errors
            );

            $display("");
            $display(
                "WRITE COVERAGE   : %0.2f%%",
                write_coverage.get_inst_coverage()
            );

            $display(
                "READ COVERAGE    : %0.2f%%",
                read_coverage.get_inst_coverage()
            );

            $display("");

            if (test_errors == 0) begin

                $display("===============================================");
                $display("             *** TEST PASSED ***");
                $display("===============================================");

            end
            else begin

                $display("===============================================");
                $display("             *** TEST FAILED ***");
                $display("===============================================");

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // Initial values
        wrst_n = 1'b0;
        rrst_n = 1'b0;

        w_en  = 1'b0;
        r_en  = 1'b0;
        wdata = '0;

        total_writes = 0;
        total_reads  = 0;

        write_errors = 0;
        read_errors  = 0;
        test_errors  = 0;

        expected_fifo.delete();


        // --------------------------------------------------------
        // Run tests
        // --------------------------------------------------------

        test_reset();

        test_basic();

        test_order();

        test_full();

        test_empty();

        test_random();


        // --------------------------------------------------------
        // Final report
        // --------------------------------------------------------

        print_report();

        #100;

        $finish;

    end

endmodule