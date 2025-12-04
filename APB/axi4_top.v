module axi4_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MUX_ADDR_WIDTH = 32,
    parameter OP_ADDR_WIDTH = 2

) (
    input PCLK,
    input PRESETn,
    //--------AXI SIGNALS --------
    input ACLK,
    input ARESETn,
    // Control interface
    input                       start,      // pulse to start transaction
    input                       write,      // 1 = write, 0 = read
    input [ADDR_WIDTH-1:0]      addr,
    input [DATA_WIDTH-1:0]      wdata,
    input [3:0]                 wstrb,      // generally 4'b1111
    output reg                  busy,       // 1 while ongoing
    output reg                  done,       // pulse when finished
    output reg [DATA_WIDTH-1:0] rdata,      // valid when done & read
    output reg [1:0]            resp        // BRESP/RRESP
    

);
    
axi4lite_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) AXI4_LITE_MASTER_INST (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        // Control interface
        .start(start),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .busy(busy),
        .done(done),
        .rdata(rdata),
        .resp(resp),
        // AXI4-Lite Interface
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .WSTRB(WSTRB),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .RRESP(RRESP)
    );
    APB_TOP #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MUX_ADDR_WIDTH(MUX_ADDR_WIDTH),
        .OP_ADDR_WIDTH(OP_ADDR_WIDTH)
    ) APB_TOP_INST (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        //--------AXI SIGNALS --------
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        //AXI READ
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .RRESP(RRESP),
        //AXI WRITE
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .WSTRB(WSTRB),
        // WRITE RESPONSE
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        // Error signal
        .error(error)
    );
  

endmodule
module axi4lite_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                       ACLK,
    input                       ARESETn,

    // Control interface
    input                       start,      // pulse to start transaction
    input                       write,      // 1 = write, 0 = read
    input [ADDR_WIDTH-1:0]      addr,
    input [DATA_WIDTH-1:0]      wdata,
    input [3:0]                 wstrb,      // generally 4'b1111

    output reg                  busy,       // 1 while ongoing
    output reg                  done,       // pulse when finished
    output reg [DATA_WIDTH-1:0] rdata,      // valid when done & read
    output reg [1:0]            resp,       // BRESP/RRESP

    // AXI4-Lite Interface
    output reg [ADDR_WIDTH-1:0] AWADDR,
    output reg                  AWVALID,
    input                       AWREADY,

    output reg [DATA_WIDTH-1:0] WDATA,
    output reg                  WVALID,
    input                       WREADY,
    output reg [3:0]            WSTRB,

    input  [1:0]                BRESP,
    input                       BVALID,
    output reg                  BREADY,

    output reg [ADDR_WIDTH-1:0] ARADDR,
    output reg                  ARVALID,
    input                       ARREADY,

    input  [DATA_WIDTH-1:0]     RDATA,
    input                       RVALID,
    output reg                  RREADY,
    input  [1:0]                RRESP
);

module APB_TOP #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MUX_ADDR_WIDTH = 32,
    parameter OP_ADDR_WIDTH = 2
) (
    input PCLK,
    input PRESETn,
    //--------AXI SIGNALS --------
    input ACLK,
    input ARESETn,
    //AXI READ
    input [ADDR_WIDTH-1:0] ARADDR,
    input ARVALID,
    output ARREADY,
    output [DATA_WIDTH-1:0] RDATA,
    output RVALID,
    input RREADY,
    output [1:0] RRESP,
    //AXI WRITE
    input [ADDR_WIDTH-1:0] AWADDR,
    input AWVALID,
    output AWREADY,
    input [DATA_WIDTH-1:0] WDATA,
    input WVALID,
    output WREADY,
    input [3:0] WSTRB,
    // WRITE RESPONSE
    output [1:0] BRESP,
    output BVALID,
    input BREADY,
    // Error signal
    output error
);
