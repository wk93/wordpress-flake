# 🧪 WordPress DevShell with Nix Flakes

A minimal local development environment for WordPress using **PHP 8.3** and **MariaDB**, powered by **Nix Flakes**. No Docker, no external services — everything runs locally over a Unix socket.

---

## ⚙️ Requirements

- [Nix](https://nixos.org/download.html) with flakes enabled (`nix.version >= 2.7`)
- `git`

---

## 🚀 Quick Start

### 1. Enter the development shell

```sh
nix develop
```

This will:

- Install PHP with required extensions.
- Launch MariaDB locally (via `mysqld`) using a Unix socket at `./run/mysql-socket/mysql.sock`.
- Initialize the database (if not already done).
- Create a `wordpress` database and user with password.

### 2. Initialize WordPress

```sh
nix run .#init
```

This will:

- Download the latest WordPress into `./wordpress/` (if not already present).
- Generate `wp-config.php` with socket-based DB connection.
- Install WordPress (site URL: `http://localhost:8080`, user: `admin:admin`).

### 3. Start the PHP development server

```sh
nix run .#dev
```

WordPress will be accessible at:

```
http://localhost:8080/wp-admin
```

---

## 🗂 Project Structure

```
project-root/
├── flake.nix
├── flake.lock
├── run/                  # Local MariaDB data and socket
│   ├── mariadb/
│   └── mysql-socket/
├── .wp-cli/              # WP-CLI cache directory
│   └── cache/
└── wordpress/            # WordPress installation (downloaded by wp-cli)
```

---

## 📦 Features

- Local MariaDB via Unix socket — no open ports.
- Automatically creates DB and user (`wordpress`).
- Uses `wp-cli` to automate install and config.
- Everything isolated and ephemeral — easy to reset.

---

## 🔄 Reset

To start from scratch:

```sh
rm -rf wordpress run .wp-cli
```

Then repeat steps 1–3.

---

## 🧰 What's Included

- `php83` with extensions: `mysqli`, `pdo_mysql`, `mbstring`, `curl`, `gd`, `zip`, `dom`, `fileinfo`
- `mariadb`
- `wp-cli`
- `php -S` for local development
