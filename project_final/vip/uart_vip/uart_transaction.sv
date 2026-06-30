class uart_transaction extends uvm_sequence_item;

    typedef enum bit{
        WRITE = 0,
        READ  = 1
    }direction_enum;

    rand direction_enum direction;
    rand bit[8:0] data;

    `uvm_object_utils_begin (uart_transaction)
        `uvm_field_enum     (direction_enum, direction, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int      (data                     , UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end


    function new(string name="uart_transaction");
        super.new(name);
    endfunction: new

endclass: uart_transaction
