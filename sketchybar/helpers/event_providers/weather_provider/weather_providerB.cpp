#include <chrono>
#include <curl/curl.h>
#include <iostream>
#include <nlohmann/json.hpp>
#include <thread>

#include "../sketchybar.h"

using json = nlohmann::json;

// Define API key and URL
#define API_KEY "API_KEY"
#define WEATHER_URL "http://api.weatherapi.com/v1/current.json?key=%s&q=%f,%f"

class WeatherProvider {
public:
  WeatherProvider(const std::string &event_name, int update_interval)
      : event_name(event_name), update_interval(update_interval) {}

  void run() {
    // Initialize curl
    curl = curl_easy_init();
    if (!curl) {
      throw std::runtime_error("Failed to initialize curl");
    }

    // Set up the event in sketchybar
    char event_message[256];
    snprintf(event_message, sizeof(event_message), "--add event '%s'",
             event_name.c_str());
    sketchybar(event_message);

    // Main loop
    while (true) {
      try {
        // Get location
        auto location = getLocation();

        // Fetch weather data
        auto weatherData = getWeather(location.first, location.second);

        // Send update event to sketchybar
        sendUpdate(weatherData);

        // Wait for the next update
        std::this_thread::sleep_for(std::chrono::seconds(update_interval));
      } catch (const std::exception &e) {
        std::cerr << "Error: " << e.what() << std::endl;
      }
    }
  }

private:
  std::pair<double, double> getLocation() {
    // Get the current location from the local server
    char location_url[] =
        "http://localhost:8000/current_location?accuracy=best";
    std::string location_response;
    curl_easy_setopt(curl, CURLOPT_URL, location_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &location_response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
      throw std::runtime_error("Failed to get location data: " +
                               std::string(curl_easy_strerror(res)));
    }

    // Parse the JSON response to get latitude and longitude
    json location_root = json::parse(location_response);
    double latitude = location_root["latitude"].get<double>();
    double longitude = location_root["longitude"].get<double>();

    return std::make_pair(latitude, longitude);
  }

  json getWeather(double latitude, double longitude) {
    // Prepare the weather API request URL
    char weather_url[256];
    snprintf(weather_url, sizeof(weather_url), WEATHER_URL, API_KEY, latitude,
             longitude);

    std::string weather_response;
    curl_easy_setopt(curl, CURLOPT_URL, weather_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &weather_response);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
      throw std::runtime_error("Failed to get weather data: " +
                               std::string(curl_easy_strerror(res)));
    }

    return json::parse(weather_response);
  }


  void sendUpdate(const json &weatherData) {
    // Extract data from JSON
    std::string city = weatherData["location"]["name"].get<std::string>();
    int condition = weatherData["current"]["condition"]["code"].get<int>();
    double temp = weatherData["current"]["temp_f"].get<double>();
    int is_day = weatherData["current"]["is_day"].get<int>();

    // Prepare the event message
    char trigger_message[256];
    snprintf(trigger_message, sizeof(trigger_message),
             "--trigger '%s' city='%s' condition='%d' temp='%.1f' is_day='%d'",
             event_name.c_str(), city.c_str(), condition, temp, is_day);

    // Trigger the event
    sketchybar(trigger_message);
  }


  std::string event_name;
  int update_interval;
  CURL *curl = nullptr;

  static size_t write_callback(char *ptr, size_t size, size_t nmemb,
                               void *userdata) {
    std::string &str = *static_cast<std::string *>(userdata);
    str.append(ptr, size * nmemb);
    return size * nmemb;
  }
};

int main(int argc, char **argv) {
  if (argc != 3) {
    std::cerr << "Usage: " << argv[0] << " <event_name> <update_interval>\n";
    return 1;
  }

  std::string event_name = argv[1];
  int update_interval = std::stoi(argv[2]);

  try {
    WeatherProvider provider(event_name, update_interval);
    provider.run();
  } catch (const std::exception &e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
