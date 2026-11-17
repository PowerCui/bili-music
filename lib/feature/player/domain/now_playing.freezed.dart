// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'now_playing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NowPlaying {

 String get stableId; String get title; String get artist; String? get coverUrl; String? get lyrics; String? get translationLyrics; int get lyricOffsetMs; Duration? get duration; String? get sourceLabel;
/// Create a copy of NowPlaying
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NowPlayingCopyWith<NowPlaying> get copyWith => _$NowPlayingCopyWithImpl<NowPlaying>(this as NowPlaying, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NowPlaying&&(identical(other.stableId, stableId) || other.stableId == stableId)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics)&&(identical(other.translationLyrics, translationLyrics) || other.translationLyrics == translationLyrics)&&(identical(other.lyricOffsetMs, lyricOffsetMs) || other.lyricOffsetMs == lyricOffsetMs)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel));
}


@override
int get hashCode => Object.hash(runtimeType,stableId,title,artist,coverUrl,lyrics,translationLyrics,lyricOffsetMs,duration,sourceLabel);

@override
String toString() {
  return 'NowPlaying(stableId: $stableId, title: $title, artist: $artist, coverUrl: $coverUrl, lyrics: $lyrics, translationLyrics: $translationLyrics, lyricOffsetMs: $lyricOffsetMs, duration: $duration, sourceLabel: $sourceLabel)';
}


}

/// @nodoc
abstract mixin class $NowPlayingCopyWith<$Res>  {
  factory $NowPlayingCopyWith(NowPlaying value, $Res Function(NowPlaying) _then) = _$NowPlayingCopyWithImpl;
@useResult
$Res call({
 String stableId, String title, String artist, String? coverUrl, String? lyrics, String? translationLyrics, int lyricOffsetMs, Duration? duration, String? sourceLabel
});




}
/// @nodoc
class _$NowPlayingCopyWithImpl<$Res>
    implements $NowPlayingCopyWith<$Res> {
  _$NowPlayingCopyWithImpl(this._self, this._then);

  final NowPlaying _self;
  final $Res Function(NowPlaying) _then;

/// Create a copy of NowPlaying
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stableId = null,Object? title = null,Object? artist = null,Object? coverUrl = freezed,Object? lyrics = freezed,Object? translationLyrics = freezed,Object? lyricOffsetMs = null,Object? duration = freezed,Object? sourceLabel = freezed,}) {
  return _then(_self.copyWith(
stableId: null == stableId ? _self.stableId : stableId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,lyrics: freezed == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as String?,translationLyrics: freezed == translationLyrics ? _self.translationLyrics : translationLyrics // ignore: cast_nullable_to_non_nullable
as String?,lyricOffsetMs: null == lyricOffsetMs ? _self.lyricOffsetMs : lyricOffsetMs // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NowPlaying].
extension NowPlayingPatterns on NowPlaying {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NowPlaying value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NowPlaying() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NowPlaying value)  $default,){
final _that = this;
switch (_that) {
case _NowPlaying():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NowPlaying value)?  $default,){
final _that = this;
switch (_that) {
case _NowPlaying() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stableId,  String title,  String artist,  String? coverUrl,  String? lyrics,  String? translationLyrics,  int lyricOffsetMs,  Duration? duration,  String? sourceLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NowPlaying() when $default != null:
return $default(_that.stableId,_that.title,_that.artist,_that.coverUrl,_that.lyrics,_that.translationLyrics,_that.lyricOffsetMs,_that.duration,_that.sourceLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stableId,  String title,  String artist,  String? coverUrl,  String? lyrics,  String? translationLyrics,  int lyricOffsetMs,  Duration? duration,  String? sourceLabel)  $default,) {final _that = this;
switch (_that) {
case _NowPlaying():
return $default(_that.stableId,_that.title,_that.artist,_that.coverUrl,_that.lyrics,_that.translationLyrics,_that.lyricOffsetMs,_that.duration,_that.sourceLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stableId,  String title,  String artist,  String? coverUrl,  String? lyrics,  String? translationLyrics,  int lyricOffsetMs,  Duration? duration,  String? sourceLabel)?  $default,) {final _that = this;
switch (_that) {
case _NowPlaying() when $default != null:
return $default(_that.stableId,_that.title,_that.artist,_that.coverUrl,_that.lyrics,_that.translationLyrics,_that.lyricOffsetMs,_that.duration,_that.sourceLabel);case _:
  return null;

}
}

}

/// @nodoc


class _NowPlaying extends NowPlaying {
  const _NowPlaying({required this.stableId, required this.title, required this.artist, this.coverUrl, this.lyrics, this.translationLyrics, this.lyricOffsetMs = 0, this.duration, this.sourceLabel}): super._();
  

@override final  String stableId;
@override final  String title;
@override final  String artist;
@override final  String? coverUrl;
@override final  String? lyrics;
@override final  String? translationLyrics;
@override@JsonKey() final  int lyricOffsetMs;
@override final  Duration? duration;
@override final  String? sourceLabel;

/// Create a copy of NowPlaying
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NowPlayingCopyWith<_NowPlaying> get copyWith => __$NowPlayingCopyWithImpl<_NowPlaying>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NowPlaying&&(identical(other.stableId, stableId) || other.stableId == stableId)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics)&&(identical(other.translationLyrics, translationLyrics) || other.translationLyrics == translationLyrics)&&(identical(other.lyricOffsetMs, lyricOffsetMs) || other.lyricOffsetMs == lyricOffsetMs)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel));
}


@override
int get hashCode => Object.hash(runtimeType,stableId,title,artist,coverUrl,lyrics,translationLyrics,lyricOffsetMs,duration,sourceLabel);

@override
String toString() {
  return 'NowPlaying(stableId: $stableId, title: $title, artist: $artist, coverUrl: $coverUrl, lyrics: $lyrics, translationLyrics: $translationLyrics, lyricOffsetMs: $lyricOffsetMs, duration: $duration, sourceLabel: $sourceLabel)';
}


}

/// @nodoc
abstract mixin class _$NowPlayingCopyWith<$Res> implements $NowPlayingCopyWith<$Res> {
  factory _$NowPlayingCopyWith(_NowPlaying value, $Res Function(_NowPlaying) _then) = __$NowPlayingCopyWithImpl;
@override @useResult
$Res call({
 String stableId, String title, String artist, String? coverUrl, String? lyrics, String? translationLyrics, int lyricOffsetMs, Duration? duration, String? sourceLabel
});




}
/// @nodoc
class __$NowPlayingCopyWithImpl<$Res>
    implements _$NowPlayingCopyWith<$Res> {
  __$NowPlayingCopyWithImpl(this._self, this._then);

  final _NowPlaying _self;
  final $Res Function(_NowPlaying) _then;

/// Create a copy of NowPlaying
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stableId = null,Object? title = null,Object? artist = null,Object? coverUrl = freezed,Object? lyrics = freezed,Object? translationLyrics = freezed,Object? lyricOffsetMs = null,Object? duration = freezed,Object? sourceLabel = freezed,}) {
  return _then(_NowPlaying(
stableId: null == stableId ? _self.stableId : stableId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,lyrics: freezed == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as String?,translationLyrics: freezed == translationLyrics ? _self.translationLyrics : translationLyrics // ignore: cast_nullable_to_non_nullable
as String?,lyricOffsetMs: null == lyricOffsetMs ? _self.lyricOffsetMs : lyricOffsetMs // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$NowPlayingPlayback {

 Duration get position; Duration? get duration; bool get isPlaying; bool get isReady; bool get isBuffering; bool get isLoading; double get speed; bool get hasPrevious; bool get hasNext; bool get hasItem;
/// Create a copy of NowPlayingPlayback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NowPlayingPlaybackCopyWith<NowPlayingPlayback> get copyWith => _$NowPlayingPlaybackCopyWithImpl<NowPlayingPlayback>(this as NowPlayingPlayback, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NowPlayingPlayback&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isReady, isReady) || other.isReady == isReady)&&(identical(other.isBuffering, isBuffering) || other.isBuffering == isBuffering)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.hasPrevious, hasPrevious) || other.hasPrevious == hasPrevious)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.hasItem, hasItem) || other.hasItem == hasItem));
}


@override
int get hashCode => Object.hash(runtimeType,position,duration,isPlaying,isReady,isBuffering,isLoading,speed,hasPrevious,hasNext,hasItem);

@override
String toString() {
  return 'NowPlayingPlayback(position: $position, duration: $duration, isPlaying: $isPlaying, isReady: $isReady, isBuffering: $isBuffering, isLoading: $isLoading, speed: $speed, hasPrevious: $hasPrevious, hasNext: $hasNext, hasItem: $hasItem)';
}


}

/// @nodoc
abstract mixin class $NowPlayingPlaybackCopyWith<$Res>  {
  factory $NowPlayingPlaybackCopyWith(NowPlayingPlayback value, $Res Function(NowPlayingPlayback) _then) = _$NowPlayingPlaybackCopyWithImpl;
@useResult
$Res call({
 Duration position, Duration? duration, bool isPlaying, bool isReady, bool isBuffering, bool isLoading, double speed, bool hasPrevious, bool hasNext, bool hasItem
});




}
/// @nodoc
class _$NowPlayingPlaybackCopyWithImpl<$Res>
    implements $NowPlayingPlaybackCopyWith<$Res> {
  _$NowPlayingPlaybackCopyWithImpl(this._self, this._then);

  final NowPlayingPlayback _self;
  final $Res Function(NowPlayingPlayback) _then;

/// Create a copy of NowPlayingPlayback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? duration = freezed,Object? isPlaying = null,Object? isReady = null,Object? isBuffering = null,Object? isLoading = null,Object? speed = null,Object? hasPrevious = null,Object? hasNext = null,Object? hasItem = null,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isReady: null == isReady ? _self.isReady : isReady // ignore: cast_nullable_to_non_nullable
as bool,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,hasPrevious: null == hasPrevious ? _self.hasPrevious : hasPrevious // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,hasItem: null == hasItem ? _self.hasItem : hasItem // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NowPlayingPlayback].
extension NowPlayingPlaybackPatterns on NowPlayingPlayback {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NowPlayingPlayback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NowPlayingPlayback() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NowPlayingPlayback value)  $default,){
final _that = this;
switch (_that) {
case _NowPlayingPlayback():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NowPlayingPlayback value)?  $default,){
final _that = this;
switch (_that) {
case _NowPlayingPlayback() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration position,  Duration? duration,  bool isPlaying,  bool isReady,  bool isBuffering,  bool isLoading,  double speed,  bool hasPrevious,  bool hasNext,  bool hasItem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NowPlayingPlayback() when $default != null:
return $default(_that.position,_that.duration,_that.isPlaying,_that.isReady,_that.isBuffering,_that.isLoading,_that.speed,_that.hasPrevious,_that.hasNext,_that.hasItem);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration position,  Duration? duration,  bool isPlaying,  bool isReady,  bool isBuffering,  bool isLoading,  double speed,  bool hasPrevious,  bool hasNext,  bool hasItem)  $default,) {final _that = this;
switch (_that) {
case _NowPlayingPlayback():
return $default(_that.position,_that.duration,_that.isPlaying,_that.isReady,_that.isBuffering,_that.isLoading,_that.speed,_that.hasPrevious,_that.hasNext,_that.hasItem);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration position,  Duration? duration,  bool isPlaying,  bool isReady,  bool isBuffering,  bool isLoading,  double speed,  bool hasPrevious,  bool hasNext,  bool hasItem)?  $default,) {final _that = this;
switch (_that) {
case _NowPlayingPlayback() when $default != null:
return $default(_that.position,_that.duration,_that.isPlaying,_that.isReady,_that.isBuffering,_that.isLoading,_that.speed,_that.hasPrevious,_that.hasNext,_that.hasItem);case _:
  return null;

}
}

}

/// @nodoc


class _NowPlayingPlayback extends NowPlayingPlayback {
  const _NowPlayingPlayback({this.position = Duration.zero, this.duration, this.isPlaying = false, this.isReady = false, this.isBuffering = false, this.isLoading = false, this.speed = 1, this.hasPrevious = false, this.hasNext = false, this.hasItem = true}): super._();
  

@override@JsonKey() final  Duration position;
@override final  Duration? duration;
@override@JsonKey() final  bool isPlaying;
@override@JsonKey() final  bool isReady;
@override@JsonKey() final  bool isBuffering;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  double speed;
@override@JsonKey() final  bool hasPrevious;
@override@JsonKey() final  bool hasNext;
@override@JsonKey() final  bool hasItem;

/// Create a copy of NowPlayingPlayback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NowPlayingPlaybackCopyWith<_NowPlayingPlayback> get copyWith => __$NowPlayingPlaybackCopyWithImpl<_NowPlayingPlayback>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NowPlayingPlayback&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isReady, isReady) || other.isReady == isReady)&&(identical(other.isBuffering, isBuffering) || other.isBuffering == isBuffering)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.hasPrevious, hasPrevious) || other.hasPrevious == hasPrevious)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.hasItem, hasItem) || other.hasItem == hasItem));
}


@override
int get hashCode => Object.hash(runtimeType,position,duration,isPlaying,isReady,isBuffering,isLoading,speed,hasPrevious,hasNext,hasItem);

@override
String toString() {
  return 'NowPlayingPlayback(position: $position, duration: $duration, isPlaying: $isPlaying, isReady: $isReady, isBuffering: $isBuffering, isLoading: $isLoading, speed: $speed, hasPrevious: $hasPrevious, hasNext: $hasNext, hasItem: $hasItem)';
}


}

/// @nodoc
abstract mixin class _$NowPlayingPlaybackCopyWith<$Res> implements $NowPlayingPlaybackCopyWith<$Res> {
  factory _$NowPlayingPlaybackCopyWith(_NowPlayingPlayback value, $Res Function(_NowPlayingPlayback) _then) = __$NowPlayingPlaybackCopyWithImpl;
@override @useResult
$Res call({
 Duration position, Duration? duration, bool isPlaying, bool isReady, bool isBuffering, bool isLoading, double speed, bool hasPrevious, bool hasNext, bool hasItem
});




}
/// @nodoc
class __$NowPlayingPlaybackCopyWithImpl<$Res>
    implements _$NowPlayingPlaybackCopyWith<$Res> {
  __$NowPlayingPlaybackCopyWithImpl(this._self, this._then);

  final _NowPlayingPlayback _self;
  final $Res Function(_NowPlayingPlayback) _then;

/// Create a copy of NowPlayingPlayback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? duration = freezed,Object? isPlaying = null,Object? isReady = null,Object? isBuffering = null,Object? isLoading = null,Object? speed = null,Object? hasPrevious = null,Object? hasNext = null,Object? hasItem = null,}) {
  return _then(_NowPlayingPlayback(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isReady: null == isReady ? _self.isReady : isReady // ignore: cast_nullable_to_non_nullable
as bool,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,hasPrevious: null == hasPrevious ? _self.hasPrevious : hasPrevious // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,hasItem: null == hasItem ? _self.hasItem : hasItem // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
