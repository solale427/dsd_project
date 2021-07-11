module tbt_adder (
    input A_stb,
    input B_stb,
    input clk,
    input reset,
    input result_ack,
    input [32 * 2 * 2 - 1:0] A,
    input [32 * 2 * 2 - 1:0] B,
    output reg result_ready,
    output reg [32 * 2 * 2 - 1:0] result
);
 
 localparam S_IDLE = 0;
 localparam S_SET_ADDER_INPUT = 1;
 localparam S_WAIT = 2;
 localparam S_WRITE_RESULT = 3;
 localparam S_SET_RESULT = 4;
 
 reg [2:0] state = S_IDLE;
 
 reg input_adder_load = 0;
 reg [31:0] input_adder_a;
 reg [31:0] input_adder_b;
 reg input_adder_ack;
 wire [31:0] output_adder_result;
 wire output_adder_ready;
 
 
 reg [31:0] A_reg[1:0][1:0];
 reg [31:0] B_reg[1:0][1:0];
 reg [31:0] result_reg[1:0][1:0];
 
 integer i;
 integer j;
 
 adder single_adder (
    .reset(reset),
    .clk(clk),
    .load(input_adder_load),
    .Number1(input_adder_a),
    .Number2(input_adder_b),
    .result_ready(output_adder_ready),
    .result_ack(input_adder_ack),
    .Result(output_adder_result)
);

 always @(posedge clk or negedge reset)
 begin
    if(!reset)
    begin
        input_adder_load <= 0;
        input_adder_ack <= 0;
        state <= S_IDLE;
    end
    else
    begin
        case (state)
            S_IDLE:
            begin
		      result_ready <= 0;
                if(A_stb && B_stb)
                begin
                    i <= 0;
                    j <= 0;
                    set_A_and_B();
                    state <= S_SET_ADDER_INPUT;
                end
                else
                begin
                    state <= S_IDLE;
                end
            end
            S_SET_ADDER_INPUT:
            begin
                input_adder_a <= A_reg[i][j];
                input_adder_b <= B_reg[i][j];
                input_adder_load <= 1;
                input_adder_ack <= 0;
                state <= S_WAIT;
            end
            S_WAIT:
            begin
                input_adder_load <= 0;
                if(output_adder_ready)
                begin
                    state <= S_WRITE_RESULT;
                end
                else
                begin
                    state <= S_WAIT;
                end
            end
            S_WRITE_RESULT:
            begin
                result_reg[i][j] <= output_adder_result;
                input_adder_ack <= 1;
                if(i >= 1 && j>=1)
                begin
                    state <= S_SET_RESULT;
                end
                else
                begin
                    j <= j + 1;
                    if(j > 1)
                    begin
                        j <= 0;
                        i <= i + 1;
                    end
                    state <= S_SET_ADDER_INPUT;  
                end
            end
            S_SET_RESULT:
            begin
                result <= {result_reg[1][1], result_reg[1][0], result_reg[0][1], result_reg[0][0]};
                result_ready <= 1;
                if(result_ack)
                begin
                    state <= S_IDLE;
                end
                else
                begin
                    state <= S_SET_RESULT;
                end
            end
            default:
            begin
                state <= S_IDLE;
            end
        endcase
    end
 end
 
 task automatic set_A_and_B();
 begin: set_A_and_B_tbt
    integer m;
    integer n;
    for(m = 0; m < 2 ; m = m + 1)
    begin
        for(n = 0; n < 2 ; n = n + 1)
        begin
            A_reg[m][n] = A[((m*2+n)*32)+:32];
            B_reg[m][n] = B[((m*2+n)*32)+:32];
        end
    end
 end
 endtask

endmodule