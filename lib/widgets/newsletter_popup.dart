import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/newsletter_service.dart';
import '../core/theme/app_theme.dart';

/// NewsletterPopup - Popup de suscripción al newsletter
/// Replica la funcionalidad de NewsletterPopup.tsx de Astro
/// Se muestra automáticamente después de unos segundos en la primera visita
class NewsletterPopup extends StatefulWidget {
  final Widget child;
  final int delaySeconds;

  const NewsletterPopup({
    super.key,
    required this.child,
    this.delaySeconds = 5,
  });

  @override
  State<NewsletterPopup> createState() => _NewsletterPopupState();
}

class _NewsletterPopupState extends State<NewsletterPopup> {
  static const String _shownKey = 'newsletter_popup_shown';
  bool _hasShownPopup = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowPopup();
  }

  Future<void> _checkAndShowPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_shownKey) ?? false;

    if (!alreadyShown && !_hasShownPopup) {
      // Esperar el delay antes de mostrar
      await Future.delayed(Duration(seconds: widget.delaySeconds));

      if (mounted && !_hasShownPopup) {
        _hasShownPopup = true;
        _showNewsletterDialog();
        await prefs.setBool(_shownKey, true);
      }
    }
  }

  void _showNewsletterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NewsletterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Dialog de newsletter
class NewsletterDialog extends StatefulWidget {
  const NewsletterDialog({super.key});

  @override
  State<NewsletterDialog> createState() => _NewsletterDialogState();
}

class _NewsletterDialogState extends State<NewsletterDialog> {
  final TextEditingController _emailController = TextEditingController();
  final NewsletterService _newsletterService = NewsletterService();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isExpired = false;
  String? _error;
  String? _discountCode;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Por favor ingresa un email válido';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _newsletterService.subscribe(email: email);

    setState(() {
      _isLoading = false;
      if (result.success) {
        _isSuccess = true;
        _discountCode = result.discountCode;
        _isExpired = result.isExpired;
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: _isSuccess ? _buildSuccessContent() : _buildFormContent(),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón cerrar
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),

        // Icono
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.jdTurquoise.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_offer,
            size: 40,
            color: AppColors.jdTurquoise,
          ),
        ),
        const SizedBox(height: 24),

        // Título
        const Text(
          '¡10% DE DESCUENTO!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Subtítulo
        Text(
          'Suscríbete a nuestra newsletter y recibe un código de descuento exclusivo para tu primera compra.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Campo de email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Tu email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
            errorText: _error,
          ),
          onSubmitted: (_) => _subscribe(),
        ),
        const SizedBox(height: 16),

        // Botón suscribirse
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _subscribe,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.jdTurquoise,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'SUSCRIBIRME',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Texto legal
        Text(
          'Al suscribirte aceptas recibir comunicaciones comerciales. Puedes darte de baja en cualquier momento.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icono de éxito
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 50,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),

        // Título
        const Text(
          '¡Gracias por suscribirte!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Código de descuento
        if (_discountCode != null) ...[
          Text(
            _isExpired ? 'Tu código de descuento ha expirado:' : 'Tu código de descuento:',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _isExpired ? Colors.grey[600] : AppColors.jdBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _discountCode!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                decoration: _isExpired ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isExpired
                ? 'Este código ya no es válido. Suscríbete con otro email para obtener un nuevo descuento.'
                : 'Úsalo en tu próxima compra para obtener un 10% de descuento.',
            style: TextStyle(fontSize: 14, color: _isExpired ? AppColors.error : Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),

        // Botón cerrar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.jdTurquoise,
            ),
            child: const Text(
              '¡EMPEZAR A COMPRAR!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper para mostrar el popup manualmente
void showNewsletterPopup(BuildContext context) {
  showDialog(context: context, builder: (context) => const NewsletterDialog());
}
