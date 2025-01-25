#include <chrono>
#include <curl/curl.h>
#include <iostream>
#include <nlohmann/json.hpp>
#include <thread>

#include "../sketchybar.h"

using json = nlohmann::json;

// Define API key and URL
#define WEATHER_API_KEY "9d2001153285473c8fb23012252501"
#define TOMORROW_API_KEY "Qu1t84lMBLguwMY7yaqh202ho6OGdvn5"
#define WEATHER_API_URL                                                        \
  "http://api.weatherapi.com/v1/current.json?key=%s&q=%f,%f"
#define TOMORROW_API_URL                                                       \
  "https://api.tomorrow.io/v4/weather/"                                        \
  "realtime?location=%f,%f&apikey=%s&units=imperial"

class WeatherProvider {
public:
  WeatherProvider(const std::string &event_name, int update_interval)
      : event_name(event_name), update_interval(update_interval),
        cached_location(std::make_pair(0.0, 0.0)), has_cached_location(false) {}

  void run() {
    // Initialize global curl once
    curl_global_init(CURL_GLOBAL_ALL);

    // Set up the event in sketchybar
    char event_message[256];
    snprintf(event_message, sizeof(event_message), "--add event '%s'",
             event_name.c_str());
    sketchybar(event_message);

    try {
      // Main loop
      while (true) {
        // Create a new CURL handle for each request
        CURL *curl = curl_easy_init();
        if (!curl) {
          throw std::runtime_error("Failed to initialize curl");
        }

        try {
          // Get location
          auto location = getLocation();

          // Fetch weather data
          auto weatherData = getWeather(curl, location.first, location.second);

          // Send update event to sketchybar
          sendUpdate(weatherData);

          // Cleanup this iteration's handle
          curl_easy_cleanup(curl);

          // Wait for the next update
          std::this_thread::sleep_for(std::chrono::seconds(update_interval));
        } catch (const std::exception &e) {
          curl_easy_cleanup(curl);
          std::cerr << "Error in loop: " << e.what() << std::endl;
          std::this_thread::sleep_for(
              std::chrono::seconds(10)); // Error backoff
        }
      }
    } catch (const std::exception &e) {
      std::cerr << "Fatal error: " << e.what() << std::endl;
      curl_global_cleanup();
      throw;
    }
  }

private:
  std::string event_name;
  int update_interval;
  std::pair<double, double> cached_location;
  bool has_cached_location;

  std::pair<double, double> getLocation() {
    // If we already have a cached location, return it
    if (has_cached_location) {
      return cached_location;
    }

    const int RETRY_DELAY_SECONDS = 10;
    CURL *curl;
    CURLcode res;
    std::string readBuffer;

    while (true) {
      curl = curl_easy_init();
      if (!curl) {
        std::cerr << "Error: Failed to initialize CURL. Retrying in "
                  << RETRY_DELAY_SECONDS << " seconds..." << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(RETRY_DELAY_SECONDS));
        continue;
      }

      readBuffer.clear();
      curl_easy_setopt(curl, CURLOPT_URL,
                       "http://localhost:8000/current_location");
      curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
      curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);

      res = curl_easy_perform(curl);
      curl_easy_cleanup(curl);

      if (res != CURLE_OK) {
        std::cerr << "CURL error: " << curl_easy_strerror(res) << std::endl;
        std::cerr << "Retrying in " << RETRY_DELAY_SECONDS << " seconds..."
                  << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(RETRY_DELAY_SECONDS));
        continue;
      }

      try {
        // Parse JSON response
        auto j = json::parse(readBuffer);

        // Check for error in response
        if (!j["error"].is_null()) {
          std::cerr << "API error: " << j["error"] << std::endl;
          std::cerr << "Retrying in " << RETRY_DELAY_SECONDS << " seconds..."
                    << std::endl;
          std::this_thread::sleep_for(
              std::chrono::seconds(RETRY_DELAY_SECONDS));
          continue;
        }

        double latitude = j["latitude"].get<double>();
        double longitude = j["longitude"].get<double>();

        // Cache the location before returning
        cached_location = std::make_pair(latitude, longitude);
        has_cached_location = true;

        return cached_location;

      } catch (const json::exception &e) {
        std::cerr << "JSON parsing error: " << e.what() << std::endl;
        std::cerr << "Response was: " << readBuffer << std::endl;
        std::cerr << "Retrying in " << RETRY_DELAY_SECONDS << " seconds..."
                  << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(RETRY_DELAY_SECONDS));
        continue;
      }
    }
  }

  json combineWeatherData(const json &tomorrowData,
                          const json &weatherApiData) {
    json combinedData;

    try {
      // Data from Tomorrow.io API
      if (tomorrowData.contains("data") &&
          tomorrowData["data"].contains("values") &&
          tomorrowData["data"]["values"].contains("temperature")) {
        combinedData["temperature"] =
            tomorrowData["data"]["values"]["temperature"];
      } else {
        throw std::runtime_error(
            "Missing temperature data from Tomorrow.io API");
      }

      // Data from WeatherAPI.com
      if (weatherApiData.contains("current") &&
          weatherApiData["current"].contains("condition") &&
          weatherApiData["current"]["condition"].contains("code")) {
        combinedData["weatherCode"] =
            weatherApiData["current"]["condition"]["code"];
      } else {
        throw std::runtime_error("Missing weather code from WeatherAPI");
      }

      if (weatherApiData.contains("current") &&
          weatherApiData["current"].contains("is_day")) {
        combinedData["is_day"] = weatherApiData["current"]["is_day"];
      } else {
        throw std::runtime_error("Missing is_day data from WeatherAPI");
      }

      if (weatherApiData.contains("location") &&
          weatherApiData["location"].contains("name")) {
        combinedData["city"] = weatherApiData["location"]["name"];
      } else {
        throw std::runtime_error("Missing city name from WeatherAPI");
      }

      return combinedData;
    } catch (const json::exception &e) {
      throw std::runtime_error(
          std::string("JSON parsing error in combineWeatherData: ") + e.what());
    }
  }

  json getWeather(CURL *curl, double latitude, double longitude) {
    // Prepare the weather API request URL
    char tomorrow_url[256];
    snprintf(tomorrow_url, sizeof(tomorrow_url), TOMORROW_API_URL, latitude,
             longitude, TOMORROW_API_KEY);

    std::string tomorrow_response;
    curl_easy_setopt(curl, CURLOPT_URL, tomorrow_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &tomorrow_response);

    CURLcode tomorrow_res = curl_easy_perform(curl);
    if (tomorrow_res != CURLE_OK) {
      throw std::runtime_error("Failed to get tomorrow data: " +
                               std::string(curl_easy_strerror(tomorrow_res)));
    }

    auto tomorrow_parse = json::parse(tomorrow_response);

    char weather_url[256];
    snprintf(weather_url, sizeof(weather_url), WEATHER_API_URL, WEATHER_API_KEY,
             latitude, longitude);

    std::string weather_response;
    curl_easy_setopt(curl, CURLOPT_URL, weather_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &weather_response);

    CURLcode weather_res = curl_easy_perform(curl);
    if (weather_res != CURLE_OK) {
      throw std::runtime_error("Failed to get weather data: " +
                               std::string(curl_easy_strerror(weather_res)));
    }

    auto weather_parse = json::parse(weather_response);
    return combineWeatherData(tomorrow_parse, weather_parse);
  }

  void sendUpdate(const json &weatherData) {
    // Extract data from JSON
    std::string city = weatherData["city"].get<std::string>();
    int condition = weatherData["weatherCode"].get<int>();
    double temp = weatherData["temperature"].get<double>();
    int is_day = weatherData["is_day"].get<int>();

    // Prepare the event message
    char trigger_message[256];
    snprintf(trigger_message, sizeof(trigger_message),
             "--trigger '%s' city='%s' condition='%d' temp='%.1f' is_day='%d'",
             event_name.c_str(), city.c_str(), condition, temp, is_day);

    // Trigger the event
    sketchybar(trigger_message);
  }

  static size_t write_callback(char *ptr, size_t size, size_t nmemb,
                               void *userdata) {
    if (!userdata)
      return 0;
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
    std::cerr << "Fatal error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
