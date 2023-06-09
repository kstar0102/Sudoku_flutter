import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:kalil_utils/utils.dart';
import 'package:value_notifier/value_notifier.dart';

import 'sudoku_data.dart';
import 'sudoku_db.dart';

class _SudokuDBController
    extends SubcontrollerBase<SudokuController, _SudokuDBController> {
  ValueNotifier<SudokuAppBoardModel?> _savedState = ValueNotifier(null);
  EventNotifier<SudokuAppBoardModel> _didRequestSave = EventNotifier();
  final SudokuDb db;
  final SudokuAppBoardState? _initialState;

  _SudokuDBController.fromStorage(this.db) : _initialState = null;
  _SudokuDBController.fromInitialState(this.db, this._initialState);

  late final ValueListenable<SudokuAppBoardModel?> _toBeSaved =
      _didRequestSave.view().debounce(wait: const Duration(seconds: 1));

  late final ValueListenable<LoadingModel> _initialModel = dbLock
      .synchronized(() => _initialState == null
          ? sudokuDbGet(db)
          : _createFromInitialAndSaveToDb(db, _initialState!))
      .toValueListenable(eager: true)
      .map((snap) => snap.hasData
          ? LoadingModel.just(ModelOrError.right(snap.requireData))
          : snap.hasError
              ? LoadingModel.just(ModelOrError.left(snap.error!))
              : LoadingModel.none());

  ValueListenable<SudokuAppBoardModel?> get savedState => _savedState.view();
  ValueListenable<SudokuAppBoardState?> get savedSnapshot =>
      savedState.map((s) => s?.snapshot);

  ValueListenable<LoadingModel> get initialModel => _initialModel.view();

  static Future<SudokuAppBoardModel> _createFromInitialAndSaveToDb(
      SudokuDb db, SudokuAppBoardState initialState) async {
    final model = SudokuAppBoardModel(initialState);
    await sudokuDbStore(db, model);
    return model;
  }

  late final requestSave = _didRequestSave.add;

  final dbLock = Lock();

  Future<void> _save(SudokuAppBoardModel state) {
    print("saving!!");
    return dbLock
        .synchronized(() => sudokuDbStore(db, state))
        .then((_) => _savedState.value = state);
  }

  void _onInitialModel(LoadingModel model) {
    _savedState.value = model.visit(
      just: (v) => v.visit(
        left: (err) => null,
        right: (v) => v,
      ),
      none: () => null,
    );
  }

  void init() {
    super.init();
    initialModel.connect(_onInitialModel);
    _toBeSaved.tap((e) => e == null ? null : _save(e));
  }

  void dispose() {
    IDisposable.disposeAll([
      _savedState,
      _didRequestSave,
    ]);
    sudokuDbClose(db);
    IDisposable.disposeAll([
      _toBeSaved,
      _initialModel,
    ]);
    super.dispose();
  }
}

extension AAAA on SudokuController {
  Maybe<SudokuAppBoardModel> changeNumber(
    SudokuBoardIndex index,
    int to,
  ) =>
      maybeAddE(snapshot.value!.changeNumberE(index, to));

  Maybe<SudokuAppBoardModel> addPossibility(
    SudokuBoardIndex index,
    int number,
  ) =>
      maybeAddE(snapshot.value!.addPossibilityE(index, number));

  Maybe<SudokuAppBoardModel> removePossibility(
    SudokuBoardIndex index,
    int number,
  ) =>
      maybeAddE(snapshot.value!.removePossibilityE(index, number));

  Maybe<SudokuAppBoardModel> commitNumber(
    SudokuBoardIndex index,
    int number,
  ) =>
      maybeAddE(snapshot.value!.commitNumberE(index, number));

  Maybe<SudokuAppBoardModel> clearTile(
    SudokuBoardIndex index,
  ) =>
      maybeAddE(snapshot.value!.clearTileE(index));

  Maybe<SudokuAppBoardModel> changeFromNumberToPossibility(
          SudokuBoardIndex index, int possibility) =>
      maybeAddE(
          snapshot.value!.changeFromNumberToPossibilityE(index, possibility));

  Maybe<SudokuAppBoardModel> clearBoard() =>
      maybeAddE(snapshot.value!.clearBoardE());
}

class SudokuController extends ControllerBase<SudokuController> {
  final _SudokuDBController _db;
  final ActionNotifier _didModifyModel = ActionNotifier();
  final EventNotifier<bool> _didFinish = EventNotifier();

  SudokuController.fromStorage(SudokuDb db)
      : _db = ControllerBase.create(() => _SudokuDBController.fromStorage(db));

  SudokuController.fromInitialState(
      SudokuDb db, SudokuAppBoardState initialState)
      : _db = ControllerBase.create(
            () => _SudokuDBController.fromInitialState(db, initialState));

  ValueListenable<ModelOrError?> get initialModel => _db.initialModel
      .map((loading) => loading.visit(just: (v) => v, none: () => null));

  ValueListenable<ModelOrError?> get model =>
      initialModel.bind((model) => _didModifyModel.view().map((_) => model));

  ValueListenable<SudokuAppBoardModel?> get modelOrNull =>
      model.map((modelOrError) => modelOrError?.visit(
            left: (err) => null,
            right: (model) => model,
          ));

  // TODO
  ValueListenable<bool?> get didFinish => _didFinish.view();
  ValueListenable<bool> get isFinished => didFinish.map((e) => e ?? false);

  ValueListenable<SudokuAppBoardState?> get snapshot =>
      modelOrNull.map((model) => model?.snapshot);

  ValueListenable<ModelUndoState?> get undoState =>
      modelOrNull.map((model) => model?.undoState);

  // todo: return SudokuAppBoardModel or SudokuAppBoardState
  Maybe<SudokuAppBoardModel> maybeAddE(Maybe<SudokuAppBoardChange> e) {
    final model = modelOrNull.value!;
    return model.maybeAddE(e).fmap(
      (model) {
        _didModifyModel.notify();
        _db.requestSave(model);
        return model;
      },
    );
  }

  void undo() {
    final model = modelOrNull.value;
    if (model?.undo() ?? false) {
      _didModifyModel.notify();
      _db.requestSave(model!);
    }
  }

  void reset() {
    clearBoard().fmap(
      (model) {
        _didModifyModel.notify();
        _db.requestSave(model);
        return model;
      },
    );
  }

  void init() {
    super.init();
    addSubcontroller(_db);
  }

  void dispose() {
    disposeSubcontroller(_db);
    IDisposable.disposeAll([
      _didModifyModel,
      _didFinish,
    ]);
    super.dispose();
  }
}
