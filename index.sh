#!/usr/bin/env bash

# Вывода отчёта
REPORT_FILE="system_analysis_report.txt"

# Очистка предыдущего отчёта
echo "" > "$REPORT_FILE"

# Добавлен заголовок
echo "=== Анализ системы после зависания/перезагрузки ===" | tee -a "$REPORT_FILE"
echo "Дата и время: $(date)" | tee -a "$REPORT_FILE"
echo "=================================================" | tee -a "$REPORT_FILE"

# 1. Информация о системе
echo -e "\n[1] Информация о системе:" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
echo -e "\n### Ядро и дистрибутив:" | tee -a "$REPORT_FILE"
uname -a | tee -a "$REPORT_FILE"
echo -e "\n### Версия ОС:" | tee -a "$REPORT_FILE"
lsb_release -a 2>/dev/null || cat /etc/os-release | tee -a "$REPORT_FILE"
echo -e "\n### Uptime:" | tee -a "$REPORT_FILE"
uptime | tee -a "$REPORT_FILE"

# 2. Анализ логов ядра (dmesg)
echo -e "\n[2] Логи ядра (dmesg):" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
dmesg -T | tail -n 50 | tee -a "$REPORT_FILE"

# 3. Логи systemd (journalctl)
echo -e "\n[3] Логи systemd (journalctl):" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
journalctl -b -1 -p 3 --no-pager | tail -n 50 | tee -a "$REPORT_FILE"

# 4. Проверка перезагрузок
echo -e "\n[4] История перезагрузок:" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
last reboot | head -n 5 | tee -a "$REPORT_FILE"

# 5. Проверка температуры и железа
echo -e "\n[5] Температура и аппаратное обеспечение:" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
echo -e "\n### Температура CPU:" | tee -a "$REPORT_FILE"
sensors 2>/dev/null || echo "Не установлен lm-sensors" | tee -a "$REPORT_FILE"
echo -e "\n### Информация о CPU:" | tee -a "$REPORT_FILE"
lscpu | grep -E "Model name|MHz|cores" | tee -a "$REPORT_FILE"

# 6. Проверка диска (SMART)
echo -e "\n[6] Проверка состояния диска:" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
echo -e "\n### S.M.A.R.T. данные:" | tee -a "$REPORT_FILE"
if command -v smartctl &>/dev/null; then
    for disk in $(lsblk -d -o NAME | grep -v NAME); do
        echo "Проверка /dev/$disk:" | tee -a "$REPORT_FILE"
        sudo smartctl -a "/dev/$disk" | grep -E "Model|Reallocated|Pending|Errors|Temperature" | tee -a "$REPORT_FILE"
    done
else
    echo "Утилита smartctl не установлена (apt install smartmontools)" | tee -a "$REPORT_FILE"
fi

# 7. Проверка оперативной памяти
echo -e "\n[7] Проверка оперативной памяти:" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
free -h | tee -a "$REPORT_FILE"
echo -e "\n### Ошибки памяти (dmesg):" | tee -a "$REPORT_FILE"
dmesg -T | grep -i "memory\|oom\|kill" | tail -n 20 | tee -a "$REPORT_FILE"

# 8. Проверка сетевых ошибок
echo -e "\n[8] Сетевые ошибки (если есть):" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
journalctl -b -1 -p 3 -u NetworkManager --no-pager | tail -n 20 | tee -a "$REPORT_FILE"

# 9. Проверка неудачных сервисов
echo -e "\n[9] Неудачные сервисы:" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
systemctl --failed | tee -a "$REPORT_FILE"

# 10. Проверка использования swap
echo -e "\n[10] Использование swap:" | tee -a "$REPORT_FILE"
echo -e "--------------------------" | tee -a "$REPORT_FILE"
swapon --show | tee -a "$REPORT_FILE"

# Итог
echo -e "\n=== Анализ завершён. Отчёт сохранён в $REPORT_FILE ===" | tee -a "$REPORT_FILE"
echo "Итоговый файл для дальнейшего анализа." | tee -a "$REPORT_FILE"
