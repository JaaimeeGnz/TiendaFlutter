/// ContactMessage - Modelo para mensajes de contacto/reportes
/// Replica la tabla 'contact_messages' de Supabase usada en tiendaOnline
class ContactMessage {
  final String id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String status; // 'new', 'read', 'resolved', 'spam'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNotes;
  final String? assignedTo;

  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    this.status = 'new',
    required this.createdAt,
    this.updatedAt,
    this.adminNotes,
    this.assignedTo,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: (json['status'] as String?) ?? 'new',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      adminNotes: json['admin_notes'] as String?,
      assignedTo: json['assigned_to'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'assigned_to': assignedTo,
    };
  }

  /// Para insertar un nuevo mensaje (sin id, lo genera Supabase)
  static Map<String, dynamic> toInsertJson({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) {
    return {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'subject': subject.trim(),
      'message': message.trim(),
      'status': 'new',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'new':
        return 'Nuevo';
      case 'read':
        return 'Leído';
      case 'resolved':
        return 'Resuelto';
      case 'spam':
        return 'Spam';
      default:
        return status;
    }
  }
}
