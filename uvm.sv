`include "uvm_macros.svh"
import uvm_pkg::*;

// --- 1. SEQUENCE ITEM (Constrained Random Stimulus) ---
class alu_item extends uvm_sequence_item;
  rand bit [3:0] a;
  rand bit [3:0] b;
  rand bit [1:0] op;
  bit [4:0] result;

  `uvm_object_utils_begin(alu_item)
    `uvm_field_int(a, UVM_DEFAULT)
    `uvm_field_int(b, UVM_DEFAULT)
    `uvm_field_int(op, UVM_DEFAULT)
    `uvm_field_int(result, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "alu_item");
    super.new(name);
  endfunction
endclass

// --- 2. SEQUENCE ---
class alu_sequence extends uvm_sequence #(alu_item);
  `uvm_object_utils(alu_sequence)
  
  function new(string name = "alu_sequence"); super.new(name); endfunction

  task body();
    repeat(50) begin // Generate 50 random transactions
      req = alu_item::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      finish_item(req);
    end
  endtask
endclass

// --- 3. DRIVER ---
class alu_driver extends uvm_driver #(alu_item);
  `uvm_component_utils(alu_driver)
  virtual alu_if vif;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      vif.a  <= req.a;
      vif.b  <= req.b;
      vif.op <= req.op;
      seq_item_port.item_done();
    end
  endtask
endclass

// --- 4. MONITOR ---
class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)
  virtual alu_if vif;
  uvm_analysis_port #(alu_item) mon_ap;

  function new(string name, uvm_component parent); 
    super.new(name, parent); 
    mon_ap = new("mon_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif);
  endfunction

  task run_phase(uvm_phase phase);
    alu_item item;
    forever begin
      @(posedge vif.clk);
      #1; // Wait for combinational logic to settle
      item = alu_item::type_id::create("item");
      item.a = vif.a;
      item.b = vif.b;
      item.op = vif.op;
      item.result = vif.result;
      mon_ap.write(item); // Broadcast to Scoreboard and Coverage
    end
  endtask
endclass

// --- 5. COVERAGE COLLECTOR (Your Main Focus) ---
class alu_coverage extends uvm_subscriber #(alu_item);
  `uvm_component_utils(alu_coverage)
  alu_item item;

  covergroup alu_cg;
    // 1. Are we hitting all ALU operations?
    option.per_instance = 1;
    cp_op: coverpoint item.op {
      bins ADD = {2'b00};
      bins SUB = {2'b01};
      bins AND = {2'b10};
      bins OR  = {2'b11};
    }
    // 2. Are we testing interesting edge cases for inputs?
    cp_a: coverpoint item.a {
      bins zero = {4'h0};
      bins max  = {4'hF};
      bins others = {[4'h1:4'hE]};
    }
    cp_b: coverpoint item.b {
      bins zero = {4'h0};
      bins max  = {4'hF};
      bins others = {[4'h1:4'hE]};
    }
    // 3. Cross Coverage: Are we testing every operation with every type of input?
    cross_op_a: cross cp_op, cp_a;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    alu_cg = new();
  endfunction

  function void write(alu_item t);
    item = t;
    alu_cg.sample(); // Sample the data to calculate coverage %
  endfunction



   virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_RESULTS", $sformatf("=============================================="), UVM_LOW)
    `uvm_info("COV_RESULTS", $sformatf("  TOTAL COVERAGE: %0.2f%%", alu_cg.get_inst_coverage()), UVM_LOW)
    `uvm_info("COV_RESULTS", $sformatf("  OP Coverpoint:  %0.2f%%", alu_cg.cp_op.get_coverage()), UVM_LOW)
    `uvm_info("COV_RESULTS", $sformatf("=============================================="), UVM_LOW)
  endfunction

endclass

// --- 6. SCOREBOARD ---
class alu_scoreboard extends uvm_subscriber #(alu_item);
  `uvm_component_utils(alu_scoreboard)

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void write(alu_item t);
    bit [4:0] expected;
    case(t.op)
      2'b00: expected = t.a + t.b;
      2'b01: expected = t.a - t.b;
      2'b10: expected = t.a & t.b;
      2'b11: expected = t.a | t.b;
    endcase

    if(expected == t.result)
      `uvm_info("PASS", $sformatf("OP:%0d A:%0d B:%0d | RES:%0d", t.op, t.a, t.b, t.result), UVM_LOW)
    else
      `uvm_error("FAIL", $sformatf("OP:%0d A:%0d B:%0d | EXP:%0d ACT:%0d", t.op, t.a, t.b, expected, t.result))
  endfunction
endclass

// --- 7. AGENT ---
class alu_agent extends uvm_agent;
  `uvm_component_utils(alu_agent)
  uvm_sequencer#(alu_item) seqr;
  alu_driver drv;
  alu_monitor mon;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = uvm_sequencer#(alu_item)::type_id::create("seqr", this);
    drv  = alu_driver::type_id::create("drv", this);
    mon  = alu_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

// --- 8. ENVIRONMENT ---
class alu_env extends uvm_env;
  `uvm_component_utils(alu_env)
  alu_agent agt;
  alu_scoreboard scb;
  alu_coverage cov;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = alu_agent::type_id::create("agt", this);
    scb = alu_scoreboard::type_id::create("scb", this);
    cov = alu_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agt.mon.mon_ap.connect(scb.analysis_export);
    agt.mon.mon_ap.connect(cov.analysis_export);
  endfunction
endclass

// --- 9. TEST ---
class alu_test extends uvm_test;
  `uvm_component_utils(alu_test)
  alu_env env;
  alu_sequence seq;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = alu_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq = alu_sequence::type_id::create("seq");
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

// --- 10. TOP MODULE ---
module tb_top;
  logic clk;
  
  alu_if vif(clk);
  alu dut(vif);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    uvm_config_db#(virtual alu_if)::set(null, "*", "vif", vif);
    run_test("alu_test");
  end
endmodule
