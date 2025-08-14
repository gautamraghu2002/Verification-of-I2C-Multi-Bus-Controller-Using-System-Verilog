class i2c_driver extends ncsu_component#(.T(i2c_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual i2c_if #(I2C_ADDR_WIDTH, I2C_DATA_WIDTH) bus;
  i2c_configuration configuration;
  i2c_transaction i2c_trans;

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);

    if(trans.op == WRITE) begin
      bus.wait_for_i2c_transfer(trans.op, trans.i2c_write_data); 
    end
    if(trans.op == READ) begin
      bus.wait_for_i2c_transfer(trans.op, trans.i2c_write_data);
      while(!trans.transfer_complete) begin
        bus.provide_read_data(trans.i2c_read_data, trans.transfer_complete);
      end
      trans.transfer_complete = 0;
    end 
      
  endtask

endclass