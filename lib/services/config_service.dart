import 'package:timely/models/app_config.dart';

// Interface
abstract class ConfigService {
  Future<AppConfig> getConfig();
  Future<void> updateConfig(AppConfig config);
}
