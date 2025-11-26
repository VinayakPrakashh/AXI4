module APB_slave1 #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input PCLK,
    input PRESETn,
    // APB Slave Interface
    input PSEL,
    input PENABLE,
    input PWRITE,
    input [ADDR_WIDTH-1:0] PADDR,
    input [DATA_WIDTH-1:0] PWDATA,
    output reg [DATA_WIDTH-1:0] PRDATA,
    output reg PREADY,
    output reg PSLVERR,
    // UART Interface
    input RX,
    output TX
);

    // Internal signals
    wire tx_busy, tx_done;
    wire rx_busy, rx_done;
    wire rx_error;
    wire parity_error;
    wire framing_error;
    wire [7:0] rx_data;
    // Memory-mapped registers
    reg [7:0] tx_data_reg;      // mem[0]
    reg [7:0] rx_data_reg;      // mem[1]
    reg [7:0] status_reg;       // mem[2]
    reg [7:0] control_reg;      // mem[3]
// memory organization
//mem[0] - TX Data Register [7:0]
//mem[1] - RX Data Register [7:0]
//mem[2] - Status Register [0]=TX Busy, [1]=TX Done, [2]=RX Busy, [3]=RX Done [4]= Parity Error, [5]= Framing Error [6]= RX Error
//mem[3] - Control Register [0]= TX Enable, [1]= RX Enable [2]= TX Start
    uart_tx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(9600)
    ) uart_tx_inst (
        .clk(PCLK),
        .resetn(PRESETn),
        .tx_enable(control_reg[0]),
        .tx_data(tx_data_reg),
        .tx_start(control_reg[2]),
        .tx(TX),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(9600)
    ) uart_rx_inst (
        .clk(PCLK),
        .resetn(PRESETn),
        .rx_enable(control_reg[1]),
        .rx(RX),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_error(rx_error),
        .rx_busy(rx_busy),
        .parity_error(parity_error),
        .framing_error(framing_error)
    );

always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_data_reg <= 8'd0;
            rx_data_reg <= 8'd0;
            status_reg  <= 8'd0;
            control_reg <= 8'd0;
            PRDATA      <= 32'd0;
        end 
        else begin

            //-----------------------------------------
            // 1. Live Status Flags
            //-----------------------------------------
            status_reg[0] <= tx_busy;   // TX Busy
            status_reg[2] <= rx_busy;   // RX Busy

            //-----------------------------------------
            // 2. Sticky Status Flags (set by hardware)
            //-----------------------------------------
            if (tx_done) status_reg[1] <= 1'b1; // TX Done
            if (tx_busy) begin
            control_reg[2] <= 1'b0;  // Clear TX Start when transmission starts
        end
            
            if (rx_done) begin
                status_reg[3] <= 1'b1; // RX Done
                rx_data_reg   <= rx_data;
            end
            if (parity_error)   status_reg[4] <= 1'b1; // Parity error
            if (framing_error)  status_reg[5] <= 1'b1; // Framing error
            if (rx_error)       status_reg[6] <= 1'b1; // RX error

            //-----------------------------------------
            // 3. APB Write Operations
            //-----------------------------------------
            if (PSEL && PENABLE && PWRITE) begin
                case (PADDR[3:2])
                    2'd0: tx_data_reg <= PWDATA[7:0]; // TXDATA (0x00)
                    2'd1: status_reg  <= status_reg & ~PWDATA[7:0]; // STATUS W1C (0x04)
                    2'd2: control_reg <= PWDATA[7:0]; // CONTROL (0x08)
                    default: ;
                endcase
            end

            //-----------------------------------------
            // 4. APB Read Operations
            //-----------------------------------------
            if (PSEL && PENABLE && !PWRITE) begin
                case (PADDR[3:2])
                    2'd0: PRDATA <= {24'd0, tx_data_reg}; // TXDATA (0x00)
                    2'd1: PRDATA <= {24'd0, rx_data_reg}; // RXDATA (0x04)
                    2'd2: PRDATA <= {24'd0, control_reg}; // CONTROL (0x08)
                    2'd3: PRDATA <= {24'd0, status_reg};  // STATUS (0x0C)

                    
                    default: PRDATA <= 32'd0;
                endcase
            end
        end
    end
always @(*) begin
    PREADY <= 1'b1;

    if (PSEL && PENABLE && PREADY) begin
        if (PADDR > 32'h1000_0003) begin
            PSLVERR = 1'b1;  // Invalid address
        end
        else begin
            PSLVERR = 1'b0;  // No error
        end
    end else begin
        PSLVERR = 1'b0;  // Default: no error
    end
end
endmodule
