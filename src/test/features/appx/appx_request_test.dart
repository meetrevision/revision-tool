import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/error/app_exception.dart';
import 'package:revitool/features/appx/appx.dart';

AppxRequest parse(List<String> argv) {
  final parser = ArgParser();
  configureAppxParser(parser);
  return parseAppxRequest(parser.parse(argv), '');
}

void main() {
  group('parseAppxRequest', () {
    test('takes comma-separated names on --remove', () {
      final AppxRequest request = parse(['--remove', 'A,B,C']);

      expect(
        request,
        isA<AppxRemoveRequest>()
            .having((r) => r.prefixes, 'prefixes', ['A', 'B', 'C'])
            .having((r) => r.allUsers, 'allUsers', isFalse)
            .having((r) => r.preserveRoaming, 'preserveRoaming', isFalse),
      );
    });

    test('composes repeated and comma-separated values', () {
      final AppxRequest request = parse(['--remove', 'A,B', '--remove', 'C']);

      expect((request as AppxRemoveRequest).prefixes, ['A', 'B', 'C']);
    });

    test('trims whitespace and drops blanks', () {
      final AppxRequest request = parse(['--remove', ' A , ,B ']);

      expect((request as AppxRemoveRequest).prefixes, ['A', 'B']);
    });

    test('builds the all-users shape from --all-users', () {
      final AppxRequest request = parse(['--remove', 'A', '--all-users']);

      expect((request as AppxRemoveRequest).allUsers, isTrue);
    });

    test('rejects --all-users with --preserve-roaming', () {
      expect(
        () => parse(['--remove', 'A', '--all-users', '--preserve-roaming']),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('--all-users cannot be combined with --preserve-roaming'),
          ),
        ),
      );
    });

    test('rejects two actions', () {
      expect(() => parse(['--list', '--remove', 'A']), throwsA(isA<UsageException>()));
      expect(() => parse(['--users', 'A', '--remove', 'B']), throwsA(isA<UsageException>()));
    });

    test('rejects scope flags without --remove', () {
      expect(() => parse(['--all-users']), throwsA(isA<UsageException>()));
      expect(() => parse(['--list', '--preserve-roaming']), throwsA(isA<UsageException>()));
    });

    test('rejects --match and --provisioned without --list', () {
      expect(() => parse(['--match', 'A']), throwsA(isA<UsageException>()));
      expect(() => parse(['--provisioned', '--remove', 'A']), throwsA(isA<UsageException>()));
    });

    test('rejects a value that is only commas and spaces', () {
      expect(() => parse(['--remove', ' , ']), throwsA(isA<UsageException>()));
    });

    test('lists everything on bare invocation', () {
      final AppxRequest request = parse(const []);

      expect(
        request,
        isA<AppxListRequest>()
            .having((r) => r.prefixes, 'prefixes', isEmpty)
            .having((r) => r.provisioned, 'provisioned', isFalse),
      );
    });

    test('lists provisioned packages matching prefixes', () {
      final AppxRequest request = parse(['--list', '--provisioned', '--match', 'A,B']);

      expect(
        request,
        isA<AppxListRequest>()
            .having((r) => r.prefixes, 'prefixes', ['A', 'B'])
            .having((r) => r.provisioned, 'provisioned', isTrue),
      );
    });

    test('reads --users values', () {
      expect((parse(['--users', 'A,B']) as AppxUsersRequest).prefixes, ['A', 'B']);
    });

    test('reads --exclude values on --remove and --list', () {
      final AppxRequest removeReq = parse(['--remove', 'A,B', '--exclude', 'C,D']);
      expect((removeReq as AppxRemoveRequest).exclude, ['C', 'D']);

      final AppxRequest listReq = parse(['--list', '-e', 'Excluded']);
      expect((listReq as AppxListRequest).exclude, ['Excluded']);
    });
  });

  group('appxExitCode', () {
    test('maps each failure kind onto its code', () {
      expect(
        appxExitCode(_wrapped(AppxBridgeUnavailableException('x'))),
        appxExitBridgeUnavailable,
      );
      expect(
        appxExitCode(
          _wrapped(
            AppxRemovalRefusedException(
              const AppxRemovalResult(identifier: 'x', extendedErrorCode: 1, errorText: 'no'),
            ),
          ),
        ),
        appxExitRefused,
      );
      expect(appxExitCode(_wrapped(AppxEnumerationException('x'))), appxExitBridgeFailed);
      expect(appxExitCode(const NetworkException()), 1);
    });
  });
}

/// Wraps a domain failure the way AppxService.errorMapper does.
AppException _wrapped(AppxException e) => UnexpectedNetworkException(message: e.message, cause: e);
