`timescale 1ns / 1ps

module Smartlock(
    input clk,
    input rst,
    // 4-bit keypad input
    inout [7:0] JA,   
    output [6:0] segout,
    output [3:0] an,
    output reg unlock,
    output reg led,
    output reg [3:0] count,
    output [3:0]key_out
);
reg [3:0] pkey_value;
    wire [3:0]key_in;
    assign key_out=key_in;
     
    // Keypad module instance
    keypadpmod kp(
        .clk(clk),
        .row(JA[7:4]),
        .col(JA[3:0]),
        .decodeout(key_in)
    );

    // 7-segment display controller instance
    DisplayController dc (
        .displayval(key_in),
        .anode(an),
        .segOut(segout)
    );
    
    
    reg [15:0] entered_password=0;

    parameter [15:0] STORED_PASSWORD = 16'h1234; // Hardcoded correct password

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            entered_password <= 16'h0000;
            count <= 4'b0000;
            unlock <= 0;
            led <= 0;
            pkey_value<=0;
        end 
        else begin 
            
             // Ensure a valid key is pressed
                if (pkey_value!=key_in) begin
                    entered_password <= {entered_password[11:0], key_in};
                     pkey_value<=key_in;
                    count <= count + 1;
                end 
                else if (count == 4) begin
                    led <= 1; // Indicate entry completion
                    if (entered_password == STORED_PASSWORD) begin
                        unlock <= 1;
                        unlock_count <= unlock_count + 1; // Increment unlock count
                    end 
                    end
                    
                    else begin
                        unlock <= 0;
                        led <= 0;
                        entered_password <= 16'h0000; // Reset password buffer
                        count <= 0;  // Reset counter for next entry
                    end
                end
            end
        
       
   

endmodule