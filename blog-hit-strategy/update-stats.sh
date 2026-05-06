#!/bin/bash
# Qiita/Zenn の統計を取得して skill.md を更新するスクリプト

set -e

SKILL_FILE="$(dirname "$0")/skill.md"
QIITA_USER="tamakiiii"
ZENN_USER="tamakiiii"

# Qiita 統計取得
echo "Fetching Qiita stats..."
QIITA_DATA=$(curl -s "https://qiita.com/api/v2/users/${QIITA_USER}/items?per_page=100")

QIITA_TOTAL=$(echo "$QIITA_DATA" | jq 'length')
QIITA_AVG=$(echo "$QIITA_DATA" | jq '(map(.likes_count) | add / length * 10 | round / 10)')
QIITA_MAX=$(echo "$QIITA_DATA" | jq '(map(.likes_count) | max)')
QIITA_ZERO=$(echo "$QIITA_DATA" | jq '(map(select(.likes_count == 0)) | length)')
QIITA_ZERO_RATE=$(echo "$QIITA_DATA" | jq '((map(select(.likes_count == 0)) | length) / length * 100 | round)')
QIITA_MAX_TITLE=$(echo "$QIITA_DATA" | jq -r '(sort_by(-.likes_count) | .[0].title)')

# Zenn 統計取得
echo "Fetching Zenn stats..."
ZENN_DATA=$(curl -s "https://zenn.dev/api/articles?username=${ZENN_USER}&order=liked_count")

ZENN_TOTAL=$(echo "$ZENN_DATA" | jq '.articles | length')
ZENN_MAX=$(echo "$ZENN_DATA" | jq '(.articles | sort_by(-.liked_count) | .[0].liked_count)')
ZENN_MAX_TITLE=$(echo "$ZENN_DATA" | jq -r '(.articles | sort_by(-.liked_count) | .[0].title)')
ZENN_MAX_CHARS=$(echo "$ZENN_DATA" | jq '(.articles | sort_by(-.liked_count) | .[0].body_letters_count)')

echo "Qiita: ${QIITA_TOTAL}記事, 平均${QIITA_AVG}いいね, 最高${QIITA_MAX}いいね"
echo "Zenn: ${ZENN_TOTAL}記事, 最高${ZENN_MAX}いいね"
echo "0いいね率: ${QIITA_ZERO_RATE}%（${QIITA_ZERO}/${QIITA_TOTAL}件）"

# skill.md の統計テーブルを更新
QIITA_MAX_SHORT=$(echo "$QIITA_MAX_TITLE" | cut -c1-15)
ZENN_MAX_CHARS_FMT=$(printf "%'.f" "$ZENN_MAX_CHARS" 2>/dev/null || echo "$ZENN_MAX_CHARS")

perl -i -0pe "
  s/\| Qiita総記事数 \| .+ \|/| Qiita総記事数 | ${QIITA_TOTAL}件 |/;
  s/\| Qiita平均いいね \| .+ \|/| Qiita平均いいね | ${QIITA_AVG} |/;
  s/\| Qiita最高いいね \| .+ \|/| Qiita最高いいね | ${QIITA_MAX}（${QIITA_MAX_SHORT}…） |/;
  s/\| Zenn総記事数 \| .+ \|/| Zenn総記事数 | ${ZENN_TOTAL}件 |/;
  s/\| Zenn最高いいね \| .+ \|/| Zenn最高いいね | ${ZENN_MAX}（${ZENN_MAX_CHARS}文字） |/;
  s/\| いいね0件率 \| .+ \|/| いいね0件率 | ${QIITA_ZERO_RATE}%（${QIITA_ZERO}\/${QIITA_TOTAL}件） |/;
" "$SKILL_FILE"

echo "✓ ${SKILL_FILE} を更新しました"
