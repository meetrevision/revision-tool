class const KGLModel({
    required final String uri,
    required final String hash,
    required final int version,
    required final int activateOnUpdate,
    required final int versionCheckTimeout,
  }) {
  factory fromJson(Map<String, dynamic> json) {
    return KGLModel(
      uri: json['URI'] as String,
      hash: json['HASH'] as String,
      version: int.parse(json['VERSION'] as String),
      activateOnUpdate: int.parse(json['ACTIVATEONUPDATE'] as String),
      versionCheckTimeout: int.parse(json['VERSIONCHECKTIMEOUT'] as String),
    );
  }
}
