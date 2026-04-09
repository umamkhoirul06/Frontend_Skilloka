/// Expandable Search Bar with voice input capability
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';

class AppSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onFilterPressed;
  final bool showVoiceButton;
  final bool showFilterButton;
  final bool expandable;
  final bool autofocus;
  final List<String>? recentSearches;
  final ValueChanged<String>? onRecentSearchTap;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Cari kursus atau LPK...',
    this.onChanged,
    this.onSubmitted,
    this.onVoicePressed,
    this.onFilterPressed,
    this.showVoiceButton = true,
    this.showFilterButton = false,
    this.expandable = false,
    this.autofocus = false,
    this.recentSearches,
    this.onRecentSearchTap,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _expandController;
  late Animation<double> _widthAnimation;
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _expandController = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    );
    _widthAnimation = Tween<double>(begin: 48, end: 1).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: AppAnimations.defaultCurve,
      ),
    );

    if (!widget.expandable) {
      _isExpanded = true;
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _expandController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (widget.recentSearches == null || widget.recentSearches!.isEmpty) return;

    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: AppShapes.borderRadiusMD,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppShapes.borderRadiusMD,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.recentSearches!.length,
              itemBuilder: (context, index) {
                final search = widget.recentSearches![index];
                return ListTile(
                  leading: const Icon(
                    Icons.history,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  title: Text(search, style: AppTypography.bodyMedium),
                  dense: true,
                  onTap: () {
                    _controller.text = search;
                    _focusNode.unfocus();
                    widget.onRecentSearchTap?.call(search);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleExpand() {
    if (!widget.expandable) return;

    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
      _focusNode.requestFocus();
    } else {
      _expandController.reverse();
      _focusNode.unfocus();
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expandable) {
      return AnimatedBuilder(
        animation: _widthAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: AppAnimations.medium,
            width: _isExpanded ? double.infinity : 48,
            child: _buildSearchField(),
          );
        },
      );
    }

    return _buildSearchField();
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.chipRadius,
        border: _focusNode.hasFocus
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Search Icon / Expand Button
          GestureDetector(
            onTap: widget.expandable ? _toggleExpand : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search,
                color: _focusNode.hasFocus
                    ? AppColors.primary
                    : AppColors.textTertiary,
                size: 24,
              ),
            ),
          ),

          // Text Field
          if (_isExpanded)
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),

          // Clear Button
          if (_isExpanded && _controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: AppColors.textTertiary,
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
                setState(() {});
              },
            ),

          // Voice Button
          if (widget.showVoiceButton && _isExpanded)
            IconButton(
              icon: const Icon(Icons.mic, size: 22),
              color: AppColors.textTertiary,
              onPressed: widget.onVoicePressed,
            ),

          // Filter Button
          if (widget.showFilterButton && _isExpanded)
            IconButton(
              icon: const Icon(Icons.tune, size: 22),
              color: AppColors.textTertiary,
              onPressed: widget.onFilterPressed,
            ),
        ],
      ),
    );
  }
}
