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

    // Internal APB Master to MUX signals
    wire psel_uart, psel_timer;
    wire penable_master;
    wire pwrite_master;
    wire [ADDR_WIDTH-1:0] paddr_master;
    wire [DATA_WIDTH-1:0] pwdata_master;
    wire [DATA_WIDTH-1:0] prdata_to_master;
    wire pready_to_master;
    wire pslverr_to_master;
    wire [3:0] PSTRB_slave;

    
    // MUX to Slaves signals
    wire psel_slave0, psel_slave1;
    wire [DATA_WIDTH-1:0] prdata_slave0, prdata_slave1;
    wire pready_slave0, pready_slave1;
    wire pslverr_slave0, pslverr_slave1;
    wire [ADDR_WIDTH-1:0] apb_waddr;
    wire [ADDR_WIDTH-1:0] apb_raddr;
    wire [DATA_WIDTH-1:0] apb_wdata;
    wire [DATA_WIDTH-1:0] apb_rdata;
    wire transfer, read, write, apb_done;
    // DUT instantiation
    //axi4-lite
    AXI4_lite #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axi4_lite_inst (
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
        .error(error),
        //for APB TOP module
        .transfer(transfer),
        .read(read),
        .write(write),

        .PSTRB(PSTRB_slave[1:0]), // Assuming full byte write for simplicity
        .apb_waddr(apb_waddr),
        .apb_raddr(apb_raddr),
        .apb_wdata(apb_wdata),
        .apb_rdata(prdata_to_master),
        .err_flag(pslverr_to_master),
        .apb_done(apb_done)
    );
    
    // APB Master Instance
    APB_MASTER #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_master_inst (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        // APB Master Interface (to MUX)
        .PSEL_UART(psel_uart),
        .PSEL_TIMER(psel_timer),
        .PENABLE(penable_master),
        .PWRITE(pwrite_master),
        .PADDR(paddr_master),
        .PWDATA(pwdata_master),
        .PSTRB(PSTRB_slave), // Not connected here
        .PRDATA(prdata_to_master),
        .PREADY(pready_to_master),
        .PSLVERR(pslverr_to_master),
        // Control signals
        .transfer(transfer),
        .read(read),
        .write(write),
        .WSTRB(WSTRB), // Assuming full byte write for simplicity
        // AXI4 simulation inputs
        .apb_waddr(apb_waddr),
        .apb_raddr(apb_raddr),
        .apb_wdata(apb_wdata),
        .apb_rdata(apb_rdata),
        .apb_done(apb_done)
    );
    
    // APB MUX Instance
    APB_MUX #(
        .ADDR_WIDTH(MUX_ADDR_WIDTH),
        .OP_ADDR_WIDTH(OP_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_mux_inst (
        .PSEL_UART(psel_uart),
        .PSEL_TIMER(psel_timer),
        .PADDR(paddr_master[MUX_ADDR_WIDTH-1:0]), // Use lower bits for MUX addressing
        .PREADY_0(pready_slave0),
        .PREADY_1(pready_slave1),
        .PRDATA_0(prdata_slave0),
        .PRDATA_1(prdata_slave1),
        .PSLVERR_0(pslverr_slave0),
        .PSLVERR_1(pslverr_slave1),
        .PSEL_0(psel_slave0),
        .PSEL_1(psel_slave1),
        .PSLVERR(pslverr_to_master),
        .PRDATA(prdata_to_master),
        .PREADY(pready_to_master)
    );
    
    // APB Slave 0 Instance
    APB_slave1 #(
        .ADDR_WIDTH(MUX_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_slave0_inst (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(psel_slave0),
        .PENABLE(penable_master),
        .PWRITE(pwrite_master),
        .PSTRB(PSTRB_slave),
        .PADDR(paddr_master[MUX_ADDR_WIDTH-1:0]),
        .PWDATA(pwdata_master),
        .PRDATA(prdata_slave0),
        .PREADY(pready_slave0),
        .PSLVERR(pslverr_slave0)
    );
    
    // APB Slave 1 Instance  
    APB_slave1 #(
        .ADDR_WIDTH(MUX_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_slave1_inst (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(psel_slave1),
        .PENABLE(penable_master),
        .PWRITE(pwrite_master),
        .PSTRB(PSTRB_slave),
        .PADDR(paddr_master[MUX_ADDR_WIDTH-1:0]),
        .PWDATA(pwdata_master),
        .PRDATA(prdata_slave1),
        .PREADY(pready_slave1),
        .PSLVERR(pslverr_slave1)
    );

endmodule
