module fbf_multiplier(
	input clk,
	input reset,
	input [16*32-1:0] A,
	input [16*32-1:0] B,
	output [16*32-1:0] Res
);
parameter s_INITIAL  = 2'b00;
parameter s_FIRSTSHIFT  = 2'b01;
parameter s_CLEANUP = 2'b11;
parameter FLOAT_SIZE = 32;

reg [1:0] state;    

reg [FLOAT_SIZE-1:0] A_1_1 [3:0];
reg [FLOAT_SIZE-1:0] A_1_2 [3:0];
reg [FLOAT_SIZE-1:0] A_2_1 [3:0];
reg [FLOAT_SIZE-1:0] A_2_2 [3:0];

reg [FLOAT_SIZE-1:0] B_1_1 [3:0];
reg [FLOAT_SIZE-1:0] B_1_2 [3:0];
reg [FLOAT_SIZE-1:0] B_2_1 [3:0];
reg [FLOAT_SIZE-1:0] B_2_2 [3:0];

reg [FLOAT_SIZE-1:0] Res_1_1 [3:0];
reg [FLOAT_SIZE-1:0] Res_1_2 [3:0];
reg [FLOAT_SIZE-1:0] Res_2_1 [3:0];
reg [FLOAT_SIZE-1:0] Res_2_2 [3:0];

reg [FLOAT_SIZE-1:0] mid_Res_1_1 [3:0];
reg [FLOAT_SIZE-1:0] mid_Res_1_2 [3:0];
reg [FLOAT_SIZE-1:0] mid_Res_2_1 [3:0];
reg [FLOAT_SIZE-1:0] mid_Res_2_2 [3:0];

tbt_mul_1_1 tbt_mult(
	.clk(clk),
	.reset(reset),
	.A(A_1_1),
	.B(B_1_1),
	.Res(mid_Res_1_1)
);

tbt_mul_1_2 tbt_mult(
	.clk(clk),
	.reset(reset),
	.A(A_1_2),
	.B(B_1_2),
	.Res(mid_Res_1_2)
);

tbt_mul_2_1 tbt_mult(
	.clk(clk),
	.reset(reset),
	.A(A_2_1),
	.B(B_2_1),
	.Res(mid_Res_2_1)
);

tbt_mul_2_2 tbt_mult(
	.clk(clk),
	.reset(reset),
	.A(A_2_2),
	.B(B_2_2),
	.Res(mid_Res_2_2)
);


always @(posedge clk or negedge reset)
    begin
	case(state)
	   s_INITIAL:
		A_1_1 <= {A[5:4],A[1:0]};
		A_1_2 <= {A[6:7],A[3:2]};
		A_2_1 <= {A[15:14],A[11:10]};
		A_2_2 <= {A[13:12],A[9:8]};
		
		B_1_1 <= {B[5:4],B[1:0]};
		B_1_2 <= {B[6:7],B[3:2]};
		B_2_1 <= {B[15:14],B[11:10]};
		B_2_2 <= {B[13:12],B[9:8]};
	   s_FIRSTSHIFT:
		A_1_1 <= {A[6:7],A[3:2]};
		A_1_2 <= {A[5:4],A[1:0]};
		A_2_1 <= {A[13:12],A[9:8]};
		A_2_2 <= {A[15:14],A[11:10]};
		
		B_1_1 <= {B[15:14],B[11:10]};
		B_1_2 <= {B[13:12],B[9:8]};
		B_2_1 <= {B[5:4],B[1:0]};
		B_2_2 <= {B[6:7],B[3:2]};
	   s_CLEANUP:
		
	endcase
    end


endmodule