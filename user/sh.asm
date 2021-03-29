
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
      14:	37858593          	addi	a1,a1,888 # 1388 <malloc+0xe6>
      18:	4509                	li	a0,2
      1a:	00001097          	auipc	ra,0x1
      1e:	19c080e7          	jalr	412(ra) # 11b6 <fprintf>
  memset(buf, 0, nbuf);
      22:	864a                	mv	a2,s2
      24:	4581                	li	a1,0
      26:	8526                	mv	a0,s1
      28:	00001097          	auipc	ra,0x1
      2c:	c40080e7          	jalr	-960(ra) # c68 <memset>
  gets(buf, nbuf);
      30:	85ca                	mv	a1,s2
      32:	8526                	mv	a0,s1
      34:	00001097          	auipc	ra,0x1
      38:	c7a080e7          	jalr	-902(ra) # cae <gets>
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
      62:	33258593          	addi	a1,a1,818 # 1390 <malloc+0xee>
      66:	4509                	li	a0,2
      68:	00001097          	auipc	ra,0x1
      6c:	14e080e7          	jalr	334(ra) # 11b6 <fprintf>
  exit(1);
      70:	4505                	li	a0,1
      72:	00001097          	auipc	ra,0x1
      76:	df2080e7          	jalr	-526(ra) # e64 <exit>

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
      86:	dda080e7          	jalr	-550(ra) # e5c <fork>
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
      9c:	30050513          	addi	a0,a0,768 # 1398 <malloc+0xf6>
      a0:	00000097          	auipc	ra,0x0
      a4:	fb4080e7          	jalr	-76(ra) # 54 <panic>

00000000000000a8 <runcmd>:
{
      a8:	7131                	addi	sp,sp,-192
      aa:	fd06                	sd	ra,184(sp)
      ac:	f922                	sd	s0,176(sp)
      ae:	f526                	sd	s1,168(sp)
      b0:	f14a                	sd	s2,160(sp)
      b2:	ed4e                	sd	s3,152(sp)
      b4:	e952                	sd	s4,144(sp)
      b6:	e556                	sd	s5,136(sp)
      b8:	e15a                	sd	s6,128(sp)
      ba:	0180                	addi	s0,sp,192
  if(cmd == 0)
      bc:	c10d                	beqz	a0,de <runcmd+0x36>
      be:	84aa                	mv	s1,a0
  switch(cmd->type){
      c0:	4118                	lw	a4,0(a0)
      c2:	4795                	li	a5,5
      c4:	02e7e263          	bltu	a5,a4,e8 <runcmd+0x40>
      c8:	00056783          	lwu	a5,0(a0)
      cc:	078a                	slli	a5,a5,0x2
      ce:	00001717          	auipc	a4,0x1
      d2:	3d270713          	addi	a4,a4,978 # 14a0 <malloc+0x1fe>
      d6:	97ba                	add	a5,a5,a4
      d8:	439c                	lw	a5,0(a5)
      da:	97ba                	add	a5,a5,a4
      dc:	8782                	jr	a5
    exit(1);
      de:	4505                	li	a0,1
      e0:	00001097          	auipc	ra,0x1
      e4:	d84080e7          	jalr	-636(ra) # e64 <exit>
    panic("runcmd");
      e8:	00001517          	auipc	a0,0x1
      ec:	2b850513          	addi	a0,a0,696 # 13a0 <malloc+0xfe>
      f0:	00000097          	auipc	ra,0x0
      f4:	f64080e7          	jalr	-156(ra) # 54 <panic>
    if(ecmd->argv[0] == 0)
      f8:	6508                	ld	a0,8(a0)
      fa:	c905                	beqz	a0,12a <runcmd+0x82>
    exec(ecmd->argv[0], ecmd->argv);
      fc:	00848a93          	addi	s5,s1,8
     100:	85d6                	mv	a1,s5
     102:	00001097          	auipc	ra,0x1
     106:	d9a080e7          	jalr	-614(ra) # e9c <exec>
    int fd = open("/path", O_CREATE | O_RDONLY);
     10a:	20000593          	li	a1,512
     10e:	00001517          	auipc	a0,0x1
     112:	29a50513          	addi	a0,a0,666 # 13a8 <malloc+0x106>
     116:	00001097          	auipc	ra,0x1
     11a:	d8e080e7          	jalr	-626(ra) # ea4 <open>
     11e:	89aa                	mv	s3,a0
    int i = 0;
     120:	4901                	li	s2,0
      if(*reader != ':'){
     122:	03a00a13          	li	s4,58
        i=0;
     126:	4b01                	li	s6,0
    while (read (fd, reader, 1) != 0){
     128:	a881                	j	178 <runcmd+0xd0>
      exit(1);
     12a:	4505                	li	a0,1
     12c:	00001097          	auipc	ra,0x1
     130:	d38080e7          	jalr	-712(ra) # e64 <exit>
        char* tmpexec = ecmd->argv[0];
     134:	648c                	ld	a1,8(s1)
        while (*tmpexec!= '\0'){
     136:	0005c703          	lbu	a4,0(a1)
     13a:	c315                	beqz	a4,15e <runcmd+0xb6>
     13c:	f5040793          	addi	a5,s0,-176
     140:	01278633          	add	a2,a5,s2
        char* tmpexec = ecmd->argv[0];
     144:	87ae                	mv	a5,a1
          newPath[i]=*tmpexec;
     146:	00e60023          	sb	a4,0(a2)
          tmpexec++;
     14a:	0785                	addi	a5,a5,1
          i++;
     14c:	40b7873b          	subw	a4,a5,a1
     150:	012706bb          	addw	a3,a4,s2
        while (*tmpexec!= '\0'){
     154:	0007c703          	lbu	a4,0(a5)
     158:	0605                	addi	a2,a2,1
     15a:	f775                	bnez	a4,146 <runcmd+0x9e>
          i++;
     15c:	8936                	mv	s2,a3
        newPath[i]='\0';
     15e:	fc040793          	addi	a5,s0,-64
     162:	993e                	add	s2,s2,a5
     164:	f8090823          	sb	zero,-112(s2)
        exec(newPath, ecmd->argv);
     168:	85d6                	mv	a1,s5
     16a:	f5040513          	addi	a0,s0,-176
     16e:	00001097          	auipc	ra,0x1
     172:	d2e080e7          	jalr	-722(ra) # e9c <exec>
        i=0;
     176:	895a                	mv	s2,s6
    while (read (fd, reader, 1) != 0){
     178:	4605                	li	a2,1
     17a:	f4840593          	addi	a1,s0,-184
     17e:	854e                	mv	a0,s3
     180:	00001097          	auipc	ra,0x1
     184:	cfc080e7          	jalr	-772(ra) # e7c <read>
     188:	cd01                	beqz	a0,1a0 <runcmd+0xf8>
      if(*reader != ':'){
     18a:	f4844783          	lbu	a5,-184(s0)
     18e:	fb4783e3          	beq	a5,s4,134 <runcmd+0x8c>
        newPath[i] = *reader;
     192:	fc040713          	addi	a4,s0,-64
     196:	974a                	add	a4,a4,s2
     198:	f8f70823          	sb	a5,-112(a4)
        i++;
     19c:	2905                	addiw	s2,s2,1
     19e:	bfe9                	j	178 <runcmd+0xd0>
    fprintf(2, "exec %s failed\n", ecmd->argv[0]);
     1a0:	6490                	ld	a2,8(s1)
     1a2:	00001597          	auipc	a1,0x1
     1a6:	20e58593          	addi	a1,a1,526 # 13b0 <malloc+0x10e>
     1aa:	4509                	li	a0,2
     1ac:	00001097          	auipc	ra,0x1
     1b0:	00a080e7          	jalr	10(ra) # 11b6 <fprintf>
    close (fd);
     1b4:	854e                	mv	a0,s3
     1b6:	00001097          	auipc	ra,0x1
     1ba:	cd6080e7          	jalr	-810(ra) # e8c <close>
  exit(0);
     1be:	4501                	li	a0,0
     1c0:	00001097          	auipc	ra,0x1
     1c4:	ca4080e7          	jalr	-860(ra) # e64 <exit>
    close(rcmd->fd);
     1c8:	5148                	lw	a0,36(a0)
     1ca:	00001097          	auipc	ra,0x1
     1ce:	cc2080e7          	jalr	-830(ra) # e8c <close>
    if(open(rcmd->file, rcmd->mode) < 0){
     1d2:	508c                	lw	a1,32(s1)
     1d4:	6888                	ld	a0,16(s1)
     1d6:	00001097          	auipc	ra,0x1
     1da:	cce080e7          	jalr	-818(ra) # ea4 <open>
     1de:	00054763          	bltz	a0,1ec <runcmd+0x144>
    runcmd(rcmd->cmd);
     1e2:	6488                	ld	a0,8(s1)
     1e4:	00000097          	auipc	ra,0x0
     1e8:	ec4080e7          	jalr	-316(ra) # a8 <runcmd>
      fprintf(2, "open %s failed\n", rcmd->file);
     1ec:	6890                	ld	a2,16(s1)
     1ee:	00001597          	auipc	a1,0x1
     1f2:	1d258593          	addi	a1,a1,466 # 13c0 <malloc+0x11e>
     1f6:	4509                	li	a0,2
     1f8:	00001097          	auipc	ra,0x1
     1fc:	fbe080e7          	jalr	-66(ra) # 11b6 <fprintf>
      exit(1);
     200:	4505                	li	a0,1
     202:	00001097          	auipc	ra,0x1
     206:	c62080e7          	jalr	-926(ra) # e64 <exit>
    if(fork1() == 0)
     20a:	00000097          	auipc	ra,0x0
     20e:	e70080e7          	jalr	-400(ra) # 7a <fork1>
     212:	c919                	beqz	a0,228 <runcmd+0x180>
    wait(0);
     214:	4501                	li	a0,0
     216:	00001097          	auipc	ra,0x1
     21a:	c56080e7          	jalr	-938(ra) # e6c <wait>
    runcmd(lcmd->right);
     21e:	6888                	ld	a0,16(s1)
     220:	00000097          	auipc	ra,0x0
     224:	e88080e7          	jalr	-376(ra) # a8 <runcmd>
      runcmd(lcmd->left);
     228:	6488                	ld	a0,8(s1)
     22a:	00000097          	auipc	ra,0x0
     22e:	e7e080e7          	jalr	-386(ra) # a8 <runcmd>
    if(pipe(p) < 0)
     232:	fb840513          	addi	a0,s0,-72
     236:	00001097          	auipc	ra,0x1
     23a:	c3e080e7          	jalr	-962(ra) # e74 <pipe>
     23e:	04054363          	bltz	a0,284 <runcmd+0x1dc>
    if(fork1() == 0){
     242:	00000097          	auipc	ra,0x0
     246:	e38080e7          	jalr	-456(ra) # 7a <fork1>
     24a:	c529                	beqz	a0,294 <runcmd+0x1ec>
    if(fork1() == 0){
     24c:	00000097          	auipc	ra,0x0
     250:	e2e080e7          	jalr	-466(ra) # 7a <fork1>
     254:	cd25                	beqz	a0,2cc <runcmd+0x224>
    close(p[0]);
     256:	fb842503          	lw	a0,-72(s0)
     25a:	00001097          	auipc	ra,0x1
     25e:	c32080e7          	jalr	-974(ra) # e8c <close>
    close(p[1]);
     262:	fbc42503          	lw	a0,-68(s0)
     266:	00001097          	auipc	ra,0x1
     26a:	c26080e7          	jalr	-986(ra) # e8c <close>
    wait(0);
     26e:	4501                	li	a0,0
     270:	00001097          	auipc	ra,0x1
     274:	bfc080e7          	jalr	-1028(ra) # e6c <wait>
    wait(0);
     278:	4501                	li	a0,0
     27a:	00001097          	auipc	ra,0x1
     27e:	bf2080e7          	jalr	-1038(ra) # e6c <wait>
    break;
     282:	bf35                	j	1be <runcmd+0x116>
      panic("pipe");
     284:	00001517          	auipc	a0,0x1
     288:	14c50513          	addi	a0,a0,332 # 13d0 <malloc+0x12e>
     28c:	00000097          	auipc	ra,0x0
     290:	dc8080e7          	jalr	-568(ra) # 54 <panic>
      close(1);
     294:	4505                	li	a0,1
     296:	00001097          	auipc	ra,0x1
     29a:	bf6080e7          	jalr	-1034(ra) # e8c <close>
      dup(p[1]);
     29e:	fbc42503          	lw	a0,-68(s0)
     2a2:	00001097          	auipc	ra,0x1
     2a6:	c3a080e7          	jalr	-966(ra) # edc <dup>
      close(p[0]);
     2aa:	fb842503          	lw	a0,-72(s0)
     2ae:	00001097          	auipc	ra,0x1
     2b2:	bde080e7          	jalr	-1058(ra) # e8c <close>
      close(p[1]);
     2b6:	fbc42503          	lw	a0,-68(s0)
     2ba:	00001097          	auipc	ra,0x1
     2be:	bd2080e7          	jalr	-1070(ra) # e8c <close>
      runcmd(pcmd->left);
     2c2:	6488                	ld	a0,8(s1)
     2c4:	00000097          	auipc	ra,0x0
     2c8:	de4080e7          	jalr	-540(ra) # a8 <runcmd>
      close(0);
     2cc:	00001097          	auipc	ra,0x1
     2d0:	bc0080e7          	jalr	-1088(ra) # e8c <close>
      dup(p[0]);
     2d4:	fb842503          	lw	a0,-72(s0)
     2d8:	00001097          	auipc	ra,0x1
     2dc:	c04080e7          	jalr	-1020(ra) # edc <dup>
      close(p[0]);
     2e0:	fb842503          	lw	a0,-72(s0)
     2e4:	00001097          	auipc	ra,0x1
     2e8:	ba8080e7          	jalr	-1112(ra) # e8c <close>
      close(p[1]);
     2ec:	fbc42503          	lw	a0,-68(s0)
     2f0:	00001097          	auipc	ra,0x1
     2f4:	b9c080e7          	jalr	-1124(ra) # e8c <close>
      runcmd(pcmd->right);
     2f8:	6888                	ld	a0,16(s1)
     2fa:	00000097          	auipc	ra,0x0
     2fe:	dae080e7          	jalr	-594(ra) # a8 <runcmd>
    if(fork1() == 0)
     302:	00000097          	auipc	ra,0x0
     306:	d78080e7          	jalr	-648(ra) # 7a <fork1>
     30a:	ea051ae3          	bnez	a0,1be <runcmd+0x116>
      runcmd(bcmd->cmd);
     30e:	6488                	ld	a0,8(s1)
     310:	00000097          	auipc	ra,0x0
     314:	d98080e7          	jalr	-616(ra) # a8 <runcmd>

0000000000000318 <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd*
execcmd(void)
{
     318:	1101                	addi	sp,sp,-32
     31a:	ec06                	sd	ra,24(sp)
     31c:	e822                	sd	s0,16(sp)
     31e:	e426                	sd	s1,8(sp)
     320:	1000                	addi	s0,sp,32
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     322:	0a800513          	li	a0,168
     326:	00001097          	auipc	ra,0x1
     32a:	f7c080e7          	jalr	-132(ra) # 12a2 <malloc>
     32e:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     330:	0a800613          	li	a2,168
     334:	4581                	li	a1,0
     336:	00001097          	auipc	ra,0x1
     33a:	932080e7          	jalr	-1742(ra) # c68 <memset>
  cmd->type = EXEC;
     33e:	4785                	li	a5,1
     340:	c09c                	sw	a5,0(s1)
  return (struct cmd*)cmd;
}
     342:	8526                	mv	a0,s1
     344:	60e2                	ld	ra,24(sp)
     346:	6442                	ld	s0,16(sp)
     348:	64a2                	ld	s1,8(sp)
     34a:	6105                	addi	sp,sp,32
     34c:	8082                	ret

000000000000034e <redircmd>:

struct cmd*
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     34e:	7139                	addi	sp,sp,-64
     350:	fc06                	sd	ra,56(sp)
     352:	f822                	sd	s0,48(sp)
     354:	f426                	sd	s1,40(sp)
     356:	f04a                	sd	s2,32(sp)
     358:	ec4e                	sd	s3,24(sp)
     35a:	e852                	sd	s4,16(sp)
     35c:	e456                	sd	s5,8(sp)
     35e:	e05a                	sd	s6,0(sp)
     360:	0080                	addi	s0,sp,64
     362:	8b2a                	mv	s6,a0
     364:	8aae                	mv	s5,a1
     366:	8a32                	mv	s4,a2
     368:	89b6                	mv	s3,a3
     36a:	893a                	mv	s2,a4
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
     36c:	02800513          	li	a0,40
     370:	00001097          	auipc	ra,0x1
     374:	f32080e7          	jalr	-206(ra) # 12a2 <malloc>
     378:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     37a:	02800613          	li	a2,40
     37e:	4581                	li	a1,0
     380:	00001097          	auipc	ra,0x1
     384:	8e8080e7          	jalr	-1816(ra) # c68 <memset>
  cmd->type = REDIR;
     388:	4789                	li	a5,2
     38a:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     38c:	0164b423          	sd	s6,8(s1)
  cmd->file = file;
     390:	0154b823          	sd	s5,16(s1)
  cmd->efile = efile;
     394:	0144bc23          	sd	s4,24(s1)
  cmd->mode = mode;
     398:	0334a023          	sw	s3,32(s1)
  cmd->fd = fd;
     39c:	0324a223          	sw	s2,36(s1)
  return (struct cmd*)cmd;
}
     3a0:	8526                	mv	a0,s1
     3a2:	70e2                	ld	ra,56(sp)
     3a4:	7442                	ld	s0,48(sp)
     3a6:	74a2                	ld	s1,40(sp)
     3a8:	7902                	ld	s2,32(sp)
     3aa:	69e2                	ld	s3,24(sp)
     3ac:	6a42                	ld	s4,16(sp)
     3ae:	6aa2                	ld	s5,8(sp)
     3b0:	6b02                	ld	s6,0(sp)
     3b2:	6121                	addi	sp,sp,64
     3b4:	8082                	ret

00000000000003b6 <pipecmd>:

struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
     3b6:	7179                	addi	sp,sp,-48
     3b8:	f406                	sd	ra,40(sp)
     3ba:	f022                	sd	s0,32(sp)
     3bc:	ec26                	sd	s1,24(sp)
     3be:	e84a                	sd	s2,16(sp)
     3c0:	e44e                	sd	s3,8(sp)
     3c2:	1800                	addi	s0,sp,48
     3c4:	89aa                	mv	s3,a0
     3c6:	892e                	mv	s2,a1
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
     3c8:	4561                	li	a0,24
     3ca:	00001097          	auipc	ra,0x1
     3ce:	ed8080e7          	jalr	-296(ra) # 12a2 <malloc>
     3d2:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     3d4:	4661                	li	a2,24
     3d6:	4581                	li	a1,0
     3d8:	00001097          	auipc	ra,0x1
     3dc:	890080e7          	jalr	-1904(ra) # c68 <memset>
  cmd->type = PIPE;
     3e0:	478d                	li	a5,3
     3e2:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     3e4:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     3e8:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     3ec:	8526                	mv	a0,s1
     3ee:	70a2                	ld	ra,40(sp)
     3f0:	7402                	ld	s0,32(sp)
     3f2:	64e2                	ld	s1,24(sp)
     3f4:	6942                	ld	s2,16(sp)
     3f6:	69a2                	ld	s3,8(sp)
     3f8:	6145                	addi	sp,sp,48
     3fa:	8082                	ret

00000000000003fc <listcmd>:

struct cmd*
listcmd(struct cmd *left, struct cmd *right)
{
     3fc:	7179                	addi	sp,sp,-48
     3fe:	f406                	sd	ra,40(sp)
     400:	f022                	sd	s0,32(sp)
     402:	ec26                	sd	s1,24(sp)
     404:	e84a                	sd	s2,16(sp)
     406:	e44e                	sd	s3,8(sp)
     408:	1800                	addi	s0,sp,48
     40a:	89aa                	mv	s3,a0
     40c:	892e                	mv	s2,a1
  struct listcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     40e:	4561                	li	a0,24
     410:	00001097          	auipc	ra,0x1
     414:	e92080e7          	jalr	-366(ra) # 12a2 <malloc>
     418:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     41a:	4661                	li	a2,24
     41c:	4581                	li	a1,0
     41e:	00001097          	auipc	ra,0x1
     422:	84a080e7          	jalr	-1974(ra) # c68 <memset>
  cmd->type = LIST;
     426:	4791                	li	a5,4
     428:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     42a:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     42e:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     432:	8526                	mv	a0,s1
     434:	70a2                	ld	ra,40(sp)
     436:	7402                	ld	s0,32(sp)
     438:	64e2                	ld	s1,24(sp)
     43a:	6942                	ld	s2,16(sp)
     43c:	69a2                	ld	s3,8(sp)
     43e:	6145                	addi	sp,sp,48
     440:	8082                	ret

0000000000000442 <backcmd>:

struct cmd*
backcmd(struct cmd *subcmd)
{
     442:	1101                	addi	sp,sp,-32
     444:	ec06                	sd	ra,24(sp)
     446:	e822                	sd	s0,16(sp)
     448:	e426                	sd	s1,8(sp)
     44a:	e04a                	sd	s2,0(sp)
     44c:	1000                	addi	s0,sp,32
     44e:	892a                	mv	s2,a0
  struct backcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     450:	4541                	li	a0,16
     452:	00001097          	auipc	ra,0x1
     456:	e50080e7          	jalr	-432(ra) # 12a2 <malloc>
     45a:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     45c:	4641                	li	a2,16
     45e:	4581                	li	a1,0
     460:	00001097          	auipc	ra,0x1
     464:	808080e7          	jalr	-2040(ra) # c68 <memset>
  cmd->type = BACK;
     468:	4795                	li	a5,5
     46a:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     46c:	0124b423          	sd	s2,8(s1)
  return (struct cmd*)cmd;
}
     470:	8526                	mv	a0,s1
     472:	60e2                	ld	ra,24(sp)
     474:	6442                	ld	s0,16(sp)
     476:	64a2                	ld	s1,8(sp)
     478:	6902                	ld	s2,0(sp)
     47a:	6105                	addi	sp,sp,32
     47c:	8082                	ret

000000000000047e <gettoken>:
char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int
gettoken(char **ps, char *es, char **q, char **eq)
{
     47e:	7139                	addi	sp,sp,-64
     480:	fc06                	sd	ra,56(sp)
     482:	f822                	sd	s0,48(sp)
     484:	f426                	sd	s1,40(sp)
     486:	f04a                	sd	s2,32(sp)
     488:	ec4e                	sd	s3,24(sp)
     48a:	e852                	sd	s4,16(sp)
     48c:	e456                	sd	s5,8(sp)
     48e:	e05a                	sd	s6,0(sp)
     490:	0080                	addi	s0,sp,64
     492:	8a2a                	mv	s4,a0
     494:	892e                	mv	s2,a1
     496:	8ab2                	mv	s5,a2
     498:	8b36                	mv	s6,a3
  char *s;
  int ret;

  s = *ps;
     49a:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     49c:	00001997          	auipc	s3,0x1
     4a0:	05c98993          	addi	s3,s3,92 # 14f8 <whitespace>
     4a4:	00b4fd63          	bgeu	s1,a1,4be <gettoken+0x40>
     4a8:	0004c583          	lbu	a1,0(s1)
     4ac:	854e                	mv	a0,s3
     4ae:	00000097          	auipc	ra,0x0
     4b2:	7dc080e7          	jalr	2012(ra) # c8a <strchr>
     4b6:	c501                	beqz	a0,4be <gettoken+0x40>
    s++;
     4b8:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     4ba:	fe9917e3          	bne	s2,s1,4a8 <gettoken+0x2a>
  if(q)
     4be:	000a8463          	beqz	s5,4c6 <gettoken+0x48>
    *q = s;
     4c2:	009ab023          	sd	s1,0(s5)
  ret = *s;
     4c6:	0004c783          	lbu	a5,0(s1)
     4ca:	00078a9b          	sext.w	s5,a5
  switch(*s){
     4ce:	03c00713          	li	a4,60
     4d2:	06f76563          	bltu	a4,a5,53c <gettoken+0xbe>
     4d6:	03a00713          	li	a4,58
     4da:	00f76e63          	bltu	a4,a5,4f6 <gettoken+0x78>
     4de:	cf89                	beqz	a5,4f8 <gettoken+0x7a>
     4e0:	02600713          	li	a4,38
     4e4:	00e78963          	beq	a5,a4,4f6 <gettoken+0x78>
     4e8:	fd87879b          	addiw	a5,a5,-40
     4ec:	0ff7f793          	andi	a5,a5,255
     4f0:	4705                	li	a4,1
     4f2:	06f76c63          	bltu	a4,a5,56a <gettoken+0xec>
  case '(':
  case ')':
  case ';':
  case '&':
  case '<':
    s++;
     4f6:	0485                	addi	s1,s1,1
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
      s++;
    break;
  }
  if(eq)
     4f8:	000b0463          	beqz	s6,500 <gettoken+0x82>
    *eq = s;
     4fc:	009b3023          	sd	s1,0(s6)

  while(s < es && strchr(whitespace, *s))
     500:	00001997          	auipc	s3,0x1
     504:	ff898993          	addi	s3,s3,-8 # 14f8 <whitespace>
     508:	0124fd63          	bgeu	s1,s2,522 <gettoken+0xa4>
     50c:	0004c583          	lbu	a1,0(s1)
     510:	854e                	mv	a0,s3
     512:	00000097          	auipc	ra,0x0
     516:	778080e7          	jalr	1912(ra) # c8a <strchr>
     51a:	c501                	beqz	a0,522 <gettoken+0xa4>
    s++;
     51c:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     51e:	fe9917e3          	bne	s2,s1,50c <gettoken+0x8e>
  *ps = s;
     522:	009a3023          	sd	s1,0(s4)
  return ret;
}
     526:	8556                	mv	a0,s5
     528:	70e2                	ld	ra,56(sp)
     52a:	7442                	ld	s0,48(sp)
     52c:	74a2                	ld	s1,40(sp)
     52e:	7902                	ld	s2,32(sp)
     530:	69e2                	ld	s3,24(sp)
     532:	6a42                	ld	s4,16(sp)
     534:	6aa2                	ld	s5,8(sp)
     536:	6b02                	ld	s6,0(sp)
     538:	6121                	addi	sp,sp,64
     53a:	8082                	ret
  switch(*s){
     53c:	03e00713          	li	a4,62
     540:	02e79163          	bne	a5,a4,562 <gettoken+0xe4>
    s++;
     544:	00148693          	addi	a3,s1,1
    if(*s == '>'){
     548:	0014c703          	lbu	a4,1(s1)
     54c:	03e00793          	li	a5,62
      s++;
     550:	0489                	addi	s1,s1,2
      ret = '+';
     552:	02b00a93          	li	s5,43
    if(*s == '>'){
     556:	faf701e3          	beq	a4,a5,4f8 <gettoken+0x7a>
    s++;
     55a:	84b6                	mv	s1,a3
  ret = *s;
     55c:	03e00a93          	li	s5,62
     560:	bf61                	j	4f8 <gettoken+0x7a>
  switch(*s){
     562:	07c00713          	li	a4,124
     566:	f8e788e3          	beq	a5,a4,4f6 <gettoken+0x78>
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     56a:	00001997          	auipc	s3,0x1
     56e:	f8e98993          	addi	s3,s3,-114 # 14f8 <whitespace>
     572:	00001a97          	auipc	s5,0x1
     576:	f7ea8a93          	addi	s5,s5,-130 # 14f0 <symbols>
     57a:	0324f563          	bgeu	s1,s2,5a4 <gettoken+0x126>
     57e:	0004c583          	lbu	a1,0(s1)
     582:	854e                	mv	a0,s3
     584:	00000097          	auipc	ra,0x0
     588:	706080e7          	jalr	1798(ra) # c8a <strchr>
     58c:	e505                	bnez	a0,5b4 <gettoken+0x136>
     58e:	0004c583          	lbu	a1,0(s1)
     592:	8556                	mv	a0,s5
     594:	00000097          	auipc	ra,0x0
     598:	6f6080e7          	jalr	1782(ra) # c8a <strchr>
     59c:	e909                	bnez	a0,5ae <gettoken+0x130>
      s++;
     59e:	0485                	addi	s1,s1,1
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     5a0:	fc991fe3          	bne	s2,s1,57e <gettoken+0x100>
  if(eq)
     5a4:	06100a93          	li	s5,97
     5a8:	f40b1ae3          	bnez	s6,4fc <gettoken+0x7e>
     5ac:	bf9d                	j	522 <gettoken+0xa4>
    ret = 'a';
     5ae:	06100a93          	li	s5,97
     5b2:	b799                	j	4f8 <gettoken+0x7a>
     5b4:	06100a93          	li	s5,97
     5b8:	b781                	j	4f8 <gettoken+0x7a>

00000000000005ba <peek>:

int
peek(char **ps, char *es, char *toks)
{
     5ba:	7139                	addi	sp,sp,-64
     5bc:	fc06                	sd	ra,56(sp)
     5be:	f822                	sd	s0,48(sp)
     5c0:	f426                	sd	s1,40(sp)
     5c2:	f04a                	sd	s2,32(sp)
     5c4:	ec4e                	sd	s3,24(sp)
     5c6:	e852                	sd	s4,16(sp)
     5c8:	e456                	sd	s5,8(sp)
     5ca:	0080                	addi	s0,sp,64
     5cc:	8a2a                	mv	s4,a0
     5ce:	892e                	mv	s2,a1
     5d0:	8ab2                	mv	s5,a2
  char *s;

  s = *ps;
     5d2:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     5d4:	00001997          	auipc	s3,0x1
     5d8:	f2498993          	addi	s3,s3,-220 # 14f8 <whitespace>
     5dc:	00b4fd63          	bgeu	s1,a1,5f6 <peek+0x3c>
     5e0:	0004c583          	lbu	a1,0(s1)
     5e4:	854e                	mv	a0,s3
     5e6:	00000097          	auipc	ra,0x0
     5ea:	6a4080e7          	jalr	1700(ra) # c8a <strchr>
     5ee:	c501                	beqz	a0,5f6 <peek+0x3c>
    s++;
     5f0:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     5f2:	fe9917e3          	bne	s2,s1,5e0 <peek+0x26>
  *ps = s;
     5f6:	009a3023          	sd	s1,0(s4)
  return *s && strchr(toks, *s);
     5fa:	0004c583          	lbu	a1,0(s1)
     5fe:	4501                	li	a0,0
     600:	e991                	bnez	a1,614 <peek+0x5a>
}
     602:	70e2                	ld	ra,56(sp)
     604:	7442                	ld	s0,48(sp)
     606:	74a2                	ld	s1,40(sp)
     608:	7902                	ld	s2,32(sp)
     60a:	69e2                	ld	s3,24(sp)
     60c:	6a42                	ld	s4,16(sp)
     60e:	6aa2                	ld	s5,8(sp)
     610:	6121                	addi	sp,sp,64
     612:	8082                	ret
  return *s && strchr(toks, *s);
     614:	8556                	mv	a0,s5
     616:	00000097          	auipc	ra,0x0
     61a:	674080e7          	jalr	1652(ra) # c8a <strchr>
     61e:	00a03533          	snez	a0,a0
     622:	b7c5                	j	602 <peek+0x48>

0000000000000624 <parseredirs>:
  return cmd;
}

struct cmd*
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     624:	7159                	addi	sp,sp,-112
     626:	f486                	sd	ra,104(sp)
     628:	f0a2                	sd	s0,96(sp)
     62a:	eca6                	sd	s1,88(sp)
     62c:	e8ca                	sd	s2,80(sp)
     62e:	e4ce                	sd	s3,72(sp)
     630:	e0d2                	sd	s4,64(sp)
     632:	fc56                	sd	s5,56(sp)
     634:	f85a                	sd	s6,48(sp)
     636:	f45e                	sd	s7,40(sp)
     638:	f062                	sd	s8,32(sp)
     63a:	ec66                	sd	s9,24(sp)
     63c:	1880                	addi	s0,sp,112
     63e:	8a2a                	mv	s4,a0
     640:	89ae                	mv	s3,a1
     642:	8932                	mv	s2,a2
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     644:	00001b97          	auipc	s7,0x1
     648:	db4b8b93          	addi	s7,s7,-588 # 13f8 <malloc+0x156>
    tok = gettoken(ps, es, 0, 0);
    if(gettoken(ps, es, &q, &eq) != 'a')
     64c:	06100c13          	li	s8,97
      panic("missing file for redirection");
    switch(tok){
     650:	03c00c93          	li	s9,60
  while(peek(ps, es, "<>")){
     654:	a02d                	j	67e <parseredirs+0x5a>
      panic("missing file for redirection");
     656:	00001517          	auipc	a0,0x1
     65a:	d8250513          	addi	a0,a0,-638 # 13d8 <malloc+0x136>
     65e:	00000097          	auipc	ra,0x0
     662:	9f6080e7          	jalr	-1546(ra) # 54 <panic>
    case '<':
      cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     666:	4701                	li	a4,0
     668:	4681                	li	a3,0
     66a:	f9043603          	ld	a2,-112(s0)
     66e:	f9843583          	ld	a1,-104(s0)
     672:	8552                	mv	a0,s4
     674:	00000097          	auipc	ra,0x0
     678:	cda080e7          	jalr	-806(ra) # 34e <redircmd>
     67c:	8a2a                	mv	s4,a0
    switch(tok){
     67e:	03e00b13          	li	s6,62
     682:	02b00a93          	li	s5,43
  while(peek(ps, es, "<>")){
     686:	865e                	mv	a2,s7
     688:	85ca                	mv	a1,s2
     68a:	854e                	mv	a0,s3
     68c:	00000097          	auipc	ra,0x0
     690:	f2e080e7          	jalr	-210(ra) # 5ba <peek>
     694:	c925                	beqz	a0,704 <parseredirs+0xe0>
    tok = gettoken(ps, es, 0, 0);
     696:	4681                	li	a3,0
     698:	4601                	li	a2,0
     69a:	85ca                	mv	a1,s2
     69c:	854e                	mv	a0,s3
     69e:	00000097          	auipc	ra,0x0
     6a2:	de0080e7          	jalr	-544(ra) # 47e <gettoken>
     6a6:	84aa                	mv	s1,a0
    if(gettoken(ps, es, &q, &eq) != 'a')
     6a8:	f9040693          	addi	a3,s0,-112
     6ac:	f9840613          	addi	a2,s0,-104
     6b0:	85ca                	mv	a1,s2
     6b2:	854e                	mv	a0,s3
     6b4:	00000097          	auipc	ra,0x0
     6b8:	dca080e7          	jalr	-566(ra) # 47e <gettoken>
     6bc:	f9851de3          	bne	a0,s8,656 <parseredirs+0x32>
    switch(tok){
     6c0:	fb9483e3          	beq	s1,s9,666 <parseredirs+0x42>
     6c4:	03648263          	beq	s1,s6,6e8 <parseredirs+0xc4>
     6c8:	fb549fe3          	bne	s1,s5,686 <parseredirs+0x62>
      break;
    case '>':
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
      break;
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     6cc:	4705                	li	a4,1
     6ce:	20100693          	li	a3,513
     6d2:	f9043603          	ld	a2,-112(s0)
     6d6:	f9843583          	ld	a1,-104(s0)
     6da:	8552                	mv	a0,s4
     6dc:	00000097          	auipc	ra,0x0
     6e0:	c72080e7          	jalr	-910(ra) # 34e <redircmd>
     6e4:	8a2a                	mv	s4,a0
      break;
     6e6:	bf61                	j	67e <parseredirs+0x5a>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
     6e8:	4705                	li	a4,1
     6ea:	60100693          	li	a3,1537
     6ee:	f9043603          	ld	a2,-112(s0)
     6f2:	f9843583          	ld	a1,-104(s0)
     6f6:	8552                	mv	a0,s4
     6f8:	00000097          	auipc	ra,0x0
     6fc:	c56080e7          	jalr	-938(ra) # 34e <redircmd>
     700:	8a2a                	mv	s4,a0
      break;
     702:	bfb5                	j	67e <parseredirs+0x5a>
    }
  }
  return cmd;
}
     704:	8552                	mv	a0,s4
     706:	70a6                	ld	ra,104(sp)
     708:	7406                	ld	s0,96(sp)
     70a:	64e6                	ld	s1,88(sp)
     70c:	6946                	ld	s2,80(sp)
     70e:	69a6                	ld	s3,72(sp)
     710:	6a06                	ld	s4,64(sp)
     712:	7ae2                	ld	s5,56(sp)
     714:	7b42                	ld	s6,48(sp)
     716:	7ba2                	ld	s7,40(sp)
     718:	7c02                	ld	s8,32(sp)
     71a:	6ce2                	ld	s9,24(sp)
     71c:	6165                	addi	sp,sp,112
     71e:	8082                	ret

0000000000000720 <parseexec>:
  return cmd;
}

struct cmd*
parseexec(char **ps, char *es)
{
     720:	7159                	addi	sp,sp,-112
     722:	f486                	sd	ra,104(sp)
     724:	f0a2                	sd	s0,96(sp)
     726:	eca6                	sd	s1,88(sp)
     728:	e8ca                	sd	s2,80(sp)
     72a:	e4ce                	sd	s3,72(sp)
     72c:	e0d2                	sd	s4,64(sp)
     72e:	fc56                	sd	s5,56(sp)
     730:	f85a                	sd	s6,48(sp)
     732:	f45e                	sd	s7,40(sp)
     734:	f062                	sd	s8,32(sp)
     736:	ec66                	sd	s9,24(sp)
     738:	1880                	addi	s0,sp,112
     73a:	8a2a                	mv	s4,a0
     73c:	8aae                	mv	s5,a1
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;

  if(peek(ps, es, "("))
     73e:	00001617          	auipc	a2,0x1
     742:	cc260613          	addi	a2,a2,-830 # 1400 <malloc+0x15e>
     746:	00000097          	auipc	ra,0x0
     74a:	e74080e7          	jalr	-396(ra) # 5ba <peek>
     74e:	e905                	bnez	a0,77e <parseexec+0x5e>
     750:	89aa                	mv	s3,a0
    return parseblock(ps, es);

  ret = execcmd();
     752:	00000097          	auipc	ra,0x0
     756:	bc6080e7          	jalr	-1082(ra) # 318 <execcmd>
     75a:	8c2a                	mv	s8,a0
  cmd = (struct execcmd*)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es);
     75c:	8656                	mv	a2,s5
     75e:	85d2                	mv	a1,s4
     760:	00000097          	auipc	ra,0x0
     764:	ec4080e7          	jalr	-316(ra) # 624 <parseredirs>
     768:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     76a:	008c0913          	addi	s2,s8,8
     76e:	00001b17          	auipc	s6,0x1
     772:	cb2b0b13          	addi	s6,s6,-846 # 1420 <malloc+0x17e>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
      break;
    if(tok != 'a')
     776:	06100c93          	li	s9,97
      panic("syntax");
    cmd->argv[argc] = q;
    cmd->eargv[argc] = eq;
    argc++;
    if(argc >= MAXARGS)
     77a:	4ba9                	li	s7,10
  while(!peek(ps, es, "|)&;")){
     77c:	a0b1                	j	7c8 <parseexec+0xa8>
    return parseblock(ps, es);
     77e:	85d6                	mv	a1,s5
     780:	8552                	mv	a0,s4
     782:	00000097          	auipc	ra,0x0
     786:	1bc080e7          	jalr	444(ra) # 93e <parseblock>
     78a:	84aa                	mv	s1,a0
    ret = parseredirs(ret, ps, es);
  }
  cmd->argv[argc] = 0;
  cmd->eargv[argc] = 0;
  return ret;
}
     78c:	8526                	mv	a0,s1
     78e:	70a6                	ld	ra,104(sp)
     790:	7406                	ld	s0,96(sp)
     792:	64e6                	ld	s1,88(sp)
     794:	6946                	ld	s2,80(sp)
     796:	69a6                	ld	s3,72(sp)
     798:	6a06                	ld	s4,64(sp)
     79a:	7ae2                	ld	s5,56(sp)
     79c:	7b42                	ld	s6,48(sp)
     79e:	7ba2                	ld	s7,40(sp)
     7a0:	7c02                	ld	s8,32(sp)
     7a2:	6ce2                	ld	s9,24(sp)
     7a4:	6165                	addi	sp,sp,112
     7a6:	8082                	ret
      panic("syntax");
     7a8:	00001517          	auipc	a0,0x1
     7ac:	c6050513          	addi	a0,a0,-928 # 1408 <malloc+0x166>
     7b0:	00000097          	auipc	ra,0x0
     7b4:	8a4080e7          	jalr	-1884(ra) # 54 <panic>
    ret = parseredirs(ret, ps, es);
     7b8:	8656                	mv	a2,s5
     7ba:	85d2                	mv	a1,s4
     7bc:	8526                	mv	a0,s1
     7be:	00000097          	auipc	ra,0x0
     7c2:	e66080e7          	jalr	-410(ra) # 624 <parseredirs>
     7c6:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     7c8:	865a                	mv	a2,s6
     7ca:	85d6                	mv	a1,s5
     7cc:	8552                	mv	a0,s4
     7ce:	00000097          	auipc	ra,0x0
     7d2:	dec080e7          	jalr	-532(ra) # 5ba <peek>
     7d6:	e131                	bnez	a0,81a <parseexec+0xfa>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
     7d8:	f9040693          	addi	a3,s0,-112
     7dc:	f9840613          	addi	a2,s0,-104
     7e0:	85d6                	mv	a1,s5
     7e2:	8552                	mv	a0,s4
     7e4:	00000097          	auipc	ra,0x0
     7e8:	c9a080e7          	jalr	-870(ra) # 47e <gettoken>
     7ec:	c51d                	beqz	a0,81a <parseexec+0xfa>
    if(tok != 'a')
     7ee:	fb951de3          	bne	a0,s9,7a8 <parseexec+0x88>
    cmd->argv[argc] = q;
     7f2:	f9843783          	ld	a5,-104(s0)
     7f6:	00f93023          	sd	a5,0(s2)
    cmd->eargv[argc] = eq;
     7fa:	f9043783          	ld	a5,-112(s0)
     7fe:	04f93823          	sd	a5,80(s2)
    argc++;
     802:	2985                	addiw	s3,s3,1
    if(argc >= MAXARGS)
     804:	0921                	addi	s2,s2,8
     806:	fb7999e3          	bne	s3,s7,7b8 <parseexec+0x98>
      panic("too many args");
     80a:	00001517          	auipc	a0,0x1
     80e:	c0650513          	addi	a0,a0,-1018 # 1410 <malloc+0x16e>
     812:	00000097          	auipc	ra,0x0
     816:	842080e7          	jalr	-1982(ra) # 54 <panic>
  cmd->argv[argc] = 0;
     81a:	098e                	slli	s3,s3,0x3
     81c:	99e2                	add	s3,s3,s8
     81e:	0009b423          	sd	zero,8(s3)
  cmd->eargv[argc] = 0;
     822:	0409bc23          	sd	zero,88(s3)
  return ret;
     826:	b79d                	j	78c <parseexec+0x6c>

0000000000000828 <parsepipe>:
{
     828:	7179                	addi	sp,sp,-48
     82a:	f406                	sd	ra,40(sp)
     82c:	f022                	sd	s0,32(sp)
     82e:	ec26                	sd	s1,24(sp)
     830:	e84a                	sd	s2,16(sp)
     832:	e44e                	sd	s3,8(sp)
     834:	1800                	addi	s0,sp,48
     836:	892a                	mv	s2,a0
     838:	89ae                	mv	s3,a1
  cmd = parseexec(ps, es);
     83a:	00000097          	auipc	ra,0x0
     83e:	ee6080e7          	jalr	-282(ra) # 720 <parseexec>
     842:	84aa                	mv	s1,a0
  if(peek(ps, es, "|")){
     844:	00001617          	auipc	a2,0x1
     848:	be460613          	addi	a2,a2,-1052 # 1428 <malloc+0x186>
     84c:	85ce                	mv	a1,s3
     84e:	854a                	mv	a0,s2
     850:	00000097          	auipc	ra,0x0
     854:	d6a080e7          	jalr	-662(ra) # 5ba <peek>
     858:	e909                	bnez	a0,86a <parsepipe+0x42>
}
     85a:	8526                	mv	a0,s1
     85c:	70a2                	ld	ra,40(sp)
     85e:	7402                	ld	s0,32(sp)
     860:	64e2                	ld	s1,24(sp)
     862:	6942                	ld	s2,16(sp)
     864:	69a2                	ld	s3,8(sp)
     866:	6145                	addi	sp,sp,48
     868:	8082                	ret
    gettoken(ps, es, 0, 0);
     86a:	4681                	li	a3,0
     86c:	4601                	li	a2,0
     86e:	85ce                	mv	a1,s3
     870:	854a                	mv	a0,s2
     872:	00000097          	auipc	ra,0x0
     876:	c0c080e7          	jalr	-1012(ra) # 47e <gettoken>
    cmd = pipecmd(cmd, parsepipe(ps, es));
     87a:	85ce                	mv	a1,s3
     87c:	854a                	mv	a0,s2
     87e:	00000097          	auipc	ra,0x0
     882:	faa080e7          	jalr	-86(ra) # 828 <parsepipe>
     886:	85aa                	mv	a1,a0
     888:	8526                	mv	a0,s1
     88a:	00000097          	auipc	ra,0x0
     88e:	b2c080e7          	jalr	-1236(ra) # 3b6 <pipecmd>
     892:	84aa                	mv	s1,a0
  return cmd;
     894:	b7d9                	j	85a <parsepipe+0x32>

0000000000000896 <parseline>:
{
     896:	7179                	addi	sp,sp,-48
     898:	f406                	sd	ra,40(sp)
     89a:	f022                	sd	s0,32(sp)
     89c:	ec26                	sd	s1,24(sp)
     89e:	e84a                	sd	s2,16(sp)
     8a0:	e44e                	sd	s3,8(sp)
     8a2:	e052                	sd	s4,0(sp)
     8a4:	1800                	addi	s0,sp,48
     8a6:	892a                	mv	s2,a0
     8a8:	89ae                	mv	s3,a1
  cmd = parsepipe(ps, es);
     8aa:	00000097          	auipc	ra,0x0
     8ae:	f7e080e7          	jalr	-130(ra) # 828 <parsepipe>
     8b2:	84aa                	mv	s1,a0
  while(peek(ps, es, "&")){
     8b4:	00001a17          	auipc	s4,0x1
     8b8:	b7ca0a13          	addi	s4,s4,-1156 # 1430 <malloc+0x18e>
     8bc:	a839                	j	8da <parseline+0x44>
    gettoken(ps, es, 0, 0);
     8be:	4681                	li	a3,0
     8c0:	4601                	li	a2,0
     8c2:	85ce                	mv	a1,s3
     8c4:	854a                	mv	a0,s2
     8c6:	00000097          	auipc	ra,0x0
     8ca:	bb8080e7          	jalr	-1096(ra) # 47e <gettoken>
    cmd = backcmd(cmd);
     8ce:	8526                	mv	a0,s1
     8d0:	00000097          	auipc	ra,0x0
     8d4:	b72080e7          	jalr	-1166(ra) # 442 <backcmd>
     8d8:	84aa                	mv	s1,a0
  while(peek(ps, es, "&")){
     8da:	8652                	mv	a2,s4
     8dc:	85ce                	mv	a1,s3
     8de:	854a                	mv	a0,s2
     8e0:	00000097          	auipc	ra,0x0
     8e4:	cda080e7          	jalr	-806(ra) # 5ba <peek>
     8e8:	f979                	bnez	a0,8be <parseline+0x28>
  if(peek(ps, es, ";")){
     8ea:	00001617          	auipc	a2,0x1
     8ee:	b4e60613          	addi	a2,a2,-1202 # 1438 <malloc+0x196>
     8f2:	85ce                	mv	a1,s3
     8f4:	854a                	mv	a0,s2
     8f6:	00000097          	auipc	ra,0x0
     8fa:	cc4080e7          	jalr	-828(ra) # 5ba <peek>
     8fe:	e911                	bnez	a0,912 <parseline+0x7c>
}
     900:	8526                	mv	a0,s1
     902:	70a2                	ld	ra,40(sp)
     904:	7402                	ld	s0,32(sp)
     906:	64e2                	ld	s1,24(sp)
     908:	6942                	ld	s2,16(sp)
     90a:	69a2                	ld	s3,8(sp)
     90c:	6a02                	ld	s4,0(sp)
     90e:	6145                	addi	sp,sp,48
     910:	8082                	ret
    gettoken(ps, es, 0, 0);
     912:	4681                	li	a3,0
     914:	4601                	li	a2,0
     916:	85ce                	mv	a1,s3
     918:	854a                	mv	a0,s2
     91a:	00000097          	auipc	ra,0x0
     91e:	b64080e7          	jalr	-1180(ra) # 47e <gettoken>
    cmd = listcmd(cmd, parseline(ps, es));
     922:	85ce                	mv	a1,s3
     924:	854a                	mv	a0,s2
     926:	00000097          	auipc	ra,0x0
     92a:	f70080e7          	jalr	-144(ra) # 896 <parseline>
     92e:	85aa                	mv	a1,a0
     930:	8526                	mv	a0,s1
     932:	00000097          	auipc	ra,0x0
     936:	aca080e7          	jalr	-1334(ra) # 3fc <listcmd>
     93a:	84aa                	mv	s1,a0
  return cmd;
     93c:	b7d1                	j	900 <parseline+0x6a>

000000000000093e <parseblock>:
{
     93e:	7179                	addi	sp,sp,-48
     940:	f406                	sd	ra,40(sp)
     942:	f022                	sd	s0,32(sp)
     944:	ec26                	sd	s1,24(sp)
     946:	e84a                	sd	s2,16(sp)
     948:	e44e                	sd	s3,8(sp)
     94a:	1800                	addi	s0,sp,48
     94c:	84aa                	mv	s1,a0
     94e:	892e                	mv	s2,a1
  if(!peek(ps, es, "("))
     950:	00001617          	auipc	a2,0x1
     954:	ab060613          	addi	a2,a2,-1360 # 1400 <malloc+0x15e>
     958:	00000097          	auipc	ra,0x0
     95c:	c62080e7          	jalr	-926(ra) # 5ba <peek>
     960:	c12d                	beqz	a0,9c2 <parseblock+0x84>
  gettoken(ps, es, 0, 0);
     962:	4681                	li	a3,0
     964:	4601                	li	a2,0
     966:	85ca                	mv	a1,s2
     968:	8526                	mv	a0,s1
     96a:	00000097          	auipc	ra,0x0
     96e:	b14080e7          	jalr	-1260(ra) # 47e <gettoken>
  cmd = parseline(ps, es);
     972:	85ca                	mv	a1,s2
     974:	8526                	mv	a0,s1
     976:	00000097          	auipc	ra,0x0
     97a:	f20080e7          	jalr	-224(ra) # 896 <parseline>
     97e:	89aa                	mv	s3,a0
  if(!peek(ps, es, ")"))
     980:	00001617          	auipc	a2,0x1
     984:	ad060613          	addi	a2,a2,-1328 # 1450 <malloc+0x1ae>
     988:	85ca                	mv	a1,s2
     98a:	8526                	mv	a0,s1
     98c:	00000097          	auipc	ra,0x0
     990:	c2e080e7          	jalr	-978(ra) # 5ba <peek>
     994:	cd1d                	beqz	a0,9d2 <parseblock+0x94>
  gettoken(ps, es, 0, 0);
     996:	4681                	li	a3,0
     998:	4601                	li	a2,0
     99a:	85ca                	mv	a1,s2
     99c:	8526                	mv	a0,s1
     99e:	00000097          	auipc	ra,0x0
     9a2:	ae0080e7          	jalr	-1312(ra) # 47e <gettoken>
  cmd = parseredirs(cmd, ps, es);
     9a6:	864a                	mv	a2,s2
     9a8:	85a6                	mv	a1,s1
     9aa:	854e                	mv	a0,s3
     9ac:	00000097          	auipc	ra,0x0
     9b0:	c78080e7          	jalr	-904(ra) # 624 <parseredirs>
}
     9b4:	70a2                	ld	ra,40(sp)
     9b6:	7402                	ld	s0,32(sp)
     9b8:	64e2                	ld	s1,24(sp)
     9ba:	6942                	ld	s2,16(sp)
     9bc:	69a2                	ld	s3,8(sp)
     9be:	6145                	addi	sp,sp,48
     9c0:	8082                	ret
    panic("parseblock");
     9c2:	00001517          	auipc	a0,0x1
     9c6:	a7e50513          	addi	a0,a0,-1410 # 1440 <malloc+0x19e>
     9ca:	fffff097          	auipc	ra,0xfffff
     9ce:	68a080e7          	jalr	1674(ra) # 54 <panic>
    panic("syntax - missing )");
     9d2:	00001517          	auipc	a0,0x1
     9d6:	a8650513          	addi	a0,a0,-1402 # 1458 <malloc+0x1b6>
     9da:	fffff097          	auipc	ra,0xfffff
     9de:	67a080e7          	jalr	1658(ra) # 54 <panic>

00000000000009e2 <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd*
nulterminate(struct cmd *cmd)
{
     9e2:	1101                	addi	sp,sp,-32
     9e4:	ec06                	sd	ra,24(sp)
     9e6:	e822                	sd	s0,16(sp)
     9e8:	e426                	sd	s1,8(sp)
     9ea:	1000                	addi	s0,sp,32
     9ec:	84aa                	mv	s1,a0
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
     9ee:	c521                	beqz	a0,a36 <nulterminate+0x54>
    return 0;

  switch(cmd->type){
     9f0:	4118                	lw	a4,0(a0)
     9f2:	4795                	li	a5,5
     9f4:	04e7e163          	bltu	a5,a4,a36 <nulterminate+0x54>
     9f8:	00056783          	lwu	a5,0(a0)
     9fc:	078a                	slli	a5,a5,0x2
     9fe:	00001717          	auipc	a4,0x1
     a02:	aba70713          	addi	a4,a4,-1350 # 14b8 <malloc+0x216>
     a06:	97ba                	add	a5,a5,a4
     a08:	439c                	lw	a5,0(a5)
     a0a:	97ba                	add	a5,a5,a4
     a0c:	8782                	jr	a5
  case EXEC:
    ecmd = (struct execcmd*)cmd;
    for(i=0; ecmd->argv[i]; i++)
     a0e:	651c                	ld	a5,8(a0)
     a10:	c39d                	beqz	a5,a36 <nulterminate+0x54>
     a12:	01050793          	addi	a5,a0,16
      *ecmd->eargv[i] = 0;
     a16:	67b8                	ld	a4,72(a5)
     a18:	00070023          	sb	zero,0(a4)
    for(i=0; ecmd->argv[i]; i++)
     a1c:	07a1                	addi	a5,a5,8
     a1e:	ff87b703          	ld	a4,-8(a5)
     a22:	fb75                	bnez	a4,a16 <nulterminate+0x34>
     a24:	a809                	j	a36 <nulterminate+0x54>
    break;

  case REDIR:
    rcmd = (struct redircmd*)cmd;
    nulterminate(rcmd->cmd);
     a26:	6508                	ld	a0,8(a0)
     a28:	00000097          	auipc	ra,0x0
     a2c:	fba080e7          	jalr	-70(ra) # 9e2 <nulterminate>
    *rcmd->efile = 0;
     a30:	6c9c                	ld	a5,24(s1)
     a32:	00078023          	sb	zero,0(a5)
    bcmd = (struct backcmd*)cmd;
    nulterminate(bcmd->cmd);
    break;
  }
  return cmd;
}
     a36:	8526                	mv	a0,s1
     a38:	60e2                	ld	ra,24(sp)
     a3a:	6442                	ld	s0,16(sp)
     a3c:	64a2                	ld	s1,8(sp)
     a3e:	6105                	addi	sp,sp,32
     a40:	8082                	ret
    nulterminate(pcmd->left);
     a42:	6508                	ld	a0,8(a0)
     a44:	00000097          	auipc	ra,0x0
     a48:	f9e080e7          	jalr	-98(ra) # 9e2 <nulterminate>
    nulterminate(pcmd->right);
     a4c:	6888                	ld	a0,16(s1)
     a4e:	00000097          	auipc	ra,0x0
     a52:	f94080e7          	jalr	-108(ra) # 9e2 <nulterminate>
    break;
     a56:	b7c5                	j	a36 <nulterminate+0x54>
    nulterminate(lcmd->left);
     a58:	6508                	ld	a0,8(a0)
     a5a:	00000097          	auipc	ra,0x0
     a5e:	f88080e7          	jalr	-120(ra) # 9e2 <nulterminate>
    nulterminate(lcmd->right);
     a62:	6888                	ld	a0,16(s1)
     a64:	00000097          	auipc	ra,0x0
     a68:	f7e080e7          	jalr	-130(ra) # 9e2 <nulterminate>
    break;
     a6c:	b7e9                	j	a36 <nulterminate+0x54>
    nulterminate(bcmd->cmd);
     a6e:	6508                	ld	a0,8(a0)
     a70:	00000097          	auipc	ra,0x0
     a74:	f72080e7          	jalr	-142(ra) # 9e2 <nulterminate>
    break;
     a78:	bf7d                	j	a36 <nulterminate+0x54>

0000000000000a7a <parsecmd>:
{
     a7a:	7179                	addi	sp,sp,-48
     a7c:	f406                	sd	ra,40(sp)
     a7e:	f022                	sd	s0,32(sp)
     a80:	ec26                	sd	s1,24(sp)
     a82:	e84a                	sd	s2,16(sp)
     a84:	1800                	addi	s0,sp,48
     a86:	fca43c23          	sd	a0,-40(s0)
  es = s + strlen(s);
     a8a:	84aa                	mv	s1,a0
     a8c:	00000097          	auipc	ra,0x0
     a90:	1b2080e7          	jalr	434(ra) # c3e <strlen>
     a94:	1502                	slli	a0,a0,0x20
     a96:	9101                	srli	a0,a0,0x20
     a98:	94aa                	add	s1,s1,a0
  cmd = parseline(&s, es);
     a9a:	85a6                	mv	a1,s1
     a9c:	fd840513          	addi	a0,s0,-40
     aa0:	00000097          	auipc	ra,0x0
     aa4:	df6080e7          	jalr	-522(ra) # 896 <parseline>
     aa8:	892a                	mv	s2,a0
  peek(&s, es, "");
     aaa:	00001617          	auipc	a2,0x1
     aae:	9c660613          	addi	a2,a2,-1594 # 1470 <malloc+0x1ce>
     ab2:	85a6                	mv	a1,s1
     ab4:	fd840513          	addi	a0,s0,-40
     ab8:	00000097          	auipc	ra,0x0
     abc:	b02080e7          	jalr	-1278(ra) # 5ba <peek>
  if(s != es){
     ac0:	fd843603          	ld	a2,-40(s0)
     ac4:	00961e63          	bne	a2,s1,ae0 <parsecmd+0x66>
  nulterminate(cmd);
     ac8:	854a                	mv	a0,s2
     aca:	00000097          	auipc	ra,0x0
     ace:	f18080e7          	jalr	-232(ra) # 9e2 <nulterminate>
}
     ad2:	854a                	mv	a0,s2
     ad4:	70a2                	ld	ra,40(sp)
     ad6:	7402                	ld	s0,32(sp)
     ad8:	64e2                	ld	s1,24(sp)
     ada:	6942                	ld	s2,16(sp)
     adc:	6145                	addi	sp,sp,48
     ade:	8082                	ret
    fprintf(2, "leftovers: %s\n", s);
     ae0:	00001597          	auipc	a1,0x1
     ae4:	99858593          	addi	a1,a1,-1640 # 1478 <malloc+0x1d6>
     ae8:	4509                	li	a0,2
     aea:	00000097          	auipc	ra,0x0
     aee:	6cc080e7          	jalr	1740(ra) # 11b6 <fprintf>
    panic("syntax");
     af2:	00001517          	auipc	a0,0x1
     af6:	91650513          	addi	a0,a0,-1770 # 1408 <malloc+0x166>
     afa:	fffff097          	auipc	ra,0xfffff
     afe:	55a080e7          	jalr	1370(ra) # 54 <panic>

0000000000000b02 <main>:
{
     b02:	7139                	addi	sp,sp,-64
     b04:	fc06                	sd	ra,56(sp)
     b06:	f822                	sd	s0,48(sp)
     b08:	f426                	sd	s1,40(sp)
     b0a:	f04a                	sd	s2,32(sp)
     b0c:	ec4e                	sd	s3,24(sp)
     b0e:	e852                	sd	s4,16(sp)
     b10:	e456                	sd	s5,8(sp)
     b12:	0080                	addi	s0,sp,64
  while((fd = open("console", O_RDWR)) >= 0){
     b14:	00001497          	auipc	s1,0x1
     b18:	97448493          	addi	s1,s1,-1676 # 1488 <malloc+0x1e6>
     b1c:	4589                	li	a1,2
     b1e:	8526                	mv	a0,s1
     b20:	00000097          	auipc	ra,0x0
     b24:	384080e7          	jalr	900(ra) # ea4 <open>
     b28:	00054963          	bltz	a0,b3a <main+0x38>
    if(fd >= 3){
     b2c:	4789                	li	a5,2
     b2e:	fea7d7e3          	bge	a5,a0,b1c <main+0x1a>
      close(fd);
     b32:	00000097          	auipc	ra,0x0
     b36:	35a080e7          	jalr	858(ra) # e8c <close>
  while(getcmd(buf, sizeof(buf)) >= 0){
     b3a:	00001497          	auipc	s1,0x1
     b3e:	9ce48493          	addi	s1,s1,-1586 # 1508 <buf.0>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     b42:	06300913          	li	s2,99
     b46:	02000993          	li	s3,32
      if(chdir(buf+3) < 0)
     b4a:	00001a17          	auipc	s4,0x1
     b4e:	9c1a0a13          	addi	s4,s4,-1599 # 150b <buf.0+0x3>
        fprintf(2, "cannot cd %s\n", buf+3);
     b52:	00001a97          	auipc	s5,0x1
     b56:	93ea8a93          	addi	s5,s5,-1730 # 1490 <malloc+0x1ee>
     b5a:	a819                	j	b70 <main+0x6e>
    if(fork1() == 0)
     b5c:	fffff097          	auipc	ra,0xfffff
     b60:	51e080e7          	jalr	1310(ra) # 7a <fork1>
     b64:	c925                	beqz	a0,bd4 <main+0xd2>
    wait(0);
     b66:	4501                	li	a0,0
     b68:	00000097          	auipc	ra,0x0
     b6c:	304080e7          	jalr	772(ra) # e6c <wait>
  while(getcmd(buf, sizeof(buf)) >= 0){
     b70:	06400593          	li	a1,100
     b74:	8526                	mv	a0,s1
     b76:	fffff097          	auipc	ra,0xfffff
     b7a:	48a080e7          	jalr	1162(ra) # 0 <getcmd>
     b7e:	06054763          	bltz	a0,bec <main+0xea>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     b82:	0004c783          	lbu	a5,0(s1)
     b86:	fd279be3          	bne	a5,s2,b5c <main+0x5a>
     b8a:	0014c703          	lbu	a4,1(s1)
     b8e:	06400793          	li	a5,100
     b92:	fcf715e3          	bne	a4,a5,b5c <main+0x5a>
     b96:	0024c783          	lbu	a5,2(s1)
     b9a:	fd3791e3          	bne	a5,s3,b5c <main+0x5a>
      buf[strlen(buf)-1] = 0;  // chop \n
     b9e:	8526                	mv	a0,s1
     ba0:	00000097          	auipc	ra,0x0
     ba4:	09e080e7          	jalr	158(ra) # c3e <strlen>
     ba8:	fff5079b          	addiw	a5,a0,-1
     bac:	1782                	slli	a5,a5,0x20
     bae:	9381                	srli	a5,a5,0x20
     bb0:	97a6                	add	a5,a5,s1
     bb2:	00078023          	sb	zero,0(a5)
      if(chdir(buf+3) < 0)
     bb6:	8552                	mv	a0,s4
     bb8:	00000097          	auipc	ra,0x0
     bbc:	31c080e7          	jalr	796(ra) # ed4 <chdir>
     bc0:	fa0558e3          	bgez	a0,b70 <main+0x6e>
        fprintf(2, "cannot cd %s\n", buf+3);
     bc4:	8652                	mv	a2,s4
     bc6:	85d6                	mv	a1,s5
     bc8:	4509                	li	a0,2
     bca:	00000097          	auipc	ra,0x0
     bce:	5ec080e7          	jalr	1516(ra) # 11b6 <fprintf>
     bd2:	bf79                	j	b70 <main+0x6e>
      runcmd(parsecmd(buf));
     bd4:	00001517          	auipc	a0,0x1
     bd8:	93450513          	addi	a0,a0,-1740 # 1508 <buf.0>
     bdc:	00000097          	auipc	ra,0x0
     be0:	e9e080e7          	jalr	-354(ra) # a7a <parsecmd>
     be4:	fffff097          	auipc	ra,0xfffff
     be8:	4c4080e7          	jalr	1220(ra) # a8 <runcmd>
  exit(0);
     bec:	4501                	li	a0,0
     bee:	00000097          	auipc	ra,0x0
     bf2:	276080e7          	jalr	630(ra) # e64 <exit>

0000000000000bf6 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     bf6:	1141                	addi	sp,sp,-16
     bf8:	e422                	sd	s0,8(sp)
     bfa:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     bfc:	87aa                	mv	a5,a0
     bfe:	0585                	addi	a1,a1,1
     c00:	0785                	addi	a5,a5,1
     c02:	fff5c703          	lbu	a4,-1(a1)
     c06:	fee78fa3          	sb	a4,-1(a5)
     c0a:	fb75                	bnez	a4,bfe <strcpy+0x8>
    ;
  return os;
}
     c0c:	6422                	ld	s0,8(sp)
     c0e:	0141                	addi	sp,sp,16
     c10:	8082                	ret

0000000000000c12 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     c12:	1141                	addi	sp,sp,-16
     c14:	e422                	sd	s0,8(sp)
     c16:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     c18:	00054783          	lbu	a5,0(a0)
     c1c:	cb91                	beqz	a5,c30 <strcmp+0x1e>
     c1e:	0005c703          	lbu	a4,0(a1)
     c22:	00f71763          	bne	a4,a5,c30 <strcmp+0x1e>
    p++, q++;
     c26:	0505                	addi	a0,a0,1
     c28:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     c2a:	00054783          	lbu	a5,0(a0)
     c2e:	fbe5                	bnez	a5,c1e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     c30:	0005c503          	lbu	a0,0(a1)
}
     c34:	40a7853b          	subw	a0,a5,a0
     c38:	6422                	ld	s0,8(sp)
     c3a:	0141                	addi	sp,sp,16
     c3c:	8082                	ret

0000000000000c3e <strlen>:

uint
strlen(const char *s)
{
     c3e:	1141                	addi	sp,sp,-16
     c40:	e422                	sd	s0,8(sp)
     c42:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     c44:	00054783          	lbu	a5,0(a0)
     c48:	cf91                	beqz	a5,c64 <strlen+0x26>
     c4a:	0505                	addi	a0,a0,1
     c4c:	87aa                	mv	a5,a0
     c4e:	4685                	li	a3,1
     c50:	9e89                	subw	a3,a3,a0
     c52:	00f6853b          	addw	a0,a3,a5
     c56:	0785                	addi	a5,a5,1
     c58:	fff7c703          	lbu	a4,-1(a5)
     c5c:	fb7d                	bnez	a4,c52 <strlen+0x14>
    ;
  return n;
}
     c5e:	6422                	ld	s0,8(sp)
     c60:	0141                	addi	sp,sp,16
     c62:	8082                	ret
  for(n = 0; s[n]; n++)
     c64:	4501                	li	a0,0
     c66:	bfe5                	j	c5e <strlen+0x20>

0000000000000c68 <memset>:

void*
memset(void *dst, int c, uint n)
{
     c68:	1141                	addi	sp,sp,-16
     c6a:	e422                	sd	s0,8(sp)
     c6c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     c6e:	ca19                	beqz	a2,c84 <memset+0x1c>
     c70:	87aa                	mv	a5,a0
     c72:	1602                	slli	a2,a2,0x20
     c74:	9201                	srli	a2,a2,0x20
     c76:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
     c7a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     c7e:	0785                	addi	a5,a5,1
     c80:	fee79de3          	bne	a5,a4,c7a <memset+0x12>
  }
  return dst;
}
     c84:	6422                	ld	s0,8(sp)
     c86:	0141                	addi	sp,sp,16
     c88:	8082                	ret

0000000000000c8a <strchr>:

char*
strchr(const char *s, char c)
{
     c8a:	1141                	addi	sp,sp,-16
     c8c:	e422                	sd	s0,8(sp)
     c8e:	0800                	addi	s0,sp,16
  for(; *s; s++)
     c90:	00054783          	lbu	a5,0(a0)
     c94:	cb99                	beqz	a5,caa <strchr+0x20>
    if(*s == c)
     c96:	00f58763          	beq	a1,a5,ca4 <strchr+0x1a>
  for(; *s; s++)
     c9a:	0505                	addi	a0,a0,1
     c9c:	00054783          	lbu	a5,0(a0)
     ca0:	fbfd                	bnez	a5,c96 <strchr+0xc>
      return (char*)s;
  return 0;
     ca2:	4501                	li	a0,0
}
     ca4:	6422                	ld	s0,8(sp)
     ca6:	0141                	addi	sp,sp,16
     ca8:	8082                	ret
  return 0;
     caa:	4501                	li	a0,0
     cac:	bfe5                	j	ca4 <strchr+0x1a>

0000000000000cae <gets>:

char*
gets(char *buf, int max)
{
     cae:	711d                	addi	sp,sp,-96
     cb0:	ec86                	sd	ra,88(sp)
     cb2:	e8a2                	sd	s0,80(sp)
     cb4:	e4a6                	sd	s1,72(sp)
     cb6:	e0ca                	sd	s2,64(sp)
     cb8:	fc4e                	sd	s3,56(sp)
     cba:	f852                	sd	s4,48(sp)
     cbc:	f456                	sd	s5,40(sp)
     cbe:	f05a                	sd	s6,32(sp)
     cc0:	ec5e                	sd	s7,24(sp)
     cc2:	1080                	addi	s0,sp,96
     cc4:	8baa                	mv	s7,a0
     cc6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     cc8:	892a                	mv	s2,a0
     cca:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     ccc:	4aa9                	li	s5,10
     cce:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     cd0:	89a6                	mv	s3,s1
     cd2:	2485                	addiw	s1,s1,1
     cd4:	0344d863          	bge	s1,s4,d04 <gets+0x56>
    cc = read(0, &c, 1);
     cd8:	4605                	li	a2,1
     cda:	faf40593          	addi	a1,s0,-81
     cde:	4501                	li	a0,0
     ce0:	00000097          	auipc	ra,0x0
     ce4:	19c080e7          	jalr	412(ra) # e7c <read>
    if(cc < 1)
     ce8:	00a05e63          	blez	a0,d04 <gets+0x56>
    buf[i++] = c;
     cec:	faf44783          	lbu	a5,-81(s0)
     cf0:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     cf4:	01578763          	beq	a5,s5,d02 <gets+0x54>
     cf8:	0905                	addi	s2,s2,1
     cfa:	fd679be3          	bne	a5,s6,cd0 <gets+0x22>
  for(i=0; i+1 < max; ){
     cfe:	89a6                	mv	s3,s1
     d00:	a011                	j	d04 <gets+0x56>
     d02:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     d04:	99de                	add	s3,s3,s7
     d06:	00098023          	sb	zero,0(s3)
  return buf;
}
     d0a:	855e                	mv	a0,s7
     d0c:	60e6                	ld	ra,88(sp)
     d0e:	6446                	ld	s0,80(sp)
     d10:	64a6                	ld	s1,72(sp)
     d12:	6906                	ld	s2,64(sp)
     d14:	79e2                	ld	s3,56(sp)
     d16:	7a42                	ld	s4,48(sp)
     d18:	7aa2                	ld	s5,40(sp)
     d1a:	7b02                	ld	s6,32(sp)
     d1c:	6be2                	ld	s7,24(sp)
     d1e:	6125                	addi	sp,sp,96
     d20:	8082                	ret

0000000000000d22 <stat>:

int
stat(const char *n, struct stat *st)
{
     d22:	1101                	addi	sp,sp,-32
     d24:	ec06                	sd	ra,24(sp)
     d26:	e822                	sd	s0,16(sp)
     d28:	e426                	sd	s1,8(sp)
     d2a:	e04a                	sd	s2,0(sp)
     d2c:	1000                	addi	s0,sp,32
     d2e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     d30:	4581                	li	a1,0
     d32:	00000097          	auipc	ra,0x0
     d36:	172080e7          	jalr	370(ra) # ea4 <open>
  if(fd < 0)
     d3a:	02054563          	bltz	a0,d64 <stat+0x42>
     d3e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     d40:	85ca                	mv	a1,s2
     d42:	00000097          	auipc	ra,0x0
     d46:	17a080e7          	jalr	378(ra) # ebc <fstat>
     d4a:	892a                	mv	s2,a0
  close(fd);
     d4c:	8526                	mv	a0,s1
     d4e:	00000097          	auipc	ra,0x0
     d52:	13e080e7          	jalr	318(ra) # e8c <close>
  return r;
}
     d56:	854a                	mv	a0,s2
     d58:	60e2                	ld	ra,24(sp)
     d5a:	6442                	ld	s0,16(sp)
     d5c:	64a2                	ld	s1,8(sp)
     d5e:	6902                	ld	s2,0(sp)
     d60:	6105                	addi	sp,sp,32
     d62:	8082                	ret
    return -1;
     d64:	597d                	li	s2,-1
     d66:	bfc5                	j	d56 <stat+0x34>

0000000000000d68 <atoi>:

int
atoi(const char *s)
{
     d68:	1141                	addi	sp,sp,-16
     d6a:	e422                	sd	s0,8(sp)
     d6c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     d6e:	00054603          	lbu	a2,0(a0)
     d72:	fd06079b          	addiw	a5,a2,-48
     d76:	0ff7f793          	andi	a5,a5,255
     d7a:	4725                	li	a4,9
     d7c:	02f76963          	bltu	a4,a5,dae <atoi+0x46>
     d80:	86aa                	mv	a3,a0
  n = 0;
     d82:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     d84:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     d86:	0685                	addi	a3,a3,1
     d88:	0025179b          	slliw	a5,a0,0x2
     d8c:	9fa9                	addw	a5,a5,a0
     d8e:	0017979b          	slliw	a5,a5,0x1
     d92:	9fb1                	addw	a5,a5,a2
     d94:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     d98:	0006c603          	lbu	a2,0(a3)
     d9c:	fd06071b          	addiw	a4,a2,-48
     da0:	0ff77713          	andi	a4,a4,255
     da4:	fee5f1e3          	bgeu	a1,a4,d86 <atoi+0x1e>
  return n;
}
     da8:	6422                	ld	s0,8(sp)
     daa:	0141                	addi	sp,sp,16
     dac:	8082                	ret
  n = 0;
     dae:	4501                	li	a0,0
     db0:	bfe5                	j	da8 <atoi+0x40>

0000000000000db2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     db2:	1141                	addi	sp,sp,-16
     db4:	e422                	sd	s0,8(sp)
     db6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     db8:	02b57463          	bgeu	a0,a1,de0 <memmove+0x2e>
    while(n-- > 0)
     dbc:	00c05f63          	blez	a2,dda <memmove+0x28>
     dc0:	1602                	slli	a2,a2,0x20
     dc2:	9201                	srli	a2,a2,0x20
     dc4:	00c507b3          	add	a5,a0,a2
  dst = vdst;
     dc8:	872a                	mv	a4,a0
      *dst++ = *src++;
     dca:	0585                	addi	a1,a1,1
     dcc:	0705                	addi	a4,a4,1
     dce:	fff5c683          	lbu	a3,-1(a1)
     dd2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     dd6:	fee79ae3          	bne	a5,a4,dca <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     dda:	6422                	ld	s0,8(sp)
     ddc:	0141                	addi	sp,sp,16
     dde:	8082                	ret
    dst += n;
     de0:	00c50733          	add	a4,a0,a2
    src += n;
     de4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     de6:	fec05ae3          	blez	a2,dda <memmove+0x28>
     dea:	fff6079b          	addiw	a5,a2,-1
     dee:	1782                	slli	a5,a5,0x20
     df0:	9381                	srli	a5,a5,0x20
     df2:	fff7c793          	not	a5,a5
     df6:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     df8:	15fd                	addi	a1,a1,-1
     dfa:	177d                	addi	a4,a4,-1
     dfc:	0005c683          	lbu	a3,0(a1)
     e00:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     e04:	fee79ae3          	bne	a5,a4,df8 <memmove+0x46>
     e08:	bfc9                	j	dda <memmove+0x28>

0000000000000e0a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     e0a:	1141                	addi	sp,sp,-16
     e0c:	e422                	sd	s0,8(sp)
     e0e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     e10:	ca05                	beqz	a2,e40 <memcmp+0x36>
     e12:	fff6069b          	addiw	a3,a2,-1
     e16:	1682                	slli	a3,a3,0x20
     e18:	9281                	srli	a3,a3,0x20
     e1a:	0685                	addi	a3,a3,1
     e1c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     e1e:	00054783          	lbu	a5,0(a0)
     e22:	0005c703          	lbu	a4,0(a1)
     e26:	00e79863          	bne	a5,a4,e36 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     e2a:	0505                	addi	a0,a0,1
    p2++;
     e2c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     e2e:	fed518e3          	bne	a0,a3,e1e <memcmp+0x14>
  }
  return 0;
     e32:	4501                	li	a0,0
     e34:	a019                	j	e3a <memcmp+0x30>
      return *p1 - *p2;
     e36:	40e7853b          	subw	a0,a5,a4
}
     e3a:	6422                	ld	s0,8(sp)
     e3c:	0141                	addi	sp,sp,16
     e3e:	8082                	ret
  return 0;
     e40:	4501                	li	a0,0
     e42:	bfe5                	j	e3a <memcmp+0x30>

0000000000000e44 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     e44:	1141                	addi	sp,sp,-16
     e46:	e406                	sd	ra,8(sp)
     e48:	e022                	sd	s0,0(sp)
     e4a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     e4c:	00000097          	auipc	ra,0x0
     e50:	f66080e7          	jalr	-154(ra) # db2 <memmove>
}
     e54:	60a2                	ld	ra,8(sp)
     e56:	6402                	ld	s0,0(sp)
     e58:	0141                	addi	sp,sp,16
     e5a:	8082                	ret

0000000000000e5c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     e5c:	4885                	li	a7,1
 ecall
     e5e:	00000073          	ecall
 ret
     e62:	8082                	ret

0000000000000e64 <exit>:
.global exit
exit:
 li a7, SYS_exit
     e64:	4889                	li	a7,2
 ecall
     e66:	00000073          	ecall
 ret
     e6a:	8082                	ret

0000000000000e6c <wait>:
.global wait
wait:
 li a7, SYS_wait
     e6c:	488d                	li	a7,3
 ecall
     e6e:	00000073          	ecall
 ret
     e72:	8082                	ret

0000000000000e74 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     e74:	4891                	li	a7,4
 ecall
     e76:	00000073          	ecall
 ret
     e7a:	8082                	ret

0000000000000e7c <read>:
.global read
read:
 li a7, SYS_read
     e7c:	4895                	li	a7,5
 ecall
     e7e:	00000073          	ecall
 ret
     e82:	8082                	ret

0000000000000e84 <write>:
.global write
write:
 li a7, SYS_write
     e84:	48c1                	li	a7,16
 ecall
     e86:	00000073          	ecall
 ret
     e8a:	8082                	ret

0000000000000e8c <close>:
.global close
close:
 li a7, SYS_close
     e8c:	48d5                	li	a7,21
 ecall
     e8e:	00000073          	ecall
 ret
     e92:	8082                	ret

0000000000000e94 <kill>:
.global kill
kill:
 li a7, SYS_kill
     e94:	4899                	li	a7,6
 ecall
     e96:	00000073          	ecall
 ret
     e9a:	8082                	ret

0000000000000e9c <exec>:
.global exec
exec:
 li a7, SYS_exec
     e9c:	489d                	li	a7,7
 ecall
     e9e:	00000073          	ecall
 ret
     ea2:	8082                	ret

0000000000000ea4 <open>:
.global open
open:
 li a7, SYS_open
     ea4:	48bd                	li	a7,15
 ecall
     ea6:	00000073          	ecall
 ret
     eaa:	8082                	ret

0000000000000eac <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     eac:	48c5                	li	a7,17
 ecall
     eae:	00000073          	ecall
 ret
     eb2:	8082                	ret

0000000000000eb4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     eb4:	48c9                	li	a7,18
 ecall
     eb6:	00000073          	ecall
 ret
     eba:	8082                	ret

0000000000000ebc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     ebc:	48a1                	li	a7,8
 ecall
     ebe:	00000073          	ecall
 ret
     ec2:	8082                	ret

0000000000000ec4 <link>:
.global link
link:
 li a7, SYS_link
     ec4:	48cd                	li	a7,19
 ecall
     ec6:	00000073          	ecall
 ret
     eca:	8082                	ret

0000000000000ecc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     ecc:	48d1                	li	a7,20
 ecall
     ece:	00000073          	ecall
 ret
     ed2:	8082                	ret

0000000000000ed4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     ed4:	48a5                	li	a7,9
 ecall
     ed6:	00000073          	ecall
 ret
     eda:	8082                	ret

0000000000000edc <dup>:
.global dup
dup:
 li a7, SYS_dup
     edc:	48a9                	li	a7,10
 ecall
     ede:	00000073          	ecall
 ret
     ee2:	8082                	ret

0000000000000ee4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     ee4:	48ad                	li	a7,11
 ecall
     ee6:	00000073          	ecall
 ret
     eea:	8082                	ret

0000000000000eec <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     eec:	48b1                	li	a7,12
 ecall
     eee:	00000073          	ecall
 ret
     ef2:	8082                	ret

0000000000000ef4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     ef4:	48b5                	li	a7,13
 ecall
     ef6:	00000073          	ecall
 ret
     efa:	8082                	ret

0000000000000efc <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     efc:	48b9                	li	a7,14
 ecall
     efe:	00000073          	ecall
 ret
     f02:	8082                	ret

0000000000000f04 <trace>:
.global trace
trace:
 li a7, SYS_trace
     f04:	48d9                	li	a7,22
 ecall
     f06:	00000073          	ecall
 ret
     f0a:	8082                	ret

0000000000000f0c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     f0c:	1101                	addi	sp,sp,-32
     f0e:	ec06                	sd	ra,24(sp)
     f10:	e822                	sd	s0,16(sp)
     f12:	1000                	addi	s0,sp,32
     f14:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     f18:	4605                	li	a2,1
     f1a:	fef40593          	addi	a1,s0,-17
     f1e:	00000097          	auipc	ra,0x0
     f22:	f66080e7          	jalr	-154(ra) # e84 <write>
}
     f26:	60e2                	ld	ra,24(sp)
     f28:	6442                	ld	s0,16(sp)
     f2a:	6105                	addi	sp,sp,32
     f2c:	8082                	ret

0000000000000f2e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     f2e:	7139                	addi	sp,sp,-64
     f30:	fc06                	sd	ra,56(sp)
     f32:	f822                	sd	s0,48(sp)
     f34:	f426                	sd	s1,40(sp)
     f36:	f04a                	sd	s2,32(sp)
     f38:	ec4e                	sd	s3,24(sp)
     f3a:	0080                	addi	s0,sp,64
     f3c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     f3e:	c299                	beqz	a3,f44 <printint+0x16>
     f40:	0805c863          	bltz	a1,fd0 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     f44:	2581                	sext.w	a1,a1
  neg = 0;
     f46:	4881                	li	a7,0
     f48:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     f4c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     f4e:	2601                	sext.w	a2,a2
     f50:	00000517          	auipc	a0,0x0
     f54:	58850513          	addi	a0,a0,1416 # 14d8 <digits>
     f58:	883a                	mv	a6,a4
     f5a:	2705                	addiw	a4,a4,1
     f5c:	02c5f7bb          	remuw	a5,a1,a2
     f60:	1782                	slli	a5,a5,0x20
     f62:	9381                	srli	a5,a5,0x20
     f64:	97aa                	add	a5,a5,a0
     f66:	0007c783          	lbu	a5,0(a5)
     f6a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     f6e:	0005879b          	sext.w	a5,a1
     f72:	02c5d5bb          	divuw	a1,a1,a2
     f76:	0685                	addi	a3,a3,1
     f78:	fec7f0e3          	bgeu	a5,a2,f58 <printint+0x2a>
  if(neg)
     f7c:	00088b63          	beqz	a7,f92 <printint+0x64>
    buf[i++] = '-';
     f80:	fd040793          	addi	a5,s0,-48
     f84:	973e                	add	a4,a4,a5
     f86:	02d00793          	li	a5,45
     f8a:	fef70823          	sb	a5,-16(a4)
     f8e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     f92:	02e05863          	blez	a4,fc2 <printint+0x94>
     f96:	fc040793          	addi	a5,s0,-64
     f9a:	00e78933          	add	s2,a5,a4
     f9e:	fff78993          	addi	s3,a5,-1
     fa2:	99ba                	add	s3,s3,a4
     fa4:	377d                	addiw	a4,a4,-1
     fa6:	1702                	slli	a4,a4,0x20
     fa8:	9301                	srli	a4,a4,0x20
     faa:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     fae:	fff94583          	lbu	a1,-1(s2)
     fb2:	8526                	mv	a0,s1
     fb4:	00000097          	auipc	ra,0x0
     fb8:	f58080e7          	jalr	-168(ra) # f0c <putc>
  while(--i >= 0)
     fbc:	197d                	addi	s2,s2,-1
     fbe:	ff3918e3          	bne	s2,s3,fae <printint+0x80>
}
     fc2:	70e2                	ld	ra,56(sp)
     fc4:	7442                	ld	s0,48(sp)
     fc6:	74a2                	ld	s1,40(sp)
     fc8:	7902                	ld	s2,32(sp)
     fca:	69e2                	ld	s3,24(sp)
     fcc:	6121                	addi	sp,sp,64
     fce:	8082                	ret
    x = -xx;
     fd0:	40b005bb          	negw	a1,a1
    neg = 1;
     fd4:	4885                	li	a7,1
    x = -xx;
     fd6:	bf8d                	j	f48 <printint+0x1a>

0000000000000fd8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
     fd8:	7119                	addi	sp,sp,-128
     fda:	fc86                	sd	ra,120(sp)
     fdc:	f8a2                	sd	s0,112(sp)
     fde:	f4a6                	sd	s1,104(sp)
     fe0:	f0ca                	sd	s2,96(sp)
     fe2:	ecce                	sd	s3,88(sp)
     fe4:	e8d2                	sd	s4,80(sp)
     fe6:	e4d6                	sd	s5,72(sp)
     fe8:	e0da                	sd	s6,64(sp)
     fea:	fc5e                	sd	s7,56(sp)
     fec:	f862                	sd	s8,48(sp)
     fee:	f466                	sd	s9,40(sp)
     ff0:	f06a                	sd	s10,32(sp)
     ff2:	ec6e                	sd	s11,24(sp)
     ff4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
     ff6:	0005c903          	lbu	s2,0(a1)
     ffa:	18090f63          	beqz	s2,1198 <vprintf+0x1c0>
     ffe:	8aaa                	mv	s5,a0
    1000:	8b32                	mv	s6,a2
    1002:	00158493          	addi	s1,a1,1
  state = 0;
    1006:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    1008:	02500a13          	li	s4,37
      if(c == 'd'){
    100c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    1010:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    1014:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    1018:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    101c:	00000b97          	auipc	s7,0x0
    1020:	4bcb8b93          	addi	s7,s7,1212 # 14d8 <digits>
    1024:	a839                	j	1042 <vprintf+0x6a>
        putc(fd, c);
    1026:	85ca                	mv	a1,s2
    1028:	8556                	mv	a0,s5
    102a:	00000097          	auipc	ra,0x0
    102e:	ee2080e7          	jalr	-286(ra) # f0c <putc>
    1032:	a019                	j	1038 <vprintf+0x60>
    } else if(state == '%'){
    1034:	01498f63          	beq	s3,s4,1052 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    1038:	0485                	addi	s1,s1,1
    103a:	fff4c903          	lbu	s2,-1(s1)
    103e:	14090d63          	beqz	s2,1198 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    1042:	0009079b          	sext.w	a5,s2
    if(state == 0){
    1046:	fe0997e3          	bnez	s3,1034 <vprintf+0x5c>
      if(c == '%'){
    104a:	fd479ee3          	bne	a5,s4,1026 <vprintf+0x4e>
        state = '%';
    104e:	89be                	mv	s3,a5
    1050:	b7e5                	j	1038 <vprintf+0x60>
      if(c == 'd'){
    1052:	05878063          	beq	a5,s8,1092 <vprintf+0xba>
      } else if(c == 'l') {
    1056:	05978c63          	beq	a5,s9,10ae <vprintf+0xd6>
      } else if(c == 'x') {
    105a:	07a78863          	beq	a5,s10,10ca <vprintf+0xf2>
      } else if(c == 'p') {
    105e:	09b78463          	beq	a5,s11,10e6 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    1062:	07300713          	li	a4,115
    1066:	0ce78663          	beq	a5,a4,1132 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    106a:	06300713          	li	a4,99
    106e:	0ee78e63          	beq	a5,a4,116a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    1072:	11478863          	beq	a5,s4,1182 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    1076:	85d2                	mv	a1,s4
    1078:	8556                	mv	a0,s5
    107a:	00000097          	auipc	ra,0x0
    107e:	e92080e7          	jalr	-366(ra) # f0c <putc>
        putc(fd, c);
    1082:	85ca                	mv	a1,s2
    1084:	8556                	mv	a0,s5
    1086:	00000097          	auipc	ra,0x0
    108a:	e86080e7          	jalr	-378(ra) # f0c <putc>
      }
      state = 0;
    108e:	4981                	li	s3,0
    1090:	b765                	j	1038 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    1092:	008b0913          	addi	s2,s6,8
    1096:	4685                	li	a3,1
    1098:	4629                	li	a2,10
    109a:	000b2583          	lw	a1,0(s6)
    109e:	8556                	mv	a0,s5
    10a0:	00000097          	auipc	ra,0x0
    10a4:	e8e080e7          	jalr	-370(ra) # f2e <printint>
    10a8:	8b4a                	mv	s6,s2
      state = 0;
    10aa:	4981                	li	s3,0
    10ac:	b771                	j	1038 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    10ae:	008b0913          	addi	s2,s6,8
    10b2:	4681                	li	a3,0
    10b4:	4629                	li	a2,10
    10b6:	000b2583          	lw	a1,0(s6)
    10ba:	8556                	mv	a0,s5
    10bc:	00000097          	auipc	ra,0x0
    10c0:	e72080e7          	jalr	-398(ra) # f2e <printint>
    10c4:	8b4a                	mv	s6,s2
      state = 0;
    10c6:	4981                	li	s3,0
    10c8:	bf85                	j	1038 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    10ca:	008b0913          	addi	s2,s6,8
    10ce:	4681                	li	a3,0
    10d0:	4641                	li	a2,16
    10d2:	000b2583          	lw	a1,0(s6)
    10d6:	8556                	mv	a0,s5
    10d8:	00000097          	auipc	ra,0x0
    10dc:	e56080e7          	jalr	-426(ra) # f2e <printint>
    10e0:	8b4a                	mv	s6,s2
      state = 0;
    10e2:	4981                	li	s3,0
    10e4:	bf91                	j	1038 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    10e6:	008b0793          	addi	a5,s6,8
    10ea:	f8f43423          	sd	a5,-120(s0)
    10ee:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    10f2:	03000593          	li	a1,48
    10f6:	8556                	mv	a0,s5
    10f8:	00000097          	auipc	ra,0x0
    10fc:	e14080e7          	jalr	-492(ra) # f0c <putc>
  putc(fd, 'x');
    1100:	85ea                	mv	a1,s10
    1102:	8556                	mv	a0,s5
    1104:	00000097          	auipc	ra,0x0
    1108:	e08080e7          	jalr	-504(ra) # f0c <putc>
    110c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    110e:	03c9d793          	srli	a5,s3,0x3c
    1112:	97de                	add	a5,a5,s7
    1114:	0007c583          	lbu	a1,0(a5)
    1118:	8556                	mv	a0,s5
    111a:	00000097          	auipc	ra,0x0
    111e:	df2080e7          	jalr	-526(ra) # f0c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    1122:	0992                	slli	s3,s3,0x4
    1124:	397d                	addiw	s2,s2,-1
    1126:	fe0914e3          	bnez	s2,110e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    112a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    112e:	4981                	li	s3,0
    1130:	b721                	j	1038 <vprintf+0x60>
        s = va_arg(ap, char*);
    1132:	008b0993          	addi	s3,s6,8
    1136:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    113a:	02090163          	beqz	s2,115c <vprintf+0x184>
        while(*s != 0){
    113e:	00094583          	lbu	a1,0(s2)
    1142:	c9a1                	beqz	a1,1192 <vprintf+0x1ba>
          putc(fd, *s);
    1144:	8556                	mv	a0,s5
    1146:	00000097          	auipc	ra,0x0
    114a:	dc6080e7          	jalr	-570(ra) # f0c <putc>
          s++;
    114e:	0905                	addi	s2,s2,1
        while(*s != 0){
    1150:	00094583          	lbu	a1,0(s2)
    1154:	f9e5                	bnez	a1,1144 <vprintf+0x16c>
        s = va_arg(ap, char*);
    1156:	8b4e                	mv	s6,s3
      state = 0;
    1158:	4981                	li	s3,0
    115a:	bdf9                	j	1038 <vprintf+0x60>
          s = "(null)";
    115c:	00000917          	auipc	s2,0x0
    1160:	37490913          	addi	s2,s2,884 # 14d0 <malloc+0x22e>
        while(*s != 0){
    1164:	02800593          	li	a1,40
    1168:	bff1                	j	1144 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    116a:	008b0913          	addi	s2,s6,8
    116e:	000b4583          	lbu	a1,0(s6)
    1172:	8556                	mv	a0,s5
    1174:	00000097          	auipc	ra,0x0
    1178:	d98080e7          	jalr	-616(ra) # f0c <putc>
    117c:	8b4a                	mv	s6,s2
      state = 0;
    117e:	4981                	li	s3,0
    1180:	bd65                	j	1038 <vprintf+0x60>
        putc(fd, c);
    1182:	85d2                	mv	a1,s4
    1184:	8556                	mv	a0,s5
    1186:	00000097          	auipc	ra,0x0
    118a:	d86080e7          	jalr	-634(ra) # f0c <putc>
      state = 0;
    118e:	4981                	li	s3,0
    1190:	b565                	j	1038 <vprintf+0x60>
        s = va_arg(ap, char*);
    1192:	8b4e                	mv	s6,s3
      state = 0;
    1194:	4981                	li	s3,0
    1196:	b54d                	j	1038 <vprintf+0x60>
    }
  }
}
    1198:	70e6                	ld	ra,120(sp)
    119a:	7446                	ld	s0,112(sp)
    119c:	74a6                	ld	s1,104(sp)
    119e:	7906                	ld	s2,96(sp)
    11a0:	69e6                	ld	s3,88(sp)
    11a2:	6a46                	ld	s4,80(sp)
    11a4:	6aa6                	ld	s5,72(sp)
    11a6:	6b06                	ld	s6,64(sp)
    11a8:	7be2                	ld	s7,56(sp)
    11aa:	7c42                	ld	s8,48(sp)
    11ac:	7ca2                	ld	s9,40(sp)
    11ae:	7d02                	ld	s10,32(sp)
    11b0:	6de2                	ld	s11,24(sp)
    11b2:	6109                	addi	sp,sp,128
    11b4:	8082                	ret

00000000000011b6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    11b6:	715d                	addi	sp,sp,-80
    11b8:	ec06                	sd	ra,24(sp)
    11ba:	e822                	sd	s0,16(sp)
    11bc:	1000                	addi	s0,sp,32
    11be:	e010                	sd	a2,0(s0)
    11c0:	e414                	sd	a3,8(s0)
    11c2:	e818                	sd	a4,16(s0)
    11c4:	ec1c                	sd	a5,24(s0)
    11c6:	03043023          	sd	a6,32(s0)
    11ca:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    11ce:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    11d2:	8622                	mv	a2,s0
    11d4:	00000097          	auipc	ra,0x0
    11d8:	e04080e7          	jalr	-508(ra) # fd8 <vprintf>
}
    11dc:	60e2                	ld	ra,24(sp)
    11de:	6442                	ld	s0,16(sp)
    11e0:	6161                	addi	sp,sp,80
    11e2:	8082                	ret

00000000000011e4 <printf>:

void
printf(const char *fmt, ...)
{
    11e4:	711d                	addi	sp,sp,-96
    11e6:	ec06                	sd	ra,24(sp)
    11e8:	e822                	sd	s0,16(sp)
    11ea:	1000                	addi	s0,sp,32
    11ec:	e40c                	sd	a1,8(s0)
    11ee:	e810                	sd	a2,16(s0)
    11f0:	ec14                	sd	a3,24(s0)
    11f2:	f018                	sd	a4,32(s0)
    11f4:	f41c                	sd	a5,40(s0)
    11f6:	03043823          	sd	a6,48(s0)
    11fa:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    11fe:	00840613          	addi	a2,s0,8
    1202:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    1206:	85aa                	mv	a1,a0
    1208:	4505                	li	a0,1
    120a:	00000097          	auipc	ra,0x0
    120e:	dce080e7          	jalr	-562(ra) # fd8 <vprintf>
}
    1212:	60e2                	ld	ra,24(sp)
    1214:	6442                	ld	s0,16(sp)
    1216:	6125                	addi	sp,sp,96
    1218:	8082                	ret

000000000000121a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    121a:	1141                	addi	sp,sp,-16
    121c:	e422                	sd	s0,8(sp)
    121e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1220:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1224:	00000797          	auipc	a5,0x0
    1228:	2dc7b783          	ld	a5,732(a5) # 1500 <freep>
    122c:	a805                	j	125c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    122e:	4618                	lw	a4,8(a2)
    1230:	9db9                	addw	a1,a1,a4
    1232:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1236:	6398                	ld	a4,0(a5)
    1238:	6318                	ld	a4,0(a4)
    123a:	fee53823          	sd	a4,-16(a0)
    123e:	a091                	j	1282 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1240:	ff852703          	lw	a4,-8(a0)
    1244:	9e39                	addw	a2,a2,a4
    1246:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    1248:	ff053703          	ld	a4,-16(a0)
    124c:	e398                	sd	a4,0(a5)
    124e:	a099                	j	1294 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1250:	6398                	ld	a4,0(a5)
    1252:	00e7e463          	bltu	a5,a4,125a <free+0x40>
    1256:	00e6ea63          	bltu	a3,a4,126a <free+0x50>
{
    125a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    125c:	fed7fae3          	bgeu	a5,a3,1250 <free+0x36>
    1260:	6398                	ld	a4,0(a5)
    1262:	00e6e463          	bltu	a3,a4,126a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1266:	fee7eae3          	bltu	a5,a4,125a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    126a:	ff852583          	lw	a1,-8(a0)
    126e:	6390                	ld	a2,0(a5)
    1270:	02059813          	slli	a6,a1,0x20
    1274:	01c85713          	srli	a4,a6,0x1c
    1278:	9736                	add	a4,a4,a3
    127a:	fae60ae3          	beq	a2,a4,122e <free+0x14>
    bp->s.ptr = p->s.ptr;
    127e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    1282:	4790                	lw	a2,8(a5)
    1284:	02061593          	slli	a1,a2,0x20
    1288:	01c5d713          	srli	a4,a1,0x1c
    128c:	973e                	add	a4,a4,a5
    128e:	fae689e3          	beq	a3,a4,1240 <free+0x26>
  } else
    p->s.ptr = bp;
    1292:	e394                	sd	a3,0(a5)
  freep = p;
    1294:	00000717          	auipc	a4,0x0
    1298:	26f73623          	sd	a5,620(a4) # 1500 <freep>
}
    129c:	6422                	ld	s0,8(sp)
    129e:	0141                	addi	sp,sp,16
    12a0:	8082                	ret

00000000000012a2 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    12a2:	7139                	addi	sp,sp,-64
    12a4:	fc06                	sd	ra,56(sp)
    12a6:	f822                	sd	s0,48(sp)
    12a8:	f426                	sd	s1,40(sp)
    12aa:	f04a                	sd	s2,32(sp)
    12ac:	ec4e                	sd	s3,24(sp)
    12ae:	e852                	sd	s4,16(sp)
    12b0:	e456                	sd	s5,8(sp)
    12b2:	e05a                	sd	s6,0(sp)
    12b4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    12b6:	02051493          	slli	s1,a0,0x20
    12ba:	9081                	srli	s1,s1,0x20
    12bc:	04bd                	addi	s1,s1,15
    12be:	8091                	srli	s1,s1,0x4
    12c0:	0014899b          	addiw	s3,s1,1
    12c4:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    12c6:	00000517          	auipc	a0,0x0
    12ca:	23a53503          	ld	a0,570(a0) # 1500 <freep>
    12ce:	c515                	beqz	a0,12fa <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    12d0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    12d2:	4798                	lw	a4,8(a5)
    12d4:	02977f63          	bgeu	a4,s1,1312 <malloc+0x70>
    12d8:	8a4e                	mv	s4,s3
    12da:	0009871b          	sext.w	a4,s3
    12de:	6685                	lui	a3,0x1
    12e0:	00d77363          	bgeu	a4,a3,12e6 <malloc+0x44>
    12e4:	6a05                	lui	s4,0x1
    12e6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    12ea:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    12ee:	00000917          	auipc	s2,0x0
    12f2:	21290913          	addi	s2,s2,530 # 1500 <freep>
  if(p == (char*)-1)
    12f6:	5afd                	li	s5,-1
    12f8:	a895                	j	136c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    12fa:	00000797          	auipc	a5,0x0
    12fe:	27678793          	addi	a5,a5,630 # 1570 <base>
    1302:	00000717          	auipc	a4,0x0
    1306:	1ef73f23          	sd	a5,510(a4) # 1500 <freep>
    130a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    130c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    1310:	b7e1                	j	12d8 <malloc+0x36>
      if(p->s.size == nunits)
    1312:	02e48c63          	beq	s1,a4,134a <malloc+0xa8>
        p->s.size -= nunits;
    1316:	4137073b          	subw	a4,a4,s3
    131a:	c798                	sw	a4,8(a5)
        p += p->s.size;
    131c:	02071693          	slli	a3,a4,0x20
    1320:	01c6d713          	srli	a4,a3,0x1c
    1324:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    1326:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    132a:	00000717          	auipc	a4,0x0
    132e:	1ca73b23          	sd	a0,470(a4) # 1500 <freep>
      return (void*)(p + 1);
    1332:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    1336:	70e2                	ld	ra,56(sp)
    1338:	7442                	ld	s0,48(sp)
    133a:	74a2                	ld	s1,40(sp)
    133c:	7902                	ld	s2,32(sp)
    133e:	69e2                	ld	s3,24(sp)
    1340:	6a42                	ld	s4,16(sp)
    1342:	6aa2                	ld	s5,8(sp)
    1344:	6b02                	ld	s6,0(sp)
    1346:	6121                	addi	sp,sp,64
    1348:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    134a:	6398                	ld	a4,0(a5)
    134c:	e118                	sd	a4,0(a0)
    134e:	bff1                	j	132a <malloc+0x88>
  hp->s.size = nu;
    1350:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    1354:	0541                	addi	a0,a0,16
    1356:	00000097          	auipc	ra,0x0
    135a:	ec4080e7          	jalr	-316(ra) # 121a <free>
  return freep;
    135e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1362:	d971                	beqz	a0,1336 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1364:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1366:	4798                	lw	a4,8(a5)
    1368:	fa9775e3          	bgeu	a4,s1,1312 <malloc+0x70>
    if(p == freep)
    136c:	00093703          	ld	a4,0(s2)
    1370:	853e                	mv	a0,a5
    1372:	fef719e3          	bne	a4,a5,1364 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    1376:	8552                	mv	a0,s4
    1378:	00000097          	auipc	ra,0x0
    137c:	b74080e7          	jalr	-1164(ra) # eec <sbrk>
  if(p == (char*)-1)
    1380:	fd5518e3          	bne	a0,s5,1350 <malloc+0xae>
        return 0;
    1384:	4501                	li	a0,0
    1386:	bf45                	j	1336 <malloc+0x94>
