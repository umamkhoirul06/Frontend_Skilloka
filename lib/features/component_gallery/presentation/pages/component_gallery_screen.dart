/// Component Gallery Screen for Development
import 'package:flutter/material.dart';

class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Component Gallery')),
      body: const Center(child: Text('Component Gallery - Development Only')),
    );
  }
}
