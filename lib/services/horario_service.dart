class EstadoHorario {
  final bool? abierto;
  final String texto;

  const EstadoHorario({required this.abierto, required this.texto});
}

class HorarioService {
  static EstadoHorario calcular(String horario, {DateTime? ahora}) {
    final limpio = horario.trim().toLowerCase();
    if (limpio.isEmpty ||
        limpio == 'por confirmar' ||
        limpio == 'sin confirmar') {
      return const EstadoHorario(abierto: null, texto: 'Horario no disponible');
    }

    if (limpio.contains('24')) {
      return const EstadoHorario(abierto: true, texto: 'Abierto ahora');
    }

    final regex = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(?:a|\/|-|–)\s*(\d{1,2})(?::(\d{2}))?',
    );
    final match = regex.firstMatch(limpio);
    if (match == null) {
      return const EstadoHorario(abierto: null, texto: 'Horario no disponible');
    }

    final inicioHora = int.parse(match.group(1)!);
    final inicioMinuto = int.tryParse(match.group(2) ?? '0') ?? 0;
    final finHora = int.parse(match.group(3)!);
    final finMinuto = int.tryParse(match.group(4) ?? '0') ?? 0;

    final ahoraLocal = ahora ?? DateTime.now();
    final minutosAhora = ahoraLocal.hour * 60 + ahoraLocal.minute;
    final minutosInicio = inicioHora * 60 + inicioMinuto;
    final minutosFin = finHora * 60 + finMinuto;

    final abierto = minutosInicio <= minutosFin
        ? minutosAhora >= minutosInicio && minutosAhora < minutosFin
        : minutosAhora >= minutosInicio || minutosAhora < minutosFin;

    return EstadoHorario(
      abierto: abierto,
      texto: abierto ? 'Abierto ahora' : 'Cerrado ahora',
    );
  }

  static String textoCombinado({
    required String horario,
    required String estadoComunitario,
    DateTime? ahora,
  }) {
    if (estadoComunitario == 'cerrado') {
      return 'Reportado cerrado por comunidad';
    }
    if (estadoComunitario == 'abierto') {
      return 'Confirmado abierto por comunidad';
    }

    return calcular(horario, ahora: ahora).texto;
  }
}
