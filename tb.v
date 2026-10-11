`timescale 1ns/1ps
module tb;
  reg clk = 0, resetn = 0;
  always #5 clk = ~clk;
  wire mem_valid, mem_instr;  reg mem_ready = 0;
  wire [31:0] mem_addr, mem_wdata;  wire [3:0] mem_wstrb;  reg [31:0] mem_rdata;

  picorv32 uut (.clk(clk), .resetn(resetn),
    .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
    .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata));

  reg [31:0] mem [0:255];
  initial $readmemh("prog.hex", mem);
  integer cycles = 0;
  always @(posedge clk) if (resetn) cycles <= cycles + 1;

  always @(posedge clk) begin
    mem_ready <= 0;
    if (mem_valid && !mem_ready) begin
      mem_ready <= 1;
      if (mem_wstrb == 4'b0000) mem_rdata <= mem[mem_addr[9:2]];
      else begin
        if (mem_wstrb[0]) mem[mem_addr[9:2]][ 7: 0] <= mem_wdata[ 7: 0];
        if (mem_wstrb[1]) mem[mem_addr[9:2]][15: 8] <= mem_wdata[15: 8];
        if (mem_wstrb[2]) mem[mem_addr[9:2]][23:16] <= mem_wdata[23:16];
        if (mem_wstrb[3]) mem[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
        if (mem_addr == 32'h100) begin
          $display("Tong 1..10 = %0d (0x%h)", mem_wdata, mem_wdata);
          $display("So chu ky = %0d, so lenh = 33, CPI = %0f", cycles, cycles/33.0);
          #50 $finish;
        end
      end
    end
  end

  initial begin
    $dumpfile("wave.vcd"); $dumpvars(0, tb);
    repeat (10) @(posedge clk); resetn <= 1;
    #100000 $finish;
  end
endmodule
