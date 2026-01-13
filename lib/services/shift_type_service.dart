import 'package:timely/models/shift_type.dart';

// Interface
abstract class ShiftTypeService {
  Future<List<ShiftType>> getAllShiftTypes();
  Future<ShiftType?> getShiftTypeById(String id);
}
