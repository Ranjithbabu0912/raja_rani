enum GameRole { raja, rani, manthiri, sippai, police, thirudan }

extension GameRoleExtension on GameRole {
  String get displayName {
    switch (this) {
      case GameRole.raja:
        return 'Raja';

      case GameRole.rani:
        return 'Rani';

      case GameRole.manthiri:
        return 'Manthiri';

      case GameRole.sippai:
        return 'Sippai';

      case GameRole.police:
        return 'Police';

      case GameRole.thirudan:
        return 'Thirudan';
    }
  }

  int get points {
    switch (this) {
      case GameRole.raja:
        return 5000;

      case GameRole.rani:
        return 3000;

      case GameRole.manthiri:
        return 2000;

      case GameRole.sippai:
        return 1000;

      case GameRole.police:
        return 500;

      case GameRole.thirudan:
        return 0;
    }
  }
}
