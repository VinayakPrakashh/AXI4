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

    localparam M_IDLE    = 3'd0,
               M_W_ADDR  = 3'd1,
               M_W_RESP  = 3'd2,
               M_R_ADDR  = 3'd3,
               M_R_DATA  = 3'd4,
               M_R_LATCH_DATA = 3'd5;

    reg [2:0] state, next_state;

    always @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn)
            state <= M_IDLE;
        else
            state <= next_state;
    end


always @(*) begin
case(state)
    M_IDLE: begin
        if(start && write) begin
            next_state = M_W_ADDR;
        end
        else if(start && !write) begin
            next_state = M_R_ADDR;
        end
        else begin
            next_state = M_IDLE;
        end
    end
    M_W_ADDR: begin
        if(AWREADY && WREADY) begin
            next_state = M_W_RESP;
        end
        else begin
            next_state =M_W_ADDR;
        end
    end
    M_W_RESP: begin
        if(BVALID) begin
            next_state = M_IDLE;
        end
        else begin
            next_state = M_W_RESP;
        end
    end
    M_R_ADDR: begin
        if(ARREADY) begin
            next_state = M_R_DATA;
        end
        else begin
            next_state = M_R_ADDR;
        end
    end
    M_R_DATA: begin
        if(RVALID) begin
            next_state = M_R_LATCH_DATA;
        end
        else begin
            next_state = M_R_DATA;
        end
        end
    M_R_LATCH_DATA: begin
            next_state = M_IDLE;
    end

    default: begin
        next_state = M_IDLE;
    end
    
endcase
    end

always @(posedge ACLK) begin
    case(state)
        M_IDLE: begin
            busy <= 1'b0;
            done <= 1'b0;
            AWVALID <= 1'b0;
            WVALID <= 1'b0;
            BREADY <= 1'b0;
            ARVALID <= 1'b0;
            RREADY <= 1'b0;
            if(start && write) begin
                busy <= 1'b1;
                // Prepare write address and data
                AWADDR <= addr;
                WDATA <= wdata;
                WSTRB <= wstrb;
                AWVALID <= 1'b1;
                WVALID <= 1'b1;
            end
            else if(start && !write) begin
                busy <= 1'b1;
                // Prepare read address
                ARADDR <= addr;
                ARVALID <= 1'b1;
            end
        end
        M_W_ADDR: begin
            busy <= 1'b1;
            done <= 1'b0;
            if(AWREADY && WREADY) begin
                AWVALID <= 1'b0;
                WVALID <= 1'b0;

            end
        end
        M_W_RESP: begin
            busy <= 1'b1;
            done <= 1'b0;
            BREADY <= 1'b1;
            if(BVALID) begin
                resp <= BRESP;

                done <= 1'b1;
                busy <= 1'b0;
            end
        end
        M_R_ADDR: begin
            busy <= 1'b1;
            done <= 1'b0;
            BREADY <= 1'b0;
            if(ARREADY) begin
                ARVALID <= 1'b0;
                RREADY <= 1'b1; // Ready to accept read data
            end
        end
        M_R_DATA: begin
            busy <= 1'b1;
            done <= 1'b0;
            end
        M_R_LATCH_DATA: begin
                rdata <= RDATA;
                resp <= RRESP;
                RREADY <= 1'b0;
                done <= 1'b1;
                busy <= 1'b0;
        end
        default: begin
            busy <= 1'b0;
            done <= 1'b0;
            AWVALID <= 1'b0;
            WVALID <= 1'b0;
            BREADY <= 1'b0;
            ARVALID <= 1'b0;
            RREADY <= 1'b0;
        end
    endcase
end
endmodule
