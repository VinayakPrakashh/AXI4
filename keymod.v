module keypadpmod(


    input clk,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] decodeout
);

reg [19:0] Clk = 0;  // Scan counter

always @(posedge clk) begin
    if (Clk == 20'b00011000011010100000) begin
        col <= 4'b0111;
        Clk <= Clk + 1;
    end
    else if (Clk == 20'b00011000011010101000) begin
        case (row)
            4'b0111: decodeout <= 4'b0001;
            4'b1011: decodeout <= 4'b0100;
            4'b1101: decodeout <= 4'b0111;
            4'b1110: decodeout <= 4'b0000;
            default: decodeout <= 4'b0000;  // No change if no key is pressed
        endcase
        Clk <= Clk + 1;
    end
    else if (Clk == 20'b00110000110101000000) begin
        col <= 4'b1011;
        Clk <= Clk + 1;
    end
    else if (Clk == 20'b00110000110101001000) begin  // FIXED VALUE
        case (row)
            4'b0111: decodeout <= 4'b0010;
            4'b1011: decodeout <= 4'b0101;
            4'b1101: decodeout <= 4'b1000;
            4'b1110: decodeout <= 4'b1111;
            default: decodeout <= 4'b0000;
        endcase
        Clk <= Clk + 1;
    end
    else if (Clk == 20'b01001001001111100000) begin
        col <= 4'b1101;
        Clk <= Clk + 1;
    end
    else if (Clk == 20'b01001001001111101000) begin
        case (row)
            4'b0111: decodeout <= 4'b0011;
            4'b1011: decodeout <= 4'b0110;
            4'b1101: decodeout <= 4'b1001;
            4'b1110: decodeout <= 4'b1110;
            default: decodeout <= 4'b0000;
        endcase
        Clk <= Clk + 1;
    end
    else if (Clk == 20'b01100001101010000000) begin
        col <= 4'b1110;
        Clk <= Clk + 1;
    end
    else if (Clk == 20'b01100001101010001000) begin
        case (row)
            4'b0111: decodeout <= 4'b1010;
            4'b1011: decodeout <= 4'b1011;
            4'b1101: decodeout <= 4'b1100;
            4'b1110: decodeout <= 4'b1101;
            default: decodeout <= 4'b0000;
        endcase
        Clk <= 0;  // Reset scan counter
    end
    else begin
        Clk <= Clk + 1;
    end
end

endmodule