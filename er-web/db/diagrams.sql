CREATE TABLE diagrams (
    id SERIAL PRIMARY KEY,
    diagram_id TEXT UNIQUE NOT NULL DEFAULT md5(now()::text || random()::text),
    name TEXT NOT NULL,
    schema_json JSONB NOT NULL,
    sys_user_session_id INTEGER NOT NULL REFERENCES sys_users_sessions(id),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX ON diagrams(name) WHERE is_deleted IS FALSE;

CREATE TABLE last_diagram_by_session (
    id SERIAL PRIMARY KEY,
    sys_user_session_id INT UNIQUE NOT NULL REFERENCES sys_users_sessions(id), 
    diagram_id INT REFERENCES diagrams(id)
);
