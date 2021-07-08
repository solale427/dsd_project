`include "adder.v"
`include "single_multiplier.v"

module tbt_mult
#(
	parameter FLOATSIZE = 32, 
	parameter LENGTH = 2
)
(
	input clk,
	input reset,
	input load,
	input [2 * LENGTH * FLOATSIZE - 1:0] A,
	input [2 * LENGTH * FLOATSIZE - 1:0] B,
	output reg [2 * LENGTH * FLOATSIZE - 1:0] Res,
	output result_ready
);

parameter s_IDLE			= 3'b000;
parameter s_INITIALIZE		= 3'b001;
parameter s_MULT		   	= 3'b010;
parameter s_WAIT			= 3'b011;
parameter s_SUM			   	= 3'b100;
parameter s_CLEANUP        	= 3'b101;

//internal variables
reg [FLOATSIZE - 1:0] A_reg			[0:LENGTH - 1][0:LENGTH - 1];
reg [FLOATSIZE - 1:0] B_reg			[0:LENGTH - 1][0:LENGTH - 1];
reg [FLOATSIZE - 1:0] Res_reg 		[0:LENGTH - 1][0:LENGTH - 1];
reg [FLOATSIZE - 1:0] input_a 		[0:LENGTH - 1][0:LENGTH - 1];
reg [FLOATSIZE - 1:0] input_b 		[0:LENGTH - 1][0:LENGTH - 1];
reg [FLOATSIZE - 1:0] state	= s_INITIALIZE;

reg result_ack 		[0:LENGTH - 1][0:LENGTH - 1];
reg input_a_stb 			= 1'b0;
reg input_b_stb 			= 1'b0;	
reg output_z_ack			= 1'b0;								
reg result_ready_reg		= 1'b0;
reg initial_reset_adder 	= 1'b0;
reg initial_reset_mult		= 1'b1;
reg initial_sum_load 		= 1'b0;

wire mult_ready 	[0:LENGTH - 1][0:LENGTH - 1][0:LENGTH - 1];
wire sum_ready 		[0:LENGTH - 1][0:LENGTH - 1];
wire [FLOATSIZE - 1:0] mult_res	[0:LENGTH - 1][0:LENGTH - 1][0:LENGTH - 1];
wire [FLOATSIZE - 1:0] sum_res 	[0:LENGTH - 1][0:LENGTH - 1];

reg [4*FLOATSIZE - 1: 0] test_a_reg = 0;
reg [4*FLOATSIZE - 1: 0] test_b_reg = 0;

integer i, j, k = 0;
genvar  l, m, n;
 
generate
begin
	for(l = 0; l < LENGTH; l = l + 1)
		for(m = 0; m < LENGTH; m = m + 1)
			for(n = 0; n < LENGTH; n = n + 1)
				single_multiplier mult(
									.input_a(input_a[l][n]),
									.input_b(input_b[n][m]),
									.input_a_stb(input_a_stb),
									.input_b_stb(input_a_stb),
									.output_z_ack(output_z_ack),
									.clk(clk),
									.rst(initial_reset_mult),
									.output_z(mult_res[l][m][n]),
									.output_z_stb(mult_ready[l][m][n]),
									.input_a_ack(),
									.input_b_ack()
								);
	for(m = 0; m < LENGTH; m = m + 1)
		for(n = 0; n < LENGTH; n = n + 1)
			adder addr(
					.clk(clk),
					.reset(initial_reset_adder), 
					.load(initial_sum_load),
					.Number1(mult_res[m][n][0]), 
					.Number2(mult_res[m][n][1]),
					.result_ack(result_ack[m][n]),
					.Result(sum_res[m][n]),
					.result_ready(sum_ready[m][n])
				);
end
endgenerate


assign 	result_ready = result_ready_reg;   

always @(posedge clk or negedge reset)
begin
	if (~reset)
	begin
		state 			<= s_IDLE;
		input_a_stb 	<= 1'b0;
		input_b_stb 	<= 1'b0;
		initial_sum_load 	<= 1'b0;
		initial_reset_adder <= 1'b0;
		initial_reset_mult 	<= 1'b1;
		result_ready_reg	<= 1'b0;
		for (i = 0; i < LENGTH; i = i + 1)
			for (j = 0; j < LENGTH; j = j + 1)
			begin
				Res_reg[i][j]		<= 0;
				result_ack[i][j]	<= 0;
			end
	end
	else
	begin
		{A_reg[0][0], A_reg[0][1], A_reg[1][0], A_reg[1][1]} = A;
		{B_reg[0][0], B_reg[0][1], B_reg[1][0], B_reg[1][1]} = B;
		
		test_a_reg = {input_a[0][0], input_a[0][1],input_a[1][0],input_a[1][1]};
		test_b_reg = {input_b[0][0], input_b[0][1],input_b[1][0],input_b[1][1]};
		i = 0;
		j = 0;
		k = 0;

		//matrix multiplication
		for(i = 0; i < LENGTH; i = i + 1)
			for(j = 0; j < LENGTH; j = j + 1)
				for(k = 0; k < LENGTH; k = k + 1)
				begin
					case(state)
						s_IDLE:
						begin
							input_a_stb 	<= 1'b0;
							input_b_stb 	<= 1'b0;
							initial_sum_load 	<= 1'b0;
							initial_reset_adder <= 1'b0;
							initial_reset_mult 	<= 1'b1;
							result_ready_reg	<= 1'b0;
							Res_reg[i][j]		<= 0;
							result_ack[i][j]	<= 0;
							if (load)
								state <= s_INITIALIZE;
							else
								state <= s_IDLE;
						end
						s_INITIALIZE:
						begin
							input_a[i][k] 	<= A_reg[i][k];
							input_b[k][j] 	<= B_reg[k][j];
							if (i == 1 && j == 1 && k == 1) 
							begin
								initial_reset_mult 	<= 1'b0;
								state <= s_MULT;
							end
							else
								state <= s_INITIALIZE;
						end
						s_MULT:
						begin
							input_a_stb <= 1'b1;
							input_b_stb <= 1'b1;
							state 		<= s_WAIT;
						end
						s_WAIT:
						begin
							if (mult_ready[i][j][0] && mult_ready[i][j][1])
							begin
								if (i == 1 && j == 1 && k == 1)
								begin
									initial_reset_adder <= 1'b1;
									state 	<= s_SUM;
								end
								else
									state <= s_WAIT;
							end
						end
						s_SUM:
						begin
							output_z_ack 		<= 1'b1;
							initial_sum_load 	<= 1'b1;
							if (sum_ready[i][j])
							begin
								Res_reg[i][j] 	<= sum_res[i][j];
								if (i == 1 && j == 1 && k == 1)
								begin
									state <= s_CLEANUP;
								end
								else
									state <= s_SUM;
							end
							else
								state <= s_SUM;
						end
						s_CLEANUP:
						begin
							result_ack[i][j] <= 1'b0;
							if (i == 1 && j == 1 && k == 1)
							begin
								Res = {Res_reg[0][0], Res_reg[0][1], Res_reg[1][0], Res_reg[1][1]};
								input_a_stb 		<= 1'b0;
								input_b_stb 		<= 1'b0;
								initial_sum_load 	<= 1'b0;
								initial_reset_adder <= 1'b1;
								initial_reset_mult 	<= 1'b0;
								result_ready_reg 	<= 1'b1;
								state 				<= s_IDLE;
							end
						end
					endcase
				end
	end
end

endmodule