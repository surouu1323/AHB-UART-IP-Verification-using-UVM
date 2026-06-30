class uart_configuration extends uvm_object;

  typedef enum int {
      ODD ,   
      EVEN, 
      NONE
  } parity_mode_enum;

    
  typedef enum int {
      D_5b, 
      D_6b, 
      D_7b, 
      D_8b 
  } data_width_enum;


  typedef enum int {
      STOP_1BIT, 
      STOP_2BIT 
  } stop_bit_enum;


  typedef enum int {
      M_16x, 
      M_13x 
  } sampling_mode_enum;

  typedef enum int {
      B_2400 ,
      B_4800 ,
      B_9600 ,
      B_19200, 
      B_38400, 
      B_76800, 
      B_115200 
  } baud_rate_enum;


	rand parity_mode_enum parity_mode;
	rand data_width_enum    data_width;
	rand stop_bit_enum    stop_bit;
	rand baud_rate_enum   baud_rate; 
	rand sampling_mode_enum sampling_mode;

  `uvm_object_utils_begin (uart_configuration)
    `uvm_field_enum       (parity_mode_enum  	, parity_mode	,UVM_ALL_ON |UVM_HEX )
    `uvm_field_enum       (data_width_enum  	, data_width 	,UVM_ALL_ON |UVM_HEX )
    `uvm_field_enum       (stop_bit_enum    	, stop_bit   	,UVM_ALL_ON |UVM_HEX )
    `uvm_field_enum       (baud_rate_enum    	, baud_rate  	,UVM_ALL_ON |UVM_HEX )
    `uvm_field_enum       (sampling_mode_enum   , sampling_mode  ,UVM_ALL_ON |UVM_HEX )
  `uvm_object_utils_end

  function new(string name="uart_configuration");
    super.new(name);
  endfunction: new

endclass: uart_configuration
