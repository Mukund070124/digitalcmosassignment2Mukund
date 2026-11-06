module rca20 (
    input  [19:0] a,
    input  [19:0] b,
    input         cin,

    output [19:0] sum,
    output        cout
);

wire [20:0] carry;

assign carry[0] = cin;

genvar i;

generate

    for (i = 0; i < 20; i = i + 1) begin : RCA_STAGE

        full_adder FA (
            .a     (a[i]),
            .b     (b[i]),
            .cin   (carry[i]),
            .sum   (sum[i]),
            .carry (carry[i+1])
        );

    end

endgenerate

assign cout = carry[20];

endmodule
