# Migration Rollback Procedure

## 1. Objective

Define the rollback procedure to be followed if critical application or data issues are discovered after migrating from MariaDB Galera to Percona XtraDB Cluster (PXC).

The rollback procedure is designed to return application traffic to the original MariaDB Galera environment while preserving the PXC environment for investigation.

This document describes a planned production procedure. A production rollback was not performed as part of the local POC.

---

## 2. Rollback Triggers

Rollback may be considered if critical issues are identified after switching application traffic to PXC, such as:

* Data inconsistencies that cannot be resolved within the maintenance window.
* Critical application functionality failing.
* Unexpected database errors affecting application operations.
* Serious performance or connectivity issues.
* PXC cluster instability affecting application availability.
* Any other issue that prevents the application from operating reliably on PXC.

The rollback decision should be made by the responsible application and operations teams based on agreed criteria.

---

## 3. Pre-Rollback Checks

Before starting the rollback:

1. Confirm that the original MariaDB Galera environment is available.
2. Confirm that the source database is in a usable state.
3. Identify whether any writes occurred on PXC after the traffic switch.
4. Determine whether those writes need to be preserved or reconciled.
5. Notify the relevant application and operations teams.
6. Record the time and reason for initiating the rollback.

Rollback should not proceed until the impact of post-cutover writes has been assessed.

---

## 4. Stop Application Writes

At the start of the rollback:

1. Stop or restrict application writes.
2. Prevent new writes from reaching the PXC cluster.
3. Keep the PXC environment available for investigation.
4. Record the point at which application writes were stopped.

This prevents additional data changes while traffic is being switched back to the original environment.

---

## 5. Switch Traffic Back to MariaDB Galera

After writes have been stopped:

1. Update the application database connection or proxy configuration to point back to MariaDB Galera.
2. Enable application traffic to the original environment.
3. Confirm that new application connections are reaching MariaDB Galera.
4. Perform basic application functionality checks.
5. Monitor application and database logs for errors.

The traffic switch should be performed using the same controlled mechanism used during the original cutover.

---

## 6. Validate the Original Environment

After traffic is restored:

* Confirm MariaDB Galera cluster health.
* Verify database connectivity.
* Verify critical application functionality.
* Check critical table row counts where required.
* Review application and database logs.
* Confirm that the application is operating normally.

Any data written to PXC after the original cutover should be reviewed separately before being considered for reconciliation with the source.

---

## 7. Preserve the PXC Environment

After rollback:

1. Keep the PXC cluster available for investigation.
2. Preserve relevant logs and error information.
3. Do not immediately delete or reinitialize the PXC environment.
4. Identify the root cause of the issue.
5. Document any data differences between PXC and MariaDB Galera.

The PXC environment should remain available until the investigation and data reconciliation requirements are understood.

---

## 8. Handling Post-Cutover Writes

If application writes occurred on PXC before rollback:

1. Identify the affected data.
2. Determine whether the writes are valid and need to be preserved.
3. Compare the affected data with the MariaDB Galera source.
4. Define a controlled reconciliation procedure.
5. Apply any required changes to the source only after validation.
6. Re-run data validation after reconciliation.

Post-cutover writes should not be copied back automatically without confirming their correctness and impact.

---

## 9. Post-Rollback Monitoring

After traffic has been returned to MariaDB Galera:

* Monitor application errors.
* Monitor database connectivity.
* Monitor query performance.
* Verify critical application operations.
* Monitor the MariaDB Galera cluster.
* Continue monitoring until the environment is stable.

The PXC environment should remain isolated from application traffic until the migration issue has been resolved.

---

## 10. Rollback Checklist

| Step                                    | Status  |
| --------------------------------------- | ------- |
| Rollback trigger identified             | Planned |
| MariaDB Galera availability confirmed   | Planned |
| Post-cutover writes assessed            | Planned |
| Application writes stopped              | Planned |
| Traffic switched back to MariaDB Galera | Planned |
| Application connectivity verified       | Planned |
| Critical functionality verified         | Planned |
| PXC environment preserved               | Planned |
| Data differences investigated           | Planned |
| Post-rollback monitoring started        | Planned |
| Root cause documented                   | Planned |

---

## 11. Scope and Limitations

This document defines the planned rollback procedure for the MariaDB Galera to PXC migration.

The rollback procedure was not executed against a production environment as part of the local POC.

A rollback rehearsal should be performed in a representative staging environment before production migration to verify the traffic-switch mechanism, application behavior, data reconciliation process, and recovery steps.

---

## 12. Conclusion

The rollback procedure provides a controlled way to return application traffic to MariaDB Galera if critical issues occur after migration to PXC.

The key steps are to stop writes, assess post-cutover changes, switch traffic back to the original environment, validate application and database health, and preserve the PXC environment for investigation.

The rollback decision criteria and data reconciliation process should be finalized with the application and operations teams before production execution.
