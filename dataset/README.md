# Adventureworks from SQL Server

Commands:

```
psql -c "CREATE DATABASE \"adventureworks\";"
psql -d adventureworks < install.sql
```

To see list of tables

```
\c "adventureworks"
\dt (humanresources|person|production|purchasing|sales).*
```


Credits: [lorint-AdventureWorks for Postgres](https://github.com/lorint/AdventureWorks-for-Postgres)
