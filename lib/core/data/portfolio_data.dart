import '../theme/app_colors.dart';
import 'models.dart';

/// Single source of truth for everything shown on the site.
/// Edit here to update content — no widget changes required.
abstract final class PortfolioData {
  static const Profile profile = Profile(
    name: 'Harshit Kumawat',
    roles: [
      'Software Developer 3',
      'Cross-Platform Engineer',
      'Flutter Developer',
      'Motion & UI Craftsman',
      'Techie Enthusiast',
    ],
    tagline: 'I build cross-platform products people actually feel — '
        'now going full-stack.',
    about: [
      'I\'m a Software Developer 3 with 4+ years turning ambitious product ideas '
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
      'Currently expanding into backend engineering with Go — building REST '
          'and gRPC services, working with PostgreSQL and Docker. The same '
          'care I put into UI motion goes into API design.',
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
    SkillGroup(
      title: 'Backend & Systems',
      items: [
        'Go (learning)',
        'REST',
        'gRPC',
        'PostgreSQL',
        'Docker',
        'Firebase',
        'WebSockets',
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
      blurb: 'Led mobile for Zadinga, a SaaS commerce app (50k+ downloads) '
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
      blurb: 'Quick-commerce at national scale. Built and shipped features for '
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
          'The Polaris Smart Energy Platform brings electricity connection '
          'management to mobile and web for the Uttar Pradesh and Manipur '
          'state governments. I built the complete cross-platform suite — '
          'Android, iOS, and a responsive Flutter Web app — on a BLoC + '
          'Clean Architecture backbone, serving metered households at scale. '
          'The app handles real-time consumption monitoring, prepaid '
          'recharges, service requests, and outage reporting across every '
          'device class, with the full Firebase suite wired in for '
          'reliability and feature agility.',
      year: '2024',
      tags: ['Flutter', 'BLoC', 'Clean Architecture', 'Firebase', 'Security'],
      highlights: [
        'Single Flutter codebase shipped to Android, iOS, and Flutter Web '
            'across two state governments at scale',
        'BLoC + Clean Architecture: feature modules, repository pattern, '
            'and strict use-case boundaries for long-term maintainability',
        'Full Firebase suite: Crashlytics, Analytics, Push, In-App '
            'Messaging, Performance Monitoring, and Remote Config',
        'Remote Config feature flags let the ops team toggle UX per state '
            'without requiring a new release',
        'Secure local storage with AES encryption; privacy-compliant data '
            'handling following government guidelines',
        'Responsive layouts tested from 4" budget phones to 27" desktop '
            'browsers with a single layout system',
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
          'Zadinga is a SaaS commerce platform that empowers SMBs to run '
          'their online stores. I was the sole mobile lead at NowFloats, '
          'owning the Flutter app across all four platforms — Android, iOS, '
          'web, and desktop. The most demanding technical work was the data '
          'layer: live-observable product and order streams backed by '
          'reactive GetX state management, isolate-backed search to keep the '
          'main thread free, and a sophisticated filter/sort/pagination '
          'engine that stayed buttery under thousands of SKUs.',
      year: '2023',
      tags: ['Flutter', 'GetX', 'MVVM', 'Isolates', 'Payments'],
      highlights: [
        '50k+ downloads across Play Store, App Store, web, and desktop '
            'from a single Flutter codebase',
        'Live search, multi-dimensional filtering, and cursor-based '
            'pagination over GetX observables — never a jank frame',
        'Background Isolate processing for heavy list operations so the '
            'UI thread stays at 60 fps regardless of catalogue size',
        'Force & Flexible in-app update flows with gradual rollout '
            'managed through Azure and Firebase CI/CD pipelines',
        'MVVM + GetX module architecture that two new engineers could '
            'onboard to and ship features in their first week',
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
          'Fraazo was a quick-commerce startup delivering fresh produce in '
          'under 30 minutes across metro India. I built and shipped '
          'consumer-facing features for the app as it scaled past a million '
          'downloads. My work spanned adaptive product catalog layouts, '
          'deep-link attribution for growth campaigns, Firebase A/B '
          'experiments, and a real-time order tracker that updated live '
          'as the delivery partner moved toward the customer.',
      year: '2022',
      tags: ['Flutter', 'Riverpod', 'A/B Testing', 'Deep Links', 'Testing'],
      highlights: [
        '1M+ downloads on a fast-moving consumer app with a zero-crash SLA '
            'maintained through Crashlytics monitoring',
        'Adaptive product catalog grid for every screen from 4" budget '
            'phones to 10" tablets without separate layout code',
        'Firebase A/B testing across multiple concurrent experiments '
            'driving measurable engagement and conversion uplift',
        'Deep link integration enabling social sharing, referral '
            'incentives, and re-engagement push campaigns',
        'Riverpod + MVC structure with full unit-test coverage of '
            'business logic and critical cart/checkout flows',
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
          'A Monte Carlo simulation engine for probabilistic stock price '
          'forecasting. The model calibrates annualised drift (μ) and '
          'volatility (σ) from historical daily log-returns, then runs '
          'hundreds of Geometric Brownian Motion paths forward in time. '
          'The Flutter frontend here fetches live closing prices from '
          'Twelvedata (NSE and US tickers) and runs the simulation off the '
          'main thread in a Dart isolate, rendering all paths and the '
          'P5–P95 confidence cone in a single-canvas CustomPainter.',
      year: '2022',
      tags: ['Python', 'Monte Carlo', 'GBM', 'Quant'],
      highlights: [
        'GBM model auto-calibrates μ and σ from up to 400 days of '
            'historical log-returns fetched from Twelvedata API',
        '300+ Monte Carlo paths computed in a Dart background isolate — '
            'the UI never drops a frame during simulation',
        'P5–P95 confidence cone and mean path rendered in one draw call '
            'via a custom CombinedPainter canvas',
        'Live NSE (₹) and US (\$) ticker support with currency-aware '
            'formatting and graceful offline fallback',
      ],
      accent: AppColors.mint,
      link: 'https://github.com/HK20may',
    ),
    Project(
      id: 'sorting-visualizer',
      title: 'Sorting Visualizer',
      subtitle: 'Watch algorithms race through data',
      context: 'Personal · Flutter',
      description: 'An interactive educational tool for understanding sorting '
          'algorithms. Five classic algorithms — Bubble, Selection, '
          'Insertion, Quick, and Merge — are implemented as step generators '
          'that pre-record every comparison, swap, and overwrite. A Ticker '
          'replays the steps at user-controlled speed in a CustomPainter '
          'canvas. Comparing bars light amber, swaps flash pink, and '
          'settled elements turn mint, giving each algorithm a distinct '
          'visual signature that makes its character immediately readable.',
      year: '2024',
      tags: ['Flutter', 'CustomPainter', 'Algorithms', 'Animation'],
      highlights: [
        'Five algorithm implementations: Bubble, Selection, Insertion, '
            'Quick Sort (Lomuto partition), and Merge Sort',
        'Step-generator pattern pre-computes all operations; rendering '
            'and algorithm logic are fully decoupled',
        'Adjustable speed from 10 to 250 steps/second — slow enough '
            'to trace by eye, fast enough to race algorithms',
        'Live status line narrates each step in plain English, making '
            'the logic transparent to non-CS audiences',
        'Bar value labels and per-algorithm blurb turn it into a '
            'self-contained learning tool',
      ],
      accent: AppColors.amber,
      metric: '5 algorithms',
    ),
    Project(
      id: 'pathfinding',
      title: 'Pathfinding Visualizer',
      subtitle: 'A* finds its way through any maze you draw',
      context: 'Personal · Flutter',
      description:
          'An interactive grid-based pathfinding explorer. Drag to paint '
          'walls in real time, then run A*, Dijkstra, or BFS to watch '
          'the algorithm explore the grid cell by cell. Frontier cells '
          'pulse amber as they are queued, visited cells fill violet as '
          'the algorithm marches outward, and the optimal path traces '
          'cyan once the goal is reached. All search logic is pre-run '
          'and its events replayed at a configurable frame rate by a '
          'Ticker, fully decoupling algorithm from rendering.',
      year: '2024',
      tags: ['Flutter', 'A*', 'Graphs', 'Animation'],
      highlights: [
        'Three search algorithms: A* (Manhattan heuristic), Dijkstra '
            '(uniform cost, h = 0), and BFS (breadth-first queue)',
        'Drag-to-paint walls with automatic draw/erase mode toggle '
            'for fluid maze creation before running any search',
        'Stepwise event replay at adjustable speed fully decouples '
            'the search algorithm from the animation layer',
        'Five visually distinct cell states — start, goal, frontier, '
            'visited, and path — each distinctly colour-coded',
        'Full path reconstruction via a cameFrom map; reports "No '
            'path found" clearly when the goal is unreachable',
      ],
      accent: AppColors.mint,
      metric: 'A* · Dijkstra · BFS',
    ),
  ];

  static Project? projectById(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }
}
