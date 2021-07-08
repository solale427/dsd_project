'define A_OFFSET
'define B_OFFSET
module top (
    input reset,
    input clock,
 );
    
    parameter ADDRESS_SIZE = 8;  
    localparam S_IDLE = 0;
    localparam S_READ_CONFIG = 1;
    localparam S_READ_A = 2;
    localparam S_EXTEND_A = 3;
    localparam S_READ_B = 4;
    localparam S_EXTEND_B = 5;
    localparam S_WAIT = 6;
    localparam S_WAIT_FOR_WRITE = 7;
    localparam S_WRITE = 8;
    localparam S_PREPARE_TO_READ = 9;
    localparam S_FINISH = 10;
        
    wire A_ack, B_ack;   //output 4 by 4 multiplier
    reg A_stb, B_stb;    //input 4 by 4 multiplier
    reg start = 1'b0;  //first bit of status
    reg size_mismatch_error;
    reg is_is_fullsize;
    reg [31:0] state = S_IDLE;
    reg [ADDRESS_SIZE - 1:0] mem_addr;
    reg [31:0] mem_Din;
    reg mem_read;
    reg mem_write;
    wire [31:0] mem_Dout;
    reg [31:0] A [3:0][3:0];
    reg [31:0] B [3:0][3:0];
    
    memory mem(
        .clk(clock),
        .addr(mem_addr),
        .Din(mem_Din),
        .Read(mem_read),
        .WriteEn(mem_write),
        .Dout(mem_Dout)
    );
    
    always @(posedge clock or negedge reset)
    begin
        if(!reset)
        begin
            state <= S_IDLE;
        end
        else
        begin
            case (state)
                S_IDLE:
                begin
                    if(start)
                        
                end
                S_READ_CONFIG:
                begin
                
                end
                S_READ_A:
                begin
                
                end
                S_EXTEND_A:
                begin
                
                end
                S_READ_B:
                begin
                
                end
                S_EXTEND_B:
                begin
                
                end
                S_WAIT:
                begin
                
                end
                S_WAIT_FOR_WRITE:
                begin
                
                end
                S_WRITE:
                begin
                
                end
                S_PREPARE_TO_READ:
                begin
                
                end
                S_FINISH:
                begin
                
                end
            endcase
        end
    end
    
    
    
    
    function automatic [ADDRESS_SIZE - 1:0] get_address(
        input [7:0] column_index;
        input [7:0] row_index;
        input [7:0] column_size;
        input [7:0] row_size;
        input [ADDRESS_SIZE - 1:0] offset;
    );
    begin
        get_address = row_index * row_size + column_index + offset;
    end
    endfunction
        
endmodule