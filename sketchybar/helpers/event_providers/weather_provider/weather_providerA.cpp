#include <iostream>
#include <string>
#include <curl/curl.h>
#include <nlohmann/json.hpp> 
#include "../sketchybar.h"

using namespace std;
using json = nlohmann::json;

// Define API Key and URL
const std::string API_KEY = "API_KEY"; // Replace with your API key
const std::string WEATHER_URL = "http://api.weatherapi.com/v1/current.json?key=%s&q=%f,%f";

// Function to handle curl response
size_t write_callback(char *ptr, size_t size, size_t nmemb, void *userdata) {
  std::string& str = *static_cast<std::string*>(userdata);
  str.append(ptr, size * nmemb);
  return size * nmemb;
}

// Class to hold weather data
class WeatherData {
public:
  std::string city;
  std::string condition;
  double temp;
  int is_day;

  WeatherData(std::string city, std::string condition, double temp, int is_day) : 
      city(city), condition(condition), temp(temp), is_day(is_day) {}
};

int main(int argc, char** argv) {
  if (argc != 3) {
    std::cerr << "Usage: " << argv[0] << " <event_name> <update_interval>\n";
    return 1;
  }

  std::string event_name = argv[1];
  int update_interval = std::stoi(argv[2]);

  // Register event with sketchybar
  std::string event_message = "--add event '" + event_name + "'";
  sketchybar(event_message.c_str());

  // Initialize curl
  curl_global_init(CURL_GLOBAL_ALL);
  CURL* curl = curl_easy_init();
  if (!curl) {
    std::cerr << "Failed to initialize curl\n";
    return 1;
  }

  while (true) {
    // Get location data from local server
    std::string location_url = "http://localhost:8000/current_location?accuracy=best";
    std::string location_response;
    curl_easy_setopt(curl, CURLOPT_URL, location_url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &location_response);
    CURLcode res = curl_easy_perform(curl);

    if (res != CURLE_OK) {
      std::cerr << "Failed to get location data: " << curl_easy_strerror(res) << std::endl;
      return 1;
    }

    // Parse location JSON
    json location_json = json::parse(location_response);
    double latitude = location_json["latitude"];
    double longitude = location_json["longitude"];

    // Construct weather API URL
    std::string weather_url =  fmt::format(WEATHER_URL, API_KEY, latitude, longitude);
    std::string weather_response;

    // Fetch weather data
    curl_easy_setopt(curl, CURLOPT_URL, weather_url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &weather_response);
    res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
      std::cerr << "Failed to get weather data: " << curl_easy_strerror(res) << std::endl;
      return 1;
    }

    // Parse weather JSON
    json weather_json = json::parse(weather_response);
    json location_json = weather_json["location"];
    json current_json = weather_json["current"];

    // Extract weather data
    std::string city = location_json["name"];
    std::string condition = current_json["condition"]["text"];
    double temp = current_json["temp_f"];
    int is_day = current_json["is_day"];

    // Create WeatherData object
    WeatherData weather_data(city, condition, temp, is_day);

    // Construct trigger message
    std::string trigger_message = "--trigger '" + event_name + "' city='" + weather_data.city + "' condition='" + weather_data.condition + "' temp='" + std::to_string(weather_data.temp) + "' is_day='" + std::to_string(weather_data.is_day) + "'";

    // Send trigger message to sketchybar
    sketchybar(trigger_message.c_str());

    // Sleep for update interval
    std::this_thread::sleep_for(std::chrono::seconds(update_interval));
  }

  curl_easy_cleanup(curl);
  curl_global_cleanup();
  return 0;
}
