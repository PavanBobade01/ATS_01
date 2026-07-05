package io.github.pavanbobade01.ATS.dto;


import io.github.pavanbobade01.ATS.model.Role;
import lombok.Data;

@Data
public class RegisterRequest {
    private String username;
    private String password;
    private Role role;
}

