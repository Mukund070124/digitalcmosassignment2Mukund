module mac8 (
    input        clk,
    input        reset,
    input        enable,
    input  [7:0] A,
    input  [7:0] B,
    output reg [19:0] Y
);

    always @(posedge clk) begin
        if (reset)
            Y <= 20'd0;
        else if (enable)
            Y <= Y + (A * B);
    end

endmodule
