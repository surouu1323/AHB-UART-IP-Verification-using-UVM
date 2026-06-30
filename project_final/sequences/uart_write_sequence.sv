class uart_write_sequence extends uvm_sequence #(uart_transaction);
  `uvm_object_utils(uart_write_sequence)

  logic [8:0] data;
  logic direction;

  function new(string name="uart_write_sequence");
    super.new(name);
  endfunction

  virtual task body();
      req      = uart_transaction::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {direction     == uart_transaction::WRITE;
                                      data          == local::data;})
        else `uvm_error("RAND_FAILED","uart write randomize failed");
      `uvm_info(get_type_name(),$sformatf("Send req to driver: \n %s",req.sprint()),UVM_HIGH);
      finish_item(req);

    // get_response(rsp);
    //#1us;
    //`uvm_info(get_type_name(),$sformatf("Recevied rsp to driver: \n %s",rsp.sprint()),UVM_LOW);
  endtask

endclass
