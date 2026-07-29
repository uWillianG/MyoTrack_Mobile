package com.myotrack.infrastructure.email;

/**
 * Modelos de e-mail transacional (pt-BR). HTML inline e tabelas simples porque
 * clientes de e-mail não suportam CSS moderno nem folhas externas.
 *
 * <p>Porte de MyoTrack.Infrastructure/Email/EmailTemplates.cs — o texto e o layout são os mesmos
 * para que o e-mail não mude de cara na migração.
 */
public final class EmailTemplates {

    private EmailTemplates() {
    }

    public static EmailContent passwordReset(String resetUrl, int validHours) {
        String subject = "Redefinição de senha — MyoTrack";

        String text = """
                Recebemos um pedido para redefinir a senha da sua conta no MyoTrack.

                Abra o link abaixo para criar uma senha nova (válido por %d horas):
                %s

                Se não foi você que pediu, ignore este e-mail — sua senha continua a mesma.

                MyoTrack — seu personal trainer e nutricionista digital
                """.formatted(validHours, resetUrl);

        String body = """
                <p style="margin:0 0 16px">Recebemos um pedido para redefinir a senha da sua conta no MyoTrack.</p>
                <p style="margin:0 0 24px">Clique no botão abaixo para criar uma senha nova. O link vale por <strong>%d horas</strong>.</p>
                %s
                <p style="margin:24px 0 0;font-size:13px;color:#64748b">
                  Se o botão não funcionar, copie e cole este endereço no navegador:<br>
                  <span style="word-break:break-all">%s</span>
                </p>
                <p style="margin:16px 0 0;font-size:13px;color:#64748b">
                  Se não foi você que pediu, ignore este e-mail — sua senha continua a mesma.
                </p>
                """.formatted(validHours, button("Criar nova senha", resetUrl), escapeHtml(resetUrl));

        return new EmailContent(subject, layout("Redefinir sua senha", body), text);
    }

    /** E-mail que leva o export de dados (LGPD) em anexo. */
    public static EmailContent dataExport(String filename) {
        String subject = "Seus dados no MyoTrack";

        String text = """
                Em anexo estão todos os dados da sua conta no MyoTrack, em formato JSON:
                perfil, planos de treino e dieta, treinos registrados, medidas, análises de
                refeição e de vídeo, e sua assinatura.

                Arquivo: %s

                Você pediu este arquivo dentro do app. Se não foi você, troque sua senha.

                MyoTrack — seu personal trainer e nutricionista digital
                """.formatted(filename);

        String body = """
                <p style="margin:0 0 16px">Em anexo estão todos os dados da sua conta no MyoTrack, em formato JSON.</p>
                <p style="margin:0 0 16px">O arquivo inclui seu perfil, planos de treino e dieta, treinos registrados,
                medidas, análises de refeição e de vídeo, e sua assinatura.</p>
                <p style="margin:0 0 24px;font-size:13px;color:#64748b">Arquivo: <strong>%s</strong></p>
                <p style="margin:16px 0 0;font-size:13px;color:#64748b">
                  Você pediu este arquivo dentro do app. Se não foi você, troque sua senha.
                </p>
                """.formatted(escapeHtml(filename));

        return new EmailContent(subject, layout("Seus dados", body), text);
    }

    private static String button(String label, String url) {
        return """
                <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0">
                  <tr><td style="border-radius:12px;background:#059669">
                    <a href="%s"
                       style="display:inline-block;padding:12px 24px;font-family:Helvetica,Arial,sans-serif;
                              font-size:15px;font-weight:bold;color:#ffffff;text-decoration:none">%s</a>
                  </td></tr>
                </table>
                """.formatted(escapeHtml(url), label);
    }

    /**
     * Escape do mínimo necessário para o contexto: a URL entra em atributo href e em texto.
     * Equivale ao {@code WebUtility.HtmlEncode} do .NET para esses casos, sem arrastar o
     * spring-web para dentro deste módulo.
     */
    private static String escapeHtml(String value) {
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static String layout(String title, String bodyHtml) {
        return """
                <!doctype html>
                <html lang="pt-BR"><body style="margin:0;padding:24px;background:#f4f6f5;
                  font-family:Helvetica,Arial,sans-serif;color:#334155;font-size:15px;line-height:1.6">
                  <table role="presentation" cellpadding="0" cellspacing="0" width="100%%" style="max-width:520px;margin:0 auto">
                    <tr><td style="padding:0 0 20px">
                      <span style="font-size:20px;font-weight:bold;color:#0f172a">Myo<span style="color:#10b981">Track</span></span>
                    </td></tr>
                    <tr><td style="background:#ffffff;border:1px solid #e2e8f0;border-radius:16px;padding:28px">
                      <h1 style="margin:0 0 16px;font-size:19px;color:#0f172a">%s</h1>
                      %s
                    </td></tr>
                    <tr><td style="padding:20px 0;font-size:12px;color:#94a3b8">
                      MyoTrack — seu personal trainer e nutricionista digital.<br>
                      Este é um e-mail automático, não responda.
                    </td></tr>
                  </table>
                </body></html>
                """.formatted(title, bodyHtml);
    }
}
