// ContentView.swift
// ══════════════════════════════════════════════════════════════
//  Navegación principal — 4 pestañas = 4 pasos del taller
// ══════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {

            // ── Paso 1: Indexar PDFs ──────────────────────────
            IndexarView()
                .tabItem {
                    Label("Indexar", systemImage: "doc.text.magnifyingglass")
                }
                .tag(0)

            // ── Paso 2: Explorar Embeddings ───────────────────
            EmbeddingsView()
                .tabItem {
                    Label("Embeddings", systemImage: "waveform.path.ecg")
                }
                .tag(1)

            // ── Paso 3 + 4: Consultar con RAG ─────────────────
            ConsultarView()
                .tabItem {
                    Label("Consultar", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(2)

            // ── Paso 4: Dashboard Swift Charts ────────────────
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}
