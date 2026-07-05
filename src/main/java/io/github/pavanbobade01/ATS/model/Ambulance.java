package io.github.pavanbobade01.ATS.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;
import java.time.LocalDateTime;

@Document(collection = "ambulances")
public class Ambulance {

    @Id
    private String id;

    private String userId;
    private String driverName;
    private String vehicleNumber;

    @GeoSpatialIndexed
    private GeoJsonPoint location;

    private AmbulanceStatus status;

    private LocalDateTime lastUpdated;

    // --- ⚠️ ADD ALL THESE GETTERS AND SETTERS ---

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getDriverName() { return driverName; }
    public void setDriverName(String driverName) { this.driverName = driverName; }
    public String getVehicleNumber() { return vehicleNumber; }
    public void setVehicleNumber(String vehicleNumber) { this.vehicleNumber = vehicleNumber; }
    public GeoJsonPoint getLocation() { return location; }
    public void setLocation(GeoJsonPoint location) { this.location = location; }
    public AmbulanceStatus getStatus() { return status; }
    public void setStatus(AmbulanceStatus status) { this.status = status; }
    public LocalDateTime getLastUpdated() { return lastUpdated; }
    public void setLastUpdated(LocalDateTime lastUpdated) { this.lastUpdated = lastUpdated; }
}