// ConsultarView.swift
// ══════════════════════════════════════════════════════════════
//  PASO 3 + 4 — RAG + FoundationModels
//
//  El participante aprende:
//  • Cómo se combina el RAG con el LLM
//  • Ver en tiempo real qué chunks recuperó el sistema
//  • Score de similitud por chunk
// ══════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

struct ConsultarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChunkDoc.documentoNombre) private var chunks: [ChunkDoc]

    @State private var agente: AgenteRH?
    @State private var mensajes: [Mensaje] = []
    @State private var inputTexto = ""
    @State private var procesando = false
    @State private var mostrarRAG = false
    @State private var ultimosResultados: [Recuperador.Resultado] = []

    // Preguntas de ejemplo para el taller
    private let preguntasEjemplo = [
        "¿Cuántos días de vacaciones me corresponden por ley?",
        "¿Qué es el IMSS y qué prestaciones cubre?",
        "¿Cuáles son mis derechos laborales?",
        "¿Qué pasa si me despiden sin causa justificada?",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Indicador de estado ───────────────────────
                EstadoRAGBar(
                    chunksDisponibles: chunks.count,
                    appleIntelligence: agente?.disponible ?? false,
                    onVerRAG: { mostrarRAG = true }
                )

                // ── Conversación ──────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if mensajes.isEmpty {
                                BienvenidaView(
                                    sinDocumentos: chunks.isEmpty,
                                    preguntas: preguntasEjemplo,
                                    onPregunta: { enviar($0) }
                                )
                                .padding()
                            }

                            ForEach(mensajes) { mensaje in
                                MensajeBubble(mensaje: mensaje)
                                    .id(mensaje.id)
                            }

                            if procesando {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: mensajes.count) { _, _ in
                        withAnimation {
                            if procesando {
                                proxy.scrollTo("typing")
                            } else {
                                proxy.scrollTo(mensajes.last?.id)
                            }
                        }
                    }
                }

                Divider()

                // ── Input ─────────────────────────────────────
                InputBar(
                    texto: $inputTexto,
                    procesando: procesando,
                    disabled: chunks.isEmpty
                ) {
                    enviar(inputTexto)
                }
            }
            .navigationTitle("Paso 3+4 — RAG")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        mostrarRAG = true
                    } label: {
                        Label("RAG Debug", systemImage: "magnifyingglass.circle")
                    }
                    .disabled(ultimosResultados.isEmpty)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpiar") {
                        mensajes = []
                        ultimosResultados = []
                    }
                    .disabled(mensajes.isEmpty)
                }
            }
            .sheet(isPresented: $mostrarRAG) {
                RAGDebugView(resultados: ultimosResultados)
            }
            .task {
                agente = AgenteRH(context: context)
            }
        }
    }

    // MARK: — Enviar mensaje

    private func enviar(_ texto: String) {
        let trimmed = texto.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !procesando else { return }

        inputTexto = ""
        mensajes.append(Mensaje(texto: trimmed, esUsuario: true))
        procesando = true

        Task {
            guard let agente else { return }
            let respuesta = await agente.consultar(pregunta: trimmed)

            await MainActor.run {
                ultimosResultados = respuesta.resultadosRAG
                mensajes.append(Mensaje(
                    texto: respuesta.texto,
                    esUsuario: false,
                    chunksUsados: respuesta.chunksUsados,
                    scoreMaximo: respuesta.scoreMaximo,
                    duracion: respuesta.duracion
                ))
                procesando = false
            }
        }
    }
}

// MARK: ─── Modelos de UI ─────────────────────────────────────

struct Mensaje: Identifiable {
    let id = UUID()
    let texto: String
    let esUsuario: Bool
    var chunksUsados: Int    = 0
    var scoreMaximo: Float   = 0
    var duracion: Double     = 0
    let timestamp = Date()
}

// MARK: ─── Subviews ──────────────────────────────────────────

struct EstadoRAGBar: View {
    let chunksDisponibles: Int
    let appleIntelligence: Bool
    let onVerRAG: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Circle()
                    .fill(chunksDisponibles > 0 ? .green : .red)
                    .frame(width: 8, height: 8)
                Text("\(chunksDisponibles) chunks")
                    .font(.caption)
            }

            HStack(spacing: 4) {
                Circle()
                    .fill(appleIntelligence ? .green : .orange)
                    .frame(width: 8, height: 8)
                Text(appleIntelligence ? "Apple Intelligence ✓" : "Modo Demo")
                    .font(.caption)
            }

            Spacer()

            Button("Ver RAG", action: onVerRAG)
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

struct BienvenidaView: View {
    let sinDocumentos: Bool
    let preguntas: [String]
    let onPregunta: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Asistente de RRHH")
                .font(.title2.bold())

            if sinDocumentos {
                Label("Primero indexa un PDF en la pestaña 'Indexar'",
                      systemImage: "arrow.left")
                .font(.callout)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
            } else {
                Text("Preguntas de ejemplo:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(preguntas, id: \.self) { pregunta in
                    Button {
                        onPregunta(pregunta)
                    } label: {
                        Text(pregunta)
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.blue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }
}

struct MensajeBubble: View {
    let mensaje: Mensaje

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if mensaje.esUsuario { Spacer(minLength: 60) }

            VStack(alignment: mensaje.esUsuario ? .trailing : .leading, spacing: 4) {
                Text(mensaje.texto)
                    .padding(12)
                    .background(mensaje.esUsuario ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(mensaje.esUsuario ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Metadata RAG solo en respuestas del agente
                if !mensaje.esUsuario && mensaje.chunksUsados > 0 {
                    HStack(spacing: 8) {
                        Label("\(mensaje.chunksUsados) chunks", systemImage: "doc.text")
                        Text("·")
                        Label(String(format: "score %.2f", mensaje.scoreMaximo),
                              systemImage: "arrow.up.right.circle")
                        Text("·")
                        Label(String(format: "%.1fs", mensaje.duracion),
                              systemImage: "clock")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            if !mensaje.esUsuario { Spacer(minLength: 60) }
        }
    }
}

struct TypingIndicator: View {
    @State private var animar = false

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animar ? 1.3 : 0.7)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: animar
                        )
                }
            }
            .padding(12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .onAppear { animar = true }
    }
}

struct InputBar: View {
    @Binding var texto: String
    let procesando: Bool
    let disabled: Bool
    let onEnviar: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Escribe tu pregunta...", text: $texto, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(disabled || procesando)
                .onSubmit { if !texto.isEmpty { onEnviar() } }

            Button(action: onEnviar) {
                Image(systemName: procesando ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(texto.isEmpty || disabled ? Color.secondary : Color.blue)
            }
            .disabled(texto.isEmpty || procesando || disabled)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.regularMaterial)

        if disabled {
            Text("⚠️ Indexa un PDF primero para poder consultar")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.bottom, 4)
        }
    }
}

// MARK: ─── RAG Debug View ────────────────────────────────────

struct RAGDebugView: View {
    let resultados: [Recuperador.Resultado]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    EducationCard(
                        paso: "3",
                        titulo: "Cómo funciona el RAG",
                        descripcion: """
                        1. Tu pregunta se vectoriza con NLEmbedding
                        2. Se calcula similitud coseno con todos los chunks
                        3. Los top-4 más similares forman el contexto
                        4. FoundationModels genera la respuesta con ese contexto
                        """,
                        color: .green
                    )
                } header: { Text("Concepto") }

                Section {
                    if resultados.isEmpty {
                        Text("Haz una consulta primero")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(resultados.enumerated()), id: \.offset) { i, resultado in
                            RAGResultadoRow(rank: i + 1, resultado: resultado)
                        }
                    }
                } header: { Text("Chunks recuperados (última consulta)") }
            }
            .navigationTitle("RAG Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

struct RAGResultadoRow: View {
    let rank: Int
    let resultado: Recuperador.Resultado

    private var colorScore: Color {
        switch resultado.score {
        case 0.7...: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(rank)")
                    .font(.caption.bold())
                    .padding(4)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(resultado.chunk.documentoNombre)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%.3f", resultado.score))
                    .font(.caption.bold())
                    .foregroundStyle(colorScore)
            }

            // Barra de similitud visual
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorScore)
                        .frame(width: geo.size.width * CGFloat(resultado.score), height: 6)
                }
            }
            .frame(height: 6)

            Text(resultado.chunk.texto)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}
