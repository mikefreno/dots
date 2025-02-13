#include "gpu.h"
#include "../sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_FREQ_ENTRIES 20

struct freq_entry {
    int freq_mhz;
    float percentage;
};

void gpu_init(struct gpu* gpu) {
    memset(gpu, 0, sizeof(struct gpu));
}

float calculate_total_utilization(struct freq_entry* entries, int count, int max_freq) {
    float total = 0.0f;
    for (int i = 0; i < count; i++) {
        if (entries[i].freq_mhz > 0 && entries[i].percentage > 0) {
            float freq_ratio = (float)entries[i].freq_mhz / max_freq;
            float time_ratio = entries[i].percentage / 100.0f;
            float contribution = freq_ratio * time_ratio;
            total += contribution;
            
            // Debug output
            printf("Freq: %d MHz (%.2f%% of max) at %.2f%% time = %.2f%% contribution\n",
                   entries[i].freq_mhz,
                   freq_ratio * 100,
                   entries[i].percentage,
                   contribution * 100);
        }
    }
    return total * 100.0f;
}

void gpu_update(struct gpu* gpu) {
    FILE *fp = popen("sudo powermetrics --samplers gpu_power -n1", "r");
    if (!fp) {
        perror("Failed to run powermetrics");
        return;
    }

    char buffer[1024];
    struct freq_entry entries[MAX_FREQ_ENTRIES];
    int entry_count = 0;
    int max_freq = 1380; // Setting fixed max frequency for M-series chips

    while (fgets(buffer, sizeof(buffer), fp)) {
        // Parse GPU HW active residency line
        if (strstr(buffer, "GPU HW active residency:")) {
            printf("Parsing line: %s", buffer);  // Debug output
            
            char* freq_start = strstr(buffer, "(");
            if (freq_start) {
                char* freq_end = strstr(buffer, ")");
                if (freq_end) {
                    *freq_end = '\0';
                    char* saveptr;
                    char* token = strtok_r(freq_start + 1, " MHz:", &saveptr);
                    
                    while (token && entry_count < MAX_FREQ_ENTRIES) {
                        // Parse frequency
                        entries[entry_count].freq_mhz = atoi(token);
                        
                        // Get percentage
                        token = strtok_r(NULL, "% ", &saveptr);
                        if (token) {
                            entries[entry_count].percentage = atof(token);
                            printf("Found: %d MHz at %.2f%%\n", 
                                   entries[entry_count].freq_mhz, 
                                   entries[entry_count].percentage);  // Debug output
                            entry_count++;
                        }
                        
                        // Get next frequency
                        token = strtok_r(NULL, " MHz:", &saveptr);
                    }
                }
            }
        }
        
        // Parse GPU idle residency
        if (strstr(buffer, "GPU idle residency")) {
            float idle;
            if (sscanf(buffer, "GPU idle residency: %f%%", &idle) == 1) {
                gpu->load = 100.0f - idle;
            }
        }
        
        // Parse GPU power draw
        if (strstr(buffer, "GPU Power")) {
            sscanf(buffer, "GPU Power: %d mW", &gpu->power_mw);
        }
    }
    
    // Calculate total GPU resource utilization
    if (entry_count > 0) {
        printf("\nCalculating utilization with %d frequency entries...\n", entry_count);
        gpu->total_utilization = calculate_total_utilization(entries, entry_count, max_freq);
        printf("Final total utilization: %.2f%%\n\n", gpu->total_utilization);
    } else {
        gpu->total_utilization = 0.0f;
    }

    pclose(fp);
}

int main(int argc, char** argv) {
    float update_freq;
    if (argc < 3 || (sscanf(argv[2], "%f", &update_freq) != 1)) {
        printf("Usage: %s \"<event-name>\" \"<update_freq>\"\n", argv[0]);
        exit(1);
    }

    struct gpu gpu;
    gpu_init(&gpu);

    char event_message[512];
    snprintf(event_message, sizeof(event_message), "--add event '%s'", argv[1]);
    sketchybar(event_message);

    char trigger_message[512];
    for (;;) {
        gpu_update(&gpu);

        // Ensure valid values
        if (gpu.load < 0) gpu.load = 0;
        if (gpu.power_mw < 0) gpu.power_mw = 0;
        if (gpu.total_utilization < 0) gpu.total_utilization = 0;

        snprintf(trigger_message, sizeof(trigger_message),
                "--trigger '%s' "
                "gpu_load='%.0f' "
                "gpu_power='%d' "
                "gpu_total_util='%.0f'",
                argv[1],
                gpu.load,
                gpu.power_mw,
                gpu.total_utilization);

        sketchybar(trigger_message);
        usleep(update_freq * 1000000);
    }

    return 0;
}

