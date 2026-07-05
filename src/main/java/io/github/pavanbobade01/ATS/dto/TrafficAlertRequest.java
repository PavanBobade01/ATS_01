package io.github.pavanbobade01.ATS.dto;


import lombok.Data;

@Data
public class TrafficAlertRequest {
    private Double latitude;
    private Double longitude;
    private String message;   // e.g., "Accident at signal"
}
