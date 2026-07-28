package com.myotrack.infrastructure.storage;

import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import io.minio.StatObjectArgs;
import io.minio.StatObjectResponse;
import io.minio.errors.ErrorResponseException;
import io.minio.http.Method;
import java.io.InputStream;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Implementação em cima do SDK Java do MinIO.
 *
 * <p>Detalhe herdado do .NET que é fácil perder: <b>a URL pré-assinada só vale para o host com
 * que foi assinada</b>. Em produção o backend fala com o MinIO por {@code http://minio:9000}
 * (rede do compose), mas o celular precisa de uma URL no domínio público — por isso existe um
 * segundo cliente, apontado ao {@code publicEndpoint}, usado apenas para assinar.
 */
@Service
public class MinioMediaStorage implements MediaStorage {

    private static final Logger log = LoggerFactory.getLogger(MinioMediaStorage.class);

    /** O SDK exige um tamanho de parte quando o tamanho do objeto é desconhecido. */
    private static final long UNKNOWN_SIZE_PART = 10L * 1024 * 1024;

    private final MinioClient client;
    private final MinioClient presignClient;
    private final String bucket;
    private final AtomicBoolean bucketEnsured = new AtomicBoolean(false);

    public MinioMediaStorage(StorageProperties properties) {
        this.bucket = properties.bucket();
        this.client = build(properties, properties.endpoint());

        String publicEndpoint = properties.effectivePublicEndpoint();
        this.presignClient = publicEndpoint.equals(properties.endpoint())
                ? this.client
                : build(properties, publicEndpoint);
    }

    private static MinioClient build(StorageProperties properties, String endpoint) {
        return MinioClient.builder()
                .endpoint(endpoint)
                .credentials(properties.accessKey(), properties.secretKey())
                .build();
    }

    @Override
    public void upload(String key, InputStream content, long size, String contentType) {
        ensureBucket();
        try {
            client.putObject(PutObjectArgs.builder()
                    .bucket(bucket)
                    .object(key)
                    .stream(content, size >= 0 ? size : -1, size >= 0 ? -1 : UNKNOWN_SIZE_PART)
                    .contentType(contentType)
                    .build());
        } catch (Exception e) {
            throw new StorageException("Falha ao subir '%s' para o storage.".formatted(key), e);
        }
    }

    @Override
    public byte[] download(String key) {
        try (InputStream stream = client.getObject(
                GetObjectArgs.builder().bucket(bucket).object(key).build())) {
            return stream.readAllBytes();
        } catch (Exception e) {
            throw new StorageException("Falha ao baixar '%s' do storage.".formatted(key), e);
        }
    }

    @Override
    public void delete(String key) {
        try {
            client.removeObject(RemoveObjectArgs.builder().bucket(bucket).object(key).build());
        } catch (Exception e) {
            throw new StorageException("Falha ao apagar '%s' do storage.".formatted(key), e);
        }
    }

    @Override
    public String presignedUploadUrl(String key, String contentType, Duration expiry) {
        ensureBucket();
        try {
            return presignClient.getPresignedObjectUrl(GetPresignedObjectUrlArgs.builder()
                    .method(Method.PUT)
                    .bucket(bucket)
                    .object(key)
                    .expiry((int) expiry.toSeconds())
                    // O cliente precisa mandar exatamente este Content-Type no PUT.
                    .extraHeaders(Map.of("Content-Type", contentType))
                    .build());
        } catch (Exception e) {
            throw new StorageException("Falha ao assinar o upload de '%s'.".formatted(key), e);
        }
    }

    @Override
    public String presignedDownloadUrl(String key, Duration expiry) {
        try {
            return presignClient.getPresignedObjectUrl(GetPresignedObjectUrlArgs.builder()
                    .method(Method.GET)
                    .bucket(bucket)
                    .object(key)
                    .expiry((int) expiry.toSeconds())
                    .build());
        } catch (Exception e) {
            throw new StorageException("Falha ao assinar o download de '%s'.".formatted(key), e);
        }
    }

    @Override
    public StoredObjectInfo objectInfo(String key) {
        try {
            StatObjectResponse stat = client.statObject(
                    StatObjectArgs.builder().bucket(bucket).object(key).build());
            return new StoredObjectInfo(stat.size(), stat.contentType() == null ? "" : stat.contentType());
        } catch (ErrorResponseException e) {
            // Objeto ausente é resposta esperada (upload que não completou), não erro.
            if ("NoSuchKey".equals(e.errorResponse().code())) {
                return null;
            }
            throw new StorageException("Falha ao consultar '%s' no storage.".formatted(key), e);
        } catch (Exception e) {
            throw new StorageException("Falha ao consultar '%s' no storage.".formatted(key), e);
        }
    }

    /** Cria o bucket na primeira escrita; o MinIO do compose sobe vazio. */
    private void ensureBucket() {
        if (bucketEnsured.get()) {
            return;
        }
        try {
            boolean exists = client.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
            if (!exists) {
                client.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
                log.info("Bucket '{}' criado.", bucket);
            }
            bucketEnsured.set(true);
        } catch (Exception e) {
            throw new StorageException("Falha ao garantir o bucket '%s'.".formatted(bucket), e);
        }
    }

    /** Falha de storage é sempre transitória do ponto de vista do job: vale reprocessar. */
    public static class StorageException extends RuntimeException {

        public StorageException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
