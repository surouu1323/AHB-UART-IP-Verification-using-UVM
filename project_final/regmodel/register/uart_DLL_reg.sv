class uart_DLL_reg extends uvm_reg;
  `uvm_object_utils(uart_DLL_reg)

  uvm_reg_field      rsvd;
  rand uvm_reg_field dll;

  function new(string name="uart_DLL_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    // Create object instance for each field
    rsvd       = uvm_reg_field::type_id::create("rsvd");
    dll        = uvm_reg_field::type_id::create("dll");

    // Configure each field
    rsvd.configure   (this,24,8,"RO",1'b0,24'b0,1,1,1);
    dll.configure    (this,8 ,0,"RW",1'b0, 8'b0,1,1,1);
  endfunction

endclass

