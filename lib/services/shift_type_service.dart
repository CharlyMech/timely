import 'package:timely/models/shift_type.dart';

/// Service interface for managing shift type definitions.
///
/// Defines the contract for retrieving shift type information including
/// names, time schedules, and color coding.
abstract class ShiftTypeService {
  /// Retrieves all available shift types.
  ///
  /// Returns a list of all [ShiftType] records. Implementations may use
  /// caching to optimize repeated calls since shift types rarely change.
  Future<List<ShiftType>> getAllShiftTypes();

  /// Retrieves a specific shift type by its unique identifier.
  ///
  /// Returns the [ShiftType] with the given [id], or null if not found.
  Future<ShiftType?> getShiftTypeById(String id);
}
