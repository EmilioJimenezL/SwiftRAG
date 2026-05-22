// SharedComponents.swift
// ══════════════════════════════════════════════════════════════
//  Componentes reutilizables del taller
// ══════════════════════════════════════════════════════════════

import SwiftUI

// MARK: ─── EducationCard ─────────────────────────────────────
// Tarjeta didáctica que aparece en cada pantalla del taller.

struct EducationCard: View {
    let paso: String
    let titulo: String
    let descripcion: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(paso)
                    .font(.headline.bold())
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.callout.bold())
                Text(descripcion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(color.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: ─── ScoreBadge ────────────────────────────────────────

struct ScoreBadge: View {
    let score: Float

    private var color: Color {
        switch score {
        case 0.7...: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text(String(format: "%.2f", score))
            .font(.caption2.monospacedDigit())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
