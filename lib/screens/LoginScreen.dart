import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/AppColors.dart';
import '../config/api_endpoints.dart';

import 'PhoneNumberScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.textColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Column(
                  children: [
                     SizedBox(height: 32),
                    Image.asset(
                      "assets/small_logo.png",//context.appColors.selectedColor, // Replace with your icon asset path
                      height: 80,
                      width: 88,
                    ),
                    Text(
                      'Dekho',
                      style: TextStyle(fontSize: 70, fontWeight: FontWeight.w200,fontFamily: 'Lexend',color: AppColors.backgroundColor/*context.appColors.selectedColor*/, letterSpacing: -3.6,),
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      'Magar Pyaar se',
                      style: TextStyle(fontSize: 16,color: AppColors.backgroundColor,fontFamily: 'Lexend'),
                    ),
                      SizedBox(height: 32),

                  ],
                ),
                // Spacer(),

                Padding(
                  padding: const EdgeInsets.only(top: 150.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.selectedColor,
                        // gradient: LinearGradient(
                        //     colors: context.appColors.gradientButton,
                        //     begin: Alignment.topCenter,
                        //     end: Alignment.bottomCenter
                        // ),
                      ),
                      child: ElevatedButton(
                        onPressed: (){
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> PhoneNumberScreen( /*existingUser: true*/)));
                        },

                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Already an agent/ New Here? ',
                          style: TextStyle(fontSize: 16,color: AppColors.textColor,fontFamily: 'Lexend'),
                        ),

                      ),
                    ),
                  ),
                ),
                SizedBox(height: 82,),

                SizedBox(height: 24),
               /* // Terms and Privacy
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final url = Uri.parse(ApiEndpoints.termsOfUseUrl);
                            if (await canLaunchUrl(url)) { await launchUrl(url); }
                          },
                          child: Text(
                            'Terms of use',
                            style: TextStyle(
                              color: AppColors.backgroundColor,
                              fontFamily: 'Lexend',
                            ),
                          ),
                        ),

                        Container(
                          width: 0.1,
                          height: 20, // ← change this to adjust line height
                          color: AppColors.headlineTextColor,
                        ),

                        TextButton(
                          onPressed: () async {
                            final url = Uri.parse(ApiEndpoints.privacyPolicyUrl);
                            if (await canLaunchUrl(url)) { await launchUrl(url); }
                          },
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.backgroundColor,
                              fontFamily: 'Lexend',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
*/
              ],
            ),
          ),
        ],
      ),
    );
  }
}
