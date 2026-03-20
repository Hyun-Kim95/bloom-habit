import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Google "G" mark (brand blue, Roboto — common simplified treatment without assets).
class GoogleGMark extends StatelessWidget {
  const GoogleGMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.roboto(
            fontSize: size * 0.75,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4285F4),
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Google-branded sign-in button (light surface, gray border).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  static const _border = Color(0xFF747775);
  static const _fg = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _fg,
          disabledForegroundColor: _fg.withValues(alpha: 0.38),
          side: const BorderSide(color: _border, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const GoogleGMark(size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: loading ? _fg.withValues(alpha: 0.38) : _fg,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kakao — yellow #FEE500, black text.
class KakaoSignInButton extends StatelessWidget {
  const KakaoSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  static const _yellow = Color(0xFFFEE500);
  static const _black = Color(0xFF191919);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _black,
          disabledBackgroundColor: _yellow.withValues(alpha: 0.5),
          disabledForegroundColor: _black.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _black,
                ),
              )
            else
              Icon(Icons.chat_bubble, size: 20, color: _black),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: loading ? _black.withValues(alpha: 0.38) : _black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Naver — green #03C75A, white text.
class NaverSignInButton extends StatelessWidget {
  const NaverSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  static const _green = Color(0xFF03C75A);
  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: _white,
          disabledBackgroundColor: _green.withValues(alpha: 0.5),
          disabledForegroundColor: _white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _white,
                ),
              )
            else
              Text(
                'N',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _white,
                  height: 1,
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: loading ? _white.withValues(alpha: 0.5) : _white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
