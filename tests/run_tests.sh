#!/bin/bash

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$PROJECT_DIR/tests/configs"

PASSED=0
FAILED=0

run_success_test() {
    local name="$1"
    local config="$2"
    local expected="$3"
    local output

    if output=$("$PROJECT_DIR/run.sh" "$config" 2>&1); then
        if echo "$output" | grep -Fq "$expected"; then
            echo "PASS: $name"
            ((PASSED += 1))
        else
            echo "FAIL: $name"
            echo "Ожидалась строка: $expected"
            echo "$output"
            ((FAILED += 1))
        fi
    else
        echo "FAIL: $name"
        echo "$output"
        ((FAILED += 1))
    fi
}

run_failure_test() {
    local name="$1"
    local config="$2"
    local expected="$3"
    local output

    if output=$("$PROJECT_DIR/run.sh" "$config" 2>&1); then
        echo "FAIL: $name"
        echo "Программа должна была завершиться с ошибкой"
        echo "$output"
        ((FAILED += 1))
    elif echo "$output" | grep -Fq "$expected"; then
        echo "PASS: $name"
        ((PASSED += 1))
    else
        echo "FAIL: $name"
        echo "Ожидалась строка: $expected"
        echo "$output"
        ((FAILED += 1))
    fi
}

run_success_test \
    "Корректная конфигурация" \
    "$CONFIG_DIR/valid.yaml" \
    "package_name: express"

run_failure_test \
    "Пустое имя пакета" \
    "$CONFIG_DIR/empty_package.yaml" \
    "Пустое значение параметра package_name"

run_failure_test \
    "Некорректный URL репозитория" \
    "$CONFIG_DIR/invalid_repository.yaml" \
    "Некорректный URL репозитория"

run_failure_test \
    "Некорректный тестовый режим" \
    "$CONFIG_DIR/invalid_test_mode.yaml" \
    "test_mode должен содержать true или false"

run_failure_test \
    "Некорректный выходной файл" \
    "$CONFIG_DIR/invalid_output_file.yaml" \
    "должно оканчиваться на .svg"

run_failure_test \
    "Пустая подстрока фильтрации" \
    "$CONFIG_DIR/empty_filter.yaml" \
    "Пустое значение параметра filter_substring"

run_failure_test \
    "Отсутствующий конфигурационный файл" \
    "$CONFIG_DIR/not_found.yaml" \
    "Конфигурационный файл не найден"

echo
echo "Пройдено: $PASSED"
echo "Не пройдено: $FAILED"

if ((FAILED > 0)); then
    exit 1
fi