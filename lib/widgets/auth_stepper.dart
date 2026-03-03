import 'package:flutter/material.dart';

class AuthStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AuthStepper({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'auth_stepper',
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= totalSteps; i++) ...[
                _buildCircle('$i', currentStep >= i),
                if (i < totalSteps) _buildLine(currentStep >= i + 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircle(String step, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10B981) : const Color(0xFF2C2C2E),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        step,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLine(bool isActive) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: isActive ? 40 : 0,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
