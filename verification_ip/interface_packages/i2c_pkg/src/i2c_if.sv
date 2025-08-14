import type_pkg::*;

interface automatic i2c_if #(
  int I2C_ADDR_WIDTH = 7,
  int I2C_DATA_WIDTH = 8
)(
  input wire rst_i,
  input wire scl,
  input wire sda,
  output wire sda_o
);

  bit sda_bit = 0;
  bit sda_value = 1;
  bit repeated_start = 0;

  int j = 0;
  int bytecount = 0;
  bit stop = 1'b0;
  int data_position = I2C_DATA_WIDTH-1;

  bit [I2C_ADDR_WIDTH-1:0] addr_sda;

  always @(posedge rst_i or negedge rst_i) begin
    sda_bit = 0;
    sda_value = 1;
    repeated_start = 0;
  end

  always begin
    while(repeated_start == 1'b0) begin
      @(negedge sda);
      if(scl && !sda_bit) repeated_start = 1'b1; 
    end
    @(posedge scl);
    repeated_start = 1'b0;
  end

  task wait_for_i2c_transfer(
    output i2c_op_t op,
    output bit [I2C_DATA_WIDTH-1:0] write_data []
  );
    write_data = new[1];
    op = WRITE;

    if(!repeated_start) begin
      do begin
        @(negedge sda);
      end while(!scl);
    end

    for (int i = I2C_ADDR_WIDTH-1; i >= 0; i--) begin
      @(posedge scl);
      addr_sda[i] = sda;
    end

    @(posedge scl);
    op = sda ? READ : WRITE;

    @(posedge scl);

    if(op == WRITE) begin
      fetch_and_check_bus_data(op, 1'b1, write_data);
    end
  endtask

  task fetch_and_check_bus_data(
    input i2c_op_t rw,
    input bit ACK,
    output bit [I2C_DATA_WIDTH-1:0] data []
  );
    automatic int j = 0;
    automatic int bytecount = 0;
    automatic bit stop = 1'b0;
    int data_position = I2C_DATA_WIDTH-1;
    bit [I2C_DATA_WIDTH-1:0] temp_data [];
    temp_data = new[1];

    while(!stop) begin
      @(posedge scl) begin
        temp_data[bytecount][data_position] = sda_value && sda;
        j++;
        data_position--;
        if(j % 8 == 0) begin
          if(ACK) sda_bit_set(1'b0);
          else @(posedge scl);
          data_position = I2C_DATA_WIDTH-1;
          bytecount++;
          temp_data = new[bytecount+1](temp_data);
          j = 0;
        end
      end
      @(negedge scl or posedge sda or negedge sda) begin
        if(scl && !sda_bit) stop = 1'b1;
        else stop = 1'b0;
      end
    end
    data = new[bytecount](temp_data);
  endtask

  task get_slave_info(
    output bit [I2C_ADDR_WIDTH-1:0] address,
    output i2c_op_t op
  );
    int addr_pos;
    int i;
    op = WRITE;
    address = 0;
    addr_pos = I2C_ADDR_WIDTH - 1;
    
    for (i = I2C_ADDR_WIDTH + 1; i > 0; i--) begin
      @(posedge scl) begin
        if (i == 1) begin
        end else if (i == 2) begin
          op = sda ? READ : WRITE;
        end else begin
          address[addr_pos] = sda;
          addr_pos--;
        end
      end
    end
  endtask

  task provide_read_data(
    input bit [I2C_DATA_WIDTH-1:0] read_data [],
    output bit transfer_complete
  );
    transfer_complete = 1'b0;
    for(int i = 0; i < read_data.size(); i++) begin
      for(int j=0; j<I2C_DATA_WIDTH; j++) begin
        sda_bit_set(read_data[i][I2C_DATA_WIDTH-1-j]);
      end
      @(posedge scl);
      transfer_complete = 1'b1;
    end
  endtask

  task sda_bit_set(input bit val);
    sda_value = val;
    @(posedge scl) sda_bit = 1;
    @(negedge scl) begin
      sda_bit = 0;
      sda_value = 1;
    end
  endtask

  task monitor(
    output bit [I2C_ADDR_WIDTH-1:0] addr,
    output i2c_op_t op,
    output bit [I2C_DATA_WIDTH-1:0] data[]
  );
    wait_for_i2c_transfer(op, data);
    addr = addr_sda;
    if(op == READ) begin
      fetch_and_check_bus_data(op, 1'b0, data);
    end
  endtask

  assign sda_o = sda_bit ? sda_value : 1'b1;

endinterface