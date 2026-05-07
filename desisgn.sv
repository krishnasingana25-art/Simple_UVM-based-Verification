// --- INTERFACE ---
interface alu_if(input logic clk);
  logic [3:0] a;
  logic [3:0] b;
  logic [1:0] op; // 00:ADD, 01:SUB, 10:AND, 11:OR
  logic [4:0] result;
endinterface

// --- DUT (Design Under Test) ---
module alu(alu_if vif);
  always_comb begin
    case(vif.op)
      2'b00: vif.result = vif.a + vif.b;
      2'b01: vif.result = vif.a - vif.b;
      2'b10: vif.result = vif.a & vif.b;
      2'b11: vif.result = vif.a | vif.b;
      default: vif.result = 5'b0;
    endcase
  end
endmodule
