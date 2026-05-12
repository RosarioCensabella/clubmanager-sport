import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});
