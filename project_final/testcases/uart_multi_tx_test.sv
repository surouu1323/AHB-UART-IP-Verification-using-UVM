class uart_multi_tx_test extends uart_base_test;
  `uvm_component_utils(uart_multi_tx_test)

  function new(string name="uart_multi_tx_test", uvm_component parent);
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
        bit[31:0] rdata;
		int i = 1;
        
        regmodel.MDR.write (status, 32'h0 );
        regmodel.DLL.write (status, 32'h36);
        regmodel.DLH.write (status, 32'h00);
        
		regmodel.IER.write (status, 32'h3);

		/*---------------------------------------------------------------------------------------*/
        regmodel.FSR.read(status,rdata);
	    `uvm_info("fifo_state", $sformatf("check state empty = 1, full = 0"), UVM_LOW);
		if(rdata[1] == 'b1 && rdata[0] == 'b0)begin
	        `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, tx_full_status = 0x%b",rdata[1],rdata[0]));
		end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("fifo_state", $sformatf("write 1 data -> check state empty = 0, full = 0"), UVM_LOW);
        regmodel.TBR.write (status, $urandom, UVM_FRONTDOOR);
		`uvm_info("fifo_state", $sformatf("write %0d data", i), UVM_LOW);			i++;
		
	    regmodel.FSR.read(status,rdata);
		if(rdata[0] == 'b0 && rdata[1] == 'b0)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, tx_full_status = 0x%b",rdata[1],rdata[0]));
		end


		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("fifo_state", $sformatf("write 14 data -> check state empty = 0, full = 0"), UVM_LOW);
        repeat(14)begin
			
		    `uvm_info("fifo_state", $sformatf("write %0d data", i), UVM_LOW);			i++;
            regmodel.TBR.write (status, $urandom, UVM_FRONTDOOR);
			
	    	regmodel.FSR.read(status,rdata);
			if(rdata[0] == 'b0 && rdata[1] == 'b0)begin
			    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
			end
			else begin
			    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, tx_full_status = 0x%b",rdata[1],rdata[0]));
			end
        end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("fifo_state", $sformatf("write 1 data -> check state empty = 0, full = 1"), UVM_LOW);
		`uvm_info("fifo_state", $sformatf("write %0d data", i), UVM_LOW);			i++;
        regmodel.TBR.write (status, $urandom, UVM_FRONTDOOR);
			
	    regmodel.FSR.read(status,rdata);
		if(rdata[0] == 'b1 && rdata[1] == 'b0)begin
		    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, tx_full_status = 0x%b",rdata[1],rdata[0]));
		end


		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("fifo_state", $sformatf("write more data -> check state empty = 0, full = 1"), UVM_LOW);
        repeat(14)begin
			
		    `uvm_info("fifo_state", $sformatf("write %0d data", i), UVM_LOW);			i++;
            regmodel.TBR.write (status, $urandom, UVM_FRONTDOOR);
			
	    	regmodel.FSR.read(status,rdata);
			if(rdata[0] == 'b1 && rdata[1] == 'b0)begin
			    `uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
			end
			else begin
			    `uvm_error("fifo_state", $sformatf("tx_empty_status = 0x%b, tx_full_status = 0x%b",rdata[1],rdata[0]));
			end
        end

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("DUT", $sformatf("set tx transfer data "), UVM_LOW);
        regmodel.LCR.write (status, 32'h23);
		#2ms;
		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("fifo_state", $sformatf("check state empty = 1, full = 0"), UVM_LOW);
        regmodel.FSR.read(status,rdata);
		if(rdata[0] == 'b0 && rdata[1] == 'b1)begin
			`uvm_info("fifo_state", $sformatf("fifo_state == 0x%0b", rdata), UVM_LOW);
		end
		else begin
		    `uvm_error("fifo_state", $sformatf("tx_empty != 0, tx_empty_status = 0x%b, tx_full_status = 0x%b",rdata[1],rdata[0]));
		end
  endtask

endclass
