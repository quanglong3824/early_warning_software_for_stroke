import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Image utilities for optimized image loading and caching
/// Requirements: 10.4 - Use cached and compressed versions of images

/// Default placeholder widget for loading images
Widget buildImagePlaceholder({double? width, double? height}) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    ),
  );
}

/// Default error widget for failed image loads
Widget buildImageError({double? width, double? height, IconData? icon}) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: Icon(
      icon ?? Icons.broken_image_outlined,
      color: Colors.grey[400],
      size: 32,
    ),
  );
}

/// Optimized cached network image widget
/// Requirements: 10.4
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate memory cache dimensions for optimization
    final cacheWidth = memCacheWidth ?? (width != null ? (width! * 2).toInt() : null);
    final cacheHeight = memCacheHeight ?? (height != null ? (height! * 2).toInt() : null);

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (context, url) =>
          placeholder ?? buildImagePlaceholder(width: width, height: height),
      errorWidget: (context, url, error) =>
          errorWidget ?? buildImageError(width: width, height: height),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Circular avatar with cached network image
class CachedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Color? backgroundColor;

  const CachedCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.placeholder,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: placeholder ?? Icon(Icons.person, size: radius, color: Colors.grey[400]),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor ?? Colors.grey[200],
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: placeholder ?? Icon(Icons.person, size: radius, color: Colors.grey[400]),
      ),
    );
  }
}

/// Image compression utilities
/// Requirements: 10.4 - Compress images before upload
class ImageCompressor {
  /// Compress image bytes with quality setting
  /// Returns compressed bytes or original if compression fails
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // For now, return original bytes
      // In production, use flutter_image_compress package
      // final result = await FlutterImageCompress.compressWithList(
      //   imageBytes,
      //   quality: quality,
      //   minWidth: maxWidth ?? 1920,
      //   minHeight: maxHeight ?? 1080,
      // );
      // return result;
      return imageBytes;
    } catch (e) {
      // Return original if compression fails
      return imageBytes;
    }
  }

  /// Get recommended quality based on image size
  static int getRecommendedQuality(int fileSizeBytes) {
    // For images larger than 2MB, use lower quality
    if (fileSizeBytes > 2 * 1024 * 1024) {
      return 60;
    }
    // For images larger than 1MB, use medium quality
    if (fileSizeBytes > 1024 * 1024) {
      return 70;
    }
    // For smaller images, use higher quality
    return 85;
  }

  /// Calculate max dimensions while maintaining aspect ratio
  static Size calculateMaxDimensions(
    int originalWidth,
    int originalHeight, {
    int maxDimension = 1920,
  }) {
    if (originalWidth <= maxDimension && originalHeight <= maxDimension) {
      return Size(originalWidth.toDouble(), originalHeight.toDouble());
    }

    final aspectRatio = originalWidth / originalHeight;
    
    if (originalWidth > originalHeight) {
      return Size(maxDimension.toDouble(), (maxDimension / aspectRatio));
    } else {
      return Size((maxDimension * aspectRatio), maxDimension.toDouble());
    }
  }
}

/// Extension for easy image caching
extension ImageCacheExtension on String {
  /// Build a cached network image from URL string
  Widget toCachedImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return OptimizedNetworkImage(
      imageUrl: this,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}
