#!/usr/bin/env bash
# Bootstrap secrets on a new Mac.
#
# fastlane/secrets/ — symlink в iCloud Drive (~/Library/Mobile Documents/...).
# Внутри лежит общий .p8-ключ ASC API (тот же, что используется Voicekeep
# и любым другим приложением под Apple Team U5BAN54DL2).
#
# Запустить один раз после `git clone`:
#   bash fastlane/setup_secrets.sh
set -euo pipefail

cd "$(dirname "$0")/.."

ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/voicekeep-secrets"
LOCAL_SYMLINK="fastlane/secrets"

if [ ! -e "$ICLOUD_DIR" ]; then
  echo "iCloud secrets dir not found at: $ICLOUD_DIR"
  echo "Дополнительно: положи туда AuthKey_798ZTD68WF.p8 (с другого Mac или из 1Password)."
  exit 1
fi

if [ -L "$LOCAL_SYMLINK" ]; then
  echo "Symlink already exists: $LOCAL_SYMLINK → $(readlink "$LOCAL_SYMLINK")"
elif [ -e "$LOCAL_SYMLINK" ]; then
  echo "Path $LOCAL_SYMLINK exists but is not a symlink. Удали вручную и перезапусти."
  exit 1
else
  ln -s "$ICLOUD_DIR" "$LOCAL_SYMLINK"
  echo "Linked $LOCAL_SYMLINK → $ICLOUD_DIR"
fi

if [ ! -f "$LOCAL_SYMLINK/AuthKey_798ZTD68WF.p8" ]; then
  echo "ВНИМАНИЕ: $LOCAL_SYMLINK/AuthKey_798ZTD68WF.p8 не найден. Скрипты ASC API работать не будут."
fi

echo "OK"
