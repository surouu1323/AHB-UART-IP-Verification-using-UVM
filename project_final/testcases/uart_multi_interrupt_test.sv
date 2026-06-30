class uart_multi_interrupt_test extends uart_base_test;
  `uvm_component_utils(uart_multi_interrupt_test)
  
	uvm_event done_tx_transfer_ev;
  uvm_event done_rx_transfer_ev;

  // Type definitions for easier access to enums
  typedef uart_configuration::baud_rate_enum   baud_rate_enum;
  typedef uart_configuration::parity_mode_enum parity_mode_enum;
  typedef uart_configuration::stop_bit_enum    stop_bit_enum;
  typedef uart_configuration::data_width_enum  data_width_enum;
  typedef uart_configuration::sampling_mode_enum  sampling_mode_enum;

  // Define lists of all possible configurations with explicit scope
  baud_rate_enum   baud_list  [7] = '{uart_configuration::B_2400, 
                                      uart_configuration::B_4800, 
                                      uart_configuration::B_9600, 
                                      uart_configuration::B_19200, 
                                      uart_configuration::B_38400, 
                                      uart_configuration::B_76800, 
                                      uart_configuration::B_115200};
                                      
  parity_mode_enum parity_list[3] = '{uart_configuration::ODD, 
                                      uart_configuration::EVEN, 
                                      uart_configuration::NONE};
                                      
  stop_bit_enum    stop_list  [2] = '{uart_configuration::STOP_1BIT, 
                                      uart_configuration::STOP_2BIT};
                                      
  data_width_enum  width_list [4] = '{uart_configuration::D_5b, 
                                      uart_configuration::D_6b, 
                                      uart_configuration::D_7b, 
                                      uart_configuration::D_8b};

  sampling_mode_enum  sampling_list [2] = '{uart_configuration::M_16x, 
                                      		uart_configuration::M_13x};

  function new(string name="uart_multi_interrupt_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

      if(uvm_config_db#(uart_configuration)::get(this, "env*", "uart_cfg", uart_cfg)) begin
        uart_cfg.baud_rate    = uart_configuration::B_115200;
        uart_cfg.parity_mode  = uart_configuration::ODD;
        uart_cfg.data_width   = uart_configuration::D_8b;
        uart_cfg.stop_bit     = uart_configuration::STOP_1BIT;
      end 
      
    done_tx_transfer_ev = uvm_event_pool::get_global("DONE_TX_TRANSFER");
    done_rx_transfer_ev = uvm_event_pool::get_global("DONE_RX_TRANSFER");
    endfunction



  virtual task run_phase(uvm_phase phase); 
    //#100ns; ahb_vif.HRESETN=0;
    phase.raise_objection(this);

    #10ns;
	regmodel.reset();
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
    bit[31:0] rdata;
	bit full_exp;
	bit empty_exp;
	int i = 1;

	/*-------Base interrupt check-----*/
	
	reg_cfg();
	regmodel.LCR.bge.set('b0);	regmodel.LCR.update(status);

	`uvm_info("TEST CASE", $sformatf("Base Interrupt Check"), UVM_LOW);
	regmodel.IER.write (status, 32'hff);

	int_chk('b1);
	tx_fifo_chk('b0, 'b1);
	rx_fifo_chk('b0, 'b1);
	parity_chk('b0);



	/*-------Tx empty clear -----*/
	`uvm_info("TEST CASE", $sformatf("Tx empty clear"), UVM_LOW);

    repeat(2) regmodel.TBR.write (status, $urandom, UVM_FRONTDOOR);

	`uvm_info("TX", $sformatf("check state full = 0, empty = 0"), UVM_LOW);

	int_chk('b1);
	tx_fifo_chk('b0, 'b0);
	rx_fifo_chk('b0, 'b1);
	parity_chk('b0);


	/*-------Tx full set  -----*/
	`uvm_info("TEST CASE", $sformatf("Tx full set"), UVM_LOW);

    repeat(15) regmodel.TBR.write (status, $urandom, UVM_FRONTDOOR);
	//uart_write($urandom_range(0,8'hff));	
	`uvm_info("TX", $sformatf("check state full = 1, empty = 0"), UVM_LOW);

	int_chk('b1);
	tx_fifo_chk('b1, 'b0);
	rx_fifo_chk('b0, 'b1);
	parity_chk('b0);

	/*-------Tx empty set  -----*/
	`uvm_info("TEST CASE", $sformatf("Tx empty set"), UVM_LOW);


	regmodel.LCR.bge.set('b1);		regmodel.LCR.update(status);
	repeat(17)begin
		done_rx_transfer_ev.wait_trigger(); 
		done_rx_transfer_ev.reset();

	end

	`uvm_info("TX", $sformatf("check state full = 0, empty = 1"), UVM_LOW);

	int_chk('b1);
	tx_fifo_chk('b0, 'b1);
	rx_fifo_chk('b0, 'b1);
	parity_chk('b0);


	/*-------Rx empty clear -----*/
	`uvm_info("TEST CASE", $sformatf("Rx empty clear"), UVM_LOW);

    //regmodel.TBR.write (status, $urandom, UVM_FRONTDOOR);
	
	repeat(2)	begin
		uart_write($urandom_range(0,8'hff));	

		done_tx_transfer_ev.wait_ptrigger(); 
		done_tx_transfer_ev.reset();
	end
	`uvm_info("RX", $sformatf("check state full = 0, empty = 0"), UVM_LOW);

	int_chk('b1);
	tx_fifo_chk('b0, 'b1);
	rx_fifo_chk('b0, 'b0);
	parity_chk('b0);


	/*-------rx full set -----*/
	`uvm_info("TEST CASE", $sformatf("rx full set"), UVM_LOW);

    //regmodel.tbr.write (status, $urandom, uvm_frontdoor);
	
	repeat(15)	begin
		uart_write($urandom_range(0,8'hff));	

		done_tx_transfer_ev.wait_ptrigger(); 
		done_tx_transfer_ev.reset();
	end
	`uvm_info("rx", $sformatf("check state full = 1, empty = 0"), UVM_LOW);

	int_chk('b1);
	tx_fifo_chk('b0, 'b1);
	rx_fifo_chk('b1, 'b0);
	parity_chk('b0);


	/*-------rx empty set -----*/
	`uvm_info("TEST CASE", $sformatf("Rx empty set"), UVM_LOW);

	repeat(16)		regmodel.RBR.read(status,rdata);

	`uvm_info("rx", $sformatf("check state full = 0, empty = 0"), UVM_LOW);

	int_chk('b1);
	tx_fifo_chk('b0, 'b1);
	rx_fifo_chk('b0, 'b1);
	parity_chk('b0);

	/*-------Parity Err inj -----*/
	`uvm_info("TEST CASE", $sformatf("Parity Err inj"), UVM_LOW);

	uart_cfg.parity_mode  = uart_configuration::EVEN;
	uart_write($urandom_range(0,8'hff));	
	done_tx_transfer_ev.wait_trigger(); 
	done_tx_transfer_ev.reset();
	uart_cfg.parity_mode  = uart_configuration::ODD;


	int_chk('b1);
	tx_fifo_chk('b0, 'b1);
	rx_fifo_chk('b0, 'b0);
	parity_chk('b1);


	/*------parity err clear -----*/
	`uvm_info("TEST CASE", $sformatf("parity err clear"), UVM_LOW);

	regmodel.FSR.parrity_error_status.set('b1);	regmodel.FSR.update(status);

	int_chk('b1);
	tx_fifo_chk('b0, 'b1);
	rx_fifo_chk('b0, 'b0);
	parity_chk('b0);


	endtask

	virtual task int_chk(bit exp);

		if(dut_int_vif.interrupt == exp)begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end
	endtask

	virtual task parity_chk(bit exp);
    	uvm_status_e status;
		bit [31:0] rdata;
        regmodel.FSR.read(status,rdata);
		if(exp == rdata[4])begin
		    `uvm_info("parity_err_state", $sformatf("parity_err_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("parity_err_state", $sformatf("status = 0x%b, expected = 0x%b",rdata[5],exp));
		end

	endtask

	virtual task tx_fifo_chk(bit full_exp, bit empty_exp);
    	uvm_status_e status;
		bit [31:0] rdata;
        regmodel.FSR.read(status,rdata);
		if(empty_exp == rdata[1] && rdata[0] == full_exp)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[1], empty_exp ,rdata[0], full_exp));
		end

	endtask


	virtual task rx_fifo_chk(bit full_exp, bit empty_exp);
    	uvm_status_e status;
		bit [31:0] rdata;
        regmodel.FSR.read(status,rdata);
		if(empty_exp == rdata[3] && rdata[2] == full_exp)begin
		    `uvm_info("fifo_state", $sformatf("rx_fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("rx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[3], empty_exp ,rdata[2], full_exp));
		end

	endtask

endclass
