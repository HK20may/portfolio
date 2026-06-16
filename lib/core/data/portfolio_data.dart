import '../theme/app_colors.dart';
import 'models.dart';

/// Single source of truth for everything shown on the site.
/// Edit here to update content — no widget changes required.
abstract final class PortfolioData {
  static const Profile profile = Profile(
    name: 'Harshit Kumawat',
    roles: [
      'Flutter Developer',
      'Cross-Platform Engineer',
      'Motion & UI Craftsman',
    ],
    tagline:
        'I build cross-platform apps that feel alive — shipped to state '
        'governments and to millions of everyday users.',
    about: [
      'I\'m a Flutter developer with 4+ years turning ambitious product ideas '
          'into fast, fluid apps across Android, iOS, web and desktop. I care '
          'about the details most people only feel: spring physics, motion '
          'that guides the eye, and interfaces that respond the instant you '
          'touch them.',
      'I\'ve carried apps from first commit to the hands of real users — '
          'smart-energy platforms for the Uttar Pradesh and Manipur '
          'governments, a SaaS commerce app with 50k+ downloads, and a '
          'quick-commerce app that crossed a million. I lean on Clean '
          'Architecture and disciplined state management so polish never comes '
          'at the cost of maintainability.',
    ],
    location: 'Jaipur, India',
    email: 'HK20may@gmail.com',
    phone: '+91 81070 98228',
    socials: [
      SocialLink(label: 'GitHub', url: 'https://github.com/HK20may'),
      SocialLink(
        label: 'LinkedIn',
        url: 'https://www.linkedin.com/in/harshit-kumawat-4680b0192/',
      ),
      SocialLink(label: 'Twitter / X', url: 'https://x.com/harshitk20may'),
      SocialLink(label: 'Email', url: 'mailto:HK20may@gmail.com'),
    ],
    stats: [
      Stat(value: '4+', label: 'Years building'),
      Stat(value: '1M+', label: 'Downloads shipped'),
      Stat(value: '4', label: 'Platforms'),
      Stat(value: '3', label: 'Product teams'),
    ],
  );

  static const List<SkillGroup> skillGroups = [
    SkillGroup(
      title: 'Languages',
      items: ['Dart', 'Java', 'Kotlin', 'Swift', 'C++'],
    ),
    SkillGroup(
      title: 'Frameworks & State',
      items: ['Flutter', 'BLoC', 'Riverpod', 'GetX', 'Provider'],
    ),
    SkillGroup(
      title: 'Data & Backend',
      items: [
        'Firebase',
        'Firestore',
        'SQLite',
        'Hive',
        'REST APIs',
        'MySQL',
      ],
    ),
    SkillGroup(
      title: 'Platforms & Delivery',
      items: [
        'Android',
        'iOS',
        'Web',
        'Desktop',
        'Git',
        'CI/CD',
        'Codemagic',
      ],
    ),
  ];

  /// Marquee strip — a fast scan of the toolkit.
  static const List<String> marquee = [
    'Flutter',
    'Dart',
    'BLoC',
    'Clean Architecture',
    'Firebase',
    'Riverpod',
    'GetX',
    'Isolates',
    'Animations',
    'Shaders',
    'REST',
    'CI/CD',
    'Kotlin',
    'Swift',
  ];

  static const List<Experience> experiences = [
    Experience(
      company: 'Polaris',
      role: 'Cross-Platform Developer',
      location: 'Jaipur, India',
      period: 'Mar 2024 — Present',
      blurb:
          'Smart-energy metering for state governments. I build the apps that '
          'let citizens monitor consumption, recharge and manage their '
          'connections across every device.',
      highlights: [
        'Shipped cross-platform apps (Android, iOS, web) for the Uttar Pradesh '
            'and Manipur governments, serving smart-meter users at scale.',
        'Architected with BLoC + Clean Architecture for modular, testable, '
            'maintainable code.',
        'Integrated the Firebase suite — Crashlytics, Analytics, In-App '
            'Messaging, Push, Remote Config and Performance Monitoring.',
        'Hardened the apps with secure storage, encryption and privacy-'
            'compliant communication.',
      ],
      tags: ['Flutter', 'BLoC', 'Clean Architecture', 'Firebase', 'Web'],
      accent: AppColors.violet,
    ),
    Experience(
      company: 'NowFloats',
      role: 'Flutter Developer · Mobile App Lead',
      location: 'Hyderabad, India',
      period: 'Dec 2022 — Mar 2024',
      blurb:
          'Led mobile for Zadinga, a SaaS commerce app (50k+ downloads) '
          'spanning Android, iOS, web and desktop from a single Flutter '
          'codebase.',
      highlights: [
        'Owned the app across four platforms, deploying to Play Store, App '
            'Store and the web.',
        'Built complex search, list filtering and pagination over live '
            'observable data, with efficient stream and isolate management.',
        'Combined BLoC and GetX under an MVVM structure for clean, testable '
            'features.',
        'Implemented Force & Flexible in-app updates and CI/CD on Azure and '
            'Firebase.',
      ],
      tags: ['Flutter', 'GetX', 'MVVM', 'Isolates', 'CI/CD'],
      accent: AppColors.cyan,
    ),
    Experience(
      company: 'Fraazo',
      role: 'Software Developer',
      location: 'Mumbai, India',
      period: 'Jul 2021 — Nov 2022',
      blurb:
          'Quick-commerce at national scale. Built and shipped features for '
          'the Fraazo app (1M+ downloads) in a fast-moving FMCG startup.',
      highlights: [
        'Designed responsive, adaptive UIs for a consistent experience across '
            'screen sizes and orientations.',
        'Integrated REST APIs, local databases and third-party packages '
            'throughout the app.',
        'Drove engagement with Firebase push, deep links, Crashlytics and A/B '
            'testing.',
        'Used Riverpod with an MVC structure, wrote unit tests and shipped '
            'in-app updates.',
      ],
      tags: ['Flutter', 'Riverpod', 'A/B Testing', 'Deep Links', 'Testing'],
      accent: AppColors.pink,
    ),
  ];

  static const List<Project> projects = [
    Project(
      id: 'smart-energy',
      title: 'Smart Energy Platform',
      subtitle: 'Government smart-metering, in citizens\' pockets',
      context: 'Polaris · Android, iOS & Web',
      description:
          'Cross-platform apps for the Uttar Pradesh and Manipur governments '
          'that let smart-meter users monitor consumption, recharge and access '
          'connection services. Built on Clean Architecture with the full '
          'Firebase suite and real-time feature toggling via Remote Config.',
      year: '2024',
      tags: ['Flutter', 'BLoC', 'Clean Architecture', 'Firebase', 'Security'],
      highlights: [
        'Android, iOS and a responsive Flutter Web build from one codebase',
        'Remote Config-driven personalisation without app updates',
        'Secure storage, encryption and privacy-compliant comms',
      ],
      accent: AppColors.violet,
      metric: 'Statewide rollout',
    ),
    Project(
      id: 'zadinga',
      title: 'Zadinga',
      subtitle: 'SaaS commerce, everywhere a business sells',
      context: 'NowFloats · Android, iOS, Web & Desktop',
      description:
          'A SaaS commerce app I led across four platforms. The hard parts '
          'lived in the data layer: search, filtering and pagination over live '
          'observable streams, plus isolate-backed processing to keep the UI '
          'buttery under load.',
      year: '2023',
      tags: ['Flutter', 'GetX', 'MVVM', 'Isolates', 'Payments'],
      highlights: [
        '50k+ downloads across Play Store, App Store and web',
        'Live search, filtering and pagination on observable data',
        'Force & Flexible in-app updates with CI/CD',
      ],
      accent: AppColors.cyan,
      metric: '50k+ downloads',
    ),
    Project(
      id: 'fraazo',
      title: 'Fraazo',
      subtitle: 'Quick-commerce groceries at a million-plus scale',
      context: 'Fraazo · Android & iOS',
      description:
          'Features for a quick-commerce FMCG app that crossed a million '
          'downloads. Responsive, adaptive UIs paired with Firebase-driven '
          'engagement — deep links, push, Crashlytics and A/B testing — under '
          'a Riverpod + MVC structure.',
      year: '2022',
      tags: ['Flutter', 'Riverpod', 'A/B Testing', 'Deep Links'],
      highlights: [
        '1M+ downloads on a fast-moving consumer app',
        'Adaptive layouts across every screen size',
        'A/B testing and deep links for growth',
      ],
      accent: AppColors.pink,
      metric: '1M+ downloads',
    ),
    Project(
      id: 'stock-prediction',
      title: 'Stock Price Prediction',
      subtitle: 'Modelling tomorrow\'s prices with Monte Carlo',
      context: 'Personal · Python',
      description:
          'A simulation engine that estimates future stock prices using Monte '
          'Carlo methods over Geometric Brownian Motion, calibrated on '
          'historical data to produce probabilistic forecasts.',
      year: '2022',
      tags: ['Python', 'Monte Carlo', 'GBM', 'Quant'],
      highlights: [
        'Geometric Brownian Motion price paths',
        'Monte Carlo simulation over historical data',
        'Probabilistic forecasting',
      ],
      accent: AppColors.mint,
      link: 'https://github.com/HK20may',
    ),
    Project(
      id: 'foodie',
      title: 'Foodie',
      subtitle: 'A food-delivery app with three sides to the story',
      context: 'Personal · Java & Android',
      description:
          'A native Android food-delivery app modelling the full marketplace: '
          'customers place orders, chefs accept or reject them, and delivery '
          'partners pick up and deliver — each role with its own flow.',
      year: '2021',
      tags: ['Java', 'Android', 'Realtime', 'Marketplace'],
      highlights: [
        'Customer, chef and delivery-partner roles',
        'Order lifecycle from placement to delivery',
        'Native Android with Java',
      ],
      accent: AppColors.amber,
      link: 'https://github.com/HK20may',
    ),
  ];

  static Project? projectById(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }
}
