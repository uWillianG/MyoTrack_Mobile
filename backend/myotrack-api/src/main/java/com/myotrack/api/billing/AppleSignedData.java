package com.myotrack.api.billing;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Lê um dado assinado pela Apple (JWS) e devolve o conteúdo, ou falha.
 *
 * <p>Existe como interface por um motivo só: <b>quem verifica assinatura precisa ser
 * substituível no teste</b>. Forjar uma cadeia de certificados que termina na raiz da Apple é,
 * felizmente, impossível — e um teste que precisasse disso ou não existiria ou nasceria
 * desligando a verificação, que é a única parte que não pode ser desligada.
 */
public interface AppleSignedData {

    /**
     * Verifica a assinatura e devolve o payload já decodificado.
     *
     * @throws InvalidSignedDataException se o JWS estiver malformado, a assinatura não bater ou
     *     a cadeia não subir até a raiz da Apple
     */
    JsonNode read(String jws);

    /** Assinatura ausente, inválida, ou cadeia que não é da Apple. */
    class InvalidSignedDataException extends RuntimeException {

        public InvalidSignedDataException(String message) {
            super(message);
        }

        public InvalidSignedDataException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
