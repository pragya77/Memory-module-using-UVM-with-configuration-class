// Code your design here

`timescale 1ns/100ps 

interface intf(input clk, input reset1);

	logic rd_wr1;
  logic [7:0] wr_data1;
  logic [7:0] rd_data1;
  logic [7:0] addr1;
  
  clocking cb @(posedge clk);
    default input #0ns;
    inout rd_data1;
    inout wr_data1;
    inout rd_wr1;
    inout addr1;
    inout reset1;
  endclocking  
  
  
   property P1;
    @(posedge clk)
     !rd_wr1 |-> (wr_data1 == addr1); 
  endproperty  
  
  A1: assert property (P1) else 
    `uvm_error("A1", "Error in property 1 assertion")
    
  
endinterface


module memory(intf vif, input clk);
  logic [7:0] register [255:0];
  always_ff @(posedge clk)
	begin
      if(vif.reset1)begin
        for( int i = 0; i<=255; i++) register[i] <= 8'hff;
      end
      else if(vif.rd_wr1 == 1 && vif.reset1 == 0) vif.rd_data1 <= register[vif.addr1]; 
      else if(vif.rd_wr1 == 0 && vif.reset1 == 0) register[vif.addr1] <= vif.wr_data1;
	end
 endmodule
