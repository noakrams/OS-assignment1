// #include "kernel/types.h"
// #include "user/user.h"
// #include "kernel/fcntl.h"
// #include "kernel/syscall.h"
// #include "kernel/perf.h"


// int main(int argc, char** argv){

//     struct perf performance;
//     int x =1000 ;

//     int pid;
//     pid = fork ();
//     if(pid == 0){
//         printf ("i'm the child\n");
//         wait(&x);
//         exit (0);
//     }
//     else{
//         printf ("i'm the father\n");

//     }


//     fprintf(2, "ctime is %d\n", performance.ctime);
//     fprintf(2, "ttime is %d\n", performance.ttime);
//     fprintf(2, "stime is %d\n", performance.stime);
//     fprintf(2, "retime is %d\n", performance.retime);
//     fprintf(2, "rutime is %d\n", performance.rutime);
//     fprintf(2, "average_bursttime is %d\n", performance.average_bursttime);

//     exit(0);
// }