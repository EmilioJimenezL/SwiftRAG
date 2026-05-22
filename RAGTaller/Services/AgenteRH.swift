// AgenteRH.swift
// ══════════════════════════════════════════════════════════════
//  PASO 4 — FoundationModels (Apple Intelligence)
//
//  Aprendemos:
//  • SystemLanguageModel.default
//  • LanguageModelSession + instructions
//  • Patrón RAG completo: contexto → prompt → respuesta
//
//  IMPORTANTE: Requiere Apple Intelligence activado en el dispositivo
//  (Configuración → Apple Intelligence y Siri → Apple Intelligence)
//  Si no está disponible, la app usa un fallback educativo.
// ══════════════════════════════════════════════════════════════

import Foundation
import FoundationModels
import SwiftData
import Combine

// MARK: ─── AgenteRH ──────────────────────────────────────────

@MainActor
final class AgenteRH: ObservableObject {

    @Published var procesando   = false
    @Published var disponible   = false
    @Published var ultimaRuta   = ""

    private let recuperador: Recuperador
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        self.recuperador = Recuperador(context: context)
        verificarDisponibilidad()
    }

    // ─────────────────────────────────────────────────────────
    // Verifica si Apple Intelligence está disponible
    // ─────────────────────────────────────────────────────────
    private func verificarDisponibilidad() {
        if case .available = SystemLanguageModel.default.availability {
            disponible = true
        }
    }

    // ─────────────────────────────────────────────────────────
    // Pipeline RAG completo:
    //  1. Recuperar chunks relevantes
    //  2. Construir prompt con contexto
    //  3. Invocar FoundationModels
    //  4. Guardar log en SwiftData
    // ─────────────────────────────────────────────────────────
    func consultar(pregunta: String) async -> RespuestaAgente {
        let inicio = Date()
        procesando = true
        defer { procesando = false }

        // TODO [PASO 4.1]: Recuperar los chunks más relevantes
        let resultados = (try? recuperador.recuperar(consulta: pregunta, topK: 4)) ?? []

        // TODO [PASO 4.2]: Construir el contexto para el LLM
        // Concatenar los textos de los chunks recuperados
        let contexto = resultados
            .map { "[\($0.chunk.documentoNombre) p.\($0.chunk.pagina)] \($0.chunk.texto)" }
            .joined(separator: "\n\n---\n\n")

        let scoreMaximo = resultados.first?.score ?? 0

        // TODO [PASO 4.3]: Generar respuesta con FoundationModels
        let textoRespuesta = await generarRespuesta(
            pregunta: pregunta,
            contexto: contexto,
            chunksDisponibles: !resultados.isEmpty
        )

        let duracion = Date().timeIntervalSince(inicio)

        // TODO [PASO 4.4]: Guardar la consulta en SwiftData
        let log = ConsultaLog(
            pregunta: pregunta,
            respuesta: textoRespuesta,
            chunksUsados: resultados.count,
            scoreMaximo: scoreMaximo,
            duracionSegundos: duracion
        )
        context.insert(log)
        try? context.save()

        return RespuestaAgente(
            texto: textoRespuesta,
            chunksUsados: resultados.count,
            scoreMaximo: scoreMaximo,
            duracion: duracion,
            resultadosRAG: resultados
        )
    }

    // ─────────────────────────────────────────────────────────
    // Invoca FoundationModels con el contexto RAG
    // ─────────────────────────────────────────────────────────
    private func generarRespuesta(pregunta: String,
                                  contexto: String,
                                  chunksDisponibles: Bool) async -> String {
        // Fallback educativo si Apple Intelligence no está disponible
        guard disponible else {
            return fallbackEducativo(pregunta: pregunta,
                                     contexto: contexto,
                                     chunksDisponibles: chunksDisponibles)
        }

        let instrucciones = """
        Eres un asistente de RRHH de Mabe. Respondes preguntas sobre prestaciones,
        vacaciones, políticas y la Ley Federal del Trabajo.
        Sé claro, conciso y amable. Responde SIEMPRE en español.
        Si no encuentras la respuesta en el contexto proporcionado, dilo honestamente.

        Contexto disponible de los documentos indexados:
        \(contexto.isEmpty ? "Sin contexto disponible." : contexto)
        """

        do {
            // TODO [PASO 4.5]: Crear sesión y generar respuesta
            let session  = LanguageModelSession(instructions: instrucciones)
            let respuesta = try await session.respond(to: pregunta)
            return respuesta.content
        } catch {
            return "Error al generar respuesta: \(error.localizedDescription)"
        }
    }

    // ─────────────────────────────────────────────────────────
    // Fallback cuando Apple Intelligence no está activo.
    // Muestra el contexto RAG directamente — útil para el taller
    // porque los participantes ven exactamente qué recuperó el RAG.
    // ─────────────────────────────────────────────────────────
    private func fallbackEducativo(pregunta: String,
                                   contexto: String,
                                   chunksDisponibles: Bool) -> String {
        guard chunksDisponibles else {
            return """
            ⚠️ Apple Intelligence no está activo y no hay documentos indexados aún.
            
            Para activar Apple Intelligence:
            Configuración → Apple Intelligence y Siri → activar
            
            Para indexar documentos:
            Ve a la pestaña "Indexar" y agrega un PDF.
            """
        }

        return """
        📚 [Modo Demo — Apple Intelligence no activo]
        
        El RAG recuperó \(contexto.split(separator: "\n").count) fragmentos relevantes para:
        "\(pregunta)"
        
        Contexto recuperado:
        ────────────────────
        \(contexto.prefix(600))...
        ────────────────────
        
        Con Apple Intelligence activo, este contexto se enviaría al modelo
        de lenguaje on-device para generar una respuesta natural.
        """
    }
}

// MARK: ─── RespuestaAgente ───────────────────────────────────

struct RespuestaAgente {
    let texto: String
    let chunksUsados: Int
    let scoreMaximo: Float
    let duracion: Double
    let resultadosRAG: [Recuperador.Resultado]
}
