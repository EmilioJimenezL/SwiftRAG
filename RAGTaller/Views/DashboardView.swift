// DashboardView.swift
// ══════════════════════════════════════════════════════════════
//  PASO 4 — Dashboard con Swift Charts
//
//  El participante aprende:
//  • Swift Charts: BarMark, LineMark, PointMark, SectorMark
//  • @Query de SwiftData en tiempo real
//  • Agregar y transformar datos para visualización
// ══════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \ConsultaLog.timestamp, order: .reverse) private var logs: [ConsultaLog]
    @Query private var chunks: [ChunkDoc]

    private var documentos: [String] {
        Array(Set(chunks.map(\.documentoNombre))).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if logs.isEmpty {
                    DashboardVacioView()
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 20) {
                        // ── KPI Cards ─────────────────────────
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            KPICard(
                                titulo: "Consultas",
                                valor: "\(logs.count)",
                                icono: "bubble.left.and.bubble.right",
                                color: .blue
                            )
                            KPICard(
                                titulo: "Docs Indexados",
                                valor: "\(documentos.count)",
                                icono: "doc.fill",
                                color: .green
                            )
                            KPICard(
                                titulo: "Score Promedio",
                                valor: String(format: "%.2f", scorePromedio),
                                icono: "chart.bar.fill",
                                color: .orange
                            )
                            KPICard(
                                titulo: "Tiempo Prom.",
                                valor: String(format: "%.1fs", tiempoPromedio),
                                icono: "clock.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)

                        // ── Gráfica de consultas por hora ─────
                        ConsultasPorHoraChart(logs: logs)
                            .padding(.horizontal)

                        // ── Distribución de scores ─────────────
                        ScoreDistribucionChart(logs: logs)
                            .padding(.horizontal)

                        // ── Chunks usados ─────────────────────
                        ChunksUsadosChart(logs: logs)
                            .padding(.horizontal)

                        // ── Historial ─────────────────────────
                        HistorialSection(logs: Array(logs.prefix(10)))
                            .padding(.horizontal)

                        // ── Tarjeta educativa ─────────────────
                        EducationCard(
                            paso: "4",
                            titulo: "Swift Charts en acción",
                            descripcion: """
                            Cada gráfica usa @Query de SwiftData — se actualiza
                            automáticamente cuando haces nuevas consultas.
                            BarMark, LineMark, SectorMark y PointMark son
                            los bloques básicos de Swift Charts.
                            """,
                            color: .orange
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Paso 4 — Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        // Limpiar historial (solo para el taller)
                    } label: {
                        Label("Limpiar", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var scorePromedio: Double {
        guard !logs.isEmpty else { return 0 }
        return logs.reduce(0.0) { $0 + Double($1.scoreMaximo) } / Double(logs.count)
    }

    private var tiempoPromedio: Double {
        guard !logs.isEmpty else { return 0 }
        return logs.reduce(0.0) { $0 + $1.duracionSegundos } / Double(logs.count)
    }
}

// MARK: ─── KPI Card ──────────────────────────────────────────

struct KPICard: View {
    let titulo: String
    let valor: String
    let icono: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icono)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(valor)
                .font(.title.bold())
            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: ─── Gráfica 1: Consultas por hora ─────────────────────

struct ConsultasPorHoraChart: View {
    let logs: [ConsultaLog]

    struct PorHora: Identifiable {
        let id = UUID()
        let hora: String
        let conteo: Int
    }

    private var datos: [PorHora] {
        let calendar = Calendar.current
        var conteos: [Int: Int] = [:]
        for log in logs {
            let hora = calendar.component(.hour, from: log.timestamp)
            conteos[hora, default: 0] += 1
        }
        return conteos.map {
            PorHora(hora: String(format: "%02d:00", $0.key), conteo: $0.value)
        }.sorted { $0.hora < $1.hora }
    }

    var body: some View {
        ChartCard(titulo: "Consultas por hora", icono: "clock") {
            Chart(datos) { punto in
                // TODO [PASO 4.6]: Agregar BarMark para consultas por hora
                BarMark(
                    x: .value("Hora", punto.hora),
                    y: .value("Consultas", punto.conteo)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) {
                    AxisValueLabel().font(.caption2)
                }
            }
        }
    }
}

// MARK: ─── Gráfica 2: Distribución de scores ─────────────────

struct ScoreDistribucionChart: View {
    let logs: [ConsultaLog]

    struct Segmento: Identifiable {
        let id = UUID()
        let etiqueta: String
        let conteo: Int
        let color: Color
    }

    private var segmentos: [Segmento] {
        let alto  = logs.filter { $0.scoreMaximo >= 0.7 }.count
        let medio = logs.filter { $0.scoreMaximo >= 0.4 && $0.scoreMaximo < 0.7 }.count
        let bajo  = logs.filter { $0.scoreMaximo < 0.4 }.count
        return [
            Segmento(etiqueta: "Alto (≥0.7)", conteo: alto, color: .green),
            Segmento(etiqueta: "Medio",       conteo: medio, color: .orange),
            Segmento(etiqueta: "Bajo (<0.4)", conteo: bajo,  color: .red),
        ].filter { $0.conteo > 0 }
    }

    var body: some View {
        ChartCard(titulo: "Score RAG", icono: "chart.pie") {
            Chart(segmentos) { seg in
                // TODO [PASO 4.7]: SectorMark para donut chart
                SectorMark(
                    angle: .value("Consultas", seg.conteo),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(seg.color)
                .annotation(position: .overlay) {
                    if seg.conteo > 0 {
                        Text("\(seg.conteo)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 180)
            .chartLegend(position: .trailing)
        }
    }
}

// MARK: ─── Gráfica 3: Chunks usados por consulta ─────────────

struct ChunksUsadosChart: View {
    let logs: [ConsultaLog]

    var body: some View {
        ChartCard(titulo: "Chunks recuperados por consulta", icono: "doc.text") {
            Chart(Array(logs.prefix(20).enumerated()), id: \.offset) { i, log in
                // TODO [PASO 4.8]: PointMark para scatter plot
                PointMark(
                    x: .value("Consulta", i + 1),
                    y: .value("Chunks", log.chunksUsados)
                )
                .foregroundStyle(by: .value("Score", scoreCategoria(log.scoreMaximo)))
                LineMark(
                    x: .value("Consulta", i + 1),
                    y: .value("Chunks", log.chunksUsados)
                )
                .foregroundStyle(.blue.opacity(0.3))
                .interpolationMethod(.catmullRom)
            }
            .chartForegroundStyleScale([
                "Alto": Color.green,
                "Medio": Color.orange,
                "Bajo": Color.red
            ])
            .frame(height: 140)
        }
    }

    private func scoreCategoria(_ score: Float) -> String {
        switch score {
        case 0.7...: return "Alto"
        case 0.4..<0.7: return "Medio"
        default: return "Bajo"
        }
    }
}

// MARK: ─── Historial ─────────────────────────────────────────

struct HistorialSection: View {
    let logs: [ConsultaLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Últimas consultas", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            ForEach(logs) { log in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(log.scoreMaximo >= 0.7 ? .green :
                              log.scoreMaximo >= 0.4 ? .orange : .red)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.pregunta)
                            .font(.callout)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text(log.timestamp, style: .relative)
                            Text("·")
                            Text("\(log.chunksUsados) chunks")
                            Text("·")
                            Text(String(format: "score %.2f", log.scoreMaximo))
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                if log.id != logs.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: ─── Vacío ─────────────────────────────────────────────

struct DashboardVacioView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Sin datos aún")
                .font(.title2.bold())
            Text("Haz consultas en la pestaña 'Consultar'\npara ver el dashboard en acción")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: ─── ChartCard ─────────────────────────────────────────

struct ChartCard<Content: View>: View {
    let titulo: String
    let icono: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(titulo, systemImage: icono)
                .font(.headline)
            content()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
