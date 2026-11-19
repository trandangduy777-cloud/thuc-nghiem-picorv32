`timescale 1ns/1ps
module tb_gl;
  parameter HALF = 2.75;
  reg clk = 0;
  always #(HALF) clk = ~clk;
  reg resetn = 0;
  initial begin repeat (10) @(posedge clk); resetn <= 1; end
  wire mem_valid, mem_instr; wire [31:0] mem_addr, mem_wdata, mem_rdata; wire [3:0] mem_wstrb;
  reg ready_r; reg [31:0] rdata_r;
  picorv32 dut (.clk(clk), .resetn(resetn), .mem_valid(mem_valid), .mem_instr(mem_instr),
                .mem_ready(ready_r), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
                .mem_wstrb(mem_wstrb), .mem_rdata(rdata_r));
  reg [31:0] mem [0:255]; integer i;
  initial begin
    for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;
    $readmemh("programs/prog.hex", mem);
    $dumpfile("wave_gl.vcd"); $dumpvars(0, tb_gl.dut);
  end
  always @(posedge clk) begin
    ready_r <= 0;
    if (mem_valid && !ready_r) begin ready_r <= 1; rdata_r <= mem[mem_addr[9:2]]; end
  end
  always @(posedge clk) if (mem_valid && ready_r && |mem_wstrb) begin
    if (mem_wstrb[0]) mem[mem_addr[9:2]][ 7: 0] <= mem_wdata[ 7: 0];
    if (mem_wstrb[1]) mem[mem_addr[9:2]][15: 8] <= mem_wdata[15: 8];
    if (mem_wstrb[2]) mem[mem_addr[9:2]][23:16] <= mem_wdata[23:16];
    if (mem_wstrb[3]) mem[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
  end
  integer cycles = 0;
  always @(posedge clk) if (resetn) begin
    cycles <= cycles + 1;
    if (mem_valid && ready_r && |mem_wstrb && mem_addr == 32'h100) begin
      $display("GATE-LEVEL: ket_qua=%0d chu_ky=%0d", mem_wdata, cycles); $finish;
    end
  end
  initial begin #100000; $display("TIMEOUT"); $finish; end
endmodule
