
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
    80000068:	bec78793          	addi	a5,a5,-1044 # 80005c50 <timervec>
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
    80000122:	36e080e7          	jalr	878(ra) # 8000248c <either_copyin>
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
    80000202:	238080e7          	jalr	568(ra) # 80002436 <either_copyout>
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
    800002e2:	204080e7          	jalr	516(ra) # 800024e2 <procdump>
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
    80000eb6:	772080e7          	jalr	1906(ra) # 80002624 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	dd6080e7          	jalr	-554(ra) # 80005c90 <plicinithart>
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
    80000f2e:	6d2080e7          	jalr	1746(ra) # 800025fc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	6f2080e7          	jalr	1778(ra) # 80002624 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	d40080e7          	jalr	-704(ra) # 80005c7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	d4e080e7          	jalr	-690(ra) # 80005c90 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	f1e080e7          	jalr	-226(ra) # 80002e68 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	5b0080e7          	jalr	1456(ra) # 80003502 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	55e080e7          	jalr	1374(ra) # 800044b8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e50080e7          	jalr	-432(ra) # 80005db2 <virtio_disk_init>
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
    800019dc:	c64080e7          	jalr	-924(ra) # 8000263c <usertrapret>
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
    800019f6:	a90080e7          	jalr	-1392(ra) # 80003482 <fsinit>
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
    80001cbc:	1f8080e7          	jalr	504(ra) # 80003eb0 <namei>
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
    80001e0c:	742080e7          	jalr	1858(ra) # 8000454a <filedup>
    80001e10:	00a93023          	sd	a0,0(s2)
    80001e14:	b7e5                	j	80001dfc <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e16:	150ab503          	ld	a0,336(s5)
    80001e1a:	00002097          	auipc	ra,0x2
    80001e1e:	8a2080e7          	jalr	-1886(ra) # 800036bc <idup>
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
    80001f2e:	668080e7          	jalr	1640(ra) # 80002592 <swtch>
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
    80001fb0:	5e6080e7          	jalr	1510(ra) # 80002592 <swtch>
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
    800022ea:	2b6080e7          	jalr	694(ra) # 8000459c <fileclose>
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
    80002302:	dd2080e7          	jalr	-558(ra) # 800040d0 <begin_op>
  iput(p->cwd);
    80002306:	1509b503          	ld	a0,336(s3)
    8000230a:	00001097          	auipc	ra,0x1
    8000230e:	5aa080e7          	jalr	1450(ra) # 800038b4 <iput>
  end_op();
    80002312:	00002097          	auipc	ra,0x2
    80002316:	e3e080e7          	jalr	-450(ra) # 80004150 <end_op>
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
    80002388:	1800                	addi	s0,sp,48
    8000238a:	89aa                	mv	s3,a0
    8000238c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	5f0080e7          	jalr	1520(ra) # 8000197e <myproc>
    80002396:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	82a080e7          	jalr	-2006(ra) # 80000bc2 <acquire>
  if(p->pid == pid)
    800023a0:	589c                	lw	a5,48(s1)
    800023a2:	01278e63          	beq	a5,s2,800023be <trace+0x42>
    p->mask = mask_input;
  release(&p->lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8ce080e7          	jalr	-1842(ra) # 80000c76 <release>
}
    800023b0:	70a2                	ld	ra,40(sp)
    800023b2:	7402                	ld	s0,32(sp)
    800023b4:	64e2                	ld	s1,24(sp)
    800023b6:	6942                	ld	s2,16(sp)
    800023b8:	69a2                	ld	s3,8(sp)
    800023ba:	6145                	addi	sp,sp,48
    800023bc:	8082                	ret
    p->mask = mask_input;
    800023be:	0334aa23          	sw	s3,52(s1)
    800023c2:	b7d5                	j	800023a6 <trace+0x2a>

00000000800023c4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023c4:	7179                	addi	sp,sp,-48
    800023c6:	f406                	sd	ra,40(sp)
    800023c8:	f022                	sd	s0,32(sp)
    800023ca:	ec26                	sd	s1,24(sp)
    800023cc:	e84a                	sd	s2,16(sp)
    800023ce:	e44e                	sd	s3,8(sp)
    800023d0:	1800                	addi	s0,sp,48
    800023d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023d4:	0000f497          	auipc	s1,0xf
    800023d8:	2fc48493          	addi	s1,s1,764 # 800116d0 <proc>
    800023dc:	00015997          	auipc	s3,0x15
    800023e0:	cf498993          	addi	s3,s3,-780 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	ffffe097          	auipc	ra,0xffffe
    800023ea:	7dc080e7          	jalr	2012(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023ee:	589c                	lw	a5,48(s1)
    800023f0:	01278d63          	beq	a5,s2,8000240a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	880080e7          	jalr	-1920(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	ff3491e3          	bne	s1,s3,800023e4 <kill+0x20>
  }
  return -1;
    80002406:	557d                	li	a0,-1
    80002408:	a829                	j	80002422 <kill+0x5e>
      p->killed = 1;
    8000240a:	4785                	li	a5,1
    8000240c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000240e:	4c98                	lw	a4,24(s1)
    80002410:	4789                	li	a5,2
    80002412:	00f70f63          	beq	a4,a5,80002430 <kill+0x6c>
      release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	85e080e7          	jalr	-1954(ra) # 80000c76 <release>
      return 0;
    80002420:	4501                	li	a0,0
}
    80002422:	70a2                	ld	ra,40(sp)
    80002424:	7402                	ld	s0,32(sp)
    80002426:	64e2                	ld	s1,24(sp)
    80002428:	6942                	ld	s2,16(sp)
    8000242a:	69a2                	ld	s3,8(sp)
    8000242c:	6145                	addi	sp,sp,48
    8000242e:	8082                	ret
        p->state = RUNNABLE;
    80002430:	478d                	li	a5,3
    80002432:	cc9c                	sw	a5,24(s1)
    80002434:	b7cd                	j	80002416 <kill+0x52>

0000000080002436 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002436:	7179                	addi	sp,sp,-48
    80002438:	f406                	sd	ra,40(sp)
    8000243a:	f022                	sd	s0,32(sp)
    8000243c:	ec26                	sd	s1,24(sp)
    8000243e:	e84a                	sd	s2,16(sp)
    80002440:	e44e                	sd	s3,8(sp)
    80002442:	e052                	sd	s4,0(sp)
    80002444:	1800                	addi	s0,sp,48
    80002446:	84aa                	mv	s1,a0
    80002448:	892e                	mv	s2,a1
    8000244a:	89b2                	mv	s3,a2
    8000244c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	530080e7          	jalr	1328(ra) # 8000197e <myproc>
  if(user_dst){
    80002456:	c08d                	beqz	s1,80002478 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002458:	86d2                	mv	a3,s4
    8000245a:	864e                	mv	a2,s3
    8000245c:	85ca                	mv	a1,s2
    8000245e:	6928                	ld	a0,80(a0)
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	1de080e7          	jalr	478(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002468:	70a2                	ld	ra,40(sp)
    8000246a:	7402                	ld	s0,32(sp)
    8000246c:	64e2                	ld	s1,24(sp)
    8000246e:	6942                	ld	s2,16(sp)
    80002470:	69a2                	ld	s3,8(sp)
    80002472:	6a02                	ld	s4,0(sp)
    80002474:	6145                	addi	sp,sp,48
    80002476:	8082                	ret
    memmove((char *)dst, src, len);
    80002478:	000a061b          	sext.w	a2,s4
    8000247c:	85ce                	mv	a1,s3
    8000247e:	854a                	mv	a0,s2
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	89a080e7          	jalr	-1894(ra) # 80000d1a <memmove>
    return 0;
    80002488:	8526                	mv	a0,s1
    8000248a:	bff9                	j	80002468 <either_copyout+0x32>

000000008000248c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000248c:	7179                	addi	sp,sp,-48
    8000248e:	f406                	sd	ra,40(sp)
    80002490:	f022                	sd	s0,32(sp)
    80002492:	ec26                	sd	s1,24(sp)
    80002494:	e84a                	sd	s2,16(sp)
    80002496:	e44e                	sd	s3,8(sp)
    80002498:	e052                	sd	s4,0(sp)
    8000249a:	1800                	addi	s0,sp,48
    8000249c:	892a                	mv	s2,a0
    8000249e:	84ae                	mv	s1,a1
    800024a0:	89b2                	mv	s3,a2
    800024a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	4da080e7          	jalr	1242(ra) # 8000197e <myproc>
  if(user_src){
    800024ac:	c08d                	beqz	s1,800024ce <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ae:	86d2                	mv	a3,s4
    800024b0:	864e                	mv	a2,s3
    800024b2:	85ca                	mv	a1,s2
    800024b4:	6928                	ld	a0,80(a0)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	214080e7          	jalr	532(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024be:	70a2                	ld	ra,40(sp)
    800024c0:	7402                	ld	s0,32(sp)
    800024c2:	64e2                	ld	s1,24(sp)
    800024c4:	6942                	ld	s2,16(sp)
    800024c6:	69a2                	ld	s3,8(sp)
    800024c8:	6a02                	ld	s4,0(sp)
    800024ca:	6145                	addi	sp,sp,48
    800024cc:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ce:	000a061b          	sext.w	a2,s4
    800024d2:	85ce                	mv	a1,s3
    800024d4:	854a                	mv	a0,s2
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	844080e7          	jalr	-1980(ra) # 80000d1a <memmove>
    return 0;
    800024de:	8526                	mv	a0,s1
    800024e0:	bff9                	j	800024be <either_copyin+0x32>

00000000800024e2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024e2:	715d                	addi	sp,sp,-80
    800024e4:	e486                	sd	ra,72(sp)
    800024e6:	e0a2                	sd	s0,64(sp)
    800024e8:	fc26                	sd	s1,56(sp)
    800024ea:	f84a                	sd	s2,48(sp)
    800024ec:	f44e                	sd	s3,40(sp)
    800024ee:	f052                	sd	s4,32(sp)
    800024f0:	ec56                	sd	s5,24(sp)
    800024f2:	e85a                	sd	s6,16(sp)
    800024f4:	e45e                	sd	s7,8(sp)
    800024f6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024f8:	00006517          	auipc	a0,0x6
    800024fc:	bd050513          	addi	a0,a0,-1072 # 800080c8 <digits+0x88>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	074080e7          	jalr	116(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002508:	0000f497          	auipc	s1,0xf
    8000250c:	32048493          	addi	s1,s1,800 # 80011828 <proc+0x158>
    80002510:	00015917          	auipc	s2,0x15
    80002514:	d1890913          	addi	s2,s2,-744 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002518:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000251a:	00006997          	auipc	s3,0x6
    8000251e:	d4e98993          	addi	s3,s3,-690 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002522:	00006a97          	auipc	s5,0x6
    80002526:	d4ea8a93          	addi	s5,s5,-690 # 80008270 <digits+0x230>
    printf("\n");
    8000252a:	00006a17          	auipc	s4,0x6
    8000252e:	b9ea0a13          	addi	s4,s4,-1122 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002532:	00006b97          	auipc	s7,0x6
    80002536:	d76b8b93          	addi	s7,s7,-650 # 800082a8 <states.0>
    8000253a:	a00d                	j	8000255c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000253c:	ed86a583          	lw	a1,-296(a3)
    80002540:	8556                	mv	a0,s5
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	032080e7          	jalr	50(ra) # 80000574 <printf>
    printf("\n");
    8000254a:	8552                	mv	a0,s4
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	028080e7          	jalr	40(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002554:	16848493          	addi	s1,s1,360
    80002558:	03248263          	beq	s1,s2,8000257c <procdump+0x9a>
    if(p->state == UNUSED)
    8000255c:	86a6                	mv	a3,s1
    8000255e:	ec04a783          	lw	a5,-320(s1)
    80002562:	dbed                	beqz	a5,80002554 <procdump+0x72>
      state = "???";
    80002564:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002566:	fcfb6be3          	bltu	s6,a5,8000253c <procdump+0x5a>
    8000256a:	02079713          	slli	a4,a5,0x20
    8000256e:	01d75793          	srli	a5,a4,0x1d
    80002572:	97de                	add	a5,a5,s7
    80002574:	6390                	ld	a2,0(a5)
    80002576:	f279                	bnez	a2,8000253c <procdump+0x5a>
      state = "???";
    80002578:	864e                	mv	a2,s3
    8000257a:	b7c9                	j	8000253c <procdump+0x5a>
  }
}
    8000257c:	60a6                	ld	ra,72(sp)
    8000257e:	6406                	ld	s0,64(sp)
    80002580:	74e2                	ld	s1,56(sp)
    80002582:	7942                	ld	s2,48(sp)
    80002584:	79a2                	ld	s3,40(sp)
    80002586:	7a02                	ld	s4,32(sp)
    80002588:	6ae2                	ld	s5,24(sp)
    8000258a:	6b42                	ld	s6,16(sp)
    8000258c:	6ba2                	ld	s7,8(sp)
    8000258e:	6161                	addi	sp,sp,80
    80002590:	8082                	ret

0000000080002592 <swtch>:
    80002592:	00153023          	sd	ra,0(a0)
    80002596:	00253423          	sd	sp,8(a0)
    8000259a:	e900                	sd	s0,16(a0)
    8000259c:	ed04                	sd	s1,24(a0)
    8000259e:	03253023          	sd	s2,32(a0)
    800025a2:	03353423          	sd	s3,40(a0)
    800025a6:	03453823          	sd	s4,48(a0)
    800025aa:	03553c23          	sd	s5,56(a0)
    800025ae:	05653023          	sd	s6,64(a0)
    800025b2:	05753423          	sd	s7,72(a0)
    800025b6:	05853823          	sd	s8,80(a0)
    800025ba:	05953c23          	sd	s9,88(a0)
    800025be:	07a53023          	sd	s10,96(a0)
    800025c2:	07b53423          	sd	s11,104(a0)
    800025c6:	0005b083          	ld	ra,0(a1)
    800025ca:	0085b103          	ld	sp,8(a1)
    800025ce:	6980                	ld	s0,16(a1)
    800025d0:	6d84                	ld	s1,24(a1)
    800025d2:	0205b903          	ld	s2,32(a1)
    800025d6:	0285b983          	ld	s3,40(a1)
    800025da:	0305ba03          	ld	s4,48(a1)
    800025de:	0385ba83          	ld	s5,56(a1)
    800025e2:	0405bb03          	ld	s6,64(a1)
    800025e6:	0485bb83          	ld	s7,72(a1)
    800025ea:	0505bc03          	ld	s8,80(a1)
    800025ee:	0585bc83          	ld	s9,88(a1)
    800025f2:	0605bd03          	ld	s10,96(a1)
    800025f6:	0685bd83          	ld	s11,104(a1)
    800025fa:	8082                	ret

00000000800025fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025fc:	1141                	addi	sp,sp,-16
    800025fe:	e406                	sd	ra,8(sp)
    80002600:	e022                	sd	s0,0(sp)
    80002602:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002604:	00006597          	auipc	a1,0x6
    80002608:	cd458593          	addi	a1,a1,-812 # 800082d8 <states.0+0x30>
    8000260c:	00015517          	auipc	a0,0x15
    80002610:	ac450513          	addi	a0,a0,-1340 # 800170d0 <tickslock>
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	51e080e7          	jalr	1310(ra) # 80000b32 <initlock>
}
    8000261c:	60a2                	ld	ra,8(sp)
    8000261e:	6402                	ld	s0,0(sp)
    80002620:	0141                	addi	sp,sp,16
    80002622:	8082                	ret

0000000080002624 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002624:	1141                	addi	sp,sp,-16
    80002626:	e422                	sd	s0,8(sp)
    80002628:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000262a:	00003797          	auipc	a5,0x3
    8000262e:	59678793          	addi	a5,a5,1430 # 80005bc0 <kernelvec>
    80002632:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002636:	6422                	ld	s0,8(sp)
    80002638:	0141                	addi	sp,sp,16
    8000263a:	8082                	ret

000000008000263c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000263c:	1141                	addi	sp,sp,-16
    8000263e:	e406                	sd	ra,8(sp)
    80002640:	e022                	sd	s0,0(sp)
    80002642:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	33a080e7          	jalr	826(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002650:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002652:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002656:	00005617          	auipc	a2,0x5
    8000265a:	9aa60613          	addi	a2,a2,-1622 # 80007000 <_trampoline>
    8000265e:	00005697          	auipc	a3,0x5
    80002662:	9a268693          	addi	a3,a3,-1630 # 80007000 <_trampoline>
    80002666:	8e91                	sub	a3,a3,a2
    80002668:	040007b7          	lui	a5,0x4000
    8000266c:	17fd                	addi	a5,a5,-1
    8000266e:	07b2                	slli	a5,a5,0xc
    80002670:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002672:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002676:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002678:	180026f3          	csrr	a3,satp
    8000267c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000267e:	6d38                	ld	a4,88(a0)
    80002680:	6134                	ld	a3,64(a0)
    80002682:	6585                	lui	a1,0x1
    80002684:	96ae                	add	a3,a3,a1
    80002686:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002688:	6d38                	ld	a4,88(a0)
    8000268a:	00000697          	auipc	a3,0x0
    8000268e:	13868693          	addi	a3,a3,312 # 800027c2 <usertrap>
    80002692:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002694:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002696:	8692                	mv	a3,tp
    80002698:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000269a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000269e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026a2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ac:	6f18                	ld	a4,24(a4)
    800026ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026b2:	692c                	ld	a1,80(a0)
    800026b4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026b6:	00005717          	auipc	a4,0x5
    800026ba:	9da70713          	addi	a4,a4,-1574 # 80007090 <userret>
    800026be:	8f11                	sub	a4,a4,a2
    800026c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026c2:	577d                	li	a4,-1
    800026c4:	177e                	slli	a4,a4,0x3f
    800026c6:	8dd9                	or	a1,a1,a4
    800026c8:	02000537          	lui	a0,0x2000
    800026cc:	157d                	addi	a0,a0,-1
    800026ce:	0536                	slli	a0,a0,0xd
    800026d0:	9782                	jalr	a5
}
    800026d2:	60a2                	ld	ra,8(sp)
    800026d4:	6402                	ld	s0,0(sp)
    800026d6:	0141                	addi	sp,sp,16
    800026d8:	8082                	ret

00000000800026da <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026da:	1101                	addi	sp,sp,-32
    800026dc:	ec06                	sd	ra,24(sp)
    800026de:	e822                	sd	s0,16(sp)
    800026e0:	e426                	sd	s1,8(sp)
    800026e2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026e4:	00015497          	auipc	s1,0x15
    800026e8:	9ec48493          	addi	s1,s1,-1556 # 800170d0 <tickslock>
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	4d4080e7          	jalr	1236(ra) # 80000bc2 <acquire>
  ticks++;
    800026f6:	00007517          	auipc	a0,0x7
    800026fa:	93a50513          	addi	a0,a0,-1734 # 80009030 <ticks>
    800026fe:	411c                	lw	a5,0(a0)
    80002700:	2785                	addiw	a5,a5,1
    80002702:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002704:	00000097          	auipc	ra,0x0
    80002708:	ad2080e7          	jalr	-1326(ra) # 800021d6 <wakeup>
  release(&tickslock);
    8000270c:	8526                	mv	a0,s1
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	568080e7          	jalr	1384(ra) # 80000c76 <release>
}
    80002716:	60e2                	ld	ra,24(sp)
    80002718:	6442                	ld	s0,16(sp)
    8000271a:	64a2                	ld	s1,8(sp)
    8000271c:	6105                	addi	sp,sp,32
    8000271e:	8082                	ret

0000000080002720 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002720:	1101                	addi	sp,sp,-32
    80002722:	ec06                	sd	ra,24(sp)
    80002724:	e822                	sd	s0,16(sp)
    80002726:	e426                	sd	s1,8(sp)
    80002728:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000272a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000272e:	00074d63          	bltz	a4,80002748 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002732:	57fd                	li	a5,-1
    80002734:	17fe                	slli	a5,a5,0x3f
    80002736:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002738:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000273a:	06f70363          	beq	a4,a5,800027a0 <devintr+0x80>
  }
}
    8000273e:	60e2                	ld	ra,24(sp)
    80002740:	6442                	ld	s0,16(sp)
    80002742:	64a2                	ld	s1,8(sp)
    80002744:	6105                	addi	sp,sp,32
    80002746:	8082                	ret
     (scause & 0xff) == 9){
    80002748:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000274c:	46a5                	li	a3,9
    8000274e:	fed792e3          	bne	a5,a3,80002732 <devintr+0x12>
    int irq = plic_claim();
    80002752:	00003097          	auipc	ra,0x3
    80002756:	576080e7          	jalr	1398(ra) # 80005cc8 <plic_claim>
    8000275a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000275c:	47a9                	li	a5,10
    8000275e:	02f50763          	beq	a0,a5,8000278c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002762:	4785                	li	a5,1
    80002764:	02f50963          	beq	a0,a5,80002796 <devintr+0x76>
    return 1;
    80002768:	4505                	li	a0,1
    } else if(irq){
    8000276a:	d8f1                	beqz	s1,8000273e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000276c:	85a6                	mv	a1,s1
    8000276e:	00006517          	auipc	a0,0x6
    80002772:	b7250513          	addi	a0,a0,-1166 # 800082e0 <states.0+0x38>
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	dfe080e7          	jalr	-514(ra) # 80000574 <printf>
      plic_complete(irq);
    8000277e:	8526                	mv	a0,s1
    80002780:	00003097          	auipc	ra,0x3
    80002784:	56c080e7          	jalr	1388(ra) # 80005cec <plic_complete>
    return 1;
    80002788:	4505                	li	a0,1
    8000278a:	bf55                	j	8000273e <devintr+0x1e>
      uartintr();
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	1fa080e7          	jalr	506(ra) # 80000986 <uartintr>
    80002794:	b7ed                	j	8000277e <devintr+0x5e>
      virtio_disk_intr();
    80002796:	00004097          	auipc	ra,0x4
    8000279a:	9e8080e7          	jalr	-1560(ra) # 8000617e <virtio_disk_intr>
    8000279e:	b7c5                	j	8000277e <devintr+0x5e>
    if(cpuid() == 0){
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	1b2080e7          	jalr	434(ra) # 80001952 <cpuid>
    800027a8:	c901                	beqz	a0,800027b8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027aa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027b0:	14479073          	csrw	sip,a5
    return 2;
    800027b4:	4509                	li	a0,2
    800027b6:	b761                	j	8000273e <devintr+0x1e>
      clockintr();
    800027b8:	00000097          	auipc	ra,0x0
    800027bc:	f22080e7          	jalr	-222(ra) # 800026da <clockintr>
    800027c0:	b7ed                	j	800027aa <devintr+0x8a>

00000000800027c2 <usertrap>:
{
    800027c2:	1101                	addi	sp,sp,-32
    800027c4:	ec06                	sd	ra,24(sp)
    800027c6:	e822                	sd	s0,16(sp)
    800027c8:	e426                	sd	s1,8(sp)
    800027ca:	e04a                	sd	s2,0(sp)
    800027cc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ce:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027d2:	1007f793          	andi	a5,a5,256
    800027d6:	e3ad                	bnez	a5,80002838 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027d8:	00003797          	auipc	a5,0x3
    800027dc:	3e878793          	addi	a5,a5,1000 # 80005bc0 <kernelvec>
    800027e0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	19a080e7          	jalr	410(ra) # 8000197e <myproc>
    800027ec:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027ee:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027f0:	14102773          	csrr	a4,sepc
    800027f4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027fa:	47a1                	li	a5,8
    800027fc:	04f71c63          	bne	a4,a5,80002854 <usertrap+0x92>
    if(p->killed)
    80002800:	551c                	lw	a5,40(a0)
    80002802:	e3b9                	bnez	a5,80002848 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002804:	6cb8                	ld	a4,88(s1)
    80002806:	6f1c                	ld	a5,24(a4)
    80002808:	0791                	addi	a5,a5,4
    8000280a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002810:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002814:	10079073          	csrw	sstatus,a5
    syscall();
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	2e0080e7          	jalr	736(ra) # 80002af8 <syscall>
  if(p->killed)
    80002820:	549c                	lw	a5,40(s1)
    80002822:	ebc1                	bnez	a5,800028b2 <usertrap+0xf0>
  usertrapret();
    80002824:	00000097          	auipc	ra,0x0
    80002828:	e18080e7          	jalr	-488(ra) # 8000263c <usertrapret>
}
    8000282c:	60e2                	ld	ra,24(sp)
    8000282e:	6442                	ld	s0,16(sp)
    80002830:	64a2                	ld	s1,8(sp)
    80002832:	6902                	ld	s2,0(sp)
    80002834:	6105                	addi	sp,sp,32
    80002836:	8082                	ret
    panic("usertrap: not from user mode");
    80002838:	00006517          	auipc	a0,0x6
    8000283c:	ac850513          	addi	a0,a0,-1336 # 80008300 <states.0+0x58>
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	cea080e7          	jalr	-790(ra) # 8000052a <panic>
      exit(-1);
    80002848:	557d                	li	a0,-1
    8000284a:	00000097          	auipc	ra,0x0
    8000284e:	a5c080e7          	jalr	-1444(ra) # 800022a6 <exit>
    80002852:	bf4d                	j	80002804 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002854:	00000097          	auipc	ra,0x0
    80002858:	ecc080e7          	jalr	-308(ra) # 80002720 <devintr>
    8000285c:	892a                	mv	s2,a0
    8000285e:	c501                	beqz	a0,80002866 <usertrap+0xa4>
  if(p->killed)
    80002860:	549c                	lw	a5,40(s1)
    80002862:	c3a1                	beqz	a5,800028a2 <usertrap+0xe0>
    80002864:	a815                	j	80002898 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002866:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000286a:	5890                	lw	a2,48(s1)
    8000286c:	00006517          	auipc	a0,0x6
    80002870:	ab450513          	addi	a0,a0,-1356 # 80008320 <states.0+0x78>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	d00080e7          	jalr	-768(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000287c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002880:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002884:	00006517          	auipc	a0,0x6
    80002888:	acc50513          	addi	a0,a0,-1332 # 80008350 <states.0+0xa8>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	ce8080e7          	jalr	-792(ra) # 80000574 <printf>
    p->killed = 1;
    80002894:	4785                	li	a5,1
    80002896:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002898:	557d                	li	a0,-1
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	a0c080e7          	jalr	-1524(ra) # 800022a6 <exit>
  if(which_dev == 2)
    800028a2:	4789                	li	a5,2
    800028a4:	f8f910e3          	bne	s2,a5,80002824 <usertrap+0x62>
    yield();
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	766080e7          	jalr	1894(ra) # 8000200e <yield>
    800028b0:	bf95                	j	80002824 <usertrap+0x62>
  int which_dev = 0;
    800028b2:	4901                	li	s2,0
    800028b4:	b7d5                	j	80002898 <usertrap+0xd6>

00000000800028b6 <kerneltrap>:
{
    800028b6:	7179                	addi	sp,sp,-48
    800028b8:	f406                	sd	ra,40(sp)
    800028ba:	f022                	sd	s0,32(sp)
    800028bc:	ec26                	sd	s1,24(sp)
    800028be:	e84a                	sd	s2,16(sp)
    800028c0:	e44e                	sd	s3,8(sp)
    800028c2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028cc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028d0:	1004f793          	andi	a5,s1,256
    800028d4:	cb85                	beqz	a5,80002904 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028da:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028dc:	ef85                	bnez	a5,80002914 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	e42080e7          	jalr	-446(ra) # 80002720 <devintr>
    800028e6:	cd1d                	beqz	a0,80002924 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028e8:	4789                	li	a5,2
    800028ea:	06f50a63          	beq	a0,a5,8000295e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ee:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f2:	10049073          	csrw	sstatus,s1
}
    800028f6:	70a2                	ld	ra,40(sp)
    800028f8:	7402                	ld	s0,32(sp)
    800028fa:	64e2                	ld	s1,24(sp)
    800028fc:	6942                	ld	s2,16(sp)
    800028fe:	69a2                	ld	s3,8(sp)
    80002900:	6145                	addi	sp,sp,48
    80002902:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002904:	00006517          	auipc	a0,0x6
    80002908:	a6c50513          	addi	a0,a0,-1428 # 80008370 <states.0+0xc8>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	c1e080e7          	jalr	-994(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002914:	00006517          	auipc	a0,0x6
    80002918:	a8450513          	addi	a0,a0,-1404 # 80008398 <states.0+0xf0>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c0e080e7          	jalr	-1010(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002924:	85ce                	mv	a1,s3
    80002926:	00006517          	auipc	a0,0x6
    8000292a:	a9250513          	addi	a0,a0,-1390 # 800083b8 <states.0+0x110>
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	c46080e7          	jalr	-954(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002936:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000293a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	a8a50513          	addi	a0,a0,-1398 # 800083c8 <states.0+0x120>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	c2e080e7          	jalr	-978(ra) # 80000574 <printf>
    panic("kerneltrap");
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	a9250513          	addi	a0,a0,-1390 # 800083e0 <states.0+0x138>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	bd4080e7          	jalr	-1068(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000295e:	fffff097          	auipc	ra,0xfffff
    80002962:	020080e7          	jalr	32(ra) # 8000197e <myproc>
    80002966:	d541                	beqz	a0,800028ee <kerneltrap+0x38>
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	016080e7          	jalr	22(ra) # 8000197e <myproc>
    80002970:	4d18                	lw	a4,24(a0)
    80002972:	4791                	li	a5,4
    80002974:	f6f71de3          	bne	a4,a5,800028ee <kerneltrap+0x38>
    yield();
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	696080e7          	jalr	1686(ra) # 8000200e <yield>
    80002980:	b7bd                	j	800028ee <kerneltrap+0x38>

0000000080002982 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002982:	1101                	addi	sp,sp,-32
    80002984:	ec06                	sd	ra,24(sp)
    80002986:	e822                	sd	s0,16(sp)
    80002988:	e426                	sd	s1,8(sp)
    8000298a:	1000                	addi	s0,sp,32
    8000298c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	ff0080e7          	jalr	-16(ra) # 8000197e <myproc>
  switch (n) {
    80002996:	4795                	li	a5,5
    80002998:	0497e163          	bltu	a5,s1,800029da <argraw+0x58>
    8000299c:	048a                	slli	s1,s1,0x2
    8000299e:	00006717          	auipc	a4,0x6
    800029a2:	b7a70713          	addi	a4,a4,-1158 # 80008518 <states.0+0x270>
    800029a6:	94ba                	add	s1,s1,a4
    800029a8:	409c                	lw	a5,0(s1)
    800029aa:	97ba                	add	a5,a5,a4
    800029ac:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029ae:	6d3c                	ld	a5,88(a0)
    800029b0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029b2:	60e2                	ld	ra,24(sp)
    800029b4:	6442                	ld	s0,16(sp)
    800029b6:	64a2                	ld	s1,8(sp)
    800029b8:	6105                	addi	sp,sp,32
    800029ba:	8082                	ret
    return p->trapframe->a1;
    800029bc:	6d3c                	ld	a5,88(a0)
    800029be:	7fa8                	ld	a0,120(a5)
    800029c0:	bfcd                	j	800029b2 <argraw+0x30>
    return p->trapframe->a2;
    800029c2:	6d3c                	ld	a5,88(a0)
    800029c4:	63c8                	ld	a0,128(a5)
    800029c6:	b7f5                	j	800029b2 <argraw+0x30>
    return p->trapframe->a3;
    800029c8:	6d3c                	ld	a5,88(a0)
    800029ca:	67c8                	ld	a0,136(a5)
    800029cc:	b7dd                	j	800029b2 <argraw+0x30>
    return p->trapframe->a4;
    800029ce:	6d3c                	ld	a5,88(a0)
    800029d0:	6bc8                	ld	a0,144(a5)
    800029d2:	b7c5                	j	800029b2 <argraw+0x30>
    return p->trapframe->a5;
    800029d4:	6d3c                	ld	a5,88(a0)
    800029d6:	6fc8                	ld	a0,152(a5)
    800029d8:	bfe9                	j	800029b2 <argraw+0x30>
  panic("argraw");
    800029da:	00006517          	auipc	a0,0x6
    800029de:	a1650513          	addi	a0,a0,-1514 # 800083f0 <states.0+0x148>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	b48080e7          	jalr	-1208(ra) # 8000052a <panic>

00000000800029ea <fetchaddr>:
{
    800029ea:	1101                	addi	sp,sp,-32
    800029ec:	ec06                	sd	ra,24(sp)
    800029ee:	e822                	sd	s0,16(sp)
    800029f0:	e426                	sd	s1,8(sp)
    800029f2:	e04a                	sd	s2,0(sp)
    800029f4:	1000                	addi	s0,sp,32
    800029f6:	84aa                	mv	s1,a0
    800029f8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	f84080e7          	jalr	-124(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a02:	653c                	ld	a5,72(a0)
    80002a04:	02f4f863          	bgeu	s1,a5,80002a34 <fetchaddr+0x4a>
    80002a08:	00848713          	addi	a4,s1,8
    80002a0c:	02e7e663          	bltu	a5,a4,80002a38 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a10:	46a1                	li	a3,8
    80002a12:	8626                	mv	a2,s1
    80002a14:	85ca                	mv	a1,s2
    80002a16:	6928                	ld	a0,80(a0)
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	cb2080e7          	jalr	-846(ra) # 800016ca <copyin>
    80002a20:	00a03533          	snez	a0,a0
    80002a24:	40a00533          	neg	a0,a0
}
    80002a28:	60e2                	ld	ra,24(sp)
    80002a2a:	6442                	ld	s0,16(sp)
    80002a2c:	64a2                	ld	s1,8(sp)
    80002a2e:	6902                	ld	s2,0(sp)
    80002a30:	6105                	addi	sp,sp,32
    80002a32:	8082                	ret
    return -1;
    80002a34:	557d                	li	a0,-1
    80002a36:	bfcd                	j	80002a28 <fetchaddr+0x3e>
    80002a38:	557d                	li	a0,-1
    80002a3a:	b7fd                	j	80002a28 <fetchaddr+0x3e>

0000000080002a3c <fetchstr>:
{
    80002a3c:	7179                	addi	sp,sp,-48
    80002a3e:	f406                	sd	ra,40(sp)
    80002a40:	f022                	sd	s0,32(sp)
    80002a42:	ec26                	sd	s1,24(sp)
    80002a44:	e84a                	sd	s2,16(sp)
    80002a46:	e44e                	sd	s3,8(sp)
    80002a48:	1800                	addi	s0,sp,48
    80002a4a:	892a                	mv	s2,a0
    80002a4c:	84ae                	mv	s1,a1
    80002a4e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	f2e080e7          	jalr	-210(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a58:	86ce                	mv	a3,s3
    80002a5a:	864a                	mv	a2,s2
    80002a5c:	85a6                	mv	a1,s1
    80002a5e:	6928                	ld	a0,80(a0)
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	cf8080e7          	jalr	-776(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002a68:	00054763          	bltz	a0,80002a76 <fetchstr+0x3a>
  return strlen(buf);
    80002a6c:	8526                	mv	a0,s1
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	3d4080e7          	jalr	980(ra) # 80000e42 <strlen>
}
    80002a76:	70a2                	ld	ra,40(sp)
    80002a78:	7402                	ld	s0,32(sp)
    80002a7a:	64e2                	ld	s1,24(sp)
    80002a7c:	6942                	ld	s2,16(sp)
    80002a7e:	69a2                	ld	s3,8(sp)
    80002a80:	6145                	addi	sp,sp,48
    80002a82:	8082                	ret

0000000080002a84 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a84:	1101                	addi	sp,sp,-32
    80002a86:	ec06                	sd	ra,24(sp)
    80002a88:	e822                	sd	s0,16(sp)
    80002a8a:	e426                	sd	s1,8(sp)
    80002a8c:	1000                	addi	s0,sp,32
    80002a8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	ef2080e7          	jalr	-270(ra) # 80002982 <argraw>
    80002a98:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a9a:	4501                	li	a0,0
    80002a9c:	60e2                	ld	ra,24(sp)
    80002a9e:	6442                	ld	s0,16(sp)
    80002aa0:	64a2                	ld	s1,8(sp)
    80002aa2:	6105                	addi	sp,sp,32
    80002aa4:	8082                	ret

0000000080002aa6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	1000                	addi	s0,sp,32
    80002ab0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	ed0080e7          	jalr	-304(ra) # 80002982 <argraw>
    80002aba:	e088                	sd	a0,0(s1)
  return 0;
}
    80002abc:	4501                	li	a0,0
    80002abe:	60e2                	ld	ra,24(sp)
    80002ac0:	6442                	ld	s0,16(sp)
    80002ac2:	64a2                	ld	s1,8(sp)
    80002ac4:	6105                	addi	sp,sp,32
    80002ac6:	8082                	ret

0000000080002ac8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ac8:	1101                	addi	sp,sp,-32
    80002aca:	ec06                	sd	ra,24(sp)
    80002acc:	e822                	sd	s0,16(sp)
    80002ace:	e426                	sd	s1,8(sp)
    80002ad0:	e04a                	sd	s2,0(sp)
    80002ad2:	1000                	addi	s0,sp,32
    80002ad4:	84ae                	mv	s1,a1
    80002ad6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	eaa080e7          	jalr	-342(ra) # 80002982 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ae0:	864a                	mv	a2,s2
    80002ae2:	85a6                	mv	a1,s1
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	f58080e7          	jalr	-168(ra) # 80002a3c <fetchstr>
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6902                	ld	s2,0(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret

0000000080002af8 <syscall>:
// print: "{pid}: syscall {the name of the syscall} {argument of the syscall} -> {return value of the syscall}"


void
syscall(void)
{
    80002af8:	7139                	addi	sp,sp,-64
    80002afa:	fc06                	sd	ra,56(sp)
    80002afc:	f822                	sd	s0,48(sp)
    80002afe:	f426                	sd	s1,40(sp)
    80002b00:	f04a                	sd	s2,32(sp)
    80002b02:	ec4e                	sd	s3,24(sp)
    80002b04:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	e78080e7          	jalr	-392(ra) # 8000197e <myproc>
    80002b0e:	892a                	mv	s2,a0
  num = p->trapframe->a7;
    80002b10:	6d3c                	ld	a5,88(a0)
    80002b12:	0a87a483          	lw	s1,168(a5)
  int argument = 0;
    80002b16:	fc042623          	sw	zero,-52(s0)
  if(num == SYS_fork || num == SYS_kill || num == SYS_sbrk)
    80002b1a:	47b1                	li	a5,12
    80002b1c:	0297e063          	bltu	a5,s1,80002b3c <syscall+0x44>
    80002b20:	6785                	lui	a5,0x1
    80002b22:	04278793          	addi	a5,a5,66 # 1042 <_entry-0x7fffefbe>
    80002b26:	0097d7b3          	srl	a5,a5,s1
    80002b2a:	8b85                	andi	a5,a5,1
    80002b2c:	cb81                	beqz	a5,80002b3c <syscall+0x44>
    argint(0, &argument);
    80002b2e:	fcc40593          	addi	a1,s0,-52
    80002b32:	4501                	li	a0,0
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	f50080e7          	jalr	-176(ra) # 80002a84 <argint>

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b3c:	fff4879b          	addiw	a5,s1,-1
    80002b40:	4755                	li	a4,21
    80002b42:	02f76163          	bltu	a4,a5,80002b64 <syscall+0x6c>
    80002b46:	00349713          	slli	a4,s1,0x3
    80002b4a:	00006797          	auipc	a5,0x6
    80002b4e:	9e678793          	addi	a5,a5,-1562 # 80008530 <syscalls>
    80002b52:	97ba                	add	a5,a5,a4
    80002b54:	639c                	ld	a5,0(a5)
    80002b56:	c799                	beqz	a5,80002b64 <syscall+0x6c>
    p->trapframe->a0 = syscalls[num]();
    80002b58:	05893983          	ld	s3,88(s2)
    80002b5c:	9782                	jalr	a5
    80002b5e:	06a9b823          	sd	a0,112(s3)
    80002b62:	a015                	j	80002b86 <syscall+0x8e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b64:	86a6                	mv	a3,s1
    80002b66:	15890613          	addi	a2,s2,344
    80002b6a:	03092583          	lw	a1,48(s2)
    80002b6e:	00006517          	auipc	a0,0x6
    80002b72:	88a50513          	addi	a0,a0,-1910 # 800083f8 <states.0+0x150>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	9fe080e7          	jalr	-1538(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b7e:	05893783          	ld	a5,88(s2)
    80002b82:	577d                	li	a4,-1
    80002b84:	fbb8                	sd	a4,112(a5)

  int ret = p->trapframe->a0;

  /* If the system calls bit is on in the mask of the process, 
  then print the trace of the system call. */
  if(p->mask & (1 << num)){
    80002b86:	03492783          	lw	a5,52(s2)
    80002b8a:	4097d7bb          	sraw	a5,a5,s1
    80002b8e:	8b85                	andi	a5,a5,1
    80002b90:	c3a9                	beqz	a5,80002bd2 <syscall+0xda>
  int ret = p->trapframe->a0;
    80002b92:	05893783          	ld	a5,88(s2)
    80002b96:	5bb4                	lw	a3,112(a5)
    if(num == SYS_fork)
    80002b98:	4785                	li	a5,1
    80002b9a:	04f48363          	beq	s1,a5,80002be0 <syscall+0xe8>
      printf("A %d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    else if(num == SYS_kill || num == SYS_sbrk)
    80002b9e:	4799                	li	a5,6
    80002ba0:	00f48563          	beq	s1,a5,80002baa <syscall+0xb2>
    80002ba4:	47b1                	li	a5,12
    80002ba6:	04f49c63          	bne	s1,a5,80002bfe <syscall+0x106>
      printf("B %d: syscall %s %d -> %d\n", p->pid, sys_calls_names[num], argument, ret);
    80002baa:	048e                	slli	s1,s1,0x3
    80002bac:	00006797          	auipc	a5,0x6
    80002bb0:	d9c78793          	addi	a5,a5,-612 # 80008948 <sys_calls_names>
    80002bb4:	94be                	add	s1,s1,a5
    80002bb6:	8736                	mv	a4,a3
    80002bb8:	fcc42683          	lw	a3,-52(s0)
    80002bbc:	6090                	ld	a2,0(s1)
    80002bbe:	03092583          	lw	a1,48(s2)
    80002bc2:	00006517          	auipc	a0,0x6
    80002bc6:	87650513          	addi	a0,a0,-1930 # 80008438 <states.0+0x190>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	9aa080e7          	jalr	-1622(ra) # 80000574 <printf>
    else
      printf("C %d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
  }
}
    80002bd2:	70e2                	ld	ra,56(sp)
    80002bd4:	7442                	ld	s0,48(sp)
    80002bd6:	74a2                	ld	s1,40(sp)
    80002bd8:	7902                	ld	s2,32(sp)
    80002bda:	69e2                	ld	s3,24(sp)
    80002bdc:	6121                	addi	sp,sp,64
    80002bde:	8082                	ret
      printf("A %d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    80002be0:	00006617          	auipc	a2,0x6
    80002be4:	d7063603          	ld	a2,-656(a2) # 80008950 <sys_calls_names+0x8>
    80002be8:	03092583          	lw	a1,48(s2)
    80002bec:	00006517          	auipc	a0,0x6
    80002bf0:	82c50513          	addi	a0,a0,-2004 # 80008418 <states.0+0x170>
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	980080e7          	jalr	-1664(ra) # 80000574 <printf>
    80002bfc:	bfd9                	j	80002bd2 <syscall+0xda>
      printf("C %d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
    80002bfe:	048e                	slli	s1,s1,0x3
    80002c00:	00006797          	auipc	a5,0x6
    80002c04:	d4878793          	addi	a5,a5,-696 # 80008948 <sys_calls_names>
    80002c08:	94be                	add	s1,s1,a5
    80002c0a:	6090                	ld	a2,0(s1)
    80002c0c:	03092583          	lw	a1,48(s2)
    80002c10:	00006517          	auipc	a0,0x6
    80002c14:	84850513          	addi	a0,a0,-1976 # 80008458 <states.0+0x1b0>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	95c080e7          	jalr	-1700(ra) # 80000574 <printf>
}
    80002c20:	bf4d                	j	80002bd2 <syscall+0xda>

0000000080002c22 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c22:	1101                	addi	sp,sp,-32
    80002c24:	ec06                	sd	ra,24(sp)
    80002c26:	e822                	sd	s0,16(sp)
    80002c28:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c2a:	fec40593          	addi	a1,s0,-20
    80002c2e:	4501                	li	a0,0
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	e54080e7          	jalr	-428(ra) # 80002a84 <argint>
    return -1;
    80002c38:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c3a:	00054963          	bltz	a0,80002c4c <sys_exit+0x2a>
  exit(n);
    80002c3e:	fec42503          	lw	a0,-20(s0)
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	664080e7          	jalr	1636(ra) # 800022a6 <exit>
  return 0;  // not reached
    80002c4a:	4781                	li	a5,0
}
    80002c4c:	853e                	mv	a0,a5
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	6105                	addi	sp,sp,32
    80002c54:	8082                	ret

0000000080002c56 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c56:	1141                	addi	sp,sp,-16
    80002c58:	e406                	sd	ra,8(sp)
    80002c5a:	e022                	sd	s0,0(sp)
    80002c5c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	d20080e7          	jalr	-736(ra) # 8000197e <myproc>
}
    80002c66:	5908                	lw	a0,48(a0)
    80002c68:	60a2                	ld	ra,8(sp)
    80002c6a:	6402                	ld	s0,0(sp)
    80002c6c:	0141                	addi	sp,sp,16
    80002c6e:	8082                	ret

0000000080002c70 <sys_fork>:

uint64
sys_fork(void)
{
    80002c70:	1141                	addi	sp,sp,-16
    80002c72:	e406                	sd	ra,8(sp)
    80002c74:	e022                	sd	s0,0(sp)
    80002c76:	0800                	addi	s0,sp,16
  return fork();
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	0d8080e7          	jalr	216(ra) # 80001d50 <fork>
}
    80002c80:	60a2                	ld	ra,8(sp)
    80002c82:	6402                	ld	s0,0(sp)
    80002c84:	0141                	addi	sp,sp,16
    80002c86:	8082                	ret

0000000080002c88 <sys_wait>:

uint64
sys_wait(void)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c90:	fe840593          	addi	a1,s0,-24
    80002c94:	4501                	li	a0,0
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	e10080e7          	jalr	-496(ra) # 80002aa6 <argaddr>
    80002c9e:	87aa                	mv	a5,a0
    return -1;
    80002ca0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ca2:	0007c863          	bltz	a5,80002cb2 <sys_wait+0x2a>
  return wait(p);
    80002ca6:	fe843503          	ld	a0,-24(s0)
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	404080e7          	jalr	1028(ra) # 800020ae <wait>
}
    80002cb2:	60e2                	ld	ra,24(sp)
    80002cb4:	6442                	ld	s0,16(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret

0000000080002cba <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cba:	7179                	addi	sp,sp,-48
    80002cbc:	f406                	sd	ra,40(sp)
    80002cbe:	f022                	sd	s0,32(sp)
    80002cc0:	ec26                	sd	s1,24(sp)
    80002cc2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cc4:	fdc40593          	addi	a1,s0,-36
    80002cc8:	4501                	li	a0,0
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	dba080e7          	jalr	-582(ra) # 80002a84 <argint>
    return -1;
    80002cd2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002cd4:	00054f63          	bltz	a0,80002cf2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	ca6080e7          	jalr	-858(ra) # 8000197e <myproc>
    80002ce0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ce2:	fdc42503          	lw	a0,-36(s0)
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	ff6080e7          	jalr	-10(ra) # 80001cdc <growproc>
    80002cee:	00054863          	bltz	a0,80002cfe <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002cf2:	8526                	mv	a0,s1
    80002cf4:	70a2                	ld	ra,40(sp)
    80002cf6:	7402                	ld	s0,32(sp)
    80002cf8:	64e2                	ld	s1,24(sp)
    80002cfa:	6145                	addi	sp,sp,48
    80002cfc:	8082                	ret
    return -1;
    80002cfe:	54fd                	li	s1,-1
    80002d00:	bfcd                	j	80002cf2 <sys_sbrk+0x38>

0000000080002d02 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d02:	7139                	addi	sp,sp,-64
    80002d04:	fc06                	sd	ra,56(sp)
    80002d06:	f822                	sd	s0,48(sp)
    80002d08:	f426                	sd	s1,40(sp)
    80002d0a:	f04a                	sd	s2,32(sp)
    80002d0c:	ec4e                	sd	s3,24(sp)
    80002d0e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d10:	fcc40593          	addi	a1,s0,-52
    80002d14:	4501                	li	a0,0
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	d6e080e7          	jalr	-658(ra) # 80002a84 <argint>
    return -1;
    80002d1e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d20:	06054563          	bltz	a0,80002d8a <sys_sleep+0x88>
  acquire(&tickslock);
    80002d24:	00014517          	auipc	a0,0x14
    80002d28:	3ac50513          	addi	a0,a0,940 # 800170d0 <tickslock>
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	e96080e7          	jalr	-362(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002d34:	00006917          	auipc	s2,0x6
    80002d38:	2fc92903          	lw	s2,764(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d3c:	fcc42783          	lw	a5,-52(s0)
    80002d40:	cf85                	beqz	a5,80002d78 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d42:	00014997          	auipc	s3,0x14
    80002d46:	38e98993          	addi	s3,s3,910 # 800170d0 <tickslock>
    80002d4a:	00006497          	auipc	s1,0x6
    80002d4e:	2e648493          	addi	s1,s1,742 # 80009030 <ticks>
    if(myproc()->killed){
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	c2c080e7          	jalr	-980(ra) # 8000197e <myproc>
    80002d5a:	551c                	lw	a5,40(a0)
    80002d5c:	ef9d                	bnez	a5,80002d9a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d5e:	85ce                	mv	a1,s3
    80002d60:	8526                	mv	a0,s1
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	2e8080e7          	jalr	744(ra) # 8000204a <sleep>
  while(ticks - ticks0 < n){
    80002d6a:	409c                	lw	a5,0(s1)
    80002d6c:	412787bb          	subw	a5,a5,s2
    80002d70:	fcc42703          	lw	a4,-52(s0)
    80002d74:	fce7efe3          	bltu	a5,a4,80002d52 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d78:	00014517          	auipc	a0,0x14
    80002d7c:	35850513          	addi	a0,a0,856 # 800170d0 <tickslock>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	ef6080e7          	jalr	-266(ra) # 80000c76 <release>
  return 0;
    80002d88:	4781                	li	a5,0
}
    80002d8a:	853e                	mv	a0,a5
    80002d8c:	70e2                	ld	ra,56(sp)
    80002d8e:	7442                	ld	s0,48(sp)
    80002d90:	74a2                	ld	s1,40(sp)
    80002d92:	7902                	ld	s2,32(sp)
    80002d94:	69e2                	ld	s3,24(sp)
    80002d96:	6121                	addi	sp,sp,64
    80002d98:	8082                	ret
      release(&tickslock);
    80002d9a:	00014517          	auipc	a0,0x14
    80002d9e:	33650513          	addi	a0,a0,822 # 800170d0 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	ed4080e7          	jalr	-300(ra) # 80000c76 <release>
      return -1;
    80002daa:	57fd                	li	a5,-1
    80002dac:	bff9                	j	80002d8a <sys_sleep+0x88>

0000000080002dae <sys_trace>:


void
sys_trace(void)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	1000                	addi	s0,sp,32
  int mask;
  int pid;

  if(argint(0, &mask) >= 0 && argint(1, &pid) >= 0)
    80002db6:	fec40593          	addi	a1,s0,-20
    80002dba:	4501                	li	a0,0
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	cc8080e7          	jalr	-824(ra) # 80002a84 <argint>
    80002dc4:	00055663          	bgez	a0,80002dd0 <sys_trace+0x22>
    trace(mask, pid);
}
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret
  if(argint(0, &mask) >= 0 && argint(1, &pid) >= 0)
    80002dd0:	fe840593          	addi	a1,s0,-24
    80002dd4:	4505                	li	a0,1
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	cae080e7          	jalr	-850(ra) # 80002a84 <argint>
    80002dde:	fe0545e3          	bltz	a0,80002dc8 <sys_trace+0x1a>
    trace(mask, pid);
    80002de2:	fe842583          	lw	a1,-24(s0)
    80002de6:	fec42503          	lw	a0,-20(s0)
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	592080e7          	jalr	1426(ra) # 8000237c <trace>
}
    80002df2:	bfd9                	j	80002dc8 <sys_trace+0x1a>

0000000080002df4 <sys_kill>:


uint64
sys_kill(void)
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dfc:	fec40593          	addi	a1,s0,-20
    80002e00:	4501                	li	a0,0
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	c82080e7          	jalr	-894(ra) # 80002a84 <argint>
    80002e0a:	87aa                	mv	a5,a0
    return -1;
    80002e0c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e0e:	0007c863          	bltz	a5,80002e1e <sys_kill+0x2a>
  return kill(pid);
    80002e12:	fec42503          	lw	a0,-20(s0)
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	5ae080e7          	jalr	1454(ra) # 800023c4 <kill>
}
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	e426                	sd	s1,8(sp)
    80002e2e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e30:	00014517          	auipc	a0,0x14
    80002e34:	2a050513          	addi	a0,a0,672 # 800170d0 <tickslock>
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	d8a080e7          	jalr	-630(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002e40:	00006497          	auipc	s1,0x6
    80002e44:	1f04a483          	lw	s1,496(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e48:	00014517          	auipc	a0,0x14
    80002e4c:	28850513          	addi	a0,a0,648 # 800170d0 <tickslock>
    80002e50:	ffffe097          	auipc	ra,0xffffe
    80002e54:	e26080e7          	jalr	-474(ra) # 80000c76 <release>
  return xticks;
}
    80002e58:	02049513          	slli	a0,s1,0x20
    80002e5c:	9101                	srli	a0,a0,0x20
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	64a2                	ld	s1,8(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e68:	7179                	addi	sp,sp,-48
    80002e6a:	f406                	sd	ra,40(sp)
    80002e6c:	f022                	sd	s0,32(sp)
    80002e6e:	ec26                	sd	s1,24(sp)
    80002e70:	e84a                	sd	s2,16(sp)
    80002e72:	e44e                	sd	s3,8(sp)
    80002e74:	e052                	sd	s4,0(sp)
    80002e76:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e78:	00005597          	auipc	a1,0x5
    80002e7c:	77058593          	addi	a1,a1,1904 # 800085e8 <syscalls+0xb8>
    80002e80:	00014517          	auipc	a0,0x14
    80002e84:	26850513          	addi	a0,a0,616 # 800170e8 <bcache>
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	caa080e7          	jalr	-854(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e90:	0001c797          	auipc	a5,0x1c
    80002e94:	25878793          	addi	a5,a5,600 # 8001f0e8 <bcache+0x8000>
    80002e98:	0001c717          	auipc	a4,0x1c
    80002e9c:	4b870713          	addi	a4,a4,1208 # 8001f350 <bcache+0x8268>
    80002ea0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ea4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ea8:	00014497          	auipc	s1,0x14
    80002eac:	25848493          	addi	s1,s1,600 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002eb0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eb2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eb4:	00005a17          	auipc	s4,0x5
    80002eb8:	73ca0a13          	addi	s4,s4,1852 # 800085f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002ebc:	2b893783          	ld	a5,696(s2)
    80002ec0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ec2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ec6:	85d2                	mv	a1,s4
    80002ec8:	01048513          	addi	a0,s1,16
    80002ecc:	00001097          	auipc	ra,0x1
    80002ed0:	4c2080e7          	jalr	1218(ra) # 8000438e <initsleeplock>
    bcache.head.next->prev = b;
    80002ed4:	2b893783          	ld	a5,696(s2)
    80002ed8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eda:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ede:	45848493          	addi	s1,s1,1112
    80002ee2:	fd349de3          	bne	s1,s3,80002ebc <binit+0x54>
  }
}
    80002ee6:	70a2                	ld	ra,40(sp)
    80002ee8:	7402                	ld	s0,32(sp)
    80002eea:	64e2                	ld	s1,24(sp)
    80002eec:	6942                	ld	s2,16(sp)
    80002eee:	69a2                	ld	s3,8(sp)
    80002ef0:	6a02                	ld	s4,0(sp)
    80002ef2:	6145                	addi	sp,sp,48
    80002ef4:	8082                	ret

0000000080002ef6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ef6:	7179                	addi	sp,sp,-48
    80002ef8:	f406                	sd	ra,40(sp)
    80002efa:	f022                	sd	s0,32(sp)
    80002efc:	ec26                	sd	s1,24(sp)
    80002efe:	e84a                	sd	s2,16(sp)
    80002f00:	e44e                	sd	s3,8(sp)
    80002f02:	1800                	addi	s0,sp,48
    80002f04:	892a                	mv	s2,a0
    80002f06:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f08:	00014517          	auipc	a0,0x14
    80002f0c:	1e050513          	addi	a0,a0,480 # 800170e8 <bcache>
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	cb2080e7          	jalr	-846(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f18:	0001c497          	auipc	s1,0x1c
    80002f1c:	4884b483          	ld	s1,1160(s1) # 8001f3a0 <bcache+0x82b8>
    80002f20:	0001c797          	auipc	a5,0x1c
    80002f24:	43078793          	addi	a5,a5,1072 # 8001f350 <bcache+0x8268>
    80002f28:	02f48f63          	beq	s1,a5,80002f66 <bread+0x70>
    80002f2c:	873e                	mv	a4,a5
    80002f2e:	a021                	j	80002f36 <bread+0x40>
    80002f30:	68a4                	ld	s1,80(s1)
    80002f32:	02e48a63          	beq	s1,a4,80002f66 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f36:	449c                	lw	a5,8(s1)
    80002f38:	ff279ce3          	bne	a5,s2,80002f30 <bread+0x3a>
    80002f3c:	44dc                	lw	a5,12(s1)
    80002f3e:	ff3799e3          	bne	a5,s3,80002f30 <bread+0x3a>
      b->refcnt++;
    80002f42:	40bc                	lw	a5,64(s1)
    80002f44:	2785                	addiw	a5,a5,1
    80002f46:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f48:	00014517          	auipc	a0,0x14
    80002f4c:	1a050513          	addi	a0,a0,416 # 800170e8 <bcache>
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	d26080e7          	jalr	-730(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002f58:	01048513          	addi	a0,s1,16
    80002f5c:	00001097          	auipc	ra,0x1
    80002f60:	46c080e7          	jalr	1132(ra) # 800043c8 <acquiresleep>
      return b;
    80002f64:	a8b9                	j	80002fc2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f66:	0001c497          	auipc	s1,0x1c
    80002f6a:	4324b483          	ld	s1,1074(s1) # 8001f398 <bcache+0x82b0>
    80002f6e:	0001c797          	auipc	a5,0x1c
    80002f72:	3e278793          	addi	a5,a5,994 # 8001f350 <bcache+0x8268>
    80002f76:	00f48863          	beq	s1,a5,80002f86 <bread+0x90>
    80002f7a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f7c:	40bc                	lw	a5,64(s1)
    80002f7e:	cf81                	beqz	a5,80002f96 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f80:	64a4                	ld	s1,72(s1)
    80002f82:	fee49de3          	bne	s1,a4,80002f7c <bread+0x86>
  panic("bget: no buffers");
    80002f86:	00005517          	auipc	a0,0x5
    80002f8a:	67250513          	addi	a0,a0,1650 # 800085f8 <syscalls+0xc8>
    80002f8e:	ffffd097          	auipc	ra,0xffffd
    80002f92:	59c080e7          	jalr	1436(ra) # 8000052a <panic>
      b->dev = dev;
    80002f96:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f9a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f9e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fa2:	4785                	li	a5,1
    80002fa4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fa6:	00014517          	auipc	a0,0x14
    80002faa:	14250513          	addi	a0,a0,322 # 800170e8 <bcache>
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	cc8080e7          	jalr	-824(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002fb6:	01048513          	addi	a0,s1,16
    80002fba:	00001097          	auipc	ra,0x1
    80002fbe:	40e080e7          	jalr	1038(ra) # 800043c8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fc2:	409c                	lw	a5,0(s1)
    80002fc4:	cb89                	beqz	a5,80002fd6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	70a2                	ld	ra,40(sp)
    80002fca:	7402                	ld	s0,32(sp)
    80002fcc:	64e2                	ld	s1,24(sp)
    80002fce:	6942                	ld	s2,16(sp)
    80002fd0:	69a2                	ld	s3,8(sp)
    80002fd2:	6145                	addi	sp,sp,48
    80002fd4:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fd6:	4581                	li	a1,0
    80002fd8:	8526                	mv	a0,s1
    80002fda:	00003097          	auipc	ra,0x3
    80002fde:	f1c080e7          	jalr	-228(ra) # 80005ef6 <virtio_disk_rw>
    b->valid = 1;
    80002fe2:	4785                	li	a5,1
    80002fe4:	c09c                	sw	a5,0(s1)
  return b;
    80002fe6:	b7c5                	j	80002fc6 <bread+0xd0>

0000000080002fe8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fe8:	1101                	addi	sp,sp,-32
    80002fea:	ec06                	sd	ra,24(sp)
    80002fec:	e822                	sd	s0,16(sp)
    80002fee:	e426                	sd	s1,8(sp)
    80002ff0:	1000                	addi	s0,sp,32
    80002ff2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ff4:	0541                	addi	a0,a0,16
    80002ff6:	00001097          	auipc	ra,0x1
    80002ffa:	46c080e7          	jalr	1132(ra) # 80004462 <holdingsleep>
    80002ffe:	cd01                	beqz	a0,80003016 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003000:	4585                	li	a1,1
    80003002:	8526                	mv	a0,s1
    80003004:	00003097          	auipc	ra,0x3
    80003008:	ef2080e7          	jalr	-270(ra) # 80005ef6 <virtio_disk_rw>
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret
    panic("bwrite");
    80003016:	00005517          	auipc	a0,0x5
    8000301a:	5fa50513          	addi	a0,a0,1530 # 80008610 <syscalls+0xe0>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	50c080e7          	jalr	1292(ra) # 8000052a <panic>

0000000080003026 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003026:	1101                	addi	sp,sp,-32
    80003028:	ec06                	sd	ra,24(sp)
    8000302a:	e822                	sd	s0,16(sp)
    8000302c:	e426                	sd	s1,8(sp)
    8000302e:	e04a                	sd	s2,0(sp)
    80003030:	1000                	addi	s0,sp,32
    80003032:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003034:	01050913          	addi	s2,a0,16
    80003038:	854a                	mv	a0,s2
    8000303a:	00001097          	auipc	ra,0x1
    8000303e:	428080e7          	jalr	1064(ra) # 80004462 <holdingsleep>
    80003042:	c92d                	beqz	a0,800030b4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003044:	854a                	mv	a0,s2
    80003046:	00001097          	auipc	ra,0x1
    8000304a:	3d8080e7          	jalr	984(ra) # 8000441e <releasesleep>

  acquire(&bcache.lock);
    8000304e:	00014517          	auipc	a0,0x14
    80003052:	09a50513          	addi	a0,a0,154 # 800170e8 <bcache>
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	b6c080e7          	jalr	-1172(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000305e:	40bc                	lw	a5,64(s1)
    80003060:	37fd                	addiw	a5,a5,-1
    80003062:	0007871b          	sext.w	a4,a5
    80003066:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003068:	eb05                	bnez	a4,80003098 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000306a:	68bc                	ld	a5,80(s1)
    8000306c:	64b8                	ld	a4,72(s1)
    8000306e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003070:	64bc                	ld	a5,72(s1)
    80003072:	68b8                	ld	a4,80(s1)
    80003074:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003076:	0001c797          	auipc	a5,0x1c
    8000307a:	07278793          	addi	a5,a5,114 # 8001f0e8 <bcache+0x8000>
    8000307e:	2b87b703          	ld	a4,696(a5)
    80003082:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003084:	0001c717          	auipc	a4,0x1c
    80003088:	2cc70713          	addi	a4,a4,716 # 8001f350 <bcache+0x8268>
    8000308c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000308e:	2b87b703          	ld	a4,696(a5)
    80003092:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003094:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003098:	00014517          	auipc	a0,0x14
    8000309c:	05050513          	addi	a0,a0,80 # 800170e8 <bcache>
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	bd6080e7          	jalr	-1066(ra) # 80000c76 <release>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6902                	ld	s2,0(sp)
    800030b0:	6105                	addi	sp,sp,32
    800030b2:	8082                	ret
    panic("brelse");
    800030b4:	00005517          	auipc	a0,0x5
    800030b8:	56450513          	addi	a0,a0,1380 # 80008618 <syscalls+0xe8>
    800030bc:	ffffd097          	auipc	ra,0xffffd
    800030c0:	46e080e7          	jalr	1134(ra) # 8000052a <panic>

00000000800030c4 <bpin>:

void
bpin(struct buf *b) {
    800030c4:	1101                	addi	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	e426                	sd	s1,8(sp)
    800030cc:	1000                	addi	s0,sp,32
    800030ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	01850513          	addi	a0,a0,24 # 800170e8 <bcache>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	aea080e7          	jalr	-1302(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800030e0:	40bc                	lw	a5,64(s1)
    800030e2:	2785                	addiw	a5,a5,1
    800030e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030e6:	00014517          	auipc	a0,0x14
    800030ea:	00250513          	addi	a0,a0,2 # 800170e8 <bcache>
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	b88080e7          	jalr	-1144(ra) # 80000c76 <release>
}
    800030f6:	60e2                	ld	ra,24(sp)
    800030f8:	6442                	ld	s0,16(sp)
    800030fa:	64a2                	ld	s1,8(sp)
    800030fc:	6105                	addi	sp,sp,32
    800030fe:	8082                	ret

0000000080003100 <bunpin>:

void
bunpin(struct buf *b) {
    80003100:	1101                	addi	sp,sp,-32
    80003102:	ec06                	sd	ra,24(sp)
    80003104:	e822                	sd	s0,16(sp)
    80003106:	e426                	sd	s1,8(sp)
    80003108:	1000                	addi	s0,sp,32
    8000310a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000310c:	00014517          	auipc	a0,0x14
    80003110:	fdc50513          	addi	a0,a0,-36 # 800170e8 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	aae080e7          	jalr	-1362(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	37fd                	addiw	a5,a5,-1
    80003120:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003122:	00014517          	auipc	a0,0x14
    80003126:	fc650513          	addi	a0,a0,-58 # 800170e8 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	b4c080e7          	jalr	-1204(ra) # 80000c76 <release>
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6105                	addi	sp,sp,32
    8000313a:	8082                	ret

000000008000313c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000313c:	1101                	addi	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	e04a                	sd	s2,0(sp)
    80003146:	1000                	addi	s0,sp,32
    80003148:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000314a:	00d5d59b          	srliw	a1,a1,0xd
    8000314e:	0001c797          	auipc	a5,0x1c
    80003152:	6767a783          	lw	a5,1654(a5) # 8001f7c4 <sb+0x1c>
    80003156:	9dbd                	addw	a1,a1,a5
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	d9e080e7          	jalr	-610(ra) # 80002ef6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003160:	0074f713          	andi	a4,s1,7
    80003164:	4785                	li	a5,1
    80003166:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000316a:	14ce                	slli	s1,s1,0x33
    8000316c:	90d9                	srli	s1,s1,0x36
    8000316e:	00950733          	add	a4,a0,s1
    80003172:	05874703          	lbu	a4,88(a4)
    80003176:	00e7f6b3          	and	a3,a5,a4
    8000317a:	c69d                	beqz	a3,800031a8 <bfree+0x6c>
    8000317c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000317e:	94aa                	add	s1,s1,a0
    80003180:	fff7c793          	not	a5,a5
    80003184:	8ff9                	and	a5,a5,a4
    80003186:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000318a:	00001097          	auipc	ra,0x1
    8000318e:	11e080e7          	jalr	286(ra) # 800042a8 <log_write>
  brelse(bp);
    80003192:	854a                	mv	a0,s2
    80003194:	00000097          	auipc	ra,0x0
    80003198:	e92080e7          	jalr	-366(ra) # 80003026 <brelse>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6902                	ld	s2,0(sp)
    800031a4:	6105                	addi	sp,sp,32
    800031a6:	8082                	ret
    panic("freeing free block");
    800031a8:	00005517          	auipc	a0,0x5
    800031ac:	47850513          	addi	a0,a0,1144 # 80008620 <syscalls+0xf0>
    800031b0:	ffffd097          	auipc	ra,0xffffd
    800031b4:	37a080e7          	jalr	890(ra) # 8000052a <panic>

00000000800031b8 <balloc>:
{
    800031b8:	711d                	addi	sp,sp,-96
    800031ba:	ec86                	sd	ra,88(sp)
    800031bc:	e8a2                	sd	s0,80(sp)
    800031be:	e4a6                	sd	s1,72(sp)
    800031c0:	e0ca                	sd	s2,64(sp)
    800031c2:	fc4e                	sd	s3,56(sp)
    800031c4:	f852                	sd	s4,48(sp)
    800031c6:	f456                	sd	s5,40(sp)
    800031c8:	f05a                	sd	s6,32(sp)
    800031ca:	ec5e                	sd	s7,24(sp)
    800031cc:	e862                	sd	s8,16(sp)
    800031ce:	e466                	sd	s9,8(sp)
    800031d0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031d2:	0001c797          	auipc	a5,0x1c
    800031d6:	5da7a783          	lw	a5,1498(a5) # 8001f7ac <sb+0x4>
    800031da:	cbd1                	beqz	a5,8000326e <balloc+0xb6>
    800031dc:	8baa                	mv	s7,a0
    800031de:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031e0:	0001cb17          	auipc	s6,0x1c
    800031e4:	5c8b0b13          	addi	s6,s6,1480 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031ea:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ec:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031ee:	6c89                	lui	s9,0x2
    800031f0:	a831                	j	8000320c <balloc+0x54>
    brelse(bp);
    800031f2:	854a                	mv	a0,s2
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	e32080e7          	jalr	-462(ra) # 80003026 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031fc:	015c87bb          	addw	a5,s9,s5
    80003200:	00078a9b          	sext.w	s5,a5
    80003204:	004b2703          	lw	a4,4(s6)
    80003208:	06eaf363          	bgeu	s5,a4,8000326e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000320c:	41fad79b          	sraiw	a5,s5,0x1f
    80003210:	0137d79b          	srliw	a5,a5,0x13
    80003214:	015787bb          	addw	a5,a5,s5
    80003218:	40d7d79b          	sraiw	a5,a5,0xd
    8000321c:	01cb2583          	lw	a1,28(s6)
    80003220:	9dbd                	addw	a1,a1,a5
    80003222:	855e                	mv	a0,s7
    80003224:	00000097          	auipc	ra,0x0
    80003228:	cd2080e7          	jalr	-814(ra) # 80002ef6 <bread>
    8000322c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322e:	004b2503          	lw	a0,4(s6)
    80003232:	000a849b          	sext.w	s1,s5
    80003236:	8662                	mv	a2,s8
    80003238:	faa4fde3          	bgeu	s1,a0,800031f2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000323c:	41f6579b          	sraiw	a5,a2,0x1f
    80003240:	01d7d69b          	srliw	a3,a5,0x1d
    80003244:	00c6873b          	addw	a4,a3,a2
    80003248:	00777793          	andi	a5,a4,7
    8000324c:	9f95                	subw	a5,a5,a3
    8000324e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003252:	4037571b          	sraiw	a4,a4,0x3
    80003256:	00e906b3          	add	a3,s2,a4
    8000325a:	0586c683          	lbu	a3,88(a3)
    8000325e:	00d7f5b3          	and	a1,a5,a3
    80003262:	cd91                	beqz	a1,8000327e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003264:	2605                	addiw	a2,a2,1
    80003266:	2485                	addiw	s1,s1,1
    80003268:	fd4618e3          	bne	a2,s4,80003238 <balloc+0x80>
    8000326c:	b759                	j	800031f2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000326e:	00005517          	auipc	a0,0x5
    80003272:	3ca50513          	addi	a0,a0,970 # 80008638 <syscalls+0x108>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	2b4080e7          	jalr	692(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000327e:	974a                	add	a4,a4,s2
    80003280:	8fd5                	or	a5,a5,a3
    80003282:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	020080e7          	jalr	32(ra) # 800042a8 <log_write>
        brelse(bp);
    80003290:	854a                	mv	a0,s2
    80003292:	00000097          	auipc	ra,0x0
    80003296:	d94080e7          	jalr	-620(ra) # 80003026 <brelse>
  bp = bread(dev, bno);
    8000329a:	85a6                	mv	a1,s1
    8000329c:	855e                	mv	a0,s7
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	c58080e7          	jalr	-936(ra) # 80002ef6 <bread>
    800032a6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032a8:	40000613          	li	a2,1024
    800032ac:	4581                	li	a1,0
    800032ae:	05850513          	addi	a0,a0,88
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	a0c080e7          	jalr	-1524(ra) # 80000cbe <memset>
  log_write(bp);
    800032ba:	854a                	mv	a0,s2
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	fec080e7          	jalr	-20(ra) # 800042a8 <log_write>
  brelse(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	d60080e7          	jalr	-672(ra) # 80003026 <brelse>
}
    800032ce:	8526                	mv	a0,s1
    800032d0:	60e6                	ld	ra,88(sp)
    800032d2:	6446                	ld	s0,80(sp)
    800032d4:	64a6                	ld	s1,72(sp)
    800032d6:	6906                	ld	s2,64(sp)
    800032d8:	79e2                	ld	s3,56(sp)
    800032da:	7a42                	ld	s4,48(sp)
    800032dc:	7aa2                	ld	s5,40(sp)
    800032de:	7b02                	ld	s6,32(sp)
    800032e0:	6be2                	ld	s7,24(sp)
    800032e2:	6c42                	ld	s8,16(sp)
    800032e4:	6ca2                	ld	s9,8(sp)
    800032e6:	6125                	addi	sp,sp,96
    800032e8:	8082                	ret

00000000800032ea <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032ea:	7179                	addi	sp,sp,-48
    800032ec:	f406                	sd	ra,40(sp)
    800032ee:	f022                	sd	s0,32(sp)
    800032f0:	ec26                	sd	s1,24(sp)
    800032f2:	e84a                	sd	s2,16(sp)
    800032f4:	e44e                	sd	s3,8(sp)
    800032f6:	e052                	sd	s4,0(sp)
    800032f8:	1800                	addi	s0,sp,48
    800032fa:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032fc:	47ad                	li	a5,11
    800032fe:	04b7fe63          	bgeu	a5,a1,8000335a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003302:	ff45849b          	addiw	s1,a1,-12
    80003306:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000330a:	0ff00793          	li	a5,255
    8000330e:	0ae7e463          	bltu	a5,a4,800033b6 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003312:	08052583          	lw	a1,128(a0)
    80003316:	c5b5                	beqz	a1,80003382 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003318:	00092503          	lw	a0,0(s2)
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	bda080e7          	jalr	-1062(ra) # 80002ef6 <bread>
    80003324:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003326:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000332a:	02049713          	slli	a4,s1,0x20
    8000332e:	01e75593          	srli	a1,a4,0x1e
    80003332:	00b784b3          	add	s1,a5,a1
    80003336:	0004a983          	lw	s3,0(s1)
    8000333a:	04098e63          	beqz	s3,80003396 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000333e:	8552                	mv	a0,s4
    80003340:	00000097          	auipc	ra,0x0
    80003344:	ce6080e7          	jalr	-794(ra) # 80003026 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003348:	854e                	mv	a0,s3
    8000334a:	70a2                	ld	ra,40(sp)
    8000334c:	7402                	ld	s0,32(sp)
    8000334e:	64e2                	ld	s1,24(sp)
    80003350:	6942                	ld	s2,16(sp)
    80003352:	69a2                	ld	s3,8(sp)
    80003354:	6a02                	ld	s4,0(sp)
    80003356:	6145                	addi	sp,sp,48
    80003358:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000335a:	02059793          	slli	a5,a1,0x20
    8000335e:	01e7d593          	srli	a1,a5,0x1e
    80003362:	00b504b3          	add	s1,a0,a1
    80003366:	0504a983          	lw	s3,80(s1)
    8000336a:	fc099fe3          	bnez	s3,80003348 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000336e:	4108                	lw	a0,0(a0)
    80003370:	00000097          	auipc	ra,0x0
    80003374:	e48080e7          	jalr	-440(ra) # 800031b8 <balloc>
    80003378:	0005099b          	sext.w	s3,a0
    8000337c:	0534a823          	sw	s3,80(s1)
    80003380:	b7e1                	j	80003348 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003382:	4108                	lw	a0,0(a0)
    80003384:	00000097          	auipc	ra,0x0
    80003388:	e34080e7          	jalr	-460(ra) # 800031b8 <balloc>
    8000338c:	0005059b          	sext.w	a1,a0
    80003390:	08b92023          	sw	a1,128(s2)
    80003394:	b751                	j	80003318 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003396:	00092503          	lw	a0,0(s2)
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	e1e080e7          	jalr	-482(ra) # 800031b8 <balloc>
    800033a2:	0005099b          	sext.w	s3,a0
    800033a6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033aa:	8552                	mv	a0,s4
    800033ac:	00001097          	auipc	ra,0x1
    800033b0:	efc080e7          	jalr	-260(ra) # 800042a8 <log_write>
    800033b4:	b769                	j	8000333e <bmap+0x54>
  panic("bmap: out of range");
    800033b6:	00005517          	auipc	a0,0x5
    800033ba:	29a50513          	addi	a0,a0,666 # 80008650 <syscalls+0x120>
    800033be:	ffffd097          	auipc	ra,0xffffd
    800033c2:	16c080e7          	jalr	364(ra) # 8000052a <panic>

00000000800033c6 <iget>:
{
    800033c6:	7179                	addi	sp,sp,-48
    800033c8:	f406                	sd	ra,40(sp)
    800033ca:	f022                	sd	s0,32(sp)
    800033cc:	ec26                	sd	s1,24(sp)
    800033ce:	e84a                	sd	s2,16(sp)
    800033d0:	e44e                	sd	s3,8(sp)
    800033d2:	e052                	sd	s4,0(sp)
    800033d4:	1800                	addi	s0,sp,48
    800033d6:	89aa                	mv	s3,a0
    800033d8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033da:	0001c517          	auipc	a0,0x1c
    800033de:	3ee50513          	addi	a0,a0,1006 # 8001f7c8 <itable>
    800033e2:	ffffd097          	auipc	ra,0xffffd
    800033e6:	7e0080e7          	jalr	2016(ra) # 80000bc2 <acquire>
  empty = 0;
    800033ea:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ec:	0001c497          	auipc	s1,0x1c
    800033f0:	3f448493          	addi	s1,s1,1012 # 8001f7e0 <itable+0x18>
    800033f4:	0001e697          	auipc	a3,0x1e
    800033f8:	e7c68693          	addi	a3,a3,-388 # 80021270 <log>
    800033fc:	a039                	j	8000340a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033fe:	02090b63          	beqz	s2,80003434 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003402:	08848493          	addi	s1,s1,136
    80003406:	02d48a63          	beq	s1,a3,8000343a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000340a:	449c                	lw	a5,8(s1)
    8000340c:	fef059e3          	blez	a5,800033fe <iget+0x38>
    80003410:	4098                	lw	a4,0(s1)
    80003412:	ff3716e3          	bne	a4,s3,800033fe <iget+0x38>
    80003416:	40d8                	lw	a4,4(s1)
    80003418:	ff4713e3          	bne	a4,s4,800033fe <iget+0x38>
      ip->ref++;
    8000341c:	2785                	addiw	a5,a5,1
    8000341e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003420:	0001c517          	auipc	a0,0x1c
    80003424:	3a850513          	addi	a0,a0,936 # 8001f7c8 <itable>
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	84e080e7          	jalr	-1970(ra) # 80000c76 <release>
      return ip;
    80003430:	8926                	mv	s2,s1
    80003432:	a03d                	j	80003460 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003434:	f7f9                	bnez	a5,80003402 <iget+0x3c>
    80003436:	8926                	mv	s2,s1
    80003438:	b7e9                	j	80003402 <iget+0x3c>
  if(empty == 0)
    8000343a:	02090c63          	beqz	s2,80003472 <iget+0xac>
  ip->dev = dev;
    8000343e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003442:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003446:	4785                	li	a5,1
    80003448:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000344c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003450:	0001c517          	auipc	a0,0x1c
    80003454:	37850513          	addi	a0,a0,888 # 8001f7c8 <itable>
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	81e080e7          	jalr	-2018(ra) # 80000c76 <release>
}
    80003460:	854a                	mv	a0,s2
    80003462:	70a2                	ld	ra,40(sp)
    80003464:	7402                	ld	s0,32(sp)
    80003466:	64e2                	ld	s1,24(sp)
    80003468:	6942                	ld	s2,16(sp)
    8000346a:	69a2                	ld	s3,8(sp)
    8000346c:	6a02                	ld	s4,0(sp)
    8000346e:	6145                	addi	sp,sp,48
    80003470:	8082                	ret
    panic("iget: no inodes");
    80003472:	00005517          	auipc	a0,0x5
    80003476:	1f650513          	addi	a0,a0,502 # 80008668 <syscalls+0x138>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	0b0080e7          	jalr	176(ra) # 8000052a <panic>

0000000080003482 <fsinit>:
fsinit(int dev) {
    80003482:	7179                	addi	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	1800                	addi	s0,sp,48
    80003490:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003492:	4585                	li	a1,1
    80003494:	00000097          	auipc	ra,0x0
    80003498:	a62080e7          	jalr	-1438(ra) # 80002ef6 <bread>
    8000349c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000349e:	0001c997          	auipc	s3,0x1c
    800034a2:	30a98993          	addi	s3,s3,778 # 8001f7a8 <sb>
    800034a6:	02000613          	li	a2,32
    800034aa:	05850593          	addi	a1,a0,88
    800034ae:	854e                	mv	a0,s3
    800034b0:	ffffe097          	auipc	ra,0xffffe
    800034b4:	86a080e7          	jalr	-1942(ra) # 80000d1a <memmove>
  brelse(bp);
    800034b8:	8526                	mv	a0,s1
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	b6c080e7          	jalr	-1172(ra) # 80003026 <brelse>
  if(sb.magic != FSMAGIC)
    800034c2:	0009a703          	lw	a4,0(s3)
    800034c6:	102037b7          	lui	a5,0x10203
    800034ca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034ce:	02f71263          	bne	a4,a5,800034f2 <fsinit+0x70>
  initlog(dev, &sb);
    800034d2:	0001c597          	auipc	a1,0x1c
    800034d6:	2d658593          	addi	a1,a1,726 # 8001f7a8 <sb>
    800034da:	854a                	mv	a0,s2
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	b4e080e7          	jalr	-1202(ra) # 8000402a <initlog>
}
    800034e4:	70a2                	ld	ra,40(sp)
    800034e6:	7402                	ld	s0,32(sp)
    800034e8:	64e2                	ld	s1,24(sp)
    800034ea:	6942                	ld	s2,16(sp)
    800034ec:	69a2                	ld	s3,8(sp)
    800034ee:	6145                	addi	sp,sp,48
    800034f0:	8082                	ret
    panic("invalid file system");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	18650513          	addi	a0,a0,390 # 80008678 <syscalls+0x148>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	030080e7          	jalr	48(ra) # 8000052a <panic>

0000000080003502 <iinit>:
{
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	e84a                	sd	s2,16(sp)
    8000350c:	e44e                	sd	s3,8(sp)
    8000350e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003510:	00005597          	auipc	a1,0x5
    80003514:	18058593          	addi	a1,a1,384 # 80008690 <syscalls+0x160>
    80003518:	0001c517          	auipc	a0,0x1c
    8000351c:	2b050513          	addi	a0,a0,688 # 8001f7c8 <itable>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	612080e7          	jalr	1554(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003528:	0001c497          	auipc	s1,0x1c
    8000352c:	2c848493          	addi	s1,s1,712 # 8001f7f0 <itable+0x28>
    80003530:	0001e997          	auipc	s3,0x1e
    80003534:	d5098993          	addi	s3,s3,-688 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003538:	00005917          	auipc	s2,0x5
    8000353c:	16090913          	addi	s2,s2,352 # 80008698 <syscalls+0x168>
    80003540:	85ca                	mv	a1,s2
    80003542:	8526                	mv	a0,s1
    80003544:	00001097          	auipc	ra,0x1
    80003548:	e4a080e7          	jalr	-438(ra) # 8000438e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000354c:	08848493          	addi	s1,s1,136
    80003550:	ff3498e3          	bne	s1,s3,80003540 <iinit+0x3e>
}
    80003554:	70a2                	ld	ra,40(sp)
    80003556:	7402                	ld	s0,32(sp)
    80003558:	64e2                	ld	s1,24(sp)
    8000355a:	6942                	ld	s2,16(sp)
    8000355c:	69a2                	ld	s3,8(sp)
    8000355e:	6145                	addi	sp,sp,48
    80003560:	8082                	ret

0000000080003562 <ialloc>:
{
    80003562:	715d                	addi	sp,sp,-80
    80003564:	e486                	sd	ra,72(sp)
    80003566:	e0a2                	sd	s0,64(sp)
    80003568:	fc26                	sd	s1,56(sp)
    8000356a:	f84a                	sd	s2,48(sp)
    8000356c:	f44e                	sd	s3,40(sp)
    8000356e:	f052                	sd	s4,32(sp)
    80003570:	ec56                	sd	s5,24(sp)
    80003572:	e85a                	sd	s6,16(sp)
    80003574:	e45e                	sd	s7,8(sp)
    80003576:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003578:	0001c717          	auipc	a4,0x1c
    8000357c:	23c72703          	lw	a4,572(a4) # 8001f7b4 <sb+0xc>
    80003580:	4785                	li	a5,1
    80003582:	04e7fa63          	bgeu	a5,a4,800035d6 <ialloc+0x74>
    80003586:	8aaa                	mv	s5,a0
    80003588:	8bae                	mv	s7,a1
    8000358a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000358c:	0001ca17          	auipc	s4,0x1c
    80003590:	21ca0a13          	addi	s4,s4,540 # 8001f7a8 <sb>
    80003594:	00048b1b          	sext.w	s6,s1
    80003598:	0044d793          	srli	a5,s1,0x4
    8000359c:	018a2583          	lw	a1,24(s4)
    800035a0:	9dbd                	addw	a1,a1,a5
    800035a2:	8556                	mv	a0,s5
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	952080e7          	jalr	-1710(ra) # 80002ef6 <bread>
    800035ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035ae:	05850993          	addi	s3,a0,88
    800035b2:	00f4f793          	andi	a5,s1,15
    800035b6:	079a                	slli	a5,a5,0x6
    800035b8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ba:	00099783          	lh	a5,0(s3)
    800035be:	c785                	beqz	a5,800035e6 <ialloc+0x84>
    brelse(bp);
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	a66080e7          	jalr	-1434(ra) # 80003026 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035c8:	0485                	addi	s1,s1,1
    800035ca:	00ca2703          	lw	a4,12(s4)
    800035ce:	0004879b          	sext.w	a5,s1
    800035d2:	fce7e1e3          	bltu	a5,a4,80003594 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035d6:	00005517          	auipc	a0,0x5
    800035da:	0ca50513          	addi	a0,a0,202 # 800086a0 <syscalls+0x170>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	f4c080e7          	jalr	-180(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800035e6:	04000613          	li	a2,64
    800035ea:	4581                	li	a1,0
    800035ec:	854e                	mv	a0,s3
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	6d0080e7          	jalr	1744(ra) # 80000cbe <memset>
      dip->type = type;
    800035f6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035fa:	854a                	mv	a0,s2
    800035fc:	00001097          	auipc	ra,0x1
    80003600:	cac080e7          	jalr	-852(ra) # 800042a8 <log_write>
      brelse(bp);
    80003604:	854a                	mv	a0,s2
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	a20080e7          	jalr	-1504(ra) # 80003026 <brelse>
      return iget(dev, inum);
    8000360e:	85da                	mv	a1,s6
    80003610:	8556                	mv	a0,s5
    80003612:	00000097          	auipc	ra,0x0
    80003616:	db4080e7          	jalr	-588(ra) # 800033c6 <iget>
}
    8000361a:	60a6                	ld	ra,72(sp)
    8000361c:	6406                	ld	s0,64(sp)
    8000361e:	74e2                	ld	s1,56(sp)
    80003620:	7942                	ld	s2,48(sp)
    80003622:	79a2                	ld	s3,40(sp)
    80003624:	7a02                	ld	s4,32(sp)
    80003626:	6ae2                	ld	s5,24(sp)
    80003628:	6b42                	ld	s6,16(sp)
    8000362a:	6ba2                	ld	s7,8(sp)
    8000362c:	6161                	addi	sp,sp,80
    8000362e:	8082                	ret

0000000080003630 <iupdate>:
{
    80003630:	1101                	addi	sp,sp,-32
    80003632:	ec06                	sd	ra,24(sp)
    80003634:	e822                	sd	s0,16(sp)
    80003636:	e426                	sd	s1,8(sp)
    80003638:	e04a                	sd	s2,0(sp)
    8000363a:	1000                	addi	s0,sp,32
    8000363c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000363e:	415c                	lw	a5,4(a0)
    80003640:	0047d79b          	srliw	a5,a5,0x4
    80003644:	0001c597          	auipc	a1,0x1c
    80003648:	17c5a583          	lw	a1,380(a1) # 8001f7c0 <sb+0x18>
    8000364c:	9dbd                	addw	a1,a1,a5
    8000364e:	4108                	lw	a0,0(a0)
    80003650:	00000097          	auipc	ra,0x0
    80003654:	8a6080e7          	jalr	-1882(ra) # 80002ef6 <bread>
    80003658:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000365a:	05850793          	addi	a5,a0,88
    8000365e:	40c8                	lw	a0,4(s1)
    80003660:	893d                	andi	a0,a0,15
    80003662:	051a                	slli	a0,a0,0x6
    80003664:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003666:	04449703          	lh	a4,68(s1)
    8000366a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000366e:	04649703          	lh	a4,70(s1)
    80003672:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003676:	04849703          	lh	a4,72(s1)
    8000367a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000367e:	04a49703          	lh	a4,74(s1)
    80003682:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003686:	44f8                	lw	a4,76(s1)
    80003688:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000368a:	03400613          	li	a2,52
    8000368e:	05048593          	addi	a1,s1,80
    80003692:	0531                	addi	a0,a0,12
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	686080e7          	jalr	1670(ra) # 80000d1a <memmove>
  log_write(bp);
    8000369c:	854a                	mv	a0,s2
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	c0a080e7          	jalr	-1014(ra) # 800042a8 <log_write>
  brelse(bp);
    800036a6:	854a                	mv	a0,s2
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	97e080e7          	jalr	-1666(ra) # 80003026 <brelse>
}
    800036b0:	60e2                	ld	ra,24(sp)
    800036b2:	6442                	ld	s0,16(sp)
    800036b4:	64a2                	ld	s1,8(sp)
    800036b6:	6902                	ld	s2,0(sp)
    800036b8:	6105                	addi	sp,sp,32
    800036ba:	8082                	ret

00000000800036bc <idup>:
{
    800036bc:	1101                	addi	sp,sp,-32
    800036be:	ec06                	sd	ra,24(sp)
    800036c0:	e822                	sd	s0,16(sp)
    800036c2:	e426                	sd	s1,8(sp)
    800036c4:	1000                	addi	s0,sp,32
    800036c6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036c8:	0001c517          	auipc	a0,0x1c
    800036cc:	10050513          	addi	a0,a0,256 # 8001f7c8 <itable>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	4f2080e7          	jalr	1266(ra) # 80000bc2 <acquire>
  ip->ref++;
    800036d8:	449c                	lw	a5,8(s1)
    800036da:	2785                	addiw	a5,a5,1
    800036dc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036de:	0001c517          	auipc	a0,0x1c
    800036e2:	0ea50513          	addi	a0,a0,234 # 8001f7c8 <itable>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	590080e7          	jalr	1424(ra) # 80000c76 <release>
}
    800036ee:	8526                	mv	a0,s1
    800036f0:	60e2                	ld	ra,24(sp)
    800036f2:	6442                	ld	s0,16(sp)
    800036f4:	64a2                	ld	s1,8(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret

00000000800036fa <ilock>:
{
    800036fa:	1101                	addi	sp,sp,-32
    800036fc:	ec06                	sd	ra,24(sp)
    800036fe:	e822                	sd	s0,16(sp)
    80003700:	e426                	sd	s1,8(sp)
    80003702:	e04a                	sd	s2,0(sp)
    80003704:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003706:	c115                	beqz	a0,8000372a <ilock+0x30>
    80003708:	84aa                	mv	s1,a0
    8000370a:	451c                	lw	a5,8(a0)
    8000370c:	00f05f63          	blez	a5,8000372a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003710:	0541                	addi	a0,a0,16
    80003712:	00001097          	auipc	ra,0x1
    80003716:	cb6080e7          	jalr	-842(ra) # 800043c8 <acquiresleep>
  if(ip->valid == 0){
    8000371a:	40bc                	lw	a5,64(s1)
    8000371c:	cf99                	beqz	a5,8000373a <ilock+0x40>
}
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6902                	ld	s2,0(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret
    panic("ilock");
    8000372a:	00005517          	auipc	a0,0x5
    8000372e:	f8e50513          	addi	a0,a0,-114 # 800086b8 <syscalls+0x188>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	df8080e7          	jalr	-520(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000373a:	40dc                	lw	a5,4(s1)
    8000373c:	0047d79b          	srliw	a5,a5,0x4
    80003740:	0001c597          	auipc	a1,0x1c
    80003744:	0805a583          	lw	a1,128(a1) # 8001f7c0 <sb+0x18>
    80003748:	9dbd                	addw	a1,a1,a5
    8000374a:	4088                	lw	a0,0(s1)
    8000374c:	fffff097          	auipc	ra,0xfffff
    80003750:	7aa080e7          	jalr	1962(ra) # 80002ef6 <bread>
    80003754:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003756:	05850593          	addi	a1,a0,88
    8000375a:	40dc                	lw	a5,4(s1)
    8000375c:	8bbd                	andi	a5,a5,15
    8000375e:	079a                	slli	a5,a5,0x6
    80003760:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003762:	00059783          	lh	a5,0(a1)
    80003766:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000376a:	00259783          	lh	a5,2(a1)
    8000376e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003772:	00459783          	lh	a5,4(a1)
    80003776:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000377a:	00659783          	lh	a5,6(a1)
    8000377e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003782:	459c                	lw	a5,8(a1)
    80003784:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003786:	03400613          	li	a2,52
    8000378a:	05b1                	addi	a1,a1,12
    8000378c:	05048513          	addi	a0,s1,80
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	58a080e7          	jalr	1418(ra) # 80000d1a <memmove>
    brelse(bp);
    80003798:	854a                	mv	a0,s2
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	88c080e7          	jalr	-1908(ra) # 80003026 <brelse>
    ip->valid = 1;
    800037a2:	4785                	li	a5,1
    800037a4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037a6:	04449783          	lh	a5,68(s1)
    800037aa:	fbb5                	bnez	a5,8000371e <ilock+0x24>
      panic("ilock: no type");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	f1450513          	addi	a0,a0,-236 # 800086c0 <syscalls+0x190>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	d76080e7          	jalr	-650(ra) # 8000052a <panic>

00000000800037bc <iunlock>:
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	e04a                	sd	s2,0(sp)
    800037c6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037c8:	c905                	beqz	a0,800037f8 <iunlock+0x3c>
    800037ca:	84aa                	mv	s1,a0
    800037cc:	01050913          	addi	s2,a0,16
    800037d0:	854a                	mv	a0,s2
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	c90080e7          	jalr	-880(ra) # 80004462 <holdingsleep>
    800037da:	cd19                	beqz	a0,800037f8 <iunlock+0x3c>
    800037dc:	449c                	lw	a5,8(s1)
    800037de:	00f05d63          	blez	a5,800037f8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037e2:	854a                	mv	a0,s2
    800037e4:	00001097          	auipc	ra,0x1
    800037e8:	c3a080e7          	jalr	-966(ra) # 8000441e <releasesleep>
}
    800037ec:	60e2                	ld	ra,24(sp)
    800037ee:	6442                	ld	s0,16(sp)
    800037f0:	64a2                	ld	s1,8(sp)
    800037f2:	6902                	ld	s2,0(sp)
    800037f4:	6105                	addi	sp,sp,32
    800037f6:	8082                	ret
    panic("iunlock");
    800037f8:	00005517          	auipc	a0,0x5
    800037fc:	ed850513          	addi	a0,a0,-296 # 800086d0 <syscalls+0x1a0>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	d2a080e7          	jalr	-726(ra) # 8000052a <panic>

0000000080003808 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003808:	7179                	addi	sp,sp,-48
    8000380a:	f406                	sd	ra,40(sp)
    8000380c:	f022                	sd	s0,32(sp)
    8000380e:	ec26                	sd	s1,24(sp)
    80003810:	e84a                	sd	s2,16(sp)
    80003812:	e44e                	sd	s3,8(sp)
    80003814:	e052                	sd	s4,0(sp)
    80003816:	1800                	addi	s0,sp,48
    80003818:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000381a:	05050493          	addi	s1,a0,80
    8000381e:	08050913          	addi	s2,a0,128
    80003822:	a021                	j	8000382a <itrunc+0x22>
    80003824:	0491                	addi	s1,s1,4
    80003826:	01248d63          	beq	s1,s2,80003840 <itrunc+0x38>
    if(ip->addrs[i]){
    8000382a:	408c                	lw	a1,0(s1)
    8000382c:	dde5                	beqz	a1,80003824 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000382e:	0009a503          	lw	a0,0(s3)
    80003832:	00000097          	auipc	ra,0x0
    80003836:	90a080e7          	jalr	-1782(ra) # 8000313c <bfree>
      ip->addrs[i] = 0;
    8000383a:	0004a023          	sw	zero,0(s1)
    8000383e:	b7dd                	j	80003824 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003840:	0809a583          	lw	a1,128(s3)
    80003844:	e185                	bnez	a1,80003864 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003846:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000384a:	854e                	mv	a0,s3
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	de4080e7          	jalr	-540(ra) # 80003630 <iupdate>
}
    80003854:	70a2                	ld	ra,40(sp)
    80003856:	7402                	ld	s0,32(sp)
    80003858:	64e2                	ld	s1,24(sp)
    8000385a:	6942                	ld	s2,16(sp)
    8000385c:	69a2                	ld	s3,8(sp)
    8000385e:	6a02                	ld	s4,0(sp)
    80003860:	6145                	addi	sp,sp,48
    80003862:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003864:	0009a503          	lw	a0,0(s3)
    80003868:	fffff097          	auipc	ra,0xfffff
    8000386c:	68e080e7          	jalr	1678(ra) # 80002ef6 <bread>
    80003870:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003872:	05850493          	addi	s1,a0,88
    80003876:	45850913          	addi	s2,a0,1112
    8000387a:	a021                	j	80003882 <itrunc+0x7a>
    8000387c:	0491                	addi	s1,s1,4
    8000387e:	01248b63          	beq	s1,s2,80003894 <itrunc+0x8c>
      if(a[j])
    80003882:	408c                	lw	a1,0(s1)
    80003884:	dde5                	beqz	a1,8000387c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003886:	0009a503          	lw	a0,0(s3)
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	8b2080e7          	jalr	-1870(ra) # 8000313c <bfree>
    80003892:	b7ed                	j	8000387c <itrunc+0x74>
    brelse(bp);
    80003894:	8552                	mv	a0,s4
    80003896:	fffff097          	auipc	ra,0xfffff
    8000389a:	790080e7          	jalr	1936(ra) # 80003026 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000389e:	0809a583          	lw	a1,128(s3)
    800038a2:	0009a503          	lw	a0,0(s3)
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	896080e7          	jalr	-1898(ra) # 8000313c <bfree>
    ip->addrs[NDIRECT] = 0;
    800038ae:	0809a023          	sw	zero,128(s3)
    800038b2:	bf51                	j	80003846 <itrunc+0x3e>

00000000800038b4 <iput>:
{
    800038b4:	1101                	addi	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	e04a                	sd	s2,0(sp)
    800038be:	1000                	addi	s0,sp,32
    800038c0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038c2:	0001c517          	auipc	a0,0x1c
    800038c6:	f0650513          	addi	a0,a0,-250 # 8001f7c8 <itable>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	2f8080e7          	jalr	760(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038d2:	4498                	lw	a4,8(s1)
    800038d4:	4785                	li	a5,1
    800038d6:	02f70363          	beq	a4,a5,800038fc <iput+0x48>
  ip->ref--;
    800038da:	449c                	lw	a5,8(s1)
    800038dc:	37fd                	addiw	a5,a5,-1
    800038de:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038e0:	0001c517          	auipc	a0,0x1c
    800038e4:	ee850513          	addi	a0,a0,-280 # 8001f7c8 <itable>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	38e080e7          	jalr	910(ra) # 80000c76 <release>
}
    800038f0:	60e2                	ld	ra,24(sp)
    800038f2:	6442                	ld	s0,16(sp)
    800038f4:	64a2                	ld	s1,8(sp)
    800038f6:	6902                	ld	s2,0(sp)
    800038f8:	6105                	addi	sp,sp,32
    800038fa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038fc:	40bc                	lw	a5,64(s1)
    800038fe:	dff1                	beqz	a5,800038da <iput+0x26>
    80003900:	04a49783          	lh	a5,74(s1)
    80003904:	fbf9                	bnez	a5,800038da <iput+0x26>
    acquiresleep(&ip->lock);
    80003906:	01048913          	addi	s2,s1,16
    8000390a:	854a                	mv	a0,s2
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	abc080e7          	jalr	-1348(ra) # 800043c8 <acquiresleep>
    release(&itable.lock);
    80003914:	0001c517          	auipc	a0,0x1c
    80003918:	eb450513          	addi	a0,a0,-332 # 8001f7c8 <itable>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	35a080e7          	jalr	858(ra) # 80000c76 <release>
    itrunc(ip);
    80003924:	8526                	mv	a0,s1
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	ee2080e7          	jalr	-286(ra) # 80003808 <itrunc>
    ip->type = 0;
    8000392e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003932:	8526                	mv	a0,s1
    80003934:	00000097          	auipc	ra,0x0
    80003938:	cfc080e7          	jalr	-772(ra) # 80003630 <iupdate>
    ip->valid = 0;
    8000393c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003940:	854a                	mv	a0,s2
    80003942:	00001097          	auipc	ra,0x1
    80003946:	adc080e7          	jalr	-1316(ra) # 8000441e <releasesleep>
    acquire(&itable.lock);
    8000394a:	0001c517          	auipc	a0,0x1c
    8000394e:	e7e50513          	addi	a0,a0,-386 # 8001f7c8 <itable>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	270080e7          	jalr	624(ra) # 80000bc2 <acquire>
    8000395a:	b741                	j	800038da <iput+0x26>

000000008000395c <iunlockput>:
{
    8000395c:	1101                	addi	sp,sp,-32
    8000395e:	ec06                	sd	ra,24(sp)
    80003960:	e822                	sd	s0,16(sp)
    80003962:	e426                	sd	s1,8(sp)
    80003964:	1000                	addi	s0,sp,32
    80003966:	84aa                	mv	s1,a0
  iunlock(ip);
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	e54080e7          	jalr	-428(ra) # 800037bc <iunlock>
  iput(ip);
    80003970:	8526                	mv	a0,s1
    80003972:	00000097          	auipc	ra,0x0
    80003976:	f42080e7          	jalr	-190(ra) # 800038b4 <iput>
}
    8000397a:	60e2                	ld	ra,24(sp)
    8000397c:	6442                	ld	s0,16(sp)
    8000397e:	64a2                	ld	s1,8(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret

0000000080003984 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003984:	1141                	addi	sp,sp,-16
    80003986:	e422                	sd	s0,8(sp)
    80003988:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000398a:	411c                	lw	a5,0(a0)
    8000398c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000398e:	415c                	lw	a5,4(a0)
    80003990:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003992:	04451783          	lh	a5,68(a0)
    80003996:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000399a:	04a51783          	lh	a5,74(a0)
    8000399e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039a2:	04c56783          	lwu	a5,76(a0)
    800039a6:	e99c                	sd	a5,16(a1)
}
    800039a8:	6422                	ld	s0,8(sp)
    800039aa:	0141                	addi	sp,sp,16
    800039ac:	8082                	ret

00000000800039ae <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ae:	457c                	lw	a5,76(a0)
    800039b0:	0ed7e963          	bltu	a5,a3,80003aa2 <readi+0xf4>
{
    800039b4:	7159                	addi	sp,sp,-112
    800039b6:	f486                	sd	ra,104(sp)
    800039b8:	f0a2                	sd	s0,96(sp)
    800039ba:	eca6                	sd	s1,88(sp)
    800039bc:	e8ca                	sd	s2,80(sp)
    800039be:	e4ce                	sd	s3,72(sp)
    800039c0:	e0d2                	sd	s4,64(sp)
    800039c2:	fc56                	sd	s5,56(sp)
    800039c4:	f85a                	sd	s6,48(sp)
    800039c6:	f45e                	sd	s7,40(sp)
    800039c8:	f062                	sd	s8,32(sp)
    800039ca:	ec66                	sd	s9,24(sp)
    800039cc:	e86a                	sd	s10,16(sp)
    800039ce:	e46e                	sd	s11,8(sp)
    800039d0:	1880                	addi	s0,sp,112
    800039d2:	8baa                	mv	s7,a0
    800039d4:	8c2e                	mv	s8,a1
    800039d6:	8ab2                	mv	s5,a2
    800039d8:	84b6                	mv	s1,a3
    800039da:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039dc:	9f35                	addw	a4,a4,a3
    return 0;
    800039de:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039e0:	0ad76063          	bltu	a4,a3,80003a80 <readi+0xd2>
  if(off + n > ip->size)
    800039e4:	00e7f463          	bgeu	a5,a4,800039ec <readi+0x3e>
    n = ip->size - off;
    800039e8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ec:	0a0b0963          	beqz	s6,80003a9e <readi+0xf0>
    800039f0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039f6:	5cfd                	li	s9,-1
    800039f8:	a82d                	j	80003a32 <readi+0x84>
    800039fa:	020a1d93          	slli	s11,s4,0x20
    800039fe:	020ddd93          	srli	s11,s11,0x20
    80003a02:	05890793          	addi	a5,s2,88
    80003a06:	86ee                	mv	a3,s11
    80003a08:	963e                	add	a2,a2,a5
    80003a0a:	85d6                	mv	a1,s5
    80003a0c:	8562                	mv	a0,s8
    80003a0e:	fffff097          	auipc	ra,0xfffff
    80003a12:	a28080e7          	jalr	-1496(ra) # 80002436 <either_copyout>
    80003a16:	05950d63          	beq	a0,s9,80003a70 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a1a:	854a                	mv	a0,s2
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	60a080e7          	jalr	1546(ra) # 80003026 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a24:	013a09bb          	addw	s3,s4,s3
    80003a28:	009a04bb          	addw	s1,s4,s1
    80003a2c:	9aee                	add	s5,s5,s11
    80003a2e:	0569f763          	bgeu	s3,s6,80003a7c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a32:	000ba903          	lw	s2,0(s7)
    80003a36:	00a4d59b          	srliw	a1,s1,0xa
    80003a3a:	855e                	mv	a0,s7
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	8ae080e7          	jalr	-1874(ra) # 800032ea <bmap>
    80003a44:	0005059b          	sext.w	a1,a0
    80003a48:	854a                	mv	a0,s2
    80003a4a:	fffff097          	auipc	ra,0xfffff
    80003a4e:	4ac080e7          	jalr	1196(ra) # 80002ef6 <bread>
    80003a52:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a54:	3ff4f613          	andi	a2,s1,1023
    80003a58:	40cd07bb          	subw	a5,s10,a2
    80003a5c:	413b073b          	subw	a4,s6,s3
    80003a60:	8a3e                	mv	s4,a5
    80003a62:	2781                	sext.w	a5,a5
    80003a64:	0007069b          	sext.w	a3,a4
    80003a68:	f8f6f9e3          	bgeu	a3,a5,800039fa <readi+0x4c>
    80003a6c:	8a3a                	mv	s4,a4
    80003a6e:	b771                	j	800039fa <readi+0x4c>
      brelse(bp);
    80003a70:	854a                	mv	a0,s2
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	5b4080e7          	jalr	1460(ra) # 80003026 <brelse>
      tot = -1;
    80003a7a:	59fd                	li	s3,-1
  }
  return tot;
    80003a7c:	0009851b          	sext.w	a0,s3
}
    80003a80:	70a6                	ld	ra,104(sp)
    80003a82:	7406                	ld	s0,96(sp)
    80003a84:	64e6                	ld	s1,88(sp)
    80003a86:	6946                	ld	s2,80(sp)
    80003a88:	69a6                	ld	s3,72(sp)
    80003a8a:	6a06                	ld	s4,64(sp)
    80003a8c:	7ae2                	ld	s5,56(sp)
    80003a8e:	7b42                	ld	s6,48(sp)
    80003a90:	7ba2                	ld	s7,40(sp)
    80003a92:	7c02                	ld	s8,32(sp)
    80003a94:	6ce2                	ld	s9,24(sp)
    80003a96:	6d42                	ld	s10,16(sp)
    80003a98:	6da2                	ld	s11,8(sp)
    80003a9a:	6165                	addi	sp,sp,112
    80003a9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9e:	89da                	mv	s3,s6
    80003aa0:	bff1                	j	80003a7c <readi+0xce>
    return 0;
    80003aa2:	4501                	li	a0,0
}
    80003aa4:	8082                	ret

0000000080003aa6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aa6:	457c                	lw	a5,76(a0)
    80003aa8:	10d7e863          	bltu	a5,a3,80003bb8 <writei+0x112>
{
    80003aac:	7159                	addi	sp,sp,-112
    80003aae:	f486                	sd	ra,104(sp)
    80003ab0:	f0a2                	sd	s0,96(sp)
    80003ab2:	eca6                	sd	s1,88(sp)
    80003ab4:	e8ca                	sd	s2,80(sp)
    80003ab6:	e4ce                	sd	s3,72(sp)
    80003ab8:	e0d2                	sd	s4,64(sp)
    80003aba:	fc56                	sd	s5,56(sp)
    80003abc:	f85a                	sd	s6,48(sp)
    80003abe:	f45e                	sd	s7,40(sp)
    80003ac0:	f062                	sd	s8,32(sp)
    80003ac2:	ec66                	sd	s9,24(sp)
    80003ac4:	e86a                	sd	s10,16(sp)
    80003ac6:	e46e                	sd	s11,8(sp)
    80003ac8:	1880                	addi	s0,sp,112
    80003aca:	8b2a                	mv	s6,a0
    80003acc:	8c2e                	mv	s8,a1
    80003ace:	8ab2                	mv	s5,a2
    80003ad0:	8936                	mv	s2,a3
    80003ad2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ad4:	00e687bb          	addw	a5,a3,a4
    80003ad8:	0ed7e263          	bltu	a5,a3,80003bbc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003adc:	00043737          	lui	a4,0x43
    80003ae0:	0ef76063          	bltu	a4,a5,80003bc0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae4:	0c0b8863          	beqz	s7,80003bb4 <writei+0x10e>
    80003ae8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aea:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003aee:	5cfd                	li	s9,-1
    80003af0:	a091                	j	80003b34 <writei+0x8e>
    80003af2:	02099d93          	slli	s11,s3,0x20
    80003af6:	020ddd93          	srli	s11,s11,0x20
    80003afa:	05848793          	addi	a5,s1,88
    80003afe:	86ee                	mv	a3,s11
    80003b00:	8656                	mv	a2,s5
    80003b02:	85e2                	mv	a1,s8
    80003b04:	953e                	add	a0,a0,a5
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	986080e7          	jalr	-1658(ra) # 8000248c <either_copyin>
    80003b0e:	07950263          	beq	a0,s9,80003b72 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b12:	8526                	mv	a0,s1
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	794080e7          	jalr	1940(ra) # 800042a8 <log_write>
    brelse(bp);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	fffff097          	auipc	ra,0xfffff
    80003b22:	508080e7          	jalr	1288(ra) # 80003026 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b26:	01498a3b          	addw	s4,s3,s4
    80003b2a:	0129893b          	addw	s2,s3,s2
    80003b2e:	9aee                	add	s5,s5,s11
    80003b30:	057a7663          	bgeu	s4,s7,80003b7c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b34:	000b2483          	lw	s1,0(s6)
    80003b38:	00a9559b          	srliw	a1,s2,0xa
    80003b3c:	855a                	mv	a0,s6
    80003b3e:	fffff097          	auipc	ra,0xfffff
    80003b42:	7ac080e7          	jalr	1964(ra) # 800032ea <bmap>
    80003b46:	0005059b          	sext.w	a1,a0
    80003b4a:	8526                	mv	a0,s1
    80003b4c:	fffff097          	auipc	ra,0xfffff
    80003b50:	3aa080e7          	jalr	938(ra) # 80002ef6 <bread>
    80003b54:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b56:	3ff97513          	andi	a0,s2,1023
    80003b5a:	40ad07bb          	subw	a5,s10,a0
    80003b5e:	414b873b          	subw	a4,s7,s4
    80003b62:	89be                	mv	s3,a5
    80003b64:	2781                	sext.w	a5,a5
    80003b66:	0007069b          	sext.w	a3,a4
    80003b6a:	f8f6f4e3          	bgeu	a3,a5,80003af2 <writei+0x4c>
    80003b6e:	89ba                	mv	s3,a4
    80003b70:	b749                	j	80003af2 <writei+0x4c>
      brelse(bp);
    80003b72:	8526                	mv	a0,s1
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	4b2080e7          	jalr	1202(ra) # 80003026 <brelse>
  }

  if(off > ip->size)
    80003b7c:	04cb2783          	lw	a5,76(s6)
    80003b80:	0127f463          	bgeu	a5,s2,80003b88 <writei+0xe2>
    ip->size = off;
    80003b84:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b88:	855a                	mv	a0,s6
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	aa6080e7          	jalr	-1370(ra) # 80003630 <iupdate>

  return tot;
    80003b92:	000a051b          	sext.w	a0,s4
}
    80003b96:	70a6                	ld	ra,104(sp)
    80003b98:	7406                	ld	s0,96(sp)
    80003b9a:	64e6                	ld	s1,88(sp)
    80003b9c:	6946                	ld	s2,80(sp)
    80003b9e:	69a6                	ld	s3,72(sp)
    80003ba0:	6a06                	ld	s4,64(sp)
    80003ba2:	7ae2                	ld	s5,56(sp)
    80003ba4:	7b42                	ld	s6,48(sp)
    80003ba6:	7ba2                	ld	s7,40(sp)
    80003ba8:	7c02                	ld	s8,32(sp)
    80003baa:	6ce2                	ld	s9,24(sp)
    80003bac:	6d42                	ld	s10,16(sp)
    80003bae:	6da2                	ld	s11,8(sp)
    80003bb0:	6165                	addi	sp,sp,112
    80003bb2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb4:	8a5e                	mv	s4,s7
    80003bb6:	bfc9                	j	80003b88 <writei+0xe2>
    return -1;
    80003bb8:	557d                	li	a0,-1
}
    80003bba:	8082                	ret
    return -1;
    80003bbc:	557d                	li	a0,-1
    80003bbe:	bfe1                	j	80003b96 <writei+0xf0>
    return -1;
    80003bc0:	557d                	li	a0,-1
    80003bc2:	bfd1                	j	80003b96 <writei+0xf0>

0000000080003bc4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bc4:	1141                	addi	sp,sp,-16
    80003bc6:	e406                	sd	ra,8(sp)
    80003bc8:	e022                	sd	s0,0(sp)
    80003bca:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bcc:	4639                	li	a2,14
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	1c8080e7          	jalr	456(ra) # 80000d96 <strncmp>
}
    80003bd6:	60a2                	ld	ra,8(sp)
    80003bd8:	6402                	ld	s0,0(sp)
    80003bda:	0141                	addi	sp,sp,16
    80003bdc:	8082                	ret

0000000080003bde <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bde:	7139                	addi	sp,sp,-64
    80003be0:	fc06                	sd	ra,56(sp)
    80003be2:	f822                	sd	s0,48(sp)
    80003be4:	f426                	sd	s1,40(sp)
    80003be6:	f04a                	sd	s2,32(sp)
    80003be8:	ec4e                	sd	s3,24(sp)
    80003bea:	e852                	sd	s4,16(sp)
    80003bec:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bee:	04451703          	lh	a4,68(a0)
    80003bf2:	4785                	li	a5,1
    80003bf4:	00f71a63          	bne	a4,a5,80003c08 <dirlookup+0x2a>
    80003bf8:	892a                	mv	s2,a0
    80003bfa:	89ae                	mv	s3,a1
    80003bfc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bfe:	457c                	lw	a5,76(a0)
    80003c00:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c02:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c04:	e79d                	bnez	a5,80003c32 <dirlookup+0x54>
    80003c06:	a8a5                	j	80003c7e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c08:	00005517          	auipc	a0,0x5
    80003c0c:	ad050513          	addi	a0,a0,-1328 # 800086d8 <syscalls+0x1a8>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	91a080e7          	jalr	-1766(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003c18:	00005517          	auipc	a0,0x5
    80003c1c:	ad850513          	addi	a0,a0,-1320 # 800086f0 <syscalls+0x1c0>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	90a080e7          	jalr	-1782(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c28:	24c1                	addiw	s1,s1,16
    80003c2a:	04c92783          	lw	a5,76(s2)
    80003c2e:	04f4f763          	bgeu	s1,a5,80003c7c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c32:	4741                	li	a4,16
    80003c34:	86a6                	mv	a3,s1
    80003c36:	fc040613          	addi	a2,s0,-64
    80003c3a:	4581                	li	a1,0
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	d70080e7          	jalr	-656(ra) # 800039ae <readi>
    80003c46:	47c1                	li	a5,16
    80003c48:	fcf518e3          	bne	a0,a5,80003c18 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c4c:	fc045783          	lhu	a5,-64(s0)
    80003c50:	dfe1                	beqz	a5,80003c28 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c52:	fc240593          	addi	a1,s0,-62
    80003c56:	854e                	mv	a0,s3
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	f6c080e7          	jalr	-148(ra) # 80003bc4 <namecmp>
    80003c60:	f561                	bnez	a0,80003c28 <dirlookup+0x4a>
      if(poff)
    80003c62:	000a0463          	beqz	s4,80003c6a <dirlookup+0x8c>
        *poff = off;
    80003c66:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c6a:	fc045583          	lhu	a1,-64(s0)
    80003c6e:	00092503          	lw	a0,0(s2)
    80003c72:	fffff097          	auipc	ra,0xfffff
    80003c76:	754080e7          	jalr	1876(ra) # 800033c6 <iget>
    80003c7a:	a011                	j	80003c7e <dirlookup+0xa0>
  return 0;
    80003c7c:	4501                	li	a0,0
}
    80003c7e:	70e2                	ld	ra,56(sp)
    80003c80:	7442                	ld	s0,48(sp)
    80003c82:	74a2                	ld	s1,40(sp)
    80003c84:	7902                	ld	s2,32(sp)
    80003c86:	69e2                	ld	s3,24(sp)
    80003c88:	6a42                	ld	s4,16(sp)
    80003c8a:	6121                	addi	sp,sp,64
    80003c8c:	8082                	ret

0000000080003c8e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c8e:	711d                	addi	sp,sp,-96
    80003c90:	ec86                	sd	ra,88(sp)
    80003c92:	e8a2                	sd	s0,80(sp)
    80003c94:	e4a6                	sd	s1,72(sp)
    80003c96:	e0ca                	sd	s2,64(sp)
    80003c98:	fc4e                	sd	s3,56(sp)
    80003c9a:	f852                	sd	s4,48(sp)
    80003c9c:	f456                	sd	s5,40(sp)
    80003c9e:	f05a                	sd	s6,32(sp)
    80003ca0:	ec5e                	sd	s7,24(sp)
    80003ca2:	e862                	sd	s8,16(sp)
    80003ca4:	e466                	sd	s9,8(sp)
    80003ca6:	1080                	addi	s0,sp,96
    80003ca8:	84aa                	mv	s1,a0
    80003caa:	8aae                	mv	s5,a1
    80003cac:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cae:	00054703          	lbu	a4,0(a0)
    80003cb2:	02f00793          	li	a5,47
    80003cb6:	02f70363          	beq	a4,a5,80003cdc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cba:	ffffe097          	auipc	ra,0xffffe
    80003cbe:	cc4080e7          	jalr	-828(ra) # 8000197e <myproc>
    80003cc2:	15053503          	ld	a0,336(a0)
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	9f6080e7          	jalr	-1546(ra) # 800036bc <idup>
    80003cce:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cd0:	02f00913          	li	s2,47
  len = path - s;
    80003cd4:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003cd6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cd8:	4b85                	li	s7,1
    80003cda:	a865                	j	80003d92 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cdc:	4585                	li	a1,1
    80003cde:	4505                	li	a0,1
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	6e6080e7          	jalr	1766(ra) # 800033c6 <iget>
    80003ce8:	89aa                	mv	s3,a0
    80003cea:	b7dd                	j	80003cd0 <namex+0x42>
      iunlockput(ip);
    80003cec:	854e                	mv	a0,s3
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	c6e080e7          	jalr	-914(ra) # 8000395c <iunlockput>
      return 0;
    80003cf6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cf8:	854e                	mv	a0,s3
    80003cfa:	60e6                	ld	ra,88(sp)
    80003cfc:	6446                	ld	s0,80(sp)
    80003cfe:	64a6                	ld	s1,72(sp)
    80003d00:	6906                	ld	s2,64(sp)
    80003d02:	79e2                	ld	s3,56(sp)
    80003d04:	7a42                	ld	s4,48(sp)
    80003d06:	7aa2                	ld	s5,40(sp)
    80003d08:	7b02                	ld	s6,32(sp)
    80003d0a:	6be2                	ld	s7,24(sp)
    80003d0c:	6c42                	ld	s8,16(sp)
    80003d0e:	6ca2                	ld	s9,8(sp)
    80003d10:	6125                	addi	sp,sp,96
    80003d12:	8082                	ret
      iunlock(ip);
    80003d14:	854e                	mv	a0,s3
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	aa6080e7          	jalr	-1370(ra) # 800037bc <iunlock>
      return ip;
    80003d1e:	bfe9                	j	80003cf8 <namex+0x6a>
      iunlockput(ip);
    80003d20:	854e                	mv	a0,s3
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	c3a080e7          	jalr	-966(ra) # 8000395c <iunlockput>
      return 0;
    80003d2a:	89e6                	mv	s3,s9
    80003d2c:	b7f1                	j	80003cf8 <namex+0x6a>
  len = path - s;
    80003d2e:	40b48633          	sub	a2,s1,a1
    80003d32:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d36:	099c5463          	bge	s8,s9,80003dbe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d3a:	4639                	li	a2,14
    80003d3c:	8552                	mv	a0,s4
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	fdc080e7          	jalr	-36(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003d46:	0004c783          	lbu	a5,0(s1)
    80003d4a:	01279763          	bne	a5,s2,80003d58 <namex+0xca>
    path++;
    80003d4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d50:	0004c783          	lbu	a5,0(s1)
    80003d54:	ff278de3          	beq	a5,s2,80003d4e <namex+0xc0>
    ilock(ip);
    80003d58:	854e                	mv	a0,s3
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	9a0080e7          	jalr	-1632(ra) # 800036fa <ilock>
    if(ip->type != T_DIR){
    80003d62:	04499783          	lh	a5,68(s3)
    80003d66:	f97793e3          	bne	a5,s7,80003cec <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d6a:	000a8563          	beqz	s5,80003d74 <namex+0xe6>
    80003d6e:	0004c783          	lbu	a5,0(s1)
    80003d72:	d3cd                	beqz	a5,80003d14 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d74:	865a                	mv	a2,s6
    80003d76:	85d2                	mv	a1,s4
    80003d78:	854e                	mv	a0,s3
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	e64080e7          	jalr	-412(ra) # 80003bde <dirlookup>
    80003d82:	8caa                	mv	s9,a0
    80003d84:	dd51                	beqz	a0,80003d20 <namex+0x92>
    iunlockput(ip);
    80003d86:	854e                	mv	a0,s3
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	bd4080e7          	jalr	-1068(ra) # 8000395c <iunlockput>
    ip = next;
    80003d90:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d92:	0004c783          	lbu	a5,0(s1)
    80003d96:	05279763          	bne	a5,s2,80003de4 <namex+0x156>
    path++;
    80003d9a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d9c:	0004c783          	lbu	a5,0(s1)
    80003da0:	ff278de3          	beq	a5,s2,80003d9a <namex+0x10c>
  if(*path == 0)
    80003da4:	c79d                	beqz	a5,80003dd2 <namex+0x144>
    path++;
    80003da6:	85a6                	mv	a1,s1
  len = path - s;
    80003da8:	8cda                	mv	s9,s6
    80003daa:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003dac:	01278963          	beq	a5,s2,80003dbe <namex+0x130>
    80003db0:	dfbd                	beqz	a5,80003d2e <namex+0xa0>
    path++;
    80003db2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003db4:	0004c783          	lbu	a5,0(s1)
    80003db8:	ff279ce3          	bne	a5,s2,80003db0 <namex+0x122>
    80003dbc:	bf8d                	j	80003d2e <namex+0xa0>
    memmove(name, s, len);
    80003dbe:	2601                	sext.w	a2,a2
    80003dc0:	8552                	mv	a0,s4
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	f58080e7          	jalr	-168(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003dca:	9cd2                	add	s9,s9,s4
    80003dcc:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003dd0:	bf9d                	j	80003d46 <namex+0xb8>
  if(nameiparent){
    80003dd2:	f20a83e3          	beqz	s5,80003cf8 <namex+0x6a>
    iput(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	adc080e7          	jalr	-1316(ra) # 800038b4 <iput>
    return 0;
    80003de0:	4981                	li	s3,0
    80003de2:	bf19                	j	80003cf8 <namex+0x6a>
  if(*path == 0)
    80003de4:	d7fd                	beqz	a5,80003dd2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	85a6                	mv	a1,s1
    80003dec:	b7d1                	j	80003db0 <namex+0x122>

0000000080003dee <dirlink>:
{
    80003dee:	7139                	addi	sp,sp,-64
    80003df0:	fc06                	sd	ra,56(sp)
    80003df2:	f822                	sd	s0,48(sp)
    80003df4:	f426                	sd	s1,40(sp)
    80003df6:	f04a                	sd	s2,32(sp)
    80003df8:	ec4e                	sd	s3,24(sp)
    80003dfa:	e852                	sd	s4,16(sp)
    80003dfc:	0080                	addi	s0,sp,64
    80003dfe:	892a                	mv	s2,a0
    80003e00:	8a2e                	mv	s4,a1
    80003e02:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e04:	4601                	li	a2,0
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	dd8080e7          	jalr	-552(ra) # 80003bde <dirlookup>
    80003e0e:	e93d                	bnez	a0,80003e84 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e10:	04c92483          	lw	s1,76(s2)
    80003e14:	c49d                	beqz	s1,80003e42 <dirlink+0x54>
    80003e16:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e18:	4741                	li	a4,16
    80003e1a:	86a6                	mv	a3,s1
    80003e1c:	fc040613          	addi	a2,s0,-64
    80003e20:	4581                	li	a1,0
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	b8a080e7          	jalr	-1142(ra) # 800039ae <readi>
    80003e2c:	47c1                	li	a5,16
    80003e2e:	06f51163          	bne	a0,a5,80003e90 <dirlink+0xa2>
    if(de.inum == 0)
    80003e32:	fc045783          	lhu	a5,-64(s0)
    80003e36:	c791                	beqz	a5,80003e42 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e38:	24c1                	addiw	s1,s1,16
    80003e3a:	04c92783          	lw	a5,76(s2)
    80003e3e:	fcf4ede3          	bltu	s1,a5,80003e18 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e42:	4639                	li	a2,14
    80003e44:	85d2                	mv	a1,s4
    80003e46:	fc240513          	addi	a0,s0,-62
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	f88080e7          	jalr	-120(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003e52:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e56:	4741                	li	a4,16
    80003e58:	86a6                	mv	a3,s1
    80003e5a:	fc040613          	addi	a2,s0,-64
    80003e5e:	4581                	li	a1,0
    80003e60:	854a                	mv	a0,s2
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	c44080e7          	jalr	-956(ra) # 80003aa6 <writei>
    80003e6a:	872a                	mv	a4,a0
    80003e6c:	47c1                	li	a5,16
  return 0;
    80003e6e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e70:	02f71863          	bne	a4,a5,80003ea0 <dirlink+0xb2>
}
    80003e74:	70e2                	ld	ra,56(sp)
    80003e76:	7442                	ld	s0,48(sp)
    80003e78:	74a2                	ld	s1,40(sp)
    80003e7a:	7902                	ld	s2,32(sp)
    80003e7c:	69e2                	ld	s3,24(sp)
    80003e7e:	6a42                	ld	s4,16(sp)
    80003e80:	6121                	addi	sp,sp,64
    80003e82:	8082                	ret
    iput(ip);
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	a30080e7          	jalr	-1488(ra) # 800038b4 <iput>
    return -1;
    80003e8c:	557d                	li	a0,-1
    80003e8e:	b7dd                	j	80003e74 <dirlink+0x86>
      panic("dirlink read");
    80003e90:	00005517          	auipc	a0,0x5
    80003e94:	87050513          	addi	a0,a0,-1936 # 80008700 <syscalls+0x1d0>
    80003e98:	ffffc097          	auipc	ra,0xffffc
    80003e9c:	692080e7          	jalr	1682(ra) # 8000052a <panic>
    panic("dirlink");
    80003ea0:	00005517          	auipc	a0,0x5
    80003ea4:	96850513          	addi	a0,a0,-1688 # 80008808 <syscalls+0x2d8>
    80003ea8:	ffffc097          	auipc	ra,0xffffc
    80003eac:	682080e7          	jalr	1666(ra) # 8000052a <panic>

0000000080003eb0 <namei>:

struct inode*
namei(char *path)
{
    80003eb0:	1101                	addi	sp,sp,-32
    80003eb2:	ec06                	sd	ra,24(sp)
    80003eb4:	e822                	sd	s0,16(sp)
    80003eb6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003eb8:	fe040613          	addi	a2,s0,-32
    80003ebc:	4581                	li	a1,0
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	dd0080e7          	jalr	-560(ra) # 80003c8e <namex>
}
    80003ec6:	60e2                	ld	ra,24(sp)
    80003ec8:	6442                	ld	s0,16(sp)
    80003eca:	6105                	addi	sp,sp,32
    80003ecc:	8082                	ret

0000000080003ece <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ece:	1141                	addi	sp,sp,-16
    80003ed0:	e406                	sd	ra,8(sp)
    80003ed2:	e022                	sd	s0,0(sp)
    80003ed4:	0800                	addi	s0,sp,16
    80003ed6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ed8:	4585                	li	a1,1
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	db4080e7          	jalr	-588(ra) # 80003c8e <namex>
}
    80003ee2:	60a2                	ld	ra,8(sp)
    80003ee4:	6402                	ld	s0,0(sp)
    80003ee6:	0141                	addi	sp,sp,16
    80003ee8:	8082                	ret

0000000080003eea <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eea:	1101                	addi	sp,sp,-32
    80003eec:	ec06                	sd	ra,24(sp)
    80003eee:	e822                	sd	s0,16(sp)
    80003ef0:	e426                	sd	s1,8(sp)
    80003ef2:	e04a                	sd	s2,0(sp)
    80003ef4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ef6:	0001d917          	auipc	s2,0x1d
    80003efa:	37a90913          	addi	s2,s2,890 # 80021270 <log>
    80003efe:	01892583          	lw	a1,24(s2)
    80003f02:	02892503          	lw	a0,40(s2)
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	ff0080e7          	jalr	-16(ra) # 80002ef6 <bread>
    80003f0e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f10:	02c92683          	lw	a3,44(s2)
    80003f14:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f16:	02d05863          	blez	a3,80003f46 <write_head+0x5c>
    80003f1a:	0001d797          	auipc	a5,0x1d
    80003f1e:	38678793          	addi	a5,a5,902 # 800212a0 <log+0x30>
    80003f22:	05c50713          	addi	a4,a0,92
    80003f26:	36fd                	addiw	a3,a3,-1
    80003f28:	02069613          	slli	a2,a3,0x20
    80003f2c:	01e65693          	srli	a3,a2,0x1e
    80003f30:	0001d617          	auipc	a2,0x1d
    80003f34:	37460613          	addi	a2,a2,884 # 800212a4 <log+0x34>
    80003f38:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f3a:	4390                	lw	a2,0(a5)
    80003f3c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f3e:	0791                	addi	a5,a5,4
    80003f40:	0711                	addi	a4,a4,4
    80003f42:	fed79ce3          	bne	a5,a3,80003f3a <write_head+0x50>
  }
  bwrite(buf);
    80003f46:	8526                	mv	a0,s1
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	0a0080e7          	jalr	160(ra) # 80002fe8 <bwrite>
  brelse(buf);
    80003f50:	8526                	mv	a0,s1
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	0d4080e7          	jalr	212(ra) # 80003026 <brelse>
}
    80003f5a:	60e2                	ld	ra,24(sp)
    80003f5c:	6442                	ld	s0,16(sp)
    80003f5e:	64a2                	ld	s1,8(sp)
    80003f60:	6902                	ld	s2,0(sp)
    80003f62:	6105                	addi	sp,sp,32
    80003f64:	8082                	ret

0000000080003f66 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f66:	0001d797          	auipc	a5,0x1d
    80003f6a:	3367a783          	lw	a5,822(a5) # 8002129c <log+0x2c>
    80003f6e:	0af05d63          	blez	a5,80004028 <install_trans+0xc2>
{
    80003f72:	7139                	addi	sp,sp,-64
    80003f74:	fc06                	sd	ra,56(sp)
    80003f76:	f822                	sd	s0,48(sp)
    80003f78:	f426                	sd	s1,40(sp)
    80003f7a:	f04a                	sd	s2,32(sp)
    80003f7c:	ec4e                	sd	s3,24(sp)
    80003f7e:	e852                	sd	s4,16(sp)
    80003f80:	e456                	sd	s5,8(sp)
    80003f82:	e05a                	sd	s6,0(sp)
    80003f84:	0080                	addi	s0,sp,64
    80003f86:	8b2a                	mv	s6,a0
    80003f88:	0001da97          	auipc	s5,0x1d
    80003f8c:	318a8a93          	addi	s5,s5,792 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f90:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f92:	0001d997          	auipc	s3,0x1d
    80003f96:	2de98993          	addi	s3,s3,734 # 80021270 <log>
    80003f9a:	a00d                	j	80003fbc <install_trans+0x56>
    brelse(lbuf);
    80003f9c:	854a                	mv	a0,s2
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	088080e7          	jalr	136(ra) # 80003026 <brelse>
    brelse(dbuf);
    80003fa6:	8526                	mv	a0,s1
    80003fa8:	fffff097          	auipc	ra,0xfffff
    80003fac:	07e080e7          	jalr	126(ra) # 80003026 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb0:	2a05                	addiw	s4,s4,1
    80003fb2:	0a91                	addi	s5,s5,4
    80003fb4:	02c9a783          	lw	a5,44(s3)
    80003fb8:	04fa5e63          	bge	s4,a5,80004014 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fbc:	0189a583          	lw	a1,24(s3)
    80003fc0:	014585bb          	addw	a1,a1,s4
    80003fc4:	2585                	addiw	a1,a1,1
    80003fc6:	0289a503          	lw	a0,40(s3)
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	f2c080e7          	jalr	-212(ra) # 80002ef6 <bread>
    80003fd2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fd4:	000aa583          	lw	a1,0(s5)
    80003fd8:	0289a503          	lw	a0,40(s3)
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	f1a080e7          	jalr	-230(ra) # 80002ef6 <bread>
    80003fe4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fe6:	40000613          	li	a2,1024
    80003fea:	05890593          	addi	a1,s2,88
    80003fee:	05850513          	addi	a0,a0,88
    80003ff2:	ffffd097          	auipc	ra,0xffffd
    80003ff6:	d28080e7          	jalr	-728(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	fec080e7          	jalr	-20(ra) # 80002fe8 <bwrite>
    if(recovering == 0)
    80004004:	f80b1ce3          	bnez	s6,80003f9c <install_trans+0x36>
      bunpin(dbuf);
    80004008:	8526                	mv	a0,s1
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	0f6080e7          	jalr	246(ra) # 80003100 <bunpin>
    80004012:	b769                	j	80003f9c <install_trans+0x36>
}
    80004014:	70e2                	ld	ra,56(sp)
    80004016:	7442                	ld	s0,48(sp)
    80004018:	74a2                	ld	s1,40(sp)
    8000401a:	7902                	ld	s2,32(sp)
    8000401c:	69e2                	ld	s3,24(sp)
    8000401e:	6a42                	ld	s4,16(sp)
    80004020:	6aa2                	ld	s5,8(sp)
    80004022:	6b02                	ld	s6,0(sp)
    80004024:	6121                	addi	sp,sp,64
    80004026:	8082                	ret
    80004028:	8082                	ret

000000008000402a <initlog>:
{
    8000402a:	7179                	addi	sp,sp,-48
    8000402c:	f406                	sd	ra,40(sp)
    8000402e:	f022                	sd	s0,32(sp)
    80004030:	ec26                	sd	s1,24(sp)
    80004032:	e84a                	sd	s2,16(sp)
    80004034:	e44e                	sd	s3,8(sp)
    80004036:	1800                	addi	s0,sp,48
    80004038:	892a                	mv	s2,a0
    8000403a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000403c:	0001d497          	auipc	s1,0x1d
    80004040:	23448493          	addi	s1,s1,564 # 80021270 <log>
    80004044:	00004597          	auipc	a1,0x4
    80004048:	6cc58593          	addi	a1,a1,1740 # 80008710 <syscalls+0x1e0>
    8000404c:	8526                	mv	a0,s1
    8000404e:	ffffd097          	auipc	ra,0xffffd
    80004052:	ae4080e7          	jalr	-1308(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004056:	0149a583          	lw	a1,20(s3)
    8000405a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000405c:	0109a783          	lw	a5,16(s3)
    80004060:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004062:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004066:	854a                	mv	a0,s2
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	e8e080e7          	jalr	-370(ra) # 80002ef6 <bread>
  log.lh.n = lh->n;
    80004070:	4d34                	lw	a3,88(a0)
    80004072:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004074:	02d05663          	blez	a3,800040a0 <initlog+0x76>
    80004078:	05c50793          	addi	a5,a0,92
    8000407c:	0001d717          	auipc	a4,0x1d
    80004080:	22470713          	addi	a4,a4,548 # 800212a0 <log+0x30>
    80004084:	36fd                	addiw	a3,a3,-1
    80004086:	02069613          	slli	a2,a3,0x20
    8000408a:	01e65693          	srli	a3,a2,0x1e
    8000408e:	06050613          	addi	a2,a0,96
    80004092:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004094:	4390                	lw	a2,0(a5)
    80004096:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004098:	0791                	addi	a5,a5,4
    8000409a:	0711                	addi	a4,a4,4
    8000409c:	fed79ce3          	bne	a5,a3,80004094 <initlog+0x6a>
  brelse(buf);
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	f86080e7          	jalr	-122(ra) # 80003026 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040a8:	4505                	li	a0,1
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	ebc080e7          	jalr	-324(ra) # 80003f66 <install_trans>
  log.lh.n = 0;
    800040b2:	0001d797          	auipc	a5,0x1d
    800040b6:	1e07a523          	sw	zero,490(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	e30080e7          	jalr	-464(ra) # 80003eea <write_head>
}
    800040c2:	70a2                	ld	ra,40(sp)
    800040c4:	7402                	ld	s0,32(sp)
    800040c6:	64e2                	ld	s1,24(sp)
    800040c8:	6942                	ld	s2,16(sp)
    800040ca:	69a2                	ld	s3,8(sp)
    800040cc:	6145                	addi	sp,sp,48
    800040ce:	8082                	ret

00000000800040d0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040d0:	1101                	addi	sp,sp,-32
    800040d2:	ec06                	sd	ra,24(sp)
    800040d4:	e822                	sd	s0,16(sp)
    800040d6:	e426                	sd	s1,8(sp)
    800040d8:	e04a                	sd	s2,0(sp)
    800040da:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040dc:	0001d517          	auipc	a0,0x1d
    800040e0:	19450513          	addi	a0,a0,404 # 80021270 <log>
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	ade080e7          	jalr	-1314(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800040ec:	0001d497          	auipc	s1,0x1d
    800040f0:	18448493          	addi	s1,s1,388 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f4:	4979                	li	s2,30
    800040f6:	a039                	j	80004104 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040f8:	85a6                	mv	a1,s1
    800040fa:	8526                	mv	a0,s1
    800040fc:	ffffe097          	auipc	ra,0xffffe
    80004100:	f4e080e7          	jalr	-178(ra) # 8000204a <sleep>
    if(log.committing){
    80004104:	50dc                	lw	a5,36(s1)
    80004106:	fbed                	bnez	a5,800040f8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004108:	509c                	lw	a5,32(s1)
    8000410a:	0017871b          	addiw	a4,a5,1
    8000410e:	0007069b          	sext.w	a3,a4
    80004112:	0027179b          	slliw	a5,a4,0x2
    80004116:	9fb9                	addw	a5,a5,a4
    80004118:	0017979b          	slliw	a5,a5,0x1
    8000411c:	54d8                	lw	a4,44(s1)
    8000411e:	9fb9                	addw	a5,a5,a4
    80004120:	00f95963          	bge	s2,a5,80004132 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004124:	85a6                	mv	a1,s1
    80004126:	8526                	mv	a0,s1
    80004128:	ffffe097          	auipc	ra,0xffffe
    8000412c:	f22080e7          	jalr	-222(ra) # 8000204a <sleep>
    80004130:	bfd1                	j	80004104 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004132:	0001d517          	auipc	a0,0x1d
    80004136:	13e50513          	addi	a0,a0,318 # 80021270 <log>
    8000413a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000413c:	ffffd097          	auipc	ra,0xffffd
    80004140:	b3a080e7          	jalr	-1222(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004144:	60e2                	ld	ra,24(sp)
    80004146:	6442                	ld	s0,16(sp)
    80004148:	64a2                	ld	s1,8(sp)
    8000414a:	6902                	ld	s2,0(sp)
    8000414c:	6105                	addi	sp,sp,32
    8000414e:	8082                	ret

0000000080004150 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004150:	7139                	addi	sp,sp,-64
    80004152:	fc06                	sd	ra,56(sp)
    80004154:	f822                	sd	s0,48(sp)
    80004156:	f426                	sd	s1,40(sp)
    80004158:	f04a                	sd	s2,32(sp)
    8000415a:	ec4e                	sd	s3,24(sp)
    8000415c:	e852                	sd	s4,16(sp)
    8000415e:	e456                	sd	s5,8(sp)
    80004160:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004162:	0001d497          	auipc	s1,0x1d
    80004166:	10e48493          	addi	s1,s1,270 # 80021270 <log>
    8000416a:	8526                	mv	a0,s1
    8000416c:	ffffd097          	auipc	ra,0xffffd
    80004170:	a56080e7          	jalr	-1450(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004174:	509c                	lw	a5,32(s1)
    80004176:	37fd                	addiw	a5,a5,-1
    80004178:	0007891b          	sext.w	s2,a5
    8000417c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000417e:	50dc                	lw	a5,36(s1)
    80004180:	e7b9                	bnez	a5,800041ce <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004182:	04091e63          	bnez	s2,800041de <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004186:	0001d497          	auipc	s1,0x1d
    8000418a:	0ea48493          	addi	s1,s1,234 # 80021270 <log>
    8000418e:	4785                	li	a5,1
    80004190:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004192:	8526                	mv	a0,s1
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	ae2080e7          	jalr	-1310(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000419c:	54dc                	lw	a5,44(s1)
    8000419e:	06f04763          	bgtz	a5,8000420c <end_op+0xbc>
    acquire(&log.lock);
    800041a2:	0001d497          	auipc	s1,0x1d
    800041a6:	0ce48493          	addi	s1,s1,206 # 80021270 <log>
    800041aa:	8526                	mv	a0,s1
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	a16080e7          	jalr	-1514(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800041b4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041b8:	8526                	mv	a0,s1
    800041ba:	ffffe097          	auipc	ra,0xffffe
    800041be:	01c080e7          	jalr	28(ra) # 800021d6 <wakeup>
    release(&log.lock);
    800041c2:	8526                	mv	a0,s1
    800041c4:	ffffd097          	auipc	ra,0xffffd
    800041c8:	ab2080e7          	jalr	-1358(ra) # 80000c76 <release>
}
    800041cc:	a03d                	j	800041fa <end_op+0xaa>
    panic("log.committing");
    800041ce:	00004517          	auipc	a0,0x4
    800041d2:	54a50513          	addi	a0,a0,1354 # 80008718 <syscalls+0x1e8>
    800041d6:	ffffc097          	auipc	ra,0xffffc
    800041da:	354080e7          	jalr	852(ra) # 8000052a <panic>
    wakeup(&log);
    800041de:	0001d497          	auipc	s1,0x1d
    800041e2:	09248493          	addi	s1,s1,146 # 80021270 <log>
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	fee080e7          	jalr	-18(ra) # 800021d6 <wakeup>
  release(&log.lock);
    800041f0:	8526                	mv	a0,s1
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	a84080e7          	jalr	-1404(ra) # 80000c76 <release>
}
    800041fa:	70e2                	ld	ra,56(sp)
    800041fc:	7442                	ld	s0,48(sp)
    800041fe:	74a2                	ld	s1,40(sp)
    80004200:	7902                	ld	s2,32(sp)
    80004202:	69e2                	ld	s3,24(sp)
    80004204:	6a42                	ld	s4,16(sp)
    80004206:	6aa2                	ld	s5,8(sp)
    80004208:	6121                	addi	sp,sp,64
    8000420a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000420c:	0001da97          	auipc	s5,0x1d
    80004210:	094a8a93          	addi	s5,s5,148 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004214:	0001da17          	auipc	s4,0x1d
    80004218:	05ca0a13          	addi	s4,s4,92 # 80021270 <log>
    8000421c:	018a2583          	lw	a1,24(s4)
    80004220:	012585bb          	addw	a1,a1,s2
    80004224:	2585                	addiw	a1,a1,1
    80004226:	028a2503          	lw	a0,40(s4)
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	ccc080e7          	jalr	-820(ra) # 80002ef6 <bread>
    80004232:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004234:	000aa583          	lw	a1,0(s5)
    80004238:	028a2503          	lw	a0,40(s4)
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	cba080e7          	jalr	-838(ra) # 80002ef6 <bread>
    80004244:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004246:	40000613          	li	a2,1024
    8000424a:	05850593          	addi	a1,a0,88
    8000424e:	05848513          	addi	a0,s1,88
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	ac8080e7          	jalr	-1336(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	d8c080e7          	jalr	-628(ra) # 80002fe8 <bwrite>
    brelse(from);
    80004264:	854e                	mv	a0,s3
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	dc0080e7          	jalr	-576(ra) # 80003026 <brelse>
    brelse(to);
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	db6080e7          	jalr	-586(ra) # 80003026 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004278:	2905                	addiw	s2,s2,1
    8000427a:	0a91                	addi	s5,s5,4
    8000427c:	02ca2783          	lw	a5,44(s4)
    80004280:	f8f94ee3          	blt	s2,a5,8000421c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004284:	00000097          	auipc	ra,0x0
    80004288:	c66080e7          	jalr	-922(ra) # 80003eea <write_head>
    install_trans(0); // Now install writes to home locations
    8000428c:	4501                	li	a0,0
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	cd8080e7          	jalr	-808(ra) # 80003f66 <install_trans>
    log.lh.n = 0;
    80004296:	0001d797          	auipc	a5,0x1d
    8000429a:	0007a323          	sw	zero,6(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	c4c080e7          	jalr	-948(ra) # 80003eea <write_head>
    800042a6:	bdf5                	j	800041a2 <end_op+0x52>

00000000800042a8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042a8:	1101                	addi	sp,sp,-32
    800042aa:	ec06                	sd	ra,24(sp)
    800042ac:	e822                	sd	s0,16(sp)
    800042ae:	e426                	sd	s1,8(sp)
    800042b0:	e04a                	sd	s2,0(sp)
    800042b2:	1000                	addi	s0,sp,32
    800042b4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042b6:	0001d917          	auipc	s2,0x1d
    800042ba:	fba90913          	addi	s2,s2,-70 # 80021270 <log>
    800042be:	854a                	mv	a0,s2
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042c8:	02c92603          	lw	a2,44(s2)
    800042cc:	47f5                	li	a5,29
    800042ce:	06c7c563          	blt	a5,a2,80004338 <log_write+0x90>
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	fba7a783          	lw	a5,-70(a5) # 8002128c <log+0x1c>
    800042da:	37fd                	addiw	a5,a5,-1
    800042dc:	04f65e63          	bge	a2,a5,80004338 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042e0:	0001d797          	auipc	a5,0x1d
    800042e4:	fb07a783          	lw	a5,-80(a5) # 80021290 <log+0x20>
    800042e8:	06f05063          	blez	a5,80004348 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042ec:	4781                	li	a5,0
    800042ee:	06c05563          	blez	a2,80004358 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042f2:	44cc                	lw	a1,12(s1)
    800042f4:	0001d717          	auipc	a4,0x1d
    800042f8:	fac70713          	addi	a4,a4,-84 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042fc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042fe:	4314                	lw	a3,0(a4)
    80004300:	04b68c63          	beq	a3,a1,80004358 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004304:	2785                	addiw	a5,a5,1
    80004306:	0711                	addi	a4,a4,4
    80004308:	fef61be3          	bne	a2,a5,800042fe <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000430c:	0621                	addi	a2,a2,8
    8000430e:	060a                	slli	a2,a2,0x2
    80004310:	0001d797          	auipc	a5,0x1d
    80004314:	f6078793          	addi	a5,a5,-160 # 80021270 <log>
    80004318:	963e                	add	a2,a2,a5
    8000431a:	44dc                	lw	a5,12(s1)
    8000431c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000431e:	8526                	mv	a0,s1
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	da4080e7          	jalr	-604(ra) # 800030c4 <bpin>
    log.lh.n++;
    80004328:	0001d717          	auipc	a4,0x1d
    8000432c:	f4870713          	addi	a4,a4,-184 # 80021270 <log>
    80004330:	575c                	lw	a5,44(a4)
    80004332:	2785                	addiw	a5,a5,1
    80004334:	d75c                	sw	a5,44(a4)
    80004336:	a835                	j	80004372 <log_write+0xca>
    panic("too big a transaction");
    80004338:	00004517          	auipc	a0,0x4
    8000433c:	3f050513          	addi	a0,a0,1008 # 80008728 <syscalls+0x1f8>
    80004340:	ffffc097          	auipc	ra,0xffffc
    80004344:	1ea080e7          	jalr	490(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004348:	00004517          	auipc	a0,0x4
    8000434c:	3f850513          	addi	a0,a0,1016 # 80008740 <syscalls+0x210>
    80004350:	ffffc097          	auipc	ra,0xffffc
    80004354:	1da080e7          	jalr	474(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004358:	00878713          	addi	a4,a5,8
    8000435c:	00271693          	slli	a3,a4,0x2
    80004360:	0001d717          	auipc	a4,0x1d
    80004364:	f1070713          	addi	a4,a4,-240 # 80021270 <log>
    80004368:	9736                	add	a4,a4,a3
    8000436a:	44d4                	lw	a3,12(s1)
    8000436c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000436e:	faf608e3          	beq	a2,a5,8000431e <log_write+0x76>
  }
  release(&log.lock);
    80004372:	0001d517          	auipc	a0,0x1d
    80004376:	efe50513          	addi	a0,a0,-258 # 80021270 <log>
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	8fc080e7          	jalr	-1796(ra) # 80000c76 <release>
}
    80004382:	60e2                	ld	ra,24(sp)
    80004384:	6442                	ld	s0,16(sp)
    80004386:	64a2                	ld	s1,8(sp)
    80004388:	6902                	ld	s2,0(sp)
    8000438a:	6105                	addi	sp,sp,32
    8000438c:	8082                	ret

000000008000438e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000438e:	1101                	addi	sp,sp,-32
    80004390:	ec06                	sd	ra,24(sp)
    80004392:	e822                	sd	s0,16(sp)
    80004394:	e426                	sd	s1,8(sp)
    80004396:	e04a                	sd	s2,0(sp)
    80004398:	1000                	addi	s0,sp,32
    8000439a:	84aa                	mv	s1,a0
    8000439c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000439e:	00004597          	auipc	a1,0x4
    800043a2:	3c258593          	addi	a1,a1,962 # 80008760 <syscalls+0x230>
    800043a6:	0521                	addi	a0,a0,8
    800043a8:	ffffc097          	auipc	ra,0xffffc
    800043ac:	78a080e7          	jalr	1930(ra) # 80000b32 <initlock>
  lk->name = name;
    800043b0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043b4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043b8:	0204a423          	sw	zero,40(s1)
}
    800043bc:	60e2                	ld	ra,24(sp)
    800043be:	6442                	ld	s0,16(sp)
    800043c0:	64a2                	ld	s1,8(sp)
    800043c2:	6902                	ld	s2,0(sp)
    800043c4:	6105                	addi	sp,sp,32
    800043c6:	8082                	ret

00000000800043c8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043c8:	1101                	addi	sp,sp,-32
    800043ca:	ec06                	sd	ra,24(sp)
    800043cc:	e822                	sd	s0,16(sp)
    800043ce:	e426                	sd	s1,8(sp)
    800043d0:	e04a                	sd	s2,0(sp)
    800043d2:	1000                	addi	s0,sp,32
    800043d4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d6:	00850913          	addi	s2,a0,8
    800043da:	854a                	mv	a0,s2
    800043dc:	ffffc097          	auipc	ra,0xffffc
    800043e0:	7e6080e7          	jalr	2022(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800043e4:	409c                	lw	a5,0(s1)
    800043e6:	cb89                	beqz	a5,800043f8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043e8:	85ca                	mv	a1,s2
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffe097          	auipc	ra,0xffffe
    800043f0:	c5e080e7          	jalr	-930(ra) # 8000204a <sleep>
  while (lk->locked) {
    800043f4:	409c                	lw	a5,0(s1)
    800043f6:	fbed                	bnez	a5,800043e8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043f8:	4785                	li	a5,1
    800043fa:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	582080e7          	jalr	1410(ra) # 8000197e <myproc>
    80004404:	591c                	lw	a5,48(a0)
    80004406:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004408:	854a                	mv	a0,s2
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	86c080e7          	jalr	-1940(ra) # 80000c76 <release>
}
    80004412:	60e2                	ld	ra,24(sp)
    80004414:	6442                	ld	s0,16(sp)
    80004416:	64a2                	ld	s1,8(sp)
    80004418:	6902                	ld	s2,0(sp)
    8000441a:	6105                	addi	sp,sp,32
    8000441c:	8082                	ret

000000008000441e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000441e:	1101                	addi	sp,sp,-32
    80004420:	ec06                	sd	ra,24(sp)
    80004422:	e822                	sd	s0,16(sp)
    80004424:	e426                	sd	s1,8(sp)
    80004426:	e04a                	sd	s2,0(sp)
    80004428:	1000                	addi	s0,sp,32
    8000442a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000442c:	00850913          	addi	s2,a0,8
    80004430:	854a                	mv	a0,s2
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	790080e7          	jalr	1936(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000443a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000443e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004442:	8526                	mv	a0,s1
    80004444:	ffffe097          	auipc	ra,0xffffe
    80004448:	d92080e7          	jalr	-622(ra) # 800021d6 <wakeup>
  release(&lk->lk);
    8000444c:	854a                	mv	a0,s2
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	828080e7          	jalr	-2008(ra) # 80000c76 <release>
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6902                	ld	s2,0(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret

0000000080004462 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004462:	7179                	addi	sp,sp,-48
    80004464:	f406                	sd	ra,40(sp)
    80004466:	f022                	sd	s0,32(sp)
    80004468:	ec26                	sd	s1,24(sp)
    8000446a:	e84a                	sd	s2,16(sp)
    8000446c:	e44e                	sd	s3,8(sp)
    8000446e:	1800                	addi	s0,sp,48
    80004470:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004472:	00850913          	addi	s2,a0,8
    80004476:	854a                	mv	a0,s2
    80004478:	ffffc097          	auipc	ra,0xffffc
    8000447c:	74a080e7          	jalr	1866(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004480:	409c                	lw	a5,0(s1)
    80004482:	ef99                	bnez	a5,800044a0 <holdingsleep+0x3e>
    80004484:	4481                	li	s1,0
  release(&lk->lk);
    80004486:	854a                	mv	a0,s2
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	7ee080e7          	jalr	2030(ra) # 80000c76 <release>
  return r;
}
    80004490:	8526                	mv	a0,s1
    80004492:	70a2                	ld	ra,40(sp)
    80004494:	7402                	ld	s0,32(sp)
    80004496:	64e2                	ld	s1,24(sp)
    80004498:	6942                	ld	s2,16(sp)
    8000449a:	69a2                	ld	s3,8(sp)
    8000449c:	6145                	addi	sp,sp,48
    8000449e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a0:	0284a983          	lw	s3,40(s1)
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	4da080e7          	jalr	1242(ra) # 8000197e <myproc>
    800044ac:	5904                	lw	s1,48(a0)
    800044ae:	413484b3          	sub	s1,s1,s3
    800044b2:	0014b493          	seqz	s1,s1
    800044b6:	bfc1                	j	80004486 <holdingsleep+0x24>

00000000800044b8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044b8:	1141                	addi	sp,sp,-16
    800044ba:	e406                	sd	ra,8(sp)
    800044bc:	e022                	sd	s0,0(sp)
    800044be:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044c0:	00004597          	auipc	a1,0x4
    800044c4:	2b058593          	addi	a1,a1,688 # 80008770 <syscalls+0x240>
    800044c8:	0001d517          	auipc	a0,0x1d
    800044cc:	ef050513          	addi	a0,a0,-272 # 800213b8 <ftable>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	662080e7          	jalr	1634(ra) # 80000b32 <initlock>
}
    800044d8:	60a2                	ld	ra,8(sp)
    800044da:	6402                	ld	s0,0(sp)
    800044dc:	0141                	addi	sp,sp,16
    800044de:	8082                	ret

00000000800044e0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044e0:	1101                	addi	sp,sp,-32
    800044e2:	ec06                	sd	ra,24(sp)
    800044e4:	e822                	sd	s0,16(sp)
    800044e6:	e426                	sd	s1,8(sp)
    800044e8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ea:	0001d517          	auipc	a0,0x1d
    800044ee:	ece50513          	addi	a0,a0,-306 # 800213b8 <ftable>
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	6d0080e7          	jalr	1744(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044fa:	0001d497          	auipc	s1,0x1d
    800044fe:	ed648493          	addi	s1,s1,-298 # 800213d0 <ftable+0x18>
    80004502:	0001e717          	auipc	a4,0x1e
    80004506:	e6e70713          	addi	a4,a4,-402 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000450a:	40dc                	lw	a5,4(s1)
    8000450c:	cf99                	beqz	a5,8000452a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000450e:	02848493          	addi	s1,s1,40
    80004512:	fee49ce3          	bne	s1,a4,8000450a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004516:	0001d517          	auipc	a0,0x1d
    8000451a:	ea250513          	addi	a0,a0,-350 # 800213b8 <ftable>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	758080e7          	jalr	1880(ra) # 80000c76 <release>
  return 0;
    80004526:	4481                	li	s1,0
    80004528:	a819                	j	8000453e <filealloc+0x5e>
      f->ref = 1;
    8000452a:	4785                	li	a5,1
    8000452c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000452e:	0001d517          	auipc	a0,0x1d
    80004532:	e8a50513          	addi	a0,a0,-374 # 800213b8 <ftable>
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	740080e7          	jalr	1856(ra) # 80000c76 <release>
}
    8000453e:	8526                	mv	a0,s1
    80004540:	60e2                	ld	ra,24(sp)
    80004542:	6442                	ld	s0,16(sp)
    80004544:	64a2                	ld	s1,8(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000454a:	1101                	addi	sp,sp,-32
    8000454c:	ec06                	sd	ra,24(sp)
    8000454e:	e822                	sd	s0,16(sp)
    80004550:	e426                	sd	s1,8(sp)
    80004552:	1000                	addi	s0,sp,32
    80004554:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004556:	0001d517          	auipc	a0,0x1d
    8000455a:	e6250513          	addi	a0,a0,-414 # 800213b8 <ftable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	664080e7          	jalr	1636(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004566:	40dc                	lw	a5,4(s1)
    80004568:	02f05263          	blez	a5,8000458c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000456c:	2785                	addiw	a5,a5,1
    8000456e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	e4850513          	addi	a0,a0,-440 # 800213b8 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	6fe080e7          	jalr	1790(ra) # 80000c76 <release>
  return f;
}
    80004580:	8526                	mv	a0,s1
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6105                	addi	sp,sp,32
    8000458a:	8082                	ret
    panic("filedup");
    8000458c:	00004517          	auipc	a0,0x4
    80004590:	1ec50513          	addi	a0,a0,492 # 80008778 <syscalls+0x248>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	f96080e7          	jalr	-106(ra) # 8000052a <panic>

000000008000459c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000459c:	7139                	addi	sp,sp,-64
    8000459e:	fc06                	sd	ra,56(sp)
    800045a0:	f822                	sd	s0,48(sp)
    800045a2:	f426                	sd	s1,40(sp)
    800045a4:	f04a                	sd	s2,32(sp)
    800045a6:	ec4e                	sd	s3,24(sp)
    800045a8:	e852                	sd	s4,16(sp)
    800045aa:	e456                	sd	s5,8(sp)
    800045ac:	0080                	addi	s0,sp,64
    800045ae:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045b0:	0001d517          	auipc	a0,0x1d
    800045b4:	e0850513          	addi	a0,a0,-504 # 800213b8 <ftable>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	60a080e7          	jalr	1546(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800045c0:	40dc                	lw	a5,4(s1)
    800045c2:	06f05163          	blez	a5,80004624 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045c6:	37fd                	addiw	a5,a5,-1
    800045c8:	0007871b          	sext.w	a4,a5
    800045cc:	c0dc                	sw	a5,4(s1)
    800045ce:	06e04363          	bgtz	a4,80004634 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045d2:	0004a903          	lw	s2,0(s1)
    800045d6:	0094ca83          	lbu	s5,9(s1)
    800045da:	0104ba03          	ld	s4,16(s1)
    800045de:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045e2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045e6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ea:	0001d517          	auipc	a0,0x1d
    800045ee:	dce50513          	addi	a0,a0,-562 # 800213b8 <ftable>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	684080e7          	jalr	1668(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800045fa:	4785                	li	a5,1
    800045fc:	04f90d63          	beq	s2,a5,80004656 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004600:	3979                	addiw	s2,s2,-2
    80004602:	4785                	li	a5,1
    80004604:	0527e063          	bltu	a5,s2,80004644 <fileclose+0xa8>
    begin_op();
    80004608:	00000097          	auipc	ra,0x0
    8000460c:	ac8080e7          	jalr	-1336(ra) # 800040d0 <begin_op>
    iput(ff.ip);
    80004610:	854e                	mv	a0,s3
    80004612:	fffff097          	auipc	ra,0xfffff
    80004616:	2a2080e7          	jalr	674(ra) # 800038b4 <iput>
    end_op();
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	b36080e7          	jalr	-1226(ra) # 80004150 <end_op>
    80004622:	a00d                	j	80004644 <fileclose+0xa8>
    panic("fileclose");
    80004624:	00004517          	auipc	a0,0x4
    80004628:	15c50513          	addi	a0,a0,348 # 80008780 <syscalls+0x250>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	efe080e7          	jalr	-258(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004634:	0001d517          	auipc	a0,0x1d
    80004638:	d8450513          	addi	a0,a0,-636 # 800213b8 <ftable>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	63a080e7          	jalr	1594(ra) # 80000c76 <release>
  }
}
    80004644:	70e2                	ld	ra,56(sp)
    80004646:	7442                	ld	s0,48(sp)
    80004648:	74a2                	ld	s1,40(sp)
    8000464a:	7902                	ld	s2,32(sp)
    8000464c:	69e2                	ld	s3,24(sp)
    8000464e:	6a42                	ld	s4,16(sp)
    80004650:	6aa2                	ld	s5,8(sp)
    80004652:	6121                	addi	sp,sp,64
    80004654:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004656:	85d6                	mv	a1,s5
    80004658:	8552                	mv	a0,s4
    8000465a:	00000097          	auipc	ra,0x0
    8000465e:	34c080e7          	jalr	844(ra) # 800049a6 <pipeclose>
    80004662:	b7cd                	j	80004644 <fileclose+0xa8>

0000000080004664 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004664:	715d                	addi	sp,sp,-80
    80004666:	e486                	sd	ra,72(sp)
    80004668:	e0a2                	sd	s0,64(sp)
    8000466a:	fc26                	sd	s1,56(sp)
    8000466c:	f84a                	sd	s2,48(sp)
    8000466e:	f44e                	sd	s3,40(sp)
    80004670:	0880                	addi	s0,sp,80
    80004672:	84aa                	mv	s1,a0
    80004674:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004676:	ffffd097          	auipc	ra,0xffffd
    8000467a:	308080e7          	jalr	776(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000467e:	409c                	lw	a5,0(s1)
    80004680:	37f9                	addiw	a5,a5,-2
    80004682:	4705                	li	a4,1
    80004684:	04f76763          	bltu	a4,a5,800046d2 <filestat+0x6e>
    80004688:	892a                	mv	s2,a0
    ilock(f->ip);
    8000468a:	6c88                	ld	a0,24(s1)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	06e080e7          	jalr	110(ra) # 800036fa <ilock>
    stati(f->ip, &st);
    80004694:	fb840593          	addi	a1,s0,-72
    80004698:	6c88                	ld	a0,24(s1)
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	2ea080e7          	jalr	746(ra) # 80003984 <stati>
    iunlock(f->ip);
    800046a2:	6c88                	ld	a0,24(s1)
    800046a4:	fffff097          	auipc	ra,0xfffff
    800046a8:	118080e7          	jalr	280(ra) # 800037bc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046ac:	46e1                	li	a3,24
    800046ae:	fb840613          	addi	a2,s0,-72
    800046b2:	85ce                	mv	a1,s3
    800046b4:	05093503          	ld	a0,80(s2)
    800046b8:	ffffd097          	auipc	ra,0xffffd
    800046bc:	f86080e7          	jalr	-122(ra) # 8000163e <copyout>
    800046c0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046c4:	60a6                	ld	ra,72(sp)
    800046c6:	6406                	ld	s0,64(sp)
    800046c8:	74e2                	ld	s1,56(sp)
    800046ca:	7942                	ld	s2,48(sp)
    800046cc:	79a2                	ld	s3,40(sp)
    800046ce:	6161                	addi	sp,sp,80
    800046d0:	8082                	ret
  return -1;
    800046d2:	557d                	li	a0,-1
    800046d4:	bfc5                	j	800046c4 <filestat+0x60>

00000000800046d6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046d6:	7179                	addi	sp,sp,-48
    800046d8:	f406                	sd	ra,40(sp)
    800046da:	f022                	sd	s0,32(sp)
    800046dc:	ec26                	sd	s1,24(sp)
    800046de:	e84a                	sd	s2,16(sp)
    800046e0:	e44e                	sd	s3,8(sp)
    800046e2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046e4:	00854783          	lbu	a5,8(a0)
    800046e8:	c3d5                	beqz	a5,8000478c <fileread+0xb6>
    800046ea:	84aa                	mv	s1,a0
    800046ec:	89ae                	mv	s3,a1
    800046ee:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046f0:	411c                	lw	a5,0(a0)
    800046f2:	4705                	li	a4,1
    800046f4:	04e78963          	beq	a5,a4,80004746 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046f8:	470d                	li	a4,3
    800046fa:	04e78d63          	beq	a5,a4,80004754 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046fe:	4709                	li	a4,2
    80004700:	06e79e63          	bne	a5,a4,8000477c <fileread+0xa6>
    ilock(f->ip);
    80004704:	6d08                	ld	a0,24(a0)
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	ff4080e7          	jalr	-12(ra) # 800036fa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000470e:	874a                	mv	a4,s2
    80004710:	5094                	lw	a3,32(s1)
    80004712:	864e                	mv	a2,s3
    80004714:	4585                	li	a1,1
    80004716:	6c88                	ld	a0,24(s1)
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	296080e7          	jalr	662(ra) # 800039ae <readi>
    80004720:	892a                	mv	s2,a0
    80004722:	00a05563          	blez	a0,8000472c <fileread+0x56>
      f->off += r;
    80004726:	509c                	lw	a5,32(s1)
    80004728:	9fa9                	addw	a5,a5,a0
    8000472a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000472c:	6c88                	ld	a0,24(s1)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	08e080e7          	jalr	142(ra) # 800037bc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004736:	854a                	mv	a0,s2
    80004738:	70a2                	ld	ra,40(sp)
    8000473a:	7402                	ld	s0,32(sp)
    8000473c:	64e2                	ld	s1,24(sp)
    8000473e:	6942                	ld	s2,16(sp)
    80004740:	69a2                	ld	s3,8(sp)
    80004742:	6145                	addi	sp,sp,48
    80004744:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004746:	6908                	ld	a0,16(a0)
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	3c0080e7          	jalr	960(ra) # 80004b08 <piperead>
    80004750:	892a                	mv	s2,a0
    80004752:	b7d5                	j	80004736 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004754:	02451783          	lh	a5,36(a0)
    80004758:	03079693          	slli	a3,a5,0x30
    8000475c:	92c1                	srli	a3,a3,0x30
    8000475e:	4725                	li	a4,9
    80004760:	02d76863          	bltu	a4,a3,80004790 <fileread+0xba>
    80004764:	0792                	slli	a5,a5,0x4
    80004766:	0001d717          	auipc	a4,0x1d
    8000476a:	bb270713          	addi	a4,a4,-1102 # 80021318 <devsw>
    8000476e:	97ba                	add	a5,a5,a4
    80004770:	639c                	ld	a5,0(a5)
    80004772:	c38d                	beqz	a5,80004794 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004774:	4505                	li	a0,1
    80004776:	9782                	jalr	a5
    80004778:	892a                	mv	s2,a0
    8000477a:	bf75                	j	80004736 <fileread+0x60>
    panic("fileread");
    8000477c:	00004517          	auipc	a0,0x4
    80004780:	01450513          	addi	a0,a0,20 # 80008790 <syscalls+0x260>
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	da6080e7          	jalr	-602(ra) # 8000052a <panic>
    return -1;
    8000478c:	597d                	li	s2,-1
    8000478e:	b765                	j	80004736 <fileread+0x60>
      return -1;
    80004790:	597d                	li	s2,-1
    80004792:	b755                	j	80004736 <fileread+0x60>
    80004794:	597d                	li	s2,-1
    80004796:	b745                	j	80004736 <fileread+0x60>

0000000080004798 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004798:	715d                	addi	sp,sp,-80
    8000479a:	e486                	sd	ra,72(sp)
    8000479c:	e0a2                	sd	s0,64(sp)
    8000479e:	fc26                	sd	s1,56(sp)
    800047a0:	f84a                	sd	s2,48(sp)
    800047a2:	f44e                	sd	s3,40(sp)
    800047a4:	f052                	sd	s4,32(sp)
    800047a6:	ec56                	sd	s5,24(sp)
    800047a8:	e85a                	sd	s6,16(sp)
    800047aa:	e45e                	sd	s7,8(sp)
    800047ac:	e062                	sd	s8,0(sp)
    800047ae:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047b0:	00954783          	lbu	a5,9(a0)
    800047b4:	10078663          	beqz	a5,800048c0 <filewrite+0x128>
    800047b8:	892a                	mv	s2,a0
    800047ba:	8aae                	mv	s5,a1
    800047bc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047be:	411c                	lw	a5,0(a0)
    800047c0:	4705                	li	a4,1
    800047c2:	02e78263          	beq	a5,a4,800047e6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c6:	470d                	li	a4,3
    800047c8:	02e78663          	beq	a5,a4,800047f4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047cc:	4709                	li	a4,2
    800047ce:	0ee79163          	bne	a5,a4,800048b0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047d2:	0ac05d63          	blez	a2,8000488c <filewrite+0xf4>
    int i = 0;
    800047d6:	4981                	li	s3,0
    800047d8:	6b05                	lui	s6,0x1
    800047da:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047de:	6b85                	lui	s7,0x1
    800047e0:	c00b8b9b          	addiw	s7,s7,-1024
    800047e4:	a861                	j	8000487c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047e6:	6908                	ld	a0,16(a0)
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	22e080e7          	jalr	558(ra) # 80004a16 <pipewrite>
    800047f0:	8a2a                	mv	s4,a0
    800047f2:	a045                	j	80004892 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047f4:	02451783          	lh	a5,36(a0)
    800047f8:	03079693          	slli	a3,a5,0x30
    800047fc:	92c1                	srli	a3,a3,0x30
    800047fe:	4725                	li	a4,9
    80004800:	0cd76263          	bltu	a4,a3,800048c4 <filewrite+0x12c>
    80004804:	0792                	slli	a5,a5,0x4
    80004806:	0001d717          	auipc	a4,0x1d
    8000480a:	b1270713          	addi	a4,a4,-1262 # 80021318 <devsw>
    8000480e:	97ba                	add	a5,a5,a4
    80004810:	679c                	ld	a5,8(a5)
    80004812:	cbdd                	beqz	a5,800048c8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004814:	4505                	li	a0,1
    80004816:	9782                	jalr	a5
    80004818:	8a2a                	mv	s4,a0
    8000481a:	a8a5                	j	80004892 <filewrite+0xfa>
    8000481c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004820:	00000097          	auipc	ra,0x0
    80004824:	8b0080e7          	jalr	-1872(ra) # 800040d0 <begin_op>
      ilock(f->ip);
    80004828:	01893503          	ld	a0,24(s2)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	ece080e7          	jalr	-306(ra) # 800036fa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004834:	8762                	mv	a4,s8
    80004836:	02092683          	lw	a3,32(s2)
    8000483a:	01598633          	add	a2,s3,s5
    8000483e:	4585                	li	a1,1
    80004840:	01893503          	ld	a0,24(s2)
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	262080e7          	jalr	610(ra) # 80003aa6 <writei>
    8000484c:	84aa                	mv	s1,a0
    8000484e:	00a05763          	blez	a0,8000485c <filewrite+0xc4>
        f->off += r;
    80004852:	02092783          	lw	a5,32(s2)
    80004856:	9fa9                	addw	a5,a5,a0
    80004858:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000485c:	01893503          	ld	a0,24(s2)
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	f5c080e7          	jalr	-164(ra) # 800037bc <iunlock>
      end_op();
    80004868:	00000097          	auipc	ra,0x0
    8000486c:	8e8080e7          	jalr	-1816(ra) # 80004150 <end_op>

      if(r != n1){
    80004870:	009c1f63          	bne	s8,s1,8000488e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004874:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004878:	0149db63          	bge	s3,s4,8000488e <filewrite+0xf6>
      int n1 = n - i;
    8000487c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004880:	84be                	mv	s1,a5
    80004882:	2781                	sext.w	a5,a5
    80004884:	f8fb5ce3          	bge	s6,a5,8000481c <filewrite+0x84>
    80004888:	84de                	mv	s1,s7
    8000488a:	bf49                	j	8000481c <filewrite+0x84>
    int i = 0;
    8000488c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000488e:	013a1f63          	bne	s4,s3,800048ac <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004892:	8552                	mv	a0,s4
    80004894:	60a6                	ld	ra,72(sp)
    80004896:	6406                	ld	s0,64(sp)
    80004898:	74e2                	ld	s1,56(sp)
    8000489a:	7942                	ld	s2,48(sp)
    8000489c:	79a2                	ld	s3,40(sp)
    8000489e:	7a02                	ld	s4,32(sp)
    800048a0:	6ae2                	ld	s5,24(sp)
    800048a2:	6b42                	ld	s6,16(sp)
    800048a4:	6ba2                	ld	s7,8(sp)
    800048a6:	6c02                	ld	s8,0(sp)
    800048a8:	6161                	addi	sp,sp,80
    800048aa:	8082                	ret
    ret = (i == n ? n : -1);
    800048ac:	5a7d                	li	s4,-1
    800048ae:	b7d5                	j	80004892 <filewrite+0xfa>
    panic("filewrite");
    800048b0:	00004517          	auipc	a0,0x4
    800048b4:	ef050513          	addi	a0,a0,-272 # 800087a0 <syscalls+0x270>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	c72080e7          	jalr	-910(ra) # 8000052a <panic>
    return -1;
    800048c0:	5a7d                	li	s4,-1
    800048c2:	bfc1                	j	80004892 <filewrite+0xfa>
      return -1;
    800048c4:	5a7d                	li	s4,-1
    800048c6:	b7f1                	j	80004892 <filewrite+0xfa>
    800048c8:	5a7d                	li	s4,-1
    800048ca:	b7e1                	j	80004892 <filewrite+0xfa>

00000000800048cc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048cc:	7179                	addi	sp,sp,-48
    800048ce:	f406                	sd	ra,40(sp)
    800048d0:	f022                	sd	s0,32(sp)
    800048d2:	ec26                	sd	s1,24(sp)
    800048d4:	e84a                	sd	s2,16(sp)
    800048d6:	e44e                	sd	s3,8(sp)
    800048d8:	e052                	sd	s4,0(sp)
    800048da:	1800                	addi	s0,sp,48
    800048dc:	84aa                	mv	s1,a0
    800048de:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048e0:	0005b023          	sd	zero,0(a1)
    800048e4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	bf8080e7          	jalr	-1032(ra) # 800044e0 <filealloc>
    800048f0:	e088                	sd	a0,0(s1)
    800048f2:	c551                	beqz	a0,8000497e <pipealloc+0xb2>
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	bec080e7          	jalr	-1044(ra) # 800044e0 <filealloc>
    800048fc:	00aa3023          	sd	a0,0(s4)
    80004900:	c92d                	beqz	a0,80004972 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	1d0080e7          	jalr	464(ra) # 80000ad2 <kalloc>
    8000490a:	892a                	mv	s2,a0
    8000490c:	c125                	beqz	a0,8000496c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000490e:	4985                	li	s3,1
    80004910:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004914:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004918:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000491c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004920:	00004597          	auipc	a1,0x4
    80004924:	b6858593          	addi	a1,a1,-1176 # 80008488 <states.0+0x1e0>
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	20a080e7          	jalr	522(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004930:	609c                	ld	a5,0(s1)
    80004932:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004936:	609c                	ld	a5,0(s1)
    80004938:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000493c:	609c                	ld	a5,0(s1)
    8000493e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004942:	609c                	ld	a5,0(s1)
    80004944:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004948:	000a3783          	ld	a5,0(s4)
    8000494c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004950:	000a3783          	ld	a5,0(s4)
    80004954:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004958:	000a3783          	ld	a5,0(s4)
    8000495c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004960:	000a3783          	ld	a5,0(s4)
    80004964:	0127b823          	sd	s2,16(a5)
  return 0;
    80004968:	4501                	li	a0,0
    8000496a:	a025                	j	80004992 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000496c:	6088                	ld	a0,0(s1)
    8000496e:	e501                	bnez	a0,80004976 <pipealloc+0xaa>
    80004970:	a039                	j	8000497e <pipealloc+0xb2>
    80004972:	6088                	ld	a0,0(s1)
    80004974:	c51d                	beqz	a0,800049a2 <pipealloc+0xd6>
    fileclose(*f0);
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	c26080e7          	jalr	-986(ra) # 8000459c <fileclose>
  if(*f1)
    8000497e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004982:	557d                	li	a0,-1
  if(*f1)
    80004984:	c799                	beqz	a5,80004992 <pipealloc+0xc6>
    fileclose(*f1);
    80004986:	853e                	mv	a0,a5
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	c14080e7          	jalr	-1004(ra) # 8000459c <fileclose>
  return -1;
    80004990:	557d                	li	a0,-1
}
    80004992:	70a2                	ld	ra,40(sp)
    80004994:	7402                	ld	s0,32(sp)
    80004996:	64e2                	ld	s1,24(sp)
    80004998:	6942                	ld	s2,16(sp)
    8000499a:	69a2                	ld	s3,8(sp)
    8000499c:	6a02                	ld	s4,0(sp)
    8000499e:	6145                	addi	sp,sp,48
    800049a0:	8082                	ret
  return -1;
    800049a2:	557d                	li	a0,-1
    800049a4:	b7fd                	j	80004992 <pipealloc+0xc6>

00000000800049a6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049a6:	1101                	addi	sp,sp,-32
    800049a8:	ec06                	sd	ra,24(sp)
    800049aa:	e822                	sd	s0,16(sp)
    800049ac:	e426                	sd	s1,8(sp)
    800049ae:	e04a                	sd	s2,0(sp)
    800049b0:	1000                	addi	s0,sp,32
    800049b2:	84aa                	mv	s1,a0
    800049b4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	20c080e7          	jalr	524(ra) # 80000bc2 <acquire>
  if(writable){
    800049be:	02090d63          	beqz	s2,800049f8 <pipeclose+0x52>
    pi->writeopen = 0;
    800049c2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049c6:	21848513          	addi	a0,s1,536
    800049ca:	ffffe097          	auipc	ra,0xffffe
    800049ce:	80c080e7          	jalr	-2036(ra) # 800021d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049d2:	2204b783          	ld	a5,544(s1)
    800049d6:	eb95                	bnez	a5,80004a0a <pipeclose+0x64>
    release(&pi->lock);
    800049d8:	8526                	mv	a0,s1
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	29c080e7          	jalr	668(ra) # 80000c76 <release>
    kfree((char*)pi);
    800049e2:	8526                	mv	a0,s1
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	ff2080e7          	jalr	-14(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800049ec:	60e2                	ld	ra,24(sp)
    800049ee:	6442                	ld	s0,16(sp)
    800049f0:	64a2                	ld	s1,8(sp)
    800049f2:	6902                	ld	s2,0(sp)
    800049f4:	6105                	addi	sp,sp,32
    800049f6:	8082                	ret
    pi->readopen = 0;
    800049f8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049fc:	21c48513          	addi	a0,s1,540
    80004a00:	ffffd097          	auipc	ra,0xffffd
    80004a04:	7d6080e7          	jalr	2006(ra) # 800021d6 <wakeup>
    80004a08:	b7e9                	j	800049d2 <pipeclose+0x2c>
    release(&pi->lock);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	26a080e7          	jalr	618(ra) # 80000c76 <release>
}
    80004a14:	bfe1                	j	800049ec <pipeclose+0x46>

0000000080004a16 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a16:	711d                	addi	sp,sp,-96
    80004a18:	ec86                	sd	ra,88(sp)
    80004a1a:	e8a2                	sd	s0,80(sp)
    80004a1c:	e4a6                	sd	s1,72(sp)
    80004a1e:	e0ca                	sd	s2,64(sp)
    80004a20:	fc4e                	sd	s3,56(sp)
    80004a22:	f852                	sd	s4,48(sp)
    80004a24:	f456                	sd	s5,40(sp)
    80004a26:	f05a                	sd	s6,32(sp)
    80004a28:	ec5e                	sd	s7,24(sp)
    80004a2a:	e862                	sd	s8,16(sp)
    80004a2c:	1080                	addi	s0,sp,96
    80004a2e:	84aa                	mv	s1,a0
    80004a30:	8aae                	mv	s5,a1
    80004a32:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a34:	ffffd097          	auipc	ra,0xffffd
    80004a38:	f4a080e7          	jalr	-182(ra) # 8000197e <myproc>
    80004a3c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a3e:	8526                	mv	a0,s1
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	182080e7          	jalr	386(ra) # 80000bc2 <acquire>
  while(i < n){
    80004a48:	0b405363          	blez	s4,80004aee <pipewrite+0xd8>
  int i = 0;
    80004a4c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a4e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a50:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a54:	21c48b93          	addi	s7,s1,540
    80004a58:	a089                	j	80004a9a <pipewrite+0x84>
      release(&pi->lock);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	21a080e7          	jalr	538(ra) # 80000c76 <release>
      return -1;
    80004a64:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a66:	854a                	mv	a0,s2
    80004a68:	60e6                	ld	ra,88(sp)
    80004a6a:	6446                	ld	s0,80(sp)
    80004a6c:	64a6                	ld	s1,72(sp)
    80004a6e:	6906                	ld	s2,64(sp)
    80004a70:	79e2                	ld	s3,56(sp)
    80004a72:	7a42                	ld	s4,48(sp)
    80004a74:	7aa2                	ld	s5,40(sp)
    80004a76:	7b02                	ld	s6,32(sp)
    80004a78:	6be2                	ld	s7,24(sp)
    80004a7a:	6c42                	ld	s8,16(sp)
    80004a7c:	6125                	addi	sp,sp,96
    80004a7e:	8082                	ret
      wakeup(&pi->nread);
    80004a80:	8562                	mv	a0,s8
    80004a82:	ffffd097          	auipc	ra,0xffffd
    80004a86:	754080e7          	jalr	1876(ra) # 800021d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a8a:	85a6                	mv	a1,s1
    80004a8c:	855e                	mv	a0,s7
    80004a8e:	ffffd097          	auipc	ra,0xffffd
    80004a92:	5bc080e7          	jalr	1468(ra) # 8000204a <sleep>
  while(i < n){
    80004a96:	05495d63          	bge	s2,s4,80004af0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004a9a:	2204a783          	lw	a5,544(s1)
    80004a9e:	dfd5                	beqz	a5,80004a5a <pipewrite+0x44>
    80004aa0:	0289a783          	lw	a5,40(s3)
    80004aa4:	fbdd                	bnez	a5,80004a5a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004aa6:	2184a783          	lw	a5,536(s1)
    80004aaa:	21c4a703          	lw	a4,540(s1)
    80004aae:	2007879b          	addiw	a5,a5,512
    80004ab2:	fcf707e3          	beq	a4,a5,80004a80 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ab6:	4685                	li	a3,1
    80004ab8:	01590633          	add	a2,s2,s5
    80004abc:	faf40593          	addi	a1,s0,-81
    80004ac0:	0509b503          	ld	a0,80(s3)
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	c06080e7          	jalr	-1018(ra) # 800016ca <copyin>
    80004acc:	03650263          	beq	a0,s6,80004af0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ad0:	21c4a783          	lw	a5,540(s1)
    80004ad4:	0017871b          	addiw	a4,a5,1
    80004ad8:	20e4ae23          	sw	a4,540(s1)
    80004adc:	1ff7f793          	andi	a5,a5,511
    80004ae0:	97a6                	add	a5,a5,s1
    80004ae2:	faf44703          	lbu	a4,-81(s0)
    80004ae6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004aea:	2905                	addiw	s2,s2,1
    80004aec:	b76d                	j	80004a96 <pipewrite+0x80>
  int i = 0;
    80004aee:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004af0:	21848513          	addi	a0,s1,536
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	6e2080e7          	jalr	1762(ra) # 800021d6 <wakeup>
  release(&pi->lock);
    80004afc:	8526                	mv	a0,s1
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	178080e7          	jalr	376(ra) # 80000c76 <release>
  return i;
    80004b06:	b785                	j	80004a66 <pipewrite+0x50>

0000000080004b08 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b08:	715d                	addi	sp,sp,-80
    80004b0a:	e486                	sd	ra,72(sp)
    80004b0c:	e0a2                	sd	s0,64(sp)
    80004b0e:	fc26                	sd	s1,56(sp)
    80004b10:	f84a                	sd	s2,48(sp)
    80004b12:	f44e                	sd	s3,40(sp)
    80004b14:	f052                	sd	s4,32(sp)
    80004b16:	ec56                	sd	s5,24(sp)
    80004b18:	e85a                	sd	s6,16(sp)
    80004b1a:	0880                	addi	s0,sp,80
    80004b1c:	84aa                	mv	s1,a0
    80004b1e:	892e                	mv	s2,a1
    80004b20:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	e5c080e7          	jalr	-420(ra) # 8000197e <myproc>
    80004b2a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	094080e7          	jalr	148(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b36:	2184a703          	lw	a4,536(s1)
    80004b3a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b3e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b42:	02f71463          	bne	a4,a5,80004b6a <piperead+0x62>
    80004b46:	2244a783          	lw	a5,548(s1)
    80004b4a:	c385                	beqz	a5,80004b6a <piperead+0x62>
    if(pr->killed){
    80004b4c:	028a2783          	lw	a5,40(s4)
    80004b50:	ebc1                	bnez	a5,80004be0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b52:	85a6                	mv	a1,s1
    80004b54:	854e                	mv	a0,s3
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	4f4080e7          	jalr	1268(ra) # 8000204a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5e:	2184a703          	lw	a4,536(s1)
    80004b62:	21c4a783          	lw	a5,540(s1)
    80004b66:	fef700e3          	beq	a4,a5,80004b46 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b6c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6e:	05505363          	blez	s5,80004bb4 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b72:	2184a783          	lw	a5,536(s1)
    80004b76:	21c4a703          	lw	a4,540(s1)
    80004b7a:	02f70d63          	beq	a4,a5,80004bb4 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b7e:	0017871b          	addiw	a4,a5,1
    80004b82:	20e4ac23          	sw	a4,536(s1)
    80004b86:	1ff7f793          	andi	a5,a5,511
    80004b8a:	97a6                	add	a5,a5,s1
    80004b8c:	0187c783          	lbu	a5,24(a5)
    80004b90:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b94:	4685                	li	a3,1
    80004b96:	fbf40613          	addi	a2,s0,-65
    80004b9a:	85ca                	mv	a1,s2
    80004b9c:	050a3503          	ld	a0,80(s4)
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	a9e080e7          	jalr	-1378(ra) # 8000163e <copyout>
    80004ba8:	01650663          	beq	a0,s6,80004bb4 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bac:	2985                	addiw	s3,s3,1
    80004bae:	0905                	addi	s2,s2,1
    80004bb0:	fd3a91e3          	bne	s5,s3,80004b72 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bb4:	21c48513          	addi	a0,s1,540
    80004bb8:	ffffd097          	auipc	ra,0xffffd
    80004bbc:	61e080e7          	jalr	1566(ra) # 800021d6 <wakeup>
  release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0b4080e7          	jalr	180(ra) # 80000c76 <release>
  return i;
}
    80004bca:	854e                	mv	a0,s3
    80004bcc:	60a6                	ld	ra,72(sp)
    80004bce:	6406                	ld	s0,64(sp)
    80004bd0:	74e2                	ld	s1,56(sp)
    80004bd2:	7942                	ld	s2,48(sp)
    80004bd4:	79a2                	ld	s3,40(sp)
    80004bd6:	7a02                	ld	s4,32(sp)
    80004bd8:	6ae2                	ld	s5,24(sp)
    80004bda:	6b42                	ld	s6,16(sp)
    80004bdc:	6161                	addi	sp,sp,80
    80004bde:	8082                	ret
      release(&pi->lock);
    80004be0:	8526                	mv	a0,s1
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	094080e7          	jalr	148(ra) # 80000c76 <release>
      return -1;
    80004bea:	59fd                	li	s3,-1
    80004bec:	bff9                	j	80004bca <piperead+0xc2>

0000000080004bee <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bee:	de010113          	addi	sp,sp,-544
    80004bf2:	20113c23          	sd	ra,536(sp)
    80004bf6:	20813823          	sd	s0,528(sp)
    80004bfa:	20913423          	sd	s1,520(sp)
    80004bfe:	21213023          	sd	s2,512(sp)
    80004c02:	ffce                	sd	s3,504(sp)
    80004c04:	fbd2                	sd	s4,496(sp)
    80004c06:	f7d6                	sd	s5,488(sp)
    80004c08:	f3da                	sd	s6,480(sp)
    80004c0a:	efde                	sd	s7,472(sp)
    80004c0c:	ebe2                	sd	s8,464(sp)
    80004c0e:	e7e6                	sd	s9,456(sp)
    80004c10:	e3ea                	sd	s10,448(sp)
    80004c12:	ff6e                	sd	s11,440(sp)
    80004c14:	1400                	addi	s0,sp,544
    80004c16:	892a                	mv	s2,a0
    80004c18:	dea43423          	sd	a0,-536(s0)
    80004c1c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	d5e080e7          	jalr	-674(ra) # 8000197e <myproc>
    80004c28:	84aa                	mv	s1,a0

  begin_op();
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	4a6080e7          	jalr	1190(ra) # 800040d0 <begin_op>

  if((ip = namei(path)) == 0){
    80004c32:	854a                	mv	a0,s2
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	27c080e7          	jalr	636(ra) # 80003eb0 <namei>
    80004c3c:	c93d                	beqz	a0,80004cb2 <exec+0xc4>
    80004c3e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	aba080e7          	jalr	-1350(ra) # 800036fa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c48:	04000713          	li	a4,64
    80004c4c:	4681                	li	a3,0
    80004c4e:	e4840613          	addi	a2,s0,-440
    80004c52:	4581                	li	a1,0
    80004c54:	8556                	mv	a0,s5
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	d58080e7          	jalr	-680(ra) # 800039ae <readi>
    80004c5e:	04000793          	li	a5,64
    80004c62:	00f51a63          	bne	a0,a5,80004c76 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c66:	e4842703          	lw	a4,-440(s0)
    80004c6a:	464c47b7          	lui	a5,0x464c4
    80004c6e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c72:	04f70663          	beq	a4,a5,80004cbe <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c76:	8556                	mv	a0,s5
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	ce4080e7          	jalr	-796(ra) # 8000395c <iunlockput>
    end_op();
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	4d0080e7          	jalr	1232(ra) # 80004150 <end_op>
  }
  return -1;
    80004c88:	557d                	li	a0,-1
}
    80004c8a:	21813083          	ld	ra,536(sp)
    80004c8e:	21013403          	ld	s0,528(sp)
    80004c92:	20813483          	ld	s1,520(sp)
    80004c96:	20013903          	ld	s2,512(sp)
    80004c9a:	79fe                	ld	s3,504(sp)
    80004c9c:	7a5e                	ld	s4,496(sp)
    80004c9e:	7abe                	ld	s5,488(sp)
    80004ca0:	7b1e                	ld	s6,480(sp)
    80004ca2:	6bfe                	ld	s7,472(sp)
    80004ca4:	6c5e                	ld	s8,464(sp)
    80004ca6:	6cbe                	ld	s9,456(sp)
    80004ca8:	6d1e                	ld	s10,448(sp)
    80004caa:	7dfa                	ld	s11,440(sp)
    80004cac:	22010113          	addi	sp,sp,544
    80004cb0:	8082                	ret
    end_op();
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	49e080e7          	jalr	1182(ra) # 80004150 <end_op>
    return -1;
    80004cba:	557d                	li	a0,-1
    80004cbc:	b7f9                	j	80004c8a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	d82080e7          	jalr	-638(ra) # 80001a42 <proc_pagetable>
    80004cc8:	8b2a                	mv	s6,a0
    80004cca:	d555                	beqz	a0,80004c76 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ccc:	e6842783          	lw	a5,-408(s0)
    80004cd0:	e8045703          	lhu	a4,-384(s0)
    80004cd4:	c735                	beqz	a4,80004d40 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cd6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cdc:	6a05                	lui	s4,0x1
    80004cde:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ce2:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004ce6:	6d85                	lui	s11,0x1
    80004ce8:	7d7d                	lui	s10,0xfffff
    80004cea:	ac1d                	j	80004f20 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cec:	00004517          	auipc	a0,0x4
    80004cf0:	ac450513          	addi	a0,a0,-1340 # 800087b0 <syscalls+0x280>
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	836080e7          	jalr	-1994(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cfc:	874a                	mv	a4,s2
    80004cfe:	009c86bb          	addw	a3,s9,s1
    80004d02:	4581                	li	a1,0
    80004d04:	8556                	mv	a0,s5
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	ca8080e7          	jalr	-856(ra) # 800039ae <readi>
    80004d0e:	2501                	sext.w	a0,a0
    80004d10:	1aa91863          	bne	s2,a0,80004ec0 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d14:	009d84bb          	addw	s1,s11,s1
    80004d18:	013d09bb          	addw	s3,s10,s3
    80004d1c:	1f74f263          	bgeu	s1,s7,80004f00 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d20:	02049593          	slli	a1,s1,0x20
    80004d24:	9181                	srli	a1,a1,0x20
    80004d26:	95e2                	add	a1,a1,s8
    80004d28:	855a                	mv	a0,s6
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	322080e7          	jalr	802(ra) # 8000104c <walkaddr>
    80004d32:	862a                	mv	a2,a0
    if(pa == 0)
    80004d34:	dd45                	beqz	a0,80004cec <exec+0xfe>
      n = PGSIZE;
    80004d36:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d38:	fd49f2e3          	bgeu	s3,s4,80004cfc <exec+0x10e>
      n = sz - i;
    80004d3c:	894e                	mv	s2,s3
    80004d3e:	bf7d                	j	80004cfc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d40:	4481                	li	s1,0
  iunlockput(ip);
    80004d42:	8556                	mv	a0,s5
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	c18080e7          	jalr	-1000(ra) # 8000395c <iunlockput>
  end_op();
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	404080e7          	jalr	1028(ra) # 80004150 <end_op>
  p = myproc();
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	c2a080e7          	jalr	-982(ra) # 8000197e <myproc>
    80004d5c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d5e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d62:	6785                	lui	a5,0x1
    80004d64:	17fd                	addi	a5,a5,-1
    80004d66:	94be                	add	s1,s1,a5
    80004d68:	77fd                	lui	a5,0xfffff
    80004d6a:	8fe5                	and	a5,a5,s1
    80004d6c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d70:	6609                	lui	a2,0x2
    80004d72:	963e                	add	a2,a2,a5
    80004d74:	85be                	mv	a1,a5
    80004d76:	855a                	mv	a0,s6
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	676080e7          	jalr	1654(ra) # 800013ee <uvmalloc>
    80004d80:	8c2a                	mv	s8,a0
  ip = 0;
    80004d82:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d84:	12050e63          	beqz	a0,80004ec0 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d88:	75f9                	lui	a1,0xffffe
    80004d8a:	95aa                	add	a1,a1,a0
    80004d8c:	855a                	mv	a0,s6
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	87e080e7          	jalr	-1922(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004d96:	7afd                	lui	s5,0xfffff
    80004d98:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d9a:	df043783          	ld	a5,-528(s0)
    80004d9e:	6388                	ld	a0,0(a5)
    80004da0:	c925                	beqz	a0,80004e10 <exec+0x222>
    80004da2:	e8840993          	addi	s3,s0,-376
    80004da6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004daa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dac:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	094080e7          	jalr	148(ra) # 80000e42 <strlen>
    80004db6:	0015079b          	addiw	a5,a0,1
    80004dba:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dbe:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dc2:	13596363          	bltu	s2,s5,80004ee8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dc6:	df043d83          	ld	s11,-528(s0)
    80004dca:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dce:	8552                	mv	a0,s4
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	072080e7          	jalr	114(ra) # 80000e42 <strlen>
    80004dd8:	0015069b          	addiw	a3,a0,1
    80004ddc:	8652                	mv	a2,s4
    80004dde:	85ca                	mv	a1,s2
    80004de0:	855a                	mv	a0,s6
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	85c080e7          	jalr	-1956(ra) # 8000163e <copyout>
    80004dea:	10054363          	bltz	a0,80004ef0 <exec+0x302>
    ustack[argc] = sp;
    80004dee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004df2:	0485                	addi	s1,s1,1
    80004df4:	008d8793          	addi	a5,s11,8
    80004df8:	def43823          	sd	a5,-528(s0)
    80004dfc:	008db503          	ld	a0,8(s11)
    80004e00:	c911                	beqz	a0,80004e14 <exec+0x226>
    if(argc >= MAXARG)
    80004e02:	09a1                	addi	s3,s3,8
    80004e04:	fb3c95e3          	bne	s9,s3,80004dae <exec+0x1c0>
  sz = sz1;
    80004e08:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e0c:	4a81                	li	s5,0
    80004e0e:	a84d                	j	80004ec0 <exec+0x2d2>
  sp = sz;
    80004e10:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e12:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e14:	00349793          	slli	a5,s1,0x3
    80004e18:	f9040713          	addi	a4,s0,-112
    80004e1c:	97ba                	add	a5,a5,a4
    80004e1e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004e22:	00148693          	addi	a3,s1,1
    80004e26:	068e                	slli	a3,a3,0x3
    80004e28:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e2c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e30:	01597663          	bgeu	s2,s5,80004e3c <exec+0x24e>
  sz = sz1;
    80004e34:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e38:	4a81                	li	s5,0
    80004e3a:	a059                	j	80004ec0 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e3c:	e8840613          	addi	a2,s0,-376
    80004e40:	85ca                	mv	a1,s2
    80004e42:	855a                	mv	a0,s6
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	7fa080e7          	jalr	2042(ra) # 8000163e <copyout>
    80004e4c:	0a054663          	bltz	a0,80004ef8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e50:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e54:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e58:	de843783          	ld	a5,-536(s0)
    80004e5c:	0007c703          	lbu	a4,0(a5)
    80004e60:	cf11                	beqz	a4,80004e7c <exec+0x28e>
    80004e62:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e64:	02f00693          	li	a3,47
    80004e68:	a039                	j	80004e76 <exec+0x288>
      last = s+1;
    80004e6a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e6e:	0785                	addi	a5,a5,1
    80004e70:	fff7c703          	lbu	a4,-1(a5)
    80004e74:	c701                	beqz	a4,80004e7c <exec+0x28e>
    if(*s == '/')
    80004e76:	fed71ce3          	bne	a4,a3,80004e6e <exec+0x280>
    80004e7a:	bfc5                	j	80004e6a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e7c:	4641                	li	a2,16
    80004e7e:	de843583          	ld	a1,-536(s0)
    80004e82:	158b8513          	addi	a0,s7,344
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	f8a080e7          	jalr	-118(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e8e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e92:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e96:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e9a:	058bb783          	ld	a5,88(s7)
    80004e9e:	e6043703          	ld	a4,-416(s0)
    80004ea2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ea4:	058bb783          	ld	a5,88(s7)
    80004ea8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eac:	85ea                	mv	a1,s10
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	c30080e7          	jalr	-976(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004eb6:	0004851b          	sext.w	a0,s1
    80004eba:	bbc1                	j	80004c8a <exec+0x9c>
    80004ebc:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ec0:	df843583          	ld	a1,-520(s0)
    80004ec4:	855a                	mv	a0,s6
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	c18080e7          	jalr	-1000(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80004ece:	da0a94e3          	bnez	s5,80004c76 <exec+0x88>
  return -1;
    80004ed2:	557d                	li	a0,-1
    80004ed4:	bb5d                	j	80004c8a <exec+0x9c>
    80004ed6:	de943c23          	sd	s1,-520(s0)
    80004eda:	b7dd                	j	80004ec0 <exec+0x2d2>
    80004edc:	de943c23          	sd	s1,-520(s0)
    80004ee0:	b7c5                	j	80004ec0 <exec+0x2d2>
    80004ee2:	de943c23          	sd	s1,-520(s0)
    80004ee6:	bfe9                	j	80004ec0 <exec+0x2d2>
  sz = sz1;
    80004ee8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eec:	4a81                	li	s5,0
    80004eee:	bfc9                	j	80004ec0 <exec+0x2d2>
  sz = sz1;
    80004ef0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ef4:	4a81                	li	s5,0
    80004ef6:	b7e9                	j	80004ec0 <exec+0x2d2>
  sz = sz1;
    80004ef8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004efc:	4a81                	li	s5,0
    80004efe:	b7c9                	j	80004ec0 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f00:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f04:	e0843783          	ld	a5,-504(s0)
    80004f08:	0017869b          	addiw	a3,a5,1
    80004f0c:	e0d43423          	sd	a3,-504(s0)
    80004f10:	e0043783          	ld	a5,-512(s0)
    80004f14:	0387879b          	addiw	a5,a5,56
    80004f18:	e8045703          	lhu	a4,-384(s0)
    80004f1c:	e2e6d3e3          	bge	a3,a4,80004d42 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f20:	2781                	sext.w	a5,a5
    80004f22:	e0f43023          	sd	a5,-512(s0)
    80004f26:	03800713          	li	a4,56
    80004f2a:	86be                	mv	a3,a5
    80004f2c:	e1040613          	addi	a2,s0,-496
    80004f30:	4581                	li	a1,0
    80004f32:	8556                	mv	a0,s5
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	a7a080e7          	jalr	-1414(ra) # 800039ae <readi>
    80004f3c:	03800793          	li	a5,56
    80004f40:	f6f51ee3          	bne	a0,a5,80004ebc <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f44:	e1042783          	lw	a5,-496(s0)
    80004f48:	4705                	li	a4,1
    80004f4a:	fae79de3          	bne	a5,a4,80004f04 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f4e:	e3843603          	ld	a2,-456(s0)
    80004f52:	e3043783          	ld	a5,-464(s0)
    80004f56:	f8f660e3          	bltu	a2,a5,80004ed6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f5a:	e2043783          	ld	a5,-480(s0)
    80004f5e:	963e                	add	a2,a2,a5
    80004f60:	f6f66ee3          	bltu	a2,a5,80004edc <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f64:	85a6                	mv	a1,s1
    80004f66:	855a                	mv	a0,s6
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	486080e7          	jalr	1158(ra) # 800013ee <uvmalloc>
    80004f70:	dea43c23          	sd	a0,-520(s0)
    80004f74:	d53d                	beqz	a0,80004ee2 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f76:	e2043c03          	ld	s8,-480(s0)
    80004f7a:	de043783          	ld	a5,-544(s0)
    80004f7e:	00fc77b3          	and	a5,s8,a5
    80004f82:	ff9d                	bnez	a5,80004ec0 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f84:	e1842c83          	lw	s9,-488(s0)
    80004f88:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f8c:	f60b8ae3          	beqz	s7,80004f00 <exec+0x312>
    80004f90:	89de                	mv	s3,s7
    80004f92:	4481                	li	s1,0
    80004f94:	b371                	j	80004d20 <exec+0x132>

0000000080004f96 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f96:	7179                	addi	sp,sp,-48
    80004f98:	f406                	sd	ra,40(sp)
    80004f9a:	f022                	sd	s0,32(sp)
    80004f9c:	ec26                	sd	s1,24(sp)
    80004f9e:	e84a                	sd	s2,16(sp)
    80004fa0:	1800                	addi	s0,sp,48
    80004fa2:	892e                	mv	s2,a1
    80004fa4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fa6:	fdc40593          	addi	a1,s0,-36
    80004faa:	ffffe097          	auipc	ra,0xffffe
    80004fae:	ada080e7          	jalr	-1318(ra) # 80002a84 <argint>
    80004fb2:	04054063          	bltz	a0,80004ff2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fb6:	fdc42703          	lw	a4,-36(s0)
    80004fba:	47bd                	li	a5,15
    80004fbc:	02e7ed63          	bltu	a5,a4,80004ff6 <argfd+0x60>
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	9be080e7          	jalr	-1602(ra) # 8000197e <myproc>
    80004fc8:	fdc42703          	lw	a4,-36(s0)
    80004fcc:	01a70793          	addi	a5,a4,26
    80004fd0:	078e                	slli	a5,a5,0x3
    80004fd2:	953e                	add	a0,a0,a5
    80004fd4:	611c                	ld	a5,0(a0)
    80004fd6:	c395                	beqz	a5,80004ffa <argfd+0x64>
    return -1;
  if(pfd)
    80004fd8:	00090463          	beqz	s2,80004fe0 <argfd+0x4a>
    *pfd = fd;
    80004fdc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fe0:	4501                	li	a0,0
  if(pf)
    80004fe2:	c091                	beqz	s1,80004fe6 <argfd+0x50>
    *pf = f;
    80004fe4:	e09c                	sd	a5,0(s1)
}
    80004fe6:	70a2                	ld	ra,40(sp)
    80004fe8:	7402                	ld	s0,32(sp)
    80004fea:	64e2                	ld	s1,24(sp)
    80004fec:	6942                	ld	s2,16(sp)
    80004fee:	6145                	addi	sp,sp,48
    80004ff0:	8082                	ret
    return -1;
    80004ff2:	557d                	li	a0,-1
    80004ff4:	bfcd                	j	80004fe6 <argfd+0x50>
    return -1;
    80004ff6:	557d                	li	a0,-1
    80004ff8:	b7fd                	j	80004fe6 <argfd+0x50>
    80004ffa:	557d                	li	a0,-1
    80004ffc:	b7ed                	j	80004fe6 <argfd+0x50>

0000000080004ffe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ffe:	1101                	addi	sp,sp,-32
    80005000:	ec06                	sd	ra,24(sp)
    80005002:	e822                	sd	s0,16(sp)
    80005004:	e426                	sd	s1,8(sp)
    80005006:	1000                	addi	s0,sp,32
    80005008:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	974080e7          	jalr	-1676(ra) # 8000197e <myproc>
    80005012:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005014:	0d050793          	addi	a5,a0,208
    80005018:	4501                	li	a0,0
    8000501a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000501c:	6398                	ld	a4,0(a5)
    8000501e:	cb19                	beqz	a4,80005034 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005020:	2505                	addiw	a0,a0,1
    80005022:	07a1                	addi	a5,a5,8
    80005024:	fed51ce3          	bne	a0,a3,8000501c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005028:	557d                	li	a0,-1
}
    8000502a:	60e2                	ld	ra,24(sp)
    8000502c:	6442                	ld	s0,16(sp)
    8000502e:	64a2                	ld	s1,8(sp)
    80005030:	6105                	addi	sp,sp,32
    80005032:	8082                	ret
      p->ofile[fd] = f;
    80005034:	01a50793          	addi	a5,a0,26
    80005038:	078e                	slli	a5,a5,0x3
    8000503a:	963e                	add	a2,a2,a5
    8000503c:	e204                	sd	s1,0(a2)
      return fd;
    8000503e:	b7f5                	j	8000502a <fdalloc+0x2c>

0000000080005040 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005040:	715d                	addi	sp,sp,-80
    80005042:	e486                	sd	ra,72(sp)
    80005044:	e0a2                	sd	s0,64(sp)
    80005046:	fc26                	sd	s1,56(sp)
    80005048:	f84a                	sd	s2,48(sp)
    8000504a:	f44e                	sd	s3,40(sp)
    8000504c:	f052                	sd	s4,32(sp)
    8000504e:	ec56                	sd	s5,24(sp)
    80005050:	0880                	addi	s0,sp,80
    80005052:	89ae                	mv	s3,a1
    80005054:	8ab2                	mv	s5,a2
    80005056:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005058:	fb040593          	addi	a1,s0,-80
    8000505c:	fffff097          	auipc	ra,0xfffff
    80005060:	e72080e7          	jalr	-398(ra) # 80003ece <nameiparent>
    80005064:	892a                	mv	s2,a0
    80005066:	12050e63          	beqz	a0,800051a2 <create+0x162>
    return 0;

  ilock(dp);
    8000506a:	ffffe097          	auipc	ra,0xffffe
    8000506e:	690080e7          	jalr	1680(ra) # 800036fa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005072:	4601                	li	a2,0
    80005074:	fb040593          	addi	a1,s0,-80
    80005078:	854a                	mv	a0,s2
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	b64080e7          	jalr	-1180(ra) # 80003bde <dirlookup>
    80005082:	84aa                	mv	s1,a0
    80005084:	c921                	beqz	a0,800050d4 <create+0x94>
    iunlockput(dp);
    80005086:	854a                	mv	a0,s2
    80005088:	fffff097          	auipc	ra,0xfffff
    8000508c:	8d4080e7          	jalr	-1836(ra) # 8000395c <iunlockput>
    ilock(ip);
    80005090:	8526                	mv	a0,s1
    80005092:	ffffe097          	auipc	ra,0xffffe
    80005096:	668080e7          	jalr	1640(ra) # 800036fa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000509a:	2981                	sext.w	s3,s3
    8000509c:	4789                	li	a5,2
    8000509e:	02f99463          	bne	s3,a5,800050c6 <create+0x86>
    800050a2:	0444d783          	lhu	a5,68(s1)
    800050a6:	37f9                	addiw	a5,a5,-2
    800050a8:	17c2                	slli	a5,a5,0x30
    800050aa:	93c1                	srli	a5,a5,0x30
    800050ac:	4705                	li	a4,1
    800050ae:	00f76c63          	bltu	a4,a5,800050c6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050b2:	8526                	mv	a0,s1
    800050b4:	60a6                	ld	ra,72(sp)
    800050b6:	6406                	ld	s0,64(sp)
    800050b8:	74e2                	ld	s1,56(sp)
    800050ba:	7942                	ld	s2,48(sp)
    800050bc:	79a2                	ld	s3,40(sp)
    800050be:	7a02                	ld	s4,32(sp)
    800050c0:	6ae2                	ld	s5,24(sp)
    800050c2:	6161                	addi	sp,sp,80
    800050c4:	8082                	ret
    iunlockput(ip);
    800050c6:	8526                	mv	a0,s1
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	894080e7          	jalr	-1900(ra) # 8000395c <iunlockput>
    return 0;
    800050d0:	4481                	li	s1,0
    800050d2:	b7c5                	j	800050b2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050d4:	85ce                	mv	a1,s3
    800050d6:	00092503          	lw	a0,0(s2)
    800050da:	ffffe097          	auipc	ra,0xffffe
    800050de:	488080e7          	jalr	1160(ra) # 80003562 <ialloc>
    800050e2:	84aa                	mv	s1,a0
    800050e4:	c521                	beqz	a0,8000512c <create+0xec>
  ilock(ip);
    800050e6:	ffffe097          	auipc	ra,0xffffe
    800050ea:	614080e7          	jalr	1556(ra) # 800036fa <ilock>
  ip->major = major;
    800050ee:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050f2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050f6:	4a05                	li	s4,1
    800050f8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050fc:	8526                	mv	a0,s1
    800050fe:	ffffe097          	auipc	ra,0xffffe
    80005102:	532080e7          	jalr	1330(ra) # 80003630 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005106:	2981                	sext.w	s3,s3
    80005108:	03498a63          	beq	s3,s4,8000513c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000510c:	40d0                	lw	a2,4(s1)
    8000510e:	fb040593          	addi	a1,s0,-80
    80005112:	854a                	mv	a0,s2
    80005114:	fffff097          	auipc	ra,0xfffff
    80005118:	cda080e7          	jalr	-806(ra) # 80003dee <dirlink>
    8000511c:	06054b63          	bltz	a0,80005192 <create+0x152>
  iunlockput(dp);
    80005120:	854a                	mv	a0,s2
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	83a080e7          	jalr	-1990(ra) # 8000395c <iunlockput>
  return ip;
    8000512a:	b761                	j	800050b2 <create+0x72>
    panic("create: ialloc");
    8000512c:	00003517          	auipc	a0,0x3
    80005130:	6a450513          	addi	a0,a0,1700 # 800087d0 <syscalls+0x2a0>
    80005134:	ffffb097          	auipc	ra,0xffffb
    80005138:	3f6080e7          	jalr	1014(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000513c:	04a95783          	lhu	a5,74(s2)
    80005140:	2785                	addiw	a5,a5,1
    80005142:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005146:	854a                	mv	a0,s2
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	4e8080e7          	jalr	1256(ra) # 80003630 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005150:	40d0                	lw	a2,4(s1)
    80005152:	00003597          	auipc	a1,0x3
    80005156:	68e58593          	addi	a1,a1,1678 # 800087e0 <syscalls+0x2b0>
    8000515a:	8526                	mv	a0,s1
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	c92080e7          	jalr	-878(ra) # 80003dee <dirlink>
    80005164:	00054f63          	bltz	a0,80005182 <create+0x142>
    80005168:	00492603          	lw	a2,4(s2)
    8000516c:	00003597          	auipc	a1,0x3
    80005170:	67c58593          	addi	a1,a1,1660 # 800087e8 <syscalls+0x2b8>
    80005174:	8526                	mv	a0,s1
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	c78080e7          	jalr	-904(ra) # 80003dee <dirlink>
    8000517e:	f80557e3          	bgez	a0,8000510c <create+0xcc>
      panic("create dots");
    80005182:	00003517          	auipc	a0,0x3
    80005186:	66e50513          	addi	a0,a0,1646 # 800087f0 <syscalls+0x2c0>
    8000518a:	ffffb097          	auipc	ra,0xffffb
    8000518e:	3a0080e7          	jalr	928(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005192:	00003517          	auipc	a0,0x3
    80005196:	66e50513          	addi	a0,a0,1646 # 80008800 <syscalls+0x2d0>
    8000519a:	ffffb097          	auipc	ra,0xffffb
    8000519e:	390080e7          	jalr	912(ra) # 8000052a <panic>
    return 0;
    800051a2:	84aa                	mv	s1,a0
    800051a4:	b739                	j	800050b2 <create+0x72>

00000000800051a6 <sys_dup>:
{
    800051a6:	7179                	addi	sp,sp,-48
    800051a8:	f406                	sd	ra,40(sp)
    800051aa:	f022                	sd	s0,32(sp)
    800051ac:	ec26                	sd	s1,24(sp)
    800051ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051b0:	fd840613          	addi	a2,s0,-40
    800051b4:	4581                	li	a1,0
    800051b6:	4501                	li	a0,0
    800051b8:	00000097          	auipc	ra,0x0
    800051bc:	dde080e7          	jalr	-546(ra) # 80004f96 <argfd>
    return -1;
    800051c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051c2:	02054363          	bltz	a0,800051e8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051c6:	fd843503          	ld	a0,-40(s0)
    800051ca:	00000097          	auipc	ra,0x0
    800051ce:	e34080e7          	jalr	-460(ra) # 80004ffe <fdalloc>
    800051d2:	84aa                	mv	s1,a0
    return -1;
    800051d4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051d6:	00054963          	bltz	a0,800051e8 <sys_dup+0x42>
  filedup(f);
    800051da:	fd843503          	ld	a0,-40(s0)
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	36c080e7          	jalr	876(ra) # 8000454a <filedup>
  return fd;
    800051e6:	87a6                	mv	a5,s1
}
    800051e8:	853e                	mv	a0,a5
    800051ea:	70a2                	ld	ra,40(sp)
    800051ec:	7402                	ld	s0,32(sp)
    800051ee:	64e2                	ld	s1,24(sp)
    800051f0:	6145                	addi	sp,sp,48
    800051f2:	8082                	ret

00000000800051f4 <sys_read>:
{
    800051f4:	7179                	addi	sp,sp,-48
    800051f6:	f406                	sd	ra,40(sp)
    800051f8:	f022                	sd	s0,32(sp)
    800051fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fc:	fe840613          	addi	a2,s0,-24
    80005200:	4581                	li	a1,0
    80005202:	4501                	li	a0,0
    80005204:	00000097          	auipc	ra,0x0
    80005208:	d92080e7          	jalr	-622(ra) # 80004f96 <argfd>
    return -1;
    8000520c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000520e:	04054163          	bltz	a0,80005250 <sys_read+0x5c>
    80005212:	fe440593          	addi	a1,s0,-28
    80005216:	4509                	li	a0,2
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	86c080e7          	jalr	-1940(ra) # 80002a84 <argint>
    return -1;
    80005220:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005222:	02054763          	bltz	a0,80005250 <sys_read+0x5c>
    80005226:	fd840593          	addi	a1,s0,-40
    8000522a:	4505                	li	a0,1
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	87a080e7          	jalr	-1926(ra) # 80002aa6 <argaddr>
    return -1;
    80005234:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005236:	00054d63          	bltz	a0,80005250 <sys_read+0x5c>
  return fileread(f, p, n);
    8000523a:	fe442603          	lw	a2,-28(s0)
    8000523e:	fd843583          	ld	a1,-40(s0)
    80005242:	fe843503          	ld	a0,-24(s0)
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	490080e7          	jalr	1168(ra) # 800046d6 <fileread>
    8000524e:	87aa                	mv	a5,a0
}
    80005250:	853e                	mv	a0,a5
    80005252:	70a2                	ld	ra,40(sp)
    80005254:	7402                	ld	s0,32(sp)
    80005256:	6145                	addi	sp,sp,48
    80005258:	8082                	ret

000000008000525a <sys_write>:
{
    8000525a:	7179                	addi	sp,sp,-48
    8000525c:	f406                	sd	ra,40(sp)
    8000525e:	f022                	sd	s0,32(sp)
    80005260:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005262:	fe840613          	addi	a2,s0,-24
    80005266:	4581                	li	a1,0
    80005268:	4501                	li	a0,0
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	d2c080e7          	jalr	-724(ra) # 80004f96 <argfd>
    return -1;
    80005272:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005274:	04054163          	bltz	a0,800052b6 <sys_write+0x5c>
    80005278:	fe440593          	addi	a1,s0,-28
    8000527c:	4509                	li	a0,2
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	806080e7          	jalr	-2042(ra) # 80002a84 <argint>
    return -1;
    80005286:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005288:	02054763          	bltz	a0,800052b6 <sys_write+0x5c>
    8000528c:	fd840593          	addi	a1,s0,-40
    80005290:	4505                	li	a0,1
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	814080e7          	jalr	-2028(ra) # 80002aa6 <argaddr>
    return -1;
    8000529a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529c:	00054d63          	bltz	a0,800052b6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052a0:	fe442603          	lw	a2,-28(s0)
    800052a4:	fd843583          	ld	a1,-40(s0)
    800052a8:	fe843503          	ld	a0,-24(s0)
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	4ec080e7          	jalr	1260(ra) # 80004798 <filewrite>
    800052b4:	87aa                	mv	a5,a0
}
    800052b6:	853e                	mv	a0,a5
    800052b8:	70a2                	ld	ra,40(sp)
    800052ba:	7402                	ld	s0,32(sp)
    800052bc:	6145                	addi	sp,sp,48
    800052be:	8082                	ret

00000000800052c0 <sys_close>:
{
    800052c0:	1101                	addi	sp,sp,-32
    800052c2:	ec06                	sd	ra,24(sp)
    800052c4:	e822                	sd	s0,16(sp)
    800052c6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052c8:	fe040613          	addi	a2,s0,-32
    800052cc:	fec40593          	addi	a1,s0,-20
    800052d0:	4501                	li	a0,0
    800052d2:	00000097          	auipc	ra,0x0
    800052d6:	cc4080e7          	jalr	-828(ra) # 80004f96 <argfd>
    return -1;
    800052da:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052dc:	02054463          	bltz	a0,80005304 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	69e080e7          	jalr	1694(ra) # 8000197e <myproc>
    800052e8:	fec42783          	lw	a5,-20(s0)
    800052ec:	07e9                	addi	a5,a5,26
    800052ee:	078e                	slli	a5,a5,0x3
    800052f0:	97aa                	add	a5,a5,a0
    800052f2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052f6:	fe043503          	ld	a0,-32(s0)
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	2a2080e7          	jalr	674(ra) # 8000459c <fileclose>
  return 0;
    80005302:	4781                	li	a5,0
}
    80005304:	853e                	mv	a0,a5
    80005306:	60e2                	ld	ra,24(sp)
    80005308:	6442                	ld	s0,16(sp)
    8000530a:	6105                	addi	sp,sp,32
    8000530c:	8082                	ret

000000008000530e <sys_fstat>:
{
    8000530e:	1101                	addi	sp,sp,-32
    80005310:	ec06                	sd	ra,24(sp)
    80005312:	e822                	sd	s0,16(sp)
    80005314:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005316:	fe840613          	addi	a2,s0,-24
    8000531a:	4581                	li	a1,0
    8000531c:	4501                	li	a0,0
    8000531e:	00000097          	auipc	ra,0x0
    80005322:	c78080e7          	jalr	-904(ra) # 80004f96 <argfd>
    return -1;
    80005326:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005328:	02054563          	bltz	a0,80005352 <sys_fstat+0x44>
    8000532c:	fe040593          	addi	a1,s0,-32
    80005330:	4505                	li	a0,1
    80005332:	ffffd097          	auipc	ra,0xffffd
    80005336:	774080e7          	jalr	1908(ra) # 80002aa6 <argaddr>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000533c:	00054b63          	bltz	a0,80005352 <sys_fstat+0x44>
  return filestat(f, st);
    80005340:	fe043583          	ld	a1,-32(s0)
    80005344:	fe843503          	ld	a0,-24(s0)
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	31c080e7          	jalr	796(ra) # 80004664 <filestat>
    80005350:	87aa                	mv	a5,a0
}
    80005352:	853e                	mv	a0,a5
    80005354:	60e2                	ld	ra,24(sp)
    80005356:	6442                	ld	s0,16(sp)
    80005358:	6105                	addi	sp,sp,32
    8000535a:	8082                	ret

000000008000535c <sys_link>:
{
    8000535c:	7169                	addi	sp,sp,-304
    8000535e:	f606                	sd	ra,296(sp)
    80005360:	f222                	sd	s0,288(sp)
    80005362:	ee26                	sd	s1,280(sp)
    80005364:	ea4a                	sd	s2,272(sp)
    80005366:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005368:	08000613          	li	a2,128
    8000536c:	ed040593          	addi	a1,s0,-304
    80005370:	4501                	li	a0,0
    80005372:	ffffd097          	auipc	ra,0xffffd
    80005376:	756080e7          	jalr	1878(ra) # 80002ac8 <argstr>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000537c:	10054e63          	bltz	a0,80005498 <sys_link+0x13c>
    80005380:	08000613          	li	a2,128
    80005384:	f5040593          	addi	a1,s0,-176
    80005388:	4505                	li	a0,1
    8000538a:	ffffd097          	auipc	ra,0xffffd
    8000538e:	73e080e7          	jalr	1854(ra) # 80002ac8 <argstr>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005394:	10054263          	bltz	a0,80005498 <sys_link+0x13c>
  begin_op();
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	d38080e7          	jalr	-712(ra) # 800040d0 <begin_op>
  if((ip = namei(old)) == 0){
    800053a0:	ed040513          	addi	a0,s0,-304
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	b0c080e7          	jalr	-1268(ra) # 80003eb0 <namei>
    800053ac:	84aa                	mv	s1,a0
    800053ae:	c551                	beqz	a0,8000543a <sys_link+0xde>
  ilock(ip);
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	34a080e7          	jalr	842(ra) # 800036fa <ilock>
  if(ip->type == T_DIR){
    800053b8:	04449703          	lh	a4,68(s1)
    800053bc:	4785                	li	a5,1
    800053be:	08f70463          	beq	a4,a5,80005446 <sys_link+0xea>
  ip->nlink++;
    800053c2:	04a4d783          	lhu	a5,74(s1)
    800053c6:	2785                	addiw	a5,a5,1
    800053c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053cc:	8526                	mv	a0,s1
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	262080e7          	jalr	610(ra) # 80003630 <iupdate>
  iunlock(ip);
    800053d6:	8526                	mv	a0,s1
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	3e4080e7          	jalr	996(ra) # 800037bc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053e0:	fd040593          	addi	a1,s0,-48
    800053e4:	f5040513          	addi	a0,s0,-176
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	ae6080e7          	jalr	-1306(ra) # 80003ece <nameiparent>
    800053f0:	892a                	mv	s2,a0
    800053f2:	c935                	beqz	a0,80005466 <sys_link+0x10a>
  ilock(dp);
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	306080e7          	jalr	774(ra) # 800036fa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053fc:	00092703          	lw	a4,0(s2)
    80005400:	409c                	lw	a5,0(s1)
    80005402:	04f71d63          	bne	a4,a5,8000545c <sys_link+0x100>
    80005406:	40d0                	lw	a2,4(s1)
    80005408:	fd040593          	addi	a1,s0,-48
    8000540c:	854a                	mv	a0,s2
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	9e0080e7          	jalr	-1568(ra) # 80003dee <dirlink>
    80005416:	04054363          	bltz	a0,8000545c <sys_link+0x100>
  iunlockput(dp);
    8000541a:	854a                	mv	a0,s2
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	540080e7          	jalr	1344(ra) # 8000395c <iunlockput>
  iput(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	48e080e7          	jalr	1166(ra) # 800038b4 <iput>
  end_op();
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	d22080e7          	jalr	-734(ra) # 80004150 <end_op>
  return 0;
    80005436:	4781                	li	a5,0
    80005438:	a085                	j	80005498 <sys_link+0x13c>
    end_op();
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	d16080e7          	jalr	-746(ra) # 80004150 <end_op>
    return -1;
    80005442:	57fd                	li	a5,-1
    80005444:	a891                	j	80005498 <sys_link+0x13c>
    iunlockput(ip);
    80005446:	8526                	mv	a0,s1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	514080e7          	jalr	1300(ra) # 8000395c <iunlockput>
    end_op();
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	d00080e7          	jalr	-768(ra) # 80004150 <end_op>
    return -1;
    80005458:	57fd                	li	a5,-1
    8000545a:	a83d                	j	80005498 <sys_link+0x13c>
    iunlockput(dp);
    8000545c:	854a                	mv	a0,s2
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	4fe080e7          	jalr	1278(ra) # 8000395c <iunlockput>
  ilock(ip);
    80005466:	8526                	mv	a0,s1
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	292080e7          	jalr	658(ra) # 800036fa <ilock>
  ip->nlink--;
    80005470:	04a4d783          	lhu	a5,74(s1)
    80005474:	37fd                	addiw	a5,a5,-1
    80005476:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000547a:	8526                	mv	a0,s1
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	1b4080e7          	jalr	436(ra) # 80003630 <iupdate>
  iunlockput(ip);
    80005484:	8526                	mv	a0,s1
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	4d6080e7          	jalr	1238(ra) # 8000395c <iunlockput>
  end_op();
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	cc2080e7          	jalr	-830(ra) # 80004150 <end_op>
  return -1;
    80005496:	57fd                	li	a5,-1
}
    80005498:	853e                	mv	a0,a5
    8000549a:	70b2                	ld	ra,296(sp)
    8000549c:	7412                	ld	s0,288(sp)
    8000549e:	64f2                	ld	s1,280(sp)
    800054a0:	6952                	ld	s2,272(sp)
    800054a2:	6155                	addi	sp,sp,304
    800054a4:	8082                	ret

00000000800054a6 <sys_unlink>:
{
    800054a6:	7151                	addi	sp,sp,-240
    800054a8:	f586                	sd	ra,232(sp)
    800054aa:	f1a2                	sd	s0,224(sp)
    800054ac:	eda6                	sd	s1,216(sp)
    800054ae:	e9ca                	sd	s2,208(sp)
    800054b0:	e5ce                	sd	s3,200(sp)
    800054b2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054b4:	08000613          	li	a2,128
    800054b8:	f3040593          	addi	a1,s0,-208
    800054bc:	4501                	li	a0,0
    800054be:	ffffd097          	auipc	ra,0xffffd
    800054c2:	60a080e7          	jalr	1546(ra) # 80002ac8 <argstr>
    800054c6:	18054163          	bltz	a0,80005648 <sys_unlink+0x1a2>
  begin_op();
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	c06080e7          	jalr	-1018(ra) # 800040d0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054d2:	fb040593          	addi	a1,s0,-80
    800054d6:	f3040513          	addi	a0,s0,-208
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	9f4080e7          	jalr	-1548(ra) # 80003ece <nameiparent>
    800054e2:	84aa                	mv	s1,a0
    800054e4:	c979                	beqz	a0,800055ba <sys_unlink+0x114>
  ilock(dp);
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	214080e7          	jalr	532(ra) # 800036fa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054ee:	00003597          	auipc	a1,0x3
    800054f2:	2f258593          	addi	a1,a1,754 # 800087e0 <syscalls+0x2b0>
    800054f6:	fb040513          	addi	a0,s0,-80
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	6ca080e7          	jalr	1738(ra) # 80003bc4 <namecmp>
    80005502:	14050a63          	beqz	a0,80005656 <sys_unlink+0x1b0>
    80005506:	00003597          	auipc	a1,0x3
    8000550a:	2e258593          	addi	a1,a1,738 # 800087e8 <syscalls+0x2b8>
    8000550e:	fb040513          	addi	a0,s0,-80
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	6b2080e7          	jalr	1714(ra) # 80003bc4 <namecmp>
    8000551a:	12050e63          	beqz	a0,80005656 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000551e:	f2c40613          	addi	a2,s0,-212
    80005522:	fb040593          	addi	a1,s0,-80
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	6b6080e7          	jalr	1718(ra) # 80003bde <dirlookup>
    80005530:	892a                	mv	s2,a0
    80005532:	12050263          	beqz	a0,80005656 <sys_unlink+0x1b0>
  ilock(ip);
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	1c4080e7          	jalr	452(ra) # 800036fa <ilock>
  if(ip->nlink < 1)
    8000553e:	04a91783          	lh	a5,74(s2)
    80005542:	08f05263          	blez	a5,800055c6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005546:	04491703          	lh	a4,68(s2)
    8000554a:	4785                	li	a5,1
    8000554c:	08f70563          	beq	a4,a5,800055d6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005550:	4641                	li	a2,16
    80005552:	4581                	li	a1,0
    80005554:	fc040513          	addi	a0,s0,-64
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	766080e7          	jalr	1894(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005560:	4741                	li	a4,16
    80005562:	f2c42683          	lw	a3,-212(s0)
    80005566:	fc040613          	addi	a2,s0,-64
    8000556a:	4581                	li	a1,0
    8000556c:	8526                	mv	a0,s1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	538080e7          	jalr	1336(ra) # 80003aa6 <writei>
    80005576:	47c1                	li	a5,16
    80005578:	0af51563          	bne	a0,a5,80005622 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000557c:	04491703          	lh	a4,68(s2)
    80005580:	4785                	li	a5,1
    80005582:	0af70863          	beq	a4,a5,80005632 <sys_unlink+0x18c>
  iunlockput(dp);
    80005586:	8526                	mv	a0,s1
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	3d4080e7          	jalr	980(ra) # 8000395c <iunlockput>
  ip->nlink--;
    80005590:	04a95783          	lhu	a5,74(s2)
    80005594:	37fd                	addiw	a5,a5,-1
    80005596:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000559a:	854a                	mv	a0,s2
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	094080e7          	jalr	148(ra) # 80003630 <iupdate>
  iunlockput(ip);
    800055a4:	854a                	mv	a0,s2
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	3b6080e7          	jalr	950(ra) # 8000395c <iunlockput>
  end_op();
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	ba2080e7          	jalr	-1118(ra) # 80004150 <end_op>
  return 0;
    800055b6:	4501                	li	a0,0
    800055b8:	a84d                	j	8000566a <sys_unlink+0x1c4>
    end_op();
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	b96080e7          	jalr	-1130(ra) # 80004150 <end_op>
    return -1;
    800055c2:	557d                	li	a0,-1
    800055c4:	a05d                	j	8000566a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055c6:	00003517          	auipc	a0,0x3
    800055ca:	24a50513          	addi	a0,a0,586 # 80008810 <syscalls+0x2e0>
    800055ce:	ffffb097          	auipc	ra,0xffffb
    800055d2:	f5c080e7          	jalr	-164(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055d6:	04c92703          	lw	a4,76(s2)
    800055da:	02000793          	li	a5,32
    800055de:	f6e7f9e3          	bgeu	a5,a4,80005550 <sys_unlink+0xaa>
    800055e2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e6:	4741                	li	a4,16
    800055e8:	86ce                	mv	a3,s3
    800055ea:	f1840613          	addi	a2,s0,-232
    800055ee:	4581                	li	a1,0
    800055f0:	854a                	mv	a0,s2
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	3bc080e7          	jalr	956(ra) # 800039ae <readi>
    800055fa:	47c1                	li	a5,16
    800055fc:	00f51b63          	bne	a0,a5,80005612 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005600:	f1845783          	lhu	a5,-232(s0)
    80005604:	e7a1                	bnez	a5,8000564c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005606:	29c1                	addiw	s3,s3,16
    80005608:	04c92783          	lw	a5,76(s2)
    8000560c:	fcf9ede3          	bltu	s3,a5,800055e6 <sys_unlink+0x140>
    80005610:	b781                	j	80005550 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	21650513          	addi	a0,a0,534 # 80008828 <syscalls+0x2f8>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f10080e7          	jalr	-240(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005622:	00003517          	auipc	a0,0x3
    80005626:	21e50513          	addi	a0,a0,542 # 80008840 <syscalls+0x310>
    8000562a:	ffffb097          	auipc	ra,0xffffb
    8000562e:	f00080e7          	jalr	-256(ra) # 8000052a <panic>
    dp->nlink--;
    80005632:	04a4d783          	lhu	a5,74(s1)
    80005636:	37fd                	addiw	a5,a5,-1
    80005638:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	ff2080e7          	jalr	-14(ra) # 80003630 <iupdate>
    80005646:	b781                	j	80005586 <sys_unlink+0xe0>
    return -1;
    80005648:	557d                	li	a0,-1
    8000564a:	a005                	j	8000566a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	30e080e7          	jalr	782(ra) # 8000395c <iunlockput>
  iunlockput(dp);
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	304080e7          	jalr	772(ra) # 8000395c <iunlockput>
  end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	af0080e7          	jalr	-1296(ra) # 80004150 <end_op>
  return -1;
    80005668:	557d                	li	a0,-1
}
    8000566a:	70ae                	ld	ra,232(sp)
    8000566c:	740e                	ld	s0,224(sp)
    8000566e:	64ee                	ld	s1,216(sp)
    80005670:	694e                	ld	s2,208(sp)
    80005672:	69ae                	ld	s3,200(sp)
    80005674:	616d                	addi	sp,sp,240
    80005676:	8082                	ret

0000000080005678 <sys_open>:

uint64
sys_open(void)
{
    80005678:	7131                	addi	sp,sp,-192
    8000567a:	fd06                	sd	ra,184(sp)
    8000567c:	f922                	sd	s0,176(sp)
    8000567e:	f526                	sd	s1,168(sp)
    80005680:	f14a                	sd	s2,160(sp)
    80005682:	ed4e                	sd	s3,152(sp)
    80005684:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005686:	08000613          	li	a2,128
    8000568a:	f5040593          	addi	a1,s0,-176
    8000568e:	4501                	li	a0,0
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	438080e7          	jalr	1080(ra) # 80002ac8 <argstr>
    return -1;
    80005698:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000569a:	0c054163          	bltz	a0,8000575c <sys_open+0xe4>
    8000569e:	f4c40593          	addi	a1,s0,-180
    800056a2:	4505                	li	a0,1
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	3e0080e7          	jalr	992(ra) # 80002a84 <argint>
    800056ac:	0a054863          	bltz	a0,8000575c <sys_open+0xe4>

  begin_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	a20080e7          	jalr	-1504(ra) # 800040d0 <begin_op>

  if(omode & O_CREATE){
    800056b8:	f4c42783          	lw	a5,-180(s0)
    800056bc:	2007f793          	andi	a5,a5,512
    800056c0:	cbdd                	beqz	a5,80005776 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056c2:	4681                	li	a3,0
    800056c4:	4601                	li	a2,0
    800056c6:	4589                	li	a1,2
    800056c8:	f5040513          	addi	a0,s0,-176
    800056cc:	00000097          	auipc	ra,0x0
    800056d0:	974080e7          	jalr	-1676(ra) # 80005040 <create>
    800056d4:	892a                	mv	s2,a0
    if(ip == 0){
    800056d6:	c959                	beqz	a0,8000576c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056d8:	04491703          	lh	a4,68(s2)
    800056dc:	478d                	li	a5,3
    800056de:	00f71763          	bne	a4,a5,800056ec <sys_open+0x74>
    800056e2:	04695703          	lhu	a4,70(s2)
    800056e6:	47a5                	li	a5,9
    800056e8:	0ce7ec63          	bltu	a5,a4,800057c0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	df4080e7          	jalr	-524(ra) # 800044e0 <filealloc>
    800056f4:	89aa                	mv	s3,a0
    800056f6:	10050263          	beqz	a0,800057fa <sys_open+0x182>
    800056fa:	00000097          	auipc	ra,0x0
    800056fe:	904080e7          	jalr	-1788(ra) # 80004ffe <fdalloc>
    80005702:	84aa                	mv	s1,a0
    80005704:	0e054663          	bltz	a0,800057f0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005708:	04491703          	lh	a4,68(s2)
    8000570c:	478d                	li	a5,3
    8000570e:	0cf70463          	beq	a4,a5,800057d6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005712:	4789                	li	a5,2
    80005714:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005718:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000571c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005720:	f4c42783          	lw	a5,-180(s0)
    80005724:	0017c713          	xori	a4,a5,1
    80005728:	8b05                	andi	a4,a4,1
    8000572a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000572e:	0037f713          	andi	a4,a5,3
    80005732:	00e03733          	snez	a4,a4
    80005736:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000573a:	4007f793          	andi	a5,a5,1024
    8000573e:	c791                	beqz	a5,8000574a <sys_open+0xd2>
    80005740:	04491703          	lh	a4,68(s2)
    80005744:	4789                	li	a5,2
    80005746:	08f70f63          	beq	a4,a5,800057e4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	070080e7          	jalr	112(ra) # 800037bc <iunlock>
  end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	9fc080e7          	jalr	-1540(ra) # 80004150 <end_op>

  return fd;
}
    8000575c:	8526                	mv	a0,s1
    8000575e:	70ea                	ld	ra,184(sp)
    80005760:	744a                	ld	s0,176(sp)
    80005762:	74aa                	ld	s1,168(sp)
    80005764:	790a                	ld	s2,160(sp)
    80005766:	69ea                	ld	s3,152(sp)
    80005768:	6129                	addi	sp,sp,192
    8000576a:	8082                	ret
      end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	9e4080e7          	jalr	-1564(ra) # 80004150 <end_op>
      return -1;
    80005774:	b7e5                	j	8000575c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005776:	f5040513          	addi	a0,s0,-176
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	736080e7          	jalr	1846(ra) # 80003eb0 <namei>
    80005782:	892a                	mv	s2,a0
    80005784:	c905                	beqz	a0,800057b4 <sys_open+0x13c>
    ilock(ip);
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	f74080e7          	jalr	-140(ra) # 800036fa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000578e:	04491703          	lh	a4,68(s2)
    80005792:	4785                	li	a5,1
    80005794:	f4f712e3          	bne	a4,a5,800056d8 <sys_open+0x60>
    80005798:	f4c42783          	lw	a5,-180(s0)
    8000579c:	dba1                	beqz	a5,800056ec <sys_open+0x74>
      iunlockput(ip);
    8000579e:	854a                	mv	a0,s2
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	1bc080e7          	jalr	444(ra) # 8000395c <iunlockput>
      end_op();
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	9a8080e7          	jalr	-1624(ra) # 80004150 <end_op>
      return -1;
    800057b0:	54fd                	li	s1,-1
    800057b2:	b76d                	j	8000575c <sys_open+0xe4>
      end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	99c080e7          	jalr	-1636(ra) # 80004150 <end_op>
      return -1;
    800057bc:	54fd                	li	s1,-1
    800057be:	bf79                	j	8000575c <sys_open+0xe4>
    iunlockput(ip);
    800057c0:	854a                	mv	a0,s2
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	19a080e7          	jalr	410(ra) # 8000395c <iunlockput>
    end_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	986080e7          	jalr	-1658(ra) # 80004150 <end_op>
    return -1;
    800057d2:	54fd                	li	s1,-1
    800057d4:	b761                	j	8000575c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057d6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057da:	04691783          	lh	a5,70(s2)
    800057de:	02f99223          	sh	a5,36(s3)
    800057e2:	bf2d                	j	8000571c <sys_open+0xa4>
    itrunc(ip);
    800057e4:	854a                	mv	a0,s2
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	022080e7          	jalr	34(ra) # 80003808 <itrunc>
    800057ee:	bfb1                	j	8000574a <sys_open+0xd2>
      fileclose(f);
    800057f0:	854e                	mv	a0,s3
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	daa080e7          	jalr	-598(ra) # 8000459c <fileclose>
    iunlockput(ip);
    800057fa:	854a                	mv	a0,s2
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	160080e7          	jalr	352(ra) # 8000395c <iunlockput>
    end_op();
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	94c080e7          	jalr	-1716(ra) # 80004150 <end_op>
    return -1;
    8000580c:	54fd                	li	s1,-1
    8000580e:	b7b9                	j	8000575c <sys_open+0xe4>

0000000080005810 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005810:	7175                	addi	sp,sp,-144
    80005812:	e506                	sd	ra,136(sp)
    80005814:	e122                	sd	s0,128(sp)
    80005816:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	8b8080e7          	jalr	-1864(ra) # 800040d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005820:	08000613          	li	a2,128
    80005824:	f7040593          	addi	a1,s0,-144
    80005828:	4501                	li	a0,0
    8000582a:	ffffd097          	auipc	ra,0xffffd
    8000582e:	29e080e7          	jalr	670(ra) # 80002ac8 <argstr>
    80005832:	02054963          	bltz	a0,80005864 <sys_mkdir+0x54>
    80005836:	4681                	li	a3,0
    80005838:	4601                	li	a2,0
    8000583a:	4585                	li	a1,1
    8000583c:	f7040513          	addi	a0,s0,-144
    80005840:	00000097          	auipc	ra,0x0
    80005844:	800080e7          	jalr	-2048(ra) # 80005040 <create>
    80005848:	cd11                	beqz	a0,80005864 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	112080e7          	jalr	274(ra) # 8000395c <iunlockput>
  end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	8fe080e7          	jalr	-1794(ra) # 80004150 <end_op>
  return 0;
    8000585a:	4501                	li	a0,0
}
    8000585c:	60aa                	ld	ra,136(sp)
    8000585e:	640a                	ld	s0,128(sp)
    80005860:	6149                	addi	sp,sp,144
    80005862:	8082                	ret
    end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	8ec080e7          	jalr	-1812(ra) # 80004150 <end_op>
    return -1;
    8000586c:	557d                	li	a0,-1
    8000586e:	b7fd                	j	8000585c <sys_mkdir+0x4c>

0000000080005870 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005870:	7135                	addi	sp,sp,-160
    80005872:	ed06                	sd	ra,152(sp)
    80005874:	e922                	sd	s0,144(sp)
    80005876:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	858080e7          	jalr	-1960(ra) # 800040d0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005880:	08000613          	li	a2,128
    80005884:	f7040593          	addi	a1,s0,-144
    80005888:	4501                	li	a0,0
    8000588a:	ffffd097          	auipc	ra,0xffffd
    8000588e:	23e080e7          	jalr	574(ra) # 80002ac8 <argstr>
    80005892:	04054a63          	bltz	a0,800058e6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005896:	f6c40593          	addi	a1,s0,-148
    8000589a:	4505                	li	a0,1
    8000589c:	ffffd097          	auipc	ra,0xffffd
    800058a0:	1e8080e7          	jalr	488(ra) # 80002a84 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a4:	04054163          	bltz	a0,800058e6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058a8:	f6840593          	addi	a1,s0,-152
    800058ac:	4509                	li	a0,2
    800058ae:	ffffd097          	auipc	ra,0xffffd
    800058b2:	1d6080e7          	jalr	470(ra) # 80002a84 <argint>
     argint(1, &major) < 0 ||
    800058b6:	02054863          	bltz	a0,800058e6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058ba:	f6841683          	lh	a3,-152(s0)
    800058be:	f6c41603          	lh	a2,-148(s0)
    800058c2:	458d                	li	a1,3
    800058c4:	f7040513          	addi	a0,s0,-144
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	778080e7          	jalr	1912(ra) # 80005040 <create>
     argint(2, &minor) < 0 ||
    800058d0:	c919                	beqz	a0,800058e6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	08a080e7          	jalr	138(ra) # 8000395c <iunlockput>
  end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	876080e7          	jalr	-1930(ra) # 80004150 <end_op>
  return 0;
    800058e2:	4501                	li	a0,0
    800058e4:	a031                	j	800058f0 <sys_mknod+0x80>
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	86a080e7          	jalr	-1942(ra) # 80004150 <end_op>
    return -1;
    800058ee:	557d                	li	a0,-1
}
    800058f0:	60ea                	ld	ra,152(sp)
    800058f2:	644a                	ld	s0,144(sp)
    800058f4:	610d                	addi	sp,sp,160
    800058f6:	8082                	ret

00000000800058f8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058f8:	7135                	addi	sp,sp,-160
    800058fa:	ed06                	sd	ra,152(sp)
    800058fc:	e922                	sd	s0,144(sp)
    800058fe:	e526                	sd	s1,136(sp)
    80005900:	e14a                	sd	s2,128(sp)
    80005902:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005904:	ffffc097          	auipc	ra,0xffffc
    80005908:	07a080e7          	jalr	122(ra) # 8000197e <myproc>
    8000590c:	892a                	mv	s2,a0
  
  begin_op();
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	7c2080e7          	jalr	1986(ra) # 800040d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005916:	08000613          	li	a2,128
    8000591a:	f6040593          	addi	a1,s0,-160
    8000591e:	4501                	li	a0,0
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	1a8080e7          	jalr	424(ra) # 80002ac8 <argstr>
    80005928:	04054b63          	bltz	a0,8000597e <sys_chdir+0x86>
    8000592c:	f6040513          	addi	a0,s0,-160
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	580080e7          	jalr	1408(ra) # 80003eb0 <namei>
    80005938:	84aa                	mv	s1,a0
    8000593a:	c131                	beqz	a0,8000597e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	dbe080e7          	jalr	-578(ra) # 800036fa <ilock>
  if(ip->type != T_DIR){
    80005944:	04449703          	lh	a4,68(s1)
    80005948:	4785                	li	a5,1
    8000594a:	04f71063          	bne	a4,a5,8000598a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	e6c080e7          	jalr	-404(ra) # 800037bc <iunlock>
  iput(p->cwd);
    80005958:	15093503          	ld	a0,336(s2)
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	f58080e7          	jalr	-168(ra) # 800038b4 <iput>
  end_op();
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	7ec080e7          	jalr	2028(ra) # 80004150 <end_op>
  p->cwd = ip;
    8000596c:	14993823          	sd	s1,336(s2)
  return 0;
    80005970:	4501                	li	a0,0
}
    80005972:	60ea                	ld	ra,152(sp)
    80005974:	644a                	ld	s0,144(sp)
    80005976:	64aa                	ld	s1,136(sp)
    80005978:	690a                	ld	s2,128(sp)
    8000597a:	610d                	addi	sp,sp,160
    8000597c:	8082                	ret
    end_op();
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	7d2080e7          	jalr	2002(ra) # 80004150 <end_op>
    return -1;
    80005986:	557d                	li	a0,-1
    80005988:	b7ed                	j	80005972 <sys_chdir+0x7a>
    iunlockput(ip);
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	fd0080e7          	jalr	-48(ra) # 8000395c <iunlockput>
    end_op();
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	7bc080e7          	jalr	1980(ra) # 80004150 <end_op>
    return -1;
    8000599c:	557d                	li	a0,-1
    8000599e:	bfd1                	j	80005972 <sys_chdir+0x7a>

00000000800059a0 <sys_exec>:

uint64
sys_exec(void)
{
    800059a0:	7145                	addi	sp,sp,-464
    800059a2:	e786                	sd	ra,456(sp)
    800059a4:	e3a2                	sd	s0,448(sp)
    800059a6:	ff26                	sd	s1,440(sp)
    800059a8:	fb4a                	sd	s2,432(sp)
    800059aa:	f74e                	sd	s3,424(sp)
    800059ac:	f352                	sd	s4,416(sp)
    800059ae:	ef56                	sd	s5,408(sp)
    800059b0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059b2:	08000613          	li	a2,128
    800059b6:	f4040593          	addi	a1,s0,-192
    800059ba:	4501                	li	a0,0
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	10c080e7          	jalr	268(ra) # 80002ac8 <argstr>
    return -1;
    800059c4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059c6:	0c054a63          	bltz	a0,80005a9a <sys_exec+0xfa>
    800059ca:	e3840593          	addi	a1,s0,-456
    800059ce:	4505                	li	a0,1
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	0d6080e7          	jalr	214(ra) # 80002aa6 <argaddr>
    800059d8:	0c054163          	bltz	a0,80005a9a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059dc:	10000613          	li	a2,256
    800059e0:	4581                	li	a1,0
    800059e2:	e4040513          	addi	a0,s0,-448
    800059e6:	ffffb097          	auipc	ra,0xffffb
    800059ea:	2d8080e7          	jalr	728(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059ee:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059f2:	89a6                	mv	s3,s1
    800059f4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059f6:	02000a13          	li	s4,32
    800059fa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059fe:	00391793          	slli	a5,s2,0x3
    80005a02:	e3040593          	addi	a1,s0,-464
    80005a06:	e3843503          	ld	a0,-456(s0)
    80005a0a:	953e                	add	a0,a0,a5
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	fde080e7          	jalr	-34(ra) # 800029ea <fetchaddr>
    80005a14:	02054a63          	bltz	a0,80005a48 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a18:	e3043783          	ld	a5,-464(s0)
    80005a1c:	c3b9                	beqz	a5,80005a62 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a1e:	ffffb097          	auipc	ra,0xffffb
    80005a22:	0b4080e7          	jalr	180(ra) # 80000ad2 <kalloc>
    80005a26:	85aa                	mv	a1,a0
    80005a28:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a2c:	cd11                	beqz	a0,80005a48 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a2e:	6605                	lui	a2,0x1
    80005a30:	e3043503          	ld	a0,-464(s0)
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	008080e7          	jalr	8(ra) # 80002a3c <fetchstr>
    80005a3c:	00054663          	bltz	a0,80005a48 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a40:	0905                	addi	s2,s2,1
    80005a42:	09a1                	addi	s3,s3,8
    80005a44:	fb491be3          	bne	s2,s4,800059fa <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a48:	10048913          	addi	s2,s1,256
    80005a4c:	6088                	ld	a0,0(s1)
    80005a4e:	c529                	beqz	a0,80005a98 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a50:	ffffb097          	auipc	ra,0xffffb
    80005a54:	f86080e7          	jalr	-122(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a58:	04a1                	addi	s1,s1,8
    80005a5a:	ff2499e3          	bne	s1,s2,80005a4c <sys_exec+0xac>
  return -1;
    80005a5e:	597d                	li	s2,-1
    80005a60:	a82d                	j	80005a9a <sys_exec+0xfa>
      argv[i] = 0;
    80005a62:	0a8e                	slli	s5,s5,0x3
    80005a64:	fc040793          	addi	a5,s0,-64
    80005a68:	9abe                	add	s5,s5,a5
    80005a6a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005a6e:	e4040593          	addi	a1,s0,-448
    80005a72:	f4040513          	addi	a0,s0,-192
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	178080e7          	jalr	376(ra) # 80004bee <exec>
    80005a7e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a80:	10048993          	addi	s3,s1,256
    80005a84:	6088                	ld	a0,0(s1)
    80005a86:	c911                	beqz	a0,80005a9a <sys_exec+0xfa>
    kfree(argv[i]);
    80005a88:	ffffb097          	auipc	ra,0xffffb
    80005a8c:	f4e080e7          	jalr	-178(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a90:	04a1                	addi	s1,s1,8
    80005a92:	ff3499e3          	bne	s1,s3,80005a84 <sys_exec+0xe4>
    80005a96:	a011                	j	80005a9a <sys_exec+0xfa>
  return -1;
    80005a98:	597d                	li	s2,-1
}
    80005a9a:	854a                	mv	a0,s2
    80005a9c:	60be                	ld	ra,456(sp)
    80005a9e:	641e                	ld	s0,448(sp)
    80005aa0:	74fa                	ld	s1,440(sp)
    80005aa2:	795a                	ld	s2,432(sp)
    80005aa4:	79ba                	ld	s3,424(sp)
    80005aa6:	7a1a                	ld	s4,416(sp)
    80005aa8:	6afa                	ld	s5,408(sp)
    80005aaa:	6179                	addi	sp,sp,464
    80005aac:	8082                	ret

0000000080005aae <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aae:	7139                	addi	sp,sp,-64
    80005ab0:	fc06                	sd	ra,56(sp)
    80005ab2:	f822                	sd	s0,48(sp)
    80005ab4:	f426                	sd	s1,40(sp)
    80005ab6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ab8:	ffffc097          	auipc	ra,0xffffc
    80005abc:	ec6080e7          	jalr	-314(ra) # 8000197e <myproc>
    80005ac0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ac2:	fd840593          	addi	a1,s0,-40
    80005ac6:	4501                	li	a0,0
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	fde080e7          	jalr	-34(ra) # 80002aa6 <argaddr>
    return -1;
    80005ad0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ad2:	0e054063          	bltz	a0,80005bb2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ad6:	fc840593          	addi	a1,s0,-56
    80005ada:	fd040513          	addi	a0,s0,-48
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	dee080e7          	jalr	-530(ra) # 800048cc <pipealloc>
    return -1;
    80005ae6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ae8:	0c054563          	bltz	a0,80005bb2 <sys_pipe+0x104>
  fd0 = -1;
    80005aec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005af0:	fd043503          	ld	a0,-48(s0)
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	50a080e7          	jalr	1290(ra) # 80004ffe <fdalloc>
    80005afc:	fca42223          	sw	a0,-60(s0)
    80005b00:	08054c63          	bltz	a0,80005b98 <sys_pipe+0xea>
    80005b04:	fc843503          	ld	a0,-56(s0)
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	4f6080e7          	jalr	1270(ra) # 80004ffe <fdalloc>
    80005b10:	fca42023          	sw	a0,-64(s0)
    80005b14:	06054863          	bltz	a0,80005b84 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b18:	4691                	li	a3,4
    80005b1a:	fc440613          	addi	a2,s0,-60
    80005b1e:	fd843583          	ld	a1,-40(s0)
    80005b22:	68a8                	ld	a0,80(s1)
    80005b24:	ffffc097          	auipc	ra,0xffffc
    80005b28:	b1a080e7          	jalr	-1254(ra) # 8000163e <copyout>
    80005b2c:	02054063          	bltz	a0,80005b4c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b30:	4691                	li	a3,4
    80005b32:	fc040613          	addi	a2,s0,-64
    80005b36:	fd843583          	ld	a1,-40(s0)
    80005b3a:	0591                	addi	a1,a1,4
    80005b3c:	68a8                	ld	a0,80(s1)
    80005b3e:	ffffc097          	auipc	ra,0xffffc
    80005b42:	b00080e7          	jalr	-1280(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b46:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b48:	06055563          	bgez	a0,80005bb2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b4c:	fc442783          	lw	a5,-60(s0)
    80005b50:	07e9                	addi	a5,a5,26
    80005b52:	078e                	slli	a5,a5,0x3
    80005b54:	97a6                	add	a5,a5,s1
    80005b56:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b5a:	fc042503          	lw	a0,-64(s0)
    80005b5e:	0569                	addi	a0,a0,26
    80005b60:	050e                	slli	a0,a0,0x3
    80005b62:	9526                	add	a0,a0,s1
    80005b64:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b68:	fd043503          	ld	a0,-48(s0)
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	a30080e7          	jalr	-1488(ra) # 8000459c <fileclose>
    fileclose(wf);
    80005b74:	fc843503          	ld	a0,-56(s0)
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	a24080e7          	jalr	-1500(ra) # 8000459c <fileclose>
    return -1;
    80005b80:	57fd                	li	a5,-1
    80005b82:	a805                	j	80005bb2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b84:	fc442783          	lw	a5,-60(s0)
    80005b88:	0007c863          	bltz	a5,80005b98 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b8c:	01a78513          	addi	a0,a5,26
    80005b90:	050e                	slli	a0,a0,0x3
    80005b92:	9526                	add	a0,a0,s1
    80005b94:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b98:	fd043503          	ld	a0,-48(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	a00080e7          	jalr	-1536(ra) # 8000459c <fileclose>
    fileclose(wf);
    80005ba4:	fc843503          	ld	a0,-56(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	9f4080e7          	jalr	-1548(ra) # 8000459c <fileclose>
    return -1;
    80005bb0:	57fd                	li	a5,-1
}
    80005bb2:	853e                	mv	a0,a5
    80005bb4:	70e2                	ld	ra,56(sp)
    80005bb6:	7442                	ld	s0,48(sp)
    80005bb8:	74a2                	ld	s1,40(sp)
    80005bba:	6121                	addi	sp,sp,64
    80005bbc:	8082                	ret
	...

0000000080005bc0 <kernelvec>:
    80005bc0:	7111                	addi	sp,sp,-256
    80005bc2:	e006                	sd	ra,0(sp)
    80005bc4:	e40a                	sd	sp,8(sp)
    80005bc6:	e80e                	sd	gp,16(sp)
    80005bc8:	ec12                	sd	tp,24(sp)
    80005bca:	f016                	sd	t0,32(sp)
    80005bcc:	f41a                	sd	t1,40(sp)
    80005bce:	f81e                	sd	t2,48(sp)
    80005bd0:	fc22                	sd	s0,56(sp)
    80005bd2:	e0a6                	sd	s1,64(sp)
    80005bd4:	e4aa                	sd	a0,72(sp)
    80005bd6:	e8ae                	sd	a1,80(sp)
    80005bd8:	ecb2                	sd	a2,88(sp)
    80005bda:	f0b6                	sd	a3,96(sp)
    80005bdc:	f4ba                	sd	a4,104(sp)
    80005bde:	f8be                	sd	a5,112(sp)
    80005be0:	fcc2                	sd	a6,120(sp)
    80005be2:	e146                	sd	a7,128(sp)
    80005be4:	e54a                	sd	s2,136(sp)
    80005be6:	e94e                	sd	s3,144(sp)
    80005be8:	ed52                	sd	s4,152(sp)
    80005bea:	f156                	sd	s5,160(sp)
    80005bec:	f55a                	sd	s6,168(sp)
    80005bee:	f95e                	sd	s7,176(sp)
    80005bf0:	fd62                	sd	s8,184(sp)
    80005bf2:	e1e6                	sd	s9,192(sp)
    80005bf4:	e5ea                	sd	s10,200(sp)
    80005bf6:	e9ee                	sd	s11,208(sp)
    80005bf8:	edf2                	sd	t3,216(sp)
    80005bfa:	f1f6                	sd	t4,224(sp)
    80005bfc:	f5fa                	sd	t5,232(sp)
    80005bfe:	f9fe                	sd	t6,240(sp)
    80005c00:	cb7fc0ef          	jal	ra,800028b6 <kerneltrap>
    80005c04:	6082                	ld	ra,0(sp)
    80005c06:	6122                	ld	sp,8(sp)
    80005c08:	61c2                	ld	gp,16(sp)
    80005c0a:	7282                	ld	t0,32(sp)
    80005c0c:	7322                	ld	t1,40(sp)
    80005c0e:	73c2                	ld	t2,48(sp)
    80005c10:	7462                	ld	s0,56(sp)
    80005c12:	6486                	ld	s1,64(sp)
    80005c14:	6526                	ld	a0,72(sp)
    80005c16:	65c6                	ld	a1,80(sp)
    80005c18:	6666                	ld	a2,88(sp)
    80005c1a:	7686                	ld	a3,96(sp)
    80005c1c:	7726                	ld	a4,104(sp)
    80005c1e:	77c6                	ld	a5,112(sp)
    80005c20:	7866                	ld	a6,120(sp)
    80005c22:	688a                	ld	a7,128(sp)
    80005c24:	692a                	ld	s2,136(sp)
    80005c26:	69ca                	ld	s3,144(sp)
    80005c28:	6a6a                	ld	s4,152(sp)
    80005c2a:	7a8a                	ld	s5,160(sp)
    80005c2c:	7b2a                	ld	s6,168(sp)
    80005c2e:	7bca                	ld	s7,176(sp)
    80005c30:	7c6a                	ld	s8,184(sp)
    80005c32:	6c8e                	ld	s9,192(sp)
    80005c34:	6d2e                	ld	s10,200(sp)
    80005c36:	6dce                	ld	s11,208(sp)
    80005c38:	6e6e                	ld	t3,216(sp)
    80005c3a:	7e8e                	ld	t4,224(sp)
    80005c3c:	7f2e                	ld	t5,232(sp)
    80005c3e:	7fce                	ld	t6,240(sp)
    80005c40:	6111                	addi	sp,sp,256
    80005c42:	10200073          	sret
    80005c46:	00000013          	nop
    80005c4a:	00000013          	nop
    80005c4e:	0001                	nop

0000000080005c50 <timervec>:
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	e10c                	sd	a1,0(a0)
    80005c56:	e510                	sd	a2,8(a0)
    80005c58:	e914                	sd	a3,16(a0)
    80005c5a:	6d0c                	ld	a1,24(a0)
    80005c5c:	7110                	ld	a2,32(a0)
    80005c5e:	6194                	ld	a3,0(a1)
    80005c60:	96b2                	add	a3,a3,a2
    80005c62:	e194                	sd	a3,0(a1)
    80005c64:	4589                	li	a1,2
    80005c66:	14459073          	csrw	sip,a1
    80005c6a:	6914                	ld	a3,16(a0)
    80005c6c:	6510                	ld	a2,8(a0)
    80005c6e:	610c                	ld	a1,0(a0)
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	30200073          	mret
	...

0000000080005c7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c7a:	1141                	addi	sp,sp,-16
    80005c7c:	e422                	sd	s0,8(sp)
    80005c7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c80:	0c0007b7          	lui	a5,0xc000
    80005c84:	4705                	li	a4,1
    80005c86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c88:	c3d8                	sw	a4,4(a5)
}
    80005c8a:	6422                	ld	s0,8(sp)
    80005c8c:	0141                	addi	sp,sp,16
    80005c8e:	8082                	ret

0000000080005c90 <plicinithart>:

void
plicinithart(void)
{
    80005c90:	1141                	addi	sp,sp,-16
    80005c92:	e406                	sd	ra,8(sp)
    80005c94:	e022                	sd	s0,0(sp)
    80005c96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	cba080e7          	jalr	-838(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ca0:	0085171b          	slliw	a4,a0,0x8
    80005ca4:	0c0027b7          	lui	a5,0xc002
    80005ca8:	97ba                	add	a5,a5,a4
    80005caa:	40200713          	li	a4,1026
    80005cae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cb2:	00d5151b          	slliw	a0,a0,0xd
    80005cb6:	0c2017b7          	lui	a5,0xc201
    80005cba:	953e                	add	a0,a0,a5
    80005cbc:	00052023          	sw	zero,0(a0)
}
    80005cc0:	60a2                	ld	ra,8(sp)
    80005cc2:	6402                	ld	s0,0(sp)
    80005cc4:	0141                	addi	sp,sp,16
    80005cc6:	8082                	ret

0000000080005cc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cc8:	1141                	addi	sp,sp,-16
    80005cca:	e406                	sd	ra,8(sp)
    80005ccc:	e022                	sd	s0,0(sp)
    80005cce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	c82080e7          	jalr	-894(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cd8:	00d5179b          	slliw	a5,a0,0xd
    80005cdc:	0c201537          	lui	a0,0xc201
    80005ce0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ce2:	4148                	lw	a0,4(a0)
    80005ce4:	60a2                	ld	ra,8(sp)
    80005ce6:	6402                	ld	s0,0(sp)
    80005ce8:	0141                	addi	sp,sp,16
    80005cea:	8082                	ret

0000000080005cec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cec:	1101                	addi	sp,sp,-32
    80005cee:	ec06                	sd	ra,24(sp)
    80005cf0:	e822                	sd	s0,16(sp)
    80005cf2:	e426                	sd	s1,8(sp)
    80005cf4:	1000                	addi	s0,sp,32
    80005cf6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	c5a080e7          	jalr	-934(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d00:	00d5151b          	slliw	a0,a0,0xd
    80005d04:	0c2017b7          	lui	a5,0xc201
    80005d08:	97aa                	add	a5,a5,a0
    80005d0a:	c3c4                	sw	s1,4(a5)
}
    80005d0c:	60e2                	ld	ra,24(sp)
    80005d0e:	6442                	ld	s0,16(sp)
    80005d10:	64a2                	ld	s1,8(sp)
    80005d12:	6105                	addi	sp,sp,32
    80005d14:	8082                	ret

0000000080005d16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d16:	1141                	addi	sp,sp,-16
    80005d18:	e406                	sd	ra,8(sp)
    80005d1a:	e022                	sd	s0,0(sp)
    80005d1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d1e:	479d                	li	a5,7
    80005d20:	06a7c963          	blt	a5,a0,80005d92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d24:	0001d797          	auipc	a5,0x1d
    80005d28:	2dc78793          	addi	a5,a5,732 # 80023000 <disk>
    80005d2c:	00a78733          	add	a4,a5,a0
    80005d30:	6789                	lui	a5,0x2
    80005d32:	97ba                	add	a5,a5,a4
    80005d34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d38:	e7ad                	bnez	a5,80005da2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d3a:	00451793          	slli	a5,a0,0x4
    80005d3e:	0001f717          	auipc	a4,0x1f
    80005d42:	2c270713          	addi	a4,a4,706 # 80025000 <disk+0x2000>
    80005d46:	6314                	ld	a3,0(a4)
    80005d48:	96be                	add	a3,a3,a5
    80005d4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d4e:	6314                	ld	a3,0(a4)
    80005d50:	96be                	add	a3,a3,a5
    80005d52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d56:	6314                	ld	a3,0(a4)
    80005d58:	96be                	add	a3,a3,a5
    80005d5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d5e:	6318                	ld	a4,0(a4)
    80005d60:	97ba                	add	a5,a5,a4
    80005d62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d66:	0001d797          	auipc	a5,0x1d
    80005d6a:	29a78793          	addi	a5,a5,666 # 80023000 <disk>
    80005d6e:	97aa                	add	a5,a5,a0
    80005d70:	6509                	lui	a0,0x2
    80005d72:	953e                	add	a0,a0,a5
    80005d74:	4785                	li	a5,1
    80005d76:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d7a:	0001f517          	auipc	a0,0x1f
    80005d7e:	29e50513          	addi	a0,a0,670 # 80025018 <disk+0x2018>
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	454080e7          	jalr	1108(ra) # 800021d6 <wakeup>
}
    80005d8a:	60a2                	ld	ra,8(sp)
    80005d8c:	6402                	ld	s0,0(sp)
    80005d8e:	0141                	addi	sp,sp,16
    80005d90:	8082                	ret
    panic("free_desc 1");
    80005d92:	00003517          	auipc	a0,0x3
    80005d96:	abe50513          	addi	a0,a0,-1346 # 80008850 <syscalls+0x320>
    80005d9a:	ffffa097          	auipc	ra,0xffffa
    80005d9e:	790080e7          	jalr	1936(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005da2:	00003517          	auipc	a0,0x3
    80005da6:	abe50513          	addi	a0,a0,-1346 # 80008860 <syscalls+0x330>
    80005daa:	ffffa097          	auipc	ra,0xffffa
    80005dae:	780080e7          	jalr	1920(ra) # 8000052a <panic>

0000000080005db2 <virtio_disk_init>:
{
    80005db2:	1101                	addi	sp,sp,-32
    80005db4:	ec06                	sd	ra,24(sp)
    80005db6:	e822                	sd	s0,16(sp)
    80005db8:	e426                	sd	s1,8(sp)
    80005dba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dbc:	00003597          	auipc	a1,0x3
    80005dc0:	ab458593          	addi	a1,a1,-1356 # 80008870 <syscalls+0x340>
    80005dc4:	0001f517          	auipc	a0,0x1f
    80005dc8:	36450513          	addi	a0,a0,868 # 80025128 <disk+0x2128>
    80005dcc:	ffffb097          	auipc	ra,0xffffb
    80005dd0:	d66080e7          	jalr	-666(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dd4:	100017b7          	lui	a5,0x10001
    80005dd8:	4398                	lw	a4,0(a5)
    80005dda:	2701                	sext.w	a4,a4
    80005ddc:	747277b7          	lui	a5,0x74727
    80005de0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005de4:	0ef71163          	bne	a4,a5,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005de8:	100017b7          	lui	a5,0x10001
    80005dec:	43dc                	lw	a5,4(a5)
    80005dee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005df0:	4705                	li	a4,1
    80005df2:	0ce79a63          	bne	a5,a4,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005df6:	100017b7          	lui	a5,0x10001
    80005dfa:	479c                	lw	a5,8(a5)
    80005dfc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dfe:	4709                	li	a4,2
    80005e00:	0ce79363          	bne	a5,a4,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e04:	100017b7          	lui	a5,0x10001
    80005e08:	47d8                	lw	a4,12(a5)
    80005e0a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e0c:	554d47b7          	lui	a5,0x554d4
    80005e10:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e14:	0af71963          	bne	a4,a5,80005ec6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e18:	100017b7          	lui	a5,0x10001
    80005e1c:	4705                	li	a4,1
    80005e1e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e20:	470d                	li	a4,3
    80005e22:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e24:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e26:	c7ffe737          	lui	a4,0xc7ffe
    80005e2a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e2e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e30:	2701                	sext.w	a4,a4
    80005e32:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e34:	472d                	li	a4,11
    80005e36:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e38:	473d                	li	a4,15
    80005e3a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e3c:	6705                	lui	a4,0x1
    80005e3e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e44:	5bdc                	lw	a5,52(a5)
    80005e46:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e48:	c7d9                	beqz	a5,80005ed6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e4a:	471d                	li	a4,7
    80005e4c:	08f77d63          	bgeu	a4,a5,80005ee6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e50:	100014b7          	lui	s1,0x10001
    80005e54:	47a1                	li	a5,8
    80005e56:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e58:	6609                	lui	a2,0x2
    80005e5a:	4581                	li	a1,0
    80005e5c:	0001d517          	auipc	a0,0x1d
    80005e60:	1a450513          	addi	a0,a0,420 # 80023000 <disk>
    80005e64:	ffffb097          	auipc	ra,0xffffb
    80005e68:	e5a080e7          	jalr	-422(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e6c:	0001d717          	auipc	a4,0x1d
    80005e70:	19470713          	addi	a4,a4,404 # 80023000 <disk>
    80005e74:	00c75793          	srli	a5,a4,0xc
    80005e78:	2781                	sext.w	a5,a5
    80005e7a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e7c:	0001f797          	auipc	a5,0x1f
    80005e80:	18478793          	addi	a5,a5,388 # 80025000 <disk+0x2000>
    80005e84:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e86:	0001d717          	auipc	a4,0x1d
    80005e8a:	1fa70713          	addi	a4,a4,506 # 80023080 <disk+0x80>
    80005e8e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e90:	0001e717          	auipc	a4,0x1e
    80005e94:	17070713          	addi	a4,a4,368 # 80024000 <disk+0x1000>
    80005e98:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e9a:	4705                	li	a4,1
    80005e9c:	00e78c23          	sb	a4,24(a5)
    80005ea0:	00e78ca3          	sb	a4,25(a5)
    80005ea4:	00e78d23          	sb	a4,26(a5)
    80005ea8:	00e78da3          	sb	a4,27(a5)
    80005eac:	00e78e23          	sb	a4,28(a5)
    80005eb0:	00e78ea3          	sb	a4,29(a5)
    80005eb4:	00e78f23          	sb	a4,30(a5)
    80005eb8:	00e78fa3          	sb	a4,31(a5)
}
    80005ebc:	60e2                	ld	ra,24(sp)
    80005ebe:	6442                	ld	s0,16(sp)
    80005ec0:	64a2                	ld	s1,8(sp)
    80005ec2:	6105                	addi	sp,sp,32
    80005ec4:	8082                	ret
    panic("could not find virtio disk");
    80005ec6:	00003517          	auipc	a0,0x3
    80005eca:	9ba50513          	addi	a0,a0,-1606 # 80008880 <syscalls+0x350>
    80005ece:	ffffa097          	auipc	ra,0xffffa
    80005ed2:	65c080e7          	jalr	1628(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005ed6:	00003517          	auipc	a0,0x3
    80005eda:	9ca50513          	addi	a0,a0,-1590 # 800088a0 <syscalls+0x370>
    80005ede:	ffffa097          	auipc	ra,0xffffa
    80005ee2:	64c080e7          	jalr	1612(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005ee6:	00003517          	auipc	a0,0x3
    80005eea:	9da50513          	addi	a0,a0,-1574 # 800088c0 <syscalls+0x390>
    80005eee:	ffffa097          	auipc	ra,0xffffa
    80005ef2:	63c080e7          	jalr	1596(ra) # 8000052a <panic>

0000000080005ef6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ef6:	7119                	addi	sp,sp,-128
    80005ef8:	fc86                	sd	ra,120(sp)
    80005efa:	f8a2                	sd	s0,112(sp)
    80005efc:	f4a6                	sd	s1,104(sp)
    80005efe:	f0ca                	sd	s2,96(sp)
    80005f00:	ecce                	sd	s3,88(sp)
    80005f02:	e8d2                	sd	s4,80(sp)
    80005f04:	e4d6                	sd	s5,72(sp)
    80005f06:	e0da                	sd	s6,64(sp)
    80005f08:	fc5e                	sd	s7,56(sp)
    80005f0a:	f862                	sd	s8,48(sp)
    80005f0c:	f466                	sd	s9,40(sp)
    80005f0e:	f06a                	sd	s10,32(sp)
    80005f10:	ec6e                	sd	s11,24(sp)
    80005f12:	0100                	addi	s0,sp,128
    80005f14:	8aaa                	mv	s5,a0
    80005f16:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f18:	00c52c83          	lw	s9,12(a0)
    80005f1c:	001c9c9b          	slliw	s9,s9,0x1
    80005f20:	1c82                	slli	s9,s9,0x20
    80005f22:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f26:	0001f517          	auipc	a0,0x1f
    80005f2a:	20250513          	addi	a0,a0,514 # 80025128 <disk+0x2128>
    80005f2e:	ffffb097          	auipc	ra,0xffffb
    80005f32:	c94080e7          	jalr	-876(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005f36:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f38:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f3a:	0001dc17          	auipc	s8,0x1d
    80005f3e:	0c6c0c13          	addi	s8,s8,198 # 80023000 <disk>
    80005f42:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f44:	4b0d                	li	s6,3
    80005f46:	a0ad                	j	80005fb0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f48:	00fc0733          	add	a4,s8,a5
    80005f4c:	975e                	add	a4,a4,s7
    80005f4e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f52:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f54:	0207c563          	bltz	a5,80005f7e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f58:	2905                	addiw	s2,s2,1
    80005f5a:	0611                	addi	a2,a2,4
    80005f5c:	19690d63          	beq	s2,s6,800060f6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f60:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f62:	0001f717          	auipc	a4,0x1f
    80005f66:	0b670713          	addi	a4,a4,182 # 80025018 <disk+0x2018>
    80005f6a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f6c:	00074683          	lbu	a3,0(a4)
    80005f70:	fee1                	bnez	a3,80005f48 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f72:	2785                	addiw	a5,a5,1
    80005f74:	0705                	addi	a4,a4,1
    80005f76:	fe979be3          	bne	a5,s1,80005f6c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f7a:	57fd                	li	a5,-1
    80005f7c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f7e:	01205d63          	blez	s2,80005f98 <virtio_disk_rw+0xa2>
    80005f82:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f84:	000a2503          	lw	a0,0(s4)
    80005f88:	00000097          	auipc	ra,0x0
    80005f8c:	d8e080e7          	jalr	-626(ra) # 80005d16 <free_desc>
      for(int j = 0; j < i; j++)
    80005f90:	2d85                	addiw	s11,s11,1
    80005f92:	0a11                	addi	s4,s4,4
    80005f94:	ffb918e3          	bne	s2,s11,80005f84 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f98:	0001f597          	auipc	a1,0x1f
    80005f9c:	19058593          	addi	a1,a1,400 # 80025128 <disk+0x2128>
    80005fa0:	0001f517          	auipc	a0,0x1f
    80005fa4:	07850513          	addi	a0,a0,120 # 80025018 <disk+0x2018>
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	0a2080e7          	jalr	162(ra) # 8000204a <sleep>
  for(int i = 0; i < 3; i++){
    80005fb0:	f8040a13          	addi	s4,s0,-128
{
    80005fb4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fb6:	894e                	mv	s2,s3
    80005fb8:	b765                	j	80005f60 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fba:	0001f697          	auipc	a3,0x1f
    80005fbe:	0466b683          	ld	a3,70(a3) # 80025000 <disk+0x2000>
    80005fc2:	96ba                	add	a3,a3,a4
    80005fc4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fc8:	0001d817          	auipc	a6,0x1d
    80005fcc:	03880813          	addi	a6,a6,56 # 80023000 <disk>
    80005fd0:	0001f697          	auipc	a3,0x1f
    80005fd4:	03068693          	addi	a3,a3,48 # 80025000 <disk+0x2000>
    80005fd8:	6290                	ld	a2,0(a3)
    80005fda:	963a                	add	a2,a2,a4
    80005fdc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005fe0:	0015e593          	ori	a1,a1,1
    80005fe4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005fe8:	f8842603          	lw	a2,-120(s0)
    80005fec:	628c                	ld	a1,0(a3)
    80005fee:	972e                	add	a4,a4,a1
    80005ff0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005ff4:	20050593          	addi	a1,a0,512
    80005ff8:	0592                	slli	a1,a1,0x4
    80005ffa:	95c2                	add	a1,a1,a6
    80005ffc:	577d                	li	a4,-1
    80005ffe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006002:	00461713          	slli	a4,a2,0x4
    80006006:	6290                	ld	a2,0(a3)
    80006008:	963a                	add	a2,a2,a4
    8000600a:	03078793          	addi	a5,a5,48
    8000600e:	97c2                	add	a5,a5,a6
    80006010:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006012:	629c                	ld	a5,0(a3)
    80006014:	97ba                	add	a5,a5,a4
    80006016:	4605                	li	a2,1
    80006018:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000601a:	629c                	ld	a5,0(a3)
    8000601c:	97ba                	add	a5,a5,a4
    8000601e:	4809                	li	a6,2
    80006020:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006024:	629c                	ld	a5,0(a3)
    80006026:	973e                	add	a4,a4,a5
    80006028:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000602c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006030:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006034:	6698                	ld	a4,8(a3)
    80006036:	00275783          	lhu	a5,2(a4)
    8000603a:	8b9d                	andi	a5,a5,7
    8000603c:	0786                	slli	a5,a5,0x1
    8000603e:	97ba                	add	a5,a5,a4
    80006040:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006044:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006048:	6698                	ld	a4,8(a3)
    8000604a:	00275783          	lhu	a5,2(a4)
    8000604e:	2785                	addiw	a5,a5,1
    80006050:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006054:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006058:	100017b7          	lui	a5,0x10001
    8000605c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006060:	004aa783          	lw	a5,4(s5)
    80006064:	02c79163          	bne	a5,a2,80006086 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006068:	0001f917          	auipc	s2,0x1f
    8000606c:	0c090913          	addi	s2,s2,192 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006070:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006072:	85ca                	mv	a1,s2
    80006074:	8556                	mv	a0,s5
    80006076:	ffffc097          	auipc	ra,0xffffc
    8000607a:	fd4080e7          	jalr	-44(ra) # 8000204a <sleep>
  while(b->disk == 1) {
    8000607e:	004aa783          	lw	a5,4(s5)
    80006082:	fe9788e3          	beq	a5,s1,80006072 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006086:	f8042903          	lw	s2,-128(s0)
    8000608a:	20090793          	addi	a5,s2,512
    8000608e:	00479713          	slli	a4,a5,0x4
    80006092:	0001d797          	auipc	a5,0x1d
    80006096:	f6e78793          	addi	a5,a5,-146 # 80023000 <disk>
    8000609a:	97ba                	add	a5,a5,a4
    8000609c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060a0:	0001f997          	auipc	s3,0x1f
    800060a4:	f6098993          	addi	s3,s3,-160 # 80025000 <disk+0x2000>
    800060a8:	00491713          	slli	a4,s2,0x4
    800060ac:	0009b783          	ld	a5,0(s3)
    800060b0:	97ba                	add	a5,a5,a4
    800060b2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060b6:	854a                	mv	a0,s2
    800060b8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060bc:	00000097          	auipc	ra,0x0
    800060c0:	c5a080e7          	jalr	-934(ra) # 80005d16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060c4:	8885                	andi	s1,s1,1
    800060c6:	f0ed                	bnez	s1,800060a8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060c8:	0001f517          	auipc	a0,0x1f
    800060cc:	06050513          	addi	a0,a0,96 # 80025128 <disk+0x2128>
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	ba6080e7          	jalr	-1114(ra) # 80000c76 <release>
}
    800060d8:	70e6                	ld	ra,120(sp)
    800060da:	7446                	ld	s0,112(sp)
    800060dc:	74a6                	ld	s1,104(sp)
    800060de:	7906                	ld	s2,96(sp)
    800060e0:	69e6                	ld	s3,88(sp)
    800060e2:	6a46                	ld	s4,80(sp)
    800060e4:	6aa6                	ld	s5,72(sp)
    800060e6:	6b06                	ld	s6,64(sp)
    800060e8:	7be2                	ld	s7,56(sp)
    800060ea:	7c42                	ld	s8,48(sp)
    800060ec:	7ca2                	ld	s9,40(sp)
    800060ee:	7d02                	ld	s10,32(sp)
    800060f0:	6de2                	ld	s11,24(sp)
    800060f2:	6109                	addi	sp,sp,128
    800060f4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060f6:	f8042503          	lw	a0,-128(s0)
    800060fa:	20050793          	addi	a5,a0,512
    800060fe:	0792                	slli	a5,a5,0x4
  if(write)
    80006100:	0001d817          	auipc	a6,0x1d
    80006104:	f0080813          	addi	a6,a6,-256 # 80023000 <disk>
    80006108:	00f80733          	add	a4,a6,a5
    8000610c:	01a036b3          	snez	a3,s10
    80006110:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006114:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006118:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000611c:	7679                	lui	a2,0xffffe
    8000611e:	963e                	add	a2,a2,a5
    80006120:	0001f697          	auipc	a3,0x1f
    80006124:	ee068693          	addi	a3,a3,-288 # 80025000 <disk+0x2000>
    80006128:	6298                	ld	a4,0(a3)
    8000612a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000612c:	0a878593          	addi	a1,a5,168
    80006130:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006132:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006134:	6298                	ld	a4,0(a3)
    80006136:	9732                	add	a4,a4,a2
    80006138:	45c1                	li	a1,16
    8000613a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000613c:	6298                	ld	a4,0(a3)
    8000613e:	9732                	add	a4,a4,a2
    80006140:	4585                	li	a1,1
    80006142:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006146:	f8442703          	lw	a4,-124(s0)
    8000614a:	628c                	ld	a1,0(a3)
    8000614c:	962e                	add	a2,a2,a1
    8000614e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006152:	0712                	slli	a4,a4,0x4
    80006154:	6290                	ld	a2,0(a3)
    80006156:	963a                	add	a2,a2,a4
    80006158:	058a8593          	addi	a1,s5,88
    8000615c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000615e:	6294                	ld	a3,0(a3)
    80006160:	96ba                	add	a3,a3,a4
    80006162:	40000613          	li	a2,1024
    80006166:	c690                	sw	a2,8(a3)
  if(write)
    80006168:	e40d19e3          	bnez	s10,80005fba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000616c:	0001f697          	auipc	a3,0x1f
    80006170:	e946b683          	ld	a3,-364(a3) # 80025000 <disk+0x2000>
    80006174:	96ba                	add	a3,a3,a4
    80006176:	4609                	li	a2,2
    80006178:	00c69623          	sh	a2,12(a3)
    8000617c:	b5b1                	j	80005fc8 <virtio_disk_rw+0xd2>

000000008000617e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000617e:	1101                	addi	sp,sp,-32
    80006180:	ec06                	sd	ra,24(sp)
    80006182:	e822                	sd	s0,16(sp)
    80006184:	e426                	sd	s1,8(sp)
    80006186:	e04a                	sd	s2,0(sp)
    80006188:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000618a:	0001f517          	auipc	a0,0x1f
    8000618e:	f9e50513          	addi	a0,a0,-98 # 80025128 <disk+0x2128>
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	a30080e7          	jalr	-1488(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000619a:	10001737          	lui	a4,0x10001
    8000619e:	533c                	lw	a5,96(a4)
    800061a0:	8b8d                	andi	a5,a5,3
    800061a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061a8:	0001f797          	auipc	a5,0x1f
    800061ac:	e5878793          	addi	a5,a5,-424 # 80025000 <disk+0x2000>
    800061b0:	6b94                	ld	a3,16(a5)
    800061b2:	0207d703          	lhu	a4,32(a5)
    800061b6:	0026d783          	lhu	a5,2(a3)
    800061ba:	06f70163          	beq	a4,a5,8000621c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061be:	0001d917          	auipc	s2,0x1d
    800061c2:	e4290913          	addi	s2,s2,-446 # 80023000 <disk>
    800061c6:	0001f497          	auipc	s1,0x1f
    800061ca:	e3a48493          	addi	s1,s1,-454 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061ce:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061d2:	6898                	ld	a4,16(s1)
    800061d4:	0204d783          	lhu	a5,32(s1)
    800061d8:	8b9d                	andi	a5,a5,7
    800061da:	078e                	slli	a5,a5,0x3
    800061dc:	97ba                	add	a5,a5,a4
    800061de:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061e0:	20078713          	addi	a4,a5,512
    800061e4:	0712                	slli	a4,a4,0x4
    800061e6:	974a                	add	a4,a4,s2
    800061e8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061ec:	e731                	bnez	a4,80006238 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061ee:	20078793          	addi	a5,a5,512
    800061f2:	0792                	slli	a5,a5,0x4
    800061f4:	97ca                	add	a5,a5,s2
    800061f6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800061f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061fc:	ffffc097          	auipc	ra,0xffffc
    80006200:	fda080e7          	jalr	-38(ra) # 800021d6 <wakeup>

    disk.used_idx += 1;
    80006204:	0204d783          	lhu	a5,32(s1)
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	17c2                	slli	a5,a5,0x30
    8000620c:	93c1                	srli	a5,a5,0x30
    8000620e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006212:	6898                	ld	a4,16(s1)
    80006214:	00275703          	lhu	a4,2(a4)
    80006218:	faf71be3          	bne	a4,a5,800061ce <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000621c:	0001f517          	auipc	a0,0x1f
    80006220:	f0c50513          	addi	a0,a0,-244 # 80025128 <disk+0x2128>
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	a52080e7          	jalr	-1454(ra) # 80000c76 <release>
}
    8000622c:	60e2                	ld	ra,24(sp)
    8000622e:	6442                	ld	s0,16(sp)
    80006230:	64a2                	ld	s1,8(sp)
    80006232:	6902                	ld	s2,0(sp)
    80006234:	6105                	addi	sp,sp,32
    80006236:	8082                	ret
      panic("virtio_disk_intr status");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	6a850513          	addi	a0,a0,1704 # 800088e0 <syscalls+0x3b0>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	2ea080e7          	jalr	746(ra) # 8000052a <panic>
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
