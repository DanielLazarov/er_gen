CREATE TABLE teams(
    id SERIAL PRIMARY KEY,
    id_hash TEXT UNIQUE NOT NULL DEFAULT md5(random()::text || now()::text || random()::text),
    name TEXT UNIQUE NOT NULL,
    notes TEXT,
    inserted_at TIMESTAMP NOT NULL DEFAULT now(),
    inserted_by TEXT NOT NULL DEFAULT 'SYSTEM',
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_by  TEXT NOT NULL DEFAULT 'SYSTEM',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE team_members(
    id SERIAL PRIMARY KEY,
    id_hash TEXT UNIQUE NOT NULL DEFAULT md5(random()::text || now()::text || random()::text),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    team_id INTEGER REFERENCES teams(id),
    notes TEXT,
    inserted_at TIMESTAMP NOT NULL DEFAULT now(),
    inserted_by TEXT NOT NULL DEFAULT 'SYSTEM',
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_by  TEXT NOT NULL DEFAULT 'SYSTEM',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);
