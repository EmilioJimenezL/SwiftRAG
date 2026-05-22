// PDFExtractor.swift
// ══════════════════════════════════════════════════════════════
//  PASO 1 — PDFKit
//
//  Aprendemos:
//  • Cargar un PDF con PDFDocument
//  • Iterar páginas con PDFPage
//  • Extraer texto plano con page.string
//
//  EJERCICIO del taller:
//  Completa la función `extraer(url:)` — busca los comentarios
//  con "// TODO:" y escribe el código que falta.
// ══════════════════════════════════════════════════════════════

import PDFKit
import Foundation

enum PDFError: LocalizedError {
    case noSeLeyoElPDF(String)
    case sinTexto(String)

    var errorDescription: String? {
        switch self {
        case .noSeLeyoElPDF(let nombre): return "No se pudo abrir: \(nombre)"
        case .sinTexto(let nombre):      return "El PDF no tiene texto: \(nombre)"
        }
    }
}

struct PDFExtractor {

    // ─────────────────────────────────────────────────────────
    // Extrae todas las páginas de un PDF como texto plano.
    // Retorna un array de tuplas (numeroDePagina, texto).
    // ─────────────────────────────────────────────────────────
    static func extraer(url: URL) throws -> [(pagina: Int, texto: String)] {

        // TODO [PASO 1.1]: Crear el PDFDocument desde la URL
        // Pista: PDFDocument(url:) regresa Optional — usa guard let
        guard let documento = PDFDocument(url: url) else {
            throw PDFError.noSeLeyoElPDF(url.lastPathComponent)
        }

        var paginas: [(Int, String)] = []

        // TODO [PASO 1.2]: Iterar cada página del documento
        // Pista: documento.pageCount te da el total de páginas
        //        documento.page(at: i) regresa PDFPage?
        for i in 0..<documento.pageCount {
            guard let pagina = documento.page(at: i),
                  let texto  = pagina.string,      // texto plano de la página
                  !texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { continue }

            paginas.append((i + 1, texto))         // páginas base-1
        }

        guard !paginas.isEmpty else {
            throw PDFError.sinTexto(url.lastPathComponent)
        }

        return paginas
    }
}
