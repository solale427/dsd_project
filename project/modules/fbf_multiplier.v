module fbf_multiplier (
    input A_stb,
    input B_stb,
    input clk,
    input reset,
    input result_ack,
    input [32 * 4 * 4 - 1:0] A,
    input [32 * 4 * 4 - 1:0] B,
    output reg result_ready,
    output reg [32 * 4 * 4 - 1:0] result
);
    
    localparam UP = 1'b1;
    localparam DOWN = 1'b0;
    localparam LEFT = 1'b1;
    localparam RIGHT = 1'b0;
    
    localparam S_IDLE = 0;
    localparam S_SET_MULTIPLIERS_INPUT = 1;
    localparam S_WAIT_FOR_FIRST = 2;
    localparam S_SHIFT = 3;
    localparam S_WAIT_FOR_SECOND = 4;
    localparam S_SET_ADDER_INPUT = 5;
    localparam S_WAIT_FOR_ADDER = 6;
    localparam S_SET_RESULT = 7;
    
    reg [3:0] state = 0;
    
    reg [31:0] A_reg [3:0][3:0];
    reg [31:0] B_reg [3:0][3:0];
    reg [31:0] result_reg [3:0][3:0];
    
    wire [32 * 4 * 4 - 1:0] temp_mult_result;
    reg [31:0] first_mult_result [3:0][3:0];
    reg [31:0] second_mult_result [3:0][3:0];
    wire mult_result_ready[3:0];
    reg mult_load = 0;
    reg mult_result_ack = 0;
    
    reg add_stb = 0;
    reg add_result_ack = 0;
    wire add_result_ready[3:0];
    wire [32 * 4 * 4 - 1:0] temp_add_result;
    
    integer j;
    integer k;
    
    genvar i;
    generate for(i = 0; i < 4; i = i + 1)
    begin: mult_loop
        reg [3:0] row_index = (i / 2) * 2;
        reg [3:0] column_index = (i % 2) * 2;
        wire [32 * 2 * 2 - 1:0] input_A, input_B, output_result;
        assign input_A = {A_reg[row_index + 1][column_index + 1], A_reg[row_index + 1][column_index], A_reg[row_index][column_index + 1], A_reg[row_index][column_index]};
        assign input_B = {B_reg[row_index + 1][column_index + 1], B_reg[row_index + 1][column_index], B_reg[row_index][column_index + 1], B_reg[row_index][column_index]};
        tbt_mult_async multiplier(
            .clk(clk),
            .reset(reset),
            .load(mult_load),
            .A(input_A),
            .B(input_B),
            .result(output_result),
            .result_ready(mult_result_ready[i]),
            .result_ack(mult_result_ack)
        );
        assign temp_mult_result[(i*128)+:128] = output_result;
    end
    endgenerate
    
    genvar l;
    generate for(l = 0; l < 4; l = l + 1)
    begin: add_loop 
        reg [3:0] row_index = (l / 2) * 2;
        reg [3:0] column_index = (l % 2) * 2;
        wire [32 * 2 * 2 - 1:0] input_A, input_B, output_result;
        assign input_A = {first_mult_result[row_index + 1][column_index + 1], first_mult_result[row_index + 1][column_index], first_mult_result[row_index][column_index + 1], first_mult_result[row_index][column_index]};
        assign input_B = {second_mult_result[row_index + 1][column_index + 1], second_mult_result[row_index + 1][column_index], second_mult_result[row_index][column_index + 1], second_mult_result[row_index][column_index]};
        tbt_adder adder (
            .A_stb(add_stb),
            .B_stb(add_stb),
            .clk(clk),
            .reset(reset),
            .result_ack(add_result_ack),
            .A(input_A),
            .B(input_B),
            .result_ready(add_result_ready[l]),
            .result(output_result)
        );
        assign temp_add_result[(l*128)+:128] = output_result;
    end
    endgenerate
    
    always @ (posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            mult_load <= 0;
            mult_result_ack <= 0;
            add_stb <= 0;
            add_result_ack <= 0;
            result_ready <= 0;
            state <= S_IDLE;
        end
        else
        begin
            case (state)
                S_IDLE:
                begin
                    result_ready <= 0;
                    add_result_ack <= 0;
                    if(A_stb && B_stb)
                    begin
                        set_A_and_B();
                        shift_left_block_A(DOWN);
                        shift_left_block_B(RIGHT);
                        state <= S_SET_MULTIPLIERS_INPUT;
                    end
                    else
                    begin
                        state <= S_IDLE;
                    end
                end
                S_SET_MULTIPLIERS_INPUT:
                begin
                    mult_load <= 1;
                    state <= S_WAIT_FOR_FIRST;
                end
                S_WAIT_FOR_FIRST:
                begin
                    if(mult_result_ready[0] && mult_result_ready[1] && mult_result_ready[2] && mult_result_ready[3])
                    begin
                        for(j = 0; j < 4; j = j + 1)
                        begin
                            for(k = 0; k < 4; k = k + 1)
                            begin
                                first_mult_result[j][k] = temp_mult_result[((4*j+k)*32)+:32];
                            end
                        end
                        mult_load <= 0;
                        mult_result_ack <= 1;
                        state <= S_SHIFT;
                    end
                    else
                    begin
                        state <= S_WAIT_FOR_FIRST;
                    end
                end
                S_SHIFT:
                begin
                    shift_left_block_A(UP);
                    shift_left_block_A(DOWN);
                    shift_left_block_B(LEFT);
                    shift_left_block_B(RIGHT);
                    mult_load <= 1;
                    state <= S_WAIT_FOR_SECOND;
                end
                S_WAIT_FOR_SECOND:
                begin
                    mult_result_ack <= 0;
                    if(mult_result_ready[0] && mult_result_ready[1] && mult_result_ready[2] && mult_result_ready[3])
                    begin
                        for(j = 0; j < 4; j = j + 1)
                        begin
                            for(k = 0; k < 4; k = k + 1)
                            begin
                                second_mult_result[j][k] <= temp_mult_result[((4*j+k)*32)+:32];
                            end
                        end
                    	mult_load <= 0;
                     mult_result_ack <= 1;
                     state <= S_SET_ADDER_INPUT;
                    end 
                    else
                    begin
                        state <= S_WAIT_FOR_SECOND;
                    end
                end
                S_SET_ADDER_INPUT:
                begin
                    add_stb <= 1;
                    state <= S_WAIT_FOR_ADDER;
                end
                S_WAIT_FOR_ADDER:
                begin
                    mult_result_ack <= 0;
                    if(add_result_ready[0] && add_result_ready[1] && add_result_ready[2] && add_result_ready[3])
                    begin
                        for(j = 0; j < 4; j = j + 1)
                        begin
                            for(k = 0; k < 4; k = k + 1)
                            begin
                                result_reg[j][k] = temp_add_result[((4*j+k)*32)+:32];
                            end
                        end
                    	add_stb <= 0;
                        add_result_ack <= 1;
                        state <= S_SET_RESULT;
                    end
                    else
                    begin
                        state <= S_WAIT_FOR_ADDER;
                    end
                end
                S_SET_RESULT:
                begin
                 
                    set_result();
                    result_ready <= 1;
                    if(result_ack)
                    begin
                        result_ready <= 0;
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
    begin: set_A_and_B_task
        integer m, n;
        for(m = 0; m < 4 ; m = m + 1)
        begin
            for(n = 0; n < 4 ; n = n + 1)
            begin
                A_reg[m][n] <= A[((m*4+n)*32)+:32];
                B_reg[m][n] <= B[((m*4+n)*32)+:32];
            end
        end
    end
    endtask
    
    task automatic shift_left_block_A(
        input up
    );
    begin: shift_left_block_A_task
        reg [1:0] offset;
        offset = up ? 2'd0 : 2'd2;
        A_reg[offset][0] <= A_reg[offset][2];
        A_reg[offset][2] <= A_reg[offset][0];
        A_reg[offset][1] <= A_reg[offset][3];
        A_reg[offset][3] <= A_reg[offset][1];
        A_reg[offset + 1][0] <= A_reg[offset + 1][2];
        A_reg[offset + 1][2] <= A_reg[offset + 1][0];
        A_reg[offset + 1][1] <= A_reg[offset + 1][3];
        A_reg[offset + 1][3] <= A_reg[offset + 1][1];
    end
    endtask
    
    task automatic shift_left_block_B(
        input left
    );
    begin: shift_left_block_B_task
        reg [1:0] offset;
        offset = left ? 2'd0 : 2'd2;
        B_reg[0][offset] <= B_reg[2][offset];
        B_reg[2][offset] <= B_reg[0][offset];
        B_reg[1][offset] <= B_reg[3][offset];
        B_reg[3][offset] <= B_reg[1][offset];
        B_reg[0][offset + 1] <= B_reg[2][offset + 1];
        B_reg[2][offset + 1] <= B_reg[0][offset + 1];
        B_reg[1][offset + 1] <= B_reg[3][offset + 1];
        B_reg[3][offset + 1] <= B_reg[1][offset + 1];
    end
    endtask
    
    task automatic set_result();
    begin: set_result_task
        integer m, n;
        for(m = 0; m < 4; m = m + 1)
        begin
            for(n = 0; n < 4; n = n + 1)
            begin
                result[((4*m+n)*32)+:32] = result_reg[m][n];
            end
        end
    end
    endtask
    
 endmodule