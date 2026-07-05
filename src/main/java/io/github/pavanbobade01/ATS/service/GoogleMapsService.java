package io.github.pavanbobade01.ATS.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

@Service
public class GoogleMapsService {

    // Inject the API key from application.properties
    @Value("${google.maps.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    // Base URL for the Google Maps Directions API
    private static final String DIRECTIONS_API_URL = "https://maps.googleapis.com/maps/api/directions/json";

    /**
     * Calls Google Directions API to get a route optimized for current traffic.
     * * @param originLat The ambulance's current latitude.
     * @param originLng The ambulance's current longitude.
     * @param destLat The destination latitude (e.g., hospital).
     * @param destLng The destination longitude.
     * @return The JSON response from Google, which includes the encoded polyline.
     */
    public String getOptimizedRoute(double originLat, double originLng, double destLat, double destLng) {

        String origin = originLat + "," + originLng;
        String destination = destLat + "," + destLng;

        // Use UriComponentsBuilder to safely construct the API URL with parameters
        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(DIRECTIONS_API_URL)
                .queryParam("origin", origin)
                .queryParam("destination", destination)
                // ⚠️ IMPORTANT: Requesting the route optimized for traffic
                .queryParam("traffic_model", "best_guess")
                // Request Polylines for easy drawing in Flutter
                .queryParam("alternatives", "false") // We only want the best route
                .queryParam("mode", "driving")
                .queryParam("key", apiKey);

        // Make the external HTTP GET request
        try {
            // The API response is returned as a String (JSON)
            return restTemplate.getForObject(builder.toUriString(), String.class);
        } catch (Exception e) {
            // Log the error and return an empty or error response
            System.err.println("Error calling Google Maps Directions API: " + e.getMessage());
            // Return an empty JSON object if the call fails
            return "{\"routes\": []}";
        }
    }
}