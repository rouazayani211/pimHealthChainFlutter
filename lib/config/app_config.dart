class AppConfig {
  // Base API URL
  static const String apiBaseUrl = 'http://192.168.0.107:3000'; // Base URL without /users
  static const String socketUrl = 'ws://192.168.0.107:3000'; // Align with API host
  
  // Function to get the complete image URL
  static String getImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return '';
    }
    
    // Log the input path for debugging
    print('Original photo path: $photoPath');
    
    // If the path already starts with http, return it as is
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    // Handle doctor image endpoint
    if (photoPath.contains('/users/doctor/image/')) {
      return photoPath;
    }
    
    // Handle direct user image endpoint URLs
    if (photoPath.contains('/users/image/')) {
      return photoPath;
    }
    
    // Special case for this specific photo from MongoDB
    if (photoPath == "uploads/photo-174639616390-336940724.jpg") {
      return '$apiBaseUrl/$photoPath';
    }
    
    // If the path is a full path from the multer implementation:
    // Handle paths like "photo-12345-67890.jpg" as defined in UserController
    if (photoPath.startsWith('photo-')) {
      return '$apiBaseUrl/uploads/$photoPath';
    }
    
    // If the path already has /uploads, just add the base URL
    if (photoPath.startsWith('/uploads/')) {
      return '$apiBaseUrl$photoPath';
    }
    
    // If the path has uploads/ without leading slash
    if (photoPath.startsWith('uploads/')) {
      return '$apiBaseUrl/$photoPath';
    }
    
    // Handle full paths - from your backend, it might be the relative path to the Uploads folder
    if (photoPath.startsWith('/')) {
      return '$apiBaseUrl$photoPath';
    }
    
    // If the path is just a filename or any other format, ensure it's properly joined with uploads
    return '$apiBaseUrl/uploads/$photoPath';
  }
}
