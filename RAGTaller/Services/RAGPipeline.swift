// RAGPipeline.swift
// ══════════════════════════════════════════════════════════════
//  PASO 3 — Pipeline RAG con SwiftData
//
//  Aprendemos:
//  • Guardar chunks+vectores en SwiftData (@Model)
//  • Recuperar chunks con FetchDescriptor
//  • Calcular similitud coseno para ranking semántico
//  • El patrón RAG: Retrieve → Augment → Generate
//
//  RAG = Retrieval-Augmented Generation
//  ┌──────────┐   ┌──────────────┐   ┌─────────────────┐
//  │ Pregunta │──▶│ Recuperar    │──▶│ FoundationModels│
//  │ usuario  │   │ chunks       │   │ (con contexto)  │
//  └──────────┘   │ relevantes   │   └─────────────────┘
//                 └──────────────┘
// ══════════════════════════════════════════════════════════════

import Foundation
import SwiftData
import NaturalLanguage

// MARK: ─── Indexador ─────────────────────────────────────────
// Procesa un PDF y lo guarda en SwiftData como chunks+vectores.

@MainActor
final class Indexador {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // ─────────────────────────────────────────────────────────
    // Indexa un PDF completo:
    //  1. Extrae texto por página (PDFKit)
    //  2. Divide en chunks (NLTokenizer)
    //  3. Genera embedding por chunk (NLEmbedding)
    //  4. Persiste en SwiftData
    // ─────────────────────────────────────────────────────────
    func indexar(url: URL) async throws -> Int {
        let nombre = url.lastPathComponent

        // Evitar re-indexar si ya existe
        let descriptor = FetchDescriptor<ChunkDoc>(
            predicate: #Predicate { $0.documentoNombre == nombre }
        )
        if let existentes = try? context.fetch(descriptor), !existentes.isEmpty {
            return existentes.count   // ya indexado
        }

        // TODO [PASO 3.1]: Extraer páginas del PDF
        let paginas = try PDFExtractor.extraer(url: url)

        var totalChunks = 0

        for (numeroPagina, textoPagina) in paginas {
            // TODO [PASO 3.2]: Dividir la página en chunks
            let chunks = TextChunker.chunkear(
                texto: textoPagina,
                pagina: numeroPagina,
                documentoNombre: nombre
            )

            for (textoChunk, indice) in chunks {
                // TODO [PASO 3.3]: Generar el embedding del chunk
                // Pista: EmbeddingEngine.vectorizar(texto:)
                guard let vector = EmbeddingEngine.vectorizar(texto: textoChunk) else {
                    continue   // si falla el embedding, saltar este chunk
                }

                // TODO [PASO 3.4]: Crear y guardar el ChunkDoc en SwiftData
                let chunk = ChunkDoc(
                    documentoNombre: nombre,
                    pagina: numeroPagina,
                    chunkIndex: indice,
                    texto: textoChunk,
                    vector: vector
                )
                context.insert(chunk)
                totalChunks += 1
            }
        }

        try context.save()
        return totalChunks
    }
}

// MARK: ─── Recuperador ───────────────────────────────────────
// Busca los chunks más relevantes para una consulta dada.

@MainActor
final class Recuperador {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    struct Resultado: Identifiable {
        let id = UUID()
        let chunk: ChunkDoc
        let score: Float      // similitud coseno (0–1)
    }

    // ─────────────────────────────────────────────────────────
    // Recupera los `topK` chunks más similares a la consulta.
    //
    //  1. Vectorizar la consulta
    //  2. Traer todos los chunks de SwiftData
    //  3. Calcular similitud coseno con cada chunk
    //  4. Ordenar de mayor a menor y tomar los top K
    // ─────────────────────────────────────────────────────────
    func recuperar(consulta: String, topK: Int = 4) throws -> [Resultado] {

        // TODO [PASO 3.5]: Vectorizar la consulta del usuario
        guard let vectorConsulta = EmbeddingEngine.vectorizar(texto: consulta) else {
            return []
        }

        // TODO [PASO 3.6]: Obtener todos los chunks de SwiftData
        let todosLosChunks = try context.fetch(FetchDescriptor<ChunkDoc>())
        guard !todosLosChunks.isEmpty else { return [] }

        // TODO [PASO 3.7]: Calcular similitud coseno y ordenar
        let rankeados = todosLosChunks
            .map { chunk in
                Resultado(chunk: chunk,
                          score: EmbeddingEngine.similitudCoseno(vectorConsulta, chunk.vector))
            }
            .sorted { $0.score > $1.score }   // mayor similitud primero

        return Array(rankeados.prefix(topK))
    }
}
