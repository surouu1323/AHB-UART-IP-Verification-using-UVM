class uart_interrupt_parity_test extends uart_base_test;
  `uvm_component_utils(uart_interrupt_parity_test)
  
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

  function new(string name="uart_interrupt_parity_test", uvm_component parent);
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
		int i = 1;
        
//        regmodel.MDR.write (status, 32'h0 );
//        regmodel.DLL.write (status, 32'h36);
//        regmodel.DLH.write (status, 32'h00);
//        
//		regmodel.IER.write (status, 32'h10);
		
		/*---------------------------------------------------------------------------------------*/

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width correct parity"), UVM_LOW);
			
	    foreach (baud_list[b]) begin
	      foreach (width_list[w]) begin
	        foreach (stop_list[s]) begin
	          foreach (sampling_list[a]) begin
	    		uart_cfg.baud_rate    = baud_list[b];
	    		uart_cfg.parity_mode  = uart_configuration::EVEN;
		        uart_cfg.data_width   = width_list[w];
		        uart_cfg.stop_bit     = stop_list[s];
		        uart_cfg.sampling_mode= sampling_list[a];
	

	
				reg_cfg();

				uart_write($urandom_range(0,8'hff));	
		        done_tx_transfer_ev.wait_ptrigger(); 
		        done_tx_transfer_ev.reset();
	
//				#1ms;
//	    		regmodel.RBR.read(status,rdata);
				rbr_reg_read();
			   
				regmodel.FSR.read(status,rdata);
				if(rdata[4] == 'b0)begin
				    `uvm_info("FSR REG", $sformatf("parrity = 0x%0b", rdata[4]), UVM_LOW);
				end
				else begin
				    `uvm_error("FSR REG", $sformatf("parrity status mismatch, got = 0x%0b, expect = 0x%0b", rdata[4],~rdata[4]));
				end
	
				if(dut_int_vif.interrupt == 0)begin
				    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt correct: == %0b", dut_int_vif.interrupt), UVM_LOW);
				end
				else begin
	    			`uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width correct parity"), UVM_LOW);
					`uvm_info("UART_CFG", $sformatf(">>> Applying Config:Sampling=%s, Baud=%s, Width=%s, Stop=%s, Parity=%s", 
						uart_cfg.sampling_mode.name(),
					    uart_cfg.baud_rate.name(), 
					    uart_cfg.data_width.name(),
					    uart_cfg.stop_bit.name(),
					    uart_cfg.parity_mode.name()), UVM_LOW)
				    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
				end
	          end
	        end
	      end
	    end

		regmodel.reset();
		ahb_vif.HRESETn = 1'b0; #10ns ahb_vif.HRESETn = 1'b1;
		
//		/*---------------------------------------------------------------------------------------*/
//	    `uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width wrong parity"), UVM_LOW);
//			
//	    foreach (baud_list[b]) begin
//	      foreach (width_list[w]) begin
//	        foreach (stop_list[s]) begin
//	          foreach (sampling_list[a]) begin
//	    		uart_cfg.baud_rate    = baud_list[b];
//		        uart_cfg.data_width   = width_list[w];
//		        uart_cfg.stop_bit     = stop_list[s];
//		        uart_cfg.sampling_mode= sampling_list[a];
//		        uart_cfg.parity_mode  = uart_configuration::ODD;
//
//				reg_cfg();
//				regmodel.LCR.write(status,{26'b0,1'b1, 1'b1, 1'b1, 1'b0, 2'h3});
//
//				uart_write($urandom_range(0,8'hff));	
//		        done_tx_transfer_ev.wait_trigger(); 
//		        done_tx_transfer_ev.reset();
//					
//				regmodel.FSR.read(status,rdata);
//				if(rdata[4] == 'b1)begin
//				    `uvm_info("FSR REG", $sformatf("parrity = 0x%0b", rdata[4]), UVM_LOW);
//				end
//				else begin
//				    `uvm_error("FSR REG", $sformatf("parrity status mismatch, got = 0x%0b, expect = %0b", rdata[4],~rdata[4]));
//				end
//		
//				if(dut_int_vif.interrupt == 1)begin
//				    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
//				end
//				else begin
//	    			`uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width wrong parity"), UVM_LOW);
//					`uvm_info("UART_CFG", $sformatf(">>> Applying Config:Sampling=%s, Baud=%s, Width=%s, Stop=%s, Parity=%s", 
//						uart_cfg.sampling_mode.name(),
//					    uart_cfg.baud_rate.name(), 
//					    uart_cfg.data_width.name(),
//					    uart_cfg.stop_bit.name(),
//					    uart_cfg.parity_mode.name()), UVM_LOW)
//				    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
//				end
//	          end
//	        end
//	      end
//	    end
//		regmodel.reset();
//		ahb_vif.HRESETn = 1'b0; #10ns ahb_vif.HRESETn = 1'b1;
//		/*---------------------------------------------------------------------------------------*/
//	    `uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width correct parity"), UVM_LOW);
//			
//	    foreach (baud_list[b]) begin
//	      foreach (width_list[w]) begin
//	        foreach (stop_list[s]) begin
//	          foreach (sampling_list[a]) begin
//	    		uart_cfg.baud_rate    = baud_list[b];
//	    		uart_cfg.parity_mode  = uart_configuration::EVEN;
//		        uart_cfg.data_width   = width_list[w];
//		        uart_cfg.stop_bit     = stop_list[s];
//		        uart_cfg.sampling_mode= sampling_list[a];
//		        uart_cfg.parity_mode  = uart_configuration::EVEN;
//		
//				reg_cfg();
//
//				uart_write($urandom_range(0,8'hff));	
//		        done_tx_transfer_ev.wait_trigger(); 
//		        done_tx_transfer_ev.reset();
//					
//		    	regmodel.TBR.read(status,rdata);
//			   
//				regmodel.FSR.read(status,rdata);
//				if(rdata[4] == 'b0)begin
//				    `uvm_info("FSR REG", $sformatf("parrity = 0x%0b", rdata[4]), UVM_LOW);
//				end
//				else begin
//				    `uvm_error("FSR REG", $sformatf("parrity status mismatch, got = 0x%0b, expect = %0b", rdata[4],~rdata[4]));
//				end
//		
//				if(dut_int_vif.interrupt == 0)begin
//				    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
//				end
//				else begin
//	    			`uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width correct parity"), UVM_LOW);
//					`uvm_info("UART_CFG", $sformatf(">>> Applying Config:Sampling=%s, Baud=%s, Width=%s, Stop=%s, Parity=%s", 
//						uart_cfg.sampling_mode.name(),
//					    uart_cfg.baud_rate.name(), 
//					    uart_cfg.data_width.name(),
//					    uart_cfg.stop_bit.name(),
//					    uart_cfg.parity_mode.name()), UVM_LOW)
//				    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
//				end
//		
//	          end
//	        end
//	      end
//	    end
//		regmodel.reset();
//		ahb_vif.HRESETn = 1'b0; #10ns ahb_vif.HRESETn = 1'b1;
//		/*---------------------------------------------------------------------------------------*/
//	    `uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width wrong parity"), UVM_LOW);
//			
//	    foreach (baud_list[b]) begin
//	      foreach (width_list[w]) begin
//	        foreach (stop_list[s]) begin
//	          foreach (sampling_list[a]) begin
//	    		uart_cfg.baud_rate    = baud_list[b];
//	    		uart_cfg.parity_mode  = uart_configuration::EVEN;
//		        uart_cfg.data_width   = width_list[w];
//		        uart_cfg.stop_bit     = stop_list[s];
//		        uart_cfg.sampling_mode= sampling_list[a];
//		        uart_cfg.parity_mode  = uart_configuration::ODD;
//		
//				reg_cfg();
//
//				uart_write($urandom_range(0,8'hff));	
//		        done_tx_transfer_ev.wait_trigger(); 
//		        done_tx_transfer_ev.reset();
//		
//		    	regmodel.TBR.read(status,rdata);
//					
//				regmodel.FSR.read(status,rdata);
//				if(rdata[4] == 'b1)begin
//				    `uvm_info("FSR REG", $sformatf("parrity = 0x%0b", rdata[4]), UVM_LOW);
//				end
//				else begin
//				    `uvm_error("FSR REG", $sformatf("parrity status mismatch, got = 0x%0b, expect = %0b", rdata[4],~rdata[4]));
//				end
//		
//				if(dut_int_vif.interrupt == 1)begin
//				    `uvm_info("dut_int_vif.interrupt", $sformatf("interrupt == %0b", dut_int_vif.interrupt), UVM_LOW);
//				end
//				else begin
//	    			`uvm_info("TEST CASE PARITY EVEN", $sformatf("write data width wrong parity"), UVM_LOW);
//					`uvm_info("UART_CFG", $sformatf(">>> Applying Config:Sampling=%s, Baud=%s, Width=%s, Stop=%s, Parity=%s", 
//						uart_cfg.sampling_mode.name(),
//					    uart_cfg.baud_rate.name(), 
//					    uart_cfg.data_width.name(),
//					    uart_cfg.stop_bit.name(),
//					    uart_cfg.parity_mode.name()), UVM_LOW)
//				    `uvm_error("dut_int_vif.interrupt", $sformatf("interrupt == %0b, exp = %0b",dut_int_vif.interrupt, ~dut_int_vif.interrupt));
//				end
//	          end
//	        end
//	      end
//	    end
//		regmodel.reset();
//		ahb_vif.HRESETn = 1'b0; #10ns ahb_vif.HRESETn = 1'b1;


	endtask
endclass
