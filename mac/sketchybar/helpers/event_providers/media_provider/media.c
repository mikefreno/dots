#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "../sketchybar.h"

static char g_event_name[256];

// Process a line from media-control stream
void process_media_line(const char* line) {
    if (!line) return;
    if (strstr(line, "\"type\":\"data\"") == NULL) return;
    if (strstr(line, "\"diff\":true") == NULL) return;

    char event_msg[512];
    snprintf(event_msg, sizeof(event_msg), "--trigger '%s'", g_event_name);
    sketchybar(event_msg);
}

// Main function to run the media control stream
int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s \"<event-name>\"\n", argv[0]);
        exit(1);
    }

    // Setup the event in sketchybar
    snprintf(g_event_name, sizeof(g_event_name), "%s", argv[1]);

    char add_event_msg[512];
    snprintf(add_event_msg, sizeof(add_event_msg), "--add event '%s'", g_event_name);
    system(add_event_msg);

    // Run media-control stream
    FILE *fp = popen("media-control stream --micros", "r");
    if (!fp) {
        fprintf(stderr, "Failed to execute media-control stream.\n");
        exit(1);
    }

    char line[8192];
    while (fgets(line, sizeof(line), fp)) {
        process_media_line(line);
    }

    pclose(fp);
    return 0;
}
