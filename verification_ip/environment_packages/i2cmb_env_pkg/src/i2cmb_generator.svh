class i2cmb_generator extends ncsu_component;

  wb_transaction wb_trans;
  i2c_transaction i2c_trans;
  i2c_transaction i2c_alt_trans[64];
  wb_agent agent_wb;
  i2c_agent agent_i2c;

parameter bit [WB_ADDR_WIDTH-1:0] csr_address = 2'b00;
parameter bit [WB_ADDR_WIDTH-1:0] dpr_address = 2'b01;
parameter bit [WB_ADDR_WIDTH-1:0] cmdr_address = 2'b10;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name, parent);
  endfunction

  virtual task run();
   // $display("[Generator] Starting generator run task");
  
    // Continuous read 100-131, 1 transaction with 32 bytes
    i2c_trans = new;
    i2c_trans.i2c_read_data = new[32];
    for (int i = 0; i < 32; i++) begin
      i2c_trans.i2c_read_data[i] = 100 + i;
     // $display("[Generator] Setting i2c_read_data[%0d] = %0d", i, i2c_trans.i2c_read_data[i]);
    end

    // Alternate read 63-0, 64 transactions with 1 byte each
    for (int i = 0; i < 64; i++) begin
      i2c_alt_trans[i] = new;
      i2c_alt_trans[i].i2c_read_data = new[1];
      i2c_alt_trans[i].i2c_read_data[0] = 63 - i;
     // $display("[Generator] Setting i2c_alt_trans[%0d].i2c_read_data[0] = %0d", i, i2c_alt_trans[i].i2c_read_data[0]);
    end
  
    fork // run once to finish
      begin : i2c_flow
        $display("[Generator] Starting i2c_flow");
        
        i2c_trans.op = WRITE;
       // $display("[Generator] Sending WRITE transaction (0-31)");
        agent_i2c.bl_put(i2c_trans);

        i2c_trans.op = READ;
       // $display("[Generator] Sending READ transaction (100-131)");
        agent_i2c.bl_put(i2c_trans);
    
        for (int i = 0; i < 64; i++) begin
          i2c_trans.op = WRITE;
         // $display("[Generator] Sending WRITE transaction %0d (64-127)", i);
          agent_i2c.bl_put(i2c_trans);
          
          i2c_alt_trans[i].op = READ;
         // $display("[Generator] Sending READ transaction %0d (63-0)", i);
          agent_i2c.bl_put(i2c_alt_trans[i]);
        end
        
        $display("[Generator] Finished i2c_flow");
      end
    join_none

    // Setup DUT
   // $display("[Generator] Setting up DUT");
    wb_trans = new;

    // Enable core
    wb_trans.we = 1; wb_trans.wb_addr = csr_address; wb_trans.wb_data = 8'b11xxxxxx;
  //  $display("[Generator] Enabling core: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Set I2C bus ID
    wb_trans.we = 1; wb_trans.wb_addr = dpr_address; wb_trans.wb_data = 8'h05;
   // $display("[Generator] Setting I2C bus ID: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Set Bus command
    wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx110;
    //$display("[Generator] Sending Set Bus command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    $display("[Generator] DUT setup complete");

    // Write 32 incrementing values
    $display("[Generator] Starting write of 32 incrementing values (0-31)");
    
    // Start command
    wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx100;
    //$display("[Generator] Sending Start command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Set slave address for writing
    wb_trans.we = 1; wb_trans.wb_addr = dpr_address; wb_trans.wb_data = 8'h44;
   // $display("[Generator] Setting slave address for writing: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Write command
    wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx001;
    //$display("[Generator] Sending Write command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Write 0 to 31
    for (int i = 0; i < 32; i++) begin
      wb_trans.we = 1; wb_trans.wb_addr = dpr_address; wb_trans.wb_data = i;
      $display("[Generator] Writing data %0d: addr=%0h, data=%0h", i, wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx001;
     // $display("[Generator] Sending Write command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);		
    end

    // Stop command
    wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx101;
   // $display("[Generator] Sending Stop command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);								                

    $display("[Generator] Finished writing 32 incrementing values");

    // Read 32 values
    $display("[Generator] Starting read of 32 values (100-131)");
    
    // Start command
    wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx100;
   // $display("[Generator] Sending Start command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Set slave address for reading
    wb_trans.we = 1; wb_trans.wb_addr = dpr_address; wb_trans.wb_data = 8'h45;
   // $display("[Generator] Setting slave address for reading: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Write command
    wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx001;
   // $display("[Generator] Sending Write command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    // Read 32 times
    for (int i = 0; i < 32; i++) begin
      if (i == 31) begin
        wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx011;
       // $display("[Generator] Sending Read With Nack command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      end else begin
        wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx010;
       // $display("[Generator] Sending Read With Ack command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      end
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 0; wb_trans.wb_addr = dpr_address;
      $display("[Generator] Reading DPR: addr=%0h", wb_trans.wb_addr);
      agent_wb.bl_put(wb_trans);
    end

    // Stop command
    wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx101;
    //$display("[Generator] Sending Stop command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);

    $display("[Generator] Finished reading 32 values");

    // Alternate writes and reads
    $display("[Generator] Starting 64 alternating writes and reads");
    
    for (int i = 0; i < 64; i++) begin
     // $display("[Generator] Alternating write/read iteration %0d", i);
      
      // Write 64 to 127
      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx100;
    //  $display("[Generator] Sending Start command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = dpr_address; wb_trans.wb_data = 8'h44;
    //  $display("[Generator] Setting slave address for writing: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx001;
    //  $display("[Generator] Sending Write command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = dpr_address; wb_trans.wb_data = 64 + i;
     // $display("[Generator] Writing data %0d: addr=%0h, data=%0h", 64+i, wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx001;
     // $display("[Generator] Sending Write command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx101;
     // $display("[Generator] Sending Stop command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      // Read 63 to 0
      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx100;
     // $display("[Generator] Sending Start command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = dpr_address; wb_trans.wb_data = 8'h45;
     // $display("[Generator] Setting slave address for reading: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx001;
     // $display("[Generator] Sending Write command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx011;
     // $display("[Generator] Sending Read With Nack command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 0; wb_trans.wb_addr = dpr_address;
      $display("[Generator] Reading DPR: addr=%0h", wb_trans.wb_addr);
      agent_wb.bl_put(wb_trans);

      wb_trans.we = 1; wb_trans.wb_addr = cmdr_address; wb_trans.wb_data = 8'bxxxxx101;
     // $display("[Generator] Sending Stop command: addr=%0h, data=%0h", wb_trans.wb_addr, wb_trans.wb_data);
      agent_wb.bl_put(wb_trans);
    end
    
    $display("[Generator] Finished 64 alternating writes and reads");
    $display("[Generator] Generator run task complete");
  endtask

  function void set_agent(wb_agent agent_wb, i2c_agent agent_i2c);
    this.agent_wb = agent_wb;
    this.agent_i2c = agent_i2c;
  endfunction

endclass
