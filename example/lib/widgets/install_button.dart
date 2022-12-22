import 'package:flutter/material.dart';

class InstallButton extends StatelessWidget {
  const InstallButton(
      {super.key,
      required this.onCall,
      required this.canCall,
      required this.label});

  final Function onCall;
  final bool canCall;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: canCall
          ? () async {
              try {
                await onCall.call();
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$error'),
                ));
              }
            }
          : null,
      child: Text(label),
    );
  }
}
