# 🎮 GameVault

Aplicativo mobile desenvolvido em **Flutter** para descobrir, pesquisar e favoritar jogos. O GameVault consome a API pública da [RAWG](https://rawg.io/apidocs) para exibir um catálogo de jogos e usa o [Supabase](https://supabase.com) para autenticação e armazenamento de dados do usuário.

---

## ✨ Funcionalidades

- 🔐 **Login e cadastro** de conta com e-mail e senha
- 🏠 **Home** com lista de jogos populares com scroll infinito
- 🔍 **Busca** de jogos por nome
- ⭐ **Filtro por avaliação mínima**
- 📄 **Tela de detalhes** de cada jogo
- ❤️ **Favoritar jogos** (salvo no Supabase)
- 👤 **Perfil do usuário**
- ⚙️ **Tela de configurações**

---

## 🛠️ Tecnologias utilizadas

| Tecnologia | Uso |
|---|---|
| Flutter | Framework principal |
| Dart | Linguagem |
| RAWG API | Catálogo de jogos |
| Supabase | Autenticação e banco de dados |
| flutter_dotenv | Variáveis de ambiente |
| sqflite | Banco local |
| carousel_slider | Carrossel de imagens |

---

## 📋 Pré-requisitos

Antes de rodar o projeto, você precisa ter instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão 3.x ou superior)
- [Android Studio](https://developer.android.com/studio) ou [VS Code](https://code.visualstudio.com/) com extensão Flutter
- Um emulador Android/iOS **ou** um dispositivo físico conectado
- Conta na [RAWG](https://rawg.io/apidocs) para obter a API Key
- Conta no [Supabase](https://supabase.com) com um projeto criado

---

## 🚀 Como rodar o projeto

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/gamevault.git
cd gamevault
```

### 2. Configure as variáveis de ambiente

Na raiz do projeto, crie um arquivo chamado `.env` baseado no `.env.example`:

```bash
cp .env.example .env
```

Abra o `.env` e preencha com suas chaves:

```env
RAWG_API_KEY=sua_chave_da_rawg_aqui
SUPABASE_URL=https://xxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=sua_anon_key_do_supabase_aqui
```

> **Como obter as chaves:**
> - **RAWG_API_KEY** → acesse [rawg.io/apidocs](https://rawg.io/apidocs), crie uma conta e gere sua chave
> - **SUPABASE_URL** e **SUPABASE_ANON_KEY** → no painel do Supabase, vá em **Project Settings → API**

### 3. Instale as dependências

```bash
flutter pub get
```

### 4. Rode o app

```bash
flutter run
```

Se tiver mais de um dispositivo conectado, liste-os e escolha:

```bash
flutter devices          # lista os dispositivos disponíveis
flutter run -d ID_AQUI   # rode no dispositivo escolhido
```

---

## ⚠️ Solução de problemas comuns

**Erro com `sign_in_with_apple` no Android:**

Atualize as dependências no `pubspec.yaml` para versões compatíveis:

```yaml
supabase_flutter: ^2.12.4
carousel_slider: ^5.0.0
flutter_dotenv: ^6.0.0
```

Depois rode:

```bash
flutter clean
flutter pub get
flutter run
```

---

**Arquivo `.env` não encontrado:**

Certifique-se de que o arquivo `.env` está na **raiz do projeto** (mesma pasta do `pubspec.yaml`) e que ele está declarado no `pubspec.yaml`:

```yaml
flutter:
  assets:
    - .env
```

---

## 📁 Estrutura do projeto

```
lib/
├── main.dart               # Entrada do app, configuração de rotas
├── models/
│   ├── game_model.dart     # Modelo de dados do jogo
│   └── supabase_models.dart
├── screens/
│   ├── home_screen.dart    # Lista e busca de jogos
│   ├── details_screen.dart # Detalhes do jogo
│   ├── login_screen.dart   # Tela de login
│   ├── register_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── api_service.dart    # Integração com a RAWG API
│   ├── auth_service.dart   # Login/cadastro com Supabase
│   └── supabase_service.dart
├── theme/
│   └── gamevault_theme.dart # Tema escuro do app
└── widgets/
    └── favorite_button.dart
```

---

## 🤝 Como contribuir

1. Clone o repositório e entre no branch correto:
```bash
git clone https://github.com/seu-usuario/gamevault.git
cd gamevault
git switch nome-do-branch
```

2. Crie um branch para sua feature:
```bash
git checkout -b minha-feature
```

3. Faça suas alterações, commit e push:
```bash
git add .
git commit -m "descrição do que foi feito"
git push origin minha-feature
```

4. Abra um **Pull Request** no GitHub.
