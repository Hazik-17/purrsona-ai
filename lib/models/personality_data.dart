import 'package:flutter/material.dart';

/// Personality type info and care tips from quiz results
class PersonalityProfile {
  final String id;
  final String title;
  final String description;
  final String careTip;
  final IconData icon;

  const PersonalityProfile({
    required this.id,
    required this.title,
    required this.description,
    required this.careTip,
    required this.icon,
  });
}

// All the personality types and what they mean
class PersonalityDatabase {
  static const Map<String, PersonalityProfile> profiles = {
    'social': PersonalityProfile(
      id: 'social',
      title: "The Social Butterfly",
      description: "This cat loves to be the center of attention! They greet guests at the door, follow you from room to room, and thrive on interaction.",
      careTip: "Ensure they have plenty of playtime and consider getting them a companion if you work long hours.",
      icon: Icons.groups_rounded,
    ),
    'playful': PersonalityProfile(
      id: 'playful',
      title: "The Energetic Hunter",
      description: "A ball of energy with a high prey drive. They love chasing lasers, pouncing on toys, and climbing to the highest point in the room.",
      careTip: "Provide vertical spaces (cat trees) and rotate interactive toys to keep them mentally stimulated.",
      icon: Icons.sports_esports_rounded,
    ),
    'affectionate': PersonalityProfile(
      id: 'affectionate',
      title: "The Cuddle Bug",
      description: "The ultimate lap cat. They value comfort and closeness above all else, often purring the moment you look at them.",
      careTip: "Create cozy nooks with soft blankets. They bond best through gentle grooming and quiet cuddle sessions.",
      icon: Icons.favorite_rounded,
    ),
    'balanced': PersonalityProfile(
      id: 'balanced',
      title: "The Balanced Companion",
      description: "The perfect mix of independent and loving. They are content doing their own thing but happy to say hello when you walk in.",
      careTip: "They are adaptable but appreciate a consistent routine. A mix of solo toys and interactive play works best.",
      icon: Icons.balance_rounded,
    ),
  };

  static PersonalityProfile getProfile(String trait) {
    return profiles[trait.toLowerCase()] ?? profiles['balanced']!;
  }
}