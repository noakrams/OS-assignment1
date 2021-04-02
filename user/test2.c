// #include "kernel/types.h"
// #include "user/user.h"
// #include "kernel/fcntl.h"
// //#include <stdlib.h>
// #include "kernel/perf.h"


// int main(int argc, char** argv){
//     fprintf(2, "Hello world!\n");
//     //mask=(1<< SYS_fork)|( 1<< SYS_kill)| ( 1<< SYS_sbrk) | ( 1<< SYS_write);
//     int mask=(1<< 1);
//     //sleep(1); //doesn't print this sleep
//     trace(mask, getpid());
//     int cpid=fork();//prints fork once
//     if (cpid==0){
//         //fork();// prints fork for the second time - the first son forks
//         mask= (1<< 13); //to turn on only the sleep bit
//         //mask= (1<< 1)|(1<< 13); you can uncomment this inorder to check you print for both fork and sleep syscalls
//         trace(mask, getpid()); //the first son and the grandchilde changes mask to print sleep
//         for(int i=0; i<2; i++){
//             sleep(10);
//         }
//         //fork();//should print nothing
//         exit(0);//should print nothing
//     }
//     else {
//         //sleep(10);// the father doesnt pring it - has original mask
//         int stat;
//         struct perf* childperf;
//         if((childperf = (struct perf *)malloc(sizeof(struct perf))) != 0){
//             if(wait_stat(&stat, childperf) > -1){
//                 fprintf(2, "child terminated!\nchild status: %d\n", stat);
//                 fprintf(2, "ctime: %d\nttime: %d\n", childperf->ctime, childperf->ttime);
//                 fprintf(2, "stime: %d\nretime: %d\nrutime: %d\n", childperf->stime, childperf->retime, childperf->rutime);
//                 free(childperf);
//             }
//             else fprintf(2, "wait_stat failed!\n");
//         }
//         else fprintf(2, "kalloc failed!\n");
//     }
//     exit(0);
// }

#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/perf.h"

int main(int argc, char** argv){
    struct perf performance;
    int status;
    int pid;

    pid = fork();

    if (pid != 0) {
        printf("start\n");
        sleep(10);
        set_priority(1);
        wait_stat(&status, &performance);
        printf("pid:%d\nctime:%d\nttime:%d\nstime:%d\nretime:%d\nrutime:%d\nburst:%d\n\n",
            pid,
            performance.ctime,
            performance.ttime,
            performance.stime,
            performance.retime,
            performance.rutime,
            performance.average_bursttime
        );
    } else {
        sleep(50);
    }


    exit(0);
}

