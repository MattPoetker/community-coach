SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    community_id bigint,
    actor_id bigint,
    subject_type character varying,
    subject_id bigint,
    action character varying NOT NULL,
    changes_made jsonb DEFAULT '{}'::jsonb NOT NULL,
    ip_address character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    "position" integer DEFAULT 0 NOT NULL,
    post_permission character varying DEFAULT 'all'::character varying NOT NULL,
    access_rule jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    post_id bigint NOT NULL,
    user_id bigint NOT NULL,
    parent_id bigint,
    body jsonb DEFAULT '{}'::jsonb NOT NULL,
    body_text text DEFAULT ''::text NOT NULL,
    path public.ltree NOT NULL,
    depth integer DEFAULT 0 NOT NULL,
    reactions_count integer DEFAULT 0 NOT NULL,
    edited_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    search_vector tsvector GENERATED ALWAYS AS (to_tsvector('english'::regconfig, COALESCE(body_text, ''::text))) STORED,
    CONSTRAINT comments_depth_check CHECK (((depth >= 0) AND (depth <= 5)))
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: communities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.communities (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    name character varying NOT NULL,
    description text,
    tagline character varying,
    privacy character varying DEFAULT 'public'::character varying NOT NULL,
    currency character varying DEFAULT 'GBP'::character varying NOT NULL,
    billing_mode character varying DEFAULT 'direct'::character varying NOT NULL,
    timezone character varying DEFAULT 'Etc/UTC'::character varying NOT NULL,
    branding jsonb DEFAULT '{}'::jsonb NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    published_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT communities_billing_mode_check CHECK (((billing_mode)::text = ANY ((ARRAY['direct'::character varying, 'connect'::character varying])::text[]))),
    CONSTRAINT communities_privacy_check CHECK (((privacy)::text = ANY ((ARRAY['public'::character varying, 'private'::character varying, 'secret'::character varying])::text[])))
);


--
-- Name: communities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.communities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: communities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.communities_id_seq OWNED BY public.communities.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupons (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    code character varying NOT NULL,
    percent_off integer,
    amount_off_cents integer,
    duration character varying DEFAULT 'once'::character varying NOT NULL,
    max_redemptions integer,
    redemptions_count integer DEFAULT 0 NOT NULL,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;


--
-- Name: course_modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_modules (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    course_id bigint NOT NULL,
    title character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: course_modules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_modules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_modules_id_seq OWNED BY public.course_modules.id;


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    cover_key character varying,
    "position" integer DEFAULT 0 NOT NULL,
    access_rule jsonb DEFAULT '{}'::jsonb NOT NULL,
    published_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: custom_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_domains (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    hostname character varying NOT NULL,
    verified_at timestamp(6) without time zone,
    verification_token character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: custom_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_domains_id_seq OWNED BY public.custom_domains.id;


--
-- Name: event_occurrences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_occurrences (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    event_id bigint NOT NULL,
    starts_at timestamp(6) without time zone NOT NULL,
    ends_at timestamp(6) without time zone NOT NULL,
    overridden boolean DEFAULT false NOT NULL,
    cancelled_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: event_occurrences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_occurrences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_occurrences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_occurrences_id_seq OWNED BY public.event_occurrences.id;


--
-- Name: event_rsvps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_rsvps (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    event_occurrence_id bigint NOT NULL,
    user_id bigint NOT NULL,
    state character varying DEFAULT 'going'::character varying NOT NULL,
    reminded_24h_at timestamp(6) without time zone,
    reminded_15m_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT event_rsvps_state_check CHECK (((state)::text = ANY ((ARRAY['going'::character varying, 'maybe'::character varying, 'declined'::character varying])::text[])))
);


--
-- Name: event_rsvps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_rsvps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_rsvps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_rsvps_id_seq OWNED BY public.event_rsvps.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    host_id bigint NOT NULL,
    title character varying NOT NULL,
    description text,
    starts_at timestamp(6) without time zone NOT NULL,
    duration_minutes integer DEFAULT 60 NOT NULL,
    timezone character varying NOT NULL,
    rrule character varying,
    recurrence_end_at timestamp(6) without time zone,
    location_kind character varying DEFAULT 'url'::character varying NOT NULL,
    location_url character varying,
    access_rule jsonb DEFAULT '{}'::jsonb NOT NULL,
    cancelled_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT events_location_kind_check CHECK (((location_kind)::text = ANY ((ARRAY['zoom'::character varying, 'meet'::character varying, 'jitsi'::character varying, 'url'::character varying, 'in_person'::character varying])::text[])))
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    invited_by_id bigint NOT NULL,
    email_address public.citext NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    token_digest character varying NOT NULL,
    accepted_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invitations_id_seq OWNED BY public.invitations.id;


--
-- Name: join_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.join_requests (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reviewed_by_id bigint,
    answers jsonb DEFAULT '{}'::jsonb NOT NULL,
    state character varying DEFAULT 'pending'::character varying NOT NULL,
    reviewed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: join_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.join_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: join_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.join_requests_id_seq OWNED BY public.join_requests.id;


--
-- Name: lesson_progresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lesson_progresses (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    user_id bigint NOT NULL,
    lesson_id bigint NOT NULL,
    state character varying DEFAULT 'started'::character varying NOT NULL,
    seconds_watched integer DEFAULT 0 NOT NULL,
    resume_at_seconds integer DEFAULT 0 NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT lesson_progresses_state_check CHECK (((state)::text = ANY ((ARRAY['started'::character varying, 'completed'::character varying])::text[])))
);


--
-- Name: lesson_progresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lesson_progresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lesson_progresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lesson_progresses_id_seq OWNED BY public.lesson_progresses.id;


--
-- Name: lessons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lessons (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    course_module_id bigint NOT NULL,
    video_asset_id bigint,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    body jsonb DEFAULT '{}'::jsonb NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    drip_kind character varying DEFAULT 'none'::character varying NOT NULL,
    drip_days integer,
    drip_at timestamp(6) without time zone,
    access_rule jsonb DEFAULT '{}'::jsonb NOT NULL,
    published_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    search_vector tsvector GENERATED ALWAYS AS (setweight(to_tsvector('english'::regconfig, (COALESCE(title, ''::character varying))::text), 'A'::"char")) STORED,
    CONSTRAINT lessons_drip_kind_check CHECK (((drip_kind)::text = ANY ((ARRAY['none'::character varying, 'days_after_join'::character varying, 'fixed_date'::character varying])::text[])))
);


--
-- Name: lessons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lessons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lessons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lessons_id_seq OWNED BY public.lessons.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memberships (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    community_id bigint NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    joined_at timestamp(6) without time zone,
    last_seen_at timestamp(6) without time zone,
    suspended_at timestamp(6) without time zone,
    suspension_reason text,
    points integer DEFAULT 0 NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT memberships_role_check CHECK (((role)::text = ANY ((ARRAY['owner'::character varying, 'admin'::character varying, 'moderator'::character varying, 'member'::character varying])::text[]))),
    CONSTRAINT memberships_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'past_due'::character varying, 'suspended'::character varying, 'cancelled'::character varying])::text[])))
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memberships_id_seq OWNED BY public.memberships.id;


--
-- Name: mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mentions (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    source_type character varying NOT NULL,
    source_id bigint NOT NULL,
    mentioned_user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: mentions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mentions_id_seq OWNED BY public.mentions.id;


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_preferences (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    user_id bigint NOT NULL,
    kind character varying NOT NULL,
    in_app boolean DEFAULT true NOT NULL,
    email character varying DEFAULT 'instant'::character varying NOT NULL,
    push boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT notification_preferences_email_check CHECK (((email)::text = ANY ((ARRAY['off'::character varying, 'instant'::character varying, 'daily'::character varying])::text[])))
);


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_preferences_id_seq OWNED BY public.notification_preferences.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    user_id bigint NOT NULL,
    actor_id bigint,
    subject_type character varying,
    subject_id bigint,
    kind character varying NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    group_count integer DEFAULT 1 NOT NULL,
    read_at timestamp(6) without time zone,
    emailed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    subscription_id bigint,
    amount_cents integer NOT NULL,
    currency character varying NOT NULL,
    status character varying NOT NULL,
    provider_ref character varying,
    invoice_url character varying,
    paid_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    "interval" character varying DEFAULT 'month'::character varying NOT NULL,
    amount_cents integer DEFAULT 0 NOT NULL,
    currency character varying DEFAULT 'GBP'::character varying NOT NULL,
    trial_days integer DEFAULT 0 NOT NULL,
    provider_price_id character varying,
    features jsonb DEFAULT '[]'::jsonb NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT plans_amount_check CHECK ((amount_cents >= 0)),
    CONSTRAINT plans_interval_check CHECK ((("interval")::text = ANY ((ARRAY['month'::character varying, 'year'::character varying, 'one_time'::character varying])::text[])))
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: poll_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_options (
    id bigint NOT NULL,
    poll_id bigint NOT NULL,
    label character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    votes_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: poll_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.poll_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.poll_options_id_seq OWNED BY public.poll_options.id;


--
-- Name: poll_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_votes (
    id bigint NOT NULL,
    poll_option_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: poll_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.poll_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.poll_votes_id_seq OWNED BY public.poll_votes.id;


--
-- Name: polls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polls (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    multiple boolean DEFAULT false NOT NULL,
    closes_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: polls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polls_id_seq OWNED BY public.polls.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    category_id bigint NOT NULL,
    user_id bigint NOT NULL,
    title character varying NOT NULL,
    body jsonb DEFAULT '{}'::jsonb NOT NULL,
    body_text text DEFAULT ''::text NOT NULL,
    kind character varying DEFAULT 'discussion'::character varying NOT NULL,
    pinned_at timestamp(6) without time zone,
    locked_at timestamp(6) without time zone,
    edited_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    comments_count integer DEFAULT 0 NOT NULL,
    reactions_count integer DEFAULT 0 NOT NULL,
    last_activity_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    search_vector tsvector GENERATED ALWAYS AS ((setweight(to_tsvector('english'::regconfig, (COALESCE(title, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('english'::regconfig, COALESCE(body_text, ''::text)), 'B'::"char"))) STORED,
    CONSTRAINT posts_kind_check CHECK (((kind)::text = ANY ((ARRAY['discussion'::character varying, 'poll'::character varying, 'announcement'::character varying])::text[])))
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.push_subscriptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    endpoint character varying NOT NULL,
    p256dh_key character varying NOT NULL,
    auth_key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.push_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.push_subscriptions_id_seq OWNED BY public.push_subscriptions.id;


--
-- Name: reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reactions (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reactable_type character varying NOT NULL,
    reactable_id bigint NOT NULL,
    kind character varying DEFAULT 'like'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reactions_id_seq OWNED BY public.reactions.id;


--
-- Name: recordings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recordings (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    event_occurrence_id bigint NOT NULL,
    video_asset_id bigint NOT NULL,
    published_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: recordings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recordings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recordings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recordings_id_seq OWNED BY public.recordings.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    reporter_id bigint NOT NULL,
    resolved_by_id bigint,
    subject_type character varying NOT NULL,
    subject_id bigint NOT NULL,
    reason character varying NOT NULL,
    detail text,
    state character varying DEFAULT 'open'::character varying NOT NULL,
    resolved_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_digest character varying NOT NULL,
    user_agent character varying,
    ip_address character varying,
    last_active_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    membership_id bigint NOT NULL,
    plan_id bigint NOT NULL,
    provider character varying DEFAULT 'stripe'::character varying NOT NULL,
    provider_ref character varying,
    status character varying DEFAULT 'trialing'::character varying NOT NULL,
    trial_ends_at timestamp(6) without time zone,
    current_period_end timestamp(6) without time zone,
    cancel_at_period_end boolean DEFAULT false NOT NULL,
    cancelled_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT subscriptions_status_check CHECK (((status)::text = ANY ((ARRAY['trialing'::character varying, 'active'::character varying, 'past_due'::character varying, 'cancelled'::character varying, 'incomplete'::character varying])::text[])))
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: thread_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thread_subscriptions (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    user_id bigint NOT NULL,
    subject_type character varying NOT NULL,
    subject_id bigint NOT NULL,
    reason character varying DEFAULT 'manual'::character varying NOT NULL,
    muted boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: thread_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.thread_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: thread_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.thread_subscriptions_id_seq OWNED BY public.thread_subscriptions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email_address public.citext NOT NULL,
    password_digest character varying NOT NULL,
    name character varying NOT NULL,
    timezone character varying DEFAULT 'Etc/UTC'::character varying NOT NULL,
    locale character varying DEFAULT 'en'::character varying NOT NULL,
    confirmed_at timestamp(6) without time zone,
    confirmation_token character varying,
    password_reset_token character varying,
    password_reset_sent_at timestamp(6) without time zone,
    totp_secret character varying,
    totp_recovery_codes character varying[] DEFAULT '{}'::character varying[],
    totp_enabled_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: video_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_assets (
    id bigint NOT NULL,
    community_id bigint NOT NULL,
    status character varying DEFAULT 'uploading'::character varying NOT NULL,
    provider character varying DEFAULT 'local'::character varying NOT NULL,
    provider_ref character varying,
    original_filename character varying,
    duration_seconds integer,
    renditions jsonb DEFAULT '[]'::jsonb NOT NULL,
    thumbnail_key character varying,
    error_message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT video_assets_status_check CHECK (((status)::text = ANY ((ARRAY['uploading'::character varying, 'processing'::character varying, 'ready'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: video_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.video_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: video_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.video_assets_id_seq OWNED BY public.video_assets.id;


--
-- Name: webhook_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_events (
    id bigint NOT NULL,
    provider character varying NOT NULL,
    provider_event_id character varying NOT NULL,
    event_type character varying NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    processed_at timestamp(6) without time zone,
    error_message text,
    attempts integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: webhook_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webhook_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhook_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webhook_events_id_seq OWNED BY public.webhook_events.id;


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: communities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communities ALTER COLUMN id SET DEFAULT nextval('public.communities_id_seq'::regclass);


--
-- Name: coupons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);


--
-- Name: course_modules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_modules ALTER COLUMN id SET DEFAULT nextval('public.course_modules_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: custom_domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains ALTER COLUMN id SET DEFAULT nextval('public.custom_domains_id_seq'::regclass);


--
-- Name: event_occurrences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_occurrences ALTER COLUMN id SET DEFAULT nextval('public.event_occurrences_id_seq'::regclass);


--
-- Name: event_rsvps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_rsvps ALTER COLUMN id SET DEFAULT nextval('public.event_rsvps_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: invitations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations ALTER COLUMN id SET DEFAULT nextval('public.invitations_id_seq'::regclass);


--
-- Name: join_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.join_requests ALTER COLUMN id SET DEFAULT nextval('public.join_requests_id_seq'::regclass);


--
-- Name: lesson_progresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_progresses ALTER COLUMN id SET DEFAULT nextval('public.lesson_progresses_id_seq'::regclass);


--
-- Name: lessons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lessons ALTER COLUMN id SET DEFAULT nextval('public.lessons_id_seq'::regclass);


--
-- Name: memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships ALTER COLUMN id SET DEFAULT nextval('public.memberships_id_seq'::regclass);


--
-- Name: mentions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions ALTER COLUMN id SET DEFAULT nextval('public.mentions_id_seq'::regclass);


--
-- Name: notification_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences ALTER COLUMN id SET DEFAULT nextval('public.notification_preferences_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: poll_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_options ALTER COLUMN id SET DEFAULT nextval('public.poll_options_id_seq'::regclass);


--
-- Name: poll_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes ALTER COLUMN id SET DEFAULT nextval('public.poll_votes_id_seq'::regclass);


--
-- Name: polls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls ALTER COLUMN id SET DEFAULT nextval('public.polls_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: push_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.push_subscriptions_id_seq'::regclass);


--
-- Name: reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions ALTER COLUMN id SET DEFAULT nextval('public.reactions_id_seq'::regclass);


--
-- Name: recordings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordings ALTER COLUMN id SET DEFAULT nextval('public.recordings_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: thread_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thread_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.thread_subscriptions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: video_assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_assets ALTER COLUMN id SET DEFAULT nextval('public.video_assets_id_seq'::regclass);


--
-- Name: webhook_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_events ALTER COLUMN id SET DEFAULT nextval('public.webhook_events_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: communities communities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communities
    ADD CONSTRAINT communities_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: course_modules course_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_modules
    ADD CONSTRAINT course_modules_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: custom_domains custom_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains
    ADD CONSTRAINT custom_domains_pkey PRIMARY KEY (id);


--
-- Name: event_occurrences event_occurrences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_occurrences
    ADD CONSTRAINT event_occurrences_pkey PRIMARY KEY (id);


--
-- Name: event_rsvps event_rsvps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT event_rsvps_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: join_requests join_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.join_requests
    ADD CONSTRAINT join_requests_pkey PRIMARY KEY (id);


--
-- Name: lesson_progresses lesson_progresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_progresses
    ADD CONSTRAINT lesson_progresses_pkey PRIMARY KEY (id);


--
-- Name: lessons lessons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT lessons_pkey PRIMARY KEY (id);


--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: mentions mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT mentions_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: poll_options poll_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_pkey PRIMARY KEY (id);


--
-- Name: poll_votes poll_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (id);


--
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: push_subscriptions push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (id);


--
-- Name: recordings recordings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordings
    ADD CONSTRAINT recordings_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: thread_subscriptions thread_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thread_subscriptions
    ADD CONSTRAINT thread_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: video_assets video_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_assets
    ADD CONSTRAINT video_assets_pkey PRIMARY KEY (id);


--
-- Name: webhook_events webhook_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_events
    ADD CONSTRAINT webhook_events_pkey PRIMARY KEY (id);


--
-- Name: index_audit_logs_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_actor_id ON public.audit_logs USING btree (actor_id);


--
-- Name: index_audit_logs_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_community_id ON public.audit_logs USING btree (community_id);


--
-- Name: index_audit_logs_on_community_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_community_id_and_created_at ON public.audit_logs USING btree (community_id, created_at DESC);


--
-- Name: index_audit_logs_on_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_subject ON public.audit_logs USING btree (subject_type, subject_id);


--
-- Name: index_categories_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_community_id ON public.categories USING btree (community_id);


--
-- Name: index_categories_on_community_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_community_id_and_position ON public.categories USING btree (community_id, "position");


--
-- Name: index_categories_on_community_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_categories_on_community_id_and_slug ON public.categories USING btree (community_id, slug);


--
-- Name: index_comments_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_community_id ON public.comments USING btree (community_id);


--
-- Name: index_comments_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_parent_id ON public.comments USING btree (parent_id);


--
-- Name: index_comments_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_path ON public.comments USING gist (path);


--
-- Name: index_comments_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_post_id ON public.comments USING btree (post_id);


--
-- Name: index_comments_on_post_id_and_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_post_id_and_path ON public.comments USING btree (post_id, path);


--
-- Name: index_comments_on_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_search_vector ON public.comments USING gin (search_vector);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_communities_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_communities_on_slug ON public.communities USING btree (slug);


--
-- Name: index_coupons_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coupons_on_community_id ON public.coupons USING btree (community_id);


--
-- Name: index_coupons_on_community_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_coupons_on_community_id_and_code ON public.coupons USING btree (community_id, code);


--
-- Name: index_course_modules_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_modules_on_community_id ON public.course_modules USING btree (community_id);


--
-- Name: index_course_modules_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_modules_on_course_id ON public.course_modules USING btree (course_id);


--
-- Name: index_course_modules_on_course_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_modules_on_course_id_and_position ON public.course_modules USING btree (course_id, "position");


--
-- Name: index_courses_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_community_id ON public.courses USING btree (community_id);


--
-- Name: index_courses_on_community_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_community_id_and_slug ON public.courses USING btree (community_id, slug);


--
-- Name: index_custom_domains_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_domains_on_community_id ON public.custom_domains USING btree (community_id);


--
-- Name: index_custom_domains_on_hostname; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_domains_on_hostname ON public.custom_domains USING btree (hostname);


--
-- Name: index_event_occurrences_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_occurrences_on_community_id ON public.event_occurrences USING btree (community_id);


--
-- Name: index_event_occurrences_on_community_id_and_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_occurrences_on_community_id_and_starts_at ON public.event_occurrences USING btree (community_id, starts_at);


--
-- Name: index_event_occurrences_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_occurrences_on_event_id ON public.event_occurrences USING btree (event_id);


--
-- Name: index_event_occurrences_on_event_id_and_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_event_occurrences_on_event_id_and_starts_at ON public.event_occurrences USING btree (event_id, starts_at);


--
-- Name: index_event_rsvps_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_rsvps_on_community_id ON public.event_rsvps USING btree (community_id);


--
-- Name: index_event_rsvps_on_event_occurrence_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_rsvps_on_event_occurrence_id ON public.event_rsvps USING btree (event_occurrence_id);


--
-- Name: index_event_rsvps_on_event_occurrence_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_event_rsvps_on_event_occurrence_id_and_user_id ON public.event_rsvps USING btree (event_occurrence_id, user_id);


--
-- Name: index_event_rsvps_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_rsvps_on_user_id ON public.event_rsvps USING btree (user_id);


--
-- Name: index_events_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_community_id ON public.events USING btree (community_id);


--
-- Name: index_events_on_community_id_and_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_community_id_and_starts_at ON public.events USING btree (community_id, starts_at);


--
-- Name: index_events_on_host_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_host_id ON public.events USING btree (host_id);


--
-- Name: index_invitations_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_community_id ON public.invitations USING btree (community_id);


--
-- Name: index_invitations_on_community_id_and_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_community_id_and_email_address ON public.invitations USING btree (community_id, email_address);


--
-- Name: index_invitations_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_invited_by_id ON public.invitations USING btree (invited_by_id);


--
-- Name: index_invitations_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invitations_on_token_digest ON public.invitations USING btree (token_digest);


--
-- Name: index_join_requests_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_join_requests_on_community_id ON public.join_requests USING btree (community_id);


--
-- Name: index_join_requests_on_community_id_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_join_requests_on_community_id_and_state ON public.join_requests USING btree (community_id, state);


--
-- Name: index_join_requests_on_community_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_join_requests_on_community_id_and_user_id ON public.join_requests USING btree (community_id, user_id);


--
-- Name: index_join_requests_on_reviewed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_join_requests_on_reviewed_by_id ON public.join_requests USING btree (reviewed_by_id);


--
-- Name: index_join_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_join_requests_on_user_id ON public.join_requests USING btree (user_id);


--
-- Name: index_lesson_progresses_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lesson_progresses_on_community_id ON public.lesson_progresses USING btree (community_id);


--
-- Name: index_lesson_progresses_on_community_id_and_user_id_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lesson_progresses_on_community_id_and_user_id_and_state ON public.lesson_progresses USING btree (community_id, user_id, state);


--
-- Name: index_lesson_progresses_on_lesson_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lesson_progresses_on_lesson_id ON public.lesson_progresses USING btree (lesson_id);


--
-- Name: index_lesson_progresses_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lesson_progresses_on_user_id ON public.lesson_progresses USING btree (user_id);


--
-- Name: index_lesson_progresses_on_user_id_and_lesson_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lesson_progresses_on_user_id_and_lesson_id ON public.lesson_progresses USING btree (user_id, lesson_id);


--
-- Name: index_lessons_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lessons_on_community_id ON public.lessons USING btree (community_id);


--
-- Name: index_lessons_on_course_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lessons_on_course_module_id ON public.lessons USING btree (course_module_id);


--
-- Name: index_lessons_on_course_module_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lessons_on_course_module_id_and_position ON public.lessons USING btree (course_module_id, "position");


--
-- Name: index_lessons_on_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lessons_on_search_vector ON public.lessons USING gin (search_vector);


--
-- Name: index_lessons_on_video_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lessons_on_video_asset_id ON public.lessons USING btree (video_asset_id);


--
-- Name: index_memberships_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_community_id ON public.memberships USING btree (community_id);


--
-- Name: index_memberships_on_community_id_and_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_community_id_and_role ON public.memberships USING btree (community_id, role);


--
-- Name: index_memberships_on_community_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_community_id_and_status ON public.memberships USING btree (community_id, status);


--
-- Name: index_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_user_id ON public.memberships USING btree (user_id);


--
-- Name: index_memberships_on_user_id_and_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_memberships_on_user_id_and_community_id ON public.memberships USING btree (user_id, community_id);


--
-- Name: index_mentions_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mentions_on_community_id ON public.mentions USING btree (community_id);


--
-- Name: index_mentions_on_mentioned_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mentions_on_mentioned_user_id ON public.mentions USING btree (mentioned_user_id);


--
-- Name: index_mentions_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mentions_on_source ON public.mentions USING btree (source_type, source_id);


--
-- Name: index_mentions_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mentions_uniqueness ON public.mentions USING btree (source_type, source_id, mentioned_user_id);


--
-- Name: index_notification_preferences_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_preferences_on_community_id ON public.notification_preferences USING btree (community_id);


--
-- Name: index_notification_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_preferences_on_user_id ON public.notification_preferences USING btree (user_id);


--
-- Name: index_notification_preferences_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_preferences_uniqueness ON public.notification_preferences USING btree (community_id, user_id, kind);


--
-- Name: index_notifications_for_grouping; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_for_grouping ON public.notifications USING btree (user_id, subject_type, subject_id, kind);


--
-- Name: index_notifications_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_actor_id ON public.notifications USING btree (actor_id);


--
-- Name: index_notifications_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_community_id ON public.notifications USING btree (community_id);


--
-- Name: index_notifications_on_inbox; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_inbox ON public.notifications USING btree (user_id, read_at, created_at DESC);


--
-- Name: index_notifications_on_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_subject ON public.notifications USING btree (subject_type, subject_id);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_user_id ON public.notifications USING btree (user_id);


--
-- Name: index_payments_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_community_id ON public.payments USING btree (community_id);


--
-- Name: index_payments_on_provider_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payments_on_provider_ref ON public.payments USING btree (provider_ref) WHERE (provider_ref IS NOT NULL);


--
-- Name: index_payments_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_subscription_id ON public.payments USING btree (subscription_id);


--
-- Name: index_plans_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_community_id ON public.plans USING btree (community_id);


--
-- Name: index_plans_on_community_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plans_on_community_id_and_slug ON public.plans USING btree (community_id, slug);


--
-- Name: index_poll_options_on_poll_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_poll_options_on_poll_id ON public.poll_options USING btree (poll_id);


--
-- Name: index_poll_votes_on_poll_option_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_poll_votes_on_poll_option_id ON public.poll_votes USING btree (poll_option_id);


--
-- Name: index_poll_votes_on_poll_option_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_poll_votes_on_poll_option_id_and_user_id ON public.poll_votes USING btree (poll_option_id, user_id);


--
-- Name: index_poll_votes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_poll_votes_on_user_id ON public.poll_votes USING btree (user_id);


--
-- Name: index_polls_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_polls_on_post_id ON public.polls USING btree (post_id);


--
-- Name: index_posts_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_category_id ON public.posts USING btree (category_id);


--
-- Name: index_posts_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_community_id ON public.posts USING btree (community_id);


--
-- Name: index_posts_on_community_id_and_pinned_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_community_id_and_pinned_at ON public.posts USING btree (community_id, pinned_at) WHERE (pinned_at IS NOT NULL);


--
-- Name: index_posts_on_feed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_feed ON public.posts USING btree (community_id, category_id, last_activity_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: index_posts_on_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_search_vector ON public.posts USING gin (search_vector);


--
-- Name: index_posts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_user_id ON public.posts USING btree (user_id);


--
-- Name: index_push_subscriptions_on_endpoint; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_push_subscriptions_on_endpoint ON public.push_subscriptions USING btree (endpoint);


--
-- Name: index_push_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_push_subscriptions_on_user_id ON public.push_subscriptions USING btree (user_id);


--
-- Name: index_reactions_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_community_id ON public.reactions USING btree (community_id);


--
-- Name: index_reactions_on_reactable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_reactable ON public.reactions USING btree (reactable_type, reactable_id);


--
-- Name: index_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_user_id ON public.reactions USING btree (user_id);


--
-- Name: index_reactions_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reactions_uniqueness ON public.reactions USING btree (reactable_type, reactable_id, user_id, kind);


--
-- Name: index_recordings_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recordings_on_community_id ON public.recordings USING btree (community_id);


--
-- Name: index_recordings_on_event_occurrence_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recordings_on_event_occurrence_id ON public.recordings USING btree (event_occurrence_id);


--
-- Name: index_recordings_on_video_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recordings_on_video_asset_id ON public.recordings USING btree (video_asset_id);


--
-- Name: index_reports_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_community_id ON public.reports USING btree (community_id);


--
-- Name: index_reports_on_community_id_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_community_id_and_state ON public.reports USING btree (community_id, state);


--
-- Name: index_reports_on_reporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_reporter_id ON public.reports USING btree (reporter_id);


--
-- Name: index_reports_on_resolved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_resolved_by_id ON public.reports USING btree (resolved_by_id);


--
-- Name: index_reports_on_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_subject ON public.reports USING btree (subject_type, subject_id);


--
-- Name: index_sessions_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_expires_at ON public.sessions USING btree (expires_at);


--
-- Name: index_sessions_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_token_digest ON public.sessions USING btree (token_digest);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_subscriptions_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_community_id ON public.subscriptions USING btree (community_id);


--
-- Name: index_subscriptions_on_membership_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_membership_id ON public.subscriptions USING btree (membership_id);


--
-- Name: index_subscriptions_on_membership_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_membership_id_and_status ON public.subscriptions USING btree (membership_id, status);


--
-- Name: index_subscriptions_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_plan_id ON public.subscriptions USING btree (plan_id);


--
-- Name: index_subscriptions_on_provider_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscriptions_on_provider_ref ON public.subscriptions USING btree (provider_ref) WHERE (provider_ref IS NOT NULL);


--
-- Name: index_thread_subscriptions_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_thread_subscriptions_on_community_id ON public.thread_subscriptions USING btree (community_id);


--
-- Name: index_thread_subscriptions_on_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_thread_subscriptions_on_subject ON public.thread_subscriptions USING btree (subject_type, subject_id);


--
-- Name: index_thread_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_thread_subscriptions_on_user_id ON public.thread_subscriptions USING btree (user_id);


--
-- Name: index_thread_subscriptions_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_thread_subscriptions_uniqueness ON public.thread_subscriptions USING btree (subject_type, subject_id, user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token) WHERE (confirmation_token IS NOT NULL);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: index_users_on_password_reset_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_password_reset_token ON public.users USING btree (password_reset_token) WHERE (password_reset_token IS NOT NULL);


--
-- Name: index_video_assets_on_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_assets_on_community_id ON public.video_assets USING btree (community_id);


--
-- Name: index_video_assets_on_community_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_assets_on_community_id_and_status ON public.video_assets USING btree (community_id, status);


--
-- Name: index_webhook_events_on_processed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_events_on_processed_at ON public.webhook_events USING btree (processed_at) WHERE (processed_at IS NULL);


--
-- Name: index_webhook_events_on_provider_and_provider_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webhook_events_on_provider_and_provider_event_id ON public.webhook_events USING btree (provider, provider_event_id);


--
-- Name: comments fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: notifications fk_rails_06a39bb8cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_06a39bb8cc FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: subscriptions fk_rails_0ded3585f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_0ded3585f1 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: lesson_progresses fk_rails_12a356079f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_progresses
    ADD CONSTRAINT fk_rails_12a356079f FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: lessons fk_rails_16e8538a8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT fk_rails_16e8538a8a FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: join_requests fk_rails_1d473f1d81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.join_requests
    ADD CONSTRAINT fk_rails_1d473f1d81 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: comments fk_rails_29378e8fae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_29378e8fae FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: audit_logs fk_rails_2c3f85fdd5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_rails_2c3f85fdd5 FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: recordings fk_rails_2ea4f95204; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordings
    ADD CONSTRAINT fk_rails_2ea4f95204 FOREIGN KEY (video_asset_id) REFERENCES public.video_assets(id);


--
-- Name: comments fk_rails_2fd19c0db7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_2fd19c0db7 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: comments fk_rails_31554e7034; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_31554e7034 FOREIGN KEY (parent_id) REFERENCES public.comments(id);


--
-- Name: events fk_rails_3451eeb877; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_3451eeb877 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: push_subscriptions fk_rails_43d43720fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT fk_rails_43d43720fc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: categories fk_rails_44268deff0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_44268deff0 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: notification_preferences fk_rails_4b08860e07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT fk_rails_4b08860e07 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: notifications fk_rails_4ea5195391; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_4ea5195391 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: mentions fk_rails_4f0533c7c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_rails_4f0533c7c7 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: lessons fk_rails_5b5d36e6c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT fk_rails_5b5d36e6c0 FOREIGN KEY (video_asset_id) REFERENCES public.video_assets(id);


--
-- Name: posts fk_rails_5b5ddfd518; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: join_requests fk_rails_5ec9bfccfd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.join_requests
    ADD CONSTRAINT fk_rails_5ec9bfccfd FOREIGN KEY (reviewed_by_id) REFERENCES public.users(id);


--
-- Name: subscriptions fk_rails_63d3df128b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_63d3df128b FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: lesson_progresses fk_rails_66ebbe8433; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_progresses
    ADD CONSTRAINT fk_rails_66ebbe8433 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: course_modules fk_rails_7168731460; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_modules
    ADD CONSTRAINT fk_rails_7168731460 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: course_modules fk_rails_74391d7a5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_modules
    ADD CONSTRAINT fk_rails_74391d7a5f FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: memberships fk_rails_7d4d071473; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_7d4d071473 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: audit_logs fk_rails_7d63bd95f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_rails_7d63bd95f9 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: video_assets fk_rails_81e40273e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_assets
    ADD CONSTRAINT fk_rails_81e40273e0 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: poll_votes fk_rails_848ece0184; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_rails_848ece0184 FOREIGN KEY (poll_option_id) REFERENCES public.poll_options(id);


--
-- Name: reports fk_rails_87004f508b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_87004f508b FOREIGN KEY (resolved_by_id) REFERENCES public.users(id);


--
-- Name: custom_domains fk_rails_87addde2d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains
    ADD CONSTRAINT fk_rails_87addde2d5 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: thread_subscriptions fk_rails_87fdcff312; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thread_subscriptions
    ADD CONSTRAINT fk_rails_87fdcff312 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: event_occurrences fk_rails_93ba1b35cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_occurrences
    ADD CONSTRAINT fk_rails_93ba1b35cf FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: notification_preferences fk_rails_9503aade25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT fk_rails_9503aade25 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: plans fk_rails_95e9653ae6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT fk_rails_95e9653ae6 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: memberships fk_rails_99326fb65d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_99326fb65d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: posts fk_rails_9b1b26f040; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_9b1b26f040 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: event_rsvps fk_rails_9d17fcd060; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT fk_rails_9d17fcd060 FOREIGN KEY (event_occurrence_id) REFERENCES public.event_occurrences(id);


--
-- Name: reactions fk_rails_9f02fc96a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT fk_rails_9f02fc96a0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: lesson_progresses fk_rails_9f28e0e601; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_progresses
    ADD CONSTRAINT fk_rails_9f28e0e601 FOREIGN KEY (lesson_id) REFERENCES public.lessons(id);


--
-- Name: poll_options fk_rails_aa85becb42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT fk_rails_aa85becb42 FOREIGN KEY (poll_id) REFERENCES public.polls(id);


--
-- Name: recordings fk_rails_aced319d6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordings
    ADD CONSTRAINT fk_rails_aced319d6b FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: notifications fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: subscriptions fk_rails_b21278ad5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_b21278ad5c FOREIGN KEY (membership_id) REFERENCES public.memberships(id);


--
-- Name: mentions fk_rails_b23bcf18a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_rails_b23bcf18a5 FOREIGN KEY (mentioned_user_id) REFERENCES public.users(id);


--
-- Name: event_occurrences fk_rails_b34bce2c40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_occurrences
    ADD CONSTRAINT fk_rails_b34bce2c40 FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: polls fk_rails_b50b782d08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT fk_rails_b50b782d08 FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: poll_votes fk_rails_b64de9b025; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_rails_b64de9b025 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payments fk_rails_c46b3b424e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_rails_c46b3b424e FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: join_requests fk_rails_c4a22473cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.join_requests
    ADD CONSTRAINT fk_rails_c4a22473cf FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: reports fk_rails_c4cb6e6463; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_c4cb6e6463 FOREIGN KEY (reporter_id) REFERENCES public.users(id);


--
-- Name: recordings fk_rails_c5a22a8beb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordings
    ADD CONSTRAINT fk_rails_c5a22a8beb FOREIGN KEY (event_occurrence_id) REFERENCES public.event_occurrences(id);


--
-- Name: invitations fk_rails_c70c9be1c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_c70c9be1c0 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: coupons fk_rails_c8dc5aaf03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT fk_rails_c8dc5aaf03 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: courses fk_rails_ced2b0fe9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_ced2b0fe9a FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: event_rsvps fk_rails_d2f0cfffa4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT fk_rails_d2f0cfffa4 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: events fk_rails_d56a268962; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_d56a268962 FOREIGN KEY (host_id) REFERENCES public.users(id);


--
-- Name: thread_subscriptions fk_rails_d6505688ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thread_subscriptions
    ADD CONSTRAINT fk_rails_d6505688ca FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: invitations fk_rails_d799c974a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_d799c974a1 FOREIGN KEY (invited_by_id) REFERENCES public.users(id);


--
-- Name: event_rsvps fk_rails_de6ac07623; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT fk_rails_de6ac07623 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: posts fk_rails_e070049175; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_e070049175 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: lessons fk_rails_e88edeba98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT fk_rails_e88edeba98 FOREIGN KEY (course_module_id) REFERENCES public.course_modules(id);


--
-- Name: reactions fk_rails_e96975026a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT fk_rails_e96975026a FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: reports fk_rails_f8d9acd7c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_f8d9acd7c1 FOREIGN KEY (community_id) REFERENCES public.communities(id);


--
-- Name: payments fk_rails_fd6be2115b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_rails_fd6be2115b FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260910120600'),
('20260910120500'),
('20260910120400'),
('20260910120300'),
('20260910120200'),
('20260910120100'),
('20260910120000');

