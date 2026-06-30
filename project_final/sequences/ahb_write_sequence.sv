class ahb_write_sequence extends uvm_sequence #(ahb_transaction);
  `uvm_object_utils(ahb_write_sequence)


    logic [9:0] addr;
    logic [31:0] data;

  function new(string name="ahb_write_sequence");
    super.new(name);
  endfunction

  virtual task body();
      req = ahb_transaction::type_id::create("req");

	start_item(req);
     
      assert(req.randomize() with {addr == local::addr;
                            data        == local::data;
                            xact_type   == ahb_transaction::WRITE;
                            burst_type  == ahb_transaction::SINGLE;
                            xfer_size   == ahb_transaction::SIZE_32BIT;});
       `uvm_info(get_type_name(),$sformatf("Send req to driver: \n %s",req.sprint()),UVM_HIGH);
      finish_item(req);
      get_response(rsp);
   // #1us;
//    `uvm_info(get_type_name(),$sformatf("Recevied rsp to driver: \n %s",rsp.sprint()),UVM_LOW);
  endtask

endclass
