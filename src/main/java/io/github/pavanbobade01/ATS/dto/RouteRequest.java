// src/main/java/io/github/pavanbobade01/ATS/dto/RouteRequest.java
package io.github.pavanbobade01.ATS.dto;

import lombok.Data;

@Data
public class RouteRequest {
    private double destinationLat; // Destination point
    private double destinationLng; // Destination point
}