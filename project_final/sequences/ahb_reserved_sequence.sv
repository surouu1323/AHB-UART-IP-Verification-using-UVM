class ahb_reserved_sequence extends uvm_sequence #(ahb_transaction);
  `uvm_object_utils(ahb_reserved_sequence)


    logic [31:0] addr;

  function new(string name="ahb_reserved_sequence");
    super.new(name);
  endfunction

  virtual task body();
    write();    
    read();
  endtask

  virtual task read();
      req = ahb_transaction::type_id::create("req");
      rsp = ahb_transaction::type_id::create("rsp");
      start_item(req);
     
      assert(req.randomize() with {addr == local::addr;
                            data        == 32'h0;
                            xact_type   == ahb_transaction::READ;
                            burst_type  == ahb_transaction::SINGLE;
                            xfer_size   == ahb_transaction::SIZE_32BIT;});
       `uvm_info(get_type_name(),$sformatf("Send req to driver: \n %s",req.sprint()),UVM_HIGH);
      finish_item(req);
      get_response(rsp);
//      if(rsp.data != 32'hFFFF_FFFF)
//            `uvm_error(get_type_name(),$sformatf("Register data != 32'h0, addr: 32'h%h, data: 32'h%h", addr, rsp.data))
//      else  `uvm_info (get_type_name(),$sformatf("Register data  = 32'h0, addr: 32'h%h",addr),UVM_LOW)            
 
  endtask
  virtual task write();
      req = ahb_transaction::type_id::create("req");
      start_item(req);
     
      assert(req.randomize() with {addr == local::addr;
                            data        == 32'hFFFF_FFFF;
                            xact_type   == ahb_transaction::WRITE;
                            burst_type  == ahb_transaction::SINGLE;
                            xfer_size   == ahb_transaction::SIZE_32BIT;});
       `uvm_info(get_type_name(),$sformatf("Send req to driver: \n %s",req.sprint()),UVM_HIGH);
      finish_item(req);
      get_response(rsp);
  endtask

endclass
