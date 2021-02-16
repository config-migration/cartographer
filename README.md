# Cartographer

Map similar utilities by inspecting system calls. See 
[sycall](http://man7.org/linux/man-pages/man2/syscalls.2.html) reference.


## Dependencies

| Name   | Version    | URL                                | Description                   |
| ------ | ---------- | ---------------------------------- | ----------------------------- |
| Python |      3.8.7 | https://www.python.org/            | Language.                     |
| Pipenv | 2020.11.15 | https://pipenv.pypa.io/en/latest/  | Python dependency management. |
| MySQL  |     8.0.18 | https://www.mysql.com/             | Database.                     | 
| Docker |    20.10.2 | https://www.docker.com/            | Container management.         |


## Setting up for development

Configure a Python environment with.

```
$ pipenv sync --keep-outdated
```

If you get an error related to cryptography on macOS using homebrew, try

```
$ brew install openssl
$ export LDFLAGS="-L$(brew --prefix openssl@1.1)/lib"
$ export CFLAGS="-I$(brew --prefix openssl@1.1)/include"
$ pipenv sync --keep-outdated
```

Start services with Docker compose.

```
$ docker-compose up --detach
```

Grab a database backup from releases and restore it (see [Database](#database) 
for additional details).

```
$ gunzip -c path/to/backup.sql | pv -btra | docker exec -i cartographer.mysql mysql -C --max-allowed-packet=1G cartographer
```

Show help to see where to get started.

```
$ python cartographer.py --help
```


## Database

To back up the database, run

```
$ docker exec -it cartographer.mysql mysqldump -Cceq --single-transaction --max-allowed-packet=1G cartographer | pv -btra | gzip -9 -c > computed/backups/yyyy-MM-ddTHH:mm.sql.gz
```

To restore the database, run

```
$ gunzip -c computed/backups/yyyy-MM-ddTHH:mm.sql | pv -btra | docker exec -i cartographer.mysql mysql -C --max-allowed-packet=1G cartographer
```

The use of `pv` ([pipe viewer](http://www.ivarch.com/programs/pv.shtml)) and/or 
`gzip` is optional but recommended.

### Importing Records

It may be useful to import traces from an external source and merge them into
the local database. For example, this may be desired to integrate traces 
collected on a separate build server. 

The simplest method for importing records is by doing a backup and restore.
Note that this _*WILL NOT*_ preserve unique executables in the database.
After restoring the records to be imported to the local database `backup`, 
run:

```sql
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;

    SELECT MAX(id) INTO @max_executable_id FROM cartographer.executables;
    UPDATE backup.executables SET id = id + @max_executable_id ORDER BY id DESC;

    SELECT MAX(id) INTO @max_strace_id FROM cartographer.straces;
    UPDATE backup.straces SET id = id + @max_strace_id ORDER BY id DESC;
    
    INSERT INTO cartographer.executables SELECT * FROM backukp.executables;
    INSERT INTO cartographer.straces SELECT * FROM backup.straces;

COMMIT;
``` 
