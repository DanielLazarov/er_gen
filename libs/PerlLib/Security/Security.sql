CREATE TABLE sys_users(
    id SERIAL PRIMARY KEY,
    account_id TEXT UNIQUE NOT NULL DEFAULT  md5(now()::text || random()::text || now()::text || random()::text),
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    salt TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
);

CREATE TABLE sys_users_sessions(
    id SERIAL PRIMARY KEY,
    session_id TEXT UNIQUE NOT NULL DEFAULT md5(random()::text || now()::text || random()::text),
    sys_user_id INT NOT NULL REFERENCES sys_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    expires_at TIMESTAMP
);
