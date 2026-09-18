# Migration Test Environment Validation

## 1. Objective

Test the core dump/restore portion of the proposed MariaDB Galera → PXC migration procedure in a local, non-production environment.

The test focuses on logical backup, PXC compatibility, restore, and replication validation.

No production database or production credentials were used.

---

## 2. Test Environment

- Target: Percona XtraDB Cluster (PXC) 8.4
- Cluster: 3 nodes
- Network: `pxc-net`
- Nodes: `pxc-node1`, `pxc-node2`, `pxc-node3`
- Source test database: `pxc_test`
- Target test database: `pxc_restore_test`
- Source test table: `test_table`

---

## 3. Tested Migration Steps

### Step 1 — Verify PXC Cluster

The three-node PXC cluster was started and verified.

The cluster showed:

```text
wsrep_cluster_size 3
wsrep_cluster_status Primary
wsrep_local_state_comment Synced
```

This confirmed that all three PXC nodes were members of the Primary cluster and were in the Synced state.

---

### Step 2 — Inspect Source Test Data

The local test database was inspected before creating the backup.

Source database:

```text
pxc_test
```

Source table:

```text
test_table
```

Source row count:

```text
1
```

---

### Step 3 — Create Logical Backup

A logical backup of the test database was created using `mysqldump`:

```bash
docker exec pxc-node2 mysqldump -uroot -prootpass --single-transaction pxc_test > pxc_test_backup.sql
```

The resulting backup file was approximately 2.9 KB.

---

### Step 4 — Attempt Initial Restore

A separate target database named `pxc_restore_test` was created.

The initial restore attempt produced a PXC strict-mode error related to table locking statements:

```text
ERROR 1105 (HY000):
Percona-XtraDB-Cluster prohibits use of LOCK TABLE/FLUSH TABLE <table>
WITH READ LOCK/FOR EXPORT with pxc_strict_mode = ENFORCING
```

This identified a compatibility issue that needed to be addressed before the restore could proceed.

---

### Step 5 — Adjust Backup for PXC Compatibility

The incompatible `LOCK TABLES` and `UNLOCK TABLES` statements were removed from the logical backup:

```bash
sed -e '/^LOCK TABLES/d' -e '/^UNLOCK TABLES/d' \
  pxc_test_backup.sql > pxc_test_backup_pxc.sql
```

The adjusted backup was approximately 2.9 KB.

---

### Step 6 — Restore into Target Database

The adjusted backup was restored into the separate `pxc_restore_test` database:

```bash
docker exec -i pxc-node2 mysql -uroot -prootpass pxc_restore_test < pxc_test_backup_pxc.sql
```

The restore completed successfully.

---

### Step 7 — Validate Restored Data

The restored database was checked on the bootstrap node.

Result:

```text
Table: test_table
Row count: 1
```

The restored row count matched the original test data.

---

### Step 8 — Verify Replication Across PXC Nodes

The restored table was checked on the other PXC nodes.

Results:

| Node        | Restored Rows |
| ----------- | ------------: |
| `pxc-node1` |             1 |
| `pxc-node2` |             1 |
| `pxc-node3` |             1 |

The matching row counts confirmed that the restored data was replicated across all three PXC nodes.

---

## 4. Test Results

| Test                                 | Result           |
| ------------------------------------ | ---------------- |
| Three-node PXC cluster               | Passed           |
| Cluster status: Primary              | Passed           |
| All nodes: Synced                    | Passed           |
| Logical backup                       | Passed           |
| Initial restore compatibility check  | Issue identified |
| PXC compatibility adjustment         | Passed           |
| Restore into target database         | Passed           |
| Restored data validation             | Passed           |
| Replication across all three nodes   | Passed           |

---

## 5. Issues Identified

The initial logical restore was blocked by a PXC strict-mode restriction involving table locking statements.

The issue was resolved in the test by removing the `LOCK TABLES` and `UNLOCK TABLES` statements from the logical backup before restoring it.

This demonstrates that the dump should be reviewed for PXC compatibility before an actual migration.

---

## 6. Scope and Limitations

The following activities were **not** tested as part of this local POC:

* Production database migration
* Production-sized data migration
* Application cutover
* Application connection testing
* Full migration downtime measurement
* Production traffic validation
* Complete rollback rehearsal
* Async replication bridge setup

These activities would require separate testing before a production migration.

---

## 7. Conclusion

The core dump/restore portion of the proposed MariaDB Galera → PXC migration procedure was successfully tested in a local non-production PXC environment.

The test identified a PXC strict-mode compatibility issue, demonstrated the required dump adjustment, successfully restored the test data, and verified replication of the restored data across all three PXC nodes.

The results provide a practical validation of the basic dump/restore workflow. Further application-level, production-scale, cutover, and rollback testing would be required before using the procedure for an actual production migration.