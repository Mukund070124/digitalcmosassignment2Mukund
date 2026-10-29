`timescale 1ns/1ps

// ============================================================
// Common self-checking testbench for:
//   1) Baseline unpipelined MAC: module mac8
//   2) Optimized pipelined Dadda MAC: module mac8_dadda_pipeline
//
// Baseline compile: iverilog -g2012 -o sim_baseline mac8.v mac8_common_tb.v
// Optimized compile: add -DOPTIMIZED and all Dadda/adder RTL files.
// ============================================================

module mac8_common_tb;

    reg         clk;
    reg         reset;
    reg         enable;
    reg  [7:0]  A;
    reg  [7:0]  B;
    wire [19:0] Y;

    // Waveform/debug signals
    reg  [19:0] expected_y;
    reg  [15:0] prev_product;
    reg         prev_enable;
    reg  [2:0]  phase;

    integer errors;
    integer tests;
    integer i;

`ifdef OPTIMIZED
    mac8_dadda_pipeline dut (
        .clk    (clk),
        .reset  (reset),
        .enable (enable),
        .A      (A),
        .B      (B),
        .Y      (Y)
    );
`else
    mac8 dut (
        .clk    (clk),
        .reset  (reset),
        .enable (enable),
        .A      (A),
        .B      (B),
        .Y      (Y)
    );
`endif

    // 10 ns simulation clock. This is only for functional simulation.
    // Physical-design timing is checked separately at 4 ns in OpenSTA.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Apply one input pair before a rising edge and check Y after it.
    // phase:
    // 1 = directed accumulation
    // 2 = hold test
    // 3 = boundary cases
    // 4 = pipeline flush
    // 5 = random tests
    // ------------------------------------------------------------
    task apply_and_check;
        input [7:0] a_in;
        input [7:0] b_in;
        input       en_in;
        input [2:0] phase_in;
        begin
            @(negedge clk);
            A      = a_in;
            B      = b_in;
            enable = en_in;
            phase  = phase_in;

            @(posedge clk);

            if (reset) begin
                expected_y   = 20'd0;
                prev_product = 16'd0;
                prev_enable  = 1'b0;
            end
            else begin
`ifdef OPTIMIZED
                // Optimized design has a product pipeline register.
                // Current Y update uses the PREVIOUS cycle's product/enable.
                if (prev_enable)
                    expected_y = expected_y + prev_product;

                prev_product = A * B;
                prev_enable  = enable;
`else
                // Baseline unpipelined MAC accumulates the CURRENT inputs.
                if (enable)
                    expected_y = expected_y + (A * B);
`endif
            end

            #1;
            tests = tests + 1;

            if (Y !== expected_y) begin
                errors = errors + 1;
                $display(
                    "FAIL | t=%0t phase=%0d A=%0d B=%0d en=%b Y=%0d expected=%0d",
                    $time, phase, A, B, enable, Y, expected_y
                );
            end
            else if (phase_in != 5) begin
                // Print directed cases, but do not flood console for 1000 random tests.
                $display(
                    "PASS | t=%0t phase=%0d A=%0d B=%0d en=%b Y=%0d",
                    $time, phase, A, B, enable, Y
                );
            end
        end
    endtask

    initial begin

`ifdef OPTIMIZED
        $dumpfile("optimized_dadda.vcd");
`else
        $dumpfile("baseline.vcd");
`endif
        $dumpvars(0, mac8_common_tb);

        A            = 8'd0;
        B            = 8'd0;
        enable       = 1'b0;
        reset        = 1'b1;
        expected_y   = 20'd0;
        prev_product = 16'd0;
        prev_enable  = 1'b0;
        phase        = 3'd0;
        errors       = 0;
        tests        = 0;

        // ========================================================
        // RESET TEST
        // ========================================================
        repeat (2) begin
            @(posedge clk);
            #1;
            if (Y !== 20'd0) begin
                errors = errors + 1;
                $display("FAIL RESET | t=%0t Y=%0d", $time, Y);
            end
        end

        @(negedge clk);
        reset = 1'b0;

        // ========================================================
        // DIRECTED ACCUMULATION
        // ========================================================
        apply_and_check(8'd3,   8'd5,   1'b1, 3'd1);  // 15
        apply_and_check(8'd2,   8'd7,   1'b1, 3'd1);  // 14
        apply_and_check(8'd10,  8'd4,   1'b1, 3'd1);  // 40

        // ========================================================
        // HOLD OPERATION
        // ========================================================
        apply_and_check(8'd99,  8'd77,  1'b0, 3'd2);

        // ========================================================
        // BOUNDARY CASES
        // ========================================================
        apply_and_check(8'd0,   8'd255, 1'b1, 3'd3);  // A = 0
        apply_and_check(8'd255, 8'd0,   1'b1, 3'd3);  // B = 0
        apply_and_check(8'd255, 8'd255, 1'b1, 3'd3);  // maximum product
        apply_and_check(8'd1,   8'd1,   1'b1, 3'd3);

`ifdef OPTIMIZED
        // Flush the final directed product into Y.
        apply_and_check(8'd0, 8'd0, 1'b0, 3'd4);
`endif

        // ========================================================
        // 1000 RANDOM TESTS
        // ========================================================
        for (i = 0; i < 1000; i = i + 1) begin
            apply_and_check(
                $random,
                $random,
                $random,
                3'd5
            );
        end

`ifdef OPTIMIZED
        // Flush final random transaction.
        apply_and_check(8'd0, 8'd0, 1'b0, 3'd4);
`endif

        // ========================================================
        // FINAL RESULT
        // ========================================================
        if (errors == 0) begin
`ifdef OPTIMIZED
            $display("============================================================");
            $display("PASS: OPTIMIZED DADDA MAC - all %0d checks passed.", tests);
            $display("============================================================");
`else
            $display("============================================================");
            $display("PASS: BASELINE MAC - all %0d checks passed.", tests);
            $display("============================================================");
`endif
        end
        else begin
            $display("============================================================");
            $display("FAIL: %0d errors detected out of %0d checks.", errors, tests);
            $display("============================================================");
        end

        #20;
        $finish;
    end

endmodule
