import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_primitives.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  var _loading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _name.text = profile.name == 'Learner' ? '' : profile.name;
    _email.text = profile.email;
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(userControllerProvider.notifier)
          .updateProfileDetails(
            name: _name.text.trim().isEmpty ? 'Learner' : _name.text.trim(),
            email: _email.text.trim(),
          );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t save your profile. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: pageInsets(context),
          children: [
            const PageHeading(
              eyebrow: 'A little more you',
              title: 'Make this space yours.',
              description:
                  'These details are optional and saved only on this device.',
              icon: Icons.auto_awesome_rounded,
            ),
            FeaturePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make yourself at home',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name (optional)',
                      hintText: 'Your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_loading) _enter();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      hintText: 'you@email.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _loading ? 'Saving…' : 'Save profile',
                    icon: Icons.arrow_forward_rounded,
                    expand: true,
                    onPressed: _loading ? null : _enter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Adding an email does not create an account or enable cloud syncing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
