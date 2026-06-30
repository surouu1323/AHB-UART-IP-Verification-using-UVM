class fifo_rx_test extends uart_base_test;
  `uvm_component_utils(fifo_rx_test)

  function new(string name="fifo_rx_test", uvm_component parent);
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
		int i = 1;
        
        regmodel.MDR.write (status, 32'h0 );
        regmodel.DLL.write (status, 32'h36);
        regmodel.DLH.write (status, 32'h00);
        
		regmodel.IER.write (status, 32'hC);
		
		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("DUT", $sformatf("set rx receive data "), UVM_LOW);
        regmodel.LCR.write (status, 32'h23);

		/*---------------------------------------------------------------------------------------*/

		`uvm_info("TEST_CASE", $sformatf("check empty fifo"), UVM_LOW);	
		uart_write($urandom_range(0,8'hff));	
		
	    regmodel.FSR.read(status,rdata);
		if(rdata[2] == 'b0 && rdata[3] == 'b1)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("rx_empty_status = 0x%b, rx_full_status = 0x%b, exp empty = 1, full = 0",rdata[3],rdata[2]));
		end
		
		if(dut_int_vif.interrupt == 1)begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp empty = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST CASE", $sformatf("write 15 data -> check state empty = 0, full = 0"), UVM_LOW);
        repeat(15)begin
			
		    `uvm_info("TEST_CASE", $sformatf("write %0d data", i), UVM_LOW);			i++;
			uart_write($urandom_range(0,8'hff));	
			
	    	regmodel.FSR.read(status,rdata);
			if(rdata[2] == 'b0 && rdata[3] == 'b0)begin
			    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
			end
			else begin
			    `uvm_error("fifo_state", $sformatf("rx_empty_status = 0x%b, rx_full_status = 0x%b, exp empty = 0, full = 0",rdata[3],rdata[2]));
			end

			if(dut_int_vif.interrupt == 0)begin
			    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
			end
			else begin
			    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp empty = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
			end
        end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST_CASE", $sformatf("write 16th data -> check state empty = 0, full = 1"), UVM_LOW);
		`uvm_info("fifo_state", $sformatf("write %0d data", i), UVM_LOW);			i++;
		uart_write($urandom_range(0,8'hff));	
			
	    regmodel.FSR.read(status,rdata);
		if(rdata[2] == 'b1 && rdata[3] == 'b0)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("rx_empty_status = 0x%b, rx_full_status = 0x%b, exp empty = 0, full = 1",rdata[3],rdata[2]));
		end

		if(dut_int_vif.interrupt == 1)begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp empty = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end


		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST_CASE", $sformatf("write more data -> check state empty = 0, full = 1"), UVM_LOW);
        repeat(16)begin
			
		    `uvm_info("fifo_state", $sformatf("write %0d data", i), UVM_LOW);			i++;
			uart_write($urandom_range(0,8'hff));	
			
	    	regmodel.FSR.read(status,rdata);
			if(rdata[2] == 'b1 && rdata[3] == 'b0)begin
			    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
			end
			else begin
			    `uvm_error("fifo_state", $sformatf("rx_empty_status = 0x%b, rx_full_status = 0x%b, exp empty = 0, full = 1",rdata[3],rdata[2]));
			end
        end

		/*---------------------------------------------------------------------------------------*/
		repeat(15)begin
			regmodel.RBR.read(status,rdata);
    	    regmodel.FSR.read(status,rdata);
			if(rdata[2] == 'b0 && rdata[3] == 'b0)begin
				`uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
			end
			else begin
			    `uvm_error("fifo_state", $sformatf("rx_empty != 0, rx_empty_status = 0x%b, rx_full_status = 0x%b, exp empty = 1, full = 0",rdata[3],rdata[2]));
			end
		end

		if(dut_int_vif.interrupt == 0)begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp empty = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end


		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST_CASE", $sformatf("check state empty = 1, full = 0"), UVM_LOW);
		regmodel.RBR.read(status,rdata);
        regmodel.FSR.read(status,rdata);
		if(rdata[2] == 'b0 && rdata[3] == 'b1)begin
			`uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("rx_empty != 0, rx_empty_status = 0x%b, rx_full_status = 0x%b, exp empty = 1, full = 0",rdata[3],rdata[2]));
		end

		if(dut_int_vif.interrupt == 1)begin
		    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
		end
		else begin
		    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp empty = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
		end
  endtask

endclass
