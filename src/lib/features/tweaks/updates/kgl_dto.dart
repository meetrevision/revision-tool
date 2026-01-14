class KGLModel {
  final String uri;
  final String hash;
  final int version;
  final int activateOnUpdate;
  final int versionCheckTimeout;

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
      version: int.parse(json['VERSION']),
      activateOnUpdate: int.parse(json['ACTIVATEONUPDATE']),
      versionCheckTimeout: int.parse(json['VERSIONCHECKTIMEOUT']),
    );
  }
}
