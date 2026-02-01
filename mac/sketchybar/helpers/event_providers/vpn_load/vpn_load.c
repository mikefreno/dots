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
    FILE *fp = popen("scutil --nwi", "r");
    if (fp == NULL) {
      fprintf(stderr, "Failed to execute scutil command\n");
      exit(1);
    }

    FILE *nc_fp = popen("scutil --nc list", "r");
    char nc_output[MAX_OUTPUT_LENGTH];
    int vpn_connected = 0;

    if (nc_fp != NULL) {
      char *line = NULL;
      size_t len = 0;
      ssize_t read;
      while ((read = getline(&line, &len, nc_fp)) != -1) {
        if ((strstr(line, "ProtonVPN") != NULL) && (strstr(line, "Tailscale") == NULL) && (strstr(line, "Connected") != NULL)) {
          vpn_connected = 1;
          break;
        }
      }
      free(line);
      pclose(nc_fp);
    }

    // Prepare the event message
    if (vpn_connected) {
      snprintf(trigger_message, 512, "--trigger '%s' vpn='Connected'", argv[1]);
    } else {
      snprintf(trigger_message, 512, "--trigger '%s' vpn='Disconnected'", argv[1]);
    }

    // Trigger the event
    sketchybar(trigger_message);

    pclose(fp);

    // Wait
    usleep(update_freq * 1000000);
  }
  return 0;
}

