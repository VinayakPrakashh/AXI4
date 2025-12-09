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
    output                   busy,       // 1 while ongoing
    output                   done,       // pulse when finished
    output  [DATA_WIDTH-1:0] rdata,      // valid when done & read
    output  [1:0]            resp        // BRESP/RRESP
    

);

wire [ADDR_WIDTH-1:0] AWADDR;
    wire                  AWVALID;
    wire [DATA_WIDTH-1:0] WDATA;
    wire                  WVALID;
    wire [3:0]            WSTRB_int;
    wire [1:0]            BRESP;
    wire                  BVALID;

    wire [ADDR_WIDTH-1:0] ARADDR;
    wire                  ARVALID;
    wire [DATA_WIDTH-1:0] RDATA;
    wire                  RVALID;
    wire [1:0]            RRESP;

    wire                  AWREADY;
    wire                  WREADY;
    wire                  BREADY;
    wire                  ARREADY;
    wire                  RREADY;

    wire                  error;

    
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
        .WSTRB(WSTRB_int),
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
        .WSTRB(WSTRB_int),
        // WRITE RESPONSE
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        // Error signal
        .error(error)
    );
  

endmodule
