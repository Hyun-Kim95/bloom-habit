import 'package:flutter/material.dart';
import 'package:habit_fable/l10n/app_localizations.dart';

import 'app_update_service.dart';
import 'app_update_snooze.dart';
import 'app_version_policy.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required UpdateCheckResult result,
  required AppUpdateService updateService,
  required AppUpdateSnooze snooze,
  required VoidCallback onFlexibleDownloadStarted,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final forced = result.isForced;
  final versionLabel = result.displayVersion.trim();

  final defaultMessage = versionLabel.isNotEmpty
      ? (forced
          ? l10n.updateRequiredMessage(versionLabel)
          : l10n.updateAvailableMessage(versionLabel))
      : (forced ? l10n.updateRequiredMessageGeneric : l10n.updateAvailableMessageGeneric);
  final title = forced ? l10n.updateRequiredTitle : l10n.updateAvailableTitle;
  final storeUrl = result.storeUrl;

  await showDialog<void>(
    context: context,
    barrierDismissible: !forced,
    builder: (dialogContext) {
      return PopScope(
        canPop: !forced,
        child: AlertDialog(
          title: Text(title),
          content: Text(defaultMessage),
          actions: [
            if (!forced) ...[
              TextButton(
                onPressed: () async {
                  await snooze.snoozeForToday();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(l10n.updateSnoozeToday),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(l10n.updateLater),
              ),
            ],
            FilledButton(
              onPressed: storeUrl.trim().isEmpty && !forced
                  ? null
                  : () async {
                      final action = await updateService.performUpdate(
                        kind: result.kind,
                        storeUrl: storeUrl,
                        playInfo: result.playInfo,
                      );
                      if (!dialogContext.mounted) return;

                      if (action == AppUpdateActionResult.storeUnavailable) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(l10n.updateStoreUnavailable)),
                        );
                        if (!forced) {
                          Navigator.of(dialogContext).pop();
                        }
                        return;
                      }

                      if (action == AppUpdateActionResult.startedInApp &&
                          result.isOptional) {
                        onFlexibleDownloadStarted();
                        Navigator.of(dialogContext).pop();
                        return;
                      }

                      if (!forced &&
                          (action == AppUpdateActionResult.openedStore ||
                              action == AppUpdateActionResult.startedInApp)) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              child: Text(l10n.updateNow),
            ),
          ],
        ),
      );
    },
  );
}

void showFlexibleUpdateReadySnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.updateFlexibleReadyMessage),
      action: SnackBarAction(
        label: l10n.updateRestartNow,
        onPressed: () async {
          final service = AppUpdateService();
          await service.completeFlexibleUpdateIfReady();
        },
      ),
      duration: const Duration(seconds: 12),
    ),
  );
}
