package io.github.pavanbobade01.ATS.controller;

import io.github.pavanbobade01.ATS.dto.RouteRequest;
import io.github.pavanbobade01.ATS.model.Ambulance;
import io.github.pavanbobade01.ATS.model.AmbulanceStatus;
import io.github.pavanbobade01.ATS.model.User;
import io.github.pavanbobade01.ATS.repository.AmbulanceRepository;
import io.github.pavanbobade01.ATS.repository.UserRepository;
import io.github.pavanbobade01.ATS.service.AmbulanceService;
import io.github.pavanbobade01.ATS.service.GoogleMapsService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * AmbulanceController
 *
 * - Keeps your route suggestion endpoint
 * - Adds API for police / clients to GET active ambulances and single ambulance details
 */
@RestController
@RequestMapping("/api/ambulances")
@RequiredArgsConstructor
public class AmbulanceController {

    private final AmbulanceService ambulanceService;
    private final GoogleMapsService googleMapsService;
    private final UserRepository userRepository;
    private final AmbulanceRepository ambulanceRepository;

    /**
     * Secures endpoint to get optimal route for the authenticated driver.
     * POST /api/ambulances/route/suggest
     */
    @PostMapping("/route/suggest")
    public ResponseEntity<String> getRouteSuggestion(
            @RequestBody RouteRequest req,
            Principal principal) {

        // 1. Get current location of the authenticated driver
        String username = principal.getName();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        Ambulance ambulance = ambulanceRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("Ambulance profile not linked to user."));

        GeoJsonPoint currentLocation = ambulance.getLocation();

        if (currentLocation == null) {
            return ResponseEntity.badRequest().body("Ambulance current location is unknown.");
        }

        // GeoJsonPoint uses (Longitude, Latitude)
        double originLng = currentLocation.getX();
        double originLat = currentLocation.getY();

        // 2. Call the Google Maps service to get the optimized route
        String routeGeoJson = googleMapsService.getOptimizedRoute(
                originLat, originLng,
                req.getDestinationLat(), req.getDestinationLng()
        );

        // 3. Return the route data (Polyline string or GeoJSON)
        return ResponseEntity.ok(routeGeoJson);
    }

    /**
     * NEW: Return active ambulances with location for police / client apps.
     * GET /api/ambulances/active
     *
     * Response format:
     * [
     *   {
     *     "id": "...",
     *     "vehicleNumber": "...",
     *     "driverName": "...",
     *     "status": "ON_DUTY",
     *     "lastUpdated": "2025-12-01T23:00:00Z",
     *     "location": { "type": "Point", "coordinates": [lng, lat] }
     *   },
     *   ...
     * ]
     */
    @GetMapping("/active")
    public ResponseEntity<List<Map<String, Object>>> getActiveAmbulances() {

        List<Ambulance> all = ambulanceRepository.findAll();

        List<Map<String, Object>> resp = all.stream()
                // keep only ambulances that have a location (and optionally filter by status)
                .filter(a -> a.getLocation() != null /* && a.getStatus() == AmbulanceStatus.ON_DUTY */)
                .map(a -> Map.of(
                        "id", a.getId(),
                        "vehicleNumber", a.getVehicleNumber(),
                        "driverName", a.getDriverName(),
                        // send status as string (e.g., "ON_DUTY" / "OFF_DUTY")
                        "status", a.getStatus() != null ? a.getStatus().name() : null,
                        "lastUpdated", a.getLastUpdated() != null ? a.getLastUpdated().toString() : null,
                        "location", Map.of(
                                "type", "Point",
                                "coordinates", List.of(a.getLocation().getX(), a.getLocation().getY())
                        )
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(resp);
    }

    /**
     * NEW: Return single ambulance details by id
     * GET /api/ambulances/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getAmbulanceById(@PathVariable String id) {
        Ambulance a = ambulanceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ambulance not found: " + id));

        Map<String, Object> resp = Map.of(
                "id", a.getId(),
                "vehicleNumber", a.getVehicleNumber(),
                "driverName", a.getDriverName(),
                "status", a.getStatus() != null ? a.getStatus().name() : null,
                "lastUpdated", a.getLastUpdated() != null ? a.getLastUpdated().toString() : null,
                "location", a.getLocation() == null ? null : Map.of(
                        "type", "Point",
                        "coordinates", List.of(a.getLocation().getX(), a.getLocation().getY())
                )
        );

        return ResponseEntity.ok(resp);
    }

    // ... Keep other controller methods here if you have them ...
}
