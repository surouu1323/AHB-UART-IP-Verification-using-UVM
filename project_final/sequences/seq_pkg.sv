//=============================================================================
// Project       : UART VIP
//=============================================================================
// Filename      : seq_pkg.sv
// Author        : Huy Nguyen
// Company       : NO
// Date          : 20-Dec-2021
//=============================================================================
// Description   : 
//
//
//
//=============================================================================
`ifndef GUARD_UART_SEQ_PKG__SV
`define GUARD_UART_SEQ_PKG__SV

package seq_pkg;
  import uvm_pkg::*;
  import uart_pkg::*;
  import ahb_pkg::*;

  // Include your file
    `include "uart_write_sequence.sv"
    `include "ahb_write_sequence.sv"
    `include "ahb_read_sequence.sv"
    `include "ahb_reserved_sequence.sv"



endpackage: seq_pkg

`endif


