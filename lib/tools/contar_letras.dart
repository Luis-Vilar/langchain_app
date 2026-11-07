import 'package:langchain/langchain.dart';

class ContarLetrasInput {
  final String palabra;
  ContarLetrasInput({required this.palabra});
}

base class ContarLetras extends Tool<ContarLetrasInput, ToolOptions, String> {
  ContarLetras()
    : super(
        name: 'contar_letras',
        description:
            'Útil para contar cuántas letras tiene una palabra específica.',
        // Definimos el esquema JSON que el LLM debe generar
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'palabra': {
              'type': 'string',
              'description':
                  'La palabra de la cual se quiere contar las letras.',
            },
          },
          'required': ['palabra'],
        },
      );

  // 1. Transforma el JSON enviado por el LLM en un objeto tipado.
  @override
  ContarLetrasInput getInputFromJson(Map<String, dynamic> json) {
    return ContarLetrasInput(palabra: json['palabra'] as String);
  }

  // 2. Ejecuta la lógica interna de tu herramienta usando el input ya tipado
  @override
  Future<String> invokeInternal(
    ContarLetrasInput input, {
    ToolOptions? options,
  }) async {
    final cantidad = input.palabra.trim().replaceAll(' ', '').length;
    return 'La palabra "${input.palabra}" tiene $cantidad letras.';
  }
}

final contarLetrasTool = ContarLetras();
