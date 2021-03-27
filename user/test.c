#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"

int main(int argc, char** argv){
    fprintf(2, "Hello world!\n");
    //mask=(1<< SYS_fork)|( 1<< SYS_kill)| ( 1<< SYS_sbrk) | ( 1<< SYS_write);
    int mask=(1<< SYS_fork); //
    sleep(1); //doesn't print this sleep
    trace(mask, getpid());
    int cpid=fork();//prints fork once
    if (cpid==0){
        fork();// prints fork for the second time - the first son forks
        mask= (1 << SYS_sleep); //to turn on only the sleep bit
        //mask= (1<< 1)|(1<< 13); you can uncomment this inorder to check you print for both fork and sleep syscalls
        trace(mask, getpid()); //the first son and the grandchilde changes mask to print sleep
        sleep(1);
        fork();//should print nothing
        exit(0);//shold print nothing
    }
    else {
        sleep(10);// the father doesnt pring it - has original mask
    }
    exit(0);
}

/* example for right printing:

3: syscall fork 0-> 4
4: syscall fork 0-> 5
4: syscall sleep -> 0
5: syscall sleep -> 0
 */


//  fprintf(1, "starting mask for: SYS_fork\n");
//  int mask = ((1<< SYS_fork) | (1<<SYS_kill) | (1<<SYS_sbrk));
//  trace(mask, 0);
//  trace(mask, 1);
//  trace(mask, 2);
//  int pid = fork()
//  if(pid != 0){
//      int status;
//      sleep(10);
//      kill(pid);
//      wait(&status);
//      fprintf(2, "Child %d finished with exit status %d\n", pid, status);
//  }
//  else{
//      int my_pid = getpid();
//      fprintf(2, "Child %d is running", my_pid);
//      sbrk(10);
//      sleep(10);
//  }
// fprintf(1, "trace end, exit\n");
// exit(0)