class uart_half_tx_ran_cfg_test extends uart_base_test;
  `uvm_component_utils(uart_half_tx_ran_cfg_test)

  int send_random_data_time = 1; // Number of data packets to send per test
  int test_case_cnt = 0;         // count number of test
  int test_cnt_set  = 6;         // set number of test
  logic [7:0] rand_val; 

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
  function new(string name="uart_half_tx_ran_cfg_test", uvm_component parent);
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
    wait(ahb_vif.HRESETn == 1'b1);
    repeat(5) @(posedge ahb_vif.HCLK);
    `uvm_info(get_type_name(), "Reset released and is stable", UVM_LOW)


	`uvm_info("TEST_STATUS", $sformatf("<<< /*=============  TEST START  ===============*/ \n"), UVM_LOW)
	repeat(test_cnt_set)begin
		int b = $urandom_range(0,6 );
		int w = $urandom_range(0,3 );
		int s = $urandom_range(0,1 );
		int p = $urandom_range(0,2 );
		int a = $urandom_range(0,1 );

        uart_cfg.baud_rate    = baud_list[b];
        uart_cfg.parity_mode  = parity_list[p];
        uart_cfg.data_width   = width_list[w];
        uart_cfg.stop_bit     = stop_list[s];
        uart_cfg.sampling_mode= sampling_list[a];
	
		test_start();
    end

	`uvm_info("TEST_STATUS", $sformatf("<<< /*=============  TEST END  ===============*/ \n"), UVM_LOW)

    #300us
    phase.drop_objection(this);
   endtask

	virtual task test_start();


	
	test_case_cnt++;
	`uvm_info("TEST_STATUS", $sformatf("<<< [CASE %0d] Start test sequence.", test_case_cnt), UVM_LOW)

	`uvm_info("UART_DATA", $sformatf("-------------------------------------------------------------------"), UVM_LOW)
	`uvm_info("UART_CFG", $sformatf(">>> [CASE %0d] Applying Config:Sampling=%s, Baud=%s, Width=%s, Stop=%s, Parity=%s.", 
	    test_case_cnt,
		uart_cfg.sampling_mode.name(),
	    uart_cfg.baud_rate.name(), 
	    uart_cfg.data_width.name(),
	    uart_cfg.stop_bit.name(),
	    uart_cfg.parity_mode.name()), UVM_LOW)


	`uvm_info("DUT_STATUS", $sformatf("<<<Configuaring DUT. \n"), UVM_LOW)
	reg_cfg();
	
	
	i = 0;	
	repeat(send_random_data_time) begin
		i++;
		`uvm_info("UART_DATA", $sformatf("-------------------------------------------------------------------"), UVM_LOW)
		`uvm_info("UART_DATA", $sformatf("Iteration [%0d/%0d] -> Writing Data " ,   i, send_random_data_time), UVM_LOW)
	
		rand_val =$urandom_range(0, 8'hFF);
	    tbr_reg_write(rand_val);
	
	
		// Wait for the monitor to trigger completion of the transfer sequence
	    done_rx_transfer_ev.wait_trigger();
		done_rx_transfer_ev.reset();
	end
	`uvm_info("TEST_STATUS", $sformatf("<<< [CASE %0d] Test sequence compledted. \n", test_case_cnt), UVM_LOW)
	#10us;
	endtask : test_start


endclass
