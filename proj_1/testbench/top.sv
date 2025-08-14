`timescale 1ns / 10ps

import type_pkg::*;

`define test_1
`define test_2
`define test_3
`define i2c_mon

module top();

parameter int I2C_SLAVE_ADDR_SIZE = 7;
parameter int I2C_BYTE_SIZE = 8;
parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 2;
parameter bit [WB_ADDR_WIDTH-1:0] csr_address = 2'b00;
parameter bit [WB_ADDR_WIDTH-1:0] dpr_address = 2'b01;
parameter bit [WB_ADDR_WIDTH-1:0] cmdr_address = 2'b10;
parameter bit [WB_DATA_WIDTH-1:0] I2C_SLAVE_ADDRESS = 8'h20;
parameter bit [WB_DATA_WIDTH-1:0] MEMORY_ADDRESS = 8'h20;
parameter int BUS_NUMBER = 0;

bit  clk;
bit transfer_complete;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;

i2c_op_t ops;

wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
triand  [NUM_I2C_BUSSES-1:0] sda;

bit [WB_DATA_WIDTH-1:0] write_data_slave [];

int i;
int j;

bit [WB_ADDR_WIDTH-1:0] address_monitor;
bit [WB_DATA_WIDTH-1:0] data_monitor;
bit we_mon;
bit [WB_DATA_WIDTH-1:0] cmdr;
bit [I2C_SLAVE_ADDR_SIZE-1:0]   addr;
i2c_op_t op_mon;
bit [I2C_BYTE_SIZE-1:0] data [];
bit [WB_DATA_WIDTH-1:0] data_slave [];

initial clk_gen : begin
  clk = 1'b1;
  forever begin
    #10 clk = ~clk;
  end
end

initial rst_gen : begin
  rst = 1'b1;
  #113
  rst = 1'b0;
end

// Wishbone bus monitoring
always @(posedge clk) begin : wb_monitoring
  wb_bus.master_monitor(address_monitor, data_monitor, we_mon);
  `ifdef MASTER_MONITOR
    if (we_mon)
      $display("[MASTER ACTION] Write Operation: Address 0x%2h, Data 0x%2h (Decimal: %0d)", address_monitor, data_monitor, data_monitor);
    else
      $display("[MASTER ACTION] Read Operation: Address 0x%2h, Data 0x%2h (Decimal: %0d)", address_monitor, data_monitor, data_monitor);
  `endif
end

// I2C bus monitoring
always @(posedge clk) begin : monitor_i2c_bus
  i2c_if_bus.monitor(addr, op_mon, data);
  `ifdef i2c_mon
    if (op_mon == READ)
      $display("[I2C BUS] READ Operation: Address 0x%2h, Data %p", addr, data);
    else
      $display("[I2C BUS] WRITE Operation: Address 0x%2h, Data %p", addr, data);
  `endif
end

// Master test flow
initial begin : master_test_flow
  bit [WB_DATA_WIDTH-1:0] data [];
  bit [WB_DATA_WIDTH-1:0] read_data_alt [];
  bit [WB_DATA_WIDTH-1:0] write_data_alt [];

  #120

  wb_bus.master_write(csr_address, 8'b11000000);
  $display("[MASTER] Initialized CSR with 0xC0");

  `ifdef test_1
    $display("[MASTER] Running Test 1: Writing 32 sequential values (0 to 31) to the I2C bus...");
    data = new[32];
    for (i = 0; i < data.size(); i++) begin
      data[i] = i;
    end
    $display("[MASTER] Test 1: Writing data %p to I2C bus", data);
    write_i2c_data(I2C_SLAVE_ADDRESS, data, BUS_NUMBER);
    $display("[MASTER] Test 1 Completed: Successfully wrote 32 values to I2C bus.");
  `endif

  `ifdef test_2
    $display("[MASTER] Running Test 2: Reading 32 values (100 to 131) from the I2C bus...");
    data = new[32];
    read_i2c_data(I2C_SLAVE_ADDRESS, BUS_NUMBER, 32, data);
    $display("[MASTER] Test 2: Read data %p from I2C bus", data);
    $display("[MASTER] Test 2 Completed: Successfully read 32 values from I2C bus.");
  `endif

  `ifdef test_3
    $display("[MASTER] Running Test 3: Perform 64 transfers alternating between writing and reading...");
    read_data_alt = new[1];
    write_data_alt = new[1];
    for (i = 0; i < 64; i++) begin
      write_data_alt[0] = i + 64;
      $display("[MASTER] Test 3: Writing value %p", write_data_alt);
      write_i2c_data(I2C_SLAVE_ADDRESS, write_data_alt, BUS_NUMBER);
      read_i2c_data(I2C_SLAVE_ADDRESS, BUS_NUMBER, 1, read_data_alt);
      $display("[MASTER] Test 3: Read value %p", read_data_alt);
    end
    $display("[MASTER] Test 3 Completed: All 64 write/read operations were successfully executed.");
  `endif

  #1000
  $display("[MASTER] All tests completed. Finishing simulation.");
  $finish();
end

// Slave test flow
// Slave test flow
initial begin : slave_test_flow
  i2c_op_t ops;
  bit transfer_complete;
  bit [WB_DATA_WIDTH-1:0] write_data_slave[];
  bit [WB_DATA_WIDTH-1:0] data_slave[];

  // Test 1: write 0-31
  $display("[SLAVE] Initiating Slave Test 1: Awaiting transfer to begin...");
  i2c_if_bus.wait_for_i2c_transfer(ops, write_data_slave);
  $display("[SLAVE] Test 1: Received operation %s, Data %p", ops.name(), write_data_slave);

  // Test 2: read 100-131
  $display("[SLAVE] Initiating Slave Test 2: Preparing data for transmission...");
  i2c_if_bus.wait_for_i2c_transfer(ops, write_data_slave);
  
  data_slave = new[1];
  data_slave[0] = 100;

  if (ops == READ) begin
    $display("[SLAVE] Test 2: Beginning read operation");
    while (!transfer_complete) begin
      i2c_if_bus.provide_read_data(data_slave, transfer_complete);
      data_slave[0]++;
    end
    transfer_complete = 1'b0;
    $display("[SLAVE] Test 2: Read operation completed");
  end

  // Test 3: Alternating write 64-127 and read 63-0
  $display("[SLAVE] Initiating Slave Test 3: Performing 128 read/write cycles...");
  for (int i = 0; i < 64; i++) begin
    i2c_if_bus.wait_for_i2c_transfer(ops, write_data_slave); // write 64-127
    $display("[SLAVE] Test 3: Received write data %p", write_data_slave);
    
    i2c_if_bus.wait_for_i2c_transfer(ops, write_data_slave); // read 63-0
    data_slave[0] = 63 - i;
    i2c_if_bus.provide_read_data(data_slave, transfer_complete);
    $display("[SLAVE] Test 3: Provided read data %p", data_slave);
  end
  $display("[SLAVE] Slave Test 3: All 128 read/write operations completed successfully.");
end


task write_i2c_data(
  bit [WB_DATA_WIDTH-1:0] address,
  bit [WB_DATA_WIDTH-1:0] write_data [],
  int bus_no
);
  int i;

  wb_bus.master_write(dpr_address,bus_no);
  wb_bus.master_write(cmdr_address,8'b00000110);
  interrupt_check();
  wb_bus.master_write(cmdr_address, 8'b00000100);
  interrupt_check();

  wb_bus.master_write(dpr_address, address << 1);
  wb_bus.master_write(cmdr_address, 8'b00000001);

  interrupt_check();

  for(i = 0; i < write_data.size(); i++) begin
    wb_bus.master_write(dpr_address, write_data[i]);
    wb_bus.master_write(cmdr_address, 8'b00000001);
    interrupt_check();
  end
  wb_bus.master_write(cmdr_address, 8'b00000101);
  interrupt_check();
endtask

task read_i2c_data(
  bit [WB_DATA_WIDTH-1:0] address,
  int bus_no,
  int read_num,
  output bit [WB_DATA_WIDTH-1:0] read_data []
);
  int i;
  wb_bus.master_write(dpr_address,bus_no);
  wb_bus.master_write(cmdr_address,8'b00000110);
  interrupt_check();
  wb_bus.master_write(cmdr_address, 8'b00000100);
  interrupt_check();

  wb_bus.master_write(dpr_address, (address << 1) | 8'd1);
  wb_bus.master_write(cmdr_address, 8'b00000001);

  interrupt_check();

  for(i = 0; i < read_num-1; i++) begin
    wb_bus.master_write(cmdr_address, 8'b00000010);
    interrupt_check();
    wb_bus.master_read(dpr_address, read_data[i]);
  end

  wb_bus.master_write(cmdr_address, 8'b00000011);
  interrupt_check();
  wb_bus.master_read(dpr_address, read_data[read_num-1]);
  wb_bus.master_write(cmdr_address, 8'b00000101);
  interrupt_check();
endtask

task interrupt_check();
  cmdr = 8'h00;
  while(!irq) @(posedge clk);
  wb_bus.master_read(cmdr_address, cmdr);

  `ifdef MASTER_MONITOR
    @(posedge clk)
  `endif
endtask

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


endmodule
