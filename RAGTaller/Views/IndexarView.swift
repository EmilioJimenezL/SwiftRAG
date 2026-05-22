// IndexarView.swift
// ══════════════════════════════════════════════════════════════
//  PASO 1 y 3 — Interfaz de indexación de PDFs
//
//  El participante aprende:
//  • DocumentPickerView para seleccionar PDFs
//  • Progreso de indexación en tiempo real
//  • Ver los chunks generados en SwiftData
// ══════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct IndexarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChunkDoc.documentoNombre) private var chunks: [ChunkDoc]

    @State private var mostrarpicker      = false
    @State private var indexando          = false
    @State private var mensajeEstado      = ""
    @State private var mostrarChunks      = false
    @State private var chunkSeleccionado: ChunkDoc?

    // Documentos únicos ya indexados
    private var documentos: [String] {
        Array(Set(chunks.map(\.documentoNombre))).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Estado del modelo de embeddings ──────────
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: EmbeddingEngine.modelo != nil
                              ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundStyle(EmbeddingEngine.modelo != nil ? .green : .red)
                        .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Modelo NLEmbedding Español")
                                .font(.headline)
                            Text(EmbeddingEngine.modelo != nil
                                 ? "Disponible on-device ✓"
                                 : "No disponible — requiere iOS 17+")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Motor de Embeddings") }

                // ── Documentos indexados ──────────────────────
                Section {
                    if documentos.isEmpty {
                        ContentUnavailableView(
                            "Sin documentos",
                            systemImage: "doc.badge.plus",
                            description: Text("Toca '+' para indexar tu primer PDF")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(documentos, id: \.self) { doc in
                            let chunksDelDoc = chunks.filter { $0.documentoNombre == doc }
                            DocumentoRow(nombre: doc, numChunks: chunksDelDoc.count) {
                                chunkSeleccionado = nil
                                mostrarChunks = true
                            }
                        }
                        .onDelete(perform: eliminarDocumento)
                    }
                } header: {
                    HStack {
                        Text("Documentos Indexados (\(documentos.count))")
                        Spacer()
                        Text("\(chunks.count) chunks totales")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // ── Progreso y estado ─────────────────────────
                if indexando || !mensajeEstado.isEmpty {
                    Section {
                        HStack(spacing: 12) {
                            if indexando {
                                ProgressView()
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            Text(mensajeEstado)
                                .font(.callout)
                        }
                        .padding(.vertical, 4)
                    } header: { Text("Estado") }
                }

                // ── Explicación educativa ─────────────────────
                Section {
                    EducationCard(
                        paso: "1",
                        titulo: "¿Qué hace PDFKit?",
                        descripcion: """
                        PDFDocument carga el archivo.
                        PDFPage.string extrae el texto de cada página.
                        Luego NLTokenizer divide el texto en oraciones
                        y las agrupa en chunks de ~250 palabras.
                        """,
                        color: .blue
                    )
                } header: { Text("Concepto") }
            }
            .navigationTitle("Paso 1 — Indexar PDF")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        mostrarpicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(indexando)
                }
            }
            .fileImporter(
                isPresented: $mostrarpicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { resultado in
                Task { await procesarSeleccion(resultado) }
            }
            .sheet(isPresented: $mostrarChunks) {
                ChunksListView(chunks: chunks)
            }
        }
    }

    // MARK: — Lógica

    private func procesarSeleccion(_ resultado: Result<[URL], Error>) async {
        switch resultado {
        case .failure(let error):
            mensajeEstado = "Error: \(error.localizedDescription)"

        case .success(let urls):
            guard let url = urls.first else { return }

            // Acceder al archivo con security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                mensajeEstado = "Sin permiso para acceder al archivo"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            indexando     = true
            mensajeEstado = "Indexando \(url.lastPathComponent)..."

            do {
                let indexador = Indexador(context: context)
                let total     = try await indexador.indexar(url: url)
                mensajeEstado = "✓ \(url.lastPathComponent) — \(total) chunks creados"
            } catch {
                mensajeEstado = "Error: \(error.localizedDescription)"
            }

            indexando = false
        }
    }

    private func eliminarDocumento(at offsets: IndexSet) {
        for index in offsets {
            let nombre = documentos[index]
            chunks.filter { $0.documentoNombre == nombre }
                  .forEach { context.delete($0) }
        }
        try? context.save()
    }
}

// MARK: ─── Subviews ──────────────────────────────────────────

struct DocumentoRow: View {
    let nombre: String
    let numChunks: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(nombre)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(numChunks) chunks indexados")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct ChunksListView: View {
    let chunks: [ChunkDoc]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(chunks) { chunk in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("p.\(chunk.pagina) chunk \(chunk.chunkIndex)",
                              systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(chunk.vector.count)d")
                            .font(.caption2)
                            .padding(4)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Text(chunk.texto)
                        .font(.caption)
                        .lineLimit(3)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Chunks (\(chunks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
