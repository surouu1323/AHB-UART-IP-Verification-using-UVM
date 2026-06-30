class uart_base_test extends uvm_test;
  `uvm_component_utils(uart_base_test)

  uvm_report_server  svr;

  uart_reg_block   regmodel;
  virtual ahb_if    ahb_vif;
  virtual dut_interrupt    dut_int_vif;

  virtual uart_if uart_vif;
  uart_configuration uart_cfg;
  uart_write_sequence m_write_seq;
  uart_error_catcher err_catcher;
  uart_environment  env;

  time usr_timeout=555s;
	int i=0;

  function new(string name="uart_base_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("build_phase","Entered...",UVM_HIGH)

    //virtual interface received through the config db
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_vif))
      `uvm_fatal(get_type_name(),$sformatf("failed to get uart_vif from uvm_config_db. please check!"))
    
    uvm_config_db#(virtual uart_if)::set(this,"env","uart_vif",uart_vif);
    
	uvm_config_db#(virtual dut_interrupt)::get(this,"","dut_int_vif",dut_int_vif);


    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get ahb_vif from uvm_config_db"))
   
    uvm_config_db#(virtual ahb_if)::set(this,"env","ahb_vif",ahb_vif);

    env     = uart_environment::type_id::create("env",this);


    uart_cfg = uart_configuration::type_id::create("uart_cfg",this);
    uart_cfg.baud_rate    = uart_configuration::B_9600;
    uart_cfg.parity_mode  = uart_configuration::ODD;
    uart_cfg.data_width   = uart_configuration::D_8b;
    uart_cfg.stop_bit     = uart_configuration::STOP_2BIT;
    `uvm_info(get_type_name(), "uart_config successed",UVM_HIGH)

    uvm_config_db#(uart_configuration)::set(this,"env*","uart_cfg",uart_cfg);

    err_catcher = uart_error_catcher::type_id::create("error_catcher");
    uvm_report_cb::add(null, err_catcher);

    `uvm_info("build_phase","Exiting...",UVM_HIGH)

    uvm_top.set_timeout(usr_timeout);


  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    this.regmodel = env.regmodel;
  endfunction: connect_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("end_of_elaboration_phase","Entered...",UVM_HIGH)

    if (get_report_verbosity_level() >= UVM_HIGH) begin // Only print verbosity is set to HIGH or above for deep debugging
        uvm_top.print_topology();
    end else begin
        uvm_top.enable_print_topology = 0; // Disable the automatic topology print to ensure a clean log
    end
    `uvm_info("end_of_elaboration_phase","Exiting...",UVM_HIGH)

  endfunction: end_of_elaboration_phase

  virtual task uart_write (input logic[8:0] data);
    int bits = get_num_bits(uart_cfg.data_width);
    logic[8:0] masked_data = data & ((1 << bits) - 1);

    `uvm_info("UART_WRITE", $sformatf("[UART]: Sending Data=0x%0h (Width=%0d bits)", 
              masked_data, bits), UVM_LOW)

    m_write_seq = new();
    m_write_seq.data = masked_data;
    m_write_seq.direction = uart_transaction::WRITE;
    m_write_seq.start(env.uart_agt.sequencer);
  endtask: uart_write

  
  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    `uvm_info("final_phase","Entered...",UVM_HIGH)
    svr = uvm_report_server::get_server();
    if(svr.get_severity_count(UVM_FATAL)+
       svr.get_severity_count(UVM_ERROR)) begin
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     `uvm_info(get_type_name(), "----           TEST FAILED         ----", UVM_NONE)
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    else begin
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     `uvm_info(get_type_name(), "----           TEST PASSED         ----", UVM_NONE)
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    `uvm_info("final_phase","Exiting...",UVM_HIGH)
  endfunction: final_phase


  local function int get_num_bits(uart_configuration::data_width_enum dw);
    case(dw)
        uart_configuration::D_5b: return 5;
        uart_configuration::D_6b: return 6;
        uart_configuration::D_7b: return 7;
        uart_configuration::D_8b: return 8;
        default: return 8;
    endcase
  endfunction: get_num_bits


	virtual task reg_cfg();
        uvm_status_e status;
        

		if(uart_cfg.sampling_mode == uart_configuration::M_13x)begin
	        regmodel.MDR.write (status, 32'b0);
			case(uart_cfg.baud_rate)
				uart_configuration::B_2400: begin
			        regmodel.DLH.write (status, 32'h0A); regmodel.DLL.write (status, 32'h2C);
				end
				uart_configuration::B_4800: begin
			        regmodel.DLH.write (status, 32'h05); regmodel.DLL.write (status, 32'h16);
				end
				uart_configuration::B_9600: begin
			        regmodel.DLH.write (status, 32'h02); regmodel.DLL.write (status, 32'h8B);
				end
				uart_configuration::B_19200: begin
			        regmodel.DLH.write (status, 32'h01); regmodel.DLL.write (status, 32'h45);
				end
				uart_configuration::B_38400: begin
			        regmodel.DLH.write (status, 32'h00); regmodel.DLL.write (status, 32'hA3);
				end
				uart_configuration::B_76800: begin
			        regmodel.DLH.write (status, 32'h00); regmodel.DLL.write (status, 32'h51);
				end
				uart_configuration::B_115200: begin
			        regmodel.DLH.write (status, 32'h00); regmodel.DLL.write (status, 32'h36);
				end
				default:;
			endcase
		end
		else begin
	        regmodel.MDR.write (status, 32'b1);
			case(uart_cfg.baud_rate)
				uart_configuration::B_2400: begin
			        regmodel.DLH.write (status, 32'h0C); regmodel.DLL.write (status, 32'h85);
				end
				uart_configuration::B_4800: begin
			        regmodel.DLH.write (status, 32'h06); regmodel.DLL.write (status, 32'h42);
				end
				uart_configuration::B_9600: begin
			        regmodel.DLH.write (status, 32'h03); regmodel.DLL.write (status, 32'h21);
				end
				uart_configuration::B_19200: begin
			        regmodel.DLH.write (status, 32'h01); regmodel.DLL.write (status, 32'h91);
				end
				uart_configuration::B_38400: begin
			        regmodel.DLH.write (status, 32'h00); regmodel.DLL.write (status, 32'hC8);
				end
				uart_configuration::B_76800: begin
			        regmodel.DLH.write (status, 32'h00); regmodel.DLL.write (status, 32'h64);
				end
				uart_configuration::B_115200: begin
			        regmodel.DLH.write (status, 32'h00); regmodel.DLL.write (status, 32'h43);
				end
				default:;
			endcase
		end
        regmodel.LCR.bge.set ( 'b1);
        regmodel.LCR.eps.set ( (uart_cfg.parity_mode == uart_configuration::ODD)?'b0:'b1);
        regmodel.LCR.pen.set ( (uart_cfg.parity_mode == uart_configuration::NONE)?'b0:'b1);
        regmodel.LCR.stb.set ( (uart_cfg.stop_bit == uart_configuration::STOP_1BIT)?'b0:'b1);
		case(uart_cfg.data_width)
			uart_configuration::D_5b:	regmodel.LCR.wls.set ( 2'b00);
			uart_configuration::D_6b:	regmodel.LCR.wls.set ( 2'b01);
			uart_configuration::D_7b:	regmodel.LCR.wls.set ( 2'b10);
			uart_configuration::D_8b:	regmodel.LCR.wls.set ( 2'b11);
			default:;
		endcase

		regmodel.LCR.update(status);
	endtask : reg_cfg

	virtual task rbr_reg_read( );
        uvm_status_e status;
		logic [31:0] data;

		#1ms;
		/*---------------------------------------------------------------------------------------*/
		regmodel.RBR.read (status, data);
	    `uvm_info("DUT", $sformatf("read Rx data : 0x%0h", data), UVM_LOW);

  endtask
	virtual task tbr_reg_write(bit [31:0] data );
        uvm_status_e status;

		/*---------------------------------------------------------------------------------------*/
	    `uvm_info("DUT", $sformatf("set tx transfer data : 0x%0h", data), UVM_LOW);
		regmodel.TBR.write (status, data);

  endtask
endclass: uart_base_test
