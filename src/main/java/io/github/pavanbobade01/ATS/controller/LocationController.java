package io.github.pavanbobade01.ATS.controller;

import io.github.pavanbobade01.ATS.dto.LocationUpdateRequest;
import io.github.pavanbobade01.ATS.model.Ambulance;
import io.github.pavanbobade01.ATS.model.User;
import io.github.pavanbobade01.ATS.repository.UserRepository;
import io.github.pavanbobade01.ATS.service.AmbulanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import java.security.Principal;

@Controller
@RequiredArgsConstructor
public class LocationController {

    private final UserRepository userRepository;
    private final AmbulanceService ambulanceService;
    private final SimpMessagingTemplate messagingTemplate;

    // STOMP endpoint → /app/driver.location
    @MessageMapping("/driver.location")
    public void handleLocationStomp(@Payload LocationUpdateRequest request, Principal principal) {
        Ambulance updated = updateLocationAndBroadcast(request, principal);
        // STOMP does not return a response
    }

    // REST endpoint → POST /api/driver/location (Postman)
    @PostMapping("/api/driver/location")
    @ResponseBody
    public ResponseEntity<Ambulance> handleLocationRest(
            @RequestBody LocationUpdateRequest request,
            Principal principal
    ) {
        Ambulance updated = updateLocationAndBroadcast(request, principal);
        return ResponseEntity.ok(updated);
    }

    // SHARED LOGIC
    private Ambulance updateLocationAndBroadcast(LocationUpdateRequest request, Principal principal) {

        if (principal == null) {
            throw new UsernameNotFoundException("Unauthenticated request (no principal)");
        }

        String username = principal.getName();

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        // 🔥 PERMANENT FIX: use service method (auto-create ambulance if missing)
        Ambulance savedAmbulance =
                ambulanceService.updateLocationForDriver(user, request);

        // Broadcast to police
        messagingTemplate.convertAndSend("/topic/police.locations", savedAmbulance);

        return savedAmbulance;
    }
}
