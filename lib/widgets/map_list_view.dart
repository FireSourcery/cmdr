import 'package:cmdr/byte_struct.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../binary_data/word_fields.dart';
import '../binary_data/word.dart';

/// Read Only views
/// possibly change to String,V
class MapRowTiles<K, V> extends StatelessWidget {
  const MapRowTiles({required this.fields, this.title, super.key});
  final Iterable<(K key, V value)> fields;
  final String? title;
  // Widget Function(K)? keyBuilder;
  // Widget Function(V)? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      // contentPadding: EdgeInsets.zero,
      // title: (label != null) ? Text(label!) : null,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (key, value) in fields)
              IntrinsicWidth(
                child: ListTile(
                  // titleAlignment: ListTileTitleAlignment.bottom,
                  subtitle: Text(key.toString()),
                  title: Text(value.toString()),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// class MapListView extends StatelessWidget {
//   const MapListView({required this.namedFields, this.label = 'Map', super.key});
//   final List<Map> namedFields;
//   final String? label;

//   @override
//   Widget build(BuildContext context) {
//     return InputDecorator(
//       decoration: InputDecoration(labelText: label),
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [for (final namedFields in namedFields) MapTile(namedFields: namedFields)],
//       ),
//     );
//   }
// }

/// A FormField partitioned corresponding to th map input. Each Map entry is an separate entity
/// Editable views
/// Value should be String or num
class MapFormFields<K, V> extends StatefulWidget {
  const MapFormFields({super.key, required this.entries, this.isReadOnly = false, this.onSaved, required this.valueParser, this.inputFormatters, this.keyStringifier});

  // todo at min max
  MapFormFields.digits({super.key, required this.entries, this.isReadOnly = false, this.onSaved, this.keyStringifier})
      : valueParser = switch (V) {
          const (int) => int.tryParse,
          const (double) => double.tryParse,
          const (num) => num.tryParse,
          _ => throw UnsupportedError('$V must be num type'),
        } as V? Function(String),
        inputFormatters = [FilteringTextInputFormatter.digitsOnly];

  final Iterable<(K key, V value)> entries; // todo as EnumMap
  final bool isReadOnly;
  final ValueSetter<Map<K, V>>? onSaved;

  final String Function(K key)? keyStringifier;
  final V? Function(String textValue) valueParser;

  final List<TextInputFormatter>? inputFormatters;
  // final (num min, num max)? numLimits;

  @override
  State<MapFormFields<K, V>> createState() => _MapFormFieldsState<K, V>();
}

class _MapFormFieldsState<K, V> extends State<MapFormFields<K, V>> {
  late final Map<K, V> cache;
  late final Map<K, TextEditingController> _textEditingControllers;
  late final Map<K, FocusNode> _focusNodes;

  // static Map<K, TextEditingController> _newTextEditingControllers<K, V>(Iterable<(K key, V value)> entries) {
  //   return {for (final (key, value) in entries) key: TextEditingController(text: value.toString())};
  // }

  String labelOf(K key) => widget.keyStringifier?.call(key) ?? key.toString();

  void updateValue(K key, String value) {
    if (value.isNotEmpty) {
      if (widget.valueParser(value) case V parsedValue) {
        cache[key] = parsedValue;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    cache = {for (final (key, value) in widget.entries) key: value};
    _textEditingControllers = {for (final (key, value) in widget.entries) key: TextEditingController(text: value.toString())};
    _focusNodes = {
      for (final (key, _) in widget.entries)
        key: FocusNode()
          ..addListener(() {
            if (!_focusNodes[key]!.hasFocus) {
              print('TextField lost focus $key');
              updateValue(key, _textEditingControllers[key]!.text);
            }
          })
    };
  }

  @override
  void dispose() {
    for (final controller in _textEditingControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Map<K, V>>(
      initialValue: cache,
      onSaved: (Map<K, V>? newValue) => widget.onSaved?.call(newValue!),
      validator: (Map<K, V>? value) {
        if (value == null || value.isEmpty) return 'Empty value';
        return null;
      },
      builder: (FormFieldState<Map<K, V>> field) {
        return Row(
          children: [
            for (final (index, (key, value)) in widget.entries.indexed) ...[
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: labelOf(key), isDense: true, counterText: '' /* , errorText: field.errorText */),

                  controller: _textEditingControllers[key]!,
                  onEditingComplete: () => updateValue(key, _textEditingControllers[key]!.text),
                  focusNode: _focusNodes[key]!,
                  onSubmitted: (String value) => updateValue(key, value),
                  // onChanged: (value) {
                  //   if (value.isNotEmpty) {
                  //     if (valueParser(value) case V value) field.value?[key] = value;
                  //   }
                  // },
                  // field.didChange(field.value), sets map object
                  // onTapOutside: (event) => print('onTapOutside'), //field.didChange(field.value),

                  inputFormatters: widget.inputFormatters,
                  readOnly: widget.isReadOnly,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLines: 1,
                ),
              ),
              if (index != field.value!.length - 1) const VerticalDivider(),
            ],
          ],
        );
      },
    );
  }
}
