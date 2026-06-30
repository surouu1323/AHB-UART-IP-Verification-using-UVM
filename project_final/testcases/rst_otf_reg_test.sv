class rst_otf_reg_test extends uart_base_test;
  `uvm_component_utils(rst_otf_reg_test)

  function new(string name="rst_otf_reg_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual task run_phase(uvm_phase phase); 
    //#100ns; ahb_vif.HRESETN=0;
    phase.raise_objection(this);

    #10ns;
    wait(ahb_vif.HRESETn == 1'b1);
    repeat(5) @(posedge ahb_vif.HCLK);
    `uvm_info(get_type_name(), "Reset released and is stable", UVM_LOW)

    fork
        rst_trigger();
        reg_write();
    join_any
    phase.drop_objection(this);
   endtask

    virtual task rst_trigger(); 
        forever begin
            wait(ahb_vif.HTRANS == 2'h2 && ahb_vif.HWRITE == 1'b1)
            @(posedge ahb_vif.HCLK);
            ahb_vif.HRESETn = 1'b0;
            @(posedge ahb_vif.HCLK);
            ahb_vif.HRESETn = 1'b1;
            wait(ahb_vif.HRESETn == 1'b1);
            `uvm_info(get_type_name(), "Reset released and is stable", UVM_LOW)
        end

    endtask

    virtual task reg_write();
    uvm_reg_data_t write_val;
    uvm_status_e status;
    
    write_val = $urandom();
    regmodel.MDR.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.MDR.reset ();
    regmodel.MDR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.DLL.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.DLL.reset ();
    regmodel.DLL.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.DLH.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.DLH.reset ();
    regmodel.DLH.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.LCR.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.LCR.reset ();
    regmodel.LCR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.IER.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.IER.reset ();
    regmodel.IER.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.FSR.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.FSR.reset ();
    regmodel.FSR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.TBR.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.TBR.reset ();
    regmodel.TBR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

    write_val = $urandom();
    regmodel.RBR.write (status, write_val, UVM_FRONTDOOR);
    wait(ahb_vif.HRESETn == 1'b1);
    regmodel.RBR.reset ();
    regmodel.RBR.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

  endtask

endclass
