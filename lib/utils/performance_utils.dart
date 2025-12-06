import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Performance utilities for better app performance
class PerformanceUtils {
  /// Cache for expensive computations
  static final Map<String, dynamic> _computationCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Memoization for expensive computations
  static T memoize<T>(String key, T Function() computation) {
    final now = DateTime.now();

    if (_computationCache.containsKey(key) &&
        _cacheTimestamps.containsKey(key) &&
        now.difference(_cacheTimestamps[key]!) < _cacheExpiry) {
      return _computationCache[key] as T;
    }

    final result = computation();
    _computationCache[key] = result;
    _cacheTimestamps[key] = now;

    return result;
  }

  /// Clear computation cache
  static void clearComputationCache() {
    _computationCache.clear();
    _cacheTimestamps.clear();
  }
}

/// Optimized cached network image with error handling and loading states
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final bool useOldImageOnUrlChange;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.useOldImageOnUrlChange = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      placeholder: (context, url) => placeholder ??
          _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ??
          _buildErrorWidget(),
      placeholderFadeInDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius as BorderRadius,
        child: image,
      );
    }

    return image;
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 200,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      color: Colors.grey[200],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }
}

/// Virtualized list for large datasets with performance optimizations
class VirtualizedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int initialItemCount;
  final int loadMoreThreshold;
  final Future<void> Function()? onLoadMore;
  final bool isLoading;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const VirtualizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialItemCount = 20,
    this.loadMoreThreshold = 5,
    this.onLoadMore,
    this.isLoading = false,
    this.loadingWidget,
    this.emptyWidget,
    this.scrollController,
    this.padding,
    this.physics,
  });

  @override
  State<VirtualizedList<T>> createState() => _VirtualizedListState<T>();
}

class _VirtualizedListState<T> extends State<VirtualizedList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || widget.onLoadMore == null) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll - (widget.loadMoreThreshold * 100.0);

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      await widget.onLoadMore?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? const Center(
        child: Text('No items to display'),
      );
    }

    final displayCount = widget.items.length < widget.initialItemCount
        ? widget.items.length
        : widget.initialItemCount;

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      itemCount: displayCount + (widget.isLoading || _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < displayCount) {
          return widget.itemBuilder(context, widget.items[index], index);
        } else {
          return widget.loadingWidget ?? _buildLoadingWidget();
        }
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

/// Debounced search utility to reduce API calls
class DebouncedSearch {
  final Duration delay;
  Timer? _timer;

  DebouncedSearch({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Image preloader for better UX
class ImagePreloader {
  static final Set<String> _preloadedImages = {};

  static Future<void> preloadImages(List<String> urls) async {
    final futures = <Future>[];

    for (final url in urls) {
      if (!_preloadedImages.contains(url)) {
        futures.add(
          precacheImage(NetworkImage(url), null as BuildContext)
              .catchError((_) => null) // Ignore errors
        );
        _preloadedImages.add(url);
      }
    }

    await Future.wait(futures);
  }

  static void clearCache() {
    _preloadedImages.clear();
  }
}

/// Memory-efficient list view with recycling
class RecyclingListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Axis scrollDirection;

  const RecyclingListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
