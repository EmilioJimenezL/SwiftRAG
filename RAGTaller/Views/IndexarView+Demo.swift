// IndexarView+Demo.swift
// ══════════════════════════════════════════════════════════════
//  Extensión de IndexarView: botón "Demo" para el taller
//  Agrega datos de ejemplo sin necesitar un PDF real.
// ══════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

extension IndexarView {
    // Este botón aparece en el toolbar cuando no hay documentos.
    // Llama al TallerSeeder para cargar artículos de la LFT.
    @MainActor
    func cargarDemo(context: ModelContext) async {
        // Llamado desde IndexarView.toolbar
        // Ver IndexarView.swift — ToolbarItem "Cargar Demo"
    }
}

// MARK: ─── Botón de Demo (componente independiente) ──────────
// Úsalo en IndexarView añadiendo este ToolbarItem:
//
//  ToolbarItem(placement: .bottomBar) {
//      DemoButton()
//  }

struct DemoButton: View {
    @Environment(\.modelContext) private var context
    @State private var cargando = false
    @State private var mensaje  = ""

    var body: some View {
        VStack(spacing: 0) {
            if !mensaje.isEmpty {
                Text(mensaje)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                Task {
                    cargando = true
                    do {
                        let n = try await TallerSeeder.sembrarSiNecesario(context: context)
                        withAnimation {
                            mensaje = "✓ \(n) chunks de demo cargados"
                        }
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        withAnimation { mensaje = "" }
                    } catch {
                        mensaje = "Error: \(error.localizedDescription)"
                    }
                    cargando = false
                }
            } label: {
                HStack {
                    if cargando {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(cargando ? "Cargando..." : "Cargar datos de demo (LFT)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(cargando)
        }
    }
}
