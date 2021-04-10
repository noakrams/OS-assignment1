
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
    80000068:	fbc78793          	addi	a5,a5,-68 # 80006020 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
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
    80000122:	5da080e7          	jalr	1498(ra) # 800026f8 <either_copyin>
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
    800001c6:	f32080e7          	jalr	-206(ra) # 800020f4 <sleep>
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
    80000202:	4a4080e7          	jalr	1188(ra) # 800026a2 <either_copyout>
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
    800002e2:	470080e7          	jalr	1136(ra) # 8000274e <procdump>
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
    80000436:	f36080e7          	jalr	-202(ra) # 80002368 <wakeup>
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
    80000464:	00022797          	auipc	a5,0x22
    80000468:	cb478793          	addi	a5,a5,-844 # 80022118 <devsw>
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
    80000882:	aea080e7          	jalr	-1302(ra) # 80002368 <wakeup>
    
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
    8000090e:	7ea080e7          	jalr	2026(ra) # 800020f4 <sleep>
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
    800009ea:	00026797          	auipc	a5,0x26
    800009ee:	61678793          	addi	a5,a5,1558 # 80027000 <end>
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
    80000aba:	00026517          	auipc	a0,0x26
    80000abe:	54650513          	addi	a0,a0,1350 # 80027000 <end>
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
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	a98080e7          	jalr	-1384(ra) # 8000294a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	1a6080e7          	jalr	422(ra) # 80006060 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	03c080e7          	jalr	60(ra) # 80001efe <scheduler>
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
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	9f8080e7          	jalr	-1544(ra) # 80002922 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	a18080e7          	jalr	-1512(ra) # 8000294a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	110080e7          	jalr	272(ra) # 8000604a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	11e080e7          	jalr	286(ra) # 80006060 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	2de080e7          	jalr	734(ra) # 80003228 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	970080e7          	jalr	-1680(ra) # 800038c2 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	91e080e7          	jalr	-1762(ra) # 80004878 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	220080e7          	jalr	544(ra) # 80006182 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d2c080e7          	jalr	-724(ra) # 80001c96 <userinit>
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
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
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
    80001840:	694a0a13          	addi	s4,s4,1684 # 80017ed0 <tickslock>
    char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
    if(pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	8595                	srai	a1,a1,0x5
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
    80001876:	1a048493          	addi	s1,s1,416
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
}

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
    8000190c:	5c898993          	addi	s3,s3,1480 # 80017ed0 <tickslock>
      initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	8795                	srai	a5,a5,0x5
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	fcbc                	sd	a5,120(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	1a048493          	addi	s1,s1,416
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
    800019d2:	f627a783          	lw	a5,-158(a5) # 80008930 <first.1>
    800019d6:	eb89                	bnez	a5,800019e8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019d8:	00001097          	auipc	ra,0x1
    800019dc:	f8a080e7          	jalr	-118(ra) # 80002962 <usertrapret>
}
    800019e0:	60a2                	ld	ra,8(sp)
    800019e2:	6402                	ld	s0,0(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret
    first = 0;
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	f407a423          	sw	zero,-184(a5) # 80008930 <first.1>
    fsinit(ROOTDEV);
    800019f0:	4505                	li	a0,1
    800019f2:	00002097          	auipc	ra,0x2
    800019f6:	e50080e7          	jalr	-432(ra) # 80003842 <fsinit>
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
    80001a1e:	f1a78793          	addi	a5,a5,-230 # 80008934 <nextpid>
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
    80001a7e:	09093683          	ld	a3,144(s2)
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
    80001b3c:	6948                	ld	a0,144(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b48:	0804b823          	sd	zero,144(s1)
  if(p->pagetable)
    80001b4c:	64c8                	ld	a0,136(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b50:	60cc                	ld	a1,128(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
  p->pagetable = 0;
    80001b5a:	0804b423          	sd	zero,136(s1)
  p->sz = 0;
    80001b5e:	0804b023          	sd	zero,128(s1)
  p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b66:	0604b823          	sd	zero,112(s1)
  p->name[0] = 0;
    80001b6a:	18048823          	sb	zero,400(s1)
  p->chan = 0;
    80001b6e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b72:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b76:	0204a623          	sw	zero,44(s1)
  p->ctime = 0;
    80001b7a:	0404a023          	sw	zero,64(s1)
  p->ttime = 0;
    80001b7e:	0404a223          	sw	zero,68(s1)
  p->stime = 0;
    80001b82:	0404a423          	sw	zero,72(s1)
  p->retime = 0;
    80001b86:	0404a623          	sw	zero,76(s1)
  p->rutime = 0;
    80001b8a:	0404a823          	sw	zero,80(s1)
  p->average_bursttime = 0;
    80001b8e:	0404aa23          	sw	zero,84(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00016917          	auipc	s2,0x16
    80001bb8:	31c90913          	addi	s2,s2,796 # 80017ed0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	004080e7          	jalr	4(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0aa080e7          	jalr	170(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	1a048493          	addi	s1,s1,416
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a8ad                	j	80001c58 <allocproc+0xb8>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e1c080e7          	jalr	-484(ra) # 800019fc <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  p->mask = 0;
    80001bee:	0204aa23          	sw	zero,52(s1)
  p->tickcounter = 0;
    80001bf2:	0204ac23          	sw	zero,56(s1)
  p->priority = NORMAL_PRIORITY;
    80001bf6:	4795                	li	a5,5
    80001bf8:	dcdc                	sw	a5,60(s1)
  p->average_bursttime = QUANTUM * 100;
    80001bfa:	1f400793          	li	a5,500
    80001bfe:	c8fc                	sw	a5,84(s1)
  p->ctime = ticks;
    80001c00:	00007797          	auipc	a5,0x7
    80001c04:	4307a783          	lw	a5,1072(a5) # 80009030 <ticks>
    80001c08:	c0bc                	sw	a5,64(s1)
  p->readyTime = 0;
    80001c0a:	0404bc23          	sd	zero,88(s1)
  p->rutime = 0;
    80001c0e:	0404a823          	sw	zero,80(s1)
  p->stime = 0;
    80001c12:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	ebc080e7          	jalr	-324(ra) # 80000ad2 <kalloc>
    80001c1e:	892a                	mv	s2,a0
    80001c20:	e8c8                	sd	a0,144(s1)
    80001c22:	c131                	beqz	a0,80001c66 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	e1c080e7          	jalr	-484(ra) # 80001a42 <proc_pagetable>
    80001c2e:	892a                	mv	s2,a0
    80001c30:	e4c8                	sd	a0,136(s1)
  if(p->pagetable == 0){
    80001c32:	c531                	beqz	a0,80001c7e <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001c34:	07000613          	li	a2,112
    80001c38:	4581                	li	a1,0
    80001c3a:	09848513          	addi	a0,s1,152
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	080080e7          	jalr	128(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c46:	00000797          	auipc	a5,0x0
    80001c4a:	d7078793          	addi	a5,a5,-656 # 800019b6 <forkret>
    80001c4e:	ecdc                	sd	a5,152(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c50:	7cbc                	ld	a5,120(s1)
    80001c52:	6705                	lui	a4,0x1
    80001c54:	97ba                	add	a5,a5,a4
    80001c56:	f0dc                	sd	a5,160(s1)
}
    80001c58:	8526                	mv	a0,s1
    80001c5a:	60e2                	ld	ra,24(sp)
    80001c5c:	6442                	ld	s0,16(sp)
    80001c5e:	64a2                	ld	s1,8(sp)
    80001c60:	6902                	ld	s2,0(sp)
    80001c62:	6105                	addi	sp,sp,32
    80001c64:	8082                	ret
    freeproc(p);
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	ec8080e7          	jalr	-312(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	004080e7          	jalr	4(ra) # 80000c76 <release>
    return 0;
    80001c7a:	84ca                	mv	s1,s2
    80001c7c:	bff1                	j	80001c58 <allocproc+0xb8>
    freeproc(p);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	eb0080e7          	jalr	-336(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	fec080e7          	jalr	-20(ra) # 80000c76 <release>
    return 0;
    80001c92:	84ca                	mv	s1,s2
    80001c94:	b7d1                	j	80001c58 <allocproc+0xb8>

0000000080001c96 <userinit>:
{
    80001c96:	1101                	addi	sp,sp,-32
    80001c98:	ec06                	sd	ra,24(sp)
    80001c9a:	e822                	sd	s0,16(sp)
    80001c9c:	e426                	sd	s1,8(sp)
    80001c9e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	f00080e7          	jalr	-256(ra) # 80001ba0 <allocproc>
    80001ca8:	84aa                	mv	s1,a0
  initproc = p;
    80001caa:	00007797          	auipc	a5,0x7
    80001cae:	36a7bf23          	sd	a0,894(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb2:	03400613          	li	a2,52
    80001cb6:	00007597          	auipc	a1,0x7
    80001cba:	c8a58593          	addi	a1,a1,-886 # 80008940 <initcode>
    80001cbe:	6548                	ld	a0,136(a0)
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	674080e7          	jalr	1652(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001cc8:	6785                	lui	a5,0x1
    80001cca:	e0dc                	sd	a5,128(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ccc:	68d8                	ld	a4,144(s1)
    80001cce:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd2:	68d8                	ld	a4,144(s1)
    80001cd4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd6:	4641                	li	a2,16
    80001cd8:	00006597          	auipc	a1,0x6
    80001cdc:	51058593          	addi	a1,a1,1296 # 800081e8 <digits+0x1a8>
    80001ce0:	19048513          	addi	a0,s1,400
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	12c080e7          	jalr	300(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cec:	00006517          	auipc	a0,0x6
    80001cf0:	50c50513          	addi	a0,a0,1292 # 800081f8 <digits+0x1b8>
    80001cf4:	00002097          	auipc	ra,0x2
    80001cf8:	57c080e7          	jalr	1404(ra) # 80004270 <namei>
    80001cfc:	18a4b423          	sd	a0,392(s1)
  p->state = RUNNABLE;
    80001d00:	478d                	li	a5,3
    80001d02:	cc9c                	sw	a5,24(s1)
  p->readyTime = ticks;
    80001d04:	00007797          	auipc	a5,0x7
    80001d08:	32c7e783          	lwu	a5,812(a5) # 80009030 <ticks>
    80001d0c:	ecbc                	sd	a5,88(s1)
  release(&p->lock);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	f66080e7          	jalr	-154(ra) # 80000c76 <release>
}
    80001d18:	60e2                	ld	ra,24(sp)
    80001d1a:	6442                	ld	s0,16(sp)
    80001d1c:	64a2                	ld	s1,8(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret

0000000080001d22 <growproc>:
{
    80001d22:	1101                	addi	sp,sp,-32
    80001d24:	ec06                	sd	ra,24(sp)
    80001d26:	e822                	sd	s0,16(sp)
    80001d28:	e426                	sd	s1,8(sp)
    80001d2a:	e04a                	sd	s2,0(sp)
    80001d2c:	1000                	addi	s0,sp,32
    80001d2e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	c4e080e7          	jalr	-946(ra) # 8000197e <myproc>
    80001d38:	892a                	mv	s2,a0
  sz = p->sz;
    80001d3a:	614c                	ld	a1,128(a0)
    80001d3c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d40:	00904f63          	bgtz	s1,80001d5e <growproc+0x3c>
  } else if(n < 0){
    80001d44:	0204cc63          	bltz	s1,80001d7c <growproc+0x5a>
  p->sz = sz;
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	08c93023          	sd	a2,128(s2)
  return 0;
    80001d50:	4501                	li	a0,0
}
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6902                	ld	s2,0(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5e:	9e25                	addw	a2,a2,s1
    80001d60:	1602                	slli	a2,a2,0x20
    80001d62:	9201                	srli	a2,a2,0x20
    80001d64:	1582                	slli	a1,a1,0x20
    80001d66:	9181                	srli	a1,a1,0x20
    80001d68:	6548                	ld	a0,136(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	684080e7          	jalr	1668(ra) # 800013ee <uvmalloc>
    80001d72:	0005061b          	sext.w	a2,a0
    80001d76:	fa69                	bnez	a2,80001d48 <growproc+0x26>
      return -1;
    80001d78:	557d                	li	a0,-1
    80001d7a:	bfe1                	j	80001d52 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d7c:	9e25                	addw	a2,a2,s1
    80001d7e:	1602                	slli	a2,a2,0x20
    80001d80:	9201                	srli	a2,a2,0x20
    80001d82:	1582                	slli	a1,a1,0x20
    80001d84:	9181                	srli	a1,a1,0x20
    80001d86:	6548                	ld	a0,136(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	61e080e7          	jalr	1566(ra) # 800013a6 <uvmdealloc>
    80001d90:	0005061b          	sext.w	a2,a0
    80001d94:	bf55                	j	80001d48 <growproc+0x26>

0000000080001d96 <fork>:
{
    80001d96:	7139                	addi	sp,sp,-64
    80001d98:	fc06                	sd	ra,56(sp)
    80001d9a:	f822                	sd	s0,48(sp)
    80001d9c:	f426                	sd	s1,40(sp)
    80001d9e:	f04a                	sd	s2,32(sp)
    80001da0:	ec4e                	sd	s3,24(sp)
    80001da2:	e852                	sd	s4,16(sp)
    80001da4:	e456                	sd	s5,8(sp)
    80001da6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	bd6080e7          	jalr	-1066(ra) # 8000197e <myproc>
    80001db0:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	dee080e7          	jalr	-530(ra) # 80001ba0 <allocproc>
    80001dba:	14050063          	beqz	a0,80001efa <fork+0x164>
    80001dbe:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc0:	080ab603          	ld	a2,128(s5)
    80001dc4:	654c                	ld	a1,136(a0)
    80001dc6:	088ab503          	ld	a0,136(s5)
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	770080e7          	jalr	1904(ra) # 8000153a <uvmcopy>
    80001dd2:	06054663          	bltz	a0,80001e3e <fork+0xa8>
  np->sz = p->sz;
    80001dd6:	080ab783          	ld	a5,128(s5)
    80001dda:	08f9b023          	sd	a5,128(s3)
  np->mask = p->mask;
    80001dde:	034aa783          	lw	a5,52(s5)
    80001de2:	02f9aa23          	sw	a5,52(s3)
  np->priority = p->priority;
    80001de6:	03caa783          	lw	a5,60(s5)
    80001dea:	02f9ae23          	sw	a5,60(s3)
  np->tickcounter = 0;
    80001dee:	0209ac23          	sw	zero,56(s3)
  np->average_bursttime = QUANTUM * 100;
    80001df2:	1f400793          	li	a5,500
    80001df6:	04f9aa23          	sw	a5,84(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dfa:	090ab683          	ld	a3,144(s5)
    80001dfe:	87b6                	mv	a5,a3
    80001e00:	0909b703          	ld	a4,144(s3)
    80001e04:	12068693          	addi	a3,a3,288
    80001e08:	0007b803          	ld	a6,0(a5)
    80001e0c:	6788                	ld	a0,8(a5)
    80001e0e:	6b8c                	ld	a1,16(a5)
    80001e10:	6f90                	ld	a2,24(a5)
    80001e12:	01073023          	sd	a6,0(a4)
    80001e16:	e708                	sd	a0,8(a4)
    80001e18:	eb0c                	sd	a1,16(a4)
    80001e1a:	ef10                	sd	a2,24(a4)
    80001e1c:	02078793          	addi	a5,a5,32
    80001e20:	02070713          	addi	a4,a4,32
    80001e24:	fed792e3          	bne	a5,a3,80001e08 <fork+0x72>
  np->trapframe->a0 = 0;
    80001e28:	0909b783          	ld	a5,144(s3)
    80001e2c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e30:	108a8493          	addi	s1,s5,264
    80001e34:	10898913          	addi	s2,s3,264
    80001e38:	188a8a13          	addi	s4,s5,392
    80001e3c:	a00d                	j	80001e5e <fork+0xc8>
    freeproc(np);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	cf0080e7          	jalr	-784(ra) # 80001b30 <freeproc>
    release(&np->lock);
    80001e48:	854e                	mv	a0,s3
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e2c080e7          	jalr	-468(ra) # 80000c76 <release>
    return -1;
    80001e52:	597d                	li	s2,-1
    80001e54:	a849                	j	80001ee6 <fork+0x150>
  for(i = 0; i < NOFILE; i++)
    80001e56:	04a1                	addi	s1,s1,8
    80001e58:	0921                	addi	s2,s2,8
    80001e5a:	01448b63          	beq	s1,s4,80001e70 <fork+0xda>
    if(p->ofile[i])
    80001e5e:	6088                	ld	a0,0(s1)
    80001e60:	d97d                	beqz	a0,80001e56 <fork+0xc0>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e62:	00003097          	auipc	ra,0x3
    80001e66:	aa8080e7          	jalr	-1368(ra) # 8000490a <filedup>
    80001e6a:	00a93023          	sd	a0,0(s2)
    80001e6e:	b7e5                	j	80001e56 <fork+0xc0>
  np->cwd = idup(p->cwd);
    80001e70:	188ab503          	ld	a0,392(s5)
    80001e74:	00002097          	auipc	ra,0x2
    80001e78:	c08080e7          	jalr	-1016(ra) # 80003a7c <idup>
    80001e7c:	18a9b423          	sd	a0,392(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e80:	4641                	li	a2,16
    80001e82:	190a8593          	addi	a1,s5,400
    80001e86:	19098513          	addi	a0,s3,400
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	f86080e7          	jalr	-122(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e92:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e96:	854e                	mv	a0,s3
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	dde080e7          	jalr	-546(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001ea0:	0000f497          	auipc	s1,0xf
    80001ea4:	41848493          	addi	s1,s1,1048 # 800112b8 <wait_lock>
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	d18080e7          	jalr	-744(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001eb2:	0759b823          	sd	s5,112(s3)
  release(&wait_lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	dbe080e7          	jalr	-578(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001ec0:	854e                	mv	a0,s3
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	d00080e7          	jalr	-768(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eca:	478d                	li	a5,3
    80001ecc:	00f9ac23          	sw	a5,24(s3)
  np->readyTime = ticks;
    80001ed0:	00007797          	auipc	a5,0x7
    80001ed4:	1607e783          	lwu	a5,352(a5) # 80009030 <ticks>
    80001ed8:	04f9bc23          	sd	a5,88(s3)
  release(&np->lock);
    80001edc:	854e                	mv	a0,s3
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	d98080e7          	jalr	-616(ra) # 80000c76 <release>
}
    80001ee6:	854a                	mv	a0,s2
    80001ee8:	70e2                	ld	ra,56(sp)
    80001eea:	7442                	ld	s0,48(sp)
    80001eec:	74a2                	ld	s1,40(sp)
    80001eee:	7902                	ld	s2,32(sp)
    80001ef0:	69e2                	ld	s3,24(sp)
    80001ef2:	6a42                	ld	s4,16(sp)
    80001ef4:	6aa2                	ld	s5,8(sp)
    80001ef6:	6121                	addi	sp,sp,64
    80001ef8:	8082                	ret
    return -1;
    80001efa:	597d                	li	s2,-1
    80001efc:	b7ed                	j	80001ee6 <fork+0x150>

0000000080001efe <scheduler>:
{
    80001efe:	715d                	addi	sp,sp,-80
    80001f00:	e486                	sd	ra,72(sp)
    80001f02:	e0a2                	sd	s0,64(sp)
    80001f04:	fc26                	sd	s1,56(sp)
    80001f06:	f84a                	sd	s2,48(sp)
    80001f08:	f44e                	sd	s3,40(sp)
    80001f0a:	f052                	sd	s4,32(sp)
    80001f0c:	ec56                	sd	s5,24(sp)
    80001f0e:	e85a                	sd	s6,16(sp)
    80001f10:	e45e                	sd	s7,8(sp)
    80001f12:	0880                	addi	s0,sp,80
    80001f14:	8792                	mv	a5,tp
  int id = r_tp();
    80001f16:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f18:	00779b13          	slli	s6,a5,0x7
    80001f1c:	0000f717          	auipc	a4,0xf
    80001f20:	38470713          	addi	a4,a4,900 # 800112a0 <pid_lock>
    80001f24:	975a                	add	a4,a4,s6
    80001f26:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f2a:	0000f717          	auipc	a4,0xf
    80001f2e:	3ae70713          	addi	a4,a4,942 # 800112d8 <cpus+0x8>
    80001f32:	9b3a                	add	s6,s6,a4
      if(p->state != RUNNABLE) {
    80001f34:	498d                	li	s3,3
        p->runningTime = ticks;
    80001f36:	00007b97          	auipc	s7,0x7
    80001f3a:	0fab8b93          	addi	s7,s7,250 # 80009030 <ticks>
        c->proc = p;
    80001f3e:	079e                	slli	a5,a5,0x7
    80001f40:	0000fa17          	auipc	s4,0xf
    80001f44:	360a0a13          	addi	s4,s4,864 # 800112a0 <pid_lock>
    80001f48:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4a:	00016917          	auipc	s2,0x16
    80001f4e:	f8690913          	addi	s2,s2,-122 # 80017ed0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5a:	10079073          	csrw	sstatus,a5
    80001f5e:	0000f497          	auipc	s1,0xf
    80001f62:	77248493          	addi	s1,s1,1906 # 800116d0 <proc>
        p->state = RUNNING;
    80001f66:	4a91                	li	s5,4
    80001f68:	a811                	j	80001f7c <scheduler+0x7e>
        release(&p->lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	d0a080e7          	jalr	-758(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f74:	1a048493          	addi	s1,s1,416
    80001f78:	fd248de3          	beq	s1,s2,80001f52 <scheduler+0x54>
      acquire(&p->lock);
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	c44080e7          	jalr	-956(ra) # 80000bc2 <acquire>
      if(p->state != RUNNABLE) {
    80001f86:	4c9c                	lw	a5,24(s1)
    80001f88:	ff3791e3          	bne	a5,s3,80001f6a <scheduler+0x6c>
        p->state = RUNNING;
    80001f8c:	0154ac23          	sw	s5,24(s1)
        p->runningTime = ticks;
    80001f90:	000ba703          	lw	a4,0(s7)
    80001f94:	02071793          	slli	a5,a4,0x20
    80001f98:	9381                	srli	a5,a5,0x20
    80001f9a:	f0bc                	sd	a5,96(s1)
        p->retime += ticks - p->readyTime;
    80001f9c:	44fc                	lw	a5,76(s1)
    80001f9e:	9fb9                	addw	a5,a5,a4
    80001fa0:	6cb8                	ld	a4,88(s1)
    80001fa2:	9f99                	subw	a5,a5,a4
    80001fa4:	c4fc                	sw	a5,76(s1)
        c->proc = p;
    80001fa6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001faa:	09848593          	addi	a1,s1,152
    80001fae:	855a                	mv	a0,s6
    80001fb0:	00001097          	auipc	ra,0x1
    80001fb4:	908080e7          	jalr	-1784(ra) # 800028b8 <swtch>
        c->proc = 0;
    80001fb8:	020a3823          	sd	zero,48(s4)
        release(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	cb8080e7          	jalr	-840(ra) # 80000c76 <release>
    80001fc6:	b77d                	j	80001f74 <scheduler+0x76>

0000000080001fc8 <sched>:
{
    80001fc8:	7179                	addi	sp,sp,-48
    80001fca:	f406                	sd	ra,40(sp)
    80001fcc:	f022                	sd	s0,32(sp)
    80001fce:	ec26                	sd	s1,24(sp)
    80001fd0:	e84a                	sd	s2,16(sp)
    80001fd2:	e44e                	sd	s3,8(sp)
    80001fd4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	9a8080e7          	jalr	-1624(ra) # 8000197e <myproc>
    80001fde:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	b68080e7          	jalr	-1176(ra) # 80000b48 <holding>
    80001fe8:	c93d                	beqz	a0,8000205e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fea:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fec:	2781                	sext.w	a5,a5
    80001fee:	079e                	slli	a5,a5,0x7
    80001ff0:	0000f717          	auipc	a4,0xf
    80001ff4:	2b070713          	addi	a4,a4,688 # 800112a0 <pid_lock>
    80001ff8:	97ba                	add	a5,a5,a4
    80001ffa:	0a87a703          	lw	a4,168(a5)
    80001ffe:	4785                	li	a5,1
    80002000:	06f71763          	bne	a4,a5,8000206e <sched+0xa6>
  if(p->state == RUNNING)
    80002004:	4c98                	lw	a4,24(s1)
    80002006:	4791                	li	a5,4
    80002008:	06f70b63          	beq	a4,a5,8000207e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002010:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002012:	efb5                	bnez	a5,8000208e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002014:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002016:	0000f917          	auipc	s2,0xf
    8000201a:	28a90913          	addi	s2,s2,650 # 800112a0 <pid_lock>
    8000201e:	2781                	sext.w	a5,a5
    80002020:	079e                	slli	a5,a5,0x7
    80002022:	97ca                	add	a5,a5,s2
    80002024:	0ac7a983          	lw	s3,172(a5)
    80002028:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000202a:	2781                	sext.w	a5,a5
    8000202c:	079e                	slli	a5,a5,0x7
    8000202e:	0000f597          	auipc	a1,0xf
    80002032:	2aa58593          	addi	a1,a1,682 # 800112d8 <cpus+0x8>
    80002036:	95be                	add	a1,a1,a5
    80002038:	09848513          	addi	a0,s1,152
    8000203c:	00001097          	auipc	ra,0x1
    80002040:	87c080e7          	jalr	-1924(ra) # 800028b8 <swtch>
    80002044:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002046:	2781                	sext.w	a5,a5
    80002048:	079e                	slli	a5,a5,0x7
    8000204a:	97ca                	add	a5,a5,s2
    8000204c:	0b37a623          	sw	s3,172(a5)
}
    80002050:	70a2                	ld	ra,40(sp)
    80002052:	7402                	ld	s0,32(sp)
    80002054:	64e2                	ld	s1,24(sp)
    80002056:	6942                	ld	s2,16(sp)
    80002058:	69a2                	ld	s3,8(sp)
    8000205a:	6145                	addi	sp,sp,48
    8000205c:	8082                	ret
    panic("sched p->lock");
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	1a250513          	addi	a0,a0,418 # 80008200 <digits+0x1c0>
    80002066:	ffffe097          	auipc	ra,0xffffe
    8000206a:	4c4080e7          	jalr	1220(ra) # 8000052a <panic>
    panic("sched locks");
    8000206e:	00006517          	auipc	a0,0x6
    80002072:	1a250513          	addi	a0,a0,418 # 80008210 <digits+0x1d0>
    80002076:	ffffe097          	auipc	ra,0xffffe
    8000207a:	4b4080e7          	jalr	1204(ra) # 8000052a <panic>
    panic("sched running");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1a250513          	addi	a0,a0,418 # 80008220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4a4080e7          	jalr	1188(ra) # 8000052a <panic>
    panic("sched interruptible");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	1a250513          	addi	a0,a0,418 # 80008230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	494080e7          	jalr	1172(ra) # 8000052a <panic>

000000008000209e <yield>:
{
    8000209e:	1101                	addi	sp,sp,-32
    800020a0:	ec06                	sd	ra,24(sp)
    800020a2:	e822                	sd	s0,16(sp)
    800020a4:	e426                	sd	s1,8(sp)
    800020a6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020a8:	00000097          	auipc	ra,0x0
    800020ac:	8d6080e7          	jalr	-1834(ra) # 8000197e <myproc>
    800020b0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	b10080e7          	jalr	-1264(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800020ba:	478d                	li	a5,3
    800020bc:	cc9c                	sw	a5,24(s1)
  p->readyTime = ticks;
    800020be:	00007717          	auipc	a4,0x7
    800020c2:	f7272703          	lw	a4,-142(a4) # 80009030 <ticks>
    800020c6:	02071793          	slli	a5,a4,0x20
    800020ca:	9381                	srli	a5,a5,0x20
    800020cc:	ecbc                	sd	a5,88(s1)
  p->rutime += ticks - p->runningTime;
    800020ce:	48bc                	lw	a5,80(s1)
    800020d0:	9fb9                	addw	a5,a5,a4
    800020d2:	70b8                	ld	a4,96(s1)
    800020d4:	9f99                	subw	a5,a5,a4
    800020d6:	c8bc                	sw	a5,80(s1)
  sched();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	ef0080e7          	jalr	-272(ra) # 80001fc8 <sched>
  release(&p->lock);
    800020e0:	8526                	mv	a0,s1
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	b94080e7          	jalr	-1132(ra) # 80000c76 <release>
}
    800020ea:	60e2                	ld	ra,24(sp)
    800020ec:	6442                	ld	s0,16(sp)
    800020ee:	64a2                	ld	s1,8(sp)
    800020f0:	6105                	addi	sp,sp,32
    800020f2:	8082                	ret

00000000800020f4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020f4:	7179                	addi	sp,sp,-48
    800020f6:	f406                	sd	ra,40(sp)
    800020f8:	f022                	sd	s0,32(sp)
    800020fa:	ec26                	sd	s1,24(sp)
    800020fc:	e84a                	sd	s2,16(sp)
    800020fe:	e44e                	sd	s3,8(sp)
    80002100:	1800                	addi	s0,sp,48
    80002102:	89aa                	mv	s3,a0
    80002104:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	878080e7          	jalr	-1928(ra) # 8000197e <myproc>
    8000210e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ab2080e7          	jalr	-1358(ra) # 80000bc2 <acquire>
  release(lk);
    80002118:	854a                	mv	a0,s2
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	b5c080e7          	jalr	-1188(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002122:	0334b023          	sd	s3,32(s1)
  p->rutime += ticks - p->runningTime;
    80002126:	48bc                	lw	a5,80(s1)
    80002128:	00007717          	auipc	a4,0x7
    8000212c:	f0872703          	lw	a4,-248(a4) # 80009030 <ticks>
    80002130:	9fb9                	addw	a5,a5,a4
    80002132:	70b8                	ld	a4,96(s1)
    80002134:	9f99                	subw	a5,a5,a4
    80002136:	c8bc                	sw	a5,80(s1)
  p->state = SLEEPING;
    80002138:	4789                	li	a5,2
    8000213a:	cc9c                	sw	a5,24(s1)

  sched();
    8000213c:	00000097          	auipc	ra,0x0
    80002140:	e8c080e7          	jalr	-372(ra) # 80001fc8 <sched>

  // Tidy up.
  p->chan = 0;
    80002144:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b2c080e7          	jalr	-1236(ra) # 80000c76 <release>
  acquire(lk);
    80002152:	854a                	mv	a0,s2
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	a6e080e7          	jalr	-1426(ra) # 80000bc2 <acquire>
}
    8000215c:	70a2                	ld	ra,40(sp)
    8000215e:	7402                	ld	s0,32(sp)
    80002160:	64e2                	ld	s1,24(sp)
    80002162:	6942                	ld	s2,16(sp)
    80002164:	69a2                	ld	s3,8(sp)
    80002166:	6145                	addi	sp,sp,48
    80002168:	8082                	ret

000000008000216a <wait_extension>:
{
    8000216a:	711d                	addi	sp,sp,-96
    8000216c:	ec86                	sd	ra,88(sp)
    8000216e:	e8a2                	sd	s0,80(sp)
    80002170:	e4a6                	sd	s1,72(sp)
    80002172:	e0ca                	sd	s2,64(sp)
    80002174:	fc4e                	sd	s3,56(sp)
    80002176:	f852                	sd	s4,48(sp)
    80002178:	f456                	sd	s5,40(sp)
    8000217a:	f05a                	sd	s6,32(sp)
    8000217c:	ec5e                	sd	s7,24(sp)
    8000217e:	e862                	sd	s8,16(sp)
    80002180:	e466                	sd	s9,8(sp)
    80002182:	1080                	addi	s0,sp,96
    80002184:	8baa                	mv	s7,a0
    80002186:	8b2e                	mv	s6,a1
  struct proc *p = myproc();
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	7f6080e7          	jalr	2038(ra) # 8000197e <myproc>
    80002190:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002192:	0000f517          	auipc	a0,0xf
    80002196:	12650513          	addi	a0,a0,294 # 800112b8 <wait_lock>
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	a28080e7          	jalr	-1496(ra) # 80000bc2 <acquire>
    havekids = 0;
    800021a2:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    800021a4:	4a15                	li	s4,5
        havekids = 1;
    800021a6:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800021a8:	00016997          	auipc	s3,0x16
    800021ac:	d2898993          	addi	s3,s3,-728 # 80017ed0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021b0:	0000fc97          	auipc	s9,0xf
    800021b4:	108c8c93          	addi	s9,s9,264 # 800112b8 <wait_lock>
    havekids = 0;
    800021b8:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    800021ba:	0000f497          	auipc	s1,0xf
    800021be:	51648493          	addi	s1,s1,1302 # 800116d0 <proc>
    800021c2:	a231                	j	800022ce <wait_extension+0x164>
          pid = np->pid;
    800021c4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021c8:	0c0b9463          	bnez	s7,80002290 <wait_extension+0x126>
          if (performance){
    800021cc:	080b0f63          	beqz	s6,8000226a <wait_extension+0x100>
            copyout(p->pagetable, (uint64) performance, (char*)&np->ctime, sizeof(int))< 0 ||
    800021d0:	4691                	li	a3,4
    800021d2:	04048613          	addi	a2,s1,64
    800021d6:	85da                	mv	a1,s6
    800021d8:	08893503          	ld	a0,136(s2)
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	462080e7          	jalr	1122(ra) # 8000163e <copyout>
            if(
    800021e4:	14054963          	bltz	a0,80002336 <wait_extension+0x1cc>
            copyout(p->pagetable, (uint64) performance+4, (char*)&np->ttime, sizeof(int))< 0 ||
    800021e8:	4691                	li	a3,4
    800021ea:	04448613          	addi	a2,s1,68
    800021ee:	004b0593          	addi	a1,s6,4
    800021f2:	08893503          	ld	a0,136(s2)
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	448080e7          	jalr	1096(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance, (char*)&np->ctime, sizeof(int))< 0 ||
    800021fe:	12054e63          	bltz	a0,8000233a <wait_extension+0x1d0>
            copyout(p->pagetable, (uint64) performance+8, (char*)&np->stime, sizeof(int))< 0 ||
    80002202:	4691                	li	a3,4
    80002204:	04848613          	addi	a2,s1,72
    80002208:	008b0593          	addi	a1,s6,8
    8000220c:	08893503          	ld	a0,136(s2)
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	42e080e7          	jalr	1070(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+4, (char*)&np->ttime, sizeof(int))< 0 ||
    80002218:	12054363          	bltz	a0,8000233e <wait_extension+0x1d4>
            copyout(p->pagetable, (uint64) performance+12, (char*)&np->retime, sizeof(int))< 0 ||
    8000221c:	4691                	li	a3,4
    8000221e:	04c48613          	addi	a2,s1,76
    80002222:	00cb0593          	addi	a1,s6,12
    80002226:	08893503          	ld	a0,136(s2)
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	414080e7          	jalr	1044(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+8, (char*)&np->stime, sizeof(int))< 0 ||
    80002232:	10054863          	bltz	a0,80002342 <wait_extension+0x1d8>
            copyout(p->pagetable, (uint64) performance+16, (char*)&np->rutime, sizeof(int))< 0 ||
    80002236:	4691                	li	a3,4
    80002238:	05048613          	addi	a2,s1,80
    8000223c:	010b0593          	addi	a1,s6,16
    80002240:	08893503          	ld	a0,136(s2)
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	3fa080e7          	jalr	1018(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+12, (char*)&np->retime, sizeof(int))< 0 ||
    8000224c:	0e054d63          	bltz	a0,80002346 <wait_extension+0x1dc>
            copyout(p->pagetable, (uint64) performance+20, (char*)&np->average_bursttime, sizeof(int))< 0
    80002250:	4691                	li	a3,4
    80002252:	05448613          	addi	a2,s1,84
    80002256:	014b0593          	addi	a1,s6,20
    8000225a:	08893503          	ld	a0,136(s2)
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	3e0080e7          	jalr	992(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+16, (char*)&np->rutime, sizeof(int))< 0 ||
    80002266:	0e054263          	bltz	a0,8000234a <wait_extension+0x1e0>
          freeproc(np);
    8000226a:	8526                	mv	a0,s1
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	8c4080e7          	jalr	-1852(ra) # 80001b30 <freeproc>
          release(&np->lock);
    80002274:	8526                	mv	a0,s1
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a00080e7          	jalr	-1536(ra) # 80000c76 <release>
          release(&wait_lock);
    8000227e:	0000f517          	auipc	a0,0xf
    80002282:	03a50513          	addi	a0,a0,58 # 800112b8 <wait_lock>
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	9f0080e7          	jalr	-1552(ra) # 80000c76 <release>
          return pid;
    8000228e:	a8bd                	j	8000230c <wait_extension+0x1a2>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002290:	4691                	li	a3,4
    80002292:	02c48613          	addi	a2,s1,44
    80002296:	85de                	mv	a1,s7
    80002298:	08893503          	ld	a0,136(s2)
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	3a2080e7          	jalr	930(ra) # 8000163e <copyout>
    800022a4:	f20554e3          	bgez	a0,800021cc <wait_extension+0x62>
            release(&np->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9cc080e7          	jalr	-1588(ra) # 80000c76 <release>
            release(&wait_lock);
    800022b2:	0000f517          	auipc	a0,0xf
    800022b6:	00650513          	addi	a0,a0,6 # 800112b8 <wait_lock>
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	9bc080e7          	jalr	-1604(ra) # 80000c76 <release>
            return -1;
    800022c2:	59fd                	li	s3,-1
    800022c4:	a0a1                	j	8000230c <wait_extension+0x1a2>
    for(np = proc; np < &proc[NPROC]; np++){
    800022c6:	1a048493          	addi	s1,s1,416
    800022ca:	03348463          	beq	s1,s3,800022f2 <wait_extension+0x188>
      if(np->parent == p){
    800022ce:	78bc                	ld	a5,112(s1)
    800022d0:	ff279be3          	bne	a5,s2,800022c6 <wait_extension+0x15c>
        acquire(&np->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	8ec080e7          	jalr	-1812(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800022de:	4c9c                	lw	a5,24(s1)
    800022e0:	ef4782e3          	beq	a5,s4,800021c4 <wait_extension+0x5a>
        release(&np->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	990080e7          	jalr	-1648(ra) # 80000c76 <release>
        havekids = 1;
    800022ee:	8756                	mv	a4,s5
    800022f0:	bfd9                	j	800022c6 <wait_extension+0x15c>
    if(!havekids || p->killed){
    800022f2:	c701                	beqz	a4,800022fa <wait_extension+0x190>
    800022f4:	02892783          	lw	a5,40(s2)
    800022f8:	cb85                	beqz	a5,80002328 <wait_extension+0x1be>
      release(&wait_lock);
    800022fa:	0000f517          	auipc	a0,0xf
    800022fe:	fbe50513          	addi	a0,a0,-66 # 800112b8 <wait_lock>
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	974080e7          	jalr	-1676(ra) # 80000c76 <release>
      return -1;
    8000230a:	59fd                	li	s3,-1
}
    8000230c:	854e                	mv	a0,s3
    8000230e:	60e6                	ld	ra,88(sp)
    80002310:	6446                	ld	s0,80(sp)
    80002312:	64a6                	ld	s1,72(sp)
    80002314:	6906                	ld	s2,64(sp)
    80002316:	79e2                	ld	s3,56(sp)
    80002318:	7a42                	ld	s4,48(sp)
    8000231a:	7aa2                	ld	s5,40(sp)
    8000231c:	7b02                	ld	s6,32(sp)
    8000231e:	6be2                	ld	s7,24(sp)
    80002320:	6c42                	ld	s8,16(sp)
    80002322:	6ca2                	ld	s9,8(sp)
    80002324:	6125                	addi	sp,sp,96
    80002326:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002328:	85e6                	mv	a1,s9
    8000232a:	854a                	mv	a0,s2
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	dc8080e7          	jalr	-568(ra) # 800020f4 <sleep>
    havekids = 0;
    80002334:	b551                	j	800021b8 <wait_extension+0x4e>
            return -1;
    80002336:	59fd                	li	s3,-1
    80002338:	bfd1                	j	8000230c <wait_extension+0x1a2>
    8000233a:	59fd                	li	s3,-1
    8000233c:	bfc1                	j	8000230c <wait_extension+0x1a2>
    8000233e:	59fd                	li	s3,-1
    80002340:	b7f1                	j	8000230c <wait_extension+0x1a2>
    80002342:	59fd                	li	s3,-1
    80002344:	b7e1                	j	8000230c <wait_extension+0x1a2>
    80002346:	59fd                	li	s3,-1
    80002348:	b7d1                	j	8000230c <wait_extension+0x1a2>
    8000234a:	59fd                	li	s3,-1
    8000234c:	b7c1                	j	8000230c <wait_extension+0x1a2>

000000008000234e <wait>:
{
    8000234e:	1141                	addi	sp,sp,-16
    80002350:	e406                	sd	ra,8(sp)
    80002352:	e022                	sd	s0,0(sp)
    80002354:	0800                	addi	s0,sp,16
  return wait_extension (addr, 0);
    80002356:	4581                	li	a1,0
    80002358:	00000097          	auipc	ra,0x0
    8000235c:	e12080e7          	jalr	-494(ra) # 8000216a <wait_extension>
}
    80002360:	60a2                	ld	ra,8(sp)
    80002362:	6402                	ld	s0,0(sp)
    80002364:	0141                	addi	sp,sp,16
    80002366:	8082                	ret

0000000080002368 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002368:	7139                	addi	sp,sp,-64
    8000236a:	fc06                	sd	ra,56(sp)
    8000236c:	f822                	sd	s0,48(sp)
    8000236e:	f426                	sd	s1,40(sp)
    80002370:	f04a                	sd	s2,32(sp)
    80002372:	ec4e                	sd	s3,24(sp)
    80002374:	e852                	sd	s4,16(sp)
    80002376:	e456                	sd	s5,8(sp)
    80002378:	e05a                	sd	s6,0(sp)
    8000237a:	0080                	addi	s0,sp,64
    8000237c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000237e:	0000f497          	auipc	s1,0xf
    80002382:	35248493          	addi	s1,s1,850 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002386:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002388:	4b0d                	li	s6,3
        p->stime += ticks - p->sleepTime;
    8000238a:	00007a97          	auipc	s5,0x7
    8000238e:	ca6a8a93          	addi	s5,s5,-858 # 80009030 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002392:	00016917          	auipc	s2,0x16
    80002396:	b3e90913          	addi	s2,s2,-1218 # 80017ed0 <tickslock>
    8000239a:	a811                	j	800023ae <wakeup+0x46>
        p->readyTime = ticks;
      }
      release(&p->lock);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8d8080e7          	jalr	-1832(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023a6:	1a048493          	addi	s1,s1,416
    800023aa:	05248063          	beq	s1,s2,800023ea <wakeup+0x82>
    if(p != myproc()){
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	5d0080e7          	jalr	1488(ra) # 8000197e <myproc>
    800023b6:	fea488e3          	beq	s1,a0,800023a6 <wakeup+0x3e>
      acquire(&p->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	806080e7          	jalr	-2042(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023c4:	4c9c                	lw	a5,24(s1)
    800023c6:	fd379be3          	bne	a5,s3,8000239c <wakeup+0x34>
    800023ca:	709c                	ld	a5,32(s1)
    800023cc:	fd4798e3          	bne	a5,s4,8000239c <wakeup+0x34>
        p->state = RUNNABLE;
    800023d0:	0164ac23          	sw	s6,24(s1)
        p->stime += ticks - p->sleepTime;
    800023d4:	000aa703          	lw	a4,0(s5)
    800023d8:	44bc                	lw	a5,72(s1)
    800023da:	9fb9                	addw	a5,a5,a4
    800023dc:	74b4                	ld	a3,104(s1)
    800023de:	9f95                	subw	a5,a5,a3
    800023e0:	c4bc                	sw	a5,72(s1)
        p->readyTime = ticks;
    800023e2:	1702                	slli	a4,a4,0x20
    800023e4:	9301                	srli	a4,a4,0x20
    800023e6:	ecb8                	sd	a4,88(s1)
    800023e8:	bf55                	j	8000239c <wakeup+0x34>
    }
  }
}
    800023ea:	70e2                	ld	ra,56(sp)
    800023ec:	7442                	ld	s0,48(sp)
    800023ee:	74a2                	ld	s1,40(sp)
    800023f0:	7902                	ld	s2,32(sp)
    800023f2:	69e2                	ld	s3,24(sp)
    800023f4:	6a42                	ld	s4,16(sp)
    800023f6:	6aa2                	ld	s5,8(sp)
    800023f8:	6b02                	ld	s6,0(sp)
    800023fa:	6121                	addi	sp,sp,64
    800023fc:	8082                	ret

00000000800023fe <reparent>:
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
    8000240e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002410:	0000f497          	auipc	s1,0xf
    80002414:	2c048493          	addi	s1,s1,704 # 800116d0 <proc>
      pp->parent = initproc;
    80002418:	00007a17          	auipc	s4,0x7
    8000241c:	c10a0a13          	addi	s4,s4,-1008 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002420:	00016997          	auipc	s3,0x16
    80002424:	ab098993          	addi	s3,s3,-1360 # 80017ed0 <tickslock>
    80002428:	a029                	j	80002432 <reparent+0x34>
    8000242a:	1a048493          	addi	s1,s1,416
    8000242e:	01348d63          	beq	s1,s3,80002448 <reparent+0x4a>
    if(pp->parent == p){
    80002432:	78bc                	ld	a5,112(s1)
    80002434:	ff279be3          	bne	a5,s2,8000242a <reparent+0x2c>
      pp->parent = initproc;
    80002438:	000a3503          	ld	a0,0(s4)
    8000243c:	f8a8                	sd	a0,112(s1)
      wakeup(initproc);
    8000243e:	00000097          	auipc	ra,0x0
    80002442:	f2a080e7          	jalr	-214(ra) # 80002368 <wakeup>
    80002446:	b7d5                	j	8000242a <reparent+0x2c>
}
    80002448:	70a2                	ld	ra,40(sp)
    8000244a:	7402                	ld	s0,32(sp)
    8000244c:	64e2                	ld	s1,24(sp)
    8000244e:	6942                	ld	s2,16(sp)
    80002450:	69a2                	ld	s3,8(sp)
    80002452:	6a02                	ld	s4,0(sp)
    80002454:	6145                	addi	sp,sp,48
    80002456:	8082                	ret

0000000080002458 <exit>:
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	e052                	sd	s4,0(sp)
    80002466:	1800                	addi	s0,sp,48
    80002468:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	514080e7          	jalr	1300(ra) # 8000197e <myproc>
    80002472:	892a                	mv	s2,a0
  p->ttime = ticks;
    80002474:	00007797          	auipc	a5,0x7
    80002478:	bbc7a783          	lw	a5,-1092(a5) # 80009030 <ticks>
    8000247c:	c17c                	sw	a5,68(a0)
  if(p == initproc)
    8000247e:	00007797          	auipc	a5,0x7
    80002482:	baa7b783          	ld	a5,-1110(a5) # 80009028 <initproc>
    80002486:	10850493          	addi	s1,a0,264
    8000248a:	18850993          	addi	s3,a0,392
    8000248e:	02a79363          	bne	a5,a0,800024b4 <exit+0x5c>
    panic("init exiting");
    80002492:	00006517          	auipc	a0,0x6
    80002496:	db650513          	addi	a0,a0,-586 # 80008248 <digits+0x208>
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	090080e7          	jalr	144(ra) # 8000052a <panic>
      fileclose(f);
    800024a2:	00002097          	auipc	ra,0x2
    800024a6:	4ba080e7          	jalr	1210(ra) # 8000495c <fileclose>
      p->ofile[fd] = 0;
    800024aa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024ae:	04a1                	addi	s1,s1,8
    800024b0:	01348563          	beq	s1,s3,800024ba <exit+0x62>
    if(p->ofile[fd]){
    800024b4:	6088                	ld	a0,0(s1)
    800024b6:	f575                	bnez	a0,800024a2 <exit+0x4a>
    800024b8:	bfdd                	j	800024ae <exit+0x56>
  begin_op();
    800024ba:	00002097          	auipc	ra,0x2
    800024be:	fd6080e7          	jalr	-42(ra) # 80004490 <begin_op>
  iput(p->cwd);
    800024c2:	18893503          	ld	a0,392(s2)
    800024c6:	00001097          	auipc	ra,0x1
    800024ca:	7ae080e7          	jalr	1966(ra) # 80003c74 <iput>
  end_op();
    800024ce:	00002097          	auipc	ra,0x2
    800024d2:	042080e7          	jalr	66(ra) # 80004510 <end_op>
  p->cwd = 0;
    800024d6:	18093423          	sd	zero,392(s2)
  acquire(&wait_lock);
    800024da:	0000f517          	auipc	a0,0xf
    800024de:	dde50513          	addi	a0,a0,-546 # 800112b8 <wait_lock>
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	6e0080e7          	jalr	1760(ra) # 80000bc2 <acquire>
  reparent(p);
    800024ea:	854a                	mv	a0,s2
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	f12080e7          	jalr	-238(ra) # 800023fe <reparent>
  wakeup(p->parent);
    800024f4:	07093503          	ld	a0,112(s2)
    800024f8:	00000097          	auipc	ra,0x0
    800024fc:	e70080e7          	jalr	-400(ra) # 80002368 <wakeup>
  acquire(&p->lock);
    80002500:	854a                	mv	a0,s2
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	6c0080e7          	jalr	1728(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000250a:	03492623          	sw	s4,44(s2)
  if(p->state == RUNNING)
    8000250e:	01892703          	lw	a4,24(s2)
    80002512:	4791                	li	a5,4
    80002514:	02f70963          	beq	a4,a5,80002546 <exit+0xee>
  p->state = ZOMBIE;
    80002518:	4795                	li	a5,5
    8000251a:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    8000251e:	0000f517          	auipc	a0,0xf
    80002522:	d9a50513          	addi	a0,a0,-614 # 800112b8 <wait_lock>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	750080e7          	jalr	1872(ra) # 80000c76 <release>
  sched();
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	a9a080e7          	jalr	-1382(ra) # 80001fc8 <sched>
  panic("zombie exit");
    80002536:	00006517          	auipc	a0,0x6
    8000253a:	d2250513          	addi	a0,a0,-734 # 80008258 <digits+0x218>
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	fec080e7          	jalr	-20(ra) # 8000052a <panic>
    p->rutime += ticks - p->runningTime;
    80002546:	05092783          	lw	a5,80(s2)
    8000254a:	00007717          	auipc	a4,0x7
    8000254e:	ae672703          	lw	a4,-1306(a4) # 80009030 <ticks>
    80002552:	9fb9                	addw	a5,a5,a4
    80002554:	06093703          	ld	a4,96(s2)
    80002558:	9f99                	subw	a5,a5,a4
    8000255a:	04f92823          	sw	a5,80(s2)
    8000255e:	bf6d                	j	80002518 <exit+0xc0>

0000000080002560 <set_priority>:

int 
set_priority(int prio)
{
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    80002560:	47e5                	li	a5,25
    80002562:	04a7e963          	bltu	a5,a0,800025b4 <set_priority+0x54>
{
    80002566:	1101                	addi	sp,sp,-32
    80002568:	ec06                	sd	ra,24(sp)
    8000256a:	e822                	sd	s0,16(sp)
    8000256c:	e426                	sd	s1,8(sp)
    8000256e:	e04a                	sd	s2,0(sp)
    80002570:	1000                	addi	s0,sp,32
    80002572:	892a                	mv	s2,a0
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    80002574:	020007b7          	lui	a5,0x2000
    80002578:	0aa78793          	addi	a5,a5,170 # 20000aa <_entry-0x7dffff56>
    8000257c:	00a7d7b3          	srl	a5,a5,a0
    80002580:	8b85                	andi	a5,a5,1
    && prio != LOW_PRIORITY && prio != TEST_LOW_PRIORITY){
      return -1;
    80002582:	557d                	li	a0,-1
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    80002584:	c395                	beqz	a5,800025a8 <set_priority+0x48>
  }
  struct proc *p = myproc();
    80002586:	fffff097          	auipc	ra,0xfffff
    8000258a:	3f8080e7          	jalr	1016(ra) # 8000197e <myproc>
    8000258e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	632080e7          	jalr	1586(ra) # 80000bc2 <acquire>
    p->priority = prio;
    80002598:	0324ae23          	sw	s2,60(s1)
  release(&p->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	6d8080e7          	jalr	1752(ra) # 80000c76 <release>
  return 0;
    800025a6:	4501                	li	a0,0
}
    800025a8:	60e2                	ld	ra,24(sp)
    800025aa:	6442                	ld	s0,16(sp)
    800025ac:	64a2                	ld	s1,8(sp)
    800025ae:	6902                	ld	s2,0(sp)
    800025b0:	6105                	addi	sp,sp,32
    800025b2:	8082                	ret
      return -1;
    800025b4:	557d                	li	a0,-1
}
    800025b6:	8082                	ret

00000000800025b8 <trace>:

int 
trace(int mask_input, int pid)
{
    800025b8:	7179                	addi	sp,sp,-48
    800025ba:	f406                	sd	ra,40(sp)
    800025bc:	f022                	sd	s0,32(sp)
    800025be:	ec26                	sd	s1,24(sp)
    800025c0:	e84a                	sd	s2,16(sp)
    800025c2:	e44e                	sd	s3,8(sp)
    800025c4:	e052                	sd	s4,0(sp)
    800025c6:	1800                	addi	s0,sp,48
    800025c8:	8a2a                	mv	s4,a0
    800025ca:	892e                	mv	s2,a1
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800025cc:	0000f497          	auipc	s1,0xf
    800025d0:	10448493          	addi	s1,s1,260 # 800116d0 <proc>
    800025d4:	00016997          	auipc	s3,0x16
    800025d8:	8fc98993          	addi	s3,s3,-1796 # 80017ed0 <tickslock>
    800025dc:	a811                	j	800025f0 <trace+0x38>
    acquire(&p->lock);
    if(p->pid == pid)
      p->mask = mask_input;
    release(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	696080e7          	jalr	1686(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e8:	1a048493          	addi	s1,s1,416
    800025ec:	01348d63          	beq	s1,s3,80002606 <trace+0x4e>
    acquire(&p->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	5d0080e7          	jalr	1488(ra) # 80000bc2 <acquire>
    if(p->pid == pid)
    800025fa:	589c                	lw	a5,48(s1)
    800025fc:	ff2791e3          	bne	a5,s2,800025de <trace+0x26>
      p->mask = mask_input;
    80002600:	0344aa23          	sw	s4,52(s1)
    80002604:	bfe9                	j	800025de <trace+0x26>
  }
  return 0;

}
    80002606:	4501                	li	a0,0
    80002608:	70a2                	ld	ra,40(sp)
    8000260a:	7402                	ld	s0,32(sp)
    8000260c:	64e2                	ld	s1,24(sp)
    8000260e:	6942                	ld	s2,16(sp)
    80002610:	69a2                	ld	s3,8(sp)
    80002612:	6a02                	ld	s4,0(sp)
    80002614:	6145                	addi	sp,sp,48
    80002616:	8082                	ret

0000000080002618 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002618:	7179                	addi	sp,sp,-48
    8000261a:	f406                	sd	ra,40(sp)
    8000261c:	f022                	sd	s0,32(sp)
    8000261e:	ec26                	sd	s1,24(sp)
    80002620:	e84a                	sd	s2,16(sp)
    80002622:	e44e                	sd	s3,8(sp)
    80002624:	1800                	addi	s0,sp,48
    80002626:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002628:	0000f497          	auipc	s1,0xf
    8000262c:	0a848493          	addi	s1,s1,168 # 800116d0 <proc>
    80002630:	00016997          	auipc	s3,0x16
    80002634:	8a098993          	addi	s3,s3,-1888 # 80017ed0 <tickslock>
    acquire(&p->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	588080e7          	jalr	1416(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002642:	589c                	lw	a5,48(s1)
    80002644:	01278d63          	beq	a5,s2,8000265e <kill+0x46>
        p->readyTime = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002648:	8526                	mv	a0,s1
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	62c080e7          	jalr	1580(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002652:	1a048493          	addi	s1,s1,416
    80002656:	ff3491e3          	bne	s1,s3,80002638 <kill+0x20>
  }
  return -1;
    8000265a:	557d                	li	a0,-1
    8000265c:	a829                	j	80002676 <kill+0x5e>
      p->killed = 1;
    8000265e:	4785                	li	a5,1
    80002660:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002662:	4c98                	lw	a4,24(s1)
    80002664:	4789                	li	a5,2
    80002666:	00f70f63          	beq	a4,a5,80002684 <kill+0x6c>
      release(&p->lock);
    8000266a:	8526                	mv	a0,s1
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	60a080e7          	jalr	1546(ra) # 80000c76 <release>
      return 0;
    80002674:	4501                	li	a0,0
}
    80002676:	70a2                	ld	ra,40(sp)
    80002678:	7402                	ld	s0,32(sp)
    8000267a:	64e2                	ld	s1,24(sp)
    8000267c:	6942                	ld	s2,16(sp)
    8000267e:	69a2                	ld	s3,8(sp)
    80002680:	6145                	addi	sp,sp,48
    80002682:	8082                	ret
        p->state = RUNNABLE;
    80002684:	478d                	li	a5,3
    80002686:	cc9c                	sw	a5,24(s1)
        p->stime += ticks - p->sleepTime;
    80002688:	00007717          	auipc	a4,0x7
    8000268c:	9a872703          	lw	a4,-1624(a4) # 80009030 <ticks>
    80002690:	44bc                	lw	a5,72(s1)
    80002692:	9fb9                	addw	a5,a5,a4
    80002694:	74b4                	ld	a3,104(s1)
    80002696:	9f95                	subw	a5,a5,a3
    80002698:	c4bc                	sw	a5,72(s1)
        p->readyTime = ticks;
    8000269a:	1702                	slli	a4,a4,0x20
    8000269c:	9301                	srli	a4,a4,0x20
    8000269e:	ecb8                	sd	a4,88(s1)
    800026a0:	b7e9                	j	8000266a <kill+0x52>

00000000800026a2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026a2:	7179                	addi	sp,sp,-48
    800026a4:	f406                	sd	ra,40(sp)
    800026a6:	f022                	sd	s0,32(sp)
    800026a8:	ec26                	sd	s1,24(sp)
    800026aa:	e84a                	sd	s2,16(sp)
    800026ac:	e44e                	sd	s3,8(sp)
    800026ae:	e052                	sd	s4,0(sp)
    800026b0:	1800                	addi	s0,sp,48
    800026b2:	84aa                	mv	s1,a0
    800026b4:	892e                	mv	s2,a1
    800026b6:	89b2                	mv	s3,a2
    800026b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	2c4080e7          	jalr	708(ra) # 8000197e <myproc>
  if(user_dst){
    800026c2:	c08d                	beqz	s1,800026e4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026c4:	86d2                	mv	a3,s4
    800026c6:	864e                	mv	a2,s3
    800026c8:	85ca                	mv	a1,s2
    800026ca:	6548                	ld	a0,136(a0)
    800026cc:	fffff097          	auipc	ra,0xfffff
    800026d0:	f72080e7          	jalr	-142(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026d4:	70a2                	ld	ra,40(sp)
    800026d6:	7402                	ld	s0,32(sp)
    800026d8:	64e2                	ld	s1,24(sp)
    800026da:	6942                	ld	s2,16(sp)
    800026dc:	69a2                	ld	s3,8(sp)
    800026de:	6a02                	ld	s4,0(sp)
    800026e0:	6145                	addi	sp,sp,48
    800026e2:	8082                	ret
    memmove((char *)dst, src, len);
    800026e4:	000a061b          	sext.w	a2,s4
    800026e8:	85ce                	mv	a1,s3
    800026ea:	854a                	mv	a0,s2
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	62e080e7          	jalr	1582(ra) # 80000d1a <memmove>
    return 0;
    800026f4:	8526                	mv	a0,s1
    800026f6:	bff9                	j	800026d4 <either_copyout+0x32>

00000000800026f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026f8:	7179                	addi	sp,sp,-48
    800026fa:	f406                	sd	ra,40(sp)
    800026fc:	f022                	sd	s0,32(sp)
    800026fe:	ec26                	sd	s1,24(sp)
    80002700:	e84a                	sd	s2,16(sp)
    80002702:	e44e                	sd	s3,8(sp)
    80002704:	e052                	sd	s4,0(sp)
    80002706:	1800                	addi	s0,sp,48
    80002708:	892a                	mv	s2,a0
    8000270a:	84ae                	mv	s1,a1
    8000270c:	89b2                	mv	s3,a2
    8000270e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	26e080e7          	jalr	622(ra) # 8000197e <myproc>
  if(user_src){
    80002718:	c08d                	beqz	s1,8000273a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000271a:	86d2                	mv	a3,s4
    8000271c:	864e                	mv	a2,s3
    8000271e:	85ca                	mv	a1,s2
    80002720:	6548                	ld	a0,136(a0)
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	fa8080e7          	jalr	-88(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000272a:	70a2                	ld	ra,40(sp)
    8000272c:	7402                	ld	s0,32(sp)
    8000272e:	64e2                	ld	s1,24(sp)
    80002730:	6942                	ld	s2,16(sp)
    80002732:	69a2                	ld	s3,8(sp)
    80002734:	6a02                	ld	s4,0(sp)
    80002736:	6145                	addi	sp,sp,48
    80002738:	8082                	ret
    memmove(dst, (char*)src, len);
    8000273a:	000a061b          	sext.w	a2,s4
    8000273e:	85ce                	mv	a1,s3
    80002740:	854a                	mv	a0,s2
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	5d8080e7          	jalr	1496(ra) # 80000d1a <memmove>
    return 0;
    8000274a:	8526                	mv	a0,s1
    8000274c:	bff9                	j	8000272a <either_copyin+0x32>

000000008000274e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000274e:	715d                	addi	sp,sp,-80
    80002750:	e486                	sd	ra,72(sp)
    80002752:	e0a2                	sd	s0,64(sp)
    80002754:	fc26                	sd	s1,56(sp)
    80002756:	f84a                	sd	s2,48(sp)
    80002758:	f44e                	sd	s3,40(sp)
    8000275a:	f052                	sd	s4,32(sp)
    8000275c:	ec56                	sd	s5,24(sp)
    8000275e:	e85a                	sd	s6,16(sp)
    80002760:	e45e                	sd	s7,8(sp)
    80002762:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002764:	00006517          	auipc	a0,0x6
    80002768:	96450513          	addi	a0,a0,-1692 # 800080c8 <digits+0x88>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	e08080e7          	jalr	-504(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002774:	0000f497          	auipc	s1,0xf
    80002778:	0ec48493          	addi	s1,s1,236 # 80011860 <proc+0x190>
    8000277c:	00016917          	auipc	s2,0x16
    80002780:	8e490913          	addi	s2,s2,-1820 # 80018060 <bcache+0x178>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002784:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002786:	00006997          	auipc	s3,0x6
    8000278a:	ae298993          	addi	s3,s3,-1310 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000278e:	00006a97          	auipc	s5,0x6
    80002792:	ae2a8a93          	addi	s5,s5,-1310 # 80008270 <digits+0x230>
    printf("\n");
    80002796:	00006a17          	auipc	s4,0x6
    8000279a:	932a0a13          	addi	s4,s4,-1742 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279e:	00006b97          	auipc	s7,0x6
    800027a2:	b0ab8b93          	addi	s7,s7,-1270 # 800082a8 <states.0>
    800027a6:	a00d                	j	800027c8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027a8:	ea06a583          	lw	a1,-352(a3)
    800027ac:	8556                	mv	a0,s5
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	dc6080e7          	jalr	-570(ra) # 80000574 <printf>
    printf("\n");
    800027b6:	8552                	mv	a0,s4
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	dbc080e7          	jalr	-580(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c0:	1a048493          	addi	s1,s1,416
    800027c4:	03248263          	beq	s1,s2,800027e8 <procdump+0x9a>
    if(p->state == UNUSED)
    800027c8:	86a6                	mv	a3,s1
    800027ca:	e884a783          	lw	a5,-376(s1)
    800027ce:	dbed                	beqz	a5,800027c0 <procdump+0x72>
      state = "???";
    800027d0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d2:	fcfb6be3          	bltu	s6,a5,800027a8 <procdump+0x5a>
    800027d6:	02079713          	slli	a4,a5,0x20
    800027da:	01d75793          	srli	a5,a4,0x1d
    800027de:	97de                	add	a5,a5,s7
    800027e0:	6390                	ld	a2,0(a5)
    800027e2:	f279                	bnez	a2,800027a8 <procdump+0x5a>
      state = "???";
    800027e4:	864e                	mv	a2,s3
    800027e6:	b7c9                	j	800027a8 <procdump+0x5a>
  }
}
    800027e8:	60a6                	ld	ra,72(sp)
    800027ea:	6406                	ld	s0,64(sp)
    800027ec:	74e2                	ld	s1,56(sp)
    800027ee:	7942                	ld	s2,48(sp)
    800027f0:	79a2                	ld	s3,40(sp)
    800027f2:	7a02                	ld	s4,32(sp)
    800027f4:	6ae2                	ld	s5,24(sp)
    800027f6:	6b42                	ld	s6,16(sp)
    800027f8:	6ba2                	ld	s7,8(sp)
    800027fa:	6161                	addi	sp,sp,80
    800027fc:	8082                	ret

00000000800027fe <wait_stat>:


int
wait_stat(int* status, struct perf* performance)
{
    800027fe:	1141                	addi	sp,sp,-16
    80002800:	e406                	sd	ra,8(sp)
    80002802:	e022                	sd	s0,0(sp)
    80002804:	0800                	addi	s0,sp,16
  
  return wait_extension ((uint64)*status, performance);
    80002806:	4108                	lw	a0,0(a0)
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	962080e7          	jalr	-1694(ra) # 8000216a <wait_extension>
}
    80002810:	60a2                	ld	ra,8(sp)
    80002812:	6402                	ld	s0,0(sp)
    80002814:	0141                	addi	sp,sp,16
    80002816:	8082                	ret

0000000080002818 <inctickcounter>:


int inctickcounter() {
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	e04a                	sd	s2,0(sp)
    80002822:	1000                	addi	s0,sp,32
  int res;
  struct proc *p = myproc();
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	15a080e7          	jalr	346(ra) # 8000197e <myproc>
    8000282c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	394080e7          	jalr	916(ra) # 80000bc2 <acquire>
  res = proc->tickcounter;
    80002836:	0000f917          	auipc	s2,0xf
    8000283a:	ed292903          	lw	s2,-302(s2) # 80011708 <proc+0x38>
  res++;
  release(&p->lock);
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	436080e7          	jalr	1078(ra) # 80000c76 <release>
  return res;
}
    80002848:	0019051b          	addiw	a0,s2,1
    8000284c:	60e2                	ld	ra,24(sp)
    8000284e:	6442                	ld	s0,16(sp)
    80002850:	64a2                	ld	s1,8(sp)
    80002852:	6902                	ld	s2,0(sp)
    80002854:	6105                	addi	sp,sp,32
    80002856:	8082                	ret

0000000080002858 <switch_to_process>:

void switch_to_process(struct proc *p, struct cpu *c){
    80002858:	1101                	addi	sp,sp,-32
    8000285a:	ec06                	sd	ra,24(sp)
    8000285c:	e822                	sd	s0,16(sp)
    8000285e:	e426                	sd	s1,8(sp)
    80002860:	1000                	addi	s0,sp,32
    80002862:	84ae                	mv	s1,a1
  // Switch to chosen process.  It is the process's job
  // to release its lock and then reacquire it
  // before jumping back to us.
  p->state = RUNNING;
    80002864:	4791                	li	a5,4
    80002866:	cd1c                	sw	a5,24(a0)
  p->retime += ticks - p->readyTime;
    80002868:	457c                	lw	a5,76(a0)
    8000286a:	00006717          	auipc	a4,0x6
    8000286e:	7c672703          	lw	a4,1990(a4) # 80009030 <ticks>
    80002872:	9fb9                	addw	a5,a5,a4
    80002874:	6d38                	ld	a4,88(a0)
    80002876:	9f99                	subw	a5,a5,a4
    80002878:	c57c                	sw	a5,76(a0)
  p->average_bursttime = (ALPHA * p->tickcounter) + (((100 - ALPHA) * p->average_bursttime) / 100);
    8000287a:	5d18                	lw	a4,56(a0)
    8000287c:	03200793          	li	a5,50
    80002880:	02e787bb          	mulw	a5,a5,a4
    80002884:	4974                	lw	a3,84(a0)
    80002886:	01f6d71b          	srliw	a4,a3,0x1f
    8000288a:	9f35                	addw	a4,a4,a3
    8000288c:	4017571b          	sraiw	a4,a4,0x1
    80002890:	9fb9                	addw	a5,a5,a4
    80002892:	c97c                	sw	a5,84(a0)
  p->tickcounter = 0;
    80002894:	02052c23          	sw	zero,56(a0)
  c->proc = p;
    80002898:	e188                	sd	a0,0(a1)
  swtch(&c->context, &p->context);
    8000289a:	09850593          	addi	a1,a0,152
    8000289e:	00848513          	addi	a0,s1,8
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	016080e7          	jalr	22(ra) # 800028b8 <swtch>

  // Process is done running for now.
  // It should have changed its p->state before coming back.
  c->proc = 0;
    800028aa:	0004b023          	sd	zero,0(s1)
}
    800028ae:	60e2                	ld	ra,24(sp)
    800028b0:	6442                	ld	s0,16(sp)
    800028b2:	64a2                	ld	s1,8(sp)
    800028b4:	6105                	addi	sp,sp,32
    800028b6:	8082                	ret

00000000800028b8 <swtch>:
    800028b8:	00153023          	sd	ra,0(a0)
    800028bc:	00253423          	sd	sp,8(a0)
    800028c0:	e900                	sd	s0,16(a0)
    800028c2:	ed04                	sd	s1,24(a0)
    800028c4:	03253023          	sd	s2,32(a0)
    800028c8:	03353423          	sd	s3,40(a0)
    800028cc:	03453823          	sd	s4,48(a0)
    800028d0:	03553c23          	sd	s5,56(a0)
    800028d4:	05653023          	sd	s6,64(a0)
    800028d8:	05753423          	sd	s7,72(a0)
    800028dc:	05853823          	sd	s8,80(a0)
    800028e0:	05953c23          	sd	s9,88(a0)
    800028e4:	07a53023          	sd	s10,96(a0)
    800028e8:	07b53423          	sd	s11,104(a0)
    800028ec:	0005b083          	ld	ra,0(a1)
    800028f0:	0085b103          	ld	sp,8(a1)
    800028f4:	6980                	ld	s0,16(a1)
    800028f6:	6d84                	ld	s1,24(a1)
    800028f8:	0205b903          	ld	s2,32(a1)
    800028fc:	0285b983          	ld	s3,40(a1)
    80002900:	0305ba03          	ld	s4,48(a1)
    80002904:	0385ba83          	ld	s5,56(a1)
    80002908:	0405bb03          	ld	s6,64(a1)
    8000290c:	0485bb83          	ld	s7,72(a1)
    80002910:	0505bc03          	ld	s8,80(a1)
    80002914:	0585bc83          	ld	s9,88(a1)
    80002918:	0605bd03          	ld	s10,96(a1)
    8000291c:	0685bd83          	ld	s11,104(a1)
    80002920:	8082                	ret

0000000080002922 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002922:	1141                	addi	sp,sp,-16
    80002924:	e406                	sd	ra,8(sp)
    80002926:	e022                	sd	s0,0(sp)
    80002928:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000292a:	00006597          	auipc	a1,0x6
    8000292e:	9ae58593          	addi	a1,a1,-1618 # 800082d8 <states.0+0x30>
    80002932:	00015517          	auipc	a0,0x15
    80002936:	59e50513          	addi	a0,a0,1438 # 80017ed0 <tickslock>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	1f8080e7          	jalr	504(ra) # 80000b32 <initlock>
}
    80002942:	60a2                	ld	ra,8(sp)
    80002944:	6402                	ld	s0,0(sp)
    80002946:	0141                	addi	sp,sp,16
    80002948:	8082                	ret

000000008000294a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000294a:	1141                	addi	sp,sp,-16
    8000294c:	e422                	sd	s0,8(sp)
    8000294e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002950:	00003797          	auipc	a5,0x3
    80002954:	64078793          	addi	a5,a5,1600 # 80005f90 <kernelvec>
    80002958:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000295c:	6422                	ld	s0,8(sp)
    8000295e:	0141                	addi	sp,sp,16
    80002960:	8082                	ret

0000000080002962 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002962:	1141                	addi	sp,sp,-16
    80002964:	e406                	sd	ra,8(sp)
    80002966:	e022                	sd	s0,0(sp)
    80002968:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	014080e7          	jalr	20(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002972:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002976:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002978:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000297c:	00004617          	auipc	a2,0x4
    80002980:	68460613          	addi	a2,a2,1668 # 80007000 <_trampoline>
    80002984:	00004697          	auipc	a3,0x4
    80002988:	67c68693          	addi	a3,a3,1660 # 80007000 <_trampoline>
    8000298c:	8e91                	sub	a3,a3,a2
    8000298e:	040007b7          	lui	a5,0x4000
    80002992:	17fd                	addi	a5,a5,-1
    80002994:	07b2                	slli	a5,a5,0xc
    80002996:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002998:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000299c:	6958                	ld	a4,144(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000299e:	180026f3          	csrr	a3,satp
    800029a2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029a4:	6958                	ld	a4,144(a0)
    800029a6:	7d34                	ld	a3,120(a0)
    800029a8:	6585                	lui	a1,0x1
    800029aa:	96ae                	add	a3,a3,a1
    800029ac:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ae:	6958                	ld	a4,144(a0)
    800029b0:	00000697          	auipc	a3,0x0
    800029b4:	13868693          	addi	a3,a3,312 # 80002ae8 <usertrap>
    800029b8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029ba:	6958                	ld	a4,144(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029bc:	8692                	mv	a3,tp
    800029be:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029c4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029c8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029cc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029d0:	6958                	ld	a4,144(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d2:	6f18                	ld	a4,24(a4)
    800029d4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029d8:	654c                	ld	a1,136(a0)
    800029da:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029dc:	00004717          	auipc	a4,0x4
    800029e0:	6b470713          	addi	a4,a4,1716 # 80007090 <userret>
    800029e4:	8f11                	sub	a4,a4,a2
    800029e6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029e8:	577d                	li	a4,-1
    800029ea:	177e                	slli	a4,a4,0x3f
    800029ec:	8dd9                	or	a1,a1,a4
    800029ee:	02000537          	lui	a0,0x2000
    800029f2:	157d                	addi	a0,a0,-1
    800029f4:	0536                	slli	a0,a0,0xd
    800029f6:	9782                	jalr	a5
}
    800029f8:	60a2                	ld	ra,8(sp)
    800029fa:	6402                	ld	s0,0(sp)
    800029fc:	0141                	addi	sp,sp,16
    800029fe:	8082                	ret

0000000080002a00 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a00:	1101                	addi	sp,sp,-32
    80002a02:	ec06                	sd	ra,24(sp)
    80002a04:	e822                	sd	s0,16(sp)
    80002a06:	e426                	sd	s1,8(sp)
    80002a08:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a0a:	00015497          	auipc	s1,0x15
    80002a0e:	4c648493          	addi	s1,s1,1222 # 80017ed0 <tickslock>
    80002a12:	8526                	mv	a0,s1
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  ticks++;
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	61450513          	addi	a0,a0,1556 # 80009030 <ticks>
    80002a24:	411c                	lw	a5,0(a0)
    80002a26:	2785                	addiw	a5,a5,1
    80002a28:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	93e080e7          	jalr	-1730(ra) # 80002368 <wakeup>
  release(&tickslock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	242080e7          	jalr	578(ra) # 80000c76 <release>
}
    80002a3c:	60e2                	ld	ra,24(sp)
    80002a3e:	6442                	ld	s0,16(sp)
    80002a40:	64a2                	ld	s1,8(sp)
    80002a42:	6105                	addi	sp,sp,32
    80002a44:	8082                	ret

0000000080002a46 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a50:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a54:	00074d63          	bltz	a4,80002a6e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a58:	57fd                	li	a5,-1
    80002a5a:	17fe                	slli	a5,a5,0x3f
    80002a5c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a5e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a60:	06f70363          	beq	a4,a5,80002ac6 <devintr+0x80>
  }
}
    80002a64:	60e2                	ld	ra,24(sp)
    80002a66:	6442                	ld	s0,16(sp)
    80002a68:	64a2                	ld	s1,8(sp)
    80002a6a:	6105                	addi	sp,sp,32
    80002a6c:	8082                	ret
     (scause & 0xff) == 9){
    80002a6e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a72:	46a5                	li	a3,9
    80002a74:	fed792e3          	bne	a5,a3,80002a58 <devintr+0x12>
    int irq = plic_claim();
    80002a78:	00003097          	auipc	ra,0x3
    80002a7c:	620080e7          	jalr	1568(ra) # 80006098 <plic_claim>
    80002a80:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a82:	47a9                	li	a5,10
    80002a84:	02f50763          	beq	a0,a5,80002ab2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a88:	4785                	li	a5,1
    80002a8a:	02f50963          	beq	a0,a5,80002abc <devintr+0x76>
    return 1;
    80002a8e:	4505                	li	a0,1
    } else if(irq){
    80002a90:	d8f1                	beqz	s1,80002a64 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a92:	85a6                	mv	a1,s1
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	84c50513          	addi	a0,a0,-1972 # 800082e0 <states.0+0x38>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	ad8080e7          	jalr	-1320(ra) # 80000574 <printf>
      plic_complete(irq);
    80002aa4:	8526                	mv	a0,s1
    80002aa6:	00003097          	auipc	ra,0x3
    80002aaa:	616080e7          	jalr	1558(ra) # 800060bc <plic_complete>
    return 1;
    80002aae:	4505                	li	a0,1
    80002ab0:	bf55                	j	80002a64 <devintr+0x1e>
      uartintr();
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ed4080e7          	jalr	-300(ra) # 80000986 <uartintr>
    80002aba:	b7ed                	j	80002aa4 <devintr+0x5e>
      virtio_disk_intr();
    80002abc:	00004097          	auipc	ra,0x4
    80002ac0:	a92080e7          	jalr	-1390(ra) # 8000654e <virtio_disk_intr>
    80002ac4:	b7c5                	j	80002aa4 <devintr+0x5e>
    if(cpuid() == 0){
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	e8c080e7          	jalr	-372(ra) # 80001952 <cpuid>
    80002ace:	c901                	beqz	a0,80002ade <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ad0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ad4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ad6:	14479073          	csrw	sip,a5
    return 2;
    80002ada:	4509                	li	a0,2
    80002adc:	b761                	j	80002a64 <devintr+0x1e>
      clockintr();
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	f22080e7          	jalr	-222(ra) # 80002a00 <clockintr>
    80002ae6:	b7ed                	j	80002ad0 <devintr+0x8a>

0000000080002ae8 <usertrap>:
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	e04a                	sd	s2,0(sp)
    80002af2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002af8:	1007f793          	andi	a5,a5,256
    80002afc:	e3ad                	bnez	a5,80002b5e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002afe:	00003797          	auipc	a5,0x3
    80002b02:	49278793          	addi	a5,a5,1170 # 80005f90 <kernelvec>
    80002b06:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	e74080e7          	jalr	-396(ra) # 8000197e <myproc>
    80002b12:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b14:	695c                	ld	a5,144(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b16:	14102773          	csrr	a4,sepc
    80002b1a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b20:	47a1                	li	a5,8
    80002b22:	04f71c63          	bne	a4,a5,80002b7a <usertrap+0x92>
    if(p->killed)
    80002b26:	551c                	lw	a5,40(a0)
    80002b28:	e3b9                	bnez	a5,80002b6e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b2a:	68d8                	ld	a4,144(s1)
    80002b2c:	6f1c                	ld	a5,24(a4)
    80002b2e:	0791                	addi	a5,a5,4
    80002b30:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b32:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b36:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b3a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b3e:	00000097          	auipc	ra,0x0
    80002b42:	2fc080e7          	jalr	764(ra) # 80002e3a <syscall>
  if(p->killed)
    80002b46:	549c                	lw	a5,40(s1)
    80002b48:	efd9                	bnez	a5,80002be6 <usertrap+0xfe>
  usertrapret();
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	e18080e7          	jalr	-488(ra) # 80002962 <usertrapret>
}
    80002b52:	60e2                	ld	ra,24(sp)
    80002b54:	6442                	ld	s0,16(sp)
    80002b56:	64a2                	ld	s1,8(sp)
    80002b58:	6902                	ld	s2,0(sp)
    80002b5a:	6105                	addi	sp,sp,32
    80002b5c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b5e:	00005517          	auipc	a0,0x5
    80002b62:	7a250513          	addi	a0,a0,1954 # 80008300 <states.0+0x58>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	9c4080e7          	jalr	-1596(ra) # 8000052a <panic>
      exit(-1);
    80002b6e:	557d                	li	a0,-1
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	8e8080e7          	jalr	-1816(ra) # 80002458 <exit>
    80002b78:	bf4d                	j	80002b2a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	ecc080e7          	jalr	-308(ra) # 80002a46 <devintr>
    80002b82:	892a                	mv	s2,a0
    80002b84:	c501                	beqz	a0,80002b8c <usertrap+0xa4>
  if(p->killed)
    80002b86:	549c                	lw	a5,40(s1)
    80002b88:	c3a1                	beqz	a5,80002bc8 <usertrap+0xe0>
    80002b8a:	a815                	j	80002bbe <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b90:	5890                	lw	a2,48(s1)
    80002b92:	00005517          	auipc	a0,0x5
    80002b96:	78e50513          	addi	a0,a0,1934 # 80008320 <states.0+0x78>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9da080e7          	jalr	-1574(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ba6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002baa:	00005517          	auipc	a0,0x5
    80002bae:	7a650513          	addi	a0,a0,1958 # 80008350 <states.0+0xa8>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	9c2080e7          	jalr	-1598(ra) # 80000574 <printf>
    p->killed = 1;
    80002bba:	4785                	li	a5,1
    80002bbc:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bbe:	557d                	li	a0,-1
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	898080e7          	jalr	-1896(ra) # 80002458 <exit>
  if(which_dev == 2){
    80002bc8:	4789                	li	a5,2
    80002bca:	f8f910e3          	bne	s2,a5,80002b4a <usertrap+0x62>
    if(inctickcounter() == QUANTUM){
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	c4a080e7          	jalr	-950(ra) # 80002818 <inctickcounter>
    80002bd6:	4795                	li	a5,5
    80002bd8:	f6f519e3          	bne	a0,a5,80002b4a <usertrap+0x62>
      yield();
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	4c2080e7          	jalr	1218(ra) # 8000209e <yield>
    80002be4:	b79d                	j	80002b4a <usertrap+0x62>
  int which_dev = 0;
    80002be6:	4901                	li	s2,0
    80002be8:	bfd9                	j	80002bbe <usertrap+0xd6>

0000000080002bea <kerneltrap>:
{
    80002bea:	7179                	addi	sp,sp,-48
    80002bec:	f406                	sd	ra,40(sp)
    80002bee:	f022                	sd	s0,32(sp)
    80002bf0:	ec26                	sd	s1,24(sp)
    80002bf2:	e84a                	sd	s2,16(sp)
    80002bf4:	e44e                	sd	s3,8(sp)
    80002bf6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c00:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c04:	1004f793          	andi	a5,s1,256
    80002c08:	cb85                	beqz	a5,80002c38 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c0e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c10:	ef85                	bnez	a5,80002c48 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	e34080e7          	jalr	-460(ra) # 80002a46 <devintr>
    80002c1a:	cd1d                	beqz	a0,80002c58 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    80002c1c:	4789                	li	a5,2
    80002c1e:	06f50a63          	beq	a0,a5,80002c92 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c22:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c26:	10049073          	csrw	sstatus,s1
}
    80002c2a:	70a2                	ld	ra,40(sp)
    80002c2c:	7402                	ld	s0,32(sp)
    80002c2e:	64e2                	ld	s1,24(sp)
    80002c30:	6942                	ld	s2,16(sp)
    80002c32:	69a2                	ld	s3,8(sp)
    80002c34:	6145                	addi	sp,sp,48
    80002c36:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c38:	00005517          	auipc	a0,0x5
    80002c3c:	73850513          	addi	a0,a0,1848 # 80008370 <states.0+0xc8>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	8ea080e7          	jalr	-1814(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002c48:	00005517          	auipc	a0,0x5
    80002c4c:	75050513          	addi	a0,a0,1872 # 80008398 <states.0+0xf0>
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	8da080e7          	jalr	-1830(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002c58:	85ce                	mv	a1,s3
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	75e50513          	addi	a0,a0,1886 # 800083b8 <states.0+0x110>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	912080e7          	jalr	-1774(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c6e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	75650513          	addi	a0,a0,1878 # 800083c8 <states.0+0x120>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	8fa080e7          	jalr	-1798(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002c82:	00005517          	auipc	a0,0x5
    80002c86:	75e50513          	addi	a0,a0,1886 # 800083e0 <states.0+0x138>
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	8a0080e7          	jalr	-1888(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	cec080e7          	jalr	-788(ra) # 8000197e <myproc>
    80002c9a:	d541                	beqz	a0,80002c22 <kerneltrap+0x38>
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	ce2080e7          	jalr	-798(ra) # 8000197e <myproc>
    80002ca4:	4d18                	lw	a4,24(a0)
    80002ca6:	4791                	li	a5,4
    80002ca8:	f6f71de3          	bne	a4,a5,80002c22 <kerneltrap+0x38>
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	b6c080e7          	jalr	-1172(ra) # 80002818 <inctickcounter>
    80002cb4:	4795                	li	a5,5
    80002cb6:	f6f516e3          	bne	a0,a5,80002c22 <kerneltrap+0x38>
    yield();
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	3e4080e7          	jalr	996(ra) # 8000209e <yield>
    80002cc2:	b785                	j	80002c22 <kerneltrap+0x38>

0000000080002cc4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc4:	1101                	addi	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	e426                	sd	s1,8(sp)
    80002ccc:	1000                	addi	s0,sp,32
    80002cce:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	cae080e7          	jalr	-850(ra) # 8000197e <myproc>
  switch (n) {
    80002cd8:	4795                	li	a5,5
    80002cda:	0497e163          	bltu	a5,s1,80002d1c <argraw+0x58>
    80002cde:	048a                	slli	s1,s1,0x2
    80002ce0:	00006717          	auipc	a4,0x6
    80002ce4:	85870713          	addi	a4,a4,-1960 # 80008538 <states.0+0x290>
    80002ce8:	94ba                	add	s1,s1,a4
    80002cea:	409c                	lw	a5,0(s1)
    80002cec:	97ba                	add	a5,a5,a4
    80002cee:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cf0:	695c                	ld	a5,144(a0)
    80002cf2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret
    return p->trapframe->a1;
    80002cfe:	695c                	ld	a5,144(a0)
    80002d00:	7fa8                	ld	a0,120(a5)
    80002d02:	bfcd                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a2;
    80002d04:	695c                	ld	a5,144(a0)
    80002d06:	63c8                	ld	a0,128(a5)
    80002d08:	b7f5                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a3;
    80002d0a:	695c                	ld	a5,144(a0)
    80002d0c:	67c8                	ld	a0,136(a5)
    80002d0e:	b7dd                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a4;
    80002d10:	695c                	ld	a5,144(a0)
    80002d12:	6bc8                	ld	a0,144(a5)
    80002d14:	b7c5                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a5;
    80002d16:	695c                	ld	a5,144(a0)
    80002d18:	6fc8                	ld	a0,152(a5)
    80002d1a:	bfe9                	j	80002cf4 <argraw+0x30>
  panic("argraw");
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	6d450513          	addi	a0,a0,1748 # 800083f0 <states.0+0x148>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	806080e7          	jalr	-2042(ra) # 8000052a <panic>

0000000080002d2c <fetchaddr>:
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	e426                	sd	s1,8(sp)
    80002d34:	e04a                	sd	s2,0(sp)
    80002d36:	1000                	addi	s0,sp,32
    80002d38:	84aa                	mv	s1,a0
    80002d3a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	c42080e7          	jalr	-958(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d44:	615c                	ld	a5,128(a0)
    80002d46:	02f4f863          	bgeu	s1,a5,80002d76 <fetchaddr+0x4a>
    80002d4a:	00848713          	addi	a4,s1,8
    80002d4e:	02e7e663          	bltu	a5,a4,80002d7a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d52:	46a1                	li	a3,8
    80002d54:	8626                	mv	a2,s1
    80002d56:	85ca                	mv	a1,s2
    80002d58:	6548                	ld	a0,136(a0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	970080e7          	jalr	-1680(ra) # 800016ca <copyin>
    80002d62:	00a03533          	snez	a0,a0
    80002d66:	40a00533          	neg	a0,a0
}
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	64a2                	ld	s1,8(sp)
    80002d70:	6902                	ld	s2,0(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret
    return -1;
    80002d76:	557d                	li	a0,-1
    80002d78:	bfcd                	j	80002d6a <fetchaddr+0x3e>
    80002d7a:	557d                	li	a0,-1
    80002d7c:	b7fd                	j	80002d6a <fetchaddr+0x3e>

0000000080002d7e <fetchstr>:
{
    80002d7e:	7179                	addi	sp,sp,-48
    80002d80:	f406                	sd	ra,40(sp)
    80002d82:	f022                	sd	s0,32(sp)
    80002d84:	ec26                	sd	s1,24(sp)
    80002d86:	e84a                	sd	s2,16(sp)
    80002d88:	e44e                	sd	s3,8(sp)
    80002d8a:	1800                	addi	s0,sp,48
    80002d8c:	892a                	mv	s2,a0
    80002d8e:	84ae                	mv	s1,a1
    80002d90:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	bec080e7          	jalr	-1044(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d9a:	86ce                	mv	a3,s3
    80002d9c:	864a                	mv	a2,s2
    80002d9e:	85a6                	mv	a1,s1
    80002da0:	6548                	ld	a0,136(a0)
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	9b6080e7          	jalr	-1610(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002daa:	00054763          	bltz	a0,80002db8 <fetchstr+0x3a>
  return strlen(buf);
    80002dae:	8526                	mv	a0,s1
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	092080e7          	jalr	146(ra) # 80000e42 <strlen>
}
    80002db8:	70a2                	ld	ra,40(sp)
    80002dba:	7402                	ld	s0,32(sp)
    80002dbc:	64e2                	ld	s1,24(sp)
    80002dbe:	6942                	ld	s2,16(sp)
    80002dc0:	69a2                	ld	s3,8(sp)
    80002dc2:	6145                	addi	sp,sp,48
    80002dc4:	8082                	ret

0000000080002dc6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	e426                	sd	s1,8(sp)
    80002dce:	1000                	addi	s0,sp,32
    80002dd0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	ef2080e7          	jalr	-270(ra) # 80002cc4 <argraw>
    80002dda:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ddc:	4501                	li	a0,0
    80002dde:	60e2                	ld	ra,24(sp)
    80002de0:	6442                	ld	s0,16(sp)
    80002de2:	64a2                	ld	s1,8(sp)
    80002de4:	6105                	addi	sp,sp,32
    80002de6:	8082                	ret

0000000080002de8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	e426                	sd	s1,8(sp)
    80002df0:	1000                	addi	s0,sp,32
    80002df2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	ed0080e7          	jalr	-304(ra) # 80002cc4 <argraw>
    80002dfc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dfe:	4501                	li	a0,0
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	64a2                	ld	s1,8(sp)
    80002e06:	6105                	addi	sp,sp,32
    80002e08:	8082                	ret

0000000080002e0a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e0a:	1101                	addi	sp,sp,-32
    80002e0c:	ec06                	sd	ra,24(sp)
    80002e0e:	e822                	sd	s0,16(sp)
    80002e10:	e426                	sd	s1,8(sp)
    80002e12:	e04a                	sd	s2,0(sp)
    80002e14:	1000                	addi	s0,sp,32
    80002e16:	84ae                	mv	s1,a1
    80002e18:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	eaa080e7          	jalr	-342(ra) # 80002cc4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e22:	864a                	mv	a2,s2
    80002e24:	85a6                	mv	a1,s1
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	f58080e7          	jalr	-168(ra) # 80002d7e <fetchstr>
}
    80002e2e:	60e2                	ld	ra,24(sp)
    80002e30:	6442                	ld	s0,16(sp)
    80002e32:	64a2                	ld	s1,8(sp)
    80002e34:	6902                	ld	s2,0(sp)
    80002e36:	6105                	addi	sp,sp,32
    80002e38:	8082                	ret

0000000080002e3a <syscall>:
 "unlink", "link", "mkdir", "close", "trace" ,"wait_stat", "set_priority"};


void
syscall(void)
{
    80002e3a:	7139                	addi	sp,sp,-64
    80002e3c:	fc06                	sd	ra,56(sp)
    80002e3e:	f822                	sd	s0,48(sp)
    80002e40:	f426                	sd	s1,40(sp)
    80002e42:	f04a                	sd	s2,32(sp)
    80002e44:	ec4e                	sd	s3,24(sp)
    80002e46:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	b36080e7          	jalr	-1226(ra) # 8000197e <myproc>
    80002e50:	892a                	mv	s2,a0
  num = p->trapframe->a7;
    80002e52:	695c                	ld	a5,144(a0)
    80002e54:	0a87a483          	lw	s1,168(a5)
  int argument = 0;
    80002e58:	fc042623          	sw	zero,-52(s0)
  if(num == SYS_fork || num == SYS_kill || num == SYS_sbrk)
    80002e5c:	47b1                	li	a5,12
    80002e5e:	0297e063          	bltu	a5,s1,80002e7e <syscall+0x44>
    80002e62:	6785                	lui	a5,0x1
    80002e64:	04278793          	addi	a5,a5,66 # 1042 <_entry-0x7fffefbe>
    80002e68:	0097d7b3          	srl	a5,a5,s1
    80002e6c:	8b85                	andi	a5,a5,1
    80002e6e:	cb81                	beqz	a5,80002e7e <syscall+0x44>
    argint(0, &argument);
    80002e70:	fcc40593          	addi	a1,s0,-52
    80002e74:	4501                	li	a0,0
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	f50080e7          	jalr	-176(ra) # 80002dc6 <argint>

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e7e:	fff4879b          	addiw	a5,s1,-1
    80002e82:	475d                	li	a4,23
    80002e84:	02f76163          	bltu	a4,a5,80002ea6 <syscall+0x6c>
    80002e88:	00349713          	slli	a4,s1,0x3
    80002e8c:	00005797          	auipc	a5,0x5
    80002e90:	6c478793          	addi	a5,a5,1732 # 80008550 <syscalls>
    80002e94:	97ba                	add	a5,a5,a4
    80002e96:	639c                	ld	a5,0(a5)
    80002e98:	c799                	beqz	a5,80002ea6 <syscall+0x6c>
    p->trapframe->a0 = syscalls[num]();
    80002e9a:	09093983          	ld	s3,144(s2)
    80002e9e:	9782                	jalr	a5
    80002ea0:	06a9b823          	sd	a0,112(s3)
    80002ea4:	a015                	j	80002ec8 <syscall+0x8e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ea6:	86a6                	mv	a3,s1
    80002ea8:	19090613          	addi	a2,s2,400
    80002eac:	03092583          	lw	a1,48(s2)
    80002eb0:	00005517          	auipc	a0,0x5
    80002eb4:	54850513          	addi	a0,a0,1352 # 800083f8 <states.0+0x150>
    80002eb8:	ffffd097          	auipc	ra,0xffffd
    80002ebc:	6bc080e7          	jalr	1724(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ec0:	09093783          	ld	a5,144(s2)
    80002ec4:	577d                	li	a4,-1
    80002ec6:	fbb8                	sd	a4,112(a5)

  int ret = p->trapframe->a0;

  /* If the system calls bit is on in the mask of the process, 
  then print the trace of the system call. */
  if(p->mask & (1 << num)){
    80002ec8:	03492783          	lw	a5,52(s2)
    80002ecc:	4097d7bb          	sraw	a5,a5,s1
    80002ed0:	8b85                	andi	a5,a5,1
    80002ed2:	c3a9                	beqz	a5,80002f14 <syscall+0xda>
  int ret = p->trapframe->a0;
    80002ed4:	09093783          	ld	a5,144(s2)
    80002ed8:	5bb4                	lw	a3,112(a5)
    if(num == SYS_fork)
    80002eda:	4785                	li	a5,1
    80002edc:	04f48363          	beq	s1,a5,80002f22 <syscall+0xe8>
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    else if(num == SYS_kill || num == SYS_sbrk)
    80002ee0:	4799                	li	a5,6
    80002ee2:	00f48563          	beq	s1,a5,80002eec <syscall+0xb2>
    80002ee6:	47b1                	li	a5,12
    80002ee8:	04f49c63          	bne	s1,a5,80002f40 <syscall+0x106>
      printf("%d: syscall %s %d -> %d\n", p->pid, sys_calls_names[num], argument, ret);
    80002eec:	048e                	slli	s1,s1,0x3
    80002eee:	00006797          	auipc	a5,0x6
    80002ef2:	a8a78793          	addi	a5,a5,-1398 # 80008978 <sys_calls_names>
    80002ef6:	94be                	add	s1,s1,a5
    80002ef8:	8736                	mv	a4,a3
    80002efa:	fcc42683          	lw	a3,-52(s0)
    80002efe:	6090                	ld	a2,0(s1)
    80002f00:	03092583          	lw	a1,48(s2)
    80002f04:	00005517          	auipc	a0,0x5
    80002f08:	53450513          	addi	a0,a0,1332 # 80008438 <states.0+0x190>
    80002f0c:	ffffd097          	auipc	ra,0xffffd
    80002f10:	668080e7          	jalr	1640(ra) # 80000574 <printf>
    else
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
  }
}
    80002f14:	70e2                	ld	ra,56(sp)
    80002f16:	7442                	ld	s0,48(sp)
    80002f18:	74a2                	ld	s1,40(sp)
    80002f1a:	7902                	ld	s2,32(sp)
    80002f1c:	69e2                	ld	s3,24(sp)
    80002f1e:	6121                	addi	sp,sp,64
    80002f20:	8082                	ret
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    80002f22:	00006617          	auipc	a2,0x6
    80002f26:	a5e63603          	ld	a2,-1442(a2) # 80008980 <sys_calls_names+0x8>
    80002f2a:	03092583          	lw	a1,48(s2)
    80002f2e:	00005517          	auipc	a0,0x5
    80002f32:	4ea50513          	addi	a0,a0,1258 # 80008418 <states.0+0x170>
    80002f36:	ffffd097          	auipc	ra,0xffffd
    80002f3a:	63e080e7          	jalr	1598(ra) # 80000574 <printf>
    80002f3e:	bfd9                	j	80002f14 <syscall+0xda>
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
    80002f40:	048e                	slli	s1,s1,0x3
    80002f42:	00006797          	auipc	a5,0x6
    80002f46:	a3678793          	addi	a5,a5,-1482 # 80008978 <sys_calls_names>
    80002f4a:	94be                	add	s1,s1,a5
    80002f4c:	6090                	ld	a2,0(s1)
    80002f4e:	03092583          	lw	a1,48(s2)
    80002f52:	00005517          	auipc	a0,0x5
    80002f56:	50650513          	addi	a0,a0,1286 # 80008458 <states.0+0x1b0>
    80002f5a:	ffffd097          	auipc	ra,0xffffd
    80002f5e:	61a080e7          	jalr	1562(ra) # 80000574 <printf>
}
    80002f62:	bf4d                	j	80002f14 <syscall+0xda>

0000000080002f64 <sys_exit>:
#include "perf.h"


uint64
sys_exit(void)
{
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f6c:	fec40593          	addi	a1,s0,-20
    80002f70:	4501                	li	a0,0
    80002f72:	00000097          	auipc	ra,0x0
    80002f76:	e54080e7          	jalr	-428(ra) # 80002dc6 <argint>
    return -1;
    80002f7a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f7c:	00054963          	bltz	a0,80002f8e <sys_exit+0x2a>
  exit(n);
    80002f80:	fec42503          	lw	a0,-20(s0)
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	4d4080e7          	jalr	1236(ra) # 80002458 <exit>
  return 0;  // not reached
    80002f8c:	4781                	li	a5,0
}
    80002f8e:	853e                	mv	a0,a5
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	6105                	addi	sp,sp,32
    80002f96:	8082                	ret

0000000080002f98 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f98:	1141                	addi	sp,sp,-16
    80002f9a:	e406                	sd	ra,8(sp)
    80002f9c:	e022                	sd	s0,0(sp)
    80002f9e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	9de080e7          	jalr	-1570(ra) # 8000197e <myproc>
}
    80002fa8:	5908                	lw	a0,48(a0)
    80002faa:	60a2                	ld	ra,8(sp)
    80002fac:	6402                	ld	s0,0(sp)
    80002fae:	0141                	addi	sp,sp,16
    80002fb0:	8082                	ret

0000000080002fb2 <sys_fork>:

uint64
sys_fork(void)
{
    80002fb2:	1141                	addi	sp,sp,-16
    80002fb4:	e406                	sd	ra,8(sp)
    80002fb6:	e022                	sd	s0,0(sp)
    80002fb8:	0800                	addi	s0,sp,16
  return fork();
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	ddc080e7          	jalr	-548(ra) # 80001d96 <fork>
}
    80002fc2:	60a2                	ld	ra,8(sp)
    80002fc4:	6402                	ld	s0,0(sp)
    80002fc6:	0141                	addi	sp,sp,16
    80002fc8:	8082                	ret

0000000080002fca <sys_wait>:

uint64
sys_wait(void)
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fd2:	fe840593          	addi	a1,s0,-24
    80002fd6:	4501                	li	a0,0
    80002fd8:	00000097          	auipc	ra,0x0
    80002fdc:	e10080e7          	jalr	-496(ra) # 80002de8 <argaddr>
    80002fe0:	87aa                	mv	a5,a0
    return -1;
    80002fe2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fe4:	0007c863          	bltz	a5,80002ff4 <sys_wait+0x2a>
  return wait(p);
    80002fe8:	fe843503          	ld	a0,-24(s0)
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	362080e7          	jalr	866(ra) # 8000234e <wait>
}
    80002ff4:	60e2                	ld	ra,24(sp)
    80002ff6:	6442                	ld	s0,16(sp)
    80002ff8:	6105                	addi	sp,sp,32
    80002ffa:	8082                	ret

0000000080002ffc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ffc:	7179                	addi	sp,sp,-48
    80002ffe:	f406                	sd	ra,40(sp)
    80003000:	f022                	sd	s0,32(sp)
    80003002:	ec26                	sd	s1,24(sp)
    80003004:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003006:	fdc40593          	addi	a1,s0,-36
    8000300a:	4501                	li	a0,0
    8000300c:	00000097          	auipc	ra,0x0
    80003010:	dba080e7          	jalr	-582(ra) # 80002dc6 <argint>
    return -1;
    80003014:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003016:	02054063          	bltz	a0,80003036 <sys_sbrk+0x3a>
  addr = myproc()->sz;
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	964080e7          	jalr	-1692(ra) # 8000197e <myproc>
    80003022:	08052483          	lw	s1,128(a0)
  if(growproc(n) < 0)
    80003026:	fdc42503          	lw	a0,-36(s0)
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	cf8080e7          	jalr	-776(ra) # 80001d22 <growproc>
    80003032:	00054863          	bltz	a0,80003042 <sys_sbrk+0x46>
    return -1;
  return addr;
}
    80003036:	8526                	mv	a0,s1
    80003038:	70a2                	ld	ra,40(sp)
    8000303a:	7402                	ld	s0,32(sp)
    8000303c:	64e2                	ld	s1,24(sp)
    8000303e:	6145                	addi	sp,sp,48
    80003040:	8082                	ret
    return -1;
    80003042:	54fd                	li	s1,-1
    80003044:	bfcd                	j	80003036 <sys_sbrk+0x3a>

0000000080003046 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003046:	7139                	addi	sp,sp,-64
    80003048:	fc06                	sd	ra,56(sp)
    8000304a:	f822                	sd	s0,48(sp)
    8000304c:	f426                	sd	s1,40(sp)
    8000304e:	f04a                	sd	s2,32(sp)
    80003050:	ec4e                	sd	s3,24(sp)
    80003052:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003054:	fcc40593          	addi	a1,s0,-52
    80003058:	4501                	li	a0,0
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	d6c080e7          	jalr	-660(ra) # 80002dc6 <argint>
    return -1;
    80003062:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003064:	06054563          	bltz	a0,800030ce <sys_sleep+0x88>
  acquire(&tickslock);
    80003068:	00015517          	auipc	a0,0x15
    8000306c:	e6850513          	addi	a0,a0,-408 # 80017ed0 <tickslock>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	b52080e7          	jalr	-1198(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003078:	00006917          	auipc	s2,0x6
    8000307c:	fb892903          	lw	s2,-72(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003080:	fcc42783          	lw	a5,-52(s0)
    80003084:	cf85                	beqz	a5,800030bc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003086:	00015997          	auipc	s3,0x15
    8000308a:	e4a98993          	addi	s3,s3,-438 # 80017ed0 <tickslock>
    8000308e:	00006497          	auipc	s1,0x6
    80003092:	fa248493          	addi	s1,s1,-94 # 80009030 <ticks>
    if(myproc()->killed){
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	8e8080e7          	jalr	-1816(ra) # 8000197e <myproc>
    8000309e:	551c                	lw	a5,40(a0)
    800030a0:	ef9d                	bnez	a5,800030de <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800030a2:	85ce                	mv	a1,s3
    800030a4:	8526                	mv	a0,s1
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	04e080e7          	jalr	78(ra) # 800020f4 <sleep>
  while(ticks - ticks0 < n){
    800030ae:	409c                	lw	a5,0(s1)
    800030b0:	412787bb          	subw	a5,a5,s2
    800030b4:	fcc42703          	lw	a4,-52(s0)
    800030b8:	fce7efe3          	bltu	a5,a4,80003096 <sys_sleep+0x50>
  }
  release(&tickslock);
    800030bc:	00015517          	auipc	a0,0x15
    800030c0:	e1450513          	addi	a0,a0,-492 # 80017ed0 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bb2080e7          	jalr	-1102(ra) # 80000c76 <release>
  return 0;
    800030cc:	4781                	li	a5,0
}
    800030ce:	853e                	mv	a0,a5
    800030d0:	70e2                	ld	ra,56(sp)
    800030d2:	7442                	ld	s0,48(sp)
    800030d4:	74a2                	ld	s1,40(sp)
    800030d6:	7902                	ld	s2,32(sp)
    800030d8:	69e2                	ld	s3,24(sp)
    800030da:	6121                	addi	sp,sp,64
    800030dc:	8082                	ret
      release(&tickslock);
    800030de:	00015517          	auipc	a0,0x15
    800030e2:	df250513          	addi	a0,a0,-526 # 80017ed0 <tickslock>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	b90080e7          	jalr	-1136(ra) # 80000c76 <release>
      return -1;
    800030ee:	57fd                	li	a5,-1
    800030f0:	bff9                	j	800030ce <sys_sleep+0x88>

00000000800030f2 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800030f2:	1101                	addi	sp,sp,-32
    800030f4:	ec06                	sd	ra,24(sp)
    800030f6:	e822                	sd	s0,16(sp)
    800030f8:	1000                	addi	s0,sp,32
  int prio;

  if(argint(0, &prio) < 0)
    800030fa:	fec40593          	addi	a1,s0,-20
    800030fe:	4501                	li	a0,0
    80003100:	00000097          	auipc	ra,0x0
    80003104:	cc6080e7          	jalr	-826(ra) # 80002dc6 <argint>
    80003108:	87aa                	mv	a5,a0
    return -1;
    8000310a:	557d                	li	a0,-1
  if(argint(0, &prio) < 0)
    8000310c:	0007c863          	bltz	a5,8000311c <sys_set_priority+0x2a>
  return set_priority(prio);
    80003110:	fec42503          	lw	a0,-20(s0)
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	44c080e7          	jalr	1100(ra) # 80002560 <set_priority>
}
    8000311c:	60e2                	ld	ra,24(sp)
    8000311e:	6442                	ld	s0,16(sp)
    80003120:	6105                	addi	sp,sp,32
    80003122:	8082                	ret

0000000080003124 <sys_trace>:


uint64
sys_trace(void)
{
    80003124:	1101                	addi	sp,sp,-32
    80003126:	ec06                	sd	ra,24(sp)
    80003128:	e822                	sd	s0,16(sp)
    8000312a:	1000                	addi	s0,sp,32
  int mask;
  int pid;

  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    8000312c:	fec40593          	addi	a1,s0,-20
    80003130:	4501                	li	a0,0
    80003132:	00000097          	auipc	ra,0x0
    80003136:	c94080e7          	jalr	-876(ra) # 80002dc6 <argint>
    return -1;
    8000313a:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    8000313c:	02054563          	bltz	a0,80003166 <sys_trace+0x42>
    80003140:	fe840593          	addi	a1,s0,-24
    80003144:	4505                	li	a0,1
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	c80080e7          	jalr	-896(ra) # 80002dc6 <argint>
    return -1;
    8000314e:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80003150:	00054b63          	bltz	a0,80003166 <sys_trace+0x42>
  return trace(mask, pid);
    80003154:	fe842583          	lw	a1,-24(s0)
    80003158:	fec42503          	lw	a0,-20(s0)
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	45c080e7          	jalr	1116(ra) # 800025b8 <trace>
    80003164:	87aa                	mv	a5,a0
}
    80003166:	853e                	mv	a0,a5
    80003168:	60e2                	ld	ra,24(sp)
    8000316a:	6442                	ld	s0,16(sp)
    8000316c:	6105                	addi	sp,sp,32
    8000316e:	8082                	ret

0000000080003170 <sys_kill>:


uint64
sys_kill(void)
{
    80003170:	1101                	addi	sp,sp,-32
    80003172:	ec06                	sd	ra,24(sp)
    80003174:	e822                	sd	s0,16(sp)
    80003176:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003178:	fec40593          	addi	a1,s0,-20
    8000317c:	4501                	li	a0,0
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	c48080e7          	jalr	-952(ra) # 80002dc6 <argint>
    80003186:	87aa                	mv	a5,a0
    return -1;
    80003188:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000318a:	0007c863          	bltz	a5,8000319a <sys_kill+0x2a>
  return kill(pid);
    8000318e:	fec42503          	lw	a0,-20(s0)
    80003192:	fffff097          	auipc	ra,0xfffff
    80003196:	486080e7          	jalr	1158(ra) # 80002618 <kill>
}
    8000319a:	60e2                	ld	ra,24(sp)
    8000319c:	6442                	ld	s0,16(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret

00000000800031a2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	e426                	sd	s1,8(sp)
    800031aa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031ac:	00015517          	auipc	a0,0x15
    800031b0:	d2450513          	addi	a0,a0,-732 # 80017ed0 <tickslock>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	a0e080e7          	jalr	-1522(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800031bc:	00006497          	auipc	s1,0x6
    800031c0:	e744a483          	lw	s1,-396(s1) # 80009030 <ticks>
  release(&tickslock);
    800031c4:	00015517          	auipc	a0,0x15
    800031c8:	d0c50513          	addi	a0,a0,-756 # 80017ed0 <tickslock>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	aaa080e7          	jalr	-1366(ra) # 80000c76 <release>
  return xticks;
}
    800031d4:	02049513          	slli	a0,s1,0x20
    800031d8:	9101                	srli	a0,a0,0x20
    800031da:	60e2                	ld	ra,24(sp)
    800031dc:	6442                	ld	s0,16(sp)
    800031de:	64a2                	ld	s1,8(sp)
    800031e0:	6105                	addi	sp,sp,32
    800031e2:	8082                	ret

00000000800031e4 <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    800031e4:	7179                	addi	sp,sp,-48
    800031e6:	f406                	sd	ra,40(sp)
    800031e8:	f022                	sd	s0,32(sp)
    800031ea:	ec26                	sd	s1,24(sp)
    800031ec:	1800                	addi	s0,sp,48
  int status;
  struct perf* tmp = (struct perf*) myproc()->trapframe->a1;
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	790080e7          	jalr	1936(ra) # 8000197e <myproc>
    800031f6:	695c                	ld	a5,144(a0)
    800031f8:	7fa4                	ld	s1,120(a5)
  if(argint(0, &status) < 0)
    800031fa:	fdc40593          	addi	a1,s0,-36
    800031fe:	4501                	li	a0,0
    80003200:	00000097          	auipc	ra,0x0
    80003204:	bc6080e7          	jalr	-1082(ra) # 80002dc6 <argint>
    80003208:	87aa                	mv	a5,a0
    return -1;
    8000320a:	557d                	li	a0,-1
  if(argint(0, &status) < 0)
    8000320c:	0007c963          	bltz	a5,8000321e <sys_wait_stat+0x3a>
 
  int x = wait_stat(&status, tmp);
    80003210:	85a6                	mv	a1,s1
    80003212:	fdc40513          	addi	a0,s0,-36
    80003216:	fffff097          	auipc	ra,0xfffff
    8000321a:	5e8080e7          	jalr	1512(ra) # 800027fe <wait_stat>

  return x;
}
    8000321e:	70a2                	ld	ra,40(sp)
    80003220:	7402                	ld	s0,32(sp)
    80003222:	64e2                	ld	s1,24(sp)
    80003224:	6145                	addi	sp,sp,48
    80003226:	8082                	ret

0000000080003228 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003228:	7179                	addi	sp,sp,-48
    8000322a:	f406                	sd	ra,40(sp)
    8000322c:	f022                	sd	s0,32(sp)
    8000322e:	ec26                	sd	s1,24(sp)
    80003230:	e84a                	sd	s2,16(sp)
    80003232:	e44e                	sd	s3,8(sp)
    80003234:	e052                	sd	s4,0(sp)
    80003236:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003238:	00005597          	auipc	a1,0x5
    8000323c:	3e058593          	addi	a1,a1,992 # 80008618 <syscalls+0xc8>
    80003240:	00015517          	auipc	a0,0x15
    80003244:	ca850513          	addi	a0,a0,-856 # 80017ee8 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	8ea080e7          	jalr	-1814(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003250:	0001d797          	auipc	a5,0x1d
    80003254:	c9878793          	addi	a5,a5,-872 # 8001fee8 <bcache+0x8000>
    80003258:	0001d717          	auipc	a4,0x1d
    8000325c:	ef870713          	addi	a4,a4,-264 # 80020150 <bcache+0x8268>
    80003260:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003264:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003268:	00015497          	auipc	s1,0x15
    8000326c:	c9848493          	addi	s1,s1,-872 # 80017f00 <bcache+0x18>
    b->next = bcache.head.next;
    80003270:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003272:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003274:	00005a17          	auipc	s4,0x5
    80003278:	3aca0a13          	addi	s4,s4,940 # 80008620 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000327c:	2b893783          	ld	a5,696(s2)
    80003280:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003282:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003286:	85d2                	mv	a1,s4
    80003288:	01048513          	addi	a0,s1,16
    8000328c:	00001097          	auipc	ra,0x1
    80003290:	4c2080e7          	jalr	1218(ra) # 8000474e <initsleeplock>
    bcache.head.next->prev = b;
    80003294:	2b893783          	ld	a5,696(s2)
    80003298:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000329a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000329e:	45848493          	addi	s1,s1,1112
    800032a2:	fd349de3          	bne	s1,s3,8000327c <binit+0x54>
  }
}
    800032a6:	70a2                	ld	ra,40(sp)
    800032a8:	7402                	ld	s0,32(sp)
    800032aa:	64e2                	ld	s1,24(sp)
    800032ac:	6942                	ld	s2,16(sp)
    800032ae:	69a2                	ld	s3,8(sp)
    800032b0:	6a02                	ld	s4,0(sp)
    800032b2:	6145                	addi	sp,sp,48
    800032b4:	8082                	ret

00000000800032b6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032b6:	7179                	addi	sp,sp,-48
    800032b8:	f406                	sd	ra,40(sp)
    800032ba:	f022                	sd	s0,32(sp)
    800032bc:	ec26                	sd	s1,24(sp)
    800032be:	e84a                	sd	s2,16(sp)
    800032c0:	e44e                	sd	s3,8(sp)
    800032c2:	1800                	addi	s0,sp,48
    800032c4:	892a                	mv	s2,a0
    800032c6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032c8:	00015517          	auipc	a0,0x15
    800032cc:	c2050513          	addi	a0,a0,-992 # 80017ee8 <bcache>
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	8f2080e7          	jalr	-1806(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032d8:	0001d497          	auipc	s1,0x1d
    800032dc:	ec84b483          	ld	s1,-312(s1) # 800201a0 <bcache+0x82b8>
    800032e0:	0001d797          	auipc	a5,0x1d
    800032e4:	e7078793          	addi	a5,a5,-400 # 80020150 <bcache+0x8268>
    800032e8:	02f48f63          	beq	s1,a5,80003326 <bread+0x70>
    800032ec:	873e                	mv	a4,a5
    800032ee:	a021                	j	800032f6 <bread+0x40>
    800032f0:	68a4                	ld	s1,80(s1)
    800032f2:	02e48a63          	beq	s1,a4,80003326 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032f6:	449c                	lw	a5,8(s1)
    800032f8:	ff279ce3          	bne	a5,s2,800032f0 <bread+0x3a>
    800032fc:	44dc                	lw	a5,12(s1)
    800032fe:	ff3799e3          	bne	a5,s3,800032f0 <bread+0x3a>
      b->refcnt++;
    80003302:	40bc                	lw	a5,64(s1)
    80003304:	2785                	addiw	a5,a5,1
    80003306:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003308:	00015517          	auipc	a0,0x15
    8000330c:	be050513          	addi	a0,a0,-1056 # 80017ee8 <bcache>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	966080e7          	jalr	-1690(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003318:	01048513          	addi	a0,s1,16
    8000331c:	00001097          	auipc	ra,0x1
    80003320:	46c080e7          	jalr	1132(ra) # 80004788 <acquiresleep>
      return b;
    80003324:	a8b9                	j	80003382 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003326:	0001d497          	auipc	s1,0x1d
    8000332a:	e724b483          	ld	s1,-398(s1) # 80020198 <bcache+0x82b0>
    8000332e:	0001d797          	auipc	a5,0x1d
    80003332:	e2278793          	addi	a5,a5,-478 # 80020150 <bcache+0x8268>
    80003336:	00f48863          	beq	s1,a5,80003346 <bread+0x90>
    8000333a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000333c:	40bc                	lw	a5,64(s1)
    8000333e:	cf81                	beqz	a5,80003356 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003340:	64a4                	ld	s1,72(s1)
    80003342:	fee49de3          	bne	s1,a4,8000333c <bread+0x86>
  panic("bget: no buffers");
    80003346:	00005517          	auipc	a0,0x5
    8000334a:	2e250513          	addi	a0,a0,738 # 80008628 <syscalls+0xd8>
    8000334e:	ffffd097          	auipc	ra,0xffffd
    80003352:	1dc080e7          	jalr	476(ra) # 8000052a <panic>
      b->dev = dev;
    80003356:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000335a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000335e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003362:	4785                	li	a5,1
    80003364:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003366:	00015517          	auipc	a0,0x15
    8000336a:	b8250513          	addi	a0,a0,-1150 # 80017ee8 <bcache>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	908080e7          	jalr	-1784(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003376:	01048513          	addi	a0,s1,16
    8000337a:	00001097          	auipc	ra,0x1
    8000337e:	40e080e7          	jalr	1038(ra) # 80004788 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003382:	409c                	lw	a5,0(s1)
    80003384:	cb89                	beqz	a5,80003396 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003386:	8526                	mv	a0,s1
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6145                	addi	sp,sp,48
    80003394:	8082                	ret
    virtio_disk_rw(b, 0);
    80003396:	4581                	li	a1,0
    80003398:	8526                	mv	a0,s1
    8000339a:	00003097          	auipc	ra,0x3
    8000339e:	f2c080e7          	jalr	-212(ra) # 800062c6 <virtio_disk_rw>
    b->valid = 1;
    800033a2:	4785                	li	a5,1
    800033a4:	c09c                	sw	a5,0(s1)
  return b;
    800033a6:	b7c5                	j	80003386 <bread+0xd0>

00000000800033a8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033a8:	1101                	addi	sp,sp,-32
    800033aa:	ec06                	sd	ra,24(sp)
    800033ac:	e822                	sd	s0,16(sp)
    800033ae:	e426                	sd	s1,8(sp)
    800033b0:	1000                	addi	s0,sp,32
    800033b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033b4:	0541                	addi	a0,a0,16
    800033b6:	00001097          	auipc	ra,0x1
    800033ba:	46c080e7          	jalr	1132(ra) # 80004822 <holdingsleep>
    800033be:	cd01                	beqz	a0,800033d6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033c0:	4585                	li	a1,1
    800033c2:	8526                	mv	a0,s1
    800033c4:	00003097          	auipc	ra,0x3
    800033c8:	f02080e7          	jalr	-254(ra) # 800062c6 <virtio_disk_rw>
}
    800033cc:	60e2                	ld	ra,24(sp)
    800033ce:	6442                	ld	s0,16(sp)
    800033d0:	64a2                	ld	s1,8(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret
    panic("bwrite");
    800033d6:	00005517          	auipc	a0,0x5
    800033da:	26a50513          	addi	a0,a0,618 # 80008640 <syscalls+0xf0>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	14c080e7          	jalr	332(ra) # 8000052a <panic>

00000000800033e6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033e6:	1101                	addi	sp,sp,-32
    800033e8:	ec06                	sd	ra,24(sp)
    800033ea:	e822                	sd	s0,16(sp)
    800033ec:	e426                	sd	s1,8(sp)
    800033ee:	e04a                	sd	s2,0(sp)
    800033f0:	1000                	addi	s0,sp,32
    800033f2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033f4:	01050913          	addi	s2,a0,16
    800033f8:	854a                	mv	a0,s2
    800033fa:	00001097          	auipc	ra,0x1
    800033fe:	428080e7          	jalr	1064(ra) # 80004822 <holdingsleep>
    80003402:	c92d                	beqz	a0,80003474 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003404:	854a                	mv	a0,s2
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	3d8080e7          	jalr	984(ra) # 800047de <releasesleep>

  acquire(&bcache.lock);
    8000340e:	00015517          	auipc	a0,0x15
    80003412:	ada50513          	addi	a0,a0,-1318 # 80017ee8 <bcache>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	7ac080e7          	jalr	1964(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000341e:	40bc                	lw	a5,64(s1)
    80003420:	37fd                	addiw	a5,a5,-1
    80003422:	0007871b          	sext.w	a4,a5
    80003426:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003428:	eb05                	bnez	a4,80003458 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000342a:	68bc                	ld	a5,80(s1)
    8000342c:	64b8                	ld	a4,72(s1)
    8000342e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003430:	64bc                	ld	a5,72(s1)
    80003432:	68b8                	ld	a4,80(s1)
    80003434:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003436:	0001d797          	auipc	a5,0x1d
    8000343a:	ab278793          	addi	a5,a5,-1358 # 8001fee8 <bcache+0x8000>
    8000343e:	2b87b703          	ld	a4,696(a5)
    80003442:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003444:	0001d717          	auipc	a4,0x1d
    80003448:	d0c70713          	addi	a4,a4,-756 # 80020150 <bcache+0x8268>
    8000344c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000344e:	2b87b703          	ld	a4,696(a5)
    80003452:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003454:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003458:	00015517          	auipc	a0,0x15
    8000345c:	a9050513          	addi	a0,a0,-1392 # 80017ee8 <bcache>
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	816080e7          	jalr	-2026(ra) # 80000c76 <release>
}
    80003468:	60e2                	ld	ra,24(sp)
    8000346a:	6442                	ld	s0,16(sp)
    8000346c:	64a2                	ld	s1,8(sp)
    8000346e:	6902                	ld	s2,0(sp)
    80003470:	6105                	addi	sp,sp,32
    80003472:	8082                	ret
    panic("brelse");
    80003474:	00005517          	auipc	a0,0x5
    80003478:	1d450513          	addi	a0,a0,468 # 80008648 <syscalls+0xf8>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	0ae080e7          	jalr	174(ra) # 8000052a <panic>

0000000080003484 <bpin>:

void
bpin(struct buf *b) {
    80003484:	1101                	addi	sp,sp,-32
    80003486:	ec06                	sd	ra,24(sp)
    80003488:	e822                	sd	s0,16(sp)
    8000348a:	e426                	sd	s1,8(sp)
    8000348c:	1000                	addi	s0,sp,32
    8000348e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003490:	00015517          	auipc	a0,0x15
    80003494:	a5850513          	addi	a0,a0,-1448 # 80017ee8 <bcache>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	72a080e7          	jalr	1834(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800034a0:	40bc                	lw	a5,64(s1)
    800034a2:	2785                	addiw	a5,a5,1
    800034a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034a6:	00015517          	auipc	a0,0x15
    800034aa:	a4250513          	addi	a0,a0,-1470 # 80017ee8 <bcache>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	7c8080e7          	jalr	1992(ra) # 80000c76 <release>
}
    800034b6:	60e2                	ld	ra,24(sp)
    800034b8:	6442                	ld	s0,16(sp)
    800034ba:	64a2                	ld	s1,8(sp)
    800034bc:	6105                	addi	sp,sp,32
    800034be:	8082                	ret

00000000800034c0 <bunpin>:

void
bunpin(struct buf *b) {
    800034c0:	1101                	addi	sp,sp,-32
    800034c2:	ec06                	sd	ra,24(sp)
    800034c4:	e822                	sd	s0,16(sp)
    800034c6:	e426                	sd	s1,8(sp)
    800034c8:	1000                	addi	s0,sp,32
    800034ca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034cc:	00015517          	auipc	a0,0x15
    800034d0:	a1c50513          	addi	a0,a0,-1508 # 80017ee8 <bcache>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	6ee080e7          	jalr	1774(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800034dc:	40bc                	lw	a5,64(s1)
    800034de:	37fd                	addiw	a5,a5,-1
    800034e0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034e2:	00015517          	auipc	a0,0x15
    800034e6:	a0650513          	addi	a0,a0,-1530 # 80017ee8 <bcache>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	78c080e7          	jalr	1932(ra) # 80000c76 <release>
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret

00000000800034fc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034fc:	1101                	addi	sp,sp,-32
    800034fe:	ec06                	sd	ra,24(sp)
    80003500:	e822                	sd	s0,16(sp)
    80003502:	e426                	sd	s1,8(sp)
    80003504:	e04a                	sd	s2,0(sp)
    80003506:	1000                	addi	s0,sp,32
    80003508:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000350a:	00d5d59b          	srliw	a1,a1,0xd
    8000350e:	0001d797          	auipc	a5,0x1d
    80003512:	0b67a783          	lw	a5,182(a5) # 800205c4 <sb+0x1c>
    80003516:	9dbd                	addw	a1,a1,a5
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	d9e080e7          	jalr	-610(ra) # 800032b6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003520:	0074f713          	andi	a4,s1,7
    80003524:	4785                	li	a5,1
    80003526:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000352a:	14ce                	slli	s1,s1,0x33
    8000352c:	90d9                	srli	s1,s1,0x36
    8000352e:	00950733          	add	a4,a0,s1
    80003532:	05874703          	lbu	a4,88(a4)
    80003536:	00e7f6b3          	and	a3,a5,a4
    8000353a:	c69d                	beqz	a3,80003568 <bfree+0x6c>
    8000353c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000353e:	94aa                	add	s1,s1,a0
    80003540:	fff7c793          	not	a5,a5
    80003544:	8ff9                	and	a5,a5,a4
    80003546:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	11e080e7          	jalr	286(ra) # 80004668 <log_write>
  brelse(bp);
    80003552:	854a                	mv	a0,s2
    80003554:	00000097          	auipc	ra,0x0
    80003558:	e92080e7          	jalr	-366(ra) # 800033e6 <brelse>
}
    8000355c:	60e2                	ld	ra,24(sp)
    8000355e:	6442                	ld	s0,16(sp)
    80003560:	64a2                	ld	s1,8(sp)
    80003562:	6902                	ld	s2,0(sp)
    80003564:	6105                	addi	sp,sp,32
    80003566:	8082                	ret
    panic("freeing free block");
    80003568:	00005517          	auipc	a0,0x5
    8000356c:	0e850513          	addi	a0,a0,232 # 80008650 <syscalls+0x100>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	fba080e7          	jalr	-70(ra) # 8000052a <panic>

0000000080003578 <balloc>:
{
    80003578:	711d                	addi	sp,sp,-96
    8000357a:	ec86                	sd	ra,88(sp)
    8000357c:	e8a2                	sd	s0,80(sp)
    8000357e:	e4a6                	sd	s1,72(sp)
    80003580:	e0ca                	sd	s2,64(sp)
    80003582:	fc4e                	sd	s3,56(sp)
    80003584:	f852                	sd	s4,48(sp)
    80003586:	f456                	sd	s5,40(sp)
    80003588:	f05a                	sd	s6,32(sp)
    8000358a:	ec5e                	sd	s7,24(sp)
    8000358c:	e862                	sd	s8,16(sp)
    8000358e:	e466                	sd	s9,8(sp)
    80003590:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003592:	0001d797          	auipc	a5,0x1d
    80003596:	01a7a783          	lw	a5,26(a5) # 800205ac <sb+0x4>
    8000359a:	cbd1                	beqz	a5,8000362e <balloc+0xb6>
    8000359c:	8baa                	mv	s7,a0
    8000359e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035a0:	0001db17          	auipc	s6,0x1d
    800035a4:	008b0b13          	addi	s6,s6,8 # 800205a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035a8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035aa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ac:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035ae:	6c89                	lui	s9,0x2
    800035b0:	a831                	j	800035cc <balloc+0x54>
    brelse(bp);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	e32080e7          	jalr	-462(ra) # 800033e6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035bc:	015c87bb          	addw	a5,s9,s5
    800035c0:	00078a9b          	sext.w	s5,a5
    800035c4:	004b2703          	lw	a4,4(s6)
    800035c8:	06eaf363          	bgeu	s5,a4,8000362e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800035cc:	41fad79b          	sraiw	a5,s5,0x1f
    800035d0:	0137d79b          	srliw	a5,a5,0x13
    800035d4:	015787bb          	addw	a5,a5,s5
    800035d8:	40d7d79b          	sraiw	a5,a5,0xd
    800035dc:	01cb2583          	lw	a1,28(s6)
    800035e0:	9dbd                	addw	a1,a1,a5
    800035e2:	855e                	mv	a0,s7
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	cd2080e7          	jalr	-814(ra) # 800032b6 <bread>
    800035ec:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ee:	004b2503          	lw	a0,4(s6)
    800035f2:	000a849b          	sext.w	s1,s5
    800035f6:	8662                	mv	a2,s8
    800035f8:	faa4fde3          	bgeu	s1,a0,800035b2 <balloc+0x3a>
      m = 1 << (bi % 8);
    800035fc:	41f6579b          	sraiw	a5,a2,0x1f
    80003600:	01d7d69b          	srliw	a3,a5,0x1d
    80003604:	00c6873b          	addw	a4,a3,a2
    80003608:	00777793          	andi	a5,a4,7
    8000360c:	9f95                	subw	a5,a5,a3
    8000360e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003612:	4037571b          	sraiw	a4,a4,0x3
    80003616:	00e906b3          	add	a3,s2,a4
    8000361a:	0586c683          	lbu	a3,88(a3)
    8000361e:	00d7f5b3          	and	a1,a5,a3
    80003622:	cd91                	beqz	a1,8000363e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003624:	2605                	addiw	a2,a2,1
    80003626:	2485                	addiw	s1,s1,1
    80003628:	fd4618e3          	bne	a2,s4,800035f8 <balloc+0x80>
    8000362c:	b759                	j	800035b2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	03a50513          	addi	a0,a0,58 # 80008668 <syscalls+0x118>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000363e:	974a                	add	a4,a4,s2
    80003640:	8fd5                	or	a5,a5,a3
    80003642:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003646:	854a                	mv	a0,s2
    80003648:	00001097          	auipc	ra,0x1
    8000364c:	020080e7          	jalr	32(ra) # 80004668 <log_write>
        brelse(bp);
    80003650:	854a                	mv	a0,s2
    80003652:	00000097          	auipc	ra,0x0
    80003656:	d94080e7          	jalr	-620(ra) # 800033e6 <brelse>
  bp = bread(dev, bno);
    8000365a:	85a6                	mv	a1,s1
    8000365c:	855e                	mv	a0,s7
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	c58080e7          	jalr	-936(ra) # 800032b6 <bread>
    80003666:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003668:	40000613          	li	a2,1024
    8000366c:	4581                	li	a1,0
    8000366e:	05850513          	addi	a0,a0,88
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	64c080e7          	jalr	1612(ra) # 80000cbe <memset>
  log_write(bp);
    8000367a:	854a                	mv	a0,s2
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	fec080e7          	jalr	-20(ra) # 80004668 <log_write>
  brelse(bp);
    80003684:	854a                	mv	a0,s2
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	d60080e7          	jalr	-672(ra) # 800033e6 <brelse>
}
    8000368e:	8526                	mv	a0,s1
    80003690:	60e6                	ld	ra,88(sp)
    80003692:	6446                	ld	s0,80(sp)
    80003694:	64a6                	ld	s1,72(sp)
    80003696:	6906                	ld	s2,64(sp)
    80003698:	79e2                	ld	s3,56(sp)
    8000369a:	7a42                	ld	s4,48(sp)
    8000369c:	7aa2                	ld	s5,40(sp)
    8000369e:	7b02                	ld	s6,32(sp)
    800036a0:	6be2                	ld	s7,24(sp)
    800036a2:	6c42                	ld	s8,16(sp)
    800036a4:	6ca2                	ld	s9,8(sp)
    800036a6:	6125                	addi	sp,sp,96
    800036a8:	8082                	ret

00000000800036aa <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036aa:	7179                	addi	sp,sp,-48
    800036ac:	f406                	sd	ra,40(sp)
    800036ae:	f022                	sd	s0,32(sp)
    800036b0:	ec26                	sd	s1,24(sp)
    800036b2:	e84a                	sd	s2,16(sp)
    800036b4:	e44e                	sd	s3,8(sp)
    800036b6:	e052                	sd	s4,0(sp)
    800036b8:	1800                	addi	s0,sp,48
    800036ba:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036bc:	47ad                	li	a5,11
    800036be:	04b7fe63          	bgeu	a5,a1,8000371a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036c2:	ff45849b          	addiw	s1,a1,-12
    800036c6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036ca:	0ff00793          	li	a5,255
    800036ce:	0ae7e463          	bltu	a5,a4,80003776 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036d2:	08052583          	lw	a1,128(a0)
    800036d6:	c5b5                	beqz	a1,80003742 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800036d8:	00092503          	lw	a0,0(s2)
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	bda080e7          	jalr	-1062(ra) # 800032b6 <bread>
    800036e4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036e6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036ea:	02049713          	slli	a4,s1,0x20
    800036ee:	01e75593          	srli	a1,a4,0x1e
    800036f2:	00b784b3          	add	s1,a5,a1
    800036f6:	0004a983          	lw	s3,0(s1)
    800036fa:	04098e63          	beqz	s3,80003756 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800036fe:	8552                	mv	a0,s4
    80003700:	00000097          	auipc	ra,0x0
    80003704:	ce6080e7          	jalr	-794(ra) # 800033e6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003708:	854e                	mv	a0,s3
    8000370a:	70a2                	ld	ra,40(sp)
    8000370c:	7402                	ld	s0,32(sp)
    8000370e:	64e2                	ld	s1,24(sp)
    80003710:	6942                	ld	s2,16(sp)
    80003712:	69a2                	ld	s3,8(sp)
    80003714:	6a02                	ld	s4,0(sp)
    80003716:	6145                	addi	sp,sp,48
    80003718:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000371a:	02059793          	slli	a5,a1,0x20
    8000371e:	01e7d593          	srli	a1,a5,0x1e
    80003722:	00b504b3          	add	s1,a0,a1
    80003726:	0504a983          	lw	s3,80(s1)
    8000372a:	fc099fe3          	bnez	s3,80003708 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000372e:	4108                	lw	a0,0(a0)
    80003730:	00000097          	auipc	ra,0x0
    80003734:	e48080e7          	jalr	-440(ra) # 80003578 <balloc>
    80003738:	0005099b          	sext.w	s3,a0
    8000373c:	0534a823          	sw	s3,80(s1)
    80003740:	b7e1                	j	80003708 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003742:	4108                	lw	a0,0(a0)
    80003744:	00000097          	auipc	ra,0x0
    80003748:	e34080e7          	jalr	-460(ra) # 80003578 <balloc>
    8000374c:	0005059b          	sext.w	a1,a0
    80003750:	08b92023          	sw	a1,128(s2)
    80003754:	b751                	j	800036d8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003756:	00092503          	lw	a0,0(s2)
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	e1e080e7          	jalr	-482(ra) # 80003578 <balloc>
    80003762:	0005099b          	sext.w	s3,a0
    80003766:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000376a:	8552                	mv	a0,s4
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	efc080e7          	jalr	-260(ra) # 80004668 <log_write>
    80003774:	b769                	j	800036fe <bmap+0x54>
  panic("bmap: out of range");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	f0a50513          	addi	a0,a0,-246 # 80008680 <syscalls+0x130>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dac080e7          	jalr	-596(ra) # 8000052a <panic>

0000000080003786 <iget>:
{
    80003786:	7179                	addi	sp,sp,-48
    80003788:	f406                	sd	ra,40(sp)
    8000378a:	f022                	sd	s0,32(sp)
    8000378c:	ec26                	sd	s1,24(sp)
    8000378e:	e84a                	sd	s2,16(sp)
    80003790:	e44e                	sd	s3,8(sp)
    80003792:	e052                	sd	s4,0(sp)
    80003794:	1800                	addi	s0,sp,48
    80003796:	89aa                	mv	s3,a0
    80003798:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000379a:	0001d517          	auipc	a0,0x1d
    8000379e:	e2e50513          	addi	a0,a0,-466 # 800205c8 <itable>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	420080e7          	jalr	1056(ra) # 80000bc2 <acquire>
  empty = 0;
    800037aa:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037ac:	0001d497          	auipc	s1,0x1d
    800037b0:	e3448493          	addi	s1,s1,-460 # 800205e0 <itable+0x18>
    800037b4:	0001f697          	auipc	a3,0x1f
    800037b8:	8bc68693          	addi	a3,a3,-1860 # 80022070 <log>
    800037bc:	a039                	j	800037ca <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037be:	02090b63          	beqz	s2,800037f4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037c2:	08848493          	addi	s1,s1,136
    800037c6:	02d48a63          	beq	s1,a3,800037fa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037ca:	449c                	lw	a5,8(s1)
    800037cc:	fef059e3          	blez	a5,800037be <iget+0x38>
    800037d0:	4098                	lw	a4,0(s1)
    800037d2:	ff3716e3          	bne	a4,s3,800037be <iget+0x38>
    800037d6:	40d8                	lw	a4,4(s1)
    800037d8:	ff4713e3          	bne	a4,s4,800037be <iget+0x38>
      ip->ref++;
    800037dc:	2785                	addiw	a5,a5,1
    800037de:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037e0:	0001d517          	auipc	a0,0x1d
    800037e4:	de850513          	addi	a0,a0,-536 # 800205c8 <itable>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	48e080e7          	jalr	1166(ra) # 80000c76 <release>
      return ip;
    800037f0:	8926                	mv	s2,s1
    800037f2:	a03d                	j	80003820 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037f4:	f7f9                	bnez	a5,800037c2 <iget+0x3c>
    800037f6:	8926                	mv	s2,s1
    800037f8:	b7e9                	j	800037c2 <iget+0x3c>
  if(empty == 0)
    800037fa:	02090c63          	beqz	s2,80003832 <iget+0xac>
  ip->dev = dev;
    800037fe:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003802:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003806:	4785                	li	a5,1
    80003808:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000380c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003810:	0001d517          	auipc	a0,0x1d
    80003814:	db850513          	addi	a0,a0,-584 # 800205c8 <itable>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	45e080e7          	jalr	1118(ra) # 80000c76 <release>
}
    80003820:	854a                	mv	a0,s2
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6a02                	ld	s4,0(sp)
    8000382e:	6145                	addi	sp,sp,48
    80003830:	8082                	ret
    panic("iget: no inodes");
    80003832:	00005517          	auipc	a0,0x5
    80003836:	e6650513          	addi	a0,a0,-410 # 80008698 <syscalls+0x148>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	cf0080e7          	jalr	-784(ra) # 8000052a <panic>

0000000080003842 <fsinit>:
fsinit(int dev) {
    80003842:	7179                	addi	sp,sp,-48
    80003844:	f406                	sd	ra,40(sp)
    80003846:	f022                	sd	s0,32(sp)
    80003848:	ec26                	sd	s1,24(sp)
    8000384a:	e84a                	sd	s2,16(sp)
    8000384c:	e44e                	sd	s3,8(sp)
    8000384e:	1800                	addi	s0,sp,48
    80003850:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003852:	4585                	li	a1,1
    80003854:	00000097          	auipc	ra,0x0
    80003858:	a62080e7          	jalr	-1438(ra) # 800032b6 <bread>
    8000385c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000385e:	0001d997          	auipc	s3,0x1d
    80003862:	d4a98993          	addi	s3,s3,-694 # 800205a8 <sb>
    80003866:	02000613          	li	a2,32
    8000386a:	05850593          	addi	a1,a0,88
    8000386e:	854e                	mv	a0,s3
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	4aa080e7          	jalr	1194(ra) # 80000d1a <memmove>
  brelse(bp);
    80003878:	8526                	mv	a0,s1
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	b6c080e7          	jalr	-1172(ra) # 800033e6 <brelse>
  if(sb.magic != FSMAGIC)
    80003882:	0009a703          	lw	a4,0(s3)
    80003886:	102037b7          	lui	a5,0x10203
    8000388a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000388e:	02f71263          	bne	a4,a5,800038b2 <fsinit+0x70>
  initlog(dev, &sb);
    80003892:	0001d597          	auipc	a1,0x1d
    80003896:	d1658593          	addi	a1,a1,-746 # 800205a8 <sb>
    8000389a:	854a                	mv	a0,s2
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	b4e080e7          	jalr	-1202(ra) # 800043ea <initlog>
}
    800038a4:	70a2                	ld	ra,40(sp)
    800038a6:	7402                	ld	s0,32(sp)
    800038a8:	64e2                	ld	s1,24(sp)
    800038aa:	6942                	ld	s2,16(sp)
    800038ac:	69a2                	ld	s3,8(sp)
    800038ae:	6145                	addi	sp,sp,48
    800038b0:	8082                	ret
    panic("invalid file system");
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	df650513          	addi	a0,a0,-522 # 800086a8 <syscalls+0x158>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	c70080e7          	jalr	-912(ra) # 8000052a <panic>

00000000800038c2 <iinit>:
{
    800038c2:	7179                	addi	sp,sp,-48
    800038c4:	f406                	sd	ra,40(sp)
    800038c6:	f022                	sd	s0,32(sp)
    800038c8:	ec26                	sd	s1,24(sp)
    800038ca:	e84a                	sd	s2,16(sp)
    800038cc:	e44e                	sd	s3,8(sp)
    800038ce:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038d0:	00005597          	auipc	a1,0x5
    800038d4:	df058593          	addi	a1,a1,-528 # 800086c0 <syscalls+0x170>
    800038d8:	0001d517          	auipc	a0,0x1d
    800038dc:	cf050513          	addi	a0,a0,-784 # 800205c8 <itable>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	252080e7          	jalr	594(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038e8:	0001d497          	auipc	s1,0x1d
    800038ec:	d0848493          	addi	s1,s1,-760 # 800205f0 <itable+0x28>
    800038f0:	0001e997          	auipc	s3,0x1e
    800038f4:	79098993          	addi	s3,s3,1936 # 80022080 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038f8:	00005917          	auipc	s2,0x5
    800038fc:	dd090913          	addi	s2,s2,-560 # 800086c8 <syscalls+0x178>
    80003900:	85ca                	mv	a1,s2
    80003902:	8526                	mv	a0,s1
    80003904:	00001097          	auipc	ra,0x1
    80003908:	e4a080e7          	jalr	-438(ra) # 8000474e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000390c:	08848493          	addi	s1,s1,136
    80003910:	ff3498e3          	bne	s1,s3,80003900 <iinit+0x3e>
}
    80003914:	70a2                	ld	ra,40(sp)
    80003916:	7402                	ld	s0,32(sp)
    80003918:	64e2                	ld	s1,24(sp)
    8000391a:	6942                	ld	s2,16(sp)
    8000391c:	69a2                	ld	s3,8(sp)
    8000391e:	6145                	addi	sp,sp,48
    80003920:	8082                	ret

0000000080003922 <ialloc>:
{
    80003922:	715d                	addi	sp,sp,-80
    80003924:	e486                	sd	ra,72(sp)
    80003926:	e0a2                	sd	s0,64(sp)
    80003928:	fc26                	sd	s1,56(sp)
    8000392a:	f84a                	sd	s2,48(sp)
    8000392c:	f44e                	sd	s3,40(sp)
    8000392e:	f052                	sd	s4,32(sp)
    80003930:	ec56                	sd	s5,24(sp)
    80003932:	e85a                	sd	s6,16(sp)
    80003934:	e45e                	sd	s7,8(sp)
    80003936:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003938:	0001d717          	auipc	a4,0x1d
    8000393c:	c7c72703          	lw	a4,-900(a4) # 800205b4 <sb+0xc>
    80003940:	4785                	li	a5,1
    80003942:	04e7fa63          	bgeu	a5,a4,80003996 <ialloc+0x74>
    80003946:	8aaa                	mv	s5,a0
    80003948:	8bae                	mv	s7,a1
    8000394a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000394c:	0001da17          	auipc	s4,0x1d
    80003950:	c5ca0a13          	addi	s4,s4,-932 # 800205a8 <sb>
    80003954:	00048b1b          	sext.w	s6,s1
    80003958:	0044d793          	srli	a5,s1,0x4
    8000395c:	018a2583          	lw	a1,24(s4)
    80003960:	9dbd                	addw	a1,a1,a5
    80003962:	8556                	mv	a0,s5
    80003964:	00000097          	auipc	ra,0x0
    80003968:	952080e7          	jalr	-1710(ra) # 800032b6 <bread>
    8000396c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000396e:	05850993          	addi	s3,a0,88
    80003972:	00f4f793          	andi	a5,s1,15
    80003976:	079a                	slli	a5,a5,0x6
    80003978:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000397a:	00099783          	lh	a5,0(s3)
    8000397e:	c785                	beqz	a5,800039a6 <ialloc+0x84>
    brelse(bp);
    80003980:	00000097          	auipc	ra,0x0
    80003984:	a66080e7          	jalr	-1434(ra) # 800033e6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003988:	0485                	addi	s1,s1,1
    8000398a:	00ca2703          	lw	a4,12(s4)
    8000398e:	0004879b          	sext.w	a5,s1
    80003992:	fce7e1e3          	bltu	a5,a4,80003954 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003996:	00005517          	auipc	a0,0x5
    8000399a:	d3a50513          	addi	a0,a0,-710 # 800086d0 <syscalls+0x180>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	b8c080e7          	jalr	-1140(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800039a6:	04000613          	li	a2,64
    800039aa:	4581                	li	a1,0
    800039ac:	854e                	mv	a0,s3
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	310080e7          	jalr	784(ra) # 80000cbe <memset>
      dip->type = type;
    800039b6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039ba:	854a                	mv	a0,s2
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	cac080e7          	jalr	-852(ra) # 80004668 <log_write>
      brelse(bp);
    800039c4:	854a                	mv	a0,s2
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	a20080e7          	jalr	-1504(ra) # 800033e6 <brelse>
      return iget(dev, inum);
    800039ce:	85da                	mv	a1,s6
    800039d0:	8556                	mv	a0,s5
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	db4080e7          	jalr	-588(ra) # 80003786 <iget>
}
    800039da:	60a6                	ld	ra,72(sp)
    800039dc:	6406                	ld	s0,64(sp)
    800039de:	74e2                	ld	s1,56(sp)
    800039e0:	7942                	ld	s2,48(sp)
    800039e2:	79a2                	ld	s3,40(sp)
    800039e4:	7a02                	ld	s4,32(sp)
    800039e6:	6ae2                	ld	s5,24(sp)
    800039e8:	6b42                	ld	s6,16(sp)
    800039ea:	6ba2                	ld	s7,8(sp)
    800039ec:	6161                	addi	sp,sp,80
    800039ee:	8082                	ret

00000000800039f0 <iupdate>:
{
    800039f0:	1101                	addi	sp,sp,-32
    800039f2:	ec06                	sd	ra,24(sp)
    800039f4:	e822                	sd	s0,16(sp)
    800039f6:	e426                	sd	s1,8(sp)
    800039f8:	e04a                	sd	s2,0(sp)
    800039fa:	1000                	addi	s0,sp,32
    800039fc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039fe:	415c                	lw	a5,4(a0)
    80003a00:	0047d79b          	srliw	a5,a5,0x4
    80003a04:	0001d597          	auipc	a1,0x1d
    80003a08:	bbc5a583          	lw	a1,-1092(a1) # 800205c0 <sb+0x18>
    80003a0c:	9dbd                	addw	a1,a1,a5
    80003a0e:	4108                	lw	a0,0(a0)
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	8a6080e7          	jalr	-1882(ra) # 800032b6 <bread>
    80003a18:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a1a:	05850793          	addi	a5,a0,88
    80003a1e:	40c8                	lw	a0,4(s1)
    80003a20:	893d                	andi	a0,a0,15
    80003a22:	051a                	slli	a0,a0,0x6
    80003a24:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a26:	04449703          	lh	a4,68(s1)
    80003a2a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a2e:	04649703          	lh	a4,70(s1)
    80003a32:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a36:	04849703          	lh	a4,72(s1)
    80003a3a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a3e:	04a49703          	lh	a4,74(s1)
    80003a42:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a46:	44f8                	lw	a4,76(s1)
    80003a48:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a4a:	03400613          	li	a2,52
    80003a4e:	05048593          	addi	a1,s1,80
    80003a52:	0531                	addi	a0,a0,12
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	2c6080e7          	jalr	710(ra) # 80000d1a <memmove>
  log_write(bp);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	c0a080e7          	jalr	-1014(ra) # 80004668 <log_write>
  brelse(bp);
    80003a66:	854a                	mv	a0,s2
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	97e080e7          	jalr	-1666(ra) # 800033e6 <brelse>
}
    80003a70:	60e2                	ld	ra,24(sp)
    80003a72:	6442                	ld	s0,16(sp)
    80003a74:	64a2                	ld	s1,8(sp)
    80003a76:	6902                	ld	s2,0(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret

0000000080003a7c <idup>:
{
    80003a7c:	1101                	addi	sp,sp,-32
    80003a7e:	ec06                	sd	ra,24(sp)
    80003a80:	e822                	sd	s0,16(sp)
    80003a82:	e426                	sd	s1,8(sp)
    80003a84:	1000                	addi	s0,sp,32
    80003a86:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a88:	0001d517          	auipc	a0,0x1d
    80003a8c:	b4050513          	addi	a0,a0,-1216 # 800205c8 <itable>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	132080e7          	jalr	306(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003a98:	449c                	lw	a5,8(s1)
    80003a9a:	2785                	addiw	a5,a5,1
    80003a9c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a9e:	0001d517          	auipc	a0,0x1d
    80003aa2:	b2a50513          	addi	a0,a0,-1238 # 800205c8 <itable>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	1d0080e7          	jalr	464(ra) # 80000c76 <release>
}
    80003aae:	8526                	mv	a0,s1
    80003ab0:	60e2                	ld	ra,24(sp)
    80003ab2:	6442                	ld	s0,16(sp)
    80003ab4:	64a2                	ld	s1,8(sp)
    80003ab6:	6105                	addi	sp,sp,32
    80003ab8:	8082                	ret

0000000080003aba <ilock>:
{
    80003aba:	1101                	addi	sp,sp,-32
    80003abc:	ec06                	sd	ra,24(sp)
    80003abe:	e822                	sd	s0,16(sp)
    80003ac0:	e426                	sd	s1,8(sp)
    80003ac2:	e04a                	sd	s2,0(sp)
    80003ac4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ac6:	c115                	beqz	a0,80003aea <ilock+0x30>
    80003ac8:	84aa                	mv	s1,a0
    80003aca:	451c                	lw	a5,8(a0)
    80003acc:	00f05f63          	blez	a5,80003aea <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ad0:	0541                	addi	a0,a0,16
    80003ad2:	00001097          	auipc	ra,0x1
    80003ad6:	cb6080e7          	jalr	-842(ra) # 80004788 <acquiresleep>
  if(ip->valid == 0){
    80003ada:	40bc                	lw	a5,64(s1)
    80003adc:	cf99                	beqz	a5,80003afa <ilock+0x40>
}
    80003ade:	60e2                	ld	ra,24(sp)
    80003ae0:	6442                	ld	s0,16(sp)
    80003ae2:	64a2                	ld	s1,8(sp)
    80003ae4:	6902                	ld	s2,0(sp)
    80003ae6:	6105                	addi	sp,sp,32
    80003ae8:	8082                	ret
    panic("ilock");
    80003aea:	00005517          	auipc	a0,0x5
    80003aee:	bfe50513          	addi	a0,a0,-1026 # 800086e8 <syscalls+0x198>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	a38080e7          	jalr	-1480(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003afa:	40dc                	lw	a5,4(s1)
    80003afc:	0047d79b          	srliw	a5,a5,0x4
    80003b00:	0001d597          	auipc	a1,0x1d
    80003b04:	ac05a583          	lw	a1,-1344(a1) # 800205c0 <sb+0x18>
    80003b08:	9dbd                	addw	a1,a1,a5
    80003b0a:	4088                	lw	a0,0(s1)
    80003b0c:	fffff097          	auipc	ra,0xfffff
    80003b10:	7aa080e7          	jalr	1962(ra) # 800032b6 <bread>
    80003b14:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b16:	05850593          	addi	a1,a0,88
    80003b1a:	40dc                	lw	a5,4(s1)
    80003b1c:	8bbd                	andi	a5,a5,15
    80003b1e:	079a                	slli	a5,a5,0x6
    80003b20:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b22:	00059783          	lh	a5,0(a1)
    80003b26:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b2a:	00259783          	lh	a5,2(a1)
    80003b2e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b32:	00459783          	lh	a5,4(a1)
    80003b36:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b3a:	00659783          	lh	a5,6(a1)
    80003b3e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b42:	459c                	lw	a5,8(a1)
    80003b44:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b46:	03400613          	li	a2,52
    80003b4a:	05b1                	addi	a1,a1,12
    80003b4c:	05048513          	addi	a0,s1,80
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	1ca080e7          	jalr	458(ra) # 80000d1a <memmove>
    brelse(bp);
    80003b58:	854a                	mv	a0,s2
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	88c080e7          	jalr	-1908(ra) # 800033e6 <brelse>
    ip->valid = 1;
    80003b62:	4785                	li	a5,1
    80003b64:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b66:	04449783          	lh	a5,68(s1)
    80003b6a:	fbb5                	bnez	a5,80003ade <ilock+0x24>
      panic("ilock: no type");
    80003b6c:	00005517          	auipc	a0,0x5
    80003b70:	b8450513          	addi	a0,a0,-1148 # 800086f0 <syscalls+0x1a0>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	9b6080e7          	jalr	-1610(ra) # 8000052a <panic>

0000000080003b7c <iunlock>:
{
    80003b7c:	1101                	addi	sp,sp,-32
    80003b7e:	ec06                	sd	ra,24(sp)
    80003b80:	e822                	sd	s0,16(sp)
    80003b82:	e426                	sd	s1,8(sp)
    80003b84:	e04a                	sd	s2,0(sp)
    80003b86:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b88:	c905                	beqz	a0,80003bb8 <iunlock+0x3c>
    80003b8a:	84aa                	mv	s1,a0
    80003b8c:	01050913          	addi	s2,a0,16
    80003b90:	854a                	mv	a0,s2
    80003b92:	00001097          	auipc	ra,0x1
    80003b96:	c90080e7          	jalr	-880(ra) # 80004822 <holdingsleep>
    80003b9a:	cd19                	beqz	a0,80003bb8 <iunlock+0x3c>
    80003b9c:	449c                	lw	a5,8(s1)
    80003b9e:	00f05d63          	blez	a5,80003bb8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	00001097          	auipc	ra,0x1
    80003ba8:	c3a080e7          	jalr	-966(ra) # 800047de <releasesleep>
}
    80003bac:	60e2                	ld	ra,24(sp)
    80003bae:	6442                	ld	s0,16(sp)
    80003bb0:	64a2                	ld	s1,8(sp)
    80003bb2:	6902                	ld	s2,0(sp)
    80003bb4:	6105                	addi	sp,sp,32
    80003bb6:	8082                	ret
    panic("iunlock");
    80003bb8:	00005517          	auipc	a0,0x5
    80003bbc:	b4850513          	addi	a0,a0,-1208 # 80008700 <syscalls+0x1b0>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	96a080e7          	jalr	-1686(ra) # 8000052a <panic>

0000000080003bc8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bc8:	7179                	addi	sp,sp,-48
    80003bca:	f406                	sd	ra,40(sp)
    80003bcc:	f022                	sd	s0,32(sp)
    80003bce:	ec26                	sd	s1,24(sp)
    80003bd0:	e84a                	sd	s2,16(sp)
    80003bd2:	e44e                	sd	s3,8(sp)
    80003bd4:	e052                	sd	s4,0(sp)
    80003bd6:	1800                	addi	s0,sp,48
    80003bd8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bda:	05050493          	addi	s1,a0,80
    80003bde:	08050913          	addi	s2,a0,128
    80003be2:	a021                	j	80003bea <itrunc+0x22>
    80003be4:	0491                	addi	s1,s1,4
    80003be6:	01248d63          	beq	s1,s2,80003c00 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bea:	408c                	lw	a1,0(s1)
    80003bec:	dde5                	beqz	a1,80003be4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bee:	0009a503          	lw	a0,0(s3)
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	90a080e7          	jalr	-1782(ra) # 800034fc <bfree>
      ip->addrs[i] = 0;
    80003bfa:	0004a023          	sw	zero,0(s1)
    80003bfe:	b7dd                	j	80003be4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c00:	0809a583          	lw	a1,128(s3)
    80003c04:	e185                	bnez	a1,80003c24 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c06:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c0a:	854e                	mv	a0,s3
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	de4080e7          	jalr	-540(ra) # 800039f0 <iupdate>
}
    80003c14:	70a2                	ld	ra,40(sp)
    80003c16:	7402                	ld	s0,32(sp)
    80003c18:	64e2                	ld	s1,24(sp)
    80003c1a:	6942                	ld	s2,16(sp)
    80003c1c:	69a2                	ld	s3,8(sp)
    80003c1e:	6a02                	ld	s4,0(sp)
    80003c20:	6145                	addi	sp,sp,48
    80003c22:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c24:	0009a503          	lw	a0,0(s3)
    80003c28:	fffff097          	auipc	ra,0xfffff
    80003c2c:	68e080e7          	jalr	1678(ra) # 800032b6 <bread>
    80003c30:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c32:	05850493          	addi	s1,a0,88
    80003c36:	45850913          	addi	s2,a0,1112
    80003c3a:	a021                	j	80003c42 <itrunc+0x7a>
    80003c3c:	0491                	addi	s1,s1,4
    80003c3e:	01248b63          	beq	s1,s2,80003c54 <itrunc+0x8c>
      if(a[j])
    80003c42:	408c                	lw	a1,0(s1)
    80003c44:	dde5                	beqz	a1,80003c3c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c46:	0009a503          	lw	a0,0(s3)
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	8b2080e7          	jalr	-1870(ra) # 800034fc <bfree>
    80003c52:	b7ed                	j	80003c3c <itrunc+0x74>
    brelse(bp);
    80003c54:	8552                	mv	a0,s4
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	790080e7          	jalr	1936(ra) # 800033e6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c5e:	0809a583          	lw	a1,128(s3)
    80003c62:	0009a503          	lw	a0,0(s3)
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	896080e7          	jalr	-1898(ra) # 800034fc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c6e:	0809a023          	sw	zero,128(s3)
    80003c72:	bf51                	j	80003c06 <itrunc+0x3e>

0000000080003c74 <iput>:
{
    80003c74:	1101                	addi	sp,sp,-32
    80003c76:	ec06                	sd	ra,24(sp)
    80003c78:	e822                	sd	s0,16(sp)
    80003c7a:	e426                	sd	s1,8(sp)
    80003c7c:	e04a                	sd	s2,0(sp)
    80003c7e:	1000                	addi	s0,sp,32
    80003c80:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c82:	0001d517          	auipc	a0,0x1d
    80003c86:	94650513          	addi	a0,a0,-1722 # 800205c8 <itable>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	f38080e7          	jalr	-200(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c92:	4498                	lw	a4,8(s1)
    80003c94:	4785                	li	a5,1
    80003c96:	02f70363          	beq	a4,a5,80003cbc <iput+0x48>
  ip->ref--;
    80003c9a:	449c                	lw	a5,8(s1)
    80003c9c:	37fd                	addiw	a5,a5,-1
    80003c9e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ca0:	0001d517          	auipc	a0,0x1d
    80003ca4:	92850513          	addi	a0,a0,-1752 # 800205c8 <itable>
    80003ca8:	ffffd097          	auipc	ra,0xffffd
    80003cac:	fce080e7          	jalr	-50(ra) # 80000c76 <release>
}
    80003cb0:	60e2                	ld	ra,24(sp)
    80003cb2:	6442                	ld	s0,16(sp)
    80003cb4:	64a2                	ld	s1,8(sp)
    80003cb6:	6902                	ld	s2,0(sp)
    80003cb8:	6105                	addi	sp,sp,32
    80003cba:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cbc:	40bc                	lw	a5,64(s1)
    80003cbe:	dff1                	beqz	a5,80003c9a <iput+0x26>
    80003cc0:	04a49783          	lh	a5,74(s1)
    80003cc4:	fbf9                	bnez	a5,80003c9a <iput+0x26>
    acquiresleep(&ip->lock);
    80003cc6:	01048913          	addi	s2,s1,16
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00001097          	auipc	ra,0x1
    80003cd0:	abc080e7          	jalr	-1348(ra) # 80004788 <acquiresleep>
    release(&itable.lock);
    80003cd4:	0001d517          	auipc	a0,0x1d
    80003cd8:	8f450513          	addi	a0,a0,-1804 # 800205c8 <itable>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	f9a080e7          	jalr	-102(ra) # 80000c76 <release>
    itrunc(ip);
    80003ce4:	8526                	mv	a0,s1
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	ee2080e7          	jalr	-286(ra) # 80003bc8 <itrunc>
    ip->type = 0;
    80003cee:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	cfc080e7          	jalr	-772(ra) # 800039f0 <iupdate>
    ip->valid = 0;
    80003cfc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d00:	854a                	mv	a0,s2
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	adc080e7          	jalr	-1316(ra) # 800047de <releasesleep>
    acquire(&itable.lock);
    80003d0a:	0001d517          	auipc	a0,0x1d
    80003d0e:	8be50513          	addi	a0,a0,-1858 # 800205c8 <itable>
    80003d12:	ffffd097          	auipc	ra,0xffffd
    80003d16:	eb0080e7          	jalr	-336(ra) # 80000bc2 <acquire>
    80003d1a:	b741                	j	80003c9a <iput+0x26>

0000000080003d1c <iunlockput>:
{
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	1000                	addi	s0,sp,32
    80003d26:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	e54080e7          	jalr	-428(ra) # 80003b7c <iunlock>
  iput(ip);
    80003d30:	8526                	mv	a0,s1
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	f42080e7          	jalr	-190(ra) # 80003c74 <iput>
}
    80003d3a:	60e2                	ld	ra,24(sp)
    80003d3c:	6442                	ld	s0,16(sp)
    80003d3e:	64a2                	ld	s1,8(sp)
    80003d40:	6105                	addi	sp,sp,32
    80003d42:	8082                	ret

0000000080003d44 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d44:	1141                	addi	sp,sp,-16
    80003d46:	e422                	sd	s0,8(sp)
    80003d48:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d4a:	411c                	lw	a5,0(a0)
    80003d4c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d4e:	415c                	lw	a5,4(a0)
    80003d50:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d52:	04451783          	lh	a5,68(a0)
    80003d56:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d5a:	04a51783          	lh	a5,74(a0)
    80003d5e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d62:	04c56783          	lwu	a5,76(a0)
    80003d66:	e99c                	sd	a5,16(a1)
}
    80003d68:	6422                	ld	s0,8(sp)
    80003d6a:	0141                	addi	sp,sp,16
    80003d6c:	8082                	ret

0000000080003d6e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d6e:	457c                	lw	a5,76(a0)
    80003d70:	0ed7e963          	bltu	a5,a3,80003e62 <readi+0xf4>
{
    80003d74:	7159                	addi	sp,sp,-112
    80003d76:	f486                	sd	ra,104(sp)
    80003d78:	f0a2                	sd	s0,96(sp)
    80003d7a:	eca6                	sd	s1,88(sp)
    80003d7c:	e8ca                	sd	s2,80(sp)
    80003d7e:	e4ce                	sd	s3,72(sp)
    80003d80:	e0d2                	sd	s4,64(sp)
    80003d82:	fc56                	sd	s5,56(sp)
    80003d84:	f85a                	sd	s6,48(sp)
    80003d86:	f45e                	sd	s7,40(sp)
    80003d88:	f062                	sd	s8,32(sp)
    80003d8a:	ec66                	sd	s9,24(sp)
    80003d8c:	e86a                	sd	s10,16(sp)
    80003d8e:	e46e                	sd	s11,8(sp)
    80003d90:	1880                	addi	s0,sp,112
    80003d92:	8baa                	mv	s7,a0
    80003d94:	8c2e                	mv	s8,a1
    80003d96:	8ab2                	mv	s5,a2
    80003d98:	84b6                	mv	s1,a3
    80003d9a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d9c:	9f35                	addw	a4,a4,a3
    return 0;
    80003d9e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003da0:	0ad76063          	bltu	a4,a3,80003e40 <readi+0xd2>
  if(off + n > ip->size)
    80003da4:	00e7f463          	bgeu	a5,a4,80003dac <readi+0x3e>
    n = ip->size - off;
    80003da8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dac:	0a0b0963          	beqz	s6,80003e5e <readi+0xf0>
    80003db0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003db6:	5cfd                	li	s9,-1
    80003db8:	a82d                	j	80003df2 <readi+0x84>
    80003dba:	020a1d93          	slli	s11,s4,0x20
    80003dbe:	020ddd93          	srli	s11,s11,0x20
    80003dc2:	05890793          	addi	a5,s2,88
    80003dc6:	86ee                	mv	a3,s11
    80003dc8:	963e                	add	a2,a2,a5
    80003dca:	85d6                	mv	a1,s5
    80003dcc:	8562                	mv	a0,s8
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	8d4080e7          	jalr	-1836(ra) # 800026a2 <either_copyout>
    80003dd6:	05950d63          	beq	a0,s9,80003e30 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003dda:	854a                	mv	a0,s2
    80003ddc:	fffff097          	auipc	ra,0xfffff
    80003de0:	60a080e7          	jalr	1546(ra) # 800033e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de4:	013a09bb          	addw	s3,s4,s3
    80003de8:	009a04bb          	addw	s1,s4,s1
    80003dec:	9aee                	add	s5,s5,s11
    80003dee:	0569f763          	bgeu	s3,s6,80003e3c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003df2:	000ba903          	lw	s2,0(s7)
    80003df6:	00a4d59b          	srliw	a1,s1,0xa
    80003dfa:	855e                	mv	a0,s7
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	8ae080e7          	jalr	-1874(ra) # 800036aa <bmap>
    80003e04:	0005059b          	sext.w	a1,a0
    80003e08:	854a                	mv	a0,s2
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	4ac080e7          	jalr	1196(ra) # 800032b6 <bread>
    80003e12:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e14:	3ff4f613          	andi	a2,s1,1023
    80003e18:	40cd07bb          	subw	a5,s10,a2
    80003e1c:	413b073b          	subw	a4,s6,s3
    80003e20:	8a3e                	mv	s4,a5
    80003e22:	2781                	sext.w	a5,a5
    80003e24:	0007069b          	sext.w	a3,a4
    80003e28:	f8f6f9e3          	bgeu	a3,a5,80003dba <readi+0x4c>
    80003e2c:	8a3a                	mv	s4,a4
    80003e2e:	b771                	j	80003dba <readi+0x4c>
      brelse(bp);
    80003e30:	854a                	mv	a0,s2
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	5b4080e7          	jalr	1460(ra) # 800033e6 <brelse>
      tot = -1;
    80003e3a:	59fd                	li	s3,-1
  }
  return tot;
    80003e3c:	0009851b          	sext.w	a0,s3
}
    80003e40:	70a6                	ld	ra,104(sp)
    80003e42:	7406                	ld	s0,96(sp)
    80003e44:	64e6                	ld	s1,88(sp)
    80003e46:	6946                	ld	s2,80(sp)
    80003e48:	69a6                	ld	s3,72(sp)
    80003e4a:	6a06                	ld	s4,64(sp)
    80003e4c:	7ae2                	ld	s5,56(sp)
    80003e4e:	7b42                	ld	s6,48(sp)
    80003e50:	7ba2                	ld	s7,40(sp)
    80003e52:	7c02                	ld	s8,32(sp)
    80003e54:	6ce2                	ld	s9,24(sp)
    80003e56:	6d42                	ld	s10,16(sp)
    80003e58:	6da2                	ld	s11,8(sp)
    80003e5a:	6165                	addi	sp,sp,112
    80003e5c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e5e:	89da                	mv	s3,s6
    80003e60:	bff1                	j	80003e3c <readi+0xce>
    return 0;
    80003e62:	4501                	li	a0,0
}
    80003e64:	8082                	ret

0000000080003e66 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e66:	457c                	lw	a5,76(a0)
    80003e68:	10d7e863          	bltu	a5,a3,80003f78 <writei+0x112>
{
    80003e6c:	7159                	addi	sp,sp,-112
    80003e6e:	f486                	sd	ra,104(sp)
    80003e70:	f0a2                	sd	s0,96(sp)
    80003e72:	eca6                	sd	s1,88(sp)
    80003e74:	e8ca                	sd	s2,80(sp)
    80003e76:	e4ce                	sd	s3,72(sp)
    80003e78:	e0d2                	sd	s4,64(sp)
    80003e7a:	fc56                	sd	s5,56(sp)
    80003e7c:	f85a                	sd	s6,48(sp)
    80003e7e:	f45e                	sd	s7,40(sp)
    80003e80:	f062                	sd	s8,32(sp)
    80003e82:	ec66                	sd	s9,24(sp)
    80003e84:	e86a                	sd	s10,16(sp)
    80003e86:	e46e                	sd	s11,8(sp)
    80003e88:	1880                	addi	s0,sp,112
    80003e8a:	8b2a                	mv	s6,a0
    80003e8c:	8c2e                	mv	s8,a1
    80003e8e:	8ab2                	mv	s5,a2
    80003e90:	8936                	mv	s2,a3
    80003e92:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e94:	00e687bb          	addw	a5,a3,a4
    80003e98:	0ed7e263          	bltu	a5,a3,80003f7c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e9c:	00043737          	lui	a4,0x43
    80003ea0:	0ef76063          	bltu	a4,a5,80003f80 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ea4:	0c0b8863          	beqz	s7,80003f74 <writei+0x10e>
    80003ea8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eaa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eae:	5cfd                	li	s9,-1
    80003eb0:	a091                	j	80003ef4 <writei+0x8e>
    80003eb2:	02099d93          	slli	s11,s3,0x20
    80003eb6:	020ddd93          	srli	s11,s11,0x20
    80003eba:	05848793          	addi	a5,s1,88
    80003ebe:	86ee                	mv	a3,s11
    80003ec0:	8656                	mv	a2,s5
    80003ec2:	85e2                	mv	a1,s8
    80003ec4:	953e                	add	a0,a0,a5
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	832080e7          	jalr	-1998(ra) # 800026f8 <either_copyin>
    80003ece:	07950263          	beq	a0,s9,80003f32 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	794080e7          	jalr	1940(ra) # 80004668 <log_write>
    brelse(bp);
    80003edc:	8526                	mv	a0,s1
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	508080e7          	jalr	1288(ra) # 800033e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ee6:	01498a3b          	addw	s4,s3,s4
    80003eea:	0129893b          	addw	s2,s3,s2
    80003eee:	9aee                	add	s5,s5,s11
    80003ef0:	057a7663          	bgeu	s4,s7,80003f3c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ef4:	000b2483          	lw	s1,0(s6)
    80003ef8:	00a9559b          	srliw	a1,s2,0xa
    80003efc:	855a                	mv	a0,s6
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	7ac080e7          	jalr	1964(ra) # 800036aa <bmap>
    80003f06:	0005059b          	sext.w	a1,a0
    80003f0a:	8526                	mv	a0,s1
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	3aa080e7          	jalr	938(ra) # 800032b6 <bread>
    80003f14:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f16:	3ff97513          	andi	a0,s2,1023
    80003f1a:	40ad07bb          	subw	a5,s10,a0
    80003f1e:	414b873b          	subw	a4,s7,s4
    80003f22:	89be                	mv	s3,a5
    80003f24:	2781                	sext.w	a5,a5
    80003f26:	0007069b          	sext.w	a3,a4
    80003f2a:	f8f6f4e3          	bgeu	a3,a5,80003eb2 <writei+0x4c>
    80003f2e:	89ba                	mv	s3,a4
    80003f30:	b749                	j	80003eb2 <writei+0x4c>
      brelse(bp);
    80003f32:	8526                	mv	a0,s1
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	4b2080e7          	jalr	1202(ra) # 800033e6 <brelse>
  }

  if(off > ip->size)
    80003f3c:	04cb2783          	lw	a5,76(s6)
    80003f40:	0127f463          	bgeu	a5,s2,80003f48 <writei+0xe2>
    ip->size = off;
    80003f44:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f48:	855a                	mv	a0,s6
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	aa6080e7          	jalr	-1370(ra) # 800039f0 <iupdate>

  return tot;
    80003f52:	000a051b          	sext.w	a0,s4
}
    80003f56:	70a6                	ld	ra,104(sp)
    80003f58:	7406                	ld	s0,96(sp)
    80003f5a:	64e6                	ld	s1,88(sp)
    80003f5c:	6946                	ld	s2,80(sp)
    80003f5e:	69a6                	ld	s3,72(sp)
    80003f60:	6a06                	ld	s4,64(sp)
    80003f62:	7ae2                	ld	s5,56(sp)
    80003f64:	7b42                	ld	s6,48(sp)
    80003f66:	7ba2                	ld	s7,40(sp)
    80003f68:	7c02                	ld	s8,32(sp)
    80003f6a:	6ce2                	ld	s9,24(sp)
    80003f6c:	6d42                	ld	s10,16(sp)
    80003f6e:	6da2                	ld	s11,8(sp)
    80003f70:	6165                	addi	sp,sp,112
    80003f72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f74:	8a5e                	mv	s4,s7
    80003f76:	bfc9                	j	80003f48 <writei+0xe2>
    return -1;
    80003f78:	557d                	li	a0,-1
}
    80003f7a:	8082                	ret
    return -1;
    80003f7c:	557d                	li	a0,-1
    80003f7e:	bfe1                	j	80003f56 <writei+0xf0>
    return -1;
    80003f80:	557d                	li	a0,-1
    80003f82:	bfd1                	j	80003f56 <writei+0xf0>

0000000080003f84 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f84:	1141                	addi	sp,sp,-16
    80003f86:	e406                	sd	ra,8(sp)
    80003f88:	e022                	sd	s0,0(sp)
    80003f8a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f8c:	4639                	li	a2,14
    80003f8e:	ffffd097          	auipc	ra,0xffffd
    80003f92:	e08080e7          	jalr	-504(ra) # 80000d96 <strncmp>
}
    80003f96:	60a2                	ld	ra,8(sp)
    80003f98:	6402                	ld	s0,0(sp)
    80003f9a:	0141                	addi	sp,sp,16
    80003f9c:	8082                	ret

0000000080003f9e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f9e:	7139                	addi	sp,sp,-64
    80003fa0:	fc06                	sd	ra,56(sp)
    80003fa2:	f822                	sd	s0,48(sp)
    80003fa4:	f426                	sd	s1,40(sp)
    80003fa6:	f04a                	sd	s2,32(sp)
    80003fa8:	ec4e                	sd	s3,24(sp)
    80003faa:	e852                	sd	s4,16(sp)
    80003fac:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fae:	04451703          	lh	a4,68(a0)
    80003fb2:	4785                	li	a5,1
    80003fb4:	00f71a63          	bne	a4,a5,80003fc8 <dirlookup+0x2a>
    80003fb8:	892a                	mv	s2,a0
    80003fba:	89ae                	mv	s3,a1
    80003fbc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fbe:	457c                	lw	a5,76(a0)
    80003fc0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fc2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc4:	e79d                	bnez	a5,80003ff2 <dirlookup+0x54>
    80003fc6:	a8a5                	j	8000403e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fc8:	00004517          	auipc	a0,0x4
    80003fcc:	74050513          	addi	a0,a0,1856 # 80008708 <syscalls+0x1b8>
    80003fd0:	ffffc097          	auipc	ra,0xffffc
    80003fd4:	55a080e7          	jalr	1370(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003fd8:	00004517          	auipc	a0,0x4
    80003fdc:	74850513          	addi	a0,a0,1864 # 80008720 <syscalls+0x1d0>
    80003fe0:	ffffc097          	auipc	ra,0xffffc
    80003fe4:	54a080e7          	jalr	1354(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe8:	24c1                	addiw	s1,s1,16
    80003fea:	04c92783          	lw	a5,76(s2)
    80003fee:	04f4f763          	bgeu	s1,a5,8000403c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff2:	4741                	li	a4,16
    80003ff4:	86a6                	mv	a3,s1
    80003ff6:	fc040613          	addi	a2,s0,-64
    80003ffa:	4581                	li	a1,0
    80003ffc:	854a                	mv	a0,s2
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	d70080e7          	jalr	-656(ra) # 80003d6e <readi>
    80004006:	47c1                	li	a5,16
    80004008:	fcf518e3          	bne	a0,a5,80003fd8 <dirlookup+0x3a>
    if(de.inum == 0)
    8000400c:	fc045783          	lhu	a5,-64(s0)
    80004010:	dfe1                	beqz	a5,80003fe8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004012:	fc240593          	addi	a1,s0,-62
    80004016:	854e                	mv	a0,s3
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	f6c080e7          	jalr	-148(ra) # 80003f84 <namecmp>
    80004020:	f561                	bnez	a0,80003fe8 <dirlookup+0x4a>
      if(poff)
    80004022:	000a0463          	beqz	s4,8000402a <dirlookup+0x8c>
        *poff = off;
    80004026:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000402a:	fc045583          	lhu	a1,-64(s0)
    8000402e:	00092503          	lw	a0,0(s2)
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	754080e7          	jalr	1876(ra) # 80003786 <iget>
    8000403a:	a011                	j	8000403e <dirlookup+0xa0>
  return 0;
    8000403c:	4501                	li	a0,0
}
    8000403e:	70e2                	ld	ra,56(sp)
    80004040:	7442                	ld	s0,48(sp)
    80004042:	74a2                	ld	s1,40(sp)
    80004044:	7902                	ld	s2,32(sp)
    80004046:	69e2                	ld	s3,24(sp)
    80004048:	6a42                	ld	s4,16(sp)
    8000404a:	6121                	addi	sp,sp,64
    8000404c:	8082                	ret

000000008000404e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000404e:	711d                	addi	sp,sp,-96
    80004050:	ec86                	sd	ra,88(sp)
    80004052:	e8a2                	sd	s0,80(sp)
    80004054:	e4a6                	sd	s1,72(sp)
    80004056:	e0ca                	sd	s2,64(sp)
    80004058:	fc4e                	sd	s3,56(sp)
    8000405a:	f852                	sd	s4,48(sp)
    8000405c:	f456                	sd	s5,40(sp)
    8000405e:	f05a                	sd	s6,32(sp)
    80004060:	ec5e                	sd	s7,24(sp)
    80004062:	e862                	sd	s8,16(sp)
    80004064:	e466                	sd	s9,8(sp)
    80004066:	1080                	addi	s0,sp,96
    80004068:	84aa                	mv	s1,a0
    8000406a:	8aae                	mv	s5,a1
    8000406c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000406e:	00054703          	lbu	a4,0(a0)
    80004072:	02f00793          	li	a5,47
    80004076:	02f70363          	beq	a4,a5,8000409c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000407a:	ffffe097          	auipc	ra,0xffffe
    8000407e:	904080e7          	jalr	-1788(ra) # 8000197e <myproc>
    80004082:	18853503          	ld	a0,392(a0)
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	9f6080e7          	jalr	-1546(ra) # 80003a7c <idup>
    8000408e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004090:	02f00913          	li	s2,47
  len = path - s;
    80004094:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004096:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004098:	4b85                	li	s7,1
    8000409a:	a865                	j	80004152 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000409c:	4585                	li	a1,1
    8000409e:	4505                	li	a0,1
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	6e6080e7          	jalr	1766(ra) # 80003786 <iget>
    800040a8:	89aa                	mv	s3,a0
    800040aa:	b7dd                	j	80004090 <namex+0x42>
      iunlockput(ip);
    800040ac:	854e                	mv	a0,s3
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	c6e080e7          	jalr	-914(ra) # 80003d1c <iunlockput>
      return 0;
    800040b6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040b8:	854e                	mv	a0,s3
    800040ba:	60e6                	ld	ra,88(sp)
    800040bc:	6446                	ld	s0,80(sp)
    800040be:	64a6                	ld	s1,72(sp)
    800040c0:	6906                	ld	s2,64(sp)
    800040c2:	79e2                	ld	s3,56(sp)
    800040c4:	7a42                	ld	s4,48(sp)
    800040c6:	7aa2                	ld	s5,40(sp)
    800040c8:	7b02                	ld	s6,32(sp)
    800040ca:	6be2                	ld	s7,24(sp)
    800040cc:	6c42                	ld	s8,16(sp)
    800040ce:	6ca2                	ld	s9,8(sp)
    800040d0:	6125                	addi	sp,sp,96
    800040d2:	8082                	ret
      iunlock(ip);
    800040d4:	854e                	mv	a0,s3
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	aa6080e7          	jalr	-1370(ra) # 80003b7c <iunlock>
      return ip;
    800040de:	bfe9                	j	800040b8 <namex+0x6a>
      iunlockput(ip);
    800040e0:	854e                	mv	a0,s3
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	c3a080e7          	jalr	-966(ra) # 80003d1c <iunlockput>
      return 0;
    800040ea:	89e6                	mv	s3,s9
    800040ec:	b7f1                	j	800040b8 <namex+0x6a>
  len = path - s;
    800040ee:	40b48633          	sub	a2,s1,a1
    800040f2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040f6:	099c5463          	bge	s8,s9,8000417e <namex+0x130>
    memmove(name, s, DIRSIZ);
    800040fa:	4639                	li	a2,14
    800040fc:	8552                	mv	a0,s4
    800040fe:	ffffd097          	auipc	ra,0xffffd
    80004102:	c1c080e7          	jalr	-996(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004106:	0004c783          	lbu	a5,0(s1)
    8000410a:	01279763          	bne	a5,s2,80004118 <namex+0xca>
    path++;
    8000410e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004110:	0004c783          	lbu	a5,0(s1)
    80004114:	ff278de3          	beq	a5,s2,8000410e <namex+0xc0>
    ilock(ip);
    80004118:	854e                	mv	a0,s3
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	9a0080e7          	jalr	-1632(ra) # 80003aba <ilock>
    if(ip->type != T_DIR){
    80004122:	04499783          	lh	a5,68(s3)
    80004126:	f97793e3          	bne	a5,s7,800040ac <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000412a:	000a8563          	beqz	s5,80004134 <namex+0xe6>
    8000412e:	0004c783          	lbu	a5,0(s1)
    80004132:	d3cd                	beqz	a5,800040d4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004134:	865a                	mv	a2,s6
    80004136:	85d2                	mv	a1,s4
    80004138:	854e                	mv	a0,s3
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	e64080e7          	jalr	-412(ra) # 80003f9e <dirlookup>
    80004142:	8caa                	mv	s9,a0
    80004144:	dd51                	beqz	a0,800040e0 <namex+0x92>
    iunlockput(ip);
    80004146:	854e                	mv	a0,s3
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	bd4080e7          	jalr	-1068(ra) # 80003d1c <iunlockput>
    ip = next;
    80004150:	89e6                	mv	s3,s9
  while(*path == '/')
    80004152:	0004c783          	lbu	a5,0(s1)
    80004156:	05279763          	bne	a5,s2,800041a4 <namex+0x156>
    path++;
    8000415a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000415c:	0004c783          	lbu	a5,0(s1)
    80004160:	ff278de3          	beq	a5,s2,8000415a <namex+0x10c>
  if(*path == 0)
    80004164:	c79d                	beqz	a5,80004192 <namex+0x144>
    path++;
    80004166:	85a6                	mv	a1,s1
  len = path - s;
    80004168:	8cda                	mv	s9,s6
    8000416a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000416c:	01278963          	beq	a5,s2,8000417e <namex+0x130>
    80004170:	dfbd                	beqz	a5,800040ee <namex+0xa0>
    path++;
    80004172:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004174:	0004c783          	lbu	a5,0(s1)
    80004178:	ff279ce3          	bne	a5,s2,80004170 <namex+0x122>
    8000417c:	bf8d                	j	800040ee <namex+0xa0>
    memmove(name, s, len);
    8000417e:	2601                	sext.w	a2,a2
    80004180:	8552                	mv	a0,s4
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	b98080e7          	jalr	-1128(ra) # 80000d1a <memmove>
    name[len] = 0;
    8000418a:	9cd2                	add	s9,s9,s4
    8000418c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004190:	bf9d                	j	80004106 <namex+0xb8>
  if(nameiparent){
    80004192:	f20a83e3          	beqz	s5,800040b8 <namex+0x6a>
    iput(ip);
    80004196:	854e                	mv	a0,s3
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	adc080e7          	jalr	-1316(ra) # 80003c74 <iput>
    return 0;
    800041a0:	4981                	li	s3,0
    800041a2:	bf19                	j	800040b8 <namex+0x6a>
  if(*path == 0)
    800041a4:	d7fd                	beqz	a5,80004192 <namex+0x144>
  while(*path != '/' && *path != 0)
    800041a6:	0004c783          	lbu	a5,0(s1)
    800041aa:	85a6                	mv	a1,s1
    800041ac:	b7d1                	j	80004170 <namex+0x122>

00000000800041ae <dirlink>:
{
    800041ae:	7139                	addi	sp,sp,-64
    800041b0:	fc06                	sd	ra,56(sp)
    800041b2:	f822                	sd	s0,48(sp)
    800041b4:	f426                	sd	s1,40(sp)
    800041b6:	f04a                	sd	s2,32(sp)
    800041b8:	ec4e                	sd	s3,24(sp)
    800041ba:	e852                	sd	s4,16(sp)
    800041bc:	0080                	addi	s0,sp,64
    800041be:	892a                	mv	s2,a0
    800041c0:	8a2e                	mv	s4,a1
    800041c2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041c4:	4601                	li	a2,0
    800041c6:	00000097          	auipc	ra,0x0
    800041ca:	dd8080e7          	jalr	-552(ra) # 80003f9e <dirlookup>
    800041ce:	e93d                	bnez	a0,80004244 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d0:	04c92483          	lw	s1,76(s2)
    800041d4:	c49d                	beqz	s1,80004202 <dirlink+0x54>
    800041d6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d8:	4741                	li	a4,16
    800041da:	86a6                	mv	a3,s1
    800041dc:	fc040613          	addi	a2,s0,-64
    800041e0:	4581                	li	a1,0
    800041e2:	854a                	mv	a0,s2
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	b8a080e7          	jalr	-1142(ra) # 80003d6e <readi>
    800041ec:	47c1                	li	a5,16
    800041ee:	06f51163          	bne	a0,a5,80004250 <dirlink+0xa2>
    if(de.inum == 0)
    800041f2:	fc045783          	lhu	a5,-64(s0)
    800041f6:	c791                	beqz	a5,80004202 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f8:	24c1                	addiw	s1,s1,16
    800041fa:	04c92783          	lw	a5,76(s2)
    800041fe:	fcf4ede3          	bltu	s1,a5,800041d8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004202:	4639                	li	a2,14
    80004204:	85d2                	mv	a1,s4
    80004206:	fc240513          	addi	a0,s0,-62
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	bc8080e7          	jalr	-1080(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004212:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004216:	4741                	li	a4,16
    80004218:	86a6                	mv	a3,s1
    8000421a:	fc040613          	addi	a2,s0,-64
    8000421e:	4581                	li	a1,0
    80004220:	854a                	mv	a0,s2
    80004222:	00000097          	auipc	ra,0x0
    80004226:	c44080e7          	jalr	-956(ra) # 80003e66 <writei>
    8000422a:	872a                	mv	a4,a0
    8000422c:	47c1                	li	a5,16
  return 0;
    8000422e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004230:	02f71863          	bne	a4,a5,80004260 <dirlink+0xb2>
}
    80004234:	70e2                	ld	ra,56(sp)
    80004236:	7442                	ld	s0,48(sp)
    80004238:	74a2                	ld	s1,40(sp)
    8000423a:	7902                	ld	s2,32(sp)
    8000423c:	69e2                	ld	s3,24(sp)
    8000423e:	6a42                	ld	s4,16(sp)
    80004240:	6121                	addi	sp,sp,64
    80004242:	8082                	ret
    iput(ip);
    80004244:	00000097          	auipc	ra,0x0
    80004248:	a30080e7          	jalr	-1488(ra) # 80003c74 <iput>
    return -1;
    8000424c:	557d                	li	a0,-1
    8000424e:	b7dd                	j	80004234 <dirlink+0x86>
      panic("dirlink read");
    80004250:	00004517          	auipc	a0,0x4
    80004254:	4e050513          	addi	a0,a0,1248 # 80008730 <syscalls+0x1e0>
    80004258:	ffffc097          	auipc	ra,0xffffc
    8000425c:	2d2080e7          	jalr	722(ra) # 8000052a <panic>
    panic("dirlink");
    80004260:	00004517          	auipc	a0,0x4
    80004264:	5d850513          	addi	a0,a0,1496 # 80008838 <syscalls+0x2e8>
    80004268:	ffffc097          	auipc	ra,0xffffc
    8000426c:	2c2080e7          	jalr	706(ra) # 8000052a <panic>

0000000080004270 <namei>:

struct inode*
namei(char *path)
{
    80004270:	1101                	addi	sp,sp,-32
    80004272:	ec06                	sd	ra,24(sp)
    80004274:	e822                	sd	s0,16(sp)
    80004276:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004278:	fe040613          	addi	a2,s0,-32
    8000427c:	4581                	li	a1,0
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	dd0080e7          	jalr	-560(ra) # 8000404e <namex>
}
    80004286:	60e2                	ld	ra,24(sp)
    80004288:	6442                	ld	s0,16(sp)
    8000428a:	6105                	addi	sp,sp,32
    8000428c:	8082                	ret

000000008000428e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000428e:	1141                	addi	sp,sp,-16
    80004290:	e406                	sd	ra,8(sp)
    80004292:	e022                	sd	s0,0(sp)
    80004294:	0800                	addi	s0,sp,16
    80004296:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004298:	4585                	li	a1,1
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	db4080e7          	jalr	-588(ra) # 8000404e <namex>
}
    800042a2:	60a2                	ld	ra,8(sp)
    800042a4:	6402                	ld	s0,0(sp)
    800042a6:	0141                	addi	sp,sp,16
    800042a8:	8082                	ret

00000000800042aa <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042aa:	1101                	addi	sp,sp,-32
    800042ac:	ec06                	sd	ra,24(sp)
    800042ae:	e822                	sd	s0,16(sp)
    800042b0:	e426                	sd	s1,8(sp)
    800042b2:	e04a                	sd	s2,0(sp)
    800042b4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042b6:	0001e917          	auipc	s2,0x1e
    800042ba:	dba90913          	addi	s2,s2,-582 # 80022070 <log>
    800042be:	01892583          	lw	a1,24(s2)
    800042c2:	02892503          	lw	a0,40(s2)
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	ff0080e7          	jalr	-16(ra) # 800032b6 <bread>
    800042ce:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042d0:	02c92683          	lw	a3,44(s2)
    800042d4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042d6:	02d05863          	blez	a3,80004306 <write_head+0x5c>
    800042da:	0001e797          	auipc	a5,0x1e
    800042de:	dc678793          	addi	a5,a5,-570 # 800220a0 <log+0x30>
    800042e2:	05c50713          	addi	a4,a0,92
    800042e6:	36fd                	addiw	a3,a3,-1
    800042e8:	02069613          	slli	a2,a3,0x20
    800042ec:	01e65693          	srli	a3,a2,0x1e
    800042f0:	0001e617          	auipc	a2,0x1e
    800042f4:	db460613          	addi	a2,a2,-588 # 800220a4 <log+0x34>
    800042f8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042fa:	4390                	lw	a2,0(a5)
    800042fc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042fe:	0791                	addi	a5,a5,4
    80004300:	0711                	addi	a4,a4,4
    80004302:	fed79ce3          	bne	a5,a3,800042fa <write_head+0x50>
  }
  bwrite(buf);
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	0a0080e7          	jalr	160(ra) # 800033a8 <bwrite>
  brelse(buf);
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	0d4080e7          	jalr	212(ra) # 800033e6 <brelse>
}
    8000431a:	60e2                	ld	ra,24(sp)
    8000431c:	6442                	ld	s0,16(sp)
    8000431e:	64a2                	ld	s1,8(sp)
    80004320:	6902                	ld	s2,0(sp)
    80004322:	6105                	addi	sp,sp,32
    80004324:	8082                	ret

0000000080004326 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004326:	0001e797          	auipc	a5,0x1e
    8000432a:	d767a783          	lw	a5,-650(a5) # 8002209c <log+0x2c>
    8000432e:	0af05d63          	blez	a5,800043e8 <install_trans+0xc2>
{
    80004332:	7139                	addi	sp,sp,-64
    80004334:	fc06                	sd	ra,56(sp)
    80004336:	f822                	sd	s0,48(sp)
    80004338:	f426                	sd	s1,40(sp)
    8000433a:	f04a                	sd	s2,32(sp)
    8000433c:	ec4e                	sd	s3,24(sp)
    8000433e:	e852                	sd	s4,16(sp)
    80004340:	e456                	sd	s5,8(sp)
    80004342:	e05a                	sd	s6,0(sp)
    80004344:	0080                	addi	s0,sp,64
    80004346:	8b2a                	mv	s6,a0
    80004348:	0001ea97          	auipc	s5,0x1e
    8000434c:	d58a8a93          	addi	s5,s5,-680 # 800220a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004350:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004352:	0001e997          	auipc	s3,0x1e
    80004356:	d1e98993          	addi	s3,s3,-738 # 80022070 <log>
    8000435a:	a00d                	j	8000437c <install_trans+0x56>
    brelse(lbuf);
    8000435c:	854a                	mv	a0,s2
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	088080e7          	jalr	136(ra) # 800033e6 <brelse>
    brelse(dbuf);
    80004366:	8526                	mv	a0,s1
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	07e080e7          	jalr	126(ra) # 800033e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004370:	2a05                	addiw	s4,s4,1
    80004372:	0a91                	addi	s5,s5,4
    80004374:	02c9a783          	lw	a5,44(s3)
    80004378:	04fa5e63          	bge	s4,a5,800043d4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000437c:	0189a583          	lw	a1,24(s3)
    80004380:	014585bb          	addw	a1,a1,s4
    80004384:	2585                	addiw	a1,a1,1
    80004386:	0289a503          	lw	a0,40(s3)
    8000438a:	fffff097          	auipc	ra,0xfffff
    8000438e:	f2c080e7          	jalr	-212(ra) # 800032b6 <bread>
    80004392:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004394:	000aa583          	lw	a1,0(s5)
    80004398:	0289a503          	lw	a0,40(s3)
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	f1a080e7          	jalr	-230(ra) # 800032b6 <bread>
    800043a4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043a6:	40000613          	li	a2,1024
    800043aa:	05890593          	addi	a1,s2,88
    800043ae:	05850513          	addi	a0,a0,88
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	968080e7          	jalr	-1688(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800043ba:	8526                	mv	a0,s1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	fec080e7          	jalr	-20(ra) # 800033a8 <bwrite>
    if(recovering == 0)
    800043c4:	f80b1ce3          	bnez	s6,8000435c <install_trans+0x36>
      bunpin(dbuf);
    800043c8:	8526                	mv	a0,s1
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	0f6080e7          	jalr	246(ra) # 800034c0 <bunpin>
    800043d2:	b769                	j	8000435c <install_trans+0x36>
}
    800043d4:	70e2                	ld	ra,56(sp)
    800043d6:	7442                	ld	s0,48(sp)
    800043d8:	74a2                	ld	s1,40(sp)
    800043da:	7902                	ld	s2,32(sp)
    800043dc:	69e2                	ld	s3,24(sp)
    800043de:	6a42                	ld	s4,16(sp)
    800043e0:	6aa2                	ld	s5,8(sp)
    800043e2:	6b02                	ld	s6,0(sp)
    800043e4:	6121                	addi	sp,sp,64
    800043e6:	8082                	ret
    800043e8:	8082                	ret

00000000800043ea <initlog>:
{
    800043ea:	7179                	addi	sp,sp,-48
    800043ec:	f406                	sd	ra,40(sp)
    800043ee:	f022                	sd	s0,32(sp)
    800043f0:	ec26                	sd	s1,24(sp)
    800043f2:	e84a                	sd	s2,16(sp)
    800043f4:	e44e                	sd	s3,8(sp)
    800043f6:	1800                	addi	s0,sp,48
    800043f8:	892a                	mv	s2,a0
    800043fa:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043fc:	0001e497          	auipc	s1,0x1e
    80004400:	c7448493          	addi	s1,s1,-908 # 80022070 <log>
    80004404:	00004597          	auipc	a1,0x4
    80004408:	33c58593          	addi	a1,a1,828 # 80008740 <syscalls+0x1f0>
    8000440c:	8526                	mv	a0,s1
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	724080e7          	jalr	1828(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004416:	0149a583          	lw	a1,20(s3)
    8000441a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000441c:	0109a783          	lw	a5,16(s3)
    80004420:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004422:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004426:	854a                	mv	a0,s2
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	e8e080e7          	jalr	-370(ra) # 800032b6 <bread>
  log.lh.n = lh->n;
    80004430:	4d34                	lw	a3,88(a0)
    80004432:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004434:	02d05663          	blez	a3,80004460 <initlog+0x76>
    80004438:	05c50793          	addi	a5,a0,92
    8000443c:	0001e717          	auipc	a4,0x1e
    80004440:	c6470713          	addi	a4,a4,-924 # 800220a0 <log+0x30>
    80004444:	36fd                	addiw	a3,a3,-1
    80004446:	02069613          	slli	a2,a3,0x20
    8000444a:	01e65693          	srli	a3,a2,0x1e
    8000444e:	06050613          	addi	a2,a0,96
    80004452:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004454:	4390                	lw	a2,0(a5)
    80004456:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004458:	0791                	addi	a5,a5,4
    8000445a:	0711                	addi	a4,a4,4
    8000445c:	fed79ce3          	bne	a5,a3,80004454 <initlog+0x6a>
  brelse(buf);
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	f86080e7          	jalr	-122(ra) # 800033e6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004468:	4505                	li	a0,1
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	ebc080e7          	jalr	-324(ra) # 80004326 <install_trans>
  log.lh.n = 0;
    80004472:	0001e797          	auipc	a5,0x1e
    80004476:	c207a523          	sw	zero,-982(a5) # 8002209c <log+0x2c>
  write_head(); // clear the log
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	e30080e7          	jalr	-464(ra) # 800042aa <write_head>
}
    80004482:	70a2                	ld	ra,40(sp)
    80004484:	7402                	ld	s0,32(sp)
    80004486:	64e2                	ld	s1,24(sp)
    80004488:	6942                	ld	s2,16(sp)
    8000448a:	69a2                	ld	s3,8(sp)
    8000448c:	6145                	addi	sp,sp,48
    8000448e:	8082                	ret

0000000080004490 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004490:	1101                	addi	sp,sp,-32
    80004492:	ec06                	sd	ra,24(sp)
    80004494:	e822                	sd	s0,16(sp)
    80004496:	e426                	sd	s1,8(sp)
    80004498:	e04a                	sd	s2,0(sp)
    8000449a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000449c:	0001e517          	auipc	a0,0x1e
    800044a0:	bd450513          	addi	a0,a0,-1068 # 80022070 <log>
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	71e080e7          	jalr	1822(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800044ac:	0001e497          	auipc	s1,0x1e
    800044b0:	bc448493          	addi	s1,s1,-1084 # 80022070 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044b4:	4979                	li	s2,30
    800044b6:	a039                	j	800044c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044b8:	85a6                	mv	a1,s1
    800044ba:	8526                	mv	a0,s1
    800044bc:	ffffe097          	auipc	ra,0xffffe
    800044c0:	c38080e7          	jalr	-968(ra) # 800020f4 <sleep>
    if(log.committing){
    800044c4:	50dc                	lw	a5,36(s1)
    800044c6:	fbed                	bnez	a5,800044b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044c8:	509c                	lw	a5,32(s1)
    800044ca:	0017871b          	addiw	a4,a5,1
    800044ce:	0007069b          	sext.w	a3,a4
    800044d2:	0027179b          	slliw	a5,a4,0x2
    800044d6:	9fb9                	addw	a5,a5,a4
    800044d8:	0017979b          	slliw	a5,a5,0x1
    800044dc:	54d8                	lw	a4,44(s1)
    800044de:	9fb9                	addw	a5,a5,a4
    800044e0:	00f95963          	bge	s2,a5,800044f2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044e4:	85a6                	mv	a1,s1
    800044e6:	8526                	mv	a0,s1
    800044e8:	ffffe097          	auipc	ra,0xffffe
    800044ec:	c0c080e7          	jalr	-1012(ra) # 800020f4 <sleep>
    800044f0:	bfd1                	j	800044c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044f2:	0001e517          	auipc	a0,0x1e
    800044f6:	b7e50513          	addi	a0,a0,-1154 # 80022070 <log>
    800044fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	77a080e7          	jalr	1914(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004504:	60e2                	ld	ra,24(sp)
    80004506:	6442                	ld	s0,16(sp)
    80004508:	64a2                	ld	s1,8(sp)
    8000450a:	6902                	ld	s2,0(sp)
    8000450c:	6105                	addi	sp,sp,32
    8000450e:	8082                	ret

0000000080004510 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004510:	7139                	addi	sp,sp,-64
    80004512:	fc06                	sd	ra,56(sp)
    80004514:	f822                	sd	s0,48(sp)
    80004516:	f426                	sd	s1,40(sp)
    80004518:	f04a                	sd	s2,32(sp)
    8000451a:	ec4e                	sd	s3,24(sp)
    8000451c:	e852                	sd	s4,16(sp)
    8000451e:	e456                	sd	s5,8(sp)
    80004520:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004522:	0001e497          	auipc	s1,0x1e
    80004526:	b4e48493          	addi	s1,s1,-1202 # 80022070 <log>
    8000452a:	8526                	mv	a0,s1
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	696080e7          	jalr	1686(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004534:	509c                	lw	a5,32(s1)
    80004536:	37fd                	addiw	a5,a5,-1
    80004538:	0007891b          	sext.w	s2,a5
    8000453c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000453e:	50dc                	lw	a5,36(s1)
    80004540:	e7b9                	bnez	a5,8000458e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004542:	04091e63          	bnez	s2,8000459e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004546:	0001e497          	auipc	s1,0x1e
    8000454a:	b2a48493          	addi	s1,s1,-1238 # 80022070 <log>
    8000454e:	4785                	li	a5,1
    80004550:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004552:	8526                	mv	a0,s1
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	722080e7          	jalr	1826(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000455c:	54dc                	lw	a5,44(s1)
    8000455e:	06f04763          	bgtz	a5,800045cc <end_op+0xbc>
    acquire(&log.lock);
    80004562:	0001e497          	auipc	s1,0x1e
    80004566:	b0e48493          	addi	s1,s1,-1266 # 80022070 <log>
    8000456a:	8526                	mv	a0,s1
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	656080e7          	jalr	1622(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004574:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffe097          	auipc	ra,0xffffe
    8000457e:	dee080e7          	jalr	-530(ra) # 80002368 <wakeup>
    release(&log.lock);
    80004582:	8526                	mv	a0,s1
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	6f2080e7          	jalr	1778(ra) # 80000c76 <release>
}
    8000458c:	a03d                	j	800045ba <end_op+0xaa>
    panic("log.committing");
    8000458e:	00004517          	auipc	a0,0x4
    80004592:	1ba50513          	addi	a0,a0,442 # 80008748 <syscalls+0x1f8>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	f94080e7          	jalr	-108(ra) # 8000052a <panic>
    wakeup(&log);
    8000459e:	0001e497          	auipc	s1,0x1e
    800045a2:	ad248493          	addi	s1,s1,-1326 # 80022070 <log>
    800045a6:	8526                	mv	a0,s1
    800045a8:	ffffe097          	auipc	ra,0xffffe
    800045ac:	dc0080e7          	jalr	-576(ra) # 80002368 <wakeup>
  release(&log.lock);
    800045b0:	8526                	mv	a0,s1
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	6c4080e7          	jalr	1732(ra) # 80000c76 <release>
}
    800045ba:	70e2                	ld	ra,56(sp)
    800045bc:	7442                	ld	s0,48(sp)
    800045be:	74a2                	ld	s1,40(sp)
    800045c0:	7902                	ld	s2,32(sp)
    800045c2:	69e2                	ld	s3,24(sp)
    800045c4:	6a42                	ld	s4,16(sp)
    800045c6:	6aa2                	ld	s5,8(sp)
    800045c8:	6121                	addi	sp,sp,64
    800045ca:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045cc:	0001ea97          	auipc	s5,0x1e
    800045d0:	ad4a8a93          	addi	s5,s5,-1324 # 800220a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045d4:	0001ea17          	auipc	s4,0x1e
    800045d8:	a9ca0a13          	addi	s4,s4,-1380 # 80022070 <log>
    800045dc:	018a2583          	lw	a1,24(s4)
    800045e0:	012585bb          	addw	a1,a1,s2
    800045e4:	2585                	addiw	a1,a1,1
    800045e6:	028a2503          	lw	a0,40(s4)
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	ccc080e7          	jalr	-820(ra) # 800032b6 <bread>
    800045f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045f4:	000aa583          	lw	a1,0(s5)
    800045f8:	028a2503          	lw	a0,40(s4)
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	cba080e7          	jalr	-838(ra) # 800032b6 <bread>
    80004604:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004606:	40000613          	li	a2,1024
    8000460a:	05850593          	addi	a1,a0,88
    8000460e:	05848513          	addi	a0,s1,88
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	708080e7          	jalr	1800(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000461a:	8526                	mv	a0,s1
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	d8c080e7          	jalr	-628(ra) # 800033a8 <bwrite>
    brelse(from);
    80004624:	854e                	mv	a0,s3
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	dc0080e7          	jalr	-576(ra) # 800033e6 <brelse>
    brelse(to);
    8000462e:	8526                	mv	a0,s1
    80004630:	fffff097          	auipc	ra,0xfffff
    80004634:	db6080e7          	jalr	-586(ra) # 800033e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004638:	2905                	addiw	s2,s2,1
    8000463a:	0a91                	addi	s5,s5,4
    8000463c:	02ca2783          	lw	a5,44(s4)
    80004640:	f8f94ee3          	blt	s2,a5,800045dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004644:	00000097          	auipc	ra,0x0
    80004648:	c66080e7          	jalr	-922(ra) # 800042aa <write_head>
    install_trans(0); // Now install writes to home locations
    8000464c:	4501                	li	a0,0
    8000464e:	00000097          	auipc	ra,0x0
    80004652:	cd8080e7          	jalr	-808(ra) # 80004326 <install_trans>
    log.lh.n = 0;
    80004656:	0001e797          	auipc	a5,0x1e
    8000465a:	a407a323          	sw	zero,-1466(a5) # 8002209c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	c4c080e7          	jalr	-948(ra) # 800042aa <write_head>
    80004666:	bdf5                	j	80004562 <end_op+0x52>

0000000080004668 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004668:	1101                	addi	sp,sp,-32
    8000466a:	ec06                	sd	ra,24(sp)
    8000466c:	e822                	sd	s0,16(sp)
    8000466e:	e426                	sd	s1,8(sp)
    80004670:	e04a                	sd	s2,0(sp)
    80004672:	1000                	addi	s0,sp,32
    80004674:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004676:	0001e917          	auipc	s2,0x1e
    8000467a:	9fa90913          	addi	s2,s2,-1542 # 80022070 <log>
    8000467e:	854a                	mv	a0,s2
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	542080e7          	jalr	1346(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004688:	02c92603          	lw	a2,44(s2)
    8000468c:	47f5                	li	a5,29
    8000468e:	06c7c563          	blt	a5,a2,800046f8 <log_write+0x90>
    80004692:	0001e797          	auipc	a5,0x1e
    80004696:	9fa7a783          	lw	a5,-1542(a5) # 8002208c <log+0x1c>
    8000469a:	37fd                	addiw	a5,a5,-1
    8000469c:	04f65e63          	bge	a2,a5,800046f8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046a0:	0001e797          	auipc	a5,0x1e
    800046a4:	9f07a783          	lw	a5,-1552(a5) # 80022090 <log+0x20>
    800046a8:	06f05063          	blez	a5,80004708 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046ac:	4781                	li	a5,0
    800046ae:	06c05563          	blez	a2,80004718 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800046b2:	44cc                	lw	a1,12(s1)
    800046b4:	0001e717          	auipc	a4,0x1e
    800046b8:	9ec70713          	addi	a4,a4,-1556 # 800220a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800046be:	4314                	lw	a3,0(a4)
    800046c0:	04b68c63          	beq	a3,a1,80004718 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046c4:	2785                	addiw	a5,a5,1
    800046c6:	0711                	addi	a4,a4,4
    800046c8:	fef61be3          	bne	a2,a5,800046be <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046cc:	0621                	addi	a2,a2,8
    800046ce:	060a                	slli	a2,a2,0x2
    800046d0:	0001e797          	auipc	a5,0x1e
    800046d4:	9a078793          	addi	a5,a5,-1632 # 80022070 <log>
    800046d8:	963e                	add	a2,a2,a5
    800046da:	44dc                	lw	a5,12(s1)
    800046dc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046de:	8526                	mv	a0,s1
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	da4080e7          	jalr	-604(ra) # 80003484 <bpin>
    log.lh.n++;
    800046e8:	0001e717          	auipc	a4,0x1e
    800046ec:	98870713          	addi	a4,a4,-1656 # 80022070 <log>
    800046f0:	575c                	lw	a5,44(a4)
    800046f2:	2785                	addiw	a5,a5,1
    800046f4:	d75c                	sw	a5,44(a4)
    800046f6:	a835                	j	80004732 <log_write+0xca>
    panic("too big a transaction");
    800046f8:	00004517          	auipc	a0,0x4
    800046fc:	06050513          	addi	a0,a0,96 # 80008758 <syscalls+0x208>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	e2a080e7          	jalr	-470(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004708:	00004517          	auipc	a0,0x4
    8000470c:	06850513          	addi	a0,a0,104 # 80008770 <syscalls+0x220>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	e1a080e7          	jalr	-486(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004718:	00878713          	addi	a4,a5,8
    8000471c:	00271693          	slli	a3,a4,0x2
    80004720:	0001e717          	auipc	a4,0x1e
    80004724:	95070713          	addi	a4,a4,-1712 # 80022070 <log>
    80004728:	9736                	add	a4,a4,a3
    8000472a:	44d4                	lw	a3,12(s1)
    8000472c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000472e:	faf608e3          	beq	a2,a5,800046de <log_write+0x76>
  }
  release(&log.lock);
    80004732:	0001e517          	auipc	a0,0x1e
    80004736:	93e50513          	addi	a0,a0,-1730 # 80022070 <log>
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	53c080e7          	jalr	1340(ra) # 80000c76 <release>
}
    80004742:	60e2                	ld	ra,24(sp)
    80004744:	6442                	ld	s0,16(sp)
    80004746:	64a2                	ld	s1,8(sp)
    80004748:	6902                	ld	s2,0(sp)
    8000474a:	6105                	addi	sp,sp,32
    8000474c:	8082                	ret

000000008000474e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000474e:	1101                	addi	sp,sp,-32
    80004750:	ec06                	sd	ra,24(sp)
    80004752:	e822                	sd	s0,16(sp)
    80004754:	e426                	sd	s1,8(sp)
    80004756:	e04a                	sd	s2,0(sp)
    80004758:	1000                	addi	s0,sp,32
    8000475a:	84aa                	mv	s1,a0
    8000475c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000475e:	00004597          	auipc	a1,0x4
    80004762:	03258593          	addi	a1,a1,50 # 80008790 <syscalls+0x240>
    80004766:	0521                	addi	a0,a0,8
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	3ca080e7          	jalr	970(ra) # 80000b32 <initlock>
  lk->name = name;
    80004770:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004774:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004778:	0204a423          	sw	zero,40(s1)
}
    8000477c:	60e2                	ld	ra,24(sp)
    8000477e:	6442                	ld	s0,16(sp)
    80004780:	64a2                	ld	s1,8(sp)
    80004782:	6902                	ld	s2,0(sp)
    80004784:	6105                	addi	sp,sp,32
    80004786:	8082                	ret

0000000080004788 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004788:	1101                	addi	sp,sp,-32
    8000478a:	ec06                	sd	ra,24(sp)
    8000478c:	e822                	sd	s0,16(sp)
    8000478e:	e426                	sd	s1,8(sp)
    80004790:	e04a                	sd	s2,0(sp)
    80004792:	1000                	addi	s0,sp,32
    80004794:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004796:	00850913          	addi	s2,a0,8
    8000479a:	854a                	mv	a0,s2
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	426080e7          	jalr	1062(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800047a4:	409c                	lw	a5,0(s1)
    800047a6:	cb89                	beqz	a5,800047b8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047a8:	85ca                	mv	a1,s2
    800047aa:	8526                	mv	a0,s1
    800047ac:	ffffe097          	auipc	ra,0xffffe
    800047b0:	948080e7          	jalr	-1720(ra) # 800020f4 <sleep>
  while (lk->locked) {
    800047b4:	409c                	lw	a5,0(s1)
    800047b6:	fbed                	bnez	a5,800047a8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047b8:	4785                	li	a5,1
    800047ba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047bc:	ffffd097          	auipc	ra,0xffffd
    800047c0:	1c2080e7          	jalr	450(ra) # 8000197e <myproc>
    800047c4:	591c                	lw	a5,48(a0)
    800047c6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047c8:	854a                	mv	a0,s2
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	4ac080e7          	jalr	1196(ra) # 80000c76 <release>
}
    800047d2:	60e2                	ld	ra,24(sp)
    800047d4:	6442                	ld	s0,16(sp)
    800047d6:	64a2                	ld	s1,8(sp)
    800047d8:	6902                	ld	s2,0(sp)
    800047da:	6105                	addi	sp,sp,32
    800047dc:	8082                	ret

00000000800047de <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047de:	1101                	addi	sp,sp,-32
    800047e0:	ec06                	sd	ra,24(sp)
    800047e2:	e822                	sd	s0,16(sp)
    800047e4:	e426                	sd	s1,8(sp)
    800047e6:	e04a                	sd	s2,0(sp)
    800047e8:	1000                	addi	s0,sp,32
    800047ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ec:	00850913          	addi	s2,a0,8
    800047f0:	854a                	mv	a0,s2
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	3d0080e7          	jalr	976(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800047fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047fe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004802:	8526                	mv	a0,s1
    80004804:	ffffe097          	auipc	ra,0xffffe
    80004808:	b64080e7          	jalr	-1180(ra) # 80002368 <wakeup>
  release(&lk->lk);
    8000480c:	854a                	mv	a0,s2
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	468080e7          	jalr	1128(ra) # 80000c76 <release>
}
    80004816:	60e2                	ld	ra,24(sp)
    80004818:	6442                	ld	s0,16(sp)
    8000481a:	64a2                	ld	s1,8(sp)
    8000481c:	6902                	ld	s2,0(sp)
    8000481e:	6105                	addi	sp,sp,32
    80004820:	8082                	ret

0000000080004822 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004822:	7179                	addi	sp,sp,-48
    80004824:	f406                	sd	ra,40(sp)
    80004826:	f022                	sd	s0,32(sp)
    80004828:	ec26                	sd	s1,24(sp)
    8000482a:	e84a                	sd	s2,16(sp)
    8000482c:	e44e                	sd	s3,8(sp)
    8000482e:	1800                	addi	s0,sp,48
    80004830:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004832:	00850913          	addi	s2,a0,8
    80004836:	854a                	mv	a0,s2
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	38a080e7          	jalr	906(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004840:	409c                	lw	a5,0(s1)
    80004842:	ef99                	bnez	a5,80004860 <holdingsleep+0x3e>
    80004844:	4481                	li	s1,0
  release(&lk->lk);
    80004846:	854a                	mv	a0,s2
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	42e080e7          	jalr	1070(ra) # 80000c76 <release>
  return r;
}
    80004850:	8526                	mv	a0,s1
    80004852:	70a2                	ld	ra,40(sp)
    80004854:	7402                	ld	s0,32(sp)
    80004856:	64e2                	ld	s1,24(sp)
    80004858:	6942                	ld	s2,16(sp)
    8000485a:	69a2                	ld	s3,8(sp)
    8000485c:	6145                	addi	sp,sp,48
    8000485e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004860:	0284a983          	lw	s3,40(s1)
    80004864:	ffffd097          	auipc	ra,0xffffd
    80004868:	11a080e7          	jalr	282(ra) # 8000197e <myproc>
    8000486c:	5904                	lw	s1,48(a0)
    8000486e:	413484b3          	sub	s1,s1,s3
    80004872:	0014b493          	seqz	s1,s1
    80004876:	bfc1                	j	80004846 <holdingsleep+0x24>

0000000080004878 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004878:	1141                	addi	sp,sp,-16
    8000487a:	e406                	sd	ra,8(sp)
    8000487c:	e022                	sd	s0,0(sp)
    8000487e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004880:	00004597          	auipc	a1,0x4
    80004884:	f2058593          	addi	a1,a1,-224 # 800087a0 <syscalls+0x250>
    80004888:	0001e517          	auipc	a0,0x1e
    8000488c:	93050513          	addi	a0,a0,-1744 # 800221b8 <ftable>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	2a2080e7          	jalr	674(ra) # 80000b32 <initlock>
}
    80004898:	60a2                	ld	ra,8(sp)
    8000489a:	6402                	ld	s0,0(sp)
    8000489c:	0141                	addi	sp,sp,16
    8000489e:	8082                	ret

00000000800048a0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048a0:	1101                	addi	sp,sp,-32
    800048a2:	ec06                	sd	ra,24(sp)
    800048a4:	e822                	sd	s0,16(sp)
    800048a6:	e426                	sd	s1,8(sp)
    800048a8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048aa:	0001e517          	auipc	a0,0x1e
    800048ae:	90e50513          	addi	a0,a0,-1778 # 800221b8 <ftable>
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	310080e7          	jalr	784(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048ba:	0001e497          	auipc	s1,0x1e
    800048be:	91648493          	addi	s1,s1,-1770 # 800221d0 <ftable+0x18>
    800048c2:	0001f717          	auipc	a4,0x1f
    800048c6:	8ae70713          	addi	a4,a4,-1874 # 80023170 <ftable+0xfb8>
    if(f->ref == 0){
    800048ca:	40dc                	lw	a5,4(s1)
    800048cc:	cf99                	beqz	a5,800048ea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048ce:	02848493          	addi	s1,s1,40
    800048d2:	fee49ce3          	bne	s1,a4,800048ca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048d6:	0001e517          	auipc	a0,0x1e
    800048da:	8e250513          	addi	a0,a0,-1822 # 800221b8 <ftable>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	398080e7          	jalr	920(ra) # 80000c76 <release>
  return 0;
    800048e6:	4481                	li	s1,0
    800048e8:	a819                	j	800048fe <filealloc+0x5e>
      f->ref = 1;
    800048ea:	4785                	li	a5,1
    800048ec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048ee:	0001e517          	auipc	a0,0x1e
    800048f2:	8ca50513          	addi	a0,a0,-1846 # 800221b8 <ftable>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	380080e7          	jalr	896(ra) # 80000c76 <release>
}
    800048fe:	8526                	mv	a0,s1
    80004900:	60e2                	ld	ra,24(sp)
    80004902:	6442                	ld	s0,16(sp)
    80004904:	64a2                	ld	s1,8(sp)
    80004906:	6105                	addi	sp,sp,32
    80004908:	8082                	ret

000000008000490a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000490a:	1101                	addi	sp,sp,-32
    8000490c:	ec06                	sd	ra,24(sp)
    8000490e:	e822                	sd	s0,16(sp)
    80004910:	e426                	sd	s1,8(sp)
    80004912:	1000                	addi	s0,sp,32
    80004914:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004916:	0001e517          	auipc	a0,0x1e
    8000491a:	8a250513          	addi	a0,a0,-1886 # 800221b8 <ftable>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	2a4080e7          	jalr	676(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004926:	40dc                	lw	a5,4(s1)
    80004928:	02f05263          	blez	a5,8000494c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000492c:	2785                	addiw	a5,a5,1
    8000492e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004930:	0001e517          	auipc	a0,0x1e
    80004934:	88850513          	addi	a0,a0,-1912 # 800221b8 <ftable>
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	33e080e7          	jalr	830(ra) # 80000c76 <release>
  return f;
}
    80004940:	8526                	mv	a0,s1
    80004942:	60e2                	ld	ra,24(sp)
    80004944:	6442                	ld	s0,16(sp)
    80004946:	64a2                	ld	s1,8(sp)
    80004948:	6105                	addi	sp,sp,32
    8000494a:	8082                	ret
    panic("filedup");
    8000494c:	00004517          	auipc	a0,0x4
    80004950:	e5c50513          	addi	a0,a0,-420 # 800087a8 <syscalls+0x258>
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	bd6080e7          	jalr	-1066(ra) # 8000052a <panic>

000000008000495c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000495c:	7139                	addi	sp,sp,-64
    8000495e:	fc06                	sd	ra,56(sp)
    80004960:	f822                	sd	s0,48(sp)
    80004962:	f426                	sd	s1,40(sp)
    80004964:	f04a                	sd	s2,32(sp)
    80004966:	ec4e                	sd	s3,24(sp)
    80004968:	e852                	sd	s4,16(sp)
    8000496a:	e456                	sd	s5,8(sp)
    8000496c:	0080                	addi	s0,sp,64
    8000496e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004970:	0001e517          	auipc	a0,0x1e
    80004974:	84850513          	addi	a0,a0,-1976 # 800221b8 <ftable>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	24a080e7          	jalr	586(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004980:	40dc                	lw	a5,4(s1)
    80004982:	06f05163          	blez	a5,800049e4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004986:	37fd                	addiw	a5,a5,-1
    80004988:	0007871b          	sext.w	a4,a5
    8000498c:	c0dc                	sw	a5,4(s1)
    8000498e:	06e04363          	bgtz	a4,800049f4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004992:	0004a903          	lw	s2,0(s1)
    80004996:	0094ca83          	lbu	s5,9(s1)
    8000499a:	0104ba03          	ld	s4,16(s1)
    8000499e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049a2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049a6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049aa:	0001e517          	auipc	a0,0x1e
    800049ae:	80e50513          	addi	a0,a0,-2034 # 800221b8 <ftable>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	2c4080e7          	jalr	708(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800049ba:	4785                	li	a5,1
    800049bc:	04f90d63          	beq	s2,a5,80004a16 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049c0:	3979                	addiw	s2,s2,-2
    800049c2:	4785                	li	a5,1
    800049c4:	0527e063          	bltu	a5,s2,80004a04 <fileclose+0xa8>
    begin_op();
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	ac8080e7          	jalr	-1336(ra) # 80004490 <begin_op>
    iput(ff.ip);
    800049d0:	854e                	mv	a0,s3
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	2a2080e7          	jalr	674(ra) # 80003c74 <iput>
    end_op();
    800049da:	00000097          	auipc	ra,0x0
    800049de:	b36080e7          	jalr	-1226(ra) # 80004510 <end_op>
    800049e2:	a00d                	j	80004a04 <fileclose+0xa8>
    panic("fileclose");
    800049e4:	00004517          	auipc	a0,0x4
    800049e8:	dcc50513          	addi	a0,a0,-564 # 800087b0 <syscalls+0x260>
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	b3e080e7          	jalr	-1218(ra) # 8000052a <panic>
    release(&ftable.lock);
    800049f4:	0001d517          	auipc	a0,0x1d
    800049f8:	7c450513          	addi	a0,a0,1988 # 800221b8 <ftable>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	27a080e7          	jalr	634(ra) # 80000c76 <release>
  }
}
    80004a04:	70e2                	ld	ra,56(sp)
    80004a06:	7442                	ld	s0,48(sp)
    80004a08:	74a2                	ld	s1,40(sp)
    80004a0a:	7902                	ld	s2,32(sp)
    80004a0c:	69e2                	ld	s3,24(sp)
    80004a0e:	6a42                	ld	s4,16(sp)
    80004a10:	6aa2                	ld	s5,8(sp)
    80004a12:	6121                	addi	sp,sp,64
    80004a14:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a16:	85d6                	mv	a1,s5
    80004a18:	8552                	mv	a0,s4
    80004a1a:	00000097          	auipc	ra,0x0
    80004a1e:	34c080e7          	jalr	844(ra) # 80004d66 <pipeclose>
    80004a22:	b7cd                	j	80004a04 <fileclose+0xa8>

0000000080004a24 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a24:	715d                	addi	sp,sp,-80
    80004a26:	e486                	sd	ra,72(sp)
    80004a28:	e0a2                	sd	s0,64(sp)
    80004a2a:	fc26                	sd	s1,56(sp)
    80004a2c:	f84a                	sd	s2,48(sp)
    80004a2e:	f44e                	sd	s3,40(sp)
    80004a30:	0880                	addi	s0,sp,80
    80004a32:	84aa                	mv	s1,a0
    80004a34:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a36:	ffffd097          	auipc	ra,0xffffd
    80004a3a:	f48080e7          	jalr	-184(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a3e:	409c                	lw	a5,0(s1)
    80004a40:	37f9                	addiw	a5,a5,-2
    80004a42:	4705                	li	a4,1
    80004a44:	04f76763          	bltu	a4,a5,80004a92 <filestat+0x6e>
    80004a48:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a4a:	6c88                	ld	a0,24(s1)
    80004a4c:	fffff097          	auipc	ra,0xfffff
    80004a50:	06e080e7          	jalr	110(ra) # 80003aba <ilock>
    stati(f->ip, &st);
    80004a54:	fb840593          	addi	a1,s0,-72
    80004a58:	6c88                	ld	a0,24(s1)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	2ea080e7          	jalr	746(ra) # 80003d44 <stati>
    iunlock(f->ip);
    80004a62:	6c88                	ld	a0,24(s1)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	118080e7          	jalr	280(ra) # 80003b7c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a6c:	46e1                	li	a3,24
    80004a6e:	fb840613          	addi	a2,s0,-72
    80004a72:	85ce                	mv	a1,s3
    80004a74:	08893503          	ld	a0,136(s2)
    80004a78:	ffffd097          	auipc	ra,0xffffd
    80004a7c:	bc6080e7          	jalr	-1082(ra) # 8000163e <copyout>
    80004a80:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a84:	60a6                	ld	ra,72(sp)
    80004a86:	6406                	ld	s0,64(sp)
    80004a88:	74e2                	ld	s1,56(sp)
    80004a8a:	7942                	ld	s2,48(sp)
    80004a8c:	79a2                	ld	s3,40(sp)
    80004a8e:	6161                	addi	sp,sp,80
    80004a90:	8082                	ret
  return -1;
    80004a92:	557d                	li	a0,-1
    80004a94:	bfc5                	j	80004a84 <filestat+0x60>

0000000080004a96 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a96:	7179                	addi	sp,sp,-48
    80004a98:	f406                	sd	ra,40(sp)
    80004a9a:	f022                	sd	s0,32(sp)
    80004a9c:	ec26                	sd	s1,24(sp)
    80004a9e:	e84a                	sd	s2,16(sp)
    80004aa0:	e44e                	sd	s3,8(sp)
    80004aa2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004aa4:	00854783          	lbu	a5,8(a0)
    80004aa8:	c3d5                	beqz	a5,80004b4c <fileread+0xb6>
    80004aaa:	84aa                	mv	s1,a0
    80004aac:	89ae                	mv	s3,a1
    80004aae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ab0:	411c                	lw	a5,0(a0)
    80004ab2:	4705                	li	a4,1
    80004ab4:	04e78963          	beq	a5,a4,80004b06 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ab8:	470d                	li	a4,3
    80004aba:	04e78d63          	beq	a5,a4,80004b14 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004abe:	4709                	li	a4,2
    80004ac0:	06e79e63          	bne	a5,a4,80004b3c <fileread+0xa6>
    ilock(f->ip);
    80004ac4:	6d08                	ld	a0,24(a0)
    80004ac6:	fffff097          	auipc	ra,0xfffff
    80004aca:	ff4080e7          	jalr	-12(ra) # 80003aba <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ace:	874a                	mv	a4,s2
    80004ad0:	5094                	lw	a3,32(s1)
    80004ad2:	864e                	mv	a2,s3
    80004ad4:	4585                	li	a1,1
    80004ad6:	6c88                	ld	a0,24(s1)
    80004ad8:	fffff097          	auipc	ra,0xfffff
    80004adc:	296080e7          	jalr	662(ra) # 80003d6e <readi>
    80004ae0:	892a                	mv	s2,a0
    80004ae2:	00a05563          	blez	a0,80004aec <fileread+0x56>
      f->off += r;
    80004ae6:	509c                	lw	a5,32(s1)
    80004ae8:	9fa9                	addw	a5,a5,a0
    80004aea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004aec:	6c88                	ld	a0,24(s1)
    80004aee:	fffff097          	auipc	ra,0xfffff
    80004af2:	08e080e7          	jalr	142(ra) # 80003b7c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004af6:	854a                	mv	a0,s2
    80004af8:	70a2                	ld	ra,40(sp)
    80004afa:	7402                	ld	s0,32(sp)
    80004afc:	64e2                	ld	s1,24(sp)
    80004afe:	6942                	ld	s2,16(sp)
    80004b00:	69a2                	ld	s3,8(sp)
    80004b02:	6145                	addi	sp,sp,48
    80004b04:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b06:	6908                	ld	a0,16(a0)
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	3c0080e7          	jalr	960(ra) # 80004ec8 <piperead>
    80004b10:	892a                	mv	s2,a0
    80004b12:	b7d5                	j	80004af6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b14:	02451783          	lh	a5,36(a0)
    80004b18:	03079693          	slli	a3,a5,0x30
    80004b1c:	92c1                	srli	a3,a3,0x30
    80004b1e:	4725                	li	a4,9
    80004b20:	02d76863          	bltu	a4,a3,80004b50 <fileread+0xba>
    80004b24:	0792                	slli	a5,a5,0x4
    80004b26:	0001d717          	auipc	a4,0x1d
    80004b2a:	5f270713          	addi	a4,a4,1522 # 80022118 <devsw>
    80004b2e:	97ba                	add	a5,a5,a4
    80004b30:	639c                	ld	a5,0(a5)
    80004b32:	c38d                	beqz	a5,80004b54 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b34:	4505                	li	a0,1
    80004b36:	9782                	jalr	a5
    80004b38:	892a                	mv	s2,a0
    80004b3a:	bf75                	j	80004af6 <fileread+0x60>
    panic("fileread");
    80004b3c:	00004517          	auipc	a0,0x4
    80004b40:	c8450513          	addi	a0,a0,-892 # 800087c0 <syscalls+0x270>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	9e6080e7          	jalr	-1562(ra) # 8000052a <panic>
    return -1;
    80004b4c:	597d                	li	s2,-1
    80004b4e:	b765                	j	80004af6 <fileread+0x60>
      return -1;
    80004b50:	597d                	li	s2,-1
    80004b52:	b755                	j	80004af6 <fileread+0x60>
    80004b54:	597d                	li	s2,-1
    80004b56:	b745                	j	80004af6 <fileread+0x60>

0000000080004b58 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b58:	715d                	addi	sp,sp,-80
    80004b5a:	e486                	sd	ra,72(sp)
    80004b5c:	e0a2                	sd	s0,64(sp)
    80004b5e:	fc26                	sd	s1,56(sp)
    80004b60:	f84a                	sd	s2,48(sp)
    80004b62:	f44e                	sd	s3,40(sp)
    80004b64:	f052                	sd	s4,32(sp)
    80004b66:	ec56                	sd	s5,24(sp)
    80004b68:	e85a                	sd	s6,16(sp)
    80004b6a:	e45e                	sd	s7,8(sp)
    80004b6c:	e062                	sd	s8,0(sp)
    80004b6e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b70:	00954783          	lbu	a5,9(a0)
    80004b74:	10078663          	beqz	a5,80004c80 <filewrite+0x128>
    80004b78:	892a                	mv	s2,a0
    80004b7a:	8aae                	mv	s5,a1
    80004b7c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b7e:	411c                	lw	a5,0(a0)
    80004b80:	4705                	li	a4,1
    80004b82:	02e78263          	beq	a5,a4,80004ba6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b86:	470d                	li	a4,3
    80004b88:	02e78663          	beq	a5,a4,80004bb4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b8c:	4709                	li	a4,2
    80004b8e:	0ee79163          	bne	a5,a4,80004c70 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b92:	0ac05d63          	blez	a2,80004c4c <filewrite+0xf4>
    int i = 0;
    80004b96:	4981                	li	s3,0
    80004b98:	6b05                	lui	s6,0x1
    80004b9a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b9e:	6b85                	lui	s7,0x1
    80004ba0:	c00b8b9b          	addiw	s7,s7,-1024
    80004ba4:	a861                	j	80004c3c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ba6:	6908                	ld	a0,16(a0)
    80004ba8:	00000097          	auipc	ra,0x0
    80004bac:	22e080e7          	jalr	558(ra) # 80004dd6 <pipewrite>
    80004bb0:	8a2a                	mv	s4,a0
    80004bb2:	a045                	j	80004c52 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bb4:	02451783          	lh	a5,36(a0)
    80004bb8:	03079693          	slli	a3,a5,0x30
    80004bbc:	92c1                	srli	a3,a3,0x30
    80004bbe:	4725                	li	a4,9
    80004bc0:	0cd76263          	bltu	a4,a3,80004c84 <filewrite+0x12c>
    80004bc4:	0792                	slli	a5,a5,0x4
    80004bc6:	0001d717          	auipc	a4,0x1d
    80004bca:	55270713          	addi	a4,a4,1362 # 80022118 <devsw>
    80004bce:	97ba                	add	a5,a5,a4
    80004bd0:	679c                	ld	a5,8(a5)
    80004bd2:	cbdd                	beqz	a5,80004c88 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bd4:	4505                	li	a0,1
    80004bd6:	9782                	jalr	a5
    80004bd8:	8a2a                	mv	s4,a0
    80004bda:	a8a5                	j	80004c52 <filewrite+0xfa>
    80004bdc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	8b0080e7          	jalr	-1872(ra) # 80004490 <begin_op>
      ilock(f->ip);
    80004be8:	01893503          	ld	a0,24(s2)
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	ece080e7          	jalr	-306(ra) # 80003aba <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004bf4:	8762                	mv	a4,s8
    80004bf6:	02092683          	lw	a3,32(s2)
    80004bfa:	01598633          	add	a2,s3,s5
    80004bfe:	4585                	li	a1,1
    80004c00:	01893503          	ld	a0,24(s2)
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	262080e7          	jalr	610(ra) # 80003e66 <writei>
    80004c0c:	84aa                	mv	s1,a0
    80004c0e:	00a05763          	blez	a0,80004c1c <filewrite+0xc4>
        f->off += r;
    80004c12:	02092783          	lw	a5,32(s2)
    80004c16:	9fa9                	addw	a5,a5,a0
    80004c18:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c1c:	01893503          	ld	a0,24(s2)
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	f5c080e7          	jalr	-164(ra) # 80003b7c <iunlock>
      end_op();
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	8e8080e7          	jalr	-1816(ra) # 80004510 <end_op>

      if(r != n1){
    80004c30:	009c1f63          	bne	s8,s1,80004c4e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c34:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c38:	0149db63          	bge	s3,s4,80004c4e <filewrite+0xf6>
      int n1 = n - i;
    80004c3c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c40:	84be                	mv	s1,a5
    80004c42:	2781                	sext.w	a5,a5
    80004c44:	f8fb5ce3          	bge	s6,a5,80004bdc <filewrite+0x84>
    80004c48:	84de                	mv	s1,s7
    80004c4a:	bf49                	j	80004bdc <filewrite+0x84>
    int i = 0;
    80004c4c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c4e:	013a1f63          	bne	s4,s3,80004c6c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c52:	8552                	mv	a0,s4
    80004c54:	60a6                	ld	ra,72(sp)
    80004c56:	6406                	ld	s0,64(sp)
    80004c58:	74e2                	ld	s1,56(sp)
    80004c5a:	7942                	ld	s2,48(sp)
    80004c5c:	79a2                	ld	s3,40(sp)
    80004c5e:	7a02                	ld	s4,32(sp)
    80004c60:	6ae2                	ld	s5,24(sp)
    80004c62:	6b42                	ld	s6,16(sp)
    80004c64:	6ba2                	ld	s7,8(sp)
    80004c66:	6c02                	ld	s8,0(sp)
    80004c68:	6161                	addi	sp,sp,80
    80004c6a:	8082                	ret
    ret = (i == n ? n : -1);
    80004c6c:	5a7d                	li	s4,-1
    80004c6e:	b7d5                	j	80004c52 <filewrite+0xfa>
    panic("filewrite");
    80004c70:	00004517          	auipc	a0,0x4
    80004c74:	b6050513          	addi	a0,a0,-1184 # 800087d0 <syscalls+0x280>
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	8b2080e7          	jalr	-1870(ra) # 8000052a <panic>
    return -1;
    80004c80:	5a7d                	li	s4,-1
    80004c82:	bfc1                	j	80004c52 <filewrite+0xfa>
      return -1;
    80004c84:	5a7d                	li	s4,-1
    80004c86:	b7f1                	j	80004c52 <filewrite+0xfa>
    80004c88:	5a7d                	li	s4,-1
    80004c8a:	b7e1                	j	80004c52 <filewrite+0xfa>

0000000080004c8c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c8c:	7179                	addi	sp,sp,-48
    80004c8e:	f406                	sd	ra,40(sp)
    80004c90:	f022                	sd	s0,32(sp)
    80004c92:	ec26                	sd	s1,24(sp)
    80004c94:	e84a                	sd	s2,16(sp)
    80004c96:	e44e                	sd	s3,8(sp)
    80004c98:	e052                	sd	s4,0(sp)
    80004c9a:	1800                	addi	s0,sp,48
    80004c9c:	84aa                	mv	s1,a0
    80004c9e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ca0:	0005b023          	sd	zero,0(a1)
    80004ca4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ca8:	00000097          	auipc	ra,0x0
    80004cac:	bf8080e7          	jalr	-1032(ra) # 800048a0 <filealloc>
    80004cb0:	e088                	sd	a0,0(s1)
    80004cb2:	c551                	beqz	a0,80004d3e <pipealloc+0xb2>
    80004cb4:	00000097          	auipc	ra,0x0
    80004cb8:	bec080e7          	jalr	-1044(ra) # 800048a0 <filealloc>
    80004cbc:	00aa3023          	sd	a0,0(s4)
    80004cc0:	c92d                	beqz	a0,80004d32 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	e10080e7          	jalr	-496(ra) # 80000ad2 <kalloc>
    80004cca:	892a                	mv	s2,a0
    80004ccc:	c125                	beqz	a0,80004d2c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cce:	4985                	li	s3,1
    80004cd0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cd4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cd8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cdc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ce0:	00003597          	auipc	a1,0x3
    80004ce4:	7a858593          	addi	a1,a1,1960 # 80008488 <states.0+0x1e0>
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	e4a080e7          	jalr	-438(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004cf0:	609c                	ld	a5,0(s1)
    80004cf2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004cf6:	609c                	ld	a5,0(s1)
    80004cf8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004cfc:	609c                	ld	a5,0(s1)
    80004cfe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d02:	609c                	ld	a5,0(s1)
    80004d04:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d08:	000a3783          	ld	a5,0(s4)
    80004d0c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d10:	000a3783          	ld	a5,0(s4)
    80004d14:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d18:	000a3783          	ld	a5,0(s4)
    80004d1c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d20:	000a3783          	ld	a5,0(s4)
    80004d24:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d28:	4501                	li	a0,0
    80004d2a:	a025                	j	80004d52 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d2c:	6088                	ld	a0,0(s1)
    80004d2e:	e501                	bnez	a0,80004d36 <pipealloc+0xaa>
    80004d30:	a039                	j	80004d3e <pipealloc+0xb2>
    80004d32:	6088                	ld	a0,0(s1)
    80004d34:	c51d                	beqz	a0,80004d62 <pipealloc+0xd6>
    fileclose(*f0);
    80004d36:	00000097          	auipc	ra,0x0
    80004d3a:	c26080e7          	jalr	-986(ra) # 8000495c <fileclose>
  if(*f1)
    80004d3e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d42:	557d                	li	a0,-1
  if(*f1)
    80004d44:	c799                	beqz	a5,80004d52 <pipealloc+0xc6>
    fileclose(*f1);
    80004d46:	853e                	mv	a0,a5
    80004d48:	00000097          	auipc	ra,0x0
    80004d4c:	c14080e7          	jalr	-1004(ra) # 8000495c <fileclose>
  return -1;
    80004d50:	557d                	li	a0,-1
}
    80004d52:	70a2                	ld	ra,40(sp)
    80004d54:	7402                	ld	s0,32(sp)
    80004d56:	64e2                	ld	s1,24(sp)
    80004d58:	6942                	ld	s2,16(sp)
    80004d5a:	69a2                	ld	s3,8(sp)
    80004d5c:	6a02                	ld	s4,0(sp)
    80004d5e:	6145                	addi	sp,sp,48
    80004d60:	8082                	ret
  return -1;
    80004d62:	557d                	li	a0,-1
    80004d64:	b7fd                	j	80004d52 <pipealloc+0xc6>

0000000080004d66 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d66:	1101                	addi	sp,sp,-32
    80004d68:	ec06                	sd	ra,24(sp)
    80004d6a:	e822                	sd	s0,16(sp)
    80004d6c:	e426                	sd	s1,8(sp)
    80004d6e:	e04a                	sd	s2,0(sp)
    80004d70:	1000                	addi	s0,sp,32
    80004d72:	84aa                	mv	s1,a0
    80004d74:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	e4c080e7          	jalr	-436(ra) # 80000bc2 <acquire>
  if(writable){
    80004d7e:	02090d63          	beqz	s2,80004db8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d82:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d86:	21848513          	addi	a0,s1,536
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	5de080e7          	jalr	1502(ra) # 80002368 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d92:	2204b783          	ld	a5,544(s1)
    80004d96:	eb95                	bnez	a5,80004dca <pipeclose+0x64>
    release(&pi->lock);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	edc080e7          	jalr	-292(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	c32080e7          	jalr	-974(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004dac:	60e2                	ld	ra,24(sp)
    80004dae:	6442                	ld	s0,16(sp)
    80004db0:	64a2                	ld	s1,8(sp)
    80004db2:	6902                	ld	s2,0(sp)
    80004db4:	6105                	addi	sp,sp,32
    80004db6:	8082                	ret
    pi->readopen = 0;
    80004db8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004dbc:	21c48513          	addi	a0,s1,540
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	5a8080e7          	jalr	1448(ra) # 80002368 <wakeup>
    80004dc8:	b7e9                	j	80004d92 <pipeclose+0x2c>
    release(&pi->lock);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	eaa080e7          	jalr	-342(ra) # 80000c76 <release>
}
    80004dd4:	bfe1                	j	80004dac <pipeclose+0x46>

0000000080004dd6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dd6:	711d                	addi	sp,sp,-96
    80004dd8:	ec86                	sd	ra,88(sp)
    80004dda:	e8a2                	sd	s0,80(sp)
    80004ddc:	e4a6                	sd	s1,72(sp)
    80004dde:	e0ca                	sd	s2,64(sp)
    80004de0:	fc4e                	sd	s3,56(sp)
    80004de2:	f852                	sd	s4,48(sp)
    80004de4:	f456                	sd	s5,40(sp)
    80004de6:	f05a                	sd	s6,32(sp)
    80004de8:	ec5e                	sd	s7,24(sp)
    80004dea:	e862                	sd	s8,16(sp)
    80004dec:	1080                	addi	s0,sp,96
    80004dee:	84aa                	mv	s1,a0
    80004df0:	8aae                	mv	s5,a1
    80004df2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	b8a080e7          	jalr	-1142(ra) # 8000197e <myproc>
    80004dfc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004dfe:	8526                	mv	a0,s1
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	dc2080e7          	jalr	-574(ra) # 80000bc2 <acquire>
  while(i < n){
    80004e08:	0b405363          	blez	s4,80004eae <pipewrite+0xd8>
  int i = 0;
    80004e0c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e0e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e10:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e14:	21c48b93          	addi	s7,s1,540
    80004e18:	a089                	j	80004e5a <pipewrite+0x84>
      release(&pi->lock);
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	e5a080e7          	jalr	-422(ra) # 80000c76 <release>
      return -1;
    80004e24:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e26:	854a                	mv	a0,s2
    80004e28:	60e6                	ld	ra,88(sp)
    80004e2a:	6446                	ld	s0,80(sp)
    80004e2c:	64a6                	ld	s1,72(sp)
    80004e2e:	6906                	ld	s2,64(sp)
    80004e30:	79e2                	ld	s3,56(sp)
    80004e32:	7a42                	ld	s4,48(sp)
    80004e34:	7aa2                	ld	s5,40(sp)
    80004e36:	7b02                	ld	s6,32(sp)
    80004e38:	6be2                	ld	s7,24(sp)
    80004e3a:	6c42                	ld	s8,16(sp)
    80004e3c:	6125                	addi	sp,sp,96
    80004e3e:	8082                	ret
      wakeup(&pi->nread);
    80004e40:	8562                	mv	a0,s8
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	526080e7          	jalr	1318(ra) # 80002368 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e4a:	85a6                	mv	a1,s1
    80004e4c:	855e                	mv	a0,s7
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	2a6080e7          	jalr	678(ra) # 800020f4 <sleep>
  while(i < n){
    80004e56:	05495d63          	bge	s2,s4,80004eb0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004e5a:	2204a783          	lw	a5,544(s1)
    80004e5e:	dfd5                	beqz	a5,80004e1a <pipewrite+0x44>
    80004e60:	0289a783          	lw	a5,40(s3)
    80004e64:	fbdd                	bnez	a5,80004e1a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e66:	2184a783          	lw	a5,536(s1)
    80004e6a:	21c4a703          	lw	a4,540(s1)
    80004e6e:	2007879b          	addiw	a5,a5,512
    80004e72:	fcf707e3          	beq	a4,a5,80004e40 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e76:	4685                	li	a3,1
    80004e78:	01590633          	add	a2,s2,s5
    80004e7c:	faf40593          	addi	a1,s0,-81
    80004e80:	0889b503          	ld	a0,136(s3)
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	846080e7          	jalr	-1978(ra) # 800016ca <copyin>
    80004e8c:	03650263          	beq	a0,s6,80004eb0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e90:	21c4a783          	lw	a5,540(s1)
    80004e94:	0017871b          	addiw	a4,a5,1
    80004e98:	20e4ae23          	sw	a4,540(s1)
    80004e9c:	1ff7f793          	andi	a5,a5,511
    80004ea0:	97a6                	add	a5,a5,s1
    80004ea2:	faf44703          	lbu	a4,-81(s0)
    80004ea6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004eaa:	2905                	addiw	s2,s2,1
    80004eac:	b76d                	j	80004e56 <pipewrite+0x80>
  int i = 0;
    80004eae:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004eb0:	21848513          	addi	a0,s1,536
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	4b4080e7          	jalr	1204(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	db8080e7          	jalr	-584(ra) # 80000c76 <release>
  return i;
    80004ec6:	b785                	j	80004e26 <pipewrite+0x50>

0000000080004ec8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ec8:	715d                	addi	sp,sp,-80
    80004eca:	e486                	sd	ra,72(sp)
    80004ecc:	e0a2                	sd	s0,64(sp)
    80004ece:	fc26                	sd	s1,56(sp)
    80004ed0:	f84a                	sd	s2,48(sp)
    80004ed2:	f44e                	sd	s3,40(sp)
    80004ed4:	f052                	sd	s4,32(sp)
    80004ed6:	ec56                	sd	s5,24(sp)
    80004ed8:	e85a                	sd	s6,16(sp)
    80004eda:	0880                	addi	s0,sp,80
    80004edc:	84aa                	mv	s1,a0
    80004ede:	892e                	mv	s2,a1
    80004ee0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	a9c080e7          	jalr	-1380(ra) # 8000197e <myproc>
    80004eea:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004eec:	8526                	mv	a0,s1
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	cd4080e7          	jalr	-812(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ef6:	2184a703          	lw	a4,536(s1)
    80004efa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004efe:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f02:	02f71463          	bne	a4,a5,80004f2a <piperead+0x62>
    80004f06:	2244a783          	lw	a5,548(s1)
    80004f0a:	c385                	beqz	a5,80004f2a <piperead+0x62>
    if(pr->killed){
    80004f0c:	028a2783          	lw	a5,40(s4)
    80004f10:	ebc1                	bnez	a5,80004fa0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f12:	85a6                	mv	a1,s1
    80004f14:	854e                	mv	a0,s3
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	1de080e7          	jalr	478(ra) # 800020f4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f1e:	2184a703          	lw	a4,536(s1)
    80004f22:	21c4a783          	lw	a5,540(s1)
    80004f26:	fef700e3          	beq	a4,a5,80004f06 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f2a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f2c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f2e:	05505363          	blez	s5,80004f74 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004f32:	2184a783          	lw	a5,536(s1)
    80004f36:	21c4a703          	lw	a4,540(s1)
    80004f3a:	02f70d63          	beq	a4,a5,80004f74 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f3e:	0017871b          	addiw	a4,a5,1
    80004f42:	20e4ac23          	sw	a4,536(s1)
    80004f46:	1ff7f793          	andi	a5,a5,511
    80004f4a:	97a6                	add	a5,a5,s1
    80004f4c:	0187c783          	lbu	a5,24(a5)
    80004f50:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f54:	4685                	li	a3,1
    80004f56:	fbf40613          	addi	a2,s0,-65
    80004f5a:	85ca                	mv	a1,s2
    80004f5c:	088a3503          	ld	a0,136(s4)
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	6de080e7          	jalr	1758(ra) # 8000163e <copyout>
    80004f68:	01650663          	beq	a0,s6,80004f74 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f6c:	2985                	addiw	s3,s3,1
    80004f6e:	0905                	addi	s2,s2,1
    80004f70:	fd3a91e3          	bne	s5,s3,80004f32 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f74:	21c48513          	addi	a0,s1,540
    80004f78:	ffffd097          	auipc	ra,0xffffd
    80004f7c:	3f0080e7          	jalr	1008(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004f80:	8526                	mv	a0,s1
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	cf4080e7          	jalr	-780(ra) # 80000c76 <release>
  return i;
}
    80004f8a:	854e                	mv	a0,s3
    80004f8c:	60a6                	ld	ra,72(sp)
    80004f8e:	6406                	ld	s0,64(sp)
    80004f90:	74e2                	ld	s1,56(sp)
    80004f92:	7942                	ld	s2,48(sp)
    80004f94:	79a2                	ld	s3,40(sp)
    80004f96:	7a02                	ld	s4,32(sp)
    80004f98:	6ae2                	ld	s5,24(sp)
    80004f9a:	6b42                	ld	s6,16(sp)
    80004f9c:	6161                	addi	sp,sp,80
    80004f9e:	8082                	ret
      release(&pi->lock);
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	cd4080e7          	jalr	-812(ra) # 80000c76 <release>
      return -1;
    80004faa:	59fd                	li	s3,-1
    80004fac:	bff9                	j	80004f8a <piperead+0xc2>

0000000080004fae <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fae:	de010113          	addi	sp,sp,-544
    80004fb2:	20113c23          	sd	ra,536(sp)
    80004fb6:	20813823          	sd	s0,528(sp)
    80004fba:	20913423          	sd	s1,520(sp)
    80004fbe:	21213023          	sd	s2,512(sp)
    80004fc2:	ffce                	sd	s3,504(sp)
    80004fc4:	fbd2                	sd	s4,496(sp)
    80004fc6:	f7d6                	sd	s5,488(sp)
    80004fc8:	f3da                	sd	s6,480(sp)
    80004fca:	efde                	sd	s7,472(sp)
    80004fcc:	ebe2                	sd	s8,464(sp)
    80004fce:	e7e6                	sd	s9,456(sp)
    80004fd0:	e3ea                	sd	s10,448(sp)
    80004fd2:	ff6e                	sd	s11,440(sp)
    80004fd4:	1400                	addi	s0,sp,544
    80004fd6:	892a                	mv	s2,a0
    80004fd8:	dea43423          	sd	a0,-536(s0)
    80004fdc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	99e080e7          	jalr	-1634(ra) # 8000197e <myproc>
    80004fe8:	84aa                	mv	s1,a0

  begin_op();
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	4a6080e7          	jalr	1190(ra) # 80004490 <begin_op>

  if((ip = namei(path)) == 0){
    80004ff2:	854a                	mv	a0,s2
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	27c080e7          	jalr	636(ra) # 80004270 <namei>
    80004ffc:	c93d                	beqz	a0,80005072 <exec+0xc4>
    80004ffe:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	aba080e7          	jalr	-1350(ra) # 80003aba <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005008:	04000713          	li	a4,64
    8000500c:	4681                	li	a3,0
    8000500e:	e4840613          	addi	a2,s0,-440
    80005012:	4581                	li	a1,0
    80005014:	8556                	mv	a0,s5
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	d58080e7          	jalr	-680(ra) # 80003d6e <readi>
    8000501e:	04000793          	li	a5,64
    80005022:	00f51a63          	bne	a0,a5,80005036 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005026:	e4842703          	lw	a4,-440(s0)
    8000502a:	464c47b7          	lui	a5,0x464c4
    8000502e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005032:	04f70663          	beq	a4,a5,8000507e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005036:	8556                	mv	a0,s5
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	ce4080e7          	jalr	-796(ra) # 80003d1c <iunlockput>
    end_op();
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	4d0080e7          	jalr	1232(ra) # 80004510 <end_op>
  }
  return -1;
    80005048:	557d                	li	a0,-1
}
    8000504a:	21813083          	ld	ra,536(sp)
    8000504e:	21013403          	ld	s0,528(sp)
    80005052:	20813483          	ld	s1,520(sp)
    80005056:	20013903          	ld	s2,512(sp)
    8000505a:	79fe                	ld	s3,504(sp)
    8000505c:	7a5e                	ld	s4,496(sp)
    8000505e:	7abe                	ld	s5,488(sp)
    80005060:	7b1e                	ld	s6,480(sp)
    80005062:	6bfe                	ld	s7,472(sp)
    80005064:	6c5e                	ld	s8,464(sp)
    80005066:	6cbe                	ld	s9,456(sp)
    80005068:	6d1e                	ld	s10,448(sp)
    8000506a:	7dfa                	ld	s11,440(sp)
    8000506c:	22010113          	addi	sp,sp,544
    80005070:	8082                	ret
    end_op();
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	49e080e7          	jalr	1182(ra) # 80004510 <end_op>
    return -1;
    8000507a:	557d                	li	a0,-1
    8000507c:	b7f9                	j	8000504a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000507e:	8526                	mv	a0,s1
    80005080:	ffffd097          	auipc	ra,0xffffd
    80005084:	9c2080e7          	jalr	-1598(ra) # 80001a42 <proc_pagetable>
    80005088:	8b2a                	mv	s6,a0
    8000508a:	d555                	beqz	a0,80005036 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000508c:	e6842783          	lw	a5,-408(s0)
    80005090:	e8045703          	lhu	a4,-384(s0)
    80005094:	c735                	beqz	a4,80005100 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005096:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005098:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000509c:	6a05                	lui	s4,0x1
    8000509e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050a2:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800050a6:	6d85                	lui	s11,0x1
    800050a8:	7d7d                	lui	s10,0xfffff
    800050aa:	ac1d                	j	800052e0 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050ac:	00003517          	auipc	a0,0x3
    800050b0:	73450513          	addi	a0,a0,1844 # 800087e0 <syscalls+0x290>
    800050b4:	ffffb097          	auipc	ra,0xffffb
    800050b8:	476080e7          	jalr	1142(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050bc:	874a                	mv	a4,s2
    800050be:	009c86bb          	addw	a3,s9,s1
    800050c2:	4581                	li	a1,0
    800050c4:	8556                	mv	a0,s5
    800050c6:	fffff097          	auipc	ra,0xfffff
    800050ca:	ca8080e7          	jalr	-856(ra) # 80003d6e <readi>
    800050ce:	2501                	sext.w	a0,a0
    800050d0:	1aa91863          	bne	s2,a0,80005280 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800050d4:	009d84bb          	addw	s1,s11,s1
    800050d8:	013d09bb          	addw	s3,s10,s3
    800050dc:	1f74f263          	bgeu	s1,s7,800052c0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800050e0:	02049593          	slli	a1,s1,0x20
    800050e4:	9181                	srli	a1,a1,0x20
    800050e6:	95e2                	add	a1,a1,s8
    800050e8:	855a                	mv	a0,s6
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	f62080e7          	jalr	-158(ra) # 8000104c <walkaddr>
    800050f2:	862a                	mv	a2,a0
    if(pa == 0)
    800050f4:	dd45                	beqz	a0,800050ac <exec+0xfe>
      n = PGSIZE;
    800050f6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800050f8:	fd49f2e3          	bgeu	s3,s4,800050bc <exec+0x10e>
      n = sz - i;
    800050fc:	894e                	mv	s2,s3
    800050fe:	bf7d                	j	800050bc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005100:	4481                	li	s1,0
  iunlockput(ip);
    80005102:	8556                	mv	a0,s5
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	c18080e7          	jalr	-1000(ra) # 80003d1c <iunlockput>
  end_op();
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	404080e7          	jalr	1028(ra) # 80004510 <end_op>
  p = myproc();
    80005114:	ffffd097          	auipc	ra,0xffffd
    80005118:	86a080e7          	jalr	-1942(ra) # 8000197e <myproc>
    8000511c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000511e:	08053d03          	ld	s10,128(a0)
  sz = PGROUNDUP(sz);
    80005122:	6785                	lui	a5,0x1
    80005124:	17fd                	addi	a5,a5,-1
    80005126:	94be                	add	s1,s1,a5
    80005128:	77fd                	lui	a5,0xfffff
    8000512a:	8fe5                	and	a5,a5,s1
    8000512c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005130:	6609                	lui	a2,0x2
    80005132:	963e                	add	a2,a2,a5
    80005134:	85be                	mv	a1,a5
    80005136:	855a                	mv	a0,s6
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	2b6080e7          	jalr	694(ra) # 800013ee <uvmalloc>
    80005140:	8c2a                	mv	s8,a0
  ip = 0;
    80005142:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005144:	12050e63          	beqz	a0,80005280 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005148:	75f9                	lui	a1,0xffffe
    8000514a:	95aa                	add	a1,a1,a0
    8000514c:	855a                	mv	a0,s6
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	4be080e7          	jalr	1214(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80005156:	7afd                	lui	s5,0xfffff
    80005158:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000515a:	df043783          	ld	a5,-528(s0)
    8000515e:	6388                	ld	a0,0(a5)
    80005160:	c925                	beqz	a0,800051d0 <exec+0x222>
    80005162:	e8840993          	addi	s3,s0,-376
    80005166:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000516a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000516c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	cd4080e7          	jalr	-812(ra) # 80000e42 <strlen>
    80005176:	0015079b          	addiw	a5,a0,1
    8000517a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000517e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005182:	13596363          	bltu	s2,s5,800052a8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005186:	df043d83          	ld	s11,-528(s0)
    8000518a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000518e:	8552                	mv	a0,s4
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	cb2080e7          	jalr	-846(ra) # 80000e42 <strlen>
    80005198:	0015069b          	addiw	a3,a0,1
    8000519c:	8652                	mv	a2,s4
    8000519e:	85ca                	mv	a1,s2
    800051a0:	855a                	mv	a0,s6
    800051a2:	ffffc097          	auipc	ra,0xffffc
    800051a6:	49c080e7          	jalr	1180(ra) # 8000163e <copyout>
    800051aa:	10054363          	bltz	a0,800052b0 <exec+0x302>
    ustack[argc] = sp;
    800051ae:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051b2:	0485                	addi	s1,s1,1
    800051b4:	008d8793          	addi	a5,s11,8
    800051b8:	def43823          	sd	a5,-528(s0)
    800051bc:	008db503          	ld	a0,8(s11)
    800051c0:	c911                	beqz	a0,800051d4 <exec+0x226>
    if(argc >= MAXARG)
    800051c2:	09a1                	addi	s3,s3,8
    800051c4:	fb3c95e3          	bne	s9,s3,8000516e <exec+0x1c0>
  sz = sz1;
    800051c8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051cc:	4a81                	li	s5,0
    800051ce:	a84d                	j	80005280 <exec+0x2d2>
  sp = sz;
    800051d0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051d2:	4481                	li	s1,0
  ustack[argc] = 0;
    800051d4:	00349793          	slli	a5,s1,0x3
    800051d8:	f9040713          	addi	a4,s0,-112
    800051dc:	97ba                	add	a5,a5,a4
    800051de:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800051e2:	00148693          	addi	a3,s1,1
    800051e6:	068e                	slli	a3,a3,0x3
    800051e8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051ec:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051f0:	01597663          	bgeu	s2,s5,800051fc <exec+0x24e>
  sz = sz1;
    800051f4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051f8:	4a81                	li	s5,0
    800051fa:	a059                	j	80005280 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051fc:	e8840613          	addi	a2,s0,-376
    80005200:	85ca                	mv	a1,s2
    80005202:	855a                	mv	a0,s6
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	43a080e7          	jalr	1082(ra) # 8000163e <copyout>
    8000520c:	0a054663          	bltz	a0,800052b8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005210:	090bb783          	ld	a5,144(s7) # 1090 <_entry-0x7fffef70>
    80005214:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005218:	de843783          	ld	a5,-536(s0)
    8000521c:	0007c703          	lbu	a4,0(a5)
    80005220:	cf11                	beqz	a4,8000523c <exec+0x28e>
    80005222:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005224:	02f00693          	li	a3,47
    80005228:	a039                	j	80005236 <exec+0x288>
      last = s+1;
    8000522a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000522e:	0785                	addi	a5,a5,1
    80005230:	fff7c703          	lbu	a4,-1(a5)
    80005234:	c701                	beqz	a4,8000523c <exec+0x28e>
    if(*s == '/')
    80005236:	fed71ce3          	bne	a4,a3,8000522e <exec+0x280>
    8000523a:	bfc5                	j	8000522a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000523c:	4641                	li	a2,16
    8000523e:	de843583          	ld	a1,-536(s0)
    80005242:	190b8513          	addi	a0,s7,400
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	bca080e7          	jalr	-1078(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    8000524e:	088bb503          	ld	a0,136(s7)
  p->pagetable = pagetable;
    80005252:	096bb423          	sd	s6,136(s7)
  p->sz = sz;
    80005256:	098bb023          	sd	s8,128(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000525a:	090bb783          	ld	a5,144(s7)
    8000525e:	e6043703          	ld	a4,-416(s0)
    80005262:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005264:	090bb783          	ld	a5,144(s7)
    80005268:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000526c:	85ea                	mv	a1,s10
    8000526e:	ffffd097          	auipc	ra,0xffffd
    80005272:	870080e7          	jalr	-1936(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005276:	0004851b          	sext.w	a0,s1
    8000527a:	bbc1                	j	8000504a <exec+0x9c>
    8000527c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005280:	df843583          	ld	a1,-520(s0)
    80005284:	855a                	mv	a0,s6
    80005286:	ffffd097          	auipc	ra,0xffffd
    8000528a:	858080e7          	jalr	-1960(ra) # 80001ade <proc_freepagetable>
  if(ip){
    8000528e:	da0a94e3          	bnez	s5,80005036 <exec+0x88>
  return -1;
    80005292:	557d                	li	a0,-1
    80005294:	bb5d                	j	8000504a <exec+0x9c>
    80005296:	de943c23          	sd	s1,-520(s0)
    8000529a:	b7dd                	j	80005280 <exec+0x2d2>
    8000529c:	de943c23          	sd	s1,-520(s0)
    800052a0:	b7c5                	j	80005280 <exec+0x2d2>
    800052a2:	de943c23          	sd	s1,-520(s0)
    800052a6:	bfe9                	j	80005280 <exec+0x2d2>
  sz = sz1;
    800052a8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ac:	4a81                	li	s5,0
    800052ae:	bfc9                	j	80005280 <exec+0x2d2>
  sz = sz1;
    800052b0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052b4:	4a81                	li	s5,0
    800052b6:	b7e9                	j	80005280 <exec+0x2d2>
  sz = sz1;
    800052b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052bc:	4a81                	li	s5,0
    800052be:	b7c9                	j	80005280 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052c0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052c4:	e0843783          	ld	a5,-504(s0)
    800052c8:	0017869b          	addiw	a3,a5,1
    800052cc:	e0d43423          	sd	a3,-504(s0)
    800052d0:	e0043783          	ld	a5,-512(s0)
    800052d4:	0387879b          	addiw	a5,a5,56
    800052d8:	e8045703          	lhu	a4,-384(s0)
    800052dc:	e2e6d3e3          	bge	a3,a4,80005102 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052e0:	2781                	sext.w	a5,a5
    800052e2:	e0f43023          	sd	a5,-512(s0)
    800052e6:	03800713          	li	a4,56
    800052ea:	86be                	mv	a3,a5
    800052ec:	e1040613          	addi	a2,s0,-496
    800052f0:	4581                	li	a1,0
    800052f2:	8556                	mv	a0,s5
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	a7a080e7          	jalr	-1414(ra) # 80003d6e <readi>
    800052fc:	03800793          	li	a5,56
    80005300:	f6f51ee3          	bne	a0,a5,8000527c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005304:	e1042783          	lw	a5,-496(s0)
    80005308:	4705                	li	a4,1
    8000530a:	fae79de3          	bne	a5,a4,800052c4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000530e:	e3843603          	ld	a2,-456(s0)
    80005312:	e3043783          	ld	a5,-464(s0)
    80005316:	f8f660e3          	bltu	a2,a5,80005296 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000531a:	e2043783          	ld	a5,-480(s0)
    8000531e:	963e                	add	a2,a2,a5
    80005320:	f6f66ee3          	bltu	a2,a5,8000529c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005324:	85a6                	mv	a1,s1
    80005326:	855a                	mv	a0,s6
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	0c6080e7          	jalr	198(ra) # 800013ee <uvmalloc>
    80005330:	dea43c23          	sd	a0,-520(s0)
    80005334:	d53d                	beqz	a0,800052a2 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005336:	e2043c03          	ld	s8,-480(s0)
    8000533a:	de043783          	ld	a5,-544(s0)
    8000533e:	00fc77b3          	and	a5,s8,a5
    80005342:	ff9d                	bnez	a5,80005280 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005344:	e1842c83          	lw	s9,-488(s0)
    80005348:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000534c:	f60b8ae3          	beqz	s7,800052c0 <exec+0x312>
    80005350:	89de                	mv	s3,s7
    80005352:	4481                	li	s1,0
    80005354:	b371                	j	800050e0 <exec+0x132>

0000000080005356 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005356:	7179                	addi	sp,sp,-48
    80005358:	f406                	sd	ra,40(sp)
    8000535a:	f022                	sd	s0,32(sp)
    8000535c:	ec26                	sd	s1,24(sp)
    8000535e:	e84a                	sd	s2,16(sp)
    80005360:	1800                	addi	s0,sp,48
    80005362:	892e                	mv	s2,a1
    80005364:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005366:	fdc40593          	addi	a1,s0,-36
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	a5c080e7          	jalr	-1444(ra) # 80002dc6 <argint>
    80005372:	04054063          	bltz	a0,800053b2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005376:	fdc42703          	lw	a4,-36(s0)
    8000537a:	47bd                	li	a5,15
    8000537c:	02e7ed63          	bltu	a5,a4,800053b6 <argfd+0x60>
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	5fe080e7          	jalr	1534(ra) # 8000197e <myproc>
    80005388:	fdc42703          	lw	a4,-36(s0)
    8000538c:	02070793          	addi	a5,a4,32
    80005390:	078e                	slli	a5,a5,0x3
    80005392:	953e                	add	a0,a0,a5
    80005394:	651c                	ld	a5,8(a0)
    80005396:	c395                	beqz	a5,800053ba <argfd+0x64>
    return -1;
  if(pfd)
    80005398:	00090463          	beqz	s2,800053a0 <argfd+0x4a>
    *pfd = fd;
    8000539c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053a0:	4501                	li	a0,0
  if(pf)
    800053a2:	c091                	beqz	s1,800053a6 <argfd+0x50>
    *pf = f;
    800053a4:	e09c                	sd	a5,0(s1)
}
    800053a6:	70a2                	ld	ra,40(sp)
    800053a8:	7402                	ld	s0,32(sp)
    800053aa:	64e2                	ld	s1,24(sp)
    800053ac:	6942                	ld	s2,16(sp)
    800053ae:	6145                	addi	sp,sp,48
    800053b0:	8082                	ret
    return -1;
    800053b2:	557d                	li	a0,-1
    800053b4:	bfcd                	j	800053a6 <argfd+0x50>
    return -1;
    800053b6:	557d                	li	a0,-1
    800053b8:	b7fd                	j	800053a6 <argfd+0x50>
    800053ba:	557d                	li	a0,-1
    800053bc:	b7ed                	j	800053a6 <argfd+0x50>

00000000800053be <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053be:	1101                	addi	sp,sp,-32
    800053c0:	ec06                	sd	ra,24(sp)
    800053c2:	e822                	sd	s0,16(sp)
    800053c4:	e426                	sd	s1,8(sp)
    800053c6:	1000                	addi	s0,sp,32
    800053c8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	5b4080e7          	jalr	1460(ra) # 8000197e <myproc>
    800053d2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053d4:	10850793          	addi	a5,a0,264
    800053d8:	4501                	li	a0,0
    800053da:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053dc:	6398                	ld	a4,0(a5)
    800053de:	cb19                	beqz	a4,800053f4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053e0:	2505                	addiw	a0,a0,1
    800053e2:	07a1                	addi	a5,a5,8
    800053e4:	fed51ce3          	bne	a0,a3,800053dc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053e8:	557d                	li	a0,-1
}
    800053ea:	60e2                	ld	ra,24(sp)
    800053ec:	6442                	ld	s0,16(sp)
    800053ee:	64a2                	ld	s1,8(sp)
    800053f0:	6105                	addi	sp,sp,32
    800053f2:	8082                	ret
      p->ofile[fd] = f;
    800053f4:	02050793          	addi	a5,a0,32
    800053f8:	078e                	slli	a5,a5,0x3
    800053fa:	963e                	add	a2,a2,a5
    800053fc:	e604                	sd	s1,8(a2)
      return fd;
    800053fe:	b7f5                	j	800053ea <fdalloc+0x2c>

0000000080005400 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005400:	715d                	addi	sp,sp,-80
    80005402:	e486                	sd	ra,72(sp)
    80005404:	e0a2                	sd	s0,64(sp)
    80005406:	fc26                	sd	s1,56(sp)
    80005408:	f84a                	sd	s2,48(sp)
    8000540a:	f44e                	sd	s3,40(sp)
    8000540c:	f052                	sd	s4,32(sp)
    8000540e:	ec56                	sd	s5,24(sp)
    80005410:	0880                	addi	s0,sp,80
    80005412:	89ae                	mv	s3,a1
    80005414:	8ab2                	mv	s5,a2
    80005416:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005418:	fb040593          	addi	a1,s0,-80
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	e72080e7          	jalr	-398(ra) # 8000428e <nameiparent>
    80005424:	892a                	mv	s2,a0
    80005426:	12050e63          	beqz	a0,80005562 <create+0x162>
    return 0;

  ilock(dp);
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	690080e7          	jalr	1680(ra) # 80003aba <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005432:	4601                	li	a2,0
    80005434:	fb040593          	addi	a1,s0,-80
    80005438:	854a                	mv	a0,s2
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	b64080e7          	jalr	-1180(ra) # 80003f9e <dirlookup>
    80005442:	84aa                	mv	s1,a0
    80005444:	c921                	beqz	a0,80005494 <create+0x94>
    iunlockput(dp);
    80005446:	854a                	mv	a0,s2
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	8d4080e7          	jalr	-1836(ra) # 80003d1c <iunlockput>
    ilock(ip);
    80005450:	8526                	mv	a0,s1
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	668080e7          	jalr	1640(ra) # 80003aba <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000545a:	2981                	sext.w	s3,s3
    8000545c:	4789                	li	a5,2
    8000545e:	02f99463          	bne	s3,a5,80005486 <create+0x86>
    80005462:	0444d783          	lhu	a5,68(s1)
    80005466:	37f9                	addiw	a5,a5,-2
    80005468:	17c2                	slli	a5,a5,0x30
    8000546a:	93c1                	srli	a5,a5,0x30
    8000546c:	4705                	li	a4,1
    8000546e:	00f76c63          	bltu	a4,a5,80005486 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005472:	8526                	mv	a0,s1
    80005474:	60a6                	ld	ra,72(sp)
    80005476:	6406                	ld	s0,64(sp)
    80005478:	74e2                	ld	s1,56(sp)
    8000547a:	7942                	ld	s2,48(sp)
    8000547c:	79a2                	ld	s3,40(sp)
    8000547e:	7a02                	ld	s4,32(sp)
    80005480:	6ae2                	ld	s5,24(sp)
    80005482:	6161                	addi	sp,sp,80
    80005484:	8082                	ret
    iunlockput(ip);
    80005486:	8526                	mv	a0,s1
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	894080e7          	jalr	-1900(ra) # 80003d1c <iunlockput>
    return 0;
    80005490:	4481                	li	s1,0
    80005492:	b7c5                	j	80005472 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005494:	85ce                	mv	a1,s3
    80005496:	00092503          	lw	a0,0(s2)
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	488080e7          	jalr	1160(ra) # 80003922 <ialloc>
    800054a2:	84aa                	mv	s1,a0
    800054a4:	c521                	beqz	a0,800054ec <create+0xec>
  ilock(ip);
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	614080e7          	jalr	1556(ra) # 80003aba <ilock>
  ip->major = major;
    800054ae:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054b2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054b6:	4a05                	li	s4,1
    800054b8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800054bc:	8526                	mv	a0,s1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	532080e7          	jalr	1330(ra) # 800039f0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054c6:	2981                	sext.w	s3,s3
    800054c8:	03498a63          	beq	s3,s4,800054fc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800054cc:	40d0                	lw	a2,4(s1)
    800054ce:	fb040593          	addi	a1,s0,-80
    800054d2:	854a                	mv	a0,s2
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	cda080e7          	jalr	-806(ra) # 800041ae <dirlink>
    800054dc:	06054b63          	bltz	a0,80005552 <create+0x152>
  iunlockput(dp);
    800054e0:	854a                	mv	a0,s2
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	83a080e7          	jalr	-1990(ra) # 80003d1c <iunlockput>
  return ip;
    800054ea:	b761                	j	80005472 <create+0x72>
    panic("create: ialloc");
    800054ec:	00003517          	auipc	a0,0x3
    800054f0:	31450513          	addi	a0,a0,788 # 80008800 <syscalls+0x2b0>
    800054f4:	ffffb097          	auipc	ra,0xffffb
    800054f8:	036080e7          	jalr	54(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800054fc:	04a95783          	lhu	a5,74(s2)
    80005500:	2785                	addiw	a5,a5,1
    80005502:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005506:	854a                	mv	a0,s2
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	4e8080e7          	jalr	1256(ra) # 800039f0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005510:	40d0                	lw	a2,4(s1)
    80005512:	00003597          	auipc	a1,0x3
    80005516:	2fe58593          	addi	a1,a1,766 # 80008810 <syscalls+0x2c0>
    8000551a:	8526                	mv	a0,s1
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	c92080e7          	jalr	-878(ra) # 800041ae <dirlink>
    80005524:	00054f63          	bltz	a0,80005542 <create+0x142>
    80005528:	00492603          	lw	a2,4(s2)
    8000552c:	00003597          	auipc	a1,0x3
    80005530:	2ec58593          	addi	a1,a1,748 # 80008818 <syscalls+0x2c8>
    80005534:	8526                	mv	a0,s1
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	c78080e7          	jalr	-904(ra) # 800041ae <dirlink>
    8000553e:	f80557e3          	bgez	a0,800054cc <create+0xcc>
      panic("create dots");
    80005542:	00003517          	auipc	a0,0x3
    80005546:	2de50513          	addi	a0,a0,734 # 80008820 <syscalls+0x2d0>
    8000554a:	ffffb097          	auipc	ra,0xffffb
    8000554e:	fe0080e7          	jalr	-32(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005552:	00003517          	auipc	a0,0x3
    80005556:	2de50513          	addi	a0,a0,734 # 80008830 <syscalls+0x2e0>
    8000555a:	ffffb097          	auipc	ra,0xffffb
    8000555e:	fd0080e7          	jalr	-48(ra) # 8000052a <panic>
    return 0;
    80005562:	84aa                	mv	s1,a0
    80005564:	b739                	j	80005472 <create+0x72>

0000000080005566 <sys_dup>:
{
    80005566:	7179                	addi	sp,sp,-48
    80005568:	f406                	sd	ra,40(sp)
    8000556a:	f022                	sd	s0,32(sp)
    8000556c:	ec26                	sd	s1,24(sp)
    8000556e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005570:	fd840613          	addi	a2,s0,-40
    80005574:	4581                	li	a1,0
    80005576:	4501                	li	a0,0
    80005578:	00000097          	auipc	ra,0x0
    8000557c:	dde080e7          	jalr	-546(ra) # 80005356 <argfd>
    return -1;
    80005580:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005582:	02054363          	bltz	a0,800055a8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005586:	fd843503          	ld	a0,-40(s0)
    8000558a:	00000097          	auipc	ra,0x0
    8000558e:	e34080e7          	jalr	-460(ra) # 800053be <fdalloc>
    80005592:	84aa                	mv	s1,a0
    return -1;
    80005594:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005596:	00054963          	bltz	a0,800055a8 <sys_dup+0x42>
  filedup(f);
    8000559a:	fd843503          	ld	a0,-40(s0)
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	36c080e7          	jalr	876(ra) # 8000490a <filedup>
  return fd;
    800055a6:	87a6                	mv	a5,s1
}
    800055a8:	853e                	mv	a0,a5
    800055aa:	70a2                	ld	ra,40(sp)
    800055ac:	7402                	ld	s0,32(sp)
    800055ae:	64e2                	ld	s1,24(sp)
    800055b0:	6145                	addi	sp,sp,48
    800055b2:	8082                	ret

00000000800055b4 <sys_read>:
{
    800055b4:	7179                	addi	sp,sp,-48
    800055b6:	f406                	sd	ra,40(sp)
    800055b8:	f022                	sd	s0,32(sp)
    800055ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055bc:	fe840613          	addi	a2,s0,-24
    800055c0:	4581                	li	a1,0
    800055c2:	4501                	li	a0,0
    800055c4:	00000097          	auipc	ra,0x0
    800055c8:	d92080e7          	jalr	-622(ra) # 80005356 <argfd>
    return -1;
    800055cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ce:	04054163          	bltz	a0,80005610 <sys_read+0x5c>
    800055d2:	fe440593          	addi	a1,s0,-28
    800055d6:	4509                	li	a0,2
    800055d8:	ffffd097          	auipc	ra,0xffffd
    800055dc:	7ee080e7          	jalr	2030(ra) # 80002dc6 <argint>
    return -1;
    800055e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055e2:	02054763          	bltz	a0,80005610 <sys_read+0x5c>
    800055e6:	fd840593          	addi	a1,s0,-40
    800055ea:	4505                	li	a0,1
    800055ec:	ffffd097          	auipc	ra,0xffffd
    800055f0:	7fc080e7          	jalr	2044(ra) # 80002de8 <argaddr>
    return -1;
    800055f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055f6:	00054d63          	bltz	a0,80005610 <sys_read+0x5c>
  return fileread(f, p, n);
    800055fa:	fe442603          	lw	a2,-28(s0)
    800055fe:	fd843583          	ld	a1,-40(s0)
    80005602:	fe843503          	ld	a0,-24(s0)
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	490080e7          	jalr	1168(ra) # 80004a96 <fileread>
    8000560e:	87aa                	mv	a5,a0
}
    80005610:	853e                	mv	a0,a5
    80005612:	70a2                	ld	ra,40(sp)
    80005614:	7402                	ld	s0,32(sp)
    80005616:	6145                	addi	sp,sp,48
    80005618:	8082                	ret

000000008000561a <sys_write>:
{
    8000561a:	7179                	addi	sp,sp,-48
    8000561c:	f406                	sd	ra,40(sp)
    8000561e:	f022                	sd	s0,32(sp)
    80005620:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005622:	fe840613          	addi	a2,s0,-24
    80005626:	4581                	li	a1,0
    80005628:	4501                	li	a0,0
    8000562a:	00000097          	auipc	ra,0x0
    8000562e:	d2c080e7          	jalr	-724(ra) # 80005356 <argfd>
    return -1;
    80005632:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005634:	04054163          	bltz	a0,80005676 <sys_write+0x5c>
    80005638:	fe440593          	addi	a1,s0,-28
    8000563c:	4509                	li	a0,2
    8000563e:	ffffd097          	auipc	ra,0xffffd
    80005642:	788080e7          	jalr	1928(ra) # 80002dc6 <argint>
    return -1;
    80005646:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005648:	02054763          	bltz	a0,80005676 <sys_write+0x5c>
    8000564c:	fd840593          	addi	a1,s0,-40
    80005650:	4505                	li	a0,1
    80005652:	ffffd097          	auipc	ra,0xffffd
    80005656:	796080e7          	jalr	1942(ra) # 80002de8 <argaddr>
    return -1;
    8000565a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000565c:	00054d63          	bltz	a0,80005676 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005660:	fe442603          	lw	a2,-28(s0)
    80005664:	fd843583          	ld	a1,-40(s0)
    80005668:	fe843503          	ld	a0,-24(s0)
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	4ec080e7          	jalr	1260(ra) # 80004b58 <filewrite>
    80005674:	87aa                	mv	a5,a0
}
    80005676:	853e                	mv	a0,a5
    80005678:	70a2                	ld	ra,40(sp)
    8000567a:	7402                	ld	s0,32(sp)
    8000567c:	6145                	addi	sp,sp,48
    8000567e:	8082                	ret

0000000080005680 <sys_close>:
{
    80005680:	1101                	addi	sp,sp,-32
    80005682:	ec06                	sd	ra,24(sp)
    80005684:	e822                	sd	s0,16(sp)
    80005686:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005688:	fe040613          	addi	a2,s0,-32
    8000568c:	fec40593          	addi	a1,s0,-20
    80005690:	4501                	li	a0,0
    80005692:	00000097          	auipc	ra,0x0
    80005696:	cc4080e7          	jalr	-828(ra) # 80005356 <argfd>
    return -1;
    8000569a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000569c:	02054563          	bltz	a0,800056c6 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    800056a0:	ffffc097          	auipc	ra,0xffffc
    800056a4:	2de080e7          	jalr	734(ra) # 8000197e <myproc>
    800056a8:	fec42783          	lw	a5,-20(s0)
    800056ac:	02078793          	addi	a5,a5,32
    800056b0:	078e                	slli	a5,a5,0x3
    800056b2:	97aa                	add	a5,a5,a0
    800056b4:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800056b8:	fe043503          	ld	a0,-32(s0)
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	2a0080e7          	jalr	672(ra) # 8000495c <fileclose>
  return 0;
    800056c4:	4781                	li	a5,0
}
    800056c6:	853e                	mv	a0,a5
    800056c8:	60e2                	ld	ra,24(sp)
    800056ca:	6442                	ld	s0,16(sp)
    800056cc:	6105                	addi	sp,sp,32
    800056ce:	8082                	ret

00000000800056d0 <sys_fstat>:
{
    800056d0:	1101                	addi	sp,sp,-32
    800056d2:	ec06                	sd	ra,24(sp)
    800056d4:	e822                	sd	s0,16(sp)
    800056d6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056d8:	fe840613          	addi	a2,s0,-24
    800056dc:	4581                	li	a1,0
    800056de:	4501                	li	a0,0
    800056e0:	00000097          	auipc	ra,0x0
    800056e4:	c76080e7          	jalr	-906(ra) # 80005356 <argfd>
    return -1;
    800056e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056ea:	02054563          	bltz	a0,80005714 <sys_fstat+0x44>
    800056ee:	fe040593          	addi	a1,s0,-32
    800056f2:	4505                	li	a0,1
    800056f4:	ffffd097          	auipc	ra,0xffffd
    800056f8:	6f4080e7          	jalr	1780(ra) # 80002de8 <argaddr>
    return -1;
    800056fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056fe:	00054b63          	bltz	a0,80005714 <sys_fstat+0x44>
  return filestat(f, st);
    80005702:	fe043583          	ld	a1,-32(s0)
    80005706:	fe843503          	ld	a0,-24(s0)
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	31a080e7          	jalr	794(ra) # 80004a24 <filestat>
    80005712:	87aa                	mv	a5,a0
}
    80005714:	853e                	mv	a0,a5
    80005716:	60e2                	ld	ra,24(sp)
    80005718:	6442                	ld	s0,16(sp)
    8000571a:	6105                	addi	sp,sp,32
    8000571c:	8082                	ret

000000008000571e <sys_link>:
{
    8000571e:	7169                	addi	sp,sp,-304
    80005720:	f606                	sd	ra,296(sp)
    80005722:	f222                	sd	s0,288(sp)
    80005724:	ee26                	sd	s1,280(sp)
    80005726:	ea4a                	sd	s2,272(sp)
    80005728:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000572a:	08000613          	li	a2,128
    8000572e:	ed040593          	addi	a1,s0,-304
    80005732:	4501                	li	a0,0
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	6d6080e7          	jalr	1750(ra) # 80002e0a <argstr>
    return -1;
    8000573c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000573e:	10054e63          	bltz	a0,8000585a <sys_link+0x13c>
    80005742:	08000613          	li	a2,128
    80005746:	f5040593          	addi	a1,s0,-176
    8000574a:	4505                	li	a0,1
    8000574c:	ffffd097          	auipc	ra,0xffffd
    80005750:	6be080e7          	jalr	1726(ra) # 80002e0a <argstr>
    return -1;
    80005754:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005756:	10054263          	bltz	a0,8000585a <sys_link+0x13c>
  begin_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	d36080e7          	jalr	-714(ra) # 80004490 <begin_op>
  if((ip = namei(old)) == 0){
    80005762:	ed040513          	addi	a0,s0,-304
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	b0a080e7          	jalr	-1270(ra) # 80004270 <namei>
    8000576e:	84aa                	mv	s1,a0
    80005770:	c551                	beqz	a0,800057fc <sys_link+0xde>
  ilock(ip);
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	348080e7          	jalr	840(ra) # 80003aba <ilock>
  if(ip->type == T_DIR){
    8000577a:	04449703          	lh	a4,68(s1)
    8000577e:	4785                	li	a5,1
    80005780:	08f70463          	beq	a4,a5,80005808 <sys_link+0xea>
  ip->nlink++;
    80005784:	04a4d783          	lhu	a5,74(s1)
    80005788:	2785                	addiw	a5,a5,1
    8000578a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000578e:	8526                	mv	a0,s1
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	260080e7          	jalr	608(ra) # 800039f0 <iupdate>
  iunlock(ip);
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	3e2080e7          	jalr	994(ra) # 80003b7c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057a2:	fd040593          	addi	a1,s0,-48
    800057a6:	f5040513          	addi	a0,s0,-176
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	ae4080e7          	jalr	-1308(ra) # 8000428e <nameiparent>
    800057b2:	892a                	mv	s2,a0
    800057b4:	c935                	beqz	a0,80005828 <sys_link+0x10a>
  ilock(dp);
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	304080e7          	jalr	772(ra) # 80003aba <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057be:	00092703          	lw	a4,0(s2)
    800057c2:	409c                	lw	a5,0(s1)
    800057c4:	04f71d63          	bne	a4,a5,8000581e <sys_link+0x100>
    800057c8:	40d0                	lw	a2,4(s1)
    800057ca:	fd040593          	addi	a1,s0,-48
    800057ce:	854a                	mv	a0,s2
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	9de080e7          	jalr	-1570(ra) # 800041ae <dirlink>
    800057d8:	04054363          	bltz	a0,8000581e <sys_link+0x100>
  iunlockput(dp);
    800057dc:	854a                	mv	a0,s2
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	53e080e7          	jalr	1342(ra) # 80003d1c <iunlockput>
  iput(ip);
    800057e6:	8526                	mv	a0,s1
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	48c080e7          	jalr	1164(ra) # 80003c74 <iput>
  end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	d20080e7          	jalr	-736(ra) # 80004510 <end_op>
  return 0;
    800057f8:	4781                	li	a5,0
    800057fa:	a085                	j	8000585a <sys_link+0x13c>
    end_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	d14080e7          	jalr	-748(ra) # 80004510 <end_op>
    return -1;
    80005804:	57fd                	li	a5,-1
    80005806:	a891                	j	8000585a <sys_link+0x13c>
    iunlockput(ip);
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	512080e7          	jalr	1298(ra) # 80003d1c <iunlockput>
    end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	cfe080e7          	jalr	-770(ra) # 80004510 <end_op>
    return -1;
    8000581a:	57fd                	li	a5,-1
    8000581c:	a83d                	j	8000585a <sys_link+0x13c>
    iunlockput(dp);
    8000581e:	854a                	mv	a0,s2
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	4fc080e7          	jalr	1276(ra) # 80003d1c <iunlockput>
  ilock(ip);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	290080e7          	jalr	656(ra) # 80003aba <ilock>
  ip->nlink--;
    80005832:	04a4d783          	lhu	a5,74(s1)
    80005836:	37fd                	addiw	a5,a5,-1
    80005838:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	1b2080e7          	jalr	434(ra) # 800039f0 <iupdate>
  iunlockput(ip);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	4d4080e7          	jalr	1236(ra) # 80003d1c <iunlockput>
  end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	cc0080e7          	jalr	-832(ra) # 80004510 <end_op>
  return -1;
    80005858:	57fd                	li	a5,-1
}
    8000585a:	853e                	mv	a0,a5
    8000585c:	70b2                	ld	ra,296(sp)
    8000585e:	7412                	ld	s0,288(sp)
    80005860:	64f2                	ld	s1,280(sp)
    80005862:	6952                	ld	s2,272(sp)
    80005864:	6155                	addi	sp,sp,304
    80005866:	8082                	ret

0000000080005868 <sys_unlink>:
{
    80005868:	7151                	addi	sp,sp,-240
    8000586a:	f586                	sd	ra,232(sp)
    8000586c:	f1a2                	sd	s0,224(sp)
    8000586e:	eda6                	sd	s1,216(sp)
    80005870:	e9ca                	sd	s2,208(sp)
    80005872:	e5ce                	sd	s3,200(sp)
    80005874:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005876:	08000613          	li	a2,128
    8000587a:	f3040593          	addi	a1,s0,-208
    8000587e:	4501                	li	a0,0
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	58a080e7          	jalr	1418(ra) # 80002e0a <argstr>
    80005888:	18054163          	bltz	a0,80005a0a <sys_unlink+0x1a2>
  begin_op();
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	c04080e7          	jalr	-1020(ra) # 80004490 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005894:	fb040593          	addi	a1,s0,-80
    80005898:	f3040513          	addi	a0,s0,-208
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	9f2080e7          	jalr	-1550(ra) # 8000428e <nameiparent>
    800058a4:	84aa                	mv	s1,a0
    800058a6:	c979                	beqz	a0,8000597c <sys_unlink+0x114>
  ilock(dp);
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	212080e7          	jalr	530(ra) # 80003aba <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058b0:	00003597          	auipc	a1,0x3
    800058b4:	f6058593          	addi	a1,a1,-160 # 80008810 <syscalls+0x2c0>
    800058b8:	fb040513          	addi	a0,s0,-80
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	6c8080e7          	jalr	1736(ra) # 80003f84 <namecmp>
    800058c4:	14050a63          	beqz	a0,80005a18 <sys_unlink+0x1b0>
    800058c8:	00003597          	auipc	a1,0x3
    800058cc:	f5058593          	addi	a1,a1,-176 # 80008818 <syscalls+0x2c8>
    800058d0:	fb040513          	addi	a0,s0,-80
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	6b0080e7          	jalr	1712(ra) # 80003f84 <namecmp>
    800058dc:	12050e63          	beqz	a0,80005a18 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058e0:	f2c40613          	addi	a2,s0,-212
    800058e4:	fb040593          	addi	a1,s0,-80
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	6b4080e7          	jalr	1716(ra) # 80003f9e <dirlookup>
    800058f2:	892a                	mv	s2,a0
    800058f4:	12050263          	beqz	a0,80005a18 <sys_unlink+0x1b0>
  ilock(ip);
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	1c2080e7          	jalr	450(ra) # 80003aba <ilock>
  if(ip->nlink < 1)
    80005900:	04a91783          	lh	a5,74(s2)
    80005904:	08f05263          	blez	a5,80005988 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005908:	04491703          	lh	a4,68(s2)
    8000590c:	4785                	li	a5,1
    8000590e:	08f70563          	beq	a4,a5,80005998 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005912:	4641                	li	a2,16
    80005914:	4581                	li	a1,0
    80005916:	fc040513          	addi	a0,s0,-64
    8000591a:	ffffb097          	auipc	ra,0xffffb
    8000591e:	3a4080e7          	jalr	932(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005922:	4741                	li	a4,16
    80005924:	f2c42683          	lw	a3,-212(s0)
    80005928:	fc040613          	addi	a2,s0,-64
    8000592c:	4581                	li	a1,0
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	536080e7          	jalr	1334(ra) # 80003e66 <writei>
    80005938:	47c1                	li	a5,16
    8000593a:	0af51563          	bne	a0,a5,800059e4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000593e:	04491703          	lh	a4,68(s2)
    80005942:	4785                	li	a5,1
    80005944:	0af70863          	beq	a4,a5,800059f4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	3d2080e7          	jalr	978(ra) # 80003d1c <iunlockput>
  ip->nlink--;
    80005952:	04a95783          	lhu	a5,74(s2)
    80005956:	37fd                	addiw	a5,a5,-1
    80005958:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000595c:	854a                	mv	a0,s2
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	092080e7          	jalr	146(ra) # 800039f0 <iupdate>
  iunlockput(ip);
    80005966:	854a                	mv	a0,s2
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	3b4080e7          	jalr	948(ra) # 80003d1c <iunlockput>
  end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	ba0080e7          	jalr	-1120(ra) # 80004510 <end_op>
  return 0;
    80005978:	4501                	li	a0,0
    8000597a:	a84d                	j	80005a2c <sys_unlink+0x1c4>
    end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	b94080e7          	jalr	-1132(ra) # 80004510 <end_op>
    return -1;
    80005984:	557d                	li	a0,-1
    80005986:	a05d                	j	80005a2c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005988:	00003517          	auipc	a0,0x3
    8000598c:	eb850513          	addi	a0,a0,-328 # 80008840 <syscalls+0x2f0>
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	b9a080e7          	jalr	-1126(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005998:	04c92703          	lw	a4,76(s2)
    8000599c:	02000793          	li	a5,32
    800059a0:	f6e7f9e3          	bgeu	a5,a4,80005912 <sys_unlink+0xaa>
    800059a4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059a8:	4741                	li	a4,16
    800059aa:	86ce                	mv	a3,s3
    800059ac:	f1840613          	addi	a2,s0,-232
    800059b0:	4581                	li	a1,0
    800059b2:	854a                	mv	a0,s2
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	3ba080e7          	jalr	954(ra) # 80003d6e <readi>
    800059bc:	47c1                	li	a5,16
    800059be:	00f51b63          	bne	a0,a5,800059d4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059c2:	f1845783          	lhu	a5,-232(s0)
    800059c6:	e7a1                	bnez	a5,80005a0e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059c8:	29c1                	addiw	s3,s3,16
    800059ca:	04c92783          	lw	a5,76(s2)
    800059ce:	fcf9ede3          	bltu	s3,a5,800059a8 <sys_unlink+0x140>
    800059d2:	b781                	j	80005912 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059d4:	00003517          	auipc	a0,0x3
    800059d8:	e8450513          	addi	a0,a0,-380 # 80008858 <syscalls+0x308>
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	b4e080e7          	jalr	-1202(ra) # 8000052a <panic>
    panic("unlink: writei");
    800059e4:	00003517          	auipc	a0,0x3
    800059e8:	e8c50513          	addi	a0,a0,-372 # 80008870 <syscalls+0x320>
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	b3e080e7          	jalr	-1218(ra) # 8000052a <panic>
    dp->nlink--;
    800059f4:	04a4d783          	lhu	a5,74(s1)
    800059f8:	37fd                	addiw	a5,a5,-1
    800059fa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059fe:	8526                	mv	a0,s1
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	ff0080e7          	jalr	-16(ra) # 800039f0 <iupdate>
    80005a08:	b781                	j	80005948 <sys_unlink+0xe0>
    return -1;
    80005a0a:	557d                	li	a0,-1
    80005a0c:	a005                	j	80005a2c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a0e:	854a                	mv	a0,s2
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	30c080e7          	jalr	780(ra) # 80003d1c <iunlockput>
  iunlockput(dp);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	302080e7          	jalr	770(ra) # 80003d1c <iunlockput>
  end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	aee080e7          	jalr	-1298(ra) # 80004510 <end_op>
  return -1;
    80005a2a:	557d                	li	a0,-1
}
    80005a2c:	70ae                	ld	ra,232(sp)
    80005a2e:	740e                	ld	s0,224(sp)
    80005a30:	64ee                	ld	s1,216(sp)
    80005a32:	694e                	ld	s2,208(sp)
    80005a34:	69ae                	ld	s3,200(sp)
    80005a36:	616d                	addi	sp,sp,240
    80005a38:	8082                	ret

0000000080005a3a <sys_open>:

uint64
sys_open(void)
{
    80005a3a:	7131                	addi	sp,sp,-192
    80005a3c:	fd06                	sd	ra,184(sp)
    80005a3e:	f922                	sd	s0,176(sp)
    80005a40:	f526                	sd	s1,168(sp)
    80005a42:	f14a                	sd	s2,160(sp)
    80005a44:	ed4e                	sd	s3,152(sp)
    80005a46:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a48:	08000613          	li	a2,128
    80005a4c:	f5040593          	addi	a1,s0,-176
    80005a50:	4501                	li	a0,0
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	3b8080e7          	jalr	952(ra) # 80002e0a <argstr>
    return -1;
    80005a5a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a5c:	0c054163          	bltz	a0,80005b1e <sys_open+0xe4>
    80005a60:	f4c40593          	addi	a1,s0,-180
    80005a64:	4505                	li	a0,1
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	360080e7          	jalr	864(ra) # 80002dc6 <argint>
    80005a6e:	0a054863          	bltz	a0,80005b1e <sys_open+0xe4>

  begin_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	a1e080e7          	jalr	-1506(ra) # 80004490 <begin_op>

  if(omode & O_CREATE){
    80005a7a:	f4c42783          	lw	a5,-180(s0)
    80005a7e:	2007f793          	andi	a5,a5,512
    80005a82:	cbdd                	beqz	a5,80005b38 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a84:	4681                	li	a3,0
    80005a86:	4601                	li	a2,0
    80005a88:	4589                	li	a1,2
    80005a8a:	f5040513          	addi	a0,s0,-176
    80005a8e:	00000097          	auipc	ra,0x0
    80005a92:	972080e7          	jalr	-1678(ra) # 80005400 <create>
    80005a96:	892a                	mv	s2,a0
    if(ip == 0){
    80005a98:	c959                	beqz	a0,80005b2e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a9a:	04491703          	lh	a4,68(s2)
    80005a9e:	478d                	li	a5,3
    80005aa0:	00f71763          	bne	a4,a5,80005aae <sys_open+0x74>
    80005aa4:	04695703          	lhu	a4,70(s2)
    80005aa8:	47a5                	li	a5,9
    80005aaa:	0ce7ec63          	bltu	a5,a4,80005b82 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	df2080e7          	jalr	-526(ra) # 800048a0 <filealloc>
    80005ab6:	89aa                	mv	s3,a0
    80005ab8:	10050263          	beqz	a0,80005bbc <sys_open+0x182>
    80005abc:	00000097          	auipc	ra,0x0
    80005ac0:	902080e7          	jalr	-1790(ra) # 800053be <fdalloc>
    80005ac4:	84aa                	mv	s1,a0
    80005ac6:	0e054663          	bltz	a0,80005bb2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005aca:	04491703          	lh	a4,68(s2)
    80005ace:	478d                	li	a5,3
    80005ad0:	0cf70463          	beq	a4,a5,80005b98 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ad4:	4789                	li	a5,2
    80005ad6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ada:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ade:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ae2:	f4c42783          	lw	a5,-180(s0)
    80005ae6:	0017c713          	xori	a4,a5,1
    80005aea:	8b05                	andi	a4,a4,1
    80005aec:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005af0:	0037f713          	andi	a4,a5,3
    80005af4:	00e03733          	snez	a4,a4
    80005af8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005afc:	4007f793          	andi	a5,a5,1024
    80005b00:	c791                	beqz	a5,80005b0c <sys_open+0xd2>
    80005b02:	04491703          	lh	a4,68(s2)
    80005b06:	4789                	li	a5,2
    80005b08:	08f70f63          	beq	a4,a5,80005ba6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b0c:	854a                	mv	a0,s2
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	06e080e7          	jalr	110(ra) # 80003b7c <iunlock>
  end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	9fa080e7          	jalr	-1542(ra) # 80004510 <end_op>

  return fd;
}
    80005b1e:	8526                	mv	a0,s1
    80005b20:	70ea                	ld	ra,184(sp)
    80005b22:	744a                	ld	s0,176(sp)
    80005b24:	74aa                	ld	s1,168(sp)
    80005b26:	790a                	ld	s2,160(sp)
    80005b28:	69ea                	ld	s3,152(sp)
    80005b2a:	6129                	addi	sp,sp,192
    80005b2c:	8082                	ret
      end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	9e2080e7          	jalr	-1566(ra) # 80004510 <end_op>
      return -1;
    80005b36:	b7e5                	j	80005b1e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b38:	f5040513          	addi	a0,s0,-176
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	734080e7          	jalr	1844(ra) # 80004270 <namei>
    80005b44:	892a                	mv	s2,a0
    80005b46:	c905                	beqz	a0,80005b76 <sys_open+0x13c>
    ilock(ip);
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	f72080e7          	jalr	-142(ra) # 80003aba <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b50:	04491703          	lh	a4,68(s2)
    80005b54:	4785                	li	a5,1
    80005b56:	f4f712e3          	bne	a4,a5,80005a9a <sys_open+0x60>
    80005b5a:	f4c42783          	lw	a5,-180(s0)
    80005b5e:	dba1                	beqz	a5,80005aae <sys_open+0x74>
      iunlockput(ip);
    80005b60:	854a                	mv	a0,s2
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	1ba080e7          	jalr	442(ra) # 80003d1c <iunlockput>
      end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	9a6080e7          	jalr	-1626(ra) # 80004510 <end_op>
      return -1;
    80005b72:	54fd                	li	s1,-1
    80005b74:	b76d                	j	80005b1e <sys_open+0xe4>
      end_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	99a080e7          	jalr	-1638(ra) # 80004510 <end_op>
      return -1;
    80005b7e:	54fd                	li	s1,-1
    80005b80:	bf79                	j	80005b1e <sys_open+0xe4>
    iunlockput(ip);
    80005b82:	854a                	mv	a0,s2
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	198080e7          	jalr	408(ra) # 80003d1c <iunlockput>
    end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	984080e7          	jalr	-1660(ra) # 80004510 <end_op>
    return -1;
    80005b94:	54fd                	li	s1,-1
    80005b96:	b761                	j	80005b1e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b98:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b9c:	04691783          	lh	a5,70(s2)
    80005ba0:	02f99223          	sh	a5,36(s3)
    80005ba4:	bf2d                	j	80005ade <sys_open+0xa4>
    itrunc(ip);
    80005ba6:	854a                	mv	a0,s2
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	020080e7          	jalr	32(ra) # 80003bc8 <itrunc>
    80005bb0:	bfb1                	j	80005b0c <sys_open+0xd2>
      fileclose(f);
    80005bb2:	854e                	mv	a0,s3
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	da8080e7          	jalr	-600(ra) # 8000495c <fileclose>
    iunlockput(ip);
    80005bbc:	854a                	mv	a0,s2
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	15e080e7          	jalr	350(ra) # 80003d1c <iunlockput>
    end_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	94a080e7          	jalr	-1718(ra) # 80004510 <end_op>
    return -1;
    80005bce:	54fd                	li	s1,-1
    80005bd0:	b7b9                	j	80005b1e <sys_open+0xe4>

0000000080005bd2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bd2:	7175                	addi	sp,sp,-144
    80005bd4:	e506                	sd	ra,136(sp)
    80005bd6:	e122                	sd	s0,128(sp)
    80005bd8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	8b6080e7          	jalr	-1866(ra) # 80004490 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005be2:	08000613          	li	a2,128
    80005be6:	f7040593          	addi	a1,s0,-144
    80005bea:	4501                	li	a0,0
    80005bec:	ffffd097          	auipc	ra,0xffffd
    80005bf0:	21e080e7          	jalr	542(ra) # 80002e0a <argstr>
    80005bf4:	02054963          	bltz	a0,80005c26 <sys_mkdir+0x54>
    80005bf8:	4681                	li	a3,0
    80005bfa:	4601                	li	a2,0
    80005bfc:	4585                	li	a1,1
    80005bfe:	f7040513          	addi	a0,s0,-144
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	7fe080e7          	jalr	2046(ra) # 80005400 <create>
    80005c0a:	cd11                	beqz	a0,80005c26 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	110080e7          	jalr	272(ra) # 80003d1c <iunlockput>
  end_op();
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	8fc080e7          	jalr	-1796(ra) # 80004510 <end_op>
  return 0;
    80005c1c:	4501                	li	a0,0
}
    80005c1e:	60aa                	ld	ra,136(sp)
    80005c20:	640a                	ld	s0,128(sp)
    80005c22:	6149                	addi	sp,sp,144
    80005c24:	8082                	ret
    end_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	8ea080e7          	jalr	-1814(ra) # 80004510 <end_op>
    return -1;
    80005c2e:	557d                	li	a0,-1
    80005c30:	b7fd                	j	80005c1e <sys_mkdir+0x4c>

0000000080005c32 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c32:	7135                	addi	sp,sp,-160
    80005c34:	ed06                	sd	ra,152(sp)
    80005c36:	e922                	sd	s0,144(sp)
    80005c38:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	856080e7          	jalr	-1962(ra) # 80004490 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c42:	08000613          	li	a2,128
    80005c46:	f7040593          	addi	a1,s0,-144
    80005c4a:	4501                	li	a0,0
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	1be080e7          	jalr	446(ra) # 80002e0a <argstr>
    80005c54:	04054a63          	bltz	a0,80005ca8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c58:	f6c40593          	addi	a1,s0,-148
    80005c5c:	4505                	li	a0,1
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	168080e7          	jalr	360(ra) # 80002dc6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c66:	04054163          	bltz	a0,80005ca8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c6a:	f6840593          	addi	a1,s0,-152
    80005c6e:	4509                	li	a0,2
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	156080e7          	jalr	342(ra) # 80002dc6 <argint>
     argint(1, &major) < 0 ||
    80005c78:	02054863          	bltz	a0,80005ca8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c7c:	f6841683          	lh	a3,-152(s0)
    80005c80:	f6c41603          	lh	a2,-148(s0)
    80005c84:	458d                	li	a1,3
    80005c86:	f7040513          	addi	a0,s0,-144
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	776080e7          	jalr	1910(ra) # 80005400 <create>
     argint(2, &minor) < 0 ||
    80005c92:	c919                	beqz	a0,80005ca8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	088080e7          	jalr	136(ra) # 80003d1c <iunlockput>
  end_op();
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	874080e7          	jalr	-1932(ra) # 80004510 <end_op>
  return 0;
    80005ca4:	4501                	li	a0,0
    80005ca6:	a031                	j	80005cb2 <sys_mknod+0x80>
    end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	868080e7          	jalr	-1944(ra) # 80004510 <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
}
    80005cb2:	60ea                	ld	ra,152(sp)
    80005cb4:	644a                	ld	s0,144(sp)
    80005cb6:	610d                	addi	sp,sp,160
    80005cb8:	8082                	ret

0000000080005cba <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cba:	7135                	addi	sp,sp,-160
    80005cbc:	ed06                	sd	ra,152(sp)
    80005cbe:	e922                	sd	s0,144(sp)
    80005cc0:	e526                	sd	s1,136(sp)
    80005cc2:	e14a                	sd	s2,128(sp)
    80005cc4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cc6:	ffffc097          	auipc	ra,0xffffc
    80005cca:	cb8080e7          	jalr	-840(ra) # 8000197e <myproc>
    80005cce:	892a                	mv	s2,a0
  
  begin_op();
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	7c0080e7          	jalr	1984(ra) # 80004490 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cd8:	08000613          	li	a2,128
    80005cdc:	f6040593          	addi	a1,s0,-160
    80005ce0:	4501                	li	a0,0
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	128080e7          	jalr	296(ra) # 80002e0a <argstr>
    80005cea:	04054b63          	bltz	a0,80005d40 <sys_chdir+0x86>
    80005cee:	f6040513          	addi	a0,s0,-160
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	57e080e7          	jalr	1406(ra) # 80004270 <namei>
    80005cfa:	84aa                	mv	s1,a0
    80005cfc:	c131                	beqz	a0,80005d40 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cfe:	ffffe097          	auipc	ra,0xffffe
    80005d02:	dbc080e7          	jalr	-580(ra) # 80003aba <ilock>
  if(ip->type != T_DIR){
    80005d06:	04449703          	lh	a4,68(s1)
    80005d0a:	4785                	li	a5,1
    80005d0c:	04f71063          	bne	a4,a5,80005d4c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d10:	8526                	mv	a0,s1
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	e6a080e7          	jalr	-406(ra) # 80003b7c <iunlock>
  iput(p->cwd);
    80005d1a:	18893503          	ld	a0,392(s2)
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	f56080e7          	jalr	-170(ra) # 80003c74 <iput>
  end_op();
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	7ea080e7          	jalr	2026(ra) # 80004510 <end_op>
  p->cwd = ip;
    80005d2e:	18993423          	sd	s1,392(s2)
  return 0;
    80005d32:	4501                	li	a0,0
}
    80005d34:	60ea                	ld	ra,152(sp)
    80005d36:	644a                	ld	s0,144(sp)
    80005d38:	64aa                	ld	s1,136(sp)
    80005d3a:	690a                	ld	s2,128(sp)
    80005d3c:	610d                	addi	sp,sp,160
    80005d3e:	8082                	ret
    end_op();
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	7d0080e7          	jalr	2000(ra) # 80004510 <end_op>
    return -1;
    80005d48:	557d                	li	a0,-1
    80005d4a:	b7ed                	j	80005d34 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d4c:	8526                	mv	a0,s1
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	fce080e7          	jalr	-50(ra) # 80003d1c <iunlockput>
    end_op();
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	7ba080e7          	jalr	1978(ra) # 80004510 <end_op>
    return -1;
    80005d5e:	557d                	li	a0,-1
    80005d60:	bfd1                	j	80005d34 <sys_chdir+0x7a>

0000000080005d62 <sys_exec>:

uint64
sys_exec(void)
{
    80005d62:	7145                	addi	sp,sp,-464
    80005d64:	e786                	sd	ra,456(sp)
    80005d66:	e3a2                	sd	s0,448(sp)
    80005d68:	ff26                	sd	s1,440(sp)
    80005d6a:	fb4a                	sd	s2,432(sp)
    80005d6c:	f74e                	sd	s3,424(sp)
    80005d6e:	f352                	sd	s4,416(sp)
    80005d70:	ef56                	sd	s5,408(sp)
    80005d72:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d74:	08000613          	li	a2,128
    80005d78:	f4040593          	addi	a1,s0,-192
    80005d7c:	4501                	li	a0,0
    80005d7e:	ffffd097          	auipc	ra,0xffffd
    80005d82:	08c080e7          	jalr	140(ra) # 80002e0a <argstr>
    return -1;
    80005d86:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d88:	0c054a63          	bltz	a0,80005e5c <sys_exec+0xfa>
    80005d8c:	e3840593          	addi	a1,s0,-456
    80005d90:	4505                	li	a0,1
    80005d92:	ffffd097          	auipc	ra,0xffffd
    80005d96:	056080e7          	jalr	86(ra) # 80002de8 <argaddr>
    80005d9a:	0c054163          	bltz	a0,80005e5c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d9e:	10000613          	li	a2,256
    80005da2:	4581                	li	a1,0
    80005da4:	e4040513          	addi	a0,s0,-448
    80005da8:	ffffb097          	auipc	ra,0xffffb
    80005dac:	f16080e7          	jalr	-234(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005db0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005db4:	89a6                	mv	s3,s1
    80005db6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005db8:	02000a13          	li	s4,32
    80005dbc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dc0:	00391793          	slli	a5,s2,0x3
    80005dc4:	e3040593          	addi	a1,s0,-464
    80005dc8:	e3843503          	ld	a0,-456(s0)
    80005dcc:	953e                	add	a0,a0,a5
    80005dce:	ffffd097          	auipc	ra,0xffffd
    80005dd2:	f5e080e7          	jalr	-162(ra) # 80002d2c <fetchaddr>
    80005dd6:	02054a63          	bltz	a0,80005e0a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005dda:	e3043783          	ld	a5,-464(s0)
    80005dde:	c3b9                	beqz	a5,80005e24 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005de0:	ffffb097          	auipc	ra,0xffffb
    80005de4:	cf2080e7          	jalr	-782(ra) # 80000ad2 <kalloc>
    80005de8:	85aa                	mv	a1,a0
    80005dea:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005dee:	cd11                	beqz	a0,80005e0a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005df0:	6605                	lui	a2,0x1
    80005df2:	e3043503          	ld	a0,-464(s0)
    80005df6:	ffffd097          	auipc	ra,0xffffd
    80005dfa:	f88080e7          	jalr	-120(ra) # 80002d7e <fetchstr>
    80005dfe:	00054663          	bltz	a0,80005e0a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e02:	0905                	addi	s2,s2,1
    80005e04:	09a1                	addi	s3,s3,8
    80005e06:	fb491be3          	bne	s2,s4,80005dbc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e0a:	10048913          	addi	s2,s1,256
    80005e0e:	6088                	ld	a0,0(s1)
    80005e10:	c529                	beqz	a0,80005e5a <sys_exec+0xf8>
    kfree(argv[i]);
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	bc4080e7          	jalr	-1084(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e1a:	04a1                	addi	s1,s1,8
    80005e1c:	ff2499e3          	bne	s1,s2,80005e0e <sys_exec+0xac>
  return -1;
    80005e20:	597d                	li	s2,-1
    80005e22:	a82d                	j	80005e5c <sys_exec+0xfa>
      argv[i] = 0;
    80005e24:	0a8e                	slli	s5,s5,0x3
    80005e26:	fc040793          	addi	a5,s0,-64
    80005e2a:	9abe                	add	s5,s5,a5
    80005e2c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005e30:	e4040593          	addi	a1,s0,-448
    80005e34:	f4040513          	addi	a0,s0,-192
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	176080e7          	jalr	374(ra) # 80004fae <exec>
    80005e40:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e42:	10048993          	addi	s3,s1,256
    80005e46:	6088                	ld	a0,0(s1)
    80005e48:	c911                	beqz	a0,80005e5c <sys_exec+0xfa>
    kfree(argv[i]);
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	b8c080e7          	jalr	-1140(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e52:	04a1                	addi	s1,s1,8
    80005e54:	ff3499e3          	bne	s1,s3,80005e46 <sys_exec+0xe4>
    80005e58:	a011                	j	80005e5c <sys_exec+0xfa>
  return -1;
    80005e5a:	597d                	li	s2,-1
}
    80005e5c:	854a                	mv	a0,s2
    80005e5e:	60be                	ld	ra,456(sp)
    80005e60:	641e                	ld	s0,448(sp)
    80005e62:	74fa                	ld	s1,440(sp)
    80005e64:	795a                	ld	s2,432(sp)
    80005e66:	79ba                	ld	s3,424(sp)
    80005e68:	7a1a                	ld	s4,416(sp)
    80005e6a:	6afa                	ld	s5,408(sp)
    80005e6c:	6179                	addi	sp,sp,464
    80005e6e:	8082                	ret

0000000080005e70 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e70:	7139                	addi	sp,sp,-64
    80005e72:	fc06                	sd	ra,56(sp)
    80005e74:	f822                	sd	s0,48(sp)
    80005e76:	f426                	sd	s1,40(sp)
    80005e78:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e7a:	ffffc097          	auipc	ra,0xffffc
    80005e7e:	b04080e7          	jalr	-1276(ra) # 8000197e <myproc>
    80005e82:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e84:	fd840593          	addi	a1,s0,-40
    80005e88:	4501                	li	a0,0
    80005e8a:	ffffd097          	auipc	ra,0xffffd
    80005e8e:	f5e080e7          	jalr	-162(ra) # 80002de8 <argaddr>
    return -1;
    80005e92:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e94:	0e054263          	bltz	a0,80005f78 <sys_pipe+0x108>
  if(pipealloc(&rf, &wf) < 0)
    80005e98:	fc840593          	addi	a1,s0,-56
    80005e9c:	fd040513          	addi	a0,s0,-48
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	dec080e7          	jalr	-532(ra) # 80004c8c <pipealloc>
    return -1;
    80005ea8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005eaa:	0c054763          	bltz	a0,80005f78 <sys_pipe+0x108>
  fd0 = -1;
    80005eae:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005eb2:	fd043503          	ld	a0,-48(s0)
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	508080e7          	jalr	1288(ra) # 800053be <fdalloc>
    80005ebe:	fca42223          	sw	a0,-60(s0)
    80005ec2:	08054e63          	bltz	a0,80005f5e <sys_pipe+0xee>
    80005ec6:	fc843503          	ld	a0,-56(s0)
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	4f4080e7          	jalr	1268(ra) # 800053be <fdalloc>
    80005ed2:	fca42023          	sw	a0,-64(s0)
    80005ed6:	06054a63          	bltz	a0,80005f4a <sys_pipe+0xda>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eda:	4691                	li	a3,4
    80005edc:	fc440613          	addi	a2,s0,-60
    80005ee0:	fd843583          	ld	a1,-40(s0)
    80005ee4:	64c8                	ld	a0,136(s1)
    80005ee6:	ffffb097          	auipc	ra,0xffffb
    80005eea:	758080e7          	jalr	1880(ra) # 8000163e <copyout>
    80005eee:	02054063          	bltz	a0,80005f0e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ef2:	4691                	li	a3,4
    80005ef4:	fc040613          	addi	a2,s0,-64
    80005ef8:	fd843583          	ld	a1,-40(s0)
    80005efc:	0591                	addi	a1,a1,4
    80005efe:	64c8                	ld	a0,136(s1)
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	73e080e7          	jalr	1854(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f08:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f0a:	06055763          	bgez	a0,80005f78 <sys_pipe+0x108>
    p->ofile[fd0] = 0;
    80005f0e:	fc442783          	lw	a5,-60(s0)
    80005f12:	02078793          	addi	a5,a5,32
    80005f16:	078e                	slli	a5,a5,0x3
    80005f18:	97a6                	add	a5,a5,s1
    80005f1a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f1e:	fc042503          	lw	a0,-64(s0)
    80005f22:	02050513          	addi	a0,a0,32
    80005f26:	050e                	slli	a0,a0,0x3
    80005f28:	9526                	add	a0,a0,s1
    80005f2a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f2e:	fd043503          	ld	a0,-48(s0)
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	a2a080e7          	jalr	-1494(ra) # 8000495c <fileclose>
    fileclose(wf);
    80005f3a:	fc843503          	ld	a0,-56(s0)
    80005f3e:	fffff097          	auipc	ra,0xfffff
    80005f42:	a1e080e7          	jalr	-1506(ra) # 8000495c <fileclose>
    return -1;
    80005f46:	57fd                	li	a5,-1
    80005f48:	a805                	j	80005f78 <sys_pipe+0x108>
    if(fd0 >= 0)
    80005f4a:	fc442783          	lw	a5,-60(s0)
    80005f4e:	0007c863          	bltz	a5,80005f5e <sys_pipe+0xee>
      p->ofile[fd0] = 0;
    80005f52:	02078513          	addi	a0,a5,32
    80005f56:	050e                	slli	a0,a0,0x3
    80005f58:	9526                	add	a0,a0,s1
    80005f5a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f5e:	fd043503          	ld	a0,-48(s0)
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	9fa080e7          	jalr	-1542(ra) # 8000495c <fileclose>
    fileclose(wf);
    80005f6a:	fc843503          	ld	a0,-56(s0)
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	9ee080e7          	jalr	-1554(ra) # 8000495c <fileclose>
    return -1;
    80005f76:	57fd                	li	a5,-1
}
    80005f78:	853e                	mv	a0,a5
    80005f7a:	70e2                	ld	ra,56(sp)
    80005f7c:	7442                	ld	s0,48(sp)
    80005f7e:	74a2                	ld	s1,40(sp)
    80005f80:	6121                	addi	sp,sp,64
    80005f82:	8082                	ret
	...

0000000080005f90 <kernelvec>:
    80005f90:	7111                	addi	sp,sp,-256
    80005f92:	e006                	sd	ra,0(sp)
    80005f94:	e40a                	sd	sp,8(sp)
    80005f96:	e80e                	sd	gp,16(sp)
    80005f98:	ec12                	sd	tp,24(sp)
    80005f9a:	f016                	sd	t0,32(sp)
    80005f9c:	f41a                	sd	t1,40(sp)
    80005f9e:	f81e                	sd	t2,48(sp)
    80005fa0:	fc22                	sd	s0,56(sp)
    80005fa2:	e0a6                	sd	s1,64(sp)
    80005fa4:	e4aa                	sd	a0,72(sp)
    80005fa6:	e8ae                	sd	a1,80(sp)
    80005fa8:	ecb2                	sd	a2,88(sp)
    80005faa:	f0b6                	sd	a3,96(sp)
    80005fac:	f4ba                	sd	a4,104(sp)
    80005fae:	f8be                	sd	a5,112(sp)
    80005fb0:	fcc2                	sd	a6,120(sp)
    80005fb2:	e146                	sd	a7,128(sp)
    80005fb4:	e54a                	sd	s2,136(sp)
    80005fb6:	e94e                	sd	s3,144(sp)
    80005fb8:	ed52                	sd	s4,152(sp)
    80005fba:	f156                	sd	s5,160(sp)
    80005fbc:	f55a                	sd	s6,168(sp)
    80005fbe:	f95e                	sd	s7,176(sp)
    80005fc0:	fd62                	sd	s8,184(sp)
    80005fc2:	e1e6                	sd	s9,192(sp)
    80005fc4:	e5ea                	sd	s10,200(sp)
    80005fc6:	e9ee                	sd	s11,208(sp)
    80005fc8:	edf2                	sd	t3,216(sp)
    80005fca:	f1f6                	sd	t4,224(sp)
    80005fcc:	f5fa                	sd	t5,232(sp)
    80005fce:	f9fe                	sd	t6,240(sp)
    80005fd0:	c1bfc0ef          	jal	ra,80002bea <kerneltrap>
    80005fd4:	6082                	ld	ra,0(sp)
    80005fd6:	6122                	ld	sp,8(sp)
    80005fd8:	61c2                	ld	gp,16(sp)
    80005fda:	7282                	ld	t0,32(sp)
    80005fdc:	7322                	ld	t1,40(sp)
    80005fde:	73c2                	ld	t2,48(sp)
    80005fe0:	7462                	ld	s0,56(sp)
    80005fe2:	6486                	ld	s1,64(sp)
    80005fe4:	6526                	ld	a0,72(sp)
    80005fe6:	65c6                	ld	a1,80(sp)
    80005fe8:	6666                	ld	a2,88(sp)
    80005fea:	7686                	ld	a3,96(sp)
    80005fec:	7726                	ld	a4,104(sp)
    80005fee:	77c6                	ld	a5,112(sp)
    80005ff0:	7866                	ld	a6,120(sp)
    80005ff2:	688a                	ld	a7,128(sp)
    80005ff4:	692a                	ld	s2,136(sp)
    80005ff6:	69ca                	ld	s3,144(sp)
    80005ff8:	6a6a                	ld	s4,152(sp)
    80005ffa:	7a8a                	ld	s5,160(sp)
    80005ffc:	7b2a                	ld	s6,168(sp)
    80005ffe:	7bca                	ld	s7,176(sp)
    80006000:	7c6a                	ld	s8,184(sp)
    80006002:	6c8e                	ld	s9,192(sp)
    80006004:	6d2e                	ld	s10,200(sp)
    80006006:	6dce                	ld	s11,208(sp)
    80006008:	6e6e                	ld	t3,216(sp)
    8000600a:	7e8e                	ld	t4,224(sp)
    8000600c:	7f2e                	ld	t5,232(sp)
    8000600e:	7fce                	ld	t6,240(sp)
    80006010:	6111                	addi	sp,sp,256
    80006012:	10200073          	sret
    80006016:	00000013          	nop
    8000601a:	00000013          	nop
    8000601e:	0001                	nop

0000000080006020 <timervec>:
    80006020:	34051573          	csrrw	a0,mscratch,a0
    80006024:	e10c                	sd	a1,0(a0)
    80006026:	e510                	sd	a2,8(a0)
    80006028:	e914                	sd	a3,16(a0)
    8000602a:	6d0c                	ld	a1,24(a0)
    8000602c:	7110                	ld	a2,32(a0)
    8000602e:	6194                	ld	a3,0(a1)
    80006030:	96b2                	add	a3,a3,a2
    80006032:	e194                	sd	a3,0(a1)
    80006034:	4589                	li	a1,2
    80006036:	14459073          	csrw	sip,a1
    8000603a:	6914                	ld	a3,16(a0)
    8000603c:	6510                	ld	a2,8(a0)
    8000603e:	610c                	ld	a1,0(a0)
    80006040:	34051573          	csrrw	a0,mscratch,a0
    80006044:	30200073          	mret
	...

000000008000604a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000604a:	1141                	addi	sp,sp,-16
    8000604c:	e422                	sd	s0,8(sp)
    8000604e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006050:	0c0007b7          	lui	a5,0xc000
    80006054:	4705                	li	a4,1
    80006056:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006058:	c3d8                	sw	a4,4(a5)
}
    8000605a:	6422                	ld	s0,8(sp)
    8000605c:	0141                	addi	sp,sp,16
    8000605e:	8082                	ret

0000000080006060 <plicinithart>:

void
plicinithart(void)
{
    80006060:	1141                	addi	sp,sp,-16
    80006062:	e406                	sd	ra,8(sp)
    80006064:	e022                	sd	s0,0(sp)
    80006066:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006068:	ffffc097          	auipc	ra,0xffffc
    8000606c:	8ea080e7          	jalr	-1814(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006070:	0085171b          	slliw	a4,a0,0x8
    80006074:	0c0027b7          	lui	a5,0xc002
    80006078:	97ba                	add	a5,a5,a4
    8000607a:	40200713          	li	a4,1026
    8000607e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006082:	00d5151b          	slliw	a0,a0,0xd
    80006086:	0c2017b7          	lui	a5,0xc201
    8000608a:	953e                	add	a0,a0,a5
    8000608c:	00052023          	sw	zero,0(a0)
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret

0000000080006098 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006098:	1141                	addi	sp,sp,-16
    8000609a:	e406                	sd	ra,8(sp)
    8000609c:	e022                	sd	s0,0(sp)
    8000609e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060a0:	ffffc097          	auipc	ra,0xffffc
    800060a4:	8b2080e7          	jalr	-1870(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060a8:	00d5179b          	slliw	a5,a0,0xd
    800060ac:	0c201537          	lui	a0,0xc201
    800060b0:	953e                	add	a0,a0,a5
  return irq;
}
    800060b2:	4148                	lw	a0,4(a0)
    800060b4:	60a2                	ld	ra,8(sp)
    800060b6:	6402                	ld	s0,0(sp)
    800060b8:	0141                	addi	sp,sp,16
    800060ba:	8082                	ret

00000000800060bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060bc:	1101                	addi	sp,sp,-32
    800060be:	ec06                	sd	ra,24(sp)
    800060c0:	e822                	sd	s0,16(sp)
    800060c2:	e426                	sd	s1,8(sp)
    800060c4:	1000                	addi	s0,sp,32
    800060c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	88a080e7          	jalr	-1910(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060d0:	00d5151b          	slliw	a0,a0,0xd
    800060d4:	0c2017b7          	lui	a5,0xc201
    800060d8:	97aa                	add	a5,a5,a0
    800060da:	c3c4                	sw	s1,4(a5)
}
    800060dc:	60e2                	ld	ra,24(sp)
    800060de:	6442                	ld	s0,16(sp)
    800060e0:	64a2                	ld	s1,8(sp)
    800060e2:	6105                	addi	sp,sp,32
    800060e4:	8082                	ret

00000000800060e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060e6:	1141                	addi	sp,sp,-16
    800060e8:	e406                	sd	ra,8(sp)
    800060ea:	e022                	sd	s0,0(sp)
    800060ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060ee:	479d                	li	a5,7
    800060f0:	06a7c963          	blt	a5,a0,80006162 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800060f4:	0001e797          	auipc	a5,0x1e
    800060f8:	f0c78793          	addi	a5,a5,-244 # 80024000 <disk>
    800060fc:	00a78733          	add	a4,a5,a0
    80006100:	6789                	lui	a5,0x2
    80006102:	97ba                	add	a5,a5,a4
    80006104:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006108:	e7ad                	bnez	a5,80006172 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000610a:	00451793          	slli	a5,a0,0x4
    8000610e:	00020717          	auipc	a4,0x20
    80006112:	ef270713          	addi	a4,a4,-270 # 80026000 <disk+0x2000>
    80006116:	6314                	ld	a3,0(a4)
    80006118:	96be                	add	a3,a3,a5
    8000611a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000611e:	6314                	ld	a3,0(a4)
    80006120:	96be                	add	a3,a3,a5
    80006122:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006126:	6314                	ld	a3,0(a4)
    80006128:	96be                	add	a3,a3,a5
    8000612a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000612e:	6318                	ld	a4,0(a4)
    80006130:	97ba                	add	a5,a5,a4
    80006132:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006136:	0001e797          	auipc	a5,0x1e
    8000613a:	eca78793          	addi	a5,a5,-310 # 80024000 <disk>
    8000613e:	97aa                	add	a5,a5,a0
    80006140:	6509                	lui	a0,0x2
    80006142:	953e                	add	a0,a0,a5
    80006144:	4785                	li	a5,1
    80006146:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000614a:	00020517          	auipc	a0,0x20
    8000614e:	ece50513          	addi	a0,a0,-306 # 80026018 <disk+0x2018>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	216080e7          	jalr	534(ra) # 80002368 <wakeup>
}
    8000615a:	60a2                	ld	ra,8(sp)
    8000615c:	6402                	ld	s0,0(sp)
    8000615e:	0141                	addi	sp,sp,16
    80006160:	8082                	ret
    panic("free_desc 1");
    80006162:	00002517          	auipc	a0,0x2
    80006166:	71e50513          	addi	a0,a0,1822 # 80008880 <syscalls+0x330>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3c0080e7          	jalr	960(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006172:	00002517          	auipc	a0,0x2
    80006176:	71e50513          	addi	a0,a0,1822 # 80008890 <syscalls+0x340>
    8000617a:	ffffa097          	auipc	ra,0xffffa
    8000617e:	3b0080e7          	jalr	944(ra) # 8000052a <panic>

0000000080006182 <virtio_disk_init>:
{
    80006182:	1101                	addi	sp,sp,-32
    80006184:	ec06                	sd	ra,24(sp)
    80006186:	e822                	sd	s0,16(sp)
    80006188:	e426                	sd	s1,8(sp)
    8000618a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000618c:	00002597          	auipc	a1,0x2
    80006190:	71458593          	addi	a1,a1,1812 # 800088a0 <syscalls+0x350>
    80006194:	00020517          	auipc	a0,0x20
    80006198:	f9450513          	addi	a0,a0,-108 # 80026128 <disk+0x2128>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	996080e7          	jalr	-1642(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061a4:	100017b7          	lui	a5,0x10001
    800061a8:	4398                	lw	a4,0(a5)
    800061aa:	2701                	sext.w	a4,a4
    800061ac:	747277b7          	lui	a5,0x74727
    800061b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061b4:	0ef71163          	bne	a4,a5,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061b8:	100017b7          	lui	a5,0x10001
    800061bc:	43dc                	lw	a5,4(a5)
    800061be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061c0:	4705                	li	a4,1
    800061c2:	0ce79a63          	bne	a5,a4,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061c6:	100017b7          	lui	a5,0x10001
    800061ca:	479c                	lw	a5,8(a5)
    800061cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061ce:	4709                	li	a4,2
    800061d0:	0ce79363          	bne	a5,a4,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061d4:	100017b7          	lui	a5,0x10001
    800061d8:	47d8                	lw	a4,12(a5)
    800061da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061dc:	554d47b7          	lui	a5,0x554d4
    800061e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061e4:	0af71963          	bne	a4,a5,80006296 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	4705                	li	a4,1
    800061ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f0:	470d                	li	a4,3
    800061f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061f6:	c7ffe737          	lui	a4,0xc7ffe
    800061fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800061fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006200:	2701                	sext.w	a4,a4
    80006202:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006204:	472d                	li	a4,11
    80006206:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006208:	473d                	li	a4,15
    8000620a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000620c:	6705                	lui	a4,0x1
    8000620e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006210:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006214:	5bdc                	lw	a5,52(a5)
    80006216:	2781                	sext.w	a5,a5
  if(max == 0)
    80006218:	c7d9                	beqz	a5,800062a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000621a:	471d                	li	a4,7
    8000621c:	08f77d63          	bgeu	a4,a5,800062b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006220:	100014b7          	lui	s1,0x10001
    80006224:	47a1                	li	a5,8
    80006226:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006228:	6609                	lui	a2,0x2
    8000622a:	4581                	li	a1,0
    8000622c:	0001e517          	auipc	a0,0x1e
    80006230:	dd450513          	addi	a0,a0,-556 # 80024000 <disk>
    80006234:	ffffb097          	auipc	ra,0xffffb
    80006238:	a8a080e7          	jalr	-1398(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000623c:	0001e717          	auipc	a4,0x1e
    80006240:	dc470713          	addi	a4,a4,-572 # 80024000 <disk>
    80006244:	00c75793          	srli	a5,a4,0xc
    80006248:	2781                	sext.w	a5,a5
    8000624a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000624c:	00020797          	auipc	a5,0x20
    80006250:	db478793          	addi	a5,a5,-588 # 80026000 <disk+0x2000>
    80006254:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006256:	0001e717          	auipc	a4,0x1e
    8000625a:	e2a70713          	addi	a4,a4,-470 # 80024080 <disk+0x80>
    8000625e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006260:	0001f717          	auipc	a4,0x1f
    80006264:	da070713          	addi	a4,a4,-608 # 80025000 <disk+0x1000>
    80006268:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000626a:	4705                	li	a4,1
    8000626c:	00e78c23          	sb	a4,24(a5)
    80006270:	00e78ca3          	sb	a4,25(a5)
    80006274:	00e78d23          	sb	a4,26(a5)
    80006278:	00e78da3          	sb	a4,27(a5)
    8000627c:	00e78e23          	sb	a4,28(a5)
    80006280:	00e78ea3          	sb	a4,29(a5)
    80006284:	00e78f23          	sb	a4,30(a5)
    80006288:	00e78fa3          	sb	a4,31(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret
    panic("could not find virtio disk");
    80006296:	00002517          	auipc	a0,0x2
    8000629a:	61a50513          	addi	a0,a0,1562 # 800088b0 <syscalls+0x360>
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	28c080e7          	jalr	652(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800062a6:	00002517          	auipc	a0,0x2
    800062aa:	62a50513          	addi	a0,a0,1578 # 800088d0 <syscalls+0x380>
    800062ae:	ffffa097          	auipc	ra,0xffffa
    800062b2:	27c080e7          	jalr	636(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800062b6:	00002517          	auipc	a0,0x2
    800062ba:	63a50513          	addi	a0,a0,1594 # 800088f0 <syscalls+0x3a0>
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	26c080e7          	jalr	620(ra) # 8000052a <panic>

00000000800062c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062c6:	7119                	addi	sp,sp,-128
    800062c8:	fc86                	sd	ra,120(sp)
    800062ca:	f8a2                	sd	s0,112(sp)
    800062cc:	f4a6                	sd	s1,104(sp)
    800062ce:	f0ca                	sd	s2,96(sp)
    800062d0:	ecce                	sd	s3,88(sp)
    800062d2:	e8d2                	sd	s4,80(sp)
    800062d4:	e4d6                	sd	s5,72(sp)
    800062d6:	e0da                	sd	s6,64(sp)
    800062d8:	fc5e                	sd	s7,56(sp)
    800062da:	f862                	sd	s8,48(sp)
    800062dc:	f466                	sd	s9,40(sp)
    800062de:	f06a                	sd	s10,32(sp)
    800062e0:	ec6e                	sd	s11,24(sp)
    800062e2:	0100                	addi	s0,sp,128
    800062e4:	8aaa                	mv	s5,a0
    800062e6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062e8:	00c52c83          	lw	s9,12(a0)
    800062ec:	001c9c9b          	slliw	s9,s9,0x1
    800062f0:	1c82                	slli	s9,s9,0x20
    800062f2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062f6:	00020517          	auipc	a0,0x20
    800062fa:	e3250513          	addi	a0,a0,-462 # 80026128 <disk+0x2128>
    800062fe:	ffffb097          	auipc	ra,0xffffb
    80006302:	8c4080e7          	jalr	-1852(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006306:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006308:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000630a:	0001ec17          	auipc	s8,0x1e
    8000630e:	cf6c0c13          	addi	s8,s8,-778 # 80024000 <disk>
    80006312:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006314:	4b0d                	li	s6,3
    80006316:	a0ad                	j	80006380 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006318:	00fc0733          	add	a4,s8,a5
    8000631c:	975e                	add	a4,a4,s7
    8000631e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006322:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006324:	0207c563          	bltz	a5,8000634e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006328:	2905                	addiw	s2,s2,1
    8000632a:	0611                	addi	a2,a2,4
    8000632c:	19690d63          	beq	s2,s6,800064c6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006330:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006332:	00020717          	auipc	a4,0x20
    80006336:	ce670713          	addi	a4,a4,-794 # 80026018 <disk+0x2018>
    8000633a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000633c:	00074683          	lbu	a3,0(a4)
    80006340:	fee1                	bnez	a3,80006318 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006342:	2785                	addiw	a5,a5,1
    80006344:	0705                	addi	a4,a4,1
    80006346:	fe979be3          	bne	a5,s1,8000633c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000634a:	57fd                	li	a5,-1
    8000634c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000634e:	01205d63          	blez	s2,80006368 <virtio_disk_rw+0xa2>
    80006352:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006354:	000a2503          	lw	a0,0(s4)
    80006358:	00000097          	auipc	ra,0x0
    8000635c:	d8e080e7          	jalr	-626(ra) # 800060e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006360:	2d85                	addiw	s11,s11,1
    80006362:	0a11                	addi	s4,s4,4
    80006364:	ffb918e3          	bne	s2,s11,80006354 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006368:	00020597          	auipc	a1,0x20
    8000636c:	dc058593          	addi	a1,a1,-576 # 80026128 <disk+0x2128>
    80006370:	00020517          	auipc	a0,0x20
    80006374:	ca850513          	addi	a0,a0,-856 # 80026018 <disk+0x2018>
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	d7c080e7          	jalr	-644(ra) # 800020f4 <sleep>
  for(int i = 0; i < 3; i++){
    80006380:	f8040a13          	addi	s4,s0,-128
{
    80006384:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006386:	894e                	mv	s2,s3
    80006388:	b765                	j	80006330 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000638a:	00020697          	auipc	a3,0x20
    8000638e:	c766b683          	ld	a3,-906(a3) # 80026000 <disk+0x2000>
    80006392:	96ba                	add	a3,a3,a4
    80006394:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006398:	0001e817          	auipc	a6,0x1e
    8000639c:	c6880813          	addi	a6,a6,-920 # 80024000 <disk>
    800063a0:	00020697          	auipc	a3,0x20
    800063a4:	c6068693          	addi	a3,a3,-928 # 80026000 <disk+0x2000>
    800063a8:	6290                	ld	a2,0(a3)
    800063aa:	963a                	add	a2,a2,a4
    800063ac:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800063b0:	0015e593          	ori	a1,a1,1
    800063b4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800063b8:	f8842603          	lw	a2,-120(s0)
    800063bc:	628c                	ld	a1,0(a3)
    800063be:	972e                	add	a4,a4,a1
    800063c0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063c4:	20050593          	addi	a1,a0,512
    800063c8:	0592                	slli	a1,a1,0x4
    800063ca:	95c2                	add	a1,a1,a6
    800063cc:	577d                	li	a4,-1
    800063ce:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063d2:	00461713          	slli	a4,a2,0x4
    800063d6:	6290                	ld	a2,0(a3)
    800063d8:	963a                	add	a2,a2,a4
    800063da:	03078793          	addi	a5,a5,48
    800063de:	97c2                	add	a5,a5,a6
    800063e0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800063e2:	629c                	ld	a5,0(a3)
    800063e4:	97ba                	add	a5,a5,a4
    800063e6:	4605                	li	a2,1
    800063e8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063ea:	629c                	ld	a5,0(a3)
    800063ec:	97ba                	add	a5,a5,a4
    800063ee:	4809                	li	a6,2
    800063f0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800063f4:	629c                	ld	a5,0(a3)
    800063f6:	973e                	add	a4,a4,a5
    800063f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063fc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006400:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006404:	6698                	ld	a4,8(a3)
    80006406:	00275783          	lhu	a5,2(a4)
    8000640a:	8b9d                	andi	a5,a5,7
    8000640c:	0786                	slli	a5,a5,0x1
    8000640e:	97ba                	add	a5,a5,a4
    80006410:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006414:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006418:	6698                	ld	a4,8(a3)
    8000641a:	00275783          	lhu	a5,2(a4)
    8000641e:	2785                	addiw	a5,a5,1
    80006420:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006424:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006428:	100017b7          	lui	a5,0x10001
    8000642c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006430:	004aa783          	lw	a5,4(s5)
    80006434:	02c79163          	bne	a5,a2,80006456 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006438:	00020917          	auipc	s2,0x20
    8000643c:	cf090913          	addi	s2,s2,-784 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006440:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006442:	85ca                	mv	a1,s2
    80006444:	8556                	mv	a0,s5
    80006446:	ffffc097          	auipc	ra,0xffffc
    8000644a:	cae080e7          	jalr	-850(ra) # 800020f4 <sleep>
  while(b->disk == 1) {
    8000644e:	004aa783          	lw	a5,4(s5)
    80006452:	fe9788e3          	beq	a5,s1,80006442 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006456:	f8042903          	lw	s2,-128(s0)
    8000645a:	20090793          	addi	a5,s2,512
    8000645e:	00479713          	slli	a4,a5,0x4
    80006462:	0001e797          	auipc	a5,0x1e
    80006466:	b9e78793          	addi	a5,a5,-1122 # 80024000 <disk>
    8000646a:	97ba                	add	a5,a5,a4
    8000646c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006470:	00020997          	auipc	s3,0x20
    80006474:	b9098993          	addi	s3,s3,-1136 # 80026000 <disk+0x2000>
    80006478:	00491713          	slli	a4,s2,0x4
    8000647c:	0009b783          	ld	a5,0(s3)
    80006480:	97ba                	add	a5,a5,a4
    80006482:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006486:	854a                	mv	a0,s2
    80006488:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000648c:	00000097          	auipc	ra,0x0
    80006490:	c5a080e7          	jalr	-934(ra) # 800060e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006494:	8885                	andi	s1,s1,1
    80006496:	f0ed                	bnez	s1,80006478 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006498:	00020517          	auipc	a0,0x20
    8000649c:	c9050513          	addi	a0,a0,-880 # 80026128 <disk+0x2128>
    800064a0:	ffffa097          	auipc	ra,0xffffa
    800064a4:	7d6080e7          	jalr	2006(ra) # 80000c76 <release>
}
    800064a8:	70e6                	ld	ra,120(sp)
    800064aa:	7446                	ld	s0,112(sp)
    800064ac:	74a6                	ld	s1,104(sp)
    800064ae:	7906                	ld	s2,96(sp)
    800064b0:	69e6                	ld	s3,88(sp)
    800064b2:	6a46                	ld	s4,80(sp)
    800064b4:	6aa6                	ld	s5,72(sp)
    800064b6:	6b06                	ld	s6,64(sp)
    800064b8:	7be2                	ld	s7,56(sp)
    800064ba:	7c42                	ld	s8,48(sp)
    800064bc:	7ca2                	ld	s9,40(sp)
    800064be:	7d02                	ld	s10,32(sp)
    800064c0:	6de2                	ld	s11,24(sp)
    800064c2:	6109                	addi	sp,sp,128
    800064c4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064c6:	f8042503          	lw	a0,-128(s0)
    800064ca:	20050793          	addi	a5,a0,512
    800064ce:	0792                	slli	a5,a5,0x4
  if(write)
    800064d0:	0001e817          	auipc	a6,0x1e
    800064d4:	b3080813          	addi	a6,a6,-1232 # 80024000 <disk>
    800064d8:	00f80733          	add	a4,a6,a5
    800064dc:	01a036b3          	snez	a3,s10
    800064e0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800064e4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064e8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064ec:	7679                	lui	a2,0xffffe
    800064ee:	963e                	add	a2,a2,a5
    800064f0:	00020697          	auipc	a3,0x20
    800064f4:	b1068693          	addi	a3,a3,-1264 # 80026000 <disk+0x2000>
    800064f8:	6298                	ld	a4,0(a3)
    800064fa:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064fc:	0a878593          	addi	a1,a5,168
    80006500:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006502:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006504:	6298                	ld	a4,0(a3)
    80006506:	9732                	add	a4,a4,a2
    80006508:	45c1                	li	a1,16
    8000650a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000650c:	6298                	ld	a4,0(a3)
    8000650e:	9732                	add	a4,a4,a2
    80006510:	4585                	li	a1,1
    80006512:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006516:	f8442703          	lw	a4,-124(s0)
    8000651a:	628c                	ld	a1,0(a3)
    8000651c:	962e                	add	a2,a2,a1
    8000651e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006522:	0712                	slli	a4,a4,0x4
    80006524:	6290                	ld	a2,0(a3)
    80006526:	963a                	add	a2,a2,a4
    80006528:	058a8593          	addi	a1,s5,88
    8000652c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000652e:	6294                	ld	a3,0(a3)
    80006530:	96ba                	add	a3,a3,a4
    80006532:	40000613          	li	a2,1024
    80006536:	c690                	sw	a2,8(a3)
  if(write)
    80006538:	e40d19e3          	bnez	s10,8000638a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000653c:	00020697          	auipc	a3,0x20
    80006540:	ac46b683          	ld	a3,-1340(a3) # 80026000 <disk+0x2000>
    80006544:	96ba                	add	a3,a3,a4
    80006546:	4609                	li	a2,2
    80006548:	00c69623          	sh	a2,12(a3)
    8000654c:	b5b1                	j	80006398 <virtio_disk_rw+0xd2>

000000008000654e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000654e:	1101                	addi	sp,sp,-32
    80006550:	ec06                	sd	ra,24(sp)
    80006552:	e822                	sd	s0,16(sp)
    80006554:	e426                	sd	s1,8(sp)
    80006556:	e04a                	sd	s2,0(sp)
    80006558:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000655a:	00020517          	auipc	a0,0x20
    8000655e:	bce50513          	addi	a0,a0,-1074 # 80026128 <disk+0x2128>
    80006562:	ffffa097          	auipc	ra,0xffffa
    80006566:	660080e7          	jalr	1632(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000656a:	10001737          	lui	a4,0x10001
    8000656e:	533c                	lw	a5,96(a4)
    80006570:	8b8d                	andi	a5,a5,3
    80006572:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006574:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006578:	00020797          	auipc	a5,0x20
    8000657c:	a8878793          	addi	a5,a5,-1400 # 80026000 <disk+0x2000>
    80006580:	6b94                	ld	a3,16(a5)
    80006582:	0207d703          	lhu	a4,32(a5)
    80006586:	0026d783          	lhu	a5,2(a3)
    8000658a:	06f70163          	beq	a4,a5,800065ec <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000658e:	0001e917          	auipc	s2,0x1e
    80006592:	a7290913          	addi	s2,s2,-1422 # 80024000 <disk>
    80006596:	00020497          	auipc	s1,0x20
    8000659a:	a6a48493          	addi	s1,s1,-1430 # 80026000 <disk+0x2000>
    __sync_synchronize();
    8000659e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065a2:	6898                	ld	a4,16(s1)
    800065a4:	0204d783          	lhu	a5,32(s1)
    800065a8:	8b9d                	andi	a5,a5,7
    800065aa:	078e                	slli	a5,a5,0x3
    800065ac:	97ba                	add	a5,a5,a4
    800065ae:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065b0:	20078713          	addi	a4,a5,512
    800065b4:	0712                	slli	a4,a4,0x4
    800065b6:	974a                	add	a4,a4,s2
    800065b8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065bc:	e731                	bnez	a4,80006608 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065be:	20078793          	addi	a5,a5,512
    800065c2:	0792                	slli	a5,a5,0x4
    800065c4:	97ca                	add	a5,a5,s2
    800065c6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800065c8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065cc:	ffffc097          	auipc	ra,0xffffc
    800065d0:	d9c080e7          	jalr	-612(ra) # 80002368 <wakeup>

    disk.used_idx += 1;
    800065d4:	0204d783          	lhu	a5,32(s1)
    800065d8:	2785                	addiw	a5,a5,1
    800065da:	17c2                	slli	a5,a5,0x30
    800065dc:	93c1                	srli	a5,a5,0x30
    800065de:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065e2:	6898                	ld	a4,16(s1)
    800065e4:	00275703          	lhu	a4,2(a4)
    800065e8:	faf71be3          	bne	a4,a5,8000659e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800065ec:	00020517          	auipc	a0,0x20
    800065f0:	b3c50513          	addi	a0,a0,-1220 # 80026128 <disk+0x2128>
    800065f4:	ffffa097          	auipc	ra,0xffffa
    800065f8:	682080e7          	jalr	1666(ra) # 80000c76 <release>
}
    800065fc:	60e2                	ld	ra,24(sp)
    800065fe:	6442                	ld	s0,16(sp)
    80006600:	64a2                	ld	s1,8(sp)
    80006602:	6902                	ld	s2,0(sp)
    80006604:	6105                	addi	sp,sp,32
    80006606:	8082                	ret
      panic("virtio_disk_intr status");
    80006608:	00002517          	auipc	a0,0x2
    8000660c:	30850513          	addi	a0,a0,776 # 80008910 <syscalls+0x3c0>
    80006610:	ffffa097          	auipc	ra,0xffffa
    80006614:	f1a080e7          	jalr	-230(ra) # 8000052a <panic>
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
