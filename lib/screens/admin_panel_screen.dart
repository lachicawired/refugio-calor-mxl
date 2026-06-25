import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/punto.dart';
import '../services/admin_service.dart';

class AdminEntryScreen extends StatefulWidget {
  const AdminEntryScreen({super.key});

  @override
  State<AdminEntryScreen> createState() => _AdminEntryScreenState();
}

class _AdminEntryScreenState extends State<AdminEntryScreen> {
  final _adminService = AdminService();
  bool _cargando = true;
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarAdmin();
  }

  Future<void> _verificarAdmin() async {
    final esAdmin = await _adminService.esAdminActual();
    if (mounted) {
      setState(() {
        _esAdmin = esAdmin;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_esAdmin) {
      return const AdminPanelScreen();
    }

    return AdminLoginScreen(onLoginOk: _verificarAdmin);
  }
}

class AdminLoginScreen extends StatefulWidget {
  final Future<void> Function() onLoginOk;

  const AdminLoginScreen({super.key, required this.onLoginOk});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _adminService = AdminService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() => _cargando = true);

    try {
      await _adminService.iniciarSesion(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final esAdmin = await _adminService.esAdminActual();
      if (!esAdmin) {
        await _adminService.cerrarSesion();
        throw Exception('Esta cuenta no tiene permiso de administrador.');
      }

      await widget.onLoginOk();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo entrar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Panel privado',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Entra con la cuenta autorizada en Firebase Auth.'),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _cargando ? null : _entrar,
            icon: _cargando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.admin_panel_settings),
            label: Text(_cargando ? 'Entrando...' : 'Entrar'),
          ),
        ],
      ),
    );
  }
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _adminService = AdminService();

  Future<void> _cerrarSesion() async {
    await _adminService.cerrarSesion();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminLoginScreen(
            onLoginOk: () async {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  void _abrirFormulario({Punto? punto}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminPuntoFormScreen(punto: punto)),
    );
  }

  Future<void> _copiarJsonAprobados() async {
    final json = await _adminService.generarJsonPuntosAprobados();
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON de puntos aprobados copiado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel admin'),
          actions: [
            IconButton(
              tooltip: 'Copiar JSON de aprobados',
              onPressed: _copiarJsonAprobados,
              icon: const Icon(Icons.copy),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Reportes'),
              Tab(text: 'Puntos'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Nuevo punto'),
        ),
        body: TabBarView(
          children: [
            _PendientesTab(adminService: _adminService),
            _ReportesTab(adminService: _adminService),
            _PuntosTab(
              adminService: _adminService,
              onEditar: (punto) => _abrirFormulario(punto: punto),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendientesTab extends StatelessWidget {
  final AdminService adminService;

  const _PendientesTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: adminService.obtenerPuntosReportadosPendientes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reportes = snapshot.data!;
        if (reportes.isEmpty) {
          return const Center(child: Text('No hay puntos pendientes.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reportes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reporte = reportes[index];
            final data = reporte.data();
            return _ReportePuntoCard(
              data: data,
              actions: [
                FilledButton.icon(
                  onPressed: () => adminService.aprobarPuntoReportado(reporte),
                  icon: const Icon(Icons.verified),
                  label: const Text('Aprobar'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      adminService.rechazarPuntoReportado(reporte.id),
                  icon: const Icon(Icons.block),
                  label: const Text('Rechazar'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      adminService.eliminarPuntoReportado(reporte.id),
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReportePuntoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Widget> actions;

  const _ReportePuntoCard({required this.data, required this.actions});

  @override
  Widget build(BuildContext context) {
    final creadoEn = data['creadoEn'];
    final fecha = creadoEn is Timestamp
        ? '${creadoEn.toDate().day.toString().padLeft(2, '0')}/${creadoEn.toDate().month.toString().padLeft(2, '0')}/${creadoEn.toDate().year}'
        : 'Sin fecha';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['nombre'] ?? 'Sin nombre',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _AdminInfoLine(label: 'Dirección', value: data['direccion'] ?? ''),
            _AdminInfoLine(
              label: 'Ubicación',
              value: '${data['lat'] ?? ''}, ${data['lng'] ?? ''}',
            ),
            _AdminInfoLine(label: 'Qué ofrece', value: data['tipo'] ?? ''),
            _AdminInfoLine(label: 'Horario', value: data['horario'] ?? ''),
            if ((data['telefono'] ?? '').toString().isNotEmpty)
              _AdminInfoLine(label: 'Teléfono', value: data['telefono']),
            _AdminInfoLine(label: 'Detalles', value: data['descripcion'] ?? ''),
            _AdminInfoLine(label: 'Fecha', value: fecha),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

class _AdminInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _AdminInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: ${value.isEmpty ? 'Sin dato' : value}'),
    );
  }
}

class _ReportesTab extends StatelessWidget {
  final AdminService adminService;

  const _ReportesTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: adminService.obtenerReportes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reportes = snapshot.data!;
        if (reportes.isEmpty) {
          return const Center(child: Text('No hay reportes recientes.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reportes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = reportes[index].data();
            final comentario = data['comentario'] ?? '';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.report),
                title: Text(data['tipoReporte'] ?? 'Reporte'),
                subtitle: Text(
                  [
                    'Punto: ${data['puntoId'] ?? ''}',
                    if (comentario.toString().isNotEmpty)
                      'Comentario: $comentario',
                  ].join('\n'),
                ),
                isThreeLine: comentario.toString().isNotEmpty,
              ),
            );
          },
        );
      },
    );
  }
}

class _PuntosTab extends StatelessWidget {
  final AdminService adminService;
  final void Function(Punto punto) onEditar;

  const _PuntosTab({required this.adminService, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Punto>>(
      stream: adminService.obtenerTodosLosPuntos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final puntos = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: puntos.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final punto = puntos[index];
            return _AdminPuntoCard(
              punto: punto,
              actions: [
                TextButton.icon(
                  onPressed: () => onEditar(punto),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => adminService.marcarCerrado(punto),
                  icon: const Icon(Icons.block),
                  label: const Text('Cerrar'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar punto'),
                        content: const Text(
                          '¿Seguro que quieres eliminar este punto?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      await adminService.eliminarPunto(punto);
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar punto'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AdminPuntoCard extends StatelessWidget {
  final Punto punto;
  final List<Widget> actions;

  const _AdminPuntoCard({required this.punto, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              punto.nombre,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(punto.direccion),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(punto.tipo)),
                Chip(label: Text(punto.estado)),
                Chip(label: Text(punto.confianza)),
                Chip(
                  label: Text(
                    '${punto.votosAbiertoHoy} abierto / ${punto.votosCerradoHoy} cerrado',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

class AdminPuntoFormScreen extends StatefulWidget {
  final Punto? punto;

  const AdminPuntoFormScreen({super.key, this.punto});

  @override
  State<AdminPuntoFormScreen> createState() => _AdminPuntoFormScreenState();
}

class _AdminPuntoFormScreenState extends State<AdminPuntoFormScreen> {
  final _adminService = AdminService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _horarioController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  late String _tipo;
  late String _estado;
  late String _confianza;
  late bool _direccionVerificada;
  bool _guardando = false;

  bool get _editando => widget.punto != null;

  @override
  void initState() {
    super.initState();
    final punto = widget.punto;
    _nombreController = TextEditingController(text: punto?.nombre ?? '');
    _direccionController = TextEditingController(text: punto?.direccion ?? '');
    _telefonoController = TextEditingController(text: punto?.telefono ?? '');
    _horarioController = TextEditingController(text: punto?.horario ?? '');
    _descripcionController = TextEditingController(
      text: punto?.descripcion ?? '',
    );
    _latController = TextEditingController(text: punto?.lat.toString() ?? '');
    _lngController = TextEditingController(text: punto?.lng.toString() ?? '');
    _tipo = punto?.tipo ?? 'hidratacion';
    _estado = punto?.estado ?? 'abierto';
    _confianza = punto?.confianza ?? 'oficial';
    _direccionVerificada = punto?.direccionVerificada ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _horarioController.dispose();
    _descripcionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final data = {
      'nombre': _nombreController.text.trim(),
      'tipo': _tipo,
      'direccion': _direccionController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'lat': double.parse(_latController.text.trim()),
      'lng': double.parse(_lngController.text.trim()),
      'horario': _horarioController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'estado': _estado,
      'confianza': _confianza,
      'direccionVerificada': _direccionVerificada,
      'confirmaciones': widget.punto?.confirmaciones ?? 0,
      'votosAbiertoHoy': widget.punto?.votosAbiertoHoy ?? 0,
      'votosCerradoHoy': widget.punto?.votosCerradoHoy ?? 0,
      'diaVotacion': widget.punto?.diaVotacion ?? '',
    };

    try {
      if (_editando) {
        await _adminService.actualizarPunto(widget.punto!, data);
      } else {
        await _adminService.crearPuntoOficial(data);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo necesario';
    return null;
  }

  String? _numero(String? value) {
    final requerido = _requerido(value);
    if (requerido != null) return requerido;
    if (double.tryParse(value!.trim()) == null) return 'Número inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar punto' : 'Nuevo punto oficial'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(labelText: 'Latitud'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: _numero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(labelText: 'Longitud'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: _numero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'hidratacion', child: Text('Agua')),
                DropdownMenuItem(value: 'sombra', child: Text('Sombra')),
                DropdownMenuItem(value: 'aire', child: Text('Aire')),
                DropdownMenuItem(value: 'refugio', child: Text('Refugio')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _tipo = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _estado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(value: 'abierto', child: Text('Abierto')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'cerrado', child: Text('Cerrado')),
                DropdownMenuItem(
                  value: 'sin_confirmar',
                  child: Text('Sin verificar'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _estado = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _confianza,
              decoration: const InputDecoration(labelText: 'Confianza'),
              items: const [
                DropdownMenuItem(value: 'oficial', child: Text('Oficial')),
                DropdownMenuItem(value: 'comunidad', child: Text('Comunidad')),
                DropdownMenuItem(value: 'reciente', child: Text('Reciente')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'cerrado', child: Text('Cerrado')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _confianza = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _horarioController,
              decoration: const InputDecoration(labelText: 'Horario'),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Qué ofrece'),
              minLines: 3,
              maxLines: 5,
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _direccionVerificada,
              onChanged: (value) {
                setState(() => _direccionVerificada = value);
              },
              title: const Text('Dirección verificada'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
