#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

struct brew_info {
  int outdated_count;
  int last_check_status;
};

static inline void brew_init(struct brew_info *brew) {
  brew->outdated_count = -1; // -1 indicates not yet checked
  brew->last_check_status = 0;
}

static inline void brew_update(struct brew_info *brew) {
  FILE *fp;
  char buffer[128];

  fp = popen("brew outdated -q>/dev/null | wc -l | tr -d ' \n'", "r");
  if (fp == NULL) {
    brew->last_check_status = -1;
    return;
  }

  // Read the count directly
  if (fgets(buffer, sizeof(buffer), fp) != NULL) {
    brew->outdated_count = atoi(buffer);
  } else {
    brew->outdated_count = 0;
  }

  int status = pclose(fp);
  brew->last_check_status = WEXITSTATUS(status);
}
