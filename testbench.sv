// Code your testbench here
// or browse Examples


	import uvm_pkg::*;
  	`include "uvm_macros.svh"
	`include "mem_config.sv"

class packet extends uvm_sequence_item;

 	rand bit rd_wr;

	rand bit [7:0] wr_data;
	rand bit reset;
   	rand bit [7:0] addr;

	bit [7:0] rd_data;

	
	`uvm_object_utils_begin(packet)
	`uvm_field_int(rd_wr, UVM_DEFAULT)
	`uvm_field_int(wr_data, UVM_DEFAULT)
	`uvm_field_int(reset, UVM_DEFAULT)
	`uvm_field_int(addr, UVM_DEFAULT)
	`uvm_field_int(rd_data, UVM_DEFAULT)
	`uvm_object_utils_end

	function new(string name = "packet");
		super.new(name);
	endfunction
  
  constraint rw { rd_wr dist {1:=40, 0:=60};}
	
 endclass

class derived_packet extends packet;

  `uvm_object_utils(derived_packet)

  function new (string name = "derived_packet");
    super.new(name);
  endfunction : new

  constraint rw { rd_wr dist {1:=30, 0:=70};}

endclass



 class sequence1 extends uvm_sequence #(packet);

	packet item;
    int count = 0;

   `uvm_object_utils(sequence1)

   function new(string name = "sequence1");
		super.new(name);
	endfunction	

	virtual task body();
		`uvm_info(get_type_name(), "Executing sequence", UVM_LOW)	
                   
      for (int i=0; i<=255;i++)begin
          `uvm_info(get_type_name(), "Executing sequence", UVM_LOW)
        `uvm_do_with(item, {item.rd_wr == 1; item.addr == i;})
        count++;
		end
                       
      for (int i=0; i<=255;i++)begin
          `uvm_info(get_type_name(), "Executing sequence", UVM_LOW)
          `uvm_do_with(item, {item.rd_wr ==0; item.wr_data == addr; item.addr == i;})
        count++;
		end
                         
      for (int i=0; i<=255;i++)begin
          `uvm_info(get_type_name(), "Executing sequence", UVM_LOW)
          `uvm_do_with(item, {item.rd_wr ==1; item.addr == i;})
        count++;
		end
        #20;       

	endtask                   

 endclass

class derived_seq extends sequence1;

  `uvm_object_utils(derived_seq)

  function new(string name="derived_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    
    `uvm_do_with(item, {item.rd_wr ==0;})
   
    `uvm_do_with(item, {item.rd_wr ==1;})
    
  endtask
  
endclass


 class sequencer extends uvm_sequencer #(packet);

	packet item;

	`uvm_component_utils(sequencer)
	
   function new(string name = "sequencer", uvm_component parent = null);
		super.new(name,parent);
	endfunction

 endclass



 class driver extends uvm_driver #(packet);

	packet item;

	virtual intf vif;

	`uvm_component_utils(driver)

   function new(string name = "driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		//if(!uvm_config_db #(virtual intf)::get(this,"","vif",vif)) 
			//`uvm_error("NOVIF", {"virtual interface must be set for:", get_full_name(), ".vif"})	
      

    
      
	endfunction

	task run_phase(uvm_phase phase);
      wait(vif.reset1 == 1'b1);
      wait(vif.reset1 == 1'b0);
      
        forever begin

		  seq_item_port.get_next_item(item);
          @(posedge vif.clk);
          vif.rd_wr1 = item.rd_wr;
          if(item.rd_wr == 0)vif.wr_data1 = item.wr_data;
		  vif.addr1 = item.addr;
		  seq_item_port.item_done();
        end
	endtask

	
 endclass
      

 class monitor extends uvm_monitor;

	packet item;

    real cov;
	virtual intf vif;
    bit enable_coverage;
   
    event cov_transaction;

	`uvm_component_utils_begin(monitor)
   `uvm_field_int(enable_coverage, UVM_ALL_ON);
   `uvm_component_utils_end
   
	uvm_analysis_port #(packet) item_collected_port;

   covergroup cov_trans;
    rw : coverpoint vif.rd_wr1 { bins read = { 1 };
                            bins write = { 0 };
                           }
    rst : coverpoint vif.reset1;
    adr : coverpoint vif.addr1 { bins low = {[0:70]};
                            bins mid = {[71:160]};
                            bins high = {[161:255]};
                         }
    read : coverpoint vif.rd_data1;
    write : coverpoint vif.wr_data1; 
  endgroup
   
   function new(string name="monitor", uvm_component parent = null);
		super.new(name,parent);
     	cov_trans = new ();
		item_collected_port = new("item_collected_port",this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
                 
	 	//if (!uvm_config_db #(virtual intf)::get(this, get_full_name(),"vif", vif))
      		//`uvm_error("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})
      
	endfunction

	task run_phase(uvm_phase phase);
                
          wait(vif.reset1 == 1'b1);
          wait(vif.reset1 == 1'b0);
		forever begin

          item = packet::type_id::create("item",this);

          @(vif.cb);
          item.rd_wr = vif.cb.rd_wr1;
        item.wr_data = vif.cb.wr_data1;
        item.rd_data = vif.cb.rd_data1;
		item.reset = vif.cb.reset1;
		item.addr = vif.cb.addr1;         
                    
          if (enable_coverage)
				perform_coverage();
          
	      item_collected_port.write(item);
		end
	endtask
      
   virtual protected function void perform_coverage();
     cov_trans.sample();
	endfunction: perform_coverage
     
    function void extract_phase(uvm_phase phase);
      cov = cov_trans.get_coverage();
   endfunction  

   function void report_phase(uvm_phase phase);
     `uvm_info(get_full_name(),$sformatf("Coverage is %f",cov),UVM_MEDIUM); 
   endfunction

 endclass      

      

 class scoreboard extends uvm_scoreboard;

	packet q[$];
	logic [7:0] ref_item[255:0]; 
    int i = 0;

	uvm_analysis_imp #(packet, scoreboard) item_collected_export;
	
	`uvm_component_utils(scoreboard)

   function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		item_collected_export = new("item_collected_export", this);
		foreach(ref_item[i]) ref_item[i] = 8'hFF;
	endfunction

	virtual function void write(packet item);
		q.push_back(item);
	endfunction

	virtual task run_phase(uvm_phase phase);		
			
		forever begin
			packet item;
			wait(q.size()>0);
			item = q.pop_front();
			if(item.reset == 0 && item.rd_wr == 1) begin
            			if(ref_item[item.addr] == item.rd_data) begin
					`uvm_info(get_type_name(),$sformatf("-----Read data Match-----"), UVM_LOW)
					`uvm_info(get_type_name(),$sformatf("Addr:%0h",item.addr), UVM_LOW)
					`uvm_info(get_type_name(), $sformatf("Expected data:%0h  Actual Data:%0h",ref_item[item.addr], item.rd_data), UVM_LOW)
					`uvm_info(get_type_name(), "--------------------------------------", UVM_LOW)
				end
            			else begin
					`uvm_error(get_type_name(),$sformatf("-----Read data Mismatch-----"))
					`uvm_info(get_type_name(),$sformatf("Addr:%0h",item.addr), UVM_LOW)
					`uvm_info(get_type_name(), $sformatf("Expected data:%0h  Actual Data:%0h",ref_item[item.addr], item.rd_data), UVM_LOW)
					`uvm_info(get_type_name(), "--------------------------------------", UVM_LOW)
				end
          		end
          		else if(item.reset == 0 && item.rd_wr == 0)begin
            			ref_item[item.addr] = item.wr_data;
				`uvm_info(get_type_name(),$sformatf("Addr:%0h",item.addr), UVM_LOW)
				`uvm_info(get_type_name(), $sformatf("Write data:%0h", item.wr_data), UVM_LOW)
          		end
          		else if (item.reset == 1)begin
                  for(int i=0; i<=5; i++) begin
              				ref_item[i] = 8'hff;
					`uvm_info(get_type_name(), "Reset", UVM_LOW)
                                    					    
            			end
          		end 
		end
	endtask

 endclass
      


 class agent extends uvm_agent;

   	mem_config i_cfg;
	monitor i_monitor;
	sequencer i_sequencer;
	driver i_driver;
   
	`uvm_component_utils_begin(agent)
   `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON);
   `uvm_component_utils_end

   
   function new(string name="agent", uvm_component parent = null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
      
      if (!uvm_config_db #(mem_config)::get(this, "", "mem_config", i_cfg))
        `uvm_error(get_type_name(), "mem_config not found")
                   
                 
        i_monitor = monitor::type_id::create("i_monitor",this);
      //if(get_is_active() == UVM_ACTIVE) begin
      if(i_cfg.is_active == UVM_ACTIVE) begin
			i_sequencer= sequencer::type_id::create("i_sequencer",this);		
			i_driver = driver::type_id::create("i_driver",this);
		end
      i_driver.vif = i_cfg.vif;
      i_monitor.vif = i_cfg.vif;
	endfunction

	function void connect_phase(uvm_phase phase);
      //if(get_is_active() == UVM_ACTIVE)
		if(i_cfg.is_active == UVM_ACTIVE) 	i_driver.seq_item_port.connect(i_sequencer.seq_item_export);
	endfunction

 endclass
      

 class env extends uvm_env;

	scoreboard i_scoreboard;
	agent i_agent;
  

	`uvm_component_utils(env)

   function new(string name="env", uvm_component parent = null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
      
      
		i_agent = agent::type_id::create("i_agent",this);
		i_scoreboard = scoreboard::type_id::create("i_scoreboard",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		i_agent.i_monitor.item_collected_port.connect(i_scoreboard.item_collected_export);
	endfunction

 endclass
      

 class test extends uvm_test;

	`uvm_component_utils(test)

	sequence1 i_seq;
	env i_env;

   function new(string name = "test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
      uvm_config_db #(uvm_bitstream_t) :: set (this, "i_env.i_agent.i_monitor", "enable_coverage", 1);
      
		super.build_phase(phase);
		i_seq = sequence1::type_id::create("i_seq");
		i_env = env::type_id::create("i_env", this);
	endfunction	

   virtual task run_phase(uvm_phase phase);
      
		phase.raise_objection(this);
        fork
          begin
		    i_seq.start(i_env.i_agent.i_sequencer);
          end
          begin
          #20000;
          end
        join_any
		phase.drop_objection(this);

	endtask
   
   virtual function void end_of_elaboration_phase (uvm_phase phase);
		uvm_top.print_topology;
	endfunction  
   
   function void check_phase(uvm_phase phase);
    check_config_usage();
  endfunction

 endclass

class derived_test extends test;

  `uvm_component_utils(derived_test)
 
  function new(string name="derived_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
 virtual function void build_phase(uvm_phase phase);
    packet::type_id::set_type_override(derived_packet::get_type()); 
    uvm_config_db #(uvm_bitstream_t) :: set (this, "i_env.i_agent.i_monitor", "enable_coverage", 1);
   super.build_phase(phase);       
   i_seq = derived_seq::type_id::create("i_seq");
  endfunction

  virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      
		phase.raise_objection(this);
		i_seq.start(i_env.i_agent.i_sequencer);
		phase.drop_objection(this);

	endtask
  
   
endclass       

 	`timescale 1ns/100ps 

 module tb;
   
   logic clk = 0;
   logic rst;
   
   intf vif (clk, rst);
   
   memory dut(vif, clk);
   
   mem_config i_cfg;
   
    always #10 clk = ~clk;

	initial begin
     // uvm_config_db #(virtual intf)::set(uvm_root::get(),"*","vif",vif);
      	
      	$dumpfile("dump.vcd");
        $dumpvars;
		
	end

    initial begin
      
      rst = 1;
      #20
      rst = 0;
    end

	initial begin
      
      i_cfg = new("i_cfg");
      if ( !i_cfg.randomize() )
      `uvm_error("tb", "Failed to randomize top-level configuration object" )
	i_cfg.vif             = vif;
    i_cfg.is_active       = UVM_ACTIVE;      
    i_cfg.has_functional_coverage   = 1;               
    i_cfg.has_scoreboard = 1;               


      uvm_config_db #(mem_config)::set(null, "*", "mem_config", i_cfg);

      run_test("test");
      
	end

 endmodule
