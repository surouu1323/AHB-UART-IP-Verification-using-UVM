class uart_driver extends uvm_driver #(uart_transaction);
  `uvm_component_utils(uart_driver)

  uart_configuration uart_cfg;
  uart_transaction trans;
  virtual uart_if uart_vif;
  virtual ahb_if ahb_vif;

//  uvm_event done_transfer_ev;
  int num_bits;


  //Calculate baud rate => delay time
  realtime bit_period;

  function new(string name="uart_driver", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    /** Applying the virtual interface received through the config db - learn detail in next session*/
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))

    //uart configuration received through the config db
    if(!uvm_config_db#(uart_configuration)::get(this,"","uart_cfg",uart_cfg))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))

    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))

  endfunction: build_phase

  /** User can use uart_vif to control real interface like systemverilog part*/
  virtual task run_phase(uvm_phase phase);
    trans = uart_transaction::type_id::create("trans");
//    done_transfer_ev = uvm_event_pool::get_global("DONE_TRANSFER");

    forever begin
        `uvm_info(get_type_name(), "Start wait packet", UVM_HIGH);        
        seq_item_port.get(req); 
        `uvm_info(get_type_name(), "Got packet from sequencer", UVM_HIGH);
        // req.print();

        $cast(trans.data, req.data);
		trans.direction = uart_transaction::WRITE;
		fork
			begin
        		drive();
			end
			begin
				wait(ahb_vif.HRESETn == 'b0);
			end
		
		join_any
		disable fork;

    end;

  endtask: run_phase

   virtual task drive();
      bit_period = get_baudrate_delay(uart_cfg.baud_rate);
      `uvm_info(get_type_name(), "Driving Tx", UVM_HIGH); 
      if (get_report_verbosity_level >= UVM_HIGH) uart_cfg.print();

      // -------------------------------------------------------------------------
      //1. Start condition
      // -------------------------------------------------------------------------
      uart_vif.tx = 1'b0;
      #(bit_period);

      // -------------------------------------------------------------------------
      //2. Shift data bits      
      // -------------------------------------------------------------------------

      num_bits = get_num_bits(uart_cfg.data_width);
      for(int i = 0; i<num_bits ; i++)
        begin
      	`uvm_info("TX SIG DRIVE",$sformatf("driving: %b", req.data[i]),UVM_HIGH);
          uart_vif.tx = req.data[i];
          #(bit_period);
        end

      // -------------------------------------------------------------------------
      //3. Parity bit
      // -------------------------------------------------------------------------        
      if((uart_cfg.parity_mode != uart_configuration::NONE))
        begin
          case(uart_cfg.parity_mode)
            uart_configuration::ODD : uart_vif.tx = ~(^(req.data & ((1<< num_bits)-1)));
            uart_configuration::EVEN: uart_vif.tx = (^(req.data & ((1<< num_bits)-1)));
            default:;
          endcase
          #(bit_period);
        end
      // -------------------------------------------------------------------------            
      //4. Stop bit
      // -------------------------------------------------------------------------        
      uart_vif.tx = 'b1;
      #(bit_period);
      if(uart_cfg.stop_bit == uart_configuration::STOP_2BIT) #(bit_period);

      //done_transfer_ev.trigger();
      `uvm_info("uart_driver","Done driving",UVM_HIGH);
  endtask: drive

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


endclass: uart_driver

