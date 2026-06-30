class ahb_subscriber extends uvm_subscriber #(ahb_transaction);
	`uvm_component_utils(ahb_subscriber)

	ahb_transaction trans;

	covergroup ahb_protocol_cg;
		option.per_instance = 1;
		option.name = "AHB Protocol coverage";

		XFER_SIZE_CP: coverpoint trans.xfer_size{
			bins xfer_size[] = {  trans.SIZE_8BIT  
							   ,trans.SIZE_16BIT  
							   ,trans.SIZE_32BIT  
							   ,trans.SIZE_64BIT  
							   ,trans.SIZE_128BIT 
							   ,trans.SIZE_256BIT 
							   ,trans.SIZE_512BIT 
							   ,trans.SIZE_1024BIT};
		}

		XACT_TYPE_CP: coverpoint trans.xact_type{
			bins xact_type[] = { trans.WRITE
								,trans.READ};
		}

		BURST_TYPE_CP: coverpoint trans.burst_type{
			bins burst_type[] = {
  				  trans.SINGLE  
  				 ,trans.INCR    
  				 ,trans.WRAP4   
  				 ,trans.INCR4   
  				 ,trans.WRAP8   
  				 ,trans.INCR8   
  				 ,trans.WRAP16  
  				 ,trans.INCR16  
			};
		}

		ADDR_CP: coverpoint trans.addr{
			bins valid_range ={[0: 32'h1C]};
			bins reserved_range ={[32'h20: 32'h3FF]};
		}
	
		DATA_CP: coverpoint trans.data{
			bins data_width ={[32'h0: 32'hFFFF_FFFF]};
		}

		//----- CROSS COVERAGE -----
		XACT_X_BRUST: cross XACT_TYPE_CP, BURST_TYPE_CP;
		SIZE_X_BRUST: cross XFER_SIZE_CP, BURST_TYPE_CP;
		XACT_X_ADDR : cross XACT_TYPE_CP, ADDR_CP;
		
endgroup

	function new(string name = "ahb_coverage_subcriber", uvm_component parent = null);
		super.new(name, parent);
		ahb_protocol_cg = new();
	endfunction

	virtual function void write(ahb_transaction t);
		this.trans = t;
		ahb_protocol_cg.sample();
	endfunction


endclass

