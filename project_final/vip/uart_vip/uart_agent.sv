class uart_agent extends uvm_agent;
  `uvm_component_utils(uart_agent)

  virtual uart_if uart_vif;

  uart_monitor   monitor;
  uart_driver    driver;
  uart_sequencer sequencer;
  uart_configuration uart_cfg;


  function new(string name="uart_agent", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("build_phase","Entered...",UVM_MEDIUM)

    //virtual interface received through the config db
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_vif))
      `uvm_fatal(get_type_name(),$sformatf("failed to get uart_vif from uvm_config_db. please check!"))

    if(is_active == UVM_ACTIVE) begin
      `uvm_info(get_type_name(),$sformatf("Active agent is configued"),UVM_MEDIUM)

      uart_cfg = uart_configuration::type_id::create("uart_cfg");

      driver = uart_driver::type_id::create("driver", this);
      sequencer = uart_sequencer::type_id::create("sequencer", this);
      monitor = uart_monitor::type_id::create("monitor", this);

    uvm_config_db#(virtual uart_if)::set(this,"driver" ,"uart_vif",uart_vif);
    uvm_config_db#(virtual uart_if)::set(this,"monitor","uart_vif",uart_vif);


    //uart configuration received through the config db
    if(!uvm_config_db#(uart_configuration)::get(this,"","uart_cfg",uart_cfg))
      `uvm_fatal(get_type_name(),$sformatf("failed to get uart_cfg from uvm_config_db. please check!"))
    
    uvm_config_db#(uart_configuration)::set(this,"driver" ,"uart_cfg",uart_cfg);
    uvm_config_db#(uart_configuration)::set(this,"monitor","uart_cfg",uart_cfg);
    
    end
    else begin
      `uvm_info(get_type_name(),$sformatf("Passive agent is configued"),UVM_MEDIUM)
      monitor = uart_monitor::type_id::create("monitor", this);
    end
    `uvm_info("build_phase","Exiting...",UVM_MEDIUM)

  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE) begin 
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction: connect_phase

endclass: uart_agent
