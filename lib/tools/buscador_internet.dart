import 'package:dotenv/dotenv.dart';
import 'package:langchain_community/langchain_community.dart';

var env = DotEnv(includePlatformEnvironment: true)..load();

final buscadorInternet = TavilyAnswerTool(apiKey: env['TAVILY_API_KEY']);
