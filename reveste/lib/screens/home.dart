import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color verdeEscuro = Color(0xFF355E4B);
  static const Color creme = Color(0xFFF7F2E8);
  static const Color terracota = Color(0xFFC96F4A);
  static const Color verdeSalvia = Color(0xFFA9BFAF);
  static const Color grafite = Color(0xFF22352D);
  static const Color branco = Color(0xFFFFFFFF);
}
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.verdeEscuro,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'ReVeste',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: AppColors.verdeEscuro,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'moda com história',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grafite.withOpacity(0.5),
                ),
              ),

              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeEscuro,
                    foregroundColor: AppColors.branco,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),  
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sou consumidor',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grafite,
                    foregroundColor: AppColors.branco,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sou um brechó',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}