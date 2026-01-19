import 'package:flutter/material.dart';
import 'package:timely/utils/responsive_utils.dart';

/// Screen that displays data privacy and protection information.
///
/// This screen provides comprehensive information about how personal data
/// is processed, the legal basis for treatment, user rights under GDPR,
/// data retention policies, and security measures implemented in the application.
class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          responsive.isMobile
              ? 'Protección de Datos'
              : 'Información sobre Protección de Datos',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: responsive.isMobile ? 18 : 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                title: 'Responsable del Tratamiento',
                content:
                    'El responsable del tratamiento de los datos es la empresa para la que usted presta servicios '
                    'como trabajador. Esta aplicación actúa como herramienta de gestión del registro horario '
                    'por cuenta de dicha empresa.',
              ),
              _buildSection(
                context,
                title: 'Datos Personales que se Tratan',
                content:
                    'A través de esta aplicación se pueden tratar los siguientes datos personales:\n\n'
                    '• Nombre y apellidos\n'
                    '• Documento de identidad (DNI)\n'
                    '• Correo electrónico y número de teléfono\n'
                    '• Dirección postal\n'
                    '• Fotografía de perfil (opcional)\n'
                    '• PIN de seguridad para el acceso a la aplicación\n'
                    '• Registros de jornada laboral (entradas, pausas, reanudaciones y salidas)\n'
                    '• Turnos planificados y estado laboral (activo, vacaciones, baja, etc.)',
              ),
              _buildSection(
                context,
                title: 'Finalidad del Tratamiento',
                content:
                    'Los datos personales se tratan con la finalidad de:\n\n'
                    '• Registrar la jornada laboral diaria de los trabajadores\n'
                    '• Cumplir con la normativa legal vigente en materia de control horario\n'
                    '• Gestionar turnos, horarios y planificación laboral\n'
                    '• Permitir al trabajador consultar su historial de registros',
              ),
              _buildSection(
                context,
                title: 'Base Legal',
                content:
                    'El tratamiento de los datos se basa en el cumplimiento de una obligación legal '
                    '(artículo 6.1.c del Reglamento General de Protección de Datos), derivada del '
                    'Real Decreto-ley 8/2019 y del Estatuto de los Trabajadores, que obligan a las empresas '
                    'a llevar un registro diario de la jornada laboral.',
              ),
              _buildSection(
                context,
                title: 'Conservación de los Datos',
                content:
                    'Los registros horarios se conservarán durante un período mínimo de 4 años, '
                    'tal y como establece la normativa laboral vigente. El resto de datos personales '
                    'se conservarán mientras se mantenga la relación laboral o durante el tiempo '
                    'necesario para cumplir con obligaciones legales.',
              ),
              _buildSection(
                context,
                title: 'Destinatarios y Encargados del Tratamiento',
                content:
                    'Los datos no se cederán a terceros salvo obligación legal. '
                    'Los datos se almacenan de forma segura en infraestructuras tecnológicas '
                    'proporcionadas por servicios en la nube (Firebase / Google Cloud), que actúan '
                    'como encargados del tratamiento bajo contratos que garantizan el cumplimiento del RGPD.',
              ),
              _buildSection(
                context,
                title: 'Transferencias Internacionales',
                content:
                    'Al utilizar servicios tecnológicos de proveedores internacionales, '
                    'los datos pueden ser tratados fuera del Espacio Económico Europeo. '
                    'Dichas transferencias se realizan con garantías adecuadas, como las '
                    'Cláusulas Contractuales Tipo aprobadas por la Comisión Europea.',
              ),
              _buildSection(
                context,
                title: 'Derechos del Usuario',
                content:
                    'Usted puede ejercer en cualquier momento los siguientes derechos:\n\n'
                    '• Acceso a sus datos personales\n'
                    '• Rectificación de datos inexactos\n'
                    '• Supresión de los datos cuando proceda\n'
                    '• Limitación u oposición al tratamiento\n'
                    '• Portabilidad de los datos\n\n'
                    'Para ejercer estos derechos, deberá dirigirse a la empresa responsable '
                    'del tratamiento. También puede presentar una reclamación ante la Agencia Española '
                    'de Protección de Datos (www.aepd.es).',
              ),
              _buildSection(
                context,
                title: 'Medidas de Seguridad',
                content:
                    'Se aplican medidas técnicas y organizativas adecuadas para garantizar la '
                    'confidencialidad, integridad y disponibilidad de los datos personales, '
                    'incluyendo control de accesos, autenticación mediante PIN y comunicaciones seguras.',
              ),
              _buildSection(
                context,
                title: 'Acuerdo de Buen Uso',
                content:
                    'El acceso a las pantallas de registro horario y datos del empleado está protegido '
                    'mediante un PIN personal e intransferible asignado a cada usuario.\n\n'
                    'Al utilizar esta aplicación, tanto los empleados como la empresa (representada por '
                    'el responsable o administrador) se comprometen a hacer un uso responsable y de buena fe '
                    'de las credenciales de acceso.\n\n'
                    'Queda expresamente prohibido:\n\n'
                    '• Compartir el PIN personal con terceros\n'
                    '• Utilizar el PIN de otro empleado para realizar fichajes en su nombre\n'
                    '• Cualquier manipulación fraudulenta de los registros horarios\n\n'
                    'El incumplimiento de estas normas puede constituir una falta laboral grave y '
                    'conllevar las responsabilidades disciplinarias, civiles o penales que correspondan.\n\n'
                    'La empresa se compromete a no utilizar los datos de registro horario para fines '
                    'distintos a los establecidos legalmente y a respetar la privacidad de los trabajadores.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a privacy information section with title and content.
  ///
  /// Creates a formatted section with a bold title and descriptive content
  /// text, used to organize different aspects of the privacy policy.
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          content,
          style: TextStyle(
            fontSize: theme.textTheme.bodyLarge?.fontSize,
            height: 1.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
