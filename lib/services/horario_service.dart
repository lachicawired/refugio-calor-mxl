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

    final normalizado = limpio
        .replaceAll('a. m.', 'am')
        .replaceAll('a.m.', 'am')
        .replaceAll('a. m', 'am')
        .replaceAll('p. m.', 'pm')
        .replaceAll('p.m.', 'pm')
        .replaceAll('p. m', 'pm')
        .replaceAll('–', '-')
        .replaceAll('—', '-');

    final regex = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:a|\/|-)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    );
    final match = regex.firstMatch(normalizado);
    if (match == null) {
      return const EstadoHorario(abierto: null, texto: 'Horario no disponible');
    }

    final inicioHora = _hora24(int.parse(match.group(1)!), match.group(3));
    final inicioMinuto = int.tryParse(match.group(2) ?? '0') ?? 0;
    final finHora = _hora24(int.parse(match.group(4)!), match.group(6));
    final finMinuto = int.tryParse(match.group(5) ?? '0') ?? 0;

    if (!_horaValida(inicioHora, inicioMinuto) ||
        !_horaValida(finHora, finMinuto)) {
      return const EstadoHorario(abierto: null, texto: 'Horario no disponible');
    }

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

  static int _hora24(int hora, String? periodo) {
    final periodoNormalizado = periodo?.toLowerCase();
    if (periodoNormalizado == 'am') return hora == 12 ? 0 : hora;
    if (periodoNormalizado == 'pm') return hora == 12 ? 12 : hora + 12;
    return hora;
  }

  static bool _horaValida(int hora, int minuto) {
    return hora >= 0 && hora <= 23 && minuto >= 0 && minuto <= 59;
  }
}
