class ahb_driver extends uvm_driver #(ahb_transaction);
  `uvm_component_utils(ahb_driver)

  virtual ahb_if ahb_vif;

  function new(string name="ahb_driver", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    /** Applying the virtual interface received through the config db - learn detail in next session*/
    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))
  endfunction: build_phase

  /** User can use ahb_vif to control real interface like systemverilog part*/
  virtual task run_phase(uvm_phase phase);
     wait(ahb_vif.HRESETn) ;

    forever begin
        ahb_bus_driver();
    end
  endtask: run_phase

    virtual task ahb_bus_driver();
        `uvm_info(get_type_name(), "Start wait packet", UVM_MEDIUM);

        seq_item_port.get(req);
        
        `uvm_info(get_type_name(), "Got packet from sequencer", UVM_MEDIUM);
        if (get_report_verbosity_level() >= UVM_HIGH)req.print();

        @(posedge ahb_vif.HCLK); #1ps;
        ahb_vif.HADDR = req.addr;
        if(req.xact_type == ahb_transaction::WRITE) ahb_vif.HWRITE = 1;
        else ahb_vif.HWRITE = 0;

        ahb_vif.HPROT  = 4'h4;
        ahb_vif.HSIZE  = 3'h2;
        ahb_vif.HTRANS  = 2'h2;
        ahb_vif.HBURST = 3'h0;

        @(posedge ahb_vif.HCLK); #1ps;
        if(req.xact_type == ahb_transaction::WRITE)   ahb_vif.HWDATA = req.data;
        ahb_vif.HWRITE = 0;
        ahb_vif.HADDR  = 0;

        ahb_vif.HPROT  = 0;
        ahb_vif.HSIZE  = 0;
        ahb_vif.HTRANS = 0;
        ahb_vif.HBURST = 0;


        @(posedge ahb_vif.HCLK iff ahb_vif.HREADYOUT); #1ps;

        if(req.xact_type == ahb_transaction::READ)begin
            @(posedge ahb_vif.HCLK);
                req.data = ahb_vif.HRDATA;
        end

        //Create rsq
        $cast(rsp, req.clone());
        rsp.set_id_info(req);
        seq_item_port.put(rsp);
        `uvm_info(get_type_name(), "Done driving", UVM_MEDIUM);

    endtask: ahb_bus_driver


endclass: ahb_driver

