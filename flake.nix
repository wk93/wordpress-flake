{
  description = "Minimalny devShell dla WordPressa z PHP i MariaDB";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      php = pkgs.php83.buildEnv {
        extensions = {
          enabled,
          all,
        }:
          with all;
            enabled
            ++ [
              mysqli
              pdo_mysql
              mbstring
              curl
              gd
              zip
              dom
              fileinfo
            ];
      };
    in {
      devShells.default = pkgs.mkShell {
        packages = [
          php
          pkgs.mariadb
        ];

        shellHook = ''
          export MYSQL_DATABASE=wordpress
          export MYSQL_USER=wordpress
          export MYSQL_PASSWORD=wordpress
          export MYSQL_ROOT_PASSWORD=root
          export MYSQL_UNIX_PORT=$PWD/run/mysql-socket/mysql.sock

          mkdir -p run/mysql-socket run/mariadb

          if [ ! -d ./run/mariadb/mysql ]; then
            echo "📦 Inicjalizacja bazy danych..."
            mariadb-install-db --datadir=./run/mariadb > /dev/null
          fi

          echo "🚀 Uruchamianie mysqld..."
          mysqld --datadir=./run/mariadb \
                 --socket=$MYSQL_UNIX_PORT \
                 --pid-file=./run/mariadb/mysqld.pid \
                 --log-error=./run/mariadb/error.log \
                 --skip-networking &
          MYSQLD_PID=$!

          # 🧼 Zatrzymaj mysqld po wyjściu z devShella
          trap 'echo "🧹 Zatrzymywanie mysqld..."; kill $MYSQLD_PID' EXIT

          echo "✅ WordPress devShell gotowy"
        '';
      };
    });
}
