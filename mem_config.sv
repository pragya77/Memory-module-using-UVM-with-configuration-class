class mem_config extends uvm_object;
  
  `uvm_object_utils(mem_config)
  
  function new(string name ="mem_config");
    super.new(name);
  endfunction  
  
  virtual intf vif;
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  bit has_functional_coverage = 0;

  bit has_scoreboard = 0;
  
endclass  
