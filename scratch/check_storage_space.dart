import 'package:storage_space/storage_space.dart';

void main() async {
  // Just to trigger compilation and see errors or find properties
  final space = StorageSpace(
    freeSize: '0',
    usedSize: '0',
    totalSize: '0',
    usageValue: 0.0, // Guessing
  );
  print(space.usageValue);
}
