class uart_cfg_subscriber extends uvm_subscriber #(uart_configuration);
	`uvm_component_utils(uart_cfg_subscriber)

	uart_configuration uart_cfg;

	covergroup uart_cfg_cg;
		option.per_instance = 1;
		option.name = "UART Config coverage";

		PARITY_CP: coverpoint uart_cfg.parity_mode{
			bins p_mode[] = {uart_cfg.ODD, uart_cfg.EVEN, uart_cfg.NONE};
		}
		
		DATA_WIDTH_CP: coverpoint uart_cfg.data_width{
			bins d_width[] = {uart_cfg.D_5b, uart_cfg.D_6b, uart_cfg.D_7b, uart_cfg.D_8b};
		}

		STOP_BIT_CP: coverpoint uart_cfg.stop_bit{
			bins s_bits[] = {uart_cfg.STOP_1BIT, uart_cfg.STOP_2BIT};
		}

		SAMPLING_CP: coverpoint uart_cfg.sampling_mode{
			bins s_modes[] = {uart_cfg.M_16x, uart_cfg.M_13x};
		}

		BAUD_RATE_CP: coverpoint uart_cfg.baud_rate{
			bins b_rates[] = {uart_cfg.B_2400, uart_cfg.B_4800, uart_cfg.B_9600, uart_cfg.B_19200, uart_cfg.B_38400, uart_cfg.B_76800, uart_cfg.B_115200};
		}

		//----- CROSS COVERAGE -----
		CROSS_BAUD_PARITY: cross BAUD_RATE_CP, PARITY_CP;

		CROSS_DATA_PARITY: cross DATA_WIDTH_CP, PARITY_CP;
	
		CROSS_DATA_STOP: cross DATA_WIDTH_CP, STOP_BIT_CP;

endgroup

	function new(string name = "uart_transaction_subcriber", uvm_component parent = null);
		super.new(name, parent);
		uart_cfg_cg = new();
	endfunction

	virtual function void write(uart_configuration t);
		this.uart_cfg = t;
		uart_cfg_cg.sample();
	endfunction

	virtual function void sample_config(uart_configuration t);
		this.uart_cfg = t;
		uart_cfg_cg.sample();
	endfunction

endclass

class uart_subscriber extends uvm_subscriber #(uart_transaction);
	`uvm_component_utils(uart_subscriber)

	uart_transaction trans;

	covergroup uart_trans_cg;
		option.per_instance = 1;
		option.name = "UART transaction coverage";

		DIRECTION_CP: coverpoint trans.direction{
			bins direction[] = {trans.WRITE, trans.READ};
		}

		DATA_CP: coverpoint trans.data{
			bins data[]={[0:8'hFF]};
		}
		

		//----- CROSS COVERAGE -----
		DIRECTION_X_DATA: cross DIRECTION_CP, DATA_CP;

endgroup

	function new(string name = "uart_transaction_subcriber", uvm_component parent = null);
		super.new(name, parent);
		uart_trans_cg = new();
	endfunction

	virtual function void write(uart_transaction t);
		this.trans = t;
		uart_trans_cg.sample();
	endfunction


endclass

