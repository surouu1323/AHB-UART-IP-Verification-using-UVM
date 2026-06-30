`timescale 1ns/1ps

	interface dut_interrupt();
	  logic interrupt;
	endinterface

module testbench;
  import uvm_pkg::*;
  import test_pkg::*;
  import uart_pkg::*;

  /** Instantiate UART Interface */
  uart_if uart_vif();

  ahb_if ahb_vif();


	dut_interrupt dut_int_vif();

  uart_top u_dut(
                 .HCLK(ahb_vif.HCLK), 
                 .HRESETN(ahb_vif.HRESETn),
                 .HADDR(ahb_vif.HADDR), 
                 .HBURST(ahb_vif.HBURST), 
                 .HTRANS(ahb_vif.HTRANS), 
                 .HSIZE(ahb_vif.HSIZE), 
                 .HPROT(ahb_vif.HPROT), 
                 .HWRITE(ahb_vif.HWRITE), 
                 .HWDATA(ahb_vif.HWDATA),
                 .HSEL(ahb_vif.HSEL),
                 .HREADYOUT(ahb_vif.HREADYOUT), 
                 .HRDATA(ahb_vif.HRDATA), 
                 .HRESP(ahb_vif.HRESP),
                  .uart_rxd(uart_vif.tx),
                  .uart_txd(uart_vif.rx),
                  .interrupt(dut_int_vif.interrupt)
                );

  assign ahb_vif.HSEL = 1'b1;

  initial begin
    ahb_vif.HRESETn = 0;


    ahb_vif.HADDR = 0;    
    ahb_vif.HBURST = 0;   
    ahb_vif.HMASTLOCK = 0;
    ahb_vif.HPROT = 0;    
    ahb_vif.HSIZE = 0;    
    ahb_vif.HTRANS = 0;   
    ahb_vif.HWDATA = 0;   
    ahb_vif.HWRITE = 0;   

    #100ns ahb_vif.HRESETn = 1;
  end


  // 100 MHz
  initial begin
    ahb_vif.HCLK = 0;
    forever begin 
      #5ns;
      ahb_vif.HCLK = ~ahb_vif.HCLK;
    end
  end

  initial begin
  /** Set the VIP interface on the environment */
    uart_vif.tx = 1;
    uvm_config_db#(virtual uart_if)::set(uvm_root::get(),"uvm_test_top","uart_vif",uart_vif);


    /** Set interface to driver to control - Learn in next session*/
    uvm_config_db#(virtual ahb_if)::set(uvm_root::get(),"uvm_test_top","ahb_vif",ahb_vif);

    /** Set interrupt interface */
    uvm_config_db#(virtual dut_interrupt)::set(uvm_root::get(),"uvm_test_top","dut_int_vif",dut_int_vif);

    /** Start the UVM test */
    run_test();
    

  end

endmodule

