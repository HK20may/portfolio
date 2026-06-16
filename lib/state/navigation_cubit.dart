import 'package:flutter_bloc/flutter_bloc.dart';

/// Ordered sections of the single-page site.
enum Section { hero, about, skills, work, experience, contact }

extension SectionLabel on Section {
  String get label => switch (this) {
        Section.hero => 'Home',
        Section.about => 'About',
        Section.skills => 'Skills',
        Section.work => 'Work',
        Section.experience => 'Experience',
        Section.contact => 'Contact',
      };
}

/// Tracks which section is currently in view so the nav can highlight it and
/// nav clicks can scroll to the right place. Updated by [Section] visibility
/// detectors on the home page.
class NavigationCubit extends Cubit<Section> {
  NavigationCubit() : super(Section.hero);

  void setActive(Section section) {
    if (state != section) emit(section);
  }
}
