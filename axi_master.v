module axi_master (
    clk,
    reset,

    //write address channel (1)
    output reg [31:0] awaddr,
    output reg awvalid,
    input awready,

    //write data channel (2)
    output reg [31:0] wdata,
    output reg wvalid,
    input wready,

    //write response channel (3)
    input [1:0] bresp,
    input bvalid,
    output reg bready,

    //read address channel (4)
    output reg [31:0] araddr,
    output reg arvalid,
    input arready,

    //read data channel (5)
    input [31:0] rdata,
    input rvalid,
    output reg rready,
);
    
parameter  IDLE= 2'b00, WRITE= 2'b01, RESP= 2'b10, READ= 2'b11;

wire handshake;

assign handshake = (awvalid & awready);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        awvalid <= 1'b0;
        wvalid <= 1'b0;
        bready <= 1'b0;
        arvalid <= 1'b0;
        rready <= 1'b0;
    end
    else begin

    end
end

endmodule