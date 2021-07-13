module RAM_TB;

parameter ADDR_WIDTH = 10;
localparam RAM_DEPTH = 1 << ADDR_WIDTH;
reg clk;
reg writeEn;
reg read = 0;
reg [ADDR_WIDTH-1:0] addr;
reg [31:0] din;
wire [31:0] dout;
sync_ram #(.ADDR_WIDTH(ADDR_WIDTH)) s0
	(.Din(din), .addr(addr), .writeEn(writeEn), .read(read), .clk(clk), .Dout(dout));

initial
   begin
      clk = 1;
      repeat(200) #10 clk = ~clk;
   end

integer i;

initial
begin

    writeEn <= 1;
    for(i=0; i<RAM_DEPTH; i=i+1) //write 2i+1 in index i
    begin
        @(negedge clk)
        begin
            addr <= i;
            din <= 2*i+1;
        end
        @(posedge clk)
        begin
        end
    end

    writeEn <= 0;
    read <= 1;

    for(i=0; i<RAM_DEPTH; i=i+1) //read 2i+1 from index i
    begin
        @(negedge clk)
        begin
            addr <= i;
        end
        @(posedge clk) #1 $display("index %d = %d" , i, s0.Dout);
        

    end

end
endmodule