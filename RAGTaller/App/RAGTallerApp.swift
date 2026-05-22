// RAGTallerApp.swift
// ══════════════════════════════════════════════════════════════
//  IA on-device: PDFKit, Embeddings y RAG con Swift
//  Taller de 1 hora — Apple Education
// ══════════════════════════════════════════════════════════════
//
//  REQUISITOS:
//  • iPhone 16 Pro Max o superior (iOS 18+)
//  • Xcode 16+
//  • NO requiere conexión a internet
//
//  ARQUITECTURA DEL TALLER (4 pasos):
//
//  PASO 1 — PDFKit:         Extraer texto de PDFs
//  PASO 2 — Embeddings:     NLEmbedding.sentenceEmbedding(.spanish)
//  PASO 3 — SwiftData RAG:  Guardar chunks + búsqueda coseno
//  PASO 4 — Dashboard:      Swift Charts + FoundationModels
//
// ══════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

@main
struct RAGTallerApp: App {

    // ┌─────────────────────────────────────────────────────────┐
    // │  SwiftData container — el "cerebro" local de la app     │
    // └─────────────────────────────────────────────────────────┘
    static let container: ModelContainer = {
        let schema = Schema([ChunkDoc.self, ConsultaLog.self])
        let config = ModelConfiguration("rag-taller", schema: schema)
        // En producción usa try/catch — aquí mantenemos simple para el taller
        return try! ModelContainer(for: schema, configurations: config)
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(Self.container)
        }
    }
}
