module cla16_block (
    input  [15:0] a,
    input  [15:0] b,
    input         cin,

    output [15:0] sum,
    output        cout
);

wire c4;
wire c8;
wire c12;


cla4 CLA0 (
    .a    (a[3:0]),
    .b    (b[3:0]),
    .cin  (cin),
    .sum  (sum[3:0]),
    .cout (c4)
);


cla4 CLA1 (
    .a    (a[7:4]),
    .b    (b[7:4]),
    .cin  (c4),
    .sum  (sum[7:4]),
    .cout (c8)
);


cla4 CLA2 (
    .a    (a[11:8]),
    .b    (b[11:8]),
    .cin  (c8),
    .sum  (sum[11:8]),
    .cout (c12)
);


cla4 CLA3 (
    .a    (a[15:12]),
    .b    (b[15:12]),
    .cin  (c12),
    .sum  (sum[15:12]),
    .cout (cout)
);

endmodule
