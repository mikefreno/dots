#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

struct brew_info {
    int outdated_count;
    int last_check_status;
};

static inline void brew_init(struct brew_info* brew) {
    brew->outdated_count = -1;  // -1 indicates not yet checked
    brew->last_check_status = 0;
}

static inline void brew_update(struct brew_info* brew) {
    FILE *fp;
    char buffer[128];
    int count = 0;
    
    // Execute brew outdated --quiet and count lines
    fp = popen("brew outdated --quiet 2>/dev/null", "r");
    if (fp == NULL) {
        brew->last_check_status = -1;
        return;
    }
    
    // Count lines in output
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        count++;
    }
    
    int status = pclose(fp);
    brew->last_check_status = WEXITSTATUS(status);
    brew->outdated_count = count;
}

