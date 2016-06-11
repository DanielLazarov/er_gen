CREATE TABLE sys_users(
    id SERIAL PRIMARY KEY,
    account_id TEXT NOT NULL DEFAULT  md5(now()::text || random()::text || now()::text || random()::text),
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    salt TEXT NOT NULL,

    CONSTRAINT sys_users_username_uconstr UNIQUE(username),
    CONSTRAINT sys_users_account_id_uconstr UNIQUE(account_id)    
);

CREATE TABLE sys_users_sessions(
    id SERIAL PRIMARY KEY,
    session_id TEXT NOT NULL DEFAULT md5(random()::text || now()::text || random()::text),
    sys_user_id INT NOT NULL REFERENCES sys_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    expires_at TIMESTAMP,

    CONSTRAINT sys_users_sessions_session_id_uconstr UNIQUE(session_id)
);
