package com.myotrack.infrastructure.repository;

import com.myotrack.infrastructure.identity.UserRole;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface UserRoleRepository extends JpaRepository<UserRole, UserRole.Key> {

    /** Nomes dos papéis do usuário — é o que vai para o claim do JWT. */
    @Query("""
            select r.name
            from UserRole ur
            join ApplicationRole r on r.id = ur.id.roleId
            where ur.id.userId = :userId
            """)
    List<String> findRoleNamesByUserId(UUID userId);
}
