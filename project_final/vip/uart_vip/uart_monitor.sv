class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)
    uart_configuration uart_cfg;
	uvm_event done_rx_transfer_ev;
	uvm_event done_tx_transfer_ev;

    virtual uart_if uart_vif;
	virtual ahb_if ahb_vif;


    /* Analysis port, send the transaction to scoreboard */
    uvm_analysis_port #(uart_transaction) item_observed_port;

    //Calculate baud rate => delay time
    realtime bit_period;

    int num_bits;


  function new(string name="uart_monitor", uvm_component parent);
    super.new(name,parent);
    item_observed_port = new("item_observed_port", this);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    /** Applying the virtual interface received through the config db - learn detail in next session*/
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))

    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))

    //uart configuration received through the config db
    if(!uvm_config_db#(uart_configuration)::get(this,"","uart_cfg",uart_cfg))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))


    done_rx_transfer_ev = uvm_event_pool::get_global("DONE_RX_TRANSFER");
    done_tx_transfer_ev = uvm_event_pool::get_global("DONE_TX_TRANSFER");
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
	forever begin
		wait(ahb_vif.HRESETn == 'b1);
	        fork
	            forever line_monitor(uart_vif.tx, uart_transaction::WRITE);
	            forever line_monitor(uart_vif.rx, uart_transaction::READ);
				begin
					wait(ahb_vif.HRESETn == 'b0);
				end
	        join_any
			disable fork;
		end
  endtask: run_phase

  virtual task line_monitor(ref logic line_sig, input uart_transaction::direction_enum dir);
        uart_transaction trans;
        trans = uart_transaction::type_id::create("trans");
        trans.data = 0;



        `uvm_info(get_type_name(), $sformatf("Start waiting Start Bit on %s", dir.name()), UVM_MEDIUM)    

        // -------------------------------------------------------------------------
        //1. Start condition
        // -------------------------------------------------------------------------
        @(negedge line_sig);
        bit_period = get_baudrate_delay(uart_cfg.baud_rate);
        `uvm_info(get_type_name(), $sformatf("Detected Start Bit on %s", dir.name()), UVM_MEDIUM)
        #(bit_period/2);

        // -------------------------------------------------------------------------
        //2. Shift data bits
        // -------------------------------------------------------------------------
        num_bits = get_num_bits(uart_cfg.data_width);
        for(int i = 0; i<num_bits ; i++)
        begin
            #(bit_period);
            trans.data[i] = line_sig;
        	`uvm_info(get_type_name(), $sformatf("Detect Data Bit: %b", line_sig), UVM_HIGH)
        end

        // -------------------------------------------------------------------------
        // 3. Parity Bit Sampling and Verification
        // -------------------------------------------------------------------------

        `uvm_info(get_type_name(), $sformatf("Parity Mode: %s", uart_cfg.parity_mode.name()), UVM_HIGH)
        if ((uart_cfg.parity_mode != uart_configuration::NONE)) begin
            bit expected_parity;
            bit actual_parity;
            #(bit_period);
            

            actual_parity = line_sig; // Sample the physical parity bit from the TX line
        	`uvm_info(get_type_name(), $sformatf("Detect Parity Bit: %b", actual_parity), UVM_HIGH)

            // Calculate the expected parity bit based on the received data payload~
            case(uart_cfg.parity_mode)
                uart_configuration::ODD : expected_parity = ~(^trans.data); // Odd: Total bits (data + parity) must be odd
                uart_configuration::EVEN: expected_parity = (^trans.data);  // Even: Total bits (data + parity) must be even
                default: expected_parity = 0; 
            endcase

            // Compare sampled parity against calculated expected value
            if (actual_parity != expected_parity) begin
                `uvm_error(get_type_name(), $sformatf("Parity Mismatch! Mode: %s, Data: 8'h%0h, Exp: %b, Got: %b", 
                        uart_cfg.parity_mode.name(), trans.data, expected_parity, actual_parity))
                        
						`uvm_error("UART_CFG", $sformatf(">>> Sampling=%s, Baud=%s, Width=%s, Stop=%s, Parity=%s.", 
							uart_cfg.sampling_mode.name(),
						    uart_cfg.baud_rate.name(), 
						    uart_cfg.data_width.name(),
						    uart_cfg.stop_bit.name(),
						    uart_cfg.parity_mode.name()))
                // trans.parity_error = 1; // Mark transaction with error flag for Scoreboard analysis
            end else begin
                `uvm_info(get_type_name(), $sformatf("Parity Match: %b", actual_parity), UVM_HIGH)
                // trans.parity_error = 0; // Parity is correct
            end

        end

        #(bit_period); // Wait for one bit period to move to the Stop bit phase
        `uvm_info(get_type_name(), $sformatf("Detect Bit: %b", line_sig), UVM_HIGH)
        // -------------------------------------------------------------------------
        //4. Stop bit
        // -------------------------------------------------------------------------  
            if(line_sig != 'b1) `uvm_error(get_type_name(), $sformatf("1st Stop bit not 1 !"))

            if(uart_cfg.stop_bit == uart_configuration::STOP_2BIT) begin
                #(bit_period);
                if(line_sig != 'b1) `uvm_error(get_type_name(), $sformatf("2nd Stop bit not 1 !"))
            end

        #(bit_period/2);

        `uvm_info(get_type_name(),"Done receiving packet",UVM_HIGH);

        `uvm_info(get_type_name(),$sformatf("Packet Sent to Scoreboard: Data=0x%0h| Dir=%s",trans.data, dir.name()),UVM_LOW);
        `uvm_info(get_type_name(), "Send packet to scoreboard", UVM_HIGH)     
        trans.direction =  dir;
        if (uvm_report_enabled(UVM_HIGH)) trans.print();
        item_observed_port.write(trans);

        `uvm_info(get_type_name(), "Frame received, triggering event...", UVM_MEDIUM)


		if(dir == uart_transaction::READ) begin
			done_rx_transfer_ev.trigger();
        	`uvm_info("EVENT TRIGGER", $sformatf("done rx transfer ev trigger"), UVM_HIGH)
		end
		else begin
			done_tx_transfer_ev.trigger();
        	`uvm_info("EVENT TRIGGER", $sformatf("done tx transfer ev trigger"), UVM_HIGH)
		end

        
  endtask: line_monitor


    local function int get_num_bits(uart_configuration::data_width_enum dw);
        case(dw)
            uart_configuration::D_5b: return 5;
            uart_configuration::D_6b: return 6;
            uart_configuration::D_7b: return 7;
            uart_configuration::D_8b: return 8;
            default: return 8;
        endcase
    endfunction

    local function realtime get_baudrate_delay(uart_configuration::baud_rate_enum br);
        case(br)
            uart_configuration::B_2400   : return 1s / 2400  ;
            uart_configuration::B_4800   : return 1s / 4800  ;
            uart_configuration::B_9600   : return 1s / 9600  ;
            uart_configuration::B_19200  : return 1s / 19200 ;
            uart_configuration::B_38400  : return 1s / 38400 ;
            uart_configuration::B_76800  : return 1s / 76800 ;
            uart_configuration::B_115200 : return 1s / 115200;
            default: return 1s / 9600;
        endcase
    endfunction

endclass: uart_monitor

