package io.github.pavanbobade01.ATS.dto;


import io.github.pavanbobade01.ATS.model.AmbulanceStatus;
import lombok.Data;

@Data
public class AmbulanceRequest {
    private String vehicleNumber;

    // --- THIS IS THE CHANGE ---
    private String driverId;           // ID of User (driver)

    private AmbulanceStatus status;    // AVAILABLE / ON_DUTY / OFF_DUTY
    private Double latitude;           // optional initial lat
    private Double longitude;          // optional initial lng
}