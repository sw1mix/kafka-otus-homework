#!/bin/bash
# Скрипт для первоначальной настройки окружения

set -e

echo "=== Настройка окружения для Kafka Infrastructure as Code ==="
echo ""

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo "Ошибка: Docker не установлен"
    exit 1
fi

# Проверка наличия Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Ошибка: Docker Compose не установлен"
    exit 1
fi

# Проверка наличия Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "Ansible не найден. Попытка установки..."
    
    # Попытка установки через apt (для Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        echo "Попытка установки Ansible через apt..."
        if sudo apt-get update && sudo apt-get install -y ansible 2>/dev/null; then
            echo "✓ Ansible установлен через apt"
        else
            echo "Не удалось установить через apt, пробуем виртуальное окружение..."
        fi
    fi
    
    # Если все еще не установлен, пробуем pip с виртуальным окружением
    if ! command -v ansible-playbook &> /dev/null; then
        echo "Создание виртуального окружения для Ansible..."
        if [ ! -d "venv" ]; then
            if ! python3 -m venv venv 2>/dev/null; then
                echo "Ошибка: Не удалось создать виртуальное окружение"
                echo "Установите python3-venv: sudo apt-get install python3-venv"
                echo ""
                echo "Или установите Ansible вручную:"
                echo "  sudo apt-get install ansible"
                echo "  или"
                echo "  pipx install ansible"
                exit 1
            fi
        fi
        source venv/bin/activate
        pip install --upgrade pip --quiet
        pip install ansible --quiet
        echo "✓ Ansible установлен в виртуальное окружение"
        echo ""
        echo "⚠ ВНИМАНИЕ: Для использования Ansible активируйте виртуальное окружение:"
        echo "  source venv/bin/activate"
        echo ""
        echo "Или используйте полный путь в командах:"
        echo "  ./venv/bin/ansible-playbook playbooks/site.yml"
    fi
else
    echo "✓ Ansible уже установлен"
    ansible-playbook --version | head -1
fi

# Создание необходимых директорий
echo "Создание директорий..."
mkdir -p config_backups
mkdir -p logs

# Установка прав на скрипты
chmod +x scripts/*.sh

echo "✓ Настройка завершена"
echo ""
echo "Для запуска кластера выполните:"
echo "  docker-compose up -d"
echo ""
echo "Для применения конфигурации выполните:"
if [ -f "venv/bin/ansible-playbook" ]; then
    echo "  source venv/bin/activate"
    echo "  ansible-playbook playbooks/site.yml"
    echo ""
    echo "Или используйте обертку:"
    echo "  ./scripts/run-ansible.sh playbooks/site.yml"
else
    echo "  ansible-playbook playbooks/site.yml"
fi
