# Data Validation Plan

## 1. Objective

Define the validation steps to confirm that data remains complete and consistent after migrating from MariaDB Galera to Percona XtraDB Cluster (PXC).

The validation will use row counts and checksums as complementary methods to identify missing, extra, or modified data.

---

## 2. Validation Approach

Data validation will be performed at multiple stages:

1. Before migration, record baseline row counts and checksums from the source.
2. After restoring the data to PXC, run the same checks against the migrated data.
3. Compare the source and PXC results.
4. Perform final validation before switching application traffic to PXC.

Both row counts and checksums should match for the migration to be considered successful.

---

## 3. Row Count Validation

For each required table:

1. Record the row count on the MariaDB Galera source.
2. Record the row count on the PXC cluster after migration.
3. Compare the results.
4. Investigate any differences before continuing with the migration.

Example:

```sql
SELECT COUNT(*) FROM database_name.table_name;
```

For large databases, validation can initially focus on critical application tables and then be expanded to all required tables.

### Pass Criteria

* Source and PXC row counts match.
* No unexpected tables or missing tables are identified.
* Any differences are investigated and resolved before cutover.

---

## 4. Checksum Validation

Row counts alone cannot detect changes where rows have been modified without changing the total number of rows.

Checksums will therefore be used as an additional validation method for critical tables.

A checksum can be generated from the table data and compared between the source and PXC.

Example approach:

```sql
CHECKSUM TABLE database_name.table_name;
```

For tables where this method is not suitable, an alternative deterministic checksum approach can be used based on the relevant columns and primary key ordering.

### Pass Criteria

* Source and PXC checksums match for the validated tables.
* Any checksum mismatch is investigated before cutover.
* The cause of any mismatch is documented.

---

## 5. PXC Node Consistency

After restoring the data, verify that the migrated data is available consistently across all PXC nodes.

For critical tables:

1. Check the row count on PXC node 1.
2. Check the row count on PXC node 2.
3. Check the row count on PXC node 3.
4. Confirm that the results are consistent.

Also verify the PXC cluster state:

```sql
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

Expected values:

* `wsrep_cluster_size` = expected number of nodes
* `wsrep_cluster_status` = `Primary`
* `wsrep_local_state_comment` = `Synced`

---

## 6. Validation Timing

Validation should be performed at the following points:

### Before Migration

* Record source row counts.
* Record source checksums for selected critical tables.
* Record the list of tables being migrated.

### After Data Restore

* Compare row counts between source and PXC.
* Compare checksums for critical tables.
* Verify PXC node consistency.

### Before Cutover

* Repeat validation after the final synchronization.
* Confirm there are no unresolved differences.
* Confirm the PXC cluster is healthy and synchronized.

---

## 7. Handling Validation Failures

If row counts or checksums do not match:

1. Do not switch application traffic to PXC.
2. Identify the affected database and table.
3. Compare the source and PXC data.
4. Check the migration and restore logs for errors.
5. Re-sync or restore the affected data if required.
6. Repeat the validation.
7. Document the cause and resolution.

The migration should proceed to cutover only after the required validation checks pass.

---

## 8. Validation Checklist

| Validation                                | Status  |
| ----------------------------------------- | ------- |
| Source table list recorded                | Planned |
| Baseline row counts recorded              | Planned |
| Baseline checksums recorded               | Planned |
| Data restored to PXC                      | Planned |
| PXC row counts compared                   | Planned |
| Critical table checksums compared         | Planned |
| PXC node consistency verified             | Planned |
| Validation differences investigated       | Planned |
| Final validation completed before cutover | Planned |

---

## 9. Scope and Limitations

This document defines the planned data validation procedure for the MariaDB Galera to PXC migration.

The validation process has not been executed against production data. The previously performed local PXC POC verified basic data restoration and replication, but did not represent a production-scale validation exercise.

Production validation should use the actual migration dataset and agreed validation criteria before application traffic is switched to PXC.

---

## 10. Conclusion

Row counts provide a basic completeness check, while checksums provide an additional way to detect data differences that row counts may not identify.

Using both methods, together with PXC node consistency and cluster health checks, provides a structured validation process before application traffic is moved to the new PXC environment.
