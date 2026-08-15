import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/features/auth/presentation/controllers/auth_controller.dart';
export 'package:mentorride/features/auth/providers/auth_repository_provider.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthActionState>(AuthController.new);
