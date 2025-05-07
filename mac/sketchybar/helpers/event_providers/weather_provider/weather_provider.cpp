#include <chrono>
#include <curl/curl.h>
#include <iostream>
#include <nlohmann/json.hpp>
#include <thread>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include "../sketchybar.h"

using json = nlohmann::json;

#define WEATHER_API_URL                                                        \
  "http://api.weatherapi.com/v1/current.json?key=%s&q=%f,%f"
#define TOMORROW_API_URL                                                       \
  "https://api.tomorrow.io/v4/weather/"                                        \
  "realtime?location=%f,%f&apikey=%s&units=imperial"

class WeatherProvider {
public:
  WeatherProvider(const std::string &event_name, int update_interval)
      : event_name(event_name), update_interval(update_interval),
        cached_location(std::make_pair(0.0, 0.0)), has_cached_location(false) {
    load_env_variables();
  }

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
  std::string weather_api_key;
  std::string tomorrow_api_key;

  std::string find_env_file() {
    std::vector<std::string> possible_paths = {
        ".env",
        "../.env",
        "../../.env",  // If binary is in build/debug or similar
        std::string(getenv("HOME")) + "/.config/sketchybar/helpers/event_providers/weather_provider/.env"
    };
    
    std::cerr << "Searching for .env file in:" << std::endl;
    for (const auto& path : possible_paths) {
        std::cerr << "Checking " << path << "... ";
        if (std::filesystem::exists(path)) {
            std::cerr << "FOUND!" << std::endl;
            return path;
        }
        std::cerr << "not found" << std::endl;
    }
    
    throw std::runtime_error("Could not find .env file");
}

void load_env_variables() {
    try {
        std::cerr << "Attempting to load environment variables..." << std::endl;
        std::string env_path = find_env_file();
        std::cerr << "Loading from: " << env_path << std::endl;
        
        std::ifstream env_file(env_path);
        if (!env_file.is_open()) {
            throw std::runtime_error("Could not open .env file: " + env_path);
        }

        std::string line;
        while (std::getline(env_file, line)) {
            if (line.empty() || line[0] == '#') continue;

            size_t pos = line.find('=');
            if (pos == std::string::npos) continue;

            std::string key = line.substr(0, pos);
            std::string value = line.substr(pos + 1);

            if (value.front() == '"' && value.back() == '"') {
                value = value.substr(1, value.length() - 2);
            }

            if (key == "WEATHER_API_KEY") {
                weather_api_key = value;
                std::cerr << "Loaded WEATHER_API_KEY" << std::endl;
            } else if (key == "TOMORROW_API_KEY") {
                tomorrow_api_key = value;
                std::cerr << "Loaded TOMORROW_API_KEY" << std::endl;
            }
        }

        if (weather_api_key.empty() || tomorrow_api_key.empty()) {
            throw std::runtime_error("Missing required API keys in .env file");
        }

        std::cerr << "Successfully loaded both API keys" << std::endl;

    } catch (const std::exception& e) {
        throw std::runtime_error(std::string("Error loading .env file: ") + e.what());
    }
}

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
             longitude, tomorrow_api_key.c_str());

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
    snprintf(weather_url, sizeof(weather_url), WEATHER_API_URL, 
             weather_api_key.c_str(), latitude, longitude);

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

