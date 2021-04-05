#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

//funcs
void test_for_bursttime_when_son_just_dies();
void testing_trace();
void extra_complicated_long_test();
void test_bursttime();
void test_for_bursttime_when_proces_with_lots_short_running_time(int num);
void test_with_lots_of_processes_for_order_checks();
void test_three1();
void test_for_FCFS();
void test_for_sleep_task3();
void test_FCFS_with_sleep();
void test_bursttime_SRT();
void test_default();

struct perf {
    int ctime;
    int ttime;
    int stime;
    int retime;
    int rutime;
    int average_bursttime; //average of bursstimes in 100ths (so average*100)

};


int main(int argc, char** argv){
    fprintf(2, "Hello world!\n");
    // testing_trace();//task2
    // extra_complicated_long_test();//mainly for task3
    // test_for_bursttime_when_son_just_dies();// tasks 3 + 4.3. expecte bursttime 500?
    // test_for_bursttime_when_proces_with_lots_short_running_time(100);//with num 100 expects burrst time 0.  
    //                                                                   //with num 2 expects burrst time ? Explenation: 
    //                                                                   // - born with 500
    //                                                                   // after firsr run in while - 250
    //                                                                   // after second run in whike - 125
    //                                                                   // afetr exit - 62
    // test_with_lots_of_processes_for_order_checks();
    // extra_complicated_long_test(); 
    
    // test_for_FCFS();  
    // test_for_sleep_task3();                                                               
    // test_FCFS_with_sleep();
    // test_bursttime(); // bursttime should be 350
    // test_bursttime_SRT();
    test_default();
    
    exit(0);

}

void test_with_lots_of_processes_for_order_checks(){
    int i=0;
    struct perf* performance = malloc(sizeof(struct perf));
    int cpid=fork();
    if(cpid==0){//son like sunshine
        while(i<5){
            int cpid2=fork();
            if(cpid2==0){//grandchild
                if(i%2==0){
                    int k=0;
                    while(k<10000000000000){
                        k++;
                    }
                }
                else{
                    sleep(1);
                    sbrk(2);
                    int k=0;
                    while(k<10000000000000){
                        k++;
                    }
                }
                exit(0); //so grandchild won't make kids
            }
            else{//father (child1)
                wait(0);
            }
            i++;
        }
    }
    else{//father
    int t_pid = wait_stat(0, performance);
    fprintf(1, "terminated pid: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n",
                t_pid, performance->ctime, performance->ttime, performance->stime, performance->retime, performance->rutime,
                 performance->average_bursttime);
    }
}

void test_for_bursttime_when_proces_with_lots_short_running_time(int num){

    int i=0;
    struct perf* performance = malloc(sizeof(struct perf));
    int cpid=fork();
    if(cpid==0){//son like sunshine
        while(i<num){
            i++;
        }
    }
    else{//father
    
    int t_pid = wait_stat(0, performance);
    fprintf(1, "terminated pid: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n",
                t_pid, performance->ctime, performance->ttime, performance->stime, performance->retime, performance->rutime,
                 performance->average_bursttime);
    }
}


void test_bursttime(){
    int i=0;
    struct perf* performance = malloc(sizeof(struct perf));
    int cpid=fork();
    if(cpid==0){//Child runs for 2 seconds
        while(i<100000000){
            i++;
        }
        exit(0);
    }
    else{//father
        int t_pid = wait_stat(0, performance);
        fprintf(1, "terminated pid: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n",
                    t_pid, performance->ctime, performance->ttime, performance->stime, performance->retime, performance->rutime,
                     performance->average_bursttime);
        //average_bursttime should be 350 because:
        //A2=αB1+(100-α)A1/100 --> A2 = 50 * 2 + (100 - 50) * 500 / 100 = 350
        //If it runs for a different amount of ticks so replace the "2" with the correct rutime.
    }
}


void test_bursttime_SRT(){
    int i=0;
    int k = 0;
    int pid=fork();
    int status1, status2;
    struct perf* performance = malloc(sizeof(struct perf));
    struct perf* performance2 = malloc(sizeof(struct perf));
    if(pid==0){ //Child runs for 2 seconds
        int cpid = fork();
        if(cpid == 0){ // GrandChild - represents i/o activitie
            for(int j = 0 ; j < 3 ; j++){
                while(k < 100000000)
                    k++;
                sleep(1);
            }
            exit(0);
        }
        else{ // Child
            while(i < 100000000){
                i++;
            }
            int t_pid2 = wait_stat(&status2, performance2);
            fprintf(1, "terminated pid from Child: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n",
            t_pid2, performance2->ctime, performance2->ttime, performance2->stime, performance2->retime, performance2->rutime,
            performance2->average_bursttime);
        }
        exit(0);

    }
    else{ //father
        while(i < 100000000){
            i++;
        }
        int t_pid = wait_stat(&status1, performance);
        fprintf(1, "terminated pid from Father: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n",
        t_pid, performance->ctime, performance->ttime, performance->stime, performance->retime, performance->rutime,
        performance->average_bursttime);
    }
}


void test_for_bursttime_when_son_just_dies(){
    struct perf* performance = malloc(sizeof(struct perf));
    int cpid=fork();
    if(cpid==0){//son like sunshine
        exit(0);
    }
    else{//father
    int t_pid = wait_stat(0, performance);
    fprintf(1, "terminated pid: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n",
                t_pid, performance->ctime, performance->ttime, performance->stime, performance->retime, performance->rutime,
                 performance->average_bursttime);
    }
}

void testing_trace(){
    //mask=(1<< SYS_fork)|( 1<< SYS_kill)| ( 1<< SYS_sbrk) | ( 1<< SYS_write);
    int mask=(1<< 1);
    sleep(1); //doesn't print this sleep
    trace(mask, getpid());
    int cpid=fork();//prints fork once
    if (cpid==0){
        fork();// prints fork for the second time - the first son forks
        //mask= (1<< 13); //to turn on only the sleep bit
        mask= (1<< 1)|(1<< 13); //you can uncomment this inorder to check you print for both fork and sleep syscalls
        trace(mask, getpid()); //the first son and the grandchilde changes mask to print sleep
        sleep(1);
        fork();//should print nothing
        exit(0);//shold print nothing
    }
    else {
        sleep(10);// the father doesnt pring it - has original mask
    }
    mask= (1<< 12)|( 1<< 2) | (1<<6); //sbrk & exit & kill
    trace(mask, getpid());
    cpid= fork();
    kill(cpid);
    sbrk(4096);
}

void extra_complicated_long_test(){

    struct perf* performance = malloc(sizeof(struct perf));
    int mask=(1<< 1) | (1<< 23) | (1<< 3);
    trace(mask, getpid());
    int cpid = fork();
    if (cpid != 0){ //Parent
        int t_pid = wait_stat(0, performance);
        fprintf(1, "terminated pid: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n", t_pid, performance->ctime, performance->ttime, performance->stime, performance->retime, performance->rutime, performance->average_bursttime);
    }
    else{ //Child
        sleep(10);
        for(int i=1; i < 15; i++){
            int c_pid = fork();
            if(c_pid == 0){
                sleep(i);
                exit(0);
            }
            else{
                int i = 0;
                while(i<100000000){
                    i++;
                }
            }
        }
        sleep(10);
        for(int i=1; i < 15; i++){
            int c_pid = fork();
            if(c_pid == 0){
                int i = 0;
                while(i<10000000){
                    i++;
                }
                exit(0);
            }
            else{
                int t_pid = wait_stat(0, performance);
                fprintf(1, "terminated pid: %d, ctime: %d, ttime: %d, stime: %d, retime: %d, rutime: %d average_bursttime: %d \n", t_pid, performance->ctime, performance->ttime, performance->stime, performance->retime, performance->rutime, performance->average_bursttime);
                int i = 0;
                while(i<10000){
                    i++;
                }
            }
        }
    }
}

void test_three1(){
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


void test_for_FCFS(){
    // int mask = (1<< SYS_fork) | (1<< SYS_wait);
    int pid = fork();
    // int status;
    if(pid == 0){
        // Child
        int cpid = fork();
        if(cpid == 0){
            //Grandchild
            int sum = 0;
            for(int i = 0; i < 1000000 ; i++){
                sum++;
            }
                printf("GrandChild with pid %d is running\n" , getpid());
            exit(0);
        }
        else{
            //Child
            int sum = 0;
            for(int i = 0; i < 1000000 ; i++){
                sum++;
            }
                printf("Child with pid %d is running\n" , getpid());
        }
        exit(0);
    }
    else{
        //Father
        int sum = 0;
        for(int i = 0; i < 1000000 ; i++){
            sum++;
        }
            printf("Father with pid %d is running\n" , getpid());

    }
   
}

void test_for_sleep_task3(){
    int pid = fork();
    int status;
    struct perf performance;
    if(pid == 0){
        //Child
        sleep(20);
        exit(0);
    }
    else{
        //Father
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
    }
}

void test_FCFS_with_sleep(){
    // int mask = (1<< SYS_fork) | (1<< SYS_wait);
    int pid = fork();
    // int status;
    if(pid == 0){
        // Child
        int cpid = fork();
        if(cpid == 0){
            //Grandchild
            int sum = 0;
            for(int i = 0; i < 10000000 ; i++){
                sum++;
            }
            printf("GrandChild with pid %d is running\n" , getpid());
            exit(0);
        }
        else{
            //Child
            int sum = 0;
            for(int i = 0; i < 10000000 ; i++){
                sum++;
            }
            printf("Child with pid %d is running\n" , getpid());
        }
        exit(0);
    }
    else{
        //Father
        sleep(1); //Father moves to the end of the queue
        printf("Father with pid %d is running\n" , getpid());

    }
   
}


void test_default(){
    int pid = fork();
    int status;
    struct perf performance;
    if(pid == 0){
        // Child
        int sum = 0;
        for(int i = 0 ; i < 1000000000 ; i++){
            sum++;
        }
    }
    else{
        // Father
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
    }
}
