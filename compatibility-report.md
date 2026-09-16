# DEV-810 — Compatibility Analysis Findings

## 1. Environment Validation

The existing MariaDB test environment was inspected to validate compatibility considerations for migration to Percona XtraDB Cluster (PXC) 8.4.

| Item                 | Observed Result                        | Assessment                          |
| -------------------- | -------------------------------------- | ----------------------------------- |
| Source Database      | MariaDB 11.4.13                        | Verified                            |
| Target Database      | Percona XtraDB Cluster 8.4 / MySQL 8.4 | Target |
| Application Database | `replication_test`                     | Verified                            |
| Tables               | 1 base table (`test_data`)             | No structural complexity identified |

## 2. Schema Compatibility

The `replication_test` database contains a single base table:

* `test_data`
* Columns: `id` (`INT`), `message` (`VARCHAR(100)`), `created_at` (`TIMESTAMP`)
* No views were found.
* No stored procedures or functions were found.
* No triggers were found.

The observed data types and basic table structure do not show an obvious compatibility issue with the PXC target.

**Assessment:** No immediate schema incompatibility identified in the tested database. Full production validation should still be performed before migration.

## 3. Storage Engine Compatibility

The `test_data` table uses:

```text
ENGINE = InnoDB
```

No non-InnoDB application tables were identified in the tested database.

**Assessment:** No storage-engine conversion is required for the observed dataset. InnoDB is the expected storage engine for PXC.

## 4. Character Set and Collation

The `test_data` table uses:

```text
Character Set: utf8mb4
Collation: utf8mb4_uca1400_ai_ci
```

The `message` column also uses `utf8mb4` with the same collation.

The utf8mb4 character set is commonly supported by both MariaDB and MySQL/PXC, but the MariaDB utf8mb4_uca1400_ai_ci collation requires explicit compatibility validation and may require conversion before migration

**Risk:** Schema objects using this collation may require conversion to a supported target collation.

**Recommendation:** Inventory all production columns, tables, views and routines using MariaDB-specific collations and validate or convert them before migration. A suitable target collation should be selected based on the application's comparison and sorting requirements.

## 5. Authentication and Users

The following accounts were observed in the MariaDB test environment:

* `root@localhost`
* `root@%`
* `mariadb.sys@localhost`
* `healthcheck@127.0.0.1`
* `healthcheck@::1`
* `healthcheck@localhost`
* `replication_user@%`

All observed accounts use:

```text
mysql_native_password
```

PXC 8.4 uses MySQL 8.4 authentication behavior, where `mysql_native_password` is disabled by default.

**Risk:** Existing application, health-check, administrative, or replication-related accounts using `mysql_native_password` require authentication compatibility testing before migration.

**Recommendation:** Inventory application users and evaluate migration to `caching_sha2_password` where supported. If legacy authentication must temporarily be retained, explicitly plan and validate the required PXC configuration.

## 6. Replication User Privileges

The observed replication account has:

```text
GRANT REPLICATION SLAVE ON *.* TO `replication_user`@`%`
```

No additional application-level privileges were observed for this account.

**Assessment:** The observed privilege scope is limited to replication. However, the account's authentication method must still be validated against the target PXC configuration.

## 7. Proxy Layer

No HAProxy, ProxySQL, or MaxScale database proxy was detected in the available local test environment.

The only container matching a proxy-related name was an Envoy container associated with a separate Consul test and was not part of the database environment.

**Assessment:** Proxy failover and health-check behavior could not be validated from the current lab.

**Recommendation:** Before production migration, identify the actual application database routing/proxy layer and validate:

* PXC node health checks
* Primary/writer selection
* Node failure handling
* Connection retry behavior
* Read/write routing
* Application connection strings

## 8. Compatibility Summary

The tested MariaDB environment has a simple schema and uses InnoDB exclusively, so no immediate storage-engine or basic schema incompatibility was identified.

Two concrete migration risks were identified:

1. **Collation compatibility:** `utf8mb4_uca1400_ai_ci` requires validation or conversion for the MySQL/PXC 8.4 target.
2. **Authentication compatibility:** Existing accounts use `mysql_native_password`, which requires migration planning because PXC 8.4 disables this authentication plugin by default.

The local environment did not contain an identifiable database proxy, so production proxy/failover compatibility remains to be validated.

## 9. Recommended Pre-Migration Checks

Before proceeding with a production MariaDB Galera → PXC migration:

1. Inventory all production schemas and database objects.
2. Identify MariaDB-specific syntax, functions, collations and data types.
3. Identify and convert any non-InnoDB tables.
4. Validate all `utf8mb4` collations against the PXC 8.4 target.
5. Inventory database users and authentication plugins.
6. Test application users with the target PXC authentication configuration.
7. Document the actual production proxy/routing layer.
8. Test PXC node health checks and failover behavior.
9. Perform application-level validation after migration.
10. Take a verified backup before making production changes.

## Conclusion

The compatibility review of the available MariaDB 11.4.13 test environment identified no immediate issues with the basic table structure or InnoDB storage engine. However, collation and authentication differences between MariaDB and the MySQL-based PXC 8.4 target require explicit validation before migration.

The findings should be treated as a compatibility baseline for the test environment; production schemas, users and proxy configuration must be validated separately before executing the migration.
