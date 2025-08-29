#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include "../sketchybar.h"

// Define the structure for media info
struct media_info {
    int status;       // 0 = playing, 1 = paused, 2 = stopped
    char title[256];  // Track title
    char artist[256]; // Artist name
    char artwork[8192]; // Artwork URL (base64 or raw)
};

// Initialize media info
static inline void media_init(struct media_info *media) {
    memset(media, 0, sizeof(*media));
    media->status = 2; // Default: stopped
}

// Process a line from media-control stream
void process_media_line(char* line, struct media_info* media) {
    char command[1024];
    snprintf(command, sizeof(command),
             "echo '%s' | jq -r 'if .diff == false then \"$(date +%%H:%%M:%%S) (\\.payload.bundleIdentifier) \\.payload.title - \\.payload.artist - \\.payload.artworkData\" else empty end'", line);

    FILE *jq = popen(command, "r");
    if (!jq) {
        fprintf(stderr, "Failed to execute jq command.\n");
        return;
    }

    char *output = NULL;
    size_t len = 0;
    if (getline(&output, &len, jq) != -1) {
        if (strcmp(output, "empty") != 0) {
            // Format the output for sketchybar
            char event_msg[2048];
            snprintf(event_msg, sizeof(event_msg),
                     "--trigger 'media' status='%d' title='%s' artist='%s' artwork='%s'",
                     media->status, media->title, media->artist, media->artwork);
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

    // Setup the event in sketchy
    char add_event_msg[512];
    snprintf(add_event_msg, sizeof(add_event_msg), "--add event '%s'", argv[1]);

    // Initialize media info
    struct media_info media;
    media_init(&media);

    // Run media-control stream
    FILE *fp = popen("media-control stream", "r");
    if (!fp) {
        fprintf(stderr, "Failed to execute media-control stream.\n");
        exit(1);
    }

    char line[1024];
    while (fgets(line, sizeof(line), fp)) {
        // Process the line
        process_media_line(line, &media);
    }

    pclose(fp);
    return 0;
}
