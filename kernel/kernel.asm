
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
    80000068:	c8c78793          	addi	a5,a5,-884 # 80005cf0 <timervec>
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
    80000122:	2fe080e7          	jalr	766(ra) # 8000241c <either_copyin>
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
    800001c6:	e00080e7          	jalr	-512(ra) # 80001fc2 <sleep>
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
    80000202:	1c8080e7          	jalr	456(ra) # 800023c6 <either_copyout>
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
    800002e2:	194080e7          	jalr	404(ra) # 80002472 <procdump>
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
    80000436:	d1c080e7          	jalr	-740(ra) # 8000214e <wakeup>
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
    80000468:	0b478793          	addi	a5,a5,180 # 80021518 <devsw>
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
    80000882:	8d0080e7          	jalr	-1840(ra) # 8000214e <wakeup>
    
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
    8000090e:	6b8080e7          	jalr	1720(ra) # 80001fc2 <sleep>
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
    80000eb6:	7f0080e7          	jalr	2032(ra) # 800026a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	e76080e7          	jalr	-394(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	6d0080e7          	jalr	1744(ra) # 80002592 <scheduler>
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
    80000f2e:	750080e7          	jalr	1872(ra) # 8000267a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	770080e7          	jalr	1904(ra) # 800026a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	de0080e7          	jalr	-544(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	dee080e7          	jalr	-530(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	fbe080e7          	jalr	-66(ra) # 80002f08 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	650080e7          	jalr	1616(ra) # 800035a2 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	5fe080e7          	jalr	1534(ra) # 80004558 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	ef0080e7          	jalr	-272(ra) # 80005e52 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	cfe080e7          	jalr	-770(ra) # 80001c68 <userinit>
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
    80001840:	a94a0a13          	addi	s4,s4,-1388 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
    if(pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	8591                	srai	a1,a1,0x4
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
    80001876:	17048493          	addi	s1,s1,368
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
    80001908:	00016997          	auipc	s3,0x16
    8000190c:	9c898993          	addi	s3,s3,-1592 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	8791                	srai	a5,a5,0x4
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	17048493          	addi	s1,s1,368
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
    800019dc:	ce2080e7          	jalr	-798(ra) # 800026ba <usertrapret>
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
    800019f6:	b30080e7          	jalr	-1232(ra) # 80003522 <fsinit>
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
    80001a7e:	06093683          	ld	a3,96(s2)
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
    80001b3c:	7128                	ld	a0,96(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b48:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b4c:	6ca8                	ld	a0,88(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b50:	68ac                	ld	a1,80(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
  p->pagetable = 0;
    80001b5a:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b5e:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b66:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001b6a:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001b6e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b72:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b76:	0204a623          	sw	zero,44(s1)
  p->ctime = 0;
    80001b7a:	0204ac23          	sw	zero,56(s1)
  p->state = UNUSED;
    80001b7e:	0004ac23          	sw	zero,24(s1)
}
    80001b82:	60e2                	ld	ra,24(sp)
    80001b84:	6442                	ld	s0,16(sp)
    80001b86:	64a2                	ld	s1,8(sp)
    80001b88:	6105                	addi	sp,sp,32
    80001b8a:	8082                	ret

0000000080001b8c <allocproc>:
{
    80001b8c:	1101                	addi	sp,sp,-32
    80001b8e:	ec06                	sd	ra,24(sp)
    80001b90:	e822                	sd	s0,16(sp)
    80001b92:	e426                	sd	s1,8(sp)
    80001b94:	e04a                	sd	s2,0(sp)
    80001b96:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b98:	00010497          	auipc	s1,0x10
    80001b9c:	b3848493          	addi	s1,s1,-1224 # 800116d0 <proc>
    80001ba0:	00015917          	auipc	s2,0x15
    80001ba4:	73090913          	addi	s2,s2,1840 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001ba8:	8526                	mv	a0,s1
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	018080e7          	jalr	24(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bb2:	4c9c                	lw	a5,24(s1)
    80001bb4:	cf81                	beqz	a5,80001bcc <allocproc+0x40>
      release(&p->lock);
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	0be080e7          	jalr	190(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc0:	17048493          	addi	s1,s1,368
    80001bc4:	ff2492e3          	bne	s1,s2,80001ba8 <allocproc+0x1c>
  return 0;
    80001bc8:	4481                	li	s1,0
    80001bca:	a085                	j	80001c2a <allocproc+0x9e>
  p->pid = allocpid();
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	e30080e7          	jalr	-464(ra) # 800019fc <allocpid>
    80001bd4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bd6:	4785                	li	a5,1
    80001bd8:	cc9c                	sw	a5,24(s1)
  p->mask = 0;
    80001bda:	0204aa23          	sw	zero,52(s1)
  p->ctime = ticks;
    80001bde:	00007797          	auipc	a5,0x7
    80001be2:	4527a783          	lw	a5,1106(a5) # 80009030 <ticks>
    80001be6:	dc9c                	sw	a5,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	eea080e7          	jalr	-278(ra) # 80000ad2 <kalloc>
    80001bf0:	892a                	mv	s2,a0
    80001bf2:	f0a8                	sd	a0,96(s1)
    80001bf4:	c131                	beqz	a0,80001c38 <allocproc+0xac>
  p->pagetable = proc_pagetable(p);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	00000097          	auipc	ra,0x0
    80001bfc:	e4a080e7          	jalr	-438(ra) # 80001a42 <proc_pagetable>
    80001c00:	892a                	mv	s2,a0
    80001c02:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c04:	c531                	beqz	a0,80001c50 <allocproc+0xc4>
  memset(&p->context, 0, sizeof(p->context));
    80001c06:	07000613          	li	a2,112
    80001c0a:	4581                	li	a1,0
    80001c0c:	06848513          	addi	a0,s1,104
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	0ae080e7          	jalr	174(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c18:	00000797          	auipc	a5,0x0
    80001c1c:	d9e78793          	addi	a5,a5,-610 # 800019b6 <forkret>
    80001c20:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c22:	64bc                	ld	a5,72(s1)
    80001c24:	6705                	lui	a4,0x1
    80001c26:	97ba                	add	a5,a5,a4
    80001c28:	f8bc                	sd	a5,112(s1)
}
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	60e2                	ld	ra,24(sp)
    80001c2e:	6442                	ld	s0,16(sp)
    80001c30:	64a2                	ld	s1,8(sp)
    80001c32:	6902                	ld	s2,0(sp)
    80001c34:	6105                	addi	sp,sp,32
    80001c36:	8082                	ret
    freeproc(p);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	ef6080e7          	jalr	-266(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	032080e7          	jalr	50(ra) # 80000c76 <release>
    return 0;
    80001c4c:	84ca                	mv	s1,s2
    80001c4e:	bff1                	j	80001c2a <allocproc+0x9e>
    freeproc(p);
    80001c50:	8526                	mv	a0,s1
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	ede080e7          	jalr	-290(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	01a080e7          	jalr	26(ra) # 80000c76 <release>
    return 0;
    80001c64:	84ca                	mv	s1,s2
    80001c66:	b7d1                	j	80001c2a <allocproc+0x9e>

0000000080001c68 <userinit>:
{
    80001c68:	1101                	addi	sp,sp,-32
    80001c6a:	ec06                	sd	ra,24(sp)
    80001c6c:	e822                	sd	s0,16(sp)
    80001c6e:	e426                	sd	s1,8(sp)
    80001c70:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	f1a080e7          	jalr	-230(ra) # 80001b8c <allocproc>
    80001c7a:	84aa                	mv	s1,a0
  initproc = p;
    80001c7c:	00007797          	auipc	a5,0x7
    80001c80:	3aa7b623          	sd	a0,940(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c84:	03400613          	li	a2,52
    80001c88:	00007597          	auipc	a1,0x7
    80001c8c:	c8858593          	addi	a1,a1,-888 # 80008910 <initcode>
    80001c90:	6d28                	ld	a0,88(a0)
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	6a2080e7          	jalr	1698(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001c9a:	6785                	lui	a5,0x1
    80001c9c:	e8bc                	sd	a5,80(s1)
  p->ctime = ticks;
    80001c9e:	00007717          	auipc	a4,0x7
    80001ca2:	39272703          	lw	a4,914(a4) # 80009030 <ticks>
    80001ca6:	dc98                	sw	a4,56(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca8:	70b8                	ld	a4,96(s1)
    80001caa:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cae:	70b8                	ld	a4,96(s1)
    80001cb0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cb2:	4641                	li	a2,16
    80001cb4:	00006597          	auipc	a1,0x6
    80001cb8:	53458593          	addi	a1,a1,1332 # 800081e8 <digits+0x1a8>
    80001cbc:	16048513          	addi	a0,s1,352
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	150080e7          	jalr	336(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	53050513          	addi	a0,a0,1328 # 800081f8 <digits+0x1b8>
    80001cd0:	00002097          	auipc	ra,0x2
    80001cd4:	280080e7          	jalr	640(ra) # 80003f50 <namei>
    80001cd8:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001cdc:	478d                	li	a5,3
    80001cde:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	f94080e7          	jalr	-108(ra) # 80000c76 <release>
}
    80001cea:	60e2                	ld	ra,24(sp)
    80001cec:	6442                	ld	s0,16(sp)
    80001cee:	64a2                	ld	s1,8(sp)
    80001cf0:	6105                	addi	sp,sp,32
    80001cf2:	8082                	ret

0000000080001cf4 <growproc>:
{
    80001cf4:	1101                	addi	sp,sp,-32
    80001cf6:	ec06                	sd	ra,24(sp)
    80001cf8:	e822                	sd	s0,16(sp)
    80001cfa:	e426                	sd	s1,8(sp)
    80001cfc:	e04a                	sd	s2,0(sp)
    80001cfe:	1000                	addi	s0,sp,32
    80001d00:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d02:	00000097          	auipc	ra,0x0
    80001d06:	c7c080e7          	jalr	-900(ra) # 8000197e <myproc>
    80001d0a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d0c:	692c                	ld	a1,80(a0)
    80001d0e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d12:	00904f63          	bgtz	s1,80001d30 <growproc+0x3c>
  } else if(n < 0){
    80001d16:	0204cc63          	bltz	s1,80001d4e <growproc+0x5a>
  p->sz = sz;
    80001d1a:	1602                	slli	a2,a2,0x20
    80001d1c:	9201                	srli	a2,a2,0x20
    80001d1e:	04c93823          	sd	a2,80(s2)
  return 0;
    80001d22:	4501                	li	a0,0
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6902                	ld	s2,0(sp)
    80001d2c:	6105                	addi	sp,sp,32
    80001d2e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d30:	9e25                	addw	a2,a2,s1
    80001d32:	1602                	slli	a2,a2,0x20
    80001d34:	9201                	srli	a2,a2,0x20
    80001d36:	1582                	slli	a1,a1,0x20
    80001d38:	9181                	srli	a1,a1,0x20
    80001d3a:	6d28                	ld	a0,88(a0)
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	6b2080e7          	jalr	1714(ra) # 800013ee <uvmalloc>
    80001d44:	0005061b          	sext.w	a2,a0
    80001d48:	fa69                	bnez	a2,80001d1a <growproc+0x26>
      return -1;
    80001d4a:	557d                	li	a0,-1
    80001d4c:	bfe1                	j	80001d24 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4e:	9e25                	addw	a2,a2,s1
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	1582                	slli	a1,a1,0x20
    80001d56:	9181                	srli	a1,a1,0x20
    80001d58:	6d28                	ld	a0,88(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	64c080e7          	jalr	1612(ra) # 800013a6 <uvmdealloc>
    80001d62:	0005061b          	sext.w	a2,a0
    80001d66:	bf55                	j	80001d1a <growproc+0x26>

0000000080001d68 <fork>:
{
    80001d68:	7139                	addi	sp,sp,-64
    80001d6a:	fc06                	sd	ra,56(sp)
    80001d6c:	f822                	sd	s0,48(sp)
    80001d6e:	f426                	sd	s1,40(sp)
    80001d70:	f04a                	sd	s2,32(sp)
    80001d72:	ec4e                	sd	s3,24(sp)
    80001d74:	e852                	sd	s4,16(sp)
    80001d76:	e456                	sd	s5,8(sp)
    80001d78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	c04080e7          	jalr	-1020(ra) # 8000197e <myproc>
    80001d82:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	e08080e7          	jalr	-504(ra) # 80001b8c <allocproc>
    80001d8c:	12050063          	beqz	a0,80001eac <fork+0x144>
    80001d90:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d92:	050ab603          	ld	a2,80(s5)
    80001d96:	6d2c                	ld	a1,88(a0)
    80001d98:	058ab503          	ld	a0,88(s5)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	79e080e7          	jalr	1950(ra) # 8000153a <uvmcopy>
    80001da4:	04054c63          	bltz	a0,80001dfc <fork+0x94>
  np->sz = p->sz;
    80001da8:	050ab783          	ld	a5,80(s5)
    80001dac:	04f9b823          	sd	a5,80(s3)
  np->mask = p->mask;
    80001db0:	034aa783          	lw	a5,52(s5)
    80001db4:	02f9aa23          	sw	a5,52(s3)
  *(np->trapframe) = *(p->trapframe);
    80001db8:	060ab683          	ld	a3,96(s5)
    80001dbc:	87b6                	mv	a5,a3
    80001dbe:	0609b703          	ld	a4,96(s3)
    80001dc2:	12068693          	addi	a3,a3,288
    80001dc6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dca:	6788                	ld	a0,8(a5)
    80001dcc:	6b8c                	ld	a1,16(a5)
    80001dce:	6f90                	ld	a2,24(a5)
    80001dd0:	01073023          	sd	a6,0(a4)
    80001dd4:	e708                	sd	a0,8(a4)
    80001dd6:	eb0c                	sd	a1,16(a4)
    80001dd8:	ef10                	sd	a2,24(a4)
    80001dda:	02078793          	addi	a5,a5,32
    80001dde:	02070713          	addi	a4,a4,32
    80001de2:	fed792e3          	bne	a5,a3,80001dc6 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001de6:	0609b783          	ld	a5,96(s3)
    80001dea:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dee:	0d8a8493          	addi	s1,s5,216
    80001df2:	0d898913          	addi	s2,s3,216
    80001df6:	158a8a13          	addi	s4,s5,344
    80001dfa:	a00d                	j	80001e1c <fork+0xb4>
    freeproc(np);
    80001dfc:	854e                	mv	a0,s3
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	d32080e7          	jalr	-718(ra) # 80001b30 <freeproc>
    release(&np->lock);
    80001e06:	854e                	mv	a0,s3
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e6e080e7          	jalr	-402(ra) # 80000c76 <release>
    return -1;
    80001e10:	597d                	li	s2,-1
    80001e12:	a059                	j	80001e98 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001e14:	04a1                	addi	s1,s1,8
    80001e16:	0921                	addi	s2,s2,8
    80001e18:	01448b63          	beq	s1,s4,80001e2e <fork+0xc6>
    if(p->ofile[i])
    80001e1c:	6088                	ld	a0,0(s1)
    80001e1e:	d97d                	beqz	a0,80001e14 <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e20:	00002097          	auipc	ra,0x2
    80001e24:	7ca080e7          	jalr	1994(ra) # 800045ea <filedup>
    80001e28:	00a93023          	sd	a0,0(s2)
    80001e2c:	b7e5                	j	80001e14 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e2e:	158ab503          	ld	a0,344(s5)
    80001e32:	00002097          	auipc	ra,0x2
    80001e36:	92a080e7          	jalr	-1750(ra) # 8000375c <idup>
    80001e3a:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e3e:	4641                	li	a2,16
    80001e40:	160a8593          	addi	a1,s5,352
    80001e44:	16098513          	addi	a0,s3,352
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	fc8080e7          	jalr	-56(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e50:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e54:	854e                	mv	a0,s3
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e20080e7          	jalr	-480(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e5e:	0000f497          	auipc	s1,0xf
    80001e62:	45a48493          	addi	s1,s1,1114 # 800112b8 <wait_lock>
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	d5a080e7          	jalr	-678(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e70:	0559b023          	sd	s5,64(s3)
  release(&wait_lock);
    80001e74:	8526                	mv	a0,s1
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e00080e7          	jalr	-512(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	d42080e7          	jalr	-702(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e88:	478d                	li	a5,3
    80001e8a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e8e:	854e                	mv	a0,s3
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	de6080e7          	jalr	-538(ra) # 80000c76 <release>
}
    80001e98:	854a                	mv	a0,s2
    80001e9a:	70e2                	ld	ra,56(sp)
    80001e9c:	7442                	ld	s0,48(sp)
    80001e9e:	74a2                	ld	s1,40(sp)
    80001ea0:	7902                	ld	s2,32(sp)
    80001ea2:	69e2                	ld	s3,24(sp)
    80001ea4:	6a42                	ld	s4,16(sp)
    80001ea6:	6aa2                	ld	s5,8(sp)
    80001ea8:	6121                	addi	sp,sp,64
    80001eaa:	8082                	ret
    return -1;
    80001eac:	597d                	li	s2,-1
    80001eae:	b7ed                	j	80001e98 <fork+0x130>

0000000080001eb0 <sched>:
{
    80001eb0:	7179                	addi	sp,sp,-48
    80001eb2:	f406                	sd	ra,40(sp)
    80001eb4:	f022                	sd	s0,32(sp)
    80001eb6:	ec26                	sd	s1,24(sp)
    80001eb8:	e84a                	sd	s2,16(sp)
    80001eba:	e44e                	sd	s3,8(sp)
    80001ebc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ebe:	00000097          	auipc	ra,0x0
    80001ec2:	ac0080e7          	jalr	-1344(ra) # 8000197e <myproc>
    80001ec6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	c80080e7          	jalr	-896(ra) # 80000b48 <holding>
    80001ed0:	c93d                	beqz	a0,80001f46 <sched+0x96>
    80001ed2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ed4:	2781                	sext.w	a5,a5
    80001ed6:	079e                	slli	a5,a5,0x7
    80001ed8:	0000f717          	auipc	a4,0xf
    80001edc:	3c870713          	addi	a4,a4,968 # 800112a0 <pid_lock>
    80001ee0:	97ba                	add	a5,a5,a4
    80001ee2:	0a87a703          	lw	a4,168(a5)
    80001ee6:	4785                	li	a5,1
    80001ee8:	06f71763          	bne	a4,a5,80001f56 <sched+0xa6>
  if(p->state == RUNNING)
    80001eec:	4c98                	lw	a4,24(s1)
    80001eee:	4791                	li	a5,4
    80001ef0:	06f70b63          	beq	a4,a5,80001f66 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ef8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001efa:	efb5                	bnez	a5,80001f76 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001efc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001efe:	0000f917          	auipc	s2,0xf
    80001f02:	3a290913          	addi	s2,s2,930 # 800112a0 <pid_lock>
    80001f06:	2781                	sext.w	a5,a5
    80001f08:	079e                	slli	a5,a5,0x7
    80001f0a:	97ca                	add	a5,a5,s2
    80001f0c:	0ac7a983          	lw	s3,172(a5)
    80001f10:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f12:	2781                	sext.w	a5,a5
    80001f14:	079e                	slli	a5,a5,0x7
    80001f16:	0000f597          	auipc	a1,0xf
    80001f1a:	3c258593          	addi	a1,a1,962 # 800112d8 <cpus+0x8>
    80001f1e:	95be                	add	a1,a1,a5
    80001f20:	06848513          	addi	a0,s1,104
    80001f24:	00000097          	auipc	ra,0x0
    80001f28:	6ec080e7          	jalr	1772(ra) # 80002610 <swtch>
    80001f2c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f2e:	2781                	sext.w	a5,a5
    80001f30:	079e                	slli	a5,a5,0x7
    80001f32:	97ca                	add	a5,a5,s2
    80001f34:	0b37a623          	sw	s3,172(a5)
}
    80001f38:	70a2                	ld	ra,40(sp)
    80001f3a:	7402                	ld	s0,32(sp)
    80001f3c:	64e2                	ld	s1,24(sp)
    80001f3e:	6942                	ld	s2,16(sp)
    80001f40:	69a2                	ld	s3,8(sp)
    80001f42:	6145                	addi	sp,sp,48
    80001f44:	8082                	ret
    panic("sched p->lock");
    80001f46:	00006517          	auipc	a0,0x6
    80001f4a:	2ba50513          	addi	a0,a0,698 # 80008200 <digits+0x1c0>
    80001f4e:	ffffe097          	auipc	ra,0xffffe
    80001f52:	5dc080e7          	jalr	1500(ra) # 8000052a <panic>
    panic("sched locks");
    80001f56:	00006517          	auipc	a0,0x6
    80001f5a:	2ba50513          	addi	a0,a0,698 # 80008210 <digits+0x1d0>
    80001f5e:	ffffe097          	auipc	ra,0xffffe
    80001f62:	5cc080e7          	jalr	1484(ra) # 8000052a <panic>
    panic("sched running");
    80001f66:	00006517          	auipc	a0,0x6
    80001f6a:	2ba50513          	addi	a0,a0,698 # 80008220 <digits+0x1e0>
    80001f6e:	ffffe097          	auipc	ra,0xffffe
    80001f72:	5bc080e7          	jalr	1468(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001f76:	00006517          	auipc	a0,0x6
    80001f7a:	2ba50513          	addi	a0,a0,698 # 80008230 <digits+0x1f0>
    80001f7e:	ffffe097          	auipc	ra,0xffffe
    80001f82:	5ac080e7          	jalr	1452(ra) # 8000052a <panic>

0000000080001f86 <yield>:
{
    80001f86:	1101                	addi	sp,sp,-32
    80001f88:	ec06                	sd	ra,24(sp)
    80001f8a:	e822                	sd	s0,16(sp)
    80001f8c:	e426                	sd	s1,8(sp)
    80001f8e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	9ee080e7          	jalr	-1554(ra) # 8000197e <myproc>
    80001f98:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	c28080e7          	jalr	-984(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80001fa2:	478d                	li	a5,3
    80001fa4:	cc9c                	sw	a5,24(s1)
  sched();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	f0a080e7          	jalr	-246(ra) # 80001eb0 <sched>
  release(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	cc6080e7          	jalr	-826(ra) # 80000c76 <release>
}
    80001fb8:	60e2                	ld	ra,24(sp)
    80001fba:	6442                	ld	s0,16(sp)
    80001fbc:	64a2                	ld	s1,8(sp)
    80001fbe:	6105                	addi	sp,sp,32
    80001fc0:	8082                	ret

0000000080001fc2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001fc2:	7179                	addi	sp,sp,-48
    80001fc4:	f406                	sd	ra,40(sp)
    80001fc6:	f022                	sd	s0,32(sp)
    80001fc8:	ec26                	sd	s1,24(sp)
    80001fca:	e84a                	sd	s2,16(sp)
    80001fcc:	e44e                	sd	s3,8(sp)
    80001fce:	1800                	addi	s0,sp,48
    80001fd0:	89aa                	mv	s3,a0
    80001fd2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	9aa080e7          	jalr	-1622(ra) # 8000197e <myproc>
    80001fdc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	be4080e7          	jalr	-1052(ra) # 80000bc2 <acquire>
  release(lk);
    80001fe6:	854a                	mv	a0,s2
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	c8e080e7          	jalr	-882(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80001ff0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001ff4:	4789                	li	a5,2
    80001ff6:	cc9c                	sw	a5,24(s1)

  sched();
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	eb8080e7          	jalr	-328(ra) # 80001eb0 <sched>

  // Tidy up.
  p->chan = 0;
    80002000:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	c70080e7          	jalr	-912(ra) # 80000c76 <release>
  acquire(lk);
    8000200e:	854a                	mv	a0,s2
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	bb2080e7          	jalr	-1102(ra) # 80000bc2 <acquire>
}
    80002018:	70a2                	ld	ra,40(sp)
    8000201a:	7402                	ld	s0,32(sp)
    8000201c:	64e2                	ld	s1,24(sp)
    8000201e:	6942                	ld	s2,16(sp)
    80002020:	69a2                	ld	s3,8(sp)
    80002022:	6145                	addi	sp,sp,48
    80002024:	8082                	ret

0000000080002026 <wait>:
{
    80002026:	715d                	addi	sp,sp,-80
    80002028:	e486                	sd	ra,72(sp)
    8000202a:	e0a2                	sd	s0,64(sp)
    8000202c:	fc26                	sd	s1,56(sp)
    8000202e:	f84a                	sd	s2,48(sp)
    80002030:	f44e                	sd	s3,40(sp)
    80002032:	f052                	sd	s4,32(sp)
    80002034:	ec56                	sd	s5,24(sp)
    80002036:	e85a                	sd	s6,16(sp)
    80002038:	e45e                	sd	s7,8(sp)
    8000203a:	e062                	sd	s8,0(sp)
    8000203c:	0880                	addi	s0,sp,80
    8000203e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002040:	00000097          	auipc	ra,0x0
    80002044:	93e080e7          	jalr	-1730(ra) # 8000197e <myproc>
    80002048:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000204a:	0000f517          	auipc	a0,0xf
    8000204e:	26e50513          	addi	a0,a0,622 # 800112b8 <wait_lock>
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	b70080e7          	jalr	-1168(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000205a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000205c:	4a15                	li	s4,5
        havekids = 1;
    8000205e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002060:	00015997          	auipc	s3,0x15
    80002064:	27098993          	addi	s3,s3,624 # 800172d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002068:	0000fc17          	auipc	s8,0xf
    8000206c:	250c0c13          	addi	s8,s8,592 # 800112b8 <wait_lock>
    havekids = 0;
    80002070:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002072:	0000f497          	auipc	s1,0xf
    80002076:	65e48493          	addi	s1,s1,1630 # 800116d0 <proc>
    8000207a:	a0bd                	j	800020e8 <wait+0xc2>
          pid = np->pid;
    8000207c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002080:	000b0e63          	beqz	s6,8000209c <wait+0x76>
    80002084:	4691                	li	a3,4
    80002086:	02c48613          	addi	a2,s1,44
    8000208a:	85da                	mv	a1,s6
    8000208c:	05893503          	ld	a0,88(s2)
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	5ae080e7          	jalr	1454(ra) # 8000163e <copyout>
    80002098:	02054563          	bltz	a0,800020c2 <wait+0x9c>
          freeproc(np);
    8000209c:	8526                	mv	a0,s1
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	a92080e7          	jalr	-1390(ra) # 80001b30 <freeproc>
          release(&np->lock);
    800020a6:	8526                	mv	a0,s1
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	bce080e7          	jalr	-1074(ra) # 80000c76 <release>
          release(&wait_lock);
    800020b0:	0000f517          	auipc	a0,0xf
    800020b4:	20850513          	addi	a0,a0,520 # 800112b8 <wait_lock>
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	bbe080e7          	jalr	-1090(ra) # 80000c76 <release>
          return pid;
    800020c0:	a09d                	j	80002126 <wait+0x100>
            release(&np->lock);
    800020c2:	8526                	mv	a0,s1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	bb2080e7          	jalr	-1102(ra) # 80000c76 <release>
            release(&wait_lock);
    800020cc:	0000f517          	auipc	a0,0xf
    800020d0:	1ec50513          	addi	a0,a0,492 # 800112b8 <wait_lock>
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	ba2080e7          	jalr	-1118(ra) # 80000c76 <release>
            return -1;
    800020dc:	59fd                	li	s3,-1
    800020de:	a0a1                	j	80002126 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800020e0:	17048493          	addi	s1,s1,368
    800020e4:	03348463          	beq	s1,s3,8000210c <wait+0xe6>
      if(np->parent == p){
    800020e8:	60bc                	ld	a5,64(s1)
    800020ea:	ff279be3          	bne	a5,s2,800020e0 <wait+0xba>
        acquire(&np->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	ad2080e7          	jalr	-1326(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800020f8:	4c9c                	lw	a5,24(s1)
    800020fa:	f94781e3          	beq	a5,s4,8000207c <wait+0x56>
        release(&np->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b76080e7          	jalr	-1162(ra) # 80000c76 <release>
        havekids = 1;
    80002108:	8756                	mv	a4,s5
    8000210a:	bfd9                	j	800020e0 <wait+0xba>
    if(!havekids || p->killed){
    8000210c:	c701                	beqz	a4,80002114 <wait+0xee>
    8000210e:	02892783          	lw	a5,40(s2)
    80002112:	c79d                	beqz	a5,80002140 <wait+0x11a>
      release(&wait_lock);
    80002114:	0000f517          	auipc	a0,0xf
    80002118:	1a450513          	addi	a0,a0,420 # 800112b8 <wait_lock>
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	b5a080e7          	jalr	-1190(ra) # 80000c76 <release>
      return -1;
    80002124:	59fd                	li	s3,-1
}
    80002126:	854e                	mv	a0,s3
    80002128:	60a6                	ld	ra,72(sp)
    8000212a:	6406                	ld	s0,64(sp)
    8000212c:	74e2                	ld	s1,56(sp)
    8000212e:	7942                	ld	s2,48(sp)
    80002130:	79a2                	ld	s3,40(sp)
    80002132:	7a02                	ld	s4,32(sp)
    80002134:	6ae2                	ld	s5,24(sp)
    80002136:	6b42                	ld	s6,16(sp)
    80002138:	6ba2                	ld	s7,8(sp)
    8000213a:	6c02                	ld	s8,0(sp)
    8000213c:	6161                	addi	sp,sp,80
    8000213e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002140:	85e2                	mv	a1,s8
    80002142:	854a                	mv	a0,s2
    80002144:	00000097          	auipc	ra,0x0
    80002148:	e7e080e7          	jalr	-386(ra) # 80001fc2 <sleep>
    havekids = 0;
    8000214c:	b715                	j	80002070 <wait+0x4a>

000000008000214e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000214e:	7139                	addi	sp,sp,-64
    80002150:	fc06                	sd	ra,56(sp)
    80002152:	f822                	sd	s0,48(sp)
    80002154:	f426                	sd	s1,40(sp)
    80002156:	f04a                	sd	s2,32(sp)
    80002158:	ec4e                	sd	s3,24(sp)
    8000215a:	e852                	sd	s4,16(sp)
    8000215c:	e456                	sd	s5,8(sp)
    8000215e:	0080                	addi	s0,sp,64
    80002160:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002162:	0000f497          	auipc	s1,0xf
    80002166:	56e48493          	addi	s1,s1,1390 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000216a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000216c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000216e:	00015917          	auipc	s2,0x15
    80002172:	16290913          	addi	s2,s2,354 # 800172d0 <tickslock>
    80002176:	a811                	j	8000218a <wakeup+0x3c>
      }
      release(&p->lock);
    80002178:	8526                	mv	a0,s1
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	afc080e7          	jalr	-1284(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002182:	17048493          	addi	s1,s1,368
    80002186:	03248663          	beq	s1,s2,800021b2 <wakeup+0x64>
    if(p != myproc()){
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	7f4080e7          	jalr	2036(ra) # 8000197e <myproc>
    80002192:	fea488e3          	beq	s1,a0,80002182 <wakeup+0x34>
      acquire(&p->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	a2a080e7          	jalr	-1494(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021a0:	4c9c                	lw	a5,24(s1)
    800021a2:	fd379be3          	bne	a5,s3,80002178 <wakeup+0x2a>
    800021a6:	709c                	ld	a5,32(s1)
    800021a8:	fd4798e3          	bne	a5,s4,80002178 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021ac:	0154ac23          	sw	s5,24(s1)
    800021b0:	b7e1                	j	80002178 <wakeup+0x2a>
    }
  }
}
    800021b2:	70e2                	ld	ra,56(sp)
    800021b4:	7442                	ld	s0,48(sp)
    800021b6:	74a2                	ld	s1,40(sp)
    800021b8:	7902                	ld	s2,32(sp)
    800021ba:	69e2                	ld	s3,24(sp)
    800021bc:	6a42                	ld	s4,16(sp)
    800021be:	6aa2                	ld	s5,8(sp)
    800021c0:	6121                	addi	sp,sp,64
    800021c2:	8082                	ret

00000000800021c4 <reparent>:
{
    800021c4:	7179                	addi	sp,sp,-48
    800021c6:	f406                	sd	ra,40(sp)
    800021c8:	f022                	sd	s0,32(sp)
    800021ca:	ec26                	sd	s1,24(sp)
    800021cc:	e84a                	sd	s2,16(sp)
    800021ce:	e44e                	sd	s3,8(sp)
    800021d0:	e052                	sd	s4,0(sp)
    800021d2:	1800                	addi	s0,sp,48
    800021d4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021d6:	0000f497          	auipc	s1,0xf
    800021da:	4fa48493          	addi	s1,s1,1274 # 800116d0 <proc>
      pp->parent = initproc;
    800021de:	00007a17          	auipc	s4,0x7
    800021e2:	e4aa0a13          	addi	s4,s4,-438 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	00015997          	auipc	s3,0x15
    800021ea:	0ea98993          	addi	s3,s3,234 # 800172d0 <tickslock>
    800021ee:	a029                	j	800021f8 <reparent+0x34>
    800021f0:	17048493          	addi	s1,s1,368
    800021f4:	01348d63          	beq	s1,s3,8000220e <reparent+0x4a>
    if(pp->parent == p){
    800021f8:	60bc                	ld	a5,64(s1)
    800021fa:	ff279be3          	bne	a5,s2,800021f0 <reparent+0x2c>
      pp->parent = initproc;
    800021fe:	000a3503          	ld	a0,0(s4)
    80002202:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002204:	00000097          	auipc	ra,0x0
    80002208:	f4a080e7          	jalr	-182(ra) # 8000214e <wakeup>
    8000220c:	b7d5                	j	800021f0 <reparent+0x2c>
}
    8000220e:	70a2                	ld	ra,40(sp)
    80002210:	7402                	ld	s0,32(sp)
    80002212:	64e2                	ld	s1,24(sp)
    80002214:	6942                	ld	s2,16(sp)
    80002216:	69a2                	ld	s3,8(sp)
    80002218:	6a02                	ld	s4,0(sp)
    8000221a:	6145                	addi	sp,sp,48
    8000221c:	8082                	ret

000000008000221e <exit>:
{
    8000221e:	7179                	addi	sp,sp,-48
    80002220:	f406                	sd	ra,40(sp)
    80002222:	f022                	sd	s0,32(sp)
    80002224:	ec26                	sd	s1,24(sp)
    80002226:	e84a                	sd	s2,16(sp)
    80002228:	e44e                	sd	s3,8(sp)
    8000222a:	e052                	sd	s4,0(sp)
    8000222c:	1800                	addi	s0,sp,48
    8000222e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	74e080e7          	jalr	1870(ra) # 8000197e <myproc>
    80002238:	89aa                	mv	s3,a0
  if(p == initproc)
    8000223a:	00007797          	auipc	a5,0x7
    8000223e:	dee7b783          	ld	a5,-530(a5) # 80009028 <initproc>
    80002242:	0d850493          	addi	s1,a0,216
    80002246:	15850913          	addi	s2,a0,344
    8000224a:	02a79363          	bne	a5,a0,80002270 <exit+0x52>
    panic("init exiting");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	ffa50513          	addi	a0,a0,-6 # 80008248 <digits+0x208>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2d4080e7          	jalr	724(ra) # 8000052a <panic>
      fileclose(f);
    8000225e:	00002097          	auipc	ra,0x2
    80002262:	3de080e7          	jalr	990(ra) # 8000463c <fileclose>
      p->ofile[fd] = 0;
    80002266:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000226a:	04a1                	addi	s1,s1,8
    8000226c:	01248563          	beq	s1,s2,80002276 <exit+0x58>
    if(p->ofile[fd]){
    80002270:	6088                	ld	a0,0(s1)
    80002272:	f575                	bnez	a0,8000225e <exit+0x40>
    80002274:	bfdd                	j	8000226a <exit+0x4c>
  begin_op();
    80002276:	00002097          	auipc	ra,0x2
    8000227a:	efa080e7          	jalr	-262(ra) # 80004170 <begin_op>
  iput(p->cwd);
    8000227e:	1589b503          	ld	a0,344(s3)
    80002282:	00001097          	auipc	ra,0x1
    80002286:	6d2080e7          	jalr	1746(ra) # 80003954 <iput>
  end_op();
    8000228a:	00002097          	auipc	ra,0x2
    8000228e:	f66080e7          	jalr	-154(ra) # 800041f0 <end_op>
  p->cwd = 0;
    80002292:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002296:	0000f497          	auipc	s1,0xf
    8000229a:	02248493          	addi	s1,s1,34 # 800112b8 <wait_lock>
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	922080e7          	jalr	-1758(ra) # 80000bc2 <acquire>
  reparent(p);
    800022a8:	854e                	mv	a0,s3
    800022aa:	00000097          	auipc	ra,0x0
    800022ae:	f1a080e7          	jalr	-230(ra) # 800021c4 <reparent>
  wakeup(p->parent);
    800022b2:	0409b503          	ld	a0,64(s3)
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	e98080e7          	jalr	-360(ra) # 8000214e <wakeup>
  acquire(&p->lock);
    800022be:	854e                	mv	a0,s3
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800022c8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022cc:	4795                	li	a5,5
    800022ce:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9a2080e7          	jalr	-1630(ra) # 80000c76 <release>
  sched();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	bd4080e7          	jalr	-1068(ra) # 80001eb0 <sched>
  panic("zombie exit");
    800022e4:	00006517          	auipc	a0,0x6
    800022e8:	f7450513          	addi	a0,a0,-140 # 80008258 <digits+0x218>
    800022ec:	ffffe097          	auipc	ra,0xffffe
    800022f0:	23e080e7          	jalr	574(ra) # 8000052a <panic>

00000000800022f4 <trace>:



int 
trace(int mask_input, int pid)
{
    800022f4:	7179                	addi	sp,sp,-48
    800022f6:	f406                	sd	ra,40(sp)
    800022f8:	f022                	sd	s0,32(sp)
    800022fa:	ec26                	sd	s1,24(sp)
    800022fc:	e84a                	sd	s2,16(sp)
    800022fe:	e44e                	sd	s3,8(sp)
    80002300:	e052                	sd	s4,0(sp)
    80002302:	1800                	addi	s0,sp,48
    80002304:	8a2a                	mv	s4,a0
    80002306:	892e                	mv	s2,a1
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    80002308:	0000f497          	auipc	s1,0xf
    8000230c:	3c848493          	addi	s1,s1,968 # 800116d0 <proc>
    80002310:	00015997          	auipc	s3,0x15
    80002314:	fc098993          	addi	s3,s3,-64 # 800172d0 <tickslock>
    80002318:	a811                	j	8000232c <trace+0x38>
    acquire(&p->lock);
    if(p->pid == pid)
      p->mask = mask_input;
    release(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	95a080e7          	jalr	-1702(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002324:	17048493          	addi	s1,s1,368
    80002328:	01348d63          	beq	s1,s3,80002342 <trace+0x4e>
    acquire(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	894080e7          	jalr	-1900(ra) # 80000bc2 <acquire>
    if(p->pid == pid)
    80002336:	589c                	lw	a5,48(s1)
    80002338:	ff2791e3          	bne	a5,s2,8000231a <trace+0x26>
      p->mask = mask_input;
    8000233c:	0344aa23          	sw	s4,52(s1)
    80002340:	bfe9                	j	8000231a <trace+0x26>
  }
  return 0;
}
    80002342:	4501                	li	a0,0
    80002344:	70a2                	ld	ra,40(sp)
    80002346:	7402                	ld	s0,32(sp)
    80002348:	64e2                	ld	s1,24(sp)
    8000234a:	6942                	ld	s2,16(sp)
    8000234c:	69a2                	ld	s3,8(sp)
    8000234e:	6a02                	ld	s4,0(sp)
    80002350:	6145                	addi	sp,sp,48
    80002352:	8082                	ret

0000000080002354 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002354:	7179                	addi	sp,sp,-48
    80002356:	f406                	sd	ra,40(sp)
    80002358:	f022                	sd	s0,32(sp)
    8000235a:	ec26                	sd	s1,24(sp)
    8000235c:	e84a                	sd	s2,16(sp)
    8000235e:	e44e                	sd	s3,8(sp)
    80002360:	1800                	addi	s0,sp,48
    80002362:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002364:	0000f497          	auipc	s1,0xf
    80002368:	36c48493          	addi	s1,s1,876 # 800116d0 <proc>
    8000236c:	00015997          	auipc	s3,0x15
    80002370:	f6498993          	addi	s3,s3,-156 # 800172d0 <tickslock>
    acquire(&p->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	84c080e7          	jalr	-1972(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    8000237e:	589c                	lw	a5,48(s1)
    80002380:	01278d63          	beq	a5,s2,8000239a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	8f0080e7          	jalr	-1808(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000238e:	17048493          	addi	s1,s1,368
    80002392:	ff3491e3          	bne	s1,s3,80002374 <kill+0x20>
  }
  return -1;
    80002396:	557d                	li	a0,-1
    80002398:	a829                	j	800023b2 <kill+0x5e>
      p->killed = 1;
    8000239a:	4785                	li	a5,1
    8000239c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000239e:	4c98                	lw	a4,24(s1)
    800023a0:	4789                	li	a5,2
    800023a2:	00f70f63          	beq	a4,a5,800023c0 <kill+0x6c>
      release(&p->lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8ce080e7          	jalr	-1842(ra) # 80000c76 <release>
      return 0;
    800023b0:	4501                	li	a0,0
}
    800023b2:	70a2                	ld	ra,40(sp)
    800023b4:	7402                	ld	s0,32(sp)
    800023b6:	64e2                	ld	s1,24(sp)
    800023b8:	6942                	ld	s2,16(sp)
    800023ba:	69a2                	ld	s3,8(sp)
    800023bc:	6145                	addi	sp,sp,48
    800023be:	8082                	ret
        p->state = RUNNABLE;
    800023c0:	478d                	li	a5,3
    800023c2:	cc9c                	sw	a5,24(s1)
    800023c4:	b7cd                	j	800023a6 <kill+0x52>

00000000800023c6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023c6:	7179                	addi	sp,sp,-48
    800023c8:	f406                	sd	ra,40(sp)
    800023ca:	f022                	sd	s0,32(sp)
    800023cc:	ec26                	sd	s1,24(sp)
    800023ce:	e84a                	sd	s2,16(sp)
    800023d0:	e44e                	sd	s3,8(sp)
    800023d2:	e052                	sd	s4,0(sp)
    800023d4:	1800                	addi	s0,sp,48
    800023d6:	84aa                	mv	s1,a0
    800023d8:	892e                	mv	s2,a1
    800023da:	89b2                	mv	s3,a2
    800023dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	5a0080e7          	jalr	1440(ra) # 8000197e <myproc>
  if(user_dst){
    800023e6:	c08d                	beqz	s1,80002408 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800023e8:	86d2                	mv	a3,s4
    800023ea:	864e                	mv	a2,s3
    800023ec:	85ca                	mv	a1,s2
    800023ee:	6d28                	ld	a0,88(a0)
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	24e080e7          	jalr	590(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800023f8:	70a2                	ld	ra,40(sp)
    800023fa:	7402                	ld	s0,32(sp)
    800023fc:	64e2                	ld	s1,24(sp)
    800023fe:	6942                	ld	s2,16(sp)
    80002400:	69a2                	ld	s3,8(sp)
    80002402:	6a02                	ld	s4,0(sp)
    80002404:	6145                	addi	sp,sp,48
    80002406:	8082                	ret
    memmove((char *)dst, src, len);
    80002408:	000a061b          	sext.w	a2,s4
    8000240c:	85ce                	mv	a1,s3
    8000240e:	854a                	mv	a0,s2
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	90a080e7          	jalr	-1782(ra) # 80000d1a <memmove>
    return 0;
    80002418:	8526                	mv	a0,s1
    8000241a:	bff9                	j	800023f8 <either_copyout+0x32>

000000008000241c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000241c:	7179                	addi	sp,sp,-48
    8000241e:	f406                	sd	ra,40(sp)
    80002420:	f022                	sd	s0,32(sp)
    80002422:	ec26                	sd	s1,24(sp)
    80002424:	e84a                	sd	s2,16(sp)
    80002426:	e44e                	sd	s3,8(sp)
    80002428:	e052                	sd	s4,0(sp)
    8000242a:	1800                	addi	s0,sp,48
    8000242c:	892a                	mv	s2,a0
    8000242e:	84ae                	mv	s1,a1
    80002430:	89b2                	mv	s3,a2
    80002432:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	54a080e7          	jalr	1354(ra) # 8000197e <myproc>
  if(user_src){
    8000243c:	c08d                	beqz	s1,8000245e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000243e:	86d2                	mv	a3,s4
    80002440:	864e                	mv	a2,s3
    80002442:	85ca                	mv	a1,s2
    80002444:	6d28                	ld	a0,88(a0)
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	284080e7          	jalr	644(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000244e:	70a2                	ld	ra,40(sp)
    80002450:	7402                	ld	s0,32(sp)
    80002452:	64e2                	ld	s1,24(sp)
    80002454:	6942                	ld	s2,16(sp)
    80002456:	69a2                	ld	s3,8(sp)
    80002458:	6a02                	ld	s4,0(sp)
    8000245a:	6145                	addi	sp,sp,48
    8000245c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000245e:	000a061b          	sext.w	a2,s4
    80002462:	85ce                	mv	a1,s3
    80002464:	854a                	mv	a0,s2
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	8b4080e7          	jalr	-1868(ra) # 80000d1a <memmove>
    return 0;
    8000246e:	8526                	mv	a0,s1
    80002470:	bff9                	j	8000244e <either_copyin+0x32>

0000000080002472 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002472:	715d                	addi	sp,sp,-80
    80002474:	e486                	sd	ra,72(sp)
    80002476:	e0a2                	sd	s0,64(sp)
    80002478:	fc26                	sd	s1,56(sp)
    8000247a:	f84a                	sd	s2,48(sp)
    8000247c:	f44e                	sd	s3,40(sp)
    8000247e:	f052                	sd	s4,32(sp)
    80002480:	ec56                	sd	s5,24(sp)
    80002482:	e85a                	sd	s6,16(sp)
    80002484:	e45e                	sd	s7,8(sp)
    80002486:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002488:	00006517          	auipc	a0,0x6
    8000248c:	c4050513          	addi	a0,a0,-960 # 800080c8 <digits+0x88>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	0e4080e7          	jalr	228(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002498:	0000f497          	auipc	s1,0xf
    8000249c:	39848493          	addi	s1,s1,920 # 80011830 <proc+0x160>
    800024a0:	00015917          	auipc	s2,0x15
    800024a4:	f9090913          	addi	s2,s2,-112 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024a8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024aa:	00006997          	auipc	s3,0x6
    800024ae:	dbe98993          	addi	s3,s3,-578 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800024b2:	00006a97          	auipc	s5,0x6
    800024b6:	dbea8a93          	addi	s5,s5,-578 # 80008270 <digits+0x230>
    printf("\n");
    800024ba:	00006a17          	auipc	s4,0x6
    800024be:	c0ea0a13          	addi	s4,s4,-1010 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024c2:	00006b97          	auipc	s7,0x6
    800024c6:	de6b8b93          	addi	s7,s7,-538 # 800082a8 <states.0>
    800024ca:	a00d                	j	800024ec <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800024cc:	ed06a583          	lw	a1,-304(a3)
    800024d0:	8556                	mv	a0,s5
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	0a2080e7          	jalr	162(ra) # 80000574 <printf>
    printf("\n");
    800024da:	8552                	mv	a0,s4
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	098080e7          	jalr	152(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024e4:	17048493          	addi	s1,s1,368
    800024e8:	03248263          	beq	s1,s2,8000250c <procdump+0x9a>
    if(p->state == UNUSED)
    800024ec:	86a6                	mv	a3,s1
    800024ee:	eb84a783          	lw	a5,-328(s1)
    800024f2:	dbed                	beqz	a5,800024e4 <procdump+0x72>
      state = "???";
    800024f4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f6:	fcfb6be3          	bltu	s6,a5,800024cc <procdump+0x5a>
    800024fa:	02079713          	slli	a4,a5,0x20
    800024fe:	01d75793          	srli	a5,a4,0x1d
    80002502:	97de                	add	a5,a5,s7
    80002504:	6390                	ld	a2,0(a5)
    80002506:	f279                	bnez	a2,800024cc <procdump+0x5a>
      state = "???";
    80002508:	864e                	mv	a2,s3
    8000250a:	b7c9                	j	800024cc <procdump+0x5a>
  }
}
    8000250c:	60a6                	ld	ra,72(sp)
    8000250e:	6406                	ld	s0,64(sp)
    80002510:	74e2                	ld	s1,56(sp)
    80002512:	7942                	ld	s2,48(sp)
    80002514:	79a2                	ld	s3,40(sp)
    80002516:	7a02                	ld	s4,32(sp)
    80002518:	6ae2                	ld	s5,24(sp)
    8000251a:	6b42                	ld	s6,16(sp)
    8000251c:	6ba2                	ld	s7,8(sp)
    8000251e:	6161                	addi	sp,sp,80
    80002520:	8082                	ret

0000000080002522 <inctickcounter>:

int inctickcounter() {
    80002522:	1101                	addi	sp,sp,-32
    80002524:	ec06                	sd	ra,24(sp)
    80002526:	e822                	sd	s0,16(sp)
    80002528:	e426                	sd	s1,8(sp)
    8000252a:	e04a                	sd	s2,0(sp)
    8000252c:	1000                	addi	s0,sp,32
  int res;
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	450080e7          	jalr	1104(ra) # 8000197e <myproc>
    80002536:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	68a080e7          	jalr	1674(ra) # 80000bc2 <acquire>
  res = proc->tickcounter;
    80002540:	0000f917          	auipc	s2,0xf
    80002544:	1cc92903          	lw	s2,460(s2) # 8001170c <proc+0x3c>
  res++;
  release(&p->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	72c080e7          	jalr	1836(ra) # 80000c76 <release>
  return res;
}
    80002552:	0019051b          	addiw	a0,s2,1
    80002556:	60e2                	ld	ra,24(sp)
    80002558:	6442                	ld	s0,16(sp)
    8000255a:	64a2                	ld	s1,8(sp)
    8000255c:	6902                	ld	s2,0(sp)
    8000255e:	6105                	addi	sp,sp,32
    80002560:	8082                	ret

0000000080002562 <switch_to_process>:

void switch_to_process(struct proc *p, struct cpu *c){
    80002562:	1101                	addi	sp,sp,-32
    80002564:	ec06                	sd	ra,24(sp)
    80002566:	e822                	sd	s0,16(sp)
    80002568:	e426                	sd	s1,8(sp)
    8000256a:	1000                	addi	s0,sp,32
    8000256c:	84ae                	mv	s1,a1
  // Switch to chosen process.  It is the process's job
  // to release its lock and then reacquire it
  // before jumping back to us.
  p->state = RUNNING;
    8000256e:	4791                	li	a5,4
    80002570:	cd1c                	sw	a5,24(a0)
  c->proc = p;
    80002572:	e188                	sd	a0,0(a1)
  swtch(&c->context, &p->context);
    80002574:	06850593          	addi	a1,a0,104
    80002578:	00848513          	addi	a0,s1,8
    8000257c:	00000097          	auipc	ra,0x0
    80002580:	094080e7          	jalr	148(ra) # 80002610 <swtch>

  // Process is done running for now.
  // It should have changed its p->state before coming back.
  c->proc = 0;
    80002584:	0004b023          	sd	zero,0(s1)
}
    80002588:	60e2                	ld	ra,24(sp)
    8000258a:	6442                	ld	s0,16(sp)
    8000258c:	64a2                	ld	s1,8(sp)
    8000258e:	6105                	addi	sp,sp,32
    80002590:	8082                	ret

0000000080002592 <scheduler>:
{
    80002592:	7179                	addi	sp,sp,-48
    80002594:	f406                	sd	ra,40(sp)
    80002596:	f022                	sd	s0,32(sp)
    80002598:	ec26                	sd	s1,24(sp)
    8000259a:	e84a                	sd	s2,16(sp)
    8000259c:	e44e                	sd	s3,8(sp)
    8000259e:	e052                	sd	s4,0(sp)
    800025a0:	1800                	addi	s0,sp,48
    800025a2:	8792                	mv	a5,tp
  int id = r_tp();
    800025a4:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    800025a6:	079e                	slli	a5,a5,0x7
    800025a8:	0000fa17          	auipc	s4,0xf
    800025ac:	d28a0a13          	addi	s4,s4,-728 # 800112d0 <cpus>
    800025b0:	9a3e                	add	s4,s4,a5
  c->proc = 0;
    800025b2:	0000f717          	auipc	a4,0xf
    800025b6:	cee70713          	addi	a4,a4,-786 # 800112a0 <pid_lock>
    800025ba:	97ba                	add	a5,a5,a4
    800025bc:	0207b823          	sd	zero,48(a5)
      if(p->state == RUNNABLE) {
    800025c0:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) {
    800025c2:	00015917          	auipc	s2,0x15
    800025c6:	d0e90913          	addi	s2,s2,-754 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025ce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025d2:	10079073          	csrw	sstatus,a5
    800025d6:	0000f497          	auipc	s1,0xf
    800025da:	0fa48493          	addi	s1,s1,250 # 800116d0 <proc>
    800025de:	a811                	j	800025f2 <scheduler+0x60>
      release(&p->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	694080e7          	jalr	1684(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800025ea:	17048493          	addi	s1,s1,368
    800025ee:	fd248ee3          	beq	s1,s2,800025ca <scheduler+0x38>
      acquire(&p->lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	5ce080e7          	jalr	1486(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    800025fc:	4c9c                	lw	a5,24(s1)
    800025fe:	ff3791e3          	bne	a5,s3,800025e0 <scheduler+0x4e>
        switch_to_process(p, c);
    80002602:	85d2                	mv	a1,s4
    80002604:	8526                	mv	a0,s1
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	f5c080e7          	jalr	-164(ra) # 80002562 <switch_to_process>
    8000260e:	bfc9                	j	800025e0 <scheduler+0x4e>

0000000080002610 <swtch>:
    80002610:	00153023          	sd	ra,0(a0)
    80002614:	00253423          	sd	sp,8(a0)
    80002618:	e900                	sd	s0,16(a0)
    8000261a:	ed04                	sd	s1,24(a0)
    8000261c:	03253023          	sd	s2,32(a0)
    80002620:	03353423          	sd	s3,40(a0)
    80002624:	03453823          	sd	s4,48(a0)
    80002628:	03553c23          	sd	s5,56(a0)
    8000262c:	05653023          	sd	s6,64(a0)
    80002630:	05753423          	sd	s7,72(a0)
    80002634:	05853823          	sd	s8,80(a0)
    80002638:	05953c23          	sd	s9,88(a0)
    8000263c:	07a53023          	sd	s10,96(a0)
    80002640:	07b53423          	sd	s11,104(a0)
    80002644:	0005b083          	ld	ra,0(a1)
    80002648:	0085b103          	ld	sp,8(a1)
    8000264c:	6980                	ld	s0,16(a1)
    8000264e:	6d84                	ld	s1,24(a1)
    80002650:	0205b903          	ld	s2,32(a1)
    80002654:	0285b983          	ld	s3,40(a1)
    80002658:	0305ba03          	ld	s4,48(a1)
    8000265c:	0385ba83          	ld	s5,56(a1)
    80002660:	0405bb03          	ld	s6,64(a1)
    80002664:	0485bb83          	ld	s7,72(a1)
    80002668:	0505bc03          	ld	s8,80(a1)
    8000266c:	0585bc83          	ld	s9,88(a1)
    80002670:	0605bd03          	ld	s10,96(a1)
    80002674:	0685bd83          	ld	s11,104(a1)
    80002678:	8082                	ret

000000008000267a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000267a:	1141                	addi	sp,sp,-16
    8000267c:	e406                	sd	ra,8(sp)
    8000267e:	e022                	sd	s0,0(sp)
    80002680:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002682:	00006597          	auipc	a1,0x6
    80002686:	c5658593          	addi	a1,a1,-938 # 800082d8 <states.0+0x30>
    8000268a:	00015517          	auipc	a0,0x15
    8000268e:	c4650513          	addi	a0,a0,-954 # 800172d0 <tickslock>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	4a0080e7          	jalr	1184(ra) # 80000b32 <initlock>
}
    8000269a:	60a2                	ld	ra,8(sp)
    8000269c:	6402                	ld	s0,0(sp)
    8000269e:	0141                	addi	sp,sp,16
    800026a0:	8082                	ret

00000000800026a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026a2:	1141                	addi	sp,sp,-16
    800026a4:	e422                	sd	s0,8(sp)
    800026a6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a8:	00003797          	auipc	a5,0x3
    800026ac:	5b878793          	addi	a5,a5,1464 # 80005c60 <kernelvec>
    800026b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026b4:	6422                	ld	s0,8(sp)
    800026b6:	0141                	addi	sp,sp,16
    800026b8:	8082                	ret

00000000800026ba <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ba:	1141                	addi	sp,sp,-16
    800026bc:	e406                	sd	ra,8(sp)
    800026be:	e022                	sd	s0,0(sp)
    800026c0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	2bc080e7          	jalr	700(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026ce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026d4:	00005617          	auipc	a2,0x5
    800026d8:	92c60613          	addi	a2,a2,-1748 # 80007000 <_trampoline>
    800026dc:	00005697          	auipc	a3,0x5
    800026e0:	92468693          	addi	a3,a3,-1756 # 80007000 <_trampoline>
    800026e4:	8e91                	sub	a3,a3,a2
    800026e6:	040007b7          	lui	a5,0x4000
    800026ea:	17fd                	addi	a5,a5,-1
    800026ec:	07b2                	slli	a5,a5,0xc
    800026ee:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026f4:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026f6:	180026f3          	csrr	a3,satp
    800026fa:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026fc:	7138                	ld	a4,96(a0)
    800026fe:	6534                	ld	a3,72(a0)
    80002700:	6585                	lui	a1,0x1
    80002702:	96ae                	add	a3,a3,a1
    80002704:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002706:	7138                	ld	a4,96(a0)
    80002708:	00000697          	auipc	a3,0x0
    8000270c:	13868693          	addi	a3,a3,312 # 80002840 <usertrap>
    80002710:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002712:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002714:	8692                	mv	a3,tp
    80002716:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000271c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002720:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002724:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002728:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000272a:	6f18                	ld	a4,24(a4)
    8000272c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002730:	6d2c                	ld	a1,88(a0)
    80002732:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002734:	00005717          	auipc	a4,0x5
    80002738:	95c70713          	addi	a4,a4,-1700 # 80007090 <userret>
    8000273c:	8f11                	sub	a4,a4,a2
    8000273e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002740:	577d                	li	a4,-1
    80002742:	177e                	slli	a4,a4,0x3f
    80002744:	8dd9                	or	a1,a1,a4
    80002746:	02000537          	lui	a0,0x2000
    8000274a:	157d                	addi	a0,a0,-1
    8000274c:	0536                	slli	a0,a0,0xd
    8000274e:	9782                	jalr	a5
}
    80002750:	60a2                	ld	ra,8(sp)
    80002752:	6402                	ld	s0,0(sp)
    80002754:	0141                	addi	sp,sp,16
    80002756:	8082                	ret

0000000080002758 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002758:	1101                	addi	sp,sp,-32
    8000275a:	ec06                	sd	ra,24(sp)
    8000275c:	e822                	sd	s0,16(sp)
    8000275e:	e426                	sd	s1,8(sp)
    80002760:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002762:	00015497          	auipc	s1,0x15
    80002766:	b6e48493          	addi	s1,s1,-1170 # 800172d0 <tickslock>
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	456080e7          	jalr	1110(ra) # 80000bc2 <acquire>
  ticks++;
    80002774:	00007517          	auipc	a0,0x7
    80002778:	8bc50513          	addi	a0,a0,-1860 # 80009030 <ticks>
    8000277c:	411c                	lw	a5,0(a0)
    8000277e:	2785                	addiw	a5,a5,1
    80002780:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002782:	00000097          	auipc	ra,0x0
    80002786:	9cc080e7          	jalr	-1588(ra) # 8000214e <wakeup>
  release(&tickslock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	4ea080e7          	jalr	1258(ra) # 80000c76 <release>
}
    80002794:	60e2                	ld	ra,24(sp)
    80002796:	6442                	ld	s0,16(sp)
    80002798:	64a2                	ld	s1,8(sp)
    8000279a:	6105                	addi	sp,sp,32
    8000279c:	8082                	ret

000000008000279e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000279e:	1101                	addi	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	e426                	sd	s1,8(sp)
    800027a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ac:	00074d63          	bltz	a4,800027c6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027b0:	57fd                	li	a5,-1
    800027b2:	17fe                	slli	a5,a5,0x3f
    800027b4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027b6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027b8:	06f70363          	beq	a4,a5,8000281e <devintr+0x80>
  }
}
    800027bc:	60e2                	ld	ra,24(sp)
    800027be:	6442                	ld	s0,16(sp)
    800027c0:	64a2                	ld	s1,8(sp)
    800027c2:	6105                	addi	sp,sp,32
    800027c4:	8082                	ret
     (scause & 0xff) == 9){
    800027c6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027ca:	46a5                	li	a3,9
    800027cc:	fed792e3          	bne	a5,a3,800027b0 <devintr+0x12>
    int irq = plic_claim();
    800027d0:	00003097          	auipc	ra,0x3
    800027d4:	598080e7          	jalr	1432(ra) # 80005d68 <plic_claim>
    800027d8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027da:	47a9                	li	a5,10
    800027dc:	02f50763          	beq	a0,a5,8000280a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027e0:	4785                	li	a5,1
    800027e2:	02f50963          	beq	a0,a5,80002814 <devintr+0x76>
    return 1;
    800027e6:	4505                	li	a0,1
    } else if(irq){
    800027e8:	d8f1                	beqz	s1,800027bc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027ea:	85a6                	mv	a1,s1
    800027ec:	00006517          	auipc	a0,0x6
    800027f0:	af450513          	addi	a0,a0,-1292 # 800082e0 <states.0+0x38>
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	d80080e7          	jalr	-640(ra) # 80000574 <printf>
      plic_complete(irq);
    800027fc:	8526                	mv	a0,s1
    800027fe:	00003097          	auipc	ra,0x3
    80002802:	58e080e7          	jalr	1422(ra) # 80005d8c <plic_complete>
    return 1;
    80002806:	4505                	li	a0,1
    80002808:	bf55                	j	800027bc <devintr+0x1e>
      uartintr();
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	17c080e7          	jalr	380(ra) # 80000986 <uartintr>
    80002812:	b7ed                	j	800027fc <devintr+0x5e>
      virtio_disk_intr();
    80002814:	00004097          	auipc	ra,0x4
    80002818:	a0a080e7          	jalr	-1526(ra) # 8000621e <virtio_disk_intr>
    8000281c:	b7c5                	j	800027fc <devintr+0x5e>
    if(cpuid() == 0){
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	134080e7          	jalr	308(ra) # 80001952 <cpuid>
    80002826:	c901                	beqz	a0,80002836 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002828:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000282c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000282e:	14479073          	csrw	sip,a5
    return 2;
    80002832:	4509                	li	a0,2
    80002834:	b761                	j	800027bc <devintr+0x1e>
      clockintr();
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	f22080e7          	jalr	-222(ra) # 80002758 <clockintr>
    8000283e:	b7ed                	j	80002828 <devintr+0x8a>

0000000080002840 <usertrap>:
{
    80002840:	1101                	addi	sp,sp,-32
    80002842:	ec06                	sd	ra,24(sp)
    80002844:	e822                	sd	s0,16(sp)
    80002846:	e426                	sd	s1,8(sp)
    80002848:	e04a                	sd	s2,0(sp)
    8000284a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002850:	1007f793          	andi	a5,a5,256
    80002854:	e3ad                	bnez	a5,800028b6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002856:	00003797          	auipc	a5,0x3
    8000285a:	40a78793          	addi	a5,a5,1034 # 80005c60 <kernelvec>
    8000285e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	11c080e7          	jalr	284(ra) # 8000197e <myproc>
    8000286a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000286c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000286e:	14102773          	csrr	a4,sepc
    80002872:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002874:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002878:	47a1                	li	a5,8
    8000287a:	04f71c63          	bne	a4,a5,800028d2 <usertrap+0x92>
    if(p->killed)
    8000287e:	551c                	lw	a5,40(a0)
    80002880:	e3b9                	bnez	a5,800028c6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002882:	70b8                	ld	a4,96(s1)
    80002884:	6f1c                	ld	a5,24(a4)
    80002886:	0791                	addi	a5,a5,4
    80002888:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000288e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002892:	10079073          	csrw	sstatus,a5
    syscall();
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	2fc080e7          	jalr	764(ra) # 80002b92 <syscall>
  if(p->killed)
    8000289e:	549c                	lw	a5,40(s1)
    800028a0:	efd9                	bnez	a5,8000293e <usertrap+0xfe>
  usertrapret();
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	e18080e7          	jalr	-488(ra) # 800026ba <usertrapret>
}
    800028aa:	60e2                	ld	ra,24(sp)
    800028ac:	6442                	ld	s0,16(sp)
    800028ae:	64a2                	ld	s1,8(sp)
    800028b0:	6902                	ld	s2,0(sp)
    800028b2:	6105                	addi	sp,sp,32
    800028b4:	8082                	ret
    panic("usertrap: not from user mode");
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	a4a50513          	addi	a0,a0,-1462 # 80008300 <states.0+0x58>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	c6c080e7          	jalr	-916(ra) # 8000052a <panic>
      exit(-1);
    800028c6:	557d                	li	a0,-1
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	956080e7          	jalr	-1706(ra) # 8000221e <exit>
    800028d0:	bf4d                	j	80002882 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	ecc080e7          	jalr	-308(ra) # 8000279e <devintr>
    800028da:	892a                	mv	s2,a0
    800028dc:	c501                	beqz	a0,800028e4 <usertrap+0xa4>
  if(p->killed)
    800028de:	549c                	lw	a5,40(s1)
    800028e0:	c3a1                	beqz	a5,80002920 <usertrap+0xe0>
    800028e2:	a815                	j	80002916 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028e8:	5890                	lw	a2,48(s1)
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	a3650513          	addi	a0,a0,-1482 # 80008320 <states.0+0x78>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c82080e7          	jalr	-894(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028fe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002902:	00006517          	auipc	a0,0x6
    80002906:	a4e50513          	addi	a0,a0,-1458 # 80008350 <states.0+0xa8>
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	c6a080e7          	jalr	-918(ra) # 80000574 <printf>
    p->killed = 1;
    80002912:	4785                	li	a5,1
    80002914:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002916:	557d                	li	a0,-1
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	906080e7          	jalr	-1786(ra) # 8000221e <exit>
  if(which_dev == 2){
    80002920:	4789                	li	a5,2
    80002922:	f8f910e3          	bne	s2,a5,800028a2 <usertrap+0x62>
    if(inctickcounter() == QUANTUM)
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	bfc080e7          	jalr	-1028(ra) # 80002522 <inctickcounter>
    8000292e:	4795                	li	a5,5
    80002930:	f6f519e3          	bne	a0,a5,800028a2 <usertrap+0x62>
      yield();
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	652080e7          	jalr	1618(ra) # 80001f86 <yield>
    8000293c:	b79d                	j	800028a2 <usertrap+0x62>
  int which_dev = 0;
    8000293e:	4901                	li	s2,0
    80002940:	bfd9                	j	80002916 <usertrap+0xd6>

0000000080002942 <kerneltrap>:
{
    80002942:	7179                	addi	sp,sp,-48
    80002944:	f406                	sd	ra,40(sp)
    80002946:	f022                	sd	s0,32(sp)
    80002948:	ec26                	sd	s1,24(sp)
    8000294a:	e84a                	sd	s2,16(sp)
    8000294c:	e44e                	sd	s3,8(sp)
    8000294e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002950:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002954:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002958:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000295c:	1004f793          	andi	a5,s1,256
    80002960:	cb85                	beqz	a5,80002990 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002962:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002966:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002968:	ef85                	bnez	a5,800029a0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000296a:	00000097          	auipc	ra,0x0
    8000296e:	e34080e7          	jalr	-460(ra) # 8000279e <devintr>
    80002972:	cd1d                	beqz	a0,800029b0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    80002974:	4789                	li	a5,2
    80002976:	06f50a63          	beq	a0,a5,800029ea <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000297a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297e:	10049073          	csrw	sstatus,s1
}
    80002982:	70a2                	ld	ra,40(sp)
    80002984:	7402                	ld	s0,32(sp)
    80002986:	64e2                	ld	s1,24(sp)
    80002988:	6942                	ld	s2,16(sp)
    8000298a:	69a2                	ld	s3,8(sp)
    8000298c:	6145                	addi	sp,sp,48
    8000298e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002990:	00006517          	auipc	a0,0x6
    80002994:	9e050513          	addi	a0,a0,-1568 # 80008370 <states.0+0xc8>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	b92080e7          	jalr	-1134(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	9f850513          	addi	a0,a0,-1544 # 80008398 <states.0+0xf0>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	b82080e7          	jalr	-1150(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800029b0:	85ce                	mv	a1,s3
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	a0650513          	addi	a0,a0,-1530 # 800083b8 <states.0+0x110>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bba080e7          	jalr	-1094(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029c6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9fe50513          	addi	a0,a0,-1538 # 800083c8 <states.0+0x120>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	ba2080e7          	jalr	-1118(ra) # 80000574 <printf>
    panic("kerneltrap");
    800029da:	00006517          	auipc	a0,0x6
    800029de:	a0650513          	addi	a0,a0,-1530 # 800083e0 <states.0+0x138>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	b48080e7          	jalr	-1208(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	f94080e7          	jalr	-108(ra) # 8000197e <myproc>
    800029f2:	d541                	beqz	a0,8000297a <kerneltrap+0x38>
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	f8a080e7          	jalr	-118(ra) # 8000197e <myproc>
    800029fc:	4d18                	lw	a4,24(a0)
    800029fe:	4791                	li	a5,4
    80002a00:	f6f71de3          	bne	a4,a5,8000297a <kerneltrap+0x38>
    80002a04:	00000097          	auipc	ra,0x0
    80002a08:	b1e080e7          	jalr	-1250(ra) # 80002522 <inctickcounter>
    80002a0c:	4795                	li	a5,5
    80002a0e:	f6f516e3          	bne	a0,a5,8000297a <kerneltrap+0x38>
    yield();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	574080e7          	jalr	1396(ra) # 80001f86 <yield>
    80002a1a:	b785                	j	8000297a <kerneltrap+0x38>

0000000080002a1c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a1c:	1101                	addi	sp,sp,-32
    80002a1e:	ec06                	sd	ra,24(sp)
    80002a20:	e822                	sd	s0,16(sp)
    80002a22:	e426                	sd	s1,8(sp)
    80002a24:	1000                	addi	s0,sp,32
    80002a26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	f56080e7          	jalr	-170(ra) # 8000197e <myproc>
  switch (n) {
    80002a30:	4795                	li	a5,5
    80002a32:	0497e163          	bltu	a5,s1,80002a74 <argraw+0x58>
    80002a36:	048a                	slli	s1,s1,0x2
    80002a38:	00006717          	auipc	a4,0x6
    80002a3c:	ae070713          	addi	a4,a4,-1312 # 80008518 <states.0+0x270>
    80002a40:	94ba                	add	s1,s1,a4
    80002a42:	409c                	lw	a5,0(s1)
    80002a44:	97ba                	add	a5,a5,a4
    80002a46:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a48:	713c                	ld	a5,96(a0)
    80002a4a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a4c:	60e2                	ld	ra,24(sp)
    80002a4e:	6442                	ld	s0,16(sp)
    80002a50:	64a2                	ld	s1,8(sp)
    80002a52:	6105                	addi	sp,sp,32
    80002a54:	8082                	ret
    return p->trapframe->a1;
    80002a56:	713c                	ld	a5,96(a0)
    80002a58:	7fa8                	ld	a0,120(a5)
    80002a5a:	bfcd                	j	80002a4c <argraw+0x30>
    return p->trapframe->a2;
    80002a5c:	713c                	ld	a5,96(a0)
    80002a5e:	63c8                	ld	a0,128(a5)
    80002a60:	b7f5                	j	80002a4c <argraw+0x30>
    return p->trapframe->a3;
    80002a62:	713c                	ld	a5,96(a0)
    80002a64:	67c8                	ld	a0,136(a5)
    80002a66:	b7dd                	j	80002a4c <argraw+0x30>
    return p->trapframe->a4;
    80002a68:	713c                	ld	a5,96(a0)
    80002a6a:	6bc8                	ld	a0,144(a5)
    80002a6c:	b7c5                	j	80002a4c <argraw+0x30>
    return p->trapframe->a5;
    80002a6e:	713c                	ld	a5,96(a0)
    80002a70:	6fc8                	ld	a0,152(a5)
    80002a72:	bfe9                	j	80002a4c <argraw+0x30>
  panic("argraw");
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	97c50513          	addi	a0,a0,-1668 # 800083f0 <states.0+0x148>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	aae080e7          	jalr	-1362(ra) # 8000052a <panic>

0000000080002a84 <fetchaddr>:
{
    80002a84:	1101                	addi	sp,sp,-32
    80002a86:	ec06                	sd	ra,24(sp)
    80002a88:	e822                	sd	s0,16(sp)
    80002a8a:	e426                	sd	s1,8(sp)
    80002a8c:	e04a                	sd	s2,0(sp)
    80002a8e:	1000                	addi	s0,sp,32
    80002a90:	84aa                	mv	s1,a0
    80002a92:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	eea080e7          	jalr	-278(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a9c:	693c                	ld	a5,80(a0)
    80002a9e:	02f4f863          	bgeu	s1,a5,80002ace <fetchaddr+0x4a>
    80002aa2:	00848713          	addi	a4,s1,8
    80002aa6:	02e7e663          	bltu	a5,a4,80002ad2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aaa:	46a1                	li	a3,8
    80002aac:	8626                	mv	a2,s1
    80002aae:	85ca                	mv	a1,s2
    80002ab0:	6d28                	ld	a0,88(a0)
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	c18080e7          	jalr	-1000(ra) # 800016ca <copyin>
    80002aba:	00a03533          	snez	a0,a0
    80002abe:	40a00533          	neg	a0,a0
}
    80002ac2:	60e2                	ld	ra,24(sp)
    80002ac4:	6442                	ld	s0,16(sp)
    80002ac6:	64a2                	ld	s1,8(sp)
    80002ac8:	6902                	ld	s2,0(sp)
    80002aca:	6105                	addi	sp,sp,32
    80002acc:	8082                	ret
    return -1;
    80002ace:	557d                	li	a0,-1
    80002ad0:	bfcd                	j	80002ac2 <fetchaddr+0x3e>
    80002ad2:	557d                	li	a0,-1
    80002ad4:	b7fd                	j	80002ac2 <fetchaddr+0x3e>

0000000080002ad6 <fetchstr>:
{
    80002ad6:	7179                	addi	sp,sp,-48
    80002ad8:	f406                	sd	ra,40(sp)
    80002ada:	f022                	sd	s0,32(sp)
    80002adc:	ec26                	sd	s1,24(sp)
    80002ade:	e84a                	sd	s2,16(sp)
    80002ae0:	e44e                	sd	s3,8(sp)
    80002ae2:	1800                	addi	s0,sp,48
    80002ae4:	892a                	mv	s2,a0
    80002ae6:	84ae                	mv	s1,a1
    80002ae8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	e94080e7          	jalr	-364(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002af2:	86ce                	mv	a3,s3
    80002af4:	864a                	mv	a2,s2
    80002af6:	85a6                	mv	a1,s1
    80002af8:	6d28                	ld	a0,88(a0)
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	c5e080e7          	jalr	-930(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002b02:	00054763          	bltz	a0,80002b10 <fetchstr+0x3a>
  return strlen(buf);
    80002b06:	8526                	mv	a0,s1
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	33a080e7          	jalr	826(ra) # 80000e42 <strlen>
}
    80002b10:	70a2                	ld	ra,40(sp)
    80002b12:	7402                	ld	s0,32(sp)
    80002b14:	64e2                	ld	s1,24(sp)
    80002b16:	6942                	ld	s2,16(sp)
    80002b18:	69a2                	ld	s3,8(sp)
    80002b1a:	6145                	addi	sp,sp,48
    80002b1c:	8082                	ret

0000000080002b1e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b1e:	1101                	addi	sp,sp,-32
    80002b20:	ec06                	sd	ra,24(sp)
    80002b22:	e822                	sd	s0,16(sp)
    80002b24:	e426                	sd	s1,8(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	ef2080e7          	jalr	-270(ra) # 80002a1c <argraw>
    80002b32:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b34:	4501                	li	a0,0
    80002b36:	60e2                	ld	ra,24(sp)
    80002b38:	6442                	ld	s0,16(sp)
    80002b3a:	64a2                	ld	s1,8(sp)
    80002b3c:	6105                	addi	sp,sp,32
    80002b3e:	8082                	ret

0000000080002b40 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	1000                	addi	s0,sp,32
    80002b4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	ed0080e7          	jalr	-304(ra) # 80002a1c <argraw>
    80002b54:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b56:	4501                	li	a0,0
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	e04a                	sd	s2,0(sp)
    80002b6c:	1000                	addi	s0,sp,32
    80002b6e:	84ae                	mv	s1,a1
    80002b70:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	eaa080e7          	jalr	-342(ra) # 80002a1c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b7a:	864a                	mv	a2,s2
    80002b7c:	85a6                	mv	a1,s1
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	f58080e7          	jalr	-168(ra) # 80002ad6 <fetchstr>
}
    80002b86:	60e2                	ld	ra,24(sp)
    80002b88:	6442                	ld	s0,16(sp)
    80002b8a:	64a2                	ld	s1,8(sp)
    80002b8c:	6902                	ld	s2,0(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret

0000000080002b92 <syscall>:
 "unlink", "link", "mkdir", "close", "trace"};


void
syscall(void)
{
    80002b92:	7139                	addi	sp,sp,-64
    80002b94:	fc06                	sd	ra,56(sp)
    80002b96:	f822                	sd	s0,48(sp)
    80002b98:	f426                	sd	s1,40(sp)
    80002b9a:	f04a                	sd	s2,32(sp)
    80002b9c:	ec4e                	sd	s3,24(sp)
    80002b9e:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	dde080e7          	jalr	-546(ra) # 8000197e <myproc>
    80002ba8:	892a                	mv	s2,a0
  num = p->trapframe->a7;
    80002baa:	713c                	ld	a5,96(a0)
    80002bac:	0a87a483          	lw	s1,168(a5)
  int argument = 0;
    80002bb0:	fc042623          	sw	zero,-52(s0)
  if(num == SYS_fork || num == SYS_kill || num == SYS_sbrk)
    80002bb4:	47b1                	li	a5,12
    80002bb6:	0297e063          	bltu	a5,s1,80002bd6 <syscall+0x44>
    80002bba:	6785                	lui	a5,0x1
    80002bbc:	04278793          	addi	a5,a5,66 # 1042 <_entry-0x7fffefbe>
    80002bc0:	0097d7b3          	srl	a5,a5,s1
    80002bc4:	8b85                	andi	a5,a5,1
    80002bc6:	cb81                	beqz	a5,80002bd6 <syscall+0x44>
    argint(0, &argument);
    80002bc8:	fcc40593          	addi	a1,s0,-52
    80002bcc:	4501                	li	a0,0
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	f50080e7          	jalr	-176(ra) # 80002b1e <argint>

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bd6:	fff4879b          	addiw	a5,s1,-1
    80002bda:	4755                	li	a4,21
    80002bdc:	02f76163          	bltu	a4,a5,80002bfe <syscall+0x6c>
    80002be0:	00349713          	slli	a4,s1,0x3
    80002be4:	00006797          	auipc	a5,0x6
    80002be8:	94c78793          	addi	a5,a5,-1716 # 80008530 <syscalls>
    80002bec:	97ba                	add	a5,a5,a4
    80002bee:	639c                	ld	a5,0(a5)
    80002bf0:	c799                	beqz	a5,80002bfe <syscall+0x6c>
    p->trapframe->a0 = syscalls[num]();
    80002bf2:	06093983          	ld	s3,96(s2)
    80002bf6:	9782                	jalr	a5
    80002bf8:	06a9b823          	sd	a0,112(s3)
    80002bfc:	a015                	j	80002c20 <syscall+0x8e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bfe:	86a6                	mv	a3,s1
    80002c00:	16090613          	addi	a2,s2,352
    80002c04:	03092583          	lw	a1,48(s2)
    80002c08:	00005517          	auipc	a0,0x5
    80002c0c:	7f050513          	addi	a0,a0,2032 # 800083f8 <states.0+0x150>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	964080e7          	jalr	-1692(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c18:	06093783          	ld	a5,96(s2)
    80002c1c:	577d                	li	a4,-1
    80002c1e:	fbb8                	sd	a4,112(a5)

  int ret = p->trapframe->a0;

  /* If the system calls bit is on in the mask of the process, 
  then print the trace of the system call. */
  if(p->mask & (1 << num)){
    80002c20:	03492783          	lw	a5,52(s2)
    80002c24:	4097d7bb          	sraw	a5,a5,s1
    80002c28:	8b85                	andi	a5,a5,1
    80002c2a:	c3a9                	beqz	a5,80002c6c <syscall+0xda>
  int ret = p->trapframe->a0;
    80002c2c:	06093783          	ld	a5,96(s2)
    80002c30:	5bb4                	lw	a3,112(a5)
    if(num == SYS_fork)
    80002c32:	4785                	li	a5,1
    80002c34:	04f48363          	beq	s1,a5,80002c7a <syscall+0xe8>
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    else if(num == SYS_kill || num == SYS_sbrk)
    80002c38:	4799                	li	a5,6
    80002c3a:	00f48563          	beq	s1,a5,80002c44 <syscall+0xb2>
    80002c3e:	47b1                	li	a5,12
    80002c40:	04f49c63          	bne	s1,a5,80002c98 <syscall+0x106>
      printf("%d: syscall %s %d -> %d\n", p->pid, sys_calls_names[num], argument, ret);
    80002c44:	048e                	slli	s1,s1,0x3
    80002c46:	00006797          	auipc	a5,0x6
    80002c4a:	d0278793          	addi	a5,a5,-766 # 80008948 <sys_calls_names>
    80002c4e:	94be                	add	s1,s1,a5
    80002c50:	8736                	mv	a4,a3
    80002c52:	fcc42683          	lw	a3,-52(s0)
    80002c56:	6090                	ld	a2,0(s1)
    80002c58:	03092583          	lw	a1,48(s2)
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	7dc50513          	addi	a0,a0,2012 # 80008438 <states.0+0x190>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	910080e7          	jalr	-1776(ra) # 80000574 <printf>
    else
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
  }
}
    80002c6c:	70e2                	ld	ra,56(sp)
    80002c6e:	7442                	ld	s0,48(sp)
    80002c70:	74a2                	ld	s1,40(sp)
    80002c72:	7902                	ld	s2,32(sp)
    80002c74:	69e2                	ld	s3,24(sp)
    80002c76:	6121                	addi	sp,sp,64
    80002c78:	8082                	ret
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    80002c7a:	00006617          	auipc	a2,0x6
    80002c7e:	cd663603          	ld	a2,-810(a2) # 80008950 <sys_calls_names+0x8>
    80002c82:	03092583          	lw	a1,48(s2)
    80002c86:	00005517          	auipc	a0,0x5
    80002c8a:	79250513          	addi	a0,a0,1938 # 80008418 <states.0+0x170>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	8e6080e7          	jalr	-1818(ra) # 80000574 <printf>
    80002c96:	bfd9                	j	80002c6c <syscall+0xda>
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
    80002c98:	048e                	slli	s1,s1,0x3
    80002c9a:	00006797          	auipc	a5,0x6
    80002c9e:	cae78793          	addi	a5,a5,-850 # 80008948 <sys_calls_names>
    80002ca2:	94be                	add	s1,s1,a5
    80002ca4:	6090                	ld	a2,0(s1)
    80002ca6:	03092583          	lw	a1,48(s2)
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	7ae50513          	addi	a0,a0,1966 # 80008458 <states.0+0x1b0>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8c2080e7          	jalr	-1854(ra) # 80000574 <printf>
}
    80002cba:	bf4d                	j	80002c6c <syscall+0xda>

0000000080002cbc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cbc:	1101                	addi	sp,sp,-32
    80002cbe:	ec06                	sd	ra,24(sp)
    80002cc0:	e822                	sd	s0,16(sp)
    80002cc2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cc4:	fec40593          	addi	a1,s0,-20
    80002cc8:	4501                	li	a0,0
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	e54080e7          	jalr	-428(ra) # 80002b1e <argint>
    return -1;
    80002cd2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cd4:	00054963          	bltz	a0,80002ce6 <sys_exit+0x2a>
  exit(n);
    80002cd8:	fec42503          	lw	a0,-20(s0)
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	542080e7          	jalr	1346(ra) # 8000221e <exit>
  return 0;  // not reached
    80002ce4:	4781                	li	a5,0
}
    80002ce6:	853e                	mv	a0,a5
    80002ce8:	60e2                	ld	ra,24(sp)
    80002cea:	6442                	ld	s0,16(sp)
    80002cec:	6105                	addi	sp,sp,32
    80002cee:	8082                	ret

0000000080002cf0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cf0:	1141                	addi	sp,sp,-16
    80002cf2:	e406                	sd	ra,8(sp)
    80002cf4:	e022                	sd	s0,0(sp)
    80002cf6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	c86080e7          	jalr	-890(ra) # 8000197e <myproc>
}
    80002d00:	5908                	lw	a0,48(a0)
    80002d02:	60a2                	ld	ra,8(sp)
    80002d04:	6402                	ld	s0,0(sp)
    80002d06:	0141                	addi	sp,sp,16
    80002d08:	8082                	ret

0000000080002d0a <sys_fork>:

uint64
sys_fork(void)
{
    80002d0a:	1141                	addi	sp,sp,-16
    80002d0c:	e406                	sd	ra,8(sp)
    80002d0e:	e022                	sd	s0,0(sp)
    80002d10:	0800                	addi	s0,sp,16
  return fork();
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	056080e7          	jalr	86(ra) # 80001d68 <fork>
}
    80002d1a:	60a2                	ld	ra,8(sp)
    80002d1c:	6402                	ld	s0,0(sp)
    80002d1e:	0141                	addi	sp,sp,16
    80002d20:	8082                	ret

0000000080002d22 <sys_wait>:

uint64
sys_wait(void)
{
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d2a:	fe840593          	addi	a1,s0,-24
    80002d2e:	4501                	li	a0,0
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	e10080e7          	jalr	-496(ra) # 80002b40 <argaddr>
    80002d38:	87aa                	mv	a5,a0
    return -1;
    80002d3a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d3c:	0007c863          	bltz	a5,80002d4c <sys_wait+0x2a>
  return wait(p);
    80002d40:	fe843503          	ld	a0,-24(s0)
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	2e2080e7          	jalr	738(ra) # 80002026 <wait>
}
    80002d4c:	60e2                	ld	ra,24(sp)
    80002d4e:	6442                	ld	s0,16(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d54:	7179                	addi	sp,sp,-48
    80002d56:	f406                	sd	ra,40(sp)
    80002d58:	f022                	sd	s0,32(sp)
    80002d5a:	ec26                	sd	s1,24(sp)
    80002d5c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d5e:	fdc40593          	addi	a1,s0,-36
    80002d62:	4501                	li	a0,0
    80002d64:	00000097          	auipc	ra,0x0
    80002d68:	dba080e7          	jalr	-582(ra) # 80002b1e <argint>
    return -1;
    80002d6c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d6e:	00054f63          	bltz	a0,80002d8c <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	c0c080e7          	jalr	-1012(ra) # 8000197e <myproc>
    80002d7a:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002d7c:	fdc42503          	lw	a0,-36(s0)
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	f74080e7          	jalr	-140(ra) # 80001cf4 <growproc>
    80002d88:	00054863          	bltz	a0,80002d98 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002d8c:	8526                	mv	a0,s1
    80002d8e:	70a2                	ld	ra,40(sp)
    80002d90:	7402                	ld	s0,32(sp)
    80002d92:	64e2                	ld	s1,24(sp)
    80002d94:	6145                	addi	sp,sp,48
    80002d96:	8082                	ret
    return -1;
    80002d98:	54fd                	li	s1,-1
    80002d9a:	bfcd                	j	80002d8c <sys_sbrk+0x38>

0000000080002d9c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d9c:	7139                	addi	sp,sp,-64
    80002d9e:	fc06                	sd	ra,56(sp)
    80002da0:	f822                	sd	s0,48(sp)
    80002da2:	f426                	sd	s1,40(sp)
    80002da4:	f04a                	sd	s2,32(sp)
    80002da6:	ec4e                	sd	s3,24(sp)
    80002da8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002daa:	fcc40593          	addi	a1,s0,-52
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	d6e080e7          	jalr	-658(ra) # 80002b1e <argint>
    return -1;
    80002db8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dba:	06054563          	bltz	a0,80002e24 <sys_sleep+0x88>
  acquire(&tickslock);
    80002dbe:	00014517          	auipc	a0,0x14
    80002dc2:	51250513          	addi	a0,a0,1298 # 800172d0 <tickslock>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	dfc080e7          	jalr	-516(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002dce:	00006917          	auipc	s2,0x6
    80002dd2:	26292903          	lw	s2,610(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002dd6:	fcc42783          	lw	a5,-52(s0)
    80002dda:	cf85                	beqz	a5,80002e12 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ddc:	00014997          	auipc	s3,0x14
    80002de0:	4f498993          	addi	s3,s3,1268 # 800172d0 <tickslock>
    80002de4:	00006497          	auipc	s1,0x6
    80002de8:	24c48493          	addi	s1,s1,588 # 80009030 <ticks>
    if(myproc()->killed){
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	b92080e7          	jalr	-1134(ra) # 8000197e <myproc>
    80002df4:	551c                	lw	a5,40(a0)
    80002df6:	ef9d                	bnez	a5,80002e34 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002df8:	85ce                	mv	a1,s3
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	1c6080e7          	jalr	454(ra) # 80001fc2 <sleep>
  while(ticks - ticks0 < n){
    80002e04:	409c                	lw	a5,0(s1)
    80002e06:	412787bb          	subw	a5,a5,s2
    80002e0a:	fcc42703          	lw	a4,-52(s0)
    80002e0e:	fce7efe3          	bltu	a5,a4,80002dec <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e12:	00014517          	auipc	a0,0x14
    80002e16:	4be50513          	addi	a0,a0,1214 # 800172d0 <tickslock>
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	e5c080e7          	jalr	-420(ra) # 80000c76 <release>
  return 0;
    80002e22:	4781                	li	a5,0
}
    80002e24:	853e                	mv	a0,a5
    80002e26:	70e2                	ld	ra,56(sp)
    80002e28:	7442                	ld	s0,48(sp)
    80002e2a:	74a2                	ld	s1,40(sp)
    80002e2c:	7902                	ld	s2,32(sp)
    80002e2e:	69e2                	ld	s3,24(sp)
    80002e30:	6121                	addi	sp,sp,64
    80002e32:	8082                	ret
      release(&tickslock);
    80002e34:	00014517          	auipc	a0,0x14
    80002e38:	49c50513          	addi	a0,a0,1180 # 800172d0 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	e3a080e7          	jalr	-454(ra) # 80000c76 <release>
      return -1;
    80002e44:	57fd                	li	a5,-1
    80002e46:	bff9                	j	80002e24 <sys_sleep+0x88>

0000000080002e48 <sys_trace>:


int
sys_trace(void)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	1000                	addi	s0,sp,32
  int mask;
  int pid;

  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80002e50:	fec40593          	addi	a1,s0,-20
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	cc8080e7          	jalr	-824(ra) # 80002b1e <argint>
    80002e5e:	02054763          	bltz	a0,80002e8c <sys_trace+0x44>
    80002e62:	fe840593          	addi	a1,s0,-24
    80002e66:	4505                	li	a0,1
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	cb6080e7          	jalr	-842(ra) # 80002b1e <argint>
    80002e70:	02054063          	bltz	a0,80002e90 <sys_trace+0x48>
    return -1;
  return trace(mask, pid);
    80002e74:	fe842583          	lw	a1,-24(s0)
    80002e78:	fec42503          	lw	a0,-20(s0)
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	478080e7          	jalr	1144(ra) # 800022f4 <trace>
}
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret
    return -1;
    80002e8c:	557d                	li	a0,-1
    80002e8e:	bfdd                	j	80002e84 <sys_trace+0x3c>
    80002e90:	557d                	li	a0,-1
    80002e92:	bfcd                	j	80002e84 <sys_trace+0x3c>

0000000080002e94 <sys_kill>:


uint64
sys_kill(void)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e9c:	fec40593          	addi	a1,s0,-20
    80002ea0:	4501                	li	a0,0
    80002ea2:	00000097          	auipc	ra,0x0
    80002ea6:	c7c080e7          	jalr	-900(ra) # 80002b1e <argint>
    80002eaa:	87aa                	mv	a5,a0
    return -1;
    80002eac:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002eae:	0007c863          	bltz	a5,80002ebe <sys_kill+0x2a>
  return kill(pid);
    80002eb2:	fec42503          	lw	a0,-20(s0)
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	49e080e7          	jalr	1182(ra) # 80002354 <kill>
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	6105                	addi	sp,sp,32
    80002ec4:	8082                	ret

0000000080002ec6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ec6:	1101                	addi	sp,sp,-32
    80002ec8:	ec06                	sd	ra,24(sp)
    80002eca:	e822                	sd	s0,16(sp)
    80002ecc:	e426                	sd	s1,8(sp)
    80002ece:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ed0:	00014517          	auipc	a0,0x14
    80002ed4:	40050513          	addi	a0,a0,1024 # 800172d0 <tickslock>
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	cea080e7          	jalr	-790(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002ee0:	00006497          	auipc	s1,0x6
    80002ee4:	1504a483          	lw	s1,336(s1) # 80009030 <ticks>
  release(&tickslock);
    80002ee8:	00014517          	auipc	a0,0x14
    80002eec:	3e850513          	addi	a0,a0,1000 # 800172d0 <tickslock>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	d86080e7          	jalr	-634(ra) # 80000c76 <release>
  return xticks;
}
    80002ef8:	02049513          	slli	a0,s1,0x20
    80002efc:	9101                	srli	a0,a0,0x20
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	64a2                	ld	s1,8(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	e84a                	sd	s2,16(sp)
    80002f12:	e44e                	sd	s3,8(sp)
    80002f14:	e052                	sd	s4,0(sp)
    80002f16:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f18:	00005597          	auipc	a1,0x5
    80002f1c:	6d058593          	addi	a1,a1,1744 # 800085e8 <syscalls+0xb8>
    80002f20:	00014517          	auipc	a0,0x14
    80002f24:	3c850513          	addi	a0,a0,968 # 800172e8 <bcache>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	c0a080e7          	jalr	-1014(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f30:	0001c797          	auipc	a5,0x1c
    80002f34:	3b878793          	addi	a5,a5,952 # 8001f2e8 <bcache+0x8000>
    80002f38:	0001c717          	auipc	a4,0x1c
    80002f3c:	61870713          	addi	a4,a4,1560 # 8001f550 <bcache+0x8268>
    80002f40:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f44:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f48:	00014497          	auipc	s1,0x14
    80002f4c:	3b848493          	addi	s1,s1,952 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002f50:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f52:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f54:	00005a17          	auipc	s4,0x5
    80002f58:	69ca0a13          	addi	s4,s4,1692 # 800085f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f5c:	2b893783          	ld	a5,696(s2)
    80002f60:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f62:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f66:	85d2                	mv	a1,s4
    80002f68:	01048513          	addi	a0,s1,16
    80002f6c:	00001097          	auipc	ra,0x1
    80002f70:	4c2080e7          	jalr	1218(ra) # 8000442e <initsleeplock>
    bcache.head.next->prev = b;
    80002f74:	2b893783          	ld	a5,696(s2)
    80002f78:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f7a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7e:	45848493          	addi	s1,s1,1112
    80002f82:	fd349de3          	bne	s1,s3,80002f5c <binit+0x54>
  }
}
    80002f86:	70a2                	ld	ra,40(sp)
    80002f88:	7402                	ld	s0,32(sp)
    80002f8a:	64e2                	ld	s1,24(sp)
    80002f8c:	6942                	ld	s2,16(sp)
    80002f8e:	69a2                	ld	s3,8(sp)
    80002f90:	6a02                	ld	s4,0(sp)
    80002f92:	6145                	addi	sp,sp,48
    80002f94:	8082                	ret

0000000080002f96 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f96:	7179                	addi	sp,sp,-48
    80002f98:	f406                	sd	ra,40(sp)
    80002f9a:	f022                	sd	s0,32(sp)
    80002f9c:	ec26                	sd	s1,24(sp)
    80002f9e:	e84a                	sd	s2,16(sp)
    80002fa0:	e44e                	sd	s3,8(sp)
    80002fa2:	1800                	addi	s0,sp,48
    80002fa4:	892a                	mv	s2,a0
    80002fa6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fa8:	00014517          	auipc	a0,0x14
    80002fac:	34050513          	addi	a0,a0,832 # 800172e8 <bcache>
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	c12080e7          	jalr	-1006(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb8:	0001c497          	auipc	s1,0x1c
    80002fbc:	5e84b483          	ld	s1,1512(s1) # 8001f5a0 <bcache+0x82b8>
    80002fc0:	0001c797          	auipc	a5,0x1c
    80002fc4:	59078793          	addi	a5,a5,1424 # 8001f550 <bcache+0x8268>
    80002fc8:	02f48f63          	beq	s1,a5,80003006 <bread+0x70>
    80002fcc:	873e                	mv	a4,a5
    80002fce:	a021                	j	80002fd6 <bread+0x40>
    80002fd0:	68a4                	ld	s1,80(s1)
    80002fd2:	02e48a63          	beq	s1,a4,80003006 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd6:	449c                	lw	a5,8(s1)
    80002fd8:	ff279ce3          	bne	a5,s2,80002fd0 <bread+0x3a>
    80002fdc:	44dc                	lw	a5,12(s1)
    80002fde:	ff3799e3          	bne	a5,s3,80002fd0 <bread+0x3a>
      b->refcnt++;
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	2785                	addiw	a5,a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	30050513          	addi	a0,a0,768 # 800172e8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	c86080e7          	jalr	-890(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002ff8:	01048513          	addi	a0,s1,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	46c080e7          	jalr	1132(ra) # 80004468 <acquiresleep>
      return b;
    80003004:	a8b9                	j	80003062 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003006:	0001c497          	auipc	s1,0x1c
    8000300a:	5924b483          	ld	s1,1426(s1) # 8001f598 <bcache+0x82b0>
    8000300e:	0001c797          	auipc	a5,0x1c
    80003012:	54278793          	addi	a5,a5,1346 # 8001f550 <bcache+0x8268>
    80003016:	00f48863          	beq	s1,a5,80003026 <bread+0x90>
    8000301a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000301c:	40bc                	lw	a5,64(s1)
    8000301e:	cf81                	beqz	a5,80003036 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003020:	64a4                	ld	s1,72(s1)
    80003022:	fee49de3          	bne	s1,a4,8000301c <bread+0x86>
  panic("bget: no buffers");
    80003026:	00005517          	auipc	a0,0x5
    8000302a:	5d250513          	addi	a0,a0,1490 # 800085f8 <syscalls+0xc8>
    8000302e:	ffffd097          	auipc	ra,0xffffd
    80003032:	4fc080e7          	jalr	1276(ra) # 8000052a <panic>
      b->dev = dev;
    80003036:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000303a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000303e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003042:	4785                	li	a5,1
    80003044:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	2a250513          	addi	a0,a0,674 # 800172e8 <bcache>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	c28080e7          	jalr	-984(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003056:	01048513          	addi	a0,s1,16
    8000305a:	00001097          	auipc	ra,0x1
    8000305e:	40e080e7          	jalr	1038(ra) # 80004468 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003062:	409c                	lw	a5,0(s1)
    80003064:	cb89                	beqz	a5,80003076 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003066:	8526                	mv	a0,s1
    80003068:	70a2                	ld	ra,40(sp)
    8000306a:	7402                	ld	s0,32(sp)
    8000306c:	64e2                	ld	s1,24(sp)
    8000306e:	6942                	ld	s2,16(sp)
    80003070:	69a2                	ld	s3,8(sp)
    80003072:	6145                	addi	sp,sp,48
    80003074:	8082                	ret
    virtio_disk_rw(b, 0);
    80003076:	4581                	li	a1,0
    80003078:	8526                	mv	a0,s1
    8000307a:	00003097          	auipc	ra,0x3
    8000307e:	f1c080e7          	jalr	-228(ra) # 80005f96 <virtio_disk_rw>
    b->valid = 1;
    80003082:	4785                	li	a5,1
    80003084:	c09c                	sw	a5,0(s1)
  return b;
    80003086:	b7c5                	j	80003066 <bread+0xd0>

0000000080003088 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003094:	0541                	addi	a0,a0,16
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	46c080e7          	jalr	1132(ra) # 80004502 <holdingsleep>
    8000309e:	cd01                	beqz	a0,800030b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030a0:	4585                	li	a1,1
    800030a2:	8526                	mv	a0,s1
    800030a4:	00003097          	auipc	ra,0x3
    800030a8:	ef2080e7          	jalr	-270(ra) # 80005f96 <virtio_disk_rw>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret
    panic("bwrite");
    800030b6:	00005517          	auipc	a0,0x5
    800030ba:	55a50513          	addi	a0,a0,1370 # 80008610 <syscalls+0xe0>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	46c080e7          	jalr	1132(ra) # 8000052a <panic>

00000000800030c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030d4:	01050913          	addi	s2,a0,16
    800030d8:	854a                	mv	a0,s2
    800030da:	00001097          	auipc	ra,0x1
    800030de:	428080e7          	jalr	1064(ra) # 80004502 <holdingsleep>
    800030e2:	c92d                	beqz	a0,80003154 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030e4:	854a                	mv	a0,s2
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	3d8080e7          	jalr	984(ra) # 800044be <releasesleep>

  acquire(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	1fa50513          	addi	a0,a0,506 # 800172e8 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	acc080e7          	jalr	-1332(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	37fd                	addiw	a5,a5,-1
    80003102:	0007871b          	sext.w	a4,a5
    80003106:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003108:	eb05                	bnez	a4,80003138 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000310a:	68bc                	ld	a5,80(s1)
    8000310c:	64b8                	ld	a4,72(s1)
    8000310e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003110:	64bc                	ld	a5,72(s1)
    80003112:	68b8                	ld	a4,80(s1)
    80003114:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003116:	0001c797          	auipc	a5,0x1c
    8000311a:	1d278793          	addi	a5,a5,466 # 8001f2e8 <bcache+0x8000>
    8000311e:	2b87b703          	ld	a4,696(a5)
    80003122:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003124:	0001c717          	auipc	a4,0x1c
    80003128:	42c70713          	addi	a4,a4,1068 # 8001f550 <bcache+0x8268>
    8000312c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000312e:	2b87b703          	ld	a4,696(a5)
    80003132:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003134:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003138:	00014517          	auipc	a0,0x14
    8000313c:	1b050513          	addi	a0,a0,432 # 800172e8 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	b36080e7          	jalr	-1226(ra) # 80000c76 <release>
}
    80003148:	60e2                	ld	ra,24(sp)
    8000314a:	6442                	ld	s0,16(sp)
    8000314c:	64a2                	ld	s1,8(sp)
    8000314e:	6902                	ld	s2,0(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret
    panic("brelse");
    80003154:	00005517          	auipc	a0,0x5
    80003158:	4c450513          	addi	a0,a0,1220 # 80008618 <syscalls+0xe8>
    8000315c:	ffffd097          	auipc	ra,0xffffd
    80003160:	3ce080e7          	jalr	974(ra) # 8000052a <panic>

0000000080003164 <bpin>:

void
bpin(struct buf *b) {
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003170:	00014517          	auipc	a0,0x14
    80003174:	17850513          	addi	a0,a0,376 # 800172e8 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	a4a080e7          	jalr	-1462(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003180:	40bc                	lw	a5,64(s1)
    80003182:	2785                	addiw	a5,a5,1
    80003184:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003186:	00014517          	auipc	a0,0x14
    8000318a:	16250513          	addi	a0,a0,354 # 800172e8 <bcache>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	ae8080e7          	jalr	-1304(ra) # 80000c76 <release>
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <bunpin>:

void
bunpin(struct buf *b) {
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	1000                	addi	s0,sp,32
    800031aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	13c50513          	addi	a0,a0,316 # 800172e8 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	a0e080e7          	jalr	-1522(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800031bc:	40bc                	lw	a5,64(s1)
    800031be:	37fd                	addiw	a5,a5,-1
    800031c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	12650513          	addi	a0,a0,294 # 800172e8 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	aac080e7          	jalr	-1364(ra) # 80000c76 <release>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ea:	00d5d59b          	srliw	a1,a1,0xd
    800031ee:	0001c797          	auipc	a5,0x1c
    800031f2:	7d67a783          	lw	a5,2006(a5) # 8001f9c4 <sb+0x1c>
    800031f6:	9dbd                	addw	a1,a1,a5
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	d9e080e7          	jalr	-610(ra) # 80002f96 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003200:	0074f713          	andi	a4,s1,7
    80003204:	4785                	li	a5,1
    80003206:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000320a:	14ce                	slli	s1,s1,0x33
    8000320c:	90d9                	srli	s1,s1,0x36
    8000320e:	00950733          	add	a4,a0,s1
    80003212:	05874703          	lbu	a4,88(a4)
    80003216:	00e7f6b3          	and	a3,a5,a4
    8000321a:	c69d                	beqz	a3,80003248 <bfree+0x6c>
    8000321c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000321e:	94aa                	add	s1,s1,a0
    80003220:	fff7c793          	not	a5,a5
    80003224:	8ff9                	and	a5,a5,a4
    80003226:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000322a:	00001097          	auipc	ra,0x1
    8000322e:	11e080e7          	jalr	286(ra) # 80004348 <log_write>
  brelse(bp);
    80003232:	854a                	mv	a0,s2
    80003234:	00000097          	auipc	ra,0x0
    80003238:	e92080e7          	jalr	-366(ra) # 800030c6 <brelse>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6902                	ld	s2,0(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret
    panic("freeing free block");
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	3d850513          	addi	a0,a0,984 # 80008620 <syscalls+0xf0>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	2da080e7          	jalr	730(ra) # 8000052a <panic>

0000000080003258 <balloc>:
{
    80003258:	711d                	addi	sp,sp,-96
    8000325a:	ec86                	sd	ra,88(sp)
    8000325c:	e8a2                	sd	s0,80(sp)
    8000325e:	e4a6                	sd	s1,72(sp)
    80003260:	e0ca                	sd	s2,64(sp)
    80003262:	fc4e                	sd	s3,56(sp)
    80003264:	f852                	sd	s4,48(sp)
    80003266:	f456                	sd	s5,40(sp)
    80003268:	f05a                	sd	s6,32(sp)
    8000326a:	ec5e                	sd	s7,24(sp)
    8000326c:	e862                	sd	s8,16(sp)
    8000326e:	e466                	sd	s9,8(sp)
    80003270:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003272:	0001c797          	auipc	a5,0x1c
    80003276:	73a7a783          	lw	a5,1850(a5) # 8001f9ac <sb+0x4>
    8000327a:	cbd1                	beqz	a5,8000330e <balloc+0xb6>
    8000327c:	8baa                	mv	s7,a0
    8000327e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003280:	0001cb17          	auipc	s6,0x1c
    80003284:	728b0b13          	addi	s6,s6,1832 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003288:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000328a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000328e:	6c89                	lui	s9,0x2
    80003290:	a831                	j	800032ac <balloc+0x54>
    brelse(bp);
    80003292:	854a                	mv	a0,s2
    80003294:	00000097          	auipc	ra,0x0
    80003298:	e32080e7          	jalr	-462(ra) # 800030c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000329c:	015c87bb          	addw	a5,s9,s5
    800032a0:	00078a9b          	sext.w	s5,a5
    800032a4:	004b2703          	lw	a4,4(s6)
    800032a8:	06eaf363          	bgeu	s5,a4,8000330e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032ac:	41fad79b          	sraiw	a5,s5,0x1f
    800032b0:	0137d79b          	srliw	a5,a5,0x13
    800032b4:	015787bb          	addw	a5,a5,s5
    800032b8:	40d7d79b          	sraiw	a5,a5,0xd
    800032bc:	01cb2583          	lw	a1,28(s6)
    800032c0:	9dbd                	addw	a1,a1,a5
    800032c2:	855e                	mv	a0,s7
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	cd2080e7          	jalr	-814(ra) # 80002f96 <bread>
    800032cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ce:	004b2503          	lw	a0,4(s6)
    800032d2:	000a849b          	sext.w	s1,s5
    800032d6:	8662                	mv	a2,s8
    800032d8:	faa4fde3          	bgeu	s1,a0,80003292 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032dc:	41f6579b          	sraiw	a5,a2,0x1f
    800032e0:	01d7d69b          	srliw	a3,a5,0x1d
    800032e4:	00c6873b          	addw	a4,a3,a2
    800032e8:	00777793          	andi	a5,a4,7
    800032ec:	9f95                	subw	a5,a5,a3
    800032ee:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032f2:	4037571b          	sraiw	a4,a4,0x3
    800032f6:	00e906b3          	add	a3,s2,a4
    800032fa:	0586c683          	lbu	a3,88(a3)
    800032fe:	00d7f5b3          	and	a1,a5,a3
    80003302:	cd91                	beqz	a1,8000331e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003304:	2605                	addiw	a2,a2,1
    80003306:	2485                	addiw	s1,s1,1
    80003308:	fd4618e3          	bne	a2,s4,800032d8 <balloc+0x80>
    8000330c:	b759                	j	80003292 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000330e:	00005517          	auipc	a0,0x5
    80003312:	32a50513          	addi	a0,a0,810 # 80008638 <syscalls+0x108>
    80003316:	ffffd097          	auipc	ra,0xffffd
    8000331a:	214080e7          	jalr	532(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000331e:	974a                	add	a4,a4,s2
    80003320:	8fd5                	or	a5,a5,a3
    80003322:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003326:	854a                	mv	a0,s2
    80003328:	00001097          	auipc	ra,0x1
    8000332c:	020080e7          	jalr	32(ra) # 80004348 <log_write>
        brelse(bp);
    80003330:	854a                	mv	a0,s2
    80003332:	00000097          	auipc	ra,0x0
    80003336:	d94080e7          	jalr	-620(ra) # 800030c6 <brelse>
  bp = bread(dev, bno);
    8000333a:	85a6                	mv	a1,s1
    8000333c:	855e                	mv	a0,s7
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	c58080e7          	jalr	-936(ra) # 80002f96 <bread>
    80003346:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003348:	40000613          	li	a2,1024
    8000334c:	4581                	li	a1,0
    8000334e:	05850513          	addi	a0,a0,88
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	96c080e7          	jalr	-1684(ra) # 80000cbe <memset>
  log_write(bp);
    8000335a:	854a                	mv	a0,s2
    8000335c:	00001097          	auipc	ra,0x1
    80003360:	fec080e7          	jalr	-20(ra) # 80004348 <log_write>
  brelse(bp);
    80003364:	854a                	mv	a0,s2
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	d60080e7          	jalr	-672(ra) # 800030c6 <brelse>
}
    8000336e:	8526                	mv	a0,s1
    80003370:	60e6                	ld	ra,88(sp)
    80003372:	6446                	ld	s0,80(sp)
    80003374:	64a6                	ld	s1,72(sp)
    80003376:	6906                	ld	s2,64(sp)
    80003378:	79e2                	ld	s3,56(sp)
    8000337a:	7a42                	ld	s4,48(sp)
    8000337c:	7aa2                	ld	s5,40(sp)
    8000337e:	7b02                	ld	s6,32(sp)
    80003380:	6be2                	ld	s7,24(sp)
    80003382:	6c42                	ld	s8,16(sp)
    80003384:	6ca2                	ld	s9,8(sp)
    80003386:	6125                	addi	sp,sp,96
    80003388:	8082                	ret

000000008000338a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000338a:	7179                	addi	sp,sp,-48
    8000338c:	f406                	sd	ra,40(sp)
    8000338e:	f022                	sd	s0,32(sp)
    80003390:	ec26                	sd	s1,24(sp)
    80003392:	e84a                	sd	s2,16(sp)
    80003394:	e44e                	sd	s3,8(sp)
    80003396:	e052                	sd	s4,0(sp)
    80003398:	1800                	addi	s0,sp,48
    8000339a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000339c:	47ad                	li	a5,11
    8000339e:	04b7fe63          	bgeu	a5,a1,800033fa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033a2:	ff45849b          	addiw	s1,a1,-12
    800033a6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033aa:	0ff00793          	li	a5,255
    800033ae:	0ae7e463          	bltu	a5,a4,80003456 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033b2:	08052583          	lw	a1,128(a0)
    800033b6:	c5b5                	beqz	a1,80003422 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033b8:	00092503          	lw	a0,0(s2)
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	bda080e7          	jalr	-1062(ra) # 80002f96 <bread>
    800033c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ca:	02049713          	slli	a4,s1,0x20
    800033ce:	01e75593          	srli	a1,a4,0x1e
    800033d2:	00b784b3          	add	s1,a5,a1
    800033d6:	0004a983          	lw	s3,0(s1)
    800033da:	04098e63          	beqz	s3,80003436 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033de:	8552                	mv	a0,s4
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	ce6080e7          	jalr	-794(ra) # 800030c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e8:	854e                	mv	a0,s3
    800033ea:	70a2                	ld	ra,40(sp)
    800033ec:	7402                	ld	s0,32(sp)
    800033ee:	64e2                	ld	s1,24(sp)
    800033f0:	6942                	ld	s2,16(sp)
    800033f2:	69a2                	ld	s3,8(sp)
    800033f4:	6a02                	ld	s4,0(sp)
    800033f6:	6145                	addi	sp,sp,48
    800033f8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033fa:	02059793          	slli	a5,a1,0x20
    800033fe:	01e7d593          	srli	a1,a5,0x1e
    80003402:	00b504b3          	add	s1,a0,a1
    80003406:	0504a983          	lw	s3,80(s1)
    8000340a:	fc099fe3          	bnez	s3,800033e8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000340e:	4108                	lw	a0,0(a0)
    80003410:	00000097          	auipc	ra,0x0
    80003414:	e48080e7          	jalr	-440(ra) # 80003258 <balloc>
    80003418:	0005099b          	sext.w	s3,a0
    8000341c:	0534a823          	sw	s3,80(s1)
    80003420:	b7e1                	j	800033e8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003422:	4108                	lw	a0,0(a0)
    80003424:	00000097          	auipc	ra,0x0
    80003428:	e34080e7          	jalr	-460(ra) # 80003258 <balloc>
    8000342c:	0005059b          	sext.w	a1,a0
    80003430:	08b92023          	sw	a1,128(s2)
    80003434:	b751                	j	800033b8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003436:	00092503          	lw	a0,0(s2)
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	e1e080e7          	jalr	-482(ra) # 80003258 <balloc>
    80003442:	0005099b          	sext.w	s3,a0
    80003446:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000344a:	8552                	mv	a0,s4
    8000344c:	00001097          	auipc	ra,0x1
    80003450:	efc080e7          	jalr	-260(ra) # 80004348 <log_write>
    80003454:	b769                	j	800033de <bmap+0x54>
  panic("bmap: out of range");
    80003456:	00005517          	auipc	a0,0x5
    8000345a:	1fa50513          	addi	a0,a0,506 # 80008650 <syscalls+0x120>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	0cc080e7          	jalr	204(ra) # 8000052a <panic>

0000000080003466 <iget>:
{
    80003466:	7179                	addi	sp,sp,-48
    80003468:	f406                	sd	ra,40(sp)
    8000346a:	f022                	sd	s0,32(sp)
    8000346c:	ec26                	sd	s1,24(sp)
    8000346e:	e84a                	sd	s2,16(sp)
    80003470:	e44e                	sd	s3,8(sp)
    80003472:	e052                	sd	s4,0(sp)
    80003474:	1800                	addi	s0,sp,48
    80003476:	89aa                	mv	s3,a0
    80003478:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000347a:	0001c517          	auipc	a0,0x1c
    8000347e:	54e50513          	addi	a0,a0,1358 # 8001f9c8 <itable>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	740080e7          	jalr	1856(ra) # 80000bc2 <acquire>
  empty = 0;
    8000348a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000348c:	0001c497          	auipc	s1,0x1c
    80003490:	55448493          	addi	s1,s1,1364 # 8001f9e0 <itable+0x18>
    80003494:	0001e697          	auipc	a3,0x1e
    80003498:	fdc68693          	addi	a3,a3,-36 # 80021470 <log>
    8000349c:	a039                	j	800034aa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349e:	02090b63          	beqz	s2,800034d4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034a2:	08848493          	addi	s1,s1,136
    800034a6:	02d48a63          	beq	s1,a3,800034da <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034aa:	449c                	lw	a5,8(s1)
    800034ac:	fef059e3          	blez	a5,8000349e <iget+0x38>
    800034b0:	4098                	lw	a4,0(s1)
    800034b2:	ff3716e3          	bne	a4,s3,8000349e <iget+0x38>
    800034b6:	40d8                	lw	a4,4(s1)
    800034b8:	ff4713e3          	bne	a4,s4,8000349e <iget+0x38>
      ip->ref++;
    800034bc:	2785                	addiw	a5,a5,1
    800034be:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034c0:	0001c517          	auipc	a0,0x1c
    800034c4:	50850513          	addi	a0,a0,1288 # 8001f9c8 <itable>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	7ae080e7          	jalr	1966(ra) # 80000c76 <release>
      return ip;
    800034d0:	8926                	mv	s2,s1
    800034d2:	a03d                	j	80003500 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d4:	f7f9                	bnez	a5,800034a2 <iget+0x3c>
    800034d6:	8926                	mv	s2,s1
    800034d8:	b7e9                	j	800034a2 <iget+0x3c>
  if(empty == 0)
    800034da:	02090c63          	beqz	s2,80003512 <iget+0xac>
  ip->dev = dev;
    800034de:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034e2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034e6:	4785                	li	a5,1
    800034e8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034ec:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034f0:	0001c517          	auipc	a0,0x1c
    800034f4:	4d850513          	addi	a0,a0,1240 # 8001f9c8 <itable>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	77e080e7          	jalr	1918(ra) # 80000c76 <release>
}
    80003500:	854a                	mv	a0,s2
    80003502:	70a2                	ld	ra,40(sp)
    80003504:	7402                	ld	s0,32(sp)
    80003506:	64e2                	ld	s1,24(sp)
    80003508:	6942                	ld	s2,16(sp)
    8000350a:	69a2                	ld	s3,8(sp)
    8000350c:	6a02                	ld	s4,0(sp)
    8000350e:	6145                	addi	sp,sp,48
    80003510:	8082                	ret
    panic("iget: no inodes");
    80003512:	00005517          	auipc	a0,0x5
    80003516:	15650513          	addi	a0,a0,342 # 80008668 <syscalls+0x138>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	010080e7          	jalr	16(ra) # 8000052a <panic>

0000000080003522 <fsinit>:
fsinit(int dev) {
    80003522:	7179                	addi	sp,sp,-48
    80003524:	f406                	sd	ra,40(sp)
    80003526:	f022                	sd	s0,32(sp)
    80003528:	ec26                	sd	s1,24(sp)
    8000352a:	e84a                	sd	s2,16(sp)
    8000352c:	e44e                	sd	s3,8(sp)
    8000352e:	1800                	addi	s0,sp,48
    80003530:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003532:	4585                	li	a1,1
    80003534:	00000097          	auipc	ra,0x0
    80003538:	a62080e7          	jalr	-1438(ra) # 80002f96 <bread>
    8000353c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000353e:	0001c997          	auipc	s3,0x1c
    80003542:	46a98993          	addi	s3,s3,1130 # 8001f9a8 <sb>
    80003546:	02000613          	li	a2,32
    8000354a:	05850593          	addi	a1,a0,88
    8000354e:	854e                	mv	a0,s3
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	7ca080e7          	jalr	1994(ra) # 80000d1a <memmove>
  brelse(bp);
    80003558:	8526                	mv	a0,s1
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	b6c080e7          	jalr	-1172(ra) # 800030c6 <brelse>
  if(sb.magic != FSMAGIC)
    80003562:	0009a703          	lw	a4,0(s3)
    80003566:	102037b7          	lui	a5,0x10203
    8000356a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000356e:	02f71263          	bne	a4,a5,80003592 <fsinit+0x70>
  initlog(dev, &sb);
    80003572:	0001c597          	auipc	a1,0x1c
    80003576:	43658593          	addi	a1,a1,1078 # 8001f9a8 <sb>
    8000357a:	854a                	mv	a0,s2
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	b4e080e7          	jalr	-1202(ra) # 800040ca <initlog>
}
    80003584:	70a2                	ld	ra,40(sp)
    80003586:	7402                	ld	s0,32(sp)
    80003588:	64e2                	ld	s1,24(sp)
    8000358a:	6942                	ld	s2,16(sp)
    8000358c:	69a2                	ld	s3,8(sp)
    8000358e:	6145                	addi	sp,sp,48
    80003590:	8082                	ret
    panic("invalid file system");
    80003592:	00005517          	auipc	a0,0x5
    80003596:	0e650513          	addi	a0,a0,230 # 80008678 <syscalls+0x148>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	f90080e7          	jalr	-112(ra) # 8000052a <panic>

00000000800035a2 <iinit>:
{
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	ec26                	sd	s1,24(sp)
    800035aa:	e84a                	sd	s2,16(sp)
    800035ac:	e44e                	sd	s3,8(sp)
    800035ae:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035b0:	00005597          	auipc	a1,0x5
    800035b4:	0e058593          	addi	a1,a1,224 # 80008690 <syscalls+0x160>
    800035b8:	0001c517          	auipc	a0,0x1c
    800035bc:	41050513          	addi	a0,a0,1040 # 8001f9c8 <itable>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	572080e7          	jalr	1394(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035c8:	0001c497          	auipc	s1,0x1c
    800035cc:	42848493          	addi	s1,s1,1064 # 8001f9f0 <itable+0x28>
    800035d0:	0001e997          	auipc	s3,0x1e
    800035d4:	eb098993          	addi	s3,s3,-336 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035d8:	00005917          	auipc	s2,0x5
    800035dc:	0c090913          	addi	s2,s2,192 # 80008698 <syscalls+0x168>
    800035e0:	85ca                	mv	a1,s2
    800035e2:	8526                	mv	a0,s1
    800035e4:	00001097          	auipc	ra,0x1
    800035e8:	e4a080e7          	jalr	-438(ra) # 8000442e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035ec:	08848493          	addi	s1,s1,136
    800035f0:	ff3498e3          	bne	s1,s3,800035e0 <iinit+0x3e>
}
    800035f4:	70a2                	ld	ra,40(sp)
    800035f6:	7402                	ld	s0,32(sp)
    800035f8:	64e2                	ld	s1,24(sp)
    800035fa:	6942                	ld	s2,16(sp)
    800035fc:	69a2                	ld	s3,8(sp)
    800035fe:	6145                	addi	sp,sp,48
    80003600:	8082                	ret

0000000080003602 <ialloc>:
{
    80003602:	715d                	addi	sp,sp,-80
    80003604:	e486                	sd	ra,72(sp)
    80003606:	e0a2                	sd	s0,64(sp)
    80003608:	fc26                	sd	s1,56(sp)
    8000360a:	f84a                	sd	s2,48(sp)
    8000360c:	f44e                	sd	s3,40(sp)
    8000360e:	f052                	sd	s4,32(sp)
    80003610:	ec56                	sd	s5,24(sp)
    80003612:	e85a                	sd	s6,16(sp)
    80003614:	e45e                	sd	s7,8(sp)
    80003616:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003618:	0001c717          	auipc	a4,0x1c
    8000361c:	39c72703          	lw	a4,924(a4) # 8001f9b4 <sb+0xc>
    80003620:	4785                	li	a5,1
    80003622:	04e7fa63          	bgeu	a5,a4,80003676 <ialloc+0x74>
    80003626:	8aaa                	mv	s5,a0
    80003628:	8bae                	mv	s7,a1
    8000362a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000362c:	0001ca17          	auipc	s4,0x1c
    80003630:	37ca0a13          	addi	s4,s4,892 # 8001f9a8 <sb>
    80003634:	00048b1b          	sext.w	s6,s1
    80003638:	0044d793          	srli	a5,s1,0x4
    8000363c:	018a2583          	lw	a1,24(s4)
    80003640:	9dbd                	addw	a1,a1,a5
    80003642:	8556                	mv	a0,s5
    80003644:	00000097          	auipc	ra,0x0
    80003648:	952080e7          	jalr	-1710(ra) # 80002f96 <bread>
    8000364c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000364e:	05850993          	addi	s3,a0,88
    80003652:	00f4f793          	andi	a5,s1,15
    80003656:	079a                	slli	a5,a5,0x6
    80003658:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000365a:	00099783          	lh	a5,0(s3)
    8000365e:	c785                	beqz	a5,80003686 <ialloc+0x84>
    brelse(bp);
    80003660:	00000097          	auipc	ra,0x0
    80003664:	a66080e7          	jalr	-1434(ra) # 800030c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003668:	0485                	addi	s1,s1,1
    8000366a:	00ca2703          	lw	a4,12(s4)
    8000366e:	0004879b          	sext.w	a5,s1
    80003672:	fce7e1e3          	bltu	a5,a4,80003634 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003676:	00005517          	auipc	a0,0x5
    8000367a:	02a50513          	addi	a0,a0,42 # 800086a0 <syscalls+0x170>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	eac080e7          	jalr	-340(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003686:	04000613          	li	a2,64
    8000368a:	4581                	li	a1,0
    8000368c:	854e                	mv	a0,s3
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	630080e7          	jalr	1584(ra) # 80000cbe <memset>
      dip->type = type;
    80003696:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000369a:	854a                	mv	a0,s2
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	cac080e7          	jalr	-852(ra) # 80004348 <log_write>
      brelse(bp);
    800036a4:	854a                	mv	a0,s2
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	a20080e7          	jalr	-1504(ra) # 800030c6 <brelse>
      return iget(dev, inum);
    800036ae:	85da                	mv	a1,s6
    800036b0:	8556                	mv	a0,s5
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	db4080e7          	jalr	-588(ra) # 80003466 <iget>
}
    800036ba:	60a6                	ld	ra,72(sp)
    800036bc:	6406                	ld	s0,64(sp)
    800036be:	74e2                	ld	s1,56(sp)
    800036c0:	7942                	ld	s2,48(sp)
    800036c2:	79a2                	ld	s3,40(sp)
    800036c4:	7a02                	ld	s4,32(sp)
    800036c6:	6ae2                	ld	s5,24(sp)
    800036c8:	6b42                	ld	s6,16(sp)
    800036ca:	6ba2                	ld	s7,8(sp)
    800036cc:	6161                	addi	sp,sp,80
    800036ce:	8082                	ret

00000000800036d0 <iupdate>:
{
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	e426                	sd	s1,8(sp)
    800036d8:	e04a                	sd	s2,0(sp)
    800036da:	1000                	addi	s0,sp,32
    800036dc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036de:	415c                	lw	a5,4(a0)
    800036e0:	0047d79b          	srliw	a5,a5,0x4
    800036e4:	0001c597          	auipc	a1,0x1c
    800036e8:	2dc5a583          	lw	a1,732(a1) # 8001f9c0 <sb+0x18>
    800036ec:	9dbd                	addw	a1,a1,a5
    800036ee:	4108                	lw	a0,0(a0)
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	8a6080e7          	jalr	-1882(ra) # 80002f96 <bread>
    800036f8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036fa:	05850793          	addi	a5,a0,88
    800036fe:	40c8                	lw	a0,4(s1)
    80003700:	893d                	andi	a0,a0,15
    80003702:	051a                	slli	a0,a0,0x6
    80003704:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003706:	04449703          	lh	a4,68(s1)
    8000370a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000370e:	04649703          	lh	a4,70(s1)
    80003712:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003716:	04849703          	lh	a4,72(s1)
    8000371a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000371e:	04a49703          	lh	a4,74(s1)
    80003722:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003726:	44f8                	lw	a4,76(s1)
    80003728:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000372a:	03400613          	li	a2,52
    8000372e:	05048593          	addi	a1,s1,80
    80003732:	0531                	addi	a0,a0,12
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	5e6080e7          	jalr	1510(ra) # 80000d1a <memmove>
  log_write(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	c0a080e7          	jalr	-1014(ra) # 80004348 <log_write>
  brelse(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	97e080e7          	jalr	-1666(ra) # 800030c6 <brelse>
}
    80003750:	60e2                	ld	ra,24(sp)
    80003752:	6442                	ld	s0,16(sp)
    80003754:	64a2                	ld	s1,8(sp)
    80003756:	6902                	ld	s2,0(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret

000000008000375c <idup>:
{
    8000375c:	1101                	addi	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	1000                	addi	s0,sp,32
    80003766:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003768:	0001c517          	auipc	a0,0x1c
    8000376c:	26050513          	addi	a0,a0,608 # 8001f9c8 <itable>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	452080e7          	jalr	1106(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003778:	449c                	lw	a5,8(s1)
    8000377a:	2785                	addiw	a5,a5,1
    8000377c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000377e:	0001c517          	auipc	a0,0x1c
    80003782:	24a50513          	addi	a0,a0,586 # 8001f9c8 <itable>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	4f0080e7          	jalr	1264(ra) # 80000c76 <release>
}
    8000378e:	8526                	mv	a0,s1
    80003790:	60e2                	ld	ra,24(sp)
    80003792:	6442                	ld	s0,16(sp)
    80003794:	64a2                	ld	s1,8(sp)
    80003796:	6105                	addi	sp,sp,32
    80003798:	8082                	ret

000000008000379a <ilock>:
{
    8000379a:	1101                	addi	sp,sp,-32
    8000379c:	ec06                	sd	ra,24(sp)
    8000379e:	e822                	sd	s0,16(sp)
    800037a0:	e426                	sd	s1,8(sp)
    800037a2:	e04a                	sd	s2,0(sp)
    800037a4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a6:	c115                	beqz	a0,800037ca <ilock+0x30>
    800037a8:	84aa                	mv	s1,a0
    800037aa:	451c                	lw	a5,8(a0)
    800037ac:	00f05f63          	blez	a5,800037ca <ilock+0x30>
  acquiresleep(&ip->lock);
    800037b0:	0541                	addi	a0,a0,16
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	cb6080e7          	jalr	-842(ra) # 80004468 <acquiresleep>
  if(ip->valid == 0){
    800037ba:	40bc                	lw	a5,64(s1)
    800037bc:	cf99                	beqz	a5,800037da <ilock+0x40>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6902                	ld	s2,0(sp)
    800037c6:	6105                	addi	sp,sp,32
    800037c8:	8082                	ret
    panic("ilock");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	eee50513          	addi	a0,a0,-274 # 800086b8 <syscalls+0x188>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d58080e7          	jalr	-680(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037da:	40dc                	lw	a5,4(s1)
    800037dc:	0047d79b          	srliw	a5,a5,0x4
    800037e0:	0001c597          	auipc	a1,0x1c
    800037e4:	1e05a583          	lw	a1,480(a1) # 8001f9c0 <sb+0x18>
    800037e8:	9dbd                	addw	a1,a1,a5
    800037ea:	4088                	lw	a0,0(s1)
    800037ec:	fffff097          	auipc	ra,0xfffff
    800037f0:	7aa080e7          	jalr	1962(ra) # 80002f96 <bread>
    800037f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f6:	05850593          	addi	a1,a0,88
    800037fa:	40dc                	lw	a5,4(s1)
    800037fc:	8bbd                	andi	a5,a5,15
    800037fe:	079a                	slli	a5,a5,0x6
    80003800:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003802:	00059783          	lh	a5,0(a1)
    80003806:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000380a:	00259783          	lh	a5,2(a1)
    8000380e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003812:	00459783          	lh	a5,4(a1)
    80003816:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000381a:	00659783          	lh	a5,6(a1)
    8000381e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003822:	459c                	lw	a5,8(a1)
    80003824:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003826:	03400613          	li	a2,52
    8000382a:	05b1                	addi	a1,a1,12
    8000382c:	05048513          	addi	a0,s1,80
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	4ea080e7          	jalr	1258(ra) # 80000d1a <memmove>
    brelse(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	88c080e7          	jalr	-1908(ra) # 800030c6 <brelse>
    ip->valid = 1;
    80003842:	4785                	li	a5,1
    80003844:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003846:	04449783          	lh	a5,68(s1)
    8000384a:	fbb5                	bnez	a5,800037be <ilock+0x24>
      panic("ilock: no type");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	e7450513          	addi	a0,a0,-396 # 800086c0 <syscalls+0x190>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	cd6080e7          	jalr	-810(ra) # 8000052a <panic>

000000008000385c <iunlock>:
{
    8000385c:	1101                	addi	sp,sp,-32
    8000385e:	ec06                	sd	ra,24(sp)
    80003860:	e822                	sd	s0,16(sp)
    80003862:	e426                	sd	s1,8(sp)
    80003864:	e04a                	sd	s2,0(sp)
    80003866:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003868:	c905                	beqz	a0,80003898 <iunlock+0x3c>
    8000386a:	84aa                	mv	s1,a0
    8000386c:	01050913          	addi	s2,a0,16
    80003870:	854a                	mv	a0,s2
    80003872:	00001097          	auipc	ra,0x1
    80003876:	c90080e7          	jalr	-880(ra) # 80004502 <holdingsleep>
    8000387a:	cd19                	beqz	a0,80003898 <iunlock+0x3c>
    8000387c:	449c                	lw	a5,8(s1)
    8000387e:	00f05d63          	blez	a5,80003898 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003882:	854a                	mv	a0,s2
    80003884:	00001097          	auipc	ra,0x1
    80003888:	c3a080e7          	jalr	-966(ra) # 800044be <releasesleep>
}
    8000388c:	60e2                	ld	ra,24(sp)
    8000388e:	6442                	ld	s0,16(sp)
    80003890:	64a2                	ld	s1,8(sp)
    80003892:	6902                	ld	s2,0(sp)
    80003894:	6105                	addi	sp,sp,32
    80003896:	8082                	ret
    panic("iunlock");
    80003898:	00005517          	auipc	a0,0x5
    8000389c:	e3850513          	addi	a0,a0,-456 # 800086d0 <syscalls+0x1a0>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	c8a080e7          	jalr	-886(ra) # 8000052a <panic>

00000000800038a8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038a8:	7179                	addi	sp,sp,-48
    800038aa:	f406                	sd	ra,40(sp)
    800038ac:	f022                	sd	s0,32(sp)
    800038ae:	ec26                	sd	s1,24(sp)
    800038b0:	e84a                	sd	s2,16(sp)
    800038b2:	e44e                	sd	s3,8(sp)
    800038b4:	e052                	sd	s4,0(sp)
    800038b6:	1800                	addi	s0,sp,48
    800038b8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ba:	05050493          	addi	s1,a0,80
    800038be:	08050913          	addi	s2,a0,128
    800038c2:	a021                	j	800038ca <itrunc+0x22>
    800038c4:	0491                	addi	s1,s1,4
    800038c6:	01248d63          	beq	s1,s2,800038e0 <itrunc+0x38>
    if(ip->addrs[i]){
    800038ca:	408c                	lw	a1,0(s1)
    800038cc:	dde5                	beqz	a1,800038c4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ce:	0009a503          	lw	a0,0(s3)
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	90a080e7          	jalr	-1782(ra) # 800031dc <bfree>
      ip->addrs[i] = 0;
    800038da:	0004a023          	sw	zero,0(s1)
    800038de:	b7dd                	j	800038c4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038e0:	0809a583          	lw	a1,128(s3)
    800038e4:	e185                	bnez	a1,80003904 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038ea:	854e                	mv	a0,s3
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	de4080e7          	jalr	-540(ra) # 800036d0 <iupdate>
}
    800038f4:	70a2                	ld	ra,40(sp)
    800038f6:	7402                	ld	s0,32(sp)
    800038f8:	64e2                	ld	s1,24(sp)
    800038fa:	6942                	ld	s2,16(sp)
    800038fc:	69a2                	ld	s3,8(sp)
    800038fe:	6a02                	ld	s4,0(sp)
    80003900:	6145                	addi	sp,sp,48
    80003902:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003904:	0009a503          	lw	a0,0(s3)
    80003908:	fffff097          	auipc	ra,0xfffff
    8000390c:	68e080e7          	jalr	1678(ra) # 80002f96 <bread>
    80003910:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003912:	05850493          	addi	s1,a0,88
    80003916:	45850913          	addi	s2,a0,1112
    8000391a:	a021                	j	80003922 <itrunc+0x7a>
    8000391c:	0491                	addi	s1,s1,4
    8000391e:	01248b63          	beq	s1,s2,80003934 <itrunc+0x8c>
      if(a[j])
    80003922:	408c                	lw	a1,0(s1)
    80003924:	dde5                	beqz	a1,8000391c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003926:	0009a503          	lw	a0,0(s3)
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	8b2080e7          	jalr	-1870(ra) # 800031dc <bfree>
    80003932:	b7ed                	j	8000391c <itrunc+0x74>
    brelse(bp);
    80003934:	8552                	mv	a0,s4
    80003936:	fffff097          	auipc	ra,0xfffff
    8000393a:	790080e7          	jalr	1936(ra) # 800030c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000393e:	0809a583          	lw	a1,128(s3)
    80003942:	0009a503          	lw	a0,0(s3)
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	896080e7          	jalr	-1898(ra) # 800031dc <bfree>
    ip->addrs[NDIRECT] = 0;
    8000394e:	0809a023          	sw	zero,128(s3)
    80003952:	bf51                	j	800038e6 <itrunc+0x3e>

0000000080003954 <iput>:
{
    80003954:	1101                	addi	sp,sp,-32
    80003956:	ec06                	sd	ra,24(sp)
    80003958:	e822                	sd	s0,16(sp)
    8000395a:	e426                	sd	s1,8(sp)
    8000395c:	e04a                	sd	s2,0(sp)
    8000395e:	1000                	addi	s0,sp,32
    80003960:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003962:	0001c517          	auipc	a0,0x1c
    80003966:	06650513          	addi	a0,a0,102 # 8001f9c8 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	258080e7          	jalr	600(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003972:	4498                	lw	a4,8(s1)
    80003974:	4785                	li	a5,1
    80003976:	02f70363          	beq	a4,a5,8000399c <iput+0x48>
  ip->ref--;
    8000397a:	449c                	lw	a5,8(s1)
    8000397c:	37fd                	addiw	a5,a5,-1
    8000397e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003980:	0001c517          	auipc	a0,0x1c
    80003984:	04850513          	addi	a0,a0,72 # 8001f9c8 <itable>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	2ee080e7          	jalr	750(ra) # 80000c76 <release>
}
    80003990:	60e2                	ld	ra,24(sp)
    80003992:	6442                	ld	s0,16(sp)
    80003994:	64a2                	ld	s1,8(sp)
    80003996:	6902                	ld	s2,0(sp)
    80003998:	6105                	addi	sp,sp,32
    8000399a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000399c:	40bc                	lw	a5,64(s1)
    8000399e:	dff1                	beqz	a5,8000397a <iput+0x26>
    800039a0:	04a49783          	lh	a5,74(s1)
    800039a4:	fbf9                	bnez	a5,8000397a <iput+0x26>
    acquiresleep(&ip->lock);
    800039a6:	01048913          	addi	s2,s1,16
    800039aa:	854a                	mv	a0,s2
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	abc080e7          	jalr	-1348(ra) # 80004468 <acquiresleep>
    release(&itable.lock);
    800039b4:	0001c517          	auipc	a0,0x1c
    800039b8:	01450513          	addi	a0,a0,20 # 8001f9c8 <itable>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	2ba080e7          	jalr	698(ra) # 80000c76 <release>
    itrunc(ip);
    800039c4:	8526                	mv	a0,s1
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	ee2080e7          	jalr	-286(ra) # 800038a8 <itrunc>
    ip->type = 0;
    800039ce:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	cfc080e7          	jalr	-772(ra) # 800036d0 <iupdate>
    ip->valid = 0;
    800039dc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039e0:	854a                	mv	a0,s2
    800039e2:	00001097          	auipc	ra,0x1
    800039e6:	adc080e7          	jalr	-1316(ra) # 800044be <releasesleep>
    acquire(&itable.lock);
    800039ea:	0001c517          	auipc	a0,0x1c
    800039ee:	fde50513          	addi	a0,a0,-34 # 8001f9c8 <itable>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	1d0080e7          	jalr	464(ra) # 80000bc2 <acquire>
    800039fa:	b741                	j	8000397a <iput+0x26>

00000000800039fc <iunlockput>:
{
    800039fc:	1101                	addi	sp,sp,-32
    800039fe:	ec06                	sd	ra,24(sp)
    80003a00:	e822                	sd	s0,16(sp)
    80003a02:	e426                	sd	s1,8(sp)
    80003a04:	1000                	addi	s0,sp,32
    80003a06:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	e54080e7          	jalr	-428(ra) # 8000385c <iunlock>
  iput(ip);
    80003a10:	8526                	mv	a0,s1
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	f42080e7          	jalr	-190(ra) # 80003954 <iput>
}
    80003a1a:	60e2                	ld	ra,24(sp)
    80003a1c:	6442                	ld	s0,16(sp)
    80003a1e:	64a2                	ld	s1,8(sp)
    80003a20:	6105                	addi	sp,sp,32
    80003a22:	8082                	ret

0000000080003a24 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a24:	1141                	addi	sp,sp,-16
    80003a26:	e422                	sd	s0,8(sp)
    80003a28:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a2a:	411c                	lw	a5,0(a0)
    80003a2c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a2e:	415c                	lw	a5,4(a0)
    80003a30:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a32:	04451783          	lh	a5,68(a0)
    80003a36:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a3a:	04a51783          	lh	a5,74(a0)
    80003a3e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a42:	04c56783          	lwu	a5,76(a0)
    80003a46:	e99c                	sd	a5,16(a1)
}
    80003a48:	6422                	ld	s0,8(sp)
    80003a4a:	0141                	addi	sp,sp,16
    80003a4c:	8082                	ret

0000000080003a4e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a4e:	457c                	lw	a5,76(a0)
    80003a50:	0ed7e963          	bltu	a5,a3,80003b42 <readi+0xf4>
{
    80003a54:	7159                	addi	sp,sp,-112
    80003a56:	f486                	sd	ra,104(sp)
    80003a58:	f0a2                	sd	s0,96(sp)
    80003a5a:	eca6                	sd	s1,88(sp)
    80003a5c:	e8ca                	sd	s2,80(sp)
    80003a5e:	e4ce                	sd	s3,72(sp)
    80003a60:	e0d2                	sd	s4,64(sp)
    80003a62:	fc56                	sd	s5,56(sp)
    80003a64:	f85a                	sd	s6,48(sp)
    80003a66:	f45e                	sd	s7,40(sp)
    80003a68:	f062                	sd	s8,32(sp)
    80003a6a:	ec66                	sd	s9,24(sp)
    80003a6c:	e86a                	sd	s10,16(sp)
    80003a6e:	e46e                	sd	s11,8(sp)
    80003a70:	1880                	addi	s0,sp,112
    80003a72:	8baa                	mv	s7,a0
    80003a74:	8c2e                	mv	s8,a1
    80003a76:	8ab2                	mv	s5,a2
    80003a78:	84b6                	mv	s1,a3
    80003a7a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a7c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a7e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a80:	0ad76063          	bltu	a4,a3,80003b20 <readi+0xd2>
  if(off + n > ip->size)
    80003a84:	00e7f463          	bgeu	a5,a4,80003a8c <readi+0x3e>
    n = ip->size - off;
    80003a88:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8c:	0a0b0963          	beqz	s6,80003b3e <readi+0xf0>
    80003a90:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a92:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a96:	5cfd                	li	s9,-1
    80003a98:	a82d                	j	80003ad2 <readi+0x84>
    80003a9a:	020a1d93          	slli	s11,s4,0x20
    80003a9e:	020ddd93          	srli	s11,s11,0x20
    80003aa2:	05890793          	addi	a5,s2,88
    80003aa6:	86ee                	mv	a3,s11
    80003aa8:	963e                	add	a2,a2,a5
    80003aaa:	85d6                	mv	a1,s5
    80003aac:	8562                	mv	a0,s8
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	918080e7          	jalr	-1768(ra) # 800023c6 <either_copyout>
    80003ab6:	05950d63          	beq	a0,s9,80003b10 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aba:	854a                	mv	a0,s2
    80003abc:	fffff097          	auipc	ra,0xfffff
    80003ac0:	60a080e7          	jalr	1546(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac4:	013a09bb          	addw	s3,s4,s3
    80003ac8:	009a04bb          	addw	s1,s4,s1
    80003acc:	9aee                	add	s5,s5,s11
    80003ace:	0569f763          	bgeu	s3,s6,80003b1c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ad2:	000ba903          	lw	s2,0(s7)
    80003ad6:	00a4d59b          	srliw	a1,s1,0xa
    80003ada:	855e                	mv	a0,s7
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	8ae080e7          	jalr	-1874(ra) # 8000338a <bmap>
    80003ae4:	0005059b          	sext.w	a1,a0
    80003ae8:	854a                	mv	a0,s2
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	4ac080e7          	jalr	1196(ra) # 80002f96 <bread>
    80003af2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af4:	3ff4f613          	andi	a2,s1,1023
    80003af8:	40cd07bb          	subw	a5,s10,a2
    80003afc:	413b073b          	subw	a4,s6,s3
    80003b00:	8a3e                	mv	s4,a5
    80003b02:	2781                	sext.w	a5,a5
    80003b04:	0007069b          	sext.w	a3,a4
    80003b08:	f8f6f9e3          	bgeu	a3,a5,80003a9a <readi+0x4c>
    80003b0c:	8a3a                	mv	s4,a4
    80003b0e:	b771                	j	80003a9a <readi+0x4c>
      brelse(bp);
    80003b10:	854a                	mv	a0,s2
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	5b4080e7          	jalr	1460(ra) # 800030c6 <brelse>
      tot = -1;
    80003b1a:	59fd                	li	s3,-1
  }
  return tot;
    80003b1c:	0009851b          	sext.w	a0,s3
}
    80003b20:	70a6                	ld	ra,104(sp)
    80003b22:	7406                	ld	s0,96(sp)
    80003b24:	64e6                	ld	s1,88(sp)
    80003b26:	6946                	ld	s2,80(sp)
    80003b28:	69a6                	ld	s3,72(sp)
    80003b2a:	6a06                	ld	s4,64(sp)
    80003b2c:	7ae2                	ld	s5,56(sp)
    80003b2e:	7b42                	ld	s6,48(sp)
    80003b30:	7ba2                	ld	s7,40(sp)
    80003b32:	7c02                	ld	s8,32(sp)
    80003b34:	6ce2                	ld	s9,24(sp)
    80003b36:	6d42                	ld	s10,16(sp)
    80003b38:	6da2                	ld	s11,8(sp)
    80003b3a:	6165                	addi	sp,sp,112
    80003b3c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3e:	89da                	mv	s3,s6
    80003b40:	bff1                	j	80003b1c <readi+0xce>
    return 0;
    80003b42:	4501                	li	a0,0
}
    80003b44:	8082                	ret

0000000080003b46 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b46:	457c                	lw	a5,76(a0)
    80003b48:	10d7e863          	bltu	a5,a3,80003c58 <writei+0x112>
{
    80003b4c:	7159                	addi	sp,sp,-112
    80003b4e:	f486                	sd	ra,104(sp)
    80003b50:	f0a2                	sd	s0,96(sp)
    80003b52:	eca6                	sd	s1,88(sp)
    80003b54:	e8ca                	sd	s2,80(sp)
    80003b56:	e4ce                	sd	s3,72(sp)
    80003b58:	e0d2                	sd	s4,64(sp)
    80003b5a:	fc56                	sd	s5,56(sp)
    80003b5c:	f85a                	sd	s6,48(sp)
    80003b5e:	f45e                	sd	s7,40(sp)
    80003b60:	f062                	sd	s8,32(sp)
    80003b62:	ec66                	sd	s9,24(sp)
    80003b64:	e86a                	sd	s10,16(sp)
    80003b66:	e46e                	sd	s11,8(sp)
    80003b68:	1880                	addi	s0,sp,112
    80003b6a:	8b2a                	mv	s6,a0
    80003b6c:	8c2e                	mv	s8,a1
    80003b6e:	8ab2                	mv	s5,a2
    80003b70:	8936                	mv	s2,a3
    80003b72:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b74:	00e687bb          	addw	a5,a3,a4
    80003b78:	0ed7e263          	bltu	a5,a3,80003c5c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b7c:	00043737          	lui	a4,0x43
    80003b80:	0ef76063          	bltu	a4,a5,80003c60 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b84:	0c0b8863          	beqz	s7,80003c54 <writei+0x10e>
    80003b88:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b8e:	5cfd                	li	s9,-1
    80003b90:	a091                	j	80003bd4 <writei+0x8e>
    80003b92:	02099d93          	slli	s11,s3,0x20
    80003b96:	020ddd93          	srli	s11,s11,0x20
    80003b9a:	05848793          	addi	a5,s1,88
    80003b9e:	86ee                	mv	a3,s11
    80003ba0:	8656                	mv	a2,s5
    80003ba2:	85e2                	mv	a1,s8
    80003ba4:	953e                	add	a0,a0,a5
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	876080e7          	jalr	-1930(ra) # 8000241c <either_copyin>
    80003bae:	07950263          	beq	a0,s9,80003c12 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	794080e7          	jalr	1940(ra) # 80004348 <log_write>
    brelse(bp);
    80003bbc:	8526                	mv	a0,s1
    80003bbe:	fffff097          	auipc	ra,0xfffff
    80003bc2:	508080e7          	jalr	1288(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc6:	01498a3b          	addw	s4,s3,s4
    80003bca:	0129893b          	addw	s2,s3,s2
    80003bce:	9aee                	add	s5,s5,s11
    80003bd0:	057a7663          	bgeu	s4,s7,80003c1c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bd4:	000b2483          	lw	s1,0(s6)
    80003bd8:	00a9559b          	srliw	a1,s2,0xa
    80003bdc:	855a                	mv	a0,s6
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	7ac080e7          	jalr	1964(ra) # 8000338a <bmap>
    80003be6:	0005059b          	sext.w	a1,a0
    80003bea:	8526                	mv	a0,s1
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	3aa080e7          	jalr	938(ra) # 80002f96 <bread>
    80003bf4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf6:	3ff97513          	andi	a0,s2,1023
    80003bfa:	40ad07bb          	subw	a5,s10,a0
    80003bfe:	414b873b          	subw	a4,s7,s4
    80003c02:	89be                	mv	s3,a5
    80003c04:	2781                	sext.w	a5,a5
    80003c06:	0007069b          	sext.w	a3,a4
    80003c0a:	f8f6f4e3          	bgeu	a3,a5,80003b92 <writei+0x4c>
    80003c0e:	89ba                	mv	s3,a4
    80003c10:	b749                	j	80003b92 <writei+0x4c>
      brelse(bp);
    80003c12:	8526                	mv	a0,s1
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	4b2080e7          	jalr	1202(ra) # 800030c6 <brelse>
  }

  if(off > ip->size)
    80003c1c:	04cb2783          	lw	a5,76(s6)
    80003c20:	0127f463          	bgeu	a5,s2,80003c28 <writei+0xe2>
    ip->size = off;
    80003c24:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c28:	855a                	mv	a0,s6
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	aa6080e7          	jalr	-1370(ra) # 800036d0 <iupdate>

  return tot;
    80003c32:	000a051b          	sext.w	a0,s4
}
    80003c36:	70a6                	ld	ra,104(sp)
    80003c38:	7406                	ld	s0,96(sp)
    80003c3a:	64e6                	ld	s1,88(sp)
    80003c3c:	6946                	ld	s2,80(sp)
    80003c3e:	69a6                	ld	s3,72(sp)
    80003c40:	6a06                	ld	s4,64(sp)
    80003c42:	7ae2                	ld	s5,56(sp)
    80003c44:	7b42                	ld	s6,48(sp)
    80003c46:	7ba2                	ld	s7,40(sp)
    80003c48:	7c02                	ld	s8,32(sp)
    80003c4a:	6ce2                	ld	s9,24(sp)
    80003c4c:	6d42                	ld	s10,16(sp)
    80003c4e:	6da2                	ld	s11,8(sp)
    80003c50:	6165                	addi	sp,sp,112
    80003c52:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c54:	8a5e                	mv	s4,s7
    80003c56:	bfc9                	j	80003c28 <writei+0xe2>
    return -1;
    80003c58:	557d                	li	a0,-1
}
    80003c5a:	8082                	ret
    return -1;
    80003c5c:	557d                	li	a0,-1
    80003c5e:	bfe1                	j	80003c36 <writei+0xf0>
    return -1;
    80003c60:	557d                	li	a0,-1
    80003c62:	bfd1                	j	80003c36 <writei+0xf0>

0000000080003c64 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c64:	1141                	addi	sp,sp,-16
    80003c66:	e406                	sd	ra,8(sp)
    80003c68:	e022                	sd	s0,0(sp)
    80003c6a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c6c:	4639                	li	a2,14
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	128080e7          	jalr	296(ra) # 80000d96 <strncmp>
}
    80003c76:	60a2                	ld	ra,8(sp)
    80003c78:	6402                	ld	s0,0(sp)
    80003c7a:	0141                	addi	sp,sp,16
    80003c7c:	8082                	ret

0000000080003c7e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c7e:	7139                	addi	sp,sp,-64
    80003c80:	fc06                	sd	ra,56(sp)
    80003c82:	f822                	sd	s0,48(sp)
    80003c84:	f426                	sd	s1,40(sp)
    80003c86:	f04a                	sd	s2,32(sp)
    80003c88:	ec4e                	sd	s3,24(sp)
    80003c8a:	e852                	sd	s4,16(sp)
    80003c8c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c8e:	04451703          	lh	a4,68(a0)
    80003c92:	4785                	li	a5,1
    80003c94:	00f71a63          	bne	a4,a5,80003ca8 <dirlookup+0x2a>
    80003c98:	892a                	mv	s2,a0
    80003c9a:	89ae                	mv	s3,a1
    80003c9c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9e:	457c                	lw	a5,76(a0)
    80003ca0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ca2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca4:	e79d                	bnez	a5,80003cd2 <dirlookup+0x54>
    80003ca6:	a8a5                	j	80003d1e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca8:	00005517          	auipc	a0,0x5
    80003cac:	a3050513          	addi	a0,a0,-1488 # 800086d8 <syscalls+0x1a8>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	87a080e7          	jalr	-1926(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003cb8:	00005517          	auipc	a0,0x5
    80003cbc:	a3850513          	addi	a0,a0,-1480 # 800086f0 <syscalls+0x1c0>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	86a080e7          	jalr	-1942(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc8:	24c1                	addiw	s1,s1,16
    80003cca:	04c92783          	lw	a5,76(s2)
    80003cce:	04f4f763          	bgeu	s1,a5,80003d1c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cd2:	4741                	li	a4,16
    80003cd4:	86a6                	mv	a3,s1
    80003cd6:	fc040613          	addi	a2,s0,-64
    80003cda:	4581                	li	a1,0
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	d70080e7          	jalr	-656(ra) # 80003a4e <readi>
    80003ce6:	47c1                	li	a5,16
    80003ce8:	fcf518e3          	bne	a0,a5,80003cb8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cec:	fc045783          	lhu	a5,-64(s0)
    80003cf0:	dfe1                	beqz	a5,80003cc8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cf2:	fc240593          	addi	a1,s0,-62
    80003cf6:	854e                	mv	a0,s3
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	f6c080e7          	jalr	-148(ra) # 80003c64 <namecmp>
    80003d00:	f561                	bnez	a0,80003cc8 <dirlookup+0x4a>
      if(poff)
    80003d02:	000a0463          	beqz	s4,80003d0a <dirlookup+0x8c>
        *poff = off;
    80003d06:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d0a:	fc045583          	lhu	a1,-64(s0)
    80003d0e:	00092503          	lw	a0,0(s2)
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	754080e7          	jalr	1876(ra) # 80003466 <iget>
    80003d1a:	a011                	j	80003d1e <dirlookup+0xa0>
  return 0;
    80003d1c:	4501                	li	a0,0
}
    80003d1e:	70e2                	ld	ra,56(sp)
    80003d20:	7442                	ld	s0,48(sp)
    80003d22:	74a2                	ld	s1,40(sp)
    80003d24:	7902                	ld	s2,32(sp)
    80003d26:	69e2                	ld	s3,24(sp)
    80003d28:	6a42                	ld	s4,16(sp)
    80003d2a:	6121                	addi	sp,sp,64
    80003d2c:	8082                	ret

0000000080003d2e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d2e:	711d                	addi	sp,sp,-96
    80003d30:	ec86                	sd	ra,88(sp)
    80003d32:	e8a2                	sd	s0,80(sp)
    80003d34:	e4a6                	sd	s1,72(sp)
    80003d36:	e0ca                	sd	s2,64(sp)
    80003d38:	fc4e                	sd	s3,56(sp)
    80003d3a:	f852                	sd	s4,48(sp)
    80003d3c:	f456                	sd	s5,40(sp)
    80003d3e:	f05a                	sd	s6,32(sp)
    80003d40:	ec5e                	sd	s7,24(sp)
    80003d42:	e862                	sd	s8,16(sp)
    80003d44:	e466                	sd	s9,8(sp)
    80003d46:	1080                	addi	s0,sp,96
    80003d48:	84aa                	mv	s1,a0
    80003d4a:	8aae                	mv	s5,a1
    80003d4c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d4e:	00054703          	lbu	a4,0(a0)
    80003d52:	02f00793          	li	a5,47
    80003d56:	02f70363          	beq	a4,a5,80003d7c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d5a:	ffffe097          	auipc	ra,0xffffe
    80003d5e:	c24080e7          	jalr	-988(ra) # 8000197e <myproc>
    80003d62:	15853503          	ld	a0,344(a0)
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	9f6080e7          	jalr	-1546(ra) # 8000375c <idup>
    80003d6e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d70:	02f00913          	li	s2,47
  len = path - s;
    80003d74:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d76:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d78:	4b85                	li	s7,1
    80003d7a:	a865                	j	80003e32 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d7c:	4585                	li	a1,1
    80003d7e:	4505                	li	a0,1
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	6e6080e7          	jalr	1766(ra) # 80003466 <iget>
    80003d88:	89aa                	mv	s3,a0
    80003d8a:	b7dd                	j	80003d70 <namex+0x42>
      iunlockput(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	c6e080e7          	jalr	-914(ra) # 800039fc <iunlockput>
      return 0;
    80003d96:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d98:	854e                	mv	a0,s3
    80003d9a:	60e6                	ld	ra,88(sp)
    80003d9c:	6446                	ld	s0,80(sp)
    80003d9e:	64a6                	ld	s1,72(sp)
    80003da0:	6906                	ld	s2,64(sp)
    80003da2:	79e2                	ld	s3,56(sp)
    80003da4:	7a42                	ld	s4,48(sp)
    80003da6:	7aa2                	ld	s5,40(sp)
    80003da8:	7b02                	ld	s6,32(sp)
    80003daa:	6be2                	ld	s7,24(sp)
    80003dac:	6c42                	ld	s8,16(sp)
    80003dae:	6ca2                	ld	s9,8(sp)
    80003db0:	6125                	addi	sp,sp,96
    80003db2:	8082                	ret
      iunlock(ip);
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	aa6080e7          	jalr	-1370(ra) # 8000385c <iunlock>
      return ip;
    80003dbe:	bfe9                	j	80003d98 <namex+0x6a>
      iunlockput(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	c3a080e7          	jalr	-966(ra) # 800039fc <iunlockput>
      return 0;
    80003dca:	89e6                	mv	s3,s9
    80003dcc:	b7f1                	j	80003d98 <namex+0x6a>
  len = path - s;
    80003dce:	40b48633          	sub	a2,s1,a1
    80003dd2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003dd6:	099c5463          	bge	s8,s9,80003e5e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dda:	4639                	li	a2,14
    80003ddc:	8552                	mv	a0,s4
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	f3c080e7          	jalr	-196(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	01279763          	bne	a5,s2,80003df8 <namex+0xca>
    path++;
    80003dee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	ff278de3          	beq	a5,s2,80003dee <namex+0xc0>
    ilock(ip);
    80003df8:	854e                	mv	a0,s3
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	9a0080e7          	jalr	-1632(ra) # 8000379a <ilock>
    if(ip->type != T_DIR){
    80003e02:	04499783          	lh	a5,68(s3)
    80003e06:	f97793e3          	bne	a5,s7,80003d8c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e0a:	000a8563          	beqz	s5,80003e14 <namex+0xe6>
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	d3cd                	beqz	a5,80003db4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e14:	865a                	mv	a2,s6
    80003e16:	85d2                	mv	a1,s4
    80003e18:	854e                	mv	a0,s3
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	e64080e7          	jalr	-412(ra) # 80003c7e <dirlookup>
    80003e22:	8caa                	mv	s9,a0
    80003e24:	dd51                	beqz	a0,80003dc0 <namex+0x92>
    iunlockput(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	bd4080e7          	jalr	-1068(ra) # 800039fc <iunlockput>
    ip = next;
    80003e30:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e32:	0004c783          	lbu	a5,0(s1)
    80003e36:	05279763          	bne	a5,s2,80003e84 <namex+0x156>
    path++;
    80003e3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e3c:	0004c783          	lbu	a5,0(s1)
    80003e40:	ff278de3          	beq	a5,s2,80003e3a <namex+0x10c>
  if(*path == 0)
    80003e44:	c79d                	beqz	a5,80003e72 <namex+0x144>
    path++;
    80003e46:	85a6                	mv	a1,s1
  len = path - s;
    80003e48:	8cda                	mv	s9,s6
    80003e4a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e4c:	01278963          	beq	a5,s2,80003e5e <namex+0x130>
    80003e50:	dfbd                	beqz	a5,80003dce <namex+0xa0>
    path++;
    80003e52:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e54:	0004c783          	lbu	a5,0(s1)
    80003e58:	ff279ce3          	bne	a5,s2,80003e50 <namex+0x122>
    80003e5c:	bf8d                	j	80003dce <namex+0xa0>
    memmove(name, s, len);
    80003e5e:	2601                	sext.w	a2,a2
    80003e60:	8552                	mv	a0,s4
    80003e62:	ffffd097          	auipc	ra,0xffffd
    80003e66:	eb8080e7          	jalr	-328(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003e6a:	9cd2                	add	s9,s9,s4
    80003e6c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e70:	bf9d                	j	80003de6 <namex+0xb8>
  if(nameiparent){
    80003e72:	f20a83e3          	beqz	s5,80003d98 <namex+0x6a>
    iput(ip);
    80003e76:	854e                	mv	a0,s3
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	adc080e7          	jalr	-1316(ra) # 80003954 <iput>
    return 0;
    80003e80:	4981                	li	s3,0
    80003e82:	bf19                	j	80003d98 <namex+0x6a>
  if(*path == 0)
    80003e84:	d7fd                	beqz	a5,80003e72 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	85a6                	mv	a1,s1
    80003e8c:	b7d1                	j	80003e50 <namex+0x122>

0000000080003e8e <dirlink>:
{
    80003e8e:	7139                	addi	sp,sp,-64
    80003e90:	fc06                	sd	ra,56(sp)
    80003e92:	f822                	sd	s0,48(sp)
    80003e94:	f426                	sd	s1,40(sp)
    80003e96:	f04a                	sd	s2,32(sp)
    80003e98:	ec4e                	sd	s3,24(sp)
    80003e9a:	e852                	sd	s4,16(sp)
    80003e9c:	0080                	addi	s0,sp,64
    80003e9e:	892a                	mv	s2,a0
    80003ea0:	8a2e                	mv	s4,a1
    80003ea2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ea4:	4601                	li	a2,0
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	dd8080e7          	jalr	-552(ra) # 80003c7e <dirlookup>
    80003eae:	e93d                	bnez	a0,80003f24 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	04c92483          	lw	s1,76(s2)
    80003eb4:	c49d                	beqz	s1,80003ee2 <dirlink+0x54>
    80003eb6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb8:	4741                	li	a4,16
    80003eba:	86a6                	mv	a3,s1
    80003ebc:	fc040613          	addi	a2,s0,-64
    80003ec0:	4581                	li	a1,0
    80003ec2:	854a                	mv	a0,s2
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	b8a080e7          	jalr	-1142(ra) # 80003a4e <readi>
    80003ecc:	47c1                	li	a5,16
    80003ece:	06f51163          	bne	a0,a5,80003f30 <dirlink+0xa2>
    if(de.inum == 0)
    80003ed2:	fc045783          	lhu	a5,-64(s0)
    80003ed6:	c791                	beqz	a5,80003ee2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed8:	24c1                	addiw	s1,s1,16
    80003eda:	04c92783          	lw	a5,76(s2)
    80003ede:	fcf4ede3          	bltu	s1,a5,80003eb8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ee2:	4639                	li	a2,14
    80003ee4:	85d2                	mv	a1,s4
    80003ee6:	fc240513          	addi	a0,s0,-62
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	ee8080e7          	jalr	-280(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003ef2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef6:	4741                	li	a4,16
    80003ef8:	86a6                	mv	a3,s1
    80003efa:	fc040613          	addi	a2,s0,-64
    80003efe:	4581                	li	a1,0
    80003f00:	854a                	mv	a0,s2
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	c44080e7          	jalr	-956(ra) # 80003b46 <writei>
    80003f0a:	872a                	mv	a4,a0
    80003f0c:	47c1                	li	a5,16
  return 0;
    80003f0e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f10:	02f71863          	bne	a4,a5,80003f40 <dirlink+0xb2>
}
    80003f14:	70e2                	ld	ra,56(sp)
    80003f16:	7442                	ld	s0,48(sp)
    80003f18:	74a2                	ld	s1,40(sp)
    80003f1a:	7902                	ld	s2,32(sp)
    80003f1c:	69e2                	ld	s3,24(sp)
    80003f1e:	6a42                	ld	s4,16(sp)
    80003f20:	6121                	addi	sp,sp,64
    80003f22:	8082                	ret
    iput(ip);
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	a30080e7          	jalr	-1488(ra) # 80003954 <iput>
    return -1;
    80003f2c:	557d                	li	a0,-1
    80003f2e:	b7dd                	j	80003f14 <dirlink+0x86>
      panic("dirlink read");
    80003f30:	00004517          	auipc	a0,0x4
    80003f34:	7d050513          	addi	a0,a0,2000 # 80008700 <syscalls+0x1d0>
    80003f38:	ffffc097          	auipc	ra,0xffffc
    80003f3c:	5f2080e7          	jalr	1522(ra) # 8000052a <panic>
    panic("dirlink");
    80003f40:	00005517          	auipc	a0,0x5
    80003f44:	8c850513          	addi	a0,a0,-1848 # 80008808 <syscalls+0x2d8>
    80003f48:	ffffc097          	auipc	ra,0xffffc
    80003f4c:	5e2080e7          	jalr	1506(ra) # 8000052a <panic>

0000000080003f50 <namei>:

struct inode*
namei(char *path)
{
    80003f50:	1101                	addi	sp,sp,-32
    80003f52:	ec06                	sd	ra,24(sp)
    80003f54:	e822                	sd	s0,16(sp)
    80003f56:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f58:	fe040613          	addi	a2,s0,-32
    80003f5c:	4581                	li	a1,0
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	dd0080e7          	jalr	-560(ra) # 80003d2e <namex>
}
    80003f66:	60e2                	ld	ra,24(sp)
    80003f68:	6442                	ld	s0,16(sp)
    80003f6a:	6105                	addi	sp,sp,32
    80003f6c:	8082                	ret

0000000080003f6e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f6e:	1141                	addi	sp,sp,-16
    80003f70:	e406                	sd	ra,8(sp)
    80003f72:	e022                	sd	s0,0(sp)
    80003f74:	0800                	addi	s0,sp,16
    80003f76:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f78:	4585                	li	a1,1
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	db4080e7          	jalr	-588(ra) # 80003d2e <namex>
}
    80003f82:	60a2                	ld	ra,8(sp)
    80003f84:	6402                	ld	s0,0(sp)
    80003f86:	0141                	addi	sp,sp,16
    80003f88:	8082                	ret

0000000080003f8a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f8a:	1101                	addi	sp,sp,-32
    80003f8c:	ec06                	sd	ra,24(sp)
    80003f8e:	e822                	sd	s0,16(sp)
    80003f90:	e426                	sd	s1,8(sp)
    80003f92:	e04a                	sd	s2,0(sp)
    80003f94:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f96:	0001d917          	auipc	s2,0x1d
    80003f9a:	4da90913          	addi	s2,s2,1242 # 80021470 <log>
    80003f9e:	01892583          	lw	a1,24(s2)
    80003fa2:	02892503          	lw	a0,40(s2)
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	ff0080e7          	jalr	-16(ra) # 80002f96 <bread>
    80003fae:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb0:	02c92683          	lw	a3,44(s2)
    80003fb4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fb6:	02d05863          	blez	a3,80003fe6 <write_head+0x5c>
    80003fba:	0001d797          	auipc	a5,0x1d
    80003fbe:	4e678793          	addi	a5,a5,1254 # 800214a0 <log+0x30>
    80003fc2:	05c50713          	addi	a4,a0,92
    80003fc6:	36fd                	addiw	a3,a3,-1
    80003fc8:	02069613          	slli	a2,a3,0x20
    80003fcc:	01e65693          	srli	a3,a2,0x1e
    80003fd0:	0001d617          	auipc	a2,0x1d
    80003fd4:	4d460613          	addi	a2,a2,1236 # 800214a4 <log+0x34>
    80003fd8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fda:	4390                	lw	a2,0(a5)
    80003fdc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fde:	0791                	addi	a5,a5,4
    80003fe0:	0711                	addi	a4,a4,4
    80003fe2:	fed79ce3          	bne	a5,a3,80003fda <write_head+0x50>
  }
  bwrite(buf);
    80003fe6:	8526                	mv	a0,s1
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	0a0080e7          	jalr	160(ra) # 80003088 <bwrite>
  brelse(buf);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	0d4080e7          	jalr	212(ra) # 800030c6 <brelse>
}
    80003ffa:	60e2                	ld	ra,24(sp)
    80003ffc:	6442                	ld	s0,16(sp)
    80003ffe:	64a2                	ld	s1,8(sp)
    80004000:	6902                	ld	s2,0(sp)
    80004002:	6105                	addi	sp,sp,32
    80004004:	8082                	ret

0000000080004006 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004006:	0001d797          	auipc	a5,0x1d
    8000400a:	4967a783          	lw	a5,1174(a5) # 8002149c <log+0x2c>
    8000400e:	0af05d63          	blez	a5,800040c8 <install_trans+0xc2>
{
    80004012:	7139                	addi	sp,sp,-64
    80004014:	fc06                	sd	ra,56(sp)
    80004016:	f822                	sd	s0,48(sp)
    80004018:	f426                	sd	s1,40(sp)
    8000401a:	f04a                	sd	s2,32(sp)
    8000401c:	ec4e                	sd	s3,24(sp)
    8000401e:	e852                	sd	s4,16(sp)
    80004020:	e456                	sd	s5,8(sp)
    80004022:	e05a                	sd	s6,0(sp)
    80004024:	0080                	addi	s0,sp,64
    80004026:	8b2a                	mv	s6,a0
    80004028:	0001da97          	auipc	s5,0x1d
    8000402c:	478a8a93          	addi	s5,s5,1144 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004030:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004032:	0001d997          	auipc	s3,0x1d
    80004036:	43e98993          	addi	s3,s3,1086 # 80021470 <log>
    8000403a:	a00d                	j	8000405c <install_trans+0x56>
    brelse(lbuf);
    8000403c:	854a                	mv	a0,s2
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	088080e7          	jalr	136(ra) # 800030c6 <brelse>
    brelse(dbuf);
    80004046:	8526                	mv	a0,s1
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	07e080e7          	jalr	126(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004050:	2a05                	addiw	s4,s4,1
    80004052:	0a91                	addi	s5,s5,4
    80004054:	02c9a783          	lw	a5,44(s3)
    80004058:	04fa5e63          	bge	s4,a5,800040b4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000405c:	0189a583          	lw	a1,24(s3)
    80004060:	014585bb          	addw	a1,a1,s4
    80004064:	2585                	addiw	a1,a1,1
    80004066:	0289a503          	lw	a0,40(s3)
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	f2c080e7          	jalr	-212(ra) # 80002f96 <bread>
    80004072:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004074:	000aa583          	lw	a1,0(s5)
    80004078:	0289a503          	lw	a0,40(s3)
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	f1a080e7          	jalr	-230(ra) # 80002f96 <bread>
    80004084:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004086:	40000613          	li	a2,1024
    8000408a:	05890593          	addi	a1,s2,88
    8000408e:	05850513          	addi	a0,a0,88
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	c88080e7          	jalr	-888(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000409a:	8526                	mv	a0,s1
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	fec080e7          	jalr	-20(ra) # 80003088 <bwrite>
    if(recovering == 0)
    800040a4:	f80b1ce3          	bnez	s6,8000403c <install_trans+0x36>
      bunpin(dbuf);
    800040a8:	8526                	mv	a0,s1
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	0f6080e7          	jalr	246(ra) # 800031a0 <bunpin>
    800040b2:	b769                	j	8000403c <install_trans+0x36>
}
    800040b4:	70e2                	ld	ra,56(sp)
    800040b6:	7442                	ld	s0,48(sp)
    800040b8:	74a2                	ld	s1,40(sp)
    800040ba:	7902                	ld	s2,32(sp)
    800040bc:	69e2                	ld	s3,24(sp)
    800040be:	6a42                	ld	s4,16(sp)
    800040c0:	6aa2                	ld	s5,8(sp)
    800040c2:	6b02                	ld	s6,0(sp)
    800040c4:	6121                	addi	sp,sp,64
    800040c6:	8082                	ret
    800040c8:	8082                	ret

00000000800040ca <initlog>:
{
    800040ca:	7179                	addi	sp,sp,-48
    800040cc:	f406                	sd	ra,40(sp)
    800040ce:	f022                	sd	s0,32(sp)
    800040d0:	ec26                	sd	s1,24(sp)
    800040d2:	e84a                	sd	s2,16(sp)
    800040d4:	e44e                	sd	s3,8(sp)
    800040d6:	1800                	addi	s0,sp,48
    800040d8:	892a                	mv	s2,a0
    800040da:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040dc:	0001d497          	auipc	s1,0x1d
    800040e0:	39448493          	addi	s1,s1,916 # 80021470 <log>
    800040e4:	00004597          	auipc	a1,0x4
    800040e8:	62c58593          	addi	a1,a1,1580 # 80008710 <syscalls+0x1e0>
    800040ec:	8526                	mv	a0,s1
    800040ee:	ffffd097          	auipc	ra,0xffffd
    800040f2:	a44080e7          	jalr	-1468(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    800040f6:	0149a583          	lw	a1,20(s3)
    800040fa:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040fc:	0109a783          	lw	a5,16(s3)
    80004100:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004102:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004106:	854a                	mv	a0,s2
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	e8e080e7          	jalr	-370(ra) # 80002f96 <bread>
  log.lh.n = lh->n;
    80004110:	4d34                	lw	a3,88(a0)
    80004112:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004114:	02d05663          	blez	a3,80004140 <initlog+0x76>
    80004118:	05c50793          	addi	a5,a0,92
    8000411c:	0001d717          	auipc	a4,0x1d
    80004120:	38470713          	addi	a4,a4,900 # 800214a0 <log+0x30>
    80004124:	36fd                	addiw	a3,a3,-1
    80004126:	02069613          	slli	a2,a3,0x20
    8000412a:	01e65693          	srli	a3,a2,0x1e
    8000412e:	06050613          	addi	a2,a0,96
    80004132:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004134:	4390                	lw	a2,0(a5)
    80004136:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004138:	0791                	addi	a5,a5,4
    8000413a:	0711                	addi	a4,a4,4
    8000413c:	fed79ce3          	bne	a5,a3,80004134 <initlog+0x6a>
  brelse(buf);
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	f86080e7          	jalr	-122(ra) # 800030c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004148:	4505                	li	a0,1
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	ebc080e7          	jalr	-324(ra) # 80004006 <install_trans>
  log.lh.n = 0;
    80004152:	0001d797          	auipc	a5,0x1d
    80004156:	3407a523          	sw	zero,842(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	e30080e7          	jalr	-464(ra) # 80003f8a <write_head>
}
    80004162:	70a2                	ld	ra,40(sp)
    80004164:	7402                	ld	s0,32(sp)
    80004166:	64e2                	ld	s1,24(sp)
    80004168:	6942                	ld	s2,16(sp)
    8000416a:	69a2                	ld	s3,8(sp)
    8000416c:	6145                	addi	sp,sp,48
    8000416e:	8082                	ret

0000000080004170 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004170:	1101                	addi	sp,sp,-32
    80004172:	ec06                	sd	ra,24(sp)
    80004174:	e822                	sd	s0,16(sp)
    80004176:	e426                	sd	s1,8(sp)
    80004178:	e04a                	sd	s2,0(sp)
    8000417a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000417c:	0001d517          	auipc	a0,0x1d
    80004180:	2f450513          	addi	a0,a0,756 # 80021470 <log>
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    8000418c:	0001d497          	auipc	s1,0x1d
    80004190:	2e448493          	addi	s1,s1,740 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004194:	4979                	li	s2,30
    80004196:	a039                	j	800041a4 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004198:	85a6                	mv	a1,s1
    8000419a:	8526                	mv	a0,s1
    8000419c:	ffffe097          	auipc	ra,0xffffe
    800041a0:	e26080e7          	jalr	-474(ra) # 80001fc2 <sleep>
    if(log.committing){
    800041a4:	50dc                	lw	a5,36(s1)
    800041a6:	fbed                	bnez	a5,80004198 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a8:	509c                	lw	a5,32(s1)
    800041aa:	0017871b          	addiw	a4,a5,1
    800041ae:	0007069b          	sext.w	a3,a4
    800041b2:	0027179b          	slliw	a5,a4,0x2
    800041b6:	9fb9                	addw	a5,a5,a4
    800041b8:	0017979b          	slliw	a5,a5,0x1
    800041bc:	54d8                	lw	a4,44(s1)
    800041be:	9fb9                	addw	a5,a5,a4
    800041c0:	00f95963          	bge	s2,a5,800041d2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041c4:	85a6                	mv	a1,s1
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffe097          	auipc	ra,0xffffe
    800041cc:	dfa080e7          	jalr	-518(ra) # 80001fc2 <sleep>
    800041d0:	bfd1                	j	800041a4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041d2:	0001d517          	auipc	a0,0x1d
    800041d6:	29e50513          	addi	a0,a0,670 # 80021470 <log>
    800041da:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	a9a080e7          	jalr	-1382(ra) # 80000c76 <release>
      break;
    }
  }
}
    800041e4:	60e2                	ld	ra,24(sp)
    800041e6:	6442                	ld	s0,16(sp)
    800041e8:	64a2                	ld	s1,8(sp)
    800041ea:	6902                	ld	s2,0(sp)
    800041ec:	6105                	addi	sp,sp,32
    800041ee:	8082                	ret

00000000800041f0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f0:	7139                	addi	sp,sp,-64
    800041f2:	fc06                	sd	ra,56(sp)
    800041f4:	f822                	sd	s0,48(sp)
    800041f6:	f426                	sd	s1,40(sp)
    800041f8:	f04a                	sd	s2,32(sp)
    800041fa:	ec4e                	sd	s3,24(sp)
    800041fc:	e852                	sd	s4,16(sp)
    800041fe:	e456                	sd	s5,8(sp)
    80004200:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004202:	0001d497          	auipc	s1,0x1d
    80004206:	26e48493          	addi	s1,s1,622 # 80021470 <log>
    8000420a:	8526                	mv	a0,s1
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	9b6080e7          	jalr	-1610(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004214:	509c                	lw	a5,32(s1)
    80004216:	37fd                	addiw	a5,a5,-1
    80004218:	0007891b          	sext.w	s2,a5
    8000421c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000421e:	50dc                	lw	a5,36(s1)
    80004220:	e7b9                	bnez	a5,8000426e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004222:	04091e63          	bnez	s2,8000427e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004226:	0001d497          	auipc	s1,0x1d
    8000422a:	24a48493          	addi	s1,s1,586 # 80021470 <log>
    8000422e:	4785                	li	a5,1
    80004230:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004232:	8526                	mv	a0,s1
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	a42080e7          	jalr	-1470(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000423c:	54dc                	lw	a5,44(s1)
    8000423e:	06f04763          	bgtz	a5,800042ac <end_op+0xbc>
    acquire(&log.lock);
    80004242:	0001d497          	auipc	s1,0x1d
    80004246:	22e48493          	addi	s1,s1,558 # 80021470 <log>
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	976080e7          	jalr	-1674(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004254:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004258:	8526                	mv	a0,s1
    8000425a:	ffffe097          	auipc	ra,0xffffe
    8000425e:	ef4080e7          	jalr	-268(ra) # 8000214e <wakeup>
    release(&log.lock);
    80004262:	8526                	mv	a0,s1
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	a12080e7          	jalr	-1518(ra) # 80000c76 <release>
}
    8000426c:	a03d                	j	8000429a <end_op+0xaa>
    panic("log.committing");
    8000426e:	00004517          	auipc	a0,0x4
    80004272:	4aa50513          	addi	a0,a0,1194 # 80008718 <syscalls+0x1e8>
    80004276:	ffffc097          	auipc	ra,0xffffc
    8000427a:	2b4080e7          	jalr	692(ra) # 8000052a <panic>
    wakeup(&log);
    8000427e:	0001d497          	auipc	s1,0x1d
    80004282:	1f248493          	addi	s1,s1,498 # 80021470 <log>
    80004286:	8526                	mv	a0,s1
    80004288:	ffffe097          	auipc	ra,0xffffe
    8000428c:	ec6080e7          	jalr	-314(ra) # 8000214e <wakeup>
  release(&log.lock);
    80004290:	8526                	mv	a0,s1
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	9e4080e7          	jalr	-1564(ra) # 80000c76 <release>
}
    8000429a:	70e2                	ld	ra,56(sp)
    8000429c:	7442                	ld	s0,48(sp)
    8000429e:	74a2                	ld	s1,40(sp)
    800042a0:	7902                	ld	s2,32(sp)
    800042a2:	69e2                	ld	s3,24(sp)
    800042a4:	6a42                	ld	s4,16(sp)
    800042a6:	6aa2                	ld	s5,8(sp)
    800042a8:	6121                	addi	sp,sp,64
    800042aa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ac:	0001da97          	auipc	s5,0x1d
    800042b0:	1f4a8a93          	addi	s5,s5,500 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042b4:	0001da17          	auipc	s4,0x1d
    800042b8:	1bca0a13          	addi	s4,s4,444 # 80021470 <log>
    800042bc:	018a2583          	lw	a1,24(s4)
    800042c0:	012585bb          	addw	a1,a1,s2
    800042c4:	2585                	addiw	a1,a1,1
    800042c6:	028a2503          	lw	a0,40(s4)
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	ccc080e7          	jalr	-820(ra) # 80002f96 <bread>
    800042d2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042d4:	000aa583          	lw	a1,0(s5)
    800042d8:	028a2503          	lw	a0,40(s4)
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	cba080e7          	jalr	-838(ra) # 80002f96 <bread>
    800042e4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042e6:	40000613          	li	a2,1024
    800042ea:	05850593          	addi	a1,a0,88
    800042ee:	05848513          	addi	a0,s1,88
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	a28080e7          	jalr	-1496(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    800042fa:	8526                	mv	a0,s1
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	d8c080e7          	jalr	-628(ra) # 80003088 <bwrite>
    brelse(from);
    80004304:	854e                	mv	a0,s3
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	dc0080e7          	jalr	-576(ra) # 800030c6 <brelse>
    brelse(to);
    8000430e:	8526                	mv	a0,s1
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	db6080e7          	jalr	-586(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004318:	2905                	addiw	s2,s2,1
    8000431a:	0a91                	addi	s5,s5,4
    8000431c:	02ca2783          	lw	a5,44(s4)
    80004320:	f8f94ee3          	blt	s2,a5,800042bc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004324:	00000097          	auipc	ra,0x0
    80004328:	c66080e7          	jalr	-922(ra) # 80003f8a <write_head>
    install_trans(0); // Now install writes to home locations
    8000432c:	4501                	li	a0,0
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	cd8080e7          	jalr	-808(ra) # 80004006 <install_trans>
    log.lh.n = 0;
    80004336:	0001d797          	auipc	a5,0x1d
    8000433a:	1607a323          	sw	zero,358(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	c4c080e7          	jalr	-948(ra) # 80003f8a <write_head>
    80004346:	bdf5                	j	80004242 <end_op+0x52>

0000000080004348 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004348:	1101                	addi	sp,sp,-32
    8000434a:	ec06                	sd	ra,24(sp)
    8000434c:	e822                	sd	s0,16(sp)
    8000434e:	e426                	sd	s1,8(sp)
    80004350:	e04a                	sd	s2,0(sp)
    80004352:	1000                	addi	s0,sp,32
    80004354:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004356:	0001d917          	auipc	s2,0x1d
    8000435a:	11a90913          	addi	s2,s2,282 # 80021470 <log>
    8000435e:	854a                	mv	a0,s2
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	862080e7          	jalr	-1950(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004368:	02c92603          	lw	a2,44(s2)
    8000436c:	47f5                	li	a5,29
    8000436e:	06c7c563          	blt	a5,a2,800043d8 <log_write+0x90>
    80004372:	0001d797          	auipc	a5,0x1d
    80004376:	11a7a783          	lw	a5,282(a5) # 8002148c <log+0x1c>
    8000437a:	37fd                	addiw	a5,a5,-1
    8000437c:	04f65e63          	bge	a2,a5,800043d8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004380:	0001d797          	auipc	a5,0x1d
    80004384:	1107a783          	lw	a5,272(a5) # 80021490 <log+0x20>
    80004388:	06f05063          	blez	a5,800043e8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000438c:	4781                	li	a5,0
    8000438e:	06c05563          	blez	a2,800043f8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004392:	44cc                	lw	a1,12(s1)
    80004394:	0001d717          	auipc	a4,0x1d
    80004398:	10c70713          	addi	a4,a4,268 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000439c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000439e:	4314                	lw	a3,0(a4)
    800043a0:	04b68c63          	beq	a3,a1,800043f8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	2785                	addiw	a5,a5,1
    800043a6:	0711                	addi	a4,a4,4
    800043a8:	fef61be3          	bne	a2,a5,8000439e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ac:	0621                	addi	a2,a2,8
    800043ae:	060a                	slli	a2,a2,0x2
    800043b0:	0001d797          	auipc	a5,0x1d
    800043b4:	0c078793          	addi	a5,a5,192 # 80021470 <log>
    800043b8:	963e                	add	a2,a2,a5
    800043ba:	44dc                	lw	a5,12(s1)
    800043bc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043be:	8526                	mv	a0,s1
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	da4080e7          	jalr	-604(ra) # 80003164 <bpin>
    log.lh.n++;
    800043c8:	0001d717          	auipc	a4,0x1d
    800043cc:	0a870713          	addi	a4,a4,168 # 80021470 <log>
    800043d0:	575c                	lw	a5,44(a4)
    800043d2:	2785                	addiw	a5,a5,1
    800043d4:	d75c                	sw	a5,44(a4)
    800043d6:	a835                	j	80004412 <log_write+0xca>
    panic("too big a transaction");
    800043d8:	00004517          	auipc	a0,0x4
    800043dc:	35050513          	addi	a0,a0,848 # 80008728 <syscalls+0x1f8>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	14a080e7          	jalr	330(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800043e8:	00004517          	auipc	a0,0x4
    800043ec:	35850513          	addi	a0,a0,856 # 80008740 <syscalls+0x210>
    800043f0:	ffffc097          	auipc	ra,0xffffc
    800043f4:	13a080e7          	jalr	314(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800043f8:	00878713          	addi	a4,a5,8
    800043fc:	00271693          	slli	a3,a4,0x2
    80004400:	0001d717          	auipc	a4,0x1d
    80004404:	07070713          	addi	a4,a4,112 # 80021470 <log>
    80004408:	9736                	add	a4,a4,a3
    8000440a:	44d4                	lw	a3,12(s1)
    8000440c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000440e:	faf608e3          	beq	a2,a5,800043be <log_write+0x76>
  }
  release(&log.lock);
    80004412:	0001d517          	auipc	a0,0x1d
    80004416:	05e50513          	addi	a0,a0,94 # 80021470 <log>
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	85c080e7          	jalr	-1956(ra) # 80000c76 <release>
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec06                	sd	ra,24(sp)
    80004432:	e822                	sd	s0,16(sp)
    80004434:	e426                	sd	s1,8(sp)
    80004436:	e04a                	sd	s2,0(sp)
    80004438:	1000                	addi	s0,sp,32
    8000443a:	84aa                	mv	s1,a0
    8000443c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000443e:	00004597          	auipc	a1,0x4
    80004442:	32258593          	addi	a1,a1,802 # 80008760 <syscalls+0x230>
    80004446:	0521                	addi	a0,a0,8
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	6ea080e7          	jalr	1770(ra) # 80000b32 <initlock>
  lk->name = name;
    80004450:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004454:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004458:	0204a423          	sw	zero,40(s1)
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004468:	1101                	addi	sp,sp,-32
    8000446a:	ec06                	sd	ra,24(sp)
    8000446c:	e822                	sd	s0,16(sp)
    8000446e:	e426                	sd	s1,8(sp)
    80004470:	e04a                	sd	s2,0(sp)
    80004472:	1000                	addi	s0,sp,32
    80004474:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	746080e7          	jalr	1862(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004484:	409c                	lw	a5,0(s1)
    80004486:	cb89                	beqz	a5,80004498 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004488:	85ca                	mv	a1,s2
    8000448a:	8526                	mv	a0,s1
    8000448c:	ffffe097          	auipc	ra,0xffffe
    80004490:	b36080e7          	jalr	-1226(ra) # 80001fc2 <sleep>
  while (lk->locked) {
    80004494:	409c                	lw	a5,0(s1)
    80004496:	fbed                	bnez	a5,80004488 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004498:	4785                	li	a5,1
    8000449a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	4e2080e7          	jalr	1250(ra) # 8000197e <myproc>
    800044a4:	591c                	lw	a5,48(a0)
    800044a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a8:	854a                	mv	a0,s2
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	7cc080e7          	jalr	1996(ra) # 80000c76 <release>
}
    800044b2:	60e2                	ld	ra,24(sp)
    800044b4:	6442                	ld	s0,16(sp)
    800044b6:	64a2                	ld	s1,8(sp)
    800044b8:	6902                	ld	s2,0(sp)
    800044ba:	6105                	addi	sp,sp,32
    800044bc:	8082                	ret

00000000800044be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	e04a                	sd	s2,0(sp)
    800044c8:	1000                	addi	s0,sp,32
    800044ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044cc:	00850913          	addi	s2,a0,8
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	6f0080e7          	jalr	1776(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800044da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044e2:	8526                	mv	a0,s1
    800044e4:	ffffe097          	auipc	ra,0xffffe
    800044e8:	c6a080e7          	jalr	-918(ra) # 8000214e <wakeup>
  release(&lk->lk);
    800044ec:	854a                	mv	a0,s2
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	788080e7          	jalr	1928(ra) # 80000c76 <release>
}
    800044f6:	60e2                	ld	ra,24(sp)
    800044f8:	6442                	ld	s0,16(sp)
    800044fa:	64a2                	ld	s1,8(sp)
    800044fc:	6902                	ld	s2,0(sp)
    800044fe:	6105                	addi	sp,sp,32
    80004500:	8082                	ret

0000000080004502 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004502:	7179                	addi	sp,sp,-48
    80004504:	f406                	sd	ra,40(sp)
    80004506:	f022                	sd	s0,32(sp)
    80004508:	ec26                	sd	s1,24(sp)
    8000450a:	e84a                	sd	s2,16(sp)
    8000450c:	e44e                	sd	s3,8(sp)
    8000450e:	1800                	addi	s0,sp,48
    80004510:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004512:	00850913          	addi	s2,a0,8
    80004516:	854a                	mv	a0,s2
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	6aa080e7          	jalr	1706(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004520:	409c                	lw	a5,0(s1)
    80004522:	ef99                	bnez	a5,80004540 <holdingsleep+0x3e>
    80004524:	4481                	li	s1,0
  release(&lk->lk);
    80004526:	854a                	mv	a0,s2
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	74e080e7          	jalr	1870(ra) # 80000c76 <release>
  return r;
}
    80004530:	8526                	mv	a0,s1
    80004532:	70a2                	ld	ra,40(sp)
    80004534:	7402                	ld	s0,32(sp)
    80004536:	64e2                	ld	s1,24(sp)
    80004538:	6942                	ld	s2,16(sp)
    8000453a:	69a2                	ld	s3,8(sp)
    8000453c:	6145                	addi	sp,sp,48
    8000453e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004540:	0284a983          	lw	s3,40(s1)
    80004544:	ffffd097          	auipc	ra,0xffffd
    80004548:	43a080e7          	jalr	1082(ra) # 8000197e <myproc>
    8000454c:	5904                	lw	s1,48(a0)
    8000454e:	413484b3          	sub	s1,s1,s3
    80004552:	0014b493          	seqz	s1,s1
    80004556:	bfc1                	j	80004526 <holdingsleep+0x24>

0000000080004558 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004558:	1141                	addi	sp,sp,-16
    8000455a:	e406                	sd	ra,8(sp)
    8000455c:	e022                	sd	s0,0(sp)
    8000455e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004560:	00004597          	auipc	a1,0x4
    80004564:	21058593          	addi	a1,a1,528 # 80008770 <syscalls+0x240>
    80004568:	0001d517          	auipc	a0,0x1d
    8000456c:	05050513          	addi	a0,a0,80 # 800215b8 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	5c2080e7          	jalr	1474(ra) # 80000b32 <initlock>
}
    80004578:	60a2                	ld	ra,8(sp)
    8000457a:	6402                	ld	s0,0(sp)
    8000457c:	0141                	addi	sp,sp,16
    8000457e:	8082                	ret

0000000080004580 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	e426                	sd	s1,8(sp)
    80004588:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000458a:	0001d517          	auipc	a0,0x1d
    8000458e:	02e50513          	addi	a0,a0,46 # 800215b8 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	630080e7          	jalr	1584(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459a:	0001d497          	auipc	s1,0x1d
    8000459e:	03648493          	addi	s1,s1,54 # 800215d0 <ftable+0x18>
    800045a2:	0001e717          	auipc	a4,0x1e
    800045a6:	fce70713          	addi	a4,a4,-50 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    800045aa:	40dc                	lw	a5,4(s1)
    800045ac:	cf99                	beqz	a5,800045ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ae:	02848493          	addi	s1,s1,40
    800045b2:	fee49ce3          	bne	s1,a4,800045aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045b6:	0001d517          	auipc	a0,0x1d
    800045ba:	00250513          	addi	a0,a0,2 # 800215b8 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	6b8080e7          	jalr	1720(ra) # 80000c76 <release>
  return 0;
    800045c6:	4481                	li	s1,0
    800045c8:	a819                	j	800045de <filealloc+0x5e>
      f->ref = 1;
    800045ca:	4785                	li	a5,1
    800045cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	fea50513          	addi	a0,a0,-22 # 800215b8 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6a0080e7          	jalr	1696(ra) # 80000c76 <release>
}
    800045de:	8526                	mv	a0,s1
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ea:	1101                	addi	sp,sp,-32
    800045ec:	ec06                	sd	ra,24(sp)
    800045ee:	e822                	sd	s0,16(sp)
    800045f0:	e426                	sd	s1,8(sp)
    800045f2:	1000                	addi	s0,sp,32
    800045f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045f6:	0001d517          	auipc	a0,0x1d
    800045fa:	fc250513          	addi	a0,a0,-62 # 800215b8 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	5c4080e7          	jalr	1476(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004606:	40dc                	lw	a5,4(s1)
    80004608:	02f05263          	blez	a5,8000462c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000460c:	2785                	addiw	a5,a5,1
    8000460e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004610:	0001d517          	auipc	a0,0x1d
    80004614:	fa850513          	addi	a0,a0,-88 # 800215b8 <ftable>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	65e080e7          	jalr	1630(ra) # 80000c76 <release>
  return f;
}
    80004620:	8526                	mv	a0,s1
    80004622:	60e2                	ld	ra,24(sp)
    80004624:	6442                	ld	s0,16(sp)
    80004626:	64a2                	ld	s1,8(sp)
    80004628:	6105                	addi	sp,sp,32
    8000462a:	8082                	ret
    panic("filedup");
    8000462c:	00004517          	auipc	a0,0x4
    80004630:	14c50513          	addi	a0,a0,332 # 80008778 <syscalls+0x248>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	ef6080e7          	jalr	-266(ra) # 8000052a <panic>

000000008000463c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000463c:	7139                	addi	sp,sp,-64
    8000463e:	fc06                	sd	ra,56(sp)
    80004640:	f822                	sd	s0,48(sp)
    80004642:	f426                	sd	s1,40(sp)
    80004644:	f04a                	sd	s2,32(sp)
    80004646:	ec4e                	sd	s3,24(sp)
    80004648:	e852                	sd	s4,16(sp)
    8000464a:	e456                	sd	s5,8(sp)
    8000464c:	0080                	addi	s0,sp,64
    8000464e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004650:	0001d517          	auipc	a0,0x1d
    80004654:	f6850513          	addi	a0,a0,-152 # 800215b8 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	56a080e7          	jalr	1386(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004660:	40dc                	lw	a5,4(s1)
    80004662:	06f05163          	blez	a5,800046c4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004666:	37fd                	addiw	a5,a5,-1
    80004668:	0007871b          	sext.w	a4,a5
    8000466c:	c0dc                	sw	a5,4(s1)
    8000466e:	06e04363          	bgtz	a4,800046d4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004672:	0004a903          	lw	s2,0(s1)
    80004676:	0094ca83          	lbu	s5,9(s1)
    8000467a:	0104ba03          	ld	s4,16(s1)
    8000467e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004682:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004686:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000468a:	0001d517          	auipc	a0,0x1d
    8000468e:	f2e50513          	addi	a0,a0,-210 # 800215b8 <ftable>
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	5e4080e7          	jalr	1508(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    8000469a:	4785                	li	a5,1
    8000469c:	04f90d63          	beq	s2,a5,800046f6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a0:	3979                	addiw	s2,s2,-2
    800046a2:	4785                	li	a5,1
    800046a4:	0527e063          	bltu	a5,s2,800046e4 <fileclose+0xa8>
    begin_op();
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	ac8080e7          	jalr	-1336(ra) # 80004170 <begin_op>
    iput(ff.ip);
    800046b0:	854e                	mv	a0,s3
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	2a2080e7          	jalr	674(ra) # 80003954 <iput>
    end_op();
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	b36080e7          	jalr	-1226(ra) # 800041f0 <end_op>
    800046c2:	a00d                	j	800046e4 <fileclose+0xa8>
    panic("fileclose");
    800046c4:	00004517          	auipc	a0,0x4
    800046c8:	0bc50513          	addi	a0,a0,188 # 80008780 <syscalls+0x250>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	e5e080e7          	jalr	-418(ra) # 8000052a <panic>
    release(&ftable.lock);
    800046d4:	0001d517          	auipc	a0,0x1d
    800046d8:	ee450513          	addi	a0,a0,-284 # 800215b8 <ftable>
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	59a080e7          	jalr	1434(ra) # 80000c76 <release>
  }
}
    800046e4:	70e2                	ld	ra,56(sp)
    800046e6:	7442                	ld	s0,48(sp)
    800046e8:	74a2                	ld	s1,40(sp)
    800046ea:	7902                	ld	s2,32(sp)
    800046ec:	69e2                	ld	s3,24(sp)
    800046ee:	6a42                	ld	s4,16(sp)
    800046f0:	6aa2                	ld	s5,8(sp)
    800046f2:	6121                	addi	sp,sp,64
    800046f4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046f6:	85d6                	mv	a1,s5
    800046f8:	8552                	mv	a0,s4
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	34c080e7          	jalr	844(ra) # 80004a46 <pipeclose>
    80004702:	b7cd                	j	800046e4 <fileclose+0xa8>

0000000080004704 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004704:	715d                	addi	sp,sp,-80
    80004706:	e486                	sd	ra,72(sp)
    80004708:	e0a2                	sd	s0,64(sp)
    8000470a:	fc26                	sd	s1,56(sp)
    8000470c:	f84a                	sd	s2,48(sp)
    8000470e:	f44e                	sd	s3,40(sp)
    80004710:	0880                	addi	s0,sp,80
    80004712:	84aa                	mv	s1,a0
    80004714:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004716:	ffffd097          	auipc	ra,0xffffd
    8000471a:	268080e7          	jalr	616(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000471e:	409c                	lw	a5,0(s1)
    80004720:	37f9                	addiw	a5,a5,-2
    80004722:	4705                	li	a4,1
    80004724:	04f76763          	bltu	a4,a5,80004772 <filestat+0x6e>
    80004728:	892a                	mv	s2,a0
    ilock(f->ip);
    8000472a:	6c88                	ld	a0,24(s1)
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	06e080e7          	jalr	110(ra) # 8000379a <ilock>
    stati(f->ip, &st);
    80004734:	fb840593          	addi	a1,s0,-72
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	2ea080e7          	jalr	746(ra) # 80003a24 <stati>
    iunlock(f->ip);
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	118080e7          	jalr	280(ra) # 8000385c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000474c:	46e1                	li	a3,24
    8000474e:	fb840613          	addi	a2,s0,-72
    80004752:	85ce                	mv	a1,s3
    80004754:	05893503          	ld	a0,88(s2)
    80004758:	ffffd097          	auipc	ra,0xffffd
    8000475c:	ee6080e7          	jalr	-282(ra) # 8000163e <copyout>
    80004760:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004764:	60a6                	ld	ra,72(sp)
    80004766:	6406                	ld	s0,64(sp)
    80004768:	74e2                	ld	s1,56(sp)
    8000476a:	7942                	ld	s2,48(sp)
    8000476c:	79a2                	ld	s3,40(sp)
    8000476e:	6161                	addi	sp,sp,80
    80004770:	8082                	ret
  return -1;
    80004772:	557d                	li	a0,-1
    80004774:	bfc5                	j	80004764 <filestat+0x60>

0000000080004776 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004776:	7179                	addi	sp,sp,-48
    80004778:	f406                	sd	ra,40(sp)
    8000477a:	f022                	sd	s0,32(sp)
    8000477c:	ec26                	sd	s1,24(sp)
    8000477e:	e84a                	sd	s2,16(sp)
    80004780:	e44e                	sd	s3,8(sp)
    80004782:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004784:	00854783          	lbu	a5,8(a0)
    80004788:	c3d5                	beqz	a5,8000482c <fileread+0xb6>
    8000478a:	84aa                	mv	s1,a0
    8000478c:	89ae                	mv	s3,a1
    8000478e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004790:	411c                	lw	a5,0(a0)
    80004792:	4705                	li	a4,1
    80004794:	04e78963          	beq	a5,a4,800047e6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004798:	470d                	li	a4,3
    8000479a:	04e78d63          	beq	a5,a4,800047f4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000479e:	4709                	li	a4,2
    800047a0:	06e79e63          	bne	a5,a4,8000481c <fileread+0xa6>
    ilock(f->ip);
    800047a4:	6d08                	ld	a0,24(a0)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	ff4080e7          	jalr	-12(ra) # 8000379a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ae:	874a                	mv	a4,s2
    800047b0:	5094                	lw	a3,32(s1)
    800047b2:	864e                	mv	a2,s3
    800047b4:	4585                	li	a1,1
    800047b6:	6c88                	ld	a0,24(s1)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	296080e7          	jalr	662(ra) # 80003a4e <readi>
    800047c0:	892a                	mv	s2,a0
    800047c2:	00a05563          	blez	a0,800047cc <fileread+0x56>
      f->off += r;
    800047c6:	509c                	lw	a5,32(s1)
    800047c8:	9fa9                	addw	a5,a5,a0
    800047ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047cc:	6c88                	ld	a0,24(s1)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	08e080e7          	jalr	142(ra) # 8000385c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047d6:	854a                	mv	a0,s2
    800047d8:	70a2                	ld	ra,40(sp)
    800047da:	7402                	ld	s0,32(sp)
    800047dc:	64e2                	ld	s1,24(sp)
    800047de:	6942                	ld	s2,16(sp)
    800047e0:	69a2                	ld	s3,8(sp)
    800047e2:	6145                	addi	sp,sp,48
    800047e4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047e6:	6908                	ld	a0,16(a0)
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	3c0080e7          	jalr	960(ra) # 80004ba8 <piperead>
    800047f0:	892a                	mv	s2,a0
    800047f2:	b7d5                	j	800047d6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047f4:	02451783          	lh	a5,36(a0)
    800047f8:	03079693          	slli	a3,a5,0x30
    800047fc:	92c1                	srli	a3,a3,0x30
    800047fe:	4725                	li	a4,9
    80004800:	02d76863          	bltu	a4,a3,80004830 <fileread+0xba>
    80004804:	0792                	slli	a5,a5,0x4
    80004806:	0001d717          	auipc	a4,0x1d
    8000480a:	d1270713          	addi	a4,a4,-750 # 80021518 <devsw>
    8000480e:	97ba                	add	a5,a5,a4
    80004810:	639c                	ld	a5,0(a5)
    80004812:	c38d                	beqz	a5,80004834 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004814:	4505                	li	a0,1
    80004816:	9782                	jalr	a5
    80004818:	892a                	mv	s2,a0
    8000481a:	bf75                	j	800047d6 <fileread+0x60>
    panic("fileread");
    8000481c:	00004517          	auipc	a0,0x4
    80004820:	f7450513          	addi	a0,a0,-140 # 80008790 <syscalls+0x260>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	d06080e7          	jalr	-762(ra) # 8000052a <panic>
    return -1;
    8000482c:	597d                	li	s2,-1
    8000482e:	b765                	j	800047d6 <fileread+0x60>
      return -1;
    80004830:	597d                	li	s2,-1
    80004832:	b755                	j	800047d6 <fileread+0x60>
    80004834:	597d                	li	s2,-1
    80004836:	b745                	j	800047d6 <fileread+0x60>

0000000080004838 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004838:	715d                	addi	sp,sp,-80
    8000483a:	e486                	sd	ra,72(sp)
    8000483c:	e0a2                	sd	s0,64(sp)
    8000483e:	fc26                	sd	s1,56(sp)
    80004840:	f84a                	sd	s2,48(sp)
    80004842:	f44e                	sd	s3,40(sp)
    80004844:	f052                	sd	s4,32(sp)
    80004846:	ec56                	sd	s5,24(sp)
    80004848:	e85a                	sd	s6,16(sp)
    8000484a:	e45e                	sd	s7,8(sp)
    8000484c:	e062                	sd	s8,0(sp)
    8000484e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004850:	00954783          	lbu	a5,9(a0)
    80004854:	10078663          	beqz	a5,80004960 <filewrite+0x128>
    80004858:	892a                	mv	s2,a0
    8000485a:	8aae                	mv	s5,a1
    8000485c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000485e:	411c                	lw	a5,0(a0)
    80004860:	4705                	li	a4,1
    80004862:	02e78263          	beq	a5,a4,80004886 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004866:	470d                	li	a4,3
    80004868:	02e78663          	beq	a5,a4,80004894 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000486c:	4709                	li	a4,2
    8000486e:	0ee79163          	bne	a5,a4,80004950 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004872:	0ac05d63          	blez	a2,8000492c <filewrite+0xf4>
    int i = 0;
    80004876:	4981                	li	s3,0
    80004878:	6b05                	lui	s6,0x1
    8000487a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000487e:	6b85                	lui	s7,0x1
    80004880:	c00b8b9b          	addiw	s7,s7,-1024
    80004884:	a861                	j	8000491c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004886:	6908                	ld	a0,16(a0)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	22e080e7          	jalr	558(ra) # 80004ab6 <pipewrite>
    80004890:	8a2a                	mv	s4,a0
    80004892:	a045                	j	80004932 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004894:	02451783          	lh	a5,36(a0)
    80004898:	03079693          	slli	a3,a5,0x30
    8000489c:	92c1                	srli	a3,a3,0x30
    8000489e:	4725                	li	a4,9
    800048a0:	0cd76263          	bltu	a4,a3,80004964 <filewrite+0x12c>
    800048a4:	0792                	slli	a5,a5,0x4
    800048a6:	0001d717          	auipc	a4,0x1d
    800048aa:	c7270713          	addi	a4,a4,-910 # 80021518 <devsw>
    800048ae:	97ba                	add	a5,a5,a4
    800048b0:	679c                	ld	a5,8(a5)
    800048b2:	cbdd                	beqz	a5,80004968 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048b4:	4505                	li	a0,1
    800048b6:	9782                	jalr	a5
    800048b8:	8a2a                	mv	s4,a0
    800048ba:	a8a5                	j	80004932 <filewrite+0xfa>
    800048bc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	8b0080e7          	jalr	-1872(ra) # 80004170 <begin_op>
      ilock(f->ip);
    800048c8:	01893503          	ld	a0,24(s2)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	ece080e7          	jalr	-306(ra) # 8000379a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048d4:	8762                	mv	a4,s8
    800048d6:	02092683          	lw	a3,32(s2)
    800048da:	01598633          	add	a2,s3,s5
    800048de:	4585                	li	a1,1
    800048e0:	01893503          	ld	a0,24(s2)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	262080e7          	jalr	610(ra) # 80003b46 <writei>
    800048ec:	84aa                	mv	s1,a0
    800048ee:	00a05763          	blez	a0,800048fc <filewrite+0xc4>
        f->off += r;
    800048f2:	02092783          	lw	a5,32(s2)
    800048f6:	9fa9                	addw	a5,a5,a0
    800048f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048fc:	01893503          	ld	a0,24(s2)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	f5c080e7          	jalr	-164(ra) # 8000385c <iunlock>
      end_op();
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	8e8080e7          	jalr	-1816(ra) # 800041f0 <end_op>

      if(r != n1){
    80004910:	009c1f63          	bne	s8,s1,8000492e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004914:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004918:	0149db63          	bge	s3,s4,8000492e <filewrite+0xf6>
      int n1 = n - i;
    8000491c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004920:	84be                	mv	s1,a5
    80004922:	2781                	sext.w	a5,a5
    80004924:	f8fb5ce3          	bge	s6,a5,800048bc <filewrite+0x84>
    80004928:	84de                	mv	s1,s7
    8000492a:	bf49                	j	800048bc <filewrite+0x84>
    int i = 0;
    8000492c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000492e:	013a1f63          	bne	s4,s3,8000494c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004932:	8552                	mv	a0,s4
    80004934:	60a6                	ld	ra,72(sp)
    80004936:	6406                	ld	s0,64(sp)
    80004938:	74e2                	ld	s1,56(sp)
    8000493a:	7942                	ld	s2,48(sp)
    8000493c:	79a2                	ld	s3,40(sp)
    8000493e:	7a02                	ld	s4,32(sp)
    80004940:	6ae2                	ld	s5,24(sp)
    80004942:	6b42                	ld	s6,16(sp)
    80004944:	6ba2                	ld	s7,8(sp)
    80004946:	6c02                	ld	s8,0(sp)
    80004948:	6161                	addi	sp,sp,80
    8000494a:	8082                	ret
    ret = (i == n ? n : -1);
    8000494c:	5a7d                	li	s4,-1
    8000494e:	b7d5                	j	80004932 <filewrite+0xfa>
    panic("filewrite");
    80004950:	00004517          	auipc	a0,0x4
    80004954:	e5050513          	addi	a0,a0,-432 # 800087a0 <syscalls+0x270>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	bd2080e7          	jalr	-1070(ra) # 8000052a <panic>
    return -1;
    80004960:	5a7d                	li	s4,-1
    80004962:	bfc1                	j	80004932 <filewrite+0xfa>
      return -1;
    80004964:	5a7d                	li	s4,-1
    80004966:	b7f1                	j	80004932 <filewrite+0xfa>
    80004968:	5a7d                	li	s4,-1
    8000496a:	b7e1                	j	80004932 <filewrite+0xfa>

000000008000496c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000496c:	7179                	addi	sp,sp,-48
    8000496e:	f406                	sd	ra,40(sp)
    80004970:	f022                	sd	s0,32(sp)
    80004972:	ec26                	sd	s1,24(sp)
    80004974:	e84a                	sd	s2,16(sp)
    80004976:	e44e                	sd	s3,8(sp)
    80004978:	e052                	sd	s4,0(sp)
    8000497a:	1800                	addi	s0,sp,48
    8000497c:	84aa                	mv	s1,a0
    8000497e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004980:	0005b023          	sd	zero,0(a1)
    80004984:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	bf8080e7          	jalr	-1032(ra) # 80004580 <filealloc>
    80004990:	e088                	sd	a0,0(s1)
    80004992:	c551                	beqz	a0,80004a1e <pipealloc+0xb2>
    80004994:	00000097          	auipc	ra,0x0
    80004998:	bec080e7          	jalr	-1044(ra) # 80004580 <filealloc>
    8000499c:	00aa3023          	sd	a0,0(s4)
    800049a0:	c92d                	beqz	a0,80004a12 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	130080e7          	jalr	304(ra) # 80000ad2 <kalloc>
    800049aa:	892a                	mv	s2,a0
    800049ac:	c125                	beqz	a0,80004a0c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ae:	4985                	li	s3,1
    800049b0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049b4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049b8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049bc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c0:	00004597          	auipc	a1,0x4
    800049c4:	ac858593          	addi	a1,a1,-1336 # 80008488 <states.0+0x1e0>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	16a080e7          	jalr	362(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049d6:	609c                	ld	a5,0(s1)
    800049d8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049dc:	609c                	ld	a5,0(s1)
    800049de:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e2:	609c                	ld	a5,0(s1)
    800049e4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049e8:	000a3783          	ld	a5,0(s4)
    800049ec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a08:	4501                	li	a0,0
    80004a0a:	a025                	j	80004a32 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a0c:	6088                	ld	a0,0(s1)
    80004a0e:	e501                	bnez	a0,80004a16 <pipealloc+0xaa>
    80004a10:	a039                	j	80004a1e <pipealloc+0xb2>
    80004a12:	6088                	ld	a0,0(s1)
    80004a14:	c51d                	beqz	a0,80004a42 <pipealloc+0xd6>
    fileclose(*f0);
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	c26080e7          	jalr	-986(ra) # 8000463c <fileclose>
  if(*f1)
    80004a1e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a22:	557d                	li	a0,-1
  if(*f1)
    80004a24:	c799                	beqz	a5,80004a32 <pipealloc+0xc6>
    fileclose(*f1);
    80004a26:	853e                	mv	a0,a5
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	c14080e7          	jalr	-1004(ra) # 8000463c <fileclose>
  return -1;
    80004a30:	557d                	li	a0,-1
}
    80004a32:	70a2                	ld	ra,40(sp)
    80004a34:	7402                	ld	s0,32(sp)
    80004a36:	64e2                	ld	s1,24(sp)
    80004a38:	6942                	ld	s2,16(sp)
    80004a3a:	69a2                	ld	s3,8(sp)
    80004a3c:	6a02                	ld	s4,0(sp)
    80004a3e:	6145                	addi	sp,sp,48
    80004a40:	8082                	ret
  return -1;
    80004a42:	557d                	li	a0,-1
    80004a44:	b7fd                	j	80004a32 <pipealloc+0xc6>

0000000080004a46 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a46:	1101                	addi	sp,sp,-32
    80004a48:	ec06                	sd	ra,24(sp)
    80004a4a:	e822                	sd	s0,16(sp)
    80004a4c:	e426                	sd	s1,8(sp)
    80004a4e:	e04a                	sd	s2,0(sp)
    80004a50:	1000                	addi	s0,sp,32
    80004a52:	84aa                	mv	s1,a0
    80004a54:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	16c080e7          	jalr	364(ra) # 80000bc2 <acquire>
  if(writable){
    80004a5e:	02090d63          	beqz	s2,80004a98 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a62:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a66:	21848513          	addi	a0,s1,536
    80004a6a:	ffffd097          	auipc	ra,0xffffd
    80004a6e:	6e4080e7          	jalr	1764(ra) # 8000214e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a72:	2204b783          	ld	a5,544(s1)
    80004a76:	eb95                	bnez	a5,80004aaa <pipeclose+0x64>
    release(&pi->lock);
    80004a78:	8526                	mv	a0,s1
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	1fc080e7          	jalr	508(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	f52080e7          	jalr	-174(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret
    pi->readopen = 0;
    80004a98:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a9c:	21c48513          	addi	a0,s1,540
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	6ae080e7          	jalr	1710(ra) # 8000214e <wakeup>
    80004aa8:	b7e9                	j	80004a72 <pipeclose+0x2c>
    release(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	1ca080e7          	jalr	458(ra) # 80000c76 <release>
}
    80004ab4:	bfe1                	j	80004a8c <pipeclose+0x46>

0000000080004ab6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ab6:	711d                	addi	sp,sp,-96
    80004ab8:	ec86                	sd	ra,88(sp)
    80004aba:	e8a2                	sd	s0,80(sp)
    80004abc:	e4a6                	sd	s1,72(sp)
    80004abe:	e0ca                	sd	s2,64(sp)
    80004ac0:	fc4e                	sd	s3,56(sp)
    80004ac2:	f852                	sd	s4,48(sp)
    80004ac4:	f456                	sd	s5,40(sp)
    80004ac6:	f05a                	sd	s6,32(sp)
    80004ac8:	ec5e                	sd	s7,24(sp)
    80004aca:	e862                	sd	s8,16(sp)
    80004acc:	1080                	addi	s0,sp,96
    80004ace:	84aa                	mv	s1,a0
    80004ad0:	8aae                	mv	s5,a1
    80004ad2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	eaa080e7          	jalr	-342(ra) # 8000197e <myproc>
    80004adc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	0e2080e7          	jalr	226(ra) # 80000bc2 <acquire>
  while(i < n){
    80004ae8:	0b405363          	blez	s4,80004b8e <pipewrite+0xd8>
  int i = 0;
    80004aec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004af0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af4:	21c48b93          	addi	s7,s1,540
    80004af8:	a089                	j	80004b3a <pipewrite+0x84>
      release(&pi->lock);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	17a080e7          	jalr	378(ra) # 80000c76 <release>
      return -1;
    80004b04:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b06:	854a                	mv	a0,s2
    80004b08:	60e6                	ld	ra,88(sp)
    80004b0a:	6446                	ld	s0,80(sp)
    80004b0c:	64a6                	ld	s1,72(sp)
    80004b0e:	6906                	ld	s2,64(sp)
    80004b10:	79e2                	ld	s3,56(sp)
    80004b12:	7a42                	ld	s4,48(sp)
    80004b14:	7aa2                	ld	s5,40(sp)
    80004b16:	7b02                	ld	s6,32(sp)
    80004b18:	6be2                	ld	s7,24(sp)
    80004b1a:	6c42                	ld	s8,16(sp)
    80004b1c:	6125                	addi	sp,sp,96
    80004b1e:	8082                	ret
      wakeup(&pi->nread);
    80004b20:	8562                	mv	a0,s8
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	62c080e7          	jalr	1580(ra) # 8000214e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b2a:	85a6                	mv	a1,s1
    80004b2c:	855e                	mv	a0,s7
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	494080e7          	jalr	1172(ra) # 80001fc2 <sleep>
  while(i < n){
    80004b36:	05495d63          	bge	s2,s4,80004b90 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004b3a:	2204a783          	lw	a5,544(s1)
    80004b3e:	dfd5                	beqz	a5,80004afa <pipewrite+0x44>
    80004b40:	0289a783          	lw	a5,40(s3)
    80004b44:	fbdd                	bnez	a5,80004afa <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b46:	2184a783          	lw	a5,536(s1)
    80004b4a:	21c4a703          	lw	a4,540(s1)
    80004b4e:	2007879b          	addiw	a5,a5,512
    80004b52:	fcf707e3          	beq	a4,a5,80004b20 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b56:	4685                	li	a3,1
    80004b58:	01590633          	add	a2,s2,s5
    80004b5c:	faf40593          	addi	a1,s0,-81
    80004b60:	0589b503          	ld	a0,88(s3)
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	b66080e7          	jalr	-1178(ra) # 800016ca <copyin>
    80004b6c:	03650263          	beq	a0,s6,80004b90 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b70:	21c4a783          	lw	a5,540(s1)
    80004b74:	0017871b          	addiw	a4,a5,1
    80004b78:	20e4ae23          	sw	a4,540(s1)
    80004b7c:	1ff7f793          	andi	a5,a5,511
    80004b80:	97a6                	add	a5,a5,s1
    80004b82:	faf44703          	lbu	a4,-81(s0)
    80004b86:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b8a:	2905                	addiw	s2,s2,1
    80004b8c:	b76d                	j	80004b36 <pipewrite+0x80>
  int i = 0;
    80004b8e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b90:	21848513          	addi	a0,s1,536
    80004b94:	ffffd097          	auipc	ra,0xffffd
    80004b98:	5ba080e7          	jalr	1466(ra) # 8000214e <wakeup>
  release(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	0d8080e7          	jalr	216(ra) # 80000c76 <release>
  return i;
    80004ba6:	b785                	j	80004b06 <pipewrite+0x50>

0000000080004ba8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba8:	715d                	addi	sp,sp,-80
    80004baa:	e486                	sd	ra,72(sp)
    80004bac:	e0a2                	sd	s0,64(sp)
    80004bae:	fc26                	sd	s1,56(sp)
    80004bb0:	f84a                	sd	s2,48(sp)
    80004bb2:	f44e                	sd	s3,40(sp)
    80004bb4:	f052                	sd	s4,32(sp)
    80004bb6:	ec56                	sd	s5,24(sp)
    80004bb8:	e85a                	sd	s6,16(sp)
    80004bba:	0880                	addi	s0,sp,80
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	892e                	mv	s2,a1
    80004bc0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	dbc080e7          	jalr	-580(ra) # 8000197e <myproc>
    80004bca:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	ff4080e7          	jalr	-12(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd6:	2184a703          	lw	a4,536(s1)
    80004bda:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bde:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be2:	02f71463          	bne	a4,a5,80004c0a <piperead+0x62>
    80004be6:	2244a783          	lw	a5,548(s1)
    80004bea:	c385                	beqz	a5,80004c0a <piperead+0x62>
    if(pr->killed){
    80004bec:	028a2783          	lw	a5,40(s4)
    80004bf0:	ebc1                	bnez	a5,80004c80 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf2:	85a6                	mv	a1,s1
    80004bf4:	854e                	mv	a0,s3
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	3cc080e7          	jalr	972(ra) # 80001fc2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfe:	2184a703          	lw	a4,536(s1)
    80004c02:	21c4a783          	lw	a5,540(s1)
    80004c06:	fef700e3          	beq	a4,a5,80004be6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c0c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0e:	05505363          	blez	s5,80004c54 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c12:	2184a783          	lw	a5,536(s1)
    80004c16:	21c4a703          	lw	a4,540(s1)
    80004c1a:	02f70d63          	beq	a4,a5,80004c54 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c1e:	0017871b          	addiw	a4,a5,1
    80004c22:	20e4ac23          	sw	a4,536(s1)
    80004c26:	1ff7f793          	andi	a5,a5,511
    80004c2a:	97a6                	add	a5,a5,s1
    80004c2c:	0187c783          	lbu	a5,24(a5)
    80004c30:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c34:	4685                	li	a3,1
    80004c36:	fbf40613          	addi	a2,s0,-65
    80004c3a:	85ca                	mv	a1,s2
    80004c3c:	058a3503          	ld	a0,88(s4)
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	9fe080e7          	jalr	-1538(ra) # 8000163e <copyout>
    80004c48:	01650663          	beq	a0,s6,80004c54 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4c:	2985                	addiw	s3,s3,1
    80004c4e:	0905                	addi	s2,s2,1
    80004c50:	fd3a91e3          	bne	s5,s3,80004c12 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c54:	21c48513          	addi	a0,s1,540
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	4f6080e7          	jalr	1270(ra) # 8000214e <wakeup>
  release(&pi->lock);
    80004c60:	8526                	mv	a0,s1
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	014080e7          	jalr	20(ra) # 80000c76 <release>
  return i;
}
    80004c6a:	854e                	mv	a0,s3
    80004c6c:	60a6                	ld	ra,72(sp)
    80004c6e:	6406                	ld	s0,64(sp)
    80004c70:	74e2                	ld	s1,56(sp)
    80004c72:	7942                	ld	s2,48(sp)
    80004c74:	79a2                	ld	s3,40(sp)
    80004c76:	7a02                	ld	s4,32(sp)
    80004c78:	6ae2                	ld	s5,24(sp)
    80004c7a:	6b42                	ld	s6,16(sp)
    80004c7c:	6161                	addi	sp,sp,80
    80004c7e:	8082                	ret
      release(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	ff4080e7          	jalr	-12(ra) # 80000c76 <release>
      return -1;
    80004c8a:	59fd                	li	s3,-1
    80004c8c:	bff9                	j	80004c6a <piperead+0xc2>

0000000080004c8e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c8e:	de010113          	addi	sp,sp,-544
    80004c92:	20113c23          	sd	ra,536(sp)
    80004c96:	20813823          	sd	s0,528(sp)
    80004c9a:	20913423          	sd	s1,520(sp)
    80004c9e:	21213023          	sd	s2,512(sp)
    80004ca2:	ffce                	sd	s3,504(sp)
    80004ca4:	fbd2                	sd	s4,496(sp)
    80004ca6:	f7d6                	sd	s5,488(sp)
    80004ca8:	f3da                	sd	s6,480(sp)
    80004caa:	efde                	sd	s7,472(sp)
    80004cac:	ebe2                	sd	s8,464(sp)
    80004cae:	e7e6                	sd	s9,456(sp)
    80004cb0:	e3ea                	sd	s10,448(sp)
    80004cb2:	ff6e                	sd	s11,440(sp)
    80004cb4:	1400                	addi	s0,sp,544
    80004cb6:	892a                	mv	s2,a0
    80004cb8:	dea43423          	sd	a0,-536(s0)
    80004cbc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	cbe080e7          	jalr	-834(ra) # 8000197e <myproc>
    80004cc8:	84aa                	mv	s1,a0

  begin_op();
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	4a6080e7          	jalr	1190(ra) # 80004170 <begin_op>

  if((ip = namei(path)) == 0){
    80004cd2:	854a                	mv	a0,s2
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	27c080e7          	jalr	636(ra) # 80003f50 <namei>
    80004cdc:	c93d                	beqz	a0,80004d52 <exec+0xc4>
    80004cde:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	aba080e7          	jalr	-1350(ra) # 8000379a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ce8:	04000713          	li	a4,64
    80004cec:	4681                	li	a3,0
    80004cee:	e4840613          	addi	a2,s0,-440
    80004cf2:	4581                	li	a1,0
    80004cf4:	8556                	mv	a0,s5
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	d58080e7          	jalr	-680(ra) # 80003a4e <readi>
    80004cfe:	04000793          	li	a5,64
    80004d02:	00f51a63          	bne	a0,a5,80004d16 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d06:	e4842703          	lw	a4,-440(s0)
    80004d0a:	464c47b7          	lui	a5,0x464c4
    80004d0e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d12:	04f70663          	beq	a4,a5,80004d5e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d16:	8556                	mv	a0,s5
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	ce4080e7          	jalr	-796(ra) # 800039fc <iunlockput>
    end_op();
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	4d0080e7          	jalr	1232(ra) # 800041f0 <end_op>
  }
  return -1;
    80004d28:	557d                	li	a0,-1
}
    80004d2a:	21813083          	ld	ra,536(sp)
    80004d2e:	21013403          	ld	s0,528(sp)
    80004d32:	20813483          	ld	s1,520(sp)
    80004d36:	20013903          	ld	s2,512(sp)
    80004d3a:	79fe                	ld	s3,504(sp)
    80004d3c:	7a5e                	ld	s4,496(sp)
    80004d3e:	7abe                	ld	s5,488(sp)
    80004d40:	7b1e                	ld	s6,480(sp)
    80004d42:	6bfe                	ld	s7,472(sp)
    80004d44:	6c5e                	ld	s8,464(sp)
    80004d46:	6cbe                	ld	s9,456(sp)
    80004d48:	6d1e                	ld	s10,448(sp)
    80004d4a:	7dfa                	ld	s11,440(sp)
    80004d4c:	22010113          	addi	sp,sp,544
    80004d50:	8082                	ret
    end_op();
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	49e080e7          	jalr	1182(ra) # 800041f0 <end_op>
    return -1;
    80004d5a:	557d                	li	a0,-1
    80004d5c:	b7f9                	j	80004d2a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d5e:	8526                	mv	a0,s1
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	ce2080e7          	jalr	-798(ra) # 80001a42 <proc_pagetable>
    80004d68:	8b2a                	mv	s6,a0
    80004d6a:	d555                	beqz	a0,80004d16 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d6c:	e6842783          	lw	a5,-408(s0)
    80004d70:	e8045703          	lhu	a4,-384(s0)
    80004d74:	c735                	beqz	a4,80004de0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d76:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d78:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d7c:	6a05                	lui	s4,0x1
    80004d7e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d82:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004d86:	6d85                	lui	s11,0x1
    80004d88:	7d7d                	lui	s10,0xfffff
    80004d8a:	ac1d                	j	80004fc0 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d8c:	00004517          	auipc	a0,0x4
    80004d90:	a2450513          	addi	a0,a0,-1500 # 800087b0 <syscalls+0x280>
    80004d94:	ffffb097          	auipc	ra,0xffffb
    80004d98:	796080e7          	jalr	1942(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d9c:	874a                	mv	a4,s2
    80004d9e:	009c86bb          	addw	a3,s9,s1
    80004da2:	4581                	li	a1,0
    80004da4:	8556                	mv	a0,s5
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	ca8080e7          	jalr	-856(ra) # 80003a4e <readi>
    80004dae:	2501                	sext.w	a0,a0
    80004db0:	1aa91863          	bne	s2,a0,80004f60 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004db4:	009d84bb          	addw	s1,s11,s1
    80004db8:	013d09bb          	addw	s3,s10,s3
    80004dbc:	1f74f263          	bgeu	s1,s7,80004fa0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004dc0:	02049593          	slli	a1,s1,0x20
    80004dc4:	9181                	srli	a1,a1,0x20
    80004dc6:	95e2                	add	a1,a1,s8
    80004dc8:	855a                	mv	a0,s6
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	282080e7          	jalr	642(ra) # 8000104c <walkaddr>
    80004dd2:	862a                	mv	a2,a0
    if(pa == 0)
    80004dd4:	dd45                	beqz	a0,80004d8c <exec+0xfe>
      n = PGSIZE;
    80004dd6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dd8:	fd49f2e3          	bgeu	s3,s4,80004d9c <exec+0x10e>
      n = sz - i;
    80004ddc:	894e                	mv	s2,s3
    80004dde:	bf7d                	j	80004d9c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004de0:	4481                	li	s1,0
  iunlockput(ip);
    80004de2:	8556                	mv	a0,s5
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	c18080e7          	jalr	-1000(ra) # 800039fc <iunlockput>
  end_op();
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	404080e7          	jalr	1028(ra) # 800041f0 <end_op>
  p = myproc();
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	b8a080e7          	jalr	-1142(ra) # 8000197e <myproc>
    80004dfc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dfe:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004e02:	6785                	lui	a5,0x1
    80004e04:	17fd                	addi	a5,a5,-1
    80004e06:	94be                	add	s1,s1,a5
    80004e08:	77fd                	lui	a5,0xfffff
    80004e0a:	8fe5                	and	a5,a5,s1
    80004e0c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e10:	6609                	lui	a2,0x2
    80004e12:	963e                	add	a2,a2,a5
    80004e14:	85be                	mv	a1,a5
    80004e16:	855a                	mv	a0,s6
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	5d6080e7          	jalr	1494(ra) # 800013ee <uvmalloc>
    80004e20:	8c2a                	mv	s8,a0
  ip = 0;
    80004e22:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e24:	12050e63          	beqz	a0,80004f60 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e28:	75f9                	lui	a1,0xffffe
    80004e2a:	95aa                	add	a1,a1,a0
    80004e2c:	855a                	mv	a0,s6
    80004e2e:	ffffc097          	auipc	ra,0xffffc
    80004e32:	7de080e7          	jalr	2014(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004e36:	7afd                	lui	s5,0xfffff
    80004e38:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e3a:	df043783          	ld	a5,-528(s0)
    80004e3e:	6388                	ld	a0,0(a5)
    80004e40:	c925                	beqz	a0,80004eb0 <exec+0x222>
    80004e42:	e8840993          	addi	s3,s0,-376
    80004e46:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e4a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e4c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	ff4080e7          	jalr	-12(ra) # 80000e42 <strlen>
    80004e56:	0015079b          	addiw	a5,a0,1
    80004e5a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e5e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e62:	13596363          	bltu	s2,s5,80004f88 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e66:	df043d83          	ld	s11,-528(s0)
    80004e6a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e6e:	8552                	mv	a0,s4
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	fd2080e7          	jalr	-46(ra) # 80000e42 <strlen>
    80004e78:	0015069b          	addiw	a3,a0,1
    80004e7c:	8652                	mv	a2,s4
    80004e7e:	85ca                	mv	a1,s2
    80004e80:	855a                	mv	a0,s6
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	7bc080e7          	jalr	1980(ra) # 8000163e <copyout>
    80004e8a:	10054363          	bltz	a0,80004f90 <exec+0x302>
    ustack[argc] = sp;
    80004e8e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e92:	0485                	addi	s1,s1,1
    80004e94:	008d8793          	addi	a5,s11,8
    80004e98:	def43823          	sd	a5,-528(s0)
    80004e9c:	008db503          	ld	a0,8(s11)
    80004ea0:	c911                	beqz	a0,80004eb4 <exec+0x226>
    if(argc >= MAXARG)
    80004ea2:	09a1                	addi	s3,s3,8
    80004ea4:	fb3c95e3          	bne	s9,s3,80004e4e <exec+0x1c0>
  sz = sz1;
    80004ea8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eac:	4a81                	li	s5,0
    80004eae:	a84d                	j	80004f60 <exec+0x2d2>
  sp = sz;
    80004eb0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eb2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eb4:	00349793          	slli	a5,s1,0x3
    80004eb8:	f9040713          	addi	a4,s0,-112
    80004ebc:	97ba                	add	a5,a5,a4
    80004ebe:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004ec2:	00148693          	addi	a3,s1,1
    80004ec6:	068e                	slli	a3,a3,0x3
    80004ec8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ecc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ed0:	01597663          	bgeu	s2,s5,80004edc <exec+0x24e>
  sz = sz1;
    80004ed4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed8:	4a81                	li	s5,0
    80004eda:	a059                	j	80004f60 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004edc:	e8840613          	addi	a2,s0,-376
    80004ee0:	85ca                	mv	a1,s2
    80004ee2:	855a                	mv	a0,s6
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	75a080e7          	jalr	1882(ra) # 8000163e <copyout>
    80004eec:	0a054663          	bltz	a0,80004f98 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004ef0:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    80004ef4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ef8:	de843783          	ld	a5,-536(s0)
    80004efc:	0007c703          	lbu	a4,0(a5)
    80004f00:	cf11                	beqz	a4,80004f1c <exec+0x28e>
    80004f02:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f04:	02f00693          	li	a3,47
    80004f08:	a039                	j	80004f16 <exec+0x288>
      last = s+1;
    80004f0a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f0e:	0785                	addi	a5,a5,1
    80004f10:	fff7c703          	lbu	a4,-1(a5)
    80004f14:	c701                	beqz	a4,80004f1c <exec+0x28e>
    if(*s == '/')
    80004f16:	fed71ce3          	bne	a4,a3,80004f0e <exec+0x280>
    80004f1a:	bfc5                	j	80004f0a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f1c:	4641                	li	a2,16
    80004f1e:	de843583          	ld	a1,-536(s0)
    80004f22:	160b8513          	addi	a0,s7,352
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	eea080e7          	jalr	-278(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f2e:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80004f32:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80004f36:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f3a:	060bb783          	ld	a5,96(s7)
    80004f3e:	e6043703          	ld	a4,-416(s0)
    80004f42:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f44:	060bb783          	ld	a5,96(s7)
    80004f48:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f4c:	85ea                	mv	a1,s10
    80004f4e:	ffffd097          	auipc	ra,0xffffd
    80004f52:	b90080e7          	jalr	-1136(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f56:	0004851b          	sext.w	a0,s1
    80004f5a:	bbc1                	j	80004d2a <exec+0x9c>
    80004f5c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f60:	df843583          	ld	a1,-520(s0)
    80004f64:	855a                	mv	a0,s6
    80004f66:	ffffd097          	auipc	ra,0xffffd
    80004f6a:	b78080e7          	jalr	-1160(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80004f6e:	da0a94e3          	bnez	s5,80004d16 <exec+0x88>
  return -1;
    80004f72:	557d                	li	a0,-1
    80004f74:	bb5d                	j	80004d2a <exec+0x9c>
    80004f76:	de943c23          	sd	s1,-520(s0)
    80004f7a:	b7dd                	j	80004f60 <exec+0x2d2>
    80004f7c:	de943c23          	sd	s1,-520(s0)
    80004f80:	b7c5                	j	80004f60 <exec+0x2d2>
    80004f82:	de943c23          	sd	s1,-520(s0)
    80004f86:	bfe9                	j	80004f60 <exec+0x2d2>
  sz = sz1;
    80004f88:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f8c:	4a81                	li	s5,0
    80004f8e:	bfc9                	j	80004f60 <exec+0x2d2>
  sz = sz1;
    80004f90:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f94:	4a81                	li	s5,0
    80004f96:	b7e9                	j	80004f60 <exec+0x2d2>
  sz = sz1;
    80004f98:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f9c:	4a81                	li	s5,0
    80004f9e:	b7c9                	j	80004f60 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fa0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa4:	e0843783          	ld	a5,-504(s0)
    80004fa8:	0017869b          	addiw	a3,a5,1
    80004fac:	e0d43423          	sd	a3,-504(s0)
    80004fb0:	e0043783          	ld	a5,-512(s0)
    80004fb4:	0387879b          	addiw	a5,a5,56
    80004fb8:	e8045703          	lhu	a4,-384(s0)
    80004fbc:	e2e6d3e3          	bge	a3,a4,80004de2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fc0:	2781                	sext.w	a5,a5
    80004fc2:	e0f43023          	sd	a5,-512(s0)
    80004fc6:	03800713          	li	a4,56
    80004fca:	86be                	mv	a3,a5
    80004fcc:	e1040613          	addi	a2,s0,-496
    80004fd0:	4581                	li	a1,0
    80004fd2:	8556                	mv	a0,s5
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	a7a080e7          	jalr	-1414(ra) # 80003a4e <readi>
    80004fdc:	03800793          	li	a5,56
    80004fe0:	f6f51ee3          	bne	a0,a5,80004f5c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004fe4:	e1042783          	lw	a5,-496(s0)
    80004fe8:	4705                	li	a4,1
    80004fea:	fae79de3          	bne	a5,a4,80004fa4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004fee:	e3843603          	ld	a2,-456(s0)
    80004ff2:	e3043783          	ld	a5,-464(s0)
    80004ff6:	f8f660e3          	bltu	a2,a5,80004f76 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ffa:	e2043783          	ld	a5,-480(s0)
    80004ffe:	963e                	add	a2,a2,a5
    80005000:	f6f66ee3          	bltu	a2,a5,80004f7c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005004:	85a6                	mv	a1,s1
    80005006:	855a                	mv	a0,s6
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	3e6080e7          	jalr	998(ra) # 800013ee <uvmalloc>
    80005010:	dea43c23          	sd	a0,-520(s0)
    80005014:	d53d                	beqz	a0,80004f82 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005016:	e2043c03          	ld	s8,-480(s0)
    8000501a:	de043783          	ld	a5,-544(s0)
    8000501e:	00fc77b3          	and	a5,s8,a5
    80005022:	ff9d                	bnez	a5,80004f60 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005024:	e1842c83          	lw	s9,-488(s0)
    80005028:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000502c:	f60b8ae3          	beqz	s7,80004fa0 <exec+0x312>
    80005030:	89de                	mv	s3,s7
    80005032:	4481                	li	s1,0
    80005034:	b371                	j	80004dc0 <exec+0x132>

0000000080005036 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005036:	7179                	addi	sp,sp,-48
    80005038:	f406                	sd	ra,40(sp)
    8000503a:	f022                	sd	s0,32(sp)
    8000503c:	ec26                	sd	s1,24(sp)
    8000503e:	e84a                	sd	s2,16(sp)
    80005040:	1800                	addi	s0,sp,48
    80005042:	892e                	mv	s2,a1
    80005044:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005046:	fdc40593          	addi	a1,s0,-36
    8000504a:	ffffe097          	auipc	ra,0xffffe
    8000504e:	ad4080e7          	jalr	-1324(ra) # 80002b1e <argint>
    80005052:	04054063          	bltz	a0,80005092 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005056:	fdc42703          	lw	a4,-36(s0)
    8000505a:	47bd                	li	a5,15
    8000505c:	02e7ed63          	bltu	a5,a4,80005096 <argfd+0x60>
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	91e080e7          	jalr	-1762(ra) # 8000197e <myproc>
    80005068:	fdc42703          	lw	a4,-36(s0)
    8000506c:	01a70793          	addi	a5,a4,26
    80005070:	078e                	slli	a5,a5,0x3
    80005072:	953e                	add	a0,a0,a5
    80005074:	651c                	ld	a5,8(a0)
    80005076:	c395                	beqz	a5,8000509a <argfd+0x64>
    return -1;
  if(pfd)
    80005078:	00090463          	beqz	s2,80005080 <argfd+0x4a>
    *pfd = fd;
    8000507c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005080:	4501                	li	a0,0
  if(pf)
    80005082:	c091                	beqz	s1,80005086 <argfd+0x50>
    *pf = f;
    80005084:	e09c                	sd	a5,0(s1)
}
    80005086:	70a2                	ld	ra,40(sp)
    80005088:	7402                	ld	s0,32(sp)
    8000508a:	64e2                	ld	s1,24(sp)
    8000508c:	6942                	ld	s2,16(sp)
    8000508e:	6145                	addi	sp,sp,48
    80005090:	8082                	ret
    return -1;
    80005092:	557d                	li	a0,-1
    80005094:	bfcd                	j	80005086 <argfd+0x50>
    return -1;
    80005096:	557d                	li	a0,-1
    80005098:	b7fd                	j	80005086 <argfd+0x50>
    8000509a:	557d                	li	a0,-1
    8000509c:	b7ed                	j	80005086 <argfd+0x50>

000000008000509e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000509e:	1101                	addi	sp,sp,-32
    800050a0:	ec06                	sd	ra,24(sp)
    800050a2:	e822                	sd	s0,16(sp)
    800050a4:	e426                	sd	s1,8(sp)
    800050a6:	1000                	addi	s0,sp,32
    800050a8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	8d4080e7          	jalr	-1836(ra) # 8000197e <myproc>
    800050b2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050b4:	0d850793          	addi	a5,a0,216
    800050b8:	4501                	li	a0,0
    800050ba:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050bc:	6398                	ld	a4,0(a5)
    800050be:	cb19                	beqz	a4,800050d4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050c0:	2505                	addiw	a0,a0,1
    800050c2:	07a1                	addi	a5,a5,8
    800050c4:	fed51ce3          	bne	a0,a3,800050bc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050c8:	557d                	li	a0,-1
}
    800050ca:	60e2                	ld	ra,24(sp)
    800050cc:	6442                	ld	s0,16(sp)
    800050ce:	64a2                	ld	s1,8(sp)
    800050d0:	6105                	addi	sp,sp,32
    800050d2:	8082                	ret
      p->ofile[fd] = f;
    800050d4:	01a50793          	addi	a5,a0,26
    800050d8:	078e                	slli	a5,a5,0x3
    800050da:	963e                	add	a2,a2,a5
    800050dc:	e604                	sd	s1,8(a2)
      return fd;
    800050de:	b7f5                	j	800050ca <fdalloc+0x2c>

00000000800050e0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050e0:	715d                	addi	sp,sp,-80
    800050e2:	e486                	sd	ra,72(sp)
    800050e4:	e0a2                	sd	s0,64(sp)
    800050e6:	fc26                	sd	s1,56(sp)
    800050e8:	f84a                	sd	s2,48(sp)
    800050ea:	f44e                	sd	s3,40(sp)
    800050ec:	f052                	sd	s4,32(sp)
    800050ee:	ec56                	sd	s5,24(sp)
    800050f0:	0880                	addi	s0,sp,80
    800050f2:	89ae                	mv	s3,a1
    800050f4:	8ab2                	mv	s5,a2
    800050f6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050f8:	fb040593          	addi	a1,s0,-80
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	e72080e7          	jalr	-398(ra) # 80003f6e <nameiparent>
    80005104:	892a                	mv	s2,a0
    80005106:	12050e63          	beqz	a0,80005242 <create+0x162>
    return 0;

  ilock(dp);
    8000510a:	ffffe097          	auipc	ra,0xffffe
    8000510e:	690080e7          	jalr	1680(ra) # 8000379a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005112:	4601                	li	a2,0
    80005114:	fb040593          	addi	a1,s0,-80
    80005118:	854a                	mv	a0,s2
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	b64080e7          	jalr	-1180(ra) # 80003c7e <dirlookup>
    80005122:	84aa                	mv	s1,a0
    80005124:	c921                	beqz	a0,80005174 <create+0x94>
    iunlockput(dp);
    80005126:	854a                	mv	a0,s2
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	8d4080e7          	jalr	-1836(ra) # 800039fc <iunlockput>
    ilock(ip);
    80005130:	8526                	mv	a0,s1
    80005132:	ffffe097          	auipc	ra,0xffffe
    80005136:	668080e7          	jalr	1640(ra) # 8000379a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000513a:	2981                	sext.w	s3,s3
    8000513c:	4789                	li	a5,2
    8000513e:	02f99463          	bne	s3,a5,80005166 <create+0x86>
    80005142:	0444d783          	lhu	a5,68(s1)
    80005146:	37f9                	addiw	a5,a5,-2
    80005148:	17c2                	slli	a5,a5,0x30
    8000514a:	93c1                	srli	a5,a5,0x30
    8000514c:	4705                	li	a4,1
    8000514e:	00f76c63          	bltu	a4,a5,80005166 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005152:	8526                	mv	a0,s1
    80005154:	60a6                	ld	ra,72(sp)
    80005156:	6406                	ld	s0,64(sp)
    80005158:	74e2                	ld	s1,56(sp)
    8000515a:	7942                	ld	s2,48(sp)
    8000515c:	79a2                	ld	s3,40(sp)
    8000515e:	7a02                	ld	s4,32(sp)
    80005160:	6ae2                	ld	s5,24(sp)
    80005162:	6161                	addi	sp,sp,80
    80005164:	8082                	ret
    iunlockput(ip);
    80005166:	8526                	mv	a0,s1
    80005168:	fffff097          	auipc	ra,0xfffff
    8000516c:	894080e7          	jalr	-1900(ra) # 800039fc <iunlockput>
    return 0;
    80005170:	4481                	li	s1,0
    80005172:	b7c5                	j	80005152 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005174:	85ce                	mv	a1,s3
    80005176:	00092503          	lw	a0,0(s2)
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	488080e7          	jalr	1160(ra) # 80003602 <ialloc>
    80005182:	84aa                	mv	s1,a0
    80005184:	c521                	beqz	a0,800051cc <create+0xec>
  ilock(ip);
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	614080e7          	jalr	1556(ra) # 8000379a <ilock>
  ip->major = major;
    8000518e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005192:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005196:	4a05                	li	s4,1
    80005198:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000519c:	8526                	mv	a0,s1
    8000519e:	ffffe097          	auipc	ra,0xffffe
    800051a2:	532080e7          	jalr	1330(ra) # 800036d0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051a6:	2981                	sext.w	s3,s3
    800051a8:	03498a63          	beq	s3,s4,800051dc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ac:	40d0                	lw	a2,4(s1)
    800051ae:	fb040593          	addi	a1,s0,-80
    800051b2:	854a                	mv	a0,s2
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	cda080e7          	jalr	-806(ra) # 80003e8e <dirlink>
    800051bc:	06054b63          	bltz	a0,80005232 <create+0x152>
  iunlockput(dp);
    800051c0:	854a                	mv	a0,s2
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	83a080e7          	jalr	-1990(ra) # 800039fc <iunlockput>
  return ip;
    800051ca:	b761                	j	80005152 <create+0x72>
    panic("create: ialloc");
    800051cc:	00003517          	auipc	a0,0x3
    800051d0:	60450513          	addi	a0,a0,1540 # 800087d0 <syscalls+0x2a0>
    800051d4:	ffffb097          	auipc	ra,0xffffb
    800051d8:	356080e7          	jalr	854(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800051dc:	04a95783          	lhu	a5,74(s2)
    800051e0:	2785                	addiw	a5,a5,1
    800051e2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051e6:	854a                	mv	a0,s2
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	4e8080e7          	jalr	1256(ra) # 800036d0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f0:	40d0                	lw	a2,4(s1)
    800051f2:	00003597          	auipc	a1,0x3
    800051f6:	5ee58593          	addi	a1,a1,1518 # 800087e0 <syscalls+0x2b0>
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	c92080e7          	jalr	-878(ra) # 80003e8e <dirlink>
    80005204:	00054f63          	bltz	a0,80005222 <create+0x142>
    80005208:	00492603          	lw	a2,4(s2)
    8000520c:	00003597          	auipc	a1,0x3
    80005210:	5dc58593          	addi	a1,a1,1500 # 800087e8 <syscalls+0x2b8>
    80005214:	8526                	mv	a0,s1
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	c78080e7          	jalr	-904(ra) # 80003e8e <dirlink>
    8000521e:	f80557e3          	bgez	a0,800051ac <create+0xcc>
      panic("create dots");
    80005222:	00003517          	auipc	a0,0x3
    80005226:	5ce50513          	addi	a0,a0,1486 # 800087f0 <syscalls+0x2c0>
    8000522a:	ffffb097          	auipc	ra,0xffffb
    8000522e:	300080e7          	jalr	768(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005232:	00003517          	auipc	a0,0x3
    80005236:	5ce50513          	addi	a0,a0,1486 # 80008800 <syscalls+0x2d0>
    8000523a:	ffffb097          	auipc	ra,0xffffb
    8000523e:	2f0080e7          	jalr	752(ra) # 8000052a <panic>
    return 0;
    80005242:	84aa                	mv	s1,a0
    80005244:	b739                	j	80005152 <create+0x72>

0000000080005246 <sys_dup>:
{
    80005246:	7179                	addi	sp,sp,-48
    80005248:	f406                	sd	ra,40(sp)
    8000524a:	f022                	sd	s0,32(sp)
    8000524c:	ec26                	sd	s1,24(sp)
    8000524e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005250:	fd840613          	addi	a2,s0,-40
    80005254:	4581                	li	a1,0
    80005256:	4501                	li	a0,0
    80005258:	00000097          	auipc	ra,0x0
    8000525c:	dde080e7          	jalr	-546(ra) # 80005036 <argfd>
    return -1;
    80005260:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005262:	02054363          	bltz	a0,80005288 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005266:	fd843503          	ld	a0,-40(s0)
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	e34080e7          	jalr	-460(ra) # 8000509e <fdalloc>
    80005272:	84aa                	mv	s1,a0
    return -1;
    80005274:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005276:	00054963          	bltz	a0,80005288 <sys_dup+0x42>
  filedup(f);
    8000527a:	fd843503          	ld	a0,-40(s0)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	36c080e7          	jalr	876(ra) # 800045ea <filedup>
  return fd;
    80005286:	87a6                	mv	a5,s1
}
    80005288:	853e                	mv	a0,a5
    8000528a:	70a2                	ld	ra,40(sp)
    8000528c:	7402                	ld	s0,32(sp)
    8000528e:	64e2                	ld	s1,24(sp)
    80005290:	6145                	addi	sp,sp,48
    80005292:	8082                	ret

0000000080005294 <sys_read>:
{
    80005294:	7179                	addi	sp,sp,-48
    80005296:	f406                	sd	ra,40(sp)
    80005298:	f022                	sd	s0,32(sp)
    8000529a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529c:	fe840613          	addi	a2,s0,-24
    800052a0:	4581                	li	a1,0
    800052a2:	4501                	li	a0,0
    800052a4:	00000097          	auipc	ra,0x0
    800052a8:	d92080e7          	jalr	-622(ra) # 80005036 <argfd>
    return -1;
    800052ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ae:	04054163          	bltz	a0,800052f0 <sys_read+0x5c>
    800052b2:	fe440593          	addi	a1,s0,-28
    800052b6:	4509                	li	a0,2
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	866080e7          	jalr	-1946(ra) # 80002b1e <argint>
    return -1;
    800052c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c2:	02054763          	bltz	a0,800052f0 <sys_read+0x5c>
    800052c6:	fd840593          	addi	a1,s0,-40
    800052ca:	4505                	li	a0,1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	874080e7          	jalr	-1932(ra) # 80002b40 <argaddr>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d6:	00054d63          	bltz	a0,800052f0 <sys_read+0x5c>
  return fileread(f, p, n);
    800052da:	fe442603          	lw	a2,-28(s0)
    800052de:	fd843583          	ld	a1,-40(s0)
    800052e2:	fe843503          	ld	a0,-24(s0)
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	490080e7          	jalr	1168(ra) # 80004776 <fileread>
    800052ee:	87aa                	mv	a5,a0
}
    800052f0:	853e                	mv	a0,a5
    800052f2:	70a2                	ld	ra,40(sp)
    800052f4:	7402                	ld	s0,32(sp)
    800052f6:	6145                	addi	sp,sp,48
    800052f8:	8082                	ret

00000000800052fa <sys_write>:
{
    800052fa:	7179                	addi	sp,sp,-48
    800052fc:	f406                	sd	ra,40(sp)
    800052fe:	f022                	sd	s0,32(sp)
    80005300:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005302:	fe840613          	addi	a2,s0,-24
    80005306:	4581                	li	a1,0
    80005308:	4501                	li	a0,0
    8000530a:	00000097          	auipc	ra,0x0
    8000530e:	d2c080e7          	jalr	-724(ra) # 80005036 <argfd>
    return -1;
    80005312:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005314:	04054163          	bltz	a0,80005356 <sys_write+0x5c>
    80005318:	fe440593          	addi	a1,s0,-28
    8000531c:	4509                	li	a0,2
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	800080e7          	jalr	-2048(ra) # 80002b1e <argint>
    return -1;
    80005326:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005328:	02054763          	bltz	a0,80005356 <sys_write+0x5c>
    8000532c:	fd840593          	addi	a1,s0,-40
    80005330:	4505                	li	a0,1
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	80e080e7          	jalr	-2034(ra) # 80002b40 <argaddr>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533c:	00054d63          	bltz	a0,80005356 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005340:	fe442603          	lw	a2,-28(s0)
    80005344:	fd843583          	ld	a1,-40(s0)
    80005348:	fe843503          	ld	a0,-24(s0)
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	4ec080e7          	jalr	1260(ra) # 80004838 <filewrite>
    80005354:	87aa                	mv	a5,a0
}
    80005356:	853e                	mv	a0,a5
    80005358:	70a2                	ld	ra,40(sp)
    8000535a:	7402                	ld	s0,32(sp)
    8000535c:	6145                	addi	sp,sp,48
    8000535e:	8082                	ret

0000000080005360 <sys_close>:
{
    80005360:	1101                	addi	sp,sp,-32
    80005362:	ec06                	sd	ra,24(sp)
    80005364:	e822                	sd	s0,16(sp)
    80005366:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005368:	fe040613          	addi	a2,s0,-32
    8000536c:	fec40593          	addi	a1,s0,-20
    80005370:	4501                	li	a0,0
    80005372:	00000097          	auipc	ra,0x0
    80005376:	cc4080e7          	jalr	-828(ra) # 80005036 <argfd>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000537c:	02054463          	bltz	a0,800053a4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	5fe080e7          	jalr	1534(ra) # 8000197e <myproc>
    80005388:	fec42783          	lw	a5,-20(s0)
    8000538c:	07e9                	addi	a5,a5,26
    8000538e:	078e                	slli	a5,a5,0x3
    80005390:	97aa                	add	a5,a5,a0
    80005392:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005396:	fe043503          	ld	a0,-32(s0)
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	2a2080e7          	jalr	674(ra) # 8000463c <fileclose>
  return 0;
    800053a2:	4781                	li	a5,0
}
    800053a4:	853e                	mv	a0,a5
    800053a6:	60e2                	ld	ra,24(sp)
    800053a8:	6442                	ld	s0,16(sp)
    800053aa:	6105                	addi	sp,sp,32
    800053ac:	8082                	ret

00000000800053ae <sys_fstat>:
{
    800053ae:	1101                	addi	sp,sp,-32
    800053b0:	ec06                	sd	ra,24(sp)
    800053b2:	e822                	sd	s0,16(sp)
    800053b4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053b6:	fe840613          	addi	a2,s0,-24
    800053ba:	4581                	li	a1,0
    800053bc:	4501                	li	a0,0
    800053be:	00000097          	auipc	ra,0x0
    800053c2:	c78080e7          	jalr	-904(ra) # 80005036 <argfd>
    return -1;
    800053c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c8:	02054563          	bltz	a0,800053f2 <sys_fstat+0x44>
    800053cc:	fe040593          	addi	a1,s0,-32
    800053d0:	4505                	li	a0,1
    800053d2:	ffffd097          	auipc	ra,0xffffd
    800053d6:	76e080e7          	jalr	1902(ra) # 80002b40 <argaddr>
    return -1;
    800053da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053dc:	00054b63          	bltz	a0,800053f2 <sys_fstat+0x44>
  return filestat(f, st);
    800053e0:	fe043583          	ld	a1,-32(s0)
    800053e4:	fe843503          	ld	a0,-24(s0)
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	31c080e7          	jalr	796(ra) # 80004704 <filestat>
    800053f0:	87aa                	mv	a5,a0
}
    800053f2:	853e                	mv	a0,a5
    800053f4:	60e2                	ld	ra,24(sp)
    800053f6:	6442                	ld	s0,16(sp)
    800053f8:	6105                	addi	sp,sp,32
    800053fa:	8082                	ret

00000000800053fc <sys_link>:
{
    800053fc:	7169                	addi	sp,sp,-304
    800053fe:	f606                	sd	ra,296(sp)
    80005400:	f222                	sd	s0,288(sp)
    80005402:	ee26                	sd	s1,280(sp)
    80005404:	ea4a                	sd	s2,272(sp)
    80005406:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005408:	08000613          	li	a2,128
    8000540c:	ed040593          	addi	a1,s0,-304
    80005410:	4501                	li	a0,0
    80005412:	ffffd097          	auipc	ra,0xffffd
    80005416:	750080e7          	jalr	1872(ra) # 80002b62 <argstr>
    return -1;
    8000541a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541c:	10054e63          	bltz	a0,80005538 <sys_link+0x13c>
    80005420:	08000613          	li	a2,128
    80005424:	f5040593          	addi	a1,s0,-176
    80005428:	4505                	li	a0,1
    8000542a:	ffffd097          	auipc	ra,0xffffd
    8000542e:	738080e7          	jalr	1848(ra) # 80002b62 <argstr>
    return -1;
    80005432:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005434:	10054263          	bltz	a0,80005538 <sys_link+0x13c>
  begin_op();
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	d38080e7          	jalr	-712(ra) # 80004170 <begin_op>
  if((ip = namei(old)) == 0){
    80005440:	ed040513          	addi	a0,s0,-304
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	b0c080e7          	jalr	-1268(ra) # 80003f50 <namei>
    8000544c:	84aa                	mv	s1,a0
    8000544e:	c551                	beqz	a0,800054da <sys_link+0xde>
  ilock(ip);
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	34a080e7          	jalr	842(ra) # 8000379a <ilock>
  if(ip->type == T_DIR){
    80005458:	04449703          	lh	a4,68(s1)
    8000545c:	4785                	li	a5,1
    8000545e:	08f70463          	beq	a4,a5,800054e6 <sys_link+0xea>
  ip->nlink++;
    80005462:	04a4d783          	lhu	a5,74(s1)
    80005466:	2785                	addiw	a5,a5,1
    80005468:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	262080e7          	jalr	610(ra) # 800036d0 <iupdate>
  iunlock(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	3e4080e7          	jalr	996(ra) # 8000385c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005480:	fd040593          	addi	a1,s0,-48
    80005484:	f5040513          	addi	a0,s0,-176
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	ae6080e7          	jalr	-1306(ra) # 80003f6e <nameiparent>
    80005490:	892a                	mv	s2,a0
    80005492:	c935                	beqz	a0,80005506 <sys_link+0x10a>
  ilock(dp);
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	306080e7          	jalr	774(ra) # 8000379a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000549c:	00092703          	lw	a4,0(s2)
    800054a0:	409c                	lw	a5,0(s1)
    800054a2:	04f71d63          	bne	a4,a5,800054fc <sys_link+0x100>
    800054a6:	40d0                	lw	a2,4(s1)
    800054a8:	fd040593          	addi	a1,s0,-48
    800054ac:	854a                	mv	a0,s2
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	9e0080e7          	jalr	-1568(ra) # 80003e8e <dirlink>
    800054b6:	04054363          	bltz	a0,800054fc <sys_link+0x100>
  iunlockput(dp);
    800054ba:	854a                	mv	a0,s2
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	540080e7          	jalr	1344(ra) # 800039fc <iunlockput>
  iput(ip);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	48e080e7          	jalr	1166(ra) # 80003954 <iput>
  end_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	d22080e7          	jalr	-734(ra) # 800041f0 <end_op>
  return 0;
    800054d6:	4781                	li	a5,0
    800054d8:	a085                	j	80005538 <sys_link+0x13c>
    end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	d16080e7          	jalr	-746(ra) # 800041f0 <end_op>
    return -1;
    800054e2:	57fd                	li	a5,-1
    800054e4:	a891                	j	80005538 <sys_link+0x13c>
    iunlockput(ip);
    800054e6:	8526                	mv	a0,s1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	514080e7          	jalr	1300(ra) # 800039fc <iunlockput>
    end_op();
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	d00080e7          	jalr	-768(ra) # 800041f0 <end_op>
    return -1;
    800054f8:	57fd                	li	a5,-1
    800054fa:	a83d                	j	80005538 <sys_link+0x13c>
    iunlockput(dp);
    800054fc:	854a                	mv	a0,s2
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	4fe080e7          	jalr	1278(ra) # 800039fc <iunlockput>
  ilock(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	292080e7          	jalr	658(ra) # 8000379a <ilock>
  ip->nlink--;
    80005510:	04a4d783          	lhu	a5,74(s1)
    80005514:	37fd                	addiw	a5,a5,-1
    80005516:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	1b4080e7          	jalr	436(ra) # 800036d0 <iupdate>
  iunlockput(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	4d6080e7          	jalr	1238(ra) # 800039fc <iunlockput>
  end_op();
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	cc2080e7          	jalr	-830(ra) # 800041f0 <end_op>
  return -1;
    80005536:	57fd                	li	a5,-1
}
    80005538:	853e                	mv	a0,a5
    8000553a:	70b2                	ld	ra,296(sp)
    8000553c:	7412                	ld	s0,288(sp)
    8000553e:	64f2                	ld	s1,280(sp)
    80005540:	6952                	ld	s2,272(sp)
    80005542:	6155                	addi	sp,sp,304
    80005544:	8082                	ret

0000000080005546 <sys_unlink>:
{
    80005546:	7151                	addi	sp,sp,-240
    80005548:	f586                	sd	ra,232(sp)
    8000554a:	f1a2                	sd	s0,224(sp)
    8000554c:	eda6                	sd	s1,216(sp)
    8000554e:	e9ca                	sd	s2,208(sp)
    80005550:	e5ce                	sd	s3,200(sp)
    80005552:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005554:	08000613          	li	a2,128
    80005558:	f3040593          	addi	a1,s0,-208
    8000555c:	4501                	li	a0,0
    8000555e:	ffffd097          	auipc	ra,0xffffd
    80005562:	604080e7          	jalr	1540(ra) # 80002b62 <argstr>
    80005566:	18054163          	bltz	a0,800056e8 <sys_unlink+0x1a2>
  begin_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	c06080e7          	jalr	-1018(ra) # 80004170 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005572:	fb040593          	addi	a1,s0,-80
    80005576:	f3040513          	addi	a0,s0,-208
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	9f4080e7          	jalr	-1548(ra) # 80003f6e <nameiparent>
    80005582:	84aa                	mv	s1,a0
    80005584:	c979                	beqz	a0,8000565a <sys_unlink+0x114>
  ilock(dp);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	214080e7          	jalr	532(ra) # 8000379a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000558e:	00003597          	auipc	a1,0x3
    80005592:	25258593          	addi	a1,a1,594 # 800087e0 <syscalls+0x2b0>
    80005596:	fb040513          	addi	a0,s0,-80
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	6ca080e7          	jalr	1738(ra) # 80003c64 <namecmp>
    800055a2:	14050a63          	beqz	a0,800056f6 <sys_unlink+0x1b0>
    800055a6:	00003597          	auipc	a1,0x3
    800055aa:	24258593          	addi	a1,a1,578 # 800087e8 <syscalls+0x2b8>
    800055ae:	fb040513          	addi	a0,s0,-80
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	6b2080e7          	jalr	1714(ra) # 80003c64 <namecmp>
    800055ba:	12050e63          	beqz	a0,800056f6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055be:	f2c40613          	addi	a2,s0,-212
    800055c2:	fb040593          	addi	a1,s0,-80
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	6b6080e7          	jalr	1718(ra) # 80003c7e <dirlookup>
    800055d0:	892a                	mv	s2,a0
    800055d2:	12050263          	beqz	a0,800056f6 <sys_unlink+0x1b0>
  ilock(ip);
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	1c4080e7          	jalr	452(ra) # 8000379a <ilock>
  if(ip->nlink < 1)
    800055de:	04a91783          	lh	a5,74(s2)
    800055e2:	08f05263          	blez	a5,80005666 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055e6:	04491703          	lh	a4,68(s2)
    800055ea:	4785                	li	a5,1
    800055ec:	08f70563          	beq	a4,a5,80005676 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055f0:	4641                	li	a2,16
    800055f2:	4581                	li	a1,0
    800055f4:	fc040513          	addi	a0,s0,-64
    800055f8:	ffffb097          	auipc	ra,0xffffb
    800055fc:	6c6080e7          	jalr	1734(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005600:	4741                	li	a4,16
    80005602:	f2c42683          	lw	a3,-212(s0)
    80005606:	fc040613          	addi	a2,s0,-64
    8000560a:	4581                	li	a1,0
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	538080e7          	jalr	1336(ra) # 80003b46 <writei>
    80005616:	47c1                	li	a5,16
    80005618:	0af51563          	bne	a0,a5,800056c2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000561c:	04491703          	lh	a4,68(s2)
    80005620:	4785                	li	a5,1
    80005622:	0af70863          	beq	a4,a5,800056d2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	3d4080e7          	jalr	980(ra) # 800039fc <iunlockput>
  ip->nlink--;
    80005630:	04a95783          	lhu	a5,74(s2)
    80005634:	37fd                	addiw	a5,a5,-1
    80005636:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000563a:	854a                	mv	a0,s2
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	094080e7          	jalr	148(ra) # 800036d0 <iupdate>
  iunlockput(ip);
    80005644:	854a                	mv	a0,s2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	3b6080e7          	jalr	950(ra) # 800039fc <iunlockput>
  end_op();
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	ba2080e7          	jalr	-1118(ra) # 800041f0 <end_op>
  return 0;
    80005656:	4501                	li	a0,0
    80005658:	a84d                	j	8000570a <sys_unlink+0x1c4>
    end_op();
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	b96080e7          	jalr	-1130(ra) # 800041f0 <end_op>
    return -1;
    80005662:	557d                	li	a0,-1
    80005664:	a05d                	j	8000570a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005666:	00003517          	auipc	a0,0x3
    8000566a:	1aa50513          	addi	a0,a0,426 # 80008810 <syscalls+0x2e0>
    8000566e:	ffffb097          	auipc	ra,0xffffb
    80005672:	ebc080e7          	jalr	-324(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005676:	04c92703          	lw	a4,76(s2)
    8000567a:	02000793          	li	a5,32
    8000567e:	f6e7f9e3          	bgeu	a5,a4,800055f0 <sys_unlink+0xaa>
    80005682:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005686:	4741                	li	a4,16
    80005688:	86ce                	mv	a3,s3
    8000568a:	f1840613          	addi	a2,s0,-232
    8000568e:	4581                	li	a1,0
    80005690:	854a                	mv	a0,s2
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	3bc080e7          	jalr	956(ra) # 80003a4e <readi>
    8000569a:	47c1                	li	a5,16
    8000569c:	00f51b63          	bne	a0,a5,800056b2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056a0:	f1845783          	lhu	a5,-232(s0)
    800056a4:	e7a1                	bnez	a5,800056ec <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056a6:	29c1                	addiw	s3,s3,16
    800056a8:	04c92783          	lw	a5,76(s2)
    800056ac:	fcf9ede3          	bltu	s3,a5,80005686 <sys_unlink+0x140>
    800056b0:	b781                	j	800055f0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056b2:	00003517          	auipc	a0,0x3
    800056b6:	17650513          	addi	a0,a0,374 # 80008828 <syscalls+0x2f8>
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	e70080e7          	jalr	-400(ra) # 8000052a <panic>
    panic("unlink: writei");
    800056c2:	00003517          	auipc	a0,0x3
    800056c6:	17e50513          	addi	a0,a0,382 # 80008840 <syscalls+0x310>
    800056ca:	ffffb097          	auipc	ra,0xffffb
    800056ce:	e60080e7          	jalr	-416(ra) # 8000052a <panic>
    dp->nlink--;
    800056d2:	04a4d783          	lhu	a5,74(s1)
    800056d6:	37fd                	addiw	a5,a5,-1
    800056d8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	ff2080e7          	jalr	-14(ra) # 800036d0 <iupdate>
    800056e6:	b781                	j	80005626 <sys_unlink+0xe0>
    return -1;
    800056e8:	557d                	li	a0,-1
    800056ea:	a005                	j	8000570a <sys_unlink+0x1c4>
    iunlockput(ip);
    800056ec:	854a                	mv	a0,s2
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	30e080e7          	jalr	782(ra) # 800039fc <iunlockput>
  iunlockput(dp);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	304080e7          	jalr	772(ra) # 800039fc <iunlockput>
  end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	af0080e7          	jalr	-1296(ra) # 800041f0 <end_op>
  return -1;
    80005708:	557d                	li	a0,-1
}
    8000570a:	70ae                	ld	ra,232(sp)
    8000570c:	740e                	ld	s0,224(sp)
    8000570e:	64ee                	ld	s1,216(sp)
    80005710:	694e                	ld	s2,208(sp)
    80005712:	69ae                	ld	s3,200(sp)
    80005714:	616d                	addi	sp,sp,240
    80005716:	8082                	ret

0000000080005718 <sys_open>:

uint64
sys_open(void)
{
    80005718:	7131                	addi	sp,sp,-192
    8000571a:	fd06                	sd	ra,184(sp)
    8000571c:	f922                	sd	s0,176(sp)
    8000571e:	f526                	sd	s1,168(sp)
    80005720:	f14a                	sd	s2,160(sp)
    80005722:	ed4e                	sd	s3,152(sp)
    80005724:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005726:	08000613          	li	a2,128
    8000572a:	f5040593          	addi	a1,s0,-176
    8000572e:	4501                	li	a0,0
    80005730:	ffffd097          	auipc	ra,0xffffd
    80005734:	432080e7          	jalr	1074(ra) # 80002b62 <argstr>
    return -1;
    80005738:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000573a:	0c054163          	bltz	a0,800057fc <sys_open+0xe4>
    8000573e:	f4c40593          	addi	a1,s0,-180
    80005742:	4505                	li	a0,1
    80005744:	ffffd097          	auipc	ra,0xffffd
    80005748:	3da080e7          	jalr	986(ra) # 80002b1e <argint>
    8000574c:	0a054863          	bltz	a0,800057fc <sys_open+0xe4>

  begin_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	a20080e7          	jalr	-1504(ra) # 80004170 <begin_op>

  if(omode & O_CREATE){
    80005758:	f4c42783          	lw	a5,-180(s0)
    8000575c:	2007f793          	andi	a5,a5,512
    80005760:	cbdd                	beqz	a5,80005816 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005762:	4681                	li	a3,0
    80005764:	4601                	li	a2,0
    80005766:	4589                	li	a1,2
    80005768:	f5040513          	addi	a0,s0,-176
    8000576c:	00000097          	auipc	ra,0x0
    80005770:	974080e7          	jalr	-1676(ra) # 800050e0 <create>
    80005774:	892a                	mv	s2,a0
    if(ip == 0){
    80005776:	c959                	beqz	a0,8000580c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005778:	04491703          	lh	a4,68(s2)
    8000577c:	478d                	li	a5,3
    8000577e:	00f71763          	bne	a4,a5,8000578c <sys_open+0x74>
    80005782:	04695703          	lhu	a4,70(s2)
    80005786:	47a5                	li	a5,9
    80005788:	0ce7ec63          	bltu	a5,a4,80005860 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	df4080e7          	jalr	-524(ra) # 80004580 <filealloc>
    80005794:	89aa                	mv	s3,a0
    80005796:	10050263          	beqz	a0,8000589a <sys_open+0x182>
    8000579a:	00000097          	auipc	ra,0x0
    8000579e:	904080e7          	jalr	-1788(ra) # 8000509e <fdalloc>
    800057a2:	84aa                	mv	s1,a0
    800057a4:	0e054663          	bltz	a0,80005890 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057a8:	04491703          	lh	a4,68(s2)
    800057ac:	478d                	li	a5,3
    800057ae:	0cf70463          	beq	a4,a5,80005876 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057b2:	4789                	li	a5,2
    800057b4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057b8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057bc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057c0:	f4c42783          	lw	a5,-180(s0)
    800057c4:	0017c713          	xori	a4,a5,1
    800057c8:	8b05                	andi	a4,a4,1
    800057ca:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ce:	0037f713          	andi	a4,a5,3
    800057d2:	00e03733          	snez	a4,a4
    800057d6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057da:	4007f793          	andi	a5,a5,1024
    800057de:	c791                	beqz	a5,800057ea <sys_open+0xd2>
    800057e0:	04491703          	lh	a4,68(s2)
    800057e4:	4789                	li	a5,2
    800057e6:	08f70f63          	beq	a4,a5,80005884 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	070080e7          	jalr	112(ra) # 8000385c <iunlock>
  end_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	9fc080e7          	jalr	-1540(ra) # 800041f0 <end_op>

  return fd;
}
    800057fc:	8526                	mv	a0,s1
    800057fe:	70ea                	ld	ra,184(sp)
    80005800:	744a                	ld	s0,176(sp)
    80005802:	74aa                	ld	s1,168(sp)
    80005804:	790a                	ld	s2,160(sp)
    80005806:	69ea                	ld	s3,152(sp)
    80005808:	6129                	addi	sp,sp,192
    8000580a:	8082                	ret
      end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	9e4080e7          	jalr	-1564(ra) # 800041f0 <end_op>
      return -1;
    80005814:	b7e5                	j	800057fc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005816:	f5040513          	addi	a0,s0,-176
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	736080e7          	jalr	1846(ra) # 80003f50 <namei>
    80005822:	892a                	mv	s2,a0
    80005824:	c905                	beqz	a0,80005854 <sys_open+0x13c>
    ilock(ip);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	f74080e7          	jalr	-140(ra) # 8000379a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000582e:	04491703          	lh	a4,68(s2)
    80005832:	4785                	li	a5,1
    80005834:	f4f712e3          	bne	a4,a5,80005778 <sys_open+0x60>
    80005838:	f4c42783          	lw	a5,-180(s0)
    8000583c:	dba1                	beqz	a5,8000578c <sys_open+0x74>
      iunlockput(ip);
    8000583e:	854a                	mv	a0,s2
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	1bc080e7          	jalr	444(ra) # 800039fc <iunlockput>
      end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	9a8080e7          	jalr	-1624(ra) # 800041f0 <end_op>
      return -1;
    80005850:	54fd                	li	s1,-1
    80005852:	b76d                	j	800057fc <sys_open+0xe4>
      end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	99c080e7          	jalr	-1636(ra) # 800041f0 <end_op>
      return -1;
    8000585c:	54fd                	li	s1,-1
    8000585e:	bf79                	j	800057fc <sys_open+0xe4>
    iunlockput(ip);
    80005860:	854a                	mv	a0,s2
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	19a080e7          	jalr	410(ra) # 800039fc <iunlockput>
    end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	986080e7          	jalr	-1658(ra) # 800041f0 <end_op>
    return -1;
    80005872:	54fd                	li	s1,-1
    80005874:	b761                	j	800057fc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005876:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000587a:	04691783          	lh	a5,70(s2)
    8000587e:	02f99223          	sh	a5,36(s3)
    80005882:	bf2d                	j	800057bc <sys_open+0xa4>
    itrunc(ip);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	022080e7          	jalr	34(ra) # 800038a8 <itrunc>
    8000588e:	bfb1                	j	800057ea <sys_open+0xd2>
      fileclose(f);
    80005890:	854e                	mv	a0,s3
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	daa080e7          	jalr	-598(ra) # 8000463c <fileclose>
    iunlockput(ip);
    8000589a:	854a                	mv	a0,s2
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	160080e7          	jalr	352(ra) # 800039fc <iunlockput>
    end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	94c080e7          	jalr	-1716(ra) # 800041f0 <end_op>
    return -1;
    800058ac:	54fd                	li	s1,-1
    800058ae:	b7b9                	j	800057fc <sys_open+0xe4>

00000000800058b0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058b0:	7175                	addi	sp,sp,-144
    800058b2:	e506                	sd	ra,136(sp)
    800058b4:	e122                	sd	s0,128(sp)
    800058b6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	8b8080e7          	jalr	-1864(ra) # 80004170 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058c0:	08000613          	li	a2,128
    800058c4:	f7040593          	addi	a1,s0,-144
    800058c8:	4501                	li	a0,0
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	298080e7          	jalr	664(ra) # 80002b62 <argstr>
    800058d2:	02054963          	bltz	a0,80005904 <sys_mkdir+0x54>
    800058d6:	4681                	li	a3,0
    800058d8:	4601                	li	a2,0
    800058da:	4585                	li	a1,1
    800058dc:	f7040513          	addi	a0,s0,-144
    800058e0:	00000097          	auipc	ra,0x0
    800058e4:	800080e7          	jalr	-2048(ra) # 800050e0 <create>
    800058e8:	cd11                	beqz	a0,80005904 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	112080e7          	jalr	274(ra) # 800039fc <iunlockput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	8fe080e7          	jalr	-1794(ra) # 800041f0 <end_op>
  return 0;
    800058fa:	4501                	li	a0,0
}
    800058fc:	60aa                	ld	ra,136(sp)
    800058fe:	640a                	ld	s0,128(sp)
    80005900:	6149                	addi	sp,sp,144
    80005902:	8082                	ret
    end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	8ec080e7          	jalr	-1812(ra) # 800041f0 <end_op>
    return -1;
    8000590c:	557d                	li	a0,-1
    8000590e:	b7fd                	j	800058fc <sys_mkdir+0x4c>

0000000080005910 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005910:	7135                	addi	sp,sp,-160
    80005912:	ed06                	sd	ra,152(sp)
    80005914:	e922                	sd	s0,144(sp)
    80005916:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	858080e7          	jalr	-1960(ra) # 80004170 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005920:	08000613          	li	a2,128
    80005924:	f7040593          	addi	a1,s0,-144
    80005928:	4501                	li	a0,0
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	238080e7          	jalr	568(ra) # 80002b62 <argstr>
    80005932:	04054a63          	bltz	a0,80005986 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005936:	f6c40593          	addi	a1,s0,-148
    8000593a:	4505                	li	a0,1
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	1e2080e7          	jalr	482(ra) # 80002b1e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005944:	04054163          	bltz	a0,80005986 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005948:	f6840593          	addi	a1,s0,-152
    8000594c:	4509                	li	a0,2
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	1d0080e7          	jalr	464(ra) # 80002b1e <argint>
     argint(1, &major) < 0 ||
    80005956:	02054863          	bltz	a0,80005986 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000595a:	f6841683          	lh	a3,-152(s0)
    8000595e:	f6c41603          	lh	a2,-148(s0)
    80005962:	458d                	li	a1,3
    80005964:	f7040513          	addi	a0,s0,-144
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	778080e7          	jalr	1912(ra) # 800050e0 <create>
     argint(2, &minor) < 0 ||
    80005970:	c919                	beqz	a0,80005986 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	08a080e7          	jalr	138(ra) # 800039fc <iunlockput>
  end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	876080e7          	jalr	-1930(ra) # 800041f0 <end_op>
  return 0;
    80005982:	4501                	li	a0,0
    80005984:	a031                	j	80005990 <sys_mknod+0x80>
    end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	86a080e7          	jalr	-1942(ra) # 800041f0 <end_op>
    return -1;
    8000598e:	557d                	li	a0,-1
}
    80005990:	60ea                	ld	ra,152(sp)
    80005992:	644a                	ld	s0,144(sp)
    80005994:	610d                	addi	sp,sp,160
    80005996:	8082                	ret

0000000080005998 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005998:	7135                	addi	sp,sp,-160
    8000599a:	ed06                	sd	ra,152(sp)
    8000599c:	e922                	sd	s0,144(sp)
    8000599e:	e526                	sd	s1,136(sp)
    800059a0:	e14a                	sd	s2,128(sp)
    800059a2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059a4:	ffffc097          	auipc	ra,0xffffc
    800059a8:	fda080e7          	jalr	-38(ra) # 8000197e <myproc>
    800059ac:	892a                	mv	s2,a0
  
  begin_op();
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	7c2080e7          	jalr	1986(ra) # 80004170 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059b6:	08000613          	li	a2,128
    800059ba:	f6040593          	addi	a1,s0,-160
    800059be:	4501                	li	a0,0
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	1a2080e7          	jalr	418(ra) # 80002b62 <argstr>
    800059c8:	04054b63          	bltz	a0,80005a1e <sys_chdir+0x86>
    800059cc:	f6040513          	addi	a0,s0,-160
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	580080e7          	jalr	1408(ra) # 80003f50 <namei>
    800059d8:	84aa                	mv	s1,a0
    800059da:	c131                	beqz	a0,80005a1e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	dbe080e7          	jalr	-578(ra) # 8000379a <ilock>
  if(ip->type != T_DIR){
    800059e4:	04449703          	lh	a4,68(s1)
    800059e8:	4785                	li	a5,1
    800059ea:	04f71063          	bne	a4,a5,80005a2a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	e6c080e7          	jalr	-404(ra) # 8000385c <iunlock>
  iput(p->cwd);
    800059f8:	15893503          	ld	a0,344(s2)
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	f58080e7          	jalr	-168(ra) # 80003954 <iput>
  end_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	7ec080e7          	jalr	2028(ra) # 800041f0 <end_op>
  p->cwd = ip;
    80005a0c:	14993c23          	sd	s1,344(s2)
  return 0;
    80005a10:	4501                	li	a0,0
}
    80005a12:	60ea                	ld	ra,152(sp)
    80005a14:	644a                	ld	s0,144(sp)
    80005a16:	64aa                	ld	s1,136(sp)
    80005a18:	690a                	ld	s2,128(sp)
    80005a1a:	610d                	addi	sp,sp,160
    80005a1c:	8082                	ret
    end_op();
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	7d2080e7          	jalr	2002(ra) # 800041f0 <end_op>
    return -1;
    80005a26:	557d                	li	a0,-1
    80005a28:	b7ed                	j	80005a12 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	fd0080e7          	jalr	-48(ra) # 800039fc <iunlockput>
    end_op();
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	7bc080e7          	jalr	1980(ra) # 800041f0 <end_op>
    return -1;
    80005a3c:	557d                	li	a0,-1
    80005a3e:	bfd1                	j	80005a12 <sys_chdir+0x7a>

0000000080005a40 <sys_exec>:

uint64
sys_exec(void)
{
    80005a40:	7145                	addi	sp,sp,-464
    80005a42:	e786                	sd	ra,456(sp)
    80005a44:	e3a2                	sd	s0,448(sp)
    80005a46:	ff26                	sd	s1,440(sp)
    80005a48:	fb4a                	sd	s2,432(sp)
    80005a4a:	f74e                	sd	s3,424(sp)
    80005a4c:	f352                	sd	s4,416(sp)
    80005a4e:	ef56                	sd	s5,408(sp)
    80005a50:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a52:	08000613          	li	a2,128
    80005a56:	f4040593          	addi	a1,s0,-192
    80005a5a:	4501                	li	a0,0
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	106080e7          	jalr	262(ra) # 80002b62 <argstr>
    return -1;
    80005a64:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a66:	0c054a63          	bltz	a0,80005b3a <sys_exec+0xfa>
    80005a6a:	e3840593          	addi	a1,s0,-456
    80005a6e:	4505                	li	a0,1
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	0d0080e7          	jalr	208(ra) # 80002b40 <argaddr>
    80005a78:	0c054163          	bltz	a0,80005b3a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a7c:	10000613          	li	a2,256
    80005a80:	4581                	li	a1,0
    80005a82:	e4040513          	addi	a0,s0,-448
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	238080e7          	jalr	568(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a8e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a92:	89a6                	mv	s3,s1
    80005a94:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a96:	02000a13          	li	s4,32
    80005a9a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a9e:	00391793          	slli	a5,s2,0x3
    80005aa2:	e3040593          	addi	a1,s0,-464
    80005aa6:	e3843503          	ld	a0,-456(s0)
    80005aaa:	953e                	add	a0,a0,a5
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	fd8080e7          	jalr	-40(ra) # 80002a84 <fetchaddr>
    80005ab4:	02054a63          	bltz	a0,80005ae8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ab8:	e3043783          	ld	a5,-464(s0)
    80005abc:	c3b9                	beqz	a5,80005b02 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005abe:	ffffb097          	auipc	ra,0xffffb
    80005ac2:	014080e7          	jalr	20(ra) # 80000ad2 <kalloc>
    80005ac6:	85aa                	mv	a1,a0
    80005ac8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005acc:	cd11                	beqz	a0,80005ae8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ace:	6605                	lui	a2,0x1
    80005ad0:	e3043503          	ld	a0,-464(s0)
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	002080e7          	jalr	2(ra) # 80002ad6 <fetchstr>
    80005adc:	00054663          	bltz	a0,80005ae8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ae0:	0905                	addi	s2,s2,1
    80005ae2:	09a1                	addi	s3,s3,8
    80005ae4:	fb491be3          	bne	s2,s4,80005a9a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae8:	10048913          	addi	s2,s1,256
    80005aec:	6088                	ld	a0,0(s1)
    80005aee:	c529                	beqz	a0,80005b38 <sys_exec+0xf8>
    kfree(argv[i]);
    80005af0:	ffffb097          	auipc	ra,0xffffb
    80005af4:	ee6080e7          	jalr	-282(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af8:	04a1                	addi	s1,s1,8
    80005afa:	ff2499e3          	bne	s1,s2,80005aec <sys_exec+0xac>
  return -1;
    80005afe:	597d                	li	s2,-1
    80005b00:	a82d                	j	80005b3a <sys_exec+0xfa>
      argv[i] = 0;
    80005b02:	0a8e                	slli	s5,s5,0x3
    80005b04:	fc040793          	addi	a5,s0,-64
    80005b08:	9abe                	add	s5,s5,a5
    80005b0a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005b0e:	e4040593          	addi	a1,s0,-448
    80005b12:	f4040513          	addi	a0,s0,-192
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	178080e7          	jalr	376(ra) # 80004c8e <exec>
    80005b1e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b20:	10048993          	addi	s3,s1,256
    80005b24:	6088                	ld	a0,0(s1)
    80005b26:	c911                	beqz	a0,80005b3a <sys_exec+0xfa>
    kfree(argv[i]);
    80005b28:	ffffb097          	auipc	ra,0xffffb
    80005b2c:	eae080e7          	jalr	-338(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b30:	04a1                	addi	s1,s1,8
    80005b32:	ff3499e3          	bne	s1,s3,80005b24 <sys_exec+0xe4>
    80005b36:	a011                	j	80005b3a <sys_exec+0xfa>
  return -1;
    80005b38:	597d                	li	s2,-1
}
    80005b3a:	854a                	mv	a0,s2
    80005b3c:	60be                	ld	ra,456(sp)
    80005b3e:	641e                	ld	s0,448(sp)
    80005b40:	74fa                	ld	s1,440(sp)
    80005b42:	795a                	ld	s2,432(sp)
    80005b44:	79ba                	ld	s3,424(sp)
    80005b46:	7a1a                	ld	s4,416(sp)
    80005b48:	6afa                	ld	s5,408(sp)
    80005b4a:	6179                	addi	sp,sp,464
    80005b4c:	8082                	ret

0000000080005b4e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b4e:	7139                	addi	sp,sp,-64
    80005b50:	fc06                	sd	ra,56(sp)
    80005b52:	f822                	sd	s0,48(sp)
    80005b54:	f426                	sd	s1,40(sp)
    80005b56:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b58:	ffffc097          	auipc	ra,0xffffc
    80005b5c:	e26080e7          	jalr	-474(ra) # 8000197e <myproc>
    80005b60:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b62:	fd840593          	addi	a1,s0,-40
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	fd8080e7          	jalr	-40(ra) # 80002b40 <argaddr>
    return -1;
    80005b70:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b72:	0e054063          	bltz	a0,80005c52 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b76:	fc840593          	addi	a1,s0,-56
    80005b7a:	fd040513          	addi	a0,s0,-48
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	dee080e7          	jalr	-530(ra) # 8000496c <pipealloc>
    return -1;
    80005b86:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b88:	0c054563          	bltz	a0,80005c52 <sys_pipe+0x104>
  fd0 = -1;
    80005b8c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b90:	fd043503          	ld	a0,-48(s0)
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	50a080e7          	jalr	1290(ra) # 8000509e <fdalloc>
    80005b9c:	fca42223          	sw	a0,-60(s0)
    80005ba0:	08054c63          	bltz	a0,80005c38 <sys_pipe+0xea>
    80005ba4:	fc843503          	ld	a0,-56(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	4f6080e7          	jalr	1270(ra) # 8000509e <fdalloc>
    80005bb0:	fca42023          	sw	a0,-64(s0)
    80005bb4:	06054863          	bltz	a0,80005c24 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb8:	4691                	li	a3,4
    80005bba:	fc440613          	addi	a2,s0,-60
    80005bbe:	fd843583          	ld	a1,-40(s0)
    80005bc2:	6ca8                	ld	a0,88(s1)
    80005bc4:	ffffc097          	auipc	ra,0xffffc
    80005bc8:	a7a080e7          	jalr	-1414(ra) # 8000163e <copyout>
    80005bcc:	02054063          	bltz	a0,80005bec <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd0:	4691                	li	a3,4
    80005bd2:	fc040613          	addi	a2,s0,-64
    80005bd6:	fd843583          	ld	a1,-40(s0)
    80005bda:	0591                	addi	a1,a1,4
    80005bdc:	6ca8                	ld	a0,88(s1)
    80005bde:	ffffc097          	auipc	ra,0xffffc
    80005be2:	a60080e7          	jalr	-1440(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005be6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be8:	06055563          	bgez	a0,80005c52 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bec:	fc442783          	lw	a5,-60(s0)
    80005bf0:	07e9                	addi	a5,a5,26
    80005bf2:	078e                	slli	a5,a5,0x3
    80005bf4:	97a6                	add	a5,a5,s1
    80005bf6:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005bfa:	fc042503          	lw	a0,-64(s0)
    80005bfe:	0569                	addi	a0,a0,26
    80005c00:	050e                	slli	a0,a0,0x3
    80005c02:	9526                	add	a0,a0,s1
    80005c04:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	a30080e7          	jalr	-1488(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c14:	fc843503          	ld	a0,-56(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	a24080e7          	jalr	-1500(ra) # 8000463c <fileclose>
    return -1;
    80005c20:	57fd                	li	a5,-1
    80005c22:	a805                	j	80005c52 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c24:	fc442783          	lw	a5,-60(s0)
    80005c28:	0007c863          	bltz	a5,80005c38 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c2c:	01a78513          	addi	a0,a5,26
    80005c30:	050e                	slli	a0,a0,0x3
    80005c32:	9526                	add	a0,a0,s1
    80005c34:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005c38:	fd043503          	ld	a0,-48(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	a00080e7          	jalr	-1536(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c44:	fc843503          	ld	a0,-56(s0)
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	9f4080e7          	jalr	-1548(ra) # 8000463c <fileclose>
    return -1;
    80005c50:	57fd                	li	a5,-1
}
    80005c52:	853e                	mv	a0,a5
    80005c54:	70e2                	ld	ra,56(sp)
    80005c56:	7442                	ld	s0,48(sp)
    80005c58:	74a2                	ld	s1,40(sp)
    80005c5a:	6121                	addi	sp,sp,64
    80005c5c:	8082                	ret
	...

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	ca3fc0ef          	jal	ra,80002942 <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	c1a080e7          	jalr	-998(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	953e                	add	a0,a0,a5
    80005d5c:	00052023          	sw	zero,0(a0)
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	be2080e7          	jalr	-1054(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5179b          	slliw	a5,a0,0xd
    80005d7c:	0c201537          	lui	a0,0xc201
    80005d80:	953e                	add	a0,a0,a5
  return irq;
}
    80005d82:	4148                	lw	a0,4(a0)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	bba080e7          	jalr	-1094(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	06a7c963          	blt	a5,a0,80005e32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	0001d797          	auipc	a5,0x1d
    80005dc8:	23c78793          	addi	a5,a5,572 # 80023000 <disk>
    80005dcc:	00a78733          	add	a4,a5,a0
    80005dd0:	6789                	lui	a5,0x2
    80005dd2:	97ba                	add	a5,a5,a4
    80005dd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dd8:	e7ad                	bnez	a5,80005e42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dda:	00451793          	slli	a5,a0,0x4
    80005dde:	0001f717          	auipc	a4,0x1f
    80005de2:	22270713          	addi	a4,a4,546 # 80025000 <disk+0x2000>
    80005de6:	6314                	ld	a3,0(a4)
    80005de8:	96be                	add	a3,a3,a5
    80005dea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dee:	6314                	ld	a3,0(a4)
    80005df0:	96be                	add	a3,a3,a5
    80005df2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005df6:	6314                	ld	a3,0(a4)
    80005df8:	96be                	add	a3,a3,a5
    80005dfa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dfe:	6318                	ld	a4,0(a4)
    80005e00:	97ba                	add	a5,a5,a4
    80005e02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e06:	0001d797          	auipc	a5,0x1d
    80005e0a:	1fa78793          	addi	a5,a5,506 # 80023000 <disk>
    80005e0e:	97aa                	add	a5,a5,a0
    80005e10:	6509                	lui	a0,0x2
    80005e12:	953e                	add	a0,a0,a5
    80005e14:	4785                	li	a5,1
    80005e16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e1a:	0001f517          	auipc	a0,0x1f
    80005e1e:	1fe50513          	addi	a0,a0,510 # 80025018 <disk+0x2018>
    80005e22:	ffffc097          	auipc	ra,0xffffc
    80005e26:	32c080e7          	jalr	812(ra) # 8000214e <wakeup>
}
    80005e2a:	60a2                	ld	ra,8(sp)
    80005e2c:	6402                	ld	s0,0(sp)
    80005e2e:	0141                	addi	sp,sp,16
    80005e30:	8082                	ret
    panic("free_desc 1");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	a1e50513          	addi	a0,a0,-1506 # 80008850 <syscalls+0x320>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	6f0080e7          	jalr	1776(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	a1e50513          	addi	a0,a0,-1506 # 80008860 <syscalls+0x330>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6e0080e7          	jalr	1760(ra) # 8000052a <panic>

0000000080005e52 <virtio_disk_init>:
{
    80005e52:	1101                	addi	sp,sp,-32
    80005e54:	ec06                	sd	ra,24(sp)
    80005e56:	e822                	sd	s0,16(sp)
    80005e58:	e426                	sd	s1,8(sp)
    80005e5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e5c:	00003597          	auipc	a1,0x3
    80005e60:	a1458593          	addi	a1,a1,-1516 # 80008870 <syscalls+0x340>
    80005e64:	0001f517          	auipc	a0,0x1f
    80005e68:	2c450513          	addi	a0,a0,708 # 80025128 <disk+0x2128>
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	cc6080e7          	jalr	-826(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e74:	100017b7          	lui	a5,0x10001
    80005e78:	4398                	lw	a4,0(a5)
    80005e7a:	2701                	sext.w	a4,a4
    80005e7c:	747277b7          	lui	a5,0x74727
    80005e80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e84:	0ef71163          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e88:	100017b7          	lui	a5,0x10001
    80005e8c:	43dc                	lw	a5,4(a5)
    80005e8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e90:	4705                	li	a4,1
    80005e92:	0ce79a63          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e96:	100017b7          	lui	a5,0x10001
    80005e9a:	479c                	lw	a5,8(a5)
    80005e9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e9e:	4709                	li	a4,2
    80005ea0:	0ce79363          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ea4:	100017b7          	lui	a5,0x10001
    80005ea8:	47d8                	lw	a4,12(a5)
    80005eaa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eac:	554d47b7          	lui	a5,0x554d4
    80005eb0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eb4:	0af71963          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb8:	100017b7          	lui	a5,0x10001
    80005ebc:	4705                	li	a4,1
    80005ebe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec0:	470d                	li	a4,3
    80005ec2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ec4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ec6:	c7ffe737          	lui	a4,0xc7ffe
    80005eca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ece:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ed0:	2701                	sext.w	a4,a4
    80005ed2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed4:	472d                	li	a4,11
    80005ed6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed8:	473d                	li	a4,15
    80005eda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005edc:	6705                	lui	a4,0x1
    80005ede:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ee0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ee4:	5bdc                	lw	a5,52(a5)
    80005ee6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee8:	c7d9                	beqz	a5,80005f76 <virtio_disk_init+0x124>
  if(max < NUM)
    80005eea:	471d                	li	a4,7
    80005eec:	08f77d63          	bgeu	a4,a5,80005f86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ef0:	100014b7          	lui	s1,0x10001
    80005ef4:	47a1                	li	a5,8
    80005ef6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ef8:	6609                	lui	a2,0x2
    80005efa:	4581                	li	a1,0
    80005efc:	0001d517          	auipc	a0,0x1d
    80005f00:	10450513          	addi	a0,a0,260 # 80023000 <disk>
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	dba080e7          	jalr	-582(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f0c:	0001d717          	auipc	a4,0x1d
    80005f10:	0f470713          	addi	a4,a4,244 # 80023000 <disk>
    80005f14:	00c75793          	srli	a5,a4,0xc
    80005f18:	2781                	sext.w	a5,a5
    80005f1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f1c:	0001f797          	auipc	a5,0x1f
    80005f20:	0e478793          	addi	a5,a5,228 # 80025000 <disk+0x2000>
    80005f24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f26:	0001d717          	auipc	a4,0x1d
    80005f2a:	15a70713          	addi	a4,a4,346 # 80023080 <disk+0x80>
    80005f2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f30:	0001e717          	auipc	a4,0x1e
    80005f34:	0d070713          	addi	a4,a4,208 # 80024000 <disk+0x1000>
    80005f38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f3a:	4705                	li	a4,1
    80005f3c:	00e78c23          	sb	a4,24(a5)
    80005f40:	00e78ca3          	sb	a4,25(a5)
    80005f44:	00e78d23          	sb	a4,26(a5)
    80005f48:	00e78da3          	sb	a4,27(a5)
    80005f4c:	00e78e23          	sb	a4,28(a5)
    80005f50:	00e78ea3          	sb	a4,29(a5)
    80005f54:	00e78f23          	sb	a4,30(a5)
    80005f58:	00e78fa3          	sb	a4,31(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret
    panic("could not find virtio disk");
    80005f66:	00003517          	auipc	a0,0x3
    80005f6a:	91a50513          	addi	a0,a0,-1766 # 80008880 <syscalls+0x350>
    80005f6e:	ffffa097          	auipc	ra,0xffffa
    80005f72:	5bc080e7          	jalr	1468(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	92a50513          	addi	a0,a0,-1750 # 800088a0 <syscalls+0x370>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5ac080e7          	jalr	1452(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	93a50513          	addi	a0,a0,-1734 # 800088c0 <syscalls+0x390>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	59c080e7          	jalr	1436(ra) # 8000052a <panic>

0000000080005f96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f96:	7119                	addi	sp,sp,-128
    80005f98:	fc86                	sd	ra,120(sp)
    80005f9a:	f8a2                	sd	s0,112(sp)
    80005f9c:	f4a6                	sd	s1,104(sp)
    80005f9e:	f0ca                	sd	s2,96(sp)
    80005fa0:	ecce                	sd	s3,88(sp)
    80005fa2:	e8d2                	sd	s4,80(sp)
    80005fa4:	e4d6                	sd	s5,72(sp)
    80005fa6:	e0da                	sd	s6,64(sp)
    80005fa8:	fc5e                	sd	s7,56(sp)
    80005faa:	f862                	sd	s8,48(sp)
    80005fac:	f466                	sd	s9,40(sp)
    80005fae:	f06a                	sd	s10,32(sp)
    80005fb0:	ec6e                	sd	s11,24(sp)
    80005fb2:	0100                	addi	s0,sp,128
    80005fb4:	8aaa                	mv	s5,a0
    80005fb6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fb8:	00c52c83          	lw	s9,12(a0)
    80005fbc:	001c9c9b          	slliw	s9,s9,0x1
    80005fc0:	1c82                	slli	s9,s9,0x20
    80005fc2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fc6:	0001f517          	auipc	a0,0x1f
    80005fca:	16250513          	addi	a0,a0,354 # 80025128 <disk+0x2128>
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	bf4080e7          	jalr	-1036(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005fd6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fd8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fda:	0001dc17          	auipc	s8,0x1d
    80005fde:	026c0c13          	addi	s8,s8,38 # 80023000 <disk>
    80005fe2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005fe4:	4b0d                	li	s6,3
    80005fe6:	a0ad                	j	80006050 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005fe8:	00fc0733          	add	a4,s8,a5
    80005fec:	975e                	add	a4,a4,s7
    80005fee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ff2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005ff4:	0207c563          	bltz	a5,8000601e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ff8:	2905                	addiw	s2,s2,1
    80005ffa:	0611                	addi	a2,a2,4
    80005ffc:	19690d63          	beq	s2,s6,80006196 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006000:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006002:	0001f717          	auipc	a4,0x1f
    80006006:	01670713          	addi	a4,a4,22 # 80025018 <disk+0x2018>
    8000600a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000600c:	00074683          	lbu	a3,0(a4)
    80006010:	fee1                	bnez	a3,80005fe8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006012:	2785                	addiw	a5,a5,1
    80006014:	0705                	addi	a4,a4,1
    80006016:	fe979be3          	bne	a5,s1,8000600c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000601a:	57fd                	li	a5,-1
    8000601c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000601e:	01205d63          	blez	s2,80006038 <virtio_disk_rw+0xa2>
    80006022:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006024:	000a2503          	lw	a0,0(s4)
    80006028:	00000097          	auipc	ra,0x0
    8000602c:	d8e080e7          	jalr	-626(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    80006030:	2d85                	addiw	s11,s11,1
    80006032:	0a11                	addi	s4,s4,4
    80006034:	ffb918e3          	bne	s2,s11,80006024 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006038:	0001f597          	auipc	a1,0x1f
    8000603c:	0f058593          	addi	a1,a1,240 # 80025128 <disk+0x2128>
    80006040:	0001f517          	auipc	a0,0x1f
    80006044:	fd850513          	addi	a0,a0,-40 # 80025018 <disk+0x2018>
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	f7a080e7          	jalr	-134(ra) # 80001fc2 <sleep>
  for(int i = 0; i < 3; i++){
    80006050:	f8040a13          	addi	s4,s0,-128
{
    80006054:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006056:	894e                	mv	s2,s3
    80006058:	b765                	j	80006000 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000605a:	0001f697          	auipc	a3,0x1f
    8000605e:	fa66b683          	ld	a3,-90(a3) # 80025000 <disk+0x2000>
    80006062:	96ba                	add	a3,a3,a4
    80006064:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006068:	0001d817          	auipc	a6,0x1d
    8000606c:	f9880813          	addi	a6,a6,-104 # 80023000 <disk>
    80006070:	0001f697          	auipc	a3,0x1f
    80006074:	f9068693          	addi	a3,a3,-112 # 80025000 <disk+0x2000>
    80006078:	6290                	ld	a2,0(a3)
    8000607a:	963a                	add	a2,a2,a4
    8000607c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006080:	0015e593          	ori	a1,a1,1
    80006084:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006088:	f8842603          	lw	a2,-120(s0)
    8000608c:	628c                	ld	a1,0(a3)
    8000608e:	972e                	add	a4,a4,a1
    80006090:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006094:	20050593          	addi	a1,a0,512
    80006098:	0592                	slli	a1,a1,0x4
    8000609a:	95c2                	add	a1,a1,a6
    8000609c:	577d                	li	a4,-1
    8000609e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060a2:	00461713          	slli	a4,a2,0x4
    800060a6:	6290                	ld	a2,0(a3)
    800060a8:	963a                	add	a2,a2,a4
    800060aa:	03078793          	addi	a5,a5,48
    800060ae:	97c2                	add	a5,a5,a6
    800060b0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800060b2:	629c                	ld	a5,0(a3)
    800060b4:	97ba                	add	a5,a5,a4
    800060b6:	4605                	li	a2,1
    800060b8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060ba:	629c                	ld	a5,0(a3)
    800060bc:	97ba                	add	a5,a5,a4
    800060be:	4809                	li	a6,2
    800060c0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060c4:	629c                	ld	a5,0(a3)
    800060c6:	973e                	add	a4,a4,a5
    800060c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060cc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800060d0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060d4:	6698                	ld	a4,8(a3)
    800060d6:	00275783          	lhu	a5,2(a4)
    800060da:	8b9d                	andi	a5,a5,7
    800060dc:	0786                	slli	a5,a5,0x1
    800060de:	97ba                	add	a5,a5,a4
    800060e0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800060e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060e8:	6698                	ld	a4,8(a3)
    800060ea:	00275783          	lhu	a5,2(a4)
    800060ee:	2785                	addiw	a5,a5,1
    800060f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060f8:	100017b7          	lui	a5,0x10001
    800060fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006100:	004aa783          	lw	a5,4(s5)
    80006104:	02c79163          	bne	a5,a2,80006126 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006108:	0001f917          	auipc	s2,0x1f
    8000610c:	02090913          	addi	s2,s2,32 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006110:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006112:	85ca                	mv	a1,s2
    80006114:	8556                	mv	a0,s5
    80006116:	ffffc097          	auipc	ra,0xffffc
    8000611a:	eac080e7          	jalr	-340(ra) # 80001fc2 <sleep>
  while(b->disk == 1) {
    8000611e:	004aa783          	lw	a5,4(s5)
    80006122:	fe9788e3          	beq	a5,s1,80006112 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006126:	f8042903          	lw	s2,-128(s0)
    8000612a:	20090793          	addi	a5,s2,512
    8000612e:	00479713          	slli	a4,a5,0x4
    80006132:	0001d797          	auipc	a5,0x1d
    80006136:	ece78793          	addi	a5,a5,-306 # 80023000 <disk>
    8000613a:	97ba                	add	a5,a5,a4
    8000613c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006140:	0001f997          	auipc	s3,0x1f
    80006144:	ec098993          	addi	s3,s3,-320 # 80025000 <disk+0x2000>
    80006148:	00491713          	slli	a4,s2,0x4
    8000614c:	0009b783          	ld	a5,0(s3)
    80006150:	97ba                	add	a5,a5,a4
    80006152:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006156:	854a                	mv	a0,s2
    80006158:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000615c:	00000097          	auipc	ra,0x0
    80006160:	c5a080e7          	jalr	-934(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006164:	8885                	andi	s1,s1,1
    80006166:	f0ed                	bnez	s1,80006148 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006168:	0001f517          	auipc	a0,0x1f
    8000616c:	fc050513          	addi	a0,a0,-64 # 80025128 <disk+0x2128>
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	b06080e7          	jalr	-1274(ra) # 80000c76 <release>
}
    80006178:	70e6                	ld	ra,120(sp)
    8000617a:	7446                	ld	s0,112(sp)
    8000617c:	74a6                	ld	s1,104(sp)
    8000617e:	7906                	ld	s2,96(sp)
    80006180:	69e6                	ld	s3,88(sp)
    80006182:	6a46                	ld	s4,80(sp)
    80006184:	6aa6                	ld	s5,72(sp)
    80006186:	6b06                	ld	s6,64(sp)
    80006188:	7be2                	ld	s7,56(sp)
    8000618a:	7c42                	ld	s8,48(sp)
    8000618c:	7ca2                	ld	s9,40(sp)
    8000618e:	7d02                	ld	s10,32(sp)
    80006190:	6de2                	ld	s11,24(sp)
    80006192:	6109                	addi	sp,sp,128
    80006194:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006196:	f8042503          	lw	a0,-128(s0)
    8000619a:	20050793          	addi	a5,a0,512
    8000619e:	0792                	slli	a5,a5,0x4
  if(write)
    800061a0:	0001d817          	auipc	a6,0x1d
    800061a4:	e6080813          	addi	a6,a6,-416 # 80023000 <disk>
    800061a8:	00f80733          	add	a4,a6,a5
    800061ac:	01a036b3          	snez	a3,s10
    800061b0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800061b4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061b8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061bc:	7679                	lui	a2,0xffffe
    800061be:	963e                	add	a2,a2,a5
    800061c0:	0001f697          	auipc	a3,0x1f
    800061c4:	e4068693          	addi	a3,a3,-448 # 80025000 <disk+0x2000>
    800061c8:	6298                	ld	a4,0(a3)
    800061ca:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061cc:	0a878593          	addi	a1,a5,168
    800061d0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061d4:	6298                	ld	a4,0(a3)
    800061d6:	9732                	add	a4,a4,a2
    800061d8:	45c1                	li	a1,16
    800061da:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061dc:	6298                	ld	a4,0(a3)
    800061de:	9732                	add	a4,a4,a2
    800061e0:	4585                	li	a1,1
    800061e2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061e6:	f8442703          	lw	a4,-124(s0)
    800061ea:	628c                	ld	a1,0(a3)
    800061ec:	962e                	add	a2,a2,a1
    800061ee:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800061f2:	0712                	slli	a4,a4,0x4
    800061f4:	6290                	ld	a2,0(a3)
    800061f6:	963a                	add	a2,a2,a4
    800061f8:	058a8593          	addi	a1,s5,88
    800061fc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061fe:	6294                	ld	a3,0(a3)
    80006200:	96ba                	add	a3,a3,a4
    80006202:	40000613          	li	a2,1024
    80006206:	c690                	sw	a2,8(a3)
  if(write)
    80006208:	e40d19e3          	bnez	s10,8000605a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000620c:	0001f697          	auipc	a3,0x1f
    80006210:	df46b683          	ld	a3,-524(a3) # 80025000 <disk+0x2000>
    80006214:	96ba                	add	a3,a3,a4
    80006216:	4609                	li	a2,2
    80006218:	00c69623          	sh	a2,12(a3)
    8000621c:	b5b1                	j	80006068 <virtio_disk_rw+0xd2>

000000008000621e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000621e:	1101                	addi	sp,sp,-32
    80006220:	ec06                	sd	ra,24(sp)
    80006222:	e822                	sd	s0,16(sp)
    80006224:	e426                	sd	s1,8(sp)
    80006226:	e04a                	sd	s2,0(sp)
    80006228:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000622a:	0001f517          	auipc	a0,0x1f
    8000622e:	efe50513          	addi	a0,a0,-258 # 80025128 <disk+0x2128>
    80006232:	ffffb097          	auipc	ra,0xffffb
    80006236:	990080e7          	jalr	-1648(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000623a:	10001737          	lui	a4,0x10001
    8000623e:	533c                	lw	a5,96(a4)
    80006240:	8b8d                	andi	a5,a5,3
    80006242:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006244:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006248:	0001f797          	auipc	a5,0x1f
    8000624c:	db878793          	addi	a5,a5,-584 # 80025000 <disk+0x2000>
    80006250:	6b94                	ld	a3,16(a5)
    80006252:	0207d703          	lhu	a4,32(a5)
    80006256:	0026d783          	lhu	a5,2(a3)
    8000625a:	06f70163          	beq	a4,a5,800062bc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000625e:	0001d917          	auipc	s2,0x1d
    80006262:	da290913          	addi	s2,s2,-606 # 80023000 <disk>
    80006266:	0001f497          	auipc	s1,0x1f
    8000626a:	d9a48493          	addi	s1,s1,-614 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000626e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006272:	6898                	ld	a4,16(s1)
    80006274:	0204d783          	lhu	a5,32(s1)
    80006278:	8b9d                	andi	a5,a5,7
    8000627a:	078e                	slli	a5,a5,0x3
    8000627c:	97ba                	add	a5,a5,a4
    8000627e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006280:	20078713          	addi	a4,a5,512
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	974a                	add	a4,a4,s2
    80006288:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000628c:	e731                	bnez	a4,800062d8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000628e:	20078793          	addi	a5,a5,512
    80006292:	0792                	slli	a5,a5,0x4
    80006294:	97ca                	add	a5,a5,s2
    80006296:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006298:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000629c:	ffffc097          	auipc	ra,0xffffc
    800062a0:	eb2080e7          	jalr	-334(ra) # 8000214e <wakeup>

    disk.used_idx += 1;
    800062a4:	0204d783          	lhu	a5,32(s1)
    800062a8:	2785                	addiw	a5,a5,1
    800062aa:	17c2                	slli	a5,a5,0x30
    800062ac:	93c1                	srli	a5,a5,0x30
    800062ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062b2:	6898                	ld	a4,16(s1)
    800062b4:	00275703          	lhu	a4,2(a4)
    800062b8:	faf71be3          	bne	a4,a5,8000626e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800062bc:	0001f517          	auipc	a0,0x1f
    800062c0:	e6c50513          	addi	a0,a0,-404 # 80025128 <disk+0x2128>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	9b2080e7          	jalr	-1614(ra) # 80000c76 <release>
}
    800062cc:	60e2                	ld	ra,24(sp)
    800062ce:	6442                	ld	s0,16(sp)
    800062d0:	64a2                	ld	s1,8(sp)
    800062d2:	6902                	ld	s2,0(sp)
    800062d4:	6105                	addi	sp,sp,32
    800062d6:	8082                	ret
      panic("virtio_disk_intr status");
    800062d8:	00002517          	auipc	a0,0x2
    800062dc:	60850513          	addi	a0,a0,1544 # 800088e0 <syscalls+0x3b0>
    800062e0:	ffffa097          	auipc	ra,0xffffa
    800062e4:	24a080e7          	jalr	586(ra) # 8000052a <panic>
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
