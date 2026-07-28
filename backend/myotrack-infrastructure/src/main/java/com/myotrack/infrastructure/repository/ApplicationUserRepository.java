package com.myotrack.infrastructure.repository;

import com.myotrack.infrastructure.identity.ApplicationUser;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ApplicationUserRepository extends JpaRepository<ApplicationUser, UUID> {

    /**
     * A busca é pela coluna normalizada (maiúsculas), como o Identity sempre fez — é ela que
     * tem o índice e é o que garante que "Willian@x.com" e "willian@x.com" sejam a mesma conta.
     */
    Optional<ApplicationUser> findByNormalizedEmail(String normalizedEmail);

    boolean existsByNormalizedEmail(String normalizedEmail);
}
