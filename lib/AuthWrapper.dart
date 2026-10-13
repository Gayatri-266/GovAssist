
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:govassist/adminDashboard%20.dart';

import 'package:govassist/loginPage.dart';

import 'package:govassist/studentdashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // Not logged in: show login page.
        if (user == null) {
          return LoginPage();
        }

        // Logged in: find the profile using the authenticated UID.
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (adminSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Unable to load your profile.'),
                ),
              );
            }

            if (adminSnapshot.data?.exists == true) {
              return const AdminDashboard();
            }

            // If not an admin, check the students collection.
            return FutureBuilder<
                DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(user.uid)
                  .get(),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (studentSnapshot.hasError) {
                  return const Scaffold(
                    body: Center(
                      child: Text('Unable to load your profile.'),
                    ),
                  );
                }

                if (studentSnapshot.data?.exists == true) {
                  return Studentdashboard();
                }

                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Profile not found. Please register again.',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
