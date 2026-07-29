package com.myotrack.infrastructure.ai;

import java.awt.AlphaComposite;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;
import javax.imageio.ImageIO;

/**
 * Desenha as anotações da análise sobre a própria foto da refeição.
 *
 * <p>É o caminho <b>local e gratuito</b> da análise ilustrada. O modelo de imagem do Gemini
 * faz melhor, mas exige chave com billing e no tier gratuito tem cota zero — sem este
 * fallback, a funcionalidade quase nunca funcionaria de verdade.
 *
 * <p>Usa só Java2D, que vem no JDK: uma biblioteca de imagem a mais no servidor seria peso
 * para desenhar meia dúzia de retângulos e textos.
 */
public final class MealImageAnnotator {

    /** Escala em que o modelo devolve as posições. */
    private static final int POSITION_SCALE = 1000;

    /** Lado maior da imagem gerada — acima disso é peso sem ganho de leitura. */
    private static final int MAX_DIMENSION = 1400;

    private static final Color LABEL_BACKGROUND = new Color(0, 0, 0, 190);
    private static final Color CARD_BACKGROUND = new Color(15, 60, 45, 225);
    private static final Color TEXT = Color.WHITE;

    private MealImageAnnotator() {
    }

    /**
     * Uma etiqueta a desenhar.
     *
     * @param posX centro do alimento, escala 0–1000; null quando o modelo não soube dizer
     */
    public record Annotation(String text, Integer posX, Integer posY) {
    }

    /**
     * Devolve a foto anotada, em JPEG.
     *
     * @throws IOException quando a imagem não pode ser lida ou escrita — o chamador trata
     *     como "sem versão ilustrada", nunca como falha da análise
     */
    public static byte[] render(byte[] photo, List<Annotation> annotations, String totals)
            throws IOException {

        final BufferedImage source = ImageIO.read(new ByteArrayInputStream(photo));
        if (source == null) {
            throw new IOException("Formato de imagem não suportado pelo renderizador.");
        }

        final BufferedImage image = downscale(source);
        final Graphics2D g = image.createGraphics();
        try {
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(
                    RenderingHints.KEY_TEXT_ANTIALIASING,
                    RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

            // A fonte acompanha o tamanho da imagem: tamanho fixo ficaria ilegível numa foto
            // grande e cobriria o prato inteiro numa pequena.
            final int base = Math.max(12, image.getWidth() / 42);
            drawLabels(g, image, annotations, base);
            drawTotals(g, image, totals, base);
        } finally {
            g.dispose();
        }

        final ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }

    private static void drawLabels(
            Graphics2D g, BufferedImage image, List<Annotation> annotations, int base) {

        g.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, base));
        final int lineHeight = g.getFontMetrics().getHeight();
        final int padding = base / 2;

        // Etiquetas sem posição empilham no topo à esquerda, em vez de sumirem: o texto
        // ainda informa, mesmo sem apontar para o lugar certo.
        int stackedY = padding;

        for (final Annotation annotation : annotations) {
            if (annotation.text() == null || annotation.text().isBlank()) {
                continue;
            }

            final int width = g.getFontMetrics().stringWidth(annotation.text()) + padding * 2;
            final int height = lineHeight + padding;

            final int x;
            final int y;
            if (annotation.posX() != null && annotation.posY() != null) {
                x = scale(annotation.posX(), image.getWidth()) - width / 2;
                y = scale(annotation.posY(), image.getHeight()) - height / 2;
            } else {
                x = padding;
                y = stackedY;
                stackedY += height + padding / 2;
            }

            drawBox(g, clamp(x, image.getWidth() - width), clamp(y, image.getHeight() - height),
                    width, height, LABEL_BACKGROUND, annotation.text(), base, padding);
        }
    }

    /** Cartão com os totais, no rodapé — é o número que a pessoa leva do prato. */
    private static void drawTotals(
            Graphics2D g, BufferedImage image, String totals, int base) {

        if (totals == null || totals.isBlank()) {
            return;
        }

        g.setFont(new Font(Font.SANS_SERIF, Font.BOLD, (int) (base * 1.15)));
        final int padding = base;
        final int width = Math.min(
                g.getFontMetrics().stringWidth(totals) + padding * 2, image.getWidth() - padding);
        final int height = g.getFontMetrics().getHeight() + padding;

        drawBox(g,
                (image.getWidth() - width) / 2,
                image.getHeight() - height - padding,
                width, height, CARD_BACKGROUND, totals, (int) (base * 1.15), padding);
    }

    private static void drawBox(
            Graphics2D g, int x, int y, int width, int height,
            Color background, String text, int fontSize, int padding) {

        g.setComposite(AlphaComposite.SrcOver);
        g.setColor(background);
        g.fillRoundRect(x, y, width, height, height / 2, height / 2);

        g.setColor(new Color(255, 255, 255, 60));
        g.setStroke(new BasicStroke(1f));
        g.drawRoundRect(x, y, width, height, height / 2, height / 2);

        g.setColor(TEXT);
        g.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, fontSize));
        final int baseline = y + (height + g.getFontMetrics().getAscent()
                - g.getFontMetrics().getDescent()) / 2;
        g.drawString(text, x + padding, baseline);
    }

    /** Reduz imagens grandes; as pequenas passam intactas. */
    private static BufferedImage downscale(BufferedImage source) {
        final int longest = Math.max(source.getWidth(), source.getHeight());
        final double factor = longest > MAX_DIMENSION ? (double) MAX_DIMENSION / longest : 1;

        final int width = Math.max(1, (int) Math.round(source.getWidth() * factor));
        final int height = Math.max(1, (int) Math.round(source.getHeight() * factor));

        // TYPE_INT_RGB sempre: a foto pode vir com canal alfa, e JPEG não o suporta — sem
        // isto o ImageIO.write devolve uma imagem com as cores trocadas.
        final BufferedImage target = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        final Graphics2D g = target.createGraphics();
        try {
            g.setRenderingHint(
                    RenderingHints.KEY_INTERPOLATION,
                    RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.drawImage(source, 0, 0, width, height, null);
        } finally {
            g.dispose();
        }
        return target;
    }

    private static int scale(int position, int size) {
        return (int) Math.round((double) position / POSITION_SCALE * size);
    }

    private static int clamp(int value, int max) {
        return Math.max(0, Math.min(value, Math.max(0, max)));
    }
}
