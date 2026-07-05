// src/main/java/io/github/pavanbobade01/ATS/repository/AmbulanceRepository.java
package io.github.pavanbobade01.ATS.repository;

import io.github.pavanbobade01.ATS.model.Ambulance;
import io.github.pavanbobade01.ATS.model.AmbulanceStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;
import java.util.Optional;

// Change to MongoRepository and use String for the ID
public interface AmbulanceRepository extends MongoRepository<Ambulance, String> {

    // This will be useful for finding the ambulance from the logged-in user
    Optional<Ambulance> findByUserId(String userId);

    // --- THIS IS THE NEW, POWERFUL METHOD ---
    // This one method replaces the entire Haversine formula.
    // It finds all ambulances with a specific status "near" a geographic point.
    List<Ambulance> findByStatusAndLocationNear(AmbulanceStatus status, GeoJsonPoint point, org.springframework.data.geo.Distance distance);
}