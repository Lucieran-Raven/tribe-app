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
      return 'Handle can only contain letters, numbers, and underscores';
    }
    
    // Min 3 chars
    if (handle.length < 3) {
      return 'Handle must be at least 3 characters';
    }
    
    // Max 20 chars
    if (handle.length > 20) {
      return 'Handle must be at most 20 characters';
    }
    
    return null; // Valid
  }
}
