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

    localparam S_IDLE    = 3'd0,
               S_W_ADDR  = 3'd1,
               S_W_RESP  = 3'd2,
               S_R_ADDR  = 3'd3,
               S_R_DATA  = 3'd4;

    reg [2:0] state, next_state;

    always @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case(state)
            S_IDLE:    if(start)                        next_state = write ? S_W_ADDR : S_R_ADDR;
            S_W_ADDR:  if((AWVALID && AWREADY) &&
                          (WVALID  && WREADY))          next_state = S_W_RESP;
            S_W_RESP:  if(BVALID && BREADY)             next_state = S_IDLE;
            S_R_ADDR:  if(ARVALID && ARREADY)           next_state = S_R_DATA;
            S_R_DATA:  if(RVALID && RREADY)             next_state = S_IDLE;
        endcase
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn) begin
            AWADDR <= 0; AWVALID <= 0;
            WDATA  <= 0; WVALID  <= 0; WSTRB <= 4'b0000;
            BREADY <= 0;
            ARADDR <= 0; ARVALID <= 0;
            RREADY <= 0;

            busy <= 0;
            done <= 0;
            rdata <= 0;
            resp <= 0;
        end else begin
            // defaults
            done <= 0;
            BREADY <= 0;
            RREADY <= 0;

            case(state)
                S_IDLE: begin
                    busy <= 0;
                    AWVALID <= 0;
                    WVALID <= 0;
                    ARVALID <= 0;

                    if(start) begin
                        busy <= 1;
                        if(write) begin
                            AWADDR <= addr;
                            WDATA <= wdata;
                            WSTRB <= wstrb;
                            AWVALID <= 1;
                            WVALID <= 1;
                        end else begin
                            ARADDR <= addr;
                            ARVALID <= 1;
                        end
                    end
                end

                S_W_ADDR: begin
                    busy <= 1;
                    if(AWREADY) AWVALID <= 0;
                    if(WREADY)  WVALID <= 0;
                end

                S_W_RESP: begin
                    busy <= 1;
                    BREADY <= 1;
                    if(BVALID) begin
                        resp <= BRESP;
                        done <= 1;
                    end
                end

                S_R_ADDR: begin
                    busy <= 1;
                    if(ARREADY) ARVALID <= 0;
                end

                S_R_DATA: begin
                    busy <= 1;
                    RREADY <= 1;
                    if(RVALID) begin
                        rdata <= RDATA;
                        resp <= RRESP;
                        done <= 1;
                    end
                end
            endcase
        end
    end

endmodule
