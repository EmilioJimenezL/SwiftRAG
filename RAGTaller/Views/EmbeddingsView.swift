// EmbeddingsView.swift
// ══════════════════════════════════════════════════════════════
//  PASO 2 — Explorador de Embeddings
//
//  El participante puede:
//  • Escribir dos textos y ver su similitud coseno en tiempo real
//  • Ver el vector resultante (primeras 10 dimensiones)
//  • Entender visualmente por qué "vacaciones" ≈ "días de descanso"
// ══════════════════════════════════════════════════════════════

import SwiftUI
import Charts

struct EmbeddingsView: View {
    @State private var textoA = "días de vacaciones anuales"
    @State private var textoB = "tiempo libre por ley"
    @State private var similitud: Float = 0
    @State private var vectorA: [Float] = []
    @State private var vectorB: [Float] = []
    @State private var calculando = false

    // Pares de ejemplo para demostrar el concepto
    private let ejemplos: [(String, String)] = [
        ("días de vacaciones anuales", "tiempo libre por ley"),
        ("mi salario mensual", "cuánto gano al mes"),
        ("vacaciones", "impuestos"),
        ("prestaciones sociales", "IMSS e INFONAVIT"),
        ("acoso laboral", "receta de cocina"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Indicador de similitud ─────────────────
                    SimilitudGauge(similitud: similitud)
                        .padding(.horizontal)

                    // ── Inputs ────────────────────────────────
                    VStack(spacing: 12) {
                        TextoEmbeddingCard(
                            etiqueta: "Texto A",
                            color: .blue,
                            texto: $textoA
                        )
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(.secondary)
                        TextoEmbeddingCard(
                            etiqueta: "Texto B",
                            color: .purple,
                            texto: $textoB
                        )
                    }
                    .padding(.horizontal)

                    // ── Botón calcular ────────────────────────
                    Button {
                        Task { await calcular() }
                    } label: {
                        HStack {
                            if calculando {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "function")
                            }
                            Text(calculando ? "Calculando..." : "Calcular Similitud")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(calculando || textoA.isEmpty || textoB.isEmpty)
                    .padding(.horizontal)

                    // ── Vectores ──────────────────────────────
                    if !vectorA.isEmpty {
                        VectorPreviewChart(
                            vectorA: Array(vectorA.prefix(12)),
                            vectorB: Array(vectorB.prefix(12))
                        )
                        .padding(.horizontal)
                    }

                    // ── Ejemplos ──────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prueba estos pares")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(ejemplos.enumerated()), id: \.offset) { _, par in
                                    EjemploChip(a: par.0, b: par.1) {
                                        textoA = par.0
                                        textoB = par.1
                                        Task { await calcular() }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // ── Explicación ───────────────────────────
                    EducationCard(
                        paso: "2",
                        titulo: "¿Qué son los embeddings?",
                        descripcion: """
                        NLEmbedding convierte texto en un vector de 128 números.
                        La similitud coseno mide el ángulo entre dos vectores:
                        • 1.0 = textos idénticos en significado
                        • 0.0 = textos sin relación semántica
                        
                        El modelo corre 100% on-device, sin internet.
                        """,
                        color: .purple
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Paso 2 — Embeddings")
            .task { await calcular() }
        }
    }

    private func calcular() async {
        guard !textoA.isEmpty, !textoB.isEmpty else { return }
        calculando = true

        await Task.detached(priority: .userInitiated) {
            let a = EmbeddingEngine.vectorizar(texto: textoA) ?? []
            let b = EmbeddingEngine.vectorizar(texto: textoB) ?? []
            let s = EmbeddingEngine.similitudCoseno(a, b)
            await MainActor.run {
                vectorA = a
                vectorB = b
                similitud = s
                calculando = false
            }
        }.value
    }
}

// MARK: ─── Subviews ──────────────────────────────────────────

struct SimilitudGauge: View {
    let similitud: Float

    private var color: Color {
        switch similitud {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    private var etiqueta: String {
        switch similitud {
        case 0.8...: return "Muy similar"
        case 0.5..<0.8: return "Relacionado"
        case 0.2..<0.5: return "Poco relacionado"
        default: return "Sin relación"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Gauge(value: Double(similitud), in: 0...1) {
                EmptyView()
            } currentValueLabel: {
                Text(String(format: "%.3f", similitud))
                    .font(.title.bold())
                    .foregroundStyle(color)
            }
            .gaugeStyle(.accessoryCircular)
            .scaleEffect(2.0)
            .frame(height: 110)

            Text(etiqueta)
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.spring, value: similitud)
    }
}

struct TextoEmbeddingCard: View {
    let etiqueta: String
    let color: Color
    @Binding var texto: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(etiqueta, systemImage: "textformat")
                .font(.caption.bold())
                .foregroundStyle(color)
            TextField("Escribe texto...", text: $texto, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }
}

struct VectorPreviewChart: View {
    let vectorA: [Float]
    let vectorB: [Float]

    struct PuntoVector: Identifiable {
        let id = UUID()
        let dimension: Int
        let valor: Double
        let serie: String
    }

    private var datos: [PuntoVector] {
        vectorA.enumerated().map { PuntoVector(dimension: $0.offset, valor: Double($0.element), serie: "A") } +
        vectorB.enumerated().map { PuntoVector(dimension: $0.offset, valor: Double($0.element), serie: "B") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Primeras 12 dimensiones del vector")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Chart(datos) { punto in
                BarMark(
                    x: .value("Dim", punto.dimension),
                    y: .value("Valor", punto.valor)
                )
                .foregroundStyle(by: .value("Texto", punto.serie))
            }
            .chartForegroundStyleScale(["A": Color.blue, "B": Color.purple])
            .frame(height: 160)
            .chartLegend(position: .top, alignment: .trailing)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EjemploChip: View {
    let a: String
    let b: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(a).lineLimit(1)
                Text("≈")
                Text(b).lineLimit(1)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
