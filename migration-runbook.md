# MariaDB Galera to PXC Migration Runbook

## 1. Objective

Provide a short runbook for migrating an application database from MariaDB Galera to Percona XtraDB Cluster (PXC) using the validated dump/restore approach.

The procedure covers preparation, data migration, validation, cutover, monitoring, and rollback.

This runbook describes the planned production process. The production migration itself was not performed as part of the local POC.

---

## 2. Migration Approach

The migration approaches considered were:

* Logical dump/restore
* Async replication bridge

Dump/restore was selected as the baseline approach for the migration POC because it provides a straightforward and controlled migration path.

The approach was tested in a local 3-node PXC environment.

---

## 3. Pre-Migration Preparation

Before starting the migration:

1. Verify MariaDB Galera source health.
2. Verify the PXC cluster is healthy and all nodes are `Synced`.
3. Confirm schema and storage-engine compatibility.
4. Confirm required databases and tables exist on PXC.
5. Test application connectivity to the PXC environment.
6. Confirm backup and rollback procedures.
7. Agree on validation criteria and cutover timing.
8. Notify the relevant application and operations teams.

---

## 4. Data Migration

Once the migration window begins:

1. Freeze application writes to the MariaDB Galera source.
2. Take the final logical backup.
3. Review the dump for known PXC compatibility requirements.
4. Restore the data into PXC.
5. Monitor the restore for errors.
6. Verify that the PXC cluster remains healthy.

The local POC identified a PXC strict-mode issue with `LOCK TABLES` statements in the dump. The dump was adjusted to make it compatible with the test PXC environment before restoring the data.

---

## 5. Data Validation

After the restore:

### Row Counts

Compare important table row counts between the source and PXC.

```sql
SELECT COUNT(*) FROM database_name.table_name;
```

### Checksums

Use checksums for critical tables to identify data differences that row counts alone may not detect.

```sql
CHECKSUM TABLE database_name.table_name;
```

### PXC Consistency

Verify that the data is available consistently across all PXC nodes.

Also confirm:

```sql
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

Expected cluster state:

* Expected cluster size
* `Primary`
* `Synced`

Do not proceed to cutover if required validation checks fail.

---

## 6. Application Cutover

After final validation:

1. Confirm source writes remain frozen.
2. Complete the final data synchronization.
3. Verify PXC cluster health and data.
4. Switch the application database connection or proxy to PXC.
5. Confirm new connections are reaching PXC.
6. Perform basic application smoke tests.
7. Monitor application and database logs.

Keep the original MariaDB Galera environment available during the stabilization period.

---

## 7. Post-Cutover Monitoring

After switching traffic:

* Monitor PXC cluster health.
* Monitor application and database errors.
* Monitor connections and query performance.
* Verify critical application operations.
* Watch for unexpected replication or cluster issues.

Do not immediately decommission the original environment.

---

## 8. Rollback

Rollback should be considered if critical application or data issues occur after cutover.

1. Stop or restrict application writes.
2. Confirm the original MariaDB Galera environment is available.
3. Identify any writes made to PXC after cutover.
4. Switch application traffic back to MariaDB Galera.
5. Verify application connectivity and critical functionality.
6. Preserve the PXC environment for investigation.
7. Reconcile any required post-cutover writes through a controlled process.
8. Document the issue and corrective actions.

Do not automatically copy post-cutover PXC writes back to the source without validating their impact.

---

## 9. Validation and Rollback Criteria

The migration should proceed only when:

* Required data is present on PXC.
* Row counts match for the required tables.
* Critical table checksums match.
* PXC nodes are healthy and `Synced`.
* Application connectivity has been verified.
* Critical application functionality passes smoke testing.

Rollback should be initiated when critical issues cannot be resolved within the agreed maintenance or stabilization window.

---

## 10. Scope and Limitations

The migration workflow, PXC setup, dump/restore process, and basic replication were tested in a local non-production environment.

The following were not performed as part of the POC:

* Production data migration
* Production traffic cutover
* Production-scale data validation
* Application production cutover testing
* Full rollback rehearsal
* Async replication bridge implementation

A representative staging rehearsal should be completed before production execution.

---

## 11. Related Documentation

The detailed procedures are documented separately:

* `compatibility-report.md` — schema, storage engine, and compatibility checks
* `migration-approach-decision.md` — migration approach comparison
* `migration-test-environment.md` — local migration test environment and results
* `cutover-plan.md` — planned production cutover procedure
* `data-validation-plan.md` — row count and checksum validation
* `rollback-procedure.md` — planned rollback procedure

---

## 12. Summary

The planned migration flow is:

```text
Compatibility checks
        ↓
PXC preparation
        ↓
Freeze source writes
        ↓
Final dump / restore
        ↓
Row count + checksum validation
        ↓
PXC cluster verification
        ↓
Application cutover
        ↓
Smoke testing + monitoring
        ↓
Keep source available for rollback
```

The migration should proceed in a controlled manner, with data validation and rollback readiness confirmed before and after application traffic is moved to PXC.
