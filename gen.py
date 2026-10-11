# Tao cac chuong trinh thu RV32I (dich tay bang Python) -> file .hex
def r(f7,rs2,rs1,f3,rd,op): return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def i(imm,rs1,f3,rd,op): return ((imm&0xFFF)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def s(imm,rs2,rs1,f3,op=0x23): return (((imm>>5)&0x7F)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1F)<<7)|op
def b(imm,rs2,rs1,f3):
    return (((imm>>12)&1)<<31)|(((imm>>5)&0x3F)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((imm>>1)&0xF)<<8)|(((imm>>11)&1)<<7)|0x63
def j(imm,rd):
    return (((imm>>20)&1)<<31)|(((imm>>1)&0x3FF)<<21)|(((imm>>11)&1)<<20)|(((imm>>12)&0xFF)<<12)|(rd<<7)|0x6F
addi=lambda rd,rs1,imm: i(imm,rs1,0,rd,0x13)
add =lambda rd,rs1,rs2: r(0,rs2,rs1,0,rd,0x33)
slli=lambda rd,rs1,sh: i(sh,rs1,1,rd,0x13)
lw  =lambda rd,rs1,imm: i(imm,rs1,2,rd,0x03)
sw  =lambda rs2,rs1,imm: s(imm,rs2,rs1,2)
bne =lambda rs1,rs2,imm: b(imm,rs2,rs1,1)
beq =lambda rs1,rs2,imm: b(imm,rs2,rs1,0)
jal =lambda rd,imm: j(imm,rd)
# kiem tra voi chuong trinh goc
assert addi(1,0,10)==0x00A00093 and add(2,2,1)==0x00110133 and bne(1,0,-8)==0xFE009CE3
assert sw(2,0,256)==0x10202023 and jal(0,0)==0x0000006F and addi(1,1,-1)==0xFFF08093

N=100
def prog(name,body):
    code=body+[sw(0,0,256),jal(0,0)]       # sw x0,256(x0) : danh dau ket thuc
    assert len(code)*4<0x200
    with open(name,'w') as f:
        for w in code: f.write('%08X\n'%w)
        f.write('@80\n00000000\n')         # o du lieu tai 0x200 cho lenh lw
prog('p_alu_imm.hex',[addi(1,1,1)]*N)
prog('p_alu_reg.hex',[addi(1,0,1),add(2,2,1)]+[add(2,2,1)]*(N-1))
prog('p_load.hex',[lw(3,0,0x200)]*N)
prog('p_store.hex',[sw(1,0,0x204)]*N)
prog('p_br_nt.hex',[bne(0,0,8)]*N)     # khong bao gio re nhanh
prog('p_br_t.hex',[beq(0,0,4)]*N)      # luon re nhanh (dich la lenh ke tiep)
prog('p_jal.hex',[jal(0,4)]*N)
prog('p_shift.hex',[addi(1,0,1)]+[slli(1,1,8)]*N)
print('done')
