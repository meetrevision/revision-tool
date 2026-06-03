abstract final class MSStoreEndpoints {
  static Uri search({
    required String query,
    required String market,
    required String locale,
    required String mediaType,
    required String age,
    required String price,
    required String category,
    required String subscription,
  }) {
    return Uri.https('apps.microsoft.com', '/api/products/search', {
      'gl': market,
      'hl': locale,
      'query': query,
      'mediaType': mediaType,
      'age': age,
      'price': price,
      'category': category,
      'subscription': subscription,
    });
  }

  static Uri productDetails({
    required String productId,
    required String market,
    required String locale,
  }) {
    return Uri.https(
      'apps.microsoft.com',
      '/api/ProductsDetails/GetProductDetailsById/$productId',
      {'gl': market, 'hl': locale},
    );
  }

  static Uri category({
    required String productId,
    required String market,
    required String locale,
    required String deviceFamily,
  }) {
    return Uri.https(
      'storeedgefd.dsx.mp.microsoft.com',
      '/v9.0/products/$productId',
      {'market': market, 'locale': locale, 'deviceFamily': deviceFamily},
    );
  }

  static Uri packageManifest({
    required String productId,
    required String market,
  }) {
    return Uri.https(
      'storeedgefd.dsx.mp.microsoft.com',
      '/v9.0/packageManifests/$productId',
      {'Market': market},
    );
  }

  static Uri fe3Delivery({bool secured = false}) {
    return Uri.https(
      'fe3.delivery.mp.microsoft.com',
      secured
          ? '/ClientWebService/client.asmx/secured'
          : '/ClientWebService/client.asmx',
    );
  }
}
