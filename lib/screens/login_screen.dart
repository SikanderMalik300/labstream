import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import 'room_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _roomNameController = TextEditingController();
  final _liveKitUrlController = TextEditingController(text: 'ws://localhost:7880');

  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _universityIdController.dispose();
    _roomNameController.dispose();
    _liveKitUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();

      // Login based on role
      if (_selectedRole == UserRole.student) {
        await provider.loginStudent(
          fullName: _fullNameController.text.trim(),
          universityId: _universityIdController.text.trim(),
        );
      } else {
        await provider.loginInstructor(
          fullName: _fullNameController.text.trim(),
        );
      }

      // Join room
      await provider.joinRoom(
        roomName: _roomNameController.text.trim(),
        liveKitUrl: _liveKitUrlController.text.trim(),
      );

      // Navigate to room screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoomScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title
                Text(
                  'LabStream',
                  style: theme.textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-time Communication Platform',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Role Selection
                Text('Select Role', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: Text('Student', style: theme.textTheme.bodyMedium),
                        value: UserRole.student,
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() => _selectedRole = value!);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: Text('Instructor', style: theme.textTheme.bodyMedium),
                        value: UserRole.instructor,
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() => _selectedRole = value!);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // University ID (only for students)
                if (_selectedRole == UserRole.student) ...[
                  TextFormField(
                    controller: _universityIdController,
                    decoration: const InputDecoration(
                      labelText: 'University ID',
                      hintText: 'Enter your university ID',
                    ),
                    validator: (value) {
                      if (_selectedRole == UserRole.student) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your university ID';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Room Name
                TextFormField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    hintText: 'Enter room name to join',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a room name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // LiveKit URL
                TextFormField(
                  controller: _liveKitUrlController,
                  decoration: const InputDecoration(
                    labelText: 'LiveKit Server URL',
                    hintText: 'ws://localhost:7880',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter LiveKit server URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join Room'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
