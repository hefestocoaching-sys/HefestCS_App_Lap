/// Defines the training split type for the Motor V3 engine.
///
/// Used by [CycleTemplateBuilder] to distribute muscles across days
/// and by [MotorV3Orchestrator] to resolve the user's preferred split.
enum TrainingSplit { fullBody, upperLower, pushPullLegs }
