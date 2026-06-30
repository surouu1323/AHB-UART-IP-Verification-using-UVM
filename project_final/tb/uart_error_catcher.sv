class uart_error_catcher extends uvm_report_catcher;
    `uvm_object_utils(uart_error_catcher)

    string error_msg_q[$];

    function new(string name="uart_error_catcher");
        super.new(name);
    endfunction

    /** Implement catcher in this function */
    virtual function action_e catch();
        string str_cmp;

        if(get_severity() == UVM_ERROR)begin
            foreach(error_msg_q[i]) begin
                str_cmp = error_msg_q[i];
                // if (get_message() == str_cmp) begin
                if (uvm_is_match($sformatf("%s*", str_cmp), get_message())) begin
                    set_severity(UVM_INFO);
                    `uvm_info("REPORT_CATCHER", $sformatf("Demoted below error message: %s",str_cmp), UVM_NONE)
                end
            end
        end
        return THROW;
    endfunction

    /** User will add which messages they want to demote*/
    virtual function void add_error_catcher_msg(string str);
        error_msg_q.push_back(str);
        // `uvm_info(get_type_name(),$sformatf("Message: %s", str),UVM_HIGH)
    endfunction


endclass: uart_error_catcher
