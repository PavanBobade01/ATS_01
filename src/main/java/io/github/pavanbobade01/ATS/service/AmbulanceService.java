package io.github.pavanbobade01.ATS.service;

import io.github.pavanbobade01.ATS.dto.AmbulanceRequest;
import io.github.pavanbobade01.ATS.dto.LocationUpdateRequest;
import io.github.pavanbobade01.ATS.model.Ambulance;
import io.github.pavanbobade01.ATS.model.AmbulanceStatus;
import io.github.pavanbobade01.ATS.model.User;
import io.github.pavanbobade01.ATS.repository.AmbulanceRepository;
import io.github.pavanbobade01.ATS.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Metrics;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AmbulanceService {

    private final AmbulanceRepository ambulanceRepository;
    private final UserRepository userRepository;

    // -------------------- CREATE BY ADMIN / DRIVER REGISTRATION --------------------

    // This method assumes your User model is also a MongoDB @Document
    public Ambulance createAmbulance(AmbulanceRequest req) {
        User driver = userRepository.findById(req.getDriverId()) // Use String ID
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Driver not found"));

        Ambulance a = new Ambulance();
        a.setVehicleNumber(req.getVehicleNumber());
        a.setUserId(driver.getId());
        // Set the driverName from the User model
        a.setDriverName(driver.getUsername());
        a.setStatus(req.getStatus() == null ? AmbulanceStatus.AVAILABLE : req.getStatus());

        // GeoJSON requires (longitude, latitude)
        if (req.getLatitude() != null && req.getLongitude() != null) {
            a.setLocation(new GeoJsonPoint(req.getLongitude(), req.getLatitude()));
        }

        a.setLastUpdated(LocalDateTime.now());

        return ambulanceRepository.save(a);
    }

    // -------------------- PERMANENT FIX: DRIVER-BASED LOCATION UPDATE --------------------

    /**
     * Update live location for a DRIVER.
     *
     * Logic:
     * - Find ambulance by userId.
     * - If NOT found, create a new ambulance for this user automatically.
     * - Update GeoJsonPoint location and lastUpdated.
     *
     * This method never throws "Ambulance not found for user ...".
     */
    public Ambulance updateLocationForDriver(User driver, LocationUpdateRequest location) {
        // 1) Try to find existing ambulance for this driver
        Ambulance ambulance = ambulanceRepository.findByUserId(driver.getId())
                .orElseGet(() -> {
                    // 2) If not found, create a new ambulance record
                    Ambulance a = new Ambulance();
                    a.setUserId(driver.getId());
                    a.setDriverName(driver.getUsername());
                    a.setVehicleNumber("UNKNOWN"); // you can later update via a separate API
                    a.setStatus(AmbulanceStatus.AVAILABLE);
                    a.setLastUpdated(LocalDateTime.now());
                    return ambulanceRepository.save(a);
                });

        // 3) Update GeoJSON location (longitude, latitude)
        ambulance.setLocation(new GeoJsonPoint(location.getLongitude(), location.getLatitude()));
        ambulance.setLastUpdated(LocalDateTime.now());

        return ambulanceRepository.save(ambulance);
    }

    // -------------------- EXISTING ID-BASED OPERATIONS (KEEP) --------------------

    // This updateLocation method is for your REST controller / admin when you know ambulanceId
    public Ambulance updateLocation(String ambulanceId, LocationUpdateRequest location) {
        Ambulance a = ambulanceRepository.findById(ambulanceId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Ambulance not found"));

        a.setLocation(new GeoJsonPoint(location.getLongitude(), location.getLatitude()));
        a.setLastUpdated(LocalDateTime.now());
        return ambulanceRepository.save(a);
    }

    public Ambulance setStatus(String ambulanceId, AmbulanceStatus status) {
        Ambulance a = ambulanceRepository.findById(ambulanceId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Ambulance not found"));
        a.setStatus(status);
        a.setLastUpdated(LocalDateTime.now());
        return ambulanceRepository.save(a);
    }

    public Ambulance getById(String ambulanceId) {
        return ambulanceRepository.findById(ambulanceId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Ambulance not found"));
    }

    /**
     * Find available ambulances within radiusKm of given lat/lng.
     */
    public List<Ambulance> findAvailableNearby(double lat, double lng, double radiusKm) {
        GeoJsonPoint center = new GeoJsonPoint(lng, lat);
        Distance distance = new Distance(radiusKm, Metrics.KILOMETERS);

        return ambulanceRepository.findByStatusAndLocationNear(
                AmbulanceStatus.AVAILABLE,
                center,
                distance
        );
    }
}
