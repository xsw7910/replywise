# Database session factory — implementation deferred to Phase 1 (auth) / Phase 3 (usage).
#
# Plan §5.1: local dev uses SQLite, production uses PostgreSQL + asyncpg.
# When implemented:
#   - engine created from DATABASE_URL in Settings
#   - async session factory exposed as get_db() FastAPI dependency
#   - SQLite dev init: PRAGMA journal_mode=WAL; busy_timeout=10000; synchronous=NORMAL
