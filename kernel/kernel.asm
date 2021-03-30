
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
    80000068:	d2c78793          	addi	a5,a5,-724 # 80005d90 <timervec>
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
    80000122:	362080e7          	jalr	866(ra) # 80002480 <either_copyin>
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
    800001c6:	e0c080e7          	jalr	-500(ra) # 80001fce <sleep>
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
    80000202:	22c080e7          	jalr	556(ra) # 8000242a <either_copyout>
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
    800002e2:	1f8080e7          	jalr	504(ra) # 800024d6 <procdump>
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
    80000436:	d28080e7          	jalr	-728(ra) # 8000215a <wakeup>
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
    80000468:	2b478793          	addi	a5,a5,692 # 80021718 <devsw>
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
    80000882:	8dc080e7          	jalr	-1828(ra) # 8000215a <wakeup>
    
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
    8000090e:	6c4080e7          	jalr	1732(ra) # 80001fce <sleep>
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
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	854080e7          	jalr	-1964(ra) # 80002706 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	f16080e7          	jalr	-234(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	734080e7          	jalr	1844(ra) # 800025f6 <scheduler>
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
    80000f2e:	7b4080e7          	jalr	1972(ra) # 800026de <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	7d4080e7          	jalr	2004(ra) # 80002706 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	e80080e7          	jalr	-384(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	e8e080e7          	jalr	-370(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	054080e7          	jalr	84(ra) # 80002f9e <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	6e6080e7          	jalr	1766(ra) # 80003638 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	694080e7          	jalr	1684(ra) # 800045ee <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f90080e7          	jalr	-112(ra) # 80005ef2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d02080e7          	jalr	-766(ra) # 80001c6c <userinit>
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
    80001840:	c94a0a13          	addi	s4,s4,-876 # 800174d0 <tickslock>
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
    80001876:	17848493          	addi	s1,s1,376
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
    8000190c:	bc898993          	addi	s3,s3,-1080 # 800174d0 <tickslock>
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
    80001934:	e8bc                	sd	a5,80(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	17848493          	addi	s1,s1,376
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
    800019dc:	d46080e7          	jalr	-698(ra) # 8000271e <usertrapret>
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
    800019f6:	bc6080e7          	jalr	-1082(ra) # 800035b8 <fsinit>
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
    80001a7e:	06893683          	ld	a3,104(s2)
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
    80001b3c:	7528                	ld	a0,104(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b48:	0604b423          	sd	zero,104(s1)
  if(p->pagetable)
    80001b4c:	70a8                	ld	a0,96(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b50:	6cac                	ld	a1,88(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
  p->pagetable = 0;
    80001b5a:	0604b023          	sd	zero,96(s1)
  p->sz = 0;
    80001b5e:	0404bc23          	sd	zero,88(s1)
  p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b66:	0404b423          	sd	zero,72(s1)
  p->name[0] = 0;
    80001b6a:	16048423          	sb	zero,360(s1)
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
    80001ba0:	00016917          	auipc	s2,0x16
    80001ba4:	93090913          	addi	s2,s2,-1744 # 800174d0 <tickslock>
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
    80001bc0:	17848493          	addi	s1,s1,376
    80001bc4:	ff2492e3          	bne	s1,s2,80001ba8 <allocproc+0x1c>
  return 0;
    80001bc8:	4481                	li	s1,0
    80001bca:	a095                	j	80001c2e <allocproc+0xa2>
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
  p->priority = NORMAL_PRIORITY;
    80001be8:	4795                	li	a5,5
    80001bea:	c0bc                	sw	a5,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	ee6080e7          	jalr	-282(ra) # 80000ad2 <kalloc>
    80001bf4:	892a                	mv	s2,a0
    80001bf6:	f4a8                	sd	a0,104(s1)
    80001bf8:	c131                	beqz	a0,80001c3c <allocproc+0xb0>
  p->pagetable = proc_pagetable(p);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	e46080e7          	jalr	-442(ra) # 80001a42 <proc_pagetable>
    80001c04:	892a                	mv	s2,a0
    80001c06:	f0a8                	sd	a0,96(s1)
  if(p->pagetable == 0){
    80001c08:	c531                	beqz	a0,80001c54 <allocproc+0xc8>
  memset(&p->context, 0, sizeof(p->context));
    80001c0a:	07000613          	li	a2,112
    80001c0e:	4581                	li	a1,0
    80001c10:	07048513          	addi	a0,s1,112
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	0aa080e7          	jalr	170(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c1c:	00000797          	auipc	a5,0x0
    80001c20:	d9a78793          	addi	a5,a5,-614 # 800019b6 <forkret>
    80001c24:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c26:	68bc                	ld	a5,80(s1)
    80001c28:	6705                	lui	a4,0x1
    80001c2a:	97ba                	add	a5,a5,a4
    80001c2c:	fcbc                	sd	a5,120(s1)
}
    80001c2e:	8526                	mv	a0,s1
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret
    freeproc(p);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	ef2080e7          	jalr	-270(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	02e080e7          	jalr	46(ra) # 80000c76 <release>
    return 0;
    80001c50:	84ca                	mv	s1,s2
    80001c52:	bff1                	j	80001c2e <allocproc+0xa2>
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	eda080e7          	jalr	-294(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	016080e7          	jalr	22(ra) # 80000c76 <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	b7d1                	j	80001c2e <allocproc+0xa2>

0000000080001c6c <userinit>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	f16080e7          	jalr	-234(ra) # 80001b8c <allocproc>
    80001c7e:	84aa                	mv	s1,a0
  initproc = p;
    80001c80:	00007797          	auipc	a5,0x7
    80001c84:	3aa7b423          	sd	a0,936(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c88:	03400613          	li	a2,52
    80001c8c:	00007597          	auipc	a1,0x7
    80001c90:	c8458593          	addi	a1,a1,-892 # 80008910 <initcode>
    80001c94:	7128                	ld	a0,96(a0)
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	69e080e7          	jalr	1694(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001c9e:	6785                	lui	a5,0x1
    80001ca0:	ecbc                	sd	a5,88(s1)
  p->ctime = ticks;
    80001ca2:	00007717          	auipc	a4,0x7
    80001ca6:	38e72703          	lw	a4,910(a4) # 80009030 <ticks>
    80001caa:	dc98                	sw	a4,56(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cac:	74b8                	ld	a4,104(s1)
    80001cae:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cb2:	74b8                	ld	a4,104(s1)
    80001cb4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cb6:	4641                	li	a2,16
    80001cb8:	00006597          	auipc	a1,0x6
    80001cbc:	53058593          	addi	a1,a1,1328 # 800081e8 <digits+0x1a8>
    80001cc0:	16848513          	addi	a0,s1,360
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	14c080e7          	jalr	332(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001ccc:	00006517          	auipc	a0,0x6
    80001cd0:	52c50513          	addi	a0,a0,1324 # 800081f8 <digits+0x1b8>
    80001cd4:	00002097          	auipc	ra,0x2
    80001cd8:	312080e7          	jalr	786(ra) # 80003fe6 <namei>
    80001cdc:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001ce0:	478d                	li	a5,3
    80001ce2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	f90080e7          	jalr	-112(ra) # 80000c76 <release>
}
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret

0000000080001cf8 <growproc>:
{
    80001cf8:	1101                	addi	sp,sp,-32
    80001cfa:	ec06                	sd	ra,24(sp)
    80001cfc:	e822                	sd	s0,16(sp)
    80001cfe:	e426                	sd	s1,8(sp)
    80001d00:	e04a                	sd	s2,0(sp)
    80001d02:	1000                	addi	s0,sp,32
    80001d04:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	c78080e7          	jalr	-904(ra) # 8000197e <myproc>
    80001d0e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d10:	6d2c                	ld	a1,88(a0)
    80001d12:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d16:	00904f63          	bgtz	s1,80001d34 <growproc+0x3c>
  } else if(n < 0){
    80001d1a:	0204cc63          	bltz	s1,80001d52 <growproc+0x5a>
  p->sz = sz;
    80001d1e:	1602                	slli	a2,a2,0x20
    80001d20:	9201                	srli	a2,a2,0x20
    80001d22:	04c93c23          	sd	a2,88(s2)
  return 0;
    80001d26:	4501                	li	a0,0
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6902                	ld	s2,0(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d34:	9e25                	addw	a2,a2,s1
    80001d36:	1602                	slli	a2,a2,0x20
    80001d38:	9201                	srli	a2,a2,0x20
    80001d3a:	1582                	slli	a1,a1,0x20
    80001d3c:	9181                	srli	a1,a1,0x20
    80001d3e:	7128                	ld	a0,96(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6ae080e7          	jalr	1710(ra) # 800013ee <uvmalloc>
    80001d48:	0005061b          	sext.w	a2,a0
    80001d4c:	fa69                	bnez	a2,80001d1e <growproc+0x26>
      return -1;
    80001d4e:	557d                	li	a0,-1
    80001d50:	bfe1                	j	80001d28 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d52:	9e25                	addw	a2,a2,s1
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	1582                	slli	a1,a1,0x20
    80001d5a:	9181                	srli	a1,a1,0x20
    80001d5c:	7128                	ld	a0,96(a0)
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	648080e7          	jalr	1608(ra) # 800013a6 <uvmdealloc>
    80001d66:	0005061b          	sext.w	a2,a0
    80001d6a:	bf55                	j	80001d1e <growproc+0x26>

0000000080001d6c <fork>:
{
    80001d6c:	7139                	addi	sp,sp,-64
    80001d6e:	fc06                	sd	ra,56(sp)
    80001d70:	f822                	sd	s0,48(sp)
    80001d72:	f426                	sd	s1,40(sp)
    80001d74:	f04a                	sd	s2,32(sp)
    80001d76:	ec4e                	sd	s3,24(sp)
    80001d78:	e852                	sd	s4,16(sp)
    80001d7a:	e456                	sd	s5,8(sp)
    80001d7c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	c00080e7          	jalr	-1024(ra) # 8000197e <myproc>
    80001d86:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	e04080e7          	jalr	-508(ra) # 80001b8c <allocproc>
    80001d90:	12050463          	beqz	a0,80001eb8 <fork+0x14c>
    80001d94:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d96:	058ab603          	ld	a2,88(s5)
    80001d9a:	712c                	ld	a1,96(a0)
    80001d9c:	060ab503          	ld	a0,96(s5)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	79a080e7          	jalr	1946(ra) # 8000153a <uvmcopy>
    80001da8:	06054063          	bltz	a0,80001e08 <fork+0x9c>
  np->sz = p->sz;
    80001dac:	058ab783          	ld	a5,88(s5)
    80001db0:	04f9bc23          	sd	a5,88(s3)
  np->mask = p->mask;
    80001db4:	034aa783          	lw	a5,52(s5)
    80001db8:	02f9aa23          	sw	a5,52(s3)
  np->priority = p->priority;
    80001dbc:	040aa783          	lw	a5,64(s5)
    80001dc0:	04f9a023          	sw	a5,64(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	068ab683          	ld	a3,104(s5)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	0689b703          	ld	a4,104(s3)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x66>
  np->trapframe->a0 = 0;
    80001df2:	0689b783          	ld	a5,104(s3)
    80001df6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dfa:	0e0a8493          	addi	s1,s5,224
    80001dfe:	0e098913          	addi	s2,s3,224
    80001e02:	160a8a13          	addi	s4,s5,352
    80001e06:	a00d                	j	80001e28 <fork+0xbc>
    freeproc(np);
    80001e08:	854e                	mv	a0,s3
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	d26080e7          	jalr	-730(ra) # 80001b30 <freeproc>
    release(&np->lock);
    80001e12:	854e                	mv	a0,s3
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	e62080e7          	jalr	-414(ra) # 80000c76 <release>
    return -1;
    80001e1c:	597d                	li	s2,-1
    80001e1e:	a059                	j	80001ea4 <fork+0x138>
  for(i = 0; i < NOFILE; i++)
    80001e20:	04a1                	addi	s1,s1,8
    80001e22:	0921                	addi	s2,s2,8
    80001e24:	01448b63          	beq	s1,s4,80001e3a <fork+0xce>
    if(p->ofile[i])
    80001e28:	6088                	ld	a0,0(s1)
    80001e2a:	d97d                	beqz	a0,80001e20 <fork+0xb4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2c:	00003097          	auipc	ra,0x3
    80001e30:	854080e7          	jalr	-1964(ra) # 80004680 <filedup>
    80001e34:	00a93023          	sd	a0,0(s2)
    80001e38:	b7e5                	j	80001e20 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e3a:	160ab503          	ld	a0,352(s5)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	9b4080e7          	jalr	-1612(ra) # 800037f2 <idup>
    80001e46:	16a9b023          	sd	a0,352(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	168a8593          	addi	a1,s5,360
    80001e50:	16898513          	addi	a0,s3,360
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	fbc080e7          	jalr	-68(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e5c:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e14080e7          	jalr	-492(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e6a:	0000f497          	auipc	s1,0xf
    80001e6e:	44e48493          	addi	s1,s1,1102 # 800112b8 <wait_lock>
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d4e080e7          	jalr	-690(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e7c:	0559b423          	sd	s5,72(s3)
  release(&wait_lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	df4080e7          	jalr	-524(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d36080e7          	jalr	-714(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e94:	478d                	li	a5,3
    80001e96:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dda080e7          	jalr	-550(ra) # 80000c76 <release>
}
    80001ea4:	854a                	mv	a0,s2
    80001ea6:	70e2                	ld	ra,56(sp)
    80001ea8:	7442                	ld	s0,48(sp)
    80001eaa:	74a2                	ld	s1,40(sp)
    80001eac:	7902                	ld	s2,32(sp)
    80001eae:	69e2                	ld	s3,24(sp)
    80001eb0:	6a42                	ld	s4,16(sp)
    80001eb2:	6aa2                	ld	s5,8(sp)
    80001eb4:	6121                	addi	sp,sp,64
    80001eb6:	8082                	ret
    return -1;
    80001eb8:	597d                	li	s2,-1
    80001eba:	b7ed                	j	80001ea4 <fork+0x138>

0000000080001ebc <sched>:
{
    80001ebc:	7179                	addi	sp,sp,-48
    80001ebe:	f406                	sd	ra,40(sp)
    80001ec0:	f022                	sd	s0,32(sp)
    80001ec2:	ec26                	sd	s1,24(sp)
    80001ec4:	e84a                	sd	s2,16(sp)
    80001ec6:	e44e                	sd	s3,8(sp)
    80001ec8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	ab4080e7          	jalr	-1356(ra) # 8000197e <myproc>
    80001ed2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	c74080e7          	jalr	-908(ra) # 80000b48 <holding>
    80001edc:	c93d                	beqz	a0,80001f52 <sched+0x96>
    80001ede:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ee0:	2781                	sext.w	a5,a5
    80001ee2:	079e                	slli	a5,a5,0x7
    80001ee4:	0000f717          	auipc	a4,0xf
    80001ee8:	3bc70713          	addi	a4,a4,956 # 800112a0 <pid_lock>
    80001eec:	97ba                	add	a5,a5,a4
    80001eee:	0a87a703          	lw	a4,168(a5)
    80001ef2:	4785                	li	a5,1
    80001ef4:	06f71763          	bne	a4,a5,80001f62 <sched+0xa6>
  if(p->state == RUNNING)
    80001ef8:	4c98                	lw	a4,24(s1)
    80001efa:	4791                	li	a5,4
    80001efc:	06f70b63          	beq	a4,a5,80001f72 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f00:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f04:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f06:	efb5                	bnez	a5,80001f82 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f08:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f0a:	0000f917          	auipc	s2,0xf
    80001f0e:	39690913          	addi	s2,s2,918 # 800112a0 <pid_lock>
    80001f12:	2781                	sext.w	a5,a5
    80001f14:	079e                	slli	a5,a5,0x7
    80001f16:	97ca                	add	a5,a5,s2
    80001f18:	0ac7a983          	lw	s3,172(a5)
    80001f1c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f1e:	2781                	sext.w	a5,a5
    80001f20:	079e                	slli	a5,a5,0x7
    80001f22:	0000f597          	auipc	a1,0xf
    80001f26:	3b658593          	addi	a1,a1,950 # 800112d8 <cpus+0x8>
    80001f2a:	95be                	add	a1,a1,a5
    80001f2c:	07048513          	addi	a0,s1,112
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	744080e7          	jalr	1860(ra) # 80002674 <swtch>
    80001f38:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f3a:	2781                	sext.w	a5,a5
    80001f3c:	079e                	slli	a5,a5,0x7
    80001f3e:	97ca                	add	a5,a5,s2
    80001f40:	0b37a623          	sw	s3,172(a5)
}
    80001f44:	70a2                	ld	ra,40(sp)
    80001f46:	7402                	ld	s0,32(sp)
    80001f48:	64e2                	ld	s1,24(sp)
    80001f4a:	6942                	ld	s2,16(sp)
    80001f4c:	69a2                	ld	s3,8(sp)
    80001f4e:	6145                	addi	sp,sp,48
    80001f50:	8082                	ret
    panic("sched p->lock");
    80001f52:	00006517          	auipc	a0,0x6
    80001f56:	2ae50513          	addi	a0,a0,686 # 80008200 <digits+0x1c0>
    80001f5a:	ffffe097          	auipc	ra,0xffffe
    80001f5e:	5d0080e7          	jalr	1488(ra) # 8000052a <panic>
    panic("sched locks");
    80001f62:	00006517          	auipc	a0,0x6
    80001f66:	2ae50513          	addi	a0,a0,686 # 80008210 <digits+0x1d0>
    80001f6a:	ffffe097          	auipc	ra,0xffffe
    80001f6e:	5c0080e7          	jalr	1472(ra) # 8000052a <panic>
    panic("sched running");
    80001f72:	00006517          	auipc	a0,0x6
    80001f76:	2ae50513          	addi	a0,a0,686 # 80008220 <digits+0x1e0>
    80001f7a:	ffffe097          	auipc	ra,0xffffe
    80001f7e:	5b0080e7          	jalr	1456(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001f82:	00006517          	auipc	a0,0x6
    80001f86:	2ae50513          	addi	a0,a0,686 # 80008230 <digits+0x1f0>
    80001f8a:	ffffe097          	auipc	ra,0xffffe
    80001f8e:	5a0080e7          	jalr	1440(ra) # 8000052a <panic>

0000000080001f92 <yield>:
{
    80001f92:	1101                	addi	sp,sp,-32
    80001f94:	ec06                	sd	ra,24(sp)
    80001f96:	e822                	sd	s0,16(sp)
    80001f98:	e426                	sd	s1,8(sp)
    80001f9a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	9e2080e7          	jalr	-1566(ra) # 8000197e <myproc>
    80001fa4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c1c080e7          	jalr	-996(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80001fae:	478d                	li	a5,3
    80001fb0:	cc9c                	sw	a5,24(s1)
  sched();
    80001fb2:	00000097          	auipc	ra,0x0
    80001fb6:	f0a080e7          	jalr	-246(ra) # 80001ebc <sched>
  release(&p->lock);
    80001fba:	8526                	mv	a0,s1
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	cba080e7          	jalr	-838(ra) # 80000c76 <release>
}
    80001fc4:	60e2                	ld	ra,24(sp)
    80001fc6:	6442                	ld	s0,16(sp)
    80001fc8:	64a2                	ld	s1,8(sp)
    80001fca:	6105                	addi	sp,sp,32
    80001fcc:	8082                	ret

0000000080001fce <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001fce:	7179                	addi	sp,sp,-48
    80001fd0:	f406                	sd	ra,40(sp)
    80001fd2:	f022                	sd	s0,32(sp)
    80001fd4:	ec26                	sd	s1,24(sp)
    80001fd6:	e84a                	sd	s2,16(sp)
    80001fd8:	e44e                	sd	s3,8(sp)
    80001fda:	1800                	addi	s0,sp,48
    80001fdc:	89aa                	mv	s3,a0
    80001fde:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	99e080e7          	jalr	-1634(ra) # 8000197e <myproc>
    80001fe8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	bd8080e7          	jalr	-1064(ra) # 80000bc2 <acquire>
  release(lk);
    80001ff2:	854a                	mv	a0,s2
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	c82080e7          	jalr	-894(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80001ffc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002000:	4789                	li	a5,2
    80002002:	cc9c                	sw	a5,24(s1)

  sched();
    80002004:	00000097          	auipc	ra,0x0
    80002008:	eb8080e7          	jalr	-328(ra) # 80001ebc <sched>

  // Tidy up.
  p->chan = 0;
    8000200c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002010:	8526                	mv	a0,s1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	c64080e7          	jalr	-924(ra) # 80000c76 <release>
  acquire(lk);
    8000201a:	854a                	mv	a0,s2
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	ba6080e7          	jalr	-1114(ra) # 80000bc2 <acquire>
}
    80002024:	70a2                	ld	ra,40(sp)
    80002026:	7402                	ld	s0,32(sp)
    80002028:	64e2                	ld	s1,24(sp)
    8000202a:	6942                	ld	s2,16(sp)
    8000202c:	69a2                	ld	s3,8(sp)
    8000202e:	6145                	addi	sp,sp,48
    80002030:	8082                	ret

0000000080002032 <wait>:
{
    80002032:	715d                	addi	sp,sp,-80
    80002034:	e486                	sd	ra,72(sp)
    80002036:	e0a2                	sd	s0,64(sp)
    80002038:	fc26                	sd	s1,56(sp)
    8000203a:	f84a                	sd	s2,48(sp)
    8000203c:	f44e                	sd	s3,40(sp)
    8000203e:	f052                	sd	s4,32(sp)
    80002040:	ec56                	sd	s5,24(sp)
    80002042:	e85a                	sd	s6,16(sp)
    80002044:	e45e                	sd	s7,8(sp)
    80002046:	e062                	sd	s8,0(sp)
    80002048:	0880                	addi	s0,sp,80
    8000204a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	932080e7          	jalr	-1742(ra) # 8000197e <myproc>
    80002054:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002056:	0000f517          	auipc	a0,0xf
    8000205a:	26250513          	addi	a0,a0,610 # 800112b8 <wait_lock>
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	b64080e7          	jalr	-1180(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002066:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002068:	4a15                	li	s4,5
        havekids = 1;
    8000206a:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000206c:	00015997          	auipc	s3,0x15
    80002070:	46498993          	addi	s3,s3,1124 # 800174d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002074:	0000fc17          	auipc	s8,0xf
    80002078:	244c0c13          	addi	s8,s8,580 # 800112b8 <wait_lock>
    havekids = 0;
    8000207c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000207e:	0000f497          	auipc	s1,0xf
    80002082:	65248493          	addi	s1,s1,1618 # 800116d0 <proc>
    80002086:	a0bd                	j	800020f4 <wait+0xc2>
          pid = np->pid;
    80002088:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000208c:	000b0e63          	beqz	s6,800020a8 <wait+0x76>
    80002090:	4691                	li	a3,4
    80002092:	02c48613          	addi	a2,s1,44
    80002096:	85da                	mv	a1,s6
    80002098:	06093503          	ld	a0,96(s2)
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	5a2080e7          	jalr	1442(ra) # 8000163e <copyout>
    800020a4:	02054563          	bltz	a0,800020ce <wait+0x9c>
          freeproc(np);
    800020a8:	8526                	mv	a0,s1
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	a86080e7          	jalr	-1402(ra) # 80001b30 <freeproc>
          release(&np->lock);
    800020b2:	8526                	mv	a0,s1
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	bc2080e7          	jalr	-1086(ra) # 80000c76 <release>
          release(&wait_lock);
    800020bc:	0000f517          	auipc	a0,0xf
    800020c0:	1fc50513          	addi	a0,a0,508 # 800112b8 <wait_lock>
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	bb2080e7          	jalr	-1102(ra) # 80000c76 <release>
          return pid;
    800020cc:	a09d                	j	80002132 <wait+0x100>
            release(&np->lock);
    800020ce:	8526                	mv	a0,s1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	ba6080e7          	jalr	-1114(ra) # 80000c76 <release>
            release(&wait_lock);
    800020d8:	0000f517          	auipc	a0,0xf
    800020dc:	1e050513          	addi	a0,a0,480 # 800112b8 <wait_lock>
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	b96080e7          	jalr	-1130(ra) # 80000c76 <release>
            return -1;
    800020e8:	59fd                	li	s3,-1
    800020ea:	a0a1                	j	80002132 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800020ec:	17848493          	addi	s1,s1,376
    800020f0:	03348463          	beq	s1,s3,80002118 <wait+0xe6>
      if(np->parent == p){
    800020f4:	64bc                	ld	a5,72(s1)
    800020f6:	ff279be3          	bne	a5,s2,800020ec <wait+0xba>
        acquire(&np->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ac6080e7          	jalr	-1338(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002104:	4c9c                	lw	a5,24(s1)
    80002106:	f94781e3          	beq	a5,s4,80002088 <wait+0x56>
        release(&np->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b6a080e7          	jalr	-1174(ra) # 80000c76 <release>
        havekids = 1;
    80002114:	8756                	mv	a4,s5
    80002116:	bfd9                	j	800020ec <wait+0xba>
    if(!havekids || p->killed){
    80002118:	c701                	beqz	a4,80002120 <wait+0xee>
    8000211a:	02892783          	lw	a5,40(s2)
    8000211e:	c79d                	beqz	a5,8000214c <wait+0x11a>
      release(&wait_lock);
    80002120:	0000f517          	auipc	a0,0xf
    80002124:	19850513          	addi	a0,a0,408 # 800112b8 <wait_lock>
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b4e080e7          	jalr	-1202(ra) # 80000c76 <release>
      return -1;
    80002130:	59fd                	li	s3,-1
}
    80002132:	854e                	mv	a0,s3
    80002134:	60a6                	ld	ra,72(sp)
    80002136:	6406                	ld	s0,64(sp)
    80002138:	74e2                	ld	s1,56(sp)
    8000213a:	7942                	ld	s2,48(sp)
    8000213c:	79a2                	ld	s3,40(sp)
    8000213e:	7a02                	ld	s4,32(sp)
    80002140:	6ae2                	ld	s5,24(sp)
    80002142:	6b42                	ld	s6,16(sp)
    80002144:	6ba2                	ld	s7,8(sp)
    80002146:	6c02                	ld	s8,0(sp)
    80002148:	6161                	addi	sp,sp,80
    8000214a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000214c:	85e2                	mv	a1,s8
    8000214e:	854a                	mv	a0,s2
    80002150:	00000097          	auipc	ra,0x0
    80002154:	e7e080e7          	jalr	-386(ra) # 80001fce <sleep>
    havekids = 0;
    80002158:	b715                	j	8000207c <wait+0x4a>

000000008000215a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215a:	7139                	addi	sp,sp,-64
    8000215c:	fc06                	sd	ra,56(sp)
    8000215e:	f822                	sd	s0,48(sp)
    80002160:	f426                	sd	s1,40(sp)
    80002162:	f04a                	sd	s2,32(sp)
    80002164:	ec4e                	sd	s3,24(sp)
    80002166:	e852                	sd	s4,16(sp)
    80002168:	e456                	sd	s5,8(sp)
    8000216a:	0080                	addi	s0,sp,64
    8000216c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000216e:	0000f497          	auipc	s1,0xf
    80002172:	56248493          	addi	s1,s1,1378 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002176:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002178:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217a:	00015917          	auipc	s2,0x15
    8000217e:	35690913          	addi	s2,s2,854 # 800174d0 <tickslock>
    80002182:	a811                	j	80002196 <wakeup+0x3c>
      }
      release(&p->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	af0080e7          	jalr	-1296(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	17848493          	addi	s1,s1,376
    80002192:	03248663          	beq	s1,s2,800021be <wakeup+0x64>
    if(p != myproc()){
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	7e8080e7          	jalr	2024(ra) # 8000197e <myproc>
    8000219e:	fea488e3          	beq	s1,a0,8000218e <wakeup+0x34>
      acquire(&p->lock);
    800021a2:	8526                	mv	a0,s1
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	a1e080e7          	jalr	-1506(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021ac:	4c9c                	lw	a5,24(s1)
    800021ae:	fd379be3          	bne	a5,s3,80002184 <wakeup+0x2a>
    800021b2:	709c                	ld	a5,32(s1)
    800021b4:	fd4798e3          	bne	a5,s4,80002184 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021b8:	0154ac23          	sw	s5,24(s1)
    800021bc:	b7e1                	j	80002184 <wakeup+0x2a>
    }
  }
}
    800021be:	70e2                	ld	ra,56(sp)
    800021c0:	7442                	ld	s0,48(sp)
    800021c2:	74a2                	ld	s1,40(sp)
    800021c4:	7902                	ld	s2,32(sp)
    800021c6:	69e2                	ld	s3,24(sp)
    800021c8:	6a42                	ld	s4,16(sp)
    800021ca:	6aa2                	ld	s5,8(sp)
    800021cc:	6121                	addi	sp,sp,64
    800021ce:	8082                	ret

00000000800021d0 <reparent>:
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	e052                	sd	s4,0(sp)
    800021de:	1800                	addi	s0,sp,48
    800021e0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e2:	0000f497          	auipc	s1,0xf
    800021e6:	4ee48493          	addi	s1,s1,1262 # 800116d0 <proc>
      pp->parent = initproc;
    800021ea:	00007a17          	auipc	s4,0x7
    800021ee:	e3ea0a13          	addi	s4,s4,-450 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f2:	00015997          	auipc	s3,0x15
    800021f6:	2de98993          	addi	s3,s3,734 # 800174d0 <tickslock>
    800021fa:	a029                	j	80002204 <reparent+0x34>
    800021fc:	17848493          	addi	s1,s1,376
    80002200:	01348d63          	beq	s1,s3,8000221a <reparent+0x4a>
    if(pp->parent == p){
    80002204:	64bc                	ld	a5,72(s1)
    80002206:	ff279be3          	bne	a5,s2,800021fc <reparent+0x2c>
      pp->parent = initproc;
    8000220a:	000a3503          	ld	a0,0(s4)
    8000220e:	e4a8                	sd	a0,72(s1)
      wakeup(initproc);
    80002210:	00000097          	auipc	ra,0x0
    80002214:	f4a080e7          	jalr	-182(ra) # 8000215a <wakeup>
    80002218:	b7d5                	j	800021fc <reparent+0x2c>
}
    8000221a:	70a2                	ld	ra,40(sp)
    8000221c:	7402                	ld	s0,32(sp)
    8000221e:	64e2                	ld	s1,24(sp)
    80002220:	6942                	ld	s2,16(sp)
    80002222:	69a2                	ld	s3,8(sp)
    80002224:	6a02                	ld	s4,0(sp)
    80002226:	6145                	addi	sp,sp,48
    80002228:	8082                	ret

000000008000222a <exit>:
{
    8000222a:	7179                	addi	sp,sp,-48
    8000222c:	f406                	sd	ra,40(sp)
    8000222e:	f022                	sd	s0,32(sp)
    80002230:	ec26                	sd	s1,24(sp)
    80002232:	e84a                	sd	s2,16(sp)
    80002234:	e44e                	sd	s3,8(sp)
    80002236:	e052                	sd	s4,0(sp)
    80002238:	1800                	addi	s0,sp,48
    8000223a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	742080e7          	jalr	1858(ra) # 8000197e <myproc>
    80002244:	89aa                	mv	s3,a0
  if(p == initproc)
    80002246:	00007797          	auipc	a5,0x7
    8000224a:	de27b783          	ld	a5,-542(a5) # 80009028 <initproc>
    8000224e:	0e050493          	addi	s1,a0,224
    80002252:	16050913          	addi	s2,a0,352
    80002256:	02a79363          	bne	a5,a0,8000227c <exit+0x52>
    panic("init exiting");
    8000225a:	00006517          	auipc	a0,0x6
    8000225e:	fee50513          	addi	a0,a0,-18 # 80008248 <digits+0x208>
    80002262:	ffffe097          	auipc	ra,0xffffe
    80002266:	2c8080e7          	jalr	712(ra) # 8000052a <panic>
      fileclose(f);
    8000226a:	00002097          	auipc	ra,0x2
    8000226e:	468080e7          	jalr	1128(ra) # 800046d2 <fileclose>
      p->ofile[fd] = 0;
    80002272:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002276:	04a1                	addi	s1,s1,8
    80002278:	01248563          	beq	s1,s2,80002282 <exit+0x58>
    if(p->ofile[fd]){
    8000227c:	6088                	ld	a0,0(s1)
    8000227e:	f575                	bnez	a0,8000226a <exit+0x40>
    80002280:	bfdd                	j	80002276 <exit+0x4c>
  begin_op();
    80002282:	00002097          	auipc	ra,0x2
    80002286:	f84080e7          	jalr	-124(ra) # 80004206 <begin_op>
  iput(p->cwd);
    8000228a:	1609b503          	ld	a0,352(s3)
    8000228e:	00001097          	auipc	ra,0x1
    80002292:	75c080e7          	jalr	1884(ra) # 800039ea <iput>
  end_op();
    80002296:	00002097          	auipc	ra,0x2
    8000229a:	ff0080e7          	jalr	-16(ra) # 80004286 <end_op>
  p->cwd = 0;
    8000229e:	1609b023          	sd	zero,352(s3)
  acquire(&wait_lock);
    800022a2:	0000f497          	auipc	s1,0xf
    800022a6:	01648493          	addi	s1,s1,22 # 800112b8 <wait_lock>
    800022aa:	8526                	mv	a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	916080e7          	jalr	-1770(ra) # 80000bc2 <acquire>
  reparent(p);
    800022b4:	854e                	mv	a0,s3
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	f1a080e7          	jalr	-230(ra) # 800021d0 <reparent>
  wakeup(p->parent);
    800022be:	0489b503          	ld	a0,72(s3)
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	e98080e7          	jalr	-360(ra) # 8000215a <wakeup>
  acquire(&p->lock);
    800022ca:	854e                	mv	a0,s3
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	8f6080e7          	jalr	-1802(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800022d4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022d8:	4795                	li	a5,5
    800022da:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022de:	8526                	mv	a0,s1
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	996080e7          	jalr	-1642(ra) # 80000c76 <release>
  sched();
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	bd4080e7          	jalr	-1068(ra) # 80001ebc <sched>
  panic("zombie exit");
    800022f0:	00006517          	auipc	a0,0x6
    800022f4:	f6850513          	addi	a0,a0,-152 # 80008258 <digits+0x218>
    800022f8:	ffffe097          	auipc	ra,0xffffe
    800022fc:	232080e7          	jalr	562(ra) # 8000052a <panic>

0000000080002300 <set_priority>:

int 
set_priority(int prio)
{
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    80002300:	47e5                	li	a5,25
    80002302:	04a7e963          	bltu	a5,a0,80002354 <set_priority+0x54>
{
    80002306:	1101                	addi	sp,sp,-32
    80002308:	ec06                	sd	ra,24(sp)
    8000230a:	e822                	sd	s0,16(sp)
    8000230c:	e426                	sd	s1,8(sp)
    8000230e:	e04a                	sd	s2,0(sp)
    80002310:	1000                	addi	s0,sp,32
    80002312:	892a                	mv	s2,a0
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    80002314:	020007b7          	lui	a5,0x2000
    80002318:	0aa78793          	addi	a5,a5,170 # 20000aa <_entry-0x7dffff56>
    8000231c:	00a7d7b3          	srl	a5,a5,a0
    80002320:	8b85                	andi	a5,a5,1
    && prio != LOW_PRIORITY && prio != TEST_LOW_PRIORITY){
      return -1;
    80002322:	557d                	li	a0,-1
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    80002324:	c395                	beqz	a5,80002348 <set_priority+0x48>
  }
  struct proc *p = myproc();
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	658080e7          	jalr	1624(ra) # 8000197e <myproc>
    8000232e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	892080e7          	jalr	-1902(ra) # 80000bc2 <acquire>
    p->priority = prio;
    80002338:	0524a023          	sw	s2,64(s1)
  release(&p->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	938080e7          	jalr	-1736(ra) # 80000c76 <release>
  return 0;
    80002346:	4501                	li	a0,0
}
    80002348:	60e2                	ld	ra,24(sp)
    8000234a:	6442                	ld	s0,16(sp)
    8000234c:	64a2                	ld	s1,8(sp)
    8000234e:	6902                	ld	s2,0(sp)
    80002350:	6105                	addi	sp,sp,32
    80002352:	8082                	ret
      return -1;
    80002354:	557d                	li	a0,-1
}
    80002356:	8082                	ret

0000000080002358 <trace>:

int 
trace(int mask_input, int pid)
{
    80002358:	7179                	addi	sp,sp,-48
    8000235a:	f406                	sd	ra,40(sp)
    8000235c:	f022                	sd	s0,32(sp)
    8000235e:	ec26                	sd	s1,24(sp)
    80002360:	e84a                	sd	s2,16(sp)
    80002362:	e44e                	sd	s3,8(sp)
    80002364:	e052                	sd	s4,0(sp)
    80002366:	1800                	addi	s0,sp,48
    80002368:	8a2a                	mv	s4,a0
    8000236a:	892e                	mv	s2,a1
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    8000236c:	0000f497          	auipc	s1,0xf
    80002370:	36448493          	addi	s1,s1,868 # 800116d0 <proc>
    80002374:	00015997          	auipc	s3,0x15
    80002378:	15c98993          	addi	s3,s3,348 # 800174d0 <tickslock>
    8000237c:	a811                	j	80002390 <trace+0x38>
    acquire(&p->lock);
    if(p->pid == pid)
      p->mask = mask_input;
    release(&p->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	8f6080e7          	jalr	-1802(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002388:	17848493          	addi	s1,s1,376
    8000238c:	01348d63          	beq	s1,s3,800023a6 <trace+0x4e>
    acquire(&p->lock);
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	830080e7          	jalr	-2000(ra) # 80000bc2 <acquire>
    if(p->pid == pid)
    8000239a:	589c                	lw	a5,48(s1)
    8000239c:	ff2791e3          	bne	a5,s2,8000237e <trace+0x26>
      p->mask = mask_input;
    800023a0:	0344aa23          	sw	s4,52(s1)
    800023a4:	bfe9                	j	8000237e <trace+0x26>
  }
  return 0;
}
    800023a6:	4501                	li	a0,0
    800023a8:	70a2                	ld	ra,40(sp)
    800023aa:	7402                	ld	s0,32(sp)
    800023ac:	64e2                	ld	s1,24(sp)
    800023ae:	6942                	ld	s2,16(sp)
    800023b0:	69a2                	ld	s3,8(sp)
    800023b2:	6a02                	ld	s4,0(sp)
    800023b4:	6145                	addi	sp,sp,48
    800023b6:	8082                	ret

00000000800023b8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023b8:	7179                	addi	sp,sp,-48
    800023ba:	f406                	sd	ra,40(sp)
    800023bc:	f022                	sd	s0,32(sp)
    800023be:	ec26                	sd	s1,24(sp)
    800023c0:	e84a                	sd	s2,16(sp)
    800023c2:	e44e                	sd	s3,8(sp)
    800023c4:	1800                	addi	s0,sp,48
    800023c6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023c8:	0000f497          	auipc	s1,0xf
    800023cc:	30848493          	addi	s1,s1,776 # 800116d0 <proc>
    800023d0:	00015997          	auipc	s3,0x15
    800023d4:	10098993          	addi	s3,s3,256 # 800174d0 <tickslock>
    acquire(&p->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	7e8080e7          	jalr	2024(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023e2:	589c                	lw	a5,48(s1)
    800023e4:	01278d63          	beq	a5,s2,800023fe <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	88c080e7          	jalr	-1908(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023f2:	17848493          	addi	s1,s1,376
    800023f6:	ff3491e3          	bne	s1,s3,800023d8 <kill+0x20>
  }
  return -1;
    800023fa:	557d                	li	a0,-1
    800023fc:	a829                	j	80002416 <kill+0x5e>
      p->killed = 1;
    800023fe:	4785                	li	a5,1
    80002400:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002402:	4c98                	lw	a4,24(s1)
    80002404:	4789                	li	a5,2
    80002406:	00f70f63          	beq	a4,a5,80002424 <kill+0x6c>
      release(&p->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	86a080e7          	jalr	-1942(ra) # 80000c76 <release>
      return 0;
    80002414:	4501                	li	a0,0
}
    80002416:	70a2                	ld	ra,40(sp)
    80002418:	7402                	ld	s0,32(sp)
    8000241a:	64e2                	ld	s1,24(sp)
    8000241c:	6942                	ld	s2,16(sp)
    8000241e:	69a2                	ld	s3,8(sp)
    80002420:	6145                	addi	sp,sp,48
    80002422:	8082                	ret
        p->state = RUNNABLE;
    80002424:	478d                	li	a5,3
    80002426:	cc9c                	sw	a5,24(s1)
    80002428:	b7cd                	j	8000240a <kill+0x52>

000000008000242a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000242a:	7179                	addi	sp,sp,-48
    8000242c:	f406                	sd	ra,40(sp)
    8000242e:	f022                	sd	s0,32(sp)
    80002430:	ec26                	sd	s1,24(sp)
    80002432:	e84a                	sd	s2,16(sp)
    80002434:	e44e                	sd	s3,8(sp)
    80002436:	e052                	sd	s4,0(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	84aa                	mv	s1,a0
    8000243c:	892e                	mv	s2,a1
    8000243e:	89b2                	mv	s3,a2
    80002440:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	53c080e7          	jalr	1340(ra) # 8000197e <myproc>
  if(user_dst){
    8000244a:	c08d                	beqz	s1,8000246c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000244c:	86d2                	mv	a3,s4
    8000244e:	864e                	mv	a2,s3
    80002450:	85ca                	mv	a1,s2
    80002452:	7128                	ld	a0,96(a0)
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	1ea080e7          	jalr	490(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000245c:	70a2                	ld	ra,40(sp)
    8000245e:	7402                	ld	s0,32(sp)
    80002460:	64e2                	ld	s1,24(sp)
    80002462:	6942                	ld	s2,16(sp)
    80002464:	69a2                	ld	s3,8(sp)
    80002466:	6a02                	ld	s4,0(sp)
    80002468:	6145                	addi	sp,sp,48
    8000246a:	8082                	ret
    memmove((char *)dst, src, len);
    8000246c:	000a061b          	sext.w	a2,s4
    80002470:	85ce                	mv	a1,s3
    80002472:	854a                	mv	a0,s2
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	8a6080e7          	jalr	-1882(ra) # 80000d1a <memmove>
    return 0;
    8000247c:	8526                	mv	a0,s1
    8000247e:	bff9                	j	8000245c <either_copyout+0x32>

0000000080002480 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002480:	7179                	addi	sp,sp,-48
    80002482:	f406                	sd	ra,40(sp)
    80002484:	f022                	sd	s0,32(sp)
    80002486:	ec26                	sd	s1,24(sp)
    80002488:	e84a                	sd	s2,16(sp)
    8000248a:	e44e                	sd	s3,8(sp)
    8000248c:	e052                	sd	s4,0(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	892a                	mv	s2,a0
    80002492:	84ae                	mv	s1,a1
    80002494:	89b2                	mv	s3,a2
    80002496:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	4e6080e7          	jalr	1254(ra) # 8000197e <myproc>
  if(user_src){
    800024a0:	c08d                	beqz	s1,800024c2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024a2:	86d2                	mv	a3,s4
    800024a4:	864e                	mv	a2,s3
    800024a6:	85ca                	mv	a1,s2
    800024a8:	7128                	ld	a0,96(a0)
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	220080e7          	jalr	544(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024b2:	70a2                	ld	ra,40(sp)
    800024b4:	7402                	ld	s0,32(sp)
    800024b6:	64e2                	ld	s1,24(sp)
    800024b8:	6942                	ld	s2,16(sp)
    800024ba:	69a2                	ld	s3,8(sp)
    800024bc:	6a02                	ld	s4,0(sp)
    800024be:	6145                	addi	sp,sp,48
    800024c0:	8082                	ret
    memmove(dst, (char*)src, len);
    800024c2:	000a061b          	sext.w	a2,s4
    800024c6:	85ce                	mv	a1,s3
    800024c8:	854a                	mv	a0,s2
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	850080e7          	jalr	-1968(ra) # 80000d1a <memmove>
    return 0;
    800024d2:	8526                	mv	a0,s1
    800024d4:	bff9                	j	800024b2 <either_copyin+0x32>

00000000800024d6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024d6:	715d                	addi	sp,sp,-80
    800024d8:	e486                	sd	ra,72(sp)
    800024da:	e0a2                	sd	s0,64(sp)
    800024dc:	fc26                	sd	s1,56(sp)
    800024de:	f84a                	sd	s2,48(sp)
    800024e0:	f44e                	sd	s3,40(sp)
    800024e2:	f052                	sd	s4,32(sp)
    800024e4:	ec56                	sd	s5,24(sp)
    800024e6:	e85a                	sd	s6,16(sp)
    800024e8:	e45e                	sd	s7,8(sp)
    800024ea:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024ec:	00006517          	auipc	a0,0x6
    800024f0:	bdc50513          	addi	a0,a0,-1060 # 800080c8 <digits+0x88>
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	080080e7          	jalr	128(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024fc:	0000f497          	auipc	s1,0xf
    80002500:	33c48493          	addi	s1,s1,828 # 80011838 <proc+0x168>
    80002504:	00015917          	auipc	s2,0x15
    80002508:	13490913          	addi	s2,s2,308 # 80017638 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000250c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000250e:	00006997          	auipc	s3,0x6
    80002512:	d5a98993          	addi	s3,s3,-678 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002516:	00006a97          	auipc	s5,0x6
    8000251a:	d5aa8a93          	addi	s5,s5,-678 # 80008270 <digits+0x230>
    printf("\n");
    8000251e:	00006a17          	auipc	s4,0x6
    80002522:	baaa0a13          	addi	s4,s4,-1110 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002526:	00006b97          	auipc	s7,0x6
    8000252a:	d82b8b93          	addi	s7,s7,-638 # 800082a8 <states.0>
    8000252e:	a00d                	j	80002550 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002530:	ec86a583          	lw	a1,-312(a3)
    80002534:	8556                	mv	a0,s5
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	03e080e7          	jalr	62(ra) # 80000574 <printf>
    printf("\n");
    8000253e:	8552                	mv	a0,s4
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	034080e7          	jalr	52(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002548:	17848493          	addi	s1,s1,376
    8000254c:	03248263          	beq	s1,s2,80002570 <procdump+0x9a>
    if(p->state == UNUSED)
    80002550:	86a6                	mv	a3,s1
    80002552:	eb04a783          	lw	a5,-336(s1)
    80002556:	dbed                	beqz	a5,80002548 <procdump+0x72>
      state = "???";
    80002558:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255a:	fcfb6be3          	bltu	s6,a5,80002530 <procdump+0x5a>
    8000255e:	02079713          	slli	a4,a5,0x20
    80002562:	01d75793          	srli	a5,a4,0x1d
    80002566:	97de                	add	a5,a5,s7
    80002568:	6390                	ld	a2,0(a5)
    8000256a:	f279                	bnez	a2,80002530 <procdump+0x5a>
      state = "???";
    8000256c:	864e                	mv	a2,s3
    8000256e:	b7c9                	j	80002530 <procdump+0x5a>
  }
}
    80002570:	60a6                	ld	ra,72(sp)
    80002572:	6406                	ld	s0,64(sp)
    80002574:	74e2                	ld	s1,56(sp)
    80002576:	7942                	ld	s2,48(sp)
    80002578:	79a2                	ld	s3,40(sp)
    8000257a:	7a02                	ld	s4,32(sp)
    8000257c:	6ae2                	ld	s5,24(sp)
    8000257e:	6b42                	ld	s6,16(sp)
    80002580:	6ba2                	ld	s7,8(sp)
    80002582:	6161                	addi	sp,sp,80
    80002584:	8082                	ret

0000000080002586 <inctickcounter>:

int inctickcounter() {
    80002586:	1101                	addi	sp,sp,-32
    80002588:	ec06                	sd	ra,24(sp)
    8000258a:	e822                	sd	s0,16(sp)
    8000258c:	e426                	sd	s1,8(sp)
    8000258e:	e04a                	sd	s2,0(sp)
    80002590:	1000                	addi	s0,sp,32
  int res;
  struct proc *p = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	3ec080e7          	jalr	1004(ra) # 8000197e <myproc>
    8000259a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	626080e7          	jalr	1574(ra) # 80000bc2 <acquire>
  res = proc->tickcounter;
    800025a4:	0000f917          	auipc	s2,0xf
    800025a8:	16892903          	lw	s2,360(s2) # 8001170c <proc+0x3c>
  res++;
  release(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6c8080e7          	jalr	1736(ra) # 80000c76 <release>
  return res;
}
    800025b6:	0019051b          	addiw	a0,s2,1
    800025ba:	60e2                	ld	ra,24(sp)
    800025bc:	6442                	ld	s0,16(sp)
    800025be:	64a2                	ld	s1,8(sp)
    800025c0:	6902                	ld	s2,0(sp)
    800025c2:	6105                	addi	sp,sp,32
    800025c4:	8082                	ret

00000000800025c6 <switch_to_process>:

void switch_to_process(struct proc *p, struct cpu *c){
    800025c6:	1101                	addi	sp,sp,-32
    800025c8:	ec06                	sd	ra,24(sp)
    800025ca:	e822                	sd	s0,16(sp)
    800025cc:	e426                	sd	s1,8(sp)
    800025ce:	1000                	addi	s0,sp,32
    800025d0:	84ae                	mv	s1,a1
  // Switch to chosen process.  It is the process's job
  // to release its lock and then reacquire it
  // before jumping back to us.
  p->state = RUNNING;
    800025d2:	4791                	li	a5,4
    800025d4:	cd1c                	sw	a5,24(a0)
  c->proc = p;
    800025d6:	e188                	sd	a0,0(a1)
  swtch(&c->context, &p->context);
    800025d8:	07050593          	addi	a1,a0,112
    800025dc:	00848513          	addi	a0,s1,8
    800025e0:	00000097          	auipc	ra,0x0
    800025e4:	094080e7          	jalr	148(ra) # 80002674 <swtch>

  // Process is done running for now.
  // It should have changed its p->state before coming back.
  c->proc = 0;
    800025e8:	0004b023          	sd	zero,0(s1)
}
    800025ec:	60e2                	ld	ra,24(sp)
    800025ee:	6442                	ld	s0,16(sp)
    800025f0:	64a2                	ld	s1,8(sp)
    800025f2:	6105                	addi	sp,sp,32
    800025f4:	8082                	ret

00000000800025f6 <scheduler>:
{
    800025f6:	7179                	addi	sp,sp,-48
    800025f8:	f406                	sd	ra,40(sp)
    800025fa:	f022                	sd	s0,32(sp)
    800025fc:	ec26                	sd	s1,24(sp)
    800025fe:	e84a                	sd	s2,16(sp)
    80002600:	e44e                	sd	s3,8(sp)
    80002602:	e052                	sd	s4,0(sp)
    80002604:	1800                	addi	s0,sp,48
    80002606:	8792                	mv	a5,tp
  int id = r_tp();
    80002608:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000260a:	079e                	slli	a5,a5,0x7
    8000260c:	0000fa17          	auipc	s4,0xf
    80002610:	cc4a0a13          	addi	s4,s4,-828 # 800112d0 <cpus>
    80002614:	9a3e                	add	s4,s4,a5
  c->proc = 0;
    80002616:	0000f717          	auipc	a4,0xf
    8000261a:	c8a70713          	addi	a4,a4,-886 # 800112a0 <pid_lock>
    8000261e:	97ba                	add	a5,a5,a4
    80002620:	0207b823          	sd	zero,48(a5)
      if(p->state == RUNNABLE) {
    80002624:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80002626:	00015917          	auipc	s2,0x15
    8000262a:	eaa90913          	addi	s2,s2,-342 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000262e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002632:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002636:	10079073          	csrw	sstatus,a5
    8000263a:	0000f497          	auipc	s1,0xf
    8000263e:	09648493          	addi	s1,s1,150 # 800116d0 <proc>
    80002642:	a811                	j	80002656 <scheduler+0x60>
      release(&p->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	630080e7          	jalr	1584(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000264e:	17848493          	addi	s1,s1,376
    80002652:	fd248ee3          	beq	s1,s2,8000262e <scheduler+0x38>
      acquire(&p->lock);
    80002656:	8526                	mv	a0,s1
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	56a080e7          	jalr	1386(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80002660:	4c9c                	lw	a5,24(s1)
    80002662:	ff3791e3          	bne	a5,s3,80002644 <scheduler+0x4e>
        switch_to_process(p, c);
    80002666:	85d2                	mv	a1,s4
    80002668:	8526                	mv	a0,s1
    8000266a:	00000097          	auipc	ra,0x0
    8000266e:	f5c080e7          	jalr	-164(ra) # 800025c6 <switch_to_process>
    80002672:	bfc9                	j	80002644 <scheduler+0x4e>

0000000080002674 <swtch>:
    80002674:	00153023          	sd	ra,0(a0)
    80002678:	00253423          	sd	sp,8(a0)
    8000267c:	e900                	sd	s0,16(a0)
    8000267e:	ed04                	sd	s1,24(a0)
    80002680:	03253023          	sd	s2,32(a0)
    80002684:	03353423          	sd	s3,40(a0)
    80002688:	03453823          	sd	s4,48(a0)
    8000268c:	03553c23          	sd	s5,56(a0)
    80002690:	05653023          	sd	s6,64(a0)
    80002694:	05753423          	sd	s7,72(a0)
    80002698:	05853823          	sd	s8,80(a0)
    8000269c:	05953c23          	sd	s9,88(a0)
    800026a0:	07a53023          	sd	s10,96(a0)
    800026a4:	07b53423          	sd	s11,104(a0)
    800026a8:	0005b083          	ld	ra,0(a1)
    800026ac:	0085b103          	ld	sp,8(a1)
    800026b0:	6980                	ld	s0,16(a1)
    800026b2:	6d84                	ld	s1,24(a1)
    800026b4:	0205b903          	ld	s2,32(a1)
    800026b8:	0285b983          	ld	s3,40(a1)
    800026bc:	0305ba03          	ld	s4,48(a1)
    800026c0:	0385ba83          	ld	s5,56(a1)
    800026c4:	0405bb03          	ld	s6,64(a1)
    800026c8:	0485bb83          	ld	s7,72(a1)
    800026cc:	0505bc03          	ld	s8,80(a1)
    800026d0:	0585bc83          	ld	s9,88(a1)
    800026d4:	0605bd03          	ld	s10,96(a1)
    800026d8:	0685bd83          	ld	s11,104(a1)
    800026dc:	8082                	ret

00000000800026de <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026de:	1141                	addi	sp,sp,-16
    800026e0:	e406                	sd	ra,8(sp)
    800026e2:	e022                	sd	s0,0(sp)
    800026e4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026e6:	00006597          	auipc	a1,0x6
    800026ea:	bf258593          	addi	a1,a1,-1038 # 800082d8 <states.0+0x30>
    800026ee:	00015517          	auipc	a0,0x15
    800026f2:	de250513          	addi	a0,a0,-542 # 800174d0 <tickslock>
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	43c080e7          	jalr	1084(ra) # 80000b32 <initlock>
}
    800026fe:	60a2                	ld	ra,8(sp)
    80002700:	6402                	ld	s0,0(sp)
    80002702:	0141                	addi	sp,sp,16
    80002704:	8082                	ret

0000000080002706 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002706:	1141                	addi	sp,sp,-16
    80002708:	e422                	sd	s0,8(sp)
    8000270a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000270c:	00003797          	auipc	a5,0x3
    80002710:	5f478793          	addi	a5,a5,1524 # 80005d00 <kernelvec>
    80002714:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002718:	6422                	ld	s0,8(sp)
    8000271a:	0141                	addi	sp,sp,16
    8000271c:	8082                	ret

000000008000271e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000271e:	1141                	addi	sp,sp,-16
    80002720:	e406                	sd	ra,8(sp)
    80002722:	e022                	sd	s0,0(sp)
    80002724:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	258080e7          	jalr	600(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002732:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002734:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002738:	00005617          	auipc	a2,0x5
    8000273c:	8c860613          	addi	a2,a2,-1848 # 80007000 <_trampoline>
    80002740:	00005697          	auipc	a3,0x5
    80002744:	8c068693          	addi	a3,a3,-1856 # 80007000 <_trampoline>
    80002748:	8e91                	sub	a3,a3,a2
    8000274a:	040007b7          	lui	a5,0x4000
    8000274e:	17fd                	addi	a5,a5,-1
    80002750:	07b2                	slli	a5,a5,0xc
    80002752:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002754:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002758:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000275a:	180026f3          	csrr	a3,satp
    8000275e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002760:	7538                	ld	a4,104(a0)
    80002762:	6934                	ld	a3,80(a0)
    80002764:	6585                	lui	a1,0x1
    80002766:	96ae                	add	a3,a3,a1
    80002768:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000276a:	7538                	ld	a4,104(a0)
    8000276c:	00000697          	auipc	a3,0x0
    80002770:	13868693          	addi	a3,a3,312 # 800028a4 <usertrap>
    80002774:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002776:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002778:	8692                	mv	a3,tp
    8000277a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000277c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002780:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002784:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002788:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000278c:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000278e:	6f18                	ld	a4,24(a4)
    80002790:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002794:	712c                	ld	a1,96(a0)
    80002796:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002798:	00005717          	auipc	a4,0x5
    8000279c:	8f870713          	addi	a4,a4,-1800 # 80007090 <userret>
    800027a0:	8f11                	sub	a4,a4,a2
    800027a2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027a4:	577d                	li	a4,-1
    800027a6:	177e                	slli	a4,a4,0x3f
    800027a8:	8dd9                	or	a1,a1,a4
    800027aa:	02000537          	lui	a0,0x2000
    800027ae:	157d                	addi	a0,a0,-1
    800027b0:	0536                	slli	a0,a0,0xd
    800027b2:	9782                	jalr	a5
}
    800027b4:	60a2                	ld	ra,8(sp)
    800027b6:	6402                	ld	s0,0(sp)
    800027b8:	0141                	addi	sp,sp,16
    800027ba:	8082                	ret

00000000800027bc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027bc:	1101                	addi	sp,sp,-32
    800027be:	ec06                	sd	ra,24(sp)
    800027c0:	e822                	sd	s0,16(sp)
    800027c2:	e426                	sd	s1,8(sp)
    800027c4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027c6:	00015497          	auipc	s1,0x15
    800027ca:	d0a48493          	addi	s1,s1,-758 # 800174d0 <tickslock>
    800027ce:	8526                	mv	a0,s1
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	3f2080e7          	jalr	1010(ra) # 80000bc2 <acquire>
  ticks++;
    800027d8:	00007517          	auipc	a0,0x7
    800027dc:	85850513          	addi	a0,a0,-1960 # 80009030 <ticks>
    800027e0:	411c                	lw	a5,0(a0)
    800027e2:	2785                	addiw	a5,a5,1
    800027e4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027e6:	00000097          	auipc	ra,0x0
    800027ea:	974080e7          	jalr	-1676(ra) # 8000215a <wakeup>
  release(&tickslock);
    800027ee:	8526                	mv	a0,s1
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	486080e7          	jalr	1158(ra) # 80000c76 <release>
}
    800027f8:	60e2                	ld	ra,24(sp)
    800027fa:	6442                	ld	s0,16(sp)
    800027fc:	64a2                	ld	s1,8(sp)
    800027fe:	6105                	addi	sp,sp,32
    80002800:	8082                	ret

0000000080002802 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002802:	1101                	addi	sp,sp,-32
    80002804:	ec06                	sd	ra,24(sp)
    80002806:	e822                	sd	s0,16(sp)
    80002808:	e426                	sd	s1,8(sp)
    8000280a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000280c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002810:	00074d63          	bltz	a4,8000282a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002814:	57fd                	li	a5,-1
    80002816:	17fe                	slli	a5,a5,0x3f
    80002818:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000281a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000281c:	06f70363          	beq	a4,a5,80002882 <devintr+0x80>
  }
}
    80002820:	60e2                	ld	ra,24(sp)
    80002822:	6442                	ld	s0,16(sp)
    80002824:	64a2                	ld	s1,8(sp)
    80002826:	6105                	addi	sp,sp,32
    80002828:	8082                	ret
     (scause & 0xff) == 9){
    8000282a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000282e:	46a5                	li	a3,9
    80002830:	fed792e3          	bne	a5,a3,80002814 <devintr+0x12>
    int irq = plic_claim();
    80002834:	00003097          	auipc	ra,0x3
    80002838:	5d4080e7          	jalr	1492(ra) # 80005e08 <plic_claim>
    8000283c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000283e:	47a9                	li	a5,10
    80002840:	02f50763          	beq	a0,a5,8000286e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002844:	4785                	li	a5,1
    80002846:	02f50963          	beq	a0,a5,80002878 <devintr+0x76>
    return 1;
    8000284a:	4505                	li	a0,1
    } else if(irq){
    8000284c:	d8f1                	beqz	s1,80002820 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000284e:	85a6                	mv	a1,s1
    80002850:	00006517          	auipc	a0,0x6
    80002854:	a9050513          	addi	a0,a0,-1392 # 800082e0 <states.0+0x38>
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	d1c080e7          	jalr	-740(ra) # 80000574 <printf>
      plic_complete(irq);
    80002860:	8526                	mv	a0,s1
    80002862:	00003097          	auipc	ra,0x3
    80002866:	5ca080e7          	jalr	1482(ra) # 80005e2c <plic_complete>
    return 1;
    8000286a:	4505                	li	a0,1
    8000286c:	bf55                	j	80002820 <devintr+0x1e>
      uartintr();
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	118080e7          	jalr	280(ra) # 80000986 <uartintr>
    80002876:	b7ed                	j	80002860 <devintr+0x5e>
      virtio_disk_intr();
    80002878:	00004097          	auipc	ra,0x4
    8000287c:	a46080e7          	jalr	-1466(ra) # 800062be <virtio_disk_intr>
    80002880:	b7c5                	j	80002860 <devintr+0x5e>
    if(cpuid() == 0){
    80002882:	fffff097          	auipc	ra,0xfffff
    80002886:	0d0080e7          	jalr	208(ra) # 80001952 <cpuid>
    8000288a:	c901                	beqz	a0,8000289a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000288c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002890:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002892:	14479073          	csrw	sip,a5
    return 2;
    80002896:	4509                	li	a0,2
    80002898:	b761                	j	80002820 <devintr+0x1e>
      clockintr();
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	f22080e7          	jalr	-222(ra) # 800027bc <clockintr>
    800028a2:	b7ed                	j	8000288c <devintr+0x8a>

00000000800028a4 <usertrap>:
{
    800028a4:	1101                	addi	sp,sp,-32
    800028a6:	ec06                	sd	ra,24(sp)
    800028a8:	e822                	sd	s0,16(sp)
    800028aa:	e426                	sd	s1,8(sp)
    800028ac:	e04a                	sd	s2,0(sp)
    800028ae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028b4:	1007f793          	andi	a5,a5,256
    800028b8:	e3ad                	bnez	a5,8000291a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ba:	00003797          	auipc	a5,0x3
    800028be:	44678793          	addi	a5,a5,1094 # 80005d00 <kernelvec>
    800028c2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	0b8080e7          	jalr	184(ra) # 8000197e <myproc>
    800028ce:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028d0:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028d2:	14102773          	csrr	a4,sepc
    800028d6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028dc:	47a1                	li	a5,8
    800028de:	04f71c63          	bne	a4,a5,80002936 <usertrap+0x92>
    if(p->killed)
    800028e2:	551c                	lw	a5,40(a0)
    800028e4:	e3b9                	bnez	a5,8000292a <usertrap+0x86>
    p->trapframe->epc += 4;
    800028e6:	74b8                	ld	a4,104(s1)
    800028e8:	6f1c                	ld	a5,24(a4)
    800028ea:	0791                	addi	a5,a5,4
    800028ec:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028f2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f6:	10079073          	csrw	sstatus,a5
    syscall();
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	2fc080e7          	jalr	764(ra) # 80002bf6 <syscall>
  if(p->killed)
    80002902:	549c                	lw	a5,40(s1)
    80002904:	efd9                	bnez	a5,800029a2 <usertrap+0xfe>
  usertrapret();
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	e18080e7          	jalr	-488(ra) # 8000271e <usertrapret>
}
    8000290e:	60e2                	ld	ra,24(sp)
    80002910:	6442                	ld	s0,16(sp)
    80002912:	64a2                	ld	s1,8(sp)
    80002914:	6902                	ld	s2,0(sp)
    80002916:	6105                	addi	sp,sp,32
    80002918:	8082                	ret
    panic("usertrap: not from user mode");
    8000291a:	00006517          	auipc	a0,0x6
    8000291e:	9e650513          	addi	a0,a0,-1562 # 80008300 <states.0+0x58>
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	c08080e7          	jalr	-1016(ra) # 8000052a <panic>
      exit(-1);
    8000292a:	557d                	li	a0,-1
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	8fe080e7          	jalr	-1794(ra) # 8000222a <exit>
    80002934:	bf4d                	j	800028e6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	ecc080e7          	jalr	-308(ra) # 80002802 <devintr>
    8000293e:	892a                	mv	s2,a0
    80002940:	c501                	beqz	a0,80002948 <usertrap+0xa4>
  if(p->killed)
    80002942:	549c                	lw	a5,40(s1)
    80002944:	c3a1                	beqz	a5,80002984 <usertrap+0xe0>
    80002946:	a815                	j	8000297a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002948:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000294c:	5890                	lw	a2,48(s1)
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	9d250513          	addi	a0,a0,-1582 # 80008320 <states.0+0x78>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	c1e080e7          	jalr	-994(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002962:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	9ea50513          	addi	a0,a0,-1558 # 80008350 <states.0+0xa8>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c06080e7          	jalr	-1018(ra) # 80000574 <printf>
    p->killed = 1;
    80002976:	4785                	li	a5,1
    80002978:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000297a:	557d                	li	a0,-1
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	8ae080e7          	jalr	-1874(ra) # 8000222a <exit>
  if(which_dev == 2){
    80002984:	4789                	li	a5,2
    80002986:	f8f910e3          	bne	s2,a5,80002906 <usertrap+0x62>
    if(inctickcounter() == QUANTUM)
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	bfc080e7          	jalr	-1028(ra) # 80002586 <inctickcounter>
    80002992:	4795                	li	a5,5
    80002994:	f6f519e3          	bne	a0,a5,80002906 <usertrap+0x62>
      yield();
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	5fa080e7          	jalr	1530(ra) # 80001f92 <yield>
    800029a0:	b79d                	j	80002906 <usertrap+0x62>
  int which_dev = 0;
    800029a2:	4901                	li	s2,0
    800029a4:	bfd9                	j	8000297a <usertrap+0xd6>

00000000800029a6 <kerneltrap>:
{
    800029a6:	7179                	addi	sp,sp,-48
    800029a8:	f406                	sd	ra,40(sp)
    800029aa:	f022                	sd	s0,32(sp)
    800029ac:	ec26                	sd	s1,24(sp)
    800029ae:	e84a                	sd	s2,16(sp)
    800029b0:	e44e                	sd	s3,8(sp)
    800029b2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029bc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029c0:	1004f793          	andi	a5,s1,256
    800029c4:	cb85                	beqz	a5,800029f4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029ca:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029cc:	ef85                	bnez	a5,80002a04 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	e34080e7          	jalr	-460(ra) # 80002802 <devintr>
    800029d6:	cd1d                	beqz	a0,80002a14 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    800029d8:	4789                	li	a5,2
    800029da:	06f50a63          	beq	a0,a5,80002a4e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029de:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e2:	10049073          	csrw	sstatus,s1
}
    800029e6:	70a2                	ld	ra,40(sp)
    800029e8:	7402                	ld	s0,32(sp)
    800029ea:	64e2                	ld	s1,24(sp)
    800029ec:	6942                	ld	s2,16(sp)
    800029ee:	69a2                	ld	s3,8(sp)
    800029f0:	6145                	addi	sp,sp,48
    800029f2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	97c50513          	addi	a0,a0,-1668 # 80008370 <states.0+0xc8>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b2e080e7          	jalr	-1234(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	99450513          	addi	a0,a0,-1644 # 80008398 <states.0+0xf0>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b1e080e7          	jalr	-1250(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002a14:	85ce                	mv	a1,s3
    80002a16:	00006517          	auipc	a0,0x6
    80002a1a:	9a250513          	addi	a0,a0,-1630 # 800083b8 <states.0+0x110>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b56080e7          	jalr	-1194(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a26:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a2a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a2e:	00006517          	auipc	a0,0x6
    80002a32:	99a50513          	addi	a0,a0,-1638 # 800083c8 <states.0+0x120>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b3e080e7          	jalr	-1218(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	9a250513          	addi	a0,a0,-1630 # 800083e0 <states.0+0x138>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	ae4080e7          	jalr	-1308(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	f30080e7          	jalr	-208(ra) # 8000197e <myproc>
    80002a56:	d541                	beqz	a0,800029de <kerneltrap+0x38>
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	f26080e7          	jalr	-218(ra) # 8000197e <myproc>
    80002a60:	4d18                	lw	a4,24(a0)
    80002a62:	4791                	li	a5,4
    80002a64:	f6f71de3          	bne	a4,a5,800029de <kerneltrap+0x38>
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	b1e080e7          	jalr	-1250(ra) # 80002586 <inctickcounter>
    80002a70:	4795                	li	a5,5
    80002a72:	f6f516e3          	bne	a0,a5,800029de <kerneltrap+0x38>
    yield();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	51c080e7          	jalr	1308(ra) # 80001f92 <yield>
    80002a7e:	b785                	j	800029de <kerneltrap+0x38>

0000000080002a80 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a80:	1101                	addi	sp,sp,-32
    80002a82:	ec06                	sd	ra,24(sp)
    80002a84:	e822                	sd	s0,16(sp)
    80002a86:	e426                	sd	s1,8(sp)
    80002a88:	1000                	addi	s0,sp,32
    80002a8a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	ef2080e7          	jalr	-270(ra) # 8000197e <myproc>
  switch (n) {
    80002a94:	4795                	li	a5,5
    80002a96:	0497e163          	bltu	a5,s1,80002ad8 <argraw+0x58>
    80002a9a:	048a                	slli	s1,s1,0x2
    80002a9c:	00006717          	auipc	a4,0x6
    80002aa0:	a7c70713          	addi	a4,a4,-1412 # 80008518 <states.0+0x270>
    80002aa4:	94ba                	add	s1,s1,a4
    80002aa6:	409c                	lw	a5,0(s1)
    80002aa8:	97ba                	add	a5,a5,a4
    80002aaa:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aac:	753c                	ld	a5,104(a0)
    80002aae:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret
    return p->trapframe->a1;
    80002aba:	753c                	ld	a5,104(a0)
    80002abc:	7fa8                	ld	a0,120(a5)
    80002abe:	bfcd                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a2;
    80002ac0:	753c                	ld	a5,104(a0)
    80002ac2:	63c8                	ld	a0,128(a5)
    80002ac4:	b7f5                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a3;
    80002ac6:	753c                	ld	a5,104(a0)
    80002ac8:	67c8                	ld	a0,136(a5)
    80002aca:	b7dd                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a4;
    80002acc:	753c                	ld	a5,104(a0)
    80002ace:	6bc8                	ld	a0,144(a5)
    80002ad0:	b7c5                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a5;
    80002ad2:	753c                	ld	a5,104(a0)
    80002ad4:	6fc8                	ld	a0,152(a5)
    80002ad6:	bfe9                	j	80002ab0 <argraw+0x30>
  panic("argraw");
    80002ad8:	00006517          	auipc	a0,0x6
    80002adc:	91850513          	addi	a0,a0,-1768 # 800083f0 <states.0+0x148>
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	a4a080e7          	jalr	-1462(ra) # 8000052a <panic>

0000000080002ae8 <fetchaddr>:
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	e04a                	sd	s2,0(sp)
    80002af2:	1000                	addi	s0,sp,32
    80002af4:	84aa                	mv	s1,a0
    80002af6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	e86080e7          	jalr	-378(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	02f4f863          	bgeu	s1,a5,80002b32 <fetchaddr+0x4a>
    80002b06:	00848713          	addi	a4,s1,8
    80002b0a:	02e7e663          	bltu	a5,a4,80002b36 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b0e:	46a1                	li	a3,8
    80002b10:	8626                	mv	a2,s1
    80002b12:	85ca                	mv	a1,s2
    80002b14:	7128                	ld	a0,96(a0)
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	bb4080e7          	jalr	-1100(ra) # 800016ca <copyin>
    80002b1e:	00a03533          	snez	a0,a0
    80002b22:	40a00533          	neg	a0,a0
}
    80002b26:	60e2                	ld	ra,24(sp)
    80002b28:	6442                	ld	s0,16(sp)
    80002b2a:	64a2                	ld	s1,8(sp)
    80002b2c:	6902                	ld	s2,0(sp)
    80002b2e:	6105                	addi	sp,sp,32
    80002b30:	8082                	ret
    return -1;
    80002b32:	557d                	li	a0,-1
    80002b34:	bfcd                	j	80002b26 <fetchaddr+0x3e>
    80002b36:	557d                	li	a0,-1
    80002b38:	b7fd                	j	80002b26 <fetchaddr+0x3e>

0000000080002b3a <fetchstr>:
{
    80002b3a:	7179                	addi	sp,sp,-48
    80002b3c:	f406                	sd	ra,40(sp)
    80002b3e:	f022                	sd	s0,32(sp)
    80002b40:	ec26                	sd	s1,24(sp)
    80002b42:	e84a                	sd	s2,16(sp)
    80002b44:	e44e                	sd	s3,8(sp)
    80002b46:	1800                	addi	s0,sp,48
    80002b48:	892a                	mv	s2,a0
    80002b4a:	84ae                	mv	s1,a1
    80002b4c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	e30080e7          	jalr	-464(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b56:	86ce                	mv	a3,s3
    80002b58:	864a                	mv	a2,s2
    80002b5a:	85a6                	mv	a1,s1
    80002b5c:	7128                	ld	a0,96(a0)
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	bfa080e7          	jalr	-1030(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002b66:	00054763          	bltz	a0,80002b74 <fetchstr+0x3a>
  return strlen(buf);
    80002b6a:	8526                	mv	a0,s1
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	2d6080e7          	jalr	726(ra) # 80000e42 <strlen>
}
    80002b74:	70a2                	ld	ra,40(sp)
    80002b76:	7402                	ld	s0,32(sp)
    80002b78:	64e2                	ld	s1,24(sp)
    80002b7a:	6942                	ld	s2,16(sp)
    80002b7c:	69a2                	ld	s3,8(sp)
    80002b7e:	6145                	addi	sp,sp,48
    80002b80:	8082                	ret

0000000080002b82 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	1000                	addi	s0,sp,32
    80002b8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	ef2080e7          	jalr	-270(ra) # 80002a80 <argraw>
    80002b96:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b98:	4501                	li	a0,0
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret

0000000080002ba4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	1000                	addi	s0,sp,32
    80002bae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	ed0080e7          	jalr	-304(ra) # 80002a80 <argraw>
    80002bb8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bba:	4501                	li	a0,0
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret

0000000080002bc6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	e04a                	sd	s2,0(sp)
    80002bd0:	1000                	addi	s0,sp,32
    80002bd2:	84ae                	mv	s1,a1
    80002bd4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	eaa080e7          	jalr	-342(ra) # 80002a80 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bde:	864a                	mv	a2,s2
    80002be0:	85a6                	mv	a1,s1
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	f58080e7          	jalr	-168(ra) # 80002b3a <fetchstr>
}
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6902                	ld	s2,0(sp)
    80002bf2:	6105                	addi	sp,sp,32
    80002bf4:	8082                	ret

0000000080002bf6 <syscall>:
 "unlink", "link", "mkdir", "close", "trace"};


void
syscall(void)
{
    80002bf6:	7139                	addi	sp,sp,-64
    80002bf8:	fc06                	sd	ra,56(sp)
    80002bfa:	f822                	sd	s0,48(sp)
    80002bfc:	f426                	sd	s1,40(sp)
    80002bfe:	f04a                	sd	s2,32(sp)
    80002c00:	ec4e                	sd	s3,24(sp)
    80002c02:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	d7a080e7          	jalr	-646(ra) # 8000197e <myproc>
    80002c0c:	892a                	mv	s2,a0
  num = p->trapframe->a7;
    80002c0e:	753c                	ld	a5,104(a0)
    80002c10:	0a87a483          	lw	s1,168(a5)
  int argument = 0;
    80002c14:	fc042623          	sw	zero,-52(s0)
  if(num == SYS_fork || num == SYS_kill || num == SYS_sbrk)
    80002c18:	47b1                	li	a5,12
    80002c1a:	0297e063          	bltu	a5,s1,80002c3a <syscall+0x44>
    80002c1e:	6785                	lui	a5,0x1
    80002c20:	04278793          	addi	a5,a5,66 # 1042 <_entry-0x7fffefbe>
    80002c24:	0097d7b3          	srl	a5,a5,s1
    80002c28:	8b85                	andi	a5,a5,1
    80002c2a:	cb81                	beqz	a5,80002c3a <syscall+0x44>
    argint(0, &argument);
    80002c2c:	fcc40593          	addi	a1,s0,-52
    80002c30:	4501                	li	a0,0
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	f50080e7          	jalr	-176(ra) # 80002b82 <argint>

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c3a:	fff4879b          	addiw	a5,s1,-1
    80002c3e:	4759                	li	a4,22
    80002c40:	02f76163          	bltu	a4,a5,80002c62 <syscall+0x6c>
    80002c44:	00349713          	slli	a4,s1,0x3
    80002c48:	00006797          	auipc	a5,0x6
    80002c4c:	8e878793          	addi	a5,a5,-1816 # 80008530 <syscalls>
    80002c50:	97ba                	add	a5,a5,a4
    80002c52:	639c                	ld	a5,0(a5)
    80002c54:	c799                	beqz	a5,80002c62 <syscall+0x6c>
    p->trapframe->a0 = syscalls[num]();
    80002c56:	06893983          	ld	s3,104(s2)
    80002c5a:	9782                	jalr	a5
    80002c5c:	06a9b823          	sd	a0,112(s3)
    80002c60:	a015                	j	80002c84 <syscall+0x8e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c62:	86a6                	mv	a3,s1
    80002c64:	16890613          	addi	a2,s2,360
    80002c68:	03092583          	lw	a1,48(s2)
    80002c6c:	00005517          	auipc	a0,0x5
    80002c70:	78c50513          	addi	a0,a0,1932 # 800083f8 <states.0+0x150>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	900080e7          	jalr	-1792(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c7c:	06893783          	ld	a5,104(s2)
    80002c80:	577d                	li	a4,-1
    80002c82:	fbb8                	sd	a4,112(a5)

  int ret = p->trapframe->a0;

  /* If the system calls bit is on in the mask of the process, 
  then print the trace of the system call. */
  if(p->mask & (1 << num)){
    80002c84:	03492783          	lw	a5,52(s2)
    80002c88:	4097d7bb          	sraw	a5,a5,s1
    80002c8c:	8b85                	andi	a5,a5,1
    80002c8e:	c3a9                	beqz	a5,80002cd0 <syscall+0xda>
  int ret = p->trapframe->a0;
    80002c90:	06893783          	ld	a5,104(s2)
    80002c94:	5bb4                	lw	a3,112(a5)
    if(num == SYS_fork)
    80002c96:	4785                	li	a5,1
    80002c98:	04f48363          	beq	s1,a5,80002cde <syscall+0xe8>
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    else if(num == SYS_kill || num == SYS_sbrk)
    80002c9c:	4799                	li	a5,6
    80002c9e:	00f48563          	beq	s1,a5,80002ca8 <syscall+0xb2>
    80002ca2:	47b1                	li	a5,12
    80002ca4:	04f49c63          	bne	s1,a5,80002cfc <syscall+0x106>
      printf("%d: syscall %s %d -> %d\n", p->pid, sys_calls_names[num], argument, ret);
    80002ca8:	048e                	slli	s1,s1,0x3
    80002caa:	00006797          	auipc	a5,0x6
    80002cae:	c9e78793          	addi	a5,a5,-866 # 80008948 <sys_calls_names>
    80002cb2:	94be                	add	s1,s1,a5
    80002cb4:	8736                	mv	a4,a3
    80002cb6:	fcc42683          	lw	a3,-52(s0)
    80002cba:	6090                	ld	a2,0(s1)
    80002cbc:	03092583          	lw	a1,48(s2)
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	77850513          	addi	a0,a0,1912 # 80008438 <states.0+0x190>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	8ac080e7          	jalr	-1876(ra) # 80000574 <printf>
    else
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
  }
}
    80002cd0:	70e2                	ld	ra,56(sp)
    80002cd2:	7442                	ld	s0,48(sp)
    80002cd4:	74a2                	ld	s1,40(sp)
    80002cd6:	7902                	ld	s2,32(sp)
    80002cd8:	69e2                	ld	s3,24(sp)
    80002cda:	6121                	addi	sp,sp,64
    80002cdc:	8082                	ret
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    80002cde:	00006617          	auipc	a2,0x6
    80002ce2:	c7263603          	ld	a2,-910(a2) # 80008950 <sys_calls_names+0x8>
    80002ce6:	03092583          	lw	a1,48(s2)
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	72e50513          	addi	a0,a0,1838 # 80008418 <states.0+0x170>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	882080e7          	jalr	-1918(ra) # 80000574 <printf>
    80002cfa:	bfd9                	j	80002cd0 <syscall+0xda>
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
    80002cfc:	048e                	slli	s1,s1,0x3
    80002cfe:	00006797          	auipc	a5,0x6
    80002d02:	c4a78793          	addi	a5,a5,-950 # 80008948 <sys_calls_names>
    80002d06:	94be                	add	s1,s1,a5
    80002d08:	6090                	ld	a2,0(s1)
    80002d0a:	03092583          	lw	a1,48(s2)
    80002d0e:	00005517          	auipc	a0,0x5
    80002d12:	74a50513          	addi	a0,a0,1866 # 80008458 <states.0+0x1b0>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	85e080e7          	jalr	-1954(ra) # 80000574 <printf>
}
    80002d1e:	bf4d                	j	80002cd0 <syscall+0xda>

0000000080002d20 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d20:	1101                	addi	sp,sp,-32
    80002d22:	ec06                	sd	ra,24(sp)
    80002d24:	e822                	sd	s0,16(sp)
    80002d26:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d28:	fec40593          	addi	a1,s0,-20
    80002d2c:	4501                	li	a0,0
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	e54080e7          	jalr	-428(ra) # 80002b82 <argint>
    return -1;
    80002d36:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d38:	00054963          	bltz	a0,80002d4a <sys_exit+0x2a>
  exit(n);
    80002d3c:	fec42503          	lw	a0,-20(s0)
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	4ea080e7          	jalr	1258(ra) # 8000222a <exit>
  return 0;  // not reached
    80002d48:	4781                	li	a5,0
}
    80002d4a:	853e                	mv	a0,a5
    80002d4c:	60e2                	ld	ra,24(sp)
    80002d4e:	6442                	ld	s0,16(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d54:	1141                	addi	sp,sp,-16
    80002d56:	e406                	sd	ra,8(sp)
    80002d58:	e022                	sd	s0,0(sp)
    80002d5a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	c22080e7          	jalr	-990(ra) # 8000197e <myproc>
}
    80002d64:	5908                	lw	a0,48(a0)
    80002d66:	60a2                	ld	ra,8(sp)
    80002d68:	6402                	ld	s0,0(sp)
    80002d6a:	0141                	addi	sp,sp,16
    80002d6c:	8082                	ret

0000000080002d6e <sys_fork>:

uint64
sys_fork(void)
{
    80002d6e:	1141                	addi	sp,sp,-16
    80002d70:	e406                	sd	ra,8(sp)
    80002d72:	e022                	sd	s0,0(sp)
    80002d74:	0800                	addi	s0,sp,16
  return fork();
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	ff6080e7          	jalr	-10(ra) # 80001d6c <fork>
}
    80002d7e:	60a2                	ld	ra,8(sp)
    80002d80:	6402                	ld	s0,0(sp)
    80002d82:	0141                	addi	sp,sp,16
    80002d84:	8082                	ret

0000000080002d86 <sys_wait>:

uint64
sys_wait(void)
{
    80002d86:	1101                	addi	sp,sp,-32
    80002d88:	ec06                	sd	ra,24(sp)
    80002d8a:	e822                	sd	s0,16(sp)
    80002d8c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d8e:	fe840593          	addi	a1,s0,-24
    80002d92:	4501                	li	a0,0
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	e10080e7          	jalr	-496(ra) # 80002ba4 <argaddr>
    80002d9c:	87aa                	mv	a5,a0
    return -1;
    80002d9e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002da0:	0007c863          	bltz	a5,80002db0 <sys_wait+0x2a>
  return wait(p);
    80002da4:	fe843503          	ld	a0,-24(s0)
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	28a080e7          	jalr	650(ra) # 80002032 <wait>
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	6105                	addi	sp,sp,32
    80002db6:	8082                	ret

0000000080002db8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002db8:	7179                	addi	sp,sp,-48
    80002dba:	f406                	sd	ra,40(sp)
    80002dbc:	f022                	sd	s0,32(sp)
    80002dbe:	ec26                	sd	s1,24(sp)
    80002dc0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dc2:	fdc40593          	addi	a1,s0,-36
    80002dc6:	4501                	li	a0,0
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	dba080e7          	jalr	-582(ra) # 80002b82 <argint>
    return -1;
    80002dd0:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002dd2:	00054f63          	bltz	a0,80002df0 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	ba8080e7          	jalr	-1112(ra) # 8000197e <myproc>
    80002dde:	4d24                	lw	s1,88(a0)
  if(growproc(n) < 0)
    80002de0:	fdc42503          	lw	a0,-36(s0)
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	f14080e7          	jalr	-236(ra) # 80001cf8 <growproc>
    80002dec:	00054863          	bltz	a0,80002dfc <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002df0:	8526                	mv	a0,s1
    80002df2:	70a2                	ld	ra,40(sp)
    80002df4:	7402                	ld	s0,32(sp)
    80002df6:	64e2                	ld	s1,24(sp)
    80002df8:	6145                	addi	sp,sp,48
    80002dfa:	8082                	ret
    return -1;
    80002dfc:	54fd                	li	s1,-1
    80002dfe:	bfcd                	j	80002df0 <sys_sbrk+0x38>

0000000080002e00 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e00:	7139                	addi	sp,sp,-64
    80002e02:	fc06                	sd	ra,56(sp)
    80002e04:	f822                	sd	s0,48(sp)
    80002e06:	f426                	sd	s1,40(sp)
    80002e08:	f04a                	sd	s2,32(sp)
    80002e0a:	ec4e                	sd	s3,24(sp)
    80002e0c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e0e:	fcc40593          	addi	a1,s0,-52
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	d6e080e7          	jalr	-658(ra) # 80002b82 <argint>
    return -1;
    80002e1c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e1e:	06054563          	bltz	a0,80002e88 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e22:	00014517          	auipc	a0,0x14
    80002e26:	6ae50513          	addi	a0,a0,1710 # 800174d0 <tickslock>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	d98080e7          	jalr	-616(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002e32:	00006917          	auipc	s2,0x6
    80002e36:	1fe92903          	lw	s2,510(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e3a:	fcc42783          	lw	a5,-52(s0)
    80002e3e:	cf85                	beqz	a5,80002e76 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e40:	00014997          	auipc	s3,0x14
    80002e44:	69098993          	addi	s3,s3,1680 # 800174d0 <tickslock>
    80002e48:	00006497          	auipc	s1,0x6
    80002e4c:	1e848493          	addi	s1,s1,488 # 80009030 <ticks>
    if(myproc()->killed){
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	b2e080e7          	jalr	-1234(ra) # 8000197e <myproc>
    80002e58:	551c                	lw	a5,40(a0)
    80002e5a:	ef9d                	bnez	a5,80002e98 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e5c:	85ce                	mv	a1,s3
    80002e5e:	8526                	mv	a0,s1
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	16e080e7          	jalr	366(ra) # 80001fce <sleep>
  while(ticks - ticks0 < n){
    80002e68:	409c                	lw	a5,0(s1)
    80002e6a:	412787bb          	subw	a5,a5,s2
    80002e6e:	fcc42703          	lw	a4,-52(s0)
    80002e72:	fce7efe3          	bltu	a5,a4,80002e50 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e76:	00014517          	auipc	a0,0x14
    80002e7a:	65a50513          	addi	a0,a0,1626 # 800174d0 <tickslock>
    80002e7e:	ffffe097          	auipc	ra,0xffffe
    80002e82:	df8080e7          	jalr	-520(ra) # 80000c76 <release>
  return 0;
    80002e86:	4781                	li	a5,0
}
    80002e88:	853e                	mv	a0,a5
    80002e8a:	70e2                	ld	ra,56(sp)
    80002e8c:	7442                	ld	s0,48(sp)
    80002e8e:	74a2                	ld	s1,40(sp)
    80002e90:	7902                	ld	s2,32(sp)
    80002e92:	69e2                	ld	s3,24(sp)
    80002e94:	6121                	addi	sp,sp,64
    80002e96:	8082                	ret
      release(&tickslock);
    80002e98:	00014517          	auipc	a0,0x14
    80002e9c:	63850513          	addi	a0,a0,1592 # 800174d0 <tickslock>
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	dd6080e7          	jalr	-554(ra) # 80000c76 <release>
      return -1;
    80002ea8:	57fd                	li	a5,-1
    80002eaa:	bff9                	j	80002e88 <sys_sleep+0x88>

0000000080002eac <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80002eac:	1101                	addi	sp,sp,-32
    80002eae:	ec06                	sd	ra,24(sp)
    80002eb0:	e822                	sd	s0,16(sp)
    80002eb2:	1000                	addi	s0,sp,32
  int prio;

  if(argint(0, &prio) < 0)
    80002eb4:	fec40593          	addi	a1,s0,-20
    80002eb8:	4501                	li	a0,0
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	cc8080e7          	jalr	-824(ra) # 80002b82 <argint>
    80002ec2:	87aa                	mv	a5,a0
    return -1;
    80002ec4:	557d                	li	a0,-1
  if(argint(0, &prio) < 0)
    80002ec6:	0007c863          	bltz	a5,80002ed6 <sys_set_priority+0x2a>
  return set_priority(prio);
    80002eca:	fec42503          	lw	a0,-20(s0)
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	432080e7          	jalr	1074(ra) # 80002300 <set_priority>
}
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_trace>:


uint64
sys_trace(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	1000                	addi	s0,sp,32
  int mask;
  int pid;

  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80002ee6:	fec40593          	addi	a1,s0,-20
    80002eea:	4501                	li	a0,0
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	c96080e7          	jalr	-874(ra) # 80002b82 <argint>
    return -1;
    80002ef4:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80002ef6:	02054563          	bltz	a0,80002f20 <sys_trace+0x42>
    80002efa:	fe840593          	addi	a1,s0,-24
    80002efe:	4505                	li	a0,1
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	c82080e7          	jalr	-894(ra) # 80002b82 <argint>
    return -1;
    80002f08:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80002f0a:	00054b63          	bltz	a0,80002f20 <sys_trace+0x42>
  return trace(mask, pid);
    80002f0e:	fe842583          	lw	a1,-24(s0)
    80002f12:	fec42503          	lw	a0,-20(s0)
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	442080e7          	jalr	1090(ra) # 80002358 <trace>
    80002f1e:	87aa                	mv	a5,a0
}
    80002f20:	853e                	mv	a0,a5
    80002f22:	60e2                	ld	ra,24(sp)
    80002f24:	6442                	ld	s0,16(sp)
    80002f26:	6105                	addi	sp,sp,32
    80002f28:	8082                	ret

0000000080002f2a <sys_kill>:


uint64
sys_kill(void)
{
    80002f2a:	1101                	addi	sp,sp,-32
    80002f2c:	ec06                	sd	ra,24(sp)
    80002f2e:	e822                	sd	s0,16(sp)
    80002f30:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f32:	fec40593          	addi	a1,s0,-20
    80002f36:	4501                	li	a0,0
    80002f38:	00000097          	auipc	ra,0x0
    80002f3c:	c4a080e7          	jalr	-950(ra) # 80002b82 <argint>
    80002f40:	87aa                	mv	a5,a0
    return -1;
    80002f42:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f44:	0007c863          	bltz	a5,80002f54 <sys_kill+0x2a>
  return kill(pid);
    80002f48:	fec42503          	lw	a0,-20(s0)
    80002f4c:	fffff097          	auipc	ra,0xfffff
    80002f50:	46c080e7          	jalr	1132(ra) # 800023b8 <kill>
}
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	6105                	addi	sp,sp,32
    80002f5a:	8082                	ret

0000000080002f5c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f5c:	1101                	addi	sp,sp,-32
    80002f5e:	ec06                	sd	ra,24(sp)
    80002f60:	e822                	sd	s0,16(sp)
    80002f62:	e426                	sd	s1,8(sp)
    80002f64:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f66:	00014517          	auipc	a0,0x14
    80002f6a:	56a50513          	addi	a0,a0,1386 # 800174d0 <tickslock>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	c54080e7          	jalr	-940(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002f76:	00006497          	auipc	s1,0x6
    80002f7a:	0ba4a483          	lw	s1,186(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f7e:	00014517          	auipc	a0,0x14
    80002f82:	55250513          	addi	a0,a0,1362 # 800174d0 <tickslock>
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	cf0080e7          	jalr	-784(ra) # 80000c76 <release>
  return xticks;
}
    80002f8e:	02049513          	slli	a0,s1,0x20
    80002f92:	9101                	srli	a0,a0,0x20
    80002f94:	60e2                	ld	ra,24(sp)
    80002f96:	6442                	ld	s0,16(sp)
    80002f98:	64a2                	ld	s1,8(sp)
    80002f9a:	6105                	addi	sp,sp,32
    80002f9c:	8082                	ret

0000000080002f9e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f9e:	7179                	addi	sp,sp,-48
    80002fa0:	f406                	sd	ra,40(sp)
    80002fa2:	f022                	sd	s0,32(sp)
    80002fa4:	ec26                	sd	s1,24(sp)
    80002fa6:	e84a                	sd	s2,16(sp)
    80002fa8:	e44e                	sd	s3,8(sp)
    80002faa:	e052                	sd	s4,0(sp)
    80002fac:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fae:	00005597          	auipc	a1,0x5
    80002fb2:	64258593          	addi	a1,a1,1602 # 800085f0 <syscalls+0xc0>
    80002fb6:	00014517          	auipc	a0,0x14
    80002fba:	53250513          	addi	a0,a0,1330 # 800174e8 <bcache>
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	b74080e7          	jalr	-1164(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fc6:	0001c797          	auipc	a5,0x1c
    80002fca:	52278793          	addi	a5,a5,1314 # 8001f4e8 <bcache+0x8000>
    80002fce:	0001c717          	auipc	a4,0x1c
    80002fd2:	78270713          	addi	a4,a4,1922 # 8001f750 <bcache+0x8268>
    80002fd6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fda:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fde:	00014497          	auipc	s1,0x14
    80002fe2:	52248493          	addi	s1,s1,1314 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80002fe6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fe8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fea:	00005a17          	auipc	s4,0x5
    80002fee:	60ea0a13          	addi	s4,s4,1550 # 800085f8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ff2:	2b893783          	ld	a5,696(s2)
    80002ff6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ff8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ffc:	85d2                	mv	a1,s4
    80002ffe:	01048513          	addi	a0,s1,16
    80003002:	00001097          	auipc	ra,0x1
    80003006:	4c2080e7          	jalr	1218(ra) # 800044c4 <initsleeplock>
    bcache.head.next->prev = b;
    8000300a:	2b893783          	ld	a5,696(s2)
    8000300e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003010:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003014:	45848493          	addi	s1,s1,1112
    80003018:	fd349de3          	bne	s1,s3,80002ff2 <binit+0x54>
  }
}
    8000301c:	70a2                	ld	ra,40(sp)
    8000301e:	7402                	ld	s0,32(sp)
    80003020:	64e2                	ld	s1,24(sp)
    80003022:	6942                	ld	s2,16(sp)
    80003024:	69a2                	ld	s3,8(sp)
    80003026:	6a02                	ld	s4,0(sp)
    80003028:	6145                	addi	sp,sp,48
    8000302a:	8082                	ret

000000008000302c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000302c:	7179                	addi	sp,sp,-48
    8000302e:	f406                	sd	ra,40(sp)
    80003030:	f022                	sd	s0,32(sp)
    80003032:	ec26                	sd	s1,24(sp)
    80003034:	e84a                	sd	s2,16(sp)
    80003036:	e44e                	sd	s3,8(sp)
    80003038:	1800                	addi	s0,sp,48
    8000303a:	892a                	mv	s2,a0
    8000303c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	4aa50513          	addi	a0,a0,1194 # 800174e8 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	b7c080e7          	jalr	-1156(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000304e:	0001c497          	auipc	s1,0x1c
    80003052:	7524b483          	ld	s1,1874(s1) # 8001f7a0 <bcache+0x82b8>
    80003056:	0001c797          	auipc	a5,0x1c
    8000305a:	6fa78793          	addi	a5,a5,1786 # 8001f750 <bcache+0x8268>
    8000305e:	02f48f63          	beq	s1,a5,8000309c <bread+0x70>
    80003062:	873e                	mv	a4,a5
    80003064:	a021                	j	8000306c <bread+0x40>
    80003066:	68a4                	ld	s1,80(s1)
    80003068:	02e48a63          	beq	s1,a4,8000309c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000306c:	449c                	lw	a5,8(s1)
    8000306e:	ff279ce3          	bne	a5,s2,80003066 <bread+0x3a>
    80003072:	44dc                	lw	a5,12(s1)
    80003074:	ff3799e3          	bne	a5,s3,80003066 <bread+0x3a>
      b->refcnt++;
    80003078:	40bc                	lw	a5,64(s1)
    8000307a:	2785                	addiw	a5,a5,1
    8000307c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000307e:	00014517          	auipc	a0,0x14
    80003082:	46a50513          	addi	a0,a0,1130 # 800174e8 <bcache>
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	bf0080e7          	jalr	-1040(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000308e:	01048513          	addi	a0,s1,16
    80003092:	00001097          	auipc	ra,0x1
    80003096:	46c080e7          	jalr	1132(ra) # 800044fe <acquiresleep>
      return b;
    8000309a:	a8b9                	j	800030f8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000309c:	0001c497          	auipc	s1,0x1c
    800030a0:	6fc4b483          	ld	s1,1788(s1) # 8001f798 <bcache+0x82b0>
    800030a4:	0001c797          	auipc	a5,0x1c
    800030a8:	6ac78793          	addi	a5,a5,1708 # 8001f750 <bcache+0x8268>
    800030ac:	00f48863          	beq	s1,a5,800030bc <bread+0x90>
    800030b0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030b2:	40bc                	lw	a5,64(s1)
    800030b4:	cf81                	beqz	a5,800030cc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030b6:	64a4                	ld	s1,72(s1)
    800030b8:	fee49de3          	bne	s1,a4,800030b2 <bread+0x86>
  panic("bget: no buffers");
    800030bc:	00005517          	auipc	a0,0x5
    800030c0:	54450513          	addi	a0,a0,1348 # 80008600 <syscalls+0xd0>
    800030c4:	ffffd097          	auipc	ra,0xffffd
    800030c8:	466080e7          	jalr	1126(ra) # 8000052a <panic>
      b->dev = dev;
    800030cc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030d0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030d4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030d8:	4785                	li	a5,1
    800030da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030dc:	00014517          	auipc	a0,0x14
    800030e0:	40c50513          	addi	a0,a0,1036 # 800174e8 <bcache>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	b92080e7          	jalr	-1134(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800030ec:	01048513          	addi	a0,s1,16
    800030f0:	00001097          	auipc	ra,0x1
    800030f4:	40e080e7          	jalr	1038(ra) # 800044fe <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030f8:	409c                	lw	a5,0(s1)
    800030fa:	cb89                	beqz	a5,8000310c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030fc:	8526                	mv	a0,s1
    800030fe:	70a2                	ld	ra,40(sp)
    80003100:	7402                	ld	s0,32(sp)
    80003102:	64e2                	ld	s1,24(sp)
    80003104:	6942                	ld	s2,16(sp)
    80003106:	69a2                	ld	s3,8(sp)
    80003108:	6145                	addi	sp,sp,48
    8000310a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000310c:	4581                	li	a1,0
    8000310e:	8526                	mv	a0,s1
    80003110:	00003097          	auipc	ra,0x3
    80003114:	f26080e7          	jalr	-218(ra) # 80006036 <virtio_disk_rw>
    b->valid = 1;
    80003118:	4785                	li	a5,1
    8000311a:	c09c                	sw	a5,0(s1)
  return b;
    8000311c:	b7c5                	j	800030fc <bread+0xd0>

000000008000311e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000312a:	0541                	addi	a0,a0,16
    8000312c:	00001097          	auipc	ra,0x1
    80003130:	46c080e7          	jalr	1132(ra) # 80004598 <holdingsleep>
    80003134:	cd01                	beqz	a0,8000314c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003136:	4585                	li	a1,1
    80003138:	8526                	mv	a0,s1
    8000313a:	00003097          	auipc	ra,0x3
    8000313e:	efc080e7          	jalr	-260(ra) # 80006036 <virtio_disk_rw>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6105                	addi	sp,sp,32
    8000314a:	8082                	ret
    panic("bwrite");
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	4cc50513          	addi	a0,a0,1228 # 80008618 <syscalls+0xe8>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	3d6080e7          	jalr	982(ra) # 8000052a <panic>

000000008000315c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	e04a                	sd	s2,0(sp)
    80003166:	1000                	addi	s0,sp,32
    80003168:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000316a:	01050913          	addi	s2,a0,16
    8000316e:	854a                	mv	a0,s2
    80003170:	00001097          	auipc	ra,0x1
    80003174:	428080e7          	jalr	1064(ra) # 80004598 <holdingsleep>
    80003178:	c92d                	beqz	a0,800031ea <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000317a:	854a                	mv	a0,s2
    8000317c:	00001097          	auipc	ra,0x1
    80003180:	3d8080e7          	jalr	984(ra) # 80004554 <releasesleep>

  acquire(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	36450513          	addi	a0,a0,868 # 800174e8 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	a36080e7          	jalr	-1482(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003194:	40bc                	lw	a5,64(s1)
    80003196:	37fd                	addiw	a5,a5,-1
    80003198:	0007871b          	sext.w	a4,a5
    8000319c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000319e:	eb05                	bnez	a4,800031ce <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031a0:	68bc                	ld	a5,80(s1)
    800031a2:	64b8                	ld	a4,72(s1)
    800031a4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031a6:	64bc                	ld	a5,72(s1)
    800031a8:	68b8                	ld	a4,80(s1)
    800031aa:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031ac:	0001c797          	auipc	a5,0x1c
    800031b0:	33c78793          	addi	a5,a5,828 # 8001f4e8 <bcache+0x8000>
    800031b4:	2b87b703          	ld	a4,696(a5)
    800031b8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031ba:	0001c717          	auipc	a4,0x1c
    800031be:	59670713          	addi	a4,a4,1430 # 8001f750 <bcache+0x8268>
    800031c2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031c4:	2b87b703          	ld	a4,696(a5)
    800031c8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ca:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031ce:	00014517          	auipc	a0,0x14
    800031d2:	31a50513          	addi	a0,a0,794 # 800174e8 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	aa0080e7          	jalr	-1376(ra) # 80000c76 <release>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6902                	ld	s2,0(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret
    panic("brelse");
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	43650513          	addi	a0,a0,1078 # 80008620 <syscalls+0xf0>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	338080e7          	jalr	824(ra) # 8000052a <panic>

00000000800031fa <bpin>:

void
bpin(struct buf *b) {
    800031fa:	1101                	addi	sp,sp,-32
    800031fc:	ec06                	sd	ra,24(sp)
    800031fe:	e822                	sd	s0,16(sp)
    80003200:	e426                	sd	s1,8(sp)
    80003202:	1000                	addi	s0,sp,32
    80003204:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003206:	00014517          	auipc	a0,0x14
    8000320a:	2e250513          	addi	a0,a0,738 # 800174e8 <bcache>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	9b4080e7          	jalr	-1612(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003216:	40bc                	lw	a5,64(s1)
    80003218:	2785                	addiw	a5,a5,1
    8000321a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000321c:	00014517          	auipc	a0,0x14
    80003220:	2cc50513          	addi	a0,a0,716 # 800174e8 <bcache>
    80003224:	ffffe097          	auipc	ra,0xffffe
    80003228:	a52080e7          	jalr	-1454(ra) # 80000c76 <release>
}
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	64a2                	ld	s1,8(sp)
    80003232:	6105                	addi	sp,sp,32
    80003234:	8082                	ret

0000000080003236 <bunpin>:

void
bunpin(struct buf *b) {
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	e426                	sd	s1,8(sp)
    8000323e:	1000                	addi	s0,sp,32
    80003240:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003242:	00014517          	auipc	a0,0x14
    80003246:	2a650513          	addi	a0,a0,678 # 800174e8 <bcache>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	978080e7          	jalr	-1672(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003252:	40bc                	lw	a5,64(s1)
    80003254:	37fd                	addiw	a5,a5,-1
    80003256:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003258:	00014517          	auipc	a0,0x14
    8000325c:	29050513          	addi	a0,a0,656 # 800174e8 <bcache>
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	a16080e7          	jalr	-1514(ra) # 80000c76 <release>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret

0000000080003272 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	e04a                	sd	s2,0(sp)
    8000327c:	1000                	addi	s0,sp,32
    8000327e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003280:	00d5d59b          	srliw	a1,a1,0xd
    80003284:	0001d797          	auipc	a5,0x1d
    80003288:	9407a783          	lw	a5,-1728(a5) # 8001fbc4 <sb+0x1c>
    8000328c:	9dbd                	addw	a1,a1,a5
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	d9e080e7          	jalr	-610(ra) # 8000302c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003296:	0074f713          	andi	a4,s1,7
    8000329a:	4785                	li	a5,1
    8000329c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032a0:	14ce                	slli	s1,s1,0x33
    800032a2:	90d9                	srli	s1,s1,0x36
    800032a4:	00950733          	add	a4,a0,s1
    800032a8:	05874703          	lbu	a4,88(a4)
    800032ac:	00e7f6b3          	and	a3,a5,a4
    800032b0:	c69d                	beqz	a3,800032de <bfree+0x6c>
    800032b2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032b4:	94aa                	add	s1,s1,a0
    800032b6:	fff7c793          	not	a5,a5
    800032ba:	8ff9                	and	a5,a5,a4
    800032bc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	11e080e7          	jalr	286(ra) # 800043de <log_write>
  brelse(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	e92080e7          	jalr	-366(ra) # 8000315c <brelse>
}
    800032d2:	60e2                	ld	ra,24(sp)
    800032d4:	6442                	ld	s0,16(sp)
    800032d6:	64a2                	ld	s1,8(sp)
    800032d8:	6902                	ld	s2,0(sp)
    800032da:	6105                	addi	sp,sp,32
    800032dc:	8082                	ret
    panic("freeing free block");
    800032de:	00005517          	auipc	a0,0x5
    800032e2:	34a50513          	addi	a0,a0,842 # 80008628 <syscalls+0xf8>
    800032e6:	ffffd097          	auipc	ra,0xffffd
    800032ea:	244080e7          	jalr	580(ra) # 8000052a <panic>

00000000800032ee <balloc>:
{
    800032ee:	711d                	addi	sp,sp,-96
    800032f0:	ec86                	sd	ra,88(sp)
    800032f2:	e8a2                	sd	s0,80(sp)
    800032f4:	e4a6                	sd	s1,72(sp)
    800032f6:	e0ca                	sd	s2,64(sp)
    800032f8:	fc4e                	sd	s3,56(sp)
    800032fa:	f852                	sd	s4,48(sp)
    800032fc:	f456                	sd	s5,40(sp)
    800032fe:	f05a                	sd	s6,32(sp)
    80003300:	ec5e                	sd	s7,24(sp)
    80003302:	e862                	sd	s8,16(sp)
    80003304:	e466                	sd	s9,8(sp)
    80003306:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003308:	0001d797          	auipc	a5,0x1d
    8000330c:	8a47a783          	lw	a5,-1884(a5) # 8001fbac <sb+0x4>
    80003310:	cbd1                	beqz	a5,800033a4 <balloc+0xb6>
    80003312:	8baa                	mv	s7,a0
    80003314:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003316:	0001db17          	auipc	s6,0x1d
    8000331a:	892b0b13          	addi	s6,s6,-1902 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000331e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003320:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003322:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003324:	6c89                	lui	s9,0x2
    80003326:	a831                	j	80003342 <balloc+0x54>
    brelse(bp);
    80003328:	854a                	mv	a0,s2
    8000332a:	00000097          	auipc	ra,0x0
    8000332e:	e32080e7          	jalr	-462(ra) # 8000315c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003332:	015c87bb          	addw	a5,s9,s5
    80003336:	00078a9b          	sext.w	s5,a5
    8000333a:	004b2703          	lw	a4,4(s6)
    8000333e:	06eaf363          	bgeu	s5,a4,800033a4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003342:	41fad79b          	sraiw	a5,s5,0x1f
    80003346:	0137d79b          	srliw	a5,a5,0x13
    8000334a:	015787bb          	addw	a5,a5,s5
    8000334e:	40d7d79b          	sraiw	a5,a5,0xd
    80003352:	01cb2583          	lw	a1,28(s6)
    80003356:	9dbd                	addw	a1,a1,a5
    80003358:	855e                	mv	a0,s7
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	cd2080e7          	jalr	-814(ra) # 8000302c <bread>
    80003362:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003364:	004b2503          	lw	a0,4(s6)
    80003368:	000a849b          	sext.w	s1,s5
    8000336c:	8662                	mv	a2,s8
    8000336e:	faa4fde3          	bgeu	s1,a0,80003328 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003372:	41f6579b          	sraiw	a5,a2,0x1f
    80003376:	01d7d69b          	srliw	a3,a5,0x1d
    8000337a:	00c6873b          	addw	a4,a3,a2
    8000337e:	00777793          	andi	a5,a4,7
    80003382:	9f95                	subw	a5,a5,a3
    80003384:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003388:	4037571b          	sraiw	a4,a4,0x3
    8000338c:	00e906b3          	add	a3,s2,a4
    80003390:	0586c683          	lbu	a3,88(a3)
    80003394:	00d7f5b3          	and	a1,a5,a3
    80003398:	cd91                	beqz	a1,800033b4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000339a:	2605                	addiw	a2,a2,1
    8000339c:	2485                	addiw	s1,s1,1
    8000339e:	fd4618e3          	bne	a2,s4,8000336e <balloc+0x80>
    800033a2:	b759                	j	80003328 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033a4:	00005517          	auipc	a0,0x5
    800033a8:	29c50513          	addi	a0,a0,668 # 80008640 <syscalls+0x110>
    800033ac:	ffffd097          	auipc	ra,0xffffd
    800033b0:	17e080e7          	jalr	382(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033b4:	974a                	add	a4,a4,s2
    800033b6:	8fd5                	or	a5,a5,a3
    800033b8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033bc:	854a                	mv	a0,s2
    800033be:	00001097          	auipc	ra,0x1
    800033c2:	020080e7          	jalr	32(ra) # 800043de <log_write>
        brelse(bp);
    800033c6:	854a                	mv	a0,s2
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	d94080e7          	jalr	-620(ra) # 8000315c <brelse>
  bp = bread(dev, bno);
    800033d0:	85a6                	mv	a1,s1
    800033d2:	855e                	mv	a0,s7
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	c58080e7          	jalr	-936(ra) # 8000302c <bread>
    800033dc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033de:	40000613          	li	a2,1024
    800033e2:	4581                	li	a1,0
    800033e4:	05850513          	addi	a0,a0,88
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	8d6080e7          	jalr	-1834(ra) # 80000cbe <memset>
  log_write(bp);
    800033f0:	854a                	mv	a0,s2
    800033f2:	00001097          	auipc	ra,0x1
    800033f6:	fec080e7          	jalr	-20(ra) # 800043de <log_write>
  brelse(bp);
    800033fa:	854a                	mv	a0,s2
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	d60080e7          	jalr	-672(ra) # 8000315c <brelse>
}
    80003404:	8526                	mv	a0,s1
    80003406:	60e6                	ld	ra,88(sp)
    80003408:	6446                	ld	s0,80(sp)
    8000340a:	64a6                	ld	s1,72(sp)
    8000340c:	6906                	ld	s2,64(sp)
    8000340e:	79e2                	ld	s3,56(sp)
    80003410:	7a42                	ld	s4,48(sp)
    80003412:	7aa2                	ld	s5,40(sp)
    80003414:	7b02                	ld	s6,32(sp)
    80003416:	6be2                	ld	s7,24(sp)
    80003418:	6c42                	ld	s8,16(sp)
    8000341a:	6ca2                	ld	s9,8(sp)
    8000341c:	6125                	addi	sp,sp,96
    8000341e:	8082                	ret

0000000080003420 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003420:	7179                	addi	sp,sp,-48
    80003422:	f406                	sd	ra,40(sp)
    80003424:	f022                	sd	s0,32(sp)
    80003426:	ec26                	sd	s1,24(sp)
    80003428:	e84a                	sd	s2,16(sp)
    8000342a:	e44e                	sd	s3,8(sp)
    8000342c:	e052                	sd	s4,0(sp)
    8000342e:	1800                	addi	s0,sp,48
    80003430:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003432:	47ad                	li	a5,11
    80003434:	04b7fe63          	bgeu	a5,a1,80003490 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003438:	ff45849b          	addiw	s1,a1,-12
    8000343c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003440:	0ff00793          	li	a5,255
    80003444:	0ae7e463          	bltu	a5,a4,800034ec <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003448:	08052583          	lw	a1,128(a0)
    8000344c:	c5b5                	beqz	a1,800034b8 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000344e:	00092503          	lw	a0,0(s2)
    80003452:	00000097          	auipc	ra,0x0
    80003456:	bda080e7          	jalr	-1062(ra) # 8000302c <bread>
    8000345a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000345c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003460:	02049713          	slli	a4,s1,0x20
    80003464:	01e75593          	srli	a1,a4,0x1e
    80003468:	00b784b3          	add	s1,a5,a1
    8000346c:	0004a983          	lw	s3,0(s1)
    80003470:	04098e63          	beqz	s3,800034cc <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003474:	8552                	mv	a0,s4
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	ce6080e7          	jalr	-794(ra) # 8000315c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000347e:	854e                	mv	a0,s3
    80003480:	70a2                	ld	ra,40(sp)
    80003482:	7402                	ld	s0,32(sp)
    80003484:	64e2                	ld	s1,24(sp)
    80003486:	6942                	ld	s2,16(sp)
    80003488:	69a2                	ld	s3,8(sp)
    8000348a:	6a02                	ld	s4,0(sp)
    8000348c:	6145                	addi	sp,sp,48
    8000348e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003490:	02059793          	slli	a5,a1,0x20
    80003494:	01e7d593          	srli	a1,a5,0x1e
    80003498:	00b504b3          	add	s1,a0,a1
    8000349c:	0504a983          	lw	s3,80(s1)
    800034a0:	fc099fe3          	bnez	s3,8000347e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034a4:	4108                	lw	a0,0(a0)
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	e48080e7          	jalr	-440(ra) # 800032ee <balloc>
    800034ae:	0005099b          	sext.w	s3,a0
    800034b2:	0534a823          	sw	s3,80(s1)
    800034b6:	b7e1                	j	8000347e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034b8:	4108                	lw	a0,0(a0)
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	e34080e7          	jalr	-460(ra) # 800032ee <balloc>
    800034c2:	0005059b          	sext.w	a1,a0
    800034c6:	08b92023          	sw	a1,128(s2)
    800034ca:	b751                	j	8000344e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034cc:	00092503          	lw	a0,0(s2)
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	e1e080e7          	jalr	-482(ra) # 800032ee <balloc>
    800034d8:	0005099b          	sext.w	s3,a0
    800034dc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034e0:	8552                	mv	a0,s4
    800034e2:	00001097          	auipc	ra,0x1
    800034e6:	efc080e7          	jalr	-260(ra) # 800043de <log_write>
    800034ea:	b769                	j	80003474 <bmap+0x54>
  panic("bmap: out of range");
    800034ec:	00005517          	auipc	a0,0x5
    800034f0:	16c50513          	addi	a0,a0,364 # 80008658 <syscalls+0x128>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	036080e7          	jalr	54(ra) # 8000052a <panic>

00000000800034fc <iget>:
{
    800034fc:	7179                	addi	sp,sp,-48
    800034fe:	f406                	sd	ra,40(sp)
    80003500:	f022                	sd	s0,32(sp)
    80003502:	ec26                	sd	s1,24(sp)
    80003504:	e84a                	sd	s2,16(sp)
    80003506:	e44e                	sd	s3,8(sp)
    80003508:	e052                	sd	s4,0(sp)
    8000350a:	1800                	addi	s0,sp,48
    8000350c:	89aa                	mv	s3,a0
    8000350e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003510:	0001c517          	auipc	a0,0x1c
    80003514:	6b850513          	addi	a0,a0,1720 # 8001fbc8 <itable>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	6aa080e7          	jalr	1706(ra) # 80000bc2 <acquire>
  empty = 0;
    80003520:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003522:	0001c497          	auipc	s1,0x1c
    80003526:	6be48493          	addi	s1,s1,1726 # 8001fbe0 <itable+0x18>
    8000352a:	0001e697          	auipc	a3,0x1e
    8000352e:	14668693          	addi	a3,a3,326 # 80021670 <log>
    80003532:	a039                	j	80003540 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003534:	02090b63          	beqz	s2,8000356a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003538:	08848493          	addi	s1,s1,136
    8000353c:	02d48a63          	beq	s1,a3,80003570 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003540:	449c                	lw	a5,8(s1)
    80003542:	fef059e3          	blez	a5,80003534 <iget+0x38>
    80003546:	4098                	lw	a4,0(s1)
    80003548:	ff3716e3          	bne	a4,s3,80003534 <iget+0x38>
    8000354c:	40d8                	lw	a4,4(s1)
    8000354e:	ff4713e3          	bne	a4,s4,80003534 <iget+0x38>
      ip->ref++;
    80003552:	2785                	addiw	a5,a5,1
    80003554:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003556:	0001c517          	auipc	a0,0x1c
    8000355a:	67250513          	addi	a0,a0,1650 # 8001fbc8 <itable>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	718080e7          	jalr	1816(ra) # 80000c76 <release>
      return ip;
    80003566:	8926                	mv	s2,s1
    80003568:	a03d                	j	80003596 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000356a:	f7f9                	bnez	a5,80003538 <iget+0x3c>
    8000356c:	8926                	mv	s2,s1
    8000356e:	b7e9                	j	80003538 <iget+0x3c>
  if(empty == 0)
    80003570:	02090c63          	beqz	s2,800035a8 <iget+0xac>
  ip->dev = dev;
    80003574:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003578:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000357c:	4785                	li	a5,1
    8000357e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003582:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003586:	0001c517          	auipc	a0,0x1c
    8000358a:	64250513          	addi	a0,a0,1602 # 8001fbc8 <itable>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	6e8080e7          	jalr	1768(ra) # 80000c76 <release>
}
    80003596:	854a                	mv	a0,s2
    80003598:	70a2                	ld	ra,40(sp)
    8000359a:	7402                	ld	s0,32(sp)
    8000359c:	64e2                	ld	s1,24(sp)
    8000359e:	6942                	ld	s2,16(sp)
    800035a0:	69a2                	ld	s3,8(sp)
    800035a2:	6a02                	ld	s4,0(sp)
    800035a4:	6145                	addi	sp,sp,48
    800035a6:	8082                	ret
    panic("iget: no inodes");
    800035a8:	00005517          	auipc	a0,0x5
    800035ac:	0c850513          	addi	a0,a0,200 # 80008670 <syscalls+0x140>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	f7a080e7          	jalr	-134(ra) # 8000052a <panic>

00000000800035b8 <fsinit>:
fsinit(int dev) {
    800035b8:	7179                	addi	sp,sp,-48
    800035ba:	f406                	sd	ra,40(sp)
    800035bc:	f022                	sd	s0,32(sp)
    800035be:	ec26                	sd	s1,24(sp)
    800035c0:	e84a                	sd	s2,16(sp)
    800035c2:	e44e                	sd	s3,8(sp)
    800035c4:	1800                	addi	s0,sp,48
    800035c6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035c8:	4585                	li	a1,1
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	a62080e7          	jalr	-1438(ra) # 8000302c <bread>
    800035d2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035d4:	0001c997          	auipc	s3,0x1c
    800035d8:	5d498993          	addi	s3,s3,1492 # 8001fba8 <sb>
    800035dc:	02000613          	li	a2,32
    800035e0:	05850593          	addi	a1,a0,88
    800035e4:	854e                	mv	a0,s3
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	734080e7          	jalr	1844(ra) # 80000d1a <memmove>
  brelse(bp);
    800035ee:	8526                	mv	a0,s1
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	b6c080e7          	jalr	-1172(ra) # 8000315c <brelse>
  if(sb.magic != FSMAGIC)
    800035f8:	0009a703          	lw	a4,0(s3)
    800035fc:	102037b7          	lui	a5,0x10203
    80003600:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003604:	02f71263          	bne	a4,a5,80003628 <fsinit+0x70>
  initlog(dev, &sb);
    80003608:	0001c597          	auipc	a1,0x1c
    8000360c:	5a058593          	addi	a1,a1,1440 # 8001fba8 <sb>
    80003610:	854a                	mv	a0,s2
    80003612:	00001097          	auipc	ra,0x1
    80003616:	b4e080e7          	jalr	-1202(ra) # 80004160 <initlog>
}
    8000361a:	70a2                	ld	ra,40(sp)
    8000361c:	7402                	ld	s0,32(sp)
    8000361e:	64e2                	ld	s1,24(sp)
    80003620:	6942                	ld	s2,16(sp)
    80003622:	69a2                	ld	s3,8(sp)
    80003624:	6145                	addi	sp,sp,48
    80003626:	8082                	ret
    panic("invalid file system");
    80003628:	00005517          	auipc	a0,0x5
    8000362c:	05850513          	addi	a0,a0,88 # 80008680 <syscalls+0x150>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	efa080e7          	jalr	-262(ra) # 8000052a <panic>

0000000080003638 <iinit>:
{
    80003638:	7179                	addi	sp,sp,-48
    8000363a:	f406                	sd	ra,40(sp)
    8000363c:	f022                	sd	s0,32(sp)
    8000363e:	ec26                	sd	s1,24(sp)
    80003640:	e84a                	sd	s2,16(sp)
    80003642:	e44e                	sd	s3,8(sp)
    80003644:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003646:	00005597          	auipc	a1,0x5
    8000364a:	05258593          	addi	a1,a1,82 # 80008698 <syscalls+0x168>
    8000364e:	0001c517          	auipc	a0,0x1c
    80003652:	57a50513          	addi	a0,a0,1402 # 8001fbc8 <itable>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	4dc080e7          	jalr	1244(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000365e:	0001c497          	auipc	s1,0x1c
    80003662:	59248493          	addi	s1,s1,1426 # 8001fbf0 <itable+0x28>
    80003666:	0001e997          	auipc	s3,0x1e
    8000366a:	01a98993          	addi	s3,s3,26 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000366e:	00005917          	auipc	s2,0x5
    80003672:	03290913          	addi	s2,s2,50 # 800086a0 <syscalls+0x170>
    80003676:	85ca                	mv	a1,s2
    80003678:	8526                	mv	a0,s1
    8000367a:	00001097          	auipc	ra,0x1
    8000367e:	e4a080e7          	jalr	-438(ra) # 800044c4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003682:	08848493          	addi	s1,s1,136
    80003686:	ff3498e3          	bne	s1,s3,80003676 <iinit+0x3e>
}
    8000368a:	70a2                	ld	ra,40(sp)
    8000368c:	7402                	ld	s0,32(sp)
    8000368e:	64e2                	ld	s1,24(sp)
    80003690:	6942                	ld	s2,16(sp)
    80003692:	69a2                	ld	s3,8(sp)
    80003694:	6145                	addi	sp,sp,48
    80003696:	8082                	ret

0000000080003698 <ialloc>:
{
    80003698:	715d                	addi	sp,sp,-80
    8000369a:	e486                	sd	ra,72(sp)
    8000369c:	e0a2                	sd	s0,64(sp)
    8000369e:	fc26                	sd	s1,56(sp)
    800036a0:	f84a                	sd	s2,48(sp)
    800036a2:	f44e                	sd	s3,40(sp)
    800036a4:	f052                	sd	s4,32(sp)
    800036a6:	ec56                	sd	s5,24(sp)
    800036a8:	e85a                	sd	s6,16(sp)
    800036aa:	e45e                	sd	s7,8(sp)
    800036ac:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ae:	0001c717          	auipc	a4,0x1c
    800036b2:	50672703          	lw	a4,1286(a4) # 8001fbb4 <sb+0xc>
    800036b6:	4785                	li	a5,1
    800036b8:	04e7fa63          	bgeu	a5,a4,8000370c <ialloc+0x74>
    800036bc:	8aaa                	mv	s5,a0
    800036be:	8bae                	mv	s7,a1
    800036c0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036c2:	0001ca17          	auipc	s4,0x1c
    800036c6:	4e6a0a13          	addi	s4,s4,1254 # 8001fba8 <sb>
    800036ca:	00048b1b          	sext.w	s6,s1
    800036ce:	0044d793          	srli	a5,s1,0x4
    800036d2:	018a2583          	lw	a1,24(s4)
    800036d6:	9dbd                	addw	a1,a1,a5
    800036d8:	8556                	mv	a0,s5
    800036da:	00000097          	auipc	ra,0x0
    800036de:	952080e7          	jalr	-1710(ra) # 8000302c <bread>
    800036e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036e4:	05850993          	addi	s3,a0,88
    800036e8:	00f4f793          	andi	a5,s1,15
    800036ec:	079a                	slli	a5,a5,0x6
    800036ee:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036f0:	00099783          	lh	a5,0(s3)
    800036f4:	c785                	beqz	a5,8000371c <ialloc+0x84>
    brelse(bp);
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	a66080e7          	jalr	-1434(ra) # 8000315c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036fe:	0485                	addi	s1,s1,1
    80003700:	00ca2703          	lw	a4,12(s4)
    80003704:	0004879b          	sext.w	a5,s1
    80003708:	fce7e1e3          	bltu	a5,a4,800036ca <ialloc+0x32>
  panic("ialloc: no inodes");
    8000370c:	00005517          	auipc	a0,0x5
    80003710:	f9c50513          	addi	a0,a0,-100 # 800086a8 <syscalls+0x178>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	e16080e7          	jalr	-490(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    8000371c:	04000613          	li	a2,64
    80003720:	4581                	li	a1,0
    80003722:	854e                	mv	a0,s3
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	59a080e7          	jalr	1434(ra) # 80000cbe <memset>
      dip->type = type;
    8000372c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003730:	854a                	mv	a0,s2
    80003732:	00001097          	auipc	ra,0x1
    80003736:	cac080e7          	jalr	-852(ra) # 800043de <log_write>
      brelse(bp);
    8000373a:	854a                	mv	a0,s2
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	a20080e7          	jalr	-1504(ra) # 8000315c <brelse>
      return iget(dev, inum);
    80003744:	85da                	mv	a1,s6
    80003746:	8556                	mv	a0,s5
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	db4080e7          	jalr	-588(ra) # 800034fc <iget>
}
    80003750:	60a6                	ld	ra,72(sp)
    80003752:	6406                	ld	s0,64(sp)
    80003754:	74e2                	ld	s1,56(sp)
    80003756:	7942                	ld	s2,48(sp)
    80003758:	79a2                	ld	s3,40(sp)
    8000375a:	7a02                	ld	s4,32(sp)
    8000375c:	6ae2                	ld	s5,24(sp)
    8000375e:	6b42                	ld	s6,16(sp)
    80003760:	6ba2                	ld	s7,8(sp)
    80003762:	6161                	addi	sp,sp,80
    80003764:	8082                	ret

0000000080003766 <iupdate>:
{
    80003766:	1101                	addi	sp,sp,-32
    80003768:	ec06                	sd	ra,24(sp)
    8000376a:	e822                	sd	s0,16(sp)
    8000376c:	e426                	sd	s1,8(sp)
    8000376e:	e04a                	sd	s2,0(sp)
    80003770:	1000                	addi	s0,sp,32
    80003772:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003774:	415c                	lw	a5,4(a0)
    80003776:	0047d79b          	srliw	a5,a5,0x4
    8000377a:	0001c597          	auipc	a1,0x1c
    8000377e:	4465a583          	lw	a1,1094(a1) # 8001fbc0 <sb+0x18>
    80003782:	9dbd                	addw	a1,a1,a5
    80003784:	4108                	lw	a0,0(a0)
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	8a6080e7          	jalr	-1882(ra) # 8000302c <bread>
    8000378e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003790:	05850793          	addi	a5,a0,88
    80003794:	40c8                	lw	a0,4(s1)
    80003796:	893d                	andi	a0,a0,15
    80003798:	051a                	slli	a0,a0,0x6
    8000379a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000379c:	04449703          	lh	a4,68(s1)
    800037a0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037a4:	04649703          	lh	a4,70(s1)
    800037a8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037ac:	04849703          	lh	a4,72(s1)
    800037b0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037b4:	04a49703          	lh	a4,74(s1)
    800037b8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037bc:	44f8                	lw	a4,76(s1)
    800037be:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037c0:	03400613          	li	a2,52
    800037c4:	05048593          	addi	a1,s1,80
    800037c8:	0531                	addi	a0,a0,12
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	550080e7          	jalr	1360(ra) # 80000d1a <memmove>
  log_write(bp);
    800037d2:	854a                	mv	a0,s2
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	c0a080e7          	jalr	-1014(ra) # 800043de <log_write>
  brelse(bp);
    800037dc:	854a                	mv	a0,s2
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	97e080e7          	jalr	-1666(ra) # 8000315c <brelse>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret

00000000800037f2 <idup>:
{
    800037f2:	1101                	addi	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	e426                	sd	s1,8(sp)
    800037fa:	1000                	addi	s0,sp,32
    800037fc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037fe:	0001c517          	auipc	a0,0x1c
    80003802:	3ca50513          	addi	a0,a0,970 # 8001fbc8 <itable>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	3bc080e7          	jalr	956(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000380e:	449c                	lw	a5,8(s1)
    80003810:	2785                	addiw	a5,a5,1
    80003812:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	3b450513          	addi	a0,a0,948 # 8001fbc8 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	45a080e7          	jalr	1114(ra) # 80000c76 <release>
}
    80003824:	8526                	mv	a0,s1
    80003826:	60e2                	ld	ra,24(sp)
    80003828:	6442                	ld	s0,16(sp)
    8000382a:	64a2                	ld	s1,8(sp)
    8000382c:	6105                	addi	sp,sp,32
    8000382e:	8082                	ret

0000000080003830 <ilock>:
{
    80003830:	1101                	addi	sp,sp,-32
    80003832:	ec06                	sd	ra,24(sp)
    80003834:	e822                	sd	s0,16(sp)
    80003836:	e426                	sd	s1,8(sp)
    80003838:	e04a                	sd	s2,0(sp)
    8000383a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000383c:	c115                	beqz	a0,80003860 <ilock+0x30>
    8000383e:	84aa                	mv	s1,a0
    80003840:	451c                	lw	a5,8(a0)
    80003842:	00f05f63          	blez	a5,80003860 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003846:	0541                	addi	a0,a0,16
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	cb6080e7          	jalr	-842(ra) # 800044fe <acquiresleep>
  if(ip->valid == 0){
    80003850:	40bc                	lw	a5,64(s1)
    80003852:	cf99                	beqz	a5,80003870 <ilock+0x40>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	64a2                	ld	s1,8(sp)
    8000385a:	6902                	ld	s2,0(sp)
    8000385c:	6105                	addi	sp,sp,32
    8000385e:	8082                	ret
    panic("ilock");
    80003860:	00005517          	auipc	a0,0x5
    80003864:	e6050513          	addi	a0,a0,-416 # 800086c0 <syscalls+0x190>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	cc2080e7          	jalr	-830(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003870:	40dc                	lw	a5,4(s1)
    80003872:	0047d79b          	srliw	a5,a5,0x4
    80003876:	0001c597          	auipc	a1,0x1c
    8000387a:	34a5a583          	lw	a1,842(a1) # 8001fbc0 <sb+0x18>
    8000387e:	9dbd                	addw	a1,a1,a5
    80003880:	4088                	lw	a0,0(s1)
    80003882:	fffff097          	auipc	ra,0xfffff
    80003886:	7aa080e7          	jalr	1962(ra) # 8000302c <bread>
    8000388a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000388c:	05850593          	addi	a1,a0,88
    80003890:	40dc                	lw	a5,4(s1)
    80003892:	8bbd                	andi	a5,a5,15
    80003894:	079a                	slli	a5,a5,0x6
    80003896:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003898:	00059783          	lh	a5,0(a1)
    8000389c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038a0:	00259783          	lh	a5,2(a1)
    800038a4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038a8:	00459783          	lh	a5,4(a1)
    800038ac:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038b0:	00659783          	lh	a5,6(a1)
    800038b4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038b8:	459c                	lw	a5,8(a1)
    800038ba:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038bc:	03400613          	li	a2,52
    800038c0:	05b1                	addi	a1,a1,12
    800038c2:	05048513          	addi	a0,s1,80
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	454080e7          	jalr	1108(ra) # 80000d1a <memmove>
    brelse(bp);
    800038ce:	854a                	mv	a0,s2
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	88c080e7          	jalr	-1908(ra) # 8000315c <brelse>
    ip->valid = 1;
    800038d8:	4785                	li	a5,1
    800038da:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038dc:	04449783          	lh	a5,68(s1)
    800038e0:	fbb5                	bnez	a5,80003854 <ilock+0x24>
      panic("ilock: no type");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	de650513          	addi	a0,a0,-538 # 800086c8 <syscalls+0x198>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c40080e7          	jalr	-960(ra) # 8000052a <panic>

00000000800038f2 <iunlock>:
{
    800038f2:	1101                	addi	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	e04a                	sd	s2,0(sp)
    800038fc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038fe:	c905                	beqz	a0,8000392e <iunlock+0x3c>
    80003900:	84aa                	mv	s1,a0
    80003902:	01050913          	addi	s2,a0,16
    80003906:	854a                	mv	a0,s2
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	c90080e7          	jalr	-880(ra) # 80004598 <holdingsleep>
    80003910:	cd19                	beqz	a0,8000392e <iunlock+0x3c>
    80003912:	449c                	lw	a5,8(s1)
    80003914:	00f05d63          	blez	a5,8000392e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003918:	854a                	mv	a0,s2
    8000391a:	00001097          	auipc	ra,0x1
    8000391e:	c3a080e7          	jalr	-966(ra) # 80004554 <releasesleep>
}
    80003922:	60e2                	ld	ra,24(sp)
    80003924:	6442                	ld	s0,16(sp)
    80003926:	64a2                	ld	s1,8(sp)
    80003928:	6902                	ld	s2,0(sp)
    8000392a:	6105                	addi	sp,sp,32
    8000392c:	8082                	ret
    panic("iunlock");
    8000392e:	00005517          	auipc	a0,0x5
    80003932:	daa50513          	addi	a0,a0,-598 # 800086d8 <syscalls+0x1a8>
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	bf4080e7          	jalr	-1036(ra) # 8000052a <panic>

000000008000393e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000393e:	7179                	addi	sp,sp,-48
    80003940:	f406                	sd	ra,40(sp)
    80003942:	f022                	sd	s0,32(sp)
    80003944:	ec26                	sd	s1,24(sp)
    80003946:	e84a                	sd	s2,16(sp)
    80003948:	e44e                	sd	s3,8(sp)
    8000394a:	e052                	sd	s4,0(sp)
    8000394c:	1800                	addi	s0,sp,48
    8000394e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003950:	05050493          	addi	s1,a0,80
    80003954:	08050913          	addi	s2,a0,128
    80003958:	a021                	j	80003960 <itrunc+0x22>
    8000395a:	0491                	addi	s1,s1,4
    8000395c:	01248d63          	beq	s1,s2,80003976 <itrunc+0x38>
    if(ip->addrs[i]){
    80003960:	408c                	lw	a1,0(s1)
    80003962:	dde5                	beqz	a1,8000395a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003964:	0009a503          	lw	a0,0(s3)
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	90a080e7          	jalr	-1782(ra) # 80003272 <bfree>
      ip->addrs[i] = 0;
    80003970:	0004a023          	sw	zero,0(s1)
    80003974:	b7dd                	j	8000395a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003976:	0809a583          	lw	a1,128(s3)
    8000397a:	e185                	bnez	a1,8000399a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000397c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003980:	854e                	mv	a0,s3
    80003982:	00000097          	auipc	ra,0x0
    80003986:	de4080e7          	jalr	-540(ra) # 80003766 <iupdate>
}
    8000398a:	70a2                	ld	ra,40(sp)
    8000398c:	7402                	ld	s0,32(sp)
    8000398e:	64e2                	ld	s1,24(sp)
    80003990:	6942                	ld	s2,16(sp)
    80003992:	69a2                	ld	s3,8(sp)
    80003994:	6a02                	ld	s4,0(sp)
    80003996:	6145                	addi	sp,sp,48
    80003998:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000399a:	0009a503          	lw	a0,0(s3)
    8000399e:	fffff097          	auipc	ra,0xfffff
    800039a2:	68e080e7          	jalr	1678(ra) # 8000302c <bread>
    800039a6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039a8:	05850493          	addi	s1,a0,88
    800039ac:	45850913          	addi	s2,a0,1112
    800039b0:	a021                	j	800039b8 <itrunc+0x7a>
    800039b2:	0491                	addi	s1,s1,4
    800039b4:	01248b63          	beq	s1,s2,800039ca <itrunc+0x8c>
      if(a[j])
    800039b8:	408c                	lw	a1,0(s1)
    800039ba:	dde5                	beqz	a1,800039b2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039bc:	0009a503          	lw	a0,0(s3)
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	8b2080e7          	jalr	-1870(ra) # 80003272 <bfree>
    800039c8:	b7ed                	j	800039b2 <itrunc+0x74>
    brelse(bp);
    800039ca:	8552                	mv	a0,s4
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	790080e7          	jalr	1936(ra) # 8000315c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039d4:	0809a583          	lw	a1,128(s3)
    800039d8:	0009a503          	lw	a0,0(s3)
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	896080e7          	jalr	-1898(ra) # 80003272 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039e4:	0809a023          	sw	zero,128(s3)
    800039e8:	bf51                	j	8000397c <itrunc+0x3e>

00000000800039ea <iput>:
{
    800039ea:	1101                	addi	sp,sp,-32
    800039ec:	ec06                	sd	ra,24(sp)
    800039ee:	e822                	sd	s0,16(sp)
    800039f0:	e426                	sd	s1,8(sp)
    800039f2:	e04a                	sd	s2,0(sp)
    800039f4:	1000                	addi	s0,sp,32
    800039f6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039f8:	0001c517          	auipc	a0,0x1c
    800039fc:	1d050513          	addi	a0,a0,464 # 8001fbc8 <itable>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	1c2080e7          	jalr	450(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a08:	4498                	lw	a4,8(s1)
    80003a0a:	4785                	li	a5,1
    80003a0c:	02f70363          	beq	a4,a5,80003a32 <iput+0x48>
  ip->ref--;
    80003a10:	449c                	lw	a5,8(s1)
    80003a12:	37fd                	addiw	a5,a5,-1
    80003a14:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a16:	0001c517          	auipc	a0,0x1c
    80003a1a:	1b250513          	addi	a0,a0,434 # 8001fbc8 <itable>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	258080e7          	jalr	600(ra) # 80000c76 <release>
}
    80003a26:	60e2                	ld	ra,24(sp)
    80003a28:	6442                	ld	s0,16(sp)
    80003a2a:	64a2                	ld	s1,8(sp)
    80003a2c:	6902                	ld	s2,0(sp)
    80003a2e:	6105                	addi	sp,sp,32
    80003a30:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a32:	40bc                	lw	a5,64(s1)
    80003a34:	dff1                	beqz	a5,80003a10 <iput+0x26>
    80003a36:	04a49783          	lh	a5,74(s1)
    80003a3a:	fbf9                	bnez	a5,80003a10 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a3c:	01048913          	addi	s2,s1,16
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	abc080e7          	jalr	-1348(ra) # 800044fe <acquiresleep>
    release(&itable.lock);
    80003a4a:	0001c517          	auipc	a0,0x1c
    80003a4e:	17e50513          	addi	a0,a0,382 # 8001fbc8 <itable>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	224080e7          	jalr	548(ra) # 80000c76 <release>
    itrunc(ip);
    80003a5a:	8526                	mv	a0,s1
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	ee2080e7          	jalr	-286(ra) # 8000393e <itrunc>
    ip->type = 0;
    80003a64:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a68:	8526                	mv	a0,s1
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	cfc080e7          	jalr	-772(ra) # 80003766 <iupdate>
    ip->valid = 0;
    80003a72:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00001097          	auipc	ra,0x1
    80003a7c:	adc080e7          	jalr	-1316(ra) # 80004554 <releasesleep>
    acquire(&itable.lock);
    80003a80:	0001c517          	auipc	a0,0x1c
    80003a84:	14850513          	addi	a0,a0,328 # 8001fbc8 <itable>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	13a080e7          	jalr	314(ra) # 80000bc2 <acquire>
    80003a90:	b741                	j	80003a10 <iput+0x26>

0000000080003a92 <iunlockput>:
{
    80003a92:	1101                	addi	sp,sp,-32
    80003a94:	ec06                	sd	ra,24(sp)
    80003a96:	e822                	sd	s0,16(sp)
    80003a98:	e426                	sd	s1,8(sp)
    80003a9a:	1000                	addi	s0,sp,32
    80003a9c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	e54080e7          	jalr	-428(ra) # 800038f2 <iunlock>
  iput(ip);
    80003aa6:	8526                	mv	a0,s1
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	f42080e7          	jalr	-190(ra) # 800039ea <iput>
}
    80003ab0:	60e2                	ld	ra,24(sp)
    80003ab2:	6442                	ld	s0,16(sp)
    80003ab4:	64a2                	ld	s1,8(sp)
    80003ab6:	6105                	addi	sp,sp,32
    80003ab8:	8082                	ret

0000000080003aba <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aba:	1141                	addi	sp,sp,-16
    80003abc:	e422                	sd	s0,8(sp)
    80003abe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ac0:	411c                	lw	a5,0(a0)
    80003ac2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ac4:	415c                	lw	a5,4(a0)
    80003ac6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ac8:	04451783          	lh	a5,68(a0)
    80003acc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ad0:	04a51783          	lh	a5,74(a0)
    80003ad4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ad8:	04c56783          	lwu	a5,76(a0)
    80003adc:	e99c                	sd	a5,16(a1)
}
    80003ade:	6422                	ld	s0,8(sp)
    80003ae0:	0141                	addi	sp,sp,16
    80003ae2:	8082                	ret

0000000080003ae4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae4:	457c                	lw	a5,76(a0)
    80003ae6:	0ed7e963          	bltu	a5,a3,80003bd8 <readi+0xf4>
{
    80003aea:	7159                	addi	sp,sp,-112
    80003aec:	f486                	sd	ra,104(sp)
    80003aee:	f0a2                	sd	s0,96(sp)
    80003af0:	eca6                	sd	s1,88(sp)
    80003af2:	e8ca                	sd	s2,80(sp)
    80003af4:	e4ce                	sd	s3,72(sp)
    80003af6:	e0d2                	sd	s4,64(sp)
    80003af8:	fc56                	sd	s5,56(sp)
    80003afa:	f85a                	sd	s6,48(sp)
    80003afc:	f45e                	sd	s7,40(sp)
    80003afe:	f062                	sd	s8,32(sp)
    80003b00:	ec66                	sd	s9,24(sp)
    80003b02:	e86a                	sd	s10,16(sp)
    80003b04:	e46e                	sd	s11,8(sp)
    80003b06:	1880                	addi	s0,sp,112
    80003b08:	8baa                	mv	s7,a0
    80003b0a:	8c2e                	mv	s8,a1
    80003b0c:	8ab2                	mv	s5,a2
    80003b0e:	84b6                	mv	s1,a3
    80003b10:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b12:	9f35                	addw	a4,a4,a3
    return 0;
    80003b14:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b16:	0ad76063          	bltu	a4,a3,80003bb6 <readi+0xd2>
  if(off + n > ip->size)
    80003b1a:	00e7f463          	bgeu	a5,a4,80003b22 <readi+0x3e>
    n = ip->size - off;
    80003b1e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b22:	0a0b0963          	beqz	s6,80003bd4 <readi+0xf0>
    80003b26:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b28:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b2c:	5cfd                	li	s9,-1
    80003b2e:	a82d                	j	80003b68 <readi+0x84>
    80003b30:	020a1d93          	slli	s11,s4,0x20
    80003b34:	020ddd93          	srli	s11,s11,0x20
    80003b38:	05890793          	addi	a5,s2,88
    80003b3c:	86ee                	mv	a3,s11
    80003b3e:	963e                	add	a2,a2,a5
    80003b40:	85d6                	mv	a1,s5
    80003b42:	8562                	mv	a0,s8
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	8e6080e7          	jalr	-1818(ra) # 8000242a <either_copyout>
    80003b4c:	05950d63          	beq	a0,s9,80003ba6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b50:	854a                	mv	a0,s2
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	60a080e7          	jalr	1546(ra) # 8000315c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5a:	013a09bb          	addw	s3,s4,s3
    80003b5e:	009a04bb          	addw	s1,s4,s1
    80003b62:	9aee                	add	s5,s5,s11
    80003b64:	0569f763          	bgeu	s3,s6,80003bb2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b68:	000ba903          	lw	s2,0(s7)
    80003b6c:	00a4d59b          	srliw	a1,s1,0xa
    80003b70:	855e                	mv	a0,s7
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	8ae080e7          	jalr	-1874(ra) # 80003420 <bmap>
    80003b7a:	0005059b          	sext.w	a1,a0
    80003b7e:	854a                	mv	a0,s2
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	4ac080e7          	jalr	1196(ra) # 8000302c <bread>
    80003b88:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8a:	3ff4f613          	andi	a2,s1,1023
    80003b8e:	40cd07bb          	subw	a5,s10,a2
    80003b92:	413b073b          	subw	a4,s6,s3
    80003b96:	8a3e                	mv	s4,a5
    80003b98:	2781                	sext.w	a5,a5
    80003b9a:	0007069b          	sext.w	a3,a4
    80003b9e:	f8f6f9e3          	bgeu	a3,a5,80003b30 <readi+0x4c>
    80003ba2:	8a3a                	mv	s4,a4
    80003ba4:	b771                	j	80003b30 <readi+0x4c>
      brelse(bp);
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	5b4080e7          	jalr	1460(ra) # 8000315c <brelse>
      tot = -1;
    80003bb0:	59fd                	li	s3,-1
  }
  return tot;
    80003bb2:	0009851b          	sext.w	a0,s3
}
    80003bb6:	70a6                	ld	ra,104(sp)
    80003bb8:	7406                	ld	s0,96(sp)
    80003bba:	64e6                	ld	s1,88(sp)
    80003bbc:	6946                	ld	s2,80(sp)
    80003bbe:	69a6                	ld	s3,72(sp)
    80003bc0:	6a06                	ld	s4,64(sp)
    80003bc2:	7ae2                	ld	s5,56(sp)
    80003bc4:	7b42                	ld	s6,48(sp)
    80003bc6:	7ba2                	ld	s7,40(sp)
    80003bc8:	7c02                	ld	s8,32(sp)
    80003bca:	6ce2                	ld	s9,24(sp)
    80003bcc:	6d42                	ld	s10,16(sp)
    80003bce:	6da2                	ld	s11,8(sp)
    80003bd0:	6165                	addi	sp,sp,112
    80003bd2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd4:	89da                	mv	s3,s6
    80003bd6:	bff1                	j	80003bb2 <readi+0xce>
    return 0;
    80003bd8:	4501                	li	a0,0
}
    80003bda:	8082                	ret

0000000080003bdc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bdc:	457c                	lw	a5,76(a0)
    80003bde:	10d7e863          	bltu	a5,a3,80003cee <writei+0x112>
{
    80003be2:	7159                	addi	sp,sp,-112
    80003be4:	f486                	sd	ra,104(sp)
    80003be6:	f0a2                	sd	s0,96(sp)
    80003be8:	eca6                	sd	s1,88(sp)
    80003bea:	e8ca                	sd	s2,80(sp)
    80003bec:	e4ce                	sd	s3,72(sp)
    80003bee:	e0d2                	sd	s4,64(sp)
    80003bf0:	fc56                	sd	s5,56(sp)
    80003bf2:	f85a                	sd	s6,48(sp)
    80003bf4:	f45e                	sd	s7,40(sp)
    80003bf6:	f062                	sd	s8,32(sp)
    80003bf8:	ec66                	sd	s9,24(sp)
    80003bfa:	e86a                	sd	s10,16(sp)
    80003bfc:	e46e                	sd	s11,8(sp)
    80003bfe:	1880                	addi	s0,sp,112
    80003c00:	8b2a                	mv	s6,a0
    80003c02:	8c2e                	mv	s8,a1
    80003c04:	8ab2                	mv	s5,a2
    80003c06:	8936                	mv	s2,a3
    80003c08:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c0a:	00e687bb          	addw	a5,a3,a4
    80003c0e:	0ed7e263          	bltu	a5,a3,80003cf2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c12:	00043737          	lui	a4,0x43
    80003c16:	0ef76063          	bltu	a4,a5,80003cf6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c1a:	0c0b8863          	beqz	s7,80003cea <writei+0x10e>
    80003c1e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c20:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c24:	5cfd                	li	s9,-1
    80003c26:	a091                	j	80003c6a <writei+0x8e>
    80003c28:	02099d93          	slli	s11,s3,0x20
    80003c2c:	020ddd93          	srli	s11,s11,0x20
    80003c30:	05848793          	addi	a5,s1,88
    80003c34:	86ee                	mv	a3,s11
    80003c36:	8656                	mv	a2,s5
    80003c38:	85e2                	mv	a1,s8
    80003c3a:	953e                	add	a0,a0,a5
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	844080e7          	jalr	-1980(ra) # 80002480 <either_copyin>
    80003c44:	07950263          	beq	a0,s9,80003ca8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c48:	8526                	mv	a0,s1
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	794080e7          	jalr	1940(ra) # 800043de <log_write>
    brelse(bp);
    80003c52:	8526                	mv	a0,s1
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	508080e7          	jalr	1288(ra) # 8000315c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c5c:	01498a3b          	addw	s4,s3,s4
    80003c60:	0129893b          	addw	s2,s3,s2
    80003c64:	9aee                	add	s5,s5,s11
    80003c66:	057a7663          	bgeu	s4,s7,80003cb2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c6a:	000b2483          	lw	s1,0(s6)
    80003c6e:	00a9559b          	srliw	a1,s2,0xa
    80003c72:	855a                	mv	a0,s6
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	7ac080e7          	jalr	1964(ra) # 80003420 <bmap>
    80003c7c:	0005059b          	sext.w	a1,a0
    80003c80:	8526                	mv	a0,s1
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	3aa080e7          	jalr	938(ra) # 8000302c <bread>
    80003c8a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c8c:	3ff97513          	andi	a0,s2,1023
    80003c90:	40ad07bb          	subw	a5,s10,a0
    80003c94:	414b873b          	subw	a4,s7,s4
    80003c98:	89be                	mv	s3,a5
    80003c9a:	2781                	sext.w	a5,a5
    80003c9c:	0007069b          	sext.w	a3,a4
    80003ca0:	f8f6f4e3          	bgeu	a3,a5,80003c28 <writei+0x4c>
    80003ca4:	89ba                	mv	s3,a4
    80003ca6:	b749                	j	80003c28 <writei+0x4c>
      brelse(bp);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	4b2080e7          	jalr	1202(ra) # 8000315c <brelse>
  }

  if(off > ip->size)
    80003cb2:	04cb2783          	lw	a5,76(s6)
    80003cb6:	0127f463          	bgeu	a5,s2,80003cbe <writei+0xe2>
    ip->size = off;
    80003cba:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cbe:	855a                	mv	a0,s6
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	aa6080e7          	jalr	-1370(ra) # 80003766 <iupdate>

  return tot;
    80003cc8:	000a051b          	sext.w	a0,s4
}
    80003ccc:	70a6                	ld	ra,104(sp)
    80003cce:	7406                	ld	s0,96(sp)
    80003cd0:	64e6                	ld	s1,88(sp)
    80003cd2:	6946                	ld	s2,80(sp)
    80003cd4:	69a6                	ld	s3,72(sp)
    80003cd6:	6a06                	ld	s4,64(sp)
    80003cd8:	7ae2                	ld	s5,56(sp)
    80003cda:	7b42                	ld	s6,48(sp)
    80003cdc:	7ba2                	ld	s7,40(sp)
    80003cde:	7c02                	ld	s8,32(sp)
    80003ce0:	6ce2                	ld	s9,24(sp)
    80003ce2:	6d42                	ld	s10,16(sp)
    80003ce4:	6da2                	ld	s11,8(sp)
    80003ce6:	6165                	addi	sp,sp,112
    80003ce8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cea:	8a5e                	mv	s4,s7
    80003cec:	bfc9                	j	80003cbe <writei+0xe2>
    return -1;
    80003cee:	557d                	li	a0,-1
}
    80003cf0:	8082                	ret
    return -1;
    80003cf2:	557d                	li	a0,-1
    80003cf4:	bfe1                	j	80003ccc <writei+0xf0>
    return -1;
    80003cf6:	557d                	li	a0,-1
    80003cf8:	bfd1                	j	80003ccc <writei+0xf0>

0000000080003cfa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cfa:	1141                	addi	sp,sp,-16
    80003cfc:	e406                	sd	ra,8(sp)
    80003cfe:	e022                	sd	s0,0(sp)
    80003d00:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d02:	4639                	li	a2,14
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	092080e7          	jalr	146(ra) # 80000d96 <strncmp>
}
    80003d0c:	60a2                	ld	ra,8(sp)
    80003d0e:	6402                	ld	s0,0(sp)
    80003d10:	0141                	addi	sp,sp,16
    80003d12:	8082                	ret

0000000080003d14 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d14:	7139                	addi	sp,sp,-64
    80003d16:	fc06                	sd	ra,56(sp)
    80003d18:	f822                	sd	s0,48(sp)
    80003d1a:	f426                	sd	s1,40(sp)
    80003d1c:	f04a                	sd	s2,32(sp)
    80003d1e:	ec4e                	sd	s3,24(sp)
    80003d20:	e852                	sd	s4,16(sp)
    80003d22:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d24:	04451703          	lh	a4,68(a0)
    80003d28:	4785                	li	a5,1
    80003d2a:	00f71a63          	bne	a4,a5,80003d3e <dirlookup+0x2a>
    80003d2e:	892a                	mv	s2,a0
    80003d30:	89ae                	mv	s3,a1
    80003d32:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d34:	457c                	lw	a5,76(a0)
    80003d36:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d38:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3a:	e79d                	bnez	a5,80003d68 <dirlookup+0x54>
    80003d3c:	a8a5                	j	80003db4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d3e:	00005517          	auipc	a0,0x5
    80003d42:	9a250513          	addi	a0,a0,-1630 # 800086e0 <syscalls+0x1b0>
    80003d46:	ffffc097          	auipc	ra,0xffffc
    80003d4a:	7e4080e7          	jalr	2020(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003d4e:	00005517          	auipc	a0,0x5
    80003d52:	9aa50513          	addi	a0,a0,-1622 # 800086f8 <syscalls+0x1c8>
    80003d56:	ffffc097          	auipc	ra,0xffffc
    80003d5a:	7d4080e7          	jalr	2004(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5e:	24c1                	addiw	s1,s1,16
    80003d60:	04c92783          	lw	a5,76(s2)
    80003d64:	04f4f763          	bgeu	s1,a5,80003db2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d68:	4741                	li	a4,16
    80003d6a:	86a6                	mv	a3,s1
    80003d6c:	fc040613          	addi	a2,s0,-64
    80003d70:	4581                	li	a1,0
    80003d72:	854a                	mv	a0,s2
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	d70080e7          	jalr	-656(ra) # 80003ae4 <readi>
    80003d7c:	47c1                	li	a5,16
    80003d7e:	fcf518e3          	bne	a0,a5,80003d4e <dirlookup+0x3a>
    if(de.inum == 0)
    80003d82:	fc045783          	lhu	a5,-64(s0)
    80003d86:	dfe1                	beqz	a5,80003d5e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d88:	fc240593          	addi	a1,s0,-62
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	f6c080e7          	jalr	-148(ra) # 80003cfa <namecmp>
    80003d96:	f561                	bnez	a0,80003d5e <dirlookup+0x4a>
      if(poff)
    80003d98:	000a0463          	beqz	s4,80003da0 <dirlookup+0x8c>
        *poff = off;
    80003d9c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003da0:	fc045583          	lhu	a1,-64(s0)
    80003da4:	00092503          	lw	a0,0(s2)
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	754080e7          	jalr	1876(ra) # 800034fc <iget>
    80003db0:	a011                	j	80003db4 <dirlookup+0xa0>
  return 0;
    80003db2:	4501                	li	a0,0
}
    80003db4:	70e2                	ld	ra,56(sp)
    80003db6:	7442                	ld	s0,48(sp)
    80003db8:	74a2                	ld	s1,40(sp)
    80003dba:	7902                	ld	s2,32(sp)
    80003dbc:	69e2                	ld	s3,24(sp)
    80003dbe:	6a42                	ld	s4,16(sp)
    80003dc0:	6121                	addi	sp,sp,64
    80003dc2:	8082                	ret

0000000080003dc4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dc4:	711d                	addi	sp,sp,-96
    80003dc6:	ec86                	sd	ra,88(sp)
    80003dc8:	e8a2                	sd	s0,80(sp)
    80003dca:	e4a6                	sd	s1,72(sp)
    80003dcc:	e0ca                	sd	s2,64(sp)
    80003dce:	fc4e                	sd	s3,56(sp)
    80003dd0:	f852                	sd	s4,48(sp)
    80003dd2:	f456                	sd	s5,40(sp)
    80003dd4:	f05a                	sd	s6,32(sp)
    80003dd6:	ec5e                	sd	s7,24(sp)
    80003dd8:	e862                	sd	s8,16(sp)
    80003dda:	e466                	sd	s9,8(sp)
    80003ddc:	1080                	addi	s0,sp,96
    80003dde:	84aa                	mv	s1,a0
    80003de0:	8aae                	mv	s5,a1
    80003de2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003de4:	00054703          	lbu	a4,0(a0)
    80003de8:	02f00793          	li	a5,47
    80003dec:	02f70363          	beq	a4,a5,80003e12 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003df0:	ffffe097          	auipc	ra,0xffffe
    80003df4:	b8e080e7          	jalr	-1138(ra) # 8000197e <myproc>
    80003df8:	16053503          	ld	a0,352(a0)
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	9f6080e7          	jalr	-1546(ra) # 800037f2 <idup>
    80003e04:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e06:	02f00913          	li	s2,47
  len = path - s;
    80003e0a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e0c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e0e:	4b85                	li	s7,1
    80003e10:	a865                	j	80003ec8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e12:	4585                	li	a1,1
    80003e14:	4505                	li	a0,1
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	6e6080e7          	jalr	1766(ra) # 800034fc <iget>
    80003e1e:	89aa                	mv	s3,a0
    80003e20:	b7dd                	j	80003e06 <namex+0x42>
      iunlockput(ip);
    80003e22:	854e                	mv	a0,s3
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	c6e080e7          	jalr	-914(ra) # 80003a92 <iunlockput>
      return 0;
    80003e2c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e2e:	854e                	mv	a0,s3
    80003e30:	60e6                	ld	ra,88(sp)
    80003e32:	6446                	ld	s0,80(sp)
    80003e34:	64a6                	ld	s1,72(sp)
    80003e36:	6906                	ld	s2,64(sp)
    80003e38:	79e2                	ld	s3,56(sp)
    80003e3a:	7a42                	ld	s4,48(sp)
    80003e3c:	7aa2                	ld	s5,40(sp)
    80003e3e:	7b02                	ld	s6,32(sp)
    80003e40:	6be2                	ld	s7,24(sp)
    80003e42:	6c42                	ld	s8,16(sp)
    80003e44:	6ca2                	ld	s9,8(sp)
    80003e46:	6125                	addi	sp,sp,96
    80003e48:	8082                	ret
      iunlock(ip);
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	aa6080e7          	jalr	-1370(ra) # 800038f2 <iunlock>
      return ip;
    80003e54:	bfe9                	j	80003e2e <namex+0x6a>
      iunlockput(ip);
    80003e56:	854e                	mv	a0,s3
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	c3a080e7          	jalr	-966(ra) # 80003a92 <iunlockput>
      return 0;
    80003e60:	89e6                	mv	s3,s9
    80003e62:	b7f1                	j	80003e2e <namex+0x6a>
  len = path - s;
    80003e64:	40b48633          	sub	a2,s1,a1
    80003e68:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e6c:	099c5463          	bge	s8,s9,80003ef4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e70:	4639                	li	a2,14
    80003e72:	8552                	mv	a0,s4
    80003e74:	ffffd097          	auipc	ra,0xffffd
    80003e78:	ea6080e7          	jalr	-346(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003e7c:	0004c783          	lbu	a5,0(s1)
    80003e80:	01279763          	bne	a5,s2,80003e8e <namex+0xca>
    path++;
    80003e84:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	ff278de3          	beq	a5,s2,80003e84 <namex+0xc0>
    ilock(ip);
    80003e8e:	854e                	mv	a0,s3
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	9a0080e7          	jalr	-1632(ra) # 80003830 <ilock>
    if(ip->type != T_DIR){
    80003e98:	04499783          	lh	a5,68(s3)
    80003e9c:	f97793e3          	bne	a5,s7,80003e22 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ea0:	000a8563          	beqz	s5,80003eaa <namex+0xe6>
    80003ea4:	0004c783          	lbu	a5,0(s1)
    80003ea8:	d3cd                	beqz	a5,80003e4a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eaa:	865a                	mv	a2,s6
    80003eac:	85d2                	mv	a1,s4
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	e64080e7          	jalr	-412(ra) # 80003d14 <dirlookup>
    80003eb8:	8caa                	mv	s9,a0
    80003eba:	dd51                	beqz	a0,80003e56 <namex+0x92>
    iunlockput(ip);
    80003ebc:	854e                	mv	a0,s3
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	bd4080e7          	jalr	-1068(ra) # 80003a92 <iunlockput>
    ip = next;
    80003ec6:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ec8:	0004c783          	lbu	a5,0(s1)
    80003ecc:	05279763          	bne	a5,s2,80003f1a <namex+0x156>
    path++;
    80003ed0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ed2:	0004c783          	lbu	a5,0(s1)
    80003ed6:	ff278de3          	beq	a5,s2,80003ed0 <namex+0x10c>
  if(*path == 0)
    80003eda:	c79d                	beqz	a5,80003f08 <namex+0x144>
    path++;
    80003edc:	85a6                	mv	a1,s1
  len = path - s;
    80003ede:	8cda                	mv	s9,s6
    80003ee0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003ee2:	01278963          	beq	a5,s2,80003ef4 <namex+0x130>
    80003ee6:	dfbd                	beqz	a5,80003e64 <namex+0xa0>
    path++;
    80003ee8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	ff279ce3          	bne	a5,s2,80003ee6 <namex+0x122>
    80003ef2:	bf8d                	j	80003e64 <namex+0xa0>
    memmove(name, s, len);
    80003ef4:	2601                	sext.w	a2,a2
    80003ef6:	8552                	mv	a0,s4
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	e22080e7          	jalr	-478(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003f00:	9cd2                	add	s9,s9,s4
    80003f02:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f06:	bf9d                	j	80003e7c <namex+0xb8>
  if(nameiparent){
    80003f08:	f20a83e3          	beqz	s5,80003e2e <namex+0x6a>
    iput(ip);
    80003f0c:	854e                	mv	a0,s3
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	adc080e7          	jalr	-1316(ra) # 800039ea <iput>
    return 0;
    80003f16:	4981                	li	s3,0
    80003f18:	bf19                	j	80003e2e <namex+0x6a>
  if(*path == 0)
    80003f1a:	d7fd                	beqz	a5,80003f08 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f1c:	0004c783          	lbu	a5,0(s1)
    80003f20:	85a6                	mv	a1,s1
    80003f22:	b7d1                	j	80003ee6 <namex+0x122>

0000000080003f24 <dirlink>:
{
    80003f24:	7139                	addi	sp,sp,-64
    80003f26:	fc06                	sd	ra,56(sp)
    80003f28:	f822                	sd	s0,48(sp)
    80003f2a:	f426                	sd	s1,40(sp)
    80003f2c:	f04a                	sd	s2,32(sp)
    80003f2e:	ec4e                	sd	s3,24(sp)
    80003f30:	e852                	sd	s4,16(sp)
    80003f32:	0080                	addi	s0,sp,64
    80003f34:	892a                	mv	s2,a0
    80003f36:	8a2e                	mv	s4,a1
    80003f38:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f3a:	4601                	li	a2,0
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	dd8080e7          	jalr	-552(ra) # 80003d14 <dirlookup>
    80003f44:	e93d                	bnez	a0,80003fba <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f46:	04c92483          	lw	s1,76(s2)
    80003f4a:	c49d                	beqz	s1,80003f78 <dirlink+0x54>
    80003f4c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f4e:	4741                	li	a4,16
    80003f50:	86a6                	mv	a3,s1
    80003f52:	fc040613          	addi	a2,s0,-64
    80003f56:	4581                	li	a1,0
    80003f58:	854a                	mv	a0,s2
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	b8a080e7          	jalr	-1142(ra) # 80003ae4 <readi>
    80003f62:	47c1                	li	a5,16
    80003f64:	06f51163          	bne	a0,a5,80003fc6 <dirlink+0xa2>
    if(de.inum == 0)
    80003f68:	fc045783          	lhu	a5,-64(s0)
    80003f6c:	c791                	beqz	a5,80003f78 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f6e:	24c1                	addiw	s1,s1,16
    80003f70:	04c92783          	lw	a5,76(s2)
    80003f74:	fcf4ede3          	bltu	s1,a5,80003f4e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f78:	4639                	li	a2,14
    80003f7a:	85d2                	mv	a1,s4
    80003f7c:	fc240513          	addi	a0,s0,-62
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	e52080e7          	jalr	-430(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003f88:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f8c:	4741                	li	a4,16
    80003f8e:	86a6                	mv	a3,s1
    80003f90:	fc040613          	addi	a2,s0,-64
    80003f94:	4581                	li	a1,0
    80003f96:	854a                	mv	a0,s2
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	c44080e7          	jalr	-956(ra) # 80003bdc <writei>
    80003fa0:	872a                	mv	a4,a0
    80003fa2:	47c1                	li	a5,16
  return 0;
    80003fa4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa6:	02f71863          	bne	a4,a5,80003fd6 <dirlink+0xb2>
}
    80003faa:	70e2                	ld	ra,56(sp)
    80003fac:	7442                	ld	s0,48(sp)
    80003fae:	74a2                	ld	s1,40(sp)
    80003fb0:	7902                	ld	s2,32(sp)
    80003fb2:	69e2                	ld	s3,24(sp)
    80003fb4:	6a42                	ld	s4,16(sp)
    80003fb6:	6121                	addi	sp,sp,64
    80003fb8:	8082                	ret
    iput(ip);
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	a30080e7          	jalr	-1488(ra) # 800039ea <iput>
    return -1;
    80003fc2:	557d                	li	a0,-1
    80003fc4:	b7dd                	j	80003faa <dirlink+0x86>
      panic("dirlink read");
    80003fc6:	00004517          	auipc	a0,0x4
    80003fca:	74250513          	addi	a0,a0,1858 # 80008708 <syscalls+0x1d8>
    80003fce:	ffffc097          	auipc	ra,0xffffc
    80003fd2:	55c080e7          	jalr	1372(ra) # 8000052a <panic>
    panic("dirlink");
    80003fd6:	00005517          	auipc	a0,0x5
    80003fda:	83a50513          	addi	a0,a0,-1990 # 80008810 <syscalls+0x2e0>
    80003fde:	ffffc097          	auipc	ra,0xffffc
    80003fe2:	54c080e7          	jalr	1356(ra) # 8000052a <panic>

0000000080003fe6 <namei>:

struct inode*
namei(char *path)
{
    80003fe6:	1101                	addi	sp,sp,-32
    80003fe8:	ec06                	sd	ra,24(sp)
    80003fea:	e822                	sd	s0,16(sp)
    80003fec:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fee:	fe040613          	addi	a2,s0,-32
    80003ff2:	4581                	li	a1,0
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	dd0080e7          	jalr	-560(ra) # 80003dc4 <namex>
}
    80003ffc:	60e2                	ld	ra,24(sp)
    80003ffe:	6442                	ld	s0,16(sp)
    80004000:	6105                	addi	sp,sp,32
    80004002:	8082                	ret

0000000080004004 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004004:	1141                	addi	sp,sp,-16
    80004006:	e406                	sd	ra,8(sp)
    80004008:	e022                	sd	s0,0(sp)
    8000400a:	0800                	addi	s0,sp,16
    8000400c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000400e:	4585                	li	a1,1
    80004010:	00000097          	auipc	ra,0x0
    80004014:	db4080e7          	jalr	-588(ra) # 80003dc4 <namex>
}
    80004018:	60a2                	ld	ra,8(sp)
    8000401a:	6402                	ld	s0,0(sp)
    8000401c:	0141                	addi	sp,sp,16
    8000401e:	8082                	ret

0000000080004020 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004020:	1101                	addi	sp,sp,-32
    80004022:	ec06                	sd	ra,24(sp)
    80004024:	e822                	sd	s0,16(sp)
    80004026:	e426                	sd	s1,8(sp)
    80004028:	e04a                	sd	s2,0(sp)
    8000402a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000402c:	0001d917          	auipc	s2,0x1d
    80004030:	64490913          	addi	s2,s2,1604 # 80021670 <log>
    80004034:	01892583          	lw	a1,24(s2)
    80004038:	02892503          	lw	a0,40(s2)
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	ff0080e7          	jalr	-16(ra) # 8000302c <bread>
    80004044:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004046:	02c92683          	lw	a3,44(s2)
    8000404a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000404c:	02d05863          	blez	a3,8000407c <write_head+0x5c>
    80004050:	0001d797          	auipc	a5,0x1d
    80004054:	65078793          	addi	a5,a5,1616 # 800216a0 <log+0x30>
    80004058:	05c50713          	addi	a4,a0,92
    8000405c:	36fd                	addiw	a3,a3,-1
    8000405e:	02069613          	slli	a2,a3,0x20
    80004062:	01e65693          	srli	a3,a2,0x1e
    80004066:	0001d617          	auipc	a2,0x1d
    8000406a:	63e60613          	addi	a2,a2,1598 # 800216a4 <log+0x34>
    8000406e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004070:	4390                	lw	a2,0(a5)
    80004072:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004074:	0791                	addi	a5,a5,4
    80004076:	0711                	addi	a4,a4,4
    80004078:	fed79ce3          	bne	a5,a3,80004070 <write_head+0x50>
  }
  bwrite(buf);
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	0a0080e7          	jalr	160(ra) # 8000311e <bwrite>
  brelse(buf);
    80004086:	8526                	mv	a0,s1
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	0d4080e7          	jalr	212(ra) # 8000315c <brelse>
}
    80004090:	60e2                	ld	ra,24(sp)
    80004092:	6442                	ld	s0,16(sp)
    80004094:	64a2                	ld	s1,8(sp)
    80004096:	6902                	ld	s2,0(sp)
    80004098:	6105                	addi	sp,sp,32
    8000409a:	8082                	ret

000000008000409c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409c:	0001d797          	auipc	a5,0x1d
    800040a0:	6007a783          	lw	a5,1536(a5) # 8002169c <log+0x2c>
    800040a4:	0af05d63          	blez	a5,8000415e <install_trans+0xc2>
{
    800040a8:	7139                	addi	sp,sp,-64
    800040aa:	fc06                	sd	ra,56(sp)
    800040ac:	f822                	sd	s0,48(sp)
    800040ae:	f426                	sd	s1,40(sp)
    800040b0:	f04a                	sd	s2,32(sp)
    800040b2:	ec4e                	sd	s3,24(sp)
    800040b4:	e852                	sd	s4,16(sp)
    800040b6:	e456                	sd	s5,8(sp)
    800040b8:	e05a                	sd	s6,0(sp)
    800040ba:	0080                	addi	s0,sp,64
    800040bc:	8b2a                	mv	s6,a0
    800040be:	0001da97          	auipc	s5,0x1d
    800040c2:	5e2a8a93          	addi	s5,s5,1506 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040c8:	0001d997          	auipc	s3,0x1d
    800040cc:	5a898993          	addi	s3,s3,1448 # 80021670 <log>
    800040d0:	a00d                	j	800040f2 <install_trans+0x56>
    brelse(lbuf);
    800040d2:	854a                	mv	a0,s2
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	088080e7          	jalr	136(ra) # 8000315c <brelse>
    brelse(dbuf);
    800040dc:	8526                	mv	a0,s1
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	07e080e7          	jalr	126(ra) # 8000315c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e6:	2a05                	addiw	s4,s4,1
    800040e8:	0a91                	addi	s5,s5,4
    800040ea:	02c9a783          	lw	a5,44(s3)
    800040ee:	04fa5e63          	bge	s4,a5,8000414a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040f2:	0189a583          	lw	a1,24(s3)
    800040f6:	014585bb          	addw	a1,a1,s4
    800040fa:	2585                	addiw	a1,a1,1
    800040fc:	0289a503          	lw	a0,40(s3)
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	f2c080e7          	jalr	-212(ra) # 8000302c <bread>
    80004108:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000410a:	000aa583          	lw	a1,0(s5)
    8000410e:	0289a503          	lw	a0,40(s3)
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	f1a080e7          	jalr	-230(ra) # 8000302c <bread>
    8000411a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000411c:	40000613          	li	a2,1024
    80004120:	05890593          	addi	a1,s2,88
    80004124:	05850513          	addi	a0,a0,88
    80004128:	ffffd097          	auipc	ra,0xffffd
    8000412c:	bf2080e7          	jalr	-1038(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004130:	8526                	mv	a0,s1
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	fec080e7          	jalr	-20(ra) # 8000311e <bwrite>
    if(recovering == 0)
    8000413a:	f80b1ce3          	bnez	s6,800040d2 <install_trans+0x36>
      bunpin(dbuf);
    8000413e:	8526                	mv	a0,s1
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	0f6080e7          	jalr	246(ra) # 80003236 <bunpin>
    80004148:	b769                	j	800040d2 <install_trans+0x36>
}
    8000414a:	70e2                	ld	ra,56(sp)
    8000414c:	7442                	ld	s0,48(sp)
    8000414e:	74a2                	ld	s1,40(sp)
    80004150:	7902                	ld	s2,32(sp)
    80004152:	69e2                	ld	s3,24(sp)
    80004154:	6a42                	ld	s4,16(sp)
    80004156:	6aa2                	ld	s5,8(sp)
    80004158:	6b02                	ld	s6,0(sp)
    8000415a:	6121                	addi	sp,sp,64
    8000415c:	8082                	ret
    8000415e:	8082                	ret

0000000080004160 <initlog>:
{
    80004160:	7179                	addi	sp,sp,-48
    80004162:	f406                	sd	ra,40(sp)
    80004164:	f022                	sd	s0,32(sp)
    80004166:	ec26                	sd	s1,24(sp)
    80004168:	e84a                	sd	s2,16(sp)
    8000416a:	e44e                	sd	s3,8(sp)
    8000416c:	1800                	addi	s0,sp,48
    8000416e:	892a                	mv	s2,a0
    80004170:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004172:	0001d497          	auipc	s1,0x1d
    80004176:	4fe48493          	addi	s1,s1,1278 # 80021670 <log>
    8000417a:	00004597          	auipc	a1,0x4
    8000417e:	59e58593          	addi	a1,a1,1438 # 80008718 <syscalls+0x1e8>
    80004182:	8526                	mv	a0,s1
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	9ae080e7          	jalr	-1618(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000418c:	0149a583          	lw	a1,20(s3)
    80004190:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004192:	0109a783          	lw	a5,16(s3)
    80004196:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004198:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000419c:	854a                	mv	a0,s2
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	e8e080e7          	jalr	-370(ra) # 8000302c <bread>
  log.lh.n = lh->n;
    800041a6:	4d34                	lw	a3,88(a0)
    800041a8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041aa:	02d05663          	blez	a3,800041d6 <initlog+0x76>
    800041ae:	05c50793          	addi	a5,a0,92
    800041b2:	0001d717          	auipc	a4,0x1d
    800041b6:	4ee70713          	addi	a4,a4,1262 # 800216a0 <log+0x30>
    800041ba:	36fd                	addiw	a3,a3,-1
    800041bc:	02069613          	slli	a2,a3,0x20
    800041c0:	01e65693          	srli	a3,a2,0x1e
    800041c4:	06050613          	addi	a2,a0,96
    800041c8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041ca:	4390                	lw	a2,0(a5)
    800041cc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041ce:	0791                	addi	a5,a5,4
    800041d0:	0711                	addi	a4,a4,4
    800041d2:	fed79ce3          	bne	a5,a3,800041ca <initlog+0x6a>
  brelse(buf);
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	f86080e7          	jalr	-122(ra) # 8000315c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041de:	4505                	li	a0,1
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	ebc080e7          	jalr	-324(ra) # 8000409c <install_trans>
  log.lh.n = 0;
    800041e8:	0001d797          	auipc	a5,0x1d
    800041ec:	4a07aa23          	sw	zero,1204(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	e30080e7          	jalr	-464(ra) # 80004020 <write_head>
}
    800041f8:	70a2                	ld	ra,40(sp)
    800041fa:	7402                	ld	s0,32(sp)
    800041fc:	64e2                	ld	s1,24(sp)
    800041fe:	6942                	ld	s2,16(sp)
    80004200:	69a2                	ld	s3,8(sp)
    80004202:	6145                	addi	sp,sp,48
    80004204:	8082                	ret

0000000080004206 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004206:	1101                	addi	sp,sp,-32
    80004208:	ec06                	sd	ra,24(sp)
    8000420a:	e822                	sd	s0,16(sp)
    8000420c:	e426                	sd	s1,8(sp)
    8000420e:	e04a                	sd	s2,0(sp)
    80004210:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004212:	0001d517          	auipc	a0,0x1d
    80004216:	45e50513          	addi	a0,a0,1118 # 80021670 <log>
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	9a8080e7          	jalr	-1624(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004222:	0001d497          	auipc	s1,0x1d
    80004226:	44e48493          	addi	s1,s1,1102 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000422a:	4979                	li	s2,30
    8000422c:	a039                	j	8000423a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000422e:	85a6                	mv	a1,s1
    80004230:	8526                	mv	a0,s1
    80004232:	ffffe097          	auipc	ra,0xffffe
    80004236:	d9c080e7          	jalr	-612(ra) # 80001fce <sleep>
    if(log.committing){
    8000423a:	50dc                	lw	a5,36(s1)
    8000423c:	fbed                	bnez	a5,8000422e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000423e:	509c                	lw	a5,32(s1)
    80004240:	0017871b          	addiw	a4,a5,1
    80004244:	0007069b          	sext.w	a3,a4
    80004248:	0027179b          	slliw	a5,a4,0x2
    8000424c:	9fb9                	addw	a5,a5,a4
    8000424e:	0017979b          	slliw	a5,a5,0x1
    80004252:	54d8                	lw	a4,44(s1)
    80004254:	9fb9                	addw	a5,a5,a4
    80004256:	00f95963          	bge	s2,a5,80004268 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000425a:	85a6                	mv	a1,s1
    8000425c:	8526                	mv	a0,s1
    8000425e:	ffffe097          	auipc	ra,0xffffe
    80004262:	d70080e7          	jalr	-656(ra) # 80001fce <sleep>
    80004266:	bfd1                	j	8000423a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004268:	0001d517          	auipc	a0,0x1d
    8000426c:	40850513          	addi	a0,a0,1032 # 80021670 <log>
    80004270:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	a04080e7          	jalr	-1532(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000427a:	60e2                	ld	ra,24(sp)
    8000427c:	6442                	ld	s0,16(sp)
    8000427e:	64a2                	ld	s1,8(sp)
    80004280:	6902                	ld	s2,0(sp)
    80004282:	6105                	addi	sp,sp,32
    80004284:	8082                	ret

0000000080004286 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004286:	7139                	addi	sp,sp,-64
    80004288:	fc06                	sd	ra,56(sp)
    8000428a:	f822                	sd	s0,48(sp)
    8000428c:	f426                	sd	s1,40(sp)
    8000428e:	f04a                	sd	s2,32(sp)
    80004290:	ec4e                	sd	s3,24(sp)
    80004292:	e852                	sd	s4,16(sp)
    80004294:	e456                	sd	s5,8(sp)
    80004296:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004298:	0001d497          	auipc	s1,0x1d
    8000429c:	3d848493          	addi	s1,s1,984 # 80021670 <log>
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	920080e7          	jalr	-1760(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800042aa:	509c                	lw	a5,32(s1)
    800042ac:	37fd                	addiw	a5,a5,-1
    800042ae:	0007891b          	sext.w	s2,a5
    800042b2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042b4:	50dc                	lw	a5,36(s1)
    800042b6:	e7b9                	bnez	a5,80004304 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042b8:	04091e63          	bnez	s2,80004314 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042bc:	0001d497          	auipc	s1,0x1d
    800042c0:	3b448493          	addi	s1,s1,948 # 80021670 <log>
    800042c4:	4785                	li	a5,1
    800042c6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042c8:	8526                	mv	a0,s1
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	9ac080e7          	jalr	-1620(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042d2:	54dc                	lw	a5,44(s1)
    800042d4:	06f04763          	bgtz	a5,80004342 <end_op+0xbc>
    acquire(&log.lock);
    800042d8:	0001d497          	auipc	s1,0x1d
    800042dc:	39848493          	addi	s1,s1,920 # 80021670 <log>
    800042e0:	8526                	mv	a0,s1
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	8e0080e7          	jalr	-1824(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800042ea:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042ee:	8526                	mv	a0,s1
    800042f0:	ffffe097          	auipc	ra,0xffffe
    800042f4:	e6a080e7          	jalr	-406(ra) # 8000215a <wakeup>
    release(&log.lock);
    800042f8:	8526                	mv	a0,s1
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	97c080e7          	jalr	-1668(ra) # 80000c76 <release>
}
    80004302:	a03d                	j	80004330 <end_op+0xaa>
    panic("log.committing");
    80004304:	00004517          	auipc	a0,0x4
    80004308:	41c50513          	addi	a0,a0,1052 # 80008720 <syscalls+0x1f0>
    8000430c:	ffffc097          	auipc	ra,0xffffc
    80004310:	21e080e7          	jalr	542(ra) # 8000052a <panic>
    wakeup(&log);
    80004314:	0001d497          	auipc	s1,0x1d
    80004318:	35c48493          	addi	s1,s1,860 # 80021670 <log>
    8000431c:	8526                	mv	a0,s1
    8000431e:	ffffe097          	auipc	ra,0xffffe
    80004322:	e3c080e7          	jalr	-452(ra) # 8000215a <wakeup>
  release(&log.lock);
    80004326:	8526                	mv	a0,s1
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	94e080e7          	jalr	-1714(ra) # 80000c76 <release>
}
    80004330:	70e2                	ld	ra,56(sp)
    80004332:	7442                	ld	s0,48(sp)
    80004334:	74a2                	ld	s1,40(sp)
    80004336:	7902                	ld	s2,32(sp)
    80004338:	69e2                	ld	s3,24(sp)
    8000433a:	6a42                	ld	s4,16(sp)
    8000433c:	6aa2                	ld	s5,8(sp)
    8000433e:	6121                	addi	sp,sp,64
    80004340:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004342:	0001da97          	auipc	s5,0x1d
    80004346:	35ea8a93          	addi	s5,s5,862 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000434a:	0001da17          	auipc	s4,0x1d
    8000434e:	326a0a13          	addi	s4,s4,806 # 80021670 <log>
    80004352:	018a2583          	lw	a1,24(s4)
    80004356:	012585bb          	addw	a1,a1,s2
    8000435a:	2585                	addiw	a1,a1,1
    8000435c:	028a2503          	lw	a0,40(s4)
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	ccc080e7          	jalr	-820(ra) # 8000302c <bread>
    80004368:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000436a:	000aa583          	lw	a1,0(s5)
    8000436e:	028a2503          	lw	a0,40(s4)
    80004372:	fffff097          	auipc	ra,0xfffff
    80004376:	cba080e7          	jalr	-838(ra) # 8000302c <bread>
    8000437a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000437c:	40000613          	li	a2,1024
    80004380:	05850593          	addi	a1,a0,88
    80004384:	05848513          	addi	a0,s1,88
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	992080e7          	jalr	-1646(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004390:	8526                	mv	a0,s1
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	d8c080e7          	jalr	-628(ra) # 8000311e <bwrite>
    brelse(from);
    8000439a:	854e                	mv	a0,s3
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	dc0080e7          	jalr	-576(ra) # 8000315c <brelse>
    brelse(to);
    800043a4:	8526                	mv	a0,s1
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	db6080e7          	jalr	-586(ra) # 8000315c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ae:	2905                	addiw	s2,s2,1
    800043b0:	0a91                	addi	s5,s5,4
    800043b2:	02ca2783          	lw	a5,44(s4)
    800043b6:	f8f94ee3          	blt	s2,a5,80004352 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043ba:	00000097          	auipc	ra,0x0
    800043be:	c66080e7          	jalr	-922(ra) # 80004020 <write_head>
    install_trans(0); // Now install writes to home locations
    800043c2:	4501                	li	a0,0
    800043c4:	00000097          	auipc	ra,0x0
    800043c8:	cd8080e7          	jalr	-808(ra) # 8000409c <install_trans>
    log.lh.n = 0;
    800043cc:	0001d797          	auipc	a5,0x1d
    800043d0:	2c07a823          	sw	zero,720(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	c4c080e7          	jalr	-948(ra) # 80004020 <write_head>
    800043dc:	bdf5                	j	800042d8 <end_op+0x52>

00000000800043de <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043de:	1101                	addi	sp,sp,-32
    800043e0:	ec06                	sd	ra,24(sp)
    800043e2:	e822                	sd	s0,16(sp)
    800043e4:	e426                	sd	s1,8(sp)
    800043e6:	e04a                	sd	s2,0(sp)
    800043e8:	1000                	addi	s0,sp,32
    800043ea:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043ec:	0001d917          	auipc	s2,0x1d
    800043f0:	28490913          	addi	s2,s2,644 # 80021670 <log>
    800043f4:	854a                	mv	a0,s2
    800043f6:	ffffc097          	auipc	ra,0xffffc
    800043fa:	7cc080e7          	jalr	1996(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043fe:	02c92603          	lw	a2,44(s2)
    80004402:	47f5                	li	a5,29
    80004404:	06c7c563          	blt	a5,a2,8000446e <log_write+0x90>
    80004408:	0001d797          	auipc	a5,0x1d
    8000440c:	2847a783          	lw	a5,644(a5) # 8002168c <log+0x1c>
    80004410:	37fd                	addiw	a5,a5,-1
    80004412:	04f65e63          	bge	a2,a5,8000446e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004416:	0001d797          	auipc	a5,0x1d
    8000441a:	27a7a783          	lw	a5,634(a5) # 80021690 <log+0x20>
    8000441e:	06f05063          	blez	a5,8000447e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004422:	4781                	li	a5,0
    80004424:	06c05563          	blez	a2,8000448e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004428:	44cc                	lw	a1,12(s1)
    8000442a:	0001d717          	auipc	a4,0x1d
    8000442e:	27670713          	addi	a4,a4,630 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004432:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004434:	4314                	lw	a3,0(a4)
    80004436:	04b68c63          	beq	a3,a1,8000448e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000443a:	2785                	addiw	a5,a5,1
    8000443c:	0711                	addi	a4,a4,4
    8000443e:	fef61be3          	bne	a2,a5,80004434 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004442:	0621                	addi	a2,a2,8
    80004444:	060a                	slli	a2,a2,0x2
    80004446:	0001d797          	auipc	a5,0x1d
    8000444a:	22a78793          	addi	a5,a5,554 # 80021670 <log>
    8000444e:	963e                	add	a2,a2,a5
    80004450:	44dc                	lw	a5,12(s1)
    80004452:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004454:	8526                	mv	a0,s1
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	da4080e7          	jalr	-604(ra) # 800031fa <bpin>
    log.lh.n++;
    8000445e:	0001d717          	auipc	a4,0x1d
    80004462:	21270713          	addi	a4,a4,530 # 80021670 <log>
    80004466:	575c                	lw	a5,44(a4)
    80004468:	2785                	addiw	a5,a5,1
    8000446a:	d75c                	sw	a5,44(a4)
    8000446c:	a835                	j	800044a8 <log_write+0xca>
    panic("too big a transaction");
    8000446e:	00004517          	auipc	a0,0x4
    80004472:	2c250513          	addi	a0,a0,706 # 80008730 <syscalls+0x200>
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	0b4080e7          	jalr	180(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000447e:	00004517          	auipc	a0,0x4
    80004482:	2ca50513          	addi	a0,a0,714 # 80008748 <syscalls+0x218>
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	0a4080e7          	jalr	164(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000448e:	00878713          	addi	a4,a5,8
    80004492:	00271693          	slli	a3,a4,0x2
    80004496:	0001d717          	auipc	a4,0x1d
    8000449a:	1da70713          	addi	a4,a4,474 # 80021670 <log>
    8000449e:	9736                	add	a4,a4,a3
    800044a0:	44d4                	lw	a3,12(s1)
    800044a2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044a4:	faf608e3          	beq	a2,a5,80004454 <log_write+0x76>
  }
  release(&log.lock);
    800044a8:	0001d517          	auipc	a0,0x1d
    800044ac:	1c850513          	addi	a0,a0,456 # 80021670 <log>
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7c6080e7          	jalr	1990(ra) # 80000c76 <release>
}
    800044b8:	60e2                	ld	ra,24(sp)
    800044ba:	6442                	ld	s0,16(sp)
    800044bc:	64a2                	ld	s1,8(sp)
    800044be:	6902                	ld	s2,0(sp)
    800044c0:	6105                	addi	sp,sp,32
    800044c2:	8082                	ret

00000000800044c4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	e04a                	sd	s2,0(sp)
    800044ce:	1000                	addi	s0,sp,32
    800044d0:	84aa                	mv	s1,a0
    800044d2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044d4:	00004597          	auipc	a1,0x4
    800044d8:	29458593          	addi	a1,a1,660 # 80008768 <syscalls+0x238>
    800044dc:	0521                	addi	a0,a0,8
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	654080e7          	jalr	1620(ra) # 80000b32 <initlock>
  lk->name = name;
    800044e6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044ea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ee:	0204a423          	sw	zero,40(s1)
}
    800044f2:	60e2                	ld	ra,24(sp)
    800044f4:	6442                	ld	s0,16(sp)
    800044f6:	64a2                	ld	s1,8(sp)
    800044f8:	6902                	ld	s2,0(sp)
    800044fa:	6105                	addi	sp,sp,32
    800044fc:	8082                	ret

00000000800044fe <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044fe:	1101                	addi	sp,sp,-32
    80004500:	ec06                	sd	ra,24(sp)
    80004502:	e822                	sd	s0,16(sp)
    80004504:	e426                	sd	s1,8(sp)
    80004506:	e04a                	sd	s2,0(sp)
    80004508:	1000                	addi	s0,sp,32
    8000450a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000450c:	00850913          	addi	s2,a0,8
    80004510:	854a                	mv	a0,s2
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	6b0080e7          	jalr	1712(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000451a:	409c                	lw	a5,0(s1)
    8000451c:	cb89                	beqz	a5,8000452e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000451e:	85ca                	mv	a1,s2
    80004520:	8526                	mv	a0,s1
    80004522:	ffffe097          	auipc	ra,0xffffe
    80004526:	aac080e7          	jalr	-1364(ra) # 80001fce <sleep>
  while (lk->locked) {
    8000452a:	409c                	lw	a5,0(s1)
    8000452c:	fbed                	bnez	a5,8000451e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000452e:	4785                	li	a5,1
    80004530:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004532:	ffffd097          	auipc	ra,0xffffd
    80004536:	44c080e7          	jalr	1100(ra) # 8000197e <myproc>
    8000453a:	591c                	lw	a5,48(a0)
    8000453c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000453e:	854a                	mv	a0,s2
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	736080e7          	jalr	1846(ra) # 80000c76 <release>
}
    80004548:	60e2                	ld	ra,24(sp)
    8000454a:	6442                	ld	s0,16(sp)
    8000454c:	64a2                	ld	s1,8(sp)
    8000454e:	6902                	ld	s2,0(sp)
    80004550:	6105                	addi	sp,sp,32
    80004552:	8082                	ret

0000000080004554 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004554:	1101                	addi	sp,sp,-32
    80004556:	ec06                	sd	ra,24(sp)
    80004558:	e822                	sd	s0,16(sp)
    8000455a:	e426                	sd	s1,8(sp)
    8000455c:	e04a                	sd	s2,0(sp)
    8000455e:	1000                	addi	s0,sp,32
    80004560:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004562:	00850913          	addi	s2,a0,8
    80004566:	854a                	mv	a0,s2
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	65a080e7          	jalr	1626(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004570:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004574:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffe097          	auipc	ra,0xffffe
    8000457e:	be0080e7          	jalr	-1056(ra) # 8000215a <wakeup>
  release(&lk->lk);
    80004582:	854a                	mv	a0,s2
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	6f2080e7          	jalr	1778(ra) # 80000c76 <release>
}
    8000458c:	60e2                	ld	ra,24(sp)
    8000458e:	6442                	ld	s0,16(sp)
    80004590:	64a2                	ld	s1,8(sp)
    80004592:	6902                	ld	s2,0(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret

0000000080004598 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004598:	7179                	addi	sp,sp,-48
    8000459a:	f406                	sd	ra,40(sp)
    8000459c:	f022                	sd	s0,32(sp)
    8000459e:	ec26                	sd	s1,24(sp)
    800045a0:	e84a                	sd	s2,16(sp)
    800045a2:	e44e                	sd	s3,8(sp)
    800045a4:	1800                	addi	s0,sp,48
    800045a6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045a8:	00850913          	addi	s2,a0,8
    800045ac:	854a                	mv	a0,s2
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	614080e7          	jalr	1556(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b6:	409c                	lw	a5,0(s1)
    800045b8:	ef99                	bnez	a5,800045d6 <holdingsleep+0x3e>
    800045ba:	4481                	li	s1,0
  release(&lk->lk);
    800045bc:	854a                	mv	a0,s2
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	6b8080e7          	jalr	1720(ra) # 80000c76 <release>
  return r;
}
    800045c6:	8526                	mv	a0,s1
    800045c8:	70a2                	ld	ra,40(sp)
    800045ca:	7402                	ld	s0,32(sp)
    800045cc:	64e2                	ld	s1,24(sp)
    800045ce:	6942                	ld	s2,16(sp)
    800045d0:	69a2                	ld	s3,8(sp)
    800045d2:	6145                	addi	sp,sp,48
    800045d4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045d6:	0284a983          	lw	s3,40(s1)
    800045da:	ffffd097          	auipc	ra,0xffffd
    800045de:	3a4080e7          	jalr	932(ra) # 8000197e <myproc>
    800045e2:	5904                	lw	s1,48(a0)
    800045e4:	413484b3          	sub	s1,s1,s3
    800045e8:	0014b493          	seqz	s1,s1
    800045ec:	bfc1                	j	800045bc <holdingsleep+0x24>

00000000800045ee <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045ee:	1141                	addi	sp,sp,-16
    800045f0:	e406                	sd	ra,8(sp)
    800045f2:	e022                	sd	s0,0(sp)
    800045f4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045f6:	00004597          	auipc	a1,0x4
    800045fa:	18258593          	addi	a1,a1,386 # 80008778 <syscalls+0x248>
    800045fe:	0001d517          	auipc	a0,0x1d
    80004602:	1ba50513          	addi	a0,a0,442 # 800217b8 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	52c080e7          	jalr	1324(ra) # 80000b32 <initlock>
}
    8000460e:	60a2                	ld	ra,8(sp)
    80004610:	6402                	ld	s0,0(sp)
    80004612:	0141                	addi	sp,sp,16
    80004614:	8082                	ret

0000000080004616 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004616:	1101                	addi	sp,sp,-32
    80004618:	ec06                	sd	ra,24(sp)
    8000461a:	e822                	sd	s0,16(sp)
    8000461c:	e426                	sd	s1,8(sp)
    8000461e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004620:	0001d517          	auipc	a0,0x1d
    80004624:	19850513          	addi	a0,a0,408 # 800217b8 <ftable>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	59a080e7          	jalr	1434(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004630:	0001d497          	auipc	s1,0x1d
    80004634:	1a048493          	addi	s1,s1,416 # 800217d0 <ftable+0x18>
    80004638:	0001e717          	auipc	a4,0x1e
    8000463c:	13870713          	addi	a4,a4,312 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    80004640:	40dc                	lw	a5,4(s1)
    80004642:	cf99                	beqz	a5,80004660 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004644:	02848493          	addi	s1,s1,40
    80004648:	fee49ce3          	bne	s1,a4,80004640 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000464c:	0001d517          	auipc	a0,0x1d
    80004650:	16c50513          	addi	a0,a0,364 # 800217b8 <ftable>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	622080e7          	jalr	1570(ra) # 80000c76 <release>
  return 0;
    8000465c:	4481                	li	s1,0
    8000465e:	a819                	j	80004674 <filealloc+0x5e>
      f->ref = 1;
    80004660:	4785                	li	a5,1
    80004662:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004664:	0001d517          	auipc	a0,0x1d
    80004668:	15450513          	addi	a0,a0,340 # 800217b8 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	60a080e7          	jalr	1546(ra) # 80000c76 <release>
}
    80004674:	8526                	mv	a0,s1
    80004676:	60e2                	ld	ra,24(sp)
    80004678:	6442                	ld	s0,16(sp)
    8000467a:	64a2                	ld	s1,8(sp)
    8000467c:	6105                	addi	sp,sp,32
    8000467e:	8082                	ret

0000000080004680 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004680:	1101                	addi	sp,sp,-32
    80004682:	ec06                	sd	ra,24(sp)
    80004684:	e822                	sd	s0,16(sp)
    80004686:	e426                	sd	s1,8(sp)
    80004688:	1000                	addi	s0,sp,32
    8000468a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000468c:	0001d517          	auipc	a0,0x1d
    80004690:	12c50513          	addi	a0,a0,300 # 800217b8 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	52e080e7          	jalr	1326(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000469c:	40dc                	lw	a5,4(s1)
    8000469e:	02f05263          	blez	a5,800046c2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046a2:	2785                	addiw	a5,a5,1
    800046a4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046a6:	0001d517          	auipc	a0,0x1d
    800046aa:	11250513          	addi	a0,a0,274 # 800217b8 <ftable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	5c8080e7          	jalr	1480(ra) # 80000c76 <release>
  return f;
}
    800046b6:	8526                	mv	a0,s1
    800046b8:	60e2                	ld	ra,24(sp)
    800046ba:	6442                	ld	s0,16(sp)
    800046bc:	64a2                	ld	s1,8(sp)
    800046be:	6105                	addi	sp,sp,32
    800046c0:	8082                	ret
    panic("filedup");
    800046c2:	00004517          	auipc	a0,0x4
    800046c6:	0be50513          	addi	a0,a0,190 # 80008780 <syscalls+0x250>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	e60080e7          	jalr	-416(ra) # 8000052a <panic>

00000000800046d2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046d2:	7139                	addi	sp,sp,-64
    800046d4:	fc06                	sd	ra,56(sp)
    800046d6:	f822                	sd	s0,48(sp)
    800046d8:	f426                	sd	s1,40(sp)
    800046da:	f04a                	sd	s2,32(sp)
    800046dc:	ec4e                	sd	s3,24(sp)
    800046de:	e852                	sd	s4,16(sp)
    800046e0:	e456                	sd	s5,8(sp)
    800046e2:	0080                	addi	s0,sp,64
    800046e4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046e6:	0001d517          	auipc	a0,0x1d
    800046ea:	0d250513          	addi	a0,a0,210 # 800217b8 <ftable>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	4d4080e7          	jalr	1236(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800046f6:	40dc                	lw	a5,4(s1)
    800046f8:	06f05163          	blez	a5,8000475a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046fc:	37fd                	addiw	a5,a5,-1
    800046fe:	0007871b          	sext.w	a4,a5
    80004702:	c0dc                	sw	a5,4(s1)
    80004704:	06e04363          	bgtz	a4,8000476a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004708:	0004a903          	lw	s2,0(s1)
    8000470c:	0094ca83          	lbu	s5,9(s1)
    80004710:	0104ba03          	ld	s4,16(s1)
    80004714:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004718:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000471c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004720:	0001d517          	auipc	a0,0x1d
    80004724:	09850513          	addi	a0,a0,152 # 800217b8 <ftable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	54e080e7          	jalr	1358(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004730:	4785                	li	a5,1
    80004732:	04f90d63          	beq	s2,a5,8000478c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004736:	3979                	addiw	s2,s2,-2
    80004738:	4785                	li	a5,1
    8000473a:	0527e063          	bltu	a5,s2,8000477a <fileclose+0xa8>
    begin_op();
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	ac8080e7          	jalr	-1336(ra) # 80004206 <begin_op>
    iput(ff.ip);
    80004746:	854e                	mv	a0,s3
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2a2080e7          	jalr	674(ra) # 800039ea <iput>
    end_op();
    80004750:	00000097          	auipc	ra,0x0
    80004754:	b36080e7          	jalr	-1226(ra) # 80004286 <end_op>
    80004758:	a00d                	j	8000477a <fileclose+0xa8>
    panic("fileclose");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	02e50513          	addi	a0,a0,46 # 80008788 <syscalls+0x258>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	dc8080e7          	jalr	-568(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000476a:	0001d517          	auipc	a0,0x1d
    8000476e:	04e50513          	addi	a0,a0,78 # 800217b8 <ftable>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	504080e7          	jalr	1284(ra) # 80000c76 <release>
  }
}
    8000477a:	70e2                	ld	ra,56(sp)
    8000477c:	7442                	ld	s0,48(sp)
    8000477e:	74a2                	ld	s1,40(sp)
    80004780:	7902                	ld	s2,32(sp)
    80004782:	69e2                	ld	s3,24(sp)
    80004784:	6a42                	ld	s4,16(sp)
    80004786:	6aa2                	ld	s5,8(sp)
    80004788:	6121                	addi	sp,sp,64
    8000478a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000478c:	85d6                	mv	a1,s5
    8000478e:	8552                	mv	a0,s4
    80004790:	00000097          	auipc	ra,0x0
    80004794:	34c080e7          	jalr	844(ra) # 80004adc <pipeclose>
    80004798:	b7cd                	j	8000477a <fileclose+0xa8>

000000008000479a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000479a:	715d                	addi	sp,sp,-80
    8000479c:	e486                	sd	ra,72(sp)
    8000479e:	e0a2                	sd	s0,64(sp)
    800047a0:	fc26                	sd	s1,56(sp)
    800047a2:	f84a                	sd	s2,48(sp)
    800047a4:	f44e                	sd	s3,40(sp)
    800047a6:	0880                	addi	s0,sp,80
    800047a8:	84aa                	mv	s1,a0
    800047aa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ac:	ffffd097          	auipc	ra,0xffffd
    800047b0:	1d2080e7          	jalr	466(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047b4:	409c                	lw	a5,0(s1)
    800047b6:	37f9                	addiw	a5,a5,-2
    800047b8:	4705                	li	a4,1
    800047ba:	04f76763          	bltu	a4,a5,80004808 <filestat+0x6e>
    800047be:	892a                	mv	s2,a0
    ilock(f->ip);
    800047c0:	6c88                	ld	a0,24(s1)
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	06e080e7          	jalr	110(ra) # 80003830 <ilock>
    stati(f->ip, &st);
    800047ca:	fb840593          	addi	a1,s0,-72
    800047ce:	6c88                	ld	a0,24(s1)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	2ea080e7          	jalr	746(ra) # 80003aba <stati>
    iunlock(f->ip);
    800047d8:	6c88                	ld	a0,24(s1)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	118080e7          	jalr	280(ra) # 800038f2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047e2:	46e1                	li	a3,24
    800047e4:	fb840613          	addi	a2,s0,-72
    800047e8:	85ce                	mv	a1,s3
    800047ea:	06093503          	ld	a0,96(s2)
    800047ee:	ffffd097          	auipc	ra,0xffffd
    800047f2:	e50080e7          	jalr	-432(ra) # 8000163e <copyout>
    800047f6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047fa:	60a6                	ld	ra,72(sp)
    800047fc:	6406                	ld	s0,64(sp)
    800047fe:	74e2                	ld	s1,56(sp)
    80004800:	7942                	ld	s2,48(sp)
    80004802:	79a2                	ld	s3,40(sp)
    80004804:	6161                	addi	sp,sp,80
    80004806:	8082                	ret
  return -1;
    80004808:	557d                	li	a0,-1
    8000480a:	bfc5                	j	800047fa <filestat+0x60>

000000008000480c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000480c:	7179                	addi	sp,sp,-48
    8000480e:	f406                	sd	ra,40(sp)
    80004810:	f022                	sd	s0,32(sp)
    80004812:	ec26                	sd	s1,24(sp)
    80004814:	e84a                	sd	s2,16(sp)
    80004816:	e44e                	sd	s3,8(sp)
    80004818:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000481a:	00854783          	lbu	a5,8(a0)
    8000481e:	c3d5                	beqz	a5,800048c2 <fileread+0xb6>
    80004820:	84aa                	mv	s1,a0
    80004822:	89ae                	mv	s3,a1
    80004824:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004826:	411c                	lw	a5,0(a0)
    80004828:	4705                	li	a4,1
    8000482a:	04e78963          	beq	a5,a4,8000487c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000482e:	470d                	li	a4,3
    80004830:	04e78d63          	beq	a5,a4,8000488a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004834:	4709                	li	a4,2
    80004836:	06e79e63          	bne	a5,a4,800048b2 <fileread+0xa6>
    ilock(f->ip);
    8000483a:	6d08                	ld	a0,24(a0)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	ff4080e7          	jalr	-12(ra) # 80003830 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004844:	874a                	mv	a4,s2
    80004846:	5094                	lw	a3,32(s1)
    80004848:	864e                	mv	a2,s3
    8000484a:	4585                	li	a1,1
    8000484c:	6c88                	ld	a0,24(s1)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	296080e7          	jalr	662(ra) # 80003ae4 <readi>
    80004856:	892a                	mv	s2,a0
    80004858:	00a05563          	blez	a0,80004862 <fileread+0x56>
      f->off += r;
    8000485c:	509c                	lw	a5,32(s1)
    8000485e:	9fa9                	addw	a5,a5,a0
    80004860:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004862:	6c88                	ld	a0,24(s1)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	08e080e7          	jalr	142(ra) # 800038f2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000486c:	854a                	mv	a0,s2
    8000486e:	70a2                	ld	ra,40(sp)
    80004870:	7402                	ld	s0,32(sp)
    80004872:	64e2                	ld	s1,24(sp)
    80004874:	6942                	ld	s2,16(sp)
    80004876:	69a2                	ld	s3,8(sp)
    80004878:	6145                	addi	sp,sp,48
    8000487a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000487c:	6908                	ld	a0,16(a0)
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	3c0080e7          	jalr	960(ra) # 80004c3e <piperead>
    80004886:	892a                	mv	s2,a0
    80004888:	b7d5                	j	8000486c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000488a:	02451783          	lh	a5,36(a0)
    8000488e:	03079693          	slli	a3,a5,0x30
    80004892:	92c1                	srli	a3,a3,0x30
    80004894:	4725                	li	a4,9
    80004896:	02d76863          	bltu	a4,a3,800048c6 <fileread+0xba>
    8000489a:	0792                	slli	a5,a5,0x4
    8000489c:	0001d717          	auipc	a4,0x1d
    800048a0:	e7c70713          	addi	a4,a4,-388 # 80021718 <devsw>
    800048a4:	97ba                	add	a5,a5,a4
    800048a6:	639c                	ld	a5,0(a5)
    800048a8:	c38d                	beqz	a5,800048ca <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048aa:	4505                	li	a0,1
    800048ac:	9782                	jalr	a5
    800048ae:	892a                	mv	s2,a0
    800048b0:	bf75                	j	8000486c <fileread+0x60>
    panic("fileread");
    800048b2:	00004517          	auipc	a0,0x4
    800048b6:	ee650513          	addi	a0,a0,-282 # 80008798 <syscalls+0x268>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	c70080e7          	jalr	-912(ra) # 8000052a <panic>
    return -1;
    800048c2:	597d                	li	s2,-1
    800048c4:	b765                	j	8000486c <fileread+0x60>
      return -1;
    800048c6:	597d                	li	s2,-1
    800048c8:	b755                	j	8000486c <fileread+0x60>
    800048ca:	597d                	li	s2,-1
    800048cc:	b745                	j	8000486c <fileread+0x60>

00000000800048ce <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048ce:	715d                	addi	sp,sp,-80
    800048d0:	e486                	sd	ra,72(sp)
    800048d2:	e0a2                	sd	s0,64(sp)
    800048d4:	fc26                	sd	s1,56(sp)
    800048d6:	f84a                	sd	s2,48(sp)
    800048d8:	f44e                	sd	s3,40(sp)
    800048da:	f052                	sd	s4,32(sp)
    800048dc:	ec56                	sd	s5,24(sp)
    800048de:	e85a                	sd	s6,16(sp)
    800048e0:	e45e                	sd	s7,8(sp)
    800048e2:	e062                	sd	s8,0(sp)
    800048e4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048e6:	00954783          	lbu	a5,9(a0)
    800048ea:	10078663          	beqz	a5,800049f6 <filewrite+0x128>
    800048ee:	892a                	mv	s2,a0
    800048f0:	8aae                	mv	s5,a1
    800048f2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048f4:	411c                	lw	a5,0(a0)
    800048f6:	4705                	li	a4,1
    800048f8:	02e78263          	beq	a5,a4,8000491c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048fc:	470d                	li	a4,3
    800048fe:	02e78663          	beq	a5,a4,8000492a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004902:	4709                	li	a4,2
    80004904:	0ee79163          	bne	a5,a4,800049e6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004908:	0ac05d63          	blez	a2,800049c2 <filewrite+0xf4>
    int i = 0;
    8000490c:	4981                	li	s3,0
    8000490e:	6b05                	lui	s6,0x1
    80004910:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004914:	6b85                	lui	s7,0x1
    80004916:	c00b8b9b          	addiw	s7,s7,-1024
    8000491a:	a861                	j	800049b2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000491c:	6908                	ld	a0,16(a0)
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	22e080e7          	jalr	558(ra) # 80004b4c <pipewrite>
    80004926:	8a2a                	mv	s4,a0
    80004928:	a045                	j	800049c8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000492a:	02451783          	lh	a5,36(a0)
    8000492e:	03079693          	slli	a3,a5,0x30
    80004932:	92c1                	srli	a3,a3,0x30
    80004934:	4725                	li	a4,9
    80004936:	0cd76263          	bltu	a4,a3,800049fa <filewrite+0x12c>
    8000493a:	0792                	slli	a5,a5,0x4
    8000493c:	0001d717          	auipc	a4,0x1d
    80004940:	ddc70713          	addi	a4,a4,-548 # 80021718 <devsw>
    80004944:	97ba                	add	a5,a5,a4
    80004946:	679c                	ld	a5,8(a5)
    80004948:	cbdd                	beqz	a5,800049fe <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000494a:	4505                	li	a0,1
    8000494c:	9782                	jalr	a5
    8000494e:	8a2a                	mv	s4,a0
    80004950:	a8a5                	j	800049c8 <filewrite+0xfa>
    80004952:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004956:	00000097          	auipc	ra,0x0
    8000495a:	8b0080e7          	jalr	-1872(ra) # 80004206 <begin_op>
      ilock(f->ip);
    8000495e:	01893503          	ld	a0,24(s2)
    80004962:	fffff097          	auipc	ra,0xfffff
    80004966:	ece080e7          	jalr	-306(ra) # 80003830 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000496a:	8762                	mv	a4,s8
    8000496c:	02092683          	lw	a3,32(s2)
    80004970:	01598633          	add	a2,s3,s5
    80004974:	4585                	li	a1,1
    80004976:	01893503          	ld	a0,24(s2)
    8000497a:	fffff097          	auipc	ra,0xfffff
    8000497e:	262080e7          	jalr	610(ra) # 80003bdc <writei>
    80004982:	84aa                	mv	s1,a0
    80004984:	00a05763          	blez	a0,80004992 <filewrite+0xc4>
        f->off += r;
    80004988:	02092783          	lw	a5,32(s2)
    8000498c:	9fa9                	addw	a5,a5,a0
    8000498e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004992:	01893503          	ld	a0,24(s2)
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	f5c080e7          	jalr	-164(ra) # 800038f2 <iunlock>
      end_op();
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	8e8080e7          	jalr	-1816(ra) # 80004286 <end_op>

      if(r != n1){
    800049a6:	009c1f63          	bne	s8,s1,800049c4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049aa:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049ae:	0149db63          	bge	s3,s4,800049c4 <filewrite+0xf6>
      int n1 = n - i;
    800049b2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049b6:	84be                	mv	s1,a5
    800049b8:	2781                	sext.w	a5,a5
    800049ba:	f8fb5ce3          	bge	s6,a5,80004952 <filewrite+0x84>
    800049be:	84de                	mv	s1,s7
    800049c0:	bf49                	j	80004952 <filewrite+0x84>
    int i = 0;
    800049c2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049c4:	013a1f63          	bne	s4,s3,800049e2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049c8:	8552                	mv	a0,s4
    800049ca:	60a6                	ld	ra,72(sp)
    800049cc:	6406                	ld	s0,64(sp)
    800049ce:	74e2                	ld	s1,56(sp)
    800049d0:	7942                	ld	s2,48(sp)
    800049d2:	79a2                	ld	s3,40(sp)
    800049d4:	7a02                	ld	s4,32(sp)
    800049d6:	6ae2                	ld	s5,24(sp)
    800049d8:	6b42                	ld	s6,16(sp)
    800049da:	6ba2                	ld	s7,8(sp)
    800049dc:	6c02                	ld	s8,0(sp)
    800049de:	6161                	addi	sp,sp,80
    800049e0:	8082                	ret
    ret = (i == n ? n : -1);
    800049e2:	5a7d                	li	s4,-1
    800049e4:	b7d5                	j	800049c8 <filewrite+0xfa>
    panic("filewrite");
    800049e6:	00004517          	auipc	a0,0x4
    800049ea:	dc250513          	addi	a0,a0,-574 # 800087a8 <syscalls+0x278>
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	b3c080e7          	jalr	-1220(ra) # 8000052a <panic>
    return -1;
    800049f6:	5a7d                	li	s4,-1
    800049f8:	bfc1                	j	800049c8 <filewrite+0xfa>
      return -1;
    800049fa:	5a7d                	li	s4,-1
    800049fc:	b7f1                	j	800049c8 <filewrite+0xfa>
    800049fe:	5a7d                	li	s4,-1
    80004a00:	b7e1                	j	800049c8 <filewrite+0xfa>

0000000080004a02 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a02:	7179                	addi	sp,sp,-48
    80004a04:	f406                	sd	ra,40(sp)
    80004a06:	f022                	sd	s0,32(sp)
    80004a08:	ec26                	sd	s1,24(sp)
    80004a0a:	e84a                	sd	s2,16(sp)
    80004a0c:	e44e                	sd	s3,8(sp)
    80004a0e:	e052                	sd	s4,0(sp)
    80004a10:	1800                	addi	s0,sp,48
    80004a12:	84aa                	mv	s1,a0
    80004a14:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a16:	0005b023          	sd	zero,0(a1)
    80004a1a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	bf8080e7          	jalr	-1032(ra) # 80004616 <filealloc>
    80004a26:	e088                	sd	a0,0(s1)
    80004a28:	c551                	beqz	a0,80004ab4 <pipealloc+0xb2>
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	bec080e7          	jalr	-1044(ra) # 80004616 <filealloc>
    80004a32:	00aa3023          	sd	a0,0(s4)
    80004a36:	c92d                	beqz	a0,80004aa8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	09a080e7          	jalr	154(ra) # 80000ad2 <kalloc>
    80004a40:	892a                	mv	s2,a0
    80004a42:	c125                	beqz	a0,80004aa2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a44:	4985                	li	s3,1
    80004a46:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a4a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a4e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a52:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a56:	00004597          	auipc	a1,0x4
    80004a5a:	a3258593          	addi	a1,a1,-1486 # 80008488 <states.0+0x1e0>
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	0d4080e7          	jalr	212(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004a66:	609c                	ld	a5,0(s1)
    80004a68:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a6c:	609c                	ld	a5,0(s1)
    80004a6e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a72:	609c                	ld	a5,0(s1)
    80004a74:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a78:	609c                	ld	a5,0(s1)
    80004a7a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a7e:	000a3783          	ld	a5,0(s4)
    80004a82:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a86:	000a3783          	ld	a5,0(s4)
    80004a8a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a8e:	000a3783          	ld	a5,0(s4)
    80004a92:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a96:	000a3783          	ld	a5,0(s4)
    80004a9a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a9e:	4501                	li	a0,0
    80004aa0:	a025                	j	80004ac8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aa2:	6088                	ld	a0,0(s1)
    80004aa4:	e501                	bnez	a0,80004aac <pipealloc+0xaa>
    80004aa6:	a039                	j	80004ab4 <pipealloc+0xb2>
    80004aa8:	6088                	ld	a0,0(s1)
    80004aaa:	c51d                	beqz	a0,80004ad8 <pipealloc+0xd6>
    fileclose(*f0);
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	c26080e7          	jalr	-986(ra) # 800046d2 <fileclose>
  if(*f1)
    80004ab4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ab8:	557d                	li	a0,-1
  if(*f1)
    80004aba:	c799                	beqz	a5,80004ac8 <pipealloc+0xc6>
    fileclose(*f1);
    80004abc:	853e                	mv	a0,a5
    80004abe:	00000097          	auipc	ra,0x0
    80004ac2:	c14080e7          	jalr	-1004(ra) # 800046d2 <fileclose>
  return -1;
    80004ac6:	557d                	li	a0,-1
}
    80004ac8:	70a2                	ld	ra,40(sp)
    80004aca:	7402                	ld	s0,32(sp)
    80004acc:	64e2                	ld	s1,24(sp)
    80004ace:	6942                	ld	s2,16(sp)
    80004ad0:	69a2                	ld	s3,8(sp)
    80004ad2:	6a02                	ld	s4,0(sp)
    80004ad4:	6145                	addi	sp,sp,48
    80004ad6:	8082                	ret
  return -1;
    80004ad8:	557d                	li	a0,-1
    80004ada:	b7fd                	j	80004ac8 <pipealloc+0xc6>

0000000080004adc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004adc:	1101                	addi	sp,sp,-32
    80004ade:	ec06                	sd	ra,24(sp)
    80004ae0:	e822                	sd	s0,16(sp)
    80004ae2:	e426                	sd	s1,8(sp)
    80004ae4:	e04a                	sd	s2,0(sp)
    80004ae6:	1000                	addi	s0,sp,32
    80004ae8:	84aa                	mv	s1,a0
    80004aea:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	0d6080e7          	jalr	214(ra) # 80000bc2 <acquire>
  if(writable){
    80004af4:	02090d63          	beqz	s2,80004b2e <pipeclose+0x52>
    pi->writeopen = 0;
    80004af8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004afc:	21848513          	addi	a0,s1,536
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	65a080e7          	jalr	1626(ra) # 8000215a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b08:	2204b783          	ld	a5,544(s1)
    80004b0c:	eb95                	bnez	a5,80004b40 <pipeclose+0x64>
    release(&pi->lock);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	166080e7          	jalr	358(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004b18:	8526                	mv	a0,s1
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	ebc080e7          	jalr	-324(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004b22:	60e2                	ld	ra,24(sp)
    80004b24:	6442                	ld	s0,16(sp)
    80004b26:	64a2                	ld	s1,8(sp)
    80004b28:	6902                	ld	s2,0(sp)
    80004b2a:	6105                	addi	sp,sp,32
    80004b2c:	8082                	ret
    pi->readopen = 0;
    80004b2e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b32:	21c48513          	addi	a0,s1,540
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	624080e7          	jalr	1572(ra) # 8000215a <wakeup>
    80004b3e:	b7e9                	j	80004b08 <pipeclose+0x2c>
    release(&pi->lock);
    80004b40:	8526                	mv	a0,s1
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	134080e7          	jalr	308(ra) # 80000c76 <release>
}
    80004b4a:	bfe1                	j	80004b22 <pipeclose+0x46>

0000000080004b4c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b4c:	711d                	addi	sp,sp,-96
    80004b4e:	ec86                	sd	ra,88(sp)
    80004b50:	e8a2                	sd	s0,80(sp)
    80004b52:	e4a6                	sd	s1,72(sp)
    80004b54:	e0ca                	sd	s2,64(sp)
    80004b56:	fc4e                	sd	s3,56(sp)
    80004b58:	f852                	sd	s4,48(sp)
    80004b5a:	f456                	sd	s5,40(sp)
    80004b5c:	f05a                	sd	s6,32(sp)
    80004b5e:	ec5e                	sd	s7,24(sp)
    80004b60:	e862                	sd	s8,16(sp)
    80004b62:	1080                	addi	s0,sp,96
    80004b64:	84aa                	mv	s1,a0
    80004b66:	8aae                	mv	s5,a1
    80004b68:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	e14080e7          	jalr	-492(ra) # 8000197e <myproc>
    80004b72:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b74:	8526                	mv	a0,s1
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	04c080e7          	jalr	76(ra) # 80000bc2 <acquire>
  while(i < n){
    80004b7e:	0b405363          	blez	s4,80004c24 <pipewrite+0xd8>
  int i = 0;
    80004b82:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b84:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b86:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b8a:	21c48b93          	addi	s7,s1,540
    80004b8e:	a089                	j	80004bd0 <pipewrite+0x84>
      release(&pi->lock);
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	0e4080e7          	jalr	228(ra) # 80000c76 <release>
      return -1;
    80004b9a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b9c:	854a                	mv	a0,s2
    80004b9e:	60e6                	ld	ra,88(sp)
    80004ba0:	6446                	ld	s0,80(sp)
    80004ba2:	64a6                	ld	s1,72(sp)
    80004ba4:	6906                	ld	s2,64(sp)
    80004ba6:	79e2                	ld	s3,56(sp)
    80004ba8:	7a42                	ld	s4,48(sp)
    80004baa:	7aa2                	ld	s5,40(sp)
    80004bac:	7b02                	ld	s6,32(sp)
    80004bae:	6be2                	ld	s7,24(sp)
    80004bb0:	6c42                	ld	s8,16(sp)
    80004bb2:	6125                	addi	sp,sp,96
    80004bb4:	8082                	ret
      wakeup(&pi->nread);
    80004bb6:	8562                	mv	a0,s8
    80004bb8:	ffffd097          	auipc	ra,0xffffd
    80004bbc:	5a2080e7          	jalr	1442(ra) # 8000215a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bc0:	85a6                	mv	a1,s1
    80004bc2:	855e                	mv	a0,s7
    80004bc4:	ffffd097          	auipc	ra,0xffffd
    80004bc8:	40a080e7          	jalr	1034(ra) # 80001fce <sleep>
  while(i < n){
    80004bcc:	05495d63          	bge	s2,s4,80004c26 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004bd0:	2204a783          	lw	a5,544(s1)
    80004bd4:	dfd5                	beqz	a5,80004b90 <pipewrite+0x44>
    80004bd6:	0289a783          	lw	a5,40(s3)
    80004bda:	fbdd                	bnez	a5,80004b90 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bdc:	2184a783          	lw	a5,536(s1)
    80004be0:	21c4a703          	lw	a4,540(s1)
    80004be4:	2007879b          	addiw	a5,a5,512
    80004be8:	fcf707e3          	beq	a4,a5,80004bb6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bec:	4685                	li	a3,1
    80004bee:	01590633          	add	a2,s2,s5
    80004bf2:	faf40593          	addi	a1,s0,-81
    80004bf6:	0609b503          	ld	a0,96(s3)
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	ad0080e7          	jalr	-1328(ra) # 800016ca <copyin>
    80004c02:	03650263          	beq	a0,s6,80004c26 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c06:	21c4a783          	lw	a5,540(s1)
    80004c0a:	0017871b          	addiw	a4,a5,1
    80004c0e:	20e4ae23          	sw	a4,540(s1)
    80004c12:	1ff7f793          	andi	a5,a5,511
    80004c16:	97a6                	add	a5,a5,s1
    80004c18:	faf44703          	lbu	a4,-81(s0)
    80004c1c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c20:	2905                	addiw	s2,s2,1
    80004c22:	b76d                	j	80004bcc <pipewrite+0x80>
  int i = 0;
    80004c24:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c26:	21848513          	addi	a0,s1,536
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	530080e7          	jalr	1328(ra) # 8000215a <wakeup>
  release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	042080e7          	jalr	66(ra) # 80000c76 <release>
  return i;
    80004c3c:	b785                	j	80004b9c <pipewrite+0x50>

0000000080004c3e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c3e:	715d                	addi	sp,sp,-80
    80004c40:	e486                	sd	ra,72(sp)
    80004c42:	e0a2                	sd	s0,64(sp)
    80004c44:	fc26                	sd	s1,56(sp)
    80004c46:	f84a                	sd	s2,48(sp)
    80004c48:	f44e                	sd	s3,40(sp)
    80004c4a:	f052                	sd	s4,32(sp)
    80004c4c:	ec56                	sd	s5,24(sp)
    80004c4e:	e85a                	sd	s6,16(sp)
    80004c50:	0880                	addi	s0,sp,80
    80004c52:	84aa                	mv	s1,a0
    80004c54:	892e                	mv	s2,a1
    80004c56:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	d26080e7          	jalr	-730(ra) # 8000197e <myproc>
    80004c60:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	f5e080e7          	jalr	-162(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6c:	2184a703          	lw	a4,536(s1)
    80004c70:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c74:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c78:	02f71463          	bne	a4,a5,80004ca0 <piperead+0x62>
    80004c7c:	2244a783          	lw	a5,548(s1)
    80004c80:	c385                	beqz	a5,80004ca0 <piperead+0x62>
    if(pr->killed){
    80004c82:	028a2783          	lw	a5,40(s4)
    80004c86:	ebc1                	bnez	a5,80004d16 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c88:	85a6                	mv	a1,s1
    80004c8a:	854e                	mv	a0,s3
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	342080e7          	jalr	834(ra) # 80001fce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c94:	2184a703          	lw	a4,536(s1)
    80004c98:	21c4a783          	lw	a5,540(s1)
    80004c9c:	fef700e3          	beq	a4,a5,80004c7c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca4:	05505363          	blez	s5,80004cea <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004ca8:	2184a783          	lw	a5,536(s1)
    80004cac:	21c4a703          	lw	a4,540(s1)
    80004cb0:	02f70d63          	beq	a4,a5,80004cea <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cb4:	0017871b          	addiw	a4,a5,1
    80004cb8:	20e4ac23          	sw	a4,536(s1)
    80004cbc:	1ff7f793          	andi	a5,a5,511
    80004cc0:	97a6                	add	a5,a5,s1
    80004cc2:	0187c783          	lbu	a5,24(a5)
    80004cc6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cca:	4685                	li	a3,1
    80004ccc:	fbf40613          	addi	a2,s0,-65
    80004cd0:	85ca                	mv	a1,s2
    80004cd2:	060a3503          	ld	a0,96(s4)
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	968080e7          	jalr	-1688(ra) # 8000163e <copyout>
    80004cde:	01650663          	beq	a0,s6,80004cea <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ce2:	2985                	addiw	s3,s3,1
    80004ce4:	0905                	addi	s2,s2,1
    80004ce6:	fd3a91e3          	bne	s5,s3,80004ca8 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cea:	21c48513          	addi	a0,s1,540
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	46c080e7          	jalr	1132(ra) # 8000215a <wakeup>
  release(&pi->lock);
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	f7e080e7          	jalr	-130(ra) # 80000c76 <release>
  return i;
}
    80004d00:	854e                	mv	a0,s3
    80004d02:	60a6                	ld	ra,72(sp)
    80004d04:	6406                	ld	s0,64(sp)
    80004d06:	74e2                	ld	s1,56(sp)
    80004d08:	7942                	ld	s2,48(sp)
    80004d0a:	79a2                	ld	s3,40(sp)
    80004d0c:	7a02                	ld	s4,32(sp)
    80004d0e:	6ae2                	ld	s5,24(sp)
    80004d10:	6b42                	ld	s6,16(sp)
    80004d12:	6161                	addi	sp,sp,80
    80004d14:	8082                	ret
      release(&pi->lock);
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	f5e080e7          	jalr	-162(ra) # 80000c76 <release>
      return -1;
    80004d20:	59fd                	li	s3,-1
    80004d22:	bff9                	j	80004d00 <piperead+0xc2>

0000000080004d24 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d24:	de010113          	addi	sp,sp,-544
    80004d28:	20113c23          	sd	ra,536(sp)
    80004d2c:	20813823          	sd	s0,528(sp)
    80004d30:	20913423          	sd	s1,520(sp)
    80004d34:	21213023          	sd	s2,512(sp)
    80004d38:	ffce                	sd	s3,504(sp)
    80004d3a:	fbd2                	sd	s4,496(sp)
    80004d3c:	f7d6                	sd	s5,488(sp)
    80004d3e:	f3da                	sd	s6,480(sp)
    80004d40:	efde                	sd	s7,472(sp)
    80004d42:	ebe2                	sd	s8,464(sp)
    80004d44:	e7e6                	sd	s9,456(sp)
    80004d46:	e3ea                	sd	s10,448(sp)
    80004d48:	ff6e                	sd	s11,440(sp)
    80004d4a:	1400                	addi	s0,sp,544
    80004d4c:	892a                	mv	s2,a0
    80004d4e:	dea43423          	sd	a0,-536(s0)
    80004d52:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	c28080e7          	jalr	-984(ra) # 8000197e <myproc>
    80004d5e:	84aa                	mv	s1,a0

  begin_op();
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	4a6080e7          	jalr	1190(ra) # 80004206 <begin_op>

  if((ip = namei(path)) == 0){
    80004d68:	854a                	mv	a0,s2
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	27c080e7          	jalr	636(ra) # 80003fe6 <namei>
    80004d72:	c93d                	beqz	a0,80004de8 <exec+0xc4>
    80004d74:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	aba080e7          	jalr	-1350(ra) # 80003830 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d7e:	04000713          	li	a4,64
    80004d82:	4681                	li	a3,0
    80004d84:	e4840613          	addi	a2,s0,-440
    80004d88:	4581                	li	a1,0
    80004d8a:	8556                	mv	a0,s5
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	d58080e7          	jalr	-680(ra) # 80003ae4 <readi>
    80004d94:	04000793          	li	a5,64
    80004d98:	00f51a63          	bne	a0,a5,80004dac <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d9c:	e4842703          	lw	a4,-440(s0)
    80004da0:	464c47b7          	lui	a5,0x464c4
    80004da4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004da8:	04f70663          	beq	a4,a5,80004df4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dac:	8556                	mv	a0,s5
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	ce4080e7          	jalr	-796(ra) # 80003a92 <iunlockput>
    end_op();
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	4d0080e7          	jalr	1232(ra) # 80004286 <end_op>
  }
  return -1;
    80004dbe:	557d                	li	a0,-1
}
    80004dc0:	21813083          	ld	ra,536(sp)
    80004dc4:	21013403          	ld	s0,528(sp)
    80004dc8:	20813483          	ld	s1,520(sp)
    80004dcc:	20013903          	ld	s2,512(sp)
    80004dd0:	79fe                	ld	s3,504(sp)
    80004dd2:	7a5e                	ld	s4,496(sp)
    80004dd4:	7abe                	ld	s5,488(sp)
    80004dd6:	7b1e                	ld	s6,480(sp)
    80004dd8:	6bfe                	ld	s7,472(sp)
    80004dda:	6c5e                	ld	s8,464(sp)
    80004ddc:	6cbe                	ld	s9,456(sp)
    80004dde:	6d1e                	ld	s10,448(sp)
    80004de0:	7dfa                	ld	s11,440(sp)
    80004de2:	22010113          	addi	sp,sp,544
    80004de6:	8082                	ret
    end_op();
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	49e080e7          	jalr	1182(ra) # 80004286 <end_op>
    return -1;
    80004df0:	557d                	li	a0,-1
    80004df2:	b7f9                	j	80004dc0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	c4c080e7          	jalr	-948(ra) # 80001a42 <proc_pagetable>
    80004dfe:	8b2a                	mv	s6,a0
    80004e00:	d555                	beqz	a0,80004dac <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e02:	e6842783          	lw	a5,-408(s0)
    80004e06:	e8045703          	lhu	a4,-384(s0)
    80004e0a:	c735                	beqz	a4,80004e76 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e0c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e0e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e12:	6a05                	lui	s4,0x1
    80004e14:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e18:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e1c:	6d85                	lui	s11,0x1
    80004e1e:	7d7d                	lui	s10,0xfffff
    80004e20:	ac1d                	j	80005056 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e22:	00004517          	auipc	a0,0x4
    80004e26:	99650513          	addi	a0,a0,-1642 # 800087b8 <syscalls+0x288>
    80004e2a:	ffffb097          	auipc	ra,0xffffb
    80004e2e:	700080e7          	jalr	1792(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e32:	874a                	mv	a4,s2
    80004e34:	009c86bb          	addw	a3,s9,s1
    80004e38:	4581                	li	a1,0
    80004e3a:	8556                	mv	a0,s5
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	ca8080e7          	jalr	-856(ra) # 80003ae4 <readi>
    80004e44:	2501                	sext.w	a0,a0
    80004e46:	1aa91863          	bne	s2,a0,80004ff6 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e4a:	009d84bb          	addw	s1,s11,s1
    80004e4e:	013d09bb          	addw	s3,s10,s3
    80004e52:	1f74f263          	bgeu	s1,s7,80005036 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e56:	02049593          	slli	a1,s1,0x20
    80004e5a:	9181                	srli	a1,a1,0x20
    80004e5c:	95e2                	add	a1,a1,s8
    80004e5e:	855a                	mv	a0,s6
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	1ec080e7          	jalr	492(ra) # 8000104c <walkaddr>
    80004e68:	862a                	mv	a2,a0
    if(pa == 0)
    80004e6a:	dd45                	beqz	a0,80004e22 <exec+0xfe>
      n = PGSIZE;
    80004e6c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e6e:	fd49f2e3          	bgeu	s3,s4,80004e32 <exec+0x10e>
      n = sz - i;
    80004e72:	894e                	mv	s2,s3
    80004e74:	bf7d                	j	80004e32 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e76:	4481                	li	s1,0
  iunlockput(ip);
    80004e78:	8556                	mv	a0,s5
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	c18080e7          	jalr	-1000(ra) # 80003a92 <iunlockput>
  end_op();
    80004e82:	fffff097          	auipc	ra,0xfffff
    80004e86:	404080e7          	jalr	1028(ra) # 80004286 <end_op>
  p = myproc();
    80004e8a:	ffffd097          	auipc	ra,0xffffd
    80004e8e:	af4080e7          	jalr	-1292(ra) # 8000197e <myproc>
    80004e92:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e94:	05853d03          	ld	s10,88(a0)
  sz = PGROUNDUP(sz);
    80004e98:	6785                	lui	a5,0x1
    80004e9a:	17fd                	addi	a5,a5,-1
    80004e9c:	94be                	add	s1,s1,a5
    80004e9e:	77fd                	lui	a5,0xfffff
    80004ea0:	8fe5                	and	a5,a5,s1
    80004ea2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ea6:	6609                	lui	a2,0x2
    80004ea8:	963e                	add	a2,a2,a5
    80004eaa:	85be                	mv	a1,a5
    80004eac:	855a                	mv	a0,s6
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	540080e7          	jalr	1344(ra) # 800013ee <uvmalloc>
    80004eb6:	8c2a                	mv	s8,a0
  ip = 0;
    80004eb8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eba:	12050e63          	beqz	a0,80004ff6 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ebe:	75f9                	lui	a1,0xffffe
    80004ec0:	95aa                	add	a1,a1,a0
    80004ec2:	855a                	mv	a0,s6
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	748080e7          	jalr	1864(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004ecc:	7afd                	lui	s5,0xfffff
    80004ece:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ed0:	df043783          	ld	a5,-528(s0)
    80004ed4:	6388                	ld	a0,0(a5)
    80004ed6:	c925                	beqz	a0,80004f46 <exec+0x222>
    80004ed8:	e8840993          	addi	s3,s0,-376
    80004edc:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ee0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ee2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	f5e080e7          	jalr	-162(ra) # 80000e42 <strlen>
    80004eec:	0015079b          	addiw	a5,a0,1
    80004ef0:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ef4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ef8:	13596363          	bltu	s2,s5,8000501e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004efc:	df043d83          	ld	s11,-528(s0)
    80004f00:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f04:	8552                	mv	a0,s4
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	f3c080e7          	jalr	-196(ra) # 80000e42 <strlen>
    80004f0e:	0015069b          	addiw	a3,a0,1
    80004f12:	8652                	mv	a2,s4
    80004f14:	85ca                	mv	a1,s2
    80004f16:	855a                	mv	a0,s6
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	726080e7          	jalr	1830(ra) # 8000163e <copyout>
    80004f20:	10054363          	bltz	a0,80005026 <exec+0x302>
    ustack[argc] = sp;
    80004f24:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f28:	0485                	addi	s1,s1,1
    80004f2a:	008d8793          	addi	a5,s11,8
    80004f2e:	def43823          	sd	a5,-528(s0)
    80004f32:	008db503          	ld	a0,8(s11)
    80004f36:	c911                	beqz	a0,80004f4a <exec+0x226>
    if(argc >= MAXARG)
    80004f38:	09a1                	addi	s3,s3,8
    80004f3a:	fb3c95e3          	bne	s9,s3,80004ee4 <exec+0x1c0>
  sz = sz1;
    80004f3e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f42:	4a81                	li	s5,0
    80004f44:	a84d                	j	80004ff6 <exec+0x2d2>
  sp = sz;
    80004f46:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f48:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f4a:	00349793          	slli	a5,s1,0x3
    80004f4e:	f9040713          	addi	a4,s0,-112
    80004f52:	97ba                	add	a5,a5,a4
    80004f54:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f58:	00148693          	addi	a3,s1,1
    80004f5c:	068e                	slli	a3,a3,0x3
    80004f5e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f62:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f66:	01597663          	bgeu	s2,s5,80004f72 <exec+0x24e>
  sz = sz1;
    80004f6a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f6e:	4a81                	li	s5,0
    80004f70:	a059                	j	80004ff6 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f72:	e8840613          	addi	a2,s0,-376
    80004f76:	85ca                	mv	a1,s2
    80004f78:	855a                	mv	a0,s6
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	6c4080e7          	jalr	1732(ra) # 8000163e <copyout>
    80004f82:	0a054663          	bltz	a0,8000502e <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f86:	068bb783          	ld	a5,104(s7) # 1068 <_entry-0x7fffef98>
    80004f8a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f8e:	de843783          	ld	a5,-536(s0)
    80004f92:	0007c703          	lbu	a4,0(a5)
    80004f96:	cf11                	beqz	a4,80004fb2 <exec+0x28e>
    80004f98:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f9a:	02f00693          	li	a3,47
    80004f9e:	a039                	j	80004fac <exec+0x288>
      last = s+1;
    80004fa0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fa4:	0785                	addi	a5,a5,1
    80004fa6:	fff7c703          	lbu	a4,-1(a5)
    80004faa:	c701                	beqz	a4,80004fb2 <exec+0x28e>
    if(*s == '/')
    80004fac:	fed71ce3          	bne	a4,a3,80004fa4 <exec+0x280>
    80004fb0:	bfc5                	j	80004fa0 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fb2:	4641                	li	a2,16
    80004fb4:	de843583          	ld	a1,-536(s0)
    80004fb8:	168b8513          	addi	a0,s7,360
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	e54080e7          	jalr	-428(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fc4:	060bb503          	ld	a0,96(s7)
  p->pagetable = pagetable;
    80004fc8:	076bb023          	sd	s6,96(s7)
  p->sz = sz;
    80004fcc:	058bbc23          	sd	s8,88(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fd0:	068bb783          	ld	a5,104(s7)
    80004fd4:	e6043703          	ld	a4,-416(s0)
    80004fd8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fda:	068bb783          	ld	a5,104(s7)
    80004fde:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fe2:	85ea                	mv	a1,s10
    80004fe4:	ffffd097          	auipc	ra,0xffffd
    80004fe8:	afa080e7          	jalr	-1286(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fec:	0004851b          	sext.w	a0,s1
    80004ff0:	bbc1                	j	80004dc0 <exec+0x9c>
    80004ff2:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ff6:	df843583          	ld	a1,-520(s0)
    80004ffa:	855a                	mv	a0,s6
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	ae2080e7          	jalr	-1310(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80005004:	da0a94e3          	bnez	s5,80004dac <exec+0x88>
  return -1;
    80005008:	557d                	li	a0,-1
    8000500a:	bb5d                	j	80004dc0 <exec+0x9c>
    8000500c:	de943c23          	sd	s1,-520(s0)
    80005010:	b7dd                	j	80004ff6 <exec+0x2d2>
    80005012:	de943c23          	sd	s1,-520(s0)
    80005016:	b7c5                	j	80004ff6 <exec+0x2d2>
    80005018:	de943c23          	sd	s1,-520(s0)
    8000501c:	bfe9                	j	80004ff6 <exec+0x2d2>
  sz = sz1;
    8000501e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005022:	4a81                	li	s5,0
    80005024:	bfc9                	j	80004ff6 <exec+0x2d2>
  sz = sz1;
    80005026:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000502a:	4a81                	li	s5,0
    8000502c:	b7e9                	j	80004ff6 <exec+0x2d2>
  sz = sz1;
    8000502e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005032:	4a81                	li	s5,0
    80005034:	b7c9                	j	80004ff6 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005036:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000503a:	e0843783          	ld	a5,-504(s0)
    8000503e:	0017869b          	addiw	a3,a5,1
    80005042:	e0d43423          	sd	a3,-504(s0)
    80005046:	e0043783          	ld	a5,-512(s0)
    8000504a:	0387879b          	addiw	a5,a5,56
    8000504e:	e8045703          	lhu	a4,-384(s0)
    80005052:	e2e6d3e3          	bge	a3,a4,80004e78 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005056:	2781                	sext.w	a5,a5
    80005058:	e0f43023          	sd	a5,-512(s0)
    8000505c:	03800713          	li	a4,56
    80005060:	86be                	mv	a3,a5
    80005062:	e1040613          	addi	a2,s0,-496
    80005066:	4581                	li	a1,0
    80005068:	8556                	mv	a0,s5
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	a7a080e7          	jalr	-1414(ra) # 80003ae4 <readi>
    80005072:	03800793          	li	a5,56
    80005076:	f6f51ee3          	bne	a0,a5,80004ff2 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000507a:	e1042783          	lw	a5,-496(s0)
    8000507e:	4705                	li	a4,1
    80005080:	fae79de3          	bne	a5,a4,8000503a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005084:	e3843603          	ld	a2,-456(s0)
    80005088:	e3043783          	ld	a5,-464(s0)
    8000508c:	f8f660e3          	bltu	a2,a5,8000500c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005090:	e2043783          	ld	a5,-480(s0)
    80005094:	963e                	add	a2,a2,a5
    80005096:	f6f66ee3          	bltu	a2,a5,80005012 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000509a:	85a6                	mv	a1,s1
    8000509c:	855a                	mv	a0,s6
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	350080e7          	jalr	848(ra) # 800013ee <uvmalloc>
    800050a6:	dea43c23          	sd	a0,-520(s0)
    800050aa:	d53d                	beqz	a0,80005018 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800050ac:	e2043c03          	ld	s8,-480(s0)
    800050b0:	de043783          	ld	a5,-544(s0)
    800050b4:	00fc77b3          	and	a5,s8,a5
    800050b8:	ff9d                	bnez	a5,80004ff6 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050ba:	e1842c83          	lw	s9,-488(s0)
    800050be:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050c2:	f60b8ae3          	beqz	s7,80005036 <exec+0x312>
    800050c6:	89de                	mv	s3,s7
    800050c8:	4481                	li	s1,0
    800050ca:	b371                	j	80004e56 <exec+0x132>

00000000800050cc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050cc:	7179                	addi	sp,sp,-48
    800050ce:	f406                	sd	ra,40(sp)
    800050d0:	f022                	sd	s0,32(sp)
    800050d2:	ec26                	sd	s1,24(sp)
    800050d4:	e84a                	sd	s2,16(sp)
    800050d6:	1800                	addi	s0,sp,48
    800050d8:	892e                	mv	s2,a1
    800050da:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050dc:	fdc40593          	addi	a1,s0,-36
    800050e0:	ffffe097          	auipc	ra,0xffffe
    800050e4:	aa2080e7          	jalr	-1374(ra) # 80002b82 <argint>
    800050e8:	04054063          	bltz	a0,80005128 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050ec:	fdc42703          	lw	a4,-36(s0)
    800050f0:	47bd                	li	a5,15
    800050f2:	02e7ed63          	bltu	a5,a4,8000512c <argfd+0x60>
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	888080e7          	jalr	-1912(ra) # 8000197e <myproc>
    800050fe:	fdc42703          	lw	a4,-36(s0)
    80005102:	01c70793          	addi	a5,a4,28
    80005106:	078e                	slli	a5,a5,0x3
    80005108:	953e                	add	a0,a0,a5
    8000510a:	611c                	ld	a5,0(a0)
    8000510c:	c395                	beqz	a5,80005130 <argfd+0x64>
    return -1;
  if(pfd)
    8000510e:	00090463          	beqz	s2,80005116 <argfd+0x4a>
    *pfd = fd;
    80005112:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005116:	4501                	li	a0,0
  if(pf)
    80005118:	c091                	beqz	s1,8000511c <argfd+0x50>
    *pf = f;
    8000511a:	e09c                	sd	a5,0(s1)
}
    8000511c:	70a2                	ld	ra,40(sp)
    8000511e:	7402                	ld	s0,32(sp)
    80005120:	64e2                	ld	s1,24(sp)
    80005122:	6942                	ld	s2,16(sp)
    80005124:	6145                	addi	sp,sp,48
    80005126:	8082                	ret
    return -1;
    80005128:	557d                	li	a0,-1
    8000512a:	bfcd                	j	8000511c <argfd+0x50>
    return -1;
    8000512c:	557d                	li	a0,-1
    8000512e:	b7fd                	j	8000511c <argfd+0x50>
    80005130:	557d                	li	a0,-1
    80005132:	b7ed                	j	8000511c <argfd+0x50>

0000000080005134 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005134:	1101                	addi	sp,sp,-32
    80005136:	ec06                	sd	ra,24(sp)
    80005138:	e822                	sd	s0,16(sp)
    8000513a:	e426                	sd	s1,8(sp)
    8000513c:	1000                	addi	s0,sp,32
    8000513e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	83e080e7          	jalr	-1986(ra) # 8000197e <myproc>
    80005148:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000514a:	0e050793          	addi	a5,a0,224
    8000514e:	4501                	li	a0,0
    80005150:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005152:	6398                	ld	a4,0(a5)
    80005154:	cb19                	beqz	a4,8000516a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005156:	2505                	addiw	a0,a0,1
    80005158:	07a1                	addi	a5,a5,8
    8000515a:	fed51ce3          	bne	a0,a3,80005152 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000515e:	557d                	li	a0,-1
}
    80005160:	60e2                	ld	ra,24(sp)
    80005162:	6442                	ld	s0,16(sp)
    80005164:	64a2                	ld	s1,8(sp)
    80005166:	6105                	addi	sp,sp,32
    80005168:	8082                	ret
      p->ofile[fd] = f;
    8000516a:	01c50793          	addi	a5,a0,28
    8000516e:	078e                	slli	a5,a5,0x3
    80005170:	963e                	add	a2,a2,a5
    80005172:	e204                	sd	s1,0(a2)
      return fd;
    80005174:	b7f5                	j	80005160 <fdalloc+0x2c>

0000000080005176 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005176:	715d                	addi	sp,sp,-80
    80005178:	e486                	sd	ra,72(sp)
    8000517a:	e0a2                	sd	s0,64(sp)
    8000517c:	fc26                	sd	s1,56(sp)
    8000517e:	f84a                	sd	s2,48(sp)
    80005180:	f44e                	sd	s3,40(sp)
    80005182:	f052                	sd	s4,32(sp)
    80005184:	ec56                	sd	s5,24(sp)
    80005186:	0880                	addi	s0,sp,80
    80005188:	89ae                	mv	s3,a1
    8000518a:	8ab2                	mv	s5,a2
    8000518c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000518e:	fb040593          	addi	a1,s0,-80
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	e72080e7          	jalr	-398(ra) # 80004004 <nameiparent>
    8000519a:	892a                	mv	s2,a0
    8000519c:	12050e63          	beqz	a0,800052d8 <create+0x162>
    return 0;

  ilock(dp);
    800051a0:	ffffe097          	auipc	ra,0xffffe
    800051a4:	690080e7          	jalr	1680(ra) # 80003830 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051a8:	4601                	li	a2,0
    800051aa:	fb040593          	addi	a1,s0,-80
    800051ae:	854a                	mv	a0,s2
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	b64080e7          	jalr	-1180(ra) # 80003d14 <dirlookup>
    800051b8:	84aa                	mv	s1,a0
    800051ba:	c921                	beqz	a0,8000520a <create+0x94>
    iunlockput(dp);
    800051bc:	854a                	mv	a0,s2
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	8d4080e7          	jalr	-1836(ra) # 80003a92 <iunlockput>
    ilock(ip);
    800051c6:	8526                	mv	a0,s1
    800051c8:	ffffe097          	auipc	ra,0xffffe
    800051cc:	668080e7          	jalr	1640(ra) # 80003830 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051d0:	2981                	sext.w	s3,s3
    800051d2:	4789                	li	a5,2
    800051d4:	02f99463          	bne	s3,a5,800051fc <create+0x86>
    800051d8:	0444d783          	lhu	a5,68(s1)
    800051dc:	37f9                	addiw	a5,a5,-2
    800051de:	17c2                	slli	a5,a5,0x30
    800051e0:	93c1                	srli	a5,a5,0x30
    800051e2:	4705                	li	a4,1
    800051e4:	00f76c63          	bltu	a4,a5,800051fc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051e8:	8526                	mv	a0,s1
    800051ea:	60a6                	ld	ra,72(sp)
    800051ec:	6406                	ld	s0,64(sp)
    800051ee:	74e2                	ld	s1,56(sp)
    800051f0:	7942                	ld	s2,48(sp)
    800051f2:	79a2                	ld	s3,40(sp)
    800051f4:	7a02                	ld	s4,32(sp)
    800051f6:	6ae2                	ld	s5,24(sp)
    800051f8:	6161                	addi	sp,sp,80
    800051fa:	8082                	ret
    iunlockput(ip);
    800051fc:	8526                	mv	a0,s1
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	894080e7          	jalr	-1900(ra) # 80003a92 <iunlockput>
    return 0;
    80005206:	4481                	li	s1,0
    80005208:	b7c5                	j	800051e8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000520a:	85ce                	mv	a1,s3
    8000520c:	00092503          	lw	a0,0(s2)
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	488080e7          	jalr	1160(ra) # 80003698 <ialloc>
    80005218:	84aa                	mv	s1,a0
    8000521a:	c521                	beqz	a0,80005262 <create+0xec>
  ilock(ip);
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	614080e7          	jalr	1556(ra) # 80003830 <ilock>
  ip->major = major;
    80005224:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005228:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000522c:	4a05                	li	s4,1
    8000522e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005232:	8526                	mv	a0,s1
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	532080e7          	jalr	1330(ra) # 80003766 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000523c:	2981                	sext.w	s3,s3
    8000523e:	03498a63          	beq	s3,s4,80005272 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005242:	40d0                	lw	a2,4(s1)
    80005244:	fb040593          	addi	a1,s0,-80
    80005248:	854a                	mv	a0,s2
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	cda080e7          	jalr	-806(ra) # 80003f24 <dirlink>
    80005252:	06054b63          	bltz	a0,800052c8 <create+0x152>
  iunlockput(dp);
    80005256:	854a                	mv	a0,s2
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	83a080e7          	jalr	-1990(ra) # 80003a92 <iunlockput>
  return ip;
    80005260:	b761                	j	800051e8 <create+0x72>
    panic("create: ialloc");
    80005262:	00003517          	auipc	a0,0x3
    80005266:	57650513          	addi	a0,a0,1398 # 800087d8 <syscalls+0x2a8>
    8000526a:	ffffb097          	auipc	ra,0xffffb
    8000526e:	2c0080e7          	jalr	704(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005272:	04a95783          	lhu	a5,74(s2)
    80005276:	2785                	addiw	a5,a5,1
    80005278:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000527c:	854a                	mv	a0,s2
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	4e8080e7          	jalr	1256(ra) # 80003766 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005286:	40d0                	lw	a2,4(s1)
    80005288:	00003597          	auipc	a1,0x3
    8000528c:	56058593          	addi	a1,a1,1376 # 800087e8 <syscalls+0x2b8>
    80005290:	8526                	mv	a0,s1
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	c92080e7          	jalr	-878(ra) # 80003f24 <dirlink>
    8000529a:	00054f63          	bltz	a0,800052b8 <create+0x142>
    8000529e:	00492603          	lw	a2,4(s2)
    800052a2:	00003597          	auipc	a1,0x3
    800052a6:	54e58593          	addi	a1,a1,1358 # 800087f0 <syscalls+0x2c0>
    800052aa:	8526                	mv	a0,s1
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	c78080e7          	jalr	-904(ra) # 80003f24 <dirlink>
    800052b4:	f80557e3          	bgez	a0,80005242 <create+0xcc>
      panic("create dots");
    800052b8:	00003517          	auipc	a0,0x3
    800052bc:	54050513          	addi	a0,a0,1344 # 800087f8 <syscalls+0x2c8>
    800052c0:	ffffb097          	auipc	ra,0xffffb
    800052c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    panic("create: dirlink");
    800052c8:	00003517          	auipc	a0,0x3
    800052cc:	54050513          	addi	a0,a0,1344 # 80008808 <syscalls+0x2d8>
    800052d0:	ffffb097          	auipc	ra,0xffffb
    800052d4:	25a080e7          	jalr	602(ra) # 8000052a <panic>
    return 0;
    800052d8:	84aa                	mv	s1,a0
    800052da:	b739                	j	800051e8 <create+0x72>

00000000800052dc <sys_dup>:
{
    800052dc:	7179                	addi	sp,sp,-48
    800052de:	f406                	sd	ra,40(sp)
    800052e0:	f022                	sd	s0,32(sp)
    800052e2:	ec26                	sd	s1,24(sp)
    800052e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052e6:	fd840613          	addi	a2,s0,-40
    800052ea:	4581                	li	a1,0
    800052ec:	4501                	li	a0,0
    800052ee:	00000097          	auipc	ra,0x0
    800052f2:	dde080e7          	jalr	-546(ra) # 800050cc <argfd>
    return -1;
    800052f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052f8:	02054363          	bltz	a0,8000531e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052fc:	fd843503          	ld	a0,-40(s0)
    80005300:	00000097          	auipc	ra,0x0
    80005304:	e34080e7          	jalr	-460(ra) # 80005134 <fdalloc>
    80005308:	84aa                	mv	s1,a0
    return -1;
    8000530a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000530c:	00054963          	bltz	a0,8000531e <sys_dup+0x42>
  filedup(f);
    80005310:	fd843503          	ld	a0,-40(s0)
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	36c080e7          	jalr	876(ra) # 80004680 <filedup>
  return fd;
    8000531c:	87a6                	mv	a5,s1
}
    8000531e:	853e                	mv	a0,a5
    80005320:	70a2                	ld	ra,40(sp)
    80005322:	7402                	ld	s0,32(sp)
    80005324:	64e2                	ld	s1,24(sp)
    80005326:	6145                	addi	sp,sp,48
    80005328:	8082                	ret

000000008000532a <sys_read>:
{
    8000532a:	7179                	addi	sp,sp,-48
    8000532c:	f406                	sd	ra,40(sp)
    8000532e:	f022                	sd	s0,32(sp)
    80005330:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005332:	fe840613          	addi	a2,s0,-24
    80005336:	4581                	li	a1,0
    80005338:	4501                	li	a0,0
    8000533a:	00000097          	auipc	ra,0x0
    8000533e:	d92080e7          	jalr	-622(ra) # 800050cc <argfd>
    return -1;
    80005342:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005344:	04054163          	bltz	a0,80005386 <sys_read+0x5c>
    80005348:	fe440593          	addi	a1,s0,-28
    8000534c:	4509                	li	a0,2
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	834080e7          	jalr	-1996(ra) # 80002b82 <argint>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005358:	02054763          	bltz	a0,80005386 <sys_read+0x5c>
    8000535c:	fd840593          	addi	a1,s0,-40
    80005360:	4505                	li	a0,1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	842080e7          	jalr	-1982(ra) # 80002ba4 <argaddr>
    return -1;
    8000536a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536c:	00054d63          	bltz	a0,80005386 <sys_read+0x5c>
  return fileread(f, p, n);
    80005370:	fe442603          	lw	a2,-28(s0)
    80005374:	fd843583          	ld	a1,-40(s0)
    80005378:	fe843503          	ld	a0,-24(s0)
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	490080e7          	jalr	1168(ra) # 8000480c <fileread>
    80005384:	87aa                	mv	a5,a0
}
    80005386:	853e                	mv	a0,a5
    80005388:	70a2                	ld	ra,40(sp)
    8000538a:	7402                	ld	s0,32(sp)
    8000538c:	6145                	addi	sp,sp,48
    8000538e:	8082                	ret

0000000080005390 <sys_write>:
{
    80005390:	7179                	addi	sp,sp,-48
    80005392:	f406                	sd	ra,40(sp)
    80005394:	f022                	sd	s0,32(sp)
    80005396:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005398:	fe840613          	addi	a2,s0,-24
    8000539c:	4581                	li	a1,0
    8000539e:	4501                	li	a0,0
    800053a0:	00000097          	auipc	ra,0x0
    800053a4:	d2c080e7          	jalr	-724(ra) # 800050cc <argfd>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053aa:	04054163          	bltz	a0,800053ec <sys_write+0x5c>
    800053ae:	fe440593          	addi	a1,s0,-28
    800053b2:	4509                	li	a0,2
    800053b4:	ffffd097          	auipc	ra,0xffffd
    800053b8:	7ce080e7          	jalr	1998(ra) # 80002b82 <argint>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053be:	02054763          	bltz	a0,800053ec <sys_write+0x5c>
    800053c2:	fd840593          	addi	a1,s0,-40
    800053c6:	4505                	li	a0,1
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	7dc080e7          	jalr	2012(ra) # 80002ba4 <argaddr>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	00054d63          	bltz	a0,800053ec <sys_write+0x5c>
  return filewrite(f, p, n);
    800053d6:	fe442603          	lw	a2,-28(s0)
    800053da:	fd843583          	ld	a1,-40(s0)
    800053de:	fe843503          	ld	a0,-24(s0)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	4ec080e7          	jalr	1260(ra) # 800048ce <filewrite>
    800053ea:	87aa                	mv	a5,a0
}
    800053ec:	853e                	mv	a0,a5
    800053ee:	70a2                	ld	ra,40(sp)
    800053f0:	7402                	ld	s0,32(sp)
    800053f2:	6145                	addi	sp,sp,48
    800053f4:	8082                	ret

00000000800053f6 <sys_close>:
{
    800053f6:	1101                	addi	sp,sp,-32
    800053f8:	ec06                	sd	ra,24(sp)
    800053fa:	e822                	sd	s0,16(sp)
    800053fc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053fe:	fe040613          	addi	a2,s0,-32
    80005402:	fec40593          	addi	a1,s0,-20
    80005406:	4501                	li	a0,0
    80005408:	00000097          	auipc	ra,0x0
    8000540c:	cc4080e7          	jalr	-828(ra) # 800050cc <argfd>
    return -1;
    80005410:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005412:	02054463          	bltz	a0,8000543a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	568080e7          	jalr	1384(ra) # 8000197e <myproc>
    8000541e:	fec42783          	lw	a5,-20(s0)
    80005422:	07f1                	addi	a5,a5,28
    80005424:	078e                	slli	a5,a5,0x3
    80005426:	97aa                	add	a5,a5,a0
    80005428:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000542c:	fe043503          	ld	a0,-32(s0)
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	2a2080e7          	jalr	674(ra) # 800046d2 <fileclose>
  return 0;
    80005438:	4781                	li	a5,0
}
    8000543a:	853e                	mv	a0,a5
    8000543c:	60e2                	ld	ra,24(sp)
    8000543e:	6442                	ld	s0,16(sp)
    80005440:	6105                	addi	sp,sp,32
    80005442:	8082                	ret

0000000080005444 <sys_fstat>:
{
    80005444:	1101                	addi	sp,sp,-32
    80005446:	ec06                	sd	ra,24(sp)
    80005448:	e822                	sd	s0,16(sp)
    8000544a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000544c:	fe840613          	addi	a2,s0,-24
    80005450:	4581                	li	a1,0
    80005452:	4501                	li	a0,0
    80005454:	00000097          	auipc	ra,0x0
    80005458:	c78080e7          	jalr	-904(ra) # 800050cc <argfd>
    return -1;
    8000545c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545e:	02054563          	bltz	a0,80005488 <sys_fstat+0x44>
    80005462:	fe040593          	addi	a1,s0,-32
    80005466:	4505                	li	a0,1
    80005468:	ffffd097          	auipc	ra,0xffffd
    8000546c:	73c080e7          	jalr	1852(ra) # 80002ba4 <argaddr>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005472:	00054b63          	bltz	a0,80005488 <sys_fstat+0x44>
  return filestat(f, st);
    80005476:	fe043583          	ld	a1,-32(s0)
    8000547a:	fe843503          	ld	a0,-24(s0)
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	31c080e7          	jalr	796(ra) # 8000479a <filestat>
    80005486:	87aa                	mv	a5,a0
}
    80005488:	853e                	mv	a0,a5
    8000548a:	60e2                	ld	ra,24(sp)
    8000548c:	6442                	ld	s0,16(sp)
    8000548e:	6105                	addi	sp,sp,32
    80005490:	8082                	ret

0000000080005492 <sys_link>:
{
    80005492:	7169                	addi	sp,sp,-304
    80005494:	f606                	sd	ra,296(sp)
    80005496:	f222                	sd	s0,288(sp)
    80005498:	ee26                	sd	s1,280(sp)
    8000549a:	ea4a                	sd	s2,272(sp)
    8000549c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549e:	08000613          	li	a2,128
    800054a2:	ed040593          	addi	a1,s0,-304
    800054a6:	4501                	li	a0,0
    800054a8:	ffffd097          	auipc	ra,0xffffd
    800054ac:	71e080e7          	jalr	1822(ra) # 80002bc6 <argstr>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b2:	10054e63          	bltz	a0,800055ce <sys_link+0x13c>
    800054b6:	08000613          	li	a2,128
    800054ba:	f5040593          	addi	a1,s0,-176
    800054be:	4505                	li	a0,1
    800054c0:	ffffd097          	auipc	ra,0xffffd
    800054c4:	706080e7          	jalr	1798(ra) # 80002bc6 <argstr>
    return -1;
    800054c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ca:	10054263          	bltz	a0,800055ce <sys_link+0x13c>
  begin_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	d38080e7          	jalr	-712(ra) # 80004206 <begin_op>
  if((ip = namei(old)) == 0){
    800054d6:	ed040513          	addi	a0,s0,-304
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	b0c080e7          	jalr	-1268(ra) # 80003fe6 <namei>
    800054e2:	84aa                	mv	s1,a0
    800054e4:	c551                	beqz	a0,80005570 <sys_link+0xde>
  ilock(ip);
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	34a080e7          	jalr	842(ra) # 80003830 <ilock>
  if(ip->type == T_DIR){
    800054ee:	04449703          	lh	a4,68(s1)
    800054f2:	4785                	li	a5,1
    800054f4:	08f70463          	beq	a4,a5,8000557c <sys_link+0xea>
  ip->nlink++;
    800054f8:	04a4d783          	lhu	a5,74(s1)
    800054fc:	2785                	addiw	a5,a5,1
    800054fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	262080e7          	jalr	610(ra) # 80003766 <iupdate>
  iunlock(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	3e4080e7          	jalr	996(ra) # 800038f2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005516:	fd040593          	addi	a1,s0,-48
    8000551a:	f5040513          	addi	a0,s0,-176
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	ae6080e7          	jalr	-1306(ra) # 80004004 <nameiparent>
    80005526:	892a                	mv	s2,a0
    80005528:	c935                	beqz	a0,8000559c <sys_link+0x10a>
  ilock(dp);
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	306080e7          	jalr	774(ra) # 80003830 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005532:	00092703          	lw	a4,0(s2)
    80005536:	409c                	lw	a5,0(s1)
    80005538:	04f71d63          	bne	a4,a5,80005592 <sys_link+0x100>
    8000553c:	40d0                	lw	a2,4(s1)
    8000553e:	fd040593          	addi	a1,s0,-48
    80005542:	854a                	mv	a0,s2
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	9e0080e7          	jalr	-1568(ra) # 80003f24 <dirlink>
    8000554c:	04054363          	bltz	a0,80005592 <sys_link+0x100>
  iunlockput(dp);
    80005550:	854a                	mv	a0,s2
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	540080e7          	jalr	1344(ra) # 80003a92 <iunlockput>
  iput(ip);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	48e080e7          	jalr	1166(ra) # 800039ea <iput>
  end_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	d22080e7          	jalr	-734(ra) # 80004286 <end_op>
  return 0;
    8000556c:	4781                	li	a5,0
    8000556e:	a085                	j	800055ce <sys_link+0x13c>
    end_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	d16080e7          	jalr	-746(ra) # 80004286 <end_op>
    return -1;
    80005578:	57fd                	li	a5,-1
    8000557a:	a891                	j	800055ce <sys_link+0x13c>
    iunlockput(ip);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	514080e7          	jalr	1300(ra) # 80003a92 <iunlockput>
    end_op();
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	d00080e7          	jalr	-768(ra) # 80004286 <end_op>
    return -1;
    8000558e:	57fd                	li	a5,-1
    80005590:	a83d                	j	800055ce <sys_link+0x13c>
    iunlockput(dp);
    80005592:	854a                	mv	a0,s2
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	4fe080e7          	jalr	1278(ra) # 80003a92 <iunlockput>
  ilock(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	292080e7          	jalr	658(ra) # 80003830 <ilock>
  ip->nlink--;
    800055a6:	04a4d783          	lhu	a5,74(s1)
    800055aa:	37fd                	addiw	a5,a5,-1
    800055ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	1b4080e7          	jalr	436(ra) # 80003766 <iupdate>
  iunlockput(ip);
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	4d6080e7          	jalr	1238(ra) # 80003a92 <iunlockput>
  end_op();
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	cc2080e7          	jalr	-830(ra) # 80004286 <end_op>
  return -1;
    800055cc:	57fd                	li	a5,-1
}
    800055ce:	853e                	mv	a0,a5
    800055d0:	70b2                	ld	ra,296(sp)
    800055d2:	7412                	ld	s0,288(sp)
    800055d4:	64f2                	ld	s1,280(sp)
    800055d6:	6952                	ld	s2,272(sp)
    800055d8:	6155                	addi	sp,sp,304
    800055da:	8082                	ret

00000000800055dc <sys_unlink>:
{
    800055dc:	7151                	addi	sp,sp,-240
    800055de:	f586                	sd	ra,232(sp)
    800055e0:	f1a2                	sd	s0,224(sp)
    800055e2:	eda6                	sd	s1,216(sp)
    800055e4:	e9ca                	sd	s2,208(sp)
    800055e6:	e5ce                	sd	s3,200(sp)
    800055e8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055ea:	08000613          	li	a2,128
    800055ee:	f3040593          	addi	a1,s0,-208
    800055f2:	4501                	li	a0,0
    800055f4:	ffffd097          	auipc	ra,0xffffd
    800055f8:	5d2080e7          	jalr	1490(ra) # 80002bc6 <argstr>
    800055fc:	18054163          	bltz	a0,8000577e <sys_unlink+0x1a2>
  begin_op();
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	c06080e7          	jalr	-1018(ra) # 80004206 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005608:	fb040593          	addi	a1,s0,-80
    8000560c:	f3040513          	addi	a0,s0,-208
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	9f4080e7          	jalr	-1548(ra) # 80004004 <nameiparent>
    80005618:	84aa                	mv	s1,a0
    8000561a:	c979                	beqz	a0,800056f0 <sys_unlink+0x114>
  ilock(dp);
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	214080e7          	jalr	532(ra) # 80003830 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005624:	00003597          	auipc	a1,0x3
    80005628:	1c458593          	addi	a1,a1,452 # 800087e8 <syscalls+0x2b8>
    8000562c:	fb040513          	addi	a0,s0,-80
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	6ca080e7          	jalr	1738(ra) # 80003cfa <namecmp>
    80005638:	14050a63          	beqz	a0,8000578c <sys_unlink+0x1b0>
    8000563c:	00003597          	auipc	a1,0x3
    80005640:	1b458593          	addi	a1,a1,436 # 800087f0 <syscalls+0x2c0>
    80005644:	fb040513          	addi	a0,s0,-80
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	6b2080e7          	jalr	1714(ra) # 80003cfa <namecmp>
    80005650:	12050e63          	beqz	a0,8000578c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005654:	f2c40613          	addi	a2,s0,-212
    80005658:	fb040593          	addi	a1,s0,-80
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	6b6080e7          	jalr	1718(ra) # 80003d14 <dirlookup>
    80005666:	892a                	mv	s2,a0
    80005668:	12050263          	beqz	a0,8000578c <sys_unlink+0x1b0>
  ilock(ip);
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	1c4080e7          	jalr	452(ra) # 80003830 <ilock>
  if(ip->nlink < 1)
    80005674:	04a91783          	lh	a5,74(s2)
    80005678:	08f05263          	blez	a5,800056fc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000567c:	04491703          	lh	a4,68(s2)
    80005680:	4785                	li	a5,1
    80005682:	08f70563          	beq	a4,a5,8000570c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005686:	4641                	li	a2,16
    80005688:	4581                	li	a1,0
    8000568a:	fc040513          	addi	a0,s0,-64
    8000568e:	ffffb097          	auipc	ra,0xffffb
    80005692:	630080e7          	jalr	1584(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005696:	4741                	li	a4,16
    80005698:	f2c42683          	lw	a3,-212(s0)
    8000569c:	fc040613          	addi	a2,s0,-64
    800056a0:	4581                	li	a1,0
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	538080e7          	jalr	1336(ra) # 80003bdc <writei>
    800056ac:	47c1                	li	a5,16
    800056ae:	0af51563          	bne	a0,a5,80005758 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056b2:	04491703          	lh	a4,68(s2)
    800056b6:	4785                	li	a5,1
    800056b8:	0af70863          	beq	a4,a5,80005768 <sys_unlink+0x18c>
  iunlockput(dp);
    800056bc:	8526                	mv	a0,s1
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	3d4080e7          	jalr	980(ra) # 80003a92 <iunlockput>
  ip->nlink--;
    800056c6:	04a95783          	lhu	a5,74(s2)
    800056ca:	37fd                	addiw	a5,a5,-1
    800056cc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056d0:	854a                	mv	a0,s2
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	094080e7          	jalr	148(ra) # 80003766 <iupdate>
  iunlockput(ip);
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	3b6080e7          	jalr	950(ra) # 80003a92 <iunlockput>
  end_op();
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	ba2080e7          	jalr	-1118(ra) # 80004286 <end_op>
  return 0;
    800056ec:	4501                	li	a0,0
    800056ee:	a84d                	j	800057a0 <sys_unlink+0x1c4>
    end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	b96080e7          	jalr	-1130(ra) # 80004286 <end_op>
    return -1;
    800056f8:	557d                	li	a0,-1
    800056fa:	a05d                	j	800057a0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056fc:	00003517          	auipc	a0,0x3
    80005700:	11c50513          	addi	a0,a0,284 # 80008818 <syscalls+0x2e8>
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	e26080e7          	jalr	-474(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000570c:	04c92703          	lw	a4,76(s2)
    80005710:	02000793          	li	a5,32
    80005714:	f6e7f9e3          	bgeu	a5,a4,80005686 <sys_unlink+0xaa>
    80005718:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000571c:	4741                	li	a4,16
    8000571e:	86ce                	mv	a3,s3
    80005720:	f1840613          	addi	a2,s0,-232
    80005724:	4581                	li	a1,0
    80005726:	854a                	mv	a0,s2
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	3bc080e7          	jalr	956(ra) # 80003ae4 <readi>
    80005730:	47c1                	li	a5,16
    80005732:	00f51b63          	bne	a0,a5,80005748 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005736:	f1845783          	lhu	a5,-232(s0)
    8000573a:	e7a1                	bnez	a5,80005782 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000573c:	29c1                	addiw	s3,s3,16
    8000573e:	04c92783          	lw	a5,76(s2)
    80005742:	fcf9ede3          	bltu	s3,a5,8000571c <sys_unlink+0x140>
    80005746:	b781                	j	80005686 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005748:	00003517          	auipc	a0,0x3
    8000574c:	0e850513          	addi	a0,a0,232 # 80008830 <syscalls+0x300>
    80005750:	ffffb097          	auipc	ra,0xffffb
    80005754:	dda080e7          	jalr	-550(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005758:	00003517          	auipc	a0,0x3
    8000575c:	0f050513          	addi	a0,a0,240 # 80008848 <syscalls+0x318>
    80005760:	ffffb097          	auipc	ra,0xffffb
    80005764:	dca080e7          	jalr	-566(ra) # 8000052a <panic>
    dp->nlink--;
    80005768:	04a4d783          	lhu	a5,74(s1)
    8000576c:	37fd                	addiw	a5,a5,-1
    8000576e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	ff2080e7          	jalr	-14(ra) # 80003766 <iupdate>
    8000577c:	b781                	j	800056bc <sys_unlink+0xe0>
    return -1;
    8000577e:	557d                	li	a0,-1
    80005780:	a005                	j	800057a0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005782:	854a                	mv	a0,s2
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	30e080e7          	jalr	782(ra) # 80003a92 <iunlockput>
  iunlockput(dp);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	304080e7          	jalr	772(ra) # 80003a92 <iunlockput>
  end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	af0080e7          	jalr	-1296(ra) # 80004286 <end_op>
  return -1;
    8000579e:	557d                	li	a0,-1
}
    800057a0:	70ae                	ld	ra,232(sp)
    800057a2:	740e                	ld	s0,224(sp)
    800057a4:	64ee                	ld	s1,216(sp)
    800057a6:	694e                	ld	s2,208(sp)
    800057a8:	69ae                	ld	s3,200(sp)
    800057aa:	616d                	addi	sp,sp,240
    800057ac:	8082                	ret

00000000800057ae <sys_open>:

uint64
sys_open(void)
{
    800057ae:	7131                	addi	sp,sp,-192
    800057b0:	fd06                	sd	ra,184(sp)
    800057b2:	f922                	sd	s0,176(sp)
    800057b4:	f526                	sd	s1,168(sp)
    800057b6:	f14a                	sd	s2,160(sp)
    800057b8:	ed4e                	sd	s3,152(sp)
    800057ba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057bc:	08000613          	li	a2,128
    800057c0:	f5040593          	addi	a1,s0,-176
    800057c4:	4501                	li	a0,0
    800057c6:	ffffd097          	auipc	ra,0xffffd
    800057ca:	400080e7          	jalr	1024(ra) # 80002bc6 <argstr>
    return -1;
    800057ce:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057d0:	0c054163          	bltz	a0,80005892 <sys_open+0xe4>
    800057d4:	f4c40593          	addi	a1,s0,-180
    800057d8:	4505                	li	a0,1
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	3a8080e7          	jalr	936(ra) # 80002b82 <argint>
    800057e2:	0a054863          	bltz	a0,80005892 <sys_open+0xe4>

  begin_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	a20080e7          	jalr	-1504(ra) # 80004206 <begin_op>

  if(omode & O_CREATE){
    800057ee:	f4c42783          	lw	a5,-180(s0)
    800057f2:	2007f793          	andi	a5,a5,512
    800057f6:	cbdd                	beqz	a5,800058ac <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057f8:	4681                	li	a3,0
    800057fa:	4601                	li	a2,0
    800057fc:	4589                	li	a1,2
    800057fe:	f5040513          	addi	a0,s0,-176
    80005802:	00000097          	auipc	ra,0x0
    80005806:	974080e7          	jalr	-1676(ra) # 80005176 <create>
    8000580a:	892a                	mv	s2,a0
    if(ip == 0){
    8000580c:	c959                	beqz	a0,800058a2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000580e:	04491703          	lh	a4,68(s2)
    80005812:	478d                	li	a5,3
    80005814:	00f71763          	bne	a4,a5,80005822 <sys_open+0x74>
    80005818:	04695703          	lhu	a4,70(s2)
    8000581c:	47a5                	li	a5,9
    8000581e:	0ce7ec63          	bltu	a5,a4,800058f6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	df4080e7          	jalr	-524(ra) # 80004616 <filealloc>
    8000582a:	89aa                	mv	s3,a0
    8000582c:	10050263          	beqz	a0,80005930 <sys_open+0x182>
    80005830:	00000097          	auipc	ra,0x0
    80005834:	904080e7          	jalr	-1788(ra) # 80005134 <fdalloc>
    80005838:	84aa                	mv	s1,a0
    8000583a:	0e054663          	bltz	a0,80005926 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000583e:	04491703          	lh	a4,68(s2)
    80005842:	478d                	li	a5,3
    80005844:	0cf70463          	beq	a4,a5,8000590c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005848:	4789                	li	a5,2
    8000584a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000584e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005852:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005856:	f4c42783          	lw	a5,-180(s0)
    8000585a:	0017c713          	xori	a4,a5,1
    8000585e:	8b05                	andi	a4,a4,1
    80005860:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005864:	0037f713          	andi	a4,a5,3
    80005868:	00e03733          	snez	a4,a4
    8000586c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005870:	4007f793          	andi	a5,a5,1024
    80005874:	c791                	beqz	a5,80005880 <sys_open+0xd2>
    80005876:	04491703          	lh	a4,68(s2)
    8000587a:	4789                	li	a5,2
    8000587c:	08f70f63          	beq	a4,a5,8000591a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	070080e7          	jalr	112(ra) # 800038f2 <iunlock>
  end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	9fc080e7          	jalr	-1540(ra) # 80004286 <end_op>

  return fd;
}
    80005892:	8526                	mv	a0,s1
    80005894:	70ea                	ld	ra,184(sp)
    80005896:	744a                	ld	s0,176(sp)
    80005898:	74aa                	ld	s1,168(sp)
    8000589a:	790a                	ld	s2,160(sp)
    8000589c:	69ea                	ld	s3,152(sp)
    8000589e:	6129                	addi	sp,sp,192
    800058a0:	8082                	ret
      end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	9e4080e7          	jalr	-1564(ra) # 80004286 <end_op>
      return -1;
    800058aa:	b7e5                	j	80005892 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058ac:	f5040513          	addi	a0,s0,-176
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	736080e7          	jalr	1846(ra) # 80003fe6 <namei>
    800058b8:	892a                	mv	s2,a0
    800058ba:	c905                	beqz	a0,800058ea <sys_open+0x13c>
    ilock(ip);
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	f74080e7          	jalr	-140(ra) # 80003830 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058c4:	04491703          	lh	a4,68(s2)
    800058c8:	4785                	li	a5,1
    800058ca:	f4f712e3          	bne	a4,a5,8000580e <sys_open+0x60>
    800058ce:	f4c42783          	lw	a5,-180(s0)
    800058d2:	dba1                	beqz	a5,80005822 <sys_open+0x74>
      iunlockput(ip);
    800058d4:	854a                	mv	a0,s2
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	1bc080e7          	jalr	444(ra) # 80003a92 <iunlockput>
      end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	9a8080e7          	jalr	-1624(ra) # 80004286 <end_op>
      return -1;
    800058e6:	54fd                	li	s1,-1
    800058e8:	b76d                	j	80005892 <sys_open+0xe4>
      end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	99c080e7          	jalr	-1636(ra) # 80004286 <end_op>
      return -1;
    800058f2:	54fd                	li	s1,-1
    800058f4:	bf79                	j	80005892 <sys_open+0xe4>
    iunlockput(ip);
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	19a080e7          	jalr	410(ra) # 80003a92 <iunlockput>
    end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	986080e7          	jalr	-1658(ra) # 80004286 <end_op>
    return -1;
    80005908:	54fd                	li	s1,-1
    8000590a:	b761                	j	80005892 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000590c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005910:	04691783          	lh	a5,70(s2)
    80005914:	02f99223          	sh	a5,36(s3)
    80005918:	bf2d                	j	80005852 <sys_open+0xa4>
    itrunc(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	022080e7          	jalr	34(ra) # 8000393e <itrunc>
    80005924:	bfb1                	j	80005880 <sys_open+0xd2>
      fileclose(f);
    80005926:	854e                	mv	a0,s3
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	daa080e7          	jalr	-598(ra) # 800046d2 <fileclose>
    iunlockput(ip);
    80005930:	854a                	mv	a0,s2
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	160080e7          	jalr	352(ra) # 80003a92 <iunlockput>
    end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	94c080e7          	jalr	-1716(ra) # 80004286 <end_op>
    return -1;
    80005942:	54fd                	li	s1,-1
    80005944:	b7b9                	j	80005892 <sys_open+0xe4>

0000000080005946 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005946:	7175                	addi	sp,sp,-144
    80005948:	e506                	sd	ra,136(sp)
    8000594a:	e122                	sd	s0,128(sp)
    8000594c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	8b8080e7          	jalr	-1864(ra) # 80004206 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005956:	08000613          	li	a2,128
    8000595a:	f7040593          	addi	a1,s0,-144
    8000595e:	4501                	li	a0,0
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	266080e7          	jalr	614(ra) # 80002bc6 <argstr>
    80005968:	02054963          	bltz	a0,8000599a <sys_mkdir+0x54>
    8000596c:	4681                	li	a3,0
    8000596e:	4601                	li	a2,0
    80005970:	4585                	li	a1,1
    80005972:	f7040513          	addi	a0,s0,-144
    80005976:	00000097          	auipc	ra,0x0
    8000597a:	800080e7          	jalr	-2048(ra) # 80005176 <create>
    8000597e:	cd11                	beqz	a0,8000599a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	112080e7          	jalr	274(ra) # 80003a92 <iunlockput>
  end_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	8fe080e7          	jalr	-1794(ra) # 80004286 <end_op>
  return 0;
    80005990:	4501                	li	a0,0
}
    80005992:	60aa                	ld	ra,136(sp)
    80005994:	640a                	ld	s0,128(sp)
    80005996:	6149                	addi	sp,sp,144
    80005998:	8082                	ret
    end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	8ec080e7          	jalr	-1812(ra) # 80004286 <end_op>
    return -1;
    800059a2:	557d                	li	a0,-1
    800059a4:	b7fd                	j	80005992 <sys_mkdir+0x4c>

00000000800059a6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059a6:	7135                	addi	sp,sp,-160
    800059a8:	ed06                	sd	ra,152(sp)
    800059aa:	e922                	sd	s0,144(sp)
    800059ac:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	858080e7          	jalr	-1960(ra) # 80004206 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b6:	08000613          	li	a2,128
    800059ba:	f7040593          	addi	a1,s0,-144
    800059be:	4501                	li	a0,0
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	206080e7          	jalr	518(ra) # 80002bc6 <argstr>
    800059c8:	04054a63          	bltz	a0,80005a1c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059cc:	f6c40593          	addi	a1,s0,-148
    800059d0:	4505                	li	a0,1
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	1b0080e7          	jalr	432(ra) # 80002b82 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059da:	04054163          	bltz	a0,80005a1c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059de:	f6840593          	addi	a1,s0,-152
    800059e2:	4509                	li	a0,2
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	19e080e7          	jalr	414(ra) # 80002b82 <argint>
     argint(1, &major) < 0 ||
    800059ec:	02054863          	bltz	a0,80005a1c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059f0:	f6841683          	lh	a3,-152(s0)
    800059f4:	f6c41603          	lh	a2,-148(s0)
    800059f8:	458d                	li	a1,3
    800059fa:	f7040513          	addi	a0,s0,-144
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	778080e7          	jalr	1912(ra) # 80005176 <create>
     argint(2, &minor) < 0 ||
    80005a06:	c919                	beqz	a0,80005a1c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	08a080e7          	jalr	138(ra) # 80003a92 <iunlockput>
  end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	876080e7          	jalr	-1930(ra) # 80004286 <end_op>
  return 0;
    80005a18:	4501                	li	a0,0
    80005a1a:	a031                	j	80005a26 <sys_mknod+0x80>
    end_op();
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	86a080e7          	jalr	-1942(ra) # 80004286 <end_op>
    return -1;
    80005a24:	557d                	li	a0,-1
}
    80005a26:	60ea                	ld	ra,152(sp)
    80005a28:	644a                	ld	s0,144(sp)
    80005a2a:	610d                	addi	sp,sp,160
    80005a2c:	8082                	ret

0000000080005a2e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a2e:	7135                	addi	sp,sp,-160
    80005a30:	ed06                	sd	ra,152(sp)
    80005a32:	e922                	sd	s0,144(sp)
    80005a34:	e526                	sd	s1,136(sp)
    80005a36:	e14a                	sd	s2,128(sp)
    80005a38:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a3a:	ffffc097          	auipc	ra,0xffffc
    80005a3e:	f44080e7          	jalr	-188(ra) # 8000197e <myproc>
    80005a42:	892a                	mv	s2,a0
  
  begin_op();
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	7c2080e7          	jalr	1986(ra) # 80004206 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a4c:	08000613          	li	a2,128
    80005a50:	f6040593          	addi	a1,s0,-160
    80005a54:	4501                	li	a0,0
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	170080e7          	jalr	368(ra) # 80002bc6 <argstr>
    80005a5e:	04054b63          	bltz	a0,80005ab4 <sys_chdir+0x86>
    80005a62:	f6040513          	addi	a0,s0,-160
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	580080e7          	jalr	1408(ra) # 80003fe6 <namei>
    80005a6e:	84aa                	mv	s1,a0
    80005a70:	c131                	beqz	a0,80005ab4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	dbe080e7          	jalr	-578(ra) # 80003830 <ilock>
  if(ip->type != T_DIR){
    80005a7a:	04449703          	lh	a4,68(s1)
    80005a7e:	4785                	li	a5,1
    80005a80:	04f71063          	bne	a4,a5,80005ac0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a84:	8526                	mv	a0,s1
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	e6c080e7          	jalr	-404(ra) # 800038f2 <iunlock>
  iput(p->cwd);
    80005a8e:	16093503          	ld	a0,352(s2)
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	f58080e7          	jalr	-168(ra) # 800039ea <iput>
  end_op();
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	7ec080e7          	jalr	2028(ra) # 80004286 <end_op>
  p->cwd = ip;
    80005aa2:	16993023          	sd	s1,352(s2)
  return 0;
    80005aa6:	4501                	li	a0,0
}
    80005aa8:	60ea                	ld	ra,152(sp)
    80005aaa:	644a                	ld	s0,144(sp)
    80005aac:	64aa                	ld	s1,136(sp)
    80005aae:	690a                	ld	s2,128(sp)
    80005ab0:	610d                	addi	sp,sp,160
    80005ab2:	8082                	ret
    end_op();
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	7d2080e7          	jalr	2002(ra) # 80004286 <end_op>
    return -1;
    80005abc:	557d                	li	a0,-1
    80005abe:	b7ed                	j	80005aa8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ac0:	8526                	mv	a0,s1
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	fd0080e7          	jalr	-48(ra) # 80003a92 <iunlockput>
    end_op();
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	7bc080e7          	jalr	1980(ra) # 80004286 <end_op>
    return -1;
    80005ad2:	557d                	li	a0,-1
    80005ad4:	bfd1                	j	80005aa8 <sys_chdir+0x7a>

0000000080005ad6 <sys_exec>:

uint64
sys_exec(void)
{
    80005ad6:	7145                	addi	sp,sp,-464
    80005ad8:	e786                	sd	ra,456(sp)
    80005ada:	e3a2                	sd	s0,448(sp)
    80005adc:	ff26                	sd	s1,440(sp)
    80005ade:	fb4a                	sd	s2,432(sp)
    80005ae0:	f74e                	sd	s3,424(sp)
    80005ae2:	f352                	sd	s4,416(sp)
    80005ae4:	ef56                	sd	s5,408(sp)
    80005ae6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ae8:	08000613          	li	a2,128
    80005aec:	f4040593          	addi	a1,s0,-192
    80005af0:	4501                	li	a0,0
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	0d4080e7          	jalr	212(ra) # 80002bc6 <argstr>
    return -1;
    80005afa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005afc:	0c054a63          	bltz	a0,80005bd0 <sys_exec+0xfa>
    80005b00:	e3840593          	addi	a1,s0,-456
    80005b04:	4505                	li	a0,1
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	09e080e7          	jalr	158(ra) # 80002ba4 <argaddr>
    80005b0e:	0c054163          	bltz	a0,80005bd0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b12:	10000613          	li	a2,256
    80005b16:	4581                	li	a1,0
    80005b18:	e4040513          	addi	a0,s0,-448
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	1a2080e7          	jalr	418(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b24:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b28:	89a6                	mv	s3,s1
    80005b2a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b2c:	02000a13          	li	s4,32
    80005b30:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b34:	00391793          	slli	a5,s2,0x3
    80005b38:	e3040593          	addi	a1,s0,-464
    80005b3c:	e3843503          	ld	a0,-456(s0)
    80005b40:	953e                	add	a0,a0,a5
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	fa6080e7          	jalr	-90(ra) # 80002ae8 <fetchaddr>
    80005b4a:	02054a63          	bltz	a0,80005b7e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b4e:	e3043783          	ld	a5,-464(s0)
    80005b52:	c3b9                	beqz	a5,80005b98 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b54:	ffffb097          	auipc	ra,0xffffb
    80005b58:	f7e080e7          	jalr	-130(ra) # 80000ad2 <kalloc>
    80005b5c:	85aa                	mv	a1,a0
    80005b5e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b62:	cd11                	beqz	a0,80005b7e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b64:	6605                	lui	a2,0x1
    80005b66:	e3043503          	ld	a0,-464(s0)
    80005b6a:	ffffd097          	auipc	ra,0xffffd
    80005b6e:	fd0080e7          	jalr	-48(ra) # 80002b3a <fetchstr>
    80005b72:	00054663          	bltz	a0,80005b7e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b76:	0905                	addi	s2,s2,1
    80005b78:	09a1                	addi	s3,s3,8
    80005b7a:	fb491be3          	bne	s2,s4,80005b30 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b7e:	10048913          	addi	s2,s1,256
    80005b82:	6088                	ld	a0,0(s1)
    80005b84:	c529                	beqz	a0,80005bce <sys_exec+0xf8>
    kfree(argv[i]);
    80005b86:	ffffb097          	auipc	ra,0xffffb
    80005b8a:	e50080e7          	jalr	-432(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8e:	04a1                	addi	s1,s1,8
    80005b90:	ff2499e3          	bne	s1,s2,80005b82 <sys_exec+0xac>
  return -1;
    80005b94:	597d                	li	s2,-1
    80005b96:	a82d                	j	80005bd0 <sys_exec+0xfa>
      argv[i] = 0;
    80005b98:	0a8e                	slli	s5,s5,0x3
    80005b9a:	fc040793          	addi	a5,s0,-64
    80005b9e:	9abe                	add	s5,s5,a5
    80005ba0:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005ba4:	e4040593          	addi	a1,s0,-448
    80005ba8:	f4040513          	addi	a0,s0,-192
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	178080e7          	jalr	376(ra) # 80004d24 <exec>
    80005bb4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb6:	10048993          	addi	s3,s1,256
    80005bba:	6088                	ld	a0,0(s1)
    80005bbc:	c911                	beqz	a0,80005bd0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	e18080e7          	jalr	-488(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc6:	04a1                	addi	s1,s1,8
    80005bc8:	ff3499e3          	bne	s1,s3,80005bba <sys_exec+0xe4>
    80005bcc:	a011                	j	80005bd0 <sys_exec+0xfa>
  return -1;
    80005bce:	597d                	li	s2,-1
}
    80005bd0:	854a                	mv	a0,s2
    80005bd2:	60be                	ld	ra,456(sp)
    80005bd4:	641e                	ld	s0,448(sp)
    80005bd6:	74fa                	ld	s1,440(sp)
    80005bd8:	795a                	ld	s2,432(sp)
    80005bda:	79ba                	ld	s3,424(sp)
    80005bdc:	7a1a                	ld	s4,416(sp)
    80005bde:	6afa                	ld	s5,408(sp)
    80005be0:	6179                	addi	sp,sp,464
    80005be2:	8082                	ret

0000000080005be4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005be4:	7139                	addi	sp,sp,-64
    80005be6:	fc06                	sd	ra,56(sp)
    80005be8:	f822                	sd	s0,48(sp)
    80005bea:	f426                	sd	s1,40(sp)
    80005bec:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bee:	ffffc097          	auipc	ra,0xffffc
    80005bf2:	d90080e7          	jalr	-624(ra) # 8000197e <myproc>
    80005bf6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bf8:	fd840593          	addi	a1,s0,-40
    80005bfc:	4501                	li	a0,0
    80005bfe:	ffffd097          	auipc	ra,0xffffd
    80005c02:	fa6080e7          	jalr	-90(ra) # 80002ba4 <argaddr>
    return -1;
    80005c06:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c08:	0e054063          	bltz	a0,80005ce8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c0c:	fc840593          	addi	a1,s0,-56
    80005c10:	fd040513          	addi	a0,s0,-48
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	dee080e7          	jalr	-530(ra) # 80004a02 <pipealloc>
    return -1;
    80005c1c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c1e:	0c054563          	bltz	a0,80005ce8 <sys_pipe+0x104>
  fd0 = -1;
    80005c22:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c26:	fd043503          	ld	a0,-48(s0)
    80005c2a:	fffff097          	auipc	ra,0xfffff
    80005c2e:	50a080e7          	jalr	1290(ra) # 80005134 <fdalloc>
    80005c32:	fca42223          	sw	a0,-60(s0)
    80005c36:	08054c63          	bltz	a0,80005cce <sys_pipe+0xea>
    80005c3a:	fc843503          	ld	a0,-56(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	4f6080e7          	jalr	1270(ra) # 80005134 <fdalloc>
    80005c46:	fca42023          	sw	a0,-64(s0)
    80005c4a:	06054863          	bltz	a0,80005cba <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c4e:	4691                	li	a3,4
    80005c50:	fc440613          	addi	a2,s0,-60
    80005c54:	fd843583          	ld	a1,-40(s0)
    80005c58:	70a8                	ld	a0,96(s1)
    80005c5a:	ffffc097          	auipc	ra,0xffffc
    80005c5e:	9e4080e7          	jalr	-1564(ra) # 8000163e <copyout>
    80005c62:	02054063          	bltz	a0,80005c82 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c66:	4691                	li	a3,4
    80005c68:	fc040613          	addi	a2,s0,-64
    80005c6c:	fd843583          	ld	a1,-40(s0)
    80005c70:	0591                	addi	a1,a1,4
    80005c72:	70a8                	ld	a0,96(s1)
    80005c74:	ffffc097          	auipc	ra,0xffffc
    80005c78:	9ca080e7          	jalr	-1590(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c7c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c7e:	06055563          	bgez	a0,80005ce8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c82:	fc442783          	lw	a5,-60(s0)
    80005c86:	07f1                	addi	a5,a5,28
    80005c88:	078e                	slli	a5,a5,0x3
    80005c8a:	97a6                	add	a5,a5,s1
    80005c8c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c90:	fc042503          	lw	a0,-64(s0)
    80005c94:	0571                	addi	a0,a0,28
    80005c96:	050e                	slli	a0,a0,0x3
    80005c98:	9526                	add	a0,a0,s1
    80005c9a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c9e:	fd043503          	ld	a0,-48(s0)
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	a30080e7          	jalr	-1488(ra) # 800046d2 <fileclose>
    fileclose(wf);
    80005caa:	fc843503          	ld	a0,-56(s0)
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	a24080e7          	jalr	-1500(ra) # 800046d2 <fileclose>
    return -1;
    80005cb6:	57fd                	li	a5,-1
    80005cb8:	a805                	j	80005ce8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cba:	fc442783          	lw	a5,-60(s0)
    80005cbe:	0007c863          	bltz	a5,80005cce <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cc2:	01c78513          	addi	a0,a5,28
    80005cc6:	050e                	slli	a0,a0,0x3
    80005cc8:	9526                	add	a0,a0,s1
    80005cca:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cce:	fd043503          	ld	a0,-48(s0)
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	a00080e7          	jalr	-1536(ra) # 800046d2 <fileclose>
    fileclose(wf);
    80005cda:	fc843503          	ld	a0,-56(s0)
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	9f4080e7          	jalr	-1548(ra) # 800046d2 <fileclose>
    return -1;
    80005ce6:	57fd                	li	a5,-1
}
    80005ce8:	853e                	mv	a0,a5
    80005cea:	70e2                	ld	ra,56(sp)
    80005cec:	7442                	ld	s0,48(sp)
    80005cee:	74a2                	ld	s1,40(sp)
    80005cf0:	6121                	addi	sp,sp,64
    80005cf2:	8082                	ret
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	c67fc0ef          	jal	ra,800029a6 <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	b7a080e7          	jalr	-1158(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	b42080e7          	jalr	-1214(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5179b          	slliw	a5,a0,0xd
    80005e1c:	0c201537          	lui	a0,0xc201
    80005e20:	953e                	add	a0,a0,a5
  return irq;
}
    80005e22:	4148                	lw	a0,4(a0)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b1a080e7          	jalr	-1254(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	06a7c963          	blt	a5,a0,80005ed2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	0001d797          	auipc	a5,0x1d
    80005e68:	19c78793          	addi	a5,a5,412 # 80023000 <disk>
    80005e6c:	00a78733          	add	a4,a5,a0
    80005e70:	6789                	lui	a5,0x2
    80005e72:	97ba                	add	a5,a5,a4
    80005e74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e78:	e7ad                	bnez	a5,80005ee2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e7a:	00451793          	slli	a5,a0,0x4
    80005e7e:	0001f717          	auipc	a4,0x1f
    80005e82:	18270713          	addi	a4,a4,386 # 80025000 <disk+0x2000>
    80005e86:	6314                	ld	a3,0(a4)
    80005e88:	96be                	add	a3,a3,a5
    80005e8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e8e:	6314                	ld	a3,0(a4)
    80005e90:	96be                	add	a3,a3,a5
    80005e92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e96:	6314                	ld	a3,0(a4)
    80005e98:	96be                	add	a3,a3,a5
    80005e9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e9e:	6318                	ld	a4,0(a4)
    80005ea0:	97ba                	add	a5,a5,a4
    80005ea2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ea6:	0001d797          	auipc	a5,0x1d
    80005eaa:	15a78793          	addi	a5,a5,346 # 80023000 <disk>
    80005eae:	97aa                	add	a5,a5,a0
    80005eb0:	6509                	lui	a0,0x2
    80005eb2:	953e                	add	a0,a0,a5
    80005eb4:	4785                	li	a5,1
    80005eb6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eba:	0001f517          	auipc	a0,0x1f
    80005ebe:	15e50513          	addi	a0,a0,350 # 80025018 <disk+0x2018>
    80005ec2:	ffffc097          	auipc	ra,0xffffc
    80005ec6:	298080e7          	jalr	664(ra) # 8000215a <wakeup>
}
    80005eca:	60a2                	ld	ra,8(sp)
    80005ecc:	6402                	ld	s0,0(sp)
    80005ece:	0141                	addi	sp,sp,16
    80005ed0:	8082                	ret
    panic("free_desc 1");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	98650513          	addi	a0,a0,-1658 # 80008858 <syscalls+0x328>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	650080e7          	jalr	1616(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	98650513          	addi	a0,a0,-1658 # 80008868 <syscalls+0x338>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	640080e7          	jalr	1600(ra) # 8000052a <panic>

0000000080005ef2 <virtio_disk_init>:
{
    80005ef2:	1101                	addi	sp,sp,-32
    80005ef4:	ec06                	sd	ra,24(sp)
    80005ef6:	e822                	sd	s0,16(sp)
    80005ef8:	e426                	sd	s1,8(sp)
    80005efa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005efc:	00003597          	auipc	a1,0x3
    80005f00:	97c58593          	addi	a1,a1,-1668 # 80008878 <syscalls+0x348>
    80005f04:	0001f517          	auipc	a0,0x1f
    80005f08:	22450513          	addi	a0,a0,548 # 80025128 <disk+0x2128>
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	c26080e7          	jalr	-986(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f14:	100017b7          	lui	a5,0x10001
    80005f18:	4398                	lw	a4,0(a5)
    80005f1a:	2701                	sext.w	a4,a4
    80005f1c:	747277b7          	lui	a5,0x74727
    80005f20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f24:	0ef71163          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	43dc                	lw	a5,4(a5)
    80005f2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f30:	4705                	li	a4,1
    80005f32:	0ce79a63          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f36:	100017b7          	lui	a5,0x10001
    80005f3a:	479c                	lw	a5,8(a5)
    80005f3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f3e:	4709                	li	a4,2
    80005f40:	0ce79363          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	47d8                	lw	a4,12(a5)
    80005f4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f4c:	554d47b7          	lui	a5,0x554d4
    80005f50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f54:	0af71963          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	4705                	li	a4,1
    80005f5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f60:	470d                	li	a4,3
    80005f62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f66:	c7ffe737          	lui	a4,0xc7ffe
    80005f6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f70:	2701                	sext.w	a4,a4
    80005f72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f74:	472d                	li	a4,11
    80005f76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f78:	473d                	li	a4,15
    80005f7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f7c:	6705                	lui	a4,0x1
    80005f7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f84:	5bdc                	lw	a5,52(a5)
    80005f86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f88:	c7d9                	beqz	a5,80006016 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f8a:	471d                	li	a4,7
    80005f8c:	08f77d63          	bgeu	a4,a5,80006026 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f90:	100014b7          	lui	s1,0x10001
    80005f94:	47a1                	li	a5,8
    80005f96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f98:	6609                	lui	a2,0x2
    80005f9a:	4581                	li	a1,0
    80005f9c:	0001d517          	auipc	a0,0x1d
    80005fa0:	06450513          	addi	a0,a0,100 # 80023000 <disk>
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	d1a080e7          	jalr	-742(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fac:	0001d717          	auipc	a4,0x1d
    80005fb0:	05470713          	addi	a4,a4,84 # 80023000 <disk>
    80005fb4:	00c75793          	srli	a5,a4,0xc
    80005fb8:	2781                	sext.w	a5,a5
    80005fba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fbc:	0001f797          	auipc	a5,0x1f
    80005fc0:	04478793          	addi	a5,a5,68 # 80025000 <disk+0x2000>
    80005fc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fc6:	0001d717          	auipc	a4,0x1d
    80005fca:	0ba70713          	addi	a4,a4,186 # 80023080 <disk+0x80>
    80005fce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fd0:	0001e717          	auipc	a4,0x1e
    80005fd4:	03070713          	addi	a4,a4,48 # 80024000 <disk+0x1000>
    80005fd8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fda:	4705                	li	a4,1
    80005fdc:	00e78c23          	sb	a4,24(a5)
    80005fe0:	00e78ca3          	sb	a4,25(a5)
    80005fe4:	00e78d23          	sb	a4,26(a5)
    80005fe8:	00e78da3          	sb	a4,27(a5)
    80005fec:	00e78e23          	sb	a4,28(a5)
    80005ff0:	00e78ea3          	sb	a4,29(a5)
    80005ff4:	00e78f23          	sb	a4,30(a5)
    80005ff8:	00e78fa3          	sb	a4,31(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6105                	addi	sp,sp,32
    80006004:	8082                	ret
    panic("could not find virtio disk");
    80006006:	00003517          	auipc	a0,0x3
    8000600a:	88250513          	addi	a0,a0,-1918 # 80008888 <syscalls+0x358>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	51c080e7          	jalr	1308(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006016:	00003517          	auipc	a0,0x3
    8000601a:	89250513          	addi	a0,a0,-1902 # 800088a8 <syscalls+0x378>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	50c080e7          	jalr	1292(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006026:	00003517          	auipc	a0,0x3
    8000602a:	8a250513          	addi	a0,a0,-1886 # 800088c8 <syscalls+0x398>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	4fc080e7          	jalr	1276(ra) # 8000052a <panic>

0000000080006036 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006036:	7119                	addi	sp,sp,-128
    80006038:	fc86                	sd	ra,120(sp)
    8000603a:	f8a2                	sd	s0,112(sp)
    8000603c:	f4a6                	sd	s1,104(sp)
    8000603e:	f0ca                	sd	s2,96(sp)
    80006040:	ecce                	sd	s3,88(sp)
    80006042:	e8d2                	sd	s4,80(sp)
    80006044:	e4d6                	sd	s5,72(sp)
    80006046:	e0da                	sd	s6,64(sp)
    80006048:	fc5e                	sd	s7,56(sp)
    8000604a:	f862                	sd	s8,48(sp)
    8000604c:	f466                	sd	s9,40(sp)
    8000604e:	f06a                	sd	s10,32(sp)
    80006050:	ec6e                	sd	s11,24(sp)
    80006052:	0100                	addi	s0,sp,128
    80006054:	8aaa                	mv	s5,a0
    80006056:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006058:	00c52c83          	lw	s9,12(a0)
    8000605c:	001c9c9b          	slliw	s9,s9,0x1
    80006060:	1c82                	slli	s9,s9,0x20
    80006062:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006066:	0001f517          	auipc	a0,0x1f
    8000606a:	0c250513          	addi	a0,a0,194 # 80025128 <disk+0x2128>
    8000606e:	ffffb097          	auipc	ra,0xffffb
    80006072:	b54080e7          	jalr	-1196(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006076:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006078:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000607a:	0001dc17          	auipc	s8,0x1d
    8000607e:	f86c0c13          	addi	s8,s8,-122 # 80023000 <disk>
    80006082:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006084:	4b0d                	li	s6,3
    80006086:	a0ad                	j	800060f0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006088:	00fc0733          	add	a4,s8,a5
    8000608c:	975e                	add	a4,a4,s7
    8000608e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006092:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006094:	0207c563          	bltz	a5,800060be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006098:	2905                	addiw	s2,s2,1
    8000609a:	0611                	addi	a2,a2,4
    8000609c:	19690d63          	beq	s2,s6,80006236 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800060a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060a2:	0001f717          	auipc	a4,0x1f
    800060a6:	f7670713          	addi	a4,a4,-138 # 80025018 <disk+0x2018>
    800060aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060ac:	00074683          	lbu	a3,0(a4)
    800060b0:	fee1                	bnez	a3,80006088 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060b2:	2785                	addiw	a5,a5,1
    800060b4:	0705                	addi	a4,a4,1
    800060b6:	fe979be3          	bne	a5,s1,800060ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ba:	57fd                	li	a5,-1
    800060bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060be:	01205d63          	blez	s2,800060d8 <virtio_disk_rw+0xa2>
    800060c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060c4:	000a2503          	lw	a0,0(s4)
    800060c8:	00000097          	auipc	ra,0x0
    800060cc:	d8e080e7          	jalr	-626(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060d0:	2d85                	addiw	s11,s11,1
    800060d2:	0a11                	addi	s4,s4,4
    800060d4:	ffb918e3          	bne	s2,s11,800060c4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060d8:	0001f597          	auipc	a1,0x1f
    800060dc:	05058593          	addi	a1,a1,80 # 80025128 <disk+0x2128>
    800060e0:	0001f517          	auipc	a0,0x1f
    800060e4:	f3850513          	addi	a0,a0,-200 # 80025018 <disk+0x2018>
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	ee6080e7          	jalr	-282(ra) # 80001fce <sleep>
  for(int i = 0; i < 3; i++){
    800060f0:	f8040a13          	addi	s4,s0,-128
{
    800060f4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060f6:	894e                	mv	s2,s3
    800060f8:	b765                	j	800060a0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060fa:	0001f697          	auipc	a3,0x1f
    800060fe:	f066b683          	ld	a3,-250(a3) # 80025000 <disk+0x2000>
    80006102:	96ba                	add	a3,a3,a4
    80006104:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006108:	0001d817          	auipc	a6,0x1d
    8000610c:	ef880813          	addi	a6,a6,-264 # 80023000 <disk>
    80006110:	0001f697          	auipc	a3,0x1f
    80006114:	ef068693          	addi	a3,a3,-272 # 80025000 <disk+0x2000>
    80006118:	6290                	ld	a2,0(a3)
    8000611a:	963a                	add	a2,a2,a4
    8000611c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006120:	0015e593          	ori	a1,a1,1
    80006124:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006128:	f8842603          	lw	a2,-120(s0)
    8000612c:	628c                	ld	a1,0(a3)
    8000612e:	972e                	add	a4,a4,a1
    80006130:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006134:	20050593          	addi	a1,a0,512
    80006138:	0592                	slli	a1,a1,0x4
    8000613a:	95c2                	add	a1,a1,a6
    8000613c:	577d                	li	a4,-1
    8000613e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006142:	00461713          	slli	a4,a2,0x4
    80006146:	6290                	ld	a2,0(a3)
    80006148:	963a                	add	a2,a2,a4
    8000614a:	03078793          	addi	a5,a5,48
    8000614e:	97c2                	add	a5,a5,a6
    80006150:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006152:	629c                	ld	a5,0(a3)
    80006154:	97ba                	add	a5,a5,a4
    80006156:	4605                	li	a2,1
    80006158:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000615a:	629c                	ld	a5,0(a3)
    8000615c:	97ba                	add	a5,a5,a4
    8000615e:	4809                	li	a6,2
    80006160:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006164:	629c                	ld	a5,0(a3)
    80006166:	973e                	add	a4,a4,a5
    80006168:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000616c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006170:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006174:	6698                	ld	a4,8(a3)
    80006176:	00275783          	lhu	a5,2(a4)
    8000617a:	8b9d                	andi	a5,a5,7
    8000617c:	0786                	slli	a5,a5,0x1
    8000617e:	97ba                	add	a5,a5,a4
    80006180:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006184:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006188:	6698                	ld	a4,8(a3)
    8000618a:	00275783          	lhu	a5,2(a4)
    8000618e:	2785                	addiw	a5,a5,1
    80006190:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006194:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006198:	100017b7          	lui	a5,0x10001
    8000619c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061a0:	004aa783          	lw	a5,4(s5)
    800061a4:	02c79163          	bne	a5,a2,800061c6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800061a8:	0001f917          	auipc	s2,0x1f
    800061ac:	f8090913          	addi	s2,s2,-128 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061b0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061b2:	85ca                	mv	a1,s2
    800061b4:	8556                	mv	a0,s5
    800061b6:	ffffc097          	auipc	ra,0xffffc
    800061ba:	e18080e7          	jalr	-488(ra) # 80001fce <sleep>
  while(b->disk == 1) {
    800061be:	004aa783          	lw	a5,4(s5)
    800061c2:	fe9788e3          	beq	a5,s1,800061b2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800061c6:	f8042903          	lw	s2,-128(s0)
    800061ca:	20090793          	addi	a5,s2,512
    800061ce:	00479713          	slli	a4,a5,0x4
    800061d2:	0001d797          	auipc	a5,0x1d
    800061d6:	e2e78793          	addi	a5,a5,-466 # 80023000 <disk>
    800061da:	97ba                	add	a5,a5,a4
    800061dc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061e0:	0001f997          	auipc	s3,0x1f
    800061e4:	e2098993          	addi	s3,s3,-480 # 80025000 <disk+0x2000>
    800061e8:	00491713          	slli	a4,s2,0x4
    800061ec:	0009b783          	ld	a5,0(s3)
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061f6:	854a                	mv	a0,s2
    800061f8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061fc:	00000097          	auipc	ra,0x0
    80006200:	c5a080e7          	jalr	-934(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006204:	8885                	andi	s1,s1,1
    80006206:	f0ed                	bnez	s1,800061e8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006208:	0001f517          	auipc	a0,0x1f
    8000620c:	f2050513          	addi	a0,a0,-224 # 80025128 <disk+0x2128>
    80006210:	ffffb097          	auipc	ra,0xffffb
    80006214:	a66080e7          	jalr	-1434(ra) # 80000c76 <release>
}
    80006218:	70e6                	ld	ra,120(sp)
    8000621a:	7446                	ld	s0,112(sp)
    8000621c:	74a6                	ld	s1,104(sp)
    8000621e:	7906                	ld	s2,96(sp)
    80006220:	69e6                	ld	s3,88(sp)
    80006222:	6a46                	ld	s4,80(sp)
    80006224:	6aa6                	ld	s5,72(sp)
    80006226:	6b06                	ld	s6,64(sp)
    80006228:	7be2                	ld	s7,56(sp)
    8000622a:	7c42                	ld	s8,48(sp)
    8000622c:	7ca2                	ld	s9,40(sp)
    8000622e:	7d02                	ld	s10,32(sp)
    80006230:	6de2                	ld	s11,24(sp)
    80006232:	6109                	addi	sp,sp,128
    80006234:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006236:	f8042503          	lw	a0,-128(s0)
    8000623a:	20050793          	addi	a5,a0,512
    8000623e:	0792                	slli	a5,a5,0x4
  if(write)
    80006240:	0001d817          	auipc	a6,0x1d
    80006244:	dc080813          	addi	a6,a6,-576 # 80023000 <disk>
    80006248:	00f80733          	add	a4,a6,a5
    8000624c:	01a036b3          	snez	a3,s10
    80006250:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006254:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006258:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000625c:	7679                	lui	a2,0xffffe
    8000625e:	963e                	add	a2,a2,a5
    80006260:	0001f697          	auipc	a3,0x1f
    80006264:	da068693          	addi	a3,a3,-608 # 80025000 <disk+0x2000>
    80006268:	6298                	ld	a4,0(a3)
    8000626a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000626c:	0a878593          	addi	a1,a5,168
    80006270:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006272:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006274:	6298                	ld	a4,0(a3)
    80006276:	9732                	add	a4,a4,a2
    80006278:	45c1                	li	a1,16
    8000627a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000627c:	6298                	ld	a4,0(a3)
    8000627e:	9732                	add	a4,a4,a2
    80006280:	4585                	li	a1,1
    80006282:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006286:	f8442703          	lw	a4,-124(s0)
    8000628a:	628c                	ld	a1,0(a3)
    8000628c:	962e                	add	a2,a2,a1
    8000628e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006292:	0712                	slli	a4,a4,0x4
    80006294:	6290                	ld	a2,0(a3)
    80006296:	963a                	add	a2,a2,a4
    80006298:	058a8593          	addi	a1,s5,88
    8000629c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000629e:	6294                	ld	a3,0(a3)
    800062a0:	96ba                	add	a3,a3,a4
    800062a2:	40000613          	li	a2,1024
    800062a6:	c690                	sw	a2,8(a3)
  if(write)
    800062a8:	e40d19e3          	bnez	s10,800060fa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062ac:	0001f697          	auipc	a3,0x1f
    800062b0:	d546b683          	ld	a3,-684(a3) # 80025000 <disk+0x2000>
    800062b4:	96ba                	add	a3,a3,a4
    800062b6:	4609                	li	a2,2
    800062b8:	00c69623          	sh	a2,12(a3)
    800062bc:	b5b1                	j	80006108 <virtio_disk_rw+0xd2>

00000000800062be <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062be:	1101                	addi	sp,sp,-32
    800062c0:	ec06                	sd	ra,24(sp)
    800062c2:	e822                	sd	s0,16(sp)
    800062c4:	e426                	sd	s1,8(sp)
    800062c6:	e04a                	sd	s2,0(sp)
    800062c8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062ca:	0001f517          	auipc	a0,0x1f
    800062ce:	e5e50513          	addi	a0,a0,-418 # 80025128 <disk+0x2128>
    800062d2:	ffffb097          	auipc	ra,0xffffb
    800062d6:	8f0080e7          	jalr	-1808(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062da:	10001737          	lui	a4,0x10001
    800062de:	533c                	lw	a5,96(a4)
    800062e0:	8b8d                	andi	a5,a5,3
    800062e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062e8:	0001f797          	auipc	a5,0x1f
    800062ec:	d1878793          	addi	a5,a5,-744 # 80025000 <disk+0x2000>
    800062f0:	6b94                	ld	a3,16(a5)
    800062f2:	0207d703          	lhu	a4,32(a5)
    800062f6:	0026d783          	lhu	a5,2(a3)
    800062fa:	06f70163          	beq	a4,a5,8000635c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062fe:	0001d917          	auipc	s2,0x1d
    80006302:	d0290913          	addi	s2,s2,-766 # 80023000 <disk>
    80006306:	0001f497          	auipc	s1,0x1f
    8000630a:	cfa48493          	addi	s1,s1,-774 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000630e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006312:	6898                	ld	a4,16(s1)
    80006314:	0204d783          	lhu	a5,32(s1)
    80006318:	8b9d                	andi	a5,a5,7
    8000631a:	078e                	slli	a5,a5,0x3
    8000631c:	97ba                	add	a5,a5,a4
    8000631e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006320:	20078713          	addi	a4,a5,512
    80006324:	0712                	slli	a4,a4,0x4
    80006326:	974a                	add	a4,a4,s2
    80006328:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000632c:	e731                	bnez	a4,80006378 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000632e:	20078793          	addi	a5,a5,512
    80006332:	0792                	slli	a5,a5,0x4
    80006334:	97ca                	add	a5,a5,s2
    80006336:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006338:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000633c:	ffffc097          	auipc	ra,0xffffc
    80006340:	e1e080e7          	jalr	-482(ra) # 8000215a <wakeup>

    disk.used_idx += 1;
    80006344:	0204d783          	lhu	a5,32(s1)
    80006348:	2785                	addiw	a5,a5,1
    8000634a:	17c2                	slli	a5,a5,0x30
    8000634c:	93c1                	srli	a5,a5,0x30
    8000634e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006352:	6898                	ld	a4,16(s1)
    80006354:	00275703          	lhu	a4,2(a4)
    80006358:	faf71be3          	bne	a4,a5,8000630e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000635c:	0001f517          	auipc	a0,0x1f
    80006360:	dcc50513          	addi	a0,a0,-564 # 80025128 <disk+0x2128>
    80006364:	ffffb097          	auipc	ra,0xffffb
    80006368:	912080e7          	jalr	-1774(ra) # 80000c76 <release>
}
    8000636c:	60e2                	ld	ra,24(sp)
    8000636e:	6442                	ld	s0,16(sp)
    80006370:	64a2                	ld	s1,8(sp)
    80006372:	6902                	ld	s2,0(sp)
    80006374:	6105                	addi	sp,sp,32
    80006376:	8082                	ret
      panic("virtio_disk_intr status");
    80006378:	00002517          	auipc	a0,0x2
    8000637c:	57050513          	addi	a0,a0,1392 # 800088e8 <syscalls+0x3b8>
    80006380:	ffffa097          	auipc	ra,0xffffa
    80006384:	1aa080e7          	jalr	426(ra) # 8000052a <panic>
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
