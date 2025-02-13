#ifndef GPU_H
#define GPU_H

struct gpu {
  float load;
  int power_mw;
  int freq_mhz;
  float total_utilization;
};

void gpu_init(struct gpu *gpu);
void gpu_update(struct gpu *gpu);

#endif
