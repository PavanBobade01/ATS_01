// src/main/java/io/github/pavanbobade01/ATS/repository/UserRepository.java
package io.github.pavanbobade01.ATS.repository;

import io.github.pavanbobade01.ATS.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {

    // This method is for your AuthService login
    Optional<User> findByUsername(String username);

    // --- ADD THIS LINE ---
    // This method is for your AuthService register
    Boolean existsByUsername(String username);
}