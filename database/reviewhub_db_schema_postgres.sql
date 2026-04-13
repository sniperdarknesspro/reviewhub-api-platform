
BEGIN;

DROP VIEW IF EXISTS v_api_visible_reviews CASCADE;

DROP TABLE IF EXISTS api_request_logs CASCADE;
DROP TABLE IF EXISTS target_aggregates CASCADE;
DROP TABLE IF EXISTS data_ingestion_jobs CASCADE;
DROP TABLE IF EXISTS moderation_events CASCADE;
DROP TABLE IF EXISTS review_ai_results CASCADE;
DROP TABLE IF EXISTS review_media CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS partner_target_visibility_rules CASCADE;
DROP TABLE IF EXISTS review_targets CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS partner_subscriptions CASCADE;
DROP TABLE IF EXISTS plan_domain_permissions CASCADE;
DROP TABLE IF EXISTS service_plans CASCADE;
DROP TABLE IF EXISTS partner_domains CASCADE;
DROP TABLE IF EXISTS app_users CASCADE;
DROP TABLE IF EXISTS partners CASCADE;
DROP TABLE IF EXISTS domains CASCADE;

DROP TYPE IF EXISTS job_status CASCADE;
DROP TYPE IF EXISTS request_outcome CASCADE;
DROP TYPE IF EXISTS moderation_status CASCADE;
DROP TYPE IF EXISTS visibility_scope CASCADE;
DROP TYPE IF EXISTS ingestion_source CASCADE;
DROP TYPE IF EXISTS api_key_status CASCADE;
DROP TYPE IF EXISTS api_key_type CASCADE;
DROP TYPE IF EXISTS subscription_status CASCADE;
DROP TYPE IF EXISTS plan_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS partner_status CASCADE;

CREATE TYPE partner_status AS ENUM ('PENDING', 'ACTIVE', 'LOCKED', 'REJECTED');
CREATE TYPE user_role AS ENUM ('ADMIN', 'STAFF', 'PARTNER');
CREATE TYPE plan_status AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TYPE subscription_status AS ENUM ('TRIAL', 'ACTIVE', 'SUSPENDED', 'EXPIRED', 'CANCELLED');
CREATE TYPE api_key_type AS ENUM ('SANDBOX', 'LIVE');
CREATE TYPE api_key_status AS ENUM ('ACTIVE', 'REVOKED', 'EXPIRED');
CREATE TYPE ingestion_source AS ENUM ('PARTNER_API', 'ADMIN_IMPORT', 'CRAWLER', 'MANUAL_ENTRY');
CREATE TYPE visibility_scope AS ENUM ('PUBLIC', 'PRIVATE');
CREATE TYPE moderation_status AS ENUM ('PENDING', 'APPROVED', 'FLAGGED', 'REJECTED', 'HIDDEN');
CREATE TYPE request_outcome AS ENUM ('SUCCESS', 'FAILED');
CREATE TYPE job_status AS ENUM ('PENDING', 'RUNNING', 'DONE', 'FAILED');

CREATE TABLE domains (
    domain_id            BIGSERIAL PRIMARY KEY,
    code                 VARCHAR(30) NOT NULL UNIQUE,
    name                 VARCHAR(100) NOT NULL,
    description          TEXT,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE partners (
    partner_id           BIGSERIAL PRIMARY KEY,
    partner_code         VARCHAR(50) NOT NULL UNIQUE,
    partner_name         VARCHAR(255) NOT NULL,
    business_type        VARCHAR(100),
    primary_domain_id    BIGINT REFERENCES domains(domain_id),
    website_url          VARCHAR(255),
    contact_email        VARCHAR(255) NOT NULL,
    contact_phone        VARCHAR(50),
    status               partner_status NOT NULL DEFAULT 'PENDING',
    approved_by_user_id  BIGINT,
    approved_at          TIMESTAMP,
    locked_at            TIMESTAMP,
    last_active_at       TIMESTAMP,
    notes                TEXT,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app_users (
    user_id              BIGSERIAL PRIMARY KEY,
    partner_id           BIGINT REFERENCES partners(partner_id) ON DELETE CASCADE,
    full_name            VARCHAR(150) NOT NULL,
    email                VARCHAR(255) NOT NULL UNIQUE,
    password_hash        VARCHAR(255) NOT NULL,
    role                 user_role NOT NULL,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at        TIMESTAMP,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE partners
ADD CONSTRAINT fk_partners_approved_by
FOREIGN KEY (approved_by_user_id) REFERENCES app_users(user_id);

CREATE TABLE partner_domains (
    partner_id           BIGINT NOT NULL REFERENCES partners(partner_id) ON DELETE CASCADE,
    domain_id            BIGINT NOT NULL REFERENCES domains(domain_id) ON DELETE CASCADE,
    is_primary           BOOLEAN NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (partner_id, domain_id)
);

CREATE TABLE service_plans (
    plan_id              BIGSERIAL PRIMARY KEY,
    plan_code            VARCHAR(50) NOT NULL UNIQUE,
    plan_name            VARCHAR(100) NOT NULL,
    price_monthly        NUMERIC(12,2),
    request_limit_monthly INTEGER NOT NULL CHECK (request_limit_monthly >= 0),
    can_read_data        BOOLEAN NOT NULL DEFAULT TRUE,
    can_write_data       BOOLEAN NOT NULL DEFAULT FALSE,
    can_use_ai           BOOLEAN NOT NULL DEFAULT FALSE,
    can_view_summary     BOOLEAN NOT NULL DEFAULT FALSE,
    can_view_sentiment   BOOLEAN NOT NULL DEFAULT FALSE,
    can_view_ranking     BOOLEAN NOT NULL DEFAULT FALSE,
    description          TEXT,
    status               plan_status NOT NULL DEFAULT 'ACTIVE',
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE plan_domain_permissions (
    plan_id              BIGINT NOT NULL REFERENCES service_plans(plan_id) ON DELETE CASCADE,
    domain_id            BIGINT NOT NULL REFERENCES domains(domain_id) ON DELETE CASCADE,
    can_read             BOOLEAN NOT NULL DEFAULT TRUE,
    can_write            BOOLEAN NOT NULL DEFAULT FALSE,
    can_share_public     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (plan_id, domain_id)
);

CREATE TABLE partner_subscriptions (
    subscription_id      BIGSERIAL PRIMARY KEY,
    partner_id           BIGINT NOT NULL REFERENCES partners(partner_id) ON DELETE CASCADE,
    plan_id              BIGINT NOT NULL REFERENCES service_plans(plan_id),
    status               subscription_status NOT NULL DEFAULT 'TRIAL',
    start_date           DATE NOT NULL,
    end_date             DATE,
    is_trial             BOOLEAN NOT NULL DEFAULT FALSE,
    request_limit_override INTEGER,
    request_used_current_cycle INTEGER NOT NULL DEFAULT 0 CHECK (request_used_current_cycle >= 0),
    quota_reset_at       DATE,
    notes                TEXT,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE api_keys (
    api_key_id           BIGSERIAL PRIMARY KEY,
    partner_id           BIGINT NOT NULL REFERENCES partners(partner_id) ON DELETE CASCADE,
    subscription_id      BIGINT REFERENCES partner_subscriptions(subscription_id) ON DELETE SET NULL,
    key_name             VARCHAR(100) NOT NULL,
    key_prefix           VARCHAR(30) NOT NULL,
    key_hash             VARCHAR(255) NOT NULL UNIQUE,
    key_type             api_key_type NOT NULL,
    status               api_key_status NOT NULL DEFAULT 'ACTIVE',
    created_by_user_id   BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    expires_at           TIMESTAMP,
    last_used_at         TIMESTAMP,
    revoked_at           TIMESTAMP,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE review_targets (
    target_id            BIGSERIAL PRIMARY KEY,
    target_code          VARCHAR(80) NOT NULL UNIQUE,
    domain_id            BIGINT NOT NULL REFERENCES domains(domain_id),
    target_name          VARCHAR(255) NOT NULL,
    owner_name           VARCHAR(255),
    owner_partner_id     BIGINT REFERENCES partners(partner_id) ON DELETE SET NULL,
    metadata             JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE partner_target_visibility_rules (
    rule_id              BIGSERIAL PRIMARY KEY,
    partner_id           BIGINT NOT NULL REFERENCES partners(partner_id) ON DELETE CASCADE,
    target_id            BIGINT NOT NULL REFERENCES review_targets(target_id) ON DELETE CASCADE,
    default_visibility   visibility_scope NOT NULL,
    effective_from       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes                TEXT,
    UNIQUE (partner_id, target_id)
);

CREATE TABLE reviews (
    review_id            BIGSERIAL PRIMARY KEY,
    review_code          VARCHAR(60) NOT NULL UNIQUE,
    external_review_id   VARCHAR(100),
    target_id            BIGINT NOT NULL REFERENCES review_targets(target_id) ON DELETE CASCADE,
    source_partner_id    BIGINT REFERENCES partners(partner_id) ON DELETE SET NULL,
    reviewer_name        VARCHAR(150),
    reviewer_external_id VARCHAR(100),
    rating               NUMERIC(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
    comment_text         TEXT NOT NULL,
    reviewed_at          TIMESTAMP NOT NULL,
    source_type          ingestion_source NOT NULL DEFAULT 'PARTNER_API',
    source_system        VARCHAR(100),
    visibility           visibility_scope NOT NULL DEFAULT 'PRIVATE',
    moderation_status    moderation_status NOT NULL DEFAULT 'PENDING',
    moderation_reason    TEXT,
    published_at         TIMESTAMP,
    deleted_at           TIMESTAMP,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX uq_reviews_partner_external
ON reviews (source_partner_id, external_review_id)
WHERE external_review_id IS NOT NULL;

CREATE TABLE review_media (
    media_id             BIGSERIAL PRIMARY KEY,
    review_id            BIGINT NOT NULL REFERENCES reviews(review_id) ON DELETE CASCADE,
    media_url            TEXT NOT NULL,
    media_type           VARCHAR(30) NOT NULL DEFAULT 'IMAGE',
    sort_order           INTEGER NOT NULL DEFAULT 1,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE review_ai_results (
    ai_result_id         BIGSERIAL PRIMARY KEY,
    review_id            BIGINT NOT NULL UNIQUE REFERENCES reviews(review_id) ON DELETE CASCADE,
    toxicity_score       NUMERIC(5,4),
    spam_score           NUMERIC(5,4),
    duplicate_score      NUMERIC(5,4),
    sentiment_label      VARCHAR(30),
    sentiment_score      NUMERIC(5,4),
    summary_text         TEXT,
    topic_tags           JSONB NOT NULL DEFAULT '[]'::jsonb,
    model_name           VARCHAR(100),
    model_version        VARCHAR(50),
    recommended_action   VARCHAR(30),
    processed_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE moderation_events (
    moderation_event_id  BIGSERIAL PRIMARY KEY,
    review_id            BIGINT NOT NULL REFERENCES reviews(review_id) ON DELETE CASCADE,
    actor_type           VARCHAR(20) NOT NULL CHECK (actor_type IN ('AI', 'ADMIN', 'STAFF')),
    actor_user_id        BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    old_status           moderation_status,
    new_status           moderation_status NOT NULL,
    reason               TEXT,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE data_ingestion_jobs (
    job_id               BIGSERIAL PRIMARY KEY,
    job_name             VARCHAR(150) NOT NULL,
    source_type          ingestion_source NOT NULL,
    partner_id           BIGINT REFERENCES partners(partner_id) ON DELETE SET NULL,
    domain_id            BIGINT REFERENCES domains(domain_id) ON DELETE SET NULL,
    source_path_or_url   TEXT,
    status               job_status NOT NULL DEFAULT 'PENDING',
    total_records        INTEGER NOT NULL DEFAULT 0 CHECK (total_records >= 0),
    success_records      INTEGER NOT NULL DEFAULT 0 CHECK (success_records >= 0),
    failed_records       INTEGER NOT NULL DEFAULT 0 CHECK (failed_records >= 0),
    created_by_user_id   BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    started_at           TIMESTAMP,
    finished_at          TIMESTAMP,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE target_aggregates (
    target_id            BIGINT PRIMARY KEY REFERENCES review_targets(target_id) ON DELETE CASCADE,
    avg_rating           NUMERIC(4,2) NOT NULL DEFAULT 0,
    total_reviews        INTEGER NOT NULL DEFAULT 0 CHECK (total_reviews >= 0),
    public_reviews       INTEGER NOT NULL DEFAULT 0 CHECK (public_reviews >= 0),
    private_reviews      INTEGER NOT NULL DEFAULT 0 CHECK (private_reviews >= 0),
    approved_reviews     INTEGER NOT NULL DEFAULT 0 CHECK (approved_reviews >= 0),
    ranking_score        NUMERIC(10,4) NOT NULL DEFAULT 0,
    last_recalculated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE api_request_logs (
    request_log_id       BIGSERIAL PRIMARY KEY,
    partner_id           BIGINT REFERENCES partners(partner_id) ON DELETE SET NULL,
    api_key_id           BIGINT REFERENCES api_keys(api_key_id) ON DELETE SET NULL,
    endpoint             VARCHAR(200) NOT NULL,
    http_method          VARCHAR(10) NOT NULL,
    request_domain_id    BIGINT REFERENCES domains(domain_id) ON DELETE SET NULL,
    target_id            BIGINT REFERENCES review_targets(target_id) ON DELETE SET NULL,
    http_status          INTEGER NOT NULL,
    response_time_ms     INTEGER CHECK (response_time_ms >= 0),
    records_returned     INTEGER NOT NULL DEFAULT 0 CHECK (records_returned >= 0),
    outcome              request_outcome NOT NULL,
    client_ip            VARCHAR(64),
    trace_id             VARCHAR(100),
    requested_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_api_visible_reviews AS
SELECT
    r.review_id,
    r.review_code,
    r.external_review_id,
    r.target_id,
    t.target_code,
    t.target_name,
    d.code AS domain_code,
    d.name AS domain_name,
    r.source_partner_id,
    r.reviewer_name,
    r.rating,
    r.comment_text,
    r.reviewed_at,
    r.visibility,
    r.moderation_status,
    air.sentiment_label,
    air.sentiment_score,
    air.summary_text,
    air.topic_tags
FROM reviews r
JOIN review_targets t ON t.target_id = r.target_id
JOIN domains d ON d.domain_id = t.domain_id
LEFT JOIN review_ai_results air ON air.review_id = r.review_id
WHERE r.moderation_status = 'APPROVED'
  AND r.deleted_at IS NULL;

CREATE INDEX idx_partners_status ON partners(status);
CREATE INDEX idx_partner_domains_domain ON partner_domains(domain_id);
CREATE INDEX idx_subscriptions_partner_status ON partner_subscriptions(partner_id, status);
CREATE INDEX idx_api_keys_partner_type_status ON api_keys(partner_id, key_type, status);
CREATE INDEX idx_targets_domain ON review_targets(domain_id);
CREATE INDEX idx_reviews_target_visibility_status
    ON reviews(target_id, visibility, moderation_status, reviewed_at DESC);
CREATE INDEX idx_reviews_partner_visibility_status
    ON reviews(source_partner_id, visibility, moderation_status, reviewed_at DESC);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_ai_results_sentiment ON review_ai_results(sentiment_label);
CREATE INDEX idx_ingestion_jobs_status ON data_ingestion_jobs(status, source_type);
CREATE INDEX idx_api_logs_partner_time ON api_request_logs(partner_id, requested_at DESC);
CREATE INDEX idx_api_logs_endpoint_time ON api_request_logs(endpoint, requested_at DESC);

-- Seed domains from the requirements.
INSERT INTO domains (code, name, description) VALUES
('BUS', 'Bus', 'Bus and coach operators'),
('HOTEL', 'Hotel', 'Hotels and accommodation'),
('FLIGHT', 'Flight', 'Airlines and flight-related services'),
('TRAIN', 'Train', 'Rail operators'),
('TOUR', 'Tour', 'Tours and travel experiences'),
('OTHER', 'Other', 'Other service categories');

-- Seed plans matching the demo HTML.
INSERT INTO service_plans (
    plan_code, plan_name, price_monthly, request_limit_monthly,
    can_read_data, can_write_data, can_use_ai, can_view_summary, can_view_sentiment, can_view_ranking, description
) VALUES
('STARTER', 'Starter', 990000, 10000, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, 'Public review read-only, sandbox support'),
('GROWTH', 'Growth', 2490000, 80000, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, 'Read and write review data with AI moderation'),
('ENTERPRISE', 'Enterprise', NULL, 999999999, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, 'Custom quota, advanced rules, SLA and support');

-- Allow every plan to read at least the baseline domains.
INSERT INTO plan_domain_permissions (plan_id, domain_id, can_read, can_write, can_share_public)
SELECT sp.plan_id, d.domain_id,
       TRUE,
       CASE WHEN sp.plan_code IN ('GROWTH', 'ENTERPRISE') THEN TRUE ELSE FALSE END,
       TRUE
FROM service_plans sp
CROSS JOIN domains d;

COMMIT;
