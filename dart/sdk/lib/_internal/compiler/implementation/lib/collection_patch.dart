// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:collection classes.
import 'dart:_foreign_helper' show JS;

patch class HashMap<K, V> {
  int _length = 0;

  // The hash map contents is divided into three parts: one part for
  // string keys, one for numeric keys, and one for the rest. String
  // and numeric keys map directly to their values, but the rest of
  // the entries are stored in bucket lists of the form:
  //
  //    [key-0, value-0, key-1, value-1, ...]
  //
  // where all keys in the same bucket share the same hash code.
  var _strings;
  var _nums;
  var _rest;

  // When iterating over the hash map, it is very convenient to have a
  // list of all the keys. We cache that on the instance and clear the
  // the cache whenever the key set changes. This is also used to
  // guard against concurrent modifications.
  List _keys;

  patch HashMap();

  patch int get length => _length;
  patch bool get isEmpty => _length == 0;

  patch Iterable<K> get keys {
    return new HashMapKeyIterable<K>(this);
  }

  patch Iterable<V> get values {
    return keys.map((each) => this[each]);
  }

  patch bool containsKey(K key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      return (strings == null) ? false : _hasTableEntry(strings, key);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      return (nums == null) ? false : _hasTableEntry(nums, key);
    } else {
      var rest = _rest;
      if (rest == null) return false;
      var bucket = _getBucket(rest, key);
      return _findBucketIndex(bucket, key) >= 0;
    }
  }

  patch bool containsValue(V value) {
    return _computeKeys().any((each) => this[each] == value);
  }

  patch void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  patch V operator[](K key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      return (strings == null) ? null : _getTableEntry(strings, key);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      return (nums == null) ? null : _getTableEntry(nums, key);
    } else {
      var rest = _rest;
      if (rest == null) return null;
      var bucket = _getBucket(rest, key);
      int index = _findBucketIndex(bucket, key);
      return (index < 0) ? null : JS('var', '#[#]', bucket, index + 1);
    }
  }

  patch void operator[]=(K key, V value) {
    if (_isStringKey(key)) {
      var strings = _strings;
      if (strings == null) _strings = strings = _newHashTable();
      _addHashTableEntry(strings, key, value);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      if (nums == null) _nums = nums = _newHashTable();
      _addHashTableEntry(nums, key, value);
    } else {
      var rest = _rest;
      if (rest == null) _rest = rest = _newHashTable();
      var hash = _computeHashCode(key);
      var bucket = JS('var', '#[#]', rest, hash);
      if (bucket == null) {
        _setTableEntry(rest, hash, JS('var', '[#, #]', key, value));
        _length++;
        _keys = null;
      } else {
        int index = _findBucketIndex(bucket, key);
        if (index >= 0) {
          JS('void', '#[#] = #', bucket, index + 1, value);
        } else {
          JS('void', '#.push(#, #)', bucket, key, value);
          _length++;
          _keys = null;
        }
      }
    }
  }

  patch V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) return this[key];
    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  patch V remove(K key) {
    if (_isStringKey(key)) {
      return _removeHashTableEntry(_strings, key);
    } else if (_isNumericKey(key)) {
      return _removeHashTableEntry(_nums, key);
    } else {
      var rest = _rest;
      if (rest == null) return null;
      var bucket = _getBucket(rest, key);
      int index = _findBucketIndex(bucket, key);
      if (index < 0) return null;
      // TODO(kasperl): Consider getting rid of the bucket list when
      // the length reaches zero.
      _length--;
      _keys = null;
      // Use splice to remove the two [key, value] elements at the
      // index and return the value.
      return JS('var', '#.splice(#, 2)[1]', bucket, index);
    }
  }

  patch void clear() {
    if (_length > 0) {
      _strings = _nums = _rest = _keys = null;
      _length = 0;
    }
  }

  patch void forEach(void action(K key, V value)) {
    List keys = _computeKeys();
    for (int i = 0, length = keys.length; i < length; i++) {
      var key = JS('var', '#[#]', keys, i);
      action(key, this[key]);
      if (JS('bool', '# !== #', keys, _keys)) {
        throw new ConcurrentModificationError(this);
      }
    }
  }

  List _computeKeys() {
    if (_keys != null) return _keys;
    List result = new List(_length);
    int index = 0;

    // Add all string keys to the list.
    var strings = _strings;
    if (strings != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', strings);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        String key = JS('String', '#[#]', names, i);
        JS('void', '#[#] = #', result, index, key);
        index++;
      }
    }

    // Add all numeric keys to the list.
    var nums = _nums;
    if (nums != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', nums);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        // Object.getOwnPropertyNames returns a list of strings, so we
        // have to convert the keys back to numbers (+).
        num key = JS('num', '+#[#]', names, i);
        JS('void', '#[#] = #', result, index, key);
        index++;
      }
    }

    // Add all the remaining keys to the list.
    var rest = _rest;
    if (rest != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', rest);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        var key = JS('String', '#[#]', names, i);
        var bucket = JS('var', '#[#]', rest, key);
        int length = JS('int', '#.length', bucket);
        for (int i = 0; i < length; i += 2) {
          var key = JS('var', '#[#]', bucket, i);
          JS('void', '#[#] = #', result, index, key);
          index++;
        }
      }
    }
    assert(index == _length);
    return _keys = result;
  }

  _newHashTable() {
    // Create a new JavaScript object to be used as a hash table. Use
    // Object.create to avoid the properties on Object.prototype
    // showing up as entries.
    var table = JS('var', 'Object.create(null)');
    // Attempt to force the hash table into 'dictionary' mode by
    // adding a property to it and deleting it again.
    var temporaryKey = '<non-identifier-key>';
    _setTableEntry(table, temporaryKey, table);
    _deleteTableEntry(table, temporaryKey);
    return table;
  }

  void _addHashTableEntry(var table, K key, V value) {
    if (!_hasTableEntry(table, key)) {
      _length++;
      _keys = null;
    }
    _setTableEntry(table, key, value);
  }

  V _removeHashTableEntry(var table, K key) {
    if (table != null && _hasTableEntry(table, key)) {
      V value = _getTableEntry(table, key);
      _deleteTableEntry(table, key);
      _length--;
      _keys = null;
      return value;
    } else {
      return null;
    }
  }

  static bool _isStringKey(var key) {
    return key is String && key != '__proto__';
  }

  static bool _isNumericKey(var key) {
    // Only treat unsigned 30-bit integers as numeric keys. This way,
    // we avoid converting them to strings when we use them as keys in
    // the JavaScript hash table object.
    return key is num && JS('bool', '(# & 0x3ffffff) === #', key, key);
  }

  static int _computeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the key isn't a number.
    return JS('int', '# & 0x3ffffff', key.hashCode);
  }

  static bool _hasTableEntry(var table, var key) {
    var entry = JS('var', '#[#]', table, key);
    // We take care to only store non-null entries in the table, so we
    // can check if the table has an entry for the given key with a
    // simple null check.
    return entry != null;
  }

  static _getTableEntry(var table, var key) {
    var entry = JS('var', '#[#]', table, key);
    // We store the table itself as the entry to signal that it really
    // is a null value, so we have to map back to null here.
    return JS('bool', '# === #', entry, table) ? null : entry;
  }

  static void _setTableEntry(var table, var key, var value) {
    // We only store non-null entries in the table, so we have to
    // change null values to refer to the table itself. Such values
    // will be recognized and mapped back to null on access.
    if (value == null) value = table;
    JS('void', '#[#] = #', table, key, value);
  }

  static void _deleteTableEntry(var table, var key) {
    JS('void', 'delete #[#]', table, key);
  }

  static _getBucket(var table, var key) {
    var hash = _computeHashCode(key);
    return JS('var', '#[#]', table, hash);
  }

  static int _findBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i += 2) {
      if (JS('var', '#[#]', bucket, i) == key) return i;
    }
    return -1;
  }
}

class HashMapKeyIterable<E> extends Iterable<E> {
  final _map;
  HashMapKeyIterable(this._map);

  int get length => _map._length;
  bool get isEmpty => _map._length == 0;

  Iterator<E> get iterator {
    return new HashMapKeyIterator<E>(_map, _map._computeKeys());
  }

  bool contains(E element) {
    return _map.containsKey(element);
  }

  void forEach(void f(E element)) {
    List keys = _map._computeKeys();
    for (int i = 0, length = JS('int', '#.length', keys); i < length; i++) {
      f(JS('var', '#[#]', keys, i));
      if (JS('bool', '# !== #', keys, _map._keys)) {
        throw new ConcurrentModificationError(_map);
      }
    }
  }
}

class HashMapKeyIterator<E> implements Iterator<E> {
  final _map;
  final List _keys;
  int _offset = 0;
  E _current;

  HashMapKeyIterator(this._map, this._keys);

  E get current => _current;

  bool moveNext() {
    var keys = _keys;
    int offset = _offset;
    if (JS('bool', '# !== #', keys, _map._keys)) {
      throw new ConcurrentModificationError(_map);
    } else if (offset >= JS('int', '#.length', keys)) {
      _current = null;
      return false;
    } else {
      _current = JS('var', '#[#]', keys, offset);
      // TODO(kasperl): For now, we have to tell the type inferrer to
      // treat the result of doing offset + 1 as an int. Otherwise, we
      // get unnecessary bailout code.
      _offset = JS('int', '#', offset + 1);
      return true;
    }
  }
}