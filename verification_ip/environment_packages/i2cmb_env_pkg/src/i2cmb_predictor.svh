class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

  ncsu_component#(.T(i2c_transaction)) scoreboard;
  i2c_transaction transport_trans;
  i2cmb_env_configuration configuration;

  bit [I2C_DATA_WIDTH-1:0] write_data[$];
  bit [I2C_DATA_WIDTH-1:0] read_data[$];
  bit [1:0] state;
  parameter [1:0] start_state       = 2'b00,
		              addr_state        = 2'b01,
                  write_state       = 2'b10,
                  read_state        = 2'b11;

  bit [I2C_DATA_WIDTH-1:0] dpr_reg;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void set_scoreboard(ncsu_component #(.T(i2c_transaction)) scoreboard);
      this.scoreboard = scoreboard;
  endfunction

 virtual function void nb_put(T trans);

  if(trans.wb_addr == 1 && trans.we == 1) begin
    dpr_reg = trans.wb_data;
  end

  if (state == start_state) begin
    if (trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b100 && trans.we == 1) begin
      state = addr_state;
    end
  end
  else if (state == addr_state) begin
    if (trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b001 && trans.we == 1) begin
      transport_trans = new;
      transport_trans.i2c_address = dpr_reg[7:1];
      if (!dpr_reg[0]) transport_trans.op = WRITE;
      else transport_trans.op = READ;
      if (!dpr_reg[0]) state = write_state;
      else state = read_state;
    end
  end
  else if (state == write_state) begin
    if (trans.wb_addr == 1 && trans.we == 1) begin
      write_data.push_back(dpr_reg);
      state = write_state;
    end
    else if (trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b101 && trans.we == 1) begin
      state = start_state;
      transport_trans.i2c_data_compare = new[write_data.size()];
      foreach (transport_trans.i2c_data_compare[i]) transport_trans.i2c_data_compare[i] = write_data.pop_front();
      scoreboard.nb_transport(transport_trans, null);
      write_data.delete();
    end
  end
  else if (state == read_state) begin
    if (trans.wb_addr == 1 && trans.we == 0) begin
      read_data.push_back(trans.wb_data);
      state = read_state;
    end
    else if (trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b101 && trans.we == 1) begin
      state = start_state;
      transport_trans.i2c_data_compare = new[read_data.size()];
      foreach (transport_trans.i2c_data_compare[i]) transport_trans.i2c_data_compare[i] = read_data.pop_front();
      scoreboard.nb_transport(transport_trans, null);
      read_data.delete();
    end
  end
  else begin
    state = start_state;
  end
endfunction

endclass