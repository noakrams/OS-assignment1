#define T_DIR     1   // Directory
#define T_FILE    2   // File
#define T_DEVICE  3   // Device

struct perf {
  int ctime;
  int ttime;
  int stime;
  int retime;
  int rutime;
  int average_bursttime;
};
