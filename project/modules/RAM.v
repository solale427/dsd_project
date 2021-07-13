module sync_ram #(
  parameter ADDR_WIDTH=16             //width of addresse bus
)(
  input  [31:0] 	    Din,     //data to be written
  input  [(ADDR_WIDTH-1):0] addr,    //address for write/read operation
  input                     writeEn, //write enable signal
  input			    read,    //read enable signal
  input                     clk,     //clock signal
  output  [31:0]            Dout     //read data
);
  localparam RAM_DEPTH = 1 << ADDR_WIDTH;
  reg [31:0] mem [RAM_DEPTH-1:0];
  
  assign Dout = (read) ? mem[addr] : 32'bz;

  always @(posedge clk) begin //WRITE
      if (writeEn) begin
          mem[addr] <= Din;
      end
  end
  
endmodule