
module tbt_mult_async
# (
	parameter FLOATSIZE = 32
)
(
	input clk,
	input reset,
	input load,
	input [2 * 2 * FLOATSIZE - 1:0] A,
	input [2 * 2 * FLOATSIZE - 1:0] B,
	input result_ack,
	output reg [2 * 2 * FLOATSIZE - 1:0] result,
	output result_ready
);

localparam s_IDLE = 0;
localparam s_INITIALIZE = 1;
localparam s_MULT = 2;
localparam s_WAIT = 3;
localparam s_SUM = 4;
localparam s_SET_RESULT = 5;
localparam s_GET_RESULT = 6;

//internal variables
reg [FLOATSIZE - 1:0] A_reg	[1:0][1:0];
reg [FLOATSIZE - 1:0] B_reg	[1:0][1:0];
reg [FLOATSIZE - 1:0] res_reg [1:0][1:0];
reg [FLOATSIZE - 1:0] input_adder_a;
reg [FLOATSIZE - 1:0] input_mult_a [0:1];
reg [FLOATSIZE - 1:0] input_mult_b [0:1];
reg [FLOATSIZE - 1:0] state	= s_IDLE;
reg result_ready_reg = 0;
reg input_mult_a_stb [0:1];
reg input_mult_b_stb [0:1];
reg input_mult_reset = 1;
reg input_adder_load = 0;
reg input_adder_reset = 0;
reg input_adder_result_ack = 0;

wire [FLOATSIZE - 1:0] output_adder_result;
wire [FLOATSIZE - 1:0] output_mult_result [0:1];
wire output_adder_ready;
wire output_mult_ready [0:1];

integer i;
integer j;
integer k;

genvar m, n;


generate
begin
	for (n = 0; n < 2; n = n + 1)
		single_multiplier mult(
			.input_a(input_mult_a[n]),
			.input_b(input_mult_b[n]),
			.input_a_stb(input_mult_a_stb[n]),
			.input_b_stb(input_mult_b_stb[n]),
			.output_z_ack(),
			.clk(clk),
			.rst(input_mult_reset),
			.output_z(output_mult_result[n]),
			.output_z_stb(output_mult_ready[n]),
			.input_a_ack(),
			.input_b_ack()
		);
end
endgenerate

adder single_adder(
		.clk(clk),
		.reset(input_adder_reset), 
		.load(input_adder_load),
		.Number1(output_mult_result[0]), 
		.Number2(output_mult_result[1]),
		.result_ack(input_adder_result_ack),
		.Result(output_adder_result),
		.result_ready(output_adder_ready)
);

assign result_ready = result_ready_reg;

always @(posedge clk or negedge reset)
begin
	if (~reset)
	begin
		state <= s_IDLE;
		input_adder_load <= 1'b0;
		input_adder_reset <= 1'b0;
		input_mult_reset <= 1'b1;
		result_ready_reg <= 1'b0;
		input_mult_a_stb[0] <= 1'b0;
		input_mult_a_stb[0] <= 1'b0;
		input_mult_b_stb[1] <= 1'b0;
		input_mult_b_stb[1] <= 1'b0;
	end
	else
	begin
		case(state)
			s_IDLE:
			begin
				input_adder_load <= 1'b0;
				input_adder_reset <= 1'b0;
				input_mult_reset <= 1'b1;
				i <= 0;
				j <= 0;
				for (k = 0; k < 2; k = k + 1)
				begin
					input_mult_a_stb[k] <= 1'b0;
					input_mult_a_stb[k] <= 1'b0;
				end
				if(load)
				begin
					{A_reg[1][1], A_reg[1][0], A_reg[0][1], A_reg[0][0]} = A;
					{B_reg[1][1], B_reg[1][0], B_reg[0][1], B_reg[0][0]} = B;
					state <= s_INITIALIZE;
				end
				else
					state <= s_IDLE;
			end
			s_INITIALIZE:
			begin
				input_mult_a[0] <= A_reg[i][0];
				input_mult_b[0] <= B_reg[0][j];
				input_mult_a[1] <= A_reg[i][1];
				input_mult_b[1] <= B_reg[1][j];
				input_mult_reset <= 0;
				state <= s_MULT;
			end
			s_MULT:
			begin
				input_mult_a_stb[0] <= 1;
				input_mult_a_stb[1] <= 1;
				input_mult_b_stb[0] <= 1;
				input_mult_b_stb[1] <= 1;
				state <= s_WAIT;
			end
			s_WAIT:
			begin
				if (output_mult_ready[0] && output_mult_ready[1])
				begin
					input_adder_reset <= 1;
					state <= s_SUM;
				end
				else
					state <= s_WAIT;
			end
			s_SUM:
			begin
				input_adder_load <= 1;
				if (output_adder_ready)
				begin
					res_reg[i][j] <= output_adder_result;
					state <= s_SET_RESULT;
				end
				else
					state <= s_SUM;
			end
			s_SET_RESULT:
			begin
				input_adder_result_ack <= 1;
				if (i >= 1 && j >= 1)
				begin
					result_ready_reg <= 1;
					result = {res_reg[1][1], res_reg[1][0], res_reg[0][1], res_reg[0][0]};
					state <= s_GET_RESULT;
				end
				else
				begin
					j <= j + 1;
					if (j >= 1)
					begin
						j <= 0;
						i <= i + 1;
					end
					input_adder_reset <= 0;
					input_mult_reset <= 1;
					input_adder_load <= 0;
					input_adder_result_ack <= 0;
					for (k = 0; k < 2; k = k + 1)
					begin
						input_mult_a_stb[k] <= 1'b0;
						input_mult_b_stb[k] <= 1'b0;
					end
					state <= s_INITIALIZE;
				end
			end
			s_GET_RESULT:
				if (result_ack)
				begin
					result_ready_reg <= 1'b0;
					input_adder_result_ack <= 0;
					state <= s_IDLE;
				end
				else
					state <= s_GET_RESULT;
			default:
				state <= s_IDLE;
		endcase
	end
end

endmodule