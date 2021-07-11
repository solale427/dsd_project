module fbf_adder #(
    parameter SIZE = 4
)
(
    input A_stb,
    input B_stb,
    input clk,
    input reset,
    input result_ack,
    input [32 * SIZE * SIZE - 1:0] A,
    input [32 * SIZE * SIZE - 1:0] B,
    output result_ready,
    output [32 * SIZE * SIZE - 1:0] result
);
    
    wire temp_result_ready[3:0];
    
    genvar i;
    generate for(i = 0; i < SIZE; i = i + 1) 
    begin
        tbt_adder partial_adder (
            .A_stb(A_stb),
            .B_stb(B_stb),
            .clk(clk),
            .reset(reset),
            .result_ack(result_ack),
            .A(A[(i * 32 * 2 * 2)+:32 * 2 * 2]),
            .B(B[(i * 32 * 2 * 2)+:32 * 2 * 2]),
            .result_ready(temp_result_ready[i]),
            .result(result[(i * 32 * 2 * 2)+:32 * 2 * 2])
        );
    end
    endgenerate
    
    assign result_ready = temp_result_ready[0] & temp_result_ready[1] & temp_result_ready[2] & temp_result_ready[3];
    
endmodule