package com.example.orderservice.client;


import com.example.orderservice.dto.UserDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class UserServiceClient {

    @Autowired
    private RestTemplate restTemplate;

    @Value("${services.user-service.url}")
    private String userServiceUrl;

    public UserDto getUserById(Long userId) {
        try {
            return restTemplate.getForObject(
                    userServiceUrl + "/api/users/" + userId,
                    UserDto.class
            );
        } catch (Exception e) {
            throw new RuntimeException("User service is unavailable");
        }
    }

}
