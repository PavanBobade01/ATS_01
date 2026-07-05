// src/main/java/io/github/pavanbobade01/ATS/service/TrafficService.java
package io.github.pavanbobade01.ATS.service;

import io.github.pavanbobade01.ATS.dto.TrafficAlertRequest;
import io.github.pavanbobade01.ATS.model.TrafficPolice;
import io.github.pavanbobade01.ATS.repository.TrafficPoliceRepository;
import io.github.pavanbobade01.ATS.model.User;
import io.github.pavanbobade01.ATS.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

// jakarta.transaction.Transactional is removed
import java.util.List;

@Service
@RequiredArgsConstructor
public class TrafficService {

    private final TrafficPoliceRepository trafficPoliceRepository;
    private final UserRepository userRepository;

    public TrafficPolice registerTrafficPolice(String userId, String stationName, Double lat, Double lng) {
        // Use String ID
        if (trafficPoliceRepository.existsByUserId(userId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User is already registered as Traffic Police");
        }

        // Use String ID
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        TrafficPolice tp = new TrafficPolice();
        tp.setUserId(user.getId()); // Link by String ID
        tp.setStationName(stationName);

        // Set location using GeoJsonPoint (Longitude, Latitude)
        if (lat != null && lng != null) {
            tp.setLocation(new GeoJsonPoint(lng, lat));
        }

        return trafficPoliceRepository.save(tp);
    }

    public List<TrafficPolice> getAllTrafficPolice() {
        return trafficPoliceRepository.findAll();
    }

    public TrafficPolice getTrafficPolice(String id) { // Use String ID
        return trafficPoliceRepository.findById(id) // Use String ID
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Traffic Police not found"));
    }

    public String sendTrafficAlert(String policeId, TrafficAlertRequest req) { // Use String ID
        TrafficPolice police = getTrafficPolice(policeId);

        // This logic is fine, but we can make it better
        // TODO: This should send a STOMP message to "/topic/traffic.alerts"
        // messagingTemplate.convertAndSend("/topic/traffic.alerts", req);

        return "Alert from " + police.getStationName() + ": " + req.getMessage()
                + " @ (" + req.getLatitude() + "," + req.getLongitude() + ")";
    }
}