// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';

import 'package:app/module/base.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef S_El = ffi.Uint8;
typedef S_Size = ffi.Uint32;

class S_Board extends ffi.Opaque {}

typedef S_Board_Ptr = ffi.Pointer<S_Board>;

typedef ExternSudokuBoard = S_Board_Ptr;

ffi.DynamicLibrary _openLib(
  String name, [
  String version = '',
]) {
  final String suffix;
  if (Platform.isMacOS || Platform.isIOS) {
    suffix = '.dylib';
  } else if (Platform.isWindows) {
    suffix = '.dll';
  } else {
    assert(Platform.isAndroid || Platform.isFuchsia || Platform.isLinux);
    suffix = '.so' +
        (Platform.isLinux ? '${version.isEmpty ? '' : '.'}$version' : '');
  }
  final soname = '$name$suffix';
  if (Platform.isLinux || Platform.isWindows || Platform.isIOS) {
    final dir = Directory.current.path;
    return ffi.DynamicLibrary.open(p.join(dir, soname));
  }
  return ffi.DynamicLibrary.open(soname);
}

final libsudoku = () {
  final libsudoku = _openLib('libsudoku', '2.0.4');
  // Initialize the random state.
  final s_rand_set_state = libsudoku.lookupFunction<
      s_rand_set_state_signature_native,
      s_rand_set_state_signature_dart>('s_rand_set_state');
  s_rand_set_state(Random().nextInt(1 << 32));
  return libsudoku;
}();
typedef s_rand_set_state_signature_native = ffi.Void Function(ffi.Int32 state);
typedef s_rand_set_state_signature_dart = void Function(int state);
typedef s_board_initialize_to_zero_signature_native = ffi.Void Function(
    S_Board_Ptr board);
typedef s_board_initialize_to_zero_signature_dart = void Function(
    S_Board_Ptr board);
final s_board_initialize_to_zero = libsudoku.lookupFunction<
    s_board_initialize_to_zero_signature_native,
    s_board_initialize_to_zero_signature_dart>('s_board_initialize_to_zero');

typedef s_board_side_sqrt_signature_native = S_Size Function(S_Board_Ptr board);
typedef s_board_side_sqrt_signature_dart = int Function(S_Board_Ptr board);
final s_board_side_sqrt = libsudoku.lookupFunction<
    s_board_side_sqrt_signature_native,
    s_board_side_sqrt_signature_dart>('s_board_side_sqrt');

typedef s_board_side_signature_native = S_Size Function(S_Board_Ptr board);
typedef s_board_side_signature_dart = int Function(S_Board_Ptr board);
final s_board_side = libsudoku.lookupFunction<s_board_side_signature_native,
    s_board_side_signature_dart>('s_board_side');

typedef s_board_get_at_signature_native = S_El Function(
    S_Board_Ptr board, S_Size r, S_Size c);
typedef s_board_get_at_signature_dart = int Function(
    S_Board_Ptr board, int r, int c);
final s_board_get_at = libsudoku.lookupFunction<s_board_get_at_signature_native,
    s_board_get_at_signature_dart>('s_board_get_at');

typedef s_board_set_at_signature_native = ffi.Void Function(
    S_Board_Ptr board, S_Size r, S_Size c, S_El value);
typedef s_board_set_at_signature_dart = void Function(
    S_Board_Ptr board, int r, int c, int value);
final s_board_set_at = libsudoku.lookupFunction<s_board_set_at_signature_native,
    s_board_set_at_signature_dart>('s_board_set_at');

typedef s_board_copy_into_signature_native = ffi.Void Function(
    S_Board_Ptr dest, S_Board_Ptr src);
typedef s_board_copy_into_signature_dart = void Function(
    S_Board_Ptr dest, S_Board_Ptr src);
final s_board_copy_into = libsudoku.lookupFunction<
    s_board_copy_into_signature_native,
    s_board_copy_into_signature_dart>('s_board_copy_into');

typedef s_board_new_signature_native = S_Board_Ptr Function(S_Size side_sqrt);
typedef s_board_new_signature_dart = S_Board_Ptr Function(int sideSqrt);
final s_board_new = libsudoku.lookupFunction<s_board_new_signature_native,
    s_board_new_signature_dart>('s_board_new');

typedef s_board_free_signature_native = S_Board_Ptr Function(S_Board_Ptr board);
typedef s_board_free_signature_dart = S_Board_Ptr Function(S_Board_Ptr board);
final s_board_free = libsudoku.lookupFunction<s_board_free_signature_native,
    s_board_free_signature_dart>('s_board_free');

typedef s_sudoku_generate_signature_native = ffi.Void Function(
    S_Board_Ptr board);
typedef s_sudoku_generate_signature_dart = void Function(S_Board_Ptr board);
final s_sudoku_generate = libsudoku.lookupFunction<
    s_sudoku_generate_signature_native,
    s_sudoku_generate_signature_dart>('s_sudoku_generate');

typedef s_sudoku_has_many_sols_signature_native = ffi.Bool Function(
    S_Board_Ptr board);
typedef s_sudoku_has_many_sols_signature_dart = bool Function(
    S_Board_Ptr board);
final s_sudoku_has_many_sols = libsudoku.lookupFunction<
    s_sudoku_has_many_sols_signature_native,
    s_sudoku_has_many_sols_signature_dart>('s_sudoku_has_many_sols');

ExternSudokuBoard _createExternBoardWithSideSqrt(int sideSqrt) {
  final result = s_board_new(sideSqrt);
  _dbg_ffi_print("Returning malloced ${_addresses(result)}");

  return result;
}

void _zeroOutExternBoard(ExternSudokuBoard board) {
  _dbg_ffi_print("Zeroing board at ${_addresses(board)}");

  s_board_initialize_to_zero(board);
}

ExternSudokuBoard externSudokuBoardFrom(SudokuBoard board) {
  final side = board.length;
  final sideSqrt = sqrt(side).toInt();
  assert(sideSqrt * sideSqrt == side);

  final nativeBoard = _createExternBoardWithSideSqrt(side);
  for (int y = 0; y < side; y++) {
    for (int x = 0; x < side; x++) {
      s_board_set_at(
        nativeBoard,
        y,
        x,
        sudokuBoardGetAt(board, SudokuBoardIndex(x, y)),
      );
    }
  }
  return nativeBoard;
}

ExternSudokuBoard emptyExternSudokuBoard(int side) {
  final sideSqrt = sqrt(side).toInt();
  assert(sideSqrt * sideSqrt == side);
  _dbg_ffi_print("Gonna create native board to be emptied");
  final nativeBoard = _createExternBoardWithSideSqrt(sideSqrt);

  _dbg_ffi_print("Created native board at ${_addresses(nativeBoard)}");

  _zeroOutExternBoard(nativeBoard);

  _dbg_ffi_print("zeroed native board at ${_addresses(nativeBoard)}");
  return nativeBoard;
}

ExternSudokuBoard cloneExternSudokuBoard(ExternSudokuBoard other) {
  final result = _createExternBoardWithSideSqrt(s_board_side_sqrt(other));
  _dbg_ffi_print(
      "Gonna copy from ${_addresses(other)} to ${_addresses(result)}");
  s_board_copy_into(result, other);
  _dbg_ffi_print("Copied!");
  return result;
}

int externSudokuBoardGetAt(ExternSudokuBoard board, SudokuBoardIndex index) =>
    s_board_get_at(board, index.y, index.x);

void externSudokuBoardSetAt(
  ExternSudokuBoard board,
  SudokuBoardIndex index,
  int value,
) =>
    s_board_set_at(board, index.y, index.x, value);

int externSudokuSide(ExternSudokuBoard board) => s_board_side(board);

SudokuBoard sudokuBoardFromExtern(ExternSudokuBoard extern) {
  final side = externSudokuSide(extern);
  final result = emptySudokuBoard(side);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final index = SudokuBoardIndex(x, y);
      sudokuBoardSetAt(
        result,
        index,
        externSudokuBoardGetAt(extern, index),
      );
    }
  }
  return result;
}

String _addresses(ExternSudokuBoard board) =>
    '*board = 0x${board.address.toRadixString(16)}';

ExternSudokuBoard generateExternSudokuBlocking(int side) {
  final board = emptyExternSudokuBoard(side);
  _dbg_ffi_print("Created sudoku to use in generation at ${_addresses(board)}");

  s_sudoku_generate(board);

  _dbg_ffi_print("Generated sudoku at ${_addresses(board)}");
  return board;
}

bool externSudokuHasOneSolBlocking(ExternSudokuBoard board) {
  return !s_sudoku_has_many_sols(board);
}

const _dbg_ffi = true;

void _dbg_ffi_print(Object? object) {
  if (!_dbg_ffi) {
    return;
  }
  if (kDebugMode) {
    print(object);
    stdout.flush();
  }
}

void externSudokuFree(ExternSudokuBoard board) {
  _dbg_ffi_print("Freeing board ${_addresses(board)}");
  s_board_free(board);
  _dbg_ffi_print("Freed board");
}
