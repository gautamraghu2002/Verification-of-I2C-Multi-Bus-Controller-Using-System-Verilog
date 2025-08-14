import type_pkg::*;

class i2c_transaction extends ncsu_transaction;

  parameter int I2C_ADDR_WIDTH = 7;
  parameter int I2C_DATA_WIDTH = 8;

  i2c_op_t op;
  bit [I2C_DATA_WIDTH-1:0] i2c_write_data[];
  bit [I2C_DATA_WIDTH-1:0] i2c_read_data[];
  bit [I2C_ADDR_WIDTH-1:0] i2c_address;
  bit transfer_complete;

  bit [I2C_DATA_WIDTH-1:0] i2c_data_compare[];

  function new(string name = ""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
    return {super.convert2string(),$sformatf("i2c_address:0x%x op:0x%x i2c_data_compare:%p", i2c_address, op, i2c_data_compare)};
  endfunction

  function bit compare(i2c_transaction rhs);
    return ((this.i2c_address == rhs.i2c_address) && 
            (this.op == rhs.op) &&
            (this.i2c_data_compare == rhs.i2c_data_compare) );
  endfunction

endclass
