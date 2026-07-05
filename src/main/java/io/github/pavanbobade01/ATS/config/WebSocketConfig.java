package io.github.pavanbobade01.ATS.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    // Interceptor that will validate JWT for STOMP CONNECT frames, etc.
    private final WebSocketAuthInterceptor webSocketAuthInterceptor;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Topics the clients can subscribe to: e.g. /topic/police.locations
        registry.enableSimpleBroker("/topic");

        // Prefix for messages sent from client to server: e.g. /app/driver.location
        registry.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                // allow all origins for now (good for dev; tighten later if you want)
                .setAllowedOriginPatterns("*")
                // IMPORTANT: enable SockJS so the URL works with StompConfig.sockJS on Flutter
                .withSockJS();
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        // Register your custom auth interceptor for incoming STOMP frames
        registration.interceptors(webSocketAuthInterceptor);
    }
}
