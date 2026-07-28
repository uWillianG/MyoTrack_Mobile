package com.myotrack.infrastructure.repository;

import com.myotrack.domain.entity.StoreNotificationLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoreNotificationLogRepository extends JpaRepository<StoreNotificationLog, String> {
}
