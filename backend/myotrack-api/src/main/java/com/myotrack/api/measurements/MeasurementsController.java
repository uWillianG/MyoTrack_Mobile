package com.myotrack.api.measurements;

import com.myotrack.api.security.CurrentUser;
import com.myotrack.domain.entity.BodyMeasurement;
import com.myotrack.infrastructure.repository.BodyMeasurementRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Medidas corporais. Porte de MyoTrack.Api/Controllers/MeasurementsController.cs.
 *
 * <p>O peso registrado aqui é o que alimenta o cálculo de TDEE na geração da dieta — sem ao
 * menos uma medida, não há como prescrever calorias.
 */
@RestController
@RequestMapping("/api/measurements")
public class MeasurementsController {

    private static final BigDecimal MAX_WEIGHT_KG = BigDecimal.valueOf(500);

    private final BodyMeasurementRepository measurements;

    public MeasurementsController(BodyMeasurementRepository measurements) {
        this.measurements = measurements;
    }

    @PostMapping
    @Transactional
    public ResponseEntity<?> create(@RequestBody MeasurementRequest request) {
        if (request.weightKg() != null
                && (request.weightKg().signum() <= 0
                        || request.weightKg().compareTo(MAX_WEIGHT_KG) > 0)) {
            return ResponseEntity.badRequest().body(Map.of("error", "Peso fora da faixa válida."));
        }

        final BodyMeasurement measurement = new BodyMeasurement();
        measurement.setUserId(CurrentUser.id());
        measurement.setDate(request.date() == null ? LocalDate.now() : request.date());
        measurement.setWeightKg(request.weightKg());
        measurement.setBodyFatPercent(request.bodyFatPercent());
        measurement.setWaistCm(request.waistCm());
        measurement.setChestCm(request.chestCm());
        measurement.setHipCm(request.hipCm());
        measurement.setArmCm(request.armCm());
        measurement.setThighCm(request.thighCm());
        measurement.setCalfCm(request.calfCm());

        return ResponseEntity.ok(measurements.save(measurement));
    }

    /** Em ordem crescente de data — é assim que o gráfico de evolução consome. */
    @GetMapping
    public List<BodyMeasurement> list() {
        return measurements.findByUserIdOrderByDateDesc(CurrentUser.id()).stream()
                .sorted(Comparator.comparing(BodyMeasurement::getDate))
                .toList();
    }

    public record MeasurementRequest(
            LocalDate date,
            BigDecimal weightKg,
            BigDecimal bodyFatPercent,
            BigDecimal waistCm,
            BigDecimal chestCm,
            BigDecimal hipCm,
            BigDecimal armCm,
            BigDecimal thighCm,
            BigDecimal calfCm) {
    }
}
