import 'package:flutter/material.dart';

import 'mascot_state.dart';

/// Renders the mascot's PNG illustration for a given [state].
///
/// Stateless and state-agnostic — it receives the [MascotState] as a plain
/// parameter rather than reading a [MascotCubit] itself. This keeps it
/// reusable in contexts where the state is hardcoded (empty states, modals)
/// as well as contexts driven by a cubit (wrap it in a `BlocBuilder`).
class MascotWidget extends StatelessWidget {
  final MascotState state;
  final double size;

  const MascotWidget({super.key, required this.state, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/mascot/${state.name}.png',
          width: size,
          height: size,
          // Decode at 2x the default display size — saves RAM vs. loading
          // the full 300px source everywhere it's used.
          cacheWidth: 240,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
