#include "../sketchybar.h"
#include <curl/curl.h>
#include <json-c/json.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define API_KEY "API_KEY"
#define WEATHER_URL "http://api.weatherapi.com/v1/current.json?key=%s&q=%f,%f"

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

  while (1) {
    // Get the current location from the local server
    char location_url[] =
        "http://localhost:8000/current_location?accuracy=best";
    char location_response[4096] = {0};
    curl_easy_setopt(curl, CURLOPT_URL, location_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, location_response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
      fprintf(stderr, "Failed to get location data: %s\n",
              curl_easy_strerror(res));
      exit(1);
    }

    // Parse the JSON response to get latitude and longitude
    json_object *location_root = json_tokener_parse(location_response);
    json_object *latitude_obj =
        json_object_object_get(location_root, "latitude");
    double latitude = json_object_get_double(latitude_obj);
    json_object *longitude_obj =
        json_object_object_get(location_root, "longitude");
    double longitude = json_object_get_double(longitude_obj);
    json_object_put(location_root);

    // Prepare the weather API request URL with latitude and longitude
    char weather_url[256];
    snprintf(weather_url, sizeof(weather_url), WEATHER_URL, API_KEY, latitude,
             longitude);

    char weather_response[4096] = {0};
    curl_easy_setopt(curl, CURLOPT_URL, weather_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, weather_response);

    res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
      fprintf(stderr, "Failed to get weather data: %s\n",
              curl_easy_strerror(res));
      exit(1);
    }

    json_object *weather_root = json_tokener_parse(weather_response);
    json_object *current = json_object_object_get(weather_root, "current");
    json_object *location = json_object_object_get(weather_root, "location");

    json_object *city_obj = json_object_object_get(location, "name");
    const char *city = json_object_get_string(city_obj);

    json_object *condition_obj = json_object_object_get(current, "condition");
    json_object *condition_code = json_object_object_get(condition_obj, "code");
    const char *condition = json_object_get_string(condition_code);

    json_object *temp_obj = json_object_object_get(current, "temp_f");
    double temp = json_object_get_double(temp_obj);

    json_object *is_day_obj = json_object_object_get(current, "is_day");
    int is_day = json_object_get_int(is_day_obj);

    // Prepare the event message with city included
    char trigger_message[256];
    snprintf(trigger_message, sizeof(trigger_message),
             "--trigger '%s' city='%s' condition='%s' temp='%.1f' is_day='%d'",
             event_name, city, condition, temp, is_day);

    // Trigger the event
    sketchybar(trigger_message);

    json_object_put(weather_root);

    usleep(update_interval * 1000000);
  }

  curl_easy_cleanup(curl);

  return 0;
}
