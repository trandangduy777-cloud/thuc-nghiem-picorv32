`timescale 1ns/1ps
module tb2;
  reg clk = 0;
  always #5 clk = ~clk;
  reg resetn = 0;
  initial begin repeat (10) @(posedge clk); resetn <= 1; end

  wire        mem_valid, mem_instr, mem_ready;
  wire [31:0] mem_addr, mem_wdata, mem_rdata;
  wire [3:0]  mem_wstrb;

  picorv32 dut (.clk(clk), .resetn(resetn), .mem_valid(mem_valid), .mem_instr(mem_instr),
                .mem_ready(mem_ready), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
                .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata));

  reg [31:0] mem [0:255];            // 1 KiB
  reg [1023:0] hexfile;
  integer wait_mode, i;
  initial begin
    for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;
    if (!$value$plusargs("hex=%s", hexfile)) hexfile = "programs/prog.hex";
    if (!$value$plusargs("wait=%d", wait_mode)) wait_mode = 1;   // 1: 1 chu ky cho, 0: tra loi ngay
    $readmemh(hexfile, mem);
    if ($test$plusargs("vcd")) begin $dumpfile("wave2.vcd"); $dumpvars(0, tb2); end
  end

  // bo nho: wait=1 giong tb.v cu (ready tre 1 chu ky), wait=0 tra loi trong cung chu ky
  reg ready_r; reg [31:0] rdata_r;
  always @(posedge clk) begin
    ready_r <= 0;
    if (wait_mode == 1 && mem_valid && !ready_r) begin
      ready_r <= 1;
      rdata_r <= mem[mem_addr[9:2]];
    end
  end
  assign mem_ready = (wait_mode == 1) ? ready_r : mem_valid;
  assign mem_rdata = (wait_mode == 1) ? rdata_r : mem[mem_addr[9:2]];

  always @(posedge clk) if (mem_valid && mem_ready && |mem_wstrb) begin
    if (mem_wstrb[0]) mem[mem_addr[9:2]][ 7: 0] <= mem_wdata[ 7: 0];
    if (mem_wstrb[1]) mem[mem_addr[9:2]][15: 8] <= mem_wdata[15: 8];
    if (mem_wstrb[2]) mem[mem_addr[9:2]][23:16] <= mem_wdata[23:16];
    if (mem_wstrb[3]) mem[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
  end

  integer cycles = 0, fetches = 0;
  always @(posedge clk) if (resetn) begin
    cycles <= cycles + 1;
    if (mem_valid && mem_ready && mem_instr) fetches <= fetches + 1;
    if (mem_valid && mem_ready && |mem_wstrb && mem_addr == 32'h100) begin
      $display("ket_qua=%0d  chu_ky=%0d  lan_nap_lenh=%0d  count_instr=%0d",
               mem_wdata, cycles, fetches, dut.count_instr);
      $finish;
    end
  end
  initial begin #5000000; $display("TIMEOUT"); $finish; end
endmodule
