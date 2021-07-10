`include "tbt_multiplier_async.v"
`timescale 1ns / 1ps

module tbt_mult_async_TB();
reg clk = 0;
reg reset = 1;
reg [127:0] A;
reg [127:0] B;
wire [127:0] generated_mul;
reg [127:0] correct_mul;
wire result_ready;
wire result_ack;
reg load = 1'b1;
reg [31:0] A_reg [0:1][0:1];
reg [31:0] B_reg [0:1][0:1];
reg [31:0] Res_reg [0:1][0:1];

tbt_mult_async uut(
        .clk(clk),
        .reset(reset),
		.load(load),
        .A(A),
        .B(B),
		.result_ack(result_ack),
        .result(generated_mul),
        .result_ready(result_ready)
    );


always #10 clk = ~clk;

initial begin
	$monitor ("A = %h, B = %h, Res = %h, valid result: %h, result ready: %b", A, B, generated_mul, correct_mul, result_ready);
	//	A = | 5.84   8.16 |
	//		| -3.01  -10  |
	//
	//	B = | 20.9   -12.8|
	//		| 9.35   2    |
	//	
	//	Res = | 198.352  -58.432|
	//		  | -156.409  18.528|
	
	A_reg[0][0] = 32'b01000000101110101110000101001000;
	A_reg[0][1]	= 32'b01000001000000101000111101011100;
	A_reg[1][0]	= 32'b11000000010000001010001111010111;
	A_reg[1][1]	= 32'b11000001001000000000000000000000;
	
	B_reg[0][0]	= 32'b01000001101001110011001100110011;
	B_reg[0][1]	= 32'b11000001010011001100110011001101;
	B_reg[1][0]	= 32'b01000001000101011001100110011010;
	B_reg[1][1]	= 32'b01000000000000000000000000000000;
	
	Res_reg[0][0]	= 32'b01000011010001100101101000011101;
	Res_reg[0][1]	= 32'b11000010011010011011101001011110;
	Res_reg[1][0]	= 32'b11000011000111000110100010110100;
	Res_reg[1][1]	= 32'b01000001100101000011100101011000;
	
	A = {A_reg[0][0], A_reg[0][1], A_reg[1][0], A_reg[1][1]};
	B = {B_reg[0][0], B_reg[0][1], B_reg[1][0], B_reg[1][1]};
	
	correct_mul = {Res_reg[0][0], Res_reg[0][1], Res_reg[1][0], Res_reg[1][1]};


    end

endmodule
