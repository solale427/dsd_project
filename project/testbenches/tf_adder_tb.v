`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2021 05:12:21 PM
// Design Name: 
// Module Name: tf_adder_tb
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


//module tf_adder_tb();
//parameter WIDTH = 1;

//reg reset;
//reg clk;
//wire ready;
//reg acknowledge;
//reg load = 1;
////wire read;
////wire [31:0] rs;
////reg [31:0] a_1;
////reg [31:0] b_1;
////wire [31:0] result[WIDTH - 1:0][WIDTH - 1:0];
////reg [31:0] A_reg[WIDTH - 1:0][WIDTH - 1:0];
////reg [31:0] B_reg[WIDTH - 1:0][WIDTH - 1:0];
////reg [31:0] result_array[WIDTH - 1:0][WIDTH - 1:0];
//reg [31:0] A_reg[WIDTH * WIDTH -1 : 0];
//reg [31:0] B_reg[WIDTH * WIDTH - 1 : 0];
//wire [31:0] correct_result[WIDTH * WIDTH - 1 : 0];
//integer i;
//integer j;

////adder addr(.clk(clk), .reset(reset), .load(load), .Number1(a_1), .Number2(b_1), .result_ack(acknowledge), .Result(rs), .result_ready(read));
//initial
//   begin
//      clk = 1;
//      repeat(200) #10 clk = ~clk;
//   end

//initial begin
//reset = 0;
//#2;
//reset = 1;
////a_1 = $random();
////b_1 = $random();
////	reset = 0; #2
////	reset = 1;
//    A_reg[0] = 32'b01000000101110101110000101001000;
////    A_reg[1] = 32'b01000000101110101110000101001000; 
////    A_reg[2] = 32'b01000000101110101110000101001000;
////    A_reg[3] = 32'b01000000101110101110000101001000;
    
//    B_reg[0] = 32'b01000000101110101110000101001000;
////    B_reg[1] = 32'b01000000101110101110000101001000; 
////    B_reg[2] = 32'b01000000101110101110000101001000;
////    B_reg[3] = 32'b01000000101110101110000101001000;	
//end

//tf_adder #(WIDTH == 1) tfAdder(.clk(clk), .load(load), .ready(ready),.result(correct_result),.A(A_reg), .B(B_reg));

// endmodule
module tf_adder_tb();
parameter WIDTH = 2;

reg clk;
wire ready;
reg load;
reg [31:0] A_reg[WIDTH * WIDTH -1 : 0];
reg [31:0] B_reg[WIDTH * WIDTH - 1 : 0];
wire [31:0] correct_result[WIDTH * WIDTH - 1 : 0];
integer i;
integer j;

//adder addr(.clk(clk), .reset(reset), .load(load), .Number1(a_1), .Number2(b_1), .result_ack(acknowledge), .Result(rs), .result_ready(read));
tf_adder tfAdder( .clk(clk),.load(load), .ready(ready),.result(correct_result),.A(A_reg), .B(B_reg));

initial
   begin
      clk = 1;
      repeat(1000) #10 clk = ~clk;
   end

initial begin
$monitor("%b",ready);
    A_reg[0] = 32'b01000000101110101110000101001000;
    A_reg[1] = 32'b01000000101110101110000101001000; 
    A_reg[2] = 32'b01000000101110101110000101001000;
    A_reg[3] = 32'b01000000101110101110000101001000;
    
    B_reg[0] = 32'b01000000101110101110000101001000;
    B_reg[1] = 32'b01000000101110101110000101001000; 
    B_reg[2] = 32'b01000000101110101110000101001000;
    B_reg[3] = 32'b01000000101110101110000101001000;	
load <= 1;

end
 endmodule
