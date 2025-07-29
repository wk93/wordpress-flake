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

                      echo "🔑 Ustawianie hasła roota..."
                      cat > ./run/mariadb/init.sql <<SQL
          ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
          FLUSH PRIVILEGES;
          SQL

                      mysqld --datadir=./run/mariadb \
                             --socket=$MYSQL_UNIX_PORT \
                             --init-file=$PWD/run/mariadb/init.sql \
                             --pid-file=./run/mariadb/mysqld-init.pid \
                             --log-error=./run/mariadb/error-init.log \
                             --skip-networking &

                      INIT_PID=$!
                      echo "⏳ Czekam na zakończenie inicjalizacji..."
                      sleep 5
                      kill $INIT_PID
                      wait $INIT_PID 2>/dev/null
                      echo "🔒 Hasło roota ustawione"
                    fi

                    echo "🚀 Uruchamianie mysqld..."
                    mysqld --datadir=./run/mariadb \
                           --socket=$MYSQL_UNIX_PORT \
                           --pid-file=./run/mariadb/mysqld.pid \
                           --log-error=./run/mariadb/error.log \
                           --skip-networking &

                    MYSQLD_PID=$!
                    trap 'echo "🧹 Zatrzymywanie mysqld..."; kill $MYSQLD_PID' EXIT

                    echo "⏳ Czekam na gotowość bazy..."
                    for i in $(seq 1 30); do
                      if mysqladmin --socket="$MYSQL_UNIX_PORT" --user=root --password="$MYSQL_ROOT_PASSWORD" ping &> /dev/null; then
                        break
                      fi
                      sleep 1
                    done

                    echo "🧪 Tworzenie bazy i użytkownika..."
                    mysql --socket="$MYSQL_UNIX_PORT" -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
          CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
          CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
          GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';
          FLUSH PRIVILEGES;
          EOF

                    echo "✅ WordPress devShell gotowy z bazą i użytkownikiem"
        '';
      };
    });
}
