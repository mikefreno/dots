#include <chrono>
#include <curl/curl.h>
#include <iostream>
#include <nlohmann/json.hpp>
#include <thread>

#include "../sketchybar.h"

using json = nlohmann::json;

// Define API key and URL
#define WEATHER_API_KEY "ac52803fe74841f7b7a191127241005"
#define TOMORROW_API_KEY "t8kl6UBDjBSlHRNodEMGqpr8ATIJ4JjJ"
#define WEATHER_API_URL                                                        \
  "http://api.weatherapi.com/v1/current.json?key=%s&q=%f,%f"
#define TOMORROW_API_URL                                                       \
  "https://api.tomorrow.io/v4/weather/"                                        \
  "realtime?location=%f,%f&apikey=%s&units=imperial"

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
        // std::cout << weatherData << std::endl;

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
    const int RETRY_DELAY_SECONDS = 10;

    while (true) {
      FILE *pipe = popen("CoreLocationCli", "r");
      if (!pipe) {
        std::cerr << "Error: Failed to execute CoreLocationCli. Retrying in "
                  << RETRY_DELAY_SECONDS << " seconds..." << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(RETRY_DELAY_SECONDS));
        continue;
      }

      char buffer[128];
      std::string result = "";
      while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        result += buffer;
      }
      pclose(pipe);

      // Trim any whitespace from the result
      result.erase(0, result.find_first_not_of(" \n\r\t"));
      result.erase(result.find_last_not_of(" \n\r\t") + 1);

      // Check if the result contains an error message
      if (result.find("error") != std::string::npos) {
        std::cerr << "CoreLocationCli error: " << result << std::endl;
        std::cerr << "Retrying in " << RETRY_DELAY_SECONDS << " seconds..."
                  << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(RETRY_DELAY_SECONDS));
        continue;
      }

      // Parse the output to get latitude and longitude
      std::istringstream iss(result);
      double latitude, longitude;
      if (!(iss >> latitude >> longitude)) {
        std::cerr << "Error: Failed to parse latitude and longitude from: '"
                  << result << "'" << std::endl;
        std::cerr << "Retrying in " << RETRY_DELAY_SECONDS << " seconds..."
                  << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(RETRY_DELAY_SECONDS));
        continue;
      }

      return std::make_pair(latitude, longitude);
    }
  }

  json combineWeatherData(const json &tomorrowData,
                          const json &weatherApiData) {
    json combinedData;

    // Data from Tomorrow.io API
    combinedData["temperature"] = tomorrowData["data"]["values"]["temperature"];

    // Data from WeatherAPI.com
    combinedData["weatherCode"] =
        weatherApiData["current"]["condition"]["code"];
    combinedData["is_day"] = weatherApiData["current"]["is_day"];
    combinedData["city"] = weatherApiData["location"]["name"];

    return combinedData;
  }

  json getWeather(double latitude, double longitude) {
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
    // std::cout << tomorrow_parse << std::endl;

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
    // std::cout << weather_parse << std::endl;
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
