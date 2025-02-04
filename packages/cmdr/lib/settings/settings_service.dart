import 'setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

//SharedPreference Service
class SettingsService {
  SettingsService._();
  static final SettingsService main = SettingsService._();
  factory SettingsService() => main;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance(); // loads the SharedPreferences cache
  late final SharedPreferences prefs;

  Future<void> init(/* {String? prefix} */) async => (prefs = await _prefs);

  R? _get<R>(String key) => prefs.get(key) as R?;

  Enum? _getEnum(String key, List<Enum> values) {
    final index = _get<int>(key);
    return (index != null) ? values.elementAtOrNull(index) : null;
  }

  R? get<R>(String key, [dynamic bounds]) {
    return switch (R) {
      const (int) || const (double) || const (bool) => _get<R>(key),
      const (String) || const (List<String>) => _get<R>(key),
      const (Enum) => _getEnum(key, bounds) as R?,
      _ => throw UnsupportedError('$R'),
    };
  }

  // loaded on init
  R? load<R>(String key, [dynamic bounds]) => get<R>(key, bounds);
  // R? load<R>(String key, [dynamic bounds]) {
  //  prefs = await _prefs
  //   return switch (R) {
  //     const (bool) => prefs.getBool(key),
  //     const (int) => prefs.getInt(key),
  //     const (double) => prefs.getDouble(key),
  //     const (String) => prefs.getString(key),
  //     const (List<String>) => prefs.getStringList(key),
  //     _ => throw UnsupportedError('$R'),
  //   } as R?;
  // }

  Future<bool> _setAsync<T>(String key, T value) {
    return switch (T) {
      const (int) => prefs.setInt(key, value as int),
      const (double) => prefs.setDouble(key, value as double),
      const (bool) => prefs.setBool(key, value as bool),
      const (String) => prefs.setString(key, value as String),
      const (List<String>) => prefs.setStringList(key, value as List<String>),
      const (Enum) => prefs.setInt(key, (value as Enum).index),
      _ => throw UnsupportedError('$T'),
    };
  }

  // Future<bool> _setEnumAsync(String key, Enum value) => _setAsync<int>(key, value.index);

  // calling without await will set that cached value
  // do not await propagate to disk, process up to _preferenceCache[key] = value;
  void set<T>(String key, T value) => _setAsync<T>(key, value);

  Future<bool> update<T>(String key, T value) async => _setAsync<T>(key, value);
}

// abstract interface class Setting<T>  = ServiceKey<T> UnionValueKey<V>

// SettingBase using SharedPreferences
abstract mixin class SharedPrefSetting<T> implements Setting<T> {
  String get key;

  @override
  List<T>? get valueRange; // Enum or options set
  @override
  ({num min, num max})? get numLimits;
  // T get defaultValue;

  // String get key => name; // if implements enum
  @override
  String get label;
  @override
  String get valueString;

  @override
  Type get type => T;
  @override
  R callWithType<R>(R Function<G>() callback) => callback<T>();

  @override
  T? get value {
    return switch (T) {
      const (bool) || const (int) || const (double) || const (String) || const (List<String>) => SettingsService.main.get<T>(key),
      const (Enum) => SettingsService.main.get<T>(key, valueRange!),
      _ => throw UnsupportedError('$T'),
    };
  }

  // not needed if all settings are loaded at once in the case of sharedPreferences, may keep interface for network settings
  @override
  Future<T?> load() async => value;

  T _boundValue(T newValue) {
    // if (numLimits == null) return newValue;
    // assert(T == int || T == double, 'Only num types are supported');
    // return (newValue as num).clamp(numLimits!.min, numLimits!.max) as T;
    // // final clamped = (newValue as num).clamp(numLimits!.min, numLimits!.max);
    // // return switch (T) { const (int) => clamped.toInt(), const (double) => clamped.toDouble(), _ => newValue } as T;

    return switch (T) {
      const (int) || const (double) => ((numLimits != null) ? (newValue as num).clamp(numLimits!.min, numLimits!.max) : newValue) as T,
      const (bool) || const (String) || const (List<String>) => newValue,
      const (Enum) => newValue,
      _ => throw UnsupportedError('$T'),
    };
  }

  @override
  set value(T? newValue) {
    if (newValue != null) SettingsService.main.set<T>(key, _boundValue(newValue));
  }

  @override
  Future<bool> update(T value) async {
    return SettingsService.main.update<T>(key, _boundValue(value));
  }
}
