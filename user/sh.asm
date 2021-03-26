
user/_sh:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <getcmd>:
  exit(0);
}

int
getcmd(char *buf, int nbuf)
{
       0:	1101                	addi	sp,sp,-32
       2:	ec06                	sd	ra,24(sp)
       4:	e822                	sd	s0,16(sp)
       6:	e426                	sd	s1,8(sp)
       8:	e04a                	sd	s2,0(sp)
       a:	1000                	addi	s0,sp,32
       c:	84aa                	mv	s1,a0
       e:	892e                	mv	s2,a1
  fprintf(2, "$ ");
      10:	00001597          	auipc	a1,0x1
      14:	3a058593          	addi	a1,a1,928 # 13b0 <malloc+0xe8>
      18:	4509                	li	a0,2
      1a:	00001097          	auipc	ra,0x1
      1e:	1c2080e7          	jalr	450(ra) # 11dc <fprintf>
  memset(buf, 0, nbuf);
      22:	864a                	mv	a2,s2
      24:	4581                	li	a1,0
      26:	8526                	mv	a0,s1
      28:	00001097          	auipc	ra,0x1
      2c:	c6e080e7          	jalr	-914(ra) # c96 <memset>
  gets(buf, nbuf);
      30:	85ca                	mv	a1,s2
      32:	8526                	mv	a0,s1
      34:	00001097          	auipc	ra,0x1
      38:	ca8080e7          	jalr	-856(ra) # cdc <gets>
  if(buf[0] == 0) // EOF
      3c:	0004c503          	lbu	a0,0(s1)
      40:	00153513          	seqz	a0,a0
    return -1;
  return 0;
}
      44:	40a00533          	neg	a0,a0
      48:	60e2                	ld	ra,24(sp)
      4a:	6442                	ld	s0,16(sp)
      4c:	64a2                	ld	s1,8(sp)
      4e:	6902                	ld	s2,0(sp)
      50:	6105                	addi	sp,sp,32
      52:	8082                	ret

0000000000000054 <panic>:
  exit(0);
}

void
panic(char *s)
{
      54:	1141                	addi	sp,sp,-16
      56:	e406                	sd	ra,8(sp)
      58:	e022                	sd	s0,0(sp)
      5a:	0800                	addi	s0,sp,16
      5c:	862a                	mv	a2,a0
  fprintf(2, "%s\n", s);
      5e:	00001597          	auipc	a1,0x1
      62:	35a58593          	addi	a1,a1,858 # 13b8 <malloc+0xf0>
      66:	4509                	li	a0,2
      68:	00001097          	auipc	ra,0x1
      6c:	174080e7          	jalr	372(ra) # 11dc <fprintf>
  exit(1);
      70:	4505                	li	a0,1
      72:	00001097          	auipc	ra,0x1
      76:	e20080e7          	jalr	-480(ra) # e92 <exit>

000000000000007a <fork1>:
}

int
fork1(void)
{
      7a:	1141                	addi	sp,sp,-16
      7c:	e406                	sd	ra,8(sp)
      7e:	e022                	sd	s0,0(sp)
      80:	0800                	addi	s0,sp,16
  int pid;

  pid = fork();
      82:	00001097          	auipc	ra,0x1
      86:	e08080e7          	jalr	-504(ra) # e8a <fork>
  if(pid == -1)
      8a:	57fd                	li	a5,-1
      8c:	00f50663          	beq	a0,a5,98 <fork1+0x1e>
    panic("fork");
  return pid;
}
      90:	60a2                	ld	ra,8(sp)
      92:	6402                	ld	s0,0(sp)
      94:	0141                	addi	sp,sp,16
      96:	8082                	ret
    panic("fork");
      98:	00001517          	auipc	a0,0x1
      9c:	32850513          	addi	a0,a0,808 # 13c0 <malloc+0xf8>
      a0:	00000097          	auipc	ra,0x0
      a4:	fb4080e7          	jalr	-76(ra) # 54 <panic>

00000000000000a8 <runcmd>:
{
      a8:	7155                	addi	sp,sp,-208
      aa:	e586                	sd	ra,200(sp)
      ac:	e1a2                	sd	s0,192(sp)
      ae:	fd26                	sd	s1,184(sp)
      b0:	f94a                	sd	s2,176(sp)
      b2:	f54e                	sd	s3,168(sp)
      b4:	f152                	sd	s4,160(sp)
      b6:	ed56                	sd	s5,152(sp)
      b8:	e95a                	sd	s6,144(sp)
      ba:	e55e                	sd	s7,136(sp)
      bc:	0980                	addi	s0,sp,208
  if(cmd == 0)
      be:	c10d                	beqz	a0,e0 <runcmd+0x38>
      c0:	84aa                	mv	s1,a0
  switch(cmd->type){
      c2:	4118                	lw	a4,0(a0)
      c4:	4795                	li	a5,5
      c6:	02e7e263          	bltu	a5,a4,ea <runcmd+0x42>
      ca:	00056783          	lwu	a5,0(a0)
      ce:	078a                	slli	a5,a5,0x2
      d0:	00001717          	auipc	a4,0x1
      d4:	40870713          	addi	a4,a4,1032 # 14d8 <malloc+0x210>
      d8:	97ba                	add	a5,a5,a4
      da:	439c                	lw	a5,0(a5)
      dc:	97ba                	add	a5,a5,a4
      de:	8782                	jr	a5
    exit(1);
      e0:	4505                	li	a0,1
      e2:	00001097          	auipc	ra,0x1
      e6:	db0080e7          	jalr	-592(ra) # e92 <exit>
    panic("runcmd");
      ea:	00001517          	auipc	a0,0x1
      ee:	2de50513          	addi	a0,a0,734 # 13c8 <malloc+0x100>
      f2:	00000097          	auipc	ra,0x0
      f6:	f62080e7          	jalr	-158(ra) # 54 <panic>
    if(ecmd->argv[0] == 0)
      fa:	6510                	ld	a2,8(a0)
      fc:	c631                	beqz	a2,148 <runcmd+0xa0>
    fprintf(2, "Trying exec %s\n", ecmd->argv[0]);
      fe:	00001597          	auipc	a1,0x1
     102:	2d258593          	addi	a1,a1,722 # 13d0 <malloc+0x108>
     106:	4509                	li	a0,2
     108:	00001097          	auipc	ra,0x1
     10c:	0d4080e7          	jalr	212(ra) # 11dc <fprintf>
    exec(ecmd->argv[0], ecmd->argv);
     110:	00848a93          	addi	s5,s1,8
     114:	85d6                	mv	a1,s5
     116:	6488                	ld	a0,8(s1)
     118:	00001097          	auipc	ra,0x1
     11c:	db2080e7          	jalr	-590(ra) # eca <exec>
    int fd = open("/path", O_CREATE | O_RDONLY);
     120:	20000593          	li	a1,512
     124:	00001517          	auipc	a0,0x1
     128:	2bc50513          	addi	a0,a0,700 # 13e0 <malloc+0x118>
     12c:	00001097          	auipc	ra,0x1
     130:	da6080e7          	jalr	-602(ra) # ed2 <open>
     134:	89aa                	mv	s3,a0
    int i = 0;
     136:	4901                	li	s2,0
      if(*reader != ':'){
     138:	03a00a13          	li	s4,58
        fprintf(2, "Trying exec %s\n", newPath);
     13c:	00001b97          	auipc	s7,0x1
     140:	294b8b93          	addi	s7,s7,660 # 13d0 <malloc+0x108>
        i=0;
     144:	4b01                	li	s6,0
    while (read (fd, reader, 1) != 0){
     146:	a085                	j	1a6 <runcmd+0xfe>
      exit(1);
     148:	4505                	li	a0,1
     14a:	00001097          	auipc	ra,0x1
     14e:	d48080e7          	jalr	-696(ra) # e92 <exit>
        char* tmpexec = ecmd->argv[0];
     152:	648c                	ld	a1,8(s1)
        while (*tmpexec!= '\0'){
     154:	0005c703          	lbu	a4,0(a1)
     158:	c315                	beqz	a4,17c <runcmd+0xd4>
     15a:	f4040793          	addi	a5,s0,-192
     15e:	01278633          	add	a2,a5,s2
        char* tmpexec = ecmd->argv[0];
     162:	87ae                	mv	a5,a1
          newPath[i]=*tmpexec;
     164:	00e60023          	sb	a4,0(a2)
          tmpexec++;
     168:	0785                	addi	a5,a5,1
          i++;
     16a:	40b7873b          	subw	a4,a5,a1
     16e:	012706bb          	addw	a3,a4,s2
        while (*tmpexec!= '\0'){
     172:	0007c703          	lbu	a4,0(a5)
     176:	0605                	addi	a2,a2,1
     178:	f775                	bnez	a4,164 <runcmd+0xbc>
          i++;
     17a:	8936                	mv	s2,a3
        newPath[i]='\0';
     17c:	fb040793          	addi	a5,s0,-80
     180:	993e                	add	s2,s2,a5
     182:	f8090823          	sb	zero,-112(s2)
        fprintf(2, "Trying exec %s\n", newPath);
     186:	f4040613          	addi	a2,s0,-192
     18a:	85de                	mv	a1,s7
     18c:	4509                	li	a0,2
     18e:	00001097          	auipc	ra,0x1
     192:	04e080e7          	jalr	78(ra) # 11dc <fprintf>
        exec(newPath, ecmd->argv);
     196:	85d6                	mv	a1,s5
     198:	f4040513          	addi	a0,s0,-192
     19c:	00001097          	auipc	ra,0x1
     1a0:	d2e080e7          	jalr	-722(ra) # eca <exec>
        i=0;
     1a4:	895a                	mv	s2,s6
    while (read (fd, reader, 1) != 0){
     1a6:	4605                	li	a2,1
     1a8:	f3840593          	addi	a1,s0,-200
     1ac:	854e                	mv	a0,s3
     1ae:	00001097          	auipc	ra,0x1
     1b2:	cfc080e7          	jalr	-772(ra) # eaa <read>
     1b6:	cd01                	beqz	a0,1ce <runcmd+0x126>
      if(*reader != ':'){
     1b8:	f3844783          	lbu	a5,-200(s0)
     1bc:	f9478be3          	beq	a5,s4,152 <runcmd+0xaa>
        newPath[i] = *reader;
     1c0:	fb040713          	addi	a4,s0,-80
     1c4:	974a                	add	a4,a4,s2
     1c6:	f8f70823          	sb	a5,-112(a4)
        i++;
     1ca:	2905                	addiw	s2,s2,1
     1cc:	bfe9                	j	1a6 <runcmd+0xfe>
    fprintf(2, "exec %s failed\n", ecmd->argv[0]);
     1ce:	6490                	ld	a2,8(s1)
     1d0:	00001597          	auipc	a1,0x1
     1d4:	21858593          	addi	a1,a1,536 # 13e8 <malloc+0x120>
     1d8:	4509                	li	a0,2
     1da:	00001097          	auipc	ra,0x1
     1de:	002080e7          	jalr	2(ra) # 11dc <fprintf>
    close (fd);
     1e2:	854e                	mv	a0,s3
     1e4:	00001097          	auipc	ra,0x1
     1e8:	cd6080e7          	jalr	-810(ra) # eba <close>
  exit(0);
     1ec:	4501                	li	a0,0
     1ee:	00001097          	auipc	ra,0x1
     1f2:	ca4080e7          	jalr	-860(ra) # e92 <exit>
    close(rcmd->fd);
     1f6:	5148                	lw	a0,36(a0)
     1f8:	00001097          	auipc	ra,0x1
     1fc:	cc2080e7          	jalr	-830(ra) # eba <close>
    if(open(rcmd->file, rcmd->mode) < 0){
     200:	508c                	lw	a1,32(s1)
     202:	6888                	ld	a0,16(s1)
     204:	00001097          	auipc	ra,0x1
     208:	cce080e7          	jalr	-818(ra) # ed2 <open>
     20c:	00054763          	bltz	a0,21a <runcmd+0x172>
    runcmd(rcmd->cmd);
     210:	6488                	ld	a0,8(s1)
     212:	00000097          	auipc	ra,0x0
     216:	e96080e7          	jalr	-362(ra) # a8 <runcmd>
      fprintf(2, "open %s failed\n", rcmd->file);
     21a:	6890                	ld	a2,16(s1)
     21c:	00001597          	auipc	a1,0x1
     220:	1dc58593          	addi	a1,a1,476 # 13f8 <malloc+0x130>
     224:	4509                	li	a0,2
     226:	00001097          	auipc	ra,0x1
     22a:	fb6080e7          	jalr	-74(ra) # 11dc <fprintf>
      exit(1);
     22e:	4505                	li	a0,1
     230:	00001097          	auipc	ra,0x1
     234:	c62080e7          	jalr	-926(ra) # e92 <exit>
    if(fork1() == 0)
     238:	00000097          	auipc	ra,0x0
     23c:	e42080e7          	jalr	-446(ra) # 7a <fork1>
     240:	c919                	beqz	a0,256 <runcmd+0x1ae>
    wait(0);
     242:	4501                	li	a0,0
     244:	00001097          	auipc	ra,0x1
     248:	c56080e7          	jalr	-938(ra) # e9a <wait>
    runcmd(lcmd->right);
     24c:	6888                	ld	a0,16(s1)
     24e:	00000097          	auipc	ra,0x0
     252:	e5a080e7          	jalr	-422(ra) # a8 <runcmd>
      runcmd(lcmd->left);
     256:	6488                	ld	a0,8(s1)
     258:	00000097          	auipc	ra,0x0
     25c:	e50080e7          	jalr	-432(ra) # a8 <runcmd>
    if(pipe(p) < 0)
     260:	fa840513          	addi	a0,s0,-88
     264:	00001097          	auipc	ra,0x1
     268:	c3e080e7          	jalr	-962(ra) # ea2 <pipe>
     26c:	04054363          	bltz	a0,2b2 <runcmd+0x20a>
    if(fork1() == 0){
     270:	00000097          	auipc	ra,0x0
     274:	e0a080e7          	jalr	-502(ra) # 7a <fork1>
     278:	c529                	beqz	a0,2c2 <runcmd+0x21a>
    if(fork1() == 0){
     27a:	00000097          	auipc	ra,0x0
     27e:	e00080e7          	jalr	-512(ra) # 7a <fork1>
     282:	cd25                	beqz	a0,2fa <runcmd+0x252>
    close(p[0]);
     284:	fa842503          	lw	a0,-88(s0)
     288:	00001097          	auipc	ra,0x1
     28c:	c32080e7          	jalr	-974(ra) # eba <close>
    close(p[1]);
     290:	fac42503          	lw	a0,-84(s0)
     294:	00001097          	auipc	ra,0x1
     298:	c26080e7          	jalr	-986(ra) # eba <close>
    wait(0);
     29c:	4501                	li	a0,0
     29e:	00001097          	auipc	ra,0x1
     2a2:	bfc080e7          	jalr	-1028(ra) # e9a <wait>
    wait(0);
     2a6:	4501                	li	a0,0
     2a8:	00001097          	auipc	ra,0x1
     2ac:	bf2080e7          	jalr	-1038(ra) # e9a <wait>
    break;
     2b0:	bf35                	j	1ec <runcmd+0x144>
      panic("pipe");
     2b2:	00001517          	auipc	a0,0x1
     2b6:	15650513          	addi	a0,a0,342 # 1408 <malloc+0x140>
     2ba:	00000097          	auipc	ra,0x0
     2be:	d9a080e7          	jalr	-614(ra) # 54 <panic>
      close(1);
     2c2:	4505                	li	a0,1
     2c4:	00001097          	auipc	ra,0x1
     2c8:	bf6080e7          	jalr	-1034(ra) # eba <close>
      dup(p[1]);
     2cc:	fac42503          	lw	a0,-84(s0)
     2d0:	00001097          	auipc	ra,0x1
     2d4:	c3a080e7          	jalr	-966(ra) # f0a <dup>
      close(p[0]);
     2d8:	fa842503          	lw	a0,-88(s0)
     2dc:	00001097          	auipc	ra,0x1
     2e0:	bde080e7          	jalr	-1058(ra) # eba <close>
      close(p[1]);
     2e4:	fac42503          	lw	a0,-84(s0)
     2e8:	00001097          	auipc	ra,0x1
     2ec:	bd2080e7          	jalr	-1070(ra) # eba <close>
      runcmd(pcmd->left);
     2f0:	6488                	ld	a0,8(s1)
     2f2:	00000097          	auipc	ra,0x0
     2f6:	db6080e7          	jalr	-586(ra) # a8 <runcmd>
      close(0);
     2fa:	00001097          	auipc	ra,0x1
     2fe:	bc0080e7          	jalr	-1088(ra) # eba <close>
      dup(p[0]);
     302:	fa842503          	lw	a0,-88(s0)
     306:	00001097          	auipc	ra,0x1
     30a:	c04080e7          	jalr	-1020(ra) # f0a <dup>
      close(p[0]);
     30e:	fa842503          	lw	a0,-88(s0)
     312:	00001097          	auipc	ra,0x1
     316:	ba8080e7          	jalr	-1112(ra) # eba <close>
      close(p[1]);
     31a:	fac42503          	lw	a0,-84(s0)
     31e:	00001097          	auipc	ra,0x1
     322:	b9c080e7          	jalr	-1124(ra) # eba <close>
      runcmd(pcmd->right);
     326:	6888                	ld	a0,16(s1)
     328:	00000097          	auipc	ra,0x0
     32c:	d80080e7          	jalr	-640(ra) # a8 <runcmd>
    if(fork1() == 0)
     330:	00000097          	auipc	ra,0x0
     334:	d4a080e7          	jalr	-694(ra) # 7a <fork1>
     338:	ea051ae3          	bnez	a0,1ec <runcmd+0x144>
      runcmd(bcmd->cmd);
     33c:	6488                	ld	a0,8(s1)
     33e:	00000097          	auipc	ra,0x0
     342:	d6a080e7          	jalr	-662(ra) # a8 <runcmd>

0000000000000346 <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd*
execcmd(void)
{
     346:	1101                	addi	sp,sp,-32
     348:	ec06                	sd	ra,24(sp)
     34a:	e822                	sd	s0,16(sp)
     34c:	e426                	sd	s1,8(sp)
     34e:	1000                	addi	s0,sp,32
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     350:	0a800513          	li	a0,168
     354:	00001097          	auipc	ra,0x1
     358:	f74080e7          	jalr	-140(ra) # 12c8 <malloc>
     35c:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     35e:	0a800613          	li	a2,168
     362:	4581                	li	a1,0
     364:	00001097          	auipc	ra,0x1
     368:	932080e7          	jalr	-1742(ra) # c96 <memset>
  cmd->type = EXEC;
     36c:	4785                	li	a5,1
     36e:	c09c                	sw	a5,0(s1)
  return (struct cmd*)cmd;
}
     370:	8526                	mv	a0,s1
     372:	60e2                	ld	ra,24(sp)
     374:	6442                	ld	s0,16(sp)
     376:	64a2                	ld	s1,8(sp)
     378:	6105                	addi	sp,sp,32
     37a:	8082                	ret

000000000000037c <redircmd>:

struct cmd*
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     37c:	7139                	addi	sp,sp,-64
     37e:	fc06                	sd	ra,56(sp)
     380:	f822                	sd	s0,48(sp)
     382:	f426                	sd	s1,40(sp)
     384:	f04a                	sd	s2,32(sp)
     386:	ec4e                	sd	s3,24(sp)
     388:	e852                	sd	s4,16(sp)
     38a:	e456                	sd	s5,8(sp)
     38c:	e05a                	sd	s6,0(sp)
     38e:	0080                	addi	s0,sp,64
     390:	8b2a                	mv	s6,a0
     392:	8aae                	mv	s5,a1
     394:	8a32                	mv	s4,a2
     396:	89b6                	mv	s3,a3
     398:	893a                	mv	s2,a4
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
     39a:	02800513          	li	a0,40
     39e:	00001097          	auipc	ra,0x1
     3a2:	f2a080e7          	jalr	-214(ra) # 12c8 <malloc>
     3a6:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     3a8:	02800613          	li	a2,40
     3ac:	4581                	li	a1,0
     3ae:	00001097          	auipc	ra,0x1
     3b2:	8e8080e7          	jalr	-1816(ra) # c96 <memset>
  cmd->type = REDIR;
     3b6:	4789                	li	a5,2
     3b8:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     3ba:	0164b423          	sd	s6,8(s1)
  cmd->file = file;
     3be:	0154b823          	sd	s5,16(s1)
  cmd->efile = efile;
     3c2:	0144bc23          	sd	s4,24(s1)
  cmd->mode = mode;
     3c6:	0334a023          	sw	s3,32(s1)
  cmd->fd = fd;
     3ca:	0324a223          	sw	s2,36(s1)
  return (struct cmd*)cmd;
}
     3ce:	8526                	mv	a0,s1
     3d0:	70e2                	ld	ra,56(sp)
     3d2:	7442                	ld	s0,48(sp)
     3d4:	74a2                	ld	s1,40(sp)
     3d6:	7902                	ld	s2,32(sp)
     3d8:	69e2                	ld	s3,24(sp)
     3da:	6a42                	ld	s4,16(sp)
     3dc:	6aa2                	ld	s5,8(sp)
     3de:	6b02                	ld	s6,0(sp)
     3e0:	6121                	addi	sp,sp,64
     3e2:	8082                	ret

00000000000003e4 <pipecmd>:

struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
     3e4:	7179                	addi	sp,sp,-48
     3e6:	f406                	sd	ra,40(sp)
     3e8:	f022                	sd	s0,32(sp)
     3ea:	ec26                	sd	s1,24(sp)
     3ec:	e84a                	sd	s2,16(sp)
     3ee:	e44e                	sd	s3,8(sp)
     3f0:	1800                	addi	s0,sp,48
     3f2:	89aa                	mv	s3,a0
     3f4:	892e                	mv	s2,a1
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
     3f6:	4561                	li	a0,24
     3f8:	00001097          	auipc	ra,0x1
     3fc:	ed0080e7          	jalr	-304(ra) # 12c8 <malloc>
     400:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     402:	4661                	li	a2,24
     404:	4581                	li	a1,0
     406:	00001097          	auipc	ra,0x1
     40a:	890080e7          	jalr	-1904(ra) # c96 <memset>
  cmd->type = PIPE;
     40e:	478d                	li	a5,3
     410:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     412:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     416:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     41a:	8526                	mv	a0,s1
     41c:	70a2                	ld	ra,40(sp)
     41e:	7402                	ld	s0,32(sp)
     420:	64e2                	ld	s1,24(sp)
     422:	6942                	ld	s2,16(sp)
     424:	69a2                	ld	s3,8(sp)
     426:	6145                	addi	sp,sp,48
     428:	8082                	ret

000000000000042a <listcmd>:

struct cmd*
listcmd(struct cmd *left, struct cmd *right)
{
     42a:	7179                	addi	sp,sp,-48
     42c:	f406                	sd	ra,40(sp)
     42e:	f022                	sd	s0,32(sp)
     430:	ec26                	sd	s1,24(sp)
     432:	e84a                	sd	s2,16(sp)
     434:	e44e                	sd	s3,8(sp)
     436:	1800                	addi	s0,sp,48
     438:	89aa                	mv	s3,a0
     43a:	892e                	mv	s2,a1
  struct listcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     43c:	4561                	li	a0,24
     43e:	00001097          	auipc	ra,0x1
     442:	e8a080e7          	jalr	-374(ra) # 12c8 <malloc>
     446:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     448:	4661                	li	a2,24
     44a:	4581                	li	a1,0
     44c:	00001097          	auipc	ra,0x1
     450:	84a080e7          	jalr	-1974(ra) # c96 <memset>
  cmd->type = LIST;
     454:	4791                	li	a5,4
     456:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     458:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     45c:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     460:	8526                	mv	a0,s1
     462:	70a2                	ld	ra,40(sp)
     464:	7402                	ld	s0,32(sp)
     466:	64e2                	ld	s1,24(sp)
     468:	6942                	ld	s2,16(sp)
     46a:	69a2                	ld	s3,8(sp)
     46c:	6145                	addi	sp,sp,48
     46e:	8082                	ret

0000000000000470 <backcmd>:

struct cmd*
backcmd(struct cmd *subcmd)
{
     470:	1101                	addi	sp,sp,-32
     472:	ec06                	sd	ra,24(sp)
     474:	e822                	sd	s0,16(sp)
     476:	e426                	sd	s1,8(sp)
     478:	e04a                	sd	s2,0(sp)
     47a:	1000                	addi	s0,sp,32
     47c:	892a                	mv	s2,a0
  struct backcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     47e:	4541                	li	a0,16
     480:	00001097          	auipc	ra,0x1
     484:	e48080e7          	jalr	-440(ra) # 12c8 <malloc>
     488:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     48a:	4641                	li	a2,16
     48c:	4581                	li	a1,0
     48e:	00001097          	auipc	ra,0x1
     492:	808080e7          	jalr	-2040(ra) # c96 <memset>
  cmd->type = BACK;
     496:	4795                	li	a5,5
     498:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     49a:	0124b423          	sd	s2,8(s1)
  return (struct cmd*)cmd;
}
     49e:	8526                	mv	a0,s1
     4a0:	60e2                	ld	ra,24(sp)
     4a2:	6442                	ld	s0,16(sp)
     4a4:	64a2                	ld	s1,8(sp)
     4a6:	6902                	ld	s2,0(sp)
     4a8:	6105                	addi	sp,sp,32
     4aa:	8082                	ret

00000000000004ac <gettoken>:
char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int
gettoken(char **ps, char *es, char **q, char **eq)
{
     4ac:	7139                	addi	sp,sp,-64
     4ae:	fc06                	sd	ra,56(sp)
     4b0:	f822                	sd	s0,48(sp)
     4b2:	f426                	sd	s1,40(sp)
     4b4:	f04a                	sd	s2,32(sp)
     4b6:	ec4e                	sd	s3,24(sp)
     4b8:	e852                	sd	s4,16(sp)
     4ba:	e456                	sd	s5,8(sp)
     4bc:	e05a                	sd	s6,0(sp)
     4be:	0080                	addi	s0,sp,64
     4c0:	8a2a                	mv	s4,a0
     4c2:	892e                	mv	s2,a1
     4c4:	8ab2                	mv	s5,a2
     4c6:	8b36                	mv	s6,a3
  char *s;
  int ret;

  s = *ps;
     4c8:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     4ca:	00001997          	auipc	s3,0x1
     4ce:	06698993          	addi	s3,s3,102 # 1530 <whitespace>
     4d2:	00b4fd63          	bgeu	s1,a1,4ec <gettoken+0x40>
     4d6:	0004c583          	lbu	a1,0(s1)
     4da:	854e                	mv	a0,s3
     4dc:	00000097          	auipc	ra,0x0
     4e0:	7dc080e7          	jalr	2012(ra) # cb8 <strchr>
     4e4:	c501                	beqz	a0,4ec <gettoken+0x40>
    s++;
     4e6:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     4e8:	fe9917e3          	bne	s2,s1,4d6 <gettoken+0x2a>
  if(q)
     4ec:	000a8463          	beqz	s5,4f4 <gettoken+0x48>
    *q = s;
     4f0:	009ab023          	sd	s1,0(s5)
  ret = *s;
     4f4:	0004c783          	lbu	a5,0(s1)
     4f8:	00078a9b          	sext.w	s5,a5
  switch(*s){
     4fc:	03c00713          	li	a4,60
     500:	06f76563          	bltu	a4,a5,56a <gettoken+0xbe>
     504:	03a00713          	li	a4,58
     508:	00f76e63          	bltu	a4,a5,524 <gettoken+0x78>
     50c:	cf89                	beqz	a5,526 <gettoken+0x7a>
     50e:	02600713          	li	a4,38
     512:	00e78963          	beq	a5,a4,524 <gettoken+0x78>
     516:	fd87879b          	addiw	a5,a5,-40
     51a:	0ff7f793          	andi	a5,a5,255
     51e:	4705                	li	a4,1
     520:	06f76c63          	bltu	a4,a5,598 <gettoken+0xec>
  case '(':
  case ')':
  case ';':
  case '&':
  case '<':
    s++;
     524:	0485                	addi	s1,s1,1
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
      s++;
    break;
  }
  if(eq)
     526:	000b0463          	beqz	s6,52e <gettoken+0x82>
    *eq = s;
     52a:	009b3023          	sd	s1,0(s6)

  while(s < es && strchr(whitespace, *s))
     52e:	00001997          	auipc	s3,0x1
     532:	00298993          	addi	s3,s3,2 # 1530 <whitespace>
     536:	0124fd63          	bgeu	s1,s2,550 <gettoken+0xa4>
     53a:	0004c583          	lbu	a1,0(s1)
     53e:	854e                	mv	a0,s3
     540:	00000097          	auipc	ra,0x0
     544:	778080e7          	jalr	1912(ra) # cb8 <strchr>
     548:	c501                	beqz	a0,550 <gettoken+0xa4>
    s++;
     54a:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     54c:	fe9917e3          	bne	s2,s1,53a <gettoken+0x8e>
  *ps = s;
     550:	009a3023          	sd	s1,0(s4)
  return ret;
}
     554:	8556                	mv	a0,s5
     556:	70e2                	ld	ra,56(sp)
     558:	7442                	ld	s0,48(sp)
     55a:	74a2                	ld	s1,40(sp)
     55c:	7902                	ld	s2,32(sp)
     55e:	69e2                	ld	s3,24(sp)
     560:	6a42                	ld	s4,16(sp)
     562:	6aa2                	ld	s5,8(sp)
     564:	6b02                	ld	s6,0(sp)
     566:	6121                	addi	sp,sp,64
     568:	8082                	ret
  switch(*s){
     56a:	03e00713          	li	a4,62
     56e:	02e79163          	bne	a5,a4,590 <gettoken+0xe4>
    s++;
     572:	00148693          	addi	a3,s1,1
    if(*s == '>'){
     576:	0014c703          	lbu	a4,1(s1)
     57a:	03e00793          	li	a5,62
      s++;
     57e:	0489                	addi	s1,s1,2
      ret = '+';
     580:	02b00a93          	li	s5,43
    if(*s == '>'){
     584:	faf701e3          	beq	a4,a5,526 <gettoken+0x7a>
    s++;
     588:	84b6                	mv	s1,a3
  ret = *s;
     58a:	03e00a93          	li	s5,62
     58e:	bf61                	j	526 <gettoken+0x7a>
  switch(*s){
     590:	07c00713          	li	a4,124
     594:	f8e788e3          	beq	a5,a4,524 <gettoken+0x78>
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     598:	00001997          	auipc	s3,0x1
     59c:	f9898993          	addi	s3,s3,-104 # 1530 <whitespace>
     5a0:	00001a97          	auipc	s5,0x1
     5a4:	f88a8a93          	addi	s5,s5,-120 # 1528 <symbols>
     5a8:	0324f563          	bgeu	s1,s2,5d2 <gettoken+0x126>
     5ac:	0004c583          	lbu	a1,0(s1)
     5b0:	854e                	mv	a0,s3
     5b2:	00000097          	auipc	ra,0x0
     5b6:	706080e7          	jalr	1798(ra) # cb8 <strchr>
     5ba:	e505                	bnez	a0,5e2 <gettoken+0x136>
     5bc:	0004c583          	lbu	a1,0(s1)
     5c0:	8556                	mv	a0,s5
     5c2:	00000097          	auipc	ra,0x0
     5c6:	6f6080e7          	jalr	1782(ra) # cb8 <strchr>
     5ca:	e909                	bnez	a0,5dc <gettoken+0x130>
      s++;
     5cc:	0485                	addi	s1,s1,1
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     5ce:	fc991fe3          	bne	s2,s1,5ac <gettoken+0x100>
  if(eq)
     5d2:	06100a93          	li	s5,97
     5d6:	f40b1ae3          	bnez	s6,52a <gettoken+0x7e>
     5da:	bf9d                	j	550 <gettoken+0xa4>
    ret = 'a';
     5dc:	06100a93          	li	s5,97
     5e0:	b799                	j	526 <gettoken+0x7a>
     5e2:	06100a93          	li	s5,97
     5e6:	b781                	j	526 <gettoken+0x7a>

00000000000005e8 <peek>:

int
peek(char **ps, char *es, char *toks)
{
     5e8:	7139                	addi	sp,sp,-64
     5ea:	fc06                	sd	ra,56(sp)
     5ec:	f822                	sd	s0,48(sp)
     5ee:	f426                	sd	s1,40(sp)
     5f0:	f04a                	sd	s2,32(sp)
     5f2:	ec4e                	sd	s3,24(sp)
     5f4:	e852                	sd	s4,16(sp)
     5f6:	e456                	sd	s5,8(sp)
     5f8:	0080                	addi	s0,sp,64
     5fa:	8a2a                	mv	s4,a0
     5fc:	892e                	mv	s2,a1
     5fe:	8ab2                	mv	s5,a2
  char *s;

  s = *ps;
     600:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     602:	00001997          	auipc	s3,0x1
     606:	f2e98993          	addi	s3,s3,-210 # 1530 <whitespace>
     60a:	00b4fd63          	bgeu	s1,a1,624 <peek+0x3c>
     60e:	0004c583          	lbu	a1,0(s1)
     612:	854e                	mv	a0,s3
     614:	00000097          	auipc	ra,0x0
     618:	6a4080e7          	jalr	1700(ra) # cb8 <strchr>
     61c:	c501                	beqz	a0,624 <peek+0x3c>
    s++;
     61e:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     620:	fe9917e3          	bne	s2,s1,60e <peek+0x26>
  *ps = s;
     624:	009a3023          	sd	s1,0(s4)
  return *s && strchr(toks, *s);
     628:	0004c583          	lbu	a1,0(s1)
     62c:	4501                	li	a0,0
     62e:	e991                	bnez	a1,642 <peek+0x5a>
}
     630:	70e2                	ld	ra,56(sp)
     632:	7442                	ld	s0,48(sp)
     634:	74a2                	ld	s1,40(sp)
     636:	7902                	ld	s2,32(sp)
     638:	69e2                	ld	s3,24(sp)
     63a:	6a42                	ld	s4,16(sp)
     63c:	6aa2                	ld	s5,8(sp)
     63e:	6121                	addi	sp,sp,64
     640:	8082                	ret
  return *s && strchr(toks, *s);
     642:	8556                	mv	a0,s5
     644:	00000097          	auipc	ra,0x0
     648:	674080e7          	jalr	1652(ra) # cb8 <strchr>
     64c:	00a03533          	snez	a0,a0
     650:	b7c5                	j	630 <peek+0x48>

0000000000000652 <parseredirs>:
  return cmd;
}

struct cmd*
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     652:	7159                	addi	sp,sp,-112
     654:	f486                	sd	ra,104(sp)
     656:	f0a2                	sd	s0,96(sp)
     658:	eca6                	sd	s1,88(sp)
     65a:	e8ca                	sd	s2,80(sp)
     65c:	e4ce                	sd	s3,72(sp)
     65e:	e0d2                	sd	s4,64(sp)
     660:	fc56                	sd	s5,56(sp)
     662:	f85a                	sd	s6,48(sp)
     664:	f45e                	sd	s7,40(sp)
     666:	f062                	sd	s8,32(sp)
     668:	ec66                	sd	s9,24(sp)
     66a:	1880                	addi	s0,sp,112
     66c:	8a2a                	mv	s4,a0
     66e:	89ae                	mv	s3,a1
     670:	8932                	mv	s2,a2
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     672:	00001b97          	auipc	s7,0x1
     676:	dbeb8b93          	addi	s7,s7,-578 # 1430 <malloc+0x168>
    tok = gettoken(ps, es, 0, 0);
    if(gettoken(ps, es, &q, &eq) != 'a')
     67a:	06100c13          	li	s8,97
      panic("missing file for redirection");
    switch(tok){
     67e:	03c00c93          	li	s9,60
  while(peek(ps, es, "<>")){
     682:	a02d                	j	6ac <parseredirs+0x5a>
      panic("missing file for redirection");
     684:	00001517          	auipc	a0,0x1
     688:	d8c50513          	addi	a0,a0,-628 # 1410 <malloc+0x148>
     68c:	00000097          	auipc	ra,0x0
     690:	9c8080e7          	jalr	-1592(ra) # 54 <panic>
    case '<':
      cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     694:	4701                	li	a4,0
     696:	4681                	li	a3,0
     698:	f9043603          	ld	a2,-112(s0)
     69c:	f9843583          	ld	a1,-104(s0)
     6a0:	8552                	mv	a0,s4
     6a2:	00000097          	auipc	ra,0x0
     6a6:	cda080e7          	jalr	-806(ra) # 37c <redircmd>
     6aa:	8a2a                	mv	s4,a0
    switch(tok){
     6ac:	03e00b13          	li	s6,62
     6b0:	02b00a93          	li	s5,43
  while(peek(ps, es, "<>")){
     6b4:	865e                	mv	a2,s7
     6b6:	85ca                	mv	a1,s2
     6b8:	854e                	mv	a0,s3
     6ba:	00000097          	auipc	ra,0x0
     6be:	f2e080e7          	jalr	-210(ra) # 5e8 <peek>
     6c2:	c925                	beqz	a0,732 <parseredirs+0xe0>
    tok = gettoken(ps, es, 0, 0);
     6c4:	4681                	li	a3,0
     6c6:	4601                	li	a2,0
     6c8:	85ca                	mv	a1,s2
     6ca:	854e                	mv	a0,s3
     6cc:	00000097          	auipc	ra,0x0
     6d0:	de0080e7          	jalr	-544(ra) # 4ac <gettoken>
     6d4:	84aa                	mv	s1,a0
    if(gettoken(ps, es, &q, &eq) != 'a')
     6d6:	f9040693          	addi	a3,s0,-112
     6da:	f9840613          	addi	a2,s0,-104
     6de:	85ca                	mv	a1,s2
     6e0:	854e                	mv	a0,s3
     6e2:	00000097          	auipc	ra,0x0
     6e6:	dca080e7          	jalr	-566(ra) # 4ac <gettoken>
     6ea:	f9851de3          	bne	a0,s8,684 <parseredirs+0x32>
    switch(tok){
     6ee:	fb9483e3          	beq	s1,s9,694 <parseredirs+0x42>
     6f2:	03648263          	beq	s1,s6,716 <parseredirs+0xc4>
     6f6:	fb549fe3          	bne	s1,s5,6b4 <parseredirs+0x62>
      break;
    case '>':
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
      break;
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     6fa:	4705                	li	a4,1
     6fc:	20100693          	li	a3,513
     700:	f9043603          	ld	a2,-112(s0)
     704:	f9843583          	ld	a1,-104(s0)
     708:	8552                	mv	a0,s4
     70a:	00000097          	auipc	ra,0x0
     70e:	c72080e7          	jalr	-910(ra) # 37c <redircmd>
     712:	8a2a                	mv	s4,a0
      break;
     714:	bf61                	j	6ac <parseredirs+0x5a>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
     716:	4705                	li	a4,1
     718:	60100693          	li	a3,1537
     71c:	f9043603          	ld	a2,-112(s0)
     720:	f9843583          	ld	a1,-104(s0)
     724:	8552                	mv	a0,s4
     726:	00000097          	auipc	ra,0x0
     72a:	c56080e7          	jalr	-938(ra) # 37c <redircmd>
     72e:	8a2a                	mv	s4,a0
      break;
     730:	bfb5                	j	6ac <parseredirs+0x5a>
    }
  }
  return cmd;
}
     732:	8552                	mv	a0,s4
     734:	70a6                	ld	ra,104(sp)
     736:	7406                	ld	s0,96(sp)
     738:	64e6                	ld	s1,88(sp)
     73a:	6946                	ld	s2,80(sp)
     73c:	69a6                	ld	s3,72(sp)
     73e:	6a06                	ld	s4,64(sp)
     740:	7ae2                	ld	s5,56(sp)
     742:	7b42                	ld	s6,48(sp)
     744:	7ba2                	ld	s7,40(sp)
     746:	7c02                	ld	s8,32(sp)
     748:	6ce2                	ld	s9,24(sp)
     74a:	6165                	addi	sp,sp,112
     74c:	8082                	ret

000000000000074e <parseexec>:
  return cmd;
}

struct cmd*
parseexec(char **ps, char *es)
{
     74e:	7159                	addi	sp,sp,-112
     750:	f486                	sd	ra,104(sp)
     752:	f0a2                	sd	s0,96(sp)
     754:	eca6                	sd	s1,88(sp)
     756:	e8ca                	sd	s2,80(sp)
     758:	e4ce                	sd	s3,72(sp)
     75a:	e0d2                	sd	s4,64(sp)
     75c:	fc56                	sd	s5,56(sp)
     75e:	f85a                	sd	s6,48(sp)
     760:	f45e                	sd	s7,40(sp)
     762:	f062                	sd	s8,32(sp)
     764:	ec66                	sd	s9,24(sp)
     766:	1880                	addi	s0,sp,112
     768:	8a2a                	mv	s4,a0
     76a:	8aae                	mv	s5,a1
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;

  if(peek(ps, es, "("))
     76c:	00001617          	auipc	a2,0x1
     770:	ccc60613          	addi	a2,a2,-820 # 1438 <malloc+0x170>
     774:	00000097          	auipc	ra,0x0
     778:	e74080e7          	jalr	-396(ra) # 5e8 <peek>
     77c:	e905                	bnez	a0,7ac <parseexec+0x5e>
     77e:	89aa                	mv	s3,a0
    return parseblock(ps, es);

  ret = execcmd();
     780:	00000097          	auipc	ra,0x0
     784:	bc6080e7          	jalr	-1082(ra) # 346 <execcmd>
     788:	8c2a                	mv	s8,a0
  cmd = (struct execcmd*)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es);
     78a:	8656                	mv	a2,s5
     78c:	85d2                	mv	a1,s4
     78e:	00000097          	auipc	ra,0x0
     792:	ec4080e7          	jalr	-316(ra) # 652 <parseredirs>
     796:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     798:	008c0913          	addi	s2,s8,8
     79c:	00001b17          	auipc	s6,0x1
     7a0:	cbcb0b13          	addi	s6,s6,-836 # 1458 <malloc+0x190>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
      break;
    if(tok != 'a')
     7a4:	06100c93          	li	s9,97
      panic("syntax");
    cmd->argv[argc] = q;
    cmd->eargv[argc] = eq;
    argc++;
    if(argc >= MAXARGS)
     7a8:	4ba9                	li	s7,10
  while(!peek(ps, es, "|)&;")){
     7aa:	a0b1                	j	7f6 <parseexec+0xa8>
    return parseblock(ps, es);
     7ac:	85d6                	mv	a1,s5
     7ae:	8552                	mv	a0,s4
     7b0:	00000097          	auipc	ra,0x0
     7b4:	1bc080e7          	jalr	444(ra) # 96c <parseblock>
     7b8:	84aa                	mv	s1,a0
    ret = parseredirs(ret, ps, es);
  }
  cmd->argv[argc] = 0;
  cmd->eargv[argc] = 0;
  return ret;
}
     7ba:	8526                	mv	a0,s1
     7bc:	70a6                	ld	ra,104(sp)
     7be:	7406                	ld	s0,96(sp)
     7c0:	64e6                	ld	s1,88(sp)
     7c2:	6946                	ld	s2,80(sp)
     7c4:	69a6                	ld	s3,72(sp)
     7c6:	6a06                	ld	s4,64(sp)
     7c8:	7ae2                	ld	s5,56(sp)
     7ca:	7b42                	ld	s6,48(sp)
     7cc:	7ba2                	ld	s7,40(sp)
     7ce:	7c02                	ld	s8,32(sp)
     7d0:	6ce2                	ld	s9,24(sp)
     7d2:	6165                	addi	sp,sp,112
     7d4:	8082                	ret
      panic("syntax");
     7d6:	00001517          	auipc	a0,0x1
     7da:	c6a50513          	addi	a0,a0,-918 # 1440 <malloc+0x178>
     7de:	00000097          	auipc	ra,0x0
     7e2:	876080e7          	jalr	-1930(ra) # 54 <panic>
    ret = parseredirs(ret, ps, es);
     7e6:	8656                	mv	a2,s5
     7e8:	85d2                	mv	a1,s4
     7ea:	8526                	mv	a0,s1
     7ec:	00000097          	auipc	ra,0x0
     7f0:	e66080e7          	jalr	-410(ra) # 652 <parseredirs>
     7f4:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     7f6:	865a                	mv	a2,s6
     7f8:	85d6                	mv	a1,s5
     7fa:	8552                	mv	a0,s4
     7fc:	00000097          	auipc	ra,0x0
     800:	dec080e7          	jalr	-532(ra) # 5e8 <peek>
     804:	e131                	bnez	a0,848 <parseexec+0xfa>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
     806:	f9040693          	addi	a3,s0,-112
     80a:	f9840613          	addi	a2,s0,-104
     80e:	85d6                	mv	a1,s5
     810:	8552                	mv	a0,s4
     812:	00000097          	auipc	ra,0x0
     816:	c9a080e7          	jalr	-870(ra) # 4ac <gettoken>
     81a:	c51d                	beqz	a0,848 <parseexec+0xfa>
    if(tok != 'a')
     81c:	fb951de3          	bne	a0,s9,7d6 <parseexec+0x88>
    cmd->argv[argc] = q;
     820:	f9843783          	ld	a5,-104(s0)
     824:	00f93023          	sd	a5,0(s2)
    cmd->eargv[argc] = eq;
     828:	f9043783          	ld	a5,-112(s0)
     82c:	04f93823          	sd	a5,80(s2)
    argc++;
     830:	2985                	addiw	s3,s3,1
    if(argc >= MAXARGS)
     832:	0921                	addi	s2,s2,8
     834:	fb7999e3          	bne	s3,s7,7e6 <parseexec+0x98>
      panic("too many args");
     838:	00001517          	auipc	a0,0x1
     83c:	c1050513          	addi	a0,a0,-1008 # 1448 <malloc+0x180>
     840:	00000097          	auipc	ra,0x0
     844:	814080e7          	jalr	-2028(ra) # 54 <panic>
  cmd->argv[argc] = 0;
     848:	098e                	slli	s3,s3,0x3
     84a:	99e2                	add	s3,s3,s8
     84c:	0009b423          	sd	zero,8(s3)
  cmd->eargv[argc] = 0;
     850:	0409bc23          	sd	zero,88(s3)
  return ret;
     854:	b79d                	j	7ba <parseexec+0x6c>

0000000000000856 <parsepipe>:
{
     856:	7179                	addi	sp,sp,-48
     858:	f406                	sd	ra,40(sp)
     85a:	f022                	sd	s0,32(sp)
     85c:	ec26                	sd	s1,24(sp)
     85e:	e84a                	sd	s2,16(sp)
     860:	e44e                	sd	s3,8(sp)
     862:	1800                	addi	s0,sp,48
     864:	892a                	mv	s2,a0
     866:	89ae                	mv	s3,a1
  cmd = parseexec(ps, es);
     868:	00000097          	auipc	ra,0x0
     86c:	ee6080e7          	jalr	-282(ra) # 74e <parseexec>
     870:	84aa                	mv	s1,a0
  if(peek(ps, es, "|")){
     872:	00001617          	auipc	a2,0x1
     876:	bee60613          	addi	a2,a2,-1042 # 1460 <malloc+0x198>
     87a:	85ce                	mv	a1,s3
     87c:	854a                	mv	a0,s2
     87e:	00000097          	auipc	ra,0x0
     882:	d6a080e7          	jalr	-662(ra) # 5e8 <peek>
     886:	e909                	bnez	a0,898 <parsepipe+0x42>
}
     888:	8526                	mv	a0,s1
     88a:	70a2                	ld	ra,40(sp)
     88c:	7402                	ld	s0,32(sp)
     88e:	64e2                	ld	s1,24(sp)
     890:	6942                	ld	s2,16(sp)
     892:	69a2                	ld	s3,8(sp)
     894:	6145                	addi	sp,sp,48
     896:	8082                	ret
    gettoken(ps, es, 0, 0);
     898:	4681                	li	a3,0
     89a:	4601                	li	a2,0
     89c:	85ce                	mv	a1,s3
     89e:	854a                	mv	a0,s2
     8a0:	00000097          	auipc	ra,0x0
     8a4:	c0c080e7          	jalr	-1012(ra) # 4ac <gettoken>
    cmd = pipecmd(cmd, parsepipe(ps, es));
     8a8:	85ce                	mv	a1,s3
     8aa:	854a                	mv	a0,s2
     8ac:	00000097          	auipc	ra,0x0
     8b0:	faa080e7          	jalr	-86(ra) # 856 <parsepipe>
     8b4:	85aa                	mv	a1,a0
     8b6:	8526                	mv	a0,s1
     8b8:	00000097          	auipc	ra,0x0
     8bc:	b2c080e7          	jalr	-1236(ra) # 3e4 <pipecmd>
     8c0:	84aa                	mv	s1,a0
  return cmd;
     8c2:	b7d9                	j	888 <parsepipe+0x32>

00000000000008c4 <parseline>:
{
     8c4:	7179                	addi	sp,sp,-48
     8c6:	f406                	sd	ra,40(sp)
     8c8:	f022                	sd	s0,32(sp)
     8ca:	ec26                	sd	s1,24(sp)
     8cc:	e84a                	sd	s2,16(sp)
     8ce:	e44e                	sd	s3,8(sp)
     8d0:	e052                	sd	s4,0(sp)
     8d2:	1800                	addi	s0,sp,48
     8d4:	892a                	mv	s2,a0
     8d6:	89ae                	mv	s3,a1
  cmd = parsepipe(ps, es);
     8d8:	00000097          	auipc	ra,0x0
     8dc:	f7e080e7          	jalr	-130(ra) # 856 <parsepipe>
     8e0:	84aa                	mv	s1,a0
  while(peek(ps, es, "&")){
     8e2:	00001a17          	auipc	s4,0x1
     8e6:	b86a0a13          	addi	s4,s4,-1146 # 1468 <malloc+0x1a0>
     8ea:	a839                	j	908 <parseline+0x44>
    gettoken(ps, es, 0, 0);
     8ec:	4681                	li	a3,0
     8ee:	4601                	li	a2,0
     8f0:	85ce                	mv	a1,s3
     8f2:	854a                	mv	a0,s2
     8f4:	00000097          	auipc	ra,0x0
     8f8:	bb8080e7          	jalr	-1096(ra) # 4ac <gettoken>
    cmd = backcmd(cmd);
     8fc:	8526                	mv	a0,s1
     8fe:	00000097          	auipc	ra,0x0
     902:	b72080e7          	jalr	-1166(ra) # 470 <backcmd>
     906:	84aa                	mv	s1,a0
  while(peek(ps, es, "&")){
     908:	8652                	mv	a2,s4
     90a:	85ce                	mv	a1,s3
     90c:	854a                	mv	a0,s2
     90e:	00000097          	auipc	ra,0x0
     912:	cda080e7          	jalr	-806(ra) # 5e8 <peek>
     916:	f979                	bnez	a0,8ec <parseline+0x28>
  if(peek(ps, es, ";")){
     918:	00001617          	auipc	a2,0x1
     91c:	b5860613          	addi	a2,a2,-1192 # 1470 <malloc+0x1a8>
     920:	85ce                	mv	a1,s3
     922:	854a                	mv	a0,s2
     924:	00000097          	auipc	ra,0x0
     928:	cc4080e7          	jalr	-828(ra) # 5e8 <peek>
     92c:	e911                	bnez	a0,940 <parseline+0x7c>
}
     92e:	8526                	mv	a0,s1
     930:	70a2                	ld	ra,40(sp)
     932:	7402                	ld	s0,32(sp)
     934:	64e2                	ld	s1,24(sp)
     936:	6942                	ld	s2,16(sp)
     938:	69a2                	ld	s3,8(sp)
     93a:	6a02                	ld	s4,0(sp)
     93c:	6145                	addi	sp,sp,48
     93e:	8082                	ret
    gettoken(ps, es, 0, 0);
     940:	4681                	li	a3,0
     942:	4601                	li	a2,0
     944:	85ce                	mv	a1,s3
     946:	854a                	mv	a0,s2
     948:	00000097          	auipc	ra,0x0
     94c:	b64080e7          	jalr	-1180(ra) # 4ac <gettoken>
    cmd = listcmd(cmd, parseline(ps, es));
     950:	85ce                	mv	a1,s3
     952:	854a                	mv	a0,s2
     954:	00000097          	auipc	ra,0x0
     958:	f70080e7          	jalr	-144(ra) # 8c4 <parseline>
     95c:	85aa                	mv	a1,a0
     95e:	8526                	mv	a0,s1
     960:	00000097          	auipc	ra,0x0
     964:	aca080e7          	jalr	-1334(ra) # 42a <listcmd>
     968:	84aa                	mv	s1,a0
  return cmd;
     96a:	b7d1                	j	92e <parseline+0x6a>

000000000000096c <parseblock>:
{
     96c:	7179                	addi	sp,sp,-48
     96e:	f406                	sd	ra,40(sp)
     970:	f022                	sd	s0,32(sp)
     972:	ec26                	sd	s1,24(sp)
     974:	e84a                	sd	s2,16(sp)
     976:	e44e                	sd	s3,8(sp)
     978:	1800                	addi	s0,sp,48
     97a:	84aa                	mv	s1,a0
     97c:	892e                	mv	s2,a1
  if(!peek(ps, es, "("))
     97e:	00001617          	auipc	a2,0x1
     982:	aba60613          	addi	a2,a2,-1350 # 1438 <malloc+0x170>
     986:	00000097          	auipc	ra,0x0
     98a:	c62080e7          	jalr	-926(ra) # 5e8 <peek>
     98e:	c12d                	beqz	a0,9f0 <parseblock+0x84>
  gettoken(ps, es, 0, 0);
     990:	4681                	li	a3,0
     992:	4601                	li	a2,0
     994:	85ca                	mv	a1,s2
     996:	8526                	mv	a0,s1
     998:	00000097          	auipc	ra,0x0
     99c:	b14080e7          	jalr	-1260(ra) # 4ac <gettoken>
  cmd = parseline(ps, es);
     9a0:	85ca                	mv	a1,s2
     9a2:	8526                	mv	a0,s1
     9a4:	00000097          	auipc	ra,0x0
     9a8:	f20080e7          	jalr	-224(ra) # 8c4 <parseline>
     9ac:	89aa                	mv	s3,a0
  if(!peek(ps, es, ")"))
     9ae:	00001617          	auipc	a2,0x1
     9b2:	ada60613          	addi	a2,a2,-1318 # 1488 <malloc+0x1c0>
     9b6:	85ca                	mv	a1,s2
     9b8:	8526                	mv	a0,s1
     9ba:	00000097          	auipc	ra,0x0
     9be:	c2e080e7          	jalr	-978(ra) # 5e8 <peek>
     9c2:	cd1d                	beqz	a0,a00 <parseblock+0x94>
  gettoken(ps, es, 0, 0);
     9c4:	4681                	li	a3,0
     9c6:	4601                	li	a2,0
     9c8:	85ca                	mv	a1,s2
     9ca:	8526                	mv	a0,s1
     9cc:	00000097          	auipc	ra,0x0
     9d0:	ae0080e7          	jalr	-1312(ra) # 4ac <gettoken>
  cmd = parseredirs(cmd, ps, es);
     9d4:	864a                	mv	a2,s2
     9d6:	85a6                	mv	a1,s1
     9d8:	854e                	mv	a0,s3
     9da:	00000097          	auipc	ra,0x0
     9de:	c78080e7          	jalr	-904(ra) # 652 <parseredirs>
}
     9e2:	70a2                	ld	ra,40(sp)
     9e4:	7402                	ld	s0,32(sp)
     9e6:	64e2                	ld	s1,24(sp)
     9e8:	6942                	ld	s2,16(sp)
     9ea:	69a2                	ld	s3,8(sp)
     9ec:	6145                	addi	sp,sp,48
     9ee:	8082                	ret
    panic("parseblock");
     9f0:	00001517          	auipc	a0,0x1
     9f4:	a8850513          	addi	a0,a0,-1400 # 1478 <malloc+0x1b0>
     9f8:	fffff097          	auipc	ra,0xfffff
     9fc:	65c080e7          	jalr	1628(ra) # 54 <panic>
    panic("syntax - missing )");
     a00:	00001517          	auipc	a0,0x1
     a04:	a9050513          	addi	a0,a0,-1392 # 1490 <malloc+0x1c8>
     a08:	fffff097          	auipc	ra,0xfffff
     a0c:	64c080e7          	jalr	1612(ra) # 54 <panic>

0000000000000a10 <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd*
nulterminate(struct cmd *cmd)
{
     a10:	1101                	addi	sp,sp,-32
     a12:	ec06                	sd	ra,24(sp)
     a14:	e822                	sd	s0,16(sp)
     a16:	e426                	sd	s1,8(sp)
     a18:	1000                	addi	s0,sp,32
     a1a:	84aa                	mv	s1,a0
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
     a1c:	c521                	beqz	a0,a64 <nulterminate+0x54>
    return 0;

  switch(cmd->type){
     a1e:	4118                	lw	a4,0(a0)
     a20:	4795                	li	a5,5
     a22:	04e7e163          	bltu	a5,a4,a64 <nulterminate+0x54>
     a26:	00056783          	lwu	a5,0(a0)
     a2a:	078a                	slli	a5,a5,0x2
     a2c:	00001717          	auipc	a4,0x1
     a30:	ac470713          	addi	a4,a4,-1340 # 14f0 <malloc+0x228>
     a34:	97ba                	add	a5,a5,a4
     a36:	439c                	lw	a5,0(a5)
     a38:	97ba                	add	a5,a5,a4
     a3a:	8782                	jr	a5
  case EXEC:
    ecmd = (struct execcmd*)cmd;
    for(i=0; ecmd->argv[i]; i++)
     a3c:	651c                	ld	a5,8(a0)
     a3e:	c39d                	beqz	a5,a64 <nulterminate+0x54>
     a40:	01050793          	addi	a5,a0,16
      *ecmd->eargv[i] = 0;
     a44:	67b8                	ld	a4,72(a5)
     a46:	00070023          	sb	zero,0(a4)
    for(i=0; ecmd->argv[i]; i++)
     a4a:	07a1                	addi	a5,a5,8
     a4c:	ff87b703          	ld	a4,-8(a5)
     a50:	fb75                	bnez	a4,a44 <nulterminate+0x34>
     a52:	a809                	j	a64 <nulterminate+0x54>
    break;

  case REDIR:
    rcmd = (struct redircmd*)cmd;
    nulterminate(rcmd->cmd);
     a54:	6508                	ld	a0,8(a0)
     a56:	00000097          	auipc	ra,0x0
     a5a:	fba080e7          	jalr	-70(ra) # a10 <nulterminate>
    *rcmd->efile = 0;
     a5e:	6c9c                	ld	a5,24(s1)
     a60:	00078023          	sb	zero,0(a5)
    bcmd = (struct backcmd*)cmd;
    nulterminate(bcmd->cmd);
    break;
  }
  return cmd;
}
     a64:	8526                	mv	a0,s1
     a66:	60e2                	ld	ra,24(sp)
     a68:	6442                	ld	s0,16(sp)
     a6a:	64a2                	ld	s1,8(sp)
     a6c:	6105                	addi	sp,sp,32
     a6e:	8082                	ret
    nulterminate(pcmd->left);
     a70:	6508                	ld	a0,8(a0)
     a72:	00000097          	auipc	ra,0x0
     a76:	f9e080e7          	jalr	-98(ra) # a10 <nulterminate>
    nulterminate(pcmd->right);
     a7a:	6888                	ld	a0,16(s1)
     a7c:	00000097          	auipc	ra,0x0
     a80:	f94080e7          	jalr	-108(ra) # a10 <nulterminate>
    break;
     a84:	b7c5                	j	a64 <nulterminate+0x54>
    nulterminate(lcmd->left);
     a86:	6508                	ld	a0,8(a0)
     a88:	00000097          	auipc	ra,0x0
     a8c:	f88080e7          	jalr	-120(ra) # a10 <nulterminate>
    nulterminate(lcmd->right);
     a90:	6888                	ld	a0,16(s1)
     a92:	00000097          	auipc	ra,0x0
     a96:	f7e080e7          	jalr	-130(ra) # a10 <nulterminate>
    break;
     a9a:	b7e9                	j	a64 <nulterminate+0x54>
    nulterminate(bcmd->cmd);
     a9c:	6508                	ld	a0,8(a0)
     a9e:	00000097          	auipc	ra,0x0
     aa2:	f72080e7          	jalr	-142(ra) # a10 <nulterminate>
    break;
     aa6:	bf7d                	j	a64 <nulterminate+0x54>

0000000000000aa8 <parsecmd>:
{
     aa8:	7179                	addi	sp,sp,-48
     aaa:	f406                	sd	ra,40(sp)
     aac:	f022                	sd	s0,32(sp)
     aae:	ec26                	sd	s1,24(sp)
     ab0:	e84a                	sd	s2,16(sp)
     ab2:	1800                	addi	s0,sp,48
     ab4:	fca43c23          	sd	a0,-40(s0)
  es = s + strlen(s);
     ab8:	84aa                	mv	s1,a0
     aba:	00000097          	auipc	ra,0x0
     abe:	1b2080e7          	jalr	434(ra) # c6c <strlen>
     ac2:	1502                	slli	a0,a0,0x20
     ac4:	9101                	srli	a0,a0,0x20
     ac6:	94aa                	add	s1,s1,a0
  cmd = parseline(&s, es);
     ac8:	85a6                	mv	a1,s1
     aca:	fd840513          	addi	a0,s0,-40
     ace:	00000097          	auipc	ra,0x0
     ad2:	df6080e7          	jalr	-522(ra) # 8c4 <parseline>
     ad6:	892a                	mv	s2,a0
  peek(&s, es, "");
     ad8:	00001617          	auipc	a2,0x1
     adc:	9d060613          	addi	a2,a2,-1584 # 14a8 <malloc+0x1e0>
     ae0:	85a6                	mv	a1,s1
     ae2:	fd840513          	addi	a0,s0,-40
     ae6:	00000097          	auipc	ra,0x0
     aea:	b02080e7          	jalr	-1278(ra) # 5e8 <peek>
  if(s != es){
     aee:	fd843603          	ld	a2,-40(s0)
     af2:	00961e63          	bne	a2,s1,b0e <parsecmd+0x66>
  nulterminate(cmd);
     af6:	854a                	mv	a0,s2
     af8:	00000097          	auipc	ra,0x0
     afc:	f18080e7          	jalr	-232(ra) # a10 <nulterminate>
}
     b00:	854a                	mv	a0,s2
     b02:	70a2                	ld	ra,40(sp)
     b04:	7402                	ld	s0,32(sp)
     b06:	64e2                	ld	s1,24(sp)
     b08:	6942                	ld	s2,16(sp)
     b0a:	6145                	addi	sp,sp,48
     b0c:	8082                	ret
    fprintf(2, "leftovers: %s\n", s);
     b0e:	00001597          	auipc	a1,0x1
     b12:	9a258593          	addi	a1,a1,-1630 # 14b0 <malloc+0x1e8>
     b16:	4509                	li	a0,2
     b18:	00000097          	auipc	ra,0x0
     b1c:	6c4080e7          	jalr	1732(ra) # 11dc <fprintf>
    panic("syntax");
     b20:	00001517          	auipc	a0,0x1
     b24:	92050513          	addi	a0,a0,-1760 # 1440 <malloc+0x178>
     b28:	fffff097          	auipc	ra,0xfffff
     b2c:	52c080e7          	jalr	1324(ra) # 54 <panic>

0000000000000b30 <main>:
{
     b30:	7139                	addi	sp,sp,-64
     b32:	fc06                	sd	ra,56(sp)
     b34:	f822                	sd	s0,48(sp)
     b36:	f426                	sd	s1,40(sp)
     b38:	f04a                	sd	s2,32(sp)
     b3a:	ec4e                	sd	s3,24(sp)
     b3c:	e852                	sd	s4,16(sp)
     b3e:	e456                	sd	s5,8(sp)
     b40:	0080                	addi	s0,sp,64
  while((fd = open("console", O_RDWR)) >= 0){
     b42:	00001497          	auipc	s1,0x1
     b46:	97e48493          	addi	s1,s1,-1666 # 14c0 <malloc+0x1f8>
     b4a:	4589                	li	a1,2
     b4c:	8526                	mv	a0,s1
     b4e:	00000097          	auipc	ra,0x0
     b52:	384080e7          	jalr	900(ra) # ed2 <open>
     b56:	00054963          	bltz	a0,b68 <main+0x38>
    if(fd >= 3){
     b5a:	4789                	li	a5,2
     b5c:	fea7d7e3          	bge	a5,a0,b4a <main+0x1a>
      close(fd);
     b60:	00000097          	auipc	ra,0x0
     b64:	35a080e7          	jalr	858(ra) # eba <close>
  while(getcmd(buf, sizeof(buf)) >= 0){
     b68:	00001497          	auipc	s1,0x1
     b6c:	9d848493          	addi	s1,s1,-1576 # 1540 <buf.0>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     b70:	06300913          	li	s2,99
     b74:	02000993          	li	s3,32
      if(chdir(buf+3) < 0)
     b78:	00001a17          	auipc	s4,0x1
     b7c:	9cba0a13          	addi	s4,s4,-1589 # 1543 <buf.0+0x3>
        fprintf(2, "cannot cd %s\n", buf+3);
     b80:	00001a97          	auipc	s5,0x1
     b84:	948a8a93          	addi	s5,s5,-1720 # 14c8 <malloc+0x200>
     b88:	a819                	j	b9e <main+0x6e>
    if(fork1() == 0)
     b8a:	fffff097          	auipc	ra,0xfffff
     b8e:	4f0080e7          	jalr	1264(ra) # 7a <fork1>
     b92:	c925                	beqz	a0,c02 <main+0xd2>
    wait(0);
     b94:	4501                	li	a0,0
     b96:	00000097          	auipc	ra,0x0
     b9a:	304080e7          	jalr	772(ra) # e9a <wait>
  while(getcmd(buf, sizeof(buf)) >= 0){
     b9e:	06400593          	li	a1,100
     ba2:	8526                	mv	a0,s1
     ba4:	fffff097          	auipc	ra,0xfffff
     ba8:	45c080e7          	jalr	1116(ra) # 0 <getcmd>
     bac:	06054763          	bltz	a0,c1a <main+0xea>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     bb0:	0004c783          	lbu	a5,0(s1)
     bb4:	fd279be3          	bne	a5,s2,b8a <main+0x5a>
     bb8:	0014c703          	lbu	a4,1(s1)
     bbc:	06400793          	li	a5,100
     bc0:	fcf715e3          	bne	a4,a5,b8a <main+0x5a>
     bc4:	0024c783          	lbu	a5,2(s1)
     bc8:	fd3791e3          	bne	a5,s3,b8a <main+0x5a>
      buf[strlen(buf)-1] = 0;  // chop \n
     bcc:	8526                	mv	a0,s1
     bce:	00000097          	auipc	ra,0x0
     bd2:	09e080e7          	jalr	158(ra) # c6c <strlen>
     bd6:	fff5079b          	addiw	a5,a0,-1
     bda:	1782                	slli	a5,a5,0x20
     bdc:	9381                	srli	a5,a5,0x20
     bde:	97a6                	add	a5,a5,s1
     be0:	00078023          	sb	zero,0(a5)
      if(chdir(buf+3) < 0)
     be4:	8552                	mv	a0,s4
     be6:	00000097          	auipc	ra,0x0
     bea:	31c080e7          	jalr	796(ra) # f02 <chdir>
     bee:	fa0558e3          	bgez	a0,b9e <main+0x6e>
        fprintf(2, "cannot cd %s\n", buf+3);
     bf2:	8652                	mv	a2,s4
     bf4:	85d6                	mv	a1,s5
     bf6:	4509                	li	a0,2
     bf8:	00000097          	auipc	ra,0x0
     bfc:	5e4080e7          	jalr	1508(ra) # 11dc <fprintf>
     c00:	bf79                	j	b9e <main+0x6e>
      runcmd(parsecmd(buf));
     c02:	00001517          	auipc	a0,0x1
     c06:	93e50513          	addi	a0,a0,-1730 # 1540 <buf.0>
     c0a:	00000097          	auipc	ra,0x0
     c0e:	e9e080e7          	jalr	-354(ra) # aa8 <parsecmd>
     c12:	fffff097          	auipc	ra,0xfffff
     c16:	496080e7          	jalr	1174(ra) # a8 <runcmd>
  exit(0);
     c1a:	4501                	li	a0,0
     c1c:	00000097          	auipc	ra,0x0
     c20:	276080e7          	jalr	630(ra) # e92 <exit>

0000000000000c24 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     c24:	1141                	addi	sp,sp,-16
     c26:	e422                	sd	s0,8(sp)
     c28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     c2a:	87aa                	mv	a5,a0
     c2c:	0585                	addi	a1,a1,1
     c2e:	0785                	addi	a5,a5,1
     c30:	fff5c703          	lbu	a4,-1(a1)
     c34:	fee78fa3          	sb	a4,-1(a5)
     c38:	fb75                	bnez	a4,c2c <strcpy+0x8>
    ;
  return os;
}
     c3a:	6422                	ld	s0,8(sp)
     c3c:	0141                	addi	sp,sp,16
     c3e:	8082                	ret

0000000000000c40 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     c40:	1141                	addi	sp,sp,-16
     c42:	e422                	sd	s0,8(sp)
     c44:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     c46:	00054783          	lbu	a5,0(a0)
     c4a:	cb91                	beqz	a5,c5e <strcmp+0x1e>
     c4c:	0005c703          	lbu	a4,0(a1)
     c50:	00f71763          	bne	a4,a5,c5e <strcmp+0x1e>
    p++, q++;
     c54:	0505                	addi	a0,a0,1
     c56:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     c58:	00054783          	lbu	a5,0(a0)
     c5c:	fbe5                	bnez	a5,c4c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     c5e:	0005c503          	lbu	a0,0(a1)
}
     c62:	40a7853b          	subw	a0,a5,a0
     c66:	6422                	ld	s0,8(sp)
     c68:	0141                	addi	sp,sp,16
     c6a:	8082                	ret

0000000000000c6c <strlen>:

uint
strlen(const char *s)
{
     c6c:	1141                	addi	sp,sp,-16
     c6e:	e422                	sd	s0,8(sp)
     c70:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     c72:	00054783          	lbu	a5,0(a0)
     c76:	cf91                	beqz	a5,c92 <strlen+0x26>
     c78:	0505                	addi	a0,a0,1
     c7a:	87aa                	mv	a5,a0
     c7c:	4685                	li	a3,1
     c7e:	9e89                	subw	a3,a3,a0
     c80:	00f6853b          	addw	a0,a3,a5
     c84:	0785                	addi	a5,a5,1
     c86:	fff7c703          	lbu	a4,-1(a5)
     c8a:	fb7d                	bnez	a4,c80 <strlen+0x14>
    ;
  return n;
}
     c8c:	6422                	ld	s0,8(sp)
     c8e:	0141                	addi	sp,sp,16
     c90:	8082                	ret
  for(n = 0; s[n]; n++)
     c92:	4501                	li	a0,0
     c94:	bfe5                	j	c8c <strlen+0x20>

0000000000000c96 <memset>:

void*
memset(void *dst, int c, uint n)
{
     c96:	1141                	addi	sp,sp,-16
     c98:	e422                	sd	s0,8(sp)
     c9a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     c9c:	ca19                	beqz	a2,cb2 <memset+0x1c>
     c9e:	87aa                	mv	a5,a0
     ca0:	1602                	slli	a2,a2,0x20
     ca2:	9201                	srli	a2,a2,0x20
     ca4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
     ca8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     cac:	0785                	addi	a5,a5,1
     cae:	fee79de3          	bne	a5,a4,ca8 <memset+0x12>
  }
  return dst;
}
     cb2:	6422                	ld	s0,8(sp)
     cb4:	0141                	addi	sp,sp,16
     cb6:	8082                	ret

0000000000000cb8 <strchr>:

char*
strchr(const char *s, char c)
{
     cb8:	1141                	addi	sp,sp,-16
     cba:	e422                	sd	s0,8(sp)
     cbc:	0800                	addi	s0,sp,16
  for(; *s; s++)
     cbe:	00054783          	lbu	a5,0(a0)
     cc2:	cb99                	beqz	a5,cd8 <strchr+0x20>
    if(*s == c)
     cc4:	00f58763          	beq	a1,a5,cd2 <strchr+0x1a>
  for(; *s; s++)
     cc8:	0505                	addi	a0,a0,1
     cca:	00054783          	lbu	a5,0(a0)
     cce:	fbfd                	bnez	a5,cc4 <strchr+0xc>
      return (char*)s;
  return 0;
     cd0:	4501                	li	a0,0
}
     cd2:	6422                	ld	s0,8(sp)
     cd4:	0141                	addi	sp,sp,16
     cd6:	8082                	ret
  return 0;
     cd8:	4501                	li	a0,0
     cda:	bfe5                	j	cd2 <strchr+0x1a>

0000000000000cdc <gets>:

char*
gets(char *buf, int max)
{
     cdc:	711d                	addi	sp,sp,-96
     cde:	ec86                	sd	ra,88(sp)
     ce0:	e8a2                	sd	s0,80(sp)
     ce2:	e4a6                	sd	s1,72(sp)
     ce4:	e0ca                	sd	s2,64(sp)
     ce6:	fc4e                	sd	s3,56(sp)
     ce8:	f852                	sd	s4,48(sp)
     cea:	f456                	sd	s5,40(sp)
     cec:	f05a                	sd	s6,32(sp)
     cee:	ec5e                	sd	s7,24(sp)
     cf0:	1080                	addi	s0,sp,96
     cf2:	8baa                	mv	s7,a0
     cf4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     cf6:	892a                	mv	s2,a0
     cf8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     cfa:	4aa9                	li	s5,10
     cfc:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     cfe:	89a6                	mv	s3,s1
     d00:	2485                	addiw	s1,s1,1
     d02:	0344d863          	bge	s1,s4,d32 <gets+0x56>
    cc = read(0, &c, 1);
     d06:	4605                	li	a2,1
     d08:	faf40593          	addi	a1,s0,-81
     d0c:	4501                	li	a0,0
     d0e:	00000097          	auipc	ra,0x0
     d12:	19c080e7          	jalr	412(ra) # eaa <read>
    if(cc < 1)
     d16:	00a05e63          	blez	a0,d32 <gets+0x56>
    buf[i++] = c;
     d1a:	faf44783          	lbu	a5,-81(s0)
     d1e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     d22:	01578763          	beq	a5,s5,d30 <gets+0x54>
     d26:	0905                	addi	s2,s2,1
     d28:	fd679be3          	bne	a5,s6,cfe <gets+0x22>
  for(i=0; i+1 < max; ){
     d2c:	89a6                	mv	s3,s1
     d2e:	a011                	j	d32 <gets+0x56>
     d30:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     d32:	99de                	add	s3,s3,s7
     d34:	00098023          	sb	zero,0(s3)
  return buf;
}
     d38:	855e                	mv	a0,s7
     d3a:	60e6                	ld	ra,88(sp)
     d3c:	6446                	ld	s0,80(sp)
     d3e:	64a6                	ld	s1,72(sp)
     d40:	6906                	ld	s2,64(sp)
     d42:	79e2                	ld	s3,56(sp)
     d44:	7a42                	ld	s4,48(sp)
     d46:	7aa2                	ld	s5,40(sp)
     d48:	7b02                	ld	s6,32(sp)
     d4a:	6be2                	ld	s7,24(sp)
     d4c:	6125                	addi	sp,sp,96
     d4e:	8082                	ret

0000000000000d50 <stat>:

int
stat(const char *n, struct stat *st)
{
     d50:	1101                	addi	sp,sp,-32
     d52:	ec06                	sd	ra,24(sp)
     d54:	e822                	sd	s0,16(sp)
     d56:	e426                	sd	s1,8(sp)
     d58:	e04a                	sd	s2,0(sp)
     d5a:	1000                	addi	s0,sp,32
     d5c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     d5e:	4581                	li	a1,0
     d60:	00000097          	auipc	ra,0x0
     d64:	172080e7          	jalr	370(ra) # ed2 <open>
  if(fd < 0)
     d68:	02054563          	bltz	a0,d92 <stat+0x42>
     d6c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     d6e:	85ca                	mv	a1,s2
     d70:	00000097          	auipc	ra,0x0
     d74:	17a080e7          	jalr	378(ra) # eea <fstat>
     d78:	892a                	mv	s2,a0
  close(fd);
     d7a:	8526                	mv	a0,s1
     d7c:	00000097          	auipc	ra,0x0
     d80:	13e080e7          	jalr	318(ra) # eba <close>
  return r;
}
     d84:	854a                	mv	a0,s2
     d86:	60e2                	ld	ra,24(sp)
     d88:	6442                	ld	s0,16(sp)
     d8a:	64a2                	ld	s1,8(sp)
     d8c:	6902                	ld	s2,0(sp)
     d8e:	6105                	addi	sp,sp,32
     d90:	8082                	ret
    return -1;
     d92:	597d                	li	s2,-1
     d94:	bfc5                	j	d84 <stat+0x34>

0000000000000d96 <atoi>:

int
atoi(const char *s)
{
     d96:	1141                	addi	sp,sp,-16
     d98:	e422                	sd	s0,8(sp)
     d9a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     d9c:	00054603          	lbu	a2,0(a0)
     da0:	fd06079b          	addiw	a5,a2,-48
     da4:	0ff7f793          	andi	a5,a5,255
     da8:	4725                	li	a4,9
     daa:	02f76963          	bltu	a4,a5,ddc <atoi+0x46>
     dae:	86aa                	mv	a3,a0
  n = 0;
     db0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     db2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     db4:	0685                	addi	a3,a3,1
     db6:	0025179b          	slliw	a5,a0,0x2
     dba:	9fa9                	addw	a5,a5,a0
     dbc:	0017979b          	slliw	a5,a5,0x1
     dc0:	9fb1                	addw	a5,a5,a2
     dc2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     dc6:	0006c603          	lbu	a2,0(a3)
     dca:	fd06071b          	addiw	a4,a2,-48
     dce:	0ff77713          	andi	a4,a4,255
     dd2:	fee5f1e3          	bgeu	a1,a4,db4 <atoi+0x1e>
  return n;
}
     dd6:	6422                	ld	s0,8(sp)
     dd8:	0141                	addi	sp,sp,16
     dda:	8082                	ret
  n = 0;
     ddc:	4501                	li	a0,0
     dde:	bfe5                	j	dd6 <atoi+0x40>

0000000000000de0 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     de0:	1141                	addi	sp,sp,-16
     de2:	e422                	sd	s0,8(sp)
     de4:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     de6:	02b57463          	bgeu	a0,a1,e0e <memmove+0x2e>
    while(n-- > 0)
     dea:	00c05f63          	blez	a2,e08 <memmove+0x28>
     dee:	1602                	slli	a2,a2,0x20
     df0:	9201                	srli	a2,a2,0x20
     df2:	00c507b3          	add	a5,a0,a2
  dst = vdst;
     df6:	872a                	mv	a4,a0
      *dst++ = *src++;
     df8:	0585                	addi	a1,a1,1
     dfa:	0705                	addi	a4,a4,1
     dfc:	fff5c683          	lbu	a3,-1(a1)
     e00:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     e04:	fee79ae3          	bne	a5,a4,df8 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     e08:	6422                	ld	s0,8(sp)
     e0a:	0141                	addi	sp,sp,16
     e0c:	8082                	ret
    dst += n;
     e0e:	00c50733          	add	a4,a0,a2
    src += n;
     e12:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     e14:	fec05ae3          	blez	a2,e08 <memmove+0x28>
     e18:	fff6079b          	addiw	a5,a2,-1
     e1c:	1782                	slli	a5,a5,0x20
     e1e:	9381                	srli	a5,a5,0x20
     e20:	fff7c793          	not	a5,a5
     e24:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     e26:	15fd                	addi	a1,a1,-1
     e28:	177d                	addi	a4,a4,-1
     e2a:	0005c683          	lbu	a3,0(a1)
     e2e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     e32:	fee79ae3          	bne	a5,a4,e26 <memmove+0x46>
     e36:	bfc9                	j	e08 <memmove+0x28>

0000000000000e38 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     e38:	1141                	addi	sp,sp,-16
     e3a:	e422                	sd	s0,8(sp)
     e3c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     e3e:	ca05                	beqz	a2,e6e <memcmp+0x36>
     e40:	fff6069b          	addiw	a3,a2,-1
     e44:	1682                	slli	a3,a3,0x20
     e46:	9281                	srli	a3,a3,0x20
     e48:	0685                	addi	a3,a3,1
     e4a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     e4c:	00054783          	lbu	a5,0(a0)
     e50:	0005c703          	lbu	a4,0(a1)
     e54:	00e79863          	bne	a5,a4,e64 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     e58:	0505                	addi	a0,a0,1
    p2++;
     e5a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     e5c:	fed518e3          	bne	a0,a3,e4c <memcmp+0x14>
  }
  return 0;
     e60:	4501                	li	a0,0
     e62:	a019                	j	e68 <memcmp+0x30>
      return *p1 - *p2;
     e64:	40e7853b          	subw	a0,a5,a4
}
     e68:	6422                	ld	s0,8(sp)
     e6a:	0141                	addi	sp,sp,16
     e6c:	8082                	ret
  return 0;
     e6e:	4501                	li	a0,0
     e70:	bfe5                	j	e68 <memcmp+0x30>

0000000000000e72 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     e72:	1141                	addi	sp,sp,-16
     e74:	e406                	sd	ra,8(sp)
     e76:	e022                	sd	s0,0(sp)
     e78:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     e7a:	00000097          	auipc	ra,0x0
     e7e:	f66080e7          	jalr	-154(ra) # de0 <memmove>
}
     e82:	60a2                	ld	ra,8(sp)
     e84:	6402                	ld	s0,0(sp)
     e86:	0141                	addi	sp,sp,16
     e88:	8082                	ret

0000000000000e8a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     e8a:	4885                	li	a7,1
 ecall
     e8c:	00000073          	ecall
 ret
     e90:	8082                	ret

0000000000000e92 <exit>:
.global exit
exit:
 li a7, SYS_exit
     e92:	4889                	li	a7,2
 ecall
     e94:	00000073          	ecall
 ret
     e98:	8082                	ret

0000000000000e9a <wait>:
.global wait
wait:
 li a7, SYS_wait
     e9a:	488d                	li	a7,3
 ecall
     e9c:	00000073          	ecall
 ret
     ea0:	8082                	ret

0000000000000ea2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     ea2:	4891                	li	a7,4
 ecall
     ea4:	00000073          	ecall
 ret
     ea8:	8082                	ret

0000000000000eaa <read>:
.global read
read:
 li a7, SYS_read
     eaa:	4895                	li	a7,5
 ecall
     eac:	00000073          	ecall
 ret
     eb0:	8082                	ret

0000000000000eb2 <write>:
.global write
write:
 li a7, SYS_write
     eb2:	48c1                	li	a7,16
 ecall
     eb4:	00000073          	ecall
 ret
     eb8:	8082                	ret

0000000000000eba <close>:
.global close
close:
 li a7, SYS_close
     eba:	48d5                	li	a7,21
 ecall
     ebc:	00000073          	ecall
 ret
     ec0:	8082                	ret

0000000000000ec2 <kill>:
.global kill
kill:
 li a7, SYS_kill
     ec2:	4899                	li	a7,6
 ecall
     ec4:	00000073          	ecall
 ret
     ec8:	8082                	ret

0000000000000eca <exec>:
.global exec
exec:
 li a7, SYS_exec
     eca:	489d                	li	a7,7
 ecall
     ecc:	00000073          	ecall
 ret
     ed0:	8082                	ret

0000000000000ed2 <open>:
.global open
open:
 li a7, SYS_open
     ed2:	48bd                	li	a7,15
 ecall
     ed4:	00000073          	ecall
 ret
     ed8:	8082                	ret

0000000000000eda <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     eda:	48c5                	li	a7,17
 ecall
     edc:	00000073          	ecall
 ret
     ee0:	8082                	ret

0000000000000ee2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     ee2:	48c9                	li	a7,18
 ecall
     ee4:	00000073          	ecall
 ret
     ee8:	8082                	ret

0000000000000eea <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     eea:	48a1                	li	a7,8
 ecall
     eec:	00000073          	ecall
 ret
     ef0:	8082                	ret

0000000000000ef2 <link>:
.global link
link:
 li a7, SYS_link
     ef2:	48cd                	li	a7,19
 ecall
     ef4:	00000073          	ecall
 ret
     ef8:	8082                	ret

0000000000000efa <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     efa:	48d1                	li	a7,20
 ecall
     efc:	00000073          	ecall
 ret
     f00:	8082                	ret

0000000000000f02 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     f02:	48a5                	li	a7,9
 ecall
     f04:	00000073          	ecall
 ret
     f08:	8082                	ret

0000000000000f0a <dup>:
.global dup
dup:
 li a7, SYS_dup
     f0a:	48a9                	li	a7,10
 ecall
     f0c:	00000073          	ecall
 ret
     f10:	8082                	ret

0000000000000f12 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     f12:	48ad                	li	a7,11
 ecall
     f14:	00000073          	ecall
 ret
     f18:	8082                	ret

0000000000000f1a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     f1a:	48b1                	li	a7,12
 ecall
     f1c:	00000073          	ecall
 ret
     f20:	8082                	ret

0000000000000f22 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     f22:	48b5                	li	a7,13
 ecall
     f24:	00000073          	ecall
 ret
     f28:	8082                	ret

0000000000000f2a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     f2a:	48b9                	li	a7,14
 ecall
     f2c:	00000073          	ecall
 ret
     f30:	8082                	ret

0000000000000f32 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     f32:	1101                	addi	sp,sp,-32
     f34:	ec06                	sd	ra,24(sp)
     f36:	e822                	sd	s0,16(sp)
     f38:	1000                	addi	s0,sp,32
     f3a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     f3e:	4605                	li	a2,1
     f40:	fef40593          	addi	a1,s0,-17
     f44:	00000097          	auipc	ra,0x0
     f48:	f6e080e7          	jalr	-146(ra) # eb2 <write>
}
     f4c:	60e2                	ld	ra,24(sp)
     f4e:	6442                	ld	s0,16(sp)
     f50:	6105                	addi	sp,sp,32
     f52:	8082                	ret

0000000000000f54 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     f54:	7139                	addi	sp,sp,-64
     f56:	fc06                	sd	ra,56(sp)
     f58:	f822                	sd	s0,48(sp)
     f5a:	f426                	sd	s1,40(sp)
     f5c:	f04a                	sd	s2,32(sp)
     f5e:	ec4e                	sd	s3,24(sp)
     f60:	0080                	addi	s0,sp,64
     f62:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     f64:	c299                	beqz	a3,f6a <printint+0x16>
     f66:	0805c863          	bltz	a1,ff6 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     f6a:	2581                	sext.w	a1,a1
  neg = 0;
     f6c:	4881                	li	a7,0
     f6e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     f72:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     f74:	2601                	sext.w	a2,a2
     f76:	00000517          	auipc	a0,0x0
     f7a:	59a50513          	addi	a0,a0,1434 # 1510 <digits>
     f7e:	883a                	mv	a6,a4
     f80:	2705                	addiw	a4,a4,1
     f82:	02c5f7bb          	remuw	a5,a1,a2
     f86:	1782                	slli	a5,a5,0x20
     f88:	9381                	srli	a5,a5,0x20
     f8a:	97aa                	add	a5,a5,a0
     f8c:	0007c783          	lbu	a5,0(a5)
     f90:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     f94:	0005879b          	sext.w	a5,a1
     f98:	02c5d5bb          	divuw	a1,a1,a2
     f9c:	0685                	addi	a3,a3,1
     f9e:	fec7f0e3          	bgeu	a5,a2,f7e <printint+0x2a>
  if(neg)
     fa2:	00088b63          	beqz	a7,fb8 <printint+0x64>
    buf[i++] = '-';
     fa6:	fd040793          	addi	a5,s0,-48
     faa:	973e                	add	a4,a4,a5
     fac:	02d00793          	li	a5,45
     fb0:	fef70823          	sb	a5,-16(a4)
     fb4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     fb8:	02e05863          	blez	a4,fe8 <printint+0x94>
     fbc:	fc040793          	addi	a5,s0,-64
     fc0:	00e78933          	add	s2,a5,a4
     fc4:	fff78993          	addi	s3,a5,-1
     fc8:	99ba                	add	s3,s3,a4
     fca:	377d                	addiw	a4,a4,-1
     fcc:	1702                	slli	a4,a4,0x20
     fce:	9301                	srli	a4,a4,0x20
     fd0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     fd4:	fff94583          	lbu	a1,-1(s2)
     fd8:	8526                	mv	a0,s1
     fda:	00000097          	auipc	ra,0x0
     fde:	f58080e7          	jalr	-168(ra) # f32 <putc>
  while(--i >= 0)
     fe2:	197d                	addi	s2,s2,-1
     fe4:	ff3918e3          	bne	s2,s3,fd4 <printint+0x80>
}
     fe8:	70e2                	ld	ra,56(sp)
     fea:	7442                	ld	s0,48(sp)
     fec:	74a2                	ld	s1,40(sp)
     fee:	7902                	ld	s2,32(sp)
     ff0:	69e2                	ld	s3,24(sp)
     ff2:	6121                	addi	sp,sp,64
     ff4:	8082                	ret
    x = -xx;
     ff6:	40b005bb          	negw	a1,a1
    neg = 1;
     ffa:	4885                	li	a7,1
    x = -xx;
     ffc:	bf8d                	j	f6e <printint+0x1a>

0000000000000ffe <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
     ffe:	7119                	addi	sp,sp,-128
    1000:	fc86                	sd	ra,120(sp)
    1002:	f8a2                	sd	s0,112(sp)
    1004:	f4a6                	sd	s1,104(sp)
    1006:	f0ca                	sd	s2,96(sp)
    1008:	ecce                	sd	s3,88(sp)
    100a:	e8d2                	sd	s4,80(sp)
    100c:	e4d6                	sd	s5,72(sp)
    100e:	e0da                	sd	s6,64(sp)
    1010:	fc5e                	sd	s7,56(sp)
    1012:	f862                	sd	s8,48(sp)
    1014:	f466                	sd	s9,40(sp)
    1016:	f06a                	sd	s10,32(sp)
    1018:	ec6e                	sd	s11,24(sp)
    101a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    101c:	0005c903          	lbu	s2,0(a1)
    1020:	18090f63          	beqz	s2,11be <vprintf+0x1c0>
    1024:	8aaa                	mv	s5,a0
    1026:	8b32                	mv	s6,a2
    1028:	00158493          	addi	s1,a1,1
  state = 0;
    102c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    102e:	02500a13          	li	s4,37
      if(c == 'd'){
    1032:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    1036:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    103a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    103e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    1042:	00000b97          	auipc	s7,0x0
    1046:	4ceb8b93          	addi	s7,s7,1230 # 1510 <digits>
    104a:	a839                	j	1068 <vprintf+0x6a>
        putc(fd, c);
    104c:	85ca                	mv	a1,s2
    104e:	8556                	mv	a0,s5
    1050:	00000097          	auipc	ra,0x0
    1054:	ee2080e7          	jalr	-286(ra) # f32 <putc>
    1058:	a019                	j	105e <vprintf+0x60>
    } else if(state == '%'){
    105a:	01498f63          	beq	s3,s4,1078 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    105e:	0485                	addi	s1,s1,1
    1060:	fff4c903          	lbu	s2,-1(s1)
    1064:	14090d63          	beqz	s2,11be <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    1068:	0009079b          	sext.w	a5,s2
    if(state == 0){
    106c:	fe0997e3          	bnez	s3,105a <vprintf+0x5c>
      if(c == '%'){
    1070:	fd479ee3          	bne	a5,s4,104c <vprintf+0x4e>
        state = '%';
    1074:	89be                	mv	s3,a5
    1076:	b7e5                	j	105e <vprintf+0x60>
      if(c == 'd'){
    1078:	05878063          	beq	a5,s8,10b8 <vprintf+0xba>
      } else if(c == 'l') {
    107c:	05978c63          	beq	a5,s9,10d4 <vprintf+0xd6>
      } else if(c == 'x') {
    1080:	07a78863          	beq	a5,s10,10f0 <vprintf+0xf2>
      } else if(c == 'p') {
    1084:	09b78463          	beq	a5,s11,110c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    1088:	07300713          	li	a4,115
    108c:	0ce78663          	beq	a5,a4,1158 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    1090:	06300713          	li	a4,99
    1094:	0ee78e63          	beq	a5,a4,1190 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    1098:	11478863          	beq	a5,s4,11a8 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    109c:	85d2                	mv	a1,s4
    109e:	8556                	mv	a0,s5
    10a0:	00000097          	auipc	ra,0x0
    10a4:	e92080e7          	jalr	-366(ra) # f32 <putc>
        putc(fd, c);
    10a8:	85ca                	mv	a1,s2
    10aa:	8556                	mv	a0,s5
    10ac:	00000097          	auipc	ra,0x0
    10b0:	e86080e7          	jalr	-378(ra) # f32 <putc>
      }
      state = 0;
    10b4:	4981                	li	s3,0
    10b6:	b765                	j	105e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    10b8:	008b0913          	addi	s2,s6,8
    10bc:	4685                	li	a3,1
    10be:	4629                	li	a2,10
    10c0:	000b2583          	lw	a1,0(s6)
    10c4:	8556                	mv	a0,s5
    10c6:	00000097          	auipc	ra,0x0
    10ca:	e8e080e7          	jalr	-370(ra) # f54 <printint>
    10ce:	8b4a                	mv	s6,s2
      state = 0;
    10d0:	4981                	li	s3,0
    10d2:	b771                	j	105e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    10d4:	008b0913          	addi	s2,s6,8
    10d8:	4681                	li	a3,0
    10da:	4629                	li	a2,10
    10dc:	000b2583          	lw	a1,0(s6)
    10e0:	8556                	mv	a0,s5
    10e2:	00000097          	auipc	ra,0x0
    10e6:	e72080e7          	jalr	-398(ra) # f54 <printint>
    10ea:	8b4a                	mv	s6,s2
      state = 0;
    10ec:	4981                	li	s3,0
    10ee:	bf85                	j	105e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    10f0:	008b0913          	addi	s2,s6,8
    10f4:	4681                	li	a3,0
    10f6:	4641                	li	a2,16
    10f8:	000b2583          	lw	a1,0(s6)
    10fc:	8556                	mv	a0,s5
    10fe:	00000097          	auipc	ra,0x0
    1102:	e56080e7          	jalr	-426(ra) # f54 <printint>
    1106:	8b4a                	mv	s6,s2
      state = 0;
    1108:	4981                	li	s3,0
    110a:	bf91                	j	105e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    110c:	008b0793          	addi	a5,s6,8
    1110:	f8f43423          	sd	a5,-120(s0)
    1114:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    1118:	03000593          	li	a1,48
    111c:	8556                	mv	a0,s5
    111e:	00000097          	auipc	ra,0x0
    1122:	e14080e7          	jalr	-492(ra) # f32 <putc>
  putc(fd, 'x');
    1126:	85ea                	mv	a1,s10
    1128:	8556                	mv	a0,s5
    112a:	00000097          	auipc	ra,0x0
    112e:	e08080e7          	jalr	-504(ra) # f32 <putc>
    1132:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    1134:	03c9d793          	srli	a5,s3,0x3c
    1138:	97de                	add	a5,a5,s7
    113a:	0007c583          	lbu	a1,0(a5)
    113e:	8556                	mv	a0,s5
    1140:	00000097          	auipc	ra,0x0
    1144:	df2080e7          	jalr	-526(ra) # f32 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    1148:	0992                	slli	s3,s3,0x4
    114a:	397d                	addiw	s2,s2,-1
    114c:	fe0914e3          	bnez	s2,1134 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    1150:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    1154:	4981                	li	s3,0
    1156:	b721                	j	105e <vprintf+0x60>
        s = va_arg(ap, char*);
    1158:	008b0993          	addi	s3,s6,8
    115c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    1160:	02090163          	beqz	s2,1182 <vprintf+0x184>
        while(*s != 0){
    1164:	00094583          	lbu	a1,0(s2)
    1168:	c9a1                	beqz	a1,11b8 <vprintf+0x1ba>
          putc(fd, *s);
    116a:	8556                	mv	a0,s5
    116c:	00000097          	auipc	ra,0x0
    1170:	dc6080e7          	jalr	-570(ra) # f32 <putc>
          s++;
    1174:	0905                	addi	s2,s2,1
        while(*s != 0){
    1176:	00094583          	lbu	a1,0(s2)
    117a:	f9e5                	bnez	a1,116a <vprintf+0x16c>
        s = va_arg(ap, char*);
    117c:	8b4e                	mv	s6,s3
      state = 0;
    117e:	4981                	li	s3,0
    1180:	bdf9                	j	105e <vprintf+0x60>
          s = "(null)";
    1182:	00000917          	auipc	s2,0x0
    1186:	38690913          	addi	s2,s2,902 # 1508 <malloc+0x240>
        while(*s != 0){
    118a:	02800593          	li	a1,40
    118e:	bff1                	j	116a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    1190:	008b0913          	addi	s2,s6,8
    1194:	000b4583          	lbu	a1,0(s6)
    1198:	8556                	mv	a0,s5
    119a:	00000097          	auipc	ra,0x0
    119e:	d98080e7          	jalr	-616(ra) # f32 <putc>
    11a2:	8b4a                	mv	s6,s2
      state = 0;
    11a4:	4981                	li	s3,0
    11a6:	bd65                	j	105e <vprintf+0x60>
        putc(fd, c);
    11a8:	85d2                	mv	a1,s4
    11aa:	8556                	mv	a0,s5
    11ac:	00000097          	auipc	ra,0x0
    11b0:	d86080e7          	jalr	-634(ra) # f32 <putc>
      state = 0;
    11b4:	4981                	li	s3,0
    11b6:	b565                	j	105e <vprintf+0x60>
        s = va_arg(ap, char*);
    11b8:	8b4e                	mv	s6,s3
      state = 0;
    11ba:	4981                	li	s3,0
    11bc:	b54d                	j	105e <vprintf+0x60>
    }
  }
}
    11be:	70e6                	ld	ra,120(sp)
    11c0:	7446                	ld	s0,112(sp)
    11c2:	74a6                	ld	s1,104(sp)
    11c4:	7906                	ld	s2,96(sp)
    11c6:	69e6                	ld	s3,88(sp)
    11c8:	6a46                	ld	s4,80(sp)
    11ca:	6aa6                	ld	s5,72(sp)
    11cc:	6b06                	ld	s6,64(sp)
    11ce:	7be2                	ld	s7,56(sp)
    11d0:	7c42                	ld	s8,48(sp)
    11d2:	7ca2                	ld	s9,40(sp)
    11d4:	7d02                	ld	s10,32(sp)
    11d6:	6de2                	ld	s11,24(sp)
    11d8:	6109                	addi	sp,sp,128
    11da:	8082                	ret

00000000000011dc <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    11dc:	715d                	addi	sp,sp,-80
    11de:	ec06                	sd	ra,24(sp)
    11e0:	e822                	sd	s0,16(sp)
    11e2:	1000                	addi	s0,sp,32
    11e4:	e010                	sd	a2,0(s0)
    11e6:	e414                	sd	a3,8(s0)
    11e8:	e818                	sd	a4,16(s0)
    11ea:	ec1c                	sd	a5,24(s0)
    11ec:	03043023          	sd	a6,32(s0)
    11f0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    11f4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    11f8:	8622                	mv	a2,s0
    11fa:	00000097          	auipc	ra,0x0
    11fe:	e04080e7          	jalr	-508(ra) # ffe <vprintf>
}
    1202:	60e2                	ld	ra,24(sp)
    1204:	6442                	ld	s0,16(sp)
    1206:	6161                	addi	sp,sp,80
    1208:	8082                	ret

000000000000120a <printf>:

void
printf(const char *fmt, ...)
{
    120a:	711d                	addi	sp,sp,-96
    120c:	ec06                	sd	ra,24(sp)
    120e:	e822                	sd	s0,16(sp)
    1210:	1000                	addi	s0,sp,32
    1212:	e40c                	sd	a1,8(s0)
    1214:	e810                	sd	a2,16(s0)
    1216:	ec14                	sd	a3,24(s0)
    1218:	f018                	sd	a4,32(s0)
    121a:	f41c                	sd	a5,40(s0)
    121c:	03043823          	sd	a6,48(s0)
    1220:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    1224:	00840613          	addi	a2,s0,8
    1228:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    122c:	85aa                	mv	a1,a0
    122e:	4505                	li	a0,1
    1230:	00000097          	auipc	ra,0x0
    1234:	dce080e7          	jalr	-562(ra) # ffe <vprintf>
}
    1238:	60e2                	ld	ra,24(sp)
    123a:	6442                	ld	s0,16(sp)
    123c:	6125                	addi	sp,sp,96
    123e:	8082                	ret

0000000000001240 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    1240:	1141                	addi	sp,sp,-16
    1242:	e422                	sd	s0,8(sp)
    1244:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1246:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    124a:	00000797          	auipc	a5,0x0
    124e:	2ee7b783          	ld	a5,750(a5) # 1538 <freep>
    1252:	a805                	j	1282 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    1254:	4618                	lw	a4,8(a2)
    1256:	9db9                	addw	a1,a1,a4
    1258:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    125c:	6398                	ld	a4,0(a5)
    125e:	6318                	ld	a4,0(a4)
    1260:	fee53823          	sd	a4,-16(a0)
    1264:	a091                	j	12a8 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1266:	ff852703          	lw	a4,-8(a0)
    126a:	9e39                	addw	a2,a2,a4
    126c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    126e:	ff053703          	ld	a4,-16(a0)
    1272:	e398                	sd	a4,0(a5)
    1274:	a099                	j	12ba <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1276:	6398                	ld	a4,0(a5)
    1278:	00e7e463          	bltu	a5,a4,1280 <free+0x40>
    127c:	00e6ea63          	bltu	a3,a4,1290 <free+0x50>
{
    1280:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1282:	fed7fae3          	bgeu	a5,a3,1276 <free+0x36>
    1286:	6398                	ld	a4,0(a5)
    1288:	00e6e463          	bltu	a3,a4,1290 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    128c:	fee7eae3          	bltu	a5,a4,1280 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    1290:	ff852583          	lw	a1,-8(a0)
    1294:	6390                	ld	a2,0(a5)
    1296:	02059813          	slli	a6,a1,0x20
    129a:	01c85713          	srli	a4,a6,0x1c
    129e:	9736                	add	a4,a4,a3
    12a0:	fae60ae3          	beq	a2,a4,1254 <free+0x14>
    bp->s.ptr = p->s.ptr;
    12a4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    12a8:	4790                	lw	a2,8(a5)
    12aa:	02061593          	slli	a1,a2,0x20
    12ae:	01c5d713          	srli	a4,a1,0x1c
    12b2:	973e                	add	a4,a4,a5
    12b4:	fae689e3          	beq	a3,a4,1266 <free+0x26>
  } else
    p->s.ptr = bp;
    12b8:	e394                	sd	a3,0(a5)
  freep = p;
    12ba:	00000717          	auipc	a4,0x0
    12be:	26f73f23          	sd	a5,638(a4) # 1538 <freep>
}
    12c2:	6422                	ld	s0,8(sp)
    12c4:	0141                	addi	sp,sp,16
    12c6:	8082                	ret

00000000000012c8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    12c8:	7139                	addi	sp,sp,-64
    12ca:	fc06                	sd	ra,56(sp)
    12cc:	f822                	sd	s0,48(sp)
    12ce:	f426                	sd	s1,40(sp)
    12d0:	f04a                	sd	s2,32(sp)
    12d2:	ec4e                	sd	s3,24(sp)
    12d4:	e852                	sd	s4,16(sp)
    12d6:	e456                	sd	s5,8(sp)
    12d8:	e05a                	sd	s6,0(sp)
    12da:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    12dc:	02051493          	slli	s1,a0,0x20
    12e0:	9081                	srli	s1,s1,0x20
    12e2:	04bd                	addi	s1,s1,15
    12e4:	8091                	srli	s1,s1,0x4
    12e6:	0014899b          	addiw	s3,s1,1
    12ea:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    12ec:	00000517          	auipc	a0,0x0
    12f0:	24c53503          	ld	a0,588(a0) # 1538 <freep>
    12f4:	c515                	beqz	a0,1320 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    12f6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    12f8:	4798                	lw	a4,8(a5)
    12fa:	02977f63          	bgeu	a4,s1,1338 <malloc+0x70>
    12fe:	8a4e                	mv	s4,s3
    1300:	0009871b          	sext.w	a4,s3
    1304:	6685                	lui	a3,0x1
    1306:	00d77363          	bgeu	a4,a3,130c <malloc+0x44>
    130a:	6a05                	lui	s4,0x1
    130c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    1310:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    1314:	00000917          	auipc	s2,0x0
    1318:	22490913          	addi	s2,s2,548 # 1538 <freep>
  if(p == (char*)-1)
    131c:	5afd                	li	s5,-1
    131e:	a895                	j	1392 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    1320:	00000797          	auipc	a5,0x0
    1324:	28878793          	addi	a5,a5,648 # 15a8 <base>
    1328:	00000717          	auipc	a4,0x0
    132c:	20f73823          	sd	a5,528(a4) # 1538 <freep>
    1330:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    1332:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    1336:	b7e1                	j	12fe <malloc+0x36>
      if(p->s.size == nunits)
    1338:	02e48c63          	beq	s1,a4,1370 <malloc+0xa8>
        p->s.size -= nunits;
    133c:	4137073b          	subw	a4,a4,s3
    1340:	c798                	sw	a4,8(a5)
        p += p->s.size;
    1342:	02071693          	slli	a3,a4,0x20
    1346:	01c6d713          	srli	a4,a3,0x1c
    134a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    134c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    1350:	00000717          	auipc	a4,0x0
    1354:	1ea73423          	sd	a0,488(a4) # 1538 <freep>
      return (void*)(p + 1);
    1358:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    135c:	70e2                	ld	ra,56(sp)
    135e:	7442                	ld	s0,48(sp)
    1360:	74a2                	ld	s1,40(sp)
    1362:	7902                	ld	s2,32(sp)
    1364:	69e2                	ld	s3,24(sp)
    1366:	6a42                	ld	s4,16(sp)
    1368:	6aa2                	ld	s5,8(sp)
    136a:	6b02                	ld	s6,0(sp)
    136c:	6121                	addi	sp,sp,64
    136e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    1370:	6398                	ld	a4,0(a5)
    1372:	e118                	sd	a4,0(a0)
    1374:	bff1                	j	1350 <malloc+0x88>
  hp->s.size = nu;
    1376:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    137a:	0541                	addi	a0,a0,16
    137c:	00000097          	auipc	ra,0x0
    1380:	ec4080e7          	jalr	-316(ra) # 1240 <free>
  return freep;
    1384:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1388:	d971                	beqz	a0,135c <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    138a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    138c:	4798                	lw	a4,8(a5)
    138e:	fa9775e3          	bgeu	a4,s1,1338 <malloc+0x70>
    if(p == freep)
    1392:	00093703          	ld	a4,0(s2)
    1396:	853e                	mv	a0,a5
    1398:	fef719e3          	bne	a4,a5,138a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    139c:	8552                	mv	a0,s4
    139e:	00000097          	auipc	ra,0x0
    13a2:	b7c080e7          	jalr	-1156(ra) # f1a <sbrk>
  if(p == (char*)-1)
    13a6:	fd5518e3          	bne	a0,s5,1376 <malloc+0xae>
        return 0;
    13aa:	4501                	li	a0,0
    13ac:	bf45                	j	135c <malloc+0x94>
