`timescale 1ns / 10ps

module top();
  parameter int WB_ADDR_WIDTH = 2;
  parameter int WB_DATA_WIDTH = 8;
  parameter int NUM_I2C_BUSSES = 1;
  parameter bit [WB_DATA_WIDTH-1:0] SLAVE_ADDRESS = 8'h22;

  bit clk;
  bit rst = 1'b1;
  wire cyc;
  wire stb;
  wire we;
  tri1 ack;
  wire [WB_ADDR_WIDTH-1:0] adr;
  wire [WB_DATA_WIDTH-1:0] dat_wr_o;
  wire [WB_DATA_WIDTH-1:0] dat_rd_i;
  wire irq;
  tri [NUM_I2C_BUSSES-1:0] scl;
  tri [NUM_I2C_BUSSES-1:0] sda;
  logic [WB_ADDR_WIDTH-1:0] address_monitor;
  logic [WB_ADDR_WIDTH-1:0] csr_address = 2'b00;
  logic [WB_ADDR_WIDTH-1:0] cmdr_address = 2'b10;
  logic [WB_ADDR_WIDTH-1:0] dpr_address = 2'b01;
  logic [WB_DATA_WIDTH-1:0] data_readwrite_monitor;
  logic [WB_DATA_WIDTH-1:0] read_data;
  logic write_enable_monitor;

  // Clock generator
  initial begin : clk_gen
    clk = 0;
    forever #10 clk = ~clk;
  end : clk_gen

  // Reset generator
  initial begin : rst_gen
    #113 rst = 1'b0;
  end : rst_gen

  initial begin : wb_monitoring
    forever @(posedge clk) begin
      wb_bus.master_monitor(address_monitor, data_readwrite_monitor, write_enable_monitor);
      $display("Address monitor: %h, Data Read/Write monitor: %h", address_monitor, data_readwrite_monitor);
    end
  end : wb_monitoring

initial begin : test_flow
  #120
  wb_bus.master_write(csr_address, 8'b11000000);

  wb_bus.master_write(dpr_address, 8'h05);

  wb_bus.master_write(cmdr_address, 8'b00000110);
 
  interrupt_check();

  wb_bus.master_write(cmdr_address, 8'b00000100);

  interrupt_check();

  wb_bus.master_write(dpr_address, {SLAVE_ADDRESS, 1'b0});

  wb_bus.master_write(cmdr_address, 8'b00000001);

  interrupt_check();

  wb_bus.master_write(dpr_address, 8'h78);

  wb_bus.master_write(cmdr_address, 8'b00000001);

  interrupt_check();

  wb_bus.master_write(cmdr_address, 8'b00000101);

  interrupt_check();

  $finish;
end : test_flow

task interrupt_check();
    read_data = 8'h00;
    while(!irq) @(posedge clk);
    wb_bus.master_read(cmdr_address, read_data);
    @(posedge clk);
endtask


  // Instantiate the Wishbone master Bus Functional Model
  wb_if #(
    .ADDR_WIDTH(WB_ADDR_WIDTH),
    .DATA_WIDTH(WB_DATA_WIDTH)
  )
  wb_bus (
    .clk_i(clk),
    .rst_i(rst),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .adr_o(adr),
    .we_o(we),
    .cyc_i(),
    .stb_i(),
    .ack_o(),
    .adr_i(),
    .we_i(),
    .dat_o(dat_wr_o),
    .dat_i(dat_rd_i)
  );

  // Instantiate the DUT - I2C Multi-Bus Controller
  \work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT (
    .clk_i(clk),
    .rst_i(rst),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ack),
    .adr_i(adr),
    .we_i(we),
    .dat_i(dat_wr_o),
    .dat_o(dat_rd_i),
    .irq(irq),
    .scl_i(scl),
    .sda_i(sda),
    .scl_o(scl),
    .sda_o(sda)
  );

endmodule
