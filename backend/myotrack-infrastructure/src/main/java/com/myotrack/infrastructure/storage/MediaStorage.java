package com.myotrack.infrastructure.storage;

import java.io.InputStream;
import java.time.Duration;

/**
 * Mídia do usuário (fotos de refeição e vídeos de exercício) no MinIO.
 * Porte de MyoTrack.Infrastructure/Storage/MediaStorage.cs.
 */
public interface MediaStorage {

    void upload(String key, InputStream content, long size, String contentType);

    byte[] download(String key);

    void delete(String key);

    /** URL pré-assinada de PUT para o cliente subir a mídia direto no storage. */
    String presignedUploadUrl(String key, String contentType, Duration expiry);

    /** URL pré-assinada de GET para o cliente baixar/reproduzir a mídia. */
    String presignedDownloadUrl(String key, Duration expiry);

    /** Metadados do objeto, ou null se não existir. */
    StoredObjectInfo objectInfo(String key);
}
