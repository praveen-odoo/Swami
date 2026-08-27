/// ============================================================
///  RAZORPAY CONFIG  —  EK HI JAGAH ID BADALNA HAI
/// ============================================================
///
/// Niche abhi Razorpay ka TEST key hai (demo ke liye). Isse test
/// payment chal jaayega par asli paisa nahi katega.
///
/// PRODUCTION ke liye: apne Razorpay dashboard se LIVE "Key Id"
/// le kar niche wali line mein daal do. Bas itna hi.
///
///   https://dashboard.razorpay.com/  ->  Settings -> API Keys
///
/// NOTE: Key Id hi app mein daalte hain. Key SECRET kabhi app mein
/// mat daalna — woh sirf aapke server par rehta hai (order banane &
/// payment verify karne ke liye).
class PaymentConfig {
  PaymentConfig._();

  /// Razorpay "Key Id". Updated with correct casing (rzp_live_T8c9EPfZ65PsIh)
  static const String razorpayKeyId = 'rzp_live_T8c9EPfZ65PsIh';
}
