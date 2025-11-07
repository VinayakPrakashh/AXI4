module APB_MUX #(
    parameter ADDR_WIDTH = 10,
    parameter OP_ADDR_WIDTH = 2,
    parameter DATA_WIDTH = 32
) (
    input PSEL,
    input [ADDR_WIDTH-1:0]PADDR,
    input PREADY_0,
    input PREADY_1,
    input [DATA_WIDTH-1:0]PRDATA_0,
    input [DATA_WIDTH-1:0]PRDATA_1,
    input PSLVERR_0,
    input PSLVERR_1,
    output reg PSEL_0,
    output reg PSEL_1,
    output reg PSLVERR,
    output reg [DATA_WIDTH-1:0]PRDATA,
    output reg PREADY

);
wire slave_select;

always @(*) begin
    if (PSEL) begin
        if (slave_select == 1'b0) begin
            PSEL_0 = 1'b1;
            PSEL_1 = 1'b0;
            PRDATA = PRDATA_0;
            PSLVERR = PSLVERR_0;
            PREADY = PREADY_0;
        end else begin
            PSEL_0 = 1'b0;
            PSEL_1 = 1'b1;
            PRDATA = PRDATA_1;
            PSLVERR = PSLVERR_1;
            PREADY = PREADY_1;
        end
    end else begin
        PSEL_0 = 1'b0;
        PSEL_1 = 1'b0;
        PRDATA = {DATA_WIDTH{1'b0}};
        PSLVERR = 1'b0;
        PREADY = 1'b0;
    end
end

assign slave_select = (PADDR[1:0] < 2'b10)? 1'b0 : 1'b1;
    
endmodule