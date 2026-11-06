module mac8_dadda_pipeline (
    input             clk,
    input             reset,
    input             enable,

    input      [7:0]  A,
    input      [7:0]  B,

    output reg [19:0] Y
);


// ============================================================
// STAGE 1: DADDA MULTIPLIER
// ============================================================

wire [15:0] multiplier_product;

dadda8_blockcla MULTIPLIER (
    .A (A),
    .B (B),
    .P (multiplier_product)
);


// ============================================================
// PIPELINE REGISTER
// ============================================================

reg [15:0] product_reg;
reg        enable_reg;


// ============================================================
// STAGE 2: 20-bit RCA ACCUMULATOR
// ============================================================

wire [19:0] product_extended;

wire [19:0] accumulator_sum;

wire accumulator_cout;


assign product_extended = {
    4'b0000,
    product_reg
};


rca20 ACCUMULATOR_ADDER (
    .a    (Y),
    .b    (product_extended),
    .cin  (1'b0),

    .sum  (accumulator_sum),
    .cout (accumulator_cout)
);


// ============================================================
// SEQUENTIAL PIPELINE
// ============================================================

always @(posedge clk) begin

    if (reset) begin

        product_reg <= 16'd0;
        enable_reg  <= 1'b0;

        Y <= 20'd0;

    end

    else begin

        // ----------------------------------------
        // Pipeline Stage 1
        // Capture current multiplication result
        // ----------------------------------------

        product_reg <= multiplier_product;

        enable_reg <= enable;


        // ----------------------------------------
        // Pipeline Stage 2
        // Accumulate previous multiplication
        // ----------------------------------------

        if (enable_reg)

            Y <= accumulator_sum;

    end

end

endmodule
