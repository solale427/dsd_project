`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2021 05:34:24 PM
// Design Name: 
// Module Name: tf_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tf_adder (input A_stb, input B_stb, input wire clk, input wire reset, output reg ready, input wire res_ack,
 input wire[32 * 2 * 2 -1:0] A, input wire [32 * 2 * 2 -1:0] B, output reg [32 * 2 * 2 -1: 0] result);
 
 localparam S_IDLE = 0;
 localparam S_SET_ADDER_INPUT = 1;
 localparam S_WAIT = 2;
 localparam S_WRITE_RESULT = 3;
 localparam S_SET_RESULT = 4;
 reg [2:0] state;
 reg adder_load;
 reg [31:0] input_adder_a;
 reg [31:0] input_adder_b;
 reg [31:0] output_adder_res;
 wire output_adder_ready;
 reg input_adder_ack;
 
 reg [31:0] A_reg[1:0][1:0];
 reg [31:0] B_reg[1:0][1:0];
 reg [31:0] Res_reg[1:0][1:0];
 
 integer i;
 integer j;
 adder adder(.reset(reset), .clk(clk), .load(adder_load), .Number1(input_adder_a), .Number2(input_adder_b), .result_ready(output_adder_ready), .result_ack(input_adder_ack), .Result(output_adder_res));
 always @(posedge clk or negedge reset) begin
 case (state)
        S_IDLE: begin
                if( A_stb && B_stb)
                    begin
                    i <= 0;
                    j <= 0;
                    state <= S_SET_ADDER_INPUT;
                    set_A_B();
                    end
                  else state <= S_IDLE;
                  end
        S_SET_ADDER_INPUT: begin
                    input_adder_a <= A_reg[i][j];
                    input_adder_b <= B_reg[i][j];
                    adder_load <= 1;
                    state <= S_WAIT;
                    end
       S_WAIT: begin
                if(output_adder_ready) begin
                state <= S_WRITE_RESULT;
                end
                else state <= S_WAIT;
       end
       S_WRITE_RESULT:begin
                Res_reg[i][j] <= output_adder_res;
                input_adder_ack <= 1;
                if( i == 1 && j == 1)
                  state <= S_SET_RESULT;
                 else begin
                 j <= j + 1;
                 if(j > 1) begin
                    j <= 0;
                    i <= i + 1;
                 end
                 state <= S_SET_ADDER_INPUT;  
                end
                end
       S_SET_RESULT:begin
                result = {Res_reg[0][0], Res_reg[0][1], Res_reg[1][0], Res_reg[1][1]};
                ready <= 1;
                if(res_ack)
                state <= S_IDLE;
                else
                state <= S_SET_RESULT;
                end   
 endcase
 end
 task automatic set_A_B();
 begin
 integer m;
 integer n;
 for(m = 0; m < 2 ; m = m + 1) begin
 for(n = 0; n < 2 ; n = n + 1) begin
    A_reg[m][n] = A[ ((m*2 + n) * 32)+: 32];
    B_reg[m][n] = B[ ((m*2 + n) * 32)+: 32];
 end
 end
 end
 endtask
endmodule
