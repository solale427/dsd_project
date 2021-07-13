module top (
    input start,
    input reset,
    input clk,
    input mult_ack,
    output reg ready
 );
    
    parameter A_OFFSET = 16'd2;
    parameter B_OFFSET = 16'd302;
    parameter C_OFFSET = 16'd602;

    parameter ADDRESS_SIZE = 10;
    parameter CONFIG_ADDR = 1;
    parameter STATUS_ADDR = 0;
    
    localparam S_IDLE = 0;
    localparam S_READ_STATUS = 1;
    localparam S_READ_CONFIG = 2;
    localparam S_READ_A = 3;
    localparam S_EXTEND_A = 4;
    localparam S_READ_B = 5;
    localparam S_EXTEND_B = 6;
    localparam S_WAIT_FOR_MULT = 7;
    localparam S_WAIT_FOR_ADD = 8;
    localparam S_PREPARE_FOR_WRITE = 9;
    localparam S_WRITE = 10;
    localparam S_PREPARE_TO_READ = 11;
    localparam S_FINISH = 12;
        
    reg [7:0] A_row_size, A_column_size, B_row_size, B_column_size, C_row_size, C_column_size;
    reg input_ready = 1'b0;  //first bit of status
    reg [7:0] A_row_index, A_column_index, B_row_index, B_column_index, C_row_index, C_column_index;
    
    reg [5:0] state = S_IDLE;
    
    reg [ADDRESS_SIZE - 1:0] mem_addr;
    reg [31:0] mem_Din;
    reg mem_read = 1'b0;
    reg mem_write = 1'b0;
    wire [31:0] mem_Dout_wire;
    reg [31:0] mem_Dout = 32'b0;
    
    reg [31:0] A_block [3:0][3:0];
    reg [31:0] B_block [3:0][3:0];
    reg [31:0] C_block [3:0][3:0];
    reg size_mismatch_error = 1'b0;
    integer i, j;
    reg finished = 0;
    
    reg A_stb_mult = 0;
    reg B_stb_mult = 0;
    reg result_ack_mult = 0;
    reg [32 * 4 * 4 - 1:0] A_mult, B_mult;
    wire result_ready_mult;
    wire [32 * 4 * 4 - 1:0] result_mult;
    
    reg A_stb_add = 0;
    reg B_stb_add = 0;
    reg result_ack_add = 0;
    reg [32 * 4 * 4 - 1:0] A_add, B_add;
    wire result_ready_add;
    wire [32 * 4 * 4 - 1:0] result_add;
    
    sync_ram mem(
        .clk(clk),
        .addr(mem_addr),
        .Din(mem_Din),
        .read(mem_read),
        .writeEn(mem_write),
        .Dout(mem_Dout_wire)
    );
    
    fbf_multiplier multiplier(
        .A_stb(A_stb_mult),
        .B_stb(B_stb_mult),
        .clk(clk),
        .reset(reset),
        .result_ack(result_ack_mult),
        .A(A_mult),
        .B(B_mult),
        .result_ready(result_ready_mult),
        .result(result_mult)
    );
    
    fbf_adder adder(
        .A_stb(A_stb_add),
        .B_stb(B_stb_add),
        .clk(clk),
        .reset(reset),
        .result_ack(result_ack_add),
        .A(A_add),
        .B(B_add),
        .result_ready(result_ready_add),
        .result(result_add)
    );
    
    
    
    always @(posedge clk or negedge reset)
    begin
        
        if(!reset)
        begin
            A_stb_mult = 0;
            B_stb_mult = 0;
            result_ack_mult = 0;
            A_stb_add = 0;
            B_stb_add = 0;
            result_ack_add = 0;
            set_off_memory();
            size_mismatch_error <= 1'b0;
            ready = 0;
            finished = 1'b0;
            state <= S_IDLE;
        end
        else
        begin
		  mem_Dout = mem_Dout_wire;
            case (state)
                S_IDLE:
                begin
                    finished = 1'b0;
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
                    input_ready = mem_Dout[0];
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
                        set_off_memory();
                        size_mismatch_error <= 1'b1;
                        state <= S_IDLE;
                    end
                    else
                    begin
                        C_row_size <= A_row_size;
                        C_column_size <= B_column_size;
                        clear_C_block();
                        reset_indexes();
                        i = 0;
                        j = 0;
                        read_memory(get_address(A_row_index, A_column_index, A_row_size, A_column_size, A_OFFSET));
                        state <= S_READ_A;
                    end
                end
                S_READ_A:
                begin
                    if(i < 4 && i + A_row_index < A_row_size)
                    begin
                        A_block[i][j] = mem_Dout;
                        j = j + 1;
                        if(j >= 4 || j + A_column_index >= A_column_size)
                        begin
                            j = 0;
                            i = i + 1;
                        end
                        read_memory(get_address(A_row_index + i, A_column_index + j, A_row_size, A_column_size, A_OFFSET));
                        state <= S_READ_A;
                    end
                    else
                    begin
                        set_off_memory();
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
                                A_block[i][j] = 0;
                            end
                        end
                    end
                    i = 0;
                    j = 0;
                    read_memory(get_address(B_row_index, B_column_index, B_row_size, B_column_size, B_OFFSET));
                    state <= S_READ_B;
                end
                S_READ_B:
                begin
                    if(i < 4 && i + B_row_index < B_row_size)
                    begin
                        B_block[i][j] = mem_Dout;
                        j = j + 1;
                        if(j >= 4 || j + B_column_index >= B_column_size)
                        begin
                            j = 0;
                            i = i + 1;
                        end
                        read_memory(get_address(B_row_index + i, B_column_index + j, B_row_size, B_column_size, B_OFFSET));
                        state <= S_READ_B;
                    end
                    else
                    begin
                        set_off_memory();
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
                                B_block[i][j] = 0;
                            end
                        end
                    end
                    set_A_and_B_mult();
                    A_stb_mult = 1;
                    B_stb_mult = 1;
                    state <= S_WAIT_FOR_MULT;
                end
                S_WAIT_FOR_MULT:
                begin
                    if(result_ready_mult)
                    begin
                        A_stb_mult = 0;
                        B_stb_mult = 0;
                        set_A_and_B_add();
                        result_ack_mult = 1;
                        A_stb_add = 1;
                        B_stb_add = 1;
                        state <= S_WAIT_FOR_ADD;
                    end
                    else
                    begin
                        state <= S_WAIT_FOR_MULT;
                    end
                end
                S_WAIT_FOR_ADD:
                begin
                    result_ack_mult = 0;
                    if(result_ready_add)
                    begin
                        A_stb_add = 0;
                        B_stb_add = 0;
                        set_C_block();
                        result_ack_add = 1;
                        state <= S_PREPARE_FOR_WRITE;
                    end
                    else
                    begin
                        state <= S_WAIT_FOR_ADD;
                    end
                end
                S_PREPARE_FOR_WRITE:
                begin
                    result_ack_add = 0;
                    if(row_read_finished(A_column_index, A_column_size))
                    begin
                        i = 0;
                        j = 0;
                        state <= S_WRITE;
                    end
                    else
                    begin
                        A_column_index = A_column_index + 4;
                        B_row_index = B_row_index + 4;
                        i = 0;
                        j = 0;
                        read_memory(get_address(A_row_index, A_column_index, A_row_size, A_column_size, A_OFFSET));
                        state <= S_READ_A;
                    end
                end
                S_WRITE:
                begin
                    write_memory(get_address(C_row_index + i, C_column_index + j, C_row_size, C_column_size, C_OFFSET), C_block[i][j]);
                    j = j + 1;
                    if(j >= 4 || j + C_column_index >= C_column_size)
                    begin
                        j = 0;
                        i = i + 1;
                    end
                    if(i < 4 && i + C_row_index < C_row_size)
                    begin
                        state <= S_WRITE;
                    end
                    else
                    begin
                        state <= S_PREPARE_TO_READ;
                    end
                end
                S_PREPARE_TO_READ:
                begin
                    clear_C_block();
                    set_finished();
                    if(finished)
                    begin
                        write_memory(STATUS_ADDR, {1'b1, 31'b0});
                        state <= S_FINISH;
                    end
                    else
                    begin
                        set_indexes();
                        i = 0;
                        j = 0;
                        read_memory(get_address(A_row_index, A_column_index, A_row_size, A_column_size, A_OFFSET));
                        state <= S_READ_A;
                    end    
                end
                S_FINISH:
                begin
                    ready = 1;
                    if(mult_ack)
                    begin
                        ready = 0;
                        write_memory(STATUS_ADDR, 32'b0);
                        state <= S_IDLE;
                    end
                    else
                    begin
                        set_off_memory();
                        state <= S_FINISH;
                    end
                end
            endcase
        end
    end
    
    
    
    
    function automatic [ADDRESS_SIZE - 1:0] get_address(
        input [7:0] row_index,
        input [7:0] column_index,
        input [7:0] row_size,
        input [7:0] column_size,
        input [ADDRESS_SIZE - 1:0] offset
    );
    begin
        get_address = row_index * column_size + column_index + offset;
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
        input [31:0] config_data
    );
    begin
        A_row_size = config_data[7:0];
        A_column_size = config_data[15:8];
        B_row_size = config_data[23:16];
        B_column_size = config_data[31:24];
    end
    endtask
    
    task automatic reset_indexes();
    begin
       A_row_index = 8'b0;
       A_column_index = 8'b0;
       B_row_index = 8'b0;
       B_column_index = 8'b0;
       C_row_index = 8'b0;
       C_column_index = 8'b0;
    end
    endtask
    
    function automatic row_read_finished(
        input [7:0] column_index,
        input [7:0] column_size
    );
    begin
        if(column_index + 4 >= column_size)
            row_read_finished = 1'b1;
        else
            row_read_finished = 1'b0;
    end
    endfunction
    
    task automatic clear_C_block();
    begin: clear_C_block_task
        integer i, j;
        for(i = 0; i < 4; i = i + 1)
            for(j = 0; j < 4; j = j + 1)
                C_block[i][j] = 0;
    end
    endtask
    
    task automatic set_finished();
    begin
        if(C_row_index + 4 >= C_row_size && C_column_index + 4 >= C_column_size)
            finished = 1'b1;
        else
            finished = 1'b0;
    end
    endtask
    
    task automatic set_indexes();
    begin
        A_column_index = 0;
        B_row_index = 0;
        B_column_index = B_column_index + 4;
        C_column_index = C_column_index + 4;
        if(B_column_index >= B_column_size)
        begin
            B_column_index = 0;
            A_row_index = A_row_index + 4;
            C_column_index = 0;
            C_row_index = C_row_index + 4;
        end
    end
    endtask
    
    task automatic set_A_and_B_mult();
    begin: set_A_and_B_mult_task
        integer m, n;
        for(m = 0; m < 4; m = m + 1)
        begin
            for(n = 0; n < 4; n = n + 1)
            begin
                A_mult[((4*m+n)*32)+:32] = A_block[m][n];
                B_mult[((4*m+n)*32)+:32] = B_block[m][n];
            end
        end
    end
    endtask
    
    task automatic set_A_and_B_add();
    begin: set_A_and_B_add_task
        integer m, n;
        for(m = 0; m < 4; m = m + 1)
        begin
            for(n = 0; n < 4; n = n + 1)
            begin
                A_add[((4*m+n)*32)+:32] = C_block[m][n];
            end
        end
        B_add = result_mult;
    end
    endtask
    
    task automatic set_C_block();
    begin: set_C_block_task
        integer m, n;
        for(m = 0; m < 4 ; m = m + 1)
        begin
            for(n = 0; n < 4 ; n = n + 1)
            begin
                C_block[m][n] = result_add[((m*4+n)*32)+:32];
            end
        end
    end
    endtask
    
    task automatic set_off_memory();
    begin
        mem_addr = 0;
        mem_read = 0;
        mem_write = 0;
    end
    endtask
    
endmodule