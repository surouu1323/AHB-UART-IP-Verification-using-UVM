class rw_reg_test extends uart_base_test;
  `uvm_component_utils(rw_reg_test)

  function new(string name="rw_reg_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual task run_phase(uvm_phase phase); 
    //#100ns; ahb_vif.HRESETN=0;
    uvm_status_e status;
    uvm_reg_data_t write_val, read_val;

    phase.raise_objection(this);

    #10ns;
    wait(ahb_vif.HRESETn == 1'b1);
    repeat(5) @(posedge ahb_vif.HCLK);
    `uvm_info(get_type_name(), "Reset released and is stable", UVM_LOW)


    write_val = $urandom();
    regmodel.MDR.write (status, write_val, UVM_FRONTDOOR);
    regmodel.MDR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.DLL.write (status, write_val, UVM_FRONTDOOR);
    regmodel.DLL.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.DLH.write (status, write_val, UVM_FRONTDOOR);
    regmodel.DLH.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.LCR.write (status, write_val, UVM_FRONTDOOR);
    regmodel.LCR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.IER.write (status, write_val, UVM_FRONTDOOR);
    regmodel.IER.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.FSR.write (status, write_val, UVM_FRONTDOOR);
    regmodel.FSR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.TBR.write (status, write_val, UVM_FRONTDOOR);
    regmodel.TBR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.RBR.write (status, write_val, UVM_FRONTDOOR);
    regmodel.RBR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);


    phase.drop_objection(this);
  endtask

endclass
