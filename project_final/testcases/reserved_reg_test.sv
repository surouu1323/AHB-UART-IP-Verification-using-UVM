class reserved_reg_test extends uart_base_test;
  `uvm_component_utils(reserved_reg_test)

  ahb_reserved_sequence  ahb_reserved_seq;
    logic [10:0] i;

  function new(string name="reserved_reg_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new



  virtual task run_phase(uvm_phase phase); 
    //#100ns; ahb_vif.HRESETN=0;
    uvm_status_e status;
    logic [31:0] data;

    phase.raise_objection(this);

    #10ns;
    wait(ahb_vif.HRESETn == 1'b1);
    @(posedge ahb_vif.HCLK);
    `uvm_info(get_type_name(), "Reset released and is stable", UVM_LOW)

    fork
        reg_chk();
//        hresp_chk();    
    join_any
    disable fork; 

    phase.drop_objection(this);
  endtask

    virtual task reg_chk();
        for (i = 10'h020; i< 10'h3FF; i = i +4) begin
	        ahb_reserved_chk(i);
		end
    endtask



    virtual task ahb_reserved_chk(input logic [31:0] addr);
        ahb_reserved_seq = new();
        ahb_reserved_seq.addr = addr;
        ahb_reserved_seq.start(env.ahb_agt.sequencer);
    endtask 
endclass
