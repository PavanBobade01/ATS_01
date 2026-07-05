package io.github.pavanbobade01.ATS.controller;


import io.github.pavanbobade01.ATS.dto.TrafficAlertRequest;
import io.github.pavanbobade01.ATS.model.TrafficPolice;
import io.github.pavanbobade01.ATS.service.TrafficService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/traffic")
@RequiredArgsConstructor
public class TrafficController {

    private final TrafficService trafficService;

    // Register Traffic Police (link with existing user)
    @PostMapping("/register")
    public ResponseEntity<TrafficPolice> register(
            @RequestParam String userId, // <-- ⚠️ CHANGED to String
            @RequestParam String stationName,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng) {

        return ResponseEntity.ok(trafficService.registerTrafficPolice(userId, stationName, lat, lng));
    }

    @GetMapping
    public ResponseEntity<List<TrafficPolice>> getAll() {
        return ResponseEntity.ok(trafficService.getAllTrafficPolice());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TrafficPolice> getById(
            @PathVariable String id) { // <-- ⚠️ CHANGED to String

        return ResponseEntity.ok(trafficService.getTrafficPolice(id));
    }

    // Send alert from police
    @PostMapping("/{id}/alert")
    public ResponseEntity<String> sendAlert(
            @PathVariable String id, // <-- ⚠️ CHANGED to String
            @RequestBody TrafficAlertRequest req) {

        return ResponseEntity.ok(trafficService.sendTrafficAlert(id, req));
    }
}