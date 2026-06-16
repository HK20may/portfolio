import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/magnetic_button.dart';

// ── Product model ──────────────────────────────────────────────────────────────

class _Item {
  const _Item(this.name, this.price, this.emoji, this.unit);
  final String name;
  final int price;
  final String emoji;
  final String unit;
}

const _catalog = [
  _Item('Fresh Spinach', 25, '🥬', '250 g'),
  _Item('Tomatoes', 45, '🍅', '1 kg'),
  _Item('Onions', 35, '🧅', '1 kg'),
  _Item('Basmati Rice', 299, '🍚', '5 kg'),
  _Item('Whole Wheat Bread', 45, '🍞', '400 g'),
  _Item('Farm Eggs', 89, '🥚', '×12'),
  _Item('Dahi', 55, '🥛', '500 g'),
  _Item('Paneer', 79, '🧀', '200 g'),
];

// ── Order status ───────────────────────────────────────────────────────────────

enum _Status { cart, placed, packing, outForDelivery, delivered }

extension _StatusX on _Status {
  String get label {
    switch (this) {
      case _Status.cart: return 'Cart';
      case _Status.placed: return 'Order Placed';
      case _Status.packing: return 'Being Packed';
      case _Status.outForDelivery: return 'Out for Delivery';
      case _Status.delivered: return 'Delivered!';
    }
  }

  IconData get icon {
    switch (this) {
      case _Status.cart: return Icons.shopping_cart_outlined;
      case _Status.placed: return Icons.receipt_long_outlined;
      case _Status.packing: return Icons.inventory_2_outlined;
      case _Status.outForDelivery: return Icons.delivery_dining_rounded;
      case _Status.delivered: return Icons.check_circle_rounded;
    }
  }

  int get step {
    switch (this) {
      case _Status.cart: return -1;
      case _Status.placed: return 0;
      case _Status.packing: return 1;
      case _Status.outForDelivery: return 2;
      case _Status.delivered: return 3;
    }
  }

  double get courierProgress {
    switch (this) {
      case _Status.cart: return 0.0;
      case _Status.placed: return 0.02;
      case _Status.packing: return 0.18;
      case _Status.outForDelivery: return 0.6;
      case _Status.delivered: return 1.0;
    }
  }
}

// ── Demo widget ────────────────────────────────────────────────────────────────

class FraazoDemo extends StatefulWidget {
  const FraazoDemo({super.key});

  @override
  State<FraazoDemo> createState() => _FraazoDemoState();
}

class _FraazoDemoState extends State<FraazoDemo> {
  final Map<String, int> _cart = {};
  _Status _status = _Status.cart;
  int _etaSec = 28 * 60;

  Timer? _advanceTimer;
  Timer? _countdown;

  int get _cartTotal => _cart.entries.fold(0, (s, e) {
        final item = _catalog.firstWhere((i) => i.name == e.key);
        return s + item.price * e.value;
      });

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _countdown?.cancel();
    super.dispose();
  }

  void _placeOrder() {
    setState(() { _status = _Status.placed; _etaSec = 28 * 60; });

    if (context.reduceMotion) {
      setState(() { _status = _Status.delivered; _etaSec = 0; });
      return;
    }

    final statuses = [_Status.packing, _Status.outForDelivery, _Status.delivered];
    var idx = 0;
    _advanceTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted) return;
      setState(() => _status = statuses[idx]);
      idx++;
      if (idx >= statuses.length) t.cancel();
    });

    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_etaSec > 0) _etaSec--;
        if (_status == _Status.delivered) { _etaSec = 0; t.cancel(); }
      });
    });
  }

  void _reset() {
    _advanceTimer?.cancel();
    _countdown?.cancel();
    setState(() { _status = _Status.cart; _cart.clear(); _etaSec = 28 * 60; });
  }

  @override
  Widget build(BuildContext context) {
    if (_status != _Status.cart) return _buildTracker();
    return _buildCart();
  }

  // ── Cart ───────────────────────────────────────────────────────────────────

  Widget _buildCart() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fresh Groceries',
              style: AppText.display(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: Insets.sm),
          for (final item in _catalog) _GroceryCard(
            item: item,
            qty: _cart[item.name] ?? 0,
            onChanged: (delta) {
              setState(() {
                final next = (_cart[item.name] ?? 0) + delta;
                if (next <= 0) _cart.remove(item.name); else _cart[item.name] = next;
              });
            },
          ),
          const SizedBox(height: Insets.md),
          if (_cartCount > 0) ...[
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.sm),
              child: Row(
                children: [
                  Text('$_cartCount item${_cartCount == 1 ? '' : 's'}',
                      style: AppText.body(size: 14, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('₹$_cartTotal',
                      style: AppText.display(size: 20, weight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: Insets.md),
            MagneticButton(
              label: '🛵  Place Order  ·  ₹$_cartTotal',
              filled: true,
              onPressed: _placeOrder,
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(Insets.xl),
                child: Text('Add items to get started.',
                    style: AppText.body(size: 14, color: AppColors.textTertiary)),
              ),
            ),
          const SizedBox(height: Insets.md),
        ],
      ),
    );
  }

  // ── Tracker ────────────────────────────────────────────────────────────────

  Widget _buildTracker() {
    final delivered = _status == _Status.delivered;
    final etaMin = _etaSec ~/ 60;
    final etaSec = _etaSec % 60;
    final etaStr = delivered
        ? 'Delivered!'
        : '$etaMin:${etaSec.toString().padLeft(2, '0')} remaining';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Order Tracker',
                  style: AppText.display(size: 16, weight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: _reset,
                child: Text('New order →',
                    style: AppText.body(size: 13, color: AppColors.pink, weight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          // ETA chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.sm),
            decoration: BoxDecoration(
              color: (delivered ? AppColors.mint : AppColors.pink).withOpacity(0.12),
              borderRadius: BorderRadius.circular(Corners.pill),
              border: Border.all(
                color: (delivered ? AppColors.mint : AppColors.pink).withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delivered ? Icons.check_circle_rounded : Icons.timer_outlined,
                  size: 15,
                  color: delivered ? AppColors.mint : AppColors.pink,
                ),
                const SizedBox(width: 6),
                Text(etaStr,
                    style: AppText.mono(
                        size: 12,
                        color: delivered ? AppColors.mint : AppColors.pink,
                        spacing: 0)),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          // Stepper
          _OrderStepper(current: _status),
          const SizedBox(height: Insets.lg),
          // Courier progress bar
          GlassContainer(child: _CourierBar(status: _status)),
          // Delivered celebration
          if (delivered) ...[
            const SizedBox(height: Insets.md),
            GlassContainer(
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: Insets.sm),
                  Text('Your order arrived in ${_etaSec == 0 ? "under 30 min" : "${28 - _etaSec ~/ 60} min"}!',
                      style: AppText.body(size: 14, color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: Insets.md),
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(Corners.pill),
                        border: Border.all(color: AppColors.mint.withOpacity(0.4)),
                      ),
                      child: Text('↺  Reorder',
                          style: AppText.mono(size: 12, color: AppColors.mint, spacing: 0)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Insets.md),
        ],
      ),
    );
  }
}

// ── Grocery card ───────────────────────────────────────────────────────────────

class _GroceryCard extends StatelessWidget {
  const _GroceryCard({required this.item, required this.qty, required this.onChanged});
  final _Item item;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.glassHigh,
                borderRadius: BorderRadius.circular(Corners.sm),
              ),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: AppText.body(
                          size: 13, weight: FontWeight.w500, color: AppColors.textPrimary)),
                  Row(
                    children: [
                      Text('₹${item.price}',
                          style: AppText.mono(size: 12, color: AppColors.pink, spacing: 0)),
                      const SizedBox(width: 6),
                      Text(item.unit,
                          style: AppText.mono(size: 10, color: AppColors.textTertiary, spacing: 0)),
                    ],
                  ),
                ],
              ),
            ),
            if (qty == 0)
              GestureDetector(
                onTap: () => onChanged(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(Corners.pill),
                    border: Border.all(color: AppColors.pink.withOpacity(0.35)),
                  ),
                  child: Text('ADD',
                      style: AppText.mono(size: 11, color: AppColors.pink, spacing: 0.5)),
                ),
              )
            else
              Row(
                children: [
                  _SmBtn(icon: Icons.remove_rounded, onTap: () => onChanged(-1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('$qty',
                        style: AppText.mono(size: 14, color: AppColors.textPrimary, spacing: 0)),
                  ),
                  _SmBtn(icon: Icons.add_rounded, onTap: () => onChanged(1)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SmBtn extends StatelessWidget {
  const _SmBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.pink.withOpacity(0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.pink.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 15, color: AppColors.pink),
      ),
    );
  }
}

// ── Order stepper ──────────────────────────────────────────────────────────────

class _OrderStepper extends StatelessWidget {
  const _OrderStepper({required this.current});
  final _Status current;

  static const _steps = [
    _Status.placed,
    _Status.packing,
    _Status.outForDelivery,
    _Status.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _StepRow(
            status: _steps[i],
            done: current.step >= _steps[i].step,
            active: current.step == _steps[i].step,
          ),
          if (i < _steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 2,
                height: 24,
                color: current.step > _steps[i].step ? AppColors.pink : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.status, required this.done, required this.active});
  final _Status status;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.pink : AppColors.glass,
            border: Border.all(
                color: done ? AppColors.pink : AppColors.border,
                width: done ? 0 : 1.5),
          ),
          child: Center(
            child: Icon(
              status.icon,
              size: 14,
              color: done ? Colors.white : AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Text(
          status.label,
          style: AppText.body(
            size: 14,
            weight: active ? FontWeight.w600 : FontWeight.w400,
            color: done || active ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
        if (active && status != _Status.delivered) ...[
          const SizedBox(width: 8),
          _PulsingDot(),
        ],
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.pink,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.pink.withOpacity(0.6 * _ctrl.value), blurRadius: 6)],
        ),
      ),
    );
  }
}

// ── Courier bar ────────────────────────────────────────────────────────────────

class _CourierBar extends StatelessWidget {
  const _CourierBar({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
          tween: Tween(begin: 0.0, end: status.courierProgress),
          builder: (_, progress, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live tracking',
                    style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.4)),
                const SizedBox(height: Insets.sm),
                SizedBox(
                  height: 34,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Track
                      Container(height: 4, decoration: BoxDecoration(
                        color: AppColors.glass, borderRadius: BorderRadius.circular(2))),
                      // Filled
                      Container(
                        height: 4,
                        width: w * progress,
                        decoration: BoxDecoration(
                          color: AppColors.pink, borderRadius: BorderRadius.circular(2)),
                      ),
                      // Courier dot
                      Positioned(
                        left: (w - 26) * progress,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.pink,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.pink.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1),
                            ],
                          ),
                          child: const Center(child: Text('🛵', style: TextStyle(fontSize: 12))),
                        ),
                      ),
                      // Store
                      Positioned(
                        left: 0,
                        child: _Endpoint('🏪'),
                      ),
                      // Home
                      Positioned(
                        right: 0,
                        child: _Endpoint('🏠'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dark store',
                        style: AppText.mono(size: 10, color: AppColors.textTertiary, spacing: 0)),
                    Text('Your door',
                        style: AppText.mono(size: 10, color: AppColors.textTertiary, spacing: 0)),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint(this.emoji);
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.glassHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 10))),
    );
  }
}
