import 'package:app/module/base.dart';
import 'package:flutter/material.dart';

import 'package:adt_annotation/adt_annotation.dart' show data, T;
import 'package:adt_annotation/adt_annotation.dart' as adt;
import 'package:flutter/foundation.dart';

part 'flutter_intents.g.dart';

class PressTileIntent extends Intent {
  final SudokuBoardIndex index;
  const PressTileIntent(this.index);
}

// data PressNumberIntent = PressNumberOnBoardIntent SudokuBoardIndex int
//                        | PressNumberOnBoardAltIntent SudokuBoardIndex int
//                        | PressFreeNumber int
@data(
  #PressNumberIntent,
  [],
  adt.Union({
    #PressNumberOnBoardIntent: {
      #index: T(#SudokuBoardIndex),
      #number: T(#int),
    },
    #PressNumberOnBoardAltIntent: {
      #index: T(#SudokuBoardIndex),
      #number: T(#int),
    },
    #PressFreeNumber: {
      #number: T(#int),
    },
  }),
  mixin: [
    T(#IntentMixin),
    T(#Diagnosticable),
  ],
  // Cant be used because Diagnosticable has an different signature for
  // toString(). Kinda sucks tbh.
  deriveToString: false,
  // Flutter uses the runtimeType of intents, so we cant override it.
  deriveRuntimeType: false,
)
const Type _pressNumberIntent = PressNumberIntent;
mixin IntentMixin implements Intent {}

class ValidateBoardIntent extends Intent {
  const ValidateBoardIntent();
}

class ChangePlacementModeIntent extends Intent {
  const ChangePlacementModeIntent();
}

class ResetBoardIntent extends Intent {
  const ResetBoardIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}
