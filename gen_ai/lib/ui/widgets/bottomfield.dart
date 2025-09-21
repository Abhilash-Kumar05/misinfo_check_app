import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/colors.dart';

class BottomField extends StatelessWidget {
  const BottomField({
    super.key,
    this.onTap,
    this.controller,
  });

  final void Function()? onTap;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(


      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 14.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: const Color(0xFFD8ECFC),
          child: Row(
            children: [
              Expanded(
                child: ThemedTextField(controller: controller),
              ),
              SizedBox(width: 7.w),
              IconButton(
                onPressed: onTap,
                icon: Icon(Icons.send, size: 28.sp, color: primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ThemedTextField extends StatelessWidget {
  final TextEditingController? controller;

  const ThemedTextField({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        color: Colors.black,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        hintText: "Type a message...",
        hintStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
