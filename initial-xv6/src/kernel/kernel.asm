
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	eee78793          	addi	a5,a5,-274 # 80005f50 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbe7f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3a8080e7          	jalr	936(ra) # 800024d2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	154080e7          	jalr	340(ra) # 8000231c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e92080e7          	jalr	-366(ra) # 80002068 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	26a080e7          	jalr	618(ra) # 8000247c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	236080e7          	jalr	566(ra) # 80002528 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c86080e7          	jalr	-890(ra) # 800020cc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	37078793          	addi	a5,a5,880 # 800217e8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	838080e7          	jalr	-1992(ra) # 800020cc <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	74a080e7          	jalr	1866(ra) # 80002068 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	f8478793          	addi	a5,a5,-124 # 80022980 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	eb250513          	addi	a0,a0,-334 # 80022980 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc681>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	956080e7          	jalr	-1706(ra) # 80002814 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	0ca080e7          	jalr	202(ra) # 80005f90 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe8080e7          	jalr	-24(ra) # 80001eb6 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8b6080e7          	jalr	-1866(ra) # 800027ec <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	8d6080e7          	jalr	-1834(ra) # 80002814 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	034080e7          	jalr	52(ra) # 80005f7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	042080e7          	jalr	66(ra) # 80005f90 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	1ca080e7          	jalr	458(ra) # 80003120 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	86a080e7          	jalr	-1942(ra) # 800037c8 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	810080e7          	jalr	-2032(ra) # 80004776 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	12a080e7          	jalr	298(ra) # 80006098 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d22080e7          	jalr	-734(ra) # 80001c98 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc677>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc680>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	75448493          	addi	s1,s1,1876 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	d3aa0a13          	addi	s4,s4,-710 # 800175a0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	19848493          	addi	s1,s1,408
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	69048493          	addi	s1,s1,1680 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	c6e98993          	addi	s3,s3,-914 # 800175a0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	19848493          	addi	s1,s1,408
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e26080e7          	jalr	-474(ra) # 8000282c <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	d28080e7          	jalr	-728(ra) # 80003748 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3de48493          	addi	s1,s1,990 # 80010fa0 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	9d690913          	addi	s2,s2,-1578 # 800175a0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	19848493          	addi	s1,s1,408
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a09d                	j	80001c5a <allocproc+0xa4>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd21                	beqz	a0,80001c68 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c125                	beqz	a0,80001c80 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	cb27a783          	lw	a5,-846(a5) # 80008900 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	ef4080e7          	jalr	-268(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	016080e7          	jalr	22(ra) # 80000c8a <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0xa4>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	edc080e7          	jalr	-292(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0xa4>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f14080e7          	jalr	-236(ra) # 80001bb6 <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	c4a7b623          	sd	a0,-948(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	bb858593          	addi	a1,a1,-1096 # 80008870 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	694080e7          	jalr	1684(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	52658593          	addi	a1,a1,1318 # 80008200 <digits+0x1c0>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	136080e7          	jalr	310(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	52250513          	addi	a0,a0,1314 # 80008210 <digits+0x1d0>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	47c080e7          	jalr	1148(ra) # 80004172 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f82080e7          	jalr	-126(ra) # 80000c8a <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80001d30:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d34:	01204c63          	bgtz	s2,80001d4c <growproc+0x32>
  else if (n < 0)
    80001d38:	02094663          	bltz	s2,80001d64 <growproc+0x4a>
  p->sz = sz;
    80001d3c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d3e:	4501                	li	a0,0
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d4c:	4691                	li	a3,4
    80001d4e:	00b90633          	add	a2,s2,a1
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	6bc080e7          	jalr	1724(ra) # 80001410 <uvmalloc>
    80001d5c:	85aa                	mv	a1,a0
    80001d5e:	fd79                	bnez	a0,80001d3c <growproc+0x22>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bff9                	j	80001d40 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	00b90633          	add	a2,s2,a1
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	65e080e7          	jalr	1630(ra) # 800013c8 <uvmdealloc>
    80001d72:	85aa                	mv	a1,a0
    80001d74:	b7e1                	j	80001d3c <growproc+0x22>

0000000080001d76 <fork>:
{
    80001d76:	7139                	addi	sp,sp,-64
    80001d78:	fc06                	sd	ra,56(sp)
    80001d7a:	f822                	sd	s0,48(sp)
    80001d7c:	f426                	sd	s1,40(sp)
    80001d7e:	f04a                	sd	s2,32(sp)
    80001d80:	ec4e                	sd	s3,24(sp)
    80001d82:	e852                	sd	s4,16(sp)
    80001d84:	e456                	sd	s5,8(sp)
    80001d86:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
    80001d90:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	e24080e7          	jalr	-476(ra) # 80001bb6 <allocproc>
    80001d9a:	10050c63          	beqz	a0,80001eb2 <fork+0x13c>
    80001d9e:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001da0:	048ab603          	ld	a2,72(s5)
    80001da4:	692c                	ld	a1,80(a0)
    80001da6:	050ab503          	ld	a0,80(s5)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	7be080e7          	jalr	1982(ra) # 80001568 <uvmcopy>
    80001db2:	04054863          	bltz	a0,80001e02 <fork+0x8c>
  np->sz = p->sz;
    80001db6:	048ab783          	ld	a5,72(s5)
    80001dba:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dbe:	058ab683          	ld	a3,88(s5)
    80001dc2:	87b6                	mv	a5,a3
    80001dc4:	058a3703          	ld	a4,88(s4)
    80001dc8:	12068693          	addi	a3,a3,288
    80001dcc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd0:	6788                	ld	a0,8(a5)
    80001dd2:	6b8c                	ld	a1,16(a5)
    80001dd4:	6f90                	ld	a2,24(a5)
    80001dd6:	01073023          	sd	a6,0(a4)
    80001dda:	e708                	sd	a0,8(a4)
    80001ddc:	eb0c                	sd	a1,16(a4)
    80001dde:	ef10                	sd	a2,24(a4)
    80001de0:	02078793          	addi	a5,a5,32
    80001de4:	02070713          	addi	a4,a4,32
    80001de8:	fed792e3          	bne	a5,a3,80001dcc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dec:	058a3783          	ld	a5,88(s4)
    80001df0:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001df4:	0d0a8493          	addi	s1,s5,208
    80001df8:	0d0a0913          	addi	s2,s4,208
    80001dfc:	150a8993          	addi	s3,s5,336
    80001e00:	a00d                	j	80001e22 <fork+0xac>
    freeproc(np);
    80001e02:	8552                	mv	a0,s4
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d5a080e7          	jalr	-678(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e0c:	8552                	mv	a0,s4
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
    return -1;
    80001e16:	597d                	li	s2,-1
    80001e18:	a059                	j	80001e9e <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e1a:	04a1                	addi	s1,s1,8
    80001e1c:	0921                	addi	s2,s2,8
    80001e1e:	01348b63          	beq	s1,s3,80001e34 <fork+0xbe>
    if (p->ofile[i])
    80001e22:	6088                	ld	a0,0(s1)
    80001e24:	d97d                	beqz	a0,80001e1a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e26:	00003097          	auipc	ra,0x3
    80001e2a:	9e2080e7          	jalr	-1566(ra) # 80004808 <filedup>
    80001e2e:	00a93023          	sd	a0,0(s2)
    80001e32:	b7e5                	j	80001e1a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e34:	150ab503          	ld	a0,336(s5)
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	b50080e7          	jalr	-1200(ra) # 80003988 <idup>
    80001e40:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e44:	4641                	li	a2,16
    80001e46:	158a8593          	addi	a1,s5,344
    80001e4a:	158a0513          	addi	a0,s4,344
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	fce080e7          	jalr	-50(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e56:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e64:	0000f497          	auipc	s1,0xf
    80001e68:	d2448493          	addi	s1,s1,-732 # 80010b88 <wait_lock>
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	d68080e7          	jalr	-664(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e76:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d50080e7          	jalr	-688(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
}
    80001e9e:	854a                	mv	a0,s2
    80001ea0:	70e2                	ld	ra,56(sp)
    80001ea2:	7442                	ld	s0,48(sp)
    80001ea4:	74a2                	ld	s1,40(sp)
    80001ea6:	7902                	ld	s2,32(sp)
    80001ea8:	69e2                	ld	s3,24(sp)
    80001eaa:	6a42                	ld	s4,16(sp)
    80001eac:	6aa2                	ld	s5,8(sp)
    80001eae:	6121                	addi	sp,sp,64
    80001eb0:	8082                	ret
    return -1;
    80001eb2:	597d                	li	s2,-1
    80001eb4:	b7ed                	j	80001e9e <fork+0x128>

0000000080001eb6 <scheduler>:
{
    80001eb6:	7139                	addi	sp,sp,-64
    80001eb8:	fc06                	sd	ra,56(sp)
    80001eba:	f822                	sd	s0,48(sp)
    80001ebc:	f426                	sd	s1,40(sp)
    80001ebe:	f04a                	sd	s2,32(sp)
    80001ec0:	ec4e                	sd	s3,24(sp)
    80001ec2:	e852                	sd	s4,16(sp)
    80001ec4:	e456                	sd	s5,8(sp)
    80001ec6:	e05a                	sd	s6,0(sp)
    80001ec8:	0080                	addi	s0,sp,64
    80001eca:	8792                	mv	a5,tp
  int id = r_tp();
    80001ecc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ece:	00779a93          	slli	s5,a5,0x7
    80001ed2:	0000f717          	auipc	a4,0xf
    80001ed6:	c9e70713          	addi	a4,a4,-866 # 80010b70 <pid_lock>
    80001eda:	9756                	add	a4,a4,s5
    80001edc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee0:	0000f717          	auipc	a4,0xf
    80001ee4:	cc870713          	addi	a4,a4,-824 # 80010ba8 <cpus+0x8>
    80001ee8:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001eea:	498d                	li	s3,3
        p->state = RUNNING;
    80001eec:	4b11                	li	s6,4
        c->proc = p;
    80001eee:	079e                	slli	a5,a5,0x7
    80001ef0:	0000fa17          	auipc	s4,0xf
    80001ef4:	c80a0a13          	addi	s4,s4,-896 # 80010b70 <pid_lock>
    80001ef8:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001efa:	00015917          	auipc	s2,0x15
    80001efe:	6a690913          	addi	s2,s2,1702 # 800175a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f06:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0a:	10079073          	csrw	sstatus,a5
    80001f0e:	0000f497          	auipc	s1,0xf
    80001f12:	09248493          	addi	s1,s1,146 # 80010fa0 <proc>
    80001f16:	a811                	j	80001f2a <scheduler+0x74>
      release(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f22:	19848493          	addi	s1,s1,408
    80001f26:	fd248ee3          	beq	s1,s2,80001f02 <scheduler+0x4c>
      acquire(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	caa080e7          	jalr	-854(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f34:	4c9c                	lw	a5,24(s1)
    80001f36:	ff3791e3          	bne	a5,s3,80001f18 <scheduler+0x62>
        p->state = RUNNING;
    80001f3a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f3e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f42:	06048593          	addi	a1,s1,96
    80001f46:	8556                	mv	a0,s5
    80001f48:	00001097          	auipc	ra,0x1
    80001f4c:	83a080e7          	jalr	-1990(ra) # 80002782 <swtch>
        c->proc = 0;
    80001f50:	020a3823          	sd	zero,48(s4)
    80001f54:	b7d1                	j	80001f18 <scheduler+0x62>

0000000080001f56 <sched>:
{
    80001f56:	7179                	addi	sp,sp,-48
    80001f58:	f406                	sd	ra,40(sp)
    80001f5a:	f022                	sd	s0,32(sp)
    80001f5c:	ec26                	sd	s1,24(sp)
    80001f5e:	e84a                	sd	s2,16(sp)
    80001f60:	e44e                	sd	s3,8(sp)
    80001f62:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	a48080e7          	jalr	-1464(ra) # 800019ac <myproc>
    80001f6c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	bee080e7          	jalr	-1042(ra) # 80000b5c <holding>
    80001f76:	c93d                	beqz	a0,80001fec <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f78:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f7a:	2781                	sext.w	a5,a5
    80001f7c:	079e                	slli	a5,a5,0x7
    80001f7e:	0000f717          	auipc	a4,0xf
    80001f82:	bf270713          	addi	a4,a4,-1038 # 80010b70 <pid_lock>
    80001f86:	97ba                	add	a5,a5,a4
    80001f88:	0a87a703          	lw	a4,168(a5)
    80001f8c:	4785                	li	a5,1
    80001f8e:	06f71763          	bne	a4,a5,80001ffc <sched+0xa6>
  if (p->state == RUNNING)
    80001f92:	4c98                	lw	a4,24(s1)
    80001f94:	4791                	li	a5,4
    80001f96:	06f70b63          	beq	a4,a5,8000200c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f9e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fa0:	efb5                	bnez	a5,8000201c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa4:	0000f917          	auipc	s2,0xf
    80001fa8:	bcc90913          	addi	s2,s2,-1076 # 80010b70 <pid_lock>
    80001fac:	2781                	sext.w	a5,a5
    80001fae:	079e                	slli	a5,a5,0x7
    80001fb0:	97ca                	add	a5,a5,s2
    80001fb2:	0ac7a983          	lw	s3,172(a5)
    80001fb6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	0000f597          	auipc	a1,0xf
    80001fc0:	bec58593          	addi	a1,a1,-1044 # 80010ba8 <cpus+0x8>
    80001fc4:	95be                	add	a1,a1,a5
    80001fc6:	06048513          	addi	a0,s1,96
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	7b8080e7          	jalr	1976(ra) # 80002782 <swtch>
    80001fd2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd4:	2781                	sext.w	a5,a5
    80001fd6:	079e                	slli	a5,a5,0x7
    80001fd8:	993e                	add	s2,s2,a5
    80001fda:	0b392623          	sw	s3,172(s2)
}
    80001fde:	70a2                	ld	ra,40(sp)
    80001fe0:	7402                	ld	s0,32(sp)
    80001fe2:	64e2                	ld	s1,24(sp)
    80001fe4:	6942                	ld	s2,16(sp)
    80001fe6:	69a2                	ld	s3,8(sp)
    80001fe8:	6145                	addi	sp,sp,48
    80001fea:	8082                	ret
    panic("sched p->lock");
    80001fec:	00006517          	auipc	a0,0x6
    80001ff0:	22c50513          	addi	a0,a0,556 # 80008218 <digits+0x1d8>
    80001ff4:	ffffe097          	auipc	ra,0xffffe
    80001ff8:	54c080e7          	jalr	1356(ra) # 80000540 <panic>
    panic("sched locks");
    80001ffc:	00006517          	auipc	a0,0x6
    80002000:	22c50513          	addi	a0,a0,556 # 80008228 <digits+0x1e8>
    80002004:	ffffe097          	auipc	ra,0xffffe
    80002008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
    panic("sched running");
    8000200c:	00006517          	auipc	a0,0x6
    80002010:	22c50513          	addi	a0,a0,556 # 80008238 <digits+0x1f8>
    80002014:	ffffe097          	auipc	ra,0xffffe
    80002018:	52c080e7          	jalr	1324(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000201c:	00006517          	auipc	a0,0x6
    80002020:	22c50513          	addi	a0,a0,556 # 80008248 <digits+0x208>
    80002024:	ffffe097          	auipc	ra,0xffffe
    80002028:	51c080e7          	jalr	1308(ra) # 80000540 <panic>

000000008000202c <yield>:
{
    8000202c:	1101                	addi	sp,sp,-32
    8000202e:	ec06                	sd	ra,24(sp)
    80002030:	e822                	sd	s0,16(sp)
    80002032:	e426                	sd	s1,8(sp)
    80002034:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	976080e7          	jalr	-1674(ra) # 800019ac <myproc>
    8000203e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	b96080e7          	jalr	-1130(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002048:	478d                	li	a5,3
    8000204a:	cc9c                	sw	a5,24(s1)
  sched();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	f0a080e7          	jalr	-246(ra) # 80001f56 <sched>
  release(&p->lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c34080e7          	jalr	-972(ra) # 80000c8a <release>
}
    8000205e:	60e2                	ld	ra,24(sp)
    80002060:	6442                	ld	s0,16(sp)
    80002062:	64a2                	ld	s1,8(sp)
    80002064:	6105                	addi	sp,sp,32
    80002066:	8082                	ret

0000000080002068 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002068:	7179                	addi	sp,sp,-48
    8000206a:	f406                	sd	ra,40(sp)
    8000206c:	f022                	sd	s0,32(sp)
    8000206e:	ec26                	sd	s1,24(sp)
    80002070:	e84a                	sd	s2,16(sp)
    80002072:	e44e                	sd	s3,8(sp)
    80002074:	1800                	addi	s0,sp,48
    80002076:	89aa                	mv	s3,a0
    80002078:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	932080e7          	jalr	-1742(ra) # 800019ac <myproc>
    80002082:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b52080e7          	jalr	-1198(ra) # 80000bd6 <acquire>
  release(lk);
    8000208c:	854a                	mv	a0,s2
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	bfc080e7          	jalr	-1028(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002096:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209a:	4789                	li	a5,2
    8000209c:	cc9c                	sw	a5,24(s1)

  sched();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	eb8080e7          	jalr	-328(ra) # 80001f56 <sched>

  // Tidy up.
  p->chan = 0;
    800020a6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	bde080e7          	jalr	-1058(ra) # 80000c8a <release>
  acquire(lk);
    800020b4:	854a                	mv	a0,s2
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b20080e7          	jalr	-1248(ra) # 80000bd6 <acquire>
}
    800020be:	70a2                	ld	ra,40(sp)
    800020c0:	7402                	ld	s0,32(sp)
    800020c2:	64e2                	ld	s1,24(sp)
    800020c4:	6942                	ld	s2,16(sp)
    800020c6:	69a2                	ld	s3,8(sp)
    800020c8:	6145                	addi	sp,sp,48
    800020ca:	8082                	ret

00000000800020cc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020cc:	7139                	addi	sp,sp,-64
    800020ce:	fc06                	sd	ra,56(sp)
    800020d0:	f822                	sd	s0,48(sp)
    800020d2:	f426                	sd	s1,40(sp)
    800020d4:	f04a                	sd	s2,32(sp)
    800020d6:	ec4e                	sd	s3,24(sp)
    800020d8:	e852                	sd	s4,16(sp)
    800020da:	e456                	sd	s5,8(sp)
    800020dc:	0080                	addi	s0,sp,64
    800020de:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020e0:	0000f497          	auipc	s1,0xf
    800020e4:	ec048493          	addi	s1,s1,-320 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020e8:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020ea:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020ec:	00015917          	auipc	s2,0x15
    800020f0:	4b490913          	addi	s2,s2,1204 # 800175a0 <tickslock>
    800020f4:	a811                	j	80002108 <wakeup+0x3c>
      }
      release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	b92080e7          	jalr	-1134(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002100:	19848493          	addi	s1,s1,408
    80002104:	03248663          	beq	s1,s2,80002130 <wakeup+0x64>
    if (p != myproc())
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	8a4080e7          	jalr	-1884(ra) # 800019ac <myproc>
    80002110:	fea488e3          	beq	s1,a0,80002100 <wakeup+0x34>
      acquire(&p->lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	ac0080e7          	jalr	-1344(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000211e:	4c9c                	lw	a5,24(s1)
    80002120:	fd379be3          	bne	a5,s3,800020f6 <wakeup+0x2a>
    80002124:	709c                	ld	a5,32(s1)
    80002126:	fd4798e3          	bne	a5,s4,800020f6 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000212a:	0154ac23          	sw	s5,24(s1)
    8000212e:	b7e1                	j	800020f6 <wakeup+0x2a>
    }
  }
}
    80002130:	70e2                	ld	ra,56(sp)
    80002132:	7442                	ld	s0,48(sp)
    80002134:	74a2                	ld	s1,40(sp)
    80002136:	7902                	ld	s2,32(sp)
    80002138:	69e2                	ld	s3,24(sp)
    8000213a:	6a42                	ld	s4,16(sp)
    8000213c:	6aa2                	ld	s5,8(sp)
    8000213e:	6121                	addi	sp,sp,64
    80002140:	8082                	ret

0000000080002142 <reparent>:
{
    80002142:	7179                	addi	sp,sp,-48
    80002144:	f406                	sd	ra,40(sp)
    80002146:	f022                	sd	s0,32(sp)
    80002148:	ec26                	sd	s1,24(sp)
    8000214a:	e84a                	sd	s2,16(sp)
    8000214c:	e44e                	sd	s3,8(sp)
    8000214e:	e052                	sd	s4,0(sp)
    80002150:	1800                	addi	s0,sp,48
    80002152:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002154:	0000f497          	auipc	s1,0xf
    80002158:	e4c48493          	addi	s1,s1,-436 # 80010fa0 <proc>
      pp->parent = initproc;
    8000215c:	00006a17          	auipc	s4,0x6
    80002160:	79ca0a13          	addi	s4,s4,1948 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002164:	00015997          	auipc	s3,0x15
    80002168:	43c98993          	addi	s3,s3,1084 # 800175a0 <tickslock>
    8000216c:	a029                	j	80002176 <reparent+0x34>
    8000216e:	19848493          	addi	s1,s1,408
    80002172:	01348d63          	beq	s1,s3,8000218c <reparent+0x4a>
    if (pp->parent == p)
    80002176:	7c9c                	ld	a5,56(s1)
    80002178:	ff279be3          	bne	a5,s2,8000216e <reparent+0x2c>
      pp->parent = initproc;
    8000217c:	000a3503          	ld	a0,0(s4)
    80002180:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002182:	00000097          	auipc	ra,0x0
    80002186:	f4a080e7          	jalr	-182(ra) # 800020cc <wakeup>
    8000218a:	b7d5                	j	8000216e <reparent+0x2c>
}
    8000218c:	70a2                	ld	ra,40(sp)
    8000218e:	7402                	ld	s0,32(sp)
    80002190:	64e2                	ld	s1,24(sp)
    80002192:	6942                	ld	s2,16(sp)
    80002194:	69a2                	ld	s3,8(sp)
    80002196:	6a02                	ld	s4,0(sp)
    80002198:	6145                	addi	sp,sp,48
    8000219a:	8082                	ret

000000008000219c <exit>:
{
    8000219c:	7179                	addi	sp,sp,-48
    8000219e:	f406                	sd	ra,40(sp)
    800021a0:	f022                	sd	s0,32(sp)
    800021a2:	ec26                	sd	s1,24(sp)
    800021a4:	e84a                	sd	s2,16(sp)
    800021a6:	e44e                	sd	s3,8(sp)
    800021a8:	e052                	sd	s4,0(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	7fe080e7          	jalr	2046(ra) # 800019ac <myproc>
    800021b6:	89aa                	mv	s3,a0
  if (p == initproc)
    800021b8:	00006797          	auipc	a5,0x6
    800021bc:	7407b783          	ld	a5,1856(a5) # 800088f8 <initproc>
    800021c0:	0d050493          	addi	s1,a0,208
    800021c4:	15050913          	addi	s2,a0,336
    800021c8:	02a79363          	bne	a5,a0,800021ee <exit+0x52>
    panic("init exiting");
    800021cc:	00006517          	auipc	a0,0x6
    800021d0:	09450513          	addi	a0,a0,148 # 80008260 <digits+0x220>
    800021d4:	ffffe097          	auipc	ra,0xffffe
    800021d8:	36c080e7          	jalr	876(ra) # 80000540 <panic>
      fileclose(f);
    800021dc:	00002097          	auipc	ra,0x2
    800021e0:	67e080e7          	jalr	1662(ra) # 8000485a <fileclose>
      p->ofile[fd] = 0;
    800021e4:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021e8:	04a1                	addi	s1,s1,8
    800021ea:	01248563          	beq	s1,s2,800021f4 <exit+0x58>
    if (p->ofile[fd])
    800021ee:	6088                	ld	a0,0(s1)
    800021f0:	f575                	bnez	a0,800021dc <exit+0x40>
    800021f2:	bfdd                	j	800021e8 <exit+0x4c>
  begin_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	19e080e7          	jalr	414(ra) # 80004392 <begin_op>
  iput(p->cwd);
    800021fc:	1509b503          	ld	a0,336(s3)
    80002200:	00002097          	auipc	ra,0x2
    80002204:	980080e7          	jalr	-1664(ra) # 80003b80 <iput>
  end_op();
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	208080e7          	jalr	520(ra) # 80004410 <end_op>
  p->cwd = 0;
    80002210:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002214:	0000f497          	auipc	s1,0xf
    80002218:	97448493          	addi	s1,s1,-1676 # 80010b88 <wait_lock>
    8000221c:	8526                	mv	a0,s1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9b8080e7          	jalr	-1608(ra) # 80000bd6 <acquire>
  reparent(p);
    80002226:	854e                	mv	a0,s3
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	f1a080e7          	jalr	-230(ra) # 80002142 <reparent>
  wakeup(p->parent);
    80002230:	0389b503          	ld	a0,56(s3)
    80002234:	00000097          	auipc	ra,0x0
    80002238:	e98080e7          	jalr	-360(ra) # 800020cc <wakeup>
  acquire(&p->lock);
    8000223c:	854e                	mv	a0,s3
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	998080e7          	jalr	-1640(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002246:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000224a:	4795                	li	a5,5
    8000224c:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002250:	00006797          	auipc	a5,0x6
    80002254:	6b07a783          	lw	a5,1712(a5) # 80008900 <ticks>
    80002258:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a2c080e7          	jalr	-1492(ra) # 80000c8a <release>
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	cf0080e7          	jalr	-784(ra) # 80001f56 <sched>
  panic("zombie exit");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	00250513          	addi	a0,a0,2 # 80008270 <digits+0x230>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2ca080e7          	jalr	714(ra) # 80000540 <panic>

000000008000227e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	d1248493          	addi	s1,s1,-750 # 80010fa0 <proc>
    80002296:	00015997          	auipc	s3,0x15
    8000229a:	30a98993          	addi	s3,s3,778 # 800175a0 <tickslock>
  {
    acquire(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022a8:	589c                	lw	a5,48(s1)
    800022aa:	01278d63          	beq	a5,s2,800022c4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9da080e7          	jalr	-1574(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022b8:	19848493          	addi	s1,s1,408
    800022bc:	ff3491e3          	bne	s1,s3,8000229e <kill+0x20>
  }
  return -1;
    800022c0:	557d                	li	a0,-1
    800022c2:	a829                	j	800022dc <kill+0x5e>
      p->killed = 1;
    800022c4:	4785                	li	a5,1
    800022c6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022c8:	4c98                	lw	a4,24(s1)
    800022ca:	4789                	li	a5,2
    800022cc:	00f70f63          	beq	a4,a5,800022ea <kill+0x6c>
      release(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9b8080e7          	jalr	-1608(ra) # 80000c8a <release>
      return 0;
    800022da:	4501                	li	a0,0
}
    800022dc:	70a2                	ld	ra,40(sp)
    800022de:	7402                	ld	s0,32(sp)
    800022e0:	64e2                	ld	s1,24(sp)
    800022e2:	6942                	ld	s2,16(sp)
    800022e4:	69a2                	ld	s3,8(sp)
    800022e6:	6145                	addi	sp,sp,48
    800022e8:	8082                	ret
        p->state = RUNNABLE;
    800022ea:	478d                	li	a5,3
    800022ec:	cc9c                	sw	a5,24(s1)
    800022ee:	b7cd                	j	800022d0 <kill+0x52>

00000000800022f0 <setkilled>:

void setkilled(struct proc *p)
{
    800022f0:	1101                	addi	sp,sp,-32
    800022f2:	ec06                	sd	ra,24(sp)
    800022f4:	e822                	sd	s0,16(sp)
    800022f6:	e426                	sd	s1,8(sp)
    800022f8:	1000                	addi	s0,sp,32
    800022fa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002304:	4785                	li	a5,1
    80002306:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	980080e7          	jalr	-1664(ra) # 80000c8a <release>
}
    80002312:	60e2                	ld	ra,24(sp)
    80002314:	6442                	ld	s0,16(sp)
    80002316:	64a2                	ld	s1,8(sp)
    80002318:	6105                	addi	sp,sp,32
    8000231a:	8082                	ret

000000008000231c <killed>:

int killed(struct proc *p)
{
    8000231c:	1101                	addi	sp,sp,-32
    8000231e:	ec06                	sd	ra,24(sp)
    80002320:	e822                	sd	s0,16(sp)
    80002322:	e426                	sd	s1,8(sp)
    80002324:	e04a                	sd	s2,0(sp)
    80002326:	1000                	addi	s0,sp,32
    80002328:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8ac080e7          	jalr	-1876(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002332:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
  return k;
}
    80002340:	854a                	mv	a0,s2
    80002342:	60e2                	ld	ra,24(sp)
    80002344:	6442                	ld	s0,16(sp)
    80002346:	64a2                	ld	s1,8(sp)
    80002348:	6902                	ld	s2,0(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret

000000008000234e <wait>:
{
    8000234e:	715d                	addi	sp,sp,-80
    80002350:	e486                	sd	ra,72(sp)
    80002352:	e0a2                	sd	s0,64(sp)
    80002354:	fc26                	sd	s1,56(sp)
    80002356:	f84a                	sd	s2,48(sp)
    80002358:	f44e                	sd	s3,40(sp)
    8000235a:	f052                	sd	s4,32(sp)
    8000235c:	ec56                	sd	s5,24(sp)
    8000235e:	e85a                	sd	s6,16(sp)
    80002360:	e45e                	sd	s7,8(sp)
    80002362:	e062                	sd	s8,0(sp)
    80002364:	0880                	addi	s0,sp,80
    80002366:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	644080e7          	jalr	1604(ra) # 800019ac <myproc>
    80002370:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002372:	0000f517          	auipc	a0,0xf
    80002376:	81650513          	addi	a0,a0,-2026 # 80010b88 <wait_lock>
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	85c080e7          	jalr	-1956(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002382:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002384:	4a15                	li	s4,5
        havekids = 1;
    80002386:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002388:	00015997          	auipc	s3,0x15
    8000238c:	21898993          	addi	s3,s3,536 # 800175a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002390:	0000ec17          	auipc	s8,0xe
    80002394:	7f8c0c13          	addi	s8,s8,2040 # 80010b88 <wait_lock>
    havekids = 0;
    80002398:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	c0648493          	addi	s1,s1,-1018 # 80010fa0 <proc>
    800023a2:	a0bd                	j	80002410 <wait+0xc2>
          pid = pp->pid;
    800023a4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023a8:	000b0e63          	beqz	s6,800023c4 <wait+0x76>
    800023ac:	4691                	li	a3,4
    800023ae:	02c48613          	addi	a2,s1,44
    800023b2:	85da                	mv	a1,s6
    800023b4:	05093503          	ld	a0,80(s2)
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	2b4080e7          	jalr	692(ra) # 8000166c <copyout>
    800023c0:	02054563          	bltz	a0,800023ea <wait+0x9c>
          freeproc(pp);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	798080e7          	jalr	1944(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
          release(&wait_lock);
    800023d8:	0000e517          	auipc	a0,0xe
    800023dc:	7b050513          	addi	a0,a0,1968 # 80010b88 <wait_lock>
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
          return pid;
    800023e8:	a0b5                	j	80002454 <wait+0x106>
            release(&pp->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	89e080e7          	jalr	-1890(ra) # 80000c8a <release>
            release(&wait_lock);
    800023f4:	0000e517          	auipc	a0,0xe
    800023f8:	79450513          	addi	a0,a0,1940 # 80010b88 <wait_lock>
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
            return -1;
    80002404:	59fd                	li	s3,-1
    80002406:	a0b9                	j	80002454 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002408:	19848493          	addi	s1,s1,408
    8000240c:	03348463          	beq	s1,s3,80002434 <wait+0xe6>
      if (pp->parent == p)
    80002410:	7c9c                	ld	a5,56(s1)
    80002412:	ff279be3          	bne	a5,s2,80002408 <wait+0xba>
        acquire(&pp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002420:	4c9c                	lw	a5,24(s1)
    80002422:	f94781e3          	beq	a5,s4,800023a4 <wait+0x56>
        release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
        havekids = 1;
    80002430:	8756                	mv	a4,s5
    80002432:	bfd9                	j	80002408 <wait+0xba>
    if (!havekids || killed(p))
    80002434:	c719                	beqz	a4,80002442 <wait+0xf4>
    80002436:	854a                	mv	a0,s2
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	ee4080e7          	jalr	-284(ra) # 8000231c <killed>
    80002440:	c51d                	beqz	a0,8000246e <wait+0x120>
      release(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	74650513          	addi	a0,a0,1862 # 80010b88 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	840080e7          	jalr	-1984(ra) # 80000c8a <release>
      return -1;
    80002452:	59fd                	li	s3,-1
}
    80002454:	854e                	mv	a0,s3
    80002456:	60a6                	ld	ra,72(sp)
    80002458:	6406                	ld	s0,64(sp)
    8000245a:	74e2                	ld	s1,56(sp)
    8000245c:	7942                	ld	s2,48(sp)
    8000245e:	79a2                	ld	s3,40(sp)
    80002460:	7a02                	ld	s4,32(sp)
    80002462:	6ae2                	ld	s5,24(sp)
    80002464:	6b42                	ld	s6,16(sp)
    80002466:	6ba2                	ld	s7,8(sp)
    80002468:	6c02                	ld	s8,0(sp)
    8000246a:	6161                	addi	sp,sp,80
    8000246c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000246e:	85e2                	mv	a1,s8
    80002470:	854a                	mv	a0,s2
    80002472:	00000097          	auipc	ra,0x0
    80002476:	bf6080e7          	jalr	-1034(ra) # 80002068 <sleep>
    havekids = 0;
    8000247a:	bf39                	j	80002398 <wait+0x4a>

000000008000247c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247c:	7179                	addi	sp,sp,-48
    8000247e:	f406                	sd	ra,40(sp)
    80002480:	f022                	sd	s0,32(sp)
    80002482:	ec26                	sd	s1,24(sp)
    80002484:	e84a                	sd	s2,16(sp)
    80002486:	e44e                	sd	s3,8(sp)
    80002488:	e052                	sd	s4,0(sp)
    8000248a:	1800                	addi	s0,sp,48
    8000248c:	84aa                	mv	s1,a0
    8000248e:	892e                	mv	s2,a1
    80002490:	89b2                	mv	s3,a2
    80002492:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	518080e7          	jalr	1304(ra) # 800019ac <myproc>
  if (user_dst)
    8000249c:	c08d                	beqz	s1,800024be <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000249e:	86d2                	mv	a3,s4
    800024a0:	864e                	mv	a2,s3
    800024a2:	85ca                	mv	a1,s2
    800024a4:	6928                	ld	a0,80(a0)
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	1c6080e7          	jalr	454(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6a02                	ld	s4,0(sp)
    800024ba:	6145                	addi	sp,sp,48
    800024bc:	8082                	ret
    memmove((char *)dst, src, len);
    800024be:	000a061b          	sext.w	a2,s4
    800024c2:	85ce                	mv	a1,s3
    800024c4:	854a                	mv	a0,s2
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	868080e7          	jalr	-1944(ra) # 80000d2e <memmove>
    return 0;
    800024ce:	8526                	mv	a0,s1
    800024d0:	bff9                	j	800024ae <either_copyout+0x32>

00000000800024d2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d2:	7179                	addi	sp,sp,-48
    800024d4:	f406                	sd	ra,40(sp)
    800024d6:	f022                	sd	s0,32(sp)
    800024d8:	ec26                	sd	s1,24(sp)
    800024da:	e84a                	sd	s2,16(sp)
    800024dc:	e44e                	sd	s3,8(sp)
    800024de:	e052                	sd	s4,0(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	892a                	mv	s2,a0
    800024e4:	84ae                	mv	s1,a1
    800024e6:	89b2                	mv	s3,a2
    800024e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	4c2080e7          	jalr	1218(ra) # 800019ac <myproc>
  if (user_src)
    800024f2:	c08d                	beqz	s1,80002514 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024f4:	86d2                	mv	a3,s4
    800024f6:	864e                	mv	a2,s3
    800024f8:	85ca                	mv	a1,s2
    800024fa:	6928                	ld	a0,80(a0)
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	1fc080e7          	jalr	508(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002504:	70a2                	ld	ra,40(sp)
    80002506:	7402                	ld	s0,32(sp)
    80002508:	64e2                	ld	s1,24(sp)
    8000250a:	6942                	ld	s2,16(sp)
    8000250c:	69a2                	ld	s3,8(sp)
    8000250e:	6a02                	ld	s4,0(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret
    memmove(dst, (char *)src, len);
    80002514:	000a061b          	sext.w	a2,s4
    80002518:	85ce                	mv	a1,s3
    8000251a:	854a                	mv	a0,s2
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	812080e7          	jalr	-2030(ra) # 80000d2e <memmove>
    return 0;
    80002524:	8526                	mv	a0,s1
    80002526:	bff9                	j	80002504 <either_copyin+0x32>

0000000080002528 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002528:	715d                	addi	sp,sp,-80
    8000252a:	e486                	sd	ra,72(sp)
    8000252c:	e0a2                	sd	s0,64(sp)
    8000252e:	fc26                	sd	s1,56(sp)
    80002530:	f84a                	sd	s2,48(sp)
    80002532:	f44e                	sd	s3,40(sp)
    80002534:	f052                	sd	s4,32(sp)
    80002536:	ec56                	sd	s5,24(sp)
    80002538:	e85a                	sd	s6,16(sp)
    8000253a:	e45e                	sd	s7,8(sp)
    8000253c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000253e:	00006517          	auipc	a0,0x6
    80002542:	b8a50513          	addi	a0,a0,-1142 # 800080c8 <digits+0x88>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	044080e7          	jalr	68(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000254e:	0000f497          	auipc	s1,0xf
    80002552:	baa48493          	addi	s1,s1,-1110 # 800110f8 <proc+0x158>
    80002556:	00015917          	auipc	s2,0x15
    8000255a:	1a290913          	addi	s2,s2,418 # 800176f8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002560:	00006997          	auipc	s3,0x6
    80002564:	d2098993          	addi	s3,s3,-736 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002568:	00006a97          	auipc	s5,0x6
    8000256c:	d20a8a93          	addi	s5,s5,-736 # 80008288 <digits+0x248>
    printf("\n");
    80002570:	00006a17          	auipc	s4,0x6
    80002574:	b58a0a13          	addi	s4,s4,-1192 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002578:	00006b97          	auipc	s7,0x6
    8000257c:	d50b8b93          	addi	s7,s7,-688 # 800082c8 <states.0>
    80002580:	a00d                	j	800025a2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002582:	ed86a583          	lw	a1,-296(a3)
    80002586:	8556                	mv	a0,s5
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	002080e7          	jalr	2(ra) # 8000058a <printf>
    printf("\n");
    80002590:	8552                	mv	a0,s4
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	ff8080e7          	jalr	-8(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000259a:	19848493          	addi	s1,s1,408
    8000259e:	03248263          	beq	s1,s2,800025c2 <procdump+0x9a>
    if (p->state == UNUSED)
    800025a2:	86a6                	mv	a3,s1
    800025a4:	ec04a783          	lw	a5,-320(s1)
    800025a8:	dbed                	beqz	a5,8000259a <procdump+0x72>
      state = "???";
    800025aa:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ac:	fcfb6be3          	bltu	s6,a5,80002582 <procdump+0x5a>
    800025b0:	02079713          	slli	a4,a5,0x20
    800025b4:	01d75793          	srli	a5,a4,0x1d
    800025b8:	97de                	add	a5,a5,s7
    800025ba:	6390                	ld	a2,0(a5)
    800025bc:	f279                	bnez	a2,80002582 <procdump+0x5a>
      state = "???";
    800025be:	864e                	mv	a2,s3
    800025c0:	b7c9                	j	80002582 <procdump+0x5a>
  }
}
    800025c2:	60a6                	ld	ra,72(sp)
    800025c4:	6406                	ld	s0,64(sp)
    800025c6:	74e2                	ld	s1,56(sp)
    800025c8:	7942                	ld	s2,48(sp)
    800025ca:	79a2                	ld	s3,40(sp)
    800025cc:	7a02                	ld	s4,32(sp)
    800025ce:	6ae2                	ld	s5,24(sp)
    800025d0:	6b42                	ld	s6,16(sp)
    800025d2:	6ba2                	ld	s7,8(sp)
    800025d4:	6161                	addi	sp,sp,80
    800025d6:	8082                	ret

00000000800025d8 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025d8:	711d                	addi	sp,sp,-96
    800025da:	ec86                	sd	ra,88(sp)
    800025dc:	e8a2                	sd	s0,80(sp)
    800025de:	e4a6                	sd	s1,72(sp)
    800025e0:	e0ca                	sd	s2,64(sp)
    800025e2:	fc4e                	sd	s3,56(sp)
    800025e4:	f852                	sd	s4,48(sp)
    800025e6:	f456                	sd	s5,40(sp)
    800025e8:	f05a                	sd	s6,32(sp)
    800025ea:	ec5e                	sd	s7,24(sp)
    800025ec:	e862                	sd	s8,16(sp)
    800025ee:	e466                	sd	s9,8(sp)
    800025f0:	e06a                	sd	s10,0(sp)
    800025f2:	1080                	addi	s0,sp,96
    800025f4:	8b2a                	mv	s6,a0
    800025f6:	8bae                	mv	s7,a1
    800025f8:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800025fa:	fffff097          	auipc	ra,0xfffff
    800025fe:	3b2080e7          	jalr	946(ra) # 800019ac <myproc>
    80002602:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002604:	0000e517          	auipc	a0,0xe
    80002608:	58450513          	addi	a0,a0,1412 # 80010b88 <wait_lock>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	5ca080e7          	jalr	1482(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002614:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002616:	4a15                	li	s4,5
        havekids = 1;
    80002618:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000261a:	00015997          	auipc	s3,0x15
    8000261e:	f8698993          	addi	s3,s3,-122 # 800175a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002622:	0000ed17          	auipc	s10,0xe
    80002626:	566d0d13          	addi	s10,s10,1382 # 80010b88 <wait_lock>
    havekids = 0;
    8000262a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000262c:	0000f497          	auipc	s1,0xf
    80002630:	97448493          	addi	s1,s1,-1676 # 80010fa0 <proc>
    80002634:	a059                	j	800026ba <waitx+0xe2>
          pid = np->pid;
    80002636:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000263a:	1684a783          	lw	a5,360(s1)
    8000263e:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002642:	16c4a703          	lw	a4,364(s1)
    80002646:	9f3d                	addw	a4,a4,a5
    80002648:	1704a783          	lw	a5,368(s1)
    8000264c:	9f99                	subw	a5,a5,a4
    8000264e:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002652:	000b0e63          	beqz	s6,8000266e <waitx+0x96>
    80002656:	4691                	li	a3,4
    80002658:	02c48613          	addi	a2,s1,44
    8000265c:	85da                	mv	a1,s6
    8000265e:	05093503          	ld	a0,80(s2)
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	00a080e7          	jalr	10(ra) # 8000166c <copyout>
    8000266a:	02054563          	bltz	a0,80002694 <waitx+0xbc>
          freeproc(np);
    8000266e:	8526                	mv	a0,s1
    80002670:	fffff097          	auipc	ra,0xfffff
    80002674:	4ee080e7          	jalr	1262(ra) # 80001b5e <freeproc>
          release(&np->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	610080e7          	jalr	1552(ra) # 80000c8a <release>
          release(&wait_lock);
    80002682:	0000e517          	auipc	a0,0xe
    80002686:	50650513          	addi	a0,a0,1286 # 80010b88 <wait_lock>
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	600080e7          	jalr	1536(ra) # 80000c8a <release>
          return pid;
    80002692:	a09d                	j	800026f8 <waitx+0x120>
            release(&np->lock);
    80002694:	8526                	mv	a0,s1
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	5f4080e7          	jalr	1524(ra) # 80000c8a <release>
            release(&wait_lock);
    8000269e:	0000e517          	auipc	a0,0xe
    800026a2:	4ea50513          	addi	a0,a0,1258 # 80010b88 <wait_lock>
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	5e4080e7          	jalr	1508(ra) # 80000c8a <release>
            return -1;
    800026ae:	59fd                	li	s3,-1
    800026b0:	a0a1                	j	800026f8 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026b2:	19848493          	addi	s1,s1,408
    800026b6:	03348463          	beq	s1,s3,800026de <waitx+0x106>
      if (np->parent == p)
    800026ba:	7c9c                	ld	a5,56(s1)
    800026bc:	ff279be3          	bne	a5,s2,800026b2 <waitx+0xda>
        acquire(&np->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	514080e7          	jalr	1300(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800026ca:	4c9c                	lw	a5,24(s1)
    800026cc:	f74785e3          	beq	a5,s4,80002636 <waitx+0x5e>
        release(&np->lock);
    800026d0:	8526                	mv	a0,s1
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	5b8080e7          	jalr	1464(ra) # 80000c8a <release>
        havekids = 1;
    800026da:	8756                	mv	a4,s5
    800026dc:	bfd9                	j	800026b2 <waitx+0xda>
    if (!havekids || p->killed)
    800026de:	c701                	beqz	a4,800026e6 <waitx+0x10e>
    800026e0:	02892783          	lw	a5,40(s2)
    800026e4:	cb8d                	beqz	a5,80002716 <waitx+0x13e>
      release(&wait_lock);
    800026e6:	0000e517          	auipc	a0,0xe
    800026ea:	4a250513          	addi	a0,a0,1186 # 80010b88 <wait_lock>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>
      return -1;
    800026f6:	59fd                	li	s3,-1
  }
}
    800026f8:	854e                	mv	a0,s3
    800026fa:	60e6                	ld	ra,88(sp)
    800026fc:	6446                	ld	s0,80(sp)
    800026fe:	64a6                	ld	s1,72(sp)
    80002700:	6906                	ld	s2,64(sp)
    80002702:	79e2                	ld	s3,56(sp)
    80002704:	7a42                	ld	s4,48(sp)
    80002706:	7aa2                	ld	s5,40(sp)
    80002708:	7b02                	ld	s6,32(sp)
    8000270a:	6be2                	ld	s7,24(sp)
    8000270c:	6c42                	ld	s8,16(sp)
    8000270e:	6ca2                	ld	s9,8(sp)
    80002710:	6d02                	ld	s10,0(sp)
    80002712:	6125                	addi	sp,sp,96
    80002714:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002716:	85ea                	mv	a1,s10
    80002718:	854a                	mv	a0,s2
    8000271a:	00000097          	auipc	ra,0x0
    8000271e:	94e080e7          	jalr	-1714(ra) # 80002068 <sleep>
    havekids = 0;
    80002722:	b721                	j	8000262a <waitx+0x52>

0000000080002724 <update_time>:

void update_time()
{
    80002724:	7179                	addi	sp,sp,-48
    80002726:	f406                	sd	ra,40(sp)
    80002728:	f022                	sd	s0,32(sp)
    8000272a:	ec26                	sd	s1,24(sp)
    8000272c:	e84a                	sd	s2,16(sp)
    8000272e:	e44e                	sd	s3,8(sp)
    80002730:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002732:	0000f497          	auipc	s1,0xf
    80002736:	86e48493          	addi	s1,s1,-1938 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000273a:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000273c:	00015917          	auipc	s2,0x15
    80002740:	e6490913          	addi	s2,s2,-412 # 800175a0 <tickslock>
    80002744:	a811                	j	80002758 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	542080e7          	jalr	1346(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002750:	19848493          	addi	s1,s1,408
    80002754:	03248063          	beq	s1,s2,80002774 <update_time+0x50>
    acquire(&p->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	47c080e7          	jalr	1148(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002762:	4c9c                	lw	a5,24(s1)
    80002764:	ff3791e3          	bne	a5,s3,80002746 <update_time+0x22>
      p->rtime++;
    80002768:	1684a783          	lw	a5,360(s1)
    8000276c:	2785                	addiw	a5,a5,1
    8000276e:	16f4a423          	sw	a5,360(s1)
    80002772:	bfd1                	j	80002746 <update_time+0x22>
  }
    80002774:	70a2                	ld	ra,40(sp)
    80002776:	7402                	ld	s0,32(sp)
    80002778:	64e2                	ld	s1,24(sp)
    8000277a:	6942                	ld	s2,16(sp)
    8000277c:	69a2                	ld	s3,8(sp)
    8000277e:	6145                	addi	sp,sp,48
    80002780:	8082                	ret

0000000080002782 <swtch>:
    80002782:	00153023          	sd	ra,0(a0)
    80002786:	00253423          	sd	sp,8(a0)
    8000278a:	e900                	sd	s0,16(a0)
    8000278c:	ed04                	sd	s1,24(a0)
    8000278e:	03253023          	sd	s2,32(a0)
    80002792:	03353423          	sd	s3,40(a0)
    80002796:	03453823          	sd	s4,48(a0)
    8000279a:	03553c23          	sd	s5,56(a0)
    8000279e:	05653023          	sd	s6,64(a0)
    800027a2:	05753423          	sd	s7,72(a0)
    800027a6:	05853823          	sd	s8,80(a0)
    800027aa:	05953c23          	sd	s9,88(a0)
    800027ae:	07a53023          	sd	s10,96(a0)
    800027b2:	07b53423          	sd	s11,104(a0)
    800027b6:	0005b083          	ld	ra,0(a1)
    800027ba:	0085b103          	ld	sp,8(a1)
    800027be:	6980                	ld	s0,16(a1)
    800027c0:	6d84                	ld	s1,24(a1)
    800027c2:	0205b903          	ld	s2,32(a1)
    800027c6:	0285b983          	ld	s3,40(a1)
    800027ca:	0305ba03          	ld	s4,48(a1)
    800027ce:	0385ba83          	ld	s5,56(a1)
    800027d2:	0405bb03          	ld	s6,64(a1)
    800027d6:	0485bb83          	ld	s7,72(a1)
    800027da:	0505bc03          	ld	s8,80(a1)
    800027de:	0585bc83          	ld	s9,88(a1)
    800027e2:	0605bd03          	ld	s10,96(a1)
    800027e6:	0685bd83          	ld	s11,104(a1)
    800027ea:	8082                	ret

00000000800027ec <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800027ec:	1141                	addi	sp,sp,-16
    800027ee:	e406                	sd	ra,8(sp)
    800027f0:	e022                	sd	s0,0(sp)
    800027f2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027f4:	00006597          	auipc	a1,0x6
    800027f8:	b0458593          	addi	a1,a1,-1276 # 800082f8 <states.0+0x30>
    800027fc:	00015517          	auipc	a0,0x15
    80002800:	da450513          	addi	a0,a0,-604 # 800175a0 <tickslock>
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	342080e7          	jalr	834(ra) # 80000b46 <initlock>
}
    8000280c:	60a2                	ld	ra,8(sp)
    8000280e:	6402                	ld	s0,0(sp)
    80002810:	0141                	addi	sp,sp,16
    80002812:	8082                	ret

0000000080002814 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002814:	1141                	addi	sp,sp,-16
    80002816:	e422                	sd	s0,8(sp)
    80002818:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000281a:	00003797          	auipc	a5,0x3
    8000281e:	6a678793          	addi	a5,a5,1702 # 80005ec0 <kernelvec>
    80002822:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002826:	6422                	ld	s0,8(sp)
    80002828:	0141                	addi	sp,sp,16
    8000282a:	8082                	ret

000000008000282c <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000282c:	1141                	addi	sp,sp,-16
    8000282e:	e406                	sd	ra,8(sp)
    80002830:	e022                	sd	s0,0(sp)
    80002832:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	178080e7          	jalr	376(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002840:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002842:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002846:	00004697          	auipc	a3,0x4
    8000284a:	7ba68693          	addi	a3,a3,1978 # 80007000 <_trampoline>
    8000284e:	00004717          	auipc	a4,0x4
    80002852:	7b270713          	addi	a4,a4,1970 # 80007000 <_trampoline>
    80002856:	8f15                	sub	a4,a4,a3
    80002858:	040007b7          	lui	a5,0x4000
    8000285c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000285e:	07b2                	slli	a5,a5,0xc
    80002860:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002862:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002866:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002868:	18002673          	csrr	a2,satp
    8000286c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000286e:	6d30                	ld	a2,88(a0)
    80002870:	6138                	ld	a4,64(a0)
    80002872:	6585                	lui	a1,0x1
    80002874:	972e                	add	a4,a4,a1
    80002876:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002878:	6d38                	ld	a4,88(a0)
    8000287a:	00000617          	auipc	a2,0x0
    8000287e:	13e60613          	addi	a2,a2,318 # 800029b8 <usertrap>
    80002882:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002884:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002886:	8612                	mv	a2,tp
    80002888:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000288e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002892:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002896:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000289a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000289c:	6f18                	ld	a4,24(a4)
    8000289e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028a2:	6928                	ld	a0,80(a0)
    800028a4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028a6:	00004717          	auipc	a4,0x4
    800028aa:	7f670713          	addi	a4,a4,2038 # 8000709c <userret>
    800028ae:	8f15                	sub	a4,a4,a3
    800028b0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028b2:	577d                	li	a4,-1
    800028b4:	177e                	slli	a4,a4,0x3f
    800028b6:	8d59                	or	a0,a0,a4
    800028b8:	9782                	jalr	a5
}
    800028ba:	60a2                	ld	ra,8(sp)
    800028bc:	6402                	ld	s0,0(sp)
    800028be:	0141                	addi	sp,sp,16
    800028c0:	8082                	ret

00000000800028c2 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028c2:	1101                	addi	sp,sp,-32
    800028c4:	ec06                	sd	ra,24(sp)
    800028c6:	e822                	sd	s0,16(sp)
    800028c8:	e426                	sd	s1,8(sp)
    800028ca:	e04a                	sd	s2,0(sp)
    800028cc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028ce:	00015917          	auipc	s2,0x15
    800028d2:	cd290913          	addi	s2,s2,-814 # 800175a0 <tickslock>
    800028d6:	854a                	mv	a0,s2
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  ticks++;
    800028e0:	00006497          	auipc	s1,0x6
    800028e4:	02048493          	addi	s1,s1,32 # 80008900 <ticks>
    800028e8:	409c                	lw	a5,0(s1)
    800028ea:	2785                	addiw	a5,a5,1
    800028ec:	c09c                	sw	a5,0(s1)
  update_time();
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	e36080e7          	jalr	-458(ra) # 80002724 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    800028f6:	8526                	mv	a0,s1
    800028f8:	fffff097          	auipc	ra,0xfffff
    800028fc:	7d4080e7          	jalr	2004(ra) # 800020cc <wakeup>
  release(&tickslock);
    80002900:	854a                	mv	a0,s2
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	388080e7          	jalr	904(ra) # 80000c8a <release>
}
    8000290a:	60e2                	ld	ra,24(sp)
    8000290c:	6442                	ld	s0,16(sp)
    8000290e:	64a2                	ld	s1,8(sp)
    80002910:	6902                	ld	s2,0(sp)
    80002912:	6105                	addi	sp,sp,32
    80002914:	8082                	ret

0000000080002916 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002916:	1101                	addi	sp,sp,-32
    80002918:	ec06                	sd	ra,24(sp)
    8000291a:	e822                	sd	s0,16(sp)
    8000291c:	e426                	sd	s1,8(sp)
    8000291e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002920:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002924:	00074d63          	bltz	a4,8000293e <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002928:	57fd                	li	a5,-1
    8000292a:	17fe                	slli	a5,a5,0x3f
    8000292c:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    8000292e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002930:	06f70363          	beq	a4,a5,80002996 <devintr+0x80>
  }
}
    80002934:	60e2                	ld	ra,24(sp)
    80002936:	6442                	ld	s0,16(sp)
    80002938:	64a2                	ld	s1,8(sp)
    8000293a:	6105                	addi	sp,sp,32
    8000293c:	8082                	ret
      (scause & 0xff) == 9)
    8000293e:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002942:	46a5                	li	a3,9
    80002944:	fed792e3          	bne	a5,a3,80002928 <devintr+0x12>
    int irq = plic_claim();
    80002948:	00003097          	auipc	ra,0x3
    8000294c:	680080e7          	jalr	1664(ra) # 80005fc8 <plic_claim>
    80002950:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002952:	47a9                	li	a5,10
    80002954:	02f50763          	beq	a0,a5,80002982 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002958:	4785                	li	a5,1
    8000295a:	02f50963          	beq	a0,a5,8000298c <devintr+0x76>
    return 1;
    8000295e:	4505                	li	a0,1
    else if (irq)
    80002960:	d8f1                	beqz	s1,80002934 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002962:	85a6                	mv	a1,s1
    80002964:	00006517          	auipc	a0,0x6
    80002968:	99c50513          	addi	a0,a0,-1636 # 80008300 <states.0+0x38>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c1e080e7          	jalr	-994(ra) # 8000058a <printf>
      plic_complete(irq);
    80002974:	8526                	mv	a0,s1
    80002976:	00003097          	auipc	ra,0x3
    8000297a:	676080e7          	jalr	1654(ra) # 80005fec <plic_complete>
    return 1;
    8000297e:	4505                	li	a0,1
    80002980:	bf55                	j	80002934 <devintr+0x1e>
      uartintr();
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	016080e7          	jalr	22(ra) # 80000998 <uartintr>
    8000298a:	b7ed                	j	80002974 <devintr+0x5e>
      virtio_disk_intr();
    8000298c:	00004097          	auipc	ra,0x4
    80002990:	b28080e7          	jalr	-1240(ra) # 800064b4 <virtio_disk_intr>
    80002994:	b7c5                	j	80002974 <devintr+0x5e>
    if (cpuid() == 0)
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	fea080e7          	jalr	-22(ra) # 80001980 <cpuid>
    8000299e:	c901                	beqz	a0,800029ae <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029a0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029a4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029a6:	14479073          	csrw	sip,a5
    return 2;
    800029aa:	4509                	li	a0,2
    800029ac:	b761                	j	80002934 <devintr+0x1e>
      clockintr();
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	f14080e7          	jalr	-236(ra) # 800028c2 <clockintr>
    800029b6:	b7ed                	j	800029a0 <devintr+0x8a>

00000000800029b8 <usertrap>:
{
    800029b8:	1101                	addi	sp,sp,-32
    800029ba:	ec06                	sd	ra,24(sp)
    800029bc:	e822                	sd	s0,16(sp)
    800029be:	e426                	sd	s1,8(sp)
    800029c0:	e04a                	sd	s2,0(sp)
    800029c2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029c8:	1007f793          	andi	a5,a5,256
    800029cc:	e7bd                	bnez	a5,80002a3a <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ce:	00003797          	auipc	a5,0x3
    800029d2:	4f278793          	addi	a5,a5,1266 # 80005ec0 <kernelvec>
    800029d6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	fd2080e7          	jalr	-46(ra) # 800019ac <myproc>
    800029e2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029e4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e6:	14102773          	csrr	a4,sepc
    800029ea:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ec:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    800029f0:	47a1                	li	a5,8
    800029f2:	04f70c63          	beq	a4,a5,80002a4a <usertrap+0x92>
  else if ((which_dev = devintr()) != 0)
    800029f6:	00000097          	auipc	ra,0x0
    800029fa:	f20080e7          	jalr	-224(ra) # 80002916 <devintr>
    800029fe:	892a                	mv	s2,a0
    80002a00:	c561                	beqz	a0,80002ac8 <usertrap+0x110>
      if (which_dev == 2 && p->alarm_on == 0)
    80002a02:	4789                	li	a5,2
    80002a04:	06f51763          	bne	a0,a5,80002a72 <usertrap+0xba>
    80002a08:	1904a783          	lw	a5,400(s1)
    80002a0c:	ef81                	bnez	a5,80002a24 <usertrap+0x6c>
        p->cur_ticks++;
    80002a0e:	1844a783          	lw	a5,388(s1)
    80002a12:	2785                	addiw	a5,a5,1
    80002a14:	0007871b          	sext.w	a4,a5
    80002a18:	18f4a223          	sw	a5,388(s1)
        if (p->cur_ticks == p->ticks)
    80002a1c:	1804a783          	lw	a5,384(s1)
    80002a20:	06e78f63          	beq	a5,a4,80002a9e <usertrap+0xe6>
  if (killed(p))
    80002a24:	8526                	mv	a0,s1
    80002a26:	00000097          	auipc	ra,0x0
    80002a2a:	8f6080e7          	jalr	-1802(ra) # 8000231c <killed>
    80002a2e:	e17d                	bnez	a0,80002b14 <usertrap+0x15c>
    yield();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	5fc080e7          	jalr	1532(ra) # 8000202c <yield>
    80002a38:	a099                	j	80002a7e <usertrap+0xc6>
    panic("usertrap: not from user mode");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	8e650513          	addi	a0,a0,-1818 # 80008320 <states.0+0x58>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	afe080e7          	jalr	-1282(ra) # 80000540 <panic>
    if (killed(p))
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	8d2080e7          	jalr	-1838(ra) # 8000231c <killed>
    80002a52:	e121                	bnez	a0,80002a92 <usertrap+0xda>
    p->trapframe->epc += 4;
    80002a54:	6cb8                	ld	a4,88(s1)
    80002a56:	6f1c                	ld	a5,24(a4)
    80002a58:	0791                	addi	a5,a5,4
    80002a5a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a60:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a64:	10079073          	csrw	sstatus,a5
    syscall();
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	302080e7          	jalr	770(ra) # 80002d6a <syscall>
  int which_dev = 0;
    80002a70:	4901                	li	s2,0
  if (killed(p))
    80002a72:	8526                	mv	a0,s1
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	8a8080e7          	jalr	-1880(ra) # 8000231c <killed>
    80002a7c:	e159                	bnez	a0,80002b02 <usertrap+0x14a>
  usertrapret();
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	dae080e7          	jalr	-594(ra) # 8000282c <usertrapret>
}
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6902                	ld	s2,0(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret
      exit(-1);
    80002a92:	557d                	li	a0,-1
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	708080e7          	jalr	1800(ra) # 8000219c <exit>
    80002a9c:	bf65                	j	80002a54 <usertrap+0x9c>
          p->alarm_on = 1;
    80002a9e:	4785                	li	a5,1
    80002aa0:	18f4a823          	sw	a5,400(s1)
          struct trapframe *tf = kalloc();
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	042080e7          	jalr	66(ra) # 80000ae6 <kalloc>
    80002aac:	892a                	mv	s2,a0
          memmove(tf, p->trapframe, PGSIZE);
    80002aae:	6605                	lui	a2,0x1
    80002ab0:	6cac                	ld	a1,88(s1)
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	27c080e7          	jalr	636(ra) # 80000d2e <memmove>
          p->alarm_tf = tf;
    80002aba:	1924b423          	sd	s2,392(s1)
          p->trapframe->epc = p->handler;
    80002abe:	6cbc                	ld	a5,88(s1)
    80002ac0:	1784b703          	ld	a4,376(s1)
    80002ac4:	ef98                	sd	a4,24(a5)
    80002ac6:	bfb9                	j	80002a24 <usertrap+0x6c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002acc:	5890                	lw	a2,48(s1)
    80002ace:	00006517          	auipc	a0,0x6
    80002ad2:	87250513          	addi	a0,a0,-1934 # 80008340 <states.0+0x78>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	ab4080e7          	jalr	-1356(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ade:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	88a50513          	addi	a0,a0,-1910 # 80008370 <states.0+0xa8>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a9c080e7          	jalr	-1380(ra) # 8000058a <printf>
    setkilled(p);
    80002af6:	8526                	mv	a0,s1
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	7f8080e7          	jalr	2040(ra) # 800022f0 <setkilled>
    80002b00:	bf8d                	j	80002a72 <usertrap+0xba>
    exit(-1);
    80002b02:	557d                	li	a0,-1
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	698080e7          	jalr	1688(ra) # 8000219c <exit>
  if (which_dev == 2)
    80002b0c:	4789                	li	a5,2
    80002b0e:	f6f918e3          	bne	s2,a5,80002a7e <usertrap+0xc6>
    80002b12:	bf39                	j	80002a30 <usertrap+0x78>
    exit(-1);
    80002b14:	557d                	li	a0,-1
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	686080e7          	jalr	1670(ra) # 8000219c <exit>
  if (which_dev == 2)
    80002b1e:	bf09                	j	80002a30 <usertrap+0x78>

0000000080002b20 <kerneltrap>:
{
    80002b20:	7179                	addi	sp,sp,-48
    80002b22:	f406                	sd	ra,40(sp)
    80002b24:	f022                	sd	s0,32(sp)
    80002b26:	ec26                	sd	s1,24(sp)
    80002b28:	e84a                	sd	s2,16(sp)
    80002b2a:	e44e                	sd	s3,8(sp)
    80002b2c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b2e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b32:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b36:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b3a:	1004f793          	andi	a5,s1,256
    80002b3e:	cb85                	beqz	a5,80002b6e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b40:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b44:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b46:	ef85                	bnez	a5,80002b7e <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	dce080e7          	jalr	-562(ra) # 80002916 <devintr>
    80002b50:	cd1d                	beqz	a0,80002b8e <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b52:	4789                	li	a5,2
    80002b54:	06f50a63          	beq	a0,a5,80002bc8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b58:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5c:	10049073          	csrw	sstatus,s1
}
    80002b60:	70a2                	ld	ra,40(sp)
    80002b62:	7402                	ld	s0,32(sp)
    80002b64:	64e2                	ld	s1,24(sp)
    80002b66:	6942                	ld	s2,16(sp)
    80002b68:	69a2                	ld	s3,8(sp)
    80002b6a:	6145                	addi	sp,sp,48
    80002b6c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b6e:	00006517          	auipc	a0,0x6
    80002b72:	82250513          	addi	a0,a0,-2014 # 80008390 <states.0+0xc8>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	9ca080e7          	jalr	-1590(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b7e:	00006517          	auipc	a0,0x6
    80002b82:	83a50513          	addi	a0,a0,-1990 # 800083b8 <states.0+0xf0>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	9ba080e7          	jalr	-1606(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002b8e:	85ce                	mv	a1,s3
    80002b90:	00006517          	auipc	a0,0x6
    80002b94:	84850513          	addi	a0,a0,-1976 # 800083d8 <states.0+0x110>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	9f2080e7          	jalr	-1550(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ba4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	84050513          	addi	a0,a0,-1984 # 800083e8 <states.0+0x120>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	9da080e7          	jalr	-1574(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002bb8:	00006517          	auipc	a0,0x6
    80002bbc:	84850513          	addi	a0,a0,-1976 # 80008400 <states.0+0x138>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	980080e7          	jalr	-1664(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	de4080e7          	jalr	-540(ra) # 800019ac <myproc>
    80002bd0:	d541                	beqz	a0,80002b58 <kerneltrap+0x38>
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	dda080e7          	jalr	-550(ra) # 800019ac <myproc>
    80002bda:	4d18                	lw	a4,24(a0)
    80002bdc:	4791                	li	a5,4
    80002bde:	f6f71de3          	bne	a4,a5,80002b58 <kerneltrap+0x38>
    yield();
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	44a080e7          	jalr	1098(ra) # 8000202c <yield>
    80002bea:	b7bd                	j	80002b58 <kerneltrap+0x38>

0000000080002bec <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	1000                	addi	s0,sp,32
    80002bf6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bf8:	fffff097          	auipc	ra,0xfffff
    80002bfc:	db4080e7          	jalr	-588(ra) # 800019ac <myproc>
  switch (n)
    80002c00:	4795                	li	a5,5
    80002c02:	0497e163          	bltu	a5,s1,80002c44 <argraw+0x58>
    80002c06:	048a                	slli	s1,s1,0x2
    80002c08:	00006717          	auipc	a4,0x6
    80002c0c:	83070713          	addi	a4,a4,-2000 # 80008438 <states.0+0x170>
    80002c10:	94ba                	add	s1,s1,a4
    80002c12:	409c                	lw	a5,0(s1)
    80002c14:	97ba                	add	a5,a5,a4
    80002c16:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002c18:	6d3c                	ld	a5,88(a0)
    80002c1a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c1c:	60e2                	ld	ra,24(sp)
    80002c1e:	6442                	ld	s0,16(sp)
    80002c20:	64a2                	ld	s1,8(sp)
    80002c22:	6105                	addi	sp,sp,32
    80002c24:	8082                	ret
    return p->trapframe->a1;
    80002c26:	6d3c                	ld	a5,88(a0)
    80002c28:	7fa8                	ld	a0,120(a5)
    80002c2a:	bfcd                	j	80002c1c <argraw+0x30>
    return p->trapframe->a2;
    80002c2c:	6d3c                	ld	a5,88(a0)
    80002c2e:	63c8                	ld	a0,128(a5)
    80002c30:	b7f5                	j	80002c1c <argraw+0x30>
    return p->trapframe->a3;
    80002c32:	6d3c                	ld	a5,88(a0)
    80002c34:	67c8                	ld	a0,136(a5)
    80002c36:	b7dd                	j	80002c1c <argraw+0x30>
    return p->trapframe->a4;
    80002c38:	6d3c                	ld	a5,88(a0)
    80002c3a:	6bc8                	ld	a0,144(a5)
    80002c3c:	b7c5                	j	80002c1c <argraw+0x30>
    return p->trapframe->a5;
    80002c3e:	6d3c                	ld	a5,88(a0)
    80002c40:	6fc8                	ld	a0,152(a5)
    80002c42:	bfe9                	j	80002c1c <argraw+0x30>
  panic("argraw");
    80002c44:	00005517          	auipc	a0,0x5
    80002c48:	7cc50513          	addi	a0,a0,1996 # 80008410 <states.0+0x148>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	8f4080e7          	jalr	-1804(ra) # 80000540 <panic>

0000000080002c54 <fetchaddr>:
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	e426                	sd	s1,8(sp)
    80002c5c:	e04a                	sd	s2,0(sp)
    80002c5e:	1000                	addi	s0,sp,32
    80002c60:	84aa                	mv	s1,a0
    80002c62:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	d48080e7          	jalr	-696(ra) # 800019ac <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c6c:	653c                	ld	a5,72(a0)
    80002c6e:	02f4f863          	bgeu	s1,a5,80002c9e <fetchaddr+0x4a>
    80002c72:	00848713          	addi	a4,s1,8
    80002c76:	02e7e663          	bltu	a5,a4,80002ca2 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c7a:	46a1                	li	a3,8
    80002c7c:	8626                	mv	a2,s1
    80002c7e:	85ca                	mv	a1,s2
    80002c80:	6928                	ld	a0,80(a0)
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	a76080e7          	jalr	-1418(ra) # 800016f8 <copyin>
    80002c8a:	00a03533          	snez	a0,a0
    80002c8e:	40a00533          	neg	a0,a0
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6902                	ld	s2,0(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret
    return -1;
    80002c9e:	557d                	li	a0,-1
    80002ca0:	bfcd                	j	80002c92 <fetchaddr+0x3e>
    80002ca2:	557d                	li	a0,-1
    80002ca4:	b7fd                	j	80002c92 <fetchaddr+0x3e>

0000000080002ca6 <fetchstr>:
{
    80002ca6:	7179                	addi	sp,sp,-48
    80002ca8:	f406                	sd	ra,40(sp)
    80002caa:	f022                	sd	s0,32(sp)
    80002cac:	ec26                	sd	s1,24(sp)
    80002cae:	e84a                	sd	s2,16(sp)
    80002cb0:	e44e                	sd	s3,8(sp)
    80002cb2:	1800                	addi	s0,sp,48
    80002cb4:	892a                	mv	s2,a0
    80002cb6:	84ae                	mv	s1,a1
    80002cb8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	cf2080e7          	jalr	-782(ra) # 800019ac <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cc2:	86ce                	mv	a3,s3
    80002cc4:	864a                	mv	a2,s2
    80002cc6:	85a6                	mv	a1,s1
    80002cc8:	6928                	ld	a0,80(a0)
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	abc080e7          	jalr	-1348(ra) # 80001786 <copyinstr>
    80002cd2:	00054e63          	bltz	a0,80002cee <fetchstr+0x48>
  return strlen(buf);
    80002cd6:	8526                	mv	a0,s1
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	176080e7          	jalr	374(ra) # 80000e4e <strlen>
}
    80002ce0:	70a2                	ld	ra,40(sp)
    80002ce2:	7402                	ld	s0,32(sp)
    80002ce4:	64e2                	ld	s1,24(sp)
    80002ce6:	6942                	ld	s2,16(sp)
    80002ce8:	69a2                	ld	s3,8(sp)
    80002cea:	6145                	addi	sp,sp,48
    80002cec:	8082                	ret
    return -1;
    80002cee:	557d                	li	a0,-1
    80002cf0:	bfc5                	j	80002ce0 <fetchstr+0x3a>

0000000080002cf2 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	e426                	sd	s1,8(sp)
    80002cfa:	1000                	addi	s0,sp,32
    80002cfc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	eee080e7          	jalr	-274(ra) # 80002bec <argraw>
    80002d06:	c088                	sw	a0,0(s1)
}
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	64a2                	ld	s1,8(sp)
    80002d0e:	6105                	addi	sp,sp,32
    80002d10:	8082                	ret

0000000080002d12 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	1000                	addi	s0,sp,32
    80002d1c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d1e:	00000097          	auipc	ra,0x0
    80002d22:	ece080e7          	jalr	-306(ra) # 80002bec <argraw>
    80002d26:	e088                	sd	a0,0(s1)
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d32:	7179                	addi	sp,sp,-48
    80002d34:	f406                	sd	ra,40(sp)
    80002d36:	f022                	sd	s0,32(sp)
    80002d38:	ec26                	sd	s1,24(sp)
    80002d3a:	e84a                	sd	s2,16(sp)
    80002d3c:	1800                	addi	s0,sp,48
    80002d3e:	84ae                	mv	s1,a1
    80002d40:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d42:	fd840593          	addi	a1,s0,-40
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	fcc080e7          	jalr	-52(ra) # 80002d12 <argaddr>
  return fetchstr(addr, buf, max);
    80002d4e:	864a                	mv	a2,s2
    80002d50:	85a6                	mv	a1,s1
    80002d52:	fd843503          	ld	a0,-40(s0)
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	f50080e7          	jalr	-176(ra) # 80002ca6 <fetchstr>
}
    80002d5e:	70a2                	ld	ra,40(sp)
    80002d60:	7402                	ld	s0,32(sp)
    80002d62:	64e2                	ld	s1,24(sp)
    80002d64:	6942                	ld	s2,16(sp)
    80002d66:	6145                	addi	sp,sp,48
    80002d68:	8082                	ret

0000000080002d6a <syscall>:

};

void
syscall(void)
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	e04a                	sd	s2,0(sp)
    80002d74:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c36080e7          	jalr	-970(ra) # 800019ac <myproc>
    80002d7e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d80:	05853903          	ld	s2,88(a0)
    80002d84:	0a893783          	ld	a5,168(s2)
    80002d88:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d8c:	37fd                	addiw	a5,a5,-1
    80002d8e:	4761                	li	a4,24
    80002d90:	00f76f63          	bltu	a4,a5,80002dae <syscall+0x44>
    80002d94:	00369713          	slli	a4,a3,0x3
    80002d98:	00005797          	auipc	a5,0x5
    80002d9c:	6b878793          	addi	a5,a5,1720 # 80008450 <syscalls>
    80002da0:	97ba                	add	a5,a5,a4
    80002da2:	639c                	ld	a5,0(a5)
    80002da4:	c789                	beqz	a5,80002dae <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002da6:	9782                	jalr	a5
    80002da8:	06a93823          	sd	a0,112(s2)
    80002dac:	a839                	j	80002dca <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dae:	15848613          	addi	a2,s1,344
    80002db2:	588c                	lw	a1,48(s1)
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	66450513          	addi	a0,a0,1636 # 80008418 <states.0+0x150>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	7ce080e7          	jalr	1998(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dc4:	6cbc                	ld	a5,88(s1)
    80002dc6:	577d                	li	a4,-1
    80002dc8:	fbb8                	sd	a4,112(a5)
  }
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6902                	ld	s2,0(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret

0000000080002dd6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dde:	fec40593          	addi	a1,s0,-20
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	f0e080e7          	jalr	-242(ra) # 80002cf2 <argint>
  exit(n);
    80002dec:	fec42503          	lw	a0,-20(s0)
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	3ac080e7          	jalr	940(ra) # 8000219c <exit>
  return 0; // not reached
}
    80002df8:	4501                	li	a0,0
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret

0000000080002e02 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e02:	1141                	addi	sp,sp,-16
    80002e04:	e406                	sd	ra,8(sp)
    80002e06:	e022                	sd	s0,0(sp)
    80002e08:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	ba2080e7          	jalr	-1118(ra) # 800019ac <myproc>
}
    80002e12:	5908                	lw	a0,48(a0)
    80002e14:	60a2                	ld	ra,8(sp)
    80002e16:	6402                	ld	s0,0(sp)
    80002e18:	0141                	addi	sp,sp,16
    80002e1a:	8082                	ret

0000000080002e1c <sys_fork>:

uint64
sys_fork(void)
{
    80002e1c:	1141                	addi	sp,sp,-16
    80002e1e:	e406                	sd	ra,8(sp)
    80002e20:	e022                	sd	s0,0(sp)
    80002e22:	0800                	addi	s0,sp,16
  return fork();
    80002e24:	fffff097          	auipc	ra,0xfffff
    80002e28:	f52080e7          	jalr	-174(ra) # 80001d76 <fork>
}
    80002e2c:	60a2                	ld	ra,8(sp)
    80002e2e:	6402                	ld	s0,0(sp)
    80002e30:	0141                	addi	sp,sp,16
    80002e32:	8082                	ret

0000000080002e34 <sys_wait>:

uint64
sys_wait(void)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e3c:	fe840593          	addi	a1,s0,-24
    80002e40:	4501                	li	a0,0
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	ed0080e7          	jalr	-304(ra) # 80002d12 <argaddr>
  return wait(p);
    80002e4a:	fe843503          	ld	a0,-24(s0)
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	500080e7          	jalr	1280(ra) # 8000234e <wait>
}
    80002e56:	60e2                	ld	ra,24(sp)
    80002e58:	6442                	ld	s0,16(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e5e:	7179                	addi	sp,sp,-48
    80002e60:	f406                	sd	ra,40(sp)
    80002e62:	f022                	sd	s0,32(sp)
    80002e64:	ec26                	sd	s1,24(sp)
    80002e66:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e68:	fdc40593          	addi	a1,s0,-36
    80002e6c:	4501                	li	a0,0
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	e84080e7          	jalr	-380(ra) # 80002cf2 <argint>
  addr = myproc()->sz;
    80002e76:	fffff097          	auipc	ra,0xfffff
    80002e7a:	b36080e7          	jalr	-1226(ra) # 800019ac <myproc>
    80002e7e:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002e80:	fdc42503          	lw	a0,-36(s0)
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	e96080e7          	jalr	-362(ra) # 80001d1a <growproc>
    80002e8c:	00054863          	bltz	a0,80002e9c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e90:	8526                	mv	a0,s1
    80002e92:	70a2                	ld	ra,40(sp)
    80002e94:	7402                	ld	s0,32(sp)
    80002e96:	64e2                	ld	s1,24(sp)
    80002e98:	6145                	addi	sp,sp,48
    80002e9a:	8082                	ret
    return -1;
    80002e9c:	54fd                	li	s1,-1
    80002e9e:	bfcd                	j	80002e90 <sys_sbrk+0x32>

0000000080002ea0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ea0:	7139                	addi	sp,sp,-64
    80002ea2:	fc06                	sd	ra,56(sp)
    80002ea4:	f822                	sd	s0,48(sp)
    80002ea6:	f426                	sd	s1,40(sp)
    80002ea8:	f04a                	sd	s2,32(sp)
    80002eaa:	ec4e                	sd	s3,24(sp)
    80002eac:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002eae:	fcc40593          	addi	a1,s0,-52
    80002eb2:	4501                	li	a0,0
    80002eb4:	00000097          	auipc	ra,0x0
    80002eb8:	e3e080e7          	jalr	-450(ra) # 80002cf2 <argint>
  acquire(&tickslock);
    80002ebc:	00014517          	auipc	a0,0x14
    80002ec0:	6e450513          	addi	a0,a0,1764 # 800175a0 <tickslock>
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	d12080e7          	jalr	-750(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ecc:	00006917          	auipc	s2,0x6
    80002ed0:	a3492903          	lw	s2,-1484(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002ed4:	fcc42783          	lw	a5,-52(s0)
    80002ed8:	cf9d                	beqz	a5,80002f16 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eda:	00014997          	auipc	s3,0x14
    80002ede:	6c698993          	addi	s3,s3,1734 # 800175a0 <tickslock>
    80002ee2:	00006497          	auipc	s1,0x6
    80002ee6:	a1e48493          	addi	s1,s1,-1506 # 80008900 <ticks>
    if (killed(myproc()))
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	ac2080e7          	jalr	-1342(ra) # 800019ac <myproc>
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	42a080e7          	jalr	1066(ra) # 8000231c <killed>
    80002efa:	ed15                	bnez	a0,80002f36 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002efc:	85ce                	mv	a1,s3
    80002efe:	8526                	mv	a0,s1
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	168080e7          	jalr	360(ra) # 80002068 <sleep>
  while (ticks - ticks0 < n)
    80002f08:	409c                	lw	a5,0(s1)
    80002f0a:	412787bb          	subw	a5,a5,s2
    80002f0e:	fcc42703          	lw	a4,-52(s0)
    80002f12:	fce7ece3          	bltu	a5,a4,80002eea <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f16:	00014517          	auipc	a0,0x14
    80002f1a:	68a50513          	addi	a0,a0,1674 # 800175a0 <tickslock>
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	d6c080e7          	jalr	-660(ra) # 80000c8a <release>
  return 0;
    80002f26:	4501                	li	a0,0
}
    80002f28:	70e2                	ld	ra,56(sp)
    80002f2a:	7442                	ld	s0,48(sp)
    80002f2c:	74a2                	ld	s1,40(sp)
    80002f2e:	7902                	ld	s2,32(sp)
    80002f30:	69e2                	ld	s3,24(sp)
    80002f32:	6121                	addi	sp,sp,64
    80002f34:	8082                	ret
      release(&tickslock);
    80002f36:	00014517          	auipc	a0,0x14
    80002f3a:	66a50513          	addi	a0,a0,1642 # 800175a0 <tickslock>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	d4c080e7          	jalr	-692(ra) # 80000c8a <release>
      return -1;
    80002f46:	557d                	li	a0,-1
    80002f48:	b7c5                	j	80002f28 <sys_sleep+0x88>

0000000080002f4a <sys_kill>:

uint64
sys_kill(void)
{
    80002f4a:	1101                	addi	sp,sp,-32
    80002f4c:	ec06                	sd	ra,24(sp)
    80002f4e:	e822                	sd	s0,16(sp)
    80002f50:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f52:	fec40593          	addi	a1,s0,-20
    80002f56:	4501                	li	a0,0
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	d9a080e7          	jalr	-614(ra) # 80002cf2 <argint>
  return kill(pid);
    80002f60:	fec42503          	lw	a0,-20(s0)
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	31a080e7          	jalr	794(ra) # 8000227e <kill>
}
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	6105                	addi	sp,sp,32
    80002f72:	8082                	ret

0000000080002f74 <sys_sigalarm>:
uint64 sys_sigalarm(void)
{
    80002f74:	1101                	addi	sp,sp,-32
    80002f76:	ec06                	sd	ra,24(sp)
    80002f78:	e822                	sd	s0,16(sp)
    80002f7a:	1000                	addi	s0,sp,32
  // source: https://xiayingp.gitbook.io/build_a_os/labs/lab-6-alarm
  uint64 addr;
  int ticks;

  argint(0, &ticks);
    80002f7c:	fe440593          	addi	a1,s0,-28
    80002f80:	4501                	li	a0,0
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	d70080e7          	jalr	-656(ra) # 80002cf2 <argint>
  argaddr(1, &addr);
    80002f8a:	fe840593          	addi	a1,s0,-24
    80002f8e:	4505                	li	a0,1
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	d82080e7          	jalr	-638(ra) # 80002d12 <argaddr>

  myproc()->cur_ticks = 0;
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	a14080e7          	jalr	-1516(ra) # 800019ac <myproc>
    80002fa0:	18052223          	sw	zero,388(a0)
  myproc()->ticks = ticks;
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	a08080e7          	jalr	-1528(ra) # 800019ac <myproc>
    80002fac:	fe442783          	lw	a5,-28(s0)
    80002fb0:	18f52023          	sw	a5,384(a0)
  myproc()->handler = addr;
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	9f8080e7          	jalr	-1544(ra) # 800019ac <myproc>
    80002fbc:	fe843783          	ld	a5,-24(s0)
    80002fc0:	16f53c23          	sd	a5,376(a0)
  myproc()->alarm_on = 0;
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	9e8080e7          	jalr	-1560(ra) # 800019ac <myproc>
    80002fcc:	18052823          	sw	zero,400(a0)

  return 0;
}
    80002fd0:	4501                	li	a0,0
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	9c8080e7          	jalr	-1592(ra) # 800019ac <myproc>
  
  if(p->alarm_on == 1){
    80002fec:	19052703          	lw	a4,400(a0)
    80002ff0:	4785                	li	a5,1
    80002ff2:	00f70863          	beq	a4,a5,80003002 <sys_sigreturn+0x28>
    p->alarm_tf = 0;
    p->alarm_on = 0;
    p->cur_ticks = 0;
  }
  return 0;
}
    80002ff6:	4501                	li	a0,0
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	64a2                	ld	s1,8(sp)
    80002ffe:	6105                	addi	sp,sp,32
    80003000:	8082                	ret
    80003002:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarm_tf, PGSIZE);
    80003004:	6605                	lui	a2,0x1
    80003006:	18853583          	ld	a1,392(a0)
    8000300a:	6d28                	ld	a0,88(a0)
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	d22080e7          	jalr	-734(ra) # 80000d2e <memmove>
    kfree(p->alarm_tf);
    80003014:	1884b503          	ld	a0,392(s1)
    80003018:	ffffe097          	auipc	ra,0xffffe
    8000301c:	9d0080e7          	jalr	-1584(ra) # 800009e8 <kfree>
    p->alarm_tf = 0;
    80003020:	1804b423          	sd	zero,392(s1)
    p->alarm_on = 0;
    80003024:	1804a823          	sw	zero,400(s1)
    p->cur_ticks = 0;
    80003028:	1804a223          	sw	zero,388(s1)
    8000302c:	b7e9                	j	80002ff6 <sys_sigreturn+0x1c>

000000008000302e <sys_uptime>:
// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003038:	00014517          	auipc	a0,0x14
    8000303c:	56850513          	addi	a0,a0,1384 # 800175a0 <tickslock>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	b96080e7          	jalr	-1130(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003048:	00006497          	auipc	s1,0x6
    8000304c:	8b84a483          	lw	s1,-1864(s1) # 80008900 <ticks>
  release(&tickslock);
    80003050:	00014517          	auipc	a0,0x14
    80003054:	55050513          	addi	a0,a0,1360 # 800175a0 <tickslock>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c32080e7          	jalr	-974(ra) # 80000c8a <release>
  return xticks;
}
    80003060:	02049513          	slli	a0,s1,0x20
    80003064:	9101                	srli	a0,a0,0x20
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	64a2                	ld	s1,8(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret

0000000080003070 <sys_getreadcount>:
extern uint64 myreadcount;

uint64 sys_getreadcount(void)
{
    80003070:	1141                	addi	sp,sp,-16
    80003072:	e422                	sd	s0,8(sp)
    80003074:	0800                	addi	s0,sp,16
  return myreadcount;
}
    80003076:	00006517          	auipc	a0,0x6
    8000307a:	89253503          	ld	a0,-1902(a0) # 80008908 <myreadcount>
    8000307e:	6422                	ld	s0,8(sp)
    80003080:	0141                	addi	sp,sp,16
    80003082:	8082                	ret

0000000080003084 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003084:	7139                	addi	sp,sp,-64
    80003086:	fc06                	sd	ra,56(sp)
    80003088:	f822                	sd	s0,48(sp)
    8000308a:	f426                	sd	s1,40(sp)
    8000308c:	f04a                	sd	s2,32(sp)
    8000308e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003090:	fd840593          	addi	a1,s0,-40
    80003094:	4501                	li	a0,0
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	c7c080e7          	jalr	-900(ra) # 80002d12 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000309e:	fd040593          	addi	a1,s0,-48
    800030a2:	4505                	li	a0,1
    800030a4:	00000097          	auipc	ra,0x0
    800030a8:	c6e080e7          	jalr	-914(ra) # 80002d12 <argaddr>
  argaddr(2, &addr2);
    800030ac:	fc840593          	addi	a1,s0,-56
    800030b0:	4509                	li	a0,2
    800030b2:	00000097          	auipc	ra,0x0
    800030b6:	c60080e7          	jalr	-928(ra) # 80002d12 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800030ba:	fc040613          	addi	a2,s0,-64
    800030be:	fc440593          	addi	a1,s0,-60
    800030c2:	fd843503          	ld	a0,-40(s0)
    800030c6:	fffff097          	auipc	ra,0xfffff
    800030ca:	512080e7          	jalr	1298(ra) # 800025d8 <waitx>
    800030ce:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	8dc080e7          	jalr	-1828(ra) # 800019ac <myproc>
    800030d8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030da:	4691                	li	a3,4
    800030dc:	fc440613          	addi	a2,s0,-60
    800030e0:	fd043583          	ld	a1,-48(s0)
    800030e4:	6928                	ld	a0,80(a0)
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	586080e7          	jalr	1414(ra) # 8000166c <copyout>
    return -1;
    800030ee:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030f0:	00054f63          	bltz	a0,8000310e <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800030f4:	4691                	li	a3,4
    800030f6:	fc040613          	addi	a2,s0,-64
    800030fa:	fc843583          	ld	a1,-56(s0)
    800030fe:	68a8                	ld	a0,80(s1)
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	56c080e7          	jalr	1388(ra) # 8000166c <copyout>
    80003108:	00054a63          	bltz	a0,8000311c <sys_waitx+0x98>
    return -1;
  return ret;
    8000310c:	87ca                	mv	a5,s2
    8000310e:	853e                	mv	a0,a5
    80003110:	70e2                	ld	ra,56(sp)
    80003112:	7442                	ld	s0,48(sp)
    80003114:	74a2                	ld	s1,40(sp)
    80003116:	7902                	ld	s2,32(sp)
    80003118:	6121                	addi	sp,sp,64
    8000311a:	8082                	ret
    return -1;
    8000311c:	57fd                	li	a5,-1
    8000311e:	bfc5                	j	8000310e <sys_waitx+0x8a>

0000000080003120 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003120:	7179                	addi	sp,sp,-48
    80003122:	f406                	sd	ra,40(sp)
    80003124:	f022                	sd	s0,32(sp)
    80003126:	ec26                	sd	s1,24(sp)
    80003128:	e84a                	sd	s2,16(sp)
    8000312a:	e44e                	sd	s3,8(sp)
    8000312c:	e052                	sd	s4,0(sp)
    8000312e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003130:	00005597          	auipc	a1,0x5
    80003134:	3f058593          	addi	a1,a1,1008 # 80008520 <syscalls+0xd0>
    80003138:	00014517          	auipc	a0,0x14
    8000313c:	48050513          	addi	a0,a0,1152 # 800175b8 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	a06080e7          	jalr	-1530(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003148:	0001c797          	auipc	a5,0x1c
    8000314c:	47078793          	addi	a5,a5,1136 # 8001f5b8 <bcache+0x8000>
    80003150:	0001c717          	auipc	a4,0x1c
    80003154:	6d070713          	addi	a4,a4,1744 # 8001f820 <bcache+0x8268>
    80003158:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000315c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003160:	00014497          	auipc	s1,0x14
    80003164:	47048493          	addi	s1,s1,1136 # 800175d0 <bcache+0x18>
    b->next = bcache.head.next;
    80003168:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000316a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000316c:	00005a17          	auipc	s4,0x5
    80003170:	3bca0a13          	addi	s4,s4,956 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003174:	2b893783          	ld	a5,696(s2)
    80003178:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000317a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000317e:	85d2                	mv	a1,s4
    80003180:	01048513          	addi	a0,s1,16
    80003184:	00001097          	auipc	ra,0x1
    80003188:	4c8080e7          	jalr	1224(ra) # 8000464c <initsleeplock>
    bcache.head.next->prev = b;
    8000318c:	2b893783          	ld	a5,696(s2)
    80003190:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003192:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003196:	45848493          	addi	s1,s1,1112
    8000319a:	fd349de3          	bne	s1,s3,80003174 <binit+0x54>
  }
}
    8000319e:	70a2                	ld	ra,40(sp)
    800031a0:	7402                	ld	s0,32(sp)
    800031a2:	64e2                	ld	s1,24(sp)
    800031a4:	6942                	ld	s2,16(sp)
    800031a6:	69a2                	ld	s3,8(sp)
    800031a8:	6a02                	ld	s4,0(sp)
    800031aa:	6145                	addi	sp,sp,48
    800031ac:	8082                	ret

00000000800031ae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031ae:	7179                	addi	sp,sp,-48
    800031b0:	f406                	sd	ra,40(sp)
    800031b2:	f022                	sd	s0,32(sp)
    800031b4:	ec26                	sd	s1,24(sp)
    800031b6:	e84a                	sd	s2,16(sp)
    800031b8:	e44e                	sd	s3,8(sp)
    800031ba:	1800                	addi	s0,sp,48
    800031bc:	892a                	mv	s2,a0
    800031be:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031c0:	00014517          	auipc	a0,0x14
    800031c4:	3f850513          	addi	a0,a0,1016 # 800175b8 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	a0e080e7          	jalr	-1522(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031d0:	0001c497          	auipc	s1,0x1c
    800031d4:	6a04b483          	ld	s1,1696(s1) # 8001f870 <bcache+0x82b8>
    800031d8:	0001c797          	auipc	a5,0x1c
    800031dc:	64878793          	addi	a5,a5,1608 # 8001f820 <bcache+0x8268>
    800031e0:	02f48f63          	beq	s1,a5,8000321e <bread+0x70>
    800031e4:	873e                	mv	a4,a5
    800031e6:	a021                	j	800031ee <bread+0x40>
    800031e8:	68a4                	ld	s1,80(s1)
    800031ea:	02e48a63          	beq	s1,a4,8000321e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031ee:	449c                	lw	a5,8(s1)
    800031f0:	ff279ce3          	bne	a5,s2,800031e8 <bread+0x3a>
    800031f4:	44dc                	lw	a5,12(s1)
    800031f6:	ff3799e3          	bne	a5,s3,800031e8 <bread+0x3a>
      b->refcnt++;
    800031fa:	40bc                	lw	a5,64(s1)
    800031fc:	2785                	addiw	a5,a5,1
    800031fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003200:	00014517          	auipc	a0,0x14
    80003204:	3b850513          	addi	a0,a0,952 # 800175b8 <bcache>
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	a82080e7          	jalr	-1406(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003210:	01048513          	addi	a0,s1,16
    80003214:	00001097          	auipc	ra,0x1
    80003218:	472080e7          	jalr	1138(ra) # 80004686 <acquiresleep>
      return b;
    8000321c:	a8b9                	j	8000327a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000321e:	0001c497          	auipc	s1,0x1c
    80003222:	64a4b483          	ld	s1,1610(s1) # 8001f868 <bcache+0x82b0>
    80003226:	0001c797          	auipc	a5,0x1c
    8000322a:	5fa78793          	addi	a5,a5,1530 # 8001f820 <bcache+0x8268>
    8000322e:	00f48863          	beq	s1,a5,8000323e <bread+0x90>
    80003232:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003234:	40bc                	lw	a5,64(s1)
    80003236:	cf81                	beqz	a5,8000324e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003238:	64a4                	ld	s1,72(s1)
    8000323a:	fee49de3          	bne	s1,a4,80003234 <bread+0x86>
  panic("bget: no buffers");
    8000323e:	00005517          	auipc	a0,0x5
    80003242:	2f250513          	addi	a0,a0,754 # 80008530 <syscalls+0xe0>
    80003246:	ffffd097          	auipc	ra,0xffffd
    8000324a:	2fa080e7          	jalr	762(ra) # 80000540 <panic>
      b->dev = dev;
    8000324e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003252:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003256:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000325a:	4785                	li	a5,1
    8000325c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	35a50513          	addi	a0,a0,858 # 800175b8 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	a24080e7          	jalr	-1500(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000326e:	01048513          	addi	a0,s1,16
    80003272:	00001097          	auipc	ra,0x1
    80003276:	414080e7          	jalr	1044(ra) # 80004686 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000327a:	409c                	lw	a5,0(s1)
    8000327c:	cb89                	beqz	a5,8000328e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000327e:	8526                	mv	a0,s1
    80003280:	70a2                	ld	ra,40(sp)
    80003282:	7402                	ld	s0,32(sp)
    80003284:	64e2                	ld	s1,24(sp)
    80003286:	6942                	ld	s2,16(sp)
    80003288:	69a2                	ld	s3,8(sp)
    8000328a:	6145                	addi	sp,sp,48
    8000328c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000328e:	4581                	li	a1,0
    80003290:	8526                	mv	a0,s1
    80003292:	00003097          	auipc	ra,0x3
    80003296:	ff0080e7          	jalr	-16(ra) # 80006282 <virtio_disk_rw>
    b->valid = 1;
    8000329a:	4785                	li	a5,1
    8000329c:	c09c                	sw	a5,0(s1)
  return b;
    8000329e:	b7c5                	j	8000327e <bread+0xd0>

00000000800032a0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	1000                	addi	s0,sp,32
    800032aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ac:	0541                	addi	a0,a0,16
    800032ae:	00001097          	auipc	ra,0x1
    800032b2:	472080e7          	jalr	1138(ra) # 80004720 <holdingsleep>
    800032b6:	cd01                	beqz	a0,800032ce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032b8:	4585                	li	a1,1
    800032ba:	8526                	mv	a0,s1
    800032bc:	00003097          	auipc	ra,0x3
    800032c0:	fc6080e7          	jalr	-58(ra) # 80006282 <virtio_disk_rw>
}
    800032c4:	60e2                	ld	ra,24(sp)
    800032c6:	6442                	ld	s0,16(sp)
    800032c8:	64a2                	ld	s1,8(sp)
    800032ca:	6105                	addi	sp,sp,32
    800032cc:	8082                	ret
    panic("bwrite");
    800032ce:	00005517          	auipc	a0,0x5
    800032d2:	27a50513          	addi	a0,a0,634 # 80008548 <syscalls+0xf8>
    800032d6:	ffffd097          	auipc	ra,0xffffd
    800032da:	26a080e7          	jalr	618(ra) # 80000540 <panic>

00000000800032de <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032de:	1101                	addi	sp,sp,-32
    800032e0:	ec06                	sd	ra,24(sp)
    800032e2:	e822                	sd	s0,16(sp)
    800032e4:	e426                	sd	s1,8(sp)
    800032e6:	e04a                	sd	s2,0(sp)
    800032e8:	1000                	addi	s0,sp,32
    800032ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ec:	01050913          	addi	s2,a0,16
    800032f0:	854a                	mv	a0,s2
    800032f2:	00001097          	auipc	ra,0x1
    800032f6:	42e080e7          	jalr	1070(ra) # 80004720 <holdingsleep>
    800032fa:	c92d                	beqz	a0,8000336c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032fc:	854a                	mv	a0,s2
    800032fe:	00001097          	auipc	ra,0x1
    80003302:	3de080e7          	jalr	990(ra) # 800046dc <releasesleep>

  acquire(&bcache.lock);
    80003306:	00014517          	auipc	a0,0x14
    8000330a:	2b250513          	addi	a0,a0,690 # 800175b8 <bcache>
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	8c8080e7          	jalr	-1848(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003316:	40bc                	lw	a5,64(s1)
    80003318:	37fd                	addiw	a5,a5,-1
    8000331a:	0007871b          	sext.w	a4,a5
    8000331e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003320:	eb05                	bnez	a4,80003350 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003322:	68bc                	ld	a5,80(s1)
    80003324:	64b8                	ld	a4,72(s1)
    80003326:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003328:	64bc                	ld	a5,72(s1)
    8000332a:	68b8                	ld	a4,80(s1)
    8000332c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000332e:	0001c797          	auipc	a5,0x1c
    80003332:	28a78793          	addi	a5,a5,650 # 8001f5b8 <bcache+0x8000>
    80003336:	2b87b703          	ld	a4,696(a5)
    8000333a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000333c:	0001c717          	auipc	a4,0x1c
    80003340:	4e470713          	addi	a4,a4,1252 # 8001f820 <bcache+0x8268>
    80003344:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003346:	2b87b703          	ld	a4,696(a5)
    8000334a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000334c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003350:	00014517          	auipc	a0,0x14
    80003354:	26850513          	addi	a0,a0,616 # 800175b8 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>
}
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	64a2                	ld	s1,8(sp)
    80003366:	6902                	ld	s2,0(sp)
    80003368:	6105                	addi	sp,sp,32
    8000336a:	8082                	ret
    panic("brelse");
    8000336c:	00005517          	auipc	a0,0x5
    80003370:	1e450513          	addi	a0,a0,484 # 80008550 <syscalls+0x100>
    80003374:	ffffd097          	auipc	ra,0xffffd
    80003378:	1cc080e7          	jalr	460(ra) # 80000540 <panic>

000000008000337c <bpin>:

void
bpin(struct buf *b) {
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	1000                	addi	s0,sp,32
    80003386:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003388:	00014517          	auipc	a0,0x14
    8000338c:	23050513          	addi	a0,a0,560 # 800175b8 <bcache>
    80003390:	ffffe097          	auipc	ra,0xffffe
    80003394:	846080e7          	jalr	-1978(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003398:	40bc                	lw	a5,64(s1)
    8000339a:	2785                	addiw	a5,a5,1
    8000339c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000339e:	00014517          	auipc	a0,0x14
    800033a2:	21a50513          	addi	a0,a0,538 # 800175b8 <bcache>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	8e4080e7          	jalr	-1820(ra) # 80000c8a <release>
}
    800033ae:	60e2                	ld	ra,24(sp)
    800033b0:	6442                	ld	s0,16(sp)
    800033b2:	64a2                	ld	s1,8(sp)
    800033b4:	6105                	addi	sp,sp,32
    800033b6:	8082                	ret

00000000800033b8 <bunpin>:

void
bunpin(struct buf *b) {
    800033b8:	1101                	addi	sp,sp,-32
    800033ba:	ec06                	sd	ra,24(sp)
    800033bc:	e822                	sd	s0,16(sp)
    800033be:	e426                	sd	s1,8(sp)
    800033c0:	1000                	addi	s0,sp,32
    800033c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033c4:	00014517          	auipc	a0,0x14
    800033c8:	1f450513          	addi	a0,a0,500 # 800175b8 <bcache>
    800033cc:	ffffe097          	auipc	ra,0xffffe
    800033d0:	80a080e7          	jalr	-2038(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033d4:	40bc                	lw	a5,64(s1)
    800033d6:	37fd                	addiw	a5,a5,-1
    800033d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033da:	00014517          	auipc	a0,0x14
    800033de:	1de50513          	addi	a0,a0,478 # 800175b8 <bcache>
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	8a8080e7          	jalr	-1880(ra) # 80000c8a <release>
}
    800033ea:	60e2                	ld	ra,24(sp)
    800033ec:	6442                	ld	s0,16(sp)
    800033ee:	64a2                	ld	s1,8(sp)
    800033f0:	6105                	addi	sp,sp,32
    800033f2:	8082                	ret

00000000800033f4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033f4:	1101                	addi	sp,sp,-32
    800033f6:	ec06                	sd	ra,24(sp)
    800033f8:	e822                	sd	s0,16(sp)
    800033fa:	e426                	sd	s1,8(sp)
    800033fc:	e04a                	sd	s2,0(sp)
    800033fe:	1000                	addi	s0,sp,32
    80003400:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003402:	00d5d59b          	srliw	a1,a1,0xd
    80003406:	0001d797          	auipc	a5,0x1d
    8000340a:	88e7a783          	lw	a5,-1906(a5) # 8001fc94 <sb+0x1c>
    8000340e:	9dbd                	addw	a1,a1,a5
    80003410:	00000097          	auipc	ra,0x0
    80003414:	d9e080e7          	jalr	-610(ra) # 800031ae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003418:	0074f713          	andi	a4,s1,7
    8000341c:	4785                	li	a5,1
    8000341e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003422:	14ce                	slli	s1,s1,0x33
    80003424:	90d9                	srli	s1,s1,0x36
    80003426:	00950733          	add	a4,a0,s1
    8000342a:	05874703          	lbu	a4,88(a4)
    8000342e:	00e7f6b3          	and	a3,a5,a4
    80003432:	c69d                	beqz	a3,80003460 <bfree+0x6c>
    80003434:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003436:	94aa                	add	s1,s1,a0
    80003438:	fff7c793          	not	a5,a5
    8000343c:	8f7d                	and	a4,a4,a5
    8000343e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003442:	00001097          	auipc	ra,0x1
    80003446:	126080e7          	jalr	294(ra) # 80004568 <log_write>
  brelse(bp);
    8000344a:	854a                	mv	a0,s2
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	e92080e7          	jalr	-366(ra) # 800032de <brelse>
}
    80003454:	60e2                	ld	ra,24(sp)
    80003456:	6442                	ld	s0,16(sp)
    80003458:	64a2                	ld	s1,8(sp)
    8000345a:	6902                	ld	s2,0(sp)
    8000345c:	6105                	addi	sp,sp,32
    8000345e:	8082                	ret
    panic("freeing free block");
    80003460:	00005517          	auipc	a0,0x5
    80003464:	0f850513          	addi	a0,a0,248 # 80008558 <syscalls+0x108>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	0d8080e7          	jalr	216(ra) # 80000540 <panic>

0000000080003470 <balloc>:
{
    80003470:	711d                	addi	sp,sp,-96
    80003472:	ec86                	sd	ra,88(sp)
    80003474:	e8a2                	sd	s0,80(sp)
    80003476:	e4a6                	sd	s1,72(sp)
    80003478:	e0ca                	sd	s2,64(sp)
    8000347a:	fc4e                	sd	s3,56(sp)
    8000347c:	f852                	sd	s4,48(sp)
    8000347e:	f456                	sd	s5,40(sp)
    80003480:	f05a                	sd	s6,32(sp)
    80003482:	ec5e                	sd	s7,24(sp)
    80003484:	e862                	sd	s8,16(sp)
    80003486:	e466                	sd	s9,8(sp)
    80003488:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000348a:	0001c797          	auipc	a5,0x1c
    8000348e:	7f27a783          	lw	a5,2034(a5) # 8001fc7c <sb+0x4>
    80003492:	cff5                	beqz	a5,8000358e <balloc+0x11e>
    80003494:	8baa                	mv	s7,a0
    80003496:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003498:	0001cb17          	auipc	s6,0x1c
    8000349c:	7e0b0b13          	addi	s6,s6,2016 # 8001fc78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034a2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034a6:	6c89                	lui	s9,0x2
    800034a8:	a061                	j	80003530 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034aa:	97ca                	add	a5,a5,s2
    800034ac:	8e55                	or	a2,a2,a3
    800034ae:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034b2:	854a                	mv	a0,s2
    800034b4:	00001097          	auipc	ra,0x1
    800034b8:	0b4080e7          	jalr	180(ra) # 80004568 <log_write>
        brelse(bp);
    800034bc:	854a                	mv	a0,s2
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	e20080e7          	jalr	-480(ra) # 800032de <brelse>
  bp = bread(dev, bno);
    800034c6:	85a6                	mv	a1,s1
    800034c8:	855e                	mv	a0,s7
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	ce4080e7          	jalr	-796(ra) # 800031ae <bread>
    800034d2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034d4:	40000613          	li	a2,1024
    800034d8:	4581                	li	a1,0
    800034da:	05850513          	addi	a0,a0,88
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7f4080e7          	jalr	2036(ra) # 80000cd2 <memset>
  log_write(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	080080e7          	jalr	128(ra) # 80004568 <log_write>
  brelse(bp);
    800034f0:	854a                	mv	a0,s2
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	dec080e7          	jalr	-532(ra) # 800032de <brelse>
}
    800034fa:	8526                	mv	a0,s1
    800034fc:	60e6                	ld	ra,88(sp)
    800034fe:	6446                	ld	s0,80(sp)
    80003500:	64a6                	ld	s1,72(sp)
    80003502:	6906                	ld	s2,64(sp)
    80003504:	79e2                	ld	s3,56(sp)
    80003506:	7a42                	ld	s4,48(sp)
    80003508:	7aa2                	ld	s5,40(sp)
    8000350a:	7b02                	ld	s6,32(sp)
    8000350c:	6be2                	ld	s7,24(sp)
    8000350e:	6c42                	ld	s8,16(sp)
    80003510:	6ca2                	ld	s9,8(sp)
    80003512:	6125                	addi	sp,sp,96
    80003514:	8082                	ret
    brelse(bp);
    80003516:	854a                	mv	a0,s2
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	dc6080e7          	jalr	-570(ra) # 800032de <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003520:	015c87bb          	addw	a5,s9,s5
    80003524:	00078a9b          	sext.w	s5,a5
    80003528:	004b2703          	lw	a4,4(s6)
    8000352c:	06eaf163          	bgeu	s5,a4,8000358e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003530:	41fad79b          	sraiw	a5,s5,0x1f
    80003534:	0137d79b          	srliw	a5,a5,0x13
    80003538:	015787bb          	addw	a5,a5,s5
    8000353c:	40d7d79b          	sraiw	a5,a5,0xd
    80003540:	01cb2583          	lw	a1,28(s6)
    80003544:	9dbd                	addw	a1,a1,a5
    80003546:	855e                	mv	a0,s7
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	c66080e7          	jalr	-922(ra) # 800031ae <bread>
    80003550:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003552:	004b2503          	lw	a0,4(s6)
    80003556:	000a849b          	sext.w	s1,s5
    8000355a:	8762                	mv	a4,s8
    8000355c:	faa4fde3          	bgeu	s1,a0,80003516 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003560:	00777693          	andi	a3,a4,7
    80003564:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003568:	41f7579b          	sraiw	a5,a4,0x1f
    8000356c:	01d7d79b          	srliw	a5,a5,0x1d
    80003570:	9fb9                	addw	a5,a5,a4
    80003572:	4037d79b          	sraiw	a5,a5,0x3
    80003576:	00f90633          	add	a2,s2,a5
    8000357a:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000357e:	00c6f5b3          	and	a1,a3,a2
    80003582:	d585                	beqz	a1,800034aa <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003584:	2705                	addiw	a4,a4,1
    80003586:	2485                	addiw	s1,s1,1
    80003588:	fd471ae3          	bne	a4,s4,8000355c <balloc+0xec>
    8000358c:	b769                	j	80003516 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	fe250513          	addi	a0,a0,-30 # 80008570 <syscalls+0x120>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	ff4080e7          	jalr	-12(ra) # 8000058a <printf>
  return 0;
    8000359e:	4481                	li	s1,0
    800035a0:	bfa9                	j	800034fa <balloc+0x8a>

00000000800035a2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	ec26                	sd	s1,24(sp)
    800035aa:	e84a                	sd	s2,16(sp)
    800035ac:	e44e                	sd	s3,8(sp)
    800035ae:	e052                	sd	s4,0(sp)
    800035b0:	1800                	addi	s0,sp,48
    800035b2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035b4:	47ad                	li	a5,11
    800035b6:	02b7e863          	bltu	a5,a1,800035e6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800035ba:	02059793          	slli	a5,a1,0x20
    800035be:	01e7d593          	srli	a1,a5,0x1e
    800035c2:	00b504b3          	add	s1,a0,a1
    800035c6:	0504a903          	lw	s2,80(s1)
    800035ca:	06091e63          	bnez	s2,80003646 <bmap+0xa4>
      addr = balloc(ip->dev);
    800035ce:	4108                	lw	a0,0(a0)
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	ea0080e7          	jalr	-352(ra) # 80003470 <balloc>
    800035d8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035dc:	06090563          	beqz	s2,80003646 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800035e0:	0524a823          	sw	s2,80(s1)
    800035e4:	a08d                	j	80003646 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035e6:	ff45849b          	addiw	s1,a1,-12
    800035ea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035ee:	0ff00793          	li	a5,255
    800035f2:	08e7e563          	bltu	a5,a4,8000367c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035f6:	08052903          	lw	s2,128(a0)
    800035fa:	00091d63          	bnez	s2,80003614 <bmap+0x72>
      addr = balloc(ip->dev);
    800035fe:	4108                	lw	a0,0(a0)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	e70080e7          	jalr	-400(ra) # 80003470 <balloc>
    80003608:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000360c:	02090d63          	beqz	s2,80003646 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003610:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003614:	85ca                	mv	a1,s2
    80003616:	0009a503          	lw	a0,0(s3)
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	b94080e7          	jalr	-1132(ra) # 800031ae <bread>
    80003622:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003624:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003628:	02049713          	slli	a4,s1,0x20
    8000362c:	01e75593          	srli	a1,a4,0x1e
    80003630:	00b784b3          	add	s1,a5,a1
    80003634:	0004a903          	lw	s2,0(s1)
    80003638:	02090063          	beqz	s2,80003658 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000363c:	8552                	mv	a0,s4
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	ca0080e7          	jalr	-864(ra) # 800032de <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003646:	854a                	mv	a0,s2
    80003648:	70a2                	ld	ra,40(sp)
    8000364a:	7402                	ld	s0,32(sp)
    8000364c:	64e2                	ld	s1,24(sp)
    8000364e:	6942                	ld	s2,16(sp)
    80003650:	69a2                	ld	s3,8(sp)
    80003652:	6a02                	ld	s4,0(sp)
    80003654:	6145                	addi	sp,sp,48
    80003656:	8082                	ret
      addr = balloc(ip->dev);
    80003658:	0009a503          	lw	a0,0(s3)
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	e14080e7          	jalr	-492(ra) # 80003470 <balloc>
    80003664:	0005091b          	sext.w	s2,a0
      if(addr){
    80003668:	fc090ae3          	beqz	s2,8000363c <bmap+0x9a>
        a[bn] = addr;
    8000366c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003670:	8552                	mv	a0,s4
    80003672:	00001097          	auipc	ra,0x1
    80003676:	ef6080e7          	jalr	-266(ra) # 80004568 <log_write>
    8000367a:	b7c9                	j	8000363c <bmap+0x9a>
  panic("bmap: out of range");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	f0c50513          	addi	a0,a0,-244 # 80008588 <syscalls+0x138>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	ebc080e7          	jalr	-324(ra) # 80000540 <panic>

000000008000368c <iget>:
{
    8000368c:	7179                	addi	sp,sp,-48
    8000368e:	f406                	sd	ra,40(sp)
    80003690:	f022                	sd	s0,32(sp)
    80003692:	ec26                	sd	s1,24(sp)
    80003694:	e84a                	sd	s2,16(sp)
    80003696:	e44e                	sd	s3,8(sp)
    80003698:	e052                	sd	s4,0(sp)
    8000369a:	1800                	addi	s0,sp,48
    8000369c:	89aa                	mv	s3,a0
    8000369e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036a0:	0001c517          	auipc	a0,0x1c
    800036a4:	5f850513          	addi	a0,a0,1528 # 8001fc98 <itable>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	52e080e7          	jalr	1326(ra) # 80000bd6 <acquire>
  empty = 0;
    800036b0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036b2:	0001c497          	auipc	s1,0x1c
    800036b6:	5fe48493          	addi	s1,s1,1534 # 8001fcb0 <itable+0x18>
    800036ba:	0001e697          	auipc	a3,0x1e
    800036be:	08668693          	addi	a3,a3,134 # 80021740 <log>
    800036c2:	a039                	j	800036d0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c4:	02090b63          	beqz	s2,800036fa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036c8:	08848493          	addi	s1,s1,136
    800036cc:	02d48a63          	beq	s1,a3,80003700 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036d0:	449c                	lw	a5,8(s1)
    800036d2:	fef059e3          	blez	a5,800036c4 <iget+0x38>
    800036d6:	4098                	lw	a4,0(s1)
    800036d8:	ff3716e3          	bne	a4,s3,800036c4 <iget+0x38>
    800036dc:	40d8                	lw	a4,4(s1)
    800036de:	ff4713e3          	bne	a4,s4,800036c4 <iget+0x38>
      ip->ref++;
    800036e2:	2785                	addiw	a5,a5,1
    800036e4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036e6:	0001c517          	auipc	a0,0x1c
    800036ea:	5b250513          	addi	a0,a0,1458 # 8001fc98 <itable>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>
      return ip;
    800036f6:	8926                	mv	s2,s1
    800036f8:	a03d                	j	80003726 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036fa:	f7f9                	bnez	a5,800036c8 <iget+0x3c>
    800036fc:	8926                	mv	s2,s1
    800036fe:	b7e9                	j	800036c8 <iget+0x3c>
  if(empty == 0)
    80003700:	02090c63          	beqz	s2,80003738 <iget+0xac>
  ip->dev = dev;
    80003704:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003708:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000370c:	4785                	li	a5,1
    8000370e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003712:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003716:	0001c517          	auipc	a0,0x1c
    8000371a:	58250513          	addi	a0,a0,1410 # 8001fc98 <itable>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	56c080e7          	jalr	1388(ra) # 80000c8a <release>
}
    80003726:	854a                	mv	a0,s2
    80003728:	70a2                	ld	ra,40(sp)
    8000372a:	7402                	ld	s0,32(sp)
    8000372c:	64e2                	ld	s1,24(sp)
    8000372e:	6942                	ld	s2,16(sp)
    80003730:	69a2                	ld	s3,8(sp)
    80003732:	6a02                	ld	s4,0(sp)
    80003734:	6145                	addi	sp,sp,48
    80003736:	8082                	ret
    panic("iget: no inodes");
    80003738:	00005517          	auipc	a0,0x5
    8000373c:	e6850513          	addi	a0,a0,-408 # 800085a0 <syscalls+0x150>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	e00080e7          	jalr	-512(ra) # 80000540 <panic>

0000000080003748 <fsinit>:
fsinit(int dev) {
    80003748:	7179                	addi	sp,sp,-48
    8000374a:	f406                	sd	ra,40(sp)
    8000374c:	f022                	sd	s0,32(sp)
    8000374e:	ec26                	sd	s1,24(sp)
    80003750:	e84a                	sd	s2,16(sp)
    80003752:	e44e                	sd	s3,8(sp)
    80003754:	1800                	addi	s0,sp,48
    80003756:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003758:	4585                	li	a1,1
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	a54080e7          	jalr	-1452(ra) # 800031ae <bread>
    80003762:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003764:	0001c997          	auipc	s3,0x1c
    80003768:	51498993          	addi	s3,s3,1300 # 8001fc78 <sb>
    8000376c:	02000613          	li	a2,32
    80003770:	05850593          	addi	a1,a0,88
    80003774:	854e                	mv	a0,s3
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	5b8080e7          	jalr	1464(ra) # 80000d2e <memmove>
  brelse(bp);
    8000377e:	8526                	mv	a0,s1
    80003780:	00000097          	auipc	ra,0x0
    80003784:	b5e080e7          	jalr	-1186(ra) # 800032de <brelse>
  if(sb.magic != FSMAGIC)
    80003788:	0009a703          	lw	a4,0(s3)
    8000378c:	102037b7          	lui	a5,0x10203
    80003790:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003794:	02f71263          	bne	a4,a5,800037b8 <fsinit+0x70>
  initlog(dev, &sb);
    80003798:	0001c597          	auipc	a1,0x1c
    8000379c:	4e058593          	addi	a1,a1,1248 # 8001fc78 <sb>
    800037a0:	854a                	mv	a0,s2
    800037a2:	00001097          	auipc	ra,0x1
    800037a6:	b4a080e7          	jalr	-1206(ra) # 800042ec <initlog>
}
    800037aa:	70a2                	ld	ra,40(sp)
    800037ac:	7402                	ld	s0,32(sp)
    800037ae:	64e2                	ld	s1,24(sp)
    800037b0:	6942                	ld	s2,16(sp)
    800037b2:	69a2                	ld	s3,8(sp)
    800037b4:	6145                	addi	sp,sp,48
    800037b6:	8082                	ret
    panic("invalid file system");
    800037b8:	00005517          	auipc	a0,0x5
    800037bc:	df850513          	addi	a0,a0,-520 # 800085b0 <syscalls+0x160>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	d80080e7          	jalr	-640(ra) # 80000540 <panic>

00000000800037c8 <iinit>:
{
    800037c8:	7179                	addi	sp,sp,-48
    800037ca:	f406                	sd	ra,40(sp)
    800037cc:	f022                	sd	s0,32(sp)
    800037ce:	ec26                	sd	s1,24(sp)
    800037d0:	e84a                	sd	s2,16(sp)
    800037d2:	e44e                	sd	s3,8(sp)
    800037d4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037d6:	00005597          	auipc	a1,0x5
    800037da:	df258593          	addi	a1,a1,-526 # 800085c8 <syscalls+0x178>
    800037de:	0001c517          	auipc	a0,0x1c
    800037e2:	4ba50513          	addi	a0,a0,1210 # 8001fc98 <itable>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	360080e7          	jalr	864(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ee:	0001c497          	auipc	s1,0x1c
    800037f2:	4d248493          	addi	s1,s1,1234 # 8001fcc0 <itable+0x28>
    800037f6:	0001e997          	auipc	s3,0x1e
    800037fa:	f5a98993          	addi	s3,s3,-166 # 80021750 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037fe:	00005917          	auipc	s2,0x5
    80003802:	dd290913          	addi	s2,s2,-558 # 800085d0 <syscalls+0x180>
    80003806:	85ca                	mv	a1,s2
    80003808:	8526                	mv	a0,s1
    8000380a:	00001097          	auipc	ra,0x1
    8000380e:	e42080e7          	jalr	-446(ra) # 8000464c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003812:	08848493          	addi	s1,s1,136
    80003816:	ff3498e3          	bne	s1,s3,80003806 <iinit+0x3e>
}
    8000381a:	70a2                	ld	ra,40(sp)
    8000381c:	7402                	ld	s0,32(sp)
    8000381e:	64e2                	ld	s1,24(sp)
    80003820:	6942                	ld	s2,16(sp)
    80003822:	69a2                	ld	s3,8(sp)
    80003824:	6145                	addi	sp,sp,48
    80003826:	8082                	ret

0000000080003828 <ialloc>:
{
    80003828:	715d                	addi	sp,sp,-80
    8000382a:	e486                	sd	ra,72(sp)
    8000382c:	e0a2                	sd	s0,64(sp)
    8000382e:	fc26                	sd	s1,56(sp)
    80003830:	f84a                	sd	s2,48(sp)
    80003832:	f44e                	sd	s3,40(sp)
    80003834:	f052                	sd	s4,32(sp)
    80003836:	ec56                	sd	s5,24(sp)
    80003838:	e85a                	sd	s6,16(sp)
    8000383a:	e45e                	sd	s7,8(sp)
    8000383c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000383e:	0001c717          	auipc	a4,0x1c
    80003842:	44672703          	lw	a4,1094(a4) # 8001fc84 <sb+0xc>
    80003846:	4785                	li	a5,1
    80003848:	04e7fa63          	bgeu	a5,a4,8000389c <ialloc+0x74>
    8000384c:	8aaa                	mv	s5,a0
    8000384e:	8bae                	mv	s7,a1
    80003850:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003852:	0001ca17          	auipc	s4,0x1c
    80003856:	426a0a13          	addi	s4,s4,1062 # 8001fc78 <sb>
    8000385a:	00048b1b          	sext.w	s6,s1
    8000385e:	0044d593          	srli	a1,s1,0x4
    80003862:	018a2783          	lw	a5,24(s4)
    80003866:	9dbd                	addw	a1,a1,a5
    80003868:	8556                	mv	a0,s5
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	944080e7          	jalr	-1724(ra) # 800031ae <bread>
    80003872:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003874:	05850993          	addi	s3,a0,88
    80003878:	00f4f793          	andi	a5,s1,15
    8000387c:	079a                	slli	a5,a5,0x6
    8000387e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003880:	00099783          	lh	a5,0(s3)
    80003884:	c3a1                	beqz	a5,800038c4 <ialloc+0x9c>
    brelse(bp);
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	a58080e7          	jalr	-1448(ra) # 800032de <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000388e:	0485                	addi	s1,s1,1
    80003890:	00ca2703          	lw	a4,12(s4)
    80003894:	0004879b          	sext.w	a5,s1
    80003898:	fce7e1e3          	bltu	a5,a4,8000385a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000389c:	00005517          	auipc	a0,0x5
    800038a0:	d3c50513          	addi	a0,a0,-708 # 800085d8 <syscalls+0x188>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	ce6080e7          	jalr	-794(ra) # 8000058a <printf>
  return 0;
    800038ac:	4501                	li	a0,0
}
    800038ae:	60a6                	ld	ra,72(sp)
    800038b0:	6406                	ld	s0,64(sp)
    800038b2:	74e2                	ld	s1,56(sp)
    800038b4:	7942                	ld	s2,48(sp)
    800038b6:	79a2                	ld	s3,40(sp)
    800038b8:	7a02                	ld	s4,32(sp)
    800038ba:	6ae2                	ld	s5,24(sp)
    800038bc:	6b42                	ld	s6,16(sp)
    800038be:	6ba2                	ld	s7,8(sp)
    800038c0:	6161                	addi	sp,sp,80
    800038c2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038c4:	04000613          	li	a2,64
    800038c8:	4581                	li	a1,0
    800038ca:	854e                	mv	a0,s3
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	406080e7          	jalr	1030(ra) # 80000cd2 <memset>
      dip->type = type;
    800038d4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038d8:	854a                	mv	a0,s2
    800038da:	00001097          	auipc	ra,0x1
    800038de:	c8e080e7          	jalr	-882(ra) # 80004568 <log_write>
      brelse(bp);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	9fa080e7          	jalr	-1542(ra) # 800032de <brelse>
      return iget(dev, inum);
    800038ec:	85da                	mv	a1,s6
    800038ee:	8556                	mv	a0,s5
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	d9c080e7          	jalr	-612(ra) # 8000368c <iget>
    800038f8:	bf5d                	j	800038ae <ialloc+0x86>

00000000800038fa <iupdate>:
{
    800038fa:	1101                	addi	sp,sp,-32
    800038fc:	ec06                	sd	ra,24(sp)
    800038fe:	e822                	sd	s0,16(sp)
    80003900:	e426                	sd	s1,8(sp)
    80003902:	e04a                	sd	s2,0(sp)
    80003904:	1000                	addi	s0,sp,32
    80003906:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003908:	415c                	lw	a5,4(a0)
    8000390a:	0047d79b          	srliw	a5,a5,0x4
    8000390e:	0001c597          	auipc	a1,0x1c
    80003912:	3825a583          	lw	a1,898(a1) # 8001fc90 <sb+0x18>
    80003916:	9dbd                	addw	a1,a1,a5
    80003918:	4108                	lw	a0,0(a0)
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	894080e7          	jalr	-1900(ra) # 800031ae <bread>
    80003922:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003924:	05850793          	addi	a5,a0,88
    80003928:	40d8                	lw	a4,4(s1)
    8000392a:	8b3d                	andi	a4,a4,15
    8000392c:	071a                	slli	a4,a4,0x6
    8000392e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003930:	04449703          	lh	a4,68(s1)
    80003934:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003938:	04649703          	lh	a4,70(s1)
    8000393c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003940:	04849703          	lh	a4,72(s1)
    80003944:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003948:	04a49703          	lh	a4,74(s1)
    8000394c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003950:	44f8                	lw	a4,76(s1)
    80003952:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003954:	03400613          	li	a2,52
    80003958:	05048593          	addi	a1,s1,80
    8000395c:	00c78513          	addi	a0,a5,12
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	3ce080e7          	jalr	974(ra) # 80000d2e <memmove>
  log_write(bp);
    80003968:	854a                	mv	a0,s2
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	bfe080e7          	jalr	-1026(ra) # 80004568 <log_write>
  brelse(bp);
    80003972:	854a                	mv	a0,s2
    80003974:	00000097          	auipc	ra,0x0
    80003978:	96a080e7          	jalr	-1686(ra) # 800032de <brelse>
}
    8000397c:	60e2                	ld	ra,24(sp)
    8000397e:	6442                	ld	s0,16(sp)
    80003980:	64a2                	ld	s1,8(sp)
    80003982:	6902                	ld	s2,0(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret

0000000080003988 <idup>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	1000                	addi	s0,sp,32
    80003992:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003994:	0001c517          	auipc	a0,0x1c
    80003998:	30450513          	addi	a0,a0,772 # 8001fc98 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	23a080e7          	jalr	570(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039a4:	449c                	lw	a5,8(s1)
    800039a6:	2785                	addiw	a5,a5,1
    800039a8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039aa:	0001c517          	auipc	a0,0x1c
    800039ae:	2ee50513          	addi	a0,a0,750 # 8001fc98 <itable>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	2d8080e7          	jalr	728(ra) # 80000c8a <release>
}
    800039ba:	8526                	mv	a0,s1
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6105                	addi	sp,sp,32
    800039c4:	8082                	ret

00000000800039c6 <ilock>:
{
    800039c6:	1101                	addi	sp,sp,-32
    800039c8:	ec06                	sd	ra,24(sp)
    800039ca:	e822                	sd	s0,16(sp)
    800039cc:	e426                	sd	s1,8(sp)
    800039ce:	e04a                	sd	s2,0(sp)
    800039d0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039d2:	c115                	beqz	a0,800039f6 <ilock+0x30>
    800039d4:	84aa                	mv	s1,a0
    800039d6:	451c                	lw	a5,8(a0)
    800039d8:	00f05f63          	blez	a5,800039f6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039dc:	0541                	addi	a0,a0,16
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	ca8080e7          	jalr	-856(ra) # 80004686 <acquiresleep>
  if(ip->valid == 0){
    800039e6:	40bc                	lw	a5,64(s1)
    800039e8:	cf99                	beqz	a5,80003a06 <ilock+0x40>
}
    800039ea:	60e2                	ld	ra,24(sp)
    800039ec:	6442                	ld	s0,16(sp)
    800039ee:	64a2                	ld	s1,8(sp)
    800039f0:	6902                	ld	s2,0(sp)
    800039f2:	6105                	addi	sp,sp,32
    800039f4:	8082                	ret
    panic("ilock");
    800039f6:	00005517          	auipc	a0,0x5
    800039fa:	bfa50513          	addi	a0,a0,-1030 # 800085f0 <syscalls+0x1a0>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	b42080e7          	jalr	-1214(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a06:	40dc                	lw	a5,4(s1)
    80003a08:	0047d79b          	srliw	a5,a5,0x4
    80003a0c:	0001c597          	auipc	a1,0x1c
    80003a10:	2845a583          	lw	a1,644(a1) # 8001fc90 <sb+0x18>
    80003a14:	9dbd                	addw	a1,a1,a5
    80003a16:	4088                	lw	a0,0(s1)
    80003a18:	fffff097          	auipc	ra,0xfffff
    80003a1c:	796080e7          	jalr	1942(ra) # 800031ae <bread>
    80003a20:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a22:	05850593          	addi	a1,a0,88
    80003a26:	40dc                	lw	a5,4(s1)
    80003a28:	8bbd                	andi	a5,a5,15
    80003a2a:	079a                	slli	a5,a5,0x6
    80003a2c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a2e:	00059783          	lh	a5,0(a1)
    80003a32:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a36:	00259783          	lh	a5,2(a1)
    80003a3a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a3e:	00459783          	lh	a5,4(a1)
    80003a42:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a46:	00659783          	lh	a5,6(a1)
    80003a4a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a4e:	459c                	lw	a5,8(a1)
    80003a50:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a52:	03400613          	li	a2,52
    80003a56:	05b1                	addi	a1,a1,12
    80003a58:	05048513          	addi	a0,s1,80
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	2d2080e7          	jalr	722(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a64:	854a                	mv	a0,s2
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	878080e7          	jalr	-1928(ra) # 800032de <brelse>
    ip->valid = 1;
    80003a6e:	4785                	li	a5,1
    80003a70:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a72:	04449783          	lh	a5,68(s1)
    80003a76:	fbb5                	bnez	a5,800039ea <ilock+0x24>
      panic("ilock: no type");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	b8050513          	addi	a0,a0,-1152 # 800085f8 <syscalls+0x1a8>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	ac0080e7          	jalr	-1344(ra) # 80000540 <panic>

0000000080003a88 <iunlock>:
{
    80003a88:	1101                	addi	sp,sp,-32
    80003a8a:	ec06                	sd	ra,24(sp)
    80003a8c:	e822                	sd	s0,16(sp)
    80003a8e:	e426                	sd	s1,8(sp)
    80003a90:	e04a                	sd	s2,0(sp)
    80003a92:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a94:	c905                	beqz	a0,80003ac4 <iunlock+0x3c>
    80003a96:	84aa                	mv	s1,a0
    80003a98:	01050913          	addi	s2,a0,16
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00001097          	auipc	ra,0x1
    80003aa2:	c82080e7          	jalr	-894(ra) # 80004720 <holdingsleep>
    80003aa6:	cd19                	beqz	a0,80003ac4 <iunlock+0x3c>
    80003aa8:	449c                	lw	a5,8(s1)
    80003aaa:	00f05d63          	blez	a5,80003ac4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aae:	854a                	mv	a0,s2
    80003ab0:	00001097          	auipc	ra,0x1
    80003ab4:	c2c080e7          	jalr	-980(ra) # 800046dc <releasesleep>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	64a2                	ld	s1,8(sp)
    80003abe:	6902                	ld	s2,0(sp)
    80003ac0:	6105                	addi	sp,sp,32
    80003ac2:	8082                	ret
    panic("iunlock");
    80003ac4:	00005517          	auipc	a0,0x5
    80003ac8:	b4450513          	addi	a0,a0,-1212 # 80008608 <syscalls+0x1b8>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	a74080e7          	jalr	-1420(ra) # 80000540 <panic>

0000000080003ad4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ad4:	7179                	addi	sp,sp,-48
    80003ad6:	f406                	sd	ra,40(sp)
    80003ad8:	f022                	sd	s0,32(sp)
    80003ada:	ec26                	sd	s1,24(sp)
    80003adc:	e84a                	sd	s2,16(sp)
    80003ade:	e44e                	sd	s3,8(sp)
    80003ae0:	e052                	sd	s4,0(sp)
    80003ae2:	1800                	addi	s0,sp,48
    80003ae4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ae6:	05050493          	addi	s1,a0,80
    80003aea:	08050913          	addi	s2,a0,128
    80003aee:	a021                	j	80003af6 <itrunc+0x22>
    80003af0:	0491                	addi	s1,s1,4
    80003af2:	01248d63          	beq	s1,s2,80003b0c <itrunc+0x38>
    if(ip->addrs[i]){
    80003af6:	408c                	lw	a1,0(s1)
    80003af8:	dde5                	beqz	a1,80003af0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003afa:	0009a503          	lw	a0,0(s3)
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	8f6080e7          	jalr	-1802(ra) # 800033f4 <bfree>
      ip->addrs[i] = 0;
    80003b06:	0004a023          	sw	zero,0(s1)
    80003b0a:	b7dd                	j	80003af0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b0c:	0809a583          	lw	a1,128(s3)
    80003b10:	e185                	bnez	a1,80003b30 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b12:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b16:	854e                	mv	a0,s3
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	de2080e7          	jalr	-542(ra) # 800038fa <iupdate>
}
    80003b20:	70a2                	ld	ra,40(sp)
    80003b22:	7402                	ld	s0,32(sp)
    80003b24:	64e2                	ld	s1,24(sp)
    80003b26:	6942                	ld	s2,16(sp)
    80003b28:	69a2                	ld	s3,8(sp)
    80003b2a:	6a02                	ld	s4,0(sp)
    80003b2c:	6145                	addi	sp,sp,48
    80003b2e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b30:	0009a503          	lw	a0,0(s3)
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	67a080e7          	jalr	1658(ra) # 800031ae <bread>
    80003b3c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b3e:	05850493          	addi	s1,a0,88
    80003b42:	45850913          	addi	s2,a0,1112
    80003b46:	a021                	j	80003b4e <itrunc+0x7a>
    80003b48:	0491                	addi	s1,s1,4
    80003b4a:	01248b63          	beq	s1,s2,80003b60 <itrunc+0x8c>
      if(a[j])
    80003b4e:	408c                	lw	a1,0(s1)
    80003b50:	dde5                	beqz	a1,80003b48 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b52:	0009a503          	lw	a0,0(s3)
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	89e080e7          	jalr	-1890(ra) # 800033f4 <bfree>
    80003b5e:	b7ed                	j	80003b48 <itrunc+0x74>
    brelse(bp);
    80003b60:	8552                	mv	a0,s4
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	77c080e7          	jalr	1916(ra) # 800032de <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b6a:	0809a583          	lw	a1,128(s3)
    80003b6e:	0009a503          	lw	a0,0(s3)
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	882080e7          	jalr	-1918(ra) # 800033f4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b7a:	0809a023          	sw	zero,128(s3)
    80003b7e:	bf51                	j	80003b12 <itrunc+0x3e>

0000000080003b80 <iput>:
{
    80003b80:	1101                	addi	sp,sp,-32
    80003b82:	ec06                	sd	ra,24(sp)
    80003b84:	e822                	sd	s0,16(sp)
    80003b86:	e426                	sd	s1,8(sp)
    80003b88:	e04a                	sd	s2,0(sp)
    80003b8a:	1000                	addi	s0,sp,32
    80003b8c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b8e:	0001c517          	auipc	a0,0x1c
    80003b92:	10a50513          	addi	a0,a0,266 # 8001fc98 <itable>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	040080e7          	jalr	64(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b9e:	4498                	lw	a4,8(s1)
    80003ba0:	4785                	li	a5,1
    80003ba2:	02f70363          	beq	a4,a5,80003bc8 <iput+0x48>
  ip->ref--;
    80003ba6:	449c                	lw	a5,8(s1)
    80003ba8:	37fd                	addiw	a5,a5,-1
    80003baa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bac:	0001c517          	auipc	a0,0x1c
    80003bb0:	0ec50513          	addi	a0,a0,236 # 8001fc98 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	0d6080e7          	jalr	214(ra) # 80000c8a <release>
}
    80003bbc:	60e2                	ld	ra,24(sp)
    80003bbe:	6442                	ld	s0,16(sp)
    80003bc0:	64a2                	ld	s1,8(sp)
    80003bc2:	6902                	ld	s2,0(sp)
    80003bc4:	6105                	addi	sp,sp,32
    80003bc6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bc8:	40bc                	lw	a5,64(s1)
    80003bca:	dff1                	beqz	a5,80003ba6 <iput+0x26>
    80003bcc:	04a49783          	lh	a5,74(s1)
    80003bd0:	fbf9                	bnez	a5,80003ba6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bd2:	01048913          	addi	s2,s1,16
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	aae080e7          	jalr	-1362(ra) # 80004686 <acquiresleep>
    release(&itable.lock);
    80003be0:	0001c517          	auipc	a0,0x1c
    80003be4:	0b850513          	addi	a0,a0,184 # 8001fc98 <itable>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	0a2080e7          	jalr	162(ra) # 80000c8a <release>
    itrunc(ip);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	ee2080e7          	jalr	-286(ra) # 80003ad4 <itrunc>
    ip->type = 0;
    80003bfa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	cfa080e7          	jalr	-774(ra) # 800038fa <iupdate>
    ip->valid = 0;
    80003c08:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	00001097          	auipc	ra,0x1
    80003c12:	ace080e7          	jalr	-1330(ra) # 800046dc <releasesleep>
    acquire(&itable.lock);
    80003c16:	0001c517          	auipc	a0,0x1c
    80003c1a:	08250513          	addi	a0,a0,130 # 8001fc98 <itable>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	fb8080e7          	jalr	-72(ra) # 80000bd6 <acquire>
    80003c26:	b741                	j	80003ba6 <iput+0x26>

0000000080003c28 <iunlockput>:
{
    80003c28:	1101                	addi	sp,sp,-32
    80003c2a:	ec06                	sd	ra,24(sp)
    80003c2c:	e822                	sd	s0,16(sp)
    80003c2e:	e426                	sd	s1,8(sp)
    80003c30:	1000                	addi	s0,sp,32
    80003c32:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	e54080e7          	jalr	-428(ra) # 80003a88 <iunlock>
  iput(ip);
    80003c3c:	8526                	mv	a0,s1
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	f42080e7          	jalr	-190(ra) # 80003b80 <iput>
}
    80003c46:	60e2                	ld	ra,24(sp)
    80003c48:	6442                	ld	s0,16(sp)
    80003c4a:	64a2                	ld	s1,8(sp)
    80003c4c:	6105                	addi	sp,sp,32
    80003c4e:	8082                	ret

0000000080003c50 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c50:	1141                	addi	sp,sp,-16
    80003c52:	e422                	sd	s0,8(sp)
    80003c54:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c56:	411c                	lw	a5,0(a0)
    80003c58:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c5a:	415c                	lw	a5,4(a0)
    80003c5c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c5e:	04451783          	lh	a5,68(a0)
    80003c62:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c66:	04a51783          	lh	a5,74(a0)
    80003c6a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c6e:	04c56783          	lwu	a5,76(a0)
    80003c72:	e99c                	sd	a5,16(a1)
}
    80003c74:	6422                	ld	s0,8(sp)
    80003c76:	0141                	addi	sp,sp,16
    80003c78:	8082                	ret

0000000080003c7a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c7a:	457c                	lw	a5,76(a0)
    80003c7c:	0ed7e963          	bltu	a5,a3,80003d6e <readi+0xf4>
{
    80003c80:	7159                	addi	sp,sp,-112
    80003c82:	f486                	sd	ra,104(sp)
    80003c84:	f0a2                	sd	s0,96(sp)
    80003c86:	eca6                	sd	s1,88(sp)
    80003c88:	e8ca                	sd	s2,80(sp)
    80003c8a:	e4ce                	sd	s3,72(sp)
    80003c8c:	e0d2                	sd	s4,64(sp)
    80003c8e:	fc56                	sd	s5,56(sp)
    80003c90:	f85a                	sd	s6,48(sp)
    80003c92:	f45e                	sd	s7,40(sp)
    80003c94:	f062                	sd	s8,32(sp)
    80003c96:	ec66                	sd	s9,24(sp)
    80003c98:	e86a                	sd	s10,16(sp)
    80003c9a:	e46e                	sd	s11,8(sp)
    80003c9c:	1880                	addi	s0,sp,112
    80003c9e:	8b2a                	mv	s6,a0
    80003ca0:	8bae                	mv	s7,a1
    80003ca2:	8a32                	mv	s4,a2
    80003ca4:	84b6                	mv	s1,a3
    80003ca6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ca8:	9f35                	addw	a4,a4,a3
    return 0;
    80003caa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cac:	0ad76063          	bltu	a4,a3,80003d4c <readi+0xd2>
  if(off + n > ip->size)
    80003cb0:	00e7f463          	bgeu	a5,a4,80003cb8 <readi+0x3e>
    n = ip->size - off;
    80003cb4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb8:	0a0a8963          	beqz	s5,80003d6a <readi+0xf0>
    80003cbc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cbe:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cc2:	5c7d                	li	s8,-1
    80003cc4:	a82d                	j	80003cfe <readi+0x84>
    80003cc6:	020d1d93          	slli	s11,s10,0x20
    80003cca:	020ddd93          	srli	s11,s11,0x20
    80003cce:	05890613          	addi	a2,s2,88
    80003cd2:	86ee                	mv	a3,s11
    80003cd4:	963a                	add	a2,a2,a4
    80003cd6:	85d2                	mv	a1,s4
    80003cd8:	855e                	mv	a0,s7
    80003cda:	ffffe097          	auipc	ra,0xffffe
    80003cde:	7a2080e7          	jalr	1954(ra) # 8000247c <either_copyout>
    80003ce2:	05850d63          	beq	a0,s8,80003d3c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	5f6080e7          	jalr	1526(ra) # 800032de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf0:	013d09bb          	addw	s3,s10,s3
    80003cf4:	009d04bb          	addw	s1,s10,s1
    80003cf8:	9a6e                	add	s4,s4,s11
    80003cfa:	0559f763          	bgeu	s3,s5,80003d48 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003cfe:	00a4d59b          	srliw	a1,s1,0xa
    80003d02:	855a                	mv	a0,s6
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	89e080e7          	jalr	-1890(ra) # 800035a2 <bmap>
    80003d0c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d10:	cd85                	beqz	a1,80003d48 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d12:	000b2503          	lw	a0,0(s6)
    80003d16:	fffff097          	auipc	ra,0xfffff
    80003d1a:	498080e7          	jalr	1176(ra) # 800031ae <bread>
    80003d1e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d20:	3ff4f713          	andi	a4,s1,1023
    80003d24:	40ec87bb          	subw	a5,s9,a4
    80003d28:	413a86bb          	subw	a3,s5,s3
    80003d2c:	8d3e                	mv	s10,a5
    80003d2e:	2781                	sext.w	a5,a5
    80003d30:	0006861b          	sext.w	a2,a3
    80003d34:	f8f679e3          	bgeu	a2,a5,80003cc6 <readi+0x4c>
    80003d38:	8d36                	mv	s10,a3
    80003d3a:	b771                	j	80003cc6 <readi+0x4c>
      brelse(bp);
    80003d3c:	854a                	mv	a0,s2
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	5a0080e7          	jalr	1440(ra) # 800032de <brelse>
      tot = -1;
    80003d46:	59fd                	li	s3,-1
  }
  return tot;
    80003d48:	0009851b          	sext.w	a0,s3
}
    80003d4c:	70a6                	ld	ra,104(sp)
    80003d4e:	7406                	ld	s0,96(sp)
    80003d50:	64e6                	ld	s1,88(sp)
    80003d52:	6946                	ld	s2,80(sp)
    80003d54:	69a6                	ld	s3,72(sp)
    80003d56:	6a06                	ld	s4,64(sp)
    80003d58:	7ae2                	ld	s5,56(sp)
    80003d5a:	7b42                	ld	s6,48(sp)
    80003d5c:	7ba2                	ld	s7,40(sp)
    80003d5e:	7c02                	ld	s8,32(sp)
    80003d60:	6ce2                	ld	s9,24(sp)
    80003d62:	6d42                	ld	s10,16(sp)
    80003d64:	6da2                	ld	s11,8(sp)
    80003d66:	6165                	addi	sp,sp,112
    80003d68:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d6a:	89d6                	mv	s3,s5
    80003d6c:	bff1                	j	80003d48 <readi+0xce>
    return 0;
    80003d6e:	4501                	li	a0,0
}
    80003d70:	8082                	ret

0000000080003d72 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d72:	457c                	lw	a5,76(a0)
    80003d74:	10d7e863          	bltu	a5,a3,80003e84 <writei+0x112>
{
    80003d78:	7159                	addi	sp,sp,-112
    80003d7a:	f486                	sd	ra,104(sp)
    80003d7c:	f0a2                	sd	s0,96(sp)
    80003d7e:	eca6                	sd	s1,88(sp)
    80003d80:	e8ca                	sd	s2,80(sp)
    80003d82:	e4ce                	sd	s3,72(sp)
    80003d84:	e0d2                	sd	s4,64(sp)
    80003d86:	fc56                	sd	s5,56(sp)
    80003d88:	f85a                	sd	s6,48(sp)
    80003d8a:	f45e                	sd	s7,40(sp)
    80003d8c:	f062                	sd	s8,32(sp)
    80003d8e:	ec66                	sd	s9,24(sp)
    80003d90:	e86a                	sd	s10,16(sp)
    80003d92:	e46e                	sd	s11,8(sp)
    80003d94:	1880                	addi	s0,sp,112
    80003d96:	8aaa                	mv	s5,a0
    80003d98:	8bae                	mv	s7,a1
    80003d9a:	8a32                	mv	s4,a2
    80003d9c:	8936                	mv	s2,a3
    80003d9e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003da0:	00e687bb          	addw	a5,a3,a4
    80003da4:	0ed7e263          	bltu	a5,a3,80003e88 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003da8:	00043737          	lui	a4,0x43
    80003dac:	0ef76063          	bltu	a4,a5,80003e8c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db0:	0c0b0863          	beqz	s6,80003e80 <writei+0x10e>
    80003db4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dba:	5c7d                	li	s8,-1
    80003dbc:	a091                	j	80003e00 <writei+0x8e>
    80003dbe:	020d1d93          	slli	s11,s10,0x20
    80003dc2:	020ddd93          	srli	s11,s11,0x20
    80003dc6:	05848513          	addi	a0,s1,88
    80003dca:	86ee                	mv	a3,s11
    80003dcc:	8652                	mv	a2,s4
    80003dce:	85de                	mv	a1,s7
    80003dd0:	953a                	add	a0,a0,a4
    80003dd2:	ffffe097          	auipc	ra,0xffffe
    80003dd6:	700080e7          	jalr	1792(ra) # 800024d2 <either_copyin>
    80003dda:	07850263          	beq	a0,s8,80003e3e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dde:	8526                	mv	a0,s1
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	788080e7          	jalr	1928(ra) # 80004568 <log_write>
    brelse(bp);
    80003de8:	8526                	mv	a0,s1
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	4f4080e7          	jalr	1268(ra) # 800032de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df2:	013d09bb          	addw	s3,s10,s3
    80003df6:	012d093b          	addw	s2,s10,s2
    80003dfa:	9a6e                	add	s4,s4,s11
    80003dfc:	0569f663          	bgeu	s3,s6,80003e48 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e00:	00a9559b          	srliw	a1,s2,0xa
    80003e04:	8556                	mv	a0,s5
    80003e06:	fffff097          	auipc	ra,0xfffff
    80003e0a:	79c080e7          	jalr	1948(ra) # 800035a2 <bmap>
    80003e0e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e12:	c99d                	beqz	a1,80003e48 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e14:	000aa503          	lw	a0,0(s5)
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	396080e7          	jalr	918(ra) # 800031ae <bread>
    80003e20:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e22:	3ff97713          	andi	a4,s2,1023
    80003e26:	40ec87bb          	subw	a5,s9,a4
    80003e2a:	413b06bb          	subw	a3,s6,s3
    80003e2e:	8d3e                	mv	s10,a5
    80003e30:	2781                	sext.w	a5,a5
    80003e32:	0006861b          	sext.w	a2,a3
    80003e36:	f8f674e3          	bgeu	a2,a5,80003dbe <writei+0x4c>
    80003e3a:	8d36                	mv	s10,a3
    80003e3c:	b749                	j	80003dbe <writei+0x4c>
      brelse(bp);
    80003e3e:	8526                	mv	a0,s1
    80003e40:	fffff097          	auipc	ra,0xfffff
    80003e44:	49e080e7          	jalr	1182(ra) # 800032de <brelse>
  }

  if(off > ip->size)
    80003e48:	04caa783          	lw	a5,76(s5)
    80003e4c:	0127f463          	bgeu	a5,s2,80003e54 <writei+0xe2>
    ip->size = off;
    80003e50:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e54:	8556                	mv	a0,s5
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	aa4080e7          	jalr	-1372(ra) # 800038fa <iupdate>

  return tot;
    80003e5e:	0009851b          	sext.w	a0,s3
}
    80003e62:	70a6                	ld	ra,104(sp)
    80003e64:	7406                	ld	s0,96(sp)
    80003e66:	64e6                	ld	s1,88(sp)
    80003e68:	6946                	ld	s2,80(sp)
    80003e6a:	69a6                	ld	s3,72(sp)
    80003e6c:	6a06                	ld	s4,64(sp)
    80003e6e:	7ae2                	ld	s5,56(sp)
    80003e70:	7b42                	ld	s6,48(sp)
    80003e72:	7ba2                	ld	s7,40(sp)
    80003e74:	7c02                	ld	s8,32(sp)
    80003e76:	6ce2                	ld	s9,24(sp)
    80003e78:	6d42                	ld	s10,16(sp)
    80003e7a:	6da2                	ld	s11,8(sp)
    80003e7c:	6165                	addi	sp,sp,112
    80003e7e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e80:	89da                	mv	s3,s6
    80003e82:	bfc9                	j	80003e54 <writei+0xe2>
    return -1;
    80003e84:	557d                	li	a0,-1
}
    80003e86:	8082                	ret
    return -1;
    80003e88:	557d                	li	a0,-1
    80003e8a:	bfe1                	j	80003e62 <writei+0xf0>
    return -1;
    80003e8c:	557d                	li	a0,-1
    80003e8e:	bfd1                	j	80003e62 <writei+0xf0>

0000000080003e90 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e90:	1141                	addi	sp,sp,-16
    80003e92:	e406                	sd	ra,8(sp)
    80003e94:	e022                	sd	s0,0(sp)
    80003e96:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e98:	4639                	li	a2,14
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	f08080e7          	jalr	-248(ra) # 80000da2 <strncmp>
}
    80003ea2:	60a2                	ld	ra,8(sp)
    80003ea4:	6402                	ld	s0,0(sp)
    80003ea6:	0141                	addi	sp,sp,16
    80003ea8:	8082                	ret

0000000080003eaa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eaa:	7139                	addi	sp,sp,-64
    80003eac:	fc06                	sd	ra,56(sp)
    80003eae:	f822                	sd	s0,48(sp)
    80003eb0:	f426                	sd	s1,40(sp)
    80003eb2:	f04a                	sd	s2,32(sp)
    80003eb4:	ec4e                	sd	s3,24(sp)
    80003eb6:	e852                	sd	s4,16(sp)
    80003eb8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eba:	04451703          	lh	a4,68(a0)
    80003ebe:	4785                	li	a5,1
    80003ec0:	00f71a63          	bne	a4,a5,80003ed4 <dirlookup+0x2a>
    80003ec4:	892a                	mv	s2,a0
    80003ec6:	89ae                	mv	s3,a1
    80003ec8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eca:	457c                	lw	a5,76(a0)
    80003ecc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ece:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed0:	e79d                	bnez	a5,80003efe <dirlookup+0x54>
    80003ed2:	a8a5                	j	80003f4a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ed4:	00004517          	auipc	a0,0x4
    80003ed8:	73c50513          	addi	a0,a0,1852 # 80008610 <syscalls+0x1c0>
    80003edc:	ffffc097          	auipc	ra,0xffffc
    80003ee0:	664080e7          	jalr	1636(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ee4:	00004517          	auipc	a0,0x4
    80003ee8:	74450513          	addi	a0,a0,1860 # 80008628 <syscalls+0x1d8>
    80003eec:	ffffc097          	auipc	ra,0xffffc
    80003ef0:	654080e7          	jalr	1620(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	24c1                	addiw	s1,s1,16
    80003ef6:	04c92783          	lw	a5,76(s2)
    80003efa:	04f4f763          	bgeu	s1,a5,80003f48 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efe:	4741                	li	a4,16
    80003f00:	86a6                	mv	a3,s1
    80003f02:	fc040613          	addi	a2,s0,-64
    80003f06:	4581                	li	a1,0
    80003f08:	854a                	mv	a0,s2
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	d70080e7          	jalr	-656(ra) # 80003c7a <readi>
    80003f12:	47c1                	li	a5,16
    80003f14:	fcf518e3          	bne	a0,a5,80003ee4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f18:	fc045783          	lhu	a5,-64(s0)
    80003f1c:	dfe1                	beqz	a5,80003ef4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f1e:	fc240593          	addi	a1,s0,-62
    80003f22:	854e                	mv	a0,s3
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	f6c080e7          	jalr	-148(ra) # 80003e90 <namecmp>
    80003f2c:	f561                	bnez	a0,80003ef4 <dirlookup+0x4a>
      if(poff)
    80003f2e:	000a0463          	beqz	s4,80003f36 <dirlookup+0x8c>
        *poff = off;
    80003f32:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f36:	fc045583          	lhu	a1,-64(s0)
    80003f3a:	00092503          	lw	a0,0(s2)
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	74e080e7          	jalr	1870(ra) # 8000368c <iget>
    80003f46:	a011                	j	80003f4a <dirlookup+0xa0>
  return 0;
    80003f48:	4501                	li	a0,0
}
    80003f4a:	70e2                	ld	ra,56(sp)
    80003f4c:	7442                	ld	s0,48(sp)
    80003f4e:	74a2                	ld	s1,40(sp)
    80003f50:	7902                	ld	s2,32(sp)
    80003f52:	69e2                	ld	s3,24(sp)
    80003f54:	6a42                	ld	s4,16(sp)
    80003f56:	6121                	addi	sp,sp,64
    80003f58:	8082                	ret

0000000080003f5a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f5a:	711d                	addi	sp,sp,-96
    80003f5c:	ec86                	sd	ra,88(sp)
    80003f5e:	e8a2                	sd	s0,80(sp)
    80003f60:	e4a6                	sd	s1,72(sp)
    80003f62:	e0ca                	sd	s2,64(sp)
    80003f64:	fc4e                	sd	s3,56(sp)
    80003f66:	f852                	sd	s4,48(sp)
    80003f68:	f456                	sd	s5,40(sp)
    80003f6a:	f05a                	sd	s6,32(sp)
    80003f6c:	ec5e                	sd	s7,24(sp)
    80003f6e:	e862                	sd	s8,16(sp)
    80003f70:	e466                	sd	s9,8(sp)
    80003f72:	e06a                	sd	s10,0(sp)
    80003f74:	1080                	addi	s0,sp,96
    80003f76:	84aa                	mv	s1,a0
    80003f78:	8b2e                	mv	s6,a1
    80003f7a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f7c:	00054703          	lbu	a4,0(a0)
    80003f80:	02f00793          	li	a5,47
    80003f84:	02f70363          	beq	a4,a5,80003faa <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f88:	ffffe097          	auipc	ra,0xffffe
    80003f8c:	a24080e7          	jalr	-1500(ra) # 800019ac <myproc>
    80003f90:	15053503          	ld	a0,336(a0)
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	9f4080e7          	jalr	-1548(ra) # 80003988 <idup>
    80003f9c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f9e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003fa2:	4cb5                	li	s9,13
  len = path - s;
    80003fa4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fa6:	4c05                	li	s8,1
    80003fa8:	a87d                	j	80004066 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003faa:	4585                	li	a1,1
    80003fac:	4505                	li	a0,1
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	6de080e7          	jalr	1758(ra) # 8000368c <iget>
    80003fb6:	8a2a                	mv	s4,a0
    80003fb8:	b7dd                	j	80003f9e <namex+0x44>
      iunlockput(ip);
    80003fba:	8552                	mv	a0,s4
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	c6c080e7          	jalr	-916(ra) # 80003c28 <iunlockput>
      return 0;
    80003fc4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fc6:	8552                	mv	a0,s4
    80003fc8:	60e6                	ld	ra,88(sp)
    80003fca:	6446                	ld	s0,80(sp)
    80003fcc:	64a6                	ld	s1,72(sp)
    80003fce:	6906                	ld	s2,64(sp)
    80003fd0:	79e2                	ld	s3,56(sp)
    80003fd2:	7a42                	ld	s4,48(sp)
    80003fd4:	7aa2                	ld	s5,40(sp)
    80003fd6:	7b02                	ld	s6,32(sp)
    80003fd8:	6be2                	ld	s7,24(sp)
    80003fda:	6c42                	ld	s8,16(sp)
    80003fdc:	6ca2                	ld	s9,8(sp)
    80003fde:	6d02                	ld	s10,0(sp)
    80003fe0:	6125                	addi	sp,sp,96
    80003fe2:	8082                	ret
      iunlock(ip);
    80003fe4:	8552                	mv	a0,s4
    80003fe6:	00000097          	auipc	ra,0x0
    80003fea:	aa2080e7          	jalr	-1374(ra) # 80003a88 <iunlock>
      return ip;
    80003fee:	bfe1                	j	80003fc6 <namex+0x6c>
      iunlockput(ip);
    80003ff0:	8552                	mv	a0,s4
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	c36080e7          	jalr	-970(ra) # 80003c28 <iunlockput>
      return 0;
    80003ffa:	8a4e                	mv	s4,s3
    80003ffc:	b7e9                	j	80003fc6 <namex+0x6c>
  len = path - s;
    80003ffe:	40998633          	sub	a2,s3,s1
    80004002:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004006:	09acd863          	bge	s9,s10,80004096 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000400a:	4639                	li	a2,14
    8000400c:	85a6                	mv	a1,s1
    8000400e:	8556                	mv	a0,s5
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	d1e080e7          	jalr	-738(ra) # 80000d2e <memmove>
    80004018:	84ce                	mv	s1,s3
  while(*path == '/')
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	01279763          	bne	a5,s2,8000402c <namex+0xd2>
    path++;
    80004022:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004024:	0004c783          	lbu	a5,0(s1)
    80004028:	ff278de3          	beq	a5,s2,80004022 <namex+0xc8>
    ilock(ip);
    8000402c:	8552                	mv	a0,s4
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	998080e7          	jalr	-1640(ra) # 800039c6 <ilock>
    if(ip->type != T_DIR){
    80004036:	044a1783          	lh	a5,68(s4)
    8000403a:	f98790e3          	bne	a5,s8,80003fba <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000403e:	000b0563          	beqz	s6,80004048 <namex+0xee>
    80004042:	0004c783          	lbu	a5,0(s1)
    80004046:	dfd9                	beqz	a5,80003fe4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004048:	865e                	mv	a2,s7
    8000404a:	85d6                	mv	a1,s5
    8000404c:	8552                	mv	a0,s4
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	e5c080e7          	jalr	-420(ra) # 80003eaa <dirlookup>
    80004056:	89aa                	mv	s3,a0
    80004058:	dd41                	beqz	a0,80003ff0 <namex+0x96>
    iunlockput(ip);
    8000405a:	8552                	mv	a0,s4
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	bcc080e7          	jalr	-1076(ra) # 80003c28 <iunlockput>
    ip = next;
    80004064:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004066:	0004c783          	lbu	a5,0(s1)
    8000406a:	01279763          	bne	a5,s2,80004078 <namex+0x11e>
    path++;
    8000406e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004070:	0004c783          	lbu	a5,0(s1)
    80004074:	ff278de3          	beq	a5,s2,8000406e <namex+0x114>
  if(*path == 0)
    80004078:	cb9d                	beqz	a5,800040ae <namex+0x154>
  while(*path != '/' && *path != 0)
    8000407a:	0004c783          	lbu	a5,0(s1)
    8000407e:	89a6                	mv	s3,s1
  len = path - s;
    80004080:	8d5e                	mv	s10,s7
    80004082:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004084:	01278963          	beq	a5,s2,80004096 <namex+0x13c>
    80004088:	dbbd                	beqz	a5,80003ffe <namex+0xa4>
    path++;
    8000408a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000408c:	0009c783          	lbu	a5,0(s3)
    80004090:	ff279ce3          	bne	a5,s2,80004088 <namex+0x12e>
    80004094:	b7ad                	j	80003ffe <namex+0xa4>
    memmove(name, s, len);
    80004096:	2601                	sext.w	a2,a2
    80004098:	85a6                	mv	a1,s1
    8000409a:	8556                	mv	a0,s5
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	c92080e7          	jalr	-878(ra) # 80000d2e <memmove>
    name[len] = 0;
    800040a4:	9d56                	add	s10,s10,s5
    800040a6:	000d0023          	sb	zero,0(s10)
    800040aa:	84ce                	mv	s1,s3
    800040ac:	b7bd                	j	8000401a <namex+0xc0>
  if(nameiparent){
    800040ae:	f00b0ce3          	beqz	s6,80003fc6 <namex+0x6c>
    iput(ip);
    800040b2:	8552                	mv	a0,s4
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	acc080e7          	jalr	-1332(ra) # 80003b80 <iput>
    return 0;
    800040bc:	4a01                	li	s4,0
    800040be:	b721                	j	80003fc6 <namex+0x6c>

00000000800040c0 <dirlink>:
{
    800040c0:	7139                	addi	sp,sp,-64
    800040c2:	fc06                	sd	ra,56(sp)
    800040c4:	f822                	sd	s0,48(sp)
    800040c6:	f426                	sd	s1,40(sp)
    800040c8:	f04a                	sd	s2,32(sp)
    800040ca:	ec4e                	sd	s3,24(sp)
    800040cc:	e852                	sd	s4,16(sp)
    800040ce:	0080                	addi	s0,sp,64
    800040d0:	892a                	mv	s2,a0
    800040d2:	8a2e                	mv	s4,a1
    800040d4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040d6:	4601                	li	a2,0
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	dd2080e7          	jalr	-558(ra) # 80003eaa <dirlookup>
    800040e0:	e93d                	bnez	a0,80004156 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e2:	04c92483          	lw	s1,76(s2)
    800040e6:	c49d                	beqz	s1,80004114 <dirlink+0x54>
    800040e8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ea:	4741                	li	a4,16
    800040ec:	86a6                	mv	a3,s1
    800040ee:	fc040613          	addi	a2,s0,-64
    800040f2:	4581                	li	a1,0
    800040f4:	854a                	mv	a0,s2
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	b84080e7          	jalr	-1148(ra) # 80003c7a <readi>
    800040fe:	47c1                	li	a5,16
    80004100:	06f51163          	bne	a0,a5,80004162 <dirlink+0xa2>
    if(de.inum == 0)
    80004104:	fc045783          	lhu	a5,-64(s0)
    80004108:	c791                	beqz	a5,80004114 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000410a:	24c1                	addiw	s1,s1,16
    8000410c:	04c92783          	lw	a5,76(s2)
    80004110:	fcf4ede3          	bltu	s1,a5,800040ea <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004114:	4639                	li	a2,14
    80004116:	85d2                	mv	a1,s4
    80004118:	fc240513          	addi	a0,s0,-62
    8000411c:	ffffd097          	auipc	ra,0xffffd
    80004120:	cc2080e7          	jalr	-830(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004124:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004128:	4741                	li	a4,16
    8000412a:	86a6                	mv	a3,s1
    8000412c:	fc040613          	addi	a2,s0,-64
    80004130:	4581                	li	a1,0
    80004132:	854a                	mv	a0,s2
    80004134:	00000097          	auipc	ra,0x0
    80004138:	c3e080e7          	jalr	-962(ra) # 80003d72 <writei>
    8000413c:	1541                	addi	a0,a0,-16
    8000413e:	00a03533          	snez	a0,a0
    80004142:	40a00533          	neg	a0,a0
}
    80004146:	70e2                	ld	ra,56(sp)
    80004148:	7442                	ld	s0,48(sp)
    8000414a:	74a2                	ld	s1,40(sp)
    8000414c:	7902                	ld	s2,32(sp)
    8000414e:	69e2                	ld	s3,24(sp)
    80004150:	6a42                	ld	s4,16(sp)
    80004152:	6121                	addi	sp,sp,64
    80004154:	8082                	ret
    iput(ip);
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	a2a080e7          	jalr	-1494(ra) # 80003b80 <iput>
    return -1;
    8000415e:	557d                	li	a0,-1
    80004160:	b7dd                	j	80004146 <dirlink+0x86>
      panic("dirlink read");
    80004162:	00004517          	auipc	a0,0x4
    80004166:	4d650513          	addi	a0,a0,1238 # 80008638 <syscalls+0x1e8>
    8000416a:	ffffc097          	auipc	ra,0xffffc
    8000416e:	3d6080e7          	jalr	982(ra) # 80000540 <panic>

0000000080004172 <namei>:

struct inode*
namei(char *path)
{
    80004172:	1101                	addi	sp,sp,-32
    80004174:	ec06                	sd	ra,24(sp)
    80004176:	e822                	sd	s0,16(sp)
    80004178:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000417a:	fe040613          	addi	a2,s0,-32
    8000417e:	4581                	li	a1,0
    80004180:	00000097          	auipc	ra,0x0
    80004184:	dda080e7          	jalr	-550(ra) # 80003f5a <namex>
}
    80004188:	60e2                	ld	ra,24(sp)
    8000418a:	6442                	ld	s0,16(sp)
    8000418c:	6105                	addi	sp,sp,32
    8000418e:	8082                	ret

0000000080004190 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004190:	1141                	addi	sp,sp,-16
    80004192:	e406                	sd	ra,8(sp)
    80004194:	e022                	sd	s0,0(sp)
    80004196:	0800                	addi	s0,sp,16
    80004198:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000419a:	4585                	li	a1,1
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	dbe080e7          	jalr	-578(ra) # 80003f5a <namex>
}
    800041a4:	60a2                	ld	ra,8(sp)
    800041a6:	6402                	ld	s0,0(sp)
    800041a8:	0141                	addi	sp,sp,16
    800041aa:	8082                	ret

00000000800041ac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041ac:	1101                	addi	sp,sp,-32
    800041ae:	ec06                	sd	ra,24(sp)
    800041b0:	e822                	sd	s0,16(sp)
    800041b2:	e426                	sd	s1,8(sp)
    800041b4:	e04a                	sd	s2,0(sp)
    800041b6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041b8:	0001d917          	auipc	s2,0x1d
    800041bc:	58890913          	addi	s2,s2,1416 # 80021740 <log>
    800041c0:	01892583          	lw	a1,24(s2)
    800041c4:	02892503          	lw	a0,40(s2)
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	fe6080e7          	jalr	-26(ra) # 800031ae <bread>
    800041d0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041d2:	02c92683          	lw	a3,44(s2)
    800041d6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041d8:	02d05863          	blez	a3,80004208 <write_head+0x5c>
    800041dc:	0001d797          	auipc	a5,0x1d
    800041e0:	59478793          	addi	a5,a5,1428 # 80021770 <log+0x30>
    800041e4:	05c50713          	addi	a4,a0,92
    800041e8:	36fd                	addiw	a3,a3,-1
    800041ea:	02069613          	slli	a2,a3,0x20
    800041ee:	01e65693          	srli	a3,a2,0x1e
    800041f2:	0001d617          	auipc	a2,0x1d
    800041f6:	58260613          	addi	a2,a2,1410 # 80021774 <log+0x34>
    800041fa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041fc:	4390                	lw	a2,0(a5)
    800041fe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004200:	0791                	addi	a5,a5,4
    80004202:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004204:	fed79ce3          	bne	a5,a3,800041fc <write_head+0x50>
  }
  bwrite(buf);
    80004208:	8526                	mv	a0,s1
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	096080e7          	jalr	150(ra) # 800032a0 <bwrite>
  brelse(buf);
    80004212:	8526                	mv	a0,s1
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	0ca080e7          	jalr	202(ra) # 800032de <brelse>
}
    8000421c:	60e2                	ld	ra,24(sp)
    8000421e:	6442                	ld	s0,16(sp)
    80004220:	64a2                	ld	s1,8(sp)
    80004222:	6902                	ld	s2,0(sp)
    80004224:	6105                	addi	sp,sp,32
    80004226:	8082                	ret

0000000080004228 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004228:	0001d797          	auipc	a5,0x1d
    8000422c:	5447a783          	lw	a5,1348(a5) # 8002176c <log+0x2c>
    80004230:	0af05d63          	blez	a5,800042ea <install_trans+0xc2>
{
    80004234:	7139                	addi	sp,sp,-64
    80004236:	fc06                	sd	ra,56(sp)
    80004238:	f822                	sd	s0,48(sp)
    8000423a:	f426                	sd	s1,40(sp)
    8000423c:	f04a                	sd	s2,32(sp)
    8000423e:	ec4e                	sd	s3,24(sp)
    80004240:	e852                	sd	s4,16(sp)
    80004242:	e456                	sd	s5,8(sp)
    80004244:	e05a                	sd	s6,0(sp)
    80004246:	0080                	addi	s0,sp,64
    80004248:	8b2a                	mv	s6,a0
    8000424a:	0001da97          	auipc	s5,0x1d
    8000424e:	526a8a93          	addi	s5,s5,1318 # 80021770 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004252:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004254:	0001d997          	auipc	s3,0x1d
    80004258:	4ec98993          	addi	s3,s3,1260 # 80021740 <log>
    8000425c:	a00d                	j	8000427e <install_trans+0x56>
    brelse(lbuf);
    8000425e:	854a                	mv	a0,s2
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	07e080e7          	jalr	126(ra) # 800032de <brelse>
    brelse(dbuf);
    80004268:	8526                	mv	a0,s1
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	074080e7          	jalr	116(ra) # 800032de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004272:	2a05                	addiw	s4,s4,1
    80004274:	0a91                	addi	s5,s5,4
    80004276:	02c9a783          	lw	a5,44(s3)
    8000427a:	04fa5e63          	bge	s4,a5,800042d6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000427e:	0189a583          	lw	a1,24(s3)
    80004282:	014585bb          	addw	a1,a1,s4
    80004286:	2585                	addiw	a1,a1,1
    80004288:	0289a503          	lw	a0,40(s3)
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	f22080e7          	jalr	-222(ra) # 800031ae <bread>
    80004294:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004296:	000aa583          	lw	a1,0(s5)
    8000429a:	0289a503          	lw	a0,40(s3)
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	f10080e7          	jalr	-240(ra) # 800031ae <bread>
    800042a6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042a8:	40000613          	li	a2,1024
    800042ac:	05890593          	addi	a1,s2,88
    800042b0:	05850513          	addi	a0,a0,88
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	a7a080e7          	jalr	-1414(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800042bc:	8526                	mv	a0,s1
    800042be:	fffff097          	auipc	ra,0xfffff
    800042c2:	fe2080e7          	jalr	-30(ra) # 800032a0 <bwrite>
    if(recovering == 0)
    800042c6:	f80b1ce3          	bnez	s6,8000425e <install_trans+0x36>
      bunpin(dbuf);
    800042ca:	8526                	mv	a0,s1
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	0ec080e7          	jalr	236(ra) # 800033b8 <bunpin>
    800042d4:	b769                	j	8000425e <install_trans+0x36>
}
    800042d6:	70e2                	ld	ra,56(sp)
    800042d8:	7442                	ld	s0,48(sp)
    800042da:	74a2                	ld	s1,40(sp)
    800042dc:	7902                	ld	s2,32(sp)
    800042de:	69e2                	ld	s3,24(sp)
    800042e0:	6a42                	ld	s4,16(sp)
    800042e2:	6aa2                	ld	s5,8(sp)
    800042e4:	6b02                	ld	s6,0(sp)
    800042e6:	6121                	addi	sp,sp,64
    800042e8:	8082                	ret
    800042ea:	8082                	ret

00000000800042ec <initlog>:
{
    800042ec:	7179                	addi	sp,sp,-48
    800042ee:	f406                	sd	ra,40(sp)
    800042f0:	f022                	sd	s0,32(sp)
    800042f2:	ec26                	sd	s1,24(sp)
    800042f4:	e84a                	sd	s2,16(sp)
    800042f6:	e44e                	sd	s3,8(sp)
    800042f8:	1800                	addi	s0,sp,48
    800042fa:	892a                	mv	s2,a0
    800042fc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042fe:	0001d497          	auipc	s1,0x1d
    80004302:	44248493          	addi	s1,s1,1090 # 80021740 <log>
    80004306:	00004597          	auipc	a1,0x4
    8000430a:	34258593          	addi	a1,a1,834 # 80008648 <syscalls+0x1f8>
    8000430e:	8526                	mv	a0,s1
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	836080e7          	jalr	-1994(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004318:	0149a583          	lw	a1,20(s3)
    8000431c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000431e:	0109a783          	lw	a5,16(s3)
    80004322:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004324:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004328:	854a                	mv	a0,s2
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	e84080e7          	jalr	-380(ra) # 800031ae <bread>
  log.lh.n = lh->n;
    80004332:	4d34                	lw	a3,88(a0)
    80004334:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004336:	02d05663          	blez	a3,80004362 <initlog+0x76>
    8000433a:	05c50793          	addi	a5,a0,92
    8000433e:	0001d717          	auipc	a4,0x1d
    80004342:	43270713          	addi	a4,a4,1074 # 80021770 <log+0x30>
    80004346:	36fd                	addiw	a3,a3,-1
    80004348:	02069613          	slli	a2,a3,0x20
    8000434c:	01e65693          	srli	a3,a2,0x1e
    80004350:	06050613          	addi	a2,a0,96
    80004354:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004356:	4390                	lw	a2,0(a5)
    80004358:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000435a:	0791                	addi	a5,a5,4
    8000435c:	0711                	addi	a4,a4,4
    8000435e:	fed79ce3          	bne	a5,a3,80004356 <initlog+0x6a>
  brelse(buf);
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	f7c080e7          	jalr	-132(ra) # 800032de <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000436a:	4505                	li	a0,1
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	ebc080e7          	jalr	-324(ra) # 80004228 <install_trans>
  log.lh.n = 0;
    80004374:	0001d797          	auipc	a5,0x1d
    80004378:	3e07ac23          	sw	zero,1016(a5) # 8002176c <log+0x2c>
  write_head(); // clear the log
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	e30080e7          	jalr	-464(ra) # 800041ac <write_head>
}
    80004384:	70a2                	ld	ra,40(sp)
    80004386:	7402                	ld	s0,32(sp)
    80004388:	64e2                	ld	s1,24(sp)
    8000438a:	6942                	ld	s2,16(sp)
    8000438c:	69a2                	ld	s3,8(sp)
    8000438e:	6145                	addi	sp,sp,48
    80004390:	8082                	ret

0000000080004392 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004392:	1101                	addi	sp,sp,-32
    80004394:	ec06                	sd	ra,24(sp)
    80004396:	e822                	sd	s0,16(sp)
    80004398:	e426                	sd	s1,8(sp)
    8000439a:	e04a                	sd	s2,0(sp)
    8000439c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000439e:	0001d517          	auipc	a0,0x1d
    800043a2:	3a250513          	addi	a0,a0,930 # 80021740 <log>
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	830080e7          	jalr	-2000(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043ae:	0001d497          	auipc	s1,0x1d
    800043b2:	39248493          	addi	s1,s1,914 # 80021740 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043b6:	4979                	li	s2,30
    800043b8:	a039                	j	800043c6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043ba:	85a6                	mv	a1,s1
    800043bc:	8526                	mv	a0,s1
    800043be:	ffffe097          	auipc	ra,0xffffe
    800043c2:	caa080e7          	jalr	-854(ra) # 80002068 <sleep>
    if(log.committing){
    800043c6:	50dc                	lw	a5,36(s1)
    800043c8:	fbed                	bnez	a5,800043ba <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ca:	5098                	lw	a4,32(s1)
    800043cc:	2705                	addiw	a4,a4,1
    800043ce:	0007069b          	sext.w	a3,a4
    800043d2:	0027179b          	slliw	a5,a4,0x2
    800043d6:	9fb9                	addw	a5,a5,a4
    800043d8:	0017979b          	slliw	a5,a5,0x1
    800043dc:	54d8                	lw	a4,44(s1)
    800043de:	9fb9                	addw	a5,a5,a4
    800043e0:	00f95963          	bge	s2,a5,800043f2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043e4:	85a6                	mv	a1,s1
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	c80080e7          	jalr	-896(ra) # 80002068 <sleep>
    800043f0:	bfd9                	j	800043c6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043f2:	0001d517          	auipc	a0,0x1d
    800043f6:	34e50513          	addi	a0,a0,846 # 80021740 <log>
    800043fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004404:	60e2                	ld	ra,24(sp)
    80004406:	6442                	ld	s0,16(sp)
    80004408:	64a2                	ld	s1,8(sp)
    8000440a:	6902                	ld	s2,0(sp)
    8000440c:	6105                	addi	sp,sp,32
    8000440e:	8082                	ret

0000000080004410 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004410:	7139                	addi	sp,sp,-64
    80004412:	fc06                	sd	ra,56(sp)
    80004414:	f822                	sd	s0,48(sp)
    80004416:	f426                	sd	s1,40(sp)
    80004418:	f04a                	sd	s2,32(sp)
    8000441a:	ec4e                	sd	s3,24(sp)
    8000441c:	e852                	sd	s4,16(sp)
    8000441e:	e456                	sd	s5,8(sp)
    80004420:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004422:	0001d497          	auipc	s1,0x1d
    80004426:	31e48493          	addi	s1,s1,798 # 80021740 <log>
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	7aa080e7          	jalr	1962(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004434:	509c                	lw	a5,32(s1)
    80004436:	37fd                	addiw	a5,a5,-1
    80004438:	0007891b          	sext.w	s2,a5
    8000443c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000443e:	50dc                	lw	a5,36(s1)
    80004440:	e7b9                	bnez	a5,8000448e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004442:	04091e63          	bnez	s2,8000449e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004446:	0001d497          	auipc	s1,0x1d
    8000444a:	2fa48493          	addi	s1,s1,762 # 80021740 <log>
    8000444e:	4785                	li	a5,1
    80004450:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004452:	8526                	mv	a0,s1
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	836080e7          	jalr	-1994(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000445c:	54dc                	lw	a5,44(s1)
    8000445e:	06f04763          	bgtz	a5,800044cc <end_op+0xbc>
    acquire(&log.lock);
    80004462:	0001d497          	auipc	s1,0x1d
    80004466:	2de48493          	addi	s1,s1,734 # 80021740 <log>
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	76a080e7          	jalr	1898(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004474:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004478:	8526                	mv	a0,s1
    8000447a:	ffffe097          	auipc	ra,0xffffe
    8000447e:	c52080e7          	jalr	-942(ra) # 800020cc <wakeup>
    release(&log.lock);
    80004482:	8526                	mv	a0,s1
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	806080e7          	jalr	-2042(ra) # 80000c8a <release>
}
    8000448c:	a03d                	j	800044ba <end_op+0xaa>
    panic("log.committing");
    8000448e:	00004517          	auipc	a0,0x4
    80004492:	1c250513          	addi	a0,a0,450 # 80008650 <syscalls+0x200>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	0aa080e7          	jalr	170(ra) # 80000540 <panic>
    wakeup(&log);
    8000449e:	0001d497          	auipc	s1,0x1d
    800044a2:	2a248493          	addi	s1,s1,674 # 80021740 <log>
    800044a6:	8526                	mv	a0,s1
    800044a8:	ffffe097          	auipc	ra,0xffffe
    800044ac:	c24080e7          	jalr	-988(ra) # 800020cc <wakeup>
  release(&log.lock);
    800044b0:	8526                	mv	a0,s1
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	7d8080e7          	jalr	2008(ra) # 80000c8a <release>
}
    800044ba:	70e2                	ld	ra,56(sp)
    800044bc:	7442                	ld	s0,48(sp)
    800044be:	74a2                	ld	s1,40(sp)
    800044c0:	7902                	ld	s2,32(sp)
    800044c2:	69e2                	ld	s3,24(sp)
    800044c4:	6a42                	ld	s4,16(sp)
    800044c6:	6aa2                	ld	s5,8(sp)
    800044c8:	6121                	addi	sp,sp,64
    800044ca:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044cc:	0001da97          	auipc	s5,0x1d
    800044d0:	2a4a8a93          	addi	s5,s5,676 # 80021770 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044d4:	0001da17          	auipc	s4,0x1d
    800044d8:	26ca0a13          	addi	s4,s4,620 # 80021740 <log>
    800044dc:	018a2583          	lw	a1,24(s4)
    800044e0:	012585bb          	addw	a1,a1,s2
    800044e4:	2585                	addiw	a1,a1,1
    800044e6:	028a2503          	lw	a0,40(s4)
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	cc4080e7          	jalr	-828(ra) # 800031ae <bread>
    800044f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044f4:	000aa583          	lw	a1,0(s5)
    800044f8:	028a2503          	lw	a0,40(s4)
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	cb2080e7          	jalr	-846(ra) # 800031ae <bread>
    80004504:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004506:	40000613          	li	a2,1024
    8000450a:	05850593          	addi	a1,a0,88
    8000450e:	05848513          	addi	a0,s1,88
    80004512:	ffffd097          	auipc	ra,0xffffd
    80004516:	81c080e7          	jalr	-2020(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000451a:	8526                	mv	a0,s1
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	d84080e7          	jalr	-636(ra) # 800032a0 <bwrite>
    brelse(from);
    80004524:	854e                	mv	a0,s3
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	db8080e7          	jalr	-584(ra) # 800032de <brelse>
    brelse(to);
    8000452e:	8526                	mv	a0,s1
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	dae080e7          	jalr	-594(ra) # 800032de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004538:	2905                	addiw	s2,s2,1
    8000453a:	0a91                	addi	s5,s5,4
    8000453c:	02ca2783          	lw	a5,44(s4)
    80004540:	f8f94ee3          	blt	s2,a5,800044dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004544:	00000097          	auipc	ra,0x0
    80004548:	c68080e7          	jalr	-920(ra) # 800041ac <write_head>
    install_trans(0); // Now install writes to home locations
    8000454c:	4501                	li	a0,0
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	cda080e7          	jalr	-806(ra) # 80004228 <install_trans>
    log.lh.n = 0;
    80004556:	0001d797          	auipc	a5,0x1d
    8000455a:	2007ab23          	sw	zero,534(a5) # 8002176c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	c4e080e7          	jalr	-946(ra) # 800041ac <write_head>
    80004566:	bdf5                	j	80004462 <end_op+0x52>

0000000080004568 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	e04a                	sd	s2,0(sp)
    80004572:	1000                	addi	s0,sp,32
    80004574:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004576:	0001d917          	auipc	s2,0x1d
    8000457a:	1ca90913          	addi	s2,s2,458 # 80021740 <log>
    8000457e:	854a                	mv	a0,s2
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	656080e7          	jalr	1622(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004588:	02c92603          	lw	a2,44(s2)
    8000458c:	47f5                	li	a5,29
    8000458e:	06c7c563          	blt	a5,a2,800045f8 <log_write+0x90>
    80004592:	0001d797          	auipc	a5,0x1d
    80004596:	1ca7a783          	lw	a5,458(a5) # 8002175c <log+0x1c>
    8000459a:	37fd                	addiw	a5,a5,-1
    8000459c:	04f65e63          	bge	a2,a5,800045f8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045a0:	0001d797          	auipc	a5,0x1d
    800045a4:	1c07a783          	lw	a5,448(a5) # 80021760 <log+0x20>
    800045a8:	06f05063          	blez	a5,80004608 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045ac:	4781                	li	a5,0
    800045ae:	06c05563          	blez	a2,80004618 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045b2:	44cc                	lw	a1,12(s1)
    800045b4:	0001d717          	auipc	a4,0x1d
    800045b8:	1bc70713          	addi	a4,a4,444 # 80021770 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045be:	4314                	lw	a3,0(a4)
    800045c0:	04b68c63          	beq	a3,a1,80004618 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045c4:	2785                	addiw	a5,a5,1
    800045c6:	0711                	addi	a4,a4,4
    800045c8:	fef61be3          	bne	a2,a5,800045be <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045cc:	0621                	addi	a2,a2,8
    800045ce:	060a                	slli	a2,a2,0x2
    800045d0:	0001d797          	auipc	a5,0x1d
    800045d4:	17078793          	addi	a5,a5,368 # 80021740 <log>
    800045d8:	97b2                	add	a5,a5,a2
    800045da:	44d8                	lw	a4,12(s1)
    800045dc:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045de:	8526                	mv	a0,s1
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	d9c080e7          	jalr	-612(ra) # 8000337c <bpin>
    log.lh.n++;
    800045e8:	0001d717          	auipc	a4,0x1d
    800045ec:	15870713          	addi	a4,a4,344 # 80021740 <log>
    800045f0:	575c                	lw	a5,44(a4)
    800045f2:	2785                	addiw	a5,a5,1
    800045f4:	d75c                	sw	a5,44(a4)
    800045f6:	a82d                	j	80004630 <log_write+0xc8>
    panic("too big a transaction");
    800045f8:	00004517          	auipc	a0,0x4
    800045fc:	06850513          	addi	a0,a0,104 # 80008660 <syscalls+0x210>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	f40080e7          	jalr	-192(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004608:	00004517          	auipc	a0,0x4
    8000460c:	07050513          	addi	a0,a0,112 # 80008678 <syscalls+0x228>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	f30080e7          	jalr	-208(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004618:	00878693          	addi	a3,a5,8
    8000461c:	068a                	slli	a3,a3,0x2
    8000461e:	0001d717          	auipc	a4,0x1d
    80004622:	12270713          	addi	a4,a4,290 # 80021740 <log>
    80004626:	9736                	add	a4,a4,a3
    80004628:	44d4                	lw	a3,12(s1)
    8000462a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000462c:	faf609e3          	beq	a2,a5,800045de <log_write+0x76>
  }
  release(&log.lock);
    80004630:	0001d517          	auipc	a0,0x1d
    80004634:	11050513          	addi	a0,a0,272 # 80021740 <log>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
}
    80004640:	60e2                	ld	ra,24(sp)
    80004642:	6442                	ld	s0,16(sp)
    80004644:	64a2                	ld	s1,8(sp)
    80004646:	6902                	ld	s2,0(sp)
    80004648:	6105                	addi	sp,sp,32
    8000464a:	8082                	ret

000000008000464c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000464c:	1101                	addi	sp,sp,-32
    8000464e:	ec06                	sd	ra,24(sp)
    80004650:	e822                	sd	s0,16(sp)
    80004652:	e426                	sd	s1,8(sp)
    80004654:	e04a                	sd	s2,0(sp)
    80004656:	1000                	addi	s0,sp,32
    80004658:	84aa                	mv	s1,a0
    8000465a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000465c:	00004597          	auipc	a1,0x4
    80004660:	03c58593          	addi	a1,a1,60 # 80008698 <syscalls+0x248>
    80004664:	0521                	addi	a0,a0,8
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	4e0080e7          	jalr	1248(ra) # 80000b46 <initlock>
  lk->name = name;
    8000466e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004672:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004676:	0204a423          	sw	zero,40(s1)
}
    8000467a:	60e2                	ld	ra,24(sp)
    8000467c:	6442                	ld	s0,16(sp)
    8000467e:	64a2                	ld	s1,8(sp)
    80004680:	6902                	ld	s2,0(sp)
    80004682:	6105                	addi	sp,sp,32
    80004684:	8082                	ret

0000000080004686 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004686:	1101                	addi	sp,sp,-32
    80004688:	ec06                	sd	ra,24(sp)
    8000468a:	e822                	sd	s0,16(sp)
    8000468c:	e426                	sd	s1,8(sp)
    8000468e:	e04a                	sd	s2,0(sp)
    80004690:	1000                	addi	s0,sp,32
    80004692:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004694:	00850913          	addi	s2,a0,8
    80004698:	854a                	mv	a0,s2
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	53c080e7          	jalr	1340(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800046a2:	409c                	lw	a5,0(s1)
    800046a4:	cb89                	beqz	a5,800046b6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046a6:	85ca                	mv	a1,s2
    800046a8:	8526                	mv	a0,s1
    800046aa:	ffffe097          	auipc	ra,0xffffe
    800046ae:	9be080e7          	jalr	-1602(ra) # 80002068 <sleep>
  while (lk->locked) {
    800046b2:	409c                	lw	a5,0(s1)
    800046b4:	fbed                	bnez	a5,800046a6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046b6:	4785                	li	a5,1
    800046b8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046ba:	ffffd097          	auipc	ra,0xffffd
    800046be:	2f2080e7          	jalr	754(ra) # 800019ac <myproc>
    800046c2:	591c                	lw	a5,48(a0)
    800046c4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046c6:	854a                	mv	a0,s2
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5c2080e7          	jalr	1474(ra) # 80000c8a <release>
}
    800046d0:	60e2                	ld	ra,24(sp)
    800046d2:	6442                	ld	s0,16(sp)
    800046d4:	64a2                	ld	s1,8(sp)
    800046d6:	6902                	ld	s2,0(sp)
    800046d8:	6105                	addi	sp,sp,32
    800046da:	8082                	ret

00000000800046dc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046dc:	1101                	addi	sp,sp,-32
    800046de:	ec06                	sd	ra,24(sp)
    800046e0:	e822                	sd	s0,16(sp)
    800046e2:	e426                	sd	s1,8(sp)
    800046e4:	e04a                	sd	s2,0(sp)
    800046e6:	1000                	addi	s0,sp,32
    800046e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046ea:	00850913          	addi	s2,a0,8
    800046ee:	854a                	mv	a0,s2
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	4e6080e7          	jalr	1254(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800046f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046fc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004700:	8526                	mv	a0,s1
    80004702:	ffffe097          	auipc	ra,0xffffe
    80004706:	9ca080e7          	jalr	-1590(ra) # 800020cc <wakeup>
  release(&lk->lk);
    8000470a:	854a                	mv	a0,s2
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	57e080e7          	jalr	1406(ra) # 80000c8a <release>
}
    80004714:	60e2                	ld	ra,24(sp)
    80004716:	6442                	ld	s0,16(sp)
    80004718:	64a2                	ld	s1,8(sp)
    8000471a:	6902                	ld	s2,0(sp)
    8000471c:	6105                	addi	sp,sp,32
    8000471e:	8082                	ret

0000000080004720 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004720:	7179                	addi	sp,sp,-48
    80004722:	f406                	sd	ra,40(sp)
    80004724:	f022                	sd	s0,32(sp)
    80004726:	ec26                	sd	s1,24(sp)
    80004728:	e84a                	sd	s2,16(sp)
    8000472a:	e44e                	sd	s3,8(sp)
    8000472c:	1800                	addi	s0,sp,48
    8000472e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004730:	00850913          	addi	s2,a0,8
    80004734:	854a                	mv	a0,s2
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	4a0080e7          	jalr	1184(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000473e:	409c                	lw	a5,0(s1)
    80004740:	ef99                	bnez	a5,8000475e <holdingsleep+0x3e>
    80004742:	4481                	li	s1,0
  release(&lk->lk);
    80004744:	854a                	mv	a0,s2
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
  return r;
}
    8000474e:	8526                	mv	a0,s1
    80004750:	70a2                	ld	ra,40(sp)
    80004752:	7402                	ld	s0,32(sp)
    80004754:	64e2                	ld	s1,24(sp)
    80004756:	6942                	ld	s2,16(sp)
    80004758:	69a2                	ld	s3,8(sp)
    8000475a:	6145                	addi	sp,sp,48
    8000475c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000475e:	0284a983          	lw	s3,40(s1)
    80004762:	ffffd097          	auipc	ra,0xffffd
    80004766:	24a080e7          	jalr	586(ra) # 800019ac <myproc>
    8000476a:	5904                	lw	s1,48(a0)
    8000476c:	413484b3          	sub	s1,s1,s3
    80004770:	0014b493          	seqz	s1,s1
    80004774:	bfc1                	j	80004744 <holdingsleep+0x24>

0000000080004776 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004776:	1141                	addi	sp,sp,-16
    80004778:	e406                	sd	ra,8(sp)
    8000477a:	e022                	sd	s0,0(sp)
    8000477c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000477e:	00004597          	auipc	a1,0x4
    80004782:	f2a58593          	addi	a1,a1,-214 # 800086a8 <syscalls+0x258>
    80004786:	0001d517          	auipc	a0,0x1d
    8000478a:	10250513          	addi	a0,a0,258 # 80021888 <ftable>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	3b8080e7          	jalr	952(ra) # 80000b46 <initlock>
}
    80004796:	60a2                	ld	ra,8(sp)
    80004798:	6402                	ld	s0,0(sp)
    8000479a:	0141                	addi	sp,sp,16
    8000479c:	8082                	ret

000000008000479e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000479e:	1101                	addi	sp,sp,-32
    800047a0:	ec06                	sd	ra,24(sp)
    800047a2:	e822                	sd	s0,16(sp)
    800047a4:	e426                	sd	s1,8(sp)
    800047a6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047a8:	0001d517          	auipc	a0,0x1d
    800047ac:	0e050513          	addi	a0,a0,224 # 80021888 <ftable>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	426080e7          	jalr	1062(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047b8:	0001d497          	auipc	s1,0x1d
    800047bc:	0e848493          	addi	s1,s1,232 # 800218a0 <ftable+0x18>
    800047c0:	0001e717          	auipc	a4,0x1e
    800047c4:	08070713          	addi	a4,a4,128 # 80022840 <disk>
    if(f->ref == 0){
    800047c8:	40dc                	lw	a5,4(s1)
    800047ca:	cf99                	beqz	a5,800047e8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047cc:	02848493          	addi	s1,s1,40
    800047d0:	fee49ce3          	bne	s1,a4,800047c8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047d4:	0001d517          	auipc	a0,0x1d
    800047d8:	0b450513          	addi	a0,a0,180 # 80021888 <ftable>
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	4ae080e7          	jalr	1198(ra) # 80000c8a <release>
  return 0;
    800047e4:	4481                	li	s1,0
    800047e6:	a819                	j	800047fc <filealloc+0x5e>
      f->ref = 1;
    800047e8:	4785                	li	a5,1
    800047ea:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047ec:	0001d517          	auipc	a0,0x1d
    800047f0:	09c50513          	addi	a0,a0,156 # 80021888 <ftable>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	496080e7          	jalr	1174(ra) # 80000c8a <release>
}
    800047fc:	8526                	mv	a0,s1
    800047fe:	60e2                	ld	ra,24(sp)
    80004800:	6442                	ld	s0,16(sp)
    80004802:	64a2                	ld	s1,8(sp)
    80004804:	6105                	addi	sp,sp,32
    80004806:	8082                	ret

0000000080004808 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004808:	1101                	addi	sp,sp,-32
    8000480a:	ec06                	sd	ra,24(sp)
    8000480c:	e822                	sd	s0,16(sp)
    8000480e:	e426                	sd	s1,8(sp)
    80004810:	1000                	addi	s0,sp,32
    80004812:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004814:	0001d517          	auipc	a0,0x1d
    80004818:	07450513          	addi	a0,a0,116 # 80021888 <ftable>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	3ba080e7          	jalr	954(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004824:	40dc                	lw	a5,4(s1)
    80004826:	02f05263          	blez	a5,8000484a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000482a:	2785                	addiw	a5,a5,1
    8000482c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000482e:	0001d517          	auipc	a0,0x1d
    80004832:	05a50513          	addi	a0,a0,90 # 80021888 <ftable>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	454080e7          	jalr	1108(ra) # 80000c8a <release>
  return f;
}
    8000483e:	8526                	mv	a0,s1
    80004840:	60e2                	ld	ra,24(sp)
    80004842:	6442                	ld	s0,16(sp)
    80004844:	64a2                	ld	s1,8(sp)
    80004846:	6105                	addi	sp,sp,32
    80004848:	8082                	ret
    panic("filedup");
    8000484a:	00004517          	auipc	a0,0x4
    8000484e:	e6650513          	addi	a0,a0,-410 # 800086b0 <syscalls+0x260>
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	cee080e7          	jalr	-786(ra) # 80000540 <panic>

000000008000485a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000485a:	7139                	addi	sp,sp,-64
    8000485c:	fc06                	sd	ra,56(sp)
    8000485e:	f822                	sd	s0,48(sp)
    80004860:	f426                	sd	s1,40(sp)
    80004862:	f04a                	sd	s2,32(sp)
    80004864:	ec4e                	sd	s3,24(sp)
    80004866:	e852                	sd	s4,16(sp)
    80004868:	e456                	sd	s5,8(sp)
    8000486a:	0080                	addi	s0,sp,64
    8000486c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000486e:	0001d517          	auipc	a0,0x1d
    80004872:	01a50513          	addi	a0,a0,26 # 80021888 <ftable>
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	360080e7          	jalr	864(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000487e:	40dc                	lw	a5,4(s1)
    80004880:	06f05163          	blez	a5,800048e2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004884:	37fd                	addiw	a5,a5,-1
    80004886:	0007871b          	sext.w	a4,a5
    8000488a:	c0dc                	sw	a5,4(s1)
    8000488c:	06e04363          	bgtz	a4,800048f2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004890:	0004a903          	lw	s2,0(s1)
    80004894:	0094ca83          	lbu	s5,9(s1)
    80004898:	0104ba03          	ld	s4,16(s1)
    8000489c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048a0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048a4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048a8:	0001d517          	auipc	a0,0x1d
    800048ac:	fe050513          	addi	a0,a0,-32 # 80021888 <ftable>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	3da080e7          	jalr	986(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800048b8:	4785                	li	a5,1
    800048ba:	04f90d63          	beq	s2,a5,80004914 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048be:	3979                	addiw	s2,s2,-2
    800048c0:	4785                	li	a5,1
    800048c2:	0527e063          	bltu	a5,s2,80004902 <fileclose+0xa8>
    begin_op();
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	acc080e7          	jalr	-1332(ra) # 80004392 <begin_op>
    iput(ff.ip);
    800048ce:	854e                	mv	a0,s3
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	2b0080e7          	jalr	688(ra) # 80003b80 <iput>
    end_op();
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	b38080e7          	jalr	-1224(ra) # 80004410 <end_op>
    800048e0:	a00d                	j	80004902 <fileclose+0xa8>
    panic("fileclose");
    800048e2:	00004517          	auipc	a0,0x4
    800048e6:	dd650513          	addi	a0,a0,-554 # 800086b8 <syscalls+0x268>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	c56080e7          	jalr	-938(ra) # 80000540 <panic>
    release(&ftable.lock);
    800048f2:	0001d517          	auipc	a0,0x1d
    800048f6:	f9650513          	addi	a0,a0,-106 # 80021888 <ftable>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	390080e7          	jalr	912(ra) # 80000c8a <release>
  }
}
    80004902:	70e2                	ld	ra,56(sp)
    80004904:	7442                	ld	s0,48(sp)
    80004906:	74a2                	ld	s1,40(sp)
    80004908:	7902                	ld	s2,32(sp)
    8000490a:	69e2                	ld	s3,24(sp)
    8000490c:	6a42                	ld	s4,16(sp)
    8000490e:	6aa2                	ld	s5,8(sp)
    80004910:	6121                	addi	sp,sp,64
    80004912:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004914:	85d6                	mv	a1,s5
    80004916:	8552                	mv	a0,s4
    80004918:	00000097          	auipc	ra,0x0
    8000491c:	34c080e7          	jalr	844(ra) # 80004c64 <pipeclose>
    80004920:	b7cd                	j	80004902 <fileclose+0xa8>

0000000080004922 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004922:	715d                	addi	sp,sp,-80
    80004924:	e486                	sd	ra,72(sp)
    80004926:	e0a2                	sd	s0,64(sp)
    80004928:	fc26                	sd	s1,56(sp)
    8000492a:	f84a                	sd	s2,48(sp)
    8000492c:	f44e                	sd	s3,40(sp)
    8000492e:	0880                	addi	s0,sp,80
    80004930:	84aa                	mv	s1,a0
    80004932:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004934:	ffffd097          	auipc	ra,0xffffd
    80004938:	078080e7          	jalr	120(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000493c:	409c                	lw	a5,0(s1)
    8000493e:	37f9                	addiw	a5,a5,-2
    80004940:	4705                	li	a4,1
    80004942:	04f76763          	bltu	a4,a5,80004990 <filestat+0x6e>
    80004946:	892a                	mv	s2,a0
    ilock(f->ip);
    80004948:	6c88                	ld	a0,24(s1)
    8000494a:	fffff097          	auipc	ra,0xfffff
    8000494e:	07c080e7          	jalr	124(ra) # 800039c6 <ilock>
    stati(f->ip, &st);
    80004952:	fb840593          	addi	a1,s0,-72
    80004956:	6c88                	ld	a0,24(s1)
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	2f8080e7          	jalr	760(ra) # 80003c50 <stati>
    iunlock(f->ip);
    80004960:	6c88                	ld	a0,24(s1)
    80004962:	fffff097          	auipc	ra,0xfffff
    80004966:	126080e7          	jalr	294(ra) # 80003a88 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000496a:	46e1                	li	a3,24
    8000496c:	fb840613          	addi	a2,s0,-72
    80004970:	85ce                	mv	a1,s3
    80004972:	05093503          	ld	a0,80(s2)
    80004976:	ffffd097          	auipc	ra,0xffffd
    8000497a:	cf6080e7          	jalr	-778(ra) # 8000166c <copyout>
    8000497e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004982:	60a6                	ld	ra,72(sp)
    80004984:	6406                	ld	s0,64(sp)
    80004986:	74e2                	ld	s1,56(sp)
    80004988:	7942                	ld	s2,48(sp)
    8000498a:	79a2                	ld	s3,40(sp)
    8000498c:	6161                	addi	sp,sp,80
    8000498e:	8082                	ret
  return -1;
    80004990:	557d                	li	a0,-1
    80004992:	bfc5                	j	80004982 <filestat+0x60>

0000000080004994 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004994:	7179                	addi	sp,sp,-48
    80004996:	f406                	sd	ra,40(sp)
    80004998:	f022                	sd	s0,32(sp)
    8000499a:	ec26                	sd	s1,24(sp)
    8000499c:	e84a                	sd	s2,16(sp)
    8000499e:	e44e                	sd	s3,8(sp)
    800049a0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049a2:	00854783          	lbu	a5,8(a0)
    800049a6:	c3d5                	beqz	a5,80004a4a <fileread+0xb6>
    800049a8:	84aa                	mv	s1,a0
    800049aa:	89ae                	mv	s3,a1
    800049ac:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ae:	411c                	lw	a5,0(a0)
    800049b0:	4705                	li	a4,1
    800049b2:	04e78963          	beq	a5,a4,80004a04 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049b6:	470d                	li	a4,3
    800049b8:	04e78d63          	beq	a5,a4,80004a12 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049bc:	4709                	li	a4,2
    800049be:	06e79e63          	bne	a5,a4,80004a3a <fileread+0xa6>
    ilock(f->ip);
    800049c2:	6d08                	ld	a0,24(a0)
    800049c4:	fffff097          	auipc	ra,0xfffff
    800049c8:	002080e7          	jalr	2(ra) # 800039c6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049cc:	874a                	mv	a4,s2
    800049ce:	5094                	lw	a3,32(s1)
    800049d0:	864e                	mv	a2,s3
    800049d2:	4585                	li	a1,1
    800049d4:	6c88                	ld	a0,24(s1)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	2a4080e7          	jalr	676(ra) # 80003c7a <readi>
    800049de:	892a                	mv	s2,a0
    800049e0:	00a05563          	blez	a0,800049ea <fileread+0x56>
      f->off += r;
    800049e4:	509c                	lw	a5,32(s1)
    800049e6:	9fa9                	addw	a5,a5,a0
    800049e8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049ea:	6c88                	ld	a0,24(s1)
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	09c080e7          	jalr	156(ra) # 80003a88 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049f4:	854a                	mv	a0,s2
    800049f6:	70a2                	ld	ra,40(sp)
    800049f8:	7402                	ld	s0,32(sp)
    800049fa:	64e2                	ld	s1,24(sp)
    800049fc:	6942                	ld	s2,16(sp)
    800049fe:	69a2                	ld	s3,8(sp)
    80004a00:	6145                	addi	sp,sp,48
    80004a02:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a04:	6908                	ld	a0,16(a0)
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	3c6080e7          	jalr	966(ra) # 80004dcc <piperead>
    80004a0e:	892a                	mv	s2,a0
    80004a10:	b7d5                	j	800049f4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a12:	02451783          	lh	a5,36(a0)
    80004a16:	03079693          	slli	a3,a5,0x30
    80004a1a:	92c1                	srli	a3,a3,0x30
    80004a1c:	4725                	li	a4,9
    80004a1e:	02d76863          	bltu	a4,a3,80004a4e <fileread+0xba>
    80004a22:	0792                	slli	a5,a5,0x4
    80004a24:	0001d717          	auipc	a4,0x1d
    80004a28:	dc470713          	addi	a4,a4,-572 # 800217e8 <devsw>
    80004a2c:	97ba                	add	a5,a5,a4
    80004a2e:	639c                	ld	a5,0(a5)
    80004a30:	c38d                	beqz	a5,80004a52 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a32:	4505                	li	a0,1
    80004a34:	9782                	jalr	a5
    80004a36:	892a                	mv	s2,a0
    80004a38:	bf75                	j	800049f4 <fileread+0x60>
    panic("fileread");
    80004a3a:	00004517          	auipc	a0,0x4
    80004a3e:	c8e50513          	addi	a0,a0,-882 # 800086c8 <syscalls+0x278>
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	afe080e7          	jalr	-1282(ra) # 80000540 <panic>
    return -1;
    80004a4a:	597d                	li	s2,-1
    80004a4c:	b765                	j	800049f4 <fileread+0x60>
      return -1;
    80004a4e:	597d                	li	s2,-1
    80004a50:	b755                	j	800049f4 <fileread+0x60>
    80004a52:	597d                	li	s2,-1
    80004a54:	b745                	j	800049f4 <fileread+0x60>

0000000080004a56 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a56:	715d                	addi	sp,sp,-80
    80004a58:	e486                	sd	ra,72(sp)
    80004a5a:	e0a2                	sd	s0,64(sp)
    80004a5c:	fc26                	sd	s1,56(sp)
    80004a5e:	f84a                	sd	s2,48(sp)
    80004a60:	f44e                	sd	s3,40(sp)
    80004a62:	f052                	sd	s4,32(sp)
    80004a64:	ec56                	sd	s5,24(sp)
    80004a66:	e85a                	sd	s6,16(sp)
    80004a68:	e45e                	sd	s7,8(sp)
    80004a6a:	e062                	sd	s8,0(sp)
    80004a6c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a6e:	00954783          	lbu	a5,9(a0)
    80004a72:	10078663          	beqz	a5,80004b7e <filewrite+0x128>
    80004a76:	892a                	mv	s2,a0
    80004a78:	8b2e                	mv	s6,a1
    80004a7a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a7c:	411c                	lw	a5,0(a0)
    80004a7e:	4705                	li	a4,1
    80004a80:	02e78263          	beq	a5,a4,80004aa4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a84:	470d                	li	a4,3
    80004a86:	02e78663          	beq	a5,a4,80004ab2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a8a:	4709                	li	a4,2
    80004a8c:	0ee79163          	bne	a5,a4,80004b6e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a90:	0ac05d63          	blez	a2,80004b4a <filewrite+0xf4>
    int i = 0;
    80004a94:	4981                	li	s3,0
    80004a96:	6b85                	lui	s7,0x1
    80004a98:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a9c:	6c05                	lui	s8,0x1
    80004a9e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004aa2:	a861                	j	80004b3a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004aa4:	6908                	ld	a0,16(a0)
    80004aa6:	00000097          	auipc	ra,0x0
    80004aaa:	22e080e7          	jalr	558(ra) # 80004cd4 <pipewrite>
    80004aae:	8a2a                	mv	s4,a0
    80004ab0:	a045                	j	80004b50 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ab2:	02451783          	lh	a5,36(a0)
    80004ab6:	03079693          	slli	a3,a5,0x30
    80004aba:	92c1                	srli	a3,a3,0x30
    80004abc:	4725                	li	a4,9
    80004abe:	0cd76263          	bltu	a4,a3,80004b82 <filewrite+0x12c>
    80004ac2:	0792                	slli	a5,a5,0x4
    80004ac4:	0001d717          	auipc	a4,0x1d
    80004ac8:	d2470713          	addi	a4,a4,-732 # 800217e8 <devsw>
    80004acc:	97ba                	add	a5,a5,a4
    80004ace:	679c                	ld	a5,8(a5)
    80004ad0:	cbdd                	beqz	a5,80004b86 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ad2:	4505                	li	a0,1
    80004ad4:	9782                	jalr	a5
    80004ad6:	8a2a                	mv	s4,a0
    80004ad8:	a8a5                	j	80004b50 <filewrite+0xfa>
    80004ada:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ade:	00000097          	auipc	ra,0x0
    80004ae2:	8b4080e7          	jalr	-1868(ra) # 80004392 <begin_op>
      ilock(f->ip);
    80004ae6:	01893503          	ld	a0,24(s2)
    80004aea:	fffff097          	auipc	ra,0xfffff
    80004aee:	edc080e7          	jalr	-292(ra) # 800039c6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004af2:	8756                	mv	a4,s5
    80004af4:	02092683          	lw	a3,32(s2)
    80004af8:	01698633          	add	a2,s3,s6
    80004afc:	4585                	li	a1,1
    80004afe:	01893503          	ld	a0,24(s2)
    80004b02:	fffff097          	auipc	ra,0xfffff
    80004b06:	270080e7          	jalr	624(ra) # 80003d72 <writei>
    80004b0a:	84aa                	mv	s1,a0
    80004b0c:	00a05763          	blez	a0,80004b1a <filewrite+0xc4>
        f->off += r;
    80004b10:	02092783          	lw	a5,32(s2)
    80004b14:	9fa9                	addw	a5,a5,a0
    80004b16:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b1a:	01893503          	ld	a0,24(s2)
    80004b1e:	fffff097          	auipc	ra,0xfffff
    80004b22:	f6a080e7          	jalr	-150(ra) # 80003a88 <iunlock>
      end_op();
    80004b26:	00000097          	auipc	ra,0x0
    80004b2a:	8ea080e7          	jalr	-1814(ra) # 80004410 <end_op>

      if(r != n1){
    80004b2e:	009a9f63          	bne	s5,s1,80004b4c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b32:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b36:	0149db63          	bge	s3,s4,80004b4c <filewrite+0xf6>
      int n1 = n - i;
    80004b3a:	413a04bb          	subw	s1,s4,s3
    80004b3e:	0004879b          	sext.w	a5,s1
    80004b42:	f8fbdce3          	bge	s7,a5,80004ada <filewrite+0x84>
    80004b46:	84e2                	mv	s1,s8
    80004b48:	bf49                	j	80004ada <filewrite+0x84>
    int i = 0;
    80004b4a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b4c:	013a1f63          	bne	s4,s3,80004b6a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b50:	8552                	mv	a0,s4
    80004b52:	60a6                	ld	ra,72(sp)
    80004b54:	6406                	ld	s0,64(sp)
    80004b56:	74e2                	ld	s1,56(sp)
    80004b58:	7942                	ld	s2,48(sp)
    80004b5a:	79a2                	ld	s3,40(sp)
    80004b5c:	7a02                	ld	s4,32(sp)
    80004b5e:	6ae2                	ld	s5,24(sp)
    80004b60:	6b42                	ld	s6,16(sp)
    80004b62:	6ba2                	ld	s7,8(sp)
    80004b64:	6c02                	ld	s8,0(sp)
    80004b66:	6161                	addi	sp,sp,80
    80004b68:	8082                	ret
    ret = (i == n ? n : -1);
    80004b6a:	5a7d                	li	s4,-1
    80004b6c:	b7d5                	j	80004b50 <filewrite+0xfa>
    panic("filewrite");
    80004b6e:	00004517          	auipc	a0,0x4
    80004b72:	b6a50513          	addi	a0,a0,-1174 # 800086d8 <syscalls+0x288>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	9ca080e7          	jalr	-1590(ra) # 80000540 <panic>
    return -1;
    80004b7e:	5a7d                	li	s4,-1
    80004b80:	bfc1                	j	80004b50 <filewrite+0xfa>
      return -1;
    80004b82:	5a7d                	li	s4,-1
    80004b84:	b7f1                	j	80004b50 <filewrite+0xfa>
    80004b86:	5a7d                	li	s4,-1
    80004b88:	b7e1                	j	80004b50 <filewrite+0xfa>

0000000080004b8a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b8a:	7179                	addi	sp,sp,-48
    80004b8c:	f406                	sd	ra,40(sp)
    80004b8e:	f022                	sd	s0,32(sp)
    80004b90:	ec26                	sd	s1,24(sp)
    80004b92:	e84a                	sd	s2,16(sp)
    80004b94:	e44e                	sd	s3,8(sp)
    80004b96:	e052                	sd	s4,0(sp)
    80004b98:	1800                	addi	s0,sp,48
    80004b9a:	84aa                	mv	s1,a0
    80004b9c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b9e:	0005b023          	sd	zero,0(a1)
    80004ba2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ba6:	00000097          	auipc	ra,0x0
    80004baa:	bf8080e7          	jalr	-1032(ra) # 8000479e <filealloc>
    80004bae:	e088                	sd	a0,0(s1)
    80004bb0:	c551                	beqz	a0,80004c3c <pipealloc+0xb2>
    80004bb2:	00000097          	auipc	ra,0x0
    80004bb6:	bec080e7          	jalr	-1044(ra) # 8000479e <filealloc>
    80004bba:	00aa3023          	sd	a0,0(s4)
    80004bbe:	c92d                	beqz	a0,80004c30 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	f26080e7          	jalr	-218(ra) # 80000ae6 <kalloc>
    80004bc8:	892a                	mv	s2,a0
    80004bca:	c125                	beqz	a0,80004c2a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bcc:	4985                	li	s3,1
    80004bce:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bd2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bd6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bda:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bde:	00004597          	auipc	a1,0x4
    80004be2:	b0a58593          	addi	a1,a1,-1270 # 800086e8 <syscalls+0x298>
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	f60080e7          	jalr	-160(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004bee:	609c                	ld	a5,0(s1)
    80004bf0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bf4:	609c                	ld	a5,0(s1)
    80004bf6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bfa:	609c                	ld	a5,0(s1)
    80004bfc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c00:	609c                	ld	a5,0(s1)
    80004c02:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c06:	000a3783          	ld	a5,0(s4)
    80004c0a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c0e:	000a3783          	ld	a5,0(s4)
    80004c12:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c16:	000a3783          	ld	a5,0(s4)
    80004c1a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c1e:	000a3783          	ld	a5,0(s4)
    80004c22:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c26:	4501                	li	a0,0
    80004c28:	a025                	j	80004c50 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c2a:	6088                	ld	a0,0(s1)
    80004c2c:	e501                	bnez	a0,80004c34 <pipealloc+0xaa>
    80004c2e:	a039                	j	80004c3c <pipealloc+0xb2>
    80004c30:	6088                	ld	a0,0(s1)
    80004c32:	c51d                	beqz	a0,80004c60 <pipealloc+0xd6>
    fileclose(*f0);
    80004c34:	00000097          	auipc	ra,0x0
    80004c38:	c26080e7          	jalr	-986(ra) # 8000485a <fileclose>
  if(*f1)
    80004c3c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c40:	557d                	li	a0,-1
  if(*f1)
    80004c42:	c799                	beqz	a5,80004c50 <pipealloc+0xc6>
    fileclose(*f1);
    80004c44:	853e                	mv	a0,a5
    80004c46:	00000097          	auipc	ra,0x0
    80004c4a:	c14080e7          	jalr	-1004(ra) # 8000485a <fileclose>
  return -1;
    80004c4e:	557d                	li	a0,-1
}
    80004c50:	70a2                	ld	ra,40(sp)
    80004c52:	7402                	ld	s0,32(sp)
    80004c54:	64e2                	ld	s1,24(sp)
    80004c56:	6942                	ld	s2,16(sp)
    80004c58:	69a2                	ld	s3,8(sp)
    80004c5a:	6a02                	ld	s4,0(sp)
    80004c5c:	6145                	addi	sp,sp,48
    80004c5e:	8082                	ret
  return -1;
    80004c60:	557d                	li	a0,-1
    80004c62:	b7fd                	j	80004c50 <pipealloc+0xc6>

0000000080004c64 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c64:	1101                	addi	sp,sp,-32
    80004c66:	ec06                	sd	ra,24(sp)
    80004c68:	e822                	sd	s0,16(sp)
    80004c6a:	e426                	sd	s1,8(sp)
    80004c6c:	e04a                	sd	s2,0(sp)
    80004c6e:	1000                	addi	s0,sp,32
    80004c70:	84aa                	mv	s1,a0
    80004c72:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	f62080e7          	jalr	-158(ra) # 80000bd6 <acquire>
  if(writable){
    80004c7c:	02090d63          	beqz	s2,80004cb6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c80:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c84:	21848513          	addi	a0,s1,536
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	444080e7          	jalr	1092(ra) # 800020cc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c90:	2204b783          	ld	a5,544(s1)
    80004c94:	eb95                	bnez	a5,80004cc8 <pipeclose+0x64>
    release(&pi->lock);
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	d46080e7          	jalr	-698(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004caa:	60e2                	ld	ra,24(sp)
    80004cac:	6442                	ld	s0,16(sp)
    80004cae:	64a2                	ld	s1,8(sp)
    80004cb0:	6902                	ld	s2,0(sp)
    80004cb2:	6105                	addi	sp,sp,32
    80004cb4:	8082                	ret
    pi->readopen = 0;
    80004cb6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cba:	21c48513          	addi	a0,s1,540
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	40e080e7          	jalr	1038(ra) # 800020cc <wakeup>
    80004cc6:	b7e9                	j	80004c90 <pipeclose+0x2c>
    release(&pi->lock);
    80004cc8:	8526                	mv	a0,s1
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	fc0080e7          	jalr	-64(ra) # 80000c8a <release>
}
    80004cd2:	bfe1                	j	80004caa <pipeclose+0x46>

0000000080004cd4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cd4:	711d                	addi	sp,sp,-96
    80004cd6:	ec86                	sd	ra,88(sp)
    80004cd8:	e8a2                	sd	s0,80(sp)
    80004cda:	e4a6                	sd	s1,72(sp)
    80004cdc:	e0ca                	sd	s2,64(sp)
    80004cde:	fc4e                	sd	s3,56(sp)
    80004ce0:	f852                	sd	s4,48(sp)
    80004ce2:	f456                	sd	s5,40(sp)
    80004ce4:	f05a                	sd	s6,32(sp)
    80004ce6:	ec5e                	sd	s7,24(sp)
    80004ce8:	e862                	sd	s8,16(sp)
    80004cea:	1080                	addi	s0,sp,96
    80004cec:	84aa                	mv	s1,a0
    80004cee:	8aae                	mv	s5,a1
    80004cf0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	cba080e7          	jalr	-838(ra) # 800019ac <myproc>
    80004cfa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	ed8080e7          	jalr	-296(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d06:	0b405663          	blez	s4,80004db2 <pipewrite+0xde>
  int i = 0;
    80004d0a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d0c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d0e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d12:	21c48b93          	addi	s7,s1,540
    80004d16:	a089                	j	80004d58 <pipewrite+0x84>
      release(&pi->lock);
    80004d18:	8526                	mv	a0,s1
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	f70080e7          	jalr	-144(ra) # 80000c8a <release>
      return -1;
    80004d22:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d24:	854a                	mv	a0,s2
    80004d26:	60e6                	ld	ra,88(sp)
    80004d28:	6446                	ld	s0,80(sp)
    80004d2a:	64a6                	ld	s1,72(sp)
    80004d2c:	6906                	ld	s2,64(sp)
    80004d2e:	79e2                	ld	s3,56(sp)
    80004d30:	7a42                	ld	s4,48(sp)
    80004d32:	7aa2                	ld	s5,40(sp)
    80004d34:	7b02                	ld	s6,32(sp)
    80004d36:	6be2                	ld	s7,24(sp)
    80004d38:	6c42                	ld	s8,16(sp)
    80004d3a:	6125                	addi	sp,sp,96
    80004d3c:	8082                	ret
      wakeup(&pi->nread);
    80004d3e:	8562                	mv	a0,s8
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	38c080e7          	jalr	908(ra) # 800020cc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d48:	85a6                	mv	a1,s1
    80004d4a:	855e                	mv	a0,s7
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	31c080e7          	jalr	796(ra) # 80002068 <sleep>
  while(i < n){
    80004d54:	07495063          	bge	s2,s4,80004db4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d58:	2204a783          	lw	a5,544(s1)
    80004d5c:	dfd5                	beqz	a5,80004d18 <pipewrite+0x44>
    80004d5e:	854e                	mv	a0,s3
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	5bc080e7          	jalr	1468(ra) # 8000231c <killed>
    80004d68:	f945                	bnez	a0,80004d18 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d6a:	2184a783          	lw	a5,536(s1)
    80004d6e:	21c4a703          	lw	a4,540(s1)
    80004d72:	2007879b          	addiw	a5,a5,512
    80004d76:	fcf704e3          	beq	a4,a5,80004d3e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d7a:	4685                	li	a3,1
    80004d7c:	01590633          	add	a2,s2,s5
    80004d80:	faf40593          	addi	a1,s0,-81
    80004d84:	0509b503          	ld	a0,80(s3)
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	970080e7          	jalr	-1680(ra) # 800016f8 <copyin>
    80004d90:	03650263          	beq	a0,s6,80004db4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d94:	21c4a783          	lw	a5,540(s1)
    80004d98:	0017871b          	addiw	a4,a5,1
    80004d9c:	20e4ae23          	sw	a4,540(s1)
    80004da0:	1ff7f793          	andi	a5,a5,511
    80004da4:	97a6                	add	a5,a5,s1
    80004da6:	faf44703          	lbu	a4,-81(s0)
    80004daa:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dae:	2905                	addiw	s2,s2,1
    80004db0:	b755                	j	80004d54 <pipewrite+0x80>
  int i = 0;
    80004db2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004db4:	21848513          	addi	a0,s1,536
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	314080e7          	jalr	788(ra) # 800020cc <wakeup>
  release(&pi->lock);
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	ec8080e7          	jalr	-312(ra) # 80000c8a <release>
  return i;
    80004dca:	bfa9                	j	80004d24 <pipewrite+0x50>

0000000080004dcc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dcc:	715d                	addi	sp,sp,-80
    80004dce:	e486                	sd	ra,72(sp)
    80004dd0:	e0a2                	sd	s0,64(sp)
    80004dd2:	fc26                	sd	s1,56(sp)
    80004dd4:	f84a                	sd	s2,48(sp)
    80004dd6:	f44e                	sd	s3,40(sp)
    80004dd8:	f052                	sd	s4,32(sp)
    80004dda:	ec56                	sd	s5,24(sp)
    80004ddc:	e85a                	sd	s6,16(sp)
    80004dde:	0880                	addi	s0,sp,80
    80004de0:	84aa                	mv	s1,a0
    80004de2:	892e                	mv	s2,a1
    80004de4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	bc6080e7          	jalr	-1082(ra) # 800019ac <myproc>
    80004dee:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004df0:	8526                	mv	a0,s1
    80004df2:	ffffc097          	auipc	ra,0xffffc
    80004df6:	de4080e7          	jalr	-540(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dfa:	2184a703          	lw	a4,536(s1)
    80004dfe:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e02:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e06:	02f71763          	bne	a4,a5,80004e34 <piperead+0x68>
    80004e0a:	2244a783          	lw	a5,548(s1)
    80004e0e:	c39d                	beqz	a5,80004e34 <piperead+0x68>
    if(killed(pr)){
    80004e10:	8552                	mv	a0,s4
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	50a080e7          	jalr	1290(ra) # 8000231c <killed>
    80004e1a:	e949                	bnez	a0,80004eac <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e1c:	85a6                	mv	a1,s1
    80004e1e:	854e                	mv	a0,s3
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	248080e7          	jalr	584(ra) # 80002068 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e28:	2184a703          	lw	a4,536(s1)
    80004e2c:	21c4a783          	lw	a5,540(s1)
    80004e30:	fcf70de3          	beq	a4,a5,80004e0a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e34:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e36:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e38:	05505463          	blez	s5,80004e80 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e3c:	2184a783          	lw	a5,536(s1)
    80004e40:	21c4a703          	lw	a4,540(s1)
    80004e44:	02f70e63          	beq	a4,a5,80004e80 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e48:	0017871b          	addiw	a4,a5,1
    80004e4c:	20e4ac23          	sw	a4,536(s1)
    80004e50:	1ff7f793          	andi	a5,a5,511
    80004e54:	97a6                	add	a5,a5,s1
    80004e56:	0187c783          	lbu	a5,24(a5)
    80004e5a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e5e:	4685                	li	a3,1
    80004e60:	fbf40613          	addi	a2,s0,-65
    80004e64:	85ca                	mv	a1,s2
    80004e66:	050a3503          	ld	a0,80(s4)
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	802080e7          	jalr	-2046(ra) # 8000166c <copyout>
    80004e72:	01650763          	beq	a0,s6,80004e80 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e76:	2985                	addiw	s3,s3,1
    80004e78:	0905                	addi	s2,s2,1
    80004e7a:	fd3a91e3          	bne	s5,s3,80004e3c <piperead+0x70>
    80004e7e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e80:	21c48513          	addi	a0,s1,540
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	248080e7          	jalr	584(ra) # 800020cc <wakeup>
  release(&pi->lock);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	dfc080e7          	jalr	-516(ra) # 80000c8a <release>
  return i;
}
    80004e96:	854e                	mv	a0,s3
    80004e98:	60a6                	ld	ra,72(sp)
    80004e9a:	6406                	ld	s0,64(sp)
    80004e9c:	74e2                	ld	s1,56(sp)
    80004e9e:	7942                	ld	s2,48(sp)
    80004ea0:	79a2                	ld	s3,40(sp)
    80004ea2:	7a02                	ld	s4,32(sp)
    80004ea4:	6ae2                	ld	s5,24(sp)
    80004ea6:	6b42                	ld	s6,16(sp)
    80004ea8:	6161                	addi	sp,sp,80
    80004eaa:	8082                	ret
      release(&pi->lock);
    80004eac:	8526                	mv	a0,s1
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	ddc080e7          	jalr	-548(ra) # 80000c8a <release>
      return -1;
    80004eb6:	59fd                	li	s3,-1
    80004eb8:	bff9                	j	80004e96 <piperead+0xca>

0000000080004eba <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004eba:	1141                	addi	sp,sp,-16
    80004ebc:	e422                	sd	s0,8(sp)
    80004ebe:	0800                	addi	s0,sp,16
    80004ec0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ec2:	8905                	andi	a0,a0,1
    80004ec4:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ec6:	8b89                	andi	a5,a5,2
    80004ec8:	c399                	beqz	a5,80004ece <flags2perm+0x14>
      perm |= PTE_W;
    80004eca:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ece:	6422                	ld	s0,8(sp)
    80004ed0:	0141                	addi	sp,sp,16
    80004ed2:	8082                	ret

0000000080004ed4 <exec>:

int
exec(char *path, char **argv)
{
    80004ed4:	de010113          	addi	sp,sp,-544
    80004ed8:	20113c23          	sd	ra,536(sp)
    80004edc:	20813823          	sd	s0,528(sp)
    80004ee0:	20913423          	sd	s1,520(sp)
    80004ee4:	21213023          	sd	s2,512(sp)
    80004ee8:	ffce                	sd	s3,504(sp)
    80004eea:	fbd2                	sd	s4,496(sp)
    80004eec:	f7d6                	sd	s5,488(sp)
    80004eee:	f3da                	sd	s6,480(sp)
    80004ef0:	efde                	sd	s7,472(sp)
    80004ef2:	ebe2                	sd	s8,464(sp)
    80004ef4:	e7e6                	sd	s9,456(sp)
    80004ef6:	e3ea                	sd	s10,448(sp)
    80004ef8:	ff6e                	sd	s11,440(sp)
    80004efa:	1400                	addi	s0,sp,544
    80004efc:	892a                	mv	s2,a0
    80004efe:	dea43423          	sd	a0,-536(s0)
    80004f02:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	aa6080e7          	jalr	-1370(ra) # 800019ac <myproc>
    80004f0e:	84aa                	mv	s1,a0

  begin_op();
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	482080e7          	jalr	1154(ra) # 80004392 <begin_op>

  if((ip = namei(path)) == 0){
    80004f18:	854a                	mv	a0,s2
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	258080e7          	jalr	600(ra) # 80004172 <namei>
    80004f22:	c93d                	beqz	a0,80004f98 <exec+0xc4>
    80004f24:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f26:	fffff097          	auipc	ra,0xfffff
    80004f2a:	aa0080e7          	jalr	-1376(ra) # 800039c6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f2e:	04000713          	li	a4,64
    80004f32:	4681                	li	a3,0
    80004f34:	e5040613          	addi	a2,s0,-432
    80004f38:	4581                	li	a1,0
    80004f3a:	8556                	mv	a0,s5
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	d3e080e7          	jalr	-706(ra) # 80003c7a <readi>
    80004f44:	04000793          	li	a5,64
    80004f48:	00f51a63          	bne	a0,a5,80004f5c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f4c:	e5042703          	lw	a4,-432(s0)
    80004f50:	464c47b7          	lui	a5,0x464c4
    80004f54:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f58:	04f70663          	beq	a4,a5,80004fa4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f5c:	8556                	mv	a0,s5
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	cca080e7          	jalr	-822(ra) # 80003c28 <iunlockput>
    end_op();
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	4aa080e7          	jalr	1194(ra) # 80004410 <end_op>
  }
  return -1;
    80004f6e:	557d                	li	a0,-1
}
    80004f70:	21813083          	ld	ra,536(sp)
    80004f74:	21013403          	ld	s0,528(sp)
    80004f78:	20813483          	ld	s1,520(sp)
    80004f7c:	20013903          	ld	s2,512(sp)
    80004f80:	79fe                	ld	s3,504(sp)
    80004f82:	7a5e                	ld	s4,496(sp)
    80004f84:	7abe                	ld	s5,488(sp)
    80004f86:	7b1e                	ld	s6,480(sp)
    80004f88:	6bfe                	ld	s7,472(sp)
    80004f8a:	6c5e                	ld	s8,464(sp)
    80004f8c:	6cbe                	ld	s9,456(sp)
    80004f8e:	6d1e                	ld	s10,448(sp)
    80004f90:	7dfa                	ld	s11,440(sp)
    80004f92:	22010113          	addi	sp,sp,544
    80004f96:	8082                	ret
    end_op();
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	478080e7          	jalr	1144(ra) # 80004410 <end_op>
    return -1;
    80004fa0:	557d                	li	a0,-1
    80004fa2:	b7f9                	j	80004f70 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fa4:	8526                	mv	a0,s1
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	aca080e7          	jalr	-1334(ra) # 80001a70 <proc_pagetable>
    80004fae:	8b2a                	mv	s6,a0
    80004fb0:	d555                	beqz	a0,80004f5c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb2:	e7042783          	lw	a5,-400(s0)
    80004fb6:	e8845703          	lhu	a4,-376(s0)
    80004fba:	c735                	beqz	a4,80005026 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fbc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fbe:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fc2:	6a05                	lui	s4,0x1
    80004fc4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004fc8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004fcc:	6d85                	lui	s11,0x1
    80004fce:	7d7d                	lui	s10,0xfffff
    80004fd0:	ac3d                	j	8000520e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fd2:	00003517          	auipc	a0,0x3
    80004fd6:	71e50513          	addi	a0,a0,1822 # 800086f0 <syscalls+0x2a0>
    80004fda:	ffffb097          	auipc	ra,0xffffb
    80004fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fe2:	874a                	mv	a4,s2
    80004fe4:	009c86bb          	addw	a3,s9,s1
    80004fe8:	4581                	li	a1,0
    80004fea:	8556                	mv	a0,s5
    80004fec:	fffff097          	auipc	ra,0xfffff
    80004ff0:	c8e080e7          	jalr	-882(ra) # 80003c7a <readi>
    80004ff4:	2501                	sext.w	a0,a0
    80004ff6:	1aa91963          	bne	s2,a0,800051a8 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004ffa:	009d84bb          	addw	s1,s11,s1
    80004ffe:	013d09bb          	addw	s3,s10,s3
    80005002:	1f74f663          	bgeu	s1,s7,800051ee <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005006:	02049593          	slli	a1,s1,0x20
    8000500a:	9181                	srli	a1,a1,0x20
    8000500c:	95e2                	add	a1,a1,s8
    8000500e:	855a                	mv	a0,s6
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	04c080e7          	jalr	76(ra) # 8000105c <walkaddr>
    80005018:	862a                	mv	a2,a0
    if(pa == 0)
    8000501a:	dd45                	beqz	a0,80004fd2 <exec+0xfe>
      n = PGSIZE;
    8000501c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000501e:	fd49f2e3          	bgeu	s3,s4,80004fe2 <exec+0x10e>
      n = sz - i;
    80005022:	894e                	mv	s2,s3
    80005024:	bf7d                	j	80004fe2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005026:	4901                	li	s2,0
  iunlockput(ip);
    80005028:	8556                	mv	a0,s5
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	bfe080e7          	jalr	-1026(ra) # 80003c28 <iunlockput>
  end_op();
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	3de080e7          	jalr	990(ra) # 80004410 <end_op>
  p = myproc();
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	972080e7          	jalr	-1678(ra) # 800019ac <myproc>
    80005042:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005044:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005048:	6785                	lui	a5,0x1
    8000504a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000504c:	97ca                	add	a5,a5,s2
    8000504e:	777d                	lui	a4,0xfffff
    80005050:	8ff9                	and	a5,a5,a4
    80005052:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005056:	4691                	li	a3,4
    80005058:	6609                	lui	a2,0x2
    8000505a:	963e                	add	a2,a2,a5
    8000505c:	85be                	mv	a1,a5
    8000505e:	855a                	mv	a0,s6
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	3b0080e7          	jalr	944(ra) # 80001410 <uvmalloc>
    80005068:	8c2a                	mv	s8,a0
  ip = 0;
    8000506a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000506c:	12050e63          	beqz	a0,800051a8 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005070:	75f9                	lui	a1,0xffffe
    80005072:	95aa                	add	a1,a1,a0
    80005074:	855a                	mv	a0,s6
    80005076:	ffffc097          	auipc	ra,0xffffc
    8000507a:	5c4080e7          	jalr	1476(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    8000507e:	7afd                	lui	s5,0xfffff
    80005080:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005082:	df043783          	ld	a5,-528(s0)
    80005086:	6388                	ld	a0,0(a5)
    80005088:	c925                	beqz	a0,800050f8 <exec+0x224>
    8000508a:	e9040993          	addi	s3,s0,-368
    8000508e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005092:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005094:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	db8080e7          	jalr	-584(ra) # 80000e4e <strlen>
    8000509e:	0015079b          	addiw	a5,a0,1
    800050a2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050a6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800050aa:	13596663          	bltu	s2,s5,800051d6 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050ae:	df043d83          	ld	s11,-528(s0)
    800050b2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050b6:	8552                	mv	a0,s4
    800050b8:	ffffc097          	auipc	ra,0xffffc
    800050bc:	d96080e7          	jalr	-618(ra) # 80000e4e <strlen>
    800050c0:	0015069b          	addiw	a3,a0,1
    800050c4:	8652                	mv	a2,s4
    800050c6:	85ca                	mv	a1,s2
    800050c8:	855a                	mv	a0,s6
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	5a2080e7          	jalr	1442(ra) # 8000166c <copyout>
    800050d2:	10054663          	bltz	a0,800051de <exec+0x30a>
    ustack[argc] = sp;
    800050d6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050da:	0485                	addi	s1,s1,1
    800050dc:	008d8793          	addi	a5,s11,8
    800050e0:	def43823          	sd	a5,-528(s0)
    800050e4:	008db503          	ld	a0,8(s11)
    800050e8:	c911                	beqz	a0,800050fc <exec+0x228>
    if(argc >= MAXARG)
    800050ea:	09a1                	addi	s3,s3,8
    800050ec:	fb3c95e3          	bne	s9,s3,80005096 <exec+0x1c2>
  sz = sz1;
    800050f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050f4:	4a81                	li	s5,0
    800050f6:	a84d                	j	800051a8 <exec+0x2d4>
  sp = sz;
    800050f8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050fa:	4481                	li	s1,0
  ustack[argc] = 0;
    800050fc:	00349793          	slli	a5,s1,0x3
    80005100:	f9078793          	addi	a5,a5,-112
    80005104:	97a2                	add	a5,a5,s0
    80005106:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000510a:	00148693          	addi	a3,s1,1
    8000510e:	068e                	slli	a3,a3,0x3
    80005110:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005114:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005118:	01597663          	bgeu	s2,s5,80005124 <exec+0x250>
  sz = sz1;
    8000511c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005120:	4a81                	li	s5,0
    80005122:	a059                	j	800051a8 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005124:	e9040613          	addi	a2,s0,-368
    80005128:	85ca                	mv	a1,s2
    8000512a:	855a                	mv	a0,s6
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	540080e7          	jalr	1344(ra) # 8000166c <copyout>
    80005134:	0a054963          	bltz	a0,800051e6 <exec+0x312>
  p->trapframe->a1 = sp;
    80005138:	058bb783          	ld	a5,88(s7)
    8000513c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005140:	de843783          	ld	a5,-536(s0)
    80005144:	0007c703          	lbu	a4,0(a5)
    80005148:	cf11                	beqz	a4,80005164 <exec+0x290>
    8000514a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000514c:	02f00693          	li	a3,47
    80005150:	a039                	j	8000515e <exec+0x28a>
      last = s+1;
    80005152:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005156:	0785                	addi	a5,a5,1
    80005158:	fff7c703          	lbu	a4,-1(a5)
    8000515c:	c701                	beqz	a4,80005164 <exec+0x290>
    if(*s == '/')
    8000515e:	fed71ce3          	bne	a4,a3,80005156 <exec+0x282>
    80005162:	bfc5                	j	80005152 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005164:	4641                	li	a2,16
    80005166:	de843583          	ld	a1,-536(s0)
    8000516a:	158b8513          	addi	a0,s7,344
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	cae080e7          	jalr	-850(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005176:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000517a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000517e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005182:	058bb783          	ld	a5,88(s7)
    80005186:	e6843703          	ld	a4,-408(s0)
    8000518a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000518c:	058bb783          	ld	a5,88(s7)
    80005190:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005194:	85ea                	mv	a1,s10
    80005196:	ffffd097          	auipc	ra,0xffffd
    8000519a:	976080e7          	jalr	-1674(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000519e:	0004851b          	sext.w	a0,s1
    800051a2:	b3f9                	j	80004f70 <exec+0x9c>
    800051a4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051a8:	df843583          	ld	a1,-520(s0)
    800051ac:	855a                	mv	a0,s6
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	95e080e7          	jalr	-1698(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800051b6:	da0a93e3          	bnez	s5,80004f5c <exec+0x88>
  return -1;
    800051ba:	557d                	li	a0,-1
    800051bc:	bb55                	j	80004f70 <exec+0x9c>
    800051be:	df243c23          	sd	s2,-520(s0)
    800051c2:	b7dd                	j	800051a8 <exec+0x2d4>
    800051c4:	df243c23          	sd	s2,-520(s0)
    800051c8:	b7c5                	j	800051a8 <exec+0x2d4>
    800051ca:	df243c23          	sd	s2,-520(s0)
    800051ce:	bfe9                	j	800051a8 <exec+0x2d4>
    800051d0:	df243c23          	sd	s2,-520(s0)
    800051d4:	bfd1                	j	800051a8 <exec+0x2d4>
  sz = sz1;
    800051d6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051da:	4a81                	li	s5,0
    800051dc:	b7f1                	j	800051a8 <exec+0x2d4>
  sz = sz1;
    800051de:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051e2:	4a81                	li	s5,0
    800051e4:	b7d1                	j	800051a8 <exec+0x2d4>
  sz = sz1;
    800051e6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ea:	4a81                	li	s5,0
    800051ec:	bf75                	j	800051a8 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051ee:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051f2:	e0843783          	ld	a5,-504(s0)
    800051f6:	0017869b          	addiw	a3,a5,1
    800051fa:	e0d43423          	sd	a3,-504(s0)
    800051fe:	e0043783          	ld	a5,-512(s0)
    80005202:	0387879b          	addiw	a5,a5,56
    80005206:	e8845703          	lhu	a4,-376(s0)
    8000520a:	e0e6dfe3          	bge	a3,a4,80005028 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000520e:	2781                	sext.w	a5,a5
    80005210:	e0f43023          	sd	a5,-512(s0)
    80005214:	03800713          	li	a4,56
    80005218:	86be                	mv	a3,a5
    8000521a:	e1840613          	addi	a2,s0,-488
    8000521e:	4581                	li	a1,0
    80005220:	8556                	mv	a0,s5
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	a58080e7          	jalr	-1448(ra) # 80003c7a <readi>
    8000522a:	03800793          	li	a5,56
    8000522e:	f6f51be3          	bne	a0,a5,800051a4 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005232:	e1842783          	lw	a5,-488(s0)
    80005236:	4705                	li	a4,1
    80005238:	fae79de3          	bne	a5,a4,800051f2 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000523c:	e4043483          	ld	s1,-448(s0)
    80005240:	e3843783          	ld	a5,-456(s0)
    80005244:	f6f4ede3          	bltu	s1,a5,800051be <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005248:	e2843783          	ld	a5,-472(s0)
    8000524c:	94be                	add	s1,s1,a5
    8000524e:	f6f4ebe3          	bltu	s1,a5,800051c4 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005252:	de043703          	ld	a4,-544(s0)
    80005256:	8ff9                	and	a5,a5,a4
    80005258:	fbad                	bnez	a5,800051ca <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000525a:	e1c42503          	lw	a0,-484(s0)
    8000525e:	00000097          	auipc	ra,0x0
    80005262:	c5c080e7          	jalr	-932(ra) # 80004eba <flags2perm>
    80005266:	86aa                	mv	a3,a0
    80005268:	8626                	mv	a2,s1
    8000526a:	85ca                	mv	a1,s2
    8000526c:	855a                	mv	a0,s6
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	1a2080e7          	jalr	418(ra) # 80001410 <uvmalloc>
    80005276:	dea43c23          	sd	a0,-520(s0)
    8000527a:	d939                	beqz	a0,800051d0 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000527c:	e2843c03          	ld	s8,-472(s0)
    80005280:	e2042c83          	lw	s9,-480(s0)
    80005284:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005288:	f60b83e3          	beqz	s7,800051ee <exec+0x31a>
    8000528c:	89de                	mv	s3,s7
    8000528e:	4481                	li	s1,0
    80005290:	bb9d                	j	80005006 <exec+0x132>

0000000080005292 <argfd>:
uint64 myreadcount=0;
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005292:	7179                	addi	sp,sp,-48
    80005294:	f406                	sd	ra,40(sp)
    80005296:	f022                	sd	s0,32(sp)
    80005298:	ec26                	sd	s1,24(sp)
    8000529a:	e84a                	sd	s2,16(sp)
    8000529c:	1800                	addi	s0,sp,48
    8000529e:	892e                	mv	s2,a1
    800052a0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052a2:	fdc40593          	addi	a1,s0,-36
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	a4c080e7          	jalr	-1460(ra) # 80002cf2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052ae:	fdc42703          	lw	a4,-36(s0)
    800052b2:	47bd                	li	a5,15
    800052b4:	02e7eb63          	bltu	a5,a4,800052ea <argfd+0x58>
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	6f4080e7          	jalr	1780(ra) # 800019ac <myproc>
    800052c0:	fdc42703          	lw	a4,-36(s0)
    800052c4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc69a>
    800052c8:	078e                	slli	a5,a5,0x3
    800052ca:	953e                	add	a0,a0,a5
    800052cc:	611c                	ld	a5,0(a0)
    800052ce:	c385                	beqz	a5,800052ee <argfd+0x5c>
    return -1;
  if(pfd)
    800052d0:	00090463          	beqz	s2,800052d8 <argfd+0x46>
    *pfd = fd;
    800052d4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052d8:	4501                	li	a0,0
  if(pf)
    800052da:	c091                	beqz	s1,800052de <argfd+0x4c>
    *pf = f;
    800052dc:	e09c                	sd	a5,0(s1)
}
    800052de:	70a2                	ld	ra,40(sp)
    800052e0:	7402                	ld	s0,32(sp)
    800052e2:	64e2                	ld	s1,24(sp)
    800052e4:	6942                	ld	s2,16(sp)
    800052e6:	6145                	addi	sp,sp,48
    800052e8:	8082                	ret
    return -1;
    800052ea:	557d                	li	a0,-1
    800052ec:	bfcd                	j	800052de <argfd+0x4c>
    800052ee:	557d                	li	a0,-1
    800052f0:	b7fd                	j	800052de <argfd+0x4c>

00000000800052f2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052f2:	1101                	addi	sp,sp,-32
    800052f4:	ec06                	sd	ra,24(sp)
    800052f6:	e822                	sd	s0,16(sp)
    800052f8:	e426                	sd	s1,8(sp)
    800052fa:	1000                	addi	s0,sp,32
    800052fc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	6ae080e7          	jalr	1710(ra) # 800019ac <myproc>
    80005306:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005308:	0d050793          	addi	a5,a0,208
    8000530c:	4501                	li	a0,0
    8000530e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005310:	6398                	ld	a4,0(a5)
    80005312:	cb19                	beqz	a4,80005328 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005314:	2505                	addiw	a0,a0,1
    80005316:	07a1                	addi	a5,a5,8
    80005318:	fed51ce3          	bne	a0,a3,80005310 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000531c:	557d                	li	a0,-1
}
    8000531e:	60e2                	ld	ra,24(sp)
    80005320:	6442                	ld	s0,16(sp)
    80005322:	64a2                	ld	s1,8(sp)
    80005324:	6105                	addi	sp,sp,32
    80005326:	8082                	ret
      p->ofile[fd] = f;
    80005328:	01a50793          	addi	a5,a0,26
    8000532c:	078e                	slli	a5,a5,0x3
    8000532e:	963e                	add	a2,a2,a5
    80005330:	e204                	sd	s1,0(a2)
      return fd;
    80005332:	b7f5                	j	8000531e <fdalloc+0x2c>

0000000080005334 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005334:	715d                	addi	sp,sp,-80
    80005336:	e486                	sd	ra,72(sp)
    80005338:	e0a2                	sd	s0,64(sp)
    8000533a:	fc26                	sd	s1,56(sp)
    8000533c:	f84a                	sd	s2,48(sp)
    8000533e:	f44e                	sd	s3,40(sp)
    80005340:	f052                	sd	s4,32(sp)
    80005342:	ec56                	sd	s5,24(sp)
    80005344:	e85a                	sd	s6,16(sp)
    80005346:	0880                	addi	s0,sp,80
    80005348:	8b2e                	mv	s6,a1
    8000534a:	89b2                	mv	s3,a2
    8000534c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000534e:	fb040593          	addi	a1,s0,-80
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	e3e080e7          	jalr	-450(ra) # 80004190 <nameiparent>
    8000535a:	84aa                	mv	s1,a0
    8000535c:	14050f63          	beqz	a0,800054ba <create+0x186>
    return 0;

  ilock(dp);
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	666080e7          	jalr	1638(ra) # 800039c6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005368:	4601                	li	a2,0
    8000536a:	fb040593          	addi	a1,s0,-80
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	b3a080e7          	jalr	-1222(ra) # 80003eaa <dirlookup>
    80005378:	8aaa                	mv	s5,a0
    8000537a:	c931                	beqz	a0,800053ce <create+0x9a>
    iunlockput(dp);
    8000537c:	8526                	mv	a0,s1
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	8aa080e7          	jalr	-1878(ra) # 80003c28 <iunlockput>
    ilock(ip);
    80005386:	8556                	mv	a0,s5
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	63e080e7          	jalr	1598(ra) # 800039c6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005390:	000b059b          	sext.w	a1,s6
    80005394:	4789                	li	a5,2
    80005396:	02f59563          	bne	a1,a5,800053c0 <create+0x8c>
    8000539a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc6c4>
    8000539e:	37f9                	addiw	a5,a5,-2
    800053a0:	17c2                	slli	a5,a5,0x30
    800053a2:	93c1                	srli	a5,a5,0x30
    800053a4:	4705                	li	a4,1
    800053a6:	00f76d63          	bltu	a4,a5,800053c0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053aa:	8556                	mv	a0,s5
    800053ac:	60a6                	ld	ra,72(sp)
    800053ae:	6406                	ld	s0,64(sp)
    800053b0:	74e2                	ld	s1,56(sp)
    800053b2:	7942                	ld	s2,48(sp)
    800053b4:	79a2                	ld	s3,40(sp)
    800053b6:	7a02                	ld	s4,32(sp)
    800053b8:	6ae2                	ld	s5,24(sp)
    800053ba:	6b42                	ld	s6,16(sp)
    800053bc:	6161                	addi	sp,sp,80
    800053be:	8082                	ret
    iunlockput(ip);
    800053c0:	8556                	mv	a0,s5
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	866080e7          	jalr	-1946(ra) # 80003c28 <iunlockput>
    return 0;
    800053ca:	4a81                	li	s5,0
    800053cc:	bff9                	j	800053aa <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053ce:	85da                	mv	a1,s6
    800053d0:	4088                	lw	a0,0(s1)
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	456080e7          	jalr	1110(ra) # 80003828 <ialloc>
    800053da:	8a2a                	mv	s4,a0
    800053dc:	c539                	beqz	a0,8000542a <create+0xf6>
  ilock(ip);
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	5e8080e7          	jalr	1512(ra) # 800039c6 <ilock>
  ip->major = major;
    800053e6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800053ea:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800053ee:	4905                	li	s2,1
    800053f0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800053f4:	8552                	mv	a0,s4
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	504080e7          	jalr	1284(ra) # 800038fa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053fe:	000b059b          	sext.w	a1,s6
    80005402:	03258b63          	beq	a1,s2,80005438 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005406:	004a2603          	lw	a2,4(s4)
    8000540a:	fb040593          	addi	a1,s0,-80
    8000540e:	8526                	mv	a0,s1
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	cb0080e7          	jalr	-848(ra) # 800040c0 <dirlink>
    80005418:	06054f63          	bltz	a0,80005496 <create+0x162>
  iunlockput(dp);
    8000541c:	8526                	mv	a0,s1
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	80a080e7          	jalr	-2038(ra) # 80003c28 <iunlockput>
  return ip;
    80005426:	8ad2                	mv	s5,s4
    80005428:	b749                	j	800053aa <create+0x76>
    iunlockput(dp);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	7fc080e7          	jalr	2044(ra) # 80003c28 <iunlockput>
    return 0;
    80005434:	8ad2                	mv	s5,s4
    80005436:	bf95                	j	800053aa <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005438:	004a2603          	lw	a2,4(s4)
    8000543c:	00003597          	auipc	a1,0x3
    80005440:	2d458593          	addi	a1,a1,724 # 80008710 <syscalls+0x2c0>
    80005444:	8552                	mv	a0,s4
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	c7a080e7          	jalr	-902(ra) # 800040c0 <dirlink>
    8000544e:	04054463          	bltz	a0,80005496 <create+0x162>
    80005452:	40d0                	lw	a2,4(s1)
    80005454:	00003597          	auipc	a1,0x3
    80005458:	2c458593          	addi	a1,a1,708 # 80008718 <syscalls+0x2c8>
    8000545c:	8552                	mv	a0,s4
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	c62080e7          	jalr	-926(ra) # 800040c0 <dirlink>
    80005466:	02054863          	bltz	a0,80005496 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000546a:	004a2603          	lw	a2,4(s4)
    8000546e:	fb040593          	addi	a1,s0,-80
    80005472:	8526                	mv	a0,s1
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	c4c080e7          	jalr	-948(ra) # 800040c0 <dirlink>
    8000547c:	00054d63          	bltz	a0,80005496 <create+0x162>
    dp->nlink++;  // for ".."
    80005480:	04a4d783          	lhu	a5,74(s1)
    80005484:	2785                	addiw	a5,a5,1
    80005486:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	46e080e7          	jalr	1134(ra) # 800038fa <iupdate>
    80005494:	b761                	j	8000541c <create+0xe8>
  ip->nlink = 0;
    80005496:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000549a:	8552                	mv	a0,s4
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	45e080e7          	jalr	1118(ra) # 800038fa <iupdate>
  iunlockput(ip);
    800054a4:	8552                	mv	a0,s4
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	782080e7          	jalr	1922(ra) # 80003c28 <iunlockput>
  iunlockput(dp);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	778080e7          	jalr	1912(ra) # 80003c28 <iunlockput>
  return 0;
    800054b8:	bdcd                	j	800053aa <create+0x76>
    return 0;
    800054ba:	8aaa                	mv	s5,a0
    800054bc:	b5fd                	j	800053aa <create+0x76>

00000000800054be <sys_dup>:
{
    800054be:	7179                	addi	sp,sp,-48
    800054c0:	f406                	sd	ra,40(sp)
    800054c2:	f022                	sd	s0,32(sp)
    800054c4:	ec26                	sd	s1,24(sp)
    800054c6:	e84a                	sd	s2,16(sp)
    800054c8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054ca:	fd840613          	addi	a2,s0,-40
    800054ce:	4581                	li	a1,0
    800054d0:	4501                	li	a0,0
    800054d2:	00000097          	auipc	ra,0x0
    800054d6:	dc0080e7          	jalr	-576(ra) # 80005292 <argfd>
    return -1;
    800054da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054dc:	02054363          	bltz	a0,80005502 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800054e0:	fd843903          	ld	s2,-40(s0)
    800054e4:	854a                	mv	a0,s2
    800054e6:	00000097          	auipc	ra,0x0
    800054ea:	e0c080e7          	jalr	-500(ra) # 800052f2 <fdalloc>
    800054ee:	84aa                	mv	s1,a0
    return -1;
    800054f0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054f2:	00054863          	bltz	a0,80005502 <sys_dup+0x44>
  filedup(f);
    800054f6:	854a                	mv	a0,s2
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	310080e7          	jalr	784(ra) # 80004808 <filedup>
  return fd;
    80005500:	87a6                	mv	a5,s1
}
    80005502:	853e                	mv	a0,a5
    80005504:	70a2                	ld	ra,40(sp)
    80005506:	7402                	ld	s0,32(sp)
    80005508:	64e2                	ld	s1,24(sp)
    8000550a:	6942                	ld	s2,16(sp)
    8000550c:	6145                	addi	sp,sp,48
    8000550e:	8082                	ret

0000000080005510 <sys_read>:
{
    80005510:	7179                	addi	sp,sp,-48
    80005512:	f406                	sd	ra,40(sp)
    80005514:	f022                	sd	s0,32(sp)
    80005516:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005518:	fd840593          	addi	a1,s0,-40
    8000551c:	4505                	li	a0,1
    8000551e:	ffffd097          	auipc	ra,0xffffd
    80005522:	7f4080e7          	jalr	2036(ra) # 80002d12 <argaddr>
  argint(2, &n);
    80005526:	fe440593          	addi	a1,s0,-28
    8000552a:	4509                	li	a0,2
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	7c6080e7          	jalr	1990(ra) # 80002cf2 <argint>
  myreadcount++;
    80005534:	00003717          	auipc	a4,0x3
    80005538:	3d470713          	addi	a4,a4,980 # 80008908 <myreadcount>
    8000553c:	631c                	ld	a5,0(a4)
    8000553e:	0785                	addi	a5,a5,1
    80005540:	e31c                	sd	a5,0(a4)
  if (argfd(0, 0, &f) < 0)
    80005542:	fe840613          	addi	a2,s0,-24
    80005546:	4581                	li	a1,0
    80005548:	4501                	li	a0,0
    8000554a:	00000097          	auipc	ra,0x0
    8000554e:	d48080e7          	jalr	-696(ra) # 80005292 <argfd>
    80005552:	87aa                	mv	a5,a0
    return -1;
    80005554:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0)
    80005556:	0007cc63          	bltz	a5,8000556e <sys_read+0x5e>
  return fileread(f, p, n);
    8000555a:	fe442603          	lw	a2,-28(s0)
    8000555e:	fd843583          	ld	a1,-40(s0)
    80005562:	fe843503          	ld	a0,-24(s0)
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	42e080e7          	jalr	1070(ra) # 80004994 <fileread>
}
    8000556e:	70a2                	ld	ra,40(sp)
    80005570:	7402                	ld	s0,32(sp)
    80005572:	6145                	addi	sp,sp,48
    80005574:	8082                	ret

0000000080005576 <sys_write>:
{
    80005576:	7179                	addi	sp,sp,-48
    80005578:	f406                	sd	ra,40(sp)
    8000557a:	f022                	sd	s0,32(sp)
    8000557c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000557e:	fd840593          	addi	a1,s0,-40
    80005582:	4505                	li	a0,1
    80005584:	ffffd097          	auipc	ra,0xffffd
    80005588:	78e080e7          	jalr	1934(ra) # 80002d12 <argaddr>
  argint(2, &n);
    8000558c:	fe440593          	addi	a1,s0,-28
    80005590:	4509                	li	a0,2
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	760080e7          	jalr	1888(ra) # 80002cf2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000559a:	fe840613          	addi	a2,s0,-24
    8000559e:	4581                	li	a1,0
    800055a0:	4501                	li	a0,0
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	cf0080e7          	jalr	-784(ra) # 80005292 <argfd>
    800055aa:	87aa                	mv	a5,a0
    return -1;
    800055ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ae:	0007cc63          	bltz	a5,800055c6 <sys_write+0x50>
  return filewrite(f, p, n);
    800055b2:	fe442603          	lw	a2,-28(s0)
    800055b6:	fd843583          	ld	a1,-40(s0)
    800055ba:	fe843503          	ld	a0,-24(s0)
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	498080e7          	jalr	1176(ra) # 80004a56 <filewrite>
}
    800055c6:	70a2                	ld	ra,40(sp)
    800055c8:	7402                	ld	s0,32(sp)
    800055ca:	6145                	addi	sp,sp,48
    800055cc:	8082                	ret

00000000800055ce <sys_close>:
{
    800055ce:	1101                	addi	sp,sp,-32
    800055d0:	ec06                	sd	ra,24(sp)
    800055d2:	e822                	sd	s0,16(sp)
    800055d4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055d6:	fe040613          	addi	a2,s0,-32
    800055da:	fec40593          	addi	a1,s0,-20
    800055de:	4501                	li	a0,0
    800055e0:	00000097          	auipc	ra,0x0
    800055e4:	cb2080e7          	jalr	-846(ra) # 80005292 <argfd>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055ea:	02054463          	bltz	a0,80005612 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055ee:	ffffc097          	auipc	ra,0xffffc
    800055f2:	3be080e7          	jalr	958(ra) # 800019ac <myproc>
    800055f6:	fec42783          	lw	a5,-20(s0)
    800055fa:	07e9                	addi	a5,a5,26
    800055fc:	078e                	slli	a5,a5,0x3
    800055fe:	953e                	add	a0,a0,a5
    80005600:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005604:	fe043503          	ld	a0,-32(s0)
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	252080e7          	jalr	594(ra) # 8000485a <fileclose>
  return 0;
    80005610:	4781                	li	a5,0
}
    80005612:	853e                	mv	a0,a5
    80005614:	60e2                	ld	ra,24(sp)
    80005616:	6442                	ld	s0,16(sp)
    80005618:	6105                	addi	sp,sp,32
    8000561a:	8082                	ret

000000008000561c <sys_fstat>:
{
    8000561c:	1101                	addi	sp,sp,-32
    8000561e:	ec06                	sd	ra,24(sp)
    80005620:	e822                	sd	s0,16(sp)
    80005622:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005624:	fe040593          	addi	a1,s0,-32
    80005628:	4505                	li	a0,1
    8000562a:	ffffd097          	auipc	ra,0xffffd
    8000562e:	6e8080e7          	jalr	1768(ra) # 80002d12 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005632:	fe840613          	addi	a2,s0,-24
    80005636:	4581                	li	a1,0
    80005638:	4501                	li	a0,0
    8000563a:	00000097          	auipc	ra,0x0
    8000563e:	c58080e7          	jalr	-936(ra) # 80005292 <argfd>
    80005642:	87aa                	mv	a5,a0
    return -1;
    80005644:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005646:	0007ca63          	bltz	a5,8000565a <sys_fstat+0x3e>
  return filestat(f, st);
    8000564a:	fe043583          	ld	a1,-32(s0)
    8000564e:	fe843503          	ld	a0,-24(s0)
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	2d0080e7          	jalr	720(ra) # 80004922 <filestat>
}
    8000565a:	60e2                	ld	ra,24(sp)
    8000565c:	6442                	ld	s0,16(sp)
    8000565e:	6105                	addi	sp,sp,32
    80005660:	8082                	ret

0000000080005662 <sys_link>:
{
    80005662:	7169                	addi	sp,sp,-304
    80005664:	f606                	sd	ra,296(sp)
    80005666:	f222                	sd	s0,288(sp)
    80005668:	ee26                	sd	s1,280(sp)
    8000566a:	ea4a                	sd	s2,272(sp)
    8000566c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000566e:	08000613          	li	a2,128
    80005672:	ed040593          	addi	a1,s0,-304
    80005676:	4501                	li	a0,0
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	6ba080e7          	jalr	1722(ra) # 80002d32 <argstr>
    return -1;
    80005680:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005682:	10054e63          	bltz	a0,8000579e <sys_link+0x13c>
    80005686:	08000613          	li	a2,128
    8000568a:	f5040593          	addi	a1,s0,-176
    8000568e:	4505                	li	a0,1
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	6a2080e7          	jalr	1698(ra) # 80002d32 <argstr>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569a:	10054263          	bltz	a0,8000579e <sys_link+0x13c>
  begin_op();
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	cf4080e7          	jalr	-780(ra) # 80004392 <begin_op>
  if((ip = namei(old)) == 0){
    800056a6:	ed040513          	addi	a0,s0,-304
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	ac8080e7          	jalr	-1336(ra) # 80004172 <namei>
    800056b2:	84aa                	mv	s1,a0
    800056b4:	c551                	beqz	a0,80005740 <sys_link+0xde>
  ilock(ip);
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	310080e7          	jalr	784(ra) # 800039c6 <ilock>
  if(ip->type == T_DIR){
    800056be:	04449703          	lh	a4,68(s1)
    800056c2:	4785                	li	a5,1
    800056c4:	08f70463          	beq	a4,a5,8000574c <sys_link+0xea>
  ip->nlink++;
    800056c8:	04a4d783          	lhu	a5,74(s1)
    800056cc:	2785                	addiw	a5,a5,1
    800056ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	226080e7          	jalr	550(ra) # 800038fa <iupdate>
  iunlock(ip);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	3aa080e7          	jalr	938(ra) # 80003a88 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056e6:	fd040593          	addi	a1,s0,-48
    800056ea:	f5040513          	addi	a0,s0,-176
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	aa2080e7          	jalr	-1374(ra) # 80004190 <nameiparent>
    800056f6:	892a                	mv	s2,a0
    800056f8:	c935                	beqz	a0,8000576c <sys_link+0x10a>
  ilock(dp);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	2cc080e7          	jalr	716(ra) # 800039c6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005702:	00092703          	lw	a4,0(s2)
    80005706:	409c                	lw	a5,0(s1)
    80005708:	04f71d63          	bne	a4,a5,80005762 <sys_link+0x100>
    8000570c:	40d0                	lw	a2,4(s1)
    8000570e:	fd040593          	addi	a1,s0,-48
    80005712:	854a                	mv	a0,s2
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	9ac080e7          	jalr	-1620(ra) # 800040c0 <dirlink>
    8000571c:	04054363          	bltz	a0,80005762 <sys_link+0x100>
  iunlockput(dp);
    80005720:	854a                	mv	a0,s2
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	506080e7          	jalr	1286(ra) # 80003c28 <iunlockput>
  iput(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	454080e7          	jalr	1108(ra) # 80003b80 <iput>
  end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	cdc080e7          	jalr	-804(ra) # 80004410 <end_op>
  return 0;
    8000573c:	4781                	li	a5,0
    8000573e:	a085                	j	8000579e <sys_link+0x13c>
    end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	cd0080e7          	jalr	-816(ra) # 80004410 <end_op>
    return -1;
    80005748:	57fd                	li	a5,-1
    8000574a:	a891                	j	8000579e <sys_link+0x13c>
    iunlockput(ip);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	4da080e7          	jalr	1242(ra) # 80003c28 <iunlockput>
    end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	cba080e7          	jalr	-838(ra) # 80004410 <end_op>
    return -1;
    8000575e:	57fd                	li	a5,-1
    80005760:	a83d                	j	8000579e <sys_link+0x13c>
    iunlockput(dp);
    80005762:	854a                	mv	a0,s2
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	4c4080e7          	jalr	1220(ra) # 80003c28 <iunlockput>
  ilock(ip);
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	258080e7          	jalr	600(ra) # 800039c6 <ilock>
  ip->nlink--;
    80005776:	04a4d783          	lhu	a5,74(s1)
    8000577a:	37fd                	addiw	a5,a5,-1
    8000577c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	178080e7          	jalr	376(ra) # 800038fa <iupdate>
  iunlockput(ip);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	49c080e7          	jalr	1180(ra) # 80003c28 <iunlockput>
  end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	c7c080e7          	jalr	-900(ra) # 80004410 <end_op>
  return -1;
    8000579c:	57fd                	li	a5,-1
}
    8000579e:	853e                	mv	a0,a5
    800057a0:	70b2                	ld	ra,296(sp)
    800057a2:	7412                	ld	s0,288(sp)
    800057a4:	64f2                	ld	s1,280(sp)
    800057a6:	6952                	ld	s2,272(sp)
    800057a8:	6155                	addi	sp,sp,304
    800057aa:	8082                	ret

00000000800057ac <sys_unlink>:
{
    800057ac:	7151                	addi	sp,sp,-240
    800057ae:	f586                	sd	ra,232(sp)
    800057b0:	f1a2                	sd	s0,224(sp)
    800057b2:	eda6                	sd	s1,216(sp)
    800057b4:	e9ca                	sd	s2,208(sp)
    800057b6:	e5ce                	sd	s3,200(sp)
    800057b8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057ba:	08000613          	li	a2,128
    800057be:	f3040593          	addi	a1,s0,-208
    800057c2:	4501                	li	a0,0
    800057c4:	ffffd097          	auipc	ra,0xffffd
    800057c8:	56e080e7          	jalr	1390(ra) # 80002d32 <argstr>
    800057cc:	18054163          	bltz	a0,8000594e <sys_unlink+0x1a2>
  begin_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	bc2080e7          	jalr	-1086(ra) # 80004392 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057d8:	fb040593          	addi	a1,s0,-80
    800057dc:	f3040513          	addi	a0,s0,-208
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	9b0080e7          	jalr	-1616(ra) # 80004190 <nameiparent>
    800057e8:	84aa                	mv	s1,a0
    800057ea:	c979                	beqz	a0,800058c0 <sys_unlink+0x114>
  ilock(dp);
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	1da080e7          	jalr	474(ra) # 800039c6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057f4:	00003597          	auipc	a1,0x3
    800057f8:	f1c58593          	addi	a1,a1,-228 # 80008710 <syscalls+0x2c0>
    800057fc:	fb040513          	addi	a0,s0,-80
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	690080e7          	jalr	1680(ra) # 80003e90 <namecmp>
    80005808:	14050a63          	beqz	a0,8000595c <sys_unlink+0x1b0>
    8000580c:	00003597          	auipc	a1,0x3
    80005810:	f0c58593          	addi	a1,a1,-244 # 80008718 <syscalls+0x2c8>
    80005814:	fb040513          	addi	a0,s0,-80
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	678080e7          	jalr	1656(ra) # 80003e90 <namecmp>
    80005820:	12050e63          	beqz	a0,8000595c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005824:	f2c40613          	addi	a2,s0,-212
    80005828:	fb040593          	addi	a1,s0,-80
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	67c080e7          	jalr	1660(ra) # 80003eaa <dirlookup>
    80005836:	892a                	mv	s2,a0
    80005838:	12050263          	beqz	a0,8000595c <sys_unlink+0x1b0>
  ilock(ip);
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	18a080e7          	jalr	394(ra) # 800039c6 <ilock>
  if(ip->nlink < 1)
    80005844:	04a91783          	lh	a5,74(s2)
    80005848:	08f05263          	blez	a5,800058cc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000584c:	04491703          	lh	a4,68(s2)
    80005850:	4785                	li	a5,1
    80005852:	08f70563          	beq	a4,a5,800058dc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005856:	4641                	li	a2,16
    80005858:	4581                	li	a1,0
    8000585a:	fc040513          	addi	a0,s0,-64
    8000585e:	ffffb097          	auipc	ra,0xffffb
    80005862:	474080e7          	jalr	1140(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005866:	4741                	li	a4,16
    80005868:	f2c42683          	lw	a3,-212(s0)
    8000586c:	fc040613          	addi	a2,s0,-64
    80005870:	4581                	li	a1,0
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	4fe080e7          	jalr	1278(ra) # 80003d72 <writei>
    8000587c:	47c1                	li	a5,16
    8000587e:	0af51563          	bne	a0,a5,80005928 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005882:	04491703          	lh	a4,68(s2)
    80005886:	4785                	li	a5,1
    80005888:	0af70863          	beq	a4,a5,80005938 <sys_unlink+0x18c>
  iunlockput(dp);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	39a080e7          	jalr	922(ra) # 80003c28 <iunlockput>
  ip->nlink--;
    80005896:	04a95783          	lhu	a5,74(s2)
    8000589a:	37fd                	addiw	a5,a5,-1
    8000589c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	058080e7          	jalr	88(ra) # 800038fa <iupdate>
  iunlockput(ip);
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	37c080e7          	jalr	892(ra) # 80003c28 <iunlockput>
  end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	b5c080e7          	jalr	-1188(ra) # 80004410 <end_op>
  return 0;
    800058bc:	4501                	li	a0,0
    800058be:	a84d                	j	80005970 <sys_unlink+0x1c4>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	b50080e7          	jalr	-1200(ra) # 80004410 <end_op>
    return -1;
    800058c8:	557d                	li	a0,-1
    800058ca:	a05d                	j	80005970 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058cc:	00003517          	auipc	a0,0x3
    800058d0:	e5450513          	addi	a0,a0,-428 # 80008720 <syscalls+0x2d0>
    800058d4:	ffffb097          	auipc	ra,0xffffb
    800058d8:	c6c080e7          	jalr	-916(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058dc:	04c92703          	lw	a4,76(s2)
    800058e0:	02000793          	li	a5,32
    800058e4:	f6e7f9e3          	bgeu	a5,a4,80005856 <sys_unlink+0xaa>
    800058e8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058ec:	4741                	li	a4,16
    800058ee:	86ce                	mv	a3,s3
    800058f0:	f1840613          	addi	a2,s0,-232
    800058f4:	4581                	li	a1,0
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	382080e7          	jalr	898(ra) # 80003c7a <readi>
    80005900:	47c1                	li	a5,16
    80005902:	00f51b63          	bne	a0,a5,80005918 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005906:	f1845783          	lhu	a5,-232(s0)
    8000590a:	e7a1                	bnez	a5,80005952 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000590c:	29c1                	addiw	s3,s3,16
    8000590e:	04c92783          	lw	a5,76(s2)
    80005912:	fcf9ede3          	bltu	s3,a5,800058ec <sys_unlink+0x140>
    80005916:	b781                	j	80005856 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005918:	00003517          	auipc	a0,0x3
    8000591c:	e2050513          	addi	a0,a0,-480 # 80008738 <syscalls+0x2e8>
    80005920:	ffffb097          	auipc	ra,0xffffb
    80005924:	c20080e7          	jalr	-992(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005928:	00003517          	auipc	a0,0x3
    8000592c:	e2850513          	addi	a0,a0,-472 # 80008750 <syscalls+0x300>
    80005930:	ffffb097          	auipc	ra,0xffffb
    80005934:	c10080e7          	jalr	-1008(ra) # 80000540 <panic>
    dp->nlink--;
    80005938:	04a4d783          	lhu	a5,74(s1)
    8000593c:	37fd                	addiw	a5,a5,-1
    8000593e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005942:	8526                	mv	a0,s1
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	fb6080e7          	jalr	-74(ra) # 800038fa <iupdate>
    8000594c:	b781                	j	8000588c <sys_unlink+0xe0>
    return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	a005                	j	80005970 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005952:	854a                	mv	a0,s2
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	2d4080e7          	jalr	724(ra) # 80003c28 <iunlockput>
  iunlockput(dp);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	2ca080e7          	jalr	714(ra) # 80003c28 <iunlockput>
  end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	aaa080e7          	jalr	-1366(ra) # 80004410 <end_op>
  return -1;
    8000596e:	557d                	li	a0,-1
}
    80005970:	70ae                	ld	ra,232(sp)
    80005972:	740e                	ld	s0,224(sp)
    80005974:	64ee                	ld	s1,216(sp)
    80005976:	694e                	ld	s2,208(sp)
    80005978:	69ae                	ld	s3,200(sp)
    8000597a:	616d                	addi	sp,sp,240
    8000597c:	8082                	ret

000000008000597e <sys_open>:

uint64
sys_open(void)
{
    8000597e:	7131                	addi	sp,sp,-192
    80005980:	fd06                	sd	ra,184(sp)
    80005982:	f922                	sd	s0,176(sp)
    80005984:	f526                	sd	s1,168(sp)
    80005986:	f14a                	sd	s2,160(sp)
    80005988:	ed4e                	sd	s3,152(sp)
    8000598a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000598c:	f4c40593          	addi	a1,s0,-180
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	360080e7          	jalr	864(ra) # 80002cf2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000599a:	08000613          	li	a2,128
    8000599e:	f5040593          	addi	a1,s0,-176
    800059a2:	4501                	li	a0,0
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	38e080e7          	jalr	910(ra) # 80002d32 <argstr>
    800059ac:	87aa                	mv	a5,a0
    return -1;
    800059ae:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059b0:	0a07c963          	bltz	a5,80005a62 <sys_open+0xe4>

  begin_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	9de080e7          	jalr	-1570(ra) # 80004392 <begin_op>

  if(omode & O_CREATE){
    800059bc:	f4c42783          	lw	a5,-180(s0)
    800059c0:	2007f793          	andi	a5,a5,512
    800059c4:	cfc5                	beqz	a5,80005a7c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059c6:	4681                	li	a3,0
    800059c8:	4601                	li	a2,0
    800059ca:	4589                	li	a1,2
    800059cc:	f5040513          	addi	a0,s0,-176
    800059d0:	00000097          	auipc	ra,0x0
    800059d4:	964080e7          	jalr	-1692(ra) # 80005334 <create>
    800059d8:	84aa                	mv	s1,a0
    if(ip == 0){
    800059da:	c959                	beqz	a0,80005a70 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059dc:	04449703          	lh	a4,68(s1)
    800059e0:	478d                	li	a5,3
    800059e2:	00f71763          	bne	a4,a5,800059f0 <sys_open+0x72>
    800059e6:	0464d703          	lhu	a4,70(s1)
    800059ea:	47a5                	li	a5,9
    800059ec:	0ce7ed63          	bltu	a5,a4,80005ac6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	dae080e7          	jalr	-594(ra) # 8000479e <filealloc>
    800059f8:	89aa                	mv	s3,a0
    800059fa:	10050363          	beqz	a0,80005b00 <sys_open+0x182>
    800059fe:	00000097          	auipc	ra,0x0
    80005a02:	8f4080e7          	jalr	-1804(ra) # 800052f2 <fdalloc>
    80005a06:	892a                	mv	s2,a0
    80005a08:	0e054763          	bltz	a0,80005af6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a0c:	04449703          	lh	a4,68(s1)
    80005a10:	478d                	li	a5,3
    80005a12:	0cf70563          	beq	a4,a5,80005adc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a16:	4789                	li	a5,2
    80005a18:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a1c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a20:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a24:	f4c42783          	lw	a5,-180(s0)
    80005a28:	0017c713          	xori	a4,a5,1
    80005a2c:	8b05                	andi	a4,a4,1
    80005a2e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a32:	0037f713          	andi	a4,a5,3
    80005a36:	00e03733          	snez	a4,a4
    80005a3a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a3e:	4007f793          	andi	a5,a5,1024
    80005a42:	c791                	beqz	a5,80005a4e <sys_open+0xd0>
    80005a44:	04449703          	lh	a4,68(s1)
    80005a48:	4789                	li	a5,2
    80005a4a:	0af70063          	beq	a4,a5,80005aea <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	038080e7          	jalr	56(ra) # 80003a88 <iunlock>
  end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	9b8080e7          	jalr	-1608(ra) # 80004410 <end_op>

  return fd;
    80005a60:	854a                	mv	a0,s2
}
    80005a62:	70ea                	ld	ra,184(sp)
    80005a64:	744a                	ld	s0,176(sp)
    80005a66:	74aa                	ld	s1,168(sp)
    80005a68:	790a                	ld	s2,160(sp)
    80005a6a:	69ea                	ld	s3,152(sp)
    80005a6c:	6129                	addi	sp,sp,192
    80005a6e:	8082                	ret
      end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	9a0080e7          	jalr	-1632(ra) # 80004410 <end_op>
      return -1;
    80005a78:	557d                	li	a0,-1
    80005a7a:	b7e5                	j	80005a62 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a7c:	f5040513          	addi	a0,s0,-176
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	6f2080e7          	jalr	1778(ra) # 80004172 <namei>
    80005a88:	84aa                	mv	s1,a0
    80005a8a:	c905                	beqz	a0,80005aba <sys_open+0x13c>
    ilock(ip);
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	f3a080e7          	jalr	-198(ra) # 800039c6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a94:	04449703          	lh	a4,68(s1)
    80005a98:	4785                	li	a5,1
    80005a9a:	f4f711e3          	bne	a4,a5,800059dc <sys_open+0x5e>
    80005a9e:	f4c42783          	lw	a5,-180(s0)
    80005aa2:	d7b9                	beqz	a5,800059f0 <sys_open+0x72>
      iunlockput(ip);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	182080e7          	jalr	386(ra) # 80003c28 <iunlockput>
      end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	962080e7          	jalr	-1694(ra) # 80004410 <end_op>
      return -1;
    80005ab6:	557d                	li	a0,-1
    80005ab8:	b76d                	j	80005a62 <sys_open+0xe4>
      end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	956080e7          	jalr	-1706(ra) # 80004410 <end_op>
      return -1;
    80005ac2:	557d                	li	a0,-1
    80005ac4:	bf79                	j	80005a62 <sys_open+0xe4>
    iunlockput(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	160080e7          	jalr	352(ra) # 80003c28 <iunlockput>
    end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	940080e7          	jalr	-1728(ra) # 80004410 <end_op>
    return -1;
    80005ad8:	557d                	li	a0,-1
    80005ada:	b761                	j	80005a62 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005adc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ae0:	04649783          	lh	a5,70(s1)
    80005ae4:	02f99223          	sh	a5,36(s3)
    80005ae8:	bf25                	j	80005a20 <sys_open+0xa2>
    itrunc(ip);
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	fe8080e7          	jalr	-24(ra) # 80003ad4 <itrunc>
    80005af4:	bfa9                	j	80005a4e <sys_open+0xd0>
      fileclose(f);
    80005af6:	854e                	mv	a0,s3
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	d62080e7          	jalr	-670(ra) # 8000485a <fileclose>
    iunlockput(ip);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	126080e7          	jalr	294(ra) # 80003c28 <iunlockput>
    end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	906080e7          	jalr	-1786(ra) # 80004410 <end_op>
    return -1;
    80005b12:	557d                	li	a0,-1
    80005b14:	b7b9                	j	80005a62 <sys_open+0xe4>

0000000080005b16 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b16:	7175                	addi	sp,sp,-144
    80005b18:	e506                	sd	ra,136(sp)
    80005b1a:	e122                	sd	s0,128(sp)
    80005b1c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	874080e7          	jalr	-1932(ra) # 80004392 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b26:	08000613          	li	a2,128
    80005b2a:	f7040593          	addi	a1,s0,-144
    80005b2e:	4501                	li	a0,0
    80005b30:	ffffd097          	auipc	ra,0xffffd
    80005b34:	202080e7          	jalr	514(ra) # 80002d32 <argstr>
    80005b38:	02054963          	bltz	a0,80005b6a <sys_mkdir+0x54>
    80005b3c:	4681                	li	a3,0
    80005b3e:	4601                	li	a2,0
    80005b40:	4585                	li	a1,1
    80005b42:	f7040513          	addi	a0,s0,-144
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	7ee080e7          	jalr	2030(ra) # 80005334 <create>
    80005b4e:	cd11                	beqz	a0,80005b6a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	0d8080e7          	jalr	216(ra) # 80003c28 <iunlockput>
  end_op();
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	8b8080e7          	jalr	-1864(ra) # 80004410 <end_op>
  return 0;
    80005b60:	4501                	li	a0,0
}
    80005b62:	60aa                	ld	ra,136(sp)
    80005b64:	640a                	ld	s0,128(sp)
    80005b66:	6149                	addi	sp,sp,144
    80005b68:	8082                	ret
    end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	8a6080e7          	jalr	-1882(ra) # 80004410 <end_op>
    return -1;
    80005b72:	557d                	li	a0,-1
    80005b74:	b7fd                	j	80005b62 <sys_mkdir+0x4c>

0000000080005b76 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b76:	7135                	addi	sp,sp,-160
    80005b78:	ed06                	sd	ra,152(sp)
    80005b7a:	e922                	sd	s0,144(sp)
    80005b7c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	814080e7          	jalr	-2028(ra) # 80004392 <begin_op>
  argint(1, &major);
    80005b86:	f6c40593          	addi	a1,s0,-148
    80005b8a:	4505                	li	a0,1
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	166080e7          	jalr	358(ra) # 80002cf2 <argint>
  argint(2, &minor);
    80005b94:	f6840593          	addi	a1,s0,-152
    80005b98:	4509                	li	a0,2
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	158080e7          	jalr	344(ra) # 80002cf2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ba2:	08000613          	li	a2,128
    80005ba6:	f7040593          	addi	a1,s0,-144
    80005baa:	4501                	li	a0,0
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	186080e7          	jalr	390(ra) # 80002d32 <argstr>
    80005bb4:	02054b63          	bltz	a0,80005bea <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bb8:	f6841683          	lh	a3,-152(s0)
    80005bbc:	f6c41603          	lh	a2,-148(s0)
    80005bc0:	458d                	li	a1,3
    80005bc2:	f7040513          	addi	a0,s0,-144
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	76e080e7          	jalr	1902(ra) # 80005334 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bce:	cd11                	beqz	a0,80005bea <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	058080e7          	jalr	88(ra) # 80003c28 <iunlockput>
  end_op();
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	838080e7          	jalr	-1992(ra) # 80004410 <end_op>
  return 0;
    80005be0:	4501                	li	a0,0
}
    80005be2:	60ea                	ld	ra,152(sp)
    80005be4:	644a                	ld	s0,144(sp)
    80005be6:	610d                	addi	sp,sp,160
    80005be8:	8082                	ret
    end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	826080e7          	jalr	-2010(ra) # 80004410 <end_op>
    return -1;
    80005bf2:	557d                	li	a0,-1
    80005bf4:	b7fd                	j	80005be2 <sys_mknod+0x6c>

0000000080005bf6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bf6:	7135                	addi	sp,sp,-160
    80005bf8:	ed06                	sd	ra,152(sp)
    80005bfa:	e922                	sd	s0,144(sp)
    80005bfc:	e526                	sd	s1,136(sp)
    80005bfe:	e14a                	sd	s2,128(sp)
    80005c00:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	daa080e7          	jalr	-598(ra) # 800019ac <myproc>
    80005c0a:	892a                	mv	s2,a0
  
  begin_op();
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	786080e7          	jalr	1926(ra) # 80004392 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c14:	08000613          	li	a2,128
    80005c18:	f6040593          	addi	a1,s0,-160
    80005c1c:	4501                	li	a0,0
    80005c1e:	ffffd097          	auipc	ra,0xffffd
    80005c22:	114080e7          	jalr	276(ra) # 80002d32 <argstr>
    80005c26:	04054b63          	bltz	a0,80005c7c <sys_chdir+0x86>
    80005c2a:	f6040513          	addi	a0,s0,-160
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	544080e7          	jalr	1348(ra) # 80004172 <namei>
    80005c36:	84aa                	mv	s1,a0
    80005c38:	c131                	beqz	a0,80005c7c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	d8c080e7          	jalr	-628(ra) # 800039c6 <ilock>
  if(ip->type != T_DIR){
    80005c42:	04449703          	lh	a4,68(s1)
    80005c46:	4785                	li	a5,1
    80005c48:	04f71063          	bne	a4,a5,80005c88 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	e3a080e7          	jalr	-454(ra) # 80003a88 <iunlock>
  iput(p->cwd);
    80005c56:	15093503          	ld	a0,336(s2)
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	f26080e7          	jalr	-218(ra) # 80003b80 <iput>
  end_op();
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	7ae080e7          	jalr	1966(ra) # 80004410 <end_op>
  p->cwd = ip;
    80005c6a:	14993823          	sd	s1,336(s2)
  return 0;
    80005c6e:	4501                	li	a0,0
}
    80005c70:	60ea                	ld	ra,152(sp)
    80005c72:	644a                	ld	s0,144(sp)
    80005c74:	64aa                	ld	s1,136(sp)
    80005c76:	690a                	ld	s2,128(sp)
    80005c78:	610d                	addi	sp,sp,160
    80005c7a:	8082                	ret
    end_op();
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	794080e7          	jalr	1940(ra) # 80004410 <end_op>
    return -1;
    80005c84:	557d                	li	a0,-1
    80005c86:	b7ed                	j	80005c70 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c88:	8526                	mv	a0,s1
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	f9e080e7          	jalr	-98(ra) # 80003c28 <iunlockput>
    end_op();
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	77e080e7          	jalr	1918(ra) # 80004410 <end_op>
    return -1;
    80005c9a:	557d                	li	a0,-1
    80005c9c:	bfd1                	j	80005c70 <sys_chdir+0x7a>

0000000080005c9e <sys_exec>:

uint64
sys_exec(void)
{
    80005c9e:	7145                	addi	sp,sp,-464
    80005ca0:	e786                	sd	ra,456(sp)
    80005ca2:	e3a2                	sd	s0,448(sp)
    80005ca4:	ff26                	sd	s1,440(sp)
    80005ca6:	fb4a                	sd	s2,432(sp)
    80005ca8:	f74e                	sd	s3,424(sp)
    80005caa:	f352                	sd	s4,416(sp)
    80005cac:	ef56                	sd	s5,408(sp)
    80005cae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cb0:	e3840593          	addi	a1,s0,-456
    80005cb4:	4505                	li	a0,1
    80005cb6:	ffffd097          	auipc	ra,0xffffd
    80005cba:	05c080e7          	jalr	92(ra) # 80002d12 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cbe:	08000613          	li	a2,128
    80005cc2:	f4040593          	addi	a1,s0,-192
    80005cc6:	4501                	li	a0,0
    80005cc8:	ffffd097          	auipc	ra,0xffffd
    80005ccc:	06a080e7          	jalr	106(ra) # 80002d32 <argstr>
    80005cd0:	87aa                	mv	a5,a0
    return -1;
    80005cd2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cd4:	0c07c363          	bltz	a5,80005d9a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005cd8:	10000613          	li	a2,256
    80005cdc:	4581                	li	a1,0
    80005cde:	e4040513          	addi	a0,s0,-448
    80005ce2:	ffffb097          	auipc	ra,0xffffb
    80005ce6:	ff0080e7          	jalr	-16(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cee:	89a6                	mv	s3,s1
    80005cf0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cf2:	02000a13          	li	s4,32
    80005cf6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cfa:	00391513          	slli	a0,s2,0x3
    80005cfe:	e3040593          	addi	a1,s0,-464
    80005d02:	e3843783          	ld	a5,-456(s0)
    80005d06:	953e                	add	a0,a0,a5
    80005d08:	ffffd097          	auipc	ra,0xffffd
    80005d0c:	f4c080e7          	jalr	-180(ra) # 80002c54 <fetchaddr>
    80005d10:	02054a63          	bltz	a0,80005d44 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d14:	e3043783          	ld	a5,-464(s0)
    80005d18:	c3b9                	beqz	a5,80005d5e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d1a:	ffffb097          	auipc	ra,0xffffb
    80005d1e:	dcc080e7          	jalr	-564(ra) # 80000ae6 <kalloc>
    80005d22:	85aa                	mv	a1,a0
    80005d24:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d28:	cd11                	beqz	a0,80005d44 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d2a:	6605                	lui	a2,0x1
    80005d2c:	e3043503          	ld	a0,-464(s0)
    80005d30:	ffffd097          	auipc	ra,0xffffd
    80005d34:	f76080e7          	jalr	-138(ra) # 80002ca6 <fetchstr>
    80005d38:	00054663          	bltz	a0,80005d44 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d3c:	0905                	addi	s2,s2,1
    80005d3e:	09a1                	addi	s3,s3,8
    80005d40:	fb491be3          	bne	s2,s4,80005cf6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d44:	f4040913          	addi	s2,s0,-192
    80005d48:	6088                	ld	a0,0(s1)
    80005d4a:	c539                	beqz	a0,80005d98 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d4c:	ffffb097          	auipc	ra,0xffffb
    80005d50:	c9c080e7          	jalr	-868(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d54:	04a1                	addi	s1,s1,8
    80005d56:	ff2499e3          	bne	s1,s2,80005d48 <sys_exec+0xaa>
  return -1;
    80005d5a:	557d                	li	a0,-1
    80005d5c:	a83d                	j	80005d9a <sys_exec+0xfc>
      argv[i] = 0;
    80005d5e:	0a8e                	slli	s5,s5,0x3
    80005d60:	fc0a8793          	addi	a5,s5,-64
    80005d64:	00878ab3          	add	s5,a5,s0
    80005d68:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d6c:	e4040593          	addi	a1,s0,-448
    80005d70:	f4040513          	addi	a0,s0,-192
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	160080e7          	jalr	352(ra) # 80004ed4 <exec>
    80005d7c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d7e:	f4040993          	addi	s3,s0,-192
    80005d82:	6088                	ld	a0,0(s1)
    80005d84:	c901                	beqz	a0,80005d94 <sys_exec+0xf6>
    kfree(argv[i]);
    80005d86:	ffffb097          	auipc	ra,0xffffb
    80005d8a:	c62080e7          	jalr	-926(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8e:	04a1                	addi	s1,s1,8
    80005d90:	ff3499e3          	bne	s1,s3,80005d82 <sys_exec+0xe4>
  return ret;
    80005d94:	854a                	mv	a0,s2
    80005d96:	a011                	j	80005d9a <sys_exec+0xfc>
  return -1;
    80005d98:	557d                	li	a0,-1
}
    80005d9a:	60be                	ld	ra,456(sp)
    80005d9c:	641e                	ld	s0,448(sp)
    80005d9e:	74fa                	ld	s1,440(sp)
    80005da0:	795a                	ld	s2,432(sp)
    80005da2:	79ba                	ld	s3,424(sp)
    80005da4:	7a1a                	ld	s4,416(sp)
    80005da6:	6afa                	ld	s5,408(sp)
    80005da8:	6179                	addi	sp,sp,464
    80005daa:	8082                	ret

0000000080005dac <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dac:	7139                	addi	sp,sp,-64
    80005dae:	fc06                	sd	ra,56(sp)
    80005db0:	f822                	sd	s0,48(sp)
    80005db2:	f426                	sd	s1,40(sp)
    80005db4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005db6:	ffffc097          	auipc	ra,0xffffc
    80005dba:	bf6080e7          	jalr	-1034(ra) # 800019ac <myproc>
    80005dbe:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dc0:	fd840593          	addi	a1,s0,-40
    80005dc4:	4501                	li	a0,0
    80005dc6:	ffffd097          	auipc	ra,0xffffd
    80005dca:	f4c080e7          	jalr	-180(ra) # 80002d12 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005dce:	fc840593          	addi	a1,s0,-56
    80005dd2:	fd040513          	addi	a0,s0,-48
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	db4080e7          	jalr	-588(ra) # 80004b8a <pipealloc>
    return -1;
    80005dde:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005de0:	0c054463          	bltz	a0,80005ea8 <sys_pipe+0xfc>
  fd0 = -1;
    80005de4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005de8:	fd043503          	ld	a0,-48(s0)
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	506080e7          	jalr	1286(ra) # 800052f2 <fdalloc>
    80005df4:	fca42223          	sw	a0,-60(s0)
    80005df8:	08054b63          	bltz	a0,80005e8e <sys_pipe+0xe2>
    80005dfc:	fc843503          	ld	a0,-56(s0)
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	4f2080e7          	jalr	1266(ra) # 800052f2 <fdalloc>
    80005e08:	fca42023          	sw	a0,-64(s0)
    80005e0c:	06054863          	bltz	a0,80005e7c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e10:	4691                	li	a3,4
    80005e12:	fc440613          	addi	a2,s0,-60
    80005e16:	fd843583          	ld	a1,-40(s0)
    80005e1a:	68a8                	ld	a0,80(s1)
    80005e1c:	ffffc097          	auipc	ra,0xffffc
    80005e20:	850080e7          	jalr	-1968(ra) # 8000166c <copyout>
    80005e24:	02054063          	bltz	a0,80005e44 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e28:	4691                	li	a3,4
    80005e2a:	fc040613          	addi	a2,s0,-64
    80005e2e:	fd843583          	ld	a1,-40(s0)
    80005e32:	0591                	addi	a1,a1,4
    80005e34:	68a8                	ld	a0,80(s1)
    80005e36:	ffffc097          	auipc	ra,0xffffc
    80005e3a:	836080e7          	jalr	-1994(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e3e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e40:	06055463          	bgez	a0,80005ea8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e44:	fc442783          	lw	a5,-60(s0)
    80005e48:	07e9                	addi	a5,a5,26
    80005e4a:	078e                	slli	a5,a5,0x3
    80005e4c:	97a6                	add	a5,a5,s1
    80005e4e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e52:	fc042783          	lw	a5,-64(s0)
    80005e56:	07e9                	addi	a5,a5,26
    80005e58:	078e                	slli	a5,a5,0x3
    80005e5a:	94be                	add	s1,s1,a5
    80005e5c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e60:	fd043503          	ld	a0,-48(s0)
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	9f6080e7          	jalr	-1546(ra) # 8000485a <fileclose>
    fileclose(wf);
    80005e6c:	fc843503          	ld	a0,-56(s0)
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	9ea080e7          	jalr	-1558(ra) # 8000485a <fileclose>
    return -1;
    80005e78:	57fd                	li	a5,-1
    80005e7a:	a03d                	j	80005ea8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e7c:	fc442783          	lw	a5,-60(s0)
    80005e80:	0007c763          	bltz	a5,80005e8e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e84:	07e9                	addi	a5,a5,26
    80005e86:	078e                	slli	a5,a5,0x3
    80005e88:	97a6                	add	a5,a5,s1
    80005e8a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005e8e:	fd043503          	ld	a0,-48(s0)
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	9c8080e7          	jalr	-1592(ra) # 8000485a <fileclose>
    fileclose(wf);
    80005e9a:	fc843503          	ld	a0,-56(s0)
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	9bc080e7          	jalr	-1604(ra) # 8000485a <fileclose>
    return -1;
    80005ea6:	57fd                	li	a5,-1
}
    80005ea8:	853e                	mv	a0,a5
    80005eaa:	70e2                	ld	ra,56(sp)
    80005eac:	7442                	ld	s0,48(sp)
    80005eae:	74a2                	ld	s1,40(sp)
    80005eb0:	6121                	addi	sp,sp,64
    80005eb2:	8082                	ret
	...

0000000080005ec0 <kernelvec>:
    80005ec0:	7111                	addi	sp,sp,-256
    80005ec2:	e006                	sd	ra,0(sp)
    80005ec4:	e40a                	sd	sp,8(sp)
    80005ec6:	e80e                	sd	gp,16(sp)
    80005ec8:	ec12                	sd	tp,24(sp)
    80005eca:	f016                	sd	t0,32(sp)
    80005ecc:	f41a                	sd	t1,40(sp)
    80005ece:	f81e                	sd	t2,48(sp)
    80005ed0:	fc22                	sd	s0,56(sp)
    80005ed2:	e0a6                	sd	s1,64(sp)
    80005ed4:	e4aa                	sd	a0,72(sp)
    80005ed6:	e8ae                	sd	a1,80(sp)
    80005ed8:	ecb2                	sd	a2,88(sp)
    80005eda:	f0b6                	sd	a3,96(sp)
    80005edc:	f4ba                	sd	a4,104(sp)
    80005ede:	f8be                	sd	a5,112(sp)
    80005ee0:	fcc2                	sd	a6,120(sp)
    80005ee2:	e146                	sd	a7,128(sp)
    80005ee4:	e54a                	sd	s2,136(sp)
    80005ee6:	e94e                	sd	s3,144(sp)
    80005ee8:	ed52                	sd	s4,152(sp)
    80005eea:	f156                	sd	s5,160(sp)
    80005eec:	f55a                	sd	s6,168(sp)
    80005eee:	f95e                	sd	s7,176(sp)
    80005ef0:	fd62                	sd	s8,184(sp)
    80005ef2:	e1e6                	sd	s9,192(sp)
    80005ef4:	e5ea                	sd	s10,200(sp)
    80005ef6:	e9ee                	sd	s11,208(sp)
    80005ef8:	edf2                	sd	t3,216(sp)
    80005efa:	f1f6                	sd	t4,224(sp)
    80005efc:	f5fa                	sd	t5,232(sp)
    80005efe:	f9fe                	sd	t6,240(sp)
    80005f00:	c21fc0ef          	jal	ra,80002b20 <kerneltrap>
    80005f04:	6082                	ld	ra,0(sp)
    80005f06:	6122                	ld	sp,8(sp)
    80005f08:	61c2                	ld	gp,16(sp)
    80005f0a:	7282                	ld	t0,32(sp)
    80005f0c:	7322                	ld	t1,40(sp)
    80005f0e:	73c2                	ld	t2,48(sp)
    80005f10:	7462                	ld	s0,56(sp)
    80005f12:	6486                	ld	s1,64(sp)
    80005f14:	6526                	ld	a0,72(sp)
    80005f16:	65c6                	ld	a1,80(sp)
    80005f18:	6666                	ld	a2,88(sp)
    80005f1a:	7686                	ld	a3,96(sp)
    80005f1c:	7726                	ld	a4,104(sp)
    80005f1e:	77c6                	ld	a5,112(sp)
    80005f20:	7866                	ld	a6,120(sp)
    80005f22:	688a                	ld	a7,128(sp)
    80005f24:	692a                	ld	s2,136(sp)
    80005f26:	69ca                	ld	s3,144(sp)
    80005f28:	6a6a                	ld	s4,152(sp)
    80005f2a:	7a8a                	ld	s5,160(sp)
    80005f2c:	7b2a                	ld	s6,168(sp)
    80005f2e:	7bca                	ld	s7,176(sp)
    80005f30:	7c6a                	ld	s8,184(sp)
    80005f32:	6c8e                	ld	s9,192(sp)
    80005f34:	6d2e                	ld	s10,200(sp)
    80005f36:	6dce                	ld	s11,208(sp)
    80005f38:	6e6e                	ld	t3,216(sp)
    80005f3a:	7e8e                	ld	t4,224(sp)
    80005f3c:	7f2e                	ld	t5,232(sp)
    80005f3e:	7fce                	ld	t6,240(sp)
    80005f40:	6111                	addi	sp,sp,256
    80005f42:	10200073          	sret
    80005f46:	00000013          	nop
    80005f4a:	00000013          	nop
    80005f4e:	0001                	nop

0000000080005f50 <timervec>:
    80005f50:	34051573          	csrrw	a0,mscratch,a0
    80005f54:	e10c                	sd	a1,0(a0)
    80005f56:	e510                	sd	a2,8(a0)
    80005f58:	e914                	sd	a3,16(a0)
    80005f5a:	6d0c                	ld	a1,24(a0)
    80005f5c:	7110                	ld	a2,32(a0)
    80005f5e:	6194                	ld	a3,0(a1)
    80005f60:	96b2                	add	a3,a3,a2
    80005f62:	e194                	sd	a3,0(a1)
    80005f64:	4589                	li	a1,2
    80005f66:	14459073          	csrw	sip,a1
    80005f6a:	6914                	ld	a3,16(a0)
    80005f6c:	6510                	ld	a2,8(a0)
    80005f6e:	610c                	ld	a1,0(a0)
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	30200073          	mret
	...

0000000080005f7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f7a:	1141                	addi	sp,sp,-16
    80005f7c:	e422                	sd	s0,8(sp)
    80005f7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f80:	0c0007b7          	lui	a5,0xc000
    80005f84:	4705                	li	a4,1
    80005f86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f88:	c3d8                	sw	a4,4(a5)
}
    80005f8a:	6422                	ld	s0,8(sp)
    80005f8c:	0141                	addi	sp,sp,16
    80005f8e:	8082                	ret

0000000080005f90 <plicinithart>:

void
plicinithart(void)
{
    80005f90:	1141                	addi	sp,sp,-16
    80005f92:	e406                	sd	ra,8(sp)
    80005f94:	e022                	sd	s0,0(sp)
    80005f96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	9e8080e7          	jalr	-1560(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fa0:	0085171b          	slliw	a4,a0,0x8
    80005fa4:	0c0027b7          	lui	a5,0xc002
    80005fa8:	97ba                	add	a5,a5,a4
    80005faa:	40200713          	li	a4,1026
    80005fae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fb2:	00d5151b          	slliw	a0,a0,0xd
    80005fb6:	0c2017b7          	lui	a5,0xc201
    80005fba:	97aa                	add	a5,a5,a0
    80005fbc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005fc0:	60a2                	ld	ra,8(sp)
    80005fc2:	6402                	ld	s0,0(sp)
    80005fc4:	0141                	addi	sp,sp,16
    80005fc6:	8082                	ret

0000000080005fc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fc8:	1141                	addi	sp,sp,-16
    80005fca:	e406                	sd	ra,8(sp)
    80005fcc:	e022                	sd	s0,0(sp)
    80005fce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd0:	ffffc097          	auipc	ra,0xffffc
    80005fd4:	9b0080e7          	jalr	-1616(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fd8:	00d5151b          	slliw	a0,a0,0xd
    80005fdc:	0c2017b7          	lui	a5,0xc201
    80005fe0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005fe2:	43c8                	lw	a0,4(a5)
    80005fe4:	60a2                	ld	ra,8(sp)
    80005fe6:	6402                	ld	s0,0(sp)
    80005fe8:	0141                	addi	sp,sp,16
    80005fea:	8082                	ret

0000000080005fec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fec:	1101                	addi	sp,sp,-32
    80005fee:	ec06                	sd	ra,24(sp)
    80005ff0:	e822                	sd	s0,16(sp)
    80005ff2:	e426                	sd	s1,8(sp)
    80005ff4:	1000                	addi	s0,sp,32
    80005ff6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ff8:	ffffc097          	auipc	ra,0xffffc
    80005ffc:	988080e7          	jalr	-1656(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006000:	00d5151b          	slliw	a0,a0,0xd
    80006004:	0c2017b7          	lui	a5,0xc201
    80006008:	97aa                	add	a5,a5,a0
    8000600a:	c3c4                	sw	s1,4(a5)
}
    8000600c:	60e2                	ld	ra,24(sp)
    8000600e:	6442                	ld	s0,16(sp)
    80006010:	64a2                	ld	s1,8(sp)
    80006012:	6105                	addi	sp,sp,32
    80006014:	8082                	ret

0000000080006016 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006016:	1141                	addi	sp,sp,-16
    80006018:	e406                	sd	ra,8(sp)
    8000601a:	e022                	sd	s0,0(sp)
    8000601c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000601e:	479d                	li	a5,7
    80006020:	04a7cc63          	blt	a5,a0,80006078 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006024:	0001d797          	auipc	a5,0x1d
    80006028:	81c78793          	addi	a5,a5,-2020 # 80022840 <disk>
    8000602c:	97aa                	add	a5,a5,a0
    8000602e:	0187c783          	lbu	a5,24(a5)
    80006032:	ebb9                	bnez	a5,80006088 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006034:	00451693          	slli	a3,a0,0x4
    80006038:	0001d797          	auipc	a5,0x1d
    8000603c:	80878793          	addi	a5,a5,-2040 # 80022840 <disk>
    80006040:	6398                	ld	a4,0(a5)
    80006042:	9736                	add	a4,a4,a3
    80006044:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006048:	6398                	ld	a4,0(a5)
    8000604a:	9736                	add	a4,a4,a3
    8000604c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006050:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006054:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006058:	97aa                	add	a5,a5,a0
    8000605a:	4705                	li	a4,1
    8000605c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006060:	0001c517          	auipc	a0,0x1c
    80006064:	7f850513          	addi	a0,a0,2040 # 80022858 <disk+0x18>
    80006068:	ffffc097          	auipc	ra,0xffffc
    8000606c:	064080e7          	jalr	100(ra) # 800020cc <wakeup>
}
    80006070:	60a2                	ld	ra,8(sp)
    80006072:	6402                	ld	s0,0(sp)
    80006074:	0141                	addi	sp,sp,16
    80006076:	8082                	ret
    panic("free_desc 1");
    80006078:	00002517          	auipc	a0,0x2
    8000607c:	6e850513          	addi	a0,a0,1768 # 80008760 <syscalls+0x310>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4c0080e7          	jalr	1216(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	6e850513          	addi	a0,a0,1768 # 80008770 <syscalls+0x320>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b0080e7          	jalr	1200(ra) # 80000540 <panic>

0000000080006098 <virtio_disk_init>:
{
    80006098:	1101                	addi	sp,sp,-32
    8000609a:	ec06                	sd	ra,24(sp)
    8000609c:	e822                	sd	s0,16(sp)
    8000609e:	e426                	sd	s1,8(sp)
    800060a0:	e04a                	sd	s2,0(sp)
    800060a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060a4:	00002597          	auipc	a1,0x2
    800060a8:	6dc58593          	addi	a1,a1,1756 # 80008780 <syscalls+0x330>
    800060ac:	0001d517          	auipc	a0,0x1d
    800060b0:	8bc50513          	addi	a0,a0,-1860 # 80022968 <disk+0x128>
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	a92080e7          	jalr	-1390(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060bc:	100017b7          	lui	a5,0x10001
    800060c0:	4398                	lw	a4,0(a5)
    800060c2:	2701                	sext.w	a4,a4
    800060c4:	747277b7          	lui	a5,0x74727
    800060c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060cc:	14f71b63          	bne	a4,a5,80006222 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060d0:	100017b7          	lui	a5,0x10001
    800060d4:	43dc                	lw	a5,4(a5)
    800060d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060d8:	4709                	li	a4,2
    800060da:	14e79463          	bne	a5,a4,80006222 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	479c                	lw	a5,8(a5)
    800060e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060e6:	12e79e63          	bne	a5,a4,80006222 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ea:	100017b7          	lui	a5,0x10001
    800060ee:	47d8                	lw	a4,12(a5)
    800060f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060f2:	554d47b7          	lui	a5,0x554d4
    800060f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060fa:	12f71463          	bne	a4,a5,80006222 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060fe:	100017b7          	lui	a5,0x10001
    80006102:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006106:	4705                	li	a4,1
    80006108:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000610a:	470d                	li	a4,3
    8000610c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000610e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006110:	c7ffe6b7          	lui	a3,0xc7ffe
    80006114:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbddf>
    80006118:	8f75                	and	a4,a4,a3
    8000611a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611c:	472d                	li	a4,11
    8000611e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006120:	5bbc                	lw	a5,112(a5)
    80006122:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006126:	8ba1                	andi	a5,a5,8
    80006128:	10078563          	beqz	a5,80006232 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000612c:	100017b7          	lui	a5,0x10001
    80006130:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006134:	43fc                	lw	a5,68(a5)
    80006136:	2781                	sext.w	a5,a5
    80006138:	10079563          	bnez	a5,80006242 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	5bdc                	lw	a5,52(a5)
    80006142:	2781                	sext.w	a5,a5
  if(max == 0)
    80006144:	10078763          	beqz	a5,80006252 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006148:	471d                	li	a4,7
    8000614a:	10f77c63          	bgeu	a4,a5,80006262 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	998080e7          	jalr	-1640(ra) # 80000ae6 <kalloc>
    80006156:	0001c497          	auipc	s1,0x1c
    8000615a:	6ea48493          	addi	s1,s1,1770 # 80022840 <disk>
    8000615e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006160:	ffffb097          	auipc	ra,0xffffb
    80006164:	986080e7          	jalr	-1658(ra) # 80000ae6 <kalloc>
    80006168:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000616a:	ffffb097          	auipc	ra,0xffffb
    8000616e:	97c080e7          	jalr	-1668(ra) # 80000ae6 <kalloc>
    80006172:	87aa                	mv	a5,a0
    80006174:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006176:	6088                	ld	a0,0(s1)
    80006178:	cd6d                	beqz	a0,80006272 <virtio_disk_init+0x1da>
    8000617a:	0001c717          	auipc	a4,0x1c
    8000617e:	6ce73703          	ld	a4,1742(a4) # 80022848 <disk+0x8>
    80006182:	cb65                	beqz	a4,80006272 <virtio_disk_init+0x1da>
    80006184:	c7fd                	beqz	a5,80006272 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006186:	6605                	lui	a2,0x1
    80006188:	4581                	li	a1,0
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	b48080e7          	jalr	-1208(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006192:	0001c497          	auipc	s1,0x1c
    80006196:	6ae48493          	addi	s1,s1,1710 # 80022840 <disk>
    8000619a:	6605                	lui	a2,0x1
    8000619c:	4581                	li	a1,0
    8000619e:	6488                	ld	a0,8(s1)
    800061a0:	ffffb097          	auipc	ra,0xffffb
    800061a4:	b32080e7          	jalr	-1230(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061a8:	6605                	lui	a2,0x1
    800061aa:	4581                	li	a1,0
    800061ac:	6888                	ld	a0,16(s1)
    800061ae:	ffffb097          	auipc	ra,0xffffb
    800061b2:	b24080e7          	jalr	-1244(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061b6:	100017b7          	lui	a5,0x10001
    800061ba:	4721                	li	a4,8
    800061bc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061be:	4098                	lw	a4,0(s1)
    800061c0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061c4:	40d8                	lw	a4,4(s1)
    800061c6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ca:	6498                	ld	a4,8(s1)
    800061cc:	0007069b          	sext.w	a3,a4
    800061d0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061d4:	9701                	srai	a4,a4,0x20
    800061d6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061da:	6898                	ld	a4,16(s1)
    800061dc:	0007069b          	sext.w	a3,a4
    800061e0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061e4:	9701                	srai	a4,a4,0x20
    800061e6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061ea:	4705                	li	a4,1
    800061ec:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800061ee:	00e48c23          	sb	a4,24(s1)
    800061f2:	00e48ca3          	sb	a4,25(s1)
    800061f6:	00e48d23          	sb	a4,26(s1)
    800061fa:	00e48da3          	sb	a4,27(s1)
    800061fe:	00e48e23          	sb	a4,28(s1)
    80006202:	00e48ea3          	sb	a4,29(s1)
    80006206:	00e48f23          	sb	a4,30(s1)
    8000620a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000620e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006212:	0727a823          	sw	s2,112(a5)
}
    80006216:	60e2                	ld	ra,24(sp)
    80006218:	6442                	ld	s0,16(sp)
    8000621a:	64a2                	ld	s1,8(sp)
    8000621c:	6902                	ld	s2,0(sp)
    8000621e:	6105                	addi	sp,sp,32
    80006220:	8082                	ret
    panic("could not find virtio disk");
    80006222:	00002517          	auipc	a0,0x2
    80006226:	56e50513          	addi	a0,a0,1390 # 80008790 <syscalls+0x340>
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	316080e7          	jalr	790(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006232:	00002517          	auipc	a0,0x2
    80006236:	57e50513          	addi	a0,a0,1406 # 800087b0 <syscalls+0x360>
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	306080e7          	jalr	774(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	58e50513          	addi	a0,a0,1422 # 800087d0 <syscalls+0x380>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	59e50513          	addi	a0,a0,1438 # 800087f0 <syscalls+0x3a0>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e6080e7          	jalr	742(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	5ae50513          	addi	a0,a0,1454 # 80008810 <syscalls+0x3c0>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d6080e7          	jalr	726(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	5be50513          	addi	a0,a0,1470 # 80008830 <syscalls+0x3e0>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>

0000000080006282 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006282:	7119                	addi	sp,sp,-128
    80006284:	fc86                	sd	ra,120(sp)
    80006286:	f8a2                	sd	s0,112(sp)
    80006288:	f4a6                	sd	s1,104(sp)
    8000628a:	f0ca                	sd	s2,96(sp)
    8000628c:	ecce                	sd	s3,88(sp)
    8000628e:	e8d2                	sd	s4,80(sp)
    80006290:	e4d6                	sd	s5,72(sp)
    80006292:	e0da                	sd	s6,64(sp)
    80006294:	fc5e                	sd	s7,56(sp)
    80006296:	f862                	sd	s8,48(sp)
    80006298:	f466                	sd	s9,40(sp)
    8000629a:	f06a                	sd	s10,32(sp)
    8000629c:	ec6e                	sd	s11,24(sp)
    8000629e:	0100                	addi	s0,sp,128
    800062a0:	8aaa                	mv	s5,a0
    800062a2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062a4:	00c52d03          	lw	s10,12(a0)
    800062a8:	001d1d1b          	slliw	s10,s10,0x1
    800062ac:	1d02                	slli	s10,s10,0x20
    800062ae:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800062b2:	0001c517          	auipc	a0,0x1c
    800062b6:	6b650513          	addi	a0,a0,1718 # 80022968 <disk+0x128>
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	91c080e7          	jalr	-1764(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800062c2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062c4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062c6:	0001cb97          	auipc	s7,0x1c
    800062ca:	57ab8b93          	addi	s7,s7,1402 # 80022840 <disk>
  for(int i = 0; i < 3; i++){
    800062ce:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062d0:	0001cc97          	auipc	s9,0x1c
    800062d4:	698c8c93          	addi	s9,s9,1688 # 80022968 <disk+0x128>
    800062d8:	a08d                	j	8000633a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062da:	00fb8733          	add	a4,s7,a5
    800062de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800062e2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062e4:	0207c563          	bltz	a5,8000630e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062e8:	2905                	addiw	s2,s2,1
    800062ea:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800062ec:	05690c63          	beq	s2,s6,80006344 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800062f0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800062f2:	0001c717          	auipc	a4,0x1c
    800062f6:	54e70713          	addi	a4,a4,1358 # 80022840 <disk>
    800062fa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800062fc:	01874683          	lbu	a3,24(a4)
    80006300:	fee9                	bnez	a3,800062da <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006302:	2785                	addiw	a5,a5,1
    80006304:	0705                	addi	a4,a4,1
    80006306:	fe979be3          	bne	a5,s1,800062fc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000630a:	57fd                	li	a5,-1
    8000630c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000630e:	01205d63          	blez	s2,80006328 <virtio_disk_rw+0xa6>
    80006312:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006314:	000a2503          	lw	a0,0(s4)
    80006318:	00000097          	auipc	ra,0x0
    8000631c:	cfe080e7          	jalr	-770(ra) # 80006016 <free_desc>
      for(int j = 0; j < i; j++)
    80006320:	2d85                	addiw	s11,s11,1
    80006322:	0a11                	addi	s4,s4,4
    80006324:	ff2d98e3          	bne	s11,s2,80006314 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006328:	85e6                	mv	a1,s9
    8000632a:	0001c517          	auipc	a0,0x1c
    8000632e:	52e50513          	addi	a0,a0,1326 # 80022858 <disk+0x18>
    80006332:	ffffc097          	auipc	ra,0xffffc
    80006336:	d36080e7          	jalr	-714(ra) # 80002068 <sleep>
  for(int i = 0; i < 3; i++){
    8000633a:	f8040a13          	addi	s4,s0,-128
{
    8000633e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006340:	894e                	mv	s2,s3
    80006342:	b77d                	j	800062f0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006344:	f8042503          	lw	a0,-128(s0)
    80006348:	00a50713          	addi	a4,a0,10
    8000634c:	0712                	slli	a4,a4,0x4

  if(write)
    8000634e:	0001c797          	auipc	a5,0x1c
    80006352:	4f278793          	addi	a5,a5,1266 # 80022840 <disk>
    80006356:	00e786b3          	add	a3,a5,a4
    8000635a:	01803633          	snez	a2,s8
    8000635e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006360:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006364:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006368:	f6070613          	addi	a2,a4,-160
    8000636c:	6394                	ld	a3,0(a5)
    8000636e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006370:	00870593          	addi	a1,a4,8
    80006374:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006376:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006378:	0007b803          	ld	a6,0(a5)
    8000637c:	9642                	add	a2,a2,a6
    8000637e:	46c1                	li	a3,16
    80006380:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006382:	4585                	li	a1,1
    80006384:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006388:	f8442683          	lw	a3,-124(s0)
    8000638c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006390:	0692                	slli	a3,a3,0x4
    80006392:	9836                	add	a6,a6,a3
    80006394:	058a8613          	addi	a2,s5,88
    80006398:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000639c:	0007b803          	ld	a6,0(a5)
    800063a0:	96c2                	add	a3,a3,a6
    800063a2:	40000613          	li	a2,1024
    800063a6:	c690                	sw	a2,8(a3)
  if(write)
    800063a8:	001c3613          	seqz	a2,s8
    800063ac:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063b0:	00166613          	ori	a2,a2,1
    800063b4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063b8:	f8842603          	lw	a2,-120(s0)
    800063bc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063c0:	00250693          	addi	a3,a0,2
    800063c4:	0692                	slli	a3,a3,0x4
    800063c6:	96be                	add	a3,a3,a5
    800063c8:	58fd                	li	a7,-1
    800063ca:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063ce:	0612                	slli	a2,a2,0x4
    800063d0:	9832                	add	a6,a6,a2
    800063d2:	f9070713          	addi	a4,a4,-112
    800063d6:	973e                	add	a4,a4,a5
    800063d8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063dc:	6398                	ld	a4,0(a5)
    800063de:	9732                	add	a4,a4,a2
    800063e0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063e2:	4609                	li	a2,2
    800063e4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800063e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063ec:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800063f0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800063f4:	6794                	ld	a3,8(a5)
    800063f6:	0026d703          	lhu	a4,2(a3)
    800063fa:	8b1d                	andi	a4,a4,7
    800063fc:	0706                	slli	a4,a4,0x1
    800063fe:	96ba                	add	a3,a3,a4
    80006400:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006404:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006408:	6798                	ld	a4,8(a5)
    8000640a:	00275783          	lhu	a5,2(a4)
    8000640e:	2785                	addiw	a5,a5,1
    80006410:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006414:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006418:	100017b7          	lui	a5,0x10001
    8000641c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006420:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006424:	0001c917          	auipc	s2,0x1c
    80006428:	54490913          	addi	s2,s2,1348 # 80022968 <disk+0x128>
  while(b->disk == 1) {
    8000642c:	4485                	li	s1,1
    8000642e:	00b79c63          	bne	a5,a1,80006446 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006432:	85ca                	mv	a1,s2
    80006434:	8556                	mv	a0,s5
    80006436:	ffffc097          	auipc	ra,0xffffc
    8000643a:	c32080e7          	jalr	-974(ra) # 80002068 <sleep>
  while(b->disk == 1) {
    8000643e:	004aa783          	lw	a5,4(s5)
    80006442:	fe9788e3          	beq	a5,s1,80006432 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006446:	f8042903          	lw	s2,-128(s0)
    8000644a:	00290713          	addi	a4,s2,2
    8000644e:	0712                	slli	a4,a4,0x4
    80006450:	0001c797          	auipc	a5,0x1c
    80006454:	3f078793          	addi	a5,a5,1008 # 80022840 <disk>
    80006458:	97ba                	add	a5,a5,a4
    8000645a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000645e:	0001c997          	auipc	s3,0x1c
    80006462:	3e298993          	addi	s3,s3,994 # 80022840 <disk>
    80006466:	00491713          	slli	a4,s2,0x4
    8000646a:	0009b783          	ld	a5,0(s3)
    8000646e:	97ba                	add	a5,a5,a4
    80006470:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006474:	854a                	mv	a0,s2
    80006476:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000647a:	00000097          	auipc	ra,0x0
    8000647e:	b9c080e7          	jalr	-1124(ra) # 80006016 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006482:	8885                	andi	s1,s1,1
    80006484:	f0ed                	bnez	s1,80006466 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006486:	0001c517          	auipc	a0,0x1c
    8000648a:	4e250513          	addi	a0,a0,1250 # 80022968 <disk+0x128>
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	7fc080e7          	jalr	2044(ra) # 80000c8a <release>
}
    80006496:	70e6                	ld	ra,120(sp)
    80006498:	7446                	ld	s0,112(sp)
    8000649a:	74a6                	ld	s1,104(sp)
    8000649c:	7906                	ld	s2,96(sp)
    8000649e:	69e6                	ld	s3,88(sp)
    800064a0:	6a46                	ld	s4,80(sp)
    800064a2:	6aa6                	ld	s5,72(sp)
    800064a4:	6b06                	ld	s6,64(sp)
    800064a6:	7be2                	ld	s7,56(sp)
    800064a8:	7c42                	ld	s8,48(sp)
    800064aa:	7ca2                	ld	s9,40(sp)
    800064ac:	7d02                	ld	s10,32(sp)
    800064ae:	6de2                	ld	s11,24(sp)
    800064b0:	6109                	addi	sp,sp,128
    800064b2:	8082                	ret

00000000800064b4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064b4:	1101                	addi	sp,sp,-32
    800064b6:	ec06                	sd	ra,24(sp)
    800064b8:	e822                	sd	s0,16(sp)
    800064ba:	e426                	sd	s1,8(sp)
    800064bc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064be:	0001c497          	auipc	s1,0x1c
    800064c2:	38248493          	addi	s1,s1,898 # 80022840 <disk>
    800064c6:	0001c517          	auipc	a0,0x1c
    800064ca:	4a250513          	addi	a0,a0,1186 # 80022968 <disk+0x128>
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	708080e7          	jalr	1800(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064d6:	10001737          	lui	a4,0x10001
    800064da:	533c                	lw	a5,96(a4)
    800064dc:	8b8d                	andi	a5,a5,3
    800064de:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064e0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064e4:	689c                	ld	a5,16(s1)
    800064e6:	0204d703          	lhu	a4,32(s1)
    800064ea:	0027d783          	lhu	a5,2(a5)
    800064ee:	04f70863          	beq	a4,a5,8000653e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064f2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064f6:	6898                	ld	a4,16(s1)
    800064f8:	0204d783          	lhu	a5,32(s1)
    800064fc:	8b9d                	andi	a5,a5,7
    800064fe:	078e                	slli	a5,a5,0x3
    80006500:	97ba                	add	a5,a5,a4
    80006502:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006504:	00278713          	addi	a4,a5,2
    80006508:	0712                	slli	a4,a4,0x4
    8000650a:	9726                	add	a4,a4,s1
    8000650c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006510:	e721                	bnez	a4,80006558 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006512:	0789                	addi	a5,a5,2
    80006514:	0792                	slli	a5,a5,0x4
    80006516:	97a6                	add	a5,a5,s1
    80006518:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000651a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000651e:	ffffc097          	auipc	ra,0xffffc
    80006522:	bae080e7          	jalr	-1106(ra) # 800020cc <wakeup>

    disk.used_idx += 1;
    80006526:	0204d783          	lhu	a5,32(s1)
    8000652a:	2785                	addiw	a5,a5,1
    8000652c:	17c2                	slli	a5,a5,0x30
    8000652e:	93c1                	srli	a5,a5,0x30
    80006530:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006534:	6898                	ld	a4,16(s1)
    80006536:	00275703          	lhu	a4,2(a4)
    8000653a:	faf71ce3          	bne	a4,a5,800064f2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000653e:	0001c517          	auipc	a0,0x1c
    80006542:	42a50513          	addi	a0,a0,1066 # 80022968 <disk+0x128>
    80006546:	ffffa097          	auipc	ra,0xffffa
    8000654a:	744080e7          	jalr	1860(ra) # 80000c8a <release>
}
    8000654e:	60e2                	ld	ra,24(sp)
    80006550:	6442                	ld	s0,16(sp)
    80006552:	64a2                	ld	s1,8(sp)
    80006554:	6105                	addi	sp,sp,32
    80006556:	8082                	ret
      panic("virtio_disk_intr status");
    80006558:	00002517          	auipc	a0,0x2
    8000655c:	2f050513          	addi	a0,a0,752 # 80008848 <syscalls+0x3f8>
    80006560:	ffffa097          	auipc	ra,0xffffa
    80006564:	fe0080e7          	jalr	-32(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
