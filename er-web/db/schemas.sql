CREATE TABLE schemas (
    id SERIAL PRIMARY KEY,
    schema_id TEXT UNIQUE NOT NULL DEFAULT md5(now()::text || random()::text),
    name TEXT NOT NULL,
    schema_json JSONB NOT NULL,
    sys_user_session_id INTEGER NOT NULL REFERENCES sys_users_sessions(id)
);
