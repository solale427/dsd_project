`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2021 04:59:09 PM
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


`include "adder.v"
//module tf_adder #(parameter WIDTH = 2) (input wire reset, input wire clk, output reg ready, input wire acknowledge,output reg[31:0] result[WIDTH *WIDTH - 1:0],
// input wire [31:0] A[WIDTH*WIDTH - 1:0], input wire [31:0] B[WIDTH*WIDTH : 0]);
////module tf_adder #(parameter WIDTH = 2) (input wire reset, input wire clk, output reg ready, input wire acknowledge,output reg[32 * WIDTH * WIDTH - 1 : 0] result,
//// input wire [32 * WIDTH * WIDTH - 1 : 0] A, input wire [32 * WIDTH * WIDTH - 1 : 0] B);
//reg load;
////reg [31:0] a[WIDTH - 1 : 0][WIDTH - 1 : 0];
////reg [31:0] b[WIDTH - 1 : 0][WIDTH - 1 : 0];
////wire [31:0] res[WIDTH - 1 : 0][WIDTH - 1 : 0];
//wire [WIDTH*WIDTH-1:0] ready_add;
//reg ack_add = 1;
//genvar i;
//genvar j;
//integer m;
//integer n;
//generate
//for(i = 0; i < WIDTH * WIDTH; i = i + 1) begin
//    adder adder_tf(.clk(clk), .reset(reset), .load(load), .Number1(A[i]), .Number2(B[i]), .result_ack(ack_add), .Result(result[i]), .result_ready(ready_add[i]));
//    end
//endgenerate

//always @(posedge clk or negedge reset)
//begin
//if(~reset)
//begin
//    ready <= 0;
//    load <= 0;
//end
//else begin
//load <= 1;
////result = {res[0][0], res[0][1], res[1][0], res[1][1]};
////for(m = 0; m < WIDTH; m = m + 1) begin
////    for(n = 0; n < WIDTH; n = n + 1) begin 
////        a[m][n] = A[m][n];
////        b[m][n] = B[m][n]; 
//        //result = {res[m][n], result};
//    //end
////end
//if (&ready_add)
//ready <= 1;
//end
//end
//endmodule

module tf_adder #(parameter WIDTH = 2) (input wire clk, output wire ready, input wire load,output reg[31:0] result[WIDTH*WIDTH-1:0],
input wire [31:0] A[WIDTH*WIDTH-1:0], input wire [31:0] B[WIDTH*WIDTH-1:0]);


wire [WIDTH*WIDTH-1:0] ready_add ;
genvar i;
genvar j;


generate
for(i = 0; i < WIDTH; i = i + 1) begin
    for(j = 0; j < WIDTH; j = j + 1)begin
    adder adder_tf(.clk(clk), .reset(1'b1), .load(load), .Number1(A[i*WIDTH+j]), .Number2(B[i*WIDTH+j]), .result_ack(1'b1), .Result(result[i*WIDTH+j]), .result_ready(ready_add[i*WIDTH+j]));
    end
    end
endgenerate

assign ready = (&ready_add);

endmodule