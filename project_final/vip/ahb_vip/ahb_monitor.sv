class ahb_monitor extends uvm_monitor;
  `uvm_component_utils(ahb_monitor)

  virtual ahb_if ahb_vif;
    /* Analysis port, send the transaction to scoreboard */
    uvm_analysis_port #(ahb_transaction) item_observed_port;
    ahb_transaction trans;
    ahb_transaction trans_clone;

  function new(string name="ahb_monitor", uvm_component parent);
    super.new(name,parent);
    item_observed_port = new("item_observed_port", this);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    /** Applying the virtual interface received through the config db - learn detail in next session*/
    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    /*Capture interface and convert to transaction level*/

        trans = ahb_transaction::type_id::create("trans");
        trans_clone = ahb_transaction::type_id::create("trans_clone");
        wait(ahb_vif.HRESETn) ;
        
        forever begin
            ahb_bus_monitor();
        end
  endtask: run_phase

    virtual task ahb_bus_monitor();
        `uvm_info(get_type_name(), "Start wait transaction", UVM_MEDIUM);     
        
        do begin
            @(posedge ahb_vif.HCLK); 
        end while (ahb_vif.HTRANS != 2'h2);

		if (ahb_vif.HTRANS == 2'h2)begin
			`uvm_info(get_type_name(), "Detect a transaction!", UVM_MEDIUM);                          
			trans.addr = ahb_vif.HADDR;

			if(ahb_vif.HWRITE) trans.xact_type = ahb_transaction::WRITE;
			else trans.xact_type = ahb_transaction::READ;

            @(posedge ahb_vif.HCLK); #1ps;
            while (ahb_vif.HREADYOUT == 1'b0) begin
                @(posedge ahb_vif.HCLK); 
            end 
           
            if(trans.addr >= 10'h20)begin
                if(ahb_vif.HRESP != 1)begin
                      `uvm_error(get_type_name(),$sformatf("ADDR: 0x%0h, HRESP != 1",trans.addr))
                end
                else begin
                   `uvm_info (get_type_name(),$sformatf("ADDR: 0x%0h, HRESP  = 1", trans.addr),UVM_LOW)            
                    if(trans.xact_type == ahb_transaction::READ ) begin
	
	        			if(trans.xact_type == ahb_transaction::READ && ahb_vif.HRDATA == 32'hFFFF_FFFF) begin
	                        `uvm_info (get_type_name(),$sformatf("RDATA at Reserved Region read back correct") ,UVM_LOW)            
	                    end
						else begin
	                        `uvm_error (get_type_name(),$sformatf("RDATA at Reserved Region read back not correct,Addr: 0x%0h, RDATA: 0x%0h ", trans.data, ahb_vif.HRDATA))            
	                    end
					end
                end
            end
			else begin
				if(trans.xact_type == ahb_transaction::WRITE) trans.data =  ahb_vif.HWDATA ;
				else trans.data =  ahb_vif.HRDATA ;
			end
        end
 

		
		`uvm_info(get_type_name(), "Transaction ended", UVM_MEDIUM);                 
		
		/*Send transaction to scoreboard*/
//		if((trans.addr == 'h018 && trans.xact_type == ahb_transaction::WRITE)||
//		    (trans.addr == 'h01C && trans.xact_type == ahb_transaction::READ))
//		begin
		    `uvm_info(get_type_name(),$sformatf("Packet Sent to Scoreboard: Addr= 0x%0h, Data=0x%0h| Dir= %s",trans.addr,trans.data,trans.xact_type),UVM_MEDIUM);
		    if(get_report_verbosity_level() >= UVM_HIGH)     trans.print();
            $cast(trans_clone, trans.clone());
            trans_clone.data = trans_clone.data & 32'hFF;
		    item_observed_port.write(trans_clone);
//		end
			
        
    endtask: ahb_bus_monitor

endclass: ahb_monitor

