package com.myotrack.domain;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * Conversores JPA dos enums do domínio. Todos com {@code autoApply}, então as entidades
 * declaram o tipo do enum direto e o valor correto vai para a coluna {@code integer}.
 *
 * <p>{@code @Enumerated(ORDINAL)} não serve: os valores são explícitos no C# original e não
 * coincidem com a ordem de declaração ({@code Equipment.Other = 99}). {@code @Enumerated(STRING)}
 * também não: as colunas são inteiras.
 */
public final class EnumConverters {

    private EnumConverters() {
    }

    /** Base comum: null continua null, o resto vai e volta pelo valor explícito. */
    private abstract static class Base<E extends Enum<E> & WireEnum> implements AttributeConverter<E, Integer> {

        private final Class<E> type;

        protected Base(Class<E> type) {
            this.type = type;
        }

        @Override
        public Integer convertToDatabaseColumn(E attribute) {
            return attribute == null ? null : attribute.getValue();
        }

        @Override
        public E convertToEntityAttribute(Integer dbData) {
            return dbData == null ? null : WireEnums.fromValue(type, dbData);
        }
    }

    @Converter(autoApply = true)
    public static class BiotypeConverter extends Base<Biotype> {
        public BiotypeConverter() {
            super(Biotype.class);
        }
    }

    @Converter(autoApply = true)
    public static class ExperienceLevelConverter extends Base<ExperienceLevel> {
        public ExperienceLevelConverter() {
            super(ExperienceLevel.class);
        }
    }

    @Converter(autoApply = true)
    public static class FitnessGoalConverter extends Base<FitnessGoal> {
        public FitnessGoalConverter() {
            super(FitnessGoal.class);
        }
    }

    @Converter(autoApply = true)
    public static class CalorieGoalConverter extends Base<CalorieGoal> {
        public CalorieGoalConverter() {
            super(CalorieGoal.class);
        }
    }

    @Converter(autoApply = true)
    public static class MuscleGroupConverter extends Base<MuscleGroup> {
        public MuscleGroupConverter() {
            super(MuscleGroup.class);
        }
    }

    @Converter(autoApply = true)
    public static class EquipmentConverter extends Base<Equipment> {
        public EquipmentConverter() {
            super(Equipment.class);
        }
    }

    @Converter(autoApply = true)
    public static class PlanStatusConverter extends Base<PlanStatus> {
        public PlanStatusConverter() {
            super(PlanStatus.class);
        }
    }

    @Converter(autoApply = true)
    public static class ConsentTypeConverter extends Base<ConsentType> {
        public ConsentTypeConverter() {
            super(ConsentType.class);
        }
    }

    @Converter(autoApply = true)
    public static class AnalysisJobTypeConverter extends Base<AnalysisJobType> {
        public AnalysisJobTypeConverter() {
            super(AnalysisJobType.class);
        }
    }

    @Converter(autoApply = true)
    public static class JobStatusConverter extends Base<JobStatus> {
        public JobStatusConverter() {
            super(JobStatus.class);
        }
    }

    @Converter(autoApply = true)
    public static class ReviewStatusConverter extends Base<ReviewStatus> {
        public ReviewStatusConverter() {
            super(ReviewStatus.class);
        }
    }

    @Converter(autoApply = true)
    public static class SubscriptionPlanTypeConverter extends Base<SubscriptionPlanType> {
        public SubscriptionPlanTypeConverter() {
            super(SubscriptionPlanType.class);
        }
    }

    @Converter(autoApply = true)
    public static class SubscriptionProviderConverter extends Base<SubscriptionProvider> {
        public SubscriptionProviderConverter() {
            super(SubscriptionProvider.class);
        }
    }

    @Converter(autoApply = true)
    public static class DevicePlatformConverter extends Base<DevicePlatform> {
        public DevicePlatformConverter() {
            super(DevicePlatform.class);
        }
    }
}
