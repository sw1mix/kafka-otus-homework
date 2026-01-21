#!/bin/bash
# Обертка для запуска Ansible с автоматической активацией виртуального окружения

# Если виртуальное окружение существует, используем его
if [ -d "venv" ] && [ -f "venv/bin/ansible-playbook" ]; then
    exec ./venv/bin/ansible-playbook "$@"
# Если Ansible установлен системно, используем его
elif command -v ansible-playbook &> /dev/null; then
    exec ansible-playbook "$@"
else
    echo "Ошибка: Ansible не найден"
    echo "Запустите ./scripts/setup.sh для установки"
    exit 1
fi
