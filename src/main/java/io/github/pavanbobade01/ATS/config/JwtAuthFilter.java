package io.github.pavanbobade01.ATS.config;

import io.github.pavanbobade01.ATS.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();

        // Skip authentication for login/register
        if (path.startsWith("/api/auth/")) {
            System.out.println("JWT FILTER: skipping /api/auth/* -> " + path);
            return true;
        }

        // Skip websocket handshake (SockJS)
        if (path.startsWith("/ws")) {
            System.out.println("JWT FILTER: skipping /ws* -> " + path);
            return true;
        }

        // Skip CORS preflight
        if (HttpMethod.OPTIONS.matches(request.getMethod())) {
            System.out.println("JWT FILTER: skipping OPTIONS -> " + path);
            return true;
        }

        return false;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        String uri = request.getRequestURI();
        final String authHeader = request.getHeader("Authorization");
        System.out.println("JWT FILTER: " + request.getMethod() + " " + uri +
                " | Authorization=" + authHeader);

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            // No token → let request continue as anonymous
            filterChain.doFilter(request, response);
            return;
        }

        final String jwt = authHeader.substring(7);

        try {
            final String username = jwtService.extractUsername(jwt);
            System.out.println("JWT FILTER: extracted username = " + username);

            if (username != null &&
                    SecurityContextHolder.getContext().getAuthentication() == null) {

                UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                System.out.println("JWT FILTER: loaded userDetails = " + userDetails.getUsername()
                        + " | authorities=" + userDetails.getAuthorities());

                if (jwtService.isTokenValid(jwt, userDetails.getUsername())) {
                    System.out.println("JWT FILTER: token valid, setting Authentication");

                    UsernamePasswordAuthenticationToken authToken =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails, null, userDetails.getAuthorities()
                            );

                    authToken.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request)
                    );

                    SecurityContextHolder.getContext().setAuthentication(authToken);
                } else {
                    System.out.println("JWT FILTER: token INVALID");
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid JWT token");
                    return;
                }
            }

            filterChain.doFilter(request, response);

        } catch (Exception e) {
            System.out.println("JWT FILTER: exception -> " + e.getMessage());
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid Token");
        }
    }
}
