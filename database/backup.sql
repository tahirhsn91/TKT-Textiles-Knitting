--
-- PostgreSQL database dump
--

\restrict vOJ8Zhft6fERT9MFGkeXQ3CJ79hCuVzP4tCA16txKBsJykoc36yP6UfeTaAMbrg

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: shift; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.shift AS ENUM (
    'Morning',
    'Night'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _applied_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._applied_migrations (
    name text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    label character varying(120) NOT NULL,
    key_hash character varying(128) NOT NULL,
    key_hint character varying(16) NOT NULL,
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- Name: app_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    username text NOT NULL,
    display_name text NOT NULL,
    password_hash text NOT NULL,
    role_id integer NOT NULL,
    employee_id integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1
);


--
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.app_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    attendance_date date NOT NULL,
    present boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_id_seq OWNED BY public.attendance.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id integer NOT NULL,
    actor_user_id integer,
    actor_tenant_id integer,
    target_tenant_id integer,
    action character varying(100) NOT NULL,
    entity_type character varying(100),
    entity_id integer,
    description text,
    before_json jsonb,
    after_json jsonb,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: auth_audit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_audit (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    user_id integer,
    email character varying(255),
    event_type character varying(50),
    event_description character varying(500),
    status character varying(50),
    ip_address character varying(45),
    user_agent text,
    device_fingerprint character varying(255),
    location_info character varying(255),
    risk_level character varying(50) DEFAULT 'low'::character varying,
    suspicious_activity boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: auth_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_audit_id_seq OWNED BY public.auth_audit.id;


--
-- Name: branding_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branding_config (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    company_name character varying(255) NOT NULL,
    company_short_name character varying(50),
    logo_url character varying(500),
    logo_filename character varying(255),
    logo_storage_path character varying(500),
    favicon_url character varying(500),
    primary_color character varying(7) DEFAULT '#1F2937'::character varying,
    secondary_color character varying(7) DEFAULT '#3B82F6'::character varying,
    accent_color character varying(7) DEFAULT '#F59E0B'::character varying,
    text_color character varying(7) DEFAULT '#111827'::character varying,
    background_color character varying(7) DEFAULT '#FFFFFF'::character varying,
    border_color character varying(7) DEFAULT '#E5E7EB'::character varying,
    navbar_background character varying(7) DEFAULT '#1F2937'::character varying,
    navbar_text_color character varying(7) DEFAULT '#FFFFFF'::character varying,
    sidebar_background character varying(7) DEFAULT '#F9FAFB'::character varying,
    sidebar_text_color character varying(7) DEFAULT '#111827'::character varying,
    accent_hover_color character varying(7),
    success_color character varying(7) DEFAULT '#10B981'::character varying,
    warning_color character varying(7) DEFAULT '#F59E0B'::character varying,
    error_color character varying(7) DEFAULT '#EF4444'::character varying,
    info_color character varying(7) DEFAULT '#3B82F6'::character varying,
    font_family character varying(255) DEFAULT 'Inter, sans-serif'::character varying,
    font_size_base integer DEFAULT 16,
    border_radius integer DEFAULT 6,
    button_style character varying(50) DEFAULT 'rounded'::character varying,
    custom_css text,
    email_logo_url character varying(500),
    email_header_color character varying(7),
    email_footer_color character varying(7),
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: branding_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.branding_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: branding_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.branding_config_id_seq OWNED BY public.branding_config.id;


--
-- Name: company_info_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_info_master (
    id integer NOT NULL,
    name text NOT NULL,
    ntn_cnic text NOT NULL,
    province text NOT NULL,
    address text NOT NULL,
    fbr_sandbox_token text,
    fbr_production_token text,
    is_default boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: company_info_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.company_info_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_info_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.company_info_master_id_seq OWNED BY public.company_info_master.id;


--
-- Name: configuration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuration (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    description text,
    enabled boolean DEFAULT true NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: configuration_audit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuration_audit (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    changed_by integer,
    change_type character varying(50),
    entity_type character varying(100),
    entity_key character varying(255),
    old_value text,
    new_value text,
    change_reason character varying(500),
    ip_address character varying(45),
    user_agent text,
    status character varying(50) DEFAULT 'completed'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: configuration_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuration_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuration_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuration_audit_id_seq OWNED BY public.configuration_audit.id;


--
-- Name: configuration_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuration_id_seq OWNED BY public.configuration.id;


--
-- Name: custom_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_domains (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    domain_name character varying(255) NOT NULL,
    is_primary boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verification_code character varying(255),
    verified_at timestamp without time zone,
    ssl_certificate_path character varying(500),
    status character varying(50) DEFAULT 'pending'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: custom_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_domains_id_seq
    AS integer
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
-- Name: daily_delivery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_delivery (
    id integer NOT NULL,
    delivery_date date NOT NULL,
    party_id integer NOT NULL,
    challan_no text NOT NULL,
    sl text,
    gsm integer,
    quantity integer NOT NULL,
    net_weight numeric(12,3) NOT NULL,
    status text DEFAULT 'submitted'::text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reconciled boolean DEFAULT false NOT NULL,
    reconciled_transaction_id integer,
    reconciled_at timestamp without time zone,
    yarn_type_id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT daily_delivery_net_weight_check CHECK ((net_weight > (0)::numeric)),
    CONSTRAINT daily_delivery_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT daily_delivery_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: daily_delivery_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_delivery_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_delivery_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_delivery_id_seq OWNED BY public.daily_delivery.id;


--
-- Name: daily_production_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_production_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    roll_number integer NOT NULL,
    roll_weight numeric(10,3) NOT NULL,
    remarks text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT daily_production_detail_roll_weight_check CHECK ((roll_weight > (0)::numeric))
);


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_production_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_production_detail_id_seq OWNED BY public.daily_production_detail.id;


--
-- Name: daily_production_header; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_production_header (
    id integer NOT NULL,
    production_date date NOT NULL,
    machine_id integer NOT NULL,
    employee_id integer NOT NULL,
    party_id integer NOT NULL,
    shift public.shift NOT NULL,
    status text DEFAULT 'submitted'::text NOT NULL,
    remarks text,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reconciled boolean DEFAULT false NOT NULL,
    reconciled_transaction_id integer,
    reconciled_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT daily_production_header_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_production_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_production_header_id_seq OWNED BY public.daily_production_header.id;


--
-- Name: department_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: department_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_master_id_seq OWNED BY public.department_master.id;


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_templates (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    template_key character varying(100) NOT NULL,
    template_name character varying(255) NOT NULL,
    subject_line character varying(500),
    template_html text,
    template_text text,
    header_color character varying(7),
    footer_color character varying(7),
    include_logo boolean DEFAULT true,
    include_footer boolean DEFAULT true,
    custom_footer_text text,
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_templates_id_seq OWNED BY public.email_templates.id;


--
-- Name: employee_advances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_advances (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    date date NOT NULL,
    amount numeric NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: employee_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    department_id integer,
    base_salary numeric(10,2),
    overtime_rate_hr numeric(10,2),
    att_allowance numeric(10,2),
    oth_allowance numeric(10,2),
    active boolean DEFAULT true NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: employee_salary_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_salary_records (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    date date NOT NULL,
    base_wage numeric NOT NULL,
    commission numeric DEFAULT 0 NOT NULL,
    final_salary numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: employee_salary_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_salary_settings (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    base_daily_wage numeric DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: fabric_type_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fabric_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fabric_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fabric_type_master_id_seq OWNED BY public.fabric_type_master.id;


--
-- Name: factory_maintenance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.factory_maintenance (
    id integer NOT NULL,
    maintenance_date date NOT NULL,
    category text DEFAULT 'Other'::text NOT NULL,
    maintenance_work text NOT NULL,
    status text DEFAULT 'submitted'::text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT factory_maintenance_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: factory_maintenance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.factory_maintenance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: factory_maintenance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.factory_maintenance_id_seq OWNED BY public.factory_maintenance.id;


--
-- Name: feature_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feature_flags (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    feature_key character varying(100) NOT NULL,
    feature_name character varying(255) NOT NULL,
    description text,
    is_enabled boolean DEFAULT true,
    is_beta boolean DEFAULT false,
    category character varying(50),
    max_users integer,
    max_orders integer,
    max_storage_mb integer,
    max_api_calls_per_month integer,
    enabled_at timestamp without time zone,
    disabled_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: feature_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feature_flags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feature_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feature_flags_id_seq OWNED BY public.feature_flags.id;


--
-- Name: integration_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_settings (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    integration_key character varying(100) NOT NULL,
    integration_name character varying(255) NOT NULL,
    description text,
    is_enabled boolean DEFAULT false,
    is_configured boolean DEFAULT false,
    api_key character varying(255),
    api_secret character varying(255),
    webhook_url character varying(500),
    webhook_secret character varying(255),
    config_json jsonb,
    last_sync_at timestamp without time zone,
    last_error_message text,
    error_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: integration_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integration_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integration_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integration_settings_id_seq OWNED BY public.integration_settings.id;


--
-- Name: invoice; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice (
    id integer NOT NULL,
    invoice_date date NOT NULL,
    company_id integer NOT NULL,
    party_id integer NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    fbr_invoice_number text,
    fbr_status_code text,
    fbr_raw_response jsonb,
    total_value numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    total_tax numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    grand_total numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    posted_at timestamp without time zone,
    due_days integer,
    origin text DEFAULT 'fbr'::text,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoice_id_seq OWNED BY public.invoice.id;


--
-- Name: invoice_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_item (
    id integer NOT NULL,
    invoice_id integer NOT NULL,
    yarn_type_id integer NOT NULL,
    yarn_count_id integer,
    hs_code text,
    uom text,
    product_description text,
    quantity numeric(12,3) NOT NULL,
    rate_per_kg numeric(14,2) NOT NULL,
    value_excluding_tax numeric(14,2) NOT NULL,
    tax_amount numeric(14,2) NOT NULL,
    total_value numeric(14,2) NOT NULL,
    sale_type text DEFAULT 'Goods at standard rate (default)'::text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: invoice_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoice_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoice_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoice_item_id_seq OWNED BY public.invoice_item.id;


--
-- Name: invoice_payment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_payment (
    id integer NOT NULL,
    invoice_id integer NOT NULL,
    amount numeric(14,2) NOT NULL,
    tax_deduction numeric(14,2) DEFAULT 0 NOT NULL,
    payment_date date NOT NULL,
    method text,
    reference text,
    notes text,
    paid_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: invoice_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoice_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoice_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoice_payment_id_seq OWNED BY public.invoice_payment.id;


--
-- Name: invoice_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_transaction (
    id integer NOT NULL,
    invoice_id integer NOT NULL,
    transaction_header_id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: invoice_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoice_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoice_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoice_transaction_id_seq OWNED BY public.invoice_transaction.id;


--
-- Name: job_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    party_id integer,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: job_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_master_id_seq OWNED BY public.job_master.id;


--
-- Name: location_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: location_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_master_id_seq OWNED BY public.location_master.id;


--
-- Name: login_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_attempts (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    email character varying(255) NOT NULL,
    ip_address character varying(45) NOT NULL,
    attempt_count integer DEFAULT 1,
    status character varying(50) DEFAULT 'failed'::character varying,
    failure_reason character varying(255),
    is_locked boolean DEFAULT false,
    locked_until timestamp without time zone,
    lockout_reason character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: login_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_attempts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_attempts_id_seq OWNED BY public.login_attempts.id;


--
-- Name: logo_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logo_uploads (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    filename character varying(255) NOT NULL,
    original_filename character varying(255),
    file_type character varying(50),
    file_size integer,
    storage_url character varying(500),
    storage_path character varying(500),
    storage_provider character varying(50) DEFAULT 'local'::character varying,
    width integer,
    height integer,
    logo_type character varying(50) DEFAULT 'primary'::character varying,
    is_active boolean DEFAULT false,
    uploaded_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: logo_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logo_uploads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logo_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logo_uploads_id_seq OWNED BY public.logo_uploads.id;


--
-- Name: machine_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_history (
    id integer NOT NULL,
    machine_id integer,
    machine_number text NOT NULL,
    name text NOT NULL,
    making_rate numeric(10,2),
    needle_change_date date,
    needle_brand text,
    sinker_change_date date,
    sinker_brand text,
    action text NOT NULL,
    changed_by text NOT NULL,
    changed_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT machine_history_action_check CHECK ((action = ANY (ARRAY['created'::text, 'updated'::text, 'deleted'::text])))
);


--
-- Name: machine_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_history_id_seq OWNED BY public.machine_history.id;


--
-- Name: machine_maintenance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_maintenance (
    id integer NOT NULL,
    maintenance_date date NOT NULL,
    machine_id integer NOT NULL,
    maintenance_work text NOT NULL,
    cost numeric(12,3),
    vendor text,
    status text DEFAULT 'submitted'::text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT machine_maintenance_cost_check CHECK (((cost IS NULL) OR (cost >= (0)::numeric))),
    CONSTRAINT machine_maintenance_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: machine_maintenance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_maintenance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_maintenance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_maintenance_id_seq OWNED BY public.machine_maintenance.id;


--
-- Name: machine_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_master (
    id integer NOT NULL,
    name text NOT NULL,
    machine_number text NOT NULL,
    making_rate numeric(10,2) DEFAULT 3.75,
    needle_change_date date,
    needle_brand text DEFAULT 'Sigma'::text,
    sinker_change_date date,
    sinker_brand text DEFAULT 'Kohala'::text,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: machine_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_master_id_seq OWNED BY public.machine_master.id;


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_operator_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_operator_master_id_seq OWNED BY public.employee_master.id;


--
-- Name: oauth_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_providers (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    provider_name character varying(100) NOT NULL,
    provider_type character varying(50),
    client_id character varying(255),
    client_secret character varying(255),
    redirect_uri character varying(500),
    scope character varying(500),
    is_enabled boolean DEFAULT false,
    is_configured boolean DEFAULT false,
    config_json jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_providers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_providers_id_seq OWNED BY public.oauth_providers.id;


--
-- Name: operator_advances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_advances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_advances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_advances_id_seq OWNED BY public.employee_advances.id;


--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_salary_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_salary_records_id_seq OWNED BY public.employee_salary_records.id;


--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_salary_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_salary_settings_id_seq OWNED BY public.employee_salary_settings.id;


--
-- Name: party_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.party_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    waste_percent numeric(5,2) DEFAULT 1.00,
    ntn_cnic text,
    province text,
    address text,
    registration_type text DEFAULT 'Unregistered'::text,
    credit_days integer DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: party_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.party_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: party_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.party_master_id_seq OWNED BY public.party_master.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    user_id integer NOT NULL,
    reset_token character varying(500) NOT NULL,
    email character varying(255) NOT NULL,
    is_used boolean DEFAULT false,
    used_at timestamp without time zone,
    expires_at timestamp without time zone,
    ip_address character varying(45),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.password_reset_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.password_reset_tokens_id_seq OWNED BY public.password_reset_tokens.id;


--
-- Name: plausibility_baseline; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plausibility_baseline (
    id integer NOT NULL,
    operation text NOT NULL,
    field text NOT NULL,
    median numeric(18,6) NOT NULL,
    iqr numeric(18,6) NOT NULL,
    mad numeric(18,6) NOT NULL,
    lower_bound numeric(18,6) NOT NULL,
    upper_bound numeric(18,6) NOT NULL,
    sample_count integer DEFAULT 0 NOT NULL,
    computed_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plausibility_baseline_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plausibility_baseline_id_seq OWNED BY public.plausibility_baseline.id;


--
-- Name: plausibility_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plausibility_feedback (
    id integer NOT NULL,
    operation text NOT NULL,
    field text NOT NULL,
    entered_value numeric(18,6) NOT NULL,
    expected_low numeric(18,6),
    expected_high numeric(18,6),
    outcome text NOT NULL,
    created_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plausibility_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plausibility_feedback_id_seq OWNED BY public.plausibility_feedback.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role (
    id integer NOT NULL,
    name text NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT 1
);


--
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_id_seq OWNED BY public.role.id;


--
-- Name: role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permission (
    role_id integer NOT NULL,
    module_id text NOT NULL
);


--
-- Name: salary_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.salary_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    employee_id integer NOT NULL,
    month integer,
    year integer,
    department_id integer,
    employee_name text NOT NULL,
    basic_salary numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    ot_rate_hr numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    att_allowance numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    oth_allowance numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    present_days numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    absent_days numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    holidays numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    total_attendance numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    total_salary numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    ot_hours numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    ot_amount numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    advance_deduction numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    loan_deduction numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    other_deduction numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    payable_salary numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: salary_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.salary_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: salary_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.salary_detail_id_seq OWNED BY public.salary_detail.id;


--
-- Name: salary_header; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.salary_header (
    id integer NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    department_ids integer[] DEFAULT '{}'::integer[] NOT NULL,
    posted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: salary_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.salary_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: salary_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.salary_header_id_seq OWNED BY public.salary_header.id;


--
-- Name: session_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_settings (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    session_timeout_minutes integer DEFAULT 30,
    remember_me_enabled boolean DEFAULT true,
    remember_me_duration_days integer DEFAULT 30,
    max_concurrent_sessions integer DEFAULT 5,
    force_password_change_days integer DEFAULT 90,
    password_expiry_enabled boolean DEFAULT false,
    two_factor_required_for_admins boolean DEFAULT true,
    two_factor_optional_for_users boolean DEFAULT false,
    device_management_enabled boolean DEFAULT true,
    max_devices_per_user integer DEFAULT 5,
    ip_whitelist_enabled boolean DEFAULT false,
    ip_whitelist character varying(1000),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: session_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.session_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: session_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.session_settings_id_seq OWNED BY public.session_settings.id;


--
-- Name: system_defaults; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_defaults (
    id integer NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_name character varying(255) NOT NULL,
    setting_value text,
    data_type character varying(50),
    description text,
    is_readonly boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: system_defaults_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_defaults_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_defaults_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_defaults_id_seq OWNED BY public.system_defaults.id;


--
-- Name: tenant_admin_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_admin_assignments (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    admin_user_id integer NOT NULL,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    assigned_by integer,
    role character varying(50) DEFAULT 'super-admin'::character varying
);


--
-- Name: tenant_admin_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenant_admin_assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_admin_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenant_admin_assignments_id_seq OWNED BY public.tenant_admin_assignments.id;


--
-- Name: tenant_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_settings (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    company_registration_number character varying(255),
    company_tax_id character varying(255),
    company_bank_account character varying(255),
    company_phone character varying(20),
    company_email character varying(255),
    company_website character varying(255),
    company_address character varying(500),
    company_city character varying(100),
    company_province character varying(100),
    company_postal_code character varying(20),
    company_country character varying(100) DEFAULT 'Pakistan'::character varying,
    business_type character varying(100),
    industry_category character varying(100),
    employee_count integer,
    annual_revenue bigint,
    fiscal_year_start date,
    fiscal_year_end date,
    timezone character varying(50) DEFAULT 'Asia/Karachi'::character varying,
    currency character varying(10) DEFAULT 'PKR'::character varying,
    language character varying(10) DEFAULT 'ur'::character varying,
    date_format character varying(20) DEFAULT 'DD/MM/YYYY'::character varying,
    number_format character varying(20) DEFAULT '1,234.56'::character varying,
    tax_enabled boolean DEFAULT true,
    default_tax_rate numeric(5,2) DEFAULT 17.00,
    tax_method character varying(50) DEFAULT 'inclusive'::character varying,
    tax_number_format character varying(50) DEFAULT 'GST'::character varying,
    invoice_prefix character varying(20) DEFAULT 'INV'::character varying,
    invoice_start_number integer DEFAULT 1001,
    invoice_logo_position character varying(50) DEFAULT 'left'::character varying,
    invoice_terms_conditions text,
    invoice_payment_instructions text,
    email_from_name character varying(255),
    email_from_address character varying(255),
    email_reply_to character varying(255),
    smtp_enabled boolean DEFAULT false,
    smtp_host character varying(255),
    smtp_port integer DEFAULT 587,
    smtp_username character varying(255),
    smtp_password character varying(255),
    smtp_use_tls boolean DEFAULT true,
    send_invoice_notifications boolean DEFAULT true,
    send_order_notifications boolean DEFAULT true,
    send_payment_notifications boolean DEFAULT true,
    send_production_alerts boolean DEFAULT true,
    app_name character varying(255),
    support_email character varying(255),
    support_phone character varying(20),
    privacy_policy_url character varying(500),
    terms_conditions_url character varying(500),
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: tenant_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenant_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenant_settings_id_seq OWNED BY public.tenant_settings.id;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    industry character varying(100),
    country character varying(100) DEFAULT 'Pakistan'::character varying,
    timezone character varying(50) DEFAULT 'Asia/Karachi'::character varying,
    currency character varying(10) DEFAULT 'PKR'::character varying,
    language character varying(10) DEFAULT 'ur'::character varying,
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb
);


--
-- Name: tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants_id_seq OWNED BY public.tenants.id;


--
-- Name: theme_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.theme_presets (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    preset_name character varying(100) NOT NULL,
    preset_key character varying(50) NOT NULL,
    description text,
    primary_color character varying(7),
    secondary_color character varying(7),
    accent_color character varying(7),
    text_color character varying(7),
    background_color character varying(7),
    is_default boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    navbar_color text,
    navbar_text_color text,
    sidebar_color text,
    sidebar_text_color text,
    accent_hover_color text
);


--
-- Name: theme_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.theme_presets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: theme_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.theme_presets_id_seq OWNED BY public.theme_presets.id;


--
-- Name: transaction_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    quantity numeric(12,3),
    net_wt numeric(12,3),
    machine_id integer,
    employee_id integer,
    yarn_type_id integer,
    yarn_count_id integer,
    yarn_brand_id integer,
    uom_id integer,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_detail_id_seq OWNED BY public.transaction_detail.id;


--
-- Name: transaction_header; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_header (
    id integer NOT NULL,
    transaction_type_id integer NOT NULL,
    date date NOT NULL,
    doc_number text NOT NULL,
    job_id integer,
    party_id integer,
    location_id integer,
    fabric_type_id integer,
    sl text,
    gsm integer,
    reference text,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: transaction_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_header_id_seq OWNED BY public.transaction_header.id;


--
-- Name: transaction_type_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    action text,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_type_master_id_seq OWNED BY public.transaction_type_master.id;


--
-- Name: two_factor_auth; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.two_factor_auth (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    user_id integer NOT NULL,
    is_enabled boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verified_at timestamp without time zone,
    totp_secret character varying(255),
    totp_backup_codes text,
    phone_number character varying(20),
    phone_verified boolean DEFAULT false,
    sms_enabled boolean DEFAULT false,
    email_enabled boolean DEFAULT false,
    recovery_codes_generated_at timestamp without time zone,
    recovery_codes_used_count integer DEFAULT 0,
    last_verified_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: two_factor_auth_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.two_factor_auth_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: two_factor_auth_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.two_factor_auth_id_seq OWNED BY public.two_factor_auth.id;


--
-- Name: uom_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uom_master (
    id integer NOT NULL,
    name text NOT NULL,
    abbreviation text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: uom_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.uom_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: uom_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.uom_master_id_seq OWNED BY public.uom_master.id;


--
-- Name: user_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_invitations (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    invited_by integer NOT NULL,
    email character varying(255) NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    accepted_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    role text DEFAULT 'Manager'::text NOT NULL,
    token text NOT NULL,
    accepted_by integer,
    expires_at timestamp without time zone
);


--
-- Name: user_invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_invitations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_invitations_id_seq OWNED BY public.user_invitations.id;


--
-- Name: user_oauth_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_oauth_accounts (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    user_id integer NOT NULL,
    provider_name character varying(100) NOT NULL,
    provider_user_id character varying(255) NOT NULL,
    access_token character varying(500),
    refresh_token character varying(500),
    token_expires_at timestamp without time zone,
    linked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_oauth_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_oauth_accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_oauth_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_oauth_accounts_id_seq OWNED BY public.user_oauth_accounts.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    user_id integer NOT NULL,
    session_token character varying(500) NOT NULL,
    refresh_token character varying(500),
    device_name character varying(255),
    device_type character varying(50),
    ip_address character varying(45),
    user_agent text,
    is_active boolean DEFAULT true,
    last_activity_at timestamp without time zone,
    expires_at timestamp without time zone,
    two_factor_verified boolean DEFAULT false,
    verified_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: workflow_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_settings (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    workflow_key character varying(100) NOT NULL,
    workflow_name character varying(255) NOT NULL,
    description text,
    requires_approval boolean DEFAULT false,
    approval_level integer DEFAULT 1,
    auto_approve_threshold numeric(12,2),
    notification_on_step_change boolean DEFAULT true,
    step_sequence text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: workflow_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_settings_id_seq OWNED BY public.workflow_settings.id;


--
-- Name: yarn_brand_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_brand_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_brand_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_brand_master_id_seq OWNED BY public.yarn_brand_master.id;


--
-- Name: yarn_count_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_count_master (
    id integer NOT NULL,
    name text NOT NULL,
    count text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_count_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_count_master_id_seq OWNED BY public.yarn_count_master.id;


--
-- Name: yarn_receipt_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_receipt_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    yarn_count_id integer NOT NULL,
    quantity integer NOT NULL,
    net_weight numeric(12,3) NOT NULL,
    yarn_brand_id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT yarn_receipt_detail_net_weight_check CHECK ((net_weight > (0)::numeric)),
    CONSTRAINT yarn_receipt_detail_quantity_check CHECK ((quantity > 0))
);


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_receipt_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_receipt_detail_id_seq OWNED BY public.yarn_receipt_detail.id;


--
-- Name: yarn_receipt_header; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_receipt_header (
    id integer NOT NULL,
    receipt_date date NOT NULL,
    party_id integer NOT NULL,
    status text DEFAULT 'submitted'::text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reconciled boolean DEFAULT false NOT NULL,
    reconciled_transaction_id integer,
    reconciled_at timestamp without time zone,
    doc_number text NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    CONSTRAINT yarn_receipt_header_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_receipt_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_receipt_header_id_seq OWNED BY public.yarn_receipt_header.id;


--
-- Name: yarn_type_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    make_rate numeric,
    hs_code text,
    tenant_id integer DEFAULT 1 NOT NULL
);


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_type_master_id_seq OWNED BY public.yarn_type_master.id;


--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- Name: attendance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance ALTER COLUMN id SET DEFAULT nextval('public.attendance_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: auth_audit id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_audit ALTER COLUMN id SET DEFAULT nextval('public.auth_audit_id_seq'::regclass);


--
-- Name: branding_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branding_config ALTER COLUMN id SET DEFAULT nextval('public.branding_config_id_seq'::regclass);


--
-- Name: company_info_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_info_master ALTER COLUMN id SET DEFAULT nextval('public.company_info_master_id_seq'::regclass);


--
-- Name: configuration id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration ALTER COLUMN id SET DEFAULT nextval('public.configuration_id_seq'::regclass);


--
-- Name: configuration_audit id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration_audit ALTER COLUMN id SET DEFAULT nextval('public.configuration_audit_id_seq'::regclass);


--
-- Name: custom_domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains ALTER COLUMN id SET DEFAULT nextval('public.custom_domains_id_seq'::regclass);


--
-- Name: daily_delivery id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery ALTER COLUMN id SET DEFAULT nextval('public.daily_delivery_id_seq'::regclass);


--
-- Name: daily_production_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail ALTER COLUMN id SET DEFAULT nextval('public.daily_production_detail_id_seq'::regclass);


--
-- Name: daily_production_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header ALTER COLUMN id SET DEFAULT nextval('public.daily_production_header_id_seq'::regclass);


--
-- Name: department_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_master ALTER COLUMN id SET DEFAULT nextval('public.department_master_id_seq'::regclass);


--
-- Name: email_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates ALTER COLUMN id SET DEFAULT nextval('public.email_templates_id_seq'::regclass);


--
-- Name: employee_advances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_advances ALTER COLUMN id SET DEFAULT nextval('public.operator_advances_id_seq'::regclass);


--
-- Name: employee_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_master ALTER COLUMN id SET DEFAULT nextval('public.machine_operator_master_id_seq'::regclass);


--
-- Name: employee_salary_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_records_id_seq'::regclass);


--
-- Name: employee_salary_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_settings_id_seq'::regclass);


--
-- Name: fabric_type_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master ALTER COLUMN id SET DEFAULT nextval('public.fabric_type_master_id_seq'::regclass);


--
-- Name: factory_maintenance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factory_maintenance ALTER COLUMN id SET DEFAULT nextval('public.factory_maintenance_id_seq'::regclass);


--
-- Name: feature_flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags ALTER COLUMN id SET DEFAULT nextval('public.feature_flags_id_seq'::regclass);


--
-- Name: integration_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_settings ALTER COLUMN id SET DEFAULT nextval('public.integration_settings_id_seq'::regclass);


--
-- Name: invoice id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice ALTER COLUMN id SET DEFAULT nextval('public.invoice_id_seq'::regclass);


--
-- Name: invoice_item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item ALTER COLUMN id SET DEFAULT nextval('public.invoice_item_id_seq'::regclass);


--
-- Name: invoice_payment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_payment ALTER COLUMN id SET DEFAULT nextval('public.invoice_payment_id_seq'::regclass);


--
-- Name: invoice_transaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_transaction ALTER COLUMN id SET DEFAULT nextval('public.invoice_transaction_id_seq'::regclass);


--
-- Name: job_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master ALTER COLUMN id SET DEFAULT nextval('public.job_master_id_seq'::regclass);


--
-- Name: location_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_master ALTER COLUMN id SET DEFAULT nextval('public.location_master_id_seq'::regclass);


--
-- Name: login_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_attempts ALTER COLUMN id SET DEFAULT nextval('public.login_attempts_id_seq'::regclass);


--
-- Name: logo_uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logo_uploads ALTER COLUMN id SET DEFAULT nextval('public.logo_uploads_id_seq'::regclass);


--
-- Name: machine_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_history ALTER COLUMN id SET DEFAULT nextval('public.machine_history_id_seq'::regclass);


--
-- Name: machine_maintenance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_maintenance ALTER COLUMN id SET DEFAULT nextval('public.machine_maintenance_id_seq'::regclass);


--
-- Name: machine_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_master ALTER COLUMN id SET DEFAULT nextval('public.machine_master_id_seq'::regclass);


--
-- Name: oauth_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_providers ALTER COLUMN id SET DEFAULT nextval('public.oauth_providers_id_seq'::regclass);


--
-- Name: party_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master ALTER COLUMN id SET DEFAULT nextval('public.party_master_id_seq'::regclass);


--
-- Name: password_reset_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_reset_tokens_id_seq'::regclass);


--
-- Name: plausibility_baseline id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_baseline ALTER COLUMN id SET DEFAULT nextval('public.plausibility_baseline_id_seq'::regclass);


--
-- Name: plausibility_feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_feedback ALTER COLUMN id SET DEFAULT nextval('public.plausibility_feedback_id_seq'::regclass);


--
-- Name: role id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role ALTER COLUMN id SET DEFAULT nextval('public.role_id_seq'::regclass);


--
-- Name: salary_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail ALTER COLUMN id SET DEFAULT nextval('public.salary_detail_id_seq'::regclass);


--
-- Name: salary_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_header ALTER COLUMN id SET DEFAULT nextval('public.salary_header_id_seq'::regclass);


--
-- Name: session_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_settings ALTER COLUMN id SET DEFAULT nextval('public.session_settings_id_seq'::regclass);


--
-- Name: system_defaults id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_defaults ALTER COLUMN id SET DEFAULT nextval('public.system_defaults_id_seq'::regclass);


--
-- Name: tenant_admin_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_admin_assignments ALTER COLUMN id SET DEFAULT nextval('public.tenant_admin_assignments_id_seq'::regclass);


--
-- Name: tenant_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_settings ALTER COLUMN id SET DEFAULT nextval('public.tenant_settings_id_seq'::regclass);


--
-- Name: tenants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants ALTER COLUMN id SET DEFAULT nextval('public.tenants_id_seq'::regclass);


--
-- Name: theme_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theme_presets ALTER COLUMN id SET DEFAULT nextval('public.theme_presets_id_seq'::regclass);


--
-- Name: transaction_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail ALTER COLUMN id SET DEFAULT nextval('public.transaction_detail_id_seq'::regclass);


--
-- Name: transaction_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header ALTER COLUMN id SET DEFAULT nextval('public.transaction_header_id_seq'::regclass);


--
-- Name: transaction_type_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master ALTER COLUMN id SET DEFAULT nextval('public.transaction_type_master_id_seq'::regclass);


--
-- Name: two_factor_auth id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth ALTER COLUMN id SET DEFAULT nextval('public.two_factor_auth_id_seq'::regclass);


--
-- Name: uom_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master ALTER COLUMN id SET DEFAULT nextval('public.uom_master_id_seq'::regclass);


--
-- Name: user_invitations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_invitations ALTER COLUMN id SET DEFAULT nextval('public.user_invitations_id_seq'::regclass);


--
-- Name: user_oauth_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_oauth_accounts ALTER COLUMN id SET DEFAULT nextval('public.user_oauth_accounts_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: workflow_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_settings ALTER COLUMN id SET DEFAULT nextval('public.workflow_settings_id_seq'::regclass);


--
-- Name: yarn_brand_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_brand_master_id_seq'::regclass);


--
-- Name: yarn_count_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_count_master_id_seq'::regclass);


--
-- Name: yarn_receipt_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail ALTER COLUMN id SET DEFAULT nextval('public.yarn_receipt_detail_id_seq'::regclass);


--
-- Name: yarn_receipt_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header ALTER COLUMN id SET DEFAULT nextval('public.yarn_receipt_header_id_seq'::regclass);


--
-- Name: yarn_type_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_type_master_id_seq'::regclass);


--
-- Data for Name: _applied_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public._applied_migrations (name, applied_at) FROM stdin;
0000_late_living_tribunal.sql	2026-08-07 12:23:06.827453+00
0001_clumsy_the_spike.sql	2026-08-07 12:23:06.993293+00
0002_sweet_marrow.sql	2026-08-07 12:23:07.134481+00
0003_tearful_klaw.sql	2026-08-07 12:23:07.332609+00
0004_reconcile_daily_production.sql	2026-08-07 12:23:07.570993+00
0005_yarn_receipt.sql	2026-08-07 12:23:07.862902+00
0006_daily_delivery.sql	2026-08-07 12:23:08.028868+00
0007_rename_operator_to_employee.sql	2026-08-07 12:23:08.219926+00
0008_create_configuration.sql	2026-08-07 12:23:08.378242+00
0009_seed_configuration.sql	2026-08-07 12:23:08.548646+00
0010_plausibility_validation.sql	2026-08-11 06:43:15.097289+00
0011_maintenance_modules.sql	2026-08-11 21:20:57.143684+00
0012_machine_analytics_change_dates.sql	2026-08-11 22:58:46.437897+00
0013_fbr_invoicing.sql	2026-08-12 13:02:03.337388+00
0014_invoice_id_seed.sql	2026-08-12 20:28:20.196568+00
0015_user_management_rbac.sql	2026-08-13 19:58:33.674223+00
0016_date_columns_type_date.sql	2026-08-15 05:53:19.636844+00
0017_credit_days_payments.sql	2026-08-16 17:30:37.720922+00
0018_performance_indexes.sql	2026-08-17 10:04:49.797138+00
0019_machine_history.sql	2026-08-19 20:36:16.612181+00
0020_seed_machine_history.sql	2026-08-19 20:36:17.119676+00
0021_attendance.sql	2026-08-20 09:26:11.200565+00
0022_add_tenant_id.sql	2026-08-26 19:07:51.311043+00
0023_add_branding_config.sql	2026-08-26 19:07:52.034009+00
0024_add_configuration_system.sql	2026-08-26 19:07:52.849046+00
0025_add_auth_hardening.sql	2026-08-26 19:07:53.908669+00
0026_add_super_admin_role.sql	2026-08-26 19:07:54.483542+00
0027_reconcile_multi_tenant_schema.sql	2026-08-26 19:11:24.110701+00
0028_reconcile_theme_presets_and_invitations.sql	2026-08-26 19:36:47.282464+00
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.api_keys (id, tenant_id, label, key_hash, key_hint, last_used_at, expires_at, revoked_at, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_user (id, username, display_name, password_hash, role_id, employee_id, is_active, created_at, updated_at, tenant_id) FROM stdin;
4	hassanimam	Hassan Imam	$argon2id$v=19$m=65536,t=3,p=4$lIPw0HuW5aYPfcKvovWglA$uTvtFYf2bPT/nK7P+4xat9CaZ9X40lXTEHXAwLydVTA	2	\N	t	2026-08-14 10:58:13.371543	2026-08-14 10:58:13.371543	1
2	khurranhassan	Khurram Hassan	$argon2id$v=19$m=65536,t=3,p=4$b/w2NGtIlSCdBiEPSpQJtg$tLnKPABoyptuY32k0HU0KHkWwGrI3p9n3sia7+NdvJ4	2	\N	f	2026-08-14 10:56:53.242172	2026-08-14 10:58:56.538	1
5	khurramhassan	Khurram Hassan	$argon2id$v=19$m=65536,t=3,p=4$J9kPaVtTsAwfsDv9VVulAg$+Zmc0plbzRftGM6VqRGq9lkPVU+emmhpq0DMP0WqMBY	2	\N	t	2026-08-14 10:59:19.452899	2026-08-14 10:59:19.452899	1
6	tahirhassan	Tahir Hassan	$argon2id$v=19$m=65536,t=3,p=4$a17sl2Znzn5HUIfBkSEY/g$nmHLMcaU7XtN+JmqsWDhU5Q5guak87FfUJEiG4PmtXo	1	\N	t	2026-08-14 11:01:50.16956	2026-08-14 11:01:50.16956	1
3	iftikhar	Iftikhar Ahmed	$argon2id$v=19$m=65536,t=3,p=4$HnNB8pBD8jSUEb5yqsvCJQ$VTot2bTY0zOAH87K0Pv4x8BXxF7C/+zbRz5oisjsU0s	3	10	t	2026-08-14 10:57:48.772162	2026-08-17 06:29:47.322	1
1	admin	Administrator	$argon2id$v=19$m=65536,t=3,p=4$a1CQL2gbg+KObhCtXyWnKw$VvVr3t3pPUEpK5Bv4Qbe9dOKUfZ87OGCrzAWXt3Ac8o	6	\N	t	2026-08-14 10:51:30.060555	2026-08-14 10:51:30.060555	\N
\.


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.attendance (id, employee_id, attendance_date, present, created_at, updated_at, tenant_id) FROM stdin;
9771	15	2026-08-01	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9772	15	2026-08-02	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9773	15	2026-08-03	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9774	15	2026-08-04	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9775	15	2026-08-05	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9776	15	2026-08-06	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9777	15	2026-08-07	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9778	15	2026-08-08	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9779	15	2026-08-09	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9780	15	2026-08-10	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9781	15	2026-08-11	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9782	15	2026-08-12	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9783	15	2026-08-13	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9784	15	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9785	15	2026-08-15	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9786	15	2026-08-16	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9787	15	2026-08-17	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9788	15	2026-08-18	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9789	15	2026-08-19	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9790	15	2026-08-20	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9791	15	2026-08-21	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9792	15	2026-08-22	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9793	15	2026-08-23	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9794	15	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9795	15	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9796	15	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9797	15	2026-08-27	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9798	15	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9799	15	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9800	8	2026-08-09	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9801	8	2026-08-10	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9802	8	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9803	8	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9804	8	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9805	8	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9806	8	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9807	10	2026-08-01	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9808	10	2026-08-02	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9809	10	2026-08-03	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9810	10	2026-08-04	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9811	10	2026-08-05	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9812	10	2026-08-06	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9813	10	2026-08-07	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9814	10	2026-08-08	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9815	10	2026-08-09	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9816	10	2026-08-10	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9817	10	2026-08-11	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9818	10	2026-08-12	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9819	10	2026-08-13	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9820	10	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9821	10	2026-08-15	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9822	10	2026-08-16	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9823	10	2026-08-17	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9824	10	2026-08-18	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9825	10	2026-08-19	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9826	10	2026-08-20	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9827	10	2026-08-21	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9828	10	2026-08-22	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9829	10	2026-08-23	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9830	10	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9831	10	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9832	10	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9833	10	2026-08-27	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9834	10	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9835	10	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9836	11	2026-08-01	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9837	11	2026-08-02	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9838	11	2026-08-03	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9839	11	2026-08-04	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9840	11	2026-08-05	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9841	11	2026-08-06	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9842	11	2026-08-07	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9843	11	2026-08-08	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9844	11	2026-08-09	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9845	11	2026-08-10	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9846	11	2026-08-11	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9847	11	2026-08-12	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9848	11	2026-08-13	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9849	11	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9850	11	2026-08-15	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9851	11	2026-08-16	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9852	11	2026-08-17	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9853	11	2026-08-18	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9854	11	2026-08-19	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9855	11	2026-08-20	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9856	11	2026-08-21	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9857	11	2026-08-22	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9858	11	2026-08-23	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9859	11	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9860	11	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9861	11	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9862	11	2026-08-27	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9863	11	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9864	11	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9865	9	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9866	9	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9867	9	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9868	9	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9869	9	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9870	9	2026-08-29	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9871	12	2026-08-01	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9872	12	2026-08-02	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9873	12	2026-08-03	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9874	12	2026-08-04	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9875	12	2026-08-05	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9876	12	2026-08-06	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9877	12	2026-08-07	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9878	12	2026-08-08	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9879	12	2026-08-09	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9880	12	2026-08-10	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9881	12	2026-08-11	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9882	12	2026-08-12	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9883	12	2026-08-13	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9884	12	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9885	12	2026-08-15	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9886	12	2026-08-16	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9887	12	2026-08-17	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9888	12	2026-08-18	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9889	12	2026-08-19	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9890	12	2026-08-20	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9891	12	2026-08-21	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9892	12	2026-08-22	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9893	12	2026-08-23	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9894	12	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9895	12	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9896	12	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9897	12	2026-08-27	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9898	12	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9899	12	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9900	19	2026-08-01	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9901	19	2026-08-02	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9902	19	2026-08-03	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9903	19	2026-08-04	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9904	19	2026-08-05	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9905	19	2026-08-06	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9906	19	2026-08-07	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9907	19	2026-08-08	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9908	19	2026-08-09	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9909	19	2026-08-10	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9910	19	2026-08-11	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9911	19	2026-08-12	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9912	19	2026-08-13	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9913	19	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9914	19	2026-08-15	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9915	19	2026-08-16	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9916	19	2026-08-17	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9917	19	2026-08-18	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9918	19	2026-08-19	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9919	19	2026-08-20	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9920	19	2026-08-21	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9921	19	2026-08-22	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9922	19	2026-08-23	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9923	19	2026-08-24	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9924	19	2026-08-25	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9925	19	2026-08-26	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9926	19	2026-08-27	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9927	19	2026-08-28	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9928	19	2026-08-29	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9929	2	2026-08-09	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9930	2	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9931	2	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9932	2	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9933	2	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9934	2	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9935	2	2026-08-29	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9936	18	2026-08-03	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9937	18	2026-08-05	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9938	18	2026-08-06	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9939	18	2026-08-07	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9940	18	2026-08-08	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9941	18	2026-08-09	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9942	18	2026-08-12	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9943	18	2026-08-13	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9944	18	2026-08-14	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9945	18	2026-08-15	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9946	18	2026-08-16	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9947	18	2026-08-18	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9948	18	2026-08-19	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9949	18	2026-08-21	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9950	18	2026-08-22	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9951	18	2026-08-23	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9952	18	2026-08-24	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9953	18	2026-08-25	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9954	18	2026-08-26	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9955	18	2026-08-27	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9956	18	2026-08-28	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9957	18	2026-08-29	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9958	7	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9959	7	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9960	7	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9961	7	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9962	7	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9963	7	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9964	14	2026-08-01	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9965	14	2026-08-02	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9966	14	2026-08-03	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9967	14	2026-08-04	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9968	14	2026-08-05	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9969	14	2026-08-06	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9970	14	2026-08-07	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9971	14	2026-08-08	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9972	14	2026-08-09	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9973	14	2026-08-10	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9974	14	2026-08-11	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9975	14	2026-08-12	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9976	14	2026-08-13	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9977	14	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9978	14	2026-08-15	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9979	14	2026-08-16	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9980	14	2026-08-17	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9981	14	2026-08-18	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9982	14	2026-08-19	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9983	14	2026-08-20	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9984	14	2026-08-21	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9985	14	2026-08-22	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9986	14	2026-08-23	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9987	14	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9988	14	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9989	14	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9990	14	2026-08-27	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9991	14	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9992	14	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9993	3	2026-08-02	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9994	3	2026-08-03	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9995	3	2026-08-04	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9996	3	2026-08-05	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9997	3	2026-08-06	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9998	3	2026-08-07	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
9999	3	2026-08-08	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10000	3	2026-08-09	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10001	3	2026-08-10	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10002	3	2026-08-11	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10003	3	2026-08-12	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10004	3	2026-08-13	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10005	3	2026-08-14	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10006	3	2026-08-15	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10007	3	2026-08-16	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10008	3	2026-08-17	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10009	3	2026-08-18	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10010	3	2026-08-19	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10011	3	2026-08-20	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10012	3	2026-08-21	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10013	3	2026-08-22	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10014	3	2026-08-23	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10015	3	2026-08-24	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10016	3	2026-08-25	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10017	3	2026-08-26	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10018	3	2026-08-27	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10019	3	2026-08-28	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10020	3	2026-08-29	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10021	16	2026-08-01	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10022	16	2026-08-02	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10023	16	2026-08-03	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10024	16	2026-08-04	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10025	16	2026-08-05	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10026	16	2026-08-06	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10027	16	2026-08-07	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10028	16	2026-08-08	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10029	16	2026-08-09	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10030	16	2026-08-10	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10031	16	2026-08-11	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10032	16	2026-08-12	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10033	16	2026-08-13	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10034	16	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10035	16	2026-08-15	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10036	16	2026-08-16	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10037	16	2026-08-17	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10038	16	2026-08-18	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10039	16	2026-08-19	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10040	16	2026-08-20	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10041	16	2026-08-21	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10042	16	2026-08-22	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10043	16	2026-08-23	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10044	16	2026-08-24	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10045	16	2026-08-25	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10046	16	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10047	16	2026-08-27	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10048	16	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10049	16	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10050	17	2026-08-01	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10051	17	2026-08-02	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10052	17	2026-08-03	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10053	17	2026-08-04	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10054	17	2026-08-05	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10055	17	2026-08-06	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10056	17	2026-08-07	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10057	17	2026-08-08	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10058	17	2026-08-09	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10059	17	2026-08-10	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10060	17	2026-08-11	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10061	17	2026-08-12	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10062	17	2026-08-13	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10063	17	2026-08-14	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10064	17	2026-08-15	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10065	17	2026-08-16	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10066	17	2026-08-17	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10067	17	2026-08-18	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10068	17	2026-08-19	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10069	17	2026-08-20	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10070	17	2026-08-21	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10071	17	2026-08-22	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10072	17	2026-08-23	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10073	17	2026-08-24	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10074	17	2026-08-25	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10075	17	2026-08-26	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10076	17	2026-08-27	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10077	17	2026-08-28	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10078	17	2026-08-29	f	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10079	1	2026-08-14	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10080	1	2026-08-26	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10081	1	2026-08-28	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
10082	1	2026-08-29	t	2026-08-29 04:52:05.9183	2026-08-29 04:52:05.9183	1
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, actor_user_id, actor_tenant_id, target_tenant_id, action, entity_type, entity_id, description, before_json, after_json, ip_address, user_agent, created_at) FROM stdin;
1	1	\N	1	invite.create	user_invitation	1	Invited test-invite@example.com as Manager	\N	\N	\N	\N	2026-08-26 19:32:48.41714
2	6	\N	1	settings.update	tenant_settings	1	Company settings updated	\N	{"currency": "", "language": "ur", "timezone": "", "taxMethod": "inclusive", "dateFormat": "DD/MM/YYYY", "taxEnabled": true, "companyCity": "Karachi", "businessType": "Manufacturing", "companyEmail": "info@tkttextiles.com", "companyPhone": "+923200000000", "companyTaxId": "GST-123456789", "numberFormat": "1,234.56", "companyAddress": "TKT Complex, Karachi", "companyCountry": "Pakistan", "companyWebsite": null, "defaultTaxRate": "18", "companyProvince": null, "industryCategory": "Textile & Knitting", "companyPostalCode": null, "companyBankAccount": null, "companyRegistrationNumber": "TKT-001"}	\N	\N	2026-08-29 11:15:16.901894
\.


--
-- Data for Name: auth_audit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_audit (id, tenant_id, user_id, email, event_type, event_description, status, ip_address, user_agent, device_fingerprint, location_info, risk_level, suspicious_activity, created_at) FROM stdin;
\.


--
-- Data for Name: branding_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.branding_config (id, tenant_id, company_name, company_short_name, logo_url, logo_filename, logo_storage_path, favicon_url, primary_color, secondary_color, accent_color, text_color, background_color, border_color, navbar_background, navbar_text_color, sidebar_background, sidebar_text_color, accent_hover_color, success_color, warning_color, error_color, info_color, font_family, font_size_base, border_radius, button_style, custom_css, email_logo_url, email_header_color, email_footer_color, status, created_at, updated_at) FROM stdin;
1	1	TKT Textiles	TKT	/api/uploads/TKTLogo-543ff2bca692.png	TKTLogo.png	TKTLogo-543ff2bca692.png	\N	#0E7490	#06B6D4	#2DD4BF	#083344	#ECFEFF	#E5E7EB	#155E75	#FFFFFF	#164E63	#A5F3FC	#14B8A6	#10B981	#F59E0B	#EF4444	#3B82F6	Inter, sans-serif	16	6	pill	\N	\N	\N	\N	active	2026-08-26 19:07:51.881144	2026-08-26 19:07:51.881144
\.


--
-- Data for Name: company_info_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.company_info_master (id, name, ntn_cnic, province, address, fbr_sandbox_token, fbr_production_token, is_default, created_at, updated_at, tenant_id) FROM stdin;
1	TKT TEXTILES	4636080	Sindh	SHADE # 1-A, PLOT NO.L-39/1, BLOCK # 22, F.B. INDUSTRIAL AREA	0df2cdcf-d19a-34da-abf4-ca470c74a565	a20c225b-60e1-3d44-9966-41007b99d358	t	2026-08-12 17:58:06.278128	2026-08-12 17:58:06.278128	1
\.


--
-- Data for Name: configuration; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configuration (id, name, code, description, enabled, tenant_id) FROM stdin;
1	Reconciled lock	0001	used to enable/disable Reconciliation lock in daily operations	t	1
2	FBR DI Sandbox	0002	used to enable/disable FBR Digital Invoicing sandbox environment; when enabled invoices post to sandbox, when disabled they post to production	t	1
3	Allow Backdated Invoices	0003	when enabled, shows the manual "Create Backdated Invoice" tool to record invoices generated from another system	f	1
\.


--
-- Data for Name: configuration_audit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configuration_audit (id, tenant_id, changed_by, change_type, entity_type, entity_key, old_value, new_value, change_reason, ip_address, user_agent, status, created_at) FROM stdin;
\.


--
-- Data for Name: custom_domains; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.custom_domains (id, tenant_id, domain_name, is_primary, is_verified, verification_code, verified_at, ssl_certificate_path, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: daily_delivery; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_delivery (id, delivery_date, party_id, challan_no, sl, gsm, quantity, net_weight, status, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at, yarn_type_id, tenant_id) FROM stdin;
24	2026-08-10	13	3754	960+720+370	250	42	1116.150	submitted	Iftikhar 	2026-08-10 07:34:04.360986	\N	2026-08-10 07:34:04.360986	t	190	2026-08-10 10:30:29.442	20	1
27	2026-08-10	14	D-3757	940+640+384	345	27	759.350	submitted	Iftikhar 	2026-08-10 07:36:55.958949	\N	2026-08-10 07:36:55.958949	t	191	2026-08-10 10:36:36.152	20	1
25	2026-08-10	14	3755	940+662+395	345	36	1011.850	submitted	Iftikhar 	2026-08-10 07:34:59.665056	\N	2026-08-10 07:34:59.665056	t	191	2026-08-10 10:36:36.152	20	1
26	2026-08-10	14	3756	940+662+395	345	49	1391.000	submitted	Iftikhar 	2026-08-10 07:35:52.138509	\N	2026-08-10 07:35:52.138509	t	191	2026-08-10 10:36:36.152	20	1
7	2026-08-01	13	3735	960+720+370	250	27	694.750	submitted	Iftikhar 	2026-08-06 12:19:38.742471	\N	2026-08-06 12:19:38.742471	t	161	2026-08-07 12:37:27.219	20	1
8	2026-08-03	13	3736	960+720+370	250	47	1233.900	submitted	Iftikhar 	2026-08-06 12:21:22.753913	\N	2026-08-06 12:21:22.753913	t	162	2026-08-07 12:41:07.182	20	1
17	2026-08-03	15	3737	1020+740+410	\N	37	990.450	submitted	Iftikhar 	2026-08-06 13:28:50.974992	\N	2026-08-06 13:28:50.974992	t	163	2026-08-07 12:47:22.057	20	1
9	2026-08-04	13	3738	960+720+370	250	20	498.150	submitted	Iftikhar 	2026-08-06 12:22:22.726969	\N	2026-08-06 12:22:22.726969	t	170	2026-08-08 07:01:16.924	20	1
18	2026-08-04	20	3739	960+670+400	\N	2	39.700	submitted	Iftikhar 	2026-08-06 13:30:30.629482	\N	2026-08-06 13:30:30.629482	t	171	2026-08-08 07:02:25.572	20	1
11	2026-08-04	16	3740	820	\N	1	5.300	submitted	Iftikhar 	2026-08-06 13:13:02.850451	\N	2026-08-06 13:13:02.850451	t	172	2026-08-08 07:06:33.654	22	1
12	2026-08-04	16	3740	1160	\N	1	9.500	submitted	Iftikhar 	2026-08-06 13:14:18.421923	\N	2026-08-06 13:14:18.421923	t	172	2026-08-08 07:06:33.654	24	1
14	2026-08-04	16	3742	1060+730+410	\N	14	401.700	submitted	Iftikhar 	2026-08-06 13:17:32.154431	\N	2026-08-06 13:17:32.154431	t	172	2026-08-08 07:06:33.654	20	1
16	2026-08-04	16	3742	1160	\N	4	100.050	submitted	Iftikhar 	2026-08-06 13:19:53.154209	\N	2026-08-06 13:19:53.154209	t	172	2026-08-08 07:06:33.654	24	1
13	2026-08-04	16	3741	1160	\N	19	561.250	submitted	Iftikhar 	2026-08-06 13:15:38.784798	Iftikhar 	2026-08-06 13:20:56.385	t	172	2026-08-08 07:06:33.654	24	1
15	2026-08-04	16	3742	820	140	1	11.800	submitted	Iftikhar 	2026-08-06 13:18:53.501896	Iftikhar 	2026-08-06 13:21:15.74	t	172	2026-08-08 07:06:33.654	22	1
19	2026-08-04	17	3743	1050+700+405	210	18	439.850	submitted	Iftikhar 	2026-08-06 13:32:33.689048	\N	2026-08-06 13:32:33.689048	t	173	2026-08-08 07:07:55.163	20	1
3	2026-08-05	14	3744	940+662+395	250	58	1721.300	submitted	Iftikhar 	2026-08-06 10:11:17.157237	\N	2026-08-06 10:11:17.157237	t	174	2026-08-08 07:09:33.234	20	1
4	2026-08-05	14	3745	940+662+395	250	59	1717.850	submitted	Iftikhar 	2026-08-06 10:12:28.906007	\N	2026-08-06 10:12:28.906007	t	174	2026-08-08 07:09:33.234	20	1
10	2026-08-05	13	3746	960+720+370	250	15	384.800	submitted	Iftikhar 	2026-08-06 12:23:52.485668	\N	2026-08-06 12:23:52.485668	t	175	2026-08-08 07:12:14.027	20	1
5	2026-08-06	14	3747	940+662+395	250	50	1422.800	submitted	Iftikhar 	2026-08-06 10:13:52.292123	Iftikhar 	2026-08-06 13:23:26.528	t	176	2026-08-08 07:13:44.041	20	1
6	2026-08-06	14	3748	940+662+395	250	59	1663.250	submitted	Iftikhar 	2026-08-06 10:14:46.992303	Iftikhar 	2026-08-06 13:23:55.892	t	176	2026-08-08 07:13:44.041	20	1
2	2026-08-06	13	3749	960+720+370	245	22	599.300	submitted	Iftikhar 	2026-08-06 09:37:19.084532	Iftikhar 	2026-08-06 12:17:49.83	t	177	2026-08-08 07:15:21.916	20	1
20	2026-08-07	13	3750	960+720+370	250	25	672.600	submitted	Iftikhar 	2026-08-07 10:24:04.049319	\N	2026-08-07 10:24:04.049319	t	178	2026-08-08 07:16:19.208	20	1
21	2026-08-07	14	3751	940+640+384	342	52	1514.900	submitted	Iftikhar 	2026-08-07 11:07:58.052085	\N	2026-08-07 11:07:58.052085	t	179	2026-08-08 07:18:48.911	20	1
22	2026-08-07	14	3752	940+640+384	245	52	1518.400	submitted	Iftikhar 	2026-08-07 15:37:46.719266	\N	2026-08-07 15:37:46.719266	t	179	2026-08-08 07:18:48.911	20	1
23	2026-08-08	13	3753	960+720+370	250	25	671.800	submitted	Iftikhar 	2026-08-08 06:24:28.201474	\N	2026-08-08 06:24:28.201474	t	180	2026-08-08 07:19:38.526	20	1
28	2026-08-10	16	3758	1160	245	6	150.600	submitted	Iftikhar 	2026-08-10 14:00:45.636968	\N	2026-08-10 14:00:45.636968	t	199	2026-08-11 08:09:50.771	24	1
31	2026-08-11	16	3761	\N	\N	26	718.900	submitted	Iftikhar 	2026-08-11 11:10:58.071828	Tahir Hassan	2026-08-15 10:59:53.434	t	216	2026-08-15 11:09:20.759	24	1
32	2026-08-11	16	3762	1060+730+410	\N	10	270.650	submitted	Iftikhar 	2026-08-11 11:11:52.777587	Tahir Hassan	2026-08-15 10:59:57.537	t	217	2026-08-15 11:10:37.621	20	1
33	2026-08-13	14	3767	940+640+384	\N	56	1549.050	submitted	Iftikhar 	2026-08-13 08:03:37.872534	\N	2026-08-13 08:03:37.872534	t	218	2026-08-15 11:12:06.539	20	1
29	2026-08-11	13	3759	960+720+370	250	47	1137.500	submitted	Iftikhar 	2026-08-11 08:02:53.830219	\N	2026-08-11 08:02:53.830219	t	209	2026-08-13 09:39:39.487	20	1
41	2026-08-18	16	3774	820	140	1	10.000	submitted	Iftikhar Ahmed	2026-08-18 11:55:08.347932	\N	2026-08-18 11:55:08.347932	t	234	2026-08-19 07:36:58.451	22	1
42	2026-08-18	16	3774	820	\N	2	42.100	submitted	Iftikhar Ahmed	2026-08-18 11:55:59.775651	\N	2026-08-18 11:55:59.775651	t	235	2026-08-19 07:38:52.137	23	1
34	2026-08-13	14	3768	940+640+384	\N	50	1377.550	submitted	Iftikhar 	2026-08-13 08:04:21.240042	Tahir Hassan	2026-08-15 11:00:42.768	t	218	2026-08-15 11:12:06.539	20	1
30	2026-08-11	16	3760	1060+730+410	\N	60	1564.400	submitted	Iftikhar 	2026-08-11 11:09:58.933201	Iftikhar 	2026-08-12 10:27:12.968	t	215	2026-08-15 11:08:24.116	20	1
35	2026-08-13	16	3769	1160	\N	5	117.000	submitted	Iftikhar 	2026-08-13 10:17:45.783406	\N	2026-08-13 10:17:45.783406	t	219	2026-08-15 11:13:40.804	24	1
36	2026-08-13	16	3770	820	145	1	5.200	submitted	Iftikhar 	2026-08-13 10:18:47.014887	Tahir Hassan	2026-08-15 11:01:03.094	t	220	2026-08-15 11:15:00.318	22	1
37	2026-08-13	16	3770	1000+740+380	245	1	24.800	submitted	Iftikhar 	2026-08-13 10:19:44.871288	Tahir Hassan	2026-08-15 11:01:09.166	t	220	2026-08-15 11:15:00.318	20	1
38	2026-08-17	14	3771	940+640+384	340	49	1388.750	submitted	Iftikhar Ahmed	2026-08-17 07:19:50.870723	\N	2026-08-17 07:19:50.870723	t	224	2026-08-17 11:01:57.708	20	1
39	2026-08-17	14	3772	940+640+384	340	51	1429.200	submitted	Iftikhar Ahmed	2026-08-17 07:20:44.956228	\N	2026-08-17 07:20:44.956228	t	224	2026-08-17 11:01:57.708	20	1
40	2026-08-18	16	3774	1000+700+385	\N	9	243.300	submitted	Iftikhar Ahmed	2026-08-18 11:54:13.546052	\N	2026-08-18 11:54:13.546052	t	233	2026-08-19 07:33:50.419	20	1
43	2026-08-20	16	3776	1260	\N	1	10.750	submitted	Iftikhar Ahmed	2026-08-20 10:33:17.448924	\N	2026-08-20 10:33:17.448924	t	246	2026-08-21 07:10:08.082	24	1
44	2026-08-20	16	3777	820	\N	2	49.850	submitted	Iftikhar Ahmed	2026-08-20 10:34:08.062186	\N	2026-08-20 10:34:08.062186	t	247	2026-08-21 07:12:03.327	23	1
45	2026-08-20	16	3778	1000+700+385	255	19	506.750	submitted	Iftikhar Ahmed	2026-08-20 11:31:10.374656	\N	2026-08-20 11:31:10.374656	t	248	2026-08-21 07:15:06.271	20	1
46	2026-08-20	16	3778	820	\N	3	72.900	submitted	Iftikhar Ahmed	2026-08-20 11:31:54.570674	\N	2026-08-20 11:31:54.570674	t	249	2026-08-21 07:16:09.962	23	1
47	2026-08-22	16	3779	820	\N	15	425.850	submitted	Iftikhar Ahmed	2026-08-22 10:36:12.537865	\N	2026-08-22 10:36:12.537865	t	260	2026-08-24 10:09:51.712	22	1
48	2026-08-22	16	3779	820	\N	10	249.600	submitted	Iftikhar Ahmed	2026-08-22 10:37:06.586118	\N	2026-08-22 10:37:06.586118	t	261	2026-08-24 10:11:13.732	23	1
50	2026-08-22	16	3781	1000+700+385	245	4	111.650	submitted	Iftikhar Ahmed	2026-08-22 10:39:30.778698	\N	2026-08-22 10:39:30.778698	t	262	2026-08-24 10:13:44.661	20	1
49	2026-08-22	16	3780	1000+700+385	245	60	1645.950	submitted	Iftikhar Ahmed	2026-08-22 10:38:28.675594	\N	2026-08-22 10:38:28.675594	t	263	2026-08-24 10:15:48.57	20	1
51	2026-08-24	16	3783	\N	\N	40	1108.800	submitted	Iftikhar Ahmed	2026-08-24 13:57:11.671268	\N	2026-08-24 13:57:11.671268	t	266	2026-08-25 06:56:21.472	20	1
52	2026-08-24	16	3783	\N	\N	10	251.800	submitted	Iftikhar Ahmed	2026-08-24 13:57:56.404798	\N	2026-08-24 13:57:56.404798	t	267	2026-08-25 06:57:42.863	23	1
53	2026-08-24	16	3784	\N	\N	24	642.700	submitted	Iftikhar Ahmed	2026-08-24 13:58:32.704275	\N	2026-08-24 13:58:32.704275	t	268	2026-08-25 06:59:27.102	20	1
54	2026-08-25	17	3785	\N	\N	34	913.400	submitted	Iftikhar Ahmed	2026-08-25 11:10:01.614692	\N	2026-08-25 11:10:01.614692	t	272	2026-08-28 07:04:36.559	20	1
55	2026-08-25	17	3785	\N	\N	9	194.150	submitted	Iftikhar Ahmed	2026-08-25 11:11:00.752876	\N	2026-08-25 11:11:00.752876	t	272	2026-08-28 07:04:36.559	23	1
56	2026-08-25	17	3786	\N	\N	28	789.600	submitted	Iftikhar Ahmed	2026-08-25 11:11:45.082051	\N	2026-08-25 11:11:45.082051	t	272	2026-08-28 07:04:36.559	20	1
57	2026-08-25	17	3786	\N	\N	9	204.200	submitted	Iftikhar Ahmed	2026-08-25 11:12:35.03495	\N	2026-08-25 11:12:35.03495	t	272	2026-08-28 07:04:36.559	23	1
58	2026-08-25	17	3787	\N	\N	30	786.650	submitted	Iftikhar Ahmed	2026-08-25 11:13:35.366069	\N	2026-08-25 11:13:35.366069	t	272	2026-08-28 07:04:36.559	20	1
59	2026-08-25	17	3787	\N	\N	9	196.900	submitted	Iftikhar Ahmed	2026-08-25 11:14:27.498385	\N	2026-08-25 11:14:27.498385	t	272	2026-08-28 07:04:36.559	23	1
60	2026-08-27	16	3790	\N	\N	15	367.850	submitted	Iftikhar Ahmed	2026-08-27 14:18:28.533815	\N	2026-08-27 14:18:28.533815	t	273	2026-08-28 07:06:37.929	20	1
61	2026-08-27	16	3791	\N	\N	28	733.000	submitted	Iftikhar Ahmed	2026-08-27 14:19:17.40633	\N	2026-08-27 14:19:17.40633	t	273	2026-08-28 07:06:37.929	20	1
62	2026-08-27	16	3791	\N	\N	8	162.550	submitted	Iftikhar Ahmed	2026-08-27 14:19:59.577549	\N	2026-08-27 14:19:59.577549	t	273	2026-08-28 07:06:37.929	23	1
63	2026-08-29	15	3792	\N	\N	44	1212.800	submitted	Iftikhar Ahmed	2026-08-29 11:58:13.518339	\N	2026-08-29 11:58:13.518339	f	\N	\N	20	1
64	2026-08-29	16	3793	\N	\N	30	804.350	submitted	Iftikhar Ahmed	2026-08-29 13:43:24.635602	\N	2026-08-29 13:43:24.635602	f	\N	\N	20	1
65	2026-08-29	16	3793	\N	\N	5	119.500	submitted	Iftikhar Ahmed	2026-08-29 13:44:05.047381	\N	2026-08-29 13:44:05.047381	f	\N	\N	23	1
66	2026-08-29	16	3794	\N	\N	30	810.050	submitted	Iftikhar Ahmed	2026-08-29 13:44:56.516675	\N	2026-08-29 13:44:56.516675	f	\N	\N	20	1
67	2026-08-29	16	3794	\N	\N	5	117.800	submitted	Iftikhar Ahmed	2026-08-29 13:45:34.45745	\N	2026-08-29 13:45:34.45745	f	\N	\N	23	1
68	2026-08-29	16	3795	\N	\N	17	415.550	submitted	Iftikhar Ahmed	2026-08-29 13:46:10.857353	\N	2026-08-29 13:46:10.857353	f	\N	\N	22	1
\.


--
-- Data for Name: daily_production_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_production_detail (id, header_id, roll_number, roll_weight, remarks, created_at, tenant_id) FROM stdin;
1194	167	1	24.600	\N	2026-08-15 06:12:14.852552	1
1195	167	2	27.550	\N	2026-08-15 06:12:14.852552	1
1196	167	3	36.050	\N	2026-08-15 06:12:14.852552	1
1197	167	4	25.250	\N	2026-08-15 06:12:14.852552	1
1198	167	5	33.950	\N	2026-08-15 06:12:14.852552	1
1199	167	6	34.450	\N	2026-08-15 06:12:14.852552	1
1200	167	7	32.700	\N	2026-08-15 06:12:14.852552	1
1201	167	8	28.900	\N	2026-08-15 06:12:14.852552	1
13	4	1	28.000	\N	2026-08-04 09:10:42.87511	1
14	4	2	29.450	\N	2026-08-04 09:10:42.87511	1
15	4	3	28.800	\N	2026-08-04 09:10:42.87511	1
16	4	4	23.300	\N	2026-08-04 09:10:42.87511	1
17	4	5	29.150	\N	2026-08-04 09:10:42.87511	1
18	4	6	23.600	\N	2026-08-04 09:10:42.87511	1
21	6	1	31.150	\N	2026-08-04 09:18:31.354253	1
22	6	2	29.900	\N	2026-08-04 09:18:31.354253	1
23	6	3	26.100	\N	2026-08-04 09:18:31.354253	1
24	6	4	30.350	\N	2026-08-04 09:18:31.354253	1
25	6	5	27.350	\N	2026-08-04 09:18:31.354253	1
26	6	6	11.300	\N	2026-08-04 09:18:31.354253	1
27	7	1	27.300	\N	2026-08-04 09:20:23.329666	1
28	7	2	17.100	\N	2026-08-04 09:20:23.329666	1
29	7	3	16.050	\N	2026-08-04 09:20:23.329666	1
30	7	4	20.550	\N	2026-08-04 09:20:23.329666	1
31	7	5	25.700	\N	2026-08-04 09:20:23.329666	1
32	7	6	21.300	\N	2026-08-04 09:20:23.329666	1
33	7	7	20.400	\N	2026-08-04 09:20:23.329666	1
36	5	1	29.250	\N	2026-08-04 09:23:18.321417	1
37	5	2	28.200	\N	2026-08-04 09:23:18.321417	1
38	5	3	30.850	\N	2026-08-04 09:23:18.321417	1
39	8	1	28.750	\N	2026-08-04 09:25:40.653893	1
40	8	2	35.100	\N	2026-08-04 09:25:40.653893	1
41	8	3	28.800	\N	2026-08-04 09:25:40.653893	1
42	8	4	28.300	\N	2026-08-04 09:25:40.653893	1
43	8	5	32.200	\N	2026-08-04 09:25:40.653893	1
44	8	6	21.750	\N	2026-08-04 09:25:40.653893	1
45	9	1	26.000	\N	2026-08-04 09:27:15.003235	1
46	9	2	27.700	\N	2026-08-04 09:27:15.003235	1
47	9	3	22.700	\N	2026-08-04 09:27:15.003235	1
48	9	4	29.400	\N	2026-08-04 09:27:15.003235	1
49	9	5	29.400	\N	2026-08-04 09:27:15.003235	1
50	9	6	25.850	\N	2026-08-04 09:27:15.003235	1
51	10	1	26.650	\N	2026-08-04 09:28:57.85111	1
52	10	2	28.300	\N	2026-08-04 09:28:57.85111	1
53	10	3	23.900	\N	2026-08-04 09:28:57.85111	1
54	10	4	19.900	\N	2026-08-04 09:28:57.85111	1
55	10	5	27.300	\N	2026-08-04 09:28:57.85111	1
56	10	6	19.200	\N	2026-08-04 09:28:57.85111	1
57	10	7	22.650	\N	2026-08-04 09:28:57.85111	1
58	11	1	19.150	\N	2026-08-04 09:30:40.700423	1
59	11	2	29.650	\N	2026-08-04 09:30:40.700423	1
60	11	3	29.450	\N	2026-08-04 09:30:40.700423	1
61	11	4	29.800	\N	2026-08-04 09:30:40.700423	1
62	11	5	15.300	\N	2026-08-04 09:30:40.700423	1
63	11	6	25.100	\N	2026-08-04 09:30:40.700423	1
64	12	1	30.700	\N	2026-08-04 09:34:40.40951	1
65	12	2	27.750	\N	2026-08-04 09:34:40.40951	1
66	12	3	36.850	\N	2026-08-04 09:34:40.40951	1
67	12	4	27.850	\N	2026-08-04 09:34:40.40951	1
68	12	5	27.800	\N	2026-08-04 09:34:40.40951	1
69	12	6	27.750	\N	2026-08-04 09:34:40.40951	1
70	12	7	27.700	\N	2026-08-04 09:34:40.40951	1
71	13	1	26.750	\N	2026-08-04 09:36:49.21394	1
72	13	2	26.150	\N	2026-08-04 09:36:49.21394	1
73	13	3	28.100	\N	2026-08-04 09:36:49.21394	1
74	13	4	28.100	\N	2026-08-04 09:36:49.21394	1
75	13	5	29.500	\N	2026-08-04 09:36:49.21394	1
76	13	6	26.900	\N	2026-08-04 09:36:49.21394	1
77	13	7	28.150	\N	2026-08-04 09:36:49.21394	1
78	13	8	29.350	\N	2026-08-04 09:36:49.21394	1
79	13	9	28.200	\N	2026-08-04 09:36:49.21394	1
80	14	1	28.900	\N	2026-08-04 09:37:42.188473	1
81	14	2	28.600	\N	2026-08-04 09:37:42.188473	1
82	14	3	28.750	\N	2026-08-04 09:37:42.188473	1
83	14	4	29.900	\N	2026-08-04 09:37:42.188473	1
84	15	1	26.400	\N	2026-08-04 09:40:48.902839	1
85	15	2	25.200	\N	2026-08-04 09:40:48.902839	1
86	15	3	25.700	\N	2026-08-04 09:40:48.902839	1
87	15	4	27.300	\N	2026-08-04 09:40:48.902839	1
90	17	1	29.550	\N	2026-08-04 09:45:30.288701	1
91	17	2	26.100	\N	2026-08-04 09:45:30.288701	1
92	17	3	24.700	\N	2026-08-04 09:45:30.288701	1
93	17	4	31.400	\N	2026-08-04 09:45:30.288701	1
94	17	5	27.550	\N	2026-08-04 09:45:30.288701	1
95	17	6	31.600	\N	2026-08-04 09:45:30.288701	1
96	17	7	29.550	\N	2026-08-04 09:45:30.288701	1
97	17	8	29.950	\N	2026-08-04 09:45:30.288701	1
98	18	1	33.750	\N	2026-08-04 09:46:52.771207	1
99	18	2	30.650	\N	2026-08-04 09:46:52.771207	1
100	18	3	25.900	\N	2026-08-04 09:46:52.771207	1
101	18	4	32.350	\N	2026-08-04 09:46:52.771207	1
102	18	5	30.600	\N	2026-08-04 09:46:52.771207	1
103	19	1	11.500	\N	2026-08-04 09:54:11.999346	1
104	19	2	24.800	\N	2026-08-04 09:54:11.999346	1
105	19	3	27.000	\N	2026-08-04 09:54:11.999346	1
106	19	4	27.050	\N	2026-08-04 09:54:11.999346	1
107	19	5	24.900	\N	2026-08-04 09:54:11.999346	1
108	19	6	27.900	\N	2026-08-04 09:54:11.999346	1
109	19	7	25.200	\N	2026-08-04 09:54:11.999346	1
110	19	8	25.850	\N	2026-08-04 09:54:11.999346	1
118	21	1	27.600	\N	2026-08-04 10:01:26.358251	1
119	21	2	28.750	\N	2026-08-04 10:01:26.358251	1
120	21	3	24.800	\N	2026-08-04 10:01:26.358251	1
121	21	4	30.950	\N	2026-08-04 10:01:26.358251	1
122	21	5	29.900	\N	2026-08-04 10:01:26.358251	1
123	21	6	29.400	\N	2026-08-04 10:01:26.358251	1
124	21	7	29.900	\N	2026-08-04 10:01:26.358251	1
125	22	1	29.500	\N	2026-08-04 10:02:51.515396	1
126	22	2	29.650	\N	2026-08-04 10:02:51.515396	1
127	22	3	29.500	\N	2026-08-04 10:02:51.515396	1
128	22	4	25.850	\N	2026-08-04 10:02:51.515396	1
129	22	5	34.700	\N	2026-08-04 10:02:51.515396	1
130	22	6	32.300	\N	2026-08-04 10:02:51.515396	1
131	22	7	29.500	\N	2026-08-04 10:02:51.515396	1
132	22	8	29.050	\N	2026-08-04 10:02:51.515396	1
133	22	9	26.750	\N	2026-08-04 10:02:51.515396	1
138	23	1	31.150	\N	2026-08-04 10:05:41.440994	1
139	23	2	28.400	\N	2026-08-04 10:05:41.440994	1
140	23	3	27.900	\N	2026-08-04 10:05:41.440994	1
141	23	4	28.850	\N	2026-08-04 10:05:41.440994	1
142	23	5	31.500	\N	2026-08-04 10:05:41.440994	1
143	23	6	26.850	\N	2026-08-04 10:05:41.440994	1
144	24	1	21.300	\N	2026-08-04 10:06:51.146146	1
145	24	2	25.050	\N	2026-08-04 10:06:51.146146	1
146	24	3	27.500	\N	2026-08-04 10:06:51.146146	1
147	24	4	28.850	\N	2026-08-04 10:06:51.146146	1
148	25	1	27.950	\N	2026-08-04 10:07:59.206754	1
149	25	2	28.100	\N	2026-08-04 10:07:59.206754	1
150	25	3	23.000	\N	2026-08-04 10:07:59.206754	1
151	25	4	23.450	\N	2026-08-04 10:07:59.206754	1
152	25	5	26.050	\N	2026-08-04 10:07:59.206754	1
153	25	6	20.000	\N	2026-08-04 10:07:59.206754	1
154	25	7	22.650	\N	2026-08-04 10:07:59.206754	1
155	25	8	28.150	\N	2026-08-04 10:07:59.206754	1
156	26	1	25.450	\N	2026-08-04 10:08:59.403701	1
157	26	2	29.000	\N	2026-08-04 10:08:59.403701	1
158	26	3	28.250	\N	2026-08-04 10:08:59.403701	1
159	26	4	20.850	\N	2026-08-04 10:08:59.403701	1
160	26	5	28.350	\N	2026-08-04 10:08:59.403701	1
161	26	6	18.850	\N	2026-08-04 10:08:59.403701	1
162	27	1	30.200	\N	2026-08-04 10:10:14.184358	1
163	27	2	30.000	\N	2026-08-04 10:10:14.184358	1
164	27	3	26.350	\N	2026-08-04 10:10:14.184358	1
165	27	4	25.850	\N	2026-08-04 10:10:14.184358	1
166	27	5	17.350	\N	2026-08-04 10:10:14.184358	1
167	27	6	28.350	\N	2026-08-04 10:10:14.184358	1
168	27	7	28.100	\N	2026-08-04 10:10:14.184358	1
169	28	1	30.200	\N	2026-08-04 10:11:18.644384	1
170	28	2	19.950	\N	2026-08-04 10:11:18.644384	1
171	28	3	29.500	\N	2026-08-04 10:11:18.644384	1
172	28	4	30.200	\N	2026-08-04 10:11:18.644384	1
173	28	5	28.950	\N	2026-08-04 10:11:18.644384	1
174	28	6	28.750	\N	2026-08-04 10:11:18.644384	1
175	29	1	31.500	\N	2026-08-04 10:44:10.948865	1
176	29	2	31.700	\N	2026-08-04 10:44:10.948865	1
177	29	3	35.950	\N	2026-08-04 10:44:10.948865	1
178	29	4	27.300	\N	2026-08-04 10:44:10.948865	1
179	29	5	28.950	\N	2026-08-04 10:44:10.948865	1
180	29	6	26.950	\N	2026-08-04 10:44:10.948865	1
181	29	7	29.000	\N	2026-08-04 10:44:10.948865	1
183	31	1	33.100	\N	2026-08-04 11:02:23.167923	1
184	31	2	29.550	\N	2026-08-04 11:02:23.167923	1
185	31	3	30.850	\N	2026-08-04 11:02:23.167923	1
186	31	4	29.150	\N	2026-08-04 11:02:23.167923	1
187	31	5	30.400	\N	2026-08-04 11:02:23.167923	1
188	31	6	32.450	\N	2026-08-04 11:02:23.167923	1
189	31	7	29.850	\N	2026-08-04 11:02:23.167923	1
190	31	8	28.100	\N	2026-08-04 11:02:23.167923	1
191	32	1	25.200	\N	2026-08-04 11:03:01.847261	1
192	32	2	31.050	\N	2026-08-04 11:03:01.847261	1
193	33	1	23.800	\N	2026-08-04 11:04:36.849782	1
194	34	1	30.850	\N	2026-08-04 11:05:46.793537	1
195	34	2	28.950	\N	2026-08-04 11:05:46.793537	1
196	34	3	29.400	\N	2026-08-04 11:05:46.793537	1
197	34	4	32.300	\N	2026-08-04 11:05:46.793537	1
198	34	5	25.700	\N	2026-08-04 11:05:46.793537	1
199	34	6	30.850	\N	2026-08-04 11:05:46.793537	1
200	34	7	31.650	\N	2026-08-04 11:05:46.793537	1
201	35	1	16.450	\N	2026-08-04 11:06:46.274667	1
202	35	2	26.550	\N	2026-08-04 11:06:46.274667	1
203	35	3	34.150	\N	2026-08-04 11:06:46.274667	1
204	35	4	31.000	\N	2026-08-04 11:06:46.274667	1
205	36	1	20.000	\N	2026-08-04 11:07:56.979945	1
206	36	2	25.200	\N	2026-08-04 11:07:56.979945	1
207	36	3	27.150	\N	2026-08-04 11:07:56.979945	1
208	36	4	25.500	\N	2026-08-04 11:07:56.979945	1
209	36	5	23.550	\N	2026-08-04 11:07:56.979945	1
210	36	6	27.400	\N	2026-08-04 11:07:56.979945	1
211	36	7	26.250	\N	2026-08-04 11:07:56.979945	1
212	36	8	9.900	\N	2026-08-04 11:07:56.979945	1
213	37	1	35.450	\N	2026-08-04 11:08:47.644403	1
214	37	2	28.250	\N	2026-08-04 11:08:47.644403	1
215	37	3	27.450	\N	2026-08-04 11:08:47.644403	1
216	38	1	29.300	\N	2026-08-04 11:10:01.18467	1
217	38	2	29.450	\N	2026-08-04 11:10:01.18467	1
218	38	3	29.600	\N	2026-08-04 11:10:01.18467	1
219	38	4	29.650	\N	2026-08-04 11:10:01.18467	1
220	38	5	21.300	\N	2026-08-04 11:10:01.18467	1
221	38	6	28.150	\N	2026-08-04 11:10:01.18467	1
222	39	1	29.650	\N	2026-08-04 11:14:57.548808	1
223	39	2	29.750	\N	2026-08-04 11:14:57.548808	1
224	39	3	29.550	\N	2026-08-04 11:14:57.548808	1
225	39	4	29.550	\N	2026-08-04 11:14:57.548808	1
226	39	5	29.750	\N	2026-08-04 11:14:57.548808	1
227	39	6	29.650	\N	2026-08-04 11:14:57.548808	1
228	39	7	24.200	\N	2026-08-04 11:14:57.548808	1
229	39	8	26.550	\N	2026-08-04 11:14:57.548808	1
230	39	9	28.050	\N	2026-08-04 11:14:57.548808	1
231	40	1	30.400	\N	2026-08-04 11:15:49.435534	1
232	40	2	32.000	\N	2026-08-04 11:15:49.435534	1
233	40	3	30.250	\N	2026-08-04 11:15:49.435534	1
234	40	4	31.000	\N	2026-08-04 11:15:49.435534	1
235	40	5	33.500	\N	2026-08-04 11:15:49.435534	1
236	41	1	21.750	\N	2026-08-04 11:16:54.358067	1
237	41	2	29.500	\N	2026-08-04 11:16:54.358067	1
238	41	3	21.850	\N	2026-08-04 11:16:54.358067	1
239	41	4	29.650	\N	2026-08-04 11:16:54.358067	1
240	41	5	16.400	\N	2026-08-04 11:16:54.358067	1
241	42	1	26.250	\N	2026-08-04 11:18:01.178238	1
242	42	2	26.000	\N	2026-08-04 11:18:01.178238	1
243	42	3	28.550	\N	2026-08-04 11:18:01.178238	1
244	42	4	29.850	\N	2026-08-04 11:18:01.178238	1
245	42	5	32.700	\N	2026-08-04 11:18:01.178238	1
246	42	6	32.100	\N	2026-08-04 11:18:01.178238	1
247	42	7	17.000	\N	2026-08-04 11:18:01.178238	1
248	43	1	26.500	\N	2026-08-04 11:18:37.003406	1
249	43	2	33.000	\N	2026-08-04 11:18:37.003406	1
250	43	3	30.350	\N	2026-08-04 11:18:37.003406	1
251	44	1	29.850	\N	2026-08-04 11:19:37.030411	1
252	44	2	28.400	\N	2026-08-04 11:19:37.030411	1
253	44	3	28.200	\N	2026-08-04 11:19:37.030411	1
254	44	4	27.000	\N	2026-08-04 11:19:37.030411	1
255	44	5	24.200	\N	2026-08-04 11:19:37.030411	1
256	44	6	24.700	\N	2026-08-04 11:19:37.030411	1
257	45	1	32.950	\N	2026-08-04 11:21:22.562363	1
258	45	2	33.400	\N	2026-08-04 11:21:22.562363	1
259	45	3	27.800	\N	2026-08-04 11:21:22.562363	1
260	45	4	25.900	\N	2026-08-04 11:21:22.562363	1
261	45	5	29.250	\N	2026-08-04 11:21:22.562363	1
262	45	6	27.250	\N	2026-08-04 11:21:22.562363	1
263	45	7	32.950	\N	2026-08-04 11:21:22.562363	1
264	46	1	32.750	\N	2026-08-04 11:22:21.680401	1
265	46	2	33.300	\N	2026-08-04 11:22:21.680401	1
266	46	3	34.250	\N	2026-08-04 11:22:21.680401	1
267	46	4	28.200	\N	2026-08-04 11:22:21.680401	1
268	46	5	28.050	\N	2026-08-04 11:22:21.680401	1
269	46	6	29.600	\N	2026-08-04 11:22:21.680401	1
270	46	7	30.450	\N	2026-08-04 11:22:21.680401	1
271	46	8	36.000	\N	2026-08-04 11:22:21.680401	1
272	47	1	22.800	\N	2026-08-04 11:23:27.891391	1
273	47	2	22.850	\N	2026-08-04 11:23:27.891391	1
274	47	3	28.750	\N	2026-08-04 11:23:27.891391	1
275	47	4	30.550	\N	2026-08-04 11:23:27.891391	1
276	47	5	31.000	\N	2026-08-04 11:23:27.891391	1
277	47	6	29.750	\N	2026-08-04 11:23:27.891391	1
278	47	7	29.300	\N	2026-08-04 11:23:27.891391	1
279	47	8	28.800	\N	2026-08-04 11:23:27.891391	1
280	48	1	21.800	\N	2026-08-04 11:24:21.364634	1
281	48	2	24.000	\N	2026-08-04 11:24:21.364634	1
282	48	3	27.200	\N	2026-08-04 11:24:21.364634	1
283	48	4	27.700	\N	2026-08-04 11:24:21.364634	1
284	48	5	26.300	\N	2026-08-04 11:24:21.364634	1
285	49	1	19.000	\N	2026-08-04 11:25:27.95248	1
286	49	2	32.450	\N	2026-08-04 11:25:27.95248	1
287	49	3	25.900	\N	2026-08-04 11:25:27.95248	1
288	49	4	32.000	\N	2026-08-04 11:25:27.95248	1
289	49	5	22.800	\N	2026-08-04 11:25:27.95248	1
290	49	6	25.800	\N	2026-08-04 11:25:27.95248	1
291	49	7	31.150	\N	2026-08-04 11:25:27.95248	1
292	49	8	29.250	\N	2026-08-04 11:25:27.95248	1
293	50	1	19.600	\N	2026-08-04 11:26:53.291837	1
294	50	2	19.650	\N	2026-08-04 11:26:53.291837	1
295	50	3	26.300	\N	2026-08-04 11:26:53.291837	1
296	50	4	25.850	\N	2026-08-04 11:26:53.291837	1
297	50	5	28.200	\N	2026-08-04 11:26:53.291837	1
298	50	6	27.450	\N	2026-08-04 11:26:53.291837	1
299	50	7	25.550	\N	2026-08-04 11:26:53.291837	1
300	50	8	27.000	\N	2026-08-04 11:26:53.291837	1
301	16	1	25.600	\N	2026-08-04 13:45:14.162052	1
302	16	2	14.100	\N	2026-08-04 13:45:14.162052	1
1202	168	1	28.150	\N	2026-08-16 07:15:31.554374	1
1203	168	2	29.000	\N	2026-08-16 07:15:31.554374	1
1204	168	3	28.700	\N	2026-08-16 07:15:31.554374	1
1205	168	4	24.950	\N	2026-08-16 07:15:31.554374	1
1206	168	5	27.750	\N	2026-08-16 07:15:31.554374	1
1207	168	6	27.400	\N	2026-08-16 07:15:31.554374	1
1208	168	7	29.350	\N	2026-08-16 07:15:31.554374	1
318	53	1	28.500	\N	2026-08-05 05:19:28.381793	1
319	53	2	28.750	\N	2026-08-05 05:19:28.381793	1
320	53	3	20.050	\N	2026-08-05 05:19:28.381793	1
321	53	4	30.050	\N	2026-08-05 05:19:28.381793	1
322	53	5	34.200	\N	2026-08-05 05:19:28.381793	1
323	53	6	32.950	\N	2026-08-05 05:19:28.381793	1
324	53	7	35.650	\N	2026-08-05 05:19:28.381793	1
325	54	1	15.100	\N	2026-08-05 05:20:10.782671	1
1254	176	1	30.200	\N	2026-08-16 07:25:54.684036	1
1255	176	2	30.600	\N	2026-08-16 07:25:54.684036	1
1256	176	3	30.250	\N	2026-08-16 07:25:54.684036	1
1257	176	4	31.600	\N	2026-08-16 07:25:54.684036	1
332	56	1	28.800	\N	2026-08-05 05:22:54.381768	1
333	56	2	27.600	\N	2026-08-05 05:22:54.381768	1
334	56	3	29.450	\N	2026-08-05 05:22:54.381768	1
335	56	4	28.900	\N	2026-08-05 05:22:54.381768	1
336	56	5	27.750	\N	2026-08-05 05:22:54.381768	1
337	56	6	26.050	\N	2026-08-05 05:22:54.381768	1
338	56	7	25.650	\N	2026-08-05 05:22:54.381768	1
339	57	1	32.050	\N	2026-08-05 05:23:56.914664	1
340	57	2	32.050	\N	2026-08-05 05:23:56.914664	1
341	57	3	35.600	\N	2026-08-05 05:23:56.914664	1
342	57	4	32.100	\N	2026-08-05 05:23:56.914664	1
343	57	5	34.250	\N	2026-08-05 05:23:56.914664	1
344	57	6	33.500	\N	2026-08-05 05:23:56.914664	1
345	57	7	31.300	\N	2026-08-05 05:23:56.914664	1
346	57	8	35.200	\N	2026-08-05 05:23:56.914664	1
347	58	1	20.000	\N	2026-08-05 05:25:07.609832	1
348	58	2	23.100	\N	2026-08-05 05:25:07.609832	1
349	58	3	31.450	\N	2026-08-05 05:25:07.609832	1
350	58	4	33.950	\N	2026-08-05 05:25:07.609832	1
351	58	5	31.350	\N	2026-08-05 05:25:07.609832	1
352	58	6	34.300	\N	2026-08-05 05:25:07.609832	1
353	58	7	33.650	\N	2026-08-05 05:25:07.609832	1
354	58	8	32.800	\N	2026-08-05 05:25:07.609832	1
355	58	9	35.050	\N	2026-08-05 05:25:07.609832	1
356	59	1	26.550	\N	2026-08-05 05:26:18.500287	1
357	59	2	26.400	\N	2026-08-05 05:26:18.500287	1
358	59	3	26.800	\N	2026-08-05 05:26:18.500287	1
359	59	4	26.200	\N	2026-08-05 05:26:18.500287	1
360	59	5	26.850	\N	2026-08-05 05:26:18.500287	1
361	59	6	27.250	\N	2026-08-05 05:26:18.500287	1
362	59	7	26.150	\N	2026-08-05 05:26:18.500287	1
363	59	8	26.550	\N	2026-08-05 05:26:18.500287	1
370	52	1	29.650	\N	2026-08-05 14:53:59.237638	1
371	52	2	27.800	\N	2026-08-05 14:53:59.237638	1
372	52	3	29.600	\N	2026-08-05 14:53:59.237638	1
373	52	4	29.150	\N	2026-08-05 14:53:59.237638	1
374	52	5	29.750	\N	2026-08-05 14:53:59.237638	1
375	52	6	28.800	\N	2026-08-05 14:53:59.237638	1
376	52	7	29.650	\N	2026-08-05 14:53:59.237638	1
377	52	8	19.850	\N	2026-08-05 14:53:59.237638	1
378	52	9	28.550	\N	2026-08-05 14:53:59.237638	1
385	51	1	28.100	\N	2026-08-05 23:02:26.289543	1
386	51	2	29.050	\N	2026-08-05 23:02:26.289543	1
387	51	3	28.250	\N	2026-08-05 23:02:26.289543	1
388	51	4	29.800	\N	2026-08-05 23:02:26.289543	1
389	51	5	28.000	\N	2026-08-05 23:02:26.289543	1
390	51	6	27.850	\N	2026-08-05 23:02:26.289543	1
391	60	1	28.400	\N	2026-08-06 05:12:09.379561	1
392	60	2	29.650	\N	2026-08-06 05:12:09.379561	1
393	60	3	29.700	\N	2026-08-06 05:12:09.379561	1
394	60	4	27.750	\N	2026-08-06 05:12:09.379561	1
395	60	5	17.350	\N	2026-08-06 05:12:09.379561	1
396	60	6	27.850	\N	2026-08-06 05:12:09.379561	1
397	60	7	14.300	\N	2026-08-06 05:12:09.379561	1
398	61	1	31.350	\N	2026-08-06 05:13:41.179759	1
399	61	2	31.450	\N	2026-08-06 05:13:41.179759	1
400	61	3	29.650	\N	2026-08-06 05:13:41.179759	1
401	61	4	29.800	\N	2026-08-06 05:13:41.179759	1
402	61	5	32.100	\N	2026-08-06 05:13:41.179759	1
403	61	6	32.100	\N	2026-08-06 05:13:41.179759	1
404	61	7	30.900	\N	2026-08-06 05:13:41.179759	1
405	61	8	32.650	\N	2026-08-06 05:13:41.179759	1
406	61	9	31.750	\N	2026-08-06 05:13:41.179759	1
407	62	1	30.800	\N	2026-08-06 05:14:54.170255	1
408	62	2	31.700	\N	2026-08-06 05:14:54.170255	1
409	62	3	31.100	\N	2026-08-06 05:14:54.170255	1
410	62	4	30.550	\N	2026-08-06 05:14:54.170255	1
411	62	5	34.150	\N	2026-08-06 05:14:54.170255	1
412	62	6	30.600	\N	2026-08-06 05:14:54.170255	1
413	62	7	29.650	\N	2026-08-06 05:14:54.170255	1
414	62	8	21.000	\N	2026-08-06 05:14:54.170255	1
415	62	9	26.600	\N	2026-08-06 05:14:54.170255	1
423	64	1	24.850	\N	2026-08-06 05:18:20.391739	1
424	64	2	28.250	\N	2026-08-06 05:18:20.391739	1
431	66	1	27.350	\N	2026-08-06 05:21:03.119254	1
432	66	2	28.900	\N	2026-08-06 05:21:03.119254	1
433	66	3	31.300	\N	2026-08-06 05:21:03.119254	1
434	66	4	27.400	\N	2026-08-06 05:21:03.119254	1
435	66	5	34.150	\N	2026-08-06 05:21:03.119254	1
436	66	6	27.250	\N	2026-08-06 05:21:03.119254	1
437	66	7	25.650	\N	2026-08-06 05:21:03.119254	1
438	66	8	29.150	\N	2026-08-06 05:21:03.119254	1
439	66	9	37.900	\N	2026-08-06 05:21:03.119254	1
440	67	1	29.050	\N	2026-08-06 05:23:48.398276	1
441	67	2	26.500	\N	2026-08-06 05:23:48.398276	1
442	67	3	28.100	\N	2026-08-06 05:23:48.398276	1
443	67	4	26.050	\N	2026-08-06 05:23:48.398276	1
444	67	5	27.400	\N	2026-08-06 05:23:48.398276	1
445	67	6	28.550	\N	2026-08-06 05:23:48.398276	1
446	67	7	28.850	\N	2026-08-06 05:23:48.398276	1
447	67	8	26.000	\N	2026-08-06 05:23:48.398276	1
448	67	9	26.700	\N	2026-08-06 05:23:48.398276	1
449	67	10	29.150	\N	2026-08-06 05:23:48.398276	1
450	68	1	23.600	\N	2026-08-06 05:24:47.564861	1
451	68	2	27.250	\N	2026-08-06 05:24:47.564861	1
452	68	3	26.450	\N	2026-08-06 05:24:47.564861	1
453	68	4	26.650	\N	2026-08-06 05:24:47.564861	1
454	68	5	30.650	\N	2026-08-06 05:24:47.564861	1
455	68	6	26.600	\N	2026-08-06 05:24:47.564861	1
456	68	7	28.800	\N	2026-08-06 05:24:47.564861	1
457	69	1	33.300	\N	2026-08-06 05:25:38.115455	1
458	69	2	28.150	\N	2026-08-06 05:25:38.115455	1
459	69	3	25.000	\N	2026-08-06 05:25:38.115455	1
460	69	4	27.050	\N	2026-08-06 05:25:38.115455	1
461	69	5	27.150	\N	2026-08-06 05:25:38.115455	1
462	69	6	30.850	\N	2026-08-06 05:25:38.115455	1
463	65	1	22.850	\N	2026-08-06 05:26:52.715078	1
464	65	2	26.450	\N	2026-08-06 05:26:52.715078	1
465	65	3	26.750	\N	2026-08-06 05:26:52.715078	1
466	65	4	26.150	\N	2026-08-06 05:26:52.715078	1
467	65	5	27.800	\N	2026-08-06 05:26:52.715078	1
468	65	6	28.600	\N	2026-08-06 05:26:52.715078	1
469	63	1	27.650	\N	2026-08-06 09:50:06.52753	1
470	63	2	26.650	\N	2026-08-06 09:50:06.52753	1
471	63	3	34.250	\N	2026-08-06 09:50:06.52753	1
472	63	4	18.350	\N	2026-08-06 09:50:06.52753	1
473	63	5	26.350	\N	2026-08-06 09:50:06.52753	1
474	63	6	30.450	\N	2026-08-06 09:50:06.52753	1
475	63	7	20.650	\N	2026-08-06 09:50:06.52753	1
476	55	1	25.000	\N	2026-08-06 10:19:47.339954	1
477	55	2	22.600	\N	2026-08-06 10:19:47.339954	1
478	55	3	26.650	\N	2026-08-06 10:19:47.339954	1
479	55	4	26.650	\N	2026-08-06 10:19:47.339954	1
480	55	5	22.500	\N	2026-08-06 10:19:47.339954	1
481	55	6	21.650	\N	2026-08-06 10:19:47.339954	1
482	70	1	29.050	\N	2026-08-07 05:23:01.634685	1
483	70	2	29.200	\N	2026-08-07 05:23:01.634685	1
484	70	3	30.250	\N	2026-08-07 05:23:01.634685	1
485	70	4	33.650	\N	2026-08-07 05:23:01.634685	1
486	70	5	27.650	\N	2026-08-07 05:23:01.634685	1
487	70	6	29.950	\N	2026-08-07 05:23:01.634685	1
488	71	1	30.950	\N	2026-08-07 05:25:39.804931	1
489	71	2	29.550	\N	2026-08-07 05:25:39.804931	1
490	71	3	27.800	\N	2026-08-07 05:25:39.804931	1
491	71	4	28.500	\N	2026-08-07 05:25:39.804931	1
492	71	5	28.700	\N	2026-08-07 05:25:39.804931	1
493	71	6	23.000	\N	2026-08-07 05:25:39.804931	1
494	71	7	29.750	\N	2026-08-07 05:25:39.804931	1
495	71	8	28.050	\N	2026-08-07 05:25:39.804931	1
496	71	9	33.100	\N	2026-08-07 05:25:39.804931	1
497	72	1	21.750	\N	2026-08-07 05:26:45.829478	1
498	72	2	28.300	\N	2026-08-07 05:26:45.829478	1
499	72	3	30.550	\N	2026-08-07 05:26:45.829478	1
500	72	4	29.300	\N	2026-08-07 05:26:45.829478	1
501	72	5	29.950	\N	2026-08-07 05:26:45.829478	1
502	72	6	27.950	\N	2026-08-07 05:26:45.829478	1
503	72	7	28.400	\N	2026-08-07 05:26:45.829478	1
504	72	8	29.850	\N	2026-08-07 05:26:45.829478	1
505	72	9	30.350	\N	2026-08-07 05:26:45.829478	1
506	73	1	28.200	\N	2026-08-07 05:27:39.547294	1
507	73	2	31.700	\N	2026-08-07 05:27:39.547294	1
508	73	3	32.700	\N	2026-08-07 05:27:39.547294	1
509	73	4	31.650	\N	2026-08-07 05:27:39.547294	1
510	73	5	25.000	\N	2026-08-07 05:27:39.547294	1
511	74	1	28.550	\N	2026-08-07 05:28:49.295736	1
512	74	2	27.400	\N	2026-08-07 05:28:49.295736	1
513	74	3	27.400	\N	2026-08-07 05:28:49.295736	1
514	74	4	28.250	\N	2026-08-07 05:28:49.295736	1
515	74	5	18.450	\N	2026-08-07 05:28:49.295736	1
516	75	1	37.050	\N	2026-08-07 05:29:56.839702	1
517	75	2	34.600	\N	2026-08-07 05:29:56.839702	1
518	75	3	28.800	\N	2026-08-07 05:29:56.839702	1
519	75	4	24.750	\N	2026-08-07 05:29:56.839702	1
520	75	5	27.250	\N	2026-08-07 05:29:56.839702	1
521	75	6	27.600	\N	2026-08-07 05:29:56.839702	1
522	75	7	28.800	\N	2026-08-07 05:29:56.839702	1
523	75	8	27.500	\N	2026-08-07 05:29:56.839702	1
524	76	1	20.050	\N	2026-08-07 05:31:51.762381	1
525	76	2	28.200	\N	2026-08-07 05:31:51.762381	1
526	76	3	20.450	\N	2026-08-07 05:31:51.762381	1
527	76	4	27.400	\N	2026-08-07 05:31:51.762381	1
528	76	5	25.400	\N	2026-08-07 05:31:51.762381	1
529	76	6	29.100	\N	2026-08-07 05:31:51.762381	1
530	76	7	25.750	\N	2026-08-07 05:31:51.762381	1
531	76	8	28.400	\N	2026-08-07 05:31:51.762381	1
532	76	9	26.250	\N	2026-08-07 05:31:51.762381	1
533	76	10	28.750	\N	2026-08-07 05:31:51.762381	1
534	77	1	21.150	\N	2026-08-07 05:33:08.312801	1
535	77	2	20.600	\N	2026-08-07 05:33:08.312801	1
536	77	3	27.300	\N	2026-08-07 05:33:08.312801	1
537	77	4	26.900	\N	2026-08-07 05:33:08.312801	1
538	77	5	27.650	\N	2026-08-07 05:33:08.312801	1
539	77	6	30.100	\N	2026-08-07 05:33:08.312801	1
540	77	7	27.200	\N	2026-08-07 05:33:08.312801	1
541	77	8	28.800	\N	2026-08-07 05:33:08.312801	1
542	77	9	27.400	\N	2026-08-07 05:33:08.312801	1
543	77	10	28.650	\N	2026-08-07 05:33:08.312801	1
544	78	1	16.650	\N	2026-08-07 05:34:13.840169	1
545	78	2	27.000	\N	2026-08-07 05:34:13.840169	1
546	78	3	17.200	\N	2026-08-07 05:34:13.840169	1
547	78	4	27.550	\N	2026-08-07 05:34:13.840169	1
548	78	5	28.200	\N	2026-08-07 05:34:13.840169	1
549	78	6	26.500	\N	2026-08-07 05:34:13.840169	1
550	78	7	27.150	\N	2026-08-07 05:34:13.840169	1
551	78	8	28.350	\N	2026-08-07 05:34:13.840169	1
552	79	1	30.750	\N	2026-08-07 05:35:10.784899	1
553	79	2	26.450	\N	2026-08-07 05:35:10.784899	1
554	79	3	28.050	\N	2026-08-07 05:35:10.784899	1
555	79	4	27.100	\N	2026-08-07 05:35:10.784899	1
556	79	5	26.300	\N	2026-08-07 05:35:10.784899	1
557	79	6	28.650	\N	2026-08-07 05:35:10.784899	1
558	79	7	27.400	\N	2026-08-07 05:35:10.784899	1
1209	169	1	26.100	\N	2026-08-16 07:16:46.800647	1
1210	169	2	25.550	\N	2026-08-16 07:16:46.800647	1
1211	169	3	25.700	\N	2026-08-16 07:16:46.800647	1
1212	169	4	28.100	\N	2026-08-16 07:16:46.800647	1
1213	169	5	27.450	\N	2026-08-16 07:16:46.800647	1
1214	169	6	28.200	\N	2026-08-16 07:16:46.800647	1
1215	169	7	29.850	\N	2026-08-16 07:16:46.800647	1
1237	174	1	29.100	\N	2026-08-16 07:23:35.942302	1
1238	174	2	29.950	\N	2026-08-16 07:23:35.942302	1
1239	174	3	25.700	\N	2026-08-16 07:23:35.942302	1
1240	174	4	25.500	\N	2026-08-16 07:23:35.942302	1
1241	174	5	24.750	\N	2026-08-16 07:23:35.942302	1
1242	174	6	28.050	\N	2026-08-16 07:23:35.942302	1
1243	174	7	26.700	\N	2026-08-16 07:23:35.942302	1
1244	174	8	27.900	\N	2026-08-16 07:23:35.942302	1
1245	174	9	26.900	\N	2026-08-16 07:23:35.942302	1
1258	176	5	30.150	\N	2026-08-16 07:25:54.684036	1
1259	176	6	29.850	\N	2026-08-16 07:25:54.684036	1
1260	176	7	20.150	\N	2026-08-16 07:25:54.684036	1
1261	177	1	23.300	\N	2026-08-16 07:27:02.334141	1
1262	177	2	24.850	\N	2026-08-16 07:27:02.334141	1
1263	177	3	24.250	\N	2026-08-16 07:27:02.334141	1
1264	177	4	24.350	\N	2026-08-16 07:27:02.334141	1
1265	177	5	27.900	\N	2026-08-16 07:27:02.334141	1
1266	177	6	26.000	\N	2026-08-16 07:27:02.334141	1
1267	178	1	26.150	\N	2026-08-17 05:21:35.499855	1
1268	178	2	28.650	\N	2026-08-17 05:21:35.499855	1
1269	178	3	27.900	\N	2026-08-17 05:21:35.499855	1
1270	178	4	29.200	\N	2026-08-17 05:21:35.499855	1
1271	178	5	31.000	\N	2026-08-17 05:21:35.499855	1
1216	170	1	27.700	\N	2026-08-16 07:17:47.960176	1
1217	170	2	26.900	\N	2026-08-16 07:17:47.960176	1
1246	175	1	23.800	\N	2026-08-16 07:24:50.375929	1
1247	175	2	23.150	\N	2026-08-16 07:24:50.375929	1
1248	175	3	24.600	\N	2026-08-16 07:24:50.375929	1
1249	175	4	24.250	\N	2026-08-16 07:24:50.375929	1
1250	175	5	22.500	\N	2026-08-16 07:24:50.375929	1
619	20	1	28.000	\N	2026-08-07 12:32:39.042585	1
620	20	2	32.950	\N	2026-08-07 12:32:39.042585	1
621	20	3	27.950	\N	2026-08-07 12:32:39.042585	1
622	20	4	27.850	\N	2026-08-07 12:32:39.042585	1
623	20	5	27.900	\N	2026-08-07 12:32:39.042585	1
624	20	6	28.450	\N	2026-08-07 12:32:39.042585	1
625	20	7	29.300	\N	2026-08-07 12:32:39.042585	1
627	88	1	28.600	\N	2026-08-08 05:33:43.300283	1
628	88	2	29.750	\N	2026-08-08 05:33:43.300283	1
629	88	3	29.400	\N	2026-08-08 05:33:43.300283	1
630	88	4	29.350	\N	2026-08-08 05:33:43.300283	1
631	88	5	29.850	\N	2026-08-08 05:33:43.300283	1
632	88	6	30.650	\N	2026-08-08 05:33:43.300283	1
633	89	1	27.350	\N	2026-08-08 05:34:49.051626	1
634	89	2	27.450	\N	2026-08-08 05:34:49.051626	1
635	89	3	27.550	\N	2026-08-08 05:34:49.051626	1
636	89	4	29.100	\N	2026-08-08 05:34:49.051626	1
637	89	5	27.500	\N	2026-08-08 05:34:49.051626	1
638	89	6	27.550	\N	2026-08-08 05:34:49.051626	1
639	89	7	27.450	\N	2026-08-08 05:34:49.051626	1
640	89	8	23.300	\N	2026-08-08 05:34:49.051626	1
641	90	1	30.500	\N	2026-08-08 05:35:45.485175	1
642	90	2	27.550	\N	2026-08-08 05:35:45.485175	1
643	90	3	28.100	\N	2026-08-08 05:35:45.485175	1
644	90	4	27.700	\N	2026-08-08 05:35:45.485175	1
645	90	5	28.550	\N	2026-08-08 05:35:45.485175	1
646	90	6	21.500	\N	2026-08-08 05:35:45.485175	1
647	90	7	30.050	\N	2026-08-08 05:35:45.485175	1
648	91	1	26.050	\N	2026-08-08 05:37:33.883171	1
649	91	2	26.900	\N	2026-08-08 05:37:33.883171	1
650	91	3	29.850	\N	2026-08-08 05:37:33.883171	1
651	91	4	27.650	\N	2026-08-08 05:37:33.883171	1
652	91	5	20.000	\N	2026-08-08 05:37:33.883171	1
653	91	6	23.450	\N	2026-08-08 05:37:33.883171	1
654	92	1	21.600	\N	2026-08-08 05:39:02.666522	1
655	92	2	28.700	\N	2026-08-08 05:39:02.666522	1
656	92	3	30.000	\N	2026-08-08 05:39:02.666522	1
657	92	4	28.450	\N	2026-08-08 05:39:02.666522	1
658	92	5	26.800	\N	2026-08-08 05:39:02.666522	1
659	93	1	27.300	\N	2026-08-08 05:41:02.110074	1
660	93	2	27.300	\N	2026-08-08 05:41:02.110074	1
661	93	3	25.400	\N	2026-08-08 05:41:02.110074	1
662	93	4	27.250	\N	2026-08-08 05:41:02.110074	1
663	93	5	28.050	\N	2026-08-08 05:41:02.110074	1
664	93	6	27.350	\N	2026-08-08 05:41:02.110074	1
665	93	7	27.250	\N	2026-08-08 05:41:02.110074	1
666	93	8	25.000	\N	2026-08-08 05:41:02.110074	1
667	93	9	29.600	\N	2026-08-08 05:41:02.110074	1
668	94	1	32.400	\N	2026-08-08 05:42:10.302604	1
669	94	2	27.450	\N	2026-08-08 05:42:10.302604	1
670	94	3	27.250	\N	2026-08-08 05:42:10.302604	1
671	94	4	29.000	\N	2026-08-08 05:42:10.302604	1
672	94	5	27.250	\N	2026-08-08 05:42:10.302604	1
673	94	6	27.200	\N	2026-08-08 05:42:10.302604	1
674	94	7	29.000	\N	2026-08-08 05:42:10.302604	1
675	94	8	27.250	\N	2026-08-08 05:42:10.302604	1
676	94	9	25.650	\N	2026-08-08 05:42:10.302604	1
677	94	10	28.950	\N	2026-08-08 05:42:10.302604	1
678	95	1	26.000	\N	2026-08-08 05:43:24.316785	1
679	95	2	29.750	\N	2026-08-08 05:43:24.316785	1
680	95	3	27.300	\N	2026-08-08 05:43:24.316785	1
681	95	4	24.900	\N	2026-08-08 05:43:24.316785	1
682	95	5	28.950	\N	2026-08-08 05:43:24.316785	1
683	95	6	30.300	\N	2026-08-08 05:43:24.316785	1
684	95	7	27.650	\N	2026-08-08 05:43:24.316785	1
685	95	8	25.600	\N	2026-08-08 05:43:24.316785	1
686	95	9	29.100	\N	2026-08-08 05:43:24.316785	1
687	95	10	30.650	\N	2026-08-08 05:43:24.316785	1
688	96	1	20.300	\N	2026-08-08 05:44:27.618161	1
689	96	2	26.250	\N	2026-08-08 05:44:27.618161	1
690	96	3	26.400	\N	2026-08-08 05:44:27.618161	1
691	96	4	26.350	\N	2026-08-08 05:44:27.618161	1
692	96	5	26.250	\N	2026-08-08 05:44:27.618161	1
693	96	6	26.700	\N	2026-08-08 05:44:27.618161	1
694	96	7	26.500	\N	2026-08-08 05:44:27.618161	1
695	96	8	28.150	\N	2026-08-08 05:44:27.618161	1
696	97	1	27.500	\N	2026-08-08 05:45:15.246474	1
697	97	2	27.400	\N	2026-08-08 05:45:15.246474	1
698	97	3	26.200	\N	2026-08-08 05:45:15.246474	1
699	97	4	29.000	\N	2026-08-08 05:45:15.246474	1
700	97	5	34.850	\N	2026-08-08 05:45:15.246474	1
701	97	6	30.500	\N	2026-08-08 05:45:15.246474	1
702	98	1	694.750	\N	2026-08-08 06:51:30.145466	1
703	99	1	1534.500	\N	2026-08-08 06:58:00.950157	1
704	100	1	2181.850	\N	2026-08-08 07:01:29.883679	1
705	101	1	17.900	\N	2026-08-08 07:05:24.210104	1
706	102	1	520.900	\N	2026-08-08 07:07:33.221562	1
707	103	1	439.600	\N	2026-08-08 07:12:47.109305	1
708	104	1	2100.900	\N	2026-08-08 07:31:28.848027	1
709	105	1	29.250	\N	2026-08-09 07:48:31.9882	1
710	105	2	28.750	\N	2026-08-09 07:48:31.9882	1
711	105	3	29.450	\N	2026-08-09 07:48:31.9882	1
712	105	4	28.050	\N	2026-08-09 07:48:31.9882	1
713	105	5	30.000	\N	2026-08-09 07:48:31.9882	1
714	105	6	29.500	\N	2026-08-09 07:48:31.9882	1
715	105	7	29.400	\N	2026-08-09 07:48:31.9882	1
716	105	8	30.500	\N	2026-08-09 07:48:31.9882	1
717	106	1	27.450	\N	2026-08-09 07:50:05.863588	1
718	106	2	27.450	\N	2026-08-09 07:50:05.863588	1
719	106	3	29.350	\N	2026-08-09 07:50:05.863588	1
720	106	4	27.850	\N	2026-08-09 07:50:05.863588	1
721	106	5	27.550	\N	2026-08-09 07:50:05.863588	1
722	106	6	27.500	\N	2026-08-09 07:50:05.863588	1
723	106	7	27.450	\N	2026-08-09 07:50:05.863588	1
724	106	8	24.600	\N	2026-08-09 07:50:05.863588	1
725	106	9	27.400	\N	2026-08-09 07:50:05.863588	1
726	106	10	31.700	\N	2026-08-09 07:50:05.863588	1
727	107	1	32.850	\N	2026-08-09 07:51:04.678261	1
728	107	2	27.050	\N	2026-08-09 07:51:04.678261	1
729	107	3	27.750	\N	2026-08-09 07:51:04.678261	1
730	107	4	29.150	\N	2026-08-09 07:51:04.678261	1
731	107	5	27.300	\N	2026-08-09 07:51:04.678261	1
732	107	6	27.500	\N	2026-08-09 07:51:04.678261	1
733	107	7	27.550	\N	2026-08-09 07:51:04.678261	1
734	107	8	30.550	\N	2026-08-09 07:51:04.678261	1
735	107	9	32.150	\N	2026-08-09 07:51:04.678261	1
736	108	1	28.400	\N	2026-08-09 07:52:30.892115	1
737	108	2	28.650	\N	2026-08-09 07:52:30.892115	1
738	108	3	23.900	\N	2026-08-09 07:52:30.892115	1
739	108	4	25.900	\N	2026-08-09 07:52:30.892115	1
740	108	5	21.450	\N	2026-08-09 07:52:30.892115	1
741	108	6	27.000	\N	2026-08-09 07:52:30.892115	1
742	109	1	28.650	\N	2026-08-09 07:53:28.839697	1
743	109	2	29.100	\N	2026-08-09 07:53:28.839697	1
744	109	3	28.650	\N	2026-08-09 07:53:28.839697	1
745	109	4	28.100	\N	2026-08-09 07:53:28.839697	1
746	109	5	10.600	\N	2026-08-09 07:53:28.839697	1
756	111	1	28.800	\N	2026-08-09 07:56:12.533537	1
757	111	2	29.550	\N	2026-08-09 07:56:12.533537	1
758	111	3	28.100	\N	2026-08-09 07:56:12.533537	1
759	111	4	23.700	\N	2026-08-09 07:56:12.533537	1
760	111	5	28.750	\N	2026-08-09 07:56:12.533537	1
761	111	6	27.200	\N	2026-08-09 07:56:12.533537	1
762	111	7	27.300	\N	2026-08-09 07:56:12.533537	1
763	111	8	28.900	\N	2026-08-09 07:56:12.533537	1
764	111	9	26.500	\N	2026-08-09 07:56:12.533537	1
765	111	10	27.300	\N	2026-08-09 07:56:12.533537	1
766	112	1	24.800	\N	2026-08-09 07:58:42.067577	1
767	112	2	28.050	\N	2026-08-09 07:58:42.067577	1
768	112	3	28.000	\N	2026-08-09 07:58:42.067577	1
769	112	4	28.850	\N	2026-08-09 07:58:42.067577	1
770	112	5	27.100	\N	2026-08-09 07:58:42.067577	1
771	112	6	27.550	\N	2026-08-09 07:58:42.067577	1
772	112	7	27.000	\N	2026-08-09 07:58:42.067577	1
773	112	8	29.050	\N	2026-08-09 07:58:42.067577	1
774	112	9	27.150	\N	2026-08-09 07:58:42.067577	1
775	112	10	29.450	\N	2026-08-09 07:58:42.067577	1
776	113	1	18.300	\N	2026-08-09 07:59:33.485241	1
777	113	2	27.000	\N	2026-08-09 07:59:33.485241	1
778	113	3	32.900	\N	2026-08-09 07:59:33.485241	1
779	113	4	28.050	\N	2026-08-09 07:59:33.485241	1
780	113	5	26.200	\N	2026-08-09 07:59:33.485241	1
781	113	6	34.600	\N	2026-08-09 07:59:33.485241	1
790	115	1	22.250	\N	2026-08-09 08:03:42.711767	1
791	115	2	26.150	\N	2026-08-09 08:03:42.711767	1
792	115	3	26.350	\N	2026-08-09 08:03:42.711767	1
793	115	4	23.200	\N	2026-08-09 08:03:42.711767	1
794	115	5	28.400	\N	2026-08-09 08:03:42.711767	1
795	115	6	27.700	\N	2026-08-09 08:03:42.711767	1
796	115	7	26.800	\N	2026-08-09 08:03:42.711767	1
797	115	8	27.500	\N	2026-08-09 08:03:42.711767	1
798	114	1	28.250	\N	2026-08-09 08:05:59.593048	1
799	114	2	26.100	\N	2026-08-09 08:05:59.593048	1
800	114	3	26.350	\N	2026-08-09 08:05:59.593048	1
801	114	4	26.350	\N	2026-08-09 08:05:59.593048	1
802	114	5	27.000	\N	2026-08-09 08:05:59.593048	1
803	114	6	26.550	\N	2026-08-09 08:05:59.593048	1
804	114	7	26.300	\N	2026-08-09 08:05:59.593048	1
805	114	8	26.450	\N	2026-08-09 08:05:59.593048	1
806	110	1	28.950	\N	2026-08-09 08:41:15.456616	1
807	110	2	20.450	\N	2026-08-09 08:41:15.456616	1
808	110	3	27.400	\N	2026-08-09 08:41:15.456616	1
809	110	4	27.250	\N	2026-08-09 08:41:15.456616	1
810	110	5	26.700	\N	2026-08-09 08:41:15.456616	1
811	110	6	27.250	\N	2026-08-09 08:41:15.456616	1
812	110	7	29.250	\N	2026-08-09 08:41:15.456616	1
813	110	8	27.350	\N	2026-08-09 08:41:15.456616	1
814	110	9	26.850	\N	2026-08-09 08:41:15.456616	1
815	116	1	27.900	\N	2026-08-10 05:23:01.976288	1
816	116	2	29.800	\N	2026-08-10 05:23:01.976288	1
817	116	3	27.250	\N	2026-08-10 05:23:01.976288	1
818	116	4	28.650	\N	2026-08-10 05:23:01.976288	1
819	116	5	30.800	\N	2026-08-10 05:23:01.976288	1
820	116	6	28.950	\N	2026-08-10 05:23:01.976288	1
821	117	1	29.550	\N	2026-08-10 05:24:06.205199	1
822	117	2	29.250	\N	2026-08-10 05:24:06.205199	1
823	117	3	28.950	\N	2026-08-10 05:24:06.205199	1
824	117	4	30.150	\N	2026-08-10 05:24:06.205199	1
825	117	5	29.150	\N	2026-08-10 05:24:06.205199	1
826	117	6	29.250	\N	2026-08-10 05:24:06.205199	1
827	117	7	28.350	\N	2026-08-10 05:24:06.205199	1
828	117	8	26.300	\N	2026-08-10 05:24:06.205199	1
829	117	9	26.500	\N	2026-08-10 05:24:06.205199	1
830	117	10	28.500	\N	2026-08-10 05:24:06.205199	1
831	118	1	29.350	\N	2026-08-10 05:25:09.40753	1
832	118	2	30.350	\N	2026-08-10 05:25:09.40753	1
833	118	3	28.150	\N	2026-08-10 05:25:09.40753	1
834	118	4	29.200	\N	2026-08-10 05:25:09.40753	1
835	118	5	27.700	\N	2026-08-10 05:25:09.40753	1
836	118	6	31.550	\N	2026-08-10 05:25:09.40753	1
837	118	7	27.600	\N	2026-08-10 05:25:09.40753	1
838	118	8	28.050	\N	2026-08-10 05:25:09.40753	1
839	118	9	30.600	\N	2026-08-10 05:25:09.40753	1
840	119	1	26.800	\N	2026-08-10 05:26:09.923348	1
841	119	2	25.150	\N	2026-08-10 05:26:09.923348	1
842	119	3	15.950	\N	2026-08-10 05:26:09.923348	1
843	119	4	16.450	\N	2026-08-10 05:26:09.923348	1
844	119	5	20.350	\N	2026-08-10 05:26:09.923348	1
845	119	6	20.350	\N	2026-08-10 05:26:09.923348	1
846	119	7	17.350	\N	2026-08-10 05:26:09.923348	1
847	119	8	24.000	\N	2026-08-10 05:26:09.923348	1
848	119	9	22.900	\N	2026-08-10 05:26:09.923348	1
849	120	1	20.250	\N	2026-08-10 05:27:03.589931	1
850	120	2	24.450	\N	2026-08-10 05:27:03.589931	1
851	120	3	28.650	\N	2026-08-10 05:27:03.589931	1
852	120	4	26.800	\N	2026-08-10 05:27:03.589931	1
853	120	5	21.250	\N	2026-08-10 05:27:03.589931	1
854	120	6	23.500	\N	2026-08-10 05:27:03.589931	1
855	120	7	25.850	\N	2026-08-10 05:27:03.589931	1
856	120	8	26.750	\N	2026-08-10 05:27:03.589931	1
857	121	1	27.900	\N	2026-08-10 05:28:03.324527	1
858	121	2	28.100	\N	2026-08-10 05:28:03.324527	1
859	121	3	28.850	\N	2026-08-10 05:28:03.324527	1
860	121	4	28.100	\N	2026-08-10 05:28:03.324527	1
861	121	5	29.150	\N	2026-08-10 05:28:03.324527	1
862	121	6	28.100	\N	2026-08-10 05:28:03.324527	1
863	121	7	28.650	\N	2026-08-10 05:28:03.324527	1
864	121	8	28.300	\N	2026-08-10 05:28:03.324527	1
865	122	1	27.450	\N	2026-08-10 05:28:46.604898	1
866	122	2	27.050	\N	2026-08-10 05:28:46.604898	1
867	122	3	32.100	\N	2026-08-10 05:28:46.604898	1
868	123	1	33.750	\N	2026-08-10 05:30:46.537843	1
869	123	2	30.250	\N	2026-08-10 05:30:46.537843	1
870	123	3	27.250	\N	2026-08-10 05:30:46.537843	1
871	123	4	27.300	\N	2026-08-10 05:30:46.537843	1
872	123	5	27.200	\N	2026-08-10 05:30:46.537843	1
873	123	6	28.250	\N	2026-08-10 05:30:46.537843	1
874	123	7	25.800	\N	2026-08-10 05:30:46.537843	1
875	123	8	27.250	\N	2026-08-10 05:30:46.537843	1
876	123	9	27.350	\N	2026-08-10 05:30:46.537843	1
884	125	1	25.900	\N	2026-08-10 05:33:23.641765	1
885	125	2	26.600	\N	2026-08-10 05:33:23.641765	1
886	125	3	25.000	\N	2026-08-10 05:33:23.641765	1
887	125	4	26.600	\N	2026-08-10 05:33:23.641765	1
888	125	5	26.850	\N	2026-08-10 05:33:23.641765	1
889	125	6	28.200	\N	2026-08-10 05:33:23.641765	1
890	125	7	25.150	\N	2026-08-10 05:33:23.641765	1
891	125	8	27.700	\N	2026-08-10 05:33:23.641765	1
892	124	1	24.600	\N	2026-08-10 05:34:55.986537	1
893	124	2	26.650	\N	2026-08-10 05:34:55.986537	1
894	124	3	24.300	\N	2026-08-10 05:34:55.986537	1
895	124	4	23.900	\N	2026-08-10 05:34:55.986537	1
896	124	5	25.050	\N	2026-08-10 05:34:55.986537	1
897	124	6	23.100	\N	2026-08-10 05:34:55.986537	1
898	124	7	25.650	\N	2026-08-10 05:34:55.986537	1
899	126	1	28.800	\N	2026-08-11 05:24:27.73266	1
900	126	2	28.150	\N	2026-08-11 05:24:27.73266	1
901	126	3	30.000	\N	2026-08-11 05:24:27.73266	1
902	126	4	23.550	\N	2026-08-11 05:24:27.73266	1
903	126	5	27.300	\N	2026-08-11 05:24:27.73266	1
904	127	1	29.550	\N	2026-08-11 05:26:47.336666	1
905	127	2	27.650	\N	2026-08-11 05:26:47.336666	1
906	127	3	29.200	\N	2026-08-11 05:26:47.336666	1
907	127	4	29.450	\N	2026-08-11 05:26:47.336666	1
908	127	5	29.650	\N	2026-08-11 05:26:47.336666	1
909	127	6	29.550	\N	2026-08-11 05:26:47.336666	1
910	128	1	27.350	\N	2026-08-11 05:31:19.677755	1
911	128	2	27.100	\N	2026-08-11 05:31:19.677755	1
912	128	3	29.550	\N	2026-08-11 05:31:19.677755	1
913	128	4	29.050	\N	2026-08-11 05:31:19.677755	1
914	128	5	25.450	\N	2026-08-11 05:31:19.677755	1
915	128	6	21.700	\N	2026-08-11 05:31:19.677755	1
916	128	7	28.100	\N	2026-08-11 05:31:19.677755	1
917	128	8	28.200	\N	2026-08-11 05:31:19.677755	1
918	128	9	18.350	\N	2026-08-11 05:31:19.677755	1
919	129	1	24.050	\N	2026-08-11 05:36:02.008856	1
920	129	2	22.450	\N	2026-08-11 05:36:02.008856	1
921	129	3	19.950	\N	2026-08-11 05:36:02.008856	1
922	129	4	25.250	\N	2026-08-11 05:36:02.008856	1
923	129	5	16.250	\N	2026-08-11 05:36:02.008856	1
924	129	6	11.950	\N	2026-08-11 05:36:02.008856	1
925	129	7	23.600	\N	2026-08-11 05:36:02.008856	1
926	130	1	28.500	\N	2026-08-11 05:36:52.435471	1
927	130	2	28.600	\N	2026-08-11 05:36:52.435471	1
928	130	3	23.000	\N	2026-08-11 05:36:52.435471	1
929	130	4	28.100	\N	2026-08-11 05:36:52.435471	1
930	131	1	31.600	\N	2026-08-11 05:38:13.686446	1
931	131	2	26.100	\N	2026-08-11 05:38:13.686446	1
932	131	3	28.500	\N	2026-08-11 05:38:13.686446	1
933	131	4	33.950	\N	2026-08-11 05:38:13.686446	1
934	131	5	27.400	\N	2026-08-11 05:38:13.686446	1
935	131	6	27.350	\N	2026-08-11 05:38:13.686446	1
936	131	7	29.100	\N	2026-08-11 05:38:13.686446	1
937	131	8	28.250	\N	2026-08-11 05:38:13.686446	1
938	132	1	27.050	\N	2026-08-11 05:39:17.78189	1
939	132	2	23.750	\N	2026-08-11 05:39:17.78189	1
940	132	3	27.400	\N	2026-08-11 05:39:17.78189	1
941	132	4	27.200	\N	2026-08-11 05:39:17.78189	1
942	132	5	27.750	\N	2026-08-11 05:39:17.78189	1
943	132	6	27.150	\N	2026-08-11 05:39:17.78189	1
944	132	7	27.250	\N	2026-08-11 05:39:17.78189	1
945	132	8	27.450	\N	2026-08-11 05:39:17.78189	1
946	132	9	27.200	\N	2026-08-11 05:39:17.78189	1
947	132	10	29.100	\N	2026-08-11 05:39:17.78189	1
948	133	1	16.800	\N	2026-08-11 05:40:14.148997	1
949	133	2	27.400	\N	2026-08-11 05:40:14.148997	1
950	133	3	26.250	\N	2026-08-11 05:40:14.148997	1
951	133	4	27.450	\N	2026-08-11 05:40:14.148997	1
952	133	5	27.850	\N	2026-08-11 05:40:14.148997	1
953	133	6	25.800	\N	2026-08-11 05:40:14.148997	1
954	133	7	29.500	\N	2026-08-11 05:40:14.148997	1
955	133	8	28.600	\N	2026-08-11 05:40:14.148997	1
956	133	9	28.450	\N	2026-08-11 05:40:14.148997	1
957	134	1	33.200	\N	2026-08-11 05:42:02.246542	1
958	134	2	30.250	\N	2026-08-11 05:42:02.246542	1
959	134	3	28.050	\N	2026-08-11 05:42:02.246542	1
960	135	1	29.050	\N	2026-08-12 05:14:43.470644	1
961	135	2	29.350	\N	2026-08-12 05:14:43.470644	1
962	135	3	28.200	\N	2026-08-12 05:14:43.470644	1
963	135	4	29.050	\N	2026-08-12 05:14:43.470644	1
964	135	5	28.850	\N	2026-08-12 05:14:43.470644	1
965	135	6	28.200	\N	2026-08-12 05:14:43.470644	1
966	135	7	28.850	\N	2026-08-12 05:14:43.470644	1
967	135	8	27.350	\N	2026-08-12 05:14:43.470644	1
968	136	1	27.750	\N	2026-08-12 05:16:36.540058	1
969	136	2	28.950	\N	2026-08-12 05:16:36.540058	1
970	136	3	29.850	\N	2026-08-12 05:16:36.540058	1
971	136	4	27.250	\N	2026-08-12 05:16:36.540058	1
972	136	5	27.500	\N	2026-08-12 05:16:36.540058	1
973	136	6	27.150	\N	2026-08-12 05:16:36.540058	1
974	136	7	27.450	\N	2026-08-12 05:16:36.540058	1
975	136	8	27.500	\N	2026-08-12 05:16:36.540058	1
976	136	9	32.850	\N	2026-08-12 05:16:36.540058	1
977	136	10	28.500	\N	2026-08-12 05:16:36.540058	1
978	137	1	27.450	\N	2026-08-12 05:19:50.744193	1
979	137	2	28.150	\N	2026-08-12 05:19:50.744193	1
980	137	3	27.350	\N	2026-08-12 05:19:50.744193	1
981	137	4	24.000	\N	2026-08-12 05:19:50.744193	1
982	137	5	27.350	\N	2026-08-12 05:19:50.744193	1
983	137	6	27.300	\N	2026-08-12 05:19:50.744193	1
984	137	7	27.250	\N	2026-08-12 05:19:50.744193	1
985	137	8	27.300	\N	2026-08-12 05:19:50.744193	1
986	137	9	27.650	\N	2026-08-12 05:19:50.744193	1
987	137	10	28.200	\N	2026-08-12 05:19:50.744193	1
988	138	1	26.900	\N	2026-08-12 05:20:38.332118	1
989	138	2	25.800	\N	2026-08-12 05:20:38.332118	1
990	138	3	25.400	\N	2026-08-12 05:20:38.332118	1
991	138	4	28.950	\N	2026-08-12 05:20:38.332118	1
992	138	5	23.050	\N	2026-08-12 05:20:38.332118	1
993	139	1	32.900	\N	2026-08-12 05:21:17.214757	1
994	139	2	27.450	\N	2026-08-12 05:21:17.214757	1
995	139	3	28.250	\N	2026-08-12 05:21:17.214757	1
996	139	4	28.050	\N	2026-08-12 05:21:17.214757	1
997	140	1	16.350	\N	2026-08-12 05:22:39.016676	1
998	140	2	17.300	\N	2026-08-12 05:22:39.016676	1
999	141	1	16.750	\N	2026-08-12 05:23:29.048664	1
1218	171	1	30.550	\N	2026-08-16 07:18:54.385539	1
1219	171	2	29.700	\N	2026-08-16 07:18:54.385539	1
1220	171	3	30.350	\N	2026-08-16 07:18:54.385539	1
1221	171	4	30.550	\N	2026-08-16 07:18:54.385539	1
1222	171	5	26.300	\N	2026-08-16 07:18:54.385539	1
1223	171	6	28.600	\N	2026-08-16 07:18:54.385539	1
1251	175	6	24.450	\N	2026-08-16 07:24:50.375929	1
1252	175	7	23.400	\N	2026-08-16 07:24:50.375929	1
1253	175	8	23.800	\N	2026-08-16 07:24:50.375929	1
1009	143	1	21.550	\N	2026-08-12 05:25:55.225812	1
1010	143	2	24.100	\N	2026-08-12 05:25:55.225812	1
1011	143	3	34.250	\N	2026-08-12 05:25:55.225812	1
1012	143	4	27.400	\N	2026-08-12 05:25:55.225812	1
1013	143	5	27.400	\N	2026-08-12 05:25:55.225812	1
1014	143	6	27.550	\N	2026-08-12 05:25:55.225812	1
1015	143	7	29.050	\N	2026-08-12 05:25:55.225812	1
1016	143	8	27.350	\N	2026-08-12 05:25:55.225812	1
1017	143	9	27.350	\N	2026-08-12 05:25:55.225812	1
1018	143	10	26.500	\N	2026-08-12 05:25:55.225812	1
1019	143	11	28.000	\N	2026-08-12 05:25:55.225812	1
1020	144	1	21.700	\N	2026-08-12 05:28:07.246176	1
1021	144	2	16.250	\N	2026-08-12 05:28:07.246176	1
1022	144	3	28.150	\N	2026-08-12 05:28:07.246176	1
1023	144	4	27.000	\N	2026-08-12 05:28:07.246176	1
1024	144	5	25.750	\N	2026-08-12 05:28:07.246176	1
1025	144	6	27.300	\N	2026-08-12 05:28:07.246176	1
1026	144	7	27.350	\N	2026-08-12 05:28:07.246176	1
1027	144	8	27.350	\N	2026-08-12 05:28:07.246176	1
1028	144	9	29.000	\N	2026-08-12 05:28:07.246176	1
1029	144	10	28.500	\N	2026-08-12 05:28:07.246176	1
1030	145	1	20.500	\N	2026-08-12 05:28:46.41942	1
1031	145	2	30.000	\N	2026-08-12 05:28:46.41942	1
1032	145	3	30.950	\N	2026-08-12 05:28:46.41942	1
1033	145	4	31.950	\N	2026-08-12 05:28:46.41942	1
1034	145	5	28.600	\N	2026-08-12 05:28:46.41942	1
1035	146	1	23.950	\N	2026-08-12 05:29:39.113399	1
1036	146	2	29.650	\N	2026-08-12 05:29:39.113399	1
1037	146	3	28.750	\N	2026-08-12 05:29:39.113399	1
1038	146	4	32.100	\N	2026-08-12 05:29:39.113399	1
1039	146	5	31.200	\N	2026-08-12 05:29:39.113399	1
1040	146	6	35.400	\N	2026-08-12 05:29:39.113399	1
1041	146	7	30.200	\N	2026-08-12 05:29:39.113399	1
1042	147	1	27.100	\N	2026-08-12 05:30:31.757677	1
1043	147	2	28.800	\N	2026-08-12 05:30:31.757677	1
1044	147	3	27.450	\N	2026-08-12 05:30:31.757677	1
1224	172	1	26.850	\N	2026-08-16 07:19:35.018273	1
1225	172	2	27.500	\N	2026-08-16 07:19:35.018273	1
1226	172	3	26.550	\N	2026-08-16 07:19:35.018273	1
1227	172	4	22.500	\N	2026-08-16 07:19:35.018273	1
1063	142	1	18.700	\N	2026-08-12 07:30:10.010366	1
1064	142	2	22.550	\N	2026-08-12 07:30:10.010366	1
1065	142	3	25.700	\N	2026-08-12 07:30:10.010366	1
1066	142	4	34.200	\N	2026-08-12 07:30:10.010366	1
1067	142	5	29.250	\N	2026-08-12 07:30:10.010366	1
1068	142	6	27.500	\N	2026-08-12 07:30:10.010366	1
1069	142	7	27.450	\N	2026-08-12 07:30:10.010366	1
1070	142	8	27.450	\N	2026-08-12 07:30:10.010366	1
1071	142	9	29.000	\N	2026-08-12 07:30:10.010366	1
1072	148	1	27.750	\N	2026-08-13 04:43:22.223796	1
1073	148	2	29.450	\N	2026-08-13 04:43:22.223796	1
1074	148	3	29.300	\N	2026-08-13 04:43:22.223796	1
1075	148	4	28.400	\N	2026-08-13 04:43:22.223796	1
1076	148	5	28.950	\N	2026-08-13 04:43:22.223796	1
1077	148	6	28.900	\N	2026-08-13 04:43:22.223796	1
1078	148	7	28.250	\N	2026-08-13 04:43:22.223796	1
1079	148	8	23.000	\N	2026-08-13 04:43:22.223796	1
1080	149	1	31.000	\N	2026-08-13 04:44:35.224753	1
1081	149	2	30.200	\N	2026-08-13 04:44:35.224753	1
1082	149	3	29.500	\N	2026-08-13 04:44:35.224753	1
1083	149	4	29.600	\N	2026-08-13 04:44:35.224753	1
1084	149	5	31.150	\N	2026-08-13 04:44:35.224753	1
1085	149	6	31.200	\N	2026-08-13 04:44:35.224753	1
1086	149	7	31.200	\N	2026-08-13 04:44:35.224753	1
1087	149	8	31.100	\N	2026-08-13 04:44:35.224753	1
1088	149	9	31.400	\N	2026-08-13 04:44:35.224753	1
1089	150	1	31.250	\N	2026-08-13 04:45:34.228718	1
1090	150	2	30.350	\N	2026-08-13 04:45:34.228718	1
1091	150	3	29.450	\N	2026-08-13 04:45:34.228718	1
1092	150	4	31.250	\N	2026-08-13 04:45:34.228718	1
1093	150	5	31.200	\N	2026-08-13 04:45:34.228718	1
1094	150	6	31.000	\N	2026-08-13 04:45:34.228718	1
1095	150	7	31.150	\N	2026-08-13 04:45:34.228718	1
1096	150	8	22.250	\N	2026-08-13 04:45:34.228718	1
1097	150	9	27.550	\N	2026-08-13 04:45:34.228718	1
1098	151	1	22.450	\N	2026-08-13 04:46:21.136222	1
1099	151	2	30.250	\N	2026-08-13 04:46:21.136222	1
1100	151	3	24.800	\N	2026-08-13 04:46:21.136222	1
1101	151	4	28.100	\N	2026-08-13 04:46:21.136222	1
1102	151	5	30.100	\N	2026-08-13 04:46:21.136222	1
1103	151	6	23.700	\N	2026-08-13 04:46:21.136222	1
1108	153	1	27.600	\N	2026-08-13 04:48:05.77479	1
1109	153	2	27.400	\N	2026-08-13 04:48:05.77479	1
1110	153	3	26.700	\N	2026-08-13 04:48:05.77479	1
1111	153	4	29.200	\N	2026-08-13 04:48:05.77479	1
1112	153	5	14.000	\N	2026-08-13 04:48:05.77479	1
1113	153	6	28.900	\N	2026-08-13 04:48:05.77479	1
1114	153	7	29.400	\N	2026-08-13 04:48:05.77479	1
1115	154	1	27.900	\N	2026-08-13 04:49:14.216822	1
1116	154	2	27.450	\N	2026-08-13 04:49:14.216822	1
1117	154	3	28.250	\N	2026-08-13 04:49:14.216822	1
1118	154	4	26.400	\N	2026-08-13 04:49:14.216822	1
1119	154	5	27.650	\N	2026-08-13 04:49:14.216822	1
1120	155	1	19.800	\N	2026-08-13 04:50:17.260845	1
1121	155	2	29.800	\N	2026-08-13 04:50:17.260845	1
1122	155	3	30.550	\N	2026-08-13 04:50:17.260845	1
1123	155	4	28.400	\N	2026-08-13 04:50:17.260845	1
1124	155	5	31.000	\N	2026-08-13 04:50:17.260845	1
1125	155	6	29.600	\N	2026-08-13 04:50:17.260845	1
1126	155	7	31.600	\N	2026-08-13 04:50:17.260845	1
1127	155	8	29.200	\N	2026-08-13 04:50:17.260845	1
1128	156	1	27.350	\N	2026-08-13 04:51:23.964216	1
1129	156	2	29.700	\N	2026-08-13 04:51:23.964216	1
1130	156	3	24.500	\N	2026-08-13 04:51:23.964216	1
1131	156	4	29.800	\N	2026-08-13 04:51:23.964216	1
1132	156	5	25.050	\N	2026-08-13 04:51:23.964216	1
1133	156	6	29.300	\N	2026-08-13 04:51:23.964216	1
1134	156	7	25.050	\N	2026-08-13 04:51:23.964216	1
1135	156	8	33.400	\N	2026-08-13 04:51:23.964216	1
1136	156	9	25.900	\N	2026-08-13 04:51:23.964216	1
1137	156	10	19.650	\N	2026-08-13 04:51:23.964216	1
1138	152	1	26.700	\N	2026-08-15 05:54:52.425583	1
1139	152	2	9.350	\N	2026-08-15 05:54:52.425583	1
1140	152	3	24.850	\N	2026-08-15 05:54:52.425583	1
1141	152	4	25.050	\N	2026-08-15 05:54:52.425583	1
1142	157	1	19.100	\N	2026-08-15 05:57:47.128772	1
1143	158	1	27.900	\N	2026-08-15 06:02:43.362655	1
1144	159	1	29.700	\N	2026-08-15 06:03:48.665526	1
1145	159	2	32.200	\N	2026-08-15 06:03:48.665526	1
1146	159	3	28.000	\N	2026-08-15 06:03:48.665526	1
1147	159	4	27.650	\N	2026-08-15 06:03:48.665526	1
1148	159	5	28.950	\N	2026-08-15 06:03:48.665526	1
1149	159	6	28.800	\N	2026-08-15 06:03:48.665526	1
1150	159	7	29.600	\N	2026-08-15 06:03:48.665526	1
1151	160	1	30.500	\N	2026-08-15 06:04:23.470122	1
1152	160	2	21.900	\N	2026-08-15 06:04:23.470122	1
1153	161	1	30.700	\N	2026-08-15 06:06:26.1927	1
1154	161	2	21.100	\N	2026-08-15 06:06:26.1927	1
1155	161	3	25.900	\N	2026-08-15 06:06:26.1927	1
1156	161	4	26.200	\N	2026-08-15 06:06:26.1927	1
1157	161	5	27.350	\N	2026-08-15 06:06:26.1927	1
1158	161	6	28.300	\N	2026-08-15 06:06:26.1927	1
1159	161	7	26.800	\N	2026-08-15 06:06:26.1927	1
1160	161	8	27.450	\N	2026-08-15 06:06:26.1927	1
1161	162	1	20.650	\N	2026-08-15 06:07:04.277791	1
1162	163	1	27.250	\N	2026-08-15 06:08:05.670254	1
1163	163	2	25.400	\N	2026-08-15 06:08:05.670254	1
1164	163	3	31.050	\N	2026-08-15 06:08:05.670254	1
1165	163	4	31.050	\N	2026-08-15 06:08:05.670254	1
1166	163	5	27.100	\N	2026-08-15 06:08:05.670254	1
1167	163	6	26.400	\N	2026-08-15 06:08:05.670254	1
1168	163	7	25.950	\N	2026-08-15 06:08:05.670254	1
1169	163	8	27.250	\N	2026-08-15 06:08:05.670254	1
1170	163	9	27.600	\N	2026-08-15 06:08:05.670254	1
1171	164	1	25.300	\N	2026-08-15 06:08:57.221169	1
1172	164	2	24.650	\N	2026-08-15 06:08:57.221169	1
1173	164	3	25.700	\N	2026-08-15 06:08:57.221169	1
1174	164	4	27.150	\N	2026-08-15 06:08:57.221169	1
1175	164	5	27.200	\N	2026-08-15 06:08:57.221169	1
1176	164	6	26.800	\N	2026-08-15 06:08:57.221169	1
1177	164	7	27.200	\N	2026-08-15 06:08:57.221169	1
1178	164	8	26.550	\N	2026-08-15 06:08:57.221169	1
1179	164	9	28.500	\N	2026-08-15 06:08:57.221169	1
1180	165	1	18.650	\N	2026-08-15 06:09:52.093661	1
1181	165	2	28.350	\N	2026-08-15 06:09:52.093661	1
1182	165	3	29.550	\N	2026-08-15 06:09:52.093661	1
1183	165	4	27.900	\N	2026-08-15 06:09:52.093661	1
1184	165	5	27.900	\N	2026-08-15 06:09:52.093661	1
1185	165	6	29.000	\N	2026-08-15 06:09:52.093661	1
1186	165	7	31.200	\N	2026-08-15 06:09:52.093661	1
1187	166	1	20.650	\N	2026-08-15 06:11:02.348358	1
1188	166	2	30.150	\N	2026-08-15 06:11:02.348358	1
1189	166	3	30.800	\N	2026-08-15 06:11:02.348358	1
1190	166	4	29.800	\N	2026-08-15 06:11:02.348358	1
1191	166	5	30.100	\N	2026-08-15 06:11:02.348358	1
1192	166	6	30.350	\N	2026-08-15 06:11:02.348358	1
1193	166	7	31.750	\N	2026-08-15 06:11:02.348358	1
1272	178	6	28.900	\N	2026-08-17 05:21:35.499855	1
1273	178	7	28.650	\N	2026-08-17 05:21:35.499855	1
1274	178	8	28.350	\N	2026-08-17 05:21:35.499855	1
1275	179	1	28.150	\N	2026-08-17 05:22:36.693698	1
1276	179	2	26.750	\N	2026-08-17 05:22:36.693698	1
1277	179	3	28.300	\N	2026-08-17 05:22:36.693698	1
1278	179	4	26.800	\N	2026-08-17 05:22:36.693698	1
1279	179	5	28.450	\N	2026-08-17 05:22:36.693698	1
1280	179	6	27.250	\N	2026-08-17 05:22:36.693698	1
1281	179	7	28.350	\N	2026-08-17 05:22:36.693698	1
1282	179	8	26.750	\N	2026-08-17 05:22:36.693698	1
1283	180	1	27.550	\N	2026-08-17 05:23:30.453518	1
1284	180	2	24.200	\N	2026-08-17 05:23:30.453518	1
1285	180	3	16.000	\N	2026-08-17 05:23:30.453518	1
1286	180	4	13.100	\N	2026-08-17 05:23:30.453518	1
1287	180	5	26.200	\N	2026-08-17 05:23:30.453518	1
1288	180	6	28.300	\N	2026-08-17 05:23:30.453518	1
1289	180	7	25.450	\N	2026-08-17 05:23:30.453518	1
1290	181	1	24.550	\N	2026-08-17 05:24:23.26763	1
1291	181	2	22.100	\N	2026-08-17 05:24:23.26763	1
1292	181	3	25.900	\N	2026-08-17 05:24:23.26763	1
1293	181	4	22.700	\N	2026-08-17 05:24:23.26763	1
1294	181	5	26.800	\N	2026-08-17 05:24:23.26763	1
1295	181	6	27.350	\N	2026-08-17 05:24:23.26763	1
1296	182	1	26.150	\N	2026-08-17 05:25:28.201228	1
1297	182	2	28.250	\N	2026-08-17 05:25:28.201228	1
1298	182	3	26.400	\N	2026-08-17 05:25:28.201228	1
1299	182	4	26.900	\N	2026-08-17 05:25:28.201228	1
1300	182	5	28.250	\N	2026-08-17 05:25:28.201228	1
1301	182	6	29.750	\N	2026-08-17 05:25:28.201228	1
1302	182	7	26.100	\N	2026-08-17 05:25:28.201228	1
1303	182	8	27.000	\N	2026-08-17 05:25:28.201228	1
1304	182	9	25.200	\N	2026-08-17 05:25:28.201228	1
1305	183	1	22.650	\N	2026-08-17 05:26:31.576617	1
1306	183	2	26.800	\N	2026-08-17 05:26:31.576617	1
1307	183	3	26.850	\N	2026-08-17 05:26:31.576617	1
1308	183	4	26.450	\N	2026-08-17 05:26:31.576617	1
1309	183	5	27.550	\N	2026-08-17 05:26:31.576617	1
1310	183	6	26.050	\N	2026-08-17 05:26:31.576617	1
1311	183	7	28.450	\N	2026-08-17 05:26:31.576617	1
1312	183	8	25.250	\N	2026-08-17 05:26:31.576617	1
1313	183	9	26.750	\N	2026-08-17 05:26:31.576617	1
1314	184	1	32.350	\N	2026-08-17 05:27:33.906173	1
1315	184	2	29.200	\N	2026-08-17 05:27:33.906173	1
1316	184	3	28.100	\N	2026-08-17 05:27:33.906173	1
1317	184	4	28.600	\N	2026-08-17 05:27:33.906173	1
1318	184	5	29.400	\N	2026-08-17 05:27:33.906173	1
1319	184	6	27.250	\N	2026-08-17 05:27:33.906173	1
1320	184	7	31.850	\N	2026-08-17 05:27:33.906173	1
1321	185	1	23.800	\N	2026-08-17 05:28:25.149654	1
1322	185	2	28.800	\N	2026-08-17 05:28:25.149654	1
1323	185	3	23.850	\N	2026-08-17 05:28:25.149654	1
1324	185	4	20.200	\N	2026-08-17 05:28:25.149654	1
1325	185	5	19.400	\N	2026-08-17 05:28:25.149654	1
1326	185	6	22.450	\N	2026-08-17 05:28:25.149654	1
1327	185	7	22.100	\N	2026-08-17 05:28:25.149654	1
1337	173	1	31.400	\N	2026-08-17 12:59:49.124489	1
1338	173	2	31.400	\N	2026-08-17 12:59:49.124489	1
1339	173	3	25.450	\N	2026-08-17 12:59:49.124489	1
1340	173	4	26.100	\N	2026-08-17 12:59:49.124489	1
1341	173	5	25.850	\N	2026-08-17 12:59:49.124489	1
1342	173	6	27.150	\N	2026-08-17 12:59:49.124489	1
1343	173	7	27.150	\N	2026-08-17 12:59:49.124489	1
1344	173	8	25.600	\N	2026-08-17 12:59:49.124489	1
1345	173	9	27.750	\N	2026-08-17 12:59:49.124489	1
1346	186	1	26.600	\N	2026-08-18 04:52:31.321758	1
1347	186	2	21.900	\N	2026-08-18 04:52:31.321758	1
1348	186	3	28.250	\N	2026-08-18 04:52:31.321758	1
1349	186	4	27.250	\N	2026-08-18 04:52:31.321758	1
1350	186	5	27.950	\N	2026-08-18 04:52:31.321758	1
1351	186	6	26.700	\N	2026-08-18 04:52:31.321758	1
1352	186	7	29.150	\N	2026-08-18 04:52:31.321758	1
1353	186	8	29.700	\N	2026-08-18 04:52:31.321758	1
1354	186	9	25.650	\N	2026-08-18 04:52:31.321758	1
1355	187	1	27.100	\N	2026-08-18 04:53:36.119909	1
1356	187	2	26.650	\N	2026-08-18 04:53:36.119909	1
1357	187	3	27.000	\N	2026-08-18 04:53:36.119909	1
1358	187	4	24.600	\N	2026-08-18 04:53:36.119909	1
1359	187	5	27.150	\N	2026-08-18 04:53:36.119909	1
1360	187	6	26.400	\N	2026-08-18 04:53:36.119909	1
1361	187	7	25.450	\N	2026-08-18 04:53:36.119909	1
1362	187	8	26.500	\N	2026-08-18 04:53:36.119909	1
1363	187	9	20.950	\N	2026-08-18 04:53:36.119909	1
1364	188	1	25.450	\N	2026-08-18 04:54:41.341051	1
1365	188	2	26.850	\N	2026-08-18 04:54:41.341051	1
1366	188	3	26.650	\N	2026-08-18 04:54:41.341051	1
1367	188	4	24.950	\N	2026-08-18 04:54:41.341051	1
1368	188	5	22.250	\N	2026-08-18 04:54:41.341051	1
1369	188	6	25.800	\N	2026-08-18 04:54:41.341051	1
1370	188	7	23.700	\N	2026-08-18 04:54:41.341051	1
1371	188	8	19.400	\N	2026-08-18 04:54:41.341051	1
1372	189	1	21.000	\N	2026-08-18 04:55:37.622849	1
1373	189	2	19.250	\N	2026-08-18 04:55:37.622849	1
1374	189	3	22.500	\N	2026-08-18 04:55:37.622849	1
1375	189	4	21.850	\N	2026-08-18 04:55:37.622849	1
1376	189	5	21.300	\N	2026-08-18 04:55:37.622849	1
1377	189	6	19.850	\N	2026-08-18 04:55:37.622849	1
1378	189	7	23.000	\N	2026-08-18 04:55:37.622849	1
1379	189	8	18.350	\N	2026-08-18 04:55:37.622849	1
1380	190	1	24.450	\N	2026-08-18 04:56:56.733562	1
1381	190	2	27.000	\N	2026-08-18 04:56:56.733562	1
1382	190	3	25.450	\N	2026-08-18 04:56:56.733562	1
1383	190	4	26.650	\N	2026-08-18 04:56:56.733562	1
1384	190	5	26.150	\N	2026-08-18 04:56:56.733562	1
1385	190	6	27.700	\N	2026-08-18 04:56:56.733562	1
1386	190	7	26.700	\N	2026-08-18 04:56:56.733562	1
1387	190	8	25.700	\N	2026-08-18 04:56:56.733562	1
1388	190	9	27.000	\N	2026-08-18 04:56:56.733562	1
1389	191	1	19.450	\N	2026-08-18 04:58:03.260133	1
1390	191	2	27.150	\N	2026-08-18 04:58:03.260133	1
1391	191	3	26.050	\N	2026-08-18 04:58:03.260133	1
1392	191	4	26.200	\N	2026-08-18 04:58:03.260133	1
1393	191	5	25.450	\N	2026-08-18 04:58:03.260133	1
1394	191	6	28.150	\N	2026-08-18 04:58:03.260133	1
1395	191	7	28.200	\N	2026-08-18 04:58:03.260133	1
1396	191	8	26.700	\N	2026-08-18 04:58:03.260133	1
1397	191	9	27.500	\N	2026-08-18 04:58:03.260133	1
1398	192	1	25.900	\N	2026-08-18 04:59:14.986452	1
1399	192	2	30.300	\N	2026-08-18 04:59:14.986452	1
1400	192	3	28.650	\N	2026-08-18 04:59:14.986452	1
1401	192	4	30.450	\N	2026-08-18 04:59:14.986452	1
1402	192	5	29.700	\N	2026-08-18 04:59:14.986452	1
1403	192	6	31.200	\N	2026-08-18 04:59:14.986452	1
1404	193	1	21.100	\N	2026-08-18 05:00:05.173048	1
1405	193	2	23.000	\N	2026-08-18 05:00:05.173048	1
1406	193	3	20.400	\N	2026-08-18 05:00:05.173048	1
1407	193	4	26.500	\N	2026-08-18 05:00:05.173048	1
1408	193	5	23.400	\N	2026-08-18 05:00:05.173048	1
1409	193	6	22.650	\N	2026-08-18 05:00:05.173048	1
1410	193	7	23.750	\N	2026-08-18 05:00:05.173048	1
1411	194	1	27.450	\N	2026-08-19 04:14:15.119295	1
1412	194	2	25.150	\N	2026-08-19 04:14:15.119295	1
1413	194	3	26.900	\N	2026-08-19 04:14:15.119295	1
1414	194	4	27.750	\N	2026-08-19 04:14:15.119295	1
1415	194	5	27.300	\N	2026-08-19 04:14:15.119295	1
1416	194	6	27.550	\N	2026-08-19 04:14:15.119295	1
1417	194	7	27.650	\N	2026-08-19 04:14:15.119295	1
1418	194	8	27.850	\N	2026-08-19 04:14:15.119295	1
1419	194	9	29.200	\N	2026-08-19 04:14:15.119295	1
1420	195	1	25.150	\N	2026-08-19 04:18:39.081607	1
1421	195	2	24.900	\N	2026-08-19 04:18:39.081607	1
1422	195	3	25.200	\N	2026-08-19 04:18:39.081607	1
1423	195	4	27.800	\N	2026-08-19 04:18:39.081607	1
1424	195	5	25.000	\N	2026-08-19 04:18:39.081607	1
1425	195	6	23.000	\N	2026-08-19 04:18:39.081607	1
1426	195	7	28.100	\N	2026-08-19 04:18:39.081607	1
1427	195	8	26.750	\N	2026-08-19 04:18:39.081607	1
1428	195	9	27.350	\N	2026-08-19 04:18:39.081607	1
1429	196	1	23.400	\N	2026-08-19 04:19:23.905054	1
1430	196	2	24.650	\N	2026-08-19 04:19:23.905054	1
1431	196	3	24.700	\N	2026-08-19 04:19:23.905054	1
1432	196	4	25.700	\N	2026-08-19 04:19:23.905054	1
1433	196	5	24.850	\N	2026-08-19 04:19:23.905054	1
1434	197	1	20.850	\N	2026-08-19 04:19:54.187297	1
1435	197	2	18.000	\N	2026-08-19 04:19:54.187297	1
1436	198	1	24.600	\N	2026-08-19 04:20:43.446799	1
1437	198	2	28.750	\N	2026-08-19 04:20:43.446799	1
1438	198	3	27.000	\N	2026-08-19 04:20:43.446799	1
1439	198	4	28.650	\N	2026-08-19 04:20:43.446799	1
1440	198	5	26.800	\N	2026-08-19 04:20:43.446799	1
1441	198	6	28.550	\N	2026-08-19 04:20:43.446799	1
1442	198	7	24.650	\N	2026-08-19 04:20:43.446799	1
1443	199	1	23.500	\N	2026-08-19 04:21:41.522123	1
1444	199	2	26.450	\N	2026-08-19 04:21:41.522123	1
1445	199	3	20.550	\N	2026-08-19 04:21:41.522123	1
1446	199	4	22.800	\N	2026-08-19 04:21:41.522123	1
1447	199	5	22.700	\N	2026-08-19 04:21:41.522123	1
1448	199	6	22.800	\N	2026-08-19 04:21:41.522123	1
1449	199	7	24.850	\N	2026-08-19 04:21:41.522123	1
1450	200	1	25.400	\N	2026-08-19 04:22:41.562026	1
1451	200	2	26.850	\N	2026-08-19 04:22:41.562026	1
1452	200	3	25.550	\N	2026-08-19 04:22:41.562026	1
1453	200	4	27.900	\N	2026-08-19 04:22:41.562026	1
1454	200	5	25.500	\N	2026-08-19 04:22:41.562026	1
1455	200	6	25.300	\N	2026-08-19 04:22:41.562026	1
1456	200	7	26.600	\N	2026-08-19 04:22:41.562026	1
1457	200	8	30.050	\N	2026-08-19 04:22:41.562026	1
1458	200	9	26.550	\N	2026-08-19 04:22:41.562026	1
1459	201	1	25.150	\N	2026-08-19 04:23:38.595844	1
1460	201	2	19.650	\N	2026-08-19 04:23:38.595844	1
1461	201	3	25.600	\N	2026-08-19 04:23:38.595844	1
1462	201	4	26.200	\N	2026-08-19 04:23:38.595844	1
1463	201	5	25.550	\N	2026-08-19 04:23:38.595844	1
1464	201	6	27.700	\N	2026-08-19 04:23:38.595844	1
1465	201	7	27.100	\N	2026-08-19 04:23:38.595844	1
1466	201	8	26.400	\N	2026-08-19 04:23:38.595844	1
1467	201	9	28.200	\N	2026-08-19 04:23:38.595844	1
1468	202	1	28.050	\N	2026-08-19 04:24:34.972893	1
1469	202	2	30.200	\N	2026-08-19 04:24:34.972893	1
1470	202	3	30.700	\N	2026-08-19 04:24:34.972893	1
1471	202	4	29.400	\N	2026-08-19 04:24:34.972893	1
1472	202	5	30.800	\N	2026-08-19 04:24:34.972893	1
1473	202	6	31.250	\N	2026-08-19 04:24:34.972893	1
1474	202	7	26.550	\N	2026-08-19 04:24:34.972893	1
1475	203	1	25.650	\N	2026-08-19 04:25:30.946876	1
1476	203	2	28.950	\N	2026-08-19 04:25:30.946876	1
1477	203	3	22.050	\N	2026-08-19 04:25:30.946876	1
1478	203	4	22.000	\N	2026-08-19 04:25:30.946876	1
1479	203	5	23.600	\N	2026-08-19 04:25:30.946876	1
1480	203	6	26.750	\N	2026-08-19 04:25:30.946876	1
1481	203	7	24.550	\N	2026-08-19 04:25:30.946876	1
1482	204	1	25.950	\N	2026-08-20 04:22:07.852447	1
1483	204	2	26.450	\N	2026-08-20 04:22:07.852447	1
1484	204	3	27.750	\N	2026-08-20 04:22:07.852447	1
1485	204	4	28.300	\N	2026-08-20 04:22:07.852447	1
1486	204	5	28.150	\N	2026-08-20 04:22:07.852447	1
1487	204	6	27.600	\N	2026-08-20 04:22:07.852447	1
1488	204	7	28.450	\N	2026-08-20 04:22:07.852447	1
1489	204	8	29.600	\N	2026-08-20 04:22:07.852447	1
1490	204	9	28.050	\N	2026-08-20 04:22:07.852447	1
1491	205	1	25.750	\N	2026-08-20 04:23:18.573807	1
1492	205	2	26.400	\N	2026-08-20 04:23:18.573807	1
1493	205	3	24.450	\N	2026-08-20 04:23:18.573807	1
1494	205	4	28.150	\N	2026-08-20 04:23:18.573807	1
1495	205	5	28.150	\N	2026-08-20 04:23:18.573807	1
1496	205	6	26.600	\N	2026-08-20 04:23:18.573807	1
1497	205	7	25.600	\N	2026-08-20 04:23:18.573807	1
1498	205	8	26.150	\N	2026-08-20 04:23:18.573807	1
1499	205	9	27.200	\N	2026-08-20 04:23:18.573807	1
1500	206	1	27.800	\N	2026-08-20 04:25:32.833822	1
1501	206	2	27.600	\N	2026-08-20 04:25:32.833822	1
1502	206	3	28.700	\N	2026-08-20 04:25:32.833822	1
1503	206	4	26.050	\N	2026-08-20 04:25:32.833822	1
1504	206	5	24.650	\N	2026-08-20 04:25:32.833822	1
1505	206	6	26.500	\N	2026-08-20 04:25:32.833822	1
1506	206	7	27.800	\N	2026-08-20 04:25:32.833822	1
1507	206	8	26.500	\N	2026-08-20 04:25:32.833822	1
1508	206	9	26.250	\N	2026-08-20 04:25:32.833822	1
1509	206	10	25.300	\N	2026-08-20 04:25:32.833822	1
1510	206	11	26.300	\N	2026-08-20 04:25:32.833822	1
1511	207	1	8.000	\N	2026-08-20 04:27:49.104865	1
1512	207	2	29.250	\N	2026-08-20 04:27:49.104865	1
1513	208	1	13.400	\N	2026-08-20 04:28:21.745778	1
1514	209	1	22.900	\N	2026-08-20 04:29:27.538971	1
1515	209	2	27.000	\N	2026-08-20 04:29:27.538971	1
1516	209	3	25.100	\N	2026-08-20 04:29:27.538971	1
1517	209	4	22.650	\N	2026-08-20 04:29:27.538971	1
1518	209	5	15.200	\N	2026-08-20 04:29:27.538971	1
1519	209	6	9.200	\N	2026-08-20 04:29:27.538971	1
1520	209	7	21.400	\N	2026-08-20 04:29:27.538971	1
1521	209	8	26.200	\N	2026-08-20 04:29:27.538971	1
1522	210	1	28.450	\N	2026-08-20 04:35:30.244206	1
1523	210	2	25.500	\N	2026-08-20 04:35:30.244206	1
1524	210	3	27.900	\N	2026-08-20 04:35:30.244206	1
1525	210	4	26.450	\N	2026-08-20 04:35:30.244206	1
1526	210	5	25.200	\N	2026-08-20 04:35:30.244206	1
1527	210	6	26.300	\N	2026-08-20 04:35:30.244206	1
1528	210	7	27.750	\N	2026-08-20 04:35:30.244206	1
1529	210	8	25.900	\N	2026-08-20 04:35:30.244206	1
1530	210	9	26.900	\N	2026-08-20 04:35:30.244206	1
1531	211	1	21.150	\N	2026-08-20 04:36:22.480788	1
1532	211	2	24.900	\N	2026-08-20 04:36:22.480788	1
1533	211	3	26.600	\N	2026-08-20 04:36:22.480788	1
1534	211	4	25.050	\N	2026-08-20 04:36:22.480788	1
1535	211	5	25.150	\N	2026-08-20 04:36:22.480788	1
1536	211	6	26.900	\N	2026-08-20 04:36:22.480788	1
1537	211	7	25.750	\N	2026-08-20 04:36:22.480788	1
1538	211	8	25.000	\N	2026-08-20 04:36:22.480788	1
1539	211	9	26.850	\N	2026-08-20 04:36:22.480788	1
1540	212	1	27.950	\N	2026-08-20 04:37:16.81992	1
1541	212	2	27.950	\N	2026-08-20 04:37:16.81992	1
1542	212	3	26.650	\N	2026-08-20 04:37:16.81992	1
1543	212	4	30.000	\N	2026-08-20 04:37:16.81992	1
1544	212	5	25.700	\N	2026-08-20 04:37:16.81992	1
1545	212	6	30.000	\N	2026-08-20 04:37:16.81992	1
1546	212	7	28.450	\N	2026-08-20 04:37:16.81992	1
1547	212	8	26.450	\N	2026-08-20 04:37:16.81992	1
1548	212	9	28.750	\N	2026-08-20 04:37:16.81992	1
1549	213	1	27.900	\N	2026-08-20 04:38:05.935748	1
1550	213	2	26.400	\N	2026-08-20 04:38:05.935748	1
1551	213	3	28.000	\N	2026-08-20 04:38:05.935748	1
1552	213	4	27.900	\N	2026-08-20 04:38:05.935748	1
1553	213	5	28.350	\N	2026-08-20 04:38:05.935748	1
1554	213	6	28.800	\N	2026-08-20 04:38:05.935748	1
1555	213	7	29.700	\N	2026-08-20 04:38:05.935748	1
1556	214	1	22.000	\N	2026-08-20 04:38:54.492376	1
1557	214	2	23.350	\N	2026-08-20 04:38:54.492376	1
1558	214	3	25.800	\N	2026-08-20 04:38:54.492376	1
1559	214	4	24.300	\N	2026-08-20 04:38:54.492376	1
1560	214	5	24.050	\N	2026-08-20 04:38:54.492376	1
1561	214	6	21.150	\N	2026-08-20 04:38:54.492376	1
1562	214	7	28.450	\N	2026-08-20 04:38:54.492376	1
1563	215	1	26.650	\N	2026-08-21 04:33:25.994244	1
1564	215	2	27.700	\N	2026-08-21 04:33:25.994244	1
1565	215	3	27.350	\N	2026-08-21 04:33:25.994244	1
1566	215	4	27.100	\N	2026-08-21 04:33:25.994244	1
1567	215	5	26.900	\N	2026-08-21 04:33:25.994244	1
1568	215	6	27.000	\N	2026-08-21 04:33:25.994244	1
1569	215	7	26.150	\N	2026-08-21 04:33:25.994244	1
1570	215	8	26.400	\N	2026-08-21 04:33:25.994244	1
1571	215	9	27.850	\N	2026-08-21 04:33:25.994244	1
1572	216	1	26.550	\N	2026-08-21 04:34:26.886079	1
1573	216	2	26.900	\N	2026-08-21 04:34:26.886079	1
1574	216	3	24.400	\N	2026-08-21 04:34:26.886079	1
1575	216	4	26.000	\N	2026-08-21 04:34:26.886079	1
1576	216	5	27.850	\N	2026-08-21 04:34:26.886079	1
1577	216	6	27.650	\N	2026-08-21 04:34:26.886079	1
1578	216	7	23.900	\N	2026-08-21 04:34:26.886079	1
1579	216	8	23.950	\N	2026-08-21 04:34:26.886079	1
1580	216	9	26.800	\N	2026-08-21 04:34:26.886079	1
1581	217	1	31.450	\N	2026-08-21 04:35:27.404379	1
1582	217	2	28.250	\N	2026-08-21 04:35:27.404379	1
1583	217	3	22.400	\N	2026-08-21 04:35:27.404379	1
1584	217	4	28.200	\N	2026-08-21 04:35:27.404379	1
1585	217	5	29.450	\N	2026-08-21 04:35:27.404379	1
1586	217	6	26.800	\N	2026-08-21 04:35:27.404379	1
1587	217	7	28.000	\N	2026-08-21 04:35:27.404379	1
1588	218	1	12.750	\N	2026-08-21 04:36:12.468441	1
1589	218	2	32.000	\N	2026-08-21 04:36:12.468441	1
1590	218	3	28.600	\N	2026-08-21 04:36:12.468441	1
1591	218	4	28.850	\N	2026-08-21 04:36:12.468441	1
1592	218	5	26.150	\N	2026-08-21 04:36:12.468441	1
1593	218	6	17.100	\N	2026-08-21 04:36:12.468441	1
1594	219	1	20.100	\N	2026-08-21 04:37:10.064042	1
1595	219	2	25.000	\N	2026-08-21 04:37:10.064042	1
1596	219	3	19.850	\N	2026-08-21 04:37:10.064042	1
1597	219	4	22.650	\N	2026-08-21 04:37:10.064042	1
1598	219	5	23.050	\N	2026-08-21 04:37:10.064042	1
1599	219	6	22.100	\N	2026-08-21 04:37:10.064042	1
1600	219	7	15.100	\N	2026-08-21 04:37:10.064042	1
1601	220	1	26.700	\N	2026-08-21 04:39:16.945034	1
1602	220	2	25.500	\N	2026-08-21 04:39:16.945034	1
1603	220	3	28.100	\N	2026-08-21 04:39:16.945034	1
1604	220	4	24.700	\N	2026-08-21 04:39:16.945034	1
1605	220	5	27.650	\N	2026-08-21 04:39:16.945034	1
1606	220	6	25.050	\N	2026-08-21 04:39:16.945034	1
1607	220	7	25.200	\N	2026-08-21 04:39:16.945034	1
1608	220	8	29.200	\N	2026-08-21 04:39:16.945034	1
1609	220	9	29.800	\N	2026-08-21 04:39:16.945034	1
1610	221	1	26.400	\N	2026-08-21 04:40:09.949218	1
1611	221	2	20.700	\N	2026-08-21 04:40:09.949218	1
1612	221	3	26.750	\N	2026-08-21 04:40:09.949218	1
1613	221	4	24.350	\N	2026-08-21 04:40:09.949218	1
1614	221	5	26.600	\N	2026-08-21 04:40:09.949218	1
1615	221	6	26.050	\N	2026-08-21 04:40:09.949218	1
1616	221	7	25.100	\N	2026-08-21 04:40:09.949218	1
1617	221	8	27.050	\N	2026-08-21 04:40:09.949218	1
1618	221	9	28.050	\N	2026-08-21 04:40:09.949218	1
1619	222	1	34.000	\N	2026-08-21 04:41:30.403069	1
1620	222	2	22.900	\N	2026-08-21 04:41:30.403069	1
1621	222	3	29.500	\N	2026-08-21 04:41:30.403069	1
1622	222	4	27.900	\N	2026-08-21 04:41:30.403069	1
1623	222	5	27.200	\N	2026-08-21 04:41:30.403069	1
1624	222	6	26.050	\N	2026-08-21 04:41:30.403069	1
1625	222	7	28.450	\N	2026-08-21 04:41:30.403069	1
1626	222	8	29.750	\N	2026-08-21 04:41:30.403069	1
1627	222	9	29.100	\N	2026-08-21 04:41:30.403069	1
1628	223	1	28.250	\N	2026-08-21 04:42:25.449944	1
1629	223	2	27.700	\N	2026-08-21 04:42:25.449944	1
1630	223	3	29.050	\N	2026-08-21 04:42:25.449944	1
1631	223	4	23.400	\N	2026-08-21 04:42:25.449944	1
1632	223	5	26.550	\N	2026-08-21 04:42:25.449944	1
1633	223	6	21.950	\N	2026-08-21 04:42:25.449944	1
1634	223	7	30.000	\N	2026-08-21 04:42:25.449944	1
1635	223	8	29.500	\N	2026-08-21 04:42:25.449944	1
1636	223	9	30.750	\N	2026-08-21 04:42:25.449944	1
1637	224	1	27.950	\N	2026-08-21 04:43:39.151219	1
1638	224	2	25.150	\N	2026-08-21 04:43:39.151219	1
1639	224	3	25.200	\N	2026-08-21 04:43:39.151219	1
1640	224	4	23.100	\N	2026-08-21 04:43:39.151219	1
1641	224	5	18.200	\N	2026-08-21 04:43:39.151219	1
1642	224	6	24.800	\N	2026-08-21 04:43:39.151219	1
1643	224	7	29.200	\N	2026-08-21 04:43:39.151219	1
1644	225	1	28.550	\N	2026-08-21 15:16:11.556372	1
1645	225	2	27.250	\N	2026-08-21 15:16:11.556372	1
1646	225	3	28.550	\N	2026-08-21 15:16:11.556372	1
1647	225	4	27.550	\N	2026-08-21 15:16:11.556372	1
1648	225	5	28.100	\N	2026-08-21 15:16:11.556372	1
1649	225	6	22.700	\N	2026-08-21 15:16:11.556372	1
1650	225	7	28.050	\N	2026-08-21 15:16:11.556372	1
1651	225	8	26.850	\N	2026-08-21 15:16:11.556372	1
1652	226	1	26.800	\N	2026-08-21 15:17:06.048513	1
1653	226	2	28.200	\N	2026-08-21 15:17:06.048513	1
1654	226	3	26.700	\N	2026-08-21 15:17:06.048513	1
1655	226	4	27.450	\N	2026-08-21 15:17:06.048513	1
1656	226	5	26.900	\N	2026-08-21 15:17:06.048513	1
1657	226	6	21.900	\N	2026-08-21 15:17:06.048513	1
1658	226	7	27.850	\N	2026-08-21 15:17:06.048513	1
1659	226	8	27.000	\N	2026-08-21 15:17:06.048513	1
1660	227	1	28.500	\N	2026-08-21 15:18:18.06769	1
1661	227	2	29.200	\N	2026-08-21 15:18:18.06769	1
1662	227	3	28.000	\N	2026-08-21 15:18:18.06769	1
1663	227	4	26.550	\N	2026-08-21 15:18:18.06769	1
1664	227	5	27.850	\N	2026-08-21 15:18:18.06769	1
1665	227	6	26.850	\N	2026-08-21 15:18:18.06769	1
1666	227	7	27.800	\N	2026-08-21 15:18:18.06769	1
1667	227	8	8.050	\N	2026-08-21 15:18:18.06769	1
1668	228	1	26.450	\N	2026-08-21 15:19:39.772427	1
1669	228	2	22.100	\N	2026-08-21 15:19:39.772427	1
1670	228	3	22.450	\N	2026-08-21 15:19:39.772427	1
1671	228	4	30.550	\N	2026-08-21 15:19:39.772427	1
1672	228	5	23.800	\N	2026-08-21 15:19:39.772427	1
1673	228	6	25.950	\N	2026-08-21 15:19:39.772427	1
1674	228	7	28.800	\N	2026-08-21 15:19:39.772427	1
1675	228	8	23.000	\N	2026-08-21 15:19:39.772427	1
1676	228	9	33.600	\N	2026-08-21 15:19:39.772427	1
1677	229	1	24.100	\N	2026-08-21 15:20:37.748251	1
1678	229	2	16.350	\N	2026-08-21 15:20:37.748251	1
1679	229	3	25.650	\N	2026-08-21 15:20:37.748251	1
1680	229	4	17.750	\N	2026-08-21 15:20:37.748251	1
1681	229	5	27.150	\N	2026-08-21 15:20:37.748251	1
1682	229	6	23.550	\N	2026-08-21 15:20:37.748251	1
1683	229	7	19.450	\N	2026-08-21 15:20:37.748251	1
1684	230	1	25.300	\N	2026-08-22 04:19:37.09366	1
1685	230	2	24.450	\N	2026-08-22 04:19:37.09366	1
1686	230	3	25.600	\N	2026-08-22 04:19:37.09366	1
1687	230	4	28.200	\N	2026-08-22 04:19:37.09366	1
1688	230	5	26.650	\N	2026-08-22 04:19:37.09366	1
1689	230	6	27.350	\N	2026-08-22 04:19:37.09366	1
1690	230	7	25.950	\N	2026-08-22 04:19:37.09366	1
1691	230	8	26.650	\N	2026-08-22 04:19:37.09366	1
1692	230	9	26.700	\N	2026-08-22 04:19:37.09366	1
1693	231	1	18.900	\N	2026-08-22 04:20:37.880008	1
1694	231	2	20.650	\N	2026-08-22 04:20:37.880008	1
1695	231	3	26.200	\N	2026-08-22 04:20:37.880008	1
1696	231	4	26.800	\N	2026-08-22 04:20:37.880008	1
1697	231	5	26.300	\N	2026-08-22 04:20:37.880008	1
1698	231	6	26.900	\N	2026-08-22 04:20:37.880008	1
1699	231	7	25.400	\N	2026-08-22 04:20:37.880008	1
1700	231	8	28.150	\N	2026-08-22 04:20:37.880008	1
1701	232	1	23.300	\N	2026-08-22 04:21:45.271294	1
1702	232	2	27.000	\N	2026-08-22 04:21:45.271294	1
1703	232	3	30.350	\N	2026-08-22 04:21:45.271294	1
1704	232	4	31.650	\N	2026-08-22 04:21:45.271294	1
1705	232	5	27.400	\N	2026-08-22 04:21:45.271294	1
1706	232	6	30.850	\N	2026-08-22 04:21:45.271294	1
1707	232	7	28.800	\N	2026-08-22 04:21:45.271294	1
1708	232	8	30.250	\N	2026-08-22 04:21:45.271294	1
1709	232	9	28.900	\N	2026-08-22 04:21:45.271294	1
1710	233	1	24.400	\N	2026-08-22 04:23:08.606383	1
1711	233	2	18.200	\N	2026-08-22 04:23:08.606383	1
1712	233	3	25.500	\N	2026-08-22 04:23:08.606383	1
1713	233	4	28.650	\N	2026-08-22 04:23:08.606383	1
1714	233	5	25.750	\N	2026-08-22 04:23:08.606383	1
1715	233	6	24.950	\N	2026-08-22 04:23:08.606383	1
1716	233	7	23.100	\N	2026-08-22 04:23:08.606383	1
1717	234	1	28.100	\N	2026-08-22 14:56:01.916476	1
1718	234	2	22.800	\N	2026-08-22 14:56:01.916476	1
1719	234	3	28.100	\N	2026-08-22 14:56:01.916476	1
1720	234	4	26.500	\N	2026-08-22 14:56:01.916476	1
1721	234	5	29.300	\N	2026-08-22 14:56:01.916476	1
1722	234	6	30.050	\N	2026-08-22 14:56:01.916476	1
1723	234	7	29.750	\N	2026-08-22 14:56:01.916476	1
1724	235	1	26.650	\N	2026-08-22 14:57:22.781042	1
1725	235	2	26.750	\N	2026-08-22 14:57:22.781042	1
1726	235	3	30.150	\N	2026-08-22 14:57:22.781042	1
1727	235	4	28.500	\N	2026-08-22 14:57:22.781042	1
1728	235	5	28.950	\N	2026-08-22 14:57:22.781042	1
1729	235	6	27.900	\N	2026-08-22 14:57:22.781042	1
1730	235	7	29.600	\N	2026-08-22 14:57:22.781042	1
1736	237	1	29.300	\N	2026-08-22 14:58:42.513398	1
1737	237	2	26.450	\N	2026-08-22 14:58:42.513398	1
1738	238	1	12.550	\N	2026-08-22 14:59:20.700636	1
1739	238	2	20.700	\N	2026-08-22 14:59:20.700636	1
1740	238	3	24.650	\N	2026-08-22 14:59:20.700636	1
1741	238	4	16.000	\N	2026-08-22 14:59:20.700636	1
1742	239	1	24.250	\N	2026-08-23 07:49:38.66813	1
1743	239	2	21.750	\N	2026-08-23 07:49:38.66813	1
1744	239	3	27.200	\N	2026-08-23 07:49:38.66813	1
1745	239	4	27.450	\N	2026-08-23 07:49:38.66813	1
1746	239	5	25.550	\N	2026-08-23 07:49:38.66813	1
1747	239	6	26.800	\N	2026-08-23 07:49:38.66813	1
1748	239	7	28.000	\N	2026-08-23 07:49:38.66813	1
1749	239	8	26.250	\N	2026-08-23 07:49:38.66813	1
1750	239	9	27.850	\N	2026-08-23 07:49:38.66813	1
1751	240	1	20.500	\N	2026-08-23 07:50:38.364573	1
1752	240	2	25.200	\N	2026-08-23 07:50:38.364573	1
1753	240	3	28.250	\N	2026-08-23 07:50:38.364573	1
1754	240	4	26.750	\N	2026-08-23 07:50:38.364573	1
1755	240	5	26.450	\N	2026-08-23 07:50:38.364573	1
1756	240	6	25.600	\N	2026-08-23 07:50:38.364573	1
1757	240	7	28.450	\N	2026-08-23 07:50:38.364573	1
1758	240	8	26.400	\N	2026-08-23 07:50:38.364573	1
1759	240	9	27.950	\N	2026-08-23 07:50:38.364573	1
1760	241	1	25.350	\N	2026-08-23 07:51:45.445947	1
1761	241	2	24.500	\N	2026-08-23 07:51:45.445947	1
1762	241	3	24.950	\N	2026-08-23 07:51:45.445947	1
1763	241	4	16.300	\N	2026-08-23 07:51:45.445947	1
1764	241	5	29.250	\N	2026-08-23 07:51:45.445947	1
1765	241	6	21.900	\N	2026-08-23 07:51:45.445947	1
1766	236	1	28.850	\N	2026-08-23 07:53:37.334253	1
1767	236	2	28.700	\N	2026-08-23 07:53:37.334253	1
1768	236	3	26.750	\N	2026-08-23 07:53:37.334253	1
1769	236	4	30.300	\N	2026-08-23 07:53:37.334253	1
1770	236	5	40.050	\N	2026-08-23 07:53:37.334253	1
1771	242	1	22.500	\N	2026-08-24 06:02:34.924141	1
1772	242	2	26.550	\N	2026-08-24 06:02:34.924141	1
1773	242	3	21.600	\N	2026-08-24 06:02:34.924141	1
1774	242	4	26.050	\N	2026-08-24 06:02:34.924141	1
1775	242	5	28.200	\N	2026-08-24 06:02:34.924141	1
1776	242	6	26.050	\N	2026-08-24 06:02:34.924141	1
1777	242	7	28.350	\N	2026-08-24 06:02:34.924141	1
1778	242	8	28.050	\N	2026-08-24 06:02:34.924141	1
1779	243	1	26.750	\N	2026-08-24 06:03:31.73487	1
1780	243	2	29.450	\N	2026-08-24 06:03:31.73487	1
1781	243	3	26.600	\N	2026-08-24 06:03:31.73487	1
1782	243	4	27.350	\N	2026-08-24 06:03:31.73487	1
1783	243	5	26.650	\N	2026-08-24 06:03:31.73487	1
1784	243	6	28.250	\N	2026-08-24 06:03:31.73487	1
1785	243	7	27.450	\N	2026-08-24 06:03:31.73487	1
1786	243	8	26.800	\N	2026-08-24 06:03:31.73487	1
1787	244	1	20.700	\N	2026-08-24 06:04:20.260871	1
1788	244	2	24.400	\N	2026-08-24 06:04:20.260871	1
1789	244	3	21.950	\N	2026-08-24 06:04:20.260871	1
1790	244	4	26.550	\N	2026-08-24 06:04:20.260871	1
1791	244	5	19.250	\N	2026-08-24 06:04:20.260871	1
1792	244	6	24.850	\N	2026-08-24 06:04:20.260871	1
1793	245	1	19.000	\N	2026-08-24 06:05:27.315084	1
1794	245	2	26.600	\N	2026-08-24 06:05:27.315084	1
1795	245	3	16.950	\N	2026-08-24 06:05:27.315084	1
1796	245	4	25.500	\N	2026-08-24 06:05:27.315084	1
1797	245	5	29.450	\N	2026-08-24 06:05:27.315084	1
1798	245	6	28.000	\N	2026-08-24 06:05:27.315084	1
1799	245	7	27.500	\N	2026-08-24 06:05:27.315084	1
1800	245	8	26.300	\N	2026-08-24 06:05:27.315084	1
1801	245	9	28.600	\N	2026-08-24 06:05:27.315084	1
1802	246	1	23.200	\N	2026-08-24 06:06:16.540301	1
1803	246	2	27.900	\N	2026-08-24 06:06:16.540301	1
1804	246	3	25.250	\N	2026-08-24 06:06:16.540301	1
1805	246	4	28.000	\N	2026-08-24 06:06:16.540301	1
1806	246	5	26.650	\N	2026-08-24 06:06:16.540301	1
1807	246	6	28.200	\N	2026-08-24 06:06:16.540301	1
1808	246	7	27.300	\N	2026-08-24 06:06:16.540301	1
1809	246	8	27.300	\N	2026-08-24 06:06:16.540301	1
1819	248	1	21.300	\N	2026-08-24 06:12:09.340163	1
1820	248	2	23.850	\N	2026-08-24 06:12:09.340163	1
1821	248	3	31.050	\N	2026-08-24 06:12:09.340163	1
1822	248	4	33.250	\N	2026-08-24 06:12:09.340163	1
1823	248	5	24.250	\N	2026-08-24 06:12:09.340163	1
1824	249	1	27.800	\N	2026-08-25 04:35:15.569093	1
1825	249	2	28.300	\N	2026-08-25 04:35:15.569093	1
1826	249	3	27.800	\N	2026-08-25 04:35:15.569093	1
1827	249	4	26.550	\N	2026-08-25 04:35:15.569093	1
1828	250	1	20.200	\N	2026-08-25 04:37:01.62906	1
1829	250	2	20.250	\N	2026-08-25 04:37:01.62906	1
1830	250	3	14.700	\N	2026-08-25 04:37:01.62906	1
1831	250	4	14.050	\N	2026-08-25 04:37:01.62906	1
1832	250	5	20.000	\N	2026-08-25 04:37:01.62906	1
1833	250	6	21.400	\N	2026-08-25 04:37:01.62906	1
1834	251	1	24.750	\N	2026-08-27 06:00:56.608211	1
1835	251	2	17.950	\N	2026-08-27 06:00:56.608211	1
1836	251	3	14.950	\N	2026-08-27 06:00:56.608211	1
1837	251	4	18.950	\N	2026-08-27 06:00:56.608211	1
1838	251	5	19.150	\N	2026-08-27 06:00:56.608211	1
1839	252	1	22.100	\N	2026-08-28 04:44:06.798769	1
1840	252	2	20.100	\N	2026-08-28 04:44:06.798769	1
1841	253	1	21.400	\N	2026-08-28 04:45:05.693469	1
1842	253	2	22.700	\N	2026-08-28 04:45:05.693469	1
1843	254	1	23.800	\N	2026-08-28 04:45:45.086238	1
1844	254	2	25.250	\N	2026-08-28 04:45:45.086238	1
1845	254	3	17.750	\N	2026-08-28 04:45:45.086238	1
1846	255	1	29.000	\N	2026-08-28 04:46:31.095324	1
1847	255	2	29.500	\N	2026-08-28 04:46:31.095324	1
1848	255	3	27.100	\N	2026-08-28 04:46:31.095324	1
1849	255	4	28.950	\N	2026-08-28 04:46:31.095324	1
1850	256	1	29.250	\N	2026-08-28 04:47:34.924058	1
1851	256	2	28.300	\N	2026-08-28 04:47:34.924058	1
1852	256	3	28.400	\N	2026-08-28 04:47:34.924058	1
1853	256	4	27.200	\N	2026-08-28 04:47:34.924058	1
1854	256	5	27.050	\N	2026-08-28 04:47:34.924058	1
1855	256	6	29.750	\N	2026-08-28 04:47:34.924058	1
1856	256	7	29.450	\N	2026-08-28 04:47:34.924058	1
1857	256	8	26.150	\N	2026-08-28 04:47:34.924058	1
1858	257	1	91.650	\N	2026-08-28 08:00:46.506389	1
1859	258	1	29.300	\N	2026-08-29 04:53:59.057269	1
1860	258	2	29.850	\N	2026-08-29 04:53:59.057269	1
1861	258	3	20.500	\N	2026-08-29 04:53:59.057269	1
1862	259	1	30.450	\N	2026-08-29 04:54:57.260201	1
1863	259	2	31.550	\N	2026-08-29 04:54:57.260201	1
1864	259	3	20.250	\N	2026-08-29 04:54:57.260201	1
1865	259	4	30.600	\N	2026-08-29 04:54:57.260201	1
1866	259	5	28.350	\N	2026-08-29 04:54:57.260201	1
1867	259	6	29.700	\N	2026-08-29 04:54:57.260201	1
1868	259	7	23.750	\N	2026-08-29 04:54:57.260201	1
1869	260	1	30.300	\N	2026-08-29 04:55:58.871861	1
1870	260	2	28.100	\N	2026-08-29 04:55:58.871861	1
1871	260	3	28.050	\N	2026-08-29 04:55:58.871861	1
1872	260	4	26.600	\N	2026-08-29 04:55:58.871861	1
1873	260	5	29.250	\N	2026-08-29 04:55:58.871861	1
1874	260	6	28.000	\N	2026-08-29 04:55:58.871861	1
1875	260	7	28.000	\N	2026-08-29 04:55:58.871861	1
1876	260	8	29.250	\N	2026-08-29 04:55:58.871861	1
1877	260	9	31.950	\N	2026-08-29 04:55:58.871861	1
1878	261	1	27.650	\N	2026-08-29 04:56:50.689512	1
1879	261	2	28.000	\N	2026-08-29 04:56:50.689512	1
1880	261	3	28.450	\N	2026-08-29 04:56:50.689512	1
1881	261	4	27.300	\N	2026-08-29 04:56:50.689512	1
1882	261	5	28.750	\N	2026-08-29 04:56:50.689512	1
1883	261	6	28.600	\N	2026-08-29 04:56:50.689512	1
1884	261	7	27.000	\N	2026-08-29 04:56:50.689512	1
1885	261	8	28.800	\N	2026-08-29 04:56:50.689512	1
1886	261	9	28.050	\N	2026-08-29 04:56:50.689512	1
\.


--
-- Data for Name: daily_production_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_production_header (id, production_date, machine_id, employee_id, party_id, shift, status, remarks, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at, tenant_id) FROM stdin;
55	2026-08-04	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-05 05:21:33.592011	Iftikhar	2026-08-06 10:19:47.34	t	147	2026-08-06 10:29:27.695	1
59	2026-08-04	23	2	13	Night	submitted	\N	Iftikhar	2026-08-05 05:26:18.500287	\N	2026-08-05 05:26:18.500287	t	147	2026-08-06 10:29:27.695	1
54	2026-08-04	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-05 05:20:10.782671	\N	2026-08-05 05:20:10.782671	t	148	2026-08-06 10:31:01.798	1
53	2026-08-04	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:19:28.381793	\N	2026-08-05 05:19:28.381793	t	150	2026-08-06 13:26:01.721	1
56	2026-08-04	25	9	14	Night	submitted	\N	Iftikhar	2026-08-05 05:22:54.381768	\N	2026-08-05 05:22:54.381768	t	150	2026-08-06 13:26:01.721	1
57	2026-08-04	14	9	14	Night	submitted	\N	Iftikhar	2026-08-05 05:23:56.914664	\N	2026-08-05 05:23:56.914664	t	150	2026-08-06 13:26:01.721	1
7	2026-08-01	18	7	17	Morning	submitted	\N	Iftikhar	2026-08-04 09:20:23.329666	\N	2026-08-04 09:20:23.329666	t	135	2026-08-04 13:14:03.613	1
15	2026-08-01	18	2	17	Night	submitted	\N	Iftikhar	2026-08-04 09:40:48.902839	\N	2026-08-04 09:40:48.902839	t	135	2026-08-04 13:14:03.613	1
58	2026-08-04	15	2	14	Night	submitted	\N	Iftikhar	2026-08-05 05:25:07.609832	\N	2026-08-05 05:25:07.609832	t	150	2026-08-06 13:26:01.721	1
60	2026-08-05	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:12:09.379561	\N	2026-08-06 05:12:09.379561	t	\N	2026-08-06 10:06:16.658	1
61	2026-08-05	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:13:41.179759	\N	2026-08-06 05:13:41.179759	t	\N	2026-08-06 10:06:16.658	1
62	2026-08-05	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:14:54.170255	\N	2026-08-06 05:14:54.170255	t	\N	2026-08-06 10:06:16.658	1
66	2026-08-05	14	9	14	Night	submitted	\N	Iftikhar	2026-08-06 05:21:03.119254	\N	2026-08-06 05:21:03.119254	t	\N	2026-08-06 10:06:16.658	1
20	2026-08-01	24	3	13	Night	submitted	\N	Iftikhar	2026-08-04 09:55:40.418218	abc	2026-08-07 12:32:39.043	t	139	2026-08-04 13:59:37.313	1
130	2026-08-10	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-11 05:36:52.435471	\N	2026-08-11 05:36:52.435471	t	197	2026-08-11 08:02:34.807	1
126	2026-08-10	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:24:27.73266	\N	2026-08-11 05:24:27.73266	t	198	2026-08-11 08:05:44.312	1
98	2026-07-31	25	18	13	Morning	submitted	\N	Hsn	2026-08-08 06:51:30.145466	\N	2026-08-08 06:51:30.145466	t	201	2026-08-12 09:30:15.429	1
104	2026-07-31	25	18	14	Morning	submitted	\N	Hsn	2026-08-08 07:31:28.848027	\N	2026-08-08 07:31:28.848027	t	202	2026-08-12 09:35:50.523	1
24	2026-08-02	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-04 10:06:51.146146	\N	2026-08-04 10:06:51.146146	t	136	2026-08-04 13:17:25.823	1
102	2026-07-31	25	18	15	Morning	submitted	\N	Hsn	2026-08-08 07:07:33.221562	\N	2026-08-08 07:07:33.221562	t	206	2026-08-12 10:05:23.747	1
4	2026-08-01	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:10:42.87511	\N	2026-08-04 09:10:42.87511	t	132	2026-08-04 12:35:23.619	1
6	2026-08-01	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:18:31.354253	\N	2026-08-04 09:18:31.354253	t	132	2026-08-04 12:35:23.619	1
5	2026-08-01	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:16:42.696457	Iftikhar	2026-08-04 09:23:18.322	t	132	2026-08-04 12:35:23.619	1
12	2026-08-01	25	3	14	Night	submitted	\N	Iftikhar	2026-08-04 09:34:40.40951	\N	2026-08-04 09:34:40.40951	t	132	2026-08-04 12:35:23.619	1
13	2026-08-01	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 09:36:49.21394	\N	2026-08-04 09:36:49.21394	t	132	2026-08-04 12:35:23.619	1
14	2026-08-01	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 09:37:42.188473	\N	2026-08-04 09:37:42.188473	t	132	2026-08-04 12:35:23.619	1
21	2026-08-02	25	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:01:26.358251	\N	2026-08-04 10:01:26.358251	t	133	2026-08-04 12:43:09.691	1
22	2026-08-02	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:02:51.515396	\N	2026-08-04 10:02:51.515396	t	133	2026-08-04 12:43:09.691	1
23	2026-08-02	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:03:57.20679	Iftikhar	2026-08-04 10:05:41.441	t	133	2026-08-04 12:43:09.691	1
29	2026-08-02	25	9	14	Night	submitted	\N	Iftikhar	2026-08-04 10:44:10.948865	\N	2026-08-04 10:44:10.948865	t	133	2026-08-04 12:43:09.691	1
31	2026-08-02	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:02:23.167923	\N	2026-08-04 11:02:23.167923	t	133	2026-08-04 12:43:09.691	1
32	2026-08-02	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 11:03:01.847261	\N	2026-08-04 11:03:01.847261	t	133	2026-08-04 12:43:09.691	1
38	2026-08-03	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:10:01.18467	\N	2026-08-04 11:10:01.18467	t	134	2026-08-04 13:06:18.972	1
39	2026-08-03	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:14:57.548808	\N	2026-08-04 11:14:57.548808	t	134	2026-08-04 13:06:18.972	1
40	2026-08-03	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:15:49.435534	\N	2026-08-04 11:15:49.435534	t	134	2026-08-04 13:06:18.972	1
45	2026-08-03	25	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:21:22.562363	\N	2026-08-04 11:21:22.562363	t	134	2026-08-04 13:06:18.972	1
46	2026-08-03	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:22:21.680401	\N	2026-08-04 11:22:21.680401	t	134	2026-08-04 13:06:18.972	1
47	2026-08-03	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 11:23:27.891391	\N	2026-08-04 11:23:27.891391	t	134	2026-08-04 13:06:18.972	1
25	2026-08-02	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 10:07:59.206754	\N	2026-08-04 10:07:59.206754	t	136	2026-08-04 13:17:25.823	1
33	2026-08-02	18	2	16	Night	submitted	\N	Iftikhar	2026-08-04 11:04:36.849782	\N	2026-08-04 11:04:36.849782	t	136	2026-08-04 13:17:25.823	1
34	2026-08-02	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 11:05:46.793537	\N	2026-08-04 11:05:46.793537	t	136	2026-08-04 13:17:25.823	1
16	2026-08-01	18	2	20	Night	submitted	\N	Iftikhar	2026-08-04 09:41:28.654011	Iftikhar	2026-08-04 13:45:14.172	t	137	2026-08-04 13:53:44.511	1
8	2026-08-01	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 09:25:40.653893	\N	2026-08-04 09:25:40.653893	t	138	2026-08-04 13:57:14.007	1
17	2026-08-01	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 09:45:30.288701	\N	2026-08-04 09:45:30.288701	t	138	2026-08-04 13:57:14.007	1
9	2026-08-01	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 09:27:15.003235	\N	2026-08-04 09:27:15.003235	t	139	2026-08-04 13:59:37.313	1
10	2026-08-01	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 09:28:57.85111	\N	2026-08-04 09:28:57.85111	t	139	2026-08-04 13:59:37.313	1
18	2026-08-01	22	9	13	Night	submitted	\N	Iftikhar	2026-08-04 09:46:52.771207	\N	2026-08-04 09:46:52.771207	t	139	2026-08-04 13:59:37.313	1
19	2026-08-01	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 09:54:11.999346	\N	2026-08-04 09:54:11.999346	t	139	2026-08-04 13:59:37.313	1
11	2026-08-01	24	1	15	Morning	submitted	\N	Iftikhar	2026-08-04 09:30:40.700423	\N	2026-08-04 09:30:40.700423	t	140	2026-08-04 14:01:03.54	1
26	2026-08-02	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 10:08:59.403701	\N	2026-08-04 10:08:59.403701	t	141	2026-08-04 14:03:06.842	1
27	2026-08-02	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 10:10:14.184358	\N	2026-08-04 10:10:14.184358	t	141	2026-08-04 14:03:06.842	1
35	2026-08-02	22	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:06:46.274667	\N	2026-08-04 11:06:46.274667	t	141	2026-08-04 14:03:06.842	1
36	2026-08-02	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:07:56.979945	\N	2026-08-04 11:07:56.979945	t	141	2026-08-04 14:03:06.842	1
28	2026-08-02	24	1	15	Morning	submitted	\N	Iftikhar	2026-08-04 10:11:18.644384	\N	2026-08-04 10:11:18.644384	t	142	2026-08-04 14:05:21.393	1
37	2026-08-02	24	9	15	Night	submitted	\N	Iftikhar	2026-08-04 11:08:47.644403	\N	2026-08-04 11:08:47.644403	t	142	2026-08-04 14:05:21.393	1
41	2026-08-03	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-04 11:16:54.358067	\N	2026-08-04 11:16:54.358067	t	143	2026-08-04 14:07:52.264	1
42	2026-08-03	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 11:18:01.178238	\N	2026-08-04 11:18:01.178238	t	143	2026-08-04 14:07:52.264	1
48	2026-08-03	18	2	16	Night	submitted	\N	Iftikhar	2026-08-04 11:24:21.364634	\N	2026-08-04 11:24:21.364634	t	143	2026-08-04 14:07:52.264	1
49	2026-08-03	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 11:25:27.95248	\N	2026-08-04 11:25:27.95248	t	143	2026-08-04 14:07:52.264	1
43	2026-08-03	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 11:18:37.003406	\N	2026-08-04 11:18:37.003406	t	144	2026-08-04 14:10:05.393	1
44	2026-08-03	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 11:19:37.030411	\N	2026-08-04 11:19:37.030411	t	144	2026-08-04 14:10:05.393	1
50	2026-08-03	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:26:53.291837	\N	2026-08-04 11:26:53.291837	t	144	2026-08-04 14:10:05.393	1
64	2026-08-05	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-06 05:18:20.391739	\N	2026-08-06 05:18:20.391739	t	146	2026-08-06 10:08:54.843	1
68	2026-08-05	23	2	13	Night	submitted	\N	Iftikhar	2026-08-06 05:24:47.564861	\N	2026-08-06 05:24:47.564861	t	146	2026-08-06 10:08:54.843	1
69	2026-08-05	24	9	13	Night	submitted	\N	Iftikhar	2026-08-06 05:25:38.115455	\N	2026-08-06 05:25:38.115455	t	146	2026-08-06 10:08:54.843	1
63	2026-08-05	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-06 05:16:12.272644	Iftikhar	2026-08-06 09:50:06.528	t	146	2026-08-06 10:08:54.843	1
52	2026-08-04	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:18:12.192286	abc	2026-08-05 14:53:59.24	t	150	2026-08-06 13:26:01.721	1
51	2026-08-04	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:15:40.749114	abc	2026-08-05 23:02:26.29	t	150	2026-08-06 13:26:01.721	1
205	2026-08-19	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-20 04:23:18.573807	\N	2026-08-20 04:23:18.573807	t	236	2026-08-20 08:25:26.459	1
209	2026-08-19	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-20 04:29:27.538971	\N	2026-08-20 04:29:27.538971	t	237	2026-08-20 08:27:05.869	1
208	2026-08-19	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-20 04:28:21.745778	\N	2026-08-20 04:28:21.745778	t	238	2026-08-20 08:30:31.123	1
100	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 07:01:29.883679	\N	2026-08-08 07:01:29.883679	t	193	2026-08-11 06:59:11.495	1
99	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 06:58:00.950157	\N	2026-08-08 06:58:00.950157	t	193	2026-08-11 06:59:11.495	1
101	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 07:05:24.210104	\N	2026-08-08 07:05:24.210104	t	193	2026-08-11 06:59:11.495	1
129	2026-08-10	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-11 05:36:02.008856	\N	2026-08-11 05:36:02.008856	t	197	2026-08-11 08:02:34.807	1
70	2026-08-06	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:23:01.634685	\N	2026-08-07 05:23:01.634685	t	153	2026-08-07 06:27:57.242	1
71	2026-08-06	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:25:39.804931	\N	2026-08-07 05:25:39.804931	t	153	2026-08-07 06:27:57.242	1
72	2026-08-06	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:26:45.829478	\N	2026-08-07 05:26:45.829478	t	153	2026-08-07 06:27:57.242	1
75	2026-08-06	25	9	14	Night	submitted	\N	Iftikhar	2026-08-07 05:29:56.839702	\N	2026-08-07 05:29:56.839702	t	153	2026-08-07 06:27:57.242	1
76	2026-08-06	14	2	14	Night	submitted	\N	Iftikhar	2026-08-07 05:31:51.762381	\N	2026-08-07 05:31:51.762381	t	153	2026-08-07 06:27:57.242	1
77	2026-08-06	15	2	14	Night	submitted	\N	Iftikhar	2026-08-07 05:33:08.312801	\N	2026-08-07 05:33:08.312801	t	153	2026-08-07 06:27:57.242	1
73	2026-08-06	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-07 05:27:39.547294	\N	2026-08-07 05:27:39.547294	t	154	2026-08-07 06:30:21.369	1
74	2026-08-06	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-07 05:28:49.295736	\N	2026-08-07 05:28:49.295736	t	154	2026-08-07 06:30:21.369	1
78	2026-08-06	23	2	13	Night	submitted	\N	Iftikhar	2026-08-07 05:34:13.840169	\N	2026-08-07 05:34:13.840169	t	154	2026-08-07 06:30:21.369	1
79	2026-08-06	24	9	13	Night	submitted	\N	Iftikhar	2026-08-07 05:35:10.784899	\N	2026-08-07 05:35:10.784899	t	154	2026-08-07 06:30:21.369	1
134	2026-08-10	22	2	13	Night	submitted	\N	Iftikhar	2026-08-11 05:42:02.246542	\N	2026-08-11 05:42:02.246542	t	197	2026-08-11 08:02:34.807	1
128	2026-08-10	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:31:19.677755	\N	2026-08-11 05:31:19.677755	t	198	2026-08-11 08:05:44.312	1
127	2026-08-10	14	1	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:26:47.336666	\N	2026-08-11 05:26:47.336666	t	198	2026-08-11 08:05:44.312	1
131	2026-08-10	25	9	14	Night	submitted	\N	Iftikhar	2026-08-11 05:38:13.686446	\N	2026-08-11 05:38:13.686446	t	198	2026-08-11 08:05:44.312	1
132	2026-08-10	14	9	14	Night	submitted	\N	Iftikhar	2026-08-11 05:39:17.78189	\N	2026-08-11 05:39:17.78189	t	198	2026-08-11 08:05:44.312	1
133	2026-08-10	15	2	14	Night	submitted	\N	Iftikhar	2026-08-11 05:40:14.148997	\N	2026-08-11 05:40:14.148997	t	198	2026-08-11 08:05:44.312	1
212	2026-08-19	15	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-08-20 04:37:16.81992	\N	2026-08-20 04:37:16.81992	t	238	2026-08-20 08:30:31.123	1
67	2026-08-05	15	2	14	Night	submitted	\N	Iftikhar	2026-08-06 05:23:48.398276	\N	2026-08-06 05:23:48.398276	t	\N	2026-08-06 10:06:16.658	1
65	2026-08-05	25	9	14	Night	submitted	\N	Iftikhar	2026-08-06 05:19:32.340692	Iftikhar	2026-08-06 05:26:52.716	t	\N	2026-08-06 10:06:16.658	1
135	2026-08-11	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-12 05:14:43.470644	\N	2026-08-12 05:14:43.470644	t	203	2026-08-12 09:41:16.297	1
138	2026-08-11	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-12 05:20:38.332118	\N	2026-08-12 05:20:38.332118	t	204	2026-08-12 09:58:09.956	1
139	2026-08-11	19	7	16	Morning	submitted	\N	Iftikhar	2026-08-12 05:21:17.214757	\N	2026-08-12 05:21:17.214757	t	204	2026-08-12 09:58:09.956	1
140	2026-08-11	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-12 05:22:39.016676	\N	2026-08-12 05:22:39.016676	t	204	2026-08-12 09:58:09.956	1
145	2026-08-11	18	2	16	Night	submitted	\N	Iftikhar	2026-08-12 05:28:46.41942	\N	2026-08-12 05:28:46.41942	t	204	2026-08-12 09:58:09.956	1
146	2026-08-11	19	2	16	Night	submitted	\N	Iftikhar	2026-08-12 05:29:39.113399	\N	2026-08-12 05:29:39.113399	t	204	2026-08-12 09:58:09.956	1
141	2026-08-11	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-12 05:23:29.048664	\N	2026-08-12 05:23:29.048664	t	205	2026-08-12 10:00:37.816	1
103	2026-07-31	25	18	17	Morning	submitted	\N	Hsn	2026-08-08 07:12:47.109305	\N	2026-08-08 07:12:47.109305	t	207	2026-08-12 10:08:10.744	1
91	2026-08-07	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-08 05:37:33.883171	\N	2026-08-08 05:37:33.883171	t	166	2026-08-08 06:23:16.557	1
92	2026-08-07	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-08 05:39:02.666522	\N	2026-08-08 05:39:02.666522	t	166	2026-08-08 06:23:16.557	1
96	2026-08-07	23	2	13	Night	submitted	\N	Iftikhar	2026-08-08 05:44:27.618161	\N	2026-08-08 05:44:27.618161	t	166	2026-08-08 06:23:16.557	1
97	2026-08-07	24	9	13	Night	submitted	\N	Iftikhar	2026-08-08 05:45:15.246474	\N	2026-08-08 05:45:15.246474	t	166	2026-08-08 06:23:16.557	1
88	2026-08-07	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:33:43.300283	\N	2026-08-08 05:33:43.300283	t	167	2026-08-08 06:25:49.267	1
89	2026-08-07	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:34:49.051626	\N	2026-08-08 05:34:49.051626	t	167	2026-08-08 06:25:49.267	1
90	2026-08-07	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:35:45.485175	\N	2026-08-08 05:35:45.485175	t	167	2026-08-08 06:25:49.267	1
93	2026-08-07	25	9	14	Night	submitted	\N	Iftikhar	2026-08-08 05:41:02.110074	\N	2026-08-08 05:41:02.110074	t	167	2026-08-08 06:25:49.267	1
94	2026-08-07	14	9	14	Night	submitted	\N	Iftikhar	2026-08-08 05:42:10.302604	\N	2026-08-08 05:42:10.302604	t	167	2026-08-08 06:25:49.267	1
95	2026-08-07	15	2	14	Night	submitted	\N	Iftikhar	2026-08-08 05:43:24.316785	\N	2026-08-08 05:43:24.316785	t	167	2026-08-08 06:25:49.267	1
108	2026-08-08	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-09 07:52:30.892115	\N	2026-08-09 07:52:30.892115	t	186	2026-08-10 09:23:21.156	1
109	2026-08-08	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-09 07:53:28.839697	\N	2026-08-09 07:53:28.839697	t	186	2026-08-10 09:23:21.156	1
113	2026-08-08	22	2	13	Night	submitted	\N	Iftikhar	2026-08-09 07:59:33.485241	\N	2026-08-09 07:59:33.485241	t	186	2026-08-10 09:23:21.156	1
115	2026-08-08	24	9	13	Night	submitted	\N	Iftikhar	2026-08-09 08:03:42.711767	\N	2026-08-09 08:03:42.711767	t	186	2026-08-10 09:23:21.156	1
114	2026-08-08	23	2	13	Night	submitted	\N	Iftikhar	2026-08-09 08:02:40.567269	Iftikhar	2026-08-09 08:05:59.595	t	186	2026-08-10 09:23:21.156	1
116	2026-08-09	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:23:01.976288	\N	2026-08-10 05:23:01.976288	t	187	2026-08-10 09:25:50.817	1
117	2026-08-09	14	1	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:24:06.205199	\N	2026-08-10 05:24:06.205199	t	187	2026-08-10 09:25:50.817	1
118	2026-08-09	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:25:09.40753	\N	2026-08-10 05:25:09.40753	t	187	2026-08-10 09:25:50.817	1
122	2026-08-09	14	9	14	Night	submitted	\N	Iftikhar	2026-08-10 05:28:46.604898	\N	2026-08-10 05:28:46.604898	t	187	2026-08-10 09:25:50.817	1
123	2026-08-09	15	9	14	Night	submitted	\N	Iftikhar	2026-08-10 05:30:46.537843	\N	2026-08-10 05:30:46.537843	t	187	2026-08-10 09:25:50.817	1
105	2026-08-08	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:48:31.9882	\N	2026-08-09 07:48:31.9882	t	188	2026-08-10 09:27:37.036	1
106	2026-08-08	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:50:05.863588	\N	2026-08-09 07:50:05.863588	t	188	2026-08-10 09:27:37.036	1
107	2026-08-08	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:51:04.678261	\N	2026-08-09 07:51:04.678261	t	188	2026-08-10 09:27:37.036	1
111	2026-08-08	14	9	14	Night	submitted	\N	Iftikhar	2026-08-09 07:56:12.533537	\N	2026-08-09 07:56:12.533537	t	188	2026-08-10 09:27:37.036	1
112	2026-08-08	15	2	14	Night	submitted	\N	Iftikhar	2026-08-09 07:58:42.067577	\N	2026-08-09 07:58:42.067577	t	188	2026-08-10 09:27:37.036	1
110	2026-08-08	25	9	14	Night	submitted	\N	Iftikhar	2026-08-09 07:54:53.092125	Iftikhar	2026-08-09 08:41:15.456	t	188	2026-08-10 09:27:37.036	1
119	2026-08-09	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:26:09.923348	\N	2026-08-10 05:26:09.923348	t	189	2026-08-10 10:26:19.752	1
120	2026-08-09	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:27:03.589931	\N	2026-08-10 05:27:03.589931	t	189	2026-08-10 10:26:19.752	1
121	2026-08-09	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:28:03.324527	\N	2026-08-10 05:28:03.324527	t	189	2026-08-10 10:26:19.752	1
125	2026-08-09	24	9	13	Night	submitted	\N	Iftikhar	2026-08-10 05:33:23.641765	\N	2026-08-10 05:33:23.641765	t	189	2026-08-10 10:26:19.752	1
124	2026-08-09	22	9	13	Night	submitted	\N	Iftikhar	2026-08-10 05:32:19.376356	Iftikhar	2026-08-10 05:34:55.987	t	189	2026-08-10 10:26:19.752	1
199	2026-08-18	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:21:41.522123	\N	2026-08-19 04:21:41.522123	t	231	2026-08-19 07:22:53.019	1
203	2026-08-18	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:25:30.946876	\N	2026-08-19 04:25:30.946876	t	231	2026-08-19 07:22:53.019	1
197	2026-08-18	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:19:54.187297	\N	2026-08-19 04:19:54.187297	t	232	2026-08-19 07:25:15.902	1
136	2026-08-11	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-12 05:16:36.540058	\N	2026-08-12 05:16:36.540058	t	203	2026-08-12 09:41:16.297	1
137	2026-08-11	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-12 05:19:50.744193	\N	2026-08-12 05:19:50.744193	t	203	2026-08-12 09:41:16.297	1
143	2026-08-11	14	9	14	Night	submitted	\N	Iftikhar	2026-08-12 05:25:55.225812	\N	2026-08-12 05:25:55.225812	t	203	2026-08-12 09:41:16.297	1
144	2026-08-11	15	2	14	Night	submitted	\N	Iftikhar	2026-08-12 05:28:07.246176	\N	2026-08-12 05:28:07.246176	t	203	2026-08-12 09:41:16.297	1
142	2026-08-11	25	9	14	Night	submitted	\N	Iftikhar	2026-08-12 05:24:37.373175	Iftikhar	2026-08-12 07:30:10.021	t	203	2026-08-12 09:41:16.297	1
147	2026-08-11	21	9	16	Night	submitted	\N	Iftikhar	2026-08-12 05:30:31.757677	\N	2026-08-12 05:30:31.757677	t	204	2026-08-12 09:58:09.956	1
210	2026-08-19	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-20 04:35:30.244206	\N	2026-08-20 04:35:30.244206	t	236	2026-08-20 08:25:26.459	1
214	2026-08-19	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-20 04:38:54.492376	\N	2026-08-20 04:38:54.492376	t	237	2026-08-20 08:27:05.869	1
206	2026-08-19	15	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-20 04:25:32.833822	\N	2026-08-20 04:25:32.833822	t	238	2026-08-20 08:30:31.123	1
148	2026-08-12	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:43:22.223796	\N	2026-08-13 04:43:22.223796	t	208	2026-08-13 08:11:22.65	1
149	2026-08-12	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:44:35.224753	\N	2026-08-13 04:44:35.224753	t	208	2026-08-13 08:11:22.65	1
150	2026-08-12	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-13 04:45:34.228718	\N	2026-08-13 04:45:34.228718	t	208	2026-08-13 08:11:22.65	1
153	2026-08-12	25	9	14	Night	submitted	\N	Iftikhar	2026-08-13 04:48:05.77479	\N	2026-08-13 04:48:05.77479	t	208	2026-08-13 08:11:22.65	1
154	2026-08-12	14	9	14	Night	submitted	\N	Iftikhar	2026-08-13 04:49:14.216822	\N	2026-08-13 04:49:14.216822	t	208	2026-08-13 08:11:22.65	1
155	2026-08-12	15	2	14	Night	submitted	\N	Iftikhar	2026-08-13 04:50:17.260845	\N	2026-08-13 04:50:17.260845	t	208	2026-08-13 08:11:22.65	1
151	2026-08-12	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-13 04:46:21.136222	\N	2026-08-13 04:46:21.136222	t	210	2026-08-15 10:32:09.085	1
156	2026-08-12	19	2	16	Night	submitted	\N	Iftikhar	2026-08-13 04:51:23.964216	\N	2026-08-13 04:51:23.964216	t	211	2026-08-15 10:46:23.243	1
152	2026-08-12	19	7	16	Morning	submitted	\N	Iftikhar	2026-08-13 04:46:55.696827	Iftikhar Ahmed	2026-08-15 05:54:52.428	t	211	2026-08-15 10:46:23.243	1
157	2026-08-13	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 05:57:47.128772	\N	2026-08-15 05:57:47.128772	t	212	2026-08-15 10:54:39.533	1
158	2026-08-13	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:02:43.362655	\N	2026-08-15 06:02:43.362655	t	212	2026-08-15 10:54:39.533	1
160	2026-08-13	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:04:23.470122	\N	2026-08-15 06:04:23.470122	t	212	2026-08-15 10:54:39.533	1
162	2026-08-13	20	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:07:04.277791	\N	2026-08-15 06:07:04.277791	t	212	2026-08-15 10:54:39.533	1
163	2026-08-13	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:08:05.670254	\N	2026-08-15 06:08:05.670254	t	212	2026-08-15 10:54:39.533	1
164	2026-08-13	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:08:57.221169	\N	2026-08-15 06:08:57.221169	t	212	2026-08-15 10:54:39.533	1
166	2026-08-13	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:11:02.348358	\N	2026-08-15 06:11:02.348358	t	212	2026-08-15 10:54:39.533	1
161	2026-08-13	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:06:26.1927	\N	2026-08-15 06:06:26.1927	t	213	2026-08-15 10:55:28.633	1
167	2026-08-13	19	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:12:14.852552	\N	2026-08-15 06:12:14.852552	t	213	2026-08-15 10:55:28.633	1
159	2026-08-13	15	8	14	Morning	submitted	\N	Iftikhar Ahmed	2026-08-15 06:03:48.665526	\N	2026-08-15 06:03:48.665526	t	214	2026-08-15 10:56:48.246	1
165	2026-08-13	15	2	14	Night	submitted	\N	Iftikhar Ahmed	2026-08-15 06:09:52.093661	\N	2026-08-15 06:09:52.093661	t	214	2026-08-15 10:56:48.246	1
168	2026-08-15	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:15:31.554374	\N	2026-08-16 07:15:31.554374	t	226	2026-08-17 13:05:21.35	1
169	2026-08-15	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:16:46.800647	\N	2026-08-16 07:16:46.800647	t	226	2026-08-17 13:05:21.35	1
170	2026-08-15	15	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:17:47.960176	\N	2026-08-16 07:17:47.960176	t	226	2026-08-17 13:05:21.35	1
171	2026-08-15	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:18:54.385539	\N	2026-08-16 07:18:54.385539	t	226	2026-08-17 13:05:21.35	1
172	2026-08-15	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-16 07:19:35.018273	\N	2026-08-16 07:19:35.018273	t	226	2026-08-17 13:05:21.35	1
174	2026-08-15	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:23:35.942302	\N	2026-08-16 07:23:35.942302	t	226	2026-08-17 13:05:21.35	1
175	2026-08-15	15	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:24:50.375929	\N	2026-08-16 07:24:50.375929	t	226	2026-08-17 13:05:21.35	1
176	2026-08-15	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:25:54.684036	\N	2026-08-16 07:25:54.684036	t	226	2026-08-17 13:05:21.35	1
177	2026-08-15	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:27:02.334141	\N	2026-08-16 07:27:02.334141	t	226	2026-08-17 13:05:21.35	1
173	2026-08-15	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-16 07:20:49.866285	Tahir Hassan	2026-08-17 12:59:49.125	t	226	2026-08-17 13:05:21.35	1
178	2026-08-16	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:21:35.499855	\N	2026-08-17 05:21:35.499855	t	227	2026-08-17 13:06:45.171	1
179	2026-08-16	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:22:36.693698	\N	2026-08-17 05:22:36.693698	t	227	2026-08-17 13:06:45.171	1
180	2026-08-16	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:23:30.453518	\N	2026-08-17 05:23:30.453518	t	227	2026-08-17 13:06:45.171	1
181	2026-08-16	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-17 05:24:23.26763	\N	2026-08-17 05:24:23.26763	t	227	2026-08-17 13:06:45.171	1
182	2026-08-16	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:25:28.201228	\N	2026-08-17 05:25:28.201228	t	227	2026-08-17 13:06:45.171	1
183	2026-08-16	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:26:31.576617	\N	2026-08-17 05:26:31.576617	t	227	2026-08-17 13:06:45.171	1
184	2026-08-16	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:27:33.906173	\N	2026-08-17 05:27:33.906173	t	227	2026-08-17 13:06:45.171	1
185	2026-08-16	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-17 05:28:25.149654	\N	2026-08-17 05:28:25.149654	t	227	2026-08-17 13:06:45.171	1
186	2026-08-17	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:52:31.321758	\N	2026-08-18 04:52:31.321758	t	228	2026-08-19 07:06:41.512	1
187	2026-08-17	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:53:36.119909	\N	2026-08-18 04:53:36.119909	t	228	2026-08-19 07:06:41.512	1
188	2026-08-17	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:54:41.341051	\N	2026-08-18 04:54:41.341051	t	228	2026-08-19 07:06:41.512	1
190	2026-08-17	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 04:56:56.733562	\N	2026-08-18 04:56:56.733562	t	228	2026-08-19 07:06:41.512	1
189	2026-08-17	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-18 04:55:37.622849	\N	2026-08-18 04:55:37.622849	t	229	2026-08-19 07:14:29.648	1
193	2026-08-17	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 05:00:05.173048	\N	2026-08-18 05:00:05.173048	t	229	2026-08-19 07:14:29.648	1
194	2026-08-18	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:14:15.119295	\N	2026-08-19 04:14:15.119295	t	230	2026-08-19 07:21:34.191	1
195	2026-08-18	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:18:39.081607	\N	2026-08-19 04:18:39.081607	t	230	2026-08-19 07:21:34.191	1
196	2026-08-18	15	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:19:23.905054	\N	2026-08-19 04:19:23.905054	t	230	2026-08-19 07:21:34.191	1
198	2026-08-18	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-19 04:20:43.446799	\N	2026-08-19 04:20:43.446799	t	230	2026-08-19 07:21:34.191	1
200	2026-08-18	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:22:41.562026	\N	2026-08-19 04:22:41.562026	t	230	2026-08-19 07:21:34.191	1
191	2026-08-17	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 04:58:03.260133	\N	2026-08-18 04:58:03.260133	t	228	2026-08-19 07:06:41.512	1
192	2026-08-17	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-18 04:59:14.986452	\N	2026-08-18 04:59:14.986452	t	228	2026-08-19 07:06:41.512	1
201	2026-08-18	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:23:38.595844	\N	2026-08-19 04:23:38.595844	t	230	2026-08-19 07:21:34.191	1
202	2026-08-18	18	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-19 04:24:34.972893	\N	2026-08-19 04:24:34.972893	t	230	2026-08-19 07:21:34.191	1
204	2026-08-19	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-20 04:22:07.852447	\N	2026-08-20 04:22:07.852447	t	236	2026-08-20 08:25:26.459	1
211	2026-08-19	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-20 04:36:22.480788	\N	2026-08-20 04:36:22.480788	t	236	2026-08-20 08:25:26.459	1
207	2026-08-19	18	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-20 04:27:49.104865	\N	2026-08-20 04:27:49.104865	t	236	2026-08-20 08:25:26.459	1
213	2026-08-19	18	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-08-20 04:38:05.935748	\N	2026-08-20 04:38:05.935748	t	238	2026-08-20 08:30:31.123	1
215	2026-08-20	25	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 04:33:25.994244	\N	2026-08-21 04:33:25.994244	t	242	2026-08-21 06:55:05.622	1
216	2026-08-20	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 04:34:26.886079	\N	2026-08-21 04:34:26.886079	t	242	2026-08-21 06:55:05.622	1
220	2026-08-20	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-21 04:39:16.945034	\N	2026-08-21 04:39:16.945034	t	242	2026-08-21 06:55:05.622	1
221	2026-08-20	14	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-21 04:40:09.949218	\N	2026-08-21 04:40:09.949218	t	242	2026-08-21 06:55:05.622	1
219	2026-08-20	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 04:37:10.064042	\N	2026-08-21 04:37:10.064042	t	243	2026-08-21 06:56:27.886	1
224	2026-08-20	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-21 04:43:39.151219	\N	2026-08-21 04:43:39.151219	t	243	2026-08-21 06:56:27.886	1
217	2026-08-20	15	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 04:35:27.404379	\N	2026-08-21 04:35:27.404379	t	244	2026-08-21 07:02:02.671	1
218	2026-08-20	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 04:36:12.468441	\N	2026-08-21 04:36:12.468441	t	244	2026-08-21 07:02:02.671	1
222	2026-08-20	15	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-08-21 04:41:30.403069	\N	2026-08-21 04:41:30.403069	t	244	2026-08-21 07:02:02.671	1
223	2026-08-20	18	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-08-21 04:42:25.449944	\N	2026-08-21 04:42:25.449944	t	244	2026-08-21 07:02:02.671	1
225	2026-08-21	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 15:16:11.556372	\N	2026-08-21 15:16:11.556372	t	250	2026-08-22 06:41:34.988	1
226	2026-08-21	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 15:17:06.048513	\N	2026-08-21 15:17:06.048513	t	250	2026-08-22 06:41:34.988	1
230	2026-08-21	25	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-22 04:19:37.09366	\N	2026-08-22 04:19:37.09366	t	250	2026-08-22 06:41:34.988	1
231	2026-08-21	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-22 04:20:37.880008	\N	2026-08-22 04:20:37.880008	t	250	2026-08-22 06:41:34.988	1
229	2026-08-21	21	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 15:20:37.748251	\N	2026-08-21 15:20:37.748251	t	251	2026-08-22 06:43:22.935	1
233	2026-08-21	21	9	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-22 04:23:08.606383	\N	2026-08-22 04:23:08.606383	t	251	2026-08-22 06:43:22.935	1
227	2026-08-21	15	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 15:18:18.06769	\N	2026-08-21 15:18:18.06769	t	252	2026-08-22 06:45:29.239	1
228	2026-08-21	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-21 15:19:39.772427	\N	2026-08-21 15:19:39.772427	t	252	2026-08-22 06:45:29.239	1
232	2026-08-21	18	2	17	Night	submitted	\N	Iftikhar Ahmed	2026-08-22 04:21:45.271294	\N	2026-08-22 04:21:45.271294	t	252	2026-08-22 06:45:29.239	1
250	2026-08-24	21	1	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-25 04:37:01.62906	\N	2026-08-25 04:37:01.62906	t	265	2026-08-25 06:53:52.902	1
234	2026-08-22	25	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-22 14:56:01.916476	\N	2026-08-22 14:56:01.916476	t	255	2026-08-24 09:49:01.775	1
235	2026-08-22	14	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-22 14:57:22.781042	\N	2026-08-22 14:57:22.781042	t	255	2026-08-24 09:49:01.775	1
237	2026-08-22	21	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-22 14:58:42.513398	\N	2026-08-22 14:58:42.513398	t	255	2026-08-24 09:49:01.775	1
239	2026-08-22	25	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-23 07:49:38.66813	\N	2026-08-23 07:49:38.66813	t	255	2026-08-24 09:49:01.775	1
240	2026-08-22	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-23 07:50:38.364573	\N	2026-08-23 07:50:38.364573	t	255	2026-08-24 09:49:01.775	1
236	2026-08-22	18	7	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-22 14:58:04.942236	Iftikhar Ahmed	2026-08-23 07:53:37.335	t	256	2026-08-24 10:01:03.22	1
238	2026-08-22	21	8	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-22 14:59:20.700636	\N	2026-08-22 14:59:20.700636	t	257	2026-08-24 10:03:00.312	1
241	2026-08-22	21	9	17	Night	submitted	\N	Iftikhar Ahmed	2026-08-23 07:51:45.445947	\N	2026-08-23 07:51:45.445947	t	257	2026-08-24 10:03:00.312	1
242	2026-08-23	25	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-24 06:02:34.924141	\N	2026-08-24 06:02:34.924141	t	258	2026-08-24 10:04:52.498	1
243	2026-08-23	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-24 06:03:31.73487	\N	2026-08-24 06:03:31.73487	t	258	2026-08-24 10:04:52.498	1
245	2026-08-23	25	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-24 06:05:27.315084	\N	2026-08-24 06:05:27.315084	t	258	2026-08-24 10:04:52.498	1
246	2026-08-23	14	2	16	Night	submitted	\N	Iftikhar Ahmed	2026-08-24 06:06:16.540301	\N	2026-08-24 06:06:16.540301	t	258	2026-08-24 10:04:52.498	1
244	2026-08-23	21	1	17	Morning	submitted	\N	Iftikhar Ahmed	2026-08-24 06:04:20.260871	\N	2026-08-24 06:04:20.260871	t	259	2026-08-24 10:06:26.392	1
248	2026-08-23	21	9	17	Night	submitted	\N	Iftikhar Ahmed	2026-08-24 06:12:09.340163	\N	2026-08-24 06:12:09.340163	t	259	2026-08-24 10:06:26.392	1
249	2026-08-24	14	8	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-25 04:35:15.569093	\N	2026-08-25 04:35:15.569093	t	264	2026-08-25 06:52:17.485	1
251	2026-08-25	21	1	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-27 06:00:56.608211	\N	2026-08-27 06:00:56.608211	t	271	2026-08-28 06:54:27.522	1
254	2026-08-27	19	7	16	Morning	submitted	\N	Iftikhar Ahmed	2026-08-28 04:45:45.086238	\N	2026-08-28 04:45:45.086238	t	277	2026-08-28 07:11:02.863	1
252	2026-08-27	25	1	15	Morning	submitted	\N	Iftikhar Ahmed	2026-08-28 04:44:06.798769	\N	2026-08-28 04:44:06.798769	t	278	2026-08-28 07:12:06.659	1
253	2026-08-27	14	8	15	Morning	submitted	\N	Iftikhar Ahmed	2026-08-28 04:45:05.693469	\N	2026-08-28 04:45:05.693469	t	278	2026-08-28 07:12:06.659	1
255	2026-08-27	25	9	15	Night	submitted	\N	Iftikhar Ahmed	2026-08-28 04:46:31.095324	\N	2026-08-28 04:46:31.095324	t	278	2026-08-28 07:12:06.659	1
256	2026-08-27	14	2	15	Night	submitted	\N	Iftikhar Ahmed	2026-08-28 04:47:34.924058	\N	2026-08-28 04:47:34.924058	t	278	2026-08-28 07:12:06.659	1
257	2026-08-17	15	18	14	Morning	submitted	\N	Hassan Imam	2026-08-28 08:00:46.506389	\N	2026-08-28 08:00:46.506389	t	281	2026-08-28 08:03:19.578	1
258	2026-08-28	25	1	15	Morning	submitted	\N	Iftikhar Ahmed	2026-08-29 04:53:59.057269	\N	2026-08-29 04:53:59.057269	t	289	2026-08-29 07:28:27.485	1
259	2026-08-28	14	8	15	Morning	submitted	\N	Iftikhar Ahmed	2026-08-29 04:54:57.260201	\N	2026-08-29 04:54:57.260201	t	289	2026-08-29 07:28:27.485	1
260	2026-08-28	25	9	15	Night	submitted	\N	Iftikhar Ahmed	2026-08-29 04:55:58.871861	\N	2026-08-29 04:55:58.871861	t	289	2026-08-29 07:28:27.485	1
261	2026-08-28	14	2	15	Night	submitted	\N	Iftikhar Ahmed	2026-08-29 04:56:50.689512	\N	2026-08-29 04:56:50.689512	t	289	2026-08-29 07:28:27.485	1
\.


--
-- Data for Name: department_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.department_master (id, name, code, tenant_id) FROM stdin;
1	Administration	0001	1
3	Loader	0003	1
4	Checker	0004	1
2	Operator	0002	1
\.


--
-- Data for Name: email_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.email_templates (id, tenant_id, template_key, template_name, subject_line, template_html, template_text, header_color, footer_color, include_logo, include_footer, custom_footer_text, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: employee_advances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_advances (id, employee_id, date, amount, notes, created_at, tenant_id) FROM stdin;
1	15	2026-08-06	10000	For rashan k liye	2026-08-06 13:47:29.301977	1
5	14	2026-08-10	5000	Advance 	2026-08-10 13:37:08.800964	1
6	16	2026-08-12	5000	\N	2026-08-12 10:43:39.53903	1
7	14	2026-08-13	2000	\N	2026-08-13 12:56:40.4883	1
8	11	2026-08-15	10000	family wedding	2026-08-15 13:39:16.459103	1
9	16	2026-08-15	5000	\N	2026-08-15 13:41:19.554272	1
10	14	2026-08-15	5000	\N	2026-08-15 13:41:28.057675	1
11	9	2026-08-17	5000	\N	2026-08-17 13:18:15.574669	1
12	10	2026-08-18	1000	\N	2026-08-19 07:41:34.62213	1
13	15	2026-08-19	1000	\N	2026-08-20 09:10:11.425687	1
14	10	2026-08-21	20000	Advance for the month of august	2026-08-21 12:12:07.868518	1
15	12	2026-08-21	35000	Advance for the month of august	2026-08-21 12:12:46.618261	1
16	8	2026-08-21	20000	Advance for the month of august	2026-08-21 12:15:16.279128	1
17	7	2026-08-21	15000	Advance for the month of august	2026-08-21 12:18:20.979547	1
18	1	2026-08-21	13000	Advance for the month of august	2026-08-21 12:19:41.78315	1
19	9	2026-08-21	5000	Advance for the month of august	2026-08-21 12:21:42.188399	1
20	2	2026-08-21	20000	Advance for the month of august	2026-08-21 12:22:14.657654	1
21	11	2026-08-21	5000	Advance for the month of august	2026-08-21 12:25:04.019592	1
22	15	2026-08-21	15000	Advance for the month of august	2026-08-21 13:03:29.270914	1
23	14	2026-08-21	12000	Advance for the month of august	2026-08-21 13:08:35.294237	1
24	16	2026-08-21	13000	Advance for the month of august	2026-08-21 13:08:45.47674	1
25	9	2026-08-22	10000	\N	2026-08-22 11:56:31.05545	1
\.


--
-- Data for Name: employee_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_master (id, name, code, department_id, base_salary, overtime_rate_hr, att_allowance, oth_allowance, active, tenant_id) FROM stdin;
10	Iftikhar	9901	1	55000.00	\N	\N	\N	t	1
11	Imran	9902	1	36000.00	\N	\N	\N	t	1
12	Liaquat	9903	1	80000.00	\N	\N	\N	t	1
1	Umaid	001	2	1200.00	\N	2000.00	2000.00	t	1
2	Nasir	002	2	1200.00	\N	2000.00	2000.00	t	1
4	Rasheed	003	2	1200.00	\N	2000.00	2000.00	f	1
3	Sajiid Rehman	004	2	1200.00	\N	2000.00	2000.00	t	1
5	Zain	005	2	1200.00	\N	2000.00	2000.00	f	1
6	Rashid	006	2	1200.00	\N	2000.00	2000.00	f	1
7	Raza	007	2	1200.00	\N	2000.00	2000.00	t	1
8	Gul Muhammad	008	2	1200.00	\N	2000.00	2000.00	t	1
9	Kareem	009	2	1200.00	\N	2000.00	2000.00	t	1
14	Safdar	9905	3	30000.00	100.00	3000.00	\N	t	1
16	Sardar	9907	3	30000.00	100.00	3000.00	\N	t	1
15	Dilshad	9906	3	30000.00	100.00	3000.00	\N	t	1
13	Zulfiqar	9904	4	33000.00	\N	2000.00	\N	f	1
17	Shiraj	9908	4	33000.00	\N	2000.00	\N	t	1
18	Quality 	011	2	\N	\N	\N	\N	t	1
19	Muhammad Moosa	9909	4	33000.00	110.00	2000.00	\N	t	1
\.


--
-- Data for Name: employee_salary_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_salary_records (id, employee_id, date, base_wage, commission, final_salary, created_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: employee_salary_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_salary_settings (id, employee_id, base_daily_wage, tenant_id) FROM stdin;
1	2	1200	1
2	4	1200.00	1
3	6	1200.00	1
4	3	1200.00	1
5	1	1200.00	1
6	5	1200.00	1
\.


--
-- Data for Name: fabric_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fabric_type_master (id, name, code, tenant_id) FROM stdin;
4	RIB (1X1)	RIB (1X1)	1
2	2-Fleece	2-Fleece	1
13	3-Fleece	3-Fleece	1
14	Single Jersey Double Tar	Single Jersey Double Tar	1
15	RIB (1X1) Double Tar	RIB (1X1) Double Tar	1
3	RIB (2X1) Double Tar	RIB (2X1) Double Tar	1
1	Single Jersey	Single Jersey	1
16	RIB (2X1)	RIB (2X1)	1
\.


--
-- Data for Name: factory_maintenance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.factory_maintenance (id, maintenance_date, category, maintenance_work, status, created_by, created_at, updated_by, updated_at, tenant_id) FROM stdin;
1	2026-08-25	Electrical	inverter compressor repair	cancelled	Tahir Hassan	2026-08-25 06:42:57.986117	Tahir Hassan	2026-08-25 06:47:20.297	1
\.


--
-- Data for Name: feature_flags; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.feature_flags (id, tenant_id, feature_key, feature_name, description, is_enabled, is_beta, category, max_users, max_orders, max_storage_mb, max_api_calls_per_month, enabled_at, disabled_at, created_at, updated_at) FROM stdin;
1	1	invoicing	Invoicing Module	Enable invoice creation and management	t	f	core	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
2	1	analytics	Analytics Dashboard	Enable analytics and reporting	t	f	core	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
3	1	api_access	API Access	Enable REST API access for integrations	f	f	enterprise	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
4	1	advanced_reporting	Advanced Reporting	Enable custom reports and exports	f	f	enterprise	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
5	1	multi_warehouse	Multi-Warehouse	Enable multiple warehouse management	f	f	enterprise	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
6	1	automated_workflows	Automated Workflows	Enable workflow automation	f	f	enterprise	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
7	1	audit_logs	Audit Logs	Enable detailed audit trail	t	f	enterprise	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
8	1	user_management	User Management	Enable team member management	t	f	core	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
9	1	role_based_access	Role-Based Access Control	Enable RBAC for users	t	f	core	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
10	1	two_factor_auth	2FA Authentication	Enable two-factor authentication	t	f	security	\N	\N	\N	\N	\N	\N	2026-08-26 19:07:52.679419	2026-08-26 19:07:52.679419
\.


--
-- Data for Name: integration_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.integration_settings (id, tenant_id, integration_key, integration_name, description, is_enabled, is_configured, api_key, api_secret, webhook_url, webhook_secret, config_json, last_sync_at, last_error_message, error_count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice (id, invoice_date, company_id, party_id, status, fbr_invoice_number, fbr_status_code, fbr_raw_response, total_value, total_tax, grand_total, created_by, created_at, updated_at, posted_at, due_days, origin, tenant_id) FROM stdin;
217	2026-02-28	1	15	posted	217	\N	\N	2881.50	518.67	3400.17	tahirhassan	2026-08-16 18:18:29.549641	2026-08-16 18:18:29.549641	2026-02-28 00:00:00	90	manual	1
224	2026-03-31	1	20	posted	224	\N	\N	17115.00	3080.70	20195.70	tahirhassan	2026-08-16 18:23:32.689355	2026-08-16 18:23:32.689355	2026-03-31 00:00:00	60	manual	1
226	2026-04-30	1	13	posted	226	\N	\N	428735.75	77172.44	505908.19	tahirhassan	2026-08-16 18:28:04.756605	2026-08-16 18:28:04.756605	2026-04-30 00:00:00	90	manual	1
227	2026-04-30	1	19	posted	227	\N	\N	156160.65	28108.92	184269.57	tahirhassan	2026-08-16 18:31:12.152217	2026-08-16 18:31:12.152217	2026-04-30 00:00:00	90	manual	1
229	2026-04-30	1	14	posted	229	\N	\N	494865.60	89075.80	583941.40	tahirhassan	2026-08-16 18:37:07.979136	2026-08-16 18:37:07.979136	2026-04-30 00:00:00	60	manual	1
243	2026-06-30	1	14	posted	243	\N	\N	404990.10	72898.22	477888.32	tahirhassan	2026-08-16 18:40:59.347969	2026-08-16 18:40:59.347969	2026-06-30 00:00:00	60	manual	1
231	2026-04-30	1	20	posted	231	\N	\N	59255.00	10665.90	69920.90	tahirhassan	2026-08-16 18:45:05.722669	2026-08-16 18:45:05.722669	2026-04-30 00:00:00	60	manual	1
233	2026-04-30	1	15	posted	233	\N	\N	123429.25	22217.27	145646.52	tahirhassan	2026-08-16 18:46:51.953058	2026-08-16 18:46:51.953058	2026-04-30 00:00:00	90	manual	1
241	2026-05-31	1	15	posted	241	\N	\N	226504.25	40770.77	267275.02	tahirhassan	2026-08-16 18:47:40.907112	2026-08-16 18:47:40.907112	2026-05-31 00:00:00	90	manual	1
251	2026-07-31	1	15	posted	251	\N	\N	122958.50	22132.53	145091.03	tahirhassan	2026-08-16 18:48:22.077033	2026-08-16 18:48:22.077033	2026-07-31 00:00:00	90	manual	1
234	2026-05-31	1	13	posted	234	\N	\N	323617.60	58251.17	381868.77	tahirhassan	2026-08-16 18:50:17.268544	2026-08-16 18:50:17.268544	2026-05-31 00:00:00	90	manual	1
242	2026-06-30	1	13	posted	242	\N	\N	378025.60	68044.61	446070.21	tahirhassan	2026-08-16 18:51:00.488544	2026-08-16 18:51:00.488544	2026-06-30 00:00:00	90	manual	1
247	2026-07-31	1	13	posted	247	\N	\N	478567.00	86142.06	564709.06	tahirhassan	2026-08-16 18:52:29.550241	2026-08-16 18:52:29.550241	2026-07-31 00:00:00	90	manual	1
236	2026-05-31	1	16	posted	236	\N	\N	119130.10	21443.42	140573.52	tahirhassan	2026-08-16 18:58:39.777194	2026-08-16 18:58:39.777194	2026-05-31 00:00:00	90	manual	1
253	2026-07-31	1	16	posted	253	\N	\N	541957.10	97552.28	639509.38	tahirhassan	2026-08-16 19:00:45.962379	2026-08-16 19:00:45.962379	2026-07-31 00:00:00	90	manual	1
254	2026-07-31	1	17	posted	254	\N	\N	10409.80	1873.76	12283.56	tahirhassan	2026-08-16 19:02:48.116447	2026-08-16 19:02:48.116447	2026-07-31 00:00:00	60	manual	1
239	2026-05-31	1	20	posted	239	\N	\N	58040.00	10447.20	68487.20	tahirhassan	2026-08-16 19:06:41.432595	2026-08-16 19:06:41.432595	2026-05-31 00:00:00	60	manual	1
245	2026-06-30	1	20	posted	245	\N	\N	4316.00	776.88	5092.88	tahirhassan	2026-08-16 19:07:47.507629	2026-08-16 19:07:47.507629	2026-06-30 00:00:00	60	manual	1
250	2026-07-31	1	20	posted	250	\N	\N	9444.00	1699.92	11143.92	tahirhassan	2026-08-16 19:08:37.313106	2026-08-16 19:08:37.313106	2026-07-31 00:00:00	60	manual	1
244	2026-06-30	1	18	posted	244	\N	\N	689071.04	124032.79	813103.83	tahirhassan	2026-08-16 19:14:37.712952	2026-08-16 19:14:37.712952	2026-06-30 00:00:00	60	manual	1
249	2026-07-31	1	18	posted	249	\N	\N	25388.00	4569.84	29957.84	tahirhassan	2026-08-16 19:15:26.539317	2026-08-16 19:15:26.539317	2026-07-31 00:00:00	60	manual	1
200	2025-11-30	1	15	posted	200	\N	\N	532900.05	95922.01	628822.06	tahirhassan	2026-08-16 19:23:21.659572	2026-08-16 19:23:21.659572	2025-11-30 00:00:00	90	manual	1
235	2026-05-31	1	19	posted	235	\N	\N	667.00	120.06	787.06	tahirhassan	2026-08-16 19:27:26.921896	2026-08-16 19:27:26.921896	2026-05-31 00:00:00	90	manual	1
252	2026-07-31	1	19	posted	252	\N	\N	81442.80	14659.70	96102.50	tahirhassan	2026-08-16 19:29:45.765231	2026-08-16 19:29:45.765231	2026-07-31 00:00:00	90	manual	1
237	2026-05-31	1	14	posted	237	\N	\N	912040.90	164167.36	1076208.26	tahirhassan	2026-08-16 20:00:45.71659	2026-08-16 20:00:45.71659	2026-05-31 00:00:00	60	manual	1
248	2026-07-31	1	14	posted	248	\N	\N	393172.90	70771.13	463944.03	tahirhassan	2026-08-16 20:18:07.936155	2026-08-16 20:18:07.936155	2026-07-31 00:00:00	60	manual	1
256	2026-08-29	1	14	draft	\N	\N	\N	590888.00	106359.84	697247.84	Khurram Hassan	2026-08-29 11:15:55.368811	2026-08-29 11:15:55.424	\N	\N	fbr	1
\.


--
-- Data for Name: invoice_item; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_item (id, invoice_id, yarn_type_id, yarn_count_id, hs_code, uom, product_description, quantity, rate_per_kg, value_excluding_tax, tax_amount, total_value, sale_type, tenant_id) FROM stdin;
1	217	20	45	\N	\N	\N	31.650	50.00	1582.50	284.85	1867.35	Goods at standard rate (default)	1
2	217	22	15	\N	\N	\N	22.750	50.00	1137.50	204.75	1342.25	Goods at standard rate (default)	1
3	217	24	39	\N	\N	\N	1.700	95.00	161.50	29.07	190.57	Goods at standard rate (default)	1
4	224	20	31	\N	\N	\N	142.750	100.00	14275.00	2569.50	16844.50	Goods at standard rate (default)	1
5	224	24	16	\N	\N	\N	6.000	100.00	600.00	108.00	708.00	Goods at standard rate (default)	1
6	224	24	13	\N	\N	\N	4.000	100.00	400.00	72.00	472.00	Goods at standard rate (default)	1
7	224	24	13	\N	\N	\N	18.400	100.00	1840.00	331.20	2171.20	Goods at standard rate (default)	1
8	226	22	13	\N	\N	\N	12434.000	22.00	273548.00	49238.64	322786.64	Goods at standard rate (default)	1
9	226	22	2	\N	\N	\N	1607.500	24.00	38580.00	6944.40	45524.40	Goods at standard rate (default)	1
10	226	20	27	\N	\N	\N	3331.650	35.00	116607.75	20989.40	137597.15	Goods at standard rate (default)	1
11	227	20	47	\N	\N	\N	5384.850	29.00	156160.65	28108.92	184269.57	Goods at standard rate (default)	1
12	229	20	49	\N	\N	\N	12071.400	32.00	386284.80	69531.26	455816.06	Goods at standard rate (default)	1
13	229	20	28	\N	\N	\N	3393.150	32.00	108580.80	19544.54	128125.34	Goods at standard rate (default)	1
16	243	20	28	\N	\N	\N	5231.400	32.00	167404.80	30132.86	197537.66	Goods at standard rate (default)	1
17	243	20	29	\N	\N	\N	4415.050	34.00	150111.70	27020.11	177131.81	Goods at standard rate (default)	1
18	243	23	36	\N	\N	\N	2733.550	32.00	87473.60	15745.25	103218.85	Goods at standard rate (default)	1
21	231	20	23	\N	\N	\N	520.250	100.00	52025.00	9364.50	61389.50	Goods at standard rate (default)	1
22	231	24	2	\N	\N	\N	85.950	50.00	4297.50	773.55	5071.05	Goods at standard rate (default)	1
23	231	22	2	\N	\N	\N	58.650	50.00	2932.50	527.85	3460.35	Goods at standard rate (default)	1
24	233	20	23	\N	\N	\N	3526.550	35.00	123429.25	22217.27	145646.52	Goods at standard rate (default)	1
25	241	20	23	\N	\N	\N	6471.550	35.00	226504.25	40770.77	267275.02	Goods at standard rate (default)	1
26	251	20	23	\N	\N	\N	3513.100	35.00	122958.50	22132.53	145091.03	Goods at standard rate (default)	1
27	234	20	23	\N	\N	\N	10113.050	32.00	323617.60	58251.17	381868.77	Goods at standard rate (default)	1
28	242	20	23	\N	\N	\N	11813.300	32.00	378025.60	68044.61	446070.21	Goods at standard rate (default)	1
29	247	20	23	\N	\N	\N	14844.900	32.00	475036.80	85506.62	560543.42	Goods at standard rate (default)	1
30	247	20	26	\N	\N	\N	49.400	35.00	1729.00	311.22	2040.22	Goods at standard rate (default)	1
31	247	20	27	\N	\N	\N	47.400	38.00	1801.20	324.22	2125.42	Goods at standard rate (default)	1
32	236	20	23	\N	\N	\N	3162.650	34.00	107530.10	19355.42	126885.52	Goods at standard rate (default)	1
33	236	23	39	\N	\N	\N	145.000	80.00	11600.00	2088.00	13688.00	Goods at standard rate (default)	1
34	253	20	26	\N	\N	\N	11828.750	34.00	402177.50	72391.95	474569.45	Goods at standard rate (default)	1
35	253	24	39	\N	\N	\N	1688.100	80.00	135048.00	24308.64	159356.64	Goods at standard rate (default)	1
36	253	22	13	\N	\N	\N	197.150	24.00	4731.60	851.69	5583.29	Goods at standard rate (default)	1
37	254	20	46	\N	\N	\N	335.800	31.00	10409.80	1873.76	12283.56	Goods at standard rate (default)	1
38	239	20	29	\N	\N	\N	200.000	80.00	16000.00	2880.00	18880.00	Goods at standard rate (default)	1
39	239	20	29	\N	\N	\N	65.550	80.00	5244.00	943.92	6187.92	Goods at standard rate (default)	1
40	239	20	29	\N	\N	\N	134.950	90.00	12145.50	2186.19	14331.69	Goods at standard rate (default)	1
41	239	24	2	\N	\N	\N	135.050	80.00	10804.00	1944.72	12748.72	Goods at standard rate (default)	1
42	239	23	40	\N	\N	\N	106.050	90.00	9544.50	1718.01	11262.51	Goods at standard rate (default)	1
43	239	22	2	\N	\N	\N	47.800	90.00	4302.00	774.36	5076.36	Goods at standard rate (default)	1
44	245	20	29	\N	\N	\N	52.100	80.00	4168.00	750.24	4918.24	Goods at standard rate (default)	1
45	245	23	2	\N	\N	\N	1.850	80.00	148.00	26.64	174.64	Goods at standard rate (default)	1
46	250	20	29	\N	\N	\N	118.050	80.00	9444.00	1699.92	11143.92	Goods at standard rate (default)	1
47	244	22	17	\N	\N	\N	8203.270	27.00	221488.29	39867.89	261356.18	Goods at standard rate (default)	1
48	244	20	29	\N	\N	\N	11654.000	40.00	466160.00	83908.80	550068.80	Goods at standard rate (default)	1
49	244	23	2	\N	\N	\N	40.650	35.00	1422.75	256.10	1678.85	Goods at standard rate (default)	1
50	249	20	29	\N	\N	\N	634.700	40.00	25388.00	4569.84	29957.84	Goods at standard rate (default)	1
51	200	20	28	\N	\N	\N	12936.100	35.00	452763.50	81497.43	534260.93	Goods at standard rate (default)	1
52	200	22	2	\N	\N	\N	144.300	26.00	3751.80	675.32	4427.12	Goods at standard rate (default)	1
53	200	23	38	\N	\N	\N	804.050	95.00	76384.75	13749.26	90134.01	Goods at standard rate (default)	1
54	235	20	47	\N	\N	\N	23.000	29.00	667.00	120.06	787.06	Goods at standard rate (default)	1
55	252	24	37	\N	\N	\N	3016.400	27.00	81442.80	14659.70	96102.50	Goods at standard rate (default)	1
56	237	20	28	\N	\N	\N	17676.050	32.00	565633.60	101814.05	667447.65	Goods at standard rate (default)	1
57	237	20	29	\N	\N	\N	9297.250	34.00	316106.50	56899.17	373005.67	Goods at standard rate (default)	1
58	237	23	36	\N	\N	\N	946.900	32.00	30300.80	5454.14	35754.94	Goods at standard rate (default)	1
59	248	20	29	\N	\N	\N	6520.050	34.00	221681.70	39902.71	261584.41	Goods at standard rate (default)	1
60	248	20	28	\N	\N	\N	5359.100	32.00	171491.20	30868.42	202359.62	Goods at standard rate (default)	1
63	256	20	28	6002.9000	KG	3-Fleece fabric	6525.200	32.00	208806.40	37585.15	246391.55	Goods at standard rate (default)	1
64	256	20	42	6002.9000	KG	3-Fleece fabric	11940.050	32.00	382081.60	68774.69	450856.29	Goods at standard rate (default)	1
\.


--
-- Data for Name: invoice_payment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_payment (id, invoice_id, amount, tax_deduction, payment_date, method, reference, notes, paid_by, created_at, tenant_id) FROM stdin;
1	200	70241.00	0.00	2026-05-22	Cheque	CA-86523688	Soneri Bank	tahirhassan	2026-08-16 19:48:42.403862	1
2	229	583941.40	5839.41	2026-08-20	Cheque	87053434	Bank Al Habib Limited	tahirhassan	2026-08-20 09:31:44.514823	1
3	237	1076208.26	10762.08	2026-08-20	Cheque	87053564	Bank Al Habib Limited	tahirhassan	2026-08-20 09:32:24.514265	1
4	226	505908.19	5059.08	2026-08-24	Cheque	Chq#4210478-B-AL-H  Dt. 21-08-2026 	\N	hassanimam	2026-08-25 09:35:14.842191	1
\.


--
-- Data for Name: invoice_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_transaction (id, invoice_id, transaction_header_id, tenant_id) FROM stdin;
7	256	174	1
8	256	176	1
9	256	179	1
10	256	191	1
11	256	218	1
12	256	224	1
\.


--
-- Data for Name: job_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_master (id, name, code, party_id, tenant_id) FROM stdin;
19	Feroze	Feroze	18	1
16	GWCC	GWCC	15	1
15	Lucky Knits	Lucky Knits	14	1
17	Mahad	Mahad	17	1
14	Perfect	Perfact	16	1
13	Towellers	Towellers	13	1
18	Eastern Garments	Eastern	19	1
\.


--
-- Data for Name: location_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.location_master (id, name, code, tenant_id) FROM stdin;
13	New Karachi	L-001	1
14	SITE Area	L-002	1
15	SITE-II Scheme 33	L-003	1
16	Landhi Industrial Area	L-004	1
17	Hub Chowki	L-005	1
18	Kathor, Super Highway	L-006	1
\.


--
-- Data for Name: login_attempts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.login_attempts (id, tenant_id, email, ip_address, attempt_count, status, failure_reason, is_locked, locked_until, lockout_reason, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logo_uploads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.logo_uploads (id, tenant_id, filename, original_filename, file_type, file_size, storage_url, storage_path, storage_provider, width, height, logo_type, is_active, uploaded_by, created_at) FROM stdin;
\.


--
-- Data for Name: machine_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_history (id, machine_id, machine_number, name, making_rate, needle_change_date, needle_brand, sinker_change_date, sinker_brand, action, changed_by, changed_at, tenant_id) FROM stdin;
1	14	M-002	M#02	3.75	2026-04-10	Sigma	2026-04-10	Kohala	created	system	2026-08-19 20:36:16.964424	1
2	15	M-003	M#03	3.75	2026-07-29	Sigma	2026-07-29	Kohala	created	system	2026-08-19 20:36:16.964424	1
3	18	M-004	M#04	3.75	2025-11-26	Sigma	2025-11-26	Kohala	created	system	2026-08-19 20:36:16.964424	1
4	19	M-005	M#05	3.00	2026-01-15	Sigma	2026-01-21	Kohala	created	system	2026-08-19 20:36:16.964424	1
5	20	M-006	M#06	3.00	2026-01-13	Sigma	2026-01-13	Sigma/YGH	created	system	2026-08-19 20:36:16.964424	1
6	21	M-007	M#07	4.00	2026-07-16	Sigma	2026-07-16	Sigma	created	system	2026-08-19 20:36:16.964424	1
7	22	M-008	M#08	3.75	2026-04-25	Sigma	2026-04-25	Kohala	created	system	2026-08-19 20:36:16.964424	1
8	23	M-009	M#09	3.75	2026-01-26	Sigma	2026-06-12	Kohala	created	system	2026-08-19 20:36:16.964424	1
9	24	M-010	M#10	3.75	2026-07-31	KE Needle	2026-07-31	Kohala	created	system	2026-08-19 20:36:16.964424	1
10	25	M-001	M#01	3.75	2025-12-24	Sigma	2025-12-24	Kohala	created	system	2026-08-19 20:36:16.964424	1
11	18	M-004	M#04	3.75	2026-08-19	Sigma	2026-08-19	Kohala	updated	tahirhassan	2026-08-20 08:13:22.056657	1
12	29	M-000	M#00	0.00	2026-08-01	Sigma	2026-08-01	Kohala	created	tahirhassan	2026-08-28 10:42:17.240752	1
\.


--
-- Data for Name: machine_maintenance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_maintenance (id, maintenance_date, machine_id, maintenance_work, cost, vendor, status, created_by, created_at, updated_by, updated_at, tenant_id) FROM stdin;
1	2026-08-10	20	Machine No. 6 — Work Date Sheet\n\nکام شروع ہونے کی تاریخ: 11-08-2026\nکام مکمل ہونے کا دورانیہ: 5 دن\n\nکروائے گئے کام\n\n1. S/Jersey کو Cross 3 Fleece میں Convert کیا گیا۔\n2. Mechanic کو بلا کر 6 تانگوں میں گٹکے بنوائے گئے۔\n3. ڈائل کے اندر 5 نمبر Elki کے Hall کروائے گئے۔\n4. Machine No. 3 کی سوئی اور شنکر Machine No. 6 میں ڈالے گئے۔\n5. مشین کا کام مکمل ہونے میں 5 دن لگے۔\n6. کپڑا نیچے آنے کے بعد ایک رول بنا کر چیک کیا گیا۔\n7. چیکنگ کے دوران کپڑے میں سفید لائنیں (White Lines) نظر آئیں۔\n8. سفید لائنیں آنے کے بعد Machine No. 6 بند کر دی گئی۔\n\nFinal Status\n\nMachine No. 6: بند — کپڑے میں سفید لائنوں کا مسئلہ چیک کرنا باقی ہے۔	6000.000	Amjad	cancelled	Iftikhar Ahmed	2026-08-15 15:47:43.250295	Iftikhar Ahmed	2026-08-15 16:01:52.143	1
2	2026-08-10	20	مشین نمبر 6 — سنگل جرسی سے تھری فلیس میں تبدیلی\n\n1. مشین نمبر 6 کو سنگل جرسی سے تھری فلیس میں تبدیل کیا گیا۔\n\n2. مکینک نے 6 گٹکے تیار کروائے، جو 6 ٹانگوں کے لیے تھے۔\n\n3. ڈائل میں سوراخ کروائے گئے۔\n\n4. مشین نمبر 3 کی سوئیاں اور شنکر مشین نمبر 6 میں لگا دیے گئے۔\n\n5. مشین نمبر 6 کو اسٹارٹ کیا گیا اور ایک رول تیار کیا گیا۔\n\n6. تیار کیے گئے رول کی چیکنگ کے دوران کپڑے میں شیڈ لائن نظر آئی۔\n\n7. شیڈ لائن کی وجہ سے مشین نمبر 6 کو بند کر دیا گیا تاکہ خرابی کو چیک کرکے درست کیا جا سکے۔	6000.000	Amjad	submitted	Iftikhar Ahmed	2026-08-15 16:10:23.450009	\N	2026-08-15 16:10:23.450009	1
3	2026-08-15	21	مشین نمبر 7 — تبدیلی اور پروڈکشن رپورٹ\n\nتاریخ: 15-08-2026\n\n1. مشین نمبر 7 پہلے 1×1 لائکرا رِب تیار کر رہی تھی۔\n\n2. مشین نمبر 7 کو 1×1 لائکرا رِب سے 2×1 لائکرا رِب میں تبدیل کر دیا گیا۔\n\n3. اس تبدیلی کے لیے پرانے والی سوئیوں کا استعمال کیا گیا۔\n\n4. تبدیلی کا کام مکمل ہونے کے بعد پرفیکٹ کمپنی کی پروڈکشن شروع کر دی گئی۔	\N	Master	submitted	Iftikhar Ahmed	2026-08-15 16:16:43.897275	\N	2026-08-15 16:16:43.897275	1
4	2026-08-08	23	Machine No. 9 — Work Report\n\nDate: 08/08/2026\n\n1. MPF change کروایا گیا۔\n2. تین Bald change کروائے گئے۔\n3. MPF wire change کروایا گیا۔	\N	\N	submitted	Iftikhar Ahmed	2026-08-18 05:37:51.831295	\N	2026-08-18 05:37:51.831295	1
5	2026-08-19	18	تاریخ: 19/8/2026\n\nمشین نمبر 4 کی مکمل سروس کروائی گئی۔ سروس کے دوران نئی سوئیاں (Needles) اور نیا شنکر (Sinker) لگایا گیا۔ تمام ضروری کام مکمل کرنے کے بعد مشین کو چلا کر چیک کیا گیا اور Mahad International پارٹی کی پروڈکشن شروع کر دی گئی۔	240000.000	\N	submitted	Iftikhar Ahmed	2026-08-20 04:19:02.051116	\N	2026-08-20 04:19:02.051116	1
6	2026-08-20	21	Change \nVendor belt A.29	300.000	Imran	submitted	Iftikhar Ahmed	2026-08-20 06:00:24.607777	\N	2026-08-20 06:00:24.607777	1
7	2026-08-25	25	Gear Repair	10000.000	Aslam	cancelled	Tahir Hassan	2026-08-25 06:41:54.302879	Tahir Hassan	2026-08-25 06:47:16.34	1
\.


--
-- Data for Name: machine_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_master (id, name, machine_number, making_rate, needle_change_date, needle_brand, sinker_change_date, sinker_brand, tenant_id) FROM stdin;
14	M#02	M-002	3.75	2026-04-10	Sigma	2026-04-10	Kohala	1
15	M#03	M-003	3.75	2026-07-29	Sigma	2026-07-29	Kohala	1
19	M#05	M-005	3.00	2026-01-15	Sigma	2026-01-21	Kohala	1
20	M#06	M-006	3.00	2026-01-13	Sigma	2026-01-13	Sigma/YGH	1
21	M#07	M-007	4.00	2026-07-16	Sigma	2026-07-16	Sigma	1
22	M#08	M-008	3.75	2026-04-25	Sigma	2026-04-25	Kohala	1
23	M#09	M-009	3.75	2026-01-26	Sigma	2026-06-12	Kohala	1
24	M#10	M-010	3.75	2026-07-31	KE Needle	2026-07-31	Kohala	1
25	M#01	M-001	3.75	2025-12-24	Sigma	2025-12-24	Kohala	1
18	M#04	M-004	3.75	2026-08-19	Sigma	2026-08-19	Kohala	1
29	M#00	M-000	0.00	2026-08-01	Sigma	2026-08-01	Kohala	1
\.


--
-- Data for Name: oauth_providers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.oauth_providers (id, tenant_id, provider_name, provider_type, client_id, client_secret, redirect_uri, scope, is_enabled, is_configured, config_json, created_at, updated_at) FROM stdin;
1	1	google	oauth2	\N	\N	\N	\N	f	f	\N	2026-08-26 19:07:53.698659	2026-08-26 19:07:53.698659
2	1	microsoft	oauth2	\N	\N	\N	\N	f	f	\N	2026-08-26 19:07:53.698659	2026-08-26 19:07:53.698659
3	1	github	oauth2	\N	\N	\N	\N	f	f	\N	2026-08-26 19:07:53.698659	2026-08-26 19:07:53.698659
\.


--
-- Data for Name: party_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.party_master (id, name, code, waste_percent, ntn_cnic, province, address, registration_type, credit_days, tenant_id) FROM stdin;
14	 Lucky Knits (Private) Limited	Lucky	1.00	2277359	Sindh	L-A-2/B, Block 21, FB Area, Karachi, Pakistan	Registered	60	1
21	Arif Silk	Arif	1.00	\N	\N	\N	Unregistered	90	1
19	Eastern Garments (Pvt) Limited	Eastern	1.00	0688665	Sindh	B-58, S.I.T.E, Karachi	Registered	90	1
18	Feroze 1888 Mills Limited	Feroze	2.00	0698565	Sindh	B-4/A, S.I.T.E, Karachi	Registered	60	1
15	GWCC	GWCC	1.00	1863333	Sindh	PLOT No 8/1-C, Street-5 Sector 12-C, North Karachi Industrial Area,  Karachi Central North Karachi Town	Registered	90	1
17	Mahad International	Mahad	1.00	A888524	Sindh	Plot No.H-160, Z-61, Floor No.2-3,, Super Highway SITE, Phase-2, Gadap Town, Karachi, Pakistan	Registered	60	1
20	PD-Feroze 1888 Mills Limited	Feroze PD	2.00	0698565	Sindh	B-4/A, S.I.T.E, Karachi	Registered	60	1
16	Perfect Apparel	Perfect	1.00	3754339	Sindh	Plot No.24/1, Sector 12-D, North Karachi Industrial Area, 	Registered	90	1
13	Towellers Limited	Towellers	1.00	0676889	Sindh	PLOT NO. W.S.A-30,, Block-1, Federal B Area,  Karachi Central, Gulberg Town, Karachi	Registered	90	1
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.password_reset_tokens (id, tenant_id, user_id, reset_token, email, is_used, used_at, expires_at, ip_address, created_at) FROM stdin;
\.


--
-- Data for Name: plausibility_baseline; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plausibility_baseline (id, operation, field, median, iqr, mad, lower_bound, upper_bound, sample_count, computed_at, tenant_id) FROM stdin;
65	production	roll_weight	27.450000	3.350000	2.483355	17.400000	37.500000	1662	2026-08-29 04:56:50.726	1
66	production	total_weight	197.275000	88.262500	64.789620	0.000000	462.062500	248	2026-08-29 04:56:50.737	1
67	production	total_weight@date	1846.600000	501.500000	395.705940	342.100000	3351.100000	27	2026-08-29 04:56:50.746	1
68	production	total_weight@shift	960.350000	385.225000	273.910350	0.000000	2116.025000	51	2026-08-29 04:56:50.754	1
69	production	total_weight@machine	368.700000	189.100000	143.515680	0.000000	936.000000	129	2026-08-29 04:56:50.763	1
70	production	total_weight@employee	394.250000	268.650000	219.610125	0.000000	1200.200000	122	2026-08-29 04:56:50.771	1
71	production	total_weight@date+shift	960.350000	385.225000	273.910350	0.000000	2116.025000	51	2026-08-29 04:56:50.779	1
72	production	total_weight@date+machine	368.700000	189.100000	143.515680	0.000000	936.000000	129	2026-08-29 04:56:50.788	1
21	delivery	net_weight	561.250000	955.900000	657.458970	0.000000	3428.950000	67	2026-08-29 13:46:10.867	1
22	delivery	quantity	20.000000	34.000000	22.239000	0.000000	122.000000	67	2026-08-29 13:46:10.873	1
23	delivery	gsm	250.000000	5.000000	7.413000	235.000000	265.000000	29	2026-08-29 13:46:10.877	1
24	delivery	wt_per_roll	26.575000	3.322748	2.409225	16.606756	36.543244	67	2026-08-29 13:46:10.883	1
25	delivery	net_total@delivery:party	1126.825000	1914.187500	1166.398485	0.000000	6869.387500	30	2026-08-29 13:46:10.894	1
26	delivery	net_total@delivery:type	670.800000	2157.075000	932.110620	0.000000	7142.025000	35	2026-08-29 13:46:10.906	1
27	delivery	net_total@delivery:party+type	597.275000	989.825000	729.328005	0.000000	3566.750000	46	2026-08-29 13:46:10.913	1
1	receipt	net_weight	1134.000000	1064.565000	973.756854	0.000000	4327.695000	42	2026-08-29 05:43:38.026	1
2	receipt	quantity	16.000000	24.500000	19.273800	0.000000	89.500000	42	2026-08-29 05:43:38.04	1
28	delivery	net_total@delivery:party+gsm_band	990.450000	1372.800000	1045.307130	0.000000	5108.850000	37	2026-08-29 13:46:10.92	1
29	delivery	net_total@delivery:type+gsm_band	595.250000	1433.275000	772.286340	0.000000	4895.075000	43	2026-08-29 13:46:10.927	1
3	receipt	wt_per_bag	45.360000	8.072500	0.520021	21.142500	69.577500	42	2026-08-29 05:43:38.053	1
4	receipt	net_total@receipt:party	2177.280000	3055.055000	2488.277232	0.000000	11342.445000	23	2026-08-29 05:43:38.065	1
5	receipt	net_total@receipt:count	1134.000000	2656.575000	941.510304	0.000000	9103.725000	34	2026-08-29 05:43:38.078	1
6	receipt	net_total@receipt:party+count	1134.000000	1306.887750	973.756854	0.000000	5054.663250	38	2026-08-29 05:43:38.088	1
7	receipt	net_total@receipt:party+brand	1134.000000	2024.692500	1040.785200	0.000000	7208.077500	34	2026-08-29 05:43:38.099	1
8	receipt	net_total@receipt:count+brand	1134.000000	1516.651750	941.510304	0.000000	5683.955250	36	2026-08-29 05:43:38.11	1
9	receipt	net_total@receipt:date+party	2177.280000	3055.055000	2488.277232	0.000000	11342.445000	23	2026-08-29 05:43:38.119	1
10	receipt	net_total@receipt:date+party+count	1134.000000	1306.887750	973.756854	0.000000	5054.663250	38	2026-08-29 05:43:38.135	1
30	delivery	net_total@delivery:date+party	1126.825000	1914.187500	1166.398485	0.000000	6869.387500	30	2026-08-29 13:46:10.935	1
31	delivery	net_total@delivery:date+party+type	597.275000	989.825000	729.328005	0.000000	3566.750000	46	2026-08-29 13:46:10.945	1
83	production	total_weight@shift+machine+employee	197.275000	82.912500	62.083875	0.000000	446.012500	238	2026-08-29 04:56:50.892	1
84	production	total_weight@shift+machine+party	197.275000	87.687500	64.233645	0.000000	460.337500	246	2026-08-29 04:56:50.905	1
85	production	total_weight@shift+employee+party	218.350000	240.925000	130.913580	0.000000	941.125000	183	2026-08-29 04:56:50.915	1
86	production	total_weight@machine+employee+party	197.275000	87.687500	64.233645	0.000000	460.337500	246	2026-08-29 04:56:50.926	1
87	production	total_weight@date+shift+machine+employee	197.275000	82.912500	62.083875	0.000000	446.012500	238	2026-08-29 04:56:50.935	1
88	production	total_weight@date+shift+machine+party	197.275000	87.687500	64.233645	0.000000	460.337500	246	2026-08-29 04:56:50.946	1
89	production	total_weight@date+shift+employee+party	218.350000	240.925000	130.913580	0.000000	941.125000	183	2026-08-29 04:56:50.954	1
90	production	total_weight@date+machine+employee+party	197.275000	87.687500	64.233645	0.000000	460.337500	246	2026-08-29 04:56:50.963	1
91	production	total_weight@shift+machine+employee+party	197.275000	87.687500	64.233645	0.000000	460.337500	246	2026-08-29 04:56:50.974	1
92	production	total_weight@date+shift+machine+employee+party	197.275000	87.687500	64.233645	0.000000	460.337500	246	2026-08-29 04:56:50.984	1
73	production	total_weight@date+employee	394.250000	268.650000	219.610125	0.000000	1200.200000	122	2026-08-29 04:56:50.796	1
74	production	total_weight@shift+machine	197.275000	82.912500	62.083875	0.000000	446.012500	238	2026-08-29 04:56:50.804	1
75	production	total_weight@shift+employee	394.250000	268.650000	219.610125	0.000000	1200.200000	122	2026-08-29 04:56:50.816	1
76	production	total_weight@machine+employee	197.275000	82.912500	62.083875	0.000000	446.012500	238	2026-08-29 04:56:50.826	1
77	production	total_weight@machine+party	368.675000	209.650000	151.039875	0.000000	997.625000	138	2026-08-29 04:56:50.835	1
78	production	total_weight@date+shift+machine	197.275000	82.912500	62.083875	0.000000	446.012500	238	2026-08-29 04:56:50.845	1
79	production	total_weight@date+shift+employee	394.250000	268.650000	219.610125	0.000000	1200.200000	122	2026-08-29 04:56:50.854	1
80	production	total_weight@date+machine+employee	197.275000	82.912500	62.083875	0.000000	446.012500	238	2026-08-29 04:56:50.862	1
81	production	total_weight@date+machine+party	368.675000	209.650000	151.039875	0.000000	997.625000	138	2026-08-29 04:56:50.869	1
82	production	total_weight@date+employee+party	218.350000	240.925000	130.913580	0.000000	941.125000	183	2026-08-29 04:56:50.88	1
\.


--
-- Data for Name: plausibility_feedback; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plausibility_feedback (id, operation, field, entered_value, expected_low, expected_high, outcome, created_by, created_at, tenant_id) FROM stdin;
1	production	roll_weight	16.350000	18.650000	37.250000	confirmed_anyway	Iftikhar	2026-08-12 05:22:38.934038	1
2	production	roll_weight	17.300000	18.650000	37.250000	confirmed_anyway	Iftikhar	2026-08-12 05:22:38.934038	1
3	production	roll_weight	16.750000	18.500000	37.400000	confirmed_anyway	Iftikhar	2026-08-12 05:23:29.030921	1
4	production	roll_weight	16.250000	18.600000	37.200000	confirmed_anyway	Iftikhar	2026-08-12 05:28:07.098999	1
5	production	roll_weight	9.350000	18.625000	37.375000	confirmed_anyway	Iftikhar	2026-08-13 04:46:55.552839	1
6	production	roll_weight	14.000000	18.625000	37.375000	confirmed_anyway	Iftikhar	2026-08-13 04:48:05.643428	1
7	production	roll_weight	9.350000	18.550000	37.450000	confirmed_anyway	Iftikhar Ahmed	2026-08-15 05:54:52.389743	1
8	delivery	gsm	145.000000	235.000000	265.000000	confirmed_anyway	Tahir Hassan	2026-08-15 11:00:36.449669	1
9	delivery	wt_per_roll	5.200000	17.040000	36.601000	confirmed_anyway	Tahir Hassan	2026-08-15 11:00:36.449669	1
10	delivery	gsm	145.000000	235.000000	265.000000	confirmed_anyway	Tahir Hassan	2026-08-15 11:01:03.177541	1
11	delivery	wt_per_roll	5.200000	17.040000	36.601000	confirmed_anyway	Tahir Hassan	2026-08-15 11:01:03.177541	1
12	production	roll_weight	16.000000	18.338000	37.463000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 05:23:30.422533	1
13	production	roll_weight	13.100000	18.338000	37.463000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 05:23:30.422533	1
14	delivery	gsm	340.000000	235.000000	265.000000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 07:19:50.745392	1
15	delivery	gsm	340.000000	235.000000	265.000000	confirmed_anyway	Iftikhar Ahmed	2026-08-17 07:20:44.927645	1
16	delivery	gsm	140.000000	235.000000	265.000000	confirmed_anyway	Iftikhar Ahmed	2026-08-18 11:55:08.282185	1
17	delivery	wt_per_roll	10.000000	17.312000	36.496000	confirmed_anyway	Iftikhar Ahmed	2026-08-18 11:55:08.282185	1
18	receipt	wt_per_bag	36.000000	36.202000	54.518000	confirmed_anyway	Iftikhar Ahmed	2026-08-19 11:32:20.780862	1
19	receipt	wt_per_bag	36.000000	43.653000	47.067000	confirmed_anyway	Iftikhar Ahmed	2026-08-19 11:35:52.323029	1
20	production	roll_weight	8.000000	17.775000	37.425000	confirmed_anyway	Iftikhar Ahmed	2026-08-20 04:27:49.026842	1
21	production	roll_weight	13.400000	17.738000	37.463000	confirmed_anyway	Iftikhar Ahmed	2026-08-20 04:28:21.696659	1
22	production	roll_weight	15.200000	17.700000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-20 04:29:27.370797	1
23	production	roll_weight	9.200000	17.700000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-20 04:29:27.370797	1
24	delivery	wt_per_roll	10.750000	16.900000	36.844000	confirmed_anyway	Iftikhar Ahmed	2026-08-20 10:33:17.521524	1
25	production	roll_weight	12.750000	17.650000	37.450000	confirmed_anyway	Iftikhar Ahmed	2026-08-21 04:36:12.32363	1
26	production	roll_weight	17.100000	17.650000	37.450000	confirmed_anyway	Iftikhar Ahmed	2026-08-21 04:36:12.32363	1
27	production	roll_weight	15.100000	17.650000	37.450000	confirmed_anyway	Iftikhar Ahmed	2026-08-21 04:37:10.01946	1
28	receipt	wt_per_bag	20.000000	43.119000	47.601000	confirmed_anyway	Iftikhar Ahmed	2026-08-21 12:34:23.863283	1
29	receipt	wt_per_bag	14.720000	41.519000	49.201000	confirmed_anyway	Iftikhar Ahmed	2026-08-21 12:35:09.280654	1
30	production	roll_weight	8.050000	17.600000	37.400000	confirmed_anyway	Iftikhar Ahmed	2026-08-21 15:18:17.940013	1
31	production	roll_weight	16.350000	17.600000	37.400000	confirmed_anyway	Iftikhar Ahmed	2026-08-21 15:20:37.566069	1
32	production	roll_weight	40.050000	17.575000	37.375000	confirmed_anyway	Iftikhar Ahmed	2026-08-22 14:58:04.89875	1
33	production	roll_weight	12.550000	17.600000	37.400000	confirmed_anyway	Iftikhar Ahmed	2026-08-22 14:59:20.566363	1
34	production	roll_weight	16.000000	17.600000	37.400000	confirmed_anyway	Iftikhar Ahmed	2026-08-22 14:59:20.566363	1
35	production	roll_weight	16.300000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-23 07:51:45.407317	1
36	production	roll_weight	40.050000	17.325000	37.575000	confirmed_anyway	Iftikhar Ahmed	2026-08-23 07:53:37.280861	1
37	production	roll_weight	16.950000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-24 06:05:27.281898	1
38	production	roll_weight	14.700000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-25 04:37:01.388813	1
39	production	roll_weight	14.050000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-25 04:37:01.388813	1
40	production	roll_weight	14.950000	17.400000	37.500000	confirmed_anyway	Iftikhar Ahmed	2026-08-27 06:00:56.55969	1
41	production	roll_weight	91.650000	17.400000	37.500000	confirmed_anyway	Hassan Imam	2026-08-28 08:00:46.409785	1
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role (id, name, is_admin, created_at, tenant_id) FROM stdin;
1	Admin	t	2026-08-13 19:58:33.532958	1
2	Manager	f	2026-08-13 19:58:33.53682	1
3	Supervisor	f	2026-08-13 19:58:33.53832	1
4	super-admin	t	2026-08-26 19:07:54.263006	1
6	super-admin	t	2026-08-26 19:11:20.707229	\N
\.


--
-- Data for Name: role_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role_permission (role_id, module_id) FROM stdin;
2	dashboard
2	transactions
2	dailyProduction
2	yarnReceipts
2	dailyDeliveries
2	payroll
2	reports
2	maintenance
2	masters
2	users
2	invoicing
2	companyInfo
3	dashboard
3	dailyProduction
3	yarnReceipts
3	dailyDeliveries
3	maintenance
3	masters
3	payroll
3	reports
\.


--
-- Data for Name: salary_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salary_detail (id, header_id, employee_id, month, year, department_id, employee_name, basic_salary, ot_rate_hr, att_allowance, oth_allowance, present_days, absent_days, holidays, total_attendance, total_salary, ot_hours, ot_amount, advance_deduction, loan_deduction, other_deduction, payable_salary, tenant_id) FROM stdin;
\.


--
-- Data for Name: salary_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salary_header (id, month, year, department_ids, posted, created_at, updated_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: session_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.session_settings (id, tenant_id, session_timeout_minutes, remember_me_enabled, remember_me_duration_days, max_concurrent_sessions, force_password_change_days, password_expiry_enabled, two_factor_required_for_admins, two_factor_optional_for_users, device_management_enabled, max_devices_per_user, ip_whitelist_enabled, ip_whitelist, created_at, updated_at) FROM stdin;
1	1	30	t	30	5	90	f	t	f	t	5	f	\N	2026-08-26 19:07:53.690948	2026-08-26 19:07:53.690948
\.


--
-- Data for Name: system_defaults; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_defaults (id, setting_key, setting_name, setting_value, data_type, description, is_readonly, created_at, updated_at) FROM stdin;
1	session_timeout_minutes	Session Timeout	30	integer	User session timeout in minutes	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
2	password_min_length	Min Password Length	8	integer	Minimum password length	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
3	password_require_uppercase	Require Uppercase	true	boolean	Require uppercase in passwords	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
4	password_require_special	Require Special Char	true	boolean	Require special characters in passwords	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
5	max_login_attempts	Max Login Attempts	5	integer	Max failed login attempts before lockout	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
6	lockout_duration_minutes	Lockout Duration	15	integer	Account lockout duration in minutes	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
7	default_invoice_terms	Default Invoice Terms	30 days	string	Default payment terms	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
8	default_discount_percentage	Default Discount	0	decimal	Default discount percentage	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
9	system_timezone	System Timezone	Asia/Karachi	string	System default timezone	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
10	system_currency	System Currency	PKR	string	System default currency	f	2026-08-26 19:07:52.686574	2026-08-26 19:07:52.686574
\.


--
-- Data for Name: tenant_admin_assignments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenant_admin_assignments (id, tenant_id, admin_user_id, assigned_at, assigned_by, role) FROM stdin;
\.


--
-- Data for Name: tenant_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenant_settings (id, tenant_id, company_registration_number, company_tax_id, company_bank_account, company_phone, company_email, company_website, company_address, company_city, company_province, company_postal_code, company_country, business_type, industry_category, employee_count, annual_revenue, fiscal_year_start, fiscal_year_end, timezone, currency, language, date_format, number_format, tax_enabled, default_tax_rate, tax_method, tax_number_format, invoice_prefix, invoice_start_number, invoice_logo_position, invoice_terms_conditions, invoice_payment_instructions, email_from_name, email_from_address, email_reply_to, smtp_enabled, smtp_host, smtp_port, smtp_username, smtp_password, smtp_use_tls, send_invoice_notifications, send_order_notifications, send_payment_notifications, send_production_alerts, app_name, support_email, support_phone, privacy_policy_url, terms_conditions_url, status, created_at, updated_at) FROM stdin;
1	1	TKT-001	GST-123456789	\N	+923200000000	info@tkttextiles.com	\N	TKT Complex, Karachi	Karachi	\N	\N	Pakistan	Manufacturing	Textile & Knitting	\N	\N	\N	\N			ur	DD/MM/YYYY	1,234.56	t	18.00	inclusive	GST	INV	1001	left	\N	\N	TKT Textiles	noreply@tkttextiles.com	\N	f	\N	587	\N	\N	t	t	t	t	t	TKT Textiles	\N	\N	\N	\N	active	2026-08-26 19:07:52.672581	2026-08-26 19:07:52.672581
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tenants (id, name, slug, industry, country, timezone, currency, language, status, created_at, updated_at, metadata) FROM stdin;
1	TKT Textiles	tkt-textiles	Textile & Knitting	Pakistan	Asia/Karachi	PKR	ur	active	2026-08-26 19:07:50.377751	2026-08-26 19:07:50.377751	\N
\.


--
-- Data for Name: theme_presets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.theme_presets (id, tenant_id, preset_name, preset_key, description, primary_color, secondary_color, accent_color, text_color, background_color, is_default, created_at, updated_at, navbar_color, navbar_text_color, sidebar_color, sidebar_text_color, accent_hover_color) FROM stdin;
5	1	Default	default	Neutral light workspace with a graphite primary.	#1F2937	#3B82F6	#F59E0B	#111827	#F2F3EE	t	2026-08-26 19:39:32.272545	2026-08-26 19:39:32.272545	#1F2937	#FFFFFF	#1F2937	#E5E7EB	#D97706
1	1	Classic Blue	classic-blue	Trustworthy indigo primary, cool slate chrome.	#2563EB	#3B82F6	#F59E0B	#0F172A	#F8FAFC	t	2026-08-26 19:07:51.887704	2026-08-26 19:39:32.282	#1E40AF	#FFFFFF	#1E293B	#CBD5E1	#D97706
6	1	Modern	modern	Sleek near-black primary with vibrant violet accent.	#111827	#6366F1	#8B5CF6	#111827	#FFFFFF	f	2026-08-26 19:39:32.294687	2026-08-26 19:39:32.294687	#0F172A	#FFFFFF	#0F172A	#94A3B8	#7C3AED
7	1	Dark	dark	Full dark theme for low-light work.	#F8FAFC	#3B82F6	#F59E0B	#F1F5F9	#0F172A	f	2026-08-26 19:39:32.302163	2026-08-26 19:39:32.302163	#020617	#F1F5F9	#020617	#94A3B8	#D97706
3	1	Professional	professional	Steady navy with warm amber accent.	#1E293B	#475569	#F59E0B	#0F172A	#F1F5F9	f	2026-08-26 19:07:51.887704	2026-08-26 19:39:32.309	#1E293B	#FFFFFF	#1E293B	#CBD5E1	#D97706
4	1	Minimal Green	minimal-green	Calm green primary, airy light page.	#16A34A	#22C55E	#F59E0B	#14532D	#F0FDF4	f	2026-08-26 19:07:51.887704	2026-08-26 19:39:32.324	#166534	#FFFFFF	#14532D	#BBF7D0	#D97706
8	1	Sunset	sunset	Warm terracotta primary, soft coral accent.	#EA580C	#F97316	#F43F5E	#431407	#FFF7ED	f	2026-08-26 19:39:32.335598	2026-08-26 19:39:32.335598	#9A3412	#FFFFFF	#7C2D12	#FED7AA	#E11D48
9	1	Ocean	ocean	Deep teal primary, fresh cyan accents.	#0E7490	#06B6D4	#2DD4BF	#083344	#ECFEFF	f	2026-08-26 19:39:32.340377	2026-08-26 19:39:32.340377	#155E75	#FFFFFF	#164E63	#A5F3FC	#14B8A6
10	1	Midnight	midnight	High-contrast slate blue, steel chrome.	#334155	#64748B	#38BDF8	#0F172A	#E2E8F0	f	2026-08-26 19:39:32.344708	2026-08-26 19:39:32.344708	#0F172A	#FFFFFF	#0F172A	#94A3B8	#0EA5E9
11	1	Coral	coral	Bold coral primary, warm sand page.	#E11D48	#F43F5E	#F59E0B	#4C0519	#FFF1F2	f	2026-08-26 19:39:32.348197	2026-08-26 19:39:32.348197	#9F1239	#FFFFFF	#881337	#FECDD3	#D97706
12	1	Lavender	lavender	Soft violet primary, gentle light chrome.	#7C3AED	#8B5CF6	#D946EF	#2E1065	#FAF5FF	f	2026-08-26 19:39:32.388859	2026-08-26 19:39:32.388859	#6D28D9	#FFFFFF	#5B21B6	#DDD6FE	#C026D3
13	1	Forest	forest	Deep evergreen primary, light sage page.	#15803D	#4D7C0F	#A3E635	#052E16	#F7FEE7	f	2026-08-26 19:39:32.394727	2026-08-26 19:39:32.394727	#14532D	#FFFFFF	#14532D	#BBF7D0	#65A30D
14	1	Slate	slate	Minimal grey-graphite, neutral professional.	#334155	#64748B	#F59E0B	#0F172A	#F1F5F9	f	2026-08-26 19:39:32.399878	2026-08-26 19:39:32.399878	#1E293B	#E2E8F0	#334155	#CBD5E1	#D97706
\.


--
-- Data for Name: transaction_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_detail (id, header_id, quantity, net_wt, machine_id, employee_id, yarn_type_id, yarn_count_id, yarn_brand_id, uom_id, tenant_id) FROM stdin;
674	202	1.000	2100.900	29	18	20	28	1	1	1
819	256	5.000	155.000	18	7	20	23	22	1	1
868	286	1.000	176.450	29	18	22	2	15	1	1
713	215	60.000	1564.400	\N	\N	20	23	3	1	1
502	154	5.000	149.250	23	7	20	23	1	1	1
503	154	8.000	198.600	23	2	20	23	1	1	1
504	154	5.000	130.050	24	1	20	23	1	1	1
719	220	1.000	5.200	\N	\N	22	13	3	1	1
720	220	1.000	24.800	\N	\N	20	23	3	1	1
505	154	7.000	194.700	24	9	20	23	1	1	1
715	217	10.000	270.650	\N	\N	20	23	3	1	1
721	221	1.000	400.950	\N	\N	\N	2	2	1	1
722	222	13.000	318.500	\N	\N	\N	19	18	1	1
496	153	6.000	179.750	25	1	20	28	1	1	1
497	153	8.000	236.350	25	9	20	28	1	1	1
498	153	9.000	259.400	14	8	20	28	1	1	1
499	153	10.000	259.750	14	2	20	28	1	1	1
500	153	9.000	256.400	15	8	20	28	1	1	1
501	153	10.000	265.750	15	2	20	28	1	1	1
506	155	7.000	175.000	25	1	20	42	1	1	1
507	155	6.000	158.600	25	9	20	42	1	1	1
508	155	9.000	281.750	14	8	20	42	1	1	1
509	155	9.000	269.050	14	9	20	42	1	1	1
510	155	9.000	266.150	15	8	20	42	1	1	1
511	155	10.000	276.350	15	2	20	42	1	1	1
518	157	14.000	635.040	\N	\N	20	2	2	1	1
520	159	25.000	1134.000	\N	\N	20	2	2	1	1
521	159	28.000	1270.080	\N	\N	20	1	20	1	1
593	146	7.000	184.350	23	7	20	23	2	1	1
527	163	37.000	990.450	\N	\N	20	23	1	1	1
594	146	7.000	190.000	23	2	20	23	2	1	1
595	146	2.000	53.450	24	1	20	23	2	1	1
653	196	23.000	828.000	\N	\N	20	41	18	1	1
557	151	34.000	1542.240	\N	\N	\N	1	1	1	1
540	136	4.000	102.700	18	7	20	26	3	1	1
541	136	1.000	23.800	18	2	20	26	3	1	1
542	136	8.000	199.350	21	1	24	39	3	1	1
543	136	7.000	209.700	21	9	24	39	3	1	1
558	151	12.000	432.000	\N	\N	\N	41	18	1	1
547	166	6.000	153.900	23	7	20	23	1	1	1
548	166	8.000	206.900	23	2	20	23	1	1	1
549	166	5.000	135.550	24	1	20	23	1	1	1
550	166	6.000	175.450	24	9	20	23	1	1	1
596	146	6.000	171.500	24	9	20	23	2	1	1
829	261	10.000	249.600	\N	\N	23	39	3	1	1
835	267	10.000	251.800	\N	\N	23	39	3	1	1
559	151	50.000	2268.000	\N	\N	\N	17	1	1	1
616	168	54.000	2442.290	\N	\N	\N	1	1	\N	1
577	174	58.000	1721.300	\N	\N	20	28	1	1	1
578	174	59.000	1717.850	\N	\N	20	28	1	1	1
580	176	50.000	1422.800	\N	\N	20	28	1	1	1
581	176	59.000	1663.250	\N	\N	20	28	1	1	1
583	178	25.000	672.600	\N	\N	20	23	2	1	1
586	180	25.000	671.800	\N	\N	20	23	2	1	1
617	168	33.000	1478.100	\N	\N	\N	17	1	\N	1
608	181	1.000	2675.056	\N	\N	20	23	2	\N	1
611	164	1.000	7436.424	\N	\N	20	29	1	1	1
613	183	1.000	706.962	\N	\N	20	29	3	\N	1
615	185	1.000	50.764	\N	\N	20	37	1	1	1
618	186	6.000	167.050	22	2	20	23	2	1	1
619	186	6.000	155.300	23	7	20	23	2	1	1
620	186	8.000	213.350	23	2	20	23	2	1	1
621	186	5.000	125.100	24	1	20	23	2	1	1
622	186	8.000	208.350	24	9	20	23	2	1	1
628	188	8.000	234.900	25	1	20	42	1	1	1
629	188	9.000	241.450	25	9	20	42	1	1	1
630	188	10.000	278.300	14	8	20	42	1	1	1
631	188	10.000	276.100	14	9	20	42	1	1	1
632	188	9.000	261.850	15	8	20	42	1	1	1
633	188	10.000	277.000	15	2	20	42	1	1	1
639	190	42.000	1116.150	\N	\N	20	23	2	1	1
645	182	1.000	4466.360	\N	\N	20	26	1	1	1
654	139	6.000	161.050	22	8	20	23	2	1	1
655	139	5.000	153.250	22	9	20	23	2	1	1
656	139	7.000	167.900	23	7	20	23	2	1	1
657	139	8.000	194.200	23	2	20	23	2	1	1
661	197	7.000	143.500	22	7	20	23	2	1	1
662	197	3.000	91.500	22	2	20	23	2	1	1
663	197	4.000	108.200	24	1	20	23	2	1	1
672	200	8.000	176.450	\N	\N	22	17	1	1	1
568	170	20.000	498.150	\N	\N	20	23	2	1	1
726	224	49.000	1388.750	\N	\N	20	42	1	1	1
727	224	51.000	1429.200	\N	\N	20	42	1	1	1
867	285	1.000	3.350	29	18	20	23	13	1	1
641	191	36.000	1011.850	\N	\N	20	42	1	1	1
642	191	49.000	1391.000	\N	\N	20	42	1	1	1
673	201	1.000	694.750	29	18	20	23	2	1	1
484	150	6.000	171.050	25	1	20	28	1	1	1
485	150	7.000	194.200	25	9	20	28	1	1	1
486	150	9.000	252.800	14	8	20	28	1	1	1
487	150	8.000	266.050	14	9	20	28	1	1	1
488	150	7.000	210.150	15	8	20	28	1	1	1
489	150	9.000	275.650	15	2	20	28	1	1	1
643	191	27.000	759.350	\N	\N	20	42	1	1	1
698	209	47.000	1137.500	\N	\N	20	23	2	1	1
869	287	1.000	25.350	29	18	20	23	2	1	1
859	280	1.000	10.750	29	18	24	39	3	1	1
870	288	15.000	680.400	\N	\N	20	1	1	1	1
871	288	33.000	1496.880	\N	\N	20	2	1	1	1
519	158	100.000	4536.000	\N	\N	24	13	3	1	1
526	162	47.000	1233.900	\N	\N	20	23	2	1	1
528	132	6.000	162.300	25	1	20	29	1	1	1
529	132	7.000	206.400	25	3	20	29	1	1	1
530	132	3.000	88.300	14	8	20	29	1	1	1
531	132	9.000	251.200	14	9	20	29	1	1	1
532	132	6.000	156.150	15	8	20	29	1	1	1
533	132	4.000	116.150	15	2	20	29	1	1	1
538	140	6.000	148.450	24	1	20	23	1	1	1
539	140	7.000	202.400	24	3	20	23	1	1	1
429	133	7.000	201.300	25	8	20	29	1	1	1
430	133	7.000	211.350	25	9	20	29	1	1	1
431	133	9.000	266.800	14	8	20	29	1	1	1
432	133	8.000	243.450	14	9	20	29	1	1	1
433	133	6.000	174.650	15	7	20	29	1	1	1
434	133	2.000	56.250	15	2	20	29	1	1	1
435	134	6.000	167.450	25	1	20	29	1	1	1
436	134	7.000	209.500	25	9	20	29	1	1	1
437	134	9.000	256.700	14	8	20	29	1	1	1
438	134	8.000	252.600	14	9	20	29	1	1	1
439	134	5.000	157.150	15	8	20	29	1	1	1
440	134	8.000	223.800	15	2	20	29	1	1	1
441	135	7.000	148.400	18	7	20	26	19	1	1
442	135	4.000	104.600	18	2	20	26	19	1	1
447	137	2.000	39.700	18	2	20	29	1	1	1
448	138	6.000	174.900	21	1	24	39	3	1	1
449	138	8.000	230.400	21	9	24	39	3	1	1
456	141	6.000	150.750	22	8	20	23	2	1	1
457	141	4.000	108.150	22	2	20	23	2	1	1
458	141	7.000	186.200	23	7	20	23	2	1	1
459	141	8.000	184.950	23	2	20	23	2	1	1
460	142	6.000	167.550	24	1	20	23	1	1	1
461	142	3.000	91.150	24	9	20	23	1	1	1
466	144	3.000	89.850	22	8	20	23	2	1	1
467	144	6.000	162.350	23	7	20	23	2	1	1
468	144	8.000	199.600	23	2	20	23	2	1	1
551	167	6.000	177.600	25	1	20	42	1	1	1
552	167	9.000	244.500	25	9	20	42	1	1	1
553	167	8.000	217.250	14	8	20	42	1	1	1
554	167	10.000	281.400	14	9	20	42	1	1	1
555	167	7.000	193.950	15	7	20	42	1	1	1
556	167	10.000	280.200	15	2	20	42	1	1	1
576	173	18.000	439.850	\N	\N	20	26	19	1	1
579	175	15.000	384.800	\N	\N	20	23	2	1	1
582	177	22.000	599.300	\N	\N	20	23	2	1	1
584	179	52.000	1514.900	\N	\N	20	42	1	1	1
585	179	52.000	1518.400	\N	\N	20	42	1	1	1
612	165	1.000	1908.837	\N	\N	20	23	3	1	1
614	184	1.000	455.460	\N	\N	20	29	1	1	1
623	187	6.000	173.350	25	1	20	42	1	1	1
624	187	10.000	285.950	14	1	20	42	1	1	1
625	187	3.000	86.600	14	9	20	42	1	1	1
626	187	9.000	262.550	15	7	20	42	1	1	1
627	187	9.000	254.400	15	9	20	42	1	1	1
634	189	9.000	189.300	22	7	20	23	2	1	1
635	189	7.000	173.250	22	9	20	23	2	1	1
636	189	8.000	197.500	23	7	20	23	2	1	1
637	189	8.000	227.150	24	1	20	23	2	1	1
638	189	8.000	212.000	24	9	20	23	2	1	1
644	192	108.000	4898.880	\N	\N	20	2	3	1	1
658	160	11.000	498.960	\N	\N	20	2	2	1	1
659	160	12.000	432.000	\N	\N	20	19	18	1	1
660	160	28.000	1270.080	\N	\N	20	1	15	1	1
664	198	5.000	137.800	25	1	20	28	1	1	1
665	198	8.000	232.250	25	9	20	28	1	1	1
666	198	6.000	175.050	14	1	20	28	1	1	1
667	198	10.000	271.300	14	9	20	28	1	1	1
668	198	9.000	234.850	15	7	20	28	1	1	1
669	198	9.000	238.100	15	2	20	28	1	1	1
675	203	8.000	228.900	25	1	20	28	1	1	1
676	203	9.000	241.800	25	9	20	28	1	1	1
677	203	10.000	284.750	14	8	20	28	1	1	1
678	203	11.000	300.500	14	9	20	28	1	1	1
679	203	10.000	272.000	15	8	20	28	1	1	1
680	203	10.000	258.350	15	2	20	28	1	1	1
683	205	1.000	16.750	22	7	20	23	1	1	1
820	257	4.000	73.900	21	8	23	37	22	1	1
821	257	6.000	142.250	21	9	23	37	22	1	1
569	171	2.000	39.700	\N	\N	20	29	1	1	1
525	161	27.000	694.750	\N	\N	20	23	2	1	1
590	147	6.000	145.850	23	7	20	23	2	1	1
723	223	24.000	777.650	\N	\N	\N	20	18	1	1
724	223	1.000	27.250	\N	\N	\N	2	1	1	1
725	223	1.000	4.550	\N	\N	\N	1	1	1	1
591	147	8.000	212.750	23	2	20	23	2	1	1
692	208	8.000	224.000	25	1	20	42	1	1	1
693	208	7.000	183.200	25	9	20	42	1	1	1
694	208	9.000	276.350	14	8	20	42	1	1	1
695	208	5.000	137.650	14	9	20	42	1	1	1
696	208	9.000	265.450	15	8	20	42	1	1	1
697	208	8.000	229.950	15	2	20	42	1	1	1
711	214	7.000	204.900	15	8	20	42	1	1	1
712	214	7.000	192.550	15	2	20	42	1	1	1
806	251	7.000	154.000	21	8	23	39	3	1	1
807	251	7.000	170.550	21	9	23	39	3	1	1
872	289	3.000	79.650	25	1	20	23	14	1	1
873	289	9.000	259.500	25	9	20	23	14	1	1
560	152	30.000	1360.800	\N	\N	20	1	1	1	1
561	152	17.000	612.000	\N	\N	20	41	18	1	1
562	152	29.000	1278.310	\N	\N	20	17	1	1	1
649	194	121.000	3993.000	\N	\N	20	19	18	1	1
651	195	31.000	1023.000	\N	\N	2	19	18	1	1
652	195	45.000	1485.000	\N	\N	2	19	18	1	1
567	169	127.000	5760.720	\N	\N	20	1	1	1	1
716	218	56.000	1549.050	\N	\N	20	42	1	1	1
717	218	50.000	1377.550	\N	\N	20	42	1	1	1
728	225	1.000	7.600	\N	\N	\N	17	1	1	1
729	225	1.000	5.150	\N	\N	\N	17	1	1	1
730	225	1.000	32.000	\N	\N	\N	41	18	1	1
731	225	5.000	180.000	\N	\N	\N	41	18	1	1
742	227	8.000	228.800	25	1	20	23	3	1	1
743	227	9.000	244.000	25	9	20	23	3	1	1
744	227	8.000	220.800	14	8	20	23	3	1	1
745	227	9.000	236.800	14	2	20	23	3	1	1
746	227	7.000	160.800	18	7	20	23	3	1	1
747	227	7.000	206.750	18	2	20	23	3	1	1
748	227	6.000	149.400	21	1	23	39	3	1	1
749	227	7.000	160.600	21	9	23	39	3	1	1
702	212	1.000	19.100	25	1	20	23	3	1	1
703	212	9.000	249.050	25	9	20	23	3	1	1
704	212	1.000	27.900	14	8	20	23	3	1	1
705	212	9.000	239.050	14	9	20	23	3	1	1
706	212	2.000	52.400	18	7	20	23	3	1	1
707	212	7.000	203.600	18	2	20	23	3	1	1
708	212	1.000	20.650	20	7	20	23	3	1	1
709	213	8.000	213.800	19	7	22	13	3	1	1
710	213	8.000	243.450	19	2	22	13	3	1	1
699	210	6.000	159.400	18	7	20	23	3	1	1
700	211	4.000	85.950	19	7	22	13	3	1	1
701	211	10.000	269.700	19	2	22	13	3	1	1
686	204	5.000	130.100	18	7	20	26	1	1	1
687	204	5.000	142.000	18	2	20	26	1	1	1
688	204	4.000	116.650	19	7	22	13	1	1	1
689	204	7.000	211.250	19	2	22	13	1	1	1
690	204	2.000	33.650	21	1	24	13	1	1	1
691	204	3.000	83.350	21	9	24	13	1	1	1
481	148	1.000	15.100	18	7	20	26	1	1	1
750	228	9.000	243.150	25	1	20	23	1	1	1
751	228	9.000	236.800	25	9	20	23	1	1	1
752	228	9.000	231.800	14	8	20	23	1	1	1
753	228	9.000	234.850	14	2	20	23	1	1	1
754	228	8.000	195.050	18	7	20	23	1	1	1
755	228	6.000	176.200	18	2	20	23	1	1	1
756	229	8.000	167.100	21	1	23	39	3	1	1
757	229	7.000	160.800	21	9	23	39	3	1	1
758	230	9.000	246.800	25	1	20	23	3	1	1
759	230	9.000	239.700	25	9	20	23	3	1	1
760	230	9.000	233.250	14	8	20	23	3	1	1
761	230	9.000	231.550	14	2	20	23	3	1	1
762	230	5.000	123.300	15	8	20	23	3	1	1
763	230	7.000	189.000	18	7	20	23	3	1	1
764	230	7.000	206.950	18	2	20	23	3	1	1
765	231	7.000	163.650	21	1	23	28	3	1	1
766	231	7.000	173.550	21	9	23	28	3	1	1
767	232	2.000	38.850	15	8	20	23	3	1	1
768	233	9.000	243.300	\N	\N	20	23	1	1	1
769	234	1.000	10.000	\N	\N	22	13	3	1	1
770	235	2.000	42.100	\N	\N	23	39	3	1	1
771	236	9.000	250.300	25	1	20	23	14	1	1
772	236	9.000	240.350	25	9	20	23	14	1	1
773	236	9.000	238.450	14	8	20	23	14	1	1
774	236	9.000	227.350	14	9	20	23	14	1	1
775	236	2.000	37.250	18	7	20	23	14	1	1
776	237	8.000	169.650	21	1	23	39	3	1	1
777	237	7.000	169.100	21	9	23	39	3	1	1
778	238	11.000	293.450	15	8	20	31	3	2	1
779	238	9.000	251.900	15	2	20	31	3	2	1
780	238	1.000	13.400	18	7	20	31	3	2	1
781	238	7.000	197.050	18	2	20	31	3	2	1
782	239	14.000	635.040	\N	\N	20	13	4	\N	1
783	240	8.000	288.000	\N	\N	20	19	18	1	1
784	241	25.000	1134.000	\N	\N	20	1	15	1	1
785	241	3.000	108.000	\N	\N	20	19	18	1	1
786	242	9.000	243.100	25	8	20	23	1	1	1
787	242	9.000	241.900	25	9	20	23	1	1	1
788	242	9.000	234.000	14	8	20	23	1	1	1
789	242	9.000	231.050	14	9	20	23	1	1	1
790	243	7.000	147.850	21	1	23	39	3	1	1
791	243	7.000	173.600	21	9	23	39	3	1	1
792	244	7.000	194.550	15	7	20	31	15	1	1
793	244	9.000	254.850	15	2	20	31	15	1	1
794	244	6.000	145.450	18	7	20	31	15	1	1
795	244	9.000	247.150	18	2	20	31	15	1	1
796	245	26.000	1179.360	\N	\N	20	13	13	1	1
797	245	19.000	861.840	\N	\N	20	1	15	1	1
826	259	6.000	134.800	21	1	23	13	15	1	1
799	247	2.000	49.850	\N	\N	23	39	3	1	1
800	248	19.000	506.750	\N	\N	20	23	3	1	1
827	259	5.000	133.700	21	9	23	13	15	1	1
802	250	8.000	217.600	25	1	20	23	1	1	1
803	250	9.000	236.850	25	9	20	23	1	1	1
804	250	8.000	212.800	14	1	20	23	1	1	1
805	250	8.000	199.300	14	2	20	23	1	1	1
808	252	8.000	202.800	15	7	20	31	3	1	1
809	252	9.000	236.700	18	7	20	31	3	1	1
810	252	9.000	258.500	18	2	20	31	3	1	1
811	253	2.000	40.000	\N	\N	23	22	18	1	1
812	254	1.000	14.720	\N	\N	23	22	18	1	1
670	199	6.000	150.600	\N	\N	24	39	3	1	1
570	172	1.000	5.300	\N	\N	22	13	3	1	1
571	172	1.000	9.500	\N	\N	24	39	3	1	1
572	172	19.000	561.250	\N	\N	24	39	3	1	1
573	172	14.000	401.700	\N	\N	20	26	13	1	1
574	172	1.000	11.800	\N	\N	22	13	3	1	1
575	172	4.000	100.050	\N	\N	24	39	3	1	1
714	216	26.000	718.900	\N	\N	24	39	3	1	1
718	219	5.000	117.000	\N	\N	24	39	3	1	1
874	289	7.000	194.650	14	8	20	23	14	1	1
875	289	9.000	252.600	14	2	20	23	14	1	1
818	255	2.000	55.750	21	9	23	39	3	1	1
822	258	8.000	207.350	25	7	20	23	1	1	1
823	258	9.000	227.900	25	2	20	23	1	1	1
824	258	8.000	219.300	14	8	20	23	1	1	1
825	258	8.000	213.800	14	2	20	23	1	1	1
876	290	25.000	1134.000	\N	\N	20	2	2	1	1
830	262	4.000	111.650	\N	\N	20	23	3	1	1
831	263	60.000	1645.950	21	9	20	23	1	1	1
832	264	4.000	110.450	14	8	20	23	1	1	1
833	265	6.000	110.600	21	1	23	13	15	1	1
834	266	40.000	1108.800	\N	\N	20	23	1	1	1
836	268	24.000	642.700	\N	\N	20	23	3	1	1
837	269	1.000	19.300	\N	\N	23	22	18	1	1
838	269	1.000	27.400	\N	\N	23	13	18	1	1
839	270	2.000	90.720	\N	\N	23	28	3	1	1
877	290	12.000	432.000	\N	\N	20	19	18	1	1
798	246	1.000	10.750	\N	\N	24	39	3	1	1
840	271	5.000	95.750	21	1	23	39	3	1	1
841	272	34.000	913.400	\N	\N	20	31	21	1	1
842	272	9.000	194.150	\N	\N	23	37	21	1	1
843	272	28.000	789.600	\N	\N	20	31	22	1	1
844	272	9.000	204.200	\N	\N	23	37	22	1	1
845	272	30.000	786.650	\N	\N	20	31	22	1	1
846	272	9.000	196.900	\N	\N	23	37	22	1	1
847	273	15.000	367.850	\N	\N	20	23	3	1	1
848	273	28.000	733.000	\N	\N	20	23	3	1	1
849	273	8.000	162.550	\N	\N	23	39	3	1	1
850	274	2.000	82.300	\N	\N	\N	13	3	1	1
851	275	11.000	498.960	\N	\N	\N	2	1	1	1
852	276	12.000	432.000	\N	\N	\N	19	18	1	1
853	277	3.000	66.800	19	7	22	13	3	1	1
854	278	2.000	42.200	25	1	20	23	3	1	1
855	278	4.000	114.550	25	9	20	23	3	1	1
856	278	2.000	44.100	14	8	20	23	3	1	1
857	278	8.000	225.550	14	2	20	23	3	1	1
462	143	5.000	119.150	18	7	20	26	3	1	1
463	143	5.000	127.000	18	2	20	26	3	1	1
464	143	7.000	192.450	21	1	23	39	3	1	1
465	143	8.000	218.350	21	9	23	39	3	1	1
878	290	28.000	1270.080	\N	\N	20	1	20	1	1
801	249	3.000	72.900	\N	\N	23	39	3	1	1
828	260	15.000	425.850	\N	\N	22	13	3	1	1
732	226	7.000	195.300	25	1	20	23	3	1	1
733	226	9.000	247.850	25	9	20	23	3	1	1
734	226	7.000	190.950	14	8	20	23	3	1	1
735	226	9.000	244.550	14	9	20	23	3	1	1
736	226	2.000	54.600	15	8	20	23	3	1	1
737	226	8.000	189.950	15	2	20	23	3	1	1
738	226	6.000	176.050	18	7	20	23	3	1	1
739	226	7.000	202.800	18	2	20	23	3	1	1
740	226	4.000	103.400	19	7	22	13	3	1	1
741	226	6.000	150.650	21	9	23	39	3	1	1
862	283	7.000	194.600	25	1	20	23	3	1	1
863	283	9.000	235.100	25	2	20	23	3	1	1
864	283	7.000	198.500	14	1	20	23	3	1	1
865	283	5.000	235.550	14	2	20	23	3	1	1
860	281	1.000	91.600	29	18	20	26	2	1	1
866	284	1.000	8.450	29	18	20	23	1	1	1
861	282	2.000	39.800	29	18	20	23	3	1	1
858	279	1.000	5.800	29	18	23	39	3	1	1
646	193	1.000	309.350	29	18	24	39	3	1	1
647	193	1.000	1809.200	29	18	20	26	3	1	1
648	193	1.000	17.100	29	18	22	13	3	1	1
684	206	1.000	372.450	29	18	20	23	1	1	1
685	207	1.000	183.500	29	18	20	32	3	1	1
\.


--
-- Data for Name: transaction_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_header (id, transaction_type_id, date, doc_number, job_id, party_id, location_id, fabric_type_id, sl, gsm, reference, tenant_id) FROM stdin;
153	5	2026-08-06	20260806	15	14	18	13	\N	\N	\N	1
155	5	2026-08-05	20260805	15	14	\N	13	\N	\N	\N	1
157	3	2026-08-03	169827	13	13	\N	13	\N	\N	\N	1
159	3	2026-08-06	169950	13	13	\N	13	\N	\N	\N	1
163	6	2026-08-03	3737	16	15	\N	13	\N	\N	\N	1
167	5	2026-08-07	20260807	15	14	\N	13	\N	\N	\N	1
234	6	2026-08-18	3774	14	16	\N	1	\N	\N	Style#158374	1
173	6	2026-08-04	3743	17	17	\N	13	\N	\N	\N	1
175	6	2026-08-05	3746	13	13	\N	13	\N	\N	\N	1
177	6	2026-08-06	3749	13	13	\N	13	\N	\N	\N	1
179	6	2026-08-07	3751,3752	15	14	\N	13	\N	\N	\N	1
236	5	2026-08-19	20260820	14	16	\N	13	\N	\N	Style#158374	1
238	5	2026-08-19	20260819	17	17	\N	13	\N	\N	\N	1
241	3	2026-08-18	1485	17	17	\N	13	\N	\N	1485	1
244	5	2026-08-20	20260820	17	17	\N	13	\N	\N	\N	1
181	3	2026-07-31	August-26 >----> Opening	\N	13	\N	13	\N	\N	August-26 >----> Opening	1
165	3	2026-07-31	August-26 >----> Opening	16	15	\N	13	\N	\N	August-26 >----> Opening	1
183	3	2026-07-31	August-26 >----> Opening	\N	17	\N	13	\N	\N	August-26 >----> Opening	1
185	3	2026-07-31	August-26 >----> Opening	\N	19	\N	13	\N	\N	August-26 >----> Opening	1
187	5	2026-08-09	20260809	15	14	\N	13	\N	\N	\N	1
189	5	2026-08-09	20260809	13	13	\N	13	\N	\N	\N	1
248	6	2026-08-20	3778	14	16	\N	13	\N	\N	Style#158374	1
197	5	2026-08-10	20260810	13	13	\N	13	\N	\N	\N	1
203	5	2026-08-11	20260811	15	14	\N	13	\N	\N	\N	1
205	5	2026-08-11	20260811	13	13	\N	13	\N	\N	\N	1
214	5	2026-08-13	4700015016	15	14	\N	13	940+640+384	340	\N	1
252	5	2026-08-21	202608021	17	17	\N	13	\N	\N	\N	1
199	6	2026-08-10	3758	14	16	\N	4	1160	\N	\N	1
220	6	2026-08-13	3770	14	16	\N	13	1000+740+380	240	3770	1
171	6	2026-08-04	3739	\N	20	\N	13	\N	\N	\N	1
191	6	2026-08-10	3755,3756,3757	15	14	\N	13	940+640+384	\N	3755,3756,3757	1
209	6	2026-08-11	3759	13	13	\N	13	960+720+370	\N	3759 	1
161	6	2026-08-01	3735	13	13	\N	13	960+720+370	\N	3735	1
222	4	2026-08-11	3764	13	13	\N	\N	\N	\N	3764	1
216	6	2026-08-11	3761	14	16	\N	4	1160	245	3761	1
151	3	2026-08-05	4700015011	\N	14	\N	13	\N	\N	4700015011	1
195	4	2026-08-01	20260801-1	14	16	\N	\N	\N	\N	20260801-1	1
255	5	2026-08-22	20260822	14	16	\N	16	\N	\N	STYLE#158374	1
258	5	2026-08-23	20260823	14	16	\N	13	\N	\N	STYLE#158374	1
286	5	2026-07-31	August-26 >----> Opening	\N	20	\N	1	620	115	August-26 >----> Opening	1
169	3	2026-08-04	852	14	16	\N	13	\N	\N	\N	1
201	5	2026-07-31	August-26 >----> Opening	13	13	\N	13	\N	\N	August-26 >----> Opening	1
218	6	2026-08-13	3767,3768	15	14	\N	13	940+640+384	340	3767,3768	1
224	6	2026-08-17	3771,3772	15	14	\N	13	940+640+384	240	3771,3772	1
227	5	2026-08-16	20260816	14	16	\N	13	\N	\N	20260816	1
212	5	2026-08-13	20260813	14	16	\N	13	1000+710+380	240	20260813	1
210	5	2026-08-12	20260812	14	16	\N	13	1000+710+380	240	20260812	1
229	5	2026-08-17	20260817	14	16	\N	16	\N	\N	\N	1
232	5	2026-08-18	20260818	17	17	\N	13	\N	\N	\N	1
263	6	2026-08-22	3780	14	16	\N	13	1000+700+385	\N	STYLE#158374	1
265	5	2026-08-24	20260824	17	17	\N	16	\N	\N	\N	1
268	6	2026-08-24	3784	\N	16	\N	13	1000+700+385	\N	STYLE#158374	1
270	4	2026-08-24	3782	14	16	\N	16	\N	\N	Yarn Return	1
147	5	2026-08-04	20260804	13	13	\N	13	\N	\N	\N	1
246	6	2026-08-20	3776	14	16	\N	4	820	\N	\N	1
271	5	2026-08-25	20260825	14	16	\N	16	\N	\N	Style#158374	1
273	6	2026-08-27	3790,3791	14	16	\N	13	1000+700+385	250	3790,3791	1
275	3	2026-08-25	762	16	15	\N	13	\N	\N	762	1
277	5	2026-08-27	4700015018	14	16	\N	1	820	145	762	1
249	6	2026-08-20	3778	14	16	\N	16	820	\N	Style#158374	1
226	5	2026-08-15	20260815	14	16	\N	13	\N	\N	20260815	1
284	5	2026-08-02	4700015024	16	15	\N	13	1020+740+410	240	20260817	1
282	5	2026-08-04	4700015022	14	16	\N	13	1060+730+410	210	20260817	1
279	5	2026-08-10	4700015020	14	16	\N	16	820	245	762	1
193	5	2026-07-31	August-26 >----> Opening	\N	16	\N	13	\N	\N	August-26 >----> Opening	1
207	5	2026-07-31	August-26 >----> Opening	17	17	\N	13	\N	\N	August-26 >----> Opening	1
259	5	2026-08-23	20260823	17	17	\N	16	\N	\N	\N	1
251	5	2026-08-21	202608021	14	16	\N	16	\N	\N	Style#158374	1
288	3	2026-08-28	GP2608-284,GP2608-288	16	15	\N	13	\N	\N	766	1
290	3	2026-08-29	170468	13	13	\N	13	\N	\N	CUS-0090	1
150	5	2026-08-04	20260804	15	14	\N	13	\N	\N	\N	1
158	3	2026-08-04	0268	14	16	\N	4	\N	\N	\N	1
162	6	2026-08-03	3736	13	13	\N	13	960+720+370	\N	\N	1
132	5	2026-08-01	20260801-01	15	14	13	13	\N	\N	20260801-01	1
269	4	2026-08-20	3775	18	19	\N	16	\N	\N	Yarn Return	1
140	5	2026-08-01	20260801-01	16	15	\N	13	\N	\N	20260801-01	1
136	5	2026-08-02	20260802-01	14	16	\N	13	\N	\N	20260802-01	1
272	6	2026-08-25	3785,3786,3787	17	17	\N	13	1020+680+415	330	3785,3786,3787	1
166	5	2026-08-07	20260807	13	13	\N	13	960+720+370	\N	\N	1
194	3	2026-08-01	20260801-1	\N	16	\N	13	\N	\N	20260801-1	1
133	5	2026-08-02	20260802-01	15	14	\N	13	\N	\N	20260802-01	1
134	5	2026-08-03	20260803-01	15	14	\N	13	\N	\N	20260803-01	1
135	5	2026-08-01	20260801-01	17	17	\N	13	\N	\N	20260801-01	1
137	5	2026-08-01	20260801-01	\N	20	\N	13	\N	\N	20260802-01	1
138	5	2026-08-01	20260801-01	14	16	\N	4	\N	\N	20260801-01	1
141	5	2026-08-02	20260802-01	13	13	\N	13	\N	\N	20260802-01	1
142	5	2026-08-02	20260802-01	16	15	\N	13	\N	\N	20260802-01	1
144	5	2026-08-03	20260803-01	13	13	\N	13	\N	\N	20260803-01	1
257	5	2026-08-22	20260822	17	17	\N	16	\N	\N	\N	1
174	6	2026-08-05	3744,3745	15	14	\N	13	\N	\N	\N	1
176	6	2026-08-06	3747,3748	15	14	\N	13	\N	\N	\N	1
178	6	2026-08-07	3750	13	13	\N	13	\N	\N	\N	1
180	6	2026-08-08	3753	13	13	\N	13	\N	\N	\N	1
285	5	2026-08-01	4700015025	17	17	\N	13	1050+700+405	250	20260817	1
170	6	2026-08-04	3738	13	13	\N	13	\N	\N	\N	1
225	4	2026-08-17	3773	15	14	\N	13	\N	\N	3773	1
213	5	2026-08-13	20260813	14	16	\N	1	820	140	20260813	1
211	5	2026-08-12	20260812	14	16	\N	1	820	140	20260812	1
204	5	2026-08-11	20260811-1	14	16	\N	13	\N	\N	20260811-1	1
148	5	2026-08-04	20260804	14	16	\N	13	\N	\N	20260804	1
164	3	2026-07-31	August-26 >----> Opening	\N	14	\N	13	\N	\N	August-26 >----> Opening	1
184	3	2026-07-31	August-26 >----> Opening	\N	20	\N	13	\N	\N	August-26 >----> Opening	1
228	5	2026-08-17	4700015017	14	16	\N	13	\N	\N	\N	1
186	5	2026-08-08	20260808	13	13	\N	13	\N	\N	\N	1
188	5	2026-08-08	20260808	15	14	\N	13	\N	\N	\N	1
190	6	2026-08-10	3754	13	13	\N	13	\N	\N	\N	1
192	3	2026-08-10	0320	14	16	\N	13	\N	\N	\N	1
182	3	2026-07-31	August-26 >----> Opening	\N	16	\N	4	\N	\N	August-26 >----> Opening	1
139	5	2026-08-01	20260801-01	13	13	\N	13	\N	\N	20260801-01	1
160	3	2026-08-01	169808	13	13	\N	13	\N	\N	\N	1
198	5	2026-08-10	20260810	15	14	\N	13	\N	\N	\N	1
200	6	2026-08-01	3734	\N	20	\N	1	\N	\N	3734	1
274	3	2026-08-25	3801	14	16	\N	13	\N	\N	3801	1
230	5	2026-08-18	20260818	14	16	\N	13	\N	\N	\N	1
208	5	2026-08-12	20260812	15	14	\N	13	940+640+384	340	\N	1
276	3	2026-08-27	762	16	15	\N	13	\N	\N	762	1
278	5	2026-08-27	4700015019	16	15	\N	13	1020+740+410	235	762	1
215	6	2026-08-11	3760	14	16	\N	13	1060+730+410	200	3760	1
143	5	2026-08-03	20260803-01	14	16	\N	13	\N	\N	20260803-01	1
217	6	2026-08-11	3762	14	16	\N	13	1060+730+410	200	3762	1
221	4	2026-08-11	3763	13	13	\N	\N	\N	\N	3763	1
223	4	2026-08-15	3766	15	14	\N	\N	\N	\N	3766	1
196	3	2026-08-05	4700015011	15	14	18	13	\N	\N	4700015011	1
152	3	2026-08-03	4700014961	15	14	18	13	\N	\N	4700014961	1
168	3	2026-08-06	4700015011	15	14	\N	13	\N	\N	4700015011	1
231	5	2026-08-18	20260818	14	16	\N	16	\N	\N	\N	1
233	6	2026-08-18	3774	14	16	\N	13	1000+700+385	368	Style#158374	1
235	6	2026-08-18	3774	14	16	\N	16	820	\N	Style#158374	1
237	5	2026-08-19	20260819	14	16	\N	16	\N	\N	Style#158374	1
239	3	2026-08-18	1483	17	17	\N	13	\N	\N	1483	1
240	3	2026-08-18	1484	17	17	\N	13	\N	\N	1484	1
242	5	2026-08-20	20260820	14	16	\N	13	\N	\N	\N	1
243	5	2026-08-20	20260820	14	16	\N	16	\N	\N	\N	1
245	3	2026-08-20	1489	17	17	\N	13	\N	\N	\N	1
247	6	2026-08-20	3777	14	16	\N	13	820	\N	3777	1
250	5	2026-08-21	20260821	14	16	\N	13	\N	\N	Style#158374	1
253	3	2026-08-21	1492	17	17	\N	16	\N	\N	1492	1
254	3	2026-08-21	1493	17	17	\N	16	\N	\N	1493	1
172	6	2026-08-04	3740,3741,3742	\N	16	\N	13	\N	\N	\N	1
219	6	2026-08-13	3769	14	16	\N	4	1160	240	3769	1
262	6	2026-08-22	3781	14	16	\N	13	1000+700+385	\N	3781	1
264	5	2026-08-24	20260824	14	16	\N	13	\N	\N	STYLE#158374	1
266	6	2026-08-24	3783	14	16	\N	13	\N	\N	STYLE#158374	1
260	6	2026-08-22	3779	14	16	\N	1	820	145	STYLE#158374	1
206	5	2026-07-31	August-26 >----> Opening	16	15	\N	13	\N	\N	August-26 >----> Opening	1
202	5	2026-07-31	August-26 >----> Opening	15	14	\N	13	\N	\N	August-26 >----> Opening	1
283	5	2026-08-22	4700015023	14	16	\N	13	1000+700+385	250	20260817	1
281	5	2026-08-17	20260817	\N	14	\N	13	\N	\N	20260817	1
256	5	2026-08-22	20260822	17	17	\N	13	\N	\N	\N	1
146	5	2026-08-05	20260805	13	13	\N	13	\N	\N	\N	1
154	5	2026-08-06	20260808	13	13	\N	13	\N	\N	\N	1
267	6	2026-08-24	3783	14	16	\N	16	\N	\N	STYLE#158374	1
287	5	2026-08-11	4700015026	13	13	\N	13	960+760+350	210	\N	1
261	6	2026-08-22	3779	14	16	\N	16	820	\N	3779	1
280	5	2026-08-20	4700015021	14	16	\N	4	1260	245	762	1
289	5	2026-08-28	20260828	\N	15	\N	13	\N	\N	\N	1
\.


--
-- Data for Name: transaction_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_type_master (id, name, code, action, tenant_id) FROM stdin;
7	Fabric Delivery Return	Fabric_Delivery_Return	Plus	1
3	Yarn Receipt	Yarn_Receipt	Plus	1
4	Yarn Return	Yarn_Return	Minus	1
6	Fabric Delivery	Fabric_Dispatch	Minus	1
5	Fabric Production	Fabric_Production	\N	1
\.


--
-- Data for Name: two_factor_auth; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.two_factor_auth (id, tenant_id, user_id, is_enabled, is_verified, verified_at, totp_secret, totp_backup_codes, phone_number, phone_verified, sms_enabled, email_enabled, recovery_codes_generated_at, recovery_codes_used_count, last_verified_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: uom_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.uom_master (id, name, abbreviation, tenant_id) FROM stdin;
3	Meter	MTR	1
1	KG	KG	1
2	GM	GM	1
4	PCS	PCS	1
13	Roll	Roll	1
14	Bags	Bags	1
\.


--
-- Data for Name: user_invitations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_invitations (id, tenant_id, invited_by, email, status, accepted_at, created_at, updated_at, role, token, accepted_by, expires_at) FROM stdin;
\.


--
-- Data for Name: user_oauth_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_oauth_accounts (id, tenant_id, user_id, provider_name, provider_user_id, access_token, refresh_token, token_expires_at, linked_at) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_sessions (id, tenant_id, user_id, session_token, refresh_token, device_name, device_type, ip_address, user_agent, is_active, last_activity_at, expires_at, two_factor_verified, verified_at, created_at) FROM stdin;
\.


--
-- Data for Name: workflow_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.workflow_settings (id, tenant_id, workflow_key, workflow_name, description, requires_approval, approval_level, auto_approve_threshold, notification_on_step_change, step_sequence, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: yarn_brand_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_brand_master (id, name, code, tenant_id) FROM stdin;
2	Premium	Premium	1
3	Faisal	Faisal	1
1	Gadoon	Gadoon	1
4	Tata	Tata	1
13	Fazal	Fazal	1
14	Gul Ahmed	Gul Ahmed	1
15	Metco	Metco	1
16	Ibrahim Fiber	Ibrahim	1
17	Feroze	Feroze	1
18	CHINA	CHINA	1
19	Shahzad	Shahzad	1
20	Relince 	Relince 	1
21	Akram	Akram	1
22	Indus	Indus	1
\.


--
-- Data for Name: yarn_count_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_count_master (id, name, count, tenant_id) FROM stdin;
37	20s+70-D Lycra	20s+70-D Lycra	1
38	30s+40-D Lycra	30s+40-D Lycra	1
39	20s+40-D Lycra	20s+40-D Lycra	1
36	30s+70-D Lyc 1.5 Tar	30s+70-D Lyc 1.5 Tar	1
40	30s+70-D Lyc D.Tar	30s+70-D Lyc D.Tar	1
1	10s	10s	1
15	16s	16s	1
13	20s	20s	1
33	20s+50/36+10s	20s+50/36+10s	1
35	20s+50/36+16s	20s+50/36+16s	1
31	20s+75/36+10s	20s+75/36+10s	1
32	20s+75/36+16s	20s+75/36+16s	1
16	24s	24s	1
17	26s	26s	1
2	30s	30s	1
29	30s+50/36+16s	30s+50/36+16s	1
28	30s+50/36+10s	30s+50/36+10s	1
30	30s+50/36+20s	30s+50/36+20s	1
23	30s+75/36+10s	30s+75/36+10s	1
26	30s+75/36+16s	30s+75/36+16s	1
27	30s+75/36+20s	30s+75/36+20s	1
18	32s	32s	1
3	40s	40s	1
4	60s	60s	1
14	08s	08s	1
45	30s+30s+16s	30s+30s+16s	1
46	30s+30s+10s	30s+30s+10s	1
47	20s+50/36+12s	20s+50/36+12s	1
48	30s+75/36+12s	30s+75/36+12s	1
49	30s+50/36+12s	30s+50/36+12s	1
42	26s+100/36+10s	26s+100/36+10s	1
21	40-D Lycra	40-D Lycra	1
22	70-D Lycra	70-D Lycra	1
43	100/20	100/20	1
41	100/36	100/36	1
20	50/36	50/36	1
19	75/36	75/36	1
\.


--
-- Data for Name: yarn_receipt_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_receipt_detail (id, header_id, yarn_count_id, quantity, net_weight, yarn_brand_id, tenant_id) FROM stdin;
3	3	2	11	498.960	2	1
4	3	19	12	432.000	18	1
5	3	1	28	1270.080	15	1
6	4	2	14	635.040	2	1
13	7	13	100	4536.000	3	1
15	9	2	25	1134.000	2	1
16	9	1	28	1270.080	20	1
17	5	1	30	1360.800	1	1
18	5	19	17	612.000	18	1
19	5	17	29	1278.310	1	1
20	6	1	34	1542.240	1	1
21	6	19	12	432.000	18	1
22	6	17	50	2268.000	1	1
23	10	1	127	5760.720	1	1
26	12	26	1	4466.360	1	1
31	13	23	1	1908.837	3	1
34	14	29	1	7436.424	1	1
35	15	29	1	706.962	3	1
37	11	23	1	2675.056	2	1
38	16	29	1	455.460	1	1
41	17	1	54	2442.290	1	1
42	17	17	33	1478.100	1	1
43	18	37	1	50.764	1	1
44	19	2	108	4898.880	3	1
45	20	19	121	3993.000	18	1
46	21	41	23	828.000	18	1
47	22	13	14	635.040	4	1
48	23	19	8	288.000	18	1
50	24	1	25	1134.000	15	1
51	24	19	3	108.000	18	1
56	25	13	26	1179.360	13	1
57	25	1	19	861.840	15	1
58	26	22	2	40.000	18	1
59	27	22	1	14.720	18	1
60	28	13	2	82.300	3	1
61	29	2	11	498.960	1	1
62	30	19	12	432.000	18	1
63	31	1	15	680.400	1	1
64	32	2	33	1496.880	1	1
65	33	2	25	1134.000	2	1
66	33	19	12	432.000	18	1
67	33	1	28	1270.080	20	1
\.


--
-- Data for Name: yarn_receipt_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_receipt_header (id, receipt_date, party_id, status, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at, doc_number, tenant_id) FROM stdin;
6	2026-08-05	14	submitted	Iftikhar 	2026-08-06 07:04:15.540986	Iftikhar 	2026-08-06 13:25:13.63	t	151	2026-08-06 13:29:06.366	47*15011	1
5	2026-08-03	14	submitted	Iftikhar 	2026-08-06 07:00:54.830412	Iftikhar 	2026-08-06 13:24:52.614	t	152	2026-08-06 13:30:37.422	47*14961	1
4	2026-08-03	13	submitted	Iftikhar 	2026-08-05 15:17:31.325144	\N	2026-08-05 15:17:31.325144	t	157	2026-08-07 09:28:55.475	169827	1
7	2026-08-04	16	submitted	Iftikhar 	2026-08-06 12:06:12.637753	\N	2026-08-06 12:06:12.637753	t	158	2026-08-07 09:39:44.079	0268	1
10	2026-08-04	16	submitted	Iftikhar 	2026-08-07 05:50:24.91951	\N	2026-08-07 05:50:24.91951	t	158	2026-08-07 09:39:44.079	852	1
9	2026-08-06	13	submitted	Iftikhar 	2026-08-06 12:15:37.982881	\N	2026-08-06 12:15:37.982881	t	159	2026-08-07 12:26:22.021	169950	1
3	2026-08-01	13	submitted	Iftikhar 	2026-08-05 15:13:49.011076	\N	2026-08-05 15:13:49.011076	t	160	2026-08-07 12:33:24.717	169808	1
28	2026-08-25	16	submitted	Iftikhar Ahmed	2026-08-25 13:24:00.426893	\N	2026-08-25 13:24:00.426893	t	274	2026-08-28 07:07:53.425	3801	1
29	2026-08-25	15	submitted	Iftikhar Ahmed	2026-08-25 13:25:52.980419	\N	2026-08-25 13:25:52.980419	t	275	2026-08-28 07:08:53.59	762	1
30	2026-08-27	15	submitted	Iftikhar Ahmed	2026-08-27 10:05:46.591103	\N	2026-08-27 10:05:46.591103	t	276	2026-08-28 07:09:38.203	762	1
31	2026-08-28	15	submitted	Iftikhar Ahmed	2026-08-28 12:40:26.536015	\N	2026-08-28 12:40:26.536015	t	288	2026-08-28 12:42:57.258	766	1
32	2026-08-28	15	submitted	Iftikhar Ahmed	2026-08-28 12:41:22.9518	\N	2026-08-28 12:41:22.9518	t	288	2026-08-28 12:42:57.258	766	1
14	2026-07-31	14	submitted	Hsn	2026-08-07 14:04:45.734997	Hsn	2026-08-07 14:05:12.041	t	164	2026-08-07 14:14:03.798	August 26 >----> Opening	1
13	2026-07-31	15	submitted	Hsn	2026-08-07 14:01:43.346427	Hsn	2026-08-07 14:03:58.678	t	165	2026-08-07 14:15:04.336	August-26 >---->  Opening	1
17	2026-08-05	14	submitted	Iftikhar 	2026-08-07 15:32:50.82745	Iftikhar 	2026-08-08 06:29:51.408	t	168	2026-08-08 06:47:23.411	47*15011	1
11	2026-07-31	13	submitted	Hsn	2026-08-07 13:32:38.03277	Hsn	2026-08-07 14:08:00.394	t	181	2026-08-08 07:39:21.867	August-26 >----> Opening	1
12	2026-07-31	16	submitted	Hsn	2026-08-07 13:43:04.390777	\N	2026-08-07 13:43:04.390777	t	182	2026-08-08 07:41:43.774	August-26 >---->Opening	1
15	2026-07-31	17	submitted	Hsn	2026-08-07 14:07:25.390882	\N	2026-08-07 14:07:25.390882	t	183	2026-08-08 07:44:51.579	August-26 >----> Opening	1
16	2026-07-31	20	submitted	Hsn	2026-08-07 14:11:11.661753	\N	2026-08-07 14:11:11.661753	t	184	2026-08-08 07:45:42.665	August-26 >----> Opening	1
18	2026-07-31	19	submitted	Hsn	2026-08-08 06:43:38.165898	\N	2026-08-08 06:43:38.165898	t	185	2026-08-08 07:46:23.931	August-26 >----> Opening	1
19	2026-08-10	16	submitted	Iftikhar 	2026-08-10 13:32:11.635391	\N	2026-08-10 13:32:11.635391	t	192	2026-08-11 06:12:17.383	0320	1
20	2026-08-01	16	submitted	Hsn	2026-08-11 07:04:47.713807	\N	2026-08-11 07:04:47.713807	t	194	2026-08-11 07:07:00.433	16237	1
21	2026-08-05	14	submitted	Iftikhar 	2026-08-11 07:39:31.106192	\N	2026-08-11 07:39:31.106192	t	196	2026-08-11 07:41:22.139	47*15011	1
33	2026-08-29	13	submitted	Iftikhar Ahmed	2026-08-29 05:43:37.982683	\N	2026-08-29 05:43:37.982683	t	290	2026-08-29 07:38:59.635	170468	1
22	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:31:08.766439	\N	2026-08-19 11:31:08.766439	t	239	2026-08-20 09:04:20.032	1483	1
23	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:32:20.90415	\N	2026-08-19 11:32:20.90415	t	240	2026-08-20 09:06:41.514	1484	1
24	2026-08-18	17	submitted	Iftikhar Ahmed	2026-08-19 11:33:54.607283	Iftikhar Ahmed	2026-08-19 11:35:52.385	t	241	2026-08-20 09:08:57.154	1485	1
25	2026-08-20	17	submitted	Iftikhar Ahmed	2026-08-20 12:28:44.161241	Iftikhar Ahmed	2026-08-21 04:59:13.033	t	245	2026-08-21 07:06:51.4	1489	1
26	2026-08-21	17	submitted	Iftikhar Ahmed	2026-08-21 12:34:23.886984	\N	2026-08-21 12:34:23.886984	t	253	2026-08-22 06:47:15.621	1492	1
27	2026-08-21	17	submitted	Iftikhar Ahmed	2026-08-21 12:35:09.127188	\N	2026-08-21 12:35:09.127188	t	254	2026-08-22 06:48:13.848	1493	1
\.


--
-- Data for Name: yarn_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_type_master (id, name, code, make_rate, hs_code, tenant_id) FROM stdin;
1	100% Cotton	CTN	\N	6002.9000	1
21	2-Fleece	2FL	3.00	6002.9000	1
20	3-Fleece	3FL	3.75	6002.9000	1
17	CVC (60/40)	CVC_60/40	\N	6002.9000	1
18	HG 	HG	\N	6002.9000	1
14	PC (52/48)	PC_52/48	\N	6002.9000	1
19	PC (60/40)	PC_60/40	\N	6002.9000	1
15	PC (65/35)	PC_65/35	\N	6002.9000	1
16	PC (75/25)	PC_75/25	\N	6002.9000	1
25	PC (80/20)	PC_80/20	\N	6002.9000	1
2	Polyester	POLYESTER	\N	6002.9000	1
24	RIB (1X1)	RIB_(1X1)	4.00	6002.9000	1
23	RIB (2X1)	RIB_(2X1)	4.00	6002.9000	1
22	Single Jersey	SJ	3.00	6002.9000	1
\.


--
-- Name: api_keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_keys_id_seq', 1, false);


--
-- Name: app_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.app_user_id_seq', 6, true);


--
-- Name: attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attendance_id_seq', 10082, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 2, true);


--
-- Name: auth_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_audit_id_seq', 1, false);


--
-- Name: branding_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.branding_config_id_seq', 1, true);


--
-- Name: company_info_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.company_info_master_id_seq', 1, true);


--
-- Name: configuration_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.configuration_audit_id_seq', 1, false);


--
-- Name: configuration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.configuration_id_seq', 3, true);


--
-- Name: custom_domains_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.custom_domains_id_seq', 1, false);


--
-- Name: daily_delivery_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_delivery_id_seq', 68, true);


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_detail_id_seq', 1886, true);


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_header_id_seq', 261, true);


--
-- Name: department_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.department_master_id_seq', 4, true);


--
-- Name: email_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.email_templates_id_seq', 1, false);


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fabric_type_master_id_seq', 16, true);


--
-- Name: factory_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.factory_maintenance_id_seq', 1, true);


--
-- Name: feature_flags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.feature_flags_id_seq', 10, true);


--
-- Name: integration_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.integration_settings_id_seq', 1, false);


--
-- Name: invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_id_seq', 256, true);


--
-- Name: invoice_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_item_id_seq', 64, true);


--
-- Name: invoice_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_payment_id_seq', 4, true);


--
-- Name: invoice_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoice_transaction_id_seq', 12, true);


--
-- Name: job_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.job_master_id_seq', 24, true);


--
-- Name: location_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.location_master_id_seq', 18, true);


--
-- Name: login_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.login_attempts_id_seq', 1, false);


--
-- Name: logo_uploads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.logo_uploads_id_seq', 1, false);


--
-- Name: machine_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_history_id_seq', 12, true);


--
-- Name: machine_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_maintenance_id_seq', 7, true);


--
-- Name: machine_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_master_id_seq', 29, true);


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_operator_master_id_seq', 19, true);


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.oauth_providers_id_seq', 3, true);


--
-- Name: operator_advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_advances_id_seq', 25, true);


--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_salary_records_id_seq', 1, false);


--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_salary_settings_id_seq', 6, true);


--
-- Name: party_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.party_master_id_seq', 21, true);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.password_reset_tokens_id_seq', 1, false);


--
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_baseline_id_seq', 4136, true);


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_feedback_id_seq', 41, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.role_id_seq', 9, true);


--
-- Name: salary_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_detail_id_seq', 6, true);


--
-- Name: salary_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_header_id_seq', 1, true);


--
-- Name: session_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.session_settings_id_seq', 2, true);


--
-- Name: system_defaults_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.system_defaults_id_seq', 10, true);


--
-- Name: tenant_admin_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenant_admin_assignments_id_seq', 1, false);


--
-- Name: tenant_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenant_settings_id_seq', 2, true);


--
-- Name: tenants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tenants_id_seq', 1, false);


--
-- Name: theme_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.theme_presets_id_seq', 14, true);


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_detail_id_seq', 878, true);


--
-- Name: transaction_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_header_id_seq', 290, true);


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_type_master_id_seq', 8, true);


--
-- Name: two_factor_auth_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.two_factor_auth_id_seq', 1, false);


--
-- Name: uom_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.uom_master_id_seq', 14, true);


--
-- Name: user_invitations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_invitations_id_seq', 1, true);


--
-- Name: user_oauth_accounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_oauth_accounts_id_seq', 1, false);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 1, false);


--
-- Name: workflow_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.workflow_settings_id_seq', 1, false);


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_brand_master_id_seq', 22, true);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_count_master_id_seq', 52, true);


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_detail_id_seq', 67, true);


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_header_id_seq', 33, true);


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_type_master_id_seq', 25, true);


--
-- Name: _applied_migrations _applied_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._applied_migrations
    ADD CONSTRAINT _applied_migrations_pkey PRIMARY KEY (name);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_employee_date_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_employee_date_unique UNIQUE (employee_id, attendance_date);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: auth_audit auth_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_audit
    ADD CONSTRAINT auth_audit_pkey PRIMARY KEY (id);


--
-- Name: branding_config branding_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branding_config
    ADD CONSTRAINT branding_config_pkey PRIMARY KEY (id);


--
-- Name: branding_config branding_config_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branding_config
    ADD CONSTRAINT branding_config_tenant_id_key UNIQUE (tenant_id);


--
-- Name: company_info_master company_info_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_info_master
    ADD CONSTRAINT company_info_master_pkey PRIMARY KEY (id);


--
-- Name: configuration_audit configuration_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration_audit
    ADD CONSTRAINT configuration_audit_pkey PRIMARY KEY (id);


--
-- Name: configuration configuration_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration
    ADD CONSTRAINT configuration_code_unique UNIQUE (code);


--
-- Name: configuration configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration
    ADD CONSTRAINT configuration_pkey PRIMARY KEY (id);


--
-- Name: custom_domains custom_domains_domain_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains
    ADD CONSTRAINT custom_domains_domain_name_key UNIQUE (domain_name);


--
-- Name: custom_domains custom_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains
    ADD CONSTRAINT custom_domains_pkey PRIMARY KEY (id);


--
-- Name: custom_domains custom_domains_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains
    ADD CONSTRAINT custom_domains_tenant_id_key UNIQUE (tenant_id);


--
-- Name: daily_delivery daily_delivery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_pkey PRIMARY KEY (id);


--
-- Name: daily_production_detail daily_production_detail_header_roll_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT daily_production_detail_header_roll_unique UNIQUE (header_id, roll_number);


--
-- Name: daily_production_detail daily_production_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT daily_production_detail_pkey PRIMARY KEY (id);


--
-- Name: daily_production_header daily_production_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_pkey PRIMARY KEY (id);


--
-- Name: department_master department_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_master
    ADD CONSTRAINT department_master_code_unique UNIQUE (code);


--
-- Name: department_master department_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_master
    ADD CONSTRAINT department_master_pkey PRIMARY KEY (id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: employee_advances employee_advances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_advances
    ADD CONSTRAINT employee_advances_pkey PRIMARY KEY (id);


--
-- Name: employee_master employee_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_master
    ADD CONSTRAINT employee_master_code_unique UNIQUE (code);


--
-- Name: employee_master employee_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_master
    ADD CONSTRAINT employee_master_pkey PRIMARY KEY (id);


--
-- Name: employee_salary_records employee_salary_records_employee_id_date_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records
    ADD CONSTRAINT employee_salary_records_employee_id_date_unique UNIQUE (employee_id, date);


--
-- Name: employee_salary_records employee_salary_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records
    ADD CONSTRAINT employee_salary_records_pkey PRIMARY KEY (id);


--
-- Name: employee_salary_settings employee_salary_settings_employee_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings
    ADD CONSTRAINT employee_salary_settings_employee_id_unique UNIQUE (employee_id);


--
-- Name: employee_salary_settings employee_salary_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings
    ADD CONSTRAINT employee_salary_settings_pkey PRIMARY KEY (id);


--
-- Name: fabric_type_master fabric_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fabric_type_master_code_unique UNIQUE (code);


--
-- Name: fabric_type_master fabric_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fabric_type_master_pkey PRIMARY KEY (id);


--
-- Name: factory_maintenance factory_maintenance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factory_maintenance
    ADD CONSTRAINT factory_maintenance_pkey PRIMARY KEY (id);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (id);


--
-- Name: integration_settings integration_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_settings
    ADD CONSTRAINT integration_settings_pkey PRIMARY KEY (id);


--
-- Name: invoice_item invoice_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item
    ADD CONSTRAINT invoice_item_pkey PRIMARY KEY (id);


--
-- Name: invoice_payment invoice_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_payment
    ADD CONSTRAINT invoice_payment_pkey PRIMARY KEY (id);


--
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (id);


--
-- Name: invoice_transaction invoice_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_transaction
    ADD CONSTRAINT invoice_transaction_pkey PRIMARY KEY (id);


--
-- Name: invoice_transaction invoice_transaction_tx_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_transaction
    ADD CONSTRAINT invoice_transaction_tx_unique UNIQUE (transaction_header_id);


--
-- Name: invoice_transaction invoice_transaction_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_transaction
    ADD CONSTRAINT invoice_transaction_unique UNIQUE (invoice_id, transaction_header_id);


--
-- Name: job_master job_master_party_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT job_master_party_code_unique UNIQUE (party_id, code);


--
-- Name: job_master job_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT job_master_pkey PRIMARY KEY (id);


--
-- Name: location_master location_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_master
    ADD CONSTRAINT location_master_code_unique UNIQUE (code);


--
-- Name: location_master location_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_master
    ADD CONSTRAINT location_master_pkey PRIMARY KEY (id);


--
-- Name: login_attempts login_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_attempts
    ADD CONSTRAINT login_attempts_pkey PRIMARY KEY (id);


--
-- Name: logo_uploads logo_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logo_uploads
    ADD CONSTRAINT logo_uploads_pkey PRIMARY KEY (id);


--
-- Name: machine_history machine_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_history
    ADD CONSTRAINT machine_history_pkey PRIMARY KEY (id);


--
-- Name: machine_maintenance machine_maintenance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_maintenance
    ADD CONSTRAINT machine_maintenance_pkey PRIMARY KEY (id);


--
-- Name: machine_master machine_master_machine_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_master
    ADD CONSTRAINT machine_master_machine_number_unique UNIQUE (machine_number);


--
-- Name: machine_master machine_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_master
    ADD CONSTRAINT machine_master_pkey PRIMARY KEY (id);


--
-- Name: oauth_providers oauth_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_providers
    ADD CONSTRAINT oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: party_master party_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master
    ADD CONSTRAINT party_master_code_unique UNIQUE (code);


--
-- Name: party_master party_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master
    ADD CONSTRAINT party_master_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_reset_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_reset_token_key UNIQUE (reset_token);


--
-- Name: plausibility_baseline plausibility_baseline_operation_field_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_baseline
    ADD CONSTRAINT plausibility_baseline_operation_field_unique UNIQUE (operation, field);


--
-- Name: plausibility_baseline plausibility_baseline_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_baseline
    ADD CONSTRAINT plausibility_baseline_pkey PRIMARY KEY (id);


--
-- Name: plausibility_feedback plausibility_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_feedback
    ADD CONSTRAINT plausibility_feedback_pkey PRIMARY KEY (id);


--
-- Name: role_permission role_permission_role_id_module_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_role_id_module_id_pk PRIMARY KEY (role_id, module_id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: salary_detail salary_detail_emp_month_year_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_emp_month_year_unique UNIQUE (employee_id, month, year);


--
-- Name: salary_detail salary_detail_header_employee_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_header_employee_unique UNIQUE (header_id, employee_id);


--
-- Name: salary_detail salary_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_pkey PRIMARY KEY (id);


--
-- Name: salary_header salary_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_header
    ADD CONSTRAINT salary_header_pkey PRIMARY KEY (id);


--
-- Name: session_settings session_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_settings
    ADD CONSTRAINT session_settings_pkey PRIMARY KEY (id);


--
-- Name: session_settings session_settings_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_settings
    ADD CONSTRAINT session_settings_tenant_id_key UNIQUE (tenant_id);


--
-- Name: system_defaults system_defaults_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_defaults
    ADD CONSTRAINT system_defaults_pkey PRIMARY KEY (id);


--
-- Name: system_defaults system_defaults_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_defaults
    ADD CONSTRAINT system_defaults_setting_key_key UNIQUE (setting_key);


--
-- Name: tenant_admin_assignments tenant_admin_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_admin_assignments
    ADD CONSTRAINT tenant_admin_assignments_pkey PRIMARY KEY (id);


--
-- Name: tenant_settings tenant_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_settings
    ADD CONSTRAINT tenant_settings_pkey PRIMARY KEY (id);


--
-- Name: tenant_settings tenant_settings_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_settings
    ADD CONSTRAINT tenant_settings_tenant_id_key UNIQUE (tenant_id);


--
-- Name: tenants tenants_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_name_key UNIQUE (name);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: tenants tenants_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_slug_key UNIQUE (slug);


--
-- Name: theme_presets theme_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theme_presets
    ADD CONSTRAINT theme_presets_pkey PRIMARY KEY (id);


--
-- Name: transaction_detail transaction_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_pkey PRIMARY KEY (id);


--
-- Name: transaction_header transaction_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_pkey PRIMARY KEY (id);


--
-- Name: transaction_type_master transaction_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT transaction_type_master_code_unique UNIQUE (code);


--
-- Name: transaction_type_master transaction_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT transaction_type_master_pkey PRIMARY KEY (id);


--
-- Name: two_factor_auth two_factor_auth_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth
    ADD CONSTRAINT two_factor_auth_pkey PRIMARY KEY (id);


--
-- Name: uom_master uom_master_abbreviation_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master
    ADD CONSTRAINT uom_master_abbreviation_unique UNIQUE (abbreviation);


--
-- Name: uom_master uom_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master
    ADD CONSTRAINT uom_master_pkey PRIMARY KEY (id);


--
-- Name: two_factor_auth uq_2fa_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth
    ADD CONSTRAINT uq_2fa_user UNIQUE (user_id);


--
-- Name: email_templates uq_email_template_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT uq_email_template_key UNIQUE (tenant_id, template_key);


--
-- Name: feature_flags uq_feature_flags_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT uq_feature_flags_key UNIQUE (tenant_id, feature_key);


--
-- Name: integration_settings uq_integration_settings_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_settings
    ADD CONSTRAINT uq_integration_settings_key UNIQUE (tenant_id, integration_key);


--
-- Name: user_oauth_accounts uq_oauth_account; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_oauth_accounts
    ADD CONSTRAINT uq_oauth_account UNIQUE (tenant_id, user_id, provider_name);


--
-- Name: oauth_providers uq_oauth_provider; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_providers
    ADD CONSTRAINT uq_oauth_provider UNIQUE (tenant_id, provider_name);


--
-- Name: tenant_admin_assignments uq_tenant_admin; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_admin_assignments
    ADD CONSTRAINT uq_tenant_admin UNIQUE (tenant_id, admin_user_id);


--
-- Name: theme_presets uq_theme_preset_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theme_presets
    ADD CONSTRAINT uq_theme_preset_key UNIQUE (tenant_id, preset_key);


--
-- Name: workflow_settings uq_workflow_settings_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_settings
    ADD CONSTRAINT uq_workflow_settings_key UNIQUE (tenant_id, workflow_key);


--
-- Name: user_invitations user_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_invitations
    ADD CONSTRAINT user_invitations_pkey PRIMARY KEY (id);


--
-- Name: user_oauth_accounts user_oauth_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_oauth_accounts
    ADD CONSTRAINT user_oauth_accounts_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_session_token_key UNIQUE (session_token);


--
-- Name: workflow_settings workflow_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_settings
    ADD CONSTRAINT workflow_settings_pkey PRIMARY KEY (id);


--
-- Name: yarn_brand_master yarn_brand_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT yarn_brand_master_code_unique UNIQUE (code);


--
-- Name: yarn_brand_master yarn_brand_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT yarn_brand_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_count_master yarn_count_master_count_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT yarn_count_master_count_unique UNIQUE (count);


--
-- Name: yarn_count_master yarn_count_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT yarn_count_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_receipt_detail yarn_receipt_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_pkey PRIMARY KEY (id);


--
-- Name: yarn_receipt_header yarn_receipt_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header
    ADD CONSTRAINT yarn_receipt_header_pkey PRIMARY KEY (id);


--
-- Name: yarn_type_master yarn_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT yarn_type_master_code_unique UNIQUE (code);


--
-- Name: yarn_type_master yarn_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT yarn_type_master_pkey PRIMARY KEY (id);


--
-- Name: attendance_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX attendance_date_idx ON public.attendance USING btree (attendance_date);


--
-- Name: daily_delivery_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_delivery_date_idx ON public.daily_delivery USING btree (delivery_date, party_id);


--
-- Name: daily_delivery_reconcile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_delivery_reconcile_idx ON public.daily_delivery USING btree (delivery_date, party_id, reconciled);


--
-- Name: daily_production_detail_header_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_production_detail_header_idx ON public.daily_production_detail USING btree (header_id);


--
-- Name: daily_production_header_reconcile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_production_header_reconcile_idx ON public.daily_production_header USING btree (production_date, party_id, reconciled);


--
-- Name: daily_production_header_summary_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_production_header_summary_idx ON public.daily_production_header USING btree (production_date, machine_id, employee_id, party_id, shift);


--
-- Name: employee_advances_employee_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employee_advances_employee_date_idx ON public.employee_advances USING btree (employee_id, date);


--
-- Name: factory_maintenance_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX factory_maintenance_date_idx ON public.factory_maintenance USING btree (maintenance_date, status);


--
-- Name: idx_2fa_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_2fa_enabled ON public.two_factor_auth USING btree (user_id, is_enabled);


--
-- Name: idx_2fa_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_2fa_tenant ON public.two_factor_auth USING btree (tenant_id);


--
-- Name: idx_app_user_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_user_tenant_id ON public.app_user USING btree (tenant_id);


--
-- Name: idx_attendance_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attendance_tenant_id ON public.attendance USING btree (tenant_id);


--
-- Name: idx_audit_log_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_log_actor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_actor ON public.audit_log USING btree (actor_user_id);


--
-- Name: idx_audit_log_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_created ON public.audit_log USING btree (created_at);


--
-- Name: idx_audit_log_target_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_target_tenant ON public.audit_log USING btree (target_tenant_id);


--
-- Name: idx_auth_audit_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_audit_created ON public.auth_audit USING btree (created_at DESC);


--
-- Name: idx_auth_audit_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_audit_event ON public.auth_audit USING btree (tenant_id, event_type);


--
-- Name: idx_auth_audit_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_audit_ip ON public.auth_audit USING btree (ip_address);


--
-- Name: idx_auth_audit_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_audit_tenant ON public.auth_audit USING btree (tenant_id, created_at DESC);


--
-- Name: idx_auth_audit_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_audit_user ON public.auth_audit USING btree (user_id);


--
-- Name: idx_branding_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branding_status ON public.branding_config USING btree (status);


--
-- Name: idx_branding_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branding_tenant_id ON public.branding_config USING btree (tenant_id);


--
-- Name: idx_company_info_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_company_info_tenant_id ON public.company_info_master USING btree (tenant_id);


--
-- Name: idx_config_audit_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_config_audit_date ON public.configuration_audit USING btree (tenant_id, created_at DESC);


--
-- Name: idx_config_audit_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_config_audit_entity ON public.configuration_audit USING btree (tenant_id, entity_type);


--
-- Name: idx_config_audit_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_config_audit_tenant ON public.configuration_audit USING btree (tenant_id);


--
-- Name: idx_config_audit_tenant_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_config_audit_tenant_date ON public.configuration_audit USING btree (tenant_id, created_at DESC);


--
-- Name: idx_config_audit_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_config_audit_user ON public.configuration_audit USING btree (changed_by);


--
-- Name: idx_configuration_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_configuration_tenant_id ON public.configuration USING btree (tenant_id);


--
-- Name: idx_custom_domain_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_domain_name ON public.custom_domains USING btree (domain_name);


--
-- Name: idx_custom_domain_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_domain_tenant ON public.custom_domains USING btree (tenant_id);


--
-- Name: idx_daily_delivery_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_delivery_tenant_id ON public.daily_delivery USING btree (tenant_id);


--
-- Name: idx_daily_prod_detail_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_prod_detail_tenant_id ON public.daily_production_detail USING btree (tenant_id);


--
-- Name: idx_daily_prod_header_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_prod_header_tenant_id ON public.daily_production_header USING btree (tenant_id);


--
-- Name: idx_department_master_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_department_master_tenant_id ON public.department_master USING btree (tenant_id);


--
-- Name: idx_email_template_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_email_template_key ON public.email_templates USING btree (tenant_id, template_key);


--
-- Name: idx_email_template_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_email_template_tenant ON public.email_templates USING btree (tenant_id);


--
-- Name: idx_employee_master_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_employee_master_tenant_id ON public.employee_master USING btree (tenant_id);


--
-- Name: idx_fabric_type_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fabric_type_tenant_id ON public.fabric_type_master USING btree (tenant_id);


--
-- Name: idx_fabric_type_tenant_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fabric_type_tenant_name ON public.fabric_type_master USING btree (tenant_id, name);


--
-- Name: idx_factory_maint_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_factory_maint_tenant_id ON public.factory_maintenance USING btree (tenant_id);


--
-- Name: idx_feature_flags_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feature_flags_category ON public.feature_flags USING btree (tenant_id, category);


--
-- Name: idx_feature_flags_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feature_flags_enabled ON public.feature_flags USING btree (tenant_id, is_enabled);


--
-- Name: idx_feature_flags_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feature_flags_tenant ON public.feature_flags USING btree (tenant_id);


--
-- Name: idx_feature_flags_tenant_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feature_flags_tenant_enabled ON public.feature_flags USING btree (tenant_id, is_enabled);


--
-- Name: idx_integration_settings_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integration_settings_enabled ON public.integration_settings USING btree (tenant_id, is_enabled);


--
-- Name: idx_integration_settings_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integration_settings_sync ON public.integration_settings USING btree (tenant_id, last_sync_at);


--
-- Name: idx_integration_settings_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integration_settings_tenant ON public.integration_settings USING btree (tenant_id);


--
-- Name: idx_invitations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invitations_status ON public.user_invitations USING btree (status);


--
-- Name: idx_invitations_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invitations_tenant ON public.user_invitations USING btree (tenant_id);


--
-- Name: idx_invoice_item_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoice_item_tenant_id ON public.invoice_item USING btree (tenant_id);


--
-- Name: idx_invoice_payment_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoice_payment_tenant_id ON public.invoice_payment USING btree (tenant_id);


--
-- Name: idx_invoice_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoice_tenant_id ON public.invoice USING btree (tenant_id);


--
-- Name: idx_invoice_transaction_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoice_transaction_tenant_id ON public.invoice_transaction USING btree (tenant_id);


--
-- Name: idx_job_master_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_master_tenant_id ON public.job_master USING btree (tenant_id);


--
-- Name: idx_location_master_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_location_master_tenant_id ON public.location_master USING btree (tenant_id);


--
-- Name: idx_login_attempts_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_attempts_created ON public.login_attempts USING btree (created_at DESC);


--
-- Name: idx_login_attempts_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_attempts_email ON public.login_attempts USING btree (tenant_id, email);


--
-- Name: idx_login_attempts_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_attempts_ip ON public.login_attempts USING btree (ip_address);


--
-- Name: idx_login_attempts_locked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_attempts_locked ON public.login_attempts USING btree (email, is_locked, locked_until);


--
-- Name: idx_logo_uploads_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logo_uploads_active ON public.logo_uploads USING btree (tenant_id, is_active);


--
-- Name: idx_logo_uploads_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logo_uploads_tenant ON public.logo_uploads USING btree (tenant_id);


--
-- Name: idx_logo_uploads_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logo_uploads_type ON public.logo_uploads USING btree (tenant_id, logo_type);


--
-- Name: idx_machine_history_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_machine_history_tenant_id ON public.machine_history USING btree (tenant_id);


--
-- Name: idx_machine_maint_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_machine_maint_tenant_id ON public.machine_maintenance USING btree (tenant_id);


--
-- Name: idx_machine_master_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_machine_master_tenant_id ON public.machine_master USING btree (tenant_id);


--
-- Name: idx_oauth_accounts_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oauth_accounts_provider ON public.user_oauth_accounts USING btree (tenant_id, provider_name);


--
-- Name: idx_oauth_accounts_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oauth_accounts_user ON public.user_oauth_accounts USING btree (user_id);


--
-- Name: idx_oauth_providers_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oauth_providers_tenant ON public.oauth_providers USING btree (tenant_id, is_enabled);


--
-- Name: idx_party_master_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_party_master_tenant_id ON public.party_master USING btree (tenant_id);


--
-- Name: idx_password_reset_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_expires ON public.password_reset_tokens USING btree (expires_at);


--
-- Name: idx_password_reset_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_token ON public.password_reset_tokens USING btree (reset_token);


--
-- Name: idx_password_reset_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_user ON public.password_reset_tokens USING btree (user_id, is_used);


--
-- Name: idx_role_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_tenant_id ON public.role USING btree (tenant_id);


--
-- Name: idx_session_settings_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_session_settings_tenant ON public.session_settings USING btree (tenant_id);


--
-- Name: idx_system_defaults_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_system_defaults_key ON public.system_defaults USING btree (setting_key);


--
-- Name: idx_tenant_admin_assignments_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_admin_assignments_admin ON public.tenant_admin_assignments USING btree (admin_user_id);


--
-- Name: idx_tenant_admin_assignments_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_admin_assignments_created ON public.tenant_admin_assignments USING btree (assigned_at DESC);


--
-- Name: idx_tenant_admin_assignments_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_admin_assignments_tenant ON public.tenant_admin_assignments USING btree (tenant_id);


--
-- Name: idx_tenant_settings_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_settings_status ON public.tenant_settings USING btree (status);


--
-- Name: idx_tenant_settings_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_tenant_settings_tenant_id ON public.tenant_settings USING btree (tenant_id);


--
-- Name: idx_theme_preset_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_theme_preset_default ON public.theme_presets USING btree (tenant_id, is_default);


--
-- Name: idx_theme_preset_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_theme_preset_tenant ON public.theme_presets USING btree (tenant_id);


--
-- Name: idx_transaction_detail_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_detail_tenant_id ON public.transaction_detail USING btree (tenant_id);


--
-- Name: idx_transaction_header_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_header_tenant_id ON public.transaction_header USING btree (tenant_id);


--
-- Name: idx_transaction_type_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_type_tenant_id ON public.transaction_type_master USING btree (tenant_id);


--
-- Name: idx_uom_master_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_uom_master_tenant_id ON public.uom_master USING btree (tenant_id);


--
-- Name: idx_user_invitations_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_invitations_created ON public.user_invitations USING btree (created_at DESC);


--
-- Name: idx_user_invitations_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_invitations_email ON public.user_invitations USING btree (tenant_id, email);


--
-- Name: idx_user_invitations_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_invitations_tenant ON public.user_invitations USING btree (tenant_id);


--
-- Name: idx_user_sessions_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_created ON public.user_sessions USING btree (created_at DESC);


--
-- Name: idx_user_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_expires ON public.user_sessions USING btree (expires_at);


--
-- Name: idx_user_sessions_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_tenant ON public.user_sessions USING btree (tenant_id);


--
-- Name: idx_user_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_token ON public.user_sessions USING btree (session_token);


--
-- Name: idx_user_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_user ON public.user_sessions USING btree (user_id, is_active);


--
-- Name: idx_workflow_settings_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workflow_settings_tenant ON public.workflow_settings USING btree (tenant_id);


--
-- Name: idx_yarn_brand_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yarn_brand_tenant_id ON public.yarn_brand_master USING btree (tenant_id);


--
-- Name: idx_yarn_brand_tenant_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_yarn_brand_tenant_name ON public.yarn_brand_master USING btree (tenant_id, name);


--
-- Name: idx_yarn_count_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yarn_count_tenant_id ON public.yarn_count_master USING btree (tenant_id);


--
-- Name: idx_yarn_receipt_detail_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yarn_receipt_detail_tenant_id ON public.yarn_receipt_detail USING btree (tenant_id);


--
-- Name: idx_yarn_receipt_header_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yarn_receipt_header_tenant_id ON public.yarn_receipt_header USING btree (tenant_id);


--
-- Name: idx_yarn_type_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yarn_type_tenant_id ON public.yarn_type_master USING btree (tenant_id);


--
-- Name: idx_yarn_type_tenant_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_yarn_type_tenant_name ON public.yarn_type_master USING btree (tenant_id, name);


--
-- Name: invoice_item_invoice_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoice_item_invoice_idx ON public.invoice_item USING btree (invoice_id);


--
-- Name: invoice_party_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoice_party_status_idx ON public.invoice USING btree (party_id, status);


--
-- Name: invoice_payment_invoice_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoice_payment_invoice_idx ON public.invoice_payment USING btree (invoice_id);


--
-- Name: invoice_transaction_invoice_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoice_transaction_invoice_idx ON public.invoice_transaction USING btree (invoice_id);


--
-- Name: machine_history_changed_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX machine_history_changed_at_idx ON public.machine_history USING btree (changed_at);


--
-- Name: machine_history_machine_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX machine_history_machine_idx ON public.machine_history USING btree (machine_id);


--
-- Name: machine_maintenance_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX machine_maintenance_date_idx ON public.machine_maintenance USING btree (maintenance_date, status);


--
-- Name: plausibility_feedback_operation_field_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX plausibility_feedback_operation_field_idx ON public.plausibility_feedback USING btree (operation, field);


--
-- Name: role_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX role_name_idx ON public.role USING btree (name, tenant_id);


--
-- Name: role_permission_role_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX role_permission_role_idx ON public.role_permission USING btree (role_id);


--
-- Name: salary_detail_header_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX salary_detail_header_idx ON public.salary_detail USING btree (header_id);


--
-- Name: salary_header_month_year_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX salary_header_month_year_idx ON public.salary_header USING btree (year, month);


--
-- Name: transaction_detail_header_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transaction_detail_header_idx ON public.transaction_detail USING btree (header_id);


--
-- Name: transaction_header_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transaction_header_date_idx ON public.transaction_header USING btree (date);


--
-- Name: transaction_header_doc_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transaction_header_doc_number_idx ON public.transaction_header USING btree (doc_number);


--
-- Name: transaction_header_type_party_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transaction_header_type_party_date_idx ON public.transaction_header USING btree (transaction_type_id, party_id, date);


--
-- Name: uq_branding_config_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_branding_config_tenant ON public.branding_config USING btree (tenant_id);


--
-- Name: uq_tenant_settings_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_tenant_settings_tenant ON public.tenant_settings USING btree (tenant_id);


--
-- Name: user_username_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_username_idx ON public.app_user USING btree (username, tenant_id);


--
-- Name: yarn_receipt_detail_header_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX yarn_receipt_detail_header_idx ON public.yarn_receipt_detail USING btree (header_id);


--
-- Name: yarn_receipt_header_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX yarn_receipt_header_date_idx ON public.yarn_receipt_header USING btree (receipt_date, party_id);


--
-- Name: yarn_receipt_header_reconcile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX yarn_receipt_header_reconcile_idx ON public.yarn_receipt_header USING btree (receipt_date, party_id, reconciled);


--
-- Name: api_keys api_keys_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: app_user app_user_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: app_user app_user_role_id_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_role_id_role_id_fk FOREIGN KEY (role_id) REFERENCES public.role(id);


--
-- Name: attendance attendance_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id) ON DELETE CASCADE;


--
-- Name: audit_log audit_log_actor_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_actor_tenant_id_fkey FOREIGN KEY (actor_tenant_id) REFERENCES public.tenants(id) ON DELETE SET NULL;


--
-- Name: audit_log audit_log_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.app_user(id) ON DELETE SET NULL;


--
-- Name: audit_log audit_log_target_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_target_tenant_id_fkey FOREIGN KEY (target_tenant_id) REFERENCES public.tenants(id) ON DELETE SET NULL;


--
-- Name: daily_delivery daily_delivery_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: daily_delivery daily_delivery_reconciled_transaction_id_transaction_header_id_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_reconciled_transaction_id_transaction_header_id_ FOREIGN KEY (reconciled_transaction_id) REFERENCES public.transaction_header(id) ON DELETE SET NULL;


--
-- Name: daily_delivery daily_delivery_yarn_type_id_yarn_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_yarn_type_id_yarn_type_master_id_fk FOREIGN KEY (yarn_type_id) REFERENCES public.yarn_type_master(id);


--
-- Name: daily_production_detail daily_production_detail_header_id_daily_production_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT daily_production_detail_header_id_daily_production_header_id_fk FOREIGN KEY (header_id) REFERENCES public.daily_production_header(id) ON DELETE CASCADE;


--
-- Name: daily_production_header daily_production_header_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: daily_production_header daily_production_header_machine_id_machine_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_machine_id_machine_master_id_fk FOREIGN KEY (machine_id) REFERENCES public.machine_master(id);


--
-- Name: daily_production_header daily_production_header_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: daily_production_header daily_production_header_reconciled_transaction_id_transaction_h; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_reconciled_transaction_id_transaction_h FOREIGN KEY (reconciled_transaction_id) REFERENCES public.transaction_header(id) ON DELETE SET NULL;


--
-- Name: employee_advances employee_advances_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_advances
    ADD CONSTRAINT employee_advances_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: employee_salary_records employee_salary_records_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records
    ADD CONSTRAINT employee_salary_records_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: employee_salary_settings employee_salary_settings_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings
    ADD CONSTRAINT employee_salary_settings_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: two_factor_auth fk_2fa_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth
    ADD CONSTRAINT fk_2fa_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: two_factor_auth fk_2fa_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth
    ADD CONSTRAINT fk_2fa_user FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: app_user fk_app_user_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT fk_app_user_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: attendance fk_attendance_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT fk_attendance_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: auth_audit fk_auth_audit_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_audit
    ADD CONSTRAINT fk_auth_audit_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: auth_audit fk_auth_audit_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_audit
    ADD CONSTRAINT fk_auth_audit_user FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE SET NULL;


--
-- Name: branding_config fk_branding_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branding_config
    ADD CONSTRAINT fk_branding_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: company_info_master fk_company_info_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_info_master
    ADD CONSTRAINT fk_company_info_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: company_info_master fk_company_info_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_info_master
    ADD CONSTRAINT fk_company_info_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: configuration_audit fk_config_audit_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration_audit
    ADD CONSTRAINT fk_config_audit_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: configuration_audit fk_config_audit_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration_audit
    ADD CONSTRAINT fk_config_audit_user FOREIGN KEY (changed_by) REFERENCES public.app_user(id) ON DELETE SET NULL;


--
-- Name: configuration fk_configuration_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration
    ADD CONSTRAINT fk_configuration_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: custom_domains fk_custom_domain_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_domains
    ADD CONSTRAINT fk_custom_domain_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: daily_delivery fk_daily_delivery_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT fk_daily_delivery_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: daily_production_detail fk_daily_prod_detail_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT fk_daily_prod_detail_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: daily_production_header fk_daily_prod_header_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT fk_daily_prod_header_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: daily_production_detail fk_daily_production_detail_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT fk_daily_production_detail_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: daily_production_header fk_daily_production_header_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT fk_daily_production_header_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: department_master fk_department_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_master
    ADD CONSTRAINT fk_department_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: email_templates fk_email_template_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT fk_email_template_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: employee_advances fk_employee_advances_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_advances
    ADD CONSTRAINT fk_employee_advances_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: employee_master fk_employee_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_master
    ADD CONSTRAINT fk_employee_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: employee_salary_records fk_employee_salary_records_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records
    ADD CONSTRAINT fk_employee_salary_records_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: employee_salary_settings fk_employee_salary_settings_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings
    ADD CONSTRAINT fk_employee_salary_settings_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: fabric_type_master fk_fabric_type_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fk_fabric_type_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: fabric_type_master fk_fabric_type_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fk_fabric_type_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: factory_maintenance fk_factory_maint_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factory_maintenance
    ADD CONSTRAINT fk_factory_maint_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: factory_maintenance fk_factory_maintenance_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factory_maintenance
    ADD CONSTRAINT fk_factory_maintenance_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: feature_flags fk_feature_flags_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT fk_feature_flags_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: integration_settings fk_integration_settings_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_settings
    ADD CONSTRAINT fk_integration_settings_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: invoice_item fk_invoice_item_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item
    ADD CONSTRAINT fk_invoice_item_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: invoice_payment fk_invoice_payment_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_payment
    ADD CONSTRAINT fk_invoice_payment_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: invoice fk_invoice_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: invoice_transaction fk_invoice_transaction_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_transaction
    ADD CONSTRAINT fk_invoice_transaction_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: job_master fk_job_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT fk_job_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: location_master fk_location_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_master
    ADD CONSTRAINT fk_location_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: login_attempts fk_login_attempts_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_attempts
    ADD CONSTRAINT fk_login_attempts_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: logo_uploads fk_logo_uploads_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logo_uploads
    ADD CONSTRAINT fk_logo_uploads_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: logo_uploads fk_logo_uploads_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logo_uploads
    ADD CONSTRAINT fk_logo_uploads_user FOREIGN KEY (uploaded_by) REFERENCES public.app_user(id) ON DELETE SET NULL;


--
-- Name: machine_history fk_machine_history_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_history
    ADD CONSTRAINT fk_machine_history_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: machine_maintenance fk_machine_maint_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_maintenance
    ADD CONSTRAINT fk_machine_maint_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: machine_maintenance fk_machine_maintenance_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_maintenance
    ADD CONSTRAINT fk_machine_maintenance_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: machine_master fk_machine_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_master
    ADD CONSTRAINT fk_machine_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_oauth_accounts fk_oauth_accounts_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_oauth_accounts
    ADD CONSTRAINT fk_oauth_accounts_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_oauth_accounts fk_oauth_accounts_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_oauth_accounts
    ADD CONSTRAINT fk_oauth_accounts_user FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: oauth_providers fk_oauth_providers_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_providers
    ADD CONSTRAINT fk_oauth_providers_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: party_master fk_party_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master
    ADD CONSTRAINT fk_party_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: password_reset_tokens fk_password_reset_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT fk_password_reset_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: password_reset_tokens fk_password_reset_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT fk_password_reset_user FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: plausibility_baseline fk_plausibility_baseline_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_baseline
    ADD CONSTRAINT fk_plausibility_baseline_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: plausibility_feedback fk_plausibility_feedback_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_feedback
    ADD CONSTRAINT fk_plausibility_feedback_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: role fk_role_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT fk_role_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: salary_detail fk_salary_detail_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT fk_salary_detail_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: salary_header fk_salary_header_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_header
    ADD CONSTRAINT fk_salary_header_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: session_settings fk_session_settings_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_settings
    ADD CONSTRAINT fk_session_settings_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: tenant_admin_assignments fk_tenant_admin_assignedby; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_admin_assignments
    ADD CONSTRAINT fk_tenant_admin_assignedby FOREIGN KEY (assigned_by) REFERENCES public.app_user(id) ON DELETE SET NULL;


--
-- Name: tenant_admin_assignments fk_tenant_admin_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_admin_assignments
    ADD CONSTRAINT fk_tenant_admin_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: tenant_admin_assignments fk_tenant_admin_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_admin_assignments
    ADD CONSTRAINT fk_tenant_admin_user FOREIGN KEY (admin_user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: tenant_settings fk_tenant_settings_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_settings
    ADD CONSTRAINT fk_tenant_settings_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: theme_presets fk_theme_preset_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theme_presets
    ADD CONSTRAINT fk_theme_preset_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: transaction_detail fk_transaction_detail_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT fk_transaction_detail_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: transaction_header fk_transaction_header_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT fk_transaction_header_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: transaction_type_master fk_transaction_type_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT fk_transaction_type_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: transaction_type_master fk_transaction_type_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT fk_transaction_type_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: uom_master fk_uom_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master
    ADD CONSTRAINT fk_uom_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_invitations fk_user_invitations_inviter; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_invitations
    ADD CONSTRAINT fk_user_invitations_inviter FOREIGN KEY (invited_by) REFERENCES public.app_user(id) ON DELETE SET NULL;


--
-- Name: user_invitations fk_user_invitations_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_invitations
    ADD CONSTRAINT fk_user_invitations_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_sessions fk_user_sessions_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT fk_user_sessions_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_sessions fk_user_sessions_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: workflow_settings fk_workflow_settings_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_settings
    ADD CONSTRAINT fk_workflow_settings_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_brand_master fk_yarn_brand_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT fk_yarn_brand_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_brand_master fk_yarn_brand_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT fk_yarn_brand_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_count_master fk_yarn_count_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT fk_yarn_count_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_count_master fk_yarn_count_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT fk_yarn_count_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_receipt_detail fk_yarn_receipt_detail_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT fk_yarn_receipt_detail_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_receipt_header fk_yarn_receipt_header_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header
    ADD CONSTRAINT fk_yarn_receipt_header_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_type_master fk_yarn_type_master_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT fk_yarn_type_master_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: yarn_type_master fk_yarn_type_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT fk_yarn_type_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: invoice invoice_company_id_company_info_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_company_id_company_info_master_id_fk FOREIGN KEY (company_id) REFERENCES public.company_info_master(id);


--
-- Name: invoice_item invoice_item_invoice_id_invoice_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item
    ADD CONSTRAINT invoice_item_invoice_id_invoice_id_fk FOREIGN KEY (invoice_id) REFERENCES public.invoice(id) ON DELETE CASCADE;


--
-- Name: invoice_item invoice_item_yarn_count_id_yarn_count_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item
    ADD CONSTRAINT invoice_item_yarn_count_id_yarn_count_master_id_fk FOREIGN KEY (yarn_count_id) REFERENCES public.yarn_count_master(id);


--
-- Name: invoice_item invoice_item_yarn_type_id_yarn_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item
    ADD CONSTRAINT invoice_item_yarn_type_id_yarn_type_master_id_fk FOREIGN KEY (yarn_type_id) REFERENCES public.yarn_type_master(id);


--
-- Name: invoice invoice_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: invoice_payment invoice_payment_invoice_id_invoice_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_payment
    ADD CONSTRAINT invoice_payment_invoice_id_invoice_id_fk FOREIGN KEY (invoice_id) REFERENCES public.invoice(id) ON DELETE CASCADE;


--
-- Name: invoice_transaction invoice_transaction_invoice_id_invoice_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_transaction
    ADD CONSTRAINT invoice_transaction_invoice_id_invoice_id_fk FOREIGN KEY (invoice_id) REFERENCES public.invoice(id) ON DELETE CASCADE;


--
-- Name: invoice_transaction invoice_transaction_transaction_header_id_transaction_header_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_transaction
    ADD CONSTRAINT invoice_transaction_transaction_header_id_transaction_header_id FOREIGN KEY (transaction_header_id) REFERENCES public.transaction_header(id) ON DELETE CASCADE;


--
-- Name: machine_history machine_history_machine_id_machine_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_history
    ADD CONSTRAINT machine_history_machine_id_machine_master_id_fk FOREIGN KEY (machine_id) REFERENCES public.machine_master(id) ON DELETE SET NULL;


--
-- Name: machine_maintenance machine_maintenance_machine_id_machine_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_maintenance
    ADD CONSTRAINT machine_maintenance_machine_id_machine_master_id_fk FOREIGN KEY (machine_id) REFERENCES public.machine_master(id);


--
-- Name: role_permission role_permission_role_id_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_role_id_role_id_fk FOREIGN KEY (role_id) REFERENCES public.role(id) ON DELETE CASCADE;


--
-- Name: salary_detail salary_detail_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: salary_detail salary_detail_header_id_salary_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_header_id_salary_header_id_fk FOREIGN KEY (header_id) REFERENCES public.salary_header(id) ON DELETE CASCADE;


--
-- Name: transaction_detail transaction_detail_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: transaction_detail transaction_detail_header_id_transaction_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_header_id_transaction_header_id_fk FOREIGN KEY (header_id) REFERENCES public.transaction_header(id) ON DELETE CASCADE;


--
-- Name: transaction_detail transaction_detail_machine_id_machine_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_machine_id_machine_master_id_fk FOREIGN KEY (machine_id) REFERENCES public.machine_master(id);


--
-- Name: transaction_detail transaction_detail_uom_id_uom_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_uom_id_uom_master_id_fk FOREIGN KEY (uom_id) REFERENCES public.uom_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_brand_id_yarn_brand_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_brand_id_yarn_brand_master_id_fk FOREIGN KEY (yarn_brand_id) REFERENCES public.yarn_brand_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_count_id_yarn_count_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_count_id_yarn_count_master_id_fk FOREIGN KEY (yarn_count_id) REFERENCES public.yarn_count_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_type_id_yarn_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_type_id_yarn_type_master_id_fk FOREIGN KEY (yarn_type_id) REFERENCES public.yarn_type_master(id);


--
-- Name: transaction_header transaction_header_fabric_type_id_fabric_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_fabric_type_id_fabric_type_master_id_fk FOREIGN KEY (fabric_type_id) REFERENCES public.fabric_type_master(id);


--
-- Name: transaction_header transaction_header_job_id_job_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_job_id_job_master_id_fk FOREIGN KEY (job_id) REFERENCES public.job_master(id);


--
-- Name: transaction_header transaction_header_location_id_location_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_location_id_location_master_id_fk FOREIGN KEY (location_id) REFERENCES public.location_master(id);


--
-- Name: transaction_header transaction_header_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: transaction_header transaction_header_transaction_type_id_transaction_type_master_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_transaction_type_id_transaction_type_master_ FOREIGN KEY (transaction_type_id) REFERENCES public.transaction_type_master(id);


--
-- Name: yarn_receipt_detail yarn_receipt_detail_header_id_yarn_receipt_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_header_id_yarn_receipt_header_id_fk FOREIGN KEY (header_id) REFERENCES public.yarn_receipt_header(id) ON DELETE CASCADE;


--
-- Name: yarn_receipt_detail yarn_receipt_detail_yarn_brand_id_yarn_brand_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_yarn_brand_id_yarn_brand_master_id_fk FOREIGN KEY (yarn_brand_id) REFERENCES public.yarn_brand_master(id);


--
-- Name: yarn_receipt_detail yarn_receipt_detail_yarn_count_id_yarn_count_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_yarn_count_id_yarn_count_master_id_fk FOREIGN KEY (yarn_count_id) REFERENCES public.yarn_count_master(id);


--
-- Name: yarn_receipt_header yarn_receipt_header_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header
    ADD CONSTRAINT yarn_receipt_header_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: yarn_receipt_header yarn_receipt_header_reconciled_transaction_id_transaction_heade; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header
    ADD CONSTRAINT yarn_receipt_header_reconciled_transaction_id_transaction_heade FOREIGN KEY (reconciled_transaction_id) REFERENCES public.transaction_header(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict vOJ8Zhft6fERT9MFGkeXQ3CJ79hCuVzP4tCA16txKBsJykoc36yP6UfeTaAMbrg

