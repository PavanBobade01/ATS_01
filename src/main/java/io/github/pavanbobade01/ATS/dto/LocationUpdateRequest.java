package io.github.pavanbobade01.ATS.dto;

import lombok.Data;

@Data
public class LocationUpdateRequest {
    // We remove the ambulanceId because the server will
    // get the user from the JWT token (the Principal)

    private Double latitude;
    private Double longitude;
}