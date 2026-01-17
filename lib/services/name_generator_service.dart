/** This file generates fun name suggestions based on the cat breed and personality detected */
class NameGeneratorService {
  // Generates 5 random cat names based on breed and personality traits
  static List<String> generateNames(String breed, String personality) {
    List<String> suggestedNames = [];

    // Add names based on Breed
    if (breed.contains('Persian') || breed.contains('Ragdoll')) {
      suggestedNames
          .addAll(['Fluffy', 'Cloud', 'Prince', 'Princess', 'Snowball']);
    } else if (breed.contains('Bengal') || breed.contains('Egyptian')) {
      suggestedNames.addAll(['Leo', 'Tiger', 'Hunter', 'Simba', 'Nala']);
    } else if (breed.contains('Siamese') || breed.contains('Sphynx')) {
      suggestedNames.addAll(['Luna', 'Mochi', 'Yoda', 'Kiki', 'Gizmo']);
    } else if (breed.contains('Maine Coon')) {
      suggestedNames.addAll(['Thor', 'Zeus', 'Bear', 'Hagrid', 'Lion']);
    } else {
      suggestedNames.addAll(['Mittens', 'Whiskers', 'Felix', 'Luna', 'Oreo']);
    }

    // Add names based on Personality
    if (personality.contains('Social Butterfly')) {
      suggestedNames.addAll(['Happy', 'Sunny', 'Buddy', 'Daisy', 'Joy']);
    } else if (personality.contains('Hunter') ||
        personality.contains('Energetic')) {
      suggestedNames.addAll(['Sparky', 'Bolt', 'Rocky', 'Zelda', 'Sonic']);
    } else if (personality.contains('Cuddle Bug') ||
        personality.contains('Affectionate')) {
      suggestedNames.addAll(['Lovey', 'Sweetie', 'Honey', 'Baby', 'Cuddles']);
    } else {
      suggestedNames.addAll(['Shadow', 'Misty', 'Lucky', 'Scout']);
    }

    // Shuffle and return top 5
    suggestedNames.shuffle();
    return suggestedNames.take(5).toList();
  }
}
