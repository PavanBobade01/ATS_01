// src/main/java/io/github/pavanbobade01/ATS/repository/TrafficPoliceRepository.java
package io.github.pavanbobade01.ATS.repository;

import io.github.pavanbobade01.ATS.model.TrafficPolice;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface TrafficPoliceRepository extends MongoRepository<TrafficPolice, String> {

    // For finding the police officer from the logged-in user
    Optional<TrafficPolice> findByUserId(String userId);

    // --- ADD THIS LINE ---
    // This method is for your TrafficService register
    Boolean existsByUserId(String userId);
}