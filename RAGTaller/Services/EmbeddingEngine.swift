// EmbeddingEngine.swift
// ══════════════════════════════════════════════════════════════
//  PASO 2 — NaturalLanguage Embeddings
//
//  Aprendemos:
//  • NLEmbedding.sentenceEmbedding(for: .spanish)
//  • Transformar texto → vector de 128 Float
//  • Partir texto largo en "chunks" (fragmentos manejables)
//  • Similitud coseno con Accelerate/vDSP
//
//  CONCEPTOS CLAVE:
//  Un embedding es una representación matemática del SIGNIFICADO
//  de un texto. Textos similares tienen vectores "cercanos".
//
//  "vacaciones" ≈ "días de descanso"  →  vectores muy parecidos
//  "vacaciones" ≈ "impuestos"         →  vectores muy diferentes
// ══════════════════════════════════════════════════════════════

import NaturalLanguage
import Accelerate
import Foundation

// MARK: ─── TextChunker ───────────────────────────────────────

struct TextChunker {
    /// Máximo de palabras por chunk (balance: contexto vs precisión)
    static let maxPalabras = 250

    // ─────────────────────────────────────────────────────────
    // Divide texto largo en fragmentos de ~250 palabras
    // respetando límites de oraciones (NLTokenizer).
    // ─────────────────────────────────────────────────────────
    static func chunkear(texto: String, pagina: Int,
                         documentoNombre: String) -> [(texto: String, indice: Int)] {

        // TODO [PASO 2.1]: Crear el tokenizador por oraciones
        // Pista: NLTokenizer(unit: .sentence), luego tokenizer.string = texto
        let tokenizador = NLTokenizer(unit: .sentence)
        tokenizador.string = texto

        var chunks:  [(String, Int)] = []
        var buffer   = ""
        var nPalabras = 0
        var indice   = 0

        // TODO [PASO 2.2]: Enumerar las oraciones y agruparlas
        tokenizador.enumerateTokens(in: texto.startIndex..<texto.endIndex) { rango, _ in
            let oracion   = String(texto[rango]).trimmingCharacters(in: .whitespaces)
            guard !oracion.isEmpty else { return true }

            let palabras  = oracion.split(separator: " ").count

            if nPalabras + palabras > Self.maxPalabras, !buffer.isEmpty {
                // El buffer está lleno → guardar chunk y empezar nuevo
                chunks.append((buffer.trimmingCharacters(in: .whitespaces), indice))
                indice   += 1
                buffer    = oracion
                nPalabras = palabras
            } else {
                buffer    += (buffer.isEmpty ? "" : " ") + oracion
                nPalabras += palabras
            }
            return true   // continuar enumerando
        }

        if !buffer.isEmpty {
            chunks.append((buffer.trimmingCharacters(in: .whitespaces), indice))
        }

        return chunks
    }
}

// MARK: ─── EmbeddingEngine ───────────────────────────────────

struct EmbeddingEngine {

    // El modelo de embeddings en español — se carga una sola vez
    // y corre 100% on-device, sin internet.
    static let modelo: NLEmbedding? = NLEmbedding.sentenceEmbedding(for: .spanish)

    // ─────────────────────────────────────────────────────────
    // Convierte un texto en su vector semántico.
    // Retorna nil si el modelo no está disponible.
    // ─────────────────────────────────────────────────────────
    static func vectorizar(texto: String) -> [Float]? {
        // TODO [PASO 2.3]: Obtener el vector del texto
        // Pista: modelo?.vector(for: texto) regresa [Double]?
        //        conviértelo a [Float] con .map { Float($0) }
        guard let modelo,
              let vectorDouble = modelo.vector(for: texto) else { return nil }

        return vectorDouble.map { Float($0) }
    }

    // ─────────────────────────────────────────────────────────
    // Similitud coseno entre dos vectores (rango: 0.0 – 1.0)
    //
    // Fórmula:  cos(θ) = (A · B) / (|A| × |B|)
    //
    // Usamos vDSP de Accelerate para hacerlo muy rápido.
    // ─────────────────────────────────────────────────────────
    static func similitudCoseno(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var productoPunto: Float = 0
        var normA: Float         = 0
        var normB: Float         = 0

        // vDSP_dotpr: producto punto  A · B
        vDSP_dotpr(a, 1, b, 1, &productoPunto, vDSP_Length(a.count))
        // vDSP_svesq: suma de cuadrados → norma²
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))

        let denominador = sqrt(normA) * sqrt(normB)
        return denominador > 0 ? productoPunto / denominador : 0
    }
}
