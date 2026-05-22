// TallerSeeder.swift
// ══════════════════════════════════════════════════════════════
//  Datos de ejemplo para el taller
//
//  Como los participantes quizás no tengan PDFs a mano,
//  este seeder crea chunks de texto de muestra directamente
//  en SwiftData para que puedan probar el RAG de inmediato.
//
//  USO: Llámalo desde la IndexarView con el botón "Demo"
// ══════════════════════════════════════════════════════════════

import Foundation
import SwiftData

@MainActor
struct TallerSeeder {

    static let documentoDemo = "LFT-Demo.pdf"

    static let textosPorPagina: [(pagina: Int, texto: String)] = [
        (1, """
        Artículo 76 — Los trabajadores que tengan más de un año de servicios disfrutarán de
        un período anual de vacaciones pagadas, que en ningún caso podrá ser inferior a doce
        días laborables, y que aumentará en dos días laborables, hasta llegar a veinte, por
        cada año subsecuente de servicios. A partir del sexto año, el período de vacaciones
        aumentará en dos días por cada cinco de servicios.
        """),
        (2, """
        Artículo 80 — Los trabajadores tendrán derecho a una prima no menor de veinticinco
        por ciento sobre los salarios que les correspondan durante el período de vacaciones.
        Esta prima de vacaciones es una prestación obligatoria que el patrón debe pagar
        adicional al salario ordinario durante el período vacacional del trabajador.
        """),
        (3, """
        Artículo 87 — Los trabajadores tendrán derecho a un aguinaldo anual que deberá
        pagarse antes del día veinte de diciembre, equivalente a quince días de salario,
        por lo menos. Los que no hayan cumplido el año de servicios tendrán derecho al
        pago proporcional al tiempo trabajado.
        """),
        (4, """
        El Instituto Mexicano del Seguro Social (IMSS) brinda a los trabajadores seguridad
        social que incluye: seguro de enfermedades y maternidad, seguro de riesgos de trabajo,
        seguro de invalidez y vida, seguro de retiro y vejez. Las aportaciones son tripartitas:
        trabajador, patrón y gobierno federal. El patrón tiene la obligación de inscribir a
        sus trabajadores dentro de los cinco días hábiles siguientes a la fecha de su ingreso.
        """),
        (5, """
        INFONAVIT — El Instituto del Fondo Nacional de la Vivienda para los Trabajadores
        administra las aportaciones patronales del cinco por ciento sobre el salario base de
        cotización para el fondo de vivienda. Los trabajadores pueden acceder a créditos de
        vivienda, mejorar su hogar o retirar sus recursos al cumplir 65 años de edad o
        en casos de desempleo prolongado.
        """),
        (6, """
        Artículo 48 — El trabajador podrá solicitar ante la Junta de Conciliación y Arbitraje,
        a su elección, que se le reinstale en el trabajo que desempeñaba, o que se le pague
        una indemnización equivalente al importe de tres meses de salario. Si en el juicio
        correspondiente resultase comprobado el despido injustificado, el patrón podrá
        liberarse de la obligación de reinstalar, pagando al trabajador la indemnización señalada.
        """),
        (7, """
        La jornada de trabajo es el tiempo durante el cual el trabajador está a disposición
        del patrón para prestar su trabajo. La duración máxima de la jornada será: ocho horas
        la diurna, siete la nocturna y siete horas y media la mixta. Horas de trabajo extraordinarias
        se pagarán con un ciento por ciento más del salario que corresponda a las horas de
        la jornada.
        """),
        (8, """
        La NOM-035-STPS establece los factores de riesgo psicosocial en el trabajo y obliga
        a las empresas a identificar, analizar y prevenir los factores de riesgo psicosocial,
        así como promover un entorno organizacional favorable. Incluye la prevención del
        hostigamiento y acoso laboral. Las empresas con más de cincuenta trabajadores deben
        aplicar evaluaciones y disponer de mecanismos seguros para la denuncia.
        """),
    ]

    // ─────────────────────────────────────────────────────────
    // Siembra chunks de ejemplo si no hay documentos indexados
    // ─────────────────────────────────────────────────────────
    static func sembrarSiNecesario(context: ModelContext) async throws -> Int {
        let descriptor = FetchDescriptor<ChunkDoc>(
            predicate: #Predicate { $0.documentoNombre == documentoDemo }
        )
        let existentes = try context.fetch(descriptor)
        guard existentes.isEmpty else { return existentes.count }

        var totalChunks = 0

        for (pagina, texto) in textosPorPagina {
            let chunks = TextChunker.chunkear(
                texto: texto,
                pagina: pagina,
                documentoNombre: documentoDemo
            )

            for (textoChunk, indice) in chunks {
                guard let vector = EmbeddingEngine.vectorizar(texto: textoChunk) else {
                    continue
                }
                let chunk = ChunkDoc(
                    documentoNombre: documentoDemo,
                    pagina: pagina,
                    chunkIndex: indice,
                    texto: textoChunk,
                    vector: vector
                )
                context.insert(chunk)
                totalChunks += 1
            }
        }

        try context.save()
        print("[TallerSeeder] \(totalChunks) chunks de demo creados")
        return totalChunks
    }
}
