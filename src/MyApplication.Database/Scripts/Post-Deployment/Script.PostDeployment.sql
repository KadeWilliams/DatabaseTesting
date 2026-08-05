/*
 Post-Deployment Script
 Runs after every successful schema deploy (sqlpackage /Action:Publish).
 Referenced scripts execute in order via :r — each one is idempotent, so
 running the same deploy twice (or against a database that already has
 the seed data) is always safe.
*/
:r .\01_SeedStatus.sql
:r .\02_SeedSampleData.sql
