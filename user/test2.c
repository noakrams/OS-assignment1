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



// #include "kernel/types.h"
// #include "user/user.h"
// #include "kernel/fcntl.h"
// #include "kernel/syscall.h"
//
// struct perf {
//   int ctime;                   // process creation time
//   int ttime;                   // process termination time
//   int stime;                   // the total time the process spent on the SLEEPING state
//   int retime;                  // the total time the process spent on the RUNNABLE state
//   int rutime;                  // the total time the process spent on the RUNNING state
//   int average_bursttime;       // approximate estimated burst time
// };
//
//
// int main(int argc, char** argv){
//     struct perf performance;
//     int status;
//     int pid;
//
//     pid = fork();
//
//     if (pid != 0) {
//         sleep(10);
//         wait_stat(&status, &performance);
//
//         printf("pid:%d\nctime:%d\nttime:%d\nstime:%d\nretime:%d\nrutime:%d\nburst:%d\n\n",
//             pid,
//             performance.ctime,
//             performance.ttime,
//             performance.stime,
//             performance.retime,
//             performance.rutime,
//             performance.average_bursttime
//         );
//     } else {
//         int pid2 = fork();
//         int c = 0;
//         int s;
//         if(pid2 != 0){
//             struct perf per;
//             wait_stat(&s, &per);
//             for(int i=0; i<1000000000; i++){
//                 c = c + 1;
//             }
//             sleep(30);
//             printf("pid:%d\nctime:%d\nttime:%d\nstime:%d\nretime:%d\nrutime:%d\nburst:%d\n\n",
//             pid,
//             per.ctime,
//             per.ttime,
//             per.stime,
//             per.retime,
//             per.rutime,
//             per.average_bursttime
//             );
//         }
//         else{
//             sleep(10);
//             exit(0);
//         }
//         exit(0);
//     }
//
//
//     exit(0);
// }


#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"

struct perf {
  int ctime;                   // process creation time
  int ttime;                   // process termination time
  int stime;                   // the total time the process spent on the SLEEPING state
  int retime;                  // the total time the process spent on the RUNNABLE state
  int rutime;                  // the total time the process spent on the RUNNING state
  int average_bursttime;       // approximate estimated burst time
};

int main(int argc, char** argv){
    int sum = 0;
    if(fork() == 0){
        //Child

        sleep(50);
        if(sbrk(5) != 0){
            for(int i = 0 ; i < 3000 && sbrk(1) ; i++){
                if(chdir("\\"))
                    sum += 1;
            }
        }
        printf("sum = %d\n", sum);
    }
    else{
        // Parent
        int status = 0;
        struct perf performance = {0 , 0 , 0 , 0 , 0 , 0};
        wait_stat(&status, &performance);
        printf("status = %d , ctime = %d , ttime = %d , stime = %d , retime = %d , rutime = %d\n" , 
        status,
        performance.ctime,
        performance.ttime,
        performance.stime,
        performance.retime,
        performance.rutime);
    }
    exit(0);
}



