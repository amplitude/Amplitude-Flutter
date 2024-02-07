/// Used for [Ampli](https://www.docs.developers.amplitude.com/data/sdks/ampli-overview/) to represent an Amplitude tracking plan
class Plan {
  String? branch;
  String? source;
  String? version;
  String? versionId;

  Plan({
    this.branch,
    this.source,
    this.version,
    this.versionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'branch': branch,
      'source': source,
      'version': version,
      'versionId': versionId,
    };
  }
}
