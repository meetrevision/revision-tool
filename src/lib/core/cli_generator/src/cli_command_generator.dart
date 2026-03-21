import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';

class CliCommandGenerator extends GeneratorForAnnotation<CliCommand> {
  static const _cliToggleChecker = TypeChecker.typeNamed(CliToggle);
  static const _cliValueChecker = TypeChecker.typeNamed(CliValue);
  static const _cliActionChecker = TypeChecker.typeNamed(CliAction);
  static const _cliEnumChecker = TypeChecker.typeNamed(CliEnumSubCommand);
  static final RegExp _dartIdentifierPattern = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_]*$',
  );
  static final RegExp _leadingDigitPattern = RegExp(r'^[0-9]');
  static final RegExp _genericCharsPattern = RegExp(r'[<>, ]');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement || !element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@CliCommand can only be applied to abstract classes.',
        element: element,
      );
    }

    final String serviceClassName = element.name ?? 'GeneratedService';
    final rootClassName = '${serviceClassName}CliCommand';
    final String commandName = annotation.read('name').stringValue;
    final String commandDescription = annotation
        .read('description')
        .stringValue;

    final groupClassNames = <String>[];
    final specs = <Spec>[];
    final enumTypes = <String>{};
    final members = <({ExecutableElement member, bool isGetter})>[
      ...element.getters
          .where((g) => g.isAbstract && !g.isPrivate)
          .map((g) => (member: g, isGetter: true)),
      ...element.methods
          .where((m) => m.isAbstract && !m.isPrivate && !m.isOperator)
          .map((m) => (member: m, isGetter: false)),
    ];

    for (final item in members) {
      final ExecutableElement member = item.member;
      final _CliMeta? meta = _extractMeta(member);
      if (meta == null) continue;
      final String memberName = _memberName(member);

      switch (meta) {
        case _CliMetaToggle():
          if (!item.isGetter) {
            throw InvalidGenerationSourceError(
              '@CliToggle on $serviceClassName.$memberName has the wrong target type. Expected getter.',
              element: member,
            );
          }
          final _GeneratedGroup group = _buildToggleGroup(
            serviceClassName,
            member as GetterElement,
            meta,
          );
          groupClassNames.add(group.className);
          specs.addAll(group.specs);

        case _CliMetaValue():
          if (!item.isGetter) {
            throw InvalidGenerationSourceError(
              '@CliValue on $serviceClassName.$memberName has the wrong target type. Expected getter.',
              element: member,
            );
          }
          final _GeneratedGroup group = _buildValueGroup(
            serviceClassName,
            member as GetterElement,
            meta,
          );
          groupClassNames.add(group.className);
          specs.addAll(group.specs);

        case _CliMetaAction():
          if (item.isGetter) {
            throw InvalidGenerationSourceError(
              '@CliAction on $serviceClassName.$memberName has the wrong target type. Expected method.',
              element: member,
            );
          }
          final MethodElement? runMethod = element.getMethod(meta.runMethod);
          if (runMethod == null) {
            throw InvalidGenerationSourceError(
              '@CliAction(name: "${meta.name}") references unknown run method: ${meta.runMethod}.',
              element: member,
            );
          }
          if (runMethod.formalParameters.isNotEmpty) {
            throw InvalidGenerationSourceError(
              '@CliAction(name: "${meta.name}") run method must not declare parameters.',
              element: member,
            );
          }
          if (!_isValidToggleReturnType(runMethod.returnType)) {
            throw InvalidGenerationSourceError(
              '@CliAction(name: "${meta.name}") run method must return void, Future<void>, or FutureOr<void>.',
              element: member,
            );
          }
          final _GeneratedLeaf leaf = _buildActionLeaf(
            serviceClassName,
            meta.runMethod,
            meta,
          );
          groupClassNames.add(leaf.className);
          specs.add(leaf.spec);

        case _CliMetaEnum():
          if (item.isGetter) {
            final getter = member as GetterElement;
            final String enumType = getter.returnType.getDisplayString();
            enumTypes.add(enumType);
            final _GeneratedGroup group = _buildEnumGroupFromGetter(
              serviceClassName,
              element,
              getter,
              meta,
            );
            groupClassNames.add(group.className);
            specs.addAll(group.specs);
            continue;
          }
          final method = member as MethodElement;
          if (method.formalParameters.length != 1) {
            throw InvalidGenerationSourceError(
              '@CliEnumSubCommand(name: "${meta.name}") status method must have exactly one enum parameter.',
              element: member,
            );
          }
          final String enumType = method.formalParameters.single.type
              .getDisplayString();
          enumTypes.add(enumType);
          final _GeneratedGroup group = _buildEnumGroup(
            serviceClassName,
            element,
            method,
            meta,
          );
          groupClassNames.add(group.className);
          specs.addAll(group.specs);
      }
    }

    final Class rootClass = _buildContainerClass(
      className: rootClassName,
      serviceClassName: serviceClassName,
      nameLiteral: _quoteLiteral(commandName),
      descriptionLiteral: _quoteLiteral(commandDescription),
      subcommandClassNames: groupClassNames,
      isFinalClass: true,
    );
    final Class baseClass = _buildServiceBaseClass(serviceClassName);

    final List<Method> helperMethods = enumTypes
        .map(_buildParseHelper)
        .toList(growable: false);

    final emitter = DartEmitter(useNullSafetySyntax: true);
    final output = StringBuffer();
    output.writeln(baseClass.accept(emitter));
    output.writeln();
    output.writeln(rootClass.accept(emitter));
    for (final helper in helperMethods) {
      output.writeln();
      output.writeln(helper.accept(emitter));
    }
    for (final spec in specs) {
      output.writeln();
      output.writeln(spec.accept(emitter));
    }
    return output.toString();
  }

  _GeneratedGroup _buildToggleGroup(
    String serviceClassName,
    GetterElement statusGetter,
    _CliMetaToggle meta,
  ) {
    final bool supportsForce =
        meta.enableForceMethod != null && meta.disableForceMethod != null;

    if ((meta.enableForceMethod == null) != (meta.disableForceMethod == null)) {
      throw InvalidGenerationSourceError(
        '@CliToggle(name: "${meta.name}") requires both enableForce and disableForce when either is provided.',
        element: statusGetter,
      );
    }

    final String display = _pascal(meta.name);
    final _GroupLeafNames names = _groupLeafNames(display);
    final String escapedMetaName = _escapeForSingleQuotedString(meta.name);

    final enableActionCode = supportsForce
        ? '''
if (force) {
  await _service.${meta.enableForceMethod}();
} else {
  await _service.${meta.enableMethod}();
}
'''
        : 'await _service.${meta.enableMethod}();\n';

    final disableActionCode = supportsForce
        ? '''
if (force) {
  await _service.${meta.disableForceMethod}();
} else {
  await _service.${meta.disableMethod}();
}
'''
        : 'await _service.${meta.disableMethod}();\n';

    final enableTryBody = supportsForce
        ? '''
final bool force = argResults?['force'] as bool? ?? false;
$enableActionCode
  logger.i('$escapedMetaName enabled\${force ? " (forced)" : ""}');
'''
        : '''
$enableActionCode
  logger.i('$escapedMetaName enabled');
''';

    final disableTryBody = supportsForce
        ? '''
final bool force = argResults?['force'] as bool? ?? false;
$disableActionCode
  logger.i('$escapedMetaName disabled\${force ? " (forced)" : ""}');
'''
        : '''
$disableActionCode
  logger.i('$escapedMetaName disabled');
''';

    final List<Class> toggleLeafClasses = [
      _buildLeafClass(
        className: names.enableLeaf,
        serviceClassName: serviceClassName,
        commandName: 'enable',
        descriptionLiteral: _quoteLiteral('Enable ${meta.name}'),
        constructorBody: supportsForce ? _toggleForceFlagCode : '',
        returnType: 'Future<void>',
        isAsync: true,
        runBodyCode: _buildTryCatchCode(
          tryBody: enableTryBody,
          exceptionMessageLiteral: _quoteLiteral(
            'Failed to enable ${meta.name}',
          ),
        ),
      ),
      _buildLeafClass(
        className: names.disableLeaf,
        serviceClassName: serviceClassName,
        commandName: 'disable',
        descriptionLiteral: _quoteLiteral('Disable ${meta.name}'),
        constructorBody: supportsForce ? _toggleForceFlagCode : '',
        returnType: 'Future<void>',
        isAsync: true,
        runBodyCode: _buildTryCatchCode(
          tryBody: disableTryBody,
          exceptionMessageLiteral: _quoteLiteral(
            'Failed to disable ${meta.name}',
          ),
        ),
      ),
      _buildLeafClass(
        className: names.statusLeaf,
        serviceClassName: serviceClassName,
        commandName: 'status',
        descriptionLiteral: _quoteLiteral('Get ${meta.name} status'),
        returnType: 'void',
        runBodyCode: _buildTryCatchCode(
          tryBody:
              '''
  final bool status = _service.${meta.status};
  logger.i('$escapedMetaName: \${status ? "enabled" : "disabled"}');
''',
          exceptionMessageLiteral: _quoteLiteral(
            'Failed to get ${meta.name} status',
          ),
        ),
      ),
    ];

    return _buildGroupWithLeaves(
      serviceClassName: serviceClassName,
      groupName: meta.name,
      names: names,
      leafClasses: toggleLeafClasses,
    );
  }

  _GeneratedGroup _buildValueGroup(
    String serviceClassName,
    GetterElement statusGetter,
    _CliMetaValue meta,
  ) {
    if (meta.setMethod == null) {
      throw InvalidGenerationSourceError(
        '@CliValue(name: "${meta.name}") requires explicit set method name.',
        element: statusGetter,
      );
    }

    final String valueType = statusGetter.returnType.getDisplayString(
      withNullability: false,
    );

    final String display = _pascal(meta.name);
    final groupClassName = '${display}Command';
    final statusLeafName = '_Status${display}Command';
    final setLeafName = '_Set${display}Command';
    final String escaped = _escapeForSingleQuotedString(meta.name);

    final Class statusLeafClass = _buildLeafClass(
      className: statusLeafName,
      serviceClassName: serviceClassName,
      commandNameLiteral: _quoteLiteral('status'),
      descriptionLiteral: _quoteLiteral('Get ${meta.name} status'),
      returnType: 'void',
      runBodyCode: _buildTryCatchCode(
        tryBody:
            '''
  final $valueType value = _service.${meta.status};
  logger.i('$escaped: \$value');
''',
        exceptionMessageLiteral: _quoteLiteral(
          'Failed to get ${meta.name} status',
        ),
      ),
    );

    final Class setLeafClass = _buildLeafClass(
      className: setLeafName,
      serviceClassName: serviceClassName,
      commandNameLiteral: _quoteLiteral('set'),
      descriptionLiteral: _quoteLiteral('Set ${meta.name} value'),
      constructorBody:
          '''
argParser.addOption(
  'value',
  mandatory: true,
  help: 'The new value (type: $valueType)',
);
''',
      returnType: 'Future<void>',
      isAsync: true,
      runBodyCode: _buildTryCatchCode(
        tryBody:
            '''
  final String valueStr = argResults!['value'] as String;
  final $valueType value = ${_generateValueParser(valueType, 'valueStr')};
  await _service.${meta.setMethod}(value);
  logger.i('$escaped set to \$valueStr');
''',
        exceptionMessageLiteral: _quoteLiteral('Failed to set ${meta.name}'),
      ),
    );

    final Class groupClass = _buildContainerClass(
      className: groupClassName,
      serviceClassName: serviceClassName,
      nameLiteral: _quoteLiteral(meta.name),
      descriptionLiteral: _quoteLiteral('${meta.name} command group'),
      subcommandClassNames: [statusLeafName, setLeafName],
    );

    return (
      className: groupClassName,
      specs: [groupClass, statusLeafClass, setLeafClass],
    );
  }

  _GeneratedLeaf _buildActionLeaf(
    String serviceClassName,
    String runMethodName,
    _CliMetaAction meta,
  ) {
    final String display = _pascal(meta.name);
    final className = '_Action${display}Command';
    return (
      className: className,
      spec: _buildLeafClass(
        className: className,
        serviceClassName: serviceClassName,
        commandNameLiteral: _quoteLiteral(meta.name),
        descriptionLiteral: _quoteLiteral('Run ${meta.name} action'),
        returnType: 'Future<void>',
        isAsync: true,
        runBodyCode: _buildTryCatchCode(
          tryBody:
              '''
  await _service.$runMethodName();
  logger.i('${_escapeForSingleQuotedString(meta.name)} completed');
''',
          exceptionMessageLiteral: _quoteLiteral('Failed to run ${meta.name}'),
        ),
      ),
    );
  }

  _GeneratedGroup _buildEnumGroup(
    String serviceClassName,
    ClassElement serviceElement,
    MethodElement status,
    _CliMetaEnum meta,
  ) {
    final String enumType = status.formalParameters.single.type
        .getDisplayString();
    final String? explicitEnableName = meta.enableMethodName;
    final String? explicitDisableName = meta.disableMethodName;
    if (explicitEnableName == null || explicitDisableName == null) {
      throw InvalidGenerationSourceError(
        '@CliEnumSubCommand(name: "${meta.name}") on method target requires both enable and disable function references.',
        element: status,
      );
    }
    final MethodElement? enableMethod = serviceElement.getMethod(
      explicitEnableName,
    );
    final MethodElement? disableMethod = serviceElement.getMethod(
      explicitDisableName,
    );
    if (enableMethod == null || disableMethod == null) {
      throw InvalidGenerationSourceError(
        '@CliEnumSubCommand(name: "${meta.name}") references unknown methods: enable=$explicitEnableName, disable=$explicitDisableName.',
        element: status,
      );
    }
    _validateEnumMemberSignature(
      function: enableMethod,
      enumType: enumType,
      field: 'enable',
      member: status,
    );
    _validateEnumMemberSignature(
      function: disableMethod,
      enumType: enumType,
      field: 'disable',
      member: status,
    );
    final _GroupLeafNames names = _groupLeafNames(_pascal(meta.name));
    final String escaped = _escapeForSingleQuotedString(meta.name);
    final parseHelper = '_parseEnumValue${_sanitizeEnumTypeName(enumType)}';
    final String optionName = _requireValidIdentifier(
      meta.argName,
      'enum argName',
    );
    final String constructorBody = _buildTargetOptionCode(
      optionName,
      enumType,
      meta.help.entries
          .map((e) => '${_quoteLiteral(e.key)}: ${_quoteLiteral(e.value)}')
          .join(', '),
    );
    return _buildGroupWithLeaves(
      serviceClassName: serviceClassName,
      groupName: meta.name,
      names: names,
      leafClasses: [
        _buildLeafClass(
          className: names.enableLeaf,
          serviceClassName: serviceClassName,
          commandName: 'enable',
          descriptionLiteral: _quoteLiteral(
            'Enable ${meta.name} ${meta.argName}',
          ),
          constructorBody: constructorBody,
          returnType: 'Future<void>',
          isAsync: true,
          runBodyCode: _buildTryCatchCode(
            tryBody:
                '''  final String modeStr = argResults!['$optionName'] as String;\n  final $enumType value = $parseHelper(modeStr);\n  await _service.$explicitEnableName(value);\n  logger.i('Enabled $escaped for \$modeStr');\n''',
            exceptionMessageLiteral: "'Operation failed'",
            enumUsageError: true,
          ),
        ),
        _buildLeafClass(
          className: names.disableLeaf,
          serviceClassName: serviceClassName,
          commandName: 'disable',
          descriptionLiteral: _quoteLiteral(
            'Disable ${meta.name} ${meta.argName}',
          ),
          constructorBody: constructorBody,
          returnType: 'Future<void>',
          isAsync: true,
          runBodyCode: _buildTryCatchCode(
            tryBody:
                '''  final String modeStr = argResults!['$optionName'] as String;\n  final $enumType value = $parseHelper(modeStr);\n  await _service.$explicitDisableName(value);\n  logger.i('Disabled $escaped for \$modeStr');\n''',
            exceptionMessageLiteral: "'Operation failed'",
            enumUsageError: true,
          ),
        ),
        _buildLeafClass(
          className: names.statusLeaf,
          serviceClassName: serviceClassName,
          commandName: 'status',
          descriptionLiteral: _quoteLiteral(
            'Get ${meta.name} ${meta.argName} status',
          ),
          constructorBody: constructorBody,
          returnType: 'void',
          runBodyCode: _buildTryCatchCode(
            tryBody:
                '''  final String modeStr = argResults!['$optionName'] as String;\n  final $enumType value = $parseHelper(modeStr);\n  final bool status = _service.${_memberName(status)}(value);\n  logger.i('$escaped (\$modeStr): \$status');\n''',
            exceptionMessageLiteral: "'Operation failed'",
            enumUsageError: true,
          ),
        ),
      ],
    );
  }

  _GeneratedGroup _buildEnumGroupFromGetter(
    String serviceClassName,
    ClassElement serviceElement,
    GetterElement statusGetter,
    _CliMetaEnum meta,
  ) {
    final String enumType = statusGetter.returnType.getDisplayString();
    final String statusName = _memberName(statusGetter);
    final String? explicitSetName = meta.setMethodName;
    if (explicitSetName == null) {
      throw InvalidGenerationSourceError(
        '@CliEnumSubCommand(name: "${meta.name}") on getter target requires a set function reference.',
        element: statusGetter,
      );
    }
    final MethodElement? setMethod = serviceElement.getMethod(explicitSetName);
    if (setMethod == null) {
      throw InvalidGenerationSourceError(
        '@CliEnumSubCommand(name: "${meta.name}") references unknown method: set=$explicitSetName.',
        element: statusGetter,
      );
    }
    _validateEnumMemberSignature(
      function: setMethod,
      enumType: enumType,
      field: 'set',
      member: statusGetter,
    );

    final String display = _pascal(meta.name);
    final groupClassName = '${display}Command';
    final statusLeafName = '_Status${display}Command';
    final setLeafName = '_Set${display}Command';
    final parseHelper = '_parseEnumValue${_sanitizeEnumTypeName(enumType)}';
    final String escaped = _escapeForSingleQuotedString(meta.name);
    final String optionName = _requireValidIdentifier(
      meta.argName,
      'enum argName',
    );
    final String constructorBody = _buildTargetOptionCode(
      optionName,
      enumType,
      meta.help.entries
          .map((e) => '${_quoteLiteral(e.key)}: ${_quoteLiteral(e.value)}')
          .join(', '),
    );

    final Class statusLeafClass = _buildLeafClass(
      className: statusLeafName,
      serviceClassName: serviceClassName,
      commandNameLiteral: _quoteLiteral('status'),
      descriptionLiteral: _quoteLiteral('Get current ${meta.name} mode'),
      returnType: 'void',
      runBodyCode: _buildTryCatchCode(
        tryBody:
            '''
  final $enumType status = _service.$statusName;
  logger.i('$escaped: \${status.name}');
''',
        exceptionMessageLiteral: "'Operation failed'",
      ),
    );

    final Class setLeafClass = _buildLeafClass(
      className: setLeafName,
      serviceClassName: serviceClassName,
      commandNameLiteral: _quoteLiteral('set'),
      descriptionLiteral: _quoteLiteral('Set ${meta.name} mode'),
      constructorBody: constructorBody,
      returnType: 'Future<void>',
      isAsync: true,
      runBodyCode: _buildTryCatchCode(
        tryBody:
            '''
  final String modeStr = argResults!['$optionName'] as String;
  final $enumType value = $parseHelper(modeStr);
  await _service.$explicitSetName(value);
  logger.i('Set $escaped to \$modeStr');
''',
        exceptionMessageLiteral: "'Operation failed'",
        enumUsageError: true,
      ),
    );

    final Class groupClass = _buildContainerClass(
      className: groupClassName,
      serviceClassName: serviceClassName,
      nameLiteral: _quoteLiteral(meta.name),
      descriptionLiteral: _quoteLiteral('${meta.name} command group'),
      subcommandClassNames: [statusLeafName, setLeafName],
    );

    return (
      className: groupClassName,
      specs: [groupClass, statusLeafClass, setLeafClass],
    );
  }

  Class _buildContainerClass({
    required String className,
    required String serviceClassName,
    required String nameLiteral,
    required String descriptionLiteral,
    required List<String> subcommandClassNames,
    bool isFinalClass = false,
  }) {
    final String constructorBody = subcommandClassNames
        .map((name) => 'addSubcommand($name(_service));')
        .join('\n');
    return Class(
      (b) => b
        ..modifier = isFinalClass ? .final$ : null
        ..name = className
        ..extend = refer(_serviceBaseClassName(serviceClassName))
        ..constructors.add(
          Constructor(
            (c) => c
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'service'
                    ..toSuper = true,
                ),
              )
              ..body = constructorBody.isEmpty ? null : Code(constructorBody),
          ),
        )
        ..methods.addAll([
          _buildGetterMethod('name', 'String', 'return $nameLiteral;'),
          _buildGetterMethod(
            'description',
            'String',
            'return $descriptionLiteral;',
          ),
          _buildRunMethod(
            returnType: 'void',
            bodyCode: const Code('printUsage();'),
          ),
        ]),
    );
  }

  Class _buildServiceBaseClass(String serviceClassName) {
    return Class(
      (b) => b
        ..name = _serviceBaseClassName(serviceClassName)
        ..abstract = true
        ..extend = refer('Command<void>')
        ..constructors.add(
          Constructor(
            (c) => c
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'service'
                    ..type = refer(serviceClassName),
                ),
              )
              ..initializers.add(const Code('_service = service')),
          ),
        )
        ..fields.add(
          Field(
            (f) => f
              ..name = '_service'
              ..type = refer(serviceClassName)
              ..modifier = .final$,
          ),
        ),
    );
  }

  String _serviceBaseClassName(String serviceClassName) =>
      '_${serviceClassName}CommandBase';

  _GroupLeafNames _groupLeafNames(String display) => (
    groupClass: '${display}Command',
    enableLeaf: '_Enable${display}Command',
    disableLeaf: '_Disable${display}Command',
    statusLeaf: '_Status${display}Command',
  );

  _GeneratedGroup _buildGroupWithLeaves({
    required String serviceClassName,
    required String groupName,
    required _GroupLeafNames names,
    required List<Class> leafClasses,
  }) {
    final Class groupClassSpec = _buildContainerClass(
      className: names.groupClass,
      serviceClassName: serviceClassName,
      nameLiteral: _quoteLiteral(groupName),
      descriptionLiteral: _quoteLiteral('$groupName command group'),
      subcommandClassNames: [
        names.enableLeaf,
        names.disableLeaf,
        names.statusLeaf,
      ],
    );
    return (
      className: names.groupClass,
      specs: [groupClassSpec, ...leafClasses],
    );
  }

  Class _buildLeafClass({
    required String className,
    required String serviceClassName,
    String? commandName,
    String? commandNameLiteral,
    required String descriptionLiteral,
    String constructorBody = '',
    required String returnType,
    bool isAsync = false,
    required Code runBodyCode,
  }) {
    final String resolvedCommandNameLiteral =
        commandNameLiteral ?? _quoteLiteral(commandName!);
    return Class(
      (b) => b
        ..name = className
        ..extend = refer(_serviceBaseClassName(serviceClassName))
        ..constructors.add(
          Constructor(
            (c) => c
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'service'
                    ..toSuper = true,
                ),
              )
              ..body = constructorBody.isEmpty ? null : Code(constructorBody),
          ),
        )
        ..methods.addAll([
          _buildGetterMethod(
            'name',
            'String',
            'return $resolvedCommandNameLiteral;',
          ),
          _buildGetterMethod(
            'description',
            'String',
            'return $descriptionLiteral;',
          ),
          _buildRunMethod(
            returnType: returnType,
            bodyCode: runBodyCode,
            isAsync: isAsync,
          ),
        ]),
    );
  }

  String _generateValueParser(String type, String valueVar) {
    switch (type) {
      case 'int':
        return 'int.parse($valueVar)';
      case 'double':
        return 'double.parse($valueVar)';
      case 'bool':
        return "($valueVar.toLowerCase() == 'true')";
      case 'String':
        return valueVar;
      default:
        throw InvalidGenerationSourceError(
          '@CliValue: unsupported parameter type "$type". Supported types: int, double, bool, String.',
        );
    }
  }

  Method _buildParseHelper(String enumType) {
    final helperName = '_parseEnumValue${_sanitizeEnumTypeName(enumType)}';
    return Method(
      (m) => m
        ..name = helperName
        ..returns = refer(enumType)
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer('String'),
          ),
        )
        ..body = Code('''
try {
  return $enumType.values.byName(value);
} on ArgumentError {
  final String allowed = $enumType.values.map((e) => e.name).join(', ');
  throw FormatException('Invalid value: \$value. Allowed: \$allowed');
}
'''),
    );
  }

  Method _buildGetterMethod(String name, String returnType, String body) {
    return Method(
      (m) => m
        ..annotations.add(refer('override'))
        ..type = MethodType.getter
        ..name = name
        ..returns = refer(returnType)
        ..body = Code(body),
    );
  }

  Method _buildRunMethod({
    required String returnType,
    required Code bodyCode,
    bool isAsync = false,
  }) {
    return Method(
      (m) => m
        ..annotations.add(refer('override'))
        ..name = 'run'
        ..returns = refer(returnType)
        ..modifier = isAsync ? .async : null
        ..body = bodyCode,
    );
  }

  Code _buildTryCatchCode({
    required String tryBody,
    required String exceptionMessageLiteral,
    bool enumUsageError = false,
  }) {
    final formatCatch = enumUsageError
        ? '''
   on FormatException catch (e) {
  logger.w('Invalid enum value', error: e);
  throw UsageException(e.message, usage);
}'''
        : '';
    return Code('''
try {
$tryBody
}$formatCatch on Exception catch (e, st) {
  logger.e($exceptionMessageLiteral, error: e, stackTrace: st);
  throw UsageException(e.toString(), usage);
}
''');
  }

  _CliMeta? _extractMeta(ExecutableElement member) {
    final DartObject? toggle = _cliToggleChecker.firstAnnotationOfExact(member);
    if (toggle != null) {
      final reader = ConstantReader(toggle);
      return _CliMetaToggle(
        reader.read('name').stringValue,
        _readIdentifierString(
          reader,
          'status',
          annotationName: 'CliToggle',
          member: member,
        ),
        enableMethod: _readIdentifierString(
          reader,
          'enable',
          annotationName: 'CliToggle',
          member: member,
        ),
        disableMethod: _readIdentifierString(
          reader,
          'disable',
          annotationName: 'CliToggle',
          member: member,
        ),
        enableForceMethod: reader.readOptionalString('enableForce'),
        disableForceMethod: reader.readOptionalString('disableForce'),
      );
    }

    final DartObject? value = _cliValueChecker.firstAnnotationOfExact(member);
    if (value != null) {
      final reader = ConstantReader(value);
      return _CliMetaValue(
        reader.read('name').stringValue,
        _readIdentifierString(
          reader,
          'status',
          annotationName: 'CliValue',
          member: member,
        ),
        setMethod: reader.readOptionalString('set'),
      );
    }

    final DartObject? action = _cliActionChecker.firstAnnotationOfExact(member);
    if (action != null) {
      final reader = ConstantReader(action);
      return _CliMetaAction(
        reader.read('name').stringValue,
        _readIdentifierString(
          reader,
          'run',
          annotationName: 'CliAction',
          member: member,
        ),
      );
    }

    final DartObject? enumMeta = _cliEnumChecker.firstAnnotationOfExact(member);
    if (enumMeta != null) {
      final reader = ConstantReader(enumMeta);
      final List<DartObject> values = reader.read('values').listValue;
      if (values.isEmpty) {
        throw InvalidGenerationSourceError(
          '@CliEnumSubCommand values must not be empty.',
          element: member,
        );
      }
      if (values.first.type == null) {
        throw InvalidGenerationSourceError(
          '@CliEnumSubCommand: could not resolve enum type. Check your imports.',
          element: member,
        );
      }
      return _CliMetaEnum(
        reader.read('name').stringValue,
        _readIdentifierString(
          reader,
          'status',
          annotationName: 'CliEnumSubCommand',
          member: member,
        ),
        argName: reader.read('argName').stringValue,
        enableMethodName: _validateOptionalIdentifier(
          reader.readOptionalString('enableMethod'),
          'enableMethod',
        ),
        disableMethodName: _validateOptionalIdentifier(
          reader.readOptionalString('disableMethod'),
          'disableMethod',
        ),
        setMethodName: _validateOptionalIdentifier(
          reader.readOptionalString('setMethod'),
          'setMethod',
        ),
        help: reader.readOptionalStringMap('help'),
      );
    }

    return null;
  }

  String _readIdentifierString(
    ConstantReader reader,
    String field, {
    required String annotationName,
    required Element member,
  }) {
    final String value = reader.read(field).stringValue;
    if (value.isEmpty) {
      throw InvalidGenerationSourceError(
        '@$annotationName requires a non-empty string "$field".',
        element: member,
      );
    }
    return _requireValidIdentifier(value, field);
  }

  String? _validateOptionalIdentifier(String? value, String field) =>
      value == null || value.isEmpty
      ? null
      : _requireValidIdentifier(value, field);

  bool _isValidToggleReturnType(DartType returnType) {
    if (returnType.getDisplayString(withNullability: false) == 'void') {
      return true;
    }
    if (returnType.isDartAsyncFuture && returnType is InterfaceType) {
      return returnType.typeArguments.isNotEmpty &&
          returnType.typeArguments.first.getDisplayString(
                withNullability: false,
              ) ==
              'void';
    }
    if (returnType.isDartAsyncFutureOr && returnType is InterfaceType) {
      return returnType.typeArguments.isNotEmpty &&
          returnType.typeArguments.first.getDisplayString(
                withNullability: false,
              ) ==
              'void';
    }
    return false;
  }

  String _buildTargetOptionCode(
    String optionName,
    String enumType,
    String allowedHelpEntries,
  ) {
    final String abbr = optionName.isEmpty ? 'm' : optionName[0];
    return '''
argParser.addOption(
  '$optionName',
  abbr: '$abbr',
  mandatory: true,
  allowed: $enumType.values.map((e) => e.name).toList(),
  allowedHelp: {$allowedHelpEntries},
);
''';
  }

  String _sanitizeEnumTypeName(String enumType) =>
      enumType.replaceAll(_genericCharsPattern, '');

  void _validateEnumMemberSignature({
    required MethodElement function,
    required String enumType,
    required String field,
    required Element member,
  }) {
    final List<FormalParameterElement> required = function.formalParameters
        .where((p) => p.isRequiredPositional)
        .toList(growable: false);
    if (required.length != 1 ||
        function.formalParameters.any(
          (p) => p.isOptionalPositional || p.isNamed,
        )) {
      throw InvalidGenerationSourceError(
        '@CliEnumSubCommand $field must accept exactly one required positional enum parameter.',
        element: member,
      );
    }
    if (required.single.type.getDisplayString(withNullability: false) !=
        enumType) {
      throw InvalidGenerationSourceError(
        '@CliEnumSubCommand $field parameter must be $enumType, but found ${required.single.type.getDisplayString()}.',
        element: member,
      );
    }
    if (!_isValidToggleReturnType(function.returnType)) {
      throw InvalidGenerationSourceError(
        '@CliEnumSubCommand $field must return void, Future<void>, or FutureOr<void>, but found ${function.returnType.getDisplayString()}.',
        element: member,
      );
    }
  }

  String _pascal(String input) {
    final String candidate = input.toCliPascal();
    return _requireValidIdentifier(candidate, '');
  }

  String _memberName(Element e) => _requireValidIdentifier(e.displayName, '');
  String _requireValidIdentifier(String v, [String? context]) =>
      _dartIdentifierPattern.hasMatch(v)
      ? v
      : (throw InvalidGenerationSourceError('Invalid identifier: $v'));

  String _escapeForSingleQuotedString(String value) {
    return value.escapeForSingleQuotedString();
  }

  String _quoteLiteral(String value) =>
      "'${_escapeForSingleQuotedString(value)}'";
}

extension _ConstantReaderX on ConstantReader {
  String? readOptionalString(String field) {
    final ConstantReader? valueReader = peek(field);
    if (valueReader == null || valueReader.isNull) return null;
    if (valueReader.isString) return valueReader.stringValue;
    throw InvalidGenerationSourceError(
      '@CliEnumSubCommand $field must be a string method name.',
    );
  }

  Map<String, String> readOptionalStringMap(String field) {
    final ConstantReader? valueReader = peek(field);
    if (valueReader == null || valueReader.isNull) return const {};
    final result = <String, String>{};
    for (final MapEntry<DartObject?, DartObject?> entry
        in valueReader.mapValue.entries) {
      final String? key = entry.key?.toStringValue();
      final String? value = entry.value?.toStringValue();
      if (key == null || value == null) continue;
      result[key] = value;
    }
    return result;
  }
}

extension _CliStringX on String {
  String toCliPascal() {
    final List<String> words = split(
      RegExp(r'[^A-Za-z0-9]+'),
    ).where((w) => w.isNotEmpty).toList(growable: false);
    if (words.isEmpty) return 'Generated';
    final String candidate = words
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join();
    return CliCommandGenerator._leadingDigitPattern.hasMatch(candidate)
        ? 'Cli$candidate'
        : candidate;
  }

  String escapeForSingleQuotedString() => replaceAll('\u005C', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t')
      .replaceAll('\b', r'\b')
      .replaceAll('\f', r'\f')
      .replaceAll('\x00', r'\x00');
}

typedef _GeneratedGroup = ({String className, List<Spec> specs});
typedef _GeneratedLeaf = ({String className, Class spec});
typedef _GroupLeafNames = ({
  String groupClass,
  String enableLeaf,
  String disableLeaf,
  String statusLeaf,
});

sealed class _CliMeta {
  const _CliMeta(this.name, this.status);
  final String name;
  final String status;
}

class _CliMetaToggle extends _CliMeta {
  const _CliMetaToggle(
    super.name,
    super.status, {
    required this.enableMethod,
    required this.disableMethod,
    this.enableForceMethod,
    this.disableForceMethod,
  });

  final String enableMethod;
  final String disableMethod;
  final String? enableForceMethod;
  final String? disableForceMethod;
}

class _CliMetaValue extends _CliMeta {
  const _CliMetaValue(super.name, super.status, {this.setMethod});
  final String? setMethod;
}

class _CliMetaAction extends _CliMeta {
  const _CliMetaAction(String name, this.runMethod) : super(name, '');

  final String runMethod;
}

class _CliMetaEnum extends _CliMeta {
  const _CliMetaEnum(
    super.name,
    super.status, {
    required this.argName,
    this.enableMethodName,
    this.disableMethodName,
    this.setMethodName,
    required this.help,
  });
  final String argName;
  final String? enableMethodName;
  final String? disableMethodName;
  final String? setMethodName;
  final Map<String, String> help;
}

const _toggleForceFlagCode = '''
argParser.addFlag(
  'force',
  abbr: 'f',
  negatable: false,
  help: 'Force operation when supported by this toggle.',
);
''';
