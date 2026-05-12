import 'package:go_router/go_router.dart';

import '../features/athletes/presentation/athlete_detail_screen.dart';
import '../features/athletes/presentation/athletes_screen.dart';
import '../features/athletes/presentation/create_athlete_screen.dart';
import '../features/athletes/presentation/link_parent_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/callups/presentation/add_callups_screen.dart';
import '../features/clubs/presentation/club_context_screen.dart';
import '../features/clubs/presentation/create_club_screen.dart';
import '../features/communications/presentation/communication_detail_screen.dart';
import '../features/communications/presentation/communications_screen.dart';
import '../features/communications/presentation/create_communication_screen.dart';
import '../features/documents/presentation/create_document_screen.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/events/presentation/create_event_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/events/presentation/events_screen.dart';
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
    GoRoute(
      path: '/athletes',
      name: 'athletes',
      builder: (context, state) => const AthletesScreen(),
    ),
    GoRoute(
      path: '/athletes/create',
      name: 'athletes-create',
      builder: (context, state) => const CreateAthleteScreen(),
    ),
    GoRoute(
      path: '/athletes/:athleteId',
      name: 'athlete-detail',
      builder: (context, state) {
        final athleteId = state.pathParameters['athleteId'] ?? '';

        return AthleteDetailScreen(athleteId: athleteId);
      },
    ),
    GoRoute(
      path: '/athletes/:athleteId/parents/link',
      name: 'athlete-link-parent',
      builder: (context, state) {
        final athleteId = state.pathParameters['athleteId'] ?? '';

        return LinkParentScreen(athleteId: athleteId);
      },
    ),
    GoRoute(
      path: '/events',
      name: 'events',
      builder: (context, state) => const EventsScreen(),
    ),
    GoRoute(
      path: '/events/create',
      name: 'events-create',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/events/:eventId',
      name: 'event-detail',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId'] ?? '';

        return EventDetailScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/events/:eventId/callups/add',
      name: 'event-add-callups',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId'] ?? '';

        return AddCallupsScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/events/:eventId/attendance',
      name: 'event-attendance',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId'] ?? '';

        return AttendanceScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/communications',
      name: 'communications',
      builder: (context, state) => const CommunicationsScreen(),
    ),
    GoRoute(
      path: '/communications/create',
      name: 'communications-create',
      builder: (context, state) => const CreateCommunicationScreen(),
    ),
    GoRoute(
      path: '/communications/:communicationId',
      name: 'communication-detail',
      builder: (context, state) {
        final communicationId = state.pathParameters['communicationId'] ?? '';

        return CommunicationDetailScreen(communicationId: communicationId);
      },
    ),
    GoRoute(
      path: '/documents',
      name: 'documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(
      path: '/documents/create',
      name: 'documents-create',
      builder: (context, state) => const CreateDocumentScreen(),
    ),
  ],
);
