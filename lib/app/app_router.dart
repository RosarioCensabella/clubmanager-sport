import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/clubs/presentation/club_context_screen.dart';
import '../features/clubs/presentation/create_club_screen.dart';
import '../features/members/presentation/create_invitation_screen.dart';
import '../features/members/presentation/invitations_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/teams/presentation/create_team_screen.dart';
import '../features/teams/presentation/teams_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/club-context',
      name: 'club-context',
      builder: (context, state) => const ClubContextScreen(),
    ),
    GoRoute(
      path: '/clubs/create',
      name: 'clubs-create',
      builder: (context, state) => const CreateClubScreen(),
    ),
    GoRoute(
      path: '/teams',
      name: 'teams',
      builder: (context, state) => const TeamsScreen(),
    ),
    GoRoute(
      path: '/teams/create',
      name: 'teams-create',
      builder: (context, state) => const CreateTeamScreen(),
    ),
    GoRoute(
      path: '/invitations',
      name: 'invitations',
      builder: (context, state) => const InvitationsScreen(),
    ),
    GoRoute(
      path: '/invitations/create',
      name: 'invitations-create',
      builder: (context, state) => const CreateInvitationScreen(),
    ),
  ],
);
