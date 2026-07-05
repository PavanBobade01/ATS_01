// src/main/java/io/github/pavanbobade01/ATS/model/User.java
package io.github.pavanbobade01.ATS.model;

// --- ADD THESE LOMBOK IMPORTS ---
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

// --- ADD THESE LOMBOK ANNOTATIONS ---
@Data // Adds getters, setters, toString, etc.
@Builder // Adds the .builder() method
@NoArgsConstructor // Adds a no-argument constructor
@AllArgsConstructor // Adds an all-argument constructor

@Document(collection = "users")
public class User implements UserDetails {

    @Id
    private String id;

    @Indexed(unique = true)
    private String username;

    private String password;

    private Role role;

    // --- UserDetails Methods (for Spring Security) ---

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority(role.name()));
    }

    // ... (all other UserDetails methods are the same) ...
    @Override
    public String getPassword() { return password; }

    @Override
    public String getUsername() { return username; }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return true; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return true; }
}