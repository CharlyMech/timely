import 'package:flutter/material.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Información sobre el Uso de Datos',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: 'Introducción',
              content:
                  'Esta aplicación cumple con la normativa española vigente en materia de protección de datos (RGPD y LOPDGDD) y con el Real Decreto-ley 8/2019 sobre el registro horario obligatorio de la jornada laboral.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Datos que Recogemos',
              content:
                  'La aplicación registra los siguientes datos:\n\n'
                  '• Datos identificativos del empleado (nombre, apellidos, número de empleado)\n'
                  '• Hora de entrada y salida de la jornada laboral\n'
                  '• Fecha de los registros horarios\n'
                  '• Imágenes de perfil (si se proporcionan)',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Finalidad del Tratamiento',
              content:
                  'Los datos se recogen con las siguientes finalidades:\n\n'
                  '• Cumplimiento de la obligación legal de registro horario (Real Decreto-ley 8/2019)\n'
                  '• Control de asistencia y puntualidad\n'
                  '• Cálculo de horas trabajadas\n'
                  '• Gestión de recursos humanos\n'
                  '• Auditorías y cumplimiento normativo',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Base Legal',
              content:
                  'El tratamiento de datos se fundamenta en:\n\n'
                  '• Obligación legal (artículo 34.9 del Estatuto de los Trabajadores)\n'
                  '• Ejecución del contrato laboral\n'
                  '• Interés legítimo del empleador en la organización del trabajo',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Acceso a los Datos',
              content:
                  'Tienen acceso a los datos:\n\n'
                  '• El propio empleado: puede consultar sus propios registros horarios\n'
                  '• Administradores y responsables de RRHH: tienen acceso completo a todos los registros para fines de gestión, supervisión y cumplimiento normativo\n'
                  '• Inspección de Trabajo: en caso de requerimiento legal',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Conservación de Datos',
              content:
                  'Los registros horarios se conservarán durante:\n\n'
                  '• Mínimo 4 años, según exige el Real Decreto-ley 8/2019\n'
                  '• Periodo adicional si es necesario para atender posibles reclamaciones o cumplir con otras obligaciones legales',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Derechos del Empleado',
              content:
                  'Como empleado, tienes derecho a:\n\n'
                  '• Acceder a tus datos personales\n'
                  '• Solicitar la rectificación de datos inexactos\n'
                  '• Solicitar la limitación del tratamiento\n'
                  '• Presentar una reclamación ante la Agencia Española de Protección de Datos (AEPD)\n\n'
                  'Nota: El derecho de supresión puede estar limitado por la obligación legal de conservar los registros horarios.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Seguridad',
              content:
                  'Se implementan medidas técnicas y organizativas apropiadas para proteger los datos:\n\n'
                  '• Acceso mediante autenticación\n'
                  '• Cifrado de comunicaciones\n'
                  '• Control de accesos según roles\n'
                  '• Copias de seguridad periódicas',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Modificaciones del Trabajo',
              content:
                  'El administrador puede:\n\n'
                  '• Consultar los registros de entrada y salida de todos los empleados\n'
                  '• Generar informes de asistencia\n'
                  '• Exportar datos para auditorías\n'
                  '• Tomar medidas correctivas en caso de incumplimiento del horario laboral según el convenio colectivo aplicable',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Actualización Normativa 2026',
              content:
                  'Esta aplicación cumple con las actualizaciones normativas vigentes en 2026 respecto al registro horario, garantizando:\n\n'
                  '• Registro inmediato de entrada y salida\n'
                  '• Accesibilidad de los registros para el empleado\n'
                  '• Disponibilidad inmediata para la Inspección de Trabajo\n'
                  '• Integridad e inalterabilidad de los registros',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Para ejercer tus derechos o realizar consultas sobre el tratamiento de datos, contacta con el responsable de protección de datos de tu empresa.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
