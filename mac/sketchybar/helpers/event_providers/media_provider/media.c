#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include "../sketchybar.h"

// Process a line from media-control stream
void process_media_line(char* line) {
    char command[4096];
    snprintf(command, sizeof(command),
             "echo '%%s' | jq -r '\n"
             "if .type == \"data\" and .diff == true then\n"
             "  \"state=\\(.payload.playing | if . == true then \\\"playing\\\" else \\\"paused\\\" end) \" +\n"
             "  \\\"title=\\(.payload.title // \\\"?\\\") \" +\n"
             "  \\\"artist=\\(.payload.artist // \\\"?\\\") \" +\n"
             "  \\\"artworkData=\\(.payload.artworkData // \\\"\\\") \" +\n"
             "  \\\"elapsedTimeMicros=\\(.payload.elapsedTimeMicros // 0) \" +\n"
             "  \\\"durationMicros=\\(.payload.durationMicros // 1)\"\n"
             "else\n"
             "  empty\n"
             "end'");

    FILE *jq = popen(command, "r");
    if (!jq) {
        fprintf(stderr, "Failed to execute jq command.\n");
        return;
    }

    char *output = NULL;
    size_t len = 0;
    if (getline(&output, &len, jq) != -1) {
        // Remove trailing newline
        size_t output_len = strlen(output);
        if (output_len > 0 && output[output_len-1] == '\n') {
            output[output_len-1] = '\0';
        }

        // Only trigger if we got actual data
        if (strlen(output) > 0) {
            // Build the sketchybar trigger message
            char event_msg[8192];
            snprintf(event_msg, sizeof(event_msg),
                     "--trigger 'media_change' %s", output);
            sketchybar(event_msg);
        }
    }

    free(output);
    pclose(jq);
}

// Main function to run the media control stream
int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s \"<event-name>\"\n", argv[0]);
        exit(1);
    }

    // Setup the event in sketchybar
    char add_event_msg[512];
    snprintf(add_event_msg, sizeof(add_event_msg), "--add event '%s'", argv[1]);
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