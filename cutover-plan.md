# Migration Cutover Plan

## 1. Objective

Define the planned cutover procedure for migrating application traffic from the existing MariaDB Galera environment to the Percona XtraDB Cluster (PXC).

The cutover is designed to minimize data inconsistency by freezing source writes, completing the final data synchronization, verifying the PXC cluster, and then switching application traffic.

This document describes a planned production procedure. The cutover itself was not performed as part of the local POC.

---

## 2. Pre-Cutover Preparation

Before starting the cutover:

- Confirm the PXC cluster is healthy.
- Confirm all PXC nodes are `Primary` and `Synced`.
- Complete schema and compatibility validation.
- Confirm the required databases and tables exist on PXC.
- Complete application connectivity testing against the PXC environment.
- Confirm the final backup is available and can be restored if required.
- Confirm the application traffic-switch mechanism.
- Notify relevant teams about the maintenance window.
- Confirm the rollback procedure and decision point.

---

## 3. Freeze Source Writes

At the start of the cutover:

1. Stop or restrict application writes to the MariaDB Galera environment.
2. Keep the source available for read access if required.
3. Confirm that no new writes are being accepted.
4. Record the time at which writes were frozen.

Freezing writes prevents the source data from changing while the final synchronization and validation are performed.

---

## 4. Perform Final Data Synchronization

After writes are frozen:

1. Take the final logical backup from the source.
2. Review the backup for known PXC compatibility requirements.
3. Restore the final data into the PXC environment.
4. Monitor the restore for errors.
5. Confirm that the restore completes successfully.

The final synchronization method should follow the validated dump/restore procedure.

---

## 5. Verify PXC Cluster

Before switching application traffic, verify:

- `wsrep_cluster_size` is the expected number of nodes.
- `wsrep_cluster_status` is `Primary`.
- `wsrep_local_state_comment` is `Synced` on all nodes.
- No replication or cluster errors are present.
- Required databases and tables are available.

Example verification:

```bash
docker exec pxc-node1 mysql -uroot -p \
  -e "SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_cluster_status'; SHOW STATUS LIKE 'wsrep_local_state_comment';"
```

Production credentials should be supplied securely rather than included in commands or documentation.

---

## 6. Validate Data

Before traffic is switched:

1. Verify that required tables exist.
2. Compare critical row counts with the source.
3. Validate important application data.
4. Check for restore errors.
5. Confirm that the data is available consistently across the PXC nodes.

The validation criteria should be agreed upon before the migration begins.

---

## 7. Switch Application Traffic

After the PXC cluster and data have been validated:

1. Update the application database connection or proxy configuration to point to PXC.
2. Enable application traffic to the PXC environment.
3. Confirm that new application connections are reaching PXC.
4. Perform basic application functionality checks.
5. Monitor database and application logs for errors.

The source environment should remain available during the initial monitoring period to support rollback if required.

---

## 8. Post-Cutover Monitoring

After traffic is switched:

* Monitor PXC cluster health.
* Monitor application errors.
* Monitor database connections.
* Monitor query performance.
* Verify critical application operations.
* Check for unexpected replication or cluster errors.
* Continue monitoring for the agreed stabilization period.

Do not immediately decommission the source environment.

---

## 9. Rollback Plan

Rollback should be considered if critical application or data issues are discovered after the traffic switch.

### Rollback procedure

1. Stop or restrict application writes.
2. Switch application traffic back to the original MariaDB Galera environment.
3. Verify source database availability.
4. Confirm application connectivity.
5. Validate critical application functions.
6. Preserve the PXC environment for investigation.
7. Document the failure and corrective actions.

Rollback should only be performed after confirming that the source environment is in a usable state and any writes made after cutover have been accounted for before rollback.

---

## 10. Cutover Sequence Summary

```text
Pre-cutover validation
        ↓
Freeze source writes
        ↓
Final backup / data synchronization
        ↓
Verify PXC cluster
        ↓
Validate critical data
        ↓
Switch application traffic to PXC
        ↓
Application smoke testing
        ↓
Monitor PXC and application
        ↓
Keep source available for rollback
```

---

## 11. Cutover Checklist

| Step                                  | Status  |
| -------------------------------------- | ------- |
| PXC cluster health verified            | Planned |
| Schema compatibility verified          | Planned |
| Application connectivity verified      | Planned |
| Source writes frozen                   | Planned |
| Final backup completed                 | Planned |
| Final data synchronization completed   | Planned |
| PXC cluster verified                   | Planned |
| Critical data validated                | Planned |
| Application traffic switched           | Planned |
| Application smoke test completed       | Planned |
| Post-cutover monitoring started        | Planned |
| Rollback readiness confirmed           | Planned |

---

## 12. Scope and Limitations

This document defines the planned cutover procedure.

The actual production cutover, traffic switch, production data synchronization, and rollback procedure were not executed as part of the local POC.

The procedure should be rehearsed in a representative staging environment before production execution.

---

## 13. Conclusion

The planned cutover follows a controlled sequence: freeze source writes, perform the final data synchronization, verify PXC cluster and data health, switch application traffic, and monitor the new environment.

Keeping the source environment available during the stabilization period provides an option for rollback if a critical issue is identified.

The exact timing, validation thresholds, traffic-switch mechanism, and rollback decision criteria should be finalized with the application and operations teams before production execution.