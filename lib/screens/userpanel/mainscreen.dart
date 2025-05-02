import 'package:gudmerchant/utils/appconstant.dart';
import 'package:flutter/material.dart';

class Mainscreen extends StatelessWidget {
  const Mainscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Appconstant.appMainColor,
        title: const Text('Home'),
        centerTitle: true,
      ),
    );
  }
}