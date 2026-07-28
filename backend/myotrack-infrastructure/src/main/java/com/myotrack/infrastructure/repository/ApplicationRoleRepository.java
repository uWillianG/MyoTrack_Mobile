package com.myotrack.infrastructure.repository;

import com.myotrack.infrastructure.identity.ApplicationRole;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ApplicationRoleRepository extends JpaRepository<ApplicationRole, UUID> {

    Optional<ApplicationRole> findByNormalizedName(String normalizedName);
}
