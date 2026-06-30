class uart_LCR_reg extends uvm_reg;
  `uvm_object_utils(uart_LCR_reg)

  uvm_reg_field      rsvd;
  rand uvm_reg_field bge;
  rand uvm_reg_field eps;
  rand uvm_reg_field pen;
  rand uvm_reg_field stb;
  rand uvm_reg_field wls;

  function new(string name="uart_LCR_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    // Create object instance for each field
    rsvd       = uvm_reg_field::type_id::create("rsvd");
    bge   = uvm_reg_field::type_id::create("bge");
    eps   = uvm_reg_field::type_id::create("eps");
    pen   = uvm_reg_field::type_id::create("pen");
    stb   = uvm_reg_field::type_id::create("stb");
    wls   = uvm_reg_field::type_id::create("wls");

    // Configure each field
    rsvd.configure  (this,26,6,"RO",1'b0,31'b0,1,1,1);
    bge.configure   (this,1 ,5,"RW",1'b0, 1'b0,1,1,1);
    eps.configure   (this,1 ,4,"RW",1'b0, 1'b0,1,1,1);
    pen.configure   (this,1 ,3,"RW",1'b0, 1'b0,1,1,1);
    stb.configure   (this,1 ,2,"RW",1'b0, 1'b0,1,1,1);
    wls.configure   (this,2 ,0,"RW",1'b0, 2'b11,1,1,1);
  endfunction

endclass

