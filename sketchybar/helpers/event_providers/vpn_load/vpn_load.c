#include "../sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_OUTPUT_LENGTH 256

int main(int argc, char **argv) {
  float update_freq;
  if (argc != 3 || (sscanf(argv[2], "%f", &update_freq) != 1)) {
    printf("Usage: %s \"<event-name>\" \"<event_freq>\"\n", argv[0]);
    exit(1);
  }

  alarm(0);
  // Setup the event in sketchybar
  char event_message[512];
  snprintf(event_message, 512, "--add event '%s'", argv[1]);
  sketchybar(event_message);

  char trigger_message[512];
  for (;;) {
    // Execute the scutil command and capture the output
    FILE *fp = popen(
        "scutil --nc list | grep Connected | sed -E 's/.*\"(.*)\".*/\\1/'",
        "r");
    if (fp == NULL) {
      fprintf(stderr, "Failed to execute scutil command\n");
      exit(1);
    }

    char output[MAX_OUTPUT_LENGTH];
    if (fgets(output, sizeof(output), fp) != NULL) {
      // Remove trailing newline character
      output[strcspn(output, "\n")] = '\0';
    } else {
      // No connected VPN found, set output to empty string
      output[0] = '\0';
    }

    // Prepare the event message
    snprintf(trigger_message, 512, "--trigger '%s' vpn='%s'", argv[1], output);

    // Trigger the event
    sketchybar(trigger_message);

    pclose(fp);

    // Wait
    usleep(update_freq * 1000000);
  }
  return 0;
}
