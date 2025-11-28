import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// ignore: unused_import
import 'logger_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Cached user data
  Map<String, dynamic>? _currentUserData;

  /// Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login user with email and password
  Future<({bool success, String message, String? fullName})> login({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      return (
        success: false,
        message: 'Email and password are required',
        fullName: null,
      );
    }

    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Get user data from database
      final userSnapshot = await _database
          .ref()
          .child('users')
          .child(userCredential.user!.uid)
          .get();

      if (userSnapshot.exists) {
        _currentUserData = Map<String, dynamic>.from(userSnapshot.value as Map);

        return (
          success: true,
          message: 'Login successful',
          fullName: _currentUserData!['name'] as String?,
        );
      } else {
        // User authenticated but no profile data
        return (
          success: false,
          message: 'User profile not found',
          fullName: null,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return (success: false, message: message, fullName: null);
    } catch (e) {
      return (
        success: false,
        message: 'Error: ${e.toString()}',
        fullName: null,
      );
    }
  }

  /// Register new user
  Future<({bool success, String message})> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Validate inputs
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      return (success: false, message: 'All fields are required');
    }

    if (password.length < 6) {
      return (
        success: false,
        message: 'Password must be at least 6 characters',
      );
    }

    if (password != confirmPassword) {
      return (success: false, message: 'Passwords do not match');
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      return (success: false, message: 'Please enter a valid email address');
    }

    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in database
      await _database.ref().child('users').child(userCredential.user!.uid).set({
        'email': email,
        'name': fullName,
        'role': 'customer', // Default role
        'createdAt': ServerValue.timestamp,
        'addresses': [],
        'paymentMethods': [],
      });

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(fullName);

      return (success: true, message: 'Registration successful');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Create user (admin function)
  Future<void> createUser(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in database
      await _database.ref().child('users').child(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'createdAt': ServerValue.timestamp,
        'addresses': [],
        'paymentMethods': [],
      });

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      // Sign out the newly created user (admin should remain signed in)
      // Note: This is a limitation - creating a user signs in as that user
      // For production, you'd need Firebase Admin SDK on a backend
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to create user');
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Get current auth token (for compatibility)
  Future<String?> getAuthToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  /// Get current logged-in user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Return cached data if available
    if (_currentUserData != null) {
      return _currentUserData;
    }

    // Fetch from database
    try {
      final userSnapshot = await _database
          .ref()
          .child('users')
          .child(user.uid)
          .get();

      if (userSnapshot.exists) {
        _currentUserData = Map<String, dynamic>.from(userSnapshot.value as Map);
        return _currentUserData;
      }
    } catch (e) {
      logger.error('Error fetching user data: $e');
    }

    return null;
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final userData = await getCurrentUser();
    // Check both 'isAdmin' field (new format) and 'role' field (legacy format)
    return userData?['isAdmin'] == true || userData?['role'] == 'admin';
  }

  /// Get authentication token (for compatibility)
  Future<String?> get token => getAuthToken();

  /// Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Check if token has expired (Firebase handles this automatically)
  bool isTokenExpired() {
    return _auth.currentUser == null;
  }

  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
    _currentUserData = null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Check if currently in offline/demo mode
  bool isOfflineMode() {
    // Firebase works offline automatically with persistence
    return false;
  }

  /// Send password reset email
  Future<({bool success, String message})> sendPasswordResetEmail({
    required String email,
  }) async {
    if (email.isEmpty) {
      return (success: false, message: 'Email is required');
    }

    if (!_isValidEmail(email)) {
      return (success: false, message: 'Please enter a valid email address');
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return (
        success: true,
        message: 'Password reset email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<({bool success, String message})> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return (success: false, message: 'No user logged in');
    }

    try {
      // Update Firebase Auth profile
      if (name != null) {
        await user.updateDisplayName(name);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update database profile
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      updates['updatedAt'] = ServerValue.timestamp;

      await _database.ref().child('users').child(user.uid).update(updates);

      // Clear cache to force refresh
      _currentUserData = null;

      return (success: true, message: 'Profile updated successfully');
    } catch (e) {
      return (
        success: false,
        message: 'Error updating profile: ${e.toString()}',
      );
    }
  }

  /// Delete user account
  Future<({bool success, String message})> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return (success: false, message: 'No user logged in');
    }

    try {
      // Delete user data from database
      await _database.ref().child('users').child(user.uid).remove();

      // Delete user from Firebase Auth
      await user.delete();

      _currentUserData = null;

      return (success: true, message: 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return (
          success: false,
          message: 'Please login again before deleting your account',
        );
      }
      return (success: false, message: 'Error deleting account: ${e.message}');
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Reauthenticate user (required for sensitive operations)
  Future<({bool success, String message})> reauthenticate({
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return (success: false, message: 'No user logged in');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return (success: true, message: 'Reauthentication successful');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'user-mismatch':
          message = 'Credential does not match current user';
          break;
        default:
          message = 'Reauthentication failed: ${e.message}';
      }
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Change user password
  Future<({bool success, String message})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return (success: false, message: 'No user logged in');
    }

    try {
      // Validate new password
      if (newPassword.length < 6) {
        return (
          success: false,
          message: 'New password must be at least 6 characters',
        );
      }

      // Reauthenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return (success: true, message: 'Password changed successfully');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak. Use a stronger password';
          break;
        case 'requires-recent-login':
          message = 'Please login again before changing password';
          break;
        default:
          message = 'Password change failed: ${e.message}';
      }
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Save user preferences (language, theme, etc)
  Future<({bool success, String message})> savePreferences({
    required String language,
    required String theme,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return (success: false, message: 'No user logged in');
    }

    try {
      await _database
          .ref()
          .child('users')
          .child(user.uid)
          .child('preferences')
          .update({
            'language': language,
            'theme': theme,
            'updatedAt': ServerValue.timestamp,
          });

      return (success: true, message: 'Preferences saved successfully');
    } catch (e) {
      return (success: false, message: 'Error saving preferences: $e');
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _database
          .ref()
          .child('users')
          .child(user.uid)
          .child('preferences')
          .get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
