import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/magnetic_button.dart';

// ── Product model ──────────────────────────────────────────────────────────────

class _Product {
  const _Product(this.name, this.price, this.category, this.emoji, this.rating);
  final String name;
  final int price;
  final String category;
  final String emoji;
  final double rating;
}

const _allProducts = [
  _Product('Wireless Earbuds', 2499, 'Electronics', '🎧', 4.5),
  _Product('Phone Stand', 399, 'Accessories', '📱', 4.1),
  _Product('Smart Watch', 8999, 'Electronics', '⌚', 4.7),
  _Product('Laptop Riser', 1299, 'Desk', '💻', 4.3),
  _Product('Ceramic Mug', 349, 'Kitchen', '☕', 4.8),
  _Product('Yoga Mat', 799, 'Fitness', '🧘', 4.6),
  _Product('Sunglasses', 1199, 'Fashion', '🕶️', 4.2),
  _Product('Running Shoes', 3499, 'Fitness', '👟', 4.9),
  _Product('BT Speaker', 4299, 'Electronics', '🔊', 4.4),
  _Product('Steel Bottle', 599, 'Kitchen', '💧', 4.7),
  _Product('Notebook Set', 249, 'Desk', '📒', 4.3),
  _Product('Backpack', 2199, 'Fashion', '🎒', 4.6),
];

const _categories = [
  'All', 'Electronics', 'Accessories', 'Desk', 'Kitchen', 'Fitness', 'Fashion'
];

// Category accent colors
const _catColors = {
  'Electronics': AppColors.cyan,
  'Accessories': AppColors.violet,
  'Desk': AppColors.amber,
  'Kitchen': AppColors.mint,
  'Fitness': AppColors.pink,
  'Fashion': Color(0xFFB06EF0),
};

// ── Sort enum ─────────────────────────────────────────────────────────────────

enum _Sort { none, priceAsc, priceDesc, nameAsc }

extension _SortLabel on _Sort {
  String get label {
    switch (this) {
      case _Sort.none: return 'Relevance';
      case _Sort.priceAsc: return 'Price ↑';
      case _Sort.priceDesc: return 'Price ↓';
      case _Sort.nameAsc: return 'A → Z';
    }
  }
}

// ── Demo widget ────────────────────────────────────────────────────────────────

class ZadingaDemo extends StatefulWidget {
  const ZadingaDemo({super.key});

  @override
  State<ZadingaDemo> createState() => _ZadingaDemoState();
}

class _ZadingaDemoState extends State<ZadingaDemo> {
  String _query = '';
  String _category = 'All';
  _Sort _sort = _Sort.none;
  int _pageSize = 6;
  final Map<String, int> _cart = {};
  int _cartBounceKey = 0;

  List<_Product> get _visible {
    var src = _allProducts.take(_pageSize).toList();
    if (_category != 'All') src = src.where((p) => p.category == _category).toList();
    if (_query.isNotEmpty) {
      src = src
          .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }
    switch (_sort) {
      case _Sort.priceAsc: src.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priceDesc: src.sort((a, b) => b.price.compareTo(a.price));
      case _Sort.nameAsc: src.sort((a, b) => a.name.compareTo(b.name));
      case _Sort.none: break;
    }
    return src;
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);
  int get _cartTotal => _cart.entries.fold(0, (s, e) {
        final p = _allProducts.firstWhere((p) => p.name == e.key,
            orElse: () => const _Product('', 0, '', '', 0));
        return s + p.price * e.value;
      });

  void _addToCart(_Product p) {
    setState(() {
      _cart[p.name] = (_cart[p.name] ?? 0) + 1;
      _cartBounceKey++;
    });
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CartSheet(
        cart: Map.from(_cart),
        products: _allProducts,
        onQtyChanged: (name, delta) {
          setState(() {
            final next = (_cart[name] ?? 0) + delta;
            if (next <= 0) _cart.remove(name); else _cart[name] = next;
          });
        },
        onCheckout: () {
          setState(() => _cart.clear());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final hasMore = _pageSize < _allProducts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Search + sort + cart ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(Insets.md, Insets.md, Insets.md, 0),
          child: Row(
            children: [
              Expanded(child: _SearchField(onChanged: (v) => setState(() => _query = v))),
              const SizedBox(width: Insets.sm),
              _SortDropdown(
                value: _sort,
                onChanged: (v) => setState(() => _sort = v),
              ),
              const SizedBox(width: Insets.sm),
              _CartButton(count: _cartCount, bounceKey: _cartBounceKey, onTap: _cartCount > 0 ? _openCart : null),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        // ── Category chips ────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Insets.md),
          child: Row(
            children: [
              for (final cat in _categories) ...[
                _CategoryChip(
                  label: cat,
                  selected: _category == cat,
                  color: _catColors[cat] ?? AppColors.cyan,
                  onTap: () => setState(() => _category = cat),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        // ── Product grid ──────────────────────────────────────────────────
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Insets.md, 0, Insets.md, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProductGrid(products: visible, onAddToCart: _addToCart),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Insets.xl),
                    child: Text('No products found.',
                        style: AppText.body(size: 14, color: AppColors.textTertiary)),
                  ),
                if (hasMore) ...[
                  const SizedBox(height: Insets.md),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _pageSize = _allProducts.length),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.glassHigh,
                          borderRadius: BorderRadius.circular(Corners.pill),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: Text(
                          'Load more  (${_allProducts.length - _pageSize} more)',
                          style: AppText.body(
                              size: 13, weight: FontWeight.w500, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Insets.md),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Search field ───────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: AppText.body(size: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search products…',
        hintStyle: AppText.body(size: 14, color: AppColors.textTertiary),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 10),
        filled: true,
        fillColor: AppColors.glassHigh,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Corners.pill),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Corners.pill),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Corners.pill),
            borderSide: const BorderSide(color: AppColors.cyan)),
      ),
    );
  }
}

// ── Sort dropdown ──────────────────────────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});
  final _Sort value;
  final ValueChanged<_Sort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.glassHigh,
        borderRadius: BorderRadius.circular(Corners.md),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_Sort>(
          value: value,
          dropdownColor: AppColors.surface,
          style: AppText.mono(size: 11, color: AppColors.textPrimary, spacing: 0),
          iconSize: 14,
          icon: const Icon(Icons.sort_rounded, size: 14, color: AppColors.textTertiary),
          items: _Sort.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// ── Category chip ──────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.color, required this.onTap});
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.16) : AppColors.glassHigh,
          borderRadius: BorderRadius.circular(Corners.pill),
          border: Border.all(color: selected ? color.withOpacity(0.55) : AppColors.border),
        ),
        child: Text(label,
            style: AppText.mono(
                size: 11, color: selected ? color : AppColors.textSecondary, spacing: 0)),
      ),
    );
  }
}

// ── Cart button ────────────────────────────────────────────────────────────────

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.bounceKey, this.onTap});
  final int count;
  final int bounceKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: count > 0 ? AppColors.cyan.withOpacity(0.12) : AppColors.glassHigh,
              borderRadius: BorderRadius.circular(Corners.md),
              border: Border.all(
                  color: count > 0 ? AppColors.cyan.withOpacity(0.4) : AppColors.border),
            ),
            child: Icon(Icons.shopping_bag_outlined,
                size: 20, color: count > 0 ? AppColors.cyan : AppColors.textSecondary),
          ),
          if (count > 0)
            Positioned(
              top: -7,
              right: -7,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(bounceKey),
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 1.6, end: 1.0),
                curve: Curves.elasticOut,
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$count',
                        style: AppText.mono(size: 10, color: Colors.black, spacing: 0)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Product grid ───────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onAddToCart});
  final List<_Product> products;
  final ValueChanged<_Product> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final p in products)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 74) / 2,
            child: _ProductCard(product: p, onAdd: () => onAddToCart(p)),
          ),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({required this.product, required this.onAdd});
  final _Product product;
  final VoidCallback onAdd;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.product.category;
    final accent = _catColors[cat] ?? AppColors.cyan;
    return GlassContainer(
      padding: const EdgeInsets.all(Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail
          Stack(
            children: [
              Container(
                height: 72,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withOpacity(0.15), AppColors.glassHigh],
                  ),
                  borderRadius: BorderRadius.circular(Corners.sm),
                ),
                child: Center(
                  child: Text(widget.product.emoji, style: const TextStyle(fontSize: 30)),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(Corners.pill),
                  ),
                  child: Text(cat,
                      style: AppText.mono(size: 8, color: accent, spacing: 0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.product.name,
              style: AppText.body(
                  size: 12, weight: FontWeight.w500, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Row(
            children: [
              Text('₹${widget.product.price}',
                  style: AppText.mono(size: 12, color: accent, spacing: 0)),
              const Spacer(),
              Text('★ ${widget.product.rating}',
                  style: AppText.mono(size: 9, color: AppColors.amber, spacing: 0)),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) { setState(() => _pressed = false); widget.onAdd(); },
              onTapCancel: () => setState(() => _pressed = false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(Corners.sm),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text('+ Add',
                      style: AppText.mono(size: 11, color: accent, spacing: 0)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart sheet ─────────────────────────────────────────────────────────────────

class _CartSheet extends StatefulWidget {
  const _CartSheet({
    required this.cart,
    required this.products,
    required this.onQtyChanged,
    required this.onCheckout,
  });
  final Map<String, int> cart;
  final List<_Product> products;
  final void Function(String name, int delta) onQtyChanged;
  final VoidCallback onCheckout;

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  bool _checkoutDone = false;
  late Map<String, int> _localCart;

  @override
  void initState() {
    super.initState();
    _localCart = Map.from(widget.cart);
  }

  int get _total => _localCart.entries.fold(0, (s, e) {
        final p = widget.products
            .firstWhere((p) => p.name == e.key, orElse: () => const _Product('', 0, '', '', 0));
        return s + p.price * e.value;
      });

  void _updateQty(String name, int delta) {
    setState(() {
      final next = (_localCart[name] ?? 0) + delta;
      if (next <= 0) _localCart.remove(name); else _localCart[name] = next;
    });
    widget.onQtyChanged(name, delta);
  }

  void _checkout() {
    setState(() => _checkoutDone = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) { Navigator.of(context).pop(); widget.onCheckout(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Corners.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: _checkoutDone ? _buildSuccess() : _buildItems(),
    );
  }

  Widget _buildItems() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Row(
            children: [
              Text('Cart', style: AppText.display(size: 20, weight: FontWeight.w700)),
              const Spacer(),
              Text('₹$_total',
                  style: AppText.mono(size: 16, color: AppColors.cyan, spacing: 0)),
            ],
          ),
        ),
        const Divider(color: AppColors.border, height: 1),
        if (_localCart.isEmpty)
          const Padding(
            padding: EdgeInsets.all(Insets.xl),
            child: Text('Cart is empty.', style: TextStyle(color: AppColors.textTertiary)),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.sm),
              children: [
                for (final e in _localCart.entries)
                  _CartRow(
                    name: e.key,
                    qty: e.value,
                    price: widget.products
                        .firstWhere((p) => p.name == e.key,
                            orElse: () => const _Product('', 0, '', '', 0))
                        .price,
                    onInc: () => _updateQty(e.key, 1),
                    onDec: () => _updateQty(e.key, -1),
                  ),
              ],
            ),
          ),
        if (_localCart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: MagneticButton(
              label: 'Checkout  ·  ₹$_total',
              filled: true,
              onPressed: _checkout,
            ),
          ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(Insets.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 52),
          const SizedBox(height: Insets.md),
          Text('Order placed!', style: AppText.display(size: 22, weight: FontWeight.w700)),
          const SizedBox(height: Insets.sm),
          Text('Your ₹$_total order is confirmed. Thank you!',
              style: AppText.body(size: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.name, required this.qty, required this.price, required this.onInc, required this.onDec});
  final String name;
  final int qty;
  final int price;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppText.body(
                        size: 13, weight: FontWeight.w500, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('₹$price × $qty = ₹${price * qty}',
                    style: AppText.mono(size: 11, color: AppColors.textSecondary, spacing: 0)),
              ],
            ),
          ),
          _QtyCtrl(qty: qty, onInc: onInc, onDec: onDec),
        ],
      ),
    );
  }
}

class _QtyCtrl extends StatelessWidget {
  const _QtyCtrl({required this.qty, required this.onInc, required this.onDec});
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Btn(icon: Icons.remove_rounded, onTap: onDec),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('$qty',
            style: AppText.mono(size: 13, color: AppColors.textPrimary, spacing: 0)),
      ),
      _Btn(icon: Icons.add_rounded, onTap: onInc),
    ]);
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.glassHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
