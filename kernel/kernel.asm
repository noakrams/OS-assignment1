
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
    80000068:	fac78793          	addi	a5,a5,-84 # 80006010 <timervec>
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
    80000122:	5d0080e7          	jalr	1488(ra) # 800026ee <either_copyin>
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
    800001c6:	f28080e7          	jalr	-216(ra) # 800020ea <sleep>
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
    80000202:	49a080e7          	jalr	1178(ra) # 80002698 <either_copyout>
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
    800002e2:	466080e7          	jalr	1126(ra) # 80002744 <procdump>
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
    80000436:	f2c080e7          	jalr	-212(ra) # 8000235e <wakeup>
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
    80000882:	ae0080e7          	jalr	-1312(ra) # 8000235e <wakeup>
    
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
    8000090e:	7e0080e7          	jalr	2016(ra) # 800020ea <sleep>
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
    80000eb6:	a8e080e7          	jalr	-1394(ra) # 80002940 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	196080e7          	jalr	406(ra) # 80006050 <plicinithart>
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
    80000f2e:	9ee080e7          	jalr	-1554(ra) # 80002918 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	a0e080e7          	jalr	-1522(ra) # 80002940 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	100080e7          	jalr	256(ra) # 8000603a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	10e080e7          	jalr	270(ra) # 80006050 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	2d4080e7          	jalr	724(ra) # 8000321e <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	966080e7          	jalr	-1690(ra) # 800038b8 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	914080e7          	jalr	-1772(ra) # 8000486e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	210080e7          	jalr	528(ra) # 80006172 <virtio_disk_init>
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
    800019dc:	f80080e7          	jalr	-128(ra) # 80002958 <usertrapret>
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
    800019f6:	e46080e7          	jalr	-442(ra) # 80003838 <fsinit>
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
    80001cf8:	572080e7          	jalr	1394(ra) # 80004266 <namei>
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
    80001e66:	a9e080e7          	jalr	-1378(ra) # 80004900 <filedup>
    80001e6a:	00a93023          	sd	a0,0(s2)
    80001e6e:	b7e5                	j	80001e56 <fork+0xc0>
  np->cwd = idup(p->cwd);
    80001e70:	188ab503          	ld	a0,392(s5)
    80001e74:	00002097          	auipc	ra,0x2
    80001e78:	bfe080e7          	jalr	-1026(ra) # 80003a72 <idup>
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
      if(p->state == RUNNABLE) {
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
      if(p->state == RUNNABLE) {
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
    80001fb4:	8fe080e7          	jalr	-1794(ra) # 800028ae <swtch>
        c->proc = 0;
    80001fb8:	020a3823          	sd	zero,48(s4)
    80001fbc:	b77d                	j	80001f6a <scheduler+0x6c>

0000000080001fbe <sched>:
{
    80001fbe:	7179                	addi	sp,sp,-48
    80001fc0:	f406                	sd	ra,40(sp)
    80001fc2:	f022                	sd	s0,32(sp)
    80001fc4:	ec26                	sd	s1,24(sp)
    80001fc6:	e84a                	sd	s2,16(sp)
    80001fc8:	e44e                	sd	s3,8(sp)
    80001fca:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	9b2080e7          	jalr	-1614(ra) # 8000197e <myproc>
    80001fd4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	b72080e7          	jalr	-1166(ra) # 80000b48 <holding>
    80001fde:	c93d                	beqz	a0,80002054 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fe2:	2781                	sext.w	a5,a5
    80001fe4:	079e                	slli	a5,a5,0x7
    80001fe6:	0000f717          	auipc	a4,0xf
    80001fea:	2ba70713          	addi	a4,a4,698 # 800112a0 <pid_lock>
    80001fee:	97ba                	add	a5,a5,a4
    80001ff0:	0a87a703          	lw	a4,168(a5)
    80001ff4:	4785                	li	a5,1
    80001ff6:	06f71763          	bne	a4,a5,80002064 <sched+0xa6>
  if(p->state == RUNNING)
    80001ffa:	4c98                	lw	a4,24(s1)
    80001ffc:	4791                	li	a5,4
    80001ffe:	06f70b63          	beq	a4,a5,80002074 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002002:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002006:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002008:	efb5                	bnez	a5,80002084 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000200c:	0000f917          	auipc	s2,0xf
    80002010:	29490913          	addi	s2,s2,660 # 800112a0 <pid_lock>
    80002014:	2781                	sext.w	a5,a5
    80002016:	079e                	slli	a5,a5,0x7
    80002018:	97ca                	add	a5,a5,s2
    8000201a:	0ac7a983          	lw	s3,172(a5)
    8000201e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002020:	2781                	sext.w	a5,a5
    80002022:	079e                	slli	a5,a5,0x7
    80002024:	0000f597          	auipc	a1,0xf
    80002028:	2b458593          	addi	a1,a1,692 # 800112d8 <cpus+0x8>
    8000202c:	95be                	add	a1,a1,a5
    8000202e:	09848513          	addi	a0,s1,152
    80002032:	00001097          	auipc	ra,0x1
    80002036:	87c080e7          	jalr	-1924(ra) # 800028ae <swtch>
    8000203a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	97ca                	add	a5,a5,s2
    80002042:	0b37a623          	sw	s3,172(a5)
}
    80002046:	70a2                	ld	ra,40(sp)
    80002048:	7402                	ld	s0,32(sp)
    8000204a:	64e2                	ld	s1,24(sp)
    8000204c:	6942                	ld	s2,16(sp)
    8000204e:	69a2                	ld	s3,8(sp)
    80002050:	6145                	addi	sp,sp,48
    80002052:	8082                	ret
    panic("sched p->lock");
    80002054:	00006517          	auipc	a0,0x6
    80002058:	1ac50513          	addi	a0,a0,428 # 80008200 <digits+0x1c0>
    8000205c:	ffffe097          	auipc	ra,0xffffe
    80002060:	4ce080e7          	jalr	1230(ra) # 8000052a <panic>
    panic("sched locks");
    80002064:	00006517          	auipc	a0,0x6
    80002068:	1ac50513          	addi	a0,a0,428 # 80008210 <digits+0x1d0>
    8000206c:	ffffe097          	auipc	ra,0xffffe
    80002070:	4be080e7          	jalr	1214(ra) # 8000052a <panic>
    panic("sched running");
    80002074:	00006517          	auipc	a0,0x6
    80002078:	1ac50513          	addi	a0,a0,428 # 80008220 <digits+0x1e0>
    8000207c:	ffffe097          	auipc	ra,0xffffe
    80002080:	4ae080e7          	jalr	1198(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002084:	00006517          	auipc	a0,0x6
    80002088:	1ac50513          	addi	a0,a0,428 # 80008230 <digits+0x1f0>
    8000208c:	ffffe097          	auipc	ra,0xffffe
    80002090:	49e080e7          	jalr	1182(ra) # 8000052a <panic>

0000000080002094 <yield>:
{
    80002094:	1101                	addi	sp,sp,-32
    80002096:	ec06                	sd	ra,24(sp)
    80002098:	e822                	sd	s0,16(sp)
    8000209a:	e426                	sd	s1,8(sp)
    8000209c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	8e0080e7          	jalr	-1824(ra) # 8000197e <myproc>
    800020a6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b1a080e7          	jalr	-1254(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800020b0:	478d                	li	a5,3
    800020b2:	cc9c                	sw	a5,24(s1)
  p->readyTime = ticks;
    800020b4:	00007717          	auipc	a4,0x7
    800020b8:	f7c72703          	lw	a4,-132(a4) # 80009030 <ticks>
    800020bc:	02071793          	slli	a5,a4,0x20
    800020c0:	9381                	srli	a5,a5,0x20
    800020c2:	ecbc                	sd	a5,88(s1)
  p->rutime += ticks - p->runningTime;
    800020c4:	48bc                	lw	a5,80(s1)
    800020c6:	9fb9                	addw	a5,a5,a4
    800020c8:	70b8                	ld	a4,96(s1)
    800020ca:	9f99                	subw	a5,a5,a4
    800020cc:	c8bc                	sw	a5,80(s1)
  sched();
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	ef0080e7          	jalr	-272(ra) # 80001fbe <sched>
  release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	b9e080e7          	jalr	-1122(ra) # 80000c76 <release>
}
    800020e0:	60e2                	ld	ra,24(sp)
    800020e2:	6442                	ld	s0,16(sp)
    800020e4:	64a2                	ld	s1,8(sp)
    800020e6:	6105                	addi	sp,sp,32
    800020e8:	8082                	ret

00000000800020ea <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ea:	7179                	addi	sp,sp,-48
    800020ec:	f406                	sd	ra,40(sp)
    800020ee:	f022                	sd	s0,32(sp)
    800020f0:	ec26                	sd	s1,24(sp)
    800020f2:	e84a                	sd	s2,16(sp)
    800020f4:	e44e                	sd	s3,8(sp)
    800020f6:	1800                	addi	s0,sp,48
    800020f8:	89aa                	mv	s3,a0
    800020fa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	882080e7          	jalr	-1918(ra) # 8000197e <myproc>
    80002104:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	abc080e7          	jalr	-1348(ra) # 80000bc2 <acquire>
  release(lk);
    8000210e:	854a                	mv	a0,s2
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	b66080e7          	jalr	-1178(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002118:	0334b023          	sd	s3,32(s1)
  p->rutime += ticks - p->runningTime;
    8000211c:	48bc                	lw	a5,80(s1)
    8000211e:	00007717          	auipc	a4,0x7
    80002122:	f1272703          	lw	a4,-238(a4) # 80009030 <ticks>
    80002126:	9fb9                	addw	a5,a5,a4
    80002128:	70b8                	ld	a4,96(s1)
    8000212a:	9f99                	subw	a5,a5,a4
    8000212c:	c8bc                	sw	a5,80(s1)
  p->state = SLEEPING;
    8000212e:	4789                	li	a5,2
    80002130:	cc9c                	sw	a5,24(s1)

  sched();
    80002132:	00000097          	auipc	ra,0x0
    80002136:	e8c080e7          	jalr	-372(ra) # 80001fbe <sched>

  // Tidy up.
  p->chan = 0;
    8000213a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b36080e7          	jalr	-1226(ra) # 80000c76 <release>
  acquire(lk);
    80002148:	854a                	mv	a0,s2
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	a78080e7          	jalr	-1416(ra) # 80000bc2 <acquire>
}
    80002152:	70a2                	ld	ra,40(sp)
    80002154:	7402                	ld	s0,32(sp)
    80002156:	64e2                	ld	s1,24(sp)
    80002158:	6942                	ld	s2,16(sp)
    8000215a:	69a2                	ld	s3,8(sp)
    8000215c:	6145                	addi	sp,sp,48
    8000215e:	8082                	ret

0000000080002160 <wait_extension>:
{
    80002160:	711d                	addi	sp,sp,-96
    80002162:	ec86                	sd	ra,88(sp)
    80002164:	e8a2                	sd	s0,80(sp)
    80002166:	e4a6                	sd	s1,72(sp)
    80002168:	e0ca                	sd	s2,64(sp)
    8000216a:	fc4e                	sd	s3,56(sp)
    8000216c:	f852                	sd	s4,48(sp)
    8000216e:	f456                	sd	s5,40(sp)
    80002170:	f05a                	sd	s6,32(sp)
    80002172:	ec5e                	sd	s7,24(sp)
    80002174:	e862                	sd	s8,16(sp)
    80002176:	e466                	sd	s9,8(sp)
    80002178:	1080                	addi	s0,sp,96
    8000217a:	8baa                	mv	s7,a0
    8000217c:	8b2e                	mv	s6,a1
  struct proc *p = myproc();
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	800080e7          	jalr	-2048(ra) # 8000197e <myproc>
    80002186:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002188:	0000f517          	auipc	a0,0xf
    8000218c:	13050513          	addi	a0,a0,304 # 800112b8 <wait_lock>
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	a32080e7          	jalr	-1486(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002198:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    8000219a:	4a15                	li	s4,5
        havekids = 1;
    8000219c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000219e:	00016997          	auipc	s3,0x16
    800021a2:	d3298993          	addi	s3,s3,-718 # 80017ed0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021a6:	0000fc97          	auipc	s9,0xf
    800021aa:	112c8c93          	addi	s9,s9,274 # 800112b8 <wait_lock>
    havekids = 0;
    800021ae:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    800021b0:	0000f497          	auipc	s1,0xf
    800021b4:	52048493          	addi	s1,s1,1312 # 800116d0 <proc>
    800021b8:	a231                	j	800022c4 <wait_extension+0x164>
          pid = np->pid;
    800021ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021be:	0c0b9463          	bnez	s7,80002286 <wait_extension+0x126>
          if (performance){
    800021c2:	080b0f63          	beqz	s6,80002260 <wait_extension+0x100>
            copyout(p->pagetable, (uint64) performance, (char*)&np->ctime, sizeof(int))< 0 ||
    800021c6:	4691                	li	a3,4
    800021c8:	04048613          	addi	a2,s1,64
    800021cc:	85da                	mv	a1,s6
    800021ce:	08893503          	ld	a0,136(s2)
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	46c080e7          	jalr	1132(ra) # 8000163e <copyout>
            if(
    800021da:	14054963          	bltz	a0,8000232c <wait_extension+0x1cc>
            copyout(p->pagetable, (uint64) performance+4, (char*)&np->ttime, sizeof(int))< 0 ||
    800021de:	4691                	li	a3,4
    800021e0:	04448613          	addi	a2,s1,68
    800021e4:	004b0593          	addi	a1,s6,4
    800021e8:	08893503          	ld	a0,136(s2)
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	452080e7          	jalr	1106(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance, (char*)&np->ctime, sizeof(int))< 0 ||
    800021f4:	12054e63          	bltz	a0,80002330 <wait_extension+0x1d0>
            copyout(p->pagetable, (uint64) performance+8, (char*)&np->stime, sizeof(int))< 0 ||
    800021f8:	4691                	li	a3,4
    800021fa:	04848613          	addi	a2,s1,72
    800021fe:	008b0593          	addi	a1,s6,8
    80002202:	08893503          	ld	a0,136(s2)
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	438080e7          	jalr	1080(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+4, (char*)&np->ttime, sizeof(int))< 0 ||
    8000220e:	12054363          	bltz	a0,80002334 <wait_extension+0x1d4>
            copyout(p->pagetable, (uint64) performance+12, (char*)&np->retime, sizeof(int))< 0 ||
    80002212:	4691                	li	a3,4
    80002214:	04c48613          	addi	a2,s1,76
    80002218:	00cb0593          	addi	a1,s6,12
    8000221c:	08893503          	ld	a0,136(s2)
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	41e080e7          	jalr	1054(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+8, (char*)&np->stime, sizeof(int))< 0 ||
    80002228:	10054863          	bltz	a0,80002338 <wait_extension+0x1d8>
            copyout(p->pagetable, (uint64) performance+16, (char*)&np->rutime, sizeof(int))< 0 ||
    8000222c:	4691                	li	a3,4
    8000222e:	05048613          	addi	a2,s1,80
    80002232:	010b0593          	addi	a1,s6,16
    80002236:	08893503          	ld	a0,136(s2)
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	404080e7          	jalr	1028(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+12, (char*)&np->retime, sizeof(int))< 0 ||
    80002242:	0e054d63          	bltz	a0,8000233c <wait_extension+0x1dc>
            copyout(p->pagetable, (uint64) performance+20, (char*)&np->average_bursttime, sizeof(int))< 0
    80002246:	4691                	li	a3,4
    80002248:	05448613          	addi	a2,s1,84
    8000224c:	014b0593          	addi	a1,s6,20
    80002250:	08893503          	ld	a0,136(s2)
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	3ea080e7          	jalr	1002(ra) # 8000163e <copyout>
            copyout(p->pagetable, (uint64) performance+16, (char*)&np->rutime, sizeof(int))< 0 ||
    8000225c:	0e054263          	bltz	a0,80002340 <wait_extension+0x1e0>
          freeproc(np);
    80002260:	8526                	mv	a0,s1
    80002262:	00000097          	auipc	ra,0x0
    80002266:	8ce080e7          	jalr	-1842(ra) # 80001b30 <freeproc>
          release(&np->lock);
    8000226a:	8526                	mv	a0,s1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a0a080e7          	jalr	-1526(ra) # 80000c76 <release>
          release(&wait_lock);
    80002274:	0000f517          	auipc	a0,0xf
    80002278:	04450513          	addi	a0,a0,68 # 800112b8 <wait_lock>
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	9fa080e7          	jalr	-1542(ra) # 80000c76 <release>
          return pid;
    80002284:	a8bd                	j	80002302 <wait_extension+0x1a2>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002286:	4691                	li	a3,4
    80002288:	02c48613          	addi	a2,s1,44
    8000228c:	85de                	mv	a1,s7
    8000228e:	08893503          	ld	a0,136(s2)
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	3ac080e7          	jalr	940(ra) # 8000163e <copyout>
    8000229a:	f20554e3          	bgez	a0,800021c2 <wait_extension+0x62>
            release(&np->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9d6080e7          	jalr	-1578(ra) # 80000c76 <release>
            release(&wait_lock);
    800022a8:	0000f517          	auipc	a0,0xf
    800022ac:	01050513          	addi	a0,a0,16 # 800112b8 <wait_lock>
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9c6080e7          	jalr	-1594(ra) # 80000c76 <release>
            return -1;
    800022b8:	59fd                	li	s3,-1
    800022ba:	a0a1                	j	80002302 <wait_extension+0x1a2>
    for(np = proc; np < &proc[NPROC]; np++){
    800022bc:	1a048493          	addi	s1,s1,416
    800022c0:	03348463          	beq	s1,s3,800022e8 <wait_extension+0x188>
      if(np->parent == p){
    800022c4:	78bc                	ld	a5,112(s1)
    800022c6:	ff279be3          	bne	a5,s2,800022bc <wait_extension+0x15c>
        acquire(&np->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	8f6080e7          	jalr	-1802(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800022d4:	4c9c                	lw	a5,24(s1)
    800022d6:	ef4782e3          	beq	a5,s4,800021ba <wait_extension+0x5a>
        release(&np->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	99a080e7          	jalr	-1638(ra) # 80000c76 <release>
        havekids = 1;
    800022e4:	8756                	mv	a4,s5
    800022e6:	bfd9                	j	800022bc <wait_extension+0x15c>
    if(!havekids || p->killed){
    800022e8:	c701                	beqz	a4,800022f0 <wait_extension+0x190>
    800022ea:	02892783          	lw	a5,40(s2)
    800022ee:	cb85                	beqz	a5,8000231e <wait_extension+0x1be>
      release(&wait_lock);
    800022f0:	0000f517          	auipc	a0,0xf
    800022f4:	fc850513          	addi	a0,a0,-56 # 800112b8 <wait_lock>
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	97e080e7          	jalr	-1666(ra) # 80000c76 <release>
      return -1;
    80002300:	59fd                	li	s3,-1
}
    80002302:	854e                	mv	a0,s3
    80002304:	60e6                	ld	ra,88(sp)
    80002306:	6446                	ld	s0,80(sp)
    80002308:	64a6                	ld	s1,72(sp)
    8000230a:	6906                	ld	s2,64(sp)
    8000230c:	79e2                	ld	s3,56(sp)
    8000230e:	7a42                	ld	s4,48(sp)
    80002310:	7aa2                	ld	s5,40(sp)
    80002312:	7b02                	ld	s6,32(sp)
    80002314:	6be2                	ld	s7,24(sp)
    80002316:	6c42                	ld	s8,16(sp)
    80002318:	6ca2                	ld	s9,8(sp)
    8000231a:	6125                	addi	sp,sp,96
    8000231c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000231e:	85e6                	mv	a1,s9
    80002320:	854a                	mv	a0,s2
    80002322:	00000097          	auipc	ra,0x0
    80002326:	dc8080e7          	jalr	-568(ra) # 800020ea <sleep>
    havekids = 0;
    8000232a:	b551                	j	800021ae <wait_extension+0x4e>
            return -1;
    8000232c:	59fd                	li	s3,-1
    8000232e:	bfd1                	j	80002302 <wait_extension+0x1a2>
    80002330:	59fd                	li	s3,-1
    80002332:	bfc1                	j	80002302 <wait_extension+0x1a2>
    80002334:	59fd                	li	s3,-1
    80002336:	b7f1                	j	80002302 <wait_extension+0x1a2>
    80002338:	59fd                	li	s3,-1
    8000233a:	b7e1                	j	80002302 <wait_extension+0x1a2>
    8000233c:	59fd                	li	s3,-1
    8000233e:	b7d1                	j	80002302 <wait_extension+0x1a2>
    80002340:	59fd                	li	s3,-1
    80002342:	b7c1                	j	80002302 <wait_extension+0x1a2>

0000000080002344 <wait>:
{
    80002344:	1141                	addi	sp,sp,-16
    80002346:	e406                	sd	ra,8(sp)
    80002348:	e022                	sd	s0,0(sp)
    8000234a:	0800                	addi	s0,sp,16
  return wait_extension (addr, 0);
    8000234c:	4581                	li	a1,0
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	e12080e7          	jalr	-494(ra) # 80002160 <wait_extension>
}
    80002356:	60a2                	ld	ra,8(sp)
    80002358:	6402                	ld	s0,0(sp)
    8000235a:	0141                	addi	sp,sp,16
    8000235c:	8082                	ret

000000008000235e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000235e:	7139                	addi	sp,sp,-64
    80002360:	fc06                	sd	ra,56(sp)
    80002362:	f822                	sd	s0,48(sp)
    80002364:	f426                	sd	s1,40(sp)
    80002366:	f04a                	sd	s2,32(sp)
    80002368:	ec4e                	sd	s3,24(sp)
    8000236a:	e852                	sd	s4,16(sp)
    8000236c:	e456                	sd	s5,8(sp)
    8000236e:	e05a                	sd	s6,0(sp)
    80002370:	0080                	addi	s0,sp,64
    80002372:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002374:	0000f497          	auipc	s1,0xf
    80002378:	35c48493          	addi	s1,s1,860 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000237c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000237e:	4b0d                	li	s6,3
        p->stime += ticks - p->sleepTime;
    80002380:	00007a97          	auipc	s5,0x7
    80002384:	cb0a8a93          	addi	s5,s5,-848 # 80009030 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002388:	00016917          	auipc	s2,0x16
    8000238c:	b4890913          	addi	s2,s2,-1208 # 80017ed0 <tickslock>
    80002390:	a811                	j	800023a4 <wakeup+0x46>
        p->readyTime = ticks;
      }
      release(&p->lock);
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	8e2080e7          	jalr	-1822(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000239c:	1a048493          	addi	s1,s1,416
    800023a0:	05248063          	beq	s1,s2,800023e0 <wakeup+0x82>
    if(p != myproc()){
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	5da080e7          	jalr	1498(ra) # 8000197e <myproc>
    800023ac:	fea488e3          	beq	s1,a0,8000239c <wakeup+0x3e>
      acquire(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	810080e7          	jalr	-2032(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023ba:	4c9c                	lw	a5,24(s1)
    800023bc:	fd379be3          	bne	a5,s3,80002392 <wakeup+0x34>
    800023c0:	709c                	ld	a5,32(s1)
    800023c2:	fd4798e3          	bne	a5,s4,80002392 <wakeup+0x34>
        p->state = RUNNABLE;
    800023c6:	0164ac23          	sw	s6,24(s1)
        p->stime += ticks - p->sleepTime;
    800023ca:	000aa703          	lw	a4,0(s5)
    800023ce:	44bc                	lw	a5,72(s1)
    800023d0:	9fb9                	addw	a5,a5,a4
    800023d2:	74b4                	ld	a3,104(s1)
    800023d4:	9f95                	subw	a5,a5,a3
    800023d6:	c4bc                	sw	a5,72(s1)
        p->readyTime = ticks;
    800023d8:	1702                	slli	a4,a4,0x20
    800023da:	9301                	srli	a4,a4,0x20
    800023dc:	ecb8                	sd	a4,88(s1)
    800023de:	bf55                	j	80002392 <wakeup+0x34>
    }
  }
}
    800023e0:	70e2                	ld	ra,56(sp)
    800023e2:	7442                	ld	s0,48(sp)
    800023e4:	74a2                	ld	s1,40(sp)
    800023e6:	7902                	ld	s2,32(sp)
    800023e8:	69e2                	ld	s3,24(sp)
    800023ea:	6a42                	ld	s4,16(sp)
    800023ec:	6aa2                	ld	s5,8(sp)
    800023ee:	6b02                	ld	s6,0(sp)
    800023f0:	6121                	addi	sp,sp,64
    800023f2:	8082                	ret

00000000800023f4 <reparent>:
{
    800023f4:	7179                	addi	sp,sp,-48
    800023f6:	f406                	sd	ra,40(sp)
    800023f8:	f022                	sd	s0,32(sp)
    800023fa:	ec26                	sd	s1,24(sp)
    800023fc:	e84a                	sd	s2,16(sp)
    800023fe:	e44e                	sd	s3,8(sp)
    80002400:	e052                	sd	s4,0(sp)
    80002402:	1800                	addi	s0,sp,48
    80002404:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002406:	0000f497          	auipc	s1,0xf
    8000240a:	2ca48493          	addi	s1,s1,714 # 800116d0 <proc>
      pp->parent = initproc;
    8000240e:	00007a17          	auipc	s4,0x7
    80002412:	c1aa0a13          	addi	s4,s4,-998 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002416:	00016997          	auipc	s3,0x16
    8000241a:	aba98993          	addi	s3,s3,-1350 # 80017ed0 <tickslock>
    8000241e:	a029                	j	80002428 <reparent+0x34>
    80002420:	1a048493          	addi	s1,s1,416
    80002424:	01348d63          	beq	s1,s3,8000243e <reparent+0x4a>
    if(pp->parent == p){
    80002428:	78bc                	ld	a5,112(s1)
    8000242a:	ff279be3          	bne	a5,s2,80002420 <reparent+0x2c>
      pp->parent = initproc;
    8000242e:	000a3503          	ld	a0,0(s4)
    80002432:	f8a8                	sd	a0,112(s1)
      wakeup(initproc);
    80002434:	00000097          	auipc	ra,0x0
    80002438:	f2a080e7          	jalr	-214(ra) # 8000235e <wakeup>
    8000243c:	b7d5                	j	80002420 <reparent+0x2c>
}
    8000243e:	70a2                	ld	ra,40(sp)
    80002440:	7402                	ld	s0,32(sp)
    80002442:	64e2                	ld	s1,24(sp)
    80002444:	6942                	ld	s2,16(sp)
    80002446:	69a2                	ld	s3,8(sp)
    80002448:	6a02                	ld	s4,0(sp)
    8000244a:	6145                	addi	sp,sp,48
    8000244c:	8082                	ret

000000008000244e <exit>:
{
    8000244e:	7179                	addi	sp,sp,-48
    80002450:	f406                	sd	ra,40(sp)
    80002452:	f022                	sd	s0,32(sp)
    80002454:	ec26                	sd	s1,24(sp)
    80002456:	e84a                	sd	s2,16(sp)
    80002458:	e44e                	sd	s3,8(sp)
    8000245a:	e052                	sd	s4,0(sp)
    8000245c:	1800                	addi	s0,sp,48
    8000245e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	51e080e7          	jalr	1310(ra) # 8000197e <myproc>
    80002468:	892a                	mv	s2,a0
  p->ttime = ticks;
    8000246a:	00007797          	auipc	a5,0x7
    8000246e:	bc67a783          	lw	a5,-1082(a5) # 80009030 <ticks>
    80002472:	c17c                	sw	a5,68(a0)
  if(p == initproc)
    80002474:	00007797          	auipc	a5,0x7
    80002478:	bb47b783          	ld	a5,-1100(a5) # 80009028 <initproc>
    8000247c:	10850493          	addi	s1,a0,264
    80002480:	18850993          	addi	s3,a0,392
    80002484:	02a79363          	bne	a5,a0,800024aa <exit+0x5c>
    panic("init exiting");
    80002488:	00006517          	auipc	a0,0x6
    8000248c:	dc050513          	addi	a0,a0,-576 # 80008248 <digits+0x208>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	09a080e7          	jalr	154(ra) # 8000052a <panic>
      fileclose(f);
    80002498:	00002097          	auipc	ra,0x2
    8000249c:	4ba080e7          	jalr	1210(ra) # 80004952 <fileclose>
      p->ofile[fd] = 0;
    800024a0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024a4:	04a1                	addi	s1,s1,8
    800024a6:	01348563          	beq	s1,s3,800024b0 <exit+0x62>
    if(p->ofile[fd]){
    800024aa:	6088                	ld	a0,0(s1)
    800024ac:	f575                	bnez	a0,80002498 <exit+0x4a>
    800024ae:	bfdd                	j	800024a4 <exit+0x56>
  begin_op();
    800024b0:	00002097          	auipc	ra,0x2
    800024b4:	fd6080e7          	jalr	-42(ra) # 80004486 <begin_op>
  iput(p->cwd);
    800024b8:	18893503          	ld	a0,392(s2)
    800024bc:	00001097          	auipc	ra,0x1
    800024c0:	7ae080e7          	jalr	1966(ra) # 80003c6a <iput>
  end_op();
    800024c4:	00002097          	auipc	ra,0x2
    800024c8:	042080e7          	jalr	66(ra) # 80004506 <end_op>
  p->cwd = 0;
    800024cc:	18093423          	sd	zero,392(s2)
  acquire(&wait_lock);
    800024d0:	0000f517          	auipc	a0,0xf
    800024d4:	de850513          	addi	a0,a0,-536 # 800112b8 <wait_lock>
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	6ea080e7          	jalr	1770(ra) # 80000bc2 <acquire>
  reparent(p);
    800024e0:	854a                	mv	a0,s2
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	f12080e7          	jalr	-238(ra) # 800023f4 <reparent>
  wakeup(p->parent);
    800024ea:	07093503          	ld	a0,112(s2)
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	e70080e7          	jalr	-400(ra) # 8000235e <wakeup>
  acquire(&p->lock);
    800024f6:	854a                	mv	a0,s2
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	6ca080e7          	jalr	1738(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002500:	03492623          	sw	s4,44(s2)
  if(p->state == RUNNING)
    80002504:	01892703          	lw	a4,24(s2)
    80002508:	4791                	li	a5,4
    8000250a:	02f70963          	beq	a4,a5,8000253c <exit+0xee>
  p->state = ZOMBIE;
    8000250e:	4795                	li	a5,5
    80002510:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002514:	0000f517          	auipc	a0,0xf
    80002518:	da450513          	addi	a0,a0,-604 # 800112b8 <wait_lock>
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	75a080e7          	jalr	1882(ra) # 80000c76 <release>
  sched();
    80002524:	00000097          	auipc	ra,0x0
    80002528:	a9a080e7          	jalr	-1382(ra) # 80001fbe <sched>
  panic("zombie exit");
    8000252c:	00006517          	auipc	a0,0x6
    80002530:	d2c50513          	addi	a0,a0,-724 # 80008258 <digits+0x218>
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	ff6080e7          	jalr	-10(ra) # 8000052a <panic>
    p->rutime += ticks - p->runningTime;
    8000253c:	05092783          	lw	a5,80(s2)
    80002540:	00007717          	auipc	a4,0x7
    80002544:	af072703          	lw	a4,-1296(a4) # 80009030 <ticks>
    80002548:	9fb9                	addw	a5,a5,a4
    8000254a:	06093703          	ld	a4,96(s2)
    8000254e:	9f99                	subw	a5,a5,a4
    80002550:	04f92823          	sw	a5,80(s2)
    80002554:	bf6d                	j	8000250e <exit+0xc0>

0000000080002556 <set_priority>:

int 
set_priority(int prio)
{
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    80002556:	47e5                	li	a5,25
    80002558:	04a7e963          	bltu	a5,a0,800025aa <set_priority+0x54>
{
    8000255c:	1101                	addi	sp,sp,-32
    8000255e:	ec06                	sd	ra,24(sp)
    80002560:	e822                	sd	s0,16(sp)
    80002562:	e426                	sd	s1,8(sp)
    80002564:	e04a                	sd	s2,0(sp)
    80002566:	1000                	addi	s0,sp,32
    80002568:	892a                	mv	s2,a0
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    8000256a:	020007b7          	lui	a5,0x2000
    8000256e:	0aa78793          	addi	a5,a5,170 # 20000aa <_entry-0x7dffff56>
    80002572:	00a7d7b3          	srl	a5,a5,a0
    80002576:	8b85                	andi	a5,a5,1
    && prio != LOW_PRIORITY && prio != TEST_LOW_PRIORITY){
      return -1;
    80002578:	557d                	li	a0,-1
  if(prio != TEST_HIGH_PRIORITY && prio != HIGH_PRIORITY && prio != NORMAL_PRIORITY
    8000257a:	c395                	beqz	a5,8000259e <set_priority+0x48>
  }
  struct proc *p = myproc();
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	402080e7          	jalr	1026(ra) # 8000197e <myproc>
    80002584:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	63c080e7          	jalr	1596(ra) # 80000bc2 <acquire>
    p->priority = prio;
    8000258e:	0324ae23          	sw	s2,60(s1)
  release(&p->lock);
    80002592:	8526                	mv	a0,s1
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	6e2080e7          	jalr	1762(ra) # 80000c76 <release>
  return 0;
    8000259c:	4501                	li	a0,0
}
    8000259e:	60e2                	ld	ra,24(sp)
    800025a0:	6442                	ld	s0,16(sp)
    800025a2:	64a2                	ld	s1,8(sp)
    800025a4:	6902                	ld	s2,0(sp)
    800025a6:	6105                	addi	sp,sp,32
    800025a8:	8082                	ret
      return -1;
    800025aa:	557d                	li	a0,-1
}
    800025ac:	8082                	ret

00000000800025ae <trace>:

int 
trace(int mask_input, int pid)
{
    800025ae:	7179                	addi	sp,sp,-48
    800025b0:	f406                	sd	ra,40(sp)
    800025b2:	f022                	sd	s0,32(sp)
    800025b4:	ec26                	sd	s1,24(sp)
    800025b6:	e84a                	sd	s2,16(sp)
    800025b8:	e44e                	sd	s3,8(sp)
    800025ba:	e052                	sd	s4,0(sp)
    800025bc:	1800                	addi	s0,sp,48
    800025be:	8a2a                	mv	s4,a0
    800025c0:	892e                	mv	s2,a1
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800025c2:	0000f497          	auipc	s1,0xf
    800025c6:	10e48493          	addi	s1,s1,270 # 800116d0 <proc>
    800025ca:	00016997          	auipc	s3,0x16
    800025ce:	90698993          	addi	s3,s3,-1786 # 80017ed0 <tickslock>
    800025d2:	a811                	j	800025e6 <trace+0x38>
    acquire(&p->lock);
    if(p->pid == pid)
      p->mask = mask_input;
    release(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6a0080e7          	jalr	1696(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	1a048493          	addi	s1,s1,416
    800025e2:	01348d63          	beq	s1,s3,800025fc <trace+0x4e>
    acquire(&p->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	5da080e7          	jalr	1498(ra) # 80000bc2 <acquire>
    if(p->pid == pid)
    800025f0:	589c                	lw	a5,48(s1)
    800025f2:	ff2791e3          	bne	a5,s2,800025d4 <trace+0x26>
      p->mask = mask_input;
    800025f6:	0344aa23          	sw	s4,52(s1)
    800025fa:	bfe9                	j	800025d4 <trace+0x26>
  }
  return 0;

}
    800025fc:	4501                	li	a0,0
    800025fe:	70a2                	ld	ra,40(sp)
    80002600:	7402                	ld	s0,32(sp)
    80002602:	64e2                	ld	s1,24(sp)
    80002604:	6942                	ld	s2,16(sp)
    80002606:	69a2                	ld	s3,8(sp)
    80002608:	6a02                	ld	s4,0(sp)
    8000260a:	6145                	addi	sp,sp,48
    8000260c:	8082                	ret

000000008000260e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000260e:	7179                	addi	sp,sp,-48
    80002610:	f406                	sd	ra,40(sp)
    80002612:	f022                	sd	s0,32(sp)
    80002614:	ec26                	sd	s1,24(sp)
    80002616:	e84a                	sd	s2,16(sp)
    80002618:	e44e                	sd	s3,8(sp)
    8000261a:	1800                	addi	s0,sp,48
    8000261c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000261e:	0000f497          	auipc	s1,0xf
    80002622:	0b248493          	addi	s1,s1,178 # 800116d0 <proc>
    80002626:	00016997          	auipc	s3,0x16
    8000262a:	8aa98993          	addi	s3,s3,-1878 # 80017ed0 <tickslock>
    acquire(&p->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	592080e7          	jalr	1426(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002638:	589c                	lw	a5,48(s1)
    8000263a:	01278d63          	beq	a5,s2,80002654 <kill+0x46>
        p->readyTime = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	636080e7          	jalr	1590(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002648:	1a048493          	addi	s1,s1,416
    8000264c:	ff3491e3          	bne	s1,s3,8000262e <kill+0x20>
  }
  return -1;
    80002650:	557d                	li	a0,-1
    80002652:	a829                	j	8000266c <kill+0x5e>
      p->killed = 1;
    80002654:	4785                	li	a5,1
    80002656:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002658:	4c98                	lw	a4,24(s1)
    8000265a:	4789                	li	a5,2
    8000265c:	00f70f63          	beq	a4,a5,8000267a <kill+0x6c>
      release(&p->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	614080e7          	jalr	1556(ra) # 80000c76 <release>
      return 0;
    8000266a:	4501                	li	a0,0
}
    8000266c:	70a2                	ld	ra,40(sp)
    8000266e:	7402                	ld	s0,32(sp)
    80002670:	64e2                	ld	s1,24(sp)
    80002672:	6942                	ld	s2,16(sp)
    80002674:	69a2                	ld	s3,8(sp)
    80002676:	6145                	addi	sp,sp,48
    80002678:	8082                	ret
        p->state = RUNNABLE;
    8000267a:	478d                	li	a5,3
    8000267c:	cc9c                	sw	a5,24(s1)
        p->stime += ticks - p->sleepTime;
    8000267e:	00007717          	auipc	a4,0x7
    80002682:	9b272703          	lw	a4,-1614(a4) # 80009030 <ticks>
    80002686:	44bc                	lw	a5,72(s1)
    80002688:	9fb9                	addw	a5,a5,a4
    8000268a:	74b4                	ld	a3,104(s1)
    8000268c:	9f95                	subw	a5,a5,a3
    8000268e:	c4bc                	sw	a5,72(s1)
        p->readyTime = ticks;
    80002690:	1702                	slli	a4,a4,0x20
    80002692:	9301                	srli	a4,a4,0x20
    80002694:	ecb8                	sd	a4,88(s1)
    80002696:	b7e9                	j	80002660 <kill+0x52>

0000000080002698 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002698:	7179                	addi	sp,sp,-48
    8000269a:	f406                	sd	ra,40(sp)
    8000269c:	f022                	sd	s0,32(sp)
    8000269e:	ec26                	sd	s1,24(sp)
    800026a0:	e84a                	sd	s2,16(sp)
    800026a2:	e44e                	sd	s3,8(sp)
    800026a4:	e052                	sd	s4,0(sp)
    800026a6:	1800                	addi	s0,sp,48
    800026a8:	84aa                	mv	s1,a0
    800026aa:	892e                	mv	s2,a1
    800026ac:	89b2                	mv	s3,a2
    800026ae:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	2ce080e7          	jalr	718(ra) # 8000197e <myproc>
  if(user_dst){
    800026b8:	c08d                	beqz	s1,800026da <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026ba:	86d2                	mv	a3,s4
    800026bc:	864e                	mv	a2,s3
    800026be:	85ca                	mv	a1,s2
    800026c0:	6548                	ld	a0,136(a0)
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	f7c080e7          	jalr	-132(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026ca:	70a2                	ld	ra,40(sp)
    800026cc:	7402                	ld	s0,32(sp)
    800026ce:	64e2                	ld	s1,24(sp)
    800026d0:	6942                	ld	s2,16(sp)
    800026d2:	69a2                	ld	s3,8(sp)
    800026d4:	6a02                	ld	s4,0(sp)
    800026d6:	6145                	addi	sp,sp,48
    800026d8:	8082                	ret
    memmove((char *)dst, src, len);
    800026da:	000a061b          	sext.w	a2,s4
    800026de:	85ce                	mv	a1,s3
    800026e0:	854a                	mv	a0,s2
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	638080e7          	jalr	1592(ra) # 80000d1a <memmove>
    return 0;
    800026ea:	8526                	mv	a0,s1
    800026ec:	bff9                	j	800026ca <either_copyout+0x32>

00000000800026ee <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026ee:	7179                	addi	sp,sp,-48
    800026f0:	f406                	sd	ra,40(sp)
    800026f2:	f022                	sd	s0,32(sp)
    800026f4:	ec26                	sd	s1,24(sp)
    800026f6:	e84a                	sd	s2,16(sp)
    800026f8:	e44e                	sd	s3,8(sp)
    800026fa:	e052                	sd	s4,0(sp)
    800026fc:	1800                	addi	s0,sp,48
    800026fe:	892a                	mv	s2,a0
    80002700:	84ae                	mv	s1,a1
    80002702:	89b2                	mv	s3,a2
    80002704:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	278080e7          	jalr	632(ra) # 8000197e <myproc>
  if(user_src){
    8000270e:	c08d                	beqz	s1,80002730 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002710:	86d2                	mv	a3,s4
    80002712:	864e                	mv	a2,s3
    80002714:	85ca                	mv	a1,s2
    80002716:	6548                	ld	a0,136(a0)
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	fb2080e7          	jalr	-78(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002720:	70a2                	ld	ra,40(sp)
    80002722:	7402                	ld	s0,32(sp)
    80002724:	64e2                	ld	s1,24(sp)
    80002726:	6942                	ld	s2,16(sp)
    80002728:	69a2                	ld	s3,8(sp)
    8000272a:	6a02                	ld	s4,0(sp)
    8000272c:	6145                	addi	sp,sp,48
    8000272e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002730:	000a061b          	sext.w	a2,s4
    80002734:	85ce                	mv	a1,s3
    80002736:	854a                	mv	a0,s2
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	5e2080e7          	jalr	1506(ra) # 80000d1a <memmove>
    return 0;
    80002740:	8526                	mv	a0,s1
    80002742:	bff9                	j	80002720 <either_copyin+0x32>

0000000080002744 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002744:	715d                	addi	sp,sp,-80
    80002746:	e486                	sd	ra,72(sp)
    80002748:	e0a2                	sd	s0,64(sp)
    8000274a:	fc26                	sd	s1,56(sp)
    8000274c:	f84a                	sd	s2,48(sp)
    8000274e:	f44e                	sd	s3,40(sp)
    80002750:	f052                	sd	s4,32(sp)
    80002752:	ec56                	sd	s5,24(sp)
    80002754:	e85a                	sd	s6,16(sp)
    80002756:	e45e                	sd	s7,8(sp)
    80002758:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000275a:	00006517          	auipc	a0,0x6
    8000275e:	96e50513          	addi	a0,a0,-1682 # 800080c8 <digits+0x88>
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	e12080e7          	jalr	-494(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000276a:	0000f497          	auipc	s1,0xf
    8000276e:	0f648493          	addi	s1,s1,246 # 80011860 <proc+0x190>
    80002772:	00016917          	auipc	s2,0x16
    80002776:	8ee90913          	addi	s2,s2,-1810 # 80018060 <bcache+0x178>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000277a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000277c:	00006997          	auipc	s3,0x6
    80002780:	aec98993          	addi	s3,s3,-1300 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002784:	00006a97          	auipc	s5,0x6
    80002788:	aeca8a93          	addi	s5,s5,-1300 # 80008270 <digits+0x230>
    printf("\n");
    8000278c:	00006a17          	auipc	s4,0x6
    80002790:	93ca0a13          	addi	s4,s4,-1732 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002794:	00006b97          	auipc	s7,0x6
    80002798:	b14b8b93          	addi	s7,s7,-1260 # 800082a8 <states.0>
    8000279c:	a00d                	j	800027be <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000279e:	ea06a583          	lw	a1,-352(a3)
    800027a2:	8556                	mv	a0,s5
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	dd0080e7          	jalr	-560(ra) # 80000574 <printf>
    printf("\n");
    800027ac:	8552                	mv	a0,s4
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	dc6080e7          	jalr	-570(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b6:	1a048493          	addi	s1,s1,416
    800027ba:	03248263          	beq	s1,s2,800027de <procdump+0x9a>
    if(p->state == UNUSED)
    800027be:	86a6                	mv	a3,s1
    800027c0:	e884a783          	lw	a5,-376(s1)
    800027c4:	dbed                	beqz	a5,800027b6 <procdump+0x72>
      state = "???";
    800027c6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c8:	fcfb6be3          	bltu	s6,a5,8000279e <procdump+0x5a>
    800027cc:	02079713          	slli	a4,a5,0x20
    800027d0:	01d75793          	srli	a5,a4,0x1d
    800027d4:	97de                	add	a5,a5,s7
    800027d6:	6390                	ld	a2,0(a5)
    800027d8:	f279                	bnez	a2,8000279e <procdump+0x5a>
      state = "???";
    800027da:	864e                	mv	a2,s3
    800027dc:	b7c9                	j	8000279e <procdump+0x5a>
  }
}
    800027de:	60a6                	ld	ra,72(sp)
    800027e0:	6406                	ld	s0,64(sp)
    800027e2:	74e2                	ld	s1,56(sp)
    800027e4:	7942                	ld	s2,48(sp)
    800027e6:	79a2                	ld	s3,40(sp)
    800027e8:	7a02                	ld	s4,32(sp)
    800027ea:	6ae2                	ld	s5,24(sp)
    800027ec:	6b42                	ld	s6,16(sp)
    800027ee:	6ba2                	ld	s7,8(sp)
    800027f0:	6161                	addi	sp,sp,80
    800027f2:	8082                	ret

00000000800027f4 <wait_stat>:


int
wait_stat(int* status, struct perf* performance)
{
    800027f4:	1141                	addi	sp,sp,-16
    800027f6:	e406                	sd	ra,8(sp)
    800027f8:	e022                	sd	s0,0(sp)
    800027fa:	0800                	addi	s0,sp,16
  
  return wait_extension ((uint64)*status, performance);
    800027fc:	4108                	lw	a0,0(a0)
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	962080e7          	jalr	-1694(ra) # 80002160 <wait_extension>
}
    80002806:	60a2                	ld	ra,8(sp)
    80002808:	6402                	ld	s0,0(sp)
    8000280a:	0141                	addi	sp,sp,16
    8000280c:	8082                	ret

000000008000280e <inctickcounter>:


int inctickcounter() {
    8000280e:	1101                	addi	sp,sp,-32
    80002810:	ec06                	sd	ra,24(sp)
    80002812:	e822                	sd	s0,16(sp)
    80002814:	e426                	sd	s1,8(sp)
    80002816:	e04a                	sd	s2,0(sp)
    80002818:	1000                	addi	s0,sp,32
  int res;
  struct proc *p = myproc();
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	164080e7          	jalr	356(ra) # 8000197e <myproc>
    80002822:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	39e080e7          	jalr	926(ra) # 80000bc2 <acquire>
  res = proc->tickcounter;
    8000282c:	0000f917          	auipc	s2,0xf
    80002830:	edc92903          	lw	s2,-292(s2) # 80011708 <proc+0x38>
  res++;
  release(&p->lock);
    80002834:	8526                	mv	a0,s1
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	440080e7          	jalr	1088(ra) # 80000c76 <release>
  return res;
}
    8000283e:	0019051b          	addiw	a0,s2,1
    80002842:	60e2                	ld	ra,24(sp)
    80002844:	6442                	ld	s0,16(sp)
    80002846:	64a2                	ld	s1,8(sp)
    80002848:	6902                	ld	s2,0(sp)
    8000284a:	6105                	addi	sp,sp,32
    8000284c:	8082                	ret

000000008000284e <switch_to_process>:

void switch_to_process(struct proc *p, struct cpu *c){
    8000284e:	1101                	addi	sp,sp,-32
    80002850:	ec06                	sd	ra,24(sp)
    80002852:	e822                	sd	s0,16(sp)
    80002854:	e426                	sd	s1,8(sp)
    80002856:	1000                	addi	s0,sp,32
    80002858:	84ae                	mv	s1,a1
  // Switch to chosen process.  It is the process's job
  // to release its lock and then reacquire it
  // before jumping back to us.
  p->state = RUNNING;
    8000285a:	4791                	li	a5,4
    8000285c:	cd1c                	sw	a5,24(a0)
  p->retime += ticks - p->readyTime;
    8000285e:	457c                	lw	a5,76(a0)
    80002860:	00006717          	auipc	a4,0x6
    80002864:	7d072703          	lw	a4,2000(a4) # 80009030 <ticks>
    80002868:	9fb9                	addw	a5,a5,a4
    8000286a:	6d38                	ld	a4,88(a0)
    8000286c:	9f99                	subw	a5,a5,a4
    8000286e:	c57c                	sw	a5,76(a0)
  p->average_bursttime = (ALPHA * p->tickcounter) + (((100 - ALPHA) * p->average_bursttime) / 100);
    80002870:	5d18                	lw	a4,56(a0)
    80002872:	03200793          	li	a5,50
    80002876:	02e787bb          	mulw	a5,a5,a4
    8000287a:	4974                	lw	a3,84(a0)
    8000287c:	01f6d71b          	srliw	a4,a3,0x1f
    80002880:	9f35                	addw	a4,a4,a3
    80002882:	4017571b          	sraiw	a4,a4,0x1
    80002886:	9fb9                	addw	a5,a5,a4
    80002888:	c97c                	sw	a5,84(a0)
  p->tickcounter = 0;
    8000288a:	02052c23          	sw	zero,56(a0)
  c->proc = p;
    8000288e:	e188                	sd	a0,0(a1)
  swtch(&c->context, &p->context);
    80002890:	09850593          	addi	a1,a0,152
    80002894:	00848513          	addi	a0,s1,8
    80002898:	00000097          	auipc	ra,0x0
    8000289c:	016080e7          	jalr	22(ra) # 800028ae <swtch>

  // Process is done running for now.
  // It should have changed its p->state before coming back.
  c->proc = 0;
    800028a0:	0004b023          	sd	zero,0(s1)
}
    800028a4:	60e2                	ld	ra,24(sp)
    800028a6:	6442                	ld	s0,16(sp)
    800028a8:	64a2                	ld	s1,8(sp)
    800028aa:	6105                	addi	sp,sp,32
    800028ac:	8082                	ret

00000000800028ae <swtch>:
    800028ae:	00153023          	sd	ra,0(a0)
    800028b2:	00253423          	sd	sp,8(a0)
    800028b6:	e900                	sd	s0,16(a0)
    800028b8:	ed04                	sd	s1,24(a0)
    800028ba:	03253023          	sd	s2,32(a0)
    800028be:	03353423          	sd	s3,40(a0)
    800028c2:	03453823          	sd	s4,48(a0)
    800028c6:	03553c23          	sd	s5,56(a0)
    800028ca:	05653023          	sd	s6,64(a0)
    800028ce:	05753423          	sd	s7,72(a0)
    800028d2:	05853823          	sd	s8,80(a0)
    800028d6:	05953c23          	sd	s9,88(a0)
    800028da:	07a53023          	sd	s10,96(a0)
    800028de:	07b53423          	sd	s11,104(a0)
    800028e2:	0005b083          	ld	ra,0(a1)
    800028e6:	0085b103          	ld	sp,8(a1)
    800028ea:	6980                	ld	s0,16(a1)
    800028ec:	6d84                	ld	s1,24(a1)
    800028ee:	0205b903          	ld	s2,32(a1)
    800028f2:	0285b983          	ld	s3,40(a1)
    800028f6:	0305ba03          	ld	s4,48(a1)
    800028fa:	0385ba83          	ld	s5,56(a1)
    800028fe:	0405bb03          	ld	s6,64(a1)
    80002902:	0485bb83          	ld	s7,72(a1)
    80002906:	0505bc03          	ld	s8,80(a1)
    8000290a:	0585bc83          	ld	s9,88(a1)
    8000290e:	0605bd03          	ld	s10,96(a1)
    80002912:	0685bd83          	ld	s11,104(a1)
    80002916:	8082                	ret

0000000080002918 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002918:	1141                	addi	sp,sp,-16
    8000291a:	e406                	sd	ra,8(sp)
    8000291c:	e022                	sd	s0,0(sp)
    8000291e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002920:	00006597          	auipc	a1,0x6
    80002924:	9b858593          	addi	a1,a1,-1608 # 800082d8 <states.0+0x30>
    80002928:	00015517          	auipc	a0,0x15
    8000292c:	5a850513          	addi	a0,a0,1448 # 80017ed0 <tickslock>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	202080e7          	jalr	514(ra) # 80000b32 <initlock>
}
    80002938:	60a2                	ld	ra,8(sp)
    8000293a:	6402                	ld	s0,0(sp)
    8000293c:	0141                	addi	sp,sp,16
    8000293e:	8082                	ret

0000000080002940 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002940:	1141                	addi	sp,sp,-16
    80002942:	e422                	sd	s0,8(sp)
    80002944:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002946:	00003797          	auipc	a5,0x3
    8000294a:	63a78793          	addi	a5,a5,1594 # 80005f80 <kernelvec>
    8000294e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002952:	6422                	ld	s0,8(sp)
    80002954:	0141                	addi	sp,sp,16
    80002956:	8082                	ret

0000000080002958 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002958:	1141                	addi	sp,sp,-16
    8000295a:	e406                	sd	ra,8(sp)
    8000295c:	e022                	sd	s0,0(sp)
    8000295e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	01e080e7          	jalr	30(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002968:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000296c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002972:	00004617          	auipc	a2,0x4
    80002976:	68e60613          	addi	a2,a2,1678 # 80007000 <_trampoline>
    8000297a:	00004697          	auipc	a3,0x4
    8000297e:	68668693          	addi	a3,a3,1670 # 80007000 <_trampoline>
    80002982:	8e91                	sub	a3,a3,a2
    80002984:	040007b7          	lui	a5,0x4000
    80002988:	17fd                	addi	a5,a5,-1
    8000298a:	07b2                	slli	a5,a5,0xc
    8000298c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000298e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002992:	6958                	ld	a4,144(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002994:	180026f3          	csrr	a3,satp
    80002998:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000299a:	6958                	ld	a4,144(a0)
    8000299c:	7d34                	ld	a3,120(a0)
    8000299e:	6585                	lui	a1,0x1
    800029a0:	96ae                	add	a3,a3,a1
    800029a2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029a4:	6958                	ld	a4,144(a0)
    800029a6:	00000697          	auipc	a3,0x0
    800029aa:	13868693          	addi	a3,a3,312 # 80002ade <usertrap>
    800029ae:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029b0:	6958                	ld	a4,144(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029b2:	8692                	mv	a3,tp
    800029b4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029ba:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029be:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029c6:	6958                	ld	a4,144(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c8:	6f18                	ld	a4,24(a4)
    800029ca:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ce:	654c                	ld	a1,136(a0)
    800029d0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029d2:	00004717          	auipc	a4,0x4
    800029d6:	6be70713          	addi	a4,a4,1726 # 80007090 <userret>
    800029da:	8f11                	sub	a4,a4,a2
    800029dc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029de:	577d                	li	a4,-1
    800029e0:	177e                	slli	a4,a4,0x3f
    800029e2:	8dd9                	or	a1,a1,a4
    800029e4:	02000537          	lui	a0,0x2000
    800029e8:	157d                	addi	a0,a0,-1
    800029ea:	0536                	slli	a0,a0,0xd
    800029ec:	9782                	jalr	a5
}
    800029ee:	60a2                	ld	ra,8(sp)
    800029f0:	6402                	ld	s0,0(sp)
    800029f2:	0141                	addi	sp,sp,16
    800029f4:	8082                	ret

00000000800029f6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a00:	00015497          	auipc	s1,0x15
    80002a04:	4d048493          	addi	s1,s1,1232 # 80017ed0 <tickslock>
    80002a08:	8526                	mv	a0,s1
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	1b8080e7          	jalr	440(ra) # 80000bc2 <acquire>
  ticks++;
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	61e50513          	addi	a0,a0,1566 # 80009030 <ticks>
    80002a1a:	411c                	lw	a5,0(a0)
    80002a1c:	2785                	addiw	a5,a5,1
    80002a1e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	93e080e7          	jalr	-1730(ra) # 8000235e <wakeup>
  release(&tickslock);
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	24c080e7          	jalr	588(ra) # 80000c76 <release>
}
    80002a32:	60e2                	ld	ra,24(sp)
    80002a34:	6442                	ld	s0,16(sp)
    80002a36:	64a2                	ld	s1,8(sp)
    80002a38:	6105                	addi	sp,sp,32
    80002a3a:	8082                	ret

0000000080002a3c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a3c:	1101                	addi	sp,sp,-32
    80002a3e:	ec06                	sd	ra,24(sp)
    80002a40:	e822                	sd	s0,16(sp)
    80002a42:	e426                	sd	s1,8(sp)
    80002a44:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a46:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a4a:	00074d63          	bltz	a4,80002a64 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a4e:	57fd                	li	a5,-1
    80002a50:	17fe                	slli	a5,a5,0x3f
    80002a52:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a54:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a56:	06f70363          	beq	a4,a5,80002abc <devintr+0x80>
  }
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6105                	addi	sp,sp,32
    80002a62:	8082                	ret
     (scause & 0xff) == 9){
    80002a64:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a68:	46a5                	li	a3,9
    80002a6a:	fed792e3          	bne	a5,a3,80002a4e <devintr+0x12>
    int irq = plic_claim();
    80002a6e:	00003097          	auipc	ra,0x3
    80002a72:	61a080e7          	jalr	1562(ra) # 80006088 <plic_claim>
    80002a76:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a78:	47a9                	li	a5,10
    80002a7a:	02f50763          	beq	a0,a5,80002aa8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a7e:	4785                	li	a5,1
    80002a80:	02f50963          	beq	a0,a5,80002ab2 <devintr+0x76>
    return 1;
    80002a84:	4505                	li	a0,1
    } else if(irq){
    80002a86:	d8f1                	beqz	s1,80002a5a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a88:	85a6                	mv	a1,s1
    80002a8a:	00006517          	auipc	a0,0x6
    80002a8e:	85650513          	addi	a0,a0,-1962 # 800082e0 <states.0+0x38>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	ae2080e7          	jalr	-1310(ra) # 80000574 <printf>
      plic_complete(irq);
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	00003097          	auipc	ra,0x3
    80002aa0:	610080e7          	jalr	1552(ra) # 800060ac <plic_complete>
    return 1;
    80002aa4:	4505                	li	a0,1
    80002aa6:	bf55                	j	80002a5a <devintr+0x1e>
      uartintr();
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	ede080e7          	jalr	-290(ra) # 80000986 <uartintr>
    80002ab0:	b7ed                	j	80002a9a <devintr+0x5e>
      virtio_disk_intr();
    80002ab2:	00004097          	auipc	ra,0x4
    80002ab6:	a8c080e7          	jalr	-1396(ra) # 8000653e <virtio_disk_intr>
    80002aba:	b7c5                	j	80002a9a <devintr+0x5e>
    if(cpuid() == 0){
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	e96080e7          	jalr	-362(ra) # 80001952 <cpuid>
    80002ac4:	c901                	beqz	a0,80002ad4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ac6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002acc:	14479073          	csrw	sip,a5
    return 2;
    80002ad0:	4509                	li	a0,2
    80002ad2:	b761                	j	80002a5a <devintr+0x1e>
      clockintr();
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	f22080e7          	jalr	-222(ra) # 800029f6 <clockintr>
    80002adc:	b7ed                	j	80002ac6 <devintr+0x8a>

0000000080002ade <usertrap>:
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	e04a                	sd	s2,0(sp)
    80002ae8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002aee:	1007f793          	andi	a5,a5,256
    80002af2:	e3ad                	bnez	a5,80002b54 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af4:	00003797          	auipc	a5,0x3
    80002af8:	48c78793          	addi	a5,a5,1164 # 80005f80 <kernelvec>
    80002afc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	e7e080e7          	jalr	-386(ra) # 8000197e <myproc>
    80002b08:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b0a:	695c                	ld	a5,144(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0c:	14102773          	csrr	a4,sepc
    80002b10:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b12:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b16:	47a1                	li	a5,8
    80002b18:	04f71c63          	bne	a4,a5,80002b70 <usertrap+0x92>
    if(p->killed)
    80002b1c:	551c                	lw	a5,40(a0)
    80002b1e:	e3b9                	bnez	a5,80002b64 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b20:	68d8                	ld	a4,144(s1)
    80002b22:	6f1c                	ld	a5,24(a4)
    80002b24:	0791                	addi	a5,a5,4
    80002b26:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b2c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b30:	10079073          	csrw	sstatus,a5
    syscall();
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	2fc080e7          	jalr	764(ra) # 80002e30 <syscall>
  if(p->killed)
    80002b3c:	549c                	lw	a5,40(s1)
    80002b3e:	efd9                	bnez	a5,80002bdc <usertrap+0xfe>
  usertrapret();
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	e18080e7          	jalr	-488(ra) # 80002958 <usertrapret>
}
    80002b48:	60e2                	ld	ra,24(sp)
    80002b4a:	6442                	ld	s0,16(sp)
    80002b4c:	64a2                	ld	s1,8(sp)
    80002b4e:	6902                	ld	s2,0(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret
    panic("usertrap: not from user mode");
    80002b54:	00005517          	auipc	a0,0x5
    80002b58:	7ac50513          	addi	a0,a0,1964 # 80008300 <states.0+0x58>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	9ce080e7          	jalr	-1586(ra) # 8000052a <panic>
      exit(-1);
    80002b64:	557d                	li	a0,-1
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	8e8080e7          	jalr	-1816(ra) # 8000244e <exit>
    80002b6e:	bf4d                	j	80002b20 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	ecc080e7          	jalr	-308(ra) # 80002a3c <devintr>
    80002b78:	892a                	mv	s2,a0
    80002b7a:	c501                	beqz	a0,80002b82 <usertrap+0xa4>
  if(p->killed)
    80002b7c:	549c                	lw	a5,40(s1)
    80002b7e:	c3a1                	beqz	a5,80002bbe <usertrap+0xe0>
    80002b80:	a815                	j	80002bb4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b82:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b86:	5890                	lw	a2,48(s1)
    80002b88:	00005517          	auipc	a0,0x5
    80002b8c:	79850513          	addi	a0,a0,1944 # 80008320 <states.0+0x78>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9e4080e7          	jalr	-1564(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b9c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ba0:	00005517          	auipc	a0,0x5
    80002ba4:	7b050513          	addi	a0,a0,1968 # 80008350 <states.0+0xa8>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9cc080e7          	jalr	-1588(ra) # 80000574 <printf>
    p->killed = 1;
    80002bb0:	4785                	li	a5,1
    80002bb2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bb4:	557d                	li	a0,-1
    80002bb6:	00000097          	auipc	ra,0x0
    80002bba:	898080e7          	jalr	-1896(ra) # 8000244e <exit>
  if(which_dev == 2){
    80002bbe:	4789                	li	a5,2
    80002bc0:	f8f910e3          	bne	s2,a5,80002b40 <usertrap+0x62>
    if(inctickcounter() == QUANTUM){
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	c4a080e7          	jalr	-950(ra) # 8000280e <inctickcounter>
    80002bcc:	4795                	li	a5,5
    80002bce:	f6f519e3          	bne	a0,a5,80002b40 <usertrap+0x62>
      yield();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	4c2080e7          	jalr	1218(ra) # 80002094 <yield>
    80002bda:	b79d                	j	80002b40 <usertrap+0x62>
  int which_dev = 0;
    80002bdc:	4901                	li	s2,0
    80002bde:	bfd9                	j	80002bb4 <usertrap+0xd6>

0000000080002be0 <kerneltrap>:
{
    80002be0:	7179                	addi	sp,sp,-48
    80002be2:	f406                	sd	ra,40(sp)
    80002be4:	f022                	sd	s0,32(sp)
    80002be6:	ec26                	sd	s1,24(sp)
    80002be8:	e84a                	sd	s2,16(sp)
    80002bea:	e44e                	sd	s3,8(sp)
    80002bec:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bee:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bfa:	1004f793          	andi	a5,s1,256
    80002bfe:	cb85                	beqz	a5,80002c2e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c00:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c04:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c06:	ef85                	bnez	a5,80002c3e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	e34080e7          	jalr	-460(ra) # 80002a3c <devintr>
    80002c10:	cd1d                	beqz	a0,80002c4e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    80002c12:	4789                	li	a5,2
    80002c14:	06f50a63          	beq	a0,a5,80002c88 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c18:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c1c:	10049073          	csrw	sstatus,s1
}
    80002c20:	70a2                	ld	ra,40(sp)
    80002c22:	7402                	ld	s0,32(sp)
    80002c24:	64e2                	ld	s1,24(sp)
    80002c26:	6942                	ld	s2,16(sp)
    80002c28:	69a2                	ld	s3,8(sp)
    80002c2a:	6145                	addi	sp,sp,48
    80002c2c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	74250513          	addi	a0,a0,1858 # 80008370 <states.0+0xc8>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	8f4080e7          	jalr	-1804(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002c3e:	00005517          	auipc	a0,0x5
    80002c42:	75a50513          	addi	a0,a0,1882 # 80008398 <states.0+0xf0>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	8e4080e7          	jalr	-1820(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002c4e:	85ce                	mv	a1,s3
    80002c50:	00005517          	auipc	a0,0x5
    80002c54:	76850513          	addi	a0,a0,1896 # 800083b8 <states.0+0x110>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	91c080e7          	jalr	-1764(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c64:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	76050513          	addi	a0,a0,1888 # 800083c8 <states.0+0x120>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	904080e7          	jalr	-1788(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	76850513          	addi	a0,a0,1896 # 800083e0 <states.0+0x138>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	8aa080e7          	jalr	-1878(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && inctickcounter() == QUANTUM){
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	cf6080e7          	jalr	-778(ra) # 8000197e <myproc>
    80002c90:	d541                	beqz	a0,80002c18 <kerneltrap+0x38>
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	cec080e7          	jalr	-788(ra) # 8000197e <myproc>
    80002c9a:	4d18                	lw	a4,24(a0)
    80002c9c:	4791                	li	a5,4
    80002c9e:	f6f71de3          	bne	a4,a5,80002c18 <kerneltrap+0x38>
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	b6c080e7          	jalr	-1172(ra) # 8000280e <inctickcounter>
    80002caa:	4795                	li	a5,5
    80002cac:	f6f516e3          	bne	a0,a5,80002c18 <kerneltrap+0x38>
    yield();
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	3e4080e7          	jalr	996(ra) # 80002094 <yield>
    80002cb8:	b785                	j	80002c18 <kerneltrap+0x38>

0000000080002cba <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	e426                	sd	s1,8(sp)
    80002cc2:	1000                	addi	s0,sp,32
    80002cc4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	cb8080e7          	jalr	-840(ra) # 8000197e <myproc>
  switch (n) {
    80002cce:	4795                	li	a5,5
    80002cd0:	0497e163          	bltu	a5,s1,80002d12 <argraw+0x58>
    80002cd4:	048a                	slli	s1,s1,0x2
    80002cd6:	00006717          	auipc	a4,0x6
    80002cda:	86270713          	addi	a4,a4,-1950 # 80008538 <states.0+0x290>
    80002cde:	94ba                	add	s1,s1,a4
    80002ce0:	409c                	lw	a5,0(s1)
    80002ce2:	97ba                	add	a5,a5,a4
    80002ce4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ce6:	695c                	ld	a5,144(a0)
    80002ce8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cea:	60e2                	ld	ra,24(sp)
    80002cec:	6442                	ld	s0,16(sp)
    80002cee:	64a2                	ld	s1,8(sp)
    80002cf0:	6105                	addi	sp,sp,32
    80002cf2:	8082                	ret
    return p->trapframe->a1;
    80002cf4:	695c                	ld	a5,144(a0)
    80002cf6:	7fa8                	ld	a0,120(a5)
    80002cf8:	bfcd                	j	80002cea <argraw+0x30>
    return p->trapframe->a2;
    80002cfa:	695c                	ld	a5,144(a0)
    80002cfc:	63c8                	ld	a0,128(a5)
    80002cfe:	b7f5                	j	80002cea <argraw+0x30>
    return p->trapframe->a3;
    80002d00:	695c                	ld	a5,144(a0)
    80002d02:	67c8                	ld	a0,136(a5)
    80002d04:	b7dd                	j	80002cea <argraw+0x30>
    return p->trapframe->a4;
    80002d06:	695c                	ld	a5,144(a0)
    80002d08:	6bc8                	ld	a0,144(a5)
    80002d0a:	b7c5                	j	80002cea <argraw+0x30>
    return p->trapframe->a5;
    80002d0c:	695c                	ld	a5,144(a0)
    80002d0e:	6fc8                	ld	a0,152(a5)
    80002d10:	bfe9                	j	80002cea <argraw+0x30>
  panic("argraw");
    80002d12:	00005517          	auipc	a0,0x5
    80002d16:	6de50513          	addi	a0,a0,1758 # 800083f0 <states.0+0x148>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	810080e7          	jalr	-2032(ra) # 8000052a <panic>

0000000080002d22 <fetchaddr>:
{
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	e426                	sd	s1,8(sp)
    80002d2a:	e04a                	sd	s2,0(sp)
    80002d2c:	1000                	addi	s0,sp,32
    80002d2e:	84aa                	mv	s1,a0
    80002d30:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	c4c080e7          	jalr	-948(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d3a:	615c                	ld	a5,128(a0)
    80002d3c:	02f4f863          	bgeu	s1,a5,80002d6c <fetchaddr+0x4a>
    80002d40:	00848713          	addi	a4,s1,8
    80002d44:	02e7e663          	bltu	a5,a4,80002d70 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d48:	46a1                	li	a3,8
    80002d4a:	8626                	mv	a2,s1
    80002d4c:	85ca                	mv	a1,s2
    80002d4e:	6548                	ld	a0,136(a0)
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	97a080e7          	jalr	-1670(ra) # 800016ca <copyin>
    80002d58:	00a03533          	snez	a0,a0
    80002d5c:	40a00533          	neg	a0,a0
}
    80002d60:	60e2                	ld	ra,24(sp)
    80002d62:	6442                	ld	s0,16(sp)
    80002d64:	64a2                	ld	s1,8(sp)
    80002d66:	6902                	ld	s2,0(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret
    return -1;
    80002d6c:	557d                	li	a0,-1
    80002d6e:	bfcd                	j	80002d60 <fetchaddr+0x3e>
    80002d70:	557d                	li	a0,-1
    80002d72:	b7fd                	j	80002d60 <fetchaddr+0x3e>

0000000080002d74 <fetchstr>:
{
    80002d74:	7179                	addi	sp,sp,-48
    80002d76:	f406                	sd	ra,40(sp)
    80002d78:	f022                	sd	s0,32(sp)
    80002d7a:	ec26                	sd	s1,24(sp)
    80002d7c:	e84a                	sd	s2,16(sp)
    80002d7e:	e44e                	sd	s3,8(sp)
    80002d80:	1800                	addi	s0,sp,48
    80002d82:	892a                	mv	s2,a0
    80002d84:	84ae                	mv	s1,a1
    80002d86:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	bf6080e7          	jalr	-1034(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d90:	86ce                	mv	a3,s3
    80002d92:	864a                	mv	a2,s2
    80002d94:	85a6                	mv	a1,s1
    80002d96:	6548                	ld	a0,136(a0)
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	9c0080e7          	jalr	-1600(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002da0:	00054763          	bltz	a0,80002dae <fetchstr+0x3a>
  return strlen(buf);
    80002da4:	8526                	mv	a0,s1
    80002da6:	ffffe097          	auipc	ra,0xffffe
    80002daa:	09c080e7          	jalr	156(ra) # 80000e42 <strlen>
}
    80002dae:	70a2                	ld	ra,40(sp)
    80002db0:	7402                	ld	s0,32(sp)
    80002db2:	64e2                	ld	s1,24(sp)
    80002db4:	6942                	ld	s2,16(sp)
    80002db6:	69a2                	ld	s3,8(sp)
    80002db8:	6145                	addi	sp,sp,48
    80002dba:	8082                	ret

0000000080002dbc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dbc:	1101                	addi	sp,sp,-32
    80002dbe:	ec06                	sd	ra,24(sp)
    80002dc0:	e822                	sd	s0,16(sp)
    80002dc2:	e426                	sd	s1,8(sp)
    80002dc4:	1000                	addi	s0,sp,32
    80002dc6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	ef2080e7          	jalr	-270(ra) # 80002cba <argraw>
    80002dd0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dd2:	4501                	li	a0,0
    80002dd4:	60e2                	ld	ra,24(sp)
    80002dd6:	6442                	ld	s0,16(sp)
    80002dd8:	64a2                	ld	s1,8(sp)
    80002dda:	6105                	addi	sp,sp,32
    80002ddc:	8082                	ret

0000000080002dde <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dde:	1101                	addi	sp,sp,-32
    80002de0:	ec06                	sd	ra,24(sp)
    80002de2:	e822                	sd	s0,16(sp)
    80002de4:	e426                	sd	s1,8(sp)
    80002de6:	1000                	addi	s0,sp,32
    80002de8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	ed0080e7          	jalr	-304(ra) # 80002cba <argraw>
    80002df2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002df4:	4501                	li	a0,0
    80002df6:	60e2                	ld	ra,24(sp)
    80002df8:	6442                	ld	s0,16(sp)
    80002dfa:	64a2                	ld	s1,8(sp)
    80002dfc:	6105                	addi	sp,sp,32
    80002dfe:	8082                	ret

0000000080002e00 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	e426                	sd	s1,8(sp)
    80002e08:	e04a                	sd	s2,0(sp)
    80002e0a:	1000                	addi	s0,sp,32
    80002e0c:	84ae                	mv	s1,a1
    80002e0e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	eaa080e7          	jalr	-342(ra) # 80002cba <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e18:	864a                	mv	a2,s2
    80002e1a:	85a6                	mv	a1,s1
    80002e1c:	00000097          	auipc	ra,0x0
    80002e20:	f58080e7          	jalr	-168(ra) # 80002d74 <fetchstr>
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6902                	ld	s2,0(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <syscall>:
 "unlink", "link", "mkdir", "close", "trace" ,"wait_stat", "set_priority"};


void
syscall(void)
{
    80002e30:	7139                	addi	sp,sp,-64
    80002e32:	fc06                	sd	ra,56(sp)
    80002e34:	f822                	sd	s0,48(sp)
    80002e36:	f426                	sd	s1,40(sp)
    80002e38:	f04a                	sd	s2,32(sp)
    80002e3a:	ec4e                	sd	s3,24(sp)
    80002e3c:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	b40080e7          	jalr	-1216(ra) # 8000197e <myproc>
    80002e46:	892a                	mv	s2,a0
  num = p->trapframe->a7;
    80002e48:	695c                	ld	a5,144(a0)
    80002e4a:	0a87a483          	lw	s1,168(a5)
  int argument = 0;
    80002e4e:	fc042623          	sw	zero,-52(s0)
  if(num == SYS_fork || num == SYS_kill || num == SYS_sbrk)
    80002e52:	47b1                	li	a5,12
    80002e54:	0297e063          	bltu	a5,s1,80002e74 <syscall+0x44>
    80002e58:	6785                	lui	a5,0x1
    80002e5a:	04278793          	addi	a5,a5,66 # 1042 <_entry-0x7fffefbe>
    80002e5e:	0097d7b3          	srl	a5,a5,s1
    80002e62:	8b85                	andi	a5,a5,1
    80002e64:	cb81                	beqz	a5,80002e74 <syscall+0x44>
    argint(0, &argument);
    80002e66:	fcc40593          	addi	a1,s0,-52
    80002e6a:	4501                	li	a0,0
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	f50080e7          	jalr	-176(ra) # 80002dbc <argint>

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e74:	fff4879b          	addiw	a5,s1,-1
    80002e78:	475d                	li	a4,23
    80002e7a:	02f76163          	bltu	a4,a5,80002e9c <syscall+0x6c>
    80002e7e:	00349713          	slli	a4,s1,0x3
    80002e82:	00005797          	auipc	a5,0x5
    80002e86:	6ce78793          	addi	a5,a5,1742 # 80008550 <syscalls>
    80002e8a:	97ba                	add	a5,a5,a4
    80002e8c:	639c                	ld	a5,0(a5)
    80002e8e:	c799                	beqz	a5,80002e9c <syscall+0x6c>
    p->trapframe->a0 = syscalls[num]();
    80002e90:	09093983          	ld	s3,144(s2)
    80002e94:	9782                	jalr	a5
    80002e96:	06a9b823          	sd	a0,112(s3)
    80002e9a:	a015                	j	80002ebe <syscall+0x8e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e9c:	86a6                	mv	a3,s1
    80002e9e:	19090613          	addi	a2,s2,400
    80002ea2:	03092583          	lw	a1,48(s2)
    80002ea6:	00005517          	auipc	a0,0x5
    80002eaa:	55250513          	addi	a0,a0,1362 # 800083f8 <states.0+0x150>
    80002eae:	ffffd097          	auipc	ra,0xffffd
    80002eb2:	6c6080e7          	jalr	1734(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eb6:	09093783          	ld	a5,144(s2)
    80002eba:	577d                	li	a4,-1
    80002ebc:	fbb8                	sd	a4,112(a5)

  int ret = p->trapframe->a0;

  /* If the system calls bit is on in the mask of the process, 
  then print the trace of the system call. */
  if(p->mask & (1 << num)){
    80002ebe:	03492783          	lw	a5,52(s2)
    80002ec2:	4097d7bb          	sraw	a5,a5,s1
    80002ec6:	8b85                	andi	a5,a5,1
    80002ec8:	c3a9                	beqz	a5,80002f0a <syscall+0xda>
  int ret = p->trapframe->a0;
    80002eca:	09093783          	ld	a5,144(s2)
    80002ece:	5bb4                	lw	a3,112(a5)
    if(num == SYS_fork)
    80002ed0:	4785                	li	a5,1
    80002ed2:	04f48363          	beq	s1,a5,80002f18 <syscall+0xe8>
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    else if(num == SYS_kill || num == SYS_sbrk)
    80002ed6:	4799                	li	a5,6
    80002ed8:	00f48563          	beq	s1,a5,80002ee2 <syscall+0xb2>
    80002edc:	47b1                	li	a5,12
    80002ede:	04f49c63          	bne	s1,a5,80002f36 <syscall+0x106>
      printf("%d: syscall %s %d -> %d\n", p->pid, sys_calls_names[num], argument, ret);
    80002ee2:	048e                	slli	s1,s1,0x3
    80002ee4:	00006797          	auipc	a5,0x6
    80002ee8:	a9478793          	addi	a5,a5,-1388 # 80008978 <sys_calls_names>
    80002eec:	94be                	add	s1,s1,a5
    80002eee:	8736                	mv	a4,a3
    80002ef0:	fcc42683          	lw	a3,-52(s0)
    80002ef4:	6090                	ld	a2,0(s1)
    80002ef6:	03092583          	lw	a1,48(s2)
    80002efa:	00005517          	auipc	a0,0x5
    80002efe:	53e50513          	addi	a0,a0,1342 # 80008438 <states.0+0x190>
    80002f02:	ffffd097          	auipc	ra,0xffffd
    80002f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    else
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
  }
}
    80002f0a:	70e2                	ld	ra,56(sp)
    80002f0c:	7442                	ld	s0,48(sp)
    80002f0e:	74a2                	ld	s1,40(sp)
    80002f10:	7902                	ld	s2,32(sp)
    80002f12:	69e2                	ld	s3,24(sp)
    80002f14:	6121                	addi	sp,sp,64
    80002f16:	8082                	ret
      printf("%d: syscall %s NULL -> %d\n", p->pid, sys_calls_names[num], ret);
    80002f18:	00006617          	auipc	a2,0x6
    80002f1c:	a6863603          	ld	a2,-1432(a2) # 80008980 <sys_calls_names+0x8>
    80002f20:	03092583          	lw	a1,48(s2)
    80002f24:	00005517          	auipc	a0,0x5
    80002f28:	4f450513          	addi	a0,a0,1268 # 80008418 <states.0+0x170>
    80002f2c:	ffffd097          	auipc	ra,0xffffd
    80002f30:	648080e7          	jalr	1608(ra) # 80000574 <printf>
    80002f34:	bfd9                	j	80002f0a <syscall+0xda>
      printf("%d: syscall %s -> %d\n", p->pid, sys_calls_names[num], ret);
    80002f36:	048e                	slli	s1,s1,0x3
    80002f38:	00006797          	auipc	a5,0x6
    80002f3c:	a4078793          	addi	a5,a5,-1472 # 80008978 <sys_calls_names>
    80002f40:	94be                	add	s1,s1,a5
    80002f42:	6090                	ld	a2,0(s1)
    80002f44:	03092583          	lw	a1,48(s2)
    80002f48:	00005517          	auipc	a0,0x5
    80002f4c:	51050513          	addi	a0,a0,1296 # 80008458 <states.0+0x1b0>
    80002f50:	ffffd097          	auipc	ra,0xffffd
    80002f54:	624080e7          	jalr	1572(ra) # 80000574 <printf>
}
    80002f58:	bf4d                	j	80002f0a <syscall+0xda>

0000000080002f5a <sys_exit>:
#include "perf.h"


uint64
sys_exit(void)
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f62:	fec40593          	addi	a1,s0,-20
    80002f66:	4501                	li	a0,0
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	e54080e7          	jalr	-428(ra) # 80002dbc <argint>
    return -1;
    80002f70:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f72:	00054963          	bltz	a0,80002f84 <sys_exit+0x2a>
  exit(n);
    80002f76:	fec42503          	lw	a0,-20(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	4d4080e7          	jalr	1236(ra) # 8000244e <exit>
  return 0;  // not reached
    80002f82:	4781                	li	a5,0
}
    80002f84:	853e                	mv	a0,a5
    80002f86:	60e2                	ld	ra,24(sp)
    80002f88:	6442                	ld	s0,16(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret

0000000080002f8e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f8e:	1141                	addi	sp,sp,-16
    80002f90:	e406                	sd	ra,8(sp)
    80002f92:	e022                	sd	s0,0(sp)
    80002f94:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	9e8080e7          	jalr	-1560(ra) # 8000197e <myproc>
}
    80002f9e:	5908                	lw	a0,48(a0)
    80002fa0:	60a2                	ld	ra,8(sp)
    80002fa2:	6402                	ld	s0,0(sp)
    80002fa4:	0141                	addi	sp,sp,16
    80002fa6:	8082                	ret

0000000080002fa8 <sys_fork>:

uint64
sys_fork(void)
{
    80002fa8:	1141                	addi	sp,sp,-16
    80002faa:	e406                	sd	ra,8(sp)
    80002fac:	e022                	sd	s0,0(sp)
    80002fae:	0800                	addi	s0,sp,16
  return fork();
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	de6080e7          	jalr	-538(ra) # 80001d96 <fork>
}
    80002fb8:	60a2                	ld	ra,8(sp)
    80002fba:	6402                	ld	s0,0(sp)
    80002fbc:	0141                	addi	sp,sp,16
    80002fbe:	8082                	ret

0000000080002fc0 <sys_wait>:

uint64
sys_wait(void)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fc8:	fe840593          	addi	a1,s0,-24
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	e10080e7          	jalr	-496(ra) # 80002dde <argaddr>
    80002fd6:	87aa                	mv	a5,a0
    return -1;
    80002fd8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fda:	0007c863          	bltz	a5,80002fea <sys_wait+0x2a>
  return wait(p);
    80002fde:	fe843503          	ld	a0,-24(s0)
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	362080e7          	jalr	866(ra) # 80002344 <wait>
}
    80002fea:	60e2                	ld	ra,24(sp)
    80002fec:	6442                	ld	s0,16(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret

0000000080002ff2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ff2:	7179                	addi	sp,sp,-48
    80002ff4:	f406                	sd	ra,40(sp)
    80002ff6:	f022                	sd	s0,32(sp)
    80002ff8:	ec26                	sd	s1,24(sp)
    80002ffa:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ffc:	fdc40593          	addi	a1,s0,-36
    80003000:	4501                	li	a0,0
    80003002:	00000097          	auipc	ra,0x0
    80003006:	dba080e7          	jalr	-582(ra) # 80002dbc <argint>
    return -1;
    8000300a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000300c:	02054063          	bltz	a0,8000302c <sys_sbrk+0x3a>
  addr = myproc()->sz;
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	96e080e7          	jalr	-1682(ra) # 8000197e <myproc>
    80003018:	08052483          	lw	s1,128(a0)
  if(growproc(n) < 0)
    8000301c:	fdc42503          	lw	a0,-36(s0)
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	d02080e7          	jalr	-766(ra) # 80001d22 <growproc>
    80003028:	00054863          	bltz	a0,80003038 <sys_sbrk+0x46>
    return -1;
  return addr;
}
    8000302c:	8526                	mv	a0,s1
    8000302e:	70a2                	ld	ra,40(sp)
    80003030:	7402                	ld	s0,32(sp)
    80003032:	64e2                	ld	s1,24(sp)
    80003034:	6145                	addi	sp,sp,48
    80003036:	8082                	ret
    return -1;
    80003038:	54fd                	li	s1,-1
    8000303a:	bfcd                	j	8000302c <sys_sbrk+0x3a>

000000008000303c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000303c:	7139                	addi	sp,sp,-64
    8000303e:	fc06                	sd	ra,56(sp)
    80003040:	f822                	sd	s0,48(sp)
    80003042:	f426                	sd	s1,40(sp)
    80003044:	f04a                	sd	s2,32(sp)
    80003046:	ec4e                	sd	s3,24(sp)
    80003048:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000304a:	fcc40593          	addi	a1,s0,-52
    8000304e:	4501                	li	a0,0
    80003050:	00000097          	auipc	ra,0x0
    80003054:	d6c080e7          	jalr	-660(ra) # 80002dbc <argint>
    return -1;
    80003058:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000305a:	06054563          	bltz	a0,800030c4 <sys_sleep+0x88>
  acquire(&tickslock);
    8000305e:	00015517          	auipc	a0,0x15
    80003062:	e7250513          	addi	a0,a0,-398 # 80017ed0 <tickslock>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	b5c080e7          	jalr	-1188(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000306e:	00006917          	auipc	s2,0x6
    80003072:	fc292903          	lw	s2,-62(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003076:	fcc42783          	lw	a5,-52(s0)
    8000307a:	cf85                	beqz	a5,800030b2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000307c:	00015997          	auipc	s3,0x15
    80003080:	e5498993          	addi	s3,s3,-428 # 80017ed0 <tickslock>
    80003084:	00006497          	auipc	s1,0x6
    80003088:	fac48493          	addi	s1,s1,-84 # 80009030 <ticks>
    if(myproc()->killed){
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	8f2080e7          	jalr	-1806(ra) # 8000197e <myproc>
    80003094:	551c                	lw	a5,40(a0)
    80003096:	ef9d                	bnez	a5,800030d4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003098:	85ce                	mv	a1,s3
    8000309a:	8526                	mv	a0,s1
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	04e080e7          	jalr	78(ra) # 800020ea <sleep>
  while(ticks - ticks0 < n){
    800030a4:	409c                	lw	a5,0(s1)
    800030a6:	412787bb          	subw	a5,a5,s2
    800030aa:	fcc42703          	lw	a4,-52(s0)
    800030ae:	fce7efe3          	bltu	a5,a4,8000308c <sys_sleep+0x50>
  }
  release(&tickslock);
    800030b2:	00015517          	auipc	a0,0x15
    800030b6:	e1e50513          	addi	a0,a0,-482 # 80017ed0 <tickslock>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	bbc080e7          	jalr	-1092(ra) # 80000c76 <release>
  return 0;
    800030c2:	4781                	li	a5,0
}
    800030c4:	853e                	mv	a0,a5
    800030c6:	70e2                	ld	ra,56(sp)
    800030c8:	7442                	ld	s0,48(sp)
    800030ca:	74a2                	ld	s1,40(sp)
    800030cc:	7902                	ld	s2,32(sp)
    800030ce:	69e2                	ld	s3,24(sp)
    800030d0:	6121                	addi	sp,sp,64
    800030d2:	8082                	ret
      release(&tickslock);
    800030d4:	00015517          	auipc	a0,0x15
    800030d8:	dfc50513          	addi	a0,a0,-516 # 80017ed0 <tickslock>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	b9a080e7          	jalr	-1126(ra) # 80000c76 <release>
      return -1;
    800030e4:	57fd                	li	a5,-1
    800030e6:	bff9                	j	800030c4 <sys_sleep+0x88>

00000000800030e8 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800030e8:	1101                	addi	sp,sp,-32
    800030ea:	ec06                	sd	ra,24(sp)
    800030ec:	e822                	sd	s0,16(sp)
    800030ee:	1000                	addi	s0,sp,32
  int prio;

  if(argint(0, &prio) < 0)
    800030f0:	fec40593          	addi	a1,s0,-20
    800030f4:	4501                	li	a0,0
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	cc6080e7          	jalr	-826(ra) # 80002dbc <argint>
    800030fe:	87aa                	mv	a5,a0
    return -1;
    80003100:	557d                	li	a0,-1
  if(argint(0, &prio) < 0)
    80003102:	0007c863          	bltz	a5,80003112 <sys_set_priority+0x2a>
  return set_priority(prio);
    80003106:	fec42503          	lw	a0,-20(s0)
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	44c080e7          	jalr	1100(ra) # 80002556 <set_priority>
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <sys_trace>:


uint64
sys_trace(void)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	1000                	addi	s0,sp,32
  int mask;
  int pid;

  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80003122:	fec40593          	addi	a1,s0,-20
    80003126:	4501                	li	a0,0
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	c94080e7          	jalr	-876(ra) # 80002dbc <argint>
    return -1;
    80003130:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80003132:	02054563          	bltz	a0,8000315c <sys_trace+0x42>
    80003136:	fe840593          	addi	a1,s0,-24
    8000313a:	4505                	li	a0,1
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	c80080e7          	jalr	-896(ra) # 80002dbc <argint>
    return -1;
    80003144:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80003146:	00054b63          	bltz	a0,8000315c <sys_trace+0x42>
  return trace(mask, pid);
    8000314a:	fe842583          	lw	a1,-24(s0)
    8000314e:	fec42503          	lw	a0,-20(s0)
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	45c080e7          	jalr	1116(ra) # 800025ae <trace>
    8000315a:	87aa                	mv	a5,a0
}
    8000315c:	853e                	mv	a0,a5
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret

0000000080003166 <sys_kill>:


uint64
sys_kill(void)
{
    80003166:	1101                	addi	sp,sp,-32
    80003168:	ec06                	sd	ra,24(sp)
    8000316a:	e822                	sd	s0,16(sp)
    8000316c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000316e:	fec40593          	addi	a1,s0,-20
    80003172:	4501                	li	a0,0
    80003174:	00000097          	auipc	ra,0x0
    80003178:	c48080e7          	jalr	-952(ra) # 80002dbc <argint>
    8000317c:	87aa                	mv	a5,a0
    return -1;
    8000317e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003180:	0007c863          	bltz	a5,80003190 <sys_kill+0x2a>
  return kill(pid);
    80003184:	fec42503          	lw	a0,-20(s0)
    80003188:	fffff097          	auipc	ra,0xfffff
    8000318c:	486080e7          	jalr	1158(ra) # 8000260e <kill>
}
    80003190:	60e2                	ld	ra,24(sp)
    80003192:	6442                	ld	s0,16(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret

0000000080003198 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031a2:	00015517          	auipc	a0,0x15
    800031a6:	d2e50513          	addi	a0,a0,-722 # 80017ed0 <tickslock>
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	a18080e7          	jalr	-1512(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800031b2:	00006497          	auipc	s1,0x6
    800031b6:	e7e4a483          	lw	s1,-386(s1) # 80009030 <ticks>
  release(&tickslock);
    800031ba:	00015517          	auipc	a0,0x15
    800031be:	d1650513          	addi	a0,a0,-746 # 80017ed0 <tickslock>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	ab4080e7          	jalr	-1356(ra) # 80000c76 <release>
  return xticks;
}
    800031ca:	02049513          	slli	a0,s1,0x20
    800031ce:	9101                	srli	a0,a0,0x20
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret

00000000800031da <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    800031da:	7179                	addi	sp,sp,-48
    800031dc:	f406                	sd	ra,40(sp)
    800031de:	f022                	sd	s0,32(sp)
    800031e0:	ec26                	sd	s1,24(sp)
    800031e2:	1800                	addi	s0,sp,48
  int status;
  struct perf* tmp = (struct perf*) myproc()->trapframe->a1;
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	79a080e7          	jalr	1946(ra) # 8000197e <myproc>
    800031ec:	695c                	ld	a5,144(a0)
    800031ee:	7fa4                	ld	s1,120(a5)
  if(argint(0, &status) < 0)
    800031f0:	fdc40593          	addi	a1,s0,-36
    800031f4:	4501                	li	a0,0
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	bc6080e7          	jalr	-1082(ra) # 80002dbc <argint>
    800031fe:	87aa                	mv	a5,a0
    return -1;
    80003200:	557d                	li	a0,-1
  if(argint(0, &status) < 0)
    80003202:	0007c963          	bltz	a5,80003214 <sys_wait_stat+0x3a>
 
  int x = wait_stat(&status, tmp);
    80003206:	85a6                	mv	a1,s1
    80003208:	fdc40513          	addi	a0,s0,-36
    8000320c:	fffff097          	auipc	ra,0xfffff
    80003210:	5e8080e7          	jalr	1512(ra) # 800027f4 <wait_stat>

  return x;
}
    80003214:	70a2                	ld	ra,40(sp)
    80003216:	7402                	ld	s0,32(sp)
    80003218:	64e2                	ld	s1,24(sp)
    8000321a:	6145                	addi	sp,sp,48
    8000321c:	8082                	ret

000000008000321e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000321e:	7179                	addi	sp,sp,-48
    80003220:	f406                	sd	ra,40(sp)
    80003222:	f022                	sd	s0,32(sp)
    80003224:	ec26                	sd	s1,24(sp)
    80003226:	e84a                	sd	s2,16(sp)
    80003228:	e44e                	sd	s3,8(sp)
    8000322a:	e052                	sd	s4,0(sp)
    8000322c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000322e:	00005597          	auipc	a1,0x5
    80003232:	3ea58593          	addi	a1,a1,1002 # 80008618 <syscalls+0xc8>
    80003236:	00015517          	auipc	a0,0x15
    8000323a:	cb250513          	addi	a0,a0,-846 # 80017ee8 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	8f4080e7          	jalr	-1804(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003246:	0001d797          	auipc	a5,0x1d
    8000324a:	ca278793          	addi	a5,a5,-862 # 8001fee8 <bcache+0x8000>
    8000324e:	0001d717          	auipc	a4,0x1d
    80003252:	f0270713          	addi	a4,a4,-254 # 80020150 <bcache+0x8268>
    80003256:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000325a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000325e:	00015497          	auipc	s1,0x15
    80003262:	ca248493          	addi	s1,s1,-862 # 80017f00 <bcache+0x18>
    b->next = bcache.head.next;
    80003266:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003268:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000326a:	00005a17          	auipc	s4,0x5
    8000326e:	3b6a0a13          	addi	s4,s4,950 # 80008620 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003272:	2b893783          	ld	a5,696(s2)
    80003276:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003278:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000327c:	85d2                	mv	a1,s4
    8000327e:	01048513          	addi	a0,s1,16
    80003282:	00001097          	auipc	ra,0x1
    80003286:	4c2080e7          	jalr	1218(ra) # 80004744 <initsleeplock>
    bcache.head.next->prev = b;
    8000328a:	2b893783          	ld	a5,696(s2)
    8000328e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003290:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003294:	45848493          	addi	s1,s1,1112
    80003298:	fd349de3          	bne	s1,s3,80003272 <binit+0x54>
  }
}
    8000329c:	70a2                	ld	ra,40(sp)
    8000329e:	7402                	ld	s0,32(sp)
    800032a0:	64e2                	ld	s1,24(sp)
    800032a2:	6942                	ld	s2,16(sp)
    800032a4:	69a2                	ld	s3,8(sp)
    800032a6:	6a02                	ld	s4,0(sp)
    800032a8:	6145                	addi	sp,sp,48
    800032aa:	8082                	ret

00000000800032ac <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032ac:	7179                	addi	sp,sp,-48
    800032ae:	f406                	sd	ra,40(sp)
    800032b0:	f022                	sd	s0,32(sp)
    800032b2:	ec26                	sd	s1,24(sp)
    800032b4:	e84a                	sd	s2,16(sp)
    800032b6:	e44e                	sd	s3,8(sp)
    800032b8:	1800                	addi	s0,sp,48
    800032ba:	892a                	mv	s2,a0
    800032bc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032be:	00015517          	auipc	a0,0x15
    800032c2:	c2a50513          	addi	a0,a0,-982 # 80017ee8 <bcache>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	8fc080e7          	jalr	-1796(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032ce:	0001d497          	auipc	s1,0x1d
    800032d2:	ed24b483          	ld	s1,-302(s1) # 800201a0 <bcache+0x82b8>
    800032d6:	0001d797          	auipc	a5,0x1d
    800032da:	e7a78793          	addi	a5,a5,-390 # 80020150 <bcache+0x8268>
    800032de:	02f48f63          	beq	s1,a5,8000331c <bread+0x70>
    800032e2:	873e                	mv	a4,a5
    800032e4:	a021                	j	800032ec <bread+0x40>
    800032e6:	68a4                	ld	s1,80(s1)
    800032e8:	02e48a63          	beq	s1,a4,8000331c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032ec:	449c                	lw	a5,8(s1)
    800032ee:	ff279ce3          	bne	a5,s2,800032e6 <bread+0x3a>
    800032f2:	44dc                	lw	a5,12(s1)
    800032f4:	ff3799e3          	bne	a5,s3,800032e6 <bread+0x3a>
      b->refcnt++;
    800032f8:	40bc                	lw	a5,64(s1)
    800032fa:	2785                	addiw	a5,a5,1
    800032fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032fe:	00015517          	auipc	a0,0x15
    80003302:	bea50513          	addi	a0,a0,-1046 # 80017ee8 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	970080e7          	jalr	-1680(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000330e:	01048513          	addi	a0,s1,16
    80003312:	00001097          	auipc	ra,0x1
    80003316:	46c080e7          	jalr	1132(ra) # 8000477e <acquiresleep>
      return b;
    8000331a:	a8b9                	j	80003378 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000331c:	0001d497          	auipc	s1,0x1d
    80003320:	e7c4b483          	ld	s1,-388(s1) # 80020198 <bcache+0x82b0>
    80003324:	0001d797          	auipc	a5,0x1d
    80003328:	e2c78793          	addi	a5,a5,-468 # 80020150 <bcache+0x8268>
    8000332c:	00f48863          	beq	s1,a5,8000333c <bread+0x90>
    80003330:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003332:	40bc                	lw	a5,64(s1)
    80003334:	cf81                	beqz	a5,8000334c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003336:	64a4                	ld	s1,72(s1)
    80003338:	fee49de3          	bne	s1,a4,80003332 <bread+0x86>
  panic("bget: no buffers");
    8000333c:	00005517          	auipc	a0,0x5
    80003340:	2ec50513          	addi	a0,a0,748 # 80008628 <syscalls+0xd8>
    80003344:	ffffd097          	auipc	ra,0xffffd
    80003348:	1e6080e7          	jalr	486(ra) # 8000052a <panic>
      b->dev = dev;
    8000334c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003350:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003354:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003358:	4785                	li	a5,1
    8000335a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000335c:	00015517          	auipc	a0,0x15
    80003360:	b8c50513          	addi	a0,a0,-1140 # 80017ee8 <bcache>
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	912080e7          	jalr	-1774(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000336c:	01048513          	addi	a0,s1,16
    80003370:	00001097          	auipc	ra,0x1
    80003374:	40e080e7          	jalr	1038(ra) # 8000477e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003378:	409c                	lw	a5,0(s1)
    8000337a:	cb89                	beqz	a5,8000338c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000337c:	8526                	mv	a0,s1
    8000337e:	70a2                	ld	ra,40(sp)
    80003380:	7402                	ld	s0,32(sp)
    80003382:	64e2                	ld	s1,24(sp)
    80003384:	6942                	ld	s2,16(sp)
    80003386:	69a2                	ld	s3,8(sp)
    80003388:	6145                	addi	sp,sp,48
    8000338a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000338c:	4581                	li	a1,0
    8000338e:	8526                	mv	a0,s1
    80003390:	00003097          	auipc	ra,0x3
    80003394:	f26080e7          	jalr	-218(ra) # 800062b6 <virtio_disk_rw>
    b->valid = 1;
    80003398:	4785                	li	a5,1
    8000339a:	c09c                	sw	a5,0(s1)
  return b;
    8000339c:	b7c5                	j	8000337c <bread+0xd0>

000000008000339e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000339e:	1101                	addi	sp,sp,-32
    800033a0:	ec06                	sd	ra,24(sp)
    800033a2:	e822                	sd	s0,16(sp)
    800033a4:	e426                	sd	s1,8(sp)
    800033a6:	1000                	addi	s0,sp,32
    800033a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033aa:	0541                	addi	a0,a0,16
    800033ac:	00001097          	auipc	ra,0x1
    800033b0:	46c080e7          	jalr	1132(ra) # 80004818 <holdingsleep>
    800033b4:	cd01                	beqz	a0,800033cc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033b6:	4585                	li	a1,1
    800033b8:	8526                	mv	a0,s1
    800033ba:	00003097          	auipc	ra,0x3
    800033be:	efc080e7          	jalr	-260(ra) # 800062b6 <virtio_disk_rw>
}
    800033c2:	60e2                	ld	ra,24(sp)
    800033c4:	6442                	ld	s0,16(sp)
    800033c6:	64a2                	ld	s1,8(sp)
    800033c8:	6105                	addi	sp,sp,32
    800033ca:	8082                	ret
    panic("bwrite");
    800033cc:	00005517          	auipc	a0,0x5
    800033d0:	27450513          	addi	a0,a0,628 # 80008640 <syscalls+0xf0>
    800033d4:	ffffd097          	auipc	ra,0xffffd
    800033d8:	156080e7          	jalr	342(ra) # 8000052a <panic>

00000000800033dc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033dc:	1101                	addi	sp,sp,-32
    800033de:	ec06                	sd	ra,24(sp)
    800033e0:	e822                	sd	s0,16(sp)
    800033e2:	e426                	sd	s1,8(sp)
    800033e4:	e04a                	sd	s2,0(sp)
    800033e6:	1000                	addi	s0,sp,32
    800033e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033ea:	01050913          	addi	s2,a0,16
    800033ee:	854a                	mv	a0,s2
    800033f0:	00001097          	auipc	ra,0x1
    800033f4:	428080e7          	jalr	1064(ra) # 80004818 <holdingsleep>
    800033f8:	c92d                	beqz	a0,8000346a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800033fa:	854a                	mv	a0,s2
    800033fc:	00001097          	auipc	ra,0x1
    80003400:	3d8080e7          	jalr	984(ra) # 800047d4 <releasesleep>

  acquire(&bcache.lock);
    80003404:	00015517          	auipc	a0,0x15
    80003408:	ae450513          	addi	a0,a0,-1308 # 80017ee8 <bcache>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	7b6080e7          	jalr	1974(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003414:	40bc                	lw	a5,64(s1)
    80003416:	37fd                	addiw	a5,a5,-1
    80003418:	0007871b          	sext.w	a4,a5
    8000341c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000341e:	eb05                	bnez	a4,8000344e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003420:	68bc                	ld	a5,80(s1)
    80003422:	64b8                	ld	a4,72(s1)
    80003424:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003426:	64bc                	ld	a5,72(s1)
    80003428:	68b8                	ld	a4,80(s1)
    8000342a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000342c:	0001d797          	auipc	a5,0x1d
    80003430:	abc78793          	addi	a5,a5,-1348 # 8001fee8 <bcache+0x8000>
    80003434:	2b87b703          	ld	a4,696(a5)
    80003438:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000343a:	0001d717          	auipc	a4,0x1d
    8000343e:	d1670713          	addi	a4,a4,-746 # 80020150 <bcache+0x8268>
    80003442:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003444:	2b87b703          	ld	a4,696(a5)
    80003448:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000344a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000344e:	00015517          	auipc	a0,0x15
    80003452:	a9a50513          	addi	a0,a0,-1382 # 80017ee8 <bcache>
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	820080e7          	jalr	-2016(ra) # 80000c76 <release>
}
    8000345e:	60e2                	ld	ra,24(sp)
    80003460:	6442                	ld	s0,16(sp)
    80003462:	64a2                	ld	s1,8(sp)
    80003464:	6902                	ld	s2,0(sp)
    80003466:	6105                	addi	sp,sp,32
    80003468:	8082                	ret
    panic("brelse");
    8000346a:	00005517          	auipc	a0,0x5
    8000346e:	1de50513          	addi	a0,a0,478 # 80008648 <syscalls+0xf8>
    80003472:	ffffd097          	auipc	ra,0xffffd
    80003476:	0b8080e7          	jalr	184(ra) # 8000052a <panic>

000000008000347a <bpin>:

void
bpin(struct buf *b) {
    8000347a:	1101                	addi	sp,sp,-32
    8000347c:	ec06                	sd	ra,24(sp)
    8000347e:	e822                	sd	s0,16(sp)
    80003480:	e426                	sd	s1,8(sp)
    80003482:	1000                	addi	s0,sp,32
    80003484:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003486:	00015517          	auipc	a0,0x15
    8000348a:	a6250513          	addi	a0,a0,-1438 # 80017ee8 <bcache>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	734080e7          	jalr	1844(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003496:	40bc                	lw	a5,64(s1)
    80003498:	2785                	addiw	a5,a5,1
    8000349a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000349c:	00015517          	auipc	a0,0x15
    800034a0:	a4c50513          	addi	a0,a0,-1460 # 80017ee8 <bcache>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	7d2080e7          	jalr	2002(ra) # 80000c76 <release>
}
    800034ac:	60e2                	ld	ra,24(sp)
    800034ae:	6442                	ld	s0,16(sp)
    800034b0:	64a2                	ld	s1,8(sp)
    800034b2:	6105                	addi	sp,sp,32
    800034b4:	8082                	ret

00000000800034b6 <bunpin>:

void
bunpin(struct buf *b) {
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034c2:	00015517          	auipc	a0,0x15
    800034c6:	a2650513          	addi	a0,a0,-1498 # 80017ee8 <bcache>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	6f8080e7          	jalr	1784(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800034d2:	40bc                	lw	a5,64(s1)
    800034d4:	37fd                	addiw	a5,a5,-1
    800034d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034d8:	00015517          	auipc	a0,0x15
    800034dc:	a1050513          	addi	a0,a0,-1520 # 80017ee8 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	796080e7          	jalr	1942(ra) # 80000c76 <release>
}
    800034e8:	60e2                	ld	ra,24(sp)
    800034ea:	6442                	ld	s0,16(sp)
    800034ec:	64a2                	ld	s1,8(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret

00000000800034f2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034f2:	1101                	addi	sp,sp,-32
    800034f4:	ec06                	sd	ra,24(sp)
    800034f6:	e822                	sd	s0,16(sp)
    800034f8:	e426                	sd	s1,8(sp)
    800034fa:	e04a                	sd	s2,0(sp)
    800034fc:	1000                	addi	s0,sp,32
    800034fe:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003500:	00d5d59b          	srliw	a1,a1,0xd
    80003504:	0001d797          	auipc	a5,0x1d
    80003508:	0c07a783          	lw	a5,192(a5) # 800205c4 <sb+0x1c>
    8000350c:	9dbd                	addw	a1,a1,a5
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	d9e080e7          	jalr	-610(ra) # 800032ac <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003516:	0074f713          	andi	a4,s1,7
    8000351a:	4785                	li	a5,1
    8000351c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003520:	14ce                	slli	s1,s1,0x33
    80003522:	90d9                	srli	s1,s1,0x36
    80003524:	00950733          	add	a4,a0,s1
    80003528:	05874703          	lbu	a4,88(a4)
    8000352c:	00e7f6b3          	and	a3,a5,a4
    80003530:	c69d                	beqz	a3,8000355e <bfree+0x6c>
    80003532:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003534:	94aa                	add	s1,s1,a0
    80003536:	fff7c793          	not	a5,a5
    8000353a:	8ff9                	and	a5,a5,a4
    8000353c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003540:	00001097          	auipc	ra,0x1
    80003544:	11e080e7          	jalr	286(ra) # 8000465e <log_write>
  brelse(bp);
    80003548:	854a                	mv	a0,s2
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	e92080e7          	jalr	-366(ra) # 800033dc <brelse>
}
    80003552:	60e2                	ld	ra,24(sp)
    80003554:	6442                	ld	s0,16(sp)
    80003556:	64a2                	ld	s1,8(sp)
    80003558:	6902                	ld	s2,0(sp)
    8000355a:	6105                	addi	sp,sp,32
    8000355c:	8082                	ret
    panic("freeing free block");
    8000355e:	00005517          	auipc	a0,0x5
    80003562:	0f250513          	addi	a0,a0,242 # 80008650 <syscalls+0x100>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	fc4080e7          	jalr	-60(ra) # 8000052a <panic>

000000008000356e <balloc>:
{
    8000356e:	711d                	addi	sp,sp,-96
    80003570:	ec86                	sd	ra,88(sp)
    80003572:	e8a2                	sd	s0,80(sp)
    80003574:	e4a6                	sd	s1,72(sp)
    80003576:	e0ca                	sd	s2,64(sp)
    80003578:	fc4e                	sd	s3,56(sp)
    8000357a:	f852                	sd	s4,48(sp)
    8000357c:	f456                	sd	s5,40(sp)
    8000357e:	f05a                	sd	s6,32(sp)
    80003580:	ec5e                	sd	s7,24(sp)
    80003582:	e862                	sd	s8,16(sp)
    80003584:	e466                	sd	s9,8(sp)
    80003586:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003588:	0001d797          	auipc	a5,0x1d
    8000358c:	0247a783          	lw	a5,36(a5) # 800205ac <sb+0x4>
    80003590:	cbd1                	beqz	a5,80003624 <balloc+0xb6>
    80003592:	8baa                	mv	s7,a0
    80003594:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003596:	0001db17          	auipc	s6,0x1d
    8000359a:	012b0b13          	addi	s6,s6,18 # 800205a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035a0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035a2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035a4:	6c89                	lui	s9,0x2
    800035a6:	a831                	j	800035c2 <balloc+0x54>
    brelse(bp);
    800035a8:	854a                	mv	a0,s2
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	e32080e7          	jalr	-462(ra) # 800033dc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035b2:	015c87bb          	addw	a5,s9,s5
    800035b6:	00078a9b          	sext.w	s5,a5
    800035ba:	004b2703          	lw	a4,4(s6)
    800035be:	06eaf363          	bgeu	s5,a4,80003624 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800035c2:	41fad79b          	sraiw	a5,s5,0x1f
    800035c6:	0137d79b          	srliw	a5,a5,0x13
    800035ca:	015787bb          	addw	a5,a5,s5
    800035ce:	40d7d79b          	sraiw	a5,a5,0xd
    800035d2:	01cb2583          	lw	a1,28(s6)
    800035d6:	9dbd                	addw	a1,a1,a5
    800035d8:	855e                	mv	a0,s7
    800035da:	00000097          	auipc	ra,0x0
    800035de:	cd2080e7          	jalr	-814(ra) # 800032ac <bread>
    800035e2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e4:	004b2503          	lw	a0,4(s6)
    800035e8:	000a849b          	sext.w	s1,s5
    800035ec:	8662                	mv	a2,s8
    800035ee:	faa4fde3          	bgeu	s1,a0,800035a8 <balloc+0x3a>
      m = 1 << (bi % 8);
    800035f2:	41f6579b          	sraiw	a5,a2,0x1f
    800035f6:	01d7d69b          	srliw	a3,a5,0x1d
    800035fa:	00c6873b          	addw	a4,a3,a2
    800035fe:	00777793          	andi	a5,a4,7
    80003602:	9f95                	subw	a5,a5,a3
    80003604:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003608:	4037571b          	sraiw	a4,a4,0x3
    8000360c:	00e906b3          	add	a3,s2,a4
    80003610:	0586c683          	lbu	a3,88(a3)
    80003614:	00d7f5b3          	and	a1,a5,a3
    80003618:	cd91                	beqz	a1,80003634 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000361a:	2605                	addiw	a2,a2,1
    8000361c:	2485                	addiw	s1,s1,1
    8000361e:	fd4618e3          	bne	a2,s4,800035ee <balloc+0x80>
    80003622:	b759                	j	800035a8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003624:	00005517          	auipc	a0,0x5
    80003628:	04450513          	addi	a0,a0,68 # 80008668 <syscalls+0x118>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	efe080e7          	jalr	-258(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003634:	974a                	add	a4,a4,s2
    80003636:	8fd5                	or	a5,a5,a3
    80003638:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000363c:	854a                	mv	a0,s2
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	020080e7          	jalr	32(ra) # 8000465e <log_write>
        brelse(bp);
    80003646:	854a                	mv	a0,s2
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	d94080e7          	jalr	-620(ra) # 800033dc <brelse>
  bp = bread(dev, bno);
    80003650:	85a6                	mv	a1,s1
    80003652:	855e                	mv	a0,s7
    80003654:	00000097          	auipc	ra,0x0
    80003658:	c58080e7          	jalr	-936(ra) # 800032ac <bread>
    8000365c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000365e:	40000613          	li	a2,1024
    80003662:	4581                	li	a1,0
    80003664:	05850513          	addi	a0,a0,88
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	656080e7          	jalr	1622(ra) # 80000cbe <memset>
  log_write(bp);
    80003670:	854a                	mv	a0,s2
    80003672:	00001097          	auipc	ra,0x1
    80003676:	fec080e7          	jalr	-20(ra) # 8000465e <log_write>
  brelse(bp);
    8000367a:	854a                	mv	a0,s2
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	d60080e7          	jalr	-672(ra) # 800033dc <brelse>
}
    80003684:	8526                	mv	a0,s1
    80003686:	60e6                	ld	ra,88(sp)
    80003688:	6446                	ld	s0,80(sp)
    8000368a:	64a6                	ld	s1,72(sp)
    8000368c:	6906                	ld	s2,64(sp)
    8000368e:	79e2                	ld	s3,56(sp)
    80003690:	7a42                	ld	s4,48(sp)
    80003692:	7aa2                	ld	s5,40(sp)
    80003694:	7b02                	ld	s6,32(sp)
    80003696:	6be2                	ld	s7,24(sp)
    80003698:	6c42                	ld	s8,16(sp)
    8000369a:	6ca2                	ld	s9,8(sp)
    8000369c:	6125                	addi	sp,sp,96
    8000369e:	8082                	ret

00000000800036a0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036a0:	7179                	addi	sp,sp,-48
    800036a2:	f406                	sd	ra,40(sp)
    800036a4:	f022                	sd	s0,32(sp)
    800036a6:	ec26                	sd	s1,24(sp)
    800036a8:	e84a                	sd	s2,16(sp)
    800036aa:	e44e                	sd	s3,8(sp)
    800036ac:	e052                	sd	s4,0(sp)
    800036ae:	1800                	addi	s0,sp,48
    800036b0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036b2:	47ad                	li	a5,11
    800036b4:	04b7fe63          	bgeu	a5,a1,80003710 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036b8:	ff45849b          	addiw	s1,a1,-12
    800036bc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036c0:	0ff00793          	li	a5,255
    800036c4:	0ae7e463          	bltu	a5,a4,8000376c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036c8:	08052583          	lw	a1,128(a0)
    800036cc:	c5b5                	beqz	a1,80003738 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800036ce:	00092503          	lw	a0,0(s2)
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	bda080e7          	jalr	-1062(ra) # 800032ac <bread>
    800036da:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036dc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036e0:	02049713          	slli	a4,s1,0x20
    800036e4:	01e75593          	srli	a1,a4,0x1e
    800036e8:	00b784b3          	add	s1,a5,a1
    800036ec:	0004a983          	lw	s3,0(s1)
    800036f0:	04098e63          	beqz	s3,8000374c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800036f4:	8552                	mv	a0,s4
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	ce6080e7          	jalr	-794(ra) # 800033dc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036fe:	854e                	mv	a0,s3
    80003700:	70a2                	ld	ra,40(sp)
    80003702:	7402                	ld	s0,32(sp)
    80003704:	64e2                	ld	s1,24(sp)
    80003706:	6942                	ld	s2,16(sp)
    80003708:	69a2                	ld	s3,8(sp)
    8000370a:	6a02                	ld	s4,0(sp)
    8000370c:	6145                	addi	sp,sp,48
    8000370e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003710:	02059793          	slli	a5,a1,0x20
    80003714:	01e7d593          	srli	a1,a5,0x1e
    80003718:	00b504b3          	add	s1,a0,a1
    8000371c:	0504a983          	lw	s3,80(s1)
    80003720:	fc099fe3          	bnez	s3,800036fe <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003724:	4108                	lw	a0,0(a0)
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	e48080e7          	jalr	-440(ra) # 8000356e <balloc>
    8000372e:	0005099b          	sext.w	s3,a0
    80003732:	0534a823          	sw	s3,80(s1)
    80003736:	b7e1                	j	800036fe <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003738:	4108                	lw	a0,0(a0)
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	e34080e7          	jalr	-460(ra) # 8000356e <balloc>
    80003742:	0005059b          	sext.w	a1,a0
    80003746:	08b92023          	sw	a1,128(s2)
    8000374a:	b751                	j	800036ce <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000374c:	00092503          	lw	a0,0(s2)
    80003750:	00000097          	auipc	ra,0x0
    80003754:	e1e080e7          	jalr	-482(ra) # 8000356e <balloc>
    80003758:	0005099b          	sext.w	s3,a0
    8000375c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003760:	8552                	mv	a0,s4
    80003762:	00001097          	auipc	ra,0x1
    80003766:	efc080e7          	jalr	-260(ra) # 8000465e <log_write>
    8000376a:	b769                	j	800036f4 <bmap+0x54>
  panic("bmap: out of range");
    8000376c:	00005517          	auipc	a0,0x5
    80003770:	f1450513          	addi	a0,a0,-236 # 80008680 <syscalls+0x130>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	db6080e7          	jalr	-586(ra) # 8000052a <panic>

000000008000377c <iget>:
{
    8000377c:	7179                	addi	sp,sp,-48
    8000377e:	f406                	sd	ra,40(sp)
    80003780:	f022                	sd	s0,32(sp)
    80003782:	ec26                	sd	s1,24(sp)
    80003784:	e84a                	sd	s2,16(sp)
    80003786:	e44e                	sd	s3,8(sp)
    80003788:	e052                	sd	s4,0(sp)
    8000378a:	1800                	addi	s0,sp,48
    8000378c:	89aa                	mv	s3,a0
    8000378e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003790:	0001d517          	auipc	a0,0x1d
    80003794:	e3850513          	addi	a0,a0,-456 # 800205c8 <itable>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	42a080e7          	jalr	1066(ra) # 80000bc2 <acquire>
  empty = 0;
    800037a0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037a2:	0001d497          	auipc	s1,0x1d
    800037a6:	e3e48493          	addi	s1,s1,-450 # 800205e0 <itable+0x18>
    800037aa:	0001f697          	auipc	a3,0x1f
    800037ae:	8c668693          	addi	a3,a3,-1850 # 80022070 <log>
    800037b2:	a039                	j	800037c0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037b4:	02090b63          	beqz	s2,800037ea <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037b8:	08848493          	addi	s1,s1,136
    800037bc:	02d48a63          	beq	s1,a3,800037f0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037c0:	449c                	lw	a5,8(s1)
    800037c2:	fef059e3          	blez	a5,800037b4 <iget+0x38>
    800037c6:	4098                	lw	a4,0(s1)
    800037c8:	ff3716e3          	bne	a4,s3,800037b4 <iget+0x38>
    800037cc:	40d8                	lw	a4,4(s1)
    800037ce:	ff4713e3          	bne	a4,s4,800037b4 <iget+0x38>
      ip->ref++;
    800037d2:	2785                	addiw	a5,a5,1
    800037d4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037d6:	0001d517          	auipc	a0,0x1d
    800037da:	df250513          	addi	a0,a0,-526 # 800205c8 <itable>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	498080e7          	jalr	1176(ra) # 80000c76 <release>
      return ip;
    800037e6:	8926                	mv	s2,s1
    800037e8:	a03d                	j	80003816 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037ea:	f7f9                	bnez	a5,800037b8 <iget+0x3c>
    800037ec:	8926                	mv	s2,s1
    800037ee:	b7e9                	j	800037b8 <iget+0x3c>
  if(empty == 0)
    800037f0:	02090c63          	beqz	s2,80003828 <iget+0xac>
  ip->dev = dev;
    800037f4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037f8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037fc:	4785                	li	a5,1
    800037fe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003802:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003806:	0001d517          	auipc	a0,0x1d
    8000380a:	dc250513          	addi	a0,a0,-574 # 800205c8 <itable>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	468080e7          	jalr	1128(ra) # 80000c76 <release>
}
    80003816:	854a                	mv	a0,s2
    80003818:	70a2                	ld	ra,40(sp)
    8000381a:	7402                	ld	s0,32(sp)
    8000381c:	64e2                	ld	s1,24(sp)
    8000381e:	6942                	ld	s2,16(sp)
    80003820:	69a2                	ld	s3,8(sp)
    80003822:	6a02                	ld	s4,0(sp)
    80003824:	6145                	addi	sp,sp,48
    80003826:	8082                	ret
    panic("iget: no inodes");
    80003828:	00005517          	auipc	a0,0x5
    8000382c:	e7050513          	addi	a0,a0,-400 # 80008698 <syscalls+0x148>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	cfa080e7          	jalr	-774(ra) # 8000052a <panic>

0000000080003838 <fsinit>:
fsinit(int dev) {
    80003838:	7179                	addi	sp,sp,-48
    8000383a:	f406                	sd	ra,40(sp)
    8000383c:	f022                	sd	s0,32(sp)
    8000383e:	ec26                	sd	s1,24(sp)
    80003840:	e84a                	sd	s2,16(sp)
    80003842:	e44e                	sd	s3,8(sp)
    80003844:	1800                	addi	s0,sp,48
    80003846:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003848:	4585                	li	a1,1
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	a62080e7          	jalr	-1438(ra) # 800032ac <bread>
    80003852:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003854:	0001d997          	auipc	s3,0x1d
    80003858:	d5498993          	addi	s3,s3,-684 # 800205a8 <sb>
    8000385c:	02000613          	li	a2,32
    80003860:	05850593          	addi	a1,a0,88
    80003864:	854e                	mv	a0,s3
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	4b4080e7          	jalr	1204(ra) # 80000d1a <memmove>
  brelse(bp);
    8000386e:	8526                	mv	a0,s1
    80003870:	00000097          	auipc	ra,0x0
    80003874:	b6c080e7          	jalr	-1172(ra) # 800033dc <brelse>
  if(sb.magic != FSMAGIC)
    80003878:	0009a703          	lw	a4,0(s3)
    8000387c:	102037b7          	lui	a5,0x10203
    80003880:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003884:	02f71263          	bne	a4,a5,800038a8 <fsinit+0x70>
  initlog(dev, &sb);
    80003888:	0001d597          	auipc	a1,0x1d
    8000388c:	d2058593          	addi	a1,a1,-736 # 800205a8 <sb>
    80003890:	854a                	mv	a0,s2
    80003892:	00001097          	auipc	ra,0x1
    80003896:	b4e080e7          	jalr	-1202(ra) # 800043e0 <initlog>
}
    8000389a:	70a2                	ld	ra,40(sp)
    8000389c:	7402                	ld	s0,32(sp)
    8000389e:	64e2                	ld	s1,24(sp)
    800038a0:	6942                	ld	s2,16(sp)
    800038a2:	69a2                	ld	s3,8(sp)
    800038a4:	6145                	addi	sp,sp,48
    800038a6:	8082                	ret
    panic("invalid file system");
    800038a8:	00005517          	auipc	a0,0x5
    800038ac:	e0050513          	addi	a0,a0,-512 # 800086a8 <syscalls+0x158>
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	c7a080e7          	jalr	-902(ra) # 8000052a <panic>

00000000800038b8 <iinit>:
{
    800038b8:	7179                	addi	sp,sp,-48
    800038ba:	f406                	sd	ra,40(sp)
    800038bc:	f022                	sd	s0,32(sp)
    800038be:	ec26                	sd	s1,24(sp)
    800038c0:	e84a                	sd	s2,16(sp)
    800038c2:	e44e                	sd	s3,8(sp)
    800038c4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038c6:	00005597          	auipc	a1,0x5
    800038ca:	dfa58593          	addi	a1,a1,-518 # 800086c0 <syscalls+0x170>
    800038ce:	0001d517          	auipc	a0,0x1d
    800038d2:	cfa50513          	addi	a0,a0,-774 # 800205c8 <itable>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	25c080e7          	jalr	604(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038de:	0001d497          	auipc	s1,0x1d
    800038e2:	d1248493          	addi	s1,s1,-750 # 800205f0 <itable+0x28>
    800038e6:	0001e997          	auipc	s3,0x1e
    800038ea:	79a98993          	addi	s3,s3,1946 # 80022080 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038ee:	00005917          	auipc	s2,0x5
    800038f2:	dda90913          	addi	s2,s2,-550 # 800086c8 <syscalls+0x178>
    800038f6:	85ca                	mv	a1,s2
    800038f8:	8526                	mv	a0,s1
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	e4a080e7          	jalr	-438(ra) # 80004744 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003902:	08848493          	addi	s1,s1,136
    80003906:	ff3498e3          	bne	s1,s3,800038f6 <iinit+0x3e>
}
    8000390a:	70a2                	ld	ra,40(sp)
    8000390c:	7402                	ld	s0,32(sp)
    8000390e:	64e2                	ld	s1,24(sp)
    80003910:	6942                	ld	s2,16(sp)
    80003912:	69a2                	ld	s3,8(sp)
    80003914:	6145                	addi	sp,sp,48
    80003916:	8082                	ret

0000000080003918 <ialloc>:
{
    80003918:	715d                	addi	sp,sp,-80
    8000391a:	e486                	sd	ra,72(sp)
    8000391c:	e0a2                	sd	s0,64(sp)
    8000391e:	fc26                	sd	s1,56(sp)
    80003920:	f84a                	sd	s2,48(sp)
    80003922:	f44e                	sd	s3,40(sp)
    80003924:	f052                	sd	s4,32(sp)
    80003926:	ec56                	sd	s5,24(sp)
    80003928:	e85a                	sd	s6,16(sp)
    8000392a:	e45e                	sd	s7,8(sp)
    8000392c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000392e:	0001d717          	auipc	a4,0x1d
    80003932:	c8672703          	lw	a4,-890(a4) # 800205b4 <sb+0xc>
    80003936:	4785                	li	a5,1
    80003938:	04e7fa63          	bgeu	a5,a4,8000398c <ialloc+0x74>
    8000393c:	8aaa                	mv	s5,a0
    8000393e:	8bae                	mv	s7,a1
    80003940:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003942:	0001da17          	auipc	s4,0x1d
    80003946:	c66a0a13          	addi	s4,s4,-922 # 800205a8 <sb>
    8000394a:	00048b1b          	sext.w	s6,s1
    8000394e:	0044d793          	srli	a5,s1,0x4
    80003952:	018a2583          	lw	a1,24(s4)
    80003956:	9dbd                	addw	a1,a1,a5
    80003958:	8556                	mv	a0,s5
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	952080e7          	jalr	-1710(ra) # 800032ac <bread>
    80003962:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003964:	05850993          	addi	s3,a0,88
    80003968:	00f4f793          	andi	a5,s1,15
    8000396c:	079a                	slli	a5,a5,0x6
    8000396e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003970:	00099783          	lh	a5,0(s3)
    80003974:	c785                	beqz	a5,8000399c <ialloc+0x84>
    brelse(bp);
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	a66080e7          	jalr	-1434(ra) # 800033dc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000397e:	0485                	addi	s1,s1,1
    80003980:	00ca2703          	lw	a4,12(s4)
    80003984:	0004879b          	sext.w	a5,s1
    80003988:	fce7e1e3          	bltu	a5,a4,8000394a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	d4450513          	addi	a0,a0,-700 # 800086d0 <syscalls+0x180>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	b96080e7          	jalr	-1130(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    8000399c:	04000613          	li	a2,64
    800039a0:	4581                	li	a1,0
    800039a2:	854e                	mv	a0,s3
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	31a080e7          	jalr	794(ra) # 80000cbe <memset>
      dip->type = type;
    800039ac:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039b0:	854a                	mv	a0,s2
    800039b2:	00001097          	auipc	ra,0x1
    800039b6:	cac080e7          	jalr	-852(ra) # 8000465e <log_write>
      brelse(bp);
    800039ba:	854a                	mv	a0,s2
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	a20080e7          	jalr	-1504(ra) # 800033dc <brelse>
      return iget(dev, inum);
    800039c4:	85da                	mv	a1,s6
    800039c6:	8556                	mv	a0,s5
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	db4080e7          	jalr	-588(ra) # 8000377c <iget>
}
    800039d0:	60a6                	ld	ra,72(sp)
    800039d2:	6406                	ld	s0,64(sp)
    800039d4:	74e2                	ld	s1,56(sp)
    800039d6:	7942                	ld	s2,48(sp)
    800039d8:	79a2                	ld	s3,40(sp)
    800039da:	7a02                	ld	s4,32(sp)
    800039dc:	6ae2                	ld	s5,24(sp)
    800039de:	6b42                	ld	s6,16(sp)
    800039e0:	6ba2                	ld	s7,8(sp)
    800039e2:	6161                	addi	sp,sp,80
    800039e4:	8082                	ret

00000000800039e6 <iupdate>:
{
    800039e6:	1101                	addi	sp,sp,-32
    800039e8:	ec06                	sd	ra,24(sp)
    800039ea:	e822                	sd	s0,16(sp)
    800039ec:	e426                	sd	s1,8(sp)
    800039ee:	e04a                	sd	s2,0(sp)
    800039f0:	1000                	addi	s0,sp,32
    800039f2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039f4:	415c                	lw	a5,4(a0)
    800039f6:	0047d79b          	srliw	a5,a5,0x4
    800039fa:	0001d597          	auipc	a1,0x1d
    800039fe:	bc65a583          	lw	a1,-1082(a1) # 800205c0 <sb+0x18>
    80003a02:	9dbd                	addw	a1,a1,a5
    80003a04:	4108                	lw	a0,0(a0)
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	8a6080e7          	jalr	-1882(ra) # 800032ac <bread>
    80003a0e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a10:	05850793          	addi	a5,a0,88
    80003a14:	40c8                	lw	a0,4(s1)
    80003a16:	893d                	andi	a0,a0,15
    80003a18:	051a                	slli	a0,a0,0x6
    80003a1a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a1c:	04449703          	lh	a4,68(s1)
    80003a20:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a24:	04649703          	lh	a4,70(s1)
    80003a28:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a2c:	04849703          	lh	a4,72(s1)
    80003a30:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a34:	04a49703          	lh	a4,74(s1)
    80003a38:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a3c:	44f8                	lw	a4,76(s1)
    80003a3e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a40:	03400613          	li	a2,52
    80003a44:	05048593          	addi	a1,s1,80
    80003a48:	0531                	addi	a0,a0,12
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	2d0080e7          	jalr	720(ra) # 80000d1a <memmove>
  log_write(bp);
    80003a52:	854a                	mv	a0,s2
    80003a54:	00001097          	auipc	ra,0x1
    80003a58:	c0a080e7          	jalr	-1014(ra) # 8000465e <log_write>
  brelse(bp);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	97e080e7          	jalr	-1666(ra) # 800033dc <brelse>
}
    80003a66:	60e2                	ld	ra,24(sp)
    80003a68:	6442                	ld	s0,16(sp)
    80003a6a:	64a2                	ld	s1,8(sp)
    80003a6c:	6902                	ld	s2,0(sp)
    80003a6e:	6105                	addi	sp,sp,32
    80003a70:	8082                	ret

0000000080003a72 <idup>:
{
    80003a72:	1101                	addi	sp,sp,-32
    80003a74:	ec06                	sd	ra,24(sp)
    80003a76:	e822                	sd	s0,16(sp)
    80003a78:	e426                	sd	s1,8(sp)
    80003a7a:	1000                	addi	s0,sp,32
    80003a7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a7e:	0001d517          	auipc	a0,0x1d
    80003a82:	b4a50513          	addi	a0,a0,-1206 # 800205c8 <itable>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	13c080e7          	jalr	316(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003a8e:	449c                	lw	a5,8(s1)
    80003a90:	2785                	addiw	a5,a5,1
    80003a92:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a94:	0001d517          	auipc	a0,0x1d
    80003a98:	b3450513          	addi	a0,a0,-1228 # 800205c8 <itable>
    80003a9c:	ffffd097          	auipc	ra,0xffffd
    80003aa0:	1da080e7          	jalr	474(ra) # 80000c76 <release>
}
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	60e2                	ld	ra,24(sp)
    80003aa8:	6442                	ld	s0,16(sp)
    80003aaa:	64a2                	ld	s1,8(sp)
    80003aac:	6105                	addi	sp,sp,32
    80003aae:	8082                	ret

0000000080003ab0 <ilock>:
{
    80003ab0:	1101                	addi	sp,sp,-32
    80003ab2:	ec06                	sd	ra,24(sp)
    80003ab4:	e822                	sd	s0,16(sp)
    80003ab6:	e426                	sd	s1,8(sp)
    80003ab8:	e04a                	sd	s2,0(sp)
    80003aba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003abc:	c115                	beqz	a0,80003ae0 <ilock+0x30>
    80003abe:	84aa                	mv	s1,a0
    80003ac0:	451c                	lw	a5,8(a0)
    80003ac2:	00f05f63          	blez	a5,80003ae0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ac6:	0541                	addi	a0,a0,16
    80003ac8:	00001097          	auipc	ra,0x1
    80003acc:	cb6080e7          	jalr	-842(ra) # 8000477e <acquiresleep>
  if(ip->valid == 0){
    80003ad0:	40bc                	lw	a5,64(s1)
    80003ad2:	cf99                	beqz	a5,80003af0 <ilock+0x40>
}
    80003ad4:	60e2                	ld	ra,24(sp)
    80003ad6:	6442                	ld	s0,16(sp)
    80003ad8:	64a2                	ld	s1,8(sp)
    80003ada:	6902                	ld	s2,0(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret
    panic("ilock");
    80003ae0:	00005517          	auipc	a0,0x5
    80003ae4:	c0850513          	addi	a0,a0,-1016 # 800086e8 <syscalls+0x198>
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	a42080e7          	jalr	-1470(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003af0:	40dc                	lw	a5,4(s1)
    80003af2:	0047d79b          	srliw	a5,a5,0x4
    80003af6:	0001d597          	auipc	a1,0x1d
    80003afa:	aca5a583          	lw	a1,-1334(a1) # 800205c0 <sb+0x18>
    80003afe:	9dbd                	addw	a1,a1,a5
    80003b00:	4088                	lw	a0,0(s1)
    80003b02:	fffff097          	auipc	ra,0xfffff
    80003b06:	7aa080e7          	jalr	1962(ra) # 800032ac <bread>
    80003b0a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b0c:	05850593          	addi	a1,a0,88
    80003b10:	40dc                	lw	a5,4(s1)
    80003b12:	8bbd                	andi	a5,a5,15
    80003b14:	079a                	slli	a5,a5,0x6
    80003b16:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b18:	00059783          	lh	a5,0(a1)
    80003b1c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b20:	00259783          	lh	a5,2(a1)
    80003b24:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b28:	00459783          	lh	a5,4(a1)
    80003b2c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b30:	00659783          	lh	a5,6(a1)
    80003b34:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b38:	459c                	lw	a5,8(a1)
    80003b3a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b3c:	03400613          	li	a2,52
    80003b40:	05b1                	addi	a1,a1,12
    80003b42:	05048513          	addi	a0,s1,80
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	1d4080e7          	jalr	468(ra) # 80000d1a <memmove>
    brelse(bp);
    80003b4e:	854a                	mv	a0,s2
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	88c080e7          	jalr	-1908(ra) # 800033dc <brelse>
    ip->valid = 1;
    80003b58:	4785                	li	a5,1
    80003b5a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b5c:	04449783          	lh	a5,68(s1)
    80003b60:	fbb5                	bnez	a5,80003ad4 <ilock+0x24>
      panic("ilock: no type");
    80003b62:	00005517          	auipc	a0,0x5
    80003b66:	b8e50513          	addi	a0,a0,-1138 # 800086f0 <syscalls+0x1a0>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	9c0080e7          	jalr	-1600(ra) # 8000052a <panic>

0000000080003b72 <iunlock>:
{
    80003b72:	1101                	addi	sp,sp,-32
    80003b74:	ec06                	sd	ra,24(sp)
    80003b76:	e822                	sd	s0,16(sp)
    80003b78:	e426                	sd	s1,8(sp)
    80003b7a:	e04a                	sd	s2,0(sp)
    80003b7c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b7e:	c905                	beqz	a0,80003bae <iunlock+0x3c>
    80003b80:	84aa                	mv	s1,a0
    80003b82:	01050913          	addi	s2,a0,16
    80003b86:	854a                	mv	a0,s2
    80003b88:	00001097          	auipc	ra,0x1
    80003b8c:	c90080e7          	jalr	-880(ra) # 80004818 <holdingsleep>
    80003b90:	cd19                	beqz	a0,80003bae <iunlock+0x3c>
    80003b92:	449c                	lw	a5,8(s1)
    80003b94:	00f05d63          	blez	a5,80003bae <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b98:	854a                	mv	a0,s2
    80003b9a:	00001097          	auipc	ra,0x1
    80003b9e:	c3a080e7          	jalr	-966(ra) # 800047d4 <releasesleep>
}
    80003ba2:	60e2                	ld	ra,24(sp)
    80003ba4:	6442                	ld	s0,16(sp)
    80003ba6:	64a2                	ld	s1,8(sp)
    80003ba8:	6902                	ld	s2,0(sp)
    80003baa:	6105                	addi	sp,sp,32
    80003bac:	8082                	ret
    panic("iunlock");
    80003bae:	00005517          	auipc	a0,0x5
    80003bb2:	b5250513          	addi	a0,a0,-1198 # 80008700 <syscalls+0x1b0>
    80003bb6:	ffffd097          	auipc	ra,0xffffd
    80003bba:	974080e7          	jalr	-1676(ra) # 8000052a <panic>

0000000080003bbe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bbe:	7179                	addi	sp,sp,-48
    80003bc0:	f406                	sd	ra,40(sp)
    80003bc2:	f022                	sd	s0,32(sp)
    80003bc4:	ec26                	sd	s1,24(sp)
    80003bc6:	e84a                	sd	s2,16(sp)
    80003bc8:	e44e                	sd	s3,8(sp)
    80003bca:	e052                	sd	s4,0(sp)
    80003bcc:	1800                	addi	s0,sp,48
    80003bce:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bd0:	05050493          	addi	s1,a0,80
    80003bd4:	08050913          	addi	s2,a0,128
    80003bd8:	a021                	j	80003be0 <itrunc+0x22>
    80003bda:	0491                	addi	s1,s1,4
    80003bdc:	01248d63          	beq	s1,s2,80003bf6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003be0:	408c                	lw	a1,0(s1)
    80003be2:	dde5                	beqz	a1,80003bda <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003be4:	0009a503          	lw	a0,0(s3)
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	90a080e7          	jalr	-1782(ra) # 800034f2 <bfree>
      ip->addrs[i] = 0;
    80003bf0:	0004a023          	sw	zero,0(s1)
    80003bf4:	b7dd                	j	80003bda <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003bf6:	0809a583          	lw	a1,128(s3)
    80003bfa:	e185                	bnez	a1,80003c1a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bfc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c00:	854e                	mv	a0,s3
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	de4080e7          	jalr	-540(ra) # 800039e6 <iupdate>
}
    80003c0a:	70a2                	ld	ra,40(sp)
    80003c0c:	7402                	ld	s0,32(sp)
    80003c0e:	64e2                	ld	s1,24(sp)
    80003c10:	6942                	ld	s2,16(sp)
    80003c12:	69a2                	ld	s3,8(sp)
    80003c14:	6a02                	ld	s4,0(sp)
    80003c16:	6145                	addi	sp,sp,48
    80003c18:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c1a:	0009a503          	lw	a0,0(s3)
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	68e080e7          	jalr	1678(ra) # 800032ac <bread>
    80003c26:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c28:	05850493          	addi	s1,a0,88
    80003c2c:	45850913          	addi	s2,a0,1112
    80003c30:	a021                	j	80003c38 <itrunc+0x7a>
    80003c32:	0491                	addi	s1,s1,4
    80003c34:	01248b63          	beq	s1,s2,80003c4a <itrunc+0x8c>
      if(a[j])
    80003c38:	408c                	lw	a1,0(s1)
    80003c3a:	dde5                	beqz	a1,80003c32 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c3c:	0009a503          	lw	a0,0(s3)
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	8b2080e7          	jalr	-1870(ra) # 800034f2 <bfree>
    80003c48:	b7ed                	j	80003c32 <itrunc+0x74>
    brelse(bp);
    80003c4a:	8552                	mv	a0,s4
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	790080e7          	jalr	1936(ra) # 800033dc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c54:	0809a583          	lw	a1,128(s3)
    80003c58:	0009a503          	lw	a0,0(s3)
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	896080e7          	jalr	-1898(ra) # 800034f2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c64:	0809a023          	sw	zero,128(s3)
    80003c68:	bf51                	j	80003bfc <itrunc+0x3e>

0000000080003c6a <iput>:
{
    80003c6a:	1101                	addi	sp,sp,-32
    80003c6c:	ec06                	sd	ra,24(sp)
    80003c6e:	e822                	sd	s0,16(sp)
    80003c70:	e426                	sd	s1,8(sp)
    80003c72:	e04a                	sd	s2,0(sp)
    80003c74:	1000                	addi	s0,sp,32
    80003c76:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c78:	0001d517          	auipc	a0,0x1d
    80003c7c:	95050513          	addi	a0,a0,-1712 # 800205c8 <itable>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	f42080e7          	jalr	-190(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c88:	4498                	lw	a4,8(s1)
    80003c8a:	4785                	li	a5,1
    80003c8c:	02f70363          	beq	a4,a5,80003cb2 <iput+0x48>
  ip->ref--;
    80003c90:	449c                	lw	a5,8(s1)
    80003c92:	37fd                	addiw	a5,a5,-1
    80003c94:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c96:	0001d517          	auipc	a0,0x1d
    80003c9a:	93250513          	addi	a0,a0,-1742 # 800205c8 <itable>
    80003c9e:	ffffd097          	auipc	ra,0xffffd
    80003ca2:	fd8080e7          	jalr	-40(ra) # 80000c76 <release>
}
    80003ca6:	60e2                	ld	ra,24(sp)
    80003ca8:	6442                	ld	s0,16(sp)
    80003caa:	64a2                	ld	s1,8(sp)
    80003cac:	6902                	ld	s2,0(sp)
    80003cae:	6105                	addi	sp,sp,32
    80003cb0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cb2:	40bc                	lw	a5,64(s1)
    80003cb4:	dff1                	beqz	a5,80003c90 <iput+0x26>
    80003cb6:	04a49783          	lh	a5,74(s1)
    80003cba:	fbf9                	bnez	a5,80003c90 <iput+0x26>
    acquiresleep(&ip->lock);
    80003cbc:	01048913          	addi	s2,s1,16
    80003cc0:	854a                	mv	a0,s2
    80003cc2:	00001097          	auipc	ra,0x1
    80003cc6:	abc080e7          	jalr	-1348(ra) # 8000477e <acquiresleep>
    release(&itable.lock);
    80003cca:	0001d517          	auipc	a0,0x1d
    80003cce:	8fe50513          	addi	a0,a0,-1794 # 800205c8 <itable>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	fa4080e7          	jalr	-92(ra) # 80000c76 <release>
    itrunc(ip);
    80003cda:	8526                	mv	a0,s1
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	ee2080e7          	jalr	-286(ra) # 80003bbe <itrunc>
    ip->type = 0;
    80003ce4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ce8:	8526                	mv	a0,s1
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	cfc080e7          	jalr	-772(ra) # 800039e6 <iupdate>
    ip->valid = 0;
    80003cf2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003cf6:	854a                	mv	a0,s2
    80003cf8:	00001097          	auipc	ra,0x1
    80003cfc:	adc080e7          	jalr	-1316(ra) # 800047d4 <releasesleep>
    acquire(&itable.lock);
    80003d00:	0001d517          	auipc	a0,0x1d
    80003d04:	8c850513          	addi	a0,a0,-1848 # 800205c8 <itable>
    80003d08:	ffffd097          	auipc	ra,0xffffd
    80003d0c:	eba080e7          	jalr	-326(ra) # 80000bc2 <acquire>
    80003d10:	b741                	j	80003c90 <iput+0x26>

0000000080003d12 <iunlockput>:
{
    80003d12:	1101                	addi	sp,sp,-32
    80003d14:	ec06                	sd	ra,24(sp)
    80003d16:	e822                	sd	s0,16(sp)
    80003d18:	e426                	sd	s1,8(sp)
    80003d1a:	1000                	addi	s0,sp,32
    80003d1c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	e54080e7          	jalr	-428(ra) # 80003b72 <iunlock>
  iput(ip);
    80003d26:	8526                	mv	a0,s1
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	f42080e7          	jalr	-190(ra) # 80003c6a <iput>
}
    80003d30:	60e2                	ld	ra,24(sp)
    80003d32:	6442                	ld	s0,16(sp)
    80003d34:	64a2                	ld	s1,8(sp)
    80003d36:	6105                	addi	sp,sp,32
    80003d38:	8082                	ret

0000000080003d3a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d3a:	1141                	addi	sp,sp,-16
    80003d3c:	e422                	sd	s0,8(sp)
    80003d3e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d40:	411c                	lw	a5,0(a0)
    80003d42:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d44:	415c                	lw	a5,4(a0)
    80003d46:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d48:	04451783          	lh	a5,68(a0)
    80003d4c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d50:	04a51783          	lh	a5,74(a0)
    80003d54:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d58:	04c56783          	lwu	a5,76(a0)
    80003d5c:	e99c                	sd	a5,16(a1)
}
    80003d5e:	6422                	ld	s0,8(sp)
    80003d60:	0141                	addi	sp,sp,16
    80003d62:	8082                	ret

0000000080003d64 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d64:	457c                	lw	a5,76(a0)
    80003d66:	0ed7e963          	bltu	a5,a3,80003e58 <readi+0xf4>
{
    80003d6a:	7159                	addi	sp,sp,-112
    80003d6c:	f486                	sd	ra,104(sp)
    80003d6e:	f0a2                	sd	s0,96(sp)
    80003d70:	eca6                	sd	s1,88(sp)
    80003d72:	e8ca                	sd	s2,80(sp)
    80003d74:	e4ce                	sd	s3,72(sp)
    80003d76:	e0d2                	sd	s4,64(sp)
    80003d78:	fc56                	sd	s5,56(sp)
    80003d7a:	f85a                	sd	s6,48(sp)
    80003d7c:	f45e                	sd	s7,40(sp)
    80003d7e:	f062                	sd	s8,32(sp)
    80003d80:	ec66                	sd	s9,24(sp)
    80003d82:	e86a                	sd	s10,16(sp)
    80003d84:	e46e                	sd	s11,8(sp)
    80003d86:	1880                	addi	s0,sp,112
    80003d88:	8baa                	mv	s7,a0
    80003d8a:	8c2e                	mv	s8,a1
    80003d8c:	8ab2                	mv	s5,a2
    80003d8e:	84b6                	mv	s1,a3
    80003d90:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d92:	9f35                	addw	a4,a4,a3
    return 0;
    80003d94:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d96:	0ad76063          	bltu	a4,a3,80003e36 <readi+0xd2>
  if(off + n > ip->size)
    80003d9a:	00e7f463          	bgeu	a5,a4,80003da2 <readi+0x3e>
    n = ip->size - off;
    80003d9e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003da2:	0a0b0963          	beqz	s6,80003e54 <readi+0xf0>
    80003da6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dac:	5cfd                	li	s9,-1
    80003dae:	a82d                	j	80003de8 <readi+0x84>
    80003db0:	020a1d93          	slli	s11,s4,0x20
    80003db4:	020ddd93          	srli	s11,s11,0x20
    80003db8:	05890793          	addi	a5,s2,88
    80003dbc:	86ee                	mv	a3,s11
    80003dbe:	963e                	add	a2,a2,a5
    80003dc0:	85d6                	mv	a1,s5
    80003dc2:	8562                	mv	a0,s8
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	8d4080e7          	jalr	-1836(ra) # 80002698 <either_copyout>
    80003dcc:	05950d63          	beq	a0,s9,80003e26 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003dd0:	854a                	mv	a0,s2
    80003dd2:	fffff097          	auipc	ra,0xfffff
    80003dd6:	60a080e7          	jalr	1546(ra) # 800033dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dda:	013a09bb          	addw	s3,s4,s3
    80003dde:	009a04bb          	addw	s1,s4,s1
    80003de2:	9aee                	add	s5,s5,s11
    80003de4:	0569f763          	bgeu	s3,s6,80003e32 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003de8:	000ba903          	lw	s2,0(s7)
    80003dec:	00a4d59b          	srliw	a1,s1,0xa
    80003df0:	855e                	mv	a0,s7
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	8ae080e7          	jalr	-1874(ra) # 800036a0 <bmap>
    80003dfa:	0005059b          	sext.w	a1,a0
    80003dfe:	854a                	mv	a0,s2
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	4ac080e7          	jalr	1196(ra) # 800032ac <bread>
    80003e08:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e0a:	3ff4f613          	andi	a2,s1,1023
    80003e0e:	40cd07bb          	subw	a5,s10,a2
    80003e12:	413b073b          	subw	a4,s6,s3
    80003e16:	8a3e                	mv	s4,a5
    80003e18:	2781                	sext.w	a5,a5
    80003e1a:	0007069b          	sext.w	a3,a4
    80003e1e:	f8f6f9e3          	bgeu	a3,a5,80003db0 <readi+0x4c>
    80003e22:	8a3a                	mv	s4,a4
    80003e24:	b771                	j	80003db0 <readi+0x4c>
      brelse(bp);
    80003e26:	854a                	mv	a0,s2
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	5b4080e7          	jalr	1460(ra) # 800033dc <brelse>
      tot = -1;
    80003e30:	59fd                	li	s3,-1
  }
  return tot;
    80003e32:	0009851b          	sext.w	a0,s3
}
    80003e36:	70a6                	ld	ra,104(sp)
    80003e38:	7406                	ld	s0,96(sp)
    80003e3a:	64e6                	ld	s1,88(sp)
    80003e3c:	6946                	ld	s2,80(sp)
    80003e3e:	69a6                	ld	s3,72(sp)
    80003e40:	6a06                	ld	s4,64(sp)
    80003e42:	7ae2                	ld	s5,56(sp)
    80003e44:	7b42                	ld	s6,48(sp)
    80003e46:	7ba2                	ld	s7,40(sp)
    80003e48:	7c02                	ld	s8,32(sp)
    80003e4a:	6ce2                	ld	s9,24(sp)
    80003e4c:	6d42                	ld	s10,16(sp)
    80003e4e:	6da2                	ld	s11,8(sp)
    80003e50:	6165                	addi	sp,sp,112
    80003e52:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e54:	89da                	mv	s3,s6
    80003e56:	bff1                	j	80003e32 <readi+0xce>
    return 0;
    80003e58:	4501                	li	a0,0
}
    80003e5a:	8082                	ret

0000000080003e5c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e5c:	457c                	lw	a5,76(a0)
    80003e5e:	10d7e863          	bltu	a5,a3,80003f6e <writei+0x112>
{
    80003e62:	7159                	addi	sp,sp,-112
    80003e64:	f486                	sd	ra,104(sp)
    80003e66:	f0a2                	sd	s0,96(sp)
    80003e68:	eca6                	sd	s1,88(sp)
    80003e6a:	e8ca                	sd	s2,80(sp)
    80003e6c:	e4ce                	sd	s3,72(sp)
    80003e6e:	e0d2                	sd	s4,64(sp)
    80003e70:	fc56                	sd	s5,56(sp)
    80003e72:	f85a                	sd	s6,48(sp)
    80003e74:	f45e                	sd	s7,40(sp)
    80003e76:	f062                	sd	s8,32(sp)
    80003e78:	ec66                	sd	s9,24(sp)
    80003e7a:	e86a                	sd	s10,16(sp)
    80003e7c:	e46e                	sd	s11,8(sp)
    80003e7e:	1880                	addi	s0,sp,112
    80003e80:	8b2a                	mv	s6,a0
    80003e82:	8c2e                	mv	s8,a1
    80003e84:	8ab2                	mv	s5,a2
    80003e86:	8936                	mv	s2,a3
    80003e88:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e8a:	00e687bb          	addw	a5,a3,a4
    80003e8e:	0ed7e263          	bltu	a5,a3,80003f72 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e92:	00043737          	lui	a4,0x43
    80003e96:	0ef76063          	bltu	a4,a5,80003f76 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e9a:	0c0b8863          	beqz	s7,80003f6a <writei+0x10e>
    80003e9e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ea0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ea4:	5cfd                	li	s9,-1
    80003ea6:	a091                	j	80003eea <writei+0x8e>
    80003ea8:	02099d93          	slli	s11,s3,0x20
    80003eac:	020ddd93          	srli	s11,s11,0x20
    80003eb0:	05848793          	addi	a5,s1,88
    80003eb4:	86ee                	mv	a3,s11
    80003eb6:	8656                	mv	a2,s5
    80003eb8:	85e2                	mv	a1,s8
    80003eba:	953e                	add	a0,a0,a5
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	832080e7          	jalr	-1998(ra) # 800026ee <either_copyin>
    80003ec4:	07950263          	beq	a0,s9,80003f28 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ec8:	8526                	mv	a0,s1
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	794080e7          	jalr	1940(ra) # 8000465e <log_write>
    brelse(bp);
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	fffff097          	auipc	ra,0xfffff
    80003ed8:	508080e7          	jalr	1288(ra) # 800033dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003edc:	01498a3b          	addw	s4,s3,s4
    80003ee0:	0129893b          	addw	s2,s3,s2
    80003ee4:	9aee                	add	s5,s5,s11
    80003ee6:	057a7663          	bgeu	s4,s7,80003f32 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eea:	000b2483          	lw	s1,0(s6)
    80003eee:	00a9559b          	srliw	a1,s2,0xa
    80003ef2:	855a                	mv	a0,s6
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	7ac080e7          	jalr	1964(ra) # 800036a0 <bmap>
    80003efc:	0005059b          	sext.w	a1,a0
    80003f00:	8526                	mv	a0,s1
    80003f02:	fffff097          	auipc	ra,0xfffff
    80003f06:	3aa080e7          	jalr	938(ra) # 800032ac <bread>
    80003f0a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f0c:	3ff97513          	andi	a0,s2,1023
    80003f10:	40ad07bb          	subw	a5,s10,a0
    80003f14:	414b873b          	subw	a4,s7,s4
    80003f18:	89be                	mv	s3,a5
    80003f1a:	2781                	sext.w	a5,a5
    80003f1c:	0007069b          	sext.w	a3,a4
    80003f20:	f8f6f4e3          	bgeu	a3,a5,80003ea8 <writei+0x4c>
    80003f24:	89ba                	mv	s3,a4
    80003f26:	b749                	j	80003ea8 <writei+0x4c>
      brelse(bp);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	4b2080e7          	jalr	1202(ra) # 800033dc <brelse>
  }

  if(off > ip->size)
    80003f32:	04cb2783          	lw	a5,76(s6)
    80003f36:	0127f463          	bgeu	a5,s2,80003f3e <writei+0xe2>
    ip->size = off;
    80003f3a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f3e:	855a                	mv	a0,s6
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	aa6080e7          	jalr	-1370(ra) # 800039e6 <iupdate>

  return tot;
    80003f48:	000a051b          	sext.w	a0,s4
}
    80003f4c:	70a6                	ld	ra,104(sp)
    80003f4e:	7406                	ld	s0,96(sp)
    80003f50:	64e6                	ld	s1,88(sp)
    80003f52:	6946                	ld	s2,80(sp)
    80003f54:	69a6                	ld	s3,72(sp)
    80003f56:	6a06                	ld	s4,64(sp)
    80003f58:	7ae2                	ld	s5,56(sp)
    80003f5a:	7b42                	ld	s6,48(sp)
    80003f5c:	7ba2                	ld	s7,40(sp)
    80003f5e:	7c02                	ld	s8,32(sp)
    80003f60:	6ce2                	ld	s9,24(sp)
    80003f62:	6d42                	ld	s10,16(sp)
    80003f64:	6da2                	ld	s11,8(sp)
    80003f66:	6165                	addi	sp,sp,112
    80003f68:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f6a:	8a5e                	mv	s4,s7
    80003f6c:	bfc9                	j	80003f3e <writei+0xe2>
    return -1;
    80003f6e:	557d                	li	a0,-1
}
    80003f70:	8082                	ret
    return -1;
    80003f72:	557d                	li	a0,-1
    80003f74:	bfe1                	j	80003f4c <writei+0xf0>
    return -1;
    80003f76:	557d                	li	a0,-1
    80003f78:	bfd1                	j	80003f4c <writei+0xf0>

0000000080003f7a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f7a:	1141                	addi	sp,sp,-16
    80003f7c:	e406                	sd	ra,8(sp)
    80003f7e:	e022                	sd	s0,0(sp)
    80003f80:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f82:	4639                	li	a2,14
    80003f84:	ffffd097          	auipc	ra,0xffffd
    80003f88:	e12080e7          	jalr	-494(ra) # 80000d96 <strncmp>
}
    80003f8c:	60a2                	ld	ra,8(sp)
    80003f8e:	6402                	ld	s0,0(sp)
    80003f90:	0141                	addi	sp,sp,16
    80003f92:	8082                	ret

0000000080003f94 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f94:	7139                	addi	sp,sp,-64
    80003f96:	fc06                	sd	ra,56(sp)
    80003f98:	f822                	sd	s0,48(sp)
    80003f9a:	f426                	sd	s1,40(sp)
    80003f9c:	f04a                	sd	s2,32(sp)
    80003f9e:	ec4e                	sd	s3,24(sp)
    80003fa0:	e852                	sd	s4,16(sp)
    80003fa2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fa4:	04451703          	lh	a4,68(a0)
    80003fa8:	4785                	li	a5,1
    80003faa:	00f71a63          	bne	a4,a5,80003fbe <dirlookup+0x2a>
    80003fae:	892a                	mv	s2,a0
    80003fb0:	89ae                	mv	s3,a1
    80003fb2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb4:	457c                	lw	a5,76(a0)
    80003fb6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fb8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fba:	e79d                	bnez	a5,80003fe8 <dirlookup+0x54>
    80003fbc:	a8a5                	j	80004034 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fbe:	00004517          	auipc	a0,0x4
    80003fc2:	74a50513          	addi	a0,a0,1866 # 80008708 <syscalls+0x1b8>
    80003fc6:	ffffc097          	auipc	ra,0xffffc
    80003fca:	564080e7          	jalr	1380(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003fce:	00004517          	auipc	a0,0x4
    80003fd2:	75250513          	addi	a0,a0,1874 # 80008720 <syscalls+0x1d0>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	554080e7          	jalr	1364(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fde:	24c1                	addiw	s1,s1,16
    80003fe0:	04c92783          	lw	a5,76(s2)
    80003fe4:	04f4f763          	bgeu	s1,a5,80004032 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe8:	4741                	li	a4,16
    80003fea:	86a6                	mv	a3,s1
    80003fec:	fc040613          	addi	a2,s0,-64
    80003ff0:	4581                	li	a1,0
    80003ff2:	854a                	mv	a0,s2
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	d70080e7          	jalr	-656(ra) # 80003d64 <readi>
    80003ffc:	47c1                	li	a5,16
    80003ffe:	fcf518e3          	bne	a0,a5,80003fce <dirlookup+0x3a>
    if(de.inum == 0)
    80004002:	fc045783          	lhu	a5,-64(s0)
    80004006:	dfe1                	beqz	a5,80003fde <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004008:	fc240593          	addi	a1,s0,-62
    8000400c:	854e                	mv	a0,s3
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	f6c080e7          	jalr	-148(ra) # 80003f7a <namecmp>
    80004016:	f561                	bnez	a0,80003fde <dirlookup+0x4a>
      if(poff)
    80004018:	000a0463          	beqz	s4,80004020 <dirlookup+0x8c>
        *poff = off;
    8000401c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004020:	fc045583          	lhu	a1,-64(s0)
    80004024:	00092503          	lw	a0,0(s2)
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	754080e7          	jalr	1876(ra) # 8000377c <iget>
    80004030:	a011                	j	80004034 <dirlookup+0xa0>
  return 0;
    80004032:	4501                	li	a0,0
}
    80004034:	70e2                	ld	ra,56(sp)
    80004036:	7442                	ld	s0,48(sp)
    80004038:	74a2                	ld	s1,40(sp)
    8000403a:	7902                	ld	s2,32(sp)
    8000403c:	69e2                	ld	s3,24(sp)
    8000403e:	6a42                	ld	s4,16(sp)
    80004040:	6121                	addi	sp,sp,64
    80004042:	8082                	ret

0000000080004044 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004044:	711d                	addi	sp,sp,-96
    80004046:	ec86                	sd	ra,88(sp)
    80004048:	e8a2                	sd	s0,80(sp)
    8000404a:	e4a6                	sd	s1,72(sp)
    8000404c:	e0ca                	sd	s2,64(sp)
    8000404e:	fc4e                	sd	s3,56(sp)
    80004050:	f852                	sd	s4,48(sp)
    80004052:	f456                	sd	s5,40(sp)
    80004054:	f05a                	sd	s6,32(sp)
    80004056:	ec5e                	sd	s7,24(sp)
    80004058:	e862                	sd	s8,16(sp)
    8000405a:	e466                	sd	s9,8(sp)
    8000405c:	1080                	addi	s0,sp,96
    8000405e:	84aa                	mv	s1,a0
    80004060:	8aae                	mv	s5,a1
    80004062:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004064:	00054703          	lbu	a4,0(a0)
    80004068:	02f00793          	li	a5,47
    8000406c:	02f70363          	beq	a4,a5,80004092 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004070:	ffffe097          	auipc	ra,0xffffe
    80004074:	90e080e7          	jalr	-1778(ra) # 8000197e <myproc>
    80004078:	18853503          	ld	a0,392(a0)
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	9f6080e7          	jalr	-1546(ra) # 80003a72 <idup>
    80004084:	89aa                	mv	s3,a0
  while(*path == '/')
    80004086:	02f00913          	li	s2,47
  len = path - s;
    8000408a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000408c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000408e:	4b85                	li	s7,1
    80004090:	a865                	j	80004148 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004092:	4585                	li	a1,1
    80004094:	4505                	li	a0,1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	6e6080e7          	jalr	1766(ra) # 8000377c <iget>
    8000409e:	89aa                	mv	s3,a0
    800040a0:	b7dd                	j	80004086 <namex+0x42>
      iunlockput(ip);
    800040a2:	854e                	mv	a0,s3
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	c6e080e7          	jalr	-914(ra) # 80003d12 <iunlockput>
      return 0;
    800040ac:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040ae:	854e                	mv	a0,s3
    800040b0:	60e6                	ld	ra,88(sp)
    800040b2:	6446                	ld	s0,80(sp)
    800040b4:	64a6                	ld	s1,72(sp)
    800040b6:	6906                	ld	s2,64(sp)
    800040b8:	79e2                	ld	s3,56(sp)
    800040ba:	7a42                	ld	s4,48(sp)
    800040bc:	7aa2                	ld	s5,40(sp)
    800040be:	7b02                	ld	s6,32(sp)
    800040c0:	6be2                	ld	s7,24(sp)
    800040c2:	6c42                	ld	s8,16(sp)
    800040c4:	6ca2                	ld	s9,8(sp)
    800040c6:	6125                	addi	sp,sp,96
    800040c8:	8082                	ret
      iunlock(ip);
    800040ca:	854e                	mv	a0,s3
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	aa6080e7          	jalr	-1370(ra) # 80003b72 <iunlock>
      return ip;
    800040d4:	bfe9                	j	800040ae <namex+0x6a>
      iunlockput(ip);
    800040d6:	854e                	mv	a0,s3
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	c3a080e7          	jalr	-966(ra) # 80003d12 <iunlockput>
      return 0;
    800040e0:	89e6                	mv	s3,s9
    800040e2:	b7f1                	j	800040ae <namex+0x6a>
  len = path - s;
    800040e4:	40b48633          	sub	a2,s1,a1
    800040e8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040ec:	099c5463          	bge	s8,s9,80004174 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800040f0:	4639                	li	a2,14
    800040f2:	8552                	mv	a0,s4
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	c26080e7          	jalr	-986(ra) # 80000d1a <memmove>
  while(*path == '/')
    800040fc:	0004c783          	lbu	a5,0(s1)
    80004100:	01279763          	bne	a5,s2,8000410e <namex+0xca>
    path++;
    80004104:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004106:	0004c783          	lbu	a5,0(s1)
    8000410a:	ff278de3          	beq	a5,s2,80004104 <namex+0xc0>
    ilock(ip);
    8000410e:	854e                	mv	a0,s3
    80004110:	00000097          	auipc	ra,0x0
    80004114:	9a0080e7          	jalr	-1632(ra) # 80003ab0 <ilock>
    if(ip->type != T_DIR){
    80004118:	04499783          	lh	a5,68(s3)
    8000411c:	f97793e3          	bne	a5,s7,800040a2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004120:	000a8563          	beqz	s5,8000412a <namex+0xe6>
    80004124:	0004c783          	lbu	a5,0(s1)
    80004128:	d3cd                	beqz	a5,800040ca <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000412a:	865a                	mv	a2,s6
    8000412c:	85d2                	mv	a1,s4
    8000412e:	854e                	mv	a0,s3
    80004130:	00000097          	auipc	ra,0x0
    80004134:	e64080e7          	jalr	-412(ra) # 80003f94 <dirlookup>
    80004138:	8caa                	mv	s9,a0
    8000413a:	dd51                	beqz	a0,800040d6 <namex+0x92>
    iunlockput(ip);
    8000413c:	854e                	mv	a0,s3
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	bd4080e7          	jalr	-1068(ra) # 80003d12 <iunlockput>
    ip = next;
    80004146:	89e6                	mv	s3,s9
  while(*path == '/')
    80004148:	0004c783          	lbu	a5,0(s1)
    8000414c:	05279763          	bne	a5,s2,8000419a <namex+0x156>
    path++;
    80004150:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004152:	0004c783          	lbu	a5,0(s1)
    80004156:	ff278de3          	beq	a5,s2,80004150 <namex+0x10c>
  if(*path == 0)
    8000415a:	c79d                	beqz	a5,80004188 <namex+0x144>
    path++;
    8000415c:	85a6                	mv	a1,s1
  len = path - s;
    8000415e:	8cda                	mv	s9,s6
    80004160:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004162:	01278963          	beq	a5,s2,80004174 <namex+0x130>
    80004166:	dfbd                	beqz	a5,800040e4 <namex+0xa0>
    path++;
    80004168:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000416a:	0004c783          	lbu	a5,0(s1)
    8000416e:	ff279ce3          	bne	a5,s2,80004166 <namex+0x122>
    80004172:	bf8d                	j	800040e4 <namex+0xa0>
    memmove(name, s, len);
    80004174:	2601                	sext.w	a2,a2
    80004176:	8552                	mv	a0,s4
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	ba2080e7          	jalr	-1118(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004180:	9cd2                	add	s9,s9,s4
    80004182:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004186:	bf9d                	j	800040fc <namex+0xb8>
  if(nameiparent){
    80004188:	f20a83e3          	beqz	s5,800040ae <namex+0x6a>
    iput(ip);
    8000418c:	854e                	mv	a0,s3
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	adc080e7          	jalr	-1316(ra) # 80003c6a <iput>
    return 0;
    80004196:	4981                	li	s3,0
    80004198:	bf19                	j	800040ae <namex+0x6a>
  if(*path == 0)
    8000419a:	d7fd                	beqz	a5,80004188 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000419c:	0004c783          	lbu	a5,0(s1)
    800041a0:	85a6                	mv	a1,s1
    800041a2:	b7d1                	j	80004166 <namex+0x122>

00000000800041a4 <dirlink>:
{
    800041a4:	7139                	addi	sp,sp,-64
    800041a6:	fc06                	sd	ra,56(sp)
    800041a8:	f822                	sd	s0,48(sp)
    800041aa:	f426                	sd	s1,40(sp)
    800041ac:	f04a                	sd	s2,32(sp)
    800041ae:	ec4e                	sd	s3,24(sp)
    800041b0:	e852                	sd	s4,16(sp)
    800041b2:	0080                	addi	s0,sp,64
    800041b4:	892a                	mv	s2,a0
    800041b6:	8a2e                	mv	s4,a1
    800041b8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041ba:	4601                	li	a2,0
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	dd8080e7          	jalr	-552(ra) # 80003f94 <dirlookup>
    800041c4:	e93d                	bnez	a0,8000423a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041c6:	04c92483          	lw	s1,76(s2)
    800041ca:	c49d                	beqz	s1,800041f8 <dirlink+0x54>
    800041cc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ce:	4741                	li	a4,16
    800041d0:	86a6                	mv	a3,s1
    800041d2:	fc040613          	addi	a2,s0,-64
    800041d6:	4581                	li	a1,0
    800041d8:	854a                	mv	a0,s2
    800041da:	00000097          	auipc	ra,0x0
    800041de:	b8a080e7          	jalr	-1142(ra) # 80003d64 <readi>
    800041e2:	47c1                	li	a5,16
    800041e4:	06f51163          	bne	a0,a5,80004246 <dirlink+0xa2>
    if(de.inum == 0)
    800041e8:	fc045783          	lhu	a5,-64(s0)
    800041ec:	c791                	beqz	a5,800041f8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ee:	24c1                	addiw	s1,s1,16
    800041f0:	04c92783          	lw	a5,76(s2)
    800041f4:	fcf4ede3          	bltu	s1,a5,800041ce <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041f8:	4639                	li	a2,14
    800041fa:	85d2                	mv	a1,s4
    800041fc:	fc240513          	addi	a0,s0,-62
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	bd2080e7          	jalr	-1070(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004208:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000420c:	4741                	li	a4,16
    8000420e:	86a6                	mv	a3,s1
    80004210:	fc040613          	addi	a2,s0,-64
    80004214:	4581                	li	a1,0
    80004216:	854a                	mv	a0,s2
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	c44080e7          	jalr	-956(ra) # 80003e5c <writei>
    80004220:	872a                	mv	a4,a0
    80004222:	47c1                	li	a5,16
  return 0;
    80004224:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004226:	02f71863          	bne	a4,a5,80004256 <dirlink+0xb2>
}
    8000422a:	70e2                	ld	ra,56(sp)
    8000422c:	7442                	ld	s0,48(sp)
    8000422e:	74a2                	ld	s1,40(sp)
    80004230:	7902                	ld	s2,32(sp)
    80004232:	69e2                	ld	s3,24(sp)
    80004234:	6a42                	ld	s4,16(sp)
    80004236:	6121                	addi	sp,sp,64
    80004238:	8082                	ret
    iput(ip);
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	a30080e7          	jalr	-1488(ra) # 80003c6a <iput>
    return -1;
    80004242:	557d                	li	a0,-1
    80004244:	b7dd                	j	8000422a <dirlink+0x86>
      panic("dirlink read");
    80004246:	00004517          	auipc	a0,0x4
    8000424a:	4ea50513          	addi	a0,a0,1258 # 80008730 <syscalls+0x1e0>
    8000424e:	ffffc097          	auipc	ra,0xffffc
    80004252:	2dc080e7          	jalr	732(ra) # 8000052a <panic>
    panic("dirlink");
    80004256:	00004517          	auipc	a0,0x4
    8000425a:	5e250513          	addi	a0,a0,1506 # 80008838 <syscalls+0x2e8>
    8000425e:	ffffc097          	auipc	ra,0xffffc
    80004262:	2cc080e7          	jalr	716(ra) # 8000052a <panic>

0000000080004266 <namei>:

struct inode*
namei(char *path)
{
    80004266:	1101                	addi	sp,sp,-32
    80004268:	ec06                	sd	ra,24(sp)
    8000426a:	e822                	sd	s0,16(sp)
    8000426c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000426e:	fe040613          	addi	a2,s0,-32
    80004272:	4581                	li	a1,0
    80004274:	00000097          	auipc	ra,0x0
    80004278:	dd0080e7          	jalr	-560(ra) # 80004044 <namex>
}
    8000427c:	60e2                	ld	ra,24(sp)
    8000427e:	6442                	ld	s0,16(sp)
    80004280:	6105                	addi	sp,sp,32
    80004282:	8082                	ret

0000000080004284 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004284:	1141                	addi	sp,sp,-16
    80004286:	e406                	sd	ra,8(sp)
    80004288:	e022                	sd	s0,0(sp)
    8000428a:	0800                	addi	s0,sp,16
    8000428c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000428e:	4585                	li	a1,1
    80004290:	00000097          	auipc	ra,0x0
    80004294:	db4080e7          	jalr	-588(ra) # 80004044 <namex>
}
    80004298:	60a2                	ld	ra,8(sp)
    8000429a:	6402                	ld	s0,0(sp)
    8000429c:	0141                	addi	sp,sp,16
    8000429e:	8082                	ret

00000000800042a0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042a0:	1101                	addi	sp,sp,-32
    800042a2:	ec06                	sd	ra,24(sp)
    800042a4:	e822                	sd	s0,16(sp)
    800042a6:	e426                	sd	s1,8(sp)
    800042a8:	e04a                	sd	s2,0(sp)
    800042aa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042ac:	0001e917          	auipc	s2,0x1e
    800042b0:	dc490913          	addi	s2,s2,-572 # 80022070 <log>
    800042b4:	01892583          	lw	a1,24(s2)
    800042b8:	02892503          	lw	a0,40(s2)
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	ff0080e7          	jalr	-16(ra) # 800032ac <bread>
    800042c4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042c6:	02c92683          	lw	a3,44(s2)
    800042ca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042cc:	02d05863          	blez	a3,800042fc <write_head+0x5c>
    800042d0:	0001e797          	auipc	a5,0x1e
    800042d4:	dd078793          	addi	a5,a5,-560 # 800220a0 <log+0x30>
    800042d8:	05c50713          	addi	a4,a0,92
    800042dc:	36fd                	addiw	a3,a3,-1
    800042de:	02069613          	slli	a2,a3,0x20
    800042e2:	01e65693          	srli	a3,a2,0x1e
    800042e6:	0001e617          	auipc	a2,0x1e
    800042ea:	dbe60613          	addi	a2,a2,-578 # 800220a4 <log+0x34>
    800042ee:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042f0:	4390                	lw	a2,0(a5)
    800042f2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042f4:	0791                	addi	a5,a5,4
    800042f6:	0711                	addi	a4,a4,4
    800042f8:	fed79ce3          	bne	a5,a3,800042f0 <write_head+0x50>
  }
  bwrite(buf);
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	0a0080e7          	jalr	160(ra) # 8000339e <bwrite>
  brelse(buf);
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	0d4080e7          	jalr	212(ra) # 800033dc <brelse>
}
    80004310:	60e2                	ld	ra,24(sp)
    80004312:	6442                	ld	s0,16(sp)
    80004314:	64a2                	ld	s1,8(sp)
    80004316:	6902                	ld	s2,0(sp)
    80004318:	6105                	addi	sp,sp,32
    8000431a:	8082                	ret

000000008000431c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431c:	0001e797          	auipc	a5,0x1e
    80004320:	d807a783          	lw	a5,-640(a5) # 8002209c <log+0x2c>
    80004324:	0af05d63          	blez	a5,800043de <install_trans+0xc2>
{
    80004328:	7139                	addi	sp,sp,-64
    8000432a:	fc06                	sd	ra,56(sp)
    8000432c:	f822                	sd	s0,48(sp)
    8000432e:	f426                	sd	s1,40(sp)
    80004330:	f04a                	sd	s2,32(sp)
    80004332:	ec4e                	sd	s3,24(sp)
    80004334:	e852                	sd	s4,16(sp)
    80004336:	e456                	sd	s5,8(sp)
    80004338:	e05a                	sd	s6,0(sp)
    8000433a:	0080                	addi	s0,sp,64
    8000433c:	8b2a                	mv	s6,a0
    8000433e:	0001ea97          	auipc	s5,0x1e
    80004342:	d62a8a93          	addi	s5,s5,-670 # 800220a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004346:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004348:	0001e997          	auipc	s3,0x1e
    8000434c:	d2898993          	addi	s3,s3,-728 # 80022070 <log>
    80004350:	a00d                	j	80004372 <install_trans+0x56>
    brelse(lbuf);
    80004352:	854a                	mv	a0,s2
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	088080e7          	jalr	136(ra) # 800033dc <brelse>
    brelse(dbuf);
    8000435c:	8526                	mv	a0,s1
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	07e080e7          	jalr	126(ra) # 800033dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004366:	2a05                	addiw	s4,s4,1
    80004368:	0a91                	addi	s5,s5,4
    8000436a:	02c9a783          	lw	a5,44(s3)
    8000436e:	04fa5e63          	bge	s4,a5,800043ca <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004372:	0189a583          	lw	a1,24(s3)
    80004376:	014585bb          	addw	a1,a1,s4
    8000437a:	2585                	addiw	a1,a1,1
    8000437c:	0289a503          	lw	a0,40(s3)
    80004380:	fffff097          	auipc	ra,0xfffff
    80004384:	f2c080e7          	jalr	-212(ra) # 800032ac <bread>
    80004388:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000438a:	000aa583          	lw	a1,0(s5)
    8000438e:	0289a503          	lw	a0,40(s3)
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	f1a080e7          	jalr	-230(ra) # 800032ac <bread>
    8000439a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000439c:	40000613          	li	a2,1024
    800043a0:	05890593          	addi	a1,s2,88
    800043a4:	05850513          	addi	a0,a0,88
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	972080e7          	jalr	-1678(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800043b0:	8526                	mv	a0,s1
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	fec080e7          	jalr	-20(ra) # 8000339e <bwrite>
    if(recovering == 0)
    800043ba:	f80b1ce3          	bnez	s6,80004352 <install_trans+0x36>
      bunpin(dbuf);
    800043be:	8526                	mv	a0,s1
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	0f6080e7          	jalr	246(ra) # 800034b6 <bunpin>
    800043c8:	b769                	j	80004352 <install_trans+0x36>
}
    800043ca:	70e2                	ld	ra,56(sp)
    800043cc:	7442                	ld	s0,48(sp)
    800043ce:	74a2                	ld	s1,40(sp)
    800043d0:	7902                	ld	s2,32(sp)
    800043d2:	69e2                	ld	s3,24(sp)
    800043d4:	6a42                	ld	s4,16(sp)
    800043d6:	6aa2                	ld	s5,8(sp)
    800043d8:	6b02                	ld	s6,0(sp)
    800043da:	6121                	addi	sp,sp,64
    800043dc:	8082                	ret
    800043de:	8082                	ret

00000000800043e0 <initlog>:
{
    800043e0:	7179                	addi	sp,sp,-48
    800043e2:	f406                	sd	ra,40(sp)
    800043e4:	f022                	sd	s0,32(sp)
    800043e6:	ec26                	sd	s1,24(sp)
    800043e8:	e84a                	sd	s2,16(sp)
    800043ea:	e44e                	sd	s3,8(sp)
    800043ec:	1800                	addi	s0,sp,48
    800043ee:	892a                	mv	s2,a0
    800043f0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043f2:	0001e497          	auipc	s1,0x1e
    800043f6:	c7e48493          	addi	s1,s1,-898 # 80022070 <log>
    800043fa:	00004597          	auipc	a1,0x4
    800043fe:	34658593          	addi	a1,a1,838 # 80008740 <syscalls+0x1f0>
    80004402:	8526                	mv	a0,s1
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	72e080e7          	jalr	1838(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000440c:	0149a583          	lw	a1,20(s3)
    80004410:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004412:	0109a783          	lw	a5,16(s3)
    80004416:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004418:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000441c:	854a                	mv	a0,s2
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	e8e080e7          	jalr	-370(ra) # 800032ac <bread>
  log.lh.n = lh->n;
    80004426:	4d34                	lw	a3,88(a0)
    80004428:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000442a:	02d05663          	blez	a3,80004456 <initlog+0x76>
    8000442e:	05c50793          	addi	a5,a0,92
    80004432:	0001e717          	auipc	a4,0x1e
    80004436:	c6e70713          	addi	a4,a4,-914 # 800220a0 <log+0x30>
    8000443a:	36fd                	addiw	a3,a3,-1
    8000443c:	02069613          	slli	a2,a3,0x20
    80004440:	01e65693          	srli	a3,a2,0x1e
    80004444:	06050613          	addi	a2,a0,96
    80004448:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000444a:	4390                	lw	a2,0(a5)
    8000444c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000444e:	0791                	addi	a5,a5,4
    80004450:	0711                	addi	a4,a4,4
    80004452:	fed79ce3          	bne	a5,a3,8000444a <initlog+0x6a>
  brelse(buf);
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	f86080e7          	jalr	-122(ra) # 800033dc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000445e:	4505                	li	a0,1
    80004460:	00000097          	auipc	ra,0x0
    80004464:	ebc080e7          	jalr	-324(ra) # 8000431c <install_trans>
  log.lh.n = 0;
    80004468:	0001e797          	auipc	a5,0x1e
    8000446c:	c207aa23          	sw	zero,-972(a5) # 8002209c <log+0x2c>
  write_head(); // clear the log
    80004470:	00000097          	auipc	ra,0x0
    80004474:	e30080e7          	jalr	-464(ra) # 800042a0 <write_head>
}
    80004478:	70a2                	ld	ra,40(sp)
    8000447a:	7402                	ld	s0,32(sp)
    8000447c:	64e2                	ld	s1,24(sp)
    8000447e:	6942                	ld	s2,16(sp)
    80004480:	69a2                	ld	s3,8(sp)
    80004482:	6145                	addi	sp,sp,48
    80004484:	8082                	ret

0000000080004486 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	e04a                	sd	s2,0(sp)
    80004490:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004492:	0001e517          	auipc	a0,0x1e
    80004496:	bde50513          	addi	a0,a0,-1058 # 80022070 <log>
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	728080e7          	jalr	1832(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800044a2:	0001e497          	auipc	s1,0x1e
    800044a6:	bce48493          	addi	s1,s1,-1074 # 80022070 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044aa:	4979                	li	s2,30
    800044ac:	a039                	j	800044ba <begin_op+0x34>
      sleep(&log, &log.lock);
    800044ae:	85a6                	mv	a1,s1
    800044b0:	8526                	mv	a0,s1
    800044b2:	ffffe097          	auipc	ra,0xffffe
    800044b6:	c38080e7          	jalr	-968(ra) # 800020ea <sleep>
    if(log.committing){
    800044ba:	50dc                	lw	a5,36(s1)
    800044bc:	fbed                	bnez	a5,800044ae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044be:	509c                	lw	a5,32(s1)
    800044c0:	0017871b          	addiw	a4,a5,1
    800044c4:	0007069b          	sext.w	a3,a4
    800044c8:	0027179b          	slliw	a5,a4,0x2
    800044cc:	9fb9                	addw	a5,a5,a4
    800044ce:	0017979b          	slliw	a5,a5,0x1
    800044d2:	54d8                	lw	a4,44(s1)
    800044d4:	9fb9                	addw	a5,a5,a4
    800044d6:	00f95963          	bge	s2,a5,800044e8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044da:	85a6                	mv	a1,s1
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffe097          	auipc	ra,0xffffe
    800044e2:	c0c080e7          	jalr	-1012(ra) # 800020ea <sleep>
    800044e6:	bfd1                	j	800044ba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044e8:	0001e517          	auipc	a0,0x1e
    800044ec:	b8850513          	addi	a0,a0,-1144 # 80022070 <log>
    800044f0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	784080e7          	jalr	1924(ra) # 80000c76 <release>
      break;
    }
  }
}
    800044fa:	60e2                	ld	ra,24(sp)
    800044fc:	6442                	ld	s0,16(sp)
    800044fe:	64a2                	ld	s1,8(sp)
    80004500:	6902                	ld	s2,0(sp)
    80004502:	6105                	addi	sp,sp,32
    80004504:	8082                	ret

0000000080004506 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004506:	7139                	addi	sp,sp,-64
    80004508:	fc06                	sd	ra,56(sp)
    8000450a:	f822                	sd	s0,48(sp)
    8000450c:	f426                	sd	s1,40(sp)
    8000450e:	f04a                	sd	s2,32(sp)
    80004510:	ec4e                	sd	s3,24(sp)
    80004512:	e852                	sd	s4,16(sp)
    80004514:	e456                	sd	s5,8(sp)
    80004516:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004518:	0001e497          	auipc	s1,0x1e
    8000451c:	b5848493          	addi	s1,s1,-1192 # 80022070 <log>
    80004520:	8526                	mv	a0,s1
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	6a0080e7          	jalr	1696(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000452a:	509c                	lw	a5,32(s1)
    8000452c:	37fd                	addiw	a5,a5,-1
    8000452e:	0007891b          	sext.w	s2,a5
    80004532:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004534:	50dc                	lw	a5,36(s1)
    80004536:	e7b9                	bnez	a5,80004584 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004538:	04091e63          	bnez	s2,80004594 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000453c:	0001e497          	auipc	s1,0x1e
    80004540:	b3448493          	addi	s1,s1,-1228 # 80022070 <log>
    80004544:	4785                	li	a5,1
    80004546:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004548:	8526                	mv	a0,s1
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	72c080e7          	jalr	1836(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004552:	54dc                	lw	a5,44(s1)
    80004554:	06f04763          	bgtz	a5,800045c2 <end_op+0xbc>
    acquire(&log.lock);
    80004558:	0001e497          	auipc	s1,0x1e
    8000455c:	b1848493          	addi	s1,s1,-1256 # 80022070 <log>
    80004560:	8526                	mv	a0,s1
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	660080e7          	jalr	1632(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000456a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000456e:	8526                	mv	a0,s1
    80004570:	ffffe097          	auipc	ra,0xffffe
    80004574:	dee080e7          	jalr	-530(ra) # 8000235e <wakeup>
    release(&log.lock);
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	6fc080e7          	jalr	1788(ra) # 80000c76 <release>
}
    80004582:	a03d                	j	800045b0 <end_op+0xaa>
    panic("log.committing");
    80004584:	00004517          	auipc	a0,0x4
    80004588:	1c450513          	addi	a0,a0,452 # 80008748 <syscalls+0x1f8>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	f9e080e7          	jalr	-98(ra) # 8000052a <panic>
    wakeup(&log);
    80004594:	0001e497          	auipc	s1,0x1e
    80004598:	adc48493          	addi	s1,s1,-1316 # 80022070 <log>
    8000459c:	8526                	mv	a0,s1
    8000459e:	ffffe097          	auipc	ra,0xffffe
    800045a2:	dc0080e7          	jalr	-576(ra) # 8000235e <wakeup>
  release(&log.lock);
    800045a6:	8526                	mv	a0,s1
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	6ce080e7          	jalr	1742(ra) # 80000c76 <release>
}
    800045b0:	70e2                	ld	ra,56(sp)
    800045b2:	7442                	ld	s0,48(sp)
    800045b4:	74a2                	ld	s1,40(sp)
    800045b6:	7902                	ld	s2,32(sp)
    800045b8:	69e2                	ld	s3,24(sp)
    800045ba:	6a42                	ld	s4,16(sp)
    800045bc:	6aa2                	ld	s5,8(sp)
    800045be:	6121                	addi	sp,sp,64
    800045c0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c2:	0001ea97          	auipc	s5,0x1e
    800045c6:	adea8a93          	addi	s5,s5,-1314 # 800220a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045ca:	0001ea17          	auipc	s4,0x1e
    800045ce:	aa6a0a13          	addi	s4,s4,-1370 # 80022070 <log>
    800045d2:	018a2583          	lw	a1,24(s4)
    800045d6:	012585bb          	addw	a1,a1,s2
    800045da:	2585                	addiw	a1,a1,1
    800045dc:	028a2503          	lw	a0,40(s4)
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	ccc080e7          	jalr	-820(ra) # 800032ac <bread>
    800045e8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045ea:	000aa583          	lw	a1,0(s5)
    800045ee:	028a2503          	lw	a0,40(s4)
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	cba080e7          	jalr	-838(ra) # 800032ac <bread>
    800045fa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045fc:	40000613          	li	a2,1024
    80004600:	05850593          	addi	a1,a0,88
    80004604:	05848513          	addi	a0,s1,88
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	712080e7          	jalr	1810(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004610:	8526                	mv	a0,s1
    80004612:	fffff097          	auipc	ra,0xfffff
    80004616:	d8c080e7          	jalr	-628(ra) # 8000339e <bwrite>
    brelse(from);
    8000461a:	854e                	mv	a0,s3
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	dc0080e7          	jalr	-576(ra) # 800033dc <brelse>
    brelse(to);
    80004624:	8526                	mv	a0,s1
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	db6080e7          	jalr	-586(ra) # 800033dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000462e:	2905                	addiw	s2,s2,1
    80004630:	0a91                	addi	s5,s5,4
    80004632:	02ca2783          	lw	a5,44(s4)
    80004636:	f8f94ee3          	blt	s2,a5,800045d2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	c66080e7          	jalr	-922(ra) # 800042a0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004642:	4501                	li	a0,0
    80004644:	00000097          	auipc	ra,0x0
    80004648:	cd8080e7          	jalr	-808(ra) # 8000431c <install_trans>
    log.lh.n = 0;
    8000464c:	0001e797          	auipc	a5,0x1e
    80004650:	a407a823          	sw	zero,-1456(a5) # 8002209c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004654:	00000097          	auipc	ra,0x0
    80004658:	c4c080e7          	jalr	-948(ra) # 800042a0 <write_head>
    8000465c:	bdf5                	j	80004558 <end_op+0x52>

000000008000465e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000465e:	1101                	addi	sp,sp,-32
    80004660:	ec06                	sd	ra,24(sp)
    80004662:	e822                	sd	s0,16(sp)
    80004664:	e426                	sd	s1,8(sp)
    80004666:	e04a                	sd	s2,0(sp)
    80004668:	1000                	addi	s0,sp,32
    8000466a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000466c:	0001e917          	auipc	s2,0x1e
    80004670:	a0490913          	addi	s2,s2,-1532 # 80022070 <log>
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	54c080e7          	jalr	1356(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000467e:	02c92603          	lw	a2,44(s2)
    80004682:	47f5                	li	a5,29
    80004684:	06c7c563          	blt	a5,a2,800046ee <log_write+0x90>
    80004688:	0001e797          	auipc	a5,0x1e
    8000468c:	a047a783          	lw	a5,-1532(a5) # 8002208c <log+0x1c>
    80004690:	37fd                	addiw	a5,a5,-1
    80004692:	04f65e63          	bge	a2,a5,800046ee <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004696:	0001e797          	auipc	a5,0x1e
    8000469a:	9fa7a783          	lw	a5,-1542(a5) # 80022090 <log+0x20>
    8000469e:	06f05063          	blez	a5,800046fe <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046a2:	4781                	li	a5,0
    800046a4:	06c05563          	blez	a2,8000470e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800046a8:	44cc                	lw	a1,12(s1)
    800046aa:	0001e717          	auipc	a4,0x1e
    800046ae:	9f670713          	addi	a4,a4,-1546 # 800220a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046b2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800046b4:	4314                	lw	a3,0(a4)
    800046b6:	04b68c63          	beq	a3,a1,8000470e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046ba:	2785                	addiw	a5,a5,1
    800046bc:	0711                	addi	a4,a4,4
    800046be:	fef61be3          	bne	a2,a5,800046b4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046c2:	0621                	addi	a2,a2,8
    800046c4:	060a                	slli	a2,a2,0x2
    800046c6:	0001e797          	auipc	a5,0x1e
    800046ca:	9aa78793          	addi	a5,a5,-1622 # 80022070 <log>
    800046ce:	963e                	add	a2,a2,a5
    800046d0:	44dc                	lw	a5,12(s1)
    800046d2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046d4:	8526                	mv	a0,s1
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	da4080e7          	jalr	-604(ra) # 8000347a <bpin>
    log.lh.n++;
    800046de:	0001e717          	auipc	a4,0x1e
    800046e2:	99270713          	addi	a4,a4,-1646 # 80022070 <log>
    800046e6:	575c                	lw	a5,44(a4)
    800046e8:	2785                	addiw	a5,a5,1
    800046ea:	d75c                	sw	a5,44(a4)
    800046ec:	a835                	j	80004728 <log_write+0xca>
    panic("too big a transaction");
    800046ee:	00004517          	auipc	a0,0x4
    800046f2:	06a50513          	addi	a0,a0,106 # 80008758 <syscalls+0x208>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	e34080e7          	jalr	-460(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800046fe:	00004517          	auipc	a0,0x4
    80004702:	07250513          	addi	a0,a0,114 # 80008770 <syscalls+0x220>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	e24080e7          	jalr	-476(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000470e:	00878713          	addi	a4,a5,8
    80004712:	00271693          	slli	a3,a4,0x2
    80004716:	0001e717          	auipc	a4,0x1e
    8000471a:	95a70713          	addi	a4,a4,-1702 # 80022070 <log>
    8000471e:	9736                	add	a4,a4,a3
    80004720:	44d4                	lw	a3,12(s1)
    80004722:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004724:	faf608e3          	beq	a2,a5,800046d4 <log_write+0x76>
  }
  release(&log.lock);
    80004728:	0001e517          	auipc	a0,0x1e
    8000472c:	94850513          	addi	a0,a0,-1720 # 80022070 <log>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	546080e7          	jalr	1350(ra) # 80000c76 <release>
}
    80004738:	60e2                	ld	ra,24(sp)
    8000473a:	6442                	ld	s0,16(sp)
    8000473c:	64a2                	ld	s1,8(sp)
    8000473e:	6902                	ld	s2,0(sp)
    80004740:	6105                	addi	sp,sp,32
    80004742:	8082                	ret

0000000080004744 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004744:	1101                	addi	sp,sp,-32
    80004746:	ec06                	sd	ra,24(sp)
    80004748:	e822                	sd	s0,16(sp)
    8000474a:	e426                	sd	s1,8(sp)
    8000474c:	e04a                	sd	s2,0(sp)
    8000474e:	1000                	addi	s0,sp,32
    80004750:	84aa                	mv	s1,a0
    80004752:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004754:	00004597          	auipc	a1,0x4
    80004758:	03c58593          	addi	a1,a1,60 # 80008790 <syscalls+0x240>
    8000475c:	0521                	addi	a0,a0,8
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	3d4080e7          	jalr	980(ra) # 80000b32 <initlock>
  lk->name = name;
    80004766:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000476a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000476e:	0204a423          	sw	zero,40(s1)
}
    80004772:	60e2                	ld	ra,24(sp)
    80004774:	6442                	ld	s0,16(sp)
    80004776:	64a2                	ld	s1,8(sp)
    80004778:	6902                	ld	s2,0(sp)
    8000477a:	6105                	addi	sp,sp,32
    8000477c:	8082                	ret

000000008000477e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000477e:	1101                	addi	sp,sp,-32
    80004780:	ec06                	sd	ra,24(sp)
    80004782:	e822                	sd	s0,16(sp)
    80004784:	e426                	sd	s1,8(sp)
    80004786:	e04a                	sd	s2,0(sp)
    80004788:	1000                	addi	s0,sp,32
    8000478a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000478c:	00850913          	addi	s2,a0,8
    80004790:	854a                	mv	a0,s2
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	430080e7          	jalr	1072(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000479a:	409c                	lw	a5,0(s1)
    8000479c:	cb89                	beqz	a5,800047ae <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000479e:	85ca                	mv	a1,s2
    800047a0:	8526                	mv	a0,s1
    800047a2:	ffffe097          	auipc	ra,0xffffe
    800047a6:	948080e7          	jalr	-1720(ra) # 800020ea <sleep>
  while (lk->locked) {
    800047aa:	409c                	lw	a5,0(s1)
    800047ac:	fbed                	bnez	a5,8000479e <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047ae:	4785                	li	a5,1
    800047b0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047b2:	ffffd097          	auipc	ra,0xffffd
    800047b6:	1cc080e7          	jalr	460(ra) # 8000197e <myproc>
    800047ba:	591c                	lw	a5,48(a0)
    800047bc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047be:	854a                	mv	a0,s2
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	4b6080e7          	jalr	1206(ra) # 80000c76 <release>
}
    800047c8:	60e2                	ld	ra,24(sp)
    800047ca:	6442                	ld	s0,16(sp)
    800047cc:	64a2                	ld	s1,8(sp)
    800047ce:	6902                	ld	s2,0(sp)
    800047d0:	6105                	addi	sp,sp,32
    800047d2:	8082                	ret

00000000800047d4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047d4:	1101                	addi	sp,sp,-32
    800047d6:	ec06                	sd	ra,24(sp)
    800047d8:	e822                	sd	s0,16(sp)
    800047da:	e426                	sd	s1,8(sp)
    800047dc:	e04a                	sd	s2,0(sp)
    800047de:	1000                	addi	s0,sp,32
    800047e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047e2:	00850913          	addi	s2,a0,8
    800047e6:	854a                	mv	a0,s2
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	3da080e7          	jalr	986(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800047f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047f4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffe097          	auipc	ra,0xffffe
    800047fe:	b64080e7          	jalr	-1180(ra) # 8000235e <wakeup>
  release(&lk->lk);
    80004802:	854a                	mv	a0,s2
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	472080e7          	jalr	1138(ra) # 80000c76 <release>
}
    8000480c:	60e2                	ld	ra,24(sp)
    8000480e:	6442                	ld	s0,16(sp)
    80004810:	64a2                	ld	s1,8(sp)
    80004812:	6902                	ld	s2,0(sp)
    80004814:	6105                	addi	sp,sp,32
    80004816:	8082                	ret

0000000080004818 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004818:	7179                	addi	sp,sp,-48
    8000481a:	f406                	sd	ra,40(sp)
    8000481c:	f022                	sd	s0,32(sp)
    8000481e:	ec26                	sd	s1,24(sp)
    80004820:	e84a                	sd	s2,16(sp)
    80004822:	e44e                	sd	s3,8(sp)
    80004824:	1800                	addi	s0,sp,48
    80004826:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004828:	00850913          	addi	s2,a0,8
    8000482c:	854a                	mv	a0,s2
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	394080e7          	jalr	916(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004836:	409c                	lw	a5,0(s1)
    80004838:	ef99                	bnez	a5,80004856 <holdingsleep+0x3e>
    8000483a:	4481                	li	s1,0
  release(&lk->lk);
    8000483c:	854a                	mv	a0,s2
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	438080e7          	jalr	1080(ra) # 80000c76 <release>
  return r;
}
    80004846:	8526                	mv	a0,s1
    80004848:	70a2                	ld	ra,40(sp)
    8000484a:	7402                	ld	s0,32(sp)
    8000484c:	64e2                	ld	s1,24(sp)
    8000484e:	6942                	ld	s2,16(sp)
    80004850:	69a2                	ld	s3,8(sp)
    80004852:	6145                	addi	sp,sp,48
    80004854:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004856:	0284a983          	lw	s3,40(s1)
    8000485a:	ffffd097          	auipc	ra,0xffffd
    8000485e:	124080e7          	jalr	292(ra) # 8000197e <myproc>
    80004862:	5904                	lw	s1,48(a0)
    80004864:	413484b3          	sub	s1,s1,s3
    80004868:	0014b493          	seqz	s1,s1
    8000486c:	bfc1                	j	8000483c <holdingsleep+0x24>

000000008000486e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000486e:	1141                	addi	sp,sp,-16
    80004870:	e406                	sd	ra,8(sp)
    80004872:	e022                	sd	s0,0(sp)
    80004874:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004876:	00004597          	auipc	a1,0x4
    8000487a:	f2a58593          	addi	a1,a1,-214 # 800087a0 <syscalls+0x250>
    8000487e:	0001e517          	auipc	a0,0x1e
    80004882:	93a50513          	addi	a0,a0,-1734 # 800221b8 <ftable>
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	2ac080e7          	jalr	684(ra) # 80000b32 <initlock>
}
    8000488e:	60a2                	ld	ra,8(sp)
    80004890:	6402                	ld	s0,0(sp)
    80004892:	0141                	addi	sp,sp,16
    80004894:	8082                	ret

0000000080004896 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004896:	1101                	addi	sp,sp,-32
    80004898:	ec06                	sd	ra,24(sp)
    8000489a:	e822                	sd	s0,16(sp)
    8000489c:	e426                	sd	s1,8(sp)
    8000489e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048a0:	0001e517          	auipc	a0,0x1e
    800048a4:	91850513          	addi	a0,a0,-1768 # 800221b8 <ftable>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	31a080e7          	jalr	794(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048b0:	0001e497          	auipc	s1,0x1e
    800048b4:	92048493          	addi	s1,s1,-1760 # 800221d0 <ftable+0x18>
    800048b8:	0001f717          	auipc	a4,0x1f
    800048bc:	8b870713          	addi	a4,a4,-1864 # 80023170 <ftable+0xfb8>
    if(f->ref == 0){
    800048c0:	40dc                	lw	a5,4(s1)
    800048c2:	cf99                	beqz	a5,800048e0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048c4:	02848493          	addi	s1,s1,40
    800048c8:	fee49ce3          	bne	s1,a4,800048c0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048cc:	0001e517          	auipc	a0,0x1e
    800048d0:	8ec50513          	addi	a0,a0,-1812 # 800221b8 <ftable>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	3a2080e7          	jalr	930(ra) # 80000c76 <release>
  return 0;
    800048dc:	4481                	li	s1,0
    800048de:	a819                	j	800048f4 <filealloc+0x5e>
      f->ref = 1;
    800048e0:	4785                	li	a5,1
    800048e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048e4:	0001e517          	auipc	a0,0x1e
    800048e8:	8d450513          	addi	a0,a0,-1836 # 800221b8 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	38a080e7          	jalr	906(ra) # 80000c76 <release>
}
    800048f4:	8526                	mv	a0,s1
    800048f6:	60e2                	ld	ra,24(sp)
    800048f8:	6442                	ld	s0,16(sp)
    800048fa:	64a2                	ld	s1,8(sp)
    800048fc:	6105                	addi	sp,sp,32
    800048fe:	8082                	ret

0000000080004900 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004900:	1101                	addi	sp,sp,-32
    80004902:	ec06                	sd	ra,24(sp)
    80004904:	e822                	sd	s0,16(sp)
    80004906:	e426                	sd	s1,8(sp)
    80004908:	1000                	addi	s0,sp,32
    8000490a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000490c:	0001e517          	auipc	a0,0x1e
    80004910:	8ac50513          	addi	a0,a0,-1876 # 800221b8 <ftable>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	2ae080e7          	jalr	686(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000491c:	40dc                	lw	a5,4(s1)
    8000491e:	02f05263          	blez	a5,80004942 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004922:	2785                	addiw	a5,a5,1
    80004924:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004926:	0001e517          	auipc	a0,0x1e
    8000492a:	89250513          	addi	a0,a0,-1902 # 800221b8 <ftable>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	348080e7          	jalr	840(ra) # 80000c76 <release>
  return f;
}
    80004936:	8526                	mv	a0,s1
    80004938:	60e2                	ld	ra,24(sp)
    8000493a:	6442                	ld	s0,16(sp)
    8000493c:	64a2                	ld	s1,8(sp)
    8000493e:	6105                	addi	sp,sp,32
    80004940:	8082                	ret
    panic("filedup");
    80004942:	00004517          	auipc	a0,0x4
    80004946:	e6650513          	addi	a0,a0,-410 # 800087a8 <syscalls+0x258>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	be0080e7          	jalr	-1056(ra) # 8000052a <panic>

0000000080004952 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004952:	7139                	addi	sp,sp,-64
    80004954:	fc06                	sd	ra,56(sp)
    80004956:	f822                	sd	s0,48(sp)
    80004958:	f426                	sd	s1,40(sp)
    8000495a:	f04a                	sd	s2,32(sp)
    8000495c:	ec4e                	sd	s3,24(sp)
    8000495e:	e852                	sd	s4,16(sp)
    80004960:	e456                	sd	s5,8(sp)
    80004962:	0080                	addi	s0,sp,64
    80004964:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004966:	0001e517          	auipc	a0,0x1e
    8000496a:	85250513          	addi	a0,a0,-1966 # 800221b8 <ftable>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	254080e7          	jalr	596(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004976:	40dc                	lw	a5,4(s1)
    80004978:	06f05163          	blez	a5,800049da <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000497c:	37fd                	addiw	a5,a5,-1
    8000497e:	0007871b          	sext.w	a4,a5
    80004982:	c0dc                	sw	a5,4(s1)
    80004984:	06e04363          	bgtz	a4,800049ea <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004988:	0004a903          	lw	s2,0(s1)
    8000498c:	0094ca83          	lbu	s5,9(s1)
    80004990:	0104ba03          	ld	s4,16(s1)
    80004994:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004998:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000499c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049a0:	0001e517          	auipc	a0,0x1e
    800049a4:	81850513          	addi	a0,a0,-2024 # 800221b8 <ftable>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	2ce080e7          	jalr	718(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800049b0:	4785                	li	a5,1
    800049b2:	04f90d63          	beq	s2,a5,80004a0c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049b6:	3979                	addiw	s2,s2,-2
    800049b8:	4785                	li	a5,1
    800049ba:	0527e063          	bltu	a5,s2,800049fa <fileclose+0xa8>
    begin_op();
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	ac8080e7          	jalr	-1336(ra) # 80004486 <begin_op>
    iput(ff.ip);
    800049c6:	854e                	mv	a0,s3
    800049c8:	fffff097          	auipc	ra,0xfffff
    800049cc:	2a2080e7          	jalr	674(ra) # 80003c6a <iput>
    end_op();
    800049d0:	00000097          	auipc	ra,0x0
    800049d4:	b36080e7          	jalr	-1226(ra) # 80004506 <end_op>
    800049d8:	a00d                	j	800049fa <fileclose+0xa8>
    panic("fileclose");
    800049da:	00004517          	auipc	a0,0x4
    800049de:	dd650513          	addi	a0,a0,-554 # 800087b0 <syscalls+0x260>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	b48080e7          	jalr	-1208(ra) # 8000052a <panic>
    release(&ftable.lock);
    800049ea:	0001d517          	auipc	a0,0x1d
    800049ee:	7ce50513          	addi	a0,a0,1998 # 800221b8 <ftable>
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	284080e7          	jalr	644(ra) # 80000c76 <release>
  }
}
    800049fa:	70e2                	ld	ra,56(sp)
    800049fc:	7442                	ld	s0,48(sp)
    800049fe:	74a2                	ld	s1,40(sp)
    80004a00:	7902                	ld	s2,32(sp)
    80004a02:	69e2                	ld	s3,24(sp)
    80004a04:	6a42                	ld	s4,16(sp)
    80004a06:	6aa2                	ld	s5,8(sp)
    80004a08:	6121                	addi	sp,sp,64
    80004a0a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a0c:	85d6                	mv	a1,s5
    80004a0e:	8552                	mv	a0,s4
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	34c080e7          	jalr	844(ra) # 80004d5c <pipeclose>
    80004a18:	b7cd                	j	800049fa <fileclose+0xa8>

0000000080004a1a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a1a:	715d                	addi	sp,sp,-80
    80004a1c:	e486                	sd	ra,72(sp)
    80004a1e:	e0a2                	sd	s0,64(sp)
    80004a20:	fc26                	sd	s1,56(sp)
    80004a22:	f84a                	sd	s2,48(sp)
    80004a24:	f44e                	sd	s3,40(sp)
    80004a26:	0880                	addi	s0,sp,80
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	f52080e7          	jalr	-174(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a34:	409c                	lw	a5,0(s1)
    80004a36:	37f9                	addiw	a5,a5,-2
    80004a38:	4705                	li	a4,1
    80004a3a:	04f76763          	bltu	a4,a5,80004a88 <filestat+0x6e>
    80004a3e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a40:	6c88                	ld	a0,24(s1)
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	06e080e7          	jalr	110(ra) # 80003ab0 <ilock>
    stati(f->ip, &st);
    80004a4a:	fb840593          	addi	a1,s0,-72
    80004a4e:	6c88                	ld	a0,24(s1)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	2ea080e7          	jalr	746(ra) # 80003d3a <stati>
    iunlock(f->ip);
    80004a58:	6c88                	ld	a0,24(s1)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	118080e7          	jalr	280(ra) # 80003b72 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a62:	46e1                	li	a3,24
    80004a64:	fb840613          	addi	a2,s0,-72
    80004a68:	85ce                	mv	a1,s3
    80004a6a:	08893503          	ld	a0,136(s2)
    80004a6e:	ffffd097          	auipc	ra,0xffffd
    80004a72:	bd0080e7          	jalr	-1072(ra) # 8000163e <copyout>
    80004a76:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a7a:	60a6                	ld	ra,72(sp)
    80004a7c:	6406                	ld	s0,64(sp)
    80004a7e:	74e2                	ld	s1,56(sp)
    80004a80:	7942                	ld	s2,48(sp)
    80004a82:	79a2                	ld	s3,40(sp)
    80004a84:	6161                	addi	sp,sp,80
    80004a86:	8082                	ret
  return -1;
    80004a88:	557d                	li	a0,-1
    80004a8a:	bfc5                	j	80004a7a <filestat+0x60>

0000000080004a8c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a8c:	7179                	addi	sp,sp,-48
    80004a8e:	f406                	sd	ra,40(sp)
    80004a90:	f022                	sd	s0,32(sp)
    80004a92:	ec26                	sd	s1,24(sp)
    80004a94:	e84a                	sd	s2,16(sp)
    80004a96:	e44e                	sd	s3,8(sp)
    80004a98:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a9a:	00854783          	lbu	a5,8(a0)
    80004a9e:	c3d5                	beqz	a5,80004b42 <fileread+0xb6>
    80004aa0:	84aa                	mv	s1,a0
    80004aa2:	89ae                	mv	s3,a1
    80004aa4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004aa6:	411c                	lw	a5,0(a0)
    80004aa8:	4705                	li	a4,1
    80004aaa:	04e78963          	beq	a5,a4,80004afc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aae:	470d                	li	a4,3
    80004ab0:	04e78d63          	beq	a5,a4,80004b0a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ab4:	4709                	li	a4,2
    80004ab6:	06e79e63          	bne	a5,a4,80004b32 <fileread+0xa6>
    ilock(f->ip);
    80004aba:	6d08                	ld	a0,24(a0)
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	ff4080e7          	jalr	-12(ra) # 80003ab0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ac4:	874a                	mv	a4,s2
    80004ac6:	5094                	lw	a3,32(s1)
    80004ac8:	864e                	mv	a2,s3
    80004aca:	4585                	li	a1,1
    80004acc:	6c88                	ld	a0,24(s1)
    80004ace:	fffff097          	auipc	ra,0xfffff
    80004ad2:	296080e7          	jalr	662(ra) # 80003d64 <readi>
    80004ad6:	892a                	mv	s2,a0
    80004ad8:	00a05563          	blez	a0,80004ae2 <fileread+0x56>
      f->off += r;
    80004adc:	509c                	lw	a5,32(s1)
    80004ade:	9fa9                	addw	a5,a5,a0
    80004ae0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ae2:	6c88                	ld	a0,24(s1)
    80004ae4:	fffff097          	auipc	ra,0xfffff
    80004ae8:	08e080e7          	jalr	142(ra) # 80003b72 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004aec:	854a                	mv	a0,s2
    80004aee:	70a2                	ld	ra,40(sp)
    80004af0:	7402                	ld	s0,32(sp)
    80004af2:	64e2                	ld	s1,24(sp)
    80004af4:	6942                	ld	s2,16(sp)
    80004af6:	69a2                	ld	s3,8(sp)
    80004af8:	6145                	addi	sp,sp,48
    80004afa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004afc:	6908                	ld	a0,16(a0)
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	3c0080e7          	jalr	960(ra) # 80004ebe <piperead>
    80004b06:	892a                	mv	s2,a0
    80004b08:	b7d5                	j	80004aec <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b0a:	02451783          	lh	a5,36(a0)
    80004b0e:	03079693          	slli	a3,a5,0x30
    80004b12:	92c1                	srli	a3,a3,0x30
    80004b14:	4725                	li	a4,9
    80004b16:	02d76863          	bltu	a4,a3,80004b46 <fileread+0xba>
    80004b1a:	0792                	slli	a5,a5,0x4
    80004b1c:	0001d717          	auipc	a4,0x1d
    80004b20:	5fc70713          	addi	a4,a4,1532 # 80022118 <devsw>
    80004b24:	97ba                	add	a5,a5,a4
    80004b26:	639c                	ld	a5,0(a5)
    80004b28:	c38d                	beqz	a5,80004b4a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b2a:	4505                	li	a0,1
    80004b2c:	9782                	jalr	a5
    80004b2e:	892a                	mv	s2,a0
    80004b30:	bf75                	j	80004aec <fileread+0x60>
    panic("fileread");
    80004b32:	00004517          	auipc	a0,0x4
    80004b36:	c8e50513          	addi	a0,a0,-882 # 800087c0 <syscalls+0x270>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	9f0080e7          	jalr	-1552(ra) # 8000052a <panic>
    return -1;
    80004b42:	597d                	li	s2,-1
    80004b44:	b765                	j	80004aec <fileread+0x60>
      return -1;
    80004b46:	597d                	li	s2,-1
    80004b48:	b755                	j	80004aec <fileread+0x60>
    80004b4a:	597d                	li	s2,-1
    80004b4c:	b745                	j	80004aec <fileread+0x60>

0000000080004b4e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b4e:	715d                	addi	sp,sp,-80
    80004b50:	e486                	sd	ra,72(sp)
    80004b52:	e0a2                	sd	s0,64(sp)
    80004b54:	fc26                	sd	s1,56(sp)
    80004b56:	f84a                	sd	s2,48(sp)
    80004b58:	f44e                	sd	s3,40(sp)
    80004b5a:	f052                	sd	s4,32(sp)
    80004b5c:	ec56                	sd	s5,24(sp)
    80004b5e:	e85a                	sd	s6,16(sp)
    80004b60:	e45e                	sd	s7,8(sp)
    80004b62:	e062                	sd	s8,0(sp)
    80004b64:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b66:	00954783          	lbu	a5,9(a0)
    80004b6a:	10078663          	beqz	a5,80004c76 <filewrite+0x128>
    80004b6e:	892a                	mv	s2,a0
    80004b70:	8aae                	mv	s5,a1
    80004b72:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b74:	411c                	lw	a5,0(a0)
    80004b76:	4705                	li	a4,1
    80004b78:	02e78263          	beq	a5,a4,80004b9c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b7c:	470d                	li	a4,3
    80004b7e:	02e78663          	beq	a5,a4,80004baa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b82:	4709                	li	a4,2
    80004b84:	0ee79163          	bne	a5,a4,80004c66 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b88:	0ac05d63          	blez	a2,80004c42 <filewrite+0xf4>
    int i = 0;
    80004b8c:	4981                	li	s3,0
    80004b8e:	6b05                	lui	s6,0x1
    80004b90:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b94:	6b85                	lui	s7,0x1
    80004b96:	c00b8b9b          	addiw	s7,s7,-1024
    80004b9a:	a861                	j	80004c32 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b9c:	6908                	ld	a0,16(a0)
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	22e080e7          	jalr	558(ra) # 80004dcc <pipewrite>
    80004ba6:	8a2a                	mv	s4,a0
    80004ba8:	a045                	j	80004c48 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004baa:	02451783          	lh	a5,36(a0)
    80004bae:	03079693          	slli	a3,a5,0x30
    80004bb2:	92c1                	srli	a3,a3,0x30
    80004bb4:	4725                	li	a4,9
    80004bb6:	0cd76263          	bltu	a4,a3,80004c7a <filewrite+0x12c>
    80004bba:	0792                	slli	a5,a5,0x4
    80004bbc:	0001d717          	auipc	a4,0x1d
    80004bc0:	55c70713          	addi	a4,a4,1372 # 80022118 <devsw>
    80004bc4:	97ba                	add	a5,a5,a4
    80004bc6:	679c                	ld	a5,8(a5)
    80004bc8:	cbdd                	beqz	a5,80004c7e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bca:	4505                	li	a0,1
    80004bcc:	9782                	jalr	a5
    80004bce:	8a2a                	mv	s4,a0
    80004bd0:	a8a5                	j	80004c48 <filewrite+0xfa>
    80004bd2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	8b0080e7          	jalr	-1872(ra) # 80004486 <begin_op>
      ilock(f->ip);
    80004bde:	01893503          	ld	a0,24(s2)
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	ece080e7          	jalr	-306(ra) # 80003ab0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004bea:	8762                	mv	a4,s8
    80004bec:	02092683          	lw	a3,32(s2)
    80004bf0:	01598633          	add	a2,s3,s5
    80004bf4:	4585                	li	a1,1
    80004bf6:	01893503          	ld	a0,24(s2)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	262080e7          	jalr	610(ra) # 80003e5c <writei>
    80004c02:	84aa                	mv	s1,a0
    80004c04:	00a05763          	blez	a0,80004c12 <filewrite+0xc4>
        f->off += r;
    80004c08:	02092783          	lw	a5,32(s2)
    80004c0c:	9fa9                	addw	a5,a5,a0
    80004c0e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c12:	01893503          	ld	a0,24(s2)
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	f5c080e7          	jalr	-164(ra) # 80003b72 <iunlock>
      end_op();
    80004c1e:	00000097          	auipc	ra,0x0
    80004c22:	8e8080e7          	jalr	-1816(ra) # 80004506 <end_op>

      if(r != n1){
    80004c26:	009c1f63          	bne	s8,s1,80004c44 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c2a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c2e:	0149db63          	bge	s3,s4,80004c44 <filewrite+0xf6>
      int n1 = n - i;
    80004c32:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c36:	84be                	mv	s1,a5
    80004c38:	2781                	sext.w	a5,a5
    80004c3a:	f8fb5ce3          	bge	s6,a5,80004bd2 <filewrite+0x84>
    80004c3e:	84de                	mv	s1,s7
    80004c40:	bf49                	j	80004bd2 <filewrite+0x84>
    int i = 0;
    80004c42:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c44:	013a1f63          	bne	s4,s3,80004c62 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c48:	8552                	mv	a0,s4
    80004c4a:	60a6                	ld	ra,72(sp)
    80004c4c:	6406                	ld	s0,64(sp)
    80004c4e:	74e2                	ld	s1,56(sp)
    80004c50:	7942                	ld	s2,48(sp)
    80004c52:	79a2                	ld	s3,40(sp)
    80004c54:	7a02                	ld	s4,32(sp)
    80004c56:	6ae2                	ld	s5,24(sp)
    80004c58:	6b42                	ld	s6,16(sp)
    80004c5a:	6ba2                	ld	s7,8(sp)
    80004c5c:	6c02                	ld	s8,0(sp)
    80004c5e:	6161                	addi	sp,sp,80
    80004c60:	8082                	ret
    ret = (i == n ? n : -1);
    80004c62:	5a7d                	li	s4,-1
    80004c64:	b7d5                	j	80004c48 <filewrite+0xfa>
    panic("filewrite");
    80004c66:	00004517          	auipc	a0,0x4
    80004c6a:	b6a50513          	addi	a0,a0,-1174 # 800087d0 <syscalls+0x280>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>
    return -1;
    80004c76:	5a7d                	li	s4,-1
    80004c78:	bfc1                	j	80004c48 <filewrite+0xfa>
      return -1;
    80004c7a:	5a7d                	li	s4,-1
    80004c7c:	b7f1                	j	80004c48 <filewrite+0xfa>
    80004c7e:	5a7d                	li	s4,-1
    80004c80:	b7e1                	j	80004c48 <filewrite+0xfa>

0000000080004c82 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c82:	7179                	addi	sp,sp,-48
    80004c84:	f406                	sd	ra,40(sp)
    80004c86:	f022                	sd	s0,32(sp)
    80004c88:	ec26                	sd	s1,24(sp)
    80004c8a:	e84a                	sd	s2,16(sp)
    80004c8c:	e44e                	sd	s3,8(sp)
    80004c8e:	e052                	sd	s4,0(sp)
    80004c90:	1800                	addi	s0,sp,48
    80004c92:	84aa                	mv	s1,a0
    80004c94:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c96:	0005b023          	sd	zero,0(a1)
    80004c9a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c9e:	00000097          	auipc	ra,0x0
    80004ca2:	bf8080e7          	jalr	-1032(ra) # 80004896 <filealloc>
    80004ca6:	e088                	sd	a0,0(s1)
    80004ca8:	c551                	beqz	a0,80004d34 <pipealloc+0xb2>
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	bec080e7          	jalr	-1044(ra) # 80004896 <filealloc>
    80004cb2:	00aa3023          	sd	a0,0(s4)
    80004cb6:	c92d                	beqz	a0,80004d28 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	e1a080e7          	jalr	-486(ra) # 80000ad2 <kalloc>
    80004cc0:	892a                	mv	s2,a0
    80004cc2:	c125                	beqz	a0,80004d22 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cc4:	4985                	li	s3,1
    80004cc6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cca:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cce:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cd2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cd6:	00003597          	auipc	a1,0x3
    80004cda:	7b258593          	addi	a1,a1,1970 # 80008488 <states.0+0x1e0>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	e54080e7          	jalr	-428(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004ce6:	609c                	ld	a5,0(s1)
    80004ce8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004cec:	609c                	ld	a5,0(s1)
    80004cee:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004cf2:	609c                	ld	a5,0(s1)
    80004cf4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cf8:	609c                	ld	a5,0(s1)
    80004cfa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cfe:	000a3783          	ld	a5,0(s4)
    80004d02:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d06:	000a3783          	ld	a5,0(s4)
    80004d0a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d0e:	000a3783          	ld	a5,0(s4)
    80004d12:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d16:	000a3783          	ld	a5,0(s4)
    80004d1a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d1e:	4501                	li	a0,0
    80004d20:	a025                	j	80004d48 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d22:	6088                	ld	a0,0(s1)
    80004d24:	e501                	bnez	a0,80004d2c <pipealloc+0xaa>
    80004d26:	a039                	j	80004d34 <pipealloc+0xb2>
    80004d28:	6088                	ld	a0,0(s1)
    80004d2a:	c51d                	beqz	a0,80004d58 <pipealloc+0xd6>
    fileclose(*f0);
    80004d2c:	00000097          	auipc	ra,0x0
    80004d30:	c26080e7          	jalr	-986(ra) # 80004952 <fileclose>
  if(*f1)
    80004d34:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d38:	557d                	li	a0,-1
  if(*f1)
    80004d3a:	c799                	beqz	a5,80004d48 <pipealloc+0xc6>
    fileclose(*f1);
    80004d3c:	853e                	mv	a0,a5
    80004d3e:	00000097          	auipc	ra,0x0
    80004d42:	c14080e7          	jalr	-1004(ra) # 80004952 <fileclose>
  return -1;
    80004d46:	557d                	li	a0,-1
}
    80004d48:	70a2                	ld	ra,40(sp)
    80004d4a:	7402                	ld	s0,32(sp)
    80004d4c:	64e2                	ld	s1,24(sp)
    80004d4e:	6942                	ld	s2,16(sp)
    80004d50:	69a2                	ld	s3,8(sp)
    80004d52:	6a02                	ld	s4,0(sp)
    80004d54:	6145                	addi	sp,sp,48
    80004d56:	8082                	ret
  return -1;
    80004d58:	557d                	li	a0,-1
    80004d5a:	b7fd                	j	80004d48 <pipealloc+0xc6>

0000000080004d5c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d5c:	1101                	addi	sp,sp,-32
    80004d5e:	ec06                	sd	ra,24(sp)
    80004d60:	e822                	sd	s0,16(sp)
    80004d62:	e426                	sd	s1,8(sp)
    80004d64:	e04a                	sd	s2,0(sp)
    80004d66:	1000                	addi	s0,sp,32
    80004d68:	84aa                	mv	s1,a0
    80004d6a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	e56080e7          	jalr	-426(ra) # 80000bc2 <acquire>
  if(writable){
    80004d74:	02090d63          	beqz	s2,80004dae <pipeclose+0x52>
    pi->writeopen = 0;
    80004d78:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d7c:	21848513          	addi	a0,s1,536
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	5de080e7          	jalr	1502(ra) # 8000235e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d88:	2204b783          	ld	a5,544(s1)
    80004d8c:	eb95                	bnez	a5,80004dc0 <pipeclose+0x64>
    release(&pi->lock);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	ee6080e7          	jalr	-282(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	c3c080e7          	jalr	-964(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004da2:	60e2                	ld	ra,24(sp)
    80004da4:	6442                	ld	s0,16(sp)
    80004da6:	64a2                	ld	s1,8(sp)
    80004da8:	6902                	ld	s2,0(sp)
    80004daa:	6105                	addi	sp,sp,32
    80004dac:	8082                	ret
    pi->readopen = 0;
    80004dae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004db2:	21c48513          	addi	a0,s1,540
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	5a8080e7          	jalr	1448(ra) # 8000235e <wakeup>
    80004dbe:	b7e9                	j	80004d88 <pipeclose+0x2c>
    release(&pi->lock);
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	eb4080e7          	jalr	-332(ra) # 80000c76 <release>
}
    80004dca:	bfe1                	j	80004da2 <pipeclose+0x46>

0000000080004dcc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dcc:	711d                	addi	sp,sp,-96
    80004dce:	ec86                	sd	ra,88(sp)
    80004dd0:	e8a2                	sd	s0,80(sp)
    80004dd2:	e4a6                	sd	s1,72(sp)
    80004dd4:	e0ca                	sd	s2,64(sp)
    80004dd6:	fc4e                	sd	s3,56(sp)
    80004dd8:	f852                	sd	s4,48(sp)
    80004dda:	f456                	sd	s5,40(sp)
    80004ddc:	f05a                	sd	s6,32(sp)
    80004dde:	ec5e                	sd	s7,24(sp)
    80004de0:	e862                	sd	s8,16(sp)
    80004de2:	1080                	addi	s0,sp,96
    80004de4:	84aa                	mv	s1,a0
    80004de6:	8aae                	mv	s5,a1
    80004de8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	b94080e7          	jalr	-1132(ra) # 8000197e <myproc>
    80004df2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	dcc080e7          	jalr	-564(ra) # 80000bc2 <acquire>
  while(i < n){
    80004dfe:	0b405363          	blez	s4,80004ea4 <pipewrite+0xd8>
  int i = 0;
    80004e02:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e04:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e06:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e0a:	21c48b93          	addi	s7,s1,540
    80004e0e:	a089                	j	80004e50 <pipewrite+0x84>
      release(&pi->lock);
    80004e10:	8526                	mv	a0,s1
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	e64080e7          	jalr	-412(ra) # 80000c76 <release>
      return -1;
    80004e1a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e1c:	854a                	mv	a0,s2
    80004e1e:	60e6                	ld	ra,88(sp)
    80004e20:	6446                	ld	s0,80(sp)
    80004e22:	64a6                	ld	s1,72(sp)
    80004e24:	6906                	ld	s2,64(sp)
    80004e26:	79e2                	ld	s3,56(sp)
    80004e28:	7a42                	ld	s4,48(sp)
    80004e2a:	7aa2                	ld	s5,40(sp)
    80004e2c:	7b02                	ld	s6,32(sp)
    80004e2e:	6be2                	ld	s7,24(sp)
    80004e30:	6c42                	ld	s8,16(sp)
    80004e32:	6125                	addi	sp,sp,96
    80004e34:	8082                	ret
      wakeup(&pi->nread);
    80004e36:	8562                	mv	a0,s8
    80004e38:	ffffd097          	auipc	ra,0xffffd
    80004e3c:	526080e7          	jalr	1318(ra) # 8000235e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e40:	85a6                	mv	a1,s1
    80004e42:	855e                	mv	a0,s7
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	2a6080e7          	jalr	678(ra) # 800020ea <sleep>
  while(i < n){
    80004e4c:	05495d63          	bge	s2,s4,80004ea6 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004e50:	2204a783          	lw	a5,544(s1)
    80004e54:	dfd5                	beqz	a5,80004e10 <pipewrite+0x44>
    80004e56:	0289a783          	lw	a5,40(s3)
    80004e5a:	fbdd                	bnez	a5,80004e10 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e5c:	2184a783          	lw	a5,536(s1)
    80004e60:	21c4a703          	lw	a4,540(s1)
    80004e64:	2007879b          	addiw	a5,a5,512
    80004e68:	fcf707e3          	beq	a4,a5,80004e36 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e6c:	4685                	li	a3,1
    80004e6e:	01590633          	add	a2,s2,s5
    80004e72:	faf40593          	addi	a1,s0,-81
    80004e76:	0889b503          	ld	a0,136(s3)
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	850080e7          	jalr	-1968(ra) # 800016ca <copyin>
    80004e82:	03650263          	beq	a0,s6,80004ea6 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e86:	21c4a783          	lw	a5,540(s1)
    80004e8a:	0017871b          	addiw	a4,a5,1
    80004e8e:	20e4ae23          	sw	a4,540(s1)
    80004e92:	1ff7f793          	andi	a5,a5,511
    80004e96:	97a6                	add	a5,a5,s1
    80004e98:	faf44703          	lbu	a4,-81(s0)
    80004e9c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ea0:	2905                	addiw	s2,s2,1
    80004ea2:	b76d                	j	80004e4c <pipewrite+0x80>
  int i = 0;
    80004ea4:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ea6:	21848513          	addi	a0,s1,536
    80004eaa:	ffffd097          	auipc	ra,0xffffd
    80004eae:	4b4080e7          	jalr	1204(ra) # 8000235e <wakeup>
  release(&pi->lock);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	dc2080e7          	jalr	-574(ra) # 80000c76 <release>
  return i;
    80004ebc:	b785                	j	80004e1c <pipewrite+0x50>

0000000080004ebe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ebe:	715d                	addi	sp,sp,-80
    80004ec0:	e486                	sd	ra,72(sp)
    80004ec2:	e0a2                	sd	s0,64(sp)
    80004ec4:	fc26                	sd	s1,56(sp)
    80004ec6:	f84a                	sd	s2,48(sp)
    80004ec8:	f44e                	sd	s3,40(sp)
    80004eca:	f052                	sd	s4,32(sp)
    80004ecc:	ec56                	sd	s5,24(sp)
    80004ece:	e85a                	sd	s6,16(sp)
    80004ed0:	0880                	addi	s0,sp,80
    80004ed2:	84aa                	mv	s1,a0
    80004ed4:	892e                	mv	s2,a1
    80004ed6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	aa6080e7          	jalr	-1370(ra) # 8000197e <myproc>
    80004ee0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ee2:	8526                	mv	a0,s1
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	cde080e7          	jalr	-802(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eec:	2184a703          	lw	a4,536(s1)
    80004ef0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ef4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ef8:	02f71463          	bne	a4,a5,80004f20 <piperead+0x62>
    80004efc:	2244a783          	lw	a5,548(s1)
    80004f00:	c385                	beqz	a5,80004f20 <piperead+0x62>
    if(pr->killed){
    80004f02:	028a2783          	lw	a5,40(s4)
    80004f06:	ebc1                	bnez	a5,80004f96 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f08:	85a6                	mv	a1,s1
    80004f0a:	854e                	mv	a0,s3
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	1de080e7          	jalr	478(ra) # 800020ea <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f14:	2184a703          	lw	a4,536(s1)
    80004f18:	21c4a783          	lw	a5,540(s1)
    80004f1c:	fef700e3          	beq	a4,a5,80004efc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f20:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f22:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f24:	05505363          	blez	s5,80004f6a <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004f28:	2184a783          	lw	a5,536(s1)
    80004f2c:	21c4a703          	lw	a4,540(s1)
    80004f30:	02f70d63          	beq	a4,a5,80004f6a <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f34:	0017871b          	addiw	a4,a5,1
    80004f38:	20e4ac23          	sw	a4,536(s1)
    80004f3c:	1ff7f793          	andi	a5,a5,511
    80004f40:	97a6                	add	a5,a5,s1
    80004f42:	0187c783          	lbu	a5,24(a5)
    80004f46:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f4a:	4685                	li	a3,1
    80004f4c:	fbf40613          	addi	a2,s0,-65
    80004f50:	85ca                	mv	a1,s2
    80004f52:	088a3503          	ld	a0,136(s4)
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	6e8080e7          	jalr	1768(ra) # 8000163e <copyout>
    80004f5e:	01650663          	beq	a0,s6,80004f6a <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f62:	2985                	addiw	s3,s3,1
    80004f64:	0905                	addi	s2,s2,1
    80004f66:	fd3a91e3          	bne	s5,s3,80004f28 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f6a:	21c48513          	addi	a0,s1,540
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	3f0080e7          	jalr	1008(ra) # 8000235e <wakeup>
  release(&pi->lock);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	cfe080e7          	jalr	-770(ra) # 80000c76 <release>
  return i;
}
    80004f80:	854e                	mv	a0,s3
    80004f82:	60a6                	ld	ra,72(sp)
    80004f84:	6406                	ld	s0,64(sp)
    80004f86:	74e2                	ld	s1,56(sp)
    80004f88:	7942                	ld	s2,48(sp)
    80004f8a:	79a2                	ld	s3,40(sp)
    80004f8c:	7a02                	ld	s4,32(sp)
    80004f8e:	6ae2                	ld	s5,24(sp)
    80004f90:	6b42                	ld	s6,16(sp)
    80004f92:	6161                	addi	sp,sp,80
    80004f94:	8082                	ret
      release(&pi->lock);
    80004f96:	8526                	mv	a0,s1
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	cde080e7          	jalr	-802(ra) # 80000c76 <release>
      return -1;
    80004fa0:	59fd                	li	s3,-1
    80004fa2:	bff9                	j	80004f80 <piperead+0xc2>

0000000080004fa4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fa4:	de010113          	addi	sp,sp,-544
    80004fa8:	20113c23          	sd	ra,536(sp)
    80004fac:	20813823          	sd	s0,528(sp)
    80004fb0:	20913423          	sd	s1,520(sp)
    80004fb4:	21213023          	sd	s2,512(sp)
    80004fb8:	ffce                	sd	s3,504(sp)
    80004fba:	fbd2                	sd	s4,496(sp)
    80004fbc:	f7d6                	sd	s5,488(sp)
    80004fbe:	f3da                	sd	s6,480(sp)
    80004fc0:	efde                	sd	s7,472(sp)
    80004fc2:	ebe2                	sd	s8,464(sp)
    80004fc4:	e7e6                	sd	s9,456(sp)
    80004fc6:	e3ea                	sd	s10,448(sp)
    80004fc8:	ff6e                	sd	s11,440(sp)
    80004fca:	1400                	addi	s0,sp,544
    80004fcc:	892a                	mv	s2,a0
    80004fce:	dea43423          	sd	a0,-536(s0)
    80004fd2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	9a8080e7          	jalr	-1624(ra) # 8000197e <myproc>
    80004fde:	84aa                	mv	s1,a0

  begin_op();
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	4a6080e7          	jalr	1190(ra) # 80004486 <begin_op>

  if((ip = namei(path)) == 0){
    80004fe8:	854a                	mv	a0,s2
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	27c080e7          	jalr	636(ra) # 80004266 <namei>
    80004ff2:	c93d                	beqz	a0,80005068 <exec+0xc4>
    80004ff4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	aba080e7          	jalr	-1350(ra) # 80003ab0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ffe:	04000713          	li	a4,64
    80005002:	4681                	li	a3,0
    80005004:	e4840613          	addi	a2,s0,-440
    80005008:	4581                	li	a1,0
    8000500a:	8556                	mv	a0,s5
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	d58080e7          	jalr	-680(ra) # 80003d64 <readi>
    80005014:	04000793          	li	a5,64
    80005018:	00f51a63          	bne	a0,a5,8000502c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000501c:	e4842703          	lw	a4,-440(s0)
    80005020:	464c47b7          	lui	a5,0x464c4
    80005024:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005028:	04f70663          	beq	a4,a5,80005074 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000502c:	8556                	mv	a0,s5
    8000502e:	fffff097          	auipc	ra,0xfffff
    80005032:	ce4080e7          	jalr	-796(ra) # 80003d12 <iunlockput>
    end_op();
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	4d0080e7          	jalr	1232(ra) # 80004506 <end_op>
  }
  return -1;
    8000503e:	557d                	li	a0,-1
}
    80005040:	21813083          	ld	ra,536(sp)
    80005044:	21013403          	ld	s0,528(sp)
    80005048:	20813483          	ld	s1,520(sp)
    8000504c:	20013903          	ld	s2,512(sp)
    80005050:	79fe                	ld	s3,504(sp)
    80005052:	7a5e                	ld	s4,496(sp)
    80005054:	7abe                	ld	s5,488(sp)
    80005056:	7b1e                	ld	s6,480(sp)
    80005058:	6bfe                	ld	s7,472(sp)
    8000505a:	6c5e                	ld	s8,464(sp)
    8000505c:	6cbe                	ld	s9,456(sp)
    8000505e:	6d1e                	ld	s10,448(sp)
    80005060:	7dfa                	ld	s11,440(sp)
    80005062:	22010113          	addi	sp,sp,544
    80005066:	8082                	ret
    end_op();
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	49e080e7          	jalr	1182(ra) # 80004506 <end_op>
    return -1;
    80005070:	557d                	li	a0,-1
    80005072:	b7f9                	j	80005040 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005074:	8526                	mv	a0,s1
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	9cc080e7          	jalr	-1588(ra) # 80001a42 <proc_pagetable>
    8000507e:	8b2a                	mv	s6,a0
    80005080:	d555                	beqz	a0,8000502c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005082:	e6842783          	lw	a5,-408(s0)
    80005086:	e8045703          	lhu	a4,-384(s0)
    8000508a:	c735                	beqz	a4,800050f6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000508c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000508e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005092:	6a05                	lui	s4,0x1
    80005094:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005098:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    8000509c:	6d85                	lui	s11,0x1
    8000509e:	7d7d                	lui	s10,0xfffff
    800050a0:	ac1d                	j	800052d6 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050a2:	00003517          	auipc	a0,0x3
    800050a6:	73e50513          	addi	a0,a0,1854 # 800087e0 <syscalls+0x290>
    800050aa:	ffffb097          	auipc	ra,0xffffb
    800050ae:	480080e7          	jalr	1152(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050b2:	874a                	mv	a4,s2
    800050b4:	009c86bb          	addw	a3,s9,s1
    800050b8:	4581                	li	a1,0
    800050ba:	8556                	mv	a0,s5
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	ca8080e7          	jalr	-856(ra) # 80003d64 <readi>
    800050c4:	2501                	sext.w	a0,a0
    800050c6:	1aa91863          	bne	s2,a0,80005276 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800050ca:	009d84bb          	addw	s1,s11,s1
    800050ce:	013d09bb          	addw	s3,s10,s3
    800050d2:	1f74f263          	bgeu	s1,s7,800052b6 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800050d6:	02049593          	slli	a1,s1,0x20
    800050da:	9181                	srli	a1,a1,0x20
    800050dc:	95e2                	add	a1,a1,s8
    800050de:	855a                	mv	a0,s6
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	f6c080e7          	jalr	-148(ra) # 8000104c <walkaddr>
    800050e8:	862a                	mv	a2,a0
    if(pa == 0)
    800050ea:	dd45                	beqz	a0,800050a2 <exec+0xfe>
      n = PGSIZE;
    800050ec:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800050ee:	fd49f2e3          	bgeu	s3,s4,800050b2 <exec+0x10e>
      n = sz - i;
    800050f2:	894e                	mv	s2,s3
    800050f4:	bf7d                	j	800050b2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800050f6:	4481                	li	s1,0
  iunlockput(ip);
    800050f8:	8556                	mv	a0,s5
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	c18080e7          	jalr	-1000(ra) # 80003d12 <iunlockput>
  end_op();
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	404080e7          	jalr	1028(ra) # 80004506 <end_op>
  p = myproc();
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	874080e7          	jalr	-1932(ra) # 8000197e <myproc>
    80005112:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005114:	08053d03          	ld	s10,128(a0)
  sz = PGROUNDUP(sz);
    80005118:	6785                	lui	a5,0x1
    8000511a:	17fd                	addi	a5,a5,-1
    8000511c:	94be                	add	s1,s1,a5
    8000511e:	77fd                	lui	a5,0xfffff
    80005120:	8fe5                	and	a5,a5,s1
    80005122:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005126:	6609                	lui	a2,0x2
    80005128:	963e                	add	a2,a2,a5
    8000512a:	85be                	mv	a1,a5
    8000512c:	855a                	mv	a0,s6
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	2c0080e7          	jalr	704(ra) # 800013ee <uvmalloc>
    80005136:	8c2a                	mv	s8,a0
  ip = 0;
    80005138:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000513a:	12050e63          	beqz	a0,80005276 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000513e:	75f9                	lui	a1,0xffffe
    80005140:	95aa                	add	a1,a1,a0
    80005142:	855a                	mv	a0,s6
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	4c8080e7          	jalr	1224(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    8000514c:	7afd                	lui	s5,0xfffff
    8000514e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005150:	df043783          	ld	a5,-528(s0)
    80005154:	6388                	ld	a0,0(a5)
    80005156:	c925                	beqz	a0,800051c6 <exec+0x222>
    80005158:	e8840993          	addi	s3,s0,-376
    8000515c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005160:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005162:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	cde080e7          	jalr	-802(ra) # 80000e42 <strlen>
    8000516c:	0015079b          	addiw	a5,a0,1
    80005170:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005174:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005178:	13596363          	bltu	s2,s5,8000529e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000517c:	df043d83          	ld	s11,-528(s0)
    80005180:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005184:	8552                	mv	a0,s4
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	cbc080e7          	jalr	-836(ra) # 80000e42 <strlen>
    8000518e:	0015069b          	addiw	a3,a0,1
    80005192:	8652                	mv	a2,s4
    80005194:	85ca                	mv	a1,s2
    80005196:	855a                	mv	a0,s6
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	4a6080e7          	jalr	1190(ra) # 8000163e <copyout>
    800051a0:	10054363          	bltz	a0,800052a6 <exec+0x302>
    ustack[argc] = sp;
    800051a4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051a8:	0485                	addi	s1,s1,1
    800051aa:	008d8793          	addi	a5,s11,8
    800051ae:	def43823          	sd	a5,-528(s0)
    800051b2:	008db503          	ld	a0,8(s11)
    800051b6:	c911                	beqz	a0,800051ca <exec+0x226>
    if(argc >= MAXARG)
    800051b8:	09a1                	addi	s3,s3,8
    800051ba:	fb3c95e3          	bne	s9,s3,80005164 <exec+0x1c0>
  sz = sz1;
    800051be:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051c2:	4a81                	li	s5,0
    800051c4:	a84d                	j	80005276 <exec+0x2d2>
  sp = sz;
    800051c6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051c8:	4481                	li	s1,0
  ustack[argc] = 0;
    800051ca:	00349793          	slli	a5,s1,0x3
    800051ce:	f9040713          	addi	a4,s0,-112
    800051d2:	97ba                	add	a5,a5,a4
    800051d4:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800051d8:	00148693          	addi	a3,s1,1
    800051dc:	068e                	slli	a3,a3,0x3
    800051de:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051e2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051e6:	01597663          	bgeu	s2,s5,800051f2 <exec+0x24e>
  sz = sz1;
    800051ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ee:	4a81                	li	s5,0
    800051f0:	a059                	j	80005276 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051f2:	e8840613          	addi	a2,s0,-376
    800051f6:	85ca                	mv	a1,s2
    800051f8:	855a                	mv	a0,s6
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	444080e7          	jalr	1092(ra) # 8000163e <copyout>
    80005202:	0a054663          	bltz	a0,800052ae <exec+0x30a>
  p->trapframe->a1 = sp;
    80005206:	090bb783          	ld	a5,144(s7) # 1090 <_entry-0x7fffef70>
    8000520a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000520e:	de843783          	ld	a5,-536(s0)
    80005212:	0007c703          	lbu	a4,0(a5)
    80005216:	cf11                	beqz	a4,80005232 <exec+0x28e>
    80005218:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000521a:	02f00693          	li	a3,47
    8000521e:	a039                	j	8000522c <exec+0x288>
      last = s+1;
    80005220:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005224:	0785                	addi	a5,a5,1
    80005226:	fff7c703          	lbu	a4,-1(a5)
    8000522a:	c701                	beqz	a4,80005232 <exec+0x28e>
    if(*s == '/')
    8000522c:	fed71ce3          	bne	a4,a3,80005224 <exec+0x280>
    80005230:	bfc5                	j	80005220 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005232:	4641                	li	a2,16
    80005234:	de843583          	ld	a1,-536(s0)
    80005238:	190b8513          	addi	a0,s7,400
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	bd4080e7          	jalr	-1068(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005244:	088bb503          	ld	a0,136(s7)
  p->pagetable = pagetable;
    80005248:	096bb423          	sd	s6,136(s7)
  p->sz = sz;
    8000524c:	098bb023          	sd	s8,128(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005250:	090bb783          	ld	a5,144(s7)
    80005254:	e6043703          	ld	a4,-416(s0)
    80005258:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000525a:	090bb783          	ld	a5,144(s7)
    8000525e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005262:	85ea                	mv	a1,s10
    80005264:	ffffd097          	auipc	ra,0xffffd
    80005268:	87a080e7          	jalr	-1926(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000526c:	0004851b          	sext.w	a0,s1
    80005270:	bbc1                	j	80005040 <exec+0x9c>
    80005272:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005276:	df843583          	ld	a1,-520(s0)
    8000527a:	855a                	mv	a0,s6
    8000527c:	ffffd097          	auipc	ra,0xffffd
    80005280:	862080e7          	jalr	-1950(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80005284:	da0a94e3          	bnez	s5,8000502c <exec+0x88>
  return -1;
    80005288:	557d                	li	a0,-1
    8000528a:	bb5d                	j	80005040 <exec+0x9c>
    8000528c:	de943c23          	sd	s1,-520(s0)
    80005290:	b7dd                	j	80005276 <exec+0x2d2>
    80005292:	de943c23          	sd	s1,-520(s0)
    80005296:	b7c5                	j	80005276 <exec+0x2d2>
    80005298:	de943c23          	sd	s1,-520(s0)
    8000529c:	bfe9                	j	80005276 <exec+0x2d2>
  sz = sz1;
    8000529e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052a2:	4a81                	li	s5,0
    800052a4:	bfc9                	j	80005276 <exec+0x2d2>
  sz = sz1;
    800052a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052aa:	4a81                	li	s5,0
    800052ac:	b7e9                	j	80005276 <exec+0x2d2>
  sz = sz1;
    800052ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052b2:	4a81                	li	s5,0
    800052b4:	b7c9                	j	80005276 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052b6:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ba:	e0843783          	ld	a5,-504(s0)
    800052be:	0017869b          	addiw	a3,a5,1
    800052c2:	e0d43423          	sd	a3,-504(s0)
    800052c6:	e0043783          	ld	a5,-512(s0)
    800052ca:	0387879b          	addiw	a5,a5,56
    800052ce:	e8045703          	lhu	a4,-384(s0)
    800052d2:	e2e6d3e3          	bge	a3,a4,800050f8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052d6:	2781                	sext.w	a5,a5
    800052d8:	e0f43023          	sd	a5,-512(s0)
    800052dc:	03800713          	li	a4,56
    800052e0:	86be                	mv	a3,a5
    800052e2:	e1040613          	addi	a2,s0,-496
    800052e6:	4581                	li	a1,0
    800052e8:	8556                	mv	a0,s5
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	a7a080e7          	jalr	-1414(ra) # 80003d64 <readi>
    800052f2:	03800793          	li	a5,56
    800052f6:	f6f51ee3          	bne	a0,a5,80005272 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800052fa:	e1042783          	lw	a5,-496(s0)
    800052fe:	4705                	li	a4,1
    80005300:	fae79de3          	bne	a5,a4,800052ba <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005304:	e3843603          	ld	a2,-456(s0)
    80005308:	e3043783          	ld	a5,-464(s0)
    8000530c:	f8f660e3          	bltu	a2,a5,8000528c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005310:	e2043783          	ld	a5,-480(s0)
    80005314:	963e                	add	a2,a2,a5
    80005316:	f6f66ee3          	bltu	a2,a5,80005292 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000531a:	85a6                	mv	a1,s1
    8000531c:	855a                	mv	a0,s6
    8000531e:	ffffc097          	auipc	ra,0xffffc
    80005322:	0d0080e7          	jalr	208(ra) # 800013ee <uvmalloc>
    80005326:	dea43c23          	sd	a0,-520(s0)
    8000532a:	d53d                	beqz	a0,80005298 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000532c:	e2043c03          	ld	s8,-480(s0)
    80005330:	de043783          	ld	a5,-544(s0)
    80005334:	00fc77b3          	and	a5,s8,a5
    80005338:	ff9d                	bnez	a5,80005276 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000533a:	e1842c83          	lw	s9,-488(s0)
    8000533e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005342:	f60b8ae3          	beqz	s7,800052b6 <exec+0x312>
    80005346:	89de                	mv	s3,s7
    80005348:	4481                	li	s1,0
    8000534a:	b371                	j	800050d6 <exec+0x132>

000000008000534c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000534c:	7179                	addi	sp,sp,-48
    8000534e:	f406                	sd	ra,40(sp)
    80005350:	f022                	sd	s0,32(sp)
    80005352:	ec26                	sd	s1,24(sp)
    80005354:	e84a                	sd	s2,16(sp)
    80005356:	1800                	addi	s0,sp,48
    80005358:	892e                	mv	s2,a1
    8000535a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000535c:	fdc40593          	addi	a1,s0,-36
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	a5c080e7          	jalr	-1444(ra) # 80002dbc <argint>
    80005368:	04054063          	bltz	a0,800053a8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000536c:	fdc42703          	lw	a4,-36(s0)
    80005370:	47bd                	li	a5,15
    80005372:	02e7ed63          	bltu	a5,a4,800053ac <argfd+0x60>
    80005376:	ffffc097          	auipc	ra,0xffffc
    8000537a:	608080e7          	jalr	1544(ra) # 8000197e <myproc>
    8000537e:	fdc42703          	lw	a4,-36(s0)
    80005382:	02070793          	addi	a5,a4,32
    80005386:	078e                	slli	a5,a5,0x3
    80005388:	953e                	add	a0,a0,a5
    8000538a:	651c                	ld	a5,8(a0)
    8000538c:	c395                	beqz	a5,800053b0 <argfd+0x64>
    return -1;
  if(pfd)
    8000538e:	00090463          	beqz	s2,80005396 <argfd+0x4a>
    *pfd = fd;
    80005392:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005396:	4501                	li	a0,0
  if(pf)
    80005398:	c091                	beqz	s1,8000539c <argfd+0x50>
    *pf = f;
    8000539a:	e09c                	sd	a5,0(s1)
}
    8000539c:	70a2                	ld	ra,40(sp)
    8000539e:	7402                	ld	s0,32(sp)
    800053a0:	64e2                	ld	s1,24(sp)
    800053a2:	6942                	ld	s2,16(sp)
    800053a4:	6145                	addi	sp,sp,48
    800053a6:	8082                	ret
    return -1;
    800053a8:	557d                	li	a0,-1
    800053aa:	bfcd                	j	8000539c <argfd+0x50>
    return -1;
    800053ac:	557d                	li	a0,-1
    800053ae:	b7fd                	j	8000539c <argfd+0x50>
    800053b0:	557d                	li	a0,-1
    800053b2:	b7ed                	j	8000539c <argfd+0x50>

00000000800053b4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053b4:	1101                	addi	sp,sp,-32
    800053b6:	ec06                	sd	ra,24(sp)
    800053b8:	e822                	sd	s0,16(sp)
    800053ba:	e426                	sd	s1,8(sp)
    800053bc:	1000                	addi	s0,sp,32
    800053be:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	5be080e7          	jalr	1470(ra) # 8000197e <myproc>
    800053c8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053ca:	10850793          	addi	a5,a0,264
    800053ce:	4501                	li	a0,0
    800053d0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053d2:	6398                	ld	a4,0(a5)
    800053d4:	cb19                	beqz	a4,800053ea <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053d6:	2505                	addiw	a0,a0,1
    800053d8:	07a1                	addi	a5,a5,8
    800053da:	fed51ce3          	bne	a0,a3,800053d2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053de:	557d                	li	a0,-1
}
    800053e0:	60e2                	ld	ra,24(sp)
    800053e2:	6442                	ld	s0,16(sp)
    800053e4:	64a2                	ld	s1,8(sp)
    800053e6:	6105                	addi	sp,sp,32
    800053e8:	8082                	ret
      p->ofile[fd] = f;
    800053ea:	02050793          	addi	a5,a0,32
    800053ee:	078e                	slli	a5,a5,0x3
    800053f0:	963e                	add	a2,a2,a5
    800053f2:	e604                	sd	s1,8(a2)
      return fd;
    800053f4:	b7f5                	j	800053e0 <fdalloc+0x2c>

00000000800053f6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053f6:	715d                	addi	sp,sp,-80
    800053f8:	e486                	sd	ra,72(sp)
    800053fa:	e0a2                	sd	s0,64(sp)
    800053fc:	fc26                	sd	s1,56(sp)
    800053fe:	f84a                	sd	s2,48(sp)
    80005400:	f44e                	sd	s3,40(sp)
    80005402:	f052                	sd	s4,32(sp)
    80005404:	ec56                	sd	s5,24(sp)
    80005406:	0880                	addi	s0,sp,80
    80005408:	89ae                	mv	s3,a1
    8000540a:	8ab2                	mv	s5,a2
    8000540c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000540e:	fb040593          	addi	a1,s0,-80
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	e72080e7          	jalr	-398(ra) # 80004284 <nameiparent>
    8000541a:	892a                	mv	s2,a0
    8000541c:	12050e63          	beqz	a0,80005558 <create+0x162>
    return 0;

  ilock(dp);
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	690080e7          	jalr	1680(ra) # 80003ab0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005428:	4601                	li	a2,0
    8000542a:	fb040593          	addi	a1,s0,-80
    8000542e:	854a                	mv	a0,s2
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	b64080e7          	jalr	-1180(ra) # 80003f94 <dirlookup>
    80005438:	84aa                	mv	s1,a0
    8000543a:	c921                	beqz	a0,8000548a <create+0x94>
    iunlockput(dp);
    8000543c:	854a                	mv	a0,s2
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	8d4080e7          	jalr	-1836(ra) # 80003d12 <iunlockput>
    ilock(ip);
    80005446:	8526                	mv	a0,s1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	668080e7          	jalr	1640(ra) # 80003ab0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005450:	2981                	sext.w	s3,s3
    80005452:	4789                	li	a5,2
    80005454:	02f99463          	bne	s3,a5,8000547c <create+0x86>
    80005458:	0444d783          	lhu	a5,68(s1)
    8000545c:	37f9                	addiw	a5,a5,-2
    8000545e:	17c2                	slli	a5,a5,0x30
    80005460:	93c1                	srli	a5,a5,0x30
    80005462:	4705                	li	a4,1
    80005464:	00f76c63          	bltu	a4,a5,8000547c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005468:	8526                	mv	a0,s1
    8000546a:	60a6                	ld	ra,72(sp)
    8000546c:	6406                	ld	s0,64(sp)
    8000546e:	74e2                	ld	s1,56(sp)
    80005470:	7942                	ld	s2,48(sp)
    80005472:	79a2                	ld	s3,40(sp)
    80005474:	7a02                	ld	s4,32(sp)
    80005476:	6ae2                	ld	s5,24(sp)
    80005478:	6161                	addi	sp,sp,80
    8000547a:	8082                	ret
    iunlockput(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	894080e7          	jalr	-1900(ra) # 80003d12 <iunlockput>
    return 0;
    80005486:	4481                	li	s1,0
    80005488:	b7c5                	j	80005468 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000548a:	85ce                	mv	a1,s3
    8000548c:	00092503          	lw	a0,0(s2)
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	488080e7          	jalr	1160(ra) # 80003918 <ialloc>
    80005498:	84aa                	mv	s1,a0
    8000549a:	c521                	beqz	a0,800054e2 <create+0xec>
  ilock(ip);
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	614080e7          	jalr	1556(ra) # 80003ab0 <ilock>
  ip->major = major;
    800054a4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054a8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054ac:	4a05                	li	s4,1
    800054ae:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	532080e7          	jalr	1330(ra) # 800039e6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054bc:	2981                	sext.w	s3,s3
    800054be:	03498a63          	beq	s3,s4,800054f2 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800054c2:	40d0                	lw	a2,4(s1)
    800054c4:	fb040593          	addi	a1,s0,-80
    800054c8:	854a                	mv	a0,s2
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	cda080e7          	jalr	-806(ra) # 800041a4 <dirlink>
    800054d2:	06054b63          	bltz	a0,80005548 <create+0x152>
  iunlockput(dp);
    800054d6:	854a                	mv	a0,s2
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	83a080e7          	jalr	-1990(ra) # 80003d12 <iunlockput>
  return ip;
    800054e0:	b761                	j	80005468 <create+0x72>
    panic("create: ialloc");
    800054e2:	00003517          	auipc	a0,0x3
    800054e6:	31e50513          	addi	a0,a0,798 # 80008800 <syscalls+0x2b0>
    800054ea:	ffffb097          	auipc	ra,0xffffb
    800054ee:	040080e7          	jalr	64(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800054f2:	04a95783          	lhu	a5,74(s2)
    800054f6:	2785                	addiw	a5,a5,1
    800054f8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800054fc:	854a                	mv	a0,s2
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	4e8080e7          	jalr	1256(ra) # 800039e6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005506:	40d0                	lw	a2,4(s1)
    80005508:	00003597          	auipc	a1,0x3
    8000550c:	30858593          	addi	a1,a1,776 # 80008810 <syscalls+0x2c0>
    80005510:	8526                	mv	a0,s1
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	c92080e7          	jalr	-878(ra) # 800041a4 <dirlink>
    8000551a:	00054f63          	bltz	a0,80005538 <create+0x142>
    8000551e:	00492603          	lw	a2,4(s2)
    80005522:	00003597          	auipc	a1,0x3
    80005526:	2f658593          	addi	a1,a1,758 # 80008818 <syscalls+0x2c8>
    8000552a:	8526                	mv	a0,s1
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	c78080e7          	jalr	-904(ra) # 800041a4 <dirlink>
    80005534:	f80557e3          	bgez	a0,800054c2 <create+0xcc>
      panic("create dots");
    80005538:	00003517          	auipc	a0,0x3
    8000553c:	2e850513          	addi	a0,a0,744 # 80008820 <syscalls+0x2d0>
    80005540:	ffffb097          	auipc	ra,0xffffb
    80005544:	fea080e7          	jalr	-22(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005548:	00003517          	auipc	a0,0x3
    8000554c:	2e850513          	addi	a0,a0,744 # 80008830 <syscalls+0x2e0>
    80005550:	ffffb097          	auipc	ra,0xffffb
    80005554:	fda080e7          	jalr	-38(ra) # 8000052a <panic>
    return 0;
    80005558:	84aa                	mv	s1,a0
    8000555a:	b739                	j	80005468 <create+0x72>

000000008000555c <sys_dup>:
{
    8000555c:	7179                	addi	sp,sp,-48
    8000555e:	f406                	sd	ra,40(sp)
    80005560:	f022                	sd	s0,32(sp)
    80005562:	ec26                	sd	s1,24(sp)
    80005564:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005566:	fd840613          	addi	a2,s0,-40
    8000556a:	4581                	li	a1,0
    8000556c:	4501                	li	a0,0
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	dde080e7          	jalr	-546(ra) # 8000534c <argfd>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005578:	02054363          	bltz	a0,8000559e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000557c:	fd843503          	ld	a0,-40(s0)
    80005580:	00000097          	auipc	ra,0x0
    80005584:	e34080e7          	jalr	-460(ra) # 800053b4 <fdalloc>
    80005588:	84aa                	mv	s1,a0
    return -1;
    8000558a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000558c:	00054963          	bltz	a0,8000559e <sys_dup+0x42>
  filedup(f);
    80005590:	fd843503          	ld	a0,-40(s0)
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	36c080e7          	jalr	876(ra) # 80004900 <filedup>
  return fd;
    8000559c:	87a6                	mv	a5,s1
}
    8000559e:	853e                	mv	a0,a5
    800055a0:	70a2                	ld	ra,40(sp)
    800055a2:	7402                	ld	s0,32(sp)
    800055a4:	64e2                	ld	s1,24(sp)
    800055a6:	6145                	addi	sp,sp,48
    800055a8:	8082                	ret

00000000800055aa <sys_read>:
{
    800055aa:	7179                	addi	sp,sp,-48
    800055ac:	f406                	sd	ra,40(sp)
    800055ae:	f022                	sd	s0,32(sp)
    800055b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b2:	fe840613          	addi	a2,s0,-24
    800055b6:	4581                	li	a1,0
    800055b8:	4501                	li	a0,0
    800055ba:	00000097          	auipc	ra,0x0
    800055be:	d92080e7          	jalr	-622(ra) # 8000534c <argfd>
    return -1;
    800055c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c4:	04054163          	bltz	a0,80005606 <sys_read+0x5c>
    800055c8:	fe440593          	addi	a1,s0,-28
    800055cc:	4509                	li	a0,2
    800055ce:	ffffd097          	auipc	ra,0xffffd
    800055d2:	7ee080e7          	jalr	2030(ra) # 80002dbc <argint>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d8:	02054763          	bltz	a0,80005606 <sys_read+0x5c>
    800055dc:	fd840593          	addi	a1,s0,-40
    800055e0:	4505                	li	a0,1
    800055e2:	ffffd097          	auipc	ra,0xffffd
    800055e6:	7fc080e7          	jalr	2044(ra) # 80002dde <argaddr>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ec:	00054d63          	bltz	a0,80005606 <sys_read+0x5c>
  return fileread(f, p, n);
    800055f0:	fe442603          	lw	a2,-28(s0)
    800055f4:	fd843583          	ld	a1,-40(s0)
    800055f8:	fe843503          	ld	a0,-24(s0)
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	490080e7          	jalr	1168(ra) # 80004a8c <fileread>
    80005604:	87aa                	mv	a5,a0
}
    80005606:	853e                	mv	a0,a5
    80005608:	70a2                	ld	ra,40(sp)
    8000560a:	7402                	ld	s0,32(sp)
    8000560c:	6145                	addi	sp,sp,48
    8000560e:	8082                	ret

0000000080005610 <sys_write>:
{
    80005610:	7179                	addi	sp,sp,-48
    80005612:	f406                	sd	ra,40(sp)
    80005614:	f022                	sd	s0,32(sp)
    80005616:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005618:	fe840613          	addi	a2,s0,-24
    8000561c:	4581                	li	a1,0
    8000561e:	4501                	li	a0,0
    80005620:	00000097          	auipc	ra,0x0
    80005624:	d2c080e7          	jalr	-724(ra) # 8000534c <argfd>
    return -1;
    80005628:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000562a:	04054163          	bltz	a0,8000566c <sys_write+0x5c>
    8000562e:	fe440593          	addi	a1,s0,-28
    80005632:	4509                	li	a0,2
    80005634:	ffffd097          	auipc	ra,0xffffd
    80005638:	788080e7          	jalr	1928(ra) # 80002dbc <argint>
    return -1;
    8000563c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563e:	02054763          	bltz	a0,8000566c <sys_write+0x5c>
    80005642:	fd840593          	addi	a1,s0,-40
    80005646:	4505                	li	a0,1
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	796080e7          	jalr	1942(ra) # 80002dde <argaddr>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005652:	00054d63          	bltz	a0,8000566c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005656:	fe442603          	lw	a2,-28(s0)
    8000565a:	fd843583          	ld	a1,-40(s0)
    8000565e:	fe843503          	ld	a0,-24(s0)
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	4ec080e7          	jalr	1260(ra) # 80004b4e <filewrite>
    8000566a:	87aa                	mv	a5,a0
}
    8000566c:	853e                	mv	a0,a5
    8000566e:	70a2                	ld	ra,40(sp)
    80005670:	7402                	ld	s0,32(sp)
    80005672:	6145                	addi	sp,sp,48
    80005674:	8082                	ret

0000000080005676 <sys_close>:
{
    80005676:	1101                	addi	sp,sp,-32
    80005678:	ec06                	sd	ra,24(sp)
    8000567a:	e822                	sd	s0,16(sp)
    8000567c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000567e:	fe040613          	addi	a2,s0,-32
    80005682:	fec40593          	addi	a1,s0,-20
    80005686:	4501                	li	a0,0
    80005688:	00000097          	auipc	ra,0x0
    8000568c:	cc4080e7          	jalr	-828(ra) # 8000534c <argfd>
    return -1;
    80005690:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005692:	02054563          	bltz	a0,800056bc <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005696:	ffffc097          	auipc	ra,0xffffc
    8000569a:	2e8080e7          	jalr	744(ra) # 8000197e <myproc>
    8000569e:	fec42783          	lw	a5,-20(s0)
    800056a2:	02078793          	addi	a5,a5,32
    800056a6:	078e                	slli	a5,a5,0x3
    800056a8:	97aa                	add	a5,a5,a0
    800056aa:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800056ae:	fe043503          	ld	a0,-32(s0)
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	2a0080e7          	jalr	672(ra) # 80004952 <fileclose>
  return 0;
    800056ba:	4781                	li	a5,0
}
    800056bc:	853e                	mv	a0,a5
    800056be:	60e2                	ld	ra,24(sp)
    800056c0:	6442                	ld	s0,16(sp)
    800056c2:	6105                	addi	sp,sp,32
    800056c4:	8082                	ret

00000000800056c6 <sys_fstat>:
{
    800056c6:	1101                	addi	sp,sp,-32
    800056c8:	ec06                	sd	ra,24(sp)
    800056ca:	e822                	sd	s0,16(sp)
    800056cc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056ce:	fe840613          	addi	a2,s0,-24
    800056d2:	4581                	li	a1,0
    800056d4:	4501                	li	a0,0
    800056d6:	00000097          	auipc	ra,0x0
    800056da:	c76080e7          	jalr	-906(ra) # 8000534c <argfd>
    return -1;
    800056de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056e0:	02054563          	bltz	a0,8000570a <sys_fstat+0x44>
    800056e4:	fe040593          	addi	a1,s0,-32
    800056e8:	4505                	li	a0,1
    800056ea:	ffffd097          	auipc	ra,0xffffd
    800056ee:	6f4080e7          	jalr	1780(ra) # 80002dde <argaddr>
    return -1;
    800056f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056f4:	00054b63          	bltz	a0,8000570a <sys_fstat+0x44>
  return filestat(f, st);
    800056f8:	fe043583          	ld	a1,-32(s0)
    800056fc:	fe843503          	ld	a0,-24(s0)
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	31a080e7          	jalr	794(ra) # 80004a1a <filestat>
    80005708:	87aa                	mv	a5,a0
}
    8000570a:	853e                	mv	a0,a5
    8000570c:	60e2                	ld	ra,24(sp)
    8000570e:	6442                	ld	s0,16(sp)
    80005710:	6105                	addi	sp,sp,32
    80005712:	8082                	ret

0000000080005714 <sys_link>:
{
    80005714:	7169                	addi	sp,sp,-304
    80005716:	f606                	sd	ra,296(sp)
    80005718:	f222                	sd	s0,288(sp)
    8000571a:	ee26                	sd	s1,280(sp)
    8000571c:	ea4a                	sd	s2,272(sp)
    8000571e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005720:	08000613          	li	a2,128
    80005724:	ed040593          	addi	a1,s0,-304
    80005728:	4501                	li	a0,0
    8000572a:	ffffd097          	auipc	ra,0xffffd
    8000572e:	6d6080e7          	jalr	1750(ra) # 80002e00 <argstr>
    return -1;
    80005732:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005734:	10054e63          	bltz	a0,80005850 <sys_link+0x13c>
    80005738:	08000613          	li	a2,128
    8000573c:	f5040593          	addi	a1,s0,-176
    80005740:	4505                	li	a0,1
    80005742:	ffffd097          	auipc	ra,0xffffd
    80005746:	6be080e7          	jalr	1726(ra) # 80002e00 <argstr>
    return -1;
    8000574a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000574c:	10054263          	bltz	a0,80005850 <sys_link+0x13c>
  begin_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	d36080e7          	jalr	-714(ra) # 80004486 <begin_op>
  if((ip = namei(old)) == 0){
    80005758:	ed040513          	addi	a0,s0,-304
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	b0a080e7          	jalr	-1270(ra) # 80004266 <namei>
    80005764:	84aa                	mv	s1,a0
    80005766:	c551                	beqz	a0,800057f2 <sys_link+0xde>
  ilock(ip);
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	348080e7          	jalr	840(ra) # 80003ab0 <ilock>
  if(ip->type == T_DIR){
    80005770:	04449703          	lh	a4,68(s1)
    80005774:	4785                	li	a5,1
    80005776:	08f70463          	beq	a4,a5,800057fe <sys_link+0xea>
  ip->nlink++;
    8000577a:	04a4d783          	lhu	a5,74(s1)
    8000577e:	2785                	addiw	a5,a5,1
    80005780:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	260080e7          	jalr	608(ra) # 800039e6 <iupdate>
  iunlock(ip);
    8000578e:	8526                	mv	a0,s1
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	3e2080e7          	jalr	994(ra) # 80003b72 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005798:	fd040593          	addi	a1,s0,-48
    8000579c:	f5040513          	addi	a0,s0,-176
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	ae4080e7          	jalr	-1308(ra) # 80004284 <nameiparent>
    800057a8:	892a                	mv	s2,a0
    800057aa:	c935                	beqz	a0,8000581e <sys_link+0x10a>
  ilock(dp);
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	304080e7          	jalr	772(ra) # 80003ab0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057b4:	00092703          	lw	a4,0(s2)
    800057b8:	409c                	lw	a5,0(s1)
    800057ba:	04f71d63          	bne	a4,a5,80005814 <sys_link+0x100>
    800057be:	40d0                	lw	a2,4(s1)
    800057c0:	fd040593          	addi	a1,s0,-48
    800057c4:	854a                	mv	a0,s2
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	9de080e7          	jalr	-1570(ra) # 800041a4 <dirlink>
    800057ce:	04054363          	bltz	a0,80005814 <sys_link+0x100>
  iunlockput(dp);
    800057d2:	854a                	mv	a0,s2
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	53e080e7          	jalr	1342(ra) # 80003d12 <iunlockput>
  iput(ip);
    800057dc:	8526                	mv	a0,s1
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	48c080e7          	jalr	1164(ra) # 80003c6a <iput>
  end_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	d20080e7          	jalr	-736(ra) # 80004506 <end_op>
  return 0;
    800057ee:	4781                	li	a5,0
    800057f0:	a085                	j	80005850 <sys_link+0x13c>
    end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	d14080e7          	jalr	-748(ra) # 80004506 <end_op>
    return -1;
    800057fa:	57fd                	li	a5,-1
    800057fc:	a891                	j	80005850 <sys_link+0x13c>
    iunlockput(ip);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	512080e7          	jalr	1298(ra) # 80003d12 <iunlockput>
    end_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	cfe080e7          	jalr	-770(ra) # 80004506 <end_op>
    return -1;
    80005810:	57fd                	li	a5,-1
    80005812:	a83d                	j	80005850 <sys_link+0x13c>
    iunlockput(dp);
    80005814:	854a                	mv	a0,s2
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	4fc080e7          	jalr	1276(ra) # 80003d12 <iunlockput>
  ilock(ip);
    8000581e:	8526                	mv	a0,s1
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	290080e7          	jalr	656(ra) # 80003ab0 <ilock>
  ip->nlink--;
    80005828:	04a4d783          	lhu	a5,74(s1)
    8000582c:	37fd                	addiw	a5,a5,-1
    8000582e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	1b2080e7          	jalr	434(ra) # 800039e6 <iupdate>
  iunlockput(ip);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	4d4080e7          	jalr	1236(ra) # 80003d12 <iunlockput>
  end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	cc0080e7          	jalr	-832(ra) # 80004506 <end_op>
  return -1;
    8000584e:	57fd                	li	a5,-1
}
    80005850:	853e                	mv	a0,a5
    80005852:	70b2                	ld	ra,296(sp)
    80005854:	7412                	ld	s0,288(sp)
    80005856:	64f2                	ld	s1,280(sp)
    80005858:	6952                	ld	s2,272(sp)
    8000585a:	6155                	addi	sp,sp,304
    8000585c:	8082                	ret

000000008000585e <sys_unlink>:
{
    8000585e:	7151                	addi	sp,sp,-240
    80005860:	f586                	sd	ra,232(sp)
    80005862:	f1a2                	sd	s0,224(sp)
    80005864:	eda6                	sd	s1,216(sp)
    80005866:	e9ca                	sd	s2,208(sp)
    80005868:	e5ce                	sd	s3,200(sp)
    8000586a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000586c:	08000613          	li	a2,128
    80005870:	f3040593          	addi	a1,s0,-208
    80005874:	4501                	li	a0,0
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	58a080e7          	jalr	1418(ra) # 80002e00 <argstr>
    8000587e:	18054163          	bltz	a0,80005a00 <sys_unlink+0x1a2>
  begin_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	c04080e7          	jalr	-1020(ra) # 80004486 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000588a:	fb040593          	addi	a1,s0,-80
    8000588e:	f3040513          	addi	a0,s0,-208
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	9f2080e7          	jalr	-1550(ra) # 80004284 <nameiparent>
    8000589a:	84aa                	mv	s1,a0
    8000589c:	c979                	beqz	a0,80005972 <sys_unlink+0x114>
  ilock(dp);
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	212080e7          	jalr	530(ra) # 80003ab0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058a6:	00003597          	auipc	a1,0x3
    800058aa:	f6a58593          	addi	a1,a1,-150 # 80008810 <syscalls+0x2c0>
    800058ae:	fb040513          	addi	a0,s0,-80
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	6c8080e7          	jalr	1736(ra) # 80003f7a <namecmp>
    800058ba:	14050a63          	beqz	a0,80005a0e <sys_unlink+0x1b0>
    800058be:	00003597          	auipc	a1,0x3
    800058c2:	f5a58593          	addi	a1,a1,-166 # 80008818 <syscalls+0x2c8>
    800058c6:	fb040513          	addi	a0,s0,-80
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	6b0080e7          	jalr	1712(ra) # 80003f7a <namecmp>
    800058d2:	12050e63          	beqz	a0,80005a0e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058d6:	f2c40613          	addi	a2,s0,-212
    800058da:	fb040593          	addi	a1,s0,-80
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	6b4080e7          	jalr	1716(ra) # 80003f94 <dirlookup>
    800058e8:	892a                	mv	s2,a0
    800058ea:	12050263          	beqz	a0,80005a0e <sys_unlink+0x1b0>
  ilock(ip);
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	1c2080e7          	jalr	450(ra) # 80003ab0 <ilock>
  if(ip->nlink < 1)
    800058f6:	04a91783          	lh	a5,74(s2)
    800058fa:	08f05263          	blez	a5,8000597e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058fe:	04491703          	lh	a4,68(s2)
    80005902:	4785                	li	a5,1
    80005904:	08f70563          	beq	a4,a5,8000598e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005908:	4641                	li	a2,16
    8000590a:	4581                	li	a1,0
    8000590c:	fc040513          	addi	a0,s0,-64
    80005910:	ffffb097          	auipc	ra,0xffffb
    80005914:	3ae080e7          	jalr	942(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005918:	4741                	li	a4,16
    8000591a:	f2c42683          	lw	a3,-212(s0)
    8000591e:	fc040613          	addi	a2,s0,-64
    80005922:	4581                	li	a1,0
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	536080e7          	jalr	1334(ra) # 80003e5c <writei>
    8000592e:	47c1                	li	a5,16
    80005930:	0af51563          	bne	a0,a5,800059da <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005934:	04491703          	lh	a4,68(s2)
    80005938:	4785                	li	a5,1
    8000593a:	0af70863          	beq	a4,a5,800059ea <sys_unlink+0x18c>
  iunlockput(dp);
    8000593e:	8526                	mv	a0,s1
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	3d2080e7          	jalr	978(ra) # 80003d12 <iunlockput>
  ip->nlink--;
    80005948:	04a95783          	lhu	a5,74(s2)
    8000594c:	37fd                	addiw	a5,a5,-1
    8000594e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005952:	854a                	mv	a0,s2
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	092080e7          	jalr	146(ra) # 800039e6 <iupdate>
  iunlockput(ip);
    8000595c:	854a                	mv	a0,s2
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	3b4080e7          	jalr	948(ra) # 80003d12 <iunlockput>
  end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	ba0080e7          	jalr	-1120(ra) # 80004506 <end_op>
  return 0;
    8000596e:	4501                	li	a0,0
    80005970:	a84d                	j	80005a22 <sys_unlink+0x1c4>
    end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	b94080e7          	jalr	-1132(ra) # 80004506 <end_op>
    return -1;
    8000597a:	557d                	li	a0,-1
    8000597c:	a05d                	j	80005a22 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000597e:	00003517          	auipc	a0,0x3
    80005982:	ec250513          	addi	a0,a0,-318 # 80008840 <syscalls+0x2f0>
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	ba4080e7          	jalr	-1116(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000598e:	04c92703          	lw	a4,76(s2)
    80005992:	02000793          	li	a5,32
    80005996:	f6e7f9e3          	bgeu	a5,a4,80005908 <sys_unlink+0xaa>
    8000599a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000599e:	4741                	li	a4,16
    800059a0:	86ce                	mv	a3,s3
    800059a2:	f1840613          	addi	a2,s0,-232
    800059a6:	4581                	li	a1,0
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	3ba080e7          	jalr	954(ra) # 80003d64 <readi>
    800059b2:	47c1                	li	a5,16
    800059b4:	00f51b63          	bne	a0,a5,800059ca <sys_unlink+0x16c>
    if(de.inum != 0)
    800059b8:	f1845783          	lhu	a5,-232(s0)
    800059bc:	e7a1                	bnez	a5,80005a04 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059be:	29c1                	addiw	s3,s3,16
    800059c0:	04c92783          	lw	a5,76(s2)
    800059c4:	fcf9ede3          	bltu	s3,a5,8000599e <sys_unlink+0x140>
    800059c8:	b781                	j	80005908 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059ca:	00003517          	auipc	a0,0x3
    800059ce:	e8e50513          	addi	a0,a0,-370 # 80008858 <syscalls+0x308>
    800059d2:	ffffb097          	auipc	ra,0xffffb
    800059d6:	b58080e7          	jalr	-1192(ra) # 8000052a <panic>
    panic("unlink: writei");
    800059da:	00003517          	auipc	a0,0x3
    800059de:	e9650513          	addi	a0,a0,-362 # 80008870 <syscalls+0x320>
    800059e2:	ffffb097          	auipc	ra,0xffffb
    800059e6:	b48080e7          	jalr	-1208(ra) # 8000052a <panic>
    dp->nlink--;
    800059ea:	04a4d783          	lhu	a5,74(s1)
    800059ee:	37fd                	addiw	a5,a5,-1
    800059f0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	ff0080e7          	jalr	-16(ra) # 800039e6 <iupdate>
    800059fe:	b781                	j	8000593e <sys_unlink+0xe0>
    return -1;
    80005a00:	557d                	li	a0,-1
    80005a02:	a005                	j	80005a22 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a04:	854a                	mv	a0,s2
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	30c080e7          	jalr	780(ra) # 80003d12 <iunlockput>
  iunlockput(dp);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	302080e7          	jalr	770(ra) # 80003d12 <iunlockput>
  end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	aee080e7          	jalr	-1298(ra) # 80004506 <end_op>
  return -1;
    80005a20:	557d                	li	a0,-1
}
    80005a22:	70ae                	ld	ra,232(sp)
    80005a24:	740e                	ld	s0,224(sp)
    80005a26:	64ee                	ld	s1,216(sp)
    80005a28:	694e                	ld	s2,208(sp)
    80005a2a:	69ae                	ld	s3,200(sp)
    80005a2c:	616d                	addi	sp,sp,240
    80005a2e:	8082                	ret

0000000080005a30 <sys_open>:

uint64
sys_open(void)
{
    80005a30:	7131                	addi	sp,sp,-192
    80005a32:	fd06                	sd	ra,184(sp)
    80005a34:	f922                	sd	s0,176(sp)
    80005a36:	f526                	sd	s1,168(sp)
    80005a38:	f14a                	sd	s2,160(sp)
    80005a3a:	ed4e                	sd	s3,152(sp)
    80005a3c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a3e:	08000613          	li	a2,128
    80005a42:	f5040593          	addi	a1,s0,-176
    80005a46:	4501                	li	a0,0
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	3b8080e7          	jalr	952(ra) # 80002e00 <argstr>
    return -1;
    80005a50:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a52:	0c054163          	bltz	a0,80005b14 <sys_open+0xe4>
    80005a56:	f4c40593          	addi	a1,s0,-180
    80005a5a:	4505                	li	a0,1
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	360080e7          	jalr	864(ra) # 80002dbc <argint>
    80005a64:	0a054863          	bltz	a0,80005b14 <sys_open+0xe4>

  begin_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	a1e080e7          	jalr	-1506(ra) # 80004486 <begin_op>

  if(omode & O_CREATE){
    80005a70:	f4c42783          	lw	a5,-180(s0)
    80005a74:	2007f793          	andi	a5,a5,512
    80005a78:	cbdd                	beqz	a5,80005b2e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a7a:	4681                	li	a3,0
    80005a7c:	4601                	li	a2,0
    80005a7e:	4589                	li	a1,2
    80005a80:	f5040513          	addi	a0,s0,-176
    80005a84:	00000097          	auipc	ra,0x0
    80005a88:	972080e7          	jalr	-1678(ra) # 800053f6 <create>
    80005a8c:	892a                	mv	s2,a0
    if(ip == 0){
    80005a8e:	c959                	beqz	a0,80005b24 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a90:	04491703          	lh	a4,68(s2)
    80005a94:	478d                	li	a5,3
    80005a96:	00f71763          	bne	a4,a5,80005aa4 <sys_open+0x74>
    80005a9a:	04695703          	lhu	a4,70(s2)
    80005a9e:	47a5                	li	a5,9
    80005aa0:	0ce7ec63          	bltu	a5,a4,80005b78 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	df2080e7          	jalr	-526(ra) # 80004896 <filealloc>
    80005aac:	89aa                	mv	s3,a0
    80005aae:	10050263          	beqz	a0,80005bb2 <sys_open+0x182>
    80005ab2:	00000097          	auipc	ra,0x0
    80005ab6:	902080e7          	jalr	-1790(ra) # 800053b4 <fdalloc>
    80005aba:	84aa                	mv	s1,a0
    80005abc:	0e054663          	bltz	a0,80005ba8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ac0:	04491703          	lh	a4,68(s2)
    80005ac4:	478d                	li	a5,3
    80005ac6:	0cf70463          	beq	a4,a5,80005b8e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005aca:	4789                	li	a5,2
    80005acc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ad0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ad4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ad8:	f4c42783          	lw	a5,-180(s0)
    80005adc:	0017c713          	xori	a4,a5,1
    80005ae0:	8b05                	andi	a4,a4,1
    80005ae2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ae6:	0037f713          	andi	a4,a5,3
    80005aea:	00e03733          	snez	a4,a4
    80005aee:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005af2:	4007f793          	andi	a5,a5,1024
    80005af6:	c791                	beqz	a5,80005b02 <sys_open+0xd2>
    80005af8:	04491703          	lh	a4,68(s2)
    80005afc:	4789                	li	a5,2
    80005afe:	08f70f63          	beq	a4,a5,80005b9c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b02:	854a                	mv	a0,s2
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	06e080e7          	jalr	110(ra) # 80003b72 <iunlock>
  end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	9fa080e7          	jalr	-1542(ra) # 80004506 <end_op>

  return fd;
}
    80005b14:	8526                	mv	a0,s1
    80005b16:	70ea                	ld	ra,184(sp)
    80005b18:	744a                	ld	s0,176(sp)
    80005b1a:	74aa                	ld	s1,168(sp)
    80005b1c:	790a                	ld	s2,160(sp)
    80005b1e:	69ea                	ld	s3,152(sp)
    80005b20:	6129                	addi	sp,sp,192
    80005b22:	8082                	ret
      end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	9e2080e7          	jalr	-1566(ra) # 80004506 <end_op>
      return -1;
    80005b2c:	b7e5                	j	80005b14 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b2e:	f5040513          	addi	a0,s0,-176
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	734080e7          	jalr	1844(ra) # 80004266 <namei>
    80005b3a:	892a                	mv	s2,a0
    80005b3c:	c905                	beqz	a0,80005b6c <sys_open+0x13c>
    ilock(ip);
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	f72080e7          	jalr	-142(ra) # 80003ab0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b46:	04491703          	lh	a4,68(s2)
    80005b4a:	4785                	li	a5,1
    80005b4c:	f4f712e3          	bne	a4,a5,80005a90 <sys_open+0x60>
    80005b50:	f4c42783          	lw	a5,-180(s0)
    80005b54:	dba1                	beqz	a5,80005aa4 <sys_open+0x74>
      iunlockput(ip);
    80005b56:	854a                	mv	a0,s2
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	1ba080e7          	jalr	442(ra) # 80003d12 <iunlockput>
      end_op();
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	9a6080e7          	jalr	-1626(ra) # 80004506 <end_op>
      return -1;
    80005b68:	54fd                	li	s1,-1
    80005b6a:	b76d                	j	80005b14 <sys_open+0xe4>
      end_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	99a080e7          	jalr	-1638(ra) # 80004506 <end_op>
      return -1;
    80005b74:	54fd                	li	s1,-1
    80005b76:	bf79                	j	80005b14 <sys_open+0xe4>
    iunlockput(ip);
    80005b78:	854a                	mv	a0,s2
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	198080e7          	jalr	408(ra) # 80003d12 <iunlockput>
    end_op();
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	984080e7          	jalr	-1660(ra) # 80004506 <end_op>
    return -1;
    80005b8a:	54fd                	li	s1,-1
    80005b8c:	b761                	j	80005b14 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b8e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b92:	04691783          	lh	a5,70(s2)
    80005b96:	02f99223          	sh	a5,36(s3)
    80005b9a:	bf2d                	j	80005ad4 <sys_open+0xa4>
    itrunc(ip);
    80005b9c:	854a                	mv	a0,s2
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	020080e7          	jalr	32(ra) # 80003bbe <itrunc>
    80005ba6:	bfb1                	j	80005b02 <sys_open+0xd2>
      fileclose(f);
    80005ba8:	854e                	mv	a0,s3
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	da8080e7          	jalr	-600(ra) # 80004952 <fileclose>
    iunlockput(ip);
    80005bb2:	854a                	mv	a0,s2
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	15e080e7          	jalr	350(ra) # 80003d12 <iunlockput>
    end_op();
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	94a080e7          	jalr	-1718(ra) # 80004506 <end_op>
    return -1;
    80005bc4:	54fd                	li	s1,-1
    80005bc6:	b7b9                	j	80005b14 <sys_open+0xe4>

0000000080005bc8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bc8:	7175                	addi	sp,sp,-144
    80005bca:	e506                	sd	ra,136(sp)
    80005bcc:	e122                	sd	s0,128(sp)
    80005bce:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	8b6080e7          	jalr	-1866(ra) # 80004486 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bd8:	08000613          	li	a2,128
    80005bdc:	f7040593          	addi	a1,s0,-144
    80005be0:	4501                	li	a0,0
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	21e080e7          	jalr	542(ra) # 80002e00 <argstr>
    80005bea:	02054963          	bltz	a0,80005c1c <sys_mkdir+0x54>
    80005bee:	4681                	li	a3,0
    80005bf0:	4601                	li	a2,0
    80005bf2:	4585                	li	a1,1
    80005bf4:	f7040513          	addi	a0,s0,-144
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	7fe080e7          	jalr	2046(ra) # 800053f6 <create>
    80005c00:	cd11                	beqz	a0,80005c1c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	110080e7          	jalr	272(ra) # 80003d12 <iunlockput>
  end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	8fc080e7          	jalr	-1796(ra) # 80004506 <end_op>
  return 0;
    80005c12:	4501                	li	a0,0
}
    80005c14:	60aa                	ld	ra,136(sp)
    80005c16:	640a                	ld	s0,128(sp)
    80005c18:	6149                	addi	sp,sp,144
    80005c1a:	8082                	ret
    end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	8ea080e7          	jalr	-1814(ra) # 80004506 <end_op>
    return -1;
    80005c24:	557d                	li	a0,-1
    80005c26:	b7fd                	j	80005c14 <sys_mkdir+0x4c>

0000000080005c28 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c28:	7135                	addi	sp,sp,-160
    80005c2a:	ed06                	sd	ra,152(sp)
    80005c2c:	e922                	sd	s0,144(sp)
    80005c2e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	856080e7          	jalr	-1962(ra) # 80004486 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c38:	08000613          	li	a2,128
    80005c3c:	f7040593          	addi	a1,s0,-144
    80005c40:	4501                	li	a0,0
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	1be080e7          	jalr	446(ra) # 80002e00 <argstr>
    80005c4a:	04054a63          	bltz	a0,80005c9e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c4e:	f6c40593          	addi	a1,s0,-148
    80005c52:	4505                	li	a0,1
    80005c54:	ffffd097          	auipc	ra,0xffffd
    80005c58:	168080e7          	jalr	360(ra) # 80002dbc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c5c:	04054163          	bltz	a0,80005c9e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c60:	f6840593          	addi	a1,s0,-152
    80005c64:	4509                	li	a0,2
    80005c66:	ffffd097          	auipc	ra,0xffffd
    80005c6a:	156080e7          	jalr	342(ra) # 80002dbc <argint>
     argint(1, &major) < 0 ||
    80005c6e:	02054863          	bltz	a0,80005c9e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c72:	f6841683          	lh	a3,-152(s0)
    80005c76:	f6c41603          	lh	a2,-148(s0)
    80005c7a:	458d                	li	a1,3
    80005c7c:	f7040513          	addi	a0,s0,-144
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	776080e7          	jalr	1910(ra) # 800053f6 <create>
     argint(2, &minor) < 0 ||
    80005c88:	c919                	beqz	a0,80005c9e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	088080e7          	jalr	136(ra) # 80003d12 <iunlockput>
  end_op();
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	874080e7          	jalr	-1932(ra) # 80004506 <end_op>
  return 0;
    80005c9a:	4501                	li	a0,0
    80005c9c:	a031                	j	80005ca8 <sys_mknod+0x80>
    end_op();
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	868080e7          	jalr	-1944(ra) # 80004506 <end_op>
    return -1;
    80005ca6:	557d                	li	a0,-1
}
    80005ca8:	60ea                	ld	ra,152(sp)
    80005caa:	644a                	ld	s0,144(sp)
    80005cac:	610d                	addi	sp,sp,160
    80005cae:	8082                	ret

0000000080005cb0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cb0:	7135                	addi	sp,sp,-160
    80005cb2:	ed06                	sd	ra,152(sp)
    80005cb4:	e922                	sd	s0,144(sp)
    80005cb6:	e526                	sd	s1,136(sp)
    80005cb8:	e14a                	sd	s2,128(sp)
    80005cba:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cbc:	ffffc097          	auipc	ra,0xffffc
    80005cc0:	cc2080e7          	jalr	-830(ra) # 8000197e <myproc>
    80005cc4:	892a                	mv	s2,a0
  
  begin_op();
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	7c0080e7          	jalr	1984(ra) # 80004486 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cce:	08000613          	li	a2,128
    80005cd2:	f6040593          	addi	a1,s0,-160
    80005cd6:	4501                	li	a0,0
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	128080e7          	jalr	296(ra) # 80002e00 <argstr>
    80005ce0:	04054b63          	bltz	a0,80005d36 <sys_chdir+0x86>
    80005ce4:	f6040513          	addi	a0,s0,-160
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	57e080e7          	jalr	1406(ra) # 80004266 <namei>
    80005cf0:	84aa                	mv	s1,a0
    80005cf2:	c131                	beqz	a0,80005d36 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	dbc080e7          	jalr	-580(ra) # 80003ab0 <ilock>
  if(ip->type != T_DIR){
    80005cfc:	04449703          	lh	a4,68(s1)
    80005d00:	4785                	li	a5,1
    80005d02:	04f71063          	bne	a4,a5,80005d42 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d06:	8526                	mv	a0,s1
    80005d08:	ffffe097          	auipc	ra,0xffffe
    80005d0c:	e6a080e7          	jalr	-406(ra) # 80003b72 <iunlock>
  iput(p->cwd);
    80005d10:	18893503          	ld	a0,392(s2)
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	f56080e7          	jalr	-170(ra) # 80003c6a <iput>
  end_op();
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	7ea080e7          	jalr	2026(ra) # 80004506 <end_op>
  p->cwd = ip;
    80005d24:	18993423          	sd	s1,392(s2)
  return 0;
    80005d28:	4501                	li	a0,0
}
    80005d2a:	60ea                	ld	ra,152(sp)
    80005d2c:	644a                	ld	s0,144(sp)
    80005d2e:	64aa                	ld	s1,136(sp)
    80005d30:	690a                	ld	s2,128(sp)
    80005d32:	610d                	addi	sp,sp,160
    80005d34:	8082                	ret
    end_op();
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	7d0080e7          	jalr	2000(ra) # 80004506 <end_op>
    return -1;
    80005d3e:	557d                	li	a0,-1
    80005d40:	b7ed                	j	80005d2a <sys_chdir+0x7a>
    iunlockput(ip);
    80005d42:	8526                	mv	a0,s1
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	fce080e7          	jalr	-50(ra) # 80003d12 <iunlockput>
    end_op();
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	7ba080e7          	jalr	1978(ra) # 80004506 <end_op>
    return -1;
    80005d54:	557d                	li	a0,-1
    80005d56:	bfd1                	j	80005d2a <sys_chdir+0x7a>

0000000080005d58 <sys_exec>:

uint64
sys_exec(void)
{
    80005d58:	7145                	addi	sp,sp,-464
    80005d5a:	e786                	sd	ra,456(sp)
    80005d5c:	e3a2                	sd	s0,448(sp)
    80005d5e:	ff26                	sd	s1,440(sp)
    80005d60:	fb4a                	sd	s2,432(sp)
    80005d62:	f74e                	sd	s3,424(sp)
    80005d64:	f352                	sd	s4,416(sp)
    80005d66:	ef56                	sd	s5,408(sp)
    80005d68:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d6a:	08000613          	li	a2,128
    80005d6e:	f4040593          	addi	a1,s0,-192
    80005d72:	4501                	li	a0,0
    80005d74:	ffffd097          	auipc	ra,0xffffd
    80005d78:	08c080e7          	jalr	140(ra) # 80002e00 <argstr>
    return -1;
    80005d7c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d7e:	0c054a63          	bltz	a0,80005e52 <sys_exec+0xfa>
    80005d82:	e3840593          	addi	a1,s0,-456
    80005d86:	4505                	li	a0,1
    80005d88:	ffffd097          	auipc	ra,0xffffd
    80005d8c:	056080e7          	jalr	86(ra) # 80002dde <argaddr>
    80005d90:	0c054163          	bltz	a0,80005e52 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d94:	10000613          	li	a2,256
    80005d98:	4581                	li	a1,0
    80005d9a:	e4040513          	addi	a0,s0,-448
    80005d9e:	ffffb097          	auipc	ra,0xffffb
    80005da2:	f20080e7          	jalr	-224(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005da6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005daa:	89a6                	mv	s3,s1
    80005dac:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dae:	02000a13          	li	s4,32
    80005db2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005db6:	00391793          	slli	a5,s2,0x3
    80005dba:	e3040593          	addi	a1,s0,-464
    80005dbe:	e3843503          	ld	a0,-456(s0)
    80005dc2:	953e                	add	a0,a0,a5
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	f5e080e7          	jalr	-162(ra) # 80002d22 <fetchaddr>
    80005dcc:	02054a63          	bltz	a0,80005e00 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005dd0:	e3043783          	ld	a5,-464(s0)
    80005dd4:	c3b9                	beqz	a5,80005e1a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005dd6:	ffffb097          	auipc	ra,0xffffb
    80005dda:	cfc080e7          	jalr	-772(ra) # 80000ad2 <kalloc>
    80005dde:	85aa                	mv	a1,a0
    80005de0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005de4:	cd11                	beqz	a0,80005e00 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005de6:	6605                	lui	a2,0x1
    80005de8:	e3043503          	ld	a0,-464(s0)
    80005dec:	ffffd097          	auipc	ra,0xffffd
    80005df0:	f88080e7          	jalr	-120(ra) # 80002d74 <fetchstr>
    80005df4:	00054663          	bltz	a0,80005e00 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005df8:	0905                	addi	s2,s2,1
    80005dfa:	09a1                	addi	s3,s3,8
    80005dfc:	fb491be3          	bne	s2,s4,80005db2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e00:	10048913          	addi	s2,s1,256
    80005e04:	6088                	ld	a0,0(s1)
    80005e06:	c529                	beqz	a0,80005e50 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e08:	ffffb097          	auipc	ra,0xffffb
    80005e0c:	bce080e7          	jalr	-1074(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e10:	04a1                	addi	s1,s1,8
    80005e12:	ff2499e3          	bne	s1,s2,80005e04 <sys_exec+0xac>
  return -1;
    80005e16:	597d                	li	s2,-1
    80005e18:	a82d                	j	80005e52 <sys_exec+0xfa>
      argv[i] = 0;
    80005e1a:	0a8e                	slli	s5,s5,0x3
    80005e1c:	fc040793          	addi	a5,s0,-64
    80005e20:	9abe                	add	s5,s5,a5
    80005e22:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005e26:	e4040593          	addi	a1,s0,-448
    80005e2a:	f4040513          	addi	a0,s0,-192
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	176080e7          	jalr	374(ra) # 80004fa4 <exec>
    80005e36:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e38:	10048993          	addi	s3,s1,256
    80005e3c:	6088                	ld	a0,0(s1)
    80005e3e:	c911                	beqz	a0,80005e52 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e40:	ffffb097          	auipc	ra,0xffffb
    80005e44:	b96080e7          	jalr	-1130(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e48:	04a1                	addi	s1,s1,8
    80005e4a:	ff3499e3          	bne	s1,s3,80005e3c <sys_exec+0xe4>
    80005e4e:	a011                	j	80005e52 <sys_exec+0xfa>
  return -1;
    80005e50:	597d                	li	s2,-1
}
    80005e52:	854a                	mv	a0,s2
    80005e54:	60be                	ld	ra,456(sp)
    80005e56:	641e                	ld	s0,448(sp)
    80005e58:	74fa                	ld	s1,440(sp)
    80005e5a:	795a                	ld	s2,432(sp)
    80005e5c:	79ba                	ld	s3,424(sp)
    80005e5e:	7a1a                	ld	s4,416(sp)
    80005e60:	6afa                	ld	s5,408(sp)
    80005e62:	6179                	addi	sp,sp,464
    80005e64:	8082                	ret

0000000080005e66 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e66:	7139                	addi	sp,sp,-64
    80005e68:	fc06                	sd	ra,56(sp)
    80005e6a:	f822                	sd	s0,48(sp)
    80005e6c:	f426                	sd	s1,40(sp)
    80005e6e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	b0e080e7          	jalr	-1266(ra) # 8000197e <myproc>
    80005e78:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e7a:	fd840593          	addi	a1,s0,-40
    80005e7e:	4501                	li	a0,0
    80005e80:	ffffd097          	auipc	ra,0xffffd
    80005e84:	f5e080e7          	jalr	-162(ra) # 80002dde <argaddr>
    return -1;
    80005e88:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e8a:	0e054263          	bltz	a0,80005f6e <sys_pipe+0x108>
  if(pipealloc(&rf, &wf) < 0)
    80005e8e:	fc840593          	addi	a1,s0,-56
    80005e92:	fd040513          	addi	a0,s0,-48
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	dec080e7          	jalr	-532(ra) # 80004c82 <pipealloc>
    return -1;
    80005e9e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ea0:	0c054763          	bltz	a0,80005f6e <sys_pipe+0x108>
  fd0 = -1;
    80005ea4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ea8:	fd043503          	ld	a0,-48(s0)
    80005eac:	fffff097          	auipc	ra,0xfffff
    80005eb0:	508080e7          	jalr	1288(ra) # 800053b4 <fdalloc>
    80005eb4:	fca42223          	sw	a0,-60(s0)
    80005eb8:	08054e63          	bltz	a0,80005f54 <sys_pipe+0xee>
    80005ebc:	fc843503          	ld	a0,-56(s0)
    80005ec0:	fffff097          	auipc	ra,0xfffff
    80005ec4:	4f4080e7          	jalr	1268(ra) # 800053b4 <fdalloc>
    80005ec8:	fca42023          	sw	a0,-64(s0)
    80005ecc:	06054a63          	bltz	a0,80005f40 <sys_pipe+0xda>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ed0:	4691                	li	a3,4
    80005ed2:	fc440613          	addi	a2,s0,-60
    80005ed6:	fd843583          	ld	a1,-40(s0)
    80005eda:	64c8                	ld	a0,136(s1)
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	762080e7          	jalr	1890(ra) # 8000163e <copyout>
    80005ee4:	02054063          	bltz	a0,80005f04 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ee8:	4691                	li	a3,4
    80005eea:	fc040613          	addi	a2,s0,-64
    80005eee:	fd843583          	ld	a1,-40(s0)
    80005ef2:	0591                	addi	a1,a1,4
    80005ef4:	64c8                	ld	a0,136(s1)
    80005ef6:	ffffb097          	auipc	ra,0xffffb
    80005efa:	748080e7          	jalr	1864(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005efe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f00:	06055763          	bgez	a0,80005f6e <sys_pipe+0x108>
    p->ofile[fd0] = 0;
    80005f04:	fc442783          	lw	a5,-60(s0)
    80005f08:	02078793          	addi	a5,a5,32
    80005f0c:	078e                	slli	a5,a5,0x3
    80005f0e:	97a6                	add	a5,a5,s1
    80005f10:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f14:	fc042503          	lw	a0,-64(s0)
    80005f18:	02050513          	addi	a0,a0,32
    80005f1c:	050e                	slli	a0,a0,0x3
    80005f1e:	9526                	add	a0,a0,s1
    80005f20:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f24:	fd043503          	ld	a0,-48(s0)
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	a2a080e7          	jalr	-1494(ra) # 80004952 <fileclose>
    fileclose(wf);
    80005f30:	fc843503          	ld	a0,-56(s0)
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	a1e080e7          	jalr	-1506(ra) # 80004952 <fileclose>
    return -1;
    80005f3c:	57fd                	li	a5,-1
    80005f3e:	a805                	j	80005f6e <sys_pipe+0x108>
    if(fd0 >= 0)
    80005f40:	fc442783          	lw	a5,-60(s0)
    80005f44:	0007c863          	bltz	a5,80005f54 <sys_pipe+0xee>
      p->ofile[fd0] = 0;
    80005f48:	02078513          	addi	a0,a5,32
    80005f4c:	050e                	slli	a0,a0,0x3
    80005f4e:	9526                	add	a0,a0,s1
    80005f50:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f54:	fd043503          	ld	a0,-48(s0)
    80005f58:	fffff097          	auipc	ra,0xfffff
    80005f5c:	9fa080e7          	jalr	-1542(ra) # 80004952 <fileclose>
    fileclose(wf);
    80005f60:	fc843503          	ld	a0,-56(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	9ee080e7          	jalr	-1554(ra) # 80004952 <fileclose>
    return -1;
    80005f6c:	57fd                	li	a5,-1
}
    80005f6e:	853e                	mv	a0,a5
    80005f70:	70e2                	ld	ra,56(sp)
    80005f72:	7442                	ld	s0,48(sp)
    80005f74:	74a2                	ld	s1,40(sp)
    80005f76:	6121                	addi	sp,sp,64
    80005f78:	8082                	ret
    80005f7a:	0000                	unimp
    80005f7c:	0000                	unimp
	...

0000000080005f80 <kernelvec>:
    80005f80:	7111                	addi	sp,sp,-256
    80005f82:	e006                	sd	ra,0(sp)
    80005f84:	e40a                	sd	sp,8(sp)
    80005f86:	e80e                	sd	gp,16(sp)
    80005f88:	ec12                	sd	tp,24(sp)
    80005f8a:	f016                	sd	t0,32(sp)
    80005f8c:	f41a                	sd	t1,40(sp)
    80005f8e:	f81e                	sd	t2,48(sp)
    80005f90:	fc22                	sd	s0,56(sp)
    80005f92:	e0a6                	sd	s1,64(sp)
    80005f94:	e4aa                	sd	a0,72(sp)
    80005f96:	e8ae                	sd	a1,80(sp)
    80005f98:	ecb2                	sd	a2,88(sp)
    80005f9a:	f0b6                	sd	a3,96(sp)
    80005f9c:	f4ba                	sd	a4,104(sp)
    80005f9e:	f8be                	sd	a5,112(sp)
    80005fa0:	fcc2                	sd	a6,120(sp)
    80005fa2:	e146                	sd	a7,128(sp)
    80005fa4:	e54a                	sd	s2,136(sp)
    80005fa6:	e94e                	sd	s3,144(sp)
    80005fa8:	ed52                	sd	s4,152(sp)
    80005faa:	f156                	sd	s5,160(sp)
    80005fac:	f55a                	sd	s6,168(sp)
    80005fae:	f95e                	sd	s7,176(sp)
    80005fb0:	fd62                	sd	s8,184(sp)
    80005fb2:	e1e6                	sd	s9,192(sp)
    80005fb4:	e5ea                	sd	s10,200(sp)
    80005fb6:	e9ee                	sd	s11,208(sp)
    80005fb8:	edf2                	sd	t3,216(sp)
    80005fba:	f1f6                	sd	t4,224(sp)
    80005fbc:	f5fa                	sd	t5,232(sp)
    80005fbe:	f9fe                	sd	t6,240(sp)
    80005fc0:	c21fc0ef          	jal	ra,80002be0 <kerneltrap>
    80005fc4:	6082                	ld	ra,0(sp)
    80005fc6:	6122                	ld	sp,8(sp)
    80005fc8:	61c2                	ld	gp,16(sp)
    80005fca:	7282                	ld	t0,32(sp)
    80005fcc:	7322                	ld	t1,40(sp)
    80005fce:	73c2                	ld	t2,48(sp)
    80005fd0:	7462                	ld	s0,56(sp)
    80005fd2:	6486                	ld	s1,64(sp)
    80005fd4:	6526                	ld	a0,72(sp)
    80005fd6:	65c6                	ld	a1,80(sp)
    80005fd8:	6666                	ld	a2,88(sp)
    80005fda:	7686                	ld	a3,96(sp)
    80005fdc:	7726                	ld	a4,104(sp)
    80005fde:	77c6                	ld	a5,112(sp)
    80005fe0:	7866                	ld	a6,120(sp)
    80005fe2:	688a                	ld	a7,128(sp)
    80005fe4:	692a                	ld	s2,136(sp)
    80005fe6:	69ca                	ld	s3,144(sp)
    80005fe8:	6a6a                	ld	s4,152(sp)
    80005fea:	7a8a                	ld	s5,160(sp)
    80005fec:	7b2a                	ld	s6,168(sp)
    80005fee:	7bca                	ld	s7,176(sp)
    80005ff0:	7c6a                	ld	s8,184(sp)
    80005ff2:	6c8e                	ld	s9,192(sp)
    80005ff4:	6d2e                	ld	s10,200(sp)
    80005ff6:	6dce                	ld	s11,208(sp)
    80005ff8:	6e6e                	ld	t3,216(sp)
    80005ffa:	7e8e                	ld	t4,224(sp)
    80005ffc:	7f2e                	ld	t5,232(sp)
    80005ffe:	7fce                	ld	t6,240(sp)
    80006000:	6111                	addi	sp,sp,256
    80006002:	10200073          	sret
    80006006:	00000013          	nop
    8000600a:	00000013          	nop
    8000600e:	0001                	nop

0000000080006010 <timervec>:
    80006010:	34051573          	csrrw	a0,mscratch,a0
    80006014:	e10c                	sd	a1,0(a0)
    80006016:	e510                	sd	a2,8(a0)
    80006018:	e914                	sd	a3,16(a0)
    8000601a:	6d0c                	ld	a1,24(a0)
    8000601c:	7110                	ld	a2,32(a0)
    8000601e:	6194                	ld	a3,0(a1)
    80006020:	96b2                	add	a3,a3,a2
    80006022:	e194                	sd	a3,0(a1)
    80006024:	4589                	li	a1,2
    80006026:	14459073          	csrw	sip,a1
    8000602a:	6914                	ld	a3,16(a0)
    8000602c:	6510                	ld	a2,8(a0)
    8000602e:	610c                	ld	a1,0(a0)
    80006030:	34051573          	csrrw	a0,mscratch,a0
    80006034:	30200073          	mret
	...

000000008000603a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000603a:	1141                	addi	sp,sp,-16
    8000603c:	e422                	sd	s0,8(sp)
    8000603e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006040:	0c0007b7          	lui	a5,0xc000
    80006044:	4705                	li	a4,1
    80006046:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006048:	c3d8                	sw	a4,4(a5)
}
    8000604a:	6422                	ld	s0,8(sp)
    8000604c:	0141                	addi	sp,sp,16
    8000604e:	8082                	ret

0000000080006050 <plicinithart>:

void
plicinithart(void)
{
    80006050:	1141                	addi	sp,sp,-16
    80006052:	e406                	sd	ra,8(sp)
    80006054:	e022                	sd	s0,0(sp)
    80006056:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	8fa080e7          	jalr	-1798(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006060:	0085171b          	slliw	a4,a0,0x8
    80006064:	0c0027b7          	lui	a5,0xc002
    80006068:	97ba                	add	a5,a5,a4
    8000606a:	40200713          	li	a4,1026
    8000606e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006072:	00d5151b          	slliw	a0,a0,0xd
    80006076:	0c2017b7          	lui	a5,0xc201
    8000607a:	953e                	add	a0,a0,a5
    8000607c:	00052023          	sw	zero,0(a0)
}
    80006080:	60a2                	ld	ra,8(sp)
    80006082:	6402                	ld	s0,0(sp)
    80006084:	0141                	addi	sp,sp,16
    80006086:	8082                	ret

0000000080006088 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006088:	1141                	addi	sp,sp,-16
    8000608a:	e406                	sd	ra,8(sp)
    8000608c:	e022                	sd	s0,0(sp)
    8000608e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006090:	ffffc097          	auipc	ra,0xffffc
    80006094:	8c2080e7          	jalr	-1854(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006098:	00d5179b          	slliw	a5,a0,0xd
    8000609c:	0c201537          	lui	a0,0xc201
    800060a0:	953e                	add	a0,a0,a5
  return irq;
}
    800060a2:	4148                	lw	a0,4(a0)
    800060a4:	60a2                	ld	ra,8(sp)
    800060a6:	6402                	ld	s0,0(sp)
    800060a8:	0141                	addi	sp,sp,16
    800060aa:	8082                	ret

00000000800060ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060ac:	1101                	addi	sp,sp,-32
    800060ae:	ec06                	sd	ra,24(sp)
    800060b0:	e822                	sd	s0,16(sp)
    800060b2:	e426                	sd	s1,8(sp)
    800060b4:	1000                	addi	s0,sp,32
    800060b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	89a080e7          	jalr	-1894(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060c0:	00d5151b          	slliw	a0,a0,0xd
    800060c4:	0c2017b7          	lui	a5,0xc201
    800060c8:	97aa                	add	a5,a5,a0
    800060ca:	c3c4                	sw	s1,4(a5)
}
    800060cc:	60e2                	ld	ra,24(sp)
    800060ce:	6442                	ld	s0,16(sp)
    800060d0:	64a2                	ld	s1,8(sp)
    800060d2:	6105                	addi	sp,sp,32
    800060d4:	8082                	ret

00000000800060d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060d6:	1141                	addi	sp,sp,-16
    800060d8:	e406                	sd	ra,8(sp)
    800060da:	e022                	sd	s0,0(sp)
    800060dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060de:	479d                	li	a5,7
    800060e0:	06a7c963          	blt	a5,a0,80006152 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800060e4:	0001e797          	auipc	a5,0x1e
    800060e8:	f1c78793          	addi	a5,a5,-228 # 80024000 <disk>
    800060ec:	00a78733          	add	a4,a5,a0
    800060f0:	6789                	lui	a5,0x2
    800060f2:	97ba                	add	a5,a5,a4
    800060f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800060f8:	e7ad                	bnez	a5,80006162 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060fa:	00451793          	slli	a5,a0,0x4
    800060fe:	00020717          	auipc	a4,0x20
    80006102:	f0270713          	addi	a4,a4,-254 # 80026000 <disk+0x2000>
    80006106:	6314                	ld	a3,0(a4)
    80006108:	96be                	add	a3,a3,a5
    8000610a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000610e:	6314                	ld	a3,0(a4)
    80006110:	96be                	add	a3,a3,a5
    80006112:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006116:	6314                	ld	a3,0(a4)
    80006118:	96be                	add	a3,a3,a5
    8000611a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000611e:	6318                	ld	a4,0(a4)
    80006120:	97ba                	add	a5,a5,a4
    80006122:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006126:	0001e797          	auipc	a5,0x1e
    8000612a:	eda78793          	addi	a5,a5,-294 # 80024000 <disk>
    8000612e:	97aa                	add	a5,a5,a0
    80006130:	6509                	lui	a0,0x2
    80006132:	953e                	add	a0,a0,a5
    80006134:	4785                	li	a5,1
    80006136:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000613a:	00020517          	auipc	a0,0x20
    8000613e:	ede50513          	addi	a0,a0,-290 # 80026018 <disk+0x2018>
    80006142:	ffffc097          	auipc	ra,0xffffc
    80006146:	21c080e7          	jalr	540(ra) # 8000235e <wakeup>
}
    8000614a:	60a2                	ld	ra,8(sp)
    8000614c:	6402                	ld	s0,0(sp)
    8000614e:	0141                	addi	sp,sp,16
    80006150:	8082                	ret
    panic("free_desc 1");
    80006152:	00002517          	auipc	a0,0x2
    80006156:	72e50513          	addi	a0,a0,1838 # 80008880 <syscalls+0x330>
    8000615a:	ffffa097          	auipc	ra,0xffffa
    8000615e:	3d0080e7          	jalr	976(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006162:	00002517          	auipc	a0,0x2
    80006166:	72e50513          	addi	a0,a0,1838 # 80008890 <syscalls+0x340>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3c0080e7          	jalr	960(ra) # 8000052a <panic>

0000000080006172 <virtio_disk_init>:
{
    80006172:	1101                	addi	sp,sp,-32
    80006174:	ec06                	sd	ra,24(sp)
    80006176:	e822                	sd	s0,16(sp)
    80006178:	e426                	sd	s1,8(sp)
    8000617a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000617c:	00002597          	auipc	a1,0x2
    80006180:	72458593          	addi	a1,a1,1828 # 800088a0 <syscalls+0x350>
    80006184:	00020517          	auipc	a0,0x20
    80006188:	fa450513          	addi	a0,a0,-92 # 80026128 <disk+0x2128>
    8000618c:	ffffb097          	auipc	ra,0xffffb
    80006190:	9a6080e7          	jalr	-1626(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006194:	100017b7          	lui	a5,0x10001
    80006198:	4398                	lw	a4,0(a5)
    8000619a:	2701                	sext.w	a4,a4
    8000619c:	747277b7          	lui	a5,0x74727
    800061a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061a4:	0ef71163          	bne	a4,a5,80006286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061a8:	100017b7          	lui	a5,0x10001
    800061ac:	43dc                	lw	a5,4(a5)
    800061ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061b0:	4705                	li	a4,1
    800061b2:	0ce79a63          	bne	a5,a4,80006286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061b6:	100017b7          	lui	a5,0x10001
    800061ba:	479c                	lw	a5,8(a5)
    800061bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061be:	4709                	li	a4,2
    800061c0:	0ce79363          	bne	a5,a4,80006286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061c4:	100017b7          	lui	a5,0x10001
    800061c8:	47d8                	lw	a4,12(a5)
    800061ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061cc:	554d47b7          	lui	a5,0x554d4
    800061d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061d4:	0af71963          	bne	a4,a5,80006286 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061d8:	100017b7          	lui	a5,0x10001
    800061dc:	4705                	li	a4,1
    800061de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e0:	470d                	li	a4,3
    800061e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061e6:	c7ffe737          	lui	a4,0xc7ffe
    800061ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800061ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061f0:	2701                	sext.w	a4,a4
    800061f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f4:	472d                	li	a4,11
    800061f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f8:	473d                	li	a4,15
    800061fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800061fc:	6705                	lui	a4,0x1
    800061fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006200:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006204:	5bdc                	lw	a5,52(a5)
    80006206:	2781                	sext.w	a5,a5
  if(max == 0)
    80006208:	c7d9                	beqz	a5,80006296 <virtio_disk_init+0x124>
  if(max < NUM)
    8000620a:	471d                	li	a4,7
    8000620c:	08f77d63          	bgeu	a4,a5,800062a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006210:	100014b7          	lui	s1,0x10001
    80006214:	47a1                	li	a5,8
    80006216:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006218:	6609                	lui	a2,0x2
    8000621a:	4581                	li	a1,0
    8000621c:	0001e517          	auipc	a0,0x1e
    80006220:	de450513          	addi	a0,a0,-540 # 80024000 <disk>
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	a9a080e7          	jalr	-1382(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000622c:	0001e717          	auipc	a4,0x1e
    80006230:	dd470713          	addi	a4,a4,-556 # 80024000 <disk>
    80006234:	00c75793          	srli	a5,a4,0xc
    80006238:	2781                	sext.w	a5,a5
    8000623a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000623c:	00020797          	auipc	a5,0x20
    80006240:	dc478793          	addi	a5,a5,-572 # 80026000 <disk+0x2000>
    80006244:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006246:	0001e717          	auipc	a4,0x1e
    8000624a:	e3a70713          	addi	a4,a4,-454 # 80024080 <disk+0x80>
    8000624e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006250:	0001f717          	auipc	a4,0x1f
    80006254:	db070713          	addi	a4,a4,-592 # 80025000 <disk+0x1000>
    80006258:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000625a:	4705                	li	a4,1
    8000625c:	00e78c23          	sb	a4,24(a5)
    80006260:	00e78ca3          	sb	a4,25(a5)
    80006264:	00e78d23          	sb	a4,26(a5)
    80006268:	00e78da3          	sb	a4,27(a5)
    8000626c:	00e78e23          	sb	a4,28(a5)
    80006270:	00e78ea3          	sb	a4,29(a5)
    80006274:	00e78f23          	sb	a4,30(a5)
    80006278:	00e78fa3          	sb	a4,31(a5)
}
    8000627c:	60e2                	ld	ra,24(sp)
    8000627e:	6442                	ld	s0,16(sp)
    80006280:	64a2                	ld	s1,8(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret
    panic("could not find virtio disk");
    80006286:	00002517          	auipc	a0,0x2
    8000628a:	62a50513          	addi	a0,a0,1578 # 800088b0 <syscalls+0x360>
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	29c080e7          	jalr	668(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006296:	00002517          	auipc	a0,0x2
    8000629a:	63a50513          	addi	a0,a0,1594 # 800088d0 <syscalls+0x380>
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	28c080e7          	jalr	652(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800062a6:	00002517          	auipc	a0,0x2
    800062aa:	64a50513          	addi	a0,a0,1610 # 800088f0 <syscalls+0x3a0>
    800062ae:	ffffa097          	auipc	ra,0xffffa
    800062b2:	27c080e7          	jalr	636(ra) # 8000052a <panic>

00000000800062b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062b6:	7119                	addi	sp,sp,-128
    800062b8:	fc86                	sd	ra,120(sp)
    800062ba:	f8a2                	sd	s0,112(sp)
    800062bc:	f4a6                	sd	s1,104(sp)
    800062be:	f0ca                	sd	s2,96(sp)
    800062c0:	ecce                	sd	s3,88(sp)
    800062c2:	e8d2                	sd	s4,80(sp)
    800062c4:	e4d6                	sd	s5,72(sp)
    800062c6:	e0da                	sd	s6,64(sp)
    800062c8:	fc5e                	sd	s7,56(sp)
    800062ca:	f862                	sd	s8,48(sp)
    800062cc:	f466                	sd	s9,40(sp)
    800062ce:	f06a                	sd	s10,32(sp)
    800062d0:	ec6e                	sd	s11,24(sp)
    800062d2:	0100                	addi	s0,sp,128
    800062d4:	8aaa                	mv	s5,a0
    800062d6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062d8:	00c52c83          	lw	s9,12(a0)
    800062dc:	001c9c9b          	slliw	s9,s9,0x1
    800062e0:	1c82                	slli	s9,s9,0x20
    800062e2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062e6:	00020517          	auipc	a0,0x20
    800062ea:	e4250513          	addi	a0,a0,-446 # 80026128 <disk+0x2128>
    800062ee:	ffffb097          	auipc	ra,0xffffb
    800062f2:	8d4080e7          	jalr	-1836(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    800062f6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062f8:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062fa:	0001ec17          	auipc	s8,0x1e
    800062fe:	d06c0c13          	addi	s8,s8,-762 # 80024000 <disk>
    80006302:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006304:	4b0d                	li	s6,3
    80006306:	a0ad                	j	80006370 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006308:	00fc0733          	add	a4,s8,a5
    8000630c:	975e                	add	a4,a4,s7
    8000630e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006312:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006314:	0207c563          	bltz	a5,8000633e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006318:	2905                	addiw	s2,s2,1
    8000631a:	0611                	addi	a2,a2,4
    8000631c:	19690d63          	beq	s2,s6,800064b6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006320:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006322:	00020717          	auipc	a4,0x20
    80006326:	cf670713          	addi	a4,a4,-778 # 80026018 <disk+0x2018>
    8000632a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000632c:	00074683          	lbu	a3,0(a4)
    80006330:	fee1                	bnez	a3,80006308 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006332:	2785                	addiw	a5,a5,1
    80006334:	0705                	addi	a4,a4,1
    80006336:	fe979be3          	bne	a5,s1,8000632c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000633a:	57fd                	li	a5,-1
    8000633c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000633e:	01205d63          	blez	s2,80006358 <virtio_disk_rw+0xa2>
    80006342:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006344:	000a2503          	lw	a0,0(s4)
    80006348:	00000097          	auipc	ra,0x0
    8000634c:	d8e080e7          	jalr	-626(ra) # 800060d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006350:	2d85                	addiw	s11,s11,1
    80006352:	0a11                	addi	s4,s4,4
    80006354:	ffb918e3          	bne	s2,s11,80006344 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006358:	00020597          	auipc	a1,0x20
    8000635c:	dd058593          	addi	a1,a1,-560 # 80026128 <disk+0x2128>
    80006360:	00020517          	auipc	a0,0x20
    80006364:	cb850513          	addi	a0,a0,-840 # 80026018 <disk+0x2018>
    80006368:	ffffc097          	auipc	ra,0xffffc
    8000636c:	d82080e7          	jalr	-638(ra) # 800020ea <sleep>
  for(int i = 0; i < 3; i++){
    80006370:	f8040a13          	addi	s4,s0,-128
{
    80006374:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006376:	894e                	mv	s2,s3
    80006378:	b765                	j	80006320 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000637a:	00020697          	auipc	a3,0x20
    8000637e:	c866b683          	ld	a3,-890(a3) # 80026000 <disk+0x2000>
    80006382:	96ba                	add	a3,a3,a4
    80006384:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006388:	0001e817          	auipc	a6,0x1e
    8000638c:	c7880813          	addi	a6,a6,-904 # 80024000 <disk>
    80006390:	00020697          	auipc	a3,0x20
    80006394:	c7068693          	addi	a3,a3,-912 # 80026000 <disk+0x2000>
    80006398:	6290                	ld	a2,0(a3)
    8000639a:	963a                	add	a2,a2,a4
    8000639c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800063a0:	0015e593          	ori	a1,a1,1
    800063a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800063a8:	f8842603          	lw	a2,-120(s0)
    800063ac:	628c                	ld	a1,0(a3)
    800063ae:	972e                	add	a4,a4,a1
    800063b0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063b4:	20050593          	addi	a1,a0,512
    800063b8:	0592                	slli	a1,a1,0x4
    800063ba:	95c2                	add	a1,a1,a6
    800063bc:	577d                	li	a4,-1
    800063be:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063c2:	00461713          	slli	a4,a2,0x4
    800063c6:	6290                	ld	a2,0(a3)
    800063c8:	963a                	add	a2,a2,a4
    800063ca:	03078793          	addi	a5,a5,48
    800063ce:	97c2                	add	a5,a5,a6
    800063d0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800063d2:	629c                	ld	a5,0(a3)
    800063d4:	97ba                	add	a5,a5,a4
    800063d6:	4605                	li	a2,1
    800063d8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063da:	629c                	ld	a5,0(a3)
    800063dc:	97ba                	add	a5,a5,a4
    800063de:	4809                	li	a6,2
    800063e0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800063e4:	629c                	ld	a5,0(a3)
    800063e6:	973e                	add	a4,a4,a5
    800063e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063ec:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800063f0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800063f4:	6698                	ld	a4,8(a3)
    800063f6:	00275783          	lhu	a5,2(a4)
    800063fa:	8b9d                	andi	a5,a5,7
    800063fc:	0786                	slli	a5,a5,0x1
    800063fe:	97ba                	add	a5,a5,a4
    80006400:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006404:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006408:	6698                	ld	a4,8(a3)
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
    80006424:	02c79163          	bne	a5,a2,80006446 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006428:	00020917          	auipc	s2,0x20
    8000642c:	d0090913          	addi	s2,s2,-768 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006430:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006432:	85ca                	mv	a1,s2
    80006434:	8556                	mv	a0,s5
    80006436:	ffffc097          	auipc	ra,0xffffc
    8000643a:	cb4080e7          	jalr	-844(ra) # 800020ea <sleep>
  while(b->disk == 1) {
    8000643e:	004aa783          	lw	a5,4(s5)
    80006442:	fe9788e3          	beq	a5,s1,80006432 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006446:	f8042903          	lw	s2,-128(s0)
    8000644a:	20090793          	addi	a5,s2,512
    8000644e:	00479713          	slli	a4,a5,0x4
    80006452:	0001e797          	auipc	a5,0x1e
    80006456:	bae78793          	addi	a5,a5,-1106 # 80024000 <disk>
    8000645a:	97ba                	add	a5,a5,a4
    8000645c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006460:	00020997          	auipc	s3,0x20
    80006464:	ba098993          	addi	s3,s3,-1120 # 80026000 <disk+0x2000>
    80006468:	00491713          	slli	a4,s2,0x4
    8000646c:	0009b783          	ld	a5,0(s3)
    80006470:	97ba                	add	a5,a5,a4
    80006472:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006476:	854a                	mv	a0,s2
    80006478:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000647c:	00000097          	auipc	ra,0x0
    80006480:	c5a080e7          	jalr	-934(ra) # 800060d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006484:	8885                	andi	s1,s1,1
    80006486:	f0ed                	bnez	s1,80006468 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006488:	00020517          	auipc	a0,0x20
    8000648c:	ca050513          	addi	a0,a0,-864 # 80026128 <disk+0x2128>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	7e6080e7          	jalr	2022(ra) # 80000c76 <release>
}
    80006498:	70e6                	ld	ra,120(sp)
    8000649a:	7446                	ld	s0,112(sp)
    8000649c:	74a6                	ld	s1,104(sp)
    8000649e:	7906                	ld	s2,96(sp)
    800064a0:	69e6                	ld	s3,88(sp)
    800064a2:	6a46                	ld	s4,80(sp)
    800064a4:	6aa6                	ld	s5,72(sp)
    800064a6:	6b06                	ld	s6,64(sp)
    800064a8:	7be2                	ld	s7,56(sp)
    800064aa:	7c42                	ld	s8,48(sp)
    800064ac:	7ca2                	ld	s9,40(sp)
    800064ae:	7d02                	ld	s10,32(sp)
    800064b0:	6de2                	ld	s11,24(sp)
    800064b2:	6109                	addi	sp,sp,128
    800064b4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064b6:	f8042503          	lw	a0,-128(s0)
    800064ba:	20050793          	addi	a5,a0,512
    800064be:	0792                	slli	a5,a5,0x4
  if(write)
    800064c0:	0001e817          	auipc	a6,0x1e
    800064c4:	b4080813          	addi	a6,a6,-1216 # 80024000 <disk>
    800064c8:	00f80733          	add	a4,a6,a5
    800064cc:	01a036b3          	snez	a3,s10
    800064d0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800064d4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064d8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064dc:	7679                	lui	a2,0xffffe
    800064de:	963e                	add	a2,a2,a5
    800064e0:	00020697          	auipc	a3,0x20
    800064e4:	b2068693          	addi	a3,a3,-1248 # 80026000 <disk+0x2000>
    800064e8:	6298                	ld	a4,0(a3)
    800064ea:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064ec:	0a878593          	addi	a1,a5,168
    800064f0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064f2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064f4:	6298                	ld	a4,0(a3)
    800064f6:	9732                	add	a4,a4,a2
    800064f8:	45c1                	li	a1,16
    800064fa:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064fc:	6298                	ld	a4,0(a3)
    800064fe:	9732                	add	a4,a4,a2
    80006500:	4585                	li	a1,1
    80006502:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006506:	f8442703          	lw	a4,-124(s0)
    8000650a:	628c                	ld	a1,0(a3)
    8000650c:	962e                	add	a2,a2,a1
    8000650e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006512:	0712                	slli	a4,a4,0x4
    80006514:	6290                	ld	a2,0(a3)
    80006516:	963a                	add	a2,a2,a4
    80006518:	058a8593          	addi	a1,s5,88
    8000651c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000651e:	6294                	ld	a3,0(a3)
    80006520:	96ba                	add	a3,a3,a4
    80006522:	40000613          	li	a2,1024
    80006526:	c690                	sw	a2,8(a3)
  if(write)
    80006528:	e40d19e3          	bnez	s10,8000637a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000652c:	00020697          	auipc	a3,0x20
    80006530:	ad46b683          	ld	a3,-1324(a3) # 80026000 <disk+0x2000>
    80006534:	96ba                	add	a3,a3,a4
    80006536:	4609                	li	a2,2
    80006538:	00c69623          	sh	a2,12(a3)
    8000653c:	b5b1                	j	80006388 <virtio_disk_rw+0xd2>

000000008000653e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000653e:	1101                	addi	sp,sp,-32
    80006540:	ec06                	sd	ra,24(sp)
    80006542:	e822                	sd	s0,16(sp)
    80006544:	e426                	sd	s1,8(sp)
    80006546:	e04a                	sd	s2,0(sp)
    80006548:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000654a:	00020517          	auipc	a0,0x20
    8000654e:	bde50513          	addi	a0,a0,-1058 # 80026128 <disk+0x2128>
    80006552:	ffffa097          	auipc	ra,0xffffa
    80006556:	670080e7          	jalr	1648(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000655a:	10001737          	lui	a4,0x10001
    8000655e:	533c                	lw	a5,96(a4)
    80006560:	8b8d                	andi	a5,a5,3
    80006562:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006564:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006568:	00020797          	auipc	a5,0x20
    8000656c:	a9878793          	addi	a5,a5,-1384 # 80026000 <disk+0x2000>
    80006570:	6b94                	ld	a3,16(a5)
    80006572:	0207d703          	lhu	a4,32(a5)
    80006576:	0026d783          	lhu	a5,2(a3)
    8000657a:	06f70163          	beq	a4,a5,800065dc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000657e:	0001e917          	auipc	s2,0x1e
    80006582:	a8290913          	addi	s2,s2,-1406 # 80024000 <disk>
    80006586:	00020497          	auipc	s1,0x20
    8000658a:	a7a48493          	addi	s1,s1,-1414 # 80026000 <disk+0x2000>
    __sync_synchronize();
    8000658e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006592:	6898                	ld	a4,16(s1)
    80006594:	0204d783          	lhu	a5,32(s1)
    80006598:	8b9d                	andi	a5,a5,7
    8000659a:	078e                	slli	a5,a5,0x3
    8000659c:	97ba                	add	a5,a5,a4
    8000659e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065a0:	20078713          	addi	a4,a5,512
    800065a4:	0712                	slli	a4,a4,0x4
    800065a6:	974a                	add	a4,a4,s2
    800065a8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065ac:	e731                	bnez	a4,800065f8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065ae:	20078793          	addi	a5,a5,512
    800065b2:	0792                	slli	a5,a5,0x4
    800065b4:	97ca                	add	a5,a5,s2
    800065b6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800065b8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065bc:	ffffc097          	auipc	ra,0xffffc
    800065c0:	da2080e7          	jalr	-606(ra) # 8000235e <wakeup>

    disk.used_idx += 1;
    800065c4:	0204d783          	lhu	a5,32(s1)
    800065c8:	2785                	addiw	a5,a5,1
    800065ca:	17c2                	slli	a5,a5,0x30
    800065cc:	93c1                	srli	a5,a5,0x30
    800065ce:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065d2:	6898                	ld	a4,16(s1)
    800065d4:	00275703          	lhu	a4,2(a4)
    800065d8:	faf71be3          	bne	a4,a5,8000658e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800065dc:	00020517          	auipc	a0,0x20
    800065e0:	b4c50513          	addi	a0,a0,-1204 # 80026128 <disk+0x2128>
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	692080e7          	jalr	1682(ra) # 80000c76 <release>
}
    800065ec:	60e2                	ld	ra,24(sp)
    800065ee:	6442                	ld	s0,16(sp)
    800065f0:	64a2                	ld	s1,8(sp)
    800065f2:	6902                	ld	s2,0(sp)
    800065f4:	6105                	addi	sp,sp,32
    800065f6:	8082                	ret
      panic("virtio_disk_intr status");
    800065f8:	00002517          	auipc	a0,0x2
    800065fc:	31850513          	addi	a0,a0,792 # 80008910 <syscalls+0x3c0>
    80006600:	ffffa097          	auipc	ra,0xffffa
    80006604:	f2a080e7          	jalr	-214(ra) # 8000052a <panic>
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
