
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"

int main(int argc, char** argv){
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    fprintf(2, "Hello world!\n");
   8:	00001597          	auipc	a1,0x1
   c:	81858593          	addi	a1,a1,-2024 # 820 <malloc+0xe6>
  10:	4509                	li	a0,2
  12:	00000097          	auipc	ra,0x0
  16:	63c080e7          	jalr	1596(ra) # 64e <fprintf>
    //mask=(1<< SYS_fork)|( 1<< SYS_kill)| ( 1<< SYS_sbrk) | ( 1<< SYS_write);
    int mask=(1<< SYS_fork); //
    sleep(1); //doesn't print this sleep
  1a:	4505                	li	a0,1
  1c:	00000097          	auipc	ra,0x0
  20:	370080e7          	jalr	880(ra) # 38c <sleep>
    trace(mask, getpid());
  24:	00000097          	auipc	ra,0x0
  28:	358080e7          	jalr	856(ra) # 37c <getpid>
  2c:	85aa                	mv	a1,a0
  2e:	4509                	li	a0,2
  30:	00000097          	auipc	ra,0x0
  34:	36c080e7          	jalr	876(ra) # 39c <trace>
    int cpid=fork();//prints fork once
  38:	00000097          	auipc	ra,0x0
  3c:	2bc080e7          	jalr	700(ra) # 2f4 <fork>
    if (cpid==0){
  40:	ed0d                	bnez	a0,7a <main+0x7a>
        fork();// prints fork for the second time - the first son forks
  42:	00000097          	auipc	ra,0x0
  46:	2b2080e7          	jalr	690(ra) # 2f4 <fork>
        mask= (1 << SYS_sleep); //to turn on only the sleep bit
        //mask= (1<< 1)|(1<< 13); you can uncomment this inorder to check you print for both fork and sleep syscalls
        trace(mask, getpid()); //the first son and the grandchilde changes mask to print sleep
  4a:	00000097          	auipc	ra,0x0
  4e:	332080e7          	jalr	818(ra) # 37c <getpid>
  52:	85aa                	mv	a1,a0
  54:	6509                	lui	a0,0x2
  56:	00000097          	auipc	ra,0x0
  5a:	346080e7          	jalr	838(ra) # 39c <trace>
        sleep(1);
  5e:	4505                	li	a0,1
  60:	00000097          	auipc	ra,0x0
  64:	32c080e7          	jalr	812(ra) # 38c <sleep>
        fork();//should print nothing
  68:	00000097          	auipc	ra,0x0
  6c:	28c080e7          	jalr	652(ra) # 2f4 <fork>
        exit(0);//shold print nothing
  70:	4501                	li	a0,0
  72:	00000097          	auipc	ra,0x0
  76:	28a080e7          	jalr	650(ra) # 2fc <exit>
    }
    else {
        sleep(10);// the father doesnt pring it - has original mask
  7a:	4529                	li	a0,10
  7c:	00000097          	auipc	ra,0x0
  80:	310080e7          	jalr	784(ra) # 38c <sleep>
    }
    exit(0);
  84:	4501                	li	a0,0
  86:	00000097          	auipc	ra,0x0
  8a:	276080e7          	jalr	630(ra) # 2fc <exit>

000000000000008e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  8e:	1141                	addi	sp,sp,-16
  90:	e422                	sd	s0,8(sp)
  92:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  94:	87aa                	mv	a5,a0
  96:	0585                	addi	a1,a1,1
  98:	0785                	addi	a5,a5,1
  9a:	fff5c703          	lbu	a4,-1(a1)
  9e:	fee78fa3          	sb	a4,-1(a5)
  a2:	fb75                	bnez	a4,96 <strcpy+0x8>
    ;
  return os;
}
  a4:	6422                	ld	s0,8(sp)
  a6:	0141                	addi	sp,sp,16
  a8:	8082                	ret

00000000000000aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
  aa:	1141                	addi	sp,sp,-16
  ac:	e422                	sd	s0,8(sp)
  ae:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  b0:	00054783          	lbu	a5,0(a0) # 2000 <__global_pointer$+0xfb7>
  b4:	cb91                	beqz	a5,c8 <strcmp+0x1e>
  b6:	0005c703          	lbu	a4,0(a1)
  ba:	00f71763          	bne	a4,a5,c8 <strcmp+0x1e>
    p++, q++;
  be:	0505                	addi	a0,a0,1
  c0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  c2:	00054783          	lbu	a5,0(a0)
  c6:	fbe5                	bnez	a5,b6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  c8:	0005c503          	lbu	a0,0(a1)
}
  cc:	40a7853b          	subw	a0,a5,a0
  d0:	6422                	ld	s0,8(sp)
  d2:	0141                	addi	sp,sp,16
  d4:	8082                	ret

00000000000000d6 <strlen>:

uint
strlen(const char *s)
{
  d6:	1141                	addi	sp,sp,-16
  d8:	e422                	sd	s0,8(sp)
  da:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  dc:	00054783          	lbu	a5,0(a0)
  e0:	cf91                	beqz	a5,fc <strlen+0x26>
  e2:	0505                	addi	a0,a0,1
  e4:	87aa                	mv	a5,a0
  e6:	4685                	li	a3,1
  e8:	9e89                	subw	a3,a3,a0
  ea:	00f6853b          	addw	a0,a3,a5
  ee:	0785                	addi	a5,a5,1
  f0:	fff7c703          	lbu	a4,-1(a5)
  f4:	fb7d                	bnez	a4,ea <strlen+0x14>
    ;
  return n;
}
  f6:	6422                	ld	s0,8(sp)
  f8:	0141                	addi	sp,sp,16
  fa:	8082                	ret
  for(n = 0; s[n]; n++)
  fc:	4501                	li	a0,0
  fe:	bfe5                	j	f6 <strlen+0x20>

0000000000000100 <memset>:

void*
memset(void *dst, int c, uint n)
{
 100:	1141                	addi	sp,sp,-16
 102:	e422                	sd	s0,8(sp)
 104:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 106:	ca19                	beqz	a2,11c <memset+0x1c>
 108:	87aa                	mv	a5,a0
 10a:	1602                	slli	a2,a2,0x20
 10c:	9201                	srli	a2,a2,0x20
 10e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 112:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 116:	0785                	addi	a5,a5,1
 118:	fee79de3          	bne	a5,a4,112 <memset+0x12>
  }
  return dst;
}
 11c:	6422                	ld	s0,8(sp)
 11e:	0141                	addi	sp,sp,16
 120:	8082                	ret

0000000000000122 <strchr>:

char*
strchr(const char *s, char c)
{
 122:	1141                	addi	sp,sp,-16
 124:	e422                	sd	s0,8(sp)
 126:	0800                	addi	s0,sp,16
  for(; *s; s++)
 128:	00054783          	lbu	a5,0(a0)
 12c:	cb99                	beqz	a5,142 <strchr+0x20>
    if(*s == c)
 12e:	00f58763          	beq	a1,a5,13c <strchr+0x1a>
  for(; *s; s++)
 132:	0505                	addi	a0,a0,1
 134:	00054783          	lbu	a5,0(a0)
 138:	fbfd                	bnez	a5,12e <strchr+0xc>
      return (char*)s;
  return 0;
 13a:	4501                	li	a0,0
}
 13c:	6422                	ld	s0,8(sp)
 13e:	0141                	addi	sp,sp,16
 140:	8082                	ret
  return 0;
 142:	4501                	li	a0,0
 144:	bfe5                	j	13c <strchr+0x1a>

0000000000000146 <gets>:

char*
gets(char *buf, int max)
{
 146:	711d                	addi	sp,sp,-96
 148:	ec86                	sd	ra,88(sp)
 14a:	e8a2                	sd	s0,80(sp)
 14c:	e4a6                	sd	s1,72(sp)
 14e:	e0ca                	sd	s2,64(sp)
 150:	fc4e                	sd	s3,56(sp)
 152:	f852                	sd	s4,48(sp)
 154:	f456                	sd	s5,40(sp)
 156:	f05a                	sd	s6,32(sp)
 158:	ec5e                	sd	s7,24(sp)
 15a:	1080                	addi	s0,sp,96
 15c:	8baa                	mv	s7,a0
 15e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 160:	892a                	mv	s2,a0
 162:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 164:	4aa9                	li	s5,10
 166:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 168:	89a6                	mv	s3,s1
 16a:	2485                	addiw	s1,s1,1
 16c:	0344d863          	bge	s1,s4,19c <gets+0x56>
    cc = read(0, &c, 1);
 170:	4605                	li	a2,1
 172:	faf40593          	addi	a1,s0,-81
 176:	4501                	li	a0,0
 178:	00000097          	auipc	ra,0x0
 17c:	19c080e7          	jalr	412(ra) # 314 <read>
    if(cc < 1)
 180:	00a05e63          	blez	a0,19c <gets+0x56>
    buf[i++] = c;
 184:	faf44783          	lbu	a5,-81(s0)
 188:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 18c:	01578763          	beq	a5,s5,19a <gets+0x54>
 190:	0905                	addi	s2,s2,1
 192:	fd679be3          	bne	a5,s6,168 <gets+0x22>
  for(i=0; i+1 < max; ){
 196:	89a6                	mv	s3,s1
 198:	a011                	j	19c <gets+0x56>
 19a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 19c:	99de                	add	s3,s3,s7
 19e:	00098023          	sb	zero,0(s3)
  return buf;
}
 1a2:	855e                	mv	a0,s7
 1a4:	60e6                	ld	ra,88(sp)
 1a6:	6446                	ld	s0,80(sp)
 1a8:	64a6                	ld	s1,72(sp)
 1aa:	6906                	ld	s2,64(sp)
 1ac:	79e2                	ld	s3,56(sp)
 1ae:	7a42                	ld	s4,48(sp)
 1b0:	7aa2                	ld	s5,40(sp)
 1b2:	7b02                	ld	s6,32(sp)
 1b4:	6be2                	ld	s7,24(sp)
 1b6:	6125                	addi	sp,sp,96
 1b8:	8082                	ret

00000000000001ba <stat>:

int
stat(const char *n, struct stat *st)
{
 1ba:	1101                	addi	sp,sp,-32
 1bc:	ec06                	sd	ra,24(sp)
 1be:	e822                	sd	s0,16(sp)
 1c0:	e426                	sd	s1,8(sp)
 1c2:	e04a                	sd	s2,0(sp)
 1c4:	1000                	addi	s0,sp,32
 1c6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1c8:	4581                	li	a1,0
 1ca:	00000097          	auipc	ra,0x0
 1ce:	172080e7          	jalr	370(ra) # 33c <open>
  if(fd < 0)
 1d2:	02054563          	bltz	a0,1fc <stat+0x42>
 1d6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1d8:	85ca                	mv	a1,s2
 1da:	00000097          	auipc	ra,0x0
 1de:	17a080e7          	jalr	378(ra) # 354 <fstat>
 1e2:	892a                	mv	s2,a0
  close(fd);
 1e4:	8526                	mv	a0,s1
 1e6:	00000097          	auipc	ra,0x0
 1ea:	13e080e7          	jalr	318(ra) # 324 <close>
  return r;
}
 1ee:	854a                	mv	a0,s2
 1f0:	60e2                	ld	ra,24(sp)
 1f2:	6442                	ld	s0,16(sp)
 1f4:	64a2                	ld	s1,8(sp)
 1f6:	6902                	ld	s2,0(sp)
 1f8:	6105                	addi	sp,sp,32
 1fa:	8082                	ret
    return -1;
 1fc:	597d                	li	s2,-1
 1fe:	bfc5                	j	1ee <stat+0x34>

0000000000000200 <atoi>:

int
atoi(const char *s)
{
 200:	1141                	addi	sp,sp,-16
 202:	e422                	sd	s0,8(sp)
 204:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 206:	00054603          	lbu	a2,0(a0)
 20a:	fd06079b          	addiw	a5,a2,-48
 20e:	0ff7f793          	andi	a5,a5,255
 212:	4725                	li	a4,9
 214:	02f76963          	bltu	a4,a5,246 <atoi+0x46>
 218:	86aa                	mv	a3,a0
  n = 0;
 21a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 21c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 21e:	0685                	addi	a3,a3,1
 220:	0025179b          	slliw	a5,a0,0x2
 224:	9fa9                	addw	a5,a5,a0
 226:	0017979b          	slliw	a5,a5,0x1
 22a:	9fb1                	addw	a5,a5,a2
 22c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 230:	0006c603          	lbu	a2,0(a3)
 234:	fd06071b          	addiw	a4,a2,-48
 238:	0ff77713          	andi	a4,a4,255
 23c:	fee5f1e3          	bgeu	a1,a4,21e <atoi+0x1e>
  return n;
}
 240:	6422                	ld	s0,8(sp)
 242:	0141                	addi	sp,sp,16
 244:	8082                	ret
  n = 0;
 246:	4501                	li	a0,0
 248:	bfe5                	j	240 <atoi+0x40>

000000000000024a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 24a:	1141                	addi	sp,sp,-16
 24c:	e422                	sd	s0,8(sp)
 24e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 250:	02b57463          	bgeu	a0,a1,278 <memmove+0x2e>
    while(n-- > 0)
 254:	00c05f63          	blez	a2,272 <memmove+0x28>
 258:	1602                	slli	a2,a2,0x20
 25a:	9201                	srli	a2,a2,0x20
 25c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 260:	872a                	mv	a4,a0
      *dst++ = *src++;
 262:	0585                	addi	a1,a1,1
 264:	0705                	addi	a4,a4,1
 266:	fff5c683          	lbu	a3,-1(a1)
 26a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 26e:	fee79ae3          	bne	a5,a4,262 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 272:	6422                	ld	s0,8(sp)
 274:	0141                	addi	sp,sp,16
 276:	8082                	ret
    dst += n;
 278:	00c50733          	add	a4,a0,a2
    src += n;
 27c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 27e:	fec05ae3          	blez	a2,272 <memmove+0x28>
 282:	fff6079b          	addiw	a5,a2,-1
 286:	1782                	slli	a5,a5,0x20
 288:	9381                	srli	a5,a5,0x20
 28a:	fff7c793          	not	a5,a5
 28e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 290:	15fd                	addi	a1,a1,-1
 292:	177d                	addi	a4,a4,-1
 294:	0005c683          	lbu	a3,0(a1)
 298:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 29c:	fee79ae3          	bne	a5,a4,290 <memmove+0x46>
 2a0:	bfc9                	j	272 <memmove+0x28>

00000000000002a2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2a2:	1141                	addi	sp,sp,-16
 2a4:	e422                	sd	s0,8(sp)
 2a6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2a8:	ca05                	beqz	a2,2d8 <memcmp+0x36>
 2aa:	fff6069b          	addiw	a3,a2,-1
 2ae:	1682                	slli	a3,a3,0x20
 2b0:	9281                	srli	a3,a3,0x20
 2b2:	0685                	addi	a3,a3,1
 2b4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2b6:	00054783          	lbu	a5,0(a0)
 2ba:	0005c703          	lbu	a4,0(a1)
 2be:	00e79863          	bne	a5,a4,2ce <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2c2:	0505                	addi	a0,a0,1
    p2++;
 2c4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2c6:	fed518e3          	bne	a0,a3,2b6 <memcmp+0x14>
  }
  return 0;
 2ca:	4501                	li	a0,0
 2cc:	a019                	j	2d2 <memcmp+0x30>
      return *p1 - *p2;
 2ce:	40e7853b          	subw	a0,a5,a4
}
 2d2:	6422                	ld	s0,8(sp)
 2d4:	0141                	addi	sp,sp,16
 2d6:	8082                	ret
  return 0;
 2d8:	4501                	li	a0,0
 2da:	bfe5                	j	2d2 <memcmp+0x30>

00000000000002dc <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2dc:	1141                	addi	sp,sp,-16
 2de:	e406                	sd	ra,8(sp)
 2e0:	e022                	sd	s0,0(sp)
 2e2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2e4:	00000097          	auipc	ra,0x0
 2e8:	f66080e7          	jalr	-154(ra) # 24a <memmove>
}
 2ec:	60a2                	ld	ra,8(sp)
 2ee:	6402                	ld	s0,0(sp)
 2f0:	0141                	addi	sp,sp,16
 2f2:	8082                	ret

00000000000002f4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2f4:	4885                	li	a7,1
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <exit>:
.global exit
exit:
 li a7, SYS_exit
 2fc:	4889                	li	a7,2
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <wait>:
.global wait
wait:
 li a7, SYS_wait
 304:	488d                	li	a7,3
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 30c:	4891                	li	a7,4
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <read>:
.global read
read:
 li a7, SYS_read
 314:	4895                	li	a7,5
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <write>:
.global write
write:
 li a7, SYS_write
 31c:	48c1                	li	a7,16
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <close>:
.global close
close:
 li a7, SYS_close
 324:	48d5                	li	a7,21
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <kill>:
.global kill
kill:
 li a7, SYS_kill
 32c:	4899                	li	a7,6
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <exec>:
.global exec
exec:
 li a7, SYS_exec
 334:	489d                	li	a7,7
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <open>:
.global open
open:
 li a7, SYS_open
 33c:	48bd                	li	a7,15
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 344:	48c5                	li	a7,17
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 34c:	48c9                	li	a7,18
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 354:	48a1                	li	a7,8
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <link>:
.global link
link:
 li a7, SYS_link
 35c:	48cd                	li	a7,19
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 364:	48d1                	li	a7,20
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 36c:	48a5                	li	a7,9
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <dup>:
.global dup
dup:
 li a7, SYS_dup
 374:	48a9                	li	a7,10
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 37c:	48ad                	li	a7,11
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 384:	48b1                	li	a7,12
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 38c:	48b5                	li	a7,13
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 394:	48b9                	li	a7,14
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <trace>:
.global trace
trace:
 li a7, SYS_trace
 39c:	48d9                	li	a7,22
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3a4:	1101                	addi	sp,sp,-32
 3a6:	ec06                	sd	ra,24(sp)
 3a8:	e822                	sd	s0,16(sp)
 3aa:	1000                	addi	s0,sp,32
 3ac:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3b0:	4605                	li	a2,1
 3b2:	fef40593          	addi	a1,s0,-17
 3b6:	00000097          	auipc	ra,0x0
 3ba:	f66080e7          	jalr	-154(ra) # 31c <write>
}
 3be:	60e2                	ld	ra,24(sp)
 3c0:	6442                	ld	s0,16(sp)
 3c2:	6105                	addi	sp,sp,32
 3c4:	8082                	ret

00000000000003c6 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3c6:	7139                	addi	sp,sp,-64
 3c8:	fc06                	sd	ra,56(sp)
 3ca:	f822                	sd	s0,48(sp)
 3cc:	f426                	sd	s1,40(sp)
 3ce:	f04a                	sd	s2,32(sp)
 3d0:	ec4e                	sd	s3,24(sp)
 3d2:	0080                	addi	s0,sp,64
 3d4:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3d6:	c299                	beqz	a3,3dc <printint+0x16>
 3d8:	0805c863          	bltz	a1,468 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3dc:	2581                	sext.w	a1,a1
  neg = 0;
 3de:	4881                	li	a7,0
 3e0:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3e4:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3e6:	2601                	sext.w	a2,a2
 3e8:	00000517          	auipc	a0,0x0
 3ec:	45050513          	addi	a0,a0,1104 # 838 <digits>
 3f0:	883a                	mv	a6,a4
 3f2:	2705                	addiw	a4,a4,1
 3f4:	02c5f7bb          	remuw	a5,a1,a2
 3f8:	1782                	slli	a5,a5,0x20
 3fa:	9381                	srli	a5,a5,0x20
 3fc:	97aa                	add	a5,a5,a0
 3fe:	0007c783          	lbu	a5,0(a5)
 402:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 406:	0005879b          	sext.w	a5,a1
 40a:	02c5d5bb          	divuw	a1,a1,a2
 40e:	0685                	addi	a3,a3,1
 410:	fec7f0e3          	bgeu	a5,a2,3f0 <printint+0x2a>
  if(neg)
 414:	00088b63          	beqz	a7,42a <printint+0x64>
    buf[i++] = '-';
 418:	fd040793          	addi	a5,s0,-48
 41c:	973e                	add	a4,a4,a5
 41e:	02d00793          	li	a5,45
 422:	fef70823          	sb	a5,-16(a4)
 426:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 42a:	02e05863          	blez	a4,45a <printint+0x94>
 42e:	fc040793          	addi	a5,s0,-64
 432:	00e78933          	add	s2,a5,a4
 436:	fff78993          	addi	s3,a5,-1
 43a:	99ba                	add	s3,s3,a4
 43c:	377d                	addiw	a4,a4,-1
 43e:	1702                	slli	a4,a4,0x20
 440:	9301                	srli	a4,a4,0x20
 442:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 446:	fff94583          	lbu	a1,-1(s2)
 44a:	8526                	mv	a0,s1
 44c:	00000097          	auipc	ra,0x0
 450:	f58080e7          	jalr	-168(ra) # 3a4 <putc>
  while(--i >= 0)
 454:	197d                	addi	s2,s2,-1
 456:	ff3918e3          	bne	s2,s3,446 <printint+0x80>
}
 45a:	70e2                	ld	ra,56(sp)
 45c:	7442                	ld	s0,48(sp)
 45e:	74a2                	ld	s1,40(sp)
 460:	7902                	ld	s2,32(sp)
 462:	69e2                	ld	s3,24(sp)
 464:	6121                	addi	sp,sp,64
 466:	8082                	ret
    x = -xx;
 468:	40b005bb          	negw	a1,a1
    neg = 1;
 46c:	4885                	li	a7,1
    x = -xx;
 46e:	bf8d                	j	3e0 <printint+0x1a>

0000000000000470 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 470:	7119                	addi	sp,sp,-128
 472:	fc86                	sd	ra,120(sp)
 474:	f8a2                	sd	s0,112(sp)
 476:	f4a6                	sd	s1,104(sp)
 478:	f0ca                	sd	s2,96(sp)
 47a:	ecce                	sd	s3,88(sp)
 47c:	e8d2                	sd	s4,80(sp)
 47e:	e4d6                	sd	s5,72(sp)
 480:	e0da                	sd	s6,64(sp)
 482:	fc5e                	sd	s7,56(sp)
 484:	f862                	sd	s8,48(sp)
 486:	f466                	sd	s9,40(sp)
 488:	f06a                	sd	s10,32(sp)
 48a:	ec6e                	sd	s11,24(sp)
 48c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 48e:	0005c903          	lbu	s2,0(a1)
 492:	18090f63          	beqz	s2,630 <vprintf+0x1c0>
 496:	8aaa                	mv	s5,a0
 498:	8b32                	mv	s6,a2
 49a:	00158493          	addi	s1,a1,1
  state = 0;
 49e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4a0:	02500a13          	li	s4,37
      if(c == 'd'){
 4a4:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4a8:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4ac:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4b0:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4b4:	00000b97          	auipc	s7,0x0
 4b8:	384b8b93          	addi	s7,s7,900 # 838 <digits>
 4bc:	a839                	j	4da <vprintf+0x6a>
        putc(fd, c);
 4be:	85ca                	mv	a1,s2
 4c0:	8556                	mv	a0,s5
 4c2:	00000097          	auipc	ra,0x0
 4c6:	ee2080e7          	jalr	-286(ra) # 3a4 <putc>
 4ca:	a019                	j	4d0 <vprintf+0x60>
    } else if(state == '%'){
 4cc:	01498f63          	beq	s3,s4,4ea <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4d0:	0485                	addi	s1,s1,1
 4d2:	fff4c903          	lbu	s2,-1(s1)
 4d6:	14090d63          	beqz	s2,630 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4da:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4de:	fe0997e3          	bnez	s3,4cc <vprintf+0x5c>
      if(c == '%'){
 4e2:	fd479ee3          	bne	a5,s4,4be <vprintf+0x4e>
        state = '%';
 4e6:	89be                	mv	s3,a5
 4e8:	b7e5                	j	4d0 <vprintf+0x60>
      if(c == 'd'){
 4ea:	05878063          	beq	a5,s8,52a <vprintf+0xba>
      } else if(c == 'l') {
 4ee:	05978c63          	beq	a5,s9,546 <vprintf+0xd6>
      } else if(c == 'x') {
 4f2:	07a78863          	beq	a5,s10,562 <vprintf+0xf2>
      } else if(c == 'p') {
 4f6:	09b78463          	beq	a5,s11,57e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4fa:	07300713          	li	a4,115
 4fe:	0ce78663          	beq	a5,a4,5ca <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 502:	06300713          	li	a4,99
 506:	0ee78e63          	beq	a5,a4,602 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 50a:	11478863          	beq	a5,s4,61a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 50e:	85d2                	mv	a1,s4
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	e92080e7          	jalr	-366(ra) # 3a4 <putc>
        putc(fd, c);
 51a:	85ca                	mv	a1,s2
 51c:	8556                	mv	a0,s5
 51e:	00000097          	auipc	ra,0x0
 522:	e86080e7          	jalr	-378(ra) # 3a4 <putc>
      }
      state = 0;
 526:	4981                	li	s3,0
 528:	b765                	j	4d0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 52a:	008b0913          	addi	s2,s6,8
 52e:	4685                	li	a3,1
 530:	4629                	li	a2,10
 532:	000b2583          	lw	a1,0(s6)
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	e8e080e7          	jalr	-370(ra) # 3c6 <printint>
 540:	8b4a                	mv	s6,s2
      state = 0;
 542:	4981                	li	s3,0
 544:	b771                	j	4d0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 546:	008b0913          	addi	s2,s6,8
 54a:	4681                	li	a3,0
 54c:	4629                	li	a2,10
 54e:	000b2583          	lw	a1,0(s6)
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	e72080e7          	jalr	-398(ra) # 3c6 <printint>
 55c:	8b4a                	mv	s6,s2
      state = 0;
 55e:	4981                	li	s3,0
 560:	bf85                	j	4d0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 562:	008b0913          	addi	s2,s6,8
 566:	4681                	li	a3,0
 568:	4641                	li	a2,16
 56a:	000b2583          	lw	a1,0(s6)
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e56080e7          	jalr	-426(ra) # 3c6 <printint>
 578:	8b4a                	mv	s6,s2
      state = 0;
 57a:	4981                	li	s3,0
 57c:	bf91                	j	4d0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 57e:	008b0793          	addi	a5,s6,8
 582:	f8f43423          	sd	a5,-120(s0)
 586:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 58a:	03000593          	li	a1,48
 58e:	8556                	mv	a0,s5
 590:	00000097          	auipc	ra,0x0
 594:	e14080e7          	jalr	-492(ra) # 3a4 <putc>
  putc(fd, 'x');
 598:	85ea                	mv	a1,s10
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	e08080e7          	jalr	-504(ra) # 3a4 <putc>
 5a4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5a6:	03c9d793          	srli	a5,s3,0x3c
 5aa:	97de                	add	a5,a5,s7
 5ac:	0007c583          	lbu	a1,0(a5)
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	df2080e7          	jalr	-526(ra) # 3a4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5ba:	0992                	slli	s3,s3,0x4
 5bc:	397d                	addiw	s2,s2,-1
 5be:	fe0914e3          	bnez	s2,5a6 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5c2:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5c6:	4981                	li	s3,0
 5c8:	b721                	j	4d0 <vprintf+0x60>
        s = va_arg(ap, char*);
 5ca:	008b0993          	addi	s3,s6,8
 5ce:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5d2:	02090163          	beqz	s2,5f4 <vprintf+0x184>
        while(*s != 0){
 5d6:	00094583          	lbu	a1,0(s2)
 5da:	c9a1                	beqz	a1,62a <vprintf+0x1ba>
          putc(fd, *s);
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	dc6080e7          	jalr	-570(ra) # 3a4 <putc>
          s++;
 5e6:	0905                	addi	s2,s2,1
        while(*s != 0){
 5e8:	00094583          	lbu	a1,0(s2)
 5ec:	f9e5                	bnez	a1,5dc <vprintf+0x16c>
        s = va_arg(ap, char*);
 5ee:	8b4e                	mv	s6,s3
      state = 0;
 5f0:	4981                	li	s3,0
 5f2:	bdf9                	j	4d0 <vprintf+0x60>
          s = "(null)";
 5f4:	00000917          	auipc	s2,0x0
 5f8:	23c90913          	addi	s2,s2,572 # 830 <malloc+0xf6>
        while(*s != 0){
 5fc:	02800593          	li	a1,40
 600:	bff1                	j	5dc <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 602:	008b0913          	addi	s2,s6,8
 606:	000b4583          	lbu	a1,0(s6)
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	d98080e7          	jalr	-616(ra) # 3a4 <putc>
 614:	8b4a                	mv	s6,s2
      state = 0;
 616:	4981                	li	s3,0
 618:	bd65                	j	4d0 <vprintf+0x60>
        putc(fd, c);
 61a:	85d2                	mv	a1,s4
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	d86080e7          	jalr	-634(ra) # 3a4 <putc>
      state = 0;
 626:	4981                	li	s3,0
 628:	b565                	j	4d0 <vprintf+0x60>
        s = va_arg(ap, char*);
 62a:	8b4e                	mv	s6,s3
      state = 0;
 62c:	4981                	li	s3,0
 62e:	b54d                	j	4d0 <vprintf+0x60>
    }
  }
}
 630:	70e6                	ld	ra,120(sp)
 632:	7446                	ld	s0,112(sp)
 634:	74a6                	ld	s1,104(sp)
 636:	7906                	ld	s2,96(sp)
 638:	69e6                	ld	s3,88(sp)
 63a:	6a46                	ld	s4,80(sp)
 63c:	6aa6                	ld	s5,72(sp)
 63e:	6b06                	ld	s6,64(sp)
 640:	7be2                	ld	s7,56(sp)
 642:	7c42                	ld	s8,48(sp)
 644:	7ca2                	ld	s9,40(sp)
 646:	7d02                	ld	s10,32(sp)
 648:	6de2                	ld	s11,24(sp)
 64a:	6109                	addi	sp,sp,128
 64c:	8082                	ret

000000000000064e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 64e:	715d                	addi	sp,sp,-80
 650:	ec06                	sd	ra,24(sp)
 652:	e822                	sd	s0,16(sp)
 654:	1000                	addi	s0,sp,32
 656:	e010                	sd	a2,0(s0)
 658:	e414                	sd	a3,8(s0)
 65a:	e818                	sd	a4,16(s0)
 65c:	ec1c                	sd	a5,24(s0)
 65e:	03043023          	sd	a6,32(s0)
 662:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 666:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 66a:	8622                	mv	a2,s0
 66c:	00000097          	auipc	ra,0x0
 670:	e04080e7          	jalr	-508(ra) # 470 <vprintf>
}
 674:	60e2                	ld	ra,24(sp)
 676:	6442                	ld	s0,16(sp)
 678:	6161                	addi	sp,sp,80
 67a:	8082                	ret

000000000000067c <printf>:

void
printf(const char *fmt, ...)
{
 67c:	711d                	addi	sp,sp,-96
 67e:	ec06                	sd	ra,24(sp)
 680:	e822                	sd	s0,16(sp)
 682:	1000                	addi	s0,sp,32
 684:	e40c                	sd	a1,8(s0)
 686:	e810                	sd	a2,16(s0)
 688:	ec14                	sd	a3,24(s0)
 68a:	f018                	sd	a4,32(s0)
 68c:	f41c                	sd	a5,40(s0)
 68e:	03043823          	sd	a6,48(s0)
 692:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 696:	00840613          	addi	a2,s0,8
 69a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 69e:	85aa                	mv	a1,a0
 6a0:	4505                	li	a0,1
 6a2:	00000097          	auipc	ra,0x0
 6a6:	dce080e7          	jalr	-562(ra) # 470 <vprintf>
}
 6aa:	60e2                	ld	ra,24(sp)
 6ac:	6442                	ld	s0,16(sp)
 6ae:	6125                	addi	sp,sp,96
 6b0:	8082                	ret

00000000000006b2 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6b2:	1141                	addi	sp,sp,-16
 6b4:	e422                	sd	s0,8(sp)
 6b6:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6b8:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6bc:	00000797          	auipc	a5,0x0
 6c0:	1947b783          	ld	a5,404(a5) # 850 <freep>
 6c4:	a805                	j	6f4 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6c6:	4618                	lw	a4,8(a2)
 6c8:	9db9                	addw	a1,a1,a4
 6ca:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ce:	6398                	ld	a4,0(a5)
 6d0:	6318                	ld	a4,0(a4)
 6d2:	fee53823          	sd	a4,-16(a0)
 6d6:	a091                	j	71a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6d8:	ff852703          	lw	a4,-8(a0)
 6dc:	9e39                	addw	a2,a2,a4
 6de:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6e0:	ff053703          	ld	a4,-16(a0)
 6e4:	e398                	sd	a4,0(a5)
 6e6:	a099                	j	72c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e8:	6398                	ld	a4,0(a5)
 6ea:	00e7e463          	bltu	a5,a4,6f2 <free+0x40>
 6ee:	00e6ea63          	bltu	a3,a4,702 <free+0x50>
{
 6f2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f4:	fed7fae3          	bgeu	a5,a3,6e8 <free+0x36>
 6f8:	6398                	ld	a4,0(a5)
 6fa:	00e6e463          	bltu	a3,a4,702 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6fe:	fee7eae3          	bltu	a5,a4,6f2 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 702:	ff852583          	lw	a1,-8(a0)
 706:	6390                	ld	a2,0(a5)
 708:	02059813          	slli	a6,a1,0x20
 70c:	01c85713          	srli	a4,a6,0x1c
 710:	9736                	add	a4,a4,a3
 712:	fae60ae3          	beq	a2,a4,6c6 <free+0x14>
    bp->s.ptr = p->s.ptr;
 716:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 71a:	4790                	lw	a2,8(a5)
 71c:	02061593          	slli	a1,a2,0x20
 720:	01c5d713          	srli	a4,a1,0x1c
 724:	973e                	add	a4,a4,a5
 726:	fae689e3          	beq	a3,a4,6d8 <free+0x26>
  } else
    p->s.ptr = bp;
 72a:	e394                	sd	a3,0(a5)
  freep = p;
 72c:	00000717          	auipc	a4,0x0
 730:	12f73223          	sd	a5,292(a4) # 850 <freep>
}
 734:	6422                	ld	s0,8(sp)
 736:	0141                	addi	sp,sp,16
 738:	8082                	ret

000000000000073a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 73a:	7139                	addi	sp,sp,-64
 73c:	fc06                	sd	ra,56(sp)
 73e:	f822                	sd	s0,48(sp)
 740:	f426                	sd	s1,40(sp)
 742:	f04a                	sd	s2,32(sp)
 744:	ec4e                	sd	s3,24(sp)
 746:	e852                	sd	s4,16(sp)
 748:	e456                	sd	s5,8(sp)
 74a:	e05a                	sd	s6,0(sp)
 74c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 74e:	02051493          	slli	s1,a0,0x20
 752:	9081                	srli	s1,s1,0x20
 754:	04bd                	addi	s1,s1,15
 756:	8091                	srli	s1,s1,0x4
 758:	0014899b          	addiw	s3,s1,1
 75c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 75e:	00000517          	auipc	a0,0x0
 762:	0f253503          	ld	a0,242(a0) # 850 <freep>
 766:	c515                	beqz	a0,792 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 768:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 76a:	4798                	lw	a4,8(a5)
 76c:	02977f63          	bgeu	a4,s1,7aa <malloc+0x70>
 770:	8a4e                	mv	s4,s3
 772:	0009871b          	sext.w	a4,s3
 776:	6685                	lui	a3,0x1
 778:	00d77363          	bgeu	a4,a3,77e <malloc+0x44>
 77c:	6a05                	lui	s4,0x1
 77e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 782:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 786:	00000917          	auipc	s2,0x0
 78a:	0ca90913          	addi	s2,s2,202 # 850 <freep>
  if(p == (char*)-1)
 78e:	5afd                	li	s5,-1
 790:	a895                	j	804 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 792:	00000797          	auipc	a5,0x0
 796:	0c678793          	addi	a5,a5,198 # 858 <base>
 79a:	00000717          	auipc	a4,0x0
 79e:	0af73b23          	sd	a5,182(a4) # 850 <freep>
 7a2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7a4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7a8:	b7e1                	j	770 <malloc+0x36>
      if(p->s.size == nunits)
 7aa:	02e48c63          	beq	s1,a4,7e2 <malloc+0xa8>
        p->s.size -= nunits;
 7ae:	4137073b          	subw	a4,a4,s3
 7b2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7b4:	02071693          	slli	a3,a4,0x20
 7b8:	01c6d713          	srli	a4,a3,0x1c
 7bc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7be:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7c2:	00000717          	auipc	a4,0x0
 7c6:	08a73723          	sd	a0,142(a4) # 850 <freep>
      return (void*)(p + 1);
 7ca:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ce:	70e2                	ld	ra,56(sp)
 7d0:	7442                	ld	s0,48(sp)
 7d2:	74a2                	ld	s1,40(sp)
 7d4:	7902                	ld	s2,32(sp)
 7d6:	69e2                	ld	s3,24(sp)
 7d8:	6a42                	ld	s4,16(sp)
 7da:	6aa2                	ld	s5,8(sp)
 7dc:	6b02                	ld	s6,0(sp)
 7de:	6121                	addi	sp,sp,64
 7e0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7e2:	6398                	ld	a4,0(a5)
 7e4:	e118                	sd	a4,0(a0)
 7e6:	bff1                	j	7c2 <malloc+0x88>
  hp->s.size = nu;
 7e8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ec:	0541                	addi	a0,a0,16
 7ee:	00000097          	auipc	ra,0x0
 7f2:	ec4080e7          	jalr	-316(ra) # 6b2 <free>
  return freep;
 7f6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7fa:	d971                	beqz	a0,7ce <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7fc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7fe:	4798                	lw	a4,8(a5)
 800:	fa9775e3          	bgeu	a4,s1,7aa <malloc+0x70>
    if(p == freep)
 804:	00093703          	ld	a4,0(s2)
 808:	853e                	mv	a0,a5
 80a:	fef719e3          	bne	a4,a5,7fc <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 80e:	8552                	mv	a0,s4
 810:	00000097          	auipc	ra,0x0
 814:	b74080e7          	jalr	-1164(ra) # 384 <sbrk>
  if(p == (char*)-1)
 818:	fd5518e3          	bne	a0,s5,7e8 <malloc+0xae>
        return 0;
 81c:	4501                	li	a0,0
 81e:	bf45                	j	7ce <malloc+0x94>
