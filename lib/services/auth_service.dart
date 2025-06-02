// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';

// class AuthService with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   Future<UserCredential?> signInWithEmailAndPassword(
//       String email, String password) async {
//     try {
//       return await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<UserCredential?> createUserWithEmailAndPassword(
//       String email, String password) async {
//     try {
//       return await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//   }
// }