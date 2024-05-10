#include "../sketchybar.h"
#include <curl/curl.h>
#include <json-c/json.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define API_KEY "api_key"
#define WEATHER_URL "http://api.weatherapi.com/v1/current.json?key=%s&q=%s"

size_t write_callback(char *ptr, size_t size, size_t nmemb, void *userdata) {
  strncat((char *)userdata, ptr, size * nmemb);
  return size * nmemb;
}

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s <event_name> <update_interval>\n", argv[0]);
    exit(1);
  }

  char *event_name = argv[1];
  int update_interval = atoi(argv[2]);

  // Setup the event in sketchybar
  char event_message[256];
  snprintf(event_message, sizeof(event_message), "--add event '%s'",
           event_name);
  sketchybar(event_message);

  CURL *curl = curl_easy_init();
  if (!curl) {
    fprintf(stderr, "Failed to initialize curl\n");
    exit(1);
  }

  char weather_url[256];
  snprintf(weather_url, sizeof(weather_url), WEATHER_URL, API_KEY, "Brooklyn");

  while (1) {
    char response[4096] = {0};
    curl_easy_setopt(curl, CURLOPT_URL, weather_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
      fprintf(stderr, "Failed to get weather data: %s\n",
              curl_easy_strerror(res));
      exit(1);
    }

    json_object *root = json_tokener_parse(response);
    json_object *current = json_object_object_get(root, "current");

    json_object *condition_obj = json_object_object_get(current, "condition");
    json_object *condition_code = json_object_object_get(condition_obj, "code");
    const char *condition = json_object_get_string(condition_code);

    json_object *temp_obj = json_object_object_get(current, "temp_f");
    double temp = json_object_get_double(temp_obj);

    json_object *is_day_obj = json_object_object_get(current, "is_day");
    int is_day = json_object_get_int(is_day_obj);

    // Prepare the event message
    char trigger_message[256];
    snprintf(trigger_message, sizeof(trigger_message),
             "--trigger '%s' condition='%s' temp='%.1f' is_day='%d'",
             event_name, condition, temp, is_day);

    // Trigger the event
    sketchybar(trigger_message);

    json_object_put(root);

    sleep(update_interval);
  }

  curl_easy_cleanup(curl);

  return 0;
}
