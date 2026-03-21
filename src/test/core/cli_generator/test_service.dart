import 'package:revitool/core/cli_generator/annotations.dart';

part 'test_service.g.dart';

enum TestTarget { alpha, beta }

@CliCommand(name: 'test', description: 'test cli')
abstract class TestService {
  @CliToggle(
    name: 'feature',
    status: 'statusFeature',
    enable: 'enableFeature',
    disable: 'disableFeature',
  )
  bool get statusFeature;
  Future<void> enableFeature();
  Future<void> disableFeature();

  @CliEnumSubCommand(
    name: 'mode',
    values: TestTarget.values,
    status: 'isModeEnabled',
    enableMethod: 'enableMode',
    disableMethod: 'disableMode',
  )
  bool isModeEnabled(TestTarget target);
  Future<void> enableMode(TestTarget target);
  Future<void> disableMode(TestTarget target);
}

class TestServiceImpl implements TestService {
  @override
  Future<void> disableFeature() async {}

  @override
  Future<void> disableMode(TestTarget target) async {}

  @override
  Future<void> enableFeature() async {}

  @override
  Future<void> enableMode(TestTarget target) async {}

  @override
  bool isModeEnabled(TestTarget target) => target == TestTarget.alpha;

  @override
  bool get statusFeature => true;
}
