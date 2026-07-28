package com.myotrack.infrastructure.repository;

import com.myotrack.infrastructure.identity.UserLogin;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserLoginRepository extends JpaRepository<UserLogin, UserLogin.Key> {

    /** Reencontra a conta pelo provider + sub do Google, antes de tentar casar por e-mail. */
    Optional<UserLogin> findByIdLoginProviderAndIdProviderKey(String loginProvider, String providerKey);
}
