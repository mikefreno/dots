#include "gpu.h"
#include "../sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void gpu_init(struct gpu* gpu) {
  // No initialization needed for this implementation
  memset(gpu, 0, sizeof(struct gpu));
}

void gpu_update(struct gpu* gpu) {
  FILE *fp = popen("sudo powermetrics --samplers gpu_power -n1", "r");
  if (!fp) {
    perror("Failed to run powermetrics");
    return;
  }

  char buffer[512];
  while (fgets(buffer, sizeof(buffer), fp)) {
    // Parse GPU load from idle residency
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
    
    // Parse current GPU frequency
    if (strstr(buffer, "GPU HW active frequency")) {
      sscanf(buffer, "GPU HW active frequency: %d MHz", &gpu->freq_mhz);
    }
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

  // Setup sketchybar event
  char event_message[512];
  snprintf(event_message, sizeof(event_message), "--add event '%s'", argv[1]);
  sketchybar(event_message);

  char trigger_message[512];
  for (;;) {
    gpu_update(&gpu);

    // Ensure valid values
    if (gpu.load < 0) gpu.load = 0;
    if (gpu.power_mw < 0) gpu.power_mw = 0;
    if (gpu.freq_mhz < 0) gpu.freq_mhz = 0;

    snprintf(trigger_message, sizeof(trigger_message),
            "--trigger '%s' "
            "gpu_load='%.0f' "
            "gpu_power='%d' "
            "gpu_freq='%d'",
            argv[1],
            gpu.load,
            gpu.power_mw,
            gpu.freq_mhz);

    sketchybar(trigger_message);
    usleep(update_freq * 1000000);
  }

  return 0;
}

