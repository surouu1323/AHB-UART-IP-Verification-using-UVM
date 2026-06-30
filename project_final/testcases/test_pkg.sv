package test_pkg;
	import uvm_pkg::*;
	import uart_pkg::*;
	import ahb_pkg::*;
	import env_pkg::*;
	import seq_pkg::*;
	import uart_regmodel_pkg::*;
	
	`include "uart_base_test.sv"
	
	`include "rst_otf_reg_test.sv"
	`include "default_value_reg_test.sv"
	`include "rw_reg_test.sv"
	`include "reserved_reg_test.sv"
	
	
	`include "uart_half_tx_test.sv"
	`include "uart_half_tx_seq_cfg_test.sv"
	`include "uart_half_tx_ran_cfg_test.sv"
	
	`include "uart_half_rx_test.sv"
	`include "uart_half_rx_seq_cfg_test.sv"
	`include "uart_half_rx_ran_cfg_test.sv"
	
	`include "uart_full_duplex_seq_cfg_test.sv"
	`include "uart_full_duplex_ran_cfg_test.sv"
	
	`include "fifo_tx_test.sv"
	`include "fifo_rx_test.sv"
	  
	`include "uart_interrupt_parity_test.sv"
	`include "uart_multi_interrupt_test.sv"
	`include "uart_corner_baud_jump_test.sv"
	`include "uart_function_otf_test.sv"
	
	`include "uart_single_tx_test.sv"
	`include "uart_multi_tx_test.sv"

endpackage
