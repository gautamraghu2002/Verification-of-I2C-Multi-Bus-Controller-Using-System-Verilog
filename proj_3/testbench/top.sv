module top;

  import type_pkg::*;
  import ncsu_pkg::*;
  import wb_pkg::*;
  import i2c_pkg::*;
  import i2cmb_env_pkg::*;

  parameter int WB_ADDR_WIDTH = 2;
  parameter int WB_DATA_WIDTH = 8;
  parameter int NUM_I2C_BUSSES = 1;
  parameter int I2C_ADDR_WIDTH = 7;
  parameter int I2C_DATA_WIDTH = 8;

  bit  clk;
  bit  rst = 1'b1;
  wire cyc;
  wire stb;
  wire we;
  tri1 ack;
  wire [WB_ADDR_WIDTH-1:0] adr;
  wire [WB_DATA_WIDTH-1:0] dat_wr_o;
  wire [WB_DATA_WIDTH-1:0] dat_rd_i;
  wire irq;
  tri  [NUM_I2C_BUSSES-1:0] scl; 
  triand  [NUM_I2C_BUSSES-1:0] sda; 

  // Clock generator
  initial begin: clk_gen
    forever #5ns clk <= ~clk;
  end

  // Reset generator
  initial begin: rst_gen
    #113ns rst = 1'b0;
  end

  // Instantiate the I2C slave Bus Functional Model
  i2c_if i2c_bus (
  .rst_i(rst),
  .scl(scl[0]),
  .sda(sda[0]),
  .sda_o(sda[0])
  );


  wb_if #(
    .ADDR_WIDTH(WB_ADDR_WIDTH),
    .DATA_WIDTH(WB_DATA_WIDTH)
  ) wb_bus (
    // System signals
    .clk_i(clk),
    .rst_i(rst),
    // Master signals
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .adr_o(adr),
    .we_o(we),
    .irq_i(irq),
    // Slave signals
    .cyc_i(),
    .stb_i(),
    .ack_o(),
    .adr_i(),
    .we_i(),
    // Shared signals
    .dat_o(dat_wr_o),
    .dat_i(dat_rd_i)
  );

  // Instantiate the DUT - I2C Multi-Bus Controller
  \work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT (
    // Wishbone signals
    .clk_i(clk),
    .rst_i(rst),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ack),
    .adr_i(adr),
    .we_i(we),
    .dat_i(dat_wr_o),
    .dat_o(dat_rd_i),
    // Interrupt request
    .irq(irq),
    // I2C interfaces
    .scl_i(scl),
    .sda_i(sda),
    .scl_o(scl),
    .sda_o(sda)
  );

  i2cmb_test test_proj2;

  //Flow of the simulation
  initial begin: test_flow
    ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH, I2C_DATA_WIDTH))::set("tst.env.i2c_agent", i2c_bus);
    ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("tst.env.wb_agent", wb_bus);
    test_proj2 = new("tst", null);
    wait (rst == 0); 
    test_proj2.run();
    #1000ns $finish();
  end

endmodule