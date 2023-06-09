import 'package:app/module/animation.dart';
import 'package:app/module/theme.dart';
import 'package:app/viewmodel/preferences_dialog.dart';
import 'package:app/widget/adaptative_dialog.dart';
import 'package:flutter/material.dart';
import 'package:value_notifier/value_notifier.dart';

import 'dialog.dart';

Future<PreferencesDialogResult?> showPreferencesDialog(BuildContext context) =>
    showAdaptativeDialog(
      context,
      builder: (context, body) =>
          ControllerInjectorBuilder<PreferencesDialogController>(
        factory: (_) => ControllerBase.create(
          () => PreferencesDialogController(
            InheritedController.get<SudokuThemeController>(context),
            InheritedController.get<SudokuAnimationController>(context),
          ),
        ),
        inherited: true,
        builder: (context, controller) =>
            PreferencesDialog.builder(context, body),
      ),
      bodyBuilder: PreferencesDialog.buildBody,
      saveBuilder: PreferencesDialog.buildSave,
      titleBuilder: PreferencesDialog.buildTitle,
    );

Future<bool> showPreferencesDialogAndUpdateModules(BuildContext context) =>
    showPreferencesDialog(context).then((r) {
      if (r == null) {
        return false;
      }
      final theme =
          InheritedController.get<SudokuThemeController>(context).unwrap;
      final animation =
          InheritedController.get<SudokuAnimationController>(context).unwrap;
      // set the user themes first because the index may be of one of the new
      // user themes
      theme.setUserThemes(r.e0.e1);
      theme.changeIndex(r.e0.e0);
      animation.changeAnimationOptions(r.e1);
      return true;
    });
