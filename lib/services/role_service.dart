import 'dart:math';

import '../models/game_role.dart';

class RoleService {
  static List<GameRole> generateRandomRoles() {
    final roles = [
      GameRole.raja,
      GameRole.rani,
      GameRole.manthiri,
      GameRole.sippai,
      GameRole.police,
      GameRole.thirudan,
    ];

    roles.shuffle(Random());

    return roles;
  }
}
