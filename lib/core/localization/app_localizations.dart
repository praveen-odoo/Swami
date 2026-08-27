import 'package:flutter/material.dart';

/// Lightweight, dependency-free localization.
/// Add a key once in BOTH maps and use it anywhere with `context.tr('key')`.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('hi')];

  static final Map<String, Map<String, String>> _values = {
    'en': {
      // Chat & Call
      'sandesh': 'Messages',
      'chatLoginTitle': 'Connect to Satsang',
      'chatLoginSubtitle': 'Sign in to chat and call within the community.',
      'noChats': 'No conversations yet',
      'typeMessage': 'Type a message…',
      'voiceCall': 'Voice call',
      'videoCall': 'Video call',
      'callFailed': 'Call could not be started.',
      // Payment (Razorpay)
      'paymentProcessing': 'Opening secure payment…',
      'paymentSuccess': 'Payment successful! Thank you for your seva 🙏',
      'paymentFailed': 'Payment failed or cancelled. Please try again.',
      'paymentError': 'Could not start payment. Please try again.',
      // General
      'appName': 'Swami Anand Swaroop',
      'tagline': 'A sacred companion for your spiritual journey',
      'viewAll': 'View all',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save changes',
      'comingSoon': 'This feature is coming soon',
      'search': 'Search',
      'minutes': 'min',
      'optional': 'Optional',
      'newBadge': 'NEW',

      // Auth
      'welcomeBack': 'Welcome back',
      'loginSubtitle': 'Sign in to continue your spiritual journey',
      'createAccount': 'Create account',
      'signupSubtitle': 'Begin your journey with Swami Anand Swaroop ji',
      'fullName': 'Full name',
      'email': 'Email address',
      'phone': 'Mobile number',
      'password': 'Password',
      'confirmPassword': 'Confirm password',
      'login': 'Sign in',
      'signup': 'Sign up',
      'forgotPassword': 'Forgot password?',
      'resetPassword': 'Reset password',
      'resetSubtitle':
          'Enter your registered email and we will reset your password.',
      'newPassword': 'New password',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'orContinueWith': 'or',
      'logout': 'Log out',
      'logoutConfirm': 'Are you sure you want to log out?',
      'agreeTerms': 'I agree to the Terms of Service and Privacy Policy',
      'mustAgreeTerms': 'Please accept the terms to continue',
      'accountCreated': 'Account created. Welcome!',
      'passwordResetDone': 'Password updated. Please sign in.',
      'invalidCredentials': 'Email or password is incorrect',
      'emailAlreadyUsed': 'An account with this email already exists',
      'emailNotFound': 'No account found with this email',

      // Validation
      'requiredField': 'This field is required',
      'invalidName': 'Enter your real name (letters only, min 3)',
      'invalidEmail': 'Enter a valid email address',
      'invalidPhone': 'Enter a valid 10-digit mobile number',
      'weakPassword':
          'Min 8 characters with a letter, a number and a symbol',
      'passwordMismatch': 'Passwords do not match',
      'invalidAmount': 'Enter a valid amount (min ₹11)',

      // Navigation
      'home': 'Home',
      'pravachan': 'Discourses',
      'bhajan': 'Bhajans',
      'more': 'More',
      'gallery': 'Gallery',
      'events': 'Events',
      'books': 'Books',
      'donation': 'Seva & Daan',
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'languageSubtitle': 'Choose your preferred language',

      // Home
      'namaste': 'OM Namo Narayan',
      'todaysQuote': "Today's Amrit Vachan",
      'dailySankalp': 'Daily Sankalp',
      'sankalpDone': 'Sankalp complete for today 🙏',
      'markDone': 'Mark as done',
      'latestPravachan': 'Latest discourses',
      'upcomingEvents': 'Upcoming events',
      'quickActions': 'Quick actions',
      'liveSatsang': 'Live Satsang',
      'aartiTimings': 'Aarti timings',
      'morningAarti': 'Morning Aarti',
      'eveningAarti': 'Evening Aarti',
      'aboutSwamiTitle': 'Shambhavi Peethadhishwar Swami Anand Swaroop ji',
      'aboutSwamiTagline': 'Dedicated to social welfare and nation-building',
      'aboutSwamiBody':
          'For over 18 years, Swami Anand Swaroop ji has devoted himself to the propagation of Sanatan Vedic Dharma, service to the Ganga, and cow protection. His resolve is "Service to humanity is service to God." Under his leadership, more than 1,000 girls have been married and thousands of orphaned children have been educated.',
      'impactKanyaVivah': '1000+ Kanya Vivah',
      'impactGangaSeva': '18+ yrs Ganga Seva',
      'impactTempleRenovation': '70+ Temples Restored',
      'sankalpMantra': 'Chant the guru-mantra 11 times',
      'ourSevaWork': 'Our Seva Work',

      // Pravachan
      'allPravachan': 'All discourses',
      'watchNow': 'Watch now',
      'aboutPravachan': 'About this discourse',

      // Bhajan
      'nowPlaying': 'Now playing',
      'bhajanList': 'Bhajan sangrah',

      // Events
      'register': 'Register',
      'registered': 'Registered 🙏',
      'venue': 'Venue',

      // Books
      'readSample': 'Read sample',

      // Donation
      'donationSubtitle':
          'Your seva supports annadaan, gaushala and gurukul education.',
      'selectAmount': 'Select amount',
      'customAmount': 'Custom amount (₹)',
      'donorName': 'Name on receipt',
      'guptDaan': 'Donate Anonymously (Gupt Daan)',
      'proceedToPay': 'Proceed to payment',
      'notifications': 'Notifications',
      'chatAuthPrompt': 'Please sign in to chat',
      'donationThanks': 'Thank you for your seva! (Demo: no real payment)',
      'donationPurpose': 'Purpose of seva',
      'annadaan': 'Annadaan',
      'gaushala': 'Gaushala seva',
      'education': 'Gurukul education',
      'templeSeva': 'Temple seva',

      // Profile
      'editProfile': 'Edit profile',
      'profileUpdated': 'Profile updated',
      'memberSince': 'Member since',
      'myBookmarks': 'My bookmarks',
      'aboutApp': 'About this app',
      'aboutAppBody':
          'This app is dedicated to Swami Anand Swaroop ji, featuring his pravachans, bhajans, and spiritual guidance.',

      // Guest mode & extras
      'guest': 'Guest',
      'continueAsGuest': 'Continue as guest',
      'loginRequired': 'Sign in required',
      'loginRequiredBody':
          'Please sign in to use this feature. It only takes a moment.',
      'guestPrompt':
          'Sign in to access your profile, seva, sankalp and event registration.',
      'videoError': 'Video could not be loaded. Check your connection.',
      'audioError': 'Audio could not be loaded. Check your connection.',
      'connectWithUs': 'Connect with us',
      'website': 'Website',
      'facebook': 'Facebook',
      'youtube': 'YouTube',
      'instagram': 'Instagram',
      'twitter': 'Twitter (X)',
      'whatsapp': 'WhatsApp',
      'connect': 'Connect',
      'complain': 'Register Complaint',
      'complainSubtitle': 'Let us know if you have any issues',
      'complainTitle': 'Issue Title',
      'complainDescription': 'Description',
      'complainSubmit': 'Submit Complaint',
      'complainSuccess': 'Complaint registered successfully',
      'complainSuccessGuest': 'Your complaint has been registered. Please note your reference number or take a screenshot for future reference.',
      'complainRef': 'Reference Number',
      'myComplaints': 'My Complaints',
      'noComplaints': 'No complaints registered yet.',
      'guestName': 'Your Name',
      'guestMobile': 'Mobile Number',
      'networkErrorTitle': 'No Internet Connection',
      'networkErrorSubtitle': 'Please check your connection and try again.',
    },
    'hi': {
      // Chat & Call
      'sandesh': 'संदेश',
      'chatLoginTitle': 'सत्संग से जुड़ें',
      'chatLoginSubtitle': 'समुदाय में चैट व कॉल हेतु साइन इन करें।',
      'noChats': 'अभी कोई बातचीत नहीं',
      'typeMessage': 'संदेश लिखें…',
      'voiceCall': 'वॉइस कॉल',
      'videoCall': 'वीडियो कॉल',
      'callFailed': 'कॉल आरंभ नहीं हो सकी।',
      // Payment (Razorpay)
      'paymentProcessing': 'सुरक्षित भुगतान खुल रहा है…',
      'paymentSuccess': 'भुगतान सफल! आपकी सेवा हेतु धन्यवाद 🙏',
      'paymentFailed': 'भुगतान असफल या रद्द। कृपया पुनः प्रयास करें।',
      'paymentError': 'भुगतान आरंभ नहीं हो सका। कृपया पुनः प्रयास करें।',
      // General
      'appName': 'स्वामी आनंद स्वरूप',
      'tagline': 'आपकी आध्यात्मिक यात्रा का पावन साथी',
      'viewAll': 'सभी देखें',
      'retry': 'पुनः प्रयास करें',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'comingSoon': 'यह सुविधा जल्द आ रही है',
      'search': 'खोजें',
      'minutes': 'मिनट',
      'optional': 'वैकल्पिक',
      'newBadge': 'नया',

      // Auth
      'welcomeBack': 'पुनः स्वागत है',
      'loginSubtitle': 'अपनी आध्यात्मिक यात्रा जारी रखने हेतु साइन इन करें',
      'createAccount': 'खाता बनाएँ',
      'signupSubtitle': 'स्वामी आनंद स्वरूप जी के साथ अपनी यात्रा आरंभ करें',
      'fullName': 'पूरा नाम',
      'email': 'ईमेल पता',
      'phone': 'मोबाइल नंबर',
      'password': 'पासवर्ड',
      'confirmPassword': 'पासवर्ड की पुष्टि करें',
      'login': 'साइन इन',
      'signup': 'साइन अप',
      'forgotPassword': 'पासवर्ड भूल गए?',
      'resetPassword': 'पासवर्ड रीसेट करें',
      'resetSubtitle':
          'अपना पंजीकृत ईमेल दर्ज करें, हम आपका पासवर्ड रीसेट कर देंगे।',
      'newPassword': 'नया पासवर्ड',
      'dontHaveAccount': 'खाता नहीं है?',
      'alreadyHaveAccount': 'पहले से खाता है?',
      'orContinueWith': 'अथवा',
      'logout': 'लॉग आउट',
      'logoutConfirm': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',
      'agreeTerms': 'मैं सेवा-शर्तों एवं गोपनीयता नीति से सहमत हूँ',
      'mustAgreeTerms': 'आगे बढ़ने हेतु कृपया शर्तें स्वीकार करें',
      'accountCreated': 'खाता बन गया। स्वागत है!',
      'passwordResetDone': 'पासवर्ड बदल गया। कृपया साइन इन करें।',
      'invalidCredentials': 'ईमेल या पासवर्ड गलत है',
      'emailAlreadyUsed': 'इस ईमेल से खाता पहले से मौजूद है',
      'emailNotFound': 'इस ईमेल से कोई खाता नहीं मिला',

      // Validation
      'requiredField': 'यह फ़ील्ड आवश्यक है',
      'invalidName': 'कृपया सही नाम लिखें (केवल अक्षर, न्यूनतम 3)',
      'invalidEmail': 'मान्य ईमेल पता दर्ज करें',
      'invalidPhone': 'मान्य 10 अंकों का मोबाइल नंबर दर्ज करें',
      'weakPassword':
          'न्यूनतम 8 अक्षर — एक अक्षर, एक अंक व एक चिह्न आवश्यक',
      'passwordMismatch': 'पासवर्ड मेल नहीं खाते',
      'invalidAmount': 'मान्य राशि दर्ज करें (न्यूनतम ₹11)',

      // Navigation
      'home': 'मुखपृष्ठ',
      'pravachan': 'प्रवचन',
      'bhajan': 'भजन',
      'more': 'अन्य',
      'gallery': 'गैलरी',
      'events': 'उत्सव',
      'books': 'ग्रंथ',
      'donation': 'सेवा व दान',
      'profile': 'प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'languageSubtitle': 'अपनी पसंदीदा भाषा चुनें',

      // Home
      'namaste': 'ॐ नमो नारायण',
      'todaysQuote': 'आज का अमृत वचन',
      'dailySankalp': 'दैनिक संकल्प',
      'sankalpDone': 'आज का संकल्प पूर्ण 🙏',
      'markDone': 'पूर्ण करें',
      'latestPravachan': 'नवीनतम प्रवचन',
      'upcomingEvents': 'आगामी उत्सव',
      'quickActions': 'त्वरित सेवाएँ',
      'liveSatsang': 'लाइव सत्संग',
      'aartiTimings': 'आरती समय',
      'morningAarti': 'प्रातः आरती',
      'eveningAarti': 'संध्या आरती',
      'aboutSwamiTitle': 'शांभवी पीठाधीश्वर स्वामी आनंद स्वरूप जी',
      'aboutSwamiTagline': 'समाज कल्याण और राष्ट्र निर्माण के प्रति समर्पित',
      'aboutSwamiBody':
          'स्वामी आनंद स्वरूप जी ने पिछले १८ वर्षों से अधिक समय सनातन वैदिक धर्म के प्रचार, गंगा सेवा और गौ-संरक्षण के लिए समर्पित किया है। उनका संकल्प है "मानव सेवा ही माधव सेवा"। उनके नेतृत्व में १,००० से अधिक कन्याओं का विवाह और हज़ारों अनाथ बच्चों की शिक्षा का कार्य संपन्न हुआ है।',
      'impactKanyaVivah': '१०००+ कन्या विवाह',
      'impactGangaSeva': '१८+ वर्ष गंगा सेवा',
      'impactTempleRenovation': '७०+ मंदिर जीर्णोद्धार',
      'sankalpMantra': '११ बार गुरु-मंत्र जप',
      'ourSevaWork': 'हमारे सेवा कार्य',

      // Pravachan
      'allPravachan': 'सभी प्रवचन',
      'watchNow': 'अभी देखें',
      'aboutPravachan': 'इस प्रवचन के विषय में',

      // Bhajan
      'nowPlaying': 'अभी चल रहा है',
      'bhajanList': 'भजन संग्रह',

      // Events
      'register': 'पंजीकरण करें',
      'registered': 'पंजीकृत 🙏',
      'venue': 'स्थान',

      // Books
      'readSample': 'अंश पढ़ें',

      // Donation
      'donationSubtitle':
          'आपकी सेवा अन्नदान, गौशाला एवं गुरुकुल शिक्षा में सहयोग करती है।',
      'selectAmount': 'राशि चुनें',
      'customAmount': 'अपनी राशि (₹)',
      'donorName': 'रसीद पर नाम',
      'guptDaan': 'गुप्त दान (Anonymous Donation)',
      'proceedToPay': 'भुगतान हेतु आगे बढ़ें',
      'notifications': 'सूचनाएं',
      'chatAuthPrompt': 'चैट करने के लिए कृपया साइन इन करें',
      'donationThanks': 'आपकी सेवा हेतु धन्यवाद! (डेमो: वास्तविक भुगतान नहीं)',
      'donationPurpose': 'सेवा का उद्देश्य',
      'annadaan': 'अन्नदान',
      'gaushala': 'गौशाला सेवा',
      'education': 'गुरुकुल शिक्षा',
      'templeSeva': 'मंदिर सेवा',

      // Profile
      'editProfile': 'प्रोफ़ाइल संपादित करें',
      'profileUpdated': 'प्रोफ़ाइल अपडेट हो गई',
      'memberSince': 'सदस्यता तिथि',
      'myBookmarks': 'मेरे बुकमार्क',
      'aboutApp': 'ऐप के विषय में',
      'aboutAppBody':
          'यह ऐप स्वामी आनंद स्वरूप जी को समर्पित है, जिसमें उनके प्रवचन, भजन और आध्यात्मिक मार्गदर्शन शामिल हैं।',

      // Guest mode & extras
      'guest': 'अतिथि',
      'continueAsGuest': 'अतिथि रूप में जारी रखें',
      'loginRequired': 'साइन इन आवश्यक',
      'loginRequiredBody':
          'इस सुविधा का उपयोग करने हेतु कृपया साइन इन करें। इसमें बस एक क्षण लगेगा।',
      'guestPrompt':
          'प्रोफ़ाइल, सेवा, संकल्प व उत्सव पंजीकरण हेतु साइन इन करें।',
      'videoError': 'वीडियो लोड नहीं हो सका। कृपया इंटरनेट जाँचें।',
      'audioError': 'ऑडियो लोड नहीं हो सका। कृपया इंटरनेट जाँचें।',
      'connectWithUs': 'हमसे जुड़ें',
      'website': 'वेबसाइट',
      'facebook': 'फेसबुक',
      'youtube': 'यूट्यूब',
      'instagram': 'इंस्टाग्राम',
      'twitter': 'ट्विटर (X)',
      'whatsapp': 'व्हाट्सएप',
      'connect': 'जुड़ें',
      'complain': 'शिकायत दर्ज करें',
      'complainSubtitle': 'यदि आपको कोई समस्या है तो हमें बताएं',
      'complainTitle': 'शिकायत का शीर्षक',
      'complainDescription': 'विवरण',
      'complainSubmit': 'शिकायत भेजें',
      'complainSuccess': 'शिकायत सफलतापूर्वक दर्ज की गई',
      'complainSuccessGuest': 'आपकी शिकायत दर्ज कर ली गई है। भविष्य के संदर्भ के लिए कृपया अपना संदर्भ नंबर नोट करें या स्क्रीनशॉट लें।',
      'complainRef': 'संदर्भ संख्या',
      'myComplaints': 'मेरी शिकायतें',
      'noComplaints': 'अभी तक कोई शिकायत दर्ज नहीं की गई है।',
      'guestName': 'आपका नाम',
      'guestMobile': 'मोबाइल नंबर',
      'networkErrorTitle': 'इंटरनेट कनेक्शन नहीं है',
      'networkErrorSubtitle': 'कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।',
    },
  };

  String tr(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  bool get isHindi => locale.languageCode == 'hi';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Handy extension: `context.tr('home')`.
extension LocalizationX on BuildContext {
  String tr(String key) => AppLocalizations.of(this).tr(key);
  bool get isHindi => AppLocalizations.of(this).isHindi;
}
