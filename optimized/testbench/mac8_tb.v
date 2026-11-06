`timescale 1ns/1ps

module tb_mac8_dadda_pipeline;

    reg         clk;
    reg         reset;
    reg         enable;
    reg  [7:0]  A;
    reg  [7:0]  B;

    wire [19:0] Y;

    // Reference model
    reg [19:0] expected_y;

    // Previous-cycle values because optimized design is pipelined
    reg [15:0] prev_product;
    reg        prev_enable;

    // Only for easy GTKWave understanding
    reg [2:0] phase;

    integer errors;
    integer tests;
    integer i;


    // ============================================================
    // DUT
    // ============================================================
    mac8_dadda_pipeline dut (
        .clk    (clk),
        .reset  (reset),
        .enable (enable),
        .A      (A),
        .B      (B),
        .Y      (Y)
    );


    // ============================================================
    // CLOCK
    // ============================================================
    initial clk = 0;
    always #5 clk = ~clk;


    // ============================================================
    // APPLY INPUT AND CHECK
    // ============================================================
    task apply_and_check;

        input [7:0] a_in;
        input [7:0] b_in;
        input       en_in;
        input [2:0] phase_in;

        begin

            // Apply before active clock edge
            @(negedge clk);

            A      = a_in;
            B      = b_in;
            enable = en_in;
            phase  = phase_in;

            @(posedge clk);

            // Dadda pipeline:
            // current Y update uses PREVIOUS product
            if (prev_enable)
                expected_y = expected_y + prev_product;

            // Save current multiplication for next cycle
            prev_product = A * B;
            prev_enable  = enable;

            #1;

            tests = tests + 1;

            if (Y !== expected_y) begin

                errors = errors + 1;

                $display(
                    "FAIL | A=%0d B=%0d en=%b | Y=%0d Expected=%0d",
                    A, B, enable, Y, expected_y
                );

            end
            else if (phase_in != 5) begin

                $display(
                    "PASS | A=%0d B=%0d en=%b | Y=%0d",
                    A, B, enable, Y
                );

            end

        end

    endtask


    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    initial begin

        $dumpfile("dadda_pipeline.vcd");
        $dumpvars(0, tb_mac8_dadda_pipeline);

        A            = 0;
        B            = 0;
        enable       = 0;
        reset        = 1;

        expected_y   = 0;
        prev_product = 0;
        prev_enable  = 0;

        errors       = 0;
        tests        = 0;
        phase        = 0;


        // ========================================================
        // TEST 1 : RESET
        // ========================================================

        repeat (2) begin

            @(posedge clk);
            #1;

            if (Y !== 20'd0) begin
                errors = errors + 1;
                $display("FAIL RESET | Y=%0d", Y);
            end
            else begin
                $display("PASS RESET | Y=0");
            end

        end

        @(negedge clk);
        reset = 0;


        // ========================================================
        // TEST 2 : NORMAL ACCUMULATION
        // Same type of directed tests as baseline
        // ========================================================

        apply_and_check(8'd3,  8'd5, 1'b1, 3'd1);
        apply_and_check(8'd2,  8'd7, 1'b1, 3'd1);
        apply_and_check(8'd10, 8'd4, 1'b1, 3'd1);


        // ========================================================
        // TEST 3 : PIPELINE FLUSH
        // Makes sure previous 10*4 reaches accumulator
        // ========================================================

        apply_and_check(
            8'd0,
            8'd0,
            1'b0,
            3'd4
        );


        // ========================================================
        // TEST 4 : HOLD WHEN ENABLE = 0
        // ========================================================

        apply_and_check(
            8'd99,
            8'd77,
            1'b0,
            3'd2
        );


        // ========================================================
        // TEST 5 : A = 0
        // ========================================================

        apply_and_check(
            8'd0,
            8'd100,
            1'b1,
            3'd3
        );


        // ========================================================
        // TEST 6 : B = 0
        // ========================================================

        apply_and_check(
            8'd100,
            8'd0,
            1'b1,
            3'd3
        );


        // ========================================================
        // TEST 7 : A = 255
        // ========================================================

        apply_and_check(
            8'd255,
            8'd10,
            1'b1,
            3'd3
        );


        // ========================================================
        // TEST 8 : B = 255
        // ========================================================

        apply_and_check(
            8'd10,
            8'd255,
            1'b1,
            3'd3
        );


        // ========================================================
        // TEST 9 : MAXIMUM PRODUCT
        // 255 * 255 = 65025
        // ========================================================

        apply_and_check(
            8'd255,
            8'd255,
            1'b1,
            3'd3
        );


        // Flush final directed product
        apply_and_check(
            8'd0,
            8'd0,
            1'b0,
            3'd4
        );


        // ========================================================
        // TEST 10 : 1000 RANDOM TESTS
        // ========================================================

        for (i = 0; i < 1000; i = i + 1) begin

            apply_and_check(
                $random,
                $random,
                $random,
                3'd5
            );

        end


        // Final pipeline flush
        apply_and_check(
            8'd0,
            8'd0,
            1'b0,
            3'd4
        );


        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display(
            "===================================================="
        );

        if (errors == 0) begin

            $display(
                "PASS: DADDA PIPELINED MAC"
            );

            $display(
                "ALL %0d TESTS PASSED",
                tests
            );

        end
        else begin

            $display(
                "FAIL: %0d ERRORS OUT OF %0d TESTS",
                errors,
                tests
            );

        end

        $display(
            "===================================================="
        );

        #20;
        $finish;

    end

endmodule
