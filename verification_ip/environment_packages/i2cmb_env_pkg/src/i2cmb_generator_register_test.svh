class i2cmb_generator_register_test extends i2cmb_generator;
  `ncsu_register_object(i2cmb_generator_register_test);
  
  wb_transaction wb_trans;

  bit [WB_DATA_WIDTH-1:0] pre_core[4]; // test plan 1.5
  bit [WB_DATA_WIDTH-1:0] post_core[4]; // test plan 1.1
  bit [WB_DATA_WIDTH-1:0] post_write[4]; // test plan 1.4

  function new(string name="", ncsu_component_base parent=null);
			super.new(name, parent);
  endfunction 

  virtual task run();

    $display("--------------------------");
    $display("Test Plan 1: Register Test");
    $display("--------------------------");

    // test plan 1.2 : Register Address
    // Should refer to all other test cases

    // test plan 1.5 : Register Default Values
    // Registers should have default values before enabling core

    $display("----------Test Plan 1.5: Register default Values----------");

    wb_trans = new;

    // default register values before enabling core
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    pre_core[0] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    pre_core[1] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    pre_core[2] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    pre_core[3] = wb_trans.wb_data;

    if(pre_core[0] == 8'b00000000 &&
      pre_core[1] == 8'b00000000 &&
      pre_core[2] == 8'b10000000 &&
      pre_core[3] == 8'b00000000) $display("Test Plan 1.5 Passed");

    else $display("Test Plan 1.5 failed");

    // test plan 1.1 : Register Core Reset
    // DPR, CMDR, and FSMR registers should reset to default after enabling core

    $display("----------Test Plan 1.1: Register Core Reset----------");

    wb_trans = new;

    // enable core
    wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'b11xxxxxx;
    agent_wb.bl_put(wb_trans);

    // read register values before writing
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_core[0] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_core[1] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_core[2] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_core[3] = wb_trans.wb_data;

    if(post_core[0] == 8'b11000000 &&
      post_core[1] == 8'b00000000 &&
      post_core[2] == 8'b10000000 &&
      post_core[3] == 8'b00000000) 
      $display("Test Plan 1.1 Passed");
    else $display("Test Plan 1.1 failed");

    // test plan 1.4 : Register Aliasing
    // Writing to 1 register should not affect the others

    $display("----------Test Plan 1.4: Register Aliasing----------");

    wb_trans = new;

    wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_write[1] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_write[2] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_write[3] = wb_trans.wb_data;

    if(post_write[1] == 8'b00000000 &&
      post_write[2] == 8'b10000000 &&
      post_write[3] == 8'b00000000) 
      $display("Test Plan 1.4: CSR Passed");
    else $display("Test Plan 1.4: CSR failed");

    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_write[0] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_write[2] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_write[3] = wb_trans.wb_data;

    if(post_write[0] == 8'b11000000 &&
      post_write[2] == 8'b10000000 &&
      post_write[3] == 8'b00000000) 
      $display("Test Plan 1.4: DPR Passed");

    else $display("Test Plan 1.4: DPR failed");

    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_write[0] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_write[1] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_write[3] = wb_trans.wb_data;

    if(post_write[0] == 8'b11000000 &&
      post_write[1] == 8'b00000000 &&
      post_write[3] == 8'b00000000) 
      $display("Test Plan 1.4: CMDR Passed");
    else $display("Test Plan 1.4: CMDR failed");

    wb_trans.we = 1; wb_trans.wb_addr = 3; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_write[0] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_write[1] = wb_trans.wb_data;

    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_write[2] = wb_trans.wb_data;

    if(post_write[0] == 8'b11000000 &&
      post_write[1] == 8'b00000000 &&
      post_write[2] == 8'b00010111) 
      $display("Test Plan 1.4: FSMR Passed");
    else $display("Test Plan 1.4: FSMR failed");

    // test plan 1.3 : Register Permissions 
    // Access permissions for CSR and DPR should follow specifications

    $display("----------Test Plan 1.3: Register Permissions----------");

    wb_trans = new; 

    wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);
    wb_trans.we = 0;
    agent_wb.bl_put(wb_trans);

    if(wb_trans.wb_data == 8'b11000000) $display("Test Plan 1.3: CSR Passed");
    else $display("Test Plan 1.3: CSR failed");

    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);
    wb_trans.we = 0;
    agent_wb.bl_put(wb_trans);

    if(wb_trans.wb_data == 8'b00000000) $display("Test Plan 1.3: DPR Passed");
    else $display("Test Plan 1.3: DPR failed");

  endtask

endclass
