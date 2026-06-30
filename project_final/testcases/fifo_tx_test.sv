class fifo_tx_test extends uart_base_test;
  `uvm_component_utils(fifo_tx_test)

	logic [7:0] ran;
	int tx_transfer_count;
  
	uvm_event done_tx_transfer_ev;
  uvm_event done_rx_transfer_ev;

  function new(string name="fifo_tx_test", uvm_component parent);
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
        
      //  regmodel.MDR.write (status, 32'h0 );
      //  regmodel.DLL.write (status, 32'h36);
      //  regmodel.DLH.write (status, 32'h00);

		regmodel.IER.write (status, 32'h3);

		/*---------------------------------------------------------------------------------------*/
        regmodel.FSR.read(status,rdata);
	    `uvm_info("TEST CASE", $sformatf("check state empty = 1, full = 0"), UVM_LOW);

		full_exp = 0; empty_exp = 1;
		if(empty_exp == rdata[1] && rdata[0] == full_exp)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[1], empty_exp ,rdata[0], full_exp));
		end
		if(dut_int_vif.interrupt == (full_exp | empty_exp))begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("fifo_state", $sformatf("write 1 data -> check state empty = 0, full = 0"), UVM_LOW);
       	ran = $urandom;
	   	`uvm_info("fifo_state", $sformatf("write %0d data: 0x%0h", i, ran), UVM_LOW);			i++;
       	regmodel.TBR.write (status, ran, UVM_FRONTDOOR);

	    regmodel.FSR.read(status,rdata);
		full_exp = 0; empty_exp = 1;
		if(empty_exp == rdata[1] && rdata[0] == full_exp)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[1], empty_exp ,rdata[0], full_exp));
		end
		if(dut_int_vif.interrupt == (full_exp | empty_exp))begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end


		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST CASE", $sformatf("write 14 data -> check state empty = 0, full = 0"), UVM_LOW);
        repeat(15)begin
			
		    `uvm_info("TEST_CASE", $sformatf("write %0d data", i), UVM_LOW);		
       		 ran = $urandom;
	   		 `uvm_info("fifo_state", $sformatf("write %0d data: 0x%0h", i, ran), UVM_LOW);			i++;
       		 regmodel.TBR.write (status, ran, UVM_FRONTDOOR);

		    regmodel.FSR.read(status,rdata);
			full_exp = 0; empty_exp = 0;
			if(empty_exp == rdata[1] && rdata[0] == full_exp)begin
			    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
			end
			else begin
			    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[1], empty_exp ,rdata[0], full_exp));
			end
			if(dut_int_vif.interrupt == (full_exp | empty_exp))begin
			    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
			end
			else begin
			    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
			end
		end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST_CASE", $sformatf("write 16th data -> check state empty = 0, full = 1"), UVM_LOW);
        ran = $urandom;
		`uvm_info("fifo_state", $sformatf("write %0d data: 0x%0h", i, ran), UVM_LOW);			i++;
        regmodel.TBR.write (status, ran, UVM_FRONTDOOR);
			
	    regmodel.FSR.read(status,rdata);
		full_exp = 1; empty_exp = 0;
		if(empty_exp == rdata[1] && rdata[0] == full_exp)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[1], empty_exp ,rdata[0], full_exp));
		end
		if(dut_int_vif.interrupt == (full_exp | empty_exp))begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST_CASE", $sformatf("write more data -> check state empty = 0, full = 1"), UVM_LOW);
        repeat(14)begin
			
        	ran = $urandom;
		    `uvm_info("fifo_state", $sformatf("write %0d data: 0x%0h", i, ran), UVM_LOW);			i++;
            regmodel.TBR.write (status, ran, UVM_FRONTDOOR);

		    regmodel.FSR.read(status,rdata);
			full_exp = 1; empty_exp = 0;
			if(empty_exp == rdata[1] && rdata[0] == full_exp)begin
			    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
			end
			else begin
			    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[1], empty_exp ,rdata[0], full_exp));
	        end
	
			if(dut_int_vif.interrupt == (full_exp | empty_exp))begin
			    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
			end
			else begin
			    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
			end

		end
		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("DUT", $sformatf("set tx transfer data "), UVM_LOW);
		reg_cfg();

		do begin
			// Wait for the monitor to trigger completion of the transfer sequence
		    done_rx_transfer_ev.wait_trigger();
			done_rx_transfer_ev.reset();
			tx_transfer_count++;	
        	regmodel.FSR.read(status,rdata);
		end while(rdata[1] == 0);

        regmodel.LCR.write (status, 32'h0);

		`uvm_info("DUT TX TRANSACTION", $sformatf("number of transactions == %0d", tx_transfer_count), UVM_LOW);

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST_CASE", $sformatf("check state empty = 1, full = 0"), UVM_LOW);

	    regmodel.FSR.read(status,rdata);
		full_exp = 0; empty_exp = 1;
		if(empty_exp == rdata[1] && rdata[0] == full_exp)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, expected = 0x%b, tx_full_status = 0x%b, expected = 0x%b",rdata[1], empty_exp ,rdata[0], full_exp));
		end
		if(dut_int_vif.interrupt == (full_exp | empty_exp))begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end
  endtask

endclass
