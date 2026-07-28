package com.myotrack.infrastructure.email;

public record EmailContent(String subject, String htmlBody, String textBody) {
}
