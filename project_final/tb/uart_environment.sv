class uart_environment extends uvm_env;
  `uvm_component_utils(uart_environment)

  virtual uart_if uart_vif;
  uart_configuration uart_cfg;
  uart_scoreboard uart_sb;
  uart_agent      uart_agt;

	ahb_subscriber ahb_cov;
	uart_cfg_subscriber uart_cfg_cov;
	uart_subscriber uart_cov;

  virtual ahb_if  ahb_vif;
  ahb_agent       ahb_agt;
  
  uart_reg_block regmodel;
  uart_reg2ahb_adapter ahb_adapter;

  // Predictor class creation
  uvm_reg_predictor #(ahb_transaction) ahb_predictor;

  function new(string name="uart_environment", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("connect_phase","Entered...",UVM_HIGH)

    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get ahb_vif from uvm_config_db"));

    ahb_agt = ahb_agent::type_id::create("ahb_agt",this);

    ahb_adapter = uart_reg2ahb_adapter::type_id::create("ahb_adapter");
    regmodel = uart_reg_block::type_id::create("regmodel",this);
    regmodel.build();

    ahb_predictor = uvm_reg_predictor#(ahb_transaction)::type_id::create("ahb_predictor",this);

    uvm_config_db#(virtual ahb_if)::set(this,"ahb_agt","ahb_vif",ahb_vif);
    uvm_config_db#(virtual ahb_if)::set(null,"*","ahb_vif",ahb_vif);

    uart_agt = uart_agent::type_id::create("uart_agt", this);
    uart_sb = uart_scoreboard::type_id::create("uart_sb", this);

	ahb_cov = ahb_subscriber::type_id::create("ahb_cov", this);
	uart_cov = uart_subscriber::type_id::create("uart_cov", this);
	uart_cfg_cov = uart_cfg_subscriber::type_id::create("uart_cfg_cov", this);

    //virtual interface received through the config db
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_vif))
      `uvm_fatal(get_type_name(),$sformatf("failed to get uart_vif from uvm_config_db. please check!"));
    
    uvm_config_db#(virtual uart_if)::set(this,"uart_agt","uart_vif" ,uart_vif);

    //uart configuration received through the config db
    if(!uvm_config_db#(uart_configuration)::get(this,"","uart_cfg",uart_cfg))
      `uvm_fatal(get_type_name(),$sformatf("failed to get uart_cfg from uvm_config_db. please check!"));

    uvm_config_db#(uart_configuration)::set(this,"uart_agt","uart_cfg" ,uart_cfg);

    `uvm_info("connect_phase","Exiting...",UVM_HIGH)

    uart_cfg_cov.sample_config(uart_cfg);
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(regmodel.get_parent() == null)begin
      regmodel.ahb_map.set_sequencer(ahb_agt.sequencer, ahb_adapter);
      regmodel.ahb_map.set_auto_predict(1);
    end
    // Predictor connection
    ahb_predictor.map = regmodel.ahb_map;
    ahb_predictor.adapter = ahb_adapter;
    ahb_agt.monitor.item_observed_port.connect(ahb_predictor.bus_in);

    // Connect to subscirber
    ahb_agt.monitor.item_observed_port.connect(ahb_cov.analysis_export);
    uart_agt.monitor.item_observed_port.connect(uart_cov.analysis_export);

    
    /*Connect to scoreboard*/
     ahb_agt.monitor.item_observed_port.connect (uart_sb.ahb_mon_collected_export);
    uart_agt.monitor.item_observed_port.connect (uart_sb.uart_mon_collected_export);

    `uvm_info("build_phase","Exiting...",UVM_HIGH);

  endfunction: connect_phase

endclass
