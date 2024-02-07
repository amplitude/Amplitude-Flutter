class IngestionMetadata {
  String? sourceName;
  String? sourceVersion;

  IngestionMetadata({
    this.sourceName,
    this.sourceVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourceName': sourceName,
      'sourceVersion': sourceVersion,
    };
  }
}
