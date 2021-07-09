'define A_OFFSET
'define B_OFFSET
module top (
    input start,
    input reset,
    input clock
 );
    
    parameter ADDRESS_SIZE = 9;
    parameter CONFIG_ADDR = 1;
    parameter STATUS_ADDR = 0;
    
    localparam S_IDLE = 0;
    localparam S_READ_STATUS = 1;
    localparam S_READ_CONFIG = 2;
    localparam S_READ_A = 3;
    localparam S_EXTEND_A = 4;
    localparam S_READ_B = 5;
    localparam S_EXTEND_B = 6;
    localparam S_WAIT = 7;
    localparam S_WAIT_FOR_WRITE = 8;
    localparam S_WRITE = 9;
    localparam S_PREPARE_TO_READ = 10;
    localparam S_FINISH = 11;
        
    reg [7:0] A_row_size, A_column_size, B_row_size, B_column_size;
    reg input_ready = 1'b0;  //first bit of status
    reg [7:0] A_row_index, A_column_index, B_row_index, B_column_index;
    wire A_ack, B_ack;   //output 4 by 4 multiplier
    reg A_stb, B_stb;    //input 4 by 4 multiplier
    reg [31:0] state = S_IDLE;
    reg [ADDRESS_SIZE - 1:0] mem_addr;
    reg [31:0] mem_Din;
    reg mem_read = 1'b0;
    reg mem_write = 1'b0;
    wire [31:0] mem_Dout_wire;
    reg [31:0] mem_Dout = 32'b0;
    reg [31:0] A [3:0][3:0];
    reg [31:0] B [3:0][3:0];
    reg size_mismatch_error = 1'b0;
    integer i, j;
    
    memory mem(
        .clk(clock),
        .addr(mem_addr),
        .Din(mem_Din),
        .Read(mem_read),
        .WriteEn(mem_write),
        .Dout(mem_Dout_wire)
    );
    
    always @(posedge clock or negedge reset)
    begin
        mem_Dout <= mem_Dout_wire;
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
                    begin
                        read_memory(STATUS_ADDR);
                        state <= S_READ_STATUS;
                    end
                    else
                    begin
                        state <= S_IDLE;
                    end
                end
                S_READ_STATUS:
                begin
                    input_ready <= mem_Dout[0];
                    if(input_ready)
                    begin
                        read_memory(CONFIG_ADDR);
                        state <= S_READ_CONFIG;
                    end
                    else
                    begin
                        read_memory(STATUS_ADDR);
                        state <= S_IDLE;
                    end
                end
                S_READ_CONFIG:
                begin
                    read_config(mem_Dout);
                    if(A_column_size != B_row_size)
                    begin
                        size_mismatch_error <= 1'b1;
                        state <= S_READ_STATUS;
                    end
                    else
                    begin
                        reset_indexes();
                        i <= 0;
                        j <= 0;
                        read_memory(get_address(A_row_index, A_column_index, A_row_size, A_column_size, A_OFFSET));
                        state <= S_READ_A;
                    end
                end
                S_READ_A:
                begin
                    if(i < 4 && i + A_row_index < A_row_size)
                    begin
                        A[i][j] <= mem_Dout;
                        j <= j + 1;
                        if(j >= 4 || j + A_column_index >= A_column_size)
                        begin
                            j <= 0;
                            i <= i + 1;
                        end
                        read_memory(get_address(A_row_index + i, A_column_index + j, A_row_size, A_column_size, A_OFFSET));
                        state <= S_READ_A;
                    end
                    else
                    begin
                        state <= S_EXTEND_A;
                    end
                end
                S_EXTEND_A:
                begin
                    for(i = 0; i < 4; i = i + 1)
                    begin
                        for(j = 0; j < 4; j = j + 1)
                        begin
                            if(i + A_row_index >= A_row_size || j + A_column_index >= A_column_size)
                            begin
                                A[i][j] <= 0;
                            end
                        end
                    end
                    i <= 0;
                    j <= 0;
                    read_memory(get_address(B_row_index, B_column_index, B_row_size, B_column_size, B_OFFSET));
                    state <= S_READ_B;
                end
                S_READ_B:
                begin
                    if(i < 4 && i + B_row_index < B_row_size)
                    begin
                        B[i][j] <= mem_Dout;
                        j <= j + 1;
                        if(j >= 4 || j + B_column_index >= B_column_size)
                        begin
                            j <= 0;
                            i <= i + 1;
                        end
                        read_memory(get_address(B_row_index + i, B_column_index + j, B_row_size, B_column_size, B_OFFSET));
                        state <= S_READ_B;
                    end
                    else
                    begin
                        state <= S_EXTEND_B;
                    end
                end
                S_EXTEND_B:
                begin
                    for(i = 0; i < 4; i = i + 1)
                    begin
                        for(j = 0; j < 4; j = j + 1)
                        begin
                            if(i + B_row_index >= B_row_size || j + B_column_index >= B_column_size)
                            begin
                                B[i][j] <= 0;
                            end
                        end
                    end
                    state <= S_WAIT;
                end
                S_WAIT:
                begin
                    A_stb <= 1'b1;
                    B_stb <= 1'b1;
                    if(row_read_finished(A_column_index, A_column_size))
                    begin
                        state <= S_WAIT_FOR_WRITE;
                    end
                    else if(A_ack && B_ack)
                    begin 
                        column_index <= column_index + 4;
                        i <= 0;
                        j <= 0;
                        read_memory(get_address(A_row_index, A_column_index, A_row_size, A_column_size, A_OFFSET));
                        state <= S_READ_A;
                    end
                    else
                    begin
                        state <= S_WAIT;
                    end
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
        input [7:0] row_index;
        input [7:0] column_index;
        input [7:0] row_size;
        input [7:0] column_size;
        input [ADDRESS_SIZE - 1:0] offset;
    );
    begin
        get_address = row_index * row_size + column_index + offset;
    end
    endfunction
    
    task automatic read_memory(
        input [ADDRESS_SIZE - 1:0] addr
    );
    begin
        mem_read = 1'b1;
        mem_write = 1'b0;
        mem_addr = addr;
    end
    endtask
    
    task automatic write_memory(
        input [ADDRESS_SIZE - 1:0] addr,
        input [31:0] data_in
    );
    begin
        mem_read = 1'b0;
        mem_write = 1'b1;
        mem_addr = addr;
        mem_Din = data_in;
    end
    endtask
    
    task automatic read_config(
        input [31:0] config
    );
    begin
        A_row_size <= config[7:0];
        A_column_size, <= config[15:8];
        B_row_size <= config[23:16];
        B_column_size <= config[31:24];
    end
    endtask
    
    task automatic reset_indexes();
    begin
       A_row_index = 8'b0;
       A_column_index = 8'b0;
       B_row_index = 8'b0;
       B_column_index = 8'b0;
    end
    endtask
    
    function automatic row_read_finished(
        input [7:0] column_index;
        input [7:0] column_size;
    );
    begin
        if(column_index + 4 >= column_size)
            row_read_finished = 1'b1;
        else
            row_read_finished = 1'b0;
    end
    endfunction
    
endmodule