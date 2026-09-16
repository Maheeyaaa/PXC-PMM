# PXC Test Cluster Setup and Data Restore Validation

## Objective

Set up a three-node Percona XtraDB Cluster (PXC) 8.4 test cluster and validate restoring a copy of local test data into the cluster.

The validation demonstrates:

- Three-node PXC cluster formation
- Cluster synchronization
- SQL backup of test data
- PXC-compatible restore
- Data replication across all PXC nodes
- Row-count validation after restore

> **Note:** This was performed using local test data. No production database or production credentials were accessed or modified.

---

## Environment

| Component | Details |
|---|---|
| PXC Version | 8.4 |
| Docker Network | `pxc-net` |
| Cluster Name | `pxc-cluster` |
| Nodes | `pxc-node1`, `pxc-node2`, `pxc-node3` |
| Source Database | `pxc_test` |
| Source Table | `test_table` |
| Test Data | 1 row |

---

## 1. PXC Cluster Setup

The existing PXC containers were recreated while preserving their existing Docker data volumes.

Node 2 was selected as the bootstrap node because its recovered Galera state had the highest available sequence number (seqno: 30).

Node 2 was started with:

```bash
docker run -d \
  --name pxc-node2 \
  --network pxc-net \
  -v 34c44223a9fc258154a4f8f40212c806f4a1f247036bbf00300400848dc33d3a:/var/lib/mysql \
  -v cf1995da4bc96e03bb0be8ae3b1babd2c83bdd6f8b79890d10962151210f7335:/var/log/mysql \
  -v "$(pwd)/cert:/cert:ro" \
  -v "$(pwd)/config:/etc/percona-xtradb-cluster.conf.d:ro" \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e XTRABACKUP_PASSWORD=xtrabackup \
  -e CLUSTER_NAME=pxc-cluster \
  percona/percona-xtradb-cluster:8.4 \
  --wsrep-new-cluster
```

Node 1 and Node 3 were then configured as joiners using:

```
CLUSTER_JOIN=pxc-node2
```

The existing data volumes were retained during container recreation.

---

## 2. Cluster Verification

The cluster was checked using the following command:

```bash
docker exec pxc-node3 mysql -uroot -prootpass -e "SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_cluster_status'; SHOW STATUS LIKE 'wsrep_local_state_comment';"
```

Final result:

```
wsrep_cluster_size        3
wsrep_cluster_status      Primary
wsrep_local_state_comment Synced
```

This confirms that all three PXC nodes joined the same Primary component and reached the Synced state.

---

## 3. Source Test Data

The local test database available on the PXC cluster was inspected:

```bash
docker exec pxc-node2 mysql -uroot -prootpass -e "SHOW DATABASES;"
```

The test database was:

```
pxc_test
```

The database contained:

```
test_table
```

The source row count was checked using:

```bash
docker exec pxc-node2 mysql -uroot -prootpass -e "SELECT COUNT(*) AS row_count FROM pxc_test.test_table;"
```

Result:

```
row_count
1
```

---

## 4. Create Database Backup

A SQL backup was created from the test database:

```bash
docker exec pxc-node2 mysqldump -uroot -prootpass --single-transaction pxc_test > pxc_test_backup.sql
```

The generated backup file was verified:

```
pxc_test_backup.sql
Size: 2.9 KB
```

---

## 5. PXC Restore Compatibility Adjustment

The initial restore attempt produced the following PXC strict-mode error:

```
ERROR 1105 (HY000):
Percona-XtraDB-Cluster prohibits use of LOCK TABLE/FLUSH TABLE
<table> WITH READ LOCK/FOR EXPORT with pxc_strict_mode = ENFORCING
```

The dump was therefore cleaned of `LOCK TABLES` and `UNLOCK TABLES` statements:

```bash
sed -e '/^LOCK TABLES/d' -e '/^UNLOCK TABLES/d' \
  pxc_test_backup.sql > pxc_test_backup_pxc.sql
```

The cleaned backup remained approximately 2.9 KB.

---

## 6. Restore Test

A separate target database was created to avoid modifying the original test database:

```bash
docker exec pxc-node2 mysql -uroot -prootpass \
  -e "CREATE DATABASE pxc_restore_test;"
```

The backup was restored into the new database:

```bash
docker exec -i pxc-node2 mysql -uroot -prootpass \
  pxc_restore_test < pxc_test_backup_pxc.sql
```

The restore completed successfully without errors.

---

## 7. Restore Validation

The restored database was checked on node 2:

```bash
docker exec pxc-node2 mysql -uroot -prootpass -e \
"SHOW TABLES FROM pxc_restore_test; SELECT COUNT(*) AS restored_row_count FROM pxc_restore_test.test_table;"
```

Result:

```
Tables_in_pxc_restore_test
test_table

restored_row_count
1
```

The restored data was then verified on the other PXC nodes.

### Node 1

```bash
docker exec pxc-node1 mysql -uroot -prootpass -e \
"SELECT COUNT(*) AS node1_restored_rows FROM pxc_restore_test.test_table;"
```

Result:

```
node1_restored_rows
1
```

### Node 3

```bash
docker exec pxc-node3 mysql -uroot -prootpass -e \
"SELECT COUNT(*) AS node3_restored_rows FROM pxc_restore_test.test_table;"
```

Result:

```
node3_restored_rows
1
```

---

## 8. Validation Summary

| Validation | Result |
|---|---|
| PXC nodes | 3 |
| Cluster status | Primary |
| Node synchronization | Synced |
| Source row count | 1 |
| Backup created | Yes |
| Backup size | 2.9 KB |
| PXC-compatible dump | Yes |
| Restore completed | Yes |
| Node 2 restored rows | 1 |
| Node 1 replicated rows | 1 |
| Node 3 replicated rows | 1 |

---

## 9. Conclusion

A three-node PXC 8.4 test cluster was successfully established using the existing local Docker data volumes.

A local test database was backed up, adjusted for PXC strict-mode compatibility, restored into a separate database, and validated across all three cluster nodes.

The matching row count of 1 on all three nodes confirms that the restored table and its test data were replicated successfully across the PXC cluster.

This validates the basic backup, restore, synchronization, and data-integrity workflow required for the migration proof of concept.

This validation uses local test data and should not be interpreted as a production-data migration. A production migration would additionally require a controlled backup, production-specific compatibility checks, application connection testing, and a documented rollback procedure.