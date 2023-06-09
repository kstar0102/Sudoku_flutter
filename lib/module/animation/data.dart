import 'package:kalil_adt_annotation/kalil_adt_annotation.dart'
    show data, T, Tp, NoMixin;
import 'package:kalil_adt_annotation/kalil_adt_annotation.dart' as adt;
import 'package:kalil_utils/utils.dart';

part 'data.g.dart';

@data(
    #SelectionAnimationOptions,
    [],
    adt.Record({
      #size: T(#bool),
      #color: T(#bool),
    }))
const Type _selectionAnimationOptions = SelectionAnimationOptions;

@data(
    #TextAnimationOptions,
    [],
    adt.Record({
      #position: T(#bool),
      #opacity: T(#bool),
      #color: T(#bool),
      #string: T(#bool),
      #size: T(#bool),
    }))
const Type _textAnimationOptions = TextAnimationOptions;

enum AnimationSpeed {
  disabled,
  fastest,
  fast,
  normal,
  slow,
}

@data(
    #AnimationOptions,
    [],
    adt.Tuple([
      T(#SelectionAnimationOptions),
      T(#TextAnimationOptions),
      T(#AnimationSpeed)
    ]))
const Type _animationOptions = AnimationOptions;

const defaultAnimationOptions = AnimationOptions(
  SelectionAnimationOptions(true, true),
  TextAnimationOptions(true, true, true, true, true),
  AnimationSpeed.fast,
);
