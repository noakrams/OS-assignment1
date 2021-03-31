#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/perf.h"

int main(int argc, char** argv){
    struct perf performance;
    int x =2 ;

    int pid;
    pid = fork ();
    if(pid == 0){
        printf ("i'm the child\n");
        exit (0);
    }
    else{
        printf ("i'm the father\n");
        wait_stat(&x, &performance);
    }

    fprintf(2, "from test, ctime is %d\n", performance.ctime);
    fprintf(2, "from test, ttime is %d\n", performance.ttime);
    fprintf(2, "from test, stime is %d\n", performance.stime);
    fprintf(2, "from test, retime is %d\n", performance.retime);
    fprintf(2, "from test, rutime is %d\n", performance.rutime);
    fprintf(2, "from test, average_bursttime is %d\n", performance.average_bursttime);

    exit(0);
}