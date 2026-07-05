// src/main/java/io/github/pavanbobade01/ATS/config/WebSocketAuthInterceptor.java
package io.github.pavanbobade01.ATS.config;

import io.github.pavanbobade01.ATS.service.JwtService;
import io.github.pavanbobade01.ATS.service.AppUserDetailsService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private final JwtService jwtService;
    private final AppUserDetailsService userDetailsService;

    private static final String AUTH_HEADER = "Authorization";

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        // Use MessageHeaderAccessor to avoid creating a new accessor accidentally
        StompHeaderAccessor accessor =
                MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor == null) {
            return message;
        }

        StompCommand command = accessor.getCommand();

        // --- Debug logging (very useful while we fix this) ---
        System.out.println("STOMP INBOUND: command=" + command +
                ", sessionId=" + accessor.getSessionId());

        // We authenticate on CONNECT. After that, Spring will reuse accessor.getUser()
        if (StompCommand.CONNECT.equals(command)) {
            String authHeader = accessor.getFirstNativeHeader(AUTH_HEADER);

            System.out.println("STOMP CONNECT headers Authorization = " + authHeader);

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                System.err.println("STOMP Auth Failed: missing or invalid Authorization header");
                // Returning null rejects the CONNECT frame (client will see error)
                return null;
            }

            String jwt = authHeader.substring(7);

            try {
                String username = jwtService.extractUsername(jwt);
                if (username == null) {
                    System.err.println("STOMP Auth Failed: could not extract username from token");
                    return null;
                }

                UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                if (!jwtService.isTokenValid(jwt, userDetails.getUsername())) {
                    System.err.println("STOMP Auth Failed: token is not valid");
                    return null;
                }

                // ✅ Token is valid -> create Authentication
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                // ✅ Attach authenticated user to WebSocket session
                accessor.setUser(authentication);

                // Optional: also put into SecurityContextHolder (not strictly required)
                SecurityContextHolder.getContext().setAuthentication(authentication);

                System.out.println("STOMP Auth SUCCESS for user: " + username);

            } catch (Exception e) {
                System.err.println("STOMP Auth Failed for token: " + e.getMessage());
                return null; // reject connection on error
            }
        } else {
            // For non-CONNECT frames, just log which user is attached
            if (accessor.getUser() == null) {
                System.out.println("STOMP " + command + " received with NO user attached.");
            } else {
                System.out.println("STOMP " + command + " from user: " +
                        accessor.getUser().getName());
            }
        }

        return message;
    }
}
