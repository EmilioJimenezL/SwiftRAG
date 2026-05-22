# IA on-device: PDFKit, Embeddings y RAG con Swift
## Taller de 1 hora — Apple Education

---

## Requisitos

| Requerimiento | Detalle |
|---|---|
| Dispositivo | iPhone 15 Pro o superior |
| Sistema operativo | iOS 18+ |
| Xcode | 16+ (macOS del instructor) |
| Apple Intelligence | Recomendado (opcional — hay fallback) |
| Internet | **No requerido** — todo corre on-device |

---

## Estructura del proyecto

```
RAGTaller/
├── App/
│   └── RAGTallerApp.swift       # Entry point, SwiftData container
├── Models/
│   └── Models.swift             # ChunkDoc, ConsultaLog (@Model)
├── Services/
│   ├── PDFExtractor.swift       # PASO 1 — PDFKit
│   ├── EmbeddingEngine.swift    # PASO 2 — NLEmbedding + similitud coseno
│   ├── RAGPipeline.swift        # PASO 3 — Indexador + Recuperador
│   ├── AgenteRH.swift           # PASO 4 — FoundationModels
│   └── TallerSeeder.swift       # Datos de demo (LFT)
├── Views/
│   ├── ContentView.swift        # TabView principal
│   ├── IndexarView.swift        # Pestaña 1: indexar PDFs
│   ├── EmbeddingsView.swift     # Pestaña 2: explorar embeddings
│   ├── ConsultarView.swift      # Pestaña 3+4: RAG + chat
│   ├── DashboardView.swift      # Pestaña 4: Swift Charts
│   ├── IndexarView+Demo.swift   # Botón de demo (sin PDF real)
│   └── SharedComponents.swift   # EducationCard, ScoreBadge
```

---

## Agenda del taller (60 minutos)

### 00:00 — Introducción (5 min)
- ¿Qué es RAG? ¿Por qué on-device?
- Tour rápido de la app
- Mostrar que corre sin internet

### 00:05 — PASO 1: PDFKit (10 min)

**Archivo:** `Services/PDFExtractor.swift`

**Concepto:** PDFKit extrae texto de cualquier PDF.

```swift
// Las dos líneas clave:
let documento = PDFDocument(url: url)          // Cargar PDF
let texto     = documento.page(at: i)?.string  // Extraer texto
```

**Ejercicio:** Completar los `// TODO [PASO 1.1]` y `// TODO [PASO 1.2]`

**Demo en app:** Pestaña "Indexar" → "Cargar datos de demo (LFT)"

---

### 00:15 — PASO 2: Embeddings (15 min)

**Archivo:** `Services/EmbeddingEngine.swift`

**Concepto:** Un embedding es el "significado matemático" de un texto.

```swift
// Generar embedding en español:
let modelo  = NLEmbedding.sentenceEmbedding(for: .spanish)
let vector  = modelo?.vector(for: "días de vacaciones")
// → [Float] de 128 dimensiones

// Similitud coseno (vDSP = muy rápido):
let similitud = EmbeddingEngine.similitudCoseno(vectorA, vectorB)
// → 0.89 (muy similar!)
```

**Ejercicio:** Completar el `// TODO [PASO 2.3]`

**Demo en app:** Pestaña "Embeddings" → probar los pares de ejemplo
- "vacaciones" vs "días de descanso" → ~0.85
- "vacaciones" vs "impuestos" → ~0.12

---

### 00:30 — PASO 3: RAG con SwiftData (15 min)

**Archivo:** `Services/RAGPipeline.swift`

**Concepto:** RAG = guardar vectores → buscar los más similares a la consulta.

```
┌──────────┐   embedding   ┌──────────────┐   top-4   ┌────────┐
│ "¿días   │──────────────▶│  SwiftData   │──────────▶│ LLM   │
│ vacacio?"│               │  (ChunkDoc)  │           │       │
└──────────┘               └──────────────┘           └────────┘
```

**Flujo en código:**
```swift
// Indexar:
let vector = EmbeddingEngine.vectorizar(texto: chunk.texto)
context.insert(ChunkDoc(texto: chunk, vector: vector))

// Recuperar:
let vectorConsulta = EmbeddingEngine.vectorizar(texto: pregunta)
let chunks = context.fetch(FetchDescriptor<ChunkDoc>())
let ranked = chunks.sorted { 
    cosineSimilarity($0.vector, vectorConsulta) > 
    cosineSimilarity($1.vector, vectorConsulta) 
}
```

**Ejercicio:** Completar los `// TODO [PASO 3.1]` al `// TODO [PASO 3.7]`

**Demo en app:** Pestaña "Consultar" → hacer una pregunta → botón "Ver RAG" para ver los chunks recuperados

---

### 00:45 — PASO 4: FoundationModels + Dashboard (12 min)

**Archivo:** `Services/AgenteRH.swift` + `Views/DashboardView.swift`

**FoundationModels:**
```swift
let model   = SystemLanguageModel.default
let session = LanguageModelSession(instructions: "Eres un asistente de RRHH...")
let respuesta = try await session.respond(to: pregunta + contextoRAG)
```

**Swift Charts:**
```swift
Chart(datos) { punto in
    BarMark(x: .value("Hora", punto.hora),
            y: .value("Consultas", punto.conteo))
    .foregroundStyle(.blue.gradient)
}
```

**Ejercicio:** Completar los `// TODO [PASO 4.5]`, `// TODO [PASO 4.6]`, `// TODO [PASO 4.7]`

**Demo:** Ver el dashboard llenarse con cada consulta que hacen.

---

### 00:57 — Cierre (3 min)
- Q&A
- ¿Qué harían diferente para su caso de uso?
- Recursos adicionales

---

## TODOs del taller (lista completa)

| TODO | Archivo | Concepto |
|---|---|---|
| PASO 1.1 | PDFExtractor.swift | `PDFDocument(url:)` |
| PASO 1.2 | PDFExtractor.swift | `documento.page(at:)` |
| PASO 2.1 | EmbeddingEngine.swift | `NLTokenizer(unit: .sentence)` |
| PASO 2.2 | EmbeddingEngine.swift | `enumerateTokens` |
| PASO 2.3 | EmbeddingEngine.swift | `NLEmbedding.vector(for:)` |
| PASO 3.1 | RAGPipeline.swift | `PDFExtractor.extraer(url:)` |
| PASO 3.2 | RAGPipeline.swift | `TextChunker.chunkear(...)` |
| PASO 3.3 | RAGPipeline.swift | `EmbeddingEngine.vectorizar(...)` |
| PASO 3.4 | RAGPipeline.swift | `context.insert(ChunkDoc(...))` |
| PASO 3.5 | RAGPipeline.swift | vectorizar la consulta |
| PASO 3.6 | RAGPipeline.swift | `context.fetch(FetchDescriptor<ChunkDoc>())` |
| PASO 3.7 | RAGPipeline.swift | `.sorted { $0.score > $1.score }` |
| PASO 4.1 | AgenteRH.swift | `recuperador.recuperar(consulta:)` |
| PASO 4.2 | AgenteRH.swift | construir contexto como String |
| PASO 4.3 | AgenteRH.swift | llamar `generarRespuesta(...)` |
| PASO 4.4 | AgenteRH.swift | `context.insert(ConsultaLog(...))` |
| PASO 4.5 | AgenteRH.swift | `LanguageModelSession` + `respond(to:)` |
| PASO 4.6 | DashboardView.swift | `BarMark` |
| PASO 4.7 | DashboardView.swift | `SectorMark` |
| PASO 4.8 | DashboardView.swift | `PointMark` |

---

## Setup en Xcode (5 minutos antes del taller)

1. Crear nuevo proyecto iOS → App
2. Product Name: `RAGTaller`
3. Copiar todos los archivos `.swift` al proyecto
4. En **Signing & Capabilities** agregar:
   - App Sandbox → Files: User Selected (Read Only)
5. Frameworks necesarios (ya incluidos en iOS 18):
   - `PDFKit` ✓
   - `NaturalLanguage` ✓
   - `FoundationModels` ✓
   - `SwiftData` ✓
   - `Accelerate` ✓
   - `Charts` ✓
6. Build & Run en el dispositivo

---

## Notas para el instructor

**Si Apple Intelligence no está activo:**
La app tiene fallback educativo que muestra directamente el contexto RAG recuperado — esto es incluso mejor para el taller porque los participantes ven exactamente qué recuperó el sistema antes de enviarlo al modelo.

**Si un participante no tiene PDF:**
El botón "Cargar datos de demo (LFT)" en la pestaña Indexar carga 8 artículos de la Ley Federal del Trabajo directamente en SwiftData sin necesitar ningún archivo.

**Preguntas que funcionan bien con los datos de demo:**
- "¿Cuántos días de vacaciones me dan?"
- "¿Qué es el IMSS?"
- "¿Cuánto es el aguinaldo?"
- "¿Cuántas horas puedo trabajar al día?"
- "¿Qué pasa si me despiden injustificadamente?"
