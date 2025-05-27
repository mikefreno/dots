#include "brew_check.h"
#include "../sketchybar.h"

int main(int argc, char** argv) {
    float update_freq;
    if (argc < 3 || (sscanf(argv[2], "%f", &update_freq) != 1)) {
        printf("Usage: %s \"<event-name>\" \"<update_freq>\"\n", argv[0]);
        exit(1);
    }

    alarm(0);
    struct brew_info brew;
    brew_init(&brew);

    // Setup the event in sketchybar
    char event_message[512];
    snprintf(event_message, 512, "--add event '%s'", argv[1]);
    sketchybar(event_message);

    char trigger_message[512];
    for (;;) {
        // Update brew info
        brew_update(&brew);

        // Prepare the event message
        snprintf(trigger_message,
                 512,
                 "--trigger '%s' outdated_count='%d' status='%d'",
                 argv[1],
                 brew.outdated_count,
                 brew.last_check_status);

        // Trigger the event
        sketchybar(trigger_message);

        // Wait
        usleep(update_freq * 1000000);
    }
    return 0;
}

