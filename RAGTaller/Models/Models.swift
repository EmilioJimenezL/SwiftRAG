// Models.swift
// ══════════════════════════════════════════════════════════════
//  PASO 2 y 3 — Modelos SwiftData
//
//  ChunkDoc:    Un fragmento de texto de un PDF + su embedding
//  ConsultaLog: Historial de búsquedas del usuario
// ══════════════════════════════════════════════════════════════

import Foundation
import SwiftData

// MARK: ─── ChunkDoc ──────────────────────────────────────────
// Representa un "chunk" (fragmento) de texto extraído de un PDF.
// El campo `vector` guarda el embedding semántico en español.

@Model
final class ChunkDoc {
    var id: UUID
    var documentoNombre: String   // nombre del archivo PDF
    var pagina: Int               // número de página origen
    var chunkIndex: Int           // índice del chunk dentro del doc
    var texto: String             // texto plano del chunk
    var vector: [Float]           // embedding NLEmbedding (128 dimensiones)
    var fechaIndexado: Date

    init(documentoNombre: String, pagina: Int, chunkIndex: Int,
         texto: String, vector: [Float]) {
        self.id = UUID()
        self.documentoNombre = documentoNombre
        self.pagina = pagina
        self.chunkIndex = chunkIndex
        self.texto = texto
        self.vector = vector
        self.fechaIndexado = Date()
    }
}

// MARK: ─── ConsultaLog ───────────────────────────────────────
// Registra cada consulta RAG que hace el usuario.
// Esto alimenta el dashboard de Swift Charts.

@Model
final class ConsultaLog {
    var id: UUID
    var pregunta: String          // pregunta del usuario
    var respuesta: String         // respuesta generada
    var chunksUsados: Int         // cuántos chunks recuperó el RAG
    var scoreMaximo: Float        // similitud coseno del mejor chunk
    var duracionSegundos: Double  // tiempo total de la consulta
    var timestamp: Date

    init(pregunta: String, respuesta: String,
         chunksUsados: Int, scoreMaximo: Float, duracionSegundos: Double) {
        self.id = UUID()
        self.pregunta = pregunta
        self.respuesta = respuesta
        self.chunksUsados = chunksUsados
        self.scoreMaximo = scoreMaximo
        self.duracionSegundos = duracionSegundos
        self.timestamp = Date()
    }
}
