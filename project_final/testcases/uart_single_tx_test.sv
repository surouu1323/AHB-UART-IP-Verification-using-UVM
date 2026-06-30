class uart_single_tx_test extends uart_base_test;
  `uvm_component_utils(uart_single_tx_test)

  function new(string name="uart_single_tx_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

      if(uvm_config_db#(uart_configuration)::get(this, "env*", "uart_cfg", uart_cfg)) begin
        uart_cfg.baud_rate    = uart_configuration::B_115200;
        uart_cfg.parity_mode  = uart_configuration::NONE;
        uart_cfg.data_width   = uart_configuration::D_8b;
        uart_cfg.stop_bit     = uart_configuration::STOP_1BIT;
      end 
      
    endfunction

  virtual task run_phase(uvm_phase phase); 
    //#100ns; ahb_vif.HRESETN=0;
    phase.raise_objection(this);

    #10ns;
    wait(ahb_vif.HRESETn == 1'b1);
    repeat(5) @(posedge ahb_vif.HCLK);
    `uvm_info(get_type_name(), "Reset released and is stable", UVM_LOW)

    fork
        reg_write();
    join_any
    #300us
    phase.drop_objection(this);
   endtask


    virtual task reg_write();
        uvm_status_e status;
        
        regmodel.MDR.write (status, 32'h0, UVM_FRONTDOOR);
        regmodel.DLL.write (status, 32'h36, UVM_FRONTDOOR);
        regmodel.DLH.write (status, 32'h00, UVM_FRONTDOOR);
        regmodel.LCR.write (status, 32'h23, UVM_FRONTDOOR);
        regmodel.TBR.write (status, 32'h55, UVM_FRONTDOOR);
  endtask

endclass
