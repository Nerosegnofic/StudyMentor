/// The mascot's emotional state.
///
/// Single source of truth for the mascot across the entire app — in-app
/// widgets, system notifications, and (eventually) the native overlay all
/// key off this same enum.
enum MascotState { idle, happy, thinking, sad, celebration }
