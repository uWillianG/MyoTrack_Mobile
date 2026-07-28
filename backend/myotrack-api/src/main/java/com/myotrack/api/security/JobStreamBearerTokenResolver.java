package com.myotrack.api.security;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.oauth2.server.resource.web.BearerTokenResolver;
import org.springframework.security.oauth2.server.resource.web.DefaultBearerTokenResolver;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Resolve o token do header {@code Authorization} e, <b>apenas em {@code /api/jobs/**}</b>,
 * também do parâmetro {@code access_token}.
 *
 * <p>A exceção existe porque o acompanhamento de job em tempo real usa SSE, e nem o
 * {@code EventSource} do browser nem o cliente SSE do Android mandam headers customizados —
 * o token precisa viajar na URL. Restringir ao caminho dos jobs limita o estrago de um token
 * que vaze em log de proxy: ele só serve para consultar o status de um job.
 *
 * <p>Porte do {@code JwtBearerEvents.OnMessageReceived} do Program.cs.
 */
@Component
public class JobStreamBearerTokenResolver implements BearerTokenResolver {

    private static final String JOBS_PATH_PREFIX = "/api/jobs";

    private final DefaultBearerTokenResolver delegate = new DefaultBearerTokenResolver();

    @Override
    public String resolve(HttpServletRequest request) {
        String fromHeader = delegate.resolve(request);
        if (fromHeader != null) {
            return fromHeader;
        }

        String path = request.getRequestURI();
        if (path != null && path.startsWith(JOBS_PATH_PREFIX)) {
            String fromQuery = request.getParameter("access_token");
            if (StringUtils.hasText(fromQuery)) {
                return fromQuery;
            }
        }

        return null;
    }
}
