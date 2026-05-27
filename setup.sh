#!/bin/bash
# setup.sh — Configuração inicial do Lanchonete Manager

echo "🍔 Lanchonete Manager — Setup"
echo "=============================="

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter não encontrado. Instale em: https://flutter.dev/docs/get-started/install"
  exit 1
fi

echo "✅ Flutter encontrado: $(flutter --version | head -1)"

# Criar pastas de assets
echo "📁 Criando pastas de assets..."
mkdir -p assets/images assets/fonts

# Instalar dependências
echo "📦 Instalando dependências..."
flutter pub get

if [ $? -ne 0 ]; then
  echo "❌ Erro ao instalar dependências. Verifique o pubspec.yaml."
  exit 1
fi

echo ""
echo "✅ Setup concluído!"
echo ""
echo "▶  Para rodar o app:"
echo "   flutter run"
echo ""
echo "📦 Para gerar APK de release:"
echo "   flutter build apk --release"
echo ""
echo "🌐 Para gerar build web:"
echo "   flutter build web --release"
