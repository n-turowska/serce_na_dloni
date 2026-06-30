bool isValidEmail(String email) {
  final cleanEmail = email.trim();
  final atParts = cleanEmail.split('@');
  if (atParts.length != 2) return false;

  final localPart = atParts[0];
  final domainPart = atParts[1];

  if (localPart.isEmpty || domainPart.isEmpty) return false;
  if (!domainPart.contains('.')) return false;

  final dotParts = domainPart.split('.');
  for (final part in dotParts) {
    if (part.isEmpty) return false;
  }

  if (dotParts.last.length < 2) return false;

  return true;
}
