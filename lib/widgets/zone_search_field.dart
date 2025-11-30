import 'package:flutter/material.dart';
import 'package:myapp/data/zones_cote_ivoire.dart';

/// Widget de recherche et sélection de zone avec autocomplétion
class ZoneSearchField extends StatefulWidget {
  final String? initialValue;
  final String labelText;
  final String hintText;
  final IconData icon;
  final Function(String) onZoneSelected;
  final String? Function(String?)? validator;

  const ZoneSearchField({
    super.key,
    this.initialValue,
    required this.labelText,
    required this.hintText,
    required this.icon,
    required this.onZoneSelected,
    this.validator,
  });

  @override
  State<ZoneSearchField> createState() => _ZoneSearchFieldState();
}

class _ZoneSearchFieldState extends State<ZoneSearchField> {
  static const _orangeColor = Color(0xFFF77F00);
  static const _borderRadius = 12.0;
  static const _maxSuggestions = 10;
  static const _overlayOffset = Offset(0, 5);
  static const _maxOverlayHeight = 300.0;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _controller.text = widget.initialValue!;
    }

    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text;
    setState(() {
      _suggestions =
          (query.isEmpty
                  ? ZonesCoteIvoire.zones
                  : ZonesCoteIvoire.rechercher(query))
              .take(_maxSuggestions)
              .toList();
    });
    _updateOverlay();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _onSearchChanged();
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + _overlayOffset.dy),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(_borderRadius),
            child: _suggestions.isEmpty
                ? _buildEmptyState()
                : _buildSuggestionsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildContainerDecoration(),
      child: const Text(
        'Aucune zone trouvée',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: _maxOverlayHeight),
      decoration: _buildContainerDecoration(),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) =>
            _buildSuggestionTile(_suggestions[index]),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_borderRadius),
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  Widget _buildSuggestionTile(String zone) {
    final parts = zone.split(', ');
    final ville = parts.isNotEmpty ? parts[0] : zone;
    final departement = parts.length > 1 ? parts[1] : '';
    final region = parts.length > 2 ? parts[2] : '';

    return ListTile(
      dense: true,
      title: Text(
        ville,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        departement.isNotEmpty ? '$departement, $region' : region,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      leading: const Icon(Icons.location_on, color: _orangeColor, size: 20),
      onTap: () {
        _controller.text = zone;
        widget.onZoneSelected(zone);
        _focusNode.unfocus();
        _removeOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icon(widget.icon, color: _orangeColor),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.onZoneSelected('');
                  },
                )
              : const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: _buildInputBorder(Colors.grey.shade300),
          enabledBorder: _buildInputBorder(Colors.grey.shade300),
          focusedBorder: _buildInputBorder(_orangeColor, width: 2),
          errorBorder: _buildInputBorder(Colors.red),
          focusedErrorBorder: _buildInputBorder(Colors.red, width: 2),
        ),
        validator: widget.validator,
      ),
    );
  }

  OutlineInputBorder _buildInputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
