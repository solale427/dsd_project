`timescale 1ns / 1ps

module top_TB();



    reg clk = 1'b0;
    wire ready;
    reg start = 1'b1;
    reg reset = 1'b1;
    reg result_ack = 1'b0;
    
    integer j;
    
    top top(
    .start(start),
    .reset(reset),
    .clk(clk),
    .mult_ack(ack),
    .ready(ready)
    );

    initial 
    begin
      forever
        #5 clk = ~clk;
    end 

    initial
    begin
        $monitor("ready: %b", ready);
    end 
    
    always @(posedge ready)
    begin
        if(ready)
        begin
            for(j = 0; j < top.C_column_size * top.C_row_size; j = j + 1)
            begin
                $display("%b", top.mem.mem[j + top.C_OFFSET]);
            end
        end
    end
  
endmodule