module sync_ram #(
  parameter ADDR_WIDTH=8             //width of addresse bus
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
  reg [31:0] dout_r;

  assign Dout = (!read && !writeEn) ?  32'bz : dout_r;

  always @(posedge clk) begin //WRITE
      if (writeEn) begin
          mem[addr] <= Din;
      end
  end

  always @ (posedge clk) begin //READ
    if (!writeEn && read) begin
      dout_r <= mem[addr];
    end
  end


endmodule