import 'package:flutter/material.dart';

@immutable
class SocialLink {
  const SocialLink({required this.label, required this.url});
  final String label;
  final String url;
}

@immutable
class Profile {
  const Profile({
    required this.name,
    required this.roles,
    required this.tagline,
    required this.about,
    required this.location,
    required this.email,
    required this.phone,
    required this.socials,
    required this.stats,
  });

  final String name;
  final List<String> roles; // cycled in the hero
  final String tagline;
  final List<String> about; // paragraphs
  final String location;
  final String email;
  final String phone;
  final List<SocialLink> socials;
  final List<Stat> stats;
}

@immutable
class Stat {
  const Stat({required this.value, required this.label});
  final String value;
  final String label;
}

@immutable
class SkillGroup {
  const SkillGroup({required this.title, required this.items});
  final String title;
  final List<String> items;
}

@immutable
class Experience {
  const Experience({
    required this.company,
    required this.role,
    required this.location,
    required this.period,
    required this.blurb,
    required this.highlights,
    required this.tags,
    required this.accent,
  });

  final String company;
  final String role;
  final String location;
  final String period;
  final String blurb;
  final List<String> highlights;
  final List<String> tags;
  final Color accent;
}

@immutable
class Project {
  const Project({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.context,
    required this.description,
    required this.year,
    required this.tags,
    required this.highlights,
    required this.accent,
    this.metric,
    this.link,
  });

  final String id;
  final String title;
  final String subtitle;
  final String context; // company / platform context
  final String description;
  final String year;
  final List<String> tags;
  final List<String> highlights;
  final Color accent;
  final String? metric; // e.g. "1M+ downloads"
  final String? link;
}
