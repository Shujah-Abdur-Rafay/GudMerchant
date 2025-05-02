import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gudmerchant/utils/app_theme.dart';

class OtpInputField extends StatefulWidget {
  final Function(String) onOtpEntered;
  final int length;
  final bool autoFocus;

  const OtpInputField({
    Key? key,
    required this.onOtpEntered,
    this.length = 6,
    this.autoFocus = true,
  }) : super(key: key);

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _otpValues;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode()..addListener(() {
        if (_focusNodes[index].hasFocus && _controllers[index].text.isNotEmpty) {
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        }
      }),
    );
    _otpValues = List.generate(widget.length, (index) => '');
    
    // Auto focus on first field
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleValueChanged() {
    final otp = _otpValues.join();
    if (otp.length == widget.length) {
      widget.onOtpEntered(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          widget.length,
          (index) => SizedBox(
            width: 45,
            height: 55,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              cursorColor: AppTheme.primaryColor,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: "",
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                _otpValues[index] = value;
                
                if (value.isNotEmpty) {
                  // Move to next field
                  if (index < widget.length - 1) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    // Last field, hide keyboard
                    FocusScope.of(context).unfocus();
                    // Verify OTP
                    _handleValueChanged();
                  }
                } else if (index > 0) {
                  // Move to previous field on delete
                  _focusNodes[index - 1].requestFocus();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
} 