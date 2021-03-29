#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/param.h"

int main(int argc, char** argv){
    fprintf(2, "Hello Prio!\n");
    set_priority(TEST_HIGH_PRIORITY);
    int pid = fork();
    if(pid == 0){//Child
        set_priority(LOW_PRIORITY);
        fprintf(2, "In process with ***low*** priority");
        exit(0);
    }
    else{
        fprintf(2, "In process with ***high*** priority");
    }

    exit(0);
}








