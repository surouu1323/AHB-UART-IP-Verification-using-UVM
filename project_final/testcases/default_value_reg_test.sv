class default_value_reg_test extends uart_base_test;
  `uvm_component_utils(default_value_reg_test)

  function new(string name="default_value_reg_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual task run_phase(uvm_phase phase); 

    uvm_status_e status;
    phase.raise_objection(this);

    #1ns; 
	ahb_vif.HRESETn=0;
	regmodel.reset();

    #10ns;
    wait(ahb_vif.HRESETn == 1'b1);
    repeat(5) @(posedge ahb_vif.HCLK);
    `uvm_info(get_type_name(), "Reset released and is stable", UVM_LOW)

    regmodel.MDR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    regmodel.DLL.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    regmodel.DLH.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    regmodel.LCR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    regmodel.IER.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    regmodel.FSR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    regmodel.TBR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    regmodel.RBR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    

    phase.drop_objection(this);
  endtask

endclass
