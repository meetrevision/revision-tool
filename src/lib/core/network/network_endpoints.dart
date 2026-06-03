enum GitHubRepositoryEndpoint {
  revisionTool(api: 'meetrevision/revision-tool'),
  cabPackages(api: 'meetrevision/packages');

  const GitHubRepositoryEndpoint({required this.api});

  final String api;
}

abstract final class NetworkEndpoints {
  static const String microsoftUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0';

  static Uri githubLatestRelease(GitHubRepositoryEndpoint endpoint) {
    return Uri.https('api.github.com', '/repos/${endpoint.api}/releases/latest');
  }
}
