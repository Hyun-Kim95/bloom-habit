/// Google Play / App Store Connect에 **동일한 ID**로 등록해야 합니다.
abstract class MonetizationProductIds {
  MonetizationProductIds._();

  static const String removeAds = 'remove_ads';
  static const String donationSmall = 'donation_small';
  static const String donationMedium = 'donation_medium';

  static const Set<String> all = {
    removeAds,
    donationSmall,
    donationMedium,
  };

  static bool isDonation(String id) =>
      id == donationSmall || id == donationMedium;
}
