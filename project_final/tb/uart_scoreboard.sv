`uvm_analysis_imp_decl(_ahb_monitor)
`uvm_analysis_imp_decl(_uart_monitor)

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

    ahb_transaction ahb_driver_tx_q[$];
    ahb_transaction ahb_driver_rx_q[$];
    uart_transaction uart_tx_q[$];
    uart_transaction uart_rx_q[$];

	virtual ahb_if ahb_vif;

 	uart_transaction uart_cloned_trans;
    uart_transaction uart_trans;
    uart_transaction uart_trans_cmp;
    ahb_transaction ahb_trans;
    ahb_transaction ahb_trans_cmp;
    ahb_transaction ahb_cloned_trans;
    uart_configuration uart_cfg;
  /*Analysis port received transaction from monitor*/

  uvm_analysis_imp_ahb_monitor#(ahb_transaction, uart_scoreboard) ahb_mon_collected_export;
  uvm_analysis_imp_uart_monitor #(uart_transaction, uart_scoreboard) uart_mon_collected_export;


  function new(string name=get_type_name(), uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahb_mon_collected_export  = new("ahb_mon_collected_export", this);
    uart_mon_collected_export = new("uart_mon_collected_export", this);

    uart_cloned_trans = uart_transaction::type_id::create("uart_cloned_trans", this);
    ahb_cloned_trans = ahb_transaction::type_id::create("ahb_cloned_trans", this);
    ahb_trans = ahb_transaction::type_id::create("ahb_trans", this);
    ahb_trans_cmp = ahb_transaction::type_id::create("ahb_trans_cmp", this);
    uart_trans = uart_transaction::type_id::create("uart_trans", this);

    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))


    //uart configuration received through the config db
    if(!uvm_config_db#(uart_configuration)::get(this,"","uart_cfg",uart_cfg))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))
  endfunction: build_phase

	virtual task run_phase(uvm_phase phase);
		forever begin
			if(ahb_vif.HRESETn == 'b0)begin
				ahb_driver_tx_q.delete();
				ahb_driver_rx_q.delete();
				uart_tx_q.delete();
				uart_rx_q.delete();
				wait(ahb_vif.HRESETn == 'b1);
			end
			else #1ns;
		end
	endtask: run_phase



  virtual function void write_uart_monitor(uart_transaction uart_trans);
    `uvm_info(get_type_name(),"Received trans from monitor",UVM_MEDIUM)
	if(get_report_verbosity_level() >= UVM_HIGH)    uart_trans.print();  
	

    if(uart_trans.direction == uart_transaction::READ) begin
		if(ahb_driver_tx_q.size >0) begin
        	ahb_trans_cmp  = ahb_driver_tx_q.pop_back(); 
			ahb_trans_cmp.data = ahb_trans_cmp.data &((1<<(get_num_bits(uart_cfg.data_width)))-1);

			if(ahb_trans_cmp.data != uart_trans.data) 
		    	`uvm_error(get_type_name(),$sformatf("Data not match: Dir: %s, ahb_tx.data: 0x%0h, monior.data: 0x%0h",uart_trans.direction ,ahb_trans_cmp.data, uart_trans.data))
			else `uvm_info(get_type_name(),$sformatf("Data match: Dir:%s, ahb_tx.data: 0x%0h, monior.data: 0x%0h",uart_trans.direction,ahb_trans_cmp.data, uart_trans.data),UVM_LOW)            
		end
		else `uvm_error(get_type_name(),"ahb_tx_q empty! ")
    end
    else begin
		if(uart_tx_q.size() < 17)  begin
			$cast(uart_cloned_trans, uart_trans.clone());
			uart_tx_q.push_front(uart_cloned_trans);
	    	`uvm_info(get_type_name(),"Push uart tx transaction -> queue",UVM_MEDIUM)
	    	`uvm_info(get_type_name(),$sformatf("uart_tx_q size: %d", uart_tx_q.size()),UVM_MEDIUM)
		end
		else
	    	`uvm_info(get_type_name(),"uart_tx_q max size! ",UVM_MEDIUM)
//        ahb_trans_cmp  = ahb_driver_rx_q.pop_back();
//		if(ahb_driver_rx_q.size >0) begin
//        	ahb_trans_cmp  = ahb_driver_rx_q.pop_back();
//			ahb_trans_cmp.data = ahb_trans_cmp.data &((1<<(get_num_bits(uart_cfg.data_width)))-1);

//			if(ahb_trans_cmp.data != uart_trans.data) 
//		    	`uvm_error(get_type_name(),$sformatf("Data not match: Dir: %s, rhs_driver.data: 0x%0h, monior.data: 0x%0h",uart_trans.direction ,ahb_trans_cmp.data, uart_trans.data))
//			else `uvm_info(get_type_name(),$sformatf("Data match: Dir:%s, rhs_driver.data: 0x%0h, monior.data: 0x%0h",uart_trans.direction,ahb_trans_cmp.data, uart_trans.data),UVM_LOW)            
//		end
    end


  endfunction: write_uart_monitor


  virtual function void write_ahb_monitor(ahb_transaction ahb_trans);
    `uvm_info(get_type_name(),"Received trans from ahb monitor",UVM_MEDIUM)
	if(get_report_verbosity_level() >= UVM_HIGH) ahb_trans.print();  

	if((ahb_trans.addr == 'h018 && ahb_trans.xact_type == ahb_transaction::WRITE)) begin
    	$cast(ahb_cloned_trans, ahb_trans.clone());
		if(ahb_driver_tx_q.size() < 17)  begin
			ahb_driver_tx_q.push_front(ahb_cloned_trans);
	    	`uvm_info(get_type_name(),"Push ahb tx transaction -> queue",UVM_MEDIUM)
	    	`uvm_info(get_type_name(),$sformatf("tx_q size: %d", ahb_driver_tx_q.size()),UVM_MEDIUM)
		end
		else
	    	`uvm_info(get_type_name(),"tx_q max size! ",UVM_MEDIUM)
	end


	else if (ahb_trans.addr == 'h01C && ahb_trans.xact_type == ahb_transaction::READ)	begin
		if(uart_tx_q.size >0) begin
        	uart_trans_cmp  = uart_tx_q.pop_back();
			ahb_trans_cmp.data = ahb_trans.data &((1<<(get_num_bits(uart_cfg.data_width)))-1);

			if(ahb_trans_cmp.data != uart_trans_cmp.data) 
		    	`uvm_error(get_type_name(),$sformatf("Data not match: Dir: %s, rhs_driver.data: 0x%0h, monior.data: 0x%0h",uart_trans.direction ,ahb_trans_cmp.data, uart_trans_cmp.data))
			else `uvm_info(get_type_name(),$sformatf("Data match: Dir:%s, rhs_driver.data: 0x%0h, monior.data: 0x%0h",uart_trans.direction,ahb_trans_cmp.data, uart_trans_cmp.data),UVM_LOW)            

		end
//		else `uvm_error(get_type_name(),"uart_tx_q empty! ")
	end
  endfunction: write_ahb_monitor


    local function int get_num_bits(uart_configuration::data_width_enum dw);
        case(dw)
            uart_configuration::D_5b: return 5;
            uart_configuration::D_6b: return 6;
            uart_configuration::D_7b: return 7;
            uart_configuration::D_8b: return 8;
            default: return 8;
        endcase
    endfunction
endclass: uart_scoreboard
