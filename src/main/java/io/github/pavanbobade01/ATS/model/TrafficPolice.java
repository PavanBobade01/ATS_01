package io.github.pavanbobade01.ATS.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;

@Document(collection = "traffic_police")
public class TrafficPolice {

    @Id
    private String id;
    private String userId;
    private String stationName; // The field exists

    @GeoSpatialIndexed
    private GeoJsonPoint location;

    // --- Getters and Setters ---
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public GeoJsonPoint getLocation() { return location; }
    public void setLocation(GeoJsonPoint location) { this.location = location; }

    // --- ⚠️ ADD THESE TWO METHODS ---
    public String getStationName() {
        return stationName;
    }
    public void setStationName(String stationName) {
        this.stationName = stationName;
    }
}