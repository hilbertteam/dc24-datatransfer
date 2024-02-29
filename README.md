# dc24-datatransfer
Lab stand for the workshop

Dataset - https://github.com/morenoh149/postgresDBSamples/tree/master/adventureworks

---

## Развертываем инфраструктуру
```bash
yc init
export YC_TOKEN=$(yc iam create-token)
export TF_VAR_yc_token=$YC_TOKEN
export TF_VAR_transfer_password=ghHGSjsdsdRT
cd terraform
terraform init
terraform plan
terraform apply

## мы получим ошибку создания пользователей
## из-за несуществующих ролей
## поэтому запустим apply повторно, т.к. нужные роли создались на первом прогоне

terraform apply
# смотрим публичный и приватный IP развернутой VM
terraform output
```
В результате у нас развернулись

- Managed PostgreSQL
- Сompute instance с развернутой БД
  - надо по логу убедиться что cloud-init завершен
- Endpoints
- DataTransfer
  - который автоматом стартовал и завершился с ошибкой
---

## Настраиваем источник

```bash
export private_ip=$(terraform output --json | jq -r '.vm_private_ip.value')
export public_ip=$(terraform output --json | jq -r '.vm_ip.value')
ssh ubuntu@$public_ip
## проверим что cloud-init завершен
sudo tail -n 100 /var/log/syslog
## подключимся к базе
sudo -u postgres psql
```

- действия в базе источника
  
```sql
CREATE ROLE transfer WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'ghHGSjsdsdRT';
\c adventureworks
CREATE SCHEMA ya_transfer;
GRANT ALL PRIVILEGES ON SCHEMA ya_transfer TO transfer;

-- дадим права на чтение
DO $do$

DECLARE
    sch text;
BEGIN

    FOR sch IN SELECT nspname FROM pg_namespace where
    nspname <> 'information_schema' and nspname not like 'pg_%'
    LOOP

        EXECUTE format($$ GRANT USAGE ON SCHEMA %I TO transfer $$, sch);
        EXECUTE format($$ GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA %I TO transfer $$, sch);
        EXECUTE format($$ GRANT SELECT ON ALL TABLES IN SCHEMA %I TO transfer $$, sch);

    END LOOP;
END;

$do$;

```
-  попробуем активировать трансфер из консоли Yandex Cloud
-  и.... снова получим ошибку коннекта к источнику
-  нужно настроить pg_hba

```bash

## внутри виртуалки уже по
ss -tulpn
## разрешенную подсеть смотрим в созданном облаке
sudo sh -c 'echo "host    all             transfer        10.128.0.0/24           md5" >> /etc/postgresql/12/main/pg_hba.conf'
```

- create file /etc/postgresql/12/main/conf.d/dc24.conf
- add next options
```bash
export private_ip="подставляем значение из терраформа"
cat <<EOT  >> dc24.conf
listen_addresses = '$private_ip'
wal_level = logical
EOT
sudo mv dc24.conf /etc/postgresql/12/main/conf.d/dc24.conf
sudo systemctl restart postgresql
sudo apt-get install postgresql-12-wal2json
```

- пробуем повторно активировать
- получаем ошибку
- трансфер не перенес DOMAINS и поэтому не можем создать таблицу
- перенесем домены руками

- найдем пароль dc24_owner в стейте терраформа
```bash
terraform show --json
```

- подключимся в консоли облака к кластеру
- выполним запрос по созданию доменов

```sql
CREATE DOMAIN "OrderNumber" varchar(25) NULL;
CREATE DOMAIN "AccountNumber" varchar(15) NULL;

CREATE DOMAIN "Flag" boolean NOT NULL;
CREATE DOMAIN "NameStyle" boolean NOT NULL;
CREATE DOMAIN "Name" varchar(50) NULL;
CREATE DOMAIN "Phone" varchar(25) NULL;

```

- повторим активацию
- проверим активность в базе и информацию по индексам

```sql
SELECT * FROM pg_stat_activity;

SELECT schemaname, count(1)
FROM pg_indexes
WHERE schemaname not like 'pg_%'
GROUP BY schemaname;

SELECT schemaname, relname, indexrelname,
pg_size_pretty(pg_relation_size(indexrelid)) "Index Size"
FROM pg_stat_all_indexes
WHERE schemaname not like 'pg_%'
ORDER BY "Index Size";
```

- при необходимости можем получить даннные схемы через pg_dump
```bash
pg_dump --section="pre-data"  -h <host> -p 5432 \
-U transfer -d adventureworks > functions.sql

pg_dump --section="pre-data"  -h <host> -p 5432 \
-U transfer -d adventureworks \
|  grep -e '^\(GRANT\|REVOKE\)' > grants.sql
```