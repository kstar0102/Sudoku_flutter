import 'dart:convert';

import 'package:app/base/hive.dart';
import 'package:flutter/material.dart';
import 'package:utils/utils.dart';
import 'package:hive/hive.dart';
import 'package:adt_annotation/adt_annotation.dart' show data, T, Tp, NoMixin;
import 'package:adt_annotation/adt_annotation.dart' as adt;

import '../generation/generation.dart';
import 'data.dart';

part 'home_db.g.dart';
part 'home_db.adapters.dart';

// data _SudokuHomeDbValues = SidesInfo SudokuHomeSideInfo
//                          | ActiveInfo SudokuDifficulty Int
@data(
  #_SudokuHomeDbValues,
  [],
  adt.Union(
    {
      #SidesInfo: {
        #info: T(#SudokuHomeSidesInfo),
      },
      #ActiveInfo: {
        #difficulty: T(#SudokuDifficulty),
        #sideSqrt: T(#int),
      }
    },
    deriveMode: adt.UnionVisitDeriveMode.data,
  ),
)
const Type _sudokuHomeDbValues = _SudokuHomeDbValues;

@data(
  #SudokuHomeDb,
  [],
  adt.Opaque(T(#Box, args: [T(#_SudokuHomeDbValues)])),
)
const Type _sudokuHomeDb = SudokuHomeDb;

bool _sudokuHomeDbWasInitialized = false;
void sudokuHomeDbInitialize() {
  assert(!_sudokuHomeDbWasInitialized);
  Hive.registerAdapter(_SudokuHomeDbValuesAdapter());
  Hive.registerAdapter(_SudokuHomeItemAdapter());
  Hive.registerAdapter(_SudokuDifficultyAdapter());
  Hive.registerAdapter(_ActiveInfoAdapter());
  _sudokuHomeDbWasInitialized = true;
}

Future<SudokuHomeDb> sudokuHomeDbOpen() {
  assert(_sudokuHomeDbWasInitialized);
  return Hive.openBox<_SudokuHomeDbValues>('sudoku-home').then(SudokuHomeDb._);
}

SidesInfo? sudokuHomeDbGetSidesInfo(
  SudokuHomeDb db,
) =>
    db._unwrap.get('sides-info')?.visit(
          sidesInfo: (sidesInfo) => sidesInfo,
          activeInfo: (activeInfo) => throw StateError(
              "Expected it to be SidesInfo, but it is ActiveInfo"),
        );

ActiveInfo? sudokuHomeDbGetActiveInfo(
  SudokuHomeDb db,
) =>
    db._unwrap.get('active-info')?.visit(
          sidesInfo: (_) => throw StateError(
              "Expected it to be ActiveInfo, but it is SidesInfo"),
          activeInfo: (activeInfo) => activeInfo,
        );

SudokuDifficulty sudokuHomeDbGetActiveDifficultyOr(
  SudokuHomeDb db,
  SudokuDifficulty difficulty,
) =>
    sudokuHomeDbGetActiveInfo(db)?.difficulty ?? difficulty;

int sudokuHomeDbGetActiveSideSqrtOr(
  SudokuHomeDb db,
  int sideSqrt,
) =>
    sudokuHomeDbGetActiveInfo(db)?.sideSqrt ?? sideSqrt;

SidesInfo sudokuHomeDbGetSidesInfoOr(
  SudokuHomeDb db,
  SidesInfo info,
) =>
    sudokuHomeDbGetSidesInfo(db) ?? info;

Future<void> sudokuHomeDbStoreActiveInfo(
  SudokuHomeDb db,
  ActiveInfo info,
) =>
    db._unwrap.put('active-info', info);

Future<void> sudokuHomeDbStoreSidesInfo(
  SudokuHomeDb db,
  SidesInfo info,
) =>
    db._unwrap.put('sides-info', info);

Future<void> sudokuHomeDbClose(SudokuHomeDb db) => db._unwrap.close();
