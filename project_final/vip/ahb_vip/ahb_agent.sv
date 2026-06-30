class ahb_agent extends uvm_agent;
  `uvm_component_utils(ahb_agent)

  virtual ahb_if ahb_vif;
  ahb_monitor   monitor;
  ahb_driver    driver;
  ahb_sequencer sequencer;

  function new(string name="ahb_agent", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

 
    /** applying the virtual interface received through the config db - learn detail in next session*/
    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("failed to get ahb_vif from uvm_config_db. please check!"))

    if(is_active == UVM_ACTIVE) begin
      `uvm_info(get_type_name(),$sformatf("Active agent is configued"),UVM_MEDIUM)
      driver = ahb_driver::type_id::create("driver", this);
      sequencer = ahb_sequencer::type_id::create("sequencer", this);
      monitor = ahb_monitor::type_id::create("monitor", this);

    uvm_config_db#(virtual ahb_if)::set(this,"driver","ahb_vif",ahb_vif);
    uvm_config_db#(virtual ahb_if)::set(this,"monitor","ahb_vif",ahb_vif);


    end
    else begin
      `uvm_info(get_type_name(),$sformatf("Passive agent is configued"),UVM_MEDIUM)
//      monitor = ahb_monitor::type_id::create("monitor", this);
    end

  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE) begin 
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction: connect_phase

endclass: ahb_agent
