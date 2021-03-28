
user/test/_lstest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include<stdio.h>

int main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  printf ("Hello world\n");
   8:	00000517          	auipc	a0,0x0
   c:	7a850513          	addi	a0,a0,1960 # 7b0 <malloc+0xea>
  10:	00000097          	auipc	ra,0x0
  14:	5f8080e7          	jalr	1528(ra) # 608 <printf>
  return 0;
}
  18:	4501                	li	a0,0
  1a:	60a2                	ld	ra,8(sp)
  1c:	6402                	ld	s0,0(sp)
  1e:	0141                	addi	sp,sp,16
  20:	8082                	ret

0000000000000022 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  22:	1141                	addi	sp,sp,-16
  24:	e422                	sd	s0,8(sp)
  26:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  28:	87aa                	mv	a5,a0
  2a:	0585                	addi	a1,a1,1
  2c:	0785                	addi	a5,a5,1
  2e:	fff5c703          	lbu	a4,-1(a1)
  32:	fee78fa3          	sb	a4,-1(a5)
  36:	fb75                	bnez	a4,2a <strcpy+0x8>
    ;
  return os;
}
  38:	6422                	ld	s0,8(sp)
  3a:	0141                	addi	sp,sp,16
  3c:	8082                	ret

000000000000003e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  3e:	1141                	addi	sp,sp,-16
  40:	e422                	sd	s0,8(sp)
  42:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  44:	00054783          	lbu	a5,0(a0)
  48:	cb91                	beqz	a5,5c <strcmp+0x1e>
  4a:	0005c703          	lbu	a4,0(a1)
  4e:	00f71763          	bne	a4,a5,5c <strcmp+0x1e>
    p++, q++;
  52:	0505                	addi	a0,a0,1
  54:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  56:	00054783          	lbu	a5,0(a0)
  5a:	fbe5                	bnez	a5,4a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  5c:	0005c503          	lbu	a0,0(a1)
}
  60:	40a7853b          	subw	a0,a5,a0
  64:	6422                	ld	s0,8(sp)
  66:	0141                	addi	sp,sp,16
  68:	8082                	ret

000000000000006a <strlen>:

uint
strlen(const char *s)
{
  6a:	1141                	addi	sp,sp,-16
  6c:	e422                	sd	s0,8(sp)
  6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  70:	00054783          	lbu	a5,0(a0)
  74:	cf91                	beqz	a5,90 <strlen+0x26>
  76:	0505                	addi	a0,a0,1
  78:	87aa                	mv	a5,a0
  7a:	4685                	li	a3,1
  7c:	9e89                	subw	a3,a3,a0
  7e:	00f6853b          	addw	a0,a3,a5
  82:	0785                	addi	a5,a5,1
  84:	fff7c703          	lbu	a4,-1(a5)
  88:	fb7d                	bnez	a4,7e <strlen+0x14>
    ;
  return n;
}
  8a:	6422                	ld	s0,8(sp)
  8c:	0141                	addi	sp,sp,16
  8e:	8082                	ret
  for(n = 0; s[n]; n++)
  90:	4501                	li	a0,0
  92:	bfe5                	j	8a <strlen+0x20>

0000000000000094 <memset>:

void*
memset(void *dst, int c, uint n)
{
  94:	1141                	addi	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  9a:	ca19                	beqz	a2,b0 <memset+0x1c>
  9c:	87aa                	mv	a5,a0
  9e:	1602                	slli	a2,a2,0x20
  a0:	9201                	srli	a2,a2,0x20
  a2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  a6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  aa:	0785                	addi	a5,a5,1
  ac:	fee79de3          	bne	a5,a4,a6 <memset+0x12>
  }
  return dst;
}
  b0:	6422                	ld	s0,8(sp)
  b2:	0141                	addi	sp,sp,16
  b4:	8082                	ret

00000000000000b6 <strchr>:

char*
strchr(const char *s, char c)
{
  b6:	1141                	addi	sp,sp,-16
  b8:	e422                	sd	s0,8(sp)
  ba:	0800                	addi	s0,sp,16
  for(; *s; s++)
  bc:	00054783          	lbu	a5,0(a0)
  c0:	cb99                	beqz	a5,d6 <strchr+0x20>
    if(*s == c)
  c2:	00f58763          	beq	a1,a5,d0 <strchr+0x1a>
  for(; *s; s++)
  c6:	0505                	addi	a0,a0,1
  c8:	00054783          	lbu	a5,0(a0)
  cc:	fbfd                	bnez	a5,c2 <strchr+0xc>
      return (char*)s;
  return 0;
  ce:	4501                	li	a0,0
}
  d0:	6422                	ld	s0,8(sp)
  d2:	0141                	addi	sp,sp,16
  d4:	8082                	ret
  return 0;
  d6:	4501                	li	a0,0
  d8:	bfe5                	j	d0 <strchr+0x1a>

00000000000000da <gets>:

char*
gets(char *buf, int max)
{
  da:	711d                	addi	sp,sp,-96
  dc:	ec86                	sd	ra,88(sp)
  de:	e8a2                	sd	s0,80(sp)
  e0:	e4a6                	sd	s1,72(sp)
  e2:	e0ca                	sd	s2,64(sp)
  e4:	fc4e                	sd	s3,56(sp)
  e6:	f852                	sd	s4,48(sp)
  e8:	f456                	sd	s5,40(sp)
  ea:	f05a                	sd	s6,32(sp)
  ec:	ec5e                	sd	s7,24(sp)
  ee:	1080                	addi	s0,sp,96
  f0:	8baa                	mv	s7,a0
  f2:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
  f4:	892a                	mv	s2,a0
  f6:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
  f8:	4aa9                	li	s5,10
  fa:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
  fc:	89a6                	mv	s3,s1
  fe:	2485                	addiw	s1,s1,1
 100:	0344d863          	bge	s1,s4,130 <gets+0x56>
    cc = read(0, &c, 1);
 104:	4605                	li	a2,1
 106:	faf40593          	addi	a1,s0,-81
 10a:	4501                	li	a0,0
 10c:	00000097          	auipc	ra,0x0
 110:	19c080e7          	jalr	412(ra) # 2a8 <read>
    if(cc < 1)
 114:	00a05e63          	blez	a0,130 <gets+0x56>
    buf[i++] = c;
 118:	faf44783          	lbu	a5,-81(s0)
 11c:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 120:	01578763          	beq	a5,s5,12e <gets+0x54>
 124:	0905                	addi	s2,s2,1
 126:	fd679be3          	bne	a5,s6,fc <gets+0x22>
  for(i=0; i+1 < max; ){
 12a:	89a6                	mv	s3,s1
 12c:	a011                	j	130 <gets+0x56>
 12e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 130:	99de                	add	s3,s3,s7
 132:	00098023          	sb	zero,0(s3)
  return buf;
}
 136:	855e                	mv	a0,s7
 138:	60e6                	ld	ra,88(sp)
 13a:	6446                	ld	s0,80(sp)
 13c:	64a6                	ld	s1,72(sp)
 13e:	6906                	ld	s2,64(sp)
 140:	79e2                	ld	s3,56(sp)
 142:	7a42                	ld	s4,48(sp)
 144:	7aa2                	ld	s5,40(sp)
 146:	7b02                	ld	s6,32(sp)
 148:	6be2                	ld	s7,24(sp)
 14a:	6125                	addi	sp,sp,96
 14c:	8082                	ret

000000000000014e <stat>:

int
stat(const char *n, struct stat *st)
{
 14e:	1101                	addi	sp,sp,-32
 150:	ec06                	sd	ra,24(sp)
 152:	e822                	sd	s0,16(sp)
 154:	e426                	sd	s1,8(sp)
 156:	e04a                	sd	s2,0(sp)
 158:	1000                	addi	s0,sp,32
 15a:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 15c:	4581                	li	a1,0
 15e:	00000097          	auipc	ra,0x0
 162:	172080e7          	jalr	370(ra) # 2d0 <open>
  if(fd < 0)
 166:	02054563          	bltz	a0,190 <stat+0x42>
 16a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 16c:	85ca                	mv	a1,s2
 16e:	00000097          	auipc	ra,0x0
 172:	17a080e7          	jalr	378(ra) # 2e8 <fstat>
 176:	892a                	mv	s2,a0
  close(fd);
 178:	8526                	mv	a0,s1
 17a:	00000097          	auipc	ra,0x0
 17e:	13e080e7          	jalr	318(ra) # 2b8 <close>
  return r;
}
 182:	854a                	mv	a0,s2
 184:	60e2                	ld	ra,24(sp)
 186:	6442                	ld	s0,16(sp)
 188:	64a2                	ld	s1,8(sp)
 18a:	6902                	ld	s2,0(sp)
 18c:	6105                	addi	sp,sp,32
 18e:	8082                	ret
    return -1;
 190:	597d                	li	s2,-1
 192:	bfc5                	j	182 <stat+0x34>

0000000000000194 <atoi>:

int
atoi(const char *s)
{
 194:	1141                	addi	sp,sp,-16
 196:	e422                	sd	s0,8(sp)
 198:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 19a:	00054603          	lbu	a2,0(a0)
 19e:	fd06079b          	addiw	a5,a2,-48
 1a2:	0ff7f793          	andi	a5,a5,255
 1a6:	4725                	li	a4,9
 1a8:	02f76963          	bltu	a4,a5,1da <atoi+0x46>
 1ac:	86aa                	mv	a3,a0
  n = 0;
 1ae:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1b0:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1b2:	0685                	addi	a3,a3,1
 1b4:	0025179b          	slliw	a5,a0,0x2
 1b8:	9fa9                	addw	a5,a5,a0
 1ba:	0017979b          	slliw	a5,a5,0x1
 1be:	9fb1                	addw	a5,a5,a2
 1c0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1c4:	0006c603          	lbu	a2,0(a3)
 1c8:	fd06071b          	addiw	a4,a2,-48
 1cc:	0ff77713          	andi	a4,a4,255
 1d0:	fee5f1e3          	bgeu	a1,a4,1b2 <atoi+0x1e>
  return n;
}
 1d4:	6422                	ld	s0,8(sp)
 1d6:	0141                	addi	sp,sp,16
 1d8:	8082                	ret
  n = 0;
 1da:	4501                	li	a0,0
 1dc:	bfe5                	j	1d4 <atoi+0x40>

00000000000001de <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1de:	1141                	addi	sp,sp,-16
 1e0:	e422                	sd	s0,8(sp)
 1e2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1e4:	02b57463          	bgeu	a0,a1,20c <memmove+0x2e>
    while(n-- > 0)
 1e8:	00c05f63          	blez	a2,206 <memmove+0x28>
 1ec:	1602                	slli	a2,a2,0x20
 1ee:	9201                	srli	a2,a2,0x20
 1f0:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 1f4:	872a                	mv	a4,a0
      *dst++ = *src++;
 1f6:	0585                	addi	a1,a1,1
 1f8:	0705                	addi	a4,a4,1
 1fa:	fff5c683          	lbu	a3,-1(a1)
 1fe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 202:	fee79ae3          	bne	a5,a4,1f6 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 206:	6422                	ld	s0,8(sp)
 208:	0141                	addi	sp,sp,16
 20a:	8082                	ret
    dst += n;
 20c:	00c50733          	add	a4,a0,a2
    src += n;
 210:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 212:	fec05ae3          	blez	a2,206 <memmove+0x28>
 216:	fff6079b          	addiw	a5,a2,-1
 21a:	1782                	slli	a5,a5,0x20
 21c:	9381                	srli	a5,a5,0x20
 21e:	fff7c793          	not	a5,a5
 222:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 224:	15fd                	addi	a1,a1,-1
 226:	177d                	addi	a4,a4,-1
 228:	0005c683          	lbu	a3,0(a1)
 22c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 230:	fee79ae3          	bne	a5,a4,224 <memmove+0x46>
 234:	bfc9                	j	206 <memmove+0x28>

0000000000000236 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 236:	1141                	addi	sp,sp,-16
 238:	e422                	sd	s0,8(sp)
 23a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 23c:	ca05                	beqz	a2,26c <memcmp+0x36>
 23e:	fff6069b          	addiw	a3,a2,-1
 242:	1682                	slli	a3,a3,0x20
 244:	9281                	srli	a3,a3,0x20
 246:	0685                	addi	a3,a3,1
 248:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 24a:	00054783          	lbu	a5,0(a0)
 24e:	0005c703          	lbu	a4,0(a1)
 252:	00e79863          	bne	a5,a4,262 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 256:	0505                	addi	a0,a0,1
    p2++;
 258:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 25a:	fed518e3          	bne	a0,a3,24a <memcmp+0x14>
  }
  return 0;
 25e:	4501                	li	a0,0
 260:	a019                	j	266 <memcmp+0x30>
      return *p1 - *p2;
 262:	40e7853b          	subw	a0,a5,a4
}
 266:	6422                	ld	s0,8(sp)
 268:	0141                	addi	sp,sp,16
 26a:	8082                	ret
  return 0;
 26c:	4501                	li	a0,0
 26e:	bfe5                	j	266 <memcmp+0x30>

0000000000000270 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 270:	1141                	addi	sp,sp,-16
 272:	e406                	sd	ra,8(sp)
 274:	e022                	sd	s0,0(sp)
 276:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 278:	00000097          	auipc	ra,0x0
 27c:	f66080e7          	jalr	-154(ra) # 1de <memmove>
}
 280:	60a2                	ld	ra,8(sp)
 282:	6402                	ld	s0,0(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret

0000000000000288 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 288:	4885                	li	a7,1
 ecall
 28a:	00000073          	ecall
 ret
 28e:	8082                	ret

0000000000000290 <exit>:
.global exit
exit:
 li a7, SYS_exit
 290:	4889                	li	a7,2
 ecall
 292:	00000073          	ecall
 ret
 296:	8082                	ret

0000000000000298 <wait>:
.global wait
wait:
 li a7, SYS_wait
 298:	488d                	li	a7,3
 ecall
 29a:	00000073          	ecall
 ret
 29e:	8082                	ret

00000000000002a0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2a0:	4891                	li	a7,4
 ecall
 2a2:	00000073          	ecall
 ret
 2a6:	8082                	ret

00000000000002a8 <read>:
.global read
read:
 li a7, SYS_read
 2a8:	4895                	li	a7,5
 ecall
 2aa:	00000073          	ecall
 ret
 2ae:	8082                	ret

00000000000002b0 <write>:
.global write
write:
 li a7, SYS_write
 2b0:	48c1                	li	a7,16
 ecall
 2b2:	00000073          	ecall
 ret
 2b6:	8082                	ret

00000000000002b8 <close>:
.global close
close:
 li a7, SYS_close
 2b8:	48d5                	li	a7,21
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2c0:	4899                	li	a7,6
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2c8:	489d                	li	a7,7
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <open>:
.global open
open:
 li a7, SYS_open
 2d0:	48bd                	li	a7,15
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2d8:	48c5                	li	a7,17
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2e0:	48c9                	li	a7,18
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2e8:	48a1                	li	a7,8
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <link>:
.global link
link:
 li a7, SYS_link
 2f0:	48cd                	li	a7,19
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 2f8:	48d1                	li	a7,20
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 300:	48a5                	li	a7,9
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <dup>:
.global dup
dup:
 li a7, SYS_dup
 308:	48a9                	li	a7,10
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 310:	48ad                	li	a7,11
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 318:	48b1                	li	a7,12
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 320:	48b5                	li	a7,13
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 328:	48b9                	li	a7,14
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 330:	1101                	addi	sp,sp,-32
 332:	ec06                	sd	ra,24(sp)
 334:	e822                	sd	s0,16(sp)
 336:	1000                	addi	s0,sp,32
 338:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 33c:	4605                	li	a2,1
 33e:	fef40593          	addi	a1,s0,-17
 342:	00000097          	auipc	ra,0x0
 346:	f6e080e7          	jalr	-146(ra) # 2b0 <write>
}
 34a:	60e2                	ld	ra,24(sp)
 34c:	6442                	ld	s0,16(sp)
 34e:	6105                	addi	sp,sp,32
 350:	8082                	ret

0000000000000352 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 352:	7139                	addi	sp,sp,-64
 354:	fc06                	sd	ra,56(sp)
 356:	f822                	sd	s0,48(sp)
 358:	f426                	sd	s1,40(sp)
 35a:	f04a                	sd	s2,32(sp)
 35c:	ec4e                	sd	s3,24(sp)
 35e:	0080                	addi	s0,sp,64
 360:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 362:	c299                	beqz	a3,368 <printint+0x16>
 364:	0805c863          	bltz	a1,3f4 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 368:	2581                	sext.w	a1,a1
  neg = 0;
 36a:	4881                	li	a7,0
 36c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 370:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 372:	2601                	sext.w	a2,a2
 374:	00000517          	auipc	a0,0x0
 378:	45450513          	addi	a0,a0,1108 # 7c8 <digits>
 37c:	883a                	mv	a6,a4
 37e:	2705                	addiw	a4,a4,1
 380:	02c5f7bb          	remuw	a5,a1,a2
 384:	1782                	slli	a5,a5,0x20
 386:	9381                	srli	a5,a5,0x20
 388:	97aa                	add	a5,a5,a0
 38a:	0007c783          	lbu	a5,0(a5)
 38e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 392:	0005879b          	sext.w	a5,a1
 396:	02c5d5bb          	divuw	a1,a1,a2
 39a:	0685                	addi	a3,a3,1
 39c:	fec7f0e3          	bgeu	a5,a2,37c <printint+0x2a>
  if(neg)
 3a0:	00088b63          	beqz	a7,3b6 <printint+0x64>
    buf[i++] = '-';
 3a4:	fd040793          	addi	a5,s0,-48
 3a8:	973e                	add	a4,a4,a5
 3aa:	02d00793          	li	a5,45
 3ae:	fef70823          	sb	a5,-16(a4)
 3b2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3b6:	02e05863          	blez	a4,3e6 <printint+0x94>
 3ba:	fc040793          	addi	a5,s0,-64
 3be:	00e78933          	add	s2,a5,a4
 3c2:	fff78993          	addi	s3,a5,-1
 3c6:	99ba                	add	s3,s3,a4
 3c8:	377d                	addiw	a4,a4,-1
 3ca:	1702                	slli	a4,a4,0x20
 3cc:	9301                	srli	a4,a4,0x20
 3ce:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3d2:	fff94583          	lbu	a1,-1(s2)
 3d6:	8526                	mv	a0,s1
 3d8:	00000097          	auipc	ra,0x0
 3dc:	f58080e7          	jalr	-168(ra) # 330 <putc>
  while(--i >= 0)
 3e0:	197d                	addi	s2,s2,-1
 3e2:	ff3918e3          	bne	s2,s3,3d2 <printint+0x80>
}
 3e6:	70e2                	ld	ra,56(sp)
 3e8:	7442                	ld	s0,48(sp)
 3ea:	74a2                	ld	s1,40(sp)
 3ec:	7902                	ld	s2,32(sp)
 3ee:	69e2                	ld	s3,24(sp)
 3f0:	6121                	addi	sp,sp,64
 3f2:	8082                	ret
    x = -xx;
 3f4:	40b005bb          	negw	a1,a1
    neg = 1;
 3f8:	4885                	li	a7,1
    x = -xx;
 3fa:	bf8d                	j	36c <printint+0x1a>

00000000000003fc <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 3fc:	7119                	addi	sp,sp,-128
 3fe:	fc86                	sd	ra,120(sp)
 400:	f8a2                	sd	s0,112(sp)
 402:	f4a6                	sd	s1,104(sp)
 404:	f0ca                	sd	s2,96(sp)
 406:	ecce                	sd	s3,88(sp)
 408:	e8d2                	sd	s4,80(sp)
 40a:	e4d6                	sd	s5,72(sp)
 40c:	e0da                	sd	s6,64(sp)
 40e:	fc5e                	sd	s7,56(sp)
 410:	f862                	sd	s8,48(sp)
 412:	f466                	sd	s9,40(sp)
 414:	f06a                	sd	s10,32(sp)
 416:	ec6e                	sd	s11,24(sp)
 418:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 41a:	0005c903          	lbu	s2,0(a1)
 41e:	18090f63          	beqz	s2,5bc <vprintf+0x1c0>
 422:	8aaa                	mv	s5,a0
 424:	8b32                	mv	s6,a2
 426:	00158493          	addi	s1,a1,1
  state = 0;
 42a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 42c:	02500a13          	li	s4,37
      if(c == 'd'){
 430:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 434:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 438:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 43c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 440:	00000b97          	auipc	s7,0x0
 444:	388b8b93          	addi	s7,s7,904 # 7c8 <digits>
 448:	a839                	j	466 <vprintf+0x6a>
        putc(fd, c);
 44a:	85ca                	mv	a1,s2
 44c:	8556                	mv	a0,s5
 44e:	00000097          	auipc	ra,0x0
 452:	ee2080e7          	jalr	-286(ra) # 330 <putc>
 456:	a019                	j	45c <vprintf+0x60>
    } else if(state == '%'){
 458:	01498f63          	beq	s3,s4,476 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 45c:	0485                	addi	s1,s1,1
 45e:	fff4c903          	lbu	s2,-1(s1)
 462:	14090d63          	beqz	s2,5bc <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 466:	0009079b          	sext.w	a5,s2
    if(state == 0){
 46a:	fe0997e3          	bnez	s3,458 <vprintf+0x5c>
      if(c == '%'){
 46e:	fd479ee3          	bne	a5,s4,44a <vprintf+0x4e>
        state = '%';
 472:	89be                	mv	s3,a5
 474:	b7e5                	j	45c <vprintf+0x60>
      if(c == 'd'){
 476:	05878063          	beq	a5,s8,4b6 <vprintf+0xba>
      } else if(c == 'l') {
 47a:	05978c63          	beq	a5,s9,4d2 <vprintf+0xd6>
      } else if(c == 'x') {
 47e:	07a78863          	beq	a5,s10,4ee <vprintf+0xf2>
      } else if(c == 'p') {
 482:	09b78463          	beq	a5,s11,50a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 486:	07300713          	li	a4,115
 48a:	0ce78663          	beq	a5,a4,556 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 48e:	06300713          	li	a4,99
 492:	0ee78e63          	beq	a5,a4,58e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 496:	11478863          	beq	a5,s4,5a6 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 49a:	85d2                	mv	a1,s4
 49c:	8556                	mv	a0,s5
 49e:	00000097          	auipc	ra,0x0
 4a2:	e92080e7          	jalr	-366(ra) # 330 <putc>
        putc(fd, c);
 4a6:	85ca                	mv	a1,s2
 4a8:	8556                	mv	a0,s5
 4aa:	00000097          	auipc	ra,0x0
 4ae:	e86080e7          	jalr	-378(ra) # 330 <putc>
      }
      state = 0;
 4b2:	4981                	li	s3,0
 4b4:	b765                	j	45c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 4b6:	008b0913          	addi	s2,s6,8
 4ba:	4685                	li	a3,1
 4bc:	4629                	li	a2,10
 4be:	000b2583          	lw	a1,0(s6)
 4c2:	8556                	mv	a0,s5
 4c4:	00000097          	auipc	ra,0x0
 4c8:	e8e080e7          	jalr	-370(ra) # 352 <printint>
 4cc:	8b4a                	mv	s6,s2
      state = 0;
 4ce:	4981                	li	s3,0
 4d0:	b771                	j	45c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4d2:	008b0913          	addi	s2,s6,8
 4d6:	4681                	li	a3,0
 4d8:	4629                	li	a2,10
 4da:	000b2583          	lw	a1,0(s6)
 4de:	8556                	mv	a0,s5
 4e0:	00000097          	auipc	ra,0x0
 4e4:	e72080e7          	jalr	-398(ra) # 352 <printint>
 4e8:	8b4a                	mv	s6,s2
      state = 0;
 4ea:	4981                	li	s3,0
 4ec:	bf85                	j	45c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4ee:	008b0913          	addi	s2,s6,8
 4f2:	4681                	li	a3,0
 4f4:	4641                	li	a2,16
 4f6:	000b2583          	lw	a1,0(s6)
 4fa:	8556                	mv	a0,s5
 4fc:	00000097          	auipc	ra,0x0
 500:	e56080e7          	jalr	-426(ra) # 352 <printint>
 504:	8b4a                	mv	s6,s2
      state = 0;
 506:	4981                	li	s3,0
 508:	bf91                	j	45c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 50a:	008b0793          	addi	a5,s6,8
 50e:	f8f43423          	sd	a5,-120(s0)
 512:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 516:	03000593          	li	a1,48
 51a:	8556                	mv	a0,s5
 51c:	00000097          	auipc	ra,0x0
 520:	e14080e7          	jalr	-492(ra) # 330 <putc>
  putc(fd, 'x');
 524:	85ea                	mv	a1,s10
 526:	8556                	mv	a0,s5
 528:	00000097          	auipc	ra,0x0
 52c:	e08080e7          	jalr	-504(ra) # 330 <putc>
 530:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 532:	03c9d793          	srli	a5,s3,0x3c
 536:	97de                	add	a5,a5,s7
 538:	0007c583          	lbu	a1,0(a5)
 53c:	8556                	mv	a0,s5
 53e:	00000097          	auipc	ra,0x0
 542:	df2080e7          	jalr	-526(ra) # 330 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 546:	0992                	slli	s3,s3,0x4
 548:	397d                	addiw	s2,s2,-1
 54a:	fe0914e3          	bnez	s2,532 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 54e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 552:	4981                	li	s3,0
 554:	b721                	j	45c <vprintf+0x60>
        s = va_arg(ap, char*);
 556:	008b0993          	addi	s3,s6,8
 55a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 55e:	02090163          	beqz	s2,580 <vprintf+0x184>
        while(*s != 0){
 562:	00094583          	lbu	a1,0(s2)
 566:	c9a1                	beqz	a1,5b6 <vprintf+0x1ba>
          putc(fd, *s);
 568:	8556                	mv	a0,s5
 56a:	00000097          	auipc	ra,0x0
 56e:	dc6080e7          	jalr	-570(ra) # 330 <putc>
          s++;
 572:	0905                	addi	s2,s2,1
        while(*s != 0){
 574:	00094583          	lbu	a1,0(s2)
 578:	f9e5                	bnez	a1,568 <vprintf+0x16c>
        s = va_arg(ap, char*);
 57a:	8b4e                	mv	s6,s3
      state = 0;
 57c:	4981                	li	s3,0
 57e:	bdf9                	j	45c <vprintf+0x60>
          s = "(null)";
 580:	00000917          	auipc	s2,0x0
 584:	24090913          	addi	s2,s2,576 # 7c0 <malloc+0xfa>
        while(*s != 0){
 588:	02800593          	li	a1,40
 58c:	bff1                	j	568 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 58e:	008b0913          	addi	s2,s6,8
 592:	000b4583          	lbu	a1,0(s6)
 596:	8556                	mv	a0,s5
 598:	00000097          	auipc	ra,0x0
 59c:	d98080e7          	jalr	-616(ra) # 330 <putc>
 5a0:	8b4a                	mv	s6,s2
      state = 0;
 5a2:	4981                	li	s3,0
 5a4:	bd65                	j	45c <vprintf+0x60>
        putc(fd, c);
 5a6:	85d2                	mv	a1,s4
 5a8:	8556                	mv	a0,s5
 5aa:	00000097          	auipc	ra,0x0
 5ae:	d86080e7          	jalr	-634(ra) # 330 <putc>
      state = 0;
 5b2:	4981                	li	s3,0
 5b4:	b565                	j	45c <vprintf+0x60>
        s = va_arg(ap, char*);
 5b6:	8b4e                	mv	s6,s3
      state = 0;
 5b8:	4981                	li	s3,0
 5ba:	b54d                	j	45c <vprintf+0x60>
    }
  }
}
 5bc:	70e6                	ld	ra,120(sp)
 5be:	7446                	ld	s0,112(sp)
 5c0:	74a6                	ld	s1,104(sp)
 5c2:	7906                	ld	s2,96(sp)
 5c4:	69e6                	ld	s3,88(sp)
 5c6:	6a46                	ld	s4,80(sp)
 5c8:	6aa6                	ld	s5,72(sp)
 5ca:	6b06                	ld	s6,64(sp)
 5cc:	7be2                	ld	s7,56(sp)
 5ce:	7c42                	ld	s8,48(sp)
 5d0:	7ca2                	ld	s9,40(sp)
 5d2:	7d02                	ld	s10,32(sp)
 5d4:	6de2                	ld	s11,24(sp)
 5d6:	6109                	addi	sp,sp,128
 5d8:	8082                	ret

00000000000005da <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5da:	715d                	addi	sp,sp,-80
 5dc:	ec06                	sd	ra,24(sp)
 5de:	e822                	sd	s0,16(sp)
 5e0:	1000                	addi	s0,sp,32
 5e2:	e010                	sd	a2,0(s0)
 5e4:	e414                	sd	a3,8(s0)
 5e6:	e818                	sd	a4,16(s0)
 5e8:	ec1c                	sd	a5,24(s0)
 5ea:	03043023          	sd	a6,32(s0)
 5ee:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 5f2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 5f6:	8622                	mv	a2,s0
 5f8:	00000097          	auipc	ra,0x0
 5fc:	e04080e7          	jalr	-508(ra) # 3fc <vprintf>
}
 600:	60e2                	ld	ra,24(sp)
 602:	6442                	ld	s0,16(sp)
 604:	6161                	addi	sp,sp,80
 606:	8082                	ret

0000000000000608 <printf>:

void
printf(const char *fmt, ...)
{
 608:	711d                	addi	sp,sp,-96
 60a:	ec06                	sd	ra,24(sp)
 60c:	e822                	sd	s0,16(sp)
 60e:	1000                	addi	s0,sp,32
 610:	e40c                	sd	a1,8(s0)
 612:	e810                	sd	a2,16(s0)
 614:	ec14                	sd	a3,24(s0)
 616:	f018                	sd	a4,32(s0)
 618:	f41c                	sd	a5,40(s0)
 61a:	03043823          	sd	a6,48(s0)
 61e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 622:	00840613          	addi	a2,s0,8
 626:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 62a:	85aa                	mv	a1,a0
 62c:	4505                	li	a0,1
 62e:	00000097          	auipc	ra,0x0
 632:	dce080e7          	jalr	-562(ra) # 3fc <vprintf>
}
 636:	60e2                	ld	ra,24(sp)
 638:	6442                	ld	s0,16(sp)
 63a:	6125                	addi	sp,sp,96
 63c:	8082                	ret

000000000000063e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 63e:	1141                	addi	sp,sp,-16
 640:	e422                	sd	s0,8(sp)
 642:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 644:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 648:	00000797          	auipc	a5,0x0
 64c:	1987b783          	ld	a5,408(a5) # 7e0 <freep>
 650:	a805                	j	680 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 652:	4618                	lw	a4,8(a2)
 654:	9db9                	addw	a1,a1,a4
 656:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 65a:	6398                	ld	a4,0(a5)
 65c:	6318                	ld	a4,0(a4)
 65e:	fee53823          	sd	a4,-16(a0)
 662:	a091                	j	6a6 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 664:	ff852703          	lw	a4,-8(a0)
 668:	9e39                	addw	a2,a2,a4
 66a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 66c:	ff053703          	ld	a4,-16(a0)
 670:	e398                	sd	a4,0(a5)
 672:	a099                	j	6b8 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 674:	6398                	ld	a4,0(a5)
 676:	00e7e463          	bltu	a5,a4,67e <free+0x40>
 67a:	00e6ea63          	bltu	a3,a4,68e <free+0x50>
{
 67e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 680:	fed7fae3          	bgeu	a5,a3,674 <free+0x36>
 684:	6398                	ld	a4,0(a5)
 686:	00e6e463          	bltu	a3,a4,68e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 68a:	fee7eae3          	bltu	a5,a4,67e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 68e:	ff852583          	lw	a1,-8(a0)
 692:	6390                	ld	a2,0(a5)
 694:	02059813          	slli	a6,a1,0x20
 698:	01c85713          	srli	a4,a6,0x1c
 69c:	9736                	add	a4,a4,a3
 69e:	fae60ae3          	beq	a2,a4,652 <free+0x14>
    bp->s.ptr = p->s.ptr;
 6a2:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6a6:	4790                	lw	a2,8(a5)
 6a8:	02061593          	slli	a1,a2,0x20
 6ac:	01c5d713          	srli	a4,a1,0x1c
 6b0:	973e                	add	a4,a4,a5
 6b2:	fae689e3          	beq	a3,a4,664 <free+0x26>
  } else
    p->s.ptr = bp;
 6b6:	e394                	sd	a3,0(a5)
  freep = p;
 6b8:	00000717          	auipc	a4,0x0
 6bc:	12f73423          	sd	a5,296(a4) # 7e0 <freep>
}
 6c0:	6422                	ld	s0,8(sp)
 6c2:	0141                	addi	sp,sp,16
 6c4:	8082                	ret

00000000000006c6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6c6:	7139                	addi	sp,sp,-64
 6c8:	fc06                	sd	ra,56(sp)
 6ca:	f822                	sd	s0,48(sp)
 6cc:	f426                	sd	s1,40(sp)
 6ce:	f04a                	sd	s2,32(sp)
 6d0:	ec4e                	sd	s3,24(sp)
 6d2:	e852                	sd	s4,16(sp)
 6d4:	e456                	sd	s5,8(sp)
 6d6:	e05a                	sd	s6,0(sp)
 6d8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6da:	02051493          	slli	s1,a0,0x20
 6de:	9081                	srli	s1,s1,0x20
 6e0:	04bd                	addi	s1,s1,15
 6e2:	8091                	srli	s1,s1,0x4
 6e4:	0014899b          	addiw	s3,s1,1
 6e8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 6ea:	00000517          	auipc	a0,0x0
 6ee:	0f653503          	ld	a0,246(a0) # 7e0 <freep>
 6f2:	c515                	beqz	a0,71e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6f4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 6f6:	4798                	lw	a4,8(a5)
 6f8:	02977f63          	bgeu	a4,s1,736 <malloc+0x70>
 6fc:	8a4e                	mv	s4,s3
 6fe:	0009871b          	sext.w	a4,s3
 702:	6685                	lui	a3,0x1
 704:	00d77363          	bgeu	a4,a3,70a <malloc+0x44>
 708:	6a05                	lui	s4,0x1
 70a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 70e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 712:	00000917          	auipc	s2,0x0
 716:	0ce90913          	addi	s2,s2,206 # 7e0 <freep>
  if(p == (char*)-1)
 71a:	5afd                	li	s5,-1
 71c:	a895                	j	790 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 71e:	00000797          	auipc	a5,0x0
 722:	0ca78793          	addi	a5,a5,202 # 7e8 <base>
 726:	00000717          	auipc	a4,0x0
 72a:	0af73d23          	sd	a5,186(a4) # 7e0 <freep>
 72e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 730:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 734:	b7e1                	j	6fc <malloc+0x36>
      if(p->s.size == nunits)
 736:	02e48c63          	beq	s1,a4,76e <malloc+0xa8>
        p->s.size -= nunits;
 73a:	4137073b          	subw	a4,a4,s3
 73e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 740:	02071693          	slli	a3,a4,0x20
 744:	01c6d713          	srli	a4,a3,0x1c
 748:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 74a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 74e:	00000717          	auipc	a4,0x0
 752:	08a73923          	sd	a0,146(a4) # 7e0 <freep>
      return (void*)(p + 1);
 756:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 75a:	70e2                	ld	ra,56(sp)
 75c:	7442                	ld	s0,48(sp)
 75e:	74a2                	ld	s1,40(sp)
 760:	7902                	ld	s2,32(sp)
 762:	69e2                	ld	s3,24(sp)
 764:	6a42                	ld	s4,16(sp)
 766:	6aa2                	ld	s5,8(sp)
 768:	6b02                	ld	s6,0(sp)
 76a:	6121                	addi	sp,sp,64
 76c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 76e:	6398                	ld	a4,0(a5)
 770:	e118                	sd	a4,0(a0)
 772:	bff1                	j	74e <malloc+0x88>
  hp->s.size = nu;
 774:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 778:	0541                	addi	a0,a0,16
 77a:	00000097          	auipc	ra,0x0
 77e:	ec4080e7          	jalr	-316(ra) # 63e <free>
  return freep;
 782:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 786:	d971                	beqz	a0,75a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 788:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 78a:	4798                	lw	a4,8(a5)
 78c:	fa9775e3          	bgeu	a4,s1,736 <malloc+0x70>
    if(p == freep)
 790:	00093703          	ld	a4,0(s2)
 794:	853e                	mv	a0,a5
 796:	fef719e3          	bne	a4,a5,788 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 79a:	8552                	mv	a0,s4
 79c:	00000097          	auipc	ra,0x0
 7a0:	b7c080e7          	jalr	-1156(ra) # 318 <sbrk>
  if(p == (char*)-1)
 7a4:	fd5518e3          	bne	a0,s5,774 <malloc+0xae>
        return 0;
 7a8:	4501                	li	a0,0
 7aa:	bf45                	j	75a <malloc+0x94>
