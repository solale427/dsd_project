
module fbf_multiplier
#(
	parameter FLOAT_SIZE = 32
)
(
	input reg clk,
	input reg reset,
	input load,
	input wire[16*FLOAT_SIZE-1:0] A,
	input wire [16*FLOAT_SIZE-1:0] B,
	output wire [16*FLOAT_SIZE-1:0] Res,
	output wire ready
);
parameter s_IDLE = 3'b000;
parameter s_INITIAL  = 3'b001;
parameter s_ADD_UP_1 = 3'b010;
parameter s_FIRSTSHIFT  = 3'b011;
parameter s_ADD_UP_2 = 3'b100;
parameter s_CLEANUP = 3'b101;

reg[2:0] state = s_IDLE;
reg out_ready = 1'b0;    

reg[FLOAT_SIZE-1:0] A_1_1[3:0];
reg[FLOAT_SIZE-1:0] A_1_2[3:0];
reg[FLOAT_SIZE-1:0] A_2_1[3:0];
reg[FLOAT_SIZE-1:0] A_2_2[3:0];

reg[FLOAT_SIZE-1:0] B_1_1[3:0];
reg[FLOAT_SIZE-1:0] B_1_2[3:0];
reg[FLOAT_SIZE-1:0] B_2_1[3:0];
reg[FLOAT_SIZE-1:0] B_2_2[3:0];

reg[FLOAT_SIZE-1:0] Res_1_1[3:0];
reg[FLOAT_SIZE-1:0] Res_1_2[3:0];
reg[FLOAT_SIZE-1:0] Res_2_1[3:0];
reg[FLOAT_SIZE-1:0] Res_2_2[3:0];

wire [FLOAT_SIZE-1:0] mid_Res_1_1[3:0];
wire [FLOAT_SIZE-1:0] mid_Res_1_2[3:0];
wire [FLOAT_SIZE-1:0] mid_Res_2_1[3:0];
wire [FLOAT_SIZE-1:0] mid_Res_2_2[3:0];

wire [3:0] tbt_ready;
reg [3:0] tbt_load;

assign Res[1 * FLOAT_SIZE - 1:0 * FLOAT_SIZE] = Res_1_1[0];
assign Res[2 * FLOAT_SIZE - 1:1 * FLOAT_SIZE] = Res_1_1[1];
assign Res[3 * FLOAT_SIZE - 1:2 * FLOAT_SIZE] = Res_1_2[0];
assign Res[4 * FLOAT_SIZE - 1:3 * FLOAT_SIZE] = Res_1_2[1];
assign Res[5 * FLOAT_SIZE - 1:4 * FLOAT_SIZE] = Res_1_1[2];
assign Res[6 * FLOAT_SIZE - 1:5 * FLOAT_SIZE] = Res_1_1[3];
assign Res[7 * FLOAT_SIZE - 1:6 * FLOAT_SIZE] = Res_1_2[2];
assign Res[8 * FLOAT_SIZE - 1:7 * FLOAT_SIZE] = Res_1_2[3];

assign Res[9 * FLOAT_SIZE - 1:8 * FLOAT_SIZE] = Res_2_1[0];
assign Res[10 * FLOAT_SIZE - 1:9 * FLOAT_SIZE] = Res_2_1[1];
assign Res[11 * FLOAT_SIZE - 1:10 * FLOAT_SIZE] = Res_2_2[0];
assign Res[12 * FLOAT_SIZE - 1:11 * FLOAT_SIZE] = Res_2_2[1];
assign Res[13 * FLOAT_SIZE - 1:12 * FLOAT_SIZE] = Res_2_1[2];
assign Res[14 * FLOAT_SIZE - 1:13 * FLOAT_SIZE] = Res_2_1[3];
assign Res[15 * FLOAT_SIZE - 1:14 * FLOAT_SIZE] = Res_2_2[2];
assign Res[16 * FLOAT_SIZE - 1:15 * FLOAT_SIZE] = Res_2_2[3];



assign  ready = out_ready;

tbt_mult tbt_mul_1_1(
	.clk(clk),
	.reset(reset),
	.A({A_1_1[3], A_1_1[2], A_1_1[1], A_1_1[0]}),
	.B({B_1_1[3], B_1_1[2], B_1_1[1], B_1_1[0]}),
	.Res({mid_Res_1_1[3], mid_Res_1_1[2], mid_Res_1_1[1], mid_Res_1_1[0]}),
	.result_ready(tbt_ready[0]),
	.load(tbt_load[0])
);

tbt_mult tbt_mul_1_2(
	.clk(clk),
	.reset(reset),
	.A({A_1_2[3], A_1_2[2], A_1_2[1], A_1_2[0]}),
	.B({B_1_2[3], B_1_2[2], B_1_2[1], B_1_2[0]}),
	.Res({mid_Res_1_2[3], mid_Res_1_2[2], mid_Res_1_2[1], mid_Res_1_2[0]}),
	.result_ready(tbt_ready[1]),
	.load(tbt_load[1])
);

tbt_mult tbt_mul_2_1(
	.clk(clk),
	.reset(reset),
	.A({A_2_1[3], A_2_1[2], A_2_1[1], A_2_1[0]}),
	.B({B_2_1[3], B_2_1[2], B_2_1[1], B_2_1[0]}),
	.Res({mid_Res_2_1[3], mid_Res_2_1[2], mid_Res_2_1[1], mid_Res_2_1[0]}),
	.result_ready(tbt_ready[2]),
	.load(tbt_load[2])
);

tbt_mult tbt_mul_2_2(
	.clk(clk),
	.reset(reset),
	.A({A_2_2[3], A_2_2[2], A_2_2[1], A_2_2[0]}),
	.B({B_2_2[3], B_2_2[2], B_2_2[1], B_2_2[0]}),
	.Res({mid_Res_2_2[3], mid_Res_2_2[2], mid_Res_2_2[1], mid_Res_2_2[0]}),
	.result_ready(tbt_ready[3]),
	.load(tbt_load[3])
);


always @(posedge clk or negedge reset)
    begin
	state = state;
	case(state)
	   s_IDLE:
		if (load)
			state <= s_INITIAL;
		else
		        state <= s_IDLE;
	   s_INITIAL:
		begin
		{A_1_1[3], A_1_1[2], A_1_1[1], A_1_1[0]} <= {A[6 * FLOAT_SIZE - 1:5 * FLOAT_SIZE], A[5 * FLOAT_SIZE - 1:4 * FLOAT_SIZE],A[2 * FLOAT_SIZE - 1:1 * FLOAT_SIZE], A[1 * FLOAT_SIZE - 1:0 * FLOAT_SIZE]};
		{A_1_2[3], A_1_2[2], A_1_2[1], A_1_2[0]} <= {A[8 * FLOAT_SIZE - 1:7 * FLOAT_SIZE], A[7 * FLOAT_SIZE - 1:6 * FLOAT_SIZE],A[4 * FLOAT_SIZE - 1:3 * FLOAT_SIZE], A[3 * FLOAT_SIZE - 1:2 * FLOAT_SIZE]};
		{A_2_1[3], A_2_1[2], A_2_1[1], A_2_1[0]} <= {A[16 * FLOAT_SIZE - 1:15 * FLOAT_SIZE], A[15 * FLOAT_SIZE - 1:14 * FLOAT_SIZE],A[12 * FLOAT_SIZE - 1:11 * FLOAT_SIZE], A[11 * FLOAT_SIZE - 1:10 * FLOAT_SIZE]};
		{A_2_2[3], A_2_2[2], A_2_2[1], A_2_2[0]} <= {A[14 * FLOAT_SIZE - 1:13 * FLOAT_SIZE], A[13 * FLOAT_SIZE - 1:12 * FLOAT_SIZE],A[10 * FLOAT_SIZE - 1:9 * FLOAT_SIZE], A[9 * FLOAT_SIZE - 1:8 * FLOAT_SIZE]};
		
		{B_1_1[3], B_1_1[2], B_1_1[1], B_1_1[0]} <= {B[6 * FLOAT_SIZE - 1:5 * FLOAT_SIZE], B[5 * FLOAT_SIZE - 1:4 * FLOAT_SIZE],B[2 * FLOAT_SIZE - 1:1 * FLOAT_SIZE], B[1 * FLOAT_SIZE - 1:0 * FLOAT_SIZE]};
		{B_1_2[3], B_1_2[2], B_1_2[1], B_1_2[0]} <= {B[8 * FLOAT_SIZE - 1:7 * FLOAT_SIZE], B[7 * FLOAT_SIZE - 1:6 * FLOAT_SIZE],B[4 * FLOAT_SIZE - 1:3 * FLOAT_SIZE], B[3 * FLOAT_SIZE - 1:2 * FLOAT_SIZE]};
		{B_2_1[3], B_2_1[2], B_2_1[1], B_2_1[0]} <= {B[16 * FLOAT_SIZE - 1:15 * FLOAT_SIZE], B[15 * FLOAT_SIZE - 1:14 * FLOAT_SIZE],B[12 * FLOAT_SIZE - 1:11 * FLOAT_SIZE], B[11 * FLOAT_SIZE - 1:10 * FLOAT_SIZE]};
		{B_2_2[3], B_2_2[2], B_2_2[1], B_2_2[0]} <= {B[14 * FLOAT_SIZE - 1:13 * FLOAT_SIZE], B[13 * FLOAT_SIZE - 1:12 * FLOAT_SIZE],B[10 * FLOAT_SIZE - 1:9 * FLOAT_SIZE], B[9 * FLOAT_SIZE - 1:8 * FLOAT_SIZE]};
		{tbt_load[3], tbt_load[2], tbt_load[1], tbt_load[0]} <= 4'b1111;
		state <= s_ADD_UP_1;
		end
	   s_ADD_UP_1:
		begin
		if(tbt_ready[0] && tbt_ready[1] && tbt_ready[2] && tbt_ready[3])
			begin
			Res_1_1[0] <= mid_Res_1_1[0];
			Res_1_1[1] <= mid_Res_1_1[1];
			Res_1_1[2] <= mid_Res_1_1[2];
			Res_1_1[3] <= mid_Res_1_1[3];
			
			Res_1_2[0] <= mid_Res_1_2[0];
			Res_1_2[1] <= mid_Res_1_2[1];
			Res_1_2[2] <= mid_Res_1_2[2];
			Res_1_2[3] <= mid_Res_1_2[3];
			
			Res_2_1[0] <= mid_Res_2_1[0];
			Res_2_1[1] <= mid_Res_2_1[1];
			Res_2_1[2] <= mid_Res_2_1[2];
			Res_2_1[3] <= mid_Res_2_1[3];
			
			Res_2_2[0] <= mid_Res_2_2[0];
			Res_2_2[1] <= mid_Res_2_2[1];
			Res_2_2[2] <= mid_Res_2_2[2];
			Res_2_2[3] <= mid_Res_2_2[3];
		    state <= s_FIRSTSHIFT;
		    {tbt_load[3], tbt_load[2], tbt_load[1], tbt_load[0]} <= 4'b0000;
			end
		end
	   s_FIRSTSHIFT:
		begin
		{A_1_1[3], A_1_1[2], A_1_1[1], A_1_1[0]} <= {A[8 * FLOAT_SIZE - 1:7 * FLOAT_SIZE], A[7 * FLOAT_SIZE - 1:6 * FLOAT_SIZE],A[4 * FLOAT_SIZE - 1:3 * FLOAT_SIZE], A[3 * FLOAT_SIZE - 1:2 * FLOAT_SIZE]};
		{A_1_2[3], A_1_2[2], A_1_2[1], A_1_2[0]} <= {A[6 * FLOAT_SIZE - 1:5 * FLOAT_SIZE], A[5 * FLOAT_SIZE - 1:4 * FLOAT_SIZE],A[2 * FLOAT_SIZE - 1:1 * FLOAT_SIZE], A[1 * FLOAT_SIZE - 1:0 * FLOAT_SIZE]};
		{A_2_1[3], A_2_1[2], A_2_1[1], A_2_1[0]} <= {A[14 * FLOAT_SIZE - 1:13 * FLOAT_SIZE], A[13 * FLOAT_SIZE - 1:12 * FLOAT_SIZE],A[10 * FLOAT_SIZE - 1:9 * FLOAT_SIZE], A[9 * FLOAT_SIZE - 1:8 * FLOAT_SIZE]};
		{A_2_2[3], A_2_2[2], A_2_2[1], A_2_2[0]} <= {A[16 * FLOAT_SIZE - 1:15 * FLOAT_SIZE], A[15 * FLOAT_SIZE - 1:14 * FLOAT_SIZE],A[12 * FLOAT_SIZE - 1:11 * FLOAT_SIZE], A[11 * FLOAT_SIZE - 1:10 * FLOAT_SIZE]};
		
		{B_1_1[3], B_1_1[2], B_1_1[1], B_1_1[0]} <= {B[16 * FLOAT_SIZE - 1:15 * FLOAT_SIZE], B[15 * FLOAT_SIZE - 1:14 * FLOAT_SIZE],B[12 * FLOAT_SIZE - 1:11 * FLOAT_SIZE], B[11 * FLOAT_SIZE - 1:10 * FLOAT_SIZE]};
		{B_1_2[3], B_1_2[2], B_1_2[1], B_1_2[0]} <= {B[14 * FLOAT_SIZE - 1:13 * FLOAT_SIZE], B[13 * FLOAT_SIZE - 1:12 * FLOAT_SIZE],B[10 * FLOAT_SIZE - 1:9 * FLOAT_SIZE], B[9 * FLOAT_SIZE - 1:8 * FLOAT_SIZE]};
		{B_2_1[3], B_2_1[2], B_2_1[1], B_2_1[0]} <= {B[6 * FLOAT_SIZE - 1:5 * FLOAT_SIZE], B[5 * FLOAT_SIZE - 1:4 * FLOAT_SIZE],B[2 * FLOAT_SIZE - 1:1 * FLOAT_SIZE], B[1 * FLOAT_SIZE - 1:0 * FLOAT_SIZE]};
		{B_2_2[3], B_2_2[2], B_2_2[1], B_2_2[0]} <= {B[8 * FLOAT_SIZE - 1:7 * FLOAT_SIZE], B[7 * FLOAT_SIZE - 1:6 * FLOAT_SIZE],B[4 * FLOAT_SIZE - 1:3 * FLOAT_SIZE], B[3 * FLOAT_SIZE - 1:2 * FLOAT_SIZE]};
		{tbt_load[3], tbt_load[2], tbt_load[1], tbt_load[0]} <= 4'b1111;
		state <= s_ADD_UP_2;
		end
	   s_ADD_UP_2:
		begin
		if(tbt_ready[0])
		   begin
			Res_1_1[0] <= Res_1_1[0] + mid_Res_1_1[0];
			Res_1_1[1] <= Res_1_1[1] + mid_Res_1_1[1];
			Res_1_1[2] <= Res_1_1[2] + mid_Res_1_1[2];
			Res_1_1[3] <= Res_1_1[3] + mid_Res_1_1[3];
		   end
		if(tbt_ready[1])
		   begin
			Res_1_2[0] <= Res_1_2[0] + mid_Res_1_2[0];
			Res_1_2[1] <= Res_1_2[1] + mid_Res_1_2[1];
			Res_1_2[2] <= Res_1_2[2] + mid_Res_1_2[2];
			Res_1_2[3] <= Res_1_2[3] + mid_Res_1_2[3];
		   end
		if(tbt_ready[2])
		   begin
			Res_2_1[0] <= Res_2_1[0] + mid_Res_2_1[0];
			Res_2_1[1] <= Res_2_1[1] + mid_Res_2_1[1];
			Res_2_1[2] <= Res_2_1[2] + mid_Res_2_1[2];
			Res_2_1[3] <= Res_2_1[3] + mid_Res_2_1[3];
		   end
		if(tbt_ready[3])
		   begin
			Res_2_2[0] <= Res_2_2[0] + mid_Res_2_2[0];
			Res_2_2[1] <= Res_2_2[1] + mid_Res_2_2[1];
			Res_2_2[2] <= Res_2_2[2] + mid_Res_2_2[2];
			Res_2_2[3] <= Res_2_2[3] + mid_Res_2_2[3];
		   end
		if(tbt_ready[0] && tbt_ready[1] && tbt_ready[2] && tbt_ready[3])
		   state <= s_CLEANUP;	
		   {tbt_load[3], tbt_load[2], tbt_load[1], tbt_load[0]} <= 4'b0000;
		end
	   s_CLEANUP:
		begin
		out_ready <= 1'b1;
		state <= s_IDLE;
		end
	endcase
    end


endmodule

