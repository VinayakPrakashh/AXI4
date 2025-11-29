module AXI4_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32

) (
    input ACLK,
    input ARESETn,
    //AXI READ
    input [ADDR_WIDTH-1:0] ARADDR,
    input ARVALID,
    output reg ARREADY,
    output [DATA_WIDTH-1:0] RDATA,
    output reg RVALID,
    input RREADY,
    output [1:0] RRESP,
    //AXI WRITE
    input [ADDR_WIDTH-1:0] AWADDR,
    input AWVALID,
    output AWREADY,
    input [DATA_WIDTH-1:0] WDATA,
    input WVALID,
    output reg WREADY,
    input [3:0] WSTRB,
    // WRITE RESPONSE
    output [1:0] BRESP,
    output reg BVALID,
    input BREADY,
    // Error signal
    output error,
    //for APB TOP module
    output reg transfer,
    output reg read,
    output reg write,

    output reg [3:0] PSTRB,
    output reg [ADDR_WIDTH-1:0] apb_waddr,
    output reg [ADDR_WIDTH-1:0] apb_raddr,
    output reg [DATA_WIDTH-1:0] apb_wdata,
    input apb_done

);

parameter S_IDLE = 4'b0001,
          S_READ = 4'b0010,
          S_WRITE = 4'b0100,
          S_RESP = 4'b1000;

reg [3:0] state, next_state;
reg [ADDR_WIDTH-1:0] latched_araddr;
reg  [ADDR_WIDTH-1:0] latched_awaddr;
reg  [DATA_WIDTH-1:0] latched_wdata;
reg  [3:0] latched_wstrb;
always @(posedge ACLK) begin
    if (!ARESETn)
        state <= S_IDLE;
    else
        state <= next_state; 
end

always @(*) begin
    case (state)
    S_IDLE: begin
        if (AWVALID & WVALID) // Write transaction
            next_state = S_W_REQ;
        else if (ARVALID) // Read transaction
            next_state = S_R_REQ;
        else
            next_state = S_IDLE;
    end
endcase
end

always @(*) begin
 case (state)
    S_IDLE: begin
        BVALID = 1'b0;
        RVALID = 1'b0;

        AWREADY = 1'b0;
        ARREADY = 1'b0;

        transfer = 1'b0;
        read = 1'b0;
        write = 1'b0;
        if(AWVALID & WVALID) begin
            AWREADY = 1'b1;
            WREADY = 1'b1;

            //latch for APB
            latched_awaddr = AWADDR;
            latched_wdata = WDATA;
            latched_wstrb = WSTRB;

            //immediate APB signals
            apb_waddr = AWADDR;
            apb_wdata = WDATA;
            PSTRB = WSTRB;

            //trigger transfer
            transfer = 1'b1;

        end
        else if (ARVALID) begin
            ARREADY = 1'b1;

            //latch for APB
            latched_araddr = ARADDR;

            //immediate APB signals
            apb_raddr = ARADDR;

            //trigger transfer
            transfer = 1'b1;
            read = 1'b1;
        end 
    end 
    S_W_REQ:begin
         // No new AXI handshakes while we’re starting APB
        ARREADY_r  <= 1'b0;
        AWREADY_r  <= 1'b0;
        WREADY_r   <= 1'b0;

        // No AXI responses yet
        RVALID   <= 1'b0;
        BVALID  <= 1'b0;

        // Fire APB write (one-cycle pulse of transfer_i + write_i)
        transfer <= 1'b1;
        write    <= 1'b1;
        read    <= 1'b0;

        // Drive APB address/data from the latched AXI values
        apb_waddr <= awaddr_reg;
        apb_wdata <= wdata_reg;
        PSTRB     <= wstrb_reg;
    end
 endcase
end
endmodule