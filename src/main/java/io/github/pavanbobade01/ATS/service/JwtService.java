package io.github.pavanbobade01.ATS.service;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.util.Date;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    /**
     * Inject the secret from application.properties:
     *   jwt.secret.key=<your-secret-here>
     *
     * The secret must be long enough for HS256 (recommended >= 32 bytes).
     */
    @Value("${jwt.secret.key}")
    private String SECRET;

    private final long EXPIRATION_TIME = 1000 * 60 * 60; // 1 hour

    @PostConstruct
    public void verifySecretKeyLoad() {
        if (SECRET == null || SECRET.isBlank()) {
            throw new IllegalStateException("JWT secret key is not configured. Set 'jwt.secret.key' in application.properties");
        }
        // Print length for quick verification in logs (safe enough in dev; remove in prod if desired)
        System.out.println("✅ JWT Secret Key Loaded successfully. Length: " + SECRET.length());
    }

    private Key getSignKey() {
        return Keys.hmacShaKeyFor(SECRET.getBytes());
    }

    /**
     * Generate a token containing subject (username) and a "role" claim.
     * Pass the role string exactly as you want it stored (for example: "ROLE_DRIVER").
     */
    public String generateToken(String username, String role) {
        return Jwts.builder()
                .setSubject(username)
                .addClaims(Map.of("role", role))
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(getSignKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * Extracts the role claim (if present). Returns null if claim missing.
     */
    public String extractRole(String token) {
        try {
            Claims claims = extractAllClaims(token);
            Object roleObj = claims.get("role");
            return roleObj != null ? roleObj.toString() : null;
        } catch (JwtException e) {
            // Let caller handle invalid token
            throw e;
        }
    }

    public <T> T extractClaim(String token, Function<Claims, T> resolver) {
        final Claims claims = extractAllClaims(token);
        return resolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        // Will throw JwtException (e.g. ExpiredJwtException, MalformedJwtException) on invalid tokens
        return Jwts.parserBuilder().setSigningKey(getSignKey()).build().parseClaimsJws(token).getBody();
    }

    public boolean isTokenValid(String token, String username) {
        try {
            return username.equals(extractUsername(token)) && !isTokenExpired(token);
        } catch (JwtException e) {
            // invalid token (expired, malformed, etc.)
            return false;
        }
    }

    private boolean isTokenExpired(String token) {
        try {
            return extractClaim(token, Claims::getExpiration).before(new Date());
        } catch (JwtException e) {
            // treat invalid tokens as expired/invalid
            return true;
        }
    }
}
