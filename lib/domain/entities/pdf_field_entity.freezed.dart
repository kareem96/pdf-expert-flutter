// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_field_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PdfFieldEntity {
  String get id => throw _privateConstructorUsedError; // ID Unik (internal app)
  String get name => throw _privateConstructorUsedError; // Nama asli (dari PDF)
  PdfFieldType get type => throw _privateConstructorUsedError;
  String? get value => throw _privateConstructorUsedError;
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  double get width => throw _privateConstructorUsedError;
  double get height => throw _privateConstructorUsedError;
  int get pageIndex => throw _privateConstructorUsedError;
  double get fontSize => throw _privateConstructorUsedError;
  String get textColor =>
      throw _privateConstructorUsedError; // Warna teks (default: hitam)
  String? get backgroundColor => throw _privateConstructorUsedError;
  String get fontFamily => throw _privateConstructorUsedError;
  bool get isBold => throw _privateConstructorUsedError;
  bool get isItalic => throw _privateConstructorUsedError;
  bool get isModified => throw _privateConstructorUsedError;
  bool get isNewField =>
      throw _privateConstructorUsedError; // True if added via "Free Text Insertion"
  int? get originalIndex => throw _privateConstructorUsedError;

  /// Create a copy of PdfFieldEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PdfFieldEntityCopyWith<PdfFieldEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PdfFieldEntityCopyWith<$Res> {
  factory $PdfFieldEntityCopyWith(
    PdfFieldEntity value,
    $Res Function(PdfFieldEntity) then,
  ) = _$PdfFieldEntityCopyWithImpl<$Res, PdfFieldEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    PdfFieldType type,
    String? value,
    double x,
    double y,
    double width,
    double height,
    int pageIndex,
    double fontSize,
    String textColor,
    String? backgroundColor,
    String fontFamily,
    bool isBold,
    bool isItalic,
    bool isModified,
    bool isNewField,
    int? originalIndex,
  });
}

/// @nodoc
class _$PdfFieldEntityCopyWithImpl<$Res, $Val extends PdfFieldEntity>
    implements $PdfFieldEntityCopyWith<$Res> {
  _$PdfFieldEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PdfFieldEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? value = freezed,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? pageIndex = null,
    Object? fontSize = null,
    Object? textColor = null,
    Object? backgroundColor = freezed,
    Object? fontFamily = null,
    Object? isBold = null,
    Object? isItalic = null,
    Object? isModified = null,
    Object? isNewField = null,
    Object? originalIndex = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as PdfFieldType,
            value: freezed == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String?,
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
            width: null == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as double,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as double,
            pageIndex: null == pageIndex
                ? _value.pageIndex
                : pageIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            fontSize: null == fontSize
                ? _value.fontSize
                : fontSize // ignore: cast_nullable_to_non_nullable
                      as double,
            textColor: null == textColor
                ? _value.textColor
                : textColor // ignore: cast_nullable_to_non_nullable
                      as String,
            backgroundColor: freezed == backgroundColor
                ? _value.backgroundColor
                : backgroundColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            fontFamily: null == fontFamily
                ? _value.fontFamily
                : fontFamily // ignore: cast_nullable_to_non_nullable
                      as String,
            isBold: null == isBold
                ? _value.isBold
                : isBold // ignore: cast_nullable_to_non_nullable
                      as bool,
            isItalic: null == isItalic
                ? _value.isItalic
                : isItalic // ignore: cast_nullable_to_non_nullable
                      as bool,
            isModified: null == isModified
                ? _value.isModified
                : isModified // ignore: cast_nullable_to_non_nullable
                      as bool,
            isNewField: null == isNewField
                ? _value.isNewField
                : isNewField // ignore: cast_nullable_to_non_nullable
                      as bool,
            originalIndex: freezed == originalIndex
                ? _value.originalIndex
                : originalIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PdfFieldEntityImplCopyWith<$Res>
    implements $PdfFieldEntityCopyWith<$Res> {
  factory _$$PdfFieldEntityImplCopyWith(
    _$PdfFieldEntityImpl value,
    $Res Function(_$PdfFieldEntityImpl) then,
  ) = __$$PdfFieldEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    PdfFieldType type,
    String? value,
    double x,
    double y,
    double width,
    double height,
    int pageIndex,
    double fontSize,
    String textColor,
    String? backgroundColor,
    String fontFamily,
    bool isBold,
    bool isItalic,
    bool isModified,
    bool isNewField,
    int? originalIndex,
  });
}

/// @nodoc
class __$$PdfFieldEntityImplCopyWithImpl<$Res>
    extends _$PdfFieldEntityCopyWithImpl<$Res, _$PdfFieldEntityImpl>
    implements _$$PdfFieldEntityImplCopyWith<$Res> {
  __$$PdfFieldEntityImplCopyWithImpl(
    _$PdfFieldEntityImpl _value,
    $Res Function(_$PdfFieldEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfFieldEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? value = freezed,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? pageIndex = null,
    Object? fontSize = null,
    Object? textColor = null,
    Object? backgroundColor = freezed,
    Object? fontFamily = null,
    Object? isBold = null,
    Object? isItalic = null,
    Object? isModified = null,
    Object? isNewField = null,
    Object? originalIndex = freezed,
  }) {
    return _then(
      _$PdfFieldEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as PdfFieldType,
        value: freezed == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String?,
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
        width: null == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as double,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as double,
        pageIndex: null == pageIndex
            ? _value.pageIndex
            : pageIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        fontSize: null == fontSize
            ? _value.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        textColor: null == textColor
            ? _value.textColor
            : textColor // ignore: cast_nullable_to_non_nullable
                  as String,
        backgroundColor: freezed == backgroundColor
            ? _value.backgroundColor
            : backgroundColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        fontFamily: null == fontFamily
            ? _value.fontFamily
            : fontFamily // ignore: cast_nullable_to_non_nullable
                  as String,
        isBold: null == isBold
            ? _value.isBold
            : isBold // ignore: cast_nullable_to_non_nullable
                  as bool,
        isItalic: null == isItalic
            ? _value.isItalic
            : isItalic // ignore: cast_nullable_to_non_nullable
                  as bool,
        isModified: null == isModified
            ? _value.isModified
            : isModified // ignore: cast_nullable_to_non_nullable
                  as bool,
        isNewField: null == isNewField
            ? _value.isNewField
            : isNewField // ignore: cast_nullable_to_non_nullable
                  as bool,
        originalIndex: freezed == originalIndex
            ? _value.originalIndex
            : originalIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$PdfFieldEntityImpl implements _PdfFieldEntity {
  const _$PdfFieldEntityImpl({
    required this.id,
    required this.name,
    required this.type,
    this.value,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.pageIndex = 0,
    this.fontSize = 12,
    this.textColor = '0xFF000000',
    this.backgroundColor,
    this.fontFamily = 'Helvetica',
    this.isBold = false,
    this.isItalic = false,
    this.isModified = false,
    this.isNewField = false,
    this.originalIndex,
  });

  @override
  final String id;
  // ID Unik (internal app)
  @override
  final String name;
  // Nama asli (dari PDF)
  @override
  final PdfFieldType type;
  @override
  final String? value;
  @override
  final double x;
  @override
  final double y;
  @override
  final double width;
  @override
  final double height;
  @override
  @JsonKey()
  final int pageIndex;
  @override
  @JsonKey()
  final double fontSize;
  @override
  @JsonKey()
  final String textColor;
  // Warna teks (default: hitam)
  @override
  final String? backgroundColor;
  @override
  @JsonKey()
  final String fontFamily;
  @override
  @JsonKey()
  final bool isBold;
  @override
  @JsonKey()
  final bool isItalic;
  @override
  @JsonKey()
  final bool isModified;
  @override
  @JsonKey()
  final bool isNewField;
  // True if added via "Free Text Insertion"
  @override
  final int? originalIndex;

  @override
  String toString() {
    return 'PdfFieldEntity(id: $id, name: $name, type: $type, value: $value, x: $x, y: $y, width: $width, height: $height, pageIndex: $pageIndex, fontSize: $fontSize, textColor: $textColor, backgroundColor: $backgroundColor, fontFamily: $fontFamily, isBold: $isBold, isItalic: $isItalic, isModified: $isModified, isNewField: $isNewField, originalIndex: $originalIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PdfFieldEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.pageIndex, pageIndex) ||
                other.pageIndex == pageIndex) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.textColor, textColor) ||
                other.textColor == textColor) &&
            (identical(other.backgroundColor, backgroundColor) ||
                other.backgroundColor == backgroundColor) &&
            (identical(other.fontFamily, fontFamily) ||
                other.fontFamily == fontFamily) &&
            (identical(other.isBold, isBold) || other.isBold == isBold) &&
            (identical(other.isItalic, isItalic) ||
                other.isItalic == isItalic) &&
            (identical(other.isModified, isModified) ||
                other.isModified == isModified) &&
            (identical(other.isNewField, isNewField) ||
                other.isNewField == isNewField) &&
            (identical(other.originalIndex, originalIndex) ||
                other.originalIndex == originalIndex));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    type,
    value,
    x,
    y,
    width,
    height,
    pageIndex,
    fontSize,
    textColor,
    backgroundColor,
    fontFamily,
    isBold,
    isItalic,
    isModified,
    isNewField,
    originalIndex,
  );

  /// Create a copy of PdfFieldEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PdfFieldEntityImplCopyWith<_$PdfFieldEntityImpl> get copyWith =>
      __$$PdfFieldEntityImplCopyWithImpl<_$PdfFieldEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _PdfFieldEntity implements PdfFieldEntity {
  const factory _PdfFieldEntity({
    required final String id,
    required final String name,
    required final PdfFieldType type,
    final String? value,
    required final double x,
    required final double y,
    required final double width,
    required final double height,
    final int pageIndex,
    final double fontSize,
    final String textColor,
    final String? backgroundColor,
    final String fontFamily,
    final bool isBold,
    final bool isItalic,
    final bool isModified,
    final bool isNewField,
    final int? originalIndex,
  }) = _$PdfFieldEntityImpl;

  @override
  String get id; // ID Unik (internal app)
  @override
  String get name; // Nama asli (dari PDF)
  @override
  PdfFieldType get type;
  @override
  String? get value;
  @override
  double get x;
  @override
  double get y;
  @override
  double get width;
  @override
  double get height;
  @override
  int get pageIndex;
  @override
  double get fontSize;
  @override
  String get textColor; // Warna teks (default: hitam)
  @override
  String? get backgroundColor;
  @override
  String get fontFamily;
  @override
  bool get isBold;
  @override
  bool get isItalic;
  @override
  bool get isModified;
  @override
  bool get isNewField; // True if added via "Free Text Insertion"
  @override
  int? get originalIndex;

  /// Create a copy of PdfFieldEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PdfFieldEntityImplCopyWith<_$PdfFieldEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
