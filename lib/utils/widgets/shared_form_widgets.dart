import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/theme.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final int maxLines;
  final TextInputType keyboardType;
  final String? hintText;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? labelWidget;
  final EdgeInsetsGeometry? contentPadding;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFormField({
    super.key,
    this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.labelWidget,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    this.inputFormatters,
  });
  @override
  Widget build(BuildContext context) {
    final baseDecoration = const InputDecoration().applyDefaults(
      Theme.of(context).inputDecorationTheme,
    );
    final decoration = baseDecoration.copyWith(
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            inputFormatters: inputFormatters,
            style: const TextStyle(color: kTextColor, fontSize: 14),
            decoration: decoration,
          ),
        ),
      ],
    );
  }
}

/// Un botón circular con icono, ideal para acciones de incremento/decremento o controles.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? kAppBarColor,
          border: Border.all(
            color: borderColor ?? kTextColor.withAlpha((255 * 0.1).round()),
          ),
        ),
        child: Icon(icon, color: iconColor ?? kTextColor, size: iconSize),
      ),
    );
  }
}

class CompactTextField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool isNumeric;
  final String? hintText;
  final IconData? icon;
  final int minLines;
  const CompactTextField({
    super.key,
    required this.title,
    required this.controller,
    this.isNumeric = false,
    this.hintText,
    this.icon,
    this.minLines = 1,
  });
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      label: title,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      hintText: hintText,
      maxLines: minLines,
    );
  }
}

class CustomDropdownButton<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T) itemLabelBuilder;
  final IconData? icon;
  final BoxConstraints? iconConstraints;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  const CustomDropdownButton({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.icon,
    this.prefixIcon,
    this.iconConstraints,
    this.suffixIcon,
    this.suffixIconConstraints,
  });
  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: DropdownButtonFormField<T>(
            initialValue: items.contains(value) ? value : null,
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabelBuilder(item),
                      style: const TextStyle(color: kTextColorSecondary),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            dropdownColor: kBackgroundColor,
            decoration: const InputDecoration()
                .applyDefaults(Theme.of(context).inputDecorationTheme)
                .copyWith(
                  labelText: label,
                  prefixIcon: icon != null
                      ? Icon(icon, color: kTextColorSecondary)
                      : null,
                  suffixIcon: suffixIcon,
                  prefixIconConstraints: iconConstraints,
                  suffixIconConstraints: suffixIconConstraints,
                ),
          ),
        ),
      ],
    );
  }
}

class PulseIcon extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;

  const PulseIcon({
    super.key,
    required this.child,
    required this.enabled,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scale = Tween<double>(
      begin: 0.92,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.enabled ? _scale : const AlwaysStoppedAnimation(1.0),
      child: widget.child,
    );
  }
}

class CompactDropdown<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final IconData? icon;
  final BoxConstraints? iconConstraints;
  final Widget? prefixIcon;
  final String Function(T)? itemLabelBuilder;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  const CompactDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.iconConstraints,
    this.prefixIcon,
    this.itemLabelBuilder,
    this.suffixIcon,
    this.suffixIconConstraints,
  });
  @override
  Widget build(BuildContext context) {
    return CustomDropdownButton<T>(
      label: title,
      value: value,
      items: items,
      onChanged: onChanged,
      itemLabelBuilder: itemLabelBuilder ?? (item) => item.toString(),
      icon: icon,
      iconConstraints: iconConstraints,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
    );
  }
}

class DateInputField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const DateInputField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      label: label,
      controller: TextEditingController(
        text: date != null ? DateFormat('dd/MM/yyyy').format(date!) : '',
      ),
      readOnly: true,
      onTap: onTap,
      hintText: 'Seleccionar fecha',
    );
  }
}

class CompactDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final IconData? icon;
  const CompactDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return DateInputField(label: label, date: date, onTap: onTap);
  }
}

class MultiChipSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onUpdate;
  const MultiChipSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onUpdate,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: kTextColorSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<String>.from(selectedOptions);
                if (selected) {
                  newList.add(option);
                } else {
                  newList.remove(option);
                }
                onUpdate(newList);
              },
              backgroundColor: kInputFillColor,
              selectedColor: kPrimaryColor.withAlpha(100),
              checkmarkColor: kTextColor,
              labelStyle: TextStyle(
                color: isSelected ? kTextColor : kTextColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class NutrientRow extends StatelessWidget {
  final String name;
  final String amount;
  final String unit;

  const NutrientRow({
    super.key,
    required this.name,
    required this.amount,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: kTextColorSecondary)),
          Text(
            '$amount $unit',
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SingleChipSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Function(String?) onUpdate;

  const SingleChipSection({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: kTextColorSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option),
              selected: selectedOption == option,
              onSelected: (selected) {
                if (selected) {
                  onUpdate(option);
                }
              },
              backgroundColor: kInputFillColor,
              selectedColor: kPrimaryColor.withAlpha(100),
              checkmarkColor: kTextColor,
              labelStyle: TextStyle(
                color: selectedOption == option ? kTextColor : kTextColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SharedSubCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? header;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const SharedSubCard({
    super.key,
    required this.title,
    required this.child,
    this.header,
    this.radius = 18,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: kPrimaryColor,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: kPrimaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        );

    return Card(
      color: backgroundColor ?? kAppBarColor.withAlpha(120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            if (header != null) ...[const SizedBox(height: 8), header!],
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GLASS-STYLE COMPACT WIDGETS (48px height, consistent styling)
// ============================================================================

/// TextField compacto con estilo glass (48px altura fija)
/// Usado en historia clínica para formularios compactos
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.readOnly = false,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );
    final baseDecoration = const InputDecoration().applyDefaults(
      Theme.of(context).inputDecorationTheme,
    );
    final decoration = baseDecoration.copyWith(
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onTap: onTap,
            inputFormatters: inputFormatters,
            style: const TextStyle(color: Colors.white),
            decoration: decoration,
          ),
        ),
      ],
    );
  }
}

/// TextField numérico con estilo glass (48px altura fija)
/// Usado en evaluación de entrenamiento para campos numéricos
class GlassNumericField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const GlassNumericField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
    );
  }
}

/// Dropdown genérico con estilo glass (48px altura fija)
/// Usado en historia clínica para selecciones
class GlassDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? itemLabelBuilder;

  const GlassDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is either null or in items list
    final validValue = items.contains(value) ? value : null;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );
    final baseDecoration = const InputDecoration().applyDefaults(
      Theme.of(context).inputDecorationTheme,
    );
    final decoration = baseDecoration.copyWith();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: DropdownButtonFormField<T>(
            initialValue: validValue,
            isExpanded: true,
            dropdownColor: kBackgroundColor,
            hint: const Text(
              'Seleccionar',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
            style: const TextStyle(color: Colors.white),
            items: items.isEmpty
                ? null
                : items.map((item) {
                    return DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabelBuilder != null
                            ? itemLabelBuilder!(item)
                            : item.toString(),
                      ),
                    );
                  }).toList(),
            onChanged: onChanged,
            decoration: decoration,
          ),
        ),
      ],
    );
  }
}
