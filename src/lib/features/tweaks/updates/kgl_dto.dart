class KGLModel {
  const KGLModel({
    required this.uri,
    required this.hash,
    required this.version,
    required this.activateOnUpdate,
    required this.versionCheckTimeout,
  });

  factory KGLModel.fromJson(final Map<String, dynamic> json) {
    return KGLModel(
      uri: json['URI'] as String,
      hash: json['HASH'] as String,
      version: int.parse(json['VERSION'] as String),
      activateOnUpdate: int.parse(json['ACTIVATEONUPDATE'] as String),
      versionCheckTimeout: int.parse(json['VERSIONCHECKTIMEOUT'] as String),
    );
  }
  final String uri;
  final String hash;
  final int version;
  final int activateOnUpdate;
  final int versionCheckTimeout;
}
