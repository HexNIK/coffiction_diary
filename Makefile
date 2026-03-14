.PHONY: all clean linux win64 release debug distclean info

PROJECT_NAME = project1
BINARY_NAME = coffiction_diary
PROJECT_LPR = src/app/$(PROJECT_NAME).lpr
PROJECT_LPI = src/app/$(PROJECT_NAME).lpi

SRC_DIR = src
DIST_DIR = dist
LINUX_DIR = $(DIST_DIR)/linux
WINDOWS_DIR = $(DIST_DIR)/windows
LIB_DIR = lib

LAZBUILD = lazbuild
FPC = fpc

LAZARUS_DIR = /usr/lib64/lazarus
LCL_BASE_DIR = $(LAZARUS_DIR)/lcl/units/x86_64-linux
LCL_GTK2_DIR = $(LAZARUS_DIR)/lcl/units/x86_64-linux/gtk2
PACKAGER_DIR = $(LAZARUS_DIR)/packager/units/x86_64-linux
LAZUTILS_DIR = $(LAZARUS_DIR)/components/lazutils/lib/x86_64-linux

$(info LCL_BASE_DIR: $(LCL_BASE_DIR))
$(info LCL_GTK2_DIR: $(LCL_GTK2_DIR))
$(info PACKAGER_DIR: $(PACKAGER_DIR))
$(info LAZUTILS_DIR: $(LAZUTILS_DIR))

PROJECT_UNITS = -Fu$(SRC_DIR)/app \
                -Fu$(SRC_DIR)/core \
                -Fu$(SRC_DIR)/core/database \
                -Fu$(SRC_DIR)/core/utils \
                -Fu$(SRC_DIR)/forms \
                -Fu$(SRC_DIR)/gui

LAZARUS_UNITS = -Fu$(LCL_BASE_DIR) \
                -Fu$(LCL_GTK2_DIR) \
                -Fu$(PACKAGER_DIR) \
                -Fu$(LAZUTILS_DIR)

RELEASE_FLAGS = -O3 -XX -Xs -CX -Sg -MObjFPC -Scghi -Cg \
                -k-Bstatic -k-static \
                -dLCL -dLCLgtk2 \
                -Fu/usr/lib64/fpc/3.2.2/units/x86_64-linux/* \
                -Fr/usr/lib64/fpc/msg/errore.msg

linux-release: | $(LINUX_DIR)
	@echo "Сборка Linux Release через lazbuild..."
	cd src/app && $(LAZBUILD) --build-mode=Release \
	  --os=linux --cpu=x86_64 --ws=gtk2 project1.lpi
	@# Ищем бинарник в разных местах
	@if [ -f src/app/$(BINARY_NAME) ]; then \
	  cp src/app/$(BINARY_NAME) $(LINUX_DIR)/; \
	  echo "Ok! Бинарник скопирован из src/app/$(BINARY_NAME)"; \
	elif [ -f src/app/bin/linux/release/x86_64-linux/$(BINARY_NAME) ]; then \
	  cp src/app/bin/linux/release/x86_64-linux/$(BINARY_NAME) $(LINUX_DIR)/; \
	  echo "Ok! Бинарник скопирован из src/app/bin/..."; \
	elif [ -f src/app/project1 ]; then \
	  cp src/app/project1 $(LINUX_DIR)/$(BINARY_NAME); \
	  echo "Ok! Бинарник project1 переименован в $(BINARY_NAME)"; \
	else \
	  echo "Fail! Бинарник не найден!"; \
	  find src/app -name '$(BINARY_NAME)' -o -name 'project1' -type f; \
	  exit 1; \
	fi
	@chmod +x $(LINUX_DIR)/$(BINARY_NAME)
	@echo "Ok! Linux Release собран: $(LINUX_DIR)/$(BINARY_NAME)"
	@echo "Запусти его: $(LINUX_DIR)/$(BINARY_NAME)"

linux-fpc: | $(LINUX_DIR)
	@echo "Сборка Linux через fpc..."
	@echo "Используемые пути:"
	@echo "  LCL: $(LCL_BASE_DIR)"
	@echo "  GTK2: $(LCL_GTK2_DIR)"
	@echo "  Packager: $(PACKAGER_DIR)"
	@echo "  LazUtils: $(LAZUTILS_DIR)"
	@# Проверяем наличие ключевого модуля
	@if [ ! -f $(LCL_GTK2_DIR)/interfaces.ppu ]; then \
	  echo "Fail! ОШИБКА: interfaces.ppu не найден!"; \
	  exit 1; \
	fi
	cd src/app && $(FPC) $(RELEASE_FLAGS) $(PROJECT_UNITS) $(LAZARUS_UNITS) \
	  -FE../../$(LINUX_DIR)  $(PROJECT_LPR)
	@if [ -f $(LINUX_DIR)/$(PROJECT_NAME) ]; then \
	  mv $(LINUX_DIR)/$(PROJECT_NAME) $(LINUX_DIR)/$(BINARY_NAME); \
	  echo "Fail! Бинарник переименован"; \
	fi
	@chmod +x $(LINUX_DIR)/$(BINARY_NAME)
	@echo "Fail! Linux (fpc) собран: $(LINUX_DIR)/$(BINARY_NAME)"

win64: | $(WINDOWS_DIR)
	@echo "Сборка Windows через кросс-компиляцию..."
	@# Проверяем наличие кросс-компилятора
	@if ! command -v ppcrossx64 >/dev/null 2>&1; then \
	  echo "Fail! ppcrossx64 не найден. Установи:"; \
	  echo "  sudo apt-get install fpc-cross-win64"; \
	  exit 1; \
	fi
	cd src/app && ppcrossx64 $(RELEASE_FLAGS) $(PROJECT_UNITS) \
	  -Twin64 -Px86_64 \
	  -FE../../../$(WINDOWS_DIR) $(PROJECT_LPR)
	@if [ -f $(WINDOWS_DIR)/$(PROJECT_NAME).exe ]; then \
	  mv $(WINDOWS_DIR)/$(PROJECT_NAME).exe $(WINDOWS_DIR)/$(BINARY_NAME).exe; \
	fi
	@echo "Ok! Windows собран: $(WINDOWS_DIR)/$(BINARY_NAME).exe"

all: linux-fpc  # Пока используем fpc как наиболее надежный
linux: linux-fpc
release: linux-fpc win64

$(LINUX_DIR):
	mkdir -p $(LINUX_DIR)

$(WINDOWS_DIR):
	mkdir -p $(WINDOWS_DIR)

clean:
	rm -rf $(LIB_DIR)/
	find . -name '*.o' -delete
	find . -name '*.ppu' -delete
	find . -name '*.rst' -delete
	find . -name '*.compiled' -delete
	find src/app -name '$(BINARY_NAME)' -type f -delete
	find src/app -name 'project1' -type f -delete
	find src/app -name '*.exe' -type f -delete
	@echo "Ok! Проект очищен"

distclean: clean
	rm -rf $(DIST_DIR)/
	@echo "Ok! Все артефакты удалены"

info:
	@echo "=== Информация о проекте ==="
	@echo "Project LPI: $(PROJECT_LPI)"
	@echo "Project LPR: $(PROJECT_LPR)"
	@echo ""
	@echo "=== Содержимое src/app ==="
	@ls -la src/app/ | grep -E "\.(lpi|lpr|pas|lfm)"
	@echo ""
	@echo "=== Проверка путей Lazarus ==="
	@echo "LCL_BASE_DIR: $(LCL_BASE_DIR) -> $$(if [ -d $(LCL_BASE_DIR) ]; then echo 'Ok!'; else echo 'Fail!'; fi)"
	@echo "LCL_GTK2_DIR: $(LCL_GTK2_DIR) -> $$(if [ -d $(LCL_GTK2_DIR) ]; then echo 'Ok!'; else echo 'Fail!'; fi)"
	@echo "PACKAGER_DIR: $(PACKAGER_DIR) -> $$(if [ -d $(PACKAGER_DIR) ]; then echo 'Ok!'; else echo 'Fail!'; fi)"
	@echo "LAZUTILS_DIR: $(LAZUTILS_DIR) -> $$(if [ -d $(LAZUTILS_DIR) ]; then echo 'Ok!'; else echo 'Fail!'; fi)"
	@echo ""
	@echo "=== Наличие ключевых модулей ==="
	@echo "interfaces.ppu: $$(if [ -f $(LCL_GTK2_DIR)/interfaces.ppu ]; then echo 'Ok!'; else echo 'Fail!'; fi)"
	@echo "forms.ppu: $$(if [ -f $(LCL_BASE_DIR)/forms.ppu ]; then echo 'Ok!'; else echo 'Fail!'; fi)"
