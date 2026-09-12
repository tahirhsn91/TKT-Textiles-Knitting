--
-- PostgreSQL database dump
--

\restrict 3NUYAbVFCGJfesdxscUA9UBJ1Gn657shsGquBzlIyu9sZ5miSMVNTGGT7LkycBy

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

\unrestrict 3NUYAbVFCGJfesdxscUA9UBJ1Gn657shsGquBzlIyu9sZ5miSMVNTGGT7LkycBy

