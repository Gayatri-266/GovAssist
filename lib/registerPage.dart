import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govassist/loginPage.dart';


class Registerpage extends StatefulWidget {
  const Registerpage({super.key});

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController =
      TextEditingController();
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isStudent = true;
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool loading = false;

  static const Color primaryBlue = Color(0xff315db5);
  static const Color darkBlue = Color(0xff173b7a);
  static const Color lightBlue = Color(0xffeef4ff);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => loading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user?.updateDisplayName(
        _usernameController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Optional: redirect to login after successful registration.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters.';
          break;
        case 'network-request-failed':
          message = 'Please check your internet connection.';
          break;
        default:
          message = e.message ?? 'Account creation failed.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  InputDecoration inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xff999999),
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: const Color(0xff6f7d94),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xfff6f8fb),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xffe5e9f0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        fontSize: 10,
        height: 1.2,
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: inputDecoration(
          hint,
          icon,
          suffix: suffix,
        ),
      ),
    );
  }

  Widget roleButton(String title, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isStudent = title == 'STUDENT';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : const Color(0xff657083),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f9fc),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // TOP HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  35,
                  24,
                  40,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      darkBlue,
                      primaryBlue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'GovAssist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Create your account and access\nall GovAssist services.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // FORM CARD
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff17233c),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Fill in your details to get started.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff7b8494),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ROLE
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xffeef1f5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              roleButton(
                                'STUDENT',
                                isStudent,
                              ),
                              roleButton(
                                'ADMIN',
                                !isStudent,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        textField(
                          controller: _usernameController,
                          hint: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),

                        textField(
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType:
                              TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your email';
                            }

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                              return 'Please enter a valid email';
                            }

                            return null;
                          },
                        ),

                        textField(
                          controller: _passwordController,
                          hint: 'Create Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: hidePassword,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 19,
                              color: const Color(0xff68758a),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                        ),

                        textField(
                          controller:
                              _confirmPasswordController,
                          hint: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: hideConfirmPassword,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                hideConfirmPassword =
                                    !hideConfirmPassword;
                              });
                            },
                            icon: Icon(
                              hideConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 19,
                              color: const Color(0xff68758a),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }

                            if (value !=
                                _passwordController.text) {
                              return 'Passwords do not match';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 5),

                        // CREATE ACCOUNT BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                loading ? null : createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              disabledBackgroundColor:
                                  const Color(0xff9db1dc),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 21,
                                    width: 21,
                                    child:
                                        CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // LOGIN LINK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff7b8494),
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign in here',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  '© GovAssist • Secure & Simple',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xff9aa2af),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}