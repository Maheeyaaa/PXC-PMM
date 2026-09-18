# Migration Approach Decision: Dump/Restore vs Async Replication Bridge

## 1. Objective

Evaluate two possible approaches for migrating data from the existing MariaDB Galera environment to a Percona XtraDB Cluster (PXC) environment:

1. Logical dump/restore
2. Asynchronous replication bridge

The objective is to compare the approaches based on compatibility, operational complexity, downtime, data consistency, rollback, and suitability for the MariaDB Galera → PXC migration.

---

## 2. Migration Context

The target environment is a three-node Percona XtraDB Cluster (PXC).

The migration must account for differences between the existing MariaDB Galera setup and the target PXC environment, including database compatibility, replication behavior, cluster configuration, application connectivity, and migration downtime.

The two approaches were evaluated as follows:

- **Dump/restore:** Create a logical backup of the source databases and restore the data into the PXC environment.
- **Async replication bridge:** Use an intermediate asynchronous replication relationship to keep the target synchronized with the source before final cutover.

---

## 3. Approach 1 — Logical Dump/Restore

### Process

1. Validate source database compatibility with PXC.
2. Take a consistent logical backup of the required databases.
3. Review and adjust the dump for PXC compatibility where required.
4. Restore the backup into the PXC cluster.
5. Validate tables, row counts, indexes, and application functionality.
6. Schedule the final cutover.
7. Stop or restrict writes on the source.
8. Perform the final backup/restore if required.
9. Redirect the application to PXC.
10. Monitor the new environment after cutover.

### Advantages

- Straightforward and well understood.
- Does not require maintaining a replication bridge between different cluster environments.
- Provides a clean logical representation of the source data.
- Allows compatibility issues to be identified before the final migration.
- Easier to document and reproduce as a migration procedure.
- Suitable when the migration can tolerate a controlled maintenance window.

### Limitations

- Requires a backup and restore operation.
- Large databases can require significant restore time.
- Final cutover may require a write-freeze or maintenance window.
- Dump contents may require adjustments for PXC strict-mode or compatibility requirements.

---

## 4. Approach 2 — Async Replication Bridge

### Process

1. Validate whether the source and target database versions and configurations support the required replication method.
2. Configure the PXC environment as the replication target.
3. Establish asynchronous replication from the source environment.
4. Allow the target to catch up with the source.
5. Monitor replication lag and errors.
6. Schedule the final cutover.
7. Stop or restrict writes on the source.
8. Wait for the target to reach the required replication position.
9. Validate the target data.
10. Redirect the application to PXC.

### Advantages

- Can reduce the final migration downtime because most data can be transferred before cutover.
- Allows the target environment to remain synchronized while migration preparation is performed.
- Provides an opportunity to validate the target before the final switch.

### Limitations

- More complex to configure and operate.
- Requires compatibility between the source replication format and target environment.
- Requires monitoring of replication state and lag.
- Introduces an additional replication path that must be maintained during migration.
- Failure or incompatibility in the replication bridge can delay the migration.
- Rollback and replication-position management require additional planning.

---

## 5. Comparison Matrix

| Criteria | Logical Dump/Restore | Async Replication Bridge |
|---|---|---|
| Setup complexity | Lower | Higher |
| Migration procedure | Straightforward | More involved |
| Cross-environment compatibility | Validated during dump/restore testing | Depends on replication compatibility |
| Downtime | Requires controlled cutover window | Can reduce final cutover window |
| Operational overhead | Lower | Higher |
| Replication monitoring | Not required during migration | Required |
| Data synchronization before cutover | No | Yes |
| Rollback planning | Relatively straightforward | Requires replication-position considerations |
| Troubleshooting | Easier to isolate | More components involved |
| Suitability for this POC | Suitable | Requires additional validation |

---

## 6. Compatibility Considerations

The migration should verify:

- MariaDB and PXC/MySQL version compatibility.
- Supported storage engines.
- Schema and SQL feature compatibility.
- Character sets and collations.
- Stored procedures, triggers, and events.
- Users, privileges, and authentication requirements.
- Application connection settings.
- Proxy/load-balancer configuration.
- PXC strict-mode restrictions.
- Backup and restore behavior.

During the PXC restore validation POC, a logical dump initially encountered a PXC strict-mode restriction related to table locking statements. Removing the incompatible `LOCK TABLES` and `UNLOCK TABLES` statements allowed the test backup to be restored successfully.

This demonstrates that logical dump/restore provides an opportunity to identify and correct compatibility issues before migration.

---

## 7. POC / Test Plan

The migration approach should be validated using a non-production test environment.

### Test activities

1. Create a representative test database.
2. Create a logical backup from the source/test environment.
3. Review the generated SQL for compatibility issues.
4. Restore the backup into a PXC test database.
5. Validate table structure and row counts.
6. Verify that the restored data is replicated across all PXC nodes.
7. Test application connectivity against the restored database.
8. Record any compatibility adjustments required.
9. Document the final cutover and rollback procedure.

The PXC test cluster validation demonstrated successful restoration of test data and replication of the restored data across all three PXC nodes.

---

## 8. Proposed Cutover Procedure

### Before cutover

- Confirm PXC cluster health.
- Confirm all nodes are `Primary` and `Synced`.
- Complete schema and compatibility validation.
- Take the final source backup.
- Validate the backup.
- Prepare application connection configuration.
- Define the maintenance window.
- Confirm rollback requirements.

### During cutover

1. Stop or restrict writes to the source database.
2. Perform the final data synchronization/restore.
3. Validate the target database.
4. Confirm PXC cluster health.
5. Update the application connection configuration.
6. Enable application traffic to PXC.
7. Monitor application and database behavior.

### After cutover

- Monitor cluster health.
- Monitor application errors.
- Verify critical tables and records.
- Monitor database performance.
- Keep the source environment available according to the rollback plan.

---

## 9. Rollback Procedure

If validation or application testing identifies a critical issue after cutover:

1. Stop or restrict application writes.
2. Redirect application traffic back to the original source environment.
3. Verify source database availability.
4. Validate application connectivity.
5. Investigate the issue in the PXC environment.
6. Correct the migration issue before attempting another cutover.

The exact rollback procedure should be finalized after application-specific testing and confirmation of the acceptable rollback window.

---

## 10. Decision

For the current MariaDB Galera → PXC migration POC, **logical dump/restore is selected as the baseline migration approach**.

The decision is based on the ability to validate schema and data compatibility during the migration process, lower operational complexity, and the successful local PXC restore validation.

An asynchronous replication bridge may be evaluated separately if the migration requires a substantially shorter final downtime window and the required replication compatibility can be demonstrated.

---

## 11. Conclusion

Both logical dump/restore and asynchronous replication can be used as migration strategies, but they have different operational requirements.

The current POC uses logical dump/restore as the baseline because it provides a controlled migration process and allows compatibility issues to be identified and addressed before cutover.

The approach should be validated further with representative application workloads, production-sized data volumes, backup/restore timing, and a complete cutover and rollback rehearsal before being used for an actual production migration.