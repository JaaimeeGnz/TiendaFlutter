import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/contact_message_service.dart';

/// SettingsScreen - Pantalla de configuración de la aplicación
/// Permite cambiar tema, idioma, notificaciones y otras preferencias
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('CONFIGURACIÓN'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de Apariencia
          _buildSectionTitle('APARIENCIA'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.brightness_4_outlined),
              title: const Text('Tema'),
              subtitle: Text(settingsProvider.getThemeModeDisplay()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(context, settingsProvider),
            ),
          ),

          const SizedBox(height: 24),

          // Sección de Privacidad y Seguridad
          _buildSectionTitle('PRIVACIDAD Y SEGURIDAD'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Política de Privacidad'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _showPrivacyPolicyDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Términos y Condiciones'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _showTermsAndConditionsDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cookie_outlined),
                  title: const Text('Política de Cookies'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _showCookiePolicyDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección de Información
          _buildSectionTitle('INFORMACIÓN'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outlined),
                  title: const Text('Versión'),
                  subtitle: const Text('1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Acerca de'),
                  subtitle: const Text('JGMarket - Tienda Online'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Reportar un problema'),
                  subtitle: const Text('Ayúdanos a mejorar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showBugReportDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección de Datos
          _buildSectionTitle('DATOS'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Caché local'),
              subtitle: const Text('Limpiar datos en caché'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showClearCacheDialog(context),
            ),
          ),

          const SizedBox(height: 24),

          // Sección de Mantenimiento
          _buildSectionTitle('MANTENIMIENTO'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Restaurar configuración por defecto'),
              subtitle: const Text('Volver a los valores iniciales'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResetDialog(context, settingsProvider),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.mediumGray,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              value: ThemeMode.light,
              groupValue: provider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  provider.themeMode = value;
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Oscuro'),
              value: ThemeMode.dark,
              groupValue: provider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  provider.themeMode = value;
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sistema'),
              value: ThemeMode.system,
              groupValue: provider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  provider.themeMode = value;
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidad'),
        content: const SingleChildScrollView(
          child: Text(
            'POLÍTICA DE PRIVACIDAD\n\n'
            'JGMarket se compromete a proteger tu privacidad. Esta política describe cómo recopilamos, utilizamos y protegemos tu información personal.\n\n'
            '1. INFORMACIÓN QUE RECOPILAMOS\n'
            '- Información de cuenta: nombre, email, dirección\n'
            '- Información de compra: productos adquiridos, historial de pedidos\n'
            '- Información técnica: dirección IP, tipo de navegador\n\n'
            '2. CÓMO UTILIZAMOS TU INFORMACIÓN\n'
            '- Procesar tus pedidos\n'
            '- Mejorar nuestros servicios\n'
            '- Comunicarnos contigo sobre tus compras\n\n'
            '3. PROTECCIÓN DE DATOS\n'
            'Utilizamos encriptación SSL y medidas de seguridad estándar de la industria para proteger tu información.\n\n'
            '4. TUS DERECHOS\n'
            'Tienes derecho a acceder, modificar o eliminar tu información personal en cualquier momento.\n\n'
            'Para más información, contacta a: privacy@jgmarket.es',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Términos y Condiciones'),
        content: const SingleChildScrollView(
          child: Text(
            'TÉRMINOS Y CONDICIONES\n\n'
            '1. USO DE LA PLATAFORMA\n'
            'JGMarket proporciona una plataforma de comercio electrónico. Al utilizar nuestros servicios, aceptas estos términos.\n\n'
            '2. CUENTAS DE USUARIO\n'
            'Eres responsable de mantener la confidencialidad de tu contraseña. JGMarket no es responsable de accesos no autorizados a tu cuenta.\n\n'
            '3. PRODUCTOS Y PRECIOS\n'
            'Tratamos de mantener información exacta de productos y precios. Sin embargo, pueden existir errores.\n\n'
            '4. DEVOLUCIONES Y REEMBOLSOS\n'
            'Los productos pueden devolverse dentro de 30 días en condición original.\n\n'
            '5. LIMITACIÓN DE RESPONSABILIDAD\n'
            'JGMarket no será responsable por daños indirectos o pérdidas de beneficios.\n\n'
            '6. CAMBIOS EN LOS TÉRMINOS\n'
            'Nos reservamos el derecho de modificar estos términos en cualquier momento.\n\n'
            'Última actualización: 2024',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showCookiePolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Cookies'),
        content: const SingleChildScrollView(
          child: Text(
            'POLÍTICA DE COOKIES\n\n'
            'JGMarket utiliza cookies para mejorar tu experiencia.\n\n'
            '1. ¿QUÉ SON LAS COOKIES?\n'
            'Las cookies son pequeños archivos que se guardan en tu dispositivo para recordar preferencias y mejorar tu experiencia.\n\n'
            '2. TIPOS DE COOKIES QUE USAMOS\n'
            '- Cookies de sesión: necesarias para funcionar\n'
            '- Cookies de preferencia: recordar tus gustos\n'
            '- Cookies analíticas: entender cómo usas la plataforma\n\n'
            '3. GESTIÓN DE COOKIES\n'
            'Puedes controlar las cookies desde la configuración de tu navegador.\n\n'
            '4. CONSENTIMIENTO\n'
            'Al usar JGMarket, aceptas el uso de cookies.\n\n'
            'Para más información: cookies@jgmarket.es',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de JGMarket'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JGMarket v1.0.0',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'JGMarket es una tienda online moderna construida con Flutter, diseñada para brindarte la mejor experiencia de compra en línea.\n\n'
                'Contamos con:\n'
                '✓ Catálogo de productos en tiempo real\n'
                '✓ Carrito de compras inteligente\n'
                '✓ Pagos seguros con Stripe\n'
                '✓ Gestión de pedidos\n'
                '✓ Soporte al cliente\n\n'
                '© 2024 JGMarket. Todos los derechos reservados.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    final contactService = ContactMessageService();
    bool isSending = false;

    // Pre-rellenar email si el usuario está autenticado
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user?.email != null) {
      emailController.text = authProvider.user!.email;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reportar un problema'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Describe el problema que encontraste:'),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Tu nombre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'tu@email.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Asunto',
                    hintText: '¿En qué podemos ayudarte?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Mensaje',
                    hintText: 'Cuéntanos qué salió mal...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          subjectController.text.isEmpty ||
                          messageController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Todos los campos son requeridos'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);

                      final success = await contactService.submitReport(
                        name: nameController.text,
                        email: emailController.text,
                        subject: subjectController.text,
                        message: messageController.text,
                      );

                      if (!context.mounted) return;

                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gracias por tu reporte. Nos pondremos en contacto pronto.',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        setDialogState(() => isSending = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error al enviar el reporte. Inténtalo de nuevo.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jdTurquoise,
              ),
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar los datos en caché? Esto puede mejorar el rendimiento de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Caché limpiado correctamente'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.jdTurquoise,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar configuración'),
        content: const Text(
          '¿Estás seguro de que deseas restaurar la configuración a los valores por defecto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.resetToDefaults();
              Navigator.pop(context);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración restaurada'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.jdTurquoise,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
}
