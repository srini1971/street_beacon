/// Represents the major official and regional languages of India
/// for localized emergency dispatch (112 / 108 / local police).
enum IndianLanguage {
  kannada('Kannada', 'kn'),
  tamil('Tamil', 'ta'),
  telugu('Telugu', 'te'),
  marathi('Marathi', 'mr'),
  malayalam('Malayalam', 'ml'),
  hindi('Hindi', 'hi'),
  bengali('Bengali', 'bn'),
  gujarati('Gujarati', 'gu'),
  punjabi('Punjabi', 'pa'),
  odia('Odia', 'or'),
  assamese('Assamese', 'as'),
  english('English', 'en');

  /// Human-readable English name of the language.
  final String languageName;

  /// ISO 639-1 code.
  final String code;

  const IndianLanguage(this.languageName, this.code);

  /// Automatically maps an Indian State or Union Territory name to its primary official regional language.
  static IndianLanguage fromState(String? stateName) {
    if (stateName == null) return IndianLanguage.english;

    final normalized = stateName.trim().toLowerCase();

    if (normalized.contains('karnataka')) {
      return IndianLanguage.kannada;
    } else if (normalized.contains('tamil nadu') || normalized.contains('puducherry')) {
      return IndianLanguage.tamil;
    } else if (normalized.contains('telangana') || normalized.contains('andhra')) {
      return IndianLanguage.telugu;
    } else if (normalized.contains('maharashtra') || normalized.contains('goa')) {
      return IndianLanguage.marathi;
    } else if (normalized.contains('kerala') || normalized.contains('lakshadweep')) {
      return IndianLanguage.malayalam;
    } else if (normalized.contains('bengal')) {
      return IndianLanguage.bengali;
    } else if (normalized.contains('gujarat')) {
      return IndianLanguage.gujarati;
    } else if (normalized.contains('punjab') || normalized.contains('chandigarh')) {
      return IndianLanguage.punjabi;
    } else if (normalized.contains('odisha') || normalized.contains('orissa')) {
      return IndianLanguage.odia;
    } else if (normalized.contains('assam')) {
      return IndianLanguage.assamese;
    } else if (normalized.contains('delhi') ||
        normalized.contains('uttar pradesh') ||
        normalized.contains('madhya pradesh') ||
        normalized.contains('rajasthan') ||
        normalized.contains('bihar') ||
        normalized.contains('haryana') ||
        normalized.contains('himachal') ||
        normalized.contains('uttarakhand') ||
        normalized.contains('jharkhand') ||
        normalized.contains('chhattisgarh') ||
        normalized.contains('jammu') ||
        normalized.contains('kashmir') ||
        normalized.contains('ladakh')) {
      return IndianLanguage.hindi;
    }

    // Default to English for other states/regions
    return IndianLanguage.english;
  }
}

/// Provides localized emergency translations across Indian regional languages.
class RegionalTranslations {
  /// Localized alert title (e.g. "ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ (EMERGENCY ASSISTANCE)").
  static String getAlertPrefix(IndianLanguage language) {
    switch (language) {
      case IndianLanguage.kannada:
        return 'ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ (EMERGENCY ASSISTANCE)';
      case IndianLanguage.tamil:
        return 'அவசர உதவி தேவை (EMERGENCY ASSISTANCE)';
      case IndianLanguage.telugu:
        return 'అత్యవసర సహాయం కావాలి (EMERGENCY ASSISTANCE)';
      case IndianLanguage.marathi:
        return 'तातडीची मदत हवी आहे (EMERGENCY ASSISTANCE)';
      case IndianLanguage.malayalam:
        return 'അടിയന്തര സഹായം ആവശ്യമാണ് (EMERGENCY ASSISTANCE)';
      case IndianLanguage.hindi:
        return 'आपातकालीन सहायता चाहिए (EMERGENCY ASSISTANCE)';
      case IndianLanguage.bengali:
        return 'জরুরী সাহায্য প্রয়োজন (EMERGENCY ASSISTANCE)';
      case IndianLanguage.gujarati:
        return 'તાત્કાલિક સહાયની જરૂર છે (EMERGENCY ASSISTANCE)';
      case IndianLanguage.punjabi:
        return 'ਐਮਰਜੈਂਸੀ ਮਦਦ ਚਾਹੀਦੀ ਹੈ (EMERGENCY ASSISTANCE)';
      case IndianLanguage.odia:
        return 'ଜରୁରୀ ସାହାଯ୍ୟ ଦରକାର (EMERGENCY ASSISTANCE)';
      case IndianLanguage.assamese:
        return 'জৰুৰীকালীন সাহায্যৰ প্ৰয়োজন (EMERGENCY ASSISTANCE)';
      case IndianLanguage.english:
        return 'EMERGENCY ASSISTANCE';
    }
  }

  /// Localized spoken phrase for the phone call with 112 / 108.
  static String getSpokenPrompt({
    required IndianLanguage language,
    required String cityName,
    required int distanceKm,
    required String compassDirection,
    bool mentionSms = true,
  }) {
    switch (language) {
      case IndianLanguage.kannada:
        final loc = distanceKm < 5
            ? '$cityName ವ್ಯಾಪ್ತಿಯಲ್ಲಿದ್ದೇನೆ'
            : '$cityName ನಗರದಿಂದ ಸುಮಾರು $distanceKm ಕಿ.ಮೀ $compassDirection ಭಾಗದಲ್ಲಿದ್ದೇನೆ';
        final smsNote = mentionSms
            ? ' ನಾನು SMS ಮೂಲಕ ಲೈವ್ ಮ್ಯಾಪ್ ಲೊಕೇಶನ್ ಕಳುಹಿಸಿದ್ದೇನೆ.'
            : '';
        return 'ತುರ್ತು ಸಹಾಯ ಬೇಕಾಗಿದೆ! ನಾನು $loc.$smsNote';

      case IndianLanguage.tamil:
        final loc = distanceKm < 5
            ? '$cityName பகுதியில் இருக்கிறேன்'
            : '$cityName நகரத்திலிருந்து சுமார் $distanceKm கி.மீ $compassDirection திசையில் இருக்கிறேன்';
        final smsNote = mentionSms
            ? ' SMS மூலம் எனது லைவ் மேப் இருப்பிடத்தை அனுப்பியுள்ளேன்.'
            : '';
        return 'அவசர உதவி தேவை! நான் $loc.$smsNote';

      case IndianLanguage.telugu:
        final loc = distanceKm < 5
            ? '$cityName పరిధిలో ఉన్నాను'
            : '$cityName నుండి సుమారు $distanceKm కి.మీ $compassDirection దిశలో ఉన్నాను';
        final smsNote = mentionSms
            ? ' నేను SMS ద్వారా లైవ్ మ్యాప్ లొకేషన్ పంపాను.'
            : '';
        return 'అత్యవసర సహాయం కావాలి! నేను $loc.$smsNote';

      case IndianLanguage.marathi:
        final loc = distanceKm < 5
            ? '$cityName जवळ आहे'
            : '$cityName पासून अंदाजे $distanceKm किमी $compassDirection दिशेला आहे';
        final smsNote = mentionSms
            ? ' मी SMS द्वारे माझे लाइव्ह मॅप लोकेशन पाठवले आहे.'
            : '';
        return 'तातडीची मदत हवी आहे! मी $loc.$smsNote';

      case IndianLanguage.malayalam:
        final loc = distanceKm < 5
            ? '$cityName സമീപത്താണ്'
            : '$cityName നിന്നും ഏകദേശം $distanceKm കി.മീ $compassDirection ഭാഗത്താണ്';
        final smsNote = mentionSms
            ? ' ഞാൻ SMS വഴി തത്സമയ മാപ്പ് ലൊക്കേഷൻ അയച്ചിട്ടുണ്ട്.'
            : '';
        return 'അടിയന്തര സഹായം ആവശ്യമാണ്! ഞാൻ $loc.$smsNote';

      case IndianLanguage.hindi:
        final loc = distanceKm < 5
            ? '$cityName के पास हूँ'
            : '$cityName से लगभग $distanceKm किमी $compassDirection दिशा में हूँ';
        final smsNote = mentionSms
            ? ' मैंने SMS द्वारा अपना लाइव मैप लोकेशन भेजा है।'
            : '';
        return 'आपातकालीन सहायता चाहिए! मैं $loc।$smsNote';

      case IndianLanguage.bengali:
        final loc = distanceKm < 5
            ? '$cityName এর কাছে আছি'
            : '$cityName থেকে প্রায় $distanceKm কিমি $compassDirection দিকে আছি';
        final smsNote = mentionSms
            ? ' আমি SMS এর মাধ্যমে লাইভ ম্যাপ লোকেশন পাঠিয়েছি।'
            : '';
        return 'জরুরী সাহায্য প্রয়োজন! আমি $loc।$smsNote';

      case IndianLanguage.gujarati:
        final loc = distanceKm < 5
            ? '$cityName નજીક છું'
            : '$cityName થી આશરે $distanceKm કિમી $compassDirection દિશામાં છું';
        final smsNote = mentionSms
            ? ' મેં SMS દ્વારા મારું લાઇવ મેપ લોકેશન મોકલ્યું છે.'
            : '';
        return 'તાત્કાલિક સહાયની જરૂર છે! હું $loc.$smsNote';

      case IndianLanguage.punjabi:
        final loc = distanceKm < 5
            ? '$cityName ਦੇ ਨੇੜੇ ਹਾਂ'
            : '$cityName ਤੋਂ ਲਗਭਗ $distanceKm ਕਿਲੋਮੀਟਰ $compassDirection ਵੱਲ ਹਾਂ';
        final smsNote = mentionSms
            ? ' ਮੈਂ SMS ਰਾਹੀਂ ਆਪਣੀ ਲਾਈਵ ਮੈਪ ਲੋਕੇਸ਼ਨ ਭੇਜ ਦਿੱਤੀ ਹੈ।'
            : '';
        return 'ਐਮਰਜੈਂਸੀ ਮਦਦ ਚਾਹੀਦੀ ਹੈ! ਮੈਂ $loc।$smsNote';

      case IndianLanguage.odia:
        final loc = distanceKm < 5
            ? '$cityName ପାଖରେ ଅଛି'
            : '$cityName ଠାରୁ ପ୍ରାୟ $distanceKm କିମି $compassDirection ଦିଗରେ ଅଛି';
        final smsNote = mentionSms
            ? ' ମୁଁ SMS ମାଧ୍ୟମରେ ଲାଇଭ୍ ମ୍ୟାପ୍ ଲୋକେସନ୍ ପଠାଇଛି।'
            : '';
        return 'ଜରୁରୀ ସାହାଯ୍ୟ ଦରକାର! ମୁଁ $loc।$smsNote';

      case IndianLanguage.assamese:
        final loc = distanceKm < 5
            ? '$cityName ৰ ওচৰত আছোঁ'
            : '$cityName ৰ পৰা প্ৰায় $distanceKm কিলোমিটাৰ $compassDirection দিশত আছোঁ';
        final smsNote = mentionSms
            ? ' মই SMS যোগে লাইভ মেপ লোকেচন পঠিয়াইছোঁ।'
            : '';
        return 'জৰুৰীকালীন সাহায্যৰ প্ৰয়োজন! মই $loc।$smsNote';

      case IndianLanguage.english:
        final loc = distanceKm < 5
            ? 'in or near $cityName'
            : 'approximately $distanceKm km $compassDirection of $cityName';
        final smsNote = mentionSms
            ? ' I have also sent my exact live map location to your control room by SMS.'
            : '';
        return 'Emergency! I need assistance. I am located $loc.$smsNote';
    }
  }

  /// Phonetic transliteration guide in English for travelers who cannot read the native regional script.
  static String getPronunciationGuide({
    required IndianLanguage language,
    required String cityName,
    required int distanceKm,
    required String compassDirection,
  }) {
    switch (language) {
      case IndianLanguage.kannada:
        return 'Thurtu sahaya bekagide! Naanu $cityName inda sumaaru $distanceKm km $compassDirection nalliddene.';
      case IndianLanguage.tamil:
        return 'Avasara udhavi thevai! Naan $cityName ilirundhu sumaar $distanceKm km $compassDirection thirathil irukiren.';
      case IndianLanguage.telugu:
        return 'Athyavasara sahayam kaavali! Nenu $cityName nunchi sumaaru $distanceKm km $compassDirection dishalo unnanu.';
      case IndianLanguage.marathi:
        return 'Taatdichi madat havi aahe! Mee $cityName pasun andaaje $distanceKm km $compassDirection dishela aahe.';
      case IndianLanguage.malayalam:
        return 'Adiyanthara sahaayam aavashyamaanu! Njaan $cityName ninnu eakadhesham $distanceKm km $compassDirection bhaagathaannu.';
      case IndianLanguage.hindi:
        return 'Aapatkaleen sahayata chahiye! Main $cityName se lagbhag $distanceKm km $compassDirection disha mein hoon.';
      case IndianLanguage.bengali:
        return 'Joruri sahajjo proyojon! Aami $cityName theke pray $distanceKm km $compassDirection dike aachi.';
      case IndianLanguage.gujarati:
        return 'Tatkalik sahay ni jaroor chhe! Hoon $cityName thi aashre $distanceKm km $compassDirection dishama chhoon.';
      case IndianLanguage.punjabi:
        return 'Emergency madad chahidi hai! Main $cityName ton lagbhag $distanceKm km $compassDirection val haan.';
      case IndianLanguage.odia:
        return 'Jaruri sahayya darkar! Mun $cityName tharu praye $distanceKm km $compassDirection digare achhi.';
      case IndianLanguage.assamese:
        return 'Jorurikalin sahajyo proyojon! Moi $cityName r pora pray $distanceKm km $compassDirection dixot asu.';
      case IndianLanguage.english:
        return 'Emergency! I need assistance near $cityName.';
    }
  }
}
