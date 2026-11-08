import 'dart:io';

import 'package:langchain/langchain.dart';
import 'package:langchain_app/tools/buscador_internet.dart';
import 'package:langchain_app/tools/calculadora.dart';
import 'package:langchain_app/tools/contar_letras.dart';
import 'package:langchain_ollama/langchain_ollama.dart';

void agent() async {
  print('🤖 Inicializando agente robusto con Ollama Local...');

  //  Inicializar el modelo de Ollama
  final model = ChatOllama(
    defaultOptions: const ChatOllamaOptions(model: 'qwen3:8b', temperature: 0),
  );

  //  Vincular (bind) la herramienta directamente al modelo
  final modelWithTools = model.bind(
    ChatOllamaOptions(tools: [contarLetrasTool, buscadorInternet, calculadora]),
  );

  // Mapear nombres de herramientas a sus instancias para evitar código repetitivo
  final toolsMap = <String, Tool<dynamic, ToolOptions, String>>{
    contarLetrasTool.name: contarLetrasTool,
    buscadorInternet.name: buscadorInternet,
    calculadora.name: calculadora,
  };

  print(
    '🚀 Agente listo. Hazle una pregunta (o escribe "salir" para terminar).\n',
  );

  while (true) {
    stdout.write('Tú 👤: ');
    final input = stdin.readLineSync();

    if (input == null || input.trim().toLowerCase() == 'salir') {
      print('¡Hasta luego! 🤖👋');
      break;
    }

    if (input.trim().isEmpty) continue;

    try {
      stdout.write('Agente local 🤖 (pensando...):\r');

      // Crear el historial de mensajes usando las clases correctas de LangChain.dart
      final mensajes = <ChatMessage>[
        SystemChatMessage(
          content:
              'Eres un asistente útil que tiene acceso a herramientas. '
              'Solo usa herramientas que tengan sentido según la entrada del humano',
        ),
        HumanChatMessage(content: ChatMessageContent.text(input)),
      ];

      // Primera llamada al modelo (para decidir si usa herramienta)
      var respuesta = await modelWithTools.invoke(PromptValue.chat(mensajes));

      // ¿El modelo decidió que quiere llamar a una herramienta?
      if (respuesta.output.toolCalls.isNotEmpty) {
        final toolCall = respuesta.output.toolCalls.first;
        final tool = toolsMap[toolCall.name];

        if (tool != null) {
          // Convertir el Map a input tipado y ejecutar usando el método público invoke
          final typedInput = tool.getInputFromJson(toolCall.arguments);
          final resultadoTool = await tool.invoke(typedInput);
          mensajes.add(respuesta.output);
          mensajes.add(
            ToolChatMessage(toolCallId: toolCall.id, content: resultadoTool),
          );
          respuesta = await modelWithTools.invoke(PromptValue.chat(mensajes));
        }
      }

      // Limpiar la línea e imprimir el resultado final limpio en lenguaje natural
      stdout.write('' * 35 + '\r');

      // Extraer el texto de los bloques de contenido (AIChatMessageTextBlock)
      final textBlocks = respuesta.output.content
          .whereType<AIChatMessageTextBlock>()
          .map((block) => block.text)
          .join(' ');

      // Fallback si no hay bloques de texto
      final outputText = textBlocks.isNotEmpty
          ? textBlocks
          : respuesta.output.content.toString();

      print('Agente local 🤖: $outputText\n');
    } catch (e) {
      print('\n❌ Error en el flujo: $e\n');
    }
  }
}
