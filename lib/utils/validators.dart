class Validators {
  static String? validateHandle(String handle) {
    // Must start with a letter
    if (handle.isEmpty) {
      return 'Handle cannot be empty';
    }
    
    // Must start with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(handle)) {
      return 'Handle must start with a letter';
    }
    
    // Alphanumeric + underscore only, no spaces
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(handle)) {
      return 'Only letters, numbers, and underscores allowed.';
    }
    
    // Min 3 chars
    if (handle.length < 3) {
      return 'Must be at least 3 characters.';
    }
    
    // Max 20 chars
    if (handle.length > 20) {
      return 'Must be 20 characters or less.';
    }
    
    return null; // Valid
  }
}
