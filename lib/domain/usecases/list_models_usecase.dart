library;

import '../entities/ai_settings.dart';
import '../repositories/ai_gateway.dart';

/// Lists the model ids a provider advertises as available.
///
/// Powers the Settings model picker so users can choose a model from a real
/// catalog instead of typing an id from memory.
class ListModelsUseCase {
  ListModelsUseCase({required AiGatewayResolver resolveGateway})
    : _resolveGateway = resolveGateway;

  final AiGatewayResolver _resolveGateway;

  Future<List<String>> call(AiSettings settings) =>
      _resolveGateway(settings).listModels(settings);
}
