package com.myotrack.infrastructure.email;

import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.io.UnsupportedEncodingException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

/**
 * Envia por SMTP quando há credenciais; sem elas, escreve a mensagem no log — o que permite
 * testar o fluxo de recuperação de senha em desenvolvimento sem configurar nada (o link aparece
 * no log da API, exatamente como no backend .NET).
 *
 * <p>Porte de MyoTrack.Infrastructure/Email/SmtpEmailSender.cs.
 */
@Service
public class EmailSender {

    private static final Logger log = LoggerFactory.getLogger(EmailSender.class);

    private final EmailProperties properties;

    public EmailSender(EmailProperties properties) {
        this.properties = properties;
    }

    /** Há credenciais SMTP configuradas (envio real, não só log). */
    public boolean isConfigured() {
        return properties.isConfigured();
    }

    public void send(String to, EmailContent content) {
        send(to, content, null);
    }

    /**
     * Envia com um anexo opcional.
     *
     * <p>O anexo existe para o export de dados (LGPD): o arquivo vai junto do e-mail em vez
     * de virar um link, que precisaria de uma URL pública para dados pessoais.
     */
    public void send(String to, EmailContent content, Attachment attachment) {
        if (!isConfigured()) {
            log.info("SMTP não configurado — e-mail não enviado.\nPara: {}\nAssunto: {}\n{}",
                    to, content.subject(), content.textBody());
            return;
        }

        try {
            JavaMailSenderImpl sender = buildSender();
            MimeMessage message = sender.createMimeMessage();

            // true = multipart, para mandar texto e HTML na mesma mensagem.
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(new InternetAddress(properties.effectiveFrom(), properties.fromName(), "UTF-8"));
            helper.setTo(to);
            helper.setSubject(content.subject());
            helper.setText(content.textBody(), content.htmlBody());

            sender.send(message);
            log.info("E-mail enviado para {}: {}", to, content.subject());
        } catch (MailException | jakarta.mail.MessagingException | UnsupportedEncodingException e) {
            // Falha de SMTP não pode derrubar o pedido de recuperação de senha: a resposta ao
            // cliente é sempre a mesma, exista ou não a conta, e vazar a falha revelaria o cadastro.
            log.error("Falha ao enviar e-mail para {}: {}", to, e.getMessage(), e);
        }
    }

    /** Arquivo anexado à mensagem. */
    public record Attachment(String filename, byte[] bytes, String contentType) {
    }

    private JavaMailSenderImpl buildSender() {
        JavaMailSenderImpl sender = new JavaMailSenderImpl();
        sender.setHost(properties.host());
        sender.setPort(properties.port());
        sender.setUsername(properties.user());
        sender.setPassword(properties.password());
        sender.setDefaultEncoding("UTF-8");

        java.util.Properties mail = sender.getJavaMailProperties();
        mail.put("mail.transport.protocol", "smtp");
        mail.put("mail.smtp.auth", "true");
        mail.put("mail.smtp.starttls.enable", String.valueOf(properties.useStartTls()));
        mail.put("mail.smtp.starttls.required", String.valueOf(properties.useStartTls()));
        return sender;
    }
}
