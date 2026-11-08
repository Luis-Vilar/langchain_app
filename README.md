# LangChain App - Agente Local con Ollama

Un agente conversacional en Dart que utiliza **LangChain.dart** y **Ollama** para ejecutar modelos de lenguaje localmente, con herramientas personalizadas y de la comunidad.

## 🎯 Características

- **Ejecución 100% local** - Los modelos corren en tu máquina vía Ollama (sin depender de APIs externas para el LLM)
- **Dos herramientas integradas**:
  - 🔤 **Contar Letras** - Herramienta personalizada que cuenta letras de una palabra
  - 🌐 **Buscador Internet** - Herramienta de `langchain_community` (Tavily) para búsqueda web
- **Arquitectura modular** - Fácil de extender con nuevas herramientas
- **Interfaz CLI interactiva** - Chat en terminal con historial de conversación

## 📋 Requisitos Previos

| Herramienta | Versión Mínima | Descripción |
|-------------|----------------|-------------|
| **Dart SDK** | 3.13.5+ | Entorno de ejecución |
| **Ollama** | 0.1.0+ | Servidor local de modelos LLM |
| **Modelo LLM** | - | `qwen3:8b` (recomendado) u otro compatible |

### Instalar Ollama y el modelo

```bash
# Instalar Ollama (Linux/macOS)
curl -fsSL https://ollama.com/install.sh | sh

# Descargar el modelo recomendado (≈ 5 GB)
ollama pull qwen3:8b

# Verificar que Ollama está corriendo
ollama serve
```

## ⚙️ Configuración

### 1. Clonar y preparar el proyecto

```bash
cd langchain_app
dart pub get
```

### 2. Configurar API Key de Tavily (Requerido para búsqueda web)

La herramienta de búsqueda internet requiere una API key de [Tavily](https://tavily.com/):

```bash
# Copiar el archivo de ejemplo
cp .env.example .env

# Editar .env y agregar tu API key
# TAVILY_API_KEY='tu-api-key-aqui'
```

> **Nota**: Sin esta key, la herramienta de búsqueda fallará, pero el agente seguirá funcionando con la herramienta de contar letras.

## 🚀 Ejecutar

```bash
# Opción 1: Desde el directorio raíz
dart run bin/langchain_app.dart

# Opción 2: Compilar y ejecutar (más rápido en ejecuciones posteriores)
dart compile exe bin/langchain_app.dart -o bin/agent
./bin/agent
```

### Ejemplo de uso

```
🤖 Inicializando agente robusto con Ollama Local...
🚀 Agente listo. Hazle una pregunta (o escribe "salir" para terminar).

Tú 👤: Cuántas letras tiene la palabra "mariposa"
Agente local 🤖 (pensando...): La palabra "mariposa" tiene 8 letras.

Tú 👤: Busca información sobre Dart lenguaje de programación
Agente local 🤖 (pensando...): Dart es un lenguaje de programación optimizado para UI...
```

## 💻 Limitaciones de Hardware (Ejecución Local)

Al ejecutar modelos **localmente** con Ollama, ten en cuenta:

| Recurso | Requisito Mínimo | Recomendado | Notas |
|---------|------------------|-------------|-------|
| **RAM** | 8 GB | 16+ GB | `qwen3:8b` necesita ~5 GB solo para el modelo |
| **VRAM (GPU)** | 6 GB | 8+ GB | Para inferencia acelerada en GPU (Metal/CUDA) |
| **Disco** | 10 GB libre | 20+ GB | Modelos + cache + SO |
| **CPU** | 4 núcleos | 8+ núcleos | Inferencia CPU-only es lenta |

### Consideraciones importantes

1. **Sin GPU dedicada**: La inferencia será **muy lenta** (tokens/segundo bajos). El modelo `qwen3:8b` en CPU puede tardar 10-30 segundos por respuesta.

2. **RAM compartida**: En laptops con gráficos integrados (ej. Apple Silicon, AMD APU), la RAM del sistema se comparte. 16 GB es el mínimo cómodo.

3. **Modelos alternativos más ligeros**:
   ```bash
   # Modelos más pequeños para hardware limitado
   ollama pull qwen3:4b      # ~2.5 GB RAM
   ollama pull llama3.2:3b   # ~2 GB RAM
   ollama pull phi3:mini     # ~2.3 GB RAM
   ```
   Luego actualiza `lib/agent.dart` línea 13:
   ```dart
   defaultOptions: const ChatOllamaOptions(model: 'qwen3:4b', temperature: 0),
   ```

4. **Temperatura 0**: Configurado para respuestas determinísticas. Sube a `0.7` para más creatividad.

## 📁 Estructura del Proyecto

```
langchain_app/
├── bin/
│   └── langchain_app.dart     # Entry point
├── lib/
│   ├── agent.dart             # Lógica principal del agente
│   └── tools/
│       ├── buscar_internet.dart   # Tool Tavily (langchain_community)
│       ├── calculadora.dart       # CalculatorTool (langchain_community)
│       └── contar_letras.dart     # Tool personalizada
├── .env                       # Variables de entorno (no commitear)
├── .env.example               # Plantilla de variables
├── pubspec.yaml               # Dependencias
└── README.md                  # Este archivo
```

## 🔧 Extender con Nuevas Herramientas

1. Crea un archivo en `lib/tools/mi_herramienta.dart`:
   ```dart
   import 'package:langchain/langchain.dart';

   class MiHerramientaInput {
     final String parametro;
     MiHerramientaInput({required this.parametro});
   }

   base class MiHerramienta extends Tool<MiHerramientaInput, ToolOptions, String> {
     MiHerramienta()
       : super(
           name: 'mi_herramienta',
           description: 'Descripción para el LLM',
           inputJsonSchema: { /* esquema JSON */ },
         );

     @override
     MiHerramientaInput getInputFromJson(Map<String, dynamic> json) => 
       MiHerramientaInput(parametro: json['parametro'] as String);

     @override
     Future<String> invokeInternal(MiHerramientaInput input, {ToolOptions? options}) async {
       // Tu lógica aquí
       return 'Resultado: ${input.parametro}';
     }
   }

   final miHerramientaTool = MiHerramienta();
   ```

2. Regístrala en `lib/agent.dart`:
   ```dart
   import 'package:langchain_app/tools/mi_herramienta.dart';

   // En toolsMap:
   final toolsMap = <String, Tool<dynamic, ToolOptions, String>>{
     contarLetrasTool.name: contarLetrasTool,
     buscadorInternet.name: buscadorInternet,
     calculadora.name: calculadora,
     miHerramientaTool.name: miHerramientaTool,  // ← Agregar
   };

   // En bind():
   final modelWithTools = model.bind(
     ChatOllamaOptions(tools: [contarLetrasTool, buscadorInternet, calculadora, miHerramientaTool]),
   );
   ```

## 🐛 Solución de Problemas

| Error | Solución |
|-------|----------|
| `Connection refused` (Ollama) | Ejecuta `ollama serve` en otra terminal |
| `model not found` | `ollama pull qwen3:8b` |
| `TAVILY_API_KEY not set` | Configura `.env` con tu key de Tavily |
| `Out of memory` | Usa modelo más pequeño (ver tabla arriba) |
| Muy lento en CPU | Normal en CPU-only; considera GPU o modelo menor |

## 📄 Licencia

MIT - Libre para uso personal y comercial.