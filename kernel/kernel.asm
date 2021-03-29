
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c0c78793          	addi	a5,a5,-1012 # 80005c70 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	384080e7          	jalr	900(ra) # 800024a2 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7cc080e7          	jalr	1996(ra) # 8000197e <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e88080e7          	jalr	-376(ra) # 8000204a <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	24e080e7          	jalr	590(ra) # 8000244c <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	21a080e7          	jalr	538(ra) # 800024f8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	da4080e7          	jalr	-604(ra) # 800021d6 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	958080e7          	jalr	-1704(ra) # 800021d6 <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	740080e7          	jalr	1856(ra) # 8000204a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e06080e7          	jalr	-506(ra) # 80001962 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	dd4080e7          	jalr	-556(ra) # 80001962 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dc8080e7          	jalr	-568(ra) # 80001962 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	db0080e7          	jalr	-592(ra) # 80001962 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	d70080e7          	jalr	-656(ra) # 80001962 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d44080e7          	jalr	-700(ra) # 80001962 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	ade080e7          	jalr	-1314(ra) # 80001952 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	ac2080e7          	jalr	-1342(ra) # 80001952 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	788080e7          	jalr	1928(ra) # 8000263a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	df6080e7          	jalr	-522(ra) # 80005cb0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fd6080e7          	jalr	-42(ra) # 80001e98 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	980080e7          	jalr	-1664(ra) # 800018a2 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	6e8080e7          	jalr	1768(ra) # 80002612 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	708080e7          	jalr	1800(ra) # 8000263a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	d60080e7          	jalr	-672(ra) # 80005c9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	d6e080e7          	jalr	-658(ra) # 80005cb0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	f34080e7          	jalr	-204(ra) # 80002e7e <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	5c6080e7          	jalr	1478(ra) # 80003518 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	574080e7          	jalr	1396(ra) # 800044ce <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e70080e7          	jalr	-400(ra) # 80005dd2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	cf0080e7          	jalr	-784(ra) # 80001c5a <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	600080e7          	jalr	1536(ra) # 8000180c <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b2:	00b67d63          	bgeu	a2,a1,800013cc <uvmdealloc+0x26>
    800013b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b8:	6785                	lui	a5,0x1
    800013ba:	17fd                	addi	a5,a5,-1
    800013bc:	00f60733          	add	a4,a2,a5
    800013c0:	767d                	lui	a2,0xfffff
    800013c2:	8f71                	and	a4,a4,a2
    800013c4:	97ae                	add	a5,a5,a1
    800013c6:	8ff1                	and	a5,a5,a2
    800013c8:	00f76863          	bltu	a4,a5,800013d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d8:	8f99                	sub	a5,a5,a4
    800013da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013dc:	4685                	li	a3,1
    800013de:	0007861b          	sext.w	a2,a5
    800013e2:	85ba                	mv	a1,a4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	e5e080e7          	jalr	-418(ra) # 80001242 <uvmunmap>
    800013ec:	b7c5                	j	800013cc <uvmdealloc+0x26>

00000000800013ee <uvmalloc>:
  if(newsz < oldsz)
    800013ee:	0ab66163          	bltu	a2,a1,80001490 <uvmalloc+0xa2>
{
    800013f2:	7139                	addi	sp,sp,-64
    800013f4:	fc06                	sd	ra,56(sp)
    800013f6:	f822                	sd	s0,48(sp)
    800013f8:	f426                	sd	s1,40(sp)
    800013fa:	f04a                	sd	s2,32(sp)
    800013fc:	ec4e                	sd	s3,24(sp)
    800013fe:	e852                	sd	s4,16(sp)
    80001400:	e456                	sd	s5,8(sp)
    80001402:	0080                	addi	s0,sp,64
    80001404:	8aaa                	mv	s5,a0
    80001406:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001408:	6985                	lui	s3,0x1
    8000140a:	19fd                	addi	s3,s3,-1
    8000140c:	95ce                	add	a1,a1,s3
    8000140e:	79fd                	lui	s3,0xfffff
    80001410:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001414:	08c9f063          	bgeu	s3,a2,80001494 <uvmalloc+0xa6>
    80001418:	894e                	mv	s2,s3
    mem = kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	6b8080e7          	jalr	1720(ra) # 80000ad2 <kalloc>
    80001422:	84aa                	mv	s1,a0
    if(mem == 0){
    80001424:	c51d                	beqz	a0,80001452 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	894080e7          	jalr	-1900(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001432:	4779                	li	a4,30
    80001434:	86a6                	mv	a3,s1
    80001436:	6605                	lui	a2,0x1
    80001438:	85ca                	mv	a1,s2
    8000143a:	8556                	mv	a0,s5
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	c52080e7          	jalr	-942(ra) # 8000108e <mappages>
    80001444:	e905                	bnez	a0,80001474 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	6785                	lui	a5,0x1
    80001448:	993e                	add	s2,s2,a5
    8000144a:	fd4968e3          	bltu	s2,s4,8000141a <uvmalloc+0x2c>
  return newsz;
    8000144e:	8552                	mv	a0,s4
    80001450:	a809                	j	80001462 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001452:	864e                	mv	a2,s3
    80001454:	85ca                	mv	a1,s2
    80001456:	8556                	mv	a0,s5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f4e080e7          	jalr	-178(ra) # 800013a6 <uvmdealloc>
      return 0;
    80001460:	4501                	li	a0,0
}
    80001462:	70e2                	ld	ra,56(sp)
    80001464:	7442                	ld	s0,48(sp)
    80001466:	74a2                	ld	s1,40(sp)
    80001468:	7902                	ld	s2,32(sp)
    8000146a:	69e2                	ld	s3,24(sp)
    8000146c:	6a42                	ld	s4,16(sp)
    8000146e:	6aa2                	ld	s5,8(sp)
    80001470:	6121                	addi	sp,sp,64
    80001472:	8082                	ret
      kfree(mem);
    80001474:	8526                	mv	a0,s1
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	560080e7          	jalr	1376(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000147e:	864e                	mv	a2,s3
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f22080e7          	jalr	-222(ra) # 800013a6 <uvmdealloc>
      return 0;
    8000148c:	4501                	li	a0,0
    8000148e:	bfd1                	j	80001462 <uvmalloc+0x74>
    return oldsz;
    80001490:	852e                	mv	a0,a1
}
    80001492:	8082                	ret
  return newsz;
    80001494:	8532                	mv	a0,a2
    80001496:	b7f1                	j	80001462 <uvmalloc+0x74>

0000000080001498 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
    800014a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014aa:	84aa                	mv	s1,a0
    800014ac:	6905                	lui	s2,0x1
    800014ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b0:	4985                	li	s3,1
    800014b2:	a821                	j	800014ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b6:	0532                	slli	a0,a0,0xc
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	fe0080e7          	jalr	-32(ra) # 80001498 <freewalk>
      pagetable[i] = 0;
    800014c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014c4:	04a1                	addi	s1,s1,8
    800014c6:	03248163          	beq	s1,s2,800014e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014cc:	00f57793          	andi	a5,a0,15
    800014d0:	ff3782e3          	beq	a5,s3,800014b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014d4:	8905                	andi	a0,a0,1
    800014d6:	d57d                	beqz	a0,800014c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c8850513          	addi	a0,a0,-888 # 80008160 <digits+0x120>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014e8:	8552                	mv	a0,s4
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4ec080e7          	jalr	1260(ra) # 800009d6 <kfree>
}
    800014f2:	70a2                	ld	ra,40(sp)
    800014f4:	7402                	ld	s0,32(sp)
    800014f6:	64e2                	ld	s1,24(sp)
    800014f8:	6942                	ld	s2,16(sp)
    800014fa:	69a2                	ld	s3,8(sp)
    800014fc:	6a02                	ld	s4,0(sp)
    800014fe:	6145                	addi	sp,sp,48
    80001500:	8082                	ret

0000000080001502 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
    8000150c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000150e:	e999                	bnez	a1,80001524 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001510:	8526                	mv	a0,s1
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f86080e7          	jalr	-122(ra) # 80001498 <freewalk>
}
    8000151a:	60e2                	ld	ra,24(sp)
    8000151c:	6442                	ld	s0,16(sp)
    8000151e:	64a2                	ld	s1,8(sp)
    80001520:	6105                	addi	sp,sp,32
    80001522:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001524:	6605                	lui	a2,0x1
    80001526:	167d                	addi	a2,a2,-1
    80001528:	962e                	add	a2,a2,a1
    8000152a:	4685                	li	a3,1
    8000152c:	8231                	srli	a2,a2,0xc
    8000152e:	4581                	li	a1,0
    80001530:	00000097          	auipc	ra,0x0
    80001534:	d12080e7          	jalr	-750(ra) # 80001242 <uvmunmap>
    80001538:	bfe1                	j	80001510 <uvmfree+0xe>

000000008000153a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000153a:	c679                	beqz	a2,80001608 <uvmcopy+0xce>
{
    8000153c:	715d                	addi	sp,sp,-80
    8000153e:	e486                	sd	ra,72(sp)
    80001540:	e0a2                	sd	s0,64(sp)
    80001542:	fc26                	sd	s1,56(sp)
    80001544:	f84a                	sd	s2,48(sp)
    80001546:	f44e                	sd	s3,40(sp)
    80001548:	f052                	sd	s4,32(sp)
    8000154a:	ec56                	sd	s5,24(sp)
    8000154c:	e85a                	sd	s6,16(sp)
    8000154e:	e45e                	sd	s7,8(sp)
    80001550:	0880                	addi	s0,sp,80
    80001552:	8b2a                	mv	s6,a0
    80001554:	8aae                	mv	s5,a1
    80001556:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001558:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000155a:	4601                	li	a2,0
    8000155c:	85ce                	mv	a1,s3
    8000155e:	855a                	mv	a0,s6
    80001560:	00000097          	auipc	ra,0x0
    80001564:	a46080e7          	jalr	-1466(ra) # 80000fa6 <walk>
    80001568:	c531                	beqz	a0,800015b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000156a:	6118                	ld	a4,0(a0)
    8000156c:	00177793          	andi	a5,a4,1
    80001570:	cbb1                	beqz	a5,800015c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001572:	00a75593          	srli	a1,a4,0xa
    80001576:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000157a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	554080e7          	jalr	1364(ra) # 80000ad2 <kalloc>
    80001586:	892a                	mv	s2,a0
    80001588:	c939                	beqz	a0,800015de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	85de                	mv	a1,s7
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	78c080e7          	jalr	1932(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001596:	8726                	mv	a4,s1
    80001598:	86ca                	mv	a3,s2
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	aee080e7          	jalr	-1298(ra) # 8000108e <mappages>
    800015a8:	e515                	bnez	a0,800015d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	99be                	add	s3,s3,a5
    800015ae:	fb49e6e3          	bltu	s3,s4,8000155a <uvmcopy+0x20>
    800015b2:	a081                	j	800015f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bbc50513          	addi	a0,a0,-1092 # 80008170 <digits+0x130>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bcc50513          	addi	a0,a0,-1076 # 80008190 <digits+0x150>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      kfree(mem);
    800015d4:	854a                	mv	a0,s2
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	400080e7          	jalr	1024(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015de:	4685                	li	a3,1
    800015e0:	00c9d613          	srli	a2,s3,0xc
    800015e4:	4581                	li	a1,0
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	c5a080e7          	jalr	-934(ra) # 80001242 <uvmunmap>
  return -1;
    800015f0:	557d                	li	a0,-1
}
    800015f2:	60a6                	ld	ra,72(sp)
    800015f4:	6406                	ld	s0,64(sp)
    800015f6:	74e2                	ld	s1,56(sp)
    800015f8:	7942                	ld	s2,48(sp)
    800015fa:	79a2                	ld	s3,40(sp)
    800015fc:	7a02                	ld	s4,32(sp)
    800015fe:	6ae2                	ld	s5,24(sp)
    80001600:	6b42                	ld	s6,16(sp)
    80001602:	6ba2                	ld	s7,8(sp)
    80001604:	6161                	addi	sp,sp,80
    80001606:	8082                	ret
  return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	8082                	ret

000000008000160c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160c:	1141                	addi	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001614:	4601                	li	a2,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	990080e7          	jalr	-1648(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000161e:	c901                	beqz	a0,8000162e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001620:	611c                	ld	a5,0(a0)
    80001622:	9bbd                	andi	a5,a5,-17
    80001624:	e11c                	sd	a5,0(a0)
}
    80001626:	60a2                	ld	ra,8(sp)
    80001628:	6402                	ld	s0,0(sp)
    8000162a:	0141                	addi	sp,sp,16
    8000162c:	8082                	ret
    panic("uvmclear");
    8000162e:	00007517          	auipc	a0,0x7
    80001632:	b8250513          	addi	a0,a0,-1150 # 800081b0 <digits+0x170>
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>

000000008000163e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163e:	c6bd                	beqz	a3,800016ac <copyout+0x6e>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	e062                	sd	s8,0(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8c2e                	mv	s8,a1
    8000165c:	8a32                	mv	s4,a2
    8000165e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001660:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001662:	6a85                	lui	s5,0x1
    80001664:	a015                	j	80001688 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001666:	9562                	add	a0,a0,s8
    80001668:	0004861b          	sext.w	a2,s1
    8000166c:	85d2                	mv	a1,s4
    8000166e:	41250533          	sub	a0,a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>

    len -= n;
    8000167a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001680:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001684:	02098263          	beqz	s3,800016a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001688:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168c:	85ca                	mv	a1,s2
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	9bc080e7          	jalr	-1604(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001698:	cd01                	beqz	a0,800016b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000169a:	418904b3          	sub	s1,s2,s8
    8000169e:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a0:	fc99f3e3          	bgeu	s3,s1,80001666 <copyout+0x28>
    800016a4:	84ce                	mv	s1,s3
    800016a6:	b7c1                	j	80001666 <copyout+0x28>
  }
  return 0;
    800016a8:	4501                	li	a0,0
    800016aa:	a021                	j	800016b2 <copyout+0x74>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
}
    800016b2:	60a6                	ld	ra,72(sp)
    800016b4:	6406                	ld	s0,64(sp)
    800016b6:	74e2                	ld	s1,56(sp)
    800016b8:	7942                	ld	s2,48(sp)
    800016ba:	79a2                	ld	s3,40(sp)
    800016bc:	7a02                	ld	s4,32(sp)
    800016be:	6ae2                	ld	s5,24(sp)
    800016c0:	6b42                	ld	s6,16(sp)
    800016c2:	6ba2                	ld	s7,8(sp)
    800016c4:	6c02                	ld	s8,0(sp)
    800016c6:	6161                	addi	sp,sp,80
    800016c8:	8082                	ret

00000000800016ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	caa5                	beqz	a3,8000173a <copyin+0x70>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	8c32                	mv	s8,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a01d                	j	80001716 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f2:	018505b3          	add	a1,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	412585b3          	sub	a1,a1,s2
    800016fe:	8552                	mv	a0,s4
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	61a080e7          	jalr	1562(ra) # 80000d1a <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000170c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	92e080e7          	jalr	-1746(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f2e3          	bgeu	s3,s1,800016f2 <copyin+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	bf7d                	j	800016f2 <copyin+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyin+0x76>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001758:	c6c5                	beqz	a3,80001800 <copyinstr+0xa8>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8a2a                	mv	s4,a0
    80001772:	8b2e                	mv	s6,a1
    80001774:	8bb2                	mv	s7,a2
    80001776:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6985                	lui	s3,0x1
    8000177c:	a035                	j	800017a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001782:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001784:	0017b793          	seqz	a5,a5
    80001788:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a6:	c8a9                	beqz	s1,800017f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	8552                	mv	a0,s4
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	89c080e7          	jalr	-1892(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017b8:	c131                	beqz	a0,800017fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ba:	41790833          	sub	a6,s2,s7
    800017be:	984e                	add	a6,a6,s3
    if(n > max)
    800017c0:	0104f363          	bgeu	s1,a6,800017c6 <copyinstr+0x6e>
    800017c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c6:	955e                	add	a0,a0,s7
    800017c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017cc:	fc080be3          	beqz	a6,800017a2 <copyinstr+0x4a>
    800017d0:	985a                	add	a6,a6,s6
    800017d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d4:	41650633          	sub	a2,a0,s6
    800017d8:	14fd                	addi	s1,s1,-1
    800017da:	9b26                	add	s6,s6,s1
    800017dc:	00f60733          	add	a4,a2,a5
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017e4:	df49                	beqz	a4,8000177e <copyinstr+0x26>
        *dst = *p;
    800017e6:	00e78023          	sb	a4,0(a5)
      --max;
    800017ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f0:	ff0796e3          	bne	a5,a6,800017dc <copyinstr+0x84>
      dst++;
    800017f4:	8b42                	mv	s6,a6
    800017f6:	b775                	j	800017a2 <copyinstr+0x4a>
    800017f8:	4781                	li	a5,0
    800017fa:	b769                	j	80001784 <copyinstr+0x2c>
      return -1;
    800017fc:	557d                	li	a0,-1
    800017fe:	b779                	j	8000178c <copyinstr+0x34>
  int got_null = 0;
    80001800:	4781                	li	a5,0
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
}
    8000180a:	8082                	ret

000000008000180c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000180c:	7139                	addi	sp,sp,-64
    8000180e:	fc06                	sd	ra,56(sp)
    80001810:	f822                	sd	s0,48(sp)
    80001812:	f426                	sd	s1,40(sp)
    80001814:	f04a                	sd	s2,32(sp)
    80001816:	ec4e                	sd	s3,24(sp)
    80001818:	e852                	sd	s4,16(sp)
    8000181a:	e456                	sd	s5,8(sp)
    8000181c:	e05a                	sd	s6,0(sp)
    8000181e:	0080                	addi	s0,sp,64
    80001820:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001822:	00010497          	auipc	s1,0x10
    80001826:	eae48493          	addi	s1,s1,-338 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000182a:	8b26                	mv	s6,s1
    8000182c:	00006a97          	auipc	s5,0x6
    80001830:	7d4a8a93          	addi	s5,s5,2004 # 80008000 <etext>
    80001834:	04000937          	lui	s2,0x4000
    80001838:	197d                	addi	s2,s2,-1
    8000183a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183c:	00016a17          	auipc	s4,0x16
    80001840:	894a0a13          	addi	s4,s4,-1900 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
    if(pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	858d                	srai	a1,a1,0x3
    80001856:	000ab783          	ld	a5,0(s5)
    8000185a:	02f585b3          	mul	a1,a1,a5
    8000185e:	2585                	addiw	a1,a1,1
    80001860:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001864:	4719                	li	a4,6
    80001866:	6685                	lui	a3,0x1
    80001868:	40b905b3          	sub	a1,s2,a1
    8000186c:	854e                	mv	a0,s3
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	8ae080e7          	jalr	-1874(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	16848493          	addi	s1,s1,360
    8000187a:	fd4495e3          	bne	s1,s4,80001844 <proc_mapstacks+0x38>
  }
}
    8000187e:	70e2                	ld	ra,56(sp)
    80001880:	7442                	ld	s0,48(sp)
    80001882:	74a2                	ld	s1,40(sp)
    80001884:	7902                	ld	s2,32(sp)
    80001886:	69e2                	ld	s3,24(sp)
    80001888:	6a42                	ld	s4,16(sp)
    8000188a:	6aa2                	ld	s5,8(sp)
    8000188c:	6b02                	ld	s6,0(sp)
    8000188e:	6121                	addi	sp,sp,64
    80001890:	8082                	ret
      panic("kalloc");
    80001892:	00007517          	auipc	a0,0x7
    80001896:	92e50513          	addi	a0,a0,-1746 # 800081c0 <digits+0x180>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	c90080e7          	jalr	-880(ra) # 8000052a <panic>

00000000800018a2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018a2:	7139                	addi	sp,sp,-64
    800018a4:	fc06                	sd	ra,56(sp)
    800018a6:	f822                	sd	s0,48(sp)
    800018a8:	f426                	sd	s1,40(sp)
    800018aa:	f04a                	sd	s2,32(sp)
    800018ac:	ec4e                	sd	s3,24(sp)
    800018ae:	e852                	sd	s4,16(sp)
    800018b0:	e456                	sd	s5,8(sp)
    800018b2:	e05a                	sd	s6,0(sp)
    800018b4:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018b6:	00007597          	auipc	a1,0x7
    800018ba:	91258593          	addi	a1,a1,-1774 # 800081c8 <digits+0x188>
    800018be:	00010517          	auipc	a0,0x10
    800018c2:	9e250513          	addi	a0,a0,-1566 # 800112a0 <pid_lock>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	26c080e7          	jalr	620(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	90258593          	addi	a1,a1,-1790 # 800081d0 <digits+0x190>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9e250513          	addi	a0,a0,-1566 # 800112b8 <wait_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	254080e7          	jalr	596(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018e6:	00010497          	auipc	s1,0x10
    800018ea:	dea48493          	addi	s1,s1,-534 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    800018ee:	00007b17          	auipc	s6,0x7
    800018f2:	8f2b0b13          	addi	s6,s6,-1806 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    800018f6:	8aa6                	mv	s5,s1
    800018f8:	00006a17          	auipc	s4,0x6
    800018fc:	708a0a13          	addi	s4,s4,1800 # 80008000 <etext>
    80001900:	04000937          	lui	s2,0x4000
    80001904:	197d                	addi	s2,s2,-1
    80001906:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001908:	00015997          	auipc	s3,0x15
    8000190c:	7c898993          	addi	s3,s3,1992 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	878d                	srai	a5,a5,0x3
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	16848493          	addi	s1,s1,360
    8000193a:	fd349be3          	bne	s1,s3,80001910 <procinit+0x6e>
  }
}
    8000193e:	70e2                	ld	ra,56(sp)
    80001940:	7442                	ld	s0,48(sp)
    80001942:	74a2                	ld	s1,40(sp)
    80001944:	7902                	ld	s2,32(sp)
    80001946:	69e2                	ld	s3,24(sp)
    80001948:	6a42                	ld	s4,16(sp)
    8000194a:	6aa2                	ld	s5,8(sp)
    8000194c:	6b02                	ld	s6,0(sp)
    8000194e:	6121                	addi	sp,sp,64
    80001950:	8082                	ret

0000000080001952 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001952:	1141                	addi	sp,sp,-16
    80001954:	e422                	sd	s0,8(sp)
    80001956:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001958:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000195a:	2501                	sext.w	a0,a0
    8000195c:	6422                	ld	s0,8(sp)
    8000195e:	0141                	addi	sp,sp,16
    80001960:	8082                	ret

0000000080001962 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001962:	1141                	addi	sp,sp,-16
    80001964:	e422                	sd	s0,8(sp)
    80001966:	0800                	addi	s0,sp,16
    80001968:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000196a:	2781                	sext.w	a5,a5
    8000196c:	079e                	slli	a5,a5,0x7
  return c;
}
    8000196e:	00010517          	auipc	a0,0x10
    80001972:	96250513          	addi	a0,a0,-1694 # 800112d0 <cpus>
    80001976:	953e                	add	a0,a0,a5
    80001978:	6422                	ld	s0,8(sp)
    8000197a:	0141                	addi	sp,sp,16
    8000197c:	8082                	ret

000000008000197e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000197e:	1101                	addi	sp,sp,-32
    80001980:	ec06                	sd	ra,24(sp)
    80001982:	e822                	sd	s0,16(sp)
    80001984:	e426                	sd	s1,8(sp)
    80001986:	1000                	addi	s0,sp,32
  push_off();
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1ee080e7          	jalr	494(ra) # 80000b76 <push_off>
    80001990:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
    80001996:	00010717          	auipc	a4,0x10
    8000199a:	90a70713          	addi	a4,a4,-1782 # 800112a0 <pid_lock>
    8000199e:	97ba                	add	a5,a5,a4
    800019a0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	274080e7          	jalr	628(ra) # 80000c16 <pop_off>
  return p;
}
    800019aa:	8526                	mv	a0,s1
    800019ac:	60e2                	ld	ra,24(sp)
    800019ae:	6442                	ld	s0,16(sp)
    800019b0:	64a2                	ld	s1,8(sp)
    800019b2:	6105                	addi	sp,sp,32
    800019b4:	8082                	ret

00000000800019b6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e406                	sd	ra,8(sp)
    800019ba:	e022                	sd	s0,0(sp)
    800019bc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	fc0080e7          	jalr	-64(ra) # 8000197e <myproc>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	2b0080e7          	jalr	688(ra) # 80000c76 <release>

  if (first) {
    800019ce:	00007797          	auipc	a5,0x7
    800019d2:	f327a783          	lw	a5,-206(a5) # 80008900 <first.1>
    800019d6:	eb89                	bnez	a5,800019e8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019d8:	00001097          	auipc	ra,0x1
    800019dc:	c7a080e7          	jalr	-902(ra) # 80002652 <usertrapret>
}
    800019e0:	60a2                	ld	ra,8(sp)
    800019e2:	6402                	ld	s0,0(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret
    first = 0;
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	f007ac23          	sw	zero,-232(a5) # 80008900 <first.1>
    fsinit(ROOTDEV);
    800019f0:	4505                	li	a0,1
    800019f2:	00002097          	auipc	ra,0x2
    800019f6:	aa6080e7          	jalr	-1370(ra) # 80003498 <fsinit>
    800019fa:	bff9                	j	800019d8 <forkret+0x22>

00000000800019fc <allocpid>:
allocpid() {
    800019fc:	1101                	addi	sp,sp,-32
    800019fe:	ec06                	sd	ra,24(sp)
    80001a00:	e822                	sd	s0,16(sp)
    80001a02:	e426                	sd	s1,8(sp)
    80001a04:	e04a                	sd	s2,0(sp)
    80001a06:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a08:	00010917          	auipc	s2,0x10
    80001a0c:	89890913          	addi	s2,s2,-1896 # 800112a0 <pid_lock>
    80001a10:	854a                	mv	a0,s2
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	1b0080e7          	jalr	432(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	eea78793          	addi	a5,a5,-278 # 80008904 <nextpid>
    80001a22:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a24:	0014871b          	addiw	a4,s1,1
    80001a28:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a2a:	854a                	mv	a0,s2
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	24a080e7          	jalr	586(ra) # 80000c76 <release>
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6902                	ld	s2,0(sp)
    80001a3e:	6105                	addi	sp,sp,32
    80001a40:	8082                	ret

0000000080001a42 <proc_pagetable>:
{
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	e04a                	sd	s2,0(sp)
    80001a4c:	1000                	addi	s0,sp,32
    80001a4e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	8b6080e7          	jalr	-1866(ra) # 80001306 <uvmcreate>
    80001a58:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a5a:	c121                	beqz	a0,80001a9a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a5c:	4729                	li	a4,10
    80001a5e:	00005697          	auipc	a3,0x5
    80001a62:	5a268693          	addi	a3,a3,1442 # 80007000 <_trampoline>
    80001a66:	6605                	lui	a2,0x1
    80001a68:	040005b7          	lui	a1,0x4000
    80001a6c:	15fd                	addi	a1,a1,-1
    80001a6e:	05b2                	slli	a1,a1,0xc
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	61e080e7          	jalr	1566(ra) # 8000108e <mappages>
    80001a78:	02054863          	bltz	a0,80001aa8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a7c:	4719                	li	a4,6
    80001a7e:	05893683          	ld	a3,88(s2)
    80001a82:	6605                	lui	a2,0x1
    80001a84:	020005b7          	lui	a1,0x2000
    80001a88:	15fd                	addi	a1,a1,-1
    80001a8a:	05b6                	slli	a1,a1,0xd
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	600080e7          	jalr	1536(ra) # 8000108e <mappages>
    80001a96:	02054163          	bltz	a0,80001ab8 <proc_pagetable+0x76>
}
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	60e2                	ld	ra,24(sp)
    80001a9e:	6442                	ld	s0,16(sp)
    80001aa0:	64a2                	ld	s1,8(sp)
    80001aa2:	6902                	ld	s2,0(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret
    uvmfree(pagetable, 0);
    80001aa8:	4581                	li	a1,0
    80001aaa:	8526                	mv	a0,s1
    80001aac:	00000097          	auipc	ra,0x0
    80001ab0:	a56080e7          	jalr	-1450(ra) # 80001502 <uvmfree>
    return 0;
    80001ab4:	4481                	li	s1,0
    80001ab6:	b7d5                	j	80001a9a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ab8:	4681                	li	a3,0
    80001aba:	4605                	li	a2,1
    80001abc:	040005b7          	lui	a1,0x4000
    80001ac0:	15fd                	addi	a1,a1,-1
    80001ac2:	05b2                	slli	a1,a1,0xc
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	77c080e7          	jalr	1916(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ace:	4581                	li	a1,0
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	a30080e7          	jalr	-1488(ra) # 80001502 <uvmfree>
    return 0;
    80001ada:	4481                	li	s1,0
    80001adc:	bf7d                	j	80001a9a <proc_pagetable+0x58>

0000000080001ade <proc_freepagetable>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	e04a                	sd	s2,0(sp)
    80001ae8:	1000                	addi	s0,sp,32
    80001aea:	84aa                	mv	s1,a0
    80001aec:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	748080e7          	jalr	1864(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	020005b7          	lui	a1,0x2000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b6                	slli	a1,a1,0xd
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	732080e7          	jalr	1842(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b18:	85ca                	mv	a1,s2
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	9e6080e7          	jalr	-1562(ra) # 80001502 <uvmfree>
}
    80001b24:	60e2                	ld	ra,24(sp)
    80001b26:	6442                	ld	s0,16(sp)
    80001b28:	64a2                	ld	s1,8(sp)
    80001b2a:	6902                	ld	s2,0(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <freeproc>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b3c:	6d28                	ld	a0,88(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b48:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b4c:	68a8                	ld	a0,80(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b50:	64ac                	ld	a1,72(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
  p->pagetable = 0;
    80001b5a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b5e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b66:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b6a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b6e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b72:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b76:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b7a:	0004ac23          	sw	zero,24(s1)
}
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <allocproc>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b94:	00010497          	auipc	s1,0x10
    80001b98:	b3c48493          	addi	s1,s1,-1220 # 800116d0 <proc>
    80001b9c:	00015917          	auipc	s2,0x15
    80001ba0:	53490913          	addi	s2,s2,1332 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	01c080e7          	jalr	28(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bae:	4c9c                	lw	a5,24(s1)
    80001bb0:	cf81                	beqz	a5,80001bc8 <allocproc+0x40>
      release(&p->lock);
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	0c2080e7          	jalr	194(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbc:	16848493          	addi	s1,s1,360
    80001bc0:	ff2492e3          	bne	s1,s2,80001ba4 <allocproc+0x1c>
  return 0;
    80001bc4:	4481                	li	s1,0
    80001bc6:	a899                	j	80001c1c <allocproc+0x94>
  p->pid = allocpid();
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	e34080e7          	jalr	-460(ra) # 800019fc <allocpid>
    80001bd0:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bd2:	4785                	li	a5,1
    80001bd4:	cc9c                	sw	a5,24(s1)
  p->mask = 0;
    80001bd6:	0204aa23          	sw	zero,52(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	ef8080e7          	jalr	-264(ra) # 80000ad2 <kalloc>
    80001be2:	892a                	mv	s2,a0
    80001be4:	eca8                	sd	a0,88(s1)
    80001be6:	c131                	beqz	a0,80001c2a <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001be8:	8526                	mv	a0,s1
    80001bea:	00000097          	auipc	ra,0x0
    80001bee:	e58080e7          	jalr	-424(ra) # 80001a42 <proc_pagetable>
    80001bf2:	892a                	mv	s2,a0
    80001bf4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bf6:	c531                	beqz	a0,80001c42 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001bf8:	07000613          	li	a2,112
    80001bfc:	4581                	li	a1,0
    80001bfe:	06048513          	addi	a0,s1,96
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	0bc080e7          	jalr	188(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c0a:	00000797          	auipc	a5,0x0
    80001c0e:	dac78793          	addi	a5,a5,-596 # 800019b6 <forkret>
    80001c12:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c14:	60bc                	ld	a5,64(s1)
    80001c16:	6705                	lui	a4,0x1
    80001c18:	97ba                	add	a5,a5,a4
    80001c1a:	f4bc                	sd	a5,104(s1)
}
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	60e2                	ld	ra,24(sp)
    80001c20:	6442                	ld	s0,16(sp)
    80001c22:	64a2                	ld	s1,8(sp)
    80001c24:	6902                	ld	s2,0(sp)
    80001c26:	6105                	addi	sp,sp,32
    80001c28:	8082                	ret
    freeproc(p);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	f04080e7          	jalr	-252(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	040080e7          	jalr	64(ra) # 80000c76 <release>
    return 0;
    80001c3e:	84ca                	mv	s1,s2
    80001c40:	bff1                	j	80001c1c <allocproc+0x94>
    freeproc(p);
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	eec080e7          	jalr	-276(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	028080e7          	jalr	40(ra) # 80000c76 <release>
    return 0;
    80001c56:	84ca                	mv	s1,s2
    80001c58:	b7d1                	j	80001c1c <allocproc+0x94>

0000000080001c5a <userinit>:
{
    80001c5a:	1101                	addi	sp,sp,-32
    80001c5c:	ec06                	sd	ra,24(sp)
    80001c5e:	e822                	sd	s0,16(sp)
    80001c60:	e426                	sd	s1,8(sp)
    80001c62:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	f24080e7          	jalr	-220(ra) # 80001b88 <allocproc>
    80001c6c:	84aa                	mv	s1,a0
  initproc = p;
    80001c6e:	00007797          	auipc	a5,0x7
    80001c72:	3aa7bd23          	sd	a0,954(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c76:	03400613          	li	a2,52
    80001c7a:	00007597          	auipc	a1,0x7
    80001c7e:	c9658593          	addi	a1,a1,-874 # 80008910 <initcode>
    80001c82:	6928                	ld	a0,80(a0)
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	6b0080e7          	jalr	1712(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001c8c:	6785                	lui	a5,0x1
    80001c8e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001c90:	6cb8                	ld	a4,88(s1)
    80001c92:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001c96:	6cb8                	ld	a4,88(s1)
    80001c98:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001c9a:	4641                	li	a2,16
    80001c9c:	00006597          	auipc	a1,0x6
    80001ca0:	54c58593          	addi	a1,a1,1356 # 800081e8 <digits+0x1a8>
    80001ca4:	15848513          	addi	a0,s1,344
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	168080e7          	jalr	360(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cb0:	00006517          	auipc	a0,0x6
    80001cb4:	54850513          	addi	a0,a0,1352 # 800081f8 <digits+0x1b8>
    80001cb8:	00002097          	auipc	ra,0x2
    80001cbc:	20e080e7          	jalr	526(ra) # 80003ec6 <namei>
    80001cc0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cc4:	478d                	li	a5,3
    80001cc6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	fac080e7          	jalr	-84(ra) # 80000c76 <release>
}
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6105                	addi	sp,sp,32
    80001cda:	8082                	ret

0000000080001cdc <growproc>:
{
    80001cdc:	1101                	addi	sp,sp,-32
    80001cde:	ec06                	sd	ra,24(sp)
    80001ce0:	e822                	sd	s0,16(sp)
    80001ce2:	e426                	sd	s1,8(sp)
    80001ce4:	e04a                	sd	s2,0(sp)
    80001ce6:	1000                	addi	s0,sp,32
    80001ce8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	c94080e7          	jalr	-876(ra) # 8000197e <myproc>
    80001cf2:	892a                	mv	s2,a0
  sz = p->sz;
    80001cf4:	652c                	ld	a1,72(a0)
    80001cf6:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001cfa:	00904f63          	bgtz	s1,80001d18 <growproc+0x3c>
  } else if(n < 0){
    80001cfe:	0204cc63          	bltz	s1,80001d36 <growproc+0x5a>
  p->sz = sz;
    80001d02:	1602                	slli	a2,a2,0x20
    80001d04:	9201                	srli	a2,a2,0x20
    80001d06:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d0a:	4501                	li	a0,0
}
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6902                	ld	s2,0(sp)
    80001d14:	6105                	addi	sp,sp,32
    80001d16:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d18:	9e25                	addw	a2,a2,s1
    80001d1a:	1602                	slli	a2,a2,0x20
    80001d1c:	9201                	srli	a2,a2,0x20
    80001d1e:	1582                	slli	a1,a1,0x20
    80001d20:	9181                	srli	a1,a1,0x20
    80001d22:	6928                	ld	a0,80(a0)
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	6ca080e7          	jalr	1738(ra) # 800013ee <uvmalloc>
    80001d2c:	0005061b          	sext.w	a2,a0
    80001d30:	fa69                	bnez	a2,80001d02 <growproc+0x26>
      return -1;
    80001d32:	557d                	li	a0,-1
    80001d34:	bfe1                	j	80001d0c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d36:	9e25                	addw	a2,a2,s1
    80001d38:	1602                	slli	a2,a2,0x20
    80001d3a:	9201                	srli	a2,a2,0x20
    80001d3c:	1582                	slli	a1,a1,0x20
    80001d3e:	9181                	srli	a1,a1,0x20
    80001d40:	6928                	ld	a0,80(a0)
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	664080e7          	jalr	1636(ra) # 800013a6 <uvmdealloc>
    80001d4a:	0005061b          	sext.w	a2,a0
    80001d4e:	bf55                	j	80001d02 <growproc+0x26>

0000000080001d50 <fork>:
{
    80001d50:	7139                	addi	sp,sp,-64
    80001d52:	fc06                	sd	ra,56(sp)
    80001d54:	f822                	sd	s0,48(sp)
    80001d56:	f426                	sd	s1,40(sp)
    80001d58:	f04a                	sd	s2,32(sp)
    80001d5a:	ec4e                	sd	s3,24(sp)
    80001d5c:	e852                	sd	s4,16(sp)
    80001d5e:	e456                	sd	s5,8(sp)
    80001d60:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d62:	00000097          	auipc	ra,0x0
    80001d66:	c1c080e7          	jalr	-996(ra) # 8000197e <myproc>
    80001d6a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	e1c080e7          	jalr	-484(ra) # 80001b88 <allocproc>
    80001d74:	12050063          	beqz	a0,80001e94 <fork+0x144>
    80001d78:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d7a:	048ab603          	ld	a2,72(s5)
    80001d7e:	692c                	ld	a1,80(a0)
    80001d80:	050ab503          	ld	a0,80(s5)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	7b6080e7          	jalr	1974(ra) # 8000153a <uvmcopy>
    80001d8c:	04054c63          	bltz	a0,80001de4 <fork+0x94>
  np->sz = p->sz;
    80001d90:	048ab783          	ld	a5,72(s5)
    80001d94:	04f9b423          	sd	a5,72(s3)
  np->mask = p->mask;
    80001d98:	034aa783          	lw	a5,52(s5)
    80001d9c:	02f9aa23          	sw	a5,52(s3)
  *(np->trapframe) = *(p->trapframe);
    80001da0:	058ab683          	ld	a3,88(s5)
    80001da4:	87b6                	mv	a5,a3
    80001da6:	0589b703          	ld	a4,88(s3)
    80001daa:	12068693          	addi	a3,a3,288
    80001dae:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001db2:	6788                	ld	a0,8(a5)
    80001db4:	6b8c                	ld	a1,16(a5)
    80001db6:	6f90                	ld	a2,24(a5)
    80001db8:	01073023          	sd	a6,0(a4)
    80001dbc:	e708                	sd	a0,8(a4)
    80001dbe:	eb0c                	sd	a1,16(a4)
    80001dc0:	ef10                	sd	a2,24(a4)
    80001dc2:	02078793          	addi	a5,a5,32
    80001dc6:	02070713          	addi	a4,a4,32
    80001dca:	fed792e3          	bne	a5,a3,80001dae <fork+0x5e>
  np->trapframe->a0 = 0;
    80001dce:	0589b783          	ld	a5,88(s3)
    80001dd2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dd6:	0d0a8493          	addi	s1,s5,208
    80001dda:	0d098913          	addi	s2,s3,208
    80001dde:	150a8a13          	addi	s4,s5,336
    80001de2:	a00d                	j	80001e04 <fork+0xb4>
    freeproc(np);
    80001de4:	854e                	mv	a0,s3
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	d4a080e7          	jalr	-694(ra) # 80001b30 <freeproc>
    release(&np->lock);
    80001dee:	854e                	mv	a0,s3
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	e86080e7          	jalr	-378(ra) # 80000c76 <release>
    return -1;
    80001df8:	597d                	li	s2,-1
    80001dfa:	a059                	j	80001e80 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001dfc:	04a1                	addi	s1,s1,8
    80001dfe:	0921                	addi	s2,s2,8
    80001e00:	01448b63          	beq	s1,s4,80001e16 <fork+0xc6>
    if(p->ofile[i])
    80001e04:	6088                	ld	a0,0(s1)
    80001e06:	d97d                	beqz	a0,80001dfc <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e08:	00002097          	auipc	ra,0x2
    80001e0c:	758080e7          	jalr	1880(ra) # 80004560 <filedup>
    80001e10:	00a93023          	sd	a0,0(s2)
    80001e14:	b7e5                	j	80001dfc <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e16:	150ab503          	ld	a0,336(s5)
    80001e1a:	00002097          	auipc	ra,0x2
    80001e1e:	8b8080e7          	jalr	-1864(ra) # 800036d2 <idup>
    80001e22:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e26:	4641                	li	a2,16
    80001e28:	158a8593          	addi	a1,s5,344
    80001e2c:	15898513          	addi	a0,s3,344
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	fe0080e7          	jalr	-32(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e38:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e3c:	854e                	mv	a0,s3
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	e38080e7          	jalr	-456(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e46:	0000f497          	auipc	s1,0xf
    80001e4a:	47248493          	addi	s1,s1,1138 # 800112b8 <wait_lock>
    80001e4e:	8526                	mv	a0,s1
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	d72080e7          	jalr	-654(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e58:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	e18080e7          	jalr	-488(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e66:	854e                	mv	a0,s3
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	d5a080e7          	jalr	-678(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e70:	478d                	li	a5,3
    80001e72:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e76:	854e                	mv	a0,s3
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	dfe080e7          	jalr	-514(ra) # 80000c76 <release>
}
    80001e80:	854a                	mv	a0,s2
    80001e82:	70e2                	ld	ra,56(sp)
    80001e84:	7442                	ld	s0,48(sp)
    80001e86:	74a2                	ld	s1,40(sp)
    80001e88:	7902                	ld	s2,32(sp)
    80001e8a:	69e2                	ld	s3,24(sp)
    80001e8c:	6a42                	ld	s4,16(sp)
    80001e8e:	6aa2                	ld	s5,8(sp)
    80001e90:	6121                	addi	sp,sp,64
    80001e92:	8082                	ret
    return -1;
    80001e94:	597d                	li	s2,-1
    80001e96:	b7ed                	j	80001e80 <fork+0x130>

0000000080001e98 <scheduler>:
{
    80001e98:	7139                	addi	sp,sp,-64
    80001e9a:	fc06                	sd	ra,56(sp)
    80001e9c:	f822                	sd	s0,48(sp)
    80001e9e:	f426                	sd	s1,40(sp)
    80001ea0:	f04a                	sd	s2,32(sp)
    80001ea2:	ec4e                	sd	s3,24(sp)
    80001ea4:	e852                	sd	s4,16(sp)
    80001ea6:	e456                	sd	s5,8(sp)
    80001ea8:	e05a                	sd	s6,0(sp)
    80001eaa:	0080                	addi	s0,sp,64
    80001eac:	8792                	mv	a5,tp
  int id = r_tp();
    80001eae:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb0:	00779a93          	slli	s5,a5,0x7
    80001eb4:	0000f717          	auipc	a4,0xf
    80001eb8:	3ec70713          	addi	a4,a4,1004 # 800112a0 <pid_lock>
    80001ebc:	9756                	add	a4,a4,s5
    80001ebe:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ec2:	0000f717          	auipc	a4,0xf
    80001ec6:	41670713          	addi	a4,a4,1046 # 800112d8 <cpus+0x8>
    80001eca:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ecc:	498d                	li	s3,3
        p->state = RUNNING;
    80001ece:	4b11                	li	s6,4
        c->proc = p;
    80001ed0:	079e                	slli	a5,a5,0x7
    80001ed2:	0000fa17          	auipc	s4,0xf
    80001ed6:	3cea0a13          	addi	s4,s4,974 # 800112a0 <pid_lock>
    80001eda:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001edc:	00015917          	auipc	s2,0x15
    80001ee0:	1f490913          	addi	s2,s2,500 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ee8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001eec:	10079073          	csrw	sstatus,a5
    80001ef0:	0000f497          	auipc	s1,0xf
    80001ef4:	7e048493          	addi	s1,s1,2016 # 800116d0 <proc>
    80001ef8:	a811                	j	80001f0c <scheduler+0x74>
      release(&p->lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	d7a080e7          	jalr	-646(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f04:	16848493          	addi	s1,s1,360
    80001f08:	fd248ee3          	beq	s1,s2,80001ee4 <scheduler+0x4c>
      acquire(&p->lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	cb4080e7          	jalr	-844(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f16:	4c9c                	lw	a5,24(s1)
    80001f18:	ff3791e3          	bne	a5,s3,80001efa <scheduler+0x62>
        p->state = RUNNING;
    80001f1c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f20:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f24:	06048593          	addi	a1,s1,96
    80001f28:	8556                	mv	a0,s5
    80001f2a:	00000097          	auipc	ra,0x0
    80001f2e:	67e080e7          	jalr	1662(ra) # 800025a8 <swtch>
        c->proc = 0;
    80001f32:	020a3823          	sd	zero,48(s4)
    80001f36:	b7d1                	j	80001efa <scheduler+0x62>

0000000080001f38 <sched>:
{
    80001f38:	7179                	addi	sp,sp,-48
    80001f3a:	f406                	sd	ra,40(sp)
    80001f3c:	f022                	sd	s0,32(sp)
    80001f3e:	ec26                	sd	s1,24(sp)
    80001f40:	e84a                	sd	s2,16(sp)
    80001f42:	e44e                	sd	s3,8(sp)
    80001f44:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	a38080e7          	jalr	-1480(ra) # 8000197e <myproc>
    80001f4e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	bf8080e7          	jalr	-1032(ra) # 80000b48 <holding>
    80001f58:	c93d                	beqz	a0,80001fce <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f5a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f5c:	2781                	sext.w	a5,a5
    80001f5e:	079e                	slli	a5,a5,0x7
    80001f60:	0000f717          	auipc	a4,0xf
    80001f64:	34070713          	addi	a4,a4,832 # 800112a0 <pid_lock>
    80001f68:	97ba                	add	a5,a5,a4
    80001f6a:	0a87a703          	lw	a4,168(a5)
    80001f6e:	4785                	li	a5,1
    80001f70:	06f71763          	bne	a4,a5,80001fde <sched+0xa6>
  if(p->state == RUNNING)
    80001f74:	4c98                	lw	a4,24(s1)
    80001f76:	4791                	li	a5,4
    80001f78:	06f70b63          	beq	a4,a5,80001fee <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f80:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f82:	efb5                	bnez	a5,80001ffe <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f84:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f86:	0000f917          	auipc	s2,0xf
    80001f8a:	31a90913          	addi	s2,s2,794 # 800112a0 <pid_lock>
    80001f8e:	2781                	sext.w	a5,a5
    80001f90:	079e                	slli	a5,a5,0x7
    80001f92:	97ca                	add	a5,a5,s2
    80001f94:	0ac7a983          	lw	s3,172(a5)
    80001f98:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f9a:	2781                	sext.w	a5,a5
    80001f9c:	079e                	slli	a5,a5,0x7
    80001f9e:	0000f597          	auipc	a1,0xf
    80001fa2:	33a58593          	addi	a1,a1,826 # 800112d8 <cpus+0x8>
    80001fa6:	95be                	add	a1,a1,a5
    80001fa8:	06048513          	addi	a0,s1,96
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	5fc080e7          	jalr	1532(ra) # 800025a8 <swtch>
    80001fb4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	97ca                	add	a5,a5,s2
    80001fbc:	0b37a623          	sw	s3,172(a5)
}
    80001fc0:	70a2                	ld	ra,40(sp)
    80001fc2:	7402                	ld	s0,32(sp)
    80001fc4:	64e2                	ld	s1,24(sp)
    80001fc6:	6942                	ld	s2,16(sp)
    80001fc8:	69a2                	ld	s3,8(sp)
    80001fca:	6145                	addi	sp,sp,48
    80001fcc:	8082                	ret
    panic("sched p->lock");
    80001fce:	00006517          	auipc	a0,0x6
    80001fd2:	23250513          	addi	a0,a0,562 # 80008200 <digits+0x1c0>
    80001fd6:	ffffe097          	auipc	ra,0xffffe
    80001fda:	554080e7          	jalr	1364(ra) # 8000052a <panic>
    panic("sched locks");
    80001fde:	00006517          	auipc	a0,0x6
    80001fe2:	23250513          	addi	a0,a0,562 # 80008210 <digits+0x1d0>
    80001fe6:	ffffe097          	auipc	ra,0xffffe
    80001fea:	544080e7          	jalr	1348(ra) # 8000052a <panic>
    panic("sched running");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	23250513          	addi	a0,a0,562 # 80008220 <digits+0x1e0>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	534080e7          	jalr	1332(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	23250513          	addi	a0,a0,562 # 80008230 <digits+0x1f0>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	524080e7          	jalr	1316(ra) # 8000052a <panic>

000000008000200e <yield>:
{
    8000200e:	1101                	addi	sp,sp,-32
    80002010:	ec06                	sd	ra,24(sp)
    80002012:	e822                	sd	s0,16(sp)
    80002014:	e426                	sd	s1,8(sp)
    80002016:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	966080e7          	jalr	-1690(ra) # 8000197e <myproc>
    80002020:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	ba0080e7          	jalr	-1120(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000202a:	478d                	li	a5,3
    8000202c:	cc9c                	sw	a5,24(s1)
  sched();
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	f0a080e7          	jalr	-246(ra) # 80001f38 <sched>
  release(&p->lock);
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c3e080e7          	jalr	-962(ra) # 80000c76 <release>
}
    80002040:	60e2                	ld	ra,24(sp)
    80002042:	6442                	ld	s0,16(sp)
    80002044:	64a2                	ld	s1,8(sp)
    80002046:	6105                	addi	sp,sp,32
    80002048:	8082                	ret

000000008000204a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000204a:	7179                	addi	sp,sp,-48
    8000204c:	f406                	sd	ra,40(sp)
    8000204e:	f022                	sd	s0,32(sp)
    80002050:	ec26                	sd	s1,24(sp)
    80002052:	e84a                	sd	s2,16(sp)
    80002054:	e44e                	sd	s3,8(sp)
    80002056:	1800                	addi	s0,sp,48
    80002058:	89aa                	mv	s3,a0
    8000205a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	922080e7          	jalr	-1758(ra) # 8000197e <myproc>
    80002064:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	b5c080e7          	jalr	-1188(ra) # 80000bc2 <acquire>
  release(lk);
    8000206e:	854a                	mv	a0,s2
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c06080e7          	jalr	-1018(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002078:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000207c:	4789                	li	a5,2
    8000207e:	cc9c                	sw	a5,24(s1)

  sched();
    80002080:	00000097          	auipc	ra,0x0
    80002084:	eb8080e7          	jalr	-328(ra) # 80001f38 <sched>

  // Tidy up.
  p->chan = 0;
    80002088:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	be8080e7          	jalr	-1048(ra) # 80000c76 <release>
  acquire(lk);
    80002096:	854a                	mv	a0,s2
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	b2a080e7          	jalr	-1238(ra) # 80000bc2 <acquire>
}
    800020a0:	70a2                	ld	ra,40(sp)
    800020a2:	7402                	ld	s0,32(sp)
    800020a4:	64e2                	ld	s1,24(sp)
    800020a6:	6942                	ld	s2,16(sp)
    800020a8:	69a2                	ld	s3,8(sp)
    800020aa:	6145                	addi	sp,sp,48
    800020ac:	8082                	ret

00000000800020ae <wait>:
{
    800020ae:	715d                	addi	sp,sp,-80
    800020b0:	e486                	sd	ra,72(sp)
    800020b2:	e0a2                	sd	s0,64(sp)
    800020b4:	fc26                	sd	s1,56(sp)
    800020b6:	f84a                	sd	s2,48(sp)
    800020b8:	f44e                	sd	s3,40(sp)
    800020ba:	f052                	sd	s4,32(sp)
    800020bc:	ec56                	sd	s5,24(sp)
    800020be:	e85a                	sd	s6,16(sp)
    800020c0:	e45e                	sd	s7,8(sp)
    800020c2:	e062                	sd	s8,0(sp)
    800020c4:	0880                	addi	s0,sp,80
    800020c6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	8b6080e7          	jalr	-1866(ra) # 8000197e <myproc>
    800020d0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020d2:	0000f517          	auipc	a0,0xf
    800020d6:	1e650513          	addi	a0,a0,486 # 800112b8 <wait_lock>
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	ae8080e7          	jalr	-1304(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020e2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020e4:	4a15                	li	s4,5
        havekids = 1;
    800020e6:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020e8:	00015997          	auipc	s3,0x15
    800020ec:	fe898993          	addi	s3,s3,-24 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020f0:	0000fc17          	auipc	s8,0xf
    800020f4:	1c8c0c13          	addi	s8,s8,456 # 800112b8 <wait_lock>
    havekids = 0;
    800020f8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020fa:	0000f497          	auipc	s1,0xf
    800020fe:	5d648493          	addi	s1,s1,1494 # 800116d0 <proc>
    80002102:	a0bd                	j	80002170 <wait+0xc2>
          pid = np->pid;
    80002104:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002108:	000b0e63          	beqz	s6,80002124 <wait+0x76>
    8000210c:	4691                	li	a3,4
    8000210e:	02c48613          	addi	a2,s1,44
    80002112:	85da                	mv	a1,s6
    80002114:	05093503          	ld	a0,80(s2)
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	526080e7          	jalr	1318(ra) # 8000163e <copyout>
    80002120:	02054563          	bltz	a0,8000214a <wait+0x9c>
          freeproc(np);
    80002124:	8526                	mv	a0,s1
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	a0a080e7          	jalr	-1526(ra) # 80001b30 <freeproc>
          release(&np->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b46080e7          	jalr	-1210(ra) # 80000c76 <release>
          release(&wait_lock);
    80002138:	0000f517          	auipc	a0,0xf
    8000213c:	18050513          	addi	a0,a0,384 # 800112b8 <wait_lock>
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b36080e7          	jalr	-1226(ra) # 80000c76 <release>
          return pid;
    80002148:	a09d                	j	800021ae <wait+0x100>
            release(&np->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b2a080e7          	jalr	-1238(ra) # 80000c76 <release>
            release(&wait_lock);
    80002154:	0000f517          	auipc	a0,0xf
    80002158:	16450513          	addi	a0,a0,356 # 800112b8 <wait_lock>
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b1a080e7          	jalr	-1254(ra) # 80000c76 <release>
            return -1;
    80002164:	59fd                	li	s3,-1
    80002166:	a0a1                	j	800021ae <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002168:	16848493          	addi	s1,s1,360
    8000216c:	03348463          	beq	s1,s3,80002194 <wait+0xe6>
      if(np->parent == p){
    80002170:	7c9c                	ld	a5,56(s1)
    80002172:	ff279be3          	bne	a5,s2,80002168 <wait+0xba>
        acquire(&np->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	a4a080e7          	jalr	-1462(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002180:	4c9c                	lw	a5,24(s1)
    80002182:	f94781e3          	beq	a5,s4,80002104 <wait+0x56>
        release(&np->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	aee080e7          	jalr	-1298(ra) # 80000c76 <release>
        havekids = 1;
    80002190:	8756                	mv	a4,s5
    80002192:	bfd9                	j	80002168 <wait+0xba>
    if(!havekids || p->killed){
    80002194:	c701                	beqz	a4,8000219c <wait+0xee>
    80002196:	02892783          	lw	a5,40(s2)
    8000219a:	c79d                	beqz	a5,800021c8 <wait+0x11a>
      release(&wait_lock);
    8000219c:	0000f517          	auipc	a0,0xf
    800021a0:	11c50513          	addi	a0,a0,284 # 800112b8 <wait_lock>
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	ad2080e7          	jalr	-1326(ra) # 80000c76 <release>
      return -1;
    800021ac:	59fd                	li	s3,-1
}
    800021ae:	854e                	mv	a0,s3
    800021b0:	60a6                	ld	ra,72(sp)
    800021b2:	6406                	ld	s0,64(sp)
    800021b4:	74e2                	ld	s1,56(sp)
    800021b6:	7942                	ld	s2,48(sp)
    800021b8:	79a2                	ld	s3,40(sp)
    800021ba:	7a02                	ld	s4,32(sp)
    800021bc:	6ae2                	ld	s5,24(sp)
    800021be:	6b42                	ld	s6,16(sp)
    800021c0:	6ba2                	ld	s7,8(sp)
    800021c2:	6c02                	ld	s8,0(sp)
    800021c4:	6161                	addi	sp,sp,80
    800021c6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021c8:	85e2                	mv	a1,s8
    800021ca:	854a                	mv	a0,s2
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	e7e080e7          	jalr	-386(ra) # 8000204a <sleep>
    havekids = 0;
    800021d4:	b715                	j	800020f8 <wait+0x4a>

00000000800021d6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021d6:	7139                	addi	sp,sp,-64
    800021d8:	fc06                	sd	ra,56(sp)
    800021da:	f822                	sd	s0,48(sp)
    800021dc:	f426                	sd	s1,40(sp)
    800021de:	f04a                	sd	s2,32(sp)
    800021e0:	ec4e                	sd	s3,24(sp)
    800021e2:	e852                	sd	s4,16(sp)
    800021e4:	e456                	sd	s5,8(sp)
    800021e6:	0080                	addi	s0,sp,64
    800021e8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021ea:	0000f497          	auipc	s1,0xf
    800021ee:	4e648493          	addi	s1,s1,1254 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021f2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021f4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f6:	00015917          	auipc	s2,0x15
    800021fa:	eda90913          	addi	s2,s2,-294 # 800170d0 <tickslock>
    800021fe:	a811                	j	80002212 <wakeup+0x3c>
      }
      release(&p->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	a74080e7          	jalr	-1420(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000220a:	16848493          	addi	s1,s1,360
    8000220e:	03248663          	beq	s1,s2,8000223a <wakeup+0x64>
    if(p != myproc()){
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	76c080e7          	jalr	1900(ra) # 8000197e <myproc>
    8000221a:	fea488e3          	beq	s1,a0,8000220a <wakeup+0x34>
      acquire(&p->lock);
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	9a2080e7          	jalr	-1630(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002228:	4c9c                	lw	a5,24(s1)
    8000222a:	fd379be3          	bne	a5,s3,80002200 <wakeup+0x2a>
    8000222e:	709c                	ld	a5,32(s1)
    80002230:	fd4798e3          	bne	a5,s4,80002200 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002234:	0154ac23          	sw	s5,24(s1)
    80002238:	b7e1                	j	80002200 <wakeup+0x2a>
    }
  }
}
    8000223a:	70e2                	ld	ra,56(sp)
    8000223c:	7442                	ld	s0,48(sp)
    8000223e:	74a2                	ld	s1,40(sp)
    80002240:	7902                	ld	s2,32(sp)
    80002242:	69e2                	ld	s3,24(sp)
    80002244:	6a42                	ld	s4,16(sp)
    80002246:	6aa2                	ld	s5,8(sp)
    80002248:	6121                	addi	sp,sp,64
    8000224a:	8082                	ret

000000008000224c <reparent>:
{
    8000224c:	7179                	addi	sp,sp,-48
    8000224e:	f406                	sd	ra,40(sp)
    80002250:	f022                	sd	s0,32(sp)
    80002252:	ec26                	sd	s1,24(sp)
    80002254:	e84a                	sd	s2,16(sp)
    80002256:	e44e                	sd	s3,8(sp)
    80002258:	e052                	sd	s4,0(sp)
    8000225a:	1800                	addi	s0,sp,48
    8000225c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000225e:	0000f497          	auipc	s1,0xf
    80002262:	47248493          	addi	s1,s1,1138 # 800116d0 <proc>
      pp->parent = initproc;
    80002266:	00007a17          	auipc	s4,0x7
    8000226a:	dc2a0a13          	addi	s4,s4,-574 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226e:	00015997          	auipc	s3,0x15
    80002272:	e6298993          	addi	s3,s3,-414 # 800170d0 <tickslock>
    80002276:	a029                	j	80002280 <reparent+0x34>
    80002278:	16848493          	addi	s1,s1,360
    8000227c:	01348d63          	beq	s1,s3,80002296 <reparent+0x4a>
    if(pp->parent == p){
    80002280:	7c9c                	ld	a5,56(s1)
    80002282:	ff279be3          	bne	a5,s2,80002278 <reparent+0x2c>
      pp->parent = initproc;
    80002286:	000a3503          	ld	a0,0(s4)
    8000228a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	f4a080e7          	jalr	-182(ra) # 800021d6 <wakeup>
    80002294:	b7d5                	j	80002278 <reparent+0x2c>
}
    80002296:	70a2                	ld	ra,40(sp)
    80002298:	7402                	ld	s0,32(sp)
    8000229a:	64e2                	ld	s1,24(sp)
    8000229c:	6942                	ld	s2,16(sp)
    8000229e:	69a2                	ld	s3,8(sp)
    800022a0:	6a02                	ld	s4,0(sp)
    800022a2:	6145                	addi	sp,sp,48
    800022a4:	8082                	ret

00000000800022a6 <exit>:
{
    800022a6:	7179                	addi	sp,sp,-48
    800022a8:	f406                	sd	ra,40(sp)
    800022aa:	f022                	sd	s0,32(sp)
    800022ac:	ec26                	sd	s1,24(sp)
    800022ae:	e84a                	sd	s2,16(sp)
    800022b0:	e44e                	sd	s3,8(sp)
    800022b2:	e052                	sd	s4,0(sp)
    800022b4:	1800                	addi	s0,sp,48
    800022b6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	6c6080e7          	jalr	1734(ra) # 8000197e <myproc>
    800022c0:	89aa                	mv	s3,a0
  if(p == initproc)
    800022c2:	00007797          	auipc	a5,0x7
    800022c6:	d667b783          	ld	a5,-666(a5) # 80009028 <initproc>
    800022ca:	0d050493          	addi	s1,a0,208
    800022ce:	15050913          	addi	s2,a0,336
    800022d2:	02a79363          	bne	a5,a0,800022f8 <exit+0x52>
    panic("init exiting");
    800022d6:	00006517          	auipc	a0,0x6
    800022da:	f7250513          	addi	a0,a0,-142 # 80008248 <digits+0x208>
    800022de:	ffffe097          	auipc	ra,0xffffe
    800022e2:	24c080e7          	jalr	588(ra) # 8000052a <panic>
      fileclose(f);
    800022e6:	00002097          	auipc	ra,0x2
    800022ea:	2cc080e7          	jalr	716(ra) # 800045b2 <fileclose>
      p->ofile[fd] = 0;
    800022ee:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022f2:	04a1                	addi	s1,s1,8
    800022f4:	01248563          	beq	s1,s2,800022fe <exit+0x58>
    if(p->ofile[fd]){
    800022f8:	6088                	ld	a0,0(s1)
    800022fa:	f575                	bnez	a0,800022e6 <exit+0x40>
    800022fc:	bfdd                	j	800022f2 <exit+0x4c>
  begin_op();
    800022fe:	00002097          	auipc	ra,0x2
    80002302:	de8080e7          	jalr	-536(ra) # 800040e6 <begin_op>
  iput(p->cwd);
    80002306:	1509b503          	ld	a0,336(s3)
    8000230a:	00001097          	auipc	ra,0x1
    8000230e:	5c0080e7          	jalr	1472(ra) # 800038ca <iput>
  end_op();
    80002312:	00002097          	auipc	ra,0x2
    80002316:	e54080e7          	jalr	-428(ra) # 80004166 <end_op>
  p->cwd = 0;
    8000231a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000231e:	0000f497          	auipc	s1,0xf
    80002322:	f9a48493          	addi	s1,s1,-102 # 800112b8 <wait_lock>
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	89a080e7          	jalr	-1894(ra) # 80000bc2 <acquire>
  reparent(p);
    80002330:	854e                	mv	a0,s3
    80002332:	00000097          	auipc	ra,0x0
    80002336:	f1a080e7          	jalr	-230(ra) # 8000224c <reparent>
  wakeup(p->parent);
    8000233a:	0389b503          	ld	a0,56(s3)
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	e98080e7          	jalr	-360(ra) # 800021d6 <wakeup>
  acquire(&p->lock);
    80002346:	854e                	mv	a0,s3
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	87a080e7          	jalr	-1926(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002350:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002354:	4795                	li	a5,5
    80002356:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	91a080e7          	jalr	-1766(ra) # 80000c76 <release>
  sched();
    80002364:	00000097          	auipc	ra,0x0
    80002368:	bd4080e7          	jalr	-1068(ra) # 80001f38 <sched>
  panic("zombie exit");
    8000236c:	00006517          	auipc	a0,0x6
    80002370:	eec50513          	addi	a0,a0,-276 # 80008258 <digits+0x218>
    80002374:	ffffe097          	auipc	ra,0xffffe
    80002378:	1b6080e7          	jalr	438(ra) # 8000052a <panic>

000000008000237c <trace>:



void 
trace(int mask_input, int pid)
{
    8000237c:	7179                	addi	sp,sp,-48
    8000237e:	f406                	sd	ra,40(sp)
    80002380:	f022                	sd	s0,32(sp)
    80002382:	ec26                	sd	s1,24(sp)
    80002384:	e84a                	sd	s2,16(sp)
    80002386:	e44e                	sd	s3,8(sp)
    80002388:	e052                	sd	s4,0(sp)
    8000238a:	1800                	addi	s0,sp,48
    8000238c:	8a2a                	mv	s4,a0
    8000238e:	892e                	mv	s2,a1
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    80002390:	0000f497          	auipc	s1,0xf
    80002394:	34048493          	addi	s1,s1,832 # 800116d0 <proc>
    80002398:	00015997          	auipc	s3,0x15
    8000239c:	d3898993          	addi	s3,s3,-712 # 800170d0 <tickslock>
    800023a0:	a811                	j	800023b4 <trace+0x38>
    acquire(&p->lock);
    if(p->pid == pid)
      p->mask = mask_input;
    release(&p->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8d2080e7          	jalr	-1838(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023ac:	16848493          	addi	s1,s1,360
    800023b0:	01348d63          	beq	s1,s3,800023ca <trace+0x4e>
    acquire(&p->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	80c080e7          	jalr	-2036(ra) # 80000bc2 <acquire>
    if(p->pid == pid)
    800023be:	589c                	lw	a5,48(s1)
    800023c0:	ff2791e3          	bne	a5,s2,800023a2 <trace+0x26>
      p->mask = mask_input;
    800023c4:	0344aa23          	sw	s4,52(s1)
    800023c8:	bfe9                	j	800023a2 <trace+0x26>
  }
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6a02                	ld	s4,0(sp)
    800023d6:	6145                	addi	sp,sp,48
    800023d8:	8082                	ret

00000000800023da <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023da:	7179                	addi	sp,sp,-48
    800023dc:	f406                	sd	ra,40(sp)
    800023de:	f022                	sd	s0,32(sp)
    800023e0:	ec26                	sd	s1,24(sp)
    800023e2:	e84a                	sd	s2,16(sp)
    800023e4:	e44e                	sd	s3,8(sp)
    800023e6:	1800                	addi	s0,sp,48
    800023e8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023ea:	0000f497          	auipc	s1,0xf
    800023ee:	2e648493          	addi	s1,s1,742 # 800116d0 <proc>
    800023f2:	00015997          	auipc	s3,0x15
    800023f6:	cde98993          	addi	s3,s3,-802 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	7c6080e7          	jalr	1990(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002404:	589c                	lw	a5,48(s1)
    80002406:	01278d63          	beq	a5,s2,80002420 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	86a080e7          	jalr	-1942(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002414:	16848493          	addi	s1,s1,360
    80002418:	ff3491e3          	bne	s1,s3,800023fa <kill+0x20>
  }
  return -1;
    8000241c:	557d                	li	a0,-1
    8000241e:	a829                	j	80002438 <kill+0x5e>
      p->killed = 1;
    80002420:	4785                	li	a5,1
    80002422:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002424:	4c98                	lw	a4,24(s1)
    80002426:	4789                	li	a5,2
    80002428:	00f70f63          	beq	a4,a5,80002446 <kill+0x6c>
      release(&p->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	848080e7          	jalr	-1976(ra) # 80000c76 <release>
      return 0;
    80002436:	4501                	li	a0,0
}
    80002438:	70a2                	ld	ra,40(sp)
    8000243a:	7402                	ld	s0,32(sp)
    8000243c:	64e2                	ld	s1,24(sp)
    8000243e:	6942                	ld	s2,16(sp)
    80002440:	69a2                	ld	s3,8(sp)
    80002442:	6145                	addi	sp,sp,48
    80002444:	8082                	ret
        p->state = RUNNABLE;
    80002446:	478d                	li	a5,3
    80002448:	cc9c                	sw	a5,24(s1)
    8000244a:	b7cd                	j	8000242c <kill+0x52>

000000008000244c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000244c:	7179                	addi	sp,sp,-48
    8000244e:	f406                	sd	ra,40(sp)
    80002450:	f022                	sd	s0,32(sp)
    80002452:	ec26                	sd	s1,24(sp)
    80002454:	e84a                	sd	s2,16(sp)
    80002456:	e44e                	sd	s3,8(sp)
    80002458:	e052                	sd	s4,0(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	84aa                	mv	s1,a0
    8000245e:	892e                	mv	s2,a1
    80002460:	89b2                	mv	s3,a2
    80002462:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	51a080e7          	jalr	1306(ra) # 8000197e <myproc>
  if(user_dst){
    8000246c:	c08d                	beqz	s1,8000248e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000246e:	86d2                	mv	a3,s4
    80002470:	864e                	mv	a2,s3
    80002472:	85ca                	mv	a1,s2
    80002474:	6928                	ld	a0,80(a0)
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	1c8080e7          	jalr	456(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000247e:	70a2                	ld	ra,40(sp)
    80002480:	7402                	ld	s0,32(sp)
    80002482:	64e2                	ld	s1,24(sp)
    80002484:	6942                	ld	s2,16(sp)
    80002486:	69a2                	ld	s3,8(sp)
    80002488:	6a02                	ld	s4,0(sp)
    8000248a:	6145                	addi	sp,sp,48
    8000248c:	8082                	ret
    memmove((char *)dst, src, len);
    8000248e:	000a061b          	sext.w	a2,s4
    80002492:	85ce                	mv	a1,s3
    80002494:	854a                	mv	a0,s2
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	884080e7          	jalr	-1916(ra) # 80000d1a <memmove>
    return 0;
    8000249e:	8526                	mv	a0,s1
    800024a0:	bff9                	j	8000247e <either_copyout+0x32>

00000000800024a2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024a2:	7179                	addi	sp,sp,-48
    800024a4:	f406                	sd	ra,40(sp)
    800024a6:	f022                	sd	s0,32(sp)
    800024a8:	ec26                	sd	s1,24(sp)
    800024aa:	e84a                	sd	s2,16(sp)
    800024ac:	e44e                	sd	s3,8(sp)
    800024ae:	e052                	sd	s4,0(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	892a                	mv	s2,a0
    800024b4:	84ae                	mv	s1,a1
    800024b6:	89b2                	mv	s3,a2
    800024b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	4c4080e7          	jalr	1220(ra) # 8000197e <myproc>
  if(user_src){
    800024c2:	c08d                	beqz	s1,800024e4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024c4:	86d2                	mv	a3,s4
    800024c6:	864e                	mv	a2,s3
    800024c8:	85ca                	mv	a1,s2
    800024ca:	6928                	ld	a0,80(a0)
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	1fe080e7          	jalr	510(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024d4:	70a2                	ld	ra,40(sp)
    800024d6:	7402                	ld	s0,32(sp)
    800024d8:	64e2                	ld	s1,24(sp)
    800024da:	6942                	ld	s2,16(sp)
    800024dc:	69a2                	ld	s3,8(sp)
    800024de:	6a02                	ld	s4,0(sp)
    800024e0:	6145                	addi	sp,sp,48
    800024e2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024e4:	000a061b          	sext.w	a2,s4
    800024e8:	85ce                	mv	a1,s3
    800024ea:	854a                	mv	a0,s2
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	82e080e7          	jalr	-2002(ra) # 80000d1a <memmove>
    return 0;
    800024f4:	8526                	mv	a0,s1
    800024f6:	bff9                	j	800024d4 <either_copyin+0x32>

00000000800024f8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024f8:	715d                	addi	sp,sp,-80
    800024fa:	e486                	sd	ra,72(sp)
    800024fc:	e0a2                	sd	s0,64(sp)
    800024fe:	fc26                	sd	s1,56(sp)
    80002500:	f84a                	sd	s2,48(sp)
    80002502:	f44e                	sd	s3,40(sp)
    80002504:	f052                	sd	s4,32(sp)
    80002506:	ec56                	sd	s5,24(sp)
    80002508:	e85a                	sd	s6,16(sp)
    8000250a:	e45e                	sd	s7,8(sp)
    8000250c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000250e:	00006517          	auipc	a0,0x6
    80002512:	bba50513          	addi	a0,a0,-1094 # 800080c8 <digits+0x88>
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	05e080e7          	jalr	94(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251e:	0000f497          	auipc	s1,0xf
    80002522:	30a48493          	addi	s1,s1,778 # 80011828 <proc+0x158>
    80002526:	00015917          	auipc	s2,0x15
    8000252a:	d0290913          	addi	s2,s2,-766 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002530:	00006997          	auipc	s3,0x6
    80002534:	d3898993          	addi	s3,s3,-712 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002538:	00006a97          	auipc	s5,0x6
    8000253c:	d38a8a93          	addi	s5,s5,-712 # 80008270 <digits+0x230>
    printf("\n");
    80002540:	00006a17          	auipc	s4,0x6
    80002544:	b88a0a13          	addi	s4,s4,-1144 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002548:	00006b97          	auipc	s7,0x6
    8000254c:	d60b8b93          	addi	s7,s7,-672 # 800082a8 <states.0>
    80002550:	a00d                	j	80002572 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002552:	ed86a583          	lw	a1,-296(a3)
    80002556:	8556                	mv	a0,s5
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	01c080e7          	jalr	28(ra) # 80000574 <printf>
    printf("\n");
    80002560:	8552                	mv	a0,s4
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	012080e7          	jalr	18(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000256a:	16848493          	addi	s1,s1,360
    8000256e:	03248263          	beq	s1,s2,80002592 <procdump+0x9a>
    if(p->state == UNUSED)
    80002572:	86a6                	mv	a3,s1
    80002574:	ec04a783          	lw	a5,-320(s1)
    80002578:	dbed                	beqz	a5,8000256a <procdump+0x72>
      state = "???";
    8000257a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257c:	fcfb6be3          	bltu	s6,a5,80002552 <procdump+0x5a>
    80002580:	02079713          	slli	a4,a5,0x20
    80002584:	01d75793          	srli	a5,a4,0x1d
    80002588:	97de                	add	a5,a5,s7
    8000258a:	6390                	ld	a2,0(a5)
    8000258c:	f279                	bnez	a2,80002552 <procdump+0x5a>
      state = "???";
    8000258e:	864e                	mv	a2,s3
    80002590:	b7c9                	j	80002552 <procdump+0x5a>
  }
}
    80002592:	60a6                	ld	ra,72(sp)
    80002594:	6406                	ld	s0,64(sp)
    80002596:	74e2                	ld	s1,56(sp)
    80002598:	7942                	ld	s2,48(sp)
    8000259a:	79a2                	ld	s3,40(sp)
    8000259c:	7a02                	ld	s4,32(sp)
    8000259e:	6ae2                	ld	s5,24(sp)
    800025a0:	6b42                	ld	s6,16(sp)
    800025a2:	6ba2                	ld	s7,8(sp)
    800025a4:	6161                	addi	sp,sp,80
    800025a6:	8082                	ret

00000000800025a8 <swtch>:
    800025a8:	00153023          	sd	ra,0(a0)
    800025ac:	00253423          	sd	sp,8(a0)
    800025b0:	e900                	sd	s0,16(a0)
    800025b2:	ed04                	sd	s1,24(a0)
    800025b4:	03253023          	sd	s2,32(a0)
    800025b8:	03353423          	sd	s3,40(a0)
    800025bc:	03453823          	sd	s4,48(a0)
    800025c0:	03553c23          	sd	s5,56(a0)
    800025c4:	05653023          	sd	s6,64(a0)
    800025c8:	05753423          	sd	s7,72(a0)
    800025cc:	05853823          	sd	s8,80(a0)
    800025d0:	05953c23          	sd	s9,88(a0)
    800025d4:	07a53023          	sd	s10,96(a0)
    800025d8:	07b53423          	sd	s11,104(a0)
    800025dc:	0005b083          	ld	ra,0(a1)
    800025e0:	0085b103          	ld	sp,8(a1)
    800025e4:	6980                	ld	s0,16(a1)
    800025e6:	6d84                	ld	s1,24(a1)
    800025e8:	0205b903          	ld	s2,32(a1)
    800025ec:	0285b983          	ld	s3,40(a1)
    800025f0:	0305ba03          	ld	s4,48(a1)
    800025f4:	0385ba83          	ld	s5,56(a1)
    800025f8:	0405bb03          	ld	s6,64(a1)
    800025fc:	0485bb83          	ld	s7,72(a1)
    80002600:	0505bc03          	ld	s8,80(a1)
    80002604:	0585bc83          	ld	s9,88(a1)
    80002608:	0605bd03          	ld	s10,96(a1)
    8000260c:	0685bd83          	ld	s11,104(a1)
    80002610:	8082                	ret

0000000080002612 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002612:	1141                	addi	sp,sp,-16
    80002614:	e406                	sd	ra,8(sp)
    80002616:	e022                	sd	s0,0(sp)
    80002618:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000261a:	00006597          	auipc	a1,0x6
    8000261e:	cbe58593          	addi	a1,a1,-834 # 800082d8 <states.0+0x30>
    80002622:	00015517          	auipc	a0,0x15
    80002626:	aae50513          	addi	a0,a0,-1362 # 800170d0 <tickslock>
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	508080e7          	jalr	1288(ra) # 80000b32 <initlock>
}
    80002632:	60a2                	ld	ra,8(sp)
    80002634:	6402                	ld	s0,0(sp)
    80002636:	0141                	addi	sp,sp,16
    80002638:	8082                	ret

000000008000263a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000263a:	1141                	addi	sp,sp,-16
    8000263c:	e422                	sd	s0,8(sp)
    8000263e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002640:	00003797          	auipc	a5,0x3
    80002644:	5a078793          	addi	a5,a5,1440 # 80005be0 <kernelvec>
    80002648:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000264c:	6422                	ld	s0,8(sp)
    8000264e:	0141                	addi	sp,sp,16
    80002650:	8082                	ret

0000000080002652 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002652:	1141                	addi	sp,sp,-16
    80002654:	e406                	sd	ra,8(sp)
    80002656:	e022                	sd	s0,0(sp)
    80002658:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000265a:	fffff097          	auipc	ra,0xfffff
    8000265e:	324080e7          	jalr	804(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002662:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002666:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002668:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000266c:	00005617          	auipc	a2,0x5
    80002670:	99460613          	addi	a2,a2,-1644 # 80007000 <_trampoline>
    80002674:	00005697          	auipc	a3,0x5
    80002678:	98c68693          	addi	a3,a3,-1652 # 80007000 <_trampoline>
    8000267c:	8e91                	sub	a3,a3,a2
    8000267e:	040007b7          	lui	a5,0x4000
    80002682:	17fd                	addi	a5,a5,-1
    80002684:	07b2                	slli	a5,a5,0xc
    80002686:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002688:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000268c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000268e:	180026f3          	csrr	a3,satp
    80002692:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002694:	6d38                	ld	a4,88(a0)
    80002696:	6134                	ld	a3,64(a0)
    80002698:	6585                	lui	a1,0x1
    8000269a:	96ae                	add	a3,a3,a1
    8000269c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000269e:	6d38                	ld	a4,88(a0)
    800026a0:	00000697          	auipc	a3,0x0
    800026a4:	13868693          	addi	a3,a3,312 # 800027d8 <usertrap>
    800026a8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026aa:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026ac:	8692                	mv	a3,tp
    800026ae:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026b4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026b8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026bc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026c2:	6f18                	ld	a4,24(a4)
    800026c4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026c8:	692c                	ld	a1,80(a0)
    800026ca:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026cc:	00005717          	auipc	a4,0x5
    800026d0:	9c470713          	addi	a4,a4,-1596 # 80007090 <userret>
    800026d4:	8f11                	sub	a4,a4,a2
    800026d6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026d8:	577d                	li	a4,-1
    800026da:	177e                	slli	a4,a4,0x3f
    800026dc:	8dd9                	or	a1,a1,a4
    800026de:	02000537          	lui	a0,0x2000
    800026e2:	157d                	addi	a0,a0,-1
    800026e4:	0536                	slli	a0,a0,0xd
    800026e6:	9782                	jalr	a5
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	addi	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f0:	1101                	addi	sp,sp,-32
    800026f2:	ec06                	sd	ra,24(sp)
    800026f4:	e822                	sd	s0,16(sp)
    800026f6:	e426                	sd	s1,8(sp)
    800026f8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026fa:	00015497          	auipc	s1,0x15
    800026fe:	9d648493          	addi	s1,s1,-1578 # 800170d0 <tickslock>
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	4be080e7          	jalr	1214(ra) # 80000bc2 <acquire>
  ticks++;
    8000270c:	00007517          	auipc	a0,0x7
    80002710:	92450513          	addi	a0,a0,-1756 # 80009030 <ticks>
    80002714:	411c                	lw	a5,0(a0)
    80002716:	2785                	addiw	a5,a5,1
    80002718:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000271a:	00000097          	auipc	ra,0x0
    8000271e:	abc080e7          	jalr	-1348(ra) # 800021d6 <wakeup>
  release(&tickslock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	552080e7          	jalr	1362(ra) # 80000c76 <release>
}
    8000272c:	60e2                	ld	ra,24(sp)
    8000272e:	6442                	ld	s0,16(sp)
    80002730:	64a2                	ld	s1,8(sp)
    80002732:	6105                	addi	sp,sp,32
    80002734:	8082                	ret

0000000080002736 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002736:	1101                	addi	sp,sp,-32
    80002738:	ec06                	sd	ra,24(sp)
    8000273a:	e822                	sd	s0,16(sp)
    8000273c:	e426                	sd	s1,8(sp)
    8000273e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002740:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002744:	00074d63          	bltz	a4,8000275e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002748:	57fd                	li	a5,-1
    8000274a:	17fe                	slli	a5,a5,0x3f
    8000274c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000274e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002750:	06f70363          	beq	a4,a5,800027b6 <devintr+0x80>
  }
}
    80002754:	60e2                	ld	ra,24(sp)
    80002756:	6442                	ld	s0,16(sp)
    80002758:	64a2                	ld	s1,8(sp)
    8000275a:	6105                	addi	sp,sp,32
    8000275c:	8082                	ret
     (scause & 0xff) == 9){
    8000275e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002762:	46a5                	li	a3,9
    80002764:	fed792e3          	bne	a5,a3,80002748 <devintr+0x12>
    int irq = plic_claim();
    80002768:	00003097          	auipc	ra,0x3
    8000276c:	580080e7          	jalr	1408(ra) # 80005ce8 <plic_claim>
    80002770:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002772:	47a9                	li	a5,10
    80002774:	02f50763          	beq	a0,a5,800027a2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002778:	4785                	li	a5,1
    8000277a:	02f50963          	beq	a0,a5,800027ac <devintr+0x76>
    return 1;
    8000277e:	4505                	li	a0,1
    } else if(irq){
    80002780:	d8f1                	beqz	s1,80002754 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002782:	85a6                	mv	a1,s1
    80002784:	00006517          	auipc	a0,0x6
    80002788:	b5c50513          	addi	a0,a0,-1188 # 800082e0 <states.0+0x38>
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	de8080e7          	jalr	-536(ra) # 80000574 <printf>
      plic_complete(irq);
    80002794:	8526                	mv	a0,s1
    80002796:	00003097          	auipc	ra,0x3
    8000279a:	576080e7          	jalr	1398(ra) # 80005d0c <plic_complete>
    return 1;
    8000279e:	4505                	li	a0,1
    800027a0:	bf55                	j	80002754 <devintr+0x1e>
      uartintr();
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	1e4080e7          	jalr	484(ra) # 80000986 <uartintr>
    800027aa:	b7ed                	j	80002794 <devintr+0x5e>
      virtio_disk_intr();
    800027ac:	00004097          	auipc	ra,0x4
    800027b0:	9f2080e7          	jalr	-1550(ra) # 8000619e <virtio_disk_intr>
    800027b4:	b7c5                	j	80002794 <devintr+0x5e>
    if(cpuid() == 0){
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	19c080e7          	jalr	412(ra) # 80001952 <cpuid>
    800027be:	c901                	beqz	a0,800027ce <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027c4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027c6:	14479073          	csrw	sip,a5
    return 2;
    800027ca:	4509                	li	a0,2
    800027cc:	b761                	j	80002754 <devintr+0x1e>
      clockintr();
    800027ce:	00000097          	auipc	ra,0x0
    800027d2:	f22080e7          	jalr	-222(ra) # 800026f0 <clockintr>
    800027d6:	b7ed                	j	800027c0 <devintr+0x8a>

00000000800027d8 <usertrap>:
{
    800027d8:	1101                	addi	sp,sp,-32
    800027da:	ec06                	sd	ra,24(sp)
    800027dc:	e822                	sd	s0,16(sp)
    800027de:	e426                	sd	s1,8(sp)
    800027e0:	e04a                	sd	s2,0(sp)
    800027e2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027e8:	1007f793          	andi	a5,a5,256
    800027ec:	e3ad                	bnez	a5,8000284e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ee:	00003797          	auipc	a5,0x3
    800027f2:	3f278793          	addi	a5,a5,1010 # 80005be0 <kernelvec>
    800027f6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027fa:	fffff097          	auipc	ra,0xfffff
    800027fe:	184080e7          	jalr	388(ra) # 8000197e <myproc>
    80002802:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002804:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002806:	14102773          	csrr	a4,sepc
    8000280a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000280c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002810:	47a1                	li	a5,8
    80002812:	04f71c63          	bne	a4,a5,8000286a <usertrap+0x92>
    if(p->killed)
    80002816:	551c                	lw	a5,40(a0)
    80002818:	e3b9                	bnez	a5,8000285e <usertrap+0x86>
    p->trapframe->epc += 4;
    8000281a:	6cb8                	ld	a4,88(s1)
    8000281c:	6f1c                	ld	a5,24(a4)
    8000281e:	0791                	addi	a5,a5,4
    80002820:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002822:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002826:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282a:	10079073          	csrw	sstatus,a5
    syscall();
    8000282e:	00000097          	auipc	ra,0x0
    80002832:	2e0080e7          	jalr	736(ra) # 80002b0e <syscall>
  if(p->killed)
    80002836:	549c                	lw	a5,40(s1)
    80002838:	ebc1                	bnez	a5,800028c8 <usertrap+0xf0>
  usertrapret();
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	e18080e7          	jalr	-488(ra) # 80002652 <usertrapret>
}
    80002842:	60e2                	ld	ra,24(sp)
    80002844:	6442                	ld	s0,16(sp)
    80002846:	64a2                	ld	s1,8(sp)
    80002848:	6902                	ld	s2,0(sp)
    8000284a:	6105                	addi	sp,sp,32
    8000284c:	8082                	ret
    panic("usertrap: not from user mode");
    8000284e:	00006517          	auipc	a0,0x6
    80002852:	ab250513          	addi	a0,a0,-1358 # 80008300 <states.0+0x58>
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	cd4080e7          	jalr	-812(ra) # 8000052a <panic>
      exit(-1);
    8000285e:	557d                	li	a0,-1
    80002860:	00000097          	auipc	ra,0x0
    80002864:	a46080e7          	jalr	-1466(ra) # 800022a6 <exit>
    80002868:	bf4d                	j	8000281a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	ecc080e7          	jalr	-308(ra) # 80002736 <devintr>
    80002872:	892a                	mv	s2,a0
    80002874:	c501                	beqz	a0,8000287c <usertrap+0xa4>
  if(p->killed)
    80002876:	549c                	lw	a5,40(s1)
    80002878:	c3a1                	beqz	a5,800028b8 <usertrap+0xe0>
    8000287a:	a815                	j	800028ae <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002880:	5890                	lw	a2,48(s1)
    80002882:	00006517          	auipc	a0,0x6
    80002886:	a9e50513          	addi	a0,a0,-1378 # 80008320 <states.0+0x78>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cea080e7          	jalr	-790(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002892:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002896:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000289a:	00006517          	auipc	a0,0x6
    8000289e:	ab650513          	addi	a0,a0,-1354 # 80008350 <states.0+0xa8>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	cd2080e7          	jalr	-814(ra) # 80000574 <printf>
    p->killed = 1;
    800028aa:	4785                	li	a5,1
    800028ac:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028ae:	557d                	li	a0,-1
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	9f6080e7          	jalr	-1546(ra) # 800022a6 <exit>
  if(which_dev == 2)
    800028b8:	4789                	li	a5,2
    800028ba:	f8f910e3          	bne	s2,a5,8000283a <usertrap+0x62>
    yield();
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	750080e7          	jalr	1872(ra) # 8000200e <yield>
    800028c6:	bf95                	j	8000283a <usertrap+0x62>
  int which_dev = 0;
    800028c8:	4901                	li	s2,0
    800028ca:	b7d5                	j	800028ae <usertrap+0xd6>

00000000800028cc <kerneltrap>:
{
    800028cc:	7179                	addi	sp,sp,-48
    800028ce:	f406                	sd	ra,40(sp)
    800028d0:	f022                	sd	s0,32(sp)
    800028d2:	ec26                	sd	s1,24(sp)
    800028d4:	e84a                	sd	s2,16(sp)
    800028d6:	e44e                	sd	s3,8(sp)
    800028d8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028da:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028de:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028e6:	1004f793          	andi	a5,s1,256
    800028ea:	cb85                	beqz	a5,8000291a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028f2:	ef85                	bnez	a5,8000292a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028f4:	00000097          	auipc	ra,0x0
    800028f8:	e42080e7          	jalr	-446(ra) # 80002736 <devintr>
    800028fc:	cd1d                	beqz	a0,8000293a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028fe:	4789                	li	a5,2
    80002900:	06f50a63          	beq	a0,a5,80002974 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002904:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002908:	10049073          	csrw	sstatus,s1
}
    8000290c:	70a2                	ld	ra,40(sp)
    8000290e:	7402                	ld	s0,32(sp)
    80002910:	64e2                	ld	s1,24(sp)
    80002912:	6942                	ld	s2,16(sp)
    80002914:	69a2                	ld	s3,8(sp)
    80002916:	6145                	addi	sp,sp,48
    80002918:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000291a:	00006517          	auipc	a0,0x6
    8000291e:	a5650513          	addi	a0,a0,-1450 # 80008370 <states.0+0xc8>
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	c08080e7          	jalr	-1016(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000292a:	00006517          	auipc	a0,0x6
    8000292e:	a6e50513          	addi	a0,a0,-1426 # 80008398 <states.0+0xf0>
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	bf8080e7          	jalr	-1032(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000293a:	85ce                	mv	a1,s3
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a7c50513          	addi	a0,a0,-1412 # 800083b8 <states.0+0x110>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c30080e7          	jalr	-976(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000294c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002950:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002954:	00006517          	auipc	a0,0x6
    80002958:	a7450513          	addi	a0,a0,-1420 # 800083c8 <states.0+0x120>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	c18080e7          	jalr	-1000(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002964:	00006517          	auipc	a0,0x6
    80002968:	a7c50513          	addi	a0,a0,-1412 # 800083e0 <states.0+0x138>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	bbe080e7          	jalr	-1090(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	00a080e7          	jalr	10(ra) # 8000197e <myproc>
    8000297c:	d541                	beqz	a0,80002904 <kerneltrap+0x38>
    8000297e:	fffff097          	auipc	ra,0xfffff
    80002982:	000080e7          	jalr	ra # 8000197e <myproc>
    80002986:	4d18                	lw	a4,24(a0)
    80002988:	4791                	li	a5,4
    8000298a:	f6f71de3          	bne	a4,a5,80002904 <kerneltrap+0x38>
    yield();
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	680080e7          	jalr	1664(ra) # 8000200e <yield>
    80002996:	b7bd                	j	80002904 <kerneltrap+0x38>

0000000080002998 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002998:	1101                	addi	sp,sp,-32
    8000299a:	ec06                	sd	ra,24(sp)
    8000299c:	e822                	sd	s0,16(sp)
    8000299e:	e426                	sd	s1,8(sp)
    800029a0:	1000                	addi	s0,sp,32
    800029a2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029a4:	fffff097          	auipc	ra,0xfffff
    800029a8:	fda080e7          	jalr	-38(ra) # 8000197e <myproc>
  switch (n) {
    800029ac:	4795                	li	a5,5
    800029ae:	0497e163          	bltu	a5,s1,800029f0 <argraw+0x58>
    800029b2:	048a                	slli	s1,s1,0x2
    800029b4:	00006717          	auipc	a4,0x6
    800029b8:	b6470713          	addi	a4,a4,-1180 # 80008518 <states.0+0x270>
    800029bc:	94ba                	add	s1,s1,a4
    800029be:	409c                	lw	a5,0(s1)
    800029c0:	97ba                	add	a5,a5,a4
    800029c2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029c4:	6d3c                	ld	a5,88(a0)
    800029c6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029c8:	60e2                	ld	ra,24(sp)
    800029ca:	6442                	ld	s0,16(sp)
    800029cc:	64a2                	ld	s1,8(sp)
    800029ce:	6105                	addi	sp,sp,32
    800029d0:	8082                	ret
    return p->trapframe->a1;
    800029d2:	6d3c                	ld	a5,88(a0)
    800029d4:	7fa8                	ld	a0,120(a5)
    800029d6:	bfcd                	j	800029c8 <argraw+0x30>
    return p->trapframe->a2;
    800029d8:	6d3c                	ld	a5,88(a0)
    800029da:	63c8                	ld	a0,128(a5)
    800029dc:	b7f5                	j	800029c8 <argraw+0x30>
    return p->trapframe->a3;
    800029de:	6d3c                	ld	a5,88(a0)
    800029e0:	67c8                	ld	a0,136(a5)
    800029e2:	b7dd                	j	800029c8 <argraw+0x30>
    return p->trapframe->a4;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	6bc8                	ld	a0,144(a5)
    800029e8:	b7c5                	j	800029c8 <argraw+0x30>
    return p->trapframe->a5;
    800029ea:	6d3c                	ld	a5,88(a0)
    800029ec:	6fc8                	ld	a0,152(a5)
    800029ee:	bfe9                	j	800029c8 <argraw+0x30>
  panic("argraw");
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	a0050513          	addi	a0,a0,-1536 # 800083f0 <states.0+0x148>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b32080e7          	jalr	-1230(ra) # 8000052a <panic>

0000000080002a00 <fetchaddr>:
{
    80002a00:	1101                	addi	sp,sp,-32
    80002a02:	ec06                	sd	ra,24(sp)
    80002a04:	e822                	sd	s0,16(sp)
    80002a06:	e426                	sd	s1,8(sp)
    80002a08:	e04a                	sd	s2,0(sp)
    80002a0a:	1000                	addi	s0,sp,32
    80002a0c:	84aa                	mv	s1,a0
    80002a0e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	f6e080e7          	jalr	-146(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a18:	653c                	ld	a5,72(a0)
    80002a1a:	02f4f863          	bgeu	s1,a5,80002a4a <fetchaddr+0x4a>
    80002a1e:	00848713          	addi	a4,s1,8
    80002a22:	02e7e663          	bltu	a5,a4,80002a4e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a26:	46a1                	li	a3,8
    80002a28:	8626                	mv	a2,s1
    80002a2a:	85ca                	mv	a1,s2
    80002a2c:	6928                	ld	a0,80(a0)
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	c9c080e7          	jalr	-868(ra) # 800016ca <copyin>
    80002a36:	00a03533          	snez	a0,a0
    80002a3a:	40a00533          	neg	a0,a0
}
    80002a3e:	60e2                	ld	ra,24(sp)
    80002a40:	6442                	ld	s0,16(sp)
    80002a42:	64a2                	ld	s1,8(sp)
    80002a44:	6902                	ld	s2,0(sp)
    80002a46:	6105                	addi	sp,sp,32
    80002a48:	8082                	ret
    return -1;
    80002a4a:	557d                	li	a0,-1
    80002a4c:	bfcd                	j	80002a3e <fetchaddr+0x3e>
    80002a4e:	557d                	li	a0,-1
    80002a50:	b7fd                	j	80002a3e <fetchaddr+0x3e>

0000000080002a52 <fetchstr>:
{
    80002a52:	7179                	addi	sp,sp,-48
    80002a54:	f406                	sd	ra,40(sp)
    80002a56:	f022                	sd	s0,32(sp)
    80002a58:	ec26                	sd	s1,24(sp)
    80002a5a:	e84a                	sd	s2,16(sp)
    80002a5c:	e44e                	sd	s3,8(sp)
    80002a5e:	1800                	addi	s0,sp,48
    80002a60:	892a                	mv	s2,a0
    80002a62:	84ae                	mv	s1,a1
    80002a64:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	f18080e7          	jalr	-232(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a6e:	86ce                	mv	a3,s3
    80002a70:	864a                	mv	a2,s2
    80002a72:	85a6                	mv	a1,s1
    80002a74:	6928                	ld	a0,80(a0)
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	ce2080e7          	jalr	-798(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002a7e:	00054763          	bltz	a0,80002a8c <fetchstr+0x3a>
  return strlen(buf);
    80002a82:	8526                	mv	a0,s1
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	3be080e7          	jalr	958(ra) # 80000e42 <strlen>
}
    80002a8c:	70a2                	ld	ra,40(sp)
    80002a8e:	7402                	ld	s0,32(sp)
    80002a90:	64e2                	ld	s1,24(sp)
    80002a92:	6942                	ld	s2,16(sp)
    80002a94:	69a2                	ld	s3,8(sp)
    80002a96:	6145                	addi	sp,sp,48
    80002a98:	8082                	ret

0000000080002a9a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a9a:	1101                	addi	sp,sp,-32
    80002a9c:	ec06                	sd	ra,24(sp)
    80002a9e:	e822                	sd	s0,16(sp)
    80002aa0:	e426                	sd	s1,8(sp)
    80002aa2:	1000                	addi	s0,sp,32
    80002aa4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	ef2080e7          	jalr	-270(ra) # 80002998 <argraw>
    80002aae:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ab0:	4501                	li	a0,0
    80002ab2:	60e2                	ld	ra,24(sp)
    80002ab4:	6442                	ld	s0,16(sp)
    80002ab6:	64a2                	ld	s1,8(sp)
    80002ab8:	6105                	addi	sp,sp,32
    80002aba:	8082                	ret

0000000080002abc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002abc:	1101                	addi	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	ed0080e7          	jalr	-304(ra) # 80002998 <argraw>
    80002ad0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ad2:	4501                	li	a0,0
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	64a2                	ld	s1,8(sp)
    80002ada:	6105                	addi	sp,sp,32
    80002adc:	8082                	ret

0000000080002ade <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	e04a                	sd	s2,0(sp)
    80002ae8:	1000                	addi	s0,sp,32
    80002aea:	84ae                	mv	s1,a1
    80002aec:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	eaa080e7          	jalr	-342(ra) # 80002998 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002af6:	864a                	mv	a2,s2
    80002af8:	85a6                	mv	a1,s1
    80002afa:	00000097          	auipc	ra,0x0
    80002afe:	f58080e7          	jalr	-168(ra) # 80002a52 <fetchstr>
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	64a2                	ld	s1,8(sp)
    80002b08:	6902                	ld	s2,0(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret

0000000080002b0e <syscall>:
 "unlink", "link", "mkdir", "close", "trace"};


void
syscall(void)
{
    80002b0e:	7139                	addi	sp,sp,-64
    80002b10:	fc06                	sd	ra,56(sp)
    80002b12:	f822                	sd	s0,48(sp)
    80002b14:	f426                	sd	s1,40(sp)
    80002b16:	f04a                	sd	s2,32(sp)
    80002b18:	ec4e                	sd	s3,24(sp)
    80002b1a:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	e62080e7          	jalr	-414(ra) # 8000197e <myproc>
    80002b24:	892a                	mv	s2,a0
  num = p->trapframe->a7;
    80002b26:	6d3c                	ld	a5,88(a0)
    80002b28:	0a87a483          	lw	s1,168(a5)
  int argument = 0;
    80002b2c:	fc042623          	sw	zero,-52(s0)
  if(num == SYS_fork || num == SYS_kill || num == SYS_sbrk)
    80002b30:	47b1                	li	a5,12
    80002b32:	0297e063          	bltu	a5,s1,80002b52 <syscall+0x44>
    80002b36:	6785                	lui	a5,0x1
    80002b38:	04278793          	addi	a5,a5,66 # 1042 <_entry-0x7fffefbe>
    80002b3c:	0097d7b3          	srl	a5,a5,s1
    80002b40:	8b85                	andi	a5,a5,1
    80002b42:	cb81                	beqz	a5,80002b52 <syscall+0x44>
    argint(0, &argument);
    80002b44:	fcc40593          	addi	a1,s0,-52
    80002b48:	4501                	li	a0,0
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	f50080e7          	jalr	-176(ra) # 80002a9a <argint>

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b52:	fff4879b          	addiw	a5,s1,-1
    80002b56:	4755                	li	a4,21
    80002b58:	02f76163          	bltu	a4,a5,80002b7a <syscall+0x6c>
    80002b5c:	00349713          	slli	a4,s1,0x3
    80002b60:	00006797          	auipc	a5,0x6
    80002b64:	9d078793          	addi	a5,a5,-1584 # 80008530 <syscalls>
    80002b68:	97ba                	add	a5,a5,a4
    80002b6a:	639c                	ld	a5,0(a5)
    80002b6c:	c799                	beqz	a5,80002b7a <syscall+0x6c>
    p->trapframe->a0 = syscalls[num]();
    80002b6e:	05893983          	ld	s3,88(s2)
    80002b72:	9782                	jalr	a5
    80002b74:	06a9b823          	sd	a0,112(s3)
    80002b78:	a015                	j	80002b9c <syscall+0x8e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b7a:	86a6                	mv	a3,s1
    80002b7c:	15890613          	addi	a2,s2,344
    80002b80:	03092583          	lw	a1,48(s2)
    80002b84:	00006517          	auipc	a0,0x6
    80002b88:	87450513          	addi	a0,a0,-1932 # 800083f8 <states.0+0x150>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	9e8080e7          	jalr	-1560(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b94:	05893783          	ld	a5,88(s2)
    80002b98:	577d                	li	a4,-1
    80002b9a:	fbb8                	sd	a4,112(a5)

  int ret = p->trapframe->a0;

  /* If the system calls bit is on in the mask of the process, 
  then print the trace of the system call. */
  if(p->mask & (1 << num)){
    80002b9c:	03492783          	lw	a5,52(s2)
    80002ba0:	4097d7bb          	sraw	a5,a5,s1
    80002ba4:	8b85                	andi	a5,a5,1
    80002ba6:	c3a9                	beqz	a5,80002be8 <syscall+0xda>
  int ret = p->trapframe->a0;
    80002ba8:	05893783          	ld	a5,88(s2)
    80002bac:	5bb4                	lw	a3,112(a5)
    if(num == SYS_fork)
    80002bae:	4785                	li	a5,1
    80002bb0:	04f48363          	beq	s1,a5,80002bf6 <syscall+0xe8>
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    else if(num == SYS_kill || num == SYS_sbrk)
    80002bb4:	4799                	li	a5,6
    80002bb6:	00f48563          	beq	s1,a5,80002bc0 <syscall+0xb2>
    80002bba:	47b1                	li	a5,12
    80002bbc:	04f49c63          	bne	s1,a5,80002c14 <syscall+0x106>
      printf("%d: syscall %s %d -> %d\n", p->pid, sys_calls_names[num], argument, ret);
    80002bc0:	048e                	slli	s1,s1,0x3
    80002bc2:	00006797          	auipc	a5,0x6
    80002bc6:	d8678793          	addi	a5,a5,-634 # 80008948 <sys_calls_names>
    80002bca:	94be                	add	s1,s1,a5
    80002bcc:	8736                	mv	a4,a3
    80002bce:	fcc42683          	lw	a3,-52(s0)
    80002bd2:	6090                	ld	a2,0(s1)
    80002bd4:	03092583          	lw	a1,48(s2)
    80002bd8:	00006517          	auipc	a0,0x6
    80002bdc:	86050513          	addi	a0,a0,-1952 # 80008438 <states.0+0x190>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	994080e7          	jalr	-1644(ra) # 80000574 <printf>
    else
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
  }
}
    80002be8:	70e2                	ld	ra,56(sp)
    80002bea:	7442                	ld	s0,48(sp)
    80002bec:	74a2                	ld	s1,40(sp)
    80002bee:	7902                	ld	s2,32(sp)
    80002bf0:	69e2                	ld	s3,24(sp)
    80002bf2:	6121                	addi	sp,sp,64
    80002bf4:	8082                	ret
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    80002bf6:	00006617          	auipc	a2,0x6
    80002bfa:	d5a63603          	ld	a2,-678(a2) # 80008950 <sys_calls_names+0x8>
    80002bfe:	03092583          	lw	a1,48(s2)
    80002c02:	00006517          	auipc	a0,0x6
    80002c06:	81650513          	addi	a0,a0,-2026 # 80008418 <states.0+0x170>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	96a080e7          	jalr	-1686(ra) # 80000574 <printf>
    80002c12:	bfd9                	j	80002be8 <syscall+0xda>
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
    80002c14:	048e                	slli	s1,s1,0x3
    80002c16:	00006797          	auipc	a5,0x6
    80002c1a:	d3278793          	addi	a5,a5,-718 # 80008948 <sys_calls_names>
    80002c1e:	94be                	add	s1,s1,a5
    80002c20:	6090                	ld	a2,0(s1)
    80002c22:	03092583          	lw	a1,48(s2)
    80002c26:	00006517          	auipc	a0,0x6
    80002c2a:	83250513          	addi	a0,a0,-1998 # 80008458 <states.0+0x1b0>
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	946080e7          	jalr	-1722(ra) # 80000574 <printf>
}
    80002c36:	bf4d                	j	80002be8 <syscall+0xda>

0000000080002c38 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c38:	1101                	addi	sp,sp,-32
    80002c3a:	ec06                	sd	ra,24(sp)
    80002c3c:	e822                	sd	s0,16(sp)
    80002c3e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c40:	fec40593          	addi	a1,s0,-20
    80002c44:	4501                	li	a0,0
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	e54080e7          	jalr	-428(ra) # 80002a9a <argint>
    return -1;
    80002c4e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c50:	00054963          	bltz	a0,80002c62 <sys_exit+0x2a>
  exit(n);
    80002c54:	fec42503          	lw	a0,-20(s0)
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	64e080e7          	jalr	1614(ra) # 800022a6 <exit>
  return 0;  // not reached
    80002c60:	4781                	li	a5,0
}
    80002c62:	853e                	mv	a0,a5
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	6105                	addi	sp,sp,32
    80002c6a:	8082                	ret

0000000080002c6c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c6c:	1141                	addi	sp,sp,-16
    80002c6e:	e406                	sd	ra,8(sp)
    80002c70:	e022                	sd	s0,0(sp)
    80002c72:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	d0a080e7          	jalr	-758(ra) # 8000197e <myproc>
}
    80002c7c:	5908                	lw	a0,48(a0)
    80002c7e:	60a2                	ld	ra,8(sp)
    80002c80:	6402                	ld	s0,0(sp)
    80002c82:	0141                	addi	sp,sp,16
    80002c84:	8082                	ret

0000000080002c86 <sys_fork>:

uint64
sys_fork(void)
{
    80002c86:	1141                	addi	sp,sp,-16
    80002c88:	e406                	sd	ra,8(sp)
    80002c8a:	e022                	sd	s0,0(sp)
    80002c8c:	0800                	addi	s0,sp,16
  return fork();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	0c2080e7          	jalr	194(ra) # 80001d50 <fork>
}
    80002c96:	60a2                	ld	ra,8(sp)
    80002c98:	6402                	ld	s0,0(sp)
    80002c9a:	0141                	addi	sp,sp,16
    80002c9c:	8082                	ret

0000000080002c9e <sys_wait>:

uint64
sys_wait(void)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ca6:	fe840593          	addi	a1,s0,-24
    80002caa:	4501                	li	a0,0
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	e10080e7          	jalr	-496(ra) # 80002abc <argaddr>
    80002cb4:	87aa                	mv	a5,a0
    return -1;
    80002cb6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cb8:	0007c863          	bltz	a5,80002cc8 <sys_wait+0x2a>
  return wait(p);
    80002cbc:	fe843503          	ld	a0,-24(s0)
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	3ee080e7          	jalr	1006(ra) # 800020ae <wait>
}
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret

0000000080002cd0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cd0:	7179                	addi	sp,sp,-48
    80002cd2:	f406                	sd	ra,40(sp)
    80002cd4:	f022                	sd	s0,32(sp)
    80002cd6:	ec26                	sd	s1,24(sp)
    80002cd8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cda:	fdc40593          	addi	a1,s0,-36
    80002cde:	4501                	li	a0,0
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	dba080e7          	jalr	-582(ra) # 80002a9a <argint>
    return -1;
    80002ce8:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002cea:	00054f63          	bltz	a0,80002d08 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	c90080e7          	jalr	-880(ra) # 8000197e <myproc>
    80002cf6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cf8:	fdc42503          	lw	a0,-36(s0)
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	fe0080e7          	jalr	-32(ra) # 80001cdc <growproc>
    80002d04:	00054863          	bltz	a0,80002d14 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002d08:	8526                	mv	a0,s1
    80002d0a:	70a2                	ld	ra,40(sp)
    80002d0c:	7402                	ld	s0,32(sp)
    80002d0e:	64e2                	ld	s1,24(sp)
    80002d10:	6145                	addi	sp,sp,48
    80002d12:	8082                	ret
    return -1;
    80002d14:	54fd                	li	s1,-1
    80002d16:	bfcd                	j	80002d08 <sys_sbrk+0x38>

0000000080002d18 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d18:	7139                	addi	sp,sp,-64
    80002d1a:	fc06                	sd	ra,56(sp)
    80002d1c:	f822                	sd	s0,48(sp)
    80002d1e:	f426                	sd	s1,40(sp)
    80002d20:	f04a                	sd	s2,32(sp)
    80002d22:	ec4e                	sd	s3,24(sp)
    80002d24:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d26:	fcc40593          	addi	a1,s0,-52
    80002d2a:	4501                	li	a0,0
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	d6e080e7          	jalr	-658(ra) # 80002a9a <argint>
    return -1;
    80002d34:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d36:	06054563          	bltz	a0,80002da0 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d3a:	00014517          	auipc	a0,0x14
    80002d3e:	39650513          	addi	a0,a0,918 # 800170d0 <tickslock>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	e80080e7          	jalr	-384(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002d4a:	00006917          	auipc	s2,0x6
    80002d4e:	2e692903          	lw	s2,742(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d52:	fcc42783          	lw	a5,-52(s0)
    80002d56:	cf85                	beqz	a5,80002d8e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d58:	00014997          	auipc	s3,0x14
    80002d5c:	37898993          	addi	s3,s3,888 # 800170d0 <tickslock>
    80002d60:	00006497          	auipc	s1,0x6
    80002d64:	2d048493          	addi	s1,s1,720 # 80009030 <ticks>
    if(myproc()->killed){
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	c16080e7          	jalr	-1002(ra) # 8000197e <myproc>
    80002d70:	551c                	lw	a5,40(a0)
    80002d72:	ef9d                	bnez	a5,80002db0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d74:	85ce                	mv	a1,s3
    80002d76:	8526                	mv	a0,s1
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	2d2080e7          	jalr	722(ra) # 8000204a <sleep>
  while(ticks - ticks0 < n){
    80002d80:	409c                	lw	a5,0(s1)
    80002d82:	412787bb          	subw	a5,a5,s2
    80002d86:	fcc42703          	lw	a4,-52(s0)
    80002d8a:	fce7efe3          	bltu	a5,a4,80002d68 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d8e:	00014517          	auipc	a0,0x14
    80002d92:	34250513          	addi	a0,a0,834 # 800170d0 <tickslock>
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	ee0080e7          	jalr	-288(ra) # 80000c76 <release>
  return 0;
    80002d9e:	4781                	li	a5,0
}
    80002da0:	853e                	mv	a0,a5
    80002da2:	70e2                	ld	ra,56(sp)
    80002da4:	7442                	ld	s0,48(sp)
    80002da6:	74a2                	ld	s1,40(sp)
    80002da8:	7902                	ld	s2,32(sp)
    80002daa:	69e2                	ld	s3,24(sp)
    80002dac:	6121                	addi	sp,sp,64
    80002dae:	8082                	ret
      release(&tickslock);
    80002db0:	00014517          	auipc	a0,0x14
    80002db4:	32050513          	addi	a0,a0,800 # 800170d0 <tickslock>
    80002db8:	ffffe097          	auipc	ra,0xffffe
    80002dbc:	ebe080e7          	jalr	-322(ra) # 80000c76 <release>
      return -1;
    80002dc0:	57fd                	li	a5,-1
    80002dc2:	bff9                	j	80002da0 <sys_sleep+0x88>

0000000080002dc4 <sys_trace>:


void
sys_trace(void)
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	1000                	addi	s0,sp,32
  int mask;
  int pid;

  if(argint(0, &mask) >= 0 && argint(1, &pid) >= 0)
    80002dcc:	fec40593          	addi	a1,s0,-20
    80002dd0:	4501                	li	a0,0
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	cc8080e7          	jalr	-824(ra) # 80002a9a <argint>
    80002dda:	00055663          	bgez	a0,80002de6 <sys_trace+0x22>
    trace(mask, pid);
}
    80002dde:	60e2                	ld	ra,24(sp)
    80002de0:	6442                	ld	s0,16(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret
  if(argint(0, &mask) >= 0 && argint(1, &pid) >= 0)
    80002de6:	fe840593          	addi	a1,s0,-24
    80002dea:	4505                	li	a0,1
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	cae080e7          	jalr	-850(ra) # 80002a9a <argint>
    80002df4:	fe0545e3          	bltz	a0,80002dde <sys_trace+0x1a>
    trace(mask, pid);
    80002df8:	fe842583          	lw	a1,-24(s0)
    80002dfc:	fec42503          	lw	a0,-20(s0)
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	57c080e7          	jalr	1404(ra) # 8000237c <trace>
}
    80002e08:	bfd9                	j	80002dde <sys_trace+0x1a>

0000000080002e0a <sys_kill>:


uint64
sys_kill(void)
{
    80002e0a:	1101                	addi	sp,sp,-32
    80002e0c:	ec06                	sd	ra,24(sp)
    80002e0e:	e822                	sd	s0,16(sp)
    80002e10:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e12:	fec40593          	addi	a1,s0,-20
    80002e16:	4501                	li	a0,0
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	c82080e7          	jalr	-894(ra) # 80002a9a <argint>
    80002e20:	87aa                	mv	a5,a0
    return -1;
    80002e22:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e24:	0007c863          	bltz	a5,80002e34 <sys_kill+0x2a>
  return kill(pid);
    80002e28:	fec42503          	lw	a0,-20(s0)
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	5ae080e7          	jalr	1454(ra) # 800023da <kill>
}
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	e426                	sd	s1,8(sp)
    80002e44:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e46:	00014517          	auipc	a0,0x14
    80002e4a:	28a50513          	addi	a0,a0,650 # 800170d0 <tickslock>
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	d74080e7          	jalr	-652(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002e56:	00006497          	auipc	s1,0x6
    80002e5a:	1da4a483          	lw	s1,474(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e5e:	00014517          	auipc	a0,0x14
    80002e62:	27250513          	addi	a0,a0,626 # 800170d0 <tickslock>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	e10080e7          	jalr	-496(ra) # 80000c76 <release>
  return xticks;
}
    80002e6e:	02049513          	slli	a0,s1,0x20
    80002e72:	9101                	srli	a0,a0,0x20
    80002e74:	60e2                	ld	ra,24(sp)
    80002e76:	6442                	ld	s0,16(sp)
    80002e78:	64a2                	ld	s1,8(sp)
    80002e7a:	6105                	addi	sp,sp,32
    80002e7c:	8082                	ret

0000000080002e7e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e7e:	7179                	addi	sp,sp,-48
    80002e80:	f406                	sd	ra,40(sp)
    80002e82:	f022                	sd	s0,32(sp)
    80002e84:	ec26                	sd	s1,24(sp)
    80002e86:	e84a                	sd	s2,16(sp)
    80002e88:	e44e                	sd	s3,8(sp)
    80002e8a:	e052                	sd	s4,0(sp)
    80002e8c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e8e:	00005597          	auipc	a1,0x5
    80002e92:	75a58593          	addi	a1,a1,1882 # 800085e8 <syscalls+0xb8>
    80002e96:	00014517          	auipc	a0,0x14
    80002e9a:	25250513          	addi	a0,a0,594 # 800170e8 <bcache>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	c94080e7          	jalr	-876(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ea6:	0001c797          	auipc	a5,0x1c
    80002eaa:	24278793          	addi	a5,a5,578 # 8001f0e8 <bcache+0x8000>
    80002eae:	0001c717          	auipc	a4,0x1c
    80002eb2:	4a270713          	addi	a4,a4,1186 # 8001f350 <bcache+0x8268>
    80002eb6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eba:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ebe:	00014497          	auipc	s1,0x14
    80002ec2:	24248493          	addi	s1,s1,578 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ec6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ec8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eca:	00005a17          	auipc	s4,0x5
    80002ece:	726a0a13          	addi	s4,s4,1830 # 800085f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002ed2:	2b893783          	ld	a5,696(s2)
    80002ed6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ed8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002edc:	85d2                	mv	a1,s4
    80002ede:	01048513          	addi	a0,s1,16
    80002ee2:	00001097          	auipc	ra,0x1
    80002ee6:	4c2080e7          	jalr	1218(ra) # 800043a4 <initsleeplock>
    bcache.head.next->prev = b;
    80002eea:	2b893783          	ld	a5,696(s2)
    80002eee:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ef0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ef4:	45848493          	addi	s1,s1,1112
    80002ef8:	fd349de3          	bne	s1,s3,80002ed2 <binit+0x54>
  }
}
    80002efc:	70a2                	ld	ra,40(sp)
    80002efe:	7402                	ld	s0,32(sp)
    80002f00:	64e2                	ld	s1,24(sp)
    80002f02:	6942                	ld	s2,16(sp)
    80002f04:	69a2                	ld	s3,8(sp)
    80002f06:	6a02                	ld	s4,0(sp)
    80002f08:	6145                	addi	sp,sp,48
    80002f0a:	8082                	ret

0000000080002f0c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f0c:	7179                	addi	sp,sp,-48
    80002f0e:	f406                	sd	ra,40(sp)
    80002f10:	f022                	sd	s0,32(sp)
    80002f12:	ec26                	sd	s1,24(sp)
    80002f14:	e84a                	sd	s2,16(sp)
    80002f16:	e44e                	sd	s3,8(sp)
    80002f18:	1800                	addi	s0,sp,48
    80002f1a:	892a                	mv	s2,a0
    80002f1c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f1e:	00014517          	auipc	a0,0x14
    80002f22:	1ca50513          	addi	a0,a0,458 # 800170e8 <bcache>
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	c9c080e7          	jalr	-868(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f2e:	0001c497          	auipc	s1,0x1c
    80002f32:	4724b483          	ld	s1,1138(s1) # 8001f3a0 <bcache+0x82b8>
    80002f36:	0001c797          	auipc	a5,0x1c
    80002f3a:	41a78793          	addi	a5,a5,1050 # 8001f350 <bcache+0x8268>
    80002f3e:	02f48f63          	beq	s1,a5,80002f7c <bread+0x70>
    80002f42:	873e                	mv	a4,a5
    80002f44:	a021                	j	80002f4c <bread+0x40>
    80002f46:	68a4                	ld	s1,80(s1)
    80002f48:	02e48a63          	beq	s1,a4,80002f7c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f4c:	449c                	lw	a5,8(s1)
    80002f4e:	ff279ce3          	bne	a5,s2,80002f46 <bread+0x3a>
    80002f52:	44dc                	lw	a5,12(s1)
    80002f54:	ff3799e3          	bne	a5,s3,80002f46 <bread+0x3a>
      b->refcnt++;
    80002f58:	40bc                	lw	a5,64(s1)
    80002f5a:	2785                	addiw	a5,a5,1
    80002f5c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f5e:	00014517          	auipc	a0,0x14
    80002f62:	18a50513          	addi	a0,a0,394 # 800170e8 <bcache>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	d10080e7          	jalr	-752(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002f6e:	01048513          	addi	a0,s1,16
    80002f72:	00001097          	auipc	ra,0x1
    80002f76:	46c080e7          	jalr	1132(ra) # 800043de <acquiresleep>
      return b;
    80002f7a:	a8b9                	j	80002fd8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f7c:	0001c497          	auipc	s1,0x1c
    80002f80:	41c4b483          	ld	s1,1052(s1) # 8001f398 <bcache+0x82b0>
    80002f84:	0001c797          	auipc	a5,0x1c
    80002f88:	3cc78793          	addi	a5,a5,972 # 8001f350 <bcache+0x8268>
    80002f8c:	00f48863          	beq	s1,a5,80002f9c <bread+0x90>
    80002f90:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f92:	40bc                	lw	a5,64(s1)
    80002f94:	cf81                	beqz	a5,80002fac <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f96:	64a4                	ld	s1,72(s1)
    80002f98:	fee49de3          	bne	s1,a4,80002f92 <bread+0x86>
  panic("bget: no buffers");
    80002f9c:	00005517          	auipc	a0,0x5
    80002fa0:	65c50513          	addi	a0,a0,1628 # 800085f8 <syscalls+0xc8>
    80002fa4:	ffffd097          	auipc	ra,0xffffd
    80002fa8:	586080e7          	jalr	1414(ra) # 8000052a <panic>
      b->dev = dev;
    80002fac:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fb0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fb4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fb8:	4785                	li	a5,1
    80002fba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fbc:	00014517          	auipc	a0,0x14
    80002fc0:	12c50513          	addi	a0,a0,300 # 800170e8 <bcache>
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	cb2080e7          	jalr	-846(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002fcc:	01048513          	addi	a0,s1,16
    80002fd0:	00001097          	auipc	ra,0x1
    80002fd4:	40e080e7          	jalr	1038(ra) # 800043de <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fd8:	409c                	lw	a5,0(s1)
    80002fda:	cb89                	beqz	a5,80002fec <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fdc:	8526                	mv	a0,s1
    80002fde:	70a2                	ld	ra,40(sp)
    80002fe0:	7402                	ld	s0,32(sp)
    80002fe2:	64e2                	ld	s1,24(sp)
    80002fe4:	6942                	ld	s2,16(sp)
    80002fe6:	69a2                	ld	s3,8(sp)
    80002fe8:	6145                	addi	sp,sp,48
    80002fea:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fec:	4581                	li	a1,0
    80002fee:	8526                	mv	a0,s1
    80002ff0:	00003097          	auipc	ra,0x3
    80002ff4:	f26080e7          	jalr	-218(ra) # 80005f16 <virtio_disk_rw>
    b->valid = 1;
    80002ff8:	4785                	li	a5,1
    80002ffa:	c09c                	sw	a5,0(s1)
  return b;
    80002ffc:	b7c5                	j	80002fdc <bread+0xd0>

0000000080002ffe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	1000                	addi	s0,sp,32
    80003008:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000300a:	0541                	addi	a0,a0,16
    8000300c:	00001097          	auipc	ra,0x1
    80003010:	46c080e7          	jalr	1132(ra) # 80004478 <holdingsleep>
    80003014:	cd01                	beqz	a0,8000302c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003016:	4585                	li	a1,1
    80003018:	8526                	mv	a0,s1
    8000301a:	00003097          	auipc	ra,0x3
    8000301e:	efc080e7          	jalr	-260(ra) # 80005f16 <virtio_disk_rw>
}
    80003022:	60e2                	ld	ra,24(sp)
    80003024:	6442                	ld	s0,16(sp)
    80003026:	64a2                	ld	s1,8(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret
    panic("bwrite");
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	5e450513          	addi	a0,a0,1508 # 80008610 <syscalls+0xe0>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	4f6080e7          	jalr	1270(ra) # 8000052a <panic>

000000008000303c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000303c:	1101                	addi	sp,sp,-32
    8000303e:	ec06                	sd	ra,24(sp)
    80003040:	e822                	sd	s0,16(sp)
    80003042:	e426                	sd	s1,8(sp)
    80003044:	e04a                	sd	s2,0(sp)
    80003046:	1000                	addi	s0,sp,32
    80003048:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000304a:	01050913          	addi	s2,a0,16
    8000304e:	854a                	mv	a0,s2
    80003050:	00001097          	auipc	ra,0x1
    80003054:	428080e7          	jalr	1064(ra) # 80004478 <holdingsleep>
    80003058:	c92d                	beqz	a0,800030ca <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000305a:	854a                	mv	a0,s2
    8000305c:	00001097          	auipc	ra,0x1
    80003060:	3d8080e7          	jalr	984(ra) # 80004434 <releasesleep>

  acquire(&bcache.lock);
    80003064:	00014517          	auipc	a0,0x14
    80003068:	08450513          	addi	a0,a0,132 # 800170e8 <bcache>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	b56080e7          	jalr	-1194(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003074:	40bc                	lw	a5,64(s1)
    80003076:	37fd                	addiw	a5,a5,-1
    80003078:	0007871b          	sext.w	a4,a5
    8000307c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000307e:	eb05                	bnez	a4,800030ae <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003080:	68bc                	ld	a5,80(s1)
    80003082:	64b8                	ld	a4,72(s1)
    80003084:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003086:	64bc                	ld	a5,72(s1)
    80003088:	68b8                	ld	a4,80(s1)
    8000308a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000308c:	0001c797          	auipc	a5,0x1c
    80003090:	05c78793          	addi	a5,a5,92 # 8001f0e8 <bcache+0x8000>
    80003094:	2b87b703          	ld	a4,696(a5)
    80003098:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000309a:	0001c717          	auipc	a4,0x1c
    8000309e:	2b670713          	addi	a4,a4,694 # 8001f350 <bcache+0x8268>
    800030a2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030a4:	2b87b703          	ld	a4,696(a5)
    800030a8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030aa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030ae:	00014517          	auipc	a0,0x14
    800030b2:	03a50513          	addi	a0,a0,58 # 800170e8 <bcache>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	bc0080e7          	jalr	-1088(ra) # 80000c76 <release>
}
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	64a2                	ld	s1,8(sp)
    800030c4:	6902                	ld	s2,0(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret
    panic("brelse");
    800030ca:	00005517          	auipc	a0,0x5
    800030ce:	54e50513          	addi	a0,a0,1358 # 80008618 <syscalls+0xe8>
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	458080e7          	jalr	1112(ra) # 8000052a <panic>

00000000800030da <bpin>:

void
bpin(struct buf *b) {
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	1000                	addi	s0,sp,32
    800030e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030e6:	00014517          	auipc	a0,0x14
    800030ea:	00250513          	addi	a0,a0,2 # 800170e8 <bcache>
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	ad4080e7          	jalr	-1324(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800030f6:	40bc                	lw	a5,64(s1)
    800030f8:	2785                	addiw	a5,a5,1
    800030fa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030fc:	00014517          	auipc	a0,0x14
    80003100:	fec50513          	addi	a0,a0,-20 # 800170e8 <bcache>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	b72080e7          	jalr	-1166(ra) # 80000c76 <release>
}
    8000310c:	60e2                	ld	ra,24(sp)
    8000310e:	6442                	ld	s0,16(sp)
    80003110:	64a2                	ld	s1,8(sp)
    80003112:	6105                	addi	sp,sp,32
    80003114:	8082                	ret

0000000080003116 <bunpin>:

void
bunpin(struct buf *b) {
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	e426                	sd	s1,8(sp)
    8000311e:	1000                	addi	s0,sp,32
    80003120:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003122:	00014517          	auipc	a0,0x14
    80003126:	fc650513          	addi	a0,a0,-58 # 800170e8 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	a98080e7          	jalr	-1384(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003132:	40bc                	lw	a5,64(s1)
    80003134:	37fd                	addiw	a5,a5,-1
    80003136:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003138:	00014517          	auipc	a0,0x14
    8000313c:	fb050513          	addi	a0,a0,-80 # 800170e8 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	b36080e7          	jalr	-1226(ra) # 80000c76 <release>
}
    80003148:	60e2                	ld	ra,24(sp)
    8000314a:	6442                	ld	s0,16(sp)
    8000314c:	64a2                	ld	s1,8(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret

0000000080003152 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003152:	1101                	addi	sp,sp,-32
    80003154:	ec06                	sd	ra,24(sp)
    80003156:	e822                	sd	s0,16(sp)
    80003158:	e426                	sd	s1,8(sp)
    8000315a:	e04a                	sd	s2,0(sp)
    8000315c:	1000                	addi	s0,sp,32
    8000315e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003160:	00d5d59b          	srliw	a1,a1,0xd
    80003164:	0001c797          	auipc	a5,0x1c
    80003168:	6607a783          	lw	a5,1632(a5) # 8001f7c4 <sb+0x1c>
    8000316c:	9dbd                	addw	a1,a1,a5
    8000316e:	00000097          	auipc	ra,0x0
    80003172:	d9e080e7          	jalr	-610(ra) # 80002f0c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003176:	0074f713          	andi	a4,s1,7
    8000317a:	4785                	li	a5,1
    8000317c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003180:	14ce                	slli	s1,s1,0x33
    80003182:	90d9                	srli	s1,s1,0x36
    80003184:	00950733          	add	a4,a0,s1
    80003188:	05874703          	lbu	a4,88(a4)
    8000318c:	00e7f6b3          	and	a3,a5,a4
    80003190:	c69d                	beqz	a3,800031be <bfree+0x6c>
    80003192:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003194:	94aa                	add	s1,s1,a0
    80003196:	fff7c793          	not	a5,a5
    8000319a:	8ff9                	and	a5,a5,a4
    8000319c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	11e080e7          	jalr	286(ra) # 800042be <log_write>
  brelse(bp);
    800031a8:	854a                	mv	a0,s2
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	e92080e7          	jalr	-366(ra) # 8000303c <brelse>
}
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6902                	ld	s2,0(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret
    panic("freeing free block");
    800031be:	00005517          	auipc	a0,0x5
    800031c2:	46250513          	addi	a0,a0,1122 # 80008620 <syscalls+0xf0>
    800031c6:	ffffd097          	auipc	ra,0xffffd
    800031ca:	364080e7          	jalr	868(ra) # 8000052a <panic>

00000000800031ce <balloc>:
{
    800031ce:	711d                	addi	sp,sp,-96
    800031d0:	ec86                	sd	ra,88(sp)
    800031d2:	e8a2                	sd	s0,80(sp)
    800031d4:	e4a6                	sd	s1,72(sp)
    800031d6:	e0ca                	sd	s2,64(sp)
    800031d8:	fc4e                	sd	s3,56(sp)
    800031da:	f852                	sd	s4,48(sp)
    800031dc:	f456                	sd	s5,40(sp)
    800031de:	f05a                	sd	s6,32(sp)
    800031e0:	ec5e                	sd	s7,24(sp)
    800031e2:	e862                	sd	s8,16(sp)
    800031e4:	e466                	sd	s9,8(sp)
    800031e6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031e8:	0001c797          	auipc	a5,0x1c
    800031ec:	5c47a783          	lw	a5,1476(a5) # 8001f7ac <sb+0x4>
    800031f0:	cbd1                	beqz	a5,80003284 <balloc+0xb6>
    800031f2:	8baa                	mv	s7,a0
    800031f4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031f6:	0001cb17          	auipc	s6,0x1c
    800031fa:	5b2b0b13          	addi	s6,s6,1458 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fe:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003200:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003202:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003204:	6c89                	lui	s9,0x2
    80003206:	a831                	j	80003222 <balloc+0x54>
    brelse(bp);
    80003208:	854a                	mv	a0,s2
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	e32080e7          	jalr	-462(ra) # 8000303c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003212:	015c87bb          	addw	a5,s9,s5
    80003216:	00078a9b          	sext.w	s5,a5
    8000321a:	004b2703          	lw	a4,4(s6)
    8000321e:	06eaf363          	bgeu	s5,a4,80003284 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003222:	41fad79b          	sraiw	a5,s5,0x1f
    80003226:	0137d79b          	srliw	a5,a5,0x13
    8000322a:	015787bb          	addw	a5,a5,s5
    8000322e:	40d7d79b          	sraiw	a5,a5,0xd
    80003232:	01cb2583          	lw	a1,28(s6)
    80003236:	9dbd                	addw	a1,a1,a5
    80003238:	855e                	mv	a0,s7
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	cd2080e7          	jalr	-814(ra) # 80002f0c <bread>
    80003242:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003244:	004b2503          	lw	a0,4(s6)
    80003248:	000a849b          	sext.w	s1,s5
    8000324c:	8662                	mv	a2,s8
    8000324e:	faa4fde3          	bgeu	s1,a0,80003208 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003252:	41f6579b          	sraiw	a5,a2,0x1f
    80003256:	01d7d69b          	srliw	a3,a5,0x1d
    8000325a:	00c6873b          	addw	a4,a3,a2
    8000325e:	00777793          	andi	a5,a4,7
    80003262:	9f95                	subw	a5,a5,a3
    80003264:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003268:	4037571b          	sraiw	a4,a4,0x3
    8000326c:	00e906b3          	add	a3,s2,a4
    80003270:	0586c683          	lbu	a3,88(a3)
    80003274:	00d7f5b3          	and	a1,a5,a3
    80003278:	cd91                	beqz	a1,80003294 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000327a:	2605                	addiw	a2,a2,1
    8000327c:	2485                	addiw	s1,s1,1
    8000327e:	fd4618e3          	bne	a2,s4,8000324e <balloc+0x80>
    80003282:	b759                	j	80003208 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003284:	00005517          	auipc	a0,0x5
    80003288:	3b450513          	addi	a0,a0,948 # 80008638 <syscalls+0x108>
    8000328c:	ffffd097          	auipc	ra,0xffffd
    80003290:	29e080e7          	jalr	670(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003294:	974a                	add	a4,a4,s2
    80003296:	8fd5                	or	a5,a5,a3
    80003298:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	020080e7          	jalr	32(ra) # 800042be <log_write>
        brelse(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	d94080e7          	jalr	-620(ra) # 8000303c <brelse>
  bp = bread(dev, bno);
    800032b0:	85a6                	mv	a1,s1
    800032b2:	855e                	mv	a0,s7
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	c58080e7          	jalr	-936(ra) # 80002f0c <bread>
    800032bc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032be:	40000613          	li	a2,1024
    800032c2:	4581                	li	a1,0
    800032c4:	05850513          	addi	a0,a0,88
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	9f6080e7          	jalr	-1546(ra) # 80000cbe <memset>
  log_write(bp);
    800032d0:	854a                	mv	a0,s2
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	fec080e7          	jalr	-20(ra) # 800042be <log_write>
  brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	d60080e7          	jalr	-672(ra) # 8000303c <brelse>
}
    800032e4:	8526                	mv	a0,s1
    800032e6:	60e6                	ld	ra,88(sp)
    800032e8:	6446                	ld	s0,80(sp)
    800032ea:	64a6                	ld	s1,72(sp)
    800032ec:	6906                	ld	s2,64(sp)
    800032ee:	79e2                	ld	s3,56(sp)
    800032f0:	7a42                	ld	s4,48(sp)
    800032f2:	7aa2                	ld	s5,40(sp)
    800032f4:	7b02                	ld	s6,32(sp)
    800032f6:	6be2                	ld	s7,24(sp)
    800032f8:	6c42                	ld	s8,16(sp)
    800032fa:	6ca2                	ld	s9,8(sp)
    800032fc:	6125                	addi	sp,sp,96
    800032fe:	8082                	ret

0000000080003300 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003300:	7179                	addi	sp,sp,-48
    80003302:	f406                	sd	ra,40(sp)
    80003304:	f022                	sd	s0,32(sp)
    80003306:	ec26                	sd	s1,24(sp)
    80003308:	e84a                	sd	s2,16(sp)
    8000330a:	e44e                	sd	s3,8(sp)
    8000330c:	e052                	sd	s4,0(sp)
    8000330e:	1800                	addi	s0,sp,48
    80003310:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003312:	47ad                	li	a5,11
    80003314:	04b7fe63          	bgeu	a5,a1,80003370 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003318:	ff45849b          	addiw	s1,a1,-12
    8000331c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003320:	0ff00793          	li	a5,255
    80003324:	0ae7e463          	bltu	a5,a4,800033cc <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003328:	08052583          	lw	a1,128(a0)
    8000332c:	c5b5                	beqz	a1,80003398 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000332e:	00092503          	lw	a0,0(s2)
    80003332:	00000097          	auipc	ra,0x0
    80003336:	bda080e7          	jalr	-1062(ra) # 80002f0c <bread>
    8000333a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000333c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003340:	02049713          	slli	a4,s1,0x20
    80003344:	01e75593          	srli	a1,a4,0x1e
    80003348:	00b784b3          	add	s1,a5,a1
    8000334c:	0004a983          	lw	s3,0(s1)
    80003350:	04098e63          	beqz	s3,800033ac <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003354:	8552                	mv	a0,s4
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	ce6080e7          	jalr	-794(ra) # 8000303c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000335e:	854e                	mv	a0,s3
    80003360:	70a2                	ld	ra,40(sp)
    80003362:	7402                	ld	s0,32(sp)
    80003364:	64e2                	ld	s1,24(sp)
    80003366:	6942                	ld	s2,16(sp)
    80003368:	69a2                	ld	s3,8(sp)
    8000336a:	6a02                	ld	s4,0(sp)
    8000336c:	6145                	addi	sp,sp,48
    8000336e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003370:	02059793          	slli	a5,a1,0x20
    80003374:	01e7d593          	srli	a1,a5,0x1e
    80003378:	00b504b3          	add	s1,a0,a1
    8000337c:	0504a983          	lw	s3,80(s1)
    80003380:	fc099fe3          	bnez	s3,8000335e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003384:	4108                	lw	a0,0(a0)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e48080e7          	jalr	-440(ra) # 800031ce <balloc>
    8000338e:	0005099b          	sext.w	s3,a0
    80003392:	0534a823          	sw	s3,80(s1)
    80003396:	b7e1                	j	8000335e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003398:	4108                	lw	a0,0(a0)
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	e34080e7          	jalr	-460(ra) # 800031ce <balloc>
    800033a2:	0005059b          	sext.w	a1,a0
    800033a6:	08b92023          	sw	a1,128(s2)
    800033aa:	b751                	j	8000332e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033ac:	00092503          	lw	a0,0(s2)
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e1e080e7          	jalr	-482(ra) # 800031ce <balloc>
    800033b8:	0005099b          	sext.w	s3,a0
    800033bc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033c0:	8552                	mv	a0,s4
    800033c2:	00001097          	auipc	ra,0x1
    800033c6:	efc080e7          	jalr	-260(ra) # 800042be <log_write>
    800033ca:	b769                	j	80003354 <bmap+0x54>
  panic("bmap: out of range");
    800033cc:	00005517          	auipc	a0,0x5
    800033d0:	28450513          	addi	a0,a0,644 # 80008650 <syscalls+0x120>
    800033d4:	ffffd097          	auipc	ra,0xffffd
    800033d8:	156080e7          	jalr	342(ra) # 8000052a <panic>

00000000800033dc <iget>:
{
    800033dc:	7179                	addi	sp,sp,-48
    800033de:	f406                	sd	ra,40(sp)
    800033e0:	f022                	sd	s0,32(sp)
    800033e2:	ec26                	sd	s1,24(sp)
    800033e4:	e84a                	sd	s2,16(sp)
    800033e6:	e44e                	sd	s3,8(sp)
    800033e8:	e052                	sd	s4,0(sp)
    800033ea:	1800                	addi	s0,sp,48
    800033ec:	89aa                	mv	s3,a0
    800033ee:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033f0:	0001c517          	auipc	a0,0x1c
    800033f4:	3d850513          	addi	a0,a0,984 # 8001f7c8 <itable>
    800033f8:	ffffd097          	auipc	ra,0xffffd
    800033fc:	7ca080e7          	jalr	1994(ra) # 80000bc2 <acquire>
  empty = 0;
    80003400:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003402:	0001c497          	auipc	s1,0x1c
    80003406:	3de48493          	addi	s1,s1,990 # 8001f7e0 <itable+0x18>
    8000340a:	0001e697          	auipc	a3,0x1e
    8000340e:	e6668693          	addi	a3,a3,-410 # 80021270 <log>
    80003412:	a039                	j	80003420 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003414:	02090b63          	beqz	s2,8000344a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003418:	08848493          	addi	s1,s1,136
    8000341c:	02d48a63          	beq	s1,a3,80003450 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003420:	449c                	lw	a5,8(s1)
    80003422:	fef059e3          	blez	a5,80003414 <iget+0x38>
    80003426:	4098                	lw	a4,0(s1)
    80003428:	ff3716e3          	bne	a4,s3,80003414 <iget+0x38>
    8000342c:	40d8                	lw	a4,4(s1)
    8000342e:	ff4713e3          	bne	a4,s4,80003414 <iget+0x38>
      ip->ref++;
    80003432:	2785                	addiw	a5,a5,1
    80003434:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003436:	0001c517          	auipc	a0,0x1c
    8000343a:	39250513          	addi	a0,a0,914 # 8001f7c8 <itable>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	838080e7          	jalr	-1992(ra) # 80000c76 <release>
      return ip;
    80003446:	8926                	mv	s2,s1
    80003448:	a03d                	j	80003476 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000344a:	f7f9                	bnez	a5,80003418 <iget+0x3c>
    8000344c:	8926                	mv	s2,s1
    8000344e:	b7e9                	j	80003418 <iget+0x3c>
  if(empty == 0)
    80003450:	02090c63          	beqz	s2,80003488 <iget+0xac>
  ip->dev = dev;
    80003454:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003458:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000345c:	4785                	li	a5,1
    8000345e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003462:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003466:	0001c517          	auipc	a0,0x1c
    8000346a:	36250513          	addi	a0,a0,866 # 8001f7c8 <itable>
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	808080e7          	jalr	-2040(ra) # 80000c76 <release>
}
    80003476:	854a                	mv	a0,s2
    80003478:	70a2                	ld	ra,40(sp)
    8000347a:	7402                	ld	s0,32(sp)
    8000347c:	64e2                	ld	s1,24(sp)
    8000347e:	6942                	ld	s2,16(sp)
    80003480:	69a2                	ld	s3,8(sp)
    80003482:	6a02                	ld	s4,0(sp)
    80003484:	6145                	addi	sp,sp,48
    80003486:	8082                	ret
    panic("iget: no inodes");
    80003488:	00005517          	auipc	a0,0x5
    8000348c:	1e050513          	addi	a0,a0,480 # 80008668 <syscalls+0x138>
    80003490:	ffffd097          	auipc	ra,0xffffd
    80003494:	09a080e7          	jalr	154(ra) # 8000052a <panic>

0000000080003498 <fsinit>:
fsinit(int dev) {
    80003498:	7179                	addi	sp,sp,-48
    8000349a:	f406                	sd	ra,40(sp)
    8000349c:	f022                	sd	s0,32(sp)
    8000349e:	ec26                	sd	s1,24(sp)
    800034a0:	e84a                	sd	s2,16(sp)
    800034a2:	e44e                	sd	s3,8(sp)
    800034a4:	1800                	addi	s0,sp,48
    800034a6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034a8:	4585                	li	a1,1
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	a62080e7          	jalr	-1438(ra) # 80002f0c <bread>
    800034b2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034b4:	0001c997          	auipc	s3,0x1c
    800034b8:	2f498993          	addi	s3,s3,756 # 8001f7a8 <sb>
    800034bc:	02000613          	li	a2,32
    800034c0:	05850593          	addi	a1,a0,88
    800034c4:	854e                	mv	a0,s3
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	854080e7          	jalr	-1964(ra) # 80000d1a <memmove>
  brelse(bp);
    800034ce:	8526                	mv	a0,s1
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	b6c080e7          	jalr	-1172(ra) # 8000303c <brelse>
  if(sb.magic != FSMAGIC)
    800034d8:	0009a703          	lw	a4,0(s3)
    800034dc:	102037b7          	lui	a5,0x10203
    800034e0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034e4:	02f71263          	bne	a4,a5,80003508 <fsinit+0x70>
  initlog(dev, &sb);
    800034e8:	0001c597          	auipc	a1,0x1c
    800034ec:	2c058593          	addi	a1,a1,704 # 8001f7a8 <sb>
    800034f0:	854a                	mv	a0,s2
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	b4e080e7          	jalr	-1202(ra) # 80004040 <initlog>
}
    800034fa:	70a2                	ld	ra,40(sp)
    800034fc:	7402                	ld	s0,32(sp)
    800034fe:	64e2                	ld	s1,24(sp)
    80003500:	6942                	ld	s2,16(sp)
    80003502:	69a2                	ld	s3,8(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret
    panic("invalid file system");
    80003508:	00005517          	auipc	a0,0x5
    8000350c:	17050513          	addi	a0,a0,368 # 80008678 <syscalls+0x148>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	01a080e7          	jalr	26(ra) # 8000052a <panic>

0000000080003518 <iinit>:
{
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003526:	00005597          	auipc	a1,0x5
    8000352a:	16a58593          	addi	a1,a1,362 # 80008690 <syscalls+0x160>
    8000352e:	0001c517          	auipc	a0,0x1c
    80003532:	29a50513          	addi	a0,a0,666 # 8001f7c8 <itable>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	5fc080e7          	jalr	1532(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000353e:	0001c497          	auipc	s1,0x1c
    80003542:	2b248493          	addi	s1,s1,690 # 8001f7f0 <itable+0x28>
    80003546:	0001e997          	auipc	s3,0x1e
    8000354a:	d3a98993          	addi	s3,s3,-710 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000354e:	00005917          	auipc	s2,0x5
    80003552:	14a90913          	addi	s2,s2,330 # 80008698 <syscalls+0x168>
    80003556:	85ca                	mv	a1,s2
    80003558:	8526                	mv	a0,s1
    8000355a:	00001097          	auipc	ra,0x1
    8000355e:	e4a080e7          	jalr	-438(ra) # 800043a4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003562:	08848493          	addi	s1,s1,136
    80003566:	ff3498e3          	bne	s1,s3,80003556 <iinit+0x3e>
}
    8000356a:	70a2                	ld	ra,40(sp)
    8000356c:	7402                	ld	s0,32(sp)
    8000356e:	64e2                	ld	s1,24(sp)
    80003570:	6942                	ld	s2,16(sp)
    80003572:	69a2                	ld	s3,8(sp)
    80003574:	6145                	addi	sp,sp,48
    80003576:	8082                	ret

0000000080003578 <ialloc>:
{
    80003578:	715d                	addi	sp,sp,-80
    8000357a:	e486                	sd	ra,72(sp)
    8000357c:	e0a2                	sd	s0,64(sp)
    8000357e:	fc26                	sd	s1,56(sp)
    80003580:	f84a                	sd	s2,48(sp)
    80003582:	f44e                	sd	s3,40(sp)
    80003584:	f052                	sd	s4,32(sp)
    80003586:	ec56                	sd	s5,24(sp)
    80003588:	e85a                	sd	s6,16(sp)
    8000358a:	e45e                	sd	s7,8(sp)
    8000358c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000358e:	0001c717          	auipc	a4,0x1c
    80003592:	22672703          	lw	a4,550(a4) # 8001f7b4 <sb+0xc>
    80003596:	4785                	li	a5,1
    80003598:	04e7fa63          	bgeu	a5,a4,800035ec <ialloc+0x74>
    8000359c:	8aaa                	mv	s5,a0
    8000359e:	8bae                	mv	s7,a1
    800035a0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035a2:	0001ca17          	auipc	s4,0x1c
    800035a6:	206a0a13          	addi	s4,s4,518 # 8001f7a8 <sb>
    800035aa:	00048b1b          	sext.w	s6,s1
    800035ae:	0044d793          	srli	a5,s1,0x4
    800035b2:	018a2583          	lw	a1,24(s4)
    800035b6:	9dbd                	addw	a1,a1,a5
    800035b8:	8556                	mv	a0,s5
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	952080e7          	jalr	-1710(ra) # 80002f0c <bread>
    800035c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035c4:	05850993          	addi	s3,a0,88
    800035c8:	00f4f793          	andi	a5,s1,15
    800035cc:	079a                	slli	a5,a5,0x6
    800035ce:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035d0:	00099783          	lh	a5,0(s3)
    800035d4:	c785                	beqz	a5,800035fc <ialloc+0x84>
    brelse(bp);
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	a66080e7          	jalr	-1434(ra) # 8000303c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035de:	0485                	addi	s1,s1,1
    800035e0:	00ca2703          	lw	a4,12(s4)
    800035e4:	0004879b          	sext.w	a5,s1
    800035e8:	fce7e1e3          	bltu	a5,a4,800035aa <ialloc+0x32>
  panic("ialloc: no inodes");
    800035ec:	00005517          	auipc	a0,0x5
    800035f0:	0b450513          	addi	a0,a0,180 # 800086a0 <syscalls+0x170>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	f36080e7          	jalr	-202(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800035fc:	04000613          	li	a2,64
    80003600:	4581                	li	a1,0
    80003602:	854e                	mv	a0,s3
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	6ba080e7          	jalr	1722(ra) # 80000cbe <memset>
      dip->type = type;
    8000360c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003610:	854a                	mv	a0,s2
    80003612:	00001097          	auipc	ra,0x1
    80003616:	cac080e7          	jalr	-852(ra) # 800042be <log_write>
      brelse(bp);
    8000361a:	854a                	mv	a0,s2
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	a20080e7          	jalr	-1504(ra) # 8000303c <brelse>
      return iget(dev, inum);
    80003624:	85da                	mv	a1,s6
    80003626:	8556                	mv	a0,s5
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	db4080e7          	jalr	-588(ra) # 800033dc <iget>
}
    80003630:	60a6                	ld	ra,72(sp)
    80003632:	6406                	ld	s0,64(sp)
    80003634:	74e2                	ld	s1,56(sp)
    80003636:	7942                	ld	s2,48(sp)
    80003638:	79a2                	ld	s3,40(sp)
    8000363a:	7a02                	ld	s4,32(sp)
    8000363c:	6ae2                	ld	s5,24(sp)
    8000363e:	6b42                	ld	s6,16(sp)
    80003640:	6ba2                	ld	s7,8(sp)
    80003642:	6161                	addi	sp,sp,80
    80003644:	8082                	ret

0000000080003646 <iupdate>:
{
    80003646:	1101                	addi	sp,sp,-32
    80003648:	ec06                	sd	ra,24(sp)
    8000364a:	e822                	sd	s0,16(sp)
    8000364c:	e426                	sd	s1,8(sp)
    8000364e:	e04a                	sd	s2,0(sp)
    80003650:	1000                	addi	s0,sp,32
    80003652:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003654:	415c                	lw	a5,4(a0)
    80003656:	0047d79b          	srliw	a5,a5,0x4
    8000365a:	0001c597          	auipc	a1,0x1c
    8000365e:	1665a583          	lw	a1,358(a1) # 8001f7c0 <sb+0x18>
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	4108                	lw	a0,0(a0)
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	8a6080e7          	jalr	-1882(ra) # 80002f0c <bread>
    8000366e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003670:	05850793          	addi	a5,a0,88
    80003674:	40c8                	lw	a0,4(s1)
    80003676:	893d                	andi	a0,a0,15
    80003678:	051a                	slli	a0,a0,0x6
    8000367a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000367c:	04449703          	lh	a4,68(s1)
    80003680:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003684:	04649703          	lh	a4,70(s1)
    80003688:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000368c:	04849703          	lh	a4,72(s1)
    80003690:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003694:	04a49703          	lh	a4,74(s1)
    80003698:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000369c:	44f8                	lw	a4,76(s1)
    8000369e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036a0:	03400613          	li	a2,52
    800036a4:	05048593          	addi	a1,s1,80
    800036a8:	0531                	addi	a0,a0,12
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	670080e7          	jalr	1648(ra) # 80000d1a <memmove>
  log_write(bp);
    800036b2:	854a                	mv	a0,s2
    800036b4:	00001097          	auipc	ra,0x1
    800036b8:	c0a080e7          	jalr	-1014(ra) # 800042be <log_write>
  brelse(bp);
    800036bc:	854a                	mv	a0,s2
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	97e080e7          	jalr	-1666(ra) # 8000303c <brelse>
}
    800036c6:	60e2                	ld	ra,24(sp)
    800036c8:	6442                	ld	s0,16(sp)
    800036ca:	64a2                	ld	s1,8(sp)
    800036cc:	6902                	ld	s2,0(sp)
    800036ce:	6105                	addi	sp,sp,32
    800036d0:	8082                	ret

00000000800036d2 <idup>:
{
    800036d2:	1101                	addi	sp,sp,-32
    800036d4:	ec06                	sd	ra,24(sp)
    800036d6:	e822                	sd	s0,16(sp)
    800036d8:	e426                	sd	s1,8(sp)
    800036da:	1000                	addi	s0,sp,32
    800036dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036de:	0001c517          	auipc	a0,0x1c
    800036e2:	0ea50513          	addi	a0,a0,234 # 8001f7c8 <itable>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	4dc080e7          	jalr	1244(ra) # 80000bc2 <acquire>
  ip->ref++;
    800036ee:	449c                	lw	a5,8(s1)
    800036f0:	2785                	addiw	a5,a5,1
    800036f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036f4:	0001c517          	auipc	a0,0x1c
    800036f8:	0d450513          	addi	a0,a0,212 # 8001f7c8 <itable>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	57a080e7          	jalr	1402(ra) # 80000c76 <release>
}
    80003704:	8526                	mv	a0,s1
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6105                	addi	sp,sp,32
    8000370e:	8082                	ret

0000000080003710 <ilock>:
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	e04a                	sd	s2,0(sp)
    8000371a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000371c:	c115                	beqz	a0,80003740 <ilock+0x30>
    8000371e:	84aa                	mv	s1,a0
    80003720:	451c                	lw	a5,8(a0)
    80003722:	00f05f63          	blez	a5,80003740 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003726:	0541                	addi	a0,a0,16
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	cb6080e7          	jalr	-842(ra) # 800043de <acquiresleep>
  if(ip->valid == 0){
    80003730:	40bc                	lw	a5,64(s1)
    80003732:	cf99                	beqz	a5,80003750 <ilock+0x40>
}
    80003734:	60e2                	ld	ra,24(sp)
    80003736:	6442                	ld	s0,16(sp)
    80003738:	64a2                	ld	s1,8(sp)
    8000373a:	6902                	ld	s2,0(sp)
    8000373c:	6105                	addi	sp,sp,32
    8000373e:	8082                	ret
    panic("ilock");
    80003740:	00005517          	auipc	a0,0x5
    80003744:	f7850513          	addi	a0,a0,-136 # 800086b8 <syscalls+0x188>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	de2080e7          	jalr	-542(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003750:	40dc                	lw	a5,4(s1)
    80003752:	0047d79b          	srliw	a5,a5,0x4
    80003756:	0001c597          	auipc	a1,0x1c
    8000375a:	06a5a583          	lw	a1,106(a1) # 8001f7c0 <sb+0x18>
    8000375e:	9dbd                	addw	a1,a1,a5
    80003760:	4088                	lw	a0,0(s1)
    80003762:	fffff097          	auipc	ra,0xfffff
    80003766:	7aa080e7          	jalr	1962(ra) # 80002f0c <bread>
    8000376a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000376c:	05850593          	addi	a1,a0,88
    80003770:	40dc                	lw	a5,4(s1)
    80003772:	8bbd                	andi	a5,a5,15
    80003774:	079a                	slli	a5,a5,0x6
    80003776:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003778:	00059783          	lh	a5,0(a1)
    8000377c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003780:	00259783          	lh	a5,2(a1)
    80003784:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003788:	00459783          	lh	a5,4(a1)
    8000378c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003790:	00659783          	lh	a5,6(a1)
    80003794:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003798:	459c                	lw	a5,8(a1)
    8000379a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000379c:	03400613          	li	a2,52
    800037a0:	05b1                	addi	a1,a1,12
    800037a2:	05048513          	addi	a0,s1,80
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	574080e7          	jalr	1396(ra) # 80000d1a <memmove>
    brelse(bp);
    800037ae:	854a                	mv	a0,s2
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	88c080e7          	jalr	-1908(ra) # 8000303c <brelse>
    ip->valid = 1;
    800037b8:	4785                	li	a5,1
    800037ba:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037bc:	04449783          	lh	a5,68(s1)
    800037c0:	fbb5                	bnez	a5,80003734 <ilock+0x24>
      panic("ilock: no type");
    800037c2:	00005517          	auipc	a0,0x5
    800037c6:	efe50513          	addi	a0,a0,-258 # 800086c0 <syscalls+0x190>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	d60080e7          	jalr	-672(ra) # 8000052a <panic>

00000000800037d2 <iunlock>:
{
    800037d2:	1101                	addi	sp,sp,-32
    800037d4:	ec06                	sd	ra,24(sp)
    800037d6:	e822                	sd	s0,16(sp)
    800037d8:	e426                	sd	s1,8(sp)
    800037da:	e04a                	sd	s2,0(sp)
    800037dc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037de:	c905                	beqz	a0,8000380e <iunlock+0x3c>
    800037e0:	84aa                	mv	s1,a0
    800037e2:	01050913          	addi	s2,a0,16
    800037e6:	854a                	mv	a0,s2
    800037e8:	00001097          	auipc	ra,0x1
    800037ec:	c90080e7          	jalr	-880(ra) # 80004478 <holdingsleep>
    800037f0:	cd19                	beqz	a0,8000380e <iunlock+0x3c>
    800037f2:	449c                	lw	a5,8(s1)
    800037f4:	00f05d63          	blez	a5,8000380e <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037f8:	854a                	mv	a0,s2
    800037fa:	00001097          	auipc	ra,0x1
    800037fe:	c3a080e7          	jalr	-966(ra) # 80004434 <releasesleep>
}
    80003802:	60e2                	ld	ra,24(sp)
    80003804:	6442                	ld	s0,16(sp)
    80003806:	64a2                	ld	s1,8(sp)
    80003808:	6902                	ld	s2,0(sp)
    8000380a:	6105                	addi	sp,sp,32
    8000380c:	8082                	ret
    panic("iunlock");
    8000380e:	00005517          	auipc	a0,0x5
    80003812:	ec250513          	addi	a0,a0,-318 # 800086d0 <syscalls+0x1a0>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	d14080e7          	jalr	-748(ra) # 8000052a <panic>

000000008000381e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000381e:	7179                	addi	sp,sp,-48
    80003820:	f406                	sd	ra,40(sp)
    80003822:	f022                	sd	s0,32(sp)
    80003824:	ec26                	sd	s1,24(sp)
    80003826:	e84a                	sd	s2,16(sp)
    80003828:	e44e                	sd	s3,8(sp)
    8000382a:	e052                	sd	s4,0(sp)
    8000382c:	1800                	addi	s0,sp,48
    8000382e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003830:	05050493          	addi	s1,a0,80
    80003834:	08050913          	addi	s2,a0,128
    80003838:	a021                	j	80003840 <itrunc+0x22>
    8000383a:	0491                	addi	s1,s1,4
    8000383c:	01248d63          	beq	s1,s2,80003856 <itrunc+0x38>
    if(ip->addrs[i]){
    80003840:	408c                	lw	a1,0(s1)
    80003842:	dde5                	beqz	a1,8000383a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003844:	0009a503          	lw	a0,0(s3)
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	90a080e7          	jalr	-1782(ra) # 80003152 <bfree>
      ip->addrs[i] = 0;
    80003850:	0004a023          	sw	zero,0(s1)
    80003854:	b7dd                	j	8000383a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003856:	0809a583          	lw	a1,128(s3)
    8000385a:	e185                	bnez	a1,8000387a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000385c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003860:	854e                	mv	a0,s3
    80003862:	00000097          	auipc	ra,0x0
    80003866:	de4080e7          	jalr	-540(ra) # 80003646 <iupdate>
}
    8000386a:	70a2                	ld	ra,40(sp)
    8000386c:	7402                	ld	s0,32(sp)
    8000386e:	64e2                	ld	s1,24(sp)
    80003870:	6942                	ld	s2,16(sp)
    80003872:	69a2                	ld	s3,8(sp)
    80003874:	6a02                	ld	s4,0(sp)
    80003876:	6145                	addi	sp,sp,48
    80003878:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000387a:	0009a503          	lw	a0,0(s3)
    8000387e:	fffff097          	auipc	ra,0xfffff
    80003882:	68e080e7          	jalr	1678(ra) # 80002f0c <bread>
    80003886:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003888:	05850493          	addi	s1,a0,88
    8000388c:	45850913          	addi	s2,a0,1112
    80003890:	a021                	j	80003898 <itrunc+0x7a>
    80003892:	0491                	addi	s1,s1,4
    80003894:	01248b63          	beq	s1,s2,800038aa <itrunc+0x8c>
      if(a[j])
    80003898:	408c                	lw	a1,0(s1)
    8000389a:	dde5                	beqz	a1,80003892 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000389c:	0009a503          	lw	a0,0(s3)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	8b2080e7          	jalr	-1870(ra) # 80003152 <bfree>
    800038a8:	b7ed                	j	80003892 <itrunc+0x74>
    brelse(bp);
    800038aa:	8552                	mv	a0,s4
    800038ac:	fffff097          	auipc	ra,0xfffff
    800038b0:	790080e7          	jalr	1936(ra) # 8000303c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038b4:	0809a583          	lw	a1,128(s3)
    800038b8:	0009a503          	lw	a0,0(s3)
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	896080e7          	jalr	-1898(ra) # 80003152 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038c4:	0809a023          	sw	zero,128(s3)
    800038c8:	bf51                	j	8000385c <itrunc+0x3e>

00000000800038ca <iput>:
{
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	e04a                	sd	s2,0(sp)
    800038d4:	1000                	addi	s0,sp,32
    800038d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038d8:	0001c517          	auipc	a0,0x1c
    800038dc:	ef050513          	addi	a0,a0,-272 # 8001f7c8 <itable>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	2e2080e7          	jalr	738(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e8:	4498                	lw	a4,8(s1)
    800038ea:	4785                	li	a5,1
    800038ec:	02f70363          	beq	a4,a5,80003912 <iput+0x48>
  ip->ref--;
    800038f0:	449c                	lw	a5,8(s1)
    800038f2:	37fd                	addiw	a5,a5,-1
    800038f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f6:	0001c517          	auipc	a0,0x1c
    800038fa:	ed250513          	addi	a0,a0,-302 # 8001f7c8 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	378080e7          	jalr	888(ra) # 80000c76 <release>
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6902                	ld	s2,0(sp)
    8000390e:	6105                	addi	sp,sp,32
    80003910:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003912:	40bc                	lw	a5,64(s1)
    80003914:	dff1                	beqz	a5,800038f0 <iput+0x26>
    80003916:	04a49783          	lh	a5,74(s1)
    8000391a:	fbf9                	bnez	a5,800038f0 <iput+0x26>
    acquiresleep(&ip->lock);
    8000391c:	01048913          	addi	s2,s1,16
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	abc080e7          	jalr	-1348(ra) # 800043de <acquiresleep>
    release(&itable.lock);
    8000392a:	0001c517          	auipc	a0,0x1c
    8000392e:	e9e50513          	addi	a0,a0,-354 # 8001f7c8 <itable>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	344080e7          	jalr	836(ra) # 80000c76 <release>
    itrunc(ip);
    8000393a:	8526                	mv	a0,s1
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	ee2080e7          	jalr	-286(ra) # 8000381e <itrunc>
    ip->type = 0;
    80003944:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003948:	8526                	mv	a0,s1
    8000394a:	00000097          	auipc	ra,0x0
    8000394e:	cfc080e7          	jalr	-772(ra) # 80003646 <iupdate>
    ip->valid = 0;
    80003952:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003956:	854a                	mv	a0,s2
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	adc080e7          	jalr	-1316(ra) # 80004434 <releasesleep>
    acquire(&itable.lock);
    80003960:	0001c517          	auipc	a0,0x1c
    80003964:	e6850513          	addi	a0,a0,-408 # 8001f7c8 <itable>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	25a080e7          	jalr	602(ra) # 80000bc2 <acquire>
    80003970:	b741                	j	800038f0 <iput+0x26>

0000000080003972 <iunlockput>:
{
    80003972:	1101                	addi	sp,sp,-32
    80003974:	ec06                	sd	ra,24(sp)
    80003976:	e822                	sd	s0,16(sp)
    80003978:	e426                	sd	s1,8(sp)
    8000397a:	1000                	addi	s0,sp,32
    8000397c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	e54080e7          	jalr	-428(ra) # 800037d2 <iunlock>
  iput(ip);
    80003986:	8526                	mv	a0,s1
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	f42080e7          	jalr	-190(ra) # 800038ca <iput>
}
    80003990:	60e2                	ld	ra,24(sp)
    80003992:	6442                	ld	s0,16(sp)
    80003994:	64a2                	ld	s1,8(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret

000000008000399a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000399a:	1141                	addi	sp,sp,-16
    8000399c:	e422                	sd	s0,8(sp)
    8000399e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039a0:	411c                	lw	a5,0(a0)
    800039a2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039a4:	415c                	lw	a5,4(a0)
    800039a6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039a8:	04451783          	lh	a5,68(a0)
    800039ac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039b0:	04a51783          	lh	a5,74(a0)
    800039b4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039b8:	04c56783          	lwu	a5,76(a0)
    800039bc:	e99c                	sd	a5,16(a1)
}
    800039be:	6422                	ld	s0,8(sp)
    800039c0:	0141                	addi	sp,sp,16
    800039c2:	8082                	ret

00000000800039c4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039c4:	457c                	lw	a5,76(a0)
    800039c6:	0ed7e963          	bltu	a5,a3,80003ab8 <readi+0xf4>
{
    800039ca:	7159                	addi	sp,sp,-112
    800039cc:	f486                	sd	ra,104(sp)
    800039ce:	f0a2                	sd	s0,96(sp)
    800039d0:	eca6                	sd	s1,88(sp)
    800039d2:	e8ca                	sd	s2,80(sp)
    800039d4:	e4ce                	sd	s3,72(sp)
    800039d6:	e0d2                	sd	s4,64(sp)
    800039d8:	fc56                	sd	s5,56(sp)
    800039da:	f85a                	sd	s6,48(sp)
    800039dc:	f45e                	sd	s7,40(sp)
    800039de:	f062                	sd	s8,32(sp)
    800039e0:	ec66                	sd	s9,24(sp)
    800039e2:	e86a                	sd	s10,16(sp)
    800039e4:	e46e                	sd	s11,8(sp)
    800039e6:	1880                	addi	s0,sp,112
    800039e8:	8baa                	mv	s7,a0
    800039ea:	8c2e                	mv	s8,a1
    800039ec:	8ab2                	mv	s5,a2
    800039ee:	84b6                	mv	s1,a3
    800039f0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039f2:	9f35                	addw	a4,a4,a3
    return 0;
    800039f4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039f6:	0ad76063          	bltu	a4,a3,80003a96 <readi+0xd2>
  if(off + n > ip->size)
    800039fa:	00e7f463          	bgeu	a5,a4,80003a02 <readi+0x3e>
    n = ip->size - off;
    800039fe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a02:	0a0b0963          	beqz	s6,80003ab4 <readi+0xf0>
    80003a06:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a08:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a0c:	5cfd                	li	s9,-1
    80003a0e:	a82d                	j	80003a48 <readi+0x84>
    80003a10:	020a1d93          	slli	s11,s4,0x20
    80003a14:	020ddd93          	srli	s11,s11,0x20
    80003a18:	05890793          	addi	a5,s2,88
    80003a1c:	86ee                	mv	a3,s11
    80003a1e:	963e                	add	a2,a2,a5
    80003a20:	85d6                	mv	a1,s5
    80003a22:	8562                	mv	a0,s8
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	a28080e7          	jalr	-1496(ra) # 8000244c <either_copyout>
    80003a2c:	05950d63          	beq	a0,s9,80003a86 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a30:	854a                	mv	a0,s2
    80003a32:	fffff097          	auipc	ra,0xfffff
    80003a36:	60a080e7          	jalr	1546(ra) # 8000303c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3a:	013a09bb          	addw	s3,s4,s3
    80003a3e:	009a04bb          	addw	s1,s4,s1
    80003a42:	9aee                	add	s5,s5,s11
    80003a44:	0569f763          	bgeu	s3,s6,80003a92 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a48:	000ba903          	lw	s2,0(s7)
    80003a4c:	00a4d59b          	srliw	a1,s1,0xa
    80003a50:	855e                	mv	a0,s7
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	8ae080e7          	jalr	-1874(ra) # 80003300 <bmap>
    80003a5a:	0005059b          	sext.w	a1,a0
    80003a5e:	854a                	mv	a0,s2
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	4ac080e7          	jalr	1196(ra) # 80002f0c <bread>
    80003a68:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6a:	3ff4f613          	andi	a2,s1,1023
    80003a6e:	40cd07bb          	subw	a5,s10,a2
    80003a72:	413b073b          	subw	a4,s6,s3
    80003a76:	8a3e                	mv	s4,a5
    80003a78:	2781                	sext.w	a5,a5
    80003a7a:	0007069b          	sext.w	a3,a4
    80003a7e:	f8f6f9e3          	bgeu	a3,a5,80003a10 <readi+0x4c>
    80003a82:	8a3a                	mv	s4,a4
    80003a84:	b771                	j	80003a10 <readi+0x4c>
      brelse(bp);
    80003a86:	854a                	mv	a0,s2
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	5b4080e7          	jalr	1460(ra) # 8000303c <brelse>
      tot = -1;
    80003a90:	59fd                	li	s3,-1
  }
  return tot;
    80003a92:	0009851b          	sext.w	a0,s3
}
    80003a96:	70a6                	ld	ra,104(sp)
    80003a98:	7406                	ld	s0,96(sp)
    80003a9a:	64e6                	ld	s1,88(sp)
    80003a9c:	6946                	ld	s2,80(sp)
    80003a9e:	69a6                	ld	s3,72(sp)
    80003aa0:	6a06                	ld	s4,64(sp)
    80003aa2:	7ae2                	ld	s5,56(sp)
    80003aa4:	7b42                	ld	s6,48(sp)
    80003aa6:	7ba2                	ld	s7,40(sp)
    80003aa8:	7c02                	ld	s8,32(sp)
    80003aaa:	6ce2                	ld	s9,24(sp)
    80003aac:	6d42                	ld	s10,16(sp)
    80003aae:	6da2                	ld	s11,8(sp)
    80003ab0:	6165                	addi	sp,sp,112
    80003ab2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab4:	89da                	mv	s3,s6
    80003ab6:	bff1                	j	80003a92 <readi+0xce>
    return 0;
    80003ab8:	4501                	li	a0,0
}
    80003aba:	8082                	ret

0000000080003abc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003abc:	457c                	lw	a5,76(a0)
    80003abe:	10d7e863          	bltu	a5,a3,80003bce <writei+0x112>
{
    80003ac2:	7159                	addi	sp,sp,-112
    80003ac4:	f486                	sd	ra,104(sp)
    80003ac6:	f0a2                	sd	s0,96(sp)
    80003ac8:	eca6                	sd	s1,88(sp)
    80003aca:	e8ca                	sd	s2,80(sp)
    80003acc:	e4ce                	sd	s3,72(sp)
    80003ace:	e0d2                	sd	s4,64(sp)
    80003ad0:	fc56                	sd	s5,56(sp)
    80003ad2:	f85a                	sd	s6,48(sp)
    80003ad4:	f45e                	sd	s7,40(sp)
    80003ad6:	f062                	sd	s8,32(sp)
    80003ad8:	ec66                	sd	s9,24(sp)
    80003ada:	e86a                	sd	s10,16(sp)
    80003adc:	e46e                	sd	s11,8(sp)
    80003ade:	1880                	addi	s0,sp,112
    80003ae0:	8b2a                	mv	s6,a0
    80003ae2:	8c2e                	mv	s8,a1
    80003ae4:	8ab2                	mv	s5,a2
    80003ae6:	8936                	mv	s2,a3
    80003ae8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003aea:	00e687bb          	addw	a5,a3,a4
    80003aee:	0ed7e263          	bltu	a5,a3,80003bd2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003af2:	00043737          	lui	a4,0x43
    80003af6:	0ef76063          	bltu	a4,a5,80003bd6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003afa:	0c0b8863          	beqz	s7,80003bca <writei+0x10e>
    80003afe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b00:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b04:	5cfd                	li	s9,-1
    80003b06:	a091                	j	80003b4a <writei+0x8e>
    80003b08:	02099d93          	slli	s11,s3,0x20
    80003b0c:	020ddd93          	srli	s11,s11,0x20
    80003b10:	05848793          	addi	a5,s1,88
    80003b14:	86ee                	mv	a3,s11
    80003b16:	8656                	mv	a2,s5
    80003b18:	85e2                	mv	a1,s8
    80003b1a:	953e                	add	a0,a0,a5
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	986080e7          	jalr	-1658(ra) # 800024a2 <either_copyin>
    80003b24:	07950263          	beq	a0,s9,80003b88 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b28:	8526                	mv	a0,s1
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	794080e7          	jalr	1940(ra) # 800042be <log_write>
    brelse(bp);
    80003b32:	8526                	mv	a0,s1
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	508080e7          	jalr	1288(ra) # 8000303c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b3c:	01498a3b          	addw	s4,s3,s4
    80003b40:	0129893b          	addw	s2,s3,s2
    80003b44:	9aee                	add	s5,s5,s11
    80003b46:	057a7663          	bgeu	s4,s7,80003b92 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b4a:	000b2483          	lw	s1,0(s6)
    80003b4e:	00a9559b          	srliw	a1,s2,0xa
    80003b52:	855a                	mv	a0,s6
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	7ac080e7          	jalr	1964(ra) # 80003300 <bmap>
    80003b5c:	0005059b          	sext.w	a1,a0
    80003b60:	8526                	mv	a0,s1
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	3aa080e7          	jalr	938(ra) # 80002f0c <bread>
    80003b6a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6c:	3ff97513          	andi	a0,s2,1023
    80003b70:	40ad07bb          	subw	a5,s10,a0
    80003b74:	414b873b          	subw	a4,s7,s4
    80003b78:	89be                	mv	s3,a5
    80003b7a:	2781                	sext.w	a5,a5
    80003b7c:	0007069b          	sext.w	a3,a4
    80003b80:	f8f6f4e3          	bgeu	a3,a5,80003b08 <writei+0x4c>
    80003b84:	89ba                	mv	s3,a4
    80003b86:	b749                	j	80003b08 <writei+0x4c>
      brelse(bp);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	4b2080e7          	jalr	1202(ra) # 8000303c <brelse>
  }

  if(off > ip->size)
    80003b92:	04cb2783          	lw	a5,76(s6)
    80003b96:	0127f463          	bgeu	a5,s2,80003b9e <writei+0xe2>
    ip->size = off;
    80003b9a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b9e:	855a                	mv	a0,s6
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	aa6080e7          	jalr	-1370(ra) # 80003646 <iupdate>

  return tot;
    80003ba8:	000a051b          	sext.w	a0,s4
}
    80003bac:	70a6                	ld	ra,104(sp)
    80003bae:	7406                	ld	s0,96(sp)
    80003bb0:	64e6                	ld	s1,88(sp)
    80003bb2:	6946                	ld	s2,80(sp)
    80003bb4:	69a6                	ld	s3,72(sp)
    80003bb6:	6a06                	ld	s4,64(sp)
    80003bb8:	7ae2                	ld	s5,56(sp)
    80003bba:	7b42                	ld	s6,48(sp)
    80003bbc:	7ba2                	ld	s7,40(sp)
    80003bbe:	7c02                	ld	s8,32(sp)
    80003bc0:	6ce2                	ld	s9,24(sp)
    80003bc2:	6d42                	ld	s10,16(sp)
    80003bc4:	6da2                	ld	s11,8(sp)
    80003bc6:	6165                	addi	sp,sp,112
    80003bc8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bca:	8a5e                	mv	s4,s7
    80003bcc:	bfc9                	j	80003b9e <writei+0xe2>
    return -1;
    80003bce:	557d                	li	a0,-1
}
    80003bd0:	8082                	ret
    return -1;
    80003bd2:	557d                	li	a0,-1
    80003bd4:	bfe1                	j	80003bac <writei+0xf0>
    return -1;
    80003bd6:	557d                	li	a0,-1
    80003bd8:	bfd1                	j	80003bac <writei+0xf0>

0000000080003bda <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bda:	1141                	addi	sp,sp,-16
    80003bdc:	e406                	sd	ra,8(sp)
    80003bde:	e022                	sd	s0,0(sp)
    80003be0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003be2:	4639                	li	a2,14
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	1b2080e7          	jalr	434(ra) # 80000d96 <strncmp>
}
    80003bec:	60a2                	ld	ra,8(sp)
    80003bee:	6402                	ld	s0,0(sp)
    80003bf0:	0141                	addi	sp,sp,16
    80003bf2:	8082                	ret

0000000080003bf4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bf4:	7139                	addi	sp,sp,-64
    80003bf6:	fc06                	sd	ra,56(sp)
    80003bf8:	f822                	sd	s0,48(sp)
    80003bfa:	f426                	sd	s1,40(sp)
    80003bfc:	f04a                	sd	s2,32(sp)
    80003bfe:	ec4e                	sd	s3,24(sp)
    80003c00:	e852                	sd	s4,16(sp)
    80003c02:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c04:	04451703          	lh	a4,68(a0)
    80003c08:	4785                	li	a5,1
    80003c0a:	00f71a63          	bne	a4,a5,80003c1e <dirlookup+0x2a>
    80003c0e:	892a                	mv	s2,a0
    80003c10:	89ae                	mv	s3,a1
    80003c12:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c14:	457c                	lw	a5,76(a0)
    80003c16:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c18:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c1a:	e79d                	bnez	a5,80003c48 <dirlookup+0x54>
    80003c1c:	a8a5                	j	80003c94 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c1e:	00005517          	auipc	a0,0x5
    80003c22:	aba50513          	addi	a0,a0,-1350 # 800086d8 <syscalls+0x1a8>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	904080e7          	jalr	-1788(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003c2e:	00005517          	auipc	a0,0x5
    80003c32:	ac250513          	addi	a0,a0,-1342 # 800086f0 <syscalls+0x1c0>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	8f4080e7          	jalr	-1804(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3e:	24c1                	addiw	s1,s1,16
    80003c40:	04c92783          	lw	a5,76(s2)
    80003c44:	04f4f763          	bgeu	s1,a5,80003c92 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c48:	4741                	li	a4,16
    80003c4a:	86a6                	mv	a3,s1
    80003c4c:	fc040613          	addi	a2,s0,-64
    80003c50:	4581                	li	a1,0
    80003c52:	854a                	mv	a0,s2
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	d70080e7          	jalr	-656(ra) # 800039c4 <readi>
    80003c5c:	47c1                	li	a5,16
    80003c5e:	fcf518e3          	bne	a0,a5,80003c2e <dirlookup+0x3a>
    if(de.inum == 0)
    80003c62:	fc045783          	lhu	a5,-64(s0)
    80003c66:	dfe1                	beqz	a5,80003c3e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c68:	fc240593          	addi	a1,s0,-62
    80003c6c:	854e                	mv	a0,s3
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	f6c080e7          	jalr	-148(ra) # 80003bda <namecmp>
    80003c76:	f561                	bnez	a0,80003c3e <dirlookup+0x4a>
      if(poff)
    80003c78:	000a0463          	beqz	s4,80003c80 <dirlookup+0x8c>
        *poff = off;
    80003c7c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c80:	fc045583          	lhu	a1,-64(s0)
    80003c84:	00092503          	lw	a0,0(s2)
    80003c88:	fffff097          	auipc	ra,0xfffff
    80003c8c:	754080e7          	jalr	1876(ra) # 800033dc <iget>
    80003c90:	a011                	j	80003c94 <dirlookup+0xa0>
  return 0;
    80003c92:	4501                	li	a0,0
}
    80003c94:	70e2                	ld	ra,56(sp)
    80003c96:	7442                	ld	s0,48(sp)
    80003c98:	74a2                	ld	s1,40(sp)
    80003c9a:	7902                	ld	s2,32(sp)
    80003c9c:	69e2                	ld	s3,24(sp)
    80003c9e:	6a42                	ld	s4,16(sp)
    80003ca0:	6121                	addi	sp,sp,64
    80003ca2:	8082                	ret

0000000080003ca4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ca4:	711d                	addi	sp,sp,-96
    80003ca6:	ec86                	sd	ra,88(sp)
    80003ca8:	e8a2                	sd	s0,80(sp)
    80003caa:	e4a6                	sd	s1,72(sp)
    80003cac:	e0ca                	sd	s2,64(sp)
    80003cae:	fc4e                	sd	s3,56(sp)
    80003cb0:	f852                	sd	s4,48(sp)
    80003cb2:	f456                	sd	s5,40(sp)
    80003cb4:	f05a                	sd	s6,32(sp)
    80003cb6:	ec5e                	sd	s7,24(sp)
    80003cb8:	e862                	sd	s8,16(sp)
    80003cba:	e466                	sd	s9,8(sp)
    80003cbc:	1080                	addi	s0,sp,96
    80003cbe:	84aa                	mv	s1,a0
    80003cc0:	8aae                	mv	s5,a1
    80003cc2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cc4:	00054703          	lbu	a4,0(a0)
    80003cc8:	02f00793          	li	a5,47
    80003ccc:	02f70363          	beq	a4,a5,80003cf2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cd0:	ffffe097          	auipc	ra,0xffffe
    80003cd4:	cae080e7          	jalr	-850(ra) # 8000197e <myproc>
    80003cd8:	15053503          	ld	a0,336(a0)
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	9f6080e7          	jalr	-1546(ra) # 800036d2 <idup>
    80003ce4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ce6:	02f00913          	li	s2,47
  len = path - s;
    80003cea:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003cec:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cee:	4b85                	li	s7,1
    80003cf0:	a865                	j	80003da8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cf2:	4585                	li	a1,1
    80003cf4:	4505                	li	a0,1
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	6e6080e7          	jalr	1766(ra) # 800033dc <iget>
    80003cfe:	89aa                	mv	s3,a0
    80003d00:	b7dd                	j	80003ce6 <namex+0x42>
      iunlockput(ip);
    80003d02:	854e                	mv	a0,s3
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	c6e080e7          	jalr	-914(ra) # 80003972 <iunlockput>
      return 0;
    80003d0c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d0e:	854e                	mv	a0,s3
    80003d10:	60e6                	ld	ra,88(sp)
    80003d12:	6446                	ld	s0,80(sp)
    80003d14:	64a6                	ld	s1,72(sp)
    80003d16:	6906                	ld	s2,64(sp)
    80003d18:	79e2                	ld	s3,56(sp)
    80003d1a:	7a42                	ld	s4,48(sp)
    80003d1c:	7aa2                	ld	s5,40(sp)
    80003d1e:	7b02                	ld	s6,32(sp)
    80003d20:	6be2                	ld	s7,24(sp)
    80003d22:	6c42                	ld	s8,16(sp)
    80003d24:	6ca2                	ld	s9,8(sp)
    80003d26:	6125                	addi	sp,sp,96
    80003d28:	8082                	ret
      iunlock(ip);
    80003d2a:	854e                	mv	a0,s3
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	aa6080e7          	jalr	-1370(ra) # 800037d2 <iunlock>
      return ip;
    80003d34:	bfe9                	j	80003d0e <namex+0x6a>
      iunlockput(ip);
    80003d36:	854e                	mv	a0,s3
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	c3a080e7          	jalr	-966(ra) # 80003972 <iunlockput>
      return 0;
    80003d40:	89e6                	mv	s3,s9
    80003d42:	b7f1                	j	80003d0e <namex+0x6a>
  len = path - s;
    80003d44:	40b48633          	sub	a2,s1,a1
    80003d48:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d4c:	099c5463          	bge	s8,s9,80003dd4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d50:	4639                	li	a2,14
    80003d52:	8552                	mv	a0,s4
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	fc6080e7          	jalr	-58(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003d5c:	0004c783          	lbu	a5,0(s1)
    80003d60:	01279763          	bne	a5,s2,80003d6e <namex+0xca>
    path++;
    80003d64:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d66:	0004c783          	lbu	a5,0(s1)
    80003d6a:	ff278de3          	beq	a5,s2,80003d64 <namex+0xc0>
    ilock(ip);
    80003d6e:	854e                	mv	a0,s3
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	9a0080e7          	jalr	-1632(ra) # 80003710 <ilock>
    if(ip->type != T_DIR){
    80003d78:	04499783          	lh	a5,68(s3)
    80003d7c:	f97793e3          	bne	a5,s7,80003d02 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d80:	000a8563          	beqz	s5,80003d8a <namex+0xe6>
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	d3cd                	beqz	a5,80003d2a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d8a:	865a                	mv	a2,s6
    80003d8c:	85d2                	mv	a1,s4
    80003d8e:	854e                	mv	a0,s3
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	e64080e7          	jalr	-412(ra) # 80003bf4 <dirlookup>
    80003d98:	8caa                	mv	s9,a0
    80003d9a:	dd51                	beqz	a0,80003d36 <namex+0x92>
    iunlockput(ip);
    80003d9c:	854e                	mv	a0,s3
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	bd4080e7          	jalr	-1068(ra) # 80003972 <iunlockput>
    ip = next;
    80003da6:	89e6                	mv	s3,s9
  while(*path == '/')
    80003da8:	0004c783          	lbu	a5,0(s1)
    80003dac:	05279763          	bne	a5,s2,80003dfa <namex+0x156>
    path++;
    80003db0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003db2:	0004c783          	lbu	a5,0(s1)
    80003db6:	ff278de3          	beq	a5,s2,80003db0 <namex+0x10c>
  if(*path == 0)
    80003dba:	c79d                	beqz	a5,80003de8 <namex+0x144>
    path++;
    80003dbc:	85a6                	mv	a1,s1
  len = path - s;
    80003dbe:	8cda                	mv	s9,s6
    80003dc0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003dc2:	01278963          	beq	a5,s2,80003dd4 <namex+0x130>
    80003dc6:	dfbd                	beqz	a5,80003d44 <namex+0xa0>
    path++;
    80003dc8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dca:	0004c783          	lbu	a5,0(s1)
    80003dce:	ff279ce3          	bne	a5,s2,80003dc6 <namex+0x122>
    80003dd2:	bf8d                	j	80003d44 <namex+0xa0>
    memmove(name, s, len);
    80003dd4:	2601                	sext.w	a2,a2
    80003dd6:	8552                	mv	a0,s4
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	f42080e7          	jalr	-190(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003de0:	9cd2                	add	s9,s9,s4
    80003de2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003de6:	bf9d                	j	80003d5c <namex+0xb8>
  if(nameiparent){
    80003de8:	f20a83e3          	beqz	s5,80003d0e <namex+0x6a>
    iput(ip);
    80003dec:	854e                	mv	a0,s3
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	adc080e7          	jalr	-1316(ra) # 800038ca <iput>
    return 0;
    80003df6:	4981                	li	s3,0
    80003df8:	bf19                	j	80003d0e <namex+0x6a>
  if(*path == 0)
    80003dfa:	d7fd                	beqz	a5,80003de8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dfc:	0004c783          	lbu	a5,0(s1)
    80003e00:	85a6                	mv	a1,s1
    80003e02:	b7d1                	j	80003dc6 <namex+0x122>

0000000080003e04 <dirlink>:
{
    80003e04:	7139                	addi	sp,sp,-64
    80003e06:	fc06                	sd	ra,56(sp)
    80003e08:	f822                	sd	s0,48(sp)
    80003e0a:	f426                	sd	s1,40(sp)
    80003e0c:	f04a                	sd	s2,32(sp)
    80003e0e:	ec4e                	sd	s3,24(sp)
    80003e10:	e852                	sd	s4,16(sp)
    80003e12:	0080                	addi	s0,sp,64
    80003e14:	892a                	mv	s2,a0
    80003e16:	8a2e                	mv	s4,a1
    80003e18:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e1a:	4601                	li	a2,0
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	dd8080e7          	jalr	-552(ra) # 80003bf4 <dirlookup>
    80003e24:	e93d                	bnez	a0,80003e9a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e26:	04c92483          	lw	s1,76(s2)
    80003e2a:	c49d                	beqz	s1,80003e58 <dirlink+0x54>
    80003e2c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e2e:	4741                	li	a4,16
    80003e30:	86a6                	mv	a3,s1
    80003e32:	fc040613          	addi	a2,s0,-64
    80003e36:	4581                	li	a1,0
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	b8a080e7          	jalr	-1142(ra) # 800039c4 <readi>
    80003e42:	47c1                	li	a5,16
    80003e44:	06f51163          	bne	a0,a5,80003ea6 <dirlink+0xa2>
    if(de.inum == 0)
    80003e48:	fc045783          	lhu	a5,-64(s0)
    80003e4c:	c791                	beqz	a5,80003e58 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4e:	24c1                	addiw	s1,s1,16
    80003e50:	04c92783          	lw	a5,76(s2)
    80003e54:	fcf4ede3          	bltu	s1,a5,80003e2e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e58:	4639                	li	a2,14
    80003e5a:	85d2                	mv	a1,s4
    80003e5c:	fc240513          	addi	a0,s0,-62
    80003e60:	ffffd097          	auipc	ra,0xffffd
    80003e64:	f72080e7          	jalr	-142(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003e68:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e6c:	4741                	li	a4,16
    80003e6e:	86a6                	mv	a3,s1
    80003e70:	fc040613          	addi	a2,s0,-64
    80003e74:	4581                	li	a1,0
    80003e76:	854a                	mv	a0,s2
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	c44080e7          	jalr	-956(ra) # 80003abc <writei>
    80003e80:	872a                	mv	a4,a0
    80003e82:	47c1                	li	a5,16
  return 0;
    80003e84:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e86:	02f71863          	bne	a4,a5,80003eb6 <dirlink+0xb2>
}
    80003e8a:	70e2                	ld	ra,56(sp)
    80003e8c:	7442                	ld	s0,48(sp)
    80003e8e:	74a2                	ld	s1,40(sp)
    80003e90:	7902                	ld	s2,32(sp)
    80003e92:	69e2                	ld	s3,24(sp)
    80003e94:	6a42                	ld	s4,16(sp)
    80003e96:	6121                	addi	sp,sp,64
    80003e98:	8082                	ret
    iput(ip);
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	a30080e7          	jalr	-1488(ra) # 800038ca <iput>
    return -1;
    80003ea2:	557d                	li	a0,-1
    80003ea4:	b7dd                	j	80003e8a <dirlink+0x86>
      panic("dirlink read");
    80003ea6:	00005517          	auipc	a0,0x5
    80003eaa:	85a50513          	addi	a0,a0,-1958 # 80008700 <syscalls+0x1d0>
    80003eae:	ffffc097          	auipc	ra,0xffffc
    80003eb2:	67c080e7          	jalr	1660(ra) # 8000052a <panic>
    panic("dirlink");
    80003eb6:	00005517          	auipc	a0,0x5
    80003eba:	95250513          	addi	a0,a0,-1710 # 80008808 <syscalls+0x2d8>
    80003ebe:	ffffc097          	auipc	ra,0xffffc
    80003ec2:	66c080e7          	jalr	1644(ra) # 8000052a <panic>

0000000080003ec6 <namei>:

struct inode*
namei(char *path)
{
    80003ec6:	1101                	addi	sp,sp,-32
    80003ec8:	ec06                	sd	ra,24(sp)
    80003eca:	e822                	sd	s0,16(sp)
    80003ecc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ece:	fe040613          	addi	a2,s0,-32
    80003ed2:	4581                	li	a1,0
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	dd0080e7          	jalr	-560(ra) # 80003ca4 <namex>
}
    80003edc:	60e2                	ld	ra,24(sp)
    80003ede:	6442                	ld	s0,16(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret

0000000080003ee4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ee4:	1141                	addi	sp,sp,-16
    80003ee6:	e406                	sd	ra,8(sp)
    80003ee8:	e022                	sd	s0,0(sp)
    80003eea:	0800                	addi	s0,sp,16
    80003eec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eee:	4585                	li	a1,1
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	db4080e7          	jalr	-588(ra) # 80003ca4 <namex>
}
    80003ef8:	60a2                	ld	ra,8(sp)
    80003efa:	6402                	ld	s0,0(sp)
    80003efc:	0141                	addi	sp,sp,16
    80003efe:	8082                	ret

0000000080003f00 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f00:	1101                	addi	sp,sp,-32
    80003f02:	ec06                	sd	ra,24(sp)
    80003f04:	e822                	sd	s0,16(sp)
    80003f06:	e426                	sd	s1,8(sp)
    80003f08:	e04a                	sd	s2,0(sp)
    80003f0a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f0c:	0001d917          	auipc	s2,0x1d
    80003f10:	36490913          	addi	s2,s2,868 # 80021270 <log>
    80003f14:	01892583          	lw	a1,24(s2)
    80003f18:	02892503          	lw	a0,40(s2)
    80003f1c:	fffff097          	auipc	ra,0xfffff
    80003f20:	ff0080e7          	jalr	-16(ra) # 80002f0c <bread>
    80003f24:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f26:	02c92683          	lw	a3,44(s2)
    80003f2a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f2c:	02d05863          	blez	a3,80003f5c <write_head+0x5c>
    80003f30:	0001d797          	auipc	a5,0x1d
    80003f34:	37078793          	addi	a5,a5,880 # 800212a0 <log+0x30>
    80003f38:	05c50713          	addi	a4,a0,92
    80003f3c:	36fd                	addiw	a3,a3,-1
    80003f3e:	02069613          	slli	a2,a3,0x20
    80003f42:	01e65693          	srli	a3,a2,0x1e
    80003f46:	0001d617          	auipc	a2,0x1d
    80003f4a:	35e60613          	addi	a2,a2,862 # 800212a4 <log+0x34>
    80003f4e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f50:	4390                	lw	a2,0(a5)
    80003f52:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f54:	0791                	addi	a5,a5,4
    80003f56:	0711                	addi	a4,a4,4
    80003f58:	fed79ce3          	bne	a5,a3,80003f50 <write_head+0x50>
  }
  bwrite(buf);
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	0a0080e7          	jalr	160(ra) # 80002ffe <bwrite>
  brelse(buf);
    80003f66:	8526                	mv	a0,s1
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	0d4080e7          	jalr	212(ra) # 8000303c <brelse>
}
    80003f70:	60e2                	ld	ra,24(sp)
    80003f72:	6442                	ld	s0,16(sp)
    80003f74:	64a2                	ld	s1,8(sp)
    80003f76:	6902                	ld	s2,0(sp)
    80003f78:	6105                	addi	sp,sp,32
    80003f7a:	8082                	ret

0000000080003f7c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f7c:	0001d797          	auipc	a5,0x1d
    80003f80:	3207a783          	lw	a5,800(a5) # 8002129c <log+0x2c>
    80003f84:	0af05d63          	blez	a5,8000403e <install_trans+0xc2>
{
    80003f88:	7139                	addi	sp,sp,-64
    80003f8a:	fc06                	sd	ra,56(sp)
    80003f8c:	f822                	sd	s0,48(sp)
    80003f8e:	f426                	sd	s1,40(sp)
    80003f90:	f04a                	sd	s2,32(sp)
    80003f92:	ec4e                	sd	s3,24(sp)
    80003f94:	e852                	sd	s4,16(sp)
    80003f96:	e456                	sd	s5,8(sp)
    80003f98:	e05a                	sd	s6,0(sp)
    80003f9a:	0080                	addi	s0,sp,64
    80003f9c:	8b2a                	mv	s6,a0
    80003f9e:	0001da97          	auipc	s5,0x1d
    80003fa2:	302a8a93          	addi	s5,s5,770 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fa8:	0001d997          	auipc	s3,0x1d
    80003fac:	2c898993          	addi	s3,s3,712 # 80021270 <log>
    80003fb0:	a00d                	j	80003fd2 <install_trans+0x56>
    brelse(lbuf);
    80003fb2:	854a                	mv	a0,s2
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	088080e7          	jalr	136(ra) # 8000303c <brelse>
    brelse(dbuf);
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	07e080e7          	jalr	126(ra) # 8000303c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc6:	2a05                	addiw	s4,s4,1
    80003fc8:	0a91                	addi	s5,s5,4
    80003fca:	02c9a783          	lw	a5,44(s3)
    80003fce:	04fa5e63          	bge	s4,a5,8000402a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd2:	0189a583          	lw	a1,24(s3)
    80003fd6:	014585bb          	addw	a1,a1,s4
    80003fda:	2585                	addiw	a1,a1,1
    80003fdc:	0289a503          	lw	a0,40(s3)
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	f2c080e7          	jalr	-212(ra) # 80002f0c <bread>
    80003fe8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fea:	000aa583          	lw	a1,0(s5)
    80003fee:	0289a503          	lw	a0,40(s3)
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	f1a080e7          	jalr	-230(ra) # 80002f0c <bread>
    80003ffa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ffc:	40000613          	li	a2,1024
    80004000:	05890593          	addi	a1,s2,88
    80004004:	05850513          	addi	a0,a0,88
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	d12080e7          	jalr	-750(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	fec080e7          	jalr	-20(ra) # 80002ffe <bwrite>
    if(recovering == 0)
    8000401a:	f80b1ce3          	bnez	s6,80003fb2 <install_trans+0x36>
      bunpin(dbuf);
    8000401e:	8526                	mv	a0,s1
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	0f6080e7          	jalr	246(ra) # 80003116 <bunpin>
    80004028:	b769                	j	80003fb2 <install_trans+0x36>
}
    8000402a:	70e2                	ld	ra,56(sp)
    8000402c:	7442                	ld	s0,48(sp)
    8000402e:	74a2                	ld	s1,40(sp)
    80004030:	7902                	ld	s2,32(sp)
    80004032:	69e2                	ld	s3,24(sp)
    80004034:	6a42                	ld	s4,16(sp)
    80004036:	6aa2                	ld	s5,8(sp)
    80004038:	6b02                	ld	s6,0(sp)
    8000403a:	6121                	addi	sp,sp,64
    8000403c:	8082                	ret
    8000403e:	8082                	ret

0000000080004040 <initlog>:
{
    80004040:	7179                	addi	sp,sp,-48
    80004042:	f406                	sd	ra,40(sp)
    80004044:	f022                	sd	s0,32(sp)
    80004046:	ec26                	sd	s1,24(sp)
    80004048:	e84a                	sd	s2,16(sp)
    8000404a:	e44e                	sd	s3,8(sp)
    8000404c:	1800                	addi	s0,sp,48
    8000404e:	892a                	mv	s2,a0
    80004050:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004052:	0001d497          	auipc	s1,0x1d
    80004056:	21e48493          	addi	s1,s1,542 # 80021270 <log>
    8000405a:	00004597          	auipc	a1,0x4
    8000405e:	6b658593          	addi	a1,a1,1718 # 80008710 <syscalls+0x1e0>
    80004062:	8526                	mv	a0,s1
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	ace080e7          	jalr	-1330(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000406c:	0149a583          	lw	a1,20(s3)
    80004070:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004072:	0109a783          	lw	a5,16(s3)
    80004076:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004078:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000407c:	854a                	mv	a0,s2
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	e8e080e7          	jalr	-370(ra) # 80002f0c <bread>
  log.lh.n = lh->n;
    80004086:	4d34                	lw	a3,88(a0)
    80004088:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000408a:	02d05663          	blez	a3,800040b6 <initlog+0x76>
    8000408e:	05c50793          	addi	a5,a0,92
    80004092:	0001d717          	auipc	a4,0x1d
    80004096:	20e70713          	addi	a4,a4,526 # 800212a0 <log+0x30>
    8000409a:	36fd                	addiw	a3,a3,-1
    8000409c:	02069613          	slli	a2,a3,0x20
    800040a0:	01e65693          	srli	a3,a2,0x1e
    800040a4:	06050613          	addi	a2,a0,96
    800040a8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040aa:	4390                	lw	a2,0(a5)
    800040ac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040ae:	0791                	addi	a5,a5,4
    800040b0:	0711                	addi	a4,a4,4
    800040b2:	fed79ce3          	bne	a5,a3,800040aa <initlog+0x6a>
  brelse(buf);
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	f86080e7          	jalr	-122(ra) # 8000303c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040be:	4505                	li	a0,1
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	ebc080e7          	jalr	-324(ra) # 80003f7c <install_trans>
  log.lh.n = 0;
    800040c8:	0001d797          	auipc	a5,0x1d
    800040cc:	1c07aa23          	sw	zero,468(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	e30080e7          	jalr	-464(ra) # 80003f00 <write_head>
}
    800040d8:	70a2                	ld	ra,40(sp)
    800040da:	7402                	ld	s0,32(sp)
    800040dc:	64e2                	ld	s1,24(sp)
    800040de:	6942                	ld	s2,16(sp)
    800040e0:	69a2                	ld	s3,8(sp)
    800040e2:	6145                	addi	sp,sp,48
    800040e4:	8082                	ret

00000000800040e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040e6:	1101                	addi	sp,sp,-32
    800040e8:	ec06                	sd	ra,24(sp)
    800040ea:	e822                	sd	s0,16(sp)
    800040ec:	e426                	sd	s1,8(sp)
    800040ee:	e04a                	sd	s2,0(sp)
    800040f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040f2:	0001d517          	auipc	a0,0x1d
    800040f6:	17e50513          	addi	a0,a0,382 # 80021270 <log>
    800040fa:	ffffd097          	auipc	ra,0xffffd
    800040fe:	ac8080e7          	jalr	-1336(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004102:	0001d497          	auipc	s1,0x1d
    80004106:	16e48493          	addi	s1,s1,366 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000410a:	4979                	li	s2,30
    8000410c:	a039                	j	8000411a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000410e:	85a6                	mv	a1,s1
    80004110:	8526                	mv	a0,s1
    80004112:	ffffe097          	auipc	ra,0xffffe
    80004116:	f38080e7          	jalr	-200(ra) # 8000204a <sleep>
    if(log.committing){
    8000411a:	50dc                	lw	a5,36(s1)
    8000411c:	fbed                	bnez	a5,8000410e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411e:	509c                	lw	a5,32(s1)
    80004120:	0017871b          	addiw	a4,a5,1
    80004124:	0007069b          	sext.w	a3,a4
    80004128:	0027179b          	slliw	a5,a4,0x2
    8000412c:	9fb9                	addw	a5,a5,a4
    8000412e:	0017979b          	slliw	a5,a5,0x1
    80004132:	54d8                	lw	a4,44(s1)
    80004134:	9fb9                	addw	a5,a5,a4
    80004136:	00f95963          	bge	s2,a5,80004148 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000413a:	85a6                	mv	a1,s1
    8000413c:	8526                	mv	a0,s1
    8000413e:	ffffe097          	auipc	ra,0xffffe
    80004142:	f0c080e7          	jalr	-244(ra) # 8000204a <sleep>
    80004146:	bfd1                	j	8000411a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004148:	0001d517          	auipc	a0,0x1d
    8000414c:	12850513          	addi	a0,a0,296 # 80021270 <log>
    80004150:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	b24080e7          	jalr	-1244(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000415a:	60e2                	ld	ra,24(sp)
    8000415c:	6442                	ld	s0,16(sp)
    8000415e:	64a2                	ld	s1,8(sp)
    80004160:	6902                	ld	s2,0(sp)
    80004162:	6105                	addi	sp,sp,32
    80004164:	8082                	ret

0000000080004166 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004166:	7139                	addi	sp,sp,-64
    80004168:	fc06                	sd	ra,56(sp)
    8000416a:	f822                	sd	s0,48(sp)
    8000416c:	f426                	sd	s1,40(sp)
    8000416e:	f04a                	sd	s2,32(sp)
    80004170:	ec4e                	sd	s3,24(sp)
    80004172:	e852                	sd	s4,16(sp)
    80004174:	e456                	sd	s5,8(sp)
    80004176:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004178:	0001d497          	auipc	s1,0x1d
    8000417c:	0f848493          	addi	s1,s1,248 # 80021270 <log>
    80004180:	8526                	mv	a0,s1
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	a40080e7          	jalr	-1472(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000418a:	509c                	lw	a5,32(s1)
    8000418c:	37fd                	addiw	a5,a5,-1
    8000418e:	0007891b          	sext.w	s2,a5
    80004192:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004194:	50dc                	lw	a5,36(s1)
    80004196:	e7b9                	bnez	a5,800041e4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004198:	04091e63          	bnez	s2,800041f4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000419c:	0001d497          	auipc	s1,0x1d
    800041a0:	0d448493          	addi	s1,s1,212 # 80021270 <log>
    800041a4:	4785                	li	a5,1
    800041a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	acc080e7          	jalr	-1332(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041b2:	54dc                	lw	a5,44(s1)
    800041b4:	06f04763          	bgtz	a5,80004222 <end_op+0xbc>
    acquire(&log.lock);
    800041b8:	0001d497          	auipc	s1,0x1d
    800041bc:	0b848493          	addi	s1,s1,184 # 80021270 <log>
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	a00080e7          	jalr	-1536(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800041ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffe097          	auipc	ra,0xffffe
    800041d4:	006080e7          	jalr	6(ra) # 800021d6 <wakeup>
    release(&log.lock);
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	a9c080e7          	jalr	-1380(ra) # 80000c76 <release>
}
    800041e2:	a03d                	j	80004210 <end_op+0xaa>
    panic("log.committing");
    800041e4:	00004517          	auipc	a0,0x4
    800041e8:	53450513          	addi	a0,a0,1332 # 80008718 <syscalls+0x1e8>
    800041ec:	ffffc097          	auipc	ra,0xffffc
    800041f0:	33e080e7          	jalr	830(ra) # 8000052a <panic>
    wakeup(&log);
    800041f4:	0001d497          	auipc	s1,0x1d
    800041f8:	07c48493          	addi	s1,s1,124 # 80021270 <log>
    800041fc:	8526                	mv	a0,s1
    800041fe:	ffffe097          	auipc	ra,0xffffe
    80004202:	fd8080e7          	jalr	-40(ra) # 800021d6 <wakeup>
  release(&log.lock);
    80004206:	8526                	mv	a0,s1
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	a6e080e7          	jalr	-1426(ra) # 80000c76 <release>
}
    80004210:	70e2                	ld	ra,56(sp)
    80004212:	7442                	ld	s0,48(sp)
    80004214:	74a2                	ld	s1,40(sp)
    80004216:	7902                	ld	s2,32(sp)
    80004218:	69e2                	ld	s3,24(sp)
    8000421a:	6a42                	ld	s4,16(sp)
    8000421c:	6aa2                	ld	s5,8(sp)
    8000421e:	6121                	addi	sp,sp,64
    80004220:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004222:	0001da97          	auipc	s5,0x1d
    80004226:	07ea8a93          	addi	s5,s5,126 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000422a:	0001da17          	auipc	s4,0x1d
    8000422e:	046a0a13          	addi	s4,s4,70 # 80021270 <log>
    80004232:	018a2583          	lw	a1,24(s4)
    80004236:	012585bb          	addw	a1,a1,s2
    8000423a:	2585                	addiw	a1,a1,1
    8000423c:	028a2503          	lw	a0,40(s4)
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	ccc080e7          	jalr	-820(ra) # 80002f0c <bread>
    80004248:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000424a:	000aa583          	lw	a1,0(s5)
    8000424e:	028a2503          	lw	a0,40(s4)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	cba080e7          	jalr	-838(ra) # 80002f0c <bread>
    8000425a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000425c:	40000613          	li	a2,1024
    80004260:	05850593          	addi	a1,a0,88
    80004264:	05848513          	addi	a0,s1,88
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	ab2080e7          	jalr	-1358(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004270:	8526                	mv	a0,s1
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	d8c080e7          	jalr	-628(ra) # 80002ffe <bwrite>
    brelse(from);
    8000427a:	854e                	mv	a0,s3
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	dc0080e7          	jalr	-576(ra) # 8000303c <brelse>
    brelse(to);
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	db6080e7          	jalr	-586(ra) # 8000303c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428e:	2905                	addiw	s2,s2,1
    80004290:	0a91                	addi	s5,s5,4
    80004292:	02ca2783          	lw	a5,44(s4)
    80004296:	f8f94ee3          	blt	s2,a5,80004232 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	c66080e7          	jalr	-922(ra) # 80003f00 <write_head>
    install_trans(0); // Now install writes to home locations
    800042a2:	4501                	li	a0,0
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	cd8080e7          	jalr	-808(ra) # 80003f7c <install_trans>
    log.lh.n = 0;
    800042ac:	0001d797          	auipc	a5,0x1d
    800042b0:	fe07a823          	sw	zero,-16(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	c4c080e7          	jalr	-948(ra) # 80003f00 <write_head>
    800042bc:	bdf5                	j	800041b8 <end_op+0x52>

00000000800042be <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042be:	1101                	addi	sp,sp,-32
    800042c0:	ec06                	sd	ra,24(sp)
    800042c2:	e822                	sd	s0,16(sp)
    800042c4:	e426                	sd	s1,8(sp)
    800042c6:	e04a                	sd	s2,0(sp)
    800042c8:	1000                	addi	s0,sp,32
    800042ca:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042cc:	0001d917          	auipc	s2,0x1d
    800042d0:	fa490913          	addi	s2,s2,-92 # 80021270 <log>
    800042d4:	854a                	mv	a0,s2
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	8ec080e7          	jalr	-1812(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042de:	02c92603          	lw	a2,44(s2)
    800042e2:	47f5                	li	a5,29
    800042e4:	06c7c563          	blt	a5,a2,8000434e <log_write+0x90>
    800042e8:	0001d797          	auipc	a5,0x1d
    800042ec:	fa47a783          	lw	a5,-92(a5) # 8002128c <log+0x1c>
    800042f0:	37fd                	addiw	a5,a5,-1
    800042f2:	04f65e63          	bge	a2,a5,8000434e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042f6:	0001d797          	auipc	a5,0x1d
    800042fa:	f9a7a783          	lw	a5,-102(a5) # 80021290 <log+0x20>
    800042fe:	06f05063          	blez	a5,8000435e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004302:	4781                	li	a5,0
    80004304:	06c05563          	blez	a2,8000436e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004308:	44cc                	lw	a1,12(s1)
    8000430a:	0001d717          	auipc	a4,0x1d
    8000430e:	f9670713          	addi	a4,a4,-106 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004312:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004314:	4314                	lw	a3,0(a4)
    80004316:	04b68c63          	beq	a3,a1,8000436e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000431a:	2785                	addiw	a5,a5,1
    8000431c:	0711                	addi	a4,a4,4
    8000431e:	fef61be3          	bne	a2,a5,80004314 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004322:	0621                	addi	a2,a2,8
    80004324:	060a                	slli	a2,a2,0x2
    80004326:	0001d797          	auipc	a5,0x1d
    8000432a:	f4a78793          	addi	a5,a5,-182 # 80021270 <log>
    8000432e:	963e                	add	a2,a2,a5
    80004330:	44dc                	lw	a5,12(s1)
    80004332:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004334:	8526                	mv	a0,s1
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	da4080e7          	jalr	-604(ra) # 800030da <bpin>
    log.lh.n++;
    8000433e:	0001d717          	auipc	a4,0x1d
    80004342:	f3270713          	addi	a4,a4,-206 # 80021270 <log>
    80004346:	575c                	lw	a5,44(a4)
    80004348:	2785                	addiw	a5,a5,1
    8000434a:	d75c                	sw	a5,44(a4)
    8000434c:	a835                	j	80004388 <log_write+0xca>
    panic("too big a transaction");
    8000434e:	00004517          	auipc	a0,0x4
    80004352:	3da50513          	addi	a0,a0,986 # 80008728 <syscalls+0x1f8>
    80004356:	ffffc097          	auipc	ra,0xffffc
    8000435a:	1d4080e7          	jalr	468(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000435e:	00004517          	auipc	a0,0x4
    80004362:	3e250513          	addi	a0,a0,994 # 80008740 <syscalls+0x210>
    80004366:	ffffc097          	auipc	ra,0xffffc
    8000436a:	1c4080e7          	jalr	452(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000436e:	00878713          	addi	a4,a5,8
    80004372:	00271693          	slli	a3,a4,0x2
    80004376:	0001d717          	auipc	a4,0x1d
    8000437a:	efa70713          	addi	a4,a4,-262 # 80021270 <log>
    8000437e:	9736                	add	a4,a4,a3
    80004380:	44d4                	lw	a3,12(s1)
    80004382:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004384:	faf608e3          	beq	a2,a5,80004334 <log_write+0x76>
  }
  release(&log.lock);
    80004388:	0001d517          	auipc	a0,0x1d
    8000438c:	ee850513          	addi	a0,a0,-280 # 80021270 <log>
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	8e6080e7          	jalr	-1818(ra) # 80000c76 <release>
}
    80004398:	60e2                	ld	ra,24(sp)
    8000439a:	6442                	ld	s0,16(sp)
    8000439c:	64a2                	ld	s1,8(sp)
    8000439e:	6902                	ld	s2,0(sp)
    800043a0:	6105                	addi	sp,sp,32
    800043a2:	8082                	ret

00000000800043a4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043a4:	1101                	addi	sp,sp,-32
    800043a6:	ec06                	sd	ra,24(sp)
    800043a8:	e822                	sd	s0,16(sp)
    800043aa:	e426                	sd	s1,8(sp)
    800043ac:	e04a                	sd	s2,0(sp)
    800043ae:	1000                	addi	s0,sp,32
    800043b0:	84aa                	mv	s1,a0
    800043b2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043b4:	00004597          	auipc	a1,0x4
    800043b8:	3ac58593          	addi	a1,a1,940 # 80008760 <syscalls+0x230>
    800043bc:	0521                	addi	a0,a0,8
    800043be:	ffffc097          	auipc	ra,0xffffc
    800043c2:	774080e7          	jalr	1908(ra) # 80000b32 <initlock>
  lk->name = name;
    800043c6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043ce:	0204a423          	sw	zero,40(s1)
}
    800043d2:	60e2                	ld	ra,24(sp)
    800043d4:	6442                	ld	s0,16(sp)
    800043d6:	64a2                	ld	s1,8(sp)
    800043d8:	6902                	ld	s2,0(sp)
    800043da:	6105                	addi	sp,sp,32
    800043dc:	8082                	ret

00000000800043de <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043de:	1101                	addi	sp,sp,-32
    800043e0:	ec06                	sd	ra,24(sp)
    800043e2:	e822                	sd	s0,16(sp)
    800043e4:	e426                	sd	s1,8(sp)
    800043e6:	e04a                	sd	s2,0(sp)
    800043e8:	1000                	addi	s0,sp,32
    800043ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ec:	00850913          	addi	s2,a0,8
    800043f0:	854a                	mv	a0,s2
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	7d0080e7          	jalr	2000(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800043fa:	409c                	lw	a5,0(s1)
    800043fc:	cb89                	beqz	a5,8000440e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043fe:	85ca                	mv	a1,s2
    80004400:	8526                	mv	a0,s1
    80004402:	ffffe097          	auipc	ra,0xffffe
    80004406:	c48080e7          	jalr	-952(ra) # 8000204a <sleep>
  while (lk->locked) {
    8000440a:	409c                	lw	a5,0(s1)
    8000440c:	fbed                	bnez	a5,800043fe <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000440e:	4785                	li	a5,1
    80004410:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004412:	ffffd097          	auipc	ra,0xffffd
    80004416:	56c080e7          	jalr	1388(ra) # 8000197e <myproc>
    8000441a:	591c                	lw	a5,48(a0)
    8000441c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000441e:	854a                	mv	a0,s2
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	856080e7          	jalr	-1962(ra) # 80000c76 <release>
}
    80004428:	60e2                	ld	ra,24(sp)
    8000442a:	6442                	ld	s0,16(sp)
    8000442c:	64a2                	ld	s1,8(sp)
    8000442e:	6902                	ld	s2,0(sp)
    80004430:	6105                	addi	sp,sp,32
    80004432:	8082                	ret

0000000080004434 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004434:	1101                	addi	sp,sp,-32
    80004436:	ec06                	sd	ra,24(sp)
    80004438:	e822                	sd	s0,16(sp)
    8000443a:	e426                	sd	s1,8(sp)
    8000443c:	e04a                	sd	s2,0(sp)
    8000443e:	1000                	addi	s0,sp,32
    80004440:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004442:	00850913          	addi	s2,a0,8
    80004446:	854a                	mv	a0,s2
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	77a080e7          	jalr	1914(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004450:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004454:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffe097          	auipc	ra,0xffffe
    8000445e:	d7c080e7          	jalr	-644(ra) # 800021d6 <wakeup>
  release(&lk->lk);
    80004462:	854a                	mv	a0,s2
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	812080e7          	jalr	-2030(ra) # 80000c76 <release>
}
    8000446c:	60e2                	ld	ra,24(sp)
    8000446e:	6442                	ld	s0,16(sp)
    80004470:	64a2                	ld	s1,8(sp)
    80004472:	6902                	ld	s2,0(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret

0000000080004478 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004478:	7179                	addi	sp,sp,-48
    8000447a:	f406                	sd	ra,40(sp)
    8000447c:	f022                	sd	s0,32(sp)
    8000447e:	ec26                	sd	s1,24(sp)
    80004480:	e84a                	sd	s2,16(sp)
    80004482:	e44e                	sd	s3,8(sp)
    80004484:	1800                	addi	s0,sp,48
    80004486:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004488:	00850913          	addi	s2,a0,8
    8000448c:	854a                	mv	a0,s2
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	734080e7          	jalr	1844(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004496:	409c                	lw	a5,0(s1)
    80004498:	ef99                	bnez	a5,800044b6 <holdingsleep+0x3e>
    8000449a:	4481                	li	s1,0
  release(&lk->lk);
    8000449c:	854a                	mv	a0,s2
    8000449e:	ffffc097          	auipc	ra,0xffffc
    800044a2:	7d8080e7          	jalr	2008(ra) # 80000c76 <release>
  return r;
}
    800044a6:	8526                	mv	a0,s1
    800044a8:	70a2                	ld	ra,40(sp)
    800044aa:	7402                	ld	s0,32(sp)
    800044ac:	64e2                	ld	s1,24(sp)
    800044ae:	6942                	ld	s2,16(sp)
    800044b0:	69a2                	ld	s3,8(sp)
    800044b2:	6145                	addi	sp,sp,48
    800044b4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044b6:	0284a983          	lw	s3,40(s1)
    800044ba:	ffffd097          	auipc	ra,0xffffd
    800044be:	4c4080e7          	jalr	1220(ra) # 8000197e <myproc>
    800044c2:	5904                	lw	s1,48(a0)
    800044c4:	413484b3          	sub	s1,s1,s3
    800044c8:	0014b493          	seqz	s1,s1
    800044cc:	bfc1                	j	8000449c <holdingsleep+0x24>

00000000800044ce <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044ce:	1141                	addi	sp,sp,-16
    800044d0:	e406                	sd	ra,8(sp)
    800044d2:	e022                	sd	s0,0(sp)
    800044d4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044d6:	00004597          	auipc	a1,0x4
    800044da:	29a58593          	addi	a1,a1,666 # 80008770 <syscalls+0x240>
    800044de:	0001d517          	auipc	a0,0x1d
    800044e2:	eda50513          	addi	a0,a0,-294 # 800213b8 <ftable>
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	64c080e7          	jalr	1612(ra) # 80000b32 <initlock>
}
    800044ee:	60a2                	ld	ra,8(sp)
    800044f0:	6402                	ld	s0,0(sp)
    800044f2:	0141                	addi	sp,sp,16
    800044f4:	8082                	ret

00000000800044f6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044f6:	1101                	addi	sp,sp,-32
    800044f8:	ec06                	sd	ra,24(sp)
    800044fa:	e822                	sd	s0,16(sp)
    800044fc:	e426                	sd	s1,8(sp)
    800044fe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004500:	0001d517          	auipc	a0,0x1d
    80004504:	eb850513          	addi	a0,a0,-328 # 800213b8 <ftable>
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	6ba080e7          	jalr	1722(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004510:	0001d497          	auipc	s1,0x1d
    80004514:	ec048493          	addi	s1,s1,-320 # 800213d0 <ftable+0x18>
    80004518:	0001e717          	auipc	a4,0x1e
    8000451c:	e5870713          	addi	a4,a4,-424 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004520:	40dc                	lw	a5,4(s1)
    80004522:	cf99                	beqz	a5,80004540 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004524:	02848493          	addi	s1,s1,40
    80004528:	fee49ce3          	bne	s1,a4,80004520 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000452c:	0001d517          	auipc	a0,0x1d
    80004530:	e8c50513          	addi	a0,a0,-372 # 800213b8 <ftable>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	742080e7          	jalr	1858(ra) # 80000c76 <release>
  return 0;
    8000453c:	4481                	li	s1,0
    8000453e:	a819                	j	80004554 <filealloc+0x5e>
      f->ref = 1;
    80004540:	4785                	li	a5,1
    80004542:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004544:	0001d517          	auipc	a0,0x1d
    80004548:	e7450513          	addi	a0,a0,-396 # 800213b8 <ftable>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	72a080e7          	jalr	1834(ra) # 80000c76 <release>
}
    80004554:	8526                	mv	a0,s1
    80004556:	60e2                	ld	ra,24(sp)
    80004558:	6442                	ld	s0,16(sp)
    8000455a:	64a2                	ld	s1,8(sp)
    8000455c:	6105                	addi	sp,sp,32
    8000455e:	8082                	ret

0000000080004560 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004560:	1101                	addi	sp,sp,-32
    80004562:	ec06                	sd	ra,24(sp)
    80004564:	e822                	sd	s0,16(sp)
    80004566:	e426                	sd	s1,8(sp)
    80004568:	1000                	addi	s0,sp,32
    8000456a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000456c:	0001d517          	auipc	a0,0x1d
    80004570:	e4c50513          	addi	a0,a0,-436 # 800213b8 <ftable>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	64e080e7          	jalr	1614(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000457c:	40dc                	lw	a5,4(s1)
    8000457e:	02f05263          	blez	a5,800045a2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004582:	2785                	addiw	a5,a5,1
    80004584:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	e3250513          	addi	a0,a0,-462 # 800213b8 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	6e8080e7          	jalr	1768(ra) # 80000c76 <release>
  return f;
}
    80004596:	8526                	mv	a0,s1
    80004598:	60e2                	ld	ra,24(sp)
    8000459a:	6442                	ld	s0,16(sp)
    8000459c:	64a2                	ld	s1,8(sp)
    8000459e:	6105                	addi	sp,sp,32
    800045a0:	8082                	ret
    panic("filedup");
    800045a2:	00004517          	auipc	a0,0x4
    800045a6:	1d650513          	addi	a0,a0,470 # 80008778 <syscalls+0x248>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	f80080e7          	jalr	-128(ra) # 8000052a <panic>

00000000800045b2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045b2:	7139                	addi	sp,sp,-64
    800045b4:	fc06                	sd	ra,56(sp)
    800045b6:	f822                	sd	s0,48(sp)
    800045b8:	f426                	sd	s1,40(sp)
    800045ba:	f04a                	sd	s2,32(sp)
    800045bc:	ec4e                	sd	s3,24(sp)
    800045be:	e852                	sd	s4,16(sp)
    800045c0:	e456                	sd	s5,8(sp)
    800045c2:	0080                	addi	s0,sp,64
    800045c4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045c6:	0001d517          	auipc	a0,0x1d
    800045ca:	df250513          	addi	a0,a0,-526 # 800213b8 <ftable>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	5f4080e7          	jalr	1524(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800045d6:	40dc                	lw	a5,4(s1)
    800045d8:	06f05163          	blez	a5,8000463a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045dc:	37fd                	addiw	a5,a5,-1
    800045de:	0007871b          	sext.w	a4,a5
    800045e2:	c0dc                	sw	a5,4(s1)
    800045e4:	06e04363          	bgtz	a4,8000464a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045e8:	0004a903          	lw	s2,0(s1)
    800045ec:	0094ca83          	lbu	s5,9(s1)
    800045f0:	0104ba03          	ld	s4,16(s1)
    800045f4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045f8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045fc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004600:	0001d517          	auipc	a0,0x1d
    80004604:	db850513          	addi	a0,a0,-584 # 800213b8 <ftable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	66e080e7          	jalr	1646(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004610:	4785                	li	a5,1
    80004612:	04f90d63          	beq	s2,a5,8000466c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004616:	3979                	addiw	s2,s2,-2
    80004618:	4785                	li	a5,1
    8000461a:	0527e063          	bltu	a5,s2,8000465a <fileclose+0xa8>
    begin_op();
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	ac8080e7          	jalr	-1336(ra) # 800040e6 <begin_op>
    iput(ff.ip);
    80004626:	854e                	mv	a0,s3
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	2a2080e7          	jalr	674(ra) # 800038ca <iput>
    end_op();
    80004630:	00000097          	auipc	ra,0x0
    80004634:	b36080e7          	jalr	-1226(ra) # 80004166 <end_op>
    80004638:	a00d                	j	8000465a <fileclose+0xa8>
    panic("fileclose");
    8000463a:	00004517          	auipc	a0,0x4
    8000463e:	14650513          	addi	a0,a0,326 # 80008780 <syscalls+0x250>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	ee8080e7          	jalr	-280(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000464a:	0001d517          	auipc	a0,0x1d
    8000464e:	d6e50513          	addi	a0,a0,-658 # 800213b8 <ftable>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	624080e7          	jalr	1572(ra) # 80000c76 <release>
  }
}
    8000465a:	70e2                	ld	ra,56(sp)
    8000465c:	7442                	ld	s0,48(sp)
    8000465e:	74a2                	ld	s1,40(sp)
    80004660:	7902                	ld	s2,32(sp)
    80004662:	69e2                	ld	s3,24(sp)
    80004664:	6a42                	ld	s4,16(sp)
    80004666:	6aa2                	ld	s5,8(sp)
    80004668:	6121                	addi	sp,sp,64
    8000466a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000466c:	85d6                	mv	a1,s5
    8000466e:	8552                	mv	a0,s4
    80004670:	00000097          	auipc	ra,0x0
    80004674:	34c080e7          	jalr	844(ra) # 800049bc <pipeclose>
    80004678:	b7cd                	j	8000465a <fileclose+0xa8>

000000008000467a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000467a:	715d                	addi	sp,sp,-80
    8000467c:	e486                	sd	ra,72(sp)
    8000467e:	e0a2                	sd	s0,64(sp)
    80004680:	fc26                	sd	s1,56(sp)
    80004682:	f84a                	sd	s2,48(sp)
    80004684:	f44e                	sd	s3,40(sp)
    80004686:	0880                	addi	s0,sp,80
    80004688:	84aa                	mv	s1,a0
    8000468a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000468c:	ffffd097          	auipc	ra,0xffffd
    80004690:	2f2080e7          	jalr	754(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004694:	409c                	lw	a5,0(s1)
    80004696:	37f9                	addiw	a5,a5,-2
    80004698:	4705                	li	a4,1
    8000469a:	04f76763          	bltu	a4,a5,800046e8 <filestat+0x6e>
    8000469e:	892a                	mv	s2,a0
    ilock(f->ip);
    800046a0:	6c88                	ld	a0,24(s1)
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	06e080e7          	jalr	110(ra) # 80003710 <ilock>
    stati(f->ip, &st);
    800046aa:	fb840593          	addi	a1,s0,-72
    800046ae:	6c88                	ld	a0,24(s1)
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	2ea080e7          	jalr	746(ra) # 8000399a <stati>
    iunlock(f->ip);
    800046b8:	6c88                	ld	a0,24(s1)
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	118080e7          	jalr	280(ra) # 800037d2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046c2:	46e1                	li	a3,24
    800046c4:	fb840613          	addi	a2,s0,-72
    800046c8:	85ce                	mv	a1,s3
    800046ca:	05093503          	ld	a0,80(s2)
    800046ce:	ffffd097          	auipc	ra,0xffffd
    800046d2:	f70080e7          	jalr	-144(ra) # 8000163e <copyout>
    800046d6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046da:	60a6                	ld	ra,72(sp)
    800046dc:	6406                	ld	s0,64(sp)
    800046de:	74e2                	ld	s1,56(sp)
    800046e0:	7942                	ld	s2,48(sp)
    800046e2:	79a2                	ld	s3,40(sp)
    800046e4:	6161                	addi	sp,sp,80
    800046e6:	8082                	ret
  return -1;
    800046e8:	557d                	li	a0,-1
    800046ea:	bfc5                	j	800046da <filestat+0x60>

00000000800046ec <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046ec:	7179                	addi	sp,sp,-48
    800046ee:	f406                	sd	ra,40(sp)
    800046f0:	f022                	sd	s0,32(sp)
    800046f2:	ec26                	sd	s1,24(sp)
    800046f4:	e84a                	sd	s2,16(sp)
    800046f6:	e44e                	sd	s3,8(sp)
    800046f8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046fa:	00854783          	lbu	a5,8(a0)
    800046fe:	c3d5                	beqz	a5,800047a2 <fileread+0xb6>
    80004700:	84aa                	mv	s1,a0
    80004702:	89ae                	mv	s3,a1
    80004704:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004706:	411c                	lw	a5,0(a0)
    80004708:	4705                	li	a4,1
    8000470a:	04e78963          	beq	a5,a4,8000475c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000470e:	470d                	li	a4,3
    80004710:	04e78d63          	beq	a5,a4,8000476a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004714:	4709                	li	a4,2
    80004716:	06e79e63          	bne	a5,a4,80004792 <fileread+0xa6>
    ilock(f->ip);
    8000471a:	6d08                	ld	a0,24(a0)
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	ff4080e7          	jalr	-12(ra) # 80003710 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004724:	874a                	mv	a4,s2
    80004726:	5094                	lw	a3,32(s1)
    80004728:	864e                	mv	a2,s3
    8000472a:	4585                	li	a1,1
    8000472c:	6c88                	ld	a0,24(s1)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	296080e7          	jalr	662(ra) # 800039c4 <readi>
    80004736:	892a                	mv	s2,a0
    80004738:	00a05563          	blez	a0,80004742 <fileread+0x56>
      f->off += r;
    8000473c:	509c                	lw	a5,32(s1)
    8000473e:	9fa9                	addw	a5,a5,a0
    80004740:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	08e080e7          	jalr	142(ra) # 800037d2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000474c:	854a                	mv	a0,s2
    8000474e:	70a2                	ld	ra,40(sp)
    80004750:	7402                	ld	s0,32(sp)
    80004752:	64e2                	ld	s1,24(sp)
    80004754:	6942                	ld	s2,16(sp)
    80004756:	69a2                	ld	s3,8(sp)
    80004758:	6145                	addi	sp,sp,48
    8000475a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000475c:	6908                	ld	a0,16(a0)
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	3c0080e7          	jalr	960(ra) # 80004b1e <piperead>
    80004766:	892a                	mv	s2,a0
    80004768:	b7d5                	j	8000474c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000476a:	02451783          	lh	a5,36(a0)
    8000476e:	03079693          	slli	a3,a5,0x30
    80004772:	92c1                	srli	a3,a3,0x30
    80004774:	4725                	li	a4,9
    80004776:	02d76863          	bltu	a4,a3,800047a6 <fileread+0xba>
    8000477a:	0792                	slli	a5,a5,0x4
    8000477c:	0001d717          	auipc	a4,0x1d
    80004780:	b9c70713          	addi	a4,a4,-1124 # 80021318 <devsw>
    80004784:	97ba                	add	a5,a5,a4
    80004786:	639c                	ld	a5,0(a5)
    80004788:	c38d                	beqz	a5,800047aa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000478a:	4505                	li	a0,1
    8000478c:	9782                	jalr	a5
    8000478e:	892a                	mv	s2,a0
    80004790:	bf75                	j	8000474c <fileread+0x60>
    panic("fileread");
    80004792:	00004517          	auipc	a0,0x4
    80004796:	ffe50513          	addi	a0,a0,-2 # 80008790 <syscalls+0x260>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	d90080e7          	jalr	-624(ra) # 8000052a <panic>
    return -1;
    800047a2:	597d                	li	s2,-1
    800047a4:	b765                	j	8000474c <fileread+0x60>
      return -1;
    800047a6:	597d                	li	s2,-1
    800047a8:	b755                	j	8000474c <fileread+0x60>
    800047aa:	597d                	li	s2,-1
    800047ac:	b745                	j	8000474c <fileread+0x60>

00000000800047ae <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047ae:	715d                	addi	sp,sp,-80
    800047b0:	e486                	sd	ra,72(sp)
    800047b2:	e0a2                	sd	s0,64(sp)
    800047b4:	fc26                	sd	s1,56(sp)
    800047b6:	f84a                	sd	s2,48(sp)
    800047b8:	f44e                	sd	s3,40(sp)
    800047ba:	f052                	sd	s4,32(sp)
    800047bc:	ec56                	sd	s5,24(sp)
    800047be:	e85a                	sd	s6,16(sp)
    800047c0:	e45e                	sd	s7,8(sp)
    800047c2:	e062                	sd	s8,0(sp)
    800047c4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047c6:	00954783          	lbu	a5,9(a0)
    800047ca:	10078663          	beqz	a5,800048d6 <filewrite+0x128>
    800047ce:	892a                	mv	s2,a0
    800047d0:	8aae                	mv	s5,a1
    800047d2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047d4:	411c                	lw	a5,0(a0)
    800047d6:	4705                	li	a4,1
    800047d8:	02e78263          	beq	a5,a4,800047fc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047dc:	470d                	li	a4,3
    800047de:	02e78663          	beq	a5,a4,8000480a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047e2:	4709                	li	a4,2
    800047e4:	0ee79163          	bne	a5,a4,800048c6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047e8:	0ac05d63          	blez	a2,800048a2 <filewrite+0xf4>
    int i = 0;
    800047ec:	4981                	li	s3,0
    800047ee:	6b05                	lui	s6,0x1
    800047f0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047f4:	6b85                	lui	s7,0x1
    800047f6:	c00b8b9b          	addiw	s7,s7,-1024
    800047fa:	a861                	j	80004892 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047fc:	6908                	ld	a0,16(a0)
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	22e080e7          	jalr	558(ra) # 80004a2c <pipewrite>
    80004806:	8a2a                	mv	s4,a0
    80004808:	a045                	j	800048a8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000480a:	02451783          	lh	a5,36(a0)
    8000480e:	03079693          	slli	a3,a5,0x30
    80004812:	92c1                	srli	a3,a3,0x30
    80004814:	4725                	li	a4,9
    80004816:	0cd76263          	bltu	a4,a3,800048da <filewrite+0x12c>
    8000481a:	0792                	slli	a5,a5,0x4
    8000481c:	0001d717          	auipc	a4,0x1d
    80004820:	afc70713          	addi	a4,a4,-1284 # 80021318 <devsw>
    80004824:	97ba                	add	a5,a5,a4
    80004826:	679c                	ld	a5,8(a5)
    80004828:	cbdd                	beqz	a5,800048de <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000482a:	4505                	li	a0,1
    8000482c:	9782                	jalr	a5
    8000482e:	8a2a                	mv	s4,a0
    80004830:	a8a5                	j	800048a8 <filewrite+0xfa>
    80004832:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004836:	00000097          	auipc	ra,0x0
    8000483a:	8b0080e7          	jalr	-1872(ra) # 800040e6 <begin_op>
      ilock(f->ip);
    8000483e:	01893503          	ld	a0,24(s2)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	ece080e7          	jalr	-306(ra) # 80003710 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000484a:	8762                	mv	a4,s8
    8000484c:	02092683          	lw	a3,32(s2)
    80004850:	01598633          	add	a2,s3,s5
    80004854:	4585                	li	a1,1
    80004856:	01893503          	ld	a0,24(s2)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	262080e7          	jalr	610(ra) # 80003abc <writei>
    80004862:	84aa                	mv	s1,a0
    80004864:	00a05763          	blez	a0,80004872 <filewrite+0xc4>
        f->off += r;
    80004868:	02092783          	lw	a5,32(s2)
    8000486c:	9fa9                	addw	a5,a5,a0
    8000486e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004872:	01893503          	ld	a0,24(s2)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	f5c080e7          	jalr	-164(ra) # 800037d2 <iunlock>
      end_op();
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	8e8080e7          	jalr	-1816(ra) # 80004166 <end_op>

      if(r != n1){
    80004886:	009c1f63          	bne	s8,s1,800048a4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000488a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000488e:	0149db63          	bge	s3,s4,800048a4 <filewrite+0xf6>
      int n1 = n - i;
    80004892:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004896:	84be                	mv	s1,a5
    80004898:	2781                	sext.w	a5,a5
    8000489a:	f8fb5ce3          	bge	s6,a5,80004832 <filewrite+0x84>
    8000489e:	84de                	mv	s1,s7
    800048a0:	bf49                	j	80004832 <filewrite+0x84>
    int i = 0;
    800048a2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048a4:	013a1f63          	bne	s4,s3,800048c2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048a8:	8552                	mv	a0,s4
    800048aa:	60a6                	ld	ra,72(sp)
    800048ac:	6406                	ld	s0,64(sp)
    800048ae:	74e2                	ld	s1,56(sp)
    800048b0:	7942                	ld	s2,48(sp)
    800048b2:	79a2                	ld	s3,40(sp)
    800048b4:	7a02                	ld	s4,32(sp)
    800048b6:	6ae2                	ld	s5,24(sp)
    800048b8:	6b42                	ld	s6,16(sp)
    800048ba:	6ba2                	ld	s7,8(sp)
    800048bc:	6c02                	ld	s8,0(sp)
    800048be:	6161                	addi	sp,sp,80
    800048c0:	8082                	ret
    ret = (i == n ? n : -1);
    800048c2:	5a7d                	li	s4,-1
    800048c4:	b7d5                	j	800048a8 <filewrite+0xfa>
    panic("filewrite");
    800048c6:	00004517          	auipc	a0,0x4
    800048ca:	eda50513          	addi	a0,a0,-294 # 800087a0 <syscalls+0x270>
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	c5c080e7          	jalr	-932(ra) # 8000052a <panic>
    return -1;
    800048d6:	5a7d                	li	s4,-1
    800048d8:	bfc1                	j	800048a8 <filewrite+0xfa>
      return -1;
    800048da:	5a7d                	li	s4,-1
    800048dc:	b7f1                	j	800048a8 <filewrite+0xfa>
    800048de:	5a7d                	li	s4,-1
    800048e0:	b7e1                	j	800048a8 <filewrite+0xfa>

00000000800048e2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048e2:	7179                	addi	sp,sp,-48
    800048e4:	f406                	sd	ra,40(sp)
    800048e6:	f022                	sd	s0,32(sp)
    800048e8:	ec26                	sd	s1,24(sp)
    800048ea:	e84a                	sd	s2,16(sp)
    800048ec:	e44e                	sd	s3,8(sp)
    800048ee:	e052                	sd	s4,0(sp)
    800048f0:	1800                	addi	s0,sp,48
    800048f2:	84aa                	mv	s1,a0
    800048f4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048f6:	0005b023          	sd	zero,0(a1)
    800048fa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	bf8080e7          	jalr	-1032(ra) # 800044f6 <filealloc>
    80004906:	e088                	sd	a0,0(s1)
    80004908:	c551                	beqz	a0,80004994 <pipealloc+0xb2>
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	bec080e7          	jalr	-1044(ra) # 800044f6 <filealloc>
    80004912:	00aa3023          	sd	a0,0(s4)
    80004916:	c92d                	beqz	a0,80004988 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	1ba080e7          	jalr	442(ra) # 80000ad2 <kalloc>
    80004920:	892a                	mv	s2,a0
    80004922:	c125                	beqz	a0,80004982 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004924:	4985                	li	s3,1
    80004926:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000492a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000492e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004932:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004936:	00004597          	auipc	a1,0x4
    8000493a:	b5258593          	addi	a1,a1,-1198 # 80008488 <states.0+0x1e0>
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	1f4080e7          	jalr	500(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004946:	609c                	ld	a5,0(s1)
    80004948:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000494c:	609c                	ld	a5,0(s1)
    8000494e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004952:	609c                	ld	a5,0(s1)
    80004954:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004958:	609c                	ld	a5,0(s1)
    8000495a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000495e:	000a3783          	ld	a5,0(s4)
    80004962:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004966:	000a3783          	ld	a5,0(s4)
    8000496a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000496e:	000a3783          	ld	a5,0(s4)
    80004972:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004976:	000a3783          	ld	a5,0(s4)
    8000497a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000497e:	4501                	li	a0,0
    80004980:	a025                	j	800049a8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004982:	6088                	ld	a0,0(s1)
    80004984:	e501                	bnez	a0,8000498c <pipealloc+0xaa>
    80004986:	a039                	j	80004994 <pipealloc+0xb2>
    80004988:	6088                	ld	a0,0(s1)
    8000498a:	c51d                	beqz	a0,800049b8 <pipealloc+0xd6>
    fileclose(*f0);
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	c26080e7          	jalr	-986(ra) # 800045b2 <fileclose>
  if(*f1)
    80004994:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004998:	557d                	li	a0,-1
  if(*f1)
    8000499a:	c799                	beqz	a5,800049a8 <pipealloc+0xc6>
    fileclose(*f1);
    8000499c:	853e                	mv	a0,a5
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	c14080e7          	jalr	-1004(ra) # 800045b2 <fileclose>
  return -1;
    800049a6:	557d                	li	a0,-1
}
    800049a8:	70a2                	ld	ra,40(sp)
    800049aa:	7402                	ld	s0,32(sp)
    800049ac:	64e2                	ld	s1,24(sp)
    800049ae:	6942                	ld	s2,16(sp)
    800049b0:	69a2                	ld	s3,8(sp)
    800049b2:	6a02                	ld	s4,0(sp)
    800049b4:	6145                	addi	sp,sp,48
    800049b6:	8082                	ret
  return -1;
    800049b8:	557d                	li	a0,-1
    800049ba:	b7fd                	j	800049a8 <pipealloc+0xc6>

00000000800049bc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049bc:	1101                	addi	sp,sp,-32
    800049be:	ec06                	sd	ra,24(sp)
    800049c0:	e822                	sd	s0,16(sp)
    800049c2:	e426                	sd	s1,8(sp)
    800049c4:	e04a                	sd	s2,0(sp)
    800049c6:	1000                	addi	s0,sp,32
    800049c8:	84aa                	mv	s1,a0
    800049ca:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	1f6080e7          	jalr	502(ra) # 80000bc2 <acquire>
  if(writable){
    800049d4:	02090d63          	beqz	s2,80004a0e <pipeclose+0x52>
    pi->writeopen = 0;
    800049d8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049dc:	21848513          	addi	a0,s1,536
    800049e0:	ffffd097          	auipc	ra,0xffffd
    800049e4:	7f6080e7          	jalr	2038(ra) # 800021d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049e8:	2204b783          	ld	a5,544(s1)
    800049ec:	eb95                	bnez	a5,80004a20 <pipeclose+0x64>
    release(&pi->lock);
    800049ee:	8526                	mv	a0,s1
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	286080e7          	jalr	646(ra) # 80000c76 <release>
    kfree((char*)pi);
    800049f8:	8526                	mv	a0,s1
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	fdc080e7          	jalr	-36(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004a02:	60e2                	ld	ra,24(sp)
    80004a04:	6442                	ld	s0,16(sp)
    80004a06:	64a2                	ld	s1,8(sp)
    80004a08:	6902                	ld	s2,0(sp)
    80004a0a:	6105                	addi	sp,sp,32
    80004a0c:	8082                	ret
    pi->readopen = 0;
    80004a0e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a12:	21c48513          	addi	a0,s1,540
    80004a16:	ffffd097          	auipc	ra,0xffffd
    80004a1a:	7c0080e7          	jalr	1984(ra) # 800021d6 <wakeup>
    80004a1e:	b7e9                	j	800049e8 <pipeclose+0x2c>
    release(&pi->lock);
    80004a20:	8526                	mv	a0,s1
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	254080e7          	jalr	596(ra) # 80000c76 <release>
}
    80004a2a:	bfe1                	j	80004a02 <pipeclose+0x46>

0000000080004a2c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a2c:	711d                	addi	sp,sp,-96
    80004a2e:	ec86                	sd	ra,88(sp)
    80004a30:	e8a2                	sd	s0,80(sp)
    80004a32:	e4a6                	sd	s1,72(sp)
    80004a34:	e0ca                	sd	s2,64(sp)
    80004a36:	fc4e                	sd	s3,56(sp)
    80004a38:	f852                	sd	s4,48(sp)
    80004a3a:	f456                	sd	s5,40(sp)
    80004a3c:	f05a                	sd	s6,32(sp)
    80004a3e:	ec5e                	sd	s7,24(sp)
    80004a40:	e862                	sd	s8,16(sp)
    80004a42:	1080                	addi	s0,sp,96
    80004a44:	84aa                	mv	s1,a0
    80004a46:	8aae                	mv	s5,a1
    80004a48:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a4a:	ffffd097          	auipc	ra,0xffffd
    80004a4e:	f34080e7          	jalr	-204(ra) # 8000197e <myproc>
    80004a52:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a54:	8526                	mv	a0,s1
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	16c080e7          	jalr	364(ra) # 80000bc2 <acquire>
  while(i < n){
    80004a5e:	0b405363          	blez	s4,80004b04 <pipewrite+0xd8>
  int i = 0;
    80004a62:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a64:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a66:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a6a:	21c48b93          	addi	s7,s1,540
    80004a6e:	a089                	j	80004ab0 <pipewrite+0x84>
      release(&pi->lock);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	204080e7          	jalr	516(ra) # 80000c76 <release>
      return -1;
    80004a7a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a7c:	854a                	mv	a0,s2
    80004a7e:	60e6                	ld	ra,88(sp)
    80004a80:	6446                	ld	s0,80(sp)
    80004a82:	64a6                	ld	s1,72(sp)
    80004a84:	6906                	ld	s2,64(sp)
    80004a86:	79e2                	ld	s3,56(sp)
    80004a88:	7a42                	ld	s4,48(sp)
    80004a8a:	7aa2                	ld	s5,40(sp)
    80004a8c:	7b02                	ld	s6,32(sp)
    80004a8e:	6be2                	ld	s7,24(sp)
    80004a90:	6c42                	ld	s8,16(sp)
    80004a92:	6125                	addi	sp,sp,96
    80004a94:	8082                	ret
      wakeup(&pi->nread);
    80004a96:	8562                	mv	a0,s8
    80004a98:	ffffd097          	auipc	ra,0xffffd
    80004a9c:	73e080e7          	jalr	1854(ra) # 800021d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004aa0:	85a6                	mv	a1,s1
    80004aa2:	855e                	mv	a0,s7
    80004aa4:	ffffd097          	auipc	ra,0xffffd
    80004aa8:	5a6080e7          	jalr	1446(ra) # 8000204a <sleep>
  while(i < n){
    80004aac:	05495d63          	bge	s2,s4,80004b06 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004ab0:	2204a783          	lw	a5,544(s1)
    80004ab4:	dfd5                	beqz	a5,80004a70 <pipewrite+0x44>
    80004ab6:	0289a783          	lw	a5,40(s3)
    80004aba:	fbdd                	bnez	a5,80004a70 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004abc:	2184a783          	lw	a5,536(s1)
    80004ac0:	21c4a703          	lw	a4,540(s1)
    80004ac4:	2007879b          	addiw	a5,a5,512
    80004ac8:	fcf707e3          	beq	a4,a5,80004a96 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004acc:	4685                	li	a3,1
    80004ace:	01590633          	add	a2,s2,s5
    80004ad2:	faf40593          	addi	a1,s0,-81
    80004ad6:	0509b503          	ld	a0,80(s3)
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	bf0080e7          	jalr	-1040(ra) # 800016ca <copyin>
    80004ae2:	03650263          	beq	a0,s6,80004b06 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ae6:	21c4a783          	lw	a5,540(s1)
    80004aea:	0017871b          	addiw	a4,a5,1
    80004aee:	20e4ae23          	sw	a4,540(s1)
    80004af2:	1ff7f793          	andi	a5,a5,511
    80004af6:	97a6                	add	a5,a5,s1
    80004af8:	faf44703          	lbu	a4,-81(s0)
    80004afc:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b00:	2905                	addiw	s2,s2,1
    80004b02:	b76d                	j	80004aac <pipewrite+0x80>
  int i = 0;
    80004b04:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b06:	21848513          	addi	a0,s1,536
    80004b0a:	ffffd097          	auipc	ra,0xffffd
    80004b0e:	6cc080e7          	jalr	1740(ra) # 800021d6 <wakeup>
  release(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	162080e7          	jalr	354(ra) # 80000c76 <release>
  return i;
    80004b1c:	b785                	j	80004a7c <pipewrite+0x50>

0000000080004b1e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b1e:	715d                	addi	sp,sp,-80
    80004b20:	e486                	sd	ra,72(sp)
    80004b22:	e0a2                	sd	s0,64(sp)
    80004b24:	fc26                	sd	s1,56(sp)
    80004b26:	f84a                	sd	s2,48(sp)
    80004b28:	f44e                	sd	s3,40(sp)
    80004b2a:	f052                	sd	s4,32(sp)
    80004b2c:	ec56                	sd	s5,24(sp)
    80004b2e:	e85a                	sd	s6,16(sp)
    80004b30:	0880                	addi	s0,sp,80
    80004b32:	84aa                	mv	s1,a0
    80004b34:	892e                	mv	s2,a1
    80004b36:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	e46080e7          	jalr	-442(ra) # 8000197e <myproc>
    80004b40:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	07e080e7          	jalr	126(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b4c:	2184a703          	lw	a4,536(s1)
    80004b50:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b54:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b58:	02f71463          	bne	a4,a5,80004b80 <piperead+0x62>
    80004b5c:	2244a783          	lw	a5,548(s1)
    80004b60:	c385                	beqz	a5,80004b80 <piperead+0x62>
    if(pr->killed){
    80004b62:	028a2783          	lw	a5,40(s4)
    80004b66:	ebc1                	bnez	a5,80004bf6 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b68:	85a6                	mv	a1,s1
    80004b6a:	854e                	mv	a0,s3
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	4de080e7          	jalr	1246(ra) # 8000204a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b74:	2184a703          	lw	a4,536(s1)
    80004b78:	21c4a783          	lw	a5,540(s1)
    80004b7c:	fef700e3          	beq	a4,a5,80004b5c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b80:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b82:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b84:	05505363          	blez	s5,80004bca <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b88:	2184a783          	lw	a5,536(s1)
    80004b8c:	21c4a703          	lw	a4,540(s1)
    80004b90:	02f70d63          	beq	a4,a5,80004bca <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b94:	0017871b          	addiw	a4,a5,1
    80004b98:	20e4ac23          	sw	a4,536(s1)
    80004b9c:	1ff7f793          	andi	a5,a5,511
    80004ba0:	97a6                	add	a5,a5,s1
    80004ba2:	0187c783          	lbu	a5,24(a5)
    80004ba6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004baa:	4685                	li	a3,1
    80004bac:	fbf40613          	addi	a2,s0,-65
    80004bb0:	85ca                	mv	a1,s2
    80004bb2:	050a3503          	ld	a0,80(s4)
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	a88080e7          	jalr	-1400(ra) # 8000163e <copyout>
    80004bbe:	01650663          	beq	a0,s6,80004bca <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc2:	2985                	addiw	s3,s3,1
    80004bc4:	0905                	addi	s2,s2,1
    80004bc6:	fd3a91e3          	bne	s5,s3,80004b88 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bca:	21c48513          	addi	a0,s1,540
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	608080e7          	jalr	1544(ra) # 800021d6 <wakeup>
  release(&pi->lock);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	09e080e7          	jalr	158(ra) # 80000c76 <release>
  return i;
}
    80004be0:	854e                	mv	a0,s3
    80004be2:	60a6                	ld	ra,72(sp)
    80004be4:	6406                	ld	s0,64(sp)
    80004be6:	74e2                	ld	s1,56(sp)
    80004be8:	7942                	ld	s2,48(sp)
    80004bea:	79a2                	ld	s3,40(sp)
    80004bec:	7a02                	ld	s4,32(sp)
    80004bee:	6ae2                	ld	s5,24(sp)
    80004bf0:	6b42                	ld	s6,16(sp)
    80004bf2:	6161                	addi	sp,sp,80
    80004bf4:	8082                	ret
      release(&pi->lock);
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	07e080e7          	jalr	126(ra) # 80000c76 <release>
      return -1;
    80004c00:	59fd                	li	s3,-1
    80004c02:	bff9                	j	80004be0 <piperead+0xc2>

0000000080004c04 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c04:	de010113          	addi	sp,sp,-544
    80004c08:	20113c23          	sd	ra,536(sp)
    80004c0c:	20813823          	sd	s0,528(sp)
    80004c10:	20913423          	sd	s1,520(sp)
    80004c14:	21213023          	sd	s2,512(sp)
    80004c18:	ffce                	sd	s3,504(sp)
    80004c1a:	fbd2                	sd	s4,496(sp)
    80004c1c:	f7d6                	sd	s5,488(sp)
    80004c1e:	f3da                	sd	s6,480(sp)
    80004c20:	efde                	sd	s7,472(sp)
    80004c22:	ebe2                	sd	s8,464(sp)
    80004c24:	e7e6                	sd	s9,456(sp)
    80004c26:	e3ea                	sd	s10,448(sp)
    80004c28:	ff6e                	sd	s11,440(sp)
    80004c2a:	1400                	addi	s0,sp,544
    80004c2c:	892a                	mv	s2,a0
    80004c2e:	dea43423          	sd	a0,-536(s0)
    80004c32:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c36:	ffffd097          	auipc	ra,0xffffd
    80004c3a:	d48080e7          	jalr	-696(ra) # 8000197e <myproc>
    80004c3e:	84aa                	mv	s1,a0

  begin_op();
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	4a6080e7          	jalr	1190(ra) # 800040e6 <begin_op>

  if((ip = namei(path)) == 0){
    80004c48:	854a                	mv	a0,s2
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	27c080e7          	jalr	636(ra) # 80003ec6 <namei>
    80004c52:	c93d                	beqz	a0,80004cc8 <exec+0xc4>
    80004c54:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	aba080e7          	jalr	-1350(ra) # 80003710 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c5e:	04000713          	li	a4,64
    80004c62:	4681                	li	a3,0
    80004c64:	e4840613          	addi	a2,s0,-440
    80004c68:	4581                	li	a1,0
    80004c6a:	8556                	mv	a0,s5
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	d58080e7          	jalr	-680(ra) # 800039c4 <readi>
    80004c74:	04000793          	li	a5,64
    80004c78:	00f51a63          	bne	a0,a5,80004c8c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c7c:	e4842703          	lw	a4,-440(s0)
    80004c80:	464c47b7          	lui	a5,0x464c4
    80004c84:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c88:	04f70663          	beq	a4,a5,80004cd4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c8c:	8556                	mv	a0,s5
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	ce4080e7          	jalr	-796(ra) # 80003972 <iunlockput>
    end_op();
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	4d0080e7          	jalr	1232(ra) # 80004166 <end_op>
  }
  return -1;
    80004c9e:	557d                	li	a0,-1
}
    80004ca0:	21813083          	ld	ra,536(sp)
    80004ca4:	21013403          	ld	s0,528(sp)
    80004ca8:	20813483          	ld	s1,520(sp)
    80004cac:	20013903          	ld	s2,512(sp)
    80004cb0:	79fe                	ld	s3,504(sp)
    80004cb2:	7a5e                	ld	s4,496(sp)
    80004cb4:	7abe                	ld	s5,488(sp)
    80004cb6:	7b1e                	ld	s6,480(sp)
    80004cb8:	6bfe                	ld	s7,472(sp)
    80004cba:	6c5e                	ld	s8,464(sp)
    80004cbc:	6cbe                	ld	s9,456(sp)
    80004cbe:	6d1e                	ld	s10,448(sp)
    80004cc0:	7dfa                	ld	s11,440(sp)
    80004cc2:	22010113          	addi	sp,sp,544
    80004cc6:	8082                	ret
    end_op();
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	49e080e7          	jalr	1182(ra) # 80004166 <end_op>
    return -1;
    80004cd0:	557d                	li	a0,-1
    80004cd2:	b7f9                	j	80004ca0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	d6c080e7          	jalr	-660(ra) # 80001a42 <proc_pagetable>
    80004cde:	8b2a                	mv	s6,a0
    80004ce0:	d555                	beqz	a0,80004c8c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ce2:	e6842783          	lw	a5,-408(s0)
    80004ce6:	e8045703          	lhu	a4,-384(s0)
    80004cea:	c735                	beqz	a4,80004d56 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cec:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cee:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cf2:	6a05                	lui	s4,0x1
    80004cf4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cf8:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004cfc:	6d85                	lui	s11,0x1
    80004cfe:	7d7d                	lui	s10,0xfffff
    80004d00:	ac1d                	j	80004f36 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d02:	00004517          	auipc	a0,0x4
    80004d06:	aae50513          	addi	a0,a0,-1362 # 800087b0 <syscalls+0x280>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	820080e7          	jalr	-2016(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d12:	874a                	mv	a4,s2
    80004d14:	009c86bb          	addw	a3,s9,s1
    80004d18:	4581                	li	a1,0
    80004d1a:	8556                	mv	a0,s5
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	ca8080e7          	jalr	-856(ra) # 800039c4 <readi>
    80004d24:	2501                	sext.w	a0,a0
    80004d26:	1aa91863          	bne	s2,a0,80004ed6 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d2a:	009d84bb          	addw	s1,s11,s1
    80004d2e:	013d09bb          	addw	s3,s10,s3
    80004d32:	1f74f263          	bgeu	s1,s7,80004f16 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d36:	02049593          	slli	a1,s1,0x20
    80004d3a:	9181                	srli	a1,a1,0x20
    80004d3c:	95e2                	add	a1,a1,s8
    80004d3e:	855a                	mv	a0,s6
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	30c080e7          	jalr	780(ra) # 8000104c <walkaddr>
    80004d48:	862a                	mv	a2,a0
    if(pa == 0)
    80004d4a:	dd45                	beqz	a0,80004d02 <exec+0xfe>
      n = PGSIZE;
    80004d4c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d4e:	fd49f2e3          	bgeu	s3,s4,80004d12 <exec+0x10e>
      n = sz - i;
    80004d52:	894e                	mv	s2,s3
    80004d54:	bf7d                	j	80004d12 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d56:	4481                	li	s1,0
  iunlockput(ip);
    80004d58:	8556                	mv	a0,s5
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	c18080e7          	jalr	-1000(ra) # 80003972 <iunlockput>
  end_op();
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	404080e7          	jalr	1028(ra) # 80004166 <end_op>
  p = myproc();
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	c14080e7          	jalr	-1004(ra) # 8000197e <myproc>
    80004d72:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d74:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d78:	6785                	lui	a5,0x1
    80004d7a:	17fd                	addi	a5,a5,-1
    80004d7c:	94be                	add	s1,s1,a5
    80004d7e:	77fd                	lui	a5,0xfffff
    80004d80:	8fe5                	and	a5,a5,s1
    80004d82:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d86:	6609                	lui	a2,0x2
    80004d88:	963e                	add	a2,a2,a5
    80004d8a:	85be                	mv	a1,a5
    80004d8c:	855a                	mv	a0,s6
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	660080e7          	jalr	1632(ra) # 800013ee <uvmalloc>
    80004d96:	8c2a                	mv	s8,a0
  ip = 0;
    80004d98:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d9a:	12050e63          	beqz	a0,80004ed6 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d9e:	75f9                	lui	a1,0xffffe
    80004da0:	95aa                	add	a1,a1,a0
    80004da2:	855a                	mv	a0,s6
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	868080e7          	jalr	-1944(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004dac:	7afd                	lui	s5,0xfffff
    80004dae:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004db0:	df043783          	ld	a5,-528(s0)
    80004db4:	6388                	ld	a0,0(a5)
    80004db6:	c925                	beqz	a0,80004e26 <exec+0x222>
    80004db8:	e8840993          	addi	s3,s0,-376
    80004dbc:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004dc0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dc2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	07e080e7          	jalr	126(ra) # 80000e42 <strlen>
    80004dcc:	0015079b          	addiw	a5,a0,1
    80004dd0:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dd4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dd8:	13596363          	bltu	s2,s5,80004efe <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ddc:	df043d83          	ld	s11,-528(s0)
    80004de0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004de4:	8552                	mv	a0,s4
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	05c080e7          	jalr	92(ra) # 80000e42 <strlen>
    80004dee:	0015069b          	addiw	a3,a0,1
    80004df2:	8652                	mv	a2,s4
    80004df4:	85ca                	mv	a1,s2
    80004df6:	855a                	mv	a0,s6
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	846080e7          	jalr	-1978(ra) # 8000163e <copyout>
    80004e00:	10054363          	bltz	a0,80004f06 <exec+0x302>
    ustack[argc] = sp;
    80004e04:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e08:	0485                	addi	s1,s1,1
    80004e0a:	008d8793          	addi	a5,s11,8
    80004e0e:	def43823          	sd	a5,-528(s0)
    80004e12:	008db503          	ld	a0,8(s11)
    80004e16:	c911                	beqz	a0,80004e2a <exec+0x226>
    if(argc >= MAXARG)
    80004e18:	09a1                	addi	s3,s3,8
    80004e1a:	fb3c95e3          	bne	s9,s3,80004dc4 <exec+0x1c0>
  sz = sz1;
    80004e1e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e22:	4a81                	li	s5,0
    80004e24:	a84d                	j	80004ed6 <exec+0x2d2>
  sp = sz;
    80004e26:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e28:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e2a:	00349793          	slli	a5,s1,0x3
    80004e2e:	f9040713          	addi	a4,s0,-112
    80004e32:	97ba                	add	a5,a5,a4
    80004e34:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004e38:	00148693          	addi	a3,s1,1
    80004e3c:	068e                	slli	a3,a3,0x3
    80004e3e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e42:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e46:	01597663          	bgeu	s2,s5,80004e52 <exec+0x24e>
  sz = sz1;
    80004e4a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e4e:	4a81                	li	s5,0
    80004e50:	a059                	j	80004ed6 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e52:	e8840613          	addi	a2,s0,-376
    80004e56:	85ca                	mv	a1,s2
    80004e58:	855a                	mv	a0,s6
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	7e4080e7          	jalr	2020(ra) # 8000163e <copyout>
    80004e62:	0a054663          	bltz	a0,80004f0e <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e66:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e6a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e6e:	de843783          	ld	a5,-536(s0)
    80004e72:	0007c703          	lbu	a4,0(a5)
    80004e76:	cf11                	beqz	a4,80004e92 <exec+0x28e>
    80004e78:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e7a:	02f00693          	li	a3,47
    80004e7e:	a039                	j	80004e8c <exec+0x288>
      last = s+1;
    80004e80:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e84:	0785                	addi	a5,a5,1
    80004e86:	fff7c703          	lbu	a4,-1(a5)
    80004e8a:	c701                	beqz	a4,80004e92 <exec+0x28e>
    if(*s == '/')
    80004e8c:	fed71ce3          	bne	a4,a3,80004e84 <exec+0x280>
    80004e90:	bfc5                	j	80004e80 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e92:	4641                	li	a2,16
    80004e94:	de843583          	ld	a1,-536(s0)
    80004e98:	158b8513          	addi	a0,s7,344
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	f74080e7          	jalr	-140(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ea4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ea8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004eac:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004eb0:	058bb783          	ld	a5,88(s7)
    80004eb4:	e6043703          	ld	a4,-416(s0)
    80004eb8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004eba:	058bb783          	ld	a5,88(s7)
    80004ebe:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ec2:	85ea                	mv	a1,s10
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	c1a080e7          	jalr	-998(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ecc:	0004851b          	sext.w	a0,s1
    80004ed0:	bbc1                	j	80004ca0 <exec+0x9c>
    80004ed2:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ed6:	df843583          	ld	a1,-520(s0)
    80004eda:	855a                	mv	a0,s6
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	c02080e7          	jalr	-1022(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80004ee4:	da0a94e3          	bnez	s5,80004c8c <exec+0x88>
  return -1;
    80004ee8:	557d                	li	a0,-1
    80004eea:	bb5d                	j	80004ca0 <exec+0x9c>
    80004eec:	de943c23          	sd	s1,-520(s0)
    80004ef0:	b7dd                	j	80004ed6 <exec+0x2d2>
    80004ef2:	de943c23          	sd	s1,-520(s0)
    80004ef6:	b7c5                	j	80004ed6 <exec+0x2d2>
    80004ef8:	de943c23          	sd	s1,-520(s0)
    80004efc:	bfe9                	j	80004ed6 <exec+0x2d2>
  sz = sz1;
    80004efe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f02:	4a81                	li	s5,0
    80004f04:	bfc9                	j	80004ed6 <exec+0x2d2>
  sz = sz1;
    80004f06:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f0a:	4a81                	li	s5,0
    80004f0c:	b7e9                	j	80004ed6 <exec+0x2d2>
  sz = sz1;
    80004f0e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f12:	4a81                	li	s5,0
    80004f14:	b7c9                	j	80004ed6 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f16:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f1a:	e0843783          	ld	a5,-504(s0)
    80004f1e:	0017869b          	addiw	a3,a5,1
    80004f22:	e0d43423          	sd	a3,-504(s0)
    80004f26:	e0043783          	ld	a5,-512(s0)
    80004f2a:	0387879b          	addiw	a5,a5,56
    80004f2e:	e8045703          	lhu	a4,-384(s0)
    80004f32:	e2e6d3e3          	bge	a3,a4,80004d58 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f36:	2781                	sext.w	a5,a5
    80004f38:	e0f43023          	sd	a5,-512(s0)
    80004f3c:	03800713          	li	a4,56
    80004f40:	86be                	mv	a3,a5
    80004f42:	e1040613          	addi	a2,s0,-496
    80004f46:	4581                	li	a1,0
    80004f48:	8556                	mv	a0,s5
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	a7a080e7          	jalr	-1414(ra) # 800039c4 <readi>
    80004f52:	03800793          	li	a5,56
    80004f56:	f6f51ee3          	bne	a0,a5,80004ed2 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f5a:	e1042783          	lw	a5,-496(s0)
    80004f5e:	4705                	li	a4,1
    80004f60:	fae79de3          	bne	a5,a4,80004f1a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f64:	e3843603          	ld	a2,-456(s0)
    80004f68:	e3043783          	ld	a5,-464(s0)
    80004f6c:	f8f660e3          	bltu	a2,a5,80004eec <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f70:	e2043783          	ld	a5,-480(s0)
    80004f74:	963e                	add	a2,a2,a5
    80004f76:	f6f66ee3          	bltu	a2,a5,80004ef2 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f7a:	85a6                	mv	a1,s1
    80004f7c:	855a                	mv	a0,s6
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	470080e7          	jalr	1136(ra) # 800013ee <uvmalloc>
    80004f86:	dea43c23          	sd	a0,-520(s0)
    80004f8a:	d53d                	beqz	a0,80004ef8 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f8c:	e2043c03          	ld	s8,-480(s0)
    80004f90:	de043783          	ld	a5,-544(s0)
    80004f94:	00fc77b3          	and	a5,s8,a5
    80004f98:	ff9d                	bnez	a5,80004ed6 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f9a:	e1842c83          	lw	s9,-488(s0)
    80004f9e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fa2:	f60b8ae3          	beqz	s7,80004f16 <exec+0x312>
    80004fa6:	89de                	mv	s3,s7
    80004fa8:	4481                	li	s1,0
    80004faa:	b371                	j	80004d36 <exec+0x132>

0000000080004fac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fac:	7179                	addi	sp,sp,-48
    80004fae:	f406                	sd	ra,40(sp)
    80004fb0:	f022                	sd	s0,32(sp)
    80004fb2:	ec26                	sd	s1,24(sp)
    80004fb4:	e84a                	sd	s2,16(sp)
    80004fb6:	1800                	addi	s0,sp,48
    80004fb8:	892e                	mv	s2,a1
    80004fba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fbc:	fdc40593          	addi	a1,s0,-36
    80004fc0:	ffffe097          	auipc	ra,0xffffe
    80004fc4:	ada080e7          	jalr	-1318(ra) # 80002a9a <argint>
    80004fc8:	04054063          	bltz	a0,80005008 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fcc:	fdc42703          	lw	a4,-36(s0)
    80004fd0:	47bd                	li	a5,15
    80004fd2:	02e7ed63          	bltu	a5,a4,8000500c <argfd+0x60>
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	9a8080e7          	jalr	-1624(ra) # 8000197e <myproc>
    80004fde:	fdc42703          	lw	a4,-36(s0)
    80004fe2:	01a70793          	addi	a5,a4,26
    80004fe6:	078e                	slli	a5,a5,0x3
    80004fe8:	953e                	add	a0,a0,a5
    80004fea:	611c                	ld	a5,0(a0)
    80004fec:	c395                	beqz	a5,80005010 <argfd+0x64>
    return -1;
  if(pfd)
    80004fee:	00090463          	beqz	s2,80004ff6 <argfd+0x4a>
    *pfd = fd;
    80004ff2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ff6:	4501                	li	a0,0
  if(pf)
    80004ff8:	c091                	beqz	s1,80004ffc <argfd+0x50>
    *pf = f;
    80004ffa:	e09c                	sd	a5,0(s1)
}
    80004ffc:	70a2                	ld	ra,40(sp)
    80004ffe:	7402                	ld	s0,32(sp)
    80005000:	64e2                	ld	s1,24(sp)
    80005002:	6942                	ld	s2,16(sp)
    80005004:	6145                	addi	sp,sp,48
    80005006:	8082                	ret
    return -1;
    80005008:	557d                	li	a0,-1
    8000500a:	bfcd                	j	80004ffc <argfd+0x50>
    return -1;
    8000500c:	557d                	li	a0,-1
    8000500e:	b7fd                	j	80004ffc <argfd+0x50>
    80005010:	557d                	li	a0,-1
    80005012:	b7ed                	j	80004ffc <argfd+0x50>

0000000080005014 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005014:	1101                	addi	sp,sp,-32
    80005016:	ec06                	sd	ra,24(sp)
    80005018:	e822                	sd	s0,16(sp)
    8000501a:	e426                	sd	s1,8(sp)
    8000501c:	1000                	addi	s0,sp,32
    8000501e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	95e080e7          	jalr	-1698(ra) # 8000197e <myproc>
    80005028:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000502a:	0d050793          	addi	a5,a0,208
    8000502e:	4501                	li	a0,0
    80005030:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005032:	6398                	ld	a4,0(a5)
    80005034:	cb19                	beqz	a4,8000504a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005036:	2505                	addiw	a0,a0,1
    80005038:	07a1                	addi	a5,a5,8
    8000503a:	fed51ce3          	bne	a0,a3,80005032 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000503e:	557d                	li	a0,-1
}
    80005040:	60e2                	ld	ra,24(sp)
    80005042:	6442                	ld	s0,16(sp)
    80005044:	64a2                	ld	s1,8(sp)
    80005046:	6105                	addi	sp,sp,32
    80005048:	8082                	ret
      p->ofile[fd] = f;
    8000504a:	01a50793          	addi	a5,a0,26
    8000504e:	078e                	slli	a5,a5,0x3
    80005050:	963e                	add	a2,a2,a5
    80005052:	e204                	sd	s1,0(a2)
      return fd;
    80005054:	b7f5                	j	80005040 <fdalloc+0x2c>

0000000080005056 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005056:	715d                	addi	sp,sp,-80
    80005058:	e486                	sd	ra,72(sp)
    8000505a:	e0a2                	sd	s0,64(sp)
    8000505c:	fc26                	sd	s1,56(sp)
    8000505e:	f84a                	sd	s2,48(sp)
    80005060:	f44e                	sd	s3,40(sp)
    80005062:	f052                	sd	s4,32(sp)
    80005064:	ec56                	sd	s5,24(sp)
    80005066:	0880                	addi	s0,sp,80
    80005068:	89ae                	mv	s3,a1
    8000506a:	8ab2                	mv	s5,a2
    8000506c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000506e:	fb040593          	addi	a1,s0,-80
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	e72080e7          	jalr	-398(ra) # 80003ee4 <nameiparent>
    8000507a:	892a                	mv	s2,a0
    8000507c:	12050e63          	beqz	a0,800051b8 <create+0x162>
    return 0;

  ilock(dp);
    80005080:	ffffe097          	auipc	ra,0xffffe
    80005084:	690080e7          	jalr	1680(ra) # 80003710 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005088:	4601                	li	a2,0
    8000508a:	fb040593          	addi	a1,s0,-80
    8000508e:	854a                	mv	a0,s2
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	b64080e7          	jalr	-1180(ra) # 80003bf4 <dirlookup>
    80005098:	84aa                	mv	s1,a0
    8000509a:	c921                	beqz	a0,800050ea <create+0x94>
    iunlockput(dp);
    8000509c:	854a                	mv	a0,s2
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	8d4080e7          	jalr	-1836(ra) # 80003972 <iunlockput>
    ilock(ip);
    800050a6:	8526                	mv	a0,s1
    800050a8:	ffffe097          	auipc	ra,0xffffe
    800050ac:	668080e7          	jalr	1640(ra) # 80003710 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050b0:	2981                	sext.w	s3,s3
    800050b2:	4789                	li	a5,2
    800050b4:	02f99463          	bne	s3,a5,800050dc <create+0x86>
    800050b8:	0444d783          	lhu	a5,68(s1)
    800050bc:	37f9                	addiw	a5,a5,-2
    800050be:	17c2                	slli	a5,a5,0x30
    800050c0:	93c1                	srli	a5,a5,0x30
    800050c2:	4705                	li	a4,1
    800050c4:	00f76c63          	bltu	a4,a5,800050dc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050c8:	8526                	mv	a0,s1
    800050ca:	60a6                	ld	ra,72(sp)
    800050cc:	6406                	ld	s0,64(sp)
    800050ce:	74e2                	ld	s1,56(sp)
    800050d0:	7942                	ld	s2,48(sp)
    800050d2:	79a2                	ld	s3,40(sp)
    800050d4:	7a02                	ld	s4,32(sp)
    800050d6:	6ae2                	ld	s5,24(sp)
    800050d8:	6161                	addi	sp,sp,80
    800050da:	8082                	ret
    iunlockput(ip);
    800050dc:	8526                	mv	a0,s1
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	894080e7          	jalr	-1900(ra) # 80003972 <iunlockput>
    return 0;
    800050e6:	4481                	li	s1,0
    800050e8:	b7c5                	j	800050c8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050ea:	85ce                	mv	a1,s3
    800050ec:	00092503          	lw	a0,0(s2)
    800050f0:	ffffe097          	auipc	ra,0xffffe
    800050f4:	488080e7          	jalr	1160(ra) # 80003578 <ialloc>
    800050f8:	84aa                	mv	s1,a0
    800050fa:	c521                	beqz	a0,80005142 <create+0xec>
  ilock(ip);
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	614080e7          	jalr	1556(ra) # 80003710 <ilock>
  ip->major = major;
    80005104:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005108:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000510c:	4a05                	li	s4,1
    8000510e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005112:	8526                	mv	a0,s1
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	532080e7          	jalr	1330(ra) # 80003646 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000511c:	2981                	sext.w	s3,s3
    8000511e:	03498a63          	beq	s3,s4,80005152 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005122:	40d0                	lw	a2,4(s1)
    80005124:	fb040593          	addi	a1,s0,-80
    80005128:	854a                	mv	a0,s2
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	cda080e7          	jalr	-806(ra) # 80003e04 <dirlink>
    80005132:	06054b63          	bltz	a0,800051a8 <create+0x152>
  iunlockput(dp);
    80005136:	854a                	mv	a0,s2
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	83a080e7          	jalr	-1990(ra) # 80003972 <iunlockput>
  return ip;
    80005140:	b761                	j	800050c8 <create+0x72>
    panic("create: ialloc");
    80005142:	00003517          	auipc	a0,0x3
    80005146:	68e50513          	addi	a0,a0,1678 # 800087d0 <syscalls+0x2a0>
    8000514a:	ffffb097          	auipc	ra,0xffffb
    8000514e:	3e0080e7          	jalr	992(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005152:	04a95783          	lhu	a5,74(s2)
    80005156:	2785                	addiw	a5,a5,1
    80005158:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000515c:	854a                	mv	a0,s2
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	4e8080e7          	jalr	1256(ra) # 80003646 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005166:	40d0                	lw	a2,4(s1)
    80005168:	00003597          	auipc	a1,0x3
    8000516c:	67858593          	addi	a1,a1,1656 # 800087e0 <syscalls+0x2b0>
    80005170:	8526                	mv	a0,s1
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	c92080e7          	jalr	-878(ra) # 80003e04 <dirlink>
    8000517a:	00054f63          	bltz	a0,80005198 <create+0x142>
    8000517e:	00492603          	lw	a2,4(s2)
    80005182:	00003597          	auipc	a1,0x3
    80005186:	66658593          	addi	a1,a1,1638 # 800087e8 <syscalls+0x2b8>
    8000518a:	8526                	mv	a0,s1
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	c78080e7          	jalr	-904(ra) # 80003e04 <dirlink>
    80005194:	f80557e3          	bgez	a0,80005122 <create+0xcc>
      panic("create dots");
    80005198:	00003517          	auipc	a0,0x3
    8000519c:	65850513          	addi	a0,a0,1624 # 800087f0 <syscalls+0x2c0>
    800051a0:	ffffb097          	auipc	ra,0xffffb
    800051a4:	38a080e7          	jalr	906(ra) # 8000052a <panic>
    panic("create: dirlink");
    800051a8:	00003517          	auipc	a0,0x3
    800051ac:	65850513          	addi	a0,a0,1624 # 80008800 <syscalls+0x2d0>
    800051b0:	ffffb097          	auipc	ra,0xffffb
    800051b4:	37a080e7          	jalr	890(ra) # 8000052a <panic>
    return 0;
    800051b8:	84aa                	mv	s1,a0
    800051ba:	b739                	j	800050c8 <create+0x72>

00000000800051bc <sys_dup>:
{
    800051bc:	7179                	addi	sp,sp,-48
    800051be:	f406                	sd	ra,40(sp)
    800051c0:	f022                	sd	s0,32(sp)
    800051c2:	ec26                	sd	s1,24(sp)
    800051c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051c6:	fd840613          	addi	a2,s0,-40
    800051ca:	4581                	li	a1,0
    800051cc:	4501                	li	a0,0
    800051ce:	00000097          	auipc	ra,0x0
    800051d2:	dde080e7          	jalr	-546(ra) # 80004fac <argfd>
    return -1;
    800051d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051d8:	02054363          	bltz	a0,800051fe <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051dc:	fd843503          	ld	a0,-40(s0)
    800051e0:	00000097          	auipc	ra,0x0
    800051e4:	e34080e7          	jalr	-460(ra) # 80005014 <fdalloc>
    800051e8:	84aa                	mv	s1,a0
    return -1;
    800051ea:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051ec:	00054963          	bltz	a0,800051fe <sys_dup+0x42>
  filedup(f);
    800051f0:	fd843503          	ld	a0,-40(s0)
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	36c080e7          	jalr	876(ra) # 80004560 <filedup>
  return fd;
    800051fc:	87a6                	mv	a5,s1
}
    800051fe:	853e                	mv	a0,a5
    80005200:	70a2                	ld	ra,40(sp)
    80005202:	7402                	ld	s0,32(sp)
    80005204:	64e2                	ld	s1,24(sp)
    80005206:	6145                	addi	sp,sp,48
    80005208:	8082                	ret

000000008000520a <sys_read>:
{
    8000520a:	7179                	addi	sp,sp,-48
    8000520c:	f406                	sd	ra,40(sp)
    8000520e:	f022                	sd	s0,32(sp)
    80005210:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005212:	fe840613          	addi	a2,s0,-24
    80005216:	4581                	li	a1,0
    80005218:	4501                	li	a0,0
    8000521a:	00000097          	auipc	ra,0x0
    8000521e:	d92080e7          	jalr	-622(ra) # 80004fac <argfd>
    return -1;
    80005222:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005224:	04054163          	bltz	a0,80005266 <sys_read+0x5c>
    80005228:	fe440593          	addi	a1,s0,-28
    8000522c:	4509                	li	a0,2
    8000522e:	ffffe097          	auipc	ra,0xffffe
    80005232:	86c080e7          	jalr	-1940(ra) # 80002a9a <argint>
    return -1;
    80005236:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005238:	02054763          	bltz	a0,80005266 <sys_read+0x5c>
    8000523c:	fd840593          	addi	a1,s0,-40
    80005240:	4505                	li	a0,1
    80005242:	ffffe097          	auipc	ra,0xffffe
    80005246:	87a080e7          	jalr	-1926(ra) # 80002abc <argaddr>
    return -1;
    8000524a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524c:	00054d63          	bltz	a0,80005266 <sys_read+0x5c>
  return fileread(f, p, n);
    80005250:	fe442603          	lw	a2,-28(s0)
    80005254:	fd843583          	ld	a1,-40(s0)
    80005258:	fe843503          	ld	a0,-24(s0)
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	490080e7          	jalr	1168(ra) # 800046ec <fileread>
    80005264:	87aa                	mv	a5,a0
}
    80005266:	853e                	mv	a0,a5
    80005268:	70a2                	ld	ra,40(sp)
    8000526a:	7402                	ld	s0,32(sp)
    8000526c:	6145                	addi	sp,sp,48
    8000526e:	8082                	ret

0000000080005270 <sys_write>:
{
    80005270:	7179                	addi	sp,sp,-48
    80005272:	f406                	sd	ra,40(sp)
    80005274:	f022                	sd	s0,32(sp)
    80005276:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005278:	fe840613          	addi	a2,s0,-24
    8000527c:	4581                	li	a1,0
    8000527e:	4501                	li	a0,0
    80005280:	00000097          	auipc	ra,0x0
    80005284:	d2c080e7          	jalr	-724(ra) # 80004fac <argfd>
    return -1;
    80005288:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528a:	04054163          	bltz	a0,800052cc <sys_write+0x5c>
    8000528e:	fe440593          	addi	a1,s0,-28
    80005292:	4509                	li	a0,2
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	806080e7          	jalr	-2042(ra) # 80002a9a <argint>
    return -1;
    8000529c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529e:	02054763          	bltz	a0,800052cc <sys_write+0x5c>
    800052a2:	fd840593          	addi	a1,s0,-40
    800052a6:	4505                	li	a0,1
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	814080e7          	jalr	-2028(ra) # 80002abc <argaddr>
    return -1;
    800052b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b2:	00054d63          	bltz	a0,800052cc <sys_write+0x5c>
  return filewrite(f, p, n);
    800052b6:	fe442603          	lw	a2,-28(s0)
    800052ba:	fd843583          	ld	a1,-40(s0)
    800052be:	fe843503          	ld	a0,-24(s0)
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	4ec080e7          	jalr	1260(ra) # 800047ae <filewrite>
    800052ca:	87aa                	mv	a5,a0
}
    800052cc:	853e                	mv	a0,a5
    800052ce:	70a2                	ld	ra,40(sp)
    800052d0:	7402                	ld	s0,32(sp)
    800052d2:	6145                	addi	sp,sp,48
    800052d4:	8082                	ret

00000000800052d6 <sys_close>:
{
    800052d6:	1101                	addi	sp,sp,-32
    800052d8:	ec06                	sd	ra,24(sp)
    800052da:	e822                	sd	s0,16(sp)
    800052dc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052de:	fe040613          	addi	a2,s0,-32
    800052e2:	fec40593          	addi	a1,s0,-20
    800052e6:	4501                	li	a0,0
    800052e8:	00000097          	auipc	ra,0x0
    800052ec:	cc4080e7          	jalr	-828(ra) # 80004fac <argfd>
    return -1;
    800052f0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052f2:	02054463          	bltz	a0,8000531a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	688080e7          	jalr	1672(ra) # 8000197e <myproc>
    800052fe:	fec42783          	lw	a5,-20(s0)
    80005302:	07e9                	addi	a5,a5,26
    80005304:	078e                	slli	a5,a5,0x3
    80005306:	97aa                	add	a5,a5,a0
    80005308:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000530c:	fe043503          	ld	a0,-32(s0)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	2a2080e7          	jalr	674(ra) # 800045b2 <fileclose>
  return 0;
    80005318:	4781                	li	a5,0
}
    8000531a:	853e                	mv	a0,a5
    8000531c:	60e2                	ld	ra,24(sp)
    8000531e:	6442                	ld	s0,16(sp)
    80005320:	6105                	addi	sp,sp,32
    80005322:	8082                	ret

0000000080005324 <sys_fstat>:
{
    80005324:	1101                	addi	sp,sp,-32
    80005326:	ec06                	sd	ra,24(sp)
    80005328:	e822                	sd	s0,16(sp)
    8000532a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000532c:	fe840613          	addi	a2,s0,-24
    80005330:	4581                	li	a1,0
    80005332:	4501                	li	a0,0
    80005334:	00000097          	auipc	ra,0x0
    80005338:	c78080e7          	jalr	-904(ra) # 80004fac <argfd>
    return -1;
    8000533c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000533e:	02054563          	bltz	a0,80005368 <sys_fstat+0x44>
    80005342:	fe040593          	addi	a1,s0,-32
    80005346:	4505                	li	a0,1
    80005348:	ffffd097          	auipc	ra,0xffffd
    8000534c:	774080e7          	jalr	1908(ra) # 80002abc <argaddr>
    return -1;
    80005350:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005352:	00054b63          	bltz	a0,80005368 <sys_fstat+0x44>
  return filestat(f, st);
    80005356:	fe043583          	ld	a1,-32(s0)
    8000535a:	fe843503          	ld	a0,-24(s0)
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	31c080e7          	jalr	796(ra) # 8000467a <filestat>
    80005366:	87aa                	mv	a5,a0
}
    80005368:	853e                	mv	a0,a5
    8000536a:	60e2                	ld	ra,24(sp)
    8000536c:	6442                	ld	s0,16(sp)
    8000536e:	6105                	addi	sp,sp,32
    80005370:	8082                	ret

0000000080005372 <sys_link>:
{
    80005372:	7169                	addi	sp,sp,-304
    80005374:	f606                	sd	ra,296(sp)
    80005376:	f222                	sd	s0,288(sp)
    80005378:	ee26                	sd	s1,280(sp)
    8000537a:	ea4a                	sd	s2,272(sp)
    8000537c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000537e:	08000613          	li	a2,128
    80005382:	ed040593          	addi	a1,s0,-304
    80005386:	4501                	li	a0,0
    80005388:	ffffd097          	auipc	ra,0xffffd
    8000538c:	756080e7          	jalr	1878(ra) # 80002ade <argstr>
    return -1;
    80005390:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005392:	10054e63          	bltz	a0,800054ae <sys_link+0x13c>
    80005396:	08000613          	li	a2,128
    8000539a:	f5040593          	addi	a1,s0,-176
    8000539e:	4505                	li	a0,1
    800053a0:	ffffd097          	auipc	ra,0xffffd
    800053a4:	73e080e7          	jalr	1854(ra) # 80002ade <argstr>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053aa:	10054263          	bltz	a0,800054ae <sys_link+0x13c>
  begin_op();
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	d38080e7          	jalr	-712(ra) # 800040e6 <begin_op>
  if((ip = namei(old)) == 0){
    800053b6:	ed040513          	addi	a0,s0,-304
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	b0c080e7          	jalr	-1268(ra) # 80003ec6 <namei>
    800053c2:	84aa                	mv	s1,a0
    800053c4:	c551                	beqz	a0,80005450 <sys_link+0xde>
  ilock(ip);
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	34a080e7          	jalr	842(ra) # 80003710 <ilock>
  if(ip->type == T_DIR){
    800053ce:	04449703          	lh	a4,68(s1)
    800053d2:	4785                	li	a5,1
    800053d4:	08f70463          	beq	a4,a5,8000545c <sys_link+0xea>
  ip->nlink++;
    800053d8:	04a4d783          	lhu	a5,74(s1)
    800053dc:	2785                	addiw	a5,a5,1
    800053de:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053e2:	8526                	mv	a0,s1
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	262080e7          	jalr	610(ra) # 80003646 <iupdate>
  iunlock(ip);
    800053ec:	8526                	mv	a0,s1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	3e4080e7          	jalr	996(ra) # 800037d2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053f6:	fd040593          	addi	a1,s0,-48
    800053fa:	f5040513          	addi	a0,s0,-176
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	ae6080e7          	jalr	-1306(ra) # 80003ee4 <nameiparent>
    80005406:	892a                	mv	s2,a0
    80005408:	c935                	beqz	a0,8000547c <sys_link+0x10a>
  ilock(dp);
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	306080e7          	jalr	774(ra) # 80003710 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005412:	00092703          	lw	a4,0(s2)
    80005416:	409c                	lw	a5,0(s1)
    80005418:	04f71d63          	bne	a4,a5,80005472 <sys_link+0x100>
    8000541c:	40d0                	lw	a2,4(s1)
    8000541e:	fd040593          	addi	a1,s0,-48
    80005422:	854a                	mv	a0,s2
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	9e0080e7          	jalr	-1568(ra) # 80003e04 <dirlink>
    8000542c:	04054363          	bltz	a0,80005472 <sys_link+0x100>
  iunlockput(dp);
    80005430:	854a                	mv	a0,s2
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	540080e7          	jalr	1344(ra) # 80003972 <iunlockput>
  iput(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	48e080e7          	jalr	1166(ra) # 800038ca <iput>
  end_op();
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	d22080e7          	jalr	-734(ra) # 80004166 <end_op>
  return 0;
    8000544c:	4781                	li	a5,0
    8000544e:	a085                	j	800054ae <sys_link+0x13c>
    end_op();
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	d16080e7          	jalr	-746(ra) # 80004166 <end_op>
    return -1;
    80005458:	57fd                	li	a5,-1
    8000545a:	a891                	j	800054ae <sys_link+0x13c>
    iunlockput(ip);
    8000545c:	8526                	mv	a0,s1
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	514080e7          	jalr	1300(ra) # 80003972 <iunlockput>
    end_op();
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	d00080e7          	jalr	-768(ra) # 80004166 <end_op>
    return -1;
    8000546e:	57fd                	li	a5,-1
    80005470:	a83d                	j	800054ae <sys_link+0x13c>
    iunlockput(dp);
    80005472:	854a                	mv	a0,s2
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	4fe080e7          	jalr	1278(ra) # 80003972 <iunlockput>
  ilock(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	292080e7          	jalr	658(ra) # 80003710 <ilock>
  ip->nlink--;
    80005486:	04a4d783          	lhu	a5,74(s1)
    8000548a:	37fd                	addiw	a5,a5,-1
    8000548c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	1b4080e7          	jalr	436(ra) # 80003646 <iupdate>
  iunlockput(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	4d6080e7          	jalr	1238(ra) # 80003972 <iunlockput>
  end_op();
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	cc2080e7          	jalr	-830(ra) # 80004166 <end_op>
  return -1;
    800054ac:	57fd                	li	a5,-1
}
    800054ae:	853e                	mv	a0,a5
    800054b0:	70b2                	ld	ra,296(sp)
    800054b2:	7412                	ld	s0,288(sp)
    800054b4:	64f2                	ld	s1,280(sp)
    800054b6:	6952                	ld	s2,272(sp)
    800054b8:	6155                	addi	sp,sp,304
    800054ba:	8082                	ret

00000000800054bc <sys_unlink>:
{
    800054bc:	7151                	addi	sp,sp,-240
    800054be:	f586                	sd	ra,232(sp)
    800054c0:	f1a2                	sd	s0,224(sp)
    800054c2:	eda6                	sd	s1,216(sp)
    800054c4:	e9ca                	sd	s2,208(sp)
    800054c6:	e5ce                	sd	s3,200(sp)
    800054c8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054ca:	08000613          	li	a2,128
    800054ce:	f3040593          	addi	a1,s0,-208
    800054d2:	4501                	li	a0,0
    800054d4:	ffffd097          	auipc	ra,0xffffd
    800054d8:	60a080e7          	jalr	1546(ra) # 80002ade <argstr>
    800054dc:	18054163          	bltz	a0,8000565e <sys_unlink+0x1a2>
  begin_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	c06080e7          	jalr	-1018(ra) # 800040e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054e8:	fb040593          	addi	a1,s0,-80
    800054ec:	f3040513          	addi	a0,s0,-208
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	9f4080e7          	jalr	-1548(ra) # 80003ee4 <nameiparent>
    800054f8:	84aa                	mv	s1,a0
    800054fa:	c979                	beqz	a0,800055d0 <sys_unlink+0x114>
  ilock(dp);
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	214080e7          	jalr	532(ra) # 80003710 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005504:	00003597          	auipc	a1,0x3
    80005508:	2dc58593          	addi	a1,a1,732 # 800087e0 <syscalls+0x2b0>
    8000550c:	fb040513          	addi	a0,s0,-80
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	6ca080e7          	jalr	1738(ra) # 80003bda <namecmp>
    80005518:	14050a63          	beqz	a0,8000566c <sys_unlink+0x1b0>
    8000551c:	00003597          	auipc	a1,0x3
    80005520:	2cc58593          	addi	a1,a1,716 # 800087e8 <syscalls+0x2b8>
    80005524:	fb040513          	addi	a0,s0,-80
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	6b2080e7          	jalr	1714(ra) # 80003bda <namecmp>
    80005530:	12050e63          	beqz	a0,8000566c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005534:	f2c40613          	addi	a2,s0,-212
    80005538:	fb040593          	addi	a1,s0,-80
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	6b6080e7          	jalr	1718(ra) # 80003bf4 <dirlookup>
    80005546:	892a                	mv	s2,a0
    80005548:	12050263          	beqz	a0,8000566c <sys_unlink+0x1b0>
  ilock(ip);
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	1c4080e7          	jalr	452(ra) # 80003710 <ilock>
  if(ip->nlink < 1)
    80005554:	04a91783          	lh	a5,74(s2)
    80005558:	08f05263          	blez	a5,800055dc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000555c:	04491703          	lh	a4,68(s2)
    80005560:	4785                	li	a5,1
    80005562:	08f70563          	beq	a4,a5,800055ec <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005566:	4641                	li	a2,16
    80005568:	4581                	li	a1,0
    8000556a:	fc040513          	addi	a0,s0,-64
    8000556e:	ffffb097          	auipc	ra,0xffffb
    80005572:	750080e7          	jalr	1872(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005576:	4741                	li	a4,16
    80005578:	f2c42683          	lw	a3,-212(s0)
    8000557c:	fc040613          	addi	a2,s0,-64
    80005580:	4581                	li	a1,0
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	538080e7          	jalr	1336(ra) # 80003abc <writei>
    8000558c:	47c1                	li	a5,16
    8000558e:	0af51563          	bne	a0,a5,80005638 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005592:	04491703          	lh	a4,68(s2)
    80005596:	4785                	li	a5,1
    80005598:	0af70863          	beq	a4,a5,80005648 <sys_unlink+0x18c>
  iunlockput(dp);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	3d4080e7          	jalr	980(ra) # 80003972 <iunlockput>
  ip->nlink--;
    800055a6:	04a95783          	lhu	a5,74(s2)
    800055aa:	37fd                	addiw	a5,a5,-1
    800055ac:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055b0:	854a                	mv	a0,s2
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	094080e7          	jalr	148(ra) # 80003646 <iupdate>
  iunlockput(ip);
    800055ba:	854a                	mv	a0,s2
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	3b6080e7          	jalr	950(ra) # 80003972 <iunlockput>
  end_op();
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	ba2080e7          	jalr	-1118(ra) # 80004166 <end_op>
  return 0;
    800055cc:	4501                	li	a0,0
    800055ce:	a84d                	j	80005680 <sys_unlink+0x1c4>
    end_op();
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	b96080e7          	jalr	-1130(ra) # 80004166 <end_op>
    return -1;
    800055d8:	557d                	li	a0,-1
    800055da:	a05d                	j	80005680 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055dc:	00003517          	auipc	a0,0x3
    800055e0:	23450513          	addi	a0,a0,564 # 80008810 <syscalls+0x2e0>
    800055e4:	ffffb097          	auipc	ra,0xffffb
    800055e8:	f46080e7          	jalr	-186(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ec:	04c92703          	lw	a4,76(s2)
    800055f0:	02000793          	li	a5,32
    800055f4:	f6e7f9e3          	bgeu	a5,a4,80005566 <sys_unlink+0xaa>
    800055f8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055fc:	4741                	li	a4,16
    800055fe:	86ce                	mv	a3,s3
    80005600:	f1840613          	addi	a2,s0,-232
    80005604:	4581                	li	a1,0
    80005606:	854a                	mv	a0,s2
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	3bc080e7          	jalr	956(ra) # 800039c4 <readi>
    80005610:	47c1                	li	a5,16
    80005612:	00f51b63          	bne	a0,a5,80005628 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005616:	f1845783          	lhu	a5,-232(s0)
    8000561a:	e7a1                	bnez	a5,80005662 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000561c:	29c1                	addiw	s3,s3,16
    8000561e:	04c92783          	lw	a5,76(s2)
    80005622:	fcf9ede3          	bltu	s3,a5,800055fc <sys_unlink+0x140>
    80005626:	b781                	j	80005566 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005628:	00003517          	auipc	a0,0x3
    8000562c:	20050513          	addi	a0,a0,512 # 80008828 <syscalls+0x2f8>
    80005630:	ffffb097          	auipc	ra,0xffffb
    80005634:	efa080e7          	jalr	-262(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005638:	00003517          	auipc	a0,0x3
    8000563c:	20850513          	addi	a0,a0,520 # 80008840 <syscalls+0x310>
    80005640:	ffffb097          	auipc	ra,0xffffb
    80005644:	eea080e7          	jalr	-278(ra) # 8000052a <panic>
    dp->nlink--;
    80005648:	04a4d783          	lhu	a5,74(s1)
    8000564c:	37fd                	addiw	a5,a5,-1
    8000564e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	ff2080e7          	jalr	-14(ra) # 80003646 <iupdate>
    8000565c:	b781                	j	8000559c <sys_unlink+0xe0>
    return -1;
    8000565e:	557d                	li	a0,-1
    80005660:	a005                	j	80005680 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	30e080e7          	jalr	782(ra) # 80003972 <iunlockput>
  iunlockput(dp);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	304080e7          	jalr	772(ra) # 80003972 <iunlockput>
  end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	af0080e7          	jalr	-1296(ra) # 80004166 <end_op>
  return -1;
    8000567e:	557d                	li	a0,-1
}
    80005680:	70ae                	ld	ra,232(sp)
    80005682:	740e                	ld	s0,224(sp)
    80005684:	64ee                	ld	s1,216(sp)
    80005686:	694e                	ld	s2,208(sp)
    80005688:	69ae                	ld	s3,200(sp)
    8000568a:	616d                	addi	sp,sp,240
    8000568c:	8082                	ret

000000008000568e <sys_open>:

uint64
sys_open(void)
{
    8000568e:	7131                	addi	sp,sp,-192
    80005690:	fd06                	sd	ra,184(sp)
    80005692:	f922                	sd	s0,176(sp)
    80005694:	f526                	sd	s1,168(sp)
    80005696:	f14a                	sd	s2,160(sp)
    80005698:	ed4e                	sd	s3,152(sp)
    8000569a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000569c:	08000613          	li	a2,128
    800056a0:	f5040593          	addi	a1,s0,-176
    800056a4:	4501                	li	a0,0
    800056a6:	ffffd097          	auipc	ra,0xffffd
    800056aa:	438080e7          	jalr	1080(ra) # 80002ade <argstr>
    return -1;
    800056ae:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056b0:	0c054163          	bltz	a0,80005772 <sys_open+0xe4>
    800056b4:	f4c40593          	addi	a1,s0,-180
    800056b8:	4505                	li	a0,1
    800056ba:	ffffd097          	auipc	ra,0xffffd
    800056be:	3e0080e7          	jalr	992(ra) # 80002a9a <argint>
    800056c2:	0a054863          	bltz	a0,80005772 <sys_open+0xe4>

  begin_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	a20080e7          	jalr	-1504(ra) # 800040e6 <begin_op>

  if(omode & O_CREATE){
    800056ce:	f4c42783          	lw	a5,-180(s0)
    800056d2:	2007f793          	andi	a5,a5,512
    800056d6:	cbdd                	beqz	a5,8000578c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056d8:	4681                	li	a3,0
    800056da:	4601                	li	a2,0
    800056dc:	4589                	li	a1,2
    800056de:	f5040513          	addi	a0,s0,-176
    800056e2:	00000097          	auipc	ra,0x0
    800056e6:	974080e7          	jalr	-1676(ra) # 80005056 <create>
    800056ea:	892a                	mv	s2,a0
    if(ip == 0){
    800056ec:	c959                	beqz	a0,80005782 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056ee:	04491703          	lh	a4,68(s2)
    800056f2:	478d                	li	a5,3
    800056f4:	00f71763          	bne	a4,a5,80005702 <sys_open+0x74>
    800056f8:	04695703          	lhu	a4,70(s2)
    800056fc:	47a5                	li	a5,9
    800056fe:	0ce7ec63          	bltu	a5,a4,800057d6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	df4080e7          	jalr	-524(ra) # 800044f6 <filealloc>
    8000570a:	89aa                	mv	s3,a0
    8000570c:	10050263          	beqz	a0,80005810 <sys_open+0x182>
    80005710:	00000097          	auipc	ra,0x0
    80005714:	904080e7          	jalr	-1788(ra) # 80005014 <fdalloc>
    80005718:	84aa                	mv	s1,a0
    8000571a:	0e054663          	bltz	a0,80005806 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000571e:	04491703          	lh	a4,68(s2)
    80005722:	478d                	li	a5,3
    80005724:	0cf70463          	beq	a4,a5,800057ec <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005728:	4789                	li	a5,2
    8000572a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000572e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005732:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005736:	f4c42783          	lw	a5,-180(s0)
    8000573a:	0017c713          	xori	a4,a5,1
    8000573e:	8b05                	andi	a4,a4,1
    80005740:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005744:	0037f713          	andi	a4,a5,3
    80005748:	00e03733          	snez	a4,a4
    8000574c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005750:	4007f793          	andi	a5,a5,1024
    80005754:	c791                	beqz	a5,80005760 <sys_open+0xd2>
    80005756:	04491703          	lh	a4,68(s2)
    8000575a:	4789                	li	a5,2
    8000575c:	08f70f63          	beq	a4,a5,800057fa <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005760:	854a                	mv	a0,s2
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	070080e7          	jalr	112(ra) # 800037d2 <iunlock>
  end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	9fc080e7          	jalr	-1540(ra) # 80004166 <end_op>

  return fd;
}
    80005772:	8526                	mv	a0,s1
    80005774:	70ea                	ld	ra,184(sp)
    80005776:	744a                	ld	s0,176(sp)
    80005778:	74aa                	ld	s1,168(sp)
    8000577a:	790a                	ld	s2,160(sp)
    8000577c:	69ea                	ld	s3,152(sp)
    8000577e:	6129                	addi	sp,sp,192
    80005780:	8082                	ret
      end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	9e4080e7          	jalr	-1564(ra) # 80004166 <end_op>
      return -1;
    8000578a:	b7e5                	j	80005772 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000578c:	f5040513          	addi	a0,s0,-176
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	736080e7          	jalr	1846(ra) # 80003ec6 <namei>
    80005798:	892a                	mv	s2,a0
    8000579a:	c905                	beqz	a0,800057ca <sys_open+0x13c>
    ilock(ip);
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	f74080e7          	jalr	-140(ra) # 80003710 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057a4:	04491703          	lh	a4,68(s2)
    800057a8:	4785                	li	a5,1
    800057aa:	f4f712e3          	bne	a4,a5,800056ee <sys_open+0x60>
    800057ae:	f4c42783          	lw	a5,-180(s0)
    800057b2:	dba1                	beqz	a5,80005702 <sys_open+0x74>
      iunlockput(ip);
    800057b4:	854a                	mv	a0,s2
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	1bc080e7          	jalr	444(ra) # 80003972 <iunlockput>
      end_op();
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	9a8080e7          	jalr	-1624(ra) # 80004166 <end_op>
      return -1;
    800057c6:	54fd                	li	s1,-1
    800057c8:	b76d                	j	80005772 <sys_open+0xe4>
      end_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	99c080e7          	jalr	-1636(ra) # 80004166 <end_op>
      return -1;
    800057d2:	54fd                	li	s1,-1
    800057d4:	bf79                	j	80005772 <sys_open+0xe4>
    iunlockput(ip);
    800057d6:	854a                	mv	a0,s2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	19a080e7          	jalr	410(ra) # 80003972 <iunlockput>
    end_op();
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	986080e7          	jalr	-1658(ra) # 80004166 <end_op>
    return -1;
    800057e8:	54fd                	li	s1,-1
    800057ea:	b761                	j	80005772 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057ec:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057f0:	04691783          	lh	a5,70(s2)
    800057f4:	02f99223          	sh	a5,36(s3)
    800057f8:	bf2d                	j	80005732 <sys_open+0xa4>
    itrunc(ip);
    800057fa:	854a                	mv	a0,s2
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	022080e7          	jalr	34(ra) # 8000381e <itrunc>
    80005804:	bfb1                	j	80005760 <sys_open+0xd2>
      fileclose(f);
    80005806:	854e                	mv	a0,s3
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	daa080e7          	jalr	-598(ra) # 800045b2 <fileclose>
    iunlockput(ip);
    80005810:	854a                	mv	a0,s2
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	160080e7          	jalr	352(ra) # 80003972 <iunlockput>
    end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	94c080e7          	jalr	-1716(ra) # 80004166 <end_op>
    return -1;
    80005822:	54fd                	li	s1,-1
    80005824:	b7b9                	j	80005772 <sys_open+0xe4>

0000000080005826 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005826:	7175                	addi	sp,sp,-144
    80005828:	e506                	sd	ra,136(sp)
    8000582a:	e122                	sd	s0,128(sp)
    8000582c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	8b8080e7          	jalr	-1864(ra) # 800040e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005836:	08000613          	li	a2,128
    8000583a:	f7040593          	addi	a1,s0,-144
    8000583e:	4501                	li	a0,0
    80005840:	ffffd097          	auipc	ra,0xffffd
    80005844:	29e080e7          	jalr	670(ra) # 80002ade <argstr>
    80005848:	02054963          	bltz	a0,8000587a <sys_mkdir+0x54>
    8000584c:	4681                	li	a3,0
    8000584e:	4601                	li	a2,0
    80005850:	4585                	li	a1,1
    80005852:	f7040513          	addi	a0,s0,-144
    80005856:	00000097          	auipc	ra,0x0
    8000585a:	800080e7          	jalr	-2048(ra) # 80005056 <create>
    8000585e:	cd11                	beqz	a0,8000587a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	112080e7          	jalr	274(ra) # 80003972 <iunlockput>
  end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	8fe080e7          	jalr	-1794(ra) # 80004166 <end_op>
  return 0;
    80005870:	4501                	li	a0,0
}
    80005872:	60aa                	ld	ra,136(sp)
    80005874:	640a                	ld	s0,128(sp)
    80005876:	6149                	addi	sp,sp,144
    80005878:	8082                	ret
    end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	8ec080e7          	jalr	-1812(ra) # 80004166 <end_op>
    return -1;
    80005882:	557d                	li	a0,-1
    80005884:	b7fd                	j	80005872 <sys_mkdir+0x4c>

0000000080005886 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005886:	7135                	addi	sp,sp,-160
    80005888:	ed06                	sd	ra,152(sp)
    8000588a:	e922                	sd	s0,144(sp)
    8000588c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	858080e7          	jalr	-1960(ra) # 800040e6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005896:	08000613          	li	a2,128
    8000589a:	f7040593          	addi	a1,s0,-144
    8000589e:	4501                	li	a0,0
    800058a0:	ffffd097          	auipc	ra,0xffffd
    800058a4:	23e080e7          	jalr	574(ra) # 80002ade <argstr>
    800058a8:	04054a63          	bltz	a0,800058fc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058ac:	f6c40593          	addi	a1,s0,-148
    800058b0:	4505                	li	a0,1
    800058b2:	ffffd097          	auipc	ra,0xffffd
    800058b6:	1e8080e7          	jalr	488(ra) # 80002a9a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ba:	04054163          	bltz	a0,800058fc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058be:	f6840593          	addi	a1,s0,-152
    800058c2:	4509                	li	a0,2
    800058c4:	ffffd097          	auipc	ra,0xffffd
    800058c8:	1d6080e7          	jalr	470(ra) # 80002a9a <argint>
     argint(1, &major) < 0 ||
    800058cc:	02054863          	bltz	a0,800058fc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058d0:	f6841683          	lh	a3,-152(s0)
    800058d4:	f6c41603          	lh	a2,-148(s0)
    800058d8:	458d                	li	a1,3
    800058da:	f7040513          	addi	a0,s0,-144
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	778080e7          	jalr	1912(ra) # 80005056 <create>
     argint(2, &minor) < 0 ||
    800058e6:	c919                	beqz	a0,800058fc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	08a080e7          	jalr	138(ra) # 80003972 <iunlockput>
  end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	876080e7          	jalr	-1930(ra) # 80004166 <end_op>
  return 0;
    800058f8:	4501                	li	a0,0
    800058fa:	a031                	j	80005906 <sys_mknod+0x80>
    end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	86a080e7          	jalr	-1942(ra) # 80004166 <end_op>
    return -1;
    80005904:	557d                	li	a0,-1
}
    80005906:	60ea                	ld	ra,152(sp)
    80005908:	644a                	ld	s0,144(sp)
    8000590a:	610d                	addi	sp,sp,160
    8000590c:	8082                	ret

000000008000590e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000590e:	7135                	addi	sp,sp,-160
    80005910:	ed06                	sd	ra,152(sp)
    80005912:	e922                	sd	s0,144(sp)
    80005914:	e526                	sd	s1,136(sp)
    80005916:	e14a                	sd	s2,128(sp)
    80005918:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000591a:	ffffc097          	auipc	ra,0xffffc
    8000591e:	064080e7          	jalr	100(ra) # 8000197e <myproc>
    80005922:	892a                	mv	s2,a0
  
  begin_op();
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	7c2080e7          	jalr	1986(ra) # 800040e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000592c:	08000613          	li	a2,128
    80005930:	f6040593          	addi	a1,s0,-160
    80005934:	4501                	li	a0,0
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	1a8080e7          	jalr	424(ra) # 80002ade <argstr>
    8000593e:	04054b63          	bltz	a0,80005994 <sys_chdir+0x86>
    80005942:	f6040513          	addi	a0,s0,-160
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	580080e7          	jalr	1408(ra) # 80003ec6 <namei>
    8000594e:	84aa                	mv	s1,a0
    80005950:	c131                	beqz	a0,80005994 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	dbe080e7          	jalr	-578(ra) # 80003710 <ilock>
  if(ip->type != T_DIR){
    8000595a:	04449703          	lh	a4,68(s1)
    8000595e:	4785                	li	a5,1
    80005960:	04f71063          	bne	a4,a5,800059a0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005964:	8526                	mv	a0,s1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	e6c080e7          	jalr	-404(ra) # 800037d2 <iunlock>
  iput(p->cwd);
    8000596e:	15093503          	ld	a0,336(s2)
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	f58080e7          	jalr	-168(ra) # 800038ca <iput>
  end_op();
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	7ec080e7          	jalr	2028(ra) # 80004166 <end_op>
  p->cwd = ip;
    80005982:	14993823          	sd	s1,336(s2)
  return 0;
    80005986:	4501                	li	a0,0
}
    80005988:	60ea                	ld	ra,152(sp)
    8000598a:	644a                	ld	s0,144(sp)
    8000598c:	64aa                	ld	s1,136(sp)
    8000598e:	690a                	ld	s2,128(sp)
    80005990:	610d                	addi	sp,sp,160
    80005992:	8082                	ret
    end_op();
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	7d2080e7          	jalr	2002(ra) # 80004166 <end_op>
    return -1;
    8000599c:	557d                	li	a0,-1
    8000599e:	b7ed                	j	80005988 <sys_chdir+0x7a>
    iunlockput(ip);
    800059a0:	8526                	mv	a0,s1
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	fd0080e7          	jalr	-48(ra) # 80003972 <iunlockput>
    end_op();
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	7bc080e7          	jalr	1980(ra) # 80004166 <end_op>
    return -1;
    800059b2:	557d                	li	a0,-1
    800059b4:	bfd1                	j	80005988 <sys_chdir+0x7a>

00000000800059b6 <sys_exec>:

uint64
sys_exec(void)
{
    800059b6:	7145                	addi	sp,sp,-464
    800059b8:	e786                	sd	ra,456(sp)
    800059ba:	e3a2                	sd	s0,448(sp)
    800059bc:	ff26                	sd	s1,440(sp)
    800059be:	fb4a                	sd	s2,432(sp)
    800059c0:	f74e                	sd	s3,424(sp)
    800059c2:	f352                	sd	s4,416(sp)
    800059c4:	ef56                	sd	s5,408(sp)
    800059c6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059c8:	08000613          	li	a2,128
    800059cc:	f4040593          	addi	a1,s0,-192
    800059d0:	4501                	li	a0,0
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	10c080e7          	jalr	268(ra) # 80002ade <argstr>
    return -1;
    800059da:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059dc:	0c054a63          	bltz	a0,80005ab0 <sys_exec+0xfa>
    800059e0:	e3840593          	addi	a1,s0,-456
    800059e4:	4505                	li	a0,1
    800059e6:	ffffd097          	auipc	ra,0xffffd
    800059ea:	0d6080e7          	jalr	214(ra) # 80002abc <argaddr>
    800059ee:	0c054163          	bltz	a0,80005ab0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059f2:	10000613          	li	a2,256
    800059f6:	4581                	li	a1,0
    800059f8:	e4040513          	addi	a0,s0,-448
    800059fc:	ffffb097          	auipc	ra,0xffffb
    80005a00:	2c2080e7          	jalr	706(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a04:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a08:	89a6                	mv	s3,s1
    80005a0a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a0c:	02000a13          	li	s4,32
    80005a10:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a14:	00391793          	slli	a5,s2,0x3
    80005a18:	e3040593          	addi	a1,s0,-464
    80005a1c:	e3843503          	ld	a0,-456(s0)
    80005a20:	953e                	add	a0,a0,a5
    80005a22:	ffffd097          	auipc	ra,0xffffd
    80005a26:	fde080e7          	jalr	-34(ra) # 80002a00 <fetchaddr>
    80005a2a:	02054a63          	bltz	a0,80005a5e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a2e:	e3043783          	ld	a5,-464(s0)
    80005a32:	c3b9                	beqz	a5,80005a78 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	09e080e7          	jalr	158(ra) # 80000ad2 <kalloc>
    80005a3c:	85aa                	mv	a1,a0
    80005a3e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a42:	cd11                	beqz	a0,80005a5e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a44:	6605                	lui	a2,0x1
    80005a46:	e3043503          	ld	a0,-464(s0)
    80005a4a:	ffffd097          	auipc	ra,0xffffd
    80005a4e:	008080e7          	jalr	8(ra) # 80002a52 <fetchstr>
    80005a52:	00054663          	bltz	a0,80005a5e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a56:	0905                	addi	s2,s2,1
    80005a58:	09a1                	addi	s3,s3,8
    80005a5a:	fb491be3          	bne	s2,s4,80005a10 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a5e:	10048913          	addi	s2,s1,256
    80005a62:	6088                	ld	a0,0(s1)
    80005a64:	c529                	beqz	a0,80005aae <sys_exec+0xf8>
    kfree(argv[i]);
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	f70080e7          	jalr	-144(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a6e:	04a1                	addi	s1,s1,8
    80005a70:	ff2499e3          	bne	s1,s2,80005a62 <sys_exec+0xac>
  return -1;
    80005a74:	597d                	li	s2,-1
    80005a76:	a82d                	j	80005ab0 <sys_exec+0xfa>
      argv[i] = 0;
    80005a78:	0a8e                	slli	s5,s5,0x3
    80005a7a:	fc040793          	addi	a5,s0,-64
    80005a7e:	9abe                	add	s5,s5,a5
    80005a80:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005a84:	e4040593          	addi	a1,s0,-448
    80005a88:	f4040513          	addi	a0,s0,-192
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	178080e7          	jalr	376(ra) # 80004c04 <exec>
    80005a94:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a96:	10048993          	addi	s3,s1,256
    80005a9a:	6088                	ld	a0,0(s1)
    80005a9c:	c911                	beqz	a0,80005ab0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	f38080e7          	jalr	-200(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa6:	04a1                	addi	s1,s1,8
    80005aa8:	ff3499e3          	bne	s1,s3,80005a9a <sys_exec+0xe4>
    80005aac:	a011                	j	80005ab0 <sys_exec+0xfa>
  return -1;
    80005aae:	597d                	li	s2,-1
}
    80005ab0:	854a                	mv	a0,s2
    80005ab2:	60be                	ld	ra,456(sp)
    80005ab4:	641e                	ld	s0,448(sp)
    80005ab6:	74fa                	ld	s1,440(sp)
    80005ab8:	795a                	ld	s2,432(sp)
    80005aba:	79ba                	ld	s3,424(sp)
    80005abc:	7a1a                	ld	s4,416(sp)
    80005abe:	6afa                	ld	s5,408(sp)
    80005ac0:	6179                	addi	sp,sp,464
    80005ac2:	8082                	ret

0000000080005ac4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ac4:	7139                	addi	sp,sp,-64
    80005ac6:	fc06                	sd	ra,56(sp)
    80005ac8:	f822                	sd	s0,48(sp)
    80005aca:	f426                	sd	s1,40(sp)
    80005acc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ace:	ffffc097          	auipc	ra,0xffffc
    80005ad2:	eb0080e7          	jalr	-336(ra) # 8000197e <myproc>
    80005ad6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ad8:	fd840593          	addi	a1,s0,-40
    80005adc:	4501                	li	a0,0
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	fde080e7          	jalr	-34(ra) # 80002abc <argaddr>
    return -1;
    80005ae6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ae8:	0e054063          	bltz	a0,80005bc8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005aec:	fc840593          	addi	a1,s0,-56
    80005af0:	fd040513          	addi	a0,s0,-48
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	dee080e7          	jalr	-530(ra) # 800048e2 <pipealloc>
    return -1;
    80005afc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005afe:	0c054563          	bltz	a0,80005bc8 <sys_pipe+0x104>
  fd0 = -1;
    80005b02:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b06:	fd043503          	ld	a0,-48(s0)
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	50a080e7          	jalr	1290(ra) # 80005014 <fdalloc>
    80005b12:	fca42223          	sw	a0,-60(s0)
    80005b16:	08054c63          	bltz	a0,80005bae <sys_pipe+0xea>
    80005b1a:	fc843503          	ld	a0,-56(s0)
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	4f6080e7          	jalr	1270(ra) # 80005014 <fdalloc>
    80005b26:	fca42023          	sw	a0,-64(s0)
    80005b2a:	06054863          	bltz	a0,80005b9a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b2e:	4691                	li	a3,4
    80005b30:	fc440613          	addi	a2,s0,-60
    80005b34:	fd843583          	ld	a1,-40(s0)
    80005b38:	68a8                	ld	a0,80(s1)
    80005b3a:	ffffc097          	auipc	ra,0xffffc
    80005b3e:	b04080e7          	jalr	-1276(ra) # 8000163e <copyout>
    80005b42:	02054063          	bltz	a0,80005b62 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b46:	4691                	li	a3,4
    80005b48:	fc040613          	addi	a2,s0,-64
    80005b4c:	fd843583          	ld	a1,-40(s0)
    80005b50:	0591                	addi	a1,a1,4
    80005b52:	68a8                	ld	a0,80(s1)
    80005b54:	ffffc097          	auipc	ra,0xffffc
    80005b58:	aea080e7          	jalr	-1302(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b5c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b5e:	06055563          	bgez	a0,80005bc8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b62:	fc442783          	lw	a5,-60(s0)
    80005b66:	07e9                	addi	a5,a5,26
    80005b68:	078e                	slli	a5,a5,0x3
    80005b6a:	97a6                	add	a5,a5,s1
    80005b6c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b70:	fc042503          	lw	a0,-64(s0)
    80005b74:	0569                	addi	a0,a0,26
    80005b76:	050e                	slli	a0,a0,0x3
    80005b78:	9526                	add	a0,a0,s1
    80005b7a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b7e:	fd043503          	ld	a0,-48(s0)
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	a30080e7          	jalr	-1488(ra) # 800045b2 <fileclose>
    fileclose(wf);
    80005b8a:	fc843503          	ld	a0,-56(s0)
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	a24080e7          	jalr	-1500(ra) # 800045b2 <fileclose>
    return -1;
    80005b96:	57fd                	li	a5,-1
    80005b98:	a805                	j	80005bc8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b9a:	fc442783          	lw	a5,-60(s0)
    80005b9e:	0007c863          	bltz	a5,80005bae <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ba2:	01a78513          	addi	a0,a5,26
    80005ba6:	050e                	slli	a0,a0,0x3
    80005ba8:	9526                	add	a0,a0,s1
    80005baa:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bae:	fd043503          	ld	a0,-48(s0)
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	a00080e7          	jalr	-1536(ra) # 800045b2 <fileclose>
    fileclose(wf);
    80005bba:	fc843503          	ld	a0,-56(s0)
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	9f4080e7          	jalr	-1548(ra) # 800045b2 <fileclose>
    return -1;
    80005bc6:	57fd                	li	a5,-1
}
    80005bc8:	853e                	mv	a0,a5
    80005bca:	70e2                	ld	ra,56(sp)
    80005bcc:	7442                	ld	s0,48(sp)
    80005bce:	74a2                	ld	s1,40(sp)
    80005bd0:	6121                	addi	sp,sp,64
    80005bd2:	8082                	ret
	...

0000000080005be0 <kernelvec>:
    80005be0:	7111                	addi	sp,sp,-256
    80005be2:	e006                	sd	ra,0(sp)
    80005be4:	e40a                	sd	sp,8(sp)
    80005be6:	e80e                	sd	gp,16(sp)
    80005be8:	ec12                	sd	tp,24(sp)
    80005bea:	f016                	sd	t0,32(sp)
    80005bec:	f41a                	sd	t1,40(sp)
    80005bee:	f81e                	sd	t2,48(sp)
    80005bf0:	fc22                	sd	s0,56(sp)
    80005bf2:	e0a6                	sd	s1,64(sp)
    80005bf4:	e4aa                	sd	a0,72(sp)
    80005bf6:	e8ae                	sd	a1,80(sp)
    80005bf8:	ecb2                	sd	a2,88(sp)
    80005bfa:	f0b6                	sd	a3,96(sp)
    80005bfc:	f4ba                	sd	a4,104(sp)
    80005bfe:	f8be                	sd	a5,112(sp)
    80005c00:	fcc2                	sd	a6,120(sp)
    80005c02:	e146                	sd	a7,128(sp)
    80005c04:	e54a                	sd	s2,136(sp)
    80005c06:	e94e                	sd	s3,144(sp)
    80005c08:	ed52                	sd	s4,152(sp)
    80005c0a:	f156                	sd	s5,160(sp)
    80005c0c:	f55a                	sd	s6,168(sp)
    80005c0e:	f95e                	sd	s7,176(sp)
    80005c10:	fd62                	sd	s8,184(sp)
    80005c12:	e1e6                	sd	s9,192(sp)
    80005c14:	e5ea                	sd	s10,200(sp)
    80005c16:	e9ee                	sd	s11,208(sp)
    80005c18:	edf2                	sd	t3,216(sp)
    80005c1a:	f1f6                	sd	t4,224(sp)
    80005c1c:	f5fa                	sd	t5,232(sp)
    80005c1e:	f9fe                	sd	t6,240(sp)
    80005c20:	cadfc0ef          	jal	ra,800028cc <kerneltrap>
    80005c24:	6082                	ld	ra,0(sp)
    80005c26:	6122                	ld	sp,8(sp)
    80005c28:	61c2                	ld	gp,16(sp)
    80005c2a:	7282                	ld	t0,32(sp)
    80005c2c:	7322                	ld	t1,40(sp)
    80005c2e:	73c2                	ld	t2,48(sp)
    80005c30:	7462                	ld	s0,56(sp)
    80005c32:	6486                	ld	s1,64(sp)
    80005c34:	6526                	ld	a0,72(sp)
    80005c36:	65c6                	ld	a1,80(sp)
    80005c38:	6666                	ld	a2,88(sp)
    80005c3a:	7686                	ld	a3,96(sp)
    80005c3c:	7726                	ld	a4,104(sp)
    80005c3e:	77c6                	ld	a5,112(sp)
    80005c40:	7866                	ld	a6,120(sp)
    80005c42:	688a                	ld	a7,128(sp)
    80005c44:	692a                	ld	s2,136(sp)
    80005c46:	69ca                	ld	s3,144(sp)
    80005c48:	6a6a                	ld	s4,152(sp)
    80005c4a:	7a8a                	ld	s5,160(sp)
    80005c4c:	7b2a                	ld	s6,168(sp)
    80005c4e:	7bca                	ld	s7,176(sp)
    80005c50:	7c6a                	ld	s8,184(sp)
    80005c52:	6c8e                	ld	s9,192(sp)
    80005c54:	6d2e                	ld	s10,200(sp)
    80005c56:	6dce                	ld	s11,208(sp)
    80005c58:	6e6e                	ld	t3,216(sp)
    80005c5a:	7e8e                	ld	t4,224(sp)
    80005c5c:	7f2e                	ld	t5,232(sp)
    80005c5e:	7fce                	ld	t6,240(sp)
    80005c60:	6111                	addi	sp,sp,256
    80005c62:	10200073          	sret
    80005c66:	00000013          	nop
    80005c6a:	00000013          	nop
    80005c6e:	0001                	nop

0000000080005c70 <timervec>:
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	e10c                	sd	a1,0(a0)
    80005c76:	e510                	sd	a2,8(a0)
    80005c78:	e914                	sd	a3,16(a0)
    80005c7a:	6d0c                	ld	a1,24(a0)
    80005c7c:	7110                	ld	a2,32(a0)
    80005c7e:	6194                	ld	a3,0(a1)
    80005c80:	96b2                	add	a3,a3,a2
    80005c82:	e194                	sd	a3,0(a1)
    80005c84:	4589                	li	a1,2
    80005c86:	14459073          	csrw	sip,a1
    80005c8a:	6914                	ld	a3,16(a0)
    80005c8c:	6510                	ld	a2,8(a0)
    80005c8e:	610c                	ld	a1,0(a0)
    80005c90:	34051573          	csrrw	a0,mscratch,a0
    80005c94:	30200073          	mret
	...

0000000080005c9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c9a:	1141                	addi	sp,sp,-16
    80005c9c:	e422                	sd	s0,8(sp)
    80005c9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ca0:	0c0007b7          	lui	a5,0xc000
    80005ca4:	4705                	li	a4,1
    80005ca6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ca8:	c3d8                	sw	a4,4(a5)
}
    80005caa:	6422                	ld	s0,8(sp)
    80005cac:	0141                	addi	sp,sp,16
    80005cae:	8082                	ret

0000000080005cb0 <plicinithart>:

void
plicinithart(void)
{
    80005cb0:	1141                	addi	sp,sp,-16
    80005cb2:	e406                	sd	ra,8(sp)
    80005cb4:	e022                	sd	s0,0(sp)
    80005cb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	c9a080e7          	jalr	-870(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cc0:	0085171b          	slliw	a4,a0,0x8
    80005cc4:	0c0027b7          	lui	a5,0xc002
    80005cc8:	97ba                	add	a5,a5,a4
    80005cca:	40200713          	li	a4,1026
    80005cce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cd2:	00d5151b          	slliw	a0,a0,0xd
    80005cd6:	0c2017b7          	lui	a5,0xc201
    80005cda:	953e                	add	a0,a0,a5
    80005cdc:	00052023          	sw	zero,0(a0)
}
    80005ce0:	60a2                	ld	ra,8(sp)
    80005ce2:	6402                	ld	s0,0(sp)
    80005ce4:	0141                	addi	sp,sp,16
    80005ce6:	8082                	ret

0000000080005ce8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ce8:	1141                	addi	sp,sp,-16
    80005cea:	e406                	sd	ra,8(sp)
    80005cec:	e022                	sd	s0,0(sp)
    80005cee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf0:	ffffc097          	auipc	ra,0xffffc
    80005cf4:	c62080e7          	jalr	-926(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cf8:	00d5179b          	slliw	a5,a0,0xd
    80005cfc:	0c201537          	lui	a0,0xc201
    80005d00:	953e                	add	a0,a0,a5
  return irq;
}
    80005d02:	4148                	lw	a0,4(a0)
    80005d04:	60a2                	ld	ra,8(sp)
    80005d06:	6402                	ld	s0,0(sp)
    80005d08:	0141                	addi	sp,sp,16
    80005d0a:	8082                	ret

0000000080005d0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d0c:	1101                	addi	sp,sp,-32
    80005d0e:	ec06                	sd	ra,24(sp)
    80005d10:	e822                	sd	s0,16(sp)
    80005d12:	e426                	sd	s1,8(sp)
    80005d14:	1000                	addi	s0,sp,32
    80005d16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	c3a080e7          	jalr	-966(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d20:	00d5151b          	slliw	a0,a0,0xd
    80005d24:	0c2017b7          	lui	a5,0xc201
    80005d28:	97aa                	add	a5,a5,a0
    80005d2a:	c3c4                	sw	s1,4(a5)
}
    80005d2c:	60e2                	ld	ra,24(sp)
    80005d2e:	6442                	ld	s0,16(sp)
    80005d30:	64a2                	ld	s1,8(sp)
    80005d32:	6105                	addi	sp,sp,32
    80005d34:	8082                	ret

0000000080005d36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d36:	1141                	addi	sp,sp,-16
    80005d38:	e406                	sd	ra,8(sp)
    80005d3a:	e022                	sd	s0,0(sp)
    80005d3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d3e:	479d                	li	a5,7
    80005d40:	06a7c963          	blt	a5,a0,80005db2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d44:	0001d797          	auipc	a5,0x1d
    80005d48:	2bc78793          	addi	a5,a5,700 # 80023000 <disk>
    80005d4c:	00a78733          	add	a4,a5,a0
    80005d50:	6789                	lui	a5,0x2
    80005d52:	97ba                	add	a5,a5,a4
    80005d54:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d58:	e7ad                	bnez	a5,80005dc2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d5a:	00451793          	slli	a5,a0,0x4
    80005d5e:	0001f717          	auipc	a4,0x1f
    80005d62:	2a270713          	addi	a4,a4,674 # 80025000 <disk+0x2000>
    80005d66:	6314                	ld	a3,0(a4)
    80005d68:	96be                	add	a3,a3,a5
    80005d6a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d6e:	6314                	ld	a3,0(a4)
    80005d70:	96be                	add	a3,a3,a5
    80005d72:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d76:	6314                	ld	a3,0(a4)
    80005d78:	96be                	add	a3,a3,a5
    80005d7a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d7e:	6318                	ld	a4,0(a4)
    80005d80:	97ba                	add	a5,a5,a4
    80005d82:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d86:	0001d797          	auipc	a5,0x1d
    80005d8a:	27a78793          	addi	a5,a5,634 # 80023000 <disk>
    80005d8e:	97aa                	add	a5,a5,a0
    80005d90:	6509                	lui	a0,0x2
    80005d92:	953e                	add	a0,a0,a5
    80005d94:	4785                	li	a5,1
    80005d96:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d9a:	0001f517          	auipc	a0,0x1f
    80005d9e:	27e50513          	addi	a0,a0,638 # 80025018 <disk+0x2018>
    80005da2:	ffffc097          	auipc	ra,0xffffc
    80005da6:	434080e7          	jalr	1076(ra) # 800021d6 <wakeup>
}
    80005daa:	60a2                	ld	ra,8(sp)
    80005dac:	6402                	ld	s0,0(sp)
    80005dae:	0141                	addi	sp,sp,16
    80005db0:	8082                	ret
    panic("free_desc 1");
    80005db2:	00003517          	auipc	a0,0x3
    80005db6:	a9e50513          	addi	a0,a0,-1378 # 80008850 <syscalls+0x320>
    80005dba:	ffffa097          	auipc	ra,0xffffa
    80005dbe:	770080e7          	jalr	1904(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005dc2:	00003517          	auipc	a0,0x3
    80005dc6:	a9e50513          	addi	a0,a0,-1378 # 80008860 <syscalls+0x330>
    80005dca:	ffffa097          	auipc	ra,0xffffa
    80005dce:	760080e7          	jalr	1888(ra) # 8000052a <panic>

0000000080005dd2 <virtio_disk_init>:
{
    80005dd2:	1101                	addi	sp,sp,-32
    80005dd4:	ec06                	sd	ra,24(sp)
    80005dd6:	e822                	sd	s0,16(sp)
    80005dd8:	e426                	sd	s1,8(sp)
    80005dda:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ddc:	00003597          	auipc	a1,0x3
    80005de0:	a9458593          	addi	a1,a1,-1388 # 80008870 <syscalls+0x340>
    80005de4:	0001f517          	auipc	a0,0x1f
    80005de8:	34450513          	addi	a0,a0,836 # 80025128 <disk+0x2128>
    80005dec:	ffffb097          	auipc	ra,0xffffb
    80005df0:	d46080e7          	jalr	-698(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005df4:	100017b7          	lui	a5,0x10001
    80005df8:	4398                	lw	a4,0(a5)
    80005dfa:	2701                	sext.w	a4,a4
    80005dfc:	747277b7          	lui	a5,0x74727
    80005e00:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e04:	0ef71163          	bne	a4,a5,80005ee6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e08:	100017b7          	lui	a5,0x10001
    80005e0c:	43dc                	lw	a5,4(a5)
    80005e0e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e10:	4705                	li	a4,1
    80005e12:	0ce79a63          	bne	a5,a4,80005ee6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e16:	100017b7          	lui	a5,0x10001
    80005e1a:	479c                	lw	a5,8(a5)
    80005e1c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e1e:	4709                	li	a4,2
    80005e20:	0ce79363          	bne	a5,a4,80005ee6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e24:	100017b7          	lui	a5,0x10001
    80005e28:	47d8                	lw	a4,12(a5)
    80005e2a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2c:	554d47b7          	lui	a5,0x554d4
    80005e30:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e34:	0af71963          	bne	a4,a5,80005ee6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e38:	100017b7          	lui	a5,0x10001
    80005e3c:	4705                	li	a4,1
    80005e3e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e40:	470d                	li	a4,3
    80005e42:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e44:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e46:	c7ffe737          	lui	a4,0xc7ffe
    80005e4a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e4e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e50:	2701                	sext.w	a4,a4
    80005e52:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e54:	472d                	li	a4,11
    80005e56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e58:	473d                	li	a4,15
    80005e5a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e5c:	6705                	lui	a4,0x1
    80005e5e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e60:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e64:	5bdc                	lw	a5,52(a5)
    80005e66:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e68:	c7d9                	beqz	a5,80005ef6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e6a:	471d                	li	a4,7
    80005e6c:	08f77d63          	bgeu	a4,a5,80005f06 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e70:	100014b7          	lui	s1,0x10001
    80005e74:	47a1                	li	a5,8
    80005e76:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e78:	6609                	lui	a2,0x2
    80005e7a:	4581                	li	a1,0
    80005e7c:	0001d517          	auipc	a0,0x1d
    80005e80:	18450513          	addi	a0,a0,388 # 80023000 <disk>
    80005e84:	ffffb097          	auipc	ra,0xffffb
    80005e88:	e3a080e7          	jalr	-454(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e8c:	0001d717          	auipc	a4,0x1d
    80005e90:	17470713          	addi	a4,a4,372 # 80023000 <disk>
    80005e94:	00c75793          	srli	a5,a4,0xc
    80005e98:	2781                	sext.w	a5,a5
    80005e9a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e9c:	0001f797          	auipc	a5,0x1f
    80005ea0:	16478793          	addi	a5,a5,356 # 80025000 <disk+0x2000>
    80005ea4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ea6:	0001d717          	auipc	a4,0x1d
    80005eaa:	1da70713          	addi	a4,a4,474 # 80023080 <disk+0x80>
    80005eae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005eb0:	0001e717          	auipc	a4,0x1e
    80005eb4:	15070713          	addi	a4,a4,336 # 80024000 <disk+0x1000>
    80005eb8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eba:	4705                	li	a4,1
    80005ebc:	00e78c23          	sb	a4,24(a5)
    80005ec0:	00e78ca3          	sb	a4,25(a5)
    80005ec4:	00e78d23          	sb	a4,26(a5)
    80005ec8:	00e78da3          	sb	a4,27(a5)
    80005ecc:	00e78e23          	sb	a4,28(a5)
    80005ed0:	00e78ea3          	sb	a4,29(a5)
    80005ed4:	00e78f23          	sb	a4,30(a5)
    80005ed8:	00e78fa3          	sb	a4,31(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret
    panic("could not find virtio disk");
    80005ee6:	00003517          	auipc	a0,0x3
    80005eea:	99a50513          	addi	a0,a0,-1638 # 80008880 <syscalls+0x350>
    80005eee:	ffffa097          	auipc	ra,0xffffa
    80005ef2:	63c080e7          	jalr	1596(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005ef6:	00003517          	auipc	a0,0x3
    80005efa:	9aa50513          	addi	a0,a0,-1622 # 800088a0 <syscalls+0x370>
    80005efe:	ffffa097          	auipc	ra,0xffffa
    80005f02:	62c080e7          	jalr	1580(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005f06:	00003517          	auipc	a0,0x3
    80005f0a:	9ba50513          	addi	a0,a0,-1606 # 800088c0 <syscalls+0x390>
    80005f0e:	ffffa097          	auipc	ra,0xffffa
    80005f12:	61c080e7          	jalr	1564(ra) # 8000052a <panic>

0000000080005f16 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f16:	7119                	addi	sp,sp,-128
    80005f18:	fc86                	sd	ra,120(sp)
    80005f1a:	f8a2                	sd	s0,112(sp)
    80005f1c:	f4a6                	sd	s1,104(sp)
    80005f1e:	f0ca                	sd	s2,96(sp)
    80005f20:	ecce                	sd	s3,88(sp)
    80005f22:	e8d2                	sd	s4,80(sp)
    80005f24:	e4d6                	sd	s5,72(sp)
    80005f26:	e0da                	sd	s6,64(sp)
    80005f28:	fc5e                	sd	s7,56(sp)
    80005f2a:	f862                	sd	s8,48(sp)
    80005f2c:	f466                	sd	s9,40(sp)
    80005f2e:	f06a                	sd	s10,32(sp)
    80005f30:	ec6e                	sd	s11,24(sp)
    80005f32:	0100                	addi	s0,sp,128
    80005f34:	8aaa                	mv	s5,a0
    80005f36:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f38:	00c52c83          	lw	s9,12(a0)
    80005f3c:	001c9c9b          	slliw	s9,s9,0x1
    80005f40:	1c82                	slli	s9,s9,0x20
    80005f42:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f46:	0001f517          	auipc	a0,0x1f
    80005f4a:	1e250513          	addi	a0,a0,482 # 80025128 <disk+0x2128>
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	c74080e7          	jalr	-908(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005f56:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f58:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f5a:	0001dc17          	auipc	s8,0x1d
    80005f5e:	0a6c0c13          	addi	s8,s8,166 # 80023000 <disk>
    80005f62:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f64:	4b0d                	li	s6,3
    80005f66:	a0ad                	j	80005fd0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f68:	00fc0733          	add	a4,s8,a5
    80005f6c:	975e                	add	a4,a4,s7
    80005f6e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f72:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f74:	0207c563          	bltz	a5,80005f9e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f78:	2905                	addiw	s2,s2,1
    80005f7a:	0611                	addi	a2,a2,4
    80005f7c:	19690d63          	beq	s2,s6,80006116 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f80:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f82:	0001f717          	auipc	a4,0x1f
    80005f86:	09670713          	addi	a4,a4,150 # 80025018 <disk+0x2018>
    80005f8a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f8c:	00074683          	lbu	a3,0(a4)
    80005f90:	fee1                	bnez	a3,80005f68 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f92:	2785                	addiw	a5,a5,1
    80005f94:	0705                	addi	a4,a4,1
    80005f96:	fe979be3          	bne	a5,s1,80005f8c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f9a:	57fd                	li	a5,-1
    80005f9c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f9e:	01205d63          	blez	s2,80005fb8 <virtio_disk_rw+0xa2>
    80005fa2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fa4:	000a2503          	lw	a0,0(s4)
    80005fa8:	00000097          	auipc	ra,0x0
    80005fac:	d8e080e7          	jalr	-626(ra) # 80005d36 <free_desc>
      for(int j = 0; j < i; j++)
    80005fb0:	2d85                	addiw	s11,s11,1
    80005fb2:	0a11                	addi	s4,s4,4
    80005fb4:	ffb918e3          	bne	s2,s11,80005fa4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fb8:	0001f597          	auipc	a1,0x1f
    80005fbc:	17058593          	addi	a1,a1,368 # 80025128 <disk+0x2128>
    80005fc0:	0001f517          	auipc	a0,0x1f
    80005fc4:	05850513          	addi	a0,a0,88 # 80025018 <disk+0x2018>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	082080e7          	jalr	130(ra) # 8000204a <sleep>
  for(int i = 0; i < 3; i++){
    80005fd0:	f8040a13          	addi	s4,s0,-128
{
    80005fd4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fd6:	894e                	mv	s2,s3
    80005fd8:	b765                	j	80005f80 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fda:	0001f697          	auipc	a3,0x1f
    80005fde:	0266b683          	ld	a3,38(a3) # 80025000 <disk+0x2000>
    80005fe2:	96ba                	add	a3,a3,a4
    80005fe4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fe8:	0001d817          	auipc	a6,0x1d
    80005fec:	01880813          	addi	a6,a6,24 # 80023000 <disk>
    80005ff0:	0001f697          	auipc	a3,0x1f
    80005ff4:	01068693          	addi	a3,a3,16 # 80025000 <disk+0x2000>
    80005ff8:	6290                	ld	a2,0(a3)
    80005ffa:	963a                	add	a2,a2,a4
    80005ffc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006000:	0015e593          	ori	a1,a1,1
    80006004:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006008:	f8842603          	lw	a2,-120(s0)
    8000600c:	628c                	ld	a1,0(a3)
    8000600e:	972e                	add	a4,a4,a1
    80006010:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006014:	20050593          	addi	a1,a0,512
    80006018:	0592                	slli	a1,a1,0x4
    8000601a:	95c2                	add	a1,a1,a6
    8000601c:	577d                	li	a4,-1
    8000601e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006022:	00461713          	slli	a4,a2,0x4
    80006026:	6290                	ld	a2,0(a3)
    80006028:	963a                	add	a2,a2,a4
    8000602a:	03078793          	addi	a5,a5,48
    8000602e:	97c2                	add	a5,a5,a6
    80006030:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006032:	629c                	ld	a5,0(a3)
    80006034:	97ba                	add	a5,a5,a4
    80006036:	4605                	li	a2,1
    80006038:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000603a:	629c                	ld	a5,0(a3)
    8000603c:	97ba                	add	a5,a5,a4
    8000603e:	4809                	li	a6,2
    80006040:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006044:	629c                	ld	a5,0(a3)
    80006046:	973e                	add	a4,a4,a5
    80006048:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000604c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006050:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006054:	6698                	ld	a4,8(a3)
    80006056:	00275783          	lhu	a5,2(a4)
    8000605a:	8b9d                	andi	a5,a5,7
    8000605c:	0786                	slli	a5,a5,0x1
    8000605e:	97ba                	add	a5,a5,a4
    80006060:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006064:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006068:	6698                	ld	a4,8(a3)
    8000606a:	00275783          	lhu	a5,2(a4)
    8000606e:	2785                	addiw	a5,a5,1
    80006070:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006074:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006078:	100017b7          	lui	a5,0x10001
    8000607c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006080:	004aa783          	lw	a5,4(s5)
    80006084:	02c79163          	bne	a5,a2,800060a6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006088:	0001f917          	auipc	s2,0x1f
    8000608c:	0a090913          	addi	s2,s2,160 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006090:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006092:	85ca                	mv	a1,s2
    80006094:	8556                	mv	a0,s5
    80006096:	ffffc097          	auipc	ra,0xffffc
    8000609a:	fb4080e7          	jalr	-76(ra) # 8000204a <sleep>
  while(b->disk == 1) {
    8000609e:	004aa783          	lw	a5,4(s5)
    800060a2:	fe9788e3          	beq	a5,s1,80006092 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060a6:	f8042903          	lw	s2,-128(s0)
    800060aa:	20090793          	addi	a5,s2,512
    800060ae:	00479713          	slli	a4,a5,0x4
    800060b2:	0001d797          	auipc	a5,0x1d
    800060b6:	f4e78793          	addi	a5,a5,-178 # 80023000 <disk>
    800060ba:	97ba                	add	a5,a5,a4
    800060bc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060c0:	0001f997          	auipc	s3,0x1f
    800060c4:	f4098993          	addi	s3,s3,-192 # 80025000 <disk+0x2000>
    800060c8:	00491713          	slli	a4,s2,0x4
    800060cc:	0009b783          	ld	a5,0(s3)
    800060d0:	97ba                	add	a5,a5,a4
    800060d2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060d6:	854a                	mv	a0,s2
    800060d8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060dc:	00000097          	auipc	ra,0x0
    800060e0:	c5a080e7          	jalr	-934(ra) # 80005d36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060e4:	8885                	andi	s1,s1,1
    800060e6:	f0ed                	bnez	s1,800060c8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060e8:	0001f517          	auipc	a0,0x1f
    800060ec:	04050513          	addi	a0,a0,64 # 80025128 <disk+0x2128>
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	b86080e7          	jalr	-1146(ra) # 80000c76 <release>
}
    800060f8:	70e6                	ld	ra,120(sp)
    800060fa:	7446                	ld	s0,112(sp)
    800060fc:	74a6                	ld	s1,104(sp)
    800060fe:	7906                	ld	s2,96(sp)
    80006100:	69e6                	ld	s3,88(sp)
    80006102:	6a46                	ld	s4,80(sp)
    80006104:	6aa6                	ld	s5,72(sp)
    80006106:	6b06                	ld	s6,64(sp)
    80006108:	7be2                	ld	s7,56(sp)
    8000610a:	7c42                	ld	s8,48(sp)
    8000610c:	7ca2                	ld	s9,40(sp)
    8000610e:	7d02                	ld	s10,32(sp)
    80006110:	6de2                	ld	s11,24(sp)
    80006112:	6109                	addi	sp,sp,128
    80006114:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006116:	f8042503          	lw	a0,-128(s0)
    8000611a:	20050793          	addi	a5,a0,512
    8000611e:	0792                	slli	a5,a5,0x4
  if(write)
    80006120:	0001d817          	auipc	a6,0x1d
    80006124:	ee080813          	addi	a6,a6,-288 # 80023000 <disk>
    80006128:	00f80733          	add	a4,a6,a5
    8000612c:	01a036b3          	snez	a3,s10
    80006130:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006134:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006138:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000613c:	7679                	lui	a2,0xffffe
    8000613e:	963e                	add	a2,a2,a5
    80006140:	0001f697          	auipc	a3,0x1f
    80006144:	ec068693          	addi	a3,a3,-320 # 80025000 <disk+0x2000>
    80006148:	6298                	ld	a4,0(a3)
    8000614a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000614c:	0a878593          	addi	a1,a5,168
    80006150:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006152:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006154:	6298                	ld	a4,0(a3)
    80006156:	9732                	add	a4,a4,a2
    80006158:	45c1                	li	a1,16
    8000615a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000615c:	6298                	ld	a4,0(a3)
    8000615e:	9732                	add	a4,a4,a2
    80006160:	4585                	li	a1,1
    80006162:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006166:	f8442703          	lw	a4,-124(s0)
    8000616a:	628c                	ld	a1,0(a3)
    8000616c:	962e                	add	a2,a2,a1
    8000616e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006172:	0712                	slli	a4,a4,0x4
    80006174:	6290                	ld	a2,0(a3)
    80006176:	963a                	add	a2,a2,a4
    80006178:	058a8593          	addi	a1,s5,88
    8000617c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000617e:	6294                	ld	a3,0(a3)
    80006180:	96ba                	add	a3,a3,a4
    80006182:	40000613          	li	a2,1024
    80006186:	c690                	sw	a2,8(a3)
  if(write)
    80006188:	e40d19e3          	bnez	s10,80005fda <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000618c:	0001f697          	auipc	a3,0x1f
    80006190:	e746b683          	ld	a3,-396(a3) # 80025000 <disk+0x2000>
    80006194:	96ba                	add	a3,a3,a4
    80006196:	4609                	li	a2,2
    80006198:	00c69623          	sh	a2,12(a3)
    8000619c:	b5b1                	j	80005fe8 <virtio_disk_rw+0xd2>

000000008000619e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000619e:	1101                	addi	sp,sp,-32
    800061a0:	ec06                	sd	ra,24(sp)
    800061a2:	e822                	sd	s0,16(sp)
    800061a4:	e426                	sd	s1,8(sp)
    800061a6:	e04a                	sd	s2,0(sp)
    800061a8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061aa:	0001f517          	auipc	a0,0x1f
    800061ae:	f7e50513          	addi	a0,a0,-130 # 80025128 <disk+0x2128>
    800061b2:	ffffb097          	auipc	ra,0xffffb
    800061b6:	a10080e7          	jalr	-1520(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061ba:	10001737          	lui	a4,0x10001
    800061be:	533c                	lw	a5,96(a4)
    800061c0:	8b8d                	andi	a5,a5,3
    800061c2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061c4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061c8:	0001f797          	auipc	a5,0x1f
    800061cc:	e3878793          	addi	a5,a5,-456 # 80025000 <disk+0x2000>
    800061d0:	6b94                	ld	a3,16(a5)
    800061d2:	0207d703          	lhu	a4,32(a5)
    800061d6:	0026d783          	lhu	a5,2(a3)
    800061da:	06f70163          	beq	a4,a5,8000623c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061de:	0001d917          	auipc	s2,0x1d
    800061e2:	e2290913          	addi	s2,s2,-478 # 80023000 <disk>
    800061e6:	0001f497          	auipc	s1,0x1f
    800061ea:	e1a48493          	addi	s1,s1,-486 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061ee:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061f2:	6898                	ld	a4,16(s1)
    800061f4:	0204d783          	lhu	a5,32(s1)
    800061f8:	8b9d                	andi	a5,a5,7
    800061fa:	078e                	slli	a5,a5,0x3
    800061fc:	97ba                	add	a5,a5,a4
    800061fe:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006200:	20078713          	addi	a4,a5,512
    80006204:	0712                	slli	a4,a4,0x4
    80006206:	974a                	add	a4,a4,s2
    80006208:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000620c:	e731                	bnez	a4,80006258 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000620e:	20078793          	addi	a5,a5,512
    80006212:	0792                	slli	a5,a5,0x4
    80006214:	97ca                	add	a5,a5,s2
    80006216:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006218:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000621c:	ffffc097          	auipc	ra,0xffffc
    80006220:	fba080e7          	jalr	-70(ra) # 800021d6 <wakeup>

    disk.used_idx += 1;
    80006224:	0204d783          	lhu	a5,32(s1)
    80006228:	2785                	addiw	a5,a5,1
    8000622a:	17c2                	slli	a5,a5,0x30
    8000622c:	93c1                	srli	a5,a5,0x30
    8000622e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006232:	6898                	ld	a4,16(s1)
    80006234:	00275703          	lhu	a4,2(a4)
    80006238:	faf71be3          	bne	a4,a5,800061ee <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000623c:	0001f517          	auipc	a0,0x1f
    80006240:	eec50513          	addi	a0,a0,-276 # 80025128 <disk+0x2128>
    80006244:	ffffb097          	auipc	ra,0xffffb
    80006248:	a32080e7          	jalr	-1486(ra) # 80000c76 <release>
}
    8000624c:	60e2                	ld	ra,24(sp)
    8000624e:	6442                	ld	s0,16(sp)
    80006250:	64a2                	ld	s1,8(sp)
    80006252:	6902                	ld	s2,0(sp)
    80006254:	6105                	addi	sp,sp,32
    80006256:	8082                	ret
      panic("virtio_disk_intr status");
    80006258:	00002517          	auipc	a0,0x2
    8000625c:	68850513          	addi	a0,a0,1672 # 800088e0 <syscalls+0x3b0>
    80006260:	ffffa097          	auipc	ra,0xffffa
    80006264:	2ca080e7          	jalr	714(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
